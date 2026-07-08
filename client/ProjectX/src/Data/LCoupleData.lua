--夫妻信息
LCoupleData = {}
LCoupleData.__index = LCoupleData

function LCoupleData:New()
	local o = {}
	setmetatable(o,LCoupleData)	
	o:Init()
	return o
end

function LCoupleData:Init()
    self.IsMarried = false ;        --是否结婚
	self.roleType = 0;	            --0丈夫1妻子
	self.roleName = "";             --名字
	self.IsShowName = false;        --是否显示称谓
	self.roleLv = 0;		        --等级
	self.ringQuality = 0;           --戒指颜色：1-5绿蓝紫橙金
	self.CurHp = 0;		            --加成气血
	self.MaxHp = 0;		            --气血加成上限
    self.CurAttack = 0;	            --加成攻击
	self.MaxAttack = 0;	            --攻击加成上限
	self.CurDef = 0;		        --当前防御加成
	self.MaxDef = 0;		        --防御加成上限
	self.MaterialItem = 0;          --婚戒培养材料
    self.MaterialItemNum = 0;       --培养材料要求数目
	self.Money = 0;		            --培养所需金币
	self.RingId = 0;                --戒指ID
    self.happyValue = 0;            --幸福值
end

function LCoupleData:Delete()
    self.IsMarried = nil;           --是否结婚
	self.roleType = nil;	        --0丈夫1妻子
	self.roleName = nil;            --名字
	self.IsShowName = nil;          --是否显示称谓
	self.roleLv = nil;		        --等级
	self.ringQuality = nil;         --戒指颜色：1-5绿蓝紫橙金
	self.CurHp = nil;		        --加成气血
	self.MaxHp = nil;		        --气血加成上限
    self.CurAttack = nil;	        --加成攻击
	self.MaxAttack = nil;	        --攻击加成上限
	self.CurDef = nil;		        --当前防御加成
	self.MaxDef = nil;		        --防御加成上限
	self.MaterialItem = nil;        --婚戒培养材料
    self.MaterialItemNum = nil;     --培养材料要求数目
	self.Money = nil;		        --培养所需金币
	self.RingId = nil;              --戒指ID
    self.happyValue = nil;          --幸福值
end