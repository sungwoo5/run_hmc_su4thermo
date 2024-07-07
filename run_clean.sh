#!/bin/bash

# Check if the argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <directory>"
  exit 1
fi

d=$1

# Check if the directory exists
if [ ! -d "$d" ]; then
  echo "The directory '$d' does not exist."
  exit 1
fi

echo "============================================"
echo "Start cleaning ${d}"
date
echo ""
# Check the last saved gauge configuration and rng
# (finding the last trajectory)
lastconf=$(ls $d/conf_nc4nf1_*_b1?p*_m0p????_lat.* | sort -V | tail -1)
lasttraj=${lastconf##*lat.}
lastrng=$(echo $lastconf | sed 's/lat./rng./g')
if [ ! -e "$lastrng" ]; then
    echo "$lastrng not found"
    exit 1
fi
echo "found the last trajectory: ${lasttraj}"

# # Prompt for confirmation
# echo "last files:"
# echo "$lastconf"
# echo "$lastrng"
# read -p "Are you sure you want to clean the directory '$d' except the last files above? (y/n): " CONFIRMATION

# # Check the user's response
# if [ "$CONFIRMATION" != "y" ]; then
#   echo "Script execution cancelled."
#   exit 0
# fi

#====================================================================
# Check if all the conf and rng files exist in lustre2 or lustre1
if [[ $d == *"_24"* ]]; then
    backup_dir=/p/lustre1/park49/SU4_sdm/run_gauge_conf
else
    backup_dir=/p/lustre2/park49/SU4_sdm/run_gauge_conf
fi

# if backup_dir exists
if [ ! -d "${backup_dir}/${d}" ]; then
  echo "The backup directory '${backup_dir}/${d}' does not exist."
  exit 1
fi

echo "scanning back-up files in ${backup_dir}"
files_backup=$(find ${backup_dir}/${d}/conf_nc4nf1_*_b1?p*_m0p????_???.* -type f -exec basename {} \; | sort  -V)
echo "scanning files to be deleted here"
files_d=$(find ${d}/conf_nc4nf1_*_b1?p*_m0p????_???.* -type f -exec basename {} \; | sort  -V)



# Check if files_d is a subset of files_backup
echo "comparing file lists in two dirs"
subset=true
while IFS= read -r file; do
  if ! grep -qx "$file" <<< "$files_backup"; then
    subset=false
    break
  fi
done <<< "$files_d"

if $subset; then
    echo "pass"
else
    echo "fail, files in ${d} do not exist in ${backup_dir}/${d}"
    exit 1
fi


echo "cleaning all the lat and rng files except the last trajectory, ${lasttraj}"
# rename these last files to tmp
tmplastconf=${d}/tmp_$(basename $lastconf)
tmplastrng=${d}/tmp_$(basename $lastrng)
mv $lastconf $tmplastconf
mv $lastrng  $tmplastrng

# remove all the conf_*_lat.* and
rm ${d}/conf_nc4nf1_*_b1?p*_m0p????_???.*
mv $tmplastconf $lastconf
mv $tmplastrng $lastrng

echo "finished cleaning ${d}"
date
echo ""
