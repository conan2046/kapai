--[[
lua版本的消息基础结构
]]
LMsgBase = {msgId = 0}

LMsgBase.__index = LMsgBase

function LMsgBase:New(msgid)
	local o = {}
	setmetatable(o,LMsgBase)
	o.msgId = msgid
	return o
end

function LMsgBase:GetManager()
    local tmpId = math.floor(self.msgId / MsgSpan) * MsgSpan
    return math.ceil(tmpId)
end

--[[
修改消息id
]]
function LMsgBase:ChangeEventId(id)
    self.msgId = id
end

function LMsgBase:GetMsgId()
	return self.msgId
end

function LMsgBase:GetState()
	return 127
end