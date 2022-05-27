import os as os
import numpy as np
import numpy.polynomial.polynomial as poly
import pandas as pd
from datetime import datetime, date, timedelta
import matplotlib.pyplot as plt
from scipy import stats
from scipy.stats import norm

# INPUT PARAMETERS
BaseDateS = date(2020,10,1)
BaseDateF = date(2021,9,30)
BaseTime = 0
StepF = 12
Acc = 12
Thr = 50.0
SystemFC = "ENS"  # valid values are "ENS", "ecPoint_Multiple_WT", "ecPoint_Single_WT"
GitRepo = "C:/Users/f_ati/OneDrive/Desktop/PhD/Papers/ecPoint_Single_WT"
DirIN_CT = "Data/Processed/CT"
DirOUT_BSrel = "Data/Processed/BSrel"
#####################################################################################################################

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
DirOUT_BSrel = GitRepo + "/" + DirOUT_BSrel + "_" + AccSTR + "_" + BaseDateSSTR + "_" + BaseDateFSTR + "_" + BaseTimeSTR + "/" + StepFSTR + "_" + ThrSTR
####################################################################################################################################################


# Check whether the output directory exists and create it if it does not
if not os.path.exists(DirOUT_BSrel):
    os.makedirs(DirOUT_BSrel)
