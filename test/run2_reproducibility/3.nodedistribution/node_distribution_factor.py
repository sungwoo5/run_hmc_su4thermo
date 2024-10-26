#!/usr/bin/env python3

import numpy as np
import subprocess



# x1005c2s6b0n0 to [1005, 2] and ignore the rest
def labeltoxc(label):
    tmpstr=label.replace("x","").replace("c",",").replace("s",",").replace("b",",").replace("n",",")
    xc=np.fromstring(tmpstr, sep=",",dtype=int)[0:2]
    # print(xc)
    return xc

    
#                   x, c, s, b
# x1005c2s6b0n0 (1005, 2, 6, 0)
# x1005c2s6b1n0 (1005, 2, 6, 1)
# x1005c2s7b0n0 (1005, 2, 7, 0)
# x1005c2s7b1n0 (1005, 2, 7, 1)
# x1005c3s0b0n0 (1005, 3, 0, 1)
# x1005c3s0b1n0
# x1005c3s1b0n0
# x1005c3s1b1n0

# on a single cabinet (ex, c2), 8 blades (s0~s7)
# for 8 nodes,
# the most local distribution is a single cabinet (4 blades *2 nodes) -> 4 different blade used
# but above, 2 different cabinet used, factor 1
# if different rack used, factor 
def distribution_factor(arr):
    
    arr2=[]
    for i in arr:

        # Run a command using the shell
        cmd="xhost-query.py tuolumne%d"%(i)
        # print(cmd)
        run=subprocess.run(cmd, capture_output=True, text=True,shell=True)
        nodelabel=run.stdout.rstrip() # rstrip removes trailing zero
        # print(nodelabel)
        arr2+=[labeltoxc(nodelabel)]
    arr2=np.array(arr2)

    n_racks=len(np.unique(arr2[:,0]))
    n_cabin=len(np.unique(arr2[:,1]))
    factor=(n_cabin-1)+(n_racks-1)*8    # 1 rack can have 8 cabinets
    return factor



def twoarray(input_str):
    # input_str="[1685,1686,1687,1688,1689,1690,1691,1692,],[1693,1694,1695,1696,1697,1698,1699,1700,]"

    # Remove unwanted characters like brackets and spaces
    cleaned_str = input_str.replace(",],[", "|").replace("[", "").replace(",]", "")
    # print(cleaned_str)

    # Split the string into two parts
    array_strs = cleaned_str.split("|")

    # Convert each part to a NumPy array
    array1 = np.fromstring(array_strs[0], sep=",",dtype=int)
    array2 = np.fromstring(array_strs[1], sep=",",dtype=int)

    # Print the result
    # print(array1)
    # print(array2)
    return array1, array2



import argparse

def main(input_string):
    # Perform actions with the input string
    # print(f"Input string is: {input_string}")

    arr1,arr2=twoarray(input_string)
    # arr2: for the orig job
    # arr1: for the run2 job
    print("%d %d"%(distribution_factor(arr2),distribution_factor(arr1)))
    

if __name__ == "__main__":
    # Create the argument parser
    parser = argparse.ArgumentParser(description="A script that takes a string as input.")

    # Add an argument for the input string
    parser.add_argument('input_string', type=str, help="The input string to process")

    # Parse the command-line arguments
    args = parser.parse_args()

    # Call the main function with the parsed input string
    main(args.input_string)
