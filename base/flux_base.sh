#!/bin/bash
#FLUX: -t 360m
#FLUX: --job-name=JOBNAME
#FLUX: --output=JOBNAME.out
#FLUX: --error=JOBNAME.err
#FLUX: -N 2
#FLUX: -q pbatch
#FLUX: --exclusive

### Shell scripting
# https://hpc-tutorials.llnl.gov/flux/
date

### Launch parallel executable
GRID_DIR=/usr/WS2/lsd/sungwoo/SU4_sdm/Grid_sdm_build/mi300a_test_6.2.0
source ${GRID_DIR}/env.sh
APP="$GRID_DIR/install/gauge_gen_unified_Nc4/bin/dweofa_mobius_HSDM_v3"

OPTIONS="--decomposition --comms-concurrent --comms-overlap --debug-mem  --shm 2048 --shm-mpi 1"

PARAMS=" --grid NL.NL.NL.NT --mpi 2.2.2.1 --threads 20 --accelerator-threads 4 ${OPTIONS} --ParameterFile XML"

LOG=log.lrun.JOBNAME

# print the nodelist
# https://flux-framework.readthedocs.io/projects/flux-core/en/latest/man1/flux-hostlist.html
flux hostlist -led'\n' > ${LOG}

flux run -N 2 -n 8 -g 1 --verbose --exclusive --setopt=mpibind=verbose:1 $APP $PARAMS &>> ${LOG}

echo 'Done'
