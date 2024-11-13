#!/bin/bash

#for d in conf_nc4nf1_328_b11p0[1-5]*_m0p4000; do
#for d in conf_nc4nf1_328_b10p8[1-4]*_m0p1000; do
#for d in conf_nc4nf1_328_b10p8[5-7]*_m0p1000; do
#for d in conf_nc4nf1_2412_b10p8*_m0p0667; do
#for d in conf_nc4nf1_2412_b11p*_m0p0667; do
#for d in conf_nc4nf1_2412_b12p*_m0p0667; do
#for d in conf_nc4nf1_248_b1*_m0p0[15]00; do
#for d in conf_nc4nf1_248_b1*_m0p1000; do
for d in conf_nc4nf1_248_b1*_m0p4000; do


    label=${d##*conf_nc4nf1_}

    lastconf=$(ls $d/conf_nc4nf1_${label}_lat.* | sort -V | tail -1)
    lasttraj=${lastconf##*lat.}

    firstconf=$(ls $d/conf_nc4nf1_${label}_lat.* | sort -V | head -1)
    firsttraj=${firstconf##*lat.}
    # firstrng=$d/conf_nc4nf1_${label}_rng.${firsttraj}
    # if [ ! -e "$firstrng" ]; then
    # 	echo "$firstrng not found"
    # 	exit 1
    # 

    # firsttraj=100

    firsttraj_to_be_deleted=${firsttraj}
    
    if (( $firsttraj_to_be_deleted % 4 == 0 )); then
	firsttraj_to_be_deleted=$(($firsttraj_to_be_deleted+2))
	echo "from" $firsttraj_to_be_deleted "to" ${lasttraj}
    elif (( $firsttraj_to_be_deleted % 4 == 2 )); then
	echo "from" $firsttraj_to_be_deleted "to" ${lasttraj}
    else
	echo "wrong firsttraj_to_be_deleted=${firsttraj_to_be_deleted}"
	exit 1
    fi

    for j in $(seq $firsttraj_to_be_deleted 4 $lasttraj); do
	ls $d/conf*_???.$j 2>/dev/null
	mv $d/conf*_???.$j ./trash/. 2>/dev/null
    done
    
done
