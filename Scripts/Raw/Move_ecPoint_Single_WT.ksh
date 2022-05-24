#!/bin/ksh

BaseDateS=20201001
BaseDateF=20210930
BaseTime=0
Acc=12
DirIN="/vol/ecpoint/mofp/PhD/Papers2Write/ecPoint_Single_WT/Data/Raw/ecPoint_Single_WT/Forecasts/SemiOper/ecPoint_Rainfall/012/ECMWF_ENS/Code1.0.0_Cal0.1.0/"
DirOUT="/vol/ecpoint/mofp/PhD/Papers2Write/ecPoint_Single_WT/Data/Raw/FC/ecPoint_Single_WT"
#############################################################################################################################################################


BaseTimeSTR=$(printf %02g ${BaseTime})
AccSTR=$(printf %03g ${Acc})

BaseDateS=$(date -d ${BaseDateS} +%Y%m%d)
BaseDateF=$(date -d ${BaseDateF} +%Y%m%d)
BaseDate=${BaseDateS}

while [[ ${BaseDate} -le ${BaseDateF} ]]; do
    
    BaseDateSTR="${BaseDate}"
    echo "Moving ${BaseDateSTR}..."
    
    DirOUT_temp=${DirOUT}/${BaseDateSTR}${BaseTimeSTR}
    mkdir -p ${DirOUT_temp}
        
    mv ${DirIN}/${BaseDateSTR}${BaseTimeSTR}/Pt_BiasCorr_RainPERC/* ${DirOUT_temp}
        
    BaseDate=$(date -d"${BaseDate} + 1 day" +"%Y%m%d")

done

rm -rf ${DirIN}/*
