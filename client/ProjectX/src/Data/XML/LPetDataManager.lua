--[[
lua里面的游戏逻辑控制
]]
LPetDataManager = LDataBase:New()
LPetDataManager.__index = LPetDataManager
function LPetDataManager:New()
	local o = LUIBase:New()
	setmetatable(o,LPetDataManager)	
	o:Awake()
	return o
end

function LPetDataManager:Awake()
	self.m_bIsLoaded = false
	self.m_pPetBuff = {}
	self.m_petIndexBuff = {}
	self.m_pPetSkillBook = {}
	self.m_pPetExpBuff = {}
	self.m_pPetXiuLianExpBuff = {}
	self.m_pPetSkillGrid = {}
	self.m_pKangXingBuff = {}
	self.m_petOpenGridMatrialID = nil
	self.m_petOpenGridMatrialNum = nil
	self.m_petTableCount = 0
end

function LPetDataManager:Instance()
	if self.m_bIsLoaded == false then
		self:ReadPetData()
		self:ReadPetSkillBookData()
		self:ReadPetExpData()
		self:ReadPetXiuLianExpData()
		self:ReadPetSkillGridData()
		self:ReadPetKangXingData()
		self.m_bIsLoaded = true
	end
	return self
end

--[[
宠物数据
]]
function LPetDataManager:ReadPetData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/pet.xml")
		-- body
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	for i = 1, #rec do
		local v = rec[i]
		local PetData = {}
		PetData.m_iId = tonumber(v["@id"])
		PetData.m_iNameId = tonumber(v["@nameid"])
		PetData.m_byType = tonumber(v["@type"])
		PetData.m_iSkills = tonumber(v["@tianji"])
		local tmpcarrylevel = string.split(v["@carrylevel"],"-")
		PetData.m_byZhuanSheng = tonumber(tmpcarrylevel[1])
		PetData.m_byLv = tonumber(tmpcarrylevel[2])
		PetData.m_iModelId = tonumber(v["@model"])
		PetData.m_iIcon = tonumber(v["@icon"])
		PetData.m_fMinGrowthRate = tonumber(v["@growth_low"])
		PetData.m_fMaxGrowthRate = tonumber(v["@growth_high"])

		PetData.m_fMinInitHp = tonumber(v["@hp_low"])
		PetData.m_fMinInitMp = tonumber(v["@mp_low"])
		PetData.m_fMinInitWuGong = tonumber(v["@wugong_low"])
		PetData.m_fMinInitFaGong = tonumber(v["@fagong_low"])
		PetData.m_fMinInitSpeed = tonumber(v["@speed_low"])

		PetData.m_fMaxInitHp = tonumber(v["@hp_high"])
		PetData.m_fMaxInitMp = tonumber(v["@mp_high"])
		PetData.m_fMaxInitWuGong = tonumber(v["@wugong_high"])
		PetData.m_fMaxInitFaGong = tonumber(v["@fagong_high"])
		PetData.m_fMaxInitSpeed = tonumber(v["@speed_high"])
		PetData.m_quanZhong = tonumber(v["@quanzhong"])

		local xiLianPingFenList = string.split(v["@gradelevel"],"|")
		PetData.m_fXiLianPingFen = {}
		for i=1,#xiLianPingFenList do
			PetData.m_fXiLianPingFen[i-1] = tonumber(xiLianPingFenList[i])
		end
		PetData.m_fWuXing = {}
		for i=0,4 do
			PetData.m_fWuXing[i] = 0
		end
		local wuXingList = string.split(v["@wuxing"],"|")
		for i=1,#wuXingList do
			local tempWuxing = string.split(wuXingList[i],"-")
			PetData.m_fWuXing[tonumber(tempWuxing[1])] = tonumber(tempWuxing[2])
		end
		PetData.m_desc = tonumber(v["@describeid"])
		PetData.m_isCanHeCheng = false
		if v["@material"] ~= "0" then
			local materialList = string.split(v["@material"],"|")
			PetData.m_materialNum = #materialList
			PetData.m_hechengItemID = {}
			PetData.m_hechengItemNum = {}
			for i=1,#materialList do
				local materialtemp = string.split(materialList[i],"-")
				PetData.m_hechengItemID[i] = tonumber(materialtemp[1])
				PetData.m_hechengItemNum[i] = tonumber(materialtemp[2])
				PetData.m_isCanHeCheng = true
			end
		end
		if v["@catch"] ~= "0" then
			local catchList = string.split(v["@catch"],"|") 
			if #catchList == 3 then
				PetData.isCanCatch = true
				PetData.m_mapid = tonumber(catchList[1])
				PetData.m_bornx = tonumber(catchList[2])
				PetData.m_bornz = tonumber(catchList[3])
			else
				PetData.isCanCatch = false
			end
		end
		self.m_pPetBuff[PetData.m_iId] = PetData
		table.insert(self.m_petIndexBuff,PetData)
	end
end

--[[
宠物技能书对应宠物技能
]]
function LPetDataManager:ReadPetSkillBookData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/petskill.xml")
		-- body
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	for i = 1, #rec do
		local v = rec[i]
		local PetSkillBookData = {}
		PetSkillBookData.m_skillBookId = tonumber(v["@id"])
		PetSkillBookData.m_petSkillId = tonumber(v["@skillid"])
		self.m_pPetSkillBook[PetSkillBookData.m_skillBookId] = PetSkillBookData
	end
end

--[[
读取宠物经验数据
]]
function LPetDataManager:ReadPetExpData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/pet_exp.xml")
		-- body
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	for i = 1, #rec do
		local v = rec[i]
		local PetExp = {}
		PetExp.m_Level = tonumber(v["@lv"])
		PetExp.m_exp = {}
		PetExp.m_exp[0] = tonumber(v["@exp"])
		PetExp.m_exp[1] = tonumber(v["@exp1"])
		PetExp.m_exp[2] = tonumber(v["@exp2"])
		PetExp.m_exp[3] = tonumber(v["@exp3"])
		self.m_pPetExpBuff[PetExp.m_Level] = PetExp
	end
end

--[[
初始化宠物经验数据
]]
function LPetDataManager:ReadPetXiuLianExpData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/pet_practice.xml")
		-- body
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	for i = 1, #rec do
		local v = rec[i]
		local PetXiuLianExp = {}
		PetXiuLianExp.m_Level = tonumber(v["@level_id"])
		PetXiuLianExp.m_exp = tonumber(v["@exp"])
		self.m_pPetXiuLianExpBuff[PetXiuLianExp.m_Level] = PetXiuLianExp
	end
end

--[[
初始化宠物技能格子
]]
function LPetDataManager:ReadPetSkillGridData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/skill_open.xml")
		-- body
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	for i = 1, #rec do
		local v = rec[i]
		local PetSkillGrid = {}
		PetSkillGrid.m_index = tonumber(v["@id"])
		PetSkillGrid.m_type = tonumber(v["@type"])
		local costList = string.split(v["@open_cost"],"|")
		PetSkillGrid.m_costItemId = tonumber(costList[1])
		PetSkillGrid.m_costItemNum = tonumber(costList[2])
		self.m_pPetSkillGrid[PetSkillGrid.m_index] = PetSkillGrid
	end
end

--[[
初始化宠物抗性信息
]]
function LPetDataManager:ReadPetKangXingData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/practice_change.xml")
		-- body
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	for i = 1, #rec do
		local v = rec[i]
		local PetKangXing = {}
		PetKangXing.m_attributeID = tonumber(v["@shuxing_id"])
		PetKangXing.m_attributeToValue = tonumber(v["@proportion"])
		PetKangXing.m_MaxAttributePoint = {}
		PetKangXing.m_MaxAttributePoint[0] = tonumber(v["@max0"])
		PetKangXing.m_MaxAttributePoint[1] = tonumber(v["@max1"])
		PetKangXing.m_MaxAttributePoint[2] = tonumber(v["@max2"])
		PetKangXing.m_MaxAttributePoint[3] = tonumber(v["@max3"])
		self.m_pKangXingBuff[PetKangXing.m_attributeID] = PetKangXing
	end
end

--[[
获取宠物数据
]]
function LPetDataManager:GetPetData(id)
	return self.m_pPetBuff[id]
end

--[[
获取宠物数据
]]
function LPetDataManager:GetPetIndexData(index)
	return self.m_petIndexBuff[index]
end

function LPetDataManager:GetPetCount()
	return #self.m_petIndexBuff
end

--[[
获取宠物技能书对应宠物技能
]]
function LPetDataManager:GetPetSkillBookToID(bookid)
	return self.m_pPetSkillBook[bookid].m_petSkillId
end

--[[
获取宠物等级对应经验数据
]]
function LPetDataManager:GetPetExpData(level)
	return self.m_pPetExpBuff[level]
end

--[[
获取宠物修炼经验数据
]]
function LPetDataManager:GetPetXiuLianExpData(level)
	return self.m_pPetXiuLianExpBuff[level]
end

--[[
获取抗性数据
]]
function LPetDataManager:GetKangXing(id)
	return self.m_pKangXingBuff[id]
end

--[[
获取解析宠物格子道具id
]]
function LPetDataManager:GetItemIdPetGrid(index)
	if self.m_petOpenGridMatrialID == nil then
		self.m_petOpenGridMatrialID = {}
		local str = LGlobalparameterManager:Instance():GetGlobalParameterString("pet_xiedai")
		local strarray = string.split(str,"|")
		for i=1,#strarray do
			local temp = string.split(strarray[i],"-")
			self.m_petOpenGridMatrialID[i-1] = temp[1]
		end
	end
	return self.m_petOpenGridMatrialID[index]
end

--[[
获取解析宠物格子道具id
]]
function LPetDataManager:GetItemNumPetGrid(index)
	if self.m_petOpenGridMatrialNum == nil then
		self.m_petOpenGridMatrialNum = {}
		local str = LGlobalparameterManager:Instance():GetGlobalParameterString("pet_xiedai")
		local strarray = string.split(str,"|")
		for i=1,#strarray do
			local temp = string.split(strarray[i],"-")
			self.m_petOpenGridMatrialNum[i-1] = temp[2]
		end
	end
	return self.m_petOpenGridMatrialNum[index]
end

function LPetDataManager:GetItemIdPetSkillGrid(index)
	return self.m_pPetSkillGrid[index].m_costItemId
end

function LPetDataManager:GetItemNumPetSkillGrid(index)
	return self.m_pPetSkillGrid[index].m_costItemNum
end

--[[
获取宠物技能描述
 21、倍道兼行 增加速度=100+亲密度*0.001 
 22、天生神力 增加数值=1000+亲密度*0.01 
 23、神工鬼力 增加数值=500+亲密度*0.005 
 24、帐饮东都 增加数值=2000+亲密度*0.05 
 25、魔力冲天 增加数值=2000+亲密度*0.05

32 大隐于朝 增加速度=100+亲密度*0.001
33 神出鬼没 增加数值=2000+亲密度*0.05
34 匿影藏形 增加数值=1000+亲密度*0.01
35 销声敛迹 增加数值=500+亲密度*0.005
]]
function LPetDataManager:GetPetSkillDesc(skillid,qinmidu)
	if skillid == 21 then
		local valuelist = {}
		valuelist[1] = tostring(100 + qinmidu * 0.001)
		valuelist[1] = string.format("%d", valuelist[1])
		return LTipsManager:Instance():GetTipsGsub(3301,valuelist)
	end
	if skillid == 22 then
		local valuelist = {}
		valuelist[1] = tostring(1000 + qinmidu * 0.01)
		valuelist[1] = string.format("%d", valuelist[1])
		return LTipsManager:Instance():GetTipsGsub(3302,valuelist)
	end
	if skillid == 23 then
		local valuelist = {}
		valuelist[1] = tostring(500 + qinmidu * 0.005)
		valuelist[1] = string.format("%d", valuelist[1])
		return LTipsManager:Instance():GetTipsGsub(3303,valuelist)
	end
	if skillid == 24 then
		local valuelist = {}
		valuelist[1] = tostring(2000 + qinmidu * 0.05)
		valuelist[1] = string.format("%d", valuelist[1])
		return LTipsManager:Instance():GetTipsGsub(3304,valuelist)
	end
	if skillid == 25 then
		local valuelist = {}
		valuelist[1] = tostring(2000 + qinmidu * 0.05)
		valuelist[1] = string.format("%d", valuelist[1])
		return LTipsManager:Instance():GetTipsGsub(3305,valuelist)
	end
	if skillid == 32 then
		local valuelist = {}
		valuelist[1] = tostring(100 + qinmidu * 0.001)
		valuelist[1] = string.format("%d", valuelist[1])
		return LTipsManager:Instance():GetTipsGsub(3312,valuelist)
	end
	if skillid == 33 then
		local valuelist = {}
		valuelist[1] = tostring(2000 + qinmidu * 0.05)
		valuelist[1] = string.format("%d", valuelist[1])
		return LTipsManager:Instance():GetTipsGsub(3313,valuelist)
	end
	if skillid == 34 then
		local valuelist = {}
		valuelist[1] = tostring(1000 + qinmidu * 0.01)
		valuelist[1] = string.format("%d", valuelist[1])
		return LTipsManager:Instance():GetTipsGsub(3314,valuelist)
	end
	if skillid == 35 then
		local valuelist = {}
		valuelist[1] = tostring(500 + qinmidu * 0.005)
		valuelist[1] = string.format("%d", valuelist[1])
		return LTipsManager:Instance():GetTipsGsub(3315,valuelist)
	end
end

--[[
是否是增加属性的技能
]]
function LPetDataManager:IsAddAttributeSkill(skillid)
	local skillList = {[1] = 21,[2] = 22,[3] = 23,[4] = 24,[5] = 25,[6] = 32,[7] = 33,[8] = 34,[9] = 35}
	for i=1,#skillList do
		if skillList[i] == skillid then
			return true
		end
	end
	return false
end

--[[
重置拥有的宠物血量蓝量
]]
function LPetDataManager:ResetPetHpMP()
	-- local roleView = LRoleData:Instance()
	-- for i=1,roleView.m_petInfoCount do
	-- 	roleView.m_petInfoList[i-1].m_petHp = roleView.m_petInfoList[i-1].m_petMaxHp
	-- 	roleView.m_petInfoList[i-1].m_petMp = roleView.m_petInfoList[i-1].m_petMaxMp
	-- end
end

return LPetDataManager:Awake()