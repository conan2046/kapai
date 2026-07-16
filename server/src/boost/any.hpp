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
		// Cast to the base explicitly.  Passing boost::any directly lets
		// std::any's value constructor win overload resolution, so it tries to
		// store another boost::any and recursively invokes this constructor.
		any(const any &other):std::any(static_cast<const std::any &>(other)) {}
		any(any &&other) noexcept:std::any(static_cast<std::any &&>(other)) {}

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
