/* 
Copyright (c) 2014, Mario Badr
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
/*
 * main.cpp
 *
 *  Created on: Jan 7, 2013
 *      Author: mario
 */

#include <iostream>
#include <fstream>
#include <stdio.h>

#include "Global.h"
#include "ModelRead.h"
#include "TrafficGenerator.h"

using namespace std;

int main(int argc, char **argv) {
	if(argc != 5) {
		cerr << "Need 4 parameters: model file, number of cycles, exit at "
				"steady state, number of packets" << endl;
		return -1;
	}

	ifstream modelFile(argv[1]);
	if(!modelFile.good()) {
		cerr << "Could not open file " << argv[1] << endl;
		return -1;
	}

	//Parses the file and stores all information in global variables
	ReadModel(modelFile);

	//Close the file stream
	modelFile.close();

	//The number of cycles to simulate for
	unsigned int numCycles = (int) strtoul(argv[2], NULL, 0);

	//Whether or not we should exit the simulation prematurely when steady
	//state is reached
	bool ssExit = ((int) strtoul(argv[3], NULL, 0)) == 1;

	//The number of packets to be injected
	unsigned int numPackets = (int) strtoul(argv[4], NULL, 0);
	
    //Run the traffic generator
	Run(numCycles, ssExit, numPackets);

	return 0;
}
