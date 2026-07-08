LUIManager = LManagerBase:New()
LUIManager.__index = LUIManager
LUIManager.m_sonMembers = {}
--local this = LUIManager
function LUIManager:New()
	local o = {}
	setmetatable(o,LUIManager)
	o.m_sonMembers = {}
	return o
end

function LUIManager:Awake()
    
end



function LUIManager:SendMsg(msg)
    if msg:GetManager() == LManagerID.LUIManager then
        self:ProcessEvent(msg)
    else--交给msgCenter处理
        LMsgCenter:SendToMsg(msg)
    end
end

function LUIManager:RegistGameObject(name, obj)
    --print("LUIManager:RegistGameObject",self,name,obj)
    -- if self.m_sonMembers[name] == nil then
    --     self.m_sonMembers[name] = obj
    -- end
    self.m_sonMembers[name] = obj
end

function LUIManager:UnRegistGameObject(name)
    self.m_sonMembers[name] = nil
    -- if self:FindKey(self.m_sonMembers, name) then
    --     self.m_sonMembers[name] = nil
    -- end
end

function LUIManager:UnRegistAllGameObject(names)
    for i = 0,names.Length - 1 do
        self.m_sonMembers[names[i]] = nil
    end
    
    -- if self:FindKey(self.m_sonMembers, name) then
    --     self.m_sonMembers[name] = nil
    -- end
end

function LUIManager:GetGameOjbect(name)
    return self.m_sonMembers[name]
end

LUIManager:Awake()