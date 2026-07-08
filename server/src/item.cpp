#include "item.h"
#include "utility.h"
#include "singleton.h"
#include <iostream>

//////////////////////////////////////////////////////////////////////////////////////////////////////

bool CEquipCfgMgr::Init()
{
	m_qhBasic.clear();
	m_qhAttr.clear();
	m_shengjieCost.clear();
	m_cuilianCfg.clear();
	m_xilianCfg.clear();
	m_xilianAttrPool.clear();

	{
		vector<map<string,string> > data;
		//                     0            1            2          3        4
		const char *keys[] = {"equip_pos","qianghua_level","basicSuccRatio","cost","itemSuccRatio"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("equip_qianghua.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;
		
		for(uint32 i=0;i < data.size();i++)
		{
			SEquipQiangHua t;
			t.equip_pos = atoi(data[i][keys[0]].c_str());
			t.qh_level = atoi(data[i][keys[1]].c_str());
			t.basicSuccRatio = atoi(data[i][keys[2]].c_str());
			SetCostData(t.costList,data[i][keys[3]]);
			SetLuckyData(t.itemSuccRatio,data[i][keys[4]]);
			
			int key = (t.equip_pos << 16) | t.qh_level;
			m_qhBasic.insert(make_pair(key,t));
		}
	}

	{
		vector<map<string,string> > data;
		//                   0         1         2
		const char *keys[] = {"type","qianghua_level","attr"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("equip_qianghua_attr.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;
		
		for(uint32 i=0;i < data.size();i++)
		{
			SEquipQiangHuaAttr t;
			t.type = atoi(data[i][keys[0]].c_str());
			t.qh_level = atoi(data[i][keys[1]].c_str());
			SetAttrData(t.attrList,data[i][keys[2]]);
			
			int key = (t.type << 16) | t.qh_level;
			m_qhAttr.insert(make_pair(key,t));
		}
	}

	{
		vector<map<string,string> > data;
		//                     0        1    2
		const char *keys[] = {"equip_pos","level","cost"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("equip_shengjie.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;
		
		for(uint32 i=0;i < data.size();i++)
		{
			SEquipShengJieCfg t;
			t.equip_pos = atoi(data[i][keys[0]].c_str());
			t.equip_level = atoi(data[i][keys[1]].c_str());
			SetCostData(t.costList,data[i][keys[2]]);
			
			int key = (t.equip_pos << 16) | t.equip_level;
			m_shengjieCost.insert(make_pair(key,t));
		}
	}

	{
		vector<map<string,string> > data;
		//                   0       1          2         3          4          5          6         7          8         9         10         11         12         13        14         15
		const char *keys[] = {"type","attr1_level","attr1_type","attr1_max","attr2_level","attr2_type","attr2_max","attr3_level","attr3_type","attr3_max","attr4_level","attr4_type","attr4_max","attr5_level","attr5_type","attr5_max"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("equip_cuilian_attr.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;
		
		for(uint32 i=0;i < data.size();i++)
		{
			SEquipCuiLianCfg t;
			t.type = atoi(data[i][keys[0]].c_str());
			for(uint8 k=0;k < sizeof(t.attrType)/sizeof(t.attrType[0]);k++)
			{
				t.openLevel[k] = atoi(data[i][keys[k*3+1]].c_str());
				t.attrType[k] = atoi(data[i][keys[k*3+2]].c_str());
				t.attrMaxValue[k] = atoi(data[i][keys[k*3+3]].c_str());
			}
			m_cuilianCfg.insert(make_pair(t.type,t));
		}
	}

	{
		vector<map<string,string> > data;
		//                     0       1          2             3
		const char *keys[] = {"equip_pos","cost","random_attr_num","ratio_pool"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("equip_xilian.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;
		
		for(uint32 i=0;i < data.size();i++)
		{
			SEquipXiLian t;
			t.equip_pos = atoi(data[i][keys[0]].c_str());
			SetCostData(t.costList,data[i][keys[1]]);
			SetRandomAttrData(t.random_attr,data[i][keys[2]]);
			SetRatioPoolData(t.ratio_pool,data[i][keys[3]]);
			uint16 itemId = GetCostItemId(t.costList);
			if(itemId == 0)
			{
				cout<<">> CEquipCfgMgr::Init() can't find costItemId,  str="<<data[i][keys[1]]<<endl;
				continue;
			}
			int key = (t.equip_pos << 16) | itemId;
			m_xilianCfg.insert(make_pair(key,t));
		}
	}

	{
		vector<map<string,string> > data;
		//                   0      1
		const char *keys[] = {"type","attr_pool"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("equip_xilian_attr.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;
		
		for(uint32 i=0;i < data.size();i++)
		{
			SEquipXiLianAttr t;
			t.type = atoi(data[i][keys[0]].c_str());
			SetAttrData(t.attrList,data[i][keys[1]]);
			m_xilianAttrPool.insert(make_pair(t.type,t));
		}
	}

	return true;
}

SEquipQiangHua *CEquipCfgMgr::GetQiangHuaBasicCfg(int equip_pos,int qh_level)
{
	if(equip_pos < 1 || qh_level < 0)
		return NULL;
	
	int key = (equip_pos << 16) | qh_level;
	map<int,SEquipQiangHua>::iterator it = m_qhBasic.find(key);
	if(it == m_qhBasic.end())
		return NULL;
	return &(it->second);
}

SEquipQiangHuaAttr *CEquipCfgMgr::GetQiangHuaAttrCfg(int type,int qh_level)
{
	if(type < 1 || qh_level < 0)
		return NULL;
	
	int key = (type << 16) | qh_level;
	map<int,SEquipQiangHuaAttr>::iterator it = m_qhAttr.find(key);
	if(it == m_qhAttr.end())
		return NULL;
	return &(it->second);
}

SEquipShengJieCfg *CEquipCfgMgr::GetShengJieCfg(int equip_pos,int equip_level)
{
	if(equip_pos < 1 || equip_level < 1)
		return NULL;
	
	int key = (equip_pos << 16) | equip_level;
	map<int,SEquipShengJieCfg>::iterator it = m_shengjieCost.find(key);
	if(it == m_shengjieCost.end())
		return NULL;
	return &(it->second);
}

SEquipCuiLianCfg *CEquipCfgMgr::GetCuiLianCfg(int type)
{
	if(type < 1)
		return NULL;

	map<int,SEquipCuiLianCfg>::iterator it = m_cuilianCfg.find(type);
	if(it == m_cuilianCfg.end())
		return NULL;
	return &(it->second);
}

SEquipXiLian *CEquipCfgMgr::GetXiLianBasicCfg(int equip_pos,int itemId)
{
	if(equip_pos < 1 || itemId < 1)
		return NULL;

	int key = (equip_pos << 16) | itemId;
	map<int,SEquipXiLian>::iterator it = m_xilianCfg.find(key);
	if(it == m_xilianCfg.end())
		return NULL;
	return &(it->second);
}

SEquipXiLianAttr *CEquipCfgMgr::GetXiLianAttrPool(int type)
{
	if(type < 1)
		return NULL;

	map<int,SEquipXiLianAttr>::iterator it = m_xilianAttrPool.find(type);
	if(it == m_xilianAttrPool.end())
		return NULL;
	return &(it->second);
}

bool CEquipCfgMgr::SetLuckyData(vector<SLuckyItemData> &data,string &str)
{
	data.clear();
	if(str.empty())
		return true;
	
	char buf[2048];
	int num = 0;
	char *p[100];
	strncpy(buf,str.c_str(),sizeof(buf));
	num = SplitLine(p,buf,';');
	for(int i=0;i < num;i++)
	{
		char tbuf[128];
		int tnum = 0;
		char *tp[10];
		strncpy(tbuf,p[i],sizeof(tbuf));
		tnum = SplitLine(tp,tbuf,'-');
		if(tnum != 2)
		{
			cout<<">> SetLuckyData() cost error ... str="<<str<<endl;
			return false;
		}

		SLuckyItemData lucky;
		lucky.itemId = atoi(tp[0]);
		lucky.extSuccRatio = atoi(tp[1]);
		data.push_back(lucky);
	}
	return true;
}

bool CEquipCfgMgr::SetRandomAttrData(vector<SRandomAttrNum> &data,string &str)
{
	data.clear();
	if(str.empty())
		return true;
	
	char buf[2048];
	int num = 0;
	char *p[100];
	strncpy(buf,str.c_str(),sizeof(buf));
	num = SplitLine(p,buf,';');
	for(int i=0;i < num;i++)
	{
		char tbuf[128];
		int tnum = 0;
		char *tp[10];
		strncpy(tbuf,p[i],sizeof(tbuf));
		tnum = SplitLine(tp,tbuf,'-');
		if(tnum != 2)
		{
			cout<<">> SetRandomAttrData() cost error ... str="<<str<<endl;
			return false;
		}

		SRandomAttrNum randomAttr;
		randomAttr.attr_num = atoi(tp[0]);
		randomAttr.ratio = atoi(tp[1]);
		data.push_back(randomAttr);
	}
	return true;
}

bool CEquipCfgMgr::SetRatioPoolData(vector<SEquipXLAttrRatio> &data,string &str)
{
	data.clear();
	if(str.empty())
		return true;
	
	char buf[2048];
	int num = 0;
	char *p[100];
	strncpy(buf,str.c_str(),sizeof(buf));
	num = SplitLine(p,buf,';');
	for(int i=0;i < num;i++)
	{
		char tbuf[128];
		int tnum = 0;
		char *tp[10];
		strncpy(tbuf,p[i],sizeof(tbuf));
		tnum = SplitLine(tp,tbuf,'-');
		if(tnum != 4)
		{
			cout<<">> SetRatioPoolData() cost error ... str="<<str<<endl;
			return false;
		}

		SEquipXLAttrRatio attrRatio;
		attrRatio.ratio = atoi(tp[0]);
		attrRatio.min_attrVal = atoi(tp[1]);
		attrRatio.max_attrVal = atoi(tp[2]);
		attrRatio.star = atoi(tp[3]);
		data.push_back(attrRatio);
	}
	return true;
}

int CEquipCfgMgr::GetCostItemId(vector<SCostData> &data)
{
	if(data.empty())
		return 0;
	for(uint16 i=0;i < data.size();i++)
	{
		if(data[i].costType < HDAT_MONEY)
			return data[i].costType;
	}
	return 0;
}











