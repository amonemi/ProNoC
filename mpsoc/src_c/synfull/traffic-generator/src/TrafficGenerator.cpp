/* 
Copyright (c) 2014, Mario Badr
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
/*
 * TrafficGenerator.cpp
 *
 *  Created on: 2013-01-13
 *      Author: mario
 */

#include <iostream>
#include <list>
#include <math.h>

#include "assert.h"
#include <map>
#include <list>
#include <set>

#include "socketstream.h"
#include "messages.h"
#include "Global.h"

#include "PacketQueue.h"

using namespace std;

//Set this to 0 to debug without connecting to booksim
#define CONNECT 1

SocketStream m_channel;

static unsigned long long next_interval;
static unsigned long long next_hinterval;

static unsigned long long cycle;

static unsigned long int total_pck_queud=0;

int state = 1;
int lastState = 1;
int lastHState = 1;

int messageId = 0;

int allPacketsEjected=0;

//Steady state
map<int, map<int, int> > steadyState;
map<int, int> hSteadyState;
map<int, double> acceptable_mse;
double acceptable_hmse;

struct transaction_t {
    int source;
    int dest;
    int invs_sent;
    int acks_received;
    bool data_received;
    bool unblock_received;

    bool Completed() {
        return (invs_sent == acks_received) && data_received && unblock_received;
    }

    transaction_t() : source(-1), dest(-1), invs_sent(0), acks_received(0),
            data_received(false), unblock_received(false) {}
};

map<int, InjectReqMsg> inTransitPackets;
map<int, transaction_t> inTransitTransactions;
PacketQueue packet_queue;

void TranslateIndex(int index, int& source, int& destination) {
    source = (int) index / 32; //Truncate remainder
    destination = index - (source * 32);
}

void printPacket(InjectReqMsg msg) {
    cout << msg.id << " ";
    cout << cycle << " ";
    cout << msg.source << " ";
    cout << msg.dest << " ";
    cout << msg.packetSize << " ";
    cout << msg.msgType << " ";
    cout << msg.coType << " ";
    cout << msg.address << " ";
    cout << state;
    cout << endl;
}

void connect() {
#if CONNECT
    // connect to network simulator
    assert(m_channel.connect(NS_HOST, NS_PORT) == 0);

    // send request to initialize
    InitializeReqMsg req;
    InitializeResMsg res;
    m_channel << req >> res;
#endif
}

void exit() {
	cout << "Total packet sent to queue: " << total_pck_queud << endl;
#if CONNECT
    // Notify network we are quitting
    QuitReqMsg req;
    QuitResMsg res;
    m_channel << req >> res;
#endif
}

void sendPacket(InjectReqMsg& req) {
    req.id = messageId;

    if((int) req.address == -1) {
        req.address = messageId;
        inTransitTransactions[req.address].source = req.source;
        inTransitTransactions[req.address].dest = req.dest;
        inTransitTransactions[req.address].invs_sent = 0;
        inTransitTransactions[req.address].acks_received = 0;
    }
    messageId++;

    inTransitPackets[req.id] = req;

#if CONNECT
    InjectResMsg res;

    m_channel << req >> res;
#endif
}

double calculate_mse(vector<double> predict, vector<double> actual) {
    if(predict.size() != actual.size()) {
        return -1;
    }

    double sum = 0;
    for(unsigned int i = 0; i < predict.size(); i++) {
        sum += (predict[i] - actual[i]) * (predict[i] - actual[i]);
    }

    return ((double) sum / predict.size());
}

bool InHSteadyState(int numCycles) {
    vector<double> predict;
    int sum = 0;
    for (map<int, int>::iterator it=hSteadyState.begin();
            it!=hSteadyState.end(); ++it) {
        double value =  it->second;
        sum+= value;
        predict.push_back(value);
    }

    for(unsigned int i = 0; i < predict.size(); i++) {
        predict[i] = ((double) predict[i] / sum);
    }

    double mse = calculate_mse(predict, g_hierSState);
    if(mse >= 0 && mse < acceptable_hmse && cycle > numCycles*0.3) {
        return true;
    }

    if(cycle > numCycles*0.7) {
        return true;
    }

    return false;
}



void QueuePacket(int source, int destination, int msgType, int coType,
        int packetSize, int time, int address) {
    InjectReqMsg packet;
    packet.source = source;
    packet.dest = destination;
    packet.cl = 0;
    packet.network = 0;
    packet.packetSize = packetSize;
    packet.msgType = msgType;
    packet.coType = coType;
    packet.address = address;

    packet_queue.Enqueue(packet, time);
    total_pck_queud++;
}

void UniformInject(int writes, int reads, int ccrs, int dcrs) {
    int source, destination;
    UniformDistribution uni_dist(0, g_resolution/2 -1);

    int delta = 0;
    
    for(int i = 0; i < writes; i++) {
        delta = uni_dist.Generate(0) * 2;
        source = g_writeSpat[g_hierClass][state].Generate(0);
        source = source * 2;

        destination = g_writeDest[g_hierClass][state][source].Generate(0);
        destination = destination * 2 + 1;

        QueuePacket(source, destination, REQUEST, WRITE, CONTROL_SIZE,
                cycle + delta, -1);
    }

    for(int i = 0; i < reads; i++) {
        delta = uni_dist.Generate(0) * 2;
        source = g_readSpat[g_hierClass][state].Generate(0);
        source = source * 2;

        destination = g_readDest[g_hierClass][state][source].Generate(0);
        destination = destination * 2 + 1;

        QueuePacket(source, destination, REQUEST, READ, CONTROL_SIZE,
                cycle + delta, -1);
    }

    for(int i = 0; i < ccrs; i++) {
        delta = uni_dist.Generate(0) * 2;
        source = g_ccrSpat[g_hierClass][state].Generate(0);
        source = source * 2;

        destination = g_ccrDest[g_hierClass][state][source].Generate(0);
        destination = destination * 2 + 1;

        QueuePacket(source, destination, REQUEST, PUTC, CONTROL_SIZE,
                cycle + delta, -1);
    }
    
    for(int i = 0; i < dcrs; i++) {
        delta = uni_dist.Generate(0) * 2;
        source = g_dcrSpat[g_hierClass][state].Generate(0);
        source = source * 2;

        destination = g_dcrDest[g_hierClass][state][source].Generate(0);
        destination = destination * 2 + 1;

        QueuePacket(source, destination, REQUEST, PUTD, DATA_SIZE,
                cycle + delta, -1);
    }
}

//Volumes
void InitiateMessages() {
    int writes = g_writes[g_hierClass][state].Generate(0);
    int reads = g_reads[g_hierClass][state].Generate(0);
    int ccrs = g_ccrs[g_hierClass][state].Generate(0);
    int dcrs = g_dcrs[g_hierClass][state].Generate(0);

    //cout << "synfull: writes " << writes << " reads " << reads << " ccrs " << ccrs << " dcrs " << dcrs  << endl;
    UniformInject(writes, reads, ccrs, dcrs);
}

void Inject() {
    list<InjectReqMsg> packets = packet_queue.DeQueue(cycle);
    list<InjectReqMsg>::iterator it;

    for(it = packets.begin(); it != packets.end(); ++it) {
        sendPacket(*it);
    }

    packet_queue.CleanUp(cycle);
}

void react(EjectResMsg ePacket) {
    map<int, InjectReqMsg>::iterator it = inTransitPackets.find(ePacket.id);
    if(it == inTransitPackets.end()) {
        cerr << "Error: couldn't find in transit packet " << ePacket.id << endl;
        exit(-1);
    }

    InjectReqMsg request = it->second;
    InjectReqMsg response;
    inTransitPackets.erase(it);

    //cout << "synfull received packet id: " << request.id << " " << cycle  << endl;


    map<int, transaction_t>::iterator trans = inTransitTransactions.find(request.address);

    if(request.msgType == REQUEST &&
            (request.coType == WRITE || request.coType == READ)) {
        //Handle Read/Write Requests
        if((int) request.address == request.id) {
            //This is an initiating request. Should we forward it or go to
            //memory?
            bool isForwarded = g_toForward[g_hierClass][request.dest][request.coType].Generate(0) == 0;

            if(isForwarded) {
                int destination = g_forwardDest[g_hierClass][state][request.dest].Generate(0);
                destination = destination*2;
                if(destination % 2 != 0) {
                    cerr << "Error: Invalid destination for forwarded request." << endl;
                    exit();
                }

                QueuePacket(request.dest, destination, REQUEST, request.coType,
                        CONTROL_SIZE, cycle + 1, request.address);

                if(request.coType == WRITE) {
                    //How many invalidates to send
                    int numInv = g_numInv[g_hierClass][state][request.dest].Generate(0);
                    int s = state;

                    if(numInv <= 0) {
                        return;
                    }

                    //Ensure invalidate destinations are unique (i.e. no two
                    //invalidate messages to the same destination)
                    set<int> destinations;
                    destinations.insert(destination); //Request already forwarded here
                    while(destinations.size() != (unsigned int) numInv) {
                        int dest = g_invDest[g_hierClass][s][request.dest].Generate(0);
                        dest = dest*2;
                        destinations.insert(dest);
                    }

                    for(set<int>::iterator it = destinations.begin();
                            it != destinations.end(); ++it) {
                        QueuePacket(request.dest, *it, REQUEST, INV,
                                CONTROL_SIZE, cycle + 1, request.address);
                        trans->second.invs_sent++;
                    }
                }

            } else {
                //Access memory, queue up a data response for the future
                    //cout << "synfull mem access  id: " << request.id << " src:"<< request.source 
                    //    << " dst:" << request.dest << " addr:" << request.address 
                    //    << " " << cycle  << endl;
                QueuePacket(request.dest, request.source, RESPONSE, DATA,
                        DATA_SIZE, cycle + 80, request.address);
            }

            return;
        } else {
            //This is not an initiating request, so it's a forwarded request
            //if(request.id==52)
            //{
            //    cout << "synfull packet debug  id: " << request.id << " src:"<< request.dest 
            //        << " dst:" << trans->second.source << 
            //           " addr:" << request.address << " " << cycle  << endl;
            //}

            //Respond with Data
            QueuePacket(request.dest,
                    trans->second.source, RESPONSE,
                    DATA, DATA_SIZE, cycle + 1, request.address);
        }
    } 
    else if(request.msgType == REQUEST &&
            (request.coType == PUTC || request.coType == PUTD)) {
        //Respond with WB_ACK
        QueuePacket(request.dest, request.source, RESPONSE, WB_ACK,
                CONTROL_SIZE, cycle + 1, request.address);
        
    }
    else if(request.msgType == REQUEST && request.coType == INV) {
        //Respond with Ack
        QueuePacket(request.dest, trans->second.source,
                RESPONSE, ACK, CONTROL_SIZE, cycle + 1, request.address);
    } else if(request.msgType == RESPONSE && request.coType == DATA) {
        trans->second.data_received = true;
        //Send unblock
        QueuePacket(inTransitTransactions[request.address].source,
                inTransitTransactions[request.address].dest, RESPONSE, UNBLOCK,
                CONTROL_SIZE, cycle + 1, request.address);
    } else if(request.msgType == RESPONSE && request.coType == ACK) {
        trans->second.acks_received++;
    } else if(request.msgType == RESPONSE && request.coType == UNBLOCK) {
                trans->second.unblock_received = true;
        }

    if(trans->second.Completed()) {
        inTransitTransactions.erase(trans);
    }
}

unsigned long long int cntPackets = 0;

void Eject(unsigned int numPackets) {
#if CONNECT
    EjectReqMsg req; //The request to the network
    EjectResMsg res; //The response from the network
    bool hasRequests = true; //Whether there are more requests from the network

    //Loop through all the network's messages
    while(hasRequests) {
        m_channel << req >> res;

        if(res.id >= 0) {
            //Add responses to list
            if(res.id > -1) {
                cntPackets++;
                react(res);
            }
        }
        //Check if there are more messages from the network
        hasRequests = res.remainingRequests;
        
    }

        if (cntPackets == numPackets) 
        {
            allPacketsEjected=1;
        }
#endif
}

void reset_ss() {
    for (std::map<int,int>::iterator it=steadyState[g_hierClass].begin();
            it!=steadyState[g_hierClass].end(); ++it) {
        it->second = 0;
    }
    state = 1;
}

void Run(unsigned int numCycles, bool ssExit, unsigned int numPackets) {
    next_interval = 0;
    next_hinterval = 0;

    //Calculate an acceptable MSE for the Markovian Steady-State
    double sensitivity = 1.04;
    vector<double> predict;
    for (unsigned int i = 0; i < g_hierSState.size(); i++) {
        predict.push_back(((double) g_hierSState[i] * sensitivity));
    }
    acceptable_hmse = calculate_mse(predict, g_hierSState);

    //Connect to network simulator
    connect();

        //Iterate through each cycle and inject packets
        for(cycle = 0; cycle < numCycles; ++cycle) {
            if(cycle >= next_hinterval) {
                next_hinterval += g_timeSpan;

                hSteadyState[g_hierClass]++;

                if(cycle != 0) {
                    lastHState = g_hierClass;
                    g_hierClass = g_hierState[g_hierClass].Generate(0) + 1;
                    reset_ss();
                }

                if(InHSteadyState(numCycles) && ssExit) {
                    cout << "Ending simulation at steady state: " << cycle << endl;
                    break;
                }

                cout << "Current hierarchical state: " << g_hierClass << endl;
            }

            if(cycle >= next_interval) {
                next_interval += g_resolution;

                //Track state history for markovian steady state
                steadyState[g_hierClass][state]++;

                if(cycle != 0) {
                    //Update state
                    lastState = state;
                    state = g_states1[g_hierClass][state].Generate(0) + 1;
                }

                //Queue up initiating messages for injection
                InitiateMessages();
            }

            //Inject all of this cycles' messages into the network
            Inject();

            //Eject from network
            Eject(numPackets);
                
            if (allPacketsEjected) 
            {
                cycle = numCycles; 
            }
            //Step the network
#if CONNECT
            StepReqMsg req;
            StepResMsg res;
            m_channel << req >> res;
#endif
        }

    //Close the connection
    exit();
}
