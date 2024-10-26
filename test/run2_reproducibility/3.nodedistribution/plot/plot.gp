# plot.gp
#set font "Helvetica,12"  # Set global font to Helvetica, size 12

set term pdfcairo font "Helvetica,12"  # Set the terminal to PDF with a font size
set output "perf_vs_nodedist_reprodtest100724_102324.pdf"                # Specify the output PDF file name


set title "Grid SU(4) MDWF HMC 32^3x8, (-N 8 -n 32)x2 jobs (10/07, 10/23-24) on Tuolumne "
set xlabel "node distribution factor difference (run1 - run2)"
set ylabel "runtime difference (run1 - run2) [%]"
set label "node distribution factor = \n(n\\_cabinet-1)+(n\\_racks-1)*8" at 5, -10
set label "1 rack = 8 cabinets\n1 cabinet = 8 blades\n1 blade = 2 nodes" at -19, -10
#m=15399.4/3/1000

# plot "data.txt" using 2:($3/1000) with linespoints title "data", \
#      m*x title sprintf("ideal") lw 2

plot "../data2.txt" using ($2-$3):1 title "data", \
