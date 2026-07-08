--商城数据结构
LApplayInfo = {}
LApplayInfo.__index = LApplayInfo
function LApplayInfo:New()
	local o = {}
	setmetatable(o,LApplayInfo)	
	o:Init()
	return o
end

function LApplayInfo:Init()
	self.roleId = 0
	self.level = 0
	self.zhandouli = 0 --战斗力
    self.name = ""
	self.head = 0   --头像
	self.sex = 0
end

function LApplayInfo:Delete()
	self.roleId = nil
	self.level = nil
	self.zhandouli = nil
    self.name = nil
	self.head = nil
	self.sex = nil
end

--------------------------------------------------------
LPlantCell = {}
LPlantCell.__index = LPlantCell
function LPlantCell:New()
	local o = {}
	setmetatable(o,LPlantCell)	
	o:Init()
	return o
end

function LPlantCell:Init()
	self.AreaIndex = 0      --所属区域索引
    self.Index = 0          --索引
    self.ItemId = 0         --种子ID
    self.RoleId = 0         --角色ID
    self.RoleName = ""  --角色名称
    self.Quality = 0        --品质
    self.State = 0          --状态
    self.StoleNum = 0       --已偷次数
    self.StealMax = 0       --最大可偷次数
    self.RipeTime = 0       --成熟时间
    self.TotalTime = 0      --总时间
    self.TreeName = ""       --树名称
    self.PicId = 0          --图片ID
    self.GainType = 0       --收获物品类型(1-金币 2-元宝 3-物品)
    self.GainItemId = 0     --收获物品id
    self.GainValue = 0      --收获物品数量
    self.MyCanStealNum = 0  --自己可偷取次数
    self.IsOpened = false       --是否开垦
    self.OpenLevel = 0      --开启等级（帮派等级）
end

function LPlantCell:Delete()
	self.AreaIndex = nil
    self.Index = nil
    self.ItemId = nil
    self.RoleId = nil
    self.RoleName = nil
    self.Quality = nil
    self.State = nil
    self.StoleNum = nil
    self.StealMax = nil
    self.RipeTime = nil
    self.TotalTime = nil
    self.TreeName = nil
    self.PicId = nil
    self.GainType = nil
    self.GainItemId = nil
    self.GainValue = nil
    self.MyCanStealNum = nil
    self.IsOpened = nil
    self.OpenLevel = nil
end

function LPlantCell:IsRipe()
	return bit:_and(self.State, 0x01) == 0x01
end

function LPlantCell:IsNeedWater()
	return bit:_and(self.State, 0x02) == 0x02
end

function LPlantCell:IsNeedBug()
	return bit:_and(self.State, 0x04) == 0x04
end

function LPlantCell:IsCanRemove()
	return bit:_and(self.State, 0x08) == 0x08
end