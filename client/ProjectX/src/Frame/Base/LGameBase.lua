LGameBase = {}

LGameBase.__index = LGameBase

function LGameBase:New()
    print("LGameBase:New")
	local o = {}
	setmetatable(o,LGameBase)
	o.msgIds = {}
	return o
end

function LGameBase:RegistSelf(script, msgs)
	LGameManager:RegistMsg(script,msgs)
end


function LGameBase:UnRegistSelf(script, msgs)
    LGameManager:UnRegistMsg(script, msgs)
end

function LGameBase:SendMsg(msg)
    LGameManager:SendMsg(msg)
end

function LGameBase:ProcessEvent(tmpMsg)
   --
end

function LGameBase:Destory()
    self:UnRegistSelf(self, self.msgIds)
end

