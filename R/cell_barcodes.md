---
title: "Cell Barcodes"
author: "Jake Sauter"
date: "3/8/2021"
output: 
  html_document: 
    keep_md: true
---




```r
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
```



```r
ctrl_1_full_barcodes <- read.csv(ctrl_1_unfiltered_count_file) %>% unlist()
ctrl_1_cell_barcodes <- read.csv(ctrl_1_count_file) %>% unlist()
ctrl_1_vdj_barcodes <- rjson::fromJSON(file=ctrl_1_vdj_file) %>% unlist()
ctrl_1_multi_vdj_barcodes <- rjson::fromJSON(file=ctrl_1_multi_vdj_file) %>% unlist()
ctrl_1_multi_cell_barcodes <- read.csv(ctrl_1_multi_count_file) %>% unlist()
```


```r
cat('Number of unfiltered barcodes: ', length(ctrl_1_full_barcodes), '\n')
```

```
Number of unfiltered barcodes:  737279 
```

```r
cat('Number of cell-associated barcodes: ', length(ctrl_1_cell_barcodes))
```

```
Number of cell-associated barcodes:  9927
```


```r
if (length(setdiff(ctrl_1_cell_barcodes, ctrl_1_full_barcodes)) == 0) {
  cat('All cell-associated barcodes found within unfiltered barcodes\n')
}
```

```
All cell-associated barcodes found within unfiltered barcodes
```

```r
cat('Number of vdj called cells: ', length(ctrl_1_vdj_barcodes), '\n')
```

```
Number of vdj called cells:  4504 
```

```r
cat('Number of vdj called cells (with multi): ', length(ctrl_1_multi_vdj_barcodes))
```

```
Number of vdj called cells (with multi):  4408
```


```r
cat('Number of vdj called cells from cellranger vdj, filtered by cellranger count called cells: ', length(intersect(ctrl_1_cell_barcodes, ctrl_1_vdj_barcodes)))
```

```
Number of vdj called cells from cellranger vdj, filtered by cellranger count called cells:  4408
```


