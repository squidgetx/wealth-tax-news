# HPC initialization 
module load r/gcc/4.2.0
USER=saz310
mkdir -p /scratch/$USER/.cache/R/renv
echo "RENV_PATHS_ROOT=/scratch/$USER/.cache/R/renv" >> .Renviron


Rscript -e 'renv::init("."); renv::restore()'
