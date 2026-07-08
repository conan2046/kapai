#ifndef LOCAL_COMPAT_BOOST_XPRESSIVE_DYNAMIC_HPP_
#define LOCAL_COMPAT_BOOST_XPRESSIVE_DYNAMIC_HPP_

#include <regex>

namespace boost {
	namespace xpressive {
		class cregex
		{
		public:
			static cregex compile(const char *pattern)
			{
				return cregex(pattern ? pattern : "");
			}

			const std::regex &native() const
			{
				return m_regex;
			}

		private:
			cregex(const char *pattern):m_regex(pattern) {}
			std::regex m_regex;
		};

		inline bool regex_match(const char *value, const cregex &reg)
		{
			return value != NULL && std::regex_match(value, reg.native());
		}
	}
}

#endif
