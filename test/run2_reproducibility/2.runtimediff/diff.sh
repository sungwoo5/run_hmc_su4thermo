#!/bin/bash

# awk '{ if (/^[0-9]/) print $0, $2-$4, $3-$5; else print $0}' $f
for f in ../1.monitor/328_b10p8[05]*txt ; do
awk 'BEGIN { block = 1; sum = 0; sum_sq=0; percent = 0; count = 0 } 
{
    if ($0 ~ /^#/) {
        if (count > 0) {
            avg = sum / count;
            variance = (sum_sq / count) - (avg * avg);
            stddev = (variance > 0) ? sqrt(variance) : 0;
            printf("%d\t%.4f(%.4f)\t%.4f\t%.4f\n",  first_row-1 ,avg , stddev , percent/count, avg/stddev) ;

        }
        block++;
        sum = 0; sum_sq=0; count = 0; percent=0 # Reset sum and count for the next block
        next;  # Skip the block delimiter line
    }
    if (count == 0) {
        first_row = $1;  # Store the first row of the block
    }
    
    # Assuming the line contains numerical data to calculate the average
    sum += ($2-$4);  # Add the first field (or change to the appropriate field)
    sum_sq += ($2-$4)*($2-$4);  # Add the first field (or change to the appropriate field)
    percent += ($2-$4)*2/($2+$4)*100;  # Add the first field (or change to the appropriate field)
    count++;    # Increment the count of numbers
}
END {
    if (count > 0) {
            avg = sum / count;
            variance = (sum_sq / count) - (avg * avg);
            stddev = (variance > 0) ? sqrt(variance) : 0;
            printf("%d\t%.4f(%.4f)\t%.4f\t%.4f\n",  first_row-1 ,avg , stddev , percent/count, avg/stddev) ;

            # print "Job " first_row-1 " Average: " avg "(" stddev ")\t", percent/count, avg/stddev ;

   }
}' $f > analyze_${f##*/}
done


# add caption
# add nodelist
#for f in analyze*txt; do
for f in analyze_328_b10p8[05]*txt; do

    f2=_${f}
    echo -n "" > ${f2}
    
    for j in $(cat $f | awk '{print $1}'); do
	_f=${f%.txt}
	label=${_f#analyze_}
	log=$(ls ../../../confs/conf_nc4nf1_${label}/log/log.${label}_cont${j}_*)


	# full nodelist, but divide into 2
	head -17 $log | tail -16 | sed 's/tuolumne//g' | awk '/^[0-9]/ {print $0}' \
	    | awk '{if(NR==1){printf("[")}; 
	      	    if(NR==9){printf("],[")};
		    printf("%s,",$1);
	      	    if(NR==16){printf("] ")}; }'>>${f2}

	# nodelist for orig run to make sure it agrees with 
	# the last nodes in the fulllist
	sed -n '70p' $log | sed 's/tuolumne//g' | sed 's/ /,/g' >>${f2}

    done
    
    paste -d '\t' $f $f2 > tmp
    mv tmp $f
    rm $f2

    awk '{sigma=int($4); if (sigma<0) sigma=-sigma; if (sigma<2){ print $0} else{ printf("%s ",$0); for(i=1; i<=sigma; i++){printf("*")}; print "";}} ' $f > tmp
    # mv tmp $f
    printf "# job\ttimediff\tpercent\tsigma\tnodelist\n" > $f
    cat tmp >> $f
    rm tmp
    
    
    echo "# (+), 2nd job (1st block) faster, 2nd block slower" >> ${f}
    echo "# (-), 1st job (2nd block) faster, 1st block slower" >> ${f}


done
