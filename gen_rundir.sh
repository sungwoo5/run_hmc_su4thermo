#!/bin/bash

# Check if the correct number of arguments was provided
if [ $# -ne 6 ]; then
    echo "Usage: $0 <NL> <NT> <beta> <mass> <STARTING_TYPE> <TRAJS>"
    echo "<STARTING_TYPE>: HotStart/ColdStart/CheckpointStart"
    echo "<TRAJS>: number of trajectories to run"
    echo "note: please run and create rundir manually one at a time, to add human randomness into the seed!"
    exit 1
fi

#==================================================
# gauge configuration parameters
NL=$1
NT=$2
BETA=$(printf "%.2f" $3)
MASS=$(printf "%.4f" $4)
STARTING_TYPE=$5
TRAJS=$6
#STARTING_TYPE="CheckpointStartReseed"
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
if [ ${STARTING_TYPE} == "ColdStart" ]; then
    str_beta=${str_beta}c
fi

JOB=$NL$NT"_b"$str_beta"_m"$str_mass
here=`pwd -P`
dir_name="conf_nc4nf1_"${JOB}

#-----------------------------------------
# Check if the directory already exists
if [ -d "$dir_name" ]; then
    echo "Directory $dir_name already exists."
    if [ ! ${STARTING_TYPE} == "CheckpointStart" ] ; then
	echo "Cannot create fresh start with ${STARTING_TYPE}"
	exit 1
    fi
else
    if [ ${STARTING_TYPE} == "CheckpointStart" ] ; then
	echo "Cannot create dir with ${STARTING_TYPE}"
	exit 1
    fi
    # Directory does not exist, so create it
    mkdir -p "$dir_name"
    echo "Directory $dir_name created."
fi    

#--------------
# create xml
NSTEPS=8
TRAJLENGTH=1.0
basexml="ip_hmc_mobius_base.xml"

if [ ! ${STARTING_TYPE} == "CheckpointStart" ] ; then

    # Cold or Hot start
    START_TRAJECTORY=0
    if [ ${STARTING_TYPE} == "ColdStart" ]; then
	# basexml="ip_hmc_mobius_base_cold.xml"
	NSTEPS=10
	TRAJLENGTH=0.1
    fi
    XML=${dir_name}/${basexml}
    
    cp -a $basexml $XML
    sed -i 's/START_TRAJECTORY/'"${START_TRAJECTORY}"'/g' $XML

else

    # CheckpointStart
    XML=${dir_name}/${basexml%%.xml}_cont".xml"
    cp -a $basexml $XML

    # starting traj will be determined by the batch script at the runtime
fi

sed -i 's/SERIAL_SEEDS/'"${SERIAL_SEEDS}"'/g' $XML
sed -i 's/PARALLEL_SEEDS/'"${PARALLEL_SEEDS}"'/g' $XML
sed -i 's/PREFIX/'"${dir_name}"'/g' $XML
sed -i 's/BETA/'"${BETA}"'/g' $XML
sed -i 's/MASS/'"${MASS}"'/g' $XML
sed -i 's/STARTING_TYPE/'"${STARTING_TYPE}"'/g' $XML
sed -i 's/TRAJS/'"${TRAJS}"'/g' $XML
sed -i 's/NSTEPS/'"${NSTEPS}"'/g' $XML
sed -i 's/TRAJLENGTH/'"${TRAJLENGTH}"'/g' $XML

#---------------------------
# create lsf batch script 
if [ ! ${STARTING_TYPE} == "CheckpointStart" ] ; then
    baselsf="bsub_base.sh"
    # baselsf="bsub_base_4.sh"
    LSF=${dir_name}/"bsub.sh"
    cp -a $baselsf $LSF
    sed -i 's/JOBNAME/'"${JOB}"'/g' $LSF
    sed -i 's/XML/'"${basexml}"'/g' $LSF
    sed -i 's/NL/'"${NL}"'/g' $LSF
    sed -i 's/NT/'"${NT}"'/g' $LSF
else
    baselsf="bsubcont_base.sh"
    # baselsf="bsub_base_4.sh"
    LSF=${dir_name}/"bsub_cont.sh"
    cp -a $baselsf $LSF
    sed -i 's/JOBNAME/'"${JOB}"'/g' $LSF
    sed -i 's/NL/'"${NL}"'/g' $LSF
    sed -i 's/NT/'"${NT}"'/g' $LSF
fi
