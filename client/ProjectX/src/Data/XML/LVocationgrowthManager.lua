--[[
时装数据管理
]]
LVocationgrowthData = {}
LVocationgrowthData.__index = LVocationgrowthData
LVocationgrowthData.Type_Hair = 1--头发类型
LVocationgrowthData.Type_Clothes = 2--衣服类型
LVocationgrowthData.Type_Face = 3--脸类型
function LVocationgrowthData:New()
	local o = {}
	setmetatable(o,LVocationgrowthData)	
	o:ctor()
	return o
end

function LVocationgrowthData:ctor()
	self.m_ivovation = 0
	self.m_hp_growth = 0
	self.m_mp_growth = 0
	self.m_wugong_growth = 0
	self.m_fagong_growth = 0
	self.m_speed_growth = 0
end

LVocationgrowthManager= LUIBase:New()
LVocationgrowthManager.__index = LVocationgrowthManager
function LVocationgrowthManager:New()
	local o = LUIBase:New()
	setmetatable(o,LVocationgrowthManager)	
	o:Awake()
	return o
end

function LVocationgrowthManager:Awake()
	self.m_bIsLoaded = false
	self.m_pVocationgrowthDatas = {}
end


function LVocationgrowthManager:ProcessEvent(msg)
	if msg.msgId == 0 then
	end
end

function LVocationgrowthManager:Instance()
	if self.m_bIsLoaded == false then
		self:ReadData()
		self.m_bIsLoaded = true
	end
	return self
end

function LVocationgrowthManager:GetvocationgrowthData(id)
    return self.m_pVocationgrowthDatas[id]
end

function LVocationgrowthManager:ReadData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/Vocationgrowth.xml")
		-- body
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	for i = 1, #rec do
		local v = rec[i]
		local VocationgrowthData = LVocationgrowthData:New()
		VocationgrowthData.m_ivovation = tonumber(v["@vovation"])
		VocationgrowthData.m_hp_growth = tonumber(v["@hp_growth"])
		VocationgrowthData.m_mp_growth = tonumber(v["@mp_growth"])
		VocationgrowthData.m_wugong_growth = tonumber(v["@wugong_growth"])
        VocationgrowthData.m_fagong_growth = tonumber(v["@fagong_growth"])
        VocationgrowthData.m_speed_growth = tonumber(v["@speed_growth"])
        self.m_pVocationgrowthDatas[VocationgrowthData.m_ivovation] = VocationgrowthData
	end
end

return LVocationgrowthManager:Awake()