#!/bin/bash

SOURCEDIR=/p/lassengpfs1/park49/SU4_sdm/run_gauge_conf

# rsync without configuration and rng files
# rsync -avz --exclude="conf_*_lat.*" --exclude="conf_*_rng.*" /p/lassengpfs1/park49/SU4_sdm/run_gauge_conf/conf_nc4nf1_248_b10p[6-9]*_m0p0[15]00 .
#rsync -avz --exclude="conf_*_lat.*" --exclude="conf_*_rng.*" ${SOURCEDIR}/conf_nc4nf1_328_b10p8*_m0p1000 .
#rsync -avz --exclude="conf_*_lat.*" --exclude="conf_*_rng.*" ${SOURCEDIR}/conf_nc4nf1_328_b10p8*_m0p1000 ${SOURCEDIR}/conf_nc4nf1_328_b11p0*_m0p4000 .
#rsync -avz --exclude="conf_*_lat.*" --exclude="conf_*_rng.*" ${SOURCEDIR}/conf_nc4nf1_248_b10p8*_m0p1000 ${SOURCEDIR}/conf_nc4nf1_248_b10p[6-9]*_m0p0[15]00 .


# for d in $(ls -d /p/lassengpfs1/park49/SU4_sdm/run_gauge_conf/conf_nc4nf1_248_b10p[6-9]*_m0p0[15]00); do
#for d in $(ls -d /p/lassengpfs1/park49/SU4_sdm/run_gauge_conf/conf_nc4nf1_248_b10p[89]*_m0p1000 /p/lassengpfs1/park49/SU4_sdm/run_gauge_conf/conf_nc4nf1_248_b11p00*_m0p1000); do
# for d in $(ls -d ${SOURCEDIR}/conf_nc4nf1_328_b10p8*_m0p1000 ${SOURCEDIR}/conf_nc4nf1_328_b11p0*_m0p4000); do
# for d in $(ls -d ${SOURCEDIR}/conf_nc4nf1_248_b10p8*_m0p1000); do
for d in $(ls -d ${SOURCEDIR}/conf_nc4nf1_248_b10p8*_m0p1000 ${SOURCEDIR}/conf_nc4nf1_248_b10p[6-9]*_m0p0[15]00); do

    echo $d
    
    # check the last saved gauge configuration and rng
    lastconf=$(ls ${d}/conf_nc4nf1_*lat.* | sort -V | tail -1)
    lasttraj=${lastconf##*lat.}
    lastrng=$(echo $lastconf | sed 's/_lat/_rng/g')
    if [ ! -e "$lastrng" ]; then
    	echo "$lastrng not found"
    	exit 1
    fi
    local_d=${d##*/}
    echo ${local_d}, ${lasttraj}

    rsync -av $lastconf ${local_d}/.
    rsync -av $lastrng ${local_d}/.
    
done



