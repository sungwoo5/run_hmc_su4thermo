#!/usr/bin/env python3

import gvar as gv
import numpy as np
import glob, lsqfit
from scipy import optimize
import sys, os
import matplotlib
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
import textwrap
from matplotlib.colors import ListedColormap, BoundaryNorm


fparsedir="/Users/sungwoo/work/sdm/thermo/run_hmc_su4thermo_1/monitor/fparse/"

def find_i_1hr(dat):
    time=0
    for i in range(len(dat)):
        time+=dat[i]
        if time>3600:
            break
    return i

#label_list=sorted(list(set([os.path.basename(f).split("_cont")[0] for f in glob.glob(fparsedir+"*_cont[2-9]??[0-9]_f*.tmp")])))
label_list=sorted(list(set([os.path.basename(f).split("_cont")[0] for f in glob.glob(fparsedir+"*_cont[2-9]??[0-9].tmp")])))
print(label_list)
# label="328_b10p80_m0p1000"
# # print(fparsedir+label+"_cont*.tmp")
for label in label_list:
#for label in ["248_b10p80_m0p1000"]:
    print(label)
    print(fparsedir+label+"_cont[2-9]??[0-9]_*.tmp")
    fig,ax=plt.subplots(figsize=(20,7))
    str_flist=""
    for f in sorted(glob.glob(fparsedir+label+"_cont[2-9]??[0-9]*.tmp")):
        if os.path.getsize(f) == 0:
            continue
        # print(f)

        try:
            dat=np.genfromtxt(f,usecols=(0,6))
            # figname=f.replace("../monitor","./runtime").replace(".txt",".pdf")

            x=range(len(dat))
            i_1hr=find_i_1hr(dat[:,1])
            ax.plot(x[:i_1hr+1], dat[:i_1hr+1,1], color='k', linewidth=1.5)
            if i_1hr+1<len(dat):
                ax.plot(x[i_1hr:], dat[i_1hr:,1], color='r', linewidth=1.5)
            # ax.plot(x, dat[:,1], color='r', linewidth=1.5)
            # print(f)
            str_flist+="%s, "%(f.split(label+"_")[-1].replace(".tmp",""))
        except:
            print("couldn't plot", f)

    wrapped_text = "\n".join(textwrap.wrap(str_flist, width=100))  # Adjust width to control line length
    ax.text(0.01, 0.98, wrapped_text, ha="left", va="top", transform=ax.transAxes, fontsize=12, color="blue")
    plt.ylabel("runtime per a trajectory [s]")
    plt.xlabel("trajectories")
    plt.text(0.8,0.05,"black: within 1hr of runtime",transform=ax.transAxes, fontsize=12, color="black")
    plt.text(0.8,0.02,"red: after 1hr of runtime",transform=ax.transAxes, fontsize=12, color="red")
    
    plt.title(label)
    plt.savefig("%s.pdf"%label)
    plt.close()

# label="2412_b11p90_m0p0667"
# # print(fparsedir+label+"_cont*.tmp")

# fig,ax=plt.subplots(figsize=(20,7))
# for f in sorted(glob.glob(fparsedir+label+"_cont[2-9]??[0-9]_*.tmp")):
#     if os.path.getsize(f) == 0:
#         continue
#     print(f)
    
#     dat=np.genfromtxt(f,usecols=(0,6))
#     # figname=f.replace("../monitor","./runtime").replace(".txt",".pdf")

#     x=range(len(dat))
#     ax.plot(x, dat[:,1], color='r', linewidth=1.5)

# plt.ylabel("runtime [s]")
# plt.xlabel("traj")

# plt.title(label)
# plt.savefig("%s.pdf"%label)
# plt.close()