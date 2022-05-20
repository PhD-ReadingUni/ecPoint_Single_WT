# RetrieveMARS_tpENS.sh retrieves from MARS rainfall forecasts 
# from ECMWF ENS forecsting system

# INPUT PARAMETERS
DateS=2020-10-01
DateF=2020-12-31
StepS=222
StepF=246
Git_repo="/vol/ecpoint/mofp/PhD/Papers2Write/ecPoint_1WT"
DirOUT="Data/Raw/ENS"
#################################################################

# Setting some general parameters
Dir_main=${Git_repo}/${DirOUT}
DateS=$(date -d $DateS +%Y%m%d)
DateF=$(date -d $DateF +%Y%m%d)


# Retriving forecasts from MARS
TheDate=${DateS}
while [[ ${TheDate} -le ${DateF} ]]; do
    
    for Time in 0 12; do
        
        if [[ ${Time} -eq 0 ]]; then
            TheTime=0
            TheTimeSTR=0${Time}
        else
            TheTime=1200
            TheTimeSTR=${Time}
        fi
        Dir_temp="${Dir_main}/${TheDate}${TheTimeSTR}"
        mkdir -p ${Dir_temp}

mars <<EOF
        retrieve,
            class=od,
            date=${TheDate},
            expver=1,
            levtype=sfc,
            param=228.128,
            step=${StepS}/to/${StepF}/by/6,
            stream=enfo,
            time=${TheTime},
            type=cf,
            target="${Dir_temp}/tp_${TheDate}_${TheTimeSTR}_[step].grib"
            
         retrieve,
            number=1/2/3/4/5/6/7/8/9/10/11/12/13/14/15/16/17/18/19/20/21/22/23/24/25/26/27/28/29/30/31/32/33/34/35/36/37/38/39/40/41/42/43/44/45/46/47/48/49/50,
            type=pf
EOF

        for TheStep in 0 6 12 18 24 30 36 42 48 54 60 66 72 78 84 90 96; do
    
            if [[ ${TheStep} -lt 10 ]]; then
                TheStepSTR=00${TheStep}
            else
                TheStepSTR=0${TheStep}
            fi        
    
            mv "${Dir_temp}/tp_${TheDate}_${TheTimeSTR}_${TheStep}.grib" "${Dir_temp}/tp_${TheDate}_${TheTimeSTR}_${TheStepSTR}.grib"

        done

    done

    TheDate=$(date -d"${TheDate} + 1 day" +"%Y%m%d")

done  
