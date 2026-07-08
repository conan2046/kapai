
--[[
初始化服务器数据消息结构
]]
LAnalysisNetStreamMsg = LMsgBase:New()
LAnalysisNetStreamMsg.__index = LAnalysisNetStreamMsg
function LAnalysisNetStreamMsg:New(msgid, stream)
    local o = LMsgBase:New(msgid)
    setmetatable(o,LAnalysisNetStreamMsg)
    o.m_pStream = stream
    return o
end

function LAnalysisNetStreamMsg:Change(msgid, stream)
	self.msgId = msgid
	self.m_pStream = stream
end

--[[
获取服务器数据的消息
]]
LServerGetDataMsg = LMsgBase:New()
LServerGetDataMsg.__index = LServerGetDataMsg
function LServerGetDataMsg:New(msgid)
    local o = LMsgBase:New(msgid)
    setmetatable(o,LServerGetDataMsg)
    return o
end

function LServerGetDataMsg:Change(backid)
	self.backId = backid
end

LServerGetDataBackMsg = LMsgBase:New()
LServerGetDataBackMsg.__index = LServerGetDataBackMsg
function LServerGetDataBackMsg:New(msgid)
    local o = LMsgBase:New(msgid)
    setmetatable(o,LServerGetDataBackMsg)
    return o
end

function LServerGetDataBackMsg:Change(backid, qulist, tuijianlist, serverlist)
	self.msgId = backid
	self.m_pQuList = qulist
	self.m_pTuijianList = tuijianlist
	self.m_pServerList = serverlist
end

LPartnerGetDataBackMsg = LMsgBase:New()
LPartnerGetDataBackMsg.__index = LPartnerGetDataBackMsg
function LPartnerGetDataBackMsg:New(msgid)
    local o = LMsgBase:New(msgid)
    setmetatable(o,LPartnerGetDataBackMsg)
    return o
end

function LPartnerGetDataBackMsg:Change(backid, data,data1)
    self.msgId = backid
    self.m_pdata = data
    self.m_pdata1 = data1
end

--[[
获取任务
]]
LTaskGetDataMsg = LMsgBase:New()
LTaskGetDataMsg.__index = LTaskGetDataMsg
function LTaskGetDataMsg:New(msgid)
    local o = LMsgBase:New(msgid)
    setmetatable(o,LTaskGetDataMsg)
    return o
end

function LTaskGetDataMsg:Change(msgid,stream)
    self.msgId = msgid
    self.m_pStream = stream
end

--资源加载消息
LResMsg = LMsgBase:New()
LResMsg.__index = LResMsg
--[[
@param1:msgid消息号
@param2:filePath 资源路径
@param3:加载成功后回调
]]
function LResMsg:New(msgid, filePath, callback)
    local o = LMsgBase:New(msgid)
    setmetatable(o,LResMsg)
    o:Change(msgid, filePath, callback)
    return o
end
--[[
@param1:msgid消息号
@param2:filePath 资源路径
@param3:加载成功后回调
]]
function LResMsg:Change(msgid, filePath, func, pNode)
    self.msgId = msgid
    self.filePath = filePath
    self.callback = func
    self.node = pNode
end




