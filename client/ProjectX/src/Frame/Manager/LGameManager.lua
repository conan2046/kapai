LGameManager = LManagerBase:New()
LGameManager.__index = LGameManager
LGameManager.m_sonMembers = {}
--local this = LGameManager
function LGameManager:New()
    local o = {}
    setmetatable(o,LGameManager)
    o.m_sonMembers = {}
    return o
end

function LGameManager:Awake()
    
end



function LGameManager:SendMsg(msg)
    --print("LGameManager:SendMsg")
    if msg:GetManager() == LManagerID.LGameManager then
        self:ProcessEvent(msg)
    else--交给msgCenter处理
        LMsgCenter:SendToMsg(msg)
    end
end

function LGameManager:RegistGameObject(name, obj)
    --print("LGameManager:RegistGameObject",self,name,obj)
    if self.m_sonMembers[name] == nil then
        self.m_sonMembers = obj
    end
end

function LGameManager:UnRegistGameObject(name)
    if self:FindKey(self.m_sonMembers, name) then
        self.m_sonMembers[name] = nil
    end
end

function LGameManager:GetGameOjbect(name)
    return self.m_sonMembers[name]
end

LGameManager:Awake()