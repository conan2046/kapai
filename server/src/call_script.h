#ifndef _CALL_SCRIPT_H_
#define _CALL_SCRIPT_H_
#include <lua.hpp>
#include <list>
#include <boost/any.hpp>
#include <boost/thread.hpp>
extern "C" int luaopen_j(lua_State*);

typedef std::list<boost::any> ArgList;

class CCallScript
{
public:
	CCallScript(int scriptId);
	//`d′ for double, `i′ for integer, and `s′ for strings
	//'u' for CUser*,'f' for CFight* 
	//`>′ separates arguments from the results
	void Call(const char *func, const char *fmt, ...);
	void Call(const char *func,ArgList *pIn,ArgList *pOut = NULL);
	void AddPath(const char *name,const char *newPath);
	int GetScriptId()
	{
		return m_scriptId;
	}
	void ReLoad();
private:
	~CCallScript();
	int m_scriptId;
	void CallVa(const char *func,const char *fmt,va_list vl);
	void NoLockCall(const char *func,ArgList *pIn,ArgList *pOut);
	lua_State *m_pLuaState;
	//boost::mutex m_mutex;
	boost::recursive_mutex m_mutex;
};

CCallScript *FindScript(int scriptId);

#endif


