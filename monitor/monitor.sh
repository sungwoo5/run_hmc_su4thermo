#!/bin/bash
# parse the log files of each HMC run
# to monitor plaquette, polyakov loop, acceptance rate, and so on

for d in ../conf_nc4nf1_*; do
    output=${d##*/conf_nc4nf1_}.txt
    echo -n "" > $output

    for f in ${d}/log.*; do 
	ls $f
	fparse=${f##*/log.lrun.}.tmp
	echo -n "" > $fparse

	# HMC parameters
	init=`awk '/Start trajectory/ {print $13; exit}' $f`
	startingtype=`awk '/Starting type/ {print $13; exit}' $f`
	trajlength=`awk '/Trajectory length/ {print $12; exit}' $f`
	mdsteps=`awk '/Number of MD steps/ {print $14; exit}' $f`

	echo "# Plaquette" >> $fparse
	grep -A 1 "Unsmeared plaquette" $f | grep "Plaquette" | awk '{printf("%d %.7e\n",$10,$12)}' >> $fparse

	printf "\n\n\n# Polyakov_Loop(re,im)\n" >> $fparse
	grep "Polyakov Loop" $f | awk '{print $11,$13}' | sed 's/[(),]/ /g' | awk '{printf("%d\t%+.7e\t%+.7e\n",$1,$2,$3)}' >> $fparse

	printf "\n\n\n# Acc._Probability\n" >> $fparse
	# grep "Acc. Probability" $f | awk '{print $11}' >> $fparse
	grep "exp(-dH)" $f | awk -v init=${init} '{itraj++; printf("%d %.2e ", init+itraj, $10); if ($10 > $13) print "Accepted"; else print "Rejected";}' >> $fparse


	printf "\n\n\n# runtime_per_traj(s)\n" >> $fparse
	grep "Total time for trajectory" $f | awk  -v init=${init} '{itraj++; printf("%d %.0f\n",init+itraj, $13)}' >> $fparse
	
	# Parse two lines of iterations (Red/Black?) after "Compute final actionGrid : Integrator : XXXXX s : Integrator action"
	#-------------
	# /^ConjugateGradient Converged on iteration/ {c=4; next}: When a line starts with "ConjugateGradient Converged on iteration", set a counter c to 4 and skip to the next line.
	# c && !--c {print; exit}: If c is non-zero, decrement c. If c becomes zero after decrementing, print the current line and exit.
	# awk -v init=${init} '/Compute final actionGrid /  {count++; r=4; b=15; next} r && !--r {R=$12} b && !--b {B=$12; print R+B}' $f >> $fparse

	printf "\n\n\n# CG_iterations\n" >> $fparse
	awk -v init=${init} '
/Compute final actionGrid / {itraj++; start=1; count=0; iter=0; next} 
start && /ConjugateGradient Converged on iteration/ {count++; iter+=$12} 
start && count==2 {start=0; print init+itraj, iter}' $f >> $fparse

	# parse finished
	# make it multicolumn

	#============================================
	header="# Starting_type: ${startingtype}\n"
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
