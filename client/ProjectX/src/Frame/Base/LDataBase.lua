LDataBase = {}

LDataBase.__index = LDataBase

function LDataBase:New()
	local o = {}
	setmetatable(o,LDataBase)
	o.msgIds = {}
	return o
end

function LDataBase:RegistSelf(script, msgs)
	LDataManager:RegistMsg(script,msgs)
end


function LDataBase:UnRegistSelf(script, msgs)
    LDataManager:UnRegistMsg(script, msgs)
end

function LDataBase:SendMsg(msg)
    LDataManager:SendMsg(msg)
end

function LDataBase:ProcessEvent(tmpMsg)
   --
end

function LDataBase:Destory()
    self:UnRegistSelf(self, self.msgIds)
end

