#!/bin/bash


################################
# Cellranger Single count runs
################################

/opt/cellranger-5.0.0/bin/cellranger count \
    --id=CTRL_1-GEX \
    --fastqs=/athena/epicore/ops/scratch/analysis/store100/demux_2200422_201028_A00814_0296_AHVKWTDMXX_EC-LV-6398__uid16974/Project_EC-LV-6398/Sample_CTRL_1-GEX \
    --transcriptome=/athena/epicore/ops/scratch/genomes/indices/Mus_musculus/refdata-gex-mm10-2020-A \
    --sample=CTRL_1-GEX --description=Sample_CTRL_1-gex --disable-ui --localcores=32 --localmem=256 > CTRL_1-gex_run_log.txt 2>&1

/opt/cellranger-5.0.0/bin/cellranger count \
    --id=CTRL_2-GEX \
    --fastqs=/athena/epicore/ops/scratch/analysis/store100/demux_2200422_201028_A00814_0296_AHVKWTDMXX_EC-LV-6398__uid16974/Project_EC-LV-6398/Sample_CTRL_2-GEX \
    --transcriptome=/athena/epicore/ops/scratch/genomes/indices/Mus_musculus/refdata-gex-mm10-2020-A \
    --sample=CTRL_2-GEX --description=Sample_CTRL_2-gex --disable-ui --localcores=32 --localmem=256 > CTRL_2-gex_run_log.txt 2>&1

/opt/cellranger-5.0.0/bin/cellranger count \
    --id=CTRL_3-GEX \
    --fastqs=/athena/epicore/ops/scratch/analysis/store100/demux_2200422_201028_A00814_0296_AHVKWTDMXX_EC-LV-6398__uid16974/Project_EC-LV-6398/Sample_CTRL_3-GEX \
    --transcriptome=/athena/epicore/ops/scratch/genomes/indices/Mus_musculus/refdata-gex-mm10-2020-A \
    --sample=CTRL_3-GEX --description=Sample_CTRL_3-gex --disable-ui --localcores=32 --localmem=256 > CTRL_3-gex_run_log.txt 2>&1


/opt/cellranger-5.0.0/bin/cellranger count \
    --id=MYD88_1-GEX \
    --fastqs=/athena/epicore/ops/scratch/analysis/store100/demux_2200422_201028_A00814_0296_AHVKWTDMXX_EC-LV-6398__uid16974/Project_EC-LV-6398/Sample_MYD88_1-GEX \
    --transcriptome=/athena/epicore/ops/scratch/genomes/indices/Mus_musculus/refdata-gex-mm10-2020-A \
    --sample=MYD88_1-GEX --description=Sample_MYD88_1-gex --disable-ui --localcores=32 --localmem=256 > MYD88_1-gex_run_log.txt 2>&1


/opt/cellranger-5.0.0/bin/cellranger count \
    --id=MYD88_2-GEX \
    --fastqs=/athena/epicore/ops/scratch/analysis/store100/demux_2200422_201028_A00814_0296_AHVKWTDMXX_EC-LV-6398__uid16974/Project_EC-LV-6398/Sample_MYD88_2-GEX \
    --transcriptome=/athena/epicore/ops/scratch/genomes/indices/Mus_musculus/refdata-gex-mm10-2020-A \
    --sample=MYD88_2-GEX --description=Sample_MYD88_2-gex --disable-ui --localcores=32 --localmem=256 > MYD88_2-gex_run_log.txt 2>&1

/opt/cellranger-5.0.0/bin/cellranger count \
    --id=MYD88_3-GEX \
    --fastqs=/athena/epicore/ops/scratch/analysis/store100/demux_2200422_201028_A00814_0296_AHVKWTDMXX_EC-LV-6398__uid16974/Project_EC-LV-6398/Sample_MYD88_3-GEX \
    --transcriptome=/athena/epicore/ops/scratch/genomes/indices/Mus_musculus/refdata-gex-mm10-2020-A \
    --sample=MYD88_3-GEX --description=Sample_MYD88_3-gex --disable-ui --localcores=32 --localmem=256 > MYD88_3-gex_run_log.txt 2>&1


################################
# Cellranger Single VDJ runs
################################


/opt/cellranger-5.0.0/bin/cellranger vdj \
    --id=CTRL_1-Ig \
    --fastqs=/athena/epicore/ops/scratch/analysis/store100/demux_2200422_201028_A00814_0296_AHVKWTDMXX_EC-LV-6398__uid16974/Project_EC-LV-6398/Sample_CTRL_1-Ig \
    --reference=/athena/epicore/ops/scratch/genomes/indices/Mus_musculus/refdata-cellranger-vdj-GRCm38-alts-ensembl-5.0.0 \
    --sample=CTRL_1-Ig --description=Sample_CTRL_1-Ig --disable-ui > CTRL_1-Ig_vdj_run_log.txt 2>&1

/opt/cellranger-5.0.0/bin/cellranger vdj \
    --id=CTRL_2-Ig \
    --fastqs=/athena/epicore/ops/scratch/analysis/store100/demux_2200422_201028_A00814_0296_AHVKWTDMXX_EC-LV-6398__uid16974/Project_EC-LV-6398/Sample_CTRL_2-Ig \
    --reference=/athena/epicore/ops/scratch/genomes/indices/Mus_musculus/refdata-cellranger-vdj-GRCm38-alts-ensembl-5.0.0 \
    --sample=CTRL_2-Ig --description=Sample_CTRL_2-Ig --disable-ui > CTRL_2-Ig_vdj_run_log.txt 2>&1

/opt/cellranger-5.0.0/bin/cellranger vdj \
    --id=CTRL_3-Ig \
    --fastqs=/athena/epicore/ops/scratch/analysis/store100/demux_2200422_201028_A00814_0296_AHVKWTDMXX_EC-LV-6398__uid16974/Project_EC-LV-6398/Sample_CTRL_3-Ig \
    --reference=/athena/epicore/ops/scratch/genomes/indices/Mus_musculus/refdata-cellranger-vdj-GRCm38-alts-ensembl-5.0.0 \
    --sample=CTRL_3-Ig --description=Sample_CTRL_3-Ig --disable-ui > CTRL_3-Ig_vdj_run_log.txt 2>&1

/opt/cellranger-5.0.0/bin/cellranger vdj \
    --id=MYD88_1-Ig \
    --fastqs=/scratch001/jns4001/cellranger5/Project_EC-LV-6398/fastqs/Sample_MYD88_1-Ig \
    --reference=/athena/epicore/ops/scratch/genomes/indices/Mus_musculus/refdata-cellranger-vdj-GRCm38-alts-ensembl-5.0.0 \
    --sample=MYD88_1-Ig --description=MYD88_1-Ig --disable-ui > MYD88_1-Ig_vdj_run_log.txt 2>&1

/opt/cellranger-5.0.0/bin/cellranger vdj \
    --id=MYD88_2-Ig \
    --fastqs=/scratch001/jns4001/cellranger5/Project_EC-LV-6398/fastqs/Sample_MYD88_2-Ig \
    --reference=/athena/epicore/ops/scratch/genomes/indices/Mus_musculus/refdata-cellranger-vdj-GRCm38-alts-ensembl-5.0.0 \
    --sample=MYD88_2-Ig --description=MYD88_2-Ig --disable-ui > MYD88_2-Ig_vdj_run_log.txt 2>&1

/opt/cellranger-5.0.0/bin/cellranger vdj \
    --id=MYD88_3-Ig \
    --fastqs=/scratch001/jns4001/cellranger5/Project_EC-LV-6398/fastqs/Sample_MYD88_3-Ig \
    --reference=/athena/epicore/ops/scratch/genomes/indices/Mus_musculus/refdata-cellranger-vdj-GRCm38-alts-ensembl-5.0.0 \
    --sample=MYD88_3-Ig --description=MYD88_3-Ig --disable-ui > MYD88_3-Ig_vdj_run_log.txt 2>&1


#####################################
# Cellranger Combined GEX + VDJ runs
#####################################


cellranger multi --id=CTRL_1-Ig_Gex \
    --csv=/home/jns4001/project_sandbox/multi_config_csvs/CTRL_1-multi-config_sample-sheet.csv \
    --disable-ui > cellranger_ctrl_1_multi_output.txt 2>&1

cellranger multi --id=CTRL_2-Ig_Gex \
    --csv=/home/jns4001/project_sandbox/multi_config_csvs/CTRL_2-multi-config_sample-sheet.csv \
    --disable-ui > cellranger_ctrl_2_multi_output.txt 2>&1

cellranger multi --id=CTRL_3-Ig_Gex \
    --csv=/home/jns4001/project_sandbox/multi_config_csvs/CTRL_3-multi-config_sample-sheet.csv \
    --disable-ui > cellranger_ctrl_3_multi_output.txt 2>&1

cellranger multi --id=MYD88_1-Ig_Gex \
    --csv=/home/jns4001/project_sandbox/multi_config_csvs/MYD88_1-Ig-multi-config_sample-sheet.csv \
    --disable-ui > cellranger_MYD88_1_multi_output.txt 2>&1

cellranger multi --id=MYD88_2-Ig_Gex \
    --csv=/home/jns4001/project_sandbox/multi_config_csvs/MYD88_2-Ig-multi-config_sample-sheet.csv \
    --disable-ui > cellranger_MYD88_2_multi_output.txt 2>&1

cellranger multi --id=MYD88_3-Ig_Gex \
    --csv=/home/jns4001/project_sandbox/multi_config_csvs/MYD88_3-Ig-multi-config_sample-sheet.csv \
    --disable-ui > cellranger_MYD88_3_multi_output.txt 2>&1