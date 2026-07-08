local ObjectPool = {}
ObjectPool.__index = ObjectPool

function ObjectPool:New(obj)
    if obj == nil then
        return nil
    end
    local o = {}
    setmetatable(o, ObjectPool)
    o:Init(obj)
    return o
end

function ObjectPool:Init(obj)
    self.m_object = obj
    obj:retain()
    self.m_free = {}
    self.m_used = {}
end

local function freeAll(arr)
    for i=1,#arr do
        if arr[i] ~= nil then
            arr[i]:release()
            arr[i] = nil
        end
    end
end

function ObjectPool:onExit()
    freeAll(self.m_free)
    freeAll(self.m_used)
    self.m_object:release()
end

function ObjectPool:Create()
    local obj = self.m_object:clone()
    if obj ~= nil then
        obj:retain()
        table.insert(self.m_free, obj)
    end
end

function ObjectPool:Push(obj)
    if obj == nil or type(obj) ~= "userdata" then
        return
    end
    for i=1,#self.m_used do
        if self.m_used[i] == obj then
            table.remove(self.m_used, i)
            break
        end
    end
    if obj:getParent() ~= nil then
        obj:removeFromParent(false)
    end
    table.insert(self.m_free, obj)
end

function ObjectPool:Pop()
    if #self.m_free == 0 then
        self:Create()
    end
    if #self.m_free == 0 then
        return nil
    end
    local obj = self.m_free[#self.m_free]
    table.insert(self.m_used, obj)
    table.remove(self.m_free, #self.m_free)
    return obj
end

function ObjectPool:GetUsed()
    return self.m_used
end

return ObjectPool