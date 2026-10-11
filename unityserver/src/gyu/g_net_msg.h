#ifndef _GYU_NET_MESSAGE_H_
#define _GYU_NET_MESSAGE_H_

#include <cstddef>
#include <string>

namespace gyu {
	namespace net {
		enum MessEncodeType {
			MET_UTF8 = 1,
			MET_Unicode = 2,
		};
		enum MessMaxLenSize {
			MMS_2Byte = 1,
			MMS_4Byte = 2,
		};

		class CNetMessage
		{
		public:
			CNetMessage();

			static void SetNetMsgEncodeType(MessEncodeType type=MET_UTF8);
			static void SetMsgMaxLenSize(MessMaxLenSize type=MMS_2Byte);
			static unsigned int GetHeadLen();

			unsigned int GetDataLen();
			unsigned int GetDataLenExceptHead();
			void SetDataLen();
			std::string *GetMsgData();
			void SetType(unsigned short type);
			unsigned short GetType();
			void ReWrite();
			void ReRead();
			void CopyData(CNetMessage&);
			void WriteData(unsigned int begin, void *pData, unsigned int datalen);
			void SetData(void *pData,unsigned int dataLen);
			void *operator new(size_t);
			void operator delete(void *);

			template<typename Type>
			CNetMessage &operator<<(Type val)
			{
				WriteData(&val,sizeof(val));
				return *this;
			}

			template<typename Type>
			CNetMessage &operator>>(Type &val)
			{
				ReadData(&val, sizeof(val));
				return *this;
			}

			bool RecvComplete();
			int RecvMsg(int sockId);
			int SendMsg(int sockId);
			bool SendComplete();
			void ReSend();
			unsigned int GetSendBegin();
			void WriteData(void *pData,unsigned int dataLen);
			void Append(CNetMessage &val);
			void ReadString(std::string &);
			void AddNetMsgExceptHead(CNetMessage &val);
			void PrintMsg();

			const static unsigned int MAX_RECV_PACK_LEN = 20480;

		private:
			void ReadData(void *pData,unsigned int dataLen);
			void add_String(const char *pStr);
			void add_String(std::string &str);
			void add_NetMsg(CNetMessage &val);
			void get_NetMsg(CNetMessage &val);
			void get_EncodeString(std::string &str);

		private:
			const static unsigned int MAX_SEND_PACK_LEN = 0xffff;
			static MessEncodeType m_messageEncodeType;
			static MessMaxLenSize m_maxLenSize;
			static int m_msgHeadLen;
			static int m_msgTypeBegin;
			unsigned int m_readPos;
			std::string m_msgData;
			unsigned int m_recvLen;
			unsigned int m_sendBegin;
		};

		template<> inline CNetMessage &CNetMessage::operator << <std::string>(std::string val)
		{
			add_String(val);
			return *this;
		}

		template<> inline CNetMessage &CNetMessage::operator << <const char*> (const char *val)
		{
			add_String(val);
			return *this;
		}

		template<> inline CNetMessage &CNetMessage::operator<< <char*> (char *val)
		{
			add_String(val);
			return *this;
		}

		template<> inline CNetMessage &CNetMessage::operator>> <std::string> (std::string &val)
		{
			get_EncodeString(val);
			return *this;
		}

		template<> inline CNetMessage &CNetMessage::operator<< <CNetMessage> (CNetMessage val)
		{
			add_NetMsg(val);
			return *this;
		}

		template<> inline CNetMessage &CNetMessage::operator>> <CNetMessage> (CNetMessage &val)
		{
			get_NetMsg(val);
			return *this;
		}
	}
}

#endif
