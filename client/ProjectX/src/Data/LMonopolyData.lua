--多次闯关
LMonopolyData = {}
LMonopolyData.__index = LMonopolyData
function LMonopolyData:New()
	local o = {}
	setmetatable(o,LMonopolyData)	
	o:ctor()
	return o
end

function LMonopolyData:ctor()
	self.timediff = 0  --倒计时
	self.exp = 0	--经验
	self.coin = 0	--金币
	self.gold = 0	--元宝
	self.roll_max = 0 --
	self.roll_use = 0
	self.monster_num = 0
	self.kill_monster = 0
	self.cellnum = 0 --格子总数
	self.curPos = 1 --当前所在位置
	self.cellData = {}
	self.isMonopolyState = false;
end

function LMonopolyData:Reset()
	self.timediff = 0  --倒计时
	self.exp = 0	--经验
	self.coin = 0	--金币
	self.gold = 0	--元宝
	self.roll_max = 0 --
	self.roll_use = 0
	self.monster_num = 0
	self.kill_monster = 0
	self.cellnum = 0 --格子总数
	self.curPos = 1 --当前所在位置
	self.cellData = {}
	self.isMonopolyState = false;
end

function LMonopolyData:Delete()
	self.timediff = nil  --倒计时
	self.exp = nil	--经验
	self.coin = nil	--金币
	self.gold = nil	--元宝
	self.roll_max = nil --投掷次数
	self.roll_use = nil	--已经是有次数
	self.monster_num = nil
	self.kill_monster = nil
	self.cellnum = nil --格子总数
	self.curPos = nil
	self.cellData = nil
	self.isMonopolyState = nil
end

--格子数据
LMonopolyCellData = {}
LMonopolyCellData.__index = LMonopolyCellData
function LMonopolyCellData:New()
	local o = {}
	setmetatable(o,LMonopolyCellData)	
	o:ctor()
	return o
end

function LMonopolyCellData:ctor()
	self.cellid = 1  	--格子索引
	self.eventid = 0	--事件ID
	self.eventnum = 0	--
--eventid == 2 才有值
	self.userid = 0
	self.career = 0
	self.weapen = 0
	self.effect = 0
	self.name = ""
	self.power = 0
	self.awardInfo = {}
end
function LMonopolyCellData:Delete()
	self.cellid = nil  	--格子索引
	self.eventid = nil	--事件ID
	self.eventnum = nil	--数量
--eventid == 2 才有值
	self.userid = nil
	self.career = nil
	self.weapen = nil
	self.effect = nil
	self.name = nil
	self.power = nil
	self.awardInfo = nil
end
