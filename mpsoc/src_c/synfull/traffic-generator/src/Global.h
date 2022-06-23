/* 
Copyright (c) 2014, Mario Badr
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
/*
 * Global.h
 *
 *  Created on: 2013-01-13
 *      Author: mario
 */

#ifndef GLOBAL_H_
#define GLOBAL_H_

#include <map>
#include <vector>
#include <random>

#include "MyRand.h"

const static int REQUEST    = 1 ;
const static int WRITE      = 0 ;
const static int READ       = 1 ;
const static int PUTC       = 2 ; // Evict - CHI
const static int PUTD       = 3 ; // WriteBackFull - CHI
const static int INV        = 4 ;
                                    
const static int RESPONSE   = 2 ;
const static int ACK        = 0 ;
const static int WB_ACK     = 1 ; // CopyBackWriteData - CHI
const static int DATA       = 2 ;
const static int UNBLOCK    = 5 ;

const static int CONTROL_SIZE   = 8 ;
const static int DATA_SIZE      = 72;



//General model information
extern int g_memory;
extern int g_numNodes;
extern int g_numClasses;
extern int g_resolution;
extern int g_hierClasses;
extern int g_hierClass;
extern int g_timeSpan;

//Hierarchical markov chain
extern std::map<int, DiscreteDistribution<double> > g_hierState;
//Hierarchical SS Markov
extern std::vector<double> g_hierSState;

//First order markov chain states
extern std::map<int, std::map<int, DiscreteDistribution<double> > > g_states1;
//Steady State Markov
extern std::map<int, std::vector<double> > g_steadyState;

extern std::map<int, std::map<int, DiscreteDistribution<int> > > g_writeSpat;
extern std::map<int, std::map<int, DiscreteDistribution<int> > > g_readSpat;
extern std::map<int, std::map<int, DiscreteDistribution<int> > > g_ccrSpat;
extern std::map<int, std::map<int, DiscreteDistribution<int> > > g_dcrSpat;

extern std::map<int, std::map<int, std::map<int, DiscreteDistribution<int> > > > g_writeDest;
extern std::map<int, std::map<int, std::map<int, DiscreteDistribution<int> > > > g_readDest;
extern std::map<int, std::map<int, std::map<int, DiscreteDistribution<int> > > > g_ccrDest;
extern std::map<int, std::map<int, std::map<int, DiscreteDistribution<int> > > > g_dcrDest;

//Injection Probabilities<class, probability>
extern std::map<int, std::map<int, DiscreteDistribution<int> > > g_writes;
extern std::map<int, std::map<int, DiscreteDistribution<int> > > g_reads;
extern std::map<int, std::map<int, DiscreteDistribution<int> > > g_ccrs;
extern std::map<int, std::map<int, DiscreteDistribution<int> > > g_dcrs;

//Forward Probabilities
extern std::map<int, std::map<int, std::map<int, DiscreteDistribution<double> > > > g_toForward;
//extern std::map<int, std::map<int, std::map<int, DiscreteDistribution<int> > > > g_forwardFlows;
extern std::map<int, std::map<int, std::map<int, DiscreteDistribution<int> > > > g_forwardDest;

//Invalidate Probabilities
extern std::map<int, std::map<int, std::map<int, DiscreteDistribution<int> > > > g_numInv;
//extern std::map<int, std::map<int, std::map<int, DiscreteDistribution<int> > > > g_invFlows;
extern std::map<int, std::map<int, std::map<int, DiscreteDistribution<int> > > > g_invDest;

#endif /* GLOBAL_H_ */
