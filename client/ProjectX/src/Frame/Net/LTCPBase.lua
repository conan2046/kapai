LTCPBase = {}
LTCPBase.__index = LTCPBase
local this = LTCPBase
function LTCPBase:New(msgid)
	local o = {}
	setmetatable(o,LTCPBase)
	o.msgId = msgid
	return o
end

function LTCPBase.Awake(msg)
	LuaAndCMsgCenters.Instance:SettingLuaCallBack(this.RecvMsg)
end

this.Awake()

function LTCPBase.GetInstance()
	return this
end