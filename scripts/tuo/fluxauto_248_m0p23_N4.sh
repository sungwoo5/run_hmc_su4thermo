#!/bin/bash
#FLUX: -t 150m
#FLUX: --output={{name}}
#FLUX: -N 4
#FLUX: --exclusive

date
here=`pwd`
label=${here##*conf_nc4nf1_}

# To verify fastload2 is loading or not, set env variable FASTLOAD_VERBOSE=1 and rank 0 (or serial tasks) will print out something of the form if fastload2 is being used:
# email notice on 10/30/24
export FASTLOAD_VERBOSE=1
# but causing the issue?
export FLUX_FASTLOAD=off

#if [[ -e conf*lat* ]]; then
nlat=$(ls conf_nc4nf1_*_lat.* 2>/dev/null | wc -l)
if [[ "${nlat}" -ne 0 ]]; then
    
    # check the last saved gauge configuration and rng
    lastconf=$(ls conf_nc4nf1_${label}_lat.* | sort -V | tail -1)
    lasttraj=${lastconf##*lat.}
    lastrng=conf_nc4nf1_${label}_rng.${lasttraj}
    if [ ! -e "$lastrng" ]; then
	echo "$lastrng not found"
	exit 1
    fi
# create xml for CheckpointStart from lasttraj
mkdir -p xml
XML=xml/ip_hmc_mobius_cont_${lasttraj}.xml

# basic params read from label
mass=0.${label##*m0p}
beta=${label##*_b}
beta=${beta%%_m*}
beta=$(echo $beta | sed 's/c//g' | sed 's/p/./g')

# params
MDsteps=7
M5=1.5
saveInterval=4
Ntraj=200


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
else

    # fresh start
    XML=ip_hmc_mobius_base.xml
    lasttraj=0

    sed -i 's/saveInterval>2</saveInterval>4</g' $XML

    if [ ! -e $XML ]; then
	echo "$XML for fresh start not found"
	exit 1
    fi
	    

fi



### Launch parallel executable
GRID_DIR=/usr/WS2/lsd/sungwoo/SU4_sdm/Grid_sdm_build/mi300a_test_6.2.0
source ${GRID_DIR}/env.sh
APP="$GRID_DIR/install/gauge_gen_unified_Nc4/bin/dweofa_mobius_HSDM_v3"

OPTIONS="--decomposition --comms-concurrent --comms-overlap --debug-mem  --shm 2048 --shm-mpi 1"

PARAMS=" --grid 24.24.24.8 --mpi 4.2.2.1 --threads 8 --accelerator-threads 8 ${OPTIONS} --ParameterFile ${XML}"


#======================
# run original
#echo "Job ID: $FLUX_JOB_ID"	# this is somehow not working...
my_jobid=$(echo ${PALS_SPOOL_DIR} | cut -d"-" -f3) # email from Kalan 10/7/2024

# log and run directory
mkdir -p log
now=$(date +"%m%d%H%M%S")
LOG=log/log.${label}_cont${lasttraj}_${my_jobid}



# print the nodelist
# https://flux-framework.readthedocs.io/projects/flux-core/en/latest/man1/flux-hostlist.html
# echo "FULL NODELIST =============================" > ${LOG}
# flux hostlist -led'\n' >> ${LOG}
# date >> ${LOG}
# echo "START =====================================" >> ${LOG}
HDR=tmp.header
echo "FULL NODELIST =============================" > ${HDR}
flux hostlist -led'\n' >> ${HDR}
date >> ${HDR}
echo "START =====================================" >> ${HDR}

#flux run -N 4 --tasks-per-node=4 --verbose --exclusive --setopt=mpibind=verbose:1 bash -c "if [[ $(flux resource-info rank) -eq 0 ]]; then  flux hostlist -le; fi; $APP $PARAMS" &>> ${LOG} & 
#flux run -N 4 --tasks-per-node=4 --verbose --exclusive --setopt=mpibind=verbose:1 bash -c "flux hostlist -le; $APP $PARAMS" &>> ${LOG} &
flux run -N 4 --tasks-per-node=4 --verbose --exclusive --setopt=mpibind=verbose:1 --output=${LOG} bash -c "flux hostlist -le; $APP $PARAMS" &


#--------------------------
# End of both run and run2
wait 

# Using sed to Prepend HDR Directly
sed -i "1e cat ${HDR}" ${LOG}
rm $HDR

date >> ${LOG}
echo 'Job Done'>> ${LOG}
