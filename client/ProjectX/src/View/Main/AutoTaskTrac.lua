--[[
单人玩法一条龙自动做任务
]]
local AutoTaskTrac = LUIBase:New()
AutoTaskTrac.__index = AutoTaskTrac

function AutoTaskTrac:New(taskView)
	local o = LUIBase:New()
	setmetatable(o, AutoTaskTrac)	
    o:Init(taskView)
	return o
end

--[[
注册消息
]]
function AutoTaskTrac:RegistMsgs()
    self.msgIds = 
    {
        LUITaskDataEvent.afterDeleteOneTask,
        LUILogicEvent.ExitBattle,
        LUIMainEvent.ChangeDayMsg,
    }
    self:RegistSelf(self,self.msgIds)
end

function AutoTaskTrac:ProcessEvent(msg)
    if msg.msgId == LUITaskDataEvent.afterDeleteOneTask then
    	self:execAutoTask(msg.value)
    elseif msg.msgId == LUILogicEvent.ExitBattle then
    	if LRechargeDataMgr.needAutoTask then
    		--print("exit battle **********************************", LRechargeDataMgr.autoTaskId)
    		if LRechargeDataMgr.autoTaskId > 0 then
    			self:execAutoTask(LRechargeDataMgr.autoTaskId)
    		end

            LRechargeDataMgr.autoTaskId = 0
            LRechargeDataMgr.needAutoTask = false
    	end
    elseif msg.msgId == LUIMainEvent.ChangeDayMsg then
    	self._completeTaskArr = {}
    end
end

function AutoTaskTrac:Init(taskView)
	self:RegistMsgs()
	self._taskView = taskView
	-- body
	--师门,周历练,杀敌夺宝,维护丹园,寻宝任务
	self._autoTaskId = {101, 106, 104, 103, 102}
	self._completeTaskArr = {}
	self:loadData()
end

function AutoTaskTrac:loadData( data )
	-- dump(self._taskView.m_pTaskCells, "CheckHasTask")
	for i=1, #self._autoTaskId do
		local idTemp = self._autoTaskId[i]
		local aTask = LRoleDataMgr.Task:GetTaskById(idTemp)
		----print("loadData ---", idTemp)
--		dump(aTask, "CheckHasTask ++++++")
		local aTask = LRoleDataMgr.Task:GetTaskById(idTemp)
    	if aTask ~= nil then
    		local state = self._taskView.getTaskState(aTask)
			if state <= 0 then
				if not self:isTaskAlreadyComplate(idTemp, self._completeTaskArr) then
					table.insert(self._completeTaskArr, idTemp)
				end
			end
    	end
	end
end

function AutoTaskTrac:CheckHasTask(taskId)
	for i = 1, #self._taskView.m_pTaskCells do
        if self._taskView.m_pTaskCells[i][1] == taskId then
        	return true
        end
    end
    return false
end

function AutoTaskTrac:findNextAutoTask(id)
	-- body
	if #self._completeTaskArr >= #self._autoTaskId then
		return 0
	end

	local idx = 0
	for i=1, #self._autoTaskId do
	 	if self._autoTaskId[i] == id then
	 		idx = i
	 	end
	end

	if idx < 1 then
		return 0
	end

	local nextIdx = 0
	if idx >= 2 then
		for i=1, idx - 1 do
			local idTemp = self._autoTaskId[i]
			if not self:isTaskAlreadyComplate(idTemp, self._completeTaskArr) then
				local aTask = LRoleDataMgr.Task:GetTaskById(idTemp)
				if aTask ~= nil then
					local state = self._taskView.getTaskState(aTask)
					if state > 0 then
						nextIdx = i
						break
					end
				end
			end
		end
	end
	--print("findNextAutoTask idx ======>", idx, nextIdx)

	if nextIdx < 1 then
		if not self:isTaskAlreadyComplate(id, self._completeTaskArr) then
			table.insert(self._completeTaskArr, id)
		end
	end

	--当前索引以前没有没有没完成的任务向下走
	if nextIdx < 1 or nextIdx == idx then
		nextIdx = idx + 1
	end


	--print("findNextAutoTask nextIdx ======>", nextIdx, idx)
	if nextIdx > #self._autoTaskId then
		return 0
	end

	local nextId = self._autoTaskId[nextIdx]
	if self:isTaskAlreadyComplate(nextId, self._completeTaskArr) or self:isTaskFinished(nextId) then
		nextId = self:findNextAutoTask(nextId)
		--print("findNextAutoTask ID ===>>>", nextId)
	end
	return nextId
end

function AutoTaskTrac:isTaskFinished(id)
	-- body
	local aTask = LRoleDataMgr.Task:GetTaskById(id)
	if aTask ~= nil then
		local state = self._taskView.getTaskState(aTask)
		return state <= 0
	end
	return true
end


function AutoTaskTrac:isTaskAlreadyComplate( id, list )
	-- body
	if list == nil then
		return false
	end

	for i=1, #list do
		if list[i] == id then
			return true
		end
	end
	return false

end

function AutoTaskTrac:CheckNextTask(id)
	-- body
	local nextId = self:findNextAutoTask(id)
	--print("CheckNextTask ======>", nextId, id)
	if nextId > 0 then
		--print("begin click next id")
		Utils:SendMsg(LUITaskDataEvent.ClickTask, nextId, true)
	end
	
end

function AutoTaskTrac:getTaskCellIndexById(id)
	-- body
	local idx = 0
	for i=1, #self._taskView.m_pTaskCells do
		if self._taskView.m_pTaskCells[i][1] == id then
			idx = i
			break
		end
	end
	return idx
end

function AutoTaskTrac:execAutoTask(id)
	-- body
	local taskId = id
	--print("AutoTaskTrac taskId 1111111111111111", taskId)
	local aTask = LRoleDataMgr.Task:GetTaskById(taskId)
	if aTask == nil then
		--print("AutoTaskTrac taskId 3333333333333333", taskId)
		self:CheckNextTask(taskId)
		return
	end

--    	dump(aTask, "ProcessEvent aTask ProcessEvent")
	local state = self._taskView.getTaskState(aTask)
	--print("ProcessEvent state", state)
	if state > 0 then
		return
	end
	--print("AutoTaskTrac taskId 22222222222222222222", taskId)
	self:CheckNextTask(taskId)
end

function AutoTaskTrac:onExit()
    self:Destory()
end

return AutoTaskTrac