# CellRanger multi pipeline

## Introduction

The initial overall vision for this project is to create a workflow starting with sequencing data (a run directory)
and ending with visualization of the pipeline results in Metabase.

- [Cell Ranger for Immune Profiling](https://support.10xgenomics.com/single-cell-vdj/software/pipelines/latest/what-is-cell-ranger)
- [Cellranger multi](https://support.10xgenomics.com/single-cell-vdj/software/pipelines/latest/using/multi)
  - cellranger multi can run, with one command line and an appropriate samplesheet, different types of samples such as 5'GEX, 5' VDJ, and Feature Barcoding

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

## Generating a sample sheet

- given one or more run id(s)
  - fetch flowcell design from EpiLIMS using API
  - e.g.
  ```bash
  curl https://abc.med.cornell.edu/epilims/rest/SeqmonDatasheet?run_id=201222_A00814_0327_BHY2C5DRXX
  curl -i https://abc.med.cornell.edu/epilims/rest/SeqmonDatasheet?run_id=201222_A00814_0327_BHY2C5DRXX
  curl -o 201222_A00814_0327_BHY2C5DRXX_flowcelldesign.json https://abc.med.cornell.edu/epilims/rest/SeqmonDatasheet?run_id=201222_A00814_0327_BHY2C5DRXX
  ```
- from flowcell design data, generate a samplesheet
  - e.g.
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



...
