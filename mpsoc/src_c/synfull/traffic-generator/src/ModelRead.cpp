/* 
Copyright (c) 2014, Mario Badr
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
/*
 * ModelRead.cpp
 *
 *  Created on: 2013-01-13
 *      Author: mario
 */

#include <string>
#include <iostream>
#include <sstream>


#include "ModelRead.h"
#include "Global.h"

using namespace std;

/**
 * Returns true if the next line equals 'header'.
 *
 * @param file The file to peak in
 * @param header The string to find in the next line
 *
 */
bool PeekForHeader(ifstream& file, string header) {
	// Get current position
	int len = file.tellg();

	// Read line
	std::string line;
	getline(file, line); //Finish reading the last line
	getline(file, line);

	// Return to position before "Read line".
	file.seekg(len ,std::ios_base::beg);

	return(line.compare(header) == 0);
}

/**
 * Parse the hierarchical parameters of the model
 *
 * @param modelFile The model file stream
 */
void ReadHierarchy(ifstream& modelFile) {
	string header;

	modelFile >> header;
	modelFile >> g_hierClasses;
	modelFile >> header;
	modelFile >> g_timeSpan;

	//Hierarchical Markov Model
	double transition;

	modelFile >> header;
	for(int i = 1; i <= g_hierClasses; i++) {
		for(int j = 0; j < g_hierClasses; j++) {
			modelFile >> transition;
			g_hierState[i].Add(transition);
		}
	}
	modelFile >> header;

	//Read steady state
	modelFile >> header;
	for(int i = 0; i < g_hierClasses; i++) {
		modelFile >> transition;
		g_hierSState.push_back(transition);
	}
	modelFile >> header;
}

/**
 * Read the parameters of the model
 *
 * @param modelFile The model file stream
 *
 */
void ReadParameters(ifstream& modelFile) {
	string header;

	modelFile >> header;
	modelFile >> g_memory;

	modelFile >> header;
	modelFile >> g_numNodes;

	modelFile >> header;
	modelFile >> g_numClasses;

	modelFile >> header;
	modelFile >> g_resolution;
}

/**
 * Read in the Markov probability matrix
 *
 * @param modelFile The model file stream
 */
void ReadMarkov1(ifstream& modelFile) {
	string header;
	double transition;

	modelFile >> header;
	for(int i = 1; i <= g_numClasses; i++) {
		for(int j = 0; j < g_numClasses; j++) {
			modelFile >> transition;
			g_states1[g_hierClass][i].Add(transition);
		}
	}
	modelFile >> header;

	//Read steady state
	modelFile >> header;
	for(int i = 0; i < g_numClasses; i++) {
		modelFile >> transition;
		g_steadyState[g_hierClass].push_back(transition);
	}
	modelFile >> header;
}

/**
 * Read in the spatial injection probabilities for each message type.
 *
 * @param modelFile The model file stream
 */
void ReadSpatial(ifstream& modelFile) {
	string header;
	int value;

	modelFile >> header;
	while(!PeekForHeader(modelFile, "END")) {
		for(int cl  = 1; cl <= g_numClasses; cl++) {
			modelFile >> value;

			g_writeSpat[g_hierClass][cl].Add(value);
		}
	}
	modelFile >> header;

	modelFile >> header;
	while(!PeekForHeader(modelFile, "END")) {
		for(int cl  = 1; cl <= g_numClasses; cl++) {
			modelFile >> value;

			g_readSpat[g_hierClass][cl].Add(value);
		}
	}
	modelFile >> header;

	modelFile >> header;
	while(!PeekForHeader(modelFile, "END")) {
		for(int cl  = 1; cl <= g_numClasses; cl++) {
			modelFile >> value;

			g_ccrSpat[g_hierClass][cl].Add(value);
		}
	}
	modelFile >> header;

	modelFile >> header;
	while(!PeekForHeader(modelFile, "END")) {
		for(int cl  = 1; cl <= g_numClasses; cl++) {
			modelFile >> value;

			g_dcrSpat[g_hierClass][cl].Add(value);
		}
	}
	modelFile >> header;
}

/**
 * Read in the flows probabilities to determine destinations for each message
 * type.
 *
 * @param modelFile The model file stream
 */
void ReadFlows2(ifstream& modelFile) {
	string header;
	int value, s, d, cl;

	modelFile >> header;
	while(!PeekForHeader(modelFile, "END")) {
		modelFile >> s >> d >> cl >> value;

		g_writeDest[g_hierClass][cl][s].Add(value);
	}
	modelFile >> header;

	modelFile >> header;
	while(!PeekForHeader(modelFile, "END")) {
		modelFile >> s >> d >> cl >> value;

		g_readDest[g_hierClass][cl][s].Add(value);
	}
	modelFile >> header;

	modelFile >> header;
	while(!PeekForHeader(modelFile, "END")) {
		modelFile >> s >> d >> cl >> value;

		g_ccrDest[g_hierClass][cl][s].Add(value);
	}
	modelFile >> header;

	modelFile >> header;

	while(!PeekForHeader(modelFile, "END")) {
		modelFile >> s >> d >> cl >> value;

		g_dcrDest[g_hierClass][cl][s].Add(value);
	}
	modelFile >> header;

}

/**
 * Read the injection rates for each message type.
 *
 * @param modelFile The model file stream
 */
void ReadInjections2(ifstream& modelFile) {
	int value;
	string header;

	modelFile >> header;

	while(!PeekForHeader(modelFile, "END")) {
		for(int cl  = 1; cl <= g_numClasses; cl++) {
			modelFile >> value;

			g_writes[g_hierClass][cl].Add(value);
		}
	}
	modelFile >> header;


	modelFile >> header;

	while(!PeekForHeader(modelFile, "END")) {
		for(int cl  = 1; cl <= g_numClasses; cl++) {
			modelFile >> value;

			g_reads[g_hierClass][cl].Add(value);
		}
	}
	modelFile >> header;


	modelFile >> header;

	while(!PeekForHeader(modelFile, "END")) {
		for(int cl  = 1; cl <= g_numClasses; cl++) {
			modelFile >> value;

			g_ccrs[g_hierClass][cl].Add(value);
		}
	}
	modelFile >> header;


	modelFile >> header;

	while(!PeekForHeader(modelFile, "END")) {
		for(int cl  = 1; cl <= g_numClasses; cl++) {
			modelFile >> value;

			g_dcrs[g_hierClass][cl].Add(value);
		}
	}
	modelFile >> header;

}

/**
 * Read the forwarding probabilities for node directories.
 *
 * @param modelFile The model file stream
 */
void ReadForwards(ifstream& modelFile) {
	int index;
	double value1, value2;
	string header;

	modelFile >> header;
	while(!PeekForHeader(modelFile, "END")) {
		modelFile >> index >> value1 >> value2;
		g_toForward[g_hierClass][index][WRITE].Add(value1);
		g_toForward[g_hierClass][index][WRITE].Add(1 - value1);
		g_toForward[g_hierClass][index][READ].Add(value2);
		g_toForward[g_hierClass][index][READ].Add(1 - value2);
	}
	modelFile >> header;

	int cl, source, destination, value;
	//map<int, map<int, map<int, int> > > iteration;
	modelFile >> header;
	while(!PeekForHeader(modelFile, "END")) {
		modelFile >> source >> destination >> cl >> value;

		g_forwardDest[g_hierClass][cl][source].Add(value);
	}
	modelFile >> header;

}

/**
 * Read in the probabilities for number of invalidates and their respective
 * destinations for each source node.
 *
 * @param modelFile The model file stream
 */
void ReadInvalidates(ifstream& modelFile) {
	string header;
	int cl, source, number, freq;

	modelFile >> header;
	while(!PeekForHeader(modelFile, "END")) {
		for(int i = 0; i < g_numNodes/2; i++) {
			modelFile >> cl >> source >> number >> freq;

			if(i != number) {
				cerr << "Invalid model file. Reading invalidate probabilities."
						<< endl;
				return;
			}

			g_numInv[g_hierClass][cl][source].Add(freq);
		}
	}
	modelFile >> header;

	int destination, value;
	map<int, map<int, map<int, int> > > iteration;
	modelFile >> header;
	while(!PeekForHeader(modelFile, "END")) {
		modelFile >> source >> destination >> cl >> value;

		g_invDest[g_hierClass][cl][source].Add(value);
	}
	modelFile >> header;
}

/**
 * Parse the modelFile given and store all information in the global variables.
 *
 * @param modelFile The model file stream
 */
void ReadModel(ifstream& modelFile) {
	cout << "Reading model\n";
	ReadHierarchy(modelFile);
	string header;

	for(int i = 0; i < g_hierClasses; i++) {
		modelFile >> header;
		modelFile >> g_hierClass;
		ReadParameters(modelFile);

		//Active Model
		ReadMarkov1(modelFile);
		cout << ".\n";
		ReadSpatial(modelFile);
		cout << ".\n";

		ReadFlows2(modelFile);
		cout << ".\n";

		ReadInjections2(modelFile);
		cout << ".\n";

		//Reactive Model
		ReadForwards(modelFile);
		cout << ".\n";
		ReadInvalidates(modelFile);
		cout << ".\n";

		modelFile >> header;
		cout << "*\n";
	}
	g_hierClass = 1;

	cout << " Done!" << endl;
}


