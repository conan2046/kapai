#include "blood_fight_manage.h"
#include "rapidjson/document.h"
#include "init.h"
#include "utility.h"
#include "user.h"
#include "pet.h"
#include "fight.h"
#include "rank.h"
#include "user_shop_manage.h"
#include <math.h>

CBloodFightCfgManager::CBloodFightCfgManager()
{
}

CBloodFightCfgManager::~CBloodFightCfgManager()
{
}

bool CBloodFightCfgManager::InitBloodFightCfg()
{
	return InitBloodNodeCfg()
		&& InitBloodBuffCfg()
		&& InitBloodFormationCfg()
		&& InitBloodCntCfg()
		&& InitChapterAllAward();
}

bool CBloodFightCfgManager::InitBloodNodeCfg()
{
	const string file = "blood_battle.json";
	//                            0    1             2            3             4               5              6
	const char* titleArrs[] = { "id", "chapter", "arrays_id", "attr_ratio", "condition", "first_reward", "reward_fixed" };
	const int typeArrs[] = { 0, 0, 2, 0, 2, 2, 2 };  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "CHeroCfgManager::InitBloodNodeCfg >> LoadJosnValue error " << endl;
		return false;
	}
	m_maxNodeId = 0;
	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		BloodNodeCfg cfg;
		uint16 id = data[titleArrs[0]].GetInt();
		cfg.chapterId = data[titleArrs[1]].GetInt();
		const rapidjson::Value &_arr = data[titleArrs[2]];
		if (!_arr.IsArray() || _arr.Size() != 3)
			continue;
		cfg.easyId = _arr[0].GetInt();
		cfg.normalId = _arr[1].GetInt();
		cfg.hardId = _arr[2].GetInt();
		cfg.ratio = data[titleArrs[3]].GetInt() / 10000.0;

		const rapidjson::Value &condArr = data[titleArrs[4]];
		if (!condArr.IsArray())
			continue;

		for (uint8 ci = 0; ci < condArr.Size(); ++ci)
		{
			const rapidjson::Value &cond = condArr[ci];
			if (!cond.IsArray() || cond.Size() != 2)
				continue;
			SFightEndData tv;
			tv.type = cond[0].GetInt();
			tv.value = cond[1].GetInt();
			cfg.conds.push_back(tv);
		}

		ReadMultiAward(data[titleArrs[5]], cfg.awards);

		const rapidjson::Value &fixArr = data[titleArrs[6]];
		if (!fixArr.IsArray())
			continue;
		U8tU32Map fixs;
		for (uint8 ci = 0; ci < fixArr.Size(); ++ci)
		{
			const rapidjson::Value &fix = fixArr[ci];
			if (!fix.IsArray() || fix.Size() != 2)
				continue;
			uint8 type = fix[0].GetInt();
			uint16 value = fix[1].GetInt();
			fixs[type] = value;
		}
		BloodChapter* cb = GetBloodChapterCfg(cfg.chapterId);
		if (cb == NULL)
		{
			BloodChapter ncb;
			if (!fixs.empty())
				ncb.fixIds[id] = fixs;
			ncb.nodes[id] = cfg;
			m_chapterBloodCfgs[cfg.chapterId] = ncb;
		}
		else
		{
			cb->nodes[id] = cfg;
			if (!fixs.empty())
				cb->fixIds[id] = fixs;
		}
		m_firstNodes.insert(make_pair(cfg.chapterId, id));
		m_nodeChapter[id] = cfg.chapterId;
		if (id > m_maxNodeId)
			m_maxNodeId = id;
	}
	return true;
}

bool CBloodFightCfgManager::InitBloodBuffCfg()
{
	const string file = "blood_buff.json";
	//                            0         1             2          3        4
	const char* titleArrs[] = { "id", "buff_arrays", "buff_value", "cost", "weight" };
	const int typeArrs[] = { 0, 0, 2, 0, 0 };  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "CHeroCfgManager::InitBloodBuffCfg >> LoadJosnValue error " << endl;
		return false;
	}

	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		BloodBuff cfg;
		cfg.buffId = data[titleArrs[0]].GetInt();
		uint8 type = data[titleArrs[1]].GetInt();
		const rapidjson::Value &_arr = data[titleArrs[2]];
		if (!_arr.IsArray() || _arr.Size() != 2)
			continue;
		cfg.attr.attrType = _arr[0].GetInt();
		cfg.attr.attrValue = _arr[1].GetInt();
		cfg.jiage = data[titleArrs[3]].GetInt();
		uint16 weight = data[titleArrs[4]].GetInt();

		BloodTypeBuffMapIt it = m_allBuff.find(type);
		if (it == m_allBuff.end())
		{
			BloodTypeBuffs buffs;
			buffs.sumWeight = weight;
			buffs.buffWeight[cfg.buffId] = buffs.sumWeight;
			m_allBuff[type] = buffs;
		}
		else
		{
			BloodTypeBuffs& buffs = it->second;
			buffs.sumWeight += weight;
			buffs.buffWeight[cfg.buffId] = buffs.sumWeight;
		}
		m_bloodBuffs[cfg.buffId] = cfg;
	}
	return true;
}

bool CBloodFightCfgManager::InitBloodFormationCfg()
{
	const string file = "blood_arrays.json";
	//                             0       1         2        3        4          5        6           7        8      9
	const char* titleArrs[] = { "type", "weight", "zhenfa", "show", "index1", "index2", "index3", "index4", "index5", "id" };
	const int typeArrs[] = { 0, 0, 0, 0, 0, 0, 0, 0, 0 };  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "CHeroCfgManager::InitBloodFormationCfg >> LoadJosnValue error " << endl;
		return false;
	}

	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		uint16 fid = data[titleArrs[9]].GetInt();
		uint8 type = data[titleArrs[0]].GetInt();
		BloodFight cfg;
		uint16 weight = data[titleArrs[1]].GetInt();
		cfg.formation = data[titleArrs[2]].GetInt();
		cfg.show = data[titleArrs[3]].GetInt();

		for (uint8 ii = 0; ii < 5; ++ii)
		{
			uint16 monster = data[titleArrs[4+ii]].GetInt();
			cfg.monster.push_back(monster);
		}

		BloodTypeFightMapIt it = m_allFights.find(type);
		if (it == m_allFights.end())
		{
			BloodTypeFights fights;
			fights.sumWeight = weight;
			fights.fightWeight[fid] = fights.sumWeight;
			m_allFights[type] = fights;
		}
		else
		{
			BloodTypeFights& fights = it->second;
			fights.sumWeight += weight;
			fights.fightWeight[fid] = fights.sumWeight;
		}
		m_bloodFights[fid] = cfg;
	}
	return true;
}

bool CBloodFightCfgManager::InitBloodCntCfg()
{
	const string file = "blood_chapter.json";
	//                             0           1                2
	const char* titleArrs[] = { "id", "challenge_time", "revive_time" };
	const int typeArrs[] = { 0, 0, 0 };  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "CHeroCfgManager::InitBloodCntCfg >> LoadJosnValue error " << endl;
		return false;
	}

	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		uint8 type = data[titleArrs[0]].GetInt();
		BloodCntCfg cfg;
		cfg.tryTimes = data[titleArrs[1]].GetInt();
		cfg.fuhuoTimes = data[titleArrs[2]].GetInt();
		m_bloodCnts[type] = cfg;
	}
	return true;
}

bool CBloodFightCfgManager::InitChapterAllAward()
{
	for (ChapterBloodCfgMapIt it = m_chapterBloodCfgs.begin(); it != m_chapterBloodCfgs.end(); ++it)
	{
		MultiAward maward;
		map<uint16, U8tU32Map>& fixIds = it->second.fixIds;
		for (map<uint16, U8tU32Map>::iterator fit = fixIds.begin(); fit != fixIds.end(); ++fit)
		{
			U8tU32Map& fids = fit->second;
			for (U8tU32MapIt fiit = fids.begin(); fiit != fids.end(); ++fiit)
			{
				MultiAward* ad = sCGuanQiaCfgMgr.QueryFixAward(fiit->second);
				if (ad != NULL)
				{
					MergeAwardList(maward, *ad);
				}
			}
		}
		m_chapterAllAwards[it->first] = maward;
	}
	return true;
}

uint16 BloodTypeBuffs::GetBuffId()
{
	int rd = Random(0, sumWeight);
	for (U16tU16MapIt si = buffWeight.begin(); si != buffWeight.end(); ++si)
	{
		if (rd <= (int)si->second)
		{
			return si->first;
		}
	}
	return 0;
}

uint16 BloodTypeFights::GetFightId()
{
	int rd = Random(0, sumWeight);
	for (U16tU16MapIt si = fightWeight.begin(); si != fightWeight.end(); ++si)
	{
		if (rd <= (int)si->second)
		{
			return si->first;
		}
	}
	return 0;
}

uint16 CBloodFightCfgManager::GetBloodNodeChpterId(uint16 nodeId)
{
	U16tU8MapIt it = m_nodeChapter.find(nodeId);
	if (it == m_nodeChapter.end())
		return 0;

	return it->second;
}

BloodChapter* CBloodFightCfgManager::GetBloodChapterCfg(uint8 chapter)
{
	ChapterBloodCfgMapIt it = m_chapterBloodCfgs.find(chapter);
	if (it == m_chapterBloodCfgs.end())
		return NULL;

	return &it->second;
}

uint16 CBloodFightCfgManager::GetChapterFirstNode(uint8 chapter)
{
	U16tU16MapIt it = m_firstNodes.find(chapter);
	if (it == m_firstNodes.end())
		return 0;

	return it->second;
}

BloodNodeCfg* CBloodFightCfgManager::GetBloodNodeCfg(uint16 nodeId)
{
	do 
	{
		uint8 cpid = GetBloodNodeChpterId(nodeId);
		if (cpid == 0)
			break;
		BloodChapter* bc = GetBloodChapterCfg(cpid);
		if (bc == NULL)
			break;

		BloodNodeCfgMapIt nit = bc->nodes.find(nodeId);
		if (nit == bc->nodes.end())
			break;
		return &nit->second;
	} while (false);

	return NULL;
}

void CBloodFightCfgManager::MakeBloodBuff(vector<BloodBuff>& buff)
{
	buff.clear();
	for (BloodTypeBuffMapIt it = m_allBuff.begin(); it != m_allBuff.end(); ++it)
	{
		uint16 buffId = it->second.GetBuffId();
		BloodBuff* buf = GetBloodBuffCfg(buffId);
		if (buf != NULL)
		{
			buff.push_back(*buf);
		}
	}
}


BloodBuff* CBloodFightCfgManager::GetBloodBuffCfg(uint16 buffId)
{
	BloodBuffMapIt it = m_bloodBuffs.find(buffId);
	if (it != m_bloodBuffs.end())
		return &it->second;
	return NULL;
}

BloodFight* CBloodFightCfgManager::GetBloodFightCfg(uint16 buffId)
{
	BloodFightMapIt it = m_bloodFights.find(buffId);
	if (it != m_bloodFights.end())
		return &it->second;
	return NULL;
}

U8tU32Map* CBloodFightCfgManager::GetBloodFixCfg(uint16 nodeId)
{
	do
	{
		uint8 cpid = GetBloodNodeChpterId(nodeId);
		if (cpid == 0)
			break;
		BloodChapter* bc = GetBloodChapterCfg(cpid);
		if (bc == NULL)
			break;

		map<uint16, U8tU32Map>::iterator it = bc->fixIds.find(nodeId);
		if (it == bc->fixIds.end())
			break;
		return &it->second;
	} while (false);
	return false;
}

MultiAward* CBloodFightCfgManager::GetBloodChaterAward(uint8 chapter)
{
	ChapterAllAwardMapIt it = m_chapterAllAwards.find(chapter);
	if (it == m_chapterAllAwards.end())
		return NULL;

	return &it->second;
}

BloodCntCfg* CBloodFightCfgManager::GetCntCfg(uint8 type)
{
	BloodTypeCntCfgMapIt it = m_bloodCnts.find(type);
	if (it == m_bloodCnts.end())
		return NULL;

	return &it->second;
}

uint16 CBloodFightCfgManager::MakeBloodFightId(uint8 type)
{
	BloodTypeFightMapIt it = m_allFights.find(type);
	if (it == m_allFights.end())
		return 0;

	return it->second.GetFightId();
}


//uint8 CBloodFightCfgManager::GetNodeChapter(uint16 nodeId)
//{
//	U16tU8MapIt it = m_nodeChapters.find(nodeId);
//	if (it == m_nodeChapters.end())
//		return 0;
//
//	return it->second;
//}


CUserBloodFight::CUserBloodFight()
{
}

CUserBloodFight::~CUserBloodFight()
{
}

void CUserBloodFight::SaveData(string & str)
{
	int pos = 0;
	uint8 data[1024 * 10] = { 0 };

	data[pos++] = m_tryTimes;
	data[pos++] = m_fuhuoTimes;
	data[pos++] = m_state;
	data[pos++] = m_rankState;
	data[pos++] = m_curChapter;
	data[pos++] = m_bufIdx;
	data[pos++] = m_fiveStar;
	data[pos++] = m_SltIdx;
	pos = CopyDataToBuf((char *)data, &m_SltSet, sizeof(m_SltSet), pos);
	pos = CopyDataToBuf((char *)data, &m_curNodeId, sizeof(m_curNodeId), pos);
	pos = CopyDataToBuf((char *)data, &m_maxHardNode, sizeof(m_maxHardNode), pos);
	pos = CopyDataToBuf((char *)data, &m_todayMaxNode, sizeof(m_todayMaxNode), pos);
	pos = CopyDataToBuf((char *)data, &m_highStar, sizeof(m_highStar), pos);
	pos = CopyDataToBuf((char *)data, &m_allStar, sizeof(m_allStar), pos);
	pos = CopyDataToBuf((char *)data, &m_curStar, sizeof(m_curStar), pos);
	pos = CopyDataToBuf((char *)data, &m_todayMaxStar, sizeof(m_todayMaxStar), pos);
	pos = CopyDataToBuf((char *)data, &m_firstAward, sizeof(m_firstAward), pos);

	pos = CopyDataToBuf((char *)data, &m_easyFight, sizeof(m_easyFight), pos);
	pos = CopyDataToBuf((char *)data, &m_normalFight, sizeof(m_normalFight), pos);
	pos = CopyDataToBuf((char *)data, &m_hardFight, sizeof(m_hardFight), pos);
	data[pos++] = m_sltBuff.size();
	for (size_t bi = 0; bi < m_sltBuff.size(); ++bi)
	{
		BloodBuff& buff = m_sltBuff[bi];
		pos = CopyDataToBuf((char *)data, &buff.buffId, sizeof(buff.buffId), pos);
	}
	data[pos++] = m_buffs.size();
	for (size_t bi = 0; bi < m_buffs.size(); ++bi)
	{
		SAttrData& buff = m_buffs[bi];
		pos = CopyDataToBuf((char *)data, &buff.attrType, sizeof(buff.attrType), pos);
		pos = CopyDataToBuf((char *)data, &buff.attrValue, sizeof(buff.attrValue), pos);
	}
	data[pos++] = m_normalAwards.size();
	for (NodeNormalAwardMapIt it = m_normalAwards.begin(); it != m_normalAwards.end(); ++it)
	{
		NodeNormalAward& ad = it->second;
		pos = CopyDataToBuf((char *)data, &it->first, sizeof(it->first), pos);
		data[pos++] = ad.star;
		data[pos++] = ad.getstate.size();
		for (U8tU8MapIt ait = ad.getstate.begin(); ait != ad.getstate.end(); ++ait)
		{
			data[pos++] = ait->first;
			data[pos++] = ait->second;
		}
	}
	Compress(data, pos, str);
}

void CUserBloodFight::LoadData(const char * str)
{
	if (str == NULL || strlen(str) == 0)
	{
		InitUserBloodFight();
		return;
	}
	uint32 len = 1024 * 10;
	uint8 data[1024 * 10];
	int pos = 0;
	if (!UnCompress(str, data, len))
		return;


	m_tryTimes = data[pos++];
	m_fuhuoTimes = data[pos++];
	m_state = data[pos++];
	m_rankState = data[pos++];
	m_curChapter = data[pos++];
	m_bufIdx = data[pos++];
	m_fiveStar = data[pos++];
	m_SltIdx = data[pos++];
	pos = ReadDataFromBuf((char *)data, &m_SltSet, sizeof(m_SltSet), pos);
	pos = ReadDataFromBuf((char *)data, &m_curNodeId, sizeof(m_curNodeId), pos);
	pos = ReadDataFromBuf((char *)data, &m_maxHardNode, sizeof(m_maxHardNode), pos);
	pos = ReadDataFromBuf((char *)data, &m_todayMaxNode, sizeof(m_todayMaxNode), pos);
	pos = ReadDataFromBuf((char *)data, &m_highStar, sizeof(m_highStar), pos);
	pos = ReadDataFromBuf((char *)data, &m_allStar, sizeof(m_allStar), pos);
	pos = ReadDataFromBuf((char *)data, &m_curStar, sizeof(m_curStar), pos);
	pos = ReadDataFromBuf((char *)data, &m_todayMaxStar, sizeof(m_todayMaxStar), pos);
	pos = ReadDataFromBuf((char *)data, &m_firstAward, sizeof(m_firstAward), pos);

	pos = ReadDataFromBuf((char *)data, &m_easyFight, sizeof(m_easyFight), pos);
	pos = ReadDataFromBuf((char *)data, &m_normalFight, sizeof(m_normalFight), pos);
	pos = ReadDataFromBuf((char *)data, &m_hardFight, sizeof(m_hardFight), pos);

	uint8 bsize = data[pos++];
	for (uint8 bi = 0; bi < bsize; ++bi)
	{
		uint16 buffId;
		pos = ReadDataFromBuf((char *)data, &buffId, sizeof(buffId), pos);
		BloodBuff* buff = sCBloodFightCfgManager.GetBloodBuffCfg(buffId);
		if (buff != NULL)
			m_sltBuff.push_back(*buff);
	}

	bsize = data[pos++];
	for (uint8 bi = 0; bi < bsize; ++bi)
	{
		SAttrData buff;
		pos = ReadDataFromBuf((char *)data, &buff.attrType, sizeof(buff.attrType), pos);
		pos = ReadDataFromBuf((char *)data, &buff.attrValue, sizeof(buff.attrValue), pos);
		m_buffs.push_back(buff);
	}

	uint8 asize = data[pos++];
	for (uint8 ai = 0; ai < asize; ++ai)
	{
		NodeNormalAward ad;
		uint16 nodeId;
		pos = ReadDataFromBuf((char *)data, &nodeId, sizeof(nodeId), pos);
		ad.star = data[pos++];
		uint8 ssize = data[pos++];
		for (uint8 si = 0; si < ssize; ++si)
		{
			uint8 star = data[pos++];
			uint8 state = data[pos++];
			ad.getstate[star] = state;
		}
		m_normalAwards[nodeId] = ad;
	}
	BloodNodeCfg* bcfg = sCBloodFightCfgManager.GetBloodNodeCfg(m_curNodeId);
	if (bcfg == NULL)
		return;
	m_curChapter = bcfg->chapterId;
}

void CUserBloodFight::InitUserBloodFight()
{
	CBloodFightCfgManager& mgr = sCBloodFightCfgManager;
	m_curNodeId = mgr.GetChapterFirstNode(1);
	BloodNodeCfg* bcfg = mgr.GetBloodNodeCfg(m_curNodeId);
	if (bcfg == NULL)
		return;

	BloodCntCfg* ccfg = mgr.GetCntCfg(bcfg->chapterId);
	if (ccfg == NULL)
		return;

	m_tryTimes = ccfg->tryTimes;
	m_fuhuoTimes = ccfg->fuhuoTimes;
	m_state = BS_Ready;
	m_curChapter = bcfg->chapterId;
	m_maxHardNode = 0;
	m_rankState = 0;
	m_highStar = 0;
	m_allStar = 0;
	m_curStar = 0;
	m_todayMaxStar = 0;
	m_todayMaxNode = 0;
	m_firstAward = 0;
	m_easyFight = 0;
	m_normalFight = 0;
	m_hardFight = 0;
	m_buffs.clear();
	m_normalAwards.clear();
	m_SltIdx = 0;
	m_fiveStar = 0;
	m_SltSet = -1;
}

void CUserBloodFight::ResetUserBloodFight()
{
	if (m_tryTimes == 0)
		return;
	CBloodFightCfgManager& mgr = sCBloodFightCfgManager;
	m_curNodeId = mgr.GetChapterFirstNode(m_curChapter);
	BloodNodeCfg* bcfg = mgr.GetBloodNodeCfg(m_curChapter);
	if (bcfg == NULL)
		return;
	m_state = BS_Ready;
	m_allStar = (m_curChapter - 1) * 900;
	m_curStar = 0;
	m_conds = bcfg->conds;
	m_buffs.clear();
	m_easyFight = 0;
	m_normalFight = 0;
	m_hardFight = 0;
	m_SltIdx = 0;
	m_sltBuff.clear();
	m_fiveStar = 0;
}

void CUserBloodFight::NewUserBloodFight()
{
	CBloodFightCfgManager& mgr = sCBloodFightCfgManager;
	static uint16 maxNodeId = 0;
	if (maxNodeId == 0)
	{
		maxNodeId = mgr.GetMaxNodeId();
	}
	uint16 nexHardNode = m_maxHardNode == maxNodeId ? m_maxHardNode : m_maxHardNode + 1;
	BloodNodeCfg* bcfg = mgr.GetBloodNodeCfg(nexHardNode);
	if (bcfg == NULL)
		return;

	BloodCntCfg* ccfg = mgr.GetCntCfg(bcfg->chapterId);
	if (ccfg == NULL)
		return;

	m_curChapter = bcfg->chapterId;
	m_tryTimes = ccfg->tryTimes;
	m_fuhuoTimes = ccfg->fuhuoTimes;
	m_rankState = 0;
	m_allStar = (m_curChapter - 1) * 900;
	m_curStar = 0;
	m_todayMaxStar = 0;
	m_buffs.clear();
	m_normalAwards.clear();
	m_curNodeId = mgr.GetChapterFirstNode(m_curChapter);
	m_easyFight = 0;
	m_normalFight = 0;
	m_hardFight = 0;
	m_todayMaxNode = 0;
	m_SltIdx = 0;
	m_sltBuff.clear();
	m_fiveStar = 0;
	m_state = BS_Ready;
}

bool CUserBloodFight::IsTry()
{
	BloodCntCfg* ccfg = sCBloodFightCfgManager.GetCntCfg(m_curChapter);
	if (ccfg == NULL)
		return false;

	return m_tryTimes != ccfg->tryTimes;
}

void CUserBloodFight::GetBloodMsg(CUser* pUser, CNetMessage& msg)
{
	BloodCntCfg* ccfg = sCBloodFightCfgManager.GetCntCfg(m_curChapter);
	if (ccfg == NULL)
		return;

	if (m_tryTimes == ccfg->tryTimes && m_rankState == 0)
	{
		// 昨日奖励
		uint32 rank = SingletonCRankMgr::instance().GetRankIdx(CRankMgr::ERT_Blood_Yesterday, pUser->GetRoleId());
		if (rank == 0)
			m_rankState = 1;
	}
	msg << m_tryTimes << m_fuhuoTimes << m_state << m_rankState << m_curChapter
		<< m_curNodeId << m_maxHardNode << m_todayMaxNode  << m_highStar << m_allStar << m_todayMaxStar
		<< m_curStar << m_firstAward << m_easyFight << m_normalFight << m_hardFight;

	msg << m_SltSet << m_SltIdx << (uint8)m_sltBuff.size();
	for (uint8 i = 0; i < m_sltBuff.size(); ++i)
	{
		msg << m_sltBuff[i].jiage;
		m_sltBuff[i].attr.MakeMsg(msg);
	}

	msg << (uint8)m_buffs.size();
	for (uint8 i = 0; i < m_buffs.size(); ++i)
	{
		m_buffs[i].MakeMsg(msg);
	}
	uint16 aNodeId = ceil(m_curNodeId / 5.0) * 5;
	msg << aNodeId;
	NodeNormalAwardMapIt nit = m_normalAwards.find(aNodeId);
	if (nit == m_normalAwards.end())
	{
		msg << 0;
	}
	else
	{
		msg << nit->second.star << (uint8)nit->second.getstate.size();
		for (U8tU8MapIt sit = nit->second.getstate.begin(); sit != nit->second.getstate.end(); ++sit)
		{
			msg << sit->first << sit->second;
		}
	}
}

void CUserBloodFight::SendBFHotPointStatus(CUser* pUser)
{
	BloodCntCfg* ccfg = sCBloodFightCfgManager.GetCntCfg(m_curChapter);
	if (ccfg == NULL)
		return;

	if (m_tryTimes == ccfg->tryTimes && m_rankState == 0)
	{
		// 昨日奖励
		uint32 rank = SingletonCRankMgr::instance().GetRankIdx(CRankMgr::ERT_Blood_Yesterday, pUser->GetRoleId());
		if (rank == 0)
			m_rankState = 1;
	}
	SendHotPointStatus(pUser, EHPoint_XueZhan, m_rankState != 1);
}

void CUserBloodFight::GetFiveFixMsg(CUser* pUser, CNetMessage& msg)
{
	uint16 nodeId;
	msg >> nodeId;
	NodeNormalAwardMapIt nit = m_normalAwards.find(nodeId);
	if (nit == m_normalAwards.end())
	{
		msg << 0;
	}
	else
	{
		msg << nit->second.star << (uint8)nit->second.getstate.size();
		for (U8tU8MapIt sit = nit->second.getstate.begin(); sit != nit->second.getstate.end(); ++sit)
		{
			msg << sit->first << sit->second;
		}
	}
}

void CUserBloodFight::TrapCurFightMsg(CUser *pUser)
{
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_BLOOD_FIGHT);
	msg << (uint8)2;
	msg << m_curNodeId << m_easyFight << m_normalFight << m_hardFight;
	msg << (uint8)m_conds.size();
	for (uint8 i = 0; i < m_conds.size(); ++i)
	{
		msg << (uint16)m_conds[i].type << m_conds[i].value;
	}
	SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
}

void CUserBloodFight::MakeFight()
{
	CBloodFightCfgManager& mgr = sCBloodFightCfgManager;
	BloodNodeCfg* cfg = mgr.GetBloodNodeCfg(m_curNodeId);
	if (cfg == NULL)
		return;
	m_easyFight = mgr.MakeBloodFightId(cfg->easyId);
	m_normalFight = mgr.MakeBloodFightId(cfg->normalId);
	m_hardFight = mgr.MakeBloodFightId(cfg->hardId);
	m_conds = cfg->conds;
	m_state = BS_Fight;
}

NodeNormalAward& CUserBloodFight::GetFiveAwardState(uint16 nodeId)
{
	uint16 anid = ceil(nodeId / 5) * 5;
	NodeNormalAwardMapIt it = m_normalAwards.find(anid);
	if (it != m_normalAwards.end())
		return it->second;

	NodeNormalAward ad;
	ad.star = 0;
	U8tU32Map* fixs = sCBloodFightCfgManager.GetBloodFixCfg(anid);
	if (fixs != NULL)
	{
		for (U8tU32MapIt it = fixs->begin(); it != fixs->end(); ++it)
		{
			ad.getstate[it->first] = 0;
		}
	}
	m_normalAwards[anid] = ad;
	return GetFiveAwardState(nodeId);
}

void CUserBloodFight::TryBloodFight(CUser* pUser, CNetMessage& msg)
{
	uint8 type;
	msg >> type;
	if (m_state == BS_Dead || m_state == BS_DeadEnd)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0244, TIPS_FAILURE_COLOR);
		return;
	}

	if (!m_sltBuff.empty())
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0191, TIPS_FAILURE_COLOR);
		return;
	}
	BloodFight* cfg = NULL;
	switch (type)
	{
	case 1:
		cfg = sCBloodFightCfgManager.GetBloodFightCfg(m_easyFight);
		break;

	case 2:
		cfg = sCBloodFightCfgManager.GetBloodFightCfg(m_normalFight);
		break;

	case 3:
		cfg = sCBloodFightCfgManager.GetBloodFightCfg(m_hardFight);
		break;

	default:
		return;
	}
	if (cfg == NULL)
		return;

	BloodNodeCfg* ncfg = sCBloodFightCfgManager.GetBloodNodeCfg(m_curNodeId);
	if (ncfg == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_80, TIPS_FAILURE_COLOR);
		return;
	}
	ShareFightPtr pFight = SingletonFightManager::instance().CreateFight();
	if (pFight.get() == NULL)
		return;
	
	m_curTryType = type;
	pFight->SetFightType(CFight::EFTBloodFight);
	ShareUserPtr ptrUser = SingletonOnlineUser::instance().GetUserByRoleId(pUser->GetRoleId());
	pFight->AddUserGroupToFight(ptrUser);
	pFight->AddGroupUnitsAttr(CFight::EGT_GROUP1, m_buffs);
	pFight->AddBloodFightMonster(*cfg, ncfg->ratio);
	pFight->SetFightEndCondition(ncfg->conds);
	SFastFightResult result;
	pFight->BeginFastFight(result, true, pUser->GetSock());
	if (result.win)
	{
		uint8 star = pFight->CalculateFightStar(CFight::EGT_GROUP1, result.win);
		BloodFightResult(pUser, star);
	}
	else
		BloodFightResult(pUser, 0);
	msg << PRO_SUCCESS;
}

void CUserBloodFight::BloodFightResult(CUser* pUser, uint8 star)
{
	if (star == 0)
	{
		m_state = BS_Dead;
		if (m_fuhuoTimes == 0)
			m_state = BS_DeadEnd;
		CNetMessage msg;
		msg.ReWrite();
		msg.SetType(MSG_BLOOD_FIGHT);
		msg << (uint8)8 << star << m_state;
		SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
		return;
	}
	sCMissionManager.UpdateQuestState(pUser, EMQCT_3, 1);
	CBloodFightCfgManager& mgr = sCBloodFightCfgManager;
	uint8 addstar = 3 * m_curTryType;
	AddStar(pUser, addstar);
	m_fiveStar += addstar;

	if (m_todayMaxNode < m_curNodeId)
		m_todayMaxNode = m_curNodeId;
	BloodNodeCfg* ncfg = mgr.GetBloodNodeCfg(m_curNodeId);
	if (ncfg == NULL)
		return;

	MultiAward firstAward;
	if (m_firstAward < m_curNodeId)
	{
		m_firstAward = m_curNodeId;
		MergeAwardList(firstAward, ncfg->awards);
		sCMissionManager.UpdateQuestState(pUser, EMQCT_33, m_firstAward);
		UserShopManager* shop = pUser->GetShop();
		if (shop != NULL)
			shop->SendShopHotPointStatus(pUser, 8);

		if (m_firstAward % 100 == 0)
		{
			char buf[128];
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0239, pUser->GetName(), m_curNodeId);
			SysInfoToAllUser(buf);
		}
	}

	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_BLOOD_FIGHT);
	msg << (uint8)8 << addstar << m_highStar << m_allStar << m_curStar << m_todayMaxStar << m_state
		<< m_firstAward;

	msg << m_fiveStar;
	U8tU32Map* fixs = mgr.GetBloodFixCfg(m_curNodeId);
	MultiAward fixAward;
	if (fixs != NULL)
	{
		NodeNormalAward& ad = GetFiveAwardState(m_curNodeId);
		ad.star = ad.star >= m_fiveStar ? ad.star : m_fiveStar;
		m_fiveStar = 0;
		msg << uint8(ad.getstate.size());
		for (U8tU32MapIt it = fixs->begin(); it != fixs->end(); ++it)
		{
			if (it->first <= ad.star)
			{
				U8tU8MapIt sit = ad.getstate.find(it->first);
				if (sit != ad.getstate.end() && sit->second == 0)
				{
					sit->second = 1;
					MultiAward* mad = sCGuanQiaCfgMgr.QueryFixAward(it->second);
					if (mad != NULL)
					{
						MergeAwardList(fixAward, *mad);
					}
					msg << it->first << uint8(1);
				}
				else
					msg << it->first << uint8(0);
			}
			else
			{
				ad.getstate[it->first] = 0;
				msg << it->first << uint8(0);
			}
		}
	}
	else
		msg << uint8(0);
	uint16 firstNodeId  = mgr.GetChapterFirstNode(m_curChapter);

	if ((m_curNodeId - firstNodeId + 1) % 3 == 0)
		mgr.MakeBloodBuff(m_sltBuff);
	else
		tryMakeNextBlood(pUser);
	msg << (uint8)m_sltBuff.size();
	for (uint8 i = 0; i < m_sltBuff.size(); ++i)
	{
		msg << m_sltBuff[i].jiage;
		m_sltBuff[i].attr.MakeMsg(msg);
	}
	SendAndMakeAwardMsg(pUser, firstAward, msg, false, MUT_XueZhanFirst);
	SendAndMakeAwardMsg(pUser, fixAward, msg, false, MUT_XueZhanFix);
	MakeFightEndMsg(pUser, star, msg);
	SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
	sCMissionManager.UpdateQuestState(pUser, EMQCT_44, m_allStar);

	if (m_curTryType == 3 && m_maxHardNode + 1 == m_curNodeId)
	{
		m_maxHardNode++;

		UserShopManager* shop = pUser->GetShop();
		if (shop != NULL)
			shop->SendShopHotPointStatus(pUser, 8);
		do
		{
			if (m_maxHardNode % 100 == 0)
			{
				BloodNodeCfg* bcfg = mgr.GetBloodNodeCfg(m_maxHardNode);
				if (bcfg == NULL)
					break;
				BloodCntCfg* pcfg = mgr.GetCntCfg(m_curChapter);
				if (pcfg == NULL)
					break;
				BloodCntCfg* ccfg = mgr.GetCntCfg(bcfg->chapterId);
				if (ccfg == NULL)
					break;
				m_curChapter = bcfg->chapterId;
				m_tryTimes += ccfg->tryTimes - pcfg->tryTimes;
				m_fuhuoTimes += ccfg->fuhuoTimes - pcfg->fuhuoTimes;
			}
		} while (false);
	}
}

void CUserBloodFight::NewBloodFight(CUser* pUser, CNetMessage& msg)
{
	if (m_tryTimes == 0 || m_state != BS_Ready || m_rankState == 0)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0189, TIPS_FAILURE_COLOR);
		return;
	}
	else
	{
		msg << PRO_SUCCESS;
	}
	m_state = BS_Fight;
	BloodCntCfg* ccfg = sCBloodFightCfgManager.GetCntCfg(m_curChapter);
	if (ccfg == NULL)
		return;
	if (m_tryTimes == ccfg->tryTimes)
	{
		CBloodFightCfgManager& mgr = sCBloodFightCfgManager;
		CGuanQiaCfgMgr& smgr = sCGuanQiaCfgMgr;
		if (m_curChapter > 1)
		{
			CNetMessage trap;
			trap.SetType(MSG_BLOOD_FIGHT);
			trap << (uint8)5 << (uint8)(m_curChapter - 1);
			for (uint8 i = 1; i < m_curChapter; ++i)
			{
				BloodChapter* bc = mgr.GetBloodChapterCfg(i);
				if (bc == NULL)
					continue;
				MultiAward award;
				map<uint16, U8tU32Map>& fixIds = bc->fixIds;
				for (map<uint16, U8tU32Map>::iterator fit = fixIds.begin(); fit != fixIds.end(); ++fit)
				{
					U8tU32Map* fixs = mgr.GetBloodFixCfg(fit->first);
					if (fixs == NULL)
						continue;
					for (U8tU32MapIt it = fixs->begin(); it != fixs->end(); ++it)
					{
						MultiAward* mad = smgr.QueryFixAward(it->second);
						if (mad != NULL)
							MergeAwardList(award, *mad);
					}
				}
				MakeMultiAwardMsg(award, trap);
				pUser->AddMultiAward(award, false, false, MUT_XueZhanFix);
			}
			SingletonSocket::instance().SendMsg(pUser->GetSock(), trap);
		}

	}
	m_tryTimes--;
	MakeFight();
	TrapCurFightMsg(pUser);
}

void CUserBloodFight::RetryBloodFight(CUser* pUser, CNetMessage& msg)
{
	if (m_state != BS_Dead && m_state != BS_End && m_state != BS_DeadEnd)
	{
		return;
	}
	if (m_tryTimes == 0)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0189, TIPS_FAILURE_COLOR);
		return;
	}
	ResetUserBloodFight();
	msg << PRO_SUCCESS << m_tryTimes;
}

void CUserBloodFight::ReviveBloodFight(CUser* pUser, CNetMessage& msg)
{
	uint8 type;
	msg >> type;
	if (m_state != BS_Dead)
	{
		return;
	}
	if (type == 2)
	{
		m_state = BS_DeadEnd;
	}
	else
	{
		if (m_fuhuoTimes == 0)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0188, TIPS_FAILURE_COLOR);
			return;
		}
		m_state = BS_Fight;
		m_fuhuoTimes--;
	}
	msg << PRO_SUCCESS << m_fuhuoTimes << m_state;
}

void CUserBloodFight::tryMakeNextBlood(CUser* pUser)
{
	if (!m_sltBuff.empty())
		return;

	static uint16 maxNodeId = 0;
	if (maxNodeId == 0)
	{
		maxNodeId = sCBloodFightCfgManager.GetMaxNodeId();
	}
	if (m_curNodeId < maxNodeId)
	{
		m_curNodeId++;

		if (m_curNodeId % 100 == 1)
		{
			m_buffs.clear();
			m_curStar = 0;
			m_SltIdx = 0;
		}
	}
	MakeFight();
	TrapCurFightMsg(pUser);
}

void CUserBloodFight::SendChapterAward(CUser *pUser)
{
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_BLOOD_FIGHT);
	msg << (uint8)9 << uint8(m_curChapter - 1);
	for (uint8 i = 0; i < m_curChapter; ++i)
	{
		MultiAward* awards = sCBloodFightCfgManager.GetBloodChaterAward(i);
		if (awards == NULL)
			return;

		msg << (uint8)awards->size();
		MakeMultiAwardMsg(*awards, msg);
		for (uint8 ai = 0; ai < awards->size(); ++ai)
		{
			SAwardData& ad = (*awards)[ai];
			pUser->AddMaterial(ad);
		}
	}
	SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
}

void CUserBloodFight::SendSaoDangBuff(CUser *pUser)
{
	CBloodFightCfgManager& mgr = sCBloodFightCfgManager;

	// 计算星
	uint8 nodeCnt = m_maxHardNode - m_curNodeId + 1;
	if (m_maxHardNode / 5 == m_curNodeId / 5)
		m_fiveStar += nodeCnt * 9;
	else
		m_fiveStar = m_maxHardNode % 5 * 9;
	AddStar(pUser, nodeCnt * 9);
	m_curNodeId = m_maxHardNode;

	if (m_todayMaxNode < m_curNodeId)
		m_todayMaxNode = m_curNodeId;
	uint8 maxIdx = nodeCnt / 3;
	if (m_SltIdx == maxIdx || maxIdx == 0)
		return;

	if (m_SltSet == -1) // 手动选
	{
		TrapSaoDangBuff(pUser);
		m_state = BS_SaoDangBuff;
		return;
	}

	for (size_t i = m_SltIdx + 1; i <= maxIdx; i++)
	{
		mgr.MakeBloodBuff(m_sltBuff);
		int bsize = m_sltBuff.size();
		if (bsize == 0) continue;
		uint32 subStar = (nodeCnt - i * 3) * 9;
		uint16 lessStar = m_curStar - subStar;
		if (m_SltSet == 0)
		{
			for (size_t j = m_sltBuff.size(); j > 0; --j)
			{
				if (m_sltBuff[j - 1].jiage <= lessStar)
				{
					AddToAttrList(m_buffs, m_sltBuff[j - 1].attr);
					m_curStar -= m_sltBuff[j - 1].jiage;
					break;
				}
			}
		}
		else
		{
			bool slt = false;
			for (size_t j = m_sltBuff.size(); j > 0; --j)
			{
				int state = m_SltSet & (1 << (m_sltBuff[j - 1].attr.attrType - 1));
				if (state != 0 && m_sltBuff[j - 1].jiage <= lessStar)
				{
					AddToAttrList(m_buffs, m_sltBuff[j - 1].attr);
					m_curStar -= m_sltBuff[j - 1].jiage;
					slt = true;
					break;
				}
			}
			if (!slt)
			{
				AddToAttrList(m_buffs, m_sltBuff[0].attr);
				m_curStar -= m_sltBuff[0].jiage;
				slt = true;
			}
		}
		m_sltBuff.clear();
	}
	m_SltIdx = maxIdx;
	TrapBuffAttr(pUser);
	tryMakeNextBlood(pUser);
}

void CUserBloodFight::TrapBuffAttr(CUser *pUser)
{
	CNetMessage msg;
	msg.SetType(MSG_BLOOD_FIGHT);
	msg << (uint8)12;
	msg << m_allStar << m_curStar << m_SltIdx;
	msg << (uint8)m_buffs.size();
	for (uint8 i = 0; i < m_buffs.size(); ++i)
	{
		msg << (uint16)m_buffs[i].attrType << m_buffs[i].attrValue;
	}
	SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
}

void CUserBloodFight::TrapSaoDangBuff(CUser *pUser)
{
	CNetMessage msg;
	msg.SetType(MSG_BLOOD_FIGHT);
	CBloodFightCfgManager& mgr = sCBloodFightCfgManager;
	mgr.MakeBloodBuff(m_sltBuff);
	msg << (uint8)13 << m_SltIdx << (uint8)m_sltBuff.size();
	for (uint8 i = 0; i < m_sltBuff.size(); ++i)
	{
		msg << m_sltBuff[i].jiage;
		m_sltBuff[i].attr.MakeMsg(msg);
	}
	SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
}

void CUserBloodFight::BloodFightSaoDang(CUser* pUser, CNetMessage& msg)
{
	CBloodFightCfgManager& mgr = sCBloodFightCfgManager;
	CMissionManager& mmgr = sCMissionManager;
	CGuanQiaCfgMgr& smgr = sCGuanQiaCfgMgr;
	BloodChapter* bc = mgr.GetBloodChapterCfg(m_curChapter);
	if (bc == NULL)
		return;
	MultiAward award;
	map<uint16, U8tU32Map>& fixIds = bc->fixIds;
	uint8 sdCnt = m_maxHardNode - m_curNodeId + 1;
	msg << uint8((sdCnt) / 5);
	uint8 lessStar = (m_curNodeId - 1) % 5 * 9 - m_fiveStar;
	for (map<uint16, U8tU32Map>::iterator fit = fixIds.begin(); fit != fixIds.end(); ++fit)
	{
		if (fit->first < m_curNodeId)
			continue;
		if (m_maxHardNode < fit->first) break;

		m_fiveStar = 45 - lessStar;
		lessStar = 0;
		MultiAward maward;
		U8tU32Map* fixs = mgr.GetBloodFixCfg(fit->first);
		if (fixs == NULL)
			continue;

		NodeNormalAward& ad = GetFiveAwardState(fit->first);
		ad.star = ad.star >= m_fiveStar ? ad.star : m_fiveStar;
		m_fiveStar = 0;
		for (U8tU32MapIt it = fixs->begin(); it != fixs->end(); ++it)
		{
			if (it->first > ad.star)
				continue;
			U8tU8MapIt sit = ad.getstate.find(it->first);
			if (sit != ad.getstate.end() && sit->second == 0)
			{
				sit->second = 1;
				MultiAward* mad = smgr.QueryFixAward(it->second);
				if (mad != NULL)
					MergeAwardList(maward, *mad);
			}
		}
		msg << fit->first;
		MakeMultiAwardMsg(maward, msg);
		MergeAwardList(award, maward);
	}
	mmgr.UpdateQuestState(pUser, EMQCT_3, sdCnt);
	mmgr.UpdateQuestState(pUser, EMQCT_44, m_allStar);
	// buff时需要用到扫荡起始关 所有星星在buff阶段计算

	for (uint8 ai = 0; ai < award.size(); ++ai)
	{
		SAwardData& ad = award[ai];
		pUser->AddMaterial(ad);
		if (ad.type >= HDAT_MONEY)
			ItemCurrencyLog(pUser->GetRoleId(), MUT_XueZhanFix, 1, ad.type, ad.num, pUser->GetMaterial(ad.type), MUT_XueZhanFix);
	}
	SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
	SendSaoDangBuff(pUser);
}

void CUserBloodFight::SelectBloodBuff(CUser* pUser, CNetMessage& msg)
{
	if (m_sltBuff.empty() || BS_SaoDangBuff == m_state)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0190, TIPS_FAILURE_COLOR);
		return;
	}
	CBloodFightCfgManager& mgr = sCBloodFightCfgManager;
	uint16 firstNode = mgr.GetChapterFirstNode(m_curChapter);
	uint8 sdNode = m_curNodeId - firstNode + 1;
	uint8 cnt = sdNode / 3;
	if (cnt == 0)
		return;

	if (m_SltIdx > cnt)
		return;
	uint8 type;
	msg >> type;
	if (type == 0 || m_sltBuff.size() < type)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_87, TIPS_FAILURE_COLOR);
		return;
	}
	// 暂时性处理
	if (m_curStar < 9)
	{
		m_curStar = 9;
	}
	if (m_sltBuff[type - 1].jiage > m_curStar)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0207, TIPS_FAILURE_COLOR);
		return;
	}
	m_curStar -= m_sltBuff[type - 1].jiage;
	msg << PRO_SUCCESS << m_curStar;
	AddToAttrList(m_buffs, m_sltBuff[type - 1].attr);
	msg << (uint8)m_buffs.size();
	for (uint8 i = 0; i < m_buffs.size(); ++i)
	{
		msg << (uint16)m_buffs[i].attrType << m_buffs[i].attrValue;
	}
	m_SltIdx++;
	m_sltBuff.clear();
	tryMakeNextBlood(pUser);
}

void CUserBloodFight::GetRankAward(CUser* pUser, CNetMessage& msg)
{
	if (m_rankState == 1)
	{
		msg << m_rankState;
		return;
	}
	uint32 rank = SingletonCRankMgr::instance().GetRankIdx(CRankMgr::ERT_Blood_Yesterday, pUser->GetRoleId());
	m_rankState = 1;
	msg << m_rankState;
	if (rank > 0)
	{
		MultiAward rad;
		sAwardManager.GetRankAward(CRankMgr::ERT_Blood_Yesterday, rank, rad);
		SendAndMakeAwardMsg(pUser, rad, msg, false, MUT_XueZhanRank);
	}
}

void CUserBloodFight::SetAutoSltBuff(CNetMessage& msg)
{
	int type;
	msg >> type;
	m_SltSet = type;
	msg << PRO_SUCCESS;
}

void CUserBloodFight::SelectSaoDangBloodBuff(CUser* pUser, CNetMessage& msg)
{
	if (BS_SaoDangBuff != m_state)
		return;
	CBloodFightCfgManager& mgr = sCBloodFightCfgManager;
	uint16 firstNode = mgr.GetChapterFirstNode(m_curChapter);
	uint8 sdNode = m_maxHardNode - firstNode + 1;
	uint16 lessStar = m_curStar - (sdNode - (m_SltIdx + 1) * 3) * 9;
	uint8 cnt = sdNode / 3;
	if (cnt == 0)
		return;

	if (m_SltIdx > cnt)
		return;

	if (m_sltBuff.empty())
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0190, TIPS_FAILURE_COLOR);
		return;
	}
	uint8 type;
	msg >> type;
	if (type == 0 || m_sltBuff.size() < 3 || m_sltBuff[type - 1].jiage > lessStar)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_87, TIPS_FAILURE_COLOR);
		return;
	}

	msg << PRO_SUCCESS;
	AddToAttrList(m_buffs, m_sltBuff[type - 1].attr);
	m_curStar -= m_sltBuff[type - 1].jiage;
	m_sltBuff.clear();
	m_SltIdx++;
	TrapBuffAttr(pUser);
	if (m_SltIdx < cnt)
		TrapSaoDangBuff(pUser);
	else if (m_SltIdx == cnt)
	{
		m_state = BS_SaoDangBuffEnd;
		tryMakeNextBlood(pUser);
	}
}

void CUserBloodFight::GetSomeRecord(CUser* pUser, CNetMessage& msg)
{
	msg << pUser->GetExtData32(ED32_JingJiZuiGaoMing) << m_firstAward << m_maxHardNode;
}

void CUserBloodFight::GetTodayInfo(uint16 &star, uint16 &nodeId)
{
	star = m_todayMaxStar;
	nodeId = m_curNodeId;
}

void CUserBloodFight::AddStar(CUser *pUser, uint16 addStar)
{
	m_allStar += addStar;
	m_curStar += addStar;
	if (m_todayMaxStar < m_allStar)
	{
		m_todayMaxStar = m_allStar;
		if (m_highStar < m_todayMaxStar)
			m_highStar = m_todayMaxStar;
		SingletonCRankMgr::instance().UpdateData(CRankMgr::ERT_Blood_Today, pUser->GetRoleId(), m_todayMaxStar, 0, m_curNodeId);
	}
}
