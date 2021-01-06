# CellRanger multi pipeline

## Introduction

The initial overall vision for this project is to create a workflow starting with sequencing data (a run directory)
and ending with visualization of the pipeline results in Metabase.

- [Cell Ranger for Immune Profiling](https://support.10xgenomics.com/single-cell-vdj/software/pipelines/latest/what-is-cell-ranger)
- [Cellranger multi](https://support.10xgenomics.com/single-cell-vdj/software/pipelines/latest/using/multi)
  - cellranger multi can run, with one command line and an appropriate samplesheet, different types of samples such as 5'GEX, 5'VDJ, and Feature Barcoding

Some steps would include:

- creating a pipeline for running cellranger multi
  - generating a sample sheet for input to cellranger multi
  - saving stats to lims
  - standardizing output of pipeline
- creating a dashboard in metabase for data visualization and analysis

## Examples

In the examples directory is the epicore cellranger pipeline (`cellranger.sh`) that runs:  `cellranger mkfastq`, `cellranger count`, and `cellranger vdj`. It has some outdated code, but most of it is useful.

## Interactive server

epicore08.pbtech is our interactive server.

I suspect you will have to set a password. Try this:  [SCU Password reset](https://scu.med.cornell.edu/sspr)

You shouldn't be able to login to epi8 directly, so, login through the head node

```bash
ssh $CWID@pascal.med.cornell.edu
```

then

```bash
ssh epicore08.pbtech
```

It would be a good idea to make a working directory

```bash
/scratch001/$USER
```

## Example datasets and cellranger commands

- half cellranger demux - 2 lanes of data

  ```bash
  /athena/epicore/ops/scratch/analysis/store100/demux_2200422_201203_A00814_0313_AHM5KKDSXY_EC-MM-6428__uid17050
  ```

- full cellranger demux - 4 lanes of data

  ```bash
  /athena/epicore/ops/scratch/analysis/store100/demux_2200422_201203_A00814_0313_AHM5KKDSXY_EC-MM-6428__uid17114
  ```

- pipeline cellranger count command
  - from `/athena/epicore/ops/scratch/analysis/store100/external_cellranger_count_201203_A00814_0313_AHM5KKDSXY_EC-MM-6428__uid17128/auxiliary/logs/cellranger-2020-12-10.log`

  ```bash
  cellranger.sh -c -x 32 -y 256 -i /athena/epicore/ops/scratch/analysis/store100/demux_2200422_201203_A00814_0313_AHM5KKDSXY_EC-MM-6428__uid17114/Project_EC-MM-6428 -p EC-MM-6428 -t /athena/epicore/ops/scratch/genomes/indices/Mus_musculus/refdata-cellranger-mm10-3.0.0
  ```

- straight cellranger count command

  ```bash
  cellranger count --id=IL10_A-GEX --fastqs=/athena/epicore/ops/scratch/analysis/store100/demux_2200422_201203_A00814_0313_AHM5KKDSXY_EC-MM-6428__uid17114/Project_EC-MM-6428/Sample_IL10_A-GEX --transcriptome=/athena/epicore/ops/scratch/genomes/indices/Mus_musculus/refdata-cellranger-mm10-3.0.0 --sample=IL10_A-GEX --description=EC-MM-6428 --disable-ui --localcores=32 --localmem=256
  ```

- pipeline cellranger vdj command
  - from `/athena/epicore/ops/scratch/analysis/store100/cellranger_vdj_201203_A00814_0313_AHM5KKDSXY_IL10_A-TCR__uid17125/auxiliary/logs/cellranger-2020-12-10.log`

  ```bash
  cellranger.sh -j -o -x 16 -y 128 -i /athena/epicore/ops/scratch/analysis/store100/demux_2200422_201203_A00814_0313_AHM5KKDSXY_EC-MM-6428__uid17114/Project_EC-MM-6428 -p EC-MM-6428 -s Sample_IL10_A-TCR -t /athena/epicore/ops/scratch/genomes/indices/Mus_musculus/refdata-cellranger-vdj-GRCm38-alts-ensembl-4.0.0
  ```

- plain cellranger vdj command

  ```bash
  cellranger vdj --id=IL10_A-TCR --fastqs=/athena/epicore/ops/scratch/analysis/store100/demux_2200422_201203_A00814_0313_AHM5KKDSXY_EC-MM-6428__uid17114/Project_EC-MM-6428/Sample_IL10_A-TCR --reference=/athena/epicore/ops/scratch/genomes/indices/Mus_musculus/refdata-cellranger-vdj-GRCm38-alts-ensembl-4.0.0 --sample=IL10_A-TCR --description=EC-MM-6428 --disable-ui --localcores=16 --localmem=128 | tee -a logs/cellranger-2020-12-10.log
  ```

## Generating a sample sheet

- cellranger multi expects a multi config CSV
- given one or more run id(s)
  - fetch flowcell design from EpiLIMS using API
  - e.g.
  ```bash
  curl https://abc.med.cornell.edu/epilims/rest/SeqmonDatasheet?run_id=201222_A00814_0327_BHY2C5DRXX
  curl -i https://abc.med.cornell.edu/epilims/rest/SeqmonDatasheet?run_id=201222_A00814_0327_BHY2C5DRXX
  curl -o 201222_A00814_0327_BHY2C5DRXX_flowcelldesign.json https://abc.med.cornell.edu/epilims/rest/SeqmonDatasheet?run_id=201222_A00814_0327_BHY2C5DRXX
  ```

- maybe 201203_A00814_0313_AHM5KKDSXY EC-MM-6428

- from flowcell design data, generate a samplesheet
  - mkfastq sample sheet e.g.

  ```bash
  [Data]
  Lane,Sample_ID,Sample_Name,index,index2,Sample_Project
  1,Sample_IFN28_3P_gex,IFN28_3P_gex,SI-TT-A1,SI-TT-A1,Project_EC-SR-6444
  1,Sample_IFN28_5P_gex,IFN28_5P_gex,SI-TT-A3,SI-TT-A3,Project_EC-SR-6445
  ```

  ```bash
  [Data]
  Lane,Sample_ID,Sample_Name,index,index2,Sample_Project
  1,Sample_HTO-3P,HTO-3P,GTCTGTGAGG,,Project_EC-SR-6444
  1,Sample_GOT-CALR-3P,GOT-CALR-3P,GGCTATAAGT,,Project_EC-SR-6444
  1,Sample_ADT-3P,ADT-3P,GAGTCTGGTG,,Project_EC-SR-6444
  1,Sample_GOT-XBP1-3P,GOT-XBP1-3P,AAATTAGAGG,,Project_EC-SR-6444
  ```

## Pipeline

- ...

## Metrics to look at

- looking into a list of important metrics for data analysis

...
