#!/bin/bash


# Time interval between checks (in seconds)
INTERVAL=3600  # e.g., 1800 seconds (30 minutes)
#INTERVAL=300  # 5 minutes


dirlist=("conf_nc4nf1_2412_b11p20c_m0p0667"
	 "conf_nc4nf1_2412_b11p20_m0p0667"
	 "conf_nc4nf1_2412_b11p30c_m0p0667"
	 "conf_nc4nf1_2412_b11p30_m0p0667"
	 "conf_nc4nf1_2412_b11p40c_m0p0667"
	 "conf_nc4nf1_2412_b11p40_m0p0667"
	 "conf_nc4nf1_2412_b11p50c_m0p0667"
	 "conf_nc4nf1_2412_b11p50_m0p0667"
	 "conf_nc4nf1_2412_b11p60c_m0p0667"
	 "conf_nc4nf1_2412_b11p60_m0p0667"
	 "conf_nc4nf1_2412_b11p70c_m0p0667"
	 "conf_nc4nf1_2412_b11p70_m0p0667"
	 "conf_nc4nf1_2412_b11p80c_m0p0667"
	 "conf_nc4nf1_2412_b11p80_m0p0667"
	 "conf_nc4nf1_2412_b11p90c_m0p0667"
	 "conf_nc4nf1_2412_b11p90_m0p0667"
	 "conf_nc4nf1_2412_b12p00c_m0p0667"
	 "conf_nc4nf1_2412_b12p00_m0p0667"
	)

	 # "conf_nc4nf1_2412_b10p80c_m0p0667"
	 # "conf_nc4nf1_2412_b10p80_m0p0667"
	 # "conf_nc4nf1_2412_b12p40c_m0p0667"
	 # "conf_nc4nf1_2412_b12p40_m0p0667"
	 # "conf_nc4nf1_2412_b12p70c_m0p0667"
	 # "conf_nc4nf1_2412_b12p70_m0p0667"

# # clean job id tmp files
# for d in ${dirlist[@]}; do
#     rm ${d}/.job_*
# done
# --> I have thought about this, and
#     there's nothing wrong to make the job dependency even if the JOB0 is already finished and not running 

# Main loop to repeat by INTERVAL
while true; do


    # loop over the dir list
    for d in ${dirlist[@]}; do
	date
	cd $d
	label=${d##*conf_nc4nf1_}

	JOB0=".job_0"	# to be used for the next dependency submission 
	JOB1=".job_1"
	

	# check jobs exist
	if [ ! -e "$JOB1" ]; then

	    echo $d
	    if [ ! -e "$JOB0" ]; then
		cmd="flux batch --job-name=${label}_cont ../fluxauto_pdebug_cont.sh > ${JOB0}"
		echo ${cmd}
		eval ${cmd}
	    fi
	    
	    # once the job0 finished, ${JOB0} cache file will be removed
	    # and ${JOB1} file will become ${JOB0}
	    # Next thing to do is submitting the 2nd job
	    
	    # dependency job submission
	    # https://flux-framework.readthedocs.io/projects/flux-core/en/latest/man1/flux-batch.html#dependencies
	    cmd="flux batch --job-name=${label}_cont --dependency=afterany:$(cat $JOB0) ../fluxauto_pdebug_cont.sh > ${JOB1}"
	    echo ${cmd}
	    eval ${cmd}

	    rm ${JOB0}		# already used, so remove
	    mv ${JOB1} ${JOB0}	# JOB1 becomes JOB0 for later dependency job submittion

	fi

	cd -
    done

    sleep $INTERVAL
done


