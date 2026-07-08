#ifndef _PARA_DEF_H_
#define _PARA_DEF_H_

enum EBitSetType
{

};

enum EExtData8Type
{
	EData8_BPCopyNum = 648,	// 帮派副本次数
	EData8_GetFriendGift = 649,	// 领取好友赠送礼物次数

};

enum EExtData16Type
{


};

enum EExtData32Type
{
	EData32_HuoYueDu_Week = 478,	// 周活跃度
	EData32_HuoYueDu_Day = 479,		// 日活跃度
};

enum EExtData64Type
{
	EData64_MaxZhanDouLi = 1,	// 最高战斗力
};




///////////////// 功能红点  ////////////////////

enum EFuncPointStatus
{	
	EHPointS_NotShow = 0,
	EHPointS_Show = 1,
};

enum EFuncHotPointType
{
	EHPoint_BP_UpgradeSkill = 1,	// 帮派副本技能是否可升级
	EHPoint_BP_JoinApply = 2,		// 帮派是否有入帮申请
	EHPoint_BP_Event = 3,			// 帮派事件
	EHPoint_BP_CopyAward = 4,		// 帮派副本是否有可领取的奖励
	EHPoint_BP_HuoYueAward = 5,		// 帮派活跃度奖励是否可领取

	EHPoint_Fri_RecvAward = 21,		// 好友收到礼物通知
	EHPoint_Fri_RecvApply = 22,		// 好友收到申请列表

	EHPoint_Mail = 31,	// 邮件通知


	EHPoint_BeiGongji = 41,		// 被攻击
	EHPoint_XueZhan = 51,		// 血战昨日奖励
	EHPoint_ChengJiu = 61,		// 成就
	EHPoint_XiangZi = 62,		// 箱子
	EHPoint_ShiLian = 63,		// 试炼
	EHPoint_FuBen = 64,			// 副本
	EHPoint_Shop1 = 71,			// 竞技奖励商店
	EHPoint_Shop2 = 72,			// 血战奖励商店

	EHPoint_Quest_1 = 101,		// 竞技场
	EHPoint_Quest_2 = 102,		// 每日
	EHPoint_Quest_3 = 103,		// 竞技场
	EHPoint_Quest_4 = 104,		// 成就
	EHPoint_TiLi = 111,			// 体力
	EHPoint_ZhaoHui = 121,		// 找回
	EHPoint_TuJian = 131,		// 图鉴
	EHPoint_HDQuest = 201,		// 七日活动
	//EHPoint_HDQuest = 202,		// 基金
	
};

///////////////// 玩家记录  ////////////////////
enum UserRecordType
{
	ERT_GuanQia = 1,
	ERT_QiRi = 2,
};


///////////////// 货币使用 ////////////////////
enum MoneyUseType
{
	MUT_ChongZhi = 1,		// 关卡重置
	MUT_KunLun = 2,		// 昆仑次数
	MUT_EChongSheng = 3,	// 装备重生
	MUT_FChongSheng = 4,	// 法宝重生
	MUT_HChongSheng = 5,	// 英雄重生
	MUT_GaiMing = 6,		// 改名
	MUT_BGaiMing = 7,		// 帮派改名
	MUT_ZhaoHui = 8,		// 资源找回
	MUT_BangFuBen = 9,		// 帮派副本
	MUT_ChouKa = 10,		// 抽卡
	MUT_QiRiDengLu = 31,	// 七日活动
	MUT_GuanQiaFix = 101,	// 关卡箱子
	MUT_GuanQiaChengJiu = 103,	// 成就
	MUT_GuanQiaLieZhuan = 104,	// 列传
	MUT_ShiLian = 105,			// 试炼
	MUT_JingJiChang = 106,		// 竞技场
	MUT_RenWu = 107,			// 任务
	MUT_KunLunAd = 108,			// 昆仑决战
	MUT_XueZhanRank = 109,		// 血战排行
	MUT_XueZhanFirst = 110,		// 血战首通
	MUT_XueZhanFix = 111,		// 血战箱子
	MUT_GuanQiaNode = 112,		// 推图
	MUT_XunBaoAd = 113,			// 昆仑寻宝
	MUT_DaTi = 114,				// 答题
	MUT_Shop = 200,			// 200 + 商店类型
};
#endif
