#!/usr/bin/env python3


import numpy as np

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


dat=sorted(set(np.genfromtxt("../fullnodelist_used.txt",dtype=int).flatten()))


# Example usage
#numbers = {1049, 1050, 1051, 1060, 1061, 1062, 1075}
result = format_ranges(dat)
print(result)
