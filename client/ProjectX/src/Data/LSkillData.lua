--[[
技能配置表数据信息
]]
LSkillBasicCfg = {}
LSkillBasicCfg.__index = LSkillBasicCfg
function LSkillBasicCfg:New()
	local o = {}
	setmetatable(o,LSkillBasicCfg)	
	o:ctor()
	return o
end

function LSkillBasicCfg:ctor()
	self.name = ""          --名字
	self.desc = ""          --介绍
	self.id = 0             --id
	self.skillType = 0	    --1主动技能2被动技能
	self.effects = {}		--技能效果，前端不需要
	self.cd = 0				--技能cd
	self.picFile = ""
	self.skillTypeTitle = ""    --技能类型,加技能标签
	--[[
	技能描述参数
	{
		{类型，id, 参数},--数组
		{类型，id, 参数},--数组
		{类型，id, 参数},--数组
	}
	参数解释：
		类型：	1：skill_active_effect技能主动效果表
				2：skill_addtive_effect技能附加效果表
		id:		对应类型表里面的id值
		参数:	对应效果表里面的param索引
		比如{1-11-2}:取skill_active_effect表里面id为11字段里面的para2这个参数值
	]]
	self.descParams = {}
end

function LSkillBasicCfg:SetDesc(desc)
	local tmp = "%{(%d+)-(%d+)-(%d)%}"
	self.desc = string.gsub(desc,tmp,
		function(a,b,c) 
			-- print("a,b,c",a,b,c)
			table.insert(self.descParams,{tonumber(a),tonumber(b),tonumber(c)})
			return "[c3]%s[/c3]"
		end)
end

function LSkillBasicCfg:Delete()
	self.name = nil          --名字
	self.desc = nil         --介绍
	self.id = nil            --id
	self.skillType = nil
	self.effects = nil         --等级
	self.cd = nil        --目标
	self.descParams = nil        --消耗
	self.skillTypeTitle = nil    --技能类型图标
end

--[[
主动技能效果配置
]]
LSkillActiveCfg = {}
LSkillActiveCfg.__index = LSkillActiveCfg
function LSkillActiveCfg:New()
	local o = {}
	setmetatable(o,LSkillActiveCfg)	
	o:ctor()
	return o
end

function LSkillActiveCfg:ctor()
	self.id = 0	 --主动效果id
	self.actionType = 0--主动效果类型
	self.targetType = 0--目标类型
	self.targetRange = 0--目标范围
	self.targetSelect = 0--目标选择
	self.targetNum = 0--目标数量
	self.buffId = 0--效果id
	self.params = {}
	--固定三个参数，一个值，一个等级，前两个百分比参数，最后一个固定值参数
	for i = 1, 3 do
		table.insert(self.params,{0,0})
	end
	
end

function LSkillActiveCfg:Delete()
	self.id = nil	 --主动效果id
	self.actionType = nil--主动效果类型
	self.targetType = nil--目标类型
	self.targetRange = nil--目标范围
	self.targetSelect = nil--目标选择
	self.targetNum = nil--目标数量
	self.buffId = nil--效果id
	self.params = nil
end

--[[
被动技能配置
]]
LSkillAdditiveCfg = {}
LSkillAdditiveCfg.__index = LSkillAdditiveCfg
function LSkillAdditiveCfg:New()
	local o = {}
	setmetatable(o,LSkillAdditiveCfg)	
	o:ctor()
	return o
end

function LSkillAdditiveCfg:ctor()
	self.id = 0	 --主动效果id
	self.showStr = ""--被动触发显示的文字，战斗用
	self.trigger = 0--触发时机
	self.addType = 0--附加效果类型
	self.buffId = 0
	self.params = {}
	--固定五个参数，一个值，一个等级，前三个百分比参数，最后两个固定值参数
	for i = 1, 5 do
		table.insert(self.params,{0,0})
	end
	
end

function LSkillAdditiveCfg:Delete()
	self.id = nil	 --主动效果id
	self.actionType = nil--主动效果类型
	self.addType = nil--目标类型
	self.buffId = nil
	self.params = nil
end

--技能详细信息
LSkillDetail = {}
LSkillDetail.__index = LSkillDetail
function LSkillDetail:New()
	local o = {}
	setmetatable(o,LSkillDetail)	
	o:ctor()
	return o
end

function LSkillDetail:ctor()
	self.name = ""          --名字
	self.desc = ""          --介绍
	self.id = 0            --id
	self.type = 0
	self.level = 0         --等级
	self.target = 0        --目标
	self.useUp = 0         --消耗
	self.cdt = 0           --CD
	self.learnLevel = 0    --可学习等级
	self.learnProf = 0	   --可学习职业 0,1昆仑山2异朽阁5妖魔殿
	self.fraze = 0			--冷却回合数
end

function LSkillDetail:Delete()
	self.name = nil          --名字
	self.desc = nil         --介绍
	self.id = nil            --id
	self.type = nil
	self.level = nil         --等级
	self.target = nil        --目标
	self.useUp = nil         --消耗
	self.cdt = nil           --CD
	self.learnLevel = nil    --可学习等级
	self.learnProf = nil	   --可学习职业 0,1昆仑山2异朽阁5妖魔殿
	self.fraze = nil			--冷却回合数
end

function LSkillDetail:getname() return name end          --名字
function LSkillDetail:getdesc() return desc end          --介绍
function LSkillDetail:getid() return id end            --id
function LSkillDetail:gettype() return type end 
function LSkillDetail:getlevel() return level end         --等级
function LSkillDetail:gettarget() return target end        --目标
function LSkillDetail:getuseUp() return useUp end          --消耗
function LSkillDetail:getcdt() return cdt end            --CD
function LSkillDetail:getlearnLevel() return learnLevel end     --可学习等级
function LSkillDetail:getlearnProf() return learnProf end 	   --可学习职业 0,1昆仑山2异朽阁5妖魔殿
function LSkillDetail:getfraze() return fraze end 			--冷却回合数

--[[
天书技能学习
]]
LBookSkStudyData = {}
LBookSkStudyData.__index = LBookSkStudyData
function LBookSkStudyData:New()
	local o = {}
	setmetatable(o,LBookSkStudyData)	
	o:ctor()
	return o
end

function LBookSkStudyData:ctor()
	self.itemId =  0--消耗的道具id
	self.skId = 0--天书id
	self.skLv = 0--学习的天书等级
end

function LBookSkStudyData:Delete()
	self.itemId =  nil--消耗的道具id
	self.skId = nil--天书id
	self.skLv = nil--学习的天书等级
end

--技能升级信息
LSkillLevelUpInfo = {}
LSkillLevelUpInfo.__index = LSkillLevelUpInfo
function LSkillLevelUpInfo:New()
	local o = {}
	setmetatable(o,LSkillLevelUpInfo)	
	o:ctor()
	return o
end

function LSkillLevelUpInfo:ctor()
	self.id = 0
	self.level = 0
	self.qianNeng = 0
	self.money = 0
end

function LSkillLevelUpInfo:Delete()
	self.id = nil
	self.level = nil
	self.qianNeng = nil
	self.money = nil
end

LSkillMgr = {}
LSkillMgr.__index = LSkillMgr
-- LSkillMgr.SkillInfoList = 
-- {
-- 	{1,2,4.5},
-- 	{2,31,5},
-- 	{3,56,7},
-- 	{4,81,8},
-- 	{5,21,4},
-- 	{6,31,5},
-- 	{7,56,7},
-- 	{8,81,8},
-- 	{17,21,4},
-- 	{18,31,5},
--  	{19,56,7},
--  	{20,81,8},
--  	{21,2,4.5},
--  	{22,2,4.5},
--  	{23,86,7},
--  	{24,86,7},
--  	{25,21,4},
--  	{57,71,14.7},
--  	{58,76,16.8},
--  	{67,61,8.4},
--  	{68,66,10.5},
--  	{69,71,14.7},
--  	{70,76,16.8},
--  	{104,51,9.6},
--  	{105,36,4.8},
--  	{106,41,6},
--  	{107,46,8.4},
--  	{108,51,9.6},
--  	{117,36,4.8},
--  	{118,41,6},
--  	{119,46,8.4},
--  	{120,51,9.6}
--  }

-- function LSkillMgr:QuerySkillDescBySkillId(skillId)
-- 	if skillId <= 0 then
-- 		return
-- 	end
-- 	local pSkill = self:getSkillById(skillId)
-- 	if pSkill == nil or string.len(pSkill.desc) > 0 then
-- 		return
-- 	end
-- 	LuaNetSendMsg:QuerySkillDesc(skillId)
-- end

-- function LSkillMgr:SetSkillDescBySkillId(skillId,desc)
-- 	if skillId <= 0 then
-- 		return
-- 	end
-- 	local pSkill = self:getSkillById(skillId)
-- 	if pSkill == nil then
-- 		return
-- 	end
-- 	pSkill.desc = desc
-- end
-- function LSkillMgr:UpdateSkill(skill)--更新技能基本信息
-- 	if skill.level <= 0 then
-- 		return
-- 	end
-- 	self:QuerySkillDescBySkillId(skill.id)
-- 	local sid = skill.id
-- 	if sid == 1 or sid == 2 or sid == 4 or sid == 5 or sid == 7 or sid == 8 or sid == 11 or sid == 12 or sid == 14 or sid == 15 or sid == 22 or sid == 23 or sid == 24 or sid == 25 then
-- 	elseif sid == 3 or sid == 6 or sid == 9 or sid == 60 or sid == 61 or sid == 62 then
-- 		skill.useUp = 30
-- 	elseif sid == 10 or sid == 13 or sid == 16 or sid == 52 or sid == 54 or sid == 56 then
-- 			skill.useUp = 16
-- 	elseif sid == 17 or sid == 18 or sid == 19 or sid == 20 or sid == 21 then
-- 		skill.useUp = 19
-- 	elseif sid == 51 or sid == 53 or sid == 55 then
-- 		skill.useUp = 10
-- 	elseif sid == 57 or sid == 101 or sid == 102 or sid == 103 then
-- 		skill.useUp = 20
-- 	elseif sid == 58 then
-- 		skill.useUp = 25
-- 	elseif sid == 104 or sid == 105 then
-- 		skill.useUp = 23
-- 	elseif sid == 59 then
-- 		skill.useUp = 35
-- 	else
-- 		skill.useUp = -1
-- 	end

-- 	if sid == 4 or sid == 7 or sid == 10 or sid == 11 or sid == 13 or sid == 14 or sid == 16 or sid == 22 or sid == 24 or sid == 51 or sid == 53 or sid == 55 or sid == 57 or sid == 58 or sid == 59 or sid == 60 or sid == 61 or sid == 62 then
-- 		skill.target =  1
-- 	elseif sid == 1 or
-- 		sid == 12 or 
-- 		sid == 15 or
-- 		sid == 23 or
-- 		sid == 25 then
-- 		skill.target =  2
-- 	elseif sid == 5 or sid == 8 then
-- 		skill.target = 3
--     elseif sid == 17 or sid == 18 or sid == 19 or sid == 20 or sid == 21 then
-- 		skill.target = 4
-- 	elseif sid == 2 then
-- 		skill.target = 5
-- 	elseif sid == 3 or sid == 6 or sid == 9 then
-- 		skill.target = 6
-- 	elseif sid == 52 or sid == 54 or sid == 56 then
-- 		local v = math.floor(1 + (skill.level - 1)/8)
-- 		skill.target = 5
-- 		if v < 5 then
-- 			skill.target = v
-- 		end
-- 	elseif sid == 101 or sid == 102 or sid == 103 or sid == 104 or sid == 105 then
-- 		local v = math.floor(1 + (skill.level - 1)/8)
-- 		skill.target = 3
-- 		if v < 3 then
-- 			skill.target = v
-- 		end
-- 	else
-- 		skill.target = 0
-- 	end
-- end
function LSkillMgr:getSkillById(id)
	local skillList = LDataConstMgr:GetSkillDetailList(id)
	return skillList
end

-- function LSkillMgr:GetSkillTargetById(id)	-- 0 enemy 1 friend
-- 	if (id >= 51 and id <= 56) or (id >= 60 and id <= 62) or id >= 151 then
-- 		return 1
-- 	else
-- 		return 0
-- 	end
-- end

--[[
lua基本变量没有引用，这个采用返回值的方式，返回两个变量，一个mana,一个targetNum
]]
-- function LSkillMgr:GetSkillManaAndTarNum(skillId,level)
-- 	local mana = 0
-- 	local targetNum = 0
-- 	if level < 0 then
-- 		return mana, targetNum
-- 	end
-- 	if skillId == 1 or
-- 		skillId == 2 or
-- 		skillId == 4 or
-- 		skillId == 5 or
-- 		skillId == 7 or
-- 		skillId == 8 or
-- 		skillId == 11 or
-- 		skillId == 12 or
-- 		skillId == 14 or
-- 		skillId == 15 or
-- 		skillId == 22 or
-- 		skillId == 23 or
-- 		skillId == 24 or
-- 		skillId == 25 then
-- 		mana = 0
-- 	elseif skillId == 3 or
-- 		skillId == 6 or
-- 		skillId == 9 then
-- 		mana = 100
-- 	elseif skillId == 60 or
-- 		skillId == 61 or
-- 		skillId == 62 then
-- 		mana = 30
-- 	elseif skillId == 10 or
-- 		skillId == 13 or
-- 		skillId == 16 or
-- 		skillId == 52 or
-- 		skillId == 54 or
-- 		skillId == 56 then
-- 		mana = 16
-- 	elseif skillId == 17 or
-- 		skillId == 18 or
-- 		skillId == 19 or
-- 		skillId == 20 or
-- 		skillId == 21 then
-- 		mana = 19
-- 	elseif skillId == 51 or
-- 		skillId == 53 or
-- 		skillId == 55 then
-- 		mana = 10
-- 	elseif skillId == 57 or
-- 		skillId == 101 or
-- 		skillId == 102 or
-- 		skillId == 103 then
-- 		mana = 20
-- 	elseif skillId == 58 then
-- 		mana = 25
-- 	elseif skillId == 104 or
-- 		skillId == 105 then
-- 		mana = 23
-- 	elseif skillId == 59 then
-- 		mana = 35
-- 	else
-- 		mana = -1
-- 	end

-- 	if skillId == 4 or
-- 		skillId == 7 or
-- 		skillId == 10 or
-- 		skillId == 11 or
-- 		skillId == 13 or
-- 		skillId == 14 or
-- 		skillId == 16 or
-- 		skillId == 51 or
-- 		skillId == 53 or
-- 		skillId == 55 or
-- 		skillId == 57 or
-- 		skillId == 58 or
-- 		skillId == 59 or
-- 		skillId == 60 or
-- 		skillId == 22 or
-- 		skillId == 24 or
--         skillId == 31 or
--         skillId == 64 then
-- 		targetNum =  1
-- 	elseif skillId == 1 or
-- 		skillId == 15 or
--         skillId == 21 or
--         skillId == 28 or
-- 		skillId == 23 or
-- 		skillId == 25 then
-- 		targetNum =  2
-- 	elseif skillId == 5 or
-- 		skillId == 8 then
-- 		targetNum = 3
-- 	elseif skillId == 2 then
-- 		targetNum = 4
-- 	elseif skillId == 52 or
-- 		skillId == 54 or
-- 		skillId == 56 then
-- 		local v = math.floor((level - 1)/15) + 1
-- 		targetNum = 5
-- 		if v < 5 then
-- 			targetNum = v
-- 		end
-- 	elseif skillId == 101 or
-- 		skillId == 102 or
-- 		skillId == 103 or
-- 		skillId == 104 or
-- 		skillId == 105 then
-- 		targetNum = 3
-- 		local v = math.floor((level - 1)/15) + 1
-- 		if v < 3 then
-- 			targetNum = v
-- 		end
-- 	elseif skillId == 3 or
-- 		skillId == 9 or
-- 		skillId == 6 then
-- 		targetNum = 6
-- 	else
-- 		targetNum = 0
-- 	end
-- 	return mana,targetNum
-- end

-- function LSkillMgr:GetSkillJie(id)
-- 	local num = 0
-- 	if id <= 50 then
-- 		num = id % 4
-- 	elseif id <= 100 then
-- 		id = id - 50
-- 		num = id % 4
-- 	else
-- 		id = id - 100
-- 		num = id % 4
-- 	end
-- 	if num == 0 then
-- 		num = 4
-- 	end
-- 	return num
-- end

--[[
lua基本变量没有引用，这个采用返回值的方式，返回三个变量，一个qianNeng,一个gold,一个requireLevel
]]
-- function LSkillMgr:GetSkillNextLevelConsume(skillId,nextLevel)
-- 	-- int id
-- 	-- int learnLevel
-- 	-- double QNBeiLv	-- 潜能倍率
-- 	local qianNeng = 0
-- 	local gold = 0
-- 	local requireLevel = 0
-- 	local beilv = 0.0
-- 	local trueLevel = 0
-- 	for i = 1,#LSkillMgr.SkillInfoList do
-- 		if LSkillMgr.SkillInfoList[i][1] == skillId then
-- 			beilv = LSkillMgr.SkillInfoList[i][3]
-- 			trueLevel = LSkillMgr.SkillInfoList[i][2]
-- 			break
-- 		end
-- 	end
-- 	if beilv < 0.0001 or trueLevel == 0 then
-- 		return qianNeng, gold, requireLevel
-- 	end
-- 	trueLevel = trueLevel + (nextLevel-1)*2

-- 	requireLevel = trueLevel
-- 	qianNeng = trueLevel*trueLevel*beilv
-- 	gold = math.floor(qianNeng/3)
-- 	return qianNeng, gold, requireLevel
-- end
-- function LSkillMgr:GetRealSkillLevel(skillId,level)--获得真实的技能等级
-- 	local trueLevel = 0
-- 	local beilv = 0.0
-- 	-- int id
-- 	-- int learnLevel
-- 	-- double QNBeiLv	-- 潜能倍率
-- 	for i = 1,#LSkillMgr.SkillInfoList do
-- 		if LSkillMgr.SkillInfoList[i][1] == skillId then
-- 			beilv = LSkillMgr.SkillInfoList[i][3]
-- 			trueLevel = LSkillMgr.SkillInfoList[i][2]
-- 			break
-- 		end
-- 	end
-- 	trueLevel = trueLevel + level*2
-- 	return trueLevel
-- end
-- function LSkillMgr:GetLearnLevelById(id)
-- 	-- int id
-- 	-- int learnLevel
-- 	-- double QNBeiLv	-- 潜能倍率
-- 	local learnLevel = 0
-- 	for i = 1,#LSkillMgr.SkillInfoList do
-- 		if LSkillMgr.SkillInfoList[i][1] == skillId then
-- 		    learnLevel = SkillInfoList[i][2]
-- 		end
-- 	end
-- 	return learnLevel
-- end
-- --获取技能公式
-- function LSkillMgr:getSkillDescFormulaDataWithId(skillId,isMonster)
-- 	if isMonster == nil then
-- 		isMonster = false
-- 	end
-- end
--获取技能升级所需人物等级
-- function LSkillMgr:SkillUpNeedHeroLevel(skillId,skillLv)
-- 	local skill = self:getSkillById(skillId)
-- 	if skill == nil then
-- 		return 0
-- 	end
-- 	return skill.learnLevel + skillLv * 3
-- end
--获取各职业技能信息
--[[
返回UserSkillInfo和skillNum
]]
function LSkillMgr:GetSkillInfo(prof)
    local skill = LDataConstMgr.m_skills[prof]
    if skill == nil then return  nil, 0 end
    return skill.skillOpenLv, #skill.skillOpenLv
end


