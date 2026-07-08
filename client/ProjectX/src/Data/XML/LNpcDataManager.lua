--[[
 NPC数据
]]
LNpcData = {}
LNpcData.__index = LNpcData
function LNpcData:New()
	local o = {}
	setmetatable(o,LNpcData)	
	o:ctor()
	return o
end

function LNpcData:ctor()
	self.m_wId = 0
	self.m_strName = ""
	self.m_wPicId = 0
	self.m_iNameId = 0
	self.m_wPosX = 0
	self.m_wPosZ = 0
	self.m_fRotation = nil
	self.m_byMoveType = 0
	self.m_strDialog = ""
	self.m_fMapId = 0
	self.m_isAppearMiniMap = 0
end

LNpcDataManager = LDataBase:New()
LNpcDataManager.__index = LNpcDataManager
function LNpcDataManager:New()
	local o = LUIBase:New()
	setmetatable(o,LNpcDataManager)	
	o:Awake()
	return o
end

function LNpcDataManager:Awake()
	self.m_bIsLoaded = false
	self.m_pNpcDataBuff = {}
end

function LNpcDataManager:Instance()
	if self.m_bIsLoaded == false then
		self:ReadData()
		self.m_bIsLoaded = true
	end
	return self
end

function LNpcDataManager:GetNpcData(id)
    return self.m_pNpcDataBuff[id]
end


function LNpcDataManager:ReadData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/npc.xml")
		-- body
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	for i = 1, #rec do
		local v = rec[i]
		local NpcData = LNpcData:New()
		NpcData.m_wId = tonumber(v["@npc_id"])
		NpcData.m_strName = tostring(v["@name"])
		NpcData.m_wPicId = tonumber(v["@bust_id"])
		NpcData.m_wPosX = tonumber(v["@pos_x"])
		NpcData.m_wPosZ = tonumber(v["@pos_z"])
		NpcData.m_fRotation = tonumber(v["@jiaodu"])
		NpcData.m_byMoveType = tonumber(v["@move_type"])
		NpcData.m_fMapId = tonumber(v["@map_id"])
		NpcData.m_strDialog = tostring(v["@duihua"])
		NpcData.m_fMapId = tonumber(v["@map_id"])
        NpcData.m_isAppearMiniMap = tonumber(v["@appear"])
        self.m_pNpcDataBuff[NpcData.m_wId] = NpcData
	end
end


function LNpcDataManager:GetNpcDataByMapId(mapid )
	local ret={}
	for i,v in ipairs(self.m_pNpcDataBuff) do
		 local NpcData = v
		 if(NpcData.m_fMapId == mapid) then
		 	table.insert(ret,NpcData)
		 end
	end
	-- for i=1, #self.m_pNpcDataBuff do
	-- 	local NpcData = self.m_pNpcDataBuff[i]
	-- 	if(NpcData.m_fMapId == mapid) then
	-- 		table.insert(ret,NpcData)
	-- 	end
	-- end
	return ret
end



return LNpcDataManager:Awake()