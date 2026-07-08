--[[
UI初始化的消息
]]
LTcpConnectMsg = LMsgBase:New()
LTcpConnectMsg.__index = LTcpConnectMsg
function LTcpConnectMsg:New(msgid, backId, ip, port)
    local o = LMsgBase:New(msgid)
    setmetatable(o,LTcpConnectMsg)
    o.msgId = msgid
    o.backId = backId
    o.ip = ip
    o.port = port
    return o
end

function LTcpConnectMsg:Change(msgid, backId, ip, port)
	self.msgId = msgid
    self.backId = backId
    self.ip = ip
    self.port = port
end

LTcpSessionMsg = LMsgBase:New()
LTcpSessionMsg.__index = LTcpSessionMsg
function LTcpSessionMsg:New(msgid, openid, openSession)
    local o = LMsgBase:New(msgid)
    setmetatable(o,LTcpSessionMsg)
    o.msgId = msgid
    o.openid = openid
    o.openSession = openSession
    return o
end

function LTcpSessionMsg:Change(msgid, openid, openSession)
	self.msgId = msgid
    self.openid = openid
    self.openSession = openSession
end