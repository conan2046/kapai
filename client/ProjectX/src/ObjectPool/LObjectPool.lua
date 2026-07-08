--[[
lua table对象池
]]
LObjectPool = {}
LObjectPool.__index = LObjectPool

function LObjectPool.New(actionGet, actionRelease)
	local o = {}
	setmetatable(o,LObjectPool)
	o:ctor(actionGet, actionRelease)
	return o
end

function LObjectPool:ctor(actionGet, actionRelease)
	self.m_Stack = {}
	self.m_ActionOnGet = actionGet;
    self.m_ActionOnRelease = actionRelease;
end

function LObjectPool:Get()
	if #self.m_Stack == 0 then
		return nil
	end
	local tmp = self.m_Stack[#self.m_Stack]
	table.remove(self.m_Stack, #self.m_Stack)
    if self.m_ActionOnGet ~= nil then
        self.m_ActionOnGet(tmp);
    end
    return tmp;
end

function LObjectPool.ReferenceEquals(stack, obj)
	for i = 1, #stack do
		if stack[i] == obj then
			return true
		end
	end
	return false
end

function LObjectPool:Release(element)
    if #self.m_Stack > 0 and self:ReferenceEquals(self.m_Stack, element) == true then
        logError("Internal error. Trying to destroy object that is already released to pool.");
    end
    if self.m_ActionOnRelease ~= nil then
        self.m_ActionOnRelease(element);
    end
    table.insert(self.m_Stack,element);
end