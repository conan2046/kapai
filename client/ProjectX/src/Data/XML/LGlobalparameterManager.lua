LGlobalparameterData = {}
LGlobalparameterData.__index = LFashionData
function LGlobalparameterData:New()
	local o = {}
	setmetatable(o,LFashionData)	
	o:ctor()
	return o
end

function LGlobalparameterData:ctor()
	self.m_sType = ""
	self.m_sString = ""
end


LGlobalparameterManager = LDataBase:New()
LGlobalparameterManager.__index = LGlobalparameterManager
function LGlobalparameterManager:New()
	local o = LUIBase:New()
	setmetatable(o,LGlobalparameterManager)	
	o:Awake()
	return o
end

function LGlobalparameterManager:Awake()
	self.m_GlobalparameterData = {}
	self.m_bIsLoaded = false
end

function LGlobalparameterManager:Instance()
	if self.m_bIsLoaded == false then
		self:ReadData()
		self.m_bIsLoaded = true
	end
	return self
end

function LGlobalparameterManager:ReadData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/globalparameter.xml")
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	for i = 1, #rec do
		local v = rec[i]
		local globalparameterData = LGlobalparameterData:New()
		globalparameterData.m_sType = tostring(v["@type"])
		globalparameterData.m_sParameter = tostring(v["@parameter"])
        self.m_GlobalparameterData[globalparameterData.m_sType] = globalparameterData
	end
end

function LGlobalparameterManager:GetGlobalParameterString(key)
	if self.m_GlobalparameterData[key] == nil then
		return nil
	end
	return self.m_GlobalparameterData[key].m_sParameter
end

return LGlobalparameterManager:Awake()