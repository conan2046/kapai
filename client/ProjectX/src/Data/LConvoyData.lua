--[[
护送详细信息
]]
LConvoyData = {}
LConvoyData.__index = LConvoyData
function LConvoyData:New()
	local o = {}
	setmetatable(o,LConvoyData)	
	o:ctor()
	return o
end

function LConvoyData:ctor()
	self.Name = ""
	self.Quality = 0
	self.MaxNum = 0
	self.AvaNum = 0
	self.Exp = 0
	self.taskId = 0
	self.npcId = 0
	self.useMoney = 0--消耗金钱
end

function LConvoyData:Reset()
	self.Name = ""
	self.Quality = 0
	self.MaxNum = 0
	self.AvaNum = 0
	self.Exp = 0
	self.taskId = 0
	self.npcId = 0
	self.useMoney = 0--消耗金钱
end

function LConvoyData:Delete()
	self.Name = nil
	self.Quality = nil
	self.MaxNum = nil
	self.AvaNum = nil
	self.Exp = nil
	self.taskId = nil
	self.npcId = nil
	self.useMoney = nil--消耗金钱
end