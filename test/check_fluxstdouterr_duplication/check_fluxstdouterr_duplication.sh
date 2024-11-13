#!/bin/bash

out=list_fluxstdouterr_duplication.out

# ../confs/conf_nc4nf1_248_b11p03c_m0p4000/log/_log.248_b11p03c_m0p4000_cont11004_fGmaEWi8Yzs   
# for d in ../confs/conf_nc4nf1_248_* ../confs/conf_nc4nf1_328_b10p8* ../confs/conf_nc4nf1_328_b11p5* ; do
#for d in ../confs/conf_nc4nf1_328_b11p05* ; do
#for d in ../confs/conf_nc4nf1_328_b11p0[0-4]*4000; do
for d in /p/lustre1/park49/SU4_sdm/run_gauge_conf/conf_nc4nf1_2412_*; do
    for f in $(ls ${d}/log.* 2>/dev/null | sort -V); do 
    # for f in $(ls ${d}/log/log.* 2>/dev/null | sort -V); do 

	ls $f
	init=`awk '/Start trajectory/ {print $13; exit}' $f`
	
	# Note that traj idx will be inferred from ${init} and single increment
	# but it can be wrong if the log file somehow repeated twice (it happens..)
	# so check if this didn't happen
	grep -A 1 "Unsmeared plaquette" $f | grep "Plaquette" | awk -v init="${init}" '{ if ( NR >0 && $10 != init+NR) { print "Error at line " NR ": Expected " (init+NR) ", but found " $10; exit 1 } }' >> ${out}
	# Check the exit status of awk
	if [[ $? -ne 0 ]]; then
	    echo $f "Trajectory index Sequential check failed." >> ${out}
	    # exit 1
	fi

    done

done
