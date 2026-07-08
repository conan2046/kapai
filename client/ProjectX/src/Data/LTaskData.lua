
--任务追踪信息
LCardTaskData = {}
LCardTaskData.__index = LCardTaskData
function LCardTaskData:New()
	local o = {}
	setmetatable(o, LCardTaskData)	
	o:Init()
	return o
end

function LCardTaskData:Init()
	self.task_id = 0            --任务Id
	self.taskActiveNum = 0            --任务条件（达成条件的数量）
	self.state = 0              -- 1 达成 0 未达成
end

function LCardTaskData:Delete()
	self.task_id = nil            --任务Id
	self.taskActiveNum = nil            --任务条件（达成条件的数量）
	self.state = nil              -- 1 达成 0 未达成
end