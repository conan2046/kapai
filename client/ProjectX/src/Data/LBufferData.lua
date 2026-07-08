
LBuffData = {}
LBuffData.__index = LBuffData
function LBuffData:New()
	local o = {}
	setmetatable(o,LBuffData)	
	o:ctor()
	return o
end

function LBuffData:ctor()
	self.type = 0        --buff类型	
	self.limitLevel=0       --开启等级
	self.surplusTime=0   --剩余时间   
	self.dic1=0             --buff属性描述 
	self.dic2=0             --buff属性描述  	
end
function LBuffData:Delete()
	self.type = 0        --buff类型
	self.limitLevel=0       --开启等级
	self.surplusTime=0   --剩余时间   	
	self.dic1=0             --buff属性描述  
	self.dic2=0             --buff属性描述  
end 