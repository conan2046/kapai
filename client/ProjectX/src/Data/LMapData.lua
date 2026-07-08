--地图路径数据
LMapInfo = {}
LMapInfo.__index = LMapInfo
function LMapInfo:New()
	local o = {}
	setmetatable(o,LMapInfo)	
	o:ctor()
	return o
end

function LMapInfo:ctor(id)
	self.id = 0--地图id
	self.pid = 0--图片id
	self.name = ""--名字
	self.GateVec = {}--传送点数组
	self.PrevMap = nil--前一个位置地图指针
	self.PrevPos = {0,0}--前一个位置的坐标点
end

function LMapInfo:Delete()
	self.id = nil--地图id
	self.pid = nil--图片id
	self.name = nil--名字
	self.GateVec = nil--传送点数组
	self.PrevMap = nil--前一个位置地图指针
	self.PrevPos = nil--前一个位置的坐标点
end

--地图传送点
LMapGateData = {}
LMapGateData.__index = LMapGateData
function LMapGateData:New()
	local o = {}
	setmetatable(o,LMapGateData)	
	o:ctor()
	return o
end

function LMapGateData:ctor(id)
	self.pos = {x = 0, y = 0}--传送点坐标
	self.id = 0--通往地图的id
	self.isNPC = false--是否是NPC传送
end

function LMapGateData:Delete()
	self.pos = nil
	self.id = nil
	self.isNPC = nil
end