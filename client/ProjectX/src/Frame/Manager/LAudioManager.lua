

LAudioManager = LManagerBase:New()
LAudioManager.__index = LAudioManager
LAudioManager.m_sonMembers = {}
--local this = LAudioManager
function LAudioManager:New()
	local o = {}
	setmetatable(o,LAudioManager)
	o.m_sonMembers = {}
	return o
end

function LAudioManager:Awake()
    
end



function LAudioManager:SendMsg(msg)
    if msg:GetManager() == LManagerID.LAudioManager then
        self:ProcessEvent(msg)
    else--交给msgCenter处理
        LMsgCenter:SendToMsg(msg)
    end
end

function LAudioManager:RegistGameObject(name, obj)
    if self.m_sonMembers[name] == nil then
        self.m_sonMembers = obj
    end
end

function LAudioManager:UnRegistGameObject(name)
    if self:FindKey(self.m_sonMembers, name) then
        self.m_sonMembers[name] = nil
    end
end

function LAudioManager:GetGameOjbect(name)
    return self.m_sonMembers[name]
end

LAudioManager:Awake()