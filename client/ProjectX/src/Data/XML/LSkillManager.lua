--[[
	技能
]]
LSkillData = {}
LSkillData.__index = LSkillData
function LSkillData:New(id,level)
	local o = {}
	setmetatable(o,LSkillData)	
	o:ctor(id,level)
	return o
end

function LSkillData:ctor(id,level)
	self.m_wId = id
	self.m_skillLevel = level
	self.m_skilltable = LSkillManager:Instance():GetSkillData(id)
end

--[[
	技能
]]
LSkilltableData = {}
LSkilltableData.__index = LSkilltableData
function LSkilltableData:New()
	local o = {}
	setmetatable(o,LSkilltableData)	
	o:ctor()
	return o
end
function LSkilltableData:ctor()
	self.m_wId = 0

	self.m_wId = 0
	self.m_strName = 0
	self.m_skillLevel = 0
	self.m_icon = 0
	self.m_iType = 0
	self.m_fictionId = 0
	self.m_levelupDes = 0
	self.m_byUseType = 0
	self.m_targetType = 0

	self.m_forgetCostItemID = 0
	self.m_forgetCostItemNum = 0

	self.m_cost1Type = {}
	self.m_cost1Params = {}
	self.m_effec1Type = 0
	self.m_effect1Parms = {}
	self.m_tar1NumLevel_lua = {}
	self.m_tar1Num_lua = {}
	self.m_tar1TargetCount = 0
	self.m_round1_level = {}
	self.m_round1 = {}

	self.m_effec2Type = 0
	self.m_effect2Parms = {}
	self.m_tar2NumLevel_lua = {}
	self.m_tar2Num_lua = {}
	self.m_round2_level = {}
	self.m_round2 = {}

	self.m_addAnger = 0
	self.m_baoji = 0
	self.m_desc = 0
	self.m_roleCreatDesc = 0
end

LSkillConsumeData = {}
LSkillConsumeData.__index = LSkillConsumeData
function LSkillConsumeData:New()
	local o = {}
	setmetatable(o,LSkillConsumeData)	
	o:ctor()
	return o
end

function LSkillConsumeData:ctor()
	self.m_byLv = 0
	self.m_iConsume1 = 0
	self.m_iConsume2 = 0
	self.m_iConsume3 = 0
	self.m_iConsume4 = 0
end


LLifeSkillData = {}
LLifeSkillData.__index = LLifeSkillData
function LLifeSkillData:New()
	local o = {}
	setmetatable(o,LLifeSkillData)	
	o:ctor()
	return o
end

function LLifeSkillData:ctor()
	self.m_id = 0
	self.m_skillname = 0
	self.m_desc = 0
	self.m_ruleDesc = 0
	self.m_typedesc = 0
	self.m_icon = 0
	self.m_itemid = nil
	self.m_limitLevel = nil
	self.m_pcostMoney = nil
	self.m_pcostHuoli = nil
	self.m_limitMaxLevel = nil
	self.m_itemCount = 0
end

--[[
lua里面的游戏逻辑控制
]]

LSkillManager = LDataBase:New()
LSkillManager.__index = LSkillManager
function LSkillManager:New()
	local o = LUIBase:New()
	setmetatable(o,LSkillManager)	
	o:Awake()
	return o
end

function LSkillManager:Awake()
	self.m_bIsLoaded = false
	self.m_pSkillsDict = {}
	self.m_pPetSkillsDict = {}
	self.m_pSkillConsumesDict = {}
	self.m_pLifeSkilDict = {}
	self.m_pLifeSkillConseumDict = {}
end

function LSkillManager:Instance()
	if self.m_bIsLoaded == false then
		self:ReadSkillData()
		self:ReadPetSkillData()
		self:ReadSkillConsumesData()
		self:ReadMakeLifeSkillData()
		self:ReadMakeLifeSkillConsumeData()
		self.m_bIsLoaded = true
	end
	return self
end

--[[
获取对应技能id的技能数据
]]
function LSkillManager:GetSkillData(id)
	return self.m_pSkillsDict[id]
end

--[[
获取对应技能id的技能数据
]]
function LSkillManager:GetSkillConsumeData(lv,skillId_pos)
	if skillId_pos == 1 then
		return self.m_pSkillConsumesDict[lv].m_iConsume1
	elseif  skillId_pos == 2 then
		return self.m_pSkillConsumesDict[lv].m_iConsume2
	elseif  skillId_pos == 3 then
		return self.m_pSkillConsumesDict[lv].m_iConsume3
	elseif  skillId_pos == 4 then
		return self.m_pSkillConsumesDict[lv].m_iConsume4
	end
	return self.m_pSkillConsumesDict[lv].m_iConsume1
end

--[[
获取技能攻击目标个数
]]
function LSkillManager:GetSkillTargetNum(id,level)
	local skilltable = self.m_pSkillsDict[tonumber(id)]
	local number = 0
	for i=1,skilltable.m_tar1TargetCount do
		if level >= skilltable.m_tar1NumLevel_lua[i] then
			number = skilltable.m_tar1Num_lua[i]
		end
	end
	return number
end

function LSkillManager:ReadSkillData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/skill.xml")
		-- body
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	for i = 1, #rec do
		local v = rec[i]
		local skilldata = LSkilltableData:New()
		skilldata.m_wId = tonumber(v["@id"])
		skilldata.m_strName = tonumber(v["@nameid"])
		skilldata.m_icon = tonumber(v["@icon"])
		skilldata.m_iType = tonumber(v["@type"])
		skilldata.m_fictionId = tonumber(v["@fiction_id"])
		skilldata.m_levelupDes = tonumber(v["@levelup_des"])
		skilldata.m_byUseType = tonumber(v["@use_type"])
		skilldata.m_targetType = tonumber(v["@tar_type"])

		local cost1TypeList = string.split(v["@cost1_type"], "|")
		skilldata.m_cost1Type = {}
		for i=1,#cost1TypeList do
			skilldata.m_cost1Type[i] = tonumber(cost1TypeList[i])
		end
		local cost1ParamList = string.split(v["@cost1_param"], "|")
		skilldata.m_cost1Params = {}
		local index = 1
		for i=1,#cost1ParamList do
			local temp = string.split(cost1ParamList[i],"-")
			for j=1,#temp do
				skilldata.m_cost1Params[index] = tonumber(temp[j])
				index = index + 1
			end
		end
		skilldata.m_effec1Type = tonumber(v["@effect1_type"])
		if skilldata.m_effec1Type ~= 0 then
			local effect1_paramList = string.split(v["@effect1_param"],"-")
			skilldata.m_effect1Parms = {}
			for i=1,#effect1_paramList do
				skilldata.m_effect1Parms[i] = tonumber(effect1_paramList[i])
			end
			local tar1_numList = string.split(v["@tar1_num"],"|")
			skilldata.m_tar1NumLevel_lua = {}
			skilldata.m_tar1Num_lua = {}
			skilldata.m_tar1TargetCount = #tar1_numList
			for i=1,#tar1_numList do
				local temp = string.split(tar1_numList[i], "-")
				skilldata.m_tar1NumLevel_lua[i] = tonumber(temp[1])
				skilldata.m_tar1Num_lua[i] = tonumber(temp[2])
			end

			local round1List = string.split(v["@round1"],"|")
			skilldata.m_round1_level = {}
			skilldata.m_round1 = {}
			for i=1,#round1List do
				local temp = string.split(round1List[i], "-")
				skilldata.m_round1_level[i] = tonumber(temp[1])
				skilldata.m_round1[i] = tonumber(temp[2])
			end
		end

		skilldata.m_effec2Type = tonumber(v["@effect2_type"])
		if skilldata.m_effec2Type ~= 0 then
			local effect2_paramList = string.split(v["@effect2_param"],"-")
			skilldata.m_effect2Parms = {}
			for i=1,#effect2_paramList do
				skilldata.m_effect2Parms[i] = tonumber(effect2_paramList[i])
			end
			local tar2_numList = string.split(v["@tar2_num"],"|")
			skilldata.m_tar2NumLevel_lua = {}
			skilldata.m_tar2Num_lua = {}
			for i=1,#tar2_numList do
				local temp = string.split(tar2_numList[i], "-")
				skilldata.m_tar2NumLevel_lua[i] = tonumber(temp[1])
				skilldata.m_tar2Num_lua[i] = tonumber(temp[2])
			end

			local round2List = string.split(v["@round2"],"|")
			skilldata.m_round2_level = {}
			skilldata.m_round2 = {}
			for i=1,#round2List do
				local temp = string.split(round2List[i], "-")
				skilldata.m_round2_level[i] = tonumber(temp[1])
				skilldata.m_round2[i] = tonumber(temp[2])
			end
		end
		skilldata.m_addAnger = tonumber(v["@add_anger"])
		skilldata.m_baoji = tonumber(v["@baoji"])
		skilldata.m_desc = tonumber(v["@describeid"])
		skilldata.m_roleCreatDesc = tonumber(v["@des"])
		self.m_pSkillsDict[skilldata.m_wId] = skilldata
	end
end

function LSkillManager:ReadSkillConsumesData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/skill_consume.xml")
		-- body
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	for i = 1, #rec do
		local v = rec[i]
		local skillConsumeData = LSkillConsumeData:New()
		skillConsumeData.m_byLv = tonumber(v["@id"])
		skillConsumeData.m_iConsume1 = tonumber(v["@consume1"])
		skillConsumeData.m_iConsume2 = tonumber(v["@consume2"])
		skillConsumeData.m_iConsume3 = tonumber(v["@consume3"])
		skillConsumeData.m_iConsume4 = tonumber(v["@consume4"])
		self.m_pSkillConsumesDict[skillConsumeData.m_byLv] = skillConsumeData
	end
end

--[[
获取所有生活技能
]]
function LSkillManager:GetAllLifeSkillData()
	return self.m_pLifeSkilDict
end

--[[
获取生活技能数据：type和index是一样的，所以可以直接调用
]]
function LSkillManager:GetLifeSkillData(id)
	return self.m_pLifeSkilDict[id]
end

--[[
生活技能
]]
function LSkillManager:ReadMakeLifeSkillData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/makeitem.xml")
		-- body
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	for i = 1, #rec do
		local v = rec[i]
		local lifetype = tonumber(v["@type"])
		if self.m_pLifeSkilDict[lifetype] == nil then
			local lifeSkillData = LLifeSkillData:New()
			lifeSkillData.m_id = tonumber(v["@type"])
			lifeSkillData.m_skillname = tonumber(v["@name"])
			lifeSkillData.m_desc = tonumber(v["@describe"])
			lifeSkillData.m_ruleDesc = tonumber(v["@rule"])
			lifeSkillData.m_typedesc = tonumber(v["@effect"])
			lifeSkillData.m_icon = tonumber(v["@icon"])
			lifeSkillData.m_itemid = {}
			lifeSkillData.m_limitLevel = {}
			lifeSkillData.m_pcostMoney = {}
			lifeSkillData.m_pcostHuoli = {}
			lifeSkillData.m_limitMaxLevel = {}
			lifeSkillData.m_itemCount = 0
			self.m_pLifeSkilDict[lifeSkillData.m_id] = lifeSkillData
		end
		local lifedata = self.m_pLifeSkilDict[lifetype]
		lifedata.m_itemCount = lifedata.m_itemCount + 1
		lifedata.m_itemid[lifedata.m_itemCount] = tonumber(v["@item"])
		lifedata.m_limitLevel[lifedata.m_itemCount] = tonumber(v["@level"])
		lifedata.m_limitMaxLevel[lifedata.m_itemCount] = tonumber(v["@maxlevel"])
		lifedata.m_pcostMoney[lifedata.m_itemCount] = tonumber(v["@cost_money"])
		lifedata.m_pcostHuoli[lifedata.m_itemCount] = tonumber(v["@cost_vitality"])
		
	end
end

function LSkillManager:GetLifeSkillLevelData(id)
	return self.m_pLifeSkillConseumDict[id]
end

function LSkillManager:GetLifeSkillMaxLevel(id)
	return self.m_pLifeSkillConseumDict[id].m_levelcostMoney
end
--[[
生活技能消耗
]]
function LSkillManager:ReadMakeLifeSkillConsumeData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/live_skill.xml")
		-- body
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	for i = 1, #rec do
		local v = rec[i]
		local lifetype = tonumber(v["@type"])
		if self.m_pLifeSkillConseumDict[lifetype] == nil then
			local tabletemp = {}
			tabletemp.m_levelcostMoney = {}
			tabletemp.m_maxLevel = 0
			self.m_pLifeSkillConseumDict[lifetype] = tabletemp
		end
		local level = tonumber(v["@level"])
		self.m_pLifeSkillConseumDict[lifetype].m_levelcostMoney[level] = tonumber(v["@cost_upgrade"])
		if self.m_pLifeSkillConseumDict[lifetype].m_maxLevel >= level then
			self.m_pLifeSkillConseumDict[lifetype].m_maxLevel = level
		end
	end
end

--[[
宠物技能数据
]]
function LSkillManager:ReadPetSkillData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/pet_skill.xml")
		-- body
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	for i = 1, #rec do
		local v = rec[i]
		local skilldata = LSkilltableData:New()
		skilldata.m_wId = tonumber(v["@id"])
		skilldata.m_strName = tonumber(v["@nameid"])
		skilldata.m_icon = tonumber(v["@icon"])
		skilldata.m_iType = tonumber(v["@type"])
		skilldata.m_fictionId = tonumber(v["@fiction_id"])
		skilldata.m_levelupDes = tonumber(v["@levelup_des"])
		skilldata.m_desc = tonumber(v["@describeid"])
		skilldata.m_targetType = tonumber(v["@tar_type"])
		skilldata.m_byUseType = tonumber(v["@use_type"])
		skilldata.m_forgetCostItemID = 3
		skilldata.m_forgetCostItemNum = tonumber(v["@forget"])

		local cost1TypeList = string.split(v["@cost1_type"], "|")
		skilldata.m_cost1Type = {}
		for i=1,#cost1TypeList do
			skilldata.m_cost1Type[i] = tonumber(cost1TypeList[i])
		end
		local cost1ParamList = string.split(v["@cost1_param"], "|")
		skilldata.m_cost1Params = {}
		local index = 1
		for i=1,#cost1ParamList do
			local temp = string.split(cost1ParamList[i],"-")
			for j=1,#temp do
				skilldata.m_cost1Params[index] = tonumber(temp[j])
				index = index + 1
			end
		end
		self.m_pPetSkillsDict[skilldata.m_wId] = skilldata
	end
end

--[[
获取宠物技能数据
]]
function LSkillManager:GetSkillPetData(id)
	return  self.m_pPetSkillsDict[id]
end

--[[获取技能描述]]
function  LSkillManager:GetSkillDesc(skill)
    local DesStrs = self:GetSkillDescData(skill)
    return LTipsManager:Instance():GetSkillTips(skill.m_skilltable.m_desc,DesStrs)
end

--根据传进来的技能决定描述。
function LSkillManager:GetSkillDescData(skill)
	--  /*
    -- @功能：获取提示文字
    -- {%}--程序添值
    -- 1基础伤害{%1}
    -- 2暴击率{%2}
    -- 3几个回合{%3}
    -- 4降低怒气{%4}
    -- 5恢复气血{%5}
    -- 6.降低速度{%6}
    -- 7.几个单位{%7}
    -- */
    function GetSkillCount1Str()
    	 -- 7.几个单位{%7}
    	local count = 1
	    if #skill.m_skilltable.m_tar1NumLevel_lua >1 then
	    	for i=1,#skill.m_skilltable.m_tar1NumLevel_lua do
	    		if  skill.m_skillLevel >= skill.m_skilltable.m_tar1NumLevel_lua[i] then
	    			count = skill.m_skilltable.m_tar1Num_lua[i]
	    		end
	    	end
	    end
	    --print("skill =" ..skill.m_skilltable.m_wId.. "   countcountcountcount == == = "..count)
	    return "{%%7}+"..count
    end

    function GetSkillRound1Str()
    	-- 3几个回合{%3}
    	local round = 1
	    if  #skill.m_skilltable.m_round1_level >=1 then
	    	for i=1,#skill.m_skilltable.m_round1_level do
	    		if  skill.m_skillLevel >= skill.m_skilltable.m_round1_level[i] then
	    			round = skill.m_skilltable.m_round1[i]
	    		end
	    	end
	    end
	    return "{%%3}+"..round
    end
    --第二个效果
    function GetSkillCount2Str()
    	 -- 7.几个单位{%7}
    	local count = 1
	    if   #skill.m_skilltable.m_round2_level >1 then
	    	for i=1,#skill.m_skilltable.m_round2_level do
	    		if  skill.m_skillLevel >= skill.m_skilltable.m_round2_level[i] then
	    			count = skill.m_skilltable.m_round2[i]
	    		end
	    	end
	    end
	    return "{%%7}+"..count
    end

    function GetSkillRound2Str()
    	-- 3几个回合{%3}
    	local round = 1
	    if   #skill.m_skilltable.m_tar2NumLevel_lua >1 then
	    	for i=1,#skill.m_skilltable.m_tar2NumLevel_lua  do
	    		if  skill.m_skillLevel >= skill.m_skilltable.m_round2_level[i] then
	    				round = skill.m_skilltable.m_round2[i]
	    		end
	    	end
	    end
	    return "{%%3}+"..round
    end

    function GetSkillBaojiStr()
    	  -- 2暴击率{%2}
	    return "{%%2}+"..skill.m_skilltable.m_baoji .. "%%"
    end


    local DesStrs = {}
    local DesStrsCount = 0
    -- 技能1
    if skill.m_skilltable.m_effec1Type == 1 or skill.m_skilltable.m_effec1Type == 2 then
    	--1基础伤害{%1}
    	local num = (((skill.m_skilltable.m_effect1Parms[1]*skill.m_skillLevel) + skill.m_skilltable.m_effect1Parms[2])/100)
    	local str = string.format("%0.1f", num)
    	DesStrs[1] = "{%%1}+"..str  .. "%%"
    	DesStrs[2] = GetSkillCount1Str()
    	DesStrs[3] = GetSkillRound1Str()
    	DesStrsCount = 3
    elseif skill.m_skilltable.m_effec1Type == 3 or skill.m_skilltable.m_effec1Type == 4 or skill.m_skilltable.m_effec1Type == 5 then
    	--命中率暂时不显示
    	DesStrs[1] = GetSkillCount1Str()
    	DesStrs[2] = GetSkillRound1Str()
    	DesStrsCount = 2
    elseif skill.m_skilltable.m_effec1Type == 6 or skill.m_skilltable.m_effec1Type == 15 or skill.m_skilltable.m_effec1Type == 14 then
    	--恢复气血{%5}
    	local num = (((skill.m_skilltable.m_effect1Parms[1]*skill.m_skillLevel) + skill.m_skilltable.m_effect1Parms[2])/10000)
    	local str = string.format("%0.1f", num)
    	DesStrs[1] = "{%%5}+"..str
    	DesStrs[2] = GetSkillCount1Str()
    	DesStrs[3] = GetSkillRound1Str()
    	DesStrsCount = 3
    	if skill.m_skilltable.m_wId == 16 or skill.m_skilltable.m_wId == 20 then
    		local num = (((skill.m_skilltable.m_effect1Parms[1]*skill.m_skillLevel) + skill.m_skilltable.m_effect1Parms[2])/100)
    		local str = string.format("%0.1f", num)
    		DesStrs[1] = "{%%5}+"..str .. "%%" --特殊技能写死
    	end
    elseif skill.m_skilltable.m_effec1Type == 7 or skill.m_skilltable.m_effec1Type == 8 then
    	--降防或者加攻
    	local num = (((skill.m_skilltable.m_effect1Parms[1]*skill.m_skillLevel) + skill.m_skilltable.m_effect1Parms[2])/100)
    	local str = string.format("%0.1f", num)
    	DesStrs[1] = "{%%}+"..str.. "%%"
    	DesStrs[2] = GetSkillCount1Str()
    	DesStrs[3] = GetSkillRound1Str()
    	DesStrsCount = 3
    elseif  skill.m_skilltable.m_effec1Type == 11  then
    	--不加怒气概率{%8}
    	local num = (((skill.m_skilltable.m_effect1Parms[1]*skill.m_skillLevel) + skill.m_skilltable.m_effect1Parms[2])/100)
    	local str = string.format("%0.1f", num)
    	DesStrs[1] = "{%%8}+"..str "%%"
    	DesStrs[2] = GetSkillCount1Str()
    	DesStrs[3] = GetSkillRound1Str()
    	DesStrsCount = 3
    elseif skill.m_skilltable.m_effec1Type == 12 then
    	--降怒气值{%4}
    	local num = (((skill.m_skilltable.m_effect1Parms[1]*skill.m_skillLevel) + skill.m_skilltable.m_effect1Parms[2])/10000)
    	local str = string.format("%0.1f", num)
    	DesStrs[1] = "{%%4}+"..str
    	DesStrs[2] = GetSkillCount1Str()
    	DesStrs[3] = GetSkillRound1Str()
    	DesStrsCount = 3
    elseif skill.m_skilltable.m_effec1Type == 13 then
    	--回怒速度{%6}
    	local num = (((skill.m_skilltable.m_effect1Parms[1]*skill.m_skillLevel) + skill.m_skilltable.m_effect1Parms[2])/100)
    	local str = string.format("%0.1f", num)
    	DesStrs[1] = "{%%6}+"..str .. "%%"
    	DesStrs[2] = GetSkillCount1Str()
    	DesStrs[3] = GetSkillRound1Str()
    	DesStrsCount = 3
    elseif skill.m_skilltable.m_effec1Type == 17 then
    	--固定加血加魔
    	--恢复气血{%5}
    	local num = (((skill.m_skilltable.m_effect1Parms[1]*skill.m_skillLevel) + skill.m_skilltable.m_effect1Parms[2])/10000)
    	local str = string.format("%0.1f", num)
    	DesStrs[1] = "{%%5}+"..str
    	DesStrs[2] = GetSkillCount1Str()
    	DesStrs[3] = GetSkillRound1Str()
    	DesStrsCount = 3
     elseif skill.m_skilltable.m_effec1Type == 18 then
    	--百分比回血回魔
    	--恢复气血{%5}
    	local num = (((skill.m_skilltable.m_effect1Parms[1]*skill.m_skillLevel) + skill.m_skilltable.m_effect1Parms[2])/10000)
    	local str = string.format("%0.1f", num)
    	DesStrs[1] = "{%%5}+"..str .. "%%"
    	DesStrs[2] = GetSkillCount1Str()
    	DesStrs[3] = GetSkillRound1Str()
    	DesStrsCount = 3
    elseif skill.m_skilltable.m_effec1Type == 19 or skill.m_skilltable.m_effec1Type == 9 then
    	--复活
    	DesStrs[1] = GetSkillCount1Str()
    	DesStrs[2] = GetSkillRound1Str()
    	DesStrsCount = 2
    end


    -- 效果2
    if skill.m_skilltable.m_effec2Type == 1 or skill.m_skilltable.m_effec2Type == 2 then
    	--1基础伤害{%1}
    	local num = (((skill.m_skilltable.m_effect2Parms[1]*skill.m_skillLevel) + skill.m_skilltable.m_effect2Parms[2])/100)
    	local str = string.format("%0.1f", num)
    	DesStrsCount = DesStrsCount+ 1
    	DesStrs[DesStrsCount] = "{%%1}+".. str .."%%"
    elseif skill.m_skilltable.m_effec2Type == 3  or skill.m_skilltable.m_effec2Type == 4 or skill.m_skilltable.m_effec2Type == 5 then
    	--命中率暂时不显示
    	DesStrs[DesStrsCount + 1] = GetSkillCount1Str()
    	DesStrs[DesStrsCount + 2] = GetSkillRound1Str()
    	DesStrsCount = DesStrsCount+ 2
    elseif skill.m_skilltable.m_effec2Type == 6 then
    	--恢复气血{%5}
    	local num = (((skill.m_skilltable.m_effect2Parms[1]*skill.m_skillLevel) + skill.m_skilltable.m_effect2Parms[2])/10000)
    	local str = string.format("%0.1f", num)
    	DesStrsCount = DesStrsCount+ 1
    	DesStrs[DesStrsCount] = "{%%5}+"..str
    elseif skill.m_skilltable.m_effec2Type == 7 or skill.m_skilltable.m_effec2Type == 8 then
    	--降防或者加攻
    	local num = (((skill.m_skilltable.m_effect2Parms[1]*skill.m_skillLevel) + skill.m_skilltable.m_effect2Parms[2])/100)
    	local str = string.format("%0.1f", num)
    	DesStrs[1] = "{%%}+"..str.."%%"
    	DesStrs[2] = GetSkillCount1Str()
    	DesStrs[3] = GetSkillRound1Str()
    	DesStrsCount = 3
    elseif skill.m_skilltable.m_effec2Type == 11 then
    	--不加怒气概率{%8}
    	local num = (((skill.m_skilltable.m_effect2Parms[1]*skill.m_skillLevel) + skill.m_skilltable.m_effect2Parms[2])/100)
    	local str = string.format("%0.1f", num)
    	DesStrsCount = DesStrsCount+ 1
    	DesStrs[DesStrsCount] = "{%%8}+"..str .. "%%"
    elseif skill.m_skilltable.m_effec2Type == 12 then
    	--降怒气值{%4}
    	local num = (((skill.m_skilltable.m_effect2Parms[1]*skill.m_skillLevel) + skill.m_skilltable.m_effect2Parms[2])/10000)
    	local str = string.format("%0.1f", num)
    	DesStrsCount = DesStrsCount+ 1
    	DesStrs[DesStrsCount] = "{%%4}+"..str
    elseif skill.m_skilltable.m_effec2Type == 13 then
    	--回怒速度{%6}
    	local num = (((skill.m_skilltable.m_effect2Parms[1]*skill.m_skillLevel) + skill.m_skilltable.m_effect2Parms[2])/100)
    	local str = string.format("%0.1f", num)
    	DesStrsCount = DesStrsCount+ 1
    	DesStrs[DesStrsCount] = "{%%6}+"..str .. "%%"
    elseif skill.m_skilltable.m_effec2Type == 17 then
    	--固定加血加魔
    	--恢复气血{%5}
    	local num = (((skill.m_skilltable.m_effect1Parms[1]*skill.m_skillLevel) + skill.m_skilltable.m_effect1Parms[2])/10000)
    	local str = string.format("%0.1f", num)
    	DesStrs[1] = "{%%5}+"..str
    	DesStrs[2] = GetSkillCount1Str()
    	DesStrs[3] = GetSkillRound1Str()
    	DesStrsCount = 3
     elseif skill.m_skilltable.m_effec2Type == 18 then
    	--百分比回血回魔
    	--恢复气血{%5}
    	local num = (((skill.m_skilltable.m_effect1Parms[1]*skill.m_skillLevel) + skill.m_skilltable.m_effect1Parms[2])/10000)
    	local str = string.format("%0.1f", num)
    	DesStrs[1] = "{%%5}+"..str .. "%%" 
    	DesStrs[2] = GetSkillCount1Str()
    	DesStrs[3] = GetSkillRound1Str()
    	DesStrsCount = 3
    elseif skill.m_skilltable.m_effec2Type == 19 or skill.m_skilltable.m_effec2Type == 9 then
    	--复活
    	DesStrs[1] = GetSkillCount1Str()
    	DesStrs[2] = GetSkillRound1Str()
    	DesStrsCount = 2
    end
    --暴击
    if skill.m_skilltable.m_baoji > 0 then
    	DesStrsCount = DesStrsCount+ 1
    	DesStrs[DesStrsCount] = GetSkillBaojiStr()
    end

    return DesStrs
end

return LSkillManager:Awake()