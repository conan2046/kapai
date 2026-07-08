#ifndef LOCAL_WIN_COMPAT_H_
#define LOCAL_WIN_COMPAT_H_

#ifdef _WIN32
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <winsock2.h>
#include <windows.h>
#include <io.h>
#include <memory>
#include <string.h>
#include <time.h>

#ifndef R_OK
#define R_OK 4
#endif
#ifndef access
#define access _access
#endif
#ifndef bzero
#define bzero(ptr, size) memset((ptr), 0, (size))
#endif
#ifndef strtok_r
#define strtok_r strtok_s
#endif
typedef unsigned long in_addr_t;

static inline unsigned int sleep(unsigned int sec)
{
	Sleep(sec * 1000);
	return 0;
}

struct timezone;
static inline int local_gettimeofday(struct timeval *tv, struct timezone *)
{
	if(tv == NULL)
		return -1;
	FILETIME ft;
	GetSystemTimeAsFileTime(&ft);
	unsigned long long t = ((unsigned long long)ft.dwHighDateTime << 32) | ft.dwLowDateTime;
	t -= 116444736000000000ULL;
	tv->tv_sec = (long)(t / 10000000ULL);
	tv->tv_usec = (long)((t % 10000000ULL) / 10);
	return 0;
}

template<class T>
using auto_ptr = std::unique_ptr<T>;
#endif

#endif
