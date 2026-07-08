#ifndef LOCAL_COMPAT_UNISTD_H_
#define LOCAL_COMPAT_UNISTD_H_

#ifdef _WIN32
#ifndef R_OK
#define R_OK 4
#endif
#ifndef access
#define access _access
#endif
#endif

#endif
