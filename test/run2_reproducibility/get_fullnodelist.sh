#!/bin/bash

output="fullnodelist_used.txt"
echo -n "" >${output}
for f in analyze*txt; do
    awk '/^[0-9]/{print $5}' $f | sed 's/\[//g' | sed 's/\]//g'| sed 's/,,/,/g' | sed 's/,/ /g'>>${output}
done
