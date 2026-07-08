--[[
lua里面的游戏逻辑控制
]]

LAttrDataManager = LDataBase:New()
LAttrDataManager.__index = LAttrDataManager
function LAttrDataManager:New()
	local o = LUIBase:New()
	setmetatable(o,LAttrDataManager)	
	o:Awake()
	return o
end

function LAttrDataManager:Awake()
	self.m_bIsLoaded = false
	self.m_pAttrDataBuff = {}--属性数组
	self.m_pAttrCount = 0--属性数目
end

function LAttrDataManager:Instance()
	if self.m_bIsLoaded == false then
		self:ReadAttrData()
		self.m_bIsLoaded = true
	end
	return self
end

--[[
获得属性的描述
]]
function LAttrDataManager:GetAttrDataStr(id,value)
	local xianshi = 1
	for i=0,self.m_pAttrDataBuff[id].m_iXianshi do
		if i == 0 then
			xianshi = 1
		else
			xianshi = xianshi + 1
		end
	end
	local str = ""
	if self.m_pAttrDataBuff[id].m_iType == 2 then
		local i = self.m_pAttrDataBuff[id].m_iType2
		i = math.pow(10,i)
		str = tostring(value / i)
		str = string.format("%."..xianshi.."f",str).."%"
	else
		str = tostring(value)
	end
	return str
end

--[[
获取属性数目
]]
function LAttrDataManager:GetAttrNum()
	return self.m_pAttrCount
end

--[[
获取属性数据
]]
function LAttrDataManager:GetAttrData(id)
	return self.m_pAttrDataBuff[id]
end

--[[
获取对应技能id的技能数据
]]
function LAttrDataManager:GetSkillData(id)
	return self.m_pAttrDataBuff[id]
end

function LAttrDataManager:ReadAttrData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/shuxing.xml")
		-- body
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	self.m_pAttrCount = 0
	for i = 1, #rec do
		local v = rec[i]
		local attrdata = {}
		attrdata.m_wId = tonumber(v["@shuxing_id"])
		attrdata.m_iNameId = tonumber(v["@name"])
		attrdata.m_iType = tonumber(v["@data_type"])
		attrdata.m_iType2 = tonumber(v["@data_type2"])
		attrdata.m_desc = tonumber(v["@des"])
		attrdata.m_iXianshi = tonumber(v["@xianshi"])
		self.m_pAttrDataBuff[attrdata.m_wId] = attrdata
		self.m_pAttrCount = self.m_pAttrCount + 1
	end
end

return LAttrDataManager:Awake()