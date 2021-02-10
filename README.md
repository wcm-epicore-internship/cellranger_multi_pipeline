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

- we didn't have any 5GE:VDJ run with cellranger 5.0, so I ran a couple
- there are 12 samples in this project:  6 5GE + 6 VDJ
- fastqs are located here:

```bash
/athena/epicore/ops/scratch/analysis/store100/demux_2200422_201028_A00814_0296_AHVKWTDMXX_EC-LV-6398__uid16974/Project_EC-LV-6398
```

- I ran one of each through cellranger 5.0, located here:

```bash
/scratch001/thk2008/cellranger5/Project_EC-LV-6398
└── Project_EC-LV-6398
    ├── count
    │   └── MYD88_3-GEX
    │       └── ...
    ├── fastqs
    │   ├── Sample_MYD88_3-GEX
    │   |   └── ...
    │   └── Sample_MYD88_3-Ig
    │       └── ...
    └── vdj
        └── MYD88_3-Ig
            └── ...
```

- with these commands:

```bash
# count
/opt/cellranger-5.0.0/bin/cellranger count --id=MYD88_3-GEX --fastqs=/scratch001/thk2008/cellranger5/Project_EC-LV-6398/fastqs/Sample_MYD88_3-GEX --transcriptome=/athena/epicore/ops/scratch/genomes/indices/Mus_musculus/refdata-gex-mm10-2020-A --sample=MYD88_3-GEX --description=EC-LV-6398 --disable-ui --localcores=16 --localmem=128
# vdj
/opt/cellranger-5.0.0/bin/cellranger vdj --id=MYD88_3-Ig --fastqs=/scratch001/thk2008/cellranger5/Project_EC-LV-6398/fastqs/Sample_MYD88_3-Ig --reference=/athena/epicore/ops/scratch/genomes/indices/Mus_musculus/refdata-cellranger-vdj-GRCm38-alts-ensembl-5.0.0 --sample=MYD88_3-Ig --description=EC-LV-6398 --disable-ui --localcores=16 --localmem=128

```

- the cellranger 3 pipeline output is here:
- MYD88_3-GEX

   ```bash
   /athena/epicore/ops/scratch/analysis/store100/cellranger_count_201028_A00814_0296_AHVKWTDMXX_MYD88_3-GEX__uid16993
   ```

- MYD88_3-Ig

   ```bash
   /athena/epicore/ops/scratch/analysis/store100/cellranger_vdj_201028_A00814_0296_AHVKWTDMXX_MYD88_3-Ig__uid16998
   ```

- there are small differences in the output
  - MYD88_3-GEX count
    - `/scratch001/thk2008/cellranger5/Project_EC-LV-6398/count/MYD88_3-GEX/outs/web_summary.html`
    - `/athena/epicore/ops/scratch/analysis/store100/cellranger_count_201028_A00814_0296_AHVKWTDMXX_MYD88_3-GEX__uid16993/MYD88_3-GEX_web_summary.html`

  - MYD88_3-Ig
    - `/scratch001/thk2008/cellranger5/Project_EC-LV-6398/vdj/MYD88_3-Ig/outs/web_summary.html`
    - `/athena/epicore/ops/scratch/analysis/store100/cellranger_vdj_201028_A00814_0296_AHVKWTDMXX_MYD88_3-Ig__uid16998/MYD88_3-Ig_web_summary.html`

My hope is that, given the right sampelsheet, cellranger multi can do all 12 samples with one command.

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

## Sequencing monitor

[SeqMon](https://abc.med.cornell.edu/sequencing_monitor/)

```bash
# code base
/home/aladdin/sequencing_monitor/current

# config file with paths to reference genomes, pipelines and stuff
/home/aladdin/sequencing_monitor/current/config/config.yml

# example for cellranger count pipeline
/home/aladdin/sequencing_monitor/current/job_templates/cellranger_count/cellranger_count.qsub
```

## Pipeline

- Original demux
  - see datasheetToSamplesheet.rb

```bash
/home/aladdin/demux/current
```

- Working on new datasheetToSamplesheet for cellranger

```bash
/home/aladdin/cellranger/bin/datasheetToSamplesheet.rb
```

## Metrics to look at

- looking into a list of important metrics for data analysis

...
