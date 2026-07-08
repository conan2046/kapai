--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

--称号数据
LMedalInfo = {}
LMedalInfo.__index = LMedalInfo

function LMedalInfo:New()
	local o = {}
	setmetatable(o,LMedalInfo)	
	o:Init()
	return o
end

function LMedalInfo:Init()
    self.id = 0;
    self.state = 0; --是否显示1显示0不显示
    self.ware = 0;  --是否佩戴1显示0不显示
    self.zhandouli = 0;
end

function LMedalInfo:Reset()
    self.id = 0;
    self.state = 0; --是否显示1显示0不显示
    self.ware = 0;  --是否佩戴1显示0不显示
    self.zhandouli = 0;
end

function LMedalInfo:Delete()
    self.id = nil;
    self.state = nil; --是否显示1显示0不显示
    self.ware = nil;  --是否佩戴1显示0不显示
    self.zhandouli = nil;
end



LMedalAttributeInfo = {}
LMedalAttributeInfo.__index = LMedalAttributeInfo

function LMedalAttributeInfo:New()
	local o = {}
	setmetatable(o,LMedalAttributeInfo)	
	o:Init()
	return o
end

function LMedalAttributeInfo:Init()
    self.id = 0;
    self.name = ""; 
    self.desc = "";  
    self.damage = 0;
    self.recovery = 0
    self.maxHp = 0
    self.speed = 0
    self.petDamage = 0
    self.petRecovery = 0
    self.petMaxHp = 0
    self.petSpeed = 0
    self.attr = ""
    self.isShow = 1
    self.newAttribute = {}
end

function LMedalAttributeInfo:Delete()
    self.id = nil;
    self.name = nil; 
    self.desc = nil;  
    self.damage = nil;
    self.recovery = nil
    self.maxHp = nil
    self.speed = nil
    self.petDamage = nil
    self.petRecovery = nil
    self.petMaxHp = nil
    self.petSpeed = nil
    self.isShow = nil
    self.newAttribute = nil
end



--endregion
