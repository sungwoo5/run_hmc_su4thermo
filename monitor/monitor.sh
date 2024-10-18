#!/bin/bash
# parse the log files of each HMC run
# to monitor plaquette, polyakov loop, acceptance rate, and so on

# v2: save parse of each log file to tmp
# v3: add log/log.* files for new dir structure for tuo runs
fparse_dir=fparse
mkdir -p ${fparse_dir}

#-------------------------
# run over the ensembles
#for d in ../conf_nc4nf1_248_*100 ../conf_nc4nf1_248_*500 ../conf_nc4nf1_??8_b10p[7-9]*1000; do
#for d in ../conf_nc4nf1_248_b10p75*100; do
#for d in ../confs/conf_nc4nf1_??12_*667; do
#for d in ../confs/conf_nc4nf1_328_b10p8*1000; do
for d in ../confs/conf_nc4nf1_328_b11p0*4000; do
    outputlabel=${d##*/conf_nc4nf1_}
    output=${outputlabel}.txt

    #------------------------------
    # do we need to update output?
    if [ -e "$output" ]; then

	time_output=$(stat -c %Y "$output")
	output_is_newer=1

	# then test if the log files are updated after this output
	# add 2>/dev/null to supress error message in case there's no ${d}/log/log.*
	for f in $(ls ${d}/log.* ${d}/log/log.* 2>/dev/null); do 
	    
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
    # add 2>/dev/null to supress error message in case there's no ${d}/log/log.*
    for f in $(ls ${d}/log.* ${d}/log/log.* 2>/dev/null | sort -V); do 
	ls $f
	if [[ ${f} == *"log.lrun."* ]]; then
	    fparse=${fparse_dir}/${f##*/log.lrun.}.tmp
	else
	    fparse=${fparse_dir}/${f##*/log.}.tmp
	fi
	
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

	# HMC parameters
	init=`awk '/Start trajectory/ {print $13; exit}' $f`
	startingtype=`awk '/Starting type/ {print $13; exit}' $f`

	# if the log already failed before even showing Starting type,
	# for ex, the previous traj conf have not saved properly, then checksum fails
	if [ -z "$startingtype" ]; then
	    # startingtype is empty, so check further
	    if ! grep -q "and plaquette, link trace, and checksum agree" $f; then
		# checksum failed, so skip this log file
		continue
	    else
		echo "$f, no Starting type found"
		exit 1
	    fi
	fi
	
	echo -n "" > tmp0
	
	if [ ${startingtype} == "HotStart" ] ||  [ ${startingtype} == "ColdStart" ]  ||  [ ${startingtype} == "CheckpointStartReseed" ] ; then
	    serial_seed=`awk '/Reseeding serial RNG with seed vector/ {print $14, $15, $16, $17, $18; exit}' $f`
	    parallel_seed=`awk '/Reseeding parallel RNG with seed vector/ {print $14, $15, $16, $17, $18; exit}' $f`
	fi
	trajlength=`awk '/Trajectory length/ {print $12; exit}' $f`
	mdsteps=`awk '/Number of MD steps/ {print $14; exit}' $f`

	echo "# Plaquette" >> tmp0
	grep -A 1 "Unsmeared plaquette" $f | grep "Plaquette" | awk '{printf("%d %.7e\n",$10,$12)}' >> tmp0

	printf "\n\n\n# Polyakov_Loop(re,im)\n" >> tmp0
	grep "Polyakov Loop" $f | awk '{print $11,$13}' | sed 's/[(),]/ /g' | awk '{printf("%d\t%+.7e\t%+.7e\n",$1,$2,$3)}' >> tmp0

	printf "\n\n\n# Acc._Probability\n" >> tmp0
	# grep "exp(-dH)" $f | awk -v init=${init} '{itraj++; printf("%d %.2e ", init+itraj, $10); if ($10 > $13) print "Accepted"; else print "Rejected";}' >> tmp0
	awk '/Skipping/ {printf("1 %.2e Skipping\n", exp(-prev2)); next} /exp\(-dH\)/ {printf("1 %.2e ",$10); if ($10 > $13) print "Accepted"; else print "Rejected"; next} {prev2=prev1; prev1=$16}' $f >> tmp0

	printf "\n\n\n# runtime_per_traj(s)\n" >> tmp0
	grep "Total time for trajectory" $f | awk  -v init=${init} '{itraj++; printf("%d %.0f\n",init+itraj, $13)}' >> tmp0
	
	# Parse two lines of iterations (Red/Black?) after "Compute final actionGrid : Integrator : XXXXX s : Integrator action"
	printf "\n\n\n# CG_iterations\n" >> tmp0
	awk -v init=${init} '
/Compute final actionGrid / {itraj++; start=1; count=0; iter=0; next} 
start && /ConjugateGradient Converged on iteration/ {count++; iter+=$12} 
start && count==2 {start=0; print init+itraj, iter}' $f >> tmp0

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
	awk '{$1=""; print $0}' tmp0 > tmp
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

	rm tmp0 tmp

    done

    #---------------
    # update output
    echo -n "" > $output
    # for f in $(ls ${d}/log.* | sort -V); do 
    # 	fparse=${fparse_dir}/${f##*/log.lrun.}.tmp
    for fparse in $(ls ${fparse_dir}/${outputlabel}*.tmp | sort -V); do 
    	# fparse=${fparse_dir}/${f##*/log.lrun.}.tmp

	# save the parsed logfile into output
	cat ${fparse}>> ${output}
    done

done
