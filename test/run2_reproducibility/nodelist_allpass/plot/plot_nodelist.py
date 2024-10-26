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

list_nodes=range(1001,2152+1)

dat=sorted(np.genfromtxt("../nodelist_allpass.txt",dtype=int).flatten())
# print(dat)
# exit(1)
# count the number of runs for each nodes
count_dict={}
for i in list_nodes:
    count_dict[i]=0
for i in dat:
    count_dict[i]=count_dict[i]+1
#print(.shape[0]/128)
count=np.array(list(count_dict.values()))
print(len(np.array(list(count_dict.keys())))/32)

print(np.reshape(np.array(list(count_dict.keys())),(32,int(1152/32))))
# exit(1)

count=np.reshape(count,(36,int(1152/36)))
fig,ax=plt.subplots()
# ax.xaxis.set_major_locator(ticker.MaxNLocator(integer=True))
# cmap = plt.colormaps['PiYG']
# im=ax.imshow(Cabs,cmap='binary',vmin=0)
# im=ax.pcolormesh(x, y, C)


cmap_name = 'viridis_r'
max_levels=8
cmap = plt.get_cmap(cmap_name, max_levels)  # Create a discrete colormap with 5 levels

# Convert the colormap to a ListedColormap
new_cmap = cmap(np.arange(max_levels))  # Extract the original colors

# Modify the first color (representing zero) to black
#new_cmap[0] = np.array([0, 0, 0, 1])  # Set the first color (zero) to black (RGBA format)
new_cmap[0] = np.array([0,0,0,0])  # Set the first color (zero) to white (RGBA format)

# Create a new colormap with the modified colors
modified_cmap = ListedColormap(new_cmap)



# Define the boundaries for the colormap
# if not used, colorbar becomes weird for discrete value case
bounds = np.arange(max_levels+1) 
norm = BoundaryNorm(bounds, cmap.N)



im=ax.imshow(count, cmap=modified_cmap, norm=norm)

# put values in text
# for (j,i),label in np.ndenumerate(C_gv):
#     if i==j:
#         continue
#     ax.text(i,j,"%s"%gv.fmt(label,ndecimal=3),c="red",ha='center',va='center',fontsize=3)
    
# plt.tick_params(left = False, right = False , labelleft = False ,
#                 labelbottom = False, bottom = False)
ax.set_yticks(np.arange(0,36,4),labels=["tuolumne%d\n(x100%d)"%(1001+i*128,i) for i in np.arange(0,9)],fontsize=8)
ax.set_xticks(np.arange(0,32,8))

# x_limits = ax.get_xlim()
# y_limits = ax.get_ylim()
# x=np.arange(x_limits[0],x_limits[1]+1)
# y=np.arange(y_limits[0],y_limits[1]+1)

# draw the grid for each 
# for i_rack in range(36):
#     ax.axhline(y=i_rack-0.5, color='k', linestyle='-', linewidth=1)
ax.axvline(x=16-0.5, color='r', linestyle='--',linewidth=1)
for i_rack in range(1,9):
    # ax.plot( x, (i_rack*4-0.5)*np.ones(len(x)), color='r', linewidth=1.5)
    ax.axhline(y=i_rack*4-0.5, color='r', linestyle='-',linewidth=1)


# https://matplotlib.org/stable/gallery/images_contours_and_fields/image_annotated_heatmap.html#using-the-helper-function-code-style
ax.spines[:].set_visible(False)

ax.set_xticks(np.arange(count.shape[1]+1)-.5, minor=True)
ax.set_yticks(np.arange(count.shape[0]+1)-.5, minor=True)
ax.grid(which="minor", color="#696969", linestyle='-', linewidth=1)
ax.tick_params(which="minor", bottom=False, left=False)


plt.ylabel("hostname (racks)")
plt.xlabel("nodes")

#plt.colorbar(im, ticks=np.arange(max_levels))

# Create the colorbar
cbar = plt.colorbar(im)
cbarticks = np.arange(max_levels)
cbar.set_ticks(cbarticks+0.5)
cbar.set_ticklabels(cbarticks)
cbar.set_label('usage count')


plt.title("Node usage count in reproducibility test (10/07,10/23-24) on Tuolumne\n (Grid SU(4) MDWF HMC $32^3x8$, (-N 8 -n 32)x2 jobs)", fontsize=10)
ax.text(-0.42, -0.1, 'ALL SUCCESS\nNO FAILURE FOUND', color='red', fontsize=14, ha='left', transform=ax.transAxes)
plt.savefig("nodeusage_reprodtest1007_23_24.pdf")
plt.clf()
