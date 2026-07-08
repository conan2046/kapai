--注：ID和IDEnd中间是实时扩展的栏目，不可插入任何ID
RedDotDef = {}
RedDotDef.ID = {
	--福利
	-- Fuli = 10,
	-- FLDengLu = 11,
	-- FLDengJi = 12,
	-- FLQianDao = 13,
	-- FLBaiJin = 14,
	-- FLLiXian = 15,
	-- FLFindRes = 16,
	-- FLZaiXian = 17,
	-- FLDengLuItem = 18,
	-- FLDengJiItem = 19,
	-- FLQianDaoItem = 20,
	-- FLBaiJinItem = 21,
	-- FLLiXianItem = 22,
	-- FLFindResItem = 23,
	-- FLZaiXianItem = 24,
	-- FuliEnd = 29,--福利结束
	--新福利
	Fuli = 10,--福利
	Fuli_Tili = 11,--体力领取
	Fuli_ResRecovery = 12,--资源找回
	FuliEnd = 29,

	--开服活动
	HuoDong = 30,
	HDBase = 31,
	HuoDongEnd = 49,--开服活动结束

	--帮派
	BangPai = 50,
	BPXinXi = 51,
	BPChengYuan = 52,
	BPShiJian = 53,
	BPFuben = 54,
	-- BPHuoDong = 53,
	BPShenQing = 55,--帮派申请
	BPJiangLi = 56,--活跃奖励
	BPSkillUpgrade = 57,
	BPFubenJiangLi = 58,--副本奖励
	--BPHuoYueDu = 58,
	--BPZongHuoYueDu = 59,
	--BPFubenHuoyueJiangLi = 59,
	--BPKeji = 59,
	BPXiuLian = 60,
	BangPaiEnd = 61,--帮派结束

	--技能
	JiNeng = 101,
	JiNengEnd = 102,--技能结束

	--羽翼
	YuYi = 201,--羽翼按钮
	YuYiXinXi = 202,--信息tab
	YuYiJinJie = 203,--进阶tab
	YuYiJJPeiYang = 204,--进阶培养按钮
	YuYiXXBase = 205,--信息
	YuYiXXBaseEnd = 265,--信息结束（目前支持60个羽翼，不够再扩）
	YuYiEnd = 300,--羽翼结束

	--顶部折叠按钮
	DingBu = 311,
	--副本
	FuBen = 321,

	FengShengTab1 = 323,
	FengShengTab2 = 324,
	FengShengTab3 = 325,
	FengShengTab4 = 326,
	--竞技
	--JingJi = 331,

	--穿戴
	ChuanDai = 401,
	--装备背包
	ZhuangBei = 411,
	ZBBeiBao = 412,
	ZBSuiPian = 413,
	ZhuangBeiEnd = 415,
	--法宝背包
	FaBao = 416,
	FBBeiBao = 417,
	FBSuiPian = 418,

	--神将背包
	ShenjiangBag = 450, --神将背包
	Shenjiang_tag = 451,  --神将
	ShuiPian_tag = 452,   --碎片
    ShenJiangTuJian= 453,--神将图鉴

	--神将阵容
	ShenJiangZhenRong = 460, --神将阵容
	ShenJiangYangCheng = 461, --神将养成
	ShenJiang_LVUp = 462, -- 神将升级
	ShenJiang_StarUp = 463, -- 神将升星星
	ShenJiang_BreakUp = 464, --神将突破
	ShenJiang_XiuLian = 468, --神将天命激活

	ShenJiang_ShangZhen = 465, --神将坑位
	
	ShenJiang_Change = 466, --换将
	ShenJiang_BuZhen=467,--神将布阵

	----------------------------------------
	--抽卡
	HappyDraw = 470,
	HD_Normal_DanCi = 471,
	HD_Normal_ShiLian = 472,
	HD_GaoJi_DanCi = 473,
	HD_GaoJi_ShiLian = 474,
	HD_FriendLy_DanCi = 475,
	HD_FriendLy_ShiLian = 476,

	---------------------好友社交--------------------------
	Friend = 480,
	FriendApply = 481,
	FriendGift = 482,
	FriendEnd = 483,

	--------邮件-------------------
	Mail = 490,
	MailNew = 491,
	MailEnd = 492,
	---------------------------------------
	QiRiActivity = 493,

	-----------玩法-------
	WanFa = 500,
	KunLunJueZhan = 501,
	
	Arena = 511,
	ArenaTask = 512,--竞技场日常任务
	AreanReport = 513,--竞技场被攻击战报
	AreanEnd = 515,

	XueZhan = 521,
	XueZhanDraw = 522,--昨日奖励待领取
	XueZhanEnd = 525,

	XunBao = 526,
	XunBaoTask = 527, --寻宝日常任务
	XunBaoHeCheng = 528,--法宝合成
	XunBaoEnd = 529,

	--------------------------
	Chat = 550,
	Chat_Private = 551,--私聊
	ChatEnd = 552,
	-----------------------------------
	FuBenAchievement = 600, --主线成就
	FuBenMap = 601, --大地图
	FengShengShiLian = 602, --封神试炼

	---------------------------------
	DaliyTask = 650,--每日任务

	-- Shop = 701,--商店
	-- XueZhanShop = 702,--血战奖励商店可购买
	-- JingjiShop =  703,--竞技奖励商店可购买
	-- ShopEnd = 710,

	----------------------------------------------------
	
	EquipZhenRong = 800,
	EquipShengJiang1 = 801,
	EquipShengJiang2 = 802,
	EquipShengJiang3 = 803,
	EquipShengJiang4 = 804,
	EquipShengJiang5 = 805,

	-----------------------------------------------
	ShopMain = 850, --商店
	ShopJiangHun = 851, --将魂商店
	ShopWanFa = 852,   --玩法商店

	ShopWanFaJingji = 853, --竞技场商店
	ShopWanFaXueZhan = 854, --血战商店
}

--[[
服务器传过来的类型和客户端的对照表
]]
RedDotDef.SID = {
	BPSkillUpgrade = 1,
	BPShenQing = 2,--帮派申请
	BPShiJian = 3,
	BPFubenJiangLi = 4,
	BPJiangLi = 5,

	FriendGift = 21,
	FriendApply = 22,

	MailNew = 31,--新邮件

	AreanReport = 41,--竞技场被攻击战报
	XueZhanDraw = 51,--血战昨日奖励待领取

	ShopWanFaJingji = 71,--竞技商店奖励页签
	ShopWanFaXueZhan = 72,--血战商店奖励页签

	ArenaTask = 101,--竞技场任务
	DaliyTask = 102,--每日任务
	XunBaoTask = 103,--寻宝任务

	QiRiActivity = 201,  --七日任务

	FuBenAchievement = 61, --主线成就
	FengShengShiLian = 63, --封神试炼
	FuBenMap = 64, --副本地图

	Fuli_Tili = 111,--体力领取
	Fuli_ResRecovery = 121,--资源找回
	ShenJiangTuJian=131,

}

RedDotDef.SIDMap = {
	[RedDotDef.SID.BPSkillUpgrade] = RedDotDef.ID.BPSkillUpgrade,
	[RedDotDef.SID.BPShenQing] = RedDotDef.ID.BPShenQing,--帮派申请
	[RedDotDef.SID.BPShiJian] = RedDotDef.ID.BPShiJian,--
	[RedDotDef.SID.BPFubenJiangLi] = RedDotDef.ID.BPFubenJiangLi,--
	[RedDotDef.SID.BPJiangLi] = RedDotDef.ID.BPJiangLi,--
	
	[RedDotDef.SID.FriendGift] = RedDotDef.ID.FriendGift,--
	[RedDotDef.SID.FriendApply] = RedDotDef.ID.FriendApply,--

	[RedDotDef.SID.MailNew] = RedDotDef.ID.MailNew,--

	[RedDotDef.SID.AreanReport] = RedDotDef.ID.AreanReport,
	[RedDotDef.SID.XueZhanDraw] = RedDotDef.ID.XueZhanDraw,
	[RedDotDef.SID.ArenaTask] = RedDotDef.ID.ArenaTask,
	[RedDotDef.SID.XunBaoTask] = RedDotDef.ID.XunBaoTask,

	[RedDotDef.SID.ShopWanFaJingji] = RedDotDef.ID.ShopWanFaJingji,
	[RedDotDef.SID.ShopWanFaXueZhan] = RedDotDef.ID.ShopWanFaXueZhan,

	[RedDotDef.SID.QiRiActivity] = RedDotDef.ID.QiRiActivity,--七日任务

	[RedDotDef.SID.FuBenAchievement] = RedDotDef.ID.FuBenAchievement,--主线成就
	[RedDotDef.SID.FuBenMap] = RedDotDef.ID.FuBenMap,--副本地图
	[RedDotDef.SID.FengShengShiLian] = RedDotDef.ID.FengShengShiLian,--封神试炼

	[RedDotDef.SID.Fuli_Tili] = RedDotDef.ID.Fuli_Tili,--体力领取
	[RedDotDef.SID.Fuli_ResRecovery] = RedDotDef.ID.Fuli_ResRecovery,--资源找回
	[RedDotDef.SID.ShenJiangTuJian]=RedDotDef.ID.ShenJiangTuJian,--神将图鉴
	
	[RedDotDef.SID.DaliyTask] = RedDotDef.ID.DaliyTask,--每日任务
}

return RedDotDef