--[[
lua里面的游戏逻辑控制
]]
LRoleNickManager = LDataBase:New()
LRoleNickManager.__index = LRoleNickManager
function LRoleNickManager:New()
	local o = LUIBase:New()
	setmetatable(o,LRoleNickManager)	
	o:Awake()
	return o
end

function LRoleNickManager:Awake()
	self.m_bIsLoaded = false
	self.m_pXingShi = {}
	self.m_pMale = {}
	self.m_pFeMale = {}
end

function LRoleNickManager:Instance()
	if self.m_bIsLoaded == false then
		self:ReadData()
		self.m_bIsLoaded = true
	end
	return self
end

function LRoleNickManager:ReadData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/name.xml")
		-- body
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	for i = 1, #rec do
		local v = rec[i]
		table.insert(self.m_pXingShi, v["@xing"])
		table.insert(self.m_pMale, v["@nan"])
		table.insert(self.m_pFeMale, v["@nv"])
	end
end

--[[
@功能：获取提示文字
param1:id(int)提示文字的id
return:string提示文字字符串
]]
function LRoleNickManager:GetRandomName(race)
	--女性的名字
	local family = self.m_pXingShi[math.random(1,#self.m_pXingShi)]
	local name
	if race == 4 or race == 5 then
		name = self.m_pMale[math.random(1,#self.m_pMale)]
	else
		name = self.m_pFeMale[math.random(1,#self.m_pFeMale)]
	end
	return tostring(family..name)
end

return LRoleNickManager:Awake()