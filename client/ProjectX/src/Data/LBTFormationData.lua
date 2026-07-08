--[[
阵容数据
]]
LFormationData = {}
LFormationData.__index = LFormationData
function LFormationData:New()
	local o = {}
	setmetatable(o,LFormationData)
	o:ctor()
	return o
end

function LFormationData:ctor()
	self.id = 0--阵型id
	self.name = ""--阵容名称
	self.posList = {0,0,0,0}--阵容出站的下标
	self.posOpenLvList = {0,0,0,0}--站位对应的开启等级
	self.restraintList = {}--克制列表
end

function LFormationData:Delete()
	self.id = nil--阵型id
	self.name = nil--阵容名称
	self.posList = nil--阵容出站的下标
	self.posOpenLvList = nil--站位对应的开启等级
	self.restraintList = nil
end

--[[
阵容对应的属性加成已经升级所需的道具
]]
LFormationLvUpData = {}
LFormationLvUpData.__index = LFormationLvUpData
function LFormationLvUpData:New()
	local o = {}
	setmetatable(o,LFormationLvUpData)
	o:ctor()
	return o
end

function LFormationLvUpData:ctor()
	self.id = 0--阵型id
	self.lv = 0--阵型等级
	--属性加成
	self.addAttrValue = {}
	self.addAttrType = {}
	--每个站位对应两个附加属性值
	for i = 1, AppDef.Formation.MaxFightNum do
		table.insert(self.addAttrType,{0,0})
		table.insert(self.addAttrValue,{0,0})
	end
	self.costItemId = 0--升级消耗的道具id
	self.costItemNum = 0--升级消耗的道具数量
	self.addPower = 0--升级成功后对应的战斗力加成
	
end

function LFormationLvUpData:Delete()
	self.id = nil--
	self.lv = nil--
	--属性加成
	self.addAttrValue = nil
	self.addAttrType = nil
	self.costItemId = nil--
	self.costItemNum = nil--
	self.addPower = nil--
end
