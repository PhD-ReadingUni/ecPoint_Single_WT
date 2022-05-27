#!/bin/bash

###############
StepF_Start=132
StepF_Final=174
Step_Disc=6
###############

for StepF in $(seq ${StepF_Start} ${Step_Disc} ${StepF_Final}); do

    for Thr in 0.2 10 50; do
    
        for SystemFC in "ENS" "ecPoint_Multiple_WT"; do
        
            ${HOME}/runcode/sbatch /vol/ecpoint/mofp/PhD/Papers2Write/ecPoint_Single_WT/Scripts/Processed/CT.sh ${StepF} ${Thr} ${SystemFC}
            
        done
        
    done
    
done
