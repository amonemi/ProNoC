/* 
Copyright (c) 2014, Mario Badr
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
/*
 * Global.cpp
 *
 *  Created on: 2013-01-13
 *      Author: mario
 */

#include "Global.h"

using namespace std;

//General model information
int g_memory;
int g_numNodes;
int g_numClasses;
int g_resolution;
int g_hierClasses;
int g_hierClass;
int g_timeSpan;

//First order markov chain states
map<int, DiscreteDistribution<double> > g_hierState;
//Steady State Markov
vector<double> g_hierSState;

//First order markov chain states
map<int, map<int, DiscreteDistribution<double> > > g_states1;
//Steady State Markov
map<int, vector<double> > g_steadyState;

//Spatial Injection Probabilities
map<int, map<int, DiscreteDistribution<int> > > g_writeSpat;
map<int, map<int, DiscreteDistribution<int> > > g_readSpat;
map<int, map<int, DiscreteDistribution<int> > > g_ccrSpat;
map<int, map<int, DiscreteDistribution<int> > > g_dcrSpat;

//Destination Probabilities given a source
map<int, map<int, map<int, DiscreteDistribution<int> > > > g_writeDest;
map<int, map<int, map<int, DiscreteDistribution<int> > > > g_readDest;
map<int, map<int, map<int, DiscreteDistribution<int> > > > g_ccrDest;
map<int, map<int, map<int, DiscreteDistribution<int> > > > g_dcrDest;

//Volume Injection Probabilities<class, probability>
map<int, map<int, DiscreteDistribution<int> > > g_writes;
map<int, map<int, DiscreteDistribution<int> > > g_reads;
map<int, map<int, DiscreteDistribution<int> > > g_ccrs;
map<int, map<int, DiscreteDistribution<int> > > g_dcrs;

//Forward Probabilities
map<int, map<int, map<int, DiscreteDistribution<double> > > > g_toForward;
//map<int, map<int, map<int, DiscreteDistribution<int> > > > g_forwardFlows;
map<int, map<int, map<int, DiscreteDistribution<int> > > > g_forwardDest;

//Invalidate Probabilities
map<int, map<int, map<int, DiscreteDistribution<int> > > > g_numInv;
//map<int, map<int, map<int, DiscreteDistribution<int> > > > g_invFlows;
map<int, map<int, map<int, DiscreteDistribution<int> > > > g_invDest;
