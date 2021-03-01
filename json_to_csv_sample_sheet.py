#!/bin/python

# Author: Jake Sauter
# File: json_to_csv_sample_sheet.py 
#
# Input: 
#        Run Id (Example: 201028_A00814_0296_AHVKWTDMXX)
#        gene expression reference (mapped from yaml)
#        vdj reference (mapped from yaml)
#
# Processing: 
#        wget flowcell design file with query from seqmon
#        map gex and vdj reference identifiers to file paths (from yaml)
#        determine path to fastq files for both vdj and gex experiments
#
# Output: sample_sheet.csv that can be used for calling cellranger multi


# Possibly in this script or by a script that uses this one: 
# 
# Submit cellranger multi command with generated sample sheet to queue
# thadeous sending code for datasheet to samplsheet (json processing) (ruby)


import os
from posix import listdir 
import sys
import csv
import yaml
import json 
import getopt


run_id=""
gex_reference=""
vdj_reference=""

try:
    opts, args = getopt.getopt(sys.argv,"hrgv:o:",
                      ["run_id=","gex_reference=","vdj_reference="])
except getopt.GetoptError:
    print('json_to_csv_sample_sheet.py -g <gex_reference> -v <vdj_reference>')
    sys.exit(2)
for opt, arg in opts:
    if opt == '-h':
      print('json_to_csv_sample_sheet.py -g <gex_reference> -v <vdj_reference>')
      sys.exit()
    elif opt in ("-r", "--run_id"):
      run_id = arg
    elif opt in ("-g", "--gex_reference"):
      gex_reference = arg
    elif opt in ("-v", "--vdj_reference"):
      vdj_reference = arg

print("run_id: ", run_id)
print("gex_refernce: ", gex_reference)
print("vdj_reference: ", vdj_reference)

PATH_TO_YAML='stuff_to_sftp/config.yml'

# Remove lines containing ruby specific info
lines=[]
with open(PATH_TO_YAML,) as yaml_file:
  for line in yaml_file: 
    if not '!ruby/regexp' in line:
      lines.append(line)

config_data = yaml.load(''.join(lines))

# >>> config_data.keys()
# dict_keys(['epicore09.pbtech', 'epicore04.med.cornell.edu', 
# ':alerts', ':brand', ':app', ':seqbrowser', ':illumina_report', 
# ':maintenance', ':roles', ':repository', ':mail', ':jobs', ':pipelines'])


flowcell_design_file =  run_id + "_flowcelldesign.json"

get_flowcell_cmd = "curl -o " + flowcell_design_file + \
  " https://abc.med.cornell.edu/epilims/rest/SeqmonDatasheet?run_id=" + run_id

os.system(get_flowcell_cmd)

with open(flowcell_design_file,) as f:
  data = json.load(f) 

# Goal: Find experiment names of all libraries
# with the same iLab service id

libs = data['libraries']
libs_keys = list(libs.keys())
service_ids = [""]*len(libs)
library_names = [""]*len(libs)
library_types = [""]*len(libs)

for i in range(len(libs)):
  service_ids[i] = libs[libs_keys[i]]["iLab_Service_ID"]
  library_names[i] = libs[libs_keys[i]]["Library_Name"]
  library_types[i] = libs[libs_keys[i]]["Library_Type"]


unique_service_ids = set(service_ids)

service_id_groups = dict()

for uniq_serv_id in unique_service_ids: 
  cur_group = []
  for key in libs.keys():
    if libs[key]["iLab_Service_ID"] == uniq_serv_id:
      cur_group.append(key)
  service_id_groups[uniq_serv_id] = cur_group


# Have determined groups by ilab service id, now
# for each group of iLabService id runs, lets check 
# if we have any vdj, gex combinations

# TODO: Want this to be able to incorporate feature barcoding 
# too, so might have to use a different design pattern than 
# this 

def find_prefixes(library_names):
  prefixes = set()
  for lib_name in library_names:
    prefix = lib_name.split('-')[0]
    prefixes.add(prefix)
  return sorted([x for x in prefixes])


def filter_sets(potential_sets):
  accepted_sets = {}
  accepted_suffix_list = ['gex', 'ig', 'fb']

  for key in potential_sets.keys():
    accepted_sets[key] = []

  for key, potential_set in potential_sets.items(): 
    for lib_name in potential_set: 
      lib_name_suffix = ''.join(lib_name.split('-')[1:]).lower()
      suffix_mask = [x in lib_name_suffix for x in accepted_suffix_list]

      if sum(suffix_mask) == 1: 
        accepted_sets[key].append(lib_name)

    if len(accepted_sets[key]) < 2: del accepted_sets[key]

  return accepted_sets

def find_similar(library_names): 
  prefixes = find_prefixes(library_names)
  sets = {} 
  for prefix in prefixes: sets[prefix] = []

  for lib_name in library_names: 
    lib_base_name = lib_name.split('-')[0]
    if lib_base_name in prefixes: 
      sets[lib_base_name].append(lib_name)

  return filter_sets(sets)


accepted_sets = []
for key, service_id_group in service_id_groups.items(): 
  library_names = [libs[key]['Library_Name'] for key in service_id_group]
  sets = find_similar(library_names)
  if len(sets) > 0:
    accepted_sets.append(sets)

# Merging dictionaries
accepted_sets = {k:v for x in accepted_sets for k,v in x.items()} 
      
# Now for each pair in the accepted_pairs, list, form the sample
# sheet and command needed for cellranger multi 


## TODO: write to include feature barcoding if we want. For now
# going to make it a lot easier to just support VDJ + Gex always

def generate_sample_sheet_for_set(exp_names, fastqs, gex_ref_path, vdj_ref_path):
  fields = ['fastq_id',	'fastqs',	'lanes', 'feature_types']
      
  with open(filename, 'w') as csvfile:  
      csvwriter = csv.writer(csvfile)
      csv.writerow(['[gene-expression]'])
      csv.writerow(['reference', gex_ref_path])
      csv.writerow(['[vdj]'])  
      csv.writerow(['reference', vdj_ref_path])  
      csvwriter.writerow(fields)  
      for i in range(len(exp_names)):
        if 'ig' in exp_set[i].lower(): 
          feature_type = 'vdj'
        else:
          feature_type='gene-expression'
        csvwriter.writerow([exp_names[i]], fastqs[i], ' ', feature_type) 

# Get Fastq files 
# TODO: Ask Thadeous for the best way to do this, other than 
# getting fastq files and figuring out how to choose the reference
# when building multiple cellranger multi runs from a single file
# then this could actually be a working utility that can recieve arguments
# as input and produce everything needed for a cellranger multi 
# command to run 

def fetch_fastq_file_names(run_id, exp_name): 
  file_systems = config_data['epicore09.pbtech'][':filesystems'][':analysis']

  relevant_dirs = []
  for fs in file_systems:
    dirs = os.listdir(fs)
    for dir in dirs: 
      if run_id in dir: 
        relevant_dirs.append(dir)

  print(relevant_dirs)


for acc_set in accepted_sets.values(): 

  # Determine which experiment is the vdj and which 
  # is the gene expression 
  vdj_exp_name = [x for x in acc_set if 
        re.search('ig|vdj', x.lower()) is not None][0]

  gex_exp_name = [x for x in acc_set if 
        re.search('gex', x.lower()) is not None][0]

  fastq_files = []

  # TODO: 
  # get reference files: 
  # Organism + Genome_Build + Library_Type
  def map_name_to_key(name):
    keys = [x for x in libs.keys()]
    names = [libs[key]['Library_Name'] for key in keys]
    return keys[names.index(name)]

  cell_ranger_count = config_data[":pipelines"][":cellranger_count"]
  cell_ranger_vdj = config_data[":pipelines"][":cellranger_vdj"]
  count_ref_seqs = cell_ranger_count[":genomes"]
  count_lib_entry = libs[map_name_to_key(gex_exp_name)]
  count_genome_dir = cell_ranger_count[':genomedir']
  vdj_genome_dir = cell_ranger_vdj[':genomedir']
  count_ref_seqs = cell_ranger_vdj[":genomes"]
  vdj_ref_seqs = cell_ranger_vdj[':genomes']


  organism = lib_entry['Organism'].lower()
  genome_build = lib_entry['Genome_Build']
  library_type = lib_entry['Library_Type']

  if ('mouse' in organism) or ('mus' in organism):
    organism_scientific = "Mus_musculus"
  elif ('human' in organism) or ('homo' in organism): 
    organism_scientific="Homo_sapiens"

  gex_ref_path = count_genome_dir + '/' + organism_scientific 
  vdj_ref_path = vdj_genome_dir + '/' + organism_scientific
  


  fastq_files.append(fetch_fastq_file_names(run_id, exp_name))
  generate_sample_sheet_for_set(acc_set, fastq_files, gex_ref_path, vdj_ref_path)
  
