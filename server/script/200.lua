-- 200.lua   -- 副本结算 各种功能
---------------------------------------
require "global"
Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
OptionConfirm = j.OptionConfirm
SMessage = j.SMessage   --弹出提示
CloseInteract = j.CloseInteract --结束交互
MissionBanner = j.MissionBanner --新版任务面板接取模式
Dialog_End = j.Dialog_End
SMessage_End = j.SMessage_End
local bit = require "bit"

------------------------------------------
--以下为脚本部分：
------------------------------------------
function NpcMain(pUser,missionId)
	
end


-- // ======================答题活动 开始=======================

QuestionAnswerTab = {} -- 玩家答题表

-- 当前问题是否重复可用
function GetQuestionAnswerEnable(roleId,question)
	if not QuestionAnswerTab[roleId] then 
		QuestionAnswerTab[roleId] = {}
		QuestionAnswerTab[roleId][1] = question
		return true
	elseif #QuestionAnswerTab[roleId] >= 20 then -- 重置，防止存储过多
		QuestionAnswerTab[roleId] = {}
	end
	for k,v in ipairs(QuestionAnswerTab[roleId]) do
		if v == question then -- 相同问题不行
			return false
		end
	end
	QuestionAnswerTab[roleId][#(QuestionAnswerTab[roleId])+1] = question
	return true
end

-- 清除记录
function ClearQuestionAnswer(pUser)
	local roleId = pUser:GetRoleId()
	QuestionAnswerTab[roleId] = nil
	--print("调用脚本的清除记录了")
end

-- 获取问题及答案
function GetQuestionAnswer(pUser)
	local roleId = pUser:GetRoleId()
	local s = j.GetQuestion(pUser)
	local t = FormatMission(s)
	local question = t[1]
	local loopIdx = 0 -- 当前循环次数

	-- 重复问题校验去掉
	--while(not GetQuestionAnswerEnable(roleId,question)) do
		--loopIdx = loopIdx + 1
		--s = j.GetQuestion()
		--t = FormatMission(s)
		--question = t[1]
		--if loopIdx >= 10 then -- 防止死循环吧
			--break
		--end
	--end
	--print("实际问题",question)	
	--print("实际答案",s)
	
	-- 乱序
	local tmpTab = {2,3,4,5}
	local i,tmp,r
	for i=1,3 do
		r = math.random(i,#tmpTab)
		if r ~= i then
			tmp = tmpTab[i]
			tmpTab[i] = tmpTab[r]
			tmpTab[r] = tmp  	
		end
	end	
	
	local answer = ""
	local right = 0
	for k,v in ipairs(tmpTab) do
		answer = answer..t[v].."|"
		if v == 2 then 
			right = k
		end
	end
	pUser:SetVal(1,right) -- 记录正确答案
	answer = string.sub(answer,1,-2)	
	--print("最终答案",answer,"索引：",right)
	return question,answer
end

-- // ======================答题活动 结束=======================

-- // ======================活跃度 开始=======================

local HuoYueDuState = { -- 活跃度状态
	["QIAN_WANG_CAN_JIA"] = 1, -- 前往参加
	["DENG_JI_BU_ZU"] = 2, -- 等级不足
	["FEI_HUO_DONG_SHI_JIAN"] = 3, -- 非活动时间
	["DAO_JI_SHI"] = 4, -- 倒计时
}

local TableIndex = {
 ["Pet"] = 1,		-- 神将
 ["Exp"] = 2,		-- 经验
 ["Equip"] = 4,	-- 装备
 ["Other"] = 8,	-- 其他
 ["Money"] = 16,-- 金币
}

-- 对应的活动奖励的道具，正数是道具id，多个物品之间用','分割
local HYD_NULL = 0 -- 无
local HYD_JINGYAN = -1 -- 经验
local HYD_JINBI = -2 -- 金币
local HYD_SHENGWANG = -3 -- 声望
local HYD_QIANNENG = -4 -- 潜能
local HYD_FUFEIDAOJU = -5 -- 付费道具
local HYD_CHONGWU = -6 -- 神将
local HYD_RENWUJIFEN = -7 -- 任务积分
local HYD_YUANBAO = -8		-- 元宝
local HYD_BANGGONG = -9 	-- 帮贡
local HYD_XIANYUAN = -10 	-- 仙缘
local HYD_SHUXINGSHI = -11 	-- 站位宝石



-- limitLevel 参与等级
-- activityNum 可参加次数
-- MaxHuoYueDu 最大活跃度
-- completeYB 一键完成一次消耗的元宝数
-- CompleteVipLimit 一键完成vip等级限制
-- CompleteNum 一键完成剩余次数
-- SaoDang 扫荡标记 1扫荡

WAN_FA_CONFIG = 
{
[1] = {			--日常BOSS
				Name = LANGUAGE_TRANSFORM_1447, 
				Time = LANGUAGE_TRANSFORM_1448,
				limitLevel = 39,
				activityNum = 3,
				MaxHuoYueDu = 6,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = HYD_JINGYAN..",2251,2301",
				tableIndex = tostring(TableIndex.Exp)..","..tostring(TableIndex.Other),
				ExtData = "",
			},
			
[2] = {			--师门
				Name = LANGUAGE_TRANSFORM_1449,
				Time = LANGUAGE_TRANSFORM_1450,
				limitLevel = 29,
				activityNum = 10,
				MaxHuoYueDu = 10,
				completeYB = 1,
				CompleteVipLimit = 0,
				CompleteLvLimit = 35,
				SaoDang = 0,
				CompleteNum = 0,
				Award = HYD_JINGYAN..","..HYD_JINBI,
				tableIndex = tostring(TableIndex.Exp)..","..tostring(TableIndex.Money),
				ExtData = "",
			},
[3] = {			--昆仑寻宝
				Name = LANGUAGE_TRANSFORM_1451,
				Time = LANGUAGE_TRANSFORM_1452,
				limitLevel = 39,
				activityNum = 2,
				MaxHuoYueDu = 10,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = HYD_YUANBAO..","..HYD_JINBI..","..HYD_JINGYAN,
				tableIndex = tostring(TableIndex.Exp)..","..tostring(TableIndex.Money)..","..tostring(TableIndex.Other),
				ExtData = "",
			},
[4] = {			--灵气捐献
				Name = LANGUAGE_TRANSFORM_1453,
				Time = LANGUAGE_TRANSFORM_1454,
				limitLevel = 37,
				activityNum = 3,
				MaxHuoYueDu = 6,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = HYD_JINGYAN,
				tableIndex = tostring(TableIndex.Exp),
				ExtData = "",
			},
[5] = {			--昆仑山
				Name = LANGUAGE_TRANSFORM_1455,
				Time = LANGUAGE_LLD_0185,
				limitLevel = 36,
				activityNum = 999,
				MaxHuoYueDu = 0,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = "2539,2538,"..HYD_YUANBAO,
				tableIndex = tostring(TableIndex.Exp)..","..tostring(TableIndex.Other),
				ExtData = "",
			},
[6] = {			--钓鱼
				Name = LANGUAGE_TRANSFORM_1456,
				Time = "12:30-12:50",
				limitLevel = 30,
				activityNum = 999,
				MaxHuoYueDu = 10,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = "2252,2251,"..HYD_JINGYAN,
				tableIndex = tostring(TableIndex.Exp)..","..tostring(TableIndex.Money),
				ExtData = "",
			},
[7] = {			--答题
				Name = LANGUAGE_TRANSFORM_1457,
				Time = LANGUAGE_TRANSFORM_1458,
				limitLevel = 39,
				activityNum = 2,
				MaxHuoYueDu = 10,
				completeYB = 1,
				CompleteVipLimit = 2,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = HYD_JINBI,
				tableIndex = tostring(TableIndex.Money),
				ExtData = "",
			},
[8] = {			--百花仙子
				Name = LANGUAGE_TRANSFORM_1459,
				Time = "19:30-19:50",
				limitLevel = 30,
				activityNum = 999,
				MaxHuoYueDu = 10,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = "1100,"..HYD_JINBI,
				tableIndex = tostring(TableIndex.Pet)..","..tostring(TableIndex.Money),
				ExtData = "",
			},

[9] = {	--年兽				
				Name = LANGUAGE_LLD_0177,
				Time = "14:00-14:20",
				limitLevel = 30,
				activityNum = 999,
				MaxHuoYueDu = 10,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = "1101,"..HYD_JINBI,
				tableIndex = tostring(TableIndex.Pet)..","..tostring(TableIndex.Money)..","..tostring(TableIndex.Equip),
				ExtData = "",
		},	
[14] = {		--历练塔
				Name = LANGUAGE_TRANSFORM_1460,
				Time = LANGUAGE_TRANSFORM_1461,
				limitLevel = 35,
				activityNum = 999,
				MaxHuoYueDu = 5,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = "60014,2562",
				tableIndex = tostring(TableIndex.Pet),
				ExtData = "",
			},
[15] = {		--竞技场
				Name = LANGUAGE_TRANSFORM_1462,
				Time = LANGUAGE_TRANSFORM_1463,
				limitLevel = 31,
				activityNum = 10,
				MaxHuoYueDu = 5,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = "60016,"..HYD_JINGYAN,
				tableIndex = tostring(TableIndex.Exp),
				ExtData = "",
			},
[16] = {		--护送神将
				Name = LANGUAGE_TRANSFORM_1464,
				Time = LANGUAGE_TRANSFORM_1465,
				limitLevel = 42,
				activityNum = 5,
				MaxHuoYueDu = 10,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = HYD_JINGYAN,
				tableIndex = tostring(TableIndex.Exp),
				ExtData = "",
			},
[17] = {		--挑战灵魔
				Name = LANGUAGE_TRANSFORM_1466,
				Time = "16:30-16:50",
				limitLevel = 37,
				activityNum = 999,
				MaxHuoYueDu = 10,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = "1105,"..HYD_JINBI,
				tableIndex = tostring(TableIndex.Equip)..","..tostring(TableIndex.Money),
				ExtData = "",
			},
[18] = {
				Name = LANGUAGE_TRANSFORM_1467,
				Time = LANGUAGE_TRANSFORM_1468,
				limitLevel = 31,
				activityNum = 3,
				MaxHuoYueDu = 0,
				completeYB = 1,
				CompleteVipLimit = 1,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = HYD_QIANNENG..","..HYD_JINGYAN..","..HYD_JINBI,
				tableIndex = tostring(TableIndex.Money),		-- 没有生效
				ExtData = "",
			},
[20] = {		--运镖(暂时不上)
				Name = LANGUAGE_TRANSFORM_1469,
				Time = LANGUAGE_TRANSFORM_1470,
				limitLevel = 28,
				activityNum = 10,
				MaxHuoYueDu = 10,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = HYD_JINGYAN..","..HYD_JINBI..",2818",
				tableIndex = tostring(TableIndex.Exp)..","..tostring(TableIndex.Money),
				ExtData = "",
			},
[24] = {		--杀敌夺宝
				Name = LANGUAGE_TRANSFORM_1471,
				Time = LANGUAGE_TRANSFORM_1472,
				limitLevel = 50,
				activityNum = 5,
				MaxHuoYueDu = 10,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = "2355,"..HYD_JINGYAN,
				tableIndex = tostring(TableIndex.Exp)..","..tostring(TableIndex.Money),
				ExtData = "",
			},
[25] = {		--维护丹园
				Name = LANGUAGE_TRANSFORM_1473,
				Time = LANGUAGE_TRANSFORM_1474,
				limitLevel = 71,
				activityNum = 10,
				MaxHuoYueDu = 10,
				completeYB = 2,
				CompleteVipLimit = 2,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = "613,614,"..HYD_JINGYAN,
				tableIndex = tostring(TableIndex.Exp)..","..tostring(TableIndex.Pet),
				ExtData = "",
			},
[26] = {		--个人擂台
				Name = LANGUAGE_TRANSFORM_1475,
				Time = LANGUAGE_TRANSFORM_1476,
				limitLevel = 40,
				activityNum = 999,
				MaxHuoYueDu = 10,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = "60016,4406",
				tableIndex = tostring(TableIndex.Other), 
				ExtData = "",
			},
[27] = {
				Name = LANGUAGE_TRANSFORM_1477,
				Time = LANGUAGE_TRANSFORM_1478,
				limitLevel = 20,
				activityNum = 999,
				MaxHuoYueDu = 0,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = " ",
				tableIndex = tostring(TableIndex.Other),		-- 没有生效
				ExtData = "",
			},
[28] = {		--帮派种植
				Name = LANGUAGE_TRANSFORM_1479,
				Time = LANGUAGE_TRANSFORM_1480,
				limitLevel = 32,
				activityNum = 999,
				MaxHuoYueDu = 0,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = HYD_JINBI..","..HYD_YUANBAO..",835",
				tableIndex = tostring(TableIndex.Pet)..","..tostring(TableIndex.Money),
				ExtData = "",
			},
[29] = {		--藏宝图
				Name = LANGUAGE_TRANSFORM_1481,
				Time = LANGUAGE_TRANSFORM_1482,
				limitLevel = 38,
				activityNum = 10,
				MaxHuoYueDu = 10,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = "2442,2441,"..HYD_JINGYAN,
				tableIndex = tostring(TableIndex.Exp),
				ExtData = "",
			},
[30] = {		--英勇试炼
				Name = LANGUAGE_TRANSFORM_1483,
				Time = LANGUAGE_TRANSFORM_1484,
				limitLevel = 52,
				activityNum = 15,
				MaxHuoYueDu = 15,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = "610,611,"..HYD_JINGYAN,
				tableIndex =tostring(TableIndex.Exp)..","..tostring(TableIndex.Equip),
				ExtData = "",
			},
[31] = {		--飞仙战场
				Name = LANGUAGE_TRANSFORM_1485,
				Time = LANGUAGE_LLD_0186,
				limitLevel = 48,
				activityNum = 999,
				MaxHuoYueDu = 10,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = "2818,"..HYD_JINGYAN,
				tableIndex = tostring(TableIndex.Exp)..","..tostring(TableIndex.Other),
				ExtData = "",
			},
[32] = {		--抓鬼
				Name = LANGUAGE_TRANSFORM_1486,
				Time = LANGUAGE_TRANSFORM_1487,
				limitLevel = 41,
				activityNum = 50,
				MaxHuoYueDu = 30,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 1,
				CompleteNum = 0,
				Award = HYD_JINGYAN..","..HYD_JINBI,
				tableIndex = tostring(TableIndex.Money)..","..tostring(TableIndex.Exp),
				ExtData = "",
			},
[33] = {		--六界使者
				Name = LANGUAGE_TRANSFORM_1488,
				Time = "10:00-23:59",
				limitLevel = 38,
				activityNum = 24,
				MaxHuoYueDu = 0,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = "852,502,"..HYD_JINBI,
				tableIndex = tostring(TableIndex.Equip)..","..tostring(TableIndex.Money),
				ExtData = "",
			},
[34] = {		--帮派掠夺
				Name = LANGUAGE_TRANSFORM_1489,
				Time = "",
				limitLevel = 35,
				activityNum = 999,
				MaxHuoYueDu = 5,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = "2497,"..HYD_BANGGONG,
				tableIndex = tostring(TableIndex.Other),
				ExtData = "",
			},
[35] = {		--摇钱树
				Name = LANGUAGE_TRANSFORM_1490,
				Time = LANGUAGE_TRANSFORM_1491,
				limitLevel = 39,
				activityNum = 3,
				MaxHuoYueDu = 0,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = HYD_JINBI..","..HYD_YUANBAO,
				tableIndex = tostring(TableIndex.Money),
				ExtData = "",
			},
[36] = {		--帮战
				Name = LANGUAGE_TRANSFORM_1492,
				Time = LANGUAGE_TRANSFORM_1493,
				limitLevel = 44,
				activityNum = 999,
				MaxHuoYueDu = 5,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = HYD_BANGGONG..",4406,2517",
				tableIndex = tostring(TableIndex.Other),
				ExtData = "",
			},
[37] = {		--修仙历练
				Name = LANGUAGE_TRANSFORM_1494,
				Time = LANGUAGE_TRANSFORM_1495,
				limitLevel = 55,
				activityNum = 999,
				MaxHuoYueDu = 0,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = "4403,4404,4405",
				tableIndex = tostring(TableIndex.Pet),
				ExtData = "",
			},
[38] = {		--跨服任务
				Name = LANGUAGE_LLD_0053,
				Time = LANGUAGE_TRANSFORM_1495,
				limitLevel = 57,
				activityNum = 5,
				MaxHuoYueDu = 0,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = "2798",
				tableIndex = tostring(TableIndex.Other),
				ExtData = "",
			},
[39] = {		--血狼啸月
				Name = LANGUAGE_LLD_0054,
				Time = LANGUAGE_LLD_0055,
				limitLevel = 57,
				activityNum = 999,
				MaxHuoYueDu = 5,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = "4406,4405,2798",
				tableIndex = tostring(TableIndex.Other),
				ExtData = "",
			},
[40] = {		--天元争霸
				Name = LANGUAGE_LLD_0059,
				Time = LANGUAGE_LLD_0060,
				limitLevel = 57,
				activityNum = 999,
				MaxHuoYueDu = 0,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = "2798,4406,60016",
				tableIndex = tostring(TableIndex.Other),
				ExtData = "",
			},
[41] = {		--古巫现世
				Name = LANGUAGE_LLD_0062,
				Time = LANGUAGE_LLD_0063,
				limitLevel = 57,
				activityNum = 999,
				MaxHuoYueDu = 0,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = "2798,4406,2517",
				tableIndex = tostring(TableIndex.Other),
				ExtData = "",
			},
[42] = {		--跨服帮战(暂时屏蔽，等级改为120)
				Name = LANGUAGE_LLD_0065,
				Time = LANGUAGE_LLD_0066,
				limitLevel = 120,
				activityNum = 999,
				MaxHuoYueDu = 5,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = "2799,"..HYD_YUANBAO,
				tableIndex = tostring(TableIndex.Other),
				ExtData = "",
			},
[43] = {		--蓬莱仙山
				Name = LANGUAGE_LLD_0167,
				Time = LANGUAGE_TRANSFORM_1448,
				limitLevel = 33,
				activityNum = 5,
				MaxHuoYueDu = 5,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = "834",
				tableIndex = tostring(TableIndex.Pet),
				ExtData = "",
			},
[44] = {	--升阶副本
				Name = LANGUAGE_LLD_0168,
				Time = LANGUAGE_TRANSFORM_1448,
				limitLevel = 33,
				activityNum = 3,
				MaxHuoYueDu = 3,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = "506,507",
				tableIndex = tostring(TableIndex.Equip),
				ExtData = "",
		},
[45] = {	--强化副本
				Name = LANGUAGE_LLD_0169,
				Time = LANGUAGE_TRANSFORM_1448,
				limitLevel = 33,
				activityNum = 3,
				MaxHuoYueDu = 3,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = "851,852",
				tableIndex = tostring(TableIndex.Equip),
				ExtData = "",
		},
[46] = {	--金币副本
				Name = LANGUAGE_LLD_0170,
				Time = LANGUAGE_TRANSFORM_1448,
				limitLevel = 33,
				activityNum = 3,
				MaxHuoYueDu = 3,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = HYD_JINBI,
				tableIndex = tostring(TableIndex.Money),
				ExtData = "",
		},
[47] = {	--淬炼副本
				Name = LANGUAGE_LLD_0171,
				Time = LANGUAGE_TRANSFORM_1448,
				limitLevel = 67,
				activityNum = 1,
				MaxHuoYueDu = 2,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = "612,801",
				tableIndex = tostring(TableIndex.Equip),
				ExtData = "",
		},
[49] = {	--岱屿结界				
				Name = LANGUAGE_LLD_0179,
				Time = LANGUAGE_TRANSFORM_1448,
				limitLevel = 62,
				activityNum = 5,
				MaxHuoYueDu = 5,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = "835",
				tableIndex = tostring(TableIndex.Pet),
				ExtData = "",
		},
[50] = {	--诛仙绝地				
				Name = LANGUAGE_LLD_0183,
				Time = LANGUAGE_TRANSFORM_1448,
				limitLevel = 50,
				activityNum = 1,
				MaxHuoYueDu = 2,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = "1817,835",
				tableIndex = tostring(TableIndex.Pet),
				ExtData = "",
		},
[51] = {	--系统经验双倍
				Name = "",
				Time = "22:30-23:59",
				limitLevel = 30,
				activityNum = 999,
				MaxHuoYueDu = 0,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 0,
				SaoDang = 0,
				CompleteNum = 0,
				Award = HYD_JINGYAN,
				tableIndex = tostring(TableIndex.Exp),
				ExtData = "5",	-- 系统经验倍数
		},
[52] = {     --周日常
				Name = LANGUAGE_ZQX_0029, 
				Time = LANGUAGE_ZQX_0030,
				limitLevel = 43,
				activityNum = 70,
				MaxHuoYueDu = 0,
				completeYB = 1,
				CompleteVipLimit = 0,
				CompleteLvLimit = 35,
				SaoDang = 0,
				CompleteNum = 0,
				Award = HYD_JINGYAN,
				tableIndex = tostring(TableIndex.Exp)..","..tostring(TableIndex.Money),
				ExtData = "",
			},
[53] = {	-- 封神试炼
				Name = LANGUAGE_SSJ_0163, 
				Time = LANGUAGE_SSJ_0164,
				limitLevel = 48,
				activityNum = 2,
				MaxHuoYueDu = 10,
				completeYB = 0,
				CompleteVipLimit = 0,
				CompleteLvLimit = 35,
				SaoDang = 0,
				CompleteNum = 0,
				Award = "2538,2818",
				tableIndex = tostring(TableIndex.Exp),
				ExtData = "",
		},
}

local LeiTaiTimeTab = {
	[80] = 1, -- 周日
	[40] = 3, -- 周二
	[50] = 3, -- 周二
	[60] = 5, -- 周四
	[70] = 5, -- 周四

	["startTime"] = 2000, -- 开始时间
	["endTime"] = 2030, -- 结束时间

	["hanzi"] = {
		[1] = LANGUAGE_TRANSFORM_1496,
		[2] = LANGUAGE_TRANSFORM_1497,
		[3] = LANGUAGE_TRANSFORM_1498,
		[4] = LANGUAGE_TRANSFORM_1499,
		[5] = LANGUAGE_TRANSFORM_1500,
		[6] = LANGUAGE_TRANSFORM_1501,
		[7] = LANGUAGE_TRANSFORM_1502,
	},
}

function GetWanFaInfoById(pUser,id)
	local year = j.GetYear() + 1900
	local month = j.GetMonth() + 1
	local mday = j.GetDay()
	local wday = j.GetWeekDay()
	local hour = j.GetHour()
	local minute = j.GetMinute()
	local curTime = os.time()
	local lv = pUser:GetLevel()
	
	local info = "" 				--文字信息
	local action = "" 			--活跃度动作信息
	local name = WAN_FA_CONFIG[id].Name
	local limitLv = WAN_FA_CONFIG[id].limitLevel				-- 限制等级
	local actNum = WAN_FA_CONFIG[id].activityNum				--活动次数
	local maxHuoYueDu = WAN_FA_CONFIG[id].MaxHuoYueDu		--最大活跃度
	local compYB = WAN_FA_CONFIG[id].completeYB					-- 一键完成一次需要消耗的元宝数
	local compVipLimitLv = WAN_FA_CONFIG[id].CompleteVipLimit
	local compLvLimitLv = WAN_FA_CONFIG[id].CompleteLvLimit
	local completeNum = WAN_FA_CONFIG[id].CompleteNum
	local SaoDang = WAN_FA_CONFIG[id].SaoDang
	local tableIdx = WAN_FA_CONFIG[id].tableIndex				-- 标签页
	local time = WAN_FA_CONFIG[id].Time
	local award = WAN_FA_CONFIG[id].Award
	local extData = WAN_FA_CONFIG[id].ExtData
	local monthCardJump = 0	-- 0不跳转 1跳转
	local serverType = j.GetServerType()
	local HYD = 0
	if serverType == "qq_qudao" then
		if id == 5 then
			award = HYD_YUANBAO
		elseif id == 26 then
			award = HYD_YUANBAO
		elseif id == 31 then
			award = "2310,2357"
		elseif id == 33 then
			award = HYD_JINBI..","..HYD_JINGYAN
		end
	end

	if id == 1 then			-- 1 日常boss
		local content = LANGUAGE_TRANSFORM_1503..actNum..LANGUAGE_TRANSFORM_1504
		local desc = LANGUAGE_TRANSFORM_1505
		local data = pUser:GetExtData8(74)
		
		if data > actNum then
			data = actNum
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1506
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		info = info.."0|"
		info = info..tableIdx.."|"
	elseif id == 2 then			-- 2 师门任务
		local content = LANGUAGE_TRANSFORM_1507..actNum..LANGUAGE_TRANSFORM_1508
		local desc = LANGUAGE_TRANSFORM_1509
		local data = pUser:GetSaveVal(2)
		
		if data > actNum then
			data = actNum
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1510
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 3 then			-- 3 多人闯关
		local content = LANGUAGE_TRANSFORM_1511..actNum..LANGUAGE_TRANSFORM_1512
		local desc = LANGUAGE_TRANSFORM_1513
		local data = pUser:GetExtData8(21)
		
		if data > actNum then
			data = actNum
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1514
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 4 then			-- 4 灵气捐献
		local content = LANGUAGE_TRANSFORM_1515..actNum..LANGUAGE_TRANSFORM_1516
		local desc = LANGUAGE_TRANSFORM_1517
		local data = pUser:GetExtData8(69)
		actNum = j.GetJuanxianMax(pUser)
		
		if data > actNum then
			data = actNum
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1518
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 5 then			-- 5 昆仑山
		local content = LANGUAGE_TRANSFORM_1519
		local desc = LANGUAGE_TRANSFORM_1520
		local data = 0	-- pUser:HaveBitSet(301) and 1 or 0
		
		if data > actNum then
			data = actNum
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			if (wday == 2 or wday == 4 or wday == 6) and (hour == 20 and minute >= 30 and minute < 50) then
				action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
			else
				actNum = 0
				action = HuoYueDuState.FEI_HUO_DONG_SHI_JIAN..LANGUAGE_TRANSFORM_1521
			end
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1522
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 6 then			-- 6 钓鱼
		local content = LANGUAGE_TRANSFORM_1523
		local desc = LANGUAGE_TRANSFORM_1524
		local data = 0    -- pUser:HaveBitSet(169) and 1 or 0
		
		if data > actNum then
			data = actNum
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			if hour == 12 and minute >= 30 and minute < 50 then
				action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
			else
				actNum = 0
				action = HuoYueDuState.FEI_HUO_DONG_SHI_JIAN..LANGUAGE_TRANSFORM_1525
			end
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1526
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 7 then	-- 7 每日答题
		local content = LANGUAGE_TRANSFORM_1527..actNum..LANGUAGE_TRANSFORM_1528
		local desc = LANGUAGE_TRANSFORM_1529
		local data = pUser:GetExtData8(6)
		
		if data > actNum then
			data = actNum
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
--			if curTime > pUser:GetExtData32(7) then
				action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
--			else
--				action = HuoYueDuState.DAO_JI_SHI.."|"..(pUser:GetExtData32(7)-curTime)
--			end
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1530
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 8 then				-- 8 百花仙子
		local content = LANGUAGE_TRANSFORM_1531..actNum..LANGUAGE_TRANSFORM_1532
		local desc = LANGUAGE_TRANSFORM_1533
		local data = pUser:HaveBitSet(181) and 1 or 0
		
		local addHuoYueDu = 0
		if data > 0 then
			addHuoYueDu = maxHuoYueDu
		end
		HYD = addHuoYueDu
		if lv >= limitLv then
			if hour == 19 and minute >= 30 and minute < 50 then
				action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
			else
				actNum = 0
				action = HuoYueDuState.FEI_HUO_DONG_SHI_JIAN..LANGUAGE_TRANSFORM_1534
			end
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1535
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 9 then			-- 年兽
		local content = LANGUAGE_LLD_0177
		local desc = LANGUAGE_LLD_0178
		local data = pUser:HaveBitSet(201) and 1 or 0
		
		local addHuoYueDu = 0
		if data > 0 then
			addHuoYueDu = maxHuoYueDu
		end
		HYD = addHuoYueDu
		if lv >= limitLv then
			if hour == 14 and minute < 20 then
				action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
			else
				actNum = 0
				action = HuoYueDuState.FEI_HUO_DONG_SHI_JIAN..LANGUAGE_TRANSFORM_1534
			end
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1535
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 14 then		-- 14 通天塔
		local content = LANGUAGE_TRANSFORM_1536..actNum..LANGUAGE_TRANSFORM_1537
		local desc = LANGUAGE_TRANSFORM_1538
		local data = pUser:GetExtData8(61)
		
		if data > actNum then
			data = actNum
		end
		local addHuoYueDu = 0
		if data >= 1 then
			addHuoYueDu = maxHuoYueDu
		end
		HYD = addHuoYueDu
		if lv >= limitLv then
			action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1539
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 15 then		-- 15 竞技场
		local content = LANGUAGE_TRANSFORM_1540..actNum..LANGUAGE_TRANSFORM_1541
		local desc = LANGUAGE_TRANSFORM_1542
		local data = pUser:GetExtData8(47)
		actNum = j.GetArenaLeftNum(pUser)
		
		if data > actNum then
			data = actNum
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1543
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"

		info = info.."0|"
		info = info..tableIdx.."|"
	elseif id == 16 then			-- 16 护送神将
		local content = LANGUAGE_TRANSFORM_1544..actNum..LANGUAGE_TRANSFORM_1545
		local desc = LANGUAGE_TRANSFORM_1546
		local data = pUser:GetExtData8(81)
		
		if data > actNum then
			data = actNum
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1547
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 17 then			-- 17 挑战灵魔
		local content = LANGUAGE_TRANSFORM_1548
		local desc = LANGUAGE_TRANSFORM_1549
		local data = pUser:HaveBitSet(303) and 1 or 0

		local addHuoYueDu = 0
		if data > 0 then
			addHuoYueDu = maxHuoYueDu
		end
		
		HYD = addHuoYueDu
		if lv >= limitLv then
			if hour == 16 and minute >= 30 and minute < 50 then
				if j.IsInLingMoActivity() then
					action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
				else
					action = HuoYueDuState.QIAN_WANG_CAN_JIA..LANGUAGE_TRANSFORM_1550
				end
			else
				action = HuoYueDuState.FEI_HUO_DONG_SHI_JIAN..LANGUAGE_TRANSFORM_1551
			end
		else
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1552
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 18 then			-- 18 猜拳
		local content = LANGUAGE_TRANSFORM_1553..actNum..LANGUAGE_TRANSFORM_1554
		local desc = LANGUAGE_TRANSFORM_1555
		local data = pUser:GetExtData8(38)
		
		if data > actNum then
			data = actNum
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			if curTime > pUser:GetExtData32(8) then
				action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
			else
				action = HuoYueDuState.DAO_JI_SHI.."|"..(pUser:GetExtData32(8)-curTime)
			end
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1556
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 20 then		-- 20 运镖
		local content = LANGUAGE_TRANSFORM_1557..actNum..LANGUAGE_TRANSFORM_1558
		local desc = LANGUAGE_TRANSFORM_1559
		local data = pUser:GetExtData8(88)
		
		if data > actNum then
			data = actNum
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1560
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 24 then			-- 24 杀敌取宝
		local content = LANGUAGE_TRANSFORM_1561..actNum..LANGUAGE_TRANSFORM_1562
		local desc = LANGUAGE_TRANSFORM_1563
		local data = pUser:GetExtData16(39)
		
		if data > actNum then
			data = actNum
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1564
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 25 then			-- 25 维护丹园
		local content = LANGUAGE_TRANSFORM_1565..actNum..LANGUAGE_TRANSFORM_1566
		local desc = LANGUAGE_TRANSFORM_1567
		local data = pUser:GetExtData8(101)
		
		if data > actNum then
			data = actNum
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1568
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 26 then		-- 26 个人擂台
		local content = LANGUAGE_TRANSFORM_1569
		local desc = LANGUAGE_TRANSFORM_1570
		local data = pUser:HaveBitSet(199) and 1 or 0
		
		if data > actNum then
			data = actNum
		end
		local joinLv = math.floor(lv/10)*10
		if joinLv > 80 then
			joinLv = 80
		elseif joinLv >= 70 and joinLv < 80 then
			joinLv = 60
		elseif joinLv >= 50 and joinLv < 60 then
			joinLv = 40
		end
		local time = string.format(" %02d:%02d-%02d:%02d",LeiTaiTimeTab.startTime/100, LeiTaiTimeTab.startTime % 100, LeiTaiTimeTab.endTime/100, LeiTaiTimeTab.endTime % 100)
		if joinLv >= 40 then
			time = LeiTaiTimeTab.hanzi[LeiTaiTimeTab[joinLv]]..time
		else
			time = LANGUAGE_TRANSFORM_1571..time
		end
		
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			local timeTab = os.date("*t",os.time())
			local curTime = timeTab.hour * 100 + timeTab.min
			local addWeek = LeiTaiTimeTab[joinLv]
			if curTime >= LeiTaiTimeTab.startTime and curTime < LeiTaiTimeTab.endTime
				and not addWeek and timeTab.wday == addWeek + 1 then
				action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
			else
				actNum = 0
				action = HuoYueDuState.FEI_HUO_DONG_SHI_JIAN.."|"..time
			end
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1572
		end
		if joinLv >= 40 then
			limitLv = joinLv
		end
		
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 27 then			-- 27 排行榜
		local content = LANGUAGE_TRANSFORM_1573
		local desc = LANGUAGE_TRANSFORM_1574
		local data = 0
		if lv >= limitLv then
			action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
			info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
			info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
			info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
			info = info.."0|"
			info = info..tableIdx.."|"
		end
	elseif id == 28 then		-- 28 帮派活动
		local content = LANGUAGE_TRANSFORM_1575
		local desc = LANGUAGE_TRANSFORM_1576
		local data = 0
		
		if data > actNum then
			data = actNum
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1577
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"

		info = info.."0|"
		info = info..tableIdx.."|"
	elseif id == 29 then			-- 29 藏宝图
		local content = LANGUAGE_TRANSFORM_1578..actNum..LANGUAGE_TRANSFORM_1579
		local desc = LANGUAGE_TRANSFORM_1580
		local data = pUser:GetExtData32(444)
		
		if data > actNum then
			data = actNum
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1581
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 30 then			-- 30 英勇试炼
		local content = LANGUAGE_TRANSFORM_1582..actNum..LANGUAGE_TRANSFORM_1583
		local desc = LANGUAGE_TRANSFORM_1584
		local data = pUser:GetExtData8(136)	--pUser:GetExtData8(135)
		
		if data > actNum then
			data = actNum
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1585
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 31 then				-- 31 飞仙战场
		local content = LANGUAGE_TRANSFORM_1586
		local desc = LANGUAGE_TRANSFORM_1587
		local data = 0
		
		if data > actNum then
			data = actNum
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			if (wday == 1 or wday == 3 or wday == 5) and (hour == 21 and minute < 20) then
				action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
			else
				actNum = 0
				action = HuoYueDuState.FEI_HUO_DONG_SHI_JIAN..LANGUAGE_TRANSFORM_1588
			end
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1589
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 32 then			-- 32 捉鬼
		local content = LANGUAGE_TRANSFORM_1590
		local desc = LANGUAGE_TRANSFORM_1591
		local data = pUser:GetExtData16(50)
		local cardValue = pUser:GetExtData8(70)
		local cardBit = {}
		monthCardJump = 1		-- 钻石以上不需要跳转
		
		if data > actNum then
			data = actNum
		end
		local idx = 1
		while (cardValue > 0)
		do
			cardBit[idx] = cardValue%2
			cardValue = math.floor(cardValue/2)
			idx = idx + 1
		end
		if cardBit[2] ~= nil and cardBit[2] > 0 then
			completeNum = completeNum+3
			monthCardJump = 0
		end
		if cardBit[3] ~= nil and cardBit[3] > 0 then
			completeNum = completeNum+5
			monthCardJump = 0
		end
		completeNum = completeNum - pUser:GetExtData8(121)
		if completeNum < 0 then
			completeNum = 0
		end		
		
		local addHuoYueDu = 0  --  math.floor(maxHuoYueDu * data / actNum * 3)
		if data >= 30 then
			addHuoYueDu = 30
		else
			addHuoYueDu = data
		end
		HYD = addHuoYueDu
		if lv >= limitLv then
			action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1592
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 33 then			-- 33 六界巡察使
		local content = LANGUAGE_TRANSFORM_1593
		local desc = LANGUAGE_TRANSFORM_1594
		local data = 0
		
		local actData = pUser:GetExtData32(116)
		for i = 0, 31 do
			local nowBit = actData
			if i ~= 0 then
				nowBit = (bit:_rshift(actData, i))
			end
			if bit:_and(nowBit, 1) == 1 then
				data = data + 1
			end
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			if hour >= 10 then
				action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
			else
				action = HuoYueDuState.FEI_HUO_DONG_SHI_JIAN.."|"..time..LANGUAGE_TRANSFORM_1595
			end
		else
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1596
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 34 then			-- 34 帮派掠夺
		local content = LANGUAGE_TRANSFORM_1597
		local desc = LANGUAGE_TRANSFORM_1598
		local data = pUser:GetExtData8(116)
		local maxNum = 1
		time = j.GetBangPaiRobTime()
		if data > maxNum then
			data = maxNum
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / maxNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			if (wday == 1 or wday == 5) and (hour == 20 and minute < 15) then
				action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
			else
				actNum = 0
				action = HuoYueDuState.FEI_HUO_DONG_SHI_JIAN..LANGUAGE_TRANSFORM_1599
			end
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1600
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
--		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
--			info = info.."1|"
--		else
			info = info.."0|"
--		end
		info = info..tableIdx.."|"
	elseif id == 35 then			-- 35 摇钱树
		local content = LANGUAGE_TRANSFORM_1601
		local desc = LANGUAGE_TRANSFORM_1602
		--add by zhudaolong
		local data = pUser:GetExtData8(377)
		local cdTime = pUser:GetExtData32(118)
		local freeNum
		if curTime < cdTime and cdTime ~= 0 then
			freeNum = 0
		else
			freeNum = j.GetYaoQianShuFreeNum(pUser)
		end
		
		if data > actNum then
			data = actNum
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
		else
			actNum = 0
			data = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1603
		end
		
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
--		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
--			info = info.."1|"
--		else
			info = info.."0|"
--		end
		info = info..tableIdx.."|"
	elseif id == 36 then			-- 36 帮战
		local content = LANGUAGE_TRANSFORM_1604
		local desc = LANGUAGE_TRANSFORM_1605
		local data = 0
		
		if data > actNum then
			data = actNum
		end

		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			if (wday == 3 or wday == 6) and ((hour == 19 and minute >= 55) or (hour == 20 and minute < 25)) then
				action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
			else
				actNum = 0
				action = HuoYueDuState.FEI_HUO_DONG_SHI_JIAN..LANGUAGE_TRANSFORM_1606
			end
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1607
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 37 then	-- 修仙历练
		local content = LANGUAGE_TRANSFORM_1608
		local desc = LANGUAGE_TRANSFORM_1609
		local data = 0
		
		if data > actNum then
			data = actNum
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1610
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 38 then	-- 跨服任务
		local content = LANGUAGE_LLD_0051
		local desc = LANGUAGE_LLD_0052
		local data = 0
		local bitsets = {801,802,803,804,805}
		local complete = true
		
		data = pUser:GetExtData8(KUAFULILIAN_DATA8)
		pUser:GetExtData8(KUAFULILIAN_DATA8)
		if data >= actNum then
			data = actNum
		else
			complete = false
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1610
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		
		if complete then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 39 then	-- 血狼啸月
		local content = LANGUAGE_LLD_0056
		local desc = LANGUAGE_LLD_0057
		local data = 0
		
		if data > actNum then
			data = actNum
		end
		limitLv = j.GetFuncOpenLevel(39)
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			if (wday == 1 or wday == 3 or wday == 5) and ((hour == 20 and minute >= 30) or (hour == 20 and minute < 50)) then
				action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
			else
				actNum = 0
				action = HuoYueDuState.FEI_HUO_DONG_SHI_JIAN..LANGUAGE_LLD_0058
			end
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1607
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 40 then	-- 天元争霸
		local content = LANGUAGE_LLD_0061
		local desc = LANGUAGE_LLD_0061
		local data = pUser:HaveBitSet(199) and 1 or 0
		
		if data > actNum then
			data = actNum
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		limitLv = j.GetFuncOpenLevel(id)
		if lv >= limitLv then
			action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1607
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 41 then	-- 神界秘境
		local content = LANGUAGE_LLD_0064
		local desc = LANGUAGE_LLD_0064
		local data = 0
		
		if data > actNum then
			data = actNum
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		limitLv = j.GetFuncOpenLevel(41)
		if lv >= limitLv then
			if (hour == 11 and minute >= 30) then
				action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
			else
				actNum = 0
				action = HuoYueDuState.FEI_HUO_DONG_SHI_JIAN..LANGUAGE_LLD_0187
			end
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1607
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 42 then	-- 跨服帮战
		local content = LANGUAGE_LLD_0067
		local desc = LANGUAGE_LLD_0067
		local data = 0
		
		if data > actNum then
			data = actNum
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			if (wday == 2 or wday == 5) and ((hour == 19 and minute >= 55) or (hour == 20 and minute < 30)) then
				action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
			else
				actNum = 0
				action = HuoYueDuState.FEI_HUO_DONG_SHI_JIAN..LANGUAGE_LLD_0068
			end
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1607
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 43 then			-- 染竹密林
		local content = LANGUAGE_LLD_0167
		local desc = LANGUAGE_LLD_0172
		local data =  pUser:GetExtData8(291)
		
		if data > actNum then
			data = actNum
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1577
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 44 then			-- 升阶副本
		local content = LANGUAGE_LLD_0168
		local desc = LANGUAGE_LLD_0173
		local data =  pUser:GetExtData8(33)
		
		if data > actNum then
			data = actNum
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1577
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 45 then			-- 强化副本
		local content = LANGUAGE_LLD_0169
		local desc = LANGUAGE_LLD_0174
		local data =  pUser:GetExtData8(24)
		
		if data > actNum then
			data = actNum
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1577
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 46 then			-- 金币副本
		local content = LANGUAGE_LLD_0170
		local desc = LANGUAGE_LLD_0175
		local data =  pUser:GetExtData8(100)
		
		if data > actNum then
			data = actNum
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1577
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 47 then			-- 淬炼副本
		local content = LANGUAGE_LLD_0171
		local desc = LANGUAGE_LLD_0176
		local data =  pUser:GetExtData8(99)
		
		if data > actNum then
			data = actNum
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1577
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 49 then			-- 绝谷悬崖
		local content = LANGUAGE_LLD_0179
		local desc = LANGUAGE_LLD_0180
		local data =  pUser:GetExtData8(292)

		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1577
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 50 then			-- 胡泊沼泽
		local content = LANGUAGE_LLD_0183
		local desc = LANGUAGE_LLD_0184
		local data =  pUser:GetExtData8(133)
		
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1577
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 51 then			-- 系统经验双倍
		name = LANGUAGE_SSJ_0158..extData..LANGUAGE_SSJ_0162
		local content = name
		local desc = LANGUAGE_SSJ_0159..extData..LANGUAGE_SSJ_0161
		local data = 0
		
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		local startHour,startMin,stopHour,stopMin = FormatTimeString(time)
		if lv >= limitLv then
			if Timing(os.time{year=year,month=month,day=mday,hour=startHour,min=startMin,sec=0},os.time{year=year,month=month,day=mday,hour=stopHour,min=stopMin,sec=0}) then
				action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
			else
				actNum = 0
				action = HuoYueDuState.FEI_HUO_DONG_SHI_JIAN..LANGUAGE_SSJ_0160
			end
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1577
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"

		info = info.."0|"
		info = info..tableIdx.."|"

	elseif id == 52 then			-- 周日常
		local content = LANGUAGE_TRANSFORM_1507..actNum..LANGUAGE_ZQX_0029
		local desc = LANGUAGE_ZQX_0031
		local times = pUser:GetExtData8(616)
		local turn = pUser:GetExtData8(619)
		local data = turn * 10 +  times
		if data > actNum then
			data = actNum
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1510
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		if (actNum == 0 and data > 0) or (actNum > 0 and data >= actNum) then
			info = info.."1|"
		else
			info = info.."0|"
		end
		info = info..tableIdx.."|"
	elseif id == 53 then			-- 封神试炼
		local content = LANGUAGE_SSJ_0165
		local desc = LANGUAGE_SSJ_0166
		local data = j.GetFengShenDoNum(pUser)
		actNum = j.GetFSBossFightNumPerDay(pUser)
		if data > actNum then
			data = actNum
		end
		local addHuoYueDu = math.floor(maxHuoYueDu * data / actNum)
		HYD = addHuoYueDu
		if lv >= limitLv then
			action = HuoYueDuState.QIAN_WANG_CAN_JIA.."| "
		else
			actNum = 0
			action = HuoYueDuState.DENG_JI_BU_ZU.."|"..limitLv..LANGUAGE_TRANSFORM_1510
		end
		info = info..id.."|"..name.."|"..content.."|"..data.."/"..actNum.."|"..addHuoYueDu.."/"..maxHuoYueDu.."|"..action.."|"
		info = info..desc.."|"..limitLv.."|"..time.."|"..award.."|"..compYB.."|"..compVipLimitLv.."|"..compLvLimitLv.."|"
		info = info..SaoDang.."|"..completeNum.."|"..monthCardJump.."|"
		info = info.."0|"	-- 0 显示参加按钮 1 不显示参加按钮，显示已完成
		info = info..tableIdx.."|"
	end
	return info, HYD
end

-- 玩法排列顺序
--[[
日常boss1   39
师门2       29     
闯关3       39
灵气捐献4   37
昆仑山5     36
钓鱼6       30
每日答题 7  39
百花仙子8   30
年兽 9      30
历练塔14    35
护送神将16  42 
挑战灵魔17  37
运镖20      不开
杀敌夺宝24  50
维护丹园25  71
个人擂台26  40
帮派种植28  32
藏宝图29    38
英勇试炼30  53
飞仙战场31  48
捉鬼32      41
六界使者33  38
帮派掠夺34  35
摇钱树35    39
帮战36      44
修仙历练37  55
跨服任务38  57
血狼啸月39  57
天元争霸40  57
古巫现世41  57
跨服帮战42  未开
蓬莱仙山43  33
升阶副本44  33
强化副本45  33
潜能副本46  33
淬炼副本47  58
岱屿结界49  62
诛仙绝地50  50
5倍挂机 51  30
周日常  52  43
封神试炼 53  48
--]]
WanFaSequence_1 = {
[1] = {2,35,32,4,3,29,14,28,1,16,33,25,37,24,30,5,8,17,34,31,43,44,45,46,47,51,52,53},
[2] = {2,6,8,9,51,28,43,44,45,46},--<33
[3] = {2,14,6,8,9,28,34,43,44,45,46,51},--<35
[4] = {2,14,4,29,5,6,8,9,33,28,17,34,43,44,45,46,51},--<38
[5] = {2,14,3,1,4,29,35,7,5,6,8,9,33,28,17,34,43,44,45,46,51},--<39
[6] = {2,14,32,3,1,4,29,16,35,7,52,5,6,8,9,33,26,28,17,34,43,44,45,46,51},--<43
[7] = {2,14,32,3,37,1,4,29,16,53,35,7,52,5,6,8,9,31,33,26,28,36,17,34,43,44,45,46,51},--<48
[8] = {2,14,32,3,37,1,4,29,16,30,53,24,35,7,52,5,6,8,9,31,33,26,28,36,17,34,38,40,41,39,43,44,45,46,47,50,51},--<56
[9] = {2,14,32,3,37,1,4,29,25,16,30,53,24,35,7,52,5,6,8,9,31,33,26,28,36,17,34,38,40,41,39,43,44,45,46,47,50,49,51},-->=56
}

WanFaSequence_HanBan = {
[1] = {35,2,24,4,3,32,28,16,25,29,30,6,8,17,34,5,33,26,31,1,14},
[2] = {35,25,2,32,28,24,4,3,16,29,30,6,8,17,34,5,33,26,31,1,14},
[3] = {35,29,25,2,32,28,24,4,3,16,30,6,8,17,34,5,33,26,31,1,14},
[4] = {35,30,29,25,2,32,28,24,4,3,16,6,8,17,34,5,33,26,31,1,14},
[5] = {35,30,29,25,2,32,28,24,4,3,16,6,8,17,34,5,33,26,31,1,14},
}

WanFaSequence_YueNan = {
[1] = {35,2,24,4,3,32,28,16,25,29,30,6,8,17,34,5,33,26,31,1,14},
[2] = {35,25,2,32,28,24,4,3,16,29,30,6,8,17,34,5,33,26,31,1,14},
[3] = {35,29,25,2,32,28,24,4,3,16,30,6,8,17,34,5,33,26,31,1,14},
[4] = {35,30,29,25,2,32,28,24,4,3,16,6,8,17,34,5,33,26,31,1,14},
[5] = {35,30,29,25,2,32,28,24,4,3,16,6,8,17,34,5,33,26,31,1,14},
}

WanFaSequence_QuDao = {
[1] = {35,2,24,4,3,32,28,16,25,29,30,37,38,6,8,17,34,5,33,26,31,1,14,36,39,40,41,42},
[2] = {35,25,2,32,28,24,4,3,16,29,30,37,38,6,8,17,34,5,33,26,31,1,14,36,39,40,41,42},
[3] = {35,29,25,2,32,28,24,4,3,16,30,37,38,6,8,17,34,5,33,26,31,1,14,36,39,40,41,42},
[4] = {35,30,29,25,2,32,28,24,4,3,16,37,38,6,8,17,34,5,33,26,31,1,14,36,39,40,41,42},
[5] = {35,38,37,30,29,25,2,32,28,24,4,3,16,6,8,17,34,5,33,26,31,1,14,36,39,40,41,42},
}


function GetHuoYueDuInfo(pUser)
	local huoYueDu = 0 -- 玩家当前活跃度
	local huoYueDuReward = "" -- 玩家是否已经领取过对应活跃度的礼包
	
	for i = 160,164 do
		if i == 163 then -- 90的活跃度去掉了
			
		elseif pUser:HaveBitSet(i) then 
			huoYueDuReward = huoYueDuReward.."1|"
		else
			huoYueDuReward = huoYueDuReward.."0|"
		end
	end

	local level = pUser:GetLevel() -- 玩家等级
	local index = 1
	if level >= 29 and level < 33 then
		index = 2
	elseif level >= 33 and level <35 then
		index = 3
	elseif level >= 35 and level < 38 then
		index = 4
	elseif level >= 38 and level < 39 then
		index = 5
	elseif level >= 39 and level < 43 then
		index = 6
	elseif level >= 43 and level < 48 then
		index = 7
	elseif level >= 48 and level < 56 then
		index = 8
	elseif level >= 56 then
		index = 9
	end

	local num = 0 		-- 当前活跃度条目数
	local info = "" 	--文字信息
	
	local serverType = j.GetServerType()
	local WanFaSequence
	if serverType == "hanban" then
		WanFaSequence = WanFaSequence_HanBan
	elseif serverType == "yuenan" then
		WanFaSequence = WanFaSequence_YueNan
	elseif serverType == "qq_qudao" then
		WanFaSequence = WanFaSequence_QuDao
	else
		WanFaSequence = WanFaSequence_1
	end
	
	for i=1,#WanFaSequence[index],1 do
		local s, h = GetWanFaInfoById(pUser, WanFaSequence[index][i])
		if string.len(s) > 0 then
			num = num + 1
			info = info..s
			huoYueDu = huoYueDu + h
		end
	end
--	print("---------------huoYueDu = "..huoYueDu)
	info = huoYueDu.."|"..huoYueDuReward..num.."|"..info
	return huoYueDu,info
end

function CompleteHuoDongWithYB(pUser,id)
	local vipLv = pUser:GetVipLevel()
	local lv = pUser:GetLevel()
	local YB = pUser:GetMoBao()
	local needYB = 0
	local leftNum = 0
	local res = 0		-- 0失败，1成功
	local compVipLimitLv = WAN_FA_CONFIG[id].CompleteVipLimit
	local compLvLimitLv = WAN_FA_CONFIG[id].CompleteLvLimit
	local completeNum = WAN_FA_CONFIG[id].CompleteNum
	
	if id == 18 then	--猜拳
		if vipLv >= compVipLimitLv and lv >= compLvLimitLv then
			local activityNum = 3
			leftNum = activityNum - pUser:GetExtData8(38)
			if leftNum <= 0 then
				return res,leftNum
			end
			needYB = 1 * leftNum
			
			if YB < needYB then
			 return res,leftNum
			end
			pUser:AddTongBao(0 - needYB,1)
			pUser:SetExtData8(38,activityNum)
			j.SaveDate(pUser,16,leftNum,"")
			
			money = 750 * leftNum
			pUser:AddMoney(money)
			j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1611..money.."[/c]")
			
			leftNum = 0
			res = 1
			return res,leftNum
		end
	elseif id == 7 then	--答题
		if vipLv >= compVipLimitLv and lv >= compLvLimitLv then
			local activityNum = 4
			leftNum = activityNum - pUser:GetExtData8(6)
			if leftNum <= 0 then
				return res,leftNum
			end
			needYB = 1 * leftNum
			
			if YB < needYB then
			 return res,leftNum
			end
			pUser:AddTongBao(0 - needYB,1)
			pUser:SetExtData8(6,activityNum)
			j.SaveDate(pUser,17,leftNum,"")
			
			money = 900 * leftNum
			pUser:AddMoney(money)
			j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1612..money.."[/c]")
			
			leftNum = 0
			res = 1
			return res,leftNum
		end
	elseif id == 2 then	--师门
		if vipLv >= compVipLimitLv and lv >= compLvLimitLv then
			local activityNum = 10
			leftNum = activityNum - pUser:GetSaveVal(2)
			if leftNum <= 0 then
				return res,leftNum
			end
			needYB = 1 * leftNum
			
			if YB < needYB then
			 return res,leftNum
			end
			pUser:AddTongBao(0 - needYB,1)
			pUser:SetSaveVal(2,activityNum)
			j.SaveDate(pUser,18,leftNum,"")
			
			j.DelNpc(pUser,139)
			pUser:DelMission(90)
			pUser:SetDataStr(1,"")
			
			exp = 0
			money = 0
			qianneng = 0
			for i=activityNum-leftNum+1,activityNum,1 do
				exp = exp + figureShiMenExp(pUser,i)
				money = money + figureShiMenYinding(pUser,i)
				qianneng = qianneng + figureShiMenQianNeng(pUser,i)
			end
			pUser:AddExp(exp)
			pUser:AddMoney(money)
			pUser:AddQianNeng(qianneng)
			local worldExpPer = GetWorldExpPercent(pUser)
			if worldExpPer > 0 then
				j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1613..exp..LANGUAGE_TRANSFORM_1614..worldExpPer..LANGUAGE_SSJ_0175..LANGUAGE_TRANSFORM_1615..money..LANGUAGE_TRANSFORM_1616..qianneng.."[/c]")
			else
				j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1617..exp..LANGUAGE_TRANSFORM_1618..money..LANGUAGE_TRANSFORM_1619..qianneng.."[/c]")
			end

			leftNum = 0
			res = 1
			return res,leftNum
		end
	elseif id == 25 then	--维护丹园
		if vipLv >= compVipLimitLv and lv >= compLvLimitLv then
			local activityNum = 10
			leftNum = activityNum - pUser:GetExtData8(101)
			if leftNum <= 0 then
				return res,leftNum
			end
			needYB = 2 * leftNum
			
			if YB < needYB then
			 return res,leftNum
			end
			pUser:AddTongBao(0 - needYB,1)
			pUser:SetExtData8(101,activityNum)
			j.SaveDate(pUser,19,leftNum,"")
			
			pUser:DelMission(222)
			pUser:DelCollect(125,1,3)
			pUser:DelCollect(125,2,3)
			pUser:DelCollect(125,3,3)
			pUser:SetDataStr(6,"")
			
			itemId = 834
			exp = pUser:GetLevel() * 1000 * leftNum
			pUser:AddBangDingPackage(itemId,leftNum)
			pUser:AddExp(exp)
			local worldExpPer = GetWorldExpPercent(pUser)
			if worldExpPer > 0 then
				j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1620..exp..LANGUAGE_TRANSFORM_1614..worldExpPer..LANGUAGE_SSJ_0175..", "..j.GetItemName(itemId).."*"..leftNum.."[/c]")
			else
				j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1622..exp..", "..j.GetItemName(itemId).."*"..leftNum.."[/c]")
			end
			
			
			leftNum = 0
			res = 1
			return res,leftNum
		end
	elseif id == 32 then
		local cardValue = pUser:GetExtData8(70)
		local cardBit = {}
		local idx = 1
		while (cardValue > 0)
		do
			cardBit[idx] = cardValue%2
			cardValue = math.floor(cardValue/2)
			idx = idx + 1
		end
		if cardBit[2] ~= nil and cardBit[2] > 0 then
			completeNum = completeNum+3
		end
		if cardBit[3] ~= nil and cardBit[3] > 0 then
			completeNum = completeNum+5
		end
		
		if pUser:GetExtData8(121) >= completeNum then
			return res,leftNum
		end
		
		if completeNum > 0 and lv >= compLvLimitLv then
			local activityNum = 10
			
			j.SaveDate(pUser,714,1,"")
			idx = pUser:GetExtData16(50)
			local exp = 0
			local money = 0
			local itemNum2538 = 0
			for k=idx+1,idx+completeNum*10,1 do
				if k <= 30 then
					if lv < 40 then
						exp = exp + 40*2800 - (40-lv)*400
					else
						exp = exp + lv*2800
					end
					money = money + 800
				elseif k <= 60 then
					if lv < 40 then
						exp = exp + 40*1400 - (40-lv)*200
					else
						exp = exp + lv*1400
					end
					money = money + 400
				elseif k <= 100 then
					if lv < 40 then
						exp = exp + 40*600 - (40-lv)*100
					else
						exp = exp + lv*600
					end
					money = money + 200
				else
					exp = exp + 2*lv*lv
					money = money + 200
				end
				
				if k%10 == 0 and k>0 and k >= 30 then
					itemNum2538 = itemNum2538+1
				end
			end
			
			pUser:SetExtData16(48,pUser:GetExtData16(48)+completeNum)
			pUser:SetExtData16(50,pUser:GetExtData16(50)+completeNum*10)
			pUser:SetExtData8(121,completeNum)
			pUser:AddExp(exp)
			pUser:AddMoney(money)
			if itemNum2538 > 0 then
				pUser:AddBangDingPackage(2538,itemNum2538)
			end
			local worldExpPer = GetWorldExpPercent(pUser)
			if worldExpPer > 0 then
				if itemNum2538 > 0 then
					j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1623..exp..LANGUAGE_TRANSFORM_1614..worldExpPer..LANGUAGE_SSJ_0175..", "..j.GetItemName(2538).."*"..itemNum2538.."[/c]")
				else
					j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1625..exp..LANGUAGE_TRANSFORM_1614..worldExpPer..LANGUAGE_SSJ_0175.."[/c]")
				end
			else
				if itemNum2538 > 0 then
					j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1627..exp..", "..j.GetItemName(2538).."*"..itemNum2538.."[/c]")
				else
					j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1628..exp.."[/c]")
				end
			end
			
			leftNum = activityNum - pUser:GetExtData16(48)
			if leftNum < 0 then
				leftNum = 0
			end
			res = 1
			return res,leftNum		
		end
	end
--	j.SendSysInfo(pUser,"[c1]一键完成功能"..compVipLimitLv.."级开启[/c]")
	return res,leftNum
end

function GetHuoYueDuRewardInfo(pUser)
	local lv = pUser:GetLevel()
	local addMoney = lv*200
	local addExp = lv*lv*3
	return "-1|1|"..addExp.."|2|"..addMoney.."|-1|3|519|561|0|2|-1|3|631|631|0|2|-1|3|851|851|0|2|-1|3|801|520|0|1|-2|"
end

-- 完成积分任务的数量
function GetWanChengJiFenRenWuCount(pUser)
	--local count = 0
	--for i=200,207 do
		--if pUser:HaveBitSet(i) then 
			--count = count + 1
		--end
	--end
	--return count	
	return pUser:GetExtData8(73)
end

function GetSystemDoubleExpCfg()
	local hd_time = WAN_FA_CONFIG[51].Time
	local extData = WAN_FA_CONFIG[51].ExtData
	local startHour,startMin,stopHour,stopMin = FormatTimeString(hd_time)
	return startHour,startMin,stopHour,stopMin,extData
end


-- // ======================活跃度 结束=======================

-- // ======================开服活动 免费坐骑是否可以领取 开始=======================

local IsFreeUpgradeMountHuoDongUserTab = {"testyw001","luqian1","hn1945","ceshi111","lilangping","243841400","66sjl001","284114999","66sjl002","a8388633","15069461007","244861999","jiao1223","722401","517017368GW","2613619","1393335005","361372181","18264258880","8962100","930765785","18903425241","1191512881","1041299733","18206323738","wen19880413","zgydmlab","luoshijin","cx284942","709552934q","zacyhysys","mzmmzy","709552934","myd999","348992712","juejian","mzmmxl","1432322792","as7887815","15959893260","605794820","ygh661930","zhaohua518","987300318","2817810024","x880212","j880212","hkj018","2864113552","1095385164","jjd444","7760376420","v2000v","xy19991216","zw877575565","j516118571","915997299","6688866","970352806","619390","137873776","1096263317","x516118571","zt9509","maf0520","yuanzhangan","950926","12993125","66351068","a8433296131","6391521","135135","shanji520","1253078594","9876543210","15669013897","762032499","zjp880813","ZPJ336","225123","lhl6514995","w710972294","3232hui","a5y2y0","7774019","ISLOVEME","86518044","971009","qaz13250","mantuoluo","a1111111111","1085331227","13729872610","896575429","260544371","776408","15839083344","wangpan","347118180","ruihunli","543210","915997296","2351591","1900110","rrrrrr","668899abc","qazjun1234","zx159321632","15260653765","1483982098","1324879063","1823585711","340282039","946087564","WEI1987315","wosleige","520131411","zslwqn","mafh0912","231941","137731","757878","yxsolinr250","h130600","a3203369","274982930","198410111","shyxiaolian","qjdhrie8284","3279021","1279117451","a385637741","shenqiao","35803580","qq41092818","wy1012371","36637860","liyun313","1008610086","66sjl003","896516655","zz5498","1993306","mydtst01","mydtst02","mydtst03","18659158780","66sjl004","s2336294","520599","13631017870","1378244344","648072670","uh505681546","qq41092817","668833","z620058","56565656","A851016","6879060306","xiongge0613","915997294","980727466","5726387369","327704504","2351594","ytrhgf","147741","ygh667712","1329573580","282116560","1351352","huang123","3607331991","wslxq66","866654","1351353","ming117","674647459","zx15932163","wangshi","179845796","20114589","ABC44444444","2602806434","786018021wo","5201314lcx","87304583","shanji","b757878","61782333","664622102","332586591","99662288","asdfghjkl12","wweYTJ","zyssjlwz","yaowei123"}
function IsFreeUpgradeMountHuoDongUser(pUser,userName)
	for k,v in ipairs(IsFreeUpgradeMountHuoDongUserTab) do
		if (userName == v) then 
			return 1
		end
	end
	return 0	
end

-- // ======================开服活动 免费坐骑是否可以领取 结束=======================

-- // ======================阶段目标 开始=======================

-- rewardType == -11 金币
-- rewardType == -12 元宝
-- rewardType == -13 道具
-- rewardType == -21 攻击
-- rewardType == -22 防御
-- rewardType == -23 气血

-- 阶段目标
local StageGoalInfoTab = {
	[1] = {
		stage = LANGUAGE_TRANSFORM_1629, -- 章节
		title = LANGUAGE_TRANSFORM_1630, -- 章节名
		target = { -- 章节目标
			-- 目标描述				奖励类型			奖励值		奖励物品数量	是否完成位	是否领取位
			{ msg = LANGUAGE_TRANSFORM_1631, rewardType = -12, reward = 30, rewardNum = 0, isFinish = 101, got = 102 }, -- 分支目标
			{ msg = LANGUAGE_TRANSFORM_1632, rewardType = -12, reward = 30, rewardNum = 0, isFinish = 103, got = 104 },
			{ msg = LANGUAGE_TRANSFORM_1633, rewardType = -12, reward = 30, rewardNum = 0, isFinish = 105, got = 106 },
			{ msg = LANGUAGE_TRANSFORM_1634, rewardType = -12, reward = 30, rewardNum = 0, isFinish = 107, got = 108 },
			{ msg = LANGUAGE_TRANSFORM_1635, rewardType = -12, reward = 30, rewardNum = 0, isFinish = 109, got = 110 },
		},
		reward = { -- 章节奖励
			-- 奖励类型			奖励值
			{ rewardType = -21, reward=100 },
			{ rewardType = -22, reward=50 },
			{ rewardType = -23, reward=3300 },
		},
		isFinish = 0, -- 章节是否完成
		got = 1, -- 章节奖励是否已经领取
	},
	[2] = {
		stage = LANGUAGE_TRANSFORM_1636,
		title = LANGUAGE_TRANSFORM_1637,
		target = {
			{ msg = LANGUAGE_TRANSFORM_1638, rewardType = -12, reward = 75, rewardNum = 0, isFinish = 111, got = 112 },
			{ msg = LANGUAGE_TRANSFORM_1639, rewardType = -12, reward = 75, rewardNum = 0, isFinish = 113, got = 114 },
			{ msg = LANGUAGE_TRANSFORM_1640, rewardType = -12, reward = 75, rewardNum = 0, isFinish = 115, got = 116 },
			{ msg = LANGUAGE_TRANSFORM_1641, rewardType = -12, reward = 75, rewardNum = 0, isFinish = 117, got = 118 },
			{ msg = LANGUAGE_TRANSFORM_1642, rewardType = -12, reward = 75, rewardNum = 0, isFinish = 119, got = 120 },
		},
		reward = {
			{ rewardType = -21, reward=100 },
			{ rewardType = -22, reward=550 },
			{ rewardType = -23, reward=300 },
		},
		isFinish = 2,
		got = 3,
	},
	[3] = {
		stage = LANGUAGE_TRANSFORM_1643,
		title = LANGUAGE_TRANSFORM_1644,
		target = {
			{ msg = LANGUAGE_TRANSFORM_1645, rewardType = -12, reward = 125, rewardNum = 0, isFinish = 121, got = 122 },
			{ msg = LANGUAGE_TRANSFORM_1646, rewardType = -12, reward = 125, rewardNum = 0, isFinish = 123, got = 124 },
			{ msg = LANGUAGE_TRANSFORM_1647, rewardType = -12, reward = 125, rewardNum = 0, isFinish = 125, got = 126 },
			{ msg = LANGUAGE_TRANSFORM_1648, rewardType = -12, reward = 125, rewardNum = 0, isFinish = 127, got = 128 },
			{ msg = LANGUAGE_TRANSFORM_1649, rewardType = -12, reward = 125, rewardNum = 0, isFinish = 129, got = 130 },
		},
		reward = {
			{ rewardType = -21, reward=1100 },
			{ rewardType = -22, reward=50 },
			{ rewardType = -23, reward=300 },
		},
		isFinish = 4,
		got = 5,
	},
	
}

-- 信息查询
function GetStageGoalInfo(pUser)
	local info = ""
	local serverType = j.GetServerType()

	for k,v in ipairs(StageGoalInfoTab) do
		info = info.."-1|"..v.stage.."|"..v.title.."|" -- 标题
		for k1,v1 in ipairs(v.target) do -- 小节
			if serverType == "BT" and v1.rewardType == -12 then
				info = info.."-2|"..v1.msg.."|"..v1.rewardType.."|"..(v1.reward*10).."|"..v1.rewardNum.."|"..ConvertBool2Bit(pUser:HaveSGBitSet(v1.isFinish)).."|"..ConvertBool2Bit(pUser:HaveSGBitSet(v1.got)).."|"
			else
				info = info.."-2|"..v1.msg.."|"..v1.rewardType.."|"..v1.reward.."|"..v1.rewardNum.."|"..ConvertBool2Bit(pUser:HaveSGBitSet(v1.isFinish)).."|"..ConvertBool2Bit(pUser:HaveSGBitSet(v1.got)).."|"
			end
		end
		info = info.."-3|" -- 章节奖励
		for k1,v1 in ipairs(v.reward) do 
			if serverType == "BT" and v1.rewardType == -12 then
				info = info..v1.rewardType.."|"..(v1.reward*10).."|"	
			else
				info = info..v1.rewardType.."|"..v1.reward.."|"	
			end
		end
		info = info.."-4|"..ConvertBool2Bit(pUser:HaveSGBitSet(v.isFinish)).."|"..ConvertBool2Bit(pUser:HaveSGBitSet(v.got)).."|-5|"
	end	
	info = info.."-6"

	--print("阶段目标：",info)
	return info
end

-- 领取小节奖励
function GetSGSectionReward(pUser,stage,section)
	if not StageGoalInfoTab[stage] then -- 没有章节
		return 1
	end
	if not StageGoalInfoTab[stage]["target"][section]	then -- 没有段落
		return 2
	end
	local sectionTab = StageGoalInfoTab[stage]["target"][section]
	if not pUser:HaveSGBitSet(sectionTab.isFinish) then -- 没有完成段落
		return 3
	end
	if pUser:HaveSGBitSet(sectionTab.got) then -- 已经领取过了
		return 4
	end
		
	pUser:SetSGBitSet(sectionTab.got) -- 标记已经领取
	if sectionTab.rewardType == -11 then
		pUser:AddCurrency(sectionTab.reward)
		j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1656..sectionTab.reward.."[/c]")
	elseif sectionTab.rewardType == -12 then
		local serverType = j.GetServerType()
		if serverType == "BT" then
			pUser:AddTongBao(sectionTab.reward*10,1)
			j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1657..(sectionTab.reward*10).."[/c]")
		else
			pUser:AddTongBao(sectionTab.reward,1)
			j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1657..sectionTab.reward.."[/c]")
		end
	elseif sectionTab.rewardType == -13 then
		pUser:AddBangDingPackage(sectionTab.reward,sectionTab.rewardNum)
		j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1658..j.GetItemName(sectionTab.reward).."*"..sectionTab.rewardNum.."[/c]")
	end
	return 0
end

-- 领取章节奖励
function GetSGStageReward(pUser,stage)
	if not StageGoalInfoTab[stage] then -- 没有章节
		return 1
	end
	local stageTab = StageGoalInfoTab[stage]
	if not pUser:HaveSGBitSet(stageTab.isFinish) then -- 没有完成段落
		return 3
	end
	if pUser:HaveSGBitSet(stageTab.got) then -- 已经领取过了
		return 4
	end
		
	pUser:SetSGBitSet(stageTab.got)	-- 标记已经领取

	if pUser:HaveSGBitSet(1) then
		local s=pUser:GetMission(251)
		if s~=nil then
			pUser:UpdateMission(251,"2")
		end
	end
	
	return 0
end

-- 装备章节奖励
function EquipSGStageReward(pUser,stage)
	if stage == 0 then -- 取消装备的处理
		pUser:SetExtData8(23,stage) -- 设置当前使用的章节奖励（神器）
		return 0
	end
	if not StageGoalInfoTab[stage] then -- 没有章节
		return 1
	end
	local stageTab = StageGoalInfoTab[stage]
	if not pUser:HaveSGBitSet(stageTab.isFinish) then -- 没有完成段落
		return 3
	end
	--if pUser:HaveSGBitSet(stageTab.got) then -- 已经领取过了
		--return 4
	--end
	pUser:SetExtData8(23,stage) -- 设置当前使用的章节奖励（神器）
	return 0
end

-- 获取阶段目标属性奖励
function GetStageGoalAttr(pUser)
	local addDamage = 0
	local addRecovery = 0
	local addHp = 0
	local stage = pUser:NoLockGetExtData8(23)
	if stage > 0 then
		local stageTab = StageGoalInfoTab[stage]
		if stageTab and pUser:HaveSGBitSet(stageTab.isFinish) then
			for k,v in ipairs(stageTab.reward) do
				if v.rewardType == -21 then
					addDamage = addDamage + v.reward
				elseif v.rewardType == -22 then
					addRecovery = addRecovery + v.reward
				elseif v.rewardType == -23 then
					addHp = addHp + v.reward
				end
			end
		end
	end

--[[
	for k,v in ipairs(StageGoalInfoTab) do
		if pUser:HaveSGBitSet(v.got) then -- 需要手动领取版本
		--if pUser:HaveSGBitSet(v.isFinish) then -- 不需要手动领取版本
			for k1,v1 in ipairs(v.reward) do
				if v1.rewardType == -21 then 
					addDamage = addDamage + v1.reward
				elseif v1.rewardType == -22 then 
					addRecovery = addRecovery + v1.reward
				elseif v1.rewardType == -23 then 
					addHp = addHp + v1.reward
				end
			end
		end
	end
--]]
	return addDamage,addRecovery,addHp
end

-- 完成阶段目标 小节
function FinishStageGoalSection(pUser,stage,section)
	--print("完成阶段目标 小节:",stage,section)
	if not StageGoalInfoTab[stage] then -- 没有章节
		return 0
	end
	if not StageGoalInfoTab[stage]["target"][section]	then -- 没有段落
		return 0
	end	
	local sectionTab = StageGoalInfoTab[stage]["target"][section]	
	if pUser:HaveSGBitSet(sectionTab.isFinish) then -- 已经设置过了就不需要通知客户端了
		return 0
	end
	pUser:SetSGBitSet(sectionTab.isFinish)
	local flag = true -- 需要更新章节完成
	for k,v in ipairs(StageGoalInfoTab[stage]["target"]) do
		if not pUser:HaveSGBitSet(v.isFinish) then 
			flag = false
			break
		end
	end
	if flag then 
		return 2
	end	
	return 1
end

-- 完成阶段目标 章节
function FinishStageGoalStage(pUser,stage)
	--print("完成阶段目标 章节",stage)
	if not StageGoalInfoTab[stage] then -- 没有章节
		return 0
	end
	if pUser:HaveSGBitSet(StageGoalInfoTab[stage].isFinish) then -- 已经设置过了就不需要通知客户端了
		return 0
	end
	pUser:SetSGBitSet(StageGoalInfoTab[stage].isFinish)
	return 1
end
	
-- bool转化为bit的1,0
function ConvertBool2Bit(flag)
	if flag then 
		return 1
	else
		return 0
	end
end	

-- // ======================阶段目标 结束=======================


EquipmentIndex = {
	0,	-- 头盔
	1,	-- 盔甲
	2,	-- 腰带
	3,	-- 鞋子
	4,	-- 武器
	5,	-- 项链
	6, 	-- 戒指
	7,	-- 护腕1
	8,	-- 护腕2
}

FFPushType = {
	1,	--神将出战
	2,	--装备强化
	3,	--获得神将
	4,	--神将进化
	5,	--宠铠强化
	6,	--神将升级
	7,	--装备升阶
	8,	--技能提升
	9,	--装备淬炼
	10,	--神将血脉
}

function FightFailedNotice(pUser,fightType,taskId,extParm)
	
	--第一次挑战血魔战斗失败
	if taskId == 61 then
		j.SendFightFailed_PushMsg(pUser,"", LANGUAGE_TRANSFORM_1659)
		return
	end	
	
	--血魔第二次任务失败提示
	if taskId == 66 then
		j.SendFightFailed_PushMsg(pUser,FFPushType[1], LANGUAGE_TRANSFORM_1660)
		return
	end
	
	--春秋不败任务
	if taskId == 103 or taskId == 104  then
		j.SendFightFailed_PushMsg(pUser,FFPushType[1], LANGUAGE_TRANSFORM_1661)
		j.ChangeClientGuaJiState(pUser,2)
		j.SendYinDao2_Op(pUser,38)	-- 死亡失败提示
		return
	end

	--狐妖任务
	if taskId == 105  then
		j.SendFightFailed_PushMsg(pUser,"", LANGUAGE_TRANSFORM_1662)
		j.ChangeClientGuaJiState(pUser,2)
		return
	end

	--狐妖任务
	if taskId == 107  then
		j.SendFightFailed_PushMsg(pUser,FFPushType[4], LANGUAGE_TRANSFORM_1663)
		j.ChangeClientGuaJiState(pUser,2)
		return
	end	
	
	--矿副本
	if fightType == 75 then
		if extParm == 0 then     --金币
			j.SendFightFailed_PushMsg(pUser,FFPushType[4].."|"..FFPushType[6], "")
			return			
		elseif extParm == 1 then --强化
			j.SendFightFailed_PushMsg(pUser,FFPushType[2].."|"..FFPushType[7], LANGUAGE_TRANSFORM_1664)
			return
		elseif extParm == 2 then --升阶	
			j.SendFightFailed_PushMsg(pUser,FFPushType[2].."|"..FFPushType[7], LANGUAGE_TRANSFORM_1665)
			return
		elseif extParm == 3 then --淬炼
			j.SendFightFailed_PushMsg(pUser,FFPushType[2].."|"..FFPushType[7], LANGUAGE_TRANSFORM_1666)
			return
		elseif extParm == 4 then --潜能	
			j.SendFightFailed_PushMsg(pUser,FFPushType[4].."|"..FFPushType[6], "")
			return		
		elseif extParm == 5 then --站铠	
			j.SendFightFailed_PushMsg(pUser,FFPushType[4].."|"..FFPushType[6], LANGUAGE_TRANSFORM_1667)
			return		
		end
	end

	local lv = pUser:GetLevel()	
	if lv < 16 then
		j.SendFightFailed_PushMsg(pUser,FFPushType[1], "")
	elseif lv < 21 then
		j.SendFightFailed_PushMsg(pUser,FFPushType[1].."|"..FFPushType[4], "")
	elseif lv < 31 then
		j.SendFightFailed_PushMsg(pUser,FFPushType[1].."|"..FFPushType[4].."|"..FFPushType[2], "")
	elseif lv < 36 then
		j.SendFightFailed_PushMsg(pUser,FFPushType[4].."|"..FFPushType[2].."|"..FFPushType[7], "")
	elseif lv < 40 then
		j.SendFightFailed_PushMsg(pUser,FFPushType[4].."|"..FFPushType[7].."|"..FFPushType[10], "")
	elseif lv < 43 then
		j.SendFightFailed_PushMsg(pUser,FFPushType[4].."|"..FFPushType[10].."|"..FFPushType[9], "")
	elseif fightType~=53 then
		j.SendFightFailed_PushMsg(pUser,FFPushType[10].."|"..FFPushType[5].."|"..FFPushType[9], "")
	end
end
