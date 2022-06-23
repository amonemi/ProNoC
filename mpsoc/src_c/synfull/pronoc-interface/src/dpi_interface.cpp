#include <stdio.h>
#include <stdlib.h>
#include <sstream>
#include <cassert>
#include <cstdlib>
#include <cstdio>
#include <cerrno>
#include "socketstream.h"
#include "messages.h"
#include "svdpi.h"
#include "dpi_interface.hpp"


extern "C" void connection_init ( 
        svLogic startCom, svLogic *ready
        )
{
    
    if ( startCom == 1 )
    {
        _connection_manager = new connection_manager;
        rp = new RequestPacket();
        _connection_manager->Init();
        *ready = '1';
    }
    
}

extern "C" void c_dpi_interface ( 
        svLogic startCom, svLogic getData, svLogic ejectReq,  svLogic queueReq, svLogic *endCom, 
        svLogic *newReq, svBitVec32 source_all[NE], svBitVec32 destination_all[NE], 
        svBitVec32 address_all[NE], svBitVec32 opcode_all[NE], svBitVec32 id_all[NE], 
        svBitVec32 valid_all[NE], svBitVec32 rtrn_pkgid_all[NE], 
        svBitVec32 rtrn_valid_all[NE], svBitVec32 NEready_all[NE], 
        svBitVec32 size_all[NE] ,
        svBitVec32 enqueue_valid[NE]   ,
        svBitVec32 enqueue_src[NE]     ,
        svBitVec32 enqueue_dst[NE]     ,
        svBitVec32 enqueue_id[NE]      ,
        svBitVec32 enqueue_size[NE]                      
        )
{

    bool process_more = true;
    int msgDone = 0;
    *endCom = '0'; 
    *newReq = '0';
    int noreq=0;
    int node_dst;
    int node_src;
    int toDataPort=0;
    int toRspPort=0;
    int id_cnt=0;

    int rtrn_valid_all_[NE];    
    int _enqueue_valid[NE] ;

    for(int i=0; i<NE; i++) {
        valid_all[i] = 0;
        rtrn_valid_all_[i] = rtrn_valid_all[i];
        _enqueue_valid[i] = enqueue_valid[i];
    }


    if (startCom == 1 && getData == 1) 
    {
        //cout << "\n*** new clock *** " << endl
        
        
        while ( process_more )
        {
            // read message
            _connection_manager->readMsg();
            

            switch(_msg->type)
            { 
                case STEP_REQ: //2
                    {
                        StepResMsg res;
                        *_channel << res;
                        
                        if (queueReq == 1)
                        {
                            // enqueue packets from pronoc
                            for(int k=0; k<NE; k++)
                            {
                                if (_enqueue_valid[k] == 1){
                                    _req->size    = enqueue_size[k];
                                    _req->dest    = enqueue_dst[k];
                                    _req->source  = enqueue_src[k];
                                    _req->id      = enqueue_id[k];

                                    if (_inject_buffer.empty()) 
                                    {
                                        _inject_buffer.push(_req);
                                        //cout << "<enqueue> id: " << _req->id << endl;
                                    }
                                    else
                                    {
                                        int quesize = _inject_buffer.size();
                                        for(int i=0;i<quesize;i++)
                                        {
                                            _req_tmp = _inject_buffer.front();
                                            _inject_buffer.pop();
                                            if ( _req->id == _req_tmp->id ) id_cnt++;
                                            _inject_buffer.push(_req_tmp);
                                        }
                                        if(id_cnt == 0)
                                        {
                                            _inject_buffer.push(_req);
                                            //cout << "<enqueue> id: " << _req->id << endl;
                                        }
                                        id_cnt=0;
                                    }
                                    _enqueue_valid[k] = 0;
                                }
                            }
                        }
    
                        //dequeue packets to send to pronoc
                        if (!_inject_buffer.empty()) {
                            int quesize = _inject_buffer.size();
                            
                            for(int i=0;i<quesize;i++){
                                _req = _inject_buffer.front();
                                _inject_buffer.pop();

                                if(NEready_all[_req->source] == 1 & valid_all[_req->source] == 0)
                                {
                                    address_all[_req->source]     = _req->address     ;
                                    size_all[_req->source]        = _req->packetSize  ;
                                    destination_all[_req->source] = _req->dest        ;
                                    source_all[_req->source]      = _req->source      ;
                                    opcode_all[_req->source]      = _req->coType      ;
                                    id_all[_req->source]          = _req->id          ;
                                    valid_all[_req->source]       = 1                 ;
                                    //cout << "<inject> id: " << _req->id << " src: " << _req->source << " dst: " << _req->dest << " size: " << _req->size << endl;
                                }
                                else
                                {
                                    _inject_buffer.push(_req);
                                    //cout << "<wait> id: " << _req->id << endl;
                                }

                            }
                        }
                        //cout << "<end cycle>" << endl;

                        // fall-through and increment your network one cycle
                        process_more = false;
                       
                       break;
                    }
                case INJECT_REQ: //4
                    {
                        _req = (InjectReqMsg*) _msg;
                        _connection_manager->sendAckReqMsg(); 
                        noreq = 0;

                            //enqueue packets from synfull
                            _inject_buffer.push(_req);

                        //cout << "<inject> id:" << _req->id << " mt:" << _req->msgType << " ct:" << _req->coType 
                        //    << " src:" << _req->source << " dst:" << _req->dest << endl;

                        break;
                    }
                case EJECT_REQ:  //6
                    {
                        if(ejectReq == 1)
                        {
                            //cout << "\n*** EJECT_REQ *** " << endl;
                            for(int k=0; k<NE; k++)
                            {
                                if (rtrn_valid_all_[k] == 1){
                                    _res.id =  rtrn_pkgid_all[k];
                                    _eject_buffer.push(_res);
                                    rtrn_valid_all_[k] = 0;
                                }
                            }
                        }
                        else
                        {
                            _res.id = -1; //not pckage
                        }
                       
                        if (!_eject_buffer.empty()) {
                                _res = _eject_buffer.front();
                                _eject_buffer.pop();
                                _res.remainingRequests = _eject_buffer.size();
                                _connection_manager->sendResMsg();
                                //cout << "<eject> id:" << _res.id << endl;
                        }
                        else
                        {
                            _connection_manager->sendResMsg();
                        }
                         
                        break;
                    }
                case QUIT_REQ:
                    {
                        // acknowledge quit
                        QuitResMsg res;
                        *_channel << res;
                        
                        *endCom = '1'; 
                        
                        process_more = false;

                        break;
                    }
                default:
                    {
                        cout << "<ERROR:> Unknown message type: " << _msg->type << endl;
                        break;
                    }
            
            }
        }
        
        *newReq = msgDone     ;
        

        StreamMessage::destroy(_msg);
        
    }

}

//*****************************************************************
// Connection Manager
//*****************************************************************
connection_manager::connection_manager(){
    _channel = NULL;
    _sources = 4;
    _dests   = 4;
    _duplicate_networks = 1;
}

//--
int connection_manager::Init() {                            
    // Start listening for incoming connections
    if (_listenSocket.listen(NS_HOST, NS_PORT) < 0) {
        return -1;
    }
            
    // Waiting to connect
    _channel = _listenSocket.accept();
                                        
    cout << "Connected... " << endl;
                   
    // Initialize client
    InitializeReqMsg req;
    InitializeResMsg res;
    *_channel >> req << res;
                    
    return 0;
}

int connection_manager::readMsg() 
{    
    _msg = NULL;
    
    if (_channel) 
    {
        *_channel >> (StreamMessage*&) _msg;
    }
    return 0;
}

int connection_manager::sendResMsg() 
{   
    *_channel << _res;
    return 0;
}

int connection_manager::sendAckMsg() 
{   
    *_channel << _ackRes;
    return 0;
}

int connection_manager::sendAckReqMsg() 
{   
    *_channel << _ackReq;
    return 0;
}

int connection_manager::checkInjection(){
    return _newInjection;
}                            

int connection_manager::getPronocEndPoint(int node){
    return (node-(node%2))/2 ; 
}                            

int connection_manager::getSynfullEndPoint(int node){
    return (((node-(node%3))/3)*2)+!(node%3); 
}

int connection_manager::getMsgType(int opcode)
{
    int type;
    switch (opcode)
    {
        case 1: // readshared - read 
            type = 1; // req
            break;
        case 4: // compdata - data 
            type = 0; // req
            break;
        default:
            type = 2;
            break;
    }
    return type; 
}

int connection_manager::getChiOpc(int opcode, int type)
{
    int chiopc;
    switch (type)
    {
        case 1:
            switch (opcode)
            {
                case 1: // readshared - read 
                    chiopc = 1 ;
                    break; 
                default:
                    chiopc = 999;
                    cout << "(req) coherency message not supported" << endl;
                    break;
            }
            break;
        case 2:
            switch (opcode)
            {
                case 2: // compdata - data 
                    chiopc = 4;
                    break;
                case 5: // compack - unblock 
                    chiopc = 2;
                    break;
                default:
                    chiopc = 999;
                    cout << "(resp) coherency message not supported" << endl;
                    break;
            } 
            break;
        default:
            chiopc = 999;
            cout << "coherency message not supported" << endl;
            break;
    }
    return chiopc; 
}

//-------Debug functions Neiel-Leyva

int connection_manager::printResMsg(EjectResMsg res) {
    cout << "Debug Neiel: res.id                = " << res.id << endl;
    cout << "Debug Neiel: res.remainingRequests = " << res.remainingRequests << endl;
    cout << "Debug Neiel: res.source            = " << res.source << endl;
    cout << "Debug Neiel: res.destination       = " << res.dest << endl;
    cout << "Debug Neiel: req.packetSize        = " << res.packetSize   << endl;
    cout << "Debug Neiel: res.network           = " << res.network << endl;
    cout << "Debug Neiel: res.cl                = " << res.cl << endl;
    cout << "Debug Neiel: res.miss_prediction   = " << res.miss_pred << endl;
    return 0;
};

int connection_manager::printReqMsg(InjectReqMsg *req) {
    cout << "  " << endl;
    cout << "Debug Neiel: req.source     = " << req->source       << endl;
    cout << "Debug Neiel: req.dest       = " << req->dest         << endl;
    cout << "Debug Neiel: req.id         = " << req->id           << endl;
    cout << "Debug Neiel: req.packetSize = " << req->packetSize   << endl;
    cout << "Debug Neiel: req.network    = " << req->network      << endl;
    cout << "Debug Neiel: req.cl         = " << req->cl           << endl;
    cout << "Debug Neiel: req.msgType    = " << req->msgType      << endl; 
    cout << "Debug Neiel: req.coType     = " << req->coType       << endl; 
    cout << "Debug Neiel: req.address    = " << req->address      << endl; 
    return 0;                                                    
};



//*****************************************************************************
// SocketStream
//*****************************************************************************

int SocketStream::listen(const char *host, int port){
    
    char *socket_path = "./socket";
    
    // Create a socket
    if ( (so = socket(AF_UNIX, SOCK_STREAM, 0)) < 0) {
        cout << "Error creating socket." << endl;
        return -1;
    }
            
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, socket_path, sizeof(addr.sun_path)-1);
                  
    // Bind it to the listening port
    unlink(socket_path);
    if (bind(so, (struct sockaddr*)&addr, sizeof(addr)) != 0) {
         cout << "Error binding socket." << endl;
         return -1;
    }
    
    //// Listen for connections
    if (::listen(so, NS_MAX_PENDING) != 0) {
         cout << "Error listening on socket." << endl;
         return -1;
    }
    
    bIsAlive = true;
                    
#ifdef NS_DEBUG
    cout << "Listening on socket" << endl;
#endif
        
    return 0;
}

// accept a new connection
SocketStream* SocketStream::accept()
{
    struct sockaddr_un clientaddr;
    socklen_t clientaddrlen = sizeof clientaddr;
    int clientsock = ::accept(so, (struct sockaddr*)&clientaddr, &clientaddrlen);
    
    if ( clientsock < 0 ){
        cout << "Error accepting a connection";
        return NULL;
    }

    return new SocketStream(clientsock, (struct sockaddr*)&clientaddr, clientaddrlen);
}

int SocketStream::connect(const char *host, int port)
{
    char *socket_path = "./socket";
    // Create a socket.
    if ( (so = socket(AF_UNIX, SOCK_STREAM, 0)) < 0 ){
        cout << "Error creating socket." << endl;
        return -1;
    }
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, socket_path, sizeof(addr.sun_path)-1);

    // Connect to the server.
    if ( ::connect(so, (struct sockaddr*)&addr, sizeof(addr)) != 0) {
        cout << "Connection failed." << endl;
        return -1;
    }

    bIsAlive = true;

#ifdef NS_DEBUG
    cout << "Connected to host" << endl;
#endif

    return 0;
}

// read from the socket
int SocketStream::get(void *data, int number)
{

    int remaining = number;
    int received = 0;
    char *dataRemaining = (char*) data;

    errno = 0;
    while (remaining > 0 && (errno == 0 || errno == EINTR))
    {
        received = recv(so, dataRemaining, remaining, 0); // MSG_WAITALL
        if (received > 0)
        {
            dataRemaining += received;
            remaining -= received;
        }
    }

    return number - remaining;
}

// write to socket
int SocketStream::put(const void *data, int number)
{
    // MSG_NOSIGNAL prevents SIGPIPE signal from being generated on failed send
    return send(so, data, number, MSG_NOSIGNAL);
}


//*****************************************************************
//*****************************************************************


using namespace std;

SocketStream& operator<<(SocketStream& os, StreamMessage& msg)
{
#ifdef NS_DEBUG_EXTRA
    std::cout << "<MessageSend> Sending message: " << msg.type << ", size: " << msg.size << std::endl;
#endif

    // cork the connection
    int flag = 1;
    setsockopt (os.so, SOL_TCP, TCP_CORK, &flag, sizeof (flag));

    os.put(&(msg.size), sizeof(int));
    os.put(&msg, msg.size);

    // uncork the connection
    flag = 0;
    setsockopt (os.so, SOL_TCP, TCP_CORK, &flag, sizeof (flag));

    // os.flush();

    return os;
}

SocketStream& operator>>(SocketStream& is, StreamMessage*& msg)
{
#ifdef NS_DEBUG_EXTRA
    std::cout << "<MessageRecv> Waiting for message" << std::endl;
#endif

    int msgSize = -1;
    int gotBytes = is.get(&msgSize, sizeof(int));

    if (gotBytes != sizeof(int))
        return is;

    assert(msgSize > 0);

    msg = (StreamMessage*) malloc(msgSize);
    is.get(msg, msgSize);


#ifdef NS_DEBUG_EXTRA
    std::cout << "<MessageRecv> Got message: " << msg->type << std::endl;
#endif

    return is;
}

SocketStream& operator>>(SocketStream& is, StreamMessage& msg)
{
#ifdef NS_DEBUG_EXTRA
    std::cout << "<MessageRecvSync> Waiting for message" << std::endl;
#endif

    int msgSize = -1;
    int gotBytes = is.get(&msgSize, sizeof(int));

    if (gotBytes != sizeof(int))
        return is;

    assert(msgSize == msg.size);
    is.get(&msg, msgSize);

#ifdef NS_DEBUG_EXTRA
    std::cout << "<MessageRecvSync> Got message: " << msg.type << std::endl;
#endif

    return is;
}

void StreamMessage::destroy(StreamMessage* msg)
{
    assert (msg != NULL);
    free(msg);
}

