LLuckyDrawItemInfo = {}
LLuckyDrawItemInfo.__index = LLuckyDrawItemInfo
function LLuckyDrawItemInfo:New()
	local o = {}
	setmetatable(o,LLuckyDrawItemInfo)	
	o:Init()
	return o
end

function LLuckyDrawItemInfo:Init()
	self.type = 0
	self.needItemId = 0
	self.needItemNum = 0
	self.needYB = 0
	self.cd = 0
	self.mustBeOrangeTimes = 0
	self.name = ''
	self.openLevel = 0
	self.isFirstTimes = false
end

function LLuckyDrawItemInfo:Delete()
	self.type = nil
	self.needItemId = nil
	self.needItemNum = nil
	self.needYB = nil
	self.cd = nil
	self.mustBeOrangeTimes = nil
	self.name = nil
	self.openLevel = nil
	self.isFirstTimes = nil
end

-------------------------------------------------------------------------
LLuckyDrawInfo = {}
LLuckyDrawInfo.__index = LLuckyDrawInfo
function LLuckyDrawInfo:New()
	local o = {}
	setmetatable(o,LLuckyDrawInfo)
	o:Init()
	return o
end

function LLuckyDrawInfo:Init()
	self.items = {} --[LLuckyDrawItemInfo]
	self.kind = 0
	self.isOpen = 0
	self.showPetIds = {}
end

function LLuckyDrawInfo:Delete()
	Utils:Delete(self.items)
	self.kind = nil
	self.isOpen = nil
	Utils:Delete(self.showPetIds)
end

-------------------------------------------------------------------------
LLuckyDrawResultItem = {}
LLuckyDrawResultItem.__index = LLuckyDrawResultItem
function LLuckyDrawResultItem:New()
	local o = {}
	setmetatable(o,LLuckyDrawResultItem)
	o:Init()
	return o
end

function LLuckyDrawResultItem:Init()
	self.awardType = 0
	self.petId = 0
    self.petName = ''
    self.petType = 0
    self.petStar = 0
    self.itemId = 0
    self.itemNum = 0
    self.transformId = 0
    self.transformNum = 0
end

function LLuckyDrawResultItem:Delete()
	self.awardType = nil
	self.petId = nil
    self.petName = nil
    self.petType = nil
    self.petStar = nil
    self.itemId = nil
    self.itemNum = nil
    self.transformId = nil
    self.transformNum = nil
end

-------------------------------------------------------------------------
LLuckyDrawResultInfo = {}
LLuckyDrawResultInfo.__index = LLuckyDrawResultInfo
function LLuckyDrawResultInfo:New()
	local o = {}
	setmetatable(o,LLuckyDrawResultInfo)
	o:Init()
	return o
end

function LLuckyDrawResultInfo:Init()
	self.kind = 0
	self.opType = 0
	self.cd = 0
	self.mustBeOrangeTimes = 0
	self.items = {} --[LLuckyDrawResultItem]
	self.mustBeList = {}
end

function LLuckyDrawResultInfo:Delete()
	Utils:Delete(self.items)
	self.kind = nil
	self.opType = nil
	self.cd = nil
	self.mustBeOrangeTimes = nil
	self.mustBeList = nil
end