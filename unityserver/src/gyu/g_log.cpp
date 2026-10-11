#include "g_log.h"
#include "g_utility.h"

namespace gyu {
namespace log {

bool CLogs::SetLogFileName(std::string &name)
{
	if(m_pFile != NULL)
		fclose(m_pFile);
	m_pFile = fopen(name.c_str(), "a+");
	return m_pFile != NULL;
}

void CLogs::WriteLog(const char *fmt, ...)
{
	FILE *out = m_pFile ? m_pFile : stdout;
	fprintf(out, "[%s] ", gyu::util::GetCurTimeString().c_str());
	va_list ap;
	va_start(ap, fmt);
	vfprintf(out, fmt, ap);
	va_end(ap);
	fprintf(out, "\n");
	fflush(out);
}

}
}
