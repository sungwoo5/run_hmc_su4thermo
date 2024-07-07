# run_hmc_su4thermo

ex) to clean the dirs
dcp -v -p conf_nc4nf1_2412_b1* /p/lustre1/park49/SU4_sdm/run_gauge_conf/. >& log.dcp_2412 &
for d in conf_nc4nf1_2412_b1*; do ls -ald $d; ./run_clean.sh $d; done &>> log.clean_070724 &