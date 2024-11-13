#!/bin/bash
# two runs within a single job allocation,
# [102224 sungwoo] exclude the nodes that were already tested


# Time interval between checks (in seconds)
INTERVAL=2400  # e.g., 1800 seconds (30 minutes)


dirlist=($(ls -d conf_nc4nf1_328_b10p80*_m0p1000))

script_nodelist="/usr/WS2/lsd/sungwoo/SU4_sdm/run_hmc_su4thermo/scripts/run2_reproducibility/makenodelist_exclude.py"
nodelist_used="nodelist_used_run2.txt"

# clean job id tmp files
for d in ${dirlist[@]}; do
    rm ${d}/.job_*
done
# This might needed to make sure there's correct .job_0 exists for job0status test

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

		excl_nodelist=$(${script_nodelist} ../${nodelist_used})

		# https://flux-framework.readthedocs.io/projects/flux-core/en/latest/man1/flux-batch.html#constraints
		cmd="flux batch --job-name=${label}_cont --requires=-host:tuolumne[${excl_nodelist}] ../fluxauto_pdebug_cont_328_run2_N16.sh > ${JOB0}"
		echo ${cmd}
		eval ${cmd}
	    fi
	    
	    # once the job0 finished, ${JOB0} cache file will be removed
	    # and ${JOB1} file will become ${JOB0}
	    # Next thing to do is submitting the 2nd job
	    
	    # dependency job submission
	    # https://flux-framework.readthedocs.io/projects/flux-core/en/latest/man1/flux-batch.html#dependencies

	    # submit only if the .job_0's status is running
	    # https://flux-framework.readthedocs.io/projects/flux-core/en/latest/man1/flux-jobs.html#job-status
	    job0id=$(cat $JOB0)
	    job0status=$(flux jobs $job0id | grep $job0id  | awk '{print $5}')
	    if [[ "$job0status" == "CD" || "$job0status" == "F" || "$job0status" == "R" ]]; then
		# CD: completed (I expect this, but haven't seen this after job finished..
		# F: failed (usually this one, so I regard this as finished..)
		# R: running
 
		excl_nodelist=$(${script_nodelist} ../${nodelist_used})
		
		cmd="flux batch --job-name=${label}_cont --requires=-host:tuolumne[${excl_nodelist}] --dependency=afterany:$(cat $JOB0) ../fluxauto_pdebug_cont_328_run2_N16.sh > ${JOB1}"
		echo ${cmd}
		eval ${cmd}

		rm ${JOB0}		# already used, so remove
		mv ${JOB1} ${JOB0}	# JOB1 becomes JOB0 for later dependency job submittion
	    fi

	fi
	sleep 1m
	cd -
    done

    sleep $INTERVAL
done

