# epicore08
#export CELLRANGER_HOME=/opt/cellranger-3.1.0
#export CELLRANGER_HOME=/opt/cellranger-4.0.0
export CELLRANGER_HOME=/opt/cellranger-5.0.0
export PATH=$CELLRANGER_HOME${PATH+:$PATH}

#export CELLRANGER_REF_PATH=/athena/epicore/ops/scratch/genomes/cellranger/3.0.0

## slchoose bcl2fastq 2.17.1.14 gcc4_64
# export BCL2FASTQ_HOME=/softlib/exe/x86_64/pkg/bcl2fastq/2.17.1.14/gcc4_64
# export PATH=$BCL2FASTQ_HOME/bin${PATH+:$PATH}
spack load -r bcl2fastq2@2.20.0.422
spack load -r python@3.6.0%gcc@6.3.0

# is this needed?

## slchoose gcc 4.7.4 gcc4_64
# export GCC_HOME=/softlib/exe/x86_64/pkg/gcc/4.7.4/gcc4_64
# export PATH=$GCC_HOME/bin${PATH+:$PATH}
# export LD_LIBRARY_PATH=$GCC_HOME/lib64${LD_LIBRARY_PATH+:$LD_LIBRARY_PATH}
# export LD_LIBRARY_PATH=$GCC_HOME/lib${LD_LIBRARY_PATH+:$LD_LIBRARY_PATH}
# export MANPATH=$GCC_HOME/share/man${MANPATH+:$MANPATH}

# spack load -r gcc@6.3.0

# fastq-qc
# slchoose fastx_toolkit 0.0.13.2 gcc4_64_libgtextutils-0.6.1
#export FASTX_TOOLKIT_HOME=/softlib/exe/x86_64/pkg/fastx_toolkit/0.0.13.2/gcc4_64_libgtextutils-0.6.1
#export PATH=$FASTX_TOOLKIT_HOME/bin${PATH+:$PATH}
#export LD_LIBRARY_PATH=$FASTX_TOOLKIT_HOME/lib${LD_LIBRARY_PATH+:$LD_LIBRARY_PATH}
# slchoose fastqc 0.10.1 java
#export FASTQC_HOME=/softlib/exe/all/pkg/fastqc/0.10.1/java
#alias fastqc='$FASTQC_HOME/fastqc'
# slchoose R 2.15.2 gcc_64
#export R_HOME=/softlib/exe/x86_64/pkg/R/2.15.2/gcc_64
#export PATH=$R_HOME/bin${PATH+:$PATH}
# slchoose dedup 0.1.0 gcc4_64
#export DEDUP_HOME=/softlib/exe/x86_64/pkg/dedup/0.1.0/gcc4_64
#export PATH=$DEDUP_HOME/bin${PATH+:$PATH}
# slchoose sun_jdk 6.0.2 dist
#export JAVA_HOME=/softlib/exe/x86_64/pkg/sun_jdk/6.0.2/dist
#export PATH=$JAVA_HOME/bin${PATH+:$PATH}
