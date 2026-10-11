#include "hero_cfg_manager.h"
#include "rapidjson/document.h"
#include "init.h"
#include "utility.h"
#include "user.h"
#include "pet.h"
#include "rank.h"

extern const int SaveDateMaxLen;

U8tU16Map CHeroCfgManager::g_xiuLianAttrAdd;
uint16 CHeroCfgManager::g_xlItemId = 0;

void SAttrData::MakeMsg(CNetMessage& msg)
{
	msg << attrType << attrValue;
}

void MakeMultiAttrMsg(MultiAttr& attrs, CNetMessage& msg)
{
	msg << (uint8)attrs.size();
	for (uint8 i = 0; i < attrs.size(); ++i)
	{
		msg << attrs[i].attrType << attrs[i].attrValue;
	}
}

bool XiuLianLevelCfg::CheckSucc(uint32 curCnt)
{
	double tmp = curCnt * 100.0;
	double percent = tmp / fullCost;
	uint16 ratio = 10000;
	for (uint8 i = 0; i < succRatios.size(); ++i)
	{
		if (succRatios[i].startPercent > percent && succRatios[i].endPercent <= percent)
		{
			ratio = succRatios[i].ratio;
			break;
		}
	}
	int idx = Random(1, 10000);
	return idx >= ratio;
}

SCostData* BookStarCfg::GetCost(uint8 quality)
{
	U8KCostMapIt it = starUpCost.find(quality);
	if (it != starUpCost.end())
	{
		return &it->second;
	}
	return NULL;
}

uint16 BookStarCfg::GetScore(uint8 quality)
{
	U8tU16MapIt it = qualityBookScore.find(quality);
	if (it != qualityBookScore.end())
	{
		return it->second;
	}
	return 0;
}

uint16 BookStarCfg::GetSumScore(uint8 quality)
{
	U8tU16MapIt it = qualityBookSumScore.find(quality);
	if (it != qualityBookSumScore.end())
	{
		return it->second;
	}
	return 0;
}
	
CHeroCfgManager::CHeroCfgManager()
{
}

CHeroCfgManager::~CHeroCfgManager()
{
}

bool CHeroCfgManager::InitHeroCfg()
{	
	return InitHeroQualityCfg()
		&& InitHeroBreakCfg()
		&& InitHeroStarCfg()
		&& InitXiuLianCfg()
		&& InitBookCfg();
}

// 品质
bool CHeroCfgManager::InitHeroQualityCfg()
{
	const string file = "quality.json";
	//                               0       1        2               3                   4                5                 6
	const char* titleArrs[] = { "quality", "name", "break_ratio", "handbook_ratio", "jinglian_ratio", "qianghua_ratio", "fabao_qianghua" };
	const int typeArrs[] = { 0, 1, 0, 0, 0 };  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "CHeroCfgManager::InitHeroQualityCfg >> LoadJosnValue error " << endl;
		return false;
	}
	
	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		uint16 quality = data[titleArrs[0]].GetInt();
		m_costRatio[quality] = data[titleArrs[2]].GetInt() / 10000.0;
		m_bookRatio[quality] = data[titleArrs[3]].GetInt() / 10000.0;
		m_jlRatio[quality] = data[titleArrs[4]].GetInt() / 10000.0;
		m_qhRatio[quality] = data[titleArrs[5]].GetInt() / 10000.0;
		m_fbjlRatio[quality] = data[titleArrs[6]].GetInt() / 10000.0;
	}
	return true;
}

// 突破
bool CHeroCfgManager::InitHeroBreakCfg()
{
	const string file = "break.json";
	//                           0               1        2       3
	const char* titleArrs[] = { "break_level", "cost", "level", "attr" };
	const int typeArrs[] = { 0, 2, 0, 0};  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "CHeroCfgManager::InitHeroBreakCfg >> LoadJosnValue error " << endl;
		return false;
	}
	uint8 sumAttr = 0;
	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		MultiCost costs;
		uint16 breakLevel = data[titleArrs[0]].GetInt();
		ReadMultiCost(data[titleArrs[1]], costs);
		uint8 lvCnd = data[titleArrs[2]].GetInt();
		sumAttr += data[titleArrs[3]].GetInt();
		CostMap costMap;
		for (U16tDblMapIt it = m_costRatio.begin(); it != m_costRatio.end(); ++it)
		{
			MultiCost qcosts = costs;
			for (size_t si = 0; si < qcosts.size(); ++si)
			{
				qcosts[si].costValue *= it->second;
			}
			costMap[it->first] = qcosts;
		}
		m_breakCost[breakLevel] = costMap;
		m_breakLvCond[breakLevel] = lvCnd;
		m_breakAttrAdd[breakLevel] = sumAttr;
	}
	return true;
}

// 星星
bool CHeroCfgManager::InitHeroStarCfg()
{
	const string file = "star.json";
	//                           0        1           2            3             4          5               6                      7               8
	const char* titleArrs[] = { "star", "cost", "skill_level", "attr_ratio", "attr_add", "handbook", "handbook_condition", "handbook_value", "handbook_cost" };
	const int typeArrs[] = { 0, 2, 0, 0, 0, 0, 0, 2, 2 };  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "CHeroCfgManager::InitHeroStarCfg >> LoadJosnValue error " << endl;
		return false;
	}
	uint32 sumEx = 0;
	uint32 sumBook = 0;
	U8tU16Map sumScore;
	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &_arr = _para[i];
		BookStarCfg bcfg;
		HeroStarCfg cfg;
		uint8 star = _arr[titleArrs[0]].GetInt();
		cfg.skillLevel = _arr[titleArrs[2]].GetInt();
		cfg.attrRate = _arr[titleArrs[3]].GetInt();
		cfg.attrEx = _arr[titleArrs[4]].GetInt();
		bcfg.bookAttr = _arr[titleArrs[5]].GetInt();
		bcfg.condLevel = _arr[titleArrs[6]].GetInt();
		sumEx += cfg.attrEx;
		sumBook += bcfg.bookAttr;
		cfg.attrExSum = sumEx;
		bcfg.bookAttrSum = sumBook;
		const rapidjson::Value &costArr = _arr[titleArrs[1]];
		// 神将升星消耗
		for(uint32 j=0; j < costArr.Size() ; j++)
		{
			const rapidjson::Value &cost = costArr[j];
			if(!cost.IsArray())
			{
				cout<<">> InitHeroStarCfg single cost error, idx " << j <<endl;
				continue;
			}
			
			uint32 size = cost.Size();
			if(size != 2)
			{
				cout<<">> InitHeroStarCfg single cost size error, idx, j="<<j<<endl;
				continue;
			}
			uint8 quality = cost[0].GetInt();
			uint16 num = cost[1].GetInt();
			cfg.starUpCost[quality] = num;
		}
		
		for (U16tDblMapIt it = m_bookRatio.end(); it != m_bookRatio.end(); ++it)
		{
			cfg.qualityAttr[it->first] = sumBook * it->second;
		}
		m_heroStarCfg[star] = cfg;
		
		// 图鉴升星消耗
		const rapidjson::Value &bcostArr = _arr[titleArrs[8]];
		// 神将升星消耗
		for(uint32 j=0; j < bcostArr.Size() ; j++)
		{
			const rapidjson::Value &cArr = bcostArr[j];
			if(!cArr.IsArray())
			{
				cout<<">> InitHeroStarCfg single book cost error, idx " << j <<endl;
				continue;
			}
			
			uint32 size = cArr.Size();
			if(size != 3)
			{
				cout<<">> InitHeroStarCfg single book cost size error, idx, j="<<j<<endl;
				continue;
			}
			SCostData cost;
			uint8 quality = cArr[0].GetInt();
			cost.costType = cArr[1].GetInt();
			cost.costValue = cArr[2].GetInt();
			bcfg.starUpCost[quality] = cost;
		}
				
		// 图鉴值
		const rapidjson::Value &bookValue = _arr[titleArrs[7]];
		for(uint32 j=0; j < bookValue.Size() ; j++)
		{
			const rapidjson::Value &bvalue = bookValue[j];
			if(!bvalue.IsArray())
			{
				cout<<">> InitHeroStarCfg single bvalue error, idx " << j <<endl;
				continue;
			}
			
			uint32 size = bvalue.Size();
			if(size != 2)
			{
				cout<<">> InitHeroStarCfg single bvalue size error, idx, j="<<j<<endl;
				continue;
			}
			uint8 quality = bvalue[0].GetInt();
			uint16 num = bvalue[1].GetInt();
			bcfg.qualityBookScore[quality] = num;
			sumScore[quality] += num;
		}
		bcfg.qualityBookSumScore = sumScore;
		m_bookStarCfg[star] = bcfg;
	}
	return true;
}
//
//// 修炼
//bool CHeroCfgManager::InitHeroXiulianCfg()
//{
//	const string file = "xiulian.json";
//	//                             0           1          2          3           4          5
//	const char* titleArrs[] = { "level", "cost_type", "cost_min", "cost_max", "success", "attr" };
//	const int typeArrs[] = { 0, 0, 0, 0, 2, 2 };  // 0-int 1-string 2-array
//	rapidjson::Document d;
//	rapidjson::Value _para;
//	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
//	{
//		cout << "CHeroCfgManager::InitHeroXiulianCfg >> LoadJosnValue error " << endl;
//		return false;
//	}
//	
//	for (uint32 i = 0; i < _para.Size(); i++)
//	{
//		const rapidjson::Value &_arr = _para[i];		
//		XiuLianLevelCfg singleCfg;
//		uint16 level = _arr[titleArrs[0]].GetInt();
//		singleCfg.costType = _arr[titleArrs[1]].GetInt();
//		singleCfg.singleCost = _arr[titleArrs[2]].GetInt();
//		singleCfg.fullCost = _arr[titleArrs[3]].GetInt();
//		
//		// 成功概率
//		const rapidjson::Value &costArr = _arr[titleArrs[4]];
//		for(uint32 j=0; j < costArr.Size() ; j++)
//		{
//			const rapidjson::Value &cost = costArr[j];
//			if(!cost.IsArray())
//			{
//				cout<<">> InitHeroXiulianCfg single cost error, idx " << j <<endl;
//				continue;
//			}
//			
//			uint32 size = cost.Size();
//			if(size != 3)
//			{
//				cout<<">> InitHeroXiulianCfg single cost size error, idx, j="<<j<<endl;
//				continue;
//			}
//			XiuLianSuccRatio ratio;
//			ratio.startPercent = cost[0].GetInt();
//			ratio.endPercent = cost[1].GetInt();
//			ratio.ratio = cost[2].GetInt();
//			singleCfg.succRatios.push_back(ratio);
//		}
//		m_xiuLianLevelCfg[level] = singleCfg;
//	}
//	return true;
//}

// 图鉴
bool CHeroCfgManager::InitBookCfg()
{
	const string file = "handbook.json";
	//                             0           1          2
	const char* titleArrs[] = { "id", "handbook_value", "attr" };
	const int typeArrs[] = { 0, 0, 2};  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "CHeroCfgManager::InitBookCfg >> LoadJosnValue error " << endl;
		return false;
	}
	
	MultiAttr sumAttr; 
	uint32 start = 0;
	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &_arr = _para[i];		
		BookLevelCfg cfg;
		cfg.level = _arr[titleArrs[0]].GetInt();
		cfg.starValue = start;
		cfg.endValue = _arr[titleArrs[1]].GetInt();
		start = cfg.endValue;
		ReadMultiAttr(_arr[titleArrs[2]], cfg.curAttrs);
		MergeAttrList(sumAttr, cfg.curAttrs);
		cfg.curSumAttrs = sumAttr;
		m_bookCfg[cfg.level] = cfg;
	}
	return true;
}

// 修炼
bool CHeroCfgManager::InitXiuLianCfg()
{
	const string file = "xiulian.json";

	//                             0       1          2             3             4            5
	const char* titleArrs[] = { "level", "name", "level_need", "cost_type", "cost_xiulian", "attr" };
	const int typeArrs[] = { EJPT_INT, EJPT_STRING, EJPT_INT, EJPT_INT, EJPT_ARRAY, EJPT_ARRAY };  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "CHeroCfgManager::InitXiuLianCfg >> LoadJosnValue error " << endl;
		return false;
	}

	uint32 sumCnt = 0;
	MultiAttr sumAttrs;
	vector<SSkillData> skills;
	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &_arr = _para[i];
		XiuLianCfg cfg;
		cfg.level = _arr[titleArrs[0]].GetInt();
		cfg.name = _arr[titleArrs[1]].GetString();
		cfg.condLv = _arr[titleArrs[2]].GetInt();
		cfg.xiuLianCnt += _arr[titleArrs[3]].GetInt();
		sumCnt += cfg.xiuLianCnt;
		cfg.sumCnt = sumCnt;

		ReadMultiCost(_arr[titleArrs[4]], cfg.costs);
		const rapidjson::Value &attrAdd = _arr[titleArrs[5]];
		// [1,10,300],[1,11,300],[1,12,300],[1,13,300],[2,5000,1]
		vector<SAttrData> attrs;
		for (uint32 ai = 0; ai < attrAdd.Size(); ++ai)
		{
			// [1,10,5]
			const rapidjson::Value &singleAttr = attrAdd[ai];
			if (!singleAttr.IsArray() || singleAttr.Size() != 3)
			{
				continue;
			}
			uint8 type = singleAttr[0].GetInt();
			if (type == 1)
			{
				SAttrData attr;
				attr.attrType = singleAttr[1].GetInt();
				attr.attrValue = singleAttr[2].GetInt();
				attrs.push_back(attr);
			}
			else if (type == 2)
			{
				SSkillData skill;
				skill.id = singleAttr[1].GetInt();
				skill.level = singleAttr[2].GetInt();
				skills.push_back(skill);
			}
		}
		MergeAttrList(sumAttrs, attrs);
		cfg.sumAttrs = sumAttrs;
		cfg.skill = skills;
		m_xiuLianCfg[cfg.level] = cfg;
	}
	return true;
}

// 获取星级配置
HeroStarCfg* CHeroCfgManager::GetHeroStarCfg(uint8 star)
{
	HeroStarCfgMapIt it = m_heroStarCfg.find(star);
	if (it != m_heroStarCfg.end())
		return &it->second;
	
	return NULL;
}

// 获取星级配置
BookStarCfg* CHeroCfgManager::GetBookStarCfg(uint8 star)
{
	BookStarCfgMapIt it = m_bookStarCfg.find(star);
	if (it != m_bookStarCfg.end())
		return &it->second;
	
	return NULL;
}

// 获取突破消耗
MultiCost* CHeroCfgManager::GetBreakCost(uint8 quality, uint8 breakLevel)
{
	QualityBreakCostMapIt qit = m_breakCost.find(breakLevel);
	if (qit == m_breakCost.end())
	{
		return NULL;
	}
	CostMap& costs = qit->second;

	CostMapIt cit = costs.find(quality);
	if (cit == costs.end())
	{
		return NULL;
	}
	return &cit->second;
}

// 获取修炼配置
XiuLianLevelCfg* CHeroCfgManager::GetXiulianCfg(uint8 xiulianLevel)
{
	XiuLianLevelCfgMapIt it = m_xiuLianLevelCfg.find(xiulianLevel);
	if (it == m_xiuLianLevelCfg.end())
		return NULL;
	
	return &it->second;
}

// 获取图鉴品质系数
double CHeroCfgManager::GetBookSumRatio(uint8 quality)
{
	U16tDblMapIt it = m_bookRatio.find(quality);
	if (it == m_bookRatio.end())
		return 0;
	
	return it->second;
}

// 获取图鉴进度id
uint8 CHeroCfgManager::GetBookLevel(uint32 score)
{
	for (BookLevelCfgMapIt it = m_bookCfg.begin(); it != m_bookCfg.end(); ++it)
	{
		BookLevelCfg& cfg = it->second;
		if (score >= cfg.starValue && score < cfg.endValue)
			return cfg.level - 1;
	}
	return 0;
}

// 获取当前等级属性
MultiAttr* CHeroCfgManager::GetBookLevelAttr(uint8 level)
{
	BookLevelCfg* cfg = GetBookLevelCfg(level);
	if (cfg == NULL)
		return NULL;
	
	return &cfg->curAttrs;
}

// 获取当前总属性
MultiAttr* CHeroCfgManager::GetBookLevelSumAttr(uint8 level)
{
	BookLevelCfg* cfg = GetBookLevelCfg(level);
	if (cfg == NULL)
		return NULL;
	
	return &cfg->curSumAttrs;
}

// 获取图鉴配置
BookLevelCfg* CHeroCfgManager::GetBookLevelCfg(uint8 level)
{
	if (level > m_bookCfg.size())
		level = m_bookCfg.size();
	BookLevelCfgMapIt it = m_bookCfg.find(level);
	if (it != m_bookCfg.end())
		return &it->second;
	
	return NULL;
}

XiuLianCfg *CHeroCfgManager::GetXiuLianCfg(uint8 level)
{
	XiuLianCfgMapIt it = m_xiuLianCfg.find(level);
	if (it == m_xiuLianCfg.end())
		return NULL;
	return &it->second;
}

// 获取精炼系数
double CHeroCfgManager::GetJingLianRatio(uint8 quality)
{
	U16tDblMapIt it = m_jlRatio.find(quality);
	if (it != m_jlRatio.end())
		return it->second;

	return 0;

}

double CHeroCfgManager::GetQiangHuaRatio(uint8 quality)
{
	U16tDblMapIt it = m_qhRatio.find(quality);
	if (it != m_qhRatio.end())
		return it->second;
	return 0.0;
}

double CHeroCfgManager::GetFaBaoQiangHuaRatio(uint8 quality)
{
	U16tDblMapIt it = m_fbjlRatio.find(quality);
	if (it != m_fbjlRatio.end())
		return it->second;
	return 0.0;
}

uint8 CHeroCfgManager::GetBreakLvCond(uint8 lv)
{
	U8tU8MapIt it = m_breakLvCond.find(lv);
	if (it != m_breakLvCond.end())
		return it->second;
	return 0;
}

uint16 CHeroCfgManager::GetBreakAttrAdd(uint8 lv)
{
	U8tU16MapIt it = m_breakAttrAdd.find(lv);
	if (it != m_breakAttrAdd.end())
		return it->second;
	return 0;
}

UserBook::UserBook()
	: m_bookScore(0)
	, m_level(0)
{
	m_bookAttrs.clear();
	m_bookScoreAttrs.clear();
	m_heroScores.clear();
}

UserBook::~UserBook()
{
	m_bookAttrs.clear();
	m_bookScoreAttrs.clear();
	m_heroScores.clear();
}

// 数据保存
void UserBook::SaveData(string &str)
{
	int pos = 0;
	uint8 data[1024*10] = {0};
	
	// 挑战次数
	data[pos++] = m_heroScores.size();
	for (HeroBookSocreMapIt bit = m_heroScores.begin(); bit != m_heroScores.end(); ++bit)
	{
		pos = CopyDataToBuf((char *)data, &bit->first, sizeof(bit->first), pos);
		data[pos++] = bit->second.star;
	}
	Compress(data, pos, str);
}

// 数据加载
void UserBook::LoadData(const char *str)
{
	if (str == NULL || strlen(str) == 0)
		return;
	uint32 len = 1024*10;
	uint8 data[1024*10];
	int pos = 0;
	if (!UnCompress(str, data, len))
		return;

	CHeroCfgManager& mgr = sCHeroCfgManager;
	// 挑战次数
	uint8 nSize = data[pos++];
	for (uint8 ni = 0; ni < nSize; ++ni)
	{
		uint16 heroId = 0;
		SingleBookSocre score;
		pos = ReadDataFromBuf((char *)data, &heroId, sizeof(heroId), pos);
		score.star = data[pos++];
		
		BookStarCfg* bcfg = mgr.GetBookStarCfg(score.star);
		if (bcfg == NULL)
			continue;
		
		SPetBasicData* pHeroCfg = SingletonCPetCfgMgr::instance().GetPetCfg(heroId);
		if (pHeroCfg == NULL)
			continue;
		score.curScore = bcfg->GetSumScore(pHeroCfg->quality);
		m_bookScore += score.curScore;
		m_heroScores[heroId] = score;
		
		double ratio = mgr.GetBookSumRatio(pHeroCfg->quality);
		uint32 sSum = bcfg->bookAttrSum * ratio;
		MultiAttr starAttr;
		SAttrData data;
		data.attrType = EAT_Attack;
		data.attrValue = sSum * pHeroCfg->attackCZ;
		starAttr.push_back(data);
		data.attrType = EAT_WuFang;
		data.attrValue = sSum * pHeroCfg->wufangCZ;
		starAttr.push_back(data);
		data.attrType = EAT_FaFang;
		data.attrValue = sSum * pHeroCfg->fafangCZ;
		starAttr.push_back(data);
		data.attrType = EAT_QiXue;
		data.attrValue = sSum * pHeroCfg->qixueCZ;
		starAttr.push_back(data);
		MergeAttrList(m_bookAttrs, starAttr);
	}
	m_level = mgr.GetBookLevel(m_bookScore);
	MultiAttr* scoreAttr = mgr.GetBookLevelSumAttr(m_level);
	if (scoreAttr != NULL)
		m_bookScoreAttrs = *scoreAttr;
}


// 获取当前属性
const MultiAttr& UserBook::GetBookAttr()
{
	return m_bookAttrs;
}

void UserBook::GetBookAttr(MultiAttr& allAttr)
{
	MergeAttrList(allAttr, m_bookAttrs);
	MergeAttrList(allAttr, m_bookScoreAttrs);
}

// 获取图鉴信息
bool UserBook::GetBookMsg(CNetMessage& msg)
{
	BookLevelCfg* cfg = sCHeroCfgManager.GetBookLevelCfg(m_level + 1);
	if (cfg == NULL)
		return false;
	msg << m_level << m_bookScore << cfg->starValue << cfg->endValue;
	msg << (uint8)m_heroScores.size();
	for (HeroBookSocreMapIt it = m_heroScores.begin(); it != m_heroScores.end(); ++it)
	{
		msg << it->first << it->second.star << it->second.curScore;
	}
	msg << (uint8)m_bookAttrs.size();
	for (size_t i = 0; i < m_bookAttrs.size(); ++i)
	{
		SAttrData& attr = m_bookAttrs[i];
		msg << attr.attrType << attr.attrValue;
	}
	msg << (uint8)m_bookScoreAttrs.size();
	for (size_t i = 0; i < m_bookScoreAttrs.size(); ++i)
	{
		SAttrData& attr = m_bookScoreAttrs[i];
		msg << attr.attrType << attr.attrValue;
	}
	return false;
}

// 升级图鉴
bool UserBook::BookStarLevelUp(CUser* pUser, CNetMessage& msg)
{
	uint16 hero = 0;
	uint8 curStar = 0;
	msg >> hero;
	if (hero == 0)
		return false;
	HeroBookSocreMapIt bit = m_heroScores.find(hero);
	if (bit != m_heroScores.end())
		curStar = bit->second.star;

	BookStarCfg* bcfg = sCHeroCfgManager.GetBookStarCfg(++curStar);
	if (bcfg == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0170, TIPS_FAILURE_COLOR);
		return true;
	}
	
	SPetBasicData* pHeroCfg = SingletonCPetCfgMgr::instance().GetPetCfg(hero);
	if (pHeroCfg == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_SSJ_0424, TIPS_FAILURE_COLOR);
		return true;
	}
	if (curStar == 1)
		sCMissionManager.UpdateQuestState(pUser, EMQCT_50, 1, pHeroCfg->quality);
	if (curStar != 1)
	{
		if (curStar > sCHeroCfgManager.GetMaxStar())
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_SSJ_0416, TIPS_FAILURE_COLOR);
			return true;
		}
		SCostData* cost = bcfg->GetCost(pHeroCfg->quality);
		if (cost == NULL)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_SSJ_0416, TIPS_FAILURE_COLOR);
			return true;
		}

		SPet *pPet = pUser->GetPet(hero).get();
		if (pPet == NULL)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_SSJ_0424, TIPS_FAILURE_COLOR);
			return true;
		}

		if (pPet->star < bcfg->condLevel)
		{
			char buf[128];
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0171, bcfg->condLevel);
			msg << PRO_ERROR << MakeStringColor(buf, TIPS_FAILURE_COLOR);
			return true;
		}

		if (pUser->GetItemNum(cost->costType) < cost->costValue)
		{
			char buf[128];
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0172, GetItemName(cost->costType));
			msg << PRO_ERROR << MakeStringColor(buf, TIPS_FAILURE_COLOR);
			return true;
		}

		if (!pUser->DelPackageById(cost->costType, cost->costValue))
		{
			cout << "error user " << pUser->GetRoleId() << " del item " << GetItemName(cost->costType) << " count " << cost->costValue << "faild!!!" << endl;
		}
	}
	
	SingleBookSocre scroe;
	scroe.star = curStar;
	scroe.curScore = bcfg->GetSumScore(pHeroCfg->quality);
	m_heroScores[hero] = scroe;
	double ratio = sCHeroCfgManager.GetBookSumRatio(pHeroCfg->quality);
	double cratio = bcfg->bookAttr * ratio;
	MultiAttr starAttr;
	SAttrData data;
	data.attrType = EAT_Attack;
	data.attrValue = cratio * pHeroCfg->attackCZ;
	starAttr.push_back(data);
	data.attrType = EAT_WuFang;
	data.attrValue = cratio * pHeroCfg->wufangCZ;
	starAttr.push_back(data);
	data.attrType = EAT_FaFang;
	data.attrValue = cratio * pHeroCfg->fafangCZ;
	starAttr.push_back(data);
	data.attrType = EAT_QiXue;
	data.attrValue = cratio * pHeroCfg->qixueCZ;
	starAttr.push_back(data);
	
	MergeAttrList(m_bookAttrs, starAttr);
	uint16 addSocre = bcfg->GetScore(pHeroCfg->quality);
	m_bookScore += addSocre;
	uint16 level = sCHeroCfgManager.GetBookLevel(m_bookScore);
	msg << PRO_SUCCESS << curStar << addSocre << level;
	MakeMultiAttrMsg(starAttr, msg);
	if (level > m_level)
	{
		for (m_level = m_level + 1; m_level <= level; ++m_level)
		{
			MultiAttr* curAttr = sCHeroCfgManager.GetBookLevelAttr(m_level);
			if (curAttr != NULL)
			{
				MergeAttrList(m_bookScoreAttrs, *curAttr);
				MakeMultiAttrMsg(*curAttr, msg);
			}
		}
		m_level = level;
	}
	sCMissionManager.UpdateQuestState(pUser, EMQCT_52, m_bookScore);

	pUser->InitChuZhanPet();
	pUser->ResetPower();
	pUser->SendUpdateInfo(EUUT_TotalZhanDouLi);
	SingletonCRankMgr::instance().UpdateData(CRankMgr::ERT_BookScore, pUser->GetRoleId(), m_bookScore);
	return true;
}

void UserBook::SendTuJianHotPointStatus(CUser* pUser)
{
	uint8 state = 0;
	do
	{
		CPetCfgManager& pmgr = sCPetCfgManager;
		CHeroCfgManager& hmgr = sCHeroCfgManager;

		map<uint16, SPetBasicData>& cfgs = pmgr.GetAllCfg();
		for (map<uint16, SPetBasicData>::iterator bcit = cfgs.begin(); bcit != cfgs.end(); ++bcit)
		{
			uint16 heroId = bcit->first;
			SPetBasicData& hcfg = bcit->second;
			uint8 curStar = 0;
			HeroBookSocreMapIt bit = m_heroScores.find(heroId);
			if (bit != m_heroScores.end())
				curStar = bit->second.star;

			SPet *pPet = pUser->GetPet(heroId).get();
			if (pPet == NULL)
				continue;

			if (curStar == 0)
			{
				state = 1;
				continue;
			}

			BookStarCfg* bcfg = hmgr.GetBookStarCfg(++curStar);
			if (bcfg == NULL)
				continue;
			if (curStar > hmgr.GetMaxStar())
				continue;
			SCostData* cost = bcfg->GetCost(hcfg.quality);
			if (cost == NULL)
				continue;

			if (pPet->star < bcfg->condLevel)
				continue;

			if (pUser->GetItemNum(cost->costType) < cost->costValue)
				continue;

			state = 1;
			break;
		}
	} while (false);
	SendHotPointStatus(pUser, EHPoint_TuJian, state);
}
