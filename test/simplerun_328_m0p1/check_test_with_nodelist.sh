#!/bin/bash

# To test if "and plaquette, link trace, and checksum agree" exist
# as a simple test that the gauge configuration was read and had the values are consistent 


for d in ../../confs/conf_nc4nf1_328_*1000; do
    out_nodelist=nodelist_${d##*conf_nc4nf1_}.txt
    printf "# icfg\tnodelist\n" >${out_nodelist}
    
    for f in $(ls ${d}/log/log.* | sort -V); do

    	logfilename=${f##*/}
    	icfg=$(echo $logfilename | awk -F_ '{print $4}' | sed 's/cont//g')
	
    	echo ${logfilename}, ${icfg}

    	# loglist=($(ls ${d}/log/log.*cont${icfg}_*))
    	# if [ ${#loglist[@]} -gt 1 ]; then
    	#     # there are 2 or more log files for this icfg
    	#     ls ${d}/log/log.*cont${icfg}_*
    	# fi

    	if ! grep -q "and plaquette, link trace, and checksum agree" $f; then
    	    ls $f
    	else
	    # only for the log that passes the cfg read test
    	    printf "%d\t" ${icfg} >> ${out_nodelist}
	    
    	    awk '/^START/ {exit} { print }' $f | grep "tuolumne" | sed 's/tuolumne//g' \
    		| awk '{printf("%s,",$1)}' >> ${out_nodelist}
	    
    	    printf "\n" >> ${out_nodelist}

    	fi



	
    done


done
