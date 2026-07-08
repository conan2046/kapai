LMisstionDialog = {}
LMisstionDialog.__index = LMisstionDialog
function LMisstionDialog:New()
	local o = {}
	setmetatable(o,LMisstionDialog)	
	o:ctor()
	return o
end

function LMisstionDialog:ctor()
	self.dialogid = 0
	self.order = 0
	self.npcid = 0
	self.position = 0 --1 左边 2 右边
	self.dialog = ""
	self.scale = 0      --立绘缩放
	self.speed = 0        --文字弹出速度
	self.delay = 0		--延迟时间
	self.showskip = 0 --0 不显示 1 显示
end

function LMisstionDialog:Delete()
	self.dialogid = nil
	self.order = nil
	self.npcid = nil
	self.position = nil --1 左边 2 右边
	self.dialog = nil
	self.scale = nil      --立绘缩放
	self.speed = nil        --文字弹出速度
	self.delay = nil		--延迟时间
	self.showskip = nil --0 不显示 1 显示
end