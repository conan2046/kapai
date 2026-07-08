LNpcChatData = {}
LNpcChatData.__index = LNpcChatData
function LNpcChatData:New()
	local o = {}
	setmetatable(o,LNpcChatData)	
	o:ctor()
	return o
end

function LNpcChatData:ctor()
	self.Name = ""                --NPC名字
	self.Desc = ""                --详细
	self.Text = {}       --选项
	self.TextIndex = {}  --索引
	self.type = 0       --说话的类型是0-NPC,1-玩家,2-怪物,3坐骑,9-空白 4-多人闯关对话
	self.picId = 0      --图片ID
	self.op = 0        --状态 1-开始 2-对话过程中 3-结束 
	self.prof = 0		--职业
	self.monopolyChatData = LMonopolyChatData:New() --闯关对话框数据
end

function LNpcChatData:Delete()
	self.Name = nil               --NPC名字
	self.Desc = nil              --详细
	local cnt = #self.Text
	for i = 1, cnt do
		self.Text[i] = nil
	end
	self.Text = nil       --选项
	cnt = #self.TextIndex
	for i = 1, cnt do
		self.TextIndex[i] = nil
	end
	self.TextIndex = nil  --索引
	self.type = nil       --说话的类型是0-NPC,1-玩家,2-怪物,3坐骑,9-空白
	self.picId = nil      --图片ID
	self.op = nil        --状态 1-开始 2-对话过程中 3-结束 
	self.prof = nil
	self.monopolyChatData = nil
end



LMonopolyChatData = {}
LMonopolyChatData.__index = LMonopolyChatData
function LMonopolyChatData:New()
	local o = {}
	setmetatable(o,LMonopolyChatData)	
	o:ctor()
	return o
end

function LMonopolyChatData:ctor()
	self.id = 0                --挑战者名字
	self.power = 0             --推荐战力
	self.awardType = 0        	--奖励类型
	self.awardNum = 0  			--奖励数量
end

function LMonopolyChatData:Delete()
	self.id = nil                --挑战者名字
	self.power = nil             --推荐战力
	self.awardType = nil       	--奖励类型
	self.awardNum = nil		--奖励数量
end
