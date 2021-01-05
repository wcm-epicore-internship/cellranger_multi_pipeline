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

In the examples directory is the epicore cellranger pipeline (`cellranger.sh`) that runs:  `cellranger mkfastq`, `cellranger count`, and `cellranger vdj`

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

...
