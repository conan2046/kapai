local CurGuideStepId = 0--当前引导Id

local GuideManager = LUIBase:New()
GuideManager.__index = GuideManager
-------------------------------------
function GuideManager:New()
    local o = {}
    setmetatable(o, GuideManager)
    o:Init()
    return o
end
-------------------------------------
function GuideManager:Init()
	---------------------------------
	self.m_guideMap = {}
	self.m_guideVec = {}
	self.m_isStartCheck = false --收到已完成引导列表数据之后才能开始检测引导
	---------------------------------
	self:RegistMsgs()
	self:InitViewSize()
	self:setCloseCallback()
	--self:LoadGuideCache()
end

-------------------------------------
function GuideManager:InitViewSize()
    self.m_pUILayer = cc.Node:create()
end

function GuideManager:onExit()
    self:Destory()
    CurGuideStepId = 0
    self.m_pUILayer = nil
end

function GuideManager:RegistMsgs()
    self.msgIds = {
    	LUIGuideEvent.RegisterStep,
    	LUIGuideEvent.GuideComplete,
    	LUIGuideEvent.CheckGuideStep,
    	LUIFunctionEvent.FunctionOpen,
    	LUIFunctionEvent.FunctionFly,
    	LUILogicEvent.GetSettingStringInfo,
    	LUITaskDataEvent.DeleteOneTask,
    	LUITaskDataEvent.AddOneTask,
    	LUITaskDataEvent.GetCompletedTask,
    	LUIGuideEvent.UnRegisterStep,
    	LUIRoleDataChangeEvent.ChangeUser,
        LUIRoleDataChangeEvent.LvUp,
    }

    self:RegistSelf(self, self.msgIds)
end
--[[
msg = {
	stepId = 步骤Id
	callback = 点击回调
	pNode = 手点击的节点
	pos = 节点在世界坐标系的位置
}
]]
-------------------------------------
function GuideManager:ProcessEvent(msg)
	local function getScriptName(script)
		local index = string.find(script, "%.")
		local uiName = string.sub(script, index + 1)
		return uiName
	end
	if msg.msgId == LUIGuideEvent.RegisterStep then
		self:registerGuide(msg.value)
	elseif msg.msgId == LUIGuideEvent.UnRegisterStep then
		self:unRegisterGuide(msg.value)
	elseif msg.msgId == LUIGuideEvent.GuideComplete then
		self:checkNextStep(msg.value)
	elseif msg.msgId == LUIGuideEvent.CheckGuideStep then
		self:checkGuideStep(msg.value[1], msg.value[2])
	elseif msg.msgId == LUIFunctionEvent.FunctionOpen then
		self:checkFunctionGuide(msg.value[1], msg.value[3])
	elseif msg.msgId == LUIFunctionEvent.FunctionFly then
		self:checkFunctionGuide({[msg.value]=true})
	elseif msg.msgId == LUILogicEvent.GetSettingStringInfo then
		self:dealServerData(true)
	elseif msg.msgId == LUITaskDataEvent.DeleteOneTask then
		local taskId = msg.value
		if LRoleDataMgr.Task:isTaskComplete(taskId) then
			self:checkTaskGuide(taskId, GuideDef.Type.CompleteTask)
		end
	elseif msg.msgId == LUITaskDataEvent.AddOneTask then
		local taskId = msg.value
		if not LRoleDataMgr.Task:isTaskComplete(taskId) then
			self:checkTaskGuide(taskId, GuideDef.Type.StartTask)
		end
	-- elseif msg.msgId == LUITaskDataEvent.GetCompletedTask then
	elseif msg.msgId == LUIRoleDataChangeEvent.ChangeUser then
		self.m_isStartCheck = false
    elseif msg.msgId == LUIRoleDataChangeEvent.LvUp then
        --print("LUIRoleDataChangeEvent.LvUp &&",msg.value)
        if msg.value == 8 or msg.value == 10 or msg.value == 15 or msg.value == 35 then
            self:SetCurGuideId(0)
        end
	end
end
-------------------------------------
function GuideManager:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
-------------------------------------
function GuideManager:registerGuide(data)
	-- dump(data)
	local isComplete = LRoleDataMgr:isGuideComplete(data.stepId, true)
	if isComplete then
		return
	end
	local pGuide = self.m_guideMap[data.stepId]
	if pGuide == nil then
		pGuide = data
		self.m_guideMap[data.stepId] = data
	else
		pGuide.pos = data.pos
		pGuide.pNode = data.pNode
		pGuide.callback = data.callback
	end
end
function GuideManager:unRegisterGuide(stepId)
	-- dump(stepId, "unRegisterGuide------>")
	if self.m_guideMap[stepId] then
		self.m_guideMap[stepId] = nil
	end
end
-------------------------------------
function GuideManager:checkNextStep(stepId)
	if stepId <= 0 then
		self:SetCurGuideId(0)
		return
	end
	local pInfo = LDataConstMgr:GetGuideData(stepId)
	if pInfo == nil then
		self:SetCurGuideId(0)
		return
	end
	local nextStepId = pInfo.nextStepId
	-- print('checkNextStep:stepId-->', stepId, 'nextStepId-->', nextStepId)
	if nextStepId == 0 and stepId ~= GuideDef.StepId.Guide_FuBen3_Finish then
		--如果是大步骤立即完成，就发送完成协议到服务端
		LRoleDataMgr:setGuideComplete(stepId, true, false)
		--performWithDelay(AppDef.Director:getRunningScene(),function(sender)
		    -- LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.AutoPathEvent.ReStartAutoPath)
		    -- self:SendMsg(LGameMsg.m_cBaseMsg)
		--end, 0)
	end
	--LRoleDataMgr:QueryGuideComplete(stepId, true)
	self:SetCurGuideId(nextStepId)
    LuaNetSendMsg:QuerySetSettingInfo(AppDef.ServerSetIndex.SSI_CURRENT_GUIDE, ""..nextStepId)
    LUserConfigMgr:SetUserCurGuide(nextStepId)

	for i=1,#self.m_guideVec do
		if self.m_guideVec[i] == stepId then
			table.remove(self.m_guideVec, i)
			break
		end
	end
	self:unRegisterGuide(stepId)
	self:checkNextGuide()
end

function GuideManager:checkNextGuide()
	--print('checkNextGuide CurGuideStepId-->', CurGuideStepId)
	-- dump(self.m_guideVec)
	for i=1,#self.m_guideVec do
		if self.m_guideVec[i] == CurGuideStepId then
			self:delayStartGuideStep(CurGuideStepId)
			break
		end
	end
end

-------------------------------------
function GuideManager:checkGuideStep(stepId, isImmediately)
	--dump({stepId, LRoleDataMgr:isGuideComplete(stepId, true), CurGuideStepId},"@@@==>")
	if stepId <= 0 then
		return
	end
	if LRoleDataMgr:isGuideComplete(stepId, true) then
		return
	end
	if isImmediately then
		self:delayStartGuideStep(stepId)
		return
	end
	if (CurGuideStepId == stepId) or (CurGuideStepId == 0 and (math.fmod(stepId, 100) == 1 or stepId == GuideDef.StepId.Guide_FuBen4)) then
		if not Utils:containValue(self.m_guideVec, stepId) then
			table.insert(self.m_guideVec, stepId)
		end
	end
	if self.m_isStartCheck then
		-- print("#self.m_guideVec",#self.m_guideVec)
		-- dump(self.m_guideVec)
		if #self.m_guideVec == 1 then
			--dump(self.m_guideVec[1], 'GuideManager:checkGuideStep-->')
		    self:delayStartGuideStep(self.m_guideVec[1])
		else
			self:checkNextGuide()
		end
	end
end
--延迟一帧
function GuideManager:delayStartGuideStep(stepId)
	if LRoleDataMgr:isGuideComplete(stepId, true) then
		return
	end

	performWithDelay(self.m_pUILayer, function(sender)
		--print("------------------------------->", stepId)
		if not self:checkTaskClickGuide(stepId) then
			self:startGuideStep(stepId)
		end
	end, 1/30)
end

function GuideManager:startGuideStep(stepId)
	--dump({CurGuideStepId, stepId})
	--当前步骤
	if CurGuideStepId == stepId then
		self:showGuide(stepId)
	elseif CurGuideStepId == 0 then
		if math.fmod(stepId, 100) == 1 or stepId == GuideDef.StepId.Guide_FuBen4 then
			self:showGuide(stepId)
		end
	end
end

function GuideManager:showGuide(stepId)
	print("stepId-->", stepId)
	-- Utils:Debug(stepId)
	local data = self.m_guideMap[stepId]
	--dump(data)
	if data ~= nil then
        --Utils:SendMsg(LUIGuideEvent.PreGuide, stepId)
		if data.pNode ~= nil then
			local p = cc.p(data.pNode:getContentSize().width/2, data.pNode:getContentSize().height/2)
			data.pos = data.pNode:convertToWorldSpace(p)
		elseif data.pos ~= nil then
			local visibleSize = AppDef.Director:getVisibleSize()
			-- dump(visibleSize, "visibleSize-->")

			local pInfo = LDataConstMgr:GetGuideData(stepId)
			local towards = pInfo.sizeTowards or 0
			if towards == 1 then--左下
			elseif towards == 2 then--右下
				data.pos = cc.pAdd(cc.pSub(data.pos, cc.p(1334,0)), cc.p(visibleSize.width, 0))
			elseif towards == 3 then--中上
				data.pos = cc.pAdd(cc.pSub(data.pos, cc.p(667,750)), cc.p(visibleSize.width/2, visibleSize.height))
			elseif towards == 4 then--左上
				data.pos = cc.pAdd(cc.pSub(data.pos, cc.p(0,750)), cc.p(0, visibleSize.height))
			elseif towards == 5 then--右上
				data.pos = cc.pAdd(cc.pSub(data.pos, cc.p(1334,750)), cc.p(visibleSize.width, visibleSize.height))
			elseif towards == 6 then--中中
				data.pos = cc.pAdd(cc.pSub(data.pos, cc.p(667,375)), cc.p(visibleSize.width/2, visibleSize.height/2))
			elseif towards == 7 then--中左
				data.pos = cc.pAdd(cc.pSub(data.pos, cc.p(0,375)), cc.p(0, visibleSize.height/2))
			elseif towards == 8 then--中右
				data.pos = cc.pAdd(cc.pSub(data.pos, cc.p(1334,375)), cc.p(visibleSize.width, visibleSize.height/2))
			else--0：中下
				data.pos = cc.pAdd(cc.pSub(data.pos, cc.p(667,0)), cc.p(visibleSize.width/2, 0))
			end
		end
        Utils:SendMsg(LUILogicEvent.ShowGuide, data)
        --LUserConfigMgr:SetUserCurGuide(stepId)
        --print("showguide",stepId)
        if CurGuideStepId == 0 then
            self:SetCurGuideId(stepId)
            LUserConfigMgr:SetUserCurGuide(stepId)
            LuaNetSendMsg:QuerySetSettingInfo(AppDef.ServerSetIndex.SSI_CURRENT_GUIDE, tostring(stepId))
        end
        --stepId = math.floor(stepId / 100)
        --LuaNetSendMsg:QuerySetSettingInfo(AppDef.ServerSetIndex.SSI_CURRENT_GUIDE, tostring(stepId))
	end
end

function GuideManager:SetCurGuideId(stepId)
    CurGuideStepId = stepId			
end

function GuideManager:checkFunctionGuide(functions, newOpen)
	functions = functions or {}
	newOpen = newOpen or {}
	if #newOpen > 0 then
		return
	end
	------------------------------------------------------------------------------------------
	local newOpenTb = {}
	Utils:SendMsg(LUIFunctionEvent.GetFuncOpenList, newOpenTb, true)
    --如果存在新功能开启，就返回不处理
    for k,v in pairs(newOpenTb) do
    	return
    end
    ---------------------------------------
    for i=1,#newOpen do
    	newOpenTb[newOpen[i]] = true
    end
    ------------------------------------------------------------------------------------------
    -- print('checkFunctionGuide---------------->')
	-- dump(newOpenTb)
	-- dump(functions)
	local guideList = LDataConstMgr:GetGuideListByType(GuideDef.Type.Code)
	-- dump(guideList)
	for i=1,#guideList do
		local pInfo = guideList[i]
		local isOpend = Utils:ToBool(functions[pInfo.missionId])
		if isOpend then
			-- dump({isOpend, pInfo})
			if (not LRoleDataMgr:isGuideComplete(pInfo.stepId, true)) then
				local notFlying = (not newOpenTb[pInfo.missionId])
				-- print("notFlying-->", notFlying)
				if notFlying then
					self:showGuide(pInfo.stepId)
					return
				end
			end
		end
	end
end

function GuideManager:checkTaskGuide(id, cType)
	if cType == nil or id == nil or id <= 0 or (cType ~= GuideDef.Type.StartTask and cType ~= GuideDef.Type.CompleteTask) then
		return
	end
	------------------------------------------------------------------------------------------
	local newOpenTb = {}
    Utils:SendMsg(LUIFunctionEvent.GetFuncOpenList, newOpenTb)
    --如果存在新功能开启，就返回不处理
    for k,v in pairs(newOpenTb) do
    	return
    end
    ------------------------------------------------------------------------------------------
	local guideList = LDataConstMgr:GetGuideListByType(cType)
	if guideList == nil then
		return
	end
	for i=1,#guideList do
		local pInfo = guideList[i]
		-- dump(pInfo)
		-- dump({pInfo.missionId == id , (not LRoleDataMgr:isGuideComplete(pInfo.stepId, true))})
		if pInfo.missionId == id and (not LRoleDataMgr:isGuideComplete(pInfo.stepId, true)) then
			self:showGuide(pInfo.stepId)
			return
		end
	end
end

function GuideManager:checkTaskClickGuide(stepId)
	local guideList = LDataConstMgr:GetGuideListByType(GuideDef.Type.ClickTask)
	if guideList == nil then
		return false
	end
	for i=1,#guideList do
		local pInfo = guideList[i]
		-- dump(pInfo)
		-- dump({pInfo.missionId == id , (not LRoleDataMgr:isGuideComplete(pInfo.stepId, true))})
		if pInfo.stepId == stepId then
			if (not LRoleDataMgr:isGuideComplete(pInfo.stepId, true))then
				self:showGuide(pInfo.stepId)
			end
			return true
		end
	end
	return false
end

function GuideManager:ParseGuideData()
	----------------------------------------------------
	local cfg = LRoleDataMgr:GetSettingStringConfig(AppDef.ServerSetIndex.SSI_FINISH_GUIDE)
	if cfg and type(cfg) == "string" then
		-- dump(cfg)
		local arr = string.split(cfg, ',')
		for i=1,#arr do
			if #arr[i] > 0 then
				LRoleDataMgr:setGuideComplete(arr[i], false, true)
			end
		end
	end
end

function GuideManager:dealServerData()
	if self.m_isStartCheck then
		return
	end
	self:ParseGuideData()
	local id = LUserConfigMgr:LoadUserGuide()
	self:SetCurGuideId(id)
	self:OnLineGuideChange()
	----------------------------------------------------
	self.m_isStartCheck = true
    --print("GuideManager:dealServerData")
	if #self.m_guideVec > 0 then
		local temp = {}
		for i=1,#self.m_guideVec do
			local stepId = self.m_guideVec[i]
			if not LRoleDataMgr:isGuideComplete(stepId, true) then
				table.insert(temp, stepId)
			end
		end
		self.m_guideVec = temp
		--dump(self.m_guideVec,"self.m_guideVec 1@@@==>")
		if #self.m_guideVec > 0 then
			self:delayStartGuideStep(self.m_guideVec[1])
		end
	end
end

-- function GuideManager:LoadGuideCache()
-- 	if self.m_isStartCheck == false then
-- 		local str = LUserConfigMgr:GetUserGuideCache()
-- 		if str and #str > 0 then
-- 			LRoleDataMgr:SetSettingStringConfig(AppDef.ServerSetIndex.SSI_FINISH_GUIDE, str)
-- 			self:ParseGuideData()
-- 		end
-- 	end
-- end

--引导上线处理
function GuideManager:OnLineGuideChange()
    local preStepId = CurGuideStepId
    local lv = LRoleDataMgr.MyHeroInfo.level
    if CurGuideStepId == 0 then
        if LRoleDataMgr:isGuideComplete(1,false) then
        	local steps = {2,3,4,5,6,8,10,15,35}
        	for i=1,#steps do
        		if not LRoleDataMgr:isGuideComplete(steps[i],false) then
                    if  lv == steps[i] then
            			CurGuideStepId = steps[i]*100+1
                        break
                    end
        		end
        	end
        end
    end
    local step = math.floor(CurGuideStepId/100)
    if step == 1 or step == 2 or step == 35 then
    	CurGuideStepId = step *100+1
    elseif step == 3 then
    	if CurGuideStepId > 300 and CurGuideStepId < 305 then
    		CurGuideStepId = 303
    	elseif CurGuideStepId > 304 and CurGuideStepId < 311 then
    		CurGuideStepId = 307
    	elseif CurGuideStepId > 310 and CurGuideStepId < 316 then
    		CurGuideStepId = 312
    	elseif CurGuideStepId == 317 then
    		CurGuideStepId = 316
    	end
    elseif step == 4 then
    	if CurGuideStepId == 402 then
    		CurGuideStepId = 401 
    	elseif CurGuideStepId > 402 and CurGuideStepId < 409 then
    		CurGuideStepId = 405
    	elseif CurGuideStepId > 408 and CurGuideStepId < 416 then
    		CurGuideStepId = 412
    	end
    elseif step == 5 then
    	if CurGuideStepId == 502 then
    		CurGuideStepId = 501
    	elseif CurGuideStepId > 502 and CurGuideStepId < 509 then
    		CurGuideStepId = 505
    	elseif CurGuideStepId > 508 and CurGuideStepId < 516 then
    		CurGuideStepId = 512
    	end
    elseif step == 6 then
    	if CurGuideStepId > 600 and CurGuideStepId < 606 then
    		CurGuideStepId = 603
    	elseif CurGuideStepId  == 607 or CurGuideStepId == 608 then
    		CurGuideStepId = 606
    	elseif CurGuideStepId  > 608 and CurGuideStepId < 615 then
    		CurGuideStepId = 611
    	end
    elseif step == 8 then
        if CurGuideStepId > 800 and CurGuideStepId < 806 then
            CurGuideStepId = 803
        elseif CurGuideStepId == 806 or CurGuideStepId == 807 then
            CurGuideStepId = 808
        end
    elseif step == 10 then
        CurGuideStepId = 1003
    elseif step == 15 then
        if CurGuideStepId > 1500 and CurGuideStepId < 1506 then
            CurGuideStepId = 1503
        elseif CurGuideStepId == 1506 then
            CurGuideStepId = 1507
        elseif CurGuideStepId > 1507 and CurGuideStepId < 1513 then
            CurGuideStepId = 1510
        elseif CurGuideStepId == 1513 then
            CurGuideStepId = 1514
        end
    end
    --print("############# CurGuideStepId:",CurGuideStepId)
    if CurGuideStepId > 0 then
        --print("等级不等于！=level",lv,CurGuideStepId)
        local step = math.floor(CurGuideStepId/100)
        if step < lv then
            LRoleDataMgr:setGuideComplete(step, false,true)
        elseif step ~= lv then
            self:SetCurGuideId(0)
        end
    end
    if preStepId ~= CurGuideStepId then
        LUserConfigMgr:SetUserCurGuide(CurGuideStepId)
        LuaNetSendMsg:QuerySetSettingInfo(AppDef.ServerSetIndex.SSI_CURRENT_GUIDE, tostring(CurGuideStepId))
    end
    if CurGuideStepId == 201 or CurGuideStepId == 316 or CurGuideStepId == 401 or CurGuideStepId == 501 then
    	Utils:OpenFuben(true)
        Utils:scheduleOnce(function()
            Utils:CheckGuide(CurGuideStepId)
        end, 0.5)
    elseif CurGuideStepId == 606 then
    	Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_SHENJIANG)
    elseif CurGuideStepId == 516 then
        Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_ZHUXIANFUBEN)
    elseif CurGuideStepId == 3501 then
        Utils:CheckGuide(CurGuideStepId)
    end
end

return GuideManager