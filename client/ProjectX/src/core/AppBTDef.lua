AppDef.BTConst = {}


AppDef.BTConst.UseNewBattle = true

AppDef.BTConst.Type = {
	Monster = 0,--怪物
	Hero = 1,--英雄
	Pet = 2,--宠物神将
	Spirit = 3--灵兽
}

AppDef.BTConst.ColumnUnitNum = 3--一列几个单位
AppDef.BTConst.LineUnitNum = 3--一行几个单位
AppDef.BTConst.MaxBuffNum = 20
AppDef.BTConst.MaxUnitNum = 18
AppDef.BTConst.MaxHalfUnitNum = 9
-- AppDef.BTConst.MaxUnitNum = 12
-- AppDef.BTConst.MaxHalfUnitNum = 6
AppDef.BTConst.MaxActionNum = 100
AppDef.BTConst.MaxLianjiNum = 10--最大连击次数
AppDef.BTConst.BattleType = 
{
	BT_NORMAL = 1,	--正常类型
    BT_MISSION = 8, --主线支线
	BT_BOSS = 67,	--日常boss战斗
	BT_XUNCHASHI = 78,--巡查使战斗
    BT_FENGSHEN = 85,--封神试炼
	BT_WATERGOST = 100,--水鬼战斗
	BT_NOLEVEL = 200,--不显示等级
	BT_MSBOSS = 53,	--跨服boss战斗
}

AppDef.BTConst.BTState = 
{
    None = 0,  --不在战斗的状态
    Start = 1,   --战斗开始状态
    Action = 2,--战斗选择动作状态
    Wait = 3,--战斗动作选择完毕等待服务器返回状态
    Playing = 4,--战斗播放动作状态
    Over = 5,--战斗结束状态
}

AppDef.BTConst.ActCombo = 
{
    Crit = 1,--暴击
    Combo = 2,--连击
}

AppDef.BTConst.UnitActState = 
{
    NORMAL = 0,             --普通状态
    DEATH = 1,              --死亡状态
    MAGIC = 2,              --施法状态
    ATTACK = 3,             --攻击状态         --6号动作,旋转冲击
    HIT = 10,         --被击状态
	RUNIN = 11,				--跑步状态
	RUNAWAY = 12,			--逃跑状态
}

AppDef.BTConst.ActionType = 
{
    BAT_ATTACK = 1,             --普通攻击
    BAT_ADDHP = 2,--加血
    BAT_BUFF = 3,--buff，纯buff
    BAT_CALLMONSTER = 4,       --召唤怪物
    BAT_RUNAWAY = 5,            --逃跑
    BAT_PASSIVE = 6,            --被动触发
    BAT_CHAT = 7,--说话
}

AppDef.BTConst.ActOpt =
{
    ACT_NULL             = 0,    --无用值
    ACT_SKATK            = 1,    --攻击
    ACT_RUNAWAY          = 2,    --逃跑
    ACT_AUTOFIGHT        = 3,   --自动战斗
}

--[[
状态id
]]
AppDef.BTConst.BTUnitState = 
{
    NONE                    = 0,    --无用值
    DEAD                    = 1,    --死亡状态
}

AppDef.BTConst.BTZorder = 
{
    ZORDER_SPEAK_MSG        = 100,  --说话文字
    ZORDER_SKILLANI         = 1000, --技能动画
    ZORDER_HURT_NUM         = 1001, --伤害数字
}

AppDef.BTConst.BUFSIZE = 29
AppDef.BTConst.BUFF_SIGN = {0x1,0x2,0x4,0x8,0x10,0x20,0x40,0x80,0x100,0x200,0x400,0x800,0x2000,0x4000,0x8000,0x10000,0x20000,0x40000,0x80000,0x100000,0x200000,0x400000,0x800000,0x1000000,0x2000000,0x4000000,0x8000000,0x10000000,0x20000000}
AppDef.BTConst.BUFF_SKILL = {55,56,51,52,53,54,60,61,62,103,101,102,66,107,5,41,68,69,71,73,74,242,243,244,252,77,257,62,61}
AppDef.BTConst.BUFF_PICID = {55,55,51,51,53,53,60,61,62,103,101,102,66,107,5,41,68,69,71,61,64,242,243,243,252,77,257,62,61}
AppDef.BTConst.BUFF_HINT = {0,0,0,0,0,0,0,1,2,0,0,0,3,0,0,2,2,0,0,0,0,0,0,0,0,0,0,2,1}
AppDef.BTConst.BUFF_HEIGHT = {0,0,0,0,0,0,0,60,0,0,0,0,0,0,0,0,0,0,83,60,0,160,200,185,160,0,160,0,60}

AppDef.BTConst.UnitState = 
{
    ESBUFF_ChaoFeng = 1,    -- 嘲讽, 强制普攻施法者
    ESBUFF_ChenMo = 2,      -- 沉默, 不能使用技能
    ESBUFF_FengYin = 3,     -- 封印, 不能使用技能
    ESBUFF_HunShui = 4,     -- 昏睡, 昏睡状态下无法行动，被攻击3次苏醒
    ESBUFF_HunLuan = 5,     -- 混乱, 目标敌我不分随机普攻敌我双方1人
    ESBUFF_MeiHuo = 6,      -- 魅惑, 目标敌我不分随机普攻敌我双方1人
    ESBUFF_FanJian = 7,     -- 反间, 目标敌我不分随机普攻敌我双方1人
    ESBUFF_ShiXinDu = 8,    -- 食心毒, 目标行动时受到最大生命值一定百分比的伤害
    ESBUFF_ShiDu = 9,       -- 尸毒, 目标每回合开始时受到固定值的伤害
    ESBUFF_FuDu = 10,       -- 腐毒, 目标每回合开始时受到当前生命值一定百分比的伤害
    ESBUFF_ZhuoShao = 11,   -- 灼烧, 受到每回合受到施法者攻击值一定百分比的伤害
    ESBUFF_ZengShangLvAdd = 12, -- 增伤提升
    ESBUFF_ZengShangLvDes = 13, -- 增伤下降
    ESBUFF_JianShangLvAdd = 14, -- 减伤提升
    ESBUFF_JianShangLvDes = 15, -- 减伤下降
    ESBUFF_WuMianLvAdd = 16,    -- 物免提升
    ESBUFF_WuMianLvDes = 17,    -- 物免下降
    ESBUFF_FaMianLvAdd = 18,    -- 法免提升
    ESBUFF_FaMianLvDes = 19,    -- 法免下降
    ESBUFF_DamageDes = 20,      -- 降低输出伤害
    ESBUFF_GetDamageAdd = 21,   -- 受到伤害增加
    ESBUFF_GetWuDamageAdd = 22,     -- 受到物理伤害增加
    ESBUFF_GetFaDamageAdd = 23, -- 受到法术伤害增加
    ESBUFF_WuMianAndGetFaDamageAdd = 24,    -- 使目标不会受到物理伤害，但受到的法术伤害增加
    ESBUFF_DamagePercentAdd = 25,       -- 攻击百分比提升
    ESBUFF_DamagePercentDes = 26,       -- 攻击百分比降低
    ESBUFF_JinGuZhou = 27,      -- 紧箍咒， 降低目标百分比攻击，且每回合受到施法者攻击百分比伤害
    ESBUFF_FangYuDes = 28,      -- 防御降低, 降低目标百分比防御
    ESBUFF_FaFangDes = 29,      -- 法术防御降低, 降低目标百分比法术防御
    ESBUFF_WuFangDes = 30,      -- 物理防御降低, 降低目标百分比物理防御
    ESBUFF_BaoJiLvAdd = 31,     -- 暴击率提升, 提升暴击率
    ESBUFF_BaoJiShangHaiAdd = 32,   -- 暴击伤害提升, 提升暴击伤害
    ESBUFF_BaoJiKangDes = 33,   -- 抗暴率降低, 降低抗暴率
    ESBUFF_FuMianKangAdd = 34,  -- 负面抵抗提升, 提升负面抵抗
    ESBUFF_ZhongDuKangAdd = 35, -- 中毒抵抗提升, 提升中毒抵抗
    ESBUFF_FuMianKangDes = 36,  -- 负面抵抗降低, 降低负面抵抗
    ESBUFF_FanZhengAllAdd = 37, -- 反震效果提升, 提升反震率和反震伤害
    ESBUFF_FanZhengLvAdd = 38,  -- 反震率提升, 提升反震率
    ESBUFF_ShanBiLvAdd = 39,    -- 闪避率提升, 提升闪避率
    ESBUFF_SpeedDes = 40,       -- 速度降低, 降低百分比速度
    ESBUFF_Protect = 41,        -- 保护状态, 保护目标，为其分担受到的伤害，同时提升双方的减免率
    ESBUFF_ShieldMianShang = 42,        -- 护盾免伤, 吸收一定比例最大生命值的护盾，并提升一定比例免伤率
    ESBUFF_Shield = 43,         -- 护盾, 吸收一定比例最大生命值的护盾
    ESBUFF_JinLiaoShu = 44,     -- 禁疗术, 降低目标受到的治疗效果
    ESBUFF_AddHpContinue = 45,      -- 持续治疗, 每回合恢复施法者攻击一定比例的气血值
    ESBUFF_ReduceMingZhongLv = 53,      -- 命中率降低
    ESBUFF_AddMingZhongLv = 54,         -- 命中率提高
    ESBUFF_AddSpeed = 55,       -- 速度提升, 百分比

    ESBUFF_WaitOneRound = 63,  -- 等待一回合不操作
    ESBUFF_Died = 64,  -- 死亡,64
}

------------动作配置表常量-------------------
AppDef.BTConst.ActAniType = 
{
    ModelAni = 1,--模型动作
    SkillAni = 2,--技能动作
    HurtAni = 3,--被击动作
}

AppDef.BTConst.MoveType ={
    ActSrcPos = 1,--施法者原位置
    TgtFwdPos = 2,--目标正前位置  
    TgtBakPos = 3,--目标正后位置  
    TgtColumnPos = 4,--目标列排位置   
    TgtLinePos = 5,--目标行位置  
    FightCenterPos = 6,--交战中心位置 
    ActCenterPos = 7,--我方中心位置   
    TgtCenterPos = 8,--敌方中心位置   
    ActBakPos = 9,--我方后方位置  
    TgtSrcPos = 10,--目标位置
    TgtColumnFwdPos = 11,--目标列排正前位置
    TgtLineFwdPos = 12,--目标行正前位置
}

AppDef.BTConst.HitPointType = 
{
    --0-地面；1-脚；2-腰；3-头
    Foot = 1,--脚
    Middle = 2,--腰
    Head = 3,--头
}

-----------------资源目录常亮--------------------------------