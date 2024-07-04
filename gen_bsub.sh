#!/bin/bash

#====================================================
# JOB=$NL$NT"_b"$str_beta"_m"$str_mass
# dir_name="conf_nc4nf1_"${JOB}
NL=32
NT=8

for dir_name in conf_nc4nf1_${NL}${NT}_*; do
    JOB=${dir_name##conf_nc4nf1_}

    #---------------------------
    # create lsf batch script 

    baselsf="bsubcont_base.sh"

    LSF=${dir_name}/"bsub_cont_2.sh"
    cp -a $baselsf $LSF

    sed -i 's/JOBNAME/'"${JOB}"'/g' $LSF
    sed -i 's/NL/'"${NL}"'/g' $LSF
    sed -i 's/NT/'"${NT}"'/g' $LSF



    baselsf="bsubcont_base_1.sh"

    LSF=${dir_name}/"bsub_cont_1.sh"
    cp -a $baselsf $LSF

    sed -i 's/JOBNAME/'"${JOB}"'/g' $LSF
    sed -i 's/NL/'"${NL}"'/g' $LSF
    sed -i 's/NT/'"${NT}"'/g' $LSF

done
