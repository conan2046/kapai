#include "utility.h"
#include "monster.h"
#include "singleton.h"
#include "init.h"
#include <iostream>

void SUnitBasicAttr::AddAttrValue(vector<SAttrData> &attrList)
{
	attack = attackBase * ((attackRatio + GetAttrValue(attrList,EAT_AttackAdd)) /10000.0) + attackEx + GetAttrValue(attrList,EAT_Attack);
	wufang = wufangBase * ((wufangRatio + GetAttrValue(attrList,EAT_WuFangAdd))/10000.0) + wufangEx + GetAttrValue(attrList,EAT_WuFang);
	fafang = fafangBase * ((fafangRatio + GetAttrValue(attrList,EAT_FaFangAdd))/10000.0) + fafangEx + GetAttrValue(attrList,EAT_FaFang);
	maxHp = maxHpBase * ((maxHpRatio + GetAttrValue(attrList,EAT_QiXueAdd))/10000.0) + maxHpEx + GetAttrValue(attrList,EAT_QiXue);
//	speed += GetAttrValue(attrList,EAT_SuDu);
	mingzhong += GetAttrValue(attrList,EAT_MingZhong);
	shanbi += GetAttrValue(attrList,EAT_ShanBi);
	baoji += GetAttrValue(attrList,EAT_BaoJi);
	baojikang += GetAttrValue(attrList,EAT_BaoJiKang);
	
	mingzhongLv += GetAttrValue(attrList,EAT_MingZhongLv);
	shanbiLv += GetAttrValue(attrList,EAT_ShanBiLv);
	baojiLv += GetAttrValue(attrList,EAT_BaoJiLv);
	baojikangLv += GetAttrValue(attrList,EAT_BaoJiKangLv);
	zengshangLv += GetAttrValue(attrList,EAT_ZengShangLv);
	wumianLv += GetAttrValue(attrList,EAT_WuMianLv);
	famianLv += GetAttrValue(attrList,EAT_FaMianLv);
	baojiAdd += GetAttrValue(attrList,EAT_BaoJiAdd);
	fanjiLv += GetAttrValue(attrList,EAT_FanJiLv);
	fanjikangLv += GetAttrValue(attrList,EAT_FanJiKangLv);
	fanjiAdd += GetAttrValue(attrList,EAT_FanJiAdd);
	lianjiLv += GetAttrValue(attrList,EAT_LianJiLv);
	lianjikangLv += GetAttrValue(attrList,EAT_LianJiKangLv);
	lianjiAdd += GetAttrValue(attrList,EAT_LianJiAdd);
	fanzhenLv += GetAttrValue(attrList,EAT_FanZhenLv);
	fanzhenkangLv += GetAttrValue(attrList,EAT_FanZhenKangLv);
	fanzhenAdd += GetAttrValue(attrList,EAT_FanZhenAdd);
	fumianAdd += GetAttrValue(attrList,EAT_FuMianAdd);
	fumianKangAdd += GetAttrValue(attrList,EAT_FuMianKangAdd);

	attack_percent_fight += GetAttrValue(attrList,EAT_AttackAdd_Fight);
	wufang_percent_fight += GetAttrValue(attrList,EAT_WuFangAdd_Fight);
	fafang_percent_fight += GetAttrValue(attrList,EAT_FaFangAdd_Fight);
	speed_percent_fight += GetAttrValue(attrList,EAT_SuDuAdd_Fight);
}


void SMonsterInst::Init()
{
	hp = attr.maxHp;
}

void SMonsterInst::AddZhenFaAttr(vector<SAttrData> &attrList)
{
	attr.AddAttrValue(attrList);
	hp = attr.maxHp;
}

//七种道具使用强化等级限制
const int SMount::itemUsedLevelLimit[SMount::MAX_MATERIAL_KIND_NUM][5]={{2251,0,9,5,2},{2252,10,19,25,10},{2253,20,39,125,50},{2254,40,99,625,250},{2584,0,99,100,40},{2585,0,99,500,125},{2586,0,99,1500,600}};
// 读取数据，设置坐骑
void SMount::SetMount(char *pMount)
{
	if(pMount == NULL)
		return;

	uint32 len = strlen(pMount)/2;
	if(len < 2)
		return;
	char pTemp[512];
	StrToHex(pMount,(uint8*)pTemp,len);

	int pos = 0;
	memcpy(&m_useIndex,pTemp+pos,sizeof(m_useIndex));
	pos += sizeof(m_useIndex);
	memcpy(&m_level,pTemp+pos,sizeof(m_level));
	pos += sizeof(m_level);

	uint8 index = 0;
	uint8 num = 0;
	memcpy(&num,pTemp+pos,sizeof(num));
	pos += sizeof(num);
	if(num >= MAX_MOUNT_NUM)
		num = MAX_MOUNT_NUM;
	for(uint8 i=0;i < num;i++)
	{
		memcpy(&m_id[index],pTemp+pos,sizeof(m_id[index]));
		pos += sizeof(m_id[index]);
		memcpy(&m_timeLimit[index],pTemp+pos,sizeof(m_timeLimit[index]));
		pos += sizeof(m_timeLimit[index]);
		if(m_timeLimit[index] == 0 || m_timeLimit[index] > (uint32)GetSysTime())
			index++;
		else
			m_id[index] = None;
	}
	m_num = index;
	if(m_useIndex >= m_num)
		m_useIndex = 0xff;
	if( (uint32)pos >= len) //m_exp是后续添加字段
	{
		m_exp = 0;
	}
	else
	{
		memcpy(&m_exp,pTemp+pos,sizeof(m_exp));
		pos += sizeof(m_exp);
	}
}

// 获取序列化坐骑，保存
void SMount::GetMount(string &str)
{	
	const int len = sizeof(m_id) + sizeof(m_timeLimit) + sizeof(m_useIndex) + sizeof(m_level) + sizeof(m_exp)+12;
	uint8 data[len];
	int pos = 0;
	memcpy(data+pos,&m_useIndex,sizeof(m_useIndex));
	pos += sizeof(m_useIndex);
	memcpy(data+pos,&m_level,sizeof(m_level));
	pos += sizeof(m_level);

	uint8 num = 0;
	int numPos = pos;
	memcpy(data+pos,&num,sizeof(num));
	pos += sizeof(num);
	for(uint8 i=0;i < sizeof(m_id)/sizeof(m_id[0]);i++)
	{
		if(m_id[i] > 0)
		{
			memcpy(data+pos,&m_id[i],sizeof(m_id[i]));
			pos += sizeof(m_id[i]);
			memcpy(data+pos,&m_timeLimit[i],sizeof(m_timeLimit[i]));
			pos += sizeof(m_timeLimit[i]);
			num++;
		}
	}
	memcpy(data+numPos,&num,sizeof(num));
	memcpy(data+pos,&m_exp,sizeof(m_exp));
	pos += sizeof(m_exp);
	HexToStr(data,pos,str);
}

int SMount::GetMoveSpeed(uint8 pos)
{
	if(pos == 0xff)
		pos = m_useIndex;
	if(pos == 0xff || pos >= m_num)
		return 0;
	uint8 id = m_id[pos];
	if(id > None)
	{
		SMountConfig *p = SingletonMountCfgMgr::instance().GetCfg(id);
		if(p != NULL)
			return p->moveSpeed;
	}
	return 0;
}

void SMount::RemoveMount(uint8 id)
{
	if(id == None)
		return;
	uint8 pos = 0xff;
	for(uint8 i=0;i < m_num;i++)
	{
		if(m_id[i] == id)
		{
			pos = i;
			break;
		}
	}
	if(pos == 0xff)
		return;
	for(uint8 i=pos+1;i < m_num;i++)
	{
		if(m_id[i] > 0)
		{
			m_id[i-1] = m_id[i];
			m_timeLimit[i-1] = m_timeLimit[i];
		}
	}
}

bool SMount::HaveMount(uint8 id)
{
	if(id == None)
		return false;
	for(uint8 i=0;i < m_num;i++)
	{
		if(m_id[i] == id)
			return true;
	}
	return false;
}

bool SMount::AddMount(uint8 id,uint32 time)
{
	if(id == None)
		return false;
	if(HaveMount(id))
		return false;

	// 添加坐骑
	if(m_num >= sizeof(m_id)/sizeof(m_id[0]))
		return false;
	bool addEnd = false;
	if(id > HuoFengHuang)
		addEnd = true;

	uint32 curTime = (uint32)GetSysTime();
	uint32 timelimit = 0;
	if(time > 0)
		timelimit = curTime + time;
	if(!addEnd)	// 正常坐骑,可进阶
	{
		// 寻找非可进阶坐骑位置
		if(m_num == 0)
		{
			m_id[m_num] = id;
			m_timeLimit[m_num] = timelimit;
		}
		else
		{
			uint8 pos = 0xff;
			for(uint8 i=0;i < m_num;i++)
			{
				if(m_id[i] > HuoFengHuang)
				{
					pos = i;
					break;
				}
			}
			if(pos < m_num)
			{
				for(int k=(int)(m_num-1);k >= (int)pos;k--)
				{
					m_id[k+1] = m_id[k];
					m_timeLimit[k+1] = m_timeLimit[k];
				}
				m_id[pos] = id;
				m_timeLimit[pos] = timelimit;
				if(pos <= m_useIndex)
					m_useIndex++;
			}
			else
			{
				m_id[m_num] = id;
				m_timeLimit[m_num] = timelimit;
			}
		}
	}
	else	// 添加活动坐骑
	{
		m_id[m_num] = id;
		m_timeLimit[m_num] = timelimit;
	}
	m_num++;
	return true;
}

bool SMount::SetUseMountIndex(uint8 index)
{
	if(index == 0xff)
	{
		if(m_useIndex != 0xff)
		{
			m_useIndex = 0xff;
			return true;
		}
		return false;
	}
	else
	{
		if(m_useIndex == index)
			return false;
		else
		{
			if(index >= m_num)
				return false;
			m_useIndex = index;
			return true;
		}
	}
}
bool SMount::GetStrengthenMaterialInfo( int itemId,int &minlevel,int &maxLevel, int &exp ,int &moneyBase)
{
	for(int counter=0; counter<MAX_MATERIAL_KIND_NUM; ++counter)
	{
		if( itemId == itemUsedLevelLimit[counter][0])
		{
			minlevel = itemUsedLevelLimit[counter][1];
			maxLevel = itemUsedLevelLimit[counter][2];
			exp = itemUsedLevelLimit[counter][3];
			moneyBase = itemUsedLevelLimit[counter][4];
			return true;
		}
	}
	return false;
}

/////////////////////////////////////////////////////////////////////////////////////////

bool SWing::AddWing(uint8 id)
{
	if(id == WT_None || id >= WT_Max)
		return false;
	if(HaveWing(id))
		return false;

	if(m_num >= sizeof(m_id)/sizeof(m_id[0]))
		return false;
	m_id[m_num] = id;
	m_num++;
	return true;
}

uint8 SWing::GetJinJieWingId(uint8 &targetId)
{
	// srcId,tarId
	const uint8 JinJieId[][2] = {{WT_Wing_1,WT_Wing_2},{WT_Wing_2,WT_None}};
	if(m_num == 0)
		return 0;
	targetId = WT_None;
	
	uint8 maxId = WT_None;
	uint8 size = sizeof(JinJieId)/sizeof(JinJieId[0]);
	for(uint8 i=0;i < m_num;i++)
	{
		for(uint8 j=0;j < size;j++)
		{
			if(m_id[i] == JinJieId[j][0])
			{
				if(maxId < m_id[i])
				{
					maxId = m_id[i];
					targetId = JinJieId[j][1];
				}
			}
		}
	}
	return maxId;
}

int SWing::GetLevelUpExp()
{
	int nextLv = 0;
	int nextStar = 0;
	if(m_level > MAX_LEVEL-1 || (m_level == MAX_LEVEL-1 && m_star == MAX_STAR-1))
	{
		return 0;
	}
	else
	{
		if(m_star < MAX_STAR-1)
		{
			nextLv = m_level;
			nextStar = m_star+1;
		}
		else
		{
			nextLv = m_level+1;
			nextStar = 0;
		}
	}
	SWingQH *p = SingletonWingCfgMgr::instance().GetQHCfg(nextLv,nextStar);
	if(p != NULL)
		return p->needExp;
	return 0;
}

bool SWing::SetUseWingIndex(uint8 index)
{
	if(index == 0xff)
	{
		if(m_useIndex != 0xff)
		{
			m_useIndex = 0xff;
			return true;
		}
		return false;
	}
	else
	{
		if(m_useIndex == index)
			return false;
		else
		{
			if(index >= m_num)
				return false;
			m_useIndex = index;
			return true;
		}
	}
}

int SWing::AddQiangHuaExp(int exp)
{
	int newWingId = 0;
	while(exp > 0)
	{
		int nLv = 0;
		int nStar = 0;
		if (m_level == MAX_LEVEL)
		{
			if (m_star < MAX_STAR)
			{
				nLv = m_level;
				nStar = m_star + 1;
			}
			else
			{
				m_qh_exp += exp;
				break;
			}
		}
		else if (m_level > MAX_LEVEL)
		{
			break;
		}
		else
		{
			if (m_star < MAX_STAR)
			{
				nLv = m_level;
				nStar = m_star + 1;
			}
			else
			{
				nLv = m_level + 1;
				nStar = 0;
			}
		}

		int nExp = 0;
		SWingQH *p = SingletonWingCfgMgr::instance().GetQHCfg(m_level, m_star);
		if(p != NULL)
			nExp = p->needExp;
		else
			break;
		if((int)m_qh_exp + exp >= nExp)
		{
			if(m_level < (uint8)nLv)
			{
				uint8 wingId = nLv + 1;
				SWingConfig *nextWing = SingletonWingCfgMgr::instance().GetCfg(wingId);
				if (nextWing != NULL && nextWing->getWay == 0)
				{
					if(wingId < 8)
					{
						if (AddWing(wingId))
							newWingId = wingId;
					}
				}
			}
			exp -= nExp - (int)m_qh_exp;
			m_level = nLv;
			m_star = nStar;
			m_qh_exp = 0;
		}
		else
		{
			m_qh_exp += exp;
			exp = 0;
			break;
		}
	}
	return newWingId;
}

void SWing::RemoveWing(uint8 id)
{
	if(id == WT_None)
		return;
	uint8 pos = 0xff;
	for(uint8 i=0;i < m_num;i++)
	{
		if(m_id[i] == id)
		{
			pos = i;
			break;
		}
	}
	if(pos == 0xff)
		return;
	for(uint8 i=pos+1;i < m_num;i++)
	{
		if(m_id[i] > 0)
			m_id[i-1] = m_id[i];
	}
}

bool SWing::HaveWing(uint8 id)
{
	if(id == WT_None || id >= WT_Max)
		return false;
	for(uint8 i=0;i < m_num;i++)
	{
		if(m_id[i] == id)
			return true;
	}
	return false;
}

// 读取数据，设置坐骑
void SWing::SetWing(char *pStr)
{
	if(pStr == NULL)
		return;
	uint32 len = strlen(pStr)/2;
	if(len < 2)
		return;
	char pTemp[1024];
	StrToHex(pStr,(uint8*)pTemp,len);

	int pos = 0;
	memcpy(&m_useIndex,pTemp+pos,sizeof(m_useIndex));
	pos += sizeof(m_useIndex);
	memcpy(&m_level,pTemp+pos,sizeof(m_level));
	pos += sizeof(m_level);
	memcpy(&m_star,pTemp+pos,sizeof(m_star));
	pos += sizeof(m_star);
	memcpy(&m_qh_exp,pTemp+pos,sizeof(m_qh_exp));
	pos += sizeof(m_qh_exp);

	uint8 index = 0;
	uint8 num = 0;
	memcpy(&num,pTemp+pos,sizeof(num));
	pos += sizeof(num);
	if(num >= MAX_WING_NUM)
		num = MAX_WING_NUM;
	for(uint8 i=0;i < num;i++)
	{
		memcpy(&m_id[index],pTemp+pos,sizeof(m_id[index]));
		pos += sizeof(m_id[index]);
		index++;
	}
	m_num = index;
	if(m_useIndex >= m_num)
		m_useIndex = 0xff;
}

// 获取序列化坐骑，保存
void SWing::GetWing(string &str)
{	
	const int len = sizeof(m_id) + sizeof(m_useIndex) + sizeof(m_level) + sizeof(m_star) + 16;
	uint8 data[len];
	int pos = 0;
	memcpy(data+pos,&m_useIndex,sizeof(m_useIndex));
	pos += sizeof(m_useIndex);
	memcpy(data+pos,&m_level,sizeof(m_level));
	pos += sizeof(m_level);
	memcpy(data+pos,&m_star,sizeof(m_star));
	pos += sizeof(m_star);
	memcpy(data+pos,&m_qh_exp,sizeof(m_qh_exp));
	pos += sizeof(m_qh_exp);

	uint8 num = 0;
	int numPos = pos;
	memcpy(data+pos,&num,sizeof(num));
	pos += sizeof(num);
	for(uint8 i=0;i < sizeof(m_id)/sizeof(m_id[0]);i++)
	{
		if(m_id[i] > 0)
		{
			memcpy(data+pos,&m_id[i],sizeof(m_id[i]));
			pos += sizeof(m_id[i]);
			num++;
		}
	}
	memcpy(data+numPos,&num,sizeof(num));
	HexToStr(data,pos,str);
}

/////////////////////////////////////////////////////////////////////////////////

bool CMonsterBossManager::Init()
{
	m_basicBoss.clear();
	m_varyBossAttr.clear();

	{
		const string file = "monster_boss_basic.json";
		//                           0     1        2         3      4          5        6           7              8                9
		const char *titleArrs[] = {"id", "name", "pic", "pic", "scale", "quality", "type", "attack_type", "strength_type", "skill_basic",
		//     10        11       12        13       14        15       16       17       18            19      20
			"level", "attack", "wufang", "fafang", "qixue", "sudu", "mingzhong", "shanbi", "baoji", "kangbao", "mingzhonglv",
		//        21       22          23           24               25           26           27          28         29             30
			"shanblv", "baojilv", "kangbaolv", "baojishanghai", "zengshanglv", "wumianlv", "famianlv", "lianjilv", "kanglianlv", "lianjishanghai",
		//      31           32            33            34           35             36                   37             38                 39
			"fanjilv", "kangfanlv", "fanjishanghia", "fanzhenlv", "kangzhenlv", "fanzhenshanghai", "fumianqianghua", "fumiandikang", "attack_ratio",
		//       40               41             42             43           44                   45              46              47               48
			"wufang_ratio", "fafang_ratio", "qixue_ratio", "sudu_ratio", "mingzhong_ratio", "shanbi_ratio", "baoji_ratio", "kangbao_ratio", "mingzhonglv_ratio",
		//        49                50                51                52                       53                54                55                56
			"shanblv_ratio", "baojilv_ratio", "kangbaolv_ratio", "baojishanghai_ratio", "zengshanglv_ratio", "wumianlv_ratio", "famianlv_ratio", "lianjilv_ratio",
		//          57                   58                    59                60              61                       62                  63
			"kanglianlv_ratio", "lianjishanghai_ratio", "fanjilv_ratio", "kangfanlv_ratio", "fanjishanghia_ratio", "fanzhenlv_ratio", "kangzhenlv_ratio",
		//                64                   65                 66
			"fanzhenshanghai_ratio", "fumianqianghua_ratio", "fumiandikang_ratio"};
		const int typeArrs[] = { 0, 1, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0,
			0, 0, EJPT_INT64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};  // 0-int 1-string 2-array
		rapidjson::Document d;
		rapidjson::Value _para;
		if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
		{
			cout << "CMonsterBossManager::Init >> LoadJosnValue error " << endl;
			return false;
		}

		for (uint32 i = 0; i < _para.Size(); i++)
		{
			const rapidjson::Value &data = _para[i];
			SMonsterBossCfg t;
			t.id = data[titleArrs[0]].GetInt();
			t.name = data[titleArrs[1]].GetString();
			t.pic = data[titleArrs[3]].GetInt();
			t.scale = data[titleArrs[4]].GetInt();
			t.quality = data[titleArrs[5]].GetInt();
			t.type = data[titleArrs[6]].GetInt();
			t.attackType = data[titleArrs[7]].GetInt();
			t.strength_type = data[titleArrs[8]].GetInt();
			ReadMultiSkill(data[titleArrs[9]], t.skills);
			t.level = data[titleArrs[10]].GetInt();
			uint16 pos = 28;
			if(t.strength_type == 0)
				pos = 0;
			t.attr.attackEx = data[titleArrs[11+pos]].GetInt();
			t.attr.attack = t.attr.attackEx;
			t.attr.attackRatio = 10000;
			t.attr.wufangEx = data[titleArrs[12+pos]].GetInt();
			t.attr.wufang = t.attr.wufangEx;
			t.attr.wufangRatio = 10000;
			t.attr.fafangEx = data[titleArrs[13+pos]].GetInt();
			t.attr.fafang = t.attr.fafangEx;
			t.attr.fafangRatio = 10000;
			t.attr.maxHpEx = data[titleArrs[14+pos]].GetInt64();
			t.attr.maxHp = t.attr.maxHpEx;
			t.attr.maxHpRatio = 10000;
			t.attr.speed = data[titleArrs[15+pos]].GetInt();
			t.attr.mingzhong = data[titleArrs[16+pos]].GetInt();
			t.attr.shanbi = data[titleArrs[17+pos]].GetInt();
			t.attr.baoji = data[titleArrs[18+pos]].GetInt();
			t.attr.baojikang = data[titleArrs[19+pos]].GetInt();
			t.attr.mingzhongLv = data[titleArrs[20+pos]].GetInt();
			t.attr.shanbiLv = data[titleArrs[21+pos]].GetInt();
			t.attr.baojiLv = data[titleArrs[22+pos]].GetInt();
			t.attr.baojikangLv = data[titleArrs[23+pos]].GetInt();
			t.attr.baojiAdd = data[titleArrs[24+pos]].GetInt();
			t.attr.zengshangLv = data[titleArrs[25+pos]].GetInt();
			t.attr.wumianLv = data[titleArrs[26+pos]].GetInt();
			t.attr.famianLv = data[titleArrs[27+pos]].GetInt();
			t.attr.lianjiLv = data[titleArrs[28+pos]].GetInt();
			t.attr.lianjikangLv = data[titleArrs[29+pos]].GetInt();
			t.attr.lianjiAdd = data[titleArrs[30+pos]].GetInt();
			t.attr.fanjiLv = data[titleArrs[31+pos]].GetInt();
			t.attr.fanjikangLv = data[titleArrs[32+pos]].GetInt();
			t.attr.fanjiAdd = data[titleArrs[33+pos]].GetInt();
			t.attr.fanzhenLv = data[titleArrs[34+pos]].GetInt();
			t.attr.fanzhenkangLv = data[titleArrs[35+pos]].GetInt();
			t.attr.fanzhenAdd = data[titleArrs[36+pos]].GetInt();
			t.attr.fumianAdd = data[titleArrs[37+pos]].GetInt();
			t.attr.fumianKangAdd = data[titleArrs[38+pos]].GetInt();
			m_basicBoss.insert(make_pair(t.id,t));
		}
	}

	{
		vector<map<string,string> > data;
		//                       0         1     2       3      4      5     6       7        8      9      10         11
		const char *keys[] = {"strength_type","level","attack","wufang","fafang","qixue","sudu","mingzhong","shanbi","baoji","kangbao","mingzhonglv",
		//     12      13       14          15          16         17       18       19       20          21        22
			"shanblv","baojilv","kangbaolv","baojishanghai","zengshanglv","wumianlv","famianlv","lianjilv","kanglianlv","lianjishanghai","fanjilv",
		//      23          24         25        26            27              28           29
			"kangfanlv","fanjishanghia","fanzhenlv","kangzhenlv","fanzhenshanghai","fumianqianghua","fumiandikang"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("monster_boss_vary_attr.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;

		for(uint32 i=0;i < data.size();i++)
		{
			int strength_type = atoi(data[i][keys[0]].c_str());
			int level = atoi(data[i][keys[1]].c_str());
			
			SUnitBasicAttr t;
			t.attack = atoi(data[i][keys[2]].c_str());
			t.wufang = atoi(data[i][keys[3]].c_str());
			t.fafang = atoi(data[i][keys[4]].c_str());
			t.maxHp = atoi(data[i][keys[5]].c_str());
			t.speed = atoi(data[i][keys[6]].c_str());
			t.mingzhong = atoi(data[i][keys[7]].c_str());
			t.shanbi = atoi(data[i][keys[8]].c_str());
			t.baoji = atoi(data[i][keys[9]].c_str());
			t.baojikang = atoi(data[i][keys[10]].c_str());
			t.mingzhongLv = atoi(data[i][keys[11]].c_str());
			t.shanbiLv = atoi(data[i][keys[12]].c_str());
			t.baojiLv = atoi(data[i][keys[13]].c_str());
			t.baojikangLv = atoi(data[i][keys[14]].c_str());
			t.baojiAdd = atoi(data[i][keys[15]].c_str());
			t.zengshangLv = atoi(data[i][keys[16]].c_str());
			t.wumianLv = atoi(data[i][keys[17]].c_str());
			t.famianLv = atoi(data[i][keys[18]].c_str());
			t.lianjiLv = atoi(data[i][keys[19]].c_str());
			t.lianjikangLv = atoi(data[i][keys[20]].c_str());
			t.lianjiAdd = atoi(data[i][keys[21]].c_str());
			t.fanjiLv = atoi(data[i][keys[22]].c_str());
			t.fanjikangLv = atoi(data[i][keys[23]].c_str());
			t.fanjiAdd = atoi(data[i][keys[24]].c_str());
			t.fanzhenLv = atoi(data[i][keys[25]].c_str());
			t.fanzhenkangLv = atoi(data[i][keys[26]].c_str());
			t.fanzhenAdd = atoi(data[i][keys[27]].c_str());
			t.fumianAdd = atoi(data[i][keys[28]].c_str());
			t.fumianKangAdd = atoi(data[i][keys[29]].c_str());
			int key = (strength_type<<16) | level;
			m_varyBossAttr.insert(make_pair(key,t));
		}
	}

	return true;
}

ShareMonsterPtr CMonsterBossManager::CreateMonsterBossById(uint32 bossId,int level)
{
	ShareMonsterPtr ptr;
	map<uint32,SMonsterBossCfg>::iterator it = m_basicBoss.find(bossId);
	if(it == m_basicBoss.end())
		return ptr;
	SMonsterBossCfg &bossCfg = it->second;
	int strength_type = bossCfg.strength_type;
	if(strength_type != 0 && level == 0)
		return ptr;
	
	SMonsterInst *pInst = new SMonsterInst;
	if(pInst == NULL)
		return ptr;
	ptr.reset(pInst);
	pInst->id = bossCfg.id;
	pInst->quality = bossCfg.quality;
	pInst->type = bossCfg.type;
	pInst->pic = bossCfg.pic;
	pInst->scale = bossCfg.scale;
	pInst->attackType = bossCfg.attackType;
	pInst->name = bossCfg.name;
	pInst->skills.assign(bossCfg.skills.begin(),bossCfg.skills.end());
	pInst->passive_skills.assign(bossCfg.passive_skills.begin(),bossCfg.passive_skills.end());
	if(strength_type == 0)
	{
		pInst->attr = bossCfg.attr;
		pInst->level = bossCfg.level;
	}
	else
	{
		pInst->level = level;
		for(uint16 i=0;i < pInst->skills.size();i++)
		{
			pInst->skills[i].level /= 5;
			if(pInst->skills[i].level < 1)
				pInst->skills[i].level = 1;
		}
		for(uint16 i=0;i < pInst->passive_skills.size();i++)
		{
			pInst->passive_skills[i].level /= 5;
			if(pInst->passive_skills[i].level < 1)
				pInst->passive_skills[i].level = 1;
		}

		int key = (strength_type << 16) | level;
		map<int,SUnitBasicAttr>::iterator varyIt = m_varyBossAttr.find(key);
		if(varyIt == m_varyBossAttr.end())
		{
			pInst->id = 0;
			return ptr;
		}
		SUnitBasicAttr varyCfg = varyIt->second;
		varyCfg.CalVaryAttr(bossCfg.attr,10000.0);
		pInst->attr = varyCfg;
	}
	pInst->Init();
	return ptr;
}

ShareMonsterPtr CMonsterBossManager::CreateRatioMonster(uint32 bossId, double ratio)
{
	ShareMonsterPtr ptr = CreateMonsterBossById(bossId);
	SMonsterInst *pInst = ptr.get();
	if (pInst == NULL)
		return ptr;
	pInst->attr.attackEx *= ratio;
	pInst->attr.maxHpEx *= ratio;
	pInst->attr.fafangEx *= ratio;
	pInst->attr.wufangEx *= ratio;
	pInst->attr.attack = pInst->attr.attackEx;
	pInst->attr.maxHp = pInst->attr.maxHpEx;
	pInst->attr.fafang = pInst->attr.fafangEx;
	pInst->attr.wufang = pInst->attr.wufangEx;
	pInst->hp = pInst->attr.maxHpEx;
	return ptr;
}

const char *CMonsterBossManager::GetMonsterBossName(uint32 bossId)
{
	map<uint32,SMonsterBossCfg>::iterator it = m_basicBoss.find(bossId);
	if(it == m_basicBoss.end())
		return "";
	return it->second.name.c_str();
}

int CMonsterBossManager::GetMonsterBossMaxHp(uint32 bossId)
{
	map<uint32,SMonsterBossCfg>::iterator it = m_basicBoss.find(bossId);
	if(it == m_basicBoss.end())
		return -1;
	return it->second.attr.maxHp;
}

bool CMonsterBossManager::GetMonsterBossInfo(uint32 bossId,int &pic,string &name)
{
	pic = 0;
	name.clear();
	map<uint32,SMonsterBossCfg>::iterator it = m_basicBoss.find(bossId);
	if(it == m_basicBoss.end())
		return false;
	pic = it->second.pic;
	name = it->second.name;
	return true;
}

SMonsterBossCfg* CMonsterBossManager::GetMonsterBossCfg(uint32 bossId)
{
	map<uint32, SMonsterBossCfg>::iterator it = m_basicBoss.find(bossId);
	if (it == m_basicBoss.end())
		return NULL;
	return &it->second;
}

bool CMonsterBossManager::SetSkillsData(vector<SSkillData> &data,string &str)
{
	data.clear();
	if(str.empty())
		return true;

	char buf[2048];
	int num = 0;
	char *p[200];
	strncpy(buf,str.c_str(),sizeof(buf));
	num = SplitLine(p,buf,';');
	for(int i=0;i < num;i++)
	{
		char tbuf[64];
		int tnum = 0;
		char *tp[10];
		strncpy(tbuf,p[i],sizeof(tbuf));
		tnum = SplitLine(tp,tbuf,'-');
		if(tnum != 3)
		{
			cout<<"CMonsterBossManager::SetSkillsData() error , str = "<<str;
			return false;
		}

		SSkillData v;
		v.id = atoi(tp[0]);
		v.level = atoi(tp[1]);
		v.ratio = atoi(tp[2]);
		data.push_back(v);
	}
	return true;
}



