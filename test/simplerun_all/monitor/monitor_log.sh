#!/bin/bash
# parse the log files of each HMC run
# to monitor plaquette, polyakov loop, acceptance rate, and so on

# v2: save parse of each log file to tmp

# 100724
# this is to monitor the test run2
fparse_dir=fparse
mkdir -p ${fparse_dir}

#-------------------------
# run over the ensembles
#for d in ../conf_nc4nf1_248_*100 ../conf_nc4nf1_248_*500 ../conf_nc4nf1_??8_b10p[7-9]*1000; do
#for d in ../conf_nc4nf1_248_b10p75*100; do
#for d in ../confs/conf_nc4nf1_??12_*667; do
#for d in ../../confs/conf_nc4nf1_328_*1000; do
for d in ../../confs/conf_nc4nf1_??8_*[14]000; do
    outputlabel=${d##*/conf_nc4nf1_}
    output=${outputlabel}.txt
    # output=${d##*/conf_nc4nf1_}.txt

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

    #-----------------------------
    # looking into each log file
    for f in $(ls ${d}/log/log.* | sort -V); do 
	ls $f
	fparse=${fparse_dir}/${f##*/log.}.tmp


	#------------------------------
	# do we need to update tmp parse file?
	if [ -e "$fparse" ]; then

	    time_fparse=$(stat -c %Y "$fparse")
	    fparse_is_newer=1

	    time_log=$(stat -c %Y "$f")
	    
	    if [ "$time_fparse" -lt "$time_log" ]; then
		# log was updated after making fparse
		# so proceed to update
		:
	    else
		# echo "no need to update ${fparse}" 
		# no need to update
		continue
	    fi
	fi



	#----------------
	# start parsing
	echo -n "" > $fparse

	# HMC parameters
	init=`awk '/Start trajectory/ {print $13; exit}' $f`
	startingtype=`awk '/Starting type/ {print $13; exit}' $f`
	if [ ${startingtype} == "HotStart" ] ||  [ ${startingtype} == "ColdStart" ]  ||  [ ${startingtype} == "CheckpointStartReseed" ] ; then
	    serial_seed=`awk '/Reseeding serial RNG with seed vector/ {print $14, $15, $16, $17, $18; exit}' $f`
	    parallel_seed=`awk '/Reseeding parallel RNG with seed vector/ {print $14, $15, $16, $17, $18; exit}' $f`
	fi
	trajlength=`awk '/Trajectory length/ {print $12; exit}' $f`
	mdsteps=`awk '/Number of MD steps/ {print $14; exit}' $f`

	# echo "# Plaquette" >> $fparse
	# grep -A 1 "Unsmeared plaquette" $f | grep "Plaquette" | awk '{printf("%d %.7e\n",$10,$12)}' >> $fparse

	# printf "\n\n\n# Polyakov_Loop(re,im)\n" >> $fparse
	# grep "Polyakov Loop" $f | awk '{print $11,$13}' | sed 's/[(),]/ /g' | awk '{printf("%d\t%+.7e\t%+.7e\n",$1,$2,$3)}' >> $fparse

	# printf "\n\n\n# Acc._Probability\n" >> $fparse
	# # grep "exp(-dH)" $f | awk -v init=${init} '{itraj++; printf("%d %.2e ", init+itraj, $10); if ($10 > $13) print "Accepted"; else print "Rejected";}' >> $fparse
	# awk '/Skipping/ {printf("1 %.2e Skipping\n", exp(-prev2)); next} /exp\(-dH\)/ {printf("1 %.2e ",$10); if ($10 > $13) print "Accepted"; else print "Rejected"; next} {prev2=prev1; prev1=$16}' $f >> $fparse

	printf "\n\n\n# runtime_per_traj(s)\n" >> $fparse
	grep "Total time for trajectory" $f | awk  -v init=${init} '{itraj++; printf("%d %.0f\n",init+itraj, $13)}' >> $fparse
	
	# Parse two lines of iterations (Red/Black?) after "Compute final actionGrid : Integrator : XXXXX s : Integrator action"
	printf "\n\n\n# CG_iterations\n" >> $fparse
	awk -v init=${init} '
/Compute final actionGrid / {itraj++; start=1; count=0; iter=0; next} 
start && /ConjugateGradient Converged on iteration/ {count++; iter+=$12} 
start && count==2 {start=0; print init+itraj, iter}' $f >> $fparse



	
# 	#============
# 	f2=$(ls ${d}/run2/log/log.*run2_${f##*_})
# 	# parse finished
# 	printf "\n\n\n# runtime_per_traj(s)\n" >> $fparse
# 	grep "Total time for trajectory" $f2 | awk  -v init=${init} '{itraj++; printf("%d %.0f\n",init+itraj, $13)}' >> $fparse
	
# 	# Parse two lines of iterations (Red/Black?) after "Compute final actionGrid : Integrator : XXXXX s : Integrator action"
# 	printf "\n\n\n# CG_iterations\n" >> $fparse
# 	awk -v init=${init} '
# /Compute final actionGrid / {itraj++; start=1; count=0; iter=0; next} 
# start && /ConjugateGradient Converged on iteration/ {count++; iter+=$12} 
# start && count==2 {start=0; print init+itraj, iter}' $f2 >> $fparse



	
	
	# parse finished

	# make it multicolumn
	#============================================
	header="# Starting_type: ${startingtype}\n"
	if [ ${startingtype} == "CheckpointStartReseed" ]; then
	    zerothconf=${d}/${d##*/}_lat.0
	    header+="# "
	    header+="$(ls -l ${zerothconf} | cut -d ' ' -f 9- | sed 's/\.\.\///g')\n"
	fi
	if [ ${startingtype} == "HotStart" ] ||  [ ${startingtype} == "ColdStart" ] ||  [ ${startingtype} == "CheckpointStartReseed" ]; then
	    header+="# serial RNG seed: \t${serial_seed}\n"
	    header+="# parallel RNG seed:\t${parallel_seed}\n"
	fi
	header+="# Trajectory_length / Number_of_MD_steps: ${trajlength} / ${mdsteps}"

	# first remove the trajectory index
	awk '{$1=""; print $0}' $fparse > tmp
	echo -e $header > ${fparse}	# The -e option enables interpretation of backslash escapes.
	
	# make 2d array for multicolumn text
	# check if all the columns have the same rows (Ntraj[NR]),
	# truncate for the smallest Ntraj[NR]
	awk -v init=${init} '
BEGIN{RS="";FS="\n"} 
{ 
   Ntraj[NR] = NF;
   for(i=1;i<=NF;i++) a[NR,i]=$i;
} 
END{
   minNtraj = Ntraj[1];
   for(k=2;k<=NR;k++) if(Ntraj[k] < minNtraj) minNtraj = Ntraj[k];

   for(j=1;j<=minNtraj;j++) { if(j==1){printf "# \t"}else{printf j-1+init "\t"}; 
                         for(i=1;i<=NR;i++) printf a[i,j] "\t"; 
                         print ""}}' tmp >> $fparse

	rm tmp

    done

    #---------------
    # update output
    echo -n "" > $output
    # for f in $(ls ${d}/log/log.* | sort -V); do 
    for fparse in $(ls ${fparse_dir}/${outputlabel}*.tmp | grep -v "cont") $(ls ${fparse_dir}/${outputlabel}*.tmp | grep "cont" | sort -V); do 
	# fparse=${fparse_dir}/${f##*/log.}.tmp

	# save the parsed logfile into output
	cat ${fparse}>> ${output}
    done

done
