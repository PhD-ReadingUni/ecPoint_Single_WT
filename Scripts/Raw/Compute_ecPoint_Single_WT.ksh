#!/bin/ksh

########################################
#                                      #
# COMPUTING SINGLE WT ECPOINT-RAINFALL #
#                                      #
########################################

####################################################################################################################################################################################################################################
# USER INPUTS

# ENVIRONMENT
RunMode="SemiOper"
NameCaseStudy="empty"
RetrMode="BulkSteps"
Code_Vers="1.0.0"
MetviewVers="5.9.1"

# CALIBRATION
Var2PP="Rainfall"
Acc=12
Model2PP="ECMWF_ENS"
Cal_Vers="0.1.0"
Perc="1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99"

# FORECASTS
BaseDateS=20201001
BaseDateF=20210930
BaseTime=0
StepS_Start=24
StepS_Final=42
Step_Disc=6
StartEM=0
FinalEM=50
NumSA=10

# MAIN DIRECTORIES
CodeDir="/home/mo/mofp/ecpoint/bitbucket/ecpoint_code"
DataDir="/vol/ecpoint/mofp/PhD/Papers2Write/ecPoint_Single_WT/Data/Raw/ecPoint_Single_WT"
EcfsDir="ec:/ecpoint"

# FORECAST TRANSFER VIA FTP
LifeFTP=30
FirstDirFTP="empty"
####################################################################################################################################################################################################################################


# --- DO NOT MODIFY FROM HERE --- #

BaseDateS=$(date -d ${BaseDateS} +%Y%m%d)
BaseDateF=$(date -d ${BaseDateF} +%Y%m%d)
BaseDate=${BaseDateS}

while [[ ${BaseDate} -le ${BaseDateF} ]]; do
    
    ############################################
    # 0) DEFINITION OF THE RUNNING ENVIRONMENT #
    ############################################
    
    # NUMBER OF DIGITS FOR STRINGS CONTAINING NUMBERS
    NumDigBT=2
    NumDigSteps=3
    NumDigAcc=3
    NumDigEM=2
    NumDigSA=2

    # BASEDATE AND BASETIME STRING
    BaseDateSTR="${BaseDate}"
    BaseTimeSTR=$(printf %0${NumDigBT}g ${BaseTime})

    # ACCUMULATION STRING
    AccSTR=$(printf %0${NumDigAcc}g ${Acc})

    # SUB-AREA
    NumSASTR=$(printf %0${NumDigSA}g ${NumSA})
    SA_arr="$(seq -f %0${NumDigSA}g 1 ${NumSA})"

    # ENSEMBLE MEMBERS
    EM_arr="$(seq -f %0${NumDigEM}g ${StartEM} ${FinalEM})"

    # FINAL STEPS
    let StepF_Start=${StepS_Start}+${Acc}
    let StepF_Final=${StepS_Final}+${Acc}
    StepF_arr="$(seq -f %0${NumDigSteps}g ${StepF_Start} ${Step_Disc} ${StepF_Final})"
    Ens_arr="$(seq -f %0${NumDigEM}g ${StartEM} ${FinalEM})"
    SA_arr="$(seq -f %0${NumDigSA}g 1 ${NumSA})"
    AccSTR=$(printf %0${NumDigAcc}g ${Acc})
    NumSASTR=$(printf %0${NumDigSA}g ${NumSA})
    if [[ ${StepF_Final} -le 24 ]]; then
        StepS_InDB=0
        StepF_InDB=24
    else
        StepF_InDB=${StepF_Final}
        let StepS_InDB=${StepF_InDB}-24
    fi

    if [[ ${StepS_InDB} -ge ${StepS_Start} ]]; then
        StepS_InDB=${StepS_Start}
    fi
    StepInDB_arr="$(seq -f %0${NumDigSteps}g ${StepS_InDB} ${Step_Disc} ${StepF_InDB})"

    # PARAMETERS TO SET FOR EACH VARIABLE TO POST-PROCESS
    #   - Minimum value to consider for accumulated predictands
    #       Smaller values will be set up to zero, and won't be post-processed.
    #       No weather type will be assigned, and the grid-box will contained the value 9999
    #   - Dummy grib code for the post-processed forecasts
    case ${Var2PP} in
        Rainfall)
            Min_Predictand_Value=0.04 
            PP_Param="82.128,sfc,0"
        ;; *)    
            echo "Not other parameters defined yet."
            exit 1
    esac

    # ECPOINT FAMILY
    ecPoint_Family="ecPoint_${Var2PP}"
    case ${Var2PP} in
        Rainfall)
            ecPoint_Family="${ecPoint_Family}/${AccSTR}"
    esac

    # RUNMODE ENVIRONMENT
    case ${RunMode} in
        CaseStudy)
            RunMode_Env="${RunMode}/${NameCaseStudy}"
        ;; *)  
            RunMode_Env="${RunMode}"
    esac  

    # CODE AND CALIBRATION ENVIRONMENT
    CodeCal_Env="Code${Code_Vers}_Cal${Cal_Vers}"
    
    # WORKING DIRECTORIES
    ScriptsDir="${CodeDir}/Scripts/${Code_Vers}"
    CalDir="${CodeDir}/CalFiles/${ecPoint_Family}/${Model2PP}/${Cal_Vers}"
    SampleDir="${ScriptsDir}/Samples/${Model2PP}"
    WorkDir="${DataDir}/Forecasts"
    IntStr="${RunMode_Env}/${ecPoint_Family}/${Model2PP}/${CodeCal_Env}"
    OutDir_Def="${WorkDir}/${IntStr}/${BaseDateSTR}${BaseTimeSTR}"
    OutDir_Temp="${OutDir_Def}/TempDir"
    EcfsDir="${EcfsDir}/Forecasts/${IntStr}"

    # COMPUTATIONAL FILES
    FileBP="${CalDir}/BP.csv"
    FileCF="${CalDir}/CF.csv"
    FileRAF="${CalDir}/RAF.csv"
    FileGL="${SampleDir}/Global/Global.grib"
    FileSA="${SampleDir}/SubArea/${NumSASTR}/SubArea.grib"

    # SCRIPTS TO RUN
    ScriptFS="${ScriptsDir}/CreateFileSystem"
    ScriptMARS="${CalDir}/MarsRetrieval_${RetrMode}"
    Script1="${CalDir}/Predict"
    Script2="${ScriptsDir}/EnsPtRain_GridRain_WT"
    Script3="${ScriptsDir}/PtRainCDF"
    Script4="${ScriptsDir}/MergePtRainCDF"
    ScriptFTP="${ScriptsDir}/TransfFTP"

    WDIR_InDB="${OutDir_Temp}/InputDB"
    WDIR1="${OutDir_Temp}/10_Predict_AllREM_GL"
    WDIR21="${OutDir_Temp}/21_EnsPtRain_SingleREM_SA"
    WDIR22="${OutDir_Temp}/22_GridRain_ALLREM_GL"
    WDIR23="${OutDir_Temp}/23_WT_AllREM_GL"
    WDIR3="${OutDir_Temp}/30_PtRainCDF_SA"
    WDIR4="${OutDir_Temp}/40_PtRainCDF_GL"
    WDIR_FTP="${OutDir_Temp}/50_TransfFTP"
    OutDir1="${OutDir_Def}/Pt_BiasCorr_RainPERC"
    OutDir2="${OutDir_Def}/Grid_BiasCorr_RainVALS"
    OutDir3="${OutDir_Def}/WT"

    # INPUT/OUTPUT FILES' NAMES
    NameFileOUT1="Predict"
    NameFileIN2=${NameFileOUT1}
    NameFileOUT21="EnsPtRain"
    NameFileOUT22="GridRain"
    NameFileOUT23="WT"
    NameFileIN3=${NameFileOUT21}
    NameFileOUT3="PtRainCDF_SA"
    NameFileIN4=${NameFileOUT3}
    NameFileOUT4="PtRainCDF_GL"
    NameFile_DefOut1="Pt_BC_PERC"
    NameFile_DefOut2="Grid_BC_VALS"
    NameFile_DefOut3="WT"

    
    
    ##################################
    # 1) CREATION OF THE FILE SYSTEM #
    ##################################

    echo " "
    echo " "
    echo " "
    echo "****************************************"
    echo "FIRST STAGE: Creation of the file system"
    echo "****************************************"

    echo " "

    echo "Running the script... ${ScriptFS}.ksh"

    echo " "
    echo "Creating..."
    echo "  - Database for the raw input variables: ${WDIR_InDB}/"
    echo "  - Working Directory: ${OutDir_Temp}/"
    echo "  - Database for the final forecasts: ${OutDir_Def}/"

    ${ScriptFS}.ksh "${WDIR_InDB}" "${WDIR1}" "${WDIR21}" "${WDIR22}" "${WDIR23}" "${WDIR3}" "${WDIR4}" "${WDIR_FTP}" "${OutDir1}" "${OutDir2}" "${OutDir3}" "${StepInDB_arr}" "${StepF_arr}" "${Ens_arr}" "${SA_arr}"

    echo " " 
    echo "*** First Stage Completed ***"


    ###########################################
    # 2) RETRIEVAL OF THE RAW INPUT VARIABLES #
    ###########################################

    echo " "
    echo " "
    echo " "
    echo "**************************************************"
    echo "SECOND STAGE: Retrieval of the raw input variables"
    echo "**************************************************"
    echo "Retrieving..."

    DirIN="/vol/ecpoint/mofp/PhD/Papers2Write/ecPoint_Single_WT/Data/Raw/FC/ENS/${BaseDateSTR}${BaseTimeSTR}"
    
    for Step in ${StepInDB_arr}; do
        echo ${Step}
        cp ${DirIN}/tp_${BaseDateSTR}_${BaseTimeSTR}_${Step}.grib ${WDIR_InDB}/${Step}/228_${Step}.grib
    done

    echo " " 
    echo "*** Second Stage Completed ***"

    
    
    ###################################################
    # 3) COMPUTATION OF THE PREDICTAND AND PREDICTORS #
    ###################################################

    echo " "
    echo " "
    echo " "
    echo "*************************************************************"
    echo "THIRD STAGE: Computation of the predictand and the predictors"
    echo "*************************************************************"

    echo " "
    echo "Running the script... ${Script1}.ksh"
    echo "The script runs the Metview Macro... ${Script1}.mv"

    for StepS in $(seq ${StepS_Start} ${Step_Disc} ${StepS_Final}); do
        
        let StepF=${StepS}+${Acc}
        StepFSTR="$(printf %0${NumDigSteps}g ${StepF})"
        
        echo " "
        echo " "
        echo "Considering (t+${StepS},t+${StepF})"
        
        FileOUT=${WDIR1}/${StepFSTR}/${NameFileOUT1}
        /home/mo/mofp/ecpoint/bitbucket/ecpoint_code/runcode/sbatch ${Script1}.ksh "${MetviewVers}" "${Script1}.mv" ${StepS} ${Acc} ${NumDigSteps} "${WDIR_InDB}" "${FileOUT}" ${StartEM} ${FinalEM} ${NumDigEM}

    done
    
    sleep 1m
    
    echo " " 
    echo "*** Third Stage Completed ***"

    
    
    #####################################################
    # 4) POST-PROCESSING OF EACH SINGLE ENSEMBLE MEMBER #
    #####################################################

    echo " "
    echo " "
    echo " "
    echo "************************************************************"
    echo "FOURTH STAGE: Post-processing of each single ensemble member"
    echo "************************************************************"

    echo " "
    echo "Running the script... ${Script2}.ksh"
    echo "The script runs the Metview Macro... ${Script2}.mv"

    for StepS in $(seq ${StepS_Start} ${Step_Disc} ${StepS_Final}); do
        
        let StepF=${StepS}+${Acc}
        StepFSTR="$(printf %0${NumDigSteps}g ${StepF})"
        
        echo " "
        echo " "
        echo "Considering (t+${StepS},t+${StepF})"
        
        for CodeEMSTR in ${Ens_arr}; do
            
            echo " "
            echo "Post-Processing the REM n.${CodeEMSTR}"
            
            FileIN="${WDIR1}/${StepFSTR}/${CodeEMSTR}/${NameFileIN2}_${CodeEMSTR}.grib"
            PathOUT1="${WDIR21}/${StepFSTR}"
            FileOUT2="${WDIR22}/${StepFSTR}/${NameFileOUT22}_${CodeEMSTR}.grib"
            FileOUT3="${WDIR23}/${StepFSTR}/${NameFileOUT23}_${CodeEMSTR}.grib"
            
            while [[ ! -f ${FileIN} ]]; do 
                echo "Input files not ready, wait 10s..."
                sleep 10s
            done
                
            /home/mo/mofp/ecpoint/bitbucket/ecpoint_code/runcode/sbatch ${Script2}.ksh "${MetviewVers}" "${Script2}.mv" "${FileBP}" "${FileCF}" "${FileRAF}" "${FileSA}" ${Min_Predictand_Value} "${PP_Param}" ${NumDigEM} ${NumDigSA} "${FileIN}" "${PathOUT1}" "${NameFileOUT21}" "${FileOUT2}" "${FileOUT3}"
                
        done
        
        sleep 2m
        
    done
    
    echo " " 
    echo "*** Fourth Stage Completed ***"
    
    
    
    ###################################################################
    # 5) COMPUTING THE CDF FOR THE NEW ENSEMBLE OF PT RAINFALL VALUES #
    ###################################################################

    echo " "
    echo " "
    echo " "
    echo "*************************************************************************"
    echo "FIFTH STAGE: Computing the CDF for the new ensemble of Pt rainfall values"
    echo "*************************************************************************"

    echo " "
    echo "Running the script... ${Script3}.ksh"
    echo "The script runs the Metview Macro... ${Script3}.mv"

    for StepS in $(seq ${StepS_Start} ${Step_Disc} ${StepS_Final}); do
        
        let StepF=${StepS}+${Acc}
        StepFSTR="$(printf %0${NumDigSteps}g ${StepF})"
        
        echo " "
        echo " "
        echo "Considering (t+${StepS},t+${StepF})"
        
        for CodeSASTR in ${SA_arr}; do
            
            echo " "
            echo "Post-Processing the SA n.${CodeSASTR}"
            
            PathIN="${WDIR21}/${StepFSTR}/${CodeSASTR}"
            NameFileIN="${NameFileOUT21}_${CodeSASTR}"
            FileOUT="${WDIR3}/${StepFSTR}/${CodeSASTR}/${NameFileOUT3}_${CodeSASTR}.grib"
            
            while [[ ! -f ${PathIN}/${NameFileIN}_00.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_01.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_02.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_03.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_04.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_05.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_06.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_07.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_08.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_09.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_10.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_11.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_12.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_13.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_14.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_15.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_16.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_17.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_18.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_19.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_20.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_21.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_22.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_23.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_24.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_25.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_26.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_27.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_28.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_29.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_30.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_31.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_32.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_33.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_34.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_35.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_36.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_37.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_38.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_39.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_40.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_41.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_42.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_43.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_44.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_45.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_46.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_47.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_48.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_49.grib ]] || [[ ! -f ${PathIN}/${NameFileIN}_50.grib ]]; do 
                echo "Input files not ready, wait 10s..."
                sleep 10s
            done
            
            /home/mo/mofp/ecpoint/bitbucket/ecpoint_code/runcode/sbatch ${Script3}.ksh "${MetviewVers}" "${Script3}.mv" "${Perc}" ${StartEM} ${FinalEM} ${NumDigEM} "${PathIN}" "${NameFileIN}" "${FileOUT}"
            
        done
        
    done
    
    sleep 1m30s
    
    echo " " 
    echo "*** Fifth Stage Completed ***"
    
    
    
    ########################################################################################
    # 6) MERGING THE SUB-AREAS THAT CONTAIN CDF FOR THE NEW ENSEMBLE OF PT RAINFALL VALUES #
    ########################################################################################

    echo " "
    echo " "
    echo " "
    echo "******************************************************************************************************************************************"
    echo "SIXTH STAGE: Merging the sub-areas that the CDF for the new ensemble of Pt rainfall values & Moving the outputs to the definitive database"
    echo "******************************************************************************************************************************************"

    echo " "
    echo "Running the script... ${Script4}.ksh"
    echo "The script runs the Metview Macro... ${Script4}.mv"

    for StepS in $(seq ${StepS_Start} ${Step_Disc} ${StepS_Final}); do
        
        let StepF=${StepS}+${Acc}
        StepFSTR="$(printf %0${NumDigSteps}g ${StepF})"
        
        echo " "
        echo " "
        echo "Considering (t+${StepS},t+${StepF})"
        
        PathIN="${WDIR3}/${StepFSTR}"
        FileOUT="${WDIR4}/${StepFSTR}/${NameFileOUT4}.grib"
        
        FileIN_temp1="${WDIR4}/${StepFSTR}/${NameFileOUT4}.grib"
        FileOUT_def1="${OutDir1}/${NameFile_DefOut1}_${AccSTR}_${BaseDateSTR}_${BaseTimeSTR}_${StepFSTR}.grib"
        
        while [[ ! -f ${PathIN}/01/${NameFileIN4}_01.grib ]] || [[ ! -f ${PathIN}/02/${NameFileIN4}_02.grib ]] || [[ ! -f ${PathIN}/03/${NameFileIN4}_03.grib ]] || [[ ! -f ${PathIN}/04/${NameFileIN4}_04.grib ]] || [[ ! -f ${PathIN}/05/${NameFileIN4}_05.grib ]] || [[ ! -f ${PathIN}/06/${NameFileIN4}_06.grib ]] || [[ ! -f ${PathIN}/07/${NameFileIN4}_07.grib ]] || [[ ! -f ${PathIN}/08/${NameFileIN4}_08.grib ]] || [[ ! -f ${PathIN}/09/${NameFileIN4}_09.grib ]] || [[ ! -f ${PathIN}/10/${NameFileIN4}_10.grib ]]; do 
            echo "Input files not ready, wait 10s..."
            sleep 10s
        done
        
        /home/mo/mofp/ecpoint/bitbucket/ecpoint_code/runcode/sbatch ${Script4}.ksh "${MetviewVers}" "${Script4}.mv" "${PP_Param}" "${FileGL}" ${NumSA} ${NumDigSA} "${PathIN}" "${NameFileIN4}" "${FileOUT}" "${FileIN_temp1}" "${FileOUT_def1}"

    done
    
    sleep 1m
    
    echo " " 
    echo "*** Sixth Stage Completed ***"

    
    
    #######################################
    # 7) REMOVING THE TEMPORARY DIRECTORY #
    #######################################

    echo " "
    echo " "
    echo " "
    echo "***********************************************"
    echo "SEVENTH STAGE: Removing the temporary directory"
    echo "***********************************************"
    
    for StepS in $(seq ${StepS_Start} ${Step_Disc} ${StepS_Final}); do
        
        let StepF=${StepS}+${Acc}
        StepFSTR="$(printf %0${NumDigSteps}g ${StepF})"

        FileIN="${OutDir1}/${NameFile_DefOut1}_${AccSTR}_${BaseDateSTR}_${BaseTimeSTR}_${StepFSTR}.grib"
        
        while [[ ! -f ${FileIN} ]]; do 
            echo "Definitive output files not ready, wait 5s..."
            sleep 5s
        done
        
    done
    
    echo " "
    echo "Removing the temporary directory ${OutDir_Temp}..."
    rm -rf "${OutDir_Temp}"

    BaseDate=$(date -d"${BaseDate} + 1 day" +"%Y%m%d")

done
