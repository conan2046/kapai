#ifndef _USER_SHOP_MANAGE_H_
#define _USER_SHOP_MANAGE_H_
#include "self_typedef.h"
#include <map>
#include <set>
#include <vector>
#include "hero_cfg_manager.h"
using namespace std;

class CUser;

struct ShopCfg
{
	bool autoRefresh;
	bool randShop;
	uint16 time;			// 刷新时间
	uint16 maxTimes;
	uint16 freeTimes;
	uint16 freeCd;
	uint16 itemId;
	uint16 itemNum;
};
typedef map<uint8, ShopCfg> ShopCfgMap;
typedef map<uint8, ShopCfg>::iterator ShopCfgMapIt;

struct ShopItemCfg
{
	ShopItemCfg()
		: id(0)
		, weight(0)
	{
		cost.clear();
		percent.clear();
		buyNum.type = 0;
		buyNum.value = 0;
		buyCond.clear();
		showCond.clear();
	}
	uint16 id;
	SAwardData item;
	uint16 weight;
	MultiCost cost;
	vector<uint16> percent;
	TypeValue buyNum;
	MultiTypeValue buyCond;
	MultiTypeValue showCond;
};
typedef map<uint16, ShopItemCfg> ShopItemCfgMap;
typedef map<uint16, ShopItemCfg>::iterator ShopItemCfgMapIt;

struct ShopGridWeightCfg
{
	uint8 gid;
	uint16 sumWeight;
	U16tU16Map weights;
	uint16 GetRand();
};
typedef map<uint8, ShopGridWeightCfg> ShopGridWeightCfgMap;
typedef map<uint8, ShopGridWeightCfg>::iterator ShopGridWeightCfgMapIt;

typedef map<uint8, ShopGridWeightCfgMap> ShopGridCfgMap;
typedef map<uint8, ShopGridWeightCfgMap>::iterator ShopGridCfgMapIt;

class ShopCfgManager
{
public:
	ShopCfgManager();
	~ShopCfgManager();

	bool InitCfg();
	bool InitShopCfg();
	bool InitShopItemCfg();

	ShopCfg* GetShopCfg(uint8 type);
	ShopGridWeightCfgMap* GetShopWeightCfg(uint8 type);
	ShopItemCfg* GetShopItemCfg(uint16 tid);
	ShopGridWeightCfg* GetGridWeightCfg(uint8 type, uint8 gid);
	ShopCfgMap& GetShopCfg() { return m_shopCfg; }
private:
	ShopCfgMap m_shopCfg;
	ShopItemCfgMap m_shopItemCfg;
	ShopGridCfgMap m_shopGridCfg;
};
#define sShopCfgManager boost::details::pool::singleton_default<ShopCfgManager>::instance()

struct UserShopGrid
{
	uint8 grid;				// 格子
	uint16 tid;				// 配置表id
	uint16 cnt;				// 购买次数
};
typedef map<uint16, UserShopGrid> UserShopGridMap;
typedef map<uint16, UserShopGrid>::iterator UserShopGridMapIt;

struct UserShopGrids
{
	uint8 freeTimes;			// 免费次数
	uint16 refreshTimes;		// 刷新次数
	uint32 cd;					// 免费次数cd
	UserShopGridMap items;
	void RefreshGrids(uint8 type, CUser* pUser);
	void MakeMsg(CNetMessage& msg);
	UserShopGrid* GetUserShopGrid(uint16 tid);
};
typedef map<uint8, UserShopGrids> ShopItemsMap;
typedef map<uint8, UserShopGrids>::iterator ShopItemsMapIt;

class UserShopManager
{
public:
	UserShopManager();
	~UserShopManager();

	// 数据保存
	void SaveData(string &str);
	// 数据加载
	void LoadData(CUser* pUser, const char *str);

	bool InitShop(CUser* pUser);
	void ResetShop(CUser* pUser);
	void CheckShopFreeCnt(CUser* pUser);
	UserShopGrids* GetShopItems(uint8 type);

	void RefreshGrids(CUser* pUser, CNetMessage& msg);
	void SendShopHotPointStatus(CUser* pUser, uint8 type);

public:
	void GetShopMsg(CUser* pUser, CNetMessage& msg);
	void BuyShopItem(CUser* pUser, CNetMessage& msg);
	void GetItemByCnt(CUser* pUser, CNetMessage& msg);

public:
	ShopItemsMap m_shops;
};

#endif 
