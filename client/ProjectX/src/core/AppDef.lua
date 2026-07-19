--[[
    @功能：整个游戏的一些配置信息，包括手机串号，分辨率之类
    @作者：陈伟
    @创建日期：2018-08-21
]]
AppDef = {}
require "core.AppBTDef"
require "core.AppHeroDef"
require "core.AppUIDef"
require "core.AppSettingDef"

-- 本地无登录服测试开关。true 时客户端跳过登录服，直接显示本地游戏服。
AppDef.LOCAL_TEST = true
AppDef.LOCAL_TEST_UID = 1
AppDef.LOCAL_TEST_SIGNATURE = "local_test"
AppDef.LOCAL_TEST_SERVER_ID = 1
AppDef.LOCAL_TEST_SERVER_NAME = "本地测试服"
AppDef.LOCAL_TEST_GAME_IP = "127.0.0.1"
AppDef.LOCAL_TEST_GAME_PORT = 8711
AppDef.LOCAL_TEST_AUTO_ENTER = true
AppDef.LOCAL_TEST_AUTO_CREATE_ROLE = true
AppDef.LOCAL_TEST_ROLE_NAME = "Test01"
AppDef.LOCAL_TEST_ROLE_ID = 1000001
-- 本地截图/自动化专用；nil 时关闭，不影响正常本地流程与线上路径。
AppDef.LOCAL_TEST_AUTO_OPEN_MODULE = nil
-- 本地阵容截图专用；例如 {1, 2} 会在打开布阵界面后交换两个阵位。
AppDef.LOCAL_TEST_AUTO_FORMATION_MOVE = nil
AppDef.LOCAL_TEST_AUTO_FORMATION_POPUP = nil

--内网
	-- AppDef.ipAdrr = "192.168.2.132"
	-- AppDef.ipPort = 8801

--外网
	AppDef.ipAdrr = "122.51.75.27"
	AppDef.ipPort = 9501



AppDef.OpenId = nil
AppDef.OpenSession = nil
AppDef.SelectedServerId = 0

--渠道号定义*********************************
AppDef.Default_ADCODE = 1--官方默认渠道号
--渠道号结束***********************************

AppDef.MAX_TEAM_TARGET_LEVEL = 120 --组队目标，最大等级
AppDef.OPEN_GUIDE = false
AppDef.OPEN_BUGLY = true
AppDef.MAX_FIGHT_SPEED = 6
AppDef.APPID_DOUSHENWUSHUANG = 1 --斗神无双
AppDef.APPID_JIANZHENGZHUXIAN = 2 --剑阵诛仙
-- AppDef.OPEN_GUIDE_TEST = false
-----------------------------地图相关--------------------------
AppDef.SceneType = 
{
	MSI_NORMAL = 0,             --普通场景
	MSI_TOWER = 1,              --通天塔
	MSI_COPY = 2,               --副本
	MSI_FISHROOM = 3,           --钓鱼
	MSI_KUNLUN = 4,             --昆仑山
	MSI_FIARYLAND = 5,          --幻境
	MSI_LEITAISAI = 6,          --擂台赛
	MSI_FACTION_ZONE = 7,       --帮派领地
	MSI_FACTION_WAR_PRE = 8,    --帮战准备
	MSI_FACTION_WAR = 9,        --帮战场景
	MSI_PETCOPY = 10,            --宠物副本
	MSI_SHILIAN = 11,            --英勇试练
	MSI_FLYFARY = 12,        	--飞仙战场
	MSI_CROSSSERVER = 13,        --跨服场景
	MSI_LUNDAO = 14,                --神界论道
	MSI_WEIWODUXIAN = 15,        --惟我独仙
	MSI_SHENJIEMIJING = 16,        --神界秘境
	MSI_MULTISER_FACTION_BATTLE_READY = 17,    --跨服帮战准备
	MSI_MULTISER_FACTION_BATTLE = 18,          --跨服帮战场景
	MSI_COUPLE_COPY = 19,                      --夫妻副本
}
--------------------------------------------------------------
-------------------------任务相关----------------------------------------
AppDef.TaskType = 
{
    TASK_MAIN	= 1,
    TASK_ZHI	= 2,
    TASK_RI     = 3,
    TASK_KuaFu     = 4,
}
----------------------------------------------------------


------------------------道具相关------------------------------------

--装备部位
AppDef.EEquipmentType = 
{
	EEMaoZi      = 1,                   --帽子
	EEKuiJia     = 2,                   --盔甲
	EEYaoDai     = 3,                   --腰带
	EEXieZi      = 4,                   --鞋子
	EEWuQi       = 5,                   --武器
	EEXiangLian  = 6,                   --项链
	EEYuPei      = 7,                   --戒指
	EEShouZhuo1  = 8,                   --护腕
	EEEquipNum = 9,
}

----装备部位对应
--AppDef.EEquipPosList = 
--{
--	3,                   --帽子
--	4,                   --盔甲
--	5,                   --腰带
--	6,                   --鞋子
--	0,                   --武器
--	7,                   --项链
--	9,                   --戒指
--	8,                   --护腕
--}

--奖励类型
AppDef.EAwardType = 
{
    EAT_ITEM = 1,      --道具
    EAT_PET = 2,       --宠物
    EAT_WIND = 3,      --翅膀
    EAT_HORSE = 4,     --坐骑
    EAT_ARTIFACT = 5   --神器
}

--道具选择UI，类型
AppDef.EItemListType = 
{
    EILTNone = 0,
    EILTLianHuaStone = 1,               --炼化石
    EILTXingYunCharm = 2,               --幸运符
    EILTXiLianStone = 3,                --洗炼石
    EILTYuyiStone = 4,                  --羽翼仙石
    EILTWuSeStone = 5,                  --五色石
    EILTMountStone = 6,                 --坐骑强化石
    EILTMountUpgradeStone = 7,          --坐骑进阶丹
}

--玩法类型
AppDef.EActivityType = 
{
    EAT_ALL = 0,  
    EAT_PET = 1,
    EAT_EXP = 2,
    EAT_EQUIP = 4,
    EAT_OTHER = 8,
    EAT_GOLD = 16,
}

--玩法ID
AppDef.EActivityID = 
{
    EAID_BOSS = 1,                   --每日boss
    EAID_SHIMEN = 2,                 --师门任务
    EAID_ADVANCE = 3,                --多人闯关
    EAID_ANIMA = 4,                  --灵气
    EAID_KUNLUN = 5,                 --昆仑山
    EAID_FISH = 6,                   --钓鱼
    EAID_QUESTION = 7,               --答题
    EAID_BAIHUA = 8,                 --百花仙子
	EAID_NIANSHOU = 9,       		 --年兽
    EAID_TOWER = 14,                 --通天塔
    EAID_COMBAT = 15,                --竞技场
    EAID_CONVOY = 16,                --护送
    EAID_LINGMO = 17,                --挑战灵魔
    EAID_CAIQUAN = 18,               --猜拳
    EAID_CHOUCHONG = 19,             --宠物寻访
    EAID_YUNBIAO = 20,               --运镖
    EAID_QUBAO = 24,                 --杀敌取宝
    EAID_DANYUAN = 25,               --维护丹园
    EAID_LEITAI = 26,                --个人擂台
    EAID_PAIHANG = 27,               --排行榜
    EAID_PLANT = 28,                 --种植
    EAID_CANGBAOTU = 29,             --藏宝图
    EAID_ORDEAL = 30,                --英勇试练
    EAID_FLYFARY = 31,	             --飞仙战场
    EAID_ZHUAGUI = 32 ,	             --捉鬼
	EAID_LIUJIESHILIAN = 33,         --六界巡察使
	EAID_FACTIONROB = 34,	         --帮派掠夺	
	EAID_SHAKEMONEYTREE = 35,	     --摇钱树
	EAID_FACTION_WAR = 36,	         --帮战
	EAID_XIUXIANLILIAN = 37,	     --修仙历练
	EAID_KUAFURENWU = 38,	     --跨服任务
	EAID_SHENJIELUNDAO = 39,	     --神界论道
	EAID_WEIWODUXIAN = 40,	     --惟我独仙
	EAID_SHENJIEMIJING = 41,	     --神界秘境
	EAID_KUAFUBANGZHAN = 42,	     --跨服帮战
    EAID_PETCOPY = 43,           --染林密竹 
    EAID_UPGRADECOPY = 44,       --升阶副本
    EAID_STRENGTHENCOPY = 45,    --强化副本
    EAID_QIANNENGCOPY = 46,      -- 潜能副本
    EAID_CUILIANCOPY = 47,       --淬炼副本 
	
	
	EAID_JUEGUXUANYA = 49,
	EAID_HUBOZHAOZE  = 50, 
    EAID_DOUBLEEXP = 51,    --杀怪双倍经验
	EAID_WEEKTASK = 52,    --每周任务
	EAID_FENGSHEN = 53,    --封神试炼
	EAID_MAX = 54,
}
--功能ID
AppDef.EModuleID = {
	EMID_GUAJI = 100,--挂机
	EMID_HERO = 110,--人物
	EMID_BEIBAO = 111,--背包
	EMID_HECHENG = 112,--合成
	EMID_LIANHUA = 113, --炼化
    EMID_FENJIE = 114,--分解
    EMID_LVUP = 115,--升级
    EMID_PETCOMPOUND = 116,--宠物合成提示
	
	---------------------------
	EMID_DUANZAO = 130,--锻造
	EMID_DZQIANGHUA = 131,--强化
	EMID_DZSHENGJIE = 132,--升阶
	EMID_DZCUILIAN = 133,--淬炼
	EMID_DZXILIAN = 134,--洗炼
	---------------------------
	EMID_ZUOJI = 140,--坐骑
	EMID_ZJJINJIE = 141,--坐骑进阶
	EMID_ZJQIANGHUA = 142,--坐骑强化
	---------------------------
	EMID_SHENJIANG = 150,--神将
	EMID_SJJINENG = 151,--神将技能
	EMID_SJSHENGXING = 152,--神将升星
	EMID_SJXIULIAN = 153,--神将修炼
	EMID_SJBUZHEN = 1040,--神将布阵
    EMID_SJEQUIP = 155,--神将装备
    EMID_SJEQUIPQH = 156,--神将装备强化
    EMID_SJBUZHENWithEnemy = 1041,--神将布阵带怪物
	---------------------------
	EMID_CHOUKA = 160,--抽卡
	EMID_JINENG = 170,--技能
	EMID_SHEZHI = 180,--设置
	---------------------------
	EMID_YUYI = 190,--羽翼
	EMID_YYJINJIE = 191,--羽翼进阶
	---------------------------
	EMID_SHENQI = 200,--神器
	EMID_SQJINJIE = 201,--神器进阶
	---------------------------
	EMID_SCCHANGYONG = 13,--常用商城
	EMID_SCSHENMI = 211,--神秘商城
	EMID_SCBANGDING = 212,--绑定商城
	EMID_SCTEGONG = 213,--特供商城

    EMID_DRUGSTORE = 214,--药店（来源跳转用）
    EMID_SEEDSTORE = 215,--种子商店（帮派内，来源跳转用）
    EMID_SCJIFEN = 216,--积分商店
	---------------------------
	EMID_FULI = 230,--福利
	EMID_FUBEN = 240,--副本
	EMID_JINGJI = 250,--竞技
	EMID_PAIHANGBANG = 260,--排行榜
	EMID_PAIHANGBANG_LILIAN = 260,--排行榜
	EMID_WANFA = 270,--玩法
	--EMID_VIP = 1210,--VIP
	EMID_ZUDUI = 290,--组队
	EMID_SHEJIAO = 300,--社交
	EMID_SJYOUJIAN = 301,--邮件
	EMID_FRIEND = 1222,--好友
	EMID_FRIEND_SENDGIFT = 12,--好友赠送

	EMID_MUBIAO = 320,--目标
	EAID_WORLDCHAT = 1230,		--世界聊天
	EAID_PK = 340,				--PK切磋
	EMID_AUTO_FIGHT = 1250,--自动战斗
	EMID_FIGHT_SPEEDUP_1 = 1251,--2倍速战斗
	EMID_FIGHT_JUMP = 1252,--战斗跳过
	EMID_FIGHT_SPEEDUP_2 = 1253,--3倍速战斗
	EMID_FIGHT_SPEEDUP_3 = 1254,--5倍速战斗
	EMID_FIGHT_SPEEDUP_4 = 1255,--10倍速战斗
	EMID_FIGHT_SPEEDUP_5 = 1256,--15倍速战斗
	EMID_CHENHAO = 370,--称号
	
	---------------------------

	EMID_KAPAI_SHENJIANG = 1030,--卡牌神将阵容
	EMID_KAPAI_ZHUJUE = 1050,--主角
	EMID_KAPAI_SJJINENG = 1060,--神将升级
	EMID_KAPAI_SJJINENG_EXTRA = 1061,--神将一级升级
	EMID_KAPAI_SJSHENGXING = 1070,--卡牌升星
	EMID_KAPAI_SJXIULIAN = 1080,--卡牌突破
	EMID_KAPAI_SJXIULIAN_REALY = 1085,--卡牌修炼
    EMID_KAPAI_SJEQUIP = 404,--卡牌信息
    EMID_KAPAI_PET_BAGS = 1100, --神将背包
    EMID_KAPAI_FRAGMENT_BAGS = 1091, --神将碎片
    EMID_KAPAI_CHANGE_PET = 407, --换将
    EMID_KAPAI_CHOUKA = 1010, -----------抽卡
    EMID_KAPAI_CHOUKA_FRIEND = 1011, -----------友情抽卡
    EMID_KAPAI_XUEZHAN = 1160,--英勇试炼
    EMID_KAPAI_XZ_SAODANG = 1161,--英勇试炼扫荡
	EMID_KAPAI_FENGSHEN = 2,--封神试炼
    EMID_KAPAI_FS_1 = 1022,--封神试炼
    EMID_KAPAI_FS_2 = 1023,--封神试炼
    EMID_KAPAI_FS_3 = 1024,--封神试炼
    EMID_KAPAI_FS_4 = 1025,--封神试炼
    EMID_KAPAI_FENGSHEN_STORY = 1200,--封神列传
	EMID_KAPAI_KUNLUN = 1201,--决战昆仑
    EMID_KAPAI_EQUIP_BAG = 1110,--装备背包
    EMID_KAPAI_XUNBAO_ONEKEY = 1181,--一键寻宝
    EMID_KAPAI_EQUIPSRENGTH = 1120, --装备强化
    EMID_KAPAI_EQUIP_jinglian = 1130, --装备精炼

    EMID_KAPAI_FABAO_SYS = 1180, --法宝系统
    EMID_KAPAI_FABAO_QIANGHUA = 1182, --法宝强化
    EMID_KAPAI_FABAO_JINGLIAN = 1183, --法宝精炼

    EMID_TUJIAN=1090,--图鉴

    EMID_KAPAI_YOULISANJIE = 1, --游历三界
    EMID_KAPAI_FENGSHENSHILIAN = 2, --封神试炼
    EMID_KAPAI_WF_FS_STORY = 3, --封神列传
    EMID_KAPAI_ZHUXIANFUBEN = 4, --主线副本
    EMID_KAPAI_ZHIXIANFUBEN = 5, --支线副本
    EMID_KAPAI_WF_ARENA = 6, --竞技场
    EMID_KAPAI_JUEZHANKUNLUN = 7, --决战昆仑
    EMID_KAPAI_WF_XZ = 8, --血战到底
    EMID_KAPAI_XUNBAO = 9,--法宝搜索
    EMID_TASK_DALIY = 10,--每日任务
    EMID_QIRI = 11, --七日活动
    EMID_KAPAI_WF_KUN_XB = 12, --封神列传

    --EMID_SHOP = 13,--商城
    EMID_BANGPAI1 = 14,--帮派
    EMID_SHOP_HUN = 15,--将魂商店
    EMID_SHOP_JINGJI = 16,--竞技场商店
    EMID_SHOP_XUEZHAN = 17,--血战商店
    EMID_HUODONG = 18,--活动
    EMID_ACTIVITY_Tili_REVERT = 18,--体力领取
  	EMID_ACTIVITY_REVERT = 19,--活动,资源找回
  	EMID_SHOP_KUNLUN = 20, --昆仑商店
    EMID_WANFA_KLXB = 21, --昆仑寻宝
	EMID_JINGJIE = 22,--境界
    EMID_ACTIVITY_YAOQIANSHU = 23,--摇钱树
    EMID_MONTHCARD = 24,--月卡
    EMID_RECHARGE_CZJJ = 25, --成长基金
    EMID_RECHARGE_HYJJ = 26, --活跃基金
    EMID_QUESTION = 27,--答题
    EMID_WORLDBOSS = 28,--世界Boss

    EMID_SHOP_TURNTABLE = 30,--转盘商店商店

	EMID_SHOP_BANGPAI = 2125, --帮派商店

    EMID_KAPAI_KPPOS1 = 1031,  --神将1号上阵位
    EMID_KAPAI_KPPOS2 = 1032,  --神将2号上阵位
    EMID_KAPAI_KPPOS3 = 1033,  --神将3号上阵位
    EMID_KAPAI_KPPOS4 = 1034,  --神将4号上阵位
    EMID_KAPAI_KPPOS5 = 1035,  --神将6号上阵位
    EMID_KAPAI_TITLE = 1260, --称号
    EMID_KAPAI_VIP = 1210,--VIP

	-- EMID_KAPAI_FENGSHEN = 2, -----------封神试炼
	---------------------------
    EMID_CROSSERVER = 390,--跨服
	EMID_HUISHOU = 410,--回收
	EMID_SHENJIANG_CHOOSE = 411,--神将选择
	EMID_ZHUANGBEI_CHOOSE = 412,--装备选择
	EMID_ZHUANGBEI_FENJIE_CHOOSE = 413,--装备选择多个
	EMID_CHONGSHENG_CONFIRM = 414,--重生确认
	EMID_FABAO_CHOOSE = 415,--法宝选择
	EMID_FABAO_FENJIE_CHOOSE = 416, --法宝分解
	---------------------------
	EMID_BANGPAI = 2120,--帮派
	EMID_BPLIEBIAO = 2121,--帮派列表
	EMID_BPXINXI = 2122,--帮派信息
	EMID_BPCHENGYUAN = 2123,--帮派成员
	EMID_BPHUODONG = 2124,--帮派活动
	EMID_BPWAR = 2126,--帮战
	--EMID_BPXIULIAN = 127,--帮派修炼
	EMID_BPRank = 2127,--帮派副本排名
	EMID_BPFUBEN = 2128,--帮派副本
  	EMID_BPSKILL = 2129,--帮派技能
  	EMID_BPQUICKFIGHT = 2130,--帮派连续战斗
  	EMID_BPHYREWARDPREVIEW = 2132,--帮派活跃奖励预览

  	----------------------------
  	EMID_OTHER_ROLE_INFO = 30000,--其他玩家信息
  	EMID_OTHER_PET_INFO = 30001,--其他玩家神将信息

  	----------------------------------------------
  	EMID_RANK_Fuben = 30100,--副本排行榜
  	EMID_RANK_JinhJi = 30101,--竞技场排行榜
  	EMID_RANK_XueZhan = 30102,--血战排行榜
  	EMID_RANK_Lv = 30103,--等级排行榜
  	EMID_RANK_Pet = 30104,--神将排行榜
  	EMID_RANK_Power = 30105,--战斗力排行榜
  	EMID_RANK_Tujian = 30105,--图鉴排行榜
  	----------------------------------------------
  	EMID_KAPAI_GIFT_ZHEKOU1 = 501,--折扣礼包1
  	EMID_KAPAI_GIFT_ZHEKOU2 = 502,--折扣礼包2
  	EMID_KAPAI_GIFT_ZHEKOU3 = 503,--折扣礼包3
    EMID_KAPAI_RECHARGE = 504,--充值

  	EMID_RECHARGE_SHOWCHONG = 556, ----首充
  	EMID_RECHARGE_CICHONG = 557, ----次充
  	
  	EMID_RECHARGE_PETDISCOUNT = 561, ----神将折扣
  	EMID_SEVENDAY_LOGIN = 560, ----七日登录
  	EMID_HUANLEZHUANPAN = 563, --欢乐转盘
}


--神将坑位
AppDef.PetFightPos = 
{
	AppDef.EModuleID.EMID_KAPAI_KPPOS1,
	AppDef.EModuleID.EMID_KAPAI_KPPOS2,
	AppDef.EModuleID.EMID_KAPAI_KPPOS3,
	AppDef.EModuleID.EMID_KAPAI_KPPOS4,
	AppDef.EModuleID.EMID_KAPAI_KPPOS5,
}

--锻造类型
AppDef.EquipForgeType = 
{
    EFT_Strengthen = 1,--强化
    EFT_Upgrade = 2,--升阶
    EFT_Baptize = 3,--淬炼
    EFT_XiLian = 4,--洗炼
}

--金钱类型
AppDef.EMoneyType = 
{
    EMT_Gold = 60000,--金币
    EMT_Cash = 60001,--元宝
    EMT_Cash1 = 60003,--元宝
    EMT_ShenHun = 60014,--神魂
    EMT_Banggong = 60021,--帮贡
    EMT_StarExp = 60025,--星宿精华（血战货币）
    EMT_Tili = 60026,--体力
    EMT_HuoYue = 60030,--活跃度（任务）
    EMT_ArenaSorce = 60050,--竞技场货币
    EMT_KunlunMoney = 60051,--昆仑币
    EMT_ShengLing = 60054,--圣灵凭证
    EMT_TurntableScore = 60056,--转盘积分
}

--特殊道具id
AppDef.SpecialItemId = 
{
    Gold = 60000,--金币
    Cash = 60001,--元宝
    Cash1 = 60003,--元宝
	PetExp = 60006,--神将经验
	Qianneng = 60007,--潜能
	Chenghao = 60008,--
	Wing = 60009,
	Mount = 60010,
	Shenqi = 60011,
	Soul = 60014,--神魂
	VipExp = 60015,--贵族经验
	Banggong = 60021,--帮贡
	StarExp = 60025,--星宿精华（血战货币）
	Tili = 60026,--体力
    JinjiCnt = 60027,--竞技场次数
    EMT_HuoYue = 60030,--活跃度（任务）
	JinjiMoney = 60050,--竞技场货币
	KunlunMoney = 60051,--昆仑币
	HeroExp = 60052,--主角经验
    MagicExp = 60053,--法宝经验 
    XunbaoCnt = 60029,--寻宝次数
    Huoyue = 60030,--活跃度
}

AppDef.EquipItemId = 
{
    Equip = 60005,--装备类型
}

--需要特殊处理的奖励类型（Icon)
AppDef.RewardItem = 
{
    RD_ITEM_PET       = 60002,        --宠物
    RD_ITEM_EQUIP     = 60005,        --装备
    RD_ITEM_FABAO     = 60028,        --法宝
}

function AppDef:IsMoneyType(itemId)
	for k,v in pairs(AppDef.EMoneyType) do
		if v == itemId then
			return true
		end
	end
	return false;
end

function AppDef:IsSpecialItem(itemId)
	for k,v in pairs(AppDef.SpecialItemId) do
		if v == itemId then
			return true
		end
	end
	return false;
	-- if itemId >= AppDef.SpecialItemId.Gold and itemId <= AppDef.SpecialItemId.HeroExp then
	-- 	return true
	-- end
	-- return false;
end

--[[
是不是装备道具
]]
function AppDef:IsItemEquip(itemId)
	if itemId == AppDef.EquipItemId.Equip then
		return true
	end
	return false;
end



AppDef.EquipAttr = 
{
	EA_LILIANG      = 1,	--"力量"
	EA_LINGLI       = 2,	--"灵力"
	EA_NALI         = 3,	--"耐力"
	EA_TIZHI        = 4,	--"体质"
	EA_MINJIE       = 5,	--"敏捷"
	EA_FANGYU       = 6,	--"防御"
	EA_SHANGHAI     = 7,	--"伤害"
	EA_QIXUE        = 8,	--"气血"
	EA_SUDU         = 9,	--"速度"
	EA_SHANBI       = 10,	--"闪避"
	EA_FANSHANG     = 11,	--"反伤"
	EA_JIANSHANG    = 12,	--"减伤"
	EA_MINGZHONG    = 13,	--"命中"
	EA_LIANJI       = 14,	--"连击"
	EA_BAOJI        = 15,	--"暴击"
	EA_FANJI        = 16,	--"反击"
	EA_GEDANG       = 17,	--"格挡"
	EA_RENXING      = 18,	--"韧性"
	EA_ZHAOJIA      = 19,	--"招架"
	EA_SXJT         = 20,	--"扇系精通"
	EA_CXJT         = 21,	--"刺系精通"
	EA_DXJT         = 22,	--"刀系精通"
	EA_QXJT         = 23,	--"全系精通"
	EA_SXKX         = 24,	--"扇系抗性"
	EA_CXKX         = 25,	--"刺系抗性"
	EA_DXKX         = 26,	--"刀系抗性"
	EA_QXKX         = 27,	--"全系抗性"
	EA_LJQH         = 28,	--"连击强化"
	EA_BJQH         = 29,	--"暴击强化"
	EA_FJQH         = 30,	--"反击强化"
	EA_FSQH         = 31,	--"反伤强化"
	EA_JSQH         = 32,	--"减伤强化"
	EA_GDQH         = 33,	--"格挡强化"
	EA_RXQH         = 34,	--"韧性强化"
	EA_ZJQH         = 35,	--"招架强化"
	EA_KYW          = 36,	--"抗封印"
	EA_KZD          = 37,	--"抗中毒"
	EA_KBD          = 38,	--"抗冰冻"
	EA_KHS          = 39,	--"抗昏睡
	EA_KHL          = 40,	--"抗混乱"
	EA_JQYW         = 41,	--"加强封印,
	EA_JQZD         = 42,	--"加强中毒"
	EA_JQBD         = 43,	--"加强冰冻"
	EA_JQHS         = 44,	--"加强昏睡"
	EA_JQHL         = 45,	--"加强混乱"
	EA_QSX1         = 46,	--"全属性"
	EA_QSX2         = 47,	--"强效全属"
}

AppDef.AwrdItem = 
{
	AWRD_ITEM_COIN      = 60000,        --金币
	AWRD_ITEM_PET       = 60002,        --宠物
	AWRD_ITEM_YUANBAO   = 60001,        --元宝
	AWRD_ITEM_EQUIP     = 60005,        --装备
	AWRD_ITEM_EXP       = 60006,        --经验
	AWRD_ITEM_POTEN     = 60007,        --潜能
	AWRD_ITEM_CHENGHAO  = 60008,        --称号
	AWRD_ITEM_WINDS     = 60009,        --翅膀
	AWRD_ITEM_HORSE     = 60010,        --坐骑
	AWRD_ITEM_ARTIFACT  = 60011,        --神器
	AWRD_ITEM_SHENPO    = 60014,        --神魄
	AWRD_ITEM_LTJIFEN   = 60016,        --擂台积分
	AWRD_ITEM_BPMONEY   = 60020,		--帮派资金
	AWRD_ITEM_BANGGONG  = 60021,		--帮贡
	AWRD_ITEM_PETEQUIP  = 60024,        --神将装备
	AWRD_ITEM_XINXIUJINHUA  = 60025,    --星宿精华
	AWRD_ITEM_MONSTER       = 60026,        --怪物(monster)
	AWRD_ITEM_TILI       = 60027,        --体力
	AWRD_ITEM_FABAO       = 60028,        --法宝
}

AppDef.AwrdItemName = {
	[AppDef.AwrdItem.AWRD_ITEM_COIN] 		= "金币",
	[AppDef.AwrdItem.AWRD_ITEM_PET] 		= "神将",
	[AppDef.AwrdItem.AWRD_ITEM_YUANBAO] 	= "元宝",
	[AppDef.AwrdItem.AWRD_ITEM_EQUIP] 		= "装备",
	[AppDef.AwrdItem.AWRD_ITEM_EXP] 		= "经验",
	[AppDef.AwrdItem.AWRD_ITEM_POTEN] 		= "潜能",
	[AppDef.AwrdItem.AWRD_ITEM_CHENGHAO] 	= "称号",
	[AppDef.AwrdItem.AWRD_ITEM_WINDS] 		= "翅膀",
	[AppDef.AwrdItem.AWRD_ITEM_HORSE] 		= "坐骑",
	[AppDef.AwrdItem.AWRD_ITEM_ARTIFACT] 	= "神器",
	[AppDef.AwrdItem.AWRD_ITEM_SHENPO] 		= "神魂之魄",
	[AppDef.AwrdItem.AWRD_ITEM_BANGGONG] 	= "帮贡",
	[AppDef.AwrdItem.AWRD_ITEM_LTJIFEN] 	= "积分",
	[AppDef.AwrdItem.AWRD_ITEM_BPMONEY] 	= "帮派资金",
	[AppDef.AwrdItem.AWRD_ITEM_PETEQUIP] 	= "神将装备",
	[AppDef.AwrdItem.AWRD_ITEM_XINXIUJINHUA] 	= "星宿精华",
	[AppDef.AwrdItem.AWRD_ITEM_TILI] 	= "体力",
}

AppDef.SpecialItemName = {
	[AppDef.SpecialItemId.Gold]            = "金币",
	[AppDef.SpecialItemId.Cash]            = "元宝",
	[AppDef.SpecialItemId.VipExp]          = "Vip经验",
	[AppDef.SpecialItemId.HeroExp]         = "主角经验",
	[AppDef.SpecialItemId.MagicExp]        = "法宝经验",
	[AppDef.SpecialItemId.Soul]            = "神魂",
	[AppDef.SpecialItemId.Banggong]        = "帮贡",
	[AppDef.SpecialItemId.JinjiMoney]      = "竞技场积分",
	[AppDef.SpecialItemId.KunlunMoney]     = "昆仑币",
	[AppDef.SpecialItemId.PetExp]          = "神将经验",
	[AppDef.SpecialItemId.StarExp]         = "星宿精华",
	[AppDef.SpecialItemId.Tili]            = "体力",
    [AppDef.SpecialItemId.JinjiCnt]        = "竞技场次数",
    [AppDef.SpecialItemId.XunbaoCnt]       = "寻宝次数",
}

--[[
vip权限条数
]]
AppDef.VipRightNums = 
{
	VIP_RIGHT_NUM1      = 5,
	VIP_RIGHT_NUM2      = 8,
	VIP_RIGHT_NUM3		= 7,
	VIP_RIGHT_NUM4		= 9,
	VIP_RIGHT_NUM5		= 7,
	VIP_RIGHT_NUM6		= 6,
	VIP_RIGHT_NUM7		= 9,
	VIP_RIGHT_NUM8		= 6,
	VIP_RIGHT_NUM9		= 5,
	VIP_RIGHT_NUM10     = 6,
	VIP_RIGHT_NUM11     = 5,
	VIP_RIGHT_NUM12     = 4,
	VIP_RIGHT_NUM13     = 5,
	VIP_RIGHT_NUM14     = 4,
	VIP_RIGHT_NUM15     = 4,
	VIP_RIGHT_NUM16     = 3,
}

AppDef.PItem = {}
AppDef.PItem.MAX_CUILIAN_ATTR_NUM = 9
AppDef.PItem.MAX_XILIAN_ATTR_NUM = 4
--可堆叠上限
AppDef.PItem.MAX_CAN_STACK = 200
-------------------------------------------------------------------
-----------------------帮派----------------------------------
AppDef.FactionInfo = {}
AppDef.FactionInfo.BPRT_NONE = 0
AppDef.FactionInfo.BPRT_BANGZHU = 1--帮主
AppDef.FactionInfo.BPRT_ZHANGLAO = 2--长老
AppDef.FactionInfo.BPRT_HUFA = 3--护法
AppDef.FactionInfo.BPRT_BANGZHONG = 4--帮众
--------------------------------------------------------------
AppDef.MAX_REMOND_NUM = 10 --金币消耗提示框类型数目

--------------------------------------------------------------
AppDef.Remond = {
    Pet_Wash = 0,
    QiangHua = 1,
    Horse_Stren = 2,
    Horse_Advan = 3,
    XiLian = 4,
    Xiangqian = 5,
    PetAmor = 6,
    Dakong = 7,
    PrayGodTree = 8,
}

AppDef.DonateCnt = {
    MaxCnt = 900,
}
--------------------------------------------------------------

--获取聊天频道资源
function AppDef:getChannelIcon(channelId)
    if channelId == AppDef.ChatChanelType.CCT_WORLD then
        return "res/UI/ui_liaotian/ui_main_liaotian_shijie.png"
    elseif(channelId == AppDef.ChatChanelType.CCT_NEAR or channelId == AppDef.ChatChanelType.CCT_BATTLE) then
    	return "res/UI/ui_liaotian/ui_main_liaotian_dangqian.png"
    elseif(channelId == AppDef.ChatChanelType.CCT_FACTION) then
        return "res/UI/ui_liaotian/ui_main_liaotian_bangpai.png"
    elseif(channelId == AppDef.ChatChanelType.CCT_TEAM) then
    	return "res/UI/ui_liaotian/ui_main_liaotian_zudui.png"		
    elseif channelId == AppDef.ChatChanelType.CCT_SYS or channelId == AppDef.ChatChanelType.CCT_LEITAI then
        return "res/UI/ui_liaotian/ui_main_liaotian_xitong.png"
    elseif channelId == AppDef.ChatChanelType.CCT_BPSYS then
    	return "res/UI/ui_liaotian/ui_main_liaotian_xitong.png"
    elseif channelId == AppDef.ChatChanelType.CCT_KUAFU then
    	return "res/UI/ui_liaotian/ui_main_liaotian_kuafu.png"
    end

    return "res/UI/ui_liaotian/ui_main_liaotian_shijie.png"
end


------------------------技能相关------------------------------------
AppDef.skill_Type =
{
        TAG_SKILL_BASE = 0,
        TAG_SKILL_SGL = 1,
        TAG_SKILL_MUL = 2,
		TAG_SKILL_SPC = 3,
		TAG_SKILL_AGL = 4,
        TAG_SKILL_FLEE = 5,
        TAG_HERO_ANGER_FULL_EFFECT = 6,
		TAG_HERO_RUNAWAY = 7,
}

AppDef.battle_Info =
{
        TAG_BATTLE_ID = 1, --战斗id
        TAG_BATTLE_TYPE = 2, --战斗类型
        TAG_ISAUTO = 3,      --是否自动战斗
		TAG_ISLOCKAUTO = 4,  --是否锁定自动战斗按钮
		TAG_WAITSECS = 5,   --每回合等待时间
        TAG_SHOWRUNAWAYFLAG = 6, --是否显示逃跑按钮
        TAG_BATTLEROUNDMAX = 7,  --最大回合数
		TAG_BATTLEROUNDIDX = 8, --当前回合数
		TAG_FORMATION_ENYMY = 9, --敌人的阵法ID
		TAG_FORMATION_ENYMY_LV = 10, --敌人阵法等级
		TAG_FORMATION_MINE = 11, --我的阵法ID
		TAG_FORMATION_MINE_LV = 12, --我的阵法等级
		TAG_FORMATION_MINE_ATTR = 13, --我的上阵信息
		TAG_FORMATION_ENEMY_ATTR = 14, --敌军上阵信息
}

------------------------多人闯关------------------------------------
AppDef.monopoly =
{
        ECGOp_Join = 1, -- 加入
		ECGOp_Sync = 2, 	-- 同步数据
		ECGOp_Roll = 3, 	-- roll点
		ECGOp_MoveEnd = 4,  -- 移动完成
		ECGOp_Msg = 5, 		-- 提示消息
		ECGOp_Hand = 6, 	-- 手头剪刀布协议消息
		ECGOp_Goal = 7, 	-- 获得元宝 与原协议一样
		ECGOp_Reset = 8, 	-- 重置闯关数据
		ECGOp_ResetRollCd = 9, -- 重置roll点cd时间
		ECGOp_FightReport = 10, -- 前端发起战斗
		ECGOp_Box = 11,     	-- 获得宝箱 与原协议一样ECGOp_End
		ECGOp_Robber = 12, 	-- 小贼战斗
		ECGOp_SyncCD = 13, 	-- 第一次进房间同步cd时间
		ECGOp_EnableCount = 14, -- 剩余有效进入次数
		ECGOp_QueryInfo = 15, -- 查询地图数据 15
		ECGOp_RandomEvent = 16, -- 随机事件 前进或者后退
		ECGOp_EmptyEvent = 17,  -- 走到没有事件的格子
		ECGOp_Coin = 18,        --    获得金币
		ECGOp_End = 19,      
		ECGOp_QueryEnemy = 20,  --    获取敌人数据 名字 等级 战斗力 奖励等

}


AppDef.CellEventType = 
{ 
	CellEvent_Empty = 0, -- 空
	CellEvent_Begin = 1 ,    -- 起点
	CellEvent_Robber = 2,    -- 战斗
	CellEvent_Box = 3,       -- 宝箱
	CellEvent_Hand = 4,      -- 猜拳
	CellEvent_End = 5,       -- 终点 
	CellEvent_Goal = 6,      -- 元宝
	CellEvent_Coin = 7,      -- 金币
	CellEvent_Random = 8,    -- 问号
}

--洗练石ID
AppDef.XiLianStoneIds = {610,2516,2517,2577}
--五色石ID
AppDef.WuSeStoneIds = {2821,2820,2819,2818}
--羽翼仙石ID
AppDef.YuyiStoneIds = {2538,2539,2540,2541,2542}

--地图ID(最后一个是主城)
AppDef.MapIds = {1,2,3,4,5,6,7,8,9,10,11}

AppDef.CopyOpType = {
	COPYPETOPOLD    = 0,--旧的宠物副本结算
	COPYPETOP       = 14,--宠物副本op
	COPYOTHEROP     = 15,--其余副本op
	COPYGOLDOP      = 16,--金钱副本op
	COPYEITEMOP     = 17,--道具副本
	COPYQIANNENGOP  = 18,--潜能副本
    COPYITEMXIANGOP = 25,--淬炼副本
    COPYITEMLIANOP  = 26,--炼化副本
    COPYITEMKAIOP   = 27,--宠铠副本

    BAIHUALIHEOP    = 28,--百花礼盒抽取
	PETCOPYTIANSHUOP= 32,--宠物天书副本
	COPYPETOPI		= 33,--终极寻宠副本掉三个宠物
	COPYMARRIAGEOP  = 34,--结婚副本
};

AppDef.FuncUI = {

	[AppDef.EModuleID.EMID_TASK_DALIY] = {lua="Activity.TaskLayer",sub = 1, ind = AppDef.UIType.SpecialLayer},

	[AppDef.EModuleID.EMID_BEIBAO] = {lua="Role.KaPaiBagMainUI",sub = 1, ind = AppDef.UIType.FirstClassLayer},
	[AppDef.EModuleID.EMID_RANK_Fuben] = {lua="Common.RankUI", sub=1, ind = AppDef.UIType.PopFirstClassLayer},
	[AppDef.EModuleID.EMID_RANK_JinhJi] = {lua="Common.RankUI", sub=2, ind = AppDef.UIType.PopFirstClassLayer},
	[AppDef.EModuleID.EMID_RANK_XueZhan] = {lua="Common.RankUI", sub=3, ind = AppDef.UIType.PopFirstClassLayer},
	[AppDef.EModuleID.EMID_RANK_Lv] = {lua="Common.RankUI", sub=4, ind = AppDef.UIType.PopFirstClassLayer},
	[AppDef.EModuleID.EMID_RANK_Pet] = {lua="Common.RankUI", sub=5, ind = AppDef.UIType.PopFirstClassLayer},
	[AppDef.EModuleID.EMID_RANK_Power] = {lua="Common.RankUI", sub=6, ind = AppDef.UIType.PopFirstClassLayer},
	[AppDef.EModuleID.EMID_RANK_Tujian] = {lua="Common.RankUI", sub=7, ind = AppDef.UIType.PopFirstClassLayer},

	[AppDef.EModuleID.EMID_ACTIVITY_REVERT] = {lua="WelfareActivity.WelfareActivityUI", sub=2, ind = AppDef.UIType.SpecialLayer},
	[AppDef.EModuleID.EMID_ACTIVITY_YAOQIANSHU] = {lua="WelfareActivity.WelfareActivityUI", sub=3, ind = AppDef.UIType.SpecialLayer},
    [AppDef.EModuleID.EMID_MONTHCARD] = {lua="WelfareActivity.WelfareActivityUI", sub=4, ind = AppDef.UIType.SpecialLayer},
    [AppDef.EModuleID.EMID_RECHARGE_CZJJ] = {lua="WelfareActivity.WelfareActivityUI", sub=5, ind = AppDef.UIType.SpecialLayer},
    [AppDef.EModuleID.EMID_RECHARGE_HYJJ] = {lua="WelfareActivity.WelfareActivityUI", sub=6, ind = AppDef.UIType.SpecialLayer},

    [AppDef.EModuleID.EMID_BANGPAI1] = {lua="BangPai.BangPaiListPage", sub=0, ind = AppDef.UIType.PopFirstClassLayer},
    [AppDef.EModuleID.EMID_SHOP_HUN] = {lua="Shop.JiangHunShop", ind = AppDef.UIType.PopFirstClassLayer},
    [AppDef.EModuleID.EMID_SHOP_JINGJI] = {lua="Shop.WanFaShopMainUI", sub=1,ind = AppDef.UIType.PopFirstClassLayer},
    [AppDef.EModuleID.EMID_SHOP_XUEZHAN] = {lua="Shop.WanFaShopMainUI", sub=2,ind = AppDef.UIType.PopFirstClassLayer},
    [AppDef.EModuleID.EMID_SHOP_TURNTABLE] = {lua="Shop.WanFaShopMainUI", sub=5,ind = AppDef.UIType.PopFirstClassLayer},


	[AppDef.EModuleID.EMID_LVUP]            = {lua="Role.LevelUpUI", ind = AppDef.UIType.PopWindow},
	[AppDef.EModuleID.EMID_PETCOMPOUND]            = {lua="KaPaiPet.PetCompoundTipUI", ind = AppDef.UIType.PopWindow},
    [AppDef.EModuleID.EMID_HERO]            = {lua="Role.RoleMainUI", sub=1},
    [AppDef.EModuleID.EMID_KAPAI_TITLE]     = {lua="Role.RoleMainUI", sub=2},
    [AppDef.EModuleID.EMID_SHEZHI]          = {lua="Role.RoleMainUI", sub=2},

    [AppDef.EModuleID.EMID_OTHER_ROLE_INFO] = {lua="OtherRole.OtherRoleMainUI", sub=1, ind = AppDef.UIType.PopFirstClassLayer},
  	[AppDef.EModuleID.EMID_OTHER_PET_INFO] = {lua="OtherRole.OtherRoleMainUI", sub=2, ind = AppDef.UIType.PopFirstClassLayer},
    
    [AppDef.EModuleID.EMID_BPXINXI]         = {lua="BangPai.BangPaiInfoUI", sub = 0, ind = AppDef.UIType.SpecialLayer},
    [AppDef.EModuleID.EMID_BPLIEBIAO]       = {lua="BangPai.BangPaiListPage", sub=0, ind = AppDef.UIType.PopFirstClassLayer},
    [AppDef.EModuleID.EMID_BPCHENGYUAN]     = {lua="BangPai.BangPaiMemList", sub=0, ind = AppDef.UIType.PopFirstClassLayer},
    [AppDef.EModuleID.EMID_BPFUBEN]     = {lua="BangPai.Fuben.BangPaiFuBenUI", sub=0, ind = AppDef.UIType.SpecialLayer},
    [AppDef.EModuleID.EMID_BPSKILL]     = {lua="BangPai.Fuben.BangPaiSkillUI", ind = AppDef.UIType.SecondClassLayer},
    [AppDef.EModuleID.EMID_BPRank]     = {lua="BangPai.Fuben.BangPaiFuBenRankUI", ind = AppDef.UIType.SecondClassLayer},
    [AppDef.EModuleID.EMID_BPQUICKFIGHT]     = {lua="BangPai.Fuben.BangPaiFuBenQuickFightUI", ind = AppDef.UIType.SecondClassLayer},
    [AppDef.EModuleID.EMID_BPHYREWARDPREVIEW]     = {lua="BangPai.Fuben.BangPaiHYRwardPreviewUI", ind = AppDef.UIType.PopWindow},

    [AppDef.EModuleID.EMID_BANGPAI]         = {lua="BangPai.BangPaiUI", sub=2},

    [AppDef.EModuleID.EMID_BPHUODONG]       = {lua="BangPai.BangPaiUI", sub=4},
    [AppDef.EModuleID.EMID_BPWAR]           = {lua="BangPai.BangPaiUI", sub=5},
    -- [AppDef.EModuleID.EMID_BPXIULIAN]       = {lua="BangPai.BangPaiUI", sub=6},
    
    [AppDef.EModuleID.EMID_DUANZAO]         = {lua="Forge.ForgeMainUI", sub=1},
    [AppDef.EModuleID.EMID_DZQIANGHUA]      = {lua="Forge.ForgeMainUI", sub=2},
    [AppDef.EModuleID.EMID_DZSHENGJIE]      = {lua="Forge.ForgeMainUI", sub=1},
    [AppDef.EModuleID.EMID_DZCUILIAN]       = {lua="Forge.ForgeMainUI", sub=4},
    [AppDef.EModuleID.EMID_DZXILIAN]        = {lua="Forge.ForgeMainUI", sub=3},
    
    [AppDef.EModuleID.EMID_ZUOJI]           = {lua="Mount.MountMainUI", sub=1},
    [AppDef.EModuleID.EMID_ZJJINJIE]        = {lua="Mount.MountMainUI", sub=2},
    [AppDef.EModuleID.EMID_ZJQIANGHUA]      = {lua="Mount.MountMainUI", sub=3},
    
    [AppDef.EModuleID.EMID_SHENJIANG]       = {lua="Pet.PetMainUI", sub=1},
    [AppDef.EModuleID.EMID_SJJINENG]        = {lua="Pet.PetMainUI", sub=2},
    [AppDef.EModuleID.EMID_SJSHENGXING]     = {lua="Pet.PetMainUI", sub=3},
    [AppDef.EModuleID.EMID_SJEQUIP]         = {lua="Pet.PetMainUI", sub=4},
    [AppDef.EModuleID.EMID_SJXIULIAN]       = {lua="Pet.PetMainUI", sub=5},
    [AppDef.EModuleID.EMID_SJBUZHEN]        = {lua="Pet.PetFormationSubUI", ind = AppDef.UIType.PopWindow},
    [AppDef.EModuleID.EMID_SJBUZHENWithEnemy]   = {lua="Common.PetFormationUI", ind = AppDef.UIType.FirstClassLayer},

    [AppDef.EModuleID.EMID_JINENG]          = {lua="Skill.SkillUI", sub=0},
    --[AppDef.EModuleID.EMID_SHEZHI]          = {lua="Setting.SettingMainUI", sub=1},

    [AppDef.EModuleID.EMID_YUYI]            = {lua="Wing.WingMainUI", sub=1},
    [AppDef.EModuleID.EMID_YYJINJIE]        = {lua="Wing.WingMainUI", sub=2},

    [AppDef.EModuleID.EMID_SHENQI]          = {lua="Artifact.ArtifactMainUI", sub=1},
    [AppDef.EModuleID.EMID_SQJINJIE]        = {lua="Artifact.ArtifactMainUI", sub=2},


    [AppDef.EModuleID.EMID_SCCHANGYONG]     = {lua="Shop.ShopUI", sub=1},
    [AppDef.EModuleID.EMID_SCSHENMI]        = {lua="Shop.ShopUI", sub=2},
    [AppDef.EModuleID.EMID_SCBANGDING]      = {lua="Shop.ShopUI", sub=3},
    [AppDef.EModuleID.EMID_SCJIFEN]        = {lua="Shop.ShopUI", sub=4},
    [AppDef.EModuleID.EMID_SCJIFEN]        	= {lua="Shop.ShopUI", sub=4},


    [AppDef.EModuleID.EMID_FULI]            = {lua="Welfare.WelfareUI", sub=0, ind = AppDef.UIType.SpecialLayer},
    [AppDef.EModuleID.EMID_FUBEN]          	= {lua="Instances.InstancesMainUI", sub=1},
    [AppDef.EModuleID.EMID_JINGJI]          = {lua="Arena.ArenaMainUI", sub=0},
    [AppDef.EModuleID.EMID_PAIHANGBANG]     = {lua="Rank.NewRankUI", sub=0},
    [AppDef.EModuleID.EMID_PAIHANGBANG_LILIAN]     = {lua="Rank.NewRankUI", sub=6},
    [AppDef.EModuleID.EMID_WANFA]           = {lua="Main.WanFaEntranceUI", sub=0,ind = AppDef.UIType.PopFirstClassLayer},
    [AppDef.EModuleID.EMID_KAPAI_VIP]             = {lua="Vip.VipMainUI", sub=2},
    [AppDef.EModuleID.EMID_KAPAI_RECHARGE]        = {lua="Vip.RechargeMainUI", sub=1},
    [AppDef.EModuleID.EMID_ZUDUI]           = {lua="Team.TeamMainUI", sub=0},

    [AppDef.EModuleID.EMID_SHEJIAO]         = {lua="Social.SocialLayer", sub=1},
    [AppDef.EModuleID.EMID_SJYOUJIAN]       = {lua="Social.SocialLayer", sub=1},
    [AppDef.EModuleID.EMID_HUISHOU]        = {lua="HuiShou.HuiShouMainUI", sub=1},

    --index的值对应AppDef.UIType
    [AppDef.EModuleID.EMID_FRIEND]        = {lua="Social.FriendLayer", sub=1, ind = AppDef.UIType.PopFirstClassLayer},
    [AppDef.EModuleID.EMID_FRIEND_SENDGIFT]        = {lua="Social.FriendLayer", sub=1, ind = AppDef.UIType.PopFirstClassLayer},

    [AppDef.EModuleID.EMID_MUBIAO]          = {lua="StageGoal.DouShenUI", sub=0, ind = AppDef.UIType.SpecialLayer},
    [AppDef.EModuleID.EMID_JINGJIE]         = {lua="JingJie.jingjieMainUI", sub=0},
    [AppDef.EActivityID.EAID_SHAKEMONEYTREE]  = {lua="Activity.MoneyTreeMainUI", sub=0},
    [AppDef.EActivityID.EAID_QIANNENGCOPY]    = {lua="Instances.InstancesMainUI", sub=6},

    [AppDef.EModuleID.EMID_CHOUKA]    	= {lua="LuckyDraw.LuckyDrawUI", sub=0, ind = AppDef.UIType.SpecialLayer},
    [AppDef.EModuleID.EMID_CHENHAO]    	= {lua="Role.RoleTitleUI", sub=0},

    [AppDef.EModuleID.EMID_TUJIAN]    	= {lua="HeroBook.HeroBookUI", sub=0},


    [AppDef.EModuleID.EMID_KAPAI_SHENJIANG]       = {lua="KaPaiPet.PetZhenRongUI", sub=0},
    [AppDef.EModuleID.EMID_KAPAI_SJJINENG]        = {lua="KaPaiPet.PetKaPaiMainUI", sub=1},
    [AppDef.EModuleID.EMID_KAPAI_SJSHENGXING]     = {lua="KaPaiPet.PetKaPaiMainUI", sub=2},
    [AppDef.EModuleID.EMID_KAPAI_EQUIPSRENGTH]         = {lua="EquipCultivate.EquipCultivateMainUI", sub={1}},
    [AppDef.EModuleID.EMID_KAPAI_EQUIP_jinglian]         = {lua="EquipCultivate.EquipCultivateMainUI", sub={2}},
    [AppDef.EModuleID.EMID_KAPAI_SJXIULIAN]       = {lua="KaPaiPet.PetKaPaiMainUI", sub=3},
    [AppDef.EModuleID.EMID_KAPAI_SJXIULIAN_REALY]       = {lua="KaPaiPet.PetKaPaiMainUI", sub=4},

    [AppDef.EModuleID.EMID_KAPAI_FABAO_SYS]       = {lua="FaBao.FaBaoMainUI", sub=1},

    [AppDef.EModuleID.EMID_KAPAI_PET_BAGS]       = {lua="KaPaiPet.PetBagMainUI", sub=1},
    [AppDef.EModuleID.EMID_KAPAI_FRAGMENT_BAGS]       = {lua="KaPaiPet.PetBagMainUI", sub=2},

    [AppDef.EModuleID.EMID_KAPAI_CHANGE_PET]       = {lua="KaPaiPet.PetChangeUI", sub=0},
    
    [AppDef.EModuleID.EMID_KAPAI_CHOUKA]    	= {lua="HappyDraw.HappyDrawUI", sub=0, ind = AppDef.UIType.SpecialLayer},
    [AppDef.EModuleID.EMID_KAPAI_CHOUKA_FRIEND]    	= {lua="HappyDraw.HappyDrawUI", sub=0, ind = AppDef.UIType.SpecialLayer},

	[AppDef.EModuleID.EMID_KAPAI_FENGSHEN]    	= {lua="Activity.FengShenShiLianUI", sub=0},
    [AppDef.EModuleID.EMID_KAPAI_FS_1]      = {lua="Activity.FengShenShiLianUI", sub=1},
    [AppDef.EModuleID.EMID_KAPAI_FS_2]      = {lua="Activity.FengShenShiLianUI", sub=2},
    [AppDef.EModuleID.EMID_KAPAI_FS_3]      = {lua="Activity.FengShenShiLianUI", sub=3},
    [AppDef.EModuleID.EMID_KAPAI_FS_4]      = {lua="Activity.FengShenShiLianUI", sub=4},
    [AppDef.EModuleID.EMID_KAPAI_XUEZHAN]       = {lua="XueZhan.XueZhanMainUI", sub=0},
    [AppDef.EModuleID.EMID_KAPAI_FENGSHEN_STORY] = {lua="FengShenStory.FengShenStoryMainUI", sub=0},
	[AppDef.EModuleID.EMID_KAPAI_JUEZHANKUNLUN]    	= {lua="JueZhanKunLun.KunLunJueZhanUI", sub=0},
    [AppDef.EModuleID.EMID_KAPAI_WF_FS_STORY]  = {lua="FengShenStory.FengShenStoryMainUI", sub=0},
    [AppDef.EModuleID.EMID_KAPAI_WF_ARENA]  = {lua="WanFa.KaPaiArenaUI", sub=0,ind = AppDef.UIType.SpecialLayer},
    [AppDef.EModuleID.EMID_KAPAI_EQUIP_BAG] = {lua="PetEquip.PetEquipMainUI", sub=1},
	[AppDef.EModuleID.EMID_SHENJIANG_CHOOSE] = {lua="HuiShou.ShengJiangChooseUI", sub={1},ind = AppDef.UIType.PopFirstClassLayer},
	[AppDef.EModuleID.EMID_ZHUANGBEI_CHOOSE] = {lua="HuiShou.ShengJiangChooseUI", sub={2},ind = AppDef.UIType.PopFirstClassLayer},
	[AppDef.EModuleID.EMID_FABAO_CHOOSE] = {lua="HuiShou.ShengJiangChooseUI", sub={3},ind = AppDef.UIType.PopFirstClassLayer},
	[AppDef.EModuleID.EMID_ZHUANGBEI_FENJIE_CHOOSE] = {lua="HuiShou.ZhuangBeiChooseUI", sub=0,ind = AppDef.UIType.PopFirstClassLayer},
	[AppDef.EModuleID.EMID_FABAO_FENJIE_CHOOSE] = {lua="HuiShou.ZhuangBeiChooseUI", sub=1,ind = AppDef.UIType.PopFirstClassLayer},
    [AppDef.EModuleID.EMID_KAPAI_XUNBAO] = {lua="WanFa.XunBaoMainUI", sub=0, ind = AppDef.UIType.SpecialLayer},

    [AppDef.EModuleID.EMID_KAPAI_ZHUXIANFUBEN] = {lua="FuBenMap.NormalFuBenUI", ind = AppDef.UIType.Normal},
    [AppDef.EModuleID.EMID_CHONGSHENG_CONFIRM] = {lua="HuiShou.ChongShengConfirmUI", sub=0, ind = AppDef.UIType.PopWindow},

    [AppDef.EModuleID.EMID_QIRI] = {lua="OperationalActivity.SevenDay", sub=0,ind = AppDef.UIType.SpecialLayer},


    [AppDef.EModuleID.EMID_KAPAI_FABAO_QIANGHUA] = {lua="FaBao.FaBaoCultivateMainUI", sub=1},
    [AppDef.EModuleID.EMID_KAPAI_FABAO_JINGLIAN] = {lua="FaBao.FaBaoCultivateMainUI", sub=2},

    [AppDef.EModuleID.EMID_SHOP_KUNLUN] = {lua="Shop.WanFaShopMainUI", sub=4, ind = AppDef.UIType.PopFirstClassLayer},
    [AppDef.EModuleID.EMID_SHOP_BANGPAI] = {lua="Shop.WanFaShopMainUI", sub=3, ind = AppDef.UIType.PopFirstClassLayer},
    
    [AppDef.EModuleID.EMID_KAPAI_GIFT_ZHEKOU1] = {lua="Shop.NewDiscountBagUI", sub=89, ind = AppDef.UIType.PopWindow},--折扣礼包1
    [AppDef.EModuleID.EMID_KAPAI_GIFT_ZHEKOU2] = {lua="Shop.NewDiscountBagUI", sub=90, ind = AppDef.UIType.PopWindow},--折扣礼包2
    [AppDef.EModuleID.EMID_KAPAI_GIFT_ZHEKOU3] = {lua="Shop.NewDiscountBagUI", sub=91, ind = AppDef.UIType.PopWindow},--折扣礼包3

    -----------------------------------------------------------------------------------------------------------------------
    -- [AppDef.EModuleID.EMID_RECHARGE_SHOWCHONG] = {lua="Recharge.FirstRechargeUI", sub=0, ind = AppDef.UIType.SpecialLayer},
    [AppDef.EModuleID.EMID_WANFA_KLXB] = {lua="Monopoly.MonopolyBaseUI", sub=0, ind = AppDef.UIType.Normal},
	[AppDef.EModuleID.EMID_SEVENDAY_LOGIN] = {lua="Welfare.LoginGiftUIPage",sub=0, ind = AppDef.UIType.PopWindow},
	[AppDef.EModuleID.EMID_QUESTION] = {lua="Activity.AnswerUI", sub=0},
    [AppDef.EModuleID.EMID_WORLDBOSS] = {lua="WanFa.WorldBossMainUI", sub=0,ind = AppDef.UIType.SpecialLayer},
    [AppDef.EModuleID.EMID_KAPAI_YOULISANJIE] = {lua="WanFa.YouLiMainUI", sub=0},
}

AppDef.FunctionIcon = {
    [AppDef.EModuleID.EMID_JINGJI]          = "res2/Icon/ui_main_icon/ui_main_icon_jingji.png",
    [AppDef.EModuleID.EMID_HECHENG]         = "res2/Icon/ui_main_icon/ui_main_icon_hecheng.png",
	[AppDef.EModuleID.EMID_LIANHUA]         = "res2/Icon/ui_main_icon/ui_main_icon_lianhua.png",
    [AppDef.EModuleID.EMID_FENJIE]          = "res2/Icon/ui_main_icon/ui_main_icon_fenjie.png",
    [AppDef.EModuleID.EMID_CHOUKA]          = "res2/Icon/ui_main_icon/ui_main_icon_chouka.png",
    [AppDef.EModuleID.EMID_SHOP_BANGPAI]     = "res2/Icon/ui_main_icon/ui_main_icon_bangpaishangcheng.png",
    [AppDef.EModuleID.EMID_SCCHANGYONG]     = "res2/Icon/ui_main_icon/ui_main_icon_shangcheng.png",
    [AppDef.EModuleID.EMID_SCSHENMI]        = "res2/Icon/ui_main_icon/ui_main_icon_shenmishangcheng.png",
    [AppDef.EModuleID.EMID_SCBANGDING]      = "res2/Icon/ui_main_icon/ui_main_icon_bangyuanshangcheng.png",
    [AppDef.EModuleID.EMID_SCTEGONG]        = "res2/Icon/ui_main_icon/ui_main_icon_shenhunshangcheng.png",
	[AppDef.EModuleID.EMID_SCJIFEN]        = "res2/Icon/ui_main_icon/ui_main_icon_jifenshangcheng.png",
    [AppDef.EModuleID.EMID_DRUGSTORE]       = "res2/Icon/ui_main_icon/ui_main_icon_zahuoshangcheng.png",
    [AppDef.EModuleID.EMID_SEEDSTORE]       = "res2/Icon/ui_main_icon/ui_main_icon_zhongzishangcheng.png",
	[AppDef.EModuleID.EMID_SJEQUIP]         = "res2/Icon/ui_main_icon/ui_main_icon_shenjiang.png",
    [AppDef.EModuleID.EMID_FUBEN]          	= "res2/Icon/ui_main_icon/ui_main_icon_fuben.png",
    [AppDef.EModuleID.EMID_FUBEN+1]         = "res2/Icon/ui_main_icon/ui_main_icon_fuben.png",
    [AppDef.EModuleID.EMID_FUBEN+2]         = "res2/Icon/ui_main_icon/ui_main_icon_fuben.png",
    [AppDef.EModuleID.EMID_FUBEN+3]         = "res2/Icon/ui_main_icon/ui_main_icon_fuben.png",
    [AppDef.EModuleID.EMID_FUBEN+4]         = "res2/Icon/ui_main_icon/ui_main_icon_fuben.png",
    [AppDef.EModuleID.EMID_FUBEN+5]         = "res2/Icon/ui_main_icon/ui_main_icon_fuben.png",
    [AppDef.EModuleID.EMID_FUBEN+11]        = "res2/Icon/ui_main_icon/ui_main_icon_fuben.png",
    [AppDef.EModuleID.EMID_FUBEN+12]        = "res2/Icon/ui_main_icon/ui_main_icon_fuben.png",
    [AppDef.EModuleID.EMID_FUBEN+13]        = "res2/Icon/ui_main_icon/ui_main_icon_fuben.png",
    [AppDef.EModuleID.EMID_FUBEN+14]        = "res2/Icon/ui_main_icon/ui_main_icon_fuben.png",
}
AppDef.BuffType={
   WorldLevel=1,--世界等级
   ExperienceMC=2,--体验月卡
   PlatinumMC=3,--白金月卡
   Team = 4,--组队加成
}

AppDef.PetEquipLevelType = {
    QiangHua = 1,
    JingLian = 2,
    JueXing = 3,
    ShenZhu = 4,
}

AppDef.PetFaBaoLevelType = {
	QiangHua = 5, 
	JingLian = 6,
}

AppDef.MapType = {
	MainLine = 1,--主线
	SubLine = 2,--支线
	Shilian = 3,--封神试炼
	HeroCopy = 4,--英雄列传
	FactionCopy = 5,--工会副本
}
