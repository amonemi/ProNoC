/*
 * message.cpp
 *
 *  Created on: Dec 13, 2009
 *      Author: sam
 */

#include "messages.h"
#include <cassert>
#include <cstdlib>

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

    //std::cout << "Debug: " << msgSize << " " << msg.size << std::endl;
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

