--[[
时装数据管理
]]
LShuxingjiadianData = {}
LShuxingjiadianData.__index = LShuxingjiadianData
LShuxingjiadianData.Type_Hair = 1--头发类型
LShuxingjiadianData.Type_Clothes = 2--衣服类型
LShuxingjiadianData.Type_Face = 3--脸类型
function LShuxingjiadianData:New()
	local o = {}
	setmetatable(o,LShuxingjiadianData)	
	o:ctor()
	return o
end

function LShuxingjiadianData:ctor()
	self.m_iID = 0
	self.m_fHp = 0
	self.m_fMp = 0
	self.m_fWugong = 0
	self.m_fFagong = 0
	self.m_fSpeed = 0
end

LShuxingjiadianManager= LUIBase:New()
LShuxingjiadianManager.__index = LShuxingjiadianManager
function LShuxingjiadianManager:New()
	local o = LUIBase:New()
	setmetatable(o,LShuxingjiadianManager)	
	o:Awake()
	return o
end

function LShuxingjiadianManager:Awake()
	self.m_bIsLoaded = false
	self.m_pShuxingjiadianDatas = {}
end


function LShuxingjiadianManager:ProcessEvent(msg)
	if msg.msgId == 0 then
	end
end

function LShuxingjiadianManager:Instance()
	if self.m_bIsLoaded == false then
		self:ReadData()
		self.m_bIsLoaded = true
	end
	return self
end

function LShuxingjiadianManager:GetshuxingjiadianData(id)
    return self.m_pShuxingjiadianDatas[id]
end

function LShuxingjiadianManager:ReadData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/shuxingjiadian.xml")
		-- body
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	for i = 1, #rec do
		local v = rec[i]
		local shuxingjiadianData = LShuxingjiadianData:New()
		shuxingjiadianData.m_iID = tonumber(v["@shuxing_id"])
		shuxingjiadianData.m_fHp = tonumber(v["@hp"])
		shuxingjiadianData.m_fMp = tonumber(v["@mp"])
		shuxingjiadianData.m_fWugong = tonumber(v["@wugong"])
        shuxingjiadianData.m_fFagong = tonumber(v["@fagong"])
        shuxingjiadianData.m_fSpeed = tonumber(v["@speed"])
        self.m_pShuxingjiadianDatas[shuxingjiadianData.m_iID] = shuxingjiadianData
	end
end

return LShuxingjiadianManager:Awake()