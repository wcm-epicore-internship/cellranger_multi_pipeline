#!/bin/bash

set -o pipefail

# this is given on the command line in the qsub from config.yml
DEFAULT_LIMS_URL='https://abc.med.cornell.edu/epilims/rest';
DEFAULT_FASTQ_QC_BIN='/home/aladdin/fastq-qc/current/bin/fastq-qc.sh';
TEST_DATASHEET_URL='https://epicore.med.cornell.edu/minilims/plugins/Local/cellranger_test/cellranger-tiny-bcl-samplesheet-1.2.0.csv';
PIPELINE_NAME='CellRanger';

bin_path=$(dirname ${BASH_SOURCE[0]});
mro_template_path="${bin_path}/../cellranger_mro_template.txt";

# Create an empty log directory
cwd=$(pwd);
log_dir="${cwd}/logs";
if [ ! -e $log_dir ]; then
  mkdir $log_dir;
else
  rm -vf ${log_dir}/*;
fi
logfile_name="cellranger-$(date +%Y-%m-%d).log";
logfile="$log_dir/$logfile_name";
touch $logfile;

echo "cellranger.sh user: $(whoami)" | tee -a $logfile;
echo "hostname: $(hostname)"         | tee -a $logfile;

if [ "$(whoami)" != 'aladdin' ]; then
  host_name=$(hostname | grep -Eo "epicore[0-9]{2}");
  echo "INIT: Sourcing ${bin_path}/cellranger-init-$host_name.sh" | tee -a $logfile;
  source "${bin_path}/cellranger-init-$host_name.sh";
fi

print_usage() {
echo "
Usage: $(basename $0)
  -c,  --count        Count, with or without demux (-d). Optional.
  -d,  --demux        Demux, with or without count (-c). Optional.
  -j,  --vdj          VDJ, generate single-cell V(D)J sequences and annotation (-v). Optional

  -b,  --bases-mask   Pass-through to mkfastq, delimit with double quotes. (eg. -b "Y26N*,I8,Y98N*")
  -e,  --sheet_path   Path to sample sheet. This OR Flowcell ID (-f) required for Demux.
  -f,  --flowcell_id  LIMS flowcell IDs (comma separated) eg. Illumina_Flowcell_1234. This OR sheet (-e) required for Demux.
  -h,  --help         Print usage.
  -i,  --input        Demux: paths to Illumina output directories (comma separated, match input order). Required.
                    Count: paths to demux Project_* directories (comma separated). Required.

  -k,  --keep         Do not remove intermediate files. Optional.
  -l,  --limsrc       LIMS RC file for use with -u --limsurl options. Optional - Default: ~/.limsrc
  -n,  --no_copy       Do not make a local copy of the input data, read it in-place. Optional.
  -o,  --output_cwd   Write output to the present working directory. Optional.
  -p,  --project      iLab ID (eg. EC-AB-1234). Required.
  -q,  --fastq_qc     Run fastq-qc pipeline (with demux only).
  -s,  --samples      One or more sample dirs (include Sample_ prefix) comma separated for Count. If empty all samples processed.
  -t,  --ref          Transcritome directory path for SGE or name for interactive. Required for Count.
  -u,  --limsurl      LIMS URL including scheme, eg. https://epicore.med.cornell.edu/minilims. Optional.
  -x,  --localcores   Pass-through to cellranger.
  -y,  --localmem     Pass-through to cellranger.
  -z,  --test         Run in test datasheet download mode. Optional.

Notes:
  count --no-bam is on by default (TODO: make this an option)
"
}

function exitWithError() {
  echo -e "\nERROR: $1\n" | tee -a $logfile;
  if [ ! -z "$2" ]; then echo "$2"; fi
  print_usage;
  exit 1;
}

function checkExitStatus() {
  if [  $? -ne 0 ]; then exitWithError "$1" "$2"; fi
}

function checkProgram() {
  which $1;
  checkExitStatus "Cannot find the $1 executable. Check PATH and init scripts. Exiting...";
}

function findReplace() {
  sed_string="'s|${1}|${2}|g' $3"
  echo "Find/Replace $sed_string" | tee -a $logfile;
  cmd="sed -i $sed_string";
  eval $cmd;
  checkExitStatus "Problem running sed -i $sed_string. Exiting... " "See $logfile for more details."
}

# As of cellranger 2.0 MRO file not required for multiple flowcells
function createMro() {
  mro_file="${count_dir}/${sample_id}.mro";
  cmd="cp $mro_template_path ${mro_file}";
  echo "- Copying mro template" | tee -a $logfile;
  echo "-- $cmd"                | tee -a $logfile;
  eval $cmd;
  json_block='';
  json_block_a='{ \"fastq_mode\": \"ILMN_BCL2FASTQ\", \"gem_group\": null, \"lanes\": null, \"read_path\": \"';
  json_block_b='\", \"sample_indices\": [ \"any\" ], \"sample_names\": [ \"';
  json_block_c='\" ]},';
  echo "- Writing JSON block" | tee -a $logfile;
  for fastq_path in "${fastq_paths[@]}"; do
    json_block="${json_block}${json_block_a}${fastq_path}/${sample_name}${json_block_b}${sample_id}${json_block_c}"
  done
  json_block=${json_block%?};
  findReplace "SAMPLE_NAME" "${sample_id}_multi" "$mro_file";
  findReplace "REF_PATH" "${ref_path}" "$mro_file";
  findReplace "JSON_BLOCK" "${json_block}" "$mro_file";
  cmd="cp ${mro_file} ${count_aux_export_dir}/";
  echo "- Creating copy of mro for export" | tee -a $logfile;
  echo "-- $cmd"                           | tee -a $logfile;
  eval $cmd;
  cmd="cellranger count ${sample_id} ${mro_file} ${cores_mem_opts} | tee -a $logfile";
  echo "- Starting count; $(date)" | tee -a $logfile;
  echo "-- $cmd"                   | tee -a $logfile;
  eval $cmd;
}

# Create an empty tmp directory
tmp_dir="${cwd}/cellranger_tmp";
if [ ! -e $tmp_dir ]; then mkdir $tmp_dir; fi

# Check program paths
checkProgram 'cellranger';
cellranger_path=$(which 'cellranger');
cellranger_version=$(cellranger | grep -Eo "[0-9.]+" | head -n 1);

echo -e "\n=== Started $PIPELINE_NAME pipeline at $(date) ===\nCommand:\n$0 $@" | tee -a $logfile;
echo -e "Using:\ncellranger version ${cellranger_version}\n$cellranger_path" | tee -a $logfile;

# Initialize all vars
bases_mask=""
input_path_param=""
input_paths=()
input_processing_queue=()
inputs_dir_path="${tmp_dir}/inputs"
flowcell_id_param=""
flowcell_ids=()
fastq_export_paths=()
project_id=""
lims_url=$DEFAULT_LIMS_URL
lims_rc_file=${HOME}/.limsrc
lims_result_file="${tmp_dir}/lims_result"
purge=1
test=0
do_count=0
do_demux=0
do_vdj=0
do_qc=0
mkfastq_dir=""
localcores=0
localmem=0
ref_path=""
samplesheet_path_param=""
sample_names_param=""
output_cwd=0
no_copy=0

declare -a sample_names

# Parse command line arguments
if [ $# -eq 0 ]; then
  exitWithError "Not enough command line arguments."
fi
until [ -z "$1" ]; do
  case "$1" in
  -h | --help)
    print_usage
    exit 0;;
  -b | --bases-mask)
    bases_mask=${2#'"'}
    shift 2;;
  -c | --count)
    do_count=1
    shift;;
  -d | --demux)
    do_demux=1
    shift;;
  -j | --vdj)
    do_vdj=1
    shift;;
  -e | --sheet_path)
    samplesheet_path_param=$2
    shift 2;;
  -q | --fastq_qc)
    do_qc=1
    shift;;
  -n | --no_copy)
    no_copy=1
    shift;;
  -o | --output_cwd)
    output_cwd=1
    shift;;
  -i | --input)
    input_path_param=$2
    shift 2;;
  -p | --project)
    project_id=$2
    shift 2;;
  -f | --flowcell_id)
    flowcell_id_param=$2
    shift 2;;
  -s | --samples)
    sample_names_param=$2
    shift 2;;
  -t | --ref)
    ref_path=$2
    shift 2;;
  -u | --limsurl)
    lims_url=${2%/}
    shift 2;;
  -l | --limsrc)
    lims_rc_file=$2
    shift 2;;
  -k | --keep)
    purge=0
    shift;;
  -x | --localcores)
    localcores=$2
    shift 2;;
  -y | --localmem)
    localmem=$2
    shift 2;;
  -z | --test)
    test=1
    shift;;
  --)  #End of all options
    shift
    break;;
  -*)
    exitWithError "Invalid option ($1).";;
  *)
    break;;
  esac
done

# ====================================================================================================
# Check all variables and file paths are valid
# ====================================================================================================
echo "Initializing; $(date)" | tee -a $logfile;
if [ $do_demux -eq 0 ] && [ $do_count -eq 0 ] && [ $do_vdj -eq 0 ]; then
  exitWithError "demux and/or count/vdj flag must be used."
fi
if [ $test -eq 1 ];     then echo "*** TEST MODE ACTIVE ***" | tee -a $logfile; fi
if [ $do_demux -eq 1 ]; then echo "- demux mode selected"    | tee -a $logfile; fi
if [ $do_count -eq 1 ]; then echo "- count mode selected"    | tee -a $logfile; fi
if [ $do_vdj -eq 1 ];   then echo "- vdj mode selected"      | tee -a $logfile; fi

# If running demux need either sheet or flowcell id
if [ $do_demux -eq 1 ]; then
  # flowcell id must not be null
  if [ -z "$flowcell_id_param" ] && [ -z "$samplesheet_path_param" ]; then exitWithError "Either sample sheet (-e) or Flowcell ID must be specified."; fi

  if [ -z "$samplesheet_path_param" ]; then
    # if there are multiple flowcell_ids
    if [[ $flowcell_id_param =~ \, ]]; then
      flowcell_ids=(${flowcell_id_param//,/ });
    else
      flowcell_ids=($flowcell_id_param);
    fi
  else # given sample sheet check it exists
    if [ ! -s "$samplesheet_path_param" ]; then exitWithError "Specified sample sheet [$samplesheet_path_param] cannot be found or is empty."; fi
  fi
fi

# input_path must be not null
if [ -z "$input_path_param" ]; then exitWithError "input must be specified (comma separated)."; fi

# if there are multiple input paths
if [[ $input_path_param =~ \, ]]; then
  input_paths=(${input_path_param//,/ });
else
  input_paths=($input_path_param);
fi

# convert relative paths to absolute
absolute_input_paths=();
for input_path in "${input_paths[@]}"; do
  if ! [[ $input_path =~ ^/.* ]]; then
    input_path="${cwd}/${input_path}";
  fi
  absolute_input_paths+=($input_path);
done
input_paths=( "${absolute_input_paths[@]}" );

# if demux and input paths there must be flowcell id for each input path
if [ $do_demux -eq 1 ] && [ -z "$samplesheet_path_param" ]; then
  if [ ${#flowcell_ids[@]} -ne ${#input_paths[@]} ]; then
    exitWithError "Number of inputs must match number of flowcell ids";
  fi
fi

echo 'Checking input paths are readable: ' | tee -a $logfile;
count=0;
for input_path in "${input_paths[@]}"; do
  if [ ! -d $input_path ]; then exitWithError "$input_path is not a directory."; elif [ ! -r $input_path ]; then exitWithError "$input_path is not readable."; fi
  # If running demux
  if [ $do_demux -eq 1 ]; then
    echo "- ${input_path} => [${flowcell_ids[$count]}]" | tee -a $logfile;
    (( count++ ));
  else
    echo "- ${input_path}" | tee -a $logfile;
    sample_dirs=($(ls -1 $input_path/Sample_* 2>/dev/null));
    if [ ${#sample_dirs[@]} -eq 0 ]; then
      exitWithError "No Sample_* directories found in $input_path"
    fi
  fi
done

if [ $do_count -eq 1 ] || [ $do_vdj -eq 1 ]; then
  if ! [[ $ref_path =~ \/ ]]; then ref_path="${CELLRANGER_REF_PATH}/$ref_path"; fi
  echo -n "Checking transcriptome path is readable: ${ref_path}... " | tee -a $logfile;
  if [ -z "$ref_path" ]; then exitWithError "transcriptome path must be specified."; fi
  if [ ! -d $ref_path ]; then exitWithError "$ref_path is not a directory."; elif [ ! -r $ref_path ]; then exitWithError "$ref_path is not readable."; fi
  echo 'OK' | tee -a $logfile;
fi

# project must be specified
if [ -z "$project_id" ]; then exitWithError "Project ID must be specified."; fi
echo "Using Project ID: ${project_id}" | tee -a $logfile;

# lims_url must not be null
if [ -z "$lims_url" ]; then exitWithError "LIMS URL must be specified."; fi

if [ -z "$lims_rc_file" ]; then
  echo "No LIMS rc file given"
else
  if [ -e "$lims_rc_file" ]; then
    echo 'Checking LIMS credentials' | tee -a $logfile;
    echo "- Found limsrc file [$lims_rc_file]"  | tee -a $logfile;
    lims_composition=$(grep cellranger_composition $lims_rc_file | cut -d'=' -f2);
    # echo "-- lims_samplesheet_path: ${lims_samplesheet_path}"      | tee -a $logfile
    echo "-- lims_url: ${lims_url}"                       | tee -a $logfile
    echo "-- lims_composition: ${lims_composition}"       | tee -a $logfile
  else
    exitWithError "Can't find LIMS rc file at [${lims_rc_file}]";
  fi
fi
# end Check all variables and file paths =============================================================
echo "===================================================" | tee -a $logfile
echo "cwd              : $cwd"                    | tee -a $logfile
echo "tmp_dir          : $tmp_dir"                | tee -a $logfile
echo "bases_mask       : $bases_mask"             | tee -a $logfile
echo "input_path_param : $input_path_param"       | tee -a $logfile
echo "input_paths      : $input_paths"            | tee -a $logfile
echo "input_processing_queue : $input_processing_queue" | tee -a $logfile
echo "inputs_dir_path    : $inputs_dir_path"      | tee -a $logfile
echo "flowcell_id_param  : $flowcell_id_param"    | tee -a $logfile
echo "flowcell_ids       : $flowcell_ids"         | tee -a $logfile
echo "fastq_export_paths : $fastq_export_paths"   | tee -a $logfile
echo "project_id         : $project_id"           | tee -a $logfile
echo "lims_url           : $lims_url"             | tee -a $logfile
echo "lims_rc_file       : $lims_rc_file"         | tee -a $logfile
echo "lims_result_file   : $lims_result_file"     | tee -a $logfile
echo "mkfastq_dir : $mkfastq_dir"                 | tee -a $logfile
echo "localcores  : $localcores"                  | tee -a $logfile
echo "localmem    : $localmem"                    | tee -a $logfile
echo "ref_path    : $ref_path"                    | tee -a $logfile
echo "samplesheet_path_param : $samplesheet_path_param" | tee -a $logfile
echo "sample_names_param     : $sample_names_param"     | tee -a $logfile
echo "purge       : $purge"                       | tee -a $logfile
echo "test        : $test"                        | tee -a $logfile
echo "do count    : $do_count"                    | tee -a $logfile
echo "do demux    : $do_demux"                    | tee -a $logfile
echo "do vdj      : $do_vdj"                      | tee -a $logfile
echo "do qc       : $do_qc"                       | tee -a $logfile
echo "output_cwd  : $output_cwd"                  | tee -a $logfile
echo "no_copy     : $no_copy"                     | tee -a $logfile
echo "===================================================" | tee -a $logfile

cores_mem_opts="";
if [ $localcores -gt 0 ]; then
  cores_mem_opts="--localcores=${localcores}";
fi
if [ $localmem -gt 0 ]; then
  cores_mem_opts="${cores_mem_opts} --localmem=${localmem}";
fi

# ====================================================================================================
# demux
# ====================================================================================================
if [ $do_demux -eq 1 ]; then

  echo -e "\n\n=== Initilizing demux at $(date) ===" | tee -a $logfile;

  checkProgram 'bcl2fastq';
  bcl2fastq_path=$(which 'bcl2fastq');
  bcl2fastq_version=$(bcl2fastq -v 2>&1 | grep bcl2fastq | awk '{print $2}');
  echo -e "bcl2fastq version ${bcl2fastq_version}\n$bcl2fastq_path"  | tee -a $logfile;

  samplesheet_file="${project_id}.csv"
  mkdir -p ${inputs_dir_path}

  if [ -z "$samplesheet_path_param" ]; then
    # login with post and get session cookie
    echo "Connect to LIMS; $(date)" | tee -a $logfile;
    echo '- Logging in to LIMS'     | tee -a $logfile;
    wget --no-check-certificate --save-cookies ${lims_cookie_file} --keep-session-cookies --post-data "Username=${lims_username}&Password=${lims_password}" "${lims_url}${lims_login_path}" -O ${lims_login_file} >> $logfile 2>&1;
    # if can't get sample sheet stop here
    if [ $? -ne 0 ]; then exitWithError "Failed to log in to LIMS"; fi
  fi

  echo -e "\n----------\nInput paths queue:" | tee -a $logfile;
  printf '%s\n' "${input_paths[@]}"          | tee -a $logfile;
  echo -e "----------\n"                     | tee -a $logfile;

  for input_path in "${input_paths[@]}"; do
    basedir=$(basename $input_path);
    #run_dir_name="${run_dir_name}${basedir}_";
    samplesheet_input_path="${inputs_dir_path}/${basedir}/${samplesheet_file}"

    if [ $no_copy -eq 1 ]; then
      echo "Reading input data in-place from $input_path" | tee -a $logfile;
      input_processing_queue+=($input_path);
      cmd="mkdir ${inputs_dir_path}/${basedir}";
      echo "Creating input directory for sample sheet"    | tee -a $logfile;
      echo "- $cmd"                                       | tee -a $logfile;
      eval $cmd;
      if [ $? -ne 0 ]; then exitWithError "Failed to create directory"; fi
    else
      # (thk2008) I think rsync would be better
      # cmd="rsync -avu --exclude=Thumbnail_Images ${input_path} ${inputs_dir_path}/";
      cmd="cp -R ${input_path} ${inputs_dir_path}/";
      echo "Copying input data" | tee -a $logfile;
      echo "- $cmd"             | tee -a $logfile;
      eval $cmd;
      if [ $? -ne 0 ]; then exitWithError "Failed to copy input data"; fi
      input_processing_queue+=("${inputs_dir_path}/${basedir}");
    fi

    if [ -z "$samplesheet_path_param" ]; then
      echo "Downloading sample sheet(s)" | tee -a $logfile;
      # load session cookie and get samplesheet file
      if [ $test -eq 0 ]; then
        for flowcell_id in "${flowcell_ids[@]}"; do
          echo "- URL: ${lims_url}${lims_samplesheet_path}?csv=1&prefix=1&run_id=${flowcell_id}&ilabsId=${project_id}" | tee -a $logfile;
          wget --no-check-certificate --load-cookies ${lims_cookie_file} "${lims_url}${lims_samplesheet_path}?csv=1&prefix=1&run_id=${flowcell_id}&ilabsId=${project_id}" -O ${samplesheet_input_path} >> $logfile 2>&1;
          if [ $? -ne 0 ]; then exitWithError "Failed to download sample sheet"; fi
        done
      else
        echo "- TEST MODE ACTUAL URL: ${TEST_DATASHEET_URL}" | tee -a $logfile;
        wget --no-check-certificate --load-cookies ${lims_cookie_file} "${TEST_DATASHEET_URL}" -O ${samplesheet_input_path} >> $logfile 2>&1;
        if [ $? -ne 0 ]; then exitWithError "Failed to download sample sheet"; fi
      fi
      # check response
      if [ ! -e ${samplesheet_input_path} ]; then
        exitWithError "Could not find ${samplesheet_input_path}" | tee -a $logfile;
      else
        echo "- Downloaded ${samplesheet_input_path} OK" | tee -a $logfile;
      fi
    else
      cmd="cp $samplesheet_path_param ${inputs_dir_path}/${basedir}/${samplesheet_file}";
      echo "Copying sample sheet" | tee -a $logfile;
      echo "- $cmd"               | tee -a $logfile;
      eval $cmd;
    fi
  done
  #run_dir_name=${run_dir_name%?}
  mkfastq_dir="${tmp_dir}/mkfastq";
  cmd="mkdir -p ${mkfastq_dir} && cd ${mkfastq_dir}";
  echo "Creating and changing to demux dir; $(date)" | tee -a $logfile;
  echo "- $cmd"                                      | tee -a $logfile;
  eval $cmd;

  #input_processing_queue=(${input_path});
  #input_processing_queue=$(find ${input_path} -maxdepth 1 -mindepth 1 -type d -not -name ".*");
  # for input_path in ${inputs_dir_path}/*/; do

  echo -e "\n\n----------\nInput processing queue:" | tee -a $logfile;
  printf '%s\n' "${input_processing_queue[@]}"      | tee -a $logfile;
  echo -e "----------"                              | tee -a $logfile;

  for input_path in ${input_processing_queue[@]}; do
    basedir=$(basename $input_path);
    bases_mask_cmd='';
    echo -e "\n---- Processing input: ${input_path}\n"  | tee -a $logfile;
    echo "Launching cellranger demux; $(date)"          | tee -a $logfile;
    if [ ! -z "$bases_mask" ]; then bases_mask_cmd="--use-bases-mask=${bases_mask}"; fi
    # seems cellranger 4.0.0/5.0.0 has removed this option and includes some other options:  --force-single-index --filter-single-index --filter-dual-index
    # cmd="cellranger mkfastq --samplesheet=${samplesheet_input_path} --project=${project_id} --run=${input_path} ${bases_mask_cmd} ${cores_mem_opts} --ignore-dual-index --delete-undetermined --disable-ui | tee -a $logfile";
    cmd="cellranger mkfastq --samplesheet=${samplesheet_input_path} --project=${project_id} --run=${input_path} ${bases_mask_cmd} ${cores_mem_opts} --delete-undetermined --disable-ui | tee -a $logfile";
    echo "- $cmd" | tee -a $logfile;
    eval $cmd;
    checkExitStatus "Failed running cellranger mkfastq" "See $logfile for more details.";

    if [ $output_cwd -eq 1 ]; then
      mkfastq_export_dir="${cwd}"
    else
      mkfastq_export_dir="${cwd}/cellranger_demux_${basedir}_${project_id}";
      cmd="mkdir ${mkfastq_export_dir}";
      echo "Creating demux export directories; $(date)" | tee -a $logfile;
      echo "- $cmd"                                     | tee -a $logfile;
      eval $cmd;
    fi

    demux_outs_path=$(find ./*/outs/fastq_path/ -maxdepth 1 -mindepth 1 -type d ! -name Reports ! -name Stats);
    if [ $? -ne 0 ] || [ ${#demux_outs_path[@]} -eq 0 ]; then exitWithError 'Could not find samples in ./*/outs/fastq_path/'; fi
    cmd="mv ${demux_outs_path} ${mkfastq_export_dir}/";
    echo "Moving demux output directory to export; $(date)" | tee -a $logfile;
    echo "- $cmd"                                           | tee -a $logfile;
    eval $cmd;
    checkExitStatus "Failed moving sample dir" "See $logfile for more details.";

    mkfastq_export_project_dir="${mkfastq_export_dir}/$(basename $demux_outs_path)";
    fastq_export_paths+=($mkfastq_export_project_dir);
    cmd="mv ./*/outs/fastq_path/Undetermined*.fastq.gz ./*/outs/fastq_path/Reports ./*/outs/fastq_path/Stats ${mkfastq_export_dir}/";
    echo "- Project demux path: ${mkfastq_export_project_dir}"            | tee -a $logfile;
    echo "Moving Undetermind reads, Reports, Stats and InterOp to export" | tee -a $logfile;
    echo "- $cmd"                                                         | tee -a $logfile;
    eval $cmd;
    cmd="mv ./*/outs/interop_path ${mkfastq_export_dir}/InterOp";
    echo "- $cmd"                                                         | tee -a $logfile;
    eval $cmd;
    mkfastq_aux_export_dir="${mkfastq_export_dir}/auxiliary";
    cmd="mkdir ${mkfastq_aux_export_dir}; mv * ${mkfastq_aux_export_dir}/"
    echo "Creating demux auxiliary dir and moving files"                  | tee -a $logfile;
    echo "- $cmd"                                                         | tee -a $logfile;
    eval $cmd;
    # this is just for convenience when running manually
    # the fastq-qc pipeline is a separate pipeline
    # (thk2008) would like to parallelize this using localcores
    if [ $do_qc -eq 1 ]; then
      cmd="cd ${mkfastq_export_dir}";
      echo "Changing to export dir" | tee -a $logfile;
      echo "- $cmd"                 | tee -a $logfile;
      eval $cmd;
      cmd="${DEFAULT_FASTQ_QC_BIN} -d -m --input ${mkfastq_export_project_dir} --project ${project_id} --run ${basedir} | tee -a $logfile";
      echo "Launching QC pipeline; $(date)" | tee -a $logfile;
      echo "-- $cmd"                        | tee -a $logfile;
      eval $cmd;
      cmd="cd ${mkfastq_dir}";
      echo "Changing back to demux dir" | tee -a $logfile;
      echo "- $cmd"                     | tee -a $logfile;
      eval $cmd;
    fi
    echo -e "=== Completed demux at $(date) ===\n\n" | tee -a $logfile;
    cmd="cp -R ${log_dir} ${mkfastq_aux_export_dir}/"
    echo "Copying current log" | tee -a $logfile;
    echo "- $cmd"              | tee -a $logfile;
    eval $cmd;
    logfile="${mkfastq_aux_export_dir}/logs/${logfile_name}";
  done
  if [ $purge -eq 1 ]; then
    cmd="rm -R ${inputs_dir_path} ${log_dir}";
    echo "- Purging: $cmd" | tee -a $logfile;
    eval $cmd;
  fi;
  cmd="cd ${cwd}";
  echo "Changing back to cwd" | tee -a $logfile;
  echo "- $cmd"               | tee -a $logfile;
  eval $cmd;
fi
# end demux ==========================================================================================
# ====================================================================================================
# count
# ====================================================================================================
if [ $do_count -eq 1 ]; then

  echo -e "\n\n=== Initilizing count at $(date) ===" | tee -a $logfile;

  if [ $do_demux -eq 1 ]; then
    fastq_paths=( "${fastq_export_paths[@]}" );
  else
    fastq_paths=( "${input_paths[@]}" );
  fi

  echo "Input paths: "                 | tee -a $logfile;
  printf '   %s\n' "${fastq_paths[@]}" | tee -a $logfile;

  count_dir="${tmp_dir}/count";
  cmd="mkdir -p ${count_dir}; cd ${count_dir}";
  echo "Creating and changing to count dir; $(date)" | tee -a $logfile;
  echo "- $cmd"                                      | tee -a $logfile;
  eval $cmd;

  if [ $output_cwd -eq 1 ]; then
    count_export_dir=${cwd};
  else
    count_export_dir="${cwd}/cellranger_count_${project_id}";
    cmd="mkdir ${count_export_dir};"
    echo "Creating count export dir" | tee -a $logfile;
    echo "- $cmd"                    | tee -a $logfile;
    eval $cmd;
    checkExitStatus "Failed creating export dir" "See $logfile for more details.";
  fi

  count_aux_export_dir="$count_export_dir/auxiliary";
  cmd="mkdir ${count_aux_export_dir};"
  echo "Creating auxiliary dir" | tee -a $logfile;
  echo "- $cmd"                 | tee -a $logfile;
  eval $cmd;
  checkExitStatus "Failed creating auxiliary dir" "See $logfile for more details.";

  if [ -z "$sample_names_param" ]; then
    sample_names=($(ls -1 ${fastq_paths[0]}));
  else
    sample_names=(${sample_names_param//,/ });
  fi

  echo "===================================================" | tee -a $logfile
  echo "count_dir            : $count_dir"            | tee -a $logfile
  echo "count_export_dir     : $count_export_dir"     | tee -a $logfile
  echo "count_aux_export_dir : $count_aux_export_dir" | tee -a $logfile
  echo "cwd                  : $cwd"                  | tee -a $logfile
  echo "log_dir              : $log_dir"              | tee -a $logfile
  echo "===================================================" | tee -a $logfile

  for sample_name in "${sample_names[@]}"; do

    if [[ $sample_name == Sample_* ]]; then
      sample_id=${sample_name:7}
    else
      sample_id=$sample_name
    fi

    echo -e "\n---- Processing input (name, id): ${sample_name}, ${sample_id} ---\n"  | tee -a $logfile;

    fastqs='';
    if [ ${#fastq_paths[@]} -eq 1 ]; then
      echo '- Single flowcell input' | tee -a $logfile;
      fastqs="${fastq_paths[0]}/${sample_name}";
    else
      echo '- Multiple flowcell input' | tee -a $logfile;
      fastqs=$(printf "%s/${sample_name}," "${fastq_paths[@]}");
      fastqs=${fastqs%?};
    fi

    cmd="cellranger count --id=${sample_id} --fastqs=${fastqs} --transcriptome=${ref_path} --sample=${sample_id} --description=${project_id} --no-bam --disable-ui ${cores_mem_opts}";
    echo "- Running count; $(date)" | tee -a $logfile;
    echo "-- $cmd"                  | tee -a $logfile;
    eval ${cmd} | tee -a $logfile
    checkExitStatus "Failed running count" "See $logfile for more details.";

    # not sure about this, is there always only one bam
    cmd="mv ${sample_id}/outs/*.bam ${count_export_dir}/${sample_id}.bam"
    cmd="${cmd}; mv ${sample_id}/outs/*.bai ${count_export_dir}/${sample_id}.bam.bai"
    cmd="${cmd}; mv ${sample_id}/outs/web_summary.html ${count_export_dir}/${sample_id}_web_summary.html";
    # cmd="${cmd}; cp ${sample_id}/SC_RNA_COUNTER_CS/SC_RNA_COUNTER/SUMMARIZE_REPORTS/fork0/files/alerts.json ${count_aux_export_dir}/alerts.json";
    echo "- Moving bam, bai, and web summary to export dir" | tee -a $logfile;
    echo "-- $cmd"                                          | tee -a $logfile;
    eval $cmd;

    echo "- Parsing stats" | tee -a $logfile;
    stats_keys=($(head -n 1 ${sample_id}/outs/metrics_summary.csv | tr '[:lower:]' '[:upper:]' | sed 's/ /_/g' | sed 's/[^A-Za-z_,]//g' | awk 'BEGIN {FS=","} {for(i=1;i<=NF;i++)print $i}'));
    stats_vals_line=$(tail -n 1 ${sample_id}/outs/metrics_summary.csv);
    i=0;
    stats_pairs=();
    # if int values are greater than 999, commas are used and values are quoted, eg. 1,2,"333,000",4,5
    if [[ $stats_vals_line =~ "\"" ]]; then
       stats_vals=($(echo $stats_vals_line | awk 'BEGIN {FS="\",\""} {for(i=1;i<=NF;i++)print $i}' |  awk 'BEGIN {FS="\""} {for(i=1;i<=NF;i++)print $i}'));
     else
      stats_vals=(${stats_vals_line//,/ });
     fi

    for stats_val in "${stats_vals[@]}"; do
      if ! [[ $stats_val =~ [0-9]+ ]]; then
        continue;
        ((i++));
      fi
      if ! [[ $stats_vals_line =~ "\"" ]]; then
        val=$(echo ${stats_val} | sed 's/[^0-9.]*//g');
        stats_pairs+=("${stats_keys[$i]}=${val}");
        ((i++));
      else
        # if this is a quoted csv line it doesn't start with a comma
        if [[ ${stats_val} != ,* ]]; then
          # remove all commas and percentage from int values
          val=$(echo ${stats_val} | sed 's/[^0-9.]*//g');
          stats_pairs+=("${stats_keys[$i]}=${val}");
          ((i++));
        else
          unquoted_vals=(${stats_val//,/ });
          for unquoted_val in "${unquoted_vals[@]}"; do
            val=$(echo ${unquoted_val} | sed 's/[^0-9.]*//g');
            stats_pairs+=("${stats_keys[$i]}=${val}");
            ((i++));
          done
        fi
      fi
    done

    stats_pair_uri='';
    for stats_pair in "${stats_pairs[@]}"; do
      stats_pair_uri="${stats_pair_uri}${stats_pair}&";
    done

    stats_pair_uri="${stats_pair_uri%?}";

    echo "- Updating LIMS"       | tee -a $logfile;
    echo "curl -X POST -i --data \"Library=${sample_id}&iLabs_Service_ID=${project_id}&${stats_pair_uri}\" ${lims_url}/${lims_composition}" | tee -a $logfile
    curl -X POST -i --data "Library=${sample_id}&iLabs_Service_ID=${project_id}&${stats_pair_uri}" ${lims_url}/${lims_composition} -o $lims_result_file >> $logfile 2>&1
    if [[ $? -ne 0 ]]; then echo "WARNING:  failed to update LIMS with stats" | tee -a $logfile; fi  # checkExitStatus "Failed to save stats to LIMS"
    # check response
    if [[ -e "${lims_result_file}" ]]; then
      if [ $(grep '200 OK' $lims_result_file | wc -l) -ne "1" ]; then
        echo "** WARNING: LIMS did not update:" | tee -a $logfile
        cat ${lims_result_file} | tee -a $logfile
        echo "**" | tee -a $logfile
      else
        echo "LIMS updated for $sample_id OK" | tee -a $logfile
      fi
      rm $lims_result_file
    fi

    # extract alerts from web summary for seqmon email
    python3 ${bin_path}/extract_alarms_from_web_summary.py ${count_export_dir}/${sample_id}_web_summary.html > ${count_aux_export_dir}/alerts.json

    cmd="tar cfz ${count_export_dir}/${sample_id}.tgz ${sample_id}";
    echo "- Archiving sample dir to export" | tee -a $logfile;
    echo "-- $cmd"                          | tee -a $logfile;
    eval $cmd;
  done

  echo -e "=== Completed count at $(date) ===\n\n" | tee -a $logfile;

  cmd="mv ${log_dir} ${count_aux_export_dir}/";
  echo "Moving logs" | tee -a $logfile;
  echo "- $cmd"      | tee -a $logfile;
  eval $cmd;
  logfile="${count_aux_export_dir}/logs/${logfile_name}";

  cmd="cd ${cwd}";
  echo "Changing back to cwd" | tee -a $logfile;
  echo "- $cmd"               | tee -a $logfile;
  eval $cmd;
fi
# end count ==========================================================================================
# ====================================================================================================
# vdj
# ====================================================================================================
if [ $do_vdj -eq 1 ]; then

  echo -e "\n\n=== Initilizing vdj at $(date) ===" | tee -a $logfile;

  if [ $do_demux -eq 1 ]; then
    fastq_paths=( "${fastq_export_paths[@]}" );
  else
    fastq_paths=( "${input_paths[@]}" );
  fi

  echo "Input paths: "                 | tee -a $logfile;
  printf '   %s\n' "${fastq_paths[@]}" | tee -a $logfile;

  vdj_dir="${tmp_dir}/vdj";
  cmd="mkdir -p ${vdj_dir} && cd ${vdj_dir}";
  echo "Creating and changing to vdj dir; $(date)" | tee -a $logfile;
  echo "- $cmd"                                    | tee -a $logfile;
  eval $cmd;

  if [ $output_cwd -eq 1 ]; then
    vdj_export_dir=${cwd};
  else
    vdj_export_dir="${cwd}/cellranger_vdj_${project_id}";
    cmd="mkdir ${vdj_export_dir};"
    echo "Creating vdj export dir" | tee -a $logfile;
    echo "- $cmd"                  | tee -a $logfile;
    eval $cmd;
    checkExitStatus "Failed creating export dir" "See $logfile for more details.";
  fi

  vdj_aux_export_dir="$vdj_export_dir/auxiliary";
  cmd="mkdir ${vdj_aux_export_dir};"
  echo "Creating auxiliary dir" | tee -a $logfile;
  echo "- $cmd"                 | tee -a $logfile;
  eval $cmd;
  checkExitStatus "Failed creating auxiliary dir" "See $logfile for more details.";

  if [ -z "$sample_names_param" ]; then
    sample_names=($(ls -1 ${fastq_paths[0]}));
  else
    sample_names=(${sample_names_param//,/ });
  fi

  echo "===================================================" | tee -a $logfile
  echo "vdj_dir            : $vdj_dir"             | tee -a $logfile
  echo "vdj_export_dir     : $vdj_export_dir"      | tee -a $logfile
  echo "vdj_aux_export_dir : $vdj_aux_export_dir"  | tee -a $logfile
  echo "cwd                : $cwd"                 | tee -a $logfile
  echo "log_dir            : $log_dir"             | tee -a $logfile
  echo "===================================================" | tee -a $logfile

  for sample_name in "${sample_names[@]}"; do

     if [[ $sample_name == Sample_* ]]; then
       sample_id=${sample_name:7}
     else
       sample_id=$sample_name
     fi
    echo -e "\n---- Processing input (name, id): ${sample_name}, ${sample_id} ---\n"  | tee -a $logfile;

     fastqs='';
     if [ ${#fastq_paths[@]} -eq 1 ]; then
       echo '- Single flowcell input'   | tee -a $logfile;
       fastqs="${fastq_paths[0]}/${sample_name}";
     else
       echo '- Multiple flowcell input' | tee -a $logfile;
       fastqs=$(printf "%s/${sample_name}," "${fastq_paths[@]}");
       fastqs=${fastqs%?};
     fi

    cmd="cellranger vdj --id=${sample_id} --fastqs=${fastqs} --reference=${ref_path} --sample=${sample_id} --description=${project_id} --disable-ui ${cores_mem_opts}";
    echo "- Running vdj; $(date)" | tee -a $logfile;
    echo "-- $cmd"                | tee -a $logfile;
    eval ${cmd} | tee -a $logfile
    checkExitStatus "Failed running vdj" "See $logfile for more details.";

    cmd="mv ${sample_id}/outs/web_summary.html ${vdj_export_dir}/${sample_id}_web_summary.html";
    # cmd="${cmd}; cp ${sample_id}/SC_VDJ_ASSEMBLER_CS/SC_VDJ_ASSEMBLER/SUMMARIZE_VDJ_REPORTS/fork0/files/alerts.json ${vdj_aux_export_dir}/alerts.json";
    echo "- Moving web summary to export" | tee -a $logfile;
    echo "-- $cmd"                        | tee -a $logfile;
    eval $cmd;

    echo "- Parsing stats" | tee -a $logfile;
    stats_keys=($(head -n 1 ${sample_id}/outs/metrics_summary.csv | tr '[:lower:]' '[:upper:]' | sed 's/ /_/g' | sed 's/[^A-Za-z_,]//g' | awk 'BEGIN {FS=","} {for(i=1;i<=NF;i++)print $i}'));
    stats_vals_line=$(tail -n 1 ${sample_id}/outs/metrics_summary.csv);
    i=0;
     stats_pairs=();
    # if int values are greater than 999, commas are used and values are quoted, eg. 1,2,"333,000",4,5
    if [[ $stats_vals_line =~ "\"" ]]; then
      stats_vals=($(echo $stats_vals_line | awk 'BEGIN {FS="\",\""} {for(i=1;i<=NF;i++)print $i}' |  awk 'BEGIN {FS="\""} {for(i=1;i<=NF;i++)print $i}'));
    else
      stats_vals=(${stats_vals_line//,/ });
    fi

    for stats_val in "${stats_vals[@]}"; do
      if ! [[ $stats_val =~ [0-9]+ ]]; then
        continue;
        ((i++));
      fi
      if ! [[ $stats_vals_line =~ "\"" ]]; then
        val=$(echo ${stats_val} | sed 's/[^0-9.]*//g');
        stats_pairs+=("${stats_keys[$i]}=${val}");
        ((i++));
      else
        # if this is a quoted csv line it doesn't start with a comma
        if [[ ${stats_val} != ,* ]]; then
          # remove all commas and percentage from int values
          val=$(echo ${stats_val} | sed 's/[^0-9.]*//g');
          stats_pairs+=("${stats_keys[$i]}=${val}");
          ((i++));
        else
          unquoted_vals=(${stats_val//,/ });
          for unquoted_val in "${unquoted_vals[@]}"; do
            val=$(echo ${unquoted_val} | sed 's/[^0-9.]*//g');
            stats_pairs+=("${stats_keys[$i]}=${val}");
            ((i++));
          done
        fi
      fi
    done

    stats_pair_uri='';
    for stats_pair in "${stats_pairs[@]}"; do
      stats_pair_uri="${stats_pair_uri}${stats_pair}&";
    done

     stats_pair_uri="${stats_pair_uri%?}";

    # echo "- Updating LIMS"       | tee -a $logfile;
    echo "cellranger vdj stats are not yet kept in lims, but if they were..." | tee -a $logfile
    echo "curl -X POST -i --data \"Library=${sample_id}&iLabs_Service_ID=${project_id}&${stats_pair_uri}\" ${lims_url}/${lims_composition}" | tee -a $logfile
    # curl -X POST -i --data "Library=${sample_id}&iLabs_Service_ID=${project_id}&${stats_pair_uri}" ${lims_url}/${lims_composition} -o $lims_result_file >> $logfile 2>&1
    echo "----"
    # if [[ $? -ne 0 ]]; then echo "WARNING:  failed to update LIMS with stats" | tee -a $logfile; fi  # checkExitStatus "Failed to save stats to LIMS"
    # # check response
    # if [[ -e "${lims_result_file}" ]]; then
    #   if [ $(grep '200 OK' $lims_result_file | wc -l) -ne "1" ]; then
    #     echo "** WARNING: LIMS did not update:" | tee -a $logfile
    #     cat ${lims_result_file} | tee -a $logfile
    #     echo "**" | tee -a $logfile
    #   else
    #     echo "LIMS updated for $sample_id OK" | tee -a $logfile
    #   fi
    #   rm $lims_result_file
    # fi
    # extract alerts from web summary for seqmon email
    python3 ${bin_path}/extract_alarms_from_web_summary.py ${vdj_export_dir}/${sample_id}_web_summary.html > ${vdj_aux_export_dir}/alerts.json

    cmd="tar cfz ${vdj_export_dir}/${sample_id}.tgz ${sample_id}";
    echo "- Archiving sample dir to export" | tee -a $logfile;
    echo "-- $cmd"                          | tee -a $logfile;
    eval $cmd;
  done

  echo -e "=== Completed vdj at $(date) ===\n\n" | tee -a $logfile;

  cmd="mv ${log_dir} ${vdj_aux_export_dir}/";
  echo "Moving logs" | tee -a $logfile;
  echo "- $cmd"      | tee -a $logfile;
  eval $cmd;
  logfile="${vdj_aux_export_dir}/logs/${logfile_name}";

  cmd="cd ${cwd}";
  echo "Changing back to cwd" | tee -a $logfile;
  echo "- $cmd"               | tee -a $logfile;
  eval $cmd;

fi
# end vdj ============================================================================================

if [ $purge -eq 1 ]; then
  cmd="rm -R ${tmp_dir}";
  echo "Purging tmp" | tee -a $logfile;
  echo "- $cmd"      | tee -a $logfile;
  eval $cmd;
fi

echo -e "\n\n=== Completed $PIPELINE_NAME pipeline at $(date) ===\n\n" | tee -a $logfile;
exit 0;
