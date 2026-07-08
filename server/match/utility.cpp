#include "utility.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <boost/format.hpp>
#include <boost/scoped_array.hpp>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include "singleton.h"
#include "main.h"

static time_t sSysTime;
static time_t msSysTime;
static int g_yday = -1;	// 0~365
static int g_wday = -1;	// 0~6 周日~周一
static int g_year = -1;	// 1900开始
static int g_month = -1;// 0~11 1~12月
static int g_mday = -1;	// 1~31
static int g_hour = -1;	// 0~23
static int g_minute = -1;// 0~59
static int g_second = -1;// 0~59

void SetSysYDay(int t)
{
	g_yday = t;
}

int GetSysYDay()
{
	return g_yday;
}

void SetSysWDay(int t)
{
	g_wday = t;
}

int GetSysWDay()
{
	return g_wday;
}

void SetSysYear(int t)
{
	g_year = t;
}

int GetSysYear()
{
	return g_year;
}

void SetSysMonth(int t)
{
	g_month = t;
}

int GetSysMonth()
{
	return g_month;
}

void SetSysMDay(int t)
{
	g_mday = t;
}

int GetSysMDay()
{
	return g_mday;
}

void SetSysHour(int t)
{
	g_hour = t;
}

int GetSysHour()
{
	return g_hour;
}

void SetSysMinute(int t)
{
	g_minute = t;
}

int GetSysMinute()
{
	return g_minute;
}

void SetSysSecond(int t)
{
	g_second = t;
}

int GetSysSecond()
{
	return g_second;
}

void SetSysTime(time_t t)
{
	sSysTime = t;
}

time_t GetSysTime()
{
	return sSysTime;
}

void SetSysTimeMs(time_t t)
{
	msSysTime = t;
}

time_t GetSysTimeMs()
{
	return msSysTime;
}

uint32 GetTomorrowMillsec()
{
	time_t now = time(0);
	tm* tmNow = localtime(&now);
	tmNow->tm_hour = 23;
	tmNow->tm_min = 59;
	tmNow->tm_sec = 59;
	time_t tomorrow = mktime(tmNow);
	return static_cast<uint32>(tomorrow - now + 1000);
}

int GetMinute()
{
	return GetSysMinute();
}

int GetHour()
{
	return GetSysHour();
}

int GetYDay()
{
	return GetSysYDay();
}

int GetWeekDay()
{
	return GetSysWDay();
}

int GetDay()
{
	return GetSysMDay();
}

int GetMonth()
{
	return GetSysMonth();
}

int GetYear()
{
	return GetSysYear();
}

int GetMonthDayNum()
{
	int day[12] = { 31,28,31,30,31,30,31,31,30,31,30,31 };
	int month = GetMonth();
	int year = GetYear() + 1900;
	if (month != 1)
	{
		return day[month];
	}
	else
	{
		if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0))
			return 29;
		else
			return 28;
	}
}

time_t sClearWeekTime = 0;
time_t sClearMonthTime = 0;
time_t sClearDayTime = 0;

void SetClearDayTime(time_t t)
{
	sClearDayTime = t;
}

time_t GetClearDayTime()
{
	return sClearDayTime;
}

void SetClearWeekTime(time_t t)
{
	sClearWeekTime = t;
}

time_t GetClearWeekTime()
{
	return sClearWeekTime;
}

void SetClearMonthTime(time_t t)
{
	sClearMonthTime = t;
}

time_t GetClearMonthTime()
{
	return sClearMonthTime;
}

int UTF8ToUnicode(char *to, size_t toLen, char *from, size_t fromLen)
{
	static iconv_t sCdGbkUnicode = iconv_open("UNICODELITTLE", "UTF-8");
	size_t oldToLen = toLen;
	iconv(sCdGbkUnicode, &from, &fromLen, &to, &toLen);
	return (oldToLen - toLen);
}

int UnicodeToUTF8(char *to, size_t toLen, char *from, size_t fromLen)
{
	static iconv_t sCdUnicodeGbk = iconv_open("UTF-8", "UNICODELITTLE");
	size_t oldToLen = toLen;
	iconv(sCdUnicodeGbk, &from, &fromLen, &to, &toLen);
	return (oldToLen - toLen);
}

int GbkToUnicode(char *to, size_t toLen, char *from, size_t fromLen)
{
	static iconv_t sCdGbkUnicode = iconv_open("UNICODELITTLE", "GBK");
	size_t oldToLen = toLen;
	iconv(sCdGbkUnicode, &from, &fromLen, &to, &toLen);
	return (oldToLen - toLen);
}

int UnicodeToGbk(char *to, size_t toLen, char *from, size_t fromLen)
{
	static iconv_t sCdUnicodeGbk = iconv_open("GBK", "UNICODELITTLE");
	size_t oldToLen = toLen;
	iconv(sCdUnicodeGbk, &from, &fromLen, &to, &toLen);
	return (oldToLen - toLen);
}

int GbkToUTF8(char *to, size_t toLen, char *from, size_t fromLen)
{
	static iconv_t sCdGbkUnicode = iconv_open("UTF-8", "GBK");
	size_t oldToLen = toLen;
	iconv(sCdGbkUnicode, &from, &fromLen, &to, &toLen);
	return (oldToLen - toLen);
}

int UTF8ToGbk(char *to, size_t toLen, char *from, size_t fromLen)
{
	static iconv_t sCdUnicodeGbk = iconv_open("GBK", "UTF-8");
	size_t oldToLen = toLen;
	iconv(sCdUnicodeGbk, &from, &fromLen, &to, &toLen);
	return (oldToLen - toLen);
}

int Random(int min, int max)
{
	if (min >= max)
		return min;
	if (max - min + 1 == 0)
		return 0;
	int t = rand();
	int r = rand();
	for (int i = 0; i < t % 7; i++)
		r = rand();
	t = rand();
	for (int i = 0; i < t % 5; i++)
		r = rand();
	r %= (max - min + 1);
	return r + min;
}

string IntToStr(int value)
{
	string res;
	char buf[128];
	snprintf(buf,sizeof(buf),"%d",value);
	res = buf;
	return res;
}
