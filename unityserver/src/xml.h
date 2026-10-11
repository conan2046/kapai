#ifndef _XML_H_
#define _XML_H_

#include <iostream>
#include <vector>
#include <string>
#include <map>
#include "tinyxml.h"
#include "self_typedef.h"
using namespace std;

const string XML_PATH = "./xml/";

class CXMLReader
{
public:
	CXMLReader()
	{
		m_doc = NULL;
		m_fileName.clear();

		m_doc = new TiXmlDocument();
		if(m_doc == NULL)
		{
			cout<<">> CXMLReader() Init Error !!"<<endl;
			return;
		}
	}
	
	CXMLReader(string fileName)
	{
		m_doc = NULL;
		if(fileName.empty())
			return;
		
		m_fileName = XML_PATH + fileName;
		m_doc = new TiXmlDocument(m_fileName.c_str());
		if(m_doc == NULL)
		{
			cout<<">> CXMLReader(fileName) Init Error !!  fileName="<<m_fileName<<endl;
			return;
		}
		if(!m_doc->LoadFile())
		{
			cout<<">> CXMLReader(fileName) LoadFile Error !!  fileName="<<m_fileName<<endl;
			return;
		}
		cout<<">> loadXML file="<<m_fileName<< "  success"<<endl;
	}
	
	bool SetFileName(string fileName)
	{
		if(m_doc == NULL)
			return false;
		if(fileName.empty())
			return false;
		
		m_fileName = XML_PATH + fileName;
		if(!m_doc->LoadFile(m_fileName.c_str()))
		{
			cout<<">> CXMLReader::SetFileName() LoadFile  Error !!  fileName="<<m_fileName<<endl;
			return false;
		}
		cout<<">> load "<<m_fileName<< "  success"<<endl;
		return true;
	}
	
	bool GetAllElements(vector<map<string,string> > &out,const char *keys[],uint32 keysize)
	{
		out.clear();
		if(keys == NULL || keysize == 0)
		{
			cout<<">> CXMLReader::GetAllElements() keys  empty "<<endl;
			return false;
		}
		if(m_doc == NULL)
		{
			cout<<">> CXMLReader::GetAllElements() m_doc=null !!  "<<endl;
			return false;
		}
		TiXmlElement *root = NULL;
		if((root = m_doc->FirstChildElement()) == NULL)
		{
			cout<<">> CXMLReader::GetAllElements() GetRootElement Error !!  "<<endl;
			return false;
		}
		
		uint16 size = keysize;
		for(TiXmlElement *e = root->FirstChildElement(); e != NULL; e = e->NextSiblingElement())
		{
			map<string,string> data;
			bool error = false;
			for(uint16 i=0;i < size;i++)
			{
				const char *value = e->Attribute(keys[i]);
				if(value == NULL)
				{
					error = true;
					cout<<">> CXMLReader::GetAllElements()  file="<<m_fileName<<", key="<<keys[i]<<" can't find "<<endl;
					break;
				}
				if(!data.insert(make_pair(keys[i],value)).second)
				{
					error = true;
					cout<<">> CXMLReader::GetAllElements()  file="<<m_fileName<<", key="<<keys[i]<<" insert error "<<endl;
					break;
				}
			}
			if(!error)
				out.push_back(data);
		}
		return true;
	}

	bool GetAllElements(map<string,map<string,string> > &out,const char *keys[],uint32 keysize)
	{
		out.clear();
		if(keys == NULL || keysize == 0)
		{
			cout<<">> CXMLReader::GetAllElements() keys  empty "<<endl;
			return false;
		}
		if(m_doc == NULL)
		{
			cout<<">> CXMLReader::GetAllElements() m_doc=null !!  "<<endl;
			return false;
		}
		TiXmlElement *root = NULL;
		if((root = m_doc->FirstChildElement()) == NULL)
		{
			cout<<">> CXMLReader::GetAllElements() GetRootElement Error !!  "<<endl;
			return false;
		}
		
		uint16 size = keysize;
		for(TiXmlElement *e = root->FirstChildElement(); e != NULL; e = e->NextSiblingElement())
		{
			map<string,string> data;
			string firstString = "";
			bool error = false;
			for(uint16 i=0;i < size;i++)
			{
				const char *value = e->Attribute(keys[i]);
				if(value == NULL)
				{
					error = true;
					cout<<">> CXMLReader::GetAllElements()  file="<<m_fileName<<", key="<<keys[i]<<" can't find "<<endl;
					break;
				}
				if(!data.insert(make_pair(keys[i],value)).second)
				{
					error = true;
					cout<<">> CXMLReader::GetAllElements()  file="<<m_fileName<<", key="<<keys[i]<<" insert error "<<endl;
					break;
				}
				if(i == 0)
					firstString = value;
			}
			if(!error)
				out.insert(make_pair(firstString,data));
		}
		return true;
	}
	
	~CXMLReader()
	{
		if(m_doc != NULL)
			delete m_doc;
		m_doc = NULL;
		m_fileName.clear();
	}

private:
	TiXmlDocument *m_doc;
	string m_fileName;
};

#endif

