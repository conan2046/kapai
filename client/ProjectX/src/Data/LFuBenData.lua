-- LBigmap = {}
-- LBigmap.__index = LBigmap
-- function LBigmap:New()
-- 	local o = {}
-- 	setmetatable(o, LBigmap)	
-- 	o:ctor()
-- 	return o
-- end

-- function LBigmap:ctor()
-- 	self.Id = 0    --章节id
-- 	self.MapType = 0 -- 地图类型 (1 主线 2支线 3 封神试炼)
-- 	self.Name = ""   -- 章节名称
-- 	self.Desc = ""    -- 描述
-- 	self.OpenLv = 0    --开启等级
-- 	self.BundleId = 0      --地图美术资源
-- 	self.OpenTime = {}        --开放时间
-- 	self.star_reward = {}		--星级奖励
-- 	self.DialogueId = 0      --剧情对话
-- end

-- function LBigmap:Delete()
-- 	self.Id = nil    --章节id
-- 	self.MapType = nil -- 地图类型 (1 主线 2支线 3 封神试炼)
-- 	self.Name = nil   -- 章节名称
-- 	self.Desc = nil    -- 描述
-- 	self.OpenLv = nil    --开启等级
-- 	self.BundleId = nil      --地图美术资源
-- 	self.OpenTime = nil        --开放时间
-- 	self.star_reward = nil		--星级奖励
-- 	self.DialogueId = nil      --剧情对话
-- end



--maplist
LStageNode = {}
LStageNode.__index = LStageNode
function LStageNode:New()
	local o = {}
	setmetatable(o, LStageNode)	
	o:ctor()
	return o
end

function LStageNode:ctor()
	self.ID = 0    --关卡id
	self.mapid = 0 -- 章节ID
	self.Name = ""   -- 关卡名称
	self.Des = ""    -- 描述
	self.type = 0    --1普通关2精英关3BOSS
	self.fightID = 0      --战斗表ID
	self.Levellimit = 0        --等级限制
	self.Suggestpower = 0		--挑战战斗力建议
	self.UnlockID = 0           --通关解锁关卡ID
	self.Hope = 0							--消耗体力值
	self.first_reward = {}  --首通奖励
	self.rewardID = 0 --正常奖励
	self.add_reward = 0 --通关额外宝箱
	self.money = {}  --掉落货币
	self.exp_pet =0 --神将经验
	self.show_reward = {}  --掉落展示
	self.AttackCount =0  --每日基础挑战次数
	self.BattleMapName = ""  -- 地图场景资源名
	self.DialogueId = 0    -- DialogueId
	self.RecommendHero = {}    --推荐英雄
	self.fight_reward = {}
	self.final_kill = {}
	self.kill_reward = 0
	self.max_damage = {}
end

function LStageNode:Delete()
	self.ID = nil    --关卡id
	self.mapid = nil -- 章节ID
	self.Name = nil   -- 关卡名称
	self.Des = nil    -- 描述
	self.type = nil   --1普通关2精英关3BOSS
	self.fightID = nil      --战斗表ID
	self.Levellimit = nil        --等级限制
	self.Suggestpower = nil		--挑战战斗力建议
	self.UnlockID = nil           --通关解锁关卡ID
	self.Hope = nil							--消耗体力值
	self.first_reward = nil  --首通奖励
	self.rewardID = nil --正常奖励
	self.add_reward = nil --通关额外宝箱
	self.money = nil  --掉落货币
	self.exp_pet = nil --神将经验
	self.show_reward = nil  --掉落展示
	self.AttackCount = nil  --每日基础挑战次数
	self.BattleMapName = nil  -- 地图场景资源名
	self.DialogueId = nil    -- DialogueId
	self.RecommendHero = nil    --推荐英雄
	self.fight_reward = nil   --公会副本每次挑战奖励
	self.final_kill = nil   --最后一击奖励
	self.kill_reward = nil  --BOSS击杀奖励
	self.max_damage = nil   --最高伤害奖励
end



--LFightData
LFightData = {}
LFightData.__index = LFightData
function LFightData:New()
	local o = {}
	setmetatable(o, LFightData)	
	o:ctor()
	return o
end

function LFightData:ctor()
	self.id =  0
    self.level_reward = 0
    self.zhenfa = {}
    self.zhenfa_id = 5
    self.zhenfa_level = {}
    self.show = 0
    self.index1 = 0
    self.index2 = 1008
    self.index3 = 0
    self.index4 = 0
    self.index5 = 0
    self.fight_dialog_id = 0
    self.team_buff = 0
end

function LFightData:Delete()
	self.id =  nil
    self.level_reward = nil
    self.zhenfa = nil
    self.zhenfa_id = nil
    self.zhenfa_level = nil
    self.show = nil
    self.index1 = nil
    self.index2 = nil
    self.index3 = nil
    self.index4 = nil
    self.index5 = nil
    self.fight_dialog_id = nil
    self.team_buff = nil
end

