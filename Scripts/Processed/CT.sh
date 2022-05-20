#!/bin/bash

#SBATCH --qos=express
#SBATCH --workdir=/vol/ecpoint/LogLXC
#SBATCH --job-name=CT
#SBATCH --error=CT.%N.%j.out
#SBATCH --output=CT.%N.%j.out
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=mofp@ecmwf.int
#SBATCH --mem-per-cpu=10000

source /home/mo/${USER}/.profile

##########################################
# INPUT VARIABLES
set -eu

# Parameters related to the wrapper script
StepF=${StepF:=${1}}
Thr=${Thr:=${2}}
SystemFC=${SystemFC:=${3}}
##########################################

module load python3
python3 /vol/ecpoint/mofp/PhD/Papers2Write/ecPoint_Single_WT/Scripts/Processed/CT.py ${StepF} ${Thr} ${SystemFC}
