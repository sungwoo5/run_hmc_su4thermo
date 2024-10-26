#!/bin/bash
#use node_distribution_factor.py

#for f in analyze_328_b10p80c_m0p1000.txt; do
#for f in analyze_328_*.txt; do
for f in ../2.runtimediff/analyze_328_b10p8[05]*txt; do

    f2=plot_${f##analyze_}
    echo -n "" > $f2
    
    awk '/^[0-9]/ {print $3, $5}' $f >tmp
    
    # Loop through each line of the file and pass it to the Python script
    while IFS= read -r line; do
	arr=($line)
	echo -n ${arr[0]} " " >>$f2
	./node_distribution_factor.py ${arr[1]} >>$f2
    done < tmp
    
done
