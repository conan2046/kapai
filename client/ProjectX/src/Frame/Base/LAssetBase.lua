LAssetBase = {}

LAssetBase.__index = LAssetBase

function LAssetBase:New()
	local o = {}
	setmetatable(o,LAssetBase)
	o.msgIds = {}
	return o
end

function LAssetBase:RegistSelf(script, msgs)
	LAssetManager:RegistMsg(script,msgs)
end


function LAssetBase:UnRegistSelf(script, msgs)
    LAssetManager:UnRegistMsg(script, msgs)
end

function LAssetBase:SendMsg(msg)
    LAssetManager:SendMsg(msg)
end

function LAssetBase:ProcessEvent(tmpMsg)
   --
end

function LAssetBase:Destory()
    self:UnRegistSelf(self, self.msgIds)
end

