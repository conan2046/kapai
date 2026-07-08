#ifndef _SINGLETON_H_
#define _SINGLETON_H_

#include "scene_manager.h"
#include "npc_manager.h"
#include "online_user.h"
#include "item.h"
#include "monster.h"
#include "fight.h"
#include "bangpai.h"
#include "huo_dong.h"
#include "self_typedef.h"

typedef boost::details::pool::singleton_default<CDespatchCommand> SingletonDespatch;
typedef boost::details::pool::singleton_default<CSocketServer> SingletonSocket;
typedef boost::details::pool::singleton_default<CSceneManager> SingletonSceneManager;
typedef boost::details::pool::singleton_default<CNpcManager> SingletonNpcManager;
typedef boost::details::pool::singleton_default<COnlineUser> SingletonOnlineUser;
typedef boost::details::pool::singleton_default<CItemTemplateManager> SingletonItemManager;
typedef boost::details::pool::singleton_default<CFightManager> SingletonFightManager;
typedef boost::details::pool::singleton_default<CFightCfgManager> SingletonCFightCfgManager;
typedef boost::details::pool::singleton_default<CBangPaiManager> SingletonCBangPaiManager;
typedef boost::details::pool::singleton_default<CBP_CfgMgr> SingletonCBP_CfgMgr;
typedef boost::details::pool::singleton_default<CFishManager> SingletonFishManager;
typedef boost::details::pool::singleton_default<CShopManager> SingletonShopManager;
typedef boost::details::pool::singleton_default<CHuoDongExpManage> SingletonHuoDongExpManager;
typedef boost::details::pool::singleton_default<CPlantSeedManager> SingletonCPlantSeedManager;
typedef boost::details::pool::singleton_default<CRiChangFuBenManager> SingletonCRiChangFuBenManager;
typedef boost::details::pool::singleton_default<CHDExchangeManager> SingletonCHDExchangeManager;
typedef boost::details::pool::singleton_default<CHuoDongAwardManager> SingletonCHuoDongAwardManager;
typedef boost::details::pool::singleton_default<CWaitForFightManager> SingletonCWaitForFightManager;
typedef boost::details::pool::singleton_default<CFestivalRandomBoxManager> SingletonCFestivalRandomBoxManager;
typedef boost::details::pool::singleton_default<CXianYuanManager> SingletonCXianYuanManager;
typedef boost::details::pool::singleton_default<CTransFormManager> SingletonCTransFormManager;

typedef boost::details::pool::singleton_default<CQunXianZhengBaManager> SingletonCQunXianZhengBaManager;
typedef boost::details::pool::singleton_default<CJiaoYiHangManager> SingletonCJiaoYiHangManager;
typedef boost::details::pool::singleton_default<CFunctionSwitchManager> SingletonCFunctionSwitchManager;

typedef boost::details::pool::singleton_default<CShenJieMiJingManager> SingletonCShenJieMiJingManager;
#ifdef KUA_FU
typedef boost::details::pool::singleton_default<CKuaFu1vs1PreliminaryManager> SingletonCKuaFu1vs1PreliminaryManager;
#endif

typedef boost::details::pool::singleton_default<CHuoDongMoneyGiftBag> SingletonCHuoDongMoneyGiftBag;


#endif

