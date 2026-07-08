#ifndef LOCAL_COMPAT_BOOST_FORMAT_HPP_
#define LOCAL_COMPAT_BOOST_FORMAT_HPP_

#include <sstream>
#include <string>

namespace boost {
	class format
	{
	public:
		format() {}
		format(const char *fmt):m_fmt(fmt ? fmt : "") {}
		format(const std::string &fmt):m_fmt(fmt) {}

		format &operator=(const char *fmt)
		{
			m_fmt = fmt ? fmt : "";
			return *this;
		}

		format &operator=(const std::string &fmt)
		{
			m_fmt = fmt;
			return *this;
		}

		format &parse(const char *fmt)
		{
			m_fmt = fmt ? fmt : "";
			return *this;
		}

		format &parse(const std::string &fmt)
		{
			m_fmt = fmt;
			return *this;
		}

		template<typename T>
		format &operator%(const T &value)
		{
			std::ostringstream ss;
			ss << value;
			replace_next(ss.str());
			return *this;
		}

		std::string str() const
		{
			return m_fmt;
		}

	private:
		void replace_next(const std::string &value)
		{
			size_t best = std::string::npos;
			size_t bestLen = 0;
			for(size_t i = 1; i <= 64; ++i)
			{
				std::string key = "%" + std::to_string(i) + "%";
				size_t pos = m_fmt.find(key);
				if(pos != std::string::npos && (best == std::string::npos || pos < best))
				{
					best = pos;
					bestLen = key.size();
				}
			}
			if(best != std::string::npos)
				m_fmt.replace(best, bestLen, value);
		}

	private:
		std::string m_fmt;
	};

	inline std::ostream &operator<<(std::ostream &os, const format &fmt)
	{
		os << fmt.str();
		return os;
	}
}

#endif
