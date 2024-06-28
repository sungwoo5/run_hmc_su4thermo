#!/bin/bash
# parse the log files of each HMC run
# to monitor plaquette, polyakov loop, acceptance rate, and so on

for d in /usr/WS2/lsd/matsumoto5/su4_16_8/cold/beta1*m0.10 /usr/WS2/lsd/matsumoto5/su4_16_8/hot/beta1*m0.10; do
    output=$(echo ${d##*/matsumoto5/} | sed 's/\//_/g').txt

    #------------------------------
    # do we need to update output?
    if [ -e "$output" ]; then

	time_output=$(stat -c %Y "$output")
	output_is_newer=1

	# then test if the log files are updated after this output
	for f in ${d}/slurm-*.out; do 
	    
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

    #---------
    # start 
    echo -n "" > $output

    for f in $(ls ${d}/slurm-*.out | sort -V); do 
	ls $f
	fparse=${f##*/slurm-}.tmp
	echo $fparse
	echo -n "" > $fparse

	# HMC parameters
	init=`awk '/Start trajectory/ {print $13; exit}' $f`
	startingtype=`awk '/Starting type/ {print $13; exit}' $f`
	if [ ${startingtype} == "HotStart" ] ||  [ ${startingtype} == "ColdStart" ]; then
	    serial_seed=`awk '/Reseeding serial RNG with seed vector/ {print $14, $15, $16, $17, $18; exit}' $f`
	    parallel_seed=`awk '/Reseeding parallel RNG with seed vector/ {print $14, $15, $16, $17, $18; exit}' $f`
	fi
	trajlength=`awk '/Trajectory length/ {print $12; exit}' $f`
	mdsteps=`awk '/Number of MD steps/ {print $14; exit}' $f`

	echo "# Plaquette" >> $fparse
	grep -A 1 "Unsmeared plaquette" $f | grep "Plaquette" | awk '{printf("%d %.7e\n",$10,$12)}' >> $fparse

	printf "\n\n\n# Polyakov_Loop(re,im)\n" >> $fparse
	grep "Polyakov Loop" $f | awk '{print $11,$13}' | sed 's/[(),]/ /g' | awk '{printf("%d\t%+.7e\t%+.7e\n",$1,$2,$3)}' >> $fparse

	printf "\n\n\n# Acc._Probability\n" >> $fparse
	grep "exp(-dH)" $f | awk -v init=${init} '{itraj++; printf("%d %.2e ", init+itraj, $10); if ($10 > $13) print "Accepted"; else print "Rejected";}' >> $fparse


	printf "\n\n\n# runtime_per_traj(s)\n" >> $fparse
	grep "Total time for trajectory" $f | awk  -v init=${init} '{itraj++; printf("%d %.0f\n",init+itraj, $13)}' >> $fparse
	
	# Parse two lines of iterations (Red/Black?) after "Compute final actionGrid : Integrator : XXXXX s : Integrator action"
	printf "\n\n\n# CG_iterations\n" >> $fparse
	awk -v init=${init} '
/Compute final actionGrid / {itraj++; start=1; count=0; iter=0; next} 
start && /ConjugateGradient Converged on iteration/ {count++; iter+=$12} 
start && count==2 {start=0; print init+itraj, iter}' $f >> $fparse

	# parse finished
	# make it multicolumn

	#============================================
	header="# Starting_type: ${startingtype}\n"
	if [ ${startingtype} == "HotStart" ] ||  [ ${startingtype} == "ColdStart" ]; then
	    header+="# serial RNG seed: \t${serial_seed}\n"
	    header+="# parallel RNG seed:\t${parallel_seed}\n"
	fi
	header+="# Trajectory_length / Number_of_MD_steps: ${trajlength} / ${mdsteps}"

	# first remove the trajectory index
	awk '{$1=""; print $0}' $fparse > tmp
	echo -e $header > ${fparse}	# The -e option enables interpretation of backslash escapes.
	awk -v init=${init} 'BEGIN{RS="";FS="\n"} {for(i=1;i<=NF;i++) a[NR,i]=$i} 
END{for(j=1;j<=NF;j++) { if(j==1){printf "# \t"}else{printf j-1+init "\t"}; 
                         for(i=1;i<=NR;i++) printf a[i,j] "\t"; 
                         print ""}}' tmp >> $fparse

	# save the parsed logfile into output
	cat ${fparse}>> ${output}
	rm *tmp

    done
done
