/*
 * socketstream.h
 *
 *  Created on: Dec 14, 2009
 *      Author: sam
 */

#ifndef SOCKETSTREAM_H_
#define SOCKETSTREAM_H_

#include <iostream>

#include <unistd.h>
#include <sys/types.h>
#include <sys/un.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <netinet/tcp.h>

#include <cstring>

#define NS_DEBUG
// #define NS_DEBUG_EXTRA
#define NS_MAX_PENDING 1
#define NS_HOST "local"
#define NS_PORT 0

using namespace std;

class SocketStream
{
public:
	int so; // the socket
	struct sockaddr_un addr;
	bool bIsAlive;

public:

	SocketStream() : so(-1), bIsAlive(false)
	{
	}

	// create from an existing socket
	SocketStream(int sock) : so(sock), bIsAlive(true)
	{
	}

	~SocketStream()
	{
		if (so != -1)
		{
			close(so);
		}
	}

	SocketStream(int sock, struct sockaddr *in_addr, socklen_t in_addrlen)
	{
		so = sock;
		bIsAlive = true;
		memcpy(&addr, in_addr, in_addrlen);
	}

	int listen(const char *host, int port);

	SocketStream* accept();

	int connect(const char *host, int port);

    // read from the socket
    int get(void *data, int number);

    // write to socket
    int put(const void *data, int number);

	bool isAlive()
	{
		return bIsAlive;
	}

};

#endif /* SOCKETSTREAM_H_ */
