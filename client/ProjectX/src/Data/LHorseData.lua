--[[
坐骑基础信息
从表里读取的基础信息，存放在LDataConstMgr里面，游戏过程中不可修改不可改变，不可在其他地方New
]]
LHorseConfig = {}
LHorseConfig.__index = LHorseConfig
function LHorseConfig:New()
	local o = {}
	setmetatable(o,LHorseConfig)	
	o:ctor()
	return o
end

function LHorseConfig:ctor()
	self.id = 0        --坐骑id
	self.name = ""--坐骑名字
	self.getWayType = 0--获取方式0进阶1元宝购买2道具兑换
	self.getWayNum = 0--获取数量
	self.getWayItem = 0--获取需要的道具id
	self.moveSpeed = 0--移动速度
	self.jinjieId = 0--进阶后的坐骑id
	self.jinjieCostIds = {}
	self.jingjieCostNums = {}
	self.attrTypeArr = {}--属性类别数组
	self.attrValueArr = {}--属性值数组
	self.desc = ""--描述
	self.isGet = false--是否已经被玩家获得，这个可以改变
end

function LHorseConfig:GetJinjieMoney()
	for i = 1, #self.jinjieCostIds do
		if self.jinjieCostIds[i] == AppDef.EMoneyType.EMT_Gold then
			return self.jingjieCostNums[i]
		end
	end
	return 0
end

function LHorseConfig:GetJinjieItem()
	for i = 1, #self.jinjieCostIds do
		if self.jinjieCostIds[i] < AppDef.EMoneyType.EMT_Gold then
			return self.jinjieCostIds[i],self.jingjieCostNums[i]
		end
	end
	return 0,0
end

function LHorseConfig:Delete()
	self.id = nil        --坐骑id
	self.name = nil
	self.getWayType = nil--获取方式0进阶1元宝购买2道具兑换
	self.getWayNum = nil--获取数量
	self.getWayItem = nil--获取需要的道具id
	self.moveSpeed = nil--移动速度
	self.attrTypeArr = nil--属性类别数组
	self.attrValueArr = nil--属性值数组
	self.desc = nil--描述
	self.isGet = nil
	self.jinjieId = nil
	self.jinjieCostIds = nil
	self.jingjieCostNums = nil
end

--[[
坐骑强化结构
从表里获取
]]
LHorseStrengthData = {}
LHorseStrengthData.__index = LHorseStrengthData
function LHorseStrengthData:New()
	local o = {}
	setmetatable(o,LHorseStrengthData)	
	o:ctor()
	return o
end

function LHorseStrengthData:ctor()
	self.lv = 0        --坐骑等级
	self.needExp = 0--所需经验
	self.attrTypeArr = {}--属性类别数组
	self.attrValueArr = {}--属性值数组
end

function LHorseStrengthData:Delete()
	self.lv = nil        --坐骑等级
	self.needExp = nil--所需经验
	self.attrTypeArr = nil--属性类别数组
	self.attrValueArr = nil--属性值数组
end


LHorseData = {}
LHorseData.__index = LHorseData
function LHorseData:New(hid)
	hid = hid or 0
	local o = {}
	setmetatable(o,LHorseData)	
	o:ctor(hid)
	return o
end

function LHorseData:SetId(hid)
	self.id = hid
	if self.id > 0 then
		self.baseData = LDataConstMgr:GetHorseConfigData()
	else
		self.baseData = nil
	end
end

function LHorseData:ctor(hid)
	self.id = 0        --坐骑id
	self.baseData = nil
	self:SetId(hid)
	self.timeLimit = 0      --时间限制 
	self.basicSpeed = 0     --速度加成
end

function LHorseData:Delete()
	self.id = nil        --坐骑id
	self.baseData = nil
	self.timeLimit = nil      --时间限制 
	self.basicSpeed = nil     --速度加成
end

-- function LHorseConfig:Getid() 
-- 	return self.id
-- end

-- function LHorseConfig:GetTimeLimit() 
-- 	return self.timeLimit 
-- end      --时间限制 

-- function LHorseConfig:GetBasicDamage() 
-- 	return self.basicDamage 
-- end  --基础伤害

-- function LHorseConfig:GetBasicRecovery() 
-- 	return self.basicRecovery
-- end  --基础防御

-- function LHorseConfig:GetBasicHP() 
-- 	return self.basicHP
-- end        --基础气血

-- function LHorseConfig:GetBasicSpeed() 
-- 	return self.basicSpeed
-- end     --速度加成


--[[
坐骑其他信息
]]
LHorseOthInf = {}
LHorseOthInf.__index = LHorseOthInf
function LHorseOthInf:New()
	local o = {}
	setmetatable(o,LHorseOthInf)	
	o:ctor()
	return o
end

function LHorseOthInf:ctor()
	self.useIndex = 0xff
	self.qhLevel = 0
	self.plusRate = 0--强化次数加成概率
	self.TotalPower=0
	self.AttrList={}
end

function LHorseOthInf:Reset()
	self.useIndex = 0xff
	self.qhLevel = 0
	self.plusRate = 0--强化次数加成概率
	self.TotalPower=0
end

function LHorseOthInf:Delete()
	self.useIndex = nil
	self.qhLevel = nil
	self.plusRate = nil
	self.TotalPower=nil
	self.AttrList=nil
	-- self.qh_damage = nil
	-- self.qh_recovery = nil
	-- self.qh_Hp = nil
end

function LHorseOthInf:GetUseIndex() 
	return self.useIndex
end

function LHorseOthInf:SetUseIndex(idx) 
	self.useIndex = idx
end

function LHorseOthInf:GetqhLevel()
	return self.qhLevel
end

function LHorseOthInf:GetPlusRate()
	return self.plusRate
end
function LHorseOthInf:GetTotalPower()
   return self.TotalPower
end

-- function LHorseOthInf:GetqhDamage() 
-- 	return self.qh_damage
-- end

-- function LHorseOthInf:GetqhRecovery() 
-- 	return self.qh_recovery
-- end

-- function LHorseOthInf:GetqhHp() 
-- 	return self.qh_Hp
-- end


-- --[[
-- 从服务器收到的坐骑列表
-- ]]
-- LServerHorseList = {}
-- LServerHorseList.__index = LServerHorseList
-- function LServerHorseList:New()
-- 	local o = {}
-- 	setmetatable(o,LServerHorseList)	
-- 	o:ctor()
-- 	return o
-- end

-- function LServerHorseList:ctor()
-- 	self.id = 0
-- 	self.describ = ""
-- 	self.getway = 0--获的方式0进阶1元宝购买2道具获得
-- 	self.needNum = 0       --所需的数量
-- 	self.itemId = 0		   --所需的item
-- 	self.IsGet = false		   --是否获得
-- 	self.basicDamage = 0   --基础伤害
-- 	self.basicRecovery = 0--基础防御
-- 	self.basicHP = 0       --基础气血
-- 	self.basicSpeed = 0	   --速度加成
-- end

-- function LServerHorseList:Delete()
-- 	self.id = nil
-- 	self.describ = nil
-- 	self.getway = nil--获的方式0进阶1元宝购买2道具获得
-- 	self.needNum = nil       --所需的数量
-- 	self.itemId = nil		   --所需的item
-- 	self.IsGet = nil		   --是否获得
-- 	self.basicDamage = nil   --基础伤害
-- 	self.basicRecovery = nil--基础防御
-- 	self.basicHP = nil       --基础气血
-- 	self.basicSpeed = nil	   --速度加成
-- end

-- function LServerHorseList:Getid() return self.id end
-- function LServerHorseList:GetDescrid() return self.describ end
-- function LServerHorseList:GetGetway() return self.getway end
-- function LServerHorseList:GetNeedNum() return self.needNum end
-- function LServerHorseList:GetItemId() return self.itemId end
-- function LServerHorseList:CheckIsGet() return self.IsGet end
-- function LServerHorseList:GetBasicDamage() return self.basicDamage end
-- function LServerHorseList:GetBasicRecovery() return self.basicRecovery end
-- function LServerHorseList:GetBasicHP() return self.basicHP end
-- function LServerHorseList:GetBasicSpeed() return self.basicSpeed end


LHorseResInfo = {}
LHorseResInfo.__index = LHorseResInfo
function LHorseResInfo:New()
	local o = {}
	setmetatable(o,LHorseResInfo)	
	o:ctor()
	return o
end

function LHorseResInfo:ctor()
	self.id = 0--坐骑id
	self.type = 0--是否买卖
	self.name = ""--坐骑名字
	self.isSameState = 0--跑步待机共用
	self.isStandState = 0--是否为站立姿态
	self.png = ""--图片资源名字
	self.ani = ""--ani资源名字
end

function LHorseResInfo:Delete()
	self.id = nil--坐骑id
	self.type = nil--是否买卖
	self.name = nil--坐骑名字
	self.isSameState = nil--跑步待机共用
	self.isStandState = nil--是否为站立姿态
	self.png = nil--图片资源名字
	self.ani = nil--ani资源名字
end
function LHorseResInfo:Getid() return self.id end--坐骑id
function LHorseResInfo:GetType() return self.type end--是否买卖
function LHorseResInfo:GetName() return self.name end--坐骑名字
function LHorseResInfo:GetPng() return self.png end--图片资源名字
function LHorseResInfo:GetAni() return self.ani end--ani资源名字
