LStuntData = {}
LStuntData.__index = LStuntData
function LStuntData:New()
	local o = {}
	setmetatable(o,LStuntData)	
	o:ctor()
	return o
end

function LStuntData:ctor()
	self.m_iID = 0
	self.m_describeId = 0
	self.m_effectId = 0
	self.m_nameid = 0
end

LStuntManager = LUIBase:New()
LStuntManager.__index = LStuntManager
function LStuntManager:New()
	local o = LUIBase:New()
	setmetatable(o,LStuntManager)	
	o:Awake()
	return o
end

function LStuntManager:Awake()
	print("LStuntManager:Awake")
	self.m_bIsLoaded = false
	self.m_pStuntDataBuff = {}
end


function LStuntManager:ProcessEvent(msg)
	if msg.msgId == 0 then
	end
end

function LStuntManager:Instance()
	if self.m_bIsLoaded == false then
		self:ReadData()
		self.m_bIsLoaded = true
	end
	return self
end

function LStuntManager:GetStuntData(id)
    return self.m_pStuntDataBuff[id]
end

function LStuntManager:ReadData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/stunt.xml")
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	for i = 1, #rec do
		local v = rec[i]
		local stuntData = LStuntData:New()
		stuntData.m_iID = tonumber(v["@id"])
		stuntData.m_describeId = tonumber(v["@describe_id"])
		stuntData.m_nameid = tonumber(v["@name_id"])
        self.m_pStuntDataBuff[stuntData.m_iID] = stuntData
	end
end

return LStuntManager:Awake()