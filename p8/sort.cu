/****************************************************************************************************
* Tyler Griffith                                                                                    *
* December 1st, 2018                                                                                *
* Project 8: Sorting Algorithms on GPU                                                              *
* CSC-4310-01 PROF: R. Shore                                                                        *
* Desc: Use the GPU to merge sort arrays and compare CPU and GPU timings                            *
* To Compile:                                                                                       *
*         nvcc sort.cu -o sort                                                                      *
* To Run:                                                                                           *
*         ./sort <array file>                                                                       *
*****************************************************************************************************/
#include <iostream>
#include <cstdio>
#include <fstream> //for I/O
#include <time.h> //for timing

using namespace std;

//function declarations
int* readArray(char* fileName);
int getSize(char* fileName);
double cuda_merge_sort(int* array, int length, dim3 dimThread, dim3 dimBlock);
void merge(int* array, int left, int mid, int right);
void mergeSort(int* array, int left, int right);
//gpu function declarations
__device__ void cudaMerge(int* a, int* b, int beg, int mid, int end);
__global__ void cudaMergeSort(int* a, int* b, int width, int length, int pieces, dim3* thread, dim3* block);
__device__ unsigned int getThreadIdx(dim3* thread, dim3* block);

//global find min function
#define min(a, b) (a < b ? a : b)

//driver
int main(int argc, char* argv[]){
   //variable declaration
   int size;
   dim3 dimThread, dimBlock; //threads per block and blocks per grid;

   //set initial values for testing
   dimThread.x = 32;
   dimThread.y = 1;
   dimThread.z = 1;
   dimBlock.x = 8;
   dimBlock.y = 1;
   dimBlock.z = 1;

   //make sure correct syntax is used
   if(argc != 2){
      cout << "Error! You do not have an element to your command!" << endl;
      cout << "To sort an array please use the following syntax:" << endl;
      cout << "./sort <array file>" << endl;
      return -1;
   }

   //read in size of the array
   size = getSize(argv[1]);
   int* gpuArray = new int[size];
   //read in array
   gpuArray = readArray(argv[1]);

	//created different array so both could be sorted
	int* cpuArray = new int[size];
	cpuArray = gpuArray;

	//GPU timing
	double gpuDuration = cuda_merge_sort(gpuArray, size, dimThread, dimBlock);

	//output sorted GPU array to separate file
	ofstream gpuSortedArray("gpuSortedArray");
	for(int i=0; i<size; i++){
		gpuSortedArray << gpuArray[i] << " ";
	}
	gpuSortedArray.close();

	//CPU timing
	clock_t cpuStart = clock();

	//call cpu merge sort function
	mergeSort(cpuArray, 0, size-1);

	//CPU timing
	clock_t cpuEnd = clock();
	double cpuDuration = (double)(cpuEnd-cpuStart)/CLOCKS_PER_SEC;

	//print timing
	cout << "gpu sort completed in " << gpuDuration*1000 << " milliseconds!" << endl;
	cout << "cpu sort completed in " << cpuDuration*1000 << " milliseconds!" << endl;

   return 0;
}

/****************************************************
 * Function: getSize - fetch and return the size    *
 *                     of the array from I/O        *
 * precondition: filename is fetched from argv[1]   *
 *               in the main                        *
 * postcondition: the size of the array is          *
 *                returned to main                  *
 ****************************************************/
int getSize(char* fileName){
	//variable delcaration
   int size;
	//initialize and open file
   ifstream inFile(fileName);
   if(inFile.is_open()){
	   //read in size
      inFile >> size;
   }
  //close file
  inFile.close();
  return size;
}

/****************************************************
 * Function: readArray - fetch and return the array *
 *                       from I/O                   *
 * precondition: filename is fetched from argv[1]   *
 *               in the main                        *
 * postcondition: the array is returned to main     *
 ****************************************************/
int* readArray(char* fileName){
   //variable declaration
   int size;
   ifstream inFile(fileName);

   //read in array size
   inFile >> size;

   //allocate memory
   int *array = new int[size];
   
   //read in array
   for(int i=0; i<size; i++)
      inFile >> array[i];

   //close file and return array
   inFile.close();
   return array;
}

/****************************************************
 * Function: mergeSort - merge sort the given array *
 *                       on the CPU                 *
 * precondition: - array is established in the main *
 *                 through readArray()              *
 *               - right is established through     *
 *                 getsize()                        *
 * postcondition: the array is sorted               *
 ****************************************************/
void mergeSort(int* array, int left, int right){
	//left is left index right is right index
	if(left < right){
		//same as (left+right)/2, but avoids overflow for large nums
		int mid = left+(right-left)/2;

		//sort first and seconds halves
		mergeSort(array, left, mid);
		mergeSort(array, mid+1, right);
		//merge the pieces together
		merge(array, left, mid, right);
	}
}

/****************************************************
 * Function: merge - merges two subarrays           *
 * precondition: - array is established in the main *
 *                 through readArray()              *
 *               - right is established through     *
 *                 getsize()                        *
 *               - mid is established in mergeSort()*
 * postcondition: the two subarrays are merged      *
 ****************************************************/
void merge(int* array, int left, int mid, int right){
	//variable declaration
	int i,j,k;
	int n1 = mid-left+1;
	int n2 = right-mid;

	//temp arrays
	int L[n1], R[n2];

	//copy data to temp arrays
	for(i=0; i<n1; i++)
		L[i] = array[left+i];
	for(j=0; j<n2; j++)
		R[j] = array[mid+1+j];

	//merge temp arrays back
	i=0;//index for first array
	j=0;//index for second array
	k=left;//index for merged array

	while(i<n1 && j<n2){
		if(L[i]<=R[j]){
			array[k] = L[i];
			i++;
		}
		else{
			array[k] = R[j];
			j++;
		}
		k++;
	}

	//copy remaining elements of L
	while(i<n1){
		array[k] = L[i];
		i++;
		k++;
	}

	//copy remaining elements of R
	while(j<n2){
		array[k] = R[j];
		j++;
		k++;
	}
}

/***********************************************************
 * Function: cuda_merge_sort - allocates memory on GPU for *
 *                             array then copies the array *
 *                             to the GPU and calls the    *
 *                             GPU merge sort function     *
 * precondition: - array is established in the main        *
 *                 through readArray()                     *
 *               - length is established in the main       *
 *                 through getSize()                       *
 *               - dimThread and dimBlock are established  *
 *                 in the main                             *
 * postcondition: the array is sorted on the GPU and the   *
 *                time taken to sort the array on the      *
 *                GPU is returned back to main             *
 ***********************************************************/
double cuda_merge_sort(int* array, int length, dim3 dimThread, dim3 dimBlock){
	//variable declaration
   int* dArray;
   int* dSwap;
   dim3* dThread;
   dim3* dBlock;

   //allocate memory for array on gpu
   cudaMalloc((void**)&dArray, length*sizeof(int));
   cudaMalloc((void**)&dSwap, length*sizeof(int));

   //copy array to gpu
   cudaMemcpy(dArray, array, length*sizeof(int), cudaMemcpyHostToDevice);

   //allocate memory for the thread and block info on gpu
   cudaMalloc((void**)&dThread, sizeof(dim3));
   cudaMalloc((void**)&dBlock, sizeof(dim3));

   //copy thread and block info to gpu
   cudaMemcpy(dThread, &dimThread, sizeof(dim3), cudaMemcpyHostToDevice);
   cudaMemcpy(dBlock, &dimBlock, sizeof(dim3), cudaMemcpyHostToDevice);

   //for copying
   int* x = dArray;
   int* y = dSwap;
   
   //get thread count
   int threadCount = dimThread.x * dimThread.y * dimThread.z * dimBlock.x * dimBlock.y * dimBlock.z;

   //timing
	clock_t start = clock();

   //cut the array into different pieces and give those pieces to each thread
   for(int width = 2; width < (length << 1); width <<= 1){
	   //variable delcaration
      int pieces = length / ((threadCount) * width) + 1;

      //call the sort
      cudaMergeSort<<<dimBlock, dimThread>>>(x, y, width, length, pieces, dThread, dBlock);

      //can swap the input/output arrays instead of copying
      x = x == dArray ? dSwap : dArray;
      y = y == dArray ? dSwap : dArray;
      
   }

	//timing
	clock_t end = clock();
	double duration = (double)(end-start)/CLOCKS_PER_SEC;

   //retrieve array from the GPU
   cudaMemcpy(array, dArray, length*sizeof(int), cudaMemcpyDeviceToHost);

   //free memory
   cudaFree(dArray);
   cudaFree(dSwap);

	return duration;
}

/*************************************************************
 * Global Function: cudaMergeSort - merge sorts the given    *
 *                                  array on the GPU         *
 * precondition: - a is established in cuda_merge_sort()     *
 *               - b is established in cuda_merge_sort()     *
 *               - width is established in cuda_merge_sort() *
 *               - length is established in getSize()        *
 *               - pieces is established in cuda_merge_sort()*
 *               - thread and block are both established     *
 *                 within the main                           *
 * postcondition: the array is sorted on the GPU             *
 *************************************************************/
__global__ void cudaMergeSort(int* a, int* b, int width, int length, int pieces, dim3* thread, dim3* block){
   //set the thread index
   unsigned int idx = getThreadIdx(thread, block);
   //initialize positioning
   int beg = width * idx * pieces;
   int mid, end;

	//for each of the pieces
   for(int piece=0; piece<pieces; piece++){
      if (beg >= length)
         break;
		//initialize the middle of the array
      mid = min(beg+(width>>1), length);
	   //initialize the end of the array
      end = min(beg+width, length);
	   //merge
      cudaMerge(a, b, beg, mid, end);
	   //update the beginning of the array
      beg += width;
   }
}

/*************************************************************
 * Device Function: cudaMerge - merges two subarrays         *
 * precondition: - a is established in cuda_merge_sort()     *
 *               - b is established in cuda_merge_sort()     *
 *               - beg, mid and end are established within   *
 *                 the cudaMergeSort global function         *
 * postcondition: the two subarrays are merged together      *
 *************************************************************/
__device__ void cudaMerge(int* a, int* b, int beg, int mid, int end){
	//initialize positioning
   int i = beg;
   int j = mid;

	//loop through the chunk
   for(int k=beg; k<end; k++){
	   //swap
      if(i < mid && (j>=end || a[i]<a[j])){
         b[k] = a[i];
         i++;
      } else {
         b[k] = a[j];
         j++;
      }
   }
}

/*************************************************************
 * Device Function: getThreadIdx - fetches the current       *
 *                                 thread index              *
 * precondition: - thread and block are established within   *
 *                 the main                                  *
 * postcondition: the current thread index is returned       *
 *************************************************************/
__device__ unsigned int getThreadIdx(dim3* thread, dim3* block) {
   int x;
   //calculates and returns the index of the current thread
   return threadIdx.x +
          threadIdx.y * (x  = thread->x) +
          threadIdx.z * (x *= thread->y) +
          blockIdx.x  * (x *= thread->z) +
          blockIdx.y  * (x *= block->z) +
          blockIdx.z  * (x *= block->y);
}