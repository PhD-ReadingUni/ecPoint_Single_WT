import sys as sys
import os as os
import numpy as np
import numpy.polynomial.polynomial as poly
import pandas as pd
import metview as mv
from datetime import datetime, date, timedelta
import matplotlib.pyplot as plt
from scipy import stats
from scipy.stats import norm

# INPUT PARAMETERS
BaseDateS = date(2020,10,1)
BaseDateF = date(2021,9,30)
BaseTime = 0
StepF = int(sys.argv[1])
Acc = 12
Thr = float(sys.argv[2])
SystemFC = sys.argv[3]  # valid values are "ENS", "ecPoint_Multiple_WT", "ecPoint_Single_WT"
GitRepo = "/vol/ecpoint/mofp/PhD/Papers2Write/ecPoint_Single_WT"
DirIN_OBS = "Data/Raw/OBS"
DirIN_FC = "Data/Raw/FC"
DirOUT_CT = "Data/Processed/CT"
#####################################################################################################################


##############################
# SETTING GENERAL PARAMETERS #
##############################

# Setting parameters related to the considered verification period and the considered threshold
BaseDateSSTR = BaseDateS.strftime("%Y%m%d")
BaseDateFSTR = BaseDateF.strftime("%Y%m%d")
BaseTimeSTR = f'{BaseTime:02d}'
ThrSTR = str(Thr)

# Setting parameters related to the considered steps
StepS = StepF - Acc
StepSSTR = f'{StepS:03d}'
StepFSTR = f'{StepF:03d}'

# Setting parameters related to the considered accumulation period
AccSTR = f'{Acc:03d}'


if SystemFC == "ENS":
    NumEM = 51
elif SystemFC == "ecPoint_Multiple_WT" or SystemFC == "ecPoint_Single_WT":
    NumEM = 99

# Setting sub-directories
DirIN_FC = GitRepo + "/" + DirIN_FC + "/" + SystemFC
DirIN_OBS = GitRepo + "/" + DirIN_OBS
DirOUT_CT = GitRepo + "/" + DirOUT_CT + "_" + AccSTR + "_" + BaseDateSSTR + "_" + BaseDateFSTR + "_" + BaseTimeSTR + "/" + StepFSTR + "_" + ThrSTR

# Setting output files
FileOUT_H = DirOUT_CT + "/H_" + SystemFC + ".npy"
FileOUT_M = DirOUT_CT + "/M_" + SystemFC + ".npy"
FileOUT_FA = DirOUT_CT + "/FA_" + SystemFC + ".npy"
FileOUT_CN = DirOUT_CT + "/CN_" + SystemFC + ".npy"
######################################################################################################################################################


print(" ")
print("****************************")
print("Computing contingency tables")
print("****************************")
        
# Checking which forecasts and observations exceed the considered threshold
obs_thr_allDays = np.array([])
fc_thr_allDays = np.array([])

BaseDate = BaseDateS
while BaseDate <= BaseDateF:
    
    BaseDateSTR = BaseDate.strftime("%Y%m%d")
    
    # Defining the valid time for the observations
    VT = datetime.strptime(BaseDateSTR,"%Y%m%d") + timedelta(hours=BaseTime) + timedelta(hours=StepF)
    DateVT = VT.strftime("%Y%m%d")
    TimeVT = VT.strftime("%H")
    
    print(" ")
    print("Considering " + SystemFC + " rainfall forecasts for " + BaseDateSTR + ", " + BaseTimeSTR + " UTC, (t+" + str(StepS) + ",t+" + str(StepF) + ") for Thr=" + str(Thr) + "mm/" + str(Acc) + "h")
    print("Considering the correspondent rainfall observations (end of accumulation period): " + DateVT + " at " + TimeVT + " UTC")
    
    # Reading observations and checking which ones exceed the considered threshold
    FileIN_OBS = DirIN_OBS + "/" + DateVT + "/tp" + str(Acc) + "_obs_" + DateVT + TimeVT + ".geo"
    obs =  mv.read(FileIN_OBS)
    obs_thr = mv.values(obs) >= Thr
    NumObs = len(obs_thr)
    
    # Reading forecasts and checking which ones exceed the considered threshold
    if SystemFC == "ENS":
        FileIN_FC1 = DirIN_FC + "/" + BaseDateSTR + BaseTimeSTR + "/tp_" + BaseDateSTR + "_" + BaseTimeSTR + "_" + StepSSTR + ".grib"
        FileIN_FC2 = DirIN_FC + "/" + BaseDateSTR + BaseTimeSTR + "/tp_" + BaseDateSTR + "_" + BaseTimeSTR + "_" + StepFSTR + ".grib"
        fc1 = mv.read(FileIN_FC1)
        fc2 = mv.read(FileIN_FC2)
        fc = (fc2 - fc1) * 1000
    else:
        FileIN_FC = DirIN_FC + "/" + BaseDateSTR + BaseTimeSTR + "/Pt_BC_PERC_" + AccSTR + "_" + BaseDateSTR + "_" + BaseTimeSTR + "_" + StepFSTR + ".grib"
        fc = mv.read(FileIN_FC)
    
    fc_thr_temp = np.zeros([NumObs,NumEM])
    for indEM in range (0,NumEM):
        fc_obs = mv.values(mv.nearest_gridpoint(fc[indEM],obs))
        fc_thr_temp[:,indEM] = fc_obs >= Thr
    fc_thr = np.sum(fc_thr_temp, axis=1)  
    
    obs_thr_allDays = np.append(obs_thr_allDays,obs_thr, axis=0)
    fc_thr_allDays = np.append(fc_thr_allDays,fc_thr, axis=0)
    
    BaseDate += timedelta(days=1) 
    
    
# Computing the contingency table
H = np.zeros([NumEM+1,1])
FA = np.zeros([NumEM+1,1])
M = np.zeros([NumEM+1,1])
CN = np.zeros([NumEM+1,1])

for indEM in range (0,(NumEM+1)):
    H[indEM] = np.sum((fc_thr_allDays>=indEM)*(obs_thr_allDays==1))
    M[indEM] = np.sum((fc_thr_allDays<indEM)*(obs_thr_allDays==1))
    FA[indEM] = np.sum((fc_thr_allDays>=indEM)*(obs_thr_allDays==0))
    CN[indEM] = np.sum((fc_thr_allDays<indEM)*(obs_thr_allDays==0))

print("Saving the contingency tables for...")
if not os.path.exists(DirOUT_CT):
    os.makedirs(DirOUT_CT)
np.save(FileOUT_H, H)
np.save(FileOUT_M, M)
np.save(FileOUT_FA, FA)
np.save(FileOUT_CN, CN)
