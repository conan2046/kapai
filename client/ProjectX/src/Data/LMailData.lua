LMailData = {}
LMailData.__index = LMailData
function LMailData:New()
	local o = {}
	setmetatable(o, LMailData )	
	o:ctor()
	return o
end

function LMailData:ctor()
    self.id = 0
    self.from_id = 0
    self.from_name = ""
    self.money = 0
    self.yuanbao = 0
    self.bdyuanbao = 0
    self.shenhun = 0
    self.endTime = 0
    self.message = ""
    self.preid = 10000
    self.item = {}
    self.itemNum = {}
    self.pet = {}
    self.otherItems = {} --积分等
    self.petEquips = {} --宠物装备
end

function LMailData:Delete(id)
    self.id = nil
    self.from_id = nil
    self.from_name = nil
    self.money = nil
    self.yuanbao = nil
    self.bdyuanbao = nil
    self.shenhun = nil
    self.endTime = nil
    self.message = nil
    self.preid = nil
    self.item = nil
    self.itemNum = nil
    self.pet = nil
    self.otherItems = nil
end

