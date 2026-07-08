LNetManager = LManagerBase:New()
LNetManager.__index = LNetManager
LNetManager.m_sonMembers = {}
--local this = LNetManager
function LNetManager:New()
    local o = {}
    setmetatable(o,LNetManager)
    o.m_sonMembers = {}
    return o
end

function LNetManager:Awake()
    
end



function LNetManager:SendMsg(msg)
    --print("LNetManager:SendMsg",msg)
    if msg:GetManager() == LManagerID.LNetManager then
        self:ProcessEvent(msg)
    else--交给msgCenter处理
        LMsgCenter:SendToMsg(msg)
    end
end

function LNetManager:RegistGameObject(name, obj)
    --print("LNetManager:RegistGameObject",self,name,obj)
    if self.m_sonMembers[name] == nil then
        self.m_sonMembers = obj
    end
end

function LNetManager:UnRegistGameObject(name)
    if self:FindKey(self.m_sonMembers, name) then
        self.m_sonMembers[name] = nil
    end
end

function LNetManager:GetGameOjbect(name)
    return self.m_sonMembers[name]
end

LNetManager:Awake()