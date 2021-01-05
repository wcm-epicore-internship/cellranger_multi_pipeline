# CellRanger multi pipeline

## Introduction

The initial overall vision for this project is to create a workflow starting with sequencing data (a run directory)
and ending with visualization of the pipeline results in Metabase.

- [Cell Ranger for Immune Profiling](https://support.10xgenomics.com/single-cell-vdj/software/pipelines/latest/what-is-cell-ranger)
- [Cellranger multi](https://support.10xgenomics.com/single-cell-vdj/software/pipelines/latest/using/multi)

Some steps would include:

- creating a pipeline for running cellranger multi
  - generating a sample sheet for input to cellranger multi
  - saving stats to lims
  - standardizing output of pipeline
- creating a dashboard in metabase for data visualization and analysis

## Examples

In the exampes directory is the epicore cellranger pipeline that runs `cellranger mkfastq`, `cellranger count`, and `cellranger vdj`

...
