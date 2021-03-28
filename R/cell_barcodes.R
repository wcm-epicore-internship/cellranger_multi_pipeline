
library(magrittr)

{
  base_dir <- '/home/x1/Documents/Weill_Cornell/Spring_Project/storage/cell_barcodes/'
  
  ctrl_1_unfiltered_count_file <-  paste0(base_dir, 'ctrl_1_unfiltered_count_barcodes.tsv')
  ctrl_2_unfiltered_count_file <-  paste0(base_dir, 'ctrl_2_unfiltered_count_barcodes.tsv')
  ctrl_3_unfiltered_count_file <-  paste0(base_dir, 'ctrl_3_unfiltered_count_barcodes.tsv')
  myd88_1_unfiltered_count_file <- paste0(base_dir, 'myd88_1_unfiltered_count_barcodes.tsv')
  myd88_2_unfiltered_count_file <- paste0(base_dir, 'myd88_2_unfiltered_count_barcodes.tsv')
  myd88_3_unfiltered_count_file <- paste0(base_dir, 'myd88_3_unfiltered_count_barcodes.tsv')
  
  ctrl_1_count_file <-  paste0(base_dir, 'ctrl_1_count_barcodes.tsv')
  ctrl_2_count_file <-  paste0(base_dir, 'ctrl_2_count_barcodes.tsv')
  ctrl_3_count_file <-  paste0(base_dir, 'ctrl_3_count_barcodes.tsv')
  myd88_1_count_file <- paste0(base_dir, 'myd88_1_count_barcodes.tsv')
  myd88_2_count_file <- paste0(base_dir, 'myd88_2_count_barcodes.tsv')
  myd88_3_count_file <- paste0(base_dir, 'myd88_3_count_barcodes.tsv')
  
  ctrl_1_vdj_file <-  paste0(base_dir, 'ctrl_1_vdj_barcodes.json')
  ctrl_2_vdj_file <-  paste0(base_dir, 'ctrl_2_vdj_barcodes.json')
  ctrl_3_vdj_file <-  paste0(base_dir, 'ctrl_3_vdj_barcodes.json')
  myd88_1_vdj_file <- paste0(base_dir, 'myd88_1_vdj_barcodes.json')
  myd88_2_vdj_file <- paste0(base_dir, 'myd88_2_vdj_barcodes.json')
  myd88_3_vdj_file <- paste0(base_dir, 'myd88_3_vdj_barcodes.json')
  
  ctrl_1_multi_vdj_file <-  paste0(base_dir, 'ctrl_1_multi_vdj_cell_barcodes.json')
  ctrl_2_multi_vdj_file <-  paste0(base_dir, 'ctrl_2_multi_vdj_cell_barcodes.json')
  ctrl_3_multi_vdj_file <-  paste0(base_dir, 'ctrl_3_multi_vdj_cell_barcodes.json')
  myd88_1_multi_vdj_file <- paste0(base_dir, 'myd88_1_multi_vdj_cell_barcodes.json')
  myd88_2_multi_vdj_file <- paste0(base_dir, 'myd88_2_multi_vdj_cell_barcodes.json')
  myd88_3_multi_vdj_file <- paste0(base_dir, 'myd88_3_multi_vdj_cell_barcodes.json')
  
  ctrl_1_multi_count_file <-  paste0(base_dir, 'ctrl_1_multi_count_barcodes.tsv')
  ctrl_2_multi_count_file <-  paste0(base_dir, 'ctrl_2_multi_count_barcodes.tsv')
  ctrl_3_multi_count_file <-  paste0(base_dir, 'ctrl_3_multi_count_barcodes.tsv')
  myd88_1_multi_count_file <- paste0(base_dir, 'myd88_1_multi_count_barcodes.tsv')
  myd88_2_multi_count_file <- paste0(base_dir, 'myd88_2_multi_count_barcodes.tsv')
  myd88_3_multi_count_file <- paste0(base_dir, 'myd88_3_multi_count_barcodes.tsv')
}

##################
## TODO ##
##################
# 1. Confirm that intersection of individual count and vdj barcodes are the 
#    barcodes returned from cellranger multi vdj -- DONE
#
# 2. Confirm that cellranger count barcodes are the same as barcodes returned
#    from multi (no change in amount or exact barcodes)
##################

#########################################################################
## CTRL 1 ##
#########################################################################
{
  ctrl_1_full_barcodes <- read.csv(ctrl_1_unfiltered_count_file) %>% unlist()
  ctrl_1_cell_barcodes <- read.csv(ctrl_1_count_file) %>% unlist()
  ctrl_1_vdj_barcodes <- rjson::fromJSON(file=ctrl_1_vdj_file) %>% unlist()
  ctrl_1_multi_vdj_barcodes <- rjson::fromJSON(file=ctrl_1_multi_vdj_file) %>% unlist()
  ctrl_1_multi_cell_barcodes <- read.csv(ctrl_1_multi_count_file) %>% unlist()
}

cat('Number of unfiltered barcodes: ', length(ctrl_1_full_barcodes))
cat('Number of cell-associated barcodes: ', length(ctrl_1_cell_barcodes))

if (length(setdiff(ctrl_1_cell_barcodes, ctrl_1_full_barcodes)) == 0) {
  cat('All cell-associated barcodes found within unfiltered barcodes')
}

cat('Number of vdj called cells: ', length(ctrl_1_vdj_barcodes))
cat('Number of vdj called cells (with multi): ', length(ctrl_1_multi_vdj_barcodes))

# Below we see that less cells are called with multi-vdj as the barcodes
# are the intersection of cell-called barcodes and vdj called barcodes

inter_barcodes <- intersect(ctrl_1_vdj_barcodes, ctrl_1_cell_barcodes)
length(inter_barcodes)
length(intersect(inter_barcodes, ctrl_1_multi_vdj_barcodes))
#########################################################################

#########################################################################
## CTRL 2 ##
#########################################################################
{
  ctrl_2_full_barcodes <- read.csv(ctrl_2_unfiltered_count_file) %>% unlist()
  ctrl_2_cell_barcodes <- read.csv(ctrl_2_count_file) %>% unlist()
  ctrl_2_vdj_barcodes <- rjson::fromJSON(file=ctrl_2_vdj_file) %>% unlist()
  ctrl_2_multi_cell_barcodes <- read.csv(ctrl_2_multi_count_file) %>% unlist()
}

length(ctrl_2_full_barcodes)
length(ctrl_2_cell_barcodes)
length(intersect(ctrl_2_cell_barcodes, ctrl_2_multi_cell_barcodes))
length(ctrl_2_vdj_barcodes)
length(intersect(ctrl_2_cell_barcodes, ctrl_2_vdj_barcodes))

# There is some barcode overlap between experiments
length(intersect(ctrl_1_cell_barcodes, ctrl_2_vdj_barcodes))
#########################################################################

#########################################################################
## CTRL 3 ##
#########################################################################
{
  ctrl_3_full_barcodes <- read.csv(ctrl_3_unfiltered_count_file) %>% unlist()
  ctrl_3_cell_barcodes <- read.csv(ctrl_3_count_file) %>% unlist()
  ctrl_3_vdj_barcodes <- rjson::fromJSON(file=ctrl_3_vdj_file) %>% unlist()
  ctrl_3_multi_cell_barcodes <- read.csv(ctrl_3_multi_count_file) %>% unlist()
}

length(ctrl_3_full_barcodes)
length(ctrl_3_cell_barcodes)
length(intersect(ctrl_3_cell_barcodes, ctrl_3_multi_cell_barcodes))

length(ctrl_3_vdj_barcodes)
length(intersect(ctrl_3_cell_barcodes, ctrl_3_vdj_barcodes))

#########################################################################


#########################################################################
## myd88 1 ##
#########################################################################
{
  myd88_1_full_barcodes <- read.csv(myd88_1_unfiltered_count_file) %>% unlist()
  myd88_1_cell_barcodes <- read.csv(myd88_1_count_file) %>% unlist()
  myd88_1_vdj_barcodes <- rjson::fromJSON(file=myd88_1_vdj_file) %>% unlist()
  myd88_1_multi_cell_barcodes <- read.csv(myd88_1_multi_count_file) %>% unlist()
}

length(myd88_1_full_barcodes)
length(ctrl_1_cell_barcodes)
length(myd88_1_vdj_barcodes)
length(intersect(myd88_1_cell_barcodes, myd88_1_vdj_barcodes))
length(intersect(myd88_1_cell_barcodes, myd88_1_multi_cell_barcodes))

#########################################################################

#########################################################################
## myd88 2 ##
#########################################################################
{
  myd88_2_full_barcodes <- read.csv(myd88_2_unfiltered_count_file) %>% unlist()
  myd88_2_cell_barcodes <- read.csv(myd88_2_count_file) %>% unlist()
  myd88_2_vdj_barcodes <- rjson::fromJSON(file=myd88_2_vdj_file) %>% unlist()
  myd88_2_multi_cell_barcodes <- read.csv(myd88_2_multi_count_file) %>% unlist()
}

length(myd88_2_full_barcodes)
length(ctrl_1_cell_barcodes)
length(myd88_2_vdj_barcodes)
length(intersect(myd88_2_cell_barcodes, myd88_2_vdj_barcodes))
length(intersect(myd88_2_cell_barcodes, myd88_2_multi_cell_barcodes))

#########################################################################


#########################################################################
## myd88 3 ##
#########################################################################
{
  myd88_3_full_barcodes <- read.csv(myd88_3_unfiltered_count_file) %>% unlist()
  myd88_3_cell_barcodes <- read.csv(myd88_3_count_file) %>% unlist()
  myd88_3_vdj_barcodes <- rjson::fromJSON(file=myd88_3_vdj_file) %>% unlist()
  myd88_3_multi_cell_barcodes <- read.csv(myd88_3_multi_count_file) %>% unlist()
}

length(myd88_3_full_barcodes)
length(myd88_3_cell_barcodes)
length(myd88_3_vdj_barcodes)
length(intersect(myd88_3_cell_barcodes, myd88_3_vdj_barcodes))
length(intersect(myd88_3_cell_barcodes, myd88_3_multi_cell_barcodes))
#########################################################################





