--[[
   离线
]]
LOnLineData = {}
LOnLineData.__index = LOnLineData
function LOnLineData:New()
	local o = {}
	setmetatable(o,LOnLineData)	
	o:ctor()
	return o
end
function LOnLineData:ctor()
	self.ind=0    -- 当前奖励
	self.curtime=0 --剩余时间
	self.state=0 --完成
end
function LOnLineData:UpdateData(data)
	self.ind=data.ind    -- 当前奖励
	self.curtime=data.time --剩余时间
end
function LOnLineData:CheckIsGet(ind)
	if ind<self.ind then
        return true
	end
	return false
end
function LOnLineData:IsCanGet()
	if self.curtime<=0 then
		return true
	end
	return false
	-- body
end
function LOnLineData:SubTime()
	self.curtime=self.curtime-1
	if self.curtime<=0 then
       self.curtime=0   
	end
	-- body
end
function LOnLineData:GetReward()
	local OLConfig = JsonConfig.m_OnLineConfig
	local tempData = OLConfig.getDefByID(self.ind)
	local lastTime = 0
	if tempData then
       lastTime=tempData.time
	end
	self.ind=self.ind+1
	
	local data =OLConfig.getDefByID(self.ind)
	if data then
		self.curtime=(data.time-lastTime)*60
	end
	
end

