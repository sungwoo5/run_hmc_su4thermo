#!/bin/bash


# Time interval between checks (in seconds)
INTERVAL=600  # e.g., 1800 seconds (30 minutes)
#INTERVAL=300  # 5 minutes

dirlist=($(ls -d conf_nc4nf0_328_b11p0[7-9]* conf_nc4nf0_328_b11p0[0-5]*) )
	 
# clean job id tmp files
for d in ${dirlist[@]}; do
    rm ${d}/.job_*
done
# --> I have thought about this, and
#     there's nothing wrong to make the job dependency even if the JOB0 is already finished and not running 

# Main loop to repeat by INTERVAL
while true; do


    # loop over the dir list
    for d in ${dirlist[@]}; do
	date
	cd $d
	label=${d##*conf_nc4nf0_}
	
	JOB0=".job_0"	# to be used for the next dependency submission 
	JOB1=".job_1"
	
	
	# check jobs exist
	if [ ! -e "$JOB1" ]; then
	    
	    echo $d
	    if [ ! -e "$JOB0" ]; then
		# cmd="flux batch --queue=pbatch  --job-name=${label}_cont ../fluxauto_cont_328_Nf0_N4.sh > ${JOB0}"
		cmd="flux batch --queue=pbatch  --job-name=${label}_cont ../fluxauto_cont_328_Nf0_N16.sh > ${JOB0}"
		echo ${cmd}
		eval ${cmd}
	    fi
	    
	    # once the job0 finished, ${JOB0} cache file will be removed
	    # and ${JOB1} file will become ${JOB0}
	    # Next thing to do is submitting the 2nd job
	    
	    # dependency job submission
	    # https://flux-framework.readthedocs.io/projects/flux-core/en/latest/man1/flux-batch.html#dependencies
	    # cmd="flux batch --queue=pbatch --job-name=${label}_cont --dependency=afterany:$(cat $JOB0) ../fluxauto_cont_328_Nf0_N4.sh > ${JOB1}"
	    # submit only if the .job_0's status is running
	    # https://flux-framework.readthedocs.io/projects/flux-core/en/latest/man1/flux-jobs.html#job-status
	    job0id=$(cat $JOB0)
	    job0status=$(flux jobs $job0id | grep $job0id  | awk '{print $5}')
	    if [[ "$job0status" == "CD" || "$job0status" == "F" || "$job0status" == "R" ]]; then
		# CD: completed (I expect this, but haven't seen this after job finished..
		# F: failed (usually this one, so I regard this as finished..)
		# R: running
		cmd="flux batch --queue=pbatch --job-name=${label}_cont --dependency=afterany:$(cat $JOB0) ../fluxauto_cont_328_Nf0_N16.sh > ${JOB1}"
		echo ${cmd}
		eval ${cmd}

		rm ${JOB0}		# already used, so remove
		mv ${JOB1} ${JOB0}	# JOB1 becomes JOB0 for later dependency job submittion
	    fi
	fi

	cd -
    done

    sleep $INTERVAL
done


