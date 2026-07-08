#ifndef _GYU_HTTP_H_
#define _GYU_HTTP_H_

#include <string>

namespace gyu {
	namespace net {
		bool RunHttpGet(std::string &url, std::string &ret, bool ishttps=false);
		bool RunHttpPost(std::string &url, std::string &postData, std::string &ret, bool ishttps=false);
	}
}

#endif

