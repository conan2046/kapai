

LDataManager = LManagerBase:New()
LDataManager.__index = LDataManager
LDataManager.m_sonMembers = {}
--local this = LDataManager
function LDataManager:New()
	local o = {}
	setmetatable(o,LDataManager)
	o.m_sonMembers = {}
	return o
end

function LDataManager:Awake()
    
end



function LDataManager:SendMsg(msg)
    if msg:GetManager() == LManagerID.LDataManager then
        self:ProcessEvent(msg)
    else--交给msgCenter处理
        LMsgCenter:SendToMsg(msg)
    end
end

function LDataManager:RegistGameObject(name, obj)
    if self.m_sonMembers[name] == nil then
        self.m_sonMembers = obj
    end
end

function LDataManager:UnRegistGameObject(name)
    if self:FindKey(self.m_sonMembers, name) then
        self.m_sonMembers[name] = nil
    end
end

function LDataManager:GetGameOjbect(name)
    return self.m_sonMembers[name]
end

LDataManager:Awake()