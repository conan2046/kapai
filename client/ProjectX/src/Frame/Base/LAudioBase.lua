LAudioBase = {}

LAudioBase.__index = LAudioBase

function LAudioBase:New()
	local o = {}
	setmetatable(o,LAudioBase)
	o.msgIds = {}
	return o
end

function LAudioBase:RegistSelf(script, msgs)
	LAudioManager:RegistMsg(script,msgs)
end


function LAudioBase:UnRegistSelf(script, msgs)
    LAudioManager:UnRegistMsg(script, msgs)
end

function LAudioBase:SendMsg(msg)
    LAudioManager:SendMsg(msg)
end

function LAudioBase:ProcessEvent(tmpMsg)
   --
end

function LAudioBase:Destory()
    self:UnRegistSelf(self, self.msgIds)
end

