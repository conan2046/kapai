local RedDotItem = {}
RedDotItem.__index = RedDotItem
--[[
isShow = false,--是否显示红点
id = 0,--Id
items = {},--子节点列表
parent = nil,--父节点
]]
function RedDotItem:New(id)
    local o = {}
    setmetatable(o, RedDotItem)
    o:init(id)
    return o
end

function RedDotItem:init(id)
	self.id = id
	self.items = {}
	self.isShow = false
	self.parent = nil
end

function RedDotItem:onExit()
	self.id = nil
	for k,v in pairs(self.items) do
		if self.items[k] and self.items[k].onExit then
			self.items[k]:onExit()
		end
		self.items[k] = nil
	end
	self.items = nil
	self.isShow = false
	self.parent = nil
end

function RedDotItem:setParent(parent)
	if self.parent ~= nil or parent == nil then
		return
	end
	self.parent = parent
end

function RedDotItem:addChild(pChild)
	if pChild == nil or pChild.parent ~= nil then
		return
	end
	for i=1,#self.items do
		if self.items[i].id == pChild.id then
			return
		end
	end
	table.insert(self.items, pChild)
	if pChild.isShow then
		self.isShow = true
	end
	pChild:setParent(self)
end

function RedDotItem:isShown()
	return self.isShow
end

function RedDotItem:setShown(val, list)
	----------------------------------------
	if self.isShow == val then
		return list
	end
	self.isShow = val
	----------------------------------------
	function _UpdateParentShow(vec)
		if self.parent == nil then
			return
		end
		if self:isShown() then--false to true
			if self.parent:isShown() then
				return
			else
				self.parent:setShown(true, vec)
			end
		else--true to false
			for i=1,#self.parent.items do
				local pChild = self.parent.items[i]
				if pChild:isShown() then
					return
				end
			end
			self.parent:setShown(false, vec)
		end
	end
	----------------------------------------
	list = list or {}
	table.insert(list, self.id)
	_UpdateParentShow(list)
	return list
end

function RedDotItem:Reset()
	self.isShow = false
	for i=1,#self.parent.items do
		self.parent.items[i]:Reset()
	end
end

return RedDotItem