

LAssetManager = LManagerBase:New()
LAssetManager.__index = LAssetManager
LAssetManager.m_sonMembers = {}
--local this = LAssetManager
function LAssetManager:New()
	local o = {}
	setmetatable(o,LAssetManager)
	o.m_sonMembers = {}
	return o
end

function LAssetManager:Awake()
    
end



function LAssetManager:SendMsg(msg)
    if msg:GetManager() == LManagerID.LAssetManager then
        self:ProcessEvent(msg)
    else--交给msgCenter处理
        LMsgCenter:SendToMsg(msg)
    end
end

function LAssetManager:RegistGameObject(name, obj)
    if self.m_sonMembers[name] == nil then
        self.m_sonMembers = obj
    end
end

function LAssetManager:UnRegistGameObject(name)
    if self:FindKey(self.m_sonMembers, name) then
        self.m_sonMembers[name] = nil
    end
end

function LAssetManager:GetGameOjbect(name)
    return self.m_sonMembers[name]
end

LAssetManager:Awake()