#ifndef _SKILL_H_
#define _SKILL_H_

#include "self_typedef.h"
#include <string>
#include <vector>
#include <map>
#include <string.h>
using namespace std;

enum EXiang
{
	EXJinXiang = 1,	// 1 -金
	EXMuXiang,		// 2－木
	EXShuiXiang,	// 3－水
	EXHuoXiang,		// 4－火
	EXTuXiang		// 5－土
};

enum ESkillTotolType	// 技能大类
{
	ESTT_Attack = 1,	// 攻击
	ESTT_FuZhu,			// 辅助
	ESTT_FuMian,		// 负面
	ESTT_BeiDong,		// 被动
};

enum EFightOptionType
{
	EFOT_Normal = 0,		// 普攻
	EFOT_DamageHp = 1,	// 伤血技能
	EFOT_AddHp = 2,	// 加血技能
	EFOT_Buff = 3,	// buff施法技能
	EFOT_ZhaoHuan = 4,	// 召唤
	EFOT_Escape = 5,	// 逃跑
	EFOT_Passive = 6,	// 被动技能触发
	EFOT_Dialog = 7,	// 战斗说话
};

struct SSkillData
{
	SSkillData():id(0),level(0),ratio(100),CD(0),leftCD(0){}
	SSkillData(uint16 skillId,uint16 skill_lv):id(skillId),level(skill_lv),ratio(100),CD(0),leftCD(0){}
	uint16 id;
	uint16 level;
	int ratio;
	int CD;
	int leftCD;	// =0则可以行动
};
typedef vector<SSkillData> skillVec;

struct SkillInfoNode
{
	uint16 id;
	uint16 learnLevel;
	uint8 xiang;
	string name;
	string desc;
};

////////////////////////////////////////////////////////////////////////////////

enum ESkillPassiveAttrType
{
	ESkill_PassAttr_Damage = 101,	// 伤害值
	ESkill_PassAttr_DamagePer = 102,	// 伤害百分比
	ESkill_PassAttr_AddHp = 103,	// 恢复生命值
	ESkill_PassAttr_AddHpPer = 104,	// 恢复生命值百分比
	ESkill_PassAttr_BaoJiLv = 105,	// 暴击率
	ESkill_PassAttr_FanJiLv = 106,	// 反击率
	ESkill_PassAttr_FuMian = 107,	// 负面概率
	ESkill_PassAttr_FanShang = 108,	// 反伤
	ESkill_PassAttr_HuShiFang = 109,	// 忽视防御
	ESkill_PassAttr_IgnoreDun = 110,	// 无视护盾
	ESkill_PassAttr_FanJiAdd = 111,	// 反击伤害
	ESkill_PassAttr_NormalAttack = 112,	// 额外普攻一次
	ESkill_PassAttr_UseSameSkill = 113,	// 技能再用一次
	ESkill_PassAttr_ZhongDuKang = 114,	// 提升中毒抵抗
	ESkill_PassAttr_ImproveMianShangLv = 115,	// 提升免伤率
	ESkill_PassAttr_NotDecHp = 116,	// 免疫伤害
	ESkill_PassAttr_AttackActionAgain = 117,	// 重复上次攻击
	ESkill_PassAttr_JinLiaoShuDamRatio = 118,	// 禁疗术伤害比例
	ESkill_PassAttr_FanJianDamRatio = 119,	// 反间伤害加成
	ESkill_PassAttr_protectDamage = 120,	// 分担伤害
};


const uint8 BuffStateNum = 4;	// 不显示32*(BuffStateNum-ShowBuffStateNum)状态
const uint8 ShowBuffStateNum = 2; // 显示32*BuffStateNum个状态

enum ESKillBuffType
{
	ESBUFF_ChaoFeng = 1,	// 嘲讽, 强制普攻施法者
	ESBUFF_ChenMo = 2,		// 沉默, 不能使用技能
	ESBUFF_FengYin = 3,		// 封印, 不能使用技能
	ESBUFF_HunShui = 4,		// 昏睡, 昏睡状态下无法行动，被攻击3次苏醒
	ESBUFF_HunLuan = 5,		// 混乱, 目标敌我不分随机普攻敌我双方1人
	ESBUFF_MeiHuo = 6,		// 魅惑, 目标敌我不分随机普攻敌我双方1人
	ESBUFF_FanJian = 7,		// 反间, 目标敌我不分随机普攻敌我双方1人
	ESBUFF_ShiXinDu = 8,	// 食心毒, 目标行动时受到最大生命值一定百分比的伤害
	ESBUFF_ShiDu = 9,		// 尸毒, 目标每回合开始时受到固定值的伤害
	ESBUFF_FuDu = 10,		// 腐毒, 目标每回合开始时受到当前生命值一定百分比的伤害
	ESBUFF_ZhuoShao = 11,	// 灼烧, 受到每回合受到施法者攻击值一定百分比的伤害
	ESBUFF_ZengShangLvAdd = 12,	// 增伤提升
	ESBUFF_ZengShangLvDes = 13,	// 增伤下降
	ESBUFF_JianShangLvAdd = 14,	// 减伤提升
	ESBUFF_JianShangLvDes = 15,	// 减伤下降
	ESBUFF_WuMianLvAdd = 16,	// 物免提升
	ESBUFF_WuMianLvDes = 17,	// 物免下降
	ESBUFF_FaMianLvAdd = 18,	// 法免提升
	ESBUFF_FaMianLvDes = 19,	// 法免下降
	ESBUFF_DamageDes = 20,		// 降低输出伤害
	ESBUFF_GetDamageAdd = 21,	// 受到伤害增加
	ESBUFF_GetWuDamageAdd = 22,		// 受到物理伤害增加
	ESBUFF_GetFaDamageAdd = 23,	// 受到法术伤害增加
	ESBUFF_WuMianAndGetFaDamageAdd = 24,	// 使目标不会受到物理伤害，但受到的法术伤害增加
	ESBUFF_DamagePercentAdd = 25,		// 攻击百分比提升
	ESBUFF_DamagePercentDes = 26,		// 攻击百分比降低
	ESBUFF_JinGuZhou = 27,		// 紧箍咒， 降低目标百分比攻击，且每回合受到施法者攻击百分比伤害
	ESBUFF_FangYuDes = 28,		// 防御降低, 降低目标百分比防御
	ESBUFF_FaFangDes = 29,		// 法术防御降低, 降低目标百分比法术防御
	ESBUFF_WuFangDes = 30,		// 物理防御降低, 降低目标百分比物理防御
	ESBUFF_BaoJiLvAdd = 31,		// 暴击率提升, 提升暴击率
	ESBUFF_BaoJiShangHaiAdd = 32,	// 暴击伤害提升, 提升暴击伤害
	ESBUFF_BaoJiKangDes = 33,	// 抗暴率降低, 降低抗暴率
	ESBUFF_FuMianKangAdd = 34,	// 负面抵抗提升, 提升负面抵抗
	ESBUFF_ZhongDuKangAdd = 35,	// 中毒抵抗提升, 提升中毒抵抗
	ESBUFF_FuMianKangDes = 36,	// 负面抵抗降低, 降低负面抵抗
	ESBUFF_FanZhengAllAdd = 37,	// 反震效果提升, 提升反震率和反震伤害
	ESBUFF_FanZhengLvAdd = 38,	// 反震率提升, 提升反震率
	ESBUFF_ShanBiLvAdd = 39,	// 闪避率提升, 提升闪避率
	ESBUFF_SpeedDes = 40,		// 速度降低, 降低百分比速度
	ESBUFF_Protect = 41,		// 保护状态, 保护目标，为其分担受到的伤害，同时提升双方的减免率
	ESBUFF_ShieldMianShang = 42,		// 护盾免伤, 吸收一定比例最大生命值的护盾，并提升一定比例免伤率
	ESBUFF_Shield = 43,			// 护盾, 吸收一定比例最大生命值的护盾
	ESBUFF_JinLiaoShu = 44,		// 禁疗术, 降低目标受到的治疗效果
	ESBUFF_AddHpContinue = 45,		// 持续治疗, 每回合恢复施法者攻击一定比例的气血值
	ESBUFF_Blooding = 46,		// 流血，每回合受到施法者攻击值一定百分比的伤害，如若目标处于降攻状态，伤害增加20%
	ESBUFF_LianJiLvAdd = 47,		// 连击率提升，提升连击率
	ESBUFF_LianJiLvShangHaiAdd = 48,		// 连击伤害提升，提升连击伤害
	ESBUFF_WuGongDes = 49,		// 物理降伤，使目标的物理输出伤害降低
	ESBUFF_FaGongDes = 50,		// 法术降伤，使目标的法术输出伤害降低
	ESBUFF_GongTongShengSi = 51,		// 共同生死,所有单位共同分担伤害
	ESBUFF_FuMianQiangHuaAdd = 52,		// 负面强化提升，提升负面强化
	ESBUFF_ReduceMingZhongLv = 53,		// 命中率降低
	ESBUFF_AddMingZhongLv = 54,			// 命中率提高
	ESBUFF_AddSpeed = 55,		// 速度提升, 百分比
	ESBUFF_ForbidFuHuo = 56,	// 禁止复活

	ESBUFF_WaitForTurn = 63,	// 等待一回合



	ESBUFF_ShowBegin = 190,		// 超过这个值不发给客户端

	// 以下buff不传给客户端，添加需注意
	ESBUFF_NOT_MOVE,		// 无法行动
	ESBUFF_ImproveCureHp,	// 提升受到的治疗效果
	ESBUFF_MianShangTemp,	// 临时免伤率

	ESBUFF_MAX,

	// 驱散时使用
	ESBUFF_AllEnBuff = 200,
	ESBUFF_AllDeBuff = 201,
	ESBUFF_AllZhongDu = 202,
};

enum EFightStateType
{
	EFST_STATE_Die = 1,		// 死亡
	EFST_STATE_Escape = 2,	// 逃跑

	EFST_STATE_MAX,
};

struct SSkillEffectCfg
{
	SSkillEffectCfg()
	{
		Clear();
	}
	void Clear()
	{
		effectType = 0;
		effectIdList.clear();
	}
	int GetEffectId();
	
	int effectType;
	vector<int> effectIdList;
};

enum ESkillActiveType
{
	ESkill_Active_Attack = 1,	// 攻击
	ESkill_Active_MulAttack = 2,	// 多段攻击
	ESkill_Active_AddHpByDam = 3,	// 攻击值治疗
	ESkill_Active_AttackByHpPer = 4,	// 当前气血百分比伤害
	ESkill_Active_AttackByDesHp = 5,	// 以血还血
	ESkill_Active_FuHuo = 6,	// 复活
	ESkill_Active_AddHpNormal = 7,	// 气血类治疗
	ESkill_Active_Wait = 8,	// 等待1回合下次优先攻击
	ESkill_Active_AddBuff = 9,	// 施加buff状态
	ESkill_Active_ClearBuff = 10,	// 驱散
};

enum ESkillTargetType
{
	ESkill_Target_Enemy = 1,	// 敌方
	ESkill_Target_Self = 2,	// 己方
};

enum ESkillRangeType
{
	ESkill_Range_Normal = 0,	// 无特殊目标限定
	ESkill_Range_FrontRow = 1,	// 前排
	ESkill_Range_MidRow = 2,	// 中排
	ESkill_Range_BackRow = 3,	// 后排
	ESkill_Range_FrontMidRow = 4,	// 前排+中排
	ESkill_Range_Column = 5,	// 列
	ESkill_Range_AllRand = 6,	// 全部目标单位随机
	ESkill_Range_Self = 7,	// 施法者自身
	ESkill_Range_Front2Row = 8,	// 前两排
};

enum ESkillSelectType
{
	ESkill_Select_Normal = 0,	// 无特殊目标限定
	ESkill_Select_Rand = 1,	// 随机n个单位
	ESkill_Select_MaxCurHp = 2,	// 当前生命值最高n个单位
	ESkill_Select_MinCurHp = 3,	// 当前生命值最低n个单位
	ESkill_Select_MinCurHpPer = 4,	// 生命值百分比最少n个单位
	ESkill_Select_MaxDamage = 5,	// 攻击最高n个单位
	ESkill_Select_MaxWuGong = 6,	// 物理攻击最高n个单位
	ESkill_Select_MaxFaGong = 7,	// 法术攻击最高n个单位
	ESkill_Select_MaxWuFang = 8,	// 物理防御最高n个单位
	ESkill_Select_MinWuFang = 9,	// 物理防御最低n个单位
	ESkill_Select_MaxFaFang = 10,	// 法术防御最高n个单位
	ESkill_Select_EnBuff = 11,		// 增益状态的n个随机单位
	ESkill_Select_MinFaFang = 12,	// 法术防御最低n个单位
	ESkill_Select_DieUnit = 13,	// 阵亡的n个随机单位
	ESkill_Select_Shield = 14,	// 有护盾的n个随机单位
	ESkill_Select_DeBuff = 15,	// 异常状态的n个随机单位
	ESkill_Select_MaxSpeed = 16,	// 速度最快的n个单位
	ESkill_Select_MaxFangYu = 17,	// 防御最高的n个单位
	ESkill_Select_ZhuoShao = 18,	// 灼烧状态的n个随机单位
	ESkill_Select_ZhongDu = 19,		// 中毒状态的n个随机单位
};

enum ESkillPassitiveType
{
	ESkill_Pass_AddBuff = 101,	// 附加buff状态
	ESkill_Pass_Attr = 102,	// 增加属性
	ESkill_Pass_AddDamByMaxFang = 103,	// 附加最大防御倍数伤害
	ESkill_Pass_AddDamBySelfHpLimitL = 104,	// 施法者生命值低于一定值时伤害提高
	ESkill_Pass_AddHp = 105,	// 恢复施法者一定比例当前生命值
	ESkill_Pass_AddFanJiRatio = 106,	// 概率反击攻击者，如若目标处于嘲讽状态，反击概率额外增加
	ESkill_Pass_SameDamToAnother = 107,	// 对随机另一个目标造成同样伤害
	ESkill_Pass_AddDamByTarHpLimitH = 108,	// 对高于生命值要求的单位造成伤害提高
	ESkill_Pass_NotMove = 109,	// 后续回合无法行动
	ESkill_Pass_AddBaoJiByHpLimitL = 110,	// 对生命值百分比低于要求的单位时增加暴击率
	ESkill_Pass_RandomAttackMinHp = 111,	// 有几率普攻生命值最低的目标
	ESkill_Pass_AddDamage = 112,	// 造成伤害增加
	ESkill_Pass_AddZhongDuKang = 113,	// 增加中毒抵抗
	ESkill_Pass_ClearBuff = 114,	// 驱散n个增益状态
	ESkill_Pass_ClearSpecBuff = 115,	// 解除有方n个异常状态单位身上的n个异常状态
	ESkill_Pass_ImproveAddHpEffect = 116,	// 提升治疗效果
	ESkill_Pass_FuHuo = 117,	// 起死回生：复活并恢复一定比例生命值
	ESkill_Pass_AddDamByAddHp = 118,	// 受到治疗量一定比例的伤害
	ESkill_Pass_DunDamage = 119,	// 对敌方全体造成一定比例的护盾吸收的伤害
	ESkill_Pass_ImproveFuMian = 120,	// 提升负面概率
	ESkill_Pass_AddDamDun = 121,	// 对有护盾的目标伤害增加
	ESkill_Pass_IgnoreDun = 122,	// 有几率直接无视护盾
	ESkill_Pass_FastAttackAgain = 123,	// 若比目标先出手则再次攻击该目标，目标死亡不触发
	ESkill_Pass_UseSkillAgain = 124,	// 有几率再次释放技能
	ESkill_Pass_ClearBuff_Self = 125,	// 解除自己身上的n个异常状态
	ESkill_Pass_ZhaoHuan = 126,	// 召唤哮天犬攻击目标造成伤害
	ESkill_Pass_AddDamBySelfMaxHp = 127,	// 附加施法者最大生命值百分比的伤害
	ESkill_Pass_FanTanBySelfMaxHp = 128,	// 反弹施法者最大生命值百分比的伤害
	ESkill_Pass_AddDamByPercent = 129,	// 额外附加攻击百分比伤害
	ESkill_Pass_ReduceCD = 130,	// 技能cd减少
	ESkill_Pass_IgnoreFang = 131,	// 忽视目标百分比防御
	ESkill_Pass_AddBuffByRandom = 132,	// 随机敌方1个目标附加buff状态
	ESkill_Pass_ShareDamage = 133,	// 分担百分比伤害
	ESkill_Pass_UseFirstSkillAgain = 134,	// 有几率再次释放第1个技能
	ESkill_Pass_AddDamByHpMoreThanSelf = 135,	// 目标生命值高于自己则伤害提升
	ESkill_Pass_DamageToMoreUnit = 136,	// 对有某个特殊状态的单位造成溅射伤害
	ESkill_Pass_IgnoreOtherAttr = 137,	// 忽视百分比守方2级属性
	ESkill_Pass_AddDamByAttacked = 138,	// 受到伤害转化为自身攻击力
	ESkill_Pass_ActionFirst = 139,	// 优先出手
	ESkill_Pass_AddDamByTarHpLimitL = 140,	// 对低于生命值要求的单位造成伤害提高
	ESkill_Pass_AddDamByTarHpPercent = 141,	// 额外附加目标当前生命值百分比的伤害
	ESkill_Pass_ImproveCureByTarHpLimitL = 142,	// 对生命值低于一定比例的单位提升治疗效果
	ESkill_Pass_CureAllMember = 143,	// 为友方全体恢复溢出治疗量百分比的生命值
	ESkill_Pass_NotBeAttacked = 144,	// 有几率免疫伤害
	ESkill_Pass_AddSelfHpByLoseHp = 145,	// 恢复自身损失气血的一定比例生命
	ESkill_Pass_AddMianShangByHpLimitL = 146,	// 生命值低于一定比例提升免伤率
	ESkill_Pass_AddBuffForMemberMinHp = 147,	// 为友方生命值百分比最低的单位附加状态
	ESkill_Pass_FuHuoFirstDieMem = 148,	// 复活第1个阵亡的友方单位，并为其恢复最大生命值的气血
	ESkill_Pass_AddSelfHpToMaxByDieOneTime = 149,	// 免死1次并将生命恢复至最大生命值的百分比
	ESkill_Pass_AddBuffWhenClear = 150,	// 有几率转移驱散的增益状态到自己身上
	ESkill_Pass_AddHpBySelfAttack = 151,	// 为其恢复自身攻击一定比例的生命值
	ESkill_Pass_AddHpByPercent = 152,	// 恢复最大生命值百分比的生命
	ESkill_Pass_MianYiFuMian = 153,	// 免疫某种负面状态
	ESkill_Pass_ClearSpecOneBuff = 154,	// 有几率驱散队友身上的某个状态
	ESkill_Pass_CureTarHp = 155,	// 恢复施法者敌方目标当前生命值一定比例的气血
	ESkill_Pass_AddBuffToAttackUnit = 156,	// 对攻击者附加buff
	ESkill_Pass_ImproveCure = 157,	// 提升受到的治疗效果
	ESkill_Pass_DescAttackUnitHp = 158,	// 消耗施法者一定比例的最大生命值
	ESkill_Pass_AddBaoJiLvByHpLimitH = 159,	// 对生命值百分比高于要求的敌方目标增加施法者的暴击率
	ESkill_Pass_AddAttrByDecHp = 160,	// 生命值每降低一定比例提升属性
	ESkill_Pass_AddTempAttr = 161,		// 增加临时属性
	ESkill_Pass_ReduceDamage = 162,		// 降低该次受到的伤害百分比
	ESkill_Pass_CureMinHpUnit = 163,	// 为友方生命值最低目标恢复该目标最大生命值百分比的生命值
	ESkill_Pass_ExtDamageBySelfMaxHpPercent = 164,	// 造成自身最大生命值百分比的真实伤害
	ESkill_Pass_DescAttackUnitHpPercent = 165,	// 消耗施法者一定比例的当前生命值
	ESkill_Pass_DescAttackAndAddToSelf = 166,	// 降低敌方攻击最高目标百分比攻击力，并提升自己该数值的攻击力
	ESkill_Pass_DescSelfAllCD = 167,		// 自己所有技能cd减少一回合
	ESkill_Pass_AddTheSkillAttack = 168,	// 该技能伤害提升
};

enum ESkillTriggerType
{
	ESkill_Trigger_DefAdd = 0,	// 被动增加
	ESkill_Trigger_Attacking = 1,	// 攻击时
	ESkill_Trigger_Action = 2,	// 行动时
	ESkill_Trigger_TurnBegin = 3,	// 每回合开始时
	ESkill_Trigger_BeAttacked = 4,	// 受击时
	ESkill_Trigger_BeFanJian = 5,	// 被反间时
	ESkill_Trigger_KillTarget = 6,	// 击杀目标时
	ESkill_Trigger_AttackZhongDu = 7,	// 攻击中毒目标时
	ESkill_Trigger_AttackDebuff = 8,	// 攻击异常状态目标时
	ESkill_Trigger_SelfDied = 9,	// 阵亡时
	ESkill_Trigger_AddHpJinLiaoShu = 10,	// 自己施加禁疗术的目标受到治疗时
	ESkill_Trigger_AttackingAddSelfBuff = 11,	// 攻击时为自己附加
	ESkill_Trigger_SelfShieldMiss = 12,	// 自己施加的护盾消失时
	ESkill_Trigger_DecHpLarge = 13,	// 自己受到的单次伤害超过一定比例最大生命值
	ESkill_Trigger_FightBegin = 14,	// 战斗开场时
	ESkill_Trigger_UnitDied = 15,	// 战斗中有单位阵亡时
	ESkill_Trigger_AddHp = 16,	// 加血时
	ESkill_Trigger_MinHpBeAttacked = 17,	// 友方生命值最低的单位受到伤害时
	ESkill_Trigger_AttackingAddBuff = 18,	// 攻击时为自己和己方1个友方单位附加
	ESkill_Trigger_AttackingAddToAllUnit = 19,	// 攻击时为己方所有单位单位附加
	ESkill_Trigger_AttackingZhuoShang = 20,	// 攻击灼伤目标时
	ESkill_Trigger_FightBeginAddToAllUnit = 21,	// 战斗开始时为友方全体附加
	ESkill_Trigger_ActionAddSelfMaxAttack = 22,	// 行动时为自己和己方攻击最高的单位附加
	ESkill_Trigger_BeAttackedWu = 23,	// 受到物理攻击时
	ESkill_Trigger_HaveMeiHuoState = 24,	// 每有1个敌方目标处于魅惑状态时
	ESkill_Trigger_AttackByZhiSi = 25,	// 受到致死打击时
	ESkill_Trigger_ClearEnBuff = 26,	// 驱散增益状态时
	ESkill_Trigger_MemberAction = 27,	// 友方行动时
	ESkill_Trigger_DieAndAddToAllUnit = 28,	// 阵亡时为友方全体
	ESkill_Trigger_MemberDied = 29,	// 友方有单位阵亡时
	ESkill_Trigger_AddAttrBeginFight = 30,	// 战斗开始时为自己附加
	ESkill_Trigger_AddHpSelfRatio = 31,	// 加血时，自身概率判定
	ESkill_Trigger_BeAttackedWuBeforeDecHp = 32,	// 受到物理攻击时，在扣血前判断
	ESkill_Trigger_AfterAttack = 33,	// 攻击后判断
	ESkill_Trigger_AfterAttackUnit = 34,	// 攻击后扣血
	ESkill_Trigger_TurnBegin_RandSelfOne = 35,	// 每回合开始时,随机一个友方
	ESkill_Trigger_FightBegin_MaxAttackEnemy = 36,	// 战斗开始时,敌方攻击最高单体
	ESkill_Trigger_AddHpAndBuff = 37,	// 加血时加buff
	ESkill_Trigger_DieAndAddToOtherUnit = 38,	// 阵亡时对敌方全体
};

enum ESkillMulBuffActiveType
{
	ESMBT_LastBuffActv = 1,	// 后添加生效
	ESMBT_AddAllBuff = 2,	// 所有数值叠加
	ESMBT_SingleActv = 3,	// 单独生效(不同buff处理方式可能不同)
};

struct SSkillActiveEffect
{
	SSkillActiveEffect()
	{
		Clear();
	}
	void Clear()
	{
		effectId = 0;
		effect_type = 0;
		target_group = 0;
		target_range = 0;
		target_select = 0;
		target_num = 0;
		buffId = 0;
		memset(para,0,sizeof(para));
		memset(para_levelAdd,0,sizeof(para_levelAdd));
	}

	const static uint8 MAX_PARA_NUM = 10;
	int effectId;
	int effect_type;
	int target_group;	// 1敌方2己方
	int target_range;	// 目标范围
	int target_select;	// 目标条件
	int target_num;
	int buffId;		// 附加buffId
	int para[MAX_PARA_NUM];				// 参数
	int para_levelAdd[MAX_PARA_NUM];	// 每一级增加的属性
};

struct SSkillAdditiveEffect
{
	SSkillAdditiveEffect()
	{
		Clear();
	}
	void Clear()
	{
		id = 0;
		trigger = 0;
		type = 0;
		buffId = 0;
		showStr.clear();
		memset(para,0,sizeof(para));
		memset(para_levelAdd,0,sizeof(para_levelAdd));
	}
	const static uint8 MAX_PARA_NUM = 10;
	int id;
	int trigger;
	int type;
	int buffId;	// 附加buffid
	string showStr;
	int para[MAX_PARA_NUM];				// 参数
	int para_levelAdd[MAX_PARA_NUM];	// 每一级增加的属性
};

struct SSkillBuff
{
	SSkillBuff()
	{
		id = 0;
		type = 0;
		canMerge = 0;
		active_type = 0;
		mutex_buffId.clear();
		name.clear();
	}

	int id;
	int type;	// 1增益2减益
	int canMerge;	// 0可叠加效果 1不可叠加效果
	int active_type;	// 1后添加生效 2所有数值叠加 3单独生效(不同buff处理可能不同)
	vector<int> mutex_buffId;	// 互斥buffId
	string name;
};

enum ESkillType
{
	ESKILL_Active = 1,	// 主动
	ESKILL_Passive = 2,	// 被动
};

struct SSkillCfgData
{
	SSkillCfgData()
	{
		id = 0;
		type = 0;
		CD = 0;
		name.clear();
		activeEffect.Clear();
		passiveEffect.clear();
	}
	
	uint16 id;
	int type;	// 1主动2被动
	int CD;
	string name;
	SSkillEffectCfg activeEffect;	// 主动效果
	vector<SSkillEffectCfg> passiveEffect;	// 被动效果
};

struct HeroSkillRoleCfg
{
	HeroSkillRoleCfg():heroId(0),regularSkillId(0),tacticSkillId(0),tacticCost(0){}
	uint16 heroId;
	uint16 regularSkillId;
	uint16 tacticSkillId;
	uint8 tacticCost;
	string buildA;
	string buildB;
};
typedef map<uint16, HeroSkillRoleCfg> HeroSkillRoleCfgMap;




class CSkillMgr
{
public:
	CSkillMgr()
	{
		m_skills.clear();
		m_activeEffects.clear();
		m_additiveEffects.clear();
		m_buffs.clear();
		m_enBuffs.clear();
		m_deBuffs.clear();
		m_zhongduBuffs.clear();
	}

	~CSkillMgr()
	{
		m_skills.clear();
		m_activeEffects.clear();
		m_additiveEffects.clear();
		m_buffs.clear();
		m_enBuffs.clear();
		m_deBuffs.clear();
		m_zhongduBuffs.clear();
	}

	bool Init();
	bool InitHeroSkillRoleCfg();
	SSkillCfgData *GetSkillCfg(int skillId);
	SSkillActiveEffect *GetActiveEffectCfg(int effectId);
	SSkillAdditiveEffect *GetAdditiveEffectCfg(int effectId);
	SSkillBuff *GetBuffCfg(int buffId);
	void GetEnBuffList(vector<int> &buffList);
	void GetDeBuffList(vector<int> &buffList);
	void GetZhongDuBuffList(vector<int> &buffList);

	void GetSkillPassiveData(int skillId,uint16 triggerId,vector<int> &passiveList);

	bool IsEnBuff(uint16 buffId);
	HeroSkillRoleCfg* GetHeroSkillRoleCfg(uint16 heroId);
	const HeroSkillRoleCfgMap& GetHeroSkillRoleCfgs() const { return m_heroSkillRoles; }
	
private:
	void SetEffectData(SSkillEffectCfg &active,vector<SSkillEffectCfg> &passive,string &str);

	map<int, SSkillCfgData> m_skills;	// key=skillId
	map<int, SSkillActiveEffect> m_activeEffects;	// key=activeEffectId
	map<int, SSkillAdditiveEffect> m_additiveEffects;	// key=additiveEffectId
	map<int, SSkillBuff> m_buffs;	// key=buffId
	vector<int> m_enBuffs;	// buffId
	vector<int> m_deBuffs;	// buffId
	vector<int> m_zhongduBuffs;	// buffId
	HeroSkillRoleCfgMap m_heroSkillRoles;
};

typedef boost::details::pool::singleton_default<CSkillMgr> SingletonCSkillMgr;



#endif

