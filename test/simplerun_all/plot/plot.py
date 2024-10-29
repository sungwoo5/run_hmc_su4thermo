#!/usr/bin/env python3

import gvar as gv
import numpy as np
import glob, lsqfit
from scipy import optimize
import sys, os
import matplotlib
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
from matplotlib.colors import ListedColormap, BoundaryNorm

for f in glob.glob("../monitor/*.txt"):
    if os.path.getsize(f) == 0:
        continue
    
    dat=np.genfromtxt(f,usecols=(0,6))
    figname=f.replace("../monitor","./runtime").replace(".txt",".pdf")
    fig,ax=plt.subplots()

    ax.plot( dat[:,0], dat[:,1], color='r', linewidth=1.5)

    plt.ylabel("runtime [s]")
    plt.xlabel("traj")

    plt.title(figname)
    plt.savefig(figname)
    plt.close()
