#ifndef _UTILITY_H_
#define _UTILITY_H_
#include <iconv.h>
#include <string>
#include <vector>
#include <list>
#include "self_typedef.h"

#define ISSPACE(c) isspace((unsigned char)(c))

using namespace std;

void SetSysYDay(int t);
int GetSysYDay();
void SetSysWDay(int t);
int GetSysWDay();
void SetSysYear(int t);
int GetSysYear();
void SetSysMonth(int t);
int GetSysMonth();
void SetSysMDay(int t);
int GetSysMDay();
void SetSysHour(int t);
int GetSysHour();
void SetSysMinute(int t);
int GetSysMinute();
void SetSysSecond(int t);
int GetSysSecond();

void SetSysTime(time_t t);
void SetSysTimeMs(time_t t);
time_t GetSysTimeMs();
time_t GetSysTime();
uint32 GetTomorrowMillsec();

void SetClearDayTime(time_t t);
time_t GetClearDayTime();
void SetClearWeekTime(time_t t);
time_t GetClearWeekTime();
void SetClearMonthTime(time_t t);
time_t GetClearMonthTime();

int GetMinute();
int GetHour();
int GetDay();
int GetMonth();
int GetYear();
int GetYDay();
int GetMonthDayNum();

int UTF8ToUnicode(char *to, size_t toLen, char *from, size_t fromLen);
int UnicodeToUTF8(char *to, size_t toLen, char *from, size_t fromLen);
int GbkToUnicode(char *to, size_t toLen, char *from, size_t fromLen);
int UnicodeToGbk(char *to, size_t toLen, char *from, size_t fromLen);
int GbkToUTF8(char *to, size_t toLen, char *from, size_t fromLen);
int UTF8ToGbk(char *to, size_t toLen, char *from, size_t fromLen);
int Random(int min, int max);

string IntToStr(int value);


#endif

