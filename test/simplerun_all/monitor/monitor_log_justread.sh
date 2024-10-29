#!/bin/bash

# use the fparse of the original monitor dir
fparse_dir=/usr/WS2/lsd/sungwoo/SU4_sdm/run_hmc_su4thermo/monitor/fparse

#-------------------------
# run over the ensembles
for _d in ../../../confs/conf_nc4nf1_*/log; do
    d=${_d%%/log}
    outputlabel=${d##*/conf_nc4nf1_}
    output=${outputlabel}.txt
    # output=${d##*/conf_nc4nf1_}.txt

    ls -d $d
    
    #------------------------------
    # do we need to update output?
    if [ -e "$output" ]; then

	time_output=$(stat -c %Y "$output")
	output_is_newer=1

	# then test if the log files are updated after this output
	for f in ${d}/log/log.*; do 
	    
	    time_log=$(stat -c %Y "$f")

	    if [ "$time_output" -lt "$time_log" ]; then
		# log was updated after making output
		output_is_newer=0
		break		
	    fi
	done
	
	if [ $output_is_newer -eq 1 ]; then
	    echo "no need to update ${d}" 
	    # no need to update
	    continue
	fi
    fi

    #---------------
    # update output
    echo -n "" > $output
    for f in $(ls -rt ${d}/log/log.* ); do 
    # for fparse in $(ls ${fparse_dir}/${outputlabel}*.tmp | grep -v "cont") $(ls ${fparse_dir}/${outputlabel}*.tmp | grep "cont" | sort -V); do 
	fparse=${fparse_dir}/${f##*/log.}.tmp

	# save the parsed logfile into output
	cat ${fparse}>> ${output}
    done

done
