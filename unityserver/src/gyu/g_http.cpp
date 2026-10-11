#include "g_http.h"

namespace gyu {
namespace net {

bool RunHttpGet(std::string &, std::string &ret, bool)
{
	ret.clear();
	return false;
}

bool RunHttpPost(std::string &, std::string &, std::string &ret, bool)
{
	ret.clear();
	return false;
}

}
}
