#include "call_script.h"
#include <lua.hpp>
#include <iostream>
#include <string>
#include "user.h"
#include "fight.h"
#include "swigluarun.h"
#include "pack_deal.h"

using namespace std;

boost::mutex sScriptMutex;
static CHashTable<int,CCallScript*> sScriptHash(1024);

static void AddScript(int scriptId,CCallScript *pScript)
{
	boost::mutex::scoped_lock lk(sScriptMutex);
	sScriptHash.Insert(scriptId,pScript);
}

CCallScript *FindScript(int scriptId)
{
	CCallScript *pScript = NULL;
	{
		boost::mutex::scoped_lock lk(sScriptMutex);
		sScriptHash.Find(scriptId,pScript);
	}
	if(pScript == NULL)
	{
		char buf[256];
		snprintf(buf,sizeof(buf),"%s%d.lua",GetScriptDir(),scriptId);
		if(access(buf,R_OK) == 0)
		{
			pScript = new CCallScript(scriptId);
		}
	}
	return pScript;
}

CCallScript::CCallScript(int scriptId)
{
	m_scriptId = scriptId;
	m_pLuaState = luaL_newstate();
	luaL_openlibs(m_pLuaState);
	luaopen_j(m_pLuaState);
	lua_gc(m_pLuaState,LUA_GCSETPAUSE,100);
	lua_gc(m_pLuaState,LUA_GCSETSTEPMUL,5000);

	const char *pScriptDir = GetScriptDir();
	if(pScriptDir != NULL && strlen(pScriptDir) > 0)
	{
		char path[128];
		snprintf(path,sizeof(path),"%s/?.lua",GetScriptDir());
		AddPath("path",path);
	}
	
	char script[256];
	snprintf(script,sizeof(script),"%s%d.lua",GetScriptDir(),scriptId);
	if((luaL_loadfile(m_pLuaState,script) != 0)
		|| (lua_pcall(m_pLuaState,0,0,0) != 0))
	{
		cout << lua_tostring(m_pLuaState, -1)<<endl; 
	}
	AddScript(scriptId,this);
}

void CCallScript::ReLoad()
{
	char script[256];
	snprintf(script,sizeof(script),"%s%d.lua",GetScriptDir(),m_scriptId);
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if((luaL_loadfile(m_pLuaState,script) != 0)
		|| (lua_pcall(m_pLuaState,0,0,0) != 0))
	{
		cout << lua_tostring(m_pLuaState, -1)<<endl; 
	}
}

CCallScript::~CCallScript()
{
	//boost::recursive_mutex::scoped_lock lk(sScriptMutex);
	lua_close(m_pLuaState);
	m_pLuaState = NULL;
}

bool PushPointer(lua_State*L, void* ptr, const char* type_name, int owned = 0) 
{
	if(type_name != NULL && strcmp(type_name, "CUser *") == 0)
	{
		void **ud = static_cast<void **>(lua_newuserdata(L, sizeof(void *)));
		*ud = ptr;
		luaL_getmetatable(L, "CUser *");
		if(lua_istable(L, -1))
			lua_setmetatable(L, -2);
		else
			lua_pop(L, 1);
		return true;
	}
	// task 1: get the object 'type' which is registered with SWIG
	// you need to call SWIG_TypeQuery() with the class name
	// (normally, just look in the wrapper file to get this)
	swig_type_info * pTypeInfo = SWIG_TypeQuery(L, type_name);
	if (pTypeInfo == 0)
		return false;   // error
	// task 2: push the pointer to the Lua stack
	// this requires a pointer & the type
	// the last param specifies if Lua is responsible for deleting the object
	SWIG_NewPointerObj(L, ptr, pTypeInfo, owned);
	return true;
}

void CCallScript::NoLockCall(const char *func,ArgList *pIn,ArgList *pOut)
{
	lua_settop(m_pLuaState,0);

	lua_getglobal(m_pLuaState, func);  /* get function */

	int narg = 0, nres = 0;
	if(pIn != NULL)
	{
		ArgList::iterator i = pIn->begin();
		for(; i != pIn->end(); i++)
		{
			boost::any &in = *i;
			if(in.type() == typeid(int))
			{
				narg++;
				lua_pushnumber(m_pLuaState, boost::any_cast<int>(in));
			}
			else if(in.type() == typeid(string))
			{
				narg++;
				lua_pushstring(m_pLuaState, (boost::any_cast<string>(in)).c_str());
			}
			else if(in.type() == typeid(CUser*))
			{
				narg++;
				PushPointer(m_pLuaState,boost::any_cast<CUser*>(in),"CUser *");
			}
			else if(in.type() == typeid(CFight*))
			{
				narg++;
				PushPointer(m_pLuaState,boost::any_cast<CFight*>(in),"CFight *");
			}
		}
	}

	if(pOut != NULL)
	{
		nres = pOut->size();
		nres = -nres;
		ArgList::iterator i = pOut->begin();
		for(; i != pOut->end(); i++)
		{
			boost::any &in = *i;
			if(in.type() == typeid(int*))
			{
				if (!lua_isnumber(m_pLuaState, nres))
				{
					cout<<m_scriptId<<" wrong result type"<<endl;
					return;
				}
				*(boost::any_cast<int*>(in)) = (int)lua_tonumber(m_pLuaState, nres);
				nres++;
			}
			else if(in.type() == typeid(char**))
			{
				if (!lua_isstring(m_pLuaState, nres))
				{
					cout<<m_scriptId<<" wrong result type"<<endl;
					return;
				}
				*(boost::any_cast<char**>(in)) = (char*)lua_tostring(m_pLuaState, nres);
				nres++;
			}
		}
	}

	if (lua_pcall(m_pLuaState, narg, nres,0) != 0)  
	{
		cout <<"call:"<<m_scriptId<<" "<<func<<" "<<lua_tostring(m_pLuaState, -1)<<endl; 
		return;
	}
}

void CCallScript::Call(const char *func,ArgList *pIn,ArgList *pOut)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	NoLockCall(func,pIn,pOut);
}

void CCallScript::Call(const char *func, const char *fmt, ...)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	va_list vl;
	va_start(vl, fmt);
	CallVa(func,fmt,vl);
	va_end(vl);
}

void CCallScript::AddPath(const char *name,const char *newPath)
{
	string v;

	lua_getglobal(m_pLuaState,"package");
	lua_getfield(m_pLuaState,-1,name);
	v.append(lua_tostring(m_pLuaState,-1));
	v.append(";");
	v.append(newPath);
	lua_pushstring(m_pLuaState,v.c_str());
	lua_setfield(m_pLuaState,-3,name);
	lua_pop(m_pLuaState,2);
}

void CCallScript::CallVa(const char *func,const char *fmt,va_list vl)
{
	int narg, nres;  /* number of arguments and results */

	lua_settop(m_pLuaState,0);
	//int top = lua_gettop(m_pLuaState);
	lua_getglobal(m_pLuaState, func);  /* get function */

	/*if(!lua_isfunction(m_pLuaState,-1))
	{
	cout << lua_tostring(m_pLuaState, -1)<<endl; 
	return;
	}*/

	/* push arguments */
	narg = 0;
	while (*fmt) {  /* push arguments */
		switch (*fmt++) {

		case 'd':  /* double argument */
			lua_pushnumber(m_pLuaState, va_arg(vl, int));
			break;

		case 'i':  /* int argument */
			lua_pushnumber(m_pLuaState, va_arg(vl, int));
			break;

		case 's':  /* string argument */
			lua_pushstring(m_pLuaState, va_arg(vl, char *));
			break;

		case 'u':
			if(!PushPointer(m_pLuaState,va_arg(vl,void*),"CUser *"))
				cout<<"push CUser error"<<endl;
			break;
		case 'f':
			if(!PushPointer(m_pLuaState,va_arg(vl,void*),"CFight *"))
				cout<<"push CUser error"<<endl;
			break;  
		case '>':
			goto endwhile;

		default:
			cout<<"invalid option "<<*(fmt - 1)<<endl;
		}
		narg++;
		luaL_checkstack(m_pLuaState, 1, "too many arguments");
	}
endwhile:

	/* do the call */
	nres = strlen(fmt);  /* number of expected results */

	if (lua_pcall(m_pLuaState, narg, nres,0) != 0)  /* do the call */
	{
		cout <<"call:"<<m_scriptId<<" "<<func<<" "<<lua_tostring(m_pLuaState, -1)<<endl; 
		return;
	}

	/* retrieve results */
	nres = -nres;  /* stack index of first result */
	while (*fmt) {  /* get results */
		switch (*fmt++) {

		case 'd':  /* double result */
			if (!lua_isnumber(m_pLuaState, nres))
			{
				cout <<"call:"<<m_scriptId<<" "<<func<<endl; 
				return;
			}
			*va_arg(vl, double *) = lua_tonumber(m_pLuaState, nres);
			break;

		case 'i':  /* int result */
			if (!lua_isnumber(m_pLuaState, nres))
			{
				cout <<"call:"<<m_scriptId<<" "<<func<<endl; 
				return;
			}
			*va_arg(vl, int *) = (int)lua_tonumber(m_pLuaState, nres);
			break;

		case 's':  /* string result */
			if (!lua_isstring(m_pLuaState, nres))
			{
				cout <<"call:"<<m_scriptId<<" "<<func<<endl; 
				return;
			}
			*va_arg(vl, const char **) = lua_tostring(m_pLuaState, nres);
			break;

		default:
			cout<<"invalid option (%c)"<<*(fmt - 1)<<endl;
		}
		nres++;
	}

	//lua_settop(m_pLuaState,top);
}
