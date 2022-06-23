#ifndef _DPI_INTERFACE_HPP_
#define _DPI_INTERFACE_HPP_

#include <queue>
#include "svdpi.h"
#include "socketstream.h"
#include "messages.h"

#define NE 4*4*2

//***************************************************************************
// DPI-C interface
//***************************************************************************

extern "C" void c_epi_interface ( 
        svLogic startCom, svLogic getData, svLogic ejectReq,  svLogic queueReq,
        svLogic *endCom, svLogic *newReq, 
        svBitVec32 source_all[NE], svBitVec32 destination_all[NE], 
        svBitVec32 address_all[NE], svBitVec32 opcode_all[NE], 
        svBitVec32 id_all[NE], svBitVec32 valid_all[NE],
        svBitVec32 rtrn_pkgid_all[NE]       ,
        svBitVec32 rtrn_valid_all[NE]       ,       
        svBitVec32 NEready_all[NE], svBitVec32 size_all[NE]            
        );

extern "C" void connection_init ( 
        svLogic startCom, svLogic *ready
        );

//***************************************************************************
// Connection manager class
//***************************************************************************
struct ReplyPacket {
	int source;
	int dest;
	int id;
	int network;
	int cl;
	int miss_pred;
};

struct RequestPacket {
	int source;
	int dest;
	int id;
	int size;
	int network;
	int cl;
	int miss_pred;
};


class connection_manager {
    private:

	    //SocketStream *_channel;
	    SocketStream _listenSocket;

        int _sources;
        int _dests;
        int _duplicate_networks;


    
    public:
        connection_manager();
        int Init();
        int Step();
        int readMsg();
        int sendResMsg();
        int sendAckMsg();
        int sendAckReqMsg();
        
        int checkInjection();
        
        int getSynfullEndPoint(int node);
        int getPronocEndPoint(int node);
        int getMsgType(int opcode);
        int getChiOpc(int opcode, int type);
        
        ReplyPacket *DequeueReplyPacket();
        int printResMsg(EjectResMsg res); 
        int printReqMsg(InjectReqMsg *req);


};
	    
SocketStream *_channel;

connection_manager *_connection_manager ;

//socket communication
StreamMessage *_msg ;
InjectReqMsg  *_req ;
InjectReqMsg  *_req_tmp ;

EjectResMsg  _res    ;
StepResMsg   _ackRes ;
InjectResMsg _ackReq ; 

queue<EjectResMsg> _eject_buffer;
queue<InjectReqMsg*> _inject_buffer;

//tmp
RequestPacket *rp;
svLogic _newInjection;

#endif

