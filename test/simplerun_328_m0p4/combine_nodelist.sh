#!/bin/bash

output="fullnodelist_used.txt"
echo -n "" >${output}
for f in nodelist*txt; do
    awk '/^[0-9]/{print $2}' $f | sed 's/,$//g'| sed 's/,/\n/g'>>${output}
done
