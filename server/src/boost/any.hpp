#ifndef LOCAL_COMPAT_BOOST_ANY_HPP_
#define LOCAL_COMPAT_BOOST_ANY_HPP_

#include <any>

namespace boost {
	using std::any_cast;
	using std::bad_any_cast;

	class any : public std::any
	{
	public:
		any() {}
		any(const any &other):std::any(other) {}
		any(any &&other) noexcept:std::any(std::move(other)) {}

		template<typename T>
		any(const T &value):std::any(value) {}

		any &operator=(const any &other)
		{
			std::any::operator=(static_cast<const std::any &>(other));
			return *this;
		}

		any &operator=(any &&other) noexcept
		{
			std::any::operator=(static_cast<std::any &&>(other));
			return *this;
		}

		bool empty() const
		{
			return !has_value();
		}
	};
}

#endif
