#!/bin/bash
### LSF syntax
#BSUB -nnodes 2                   #number of nodes
#BSUB -W 30                      #walltime in minutes
##BSUB -G guests                   #account
#BSUB -e myerrors.txt             #stderr
#BSUB -o myoutput.txt             #stdout
#BSUB -J myjob                    #name of job
#BSUB -q pdebug                   #queue to use

### Shell scripting
# https://hpc.llnl.gov/documentation/tutorials/using-lc-s-sierra-systems#BatchScripts
date; hostname
echo -n 'JobID is '; echo $LSB_JOBID

### Launch parallel executable
GRID_DIR=../..
source ${GRID_DIR}/env.sh
APP="$GRID_DIR/install/gauge_gen_Nc4/bin/dweofa_mobius_HSDM_v3"

OPTIONS="--decomposition  --comms-concurrent --comms-overlap --debug-mem  --shm 2048 --shm-mpi 1"

# PARAMS=" --grid 24.24.24.12 --mpi 2.2.1.1 --threads 20 --accelerator-threads 4 ${OPTIONS} --ParameterFile ip_hmc_mobius.xml"
# lrun -M -gpu -N 1 -n 4 $APP $PARAMS >& log.lrun.N1n4.2412

# PARAMS=" --grid 24.24.24.24 --mpi 2.2.1.1 --threads 20 --accelerator-threads 4 ${OPTIONS} --ParameterFile ip_hmc_mobius.xml"
# lrun -M -gpu -N 1 -n 4 $APP $PARAMS >& log.lrun.N1n4.2424

PARAMS=" --grid 32.32.32.16 --mpi 2.2.2.1 --threads 20 --accelerator-threads 4 ${OPTIONS} --ParameterFile ip_hmc_mobius_trj2.xml"
lrun -M -gpu -N 2 -n 8 $APP $PARAMS >& log.lrun.N2n8.3216_try2

# OPTIONS="--decomposition  --comms-concurrent --comms-overlap --debug-mem  --shm 3096 --shm-mpi 1"
# PARAMS=" --grid 32.32.32.24 --mpi 2.2.2.1 --threads 20 --accelerator-threads 4 ${OPTIONS} --ParameterFile ip_hmc_mobius_trj2.xml"
# lrun -M -gpu -N 2 -n 8 $APP $PARAMS >& log.lrun.N2n8.3224

# PARAMS=" --grid 32.32.32.32 --mpi 2.2.2.1 --threads 20 --accelerator-threads 4 ${OPTIONS} --ParameterFile ip_hmc_mobius_trj2.xml"
# lrun -M -gpu -N 2 -n 8 $APP $PARAMS >& log.lrun.N2n8.3232

# PARAMS=" --grid 48.48.48.12 --mpi 2.2.2.1 --threads 20 --accelerator-threads 4 ${OPTIONS} --ParameterFile ip_hmc_mobius_trj2.xml"
# lrun -M -gpu -N 2 -n 8 $APP $PARAMS >& log.lrun.N2n8.4812

echo 'Done'
