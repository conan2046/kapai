LNetBase = {}

LNetBase.__index = LNetBase

function LNetBase:New()
	local o = {}
	setmetatable(o,LNetBase)
	o.msgIds = {}
	return o
end

function LNetBase:RegistSelf(script, msgs)
	LNetManager:RegistMsg(script,msgs)
end


function LNetBase:UnRegistSelf(script, msgs)
    LNetManager:UnRegistMsg(script, msgs)
end

function LNetBase:SendMsg(msg)
	--print("LNetBase:SendMsg")
    LNetManager:SendMsg(msg)
end

function LNetBase:ProcessEvent(tmpMsg)
   --
end

function LNetBase:Destory()
    self:UnRegistSelf(self, self.msgIds)
end

