#!/bin/bash
### LSF syntax
#BSUB -nnodes 2                   #number of nodes
#BSUB -W 720                      #walltime in minutes
##BSUB -G guests                   #account
#BSUB -e JOBNAME.err             #stderr
#BSUB -o JOBNAME.out             #stdout
#BSUB -J JOBNAME                    #name of job
#BSUB -q pbatch                   #queue to use

### Shell scripting
# https://hpc.llnl.gov/documentation/tutorials/using-lc-s-sierra-systems#BatchScripts
date; hostname
echo -n 'JobID is '; echo $LSB_JOBID

### Launch parallel executable
GRID_DIR=/usr/WS2/lsd/sungwoo/SU4_sdm/Grid_sdm_build/lassen
source ${GRID_DIR}/env.sh
APP="$GRID_DIR/install/gauge_gen_Nc4/bin/dweofa_mobius_HSDM_v3"

OPTIONS="--decomposition --comms-concurrent --comms-overlap --debug-mem  --shm 2048 --shm-mpi 1"

PARAMS=" --grid NL.NL.NL.NT --mpi 2.2.2.1 --threads 20 --accelerator-threads 4 ${OPTIONS} --ParameterFile XML"
lrun -M -gpu -N 2 -n 8 $APP $PARAMS >& log.lrun.JOBNAME

echo 'Done'
