#ifndef LOCAL_COMPAT_NETINET_IN_H_
#define LOCAL_COMPAT_NETINET_IN_H_

#ifdef _WIN32
#ifndef _WIN32_WINNT
#define _WIN32_WINNT 0x0601
#endif
#include <winsock2.h>
#include <ws2tcpip.h>
#else
#include_next <netinet/in.h>
#endif

#endif
