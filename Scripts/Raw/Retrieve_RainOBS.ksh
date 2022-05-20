#!/bin/ksh

##################
# USERS' INPUTS
BaseDateS=20201001
BaseDateF=20211010
DirIN="/vol/ecpoint/mofp/PhD/Papers2Write/ecPoint_1WT/Data/Raw/RainOBS"
##################

BaseDateS=$(date -d ${BaseDateS} +%Y%m%d)
BaseDateF=$(date -d ${BaseDateF} +%Y%m%d)
BaseDate=${BaseDateS}

while [[ ${BaseDate} -le ${BaseDateF} ]]; do

    mkdir -p ${DirIN}/${BaseDate}

    /home/mo/moz/bin/stvl_getgeo --sources synop hdobs efas --parameter tp --period 12 --dates ${BaseDate} --times 00 06 12 18 --columns value_0 --outdir ${DirIN}/${BaseDate} --flattree

    BaseDate=$(date -d"${BaseDate} + 1 day" +"%Y%m%d")

done
