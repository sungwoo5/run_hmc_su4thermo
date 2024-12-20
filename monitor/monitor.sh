#!/bin/bash
# parse the log files of each HMC run
# to monitor plaquette, polyakov loop, acceptance rate, and so on

# v2: save parse of each log file to tmp
# v3: add log/log.* files for new dir structure for tuo runs
# v4: deals with flux repeated stdout bug
#     use lastNR to scan only up to the correct amount
#     support nf0
fparse_dir=fparse
mkdir -p ${fparse_dir}

#-------------------------
# run over the ensembles
#for d in ../confs_nf0/conf_nc4nf0_328_b11p07; do
#for d in ../confs/conf_nc4nf1_248_b11p04c_m0p4000; do
#for d in ../confs/conf_nc4nf1_248_b1* ; do
for d in ../confs_elcap/conf_nc4nf1_328_b1* ; do
    outputlabel=${d##*/conf_nc4nf0_}
    if [[ ${d} == *"nc4nf1"* ]]; then
	outputlabel=${d##*/conf_nc4nf1_}
    fi
    output=${outputlabel}.txt

    #------------------------------
    # do we need to update output?
    if [ -e "$output" ]; then

    	time_output=$(stat -c %Y "$output")
    	output_is_newer=1

    	# then test if the log files are updated after this output
    	# add 2>/dev/null to supress error message in case there's no ${d}/log/log.*
    	for f in $(ls ${d}/log.* ${d}/log/log.* ${d}/log_elcap/log.* 2>/dev/null); do 
	    
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
    for f in $(ls ${d}/log.* ${d}/log/log.*  ${d}/log_elcap/log.* 2>/dev/null | sort -V); do 
    # for f in $(ls ${d}/log/log.* 2>/dev/null | sort -V); do 
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
		mkdir -p ${d}/log/fail
		mv $f ${d}/log/fail/.
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

	#----------------------------------------------------------------------------
	# Note that traj idx will be inferred from ${init} and single increment
	# but it can be wrong if the log file somehow repeated twice (it happens..)
	#
	# lastNR: the last NR that is increasing and correct, so to be saved
	#
	# and we truncate after lastNR in the following awks
	lastNR=$(grep -A 1 "Unsmeared plaquette" $f | grep "Plaquette" | awk -v init=${init} '{ lastNR=NR; if ( NR >0 && $10 != init+NR) { lastNR--; exit 1 } } END {print lastNR}')
	# echo "lastNR" $lastNR
	
       	# scan plaquette with traj idx first
	echo "# Plaquette" >> tmp0
	grep -A 1 "Unsmeared plaquette" $f | grep "Plaquette" | awk -v lastNR=${lastNR} 'NR <= lastNR {printf("%d %.7e\n",$10,$12)}' >> tmp0
	
	printf "\n\n\n# Polyakov_Loop(re,im)\n" >> tmp0
	grep "Polyakov Loop" $f | awk '{print $11,$13}' | sed 's/[(),]/ /g' | awk -v lastNR=${lastNR} 'NR <= lastNR {printf("%d\t%+.7e\t%+.7e\n",$1,$2,$3)}' >> tmp0

	printf "\n\n\n# Acc._Probability\n" >> tmp0
	awk -v init=${init} -v lastNR=${lastNR} 'BEGIN {idx=0} 
	       		     /Total H after trajectory/ {dH=$16; } 
	       		     /Skipping/ {idx++; printf("%d %.2e Skipping\n", init+idx, exp(-dH)); next} 
			     /exp\(-dH\)/ {idx++; printf("%d %.2e ",init+idx, $10); if ($10 > $13) print "Accepted"; else print "Rejected"; next} 
			     idx==lastNR {exit}' $f >> tmp0

	printf "\n\n\n# runtime_per_traj(s)\n" >> tmp0
	grep "Total time for trajectory" $f | awk  -v init=${init} -v lastNR="${lastNR}" 'NR <= lastNR {itraj++; printf("%d %.0f\n",init+itraj, $13)}' >> tmp0

	# CG inversion only if nf1
	if [[ ${d} == *"nc4nf1"* ]]; then
	    # Parse two lines of iterations (Red/Black?) after "Compute final actionGrid : Integrator : XXXXX s : Integrator action"
	    printf "\n\n\n# CG_iterations\n" >> tmp0
	    awk -v init=${init} -v lastNR=${lastNR} '
	    	/Compute final actionGrid / {itraj++; start=1; count=0; iter=0; next} 
		start && /ConjugateGradient Converged on iteration/ {count++; iter+=$12} 
		start && count==2 {start=0; print init+itraj, iter; if (itraj==lastNR) {exit}}
		' $f >> tmp0
	fi

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
	# as it was already tested that they are sequential with 1 increment 
	awk '{$1=""; print $0}' tmp0 > tmp
	# echo -e $header > ${fparse}	# The -e option enables interpretation of backslash escapes.
	echo -e $header > tmp0 # The -e option enables interpretation of backslash escapes.
	
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
                         print ""}}' tmp >> tmp0 #$fparse

	
	# create fparse file at the very end
	# to prevent fparse created and canceled while still running
	mv tmp0 ${fparse}
	rm tmp

    done

    #---------------
    # update output
    echo -n "" > $output
    # for f in $(ls ${d}/log.* | sort -V); do 
    # 	fparse=${fparse_dir}/${f##*/log.lrun.}.tmp
    for fparse in $(ls ${fparse_dir}/${outputlabel}*.tmp | grep -v "cont") $(ls ${fparse_dir}/${outputlabel}_*.tmp | grep "cont" | sort -V); do 
    # for fparse in $(ls ${fparse_dir}/${outputlabel}_*.tmp | grep "cont" | sort -V); do 
    	# fparse=${fparse_dir}/${f##*/log.lrun.}.tmp

	# save the parsed logfile into output
	cat ${fparse}>> ${output}
    done

done
