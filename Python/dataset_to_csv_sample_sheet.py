#!/bin/python

# Author: Jake Sauter
# File: dataset_to_csv_sample_sheet.py 
#
# Example: python3.6 dataset_to_csv_sample_sheet.py --dataset_uid='demux_2200422_201028_A00814_0296_AHVKWTDMXX_EC-LV-6398__uid16974'
#
#
# Input: 
#        Dataset UID (Example: demux_2200422_201028_A00814_0296_AHVKWTDMXX_EC-LV-6398__uid16974)
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
#    Submit cellranger multi command with generated sample sheet to queue


import os
import sys
import csv
import yaml
import json 
import getopt
import socket
import argparse
import subprocess
import regex as re


# Create the parser and add arguments
parser = argparse.ArgumentParser(description='Generate a cellranger multi sample csv sheet.')

parser.add_argument('--dataset_uid', type=str, 
    required=True, help='dataset uid to retrieve json from')

parser.add_argument('--reference_csv_list', 
                    help='references to be used for each experiment')

args = parser.parse_args()
print('DATASET_UID: ', args.dataset_uid)


PATH_TO_YAML='/home/aladdin/sequencing_monitor/current/config/config.yml'

# Remove lines containing ruby specific info
lines=[]
with open(PATH_TO_YAML,) as yaml_file:
  for line in yaml_file: 
    if not '!ruby/regexp' in line:
      lines.append(line)

config_data = yaml.safe_load(''.join(lines))

# >>> config_data.keys()
# dict_keys(['epicore09.pbtech', 'epicore04.med.cornell.edu', 
# ':alerts', ':brand', ':app', ':seqbrowser', ':illumina_report', 
# ':maintenance', ':roles', ':repository', ':mail', ':jobs', ':pipelines'])


dataset_uid = args.dataset_uid  
# dataset_uid = 'demux_2200422_201028_A00814_0296_AHVKWTDMXX_EC-LV-6398__uid16974'

project_id = [x for x in re.findall('[0-9A-Z-]*', 
                                    re.findall('_[0-9A-Z-]*__uid', dataset_uid)[0]) 
              if x != ''][0]

get_dataset_cmd = "curl " + \
    "https://abc.med.cornell.edu/sequencing_monitor/uid/" + dataset_uid + ".json"
direct_output = subprocess.check_output(get_dataset_cmd, shell=True)
dataset_info = json.loads(direct_output)

dataset_fastq_path = os.path.join(dataset_info['dataset']['path'],
                                  dataset_info['dataset']['uid'], 
                                  'Project_' + project_id) 

run_data = json.loads(dataset_info['job']['flowcell_design'])

# >>> run_data.keys()
# dict_keys(['flowcellid', 'flowcellinst', 'valid', 'display',
#                  'problems', 'warnings', 'lanes', 'libraries'])

# Goal: Find experiment names of all libraries
# with the same iLab service id

libs = run_data['libraries']
libs_keys = list(libs.keys())
service_ids = [""]*len(libs)
library_names = [""]*len(libs)
library_types = [""]*len(libs)

for i in range(len(libs)):
  service_ids[i] = libs[libs_keys[i]]["iLabs_Service_ID"]
  library_names[i] = libs[libs_keys[i]]["Library_Name"]
  library_types[i] = libs[libs_keys[i]]["Library_Type"]


unique_service_ids = set(service_ids)

service_id_groups = dict()

for uniq_serv_id in unique_service_ids: 
  cur_group = []
  for key in libs.keys():
    if libs[key]["iLabs_Service_ID"] == uniq_serv_id:
      cur_group.append(key)
  service_id_groups[uniq_serv_id] = cur_group


# Have determined groups by iLab_Service_ID, now
# for each group of iLab_Service_IDs, lets check 
# if we have any vdj, gex combinations

def find_prefixes(library_names):
  prefixes = set()
  for lib_name in library_names:
    prefix = lib_name.split('-')[0]
    prefixes.add(prefix)
  return sorted([x for x in prefixes])

def filter_sets(potential_sets):
  accepted_sets = {}
  # TODO: allow for selective 
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

def find_similar_experiments(library_names): 
  prefixes = find_prefixes(library_names)
  sets = {} 
  for prefix in prefixes: sets[prefix] = []
  
  for lib_name in library_names: 
    
    # TODO: Go off of library assay in the future, though 
    #  for the development dataset, the library assay is not correct, 
    #  so going off library name for now
    lib_base_name = lib_name.split('-')[0]
    
    if lib_base_name in prefixes: 
      sets[lib_base_name].append(lib_name)
  
  return filter_sets(sets)


accepted_sets = []
for key, service_id_group in service_id_groups.items(): 
  library_names = [libs[key]['Library_Name'] for key in service_id_group]
  sets = find_similar_experiments(library_names)
  if len(sets) > 0:
    accepted_sets.append(sets)

# Merging dictionaries
accepted_sets = {k:v for x in accepted_sets for k,v in x.items()} 
      
# Now for each pair in the accepted_pairs, list, form the sample
# sheet and command needed for cellranger multi 

## TODO: write to include feature barcoding if we want. For now
# going to make it a lot easier to just support VDJ + Gex always

def generate_sample_sheet_for_set(exp_names, fastqs, refpaths, outdir):
  fields = ['fastq_id',	'fastqs',	'lanes', 'feature_types']

  filename=outdir+'/cellranger_multi_config_' + exp_names['gex'] + \
            '_' + exp_names['vdj'] + '.csv'
      
  with open(filename, 'w') as csvfile:  
      csvwriter = csv.writer(csvfile)
      csvwriter.writerow(['[gene-expression]', '', '', ''])
      csvwriter.writerow(['reference', refpaths['gex'], '', ''])
      csvwriter.writerow(['[vdj]', '', '', ''])  
      csvwriter.writerow(['reference', refpaths['vdj'], '', ''])  
      csvwriter.writerow(['[libraries]', '', '', ''])  
      csvwriter.writerow(fields)  
      csvwriter.writerow([exp_names['gex'], fastqs['gex'], ' ', 'gene expression']) 
      csvwriter.writerow([exp_names['vdj'], fastqs['vdj'], ' ', 'vdj']) 
  
  return(filename)

def determine_reference_from_config_data(config_data, lib_entries): 
  
  refpaths = {'gex': '', 'vdj': ''}
  
  cell_ranger_count = config_data[":pipelines"][":cellranger_count"]
  cell_ranger_vdj = config_data[":pipelines"][":cellranger_vdj"]
  
  refpaths['gex'] = cell_ranger_count[':genomedir']
  refpaths['vdj'] = cell_ranger_vdj[':genomedir']
  
  organism = lib_entries['gex']['Organism'].lower()
  
  if ('mouse' in organism) or ('mus' in organism):
    organism_scientific = "Mus_musculus"
  elif ('human' in organism) or ('homo' in organism): 
    organism_scientific="Homo_sapiens"
  
  gex_reference_genomes = cell_ranger_count[":genomes"][organism_scientific][0]
  gex_reference_genomes = {v:k for k,v in gex_reference_genomes.items()}
  gex_genome_build = lib_entries['gex']['Genome_Build']
  
  if len(gex_reference_genomes) == 1: 
    only_key = list(gex_reference_genomes.keys())[0]
    gex_genome_file = gex_reference_genomes[only_key]
  else: 
    gex_genome_file = gex_reference_genomes[gex_genome_build]
  
  print('Using GEX Reference File: : ' + gex_genome_file)
  
  vdj_reference_genomes = cell_ranger_vdj[":genomes"][organism_scientific][0]
  vdj_reference_genomes = {v:k for k,v in vdj_reference_genomes.items()}
  vdj_genome_build = lib_entries['vdj']['Genome_Build']
  
  if len(vdj_reference_genomes) == 1: 
    only_key = list(vdj_reference_genomes.keys())[0]
    vdj_genome_file = vdj_reference_genomes[only_key]
  else: 
    vdj_genome_file = vdj_reference_genomes[vdj_genome_build]
    
  print('Using VDJ Reference File: : ' + vdj_genome_file)
  
  refpaths['gex'] = os.path.join(refpaths['gex'], organism_scientific, gex_genome_file)
  refpaths['vdj'] = os.path.join(refpaths['vdj'], organism_scientific, vdj_genome_file)
  
  if not os.path.exists(refpaths['gex']):
    sys.exit('Path to reference does not exist: ', refpaths['gex'])
  
  if not os.path.exists(refpaths['vdj']):
    sys.exit('Path to reference does not exist: ', refpaths['vdj'])
  
  
  return refpaths

# TODO: This will most likely change
#   during integration
# Set the CSV output directory
outdir = 'cellranger_multi_config_csvs'
os.system('mkdir ' + outdir)

output_command = ""

for acc_set in accepted_sets.values(): 
  
  print("\nProcessing experiment pair: ", acc_set)

  vdj_exp_name = [x for x in acc_set if 
        re.search('ig|vdj', x.lower()) is not None][0]

  gex_exp_name = [x for x in acc_set if 
        re.search('gex', x.lower()) is not None][0]


  def map_name_to_key(name):
    keys = [x for x in libs.keys()]
    names = [libs[key]['Library_Name'] for key in keys]
    return keys[names.index(name)]

  lib_entries = {'gex': libs[map_name_to_key(gex_exp_name)], 
                  'vdj': libs[map_name_to_key(vdj_exp_name)]}


  ref_paths = determine_reference_from_config_data(config_data, lib_entries)

  gex_fastq_path = \
    os.path.join(dataset_fastq_path,
                 'Sample_' + gex_exp_name) 
  vdj_fastq_path = \
    os.path.join(dataset_fastq_path, 
                 'Sample_' + vdj_exp_name) 
  
  exp_names = {'gex': gex_exp_name, 
               'vdj': vdj_exp_name}
  

  fastq_files = {'gex': gex_fastq_path, 
                 'vdj': vdj_fastq_path}
  
  csv_samplesheet = generate_sample_sheet_for_set(exp_names, fastq_files, ref_paths, outdir)
  
  output_command = output_command + \
                  'cellranger multi --id=MULTI_' + gex_exp_name + '_' + \
                   vdj_exp_name + ' \\\n' + \
                  ' --csv=' + csv_samplesheet + ' \\\n' + \
                  " --disable-ui" + '\n\n'


print('\n\n\nCellranger Multi Commands: \n\n' + output_command)
