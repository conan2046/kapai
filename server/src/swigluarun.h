#ifndef LOCAL_COMPAT_SWIGLUARUN_H_
#define LOCAL_COMPAT_SWIGLUARUN_H_

struct swig_type_info {
	const char *name;
};

static inline swig_type_info *SWIG_TypeQuery(lua_State *, const char *type_name)
{
	static swig_type_info info;
	info.name = type_name;
	return &info;
}

static inline void SWIG_NewPointerObj(lua_State *L, void *ptr, swig_type_info *type, int)
{
	void **ud = static_cast<void **>(lua_newuserdata(L, sizeof(void *)));
	*ud = ptr;
	if(type != 0 && type->name != 0)
	{
		luaL_getmetatable(L, type->name);
		if(lua_istable(L, -1))
			lua_setmetatable(L, -2);
		else
			lua_pop(L, 1);
	}
}

#endif
