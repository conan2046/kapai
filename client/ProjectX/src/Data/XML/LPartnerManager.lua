--[[
lua里面的游戏逻辑控制
]]

LPartnerManager = LDataBase:New()
LPartnerManager.__index = LPartnerManager
function LPartnerManager:New()
	local o = LUIBase:New()
	setmetatable(o,LPartnerManager)	
	o:Awake()
	return o
end

function LPartnerManager:Awake()
	self.m_bIsLoaded = false
	self.m_pPartnerDataBuff = {}--伙伴表格,所有伙伴全部在里面
	self.m_pPartnerExpBuff = {}--伙伴经验表格
	self.m_pPartnerLevelAtt = {}--伙伴不同等级对应属性表格
	self.m_pPartnerYuanFen = {}--伙伴缘分数据
end


function LPartnerManager:ProcessEvent(msg)
	if msg.msgId == 0 then
	end
end

function LPartnerManager:Instance()
	if self.m_bIsLoaded == false then
		self:ReadPartnerData()
		self:ReadPartnerExpData()
		self:ReadPartnerAttributeData()
		self:ReadPartnerYuanFenData()
		self.m_bIsLoaded = true
	end
	return self
end

--[[
获取伙伴数据 根据表格中索引
]]
function LPartnerManager:GetPartnerDataByIndex(index)
	return self.m_pPartnerDataBuff[index]
end

--[[
获取伙伴数据 根据表格中id
]]
function LPartnerManager:GetPartnerDataByID(id)
	for i=1,#self.m_pPartnerDataBuff do
		if self.m_pPartnerDataBuff[i].m_iId == id then
			return self.m_pPartnerDataBuff[i]
		end
	end
	return nil
end

--[[
获取伙伴数目
]]
function LPartnerManager:GetPartnerCount()
    return #self.m_pPartnerDataBuff
end

--[[
读取数据表格中数据
]]
function LPartnerManager:ReadPartnerData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/brother.xml")
	-- body
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	self.m_pPartnerDataBuff = {}
	for i = 1, #rec do
		local v = rec[i]
		local partnerData = {}
		partnerData.m_iId = tonumber(v["@id"])
		partnerData.m_iNameId = tonumber(v["@nameid"])
		local skilltempList = string.split(v["@skillid"], "|")
		partnerData.m_iSkillCount = #skilltempList
		partnerData.m_iSkills = {}
		partnerData.m_iSkLvs = {}
		for i=1,#skilltempList do
			local temp = string.split(skilltempList[i],"-")
			partnerData.m_iSkills[i] = tonumber(temp[1])
			partnerData.m_iSkLvs[i] = tonumber(temp[2])
		end
		partnerData.m_iModelId = tonumber(v["@model"])
		partnerData.m_iIcon = tonumber(v["@icon"])
		partnerData.m_iQuality = tonumber(v["@quality"])
		partnerData.m_teChang = tonumber(v["@strong"])
		partnerData.m_desc = tonumber(v["@desc"])
		partnerData.m_callLevel = tonumber(v["@callLevel"])
		partnerData.m_teChang = tonumber(v["@strong"])
		local yuanfenList = string.split(v["@yuanfenid"], "|")
		partnerData.m_iYuanFenCount = #yuanfenList
		partnerData.m_iYuanFens = {}
		for i=1,#yuanfenList do
			partnerData.m_iYuanFens[i] = tonumber(yuanfenList[i])
		end
		--伙伴的属性
		partnerData.m_partnerHp = tonumber(v["@hp"])
		partnerData.m_partnerWuGong = tonumber(v["@wugong"])
		partnerData.m_partnerFaGong = tonumber(v["@fagong"])
		partnerData.m_partnerSpeed = tonumber(v["@speed"])
		partnerData.m_partnerKangXing = {}
		partnerData.m_partnerKangXing[0] = tonumber(v["@addkangfengyin"])
		partnerData.m_partnerKangXing[1] = tonumber(v["@addkanghunluan"])
		partnerData.m_partnerKangXing[2] = tonumber(v["@addkangshuimian"])
		partnerData.m_partnerKangXing[3] = tonumber(v["@wufang"])
		partnerData.m_partnerKangXing[4] = tonumber(v["@fafang"])

		partnerData.m_partnerKangXing[5] = tonumber(v["@adddamage"])
		partnerData.m_partnerKangXing[6] = tonumber(v["@fabao"])
		partnerData.m_partnerKangXing[7] = tonumber(v["@wubao"])
		partnerData.m_partnerKangXing[8] = tonumber(v["@ignorekangfeng"])
		partnerData.m_partnerKangXing[9] = tonumber(v["@ignorekanghun"])
		partnerData.m_partnerKangXing[10] = tonumber(v["@ignorekangshui"])
		partnerData.m_partnerKangXing[11] = tonumber(v["@zhiliao"])
		partnerData.m_partnerKangXing[12] = tonumber(v["@powerpofang"])
		partnerData.m_partnerKangXing[13] = tonumber(v["@powerhp"])
		partnerData.m_partnerKangXing[14] = tonumber(v["@powerwugong"])

		partnerData.m_partnerKangXing[15] = tonumber(v["@powerkejing5x"])
		partnerData.m_partnerKangXing[16] = tonumber(v["@powerkemu5x"])
		partnerData.m_partnerKangXing[17] = tonumber(v["@powerketu5x"])
		partnerData.m_partnerKangXing[18] = tonumber(v["@powerkehuo5x"])
		partnerData.m_partnerKangXing[19] = tonumber(v["@powerkeshui5x"])
		partnerData.m_partnerKangXing[20] = tonumber(v["@jing5xing"])
		partnerData.m_partnerKangXing[21] = tonumber(v["@mu5xing"])
		partnerData.m_partnerKangXing[22] = tonumber(v["@tu5xing"])
		partnerData.m_partnerKangXing[23] = tonumber(v["@shui5xing"])
		partnerData.m_partnerKangXing[24] = tonumber(v["@huo5xing"])

		partnerData.m_byZhongzu = tonumber(v["@vocation"])
		local callcostList = string.split(v["@cost"], "-")
		partnerData.m_costType = tonumber(callcostList[1])
		partnerData.m_costNumber = tonumber(callcostList[2])

		-- self.m_pPartnerDataBuff[partnerData.m_iId] = partnerData
		table.insert(self.m_pPartnerDataBuff,partnerData)
		--print("伙伴的数目 = "..#self.m_pPartnerDataBuff)
	end
end

--[[
读取伙伴经验数据
]]
function LPartnerManager:ReadPartnerExpData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/brother_exp.xml")
	-- body
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	self.m_pPartnerExpBuff = {}
	for i = 1, #rec do
		local v = rec[i]
		local partnerExp = {}
		partnerExp.m_Level = tonumber(v["@lv"])
		partnerExp.m_exp = {}
		partnerExp.m_exp[0] = tonumber(v["@exp"])
		partnerExp.m_exp[1] = tonumber(v["@exp1"])
		partnerExp.m_exp[2] = tonumber(v["@exp2"])
		partnerExp.m_exp[3] = tonumber(v["@exp3"])
		self.m_pPartnerExpBuff[partnerExp.m_Level] = partnerExp
	end
end

function LPartnerManager:GetPartnerExpData(level)
	return self.m_pPartnerExpBuff[level]
end

--[[
获取伙伴等级对应属性
]]
function LPartnerManager:GetPartnerLevelAttribute(id, level)
	for i=1,#self.m_pPartnerLevelAtt do
		if self.m_pPartnerLevelAtt[i].m_id == id and self.m_pPartnerLevelAtt[i].m_level == level then
			return self.m_pPartnerLevelAtt[i]
		end
	end
	return nil
end

--[[
读取伙伴经验数据
]]
function LPartnerManager:ReadPartnerAttributeData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/brothervalue.xml")
	-- body
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	self.m_pPartnerLevelAtt = {}
	for i = 1, #rec do
		local v = rec[i]
		local partnerLAtt = {}
		partnerLAtt.m_id = tonumber(v["@id"])
		partnerLAtt.m_level = tonumber(v["@level"])
		partnerLAtt.m_partnerHp = tonumber(v["@hp"])
		partnerLAtt.m_partnerWuGong = tonumber(v["@wugong"])
		partnerLAtt.m_partnerFaGong = tonumber(v["@fagong"])
		partnerLAtt.m_partnerSpeed = tonumber(v["@speed"])

		partnerLAtt.m_partnerKangXing = {}
		partnerLAtt.m_partnerKangXing[0] = tonumber(v["@addkangfengyin"])
		partnerLAtt.m_partnerKangXing[1] = tonumber(v["@addkanghunluan"])
		partnerLAtt.m_partnerKangXing[2] = tonumber(v["@addkangshuimian"])
		partnerLAtt.m_partnerKangXing[3] = tonumber(v["@wufang"])
		partnerLAtt.m_partnerKangXing[4] = tonumber(v["@fafang"])

		partnerLAtt.m_partnerKangXing[5] = tonumber(v["@adddamage"])
		partnerLAtt.m_partnerKangXing[6] = tonumber(v["@fabao"])
		partnerLAtt.m_partnerKangXing[7] = tonumber(v["@wubao"])
		partnerLAtt.m_partnerKangXing[8] = tonumber(v["@ignorekangfeng"])
		partnerLAtt.m_partnerKangXing[9] = tonumber(v["@ignorekanghun"])
		partnerLAtt.m_partnerKangXing[10] = tonumber(v["@ignorekangshui"])
		partnerLAtt.m_partnerKangXing[11] = tonumber(v["@zhiliao"])
		partnerLAtt.m_partnerKangXing[12] = tonumber(v["@powerpofang"])
		partnerLAtt.m_partnerKangXing[13] = tonumber(v["@powerhp"])
		partnerLAtt.m_partnerKangXing[14] = tonumber(v["@powerwugong"])

		partnerLAtt.m_partnerKangXing[15] = tonumber(v["@powerkejing5x"])
		partnerLAtt.m_partnerKangXing[16] = tonumber(v["@powerkemu5x"])
		partnerLAtt.m_partnerKangXing[17] = tonumber(v["@powerketu5x"])
		partnerLAtt.m_partnerKangXing[18] = tonumber(v["@powerkehuo5x"])
		partnerLAtt.m_partnerKangXing[19] = tonumber(v["@powerkeshui5x"])
		partnerLAtt.m_partnerKangXing[20] = tonumber(v["@jing5xing"])
		partnerLAtt.m_partnerKangXing[21] = tonumber(v["@mu5xing"])
		partnerLAtt.m_partnerKangXing[22] = tonumber(v["@tu5xing"])
		partnerLAtt.m_partnerKangXing[23] = tonumber(v["@shui5xing"])
		partnerLAtt.m_partnerKangXing[24] = tonumber(v["@huo5xing"])
		table.insert(self.m_pPartnerLevelAtt,partnerLAtt)
	end
end

--[[
获取伙伴缘分数据
]]
function LPartnerManager:GetPartnerYuanFenData(id)
	return self.m_pPartnerYuanFen[id]
end

--[[
读取伙伴缘分数据
]]
function LPartnerManager:ReadPartnerYuanFenData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/brotherfriend.xml")
	-- body
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	self.m_pPartnerYuanFen = {}
	for i = 1, #rec do
		local v = rec[i]
		local partnerYuanFen = {}
		partnerYuanFen.m_id = tonumber(v["@id"])
		partnerYuanFen.m_name = tonumber(v["@nameid"])
		partnerYuanFen.m_desc = tonumber(v["@descid"])
		local brotherList = string.split(v["@brotherid"], "|")
		partnerYuanFen.m_partnerNum = #brotherList
		partnerYuanFen.m_partnerID = {}
		for i=1,#brotherList do
			partnerYuanFen.m_partnerID[i] = tonumber(brotherList[i])
		end
		self.m_pPartnerYuanFen[partnerYuanFen.m_id] = partnerYuanFen
	end
end

return LPartnerManager:Awake()