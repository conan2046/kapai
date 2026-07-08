#ifndef _GYU_UTILITY_H_
#define _GYU_UTILITY_H_
#include <string>
#include <vector>
#include <sys/time.h>

namespace gyu {
	namespace util {
		class TimePrint
		{
		public:
			TimePrint(std::string str,int sock=0);
			~TimePrint();

		private:
			std::string m_str;
			timeval m_time;
			int m_sock;
		};

		std::string GetCurTimeString();

		bool SetSignal(void(*sigHandler)(int), void(*sigCoreHandler)(int));
		void SetDaemon();
	
		int StrToHex(const char *str,unsigned char *pHex,int hexLen);
		void HexToStr(unsigned char *pHex,int hexLen,std::string &str);
		bool SplitString(const std::string & src, std::vector<std::string>& vec, char ch);

		int Random(int min,int max);
		bool RandomSequence(int *array,int arrayLen,int max);

		void MD5String(std::string &str);
		std::string Base64Decode(std::string src);

		int UTF8ToUnicode(char *to,size_t toLen,char *from,size_t fromLen);
		int UnicodeToUTF8(char *to,size_t toLen,char *from,size_t fromLen);
		int GbkToUnicode(char *to,size_t toLen,char *from,size_t fromLen);
		int UnicodeToGbk(char *to,size_t toLen,char *from,size_t fromLen);
		int GbkToUTF8(char *to,size_t toLen,char *from,size_t fromLen);
		int UTF8ToGbk(char *to,size_t toLen,char *from,size_t fromLen);


		template<typename Type>
		inline Type RandSelect(Type *arr,int num)
		{
			return arr[Random(0,num-1)];
		}

		template<typename Type>
		inline Type CalculateRate(Type src,Type numerator,Type denominator)
		{
			double temp = numerator;
			temp /= denominator;
			return (Type)(src * temp);
		}

		template<typename Bit>
		inline void BitsetToHex(Bit &bit,unsigned char *hex)
		{
			for (int i = 0; i < (int)bit.size(); i++)
			{
				if(bit.test(i))
					hex[i/8] |= 1<<(i%8);
			}
		}

		template<typename Bit>
		inline void HexToBitset(unsigned char *hex,Bit &bit)
		{
			for(int i = 0; i < (int)bit.size(); i++)
			{
				if(hex[i/8] & (1<<(i%8)))
					bit.set(i);
			}
		}

		template<typename Type>
		inline void HexToStr(Type &data,std::string &toStr)
		{
			HexToStr((unsigned char*)&data,sizeof(data),toStr);
		}

		//字符串转换十六进制
		int UnHexify(unsigned char *obuf, const char *ibuf);

		//十六进制转化字符串
		void Hexify(unsigned char *obuf, const unsigned char *ibuf, int len);

		bool Compress(unsigned char *pInBuf,unsigned int inLen,std::string &compress);

		bool UnCompress(const char *inStr, unsigned char *pOutBuf, unsigned int &outLen);
		int UnCompressEx(const char *inStr, unsigned char *pOutBuf, unsigned int outLen);


		template<typename TYPE>
		void RandVector(std::vector<TYPE>& seqs)
		{
			unsigned int num = seqs.size();
			for(unsigned int i = 0; i < num; ++i)
			{
				unsigned int idx = Random(i, num - 1);
				if(idx == i)
					continue;
				TYPE swapIdx = seqs[idx];
				seqs[idx] = seqs[i];
				seqs[i] = swapIdx;
			}
		}
	}
}

#endif

