#include "g_net_msg.h"
#include <algorithm>
#include <cstring>
#include <iostream>
#include <string>

#ifdef _WIN32
#include <winsock2.h>
#else
#include <errno.h>
#include <sys/socket.h>
#include <unistd.h>
#endif

namespace gyu {
namespace net {

namespace {

std::string Utf8ToUtf16Le(const char *text, size_t len)
{
	std::string out;
	out.reserve(len * 2);
	for(size_t i = 0; i < len;)
	{
		unsigned int cp = 0;
		unsigned char c = static_cast<unsigned char>(text[i]);
		if(c < 0x80)
		{
			cp = c;
			++i;
		}
		else if((c & 0xe0) == 0xc0 && i + 1 < len)
		{
			cp = ((c & 0x1f) << 6) | (static_cast<unsigned char>(text[i + 1]) & 0x3f);
			i += 2;
		}
		else if((c & 0xf0) == 0xe0 && i + 2 < len)
		{
			cp = ((c & 0x0f) << 12)
				| ((static_cast<unsigned char>(text[i + 1]) & 0x3f) << 6)
				| (static_cast<unsigned char>(text[i + 2]) & 0x3f);
			i += 3;
		}
		else if((c & 0xf8) == 0xf0 && i + 3 < len)
		{
			cp = ((c & 0x07) << 18)
				| ((static_cast<unsigned char>(text[i + 1]) & 0x3f) << 12)
				| ((static_cast<unsigned char>(text[i + 2]) & 0x3f) << 6)
				| (static_cast<unsigned char>(text[i + 3]) & 0x3f);
			i += 4;
		}
		else
		{
			cp = '?';
			++i;
		}

		if(cp <= 0xffff)
		{
			out.push_back(static_cast<char>(cp & 0xff));
			out.push_back(static_cast<char>((cp >> 8) & 0xff));
		}
		else
		{
			cp -= 0x10000;
			unsigned int high = 0xd800 + (cp >> 10);
			unsigned int low = 0xdc00 + (cp & 0x3ff);
			out.push_back(static_cast<char>(high & 0xff));
			out.push_back(static_cast<char>((high >> 8) & 0xff));
			out.push_back(static_cast<char>(low & 0xff));
			out.push_back(static_cast<char>((low >> 8) & 0xff));
		}
	}
	return out;
}

void AppendUtf8Codepoint(std::string &out, unsigned int cp)
{
	if(cp <= 0x7f)
	{
		out.push_back(static_cast<char>(cp));
	}
	else if(cp <= 0x7ff)
	{
		out.push_back(static_cast<char>(0xc0 | (cp >> 6)));
		out.push_back(static_cast<char>(0x80 | (cp & 0x3f)));
	}
	else if(cp <= 0xffff)
	{
		out.push_back(static_cast<char>(0xe0 | (cp >> 12)));
		out.push_back(static_cast<char>(0x80 | ((cp >> 6) & 0x3f)));
		out.push_back(static_cast<char>(0x80 | (cp & 0x3f)));
	}
	else
	{
		out.push_back(static_cast<char>(0xf0 | (cp >> 18)));
		out.push_back(static_cast<char>(0x80 | ((cp >> 12) & 0x3f)));
		out.push_back(static_cast<char>(0x80 | ((cp >> 6) & 0x3f)));
		out.push_back(static_cast<char>(0x80 | (cp & 0x3f)));
	}
}

std::string Utf16LeToUtf8(const char *data, size_t len)
{
	std::string out;
	for(size_t i = 0; i + 1 < len; i += 2)
	{
		unsigned int w1 = static_cast<unsigned char>(data[i])
			| (static_cast<unsigned char>(data[i + 1]) << 8);
		if(w1 >= 0xd800 && w1 <= 0xdbff && i + 3 < len)
		{
			unsigned int w2 = static_cast<unsigned char>(data[i + 2])
				| (static_cast<unsigned char>(data[i + 3]) << 8);
			if(w2 >= 0xdc00 && w2 <= 0xdfff)
			{
				unsigned int cp = 0x10000 + (((w1 - 0xd800) << 10) | (w2 - 0xdc00));
				AppendUtf8Codepoint(out, cp);
				i += 2;
				continue;
			}
		}
		AppendUtf8Codepoint(out, w1);
	}
	return out;
}

}

MessEncodeType CNetMessage::m_messageEncodeType = MET_UTF8;
MessMaxLenSize CNetMessage::m_maxLenSize = MMS_2Byte;
int CNetMessage::m_msgHeadLen = 4;
int CNetMessage::m_msgTypeBegin = 2;

CNetMessage::CNetMessage()
	:m_readPos(0), m_recvLen(0), m_sendBegin(0)
{
	ReWrite();
}

void CNetMessage::SetNetMsgEncodeType(MessEncodeType type)
{
	m_messageEncodeType = type;
}

void CNetMessage::SetMsgMaxLenSize(MessMaxLenSize type)
{
	m_maxLenSize = type;
	if(type == MMS_4Byte)
	{
		m_msgHeadLen = 6;
		m_msgTypeBegin = 4;
	}
	else
	{
		m_msgHeadLen = 4;
		m_msgTypeBegin = 2;
	}
}

unsigned int CNetMessage::GetHeadLen()
{
	return (unsigned int)m_msgHeadLen;
}

unsigned int CNetMessage::GetDataLen()
{
	return (unsigned int)m_msgData.size();
}

unsigned int CNetMessage::GetDataLenExceptHead()
{
	return m_msgData.size() >= (size_t)m_msgHeadLen ? (unsigned int)m_msgData.size() - m_msgHeadLen : 0;
}

void CNetMessage::SetDataLen()
{
	unsigned int len = m_msgData.size() > (size_t)m_msgHeadLen
		? (unsigned int)m_msgData.size() - (unsigned int)m_msgHeadLen
		: 0;
	if(m_maxLenSize == MMS_4Byte)
	{
		if(m_msgData.size() < 4)
			m_msgData.resize(4, 0);
		std::memcpy(&m_msgData[0], &len, 4);
	}
	else
	{
		unsigned short s = (unsigned short)len;
		if(m_msgData.size() < 2)
			m_msgData.resize(2, 0);
		std::memcpy(&m_msgData[0], &s, 2);
	}
}

std::string *CNetMessage::GetMsgData()
{
	return &m_msgData;
}

void CNetMessage::SetType(unsigned short type)
{
	if(m_msgData.size() < (size_t)m_msgHeadLen)
		m_msgData.resize(m_msgHeadLen, 0);
	std::memcpy(&m_msgData[m_msgTypeBegin], &type, sizeof(type));
	SetDataLen();
}

unsigned short CNetMessage::GetType()
{
	unsigned short type = 0;
	if(m_msgData.size() >= (size_t)(m_msgTypeBegin + 2))
		std::memcpy(&type, &m_msgData[m_msgTypeBegin], sizeof(type));
	return type;
}

void CNetMessage::ReWrite()
{
	m_msgData.assign(m_msgHeadLen, '\0');
	m_readPos = m_msgHeadLen;
	m_recvLen = 0;
	m_sendBegin = 0;
	SetDataLen();
}

void CNetMessage::ReRead()
{
	m_readPos = m_msgHeadLen;
}

void CNetMessage::CopyData(CNetMessage& other)
{
	m_msgData = *other.GetMsgData();
	m_readPos = m_msgHeadLen;
	m_recvLen = (unsigned int)m_msgData.size();
	m_sendBegin = 0;
}

void CNetMessage::WriteData(unsigned int begin, void *pData, unsigned int datalen)
{
	if(pData == NULL || datalen == 0)
		return;
	if(m_msgData.size() < begin + datalen)
		m_msgData.resize(begin + datalen, 0);
	std::memcpy(&m_msgData[begin], pData, datalen);
	SetDataLen();
}

void CNetMessage::SetData(void *pData,unsigned int dataLen)
{
	if(pData == NULL || dataLen == 0)
	{
		ReWrite();
		return;
	}
	m_msgData.assign((const char*)pData, dataLen);
	m_recvLen = dataLen;
	m_readPos = m_msgHeadLen;
	m_sendBegin = 0;
}

void *CNetMessage::operator new(size_t s)
{
	return ::operator new(s);
}

void CNetMessage::operator delete(void *p)
{
	::operator delete(p);
}

void CNetMessage::WriteData(void *pData,unsigned int dataLen)
{
	if(pData == NULL || dataLen == 0)
		return;
	m_msgData.append((const char*)pData, dataLen);
	SetDataLen();
}

void CNetMessage::Append(CNetMessage &val)
{
	if(val.GetDataLen() == 0)
		return;
	WriteData((void*)val.GetMsgData()->data(), val.GetDataLen());
}

void CNetMessage::ReadData(void *pData,unsigned int dataLen)
{
	if(pData == NULL || m_readPos + dataLen > m_msgData.size())
	{
		if(pData != NULL)
			std::memset(pData, 0, dataLen);
		return;
	}
	std::memcpy(pData, m_msgData.data() + m_readPos, dataLen);
	m_readPos += dataLen;
}

void CNetMessage::add_String(const char *pStr)
{
	if(pStr == NULL)
	{
		unsigned short len = 0;
		WriteData(&len, sizeof(len));
		return;
	}
	std::string encoded = m_messageEncodeType == MET_Unicode
		? Utf8ToUtf16Le(pStr, std::strlen(pStr))
		: std::string(pStr);
	unsigned short len = (unsigned short)encoded.size();
	WriteData(&len, sizeof(len));
	if(len > 0)
		WriteData((void*)encoded.data(), len);
}

void CNetMessage::add_String(std::string &str)
{
	std::string encoded = m_messageEncodeType == MET_Unicode
		? Utf8ToUtf16Le(str.data(), str.size())
		: str;
	unsigned short len = (unsigned short)encoded.size();
	WriteData(&len, sizeof(len));
	if(len > 0)
		WriteData((void*)encoded.data(), len);
}

void CNetMessage::get_EncodeString(std::string &str)
{
	unsigned short len = 0;
	ReadData(&len, sizeof(len));
	if(len == 0)
	{
		str.clear();
		return;
	}
	if(m_readPos + len > m_msgData.size())
	{
		str.clear();
		m_readPos = (unsigned int)m_msgData.size();
		return;
	}
	if(m_messageEncodeType == MET_Unicode)
		str = Utf16LeToUtf8(m_msgData.data() + m_readPos, len);
	else
		str.assign(m_msgData.data() + m_readPos, len);
	m_readPos += len;
}

void CNetMessage::ReadString(std::string &str)
{
	get_EncodeString(str);
}

void CNetMessage::add_NetMsg(CNetMessage &val)
{
	// A nested network message already contains its own 4-byte body length and
	// 2-byte command header.  NetMsgBase::ReadNetMsg() expects that packet
	// directly at the current cursor.  Prefixing it with another total-length
	// field shifts the header and makes the client read six bytes past every
	// embedded battle packet, eventually crashing in VCRUNTIME140D.dll.
	val.SetDataLen();
	unsigned int len = val.GetDataLen();
	if(len > 0)
		WriteData((void*)val.GetMsgData()->data(), len);
}

void CNetMessage::get_NetMsg(CNetMessage &val)
{
	unsigned int len = 0;
	ReadData(&len, sizeof(len));
	if(len == 0 || m_readPos + len > m_msgData.size())
	{
		val.ReWrite();
		return;
	}
	val.SetData((void*)(m_msgData.data() + m_readPos), len);
	m_readPos += len;
}

void CNetMessage::AddNetMsgExceptHead(CNetMessage &val)
{
	if(val.GetDataLenExceptHead() == 0)
		return;
	WriteData((void*)(val.GetMsgData()->data() + m_msgHeadLen), val.GetDataLenExceptHead());
}

bool CNetMessage::RecvComplete()
{
	if(m_msgData.size() < (size_t)m_msgHeadLen)
		return false;
	unsigned int bodyLen = 0;
	if(m_maxLenSize == MMS_4Byte)
		std::memcpy(&bodyLen, m_msgData.data(), 4);
	else
	{
		unsigned short s = 0;
		std::memcpy(&s, m_msgData.data(), 2);
		bodyLen = s;
	}
	unsigned int totalLen = bodyLen + (unsigned int)m_msgHeadLen;
	return bodyLen > 0 && m_msgData.size() >= totalLen;
}

int CNetMessage::RecvMsg(int sockId)
{
	char buf[4096];
#ifdef _WIN32
	int ret = recv(sockId, buf, sizeof(buf), 0);
#else
	int ret = (int)recv(sockId, buf, sizeof(buf), 0);
#endif
	if(ret > 0)
	{
		m_msgData.append(buf, ret);
		m_recvLen = (unsigned int)m_msgData.size();
		return ret;
	}
	return ret;
}

int CNetMessage::SendMsg(int sockId)
{
	SetDataLen();
	if(m_sendBegin >= m_msgData.size())
		return 0;
	const char *buf = m_msgData.data() + m_sendBegin;
	int left = (int)(m_msgData.size() - m_sendBegin);
#ifdef _WIN32
	int ret = send(sockId, buf, left, 0);
#else
	int ret = (int)send(sockId, buf, left, 0);
#endif
	if(ret > 0)
		m_sendBegin += ret;
	return ret;
}

bool CNetMessage::SendComplete()
{
	return m_sendBegin >= m_msgData.size();
}

void CNetMessage::ReSend()
{
	m_sendBegin = 0;
}

unsigned int CNetMessage::GetSendBegin()
{
	return m_sendBegin;
}

void CNetMessage::PrintMsg()
{
	std::cout << "CNetMessage type=" << GetType() << " len=" << GetDataLen() << std::endl;
}

}
}
