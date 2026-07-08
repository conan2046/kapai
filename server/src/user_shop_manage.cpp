#include "user_shop_manage.h"
#include "rapidjson/document.h"
#include "init.h"
#include "user.h"
#include "blood_fight_manage.h"

uint16 ShopGridWeightCfg::GetRand()
{
	uint16 rd = Random(0, sumWeight);
	for (U16tU16MapIt it = weights.begin(); it != weights.end(); ++it)
	{
		if (rd <= it->second)
			return it->first;
	}
	return 0;
}


ShopCfgManager::ShopCfgManager()
{
}

ShopCfgManager::~ShopCfgManager()
{
}

bool ShopCfgManager::InitCfg()
{
	return InitShopCfg()
		&& InitShopItemCfg();
}

bool ShopCfgManager::InitShopCfg()
{
	const string file = "shop_config.json";
	//                            0      1          2               3           4         5            6        7
	const char* titleArrs[] = { "id", "auto", "refreshtime", "refresh_count", "cost", "free_time", "free_cd", "auto" };
	const int typeArrs[] = { 0, 0, 0, 0, 2, 0, 0 };  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "ShopCfgManager::InitShopCfg >> LoadJosnValue error " << endl;
		return false;
	}

	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		ShopCfg cfg;
		uint8 type = data[titleArrs[0]].GetInt();
		cfg.autoRefresh = data[titleArrs[1]].GetInt();
		cfg.time = data[titleArrs[2]].GetInt();
		cfg.maxTimes = data[titleArrs[3]].GetInt();
		cfg.freeTimes = data[titleArrs[5]].GetInt();
		cfg.freeCd = data[titleArrs[6]].GetInt();
		cfg.autoRefresh = data[titleArrs[7]].GetInt();
		const rapidjson::Value &_arr = data[titleArrs[4]];
		if (_arr.IsArray() && _arr.Size() == 2)
		{
			cfg.itemId = _arr[0].GetInt();
			cfg.itemNum = _arr[1].GetInt();
		}
		m_shopCfg[type] = cfg;
	}
	return true;
}

bool ShopCfgManager::InitShopItemCfg()
{
	const string file = "shop.json";
	//                            0     1       2        3          4         5       6         7            8            9
	const char* titleArrs[] = { "id", "type", "cell", "itemid", "weight", "count", "price", "price_real", "condition", "show" };
	const int typeArrs[] = { 0, 0, 0, 2, 0, 2, 2, 2, 2, 2 };  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "ShopCfgManager::InitShopItemCfg >> LoadJosnValue error " << endl;
		return false;
	}

	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		ShopItemCfg cfg;
		cfg.id = data[titleArrs[0]].GetInt();
		if (cfg.id == 0)
			continue;
		uint8 type = data[titleArrs[1]].GetInt();
		uint8 grid = data[titleArrs[2]].GetInt();
		ReadSingleAward(data[titleArrs[3]], cfg.item);
		cfg.weight = data[titleArrs[4]].GetInt();
		ReadSingleTypeValue(data[titleArrs[5]], cfg.buyNum);
		ReadMultiCost(data[titleArrs[6]], cfg.cost);
		const rapidjson::Value &_arr1 = data[titleArrs[7]];
		if (!_arr1.IsArray())
			continue;
		for (uint8 ai = 0; ai < _arr1.Size(); ++ai)
		{
			cfg.percent.push_back(_arr1[ai].GetInt());
		}
		ReadMultiTypeValue(data[titleArrs[8]], cfg.buyCond);
		ReadMultiTypeValue(data[titleArrs[9]], cfg.showCond);
		ShopGridWeightCfgMap* sg = GetShopWeightCfg(type);
		if (sg == NULL)
		{
			ShopGridWeightCfgMap tmpSg;
			ShopGridWeightCfg sgw;
			sgw.gid = grid;
			sgw.sumWeight = cfg.weight;
			sgw.weights[cfg.id] = cfg.weight;
			tmpSg[grid] = sgw;
			m_shopGridCfg[type] = tmpSg;
		}
		else
		{
			ShopGridWeightCfg* wc = GetGridWeightCfg(type, grid);
			if (wc != NULL)
			{
				wc->sumWeight += cfg.weight;
				cfg.weight = wc->sumWeight;
				wc->weights[cfg.id] = wc->sumWeight;
			}
			else
			{
				ShopGridWeightCfg sgw;
				sgw.gid = grid;
				sgw.sumWeight = cfg.weight;
				sgw.weights[cfg.id] = cfg.weight;
				(*sg)[grid] = sgw;
			}
		}
		m_shopItemCfg[cfg.id] = cfg;
	}
	return true;
}

ShopCfg * ShopCfgManager::GetShopCfg(uint8 type)
{
	ShopCfgMapIt it = m_shopCfg.find(type);
	if (it == m_shopCfg.end())
		return NULL;

	return &it->second;
}

ShopGridWeightCfgMap * ShopCfgManager::GetShopWeightCfg(uint8 type)
{
	ShopGridCfgMapIt it = m_shopGridCfg.find(type);
	if (it == m_shopGridCfg.end())
		return NULL;

	return &it->second;
}

ShopItemCfg * ShopCfgManager::GetShopItemCfg(uint16 tid)
{
	ShopItemCfgMapIt it = m_shopItemCfg.find(tid);
	if (it == m_shopItemCfg.end())
		return NULL;

	return &it->second;
}

ShopGridWeightCfg * ShopCfgManager::GetGridWeightCfg(uint8 type, uint8 gid)
{
	ShopGridWeightCfgMap* gmap = GetShopWeightCfg(type);
	if (gmap == NULL)
		return NULL;

	ShopGridWeightCfgMapIt it = gmap->find(gid);
	if (it == gmap->end())
		return NULL;

	return &it->second;
}

UserShopManager::UserShopManager()
{
}

UserShopManager::~UserShopManager()
{
}

void UserShopManager::SaveData(string & str)
{
	int pos = 0;
	uint8 data[1024 * 10] = { 0 };

	data[pos++] = m_shops.size();
	for (ShopItemsMapIt it = m_shops.begin(); it != m_shops.end(); ++it)
	{
		UserShopGrids& usg = it->second;
		pos = CopyDataToBuf((char *)data, &it->first, sizeof(it->first), pos);
		pos = CopyDataToBuf((char *)data, &usg.refreshTimes, sizeof(usg.refreshTimes), pos);
		pos = CopyDataToBuf((char *)data, &usg.freeTimes, sizeof(usg.freeTimes), pos);
		pos = CopyDataToBuf((char *)data, &usg.cd, sizeof(usg.cd), pos);
		data[pos++] = usg.items.size();
		for (UserShopGridMapIt ii = usg.items.begin(); ii != usg.items.end(); ii++)
		{
			UserShopGrid& gd = ii->second;
			pos = CopyDataToBuf((char *)data, &gd.grid, sizeof(gd.grid), pos);
			pos = CopyDataToBuf((char *)data, &gd.tid, sizeof(gd.tid), pos);
			pos = CopyDataToBuf((char *)data, &gd.cnt, sizeof(gd.cnt), pos);
		}
	}
	Compress(data, pos, str);
}

void UserShopManager::LoadData(CUser* pUser, const char * str)
{
	if (str == NULL || strlen(str) == 0)
	{
		InitShop(pUser);
		return;
	}
	uint32 len = 1024 * 10;
	uint8 data[1024 * 10];
	int pos = 0;
	if (!UnCompress(str, data, len))
		return;

	uint8 size = data[pos++];
	for (size_t i = 0; i < size; i++)
	{
		UserShopGrids usg;
		uint8 type = data[pos++];
		pos = ReadDataFromBuf((char *)data, &usg.refreshTimes, sizeof(usg.refreshTimes), pos);
		pos = ReadDataFromBuf((char *)data, &usg.freeTimes, sizeof(usg.freeTimes), pos);
		pos = ReadDataFromBuf((char *)data, &usg.cd, sizeof(usg.cd), pos);
		uint8 isize = data[pos++];
		for (size_t ii = 0; ii < isize; ii++)
		{
			UserShopGrid gd;
			pos = ReadDataFromBuf((char *)data, &gd.grid, sizeof(gd.grid), pos);
			pos = ReadDataFromBuf((char *)data, &gd.tid, sizeof(gd.tid), pos);
			pos = ReadDataFromBuf((char *)data, &gd.cnt, sizeof(gd.cnt), pos);
			usg.items[gd.tid] = gd;
		}
		m_shops[type] = usg;
	}

	ShopCfgMap& mcfg = sShopCfgManager.GetShopCfg();
	for (ShopCfgMapIt it = mcfg.begin(); it != mcfg.end(); ++it)
	{
		UserShopGrids* tmp = GetShopItems(it->first);
		if (tmp == NULL)
		{
			UserShopGrids grids;
			grids.freeTimes = it->second.freeTimes;
			grids.refreshTimes = 0;
			grids.cd = 0;
			grids.RefreshGrids(it->first, pUser);
			m_shops[it->first] = grids;
		}
	}
}

bool UserShopManager::InitShop(CUser* pUser)
{
	ShopCfgMap& mcfg = sShopCfgManager.GetShopCfg();
	for (ShopCfgMapIt it = mcfg.begin(); it != mcfg.end(); ++it)
	{
		ShopCfg& scfg = it->second;
		UserShopGrids grids;
		grids.freeTimes = scfg.freeTimes;
		grids.refreshTimes = 0;
		grids.cd = 0;
		grids.RefreshGrids(it->first, pUser);
		m_shops[it->first] = grids;
	}
	return true;
}

void UserShopManager::ResetShop(CUser* pUser)
{
	ShopCfgManager& mgr = sShopCfgManager;
	for (ShopItemsMapIt it = m_shops.begin(); it != m_shops.end(); ++it)
	{
		UserShopGrids& grids = it->second;
		ShopCfg* scfg = mgr.GetShopCfg(it->first);
		if (scfg == NULL)
			continue;
		grids.freeTimes = scfg->freeTimes;
		grids.refreshTimes = 0;
		grids.cd = 0;
		if (scfg->autoRefresh)
			grids.RefreshGrids(it->first, pUser);
	}
}

void UserShopManager::CheckShopFreeCnt(CUser* pUser)
{
	ShopCfgManager& mgr = sShopCfgManager;
	uint32 curTime = GetSysTime();
	for (ShopItemsMapIt it = m_shops.begin(); it != m_shops.end(); ++it)
	{
		UserShopGrids& shop = it->second;
		ShopCfg* cfg = mgr.GetShopCfg(it->first);
		if (cfg == NULL)
			continue;
		if (cfg->freeCd != 0 && shop.cd != 0 && curTime >= shop.cd)
		{
			int lessCd = curTime - (shop.cd - cfg->freeCd);
			uint8 addCnt = lessCd / cfg->freeCd;
			shop.freeTimes += addCnt;
			if (shop.freeTimes >= cfg->freeTimes)
			{
				shop.freeTimes = cfg->freeTimes;
				shop.cd = 0;
			}
			else
			{
				shop.cd += addCnt * cfg->freeCd;
			}

			CNetMessage trap;
			trap.SetType(MSG_SHOP);
			trap << (uint8)1 << it->first << PRO_SUCCESS;
			shop.MakeMsg(trap);
			SingletonSocket::instance().SendMsg(pUser->GetSock(), trap);
		}
	}
}

void UserShopGrids::RefreshGrids(uint8 type, CUser* pUser)
{
	items.clear();
	ShopCfgManager& mgr = sShopCfgManager;
	ShopGridWeightCfgMap* mp = mgr.GetShopWeightCfg(type);
	if (mp == NULL)
		return;
	for (ShopGridWeightCfgMapIt mit = mp->begin(); mit != mp->end(); ++mit)
	{
		uint16 tid = 0;
		while (true)
		{
			ShopGridWeightCfg& grid = mit->second;
			tid = grid.GetRand();
			ShopItemCfg* cfg = mgr.GetShopItemCfg(tid);
			if (cfg == NULL)
				continue;
			bool show = CheckUserCond(pUser, cfg->showCond);
			if (!show && grid.weights.size() == 1)
			{
				tid = 0;
				break;
			}
			if (show)
				break;
		}

		if (tid == 0)
			continue;

		UserShopGrid grid;
		grid.tid = tid;
		grid.grid = mit->first;
		grid.cnt = 0;
		items[grid.tid] = grid;
	}
}

void UserShopGrids::MakeMsg(CNetMessage& msg)
{
	uint32 curTime = GetSysTime();
	uint16 lessTime = cd > curTime ? cd - curTime : 0;
	msg << refreshTimes << freeTimes << lessTime << (uint8)items.size();

	for (UserShopGridMapIt i = items.begin(); i != items.end(); ++i)
	{
		UserShopGrid& grid = i->second;
		msg << grid.grid << grid.tid << grid.cnt;
	}

}

UserShopGrid* UserShopGrids::GetUserShopGrid(uint16 tid)
{
	UserShopGridMapIt it = items.find(tid);
	if (it == items.end())
		return NULL;

	return &it->second;
}

UserShopGrids* UserShopManager::GetShopItems(uint8 type)
{
	ShopItemsMapIt it = m_shops.find(type);
	if (it == m_shops.end())
		return NULL;

	return &it->second;
}

void UserShopManager::GetShopMsg(CUser* pUser, CNetMessage & msg)
{
	uint8 type;
	msg >> type;
	ShopCfg* cfg = sShopCfgManager.GetShopCfg(type);
	if (cfg == NULL)
		return;
	UserShopGrids* shop = GetShopItems(type);
	if (shop == NULL)
		return;
	CheckShopFreeCnt(pUser);
	msg << PRO_SUCCESS;
	if (shop->items.empty())
		shop->RefreshGrids(type, pUser);
	shop->MakeMsg(msg);
}

void UserShopManager::BuyShopItem(CUser* pUser, CNetMessage& msg)
{
	uint8 type;
	uint16 tid;
	uint16 num;
	uint8 use;
	msg >> type >> tid >> num >> use;
	if (num > 10000)
		num = 10000;
	UserShopGrids* shop = GetShopItems(type);
	if (shop == NULL)
		return;

	uint16 cnt = 0;
	UserShopGrid* grid = shop->GetUserShopGrid(tid);
	if (grid != NULL)
		cnt = grid->cnt;
	ShopItemCfg* gcfg = sShopCfgManager.GetShopItemCfg(tid);
	if (gcfg == NULL)
		return;

	if (gcfg->buyNum.value > 0 && cnt >= gcfg->buyNum.value)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0198, TIPS_FAILURE_COLOR);
		return;
	}
	bool canBuy = CheckUserCond(pUser, gcfg->buyCond);
	if (!canBuy)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0196, TIPS_FAILURE_COLOR);
		return;
	}

	float sumPer = 0;
	for (uint16 i = cnt; i < num + cnt; ++i)
	{
		if (i >= gcfg->percent.size())
			sumPer += gcfg->percent[gcfg->percent.size() - 1];
		else
			sumPer += gcfg->percent[i];
	}
	sumPer /= 100.0;
	MultiCost cost = gcfg->cost;
	for (size_t i = 0; i < cost.size(); i++)
	{
		cost[i].costValue *= sumPer;
	}
	if (!pUser->DelCostMaterial(cost))
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_267, TIPS_FAILURE_COLOR);
		return;
	}
	if (grid == NULL)
	{
		UserShopGrid tmp;
		tmp.cnt = num;
		tmp.tid = tid;
		tmp.grid = shop->items.size() + 1;
		shop->items[tid] = tmp;
	}
	else
		grid->cnt += num;
	SAwardData ad = gcfg->item;
	ad.num *= num;
	pUser->AddMaterial(ad);
	SCostData& scost = cost[0];
	if (use == 1)
	{
		int pos = pUser->GetItemPosById(ad.type);
		pUser->UseItem(pos);
	}
	msg << PRO_SUCCESS << uint16(cnt + num) << (uint16)gcfg->item.type << gcfg->item.num;
	sCMissionManager.UpdateQuestState(pUser, EMQCT_1, num, gcfg->item.type);
	SaveBuyShopItem(type, pUser->GetRoleId(), ad, scost, pUser->GetMaterial(scost.costType));
}

void UserShopManager::SendShopHotPointStatus(CUser* pUser, uint8 type)
{
	uint8 state = EHPointS_NotShow;
	do 
	{
		ShopCfgManager& smgr = sShopCfgManager;
		ShopGridWeightCfgMap* cfgs = smgr.GetShopWeightCfg(type);
		if (cfgs == NULL)
			break;

		UserShopGrids* shop = GetShopItems(type);
		if (shop == NULL)
			break;

		for (ShopGridWeightCfgMapIt mit = cfgs->begin(); mit != cfgs->end(); ++mit)
		{
			ShopGridWeightCfg& grid = mit->second;
			for (U16tU16MapIt wit = grid.weights.begin(); wit != grid.weights.end(); ++wit)
			{
				uint16 tid = wit->first;
				ShopItemCfg* cfg = smgr.GetShopItemCfg(tid);
				if (cfg == NULL)
					continue;
				if (!CheckUserCond(pUser, cfg->showCond))
					continue;
				if (!CheckUserCond(pUser, cfg->buyCond))
					continue;

				uint16 cnt = 0;
				UserShopGrid* grid = shop->GetUserShopGrid(tid);
				if (grid != NULL)
					cnt = grid->cnt;
				if (cfg->buyNum.value > 0 && cnt >= cfg->buyNum.value)
					continue;
				string tmp;
				if (!pUser->CheckCostMaterial(cfg->cost, tmp))
					continue;
				state = EHPointS_Show;
				break;
			}
			if (state == EHPointS_Show)
				break;
		}
	} while (false);
	switch (type)
	{
	case 4:
		SendHotPointStatus(pUser, EHPoint_Shop1, state);
		break;
	case 8:
		SendHotPointStatus(pUser, EHPoint_Shop2, state);
		break;
	}
}

void UserShopManager::GetItemByCnt(CUser* pUser, CNetMessage& msg)
{
	uint8 type;
	uint16 timeId;
	msg >> type >> timeId;

	UserShopGrids* grids = GetShopItems(type);
	if (grids == NULL)
		return;
	uint16 cnt = 0;
	UserShopGrid* grid = grids->GetUserShopGrid(timeId);
	if (grid != NULL)
		cnt = grid->cnt;
	msg << PRO_SUCCESS << cnt;
	return;
}


void UserShopManager::RefreshGrids(CUser* pUser, CNetMessage& msg)
{
	uint8 type;
	msg >> type;
	UserShopGrids* grids = GetShopItems(type);
	if (grids == NULL)
		return;
	ShopCfg* cfg = sShopCfgManager.GetShopCfg(type);
	if (cfg == NULL)
		return;
	if (grids->freeTimes == 0 && cfg->maxTimes <= grids->refreshTimes)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0194, TIPS_FAILURE_COLOR);
		return;
	}
	if (grids->freeTimes > 0)
		grids->freeTimes--;
	else
	{
		if (pUser->GetMaterial(cfg->itemId) < cfg->itemNum)
		{
			char buf[128];
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0195, GetItemName(cfg->itemId));
			msg << PRO_ERROR << MakeStringColor(buf, TIPS_FAILURE_COLOR);
			return;
		}
		grids->refreshTimes++;
		pUser->SubMaterial(cfg->itemId, cfg->itemNum);
	}

	if (grids->cd == 0)
		grids->cd = GetSysTime() + cfg->freeCd;

	grids->RefreshGrids(type, pUser);
	msg << PRO_SUCCESS;
	grids->MakeMsg(msg);
	sCMissionManager.UpdateQuestState(pUser, EMQCT_18, 1, type);
}
