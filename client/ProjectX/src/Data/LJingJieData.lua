--[[
坐骑基础信息
从表里读取的基础信息，存放在LDataConstMgr里面，游戏过程中不可修改不可改变，不可在其他地方New
]]
LJingJieConfig = {}
LJingJieConfig.__index = LJingJieConfig
function LJingJieConfig:New()
	local o = {}
	setmetatable(o,LJingJieConfig)	
	o:ctor()
	return o
end

function LJingJieConfig:ctor()
	self.id = 0        --境界id
	self.name = ""     --境界名字
	self.color=0       --境界颜色
	self.upgrade={}    --升级类型和数量
	self.attrList={}   --属性加成
	self.salary=nil     --每日俸禄
	self.icon=""      --图标
	self.isGet=false   --是否获得
	
end



function LJingJieConfig:GetBreakItem()
   for k,v in pairs(self.cost) do
   	   return k,v
   end
end

function LJingJieConfig:Delete()
	self.id =nil        --境界id
	self.name = nil     --境界名字
	self.color=nil       --境界颜色
	self.upgrade=nil    --升级类型和数量
	self.attrList=nil  --属性加成
	self.salary=nil      --每日俸禄
	self.icon=""
	self.isGet=false--是否获得
	
end
LJingJieOtherInfo = {}
LJingJieOtherInfo.__index = LJingJieOtherInfo
function LJingJieOtherInfo:New()
	local o = {}
	setmetatable(o,LJingJieOtherInfo)	
	o:ctor()
	return o
end

function LJingJieOtherInfo:ctor()
	self.totalPower=0--总战力
	self.attrList={}--属性
	self.isShow=0--是否显示
	self.salary=0--奖励
	self.curId=0--当前id

end





