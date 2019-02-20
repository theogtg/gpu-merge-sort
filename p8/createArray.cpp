/********************************************************************
 * Tyler Griffith                                                   *
 * December 6th, 2018                                               *
 * Project 8 helper function                                        *
 * CSC-4310-01 PROF: R. Shore                                       *
 * Desc: creates an array of random ints of specified length        *
 * To Compile: g++ createArray.cpp -o makeArray                     *
 * To Run: ./makeArray <size>                                       *
 ********************************************************************/
#include <iostream>
#include <fstream>
#include <stdlib.h>

using namespace std;

int main(int argc, char *argv[]){
   //initialize size
   int size = atoi(argv[1]);

   ofstream outFile;
   outFile.open("array");
   outFile << size << endl;
   for(int i=0; i<size; i++)
      outFile << rand() % 1000 << " ";
   outFile.close();

   return 0;
}
