#!/bin/bash
#FLUX: -t 60m
#FLUX: --output={{name}}.out
#FLUX: --error={{name}}.err
#FLUX: -N 2
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
XML=ip_hmc_mobius_cont_${lasttraj}.xml
sed 's/START_TRAJECTORY/'${lasttraj}'/g' ${BASEXML} > ${XML}

### Launch parallel executable
GRID_DIR=/usr/WS2/lsd/sungwoo/SU4_sdm/Grid_sdm_build/mi300a_test_6.2.0
source ${GRID_DIR}/env.sh
APP="$GRID_DIR/install/gauge_gen_unified_Nc4/bin/dweofa_mobius_HSDM_v3"

OPTIONS="--decomposition --comms-concurrent --comms-overlap --debug-mem  --shm 2048 --shm-mpi 1"

PARAMS=" --grid 24.24.24.12 --mpi 2.2.2.1 --threads 20 --accelerator-threads 8 ${OPTIONS} --ParameterFile ${XML}"
LOG=log.lrun.${label}_cont${lasttraj}

# print the nodelist
# https://flux-framework.readthedocs.io/projects/flux-core/en/latest/man1/flux-hostlist.html
flux hostlist -led'\n' > ${LOG}

flux run -N 2 -n 8 -g 1 --verbose --exclusive --setopt=mpibind=verbose:1 $APP $PARAMS &>> ${LOG}

# manage the queue of two jobs
# note that the following files were created when the jobs were submitted
# rm .job_current
# mv .job_next .job_current
# --> cannot do this here, as the job will be canceled due to the walltime limit,
#     then this part will not be executed at the end of this job

echo 'Done'
