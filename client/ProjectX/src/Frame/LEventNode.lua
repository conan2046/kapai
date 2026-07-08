--[[
lua里面的消息节点
和C#里面的差不多
]]

LEventNode = {}

LEventNode.__index = LEventNode

function LEventNode:New(script)
	local o = {}
	setmetatable(o,LEventNode)
	o.data = script
	o.next = nil
	return o
end
