#!/bin/bash
# get rid of cont batch script
# v2 does Nf0 by zero mass input

# Check if the correct number of arguments was provided
if [ $# -ne 5 ]; then
    echo "Usage: $0 <NL> <NT> <beta> <mass> <STARTING_TYPE>"
    echo "<STARTING_TYPE>: HotStart/ColdStart" 
    # scripts for CheckpointStartfromHot/CheckpointStartfromCold will be automatically generated simultaneously
    #STARTING_TYPE="CheckpointStartReseed" is not currently supported here
    echo "note: please run and create rundir manually one at a time, to add human randomness into the seed!"
    exit 1
fi

#==================================================
# gauge configuration parameters
NL=$1
NT=$2
BETA=$(printf "%06.3f" $3)
MASS=$(printf "%.4f" $4)
STARTING_TYPE=$5
TRAJS=500	# just large enough number to run over the whole walltime
# Note:
# NT*baremass fixed
# Nobuyuki's run 16.16.16.8  with m=0.075, 0.10, 0.125
# Sungwoo's run  32.32.32.16 with m=     , 0.05,


#==================================================
# Random seed

# 0th seed from nanosecond time
#seed0=$(printf "%.0f" "$(echo "$NL * $NT * $MASS * $BETA " | bc)")
seed0=$(date '+%N')

# 1st seed for generating 10 random seeds
MIN=1
MAX=65536
seed1=$(awk -v min=$MIN -v max=$MAX -v seed=$seed0 'BEGIN { srand(seed); print int(min+rand()*(max-min+1)) }')

# 10 random seeds as inputs to the HMC executable
MIN=1
MAX=65536
seeds=`awk -v min=$MIN -v max=$MAX -v seed=$seed1 '
BEGIN {
    srand(seed);  # Set the seed for the random number generator
    for (i = 1; i <= 10; i++) {
        # Generate and print a random number in the specified range
        print int(min + rand() * (max - min + 1));
    }
}'`

# Convert the string into an array
arr=($seeds)

# Slice the array into two parts
SERIAL_SEEDS="${arr[@]:0:5}"  # Extract the first 5 elements
PARALLEL_SEEDS="${arr[@]:5:5}"  # Extract the next 5 elements


#====================================================
# Job description
str_mass=$(echo $MASS | sed 's/\./p/g')
str_beta=$(echo $BETA | sed 's/\./p/g')
if [[ ${STARTING_TYPE} == *"Cold"* ]]; then
    str_beta=${str_beta}c
fi

JOB=$NL$NT"_b"$str_beta"_m"$str_mass
here=`pwd -P`
#dir_path="./confs"
dir_path="./confs_elcap"
dir_name="conf_nc4nf1_"${JOB}

if [ ${MASS} = "0.0000" ]; then	# string comparison is [] with =
    JOB=$NL$NT"_b"$str_beta
    dir_path="./confs_nf0"
    dir_name="conf_nc4nf0_"${JOB}
    TRAJS=6000
fi

#-----------------------------------------
# Check if the directory already exists
if [ -d "${dir_path}/${dir_name}" ]; then
    echo "Directory ${dir_path}/${dir_name} already exists."
    echo "Cannot create fresh start with ${STARTING_TYPE}"
    exit 1
else
    # if [[ ${STARTING_TYPE} == "CheckpointStart"* ]] ; then
    # 	echo "Cannot create dir with ${STARTING_TYPE}"
    # 	exit 1
    # fi
    # Directory does not exist, so create it
    mkdir -p "${dir_path}/${dir_name}"
    echo "Directory ${dir_path}/${dir_name} created."
fi    

#--------------
# create xml
NSTEPS=7
TRAJLENGTH=1.0
basepath="base"
basexml="ip_hmc_mobius_base.xml"
if [ ${MASS} = "0.0000" ]; then	# string comparison is [] with =
    basexml="ip_hmc_mobius_nf0_base.xml"
fi

hostname=$(hostname)
JOB_SCHEDULER="bsub"
if [[ ${hostname} == "tuolumne"* ]]; then
    JOB_SCHEDULER="flux"
fi

for ifcheckpoint in "" "CheckpointStartfrom"; do
    
    SKIPFORTHERMALIZATION=0
    STARTING_TYPE=${ifcheckpoint}${STARTING_TYPE}

    if [[ ! ${STARTING_TYPE} == "CheckpointStart"* ]] ; then

	# Cold or Hot start
	START_TRAJECTORY=0
	if [ ${STARTING_TYPE} == "ColdStart" ]; then
	    # NSTEPS=10
	    # TRAJLENGTH=0.1
	    # -> rather than putting smaller trajL,
	    #    now put <NoMetropolisUntil>SKIPFORTHERMALIZATION</NoMetropolisUntil>
	    #    which skip metropolistest and just accept
	    SKIPFORTHERMALIZATION=50	
	fi
	if [ ${MASS} = "0.0000" ]; then	# string comparison is [] with =
	    SKIPFORTHERMALIZATION=1000
	fi
	XML=${dir_path}/${dir_name}/${basexml}
	
	cp -a ${basepath}/$basexml $XML
	sed -i 's/START_TRAJECTORY/'"${START_TRAJECTORY}"'/g' $XML

    else

	# CheckpointStart
	XML=${dir_path}/${dir_name}/${basexml%%.xml}_cont".xml"
	cp -a $basepath/$basexml $XML

	# starting traj will be determined by the batch script at the runtime
    fi

    sed -i 's/SERIAL_SEEDS/'"${SERIAL_SEEDS}"'/g' $XML
    sed -i 's/PARALLEL_SEEDS/'"${PARALLEL_SEEDS}"'/g' $XML
    sed -i 's/PREFIX/'"${dir_name}"'/g' $XML
    sed -i 's/BETA/'"${BETA}"'/g' $XML
    if [ ${MASS} != "0.0000" ]; then	# string comparison is [] with =
	sed -i 's/MASS/'"${MASS}"'/g' $XML
    fi
    sed -i 's/STARTING_TYPE/'"${STARTING_TYPE%%from*}"'/g' $XML
    sed -i 's/TRAJS/'"${TRAJS}"'/g' $XML
    sed -i 's/NSTEPS/'"${NSTEPS}"'/g' $XML
    sed -i 's/TRAJLENGTH/'"${TRAJLENGTH}"'/g' $XML
    sed -i 's/SKIPFORTHERMALIZATION/'"${SKIPFORTHERMALIZATION}"'/g' $XML

    # FIXME:
    # temporary thing to adjust params for 32^3*8 m=0.05
    if [[ ${NT} == "8" ]]; then
	# if [[ ${MASS} == "0.0500" || ${MASS} == "0.0100" ]] ; then
	if (( $( echo "${MASS} <= 0.05" | bc -l) )) ; then # if (( )) is required for float comp
	    sed -i 's/>1.8</>1.5</g' $XML
	    sed -i 's/MDsteps>'$NSTEPS'</MDsteps>7</g' $XML
	fi
	if [[ ${MASS} == "0.2000" || ${MASS} == "0.3000" ]] ; then
	    sed -i 's/>1.8</>1.5</g' $XML
	    sed -i 's/MDsteps>'$NSTEPS'</MDsteps>7</g' $XML
	fi
    fi

    #---------------------------
    # create lsf batch script 
    if [[ ! ${STARTING_TYPE} == "CheckpointStart"* ]] ; then
	# Fresh start
	baselsf="${JOB_SCHEDULER}_base.sh"

	# if [ ${NT} == "16" ] ; then
	#     # let me use 4 nodes for larger volume..
	#     baselsf="bsub_base_4.sh"
	# # elif [[ ${NT} == "8" && ${NL} == "24" ]] ; then
	# elif [[ ${NT} == "8" ]] ; then
	#     # let me use 1 node for smaller volume..
	#     baselsf="bsub_base_1.sh"
	# fi

	LSF=${dir_path}/${dir_name}/"${JOB_SCHEDULER}.sh"
	cp -a $basepath/$baselsf $LSF
	sed -i 's/XML/'"${basexml}"'/g' $LSF
    # else
    # 	# CheckpointStart
    # 	baselsf="bsubcont_base.sh"

    # 	if [ ${NT} == "16" ] ; then
    # 	    # let me use 4 nodes for larger volume..
    # 	    baselsf="bsubcont_base_4.sh"
    # 	elif [[ ${NT} == "8" && ${NL} == "24" ]] ; then
    # 	# elif [[ ${NT} == "8" ]] ; then
    # 	    # let me use 1 node for smaller volume..
    # 	    baselsf="bsubcont_base_1.sh"
    # 	fi

    # 	LSF=${dir_path}/${dir_name}/"bsub_cont.sh"
    # 	cp -a $basepath/$baselsf $LSF
    fi

    sed -i 's/JOBNAME/'"${JOB}"'/g' $LSF
    sed -i 's/NL/'"${NL}"'/g' $LSF
    sed -i 's/NT/'"${NT}"'/g' $LSF

    # if [ ${STARTING_TYPE} == "ColdStart" ]; then
    #     sed -i 's/pbatch/pdebug/g' $LSF
    #     sed -i 's/720/120/g' $LSF
    # fi
done
