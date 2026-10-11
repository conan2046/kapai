#ifndef LOCAL_COMPAT_SYS_SOCKET_H_
#define LOCAL_COMPAT_SYS_SOCKET_H_

#ifdef _WIN32
#ifndef _WIN32_WINNT
#define _WIN32_WINNT 0x0601
#endif
#include <winsock2.h>
#include <ws2tcpip.h>

typedef int socklen_t;

#ifndef SHUT_RD
#define SHUT_RD SD_RECEIVE
#endif
#ifndef SHUT_WR
#define SHUT_WR SD_SEND
#endif
#ifndef SHUT_RDWR
#define SHUT_RDWR SD_BOTH
#endif

#ifndef close
#define close closesocket
#endif

#else
#include_next <sys/socket.h>
#endif

#endif
