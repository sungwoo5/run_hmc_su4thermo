#!/bin/bash

# To test if "and plaquette, link trace, and checksum agree" exist
# as a simple test that the gauge configuration was read and had the values are consistent 

log_didntpass=log_didntpass.txt
echo -n "" > ${log_didntpass}

for d in ../../../confs/conf_nc4nf1_328_*1000; do
    out_nodelist=nodelist_${d##*conf_nc4nf1_}.txt
    printf "# icfg\tnodelist\n" >${out_nodelist}

    # reprod test runs have log filename have no jobid as suffix
    # but have the date.. so I scan the logfile using this fact
    for f in $(ls ${d}/log/log.*_10* | sort -V); do

    	logfilename=${f##*/}
    	icfg=$(echo $logfilename | awk -F_ '{print $4}' | sed 's/cont//g')
	
    	echo ${logfilename}, ${icfg}


	# test if there are more than 2 log files
    	loglist=($(ls ${d}/log/log.*cont${icfg}_*))
    	if [ ${#loglist[@]} -gt 1 ]; then
    	    echo "there are 2 or more log files for this icfg"
    	    ls ${d}/log/log.*cont${icfg}_*
    	fi

	# check initial read test
    	if ! grep -q "and plaquette, link trace, and checksum agree" $f; then
    	    ls $f
    	elif ! $(tail -1 $f | grep -q "all pass"); then	# final reproducibility test!
	    echo "$f didn't pass"
	    echo "$f didn't pass" >> ${log_didntpass}
	    tail -5 $f >> ${log_didntpass}
    	else
	    # only for the log that passes the cfg read test
    	    printf "%d\t" ${icfg} >> ${out_nodelist}
	    
    	    awk '/^START/ {exit} { print }' $f | grep "tuolumne" | sed 's/tuolumne//g' \
    		| awk '{printf("%s,",$1)}' >> ${out_nodelist}
	    
    	    printf "\n" >> ${out_nodelist}

    	fi



	
    done


done

# combined full nodelist
out=nodelist_allpass.txt
echo -n "" > ${out}
for f in nodelist_328*txt; do
    awk '/^[0-9]/ {print $2}' $f | sed 's/,/ /g'>> ${out}
done
