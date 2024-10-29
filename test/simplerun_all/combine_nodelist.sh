#!/bin/bash

# check total number of jobs
# njobs=$(awk '/^log/ {print $0}' log.102124 | wc -l)
# echo "There were total ${njobs} jobs analyzed"

# output="fullnodelist_used.txt"
# echo -n "" >${output}
# for f in nodelist*/nodelist*txt; do
#     awk '/^[0-9]/{print $2}' $f | sed 's/,$//g'| sed 's/,/\n/g'>>${output}
# done

output="fullnodelist_used_nolinebreak.txt"
echo -n "" >${output}
for f in nodelist*/nodelist*txt; do
    awk '/^[0-9]/{print $2}' $f >>${output}
done
