--[[
消息存储和处理基类
]]

LManagerBase = {}
LManagerBase.__index = LManagerBase
function LManagerBase:New()
	local o = {}
	setmetatable(o,LManagerBase)
	o.eventTree = {}
	return o
end

--[[查找键值]]
function LManagerBase:FindKey(dict,key)
	for k,v in pairs(dict) do
		if k == key then
			return true
		end
	end
	return false
end

--[[
注册一条消息
]]
function LManagerBase:RegistMsgWithNode(id,eventNode)
	--if not self:FindKey(self.eventTree, id) then
    if self.eventTree[id] == nil then
		self.eventTree[id] = eventNode
	else
		local tmp = self.eventTree[id];
        --加到链表最后
        while tmp.next ~= nil do
            tmp = tmp.next
        end
        tmp.next = eventNode
	end
end

--[[
注册多条消息
@param1:各种Base脚本
@param2:消息数组
]]
function LManagerBase:RegistMsg(script,msgs)
	for i, v in pairs(msgs) do
	    local tmp = LEventNode:New(script)
	    self:RegistMsgWithNode(v,tmp)
    end
end

function LManagerBase:PrintKey()
    -- local num = 0
    -- for k,v in pairs(self.eventTree) do
    --     num = num + 1
    --     -- print("key=",k,"value=",v)
    -- end
    -- print("KeyNum=",num)
end

function LManagerBase:PrintNode(msgId)
    if self.eventTree[msgId] == nil then
        print("msgId=",msgId,"Num=0")
        return
    end
    local num = 1
    local tmp = self.eventTree[msgId];
    --加到链表最后
    while tmp.next ~= nil do
        tmp = tmp.next
        num = num + 1
    end
    print("msgId=",msgId,"Num=",num)
    tmp.next = eventNode
end

function LManagerBase:UnRegistOneMsg(id, script)
    --if not self:FindKey(self.eventTree, id) then
    if self.eventTree[id] == nil then
    	print("not contain id = " .. id)
        return
    else
        local tmp = self.eventTree[id];
        
        if tmp.data == script then--刚好在头部
            if tmp.next ~= nil then
                self.eventTree[id] = tmp.next
                tmp.next = nil
            else
            	--table.remove(self.eventTree,id)
                self.eventTree[id] = nil
                --self.eventTree.Remove(id)
            end
            tmp = nil
        else--在尾部或者中间
            while tmp.next ~= nil and tmp.next.data ~= script do
                tmp = tmp.next
            end--已经找到该节点的父节点

            --没有引用 会自动释放
            if tmp.next.next ~= nil then--去掉中间的
            	local curNode = tmp.next
                tmp.next = curNode.next
                curNode.next = nil
            else --去掉尾部的
                tmp.next = nil
            end
            tmp = nil
        end
    end
end

function LManagerBase:UnRegistMsg(script, msgs)
	if msgs == nil then--arg等于...
		return
	end
	for i, v in pairs(msgs) do
		self:UnRegistOneMsg(v, script);
	end
end

function LManagerBase:Destory()
    local tmpKeys = {}
    for k,v in pairs(self.eventTree) do
		table.insert(tmpKeys, k)
    end

    for i = 1,#(tmpKeys) do
    	self.eventTree[tmpKeys[i]] = nil
    end
end

--[[
处理消息
]]
function LManagerBase:ProcessEvent(tmpMsg)
	--if not self:FindKey(self.eventTree, tmpMsg:GetMsgId()) then
    local msgId = tmpMsg:GetMsgId()
    if self.eventTree[msgId] == nil then
        --print("not contain msg = " .. tmpMsg:GetMsgId())
        return
    else
    	local tmpNode = self.eventTree[msgId]
    	while tmpNode ~= nil do
    		tmpNode.data:ProcessEvent(tmpMsg)
    		tmpNode = tmpNode.next
    	end
    end
end