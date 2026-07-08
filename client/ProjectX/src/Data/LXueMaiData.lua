--血脉提升属性配置
LXueMaiData = {}
LXueMaiData.__index = LXueMaiData
function LXueMaiData:New()
	local o = {}
	setmetatable(o,LXueMaiData)	
	o:ctor()
	return o
end

function LXueMaiData:ctor(id)
	self.lv = 0--血脉等级
	self.exp = 0--经验
	self.data = {0,0,0,0}--血脉提升属性 0白虎1玄武2朱雀3青龙
end

function LXueMaiData:Delete()
	self.lv = nil
    self.exp = nil
	self.data = nil
end