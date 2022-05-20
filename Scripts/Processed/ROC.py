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
StepF = 24
Acc = 12
Thr = 50.0
SystemFC_list = ["ENS", "ecPoint_Multiple_WT"]
GitRepo = "/vol/ecpoint/mofp/PhD/Papers2Write/ecPoint_Single_WT"
DirIN_CT = "Data/Processed/CT"
DirOUT_ROC = "Data/Processed/ROC"

#####################################################################################################################


########################
# FUNCTIONS DEFINITION #
########################

# Computation of 'real' Hit Rates (HR) and False Alarm Rates (FAR)
def HR_FAR(H,M,FA,CN):
    
    HR = H / (H + M)
    FAR = FA / (FA + CN)
    HR = np.insert(HR,0,1) #to make sure the ROC curve includes the point (0,0)
    FAR = np.insert(FAR,0,1)
    HR = np.append(HR,0) #to make sure the ROC curve includes the point (1.1)
    FAR = np.append(FAR,0)
    
    n = len(HR)
    AURC = 0
    for i in range(0,n-1):
        j = i + 1 
        a = HR[i]
        b = HR[j]
        h = FAR[j] - FAR[i]
        AURC = AURC + (((a+b)*h)/2)*(-1)
    
    return HR, FAR, AURC


# Computation of hit rates (HRz) and false alarm rates (FARz) for binormal model
def binormal_HR_FAR(HR,FAR):
    
    HRz_inv = norm.ppf(HR)
    FARz_inv = norm.ppf(FAR)
    ind_finite = np.isfinite(FARz_inv + HRz_inv) # index only finite values
    HRz_inv = HRz_inv[ind_finite]
    FARz_inv = FARz_inv[ind_finite]
    
    binormal_params = np.polyfit(FARz_inv,HRz_inv,1) # apply linear regression to define the parameters of the binormal model
    
    x = np.arange(-10,10,0.1) # sample the z space
    y = (binormal_params[0] * x) + binormal_params[1]
    HRz = norm.cdf(y)
    FARz = norm.cdf(x)
    AURCz = norm.cdf( (binormal_params[1]*( (binormal_params[0]**2+1.)/2.)**(-0.5) )/(2.**(0.5)))

    return HRz, FARz, AURCz


##############################
# SETTING GENERAL PARAMETERS #
##############################

# Setting parameters related to the considered verification period and the considered threshold
BaseDateSSTR = BaseDateS.strftime("%Y%m%d")
BaseDateFSTR = BaseDateF.strftime("%Y%m%d")
BaseTimeSTR = f'{BaseTime:02d}'
StepFSTR = f'{StepF:03d}'
AccSTR = f'{Acc:03d}'
ThrSTR = str(Thr)
Legend = []

# Setting sub-directories
DirIN_CT = GitRepo + "/" + DirIN_CT + "_" + AccSTR + "_" + BaseDateSSTR + "_" + BaseDateFSTR + "_" + BaseTimeSTR + "/" + StepFSTR + "_" + ThrSTR
DirOUT_ROC = GitRepo + "/" + DirOUT_ROC + "_" + AccSTR + "_" + BaseDateSSTR + "_" + BaseDateFSTR + "_" + BaseTimeSTR + "/" + StepFSTR + "_" + ThrSTR
####################################################################################################################################################


#######################
# PLOTTING ROC CURVES #
#######################

print(" ")
print("*******************")
print("Plotting ROC curves")
print("*******************") 

for SystemFC in SystemFC_list:
    
    # Setting parameters related to the considered forecasting system
    if SystemFC == "ENS":
        NumEM = 51
        Plot_real_ROC = [1,0,0]
        Plot_binormal_ROC = [1,0.6,0.6]
    elif SystemFC == "ecPoint_Multiple_WT":
        NumEM = 99
        Plot_real_ROC = [0,0,1]
        Plot_binormal_ROC = [0.6,0.6,1]
    elif SystemFC == "ecPoint_Single_WT":
        NumEM = 99
        Plot_real_ROC = [0,1,0]
        Plot_binormal_ROC = [0.6,1,0.6]

    # Setting input files
    FileOUT_H = DirIN_CT + "/H_" + SystemFC + ".npy"
    FileOUT_M = DirIN_CT + "/M_" + SystemFC + ".npy"
    FileOUT_FA = DirIN_CT + "/FA_" + SystemFC + ".npy"
    FileOUT_CN = DirIN_CT + "/CN_" + SystemFC + ".npy"

    # Loading contingency tables
    print(" ")
    print("Loading contingency table for " + SystemFC + " for (t+" + str(StepF) + ") and Thr=" + str(Thr) + "mm/" + str(Acc) + "h")
    H = np.load(FileOUT_H)
    M = np.load(FileOUT_M)
    FA = np.load(FileOUT_FA)
    CN = np.load(FileOUT_CN)
                
    # Computing hit rates (HR) and false alarm rates (FAR)
    print("Computing 'real' ROC curve")
    HR, FAR, AURC = HR_FAR(H,M,FA,CN)
    
    print("Computing 'binormal' ROC curve")
    HRz, FARz, AURCz = binormal_HR_FAR(HR,FAR)
    
    # Plotting 'real' and 'binormal' ROC curves
    print("Plotting 'real' and 'binormal' ROC curves")
    plt.plot(FAR, HR, "-o", color=Plot_real_ROC)
    plt.plot(FARz, HRz, "-", color=Plot_binormal_ROC)
    Legend.append("ROC " + SystemFC + " (AURC=" + str(round(AURC,3)) + ")")
    Legend.append("ROCz " + SystemFC + " (AURCz=" + str(round(AURCz,3)) + ")")
    
dgn_x = np.zeros(2)
dgn_y = np.zeros(2)
dgn_x[1] = 1
dgn_y[1] = 1
plt.plot(dgn_x, dgn_y, "-k")
plt.title("ROC curves for Thr=" + str(Thr) + "mm/" + str(Acc) + " and for (t+" + str(StepF) + ")")
plt.xlabel('False Alarm Rate (FAR)')
plt.ylabel('Hit Rate (HR)')
plt.legend(Legend)
plt.xlim((0,1))
plt.ylim((0,1))
plt.show()
