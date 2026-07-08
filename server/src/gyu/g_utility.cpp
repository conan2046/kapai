#include "g_utility.h"
#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <cctype>
#include <ctime>
#include <iomanip>
#include <sstream>
#include <string.h>
#include <signal.h>
#include <vector>

#ifndef __has_include
#define __has_include(x) 0
#endif

#if __has_include(<zlib.h>)
#include <zlib.h>
#define GYU_HAS_ZLIB 1
#endif

#if __has_include(<openssl/md5.h>)
#include <openssl/md5.h>
#define GYU_HAS_OPENSSL_MD5 1
#endif

#ifdef _WIN32
#ifndef _WIN32_WINNT
#define _WIN32_WINNT 0x0601
#endif
#include <winsock2.h>
#include <windows.h>

static int gettimeofday(timeval *tv, void *)
{
	if(tv == NULL)
		return -1;
	FILETIME ft;
	GetSystemTimeAsFileTime(&ft);
	unsigned long long ticks = ((unsigned long long)ft.dwHighDateTime << 32) | ft.dwLowDateTime;
	unsigned long long us = ticks / 10 - 11644473600000000ULL;
	tv->tv_sec = (long)(us / 1000000ULL);
	tv->tv_usec = (long)(us % 1000000ULL);
	return 0;
}
#else
#include <unistd.h>
#endif

namespace gyu {
namespace util {

TimePrint::TimePrint(std::string str,int sock)
	:m_str(str), m_sock(sock)
{
	local_gettimeofday(&m_time, NULL);
}

TimePrint::~TimePrint()
{
	timeval now;
	local_gettimeofday(&now, NULL);
	long usec = (now.tv_sec - m_time.tv_sec) * 1000000L + (now.tv_usec - m_time.tv_usec);
	if(usec > 100000)
		printf("[TimePrint]%s sock=%d cost=%ldus\n", m_str.c_str(), m_sock, usec);
}

std::string GetCurTimeString()
{
	time_t t = time(NULL);
	tm *lt = localtime(&t);
	char buf[64];
	if(lt == NULL)
		return "";
	snprintf(buf, sizeof(buf), "%04d-%02d-%02d %02d:%02d:%02d",
		lt->tm_year + 1900, lt->tm_mon + 1, lt->tm_mday, lt->tm_hour, lt->tm_min, lt->tm_sec);
	return buf;
}

bool SetSignal(void(*sigHandler)(int), void(*sigCoreHandler)(int))
{
	if(sigHandler != NULL)
	{
		signal(SIGINT, sigHandler);
		signal(SIGTERM, sigHandler);
	}
#ifndef _WIN32
	if(sigCoreHandler != NULL)
	{
		signal(SIGSEGV, sigCoreHandler);
		signal(SIGABRT, sigCoreHandler);
	}
#endif
	return true;
}

void SetDaemon()
{
#ifndef _WIN32
	daemon(1, 0);
#endif
}

int StrToHex(const char *str,unsigned char *pHex,int hexLen)
{
	if(str == NULL || pHex == NULL || hexLen <= 0)
		return 0;
	int len = 0;
	while(str[0] && str[1] && len < hexLen)
	{
		unsigned int v = 0;
		sscanf(str, "%02x", &v);
		pHex[len++] = (unsigned char)v;
		str += 2;
	}
	return len;
}

void HexToStr(unsigned char *pHex,int hexLen,std::string &str)
{
	static const char *hex = "0123456789abcdef";
	str.clear();
	for(int i = 0; i < hexLen; ++i)
	{
		str.push_back(hex[(pHex[i] >> 4) & 0x0f]);
		str.push_back(hex[pHex[i] & 0x0f]);
	}
}

bool SplitString(const std::string & src, std::vector<std::string>& vec, char ch)
{
	vec.clear();
	std::string cur;
	for(size_t i = 0; i < src.size(); ++i)
	{
		if(src[i] == ch)
		{
			vec.push_back(cur);
			cur.clear();
		}
		else
			cur.push_back(src[i]);
	}
	vec.push_back(cur);
	return true;
}

int Random(int min,int max)
{
	if(max <= min)
		return min;
	return min + rand() % (max - min + 1);
}

bool RandomSequence(int *array,int arrayLen,int max)
{
	if(array == NULL || arrayLen < 0 || max < arrayLen)
		return false;
	std::vector<int> pool;
	pool.reserve(max);
	for(int i = 0; i < max; ++i)
		pool.push_back(i);
	for(int i = 0; i < arrayLen; ++i)
	{
		int idx = Random(i, max - 1);
		std::swap(pool[i], pool[idx]);
		array[i] = pool[i];
	}
	return true;
}

void MD5String(std::string &str)
{
#ifdef GYU_HAS_OPENSSL_MD5
	unsigned char digest[MD5_DIGEST_LENGTH];
	MD5((const unsigned char*)str.data(), str.size(), digest);
	HexToStr(digest, MD5_DIGEST_LENGTH, str);
#else
	unsigned long h = 5381;
	for(size_t i = 0; i < str.size(); ++i)
		h = ((h << 5) + h) + (unsigned char)str[i];
	char buf[33];
	snprintf(buf, sizeof(buf), "%032lx", h);
	str = buf;
#endif
}

std::string Base64Decode(std::string src)
{
	static const std::string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	std::string out;
	int val = 0;
	int valb = -8;
	for(size_t i = 0; i < src.size(); ++i)
	{
		unsigned char c = (unsigned char)src[i];
		if(isspace(c))
			continue;
		if(c == '=')
			break;
		size_t pos = chars.find(c);
		if(pos == std::string::npos)
			continue;
		val = (val << 6) + (int)pos;
		valb += 6;
		if(valb >= 0)
		{
			out.push_back(char((val >> valb) & 0xff));
			valb -= 8;
		}
	}
	return out;
}

static int copy_convert(char *to,size_t toLen,char *from,size_t fromLen)
{
	if(to == NULL || from == NULL || toLen == 0)
		return 0;
	size_t n = std::min(toLen - 1, fromLen);
	memcpy(to, from, n);
	to[n] = 0;
	return (int)n;
}

int UTF8ToUnicode(char *to,size_t toLen,char *from,size_t fromLen) { return copy_convert(to,toLen,from,fromLen); }
int UnicodeToUTF8(char *to,size_t toLen,char *from,size_t fromLen) { return copy_convert(to,toLen,from,fromLen); }
int GbkToUnicode(char *to,size_t toLen,char *from,size_t fromLen) { return copy_convert(to,toLen,from,fromLen); }
int UnicodeToGbk(char *to,size_t toLen,char *from,size_t fromLen) { return copy_convert(to,toLen,from,fromLen); }
int GbkToUTF8(char *to,size_t toLen,char *from,size_t fromLen) { return copy_convert(to,toLen,from,fromLen); }
int UTF8ToGbk(char *to,size_t toLen,char *from,size_t fromLen) { return copy_convert(to,toLen,from,fromLen); }

int UnHexify(unsigned char *obuf, const char *ibuf)
{
	return StrToHex(ibuf, obuf, (int)strlen(ibuf) / 2);
}

void Hexify(unsigned char *obuf, const unsigned char *ibuf, int len)
{
	static const char *hex = "0123456789abcdef";
	for(int i = 0; i < len; ++i)
	{
		obuf[i * 2] = hex[(ibuf[i] >> 4) & 0x0f];
		obuf[i * 2 + 1] = hex[ibuf[i] & 0x0f];
	}
	obuf[len * 2] = 0;
}

bool Compress(unsigned char *pInBuf,unsigned int inLen,std::string &out)
{
#ifdef GYU_HAS_ZLIB
	if(pInBuf == NULL)
		return false;
	uLongf bound = compressBound(inLen);
	std::string tmp;
	tmp.resize(bound);
	if(compress((Bytef*)&tmp[0], &bound, (Bytef*)pInBuf, inLen) != Z_OK)
		return false;
	tmp.resize(bound);
	out.resize(bound * 2 + 1);
	Hexify((unsigned char*)&out[0], (const unsigned char*)tmp.data(), (int)bound);
	out.resize(bound * 2);
	return true;
#else
	out.assign((const char*)pInBuf, inLen);
	return true;
#endif
}

bool UnCompress(const char *inStr, unsigned char *pOutBuf, unsigned int &outLen)
{
#ifdef GYU_HAS_ZLIB
	if(inStr == NULL || pOutBuf == NULL)
		return false;
	std::string bin;
	bin.resize(strlen(inStr) / 2 + 1);
	int len = UnHexify((unsigned char*)&bin[0], inStr);
	uLongf destLen = outLen;
	int ret = uncompress((Bytef*)pOutBuf, &destLen, (Bytef*)bin.data(), len);
	outLen = (unsigned int)destLen;
	return ret == Z_OK;
#else
	size_t len = strlen(inStr);
	if(len > outLen)
		return false;
	memcpy(pOutBuf, inStr, len);
	outLen = (unsigned int)len;
	return true;
#endif
}

int UnCompressEx(const char *inStr, unsigned char *pOutBuf, unsigned int outLen)
{
	unsigned int len = outLen;
	if(!UnCompress(inStr, pOutBuf, len))
		return -1;
	return (int)len;
}

}
}
