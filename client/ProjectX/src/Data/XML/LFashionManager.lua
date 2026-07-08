--[[
]]
PFashionData = {}
PFashionData.__index = PFashionData
function PFashionData:New(id)
	local o = {}
	setmetatable(o,PFashionData)
	o:ctor(id)
	return o
end

function PFashionData:ctor(id)
	self.m_iID = id
	self.m_sName = LTipsManager:Instance():GetTips(LItemManager:Instance():GetItemResData(id).m_iNameId)
	self.m_Data = LFashionManager:Instance():GetFashionData(id)
	self.m_pBItem = LItemManager:Instance():GetItemResData(id)
	self.m_Color = self.m_Data.m_byColors[1] --颜色属性
	self.m_IsOwn = 0 --是否拥有 0否 1是
end


--[[
时装数据管理
]]
LFashionData = {}
LFashionData.__index = LFashionData
LFashionData.Type_Hair = 1--头发类型
LFashionData.Type_Clothes = 2--衣服类型
LFashionData.Type_Face = 3--脸类型
function LFashionData:New()
	local o = {}
	setmetatable(o,LFashionData)	
	o:ctor()
	return o
end

function LFashionData:ctor()
	self.m_iID = 0
	self.m_iModelId = 0--m_netType
	self.m_byType = 0--时装类型
	self.m_iNameId = 0--名字id
	self.m_byColors = {}--颜色表
	self.m_iConsumeIds = {}--
	self.m_byConsumeNums = {}--
	self.m_iDescId = 0--详细描述id
	self.m_iParentModelId = 0--父模型id
end

LFashionManager = LDataBase:New()
LFashionManager.__index = LFashionManager
function LFashionManager:New()
	local o = LUIBase:New()
	setmetatable(o,LFashionManager)	
	o:Awake()
	return o
end

function LFashionManager:Awake()
	self.m_bIsLoaded = false
	self.m_pFashionDataBuff = {}
end

function LFashionManager:Instance()
	if self.m_bIsLoaded == false then
		self:ReadData()
		self.m_bIsLoaded = true
	end
	return self
end

function LFashionManager:GetFashionData(id)
    return self.m_pFashionDataBuff[id]
end

function LFashionManager:GetFashionCount()
    return #self.m_pFashionDataBuff
end


--时装类型(1发型 2衣服)
function LFashionManager:GetMoRenFashion(modelId)
    local fashions = {}
    local k = 0
    for k, v in pairs(self.m_pFashionDataBuff) do
    	if v.m_iParentModelId == modelId and v.m_iModelId == 1 then
    		k = k + 1
    		fashions[v.m_byType] = v.m_iID
    		if k == 3 then
    			break
    		end
    	end
    end
    return fashions
end

function LFashionManager:ReadData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/fashion.xml")
		-- body
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	for i = 1, #rec do
		local v = rec[i]
		local fashiondata = LFashionData:New()
		fashiondata.m_iID = tonumber(v["@id"])
		fashiondata.m_iModelId = tonumber(v["@net_type"])
		fashiondata.m_byType = tonumber(v["@type2"])
		fashiondata.m_iDescId = tonumber(v["@tip"])
		local cc = string.split( v["@consume"], "|")
		for i = 1, #cc do
			if cc[i] ~= "0" then
				local temp = string.split( cc[i], "-")
				table.insert(fashiondata.m_iConsumeIds, tonumber(temp[1]))
				table.insert(fashiondata.m_byConsumeNums, tonumber(temp[2]))
			end
		end
		local s = v["@colour"]
        local ss = string.split( v["@colour"], "|")
        for i = 1, #ss do
        	table.insert(fashiondata.m_byColors, tonumber(ss[i]))
        end
        
        fashiondata.m_iParentModelId = tonumber(v["@model"])
        self.m_pFashionDataBuff[fashiondata.m_iID] = fashiondata
	end
end

return LFashionManager:Awake()