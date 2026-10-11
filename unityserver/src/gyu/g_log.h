#ifndef _GYU_LOG_FILE_H_
#define _GYU_LOG_FILE_H_

#include <iostream>
#include <stdarg.h>
#include <stdio.h>
#include <string>

namespace gyu {
	namespace log {
		class CLogs
		{
		public:
			CLogs():m_pFile(NULL){}
			~CLogs()
			{
				if(m_pFile != NULL)
					fclose(m_pFile);
			}
			bool SetLogFileName(std::string &);
			void WriteLog(const char *fmt, ...);

		private:
			FILE *m_pFile;
		};
	}
}

#endif
