#!/bin/ksh

###############
# USER INPUTS #
###############

BaseDateS=20201003
BaseDateF=20210930
BaseTime=00
##################


BaseDateS=$(date -d ${BaseDateS} +%Y%m%d)
BaseDateF=$(date -d ${BaseDateF} +%Y%m%d)
BaseDate=${BaseDateS}

while [[ ${BaseDate} -le ${BaseDateF} ]]; do
    
    echo " "
    echo "Retrieving forecast for ${BaseDate}"
    
    if [[ ${BaseDate} -le 20201231 ]]; then
    
        DirIN="ec:/emos/ecpoint/Oper/ecPoint_Rainfall/012/Vers1.2"
        DirOUT="/vol/ecpoint/mofp/PhD/Papers2Write/ecPoint_1WT/Data/Raw/ecPoint_Multiple_WT"
        
        mkdir -p ${DirOUT}/${BaseDate}${BaseTime}
        ecp ${DirIN}/${BaseDate}${BaseTime}/Pt_BiasCorr_RainPERC.tar ${DirOUT}/${BaseDate}${BaseTime}
        tar -C ${DirOUT}/${BaseDate}${BaseTime} -xvf ${DirOUT}/${BaseDate}${BaseTime}/Pt_BiasCorr_RainPERC.tar
        mv ${DirOUT}/${BaseDate}${BaseTime}/sc2/tcwork/emos/emos_data/log/ecpoint_oper/emos/Forecasts/Oper/ecPoint_Rainfall/012/Vers1.2/${BaseDate}${BaseTime}/Pt_BiasCorr_RainPERC/* ${DirOUT}/${BaseDate}${BaseTime}
        rm -rf ${DirOUT}/${BaseDate}${BaseTime}/Pt_BiasCorr_RainPERC.tar ${DirOUT}/${BaseDate}${BaseTime}/sc2
    
    else
        
        DirIN="/vol/ecpoint/emos/Forecasts/Oper/ecPoint_Rainfall/012/Vers1.2"
        DirOUT="/vol/ecpoint/mofp/PhD/Papers2Write/ecPoint_1WT/Data/Raw/ecPoint_Multiple_WT"
        
        mkdir -p ${DirOUT}/${BaseDate}${BaseTime}
        cp ${DirIN}/${BaseDate}${BaseTime}/Pt_BiasCorr_RainPERC/* ${DirOUT}/${BaseDate}${BaseTime}
        
    fi
    
    BaseDate=$(date -d"${BaseDate} + 1 day" +"%Y%m%d")

done
