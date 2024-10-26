#!/usr/bin/env python3
import numpy as np
import argparse, sys, os

def format_ranges(numbers):
    sorted_numbers = sorted(numbers)
    ranges = []
    start = sorted_numbers[0]
    end = sorted_numbers[0]
    
    for num in sorted_numbers[1:]:
        if num == end + 1:  # Consecutive number
            end = num
        else:  # End of a consecutive sequence
            if start == end:
                ranges.append(str(start))  # Single number
            else:
                ranges.append(f"{start}-{end}")  # Range of numbers
            start = end = num  # Start a new range

    # Handle the last range or single number
    if start == end:
        ranges.append(str(start))
    else:
        ranges.append(f"{start}-{end}")
    
    return ",".join(ranges)


def main():
    # Create the argument parser
    parser = argparse.ArgumentParser(description="Process a nodelist file.")
    
    # Add a positional argument for the filename
    parser.add_argument('filename', type=str, help='The name of the nodelist file to process')

    # Parse the arguments
    args = parser.parse_args()

    # Access the filename
    filename = args.filename
    # print(f"The provided filename is: {filename}")

    if not os.path.isfile(filename):
        sys.exit("no nodelist file %s exists"%filename)
    
    dat=sorted(set(np.genfromtxt(filename,dtype=int).flatten()))
    result = format_ranges(dat)
    print(result)


    
if __name__ == "__main__":
    main()


