#!/bin/bash
#FLUX: -t 60m
#FLUX: --output={{name}}
#FLUX: -N 16
#FLUX: -q pdebug
#FLUX: --exclusive

date
here=`pwd`
label=${here##*conf_nc4nf1_}

# check the last saved gauge configuration and rng
lastconf=$(ls conf_nc4nf1_${label}_lat.* | sort -V | tail -1)
lasttraj=${lastconf##*lat.}
lastrng=conf_nc4nf1_${label}_rng.${lasttraj}
if [ ! -e "$lastrng" ]; then
    echo "$lastrng not found"
    exit 1
fi

# create xml for CheckpointStart from lasttraj
BASEXML=./ip_hmc_mobius_base_cont.xml
mkdir -p xml
XML=xml/ip_hmc_mobius_cont_${lasttraj}.xml

# basic params read from label
mass=0.${label##*m0p}
beta=${label##*_b}
beta=${beta%%_m*}
beta=$(echo $beta | sed 's/c//g' | sed 's/p/./g')

# params
MDsteps=8
M5=1.8
saveInterval=2
Ntraj=36


# make the input xml
cat <<EOF > ${XML}
<?xml version="1.0"?>
<grid>
  <HMC>
    <StartTrajectory>${lasttraj}</StartTrajectory>
    <Trajectories>${Ntraj}</Trajectories>
    <MetropolisTest>true</MetropolisTest>
    <NoMetropolisUntil>0</NoMetropolisUntil>
    <StartingType>CheckpointStart</StartingType>
    <PerformRandomShift>false</PerformRandomShift>
    <MD>
      <!-- <name>MinimumNorm2</name> -->
      <name>ForceGradient</name>
      <MDsteps>${MDsteps}</MDsteps>
      <trajL>1.0</trajL>
    </MD>
  </HMC>
  <Checkpointer>
    <config_prefix>conf_nc4nf1_${label}_lat</config_prefix>
    <rng_prefix>conf_nc4nf1_${label}_rng</rng_prefix>
    <saveInterval>${saveInterval}</saveInterval>
    <saveSmeared>false</saveSmeared> <!--latest Grid-->
    <smeared_prefix>conf_nc4nf1_${label}_lat_smr</smeared_prefix> <!--latest Grid-->
    <format>IEEE64BIG</format>
  </Checkpointer>
  <RandomNumberGenerator>
    <!-- DUMMY SEED AS CheckpointStart DOESN'T RESEED -->
    <serial_seeds>0 0 0 0 0</serial_seeds>
    <parallel_seeds>0 0 0 0 0</parallel_seeds>
  </RandomNumberGenerator>
  <Action>
    <gauge_beta>${beta}</gauge_beta>
    <Mobius>
        <Ls>16</Ls>
        <mass>${mass}</mass>
        <M5>${M5}</M5>
        <b>1.5</b>
        <c>0.5</c>
        <StoppingCondition>1e-10</StoppingCondition>
        <MaxCGIterations>30000</MaxCGIterations>
        <ApplySmearing>false</ApplySmearing>
    </Mobius>
  </Action>
</grid>

EOF




### Launch parallel executable
GRID_DIR=/usr/WS2/lsd/sungwoo/SU4_sdm/Grid_sdm_build/mi300a_test_6.2.0
source ${GRID_DIR}/env.sh
APP="$GRID_DIR/install/gauge_gen_unified_Nc4/bin/dweofa_mobius_HSDM_v3"

OPTIONS="--decomposition --comms-concurrent --comms-overlap --debug-mem  --shm 2048 --shm-mpi 1"

PARAMS=" --grid 32.32.32.8 --mpi 4.4.2.1 --threads 20 --accelerator-threads 8 ${OPTIONS} --ParameterFile ${XML}"


#======================
# run original

# log and run directory
mkdir -p log
now=$(date +"%m%d%H%M%S")
LOG=log/log.${label}_cont${lasttraj}_${now}

echo "Job ID: $FLUX_JOB_ID"	# this is somehow not working...


# make nodelist_used_run2.txt
nodelist_used=../nodelist_used_run2.txt
flux hostlist -led' ' | sed 's/tuolumne//g' >>${nodelist_used}


# print the nodelist
# https://flux-framework.readthedocs.io/projects/flux-core/en/latest/man1/flux-hostlist.html
echo "FULL NODELIST =============================" > ${LOG}
flux hostlist -led'\n' >> ${LOG}
date >> ${LOG}
echo "START =====================================" >> ${LOG}

#flux run -N 4 --tasks-per-node=4 --verbose --exclusive --setopt=mpibind=verbose:1 bash -c "if [[ $(flux resource-info rank) -eq 0 ]]; then  flux hostlist -le; fi; $APP $PARAMS" &>> ${LOG} & 
flux run -N 8 --tasks-per-node=4 --verbose --exclusive --setopt=mpibind=verbose:1 bash -c "flux hostlist -le; $APP $PARAMS" &>> ${LOG} &

#========================
# run2 for test 
TESTDIR=run2
LOG2=log/log.${label}_cont${lasttraj}_run2_${now}
mkdir -p ${TESTDIR}/log
cd $TESTDIR

if [[ ! "$(basename "$PWD")" == "$TESTDIR" ]]; then
    echo "not in the run2 directory for the test"
    exit 1
else
    # clean run2 dir
    rm conf_*
fi

if [ ! -L "xml" ]; then
    ln -s ../xml . 
fi

ln -s ../${lastconf} .
ln -s ../${lastrng} .
flux run -N 8 --tasks-per-node=4 --verbose --exclusive --setopt=mpibind=verbose:1 bash -c "flux hostlist -le; $APP $PARAMS" &> ${LOG2} &

#--------------------------
# End of both run and run2
wait 
date >> ../${LOG}
echo 'Job Done'>> ../${LOG}

#-------------------------------------------------------------------
# extract the gauge observables of the last traj from a log file
extract_data() {
    local logfile=$1

    # Extract unsmeared plaquette value
    unsmeared_plaquette=$(grep -A 1 "Unsmeared plaquette" $logfile | grep "Plaquette" | awk '{print $10, $12}')

    # Extract Polyakov loop values
    polyakov_loop=$(tail -10 $logfile | grep 'Polyakov Loop' | awk '{print $13}' | sed 's/[(),]/ /g')

    # Print the extracted 4 values
    # traj# plaq pol_re pol_im
    echo "$unsmeared_plaquette $polyakov_loop"
}

#---------------------------------------------------
# Call the extract_data function for two log files
data1=($(extract_data ../${LOG}))
data2=($(extract_data ${LOG2}))
LOG_COMPARE=tmp_compare
#------------------------
# compare two last traj
echo "==================================================">> ${LOG_COMPARE}
echo "Compare two last traj">> ${LOG_COMPARE}
data_str=("traj_idx   :"
	  "plaq       :"
	  "polyakov_re:"
	  "polyakov_im:")
allpass=1
for i in {0..3}; do

    abs_diff=$(python3 -c "print(abs(${data1[$i]}-${data2[$i]}))")
    tol=1e-14
    echo -n "${data_str[i]} ">> ${LOG_COMPARE}
    compare=$(python3 -c 'print("0") if '${abs_diff}'>='${tol}' else print("1")')
    
    if (( $compare )); then
    	echo "matched, diff=${abs_diff} < $tol">> ${LOG_COMPARE}
    else
    	echo "fail">> ${LOG_COMPARE}
	allpass=0
    fi
done

if (( $allpass )); then
    echo "all pass">> ${LOG_COMPARE}
    cat ${LOG_COMPARE} >> ../${LOG}

else
    echo "failed, remove all the configurations generated so that the next job starts from ${lasttraj}">> ${LOG_COMPARE}

    if [[ ! "$(basename "$PWD")" == "$TESTDIR" ]]; then
	echo "not in the run2 directory for the test"
	exit 1
    else
	# remove the symbolic links of first configuration and rng
	rm ${lastconf} ${lastrng}

	# remove the generated files as the original run
	for f in conf_*; do
	    # last check if the traj is larger than lasttraj
	    # to make sure this is generated from this failed job
	    thistraj=${f##*.}
	    if [ "$thistraj" -gt "$lasttraj" ]; then
		rm ../$f
	    fi
	done

	# rename the logs 
    fi
fi

#--------------------------
# clean run2 directory
if [[ "$(basename "$PWD")" == "$TESTDIR" ]]; then
    rm conf_*
    rm ${LOG_COMPARE}
fi
cd -

