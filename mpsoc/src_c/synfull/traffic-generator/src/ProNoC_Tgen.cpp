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


#include <fstream>
#include <stdio.h>


#include "socketstream.h"
#include "messages.h"
#include "Global.h"

#include "PacketQueue.h"
#include "ModelRead.h"



#include "TrafficGenerator.h"


typedef struct node node_t;
typedef struct queue queue_t;

struct node {
	node_t* prev;
	node_t* next;
	unsigned long long int prio;
	void* elem;
};

struct queue {
	node_t* head;
	node_t* tail;
};



int * pronoc_mapping;


queue_t* synful_queue_new() {
	queue_t* to_return = (queue_t*) malloc( sizeof(queue_t) );
	if( to_return == NULL ) {
		printf( "Failed malloc in queue_new\n" );
		exit(0);
	}
	to_return->head = NULL;
	to_return->tail = NULL;
	return to_return;
}


#include "synful.h"



bool synful_ssExit =false;
int synful_injection_done=0;

static  unsigned int  synful_max_pck;
static  unsigned int  synful_max_clk;



void synful_queue_push( queue_t* q, void* e, unsigned long long int prio ) {
	if( q != NULL ) {
		if( q->head == NULL ) {
			q->head = (node_t*) malloc( sizeof(node_t) );
			if( q->head == NULL ) {
				printf( "Failed malloc in queue_push\n" );
				exit(0);
			}
			q->tail = q->head;
			q->head->prev = NULL;
			q->head->next = NULL;
			q->head->elem = e;
			q->head->prio = prio;
		} else {
			node_t* to_add = (node_t*) malloc( sizeof(node_t) );
			if( to_add == NULL ) {
				printf( "Failed malloc in queue_push\n" );
				exit(0);
			}
			to_add->prio = prio;
			to_add->elem = e;
			node_t* behind;
			for( behind = q->head; (behind != NULL) && (behind->prio < prio); behind = behind->next );
			to_add->next = behind;
			if( behind == NULL ) {
				to_add->prev = q->tail;
				q->tail->next = to_add;
				q->tail = to_add;
			} else if( behind == q->head ) {
				to_add->prev = behind->prev;
				behind->prev = to_add;
				q->head = to_add;
			} else {
				to_add->prev = behind->prev;
				to_add->prev->next = to_add;
				behind->prev = to_add;
			}
		}
	} else {
		printf( "Must initialize queue with queue_new()\n" );
		exit(0);
	}
}




using namespace std;


unsigned long long synful_numCycles;



//Set this to 0 to debug without connecting to booksim
#define CONNECT 0


queue_t** synful_inject;

int synful_steady_exit_activated=0;


static unsigned long long synful_next_interval;
static unsigned long long synful_next_hinterval;
unsigned long long synful_cycle;
static unsigned long int synful_total_pck_queud=0;
unsigned long long int synful_cntPackets = 0;




int synful_state = 1;
int synful_lastState = 1;
int synful_lastHState = 1;

int synful_messageId = 0;

int synful_allPacketsEjected=0;

//Steady state
map<int, map<int, int> > synful_steadyState;
map<int, int> synful_hSteadyState;
map<int, double> synful_acceptable_mse;
double synful_acceptable_hmse;

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

map<int, InjectReqMsg> synful_inTransitPackets;
map<int, transaction_t> synful_inTransitTransactions;
PacketQueue synful_packet_queue;

void synful_TranslateIndex(int index, int& source, int& destination) {
    source = (int) index / 32; //Truncate remainder
    destination = index - (source * 32);
}




void* _synful_checked_malloc( size_t n, const char* file, int line ) {
	void* ptr;
	ptr = malloc( n );
	if( ptr == NULL ) {
		fprintf( stderr, "ERROR: bad allocation at %s:%d\n", file, line );
		exit(0);
	}
	return ptr;
}

#define synful_checked_malloc(x) _synful_checked_malloc(x,__FILE__,__LINE__)




void synful_printPacket(InjectReqMsg msg) {
    cout << msg.id << " ";
    cout << synful_cycle << " ";
    cout << msg.source << " ";
    cout << msg.dest << " ";
    cout << msg.packetSize << " ";
    cout << msg.msgType << " ";
    cout << msg.coType << " ";
    cout << msg.address << " ";
    cout << synful_state;
    cout << endl;
}

#define SYNFUL_NUM_PACKET_TYPES  10

const char* synful_packet_types[] = {
"INITIALIZE_REQ"  ,
"INITIALIZE_RES"  ,
"STEP_REQ"        ,
"STEP_RES"        ,
"INJECT_REQ"      ,
"INJECT_RES"      ,
"EJECT_REQ"       ,
"EJECT_RES"       ,
"QUIT_REQ"        ,
"QUIT_RES"        ,
"INVALID"
};

const char* synful_packet_type_to_string( pronoc_pck_t* packet ) {
	if( packet->msgType < SYNFUL_NUM_PACKET_TYPES ) {
		return synful_packet_types[packet->msgType];
	} else {
		return synful_packet_types[SYNFUL_NUM_PACKET_TYPES];
	}
}



void synful_print_packet( pronoc_pck_t* packet ) {
	if( packet != NULL ) {
		printf( "  ID:%u SRC:%u DST:%u SIZ:%u TYP:%s",
				packet->id, packet->source,
				packet->dest, packet->packetSize, synful_packet_type_to_string(packet) );

		printf( "\n" );
	} else {
		printf( "WARNING: %s:%d: NULL packet printed!\n", __FILE__, __LINE__ );
	}
}



void synful_sendPacket(InjectReqMsg& req) {
    req.id = synful_messageId;

    if((int) req.address == -1) {
        req.address = synful_messageId;
        synful_inTransitTransactions[req.address].source = req.source;
        synful_inTransitTransactions[req.address].dest = req.dest;
        synful_inTransitTransactions[req.address].invs_sent = 0;
        synful_inTransitTransactions[req.address].acks_received = 0;
    }
    synful_messageId++;

    synful_inTransitPackets[req.id] = req;
    pronoc_pck_t* new_node = (pronoc_pck_t*) synful_checked_malloc( sizeof(pronoc_pck_t) );
    new_node->source = req.source;
    new_node->dest= req.dest;
    new_node->id= req.id;
    new_node->packetSize= req.packetSize;
    new_node->msgType=req.msgType;
    new_node->cycle = synful_cycle;
    int pronoc_id = pronoc_mapping [req.source];
    synful_queue_push( synful_inject[pronoc_id], new_node, synful_cycle );
}

double synful_calculate_mse(vector<double> predict, vector<double> actual) {
    if(predict.size() != actual.size()) {
        return -1;
    }

    double sum = 0;
    for(unsigned int i = 0; i < predict.size(); i++) {
        sum += (predict[i] - actual[i]) * (predict[i] - actual[i]);
    }

    return ((double) sum / predict.size());
}

bool synful_InHSteadyState(int synful_numCycles) {
    vector<double> predict;
    int sum = 0;
    for (map<int, int>::iterator it=synful_hSteadyState.begin();
            it!=synful_hSteadyState.end(); ++it) {
        double value =  it->second;
        sum+= value;
        predict.push_back(value);
    }

    for(unsigned int i = 0; i < predict.size(); i++) {
        predict[i] = ((double) predict[i] / sum);
    }

    double mse = synful_calculate_mse(predict, g_hierSState);
    if(mse >= 0 && mse < synful_acceptable_hmse && synful_cycle > synful_numCycles*0.3) {
        return true;
    }

    if(synful_cycle > synful_numCycles*0.7) {
        return true;
    }

    return false;
}



void synful_QueuePacket(int source, int destination, int msgType, int coType,
        int packetSize, int time, int address) {

	 if((synful_total_pck_queud >=  synful_max_pck) || (synful_cycle > synful_max_clk)    ||  (synful_steady_exit_activated==1)){
	    	if(synful_injection_done!=1){
	    		if (synful_total_pck_queud >  synful_max_pck)  cout << "Reaching max injected packet limit: " << synful_total_pck_queud << " Ending simulation: " << synful_cycle << endl;
	    		if (synful_cycle > synful_max_clk)     		   cout << "Ending simulation at max simulation clk: " << synful_cycle << endl;
	    		if (synful_steady_exit_activated==1)           cout << "Ending simulation at steady state: " << synful_cycle << endl;
	    	}
	    	synful_injection_done=1;
	    	return;
	 }



	InjectReqMsg packet;
    packet.source = source;
    packet.dest = destination;
    packet.cl = 0;
    packet.network = 0;
    packet.packetSize = packetSize;
    packet.msgType = msgType;
    packet.coType = coType;
    packet.address = address;

    synful_packet_queue.Enqueue(packet, time);
    synful_total_pck_queud++;
}

void synful_UniformInject(int writes, int reads, int ccrs, int dcrs) {
    int source, destination;
    UniformDistribution uni_dist(0, g_resolution/2 -1);

    int delta = 0;
    


    for(int i = 0; i < writes; i++) {
        delta = uni_dist.Generate(DEFAULT_ENG) * 2;
        source = g_writeSpat[g_hierClass][synful_state].Generate(DEFAULT_ENG);
        source = source * 2;

        destination = g_writeDest[g_hierClass][synful_state][source].Generate(DEFAULT_ENG);
        destination = destination * 2 + 1;

        synful_QueuePacket(source, destination, REQUEST, WRITE, CONTROL_SIZE,
                synful_cycle + delta, -1);
    }

    for(int i = 0; i < reads; i++) {
        delta = uni_dist.Generate(DEFAULT_ENG) * 2;
        source = g_readSpat[g_hierClass][synful_state].Generate(DEFAULT_ENG);
        source = source * 2;

        destination = g_readDest[g_hierClass][synful_state][source].Generate(DEFAULT_ENG);
        destination = destination * 2 + 1;

        synful_QueuePacket(source, destination, REQUEST, READ, CONTROL_SIZE,
                synful_cycle + delta, -1);
    }

    for(int i = 0; i < ccrs; i++) {
        delta = uni_dist.Generate(DEFAULT_ENG) * 2;
        source = g_ccrSpat[g_hierClass][synful_state].Generate(DEFAULT_ENG);
        source = source * 2;

        destination = g_ccrDest[g_hierClass][synful_state][source].Generate(DEFAULT_ENG);
        destination = destination * 2 + 1;

        synful_QueuePacket(source, destination, REQUEST, PUTC, CONTROL_SIZE,
                synful_cycle + delta, -1);
    }
    
    for(int i = 0; i < dcrs; i++) {
        delta = uni_dist.Generate(DEFAULT_ENG) * 2;
        source = g_dcrSpat[g_hierClass][synful_state].Generate(DEFAULT_ENG);
        source = source * 2;

        destination = g_dcrDest[g_hierClass][synful_state][source].Generate(DEFAULT_ENG);
        destination = destination * 2 + 1;

        synful_QueuePacket(source, destination, REQUEST, PUTD, DATA_SIZE,
                synful_cycle + delta, -1);
    }
}

//Volumes
void synful_InitiateMessages() {
    int writes = g_writes[g_hierClass][synful_state].Generate(INIT_MSG_ENG);
    int reads = g_reads[g_hierClass][synful_state].Generate(INIT_MSG_ENG);
    int ccrs = g_ccrs[g_hierClass][synful_state].Generate(INIT_MSG_ENG);
    int dcrs = g_dcrs[g_hierClass][synful_state].Generate(INIT_MSG_ENG);

    //cout << "synfull: writes " << writes << " reads " << reads << " ccrs " << ccrs << " dcrs " << dcrs  << endl;
    synful_UniformInject(writes, reads, ccrs, dcrs);
}

void synful_Inject() {
    list<InjectReqMsg> packets = synful_packet_queue.DeQueue(synful_cycle);
    list<InjectReqMsg>::iterator it;

    for(it = packets.begin(); it != packets.end(); ++it) {
        synful_sendPacket(*it);
    }

    synful_packet_queue.CleanUp(synful_cycle);
}

void synful_react(EjectResMsg ePacket) {
    map<int, InjectReqMsg>::iterator it = synful_inTransitPackets.find(ePacket.id);
    if(it == synful_inTransitPackets.end()) {
        cerr << "Error: couldn't find in transit packet " << ePacket.id << endl;
        exit(-1);
    }

    InjectReqMsg request = it->second;
    InjectReqMsg response;
    synful_inTransitPackets.erase(it);

    //cout << "synfull received packet id: " << request.id << " " << cycle  << endl;


    map<int, transaction_t>::iterator trans = synful_inTransitTransactions.find(request.address);

    if(request.msgType == REQUEST &&
            (request.coType == WRITE || request.coType == READ)) {
        //Handle Read/Write Requests
        if((int) request.address == request.id) {
            //This is an initiating request. Should we forward it or go to
            //memory?
            bool isForwarded = g_toForward[g_hierClass][request.dest][request.coType].Generate(REACT_ENG) == 0;

            if(isForwarded) {
                int destination = g_forwardDest[g_hierClass][synful_state][request.dest].Generate(REACT_ENG);
                destination = destination*2;
                if(destination % 2 != 0) {
                    cerr << "Error: Invalid destination for forwarded request." << endl;
                    exit(-1);
                }

                synful_QueuePacket(request.dest, destination, REQUEST, request.coType,
                        CONTROL_SIZE, synful_cycle + 1, request.address);

                if(request.coType == WRITE) {
                    //How many invalidates to send
                    int numInv = g_numInv[g_hierClass][synful_state][request.dest].Generate(REACT_ENG);
                    int s = synful_state;

                    if(numInv <= 0) {
                        return;
                    }

                    //Ensure invalidate destinations are unique (i.e. no two
                    //invalidate messages to the same destination)
                    set<int> destinations;
                    destinations.insert(destination); //Request already forwarded here
                    while(destinations.size() != (unsigned int) numInv) {
                        int dest = g_invDest[g_hierClass][s][request.dest].Generate(REACT_ENG);
                        dest = dest*2;
                        destinations.insert(dest);
                    }

                    for(set<int>::iterator it = destinations.begin();
                            it != destinations.end(); ++it) {
                        synful_QueuePacket(request.dest, *it, REQUEST, INV,
                                CONTROL_SIZE, synful_cycle + 1, request.address);
                        trans->second.invs_sent++;
                    }
                }

            } else {
                //Access memory, queue up a data response for the future
                    //cout << "synfull mem access  id: " << request.id << " src:"<< request.source 
                    //    << " dst:" << request.dest << " addr:" << request.address 
                    //    << " " << cycle  << endl;
                synful_QueuePacket(request.dest, request.source, RESPONSE, DATA,
                        DATA_SIZE, synful_cycle + 80, request.address);
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
            synful_QueuePacket(request.dest,
                    trans->second.source, RESPONSE,
                    DATA, DATA_SIZE, synful_cycle + 1, request.address);
        }
    } 
    else if(request.msgType == REQUEST &&
            (request.coType == PUTC || request.coType == PUTD)) {
        //Respond with WB_ACK
        synful_QueuePacket(request.dest, request.source, RESPONSE, WB_ACK,
                CONTROL_SIZE, synful_cycle + 1, request.address);
        
    }
    else if(request.msgType == REQUEST && request.coType == INV) {
        //Respond with Ack
        synful_QueuePacket(request.dest, trans->second.source,
                RESPONSE, ACK, CONTROL_SIZE, synful_cycle + 1, request.address);
    } else if(request.msgType == RESPONSE && request.coType == DATA) {
        trans->second.data_received = true;
        //Send unblock
        synful_QueuePacket(synful_inTransitTransactions[request.address].source,
                synful_inTransitTransactions[request.address].dest, RESPONSE, UNBLOCK,
                CONTROL_SIZE, synful_cycle + 1, request.address);
    } else if(request.msgType == RESPONSE && request.coType == ACK) {
        trans->second.acks_received++;
    } else if(request.msgType == RESPONSE && request.coType == UNBLOCK) {
                trans->second.unblock_received = true;
        }

    if(trans->second.Completed()) {
        synful_inTransitTransactions.erase(trans);
    }
}









void synful_reset_ss() {
    for (std::map<int,int>::iterator it=synful_steadyState[g_hierClass].begin();
            it!=synful_steadyState[g_hierClass].end(); ++it) {
        it->second = 0;
    }
   synful_state = 1;
}





void synful_model_init(char * fname, bool ss_exit, int seed,unsigned int max_clk, unsigned int max_pck, int * mapping){
    cout << "Initiating synful with: " << fname << "random seed:" << seed << endl;
	synful_ssExit = ss_exit;


 	ifstream modelFile(fname);
	if(!modelFile.good()) {
		cerr << "Could not open file " << fname << endl;
		exit(-1);
	}


	//Parses the file and stores all information in global variables
	ReadModel(modelFile);

	//Close the file stream
	modelFile.close(); 	
 	
 	synful_next_interval = 0;
    synful_next_hinterval = 0;
 	//Calculate an acceptable MSE for the Markovian Steady-State
    double sensitivity = 1.04;
	vector<double> predict;
    for (unsigned int i = 0; i < g_hierSState.size(); i++) {
        predict.push_back(((double) g_hierSState[i] * sensitivity));
    }
    synful_acceptable_hmse = synful_calculate_mse(predict, g_hierSState);

    synful_max_pck =max_pck;
    synful_max_clk =max_clk;
    for (int i=0;i< RND_ENG_NUM; i++){
    	mt_rng[i].seed(seed+i);
    }

    pronoc_mapping=mapping;

}


void synful_run_one_cycle (){

           if(synful_cycle >= synful_next_hinterval) {
                synful_next_hinterval += g_timeSpan;

                synful_hSteadyState[g_hierClass]++;

                if(synful_cycle != 0) {
                    synful_lastHState = g_hierClass;
                    g_hierClass = g_hierState[g_hierClass].Generate(hierClass_ENG) + 1;
                    synful_reset_ss();
                }

                if(synful_InHSteadyState(synful_numCycles) && synful_ssExit) {
                   

                    //end simulation
                    synful_steady_exit_activated=1;
                }

                cout << "Current hierarchical state: " << g_hierClass << endl;
            }

            if(synful_cycle >= synful_next_interval) {
                synful_next_interval += g_resolution;

                //Track state history for markovian steady state
                synful_steadyState[g_hierClass][synful_state]++;

                if(synful_cycle != 0) {
                    //Update state
                    synful_lastState = synful_state;
                    synful_state = g_states1[g_hierClass][synful_state].Generate(hierClass_ENG) + 1;
                }

                //Queue up initiating messages for injection
                synful_InitiateMessages();
            }

            //Inject all of this cycles' messages into the network injection queue
            synful_Inject();
           
                
            if (synful_allPacketsEjected) 
            {
                cout << "all pck injected" << endl;
                synful_cycle = synful_numCycles; 
            }

}


void synful_Eject (pronoc_pck_t * packet){

	EjectResMsg res;

	res.id = packet->id;
	res.source = packet->source;
	res.dest = packet->dest;
	res.packetSize = packet->packetSize;
	res.network = 0;
	res.cl =0;
	//res->miss_pred;
	//res->remainingRequests;



	//bool hasRequests = true; //Whether there are more requests from the network
	if(res.id >= 0) {
    //Add responses to list
        if(res.id > -1) {
             synful_cntPackets++;
             synful_react(res);
        }
     }
    //Check if there are more messages from the network
   // hasRequests = res.remainingRequests;
}





