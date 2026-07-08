#ifndef LOCAL_COMPAT_SYS_TIME_H_
#define LOCAL_COMPAT_SYS_TIME_H_

#ifdef _WIN32
#ifndef _WIN32_WINNT
#define _WIN32_WINNT 0x0601
#endif
#include <winsock2.h>
#else
#include_next <sys/time.h>
#endif

#endif
