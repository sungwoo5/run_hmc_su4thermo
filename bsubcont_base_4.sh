#!/bin/bash
### LSF syntax
#BSUB -nnodes 4                   #number of nodes
#BSUB -W 720                      #walltime in minutes
##BSUB -G guests                   #account
#BSUB -e JOBNAME_cont.err             #stderr
#BSUB -o JOBNAME_cont.out             #stdout
#BSUB -J JOBNAME_cont                    #name of job
#BSUB -q pbatch                   #queue to use

### Shell scripting
# https://hpc.llnl.gov/documentation/tutorials/using-lc-s-sierra-systems#BatchScripts
date; hostname
echo -n 'JobID is '; echo $LSB_JOBID

# check the last saved gauge configuration and rng
lastconf=$(ls conf_nc4nf1_JOBNAME_lat.* | sort -V | tail -1)
lasttraj=${lastconf##*lat.}
lastrng=conf_nc4nf1_JOBNAME_rng.${lasttraj}
if [ ! -e "$lastrng" ]; then
    echo "$lastrng not found"
    exit 1
fi

# create xml for CheckpointStart from lasttraj
BASEXML=./ip_hmc_mobius_base_cont.xml
XML=ip_hmc_mobius_cont_${lasttraj}.xml
sed 's/START_TRAJECTORY/'${lasttraj}'/g' ${BASEXML} > ${XML}

### Launch parallel executable
GRID_DIR=/usr/WS2/lsd/sungwoo/SU4_sdm/Grid_sdm_build/lassen
source ${GRID_DIR}/env.sh
APP="$GRID_DIR/install/gauge_gen_Nc4/bin/dweofa_mobius_HSDM_v3"

OPTIONS="--decomposition --comms-concurrent --comms-overlap --debug-mem  --shm 2048 --shm-mpi 1"

PARAMS=" --grid NL.NL.NL.NT --mpi 4.2.2.1 --threads 20 --accelerator-threads 4 ${OPTIONS} --ParameterFile ${XML}"
lrun -M -gpu -N 4 -n 16 $APP $PARAMS >& log.lrun.JOBNAME_cont${lasttraj}

echo 'Done'
