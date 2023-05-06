#!/bin/bash 
#SBATCH --nodes=1                        # requests 3 compute servers
#SBATCH --cpus-per-task=2                # uses 1 compute core per task
#SBATCH --time=2:00:00
#SBATCH --mem=4GB
#SBATCH --job-name=congress-svm
#SBATCH --output=congress-model/congres-svm.out

module purge
module load r/gcc/4.2.0
Rscript congress-model/svm.R

