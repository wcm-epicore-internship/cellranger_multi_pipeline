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

parser.add_argument('--run_id', type=str, 
    required=True, help='run_id to retrieve flowcell_design.json from')

parser.add_argument('--reference_csv_list', 
                    help='references to be used for each experiment')

args = parser.parse_args()
print('RUN_ID: ', args.run_id)



## TODO: Remove after development
if socket.gethostname() == 'spaceship':
  PATH_TO_YAML='/home/x1/Documents/Weill_Cornell/Spring_Project/stuff_to_sftp/config.yml'
else: 
  PATH_TO_YAML='/home/aladdin/sequencing_monitor/current/config/config.yml'

# Remove lines containing ruby specific info
lines=[]
with open(PATH_TO_YAML,) as yaml_file:
  for line in yaml_file: 
    if not '!ruby/regexp' in line:
      lines.append(line)

config_data = yaml.safe_load(''.join(lines))

print(config_data.keys())

# >>> config_data.keys()
# dict_keys(['epicore09.pbtech', 'epicore04.med.cornell.edu', 
# ':alerts', ':brand', ':app', ':seqbrowser', ':illumina_report', 
# ':maintenance', ':roles', ':repository', ':mail', ':jobs', ':pipelines'])

## TODO: Should I even be curling for this? Maybe I can get just as 
# a filepath and get it on the system. This does work though as 
# only with a run_id I can curl without saving a file and load into 
# a python dict

# TODO: Remove after development
if socket.gethostname() == 'spaceship':
  json_file = "/home/x1/Documents/Weill_Cornell/Spring_Project/working_flowcelldesign.json"
  with open(json_file, 'r') as f: 
    data = json.load(f)
else: 
  get_flowcell_cmd = "curl " + \
      "https://abc.med.cornell.edu/epilims/rest/SeqmonDatasheet?run_id=" + args.run_id
  direct_output = subprocess.check_output(get_flowcell_cmd, shell=True)
  data = json.loads(direct_output)


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

  filename='cellranger_config_csvs/cellranger_multi_config_' + exp_names[0] + \
            '_' + exp_names[1] + '.csv'
      
  with open(filename, 'w') as csvfile:  
      csvwriter = csv.writer(csvfile)
      csvwriter.writerow(['[gene-expression]', '', '', ''])
      csvwriter.writerow(['reference', gex_ref_path, '', ''])
      csvwriter.writerow(['[vdj]', '', '', ''])  
      csvwriter.writerow(['reference', vdj_ref_path, '', ''])  
      csvwriter.writerow(fields)  
      for i in range(len(exp_names)):
        if 'ig' in exp_names[i].lower(): 
          feature_type = 'vdj'
        else:
          feature_type='gene expression'
        csvwriter.writerow([exp_names[i], fastqs[exp_names[i]], ' ', feature_type]) 


# Get Fastq files 
# TODO: Ask Thadeous for the best way to do this

def fetch_fastq_file_names(run_id, exp_name): 
  file_systems = config_data['epicore09.pbtech'][':filesystems'][':analysis']

  relevant_dirs = []
  for fs in file_systems:
    dirs = os.listdir(fs)
    for dir in dirs: 
      if run_id in dir: 
        relevant_dirs.append(dir)

  print(relevant_dirs)


def determine_reference_from_config_data(config_data): 
  cell_ranger_count = config_data[":pipelines"][":cellranger_count"]
  cell_ranger_vdj = config_data[":pipelines"][":cellranger_vdj"]
  count_ref_seqs = cell_ranger_count[":genomes"]
  count_lib_entry = libs[map_name_to_key(gex_exp_name)]
  count_genome_dir = cell_ranger_count[':genomedir']
  vdj_genome_dir = cell_ranger_vdj[':genomedir']
  count_ref_seqs = cell_ranger_vdj[":genomes"]
  vdj_ref_seqs = cell_ranger_vdj[':genomes']


  organism = count_lib_entry['Organism'].lower()
  genome_build = count_lib_entry['Genome_Build']
  library_type = count_lib_entry['Library_Type']

  if ('mouse' in organism) or ('mus' in organism):
    organism_scientific = "Mus_musculus"
  elif ('human' in organism) or ('homo' in organism): 
    organism_scientific="Homo_sapiens"

  return organism_scientific


for acc_set in accepted_sets.values(): 

  print("Processing experimet pair: ", acc_set)

  vdj_exp_name = [x for x in acc_set if 
        re.search('ig|vdj', x.lower()) is not None][0]

  gex_exp_name = [x for x in acc_set if 
        re.search('gex', x.lower()) is not None][0]

  # TODO: 
  # get reference files: 
  # Organism + Genome_Build + Library_Type
  def map_name_to_key(name):
    keys = [x for x in libs.keys()]
    names = [libs[key]['Library_Name'] for key in keys]
    return keys[names.index(name)]

  cell_ranger_count = config_data[":pipelines"][":cellranger_count"]
  cell_ranger_vdj = config_data[":pipelines"][":cellranger_vdj"]
  count_genome_dir = cell_ranger_count[':genomedir']
  vdj_genome_dir = cell_ranger_vdj[':genomedir']

  organism_scientific = determine_reference_from_config_data(config_data)

  gex_ref_path = count_genome_dir + '/' + organism_scientific 
  vdj_ref_path = vdj_genome_dir + '/' + organism_scientific

  fastq_files = {gex_exp_name: "fastq_for_gex.fastq", 
                 vdj_exp_name: "fastq_for_vdj.fastq"}

  # fastq_files = fetch_fastq_file_names(args.run_id, exp_name)

  generate_sample_sheet_for_set(acc_set, fastq_files, gex_ref_path, vdj_ref_path)
  
