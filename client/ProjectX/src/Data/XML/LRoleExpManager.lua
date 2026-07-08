LRoleExpData = {}
LRoleExpData.__index = LRoleExpData
function LRoleExpData:New()
	local o = {}
	setmetatable(o,LRoleExpData)	
	o:ctor()
	return o
end

function LRoleExpData:ctor()
	self.m_wLV = 0
	self.m_strExp = 0
	self.m_strExp1 = 0
	self.m_strExp2 = 0
	self.m_strExp3 = 0
	self.m_idaohang = 0
	self.m_idaohang1 = 0
	self.m_idaohang2 = 0
	self.m_idaohang3 = 0
end

LRoleExpManager = LUIBase:New()
LRoleExpManager.__index = LRoleExpManager
function LRoleExpManager:New()
	local o = LUIBase:New()
	setmetatable(o,LRoleExpManager)	
	o:Awake()
	return o
end

function LRoleExpManager:Awake()
	self.m_bIsLoaded = false
	self.m_pRoleExpDatas = {}
end

function LRoleExpManager:Instance()
	if self.m_bIsLoaded == false then
		self:ReadData()
		self.m_bIsLoaded = true
	end
	return self
end

function LRoleExpManager:GetExpData(id)
	if self.m_pRoleExpDatas[id] == nil then
		return nil
	end
	return self.m_pRoleExpDatas[id]
end

function LRoleExpManager:GetAttrNum(id)
	return #self.m_pRoleExpDatas
end

function LRoleExpManager:GetdaoHengDay(zhuansheng,dengji)
	if zhuansheng == 0 then
		return self.m_pRoleExpDatas[dengji].m_idaohang
	elseif zhuansheng == 1 then
		return self.m_pRoleExpDatas[dengji].m_idaohang1
	elseif zhuansheng == 2 then
		return self.m_pRoleExpDatas[dengji].m_idaohang2
	elseif zhuansheng == 3 then
		return self.m_pRoleExpDatas[dengji].m_idaohang3
	end
end

function LRoleExpManager:ReadData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/role_exp.xml")
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	for i = 1, #rec do
		local v = rec[i]
		local roleExpData = LRoleExpData:New()
		roleExpData.m_wLV = tonumber(v["@LV"])
		roleExpData.m_strExp = tonumber(v["@EXP"])
		roleExpData.m_strExp1 = tonumber(v["@exp1"])
		roleExpData.m_strExp2 = tonumber(v["@exp2"])
		roleExpData.m_strExp3 = tonumber(v["@exp3"])
		roleExpData.m_idaohang = tonumber(v["@daohang"])
		roleExpData.m_idaohang1 = tonumber(v["@daohang1"])
		roleExpData.m_idaohang2 = tonumber(v["@daohang2"])
		roleExpData.m_idaohang3 = tonumber(v["@daohang3"])
        self.m_pRoleExpDatas[roleExpData.m_wLV] = roleExpData
	end
end

function LRoleExpManager:ProcessEvent(msg)
	if msg.msgId == 0 then
	end
end

return LRoleExpManager:Awake()