#!/bin/bash

# To test if "and plaquette, link trace, and checksum agree" exist
# as a simple test that the gauge configuration was read and had the values are consistent 

outdir=nodelist_nf0
mkdir -p ${outdir}

# only consider log files under separate log dir
for _d in ../../confs_nf0/conf_nc4nf0_*/log; do
    d=${_d%%/log}
    out_nodelist=${outdir}/nodelist_${d##*conf_nc4nf0_}.txt
    printf "# icfg\tnodelist\n" >${out_nodelist}
    
    for f in $(ls ${d}/log/log.* | sort -V); do

    	logfilename=${f##*/}
    	icfg=$(echo $logfilename | awk -F_ '{print $3}')
    	if [[ ${icfg} == *"cont"* ]]; then
	    icfg=$(echo $icfg | sed 's/cont//g')

	    loglist=($(ls ${d}/log/log.*cont${icfg}_*))
    	    if [ ${#loglist[@]} -gt 1 ]; then
    		# there are 2 or more log files for this icfg
		echo "there are 2 or more log files for this icfg"
    		ls -al ${d}/log/log.*cont${icfg}_*
    	    fi
	else
	    # fresh run log file without using cont0 filename convention
	    icfg=0
	fi
	
    	echo ${logfilename}, ${icfg}

    	if [ "$icfg" -eq 0 ] || grep -q "and plaquette, link trace, and checksum agree" $f; then
    	    # only for the log that passes the cfg read test
    	    printf "%d\t" ${icfg} >> ${out_nodelist}
	    
    	    awk '/^START/ {exit} { print }' $f | grep "tuolumne" | sed 's/tuolumne//g' \
    		| awk '{printf("%s,",$1)}' >> ${out_nodelist}
	    
    	    printf "\n" >> ${out_nodelist}
	else
    	    ls $f
    	fi



	
    done


done
