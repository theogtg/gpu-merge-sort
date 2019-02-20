
#INSTRUCTIONS

###Steps to create a sample array
**To compile:**
   `gcc createArray.cpp -o makeArray`
**To run:**
   `./makeArray <size of array>`
**What does it do?**
   - This is a simple program that will create a sample array file called `array`
   - The `array` file's contents consist of the first number being the size of the array, then the array, with each number separated by a space
   - The array is of data type `int` and the size is specified by the user
   - The random `int`'s will range anywhere from 0-1000

###Steps to run the merge sort
**To compile:**
   `nvcc sort.cu -o sort`
**To run:**
   `./sort <array file>`
**What does it do?**
   - reads in the given array through argv
   - Sorts the given array on both the CPU and GPU and outputs the timings to standard output
   - Outputs the fully sorted array by the GPU to the file `gpuSortedArray`

###Findings
   - Initially I wanted to do multiple sorting algorithms but you were absolutely right in saying that there wasn't enough time as the merge sort took most of my time
   - The gpu merge sort was no where close to the cpu merge sort in terms of sort time until the array was >= 1 million integers due to the time it takes to copy the data to the GPU and to allocate the GPU memory
   - When running the timing without including copying and allocationg to gpu memory the speed up is incredibly fast, almost unbelievably faster
