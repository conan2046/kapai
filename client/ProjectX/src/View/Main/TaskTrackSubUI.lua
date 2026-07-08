--[[
主界面的任务追踪逻辑放这里
]]


local TaskTrackSubUI = LUIBase:New()
TaskTrackSubUI.__index = TaskTrackSubUI

function TaskTrackSubUI:New(mainNode)
    
	local o = LUIBase:New()
	setmetatable(o,TaskTrackSubUI)	

    o:Init(mainNode)
	return o
end

function TaskTrackSubUI:onExit()
    self:Destory()
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_DZ_RESUME_TASK)
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_SHENJ_FINISH)
    if self.m_pEffectAni then
        self.m_pEffectAni:release()
        self.m_pEffectAni = nil
    end
    if self.m_pBaseTaskCell then
        self.m_pBaseTaskCell:release()
        self.m_pBaseTaskCell = nil
    end
    if self.m_pBaseTeamCell then
        self.m_pBaseTeamCell:release()
        self.m_pBaseTeamCell = nil
    end
end

--[[
注册消息
]]
function TaskTrackSubUI:RegistMsgs()
    self.msgIds = 
    {
        LUITaskDataEvent.GotTaskInfo,
        LUITaskDataEvent.DeleteOneTask,
        LUIRoleTeamEvent.TeamMemberChanged,
        LUITaskDataEvent.ChangeTeamTab,
        LUITaskDataEvent.ClickTask,
        LUIGetPetWingEvent.CheckNext,
        LUITaskDataEvent.ContinueTask,
        LUITaskDataEvent.ShowTaskPanel,
    }
    self:RegistSelf(self,self.msgIds)

    self.m_pPauseImgRes = "res/UI/ui_zudui/ui_zudui_zanli.png"
    self.m_pCapImgRes = "res/UI/ui_zudui/ui_zudui_duizhang.png"
    self.m_bNeedUpdateTask = false

    --任务追踪
    --[[
    {taskId, taskCell},
    {taskId, taskCell},
    ...
    ]]
    self.m_pTaskCells = {}
    self.m_pEffectAni = nil
end

function TaskTrackSubUI:ProcessEvent(msg)
    if msg.msgId == LUITaskDataEvent.GotTaskInfo then
        local taskid = msg.value
--        print("ProcessEvent ------------------------------", taskid)
        self:InstertTaskCell(taskid)
    elseif msg.msgId == LUITaskDataEvent.DeleteOneTask then
--        print("DeleteOneTask", msg.value)
        self:CheckTaskDelete(msg.value)
    elseif msg.msgId == LUITaskDataEvent.DeleteAllTask then
        self:DeleteAllTask()
    elseif msg.msgId == LUIRoleTeamEvent.TeamMemberChanged then
        self:TeamMemberChanged()
    elseif msg.msgId == LUITaskDataEvent.ClickTask then
        local taskCell = self.m_pTaskListView:getChildByTag(msg.value)
        if taskCell ~= nil then
            local ind = self.m_pTaskListView:getIndex(taskCell)
            local worldPos = taskCell:getParent():convertToWorldSpace(cc.p(taskCell:getPositionX(), taskCell:getPositionY()));
            LGameMsg.m_baseMsgWithOne:Change(LUITaskDataEvent.TaskCellTouchPos, worldPos)
            
            LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
            self:TaskClicked(ind)
        end
    elseif msg.msgId == LUIGetPetWingEvent.CheckNext then
        --TODO:BUG 1800 增加部分“强制”自动化节点
        if LRoleDataMgr.MyHeroInfo.level < 10 or LRoleDataMgr.MyHeroInfo.level == 14 or LRoleDataMgr.MyHeroInfo.level == 17 then
            if #self.m_pTaskCells > 0 then
                Utils:SendMsg(LUITaskDataEvent.ClickTask, self.m_pTaskCells[1][1], true)
            end
        end
    elseif msg.msgId == LUITaskDataEvent.ContinueTask then
        if #self.m_pTaskCells > 0 then
            Utils:SendMsg(LUITaskDataEvent.ClickTask, self.m_pTaskCells[1][1], true)
        end
    elseif msg.msgId == LUITaskDataEvent.ChangeTeamTab then
        self.m_pCurTab = 1
        self:SetTabVisible()
        self.m_pTeamCheckBox:setSelected(true)
    elseif msg.msgId == LUITaskDataEvent.ShowTaskPanel then
        self.m_pTaskPanel:setVisible(msg.value)
    end
end

--[[
注册新手引导
]]
function TaskTrackSubUI:RegisterGuide()
    local function resumeMainTask()
        if #self.m_pTaskCells > 0 then
            Utils:SendMsg(LUITaskDataEvent.ClickTask, self.m_pTaskCells[1][1], true)
        end
    end
    local list = {
        GuideDef.StepId.Guide_DZ_RESUME_TASK,
        GuideDef.StepId.Guide_SHENJ_FINISH,
    }
    for i=1,#list do
        local data = LDataConstMgr:GetGuideData(list[i])
        Utils:RegisterGuide(data.stepId, nil, resumeMainTask, data.maskOffset, true)
    end
end

function TaskTrackSubUI:DoClickOthers(pid, pos)

    local function ChangeLeaderCallback()
        LuaNetSendMsg:QueryTeamLeader(pid)
    end

    local function AddFriendCallback()

    end

    local function QueryInfoCallback()
        LuaNetSendMsg:QueryOtherPlayer(pid)
    end

    local function KickoutCallback()
        LuaNetSendMsg:QueryExpelTeam(pid)

    end
    local btndata = {}
    btndata.pos = pos
    if LRoleDataMgr.MyHeroInfo:IsLeader() == true then
        table.insert(btndata,{GUITips.UI_Team_ChangeLeader,ChangeLeaderCallback})
        table.insert(btndata,{GUITips.UI_Team_MemberInfo,QueryInfoCallback})
        table.insert(btndata,{GUITips.UI_Team_AddFriend,AddFriendCallback})
        table.insert(btndata,{GUITips.UI_Team_Kickout,KickoutCallback})
    else
        table.insert(btndata,{GUITips.UI_Team_MemberInfo,QueryInfoCallback})
        table.insert(btndata,{GUITips.UI_Team_AddFriend,AddFriendCallback})
    end

    LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowCommomBtnList, btndata)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function TaskTrackSubUI:DoClickSelf(member, pos)

    local function LeaveTeamCallback()
        --退出队伍
        LuaNetSendMsg:QueryLeaveTeam()
    end

    local function PauseTeamCallback()
        --暂离队伍
        --print("PauseTeamCallback")
        LuaNetSendMsg:QueryPauseTeam()
    end

    --[[
    归队
    ]]
    local function ReturnTeamCallback()
        LuaNetSendMsg:QueryBackTeam()
    end

    local btndata = {}
    btndata.pos = pos
    if LRoleDataMgr.MyHeroInfo:IsLeader() == true then
        table.insert(btndata,{GUITips.UI_Team_LeaveTeam,LeaveTeamCallback})
    else
        if member.m_state == 0 then
            table.insert(btndata,{GUITips.UI_Team_ReturnTeam,ReturnTeamCallback})
            table.insert(btndata,{GUITips.UI_Team_LeaveTeam,LeaveTeamCallback})
        else
            table.insert(btndata,{GUITips.UI_Team_PauseTeam,PauseTeamCallback})
            table.insert(btndata,{GUITips.UI_Team_LeaveTeam,LeaveTeamCallback})
        end
       
    end
    LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowCommomBtnList, btndata)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function TaskTrackSubUI:TeamMemberChanged()

    local heroData = LRoleDataMgr.MyHeroInfo
    local cells = self.m_pTeamListView:getItems()
    local curnum = #cells
    local member
    local curInd = 0

    local members = heroData.m_pTeam.m_pMembers
    local function TeamMemberClicked(sender)
        local ind = sender:getTag()
        local member = members[ind]
        local worldPos = sender:getParent():convertToWorldSpace(cc.p(sender:getPositionX(), sender:getPositionY()));
        local showPos = cc.p(worldPos.x - 306 - sender:getContentSize().width / 2, worldPos.y)
        if member.m_id == heroData.id then
            self:DoClickSelf(member, showPos)
        else
            self:DoClickOthers(member.m_id, showPos)
        end
    end
    --insertCustomItem
    for i = 1,#members do
        if members[i].m_type == 1 then
            member = members[i]
            local curCell
            curInd = curInd + 1
            if curInd > curnum then
                curCell = self.m_pBaseTeamCell:clone()
                self.m_pTeamListView:pushBackCustomItem(curCell)
                curCell:addClickEventListener(TeamMemberClicked)
				self:MarkIntaractCObj(curCell)
            else
                curCell = self.m_pTeamListView:getItem(curInd - 1)
            end
            curCell:setTag(i)

            local headBg = curCell:getChildByName("bg_Head")
            local headImg = headBg:getChildByName("Icon")
            local str = Utils:GetHeroIconRes(member.m_professnal, AppDef.HeadIconResType.Square)
            headImg:loadTexture(str,ccui.TextureResType.localType)
            headImg:setScale(0.9)
            local capImg = curCell:getChildByName("Captain")
            if member.m_cap == 1 then--队长
                capImg:loadTexture(self.m_pCapImgRes, ccui.TextureResType.plistType)
                capImg:setVisible(true)
                if member.m_cap == 1 then--队长
                    curCell:retain()
                    --curCell:removeFromParent()
                    self.m_pTeamListView:removeItem(curInd - 1)
                    self.m_pTeamListView:insertCustomItem(curCell,0)
                    curCell:release()
                end
            elseif member.m_state == 0 then
                capImg:loadTexture(self.m_pPauseImgRes, ccui.TextureResType.plistType)
                capImg:setVisible(true)
            else
                capImg:setVisible(false)
            end


            local nameLabel = curCell:getChildByName("Name")
            nameLabel:setString(member.m_name)
            local lvLabel = curCell:getChildByName("Level")
            lvLabel:setString(member.m_lv)
            
        end
    end
    for i = curInd + 1, curnum do
        self.m_pTeamListView:removeLastItem()
    end

    --[[
    被动加入队伍不自动切换到组队页签
    ]]
    if self.m_pCurTab == 0 then
        -- self.m_pTaskCheckBox:setSelected(true)
        -- self:SetCurTab(0)
        return
    end
    -- if self.m_pCurTab ~= 1 then
    --     self.m_pTeamCheckBox:setSelected(true)
    --     self:SetCurTab(1)
    -- end
    if LRoleDataMgr.MyHeroInfo:IsTeam() == true then
        self.m_pTeamListView:setVisible(true)
        self.m_pNoTeamPanel:setVisible(false)
    else
        self.m_pNoTeamPanel:setVisible(true)
        self.m_pTeamListView:setVisible(false)
    end
end

function TaskTrackSubUI:DeleteAllTask()
    self.m_pTaskCells = {}
    self.m_pTaskListView:removeAllItems()
end

function TaskTrackSubUI:CheckTaskDelete(taskId)
    for i = 1, #self.m_pTaskCells do
        if self.m_pTaskCells[i][1] == taskId then
            self.m_pTaskListView:removeItem(i - 1)
            table.remove(self.m_pTaskCells,i)
            break
        end
    end
    -- local taskCell = self.m_pTaskListView:getChildByTag(taskId)
    -- if taskCell ~= nil then
    --     local ind = self.m_pTaskListView:getIndex(taskCell)
    --     self.m_pTaskListView:removeItem(ind)
    -- end
end

-- showExp body
-- function ShowExpEffect(pTouch, pEvent)
--     if pEvent == ccui.TouchEventType.began then
--        local _touchBeginPos = pTouch:getTouchBeganPosition()
       
--        LGameMsg.m_baseMsgWithOne:Change(LUITaskDataEvent.TaskCellTouchPos, _touchBeginPos)
--        LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)

--        LGameMsg.m_baseMsgWithOne:Change(LUITaskDataEvent.GetCompletedTask)
--        LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
--     end

--     if pEvent == ccui.TouchEventType.moved then
--         local movey = pTouch:getTouchMovePosition()
--     end

--     if pEvent == ccui.TouchEventType.ended then
        
--     end
-- end

--[[
获取任务状态
return 0已完成 1已接未完成 2未接 
]]
function TaskTrackSubUI.getTaskState(task)
    if task == nil then
        return 2
    end
    if task.getState == 0 then         --未接
        return 2
    elseif task.getState == 1 then--已接完成
        if task.state == 1 or (task.taskType == AppDef.TaskType.TASK_RI and task.state == 2) then
            return 0
        elseif task.state == 0 or task.state == 2 then--已接未完成
            return 1
        end
    else
        return 2--error
    end
end

function TaskTrackSubUI.sortFunc3(a, b) 
    local aTaskId = a[1]
    local bTaskId = b[1]
    local aTask = LRoleDataMgr.Task:GetTaskById(aTaskId)
    local bTask = LRoleDataMgr.Task:GetTaskById(bTaskId)
    local aState = TaskTrackSubUI.getTaskState(aTask)
    local bState = TaskTrackSubUI.getTaskState(bTask)
    if aTask == nil then
        return false
    end
    if bTask == nil then
        return true
    end
    -- if aTaskId == curTaskId then
    --     return true
    -- elseif bTaskId == curTaskId then
    --     return false
    -- else
    --     return aState < bState
    -- end
    if aTaskId == TaskTrackSubUI.curTaskId then
        return true
    elseif bTaskId == TaskTrackSubUI.curTaskId then
        return false
    else
        return aTaskId < bTaskId
    end
    
end

--日常 跨服排序
function TaskTrackSubUI.sortFunc4(a, b) 
    local aTaskId = a[1]
    local bTaskId = b[1]
    local aTask = LRoleDataMgr.Task:GetTaskById(aTaskId)
    local bTask = LRoleDataMgr.Task:GetTaskById(bTaskId)
    local aState = TaskTrackSubUI.getTaskState(aTask)
    local bState = TaskTrackSubUI.getTaskState(bTask)
    if aTask == nil then
        return false
    end
    if bTask == nil then
        return true
    end 


    -- if aTaskId >bTaskId then
    --   return true
    -- else
    --   return false
    -- end

    if aTaskId < bTaskId then
      return true
    else
      return false
    end

end

function TaskTrackSubUI:InstertTaskCell(taskId)
    TaskTrackSubUI.curTaskId = taskId
--    print("InstertTaskCell", TaskTrackSubUI.curTaskId)
    local isExit = false
    local curNum = #self.m_pTaskCells
    for i = 1, #self.m_pTaskCells do
        if self.m_pTaskCells[i][1] == taskId then
            self:ShowTaskInfo(self.m_pTaskCells[i][2], taskId)
            isExit = true
            break
        end
    end
    if isExit == false then
        local taskCell = self.m_pBaseTaskCell:clone()
        local descLabel = taskCell:getChildByName("Condition")
        local newLabel = CCAysLabel:create()
        newLabel:setPosition(descLabel:getPosition())
        newLabel:setAnchorPoint(cc.p(0,1))
        newLabel:setName("NewCondition")
        taskCell:addChild(newLabel)
        descLabel:removeFromParent()
        taskCell:setTag(taskId)
        self.m_pTaskListView:pushBackCustomItem(taskCell)
        --taskCell:addTouchEventListener(ShowExpEffect)
        table.insert(self.m_pTaskCells,{taskId,taskCell})
        self:ShowTaskInfo(taskCell, taskId)
    end

    --[[
    获取任务状态
    return 0已完成 1已接未完成 2未接 
    ]]
    -- local function getTaskState(task)
    --     if task == nil then
    --         return 2
    --     end
    --     if task.getState == 0 then         --未接
    --         return 2
    --     elseif task.getState == 1 then--已接完成
    --         if task.state == 1 or (task.taskType == AppDef.TaskType.TASK_RI and task.state == 2) then
    --             return 0
    --         elseif task.state == 0 or task.state == 2 then--已接未完成
    --             return 1
    --         end
    --     else
    --         return 2--error
    --     end
    -- end
    if #self.m_pTaskCells == 1 then
        self:UpdateTaskEffect()
        return
    end
    --[[
任务追踪栏排版优化：
1、先按类型排序，次序依次为：主线、日长、引导
2、类型内任务按照服务器发给的顺序显示，不会因为状态改变而发生位置改变
3、任务追踪栏中特效显示位置为我当前正在进行的任务
    ]]

    --[[
    AppDef.TaskType = 
{
    TASK_MAIN   = 1,
    TASK_ZHI    = 5,
    TASK_RI        = 10,
}
    ]]
    
    local typeValue = {}
    typeValue[AppDef.TaskType.TASK_MAIN] = 1
    typeValue[AppDef.TaskType.TASK_ZHI] = 3
    typeValue[AppDef.TaskType.TASK_RI] = 2
    typeValue[AppDef.TaskType.TASK_KuaFu] = 4
    -- print("----------------------------------------------------------")
    -- print("curTaskId=",curTaskId)
    -- print("----------------------------------------------------------")
    -- function sortFunc2(a, b) 
    --     local aTaskId = a[1]
    --     local bTaskId = b[1]
    --     local aTask = LRoleDataMgr.Task:GetTaskById(aTaskId)
    --     local bTask = LRoleDataMgr.Task:GetTaskById(bTaskId)
    --     local aState = self:getTaskState(aTask)
    --     local bState = self:getTaskState(bTask)
    --     if aTask == nil then
    --         return false
    --     end
    --     if bTask == nil then
    --         return true
    --     end
    --     -- print("aTask.id=",aTaskId,"aTask.name=",aTask.name,"aTask.type=",aTask.taskType)
    --     -- print("bTask.id=",bTaskId,"bTask.name=",bTask.name,"bTask.type=",bTask.taskType)
    --     if aTask.taskType ~= bTask.taskType then
    --         if typeValue[aTask.taskType] == nil then
    --             return false
    --         elseif typeValue[bTask.taskType] == nil then
    --                 return true
    --         else
    --             return typeValue[aTask.taskType] < typeValue[bTask.taskType] 
    --         end
    --     else
    --         if aTaskId == curTaskId then
    --             return true
    --         elseif bTaskId == curTaskId then
    --             return false
    --         else
    --             return aState < bState
    --         end
    --     end
    -- end

    
    
    
    
    --table.sort(self.m_pTaskCells, sortFunc2)
    
    ----------------------------------------------
    local curTask = LRoleDataMgr.Task:GetTaskById(TaskTrackSubUI.curTaskId)
    if curTask == nil then
        return
    end
    local mainTaskArr = {}
    local riTaskArr = {}
    local zhiTaskArr = {}
    local kuafuTaskArr = {}
    for i = 1, #self.m_pTaskCells do
        local tmpId = self.m_pTaskCells[i][1]
        local tmpTask = LRoleDataMgr.Task:GetTaskById(tmpId)
        if tmpTask == nil then
            table.insert(zhiTaskArr, self.m_pTaskCells[i])
        elseif tmpTask.taskType == AppDef.TaskType.TASK_MAIN then

            table.insert(mainTaskArr, self.m_pTaskCells[i])
        elseif tmpTask.taskType == AppDef.TaskType.TASK_RI then
            table.insert(riTaskArr, self.m_pTaskCells[i])
        elseif tmpTask.taskType == AppDef.TaskType.TASK_KuaFu then
            table.insert(kuafuTaskArr, self.m_pTaskCells[i])
        else
            table.insert(zhiTaskArr, self.m_pTaskCells[i])
        end
    end
    
    if curTask.taskType == AppDef.TaskType.TASK_MAIN then
        if #mainTaskArr > 1 then
            table.sort(mainTaskArr, TaskTrackSubUI.sortFunc3)
        end
    elseif curTask.taskType == AppDef.TaskType.TASK_RI then
        if #riTaskArr > 1 then
            table.sort(riTaskArr, TaskTrackSubUI.sortFunc4)
        end
    elseif curTask.taskType == AppDef.TaskType.TASK_KuaFu then
        if #kuafuTaskArr > 1 then
            table.sort(kuafuTaskArr, TaskTrackSubUI.sortFunc4)
        end
    else
        if #zhiTaskArr > 1 then
            table.sort(zhiTaskArr, TaskTrackSubUI.sortFunc3)
        end
    end
    ----------------------------------------------
    self.m_pTaskCells = {}
    for i = 1, #mainTaskArr do
        table.insert(self.m_pTaskCells,mainTaskArr[i])
    end

    for i = 1, #kuafuTaskArr do

        table.insert(self.m_pTaskCells,kuafuTaskArr[i])
    end

    for i = 1, #riTaskArr do

        table.insert(self.m_pTaskCells,riTaskArr[i])
    end
    for i = 1, #zhiTaskArr do
        table.insert(self.m_pTaskCells,zhiTaskArr[i])
    end
    for i = 1, #self.m_pTaskCells do
        self.m_pTaskCells[i][2]:retain()
    end
    self.m_pTaskListView:removeAllItems()
    for i = 1, #self.m_pTaskCells do
        self.m_pTaskListView:pushBackCustomItem(self.m_pTaskCells[i][2])
        --self.m_pTaskCells[i][2]:addTouchEventListener(ShowExpEffect)
        self.m_pTaskCells[i][2]:release()
    end
    self:UpdateTaskEffect()
    
end

function TaskTrackSubUI:UpdateTaskEffect()
    if #self.m_pTaskCells > 0 then
        local firstTId = self.m_pTaskCells[1][1]
        local aTask = LRoleDataMgr.Task:GetTaskById(firstTId)
        if aTask.taskType == AppDef.TaskType.TASK_MAIN  then
            if aTask.getState == 2 then
                --不可接
                if #self.m_pTaskCells > 1 then
                    local secTID = self.m_pTaskCells[2][1]
                    self:ShowTaskEffect(self.m_pTaskCells[2][2],self.m_pTaskCells[2][2]:getContentSize())
                end
            else
                self:ShowTaskEffect(self.m_pTaskCells[1][2],self.m_pTaskCells[1][2]:getContentSize())
            end
        end
    end
end

function TaskTrackSubUI:getTaskIndexByID(taskId)
    -- body
    --dump(self.m_pTaskCells, "getTaskIndexByID")
    for i = 1, #self.m_pTaskCells do
        if self.m_pTaskCells[i][1] == taskId then
            return i
        end
    end
    return 0
end

function TaskTrackSubUI:CheckTaskUpdate(taskId)
    local task = LRoleDataMgr.Task:GetTaskById(taskId)

    local taskCell = self.m_pTaskListView:getChildByTag(taskId)
    if taskCell ~= nil then--找到了
        local isComplete = self:ShowTaskInfo(taskCell, taskId)
        if isComplete or task.taskType == AppDef.TaskType.TASK_MAIN then
            taskCell:retain()
            local ind = self.m_pTaskListView:getIndex(taskCell)
            self.m_pTaskListView:removeItem(ind)
            self.m_pTaskListView:insertCustomItem(taskCell,0)
            taskCell:release()
        end
    else--没有找到，新建一个
        taskCell = self.m_pBaseTaskCell:clone()
        local descLabel = taskCell:getChildByName("Condition")
        local newLabel = CCAysLabel:create()
        newLabel:setPosition(descLabel:getPosition())
        newLabel:setAnchorPoint(cc.p(0,1))
        newLabel:setName("NewCondition")
        taskCell:addChild(newLabel)
        descLabel:removeFromParent()
        taskCell:setTag(taskId)
        local isComplete = self:ShowTaskInfo(taskCell,taskId)
        if isComplete or task.taskType == AppDef.TaskType.TASK_MAIN then
            self.m_pTaskListView:insertCustomItem(taskCell,0)
        else
            self.m_pTaskListView:pushBackCustomItem(taskCell)
        end

        --taskCell:addTouchEventListener(ShowExpEffect)
    end
end

--[[
return true 已完成  false未完成
]]
function TaskTrackSubUI:ShowTaskInfo(taskCell, taskId)

    local task = LRoleDataMgr.Task:GetTaskById(taskId)
    local complete = false
    if task == nil then
        return complete
    end
    local titleLabel = taskCell:getChildByName("Title")
    local stateImag = taskCell:getChildByName("Image_1")
    local descLabel = taskCell:getChildByName("NewCondition")


    --local stateStr = ""
    --local taskColor = AppDef.UIColor.CL_TASK_RED
    -- print("task.getState=",task.getState,"task.taskType=",task.taskType,"task.state=",task.state)
    --if task.getState == 0 then         --未接
        --stateStr = GUITips.UI_TASK_TRACK_1
        --taskColor = AppDef.UIColor.CL_TASK_BLUE
    if task.getState == 1 then--已接
        if task.state == 1 or (task.taskType == AppDef.TaskType.TASK_RI and task.state == 2) then
            --stateStr = GUITips.UI_TASK_TRACK_2
            --taskColor = AppDef.UIColor.CL_TASK_GREEN
            complete = true      
        --elseif task.state == 0 or task.state == 2 then
            --stateStr = GUITips.UI_TASK_TRACK_3
            --taskColor = AppDef.UIColor.CL_TASK_YELLOW
        end
    end
    if complete then
        stateImag:setVisible(true)
    else
        stateImag:setVisible(false)
    end
    --stataLabel:setColor(taskColor)
    --stataLabel:setString(stateStr)

    local namecolor = UICOLOR_BLUE_TASK
    if task.taskType == AppDef.TaskType.TASK_MAIN then
        namecolor = UICOLOR_PURPLE_TASK
    elseif task.taskType == AppDef.TaskType.TASK_KuaFu then
        namecolor = AppDef.UIColor.ORANGE
    end
    titleLabel:setColor(namecolor)
    titleLabel:setString(task.name)

    --任务内容描述，
    local size
    local newSize
    local fixHeight
    descLabel:removeAllChildren()
    if task.getState == 2 then   --不可接 
        -- pDescNode = cc.Label:createWithSystemFont(self._TaskData[i+1].info , FNT_NAMEC , FNT_SIZE_M , CCSizeMake(MaxWidth - 15,0) , kCCTextAlignmentLeft , kCCVerticalTextAlignmentCenter ) 
        -- pDescNode:setColor(CCRED)      
        -- size = pDescNode:getContentSize() 
        descLabel:triggleInit(task.info , cc.size(self.m_oldTaskCellSize.width,0) , -132 , CL_TASK_WHITE , self.m_taskFontSize,
        false,0,0,0,true,false)   --ccWHITE
        size = descLabel:getSize()

        fixHeight = size.height - self.m_oldTaskCellSize.height
        newSize = cc.size(self.m_taskCellSize.width,self.m_taskCellSize.height + fixHeight)

--不可接,则删掉引导光圈
        -- if task.taskType == AppDef.TaskType.TASK_MAIN then
        --     self._mainTaskIsCandDo = false
        --     self:removeTaskEffect(taskCell)
        -- end
        
    else 
        descLabel:triggleInit(  
                task.info, 
                cc.size(self.m_oldTaskCellSize.width - 15,0) , 
                -132 , 
                CL_TASK_WHITE ,
                 self.m_taskFontSize,
                 false,0,0,0,true,false
                 )   --ccWHITE
        size = descLabel:getSize()

        fixHeight = size.height - self.m_oldTaskCellSize.height
        newSize = cc.size(self.m_taskCellSize.width,self.m_taskCellSize.height + fixHeight)

--当任务追踪栏中没有主线时，引导光圈在第二个上面
        -- if task.taskType == AppDef.TaskType.TASK_MAIN then
        --     self._mainTaskIsCandDo = true
        --     self:ShowTaskEffect(taskCell,newSize)
        -- else
        --     if not self._mainTaskIsCandDo then
        --         --self:updateTaskEffect(newSize)
        --         self:ShowTaskEffect(taskCell,newSize)
        --     end
        -- end
    end
    
    --print("fixHeight=",fixHeight)
    -- local cellSize = self.m_taskCellSize
    -- print("cellSize=",cellSize.height)
    -- cellSize.height = cellSize.height + fixHeight
    
    taskCell:setContentSize(newSize)
    titleLabel:setPositionY(fixHeight+self.m_titlePosY)
    --stateImag:setPositionY(fixHeight+self.m_statePosY)
    descLabel:setPositionY(fixHeight+self.m_descPosY)
    stateImag:setLocalZOrder(9)
    return complete
end

function TaskTrackSubUI:removeTaskEffect( taskCell )
    -- body
    -- if self.m_pEffectAni == nil then
    --     return
    -- end
    -- if self.m_pEffectAni:getParent() == nil then
    --     return
    -- end
    -- if taskCell == nil then
    --     return
    -- end
    -- self.m_pEffectAni:retain()
    -- self.m_pEffectAni:removeFromParent()
    -- --去除29级之后看不到引导光圈限制
    -- local aniNode = taskCell:getChildByName("AniNode")
    -- if aniNode ~= nil then
    --     aniNode:removeFromParent()
    -- end
    -- return
end

function TaskTrackSubUI:ShowTaskEffect(taskCell,newSize)
    -- local aniNode = taskCell:getChildByName("AniNode")
    -- if aniNode == nil then
    --     aniNode = ImodAnim:createWithFileSync("res2/fx/renwulan")
    --     taskCell:addChild(aniNode)
    --     --table.insert(self._AnimArr, taskCell)
    --     aniNode:setPosition(cc.p(newSize.width/2, newSize.height/2))
    --     aniNode:setScale(newSize.width/262,newSize.height/78)
    --     aniNode:setName("AniNode")
    -- end
    -- aniNode:PlayNewAction(0,true)
    if self.m_pEffectAni == nil then
        self.m_pEffectAni = ImodAnim:createWithFileSync("res2/fx/renwulan")
        self.m_pEffectAni:retain()
    end
    if self.m_pEffectAni:getParent() ~= nil then
        self.m_pEffectAni:removeFromParent()
    end
    taskCell:addChild(self.m_pEffectAni)
    self.m_pEffectAni:setPosition(cc.p(newSize.width/2, newSize.height/2))
    self.m_pEffectAni:setScale(newSize.width/262,newSize.height/78)
    self.m_pEffectAni:PlayNewAction(0,true)
end

function TaskTrackSubUI:updateTaskEffect(newSize)
    -- body
    -- for i = 1, #self.m_pTaskCells do
    --     self:removeTaskEffect(self.m_pTaskCells[i][2])
    -- end  
    -- if self.m_pTaskCells[2] ~= nil then
    --     self:ShowTaskEffect(self.m_pTaskCells[2][2], newSize)
    -- end    
end

function TaskTrackSubUI:Init(mainNode)
    self.m_pTaskPanel = mainNode
    self:RegistMsgs()
    self:InitData()
    self:AddTouchEvt()
    self:SetDefaultTab()
    performWithDelay(self.m_pTaskPanel, function()
        self:RegisterGuide()
    end, 1/10)
    --self:LoadTaskEffect()
end

-- function TaskTrackSubUI:LoadTaskEffect()
--     local function loadImgSuccess()
--     end
--     display.loadImage("res2/fx/renwulan.png", loadImgSuccess)
-- end

-- function TaskTrackSubUI:ShowTaskEffect()

-- end


function TaskTrackSubUI:InitData()
    self.m_pTaskListView = self.m_pTaskPanel:getChildByName("ListView_1")
    self.m_pBaseTaskCell = self.m_pTaskPanel:getChildByName("Item_Quest")
    self.m_pBaseTaskCell:getChildByName("State"):setVisible(false)
    self.m_pBaseTaskCell:retain()
    self.m_pBaseTaskCell:removeFromParent()
    local descLabel = self.m_pBaseTaskCell:getChildByName("Condition")

    self.m_oldTaskCellSize = descLabel:getContentSize()
    self.m_taskCellSize = self.m_pBaseTaskCell:getContentSize()
    self.m_taskFontSize = descLabel:getFontSize()
    self.m_taskFontName = descLabel:getFontName()
    self.m_titlePosY = self.m_pBaseTaskCell:getChildByName("Title"):getPositionY()
    self.m_statePosY = self.m_pBaseTaskCell:getChildByName("Image_1"):getPositionY()
    self.m_descPosY = descLabel:getPositionY()
    
    self.m_pTaskCheckBox = self.m_pTaskPanel:getChildByName("CheckBox_Quest")
    self.m_pTeamCheckBox = self.m_pTaskPanel:getChildByName("CheckBox_Team")
    self.m_pTeamCheckBox:setVisible(LDataConstMgr:isModuleDefaultShow(AppDef.EModuleID.EMID_ZUDUI))
    self.m_pShowBtn = self.m_pTaskPanel:getChildByName("btn_Locker")
    self.m_pBaseTeamCell = self.m_pTaskPanel:getChildByName("Item_Team")
    self.m_pBaseTeamCell:retain()
    self.m_pBaseTeamCell:removeFromParent()

    self.m_pNoTeamPanel = self.m_pTaskPanel:getChildByName("Panel")
    self.m_pCreatTeamBtn = self.m_pNoTeamPanel:getChildByName("btn_Found")
    self.m_pFindTeamBtn = self.m_pNoTeamPanel:getChildByName("btn_Seek")
    self.m_pTeamListView = self.m_pTaskPanel:getChildByName("teamListView")

    self.m_pCurTab = -1
    self.m_bIsShowPanel = true
    self._mainTaskIsCandDo = true
    --self._AnimArr = {}
end

function TaskTrackSubUI:AddTouchEvt()
    local function TaskListCallback(sender,eventType)
        if eventType ~= 1 then
            return
        end
        local ind = self.m_pTaskListView:getCurSelectedIndex()
        self:TaskClicked(ind)
    end
    self.m_pTaskListView:addEventListener(TaskListCallback)

    local function TaskCBCallback(sender)
        local sceneType = LRoleDataMgr.MyHeroInfo.SceneType
        if  sceneType == AppDef.SceneType.MSI_FACTION_WAR_PRE then
            Utils:ShowScrollTips(GUITips.RSI_FACTION_MGS211)
            self.m_pTaskCheckBox:setSelected(true)
            return
        end
        if sceneType == AppDef.SceneType.MSI_FACTION_WAR then
            self.m_pTaskPanel:setVisible(false)
            Utils:SendMsg(LUIBangPaiEvent.ShowBangPaiWarTask)
            return
        end

        self:SetCurTab(0)
    end
    self.m_pTaskCheckBox:addClickEventListener(TaskCBCallback)
	self:MarkIntaractCObj(self.m_pTaskCheckBox)
    local function TeamCBCallback(sender, event)
        if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_ZUDUI) then
            self.m_pTeamCheckBox:setSelected(false)
            return
        end
        self:SetCurTab(1)
    end
    self.m_pTeamCheckBox:addEventListener(TeamCBCallback)

    local function ShowBtnCallback(sender)
        --print("ShowBtnCallback")
        self:CheckShowPanel()
    end
    self.m_pShowBtn:addClickEventListener(ShowBtnCallback)
	self:MarkIntaractCObj(self.m_pShowBtn)
    local function CreateTeamBtnCallback(sender)
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Team.TeamMainUI",AppDef.UIType.FirstClassLayer)
        self:SendMsg(LGameMsg.m_initUIMsg)
        LuaNetSendMsg:QueryCreateTeam()
    end
    self.m_pCreatTeamBtn:addClickEventListener(CreateTeamBtnCallback)
	self:MarkIntaractCObj(self.m_pCreatTeamBtn)
    local function FindTeamBtnCallback(sender)
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Team.TeamMainUI",AppDef.UIType.FirstClassLayer,AppDef.UITab.Team.Quick)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    self.m_pFindTeamBtn:addClickEventListener(FindTeamBtnCallback)
	self:MarkIntaractCObj(self.m_pFindTeamBtn)
end

function TaskTrackSubUI:CheckShowPanel()
    if self.m_bIsShowPanel == true then
        self.m_bIsShowPanel = false
        self.m_pShowBtn:setFlippedX(true)
        self.m_pTaskListView:setVisible(false)
        self.m_pTaskCheckBox:setVisible(false)
        self.m_pTeamCheckBox:setVisible(false)
        self.m_pNoTeamPanel:setVisible(false)
        self.m_pTeamListView:setVisible(false)
    else
        self.m_bIsShowPanel = true
        self.m_pShowBtn:setFlippedX(false)
        self.m_pTaskCheckBox:setVisible(true)
        self.m_pTeamCheckBox:setVisible(true)
        self:SetTabVisible()
    end
end

function TaskTrackSubUI:SetCurTab(tab)
    
    if self.m_pCurTab == tab then
        if self.m_pCurTab == 0 then
            self.m_pTaskCheckBox:setSelected(false)
        else
            self.m_pTeamCheckBox:setSelected(true)
        end
        if tab == 1 then
            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Team.TeamMainUI",AppDef.UIType.FirstClassLayer)
            self:SendMsg(LGameMsg.m_initUIMsg)
        end
        return
    end

    self.m_pCurTab = tab
    self:SetTabVisible()

    if tab == 1 then
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Team.TeamMainUI",AppDef.UIType.FirstClassLayer)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
end

function TaskTrackSubUI:SetDefaultTab()
    self.m_pCurTab = 0
    self.m_pTaskCheckBox:setSelected(true)
    self.m_pTeamCheckBox:setSelected(false)
    self.m_pTeamListView:setVisible(false)
    self.m_pNoTeamPanel:setVisible(false)
    self.m_pTaskListView:setVisible(true)
end

function TaskTrackSubUI:SetTabVisible()
    if self.m_pCurTab == 0 then
        -- self.m_pTaskCheckBox:setEnabled(false)
        -- self.m_pTeamCheckBox:setEnabled(true)
        self.m_pTeamCheckBox:setSelected(false)
        self.m_pTeamListView:setVisible(false)
        self.m_pNoTeamPanel:setVisible(false)
        self.m_pTaskListView:setVisible(true)
    else
        -- self.m_pTaskCheckBox:setEnabled(true)
        -- self.m_pTeamCheckBox:setEnabled(false)
        if LRoleDataMgr.MyHeroInfo:IsTeam() == true then
            self.m_pTeamListView:setVisible(true)
            self.m_pNoTeamPanel:setVisible(false)
        else
            self.m_pNoTeamPanel:setVisible(true)
            self.m_pTeamListView:setVisible(false)
        end
        self.m_pTaskCheckBox:setSelected(false)
        self.m_pTaskListView:setVisible(false)
    end
end
--打开跨服NPC对话
 function TaskTrackSubUI:OpenKuaFuChat(id ,idnex)
	LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, false)
	LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
	LRoleDataMgr.MyHeroInfo.isKuFuTaskAutoPath=true
    LuaNetSendMsg:QueryNpcChatOpen(228, 228,taskid)       
end
--寻路到跨服npc
function TaskTrackSubUI:AutoPathKuaFuNpc()
     local secneType = LRoleDataMgr.MyHeroInfo.SceneType
     local factionWarScene = secneType == AppDef.SceneType.MSI_FACTION_WAR or secneType == AppDef.SceneType.MSI_FACTION_WAR_PRE
           or secneType == AppDef.SceneType.MSI_MULTISER_FACTION_BATTLE_READY or secneType == AppDef.SceneType.MSI_MULTISER_FACTION_BATTLE
    if factionWarScene == true then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_GL_CPT_TIP7)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
            return
    end 
    LGameMsg.m_autoPathMsg:ChangeToStart(11,1245,1468,0,bit.lshift(228,16),true,true,TaskTrackSubUI.OpenKuaFuChat)
    self:SendMsg(LGameMsg.m_autoPathMsg)
  
	LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, true)
	self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function TaskTrackSubUI:TaskClicked(ind)
    if self.m_bNeedUpdateTask then
        return
    end
    --print("TaskClicked",ind)
    local taskCell = self.m_pTaskListView:getItem(ind)
    local taskid = taskCell:getTag()
    --print("taskid=",taskid)
    local task = LRoleDataMgr.Task:GetTaskById(taskid)

    local x = 0
    local y = 0
    local id = -1
    local op = 0
    local opVal = 0
    local opVal2 = 0
    local opVal3 = 0
    local state = 0
    if task ~= nil then
        id = task.scene_id
        x = task.posx
        y = task.posy
        op = task.op
        opVal = task.opVal
        opVal2 = task.opVal2
        opVal3 = task.opVal3
        state = task.state
       
        --popIdx = task.popLayerIdx
    end
 
    --print("task=",taskid, task,"task.scene_id=",task.scene_id,"opVal=",task.opVal,"task.op=",task.op,"task.state=",task.state)
    
    if taskid == 213 and state ~= 2 then
        LRoleDataMgr.MyHeroInfo:SendHeroConvoyChangedMsg()
    end

    --判断是否在帮战场景，是的话处理特殊情况（屏蔽跳转其他地图）
    local secneType = LRoleDataMgr.MyHeroInfo.SceneType
    local factionWarScene = secneType == AppDef.SceneType.MSI_FACTION_WAR or secneType == AppDef.SceneType.MSI_FACTION_WAR_PRE
        or secneType == AppDef.SceneType.MSI_MULTISER_FACTION_BATTLE_READY or secneType == AppDef.SceneType.MSI_MULTISER_FACTION_BATTLE

    --如果是弹窗任务   MAX = 40
       --op=2
       --opVal=18
       --opVal2=2
  
    if op == 2 then
     
        if factionWarScene and (popIdx==11 or popIdx == 25 or popIdx ==26 or popIdx ==28 or popIdx == 30 or popIdx == 31 or popIdx == 32 or popIdx == 39) then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_GL_CPT_TIP7)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
            return
        end
        self:OpenUIByTask(opVal,opVal2, opVal3)
    elseif op == 3 then
      
        Utils:OpenFunction(AppDef.EModuleID.EMID_MUBIAO)
        Utils:SendMsg(LUITaskGiftEvent.InitTaskEvent, taskid)
   
    elseif op==4 then
        if LRoleDataMgr.m_bIsCrossServer==false then
           self:AutoPathKuaFuNpc()
           return
        end

          local  pro = ""
          if opVal==AppDef.HeroPro.Zhenguo then
              pro=GUITips.HeroPro1
          elseif opVal==AppDef.HeroPro.Bajinggong then
             pro=GUITips.HeroPro2
          elseif opVal==AppDef.HeroPro.Yuxugong then
             pro=GUITips.HeroPro3
          elseif opVal==AppDef.HeroPro.Biyougong then
             pro=GUITips.HeroPro4
          elseif opVal==AppDef.HeroPro.Kunlun then
             pro=GUITips.HeroPro5
          elseif opVal==AppDef.HeroPro.Jiuli then
             pro=GUITips.HeroPro6
          end

          --Utils:ShowScrollTips(string.format(GUITips.RSL_PK_MSG1,pro))
          Utils:ShowScrollTips(GUITips.RSL_PK_MSG1,pro)
    else
        --寻路或者传送的任务在帮战场景禁止
        if factionWarScene == true then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_GL_CPT_TIP7)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
            return
        end 
        local endPos = cc.p(x,y)
        -- if((op == 0 or op==2) && (endPos.x < 0 or endPos.y < 0))
        -- {
        --     --找NPC
        --     CCPoint npcMinPoint
        --     if (gLayer->GetGameMap()->CheckNearNpc(opVal))
        --         return
        --     float minLen = gLayer->GetGameMap()->CalcHeroBetweenNPCDistance(opVal, npcMinPoint)
        --     if(minLen >= 0.0f)
        --     {
        --         endPos = npcMinPoint
        --         --距离小于2，认为已经到达
        --         if(minLen < 2.0f)
        --             endPos = ccp(-1, -1)
        --     }
        -- }

        --如果有采集关闭采集功能
        --关闭挂机功能
        -- if(DATA_MGR->IsHooking)
        -- {
        --     DATA_MGR->IsHooking = false
        --     gLayer->CheckHook(false)
        -- }

        --打开寻路不遇怪模式
        --BT_PARAMS.IsCanBattle = true
        -- if op ~= 1 then
        --     LuaNetSendMsg:QueryCanBattle(2)
        -- end
        LuaNetSendMsg:QueryCanBattle(2)
        --设置自动寻路状态
        if LRoleDataMgr.MyHeroInfo:IsTeam() == true and LRoleDataMgr.MyHeroInfo:IsLeader() == false then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_TTL_TIP1)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
        else
            --GAMELAYER->GetGameMap()->StopHeroMove()
            local canJumpMap = false
            --local delayWalk = 0.0
            if LRoleDataMgr.MyHeroInfo.level > 25 and LRoleDataMgr.MyHeroInfo.sid ~= id then--如果不在当前地图则传送
                canJumpMap = true
            end

            --护送任务忽略NPC
            local IsPassNPC = false
            if LRoleDataMgr.MyHeroInfo.ConvoyType ~= 0 and taskid == 213 then
                IsPassNPC = true
            end
            if LRoleDataMgr.MyHeroInfo.ConvoyType ~= 0 then
                canJumpMap = false
            end
            --short mid, short px, short pz, int pathType, int iid, bool isShowAni, bool jump, int callback
            local function AutoPachEndCallback(npcId, npcIdx)
              
                LuaNetSendMsg:QueryCanBattle(3)
                if (npcId ~= nil and npcIdx ~= nil)
                    and npcId > 0 
                    and (opVal == npcId) then
                        if (op == 0 or op == 2) then   
                            
                            LuaNetSendMsg:QueryNpcChatOpen(opVal, npcIdx,taskid)
                        elseif op == 1 then
                            --挂机
                            LGameMsg.m_baseMsgWithOne:Change(LUIRoleDataChangeEvent.StartHangUp, {taskid, opVal})
                            self:SendMsg(LGameMsg.m_baseMsgWithOne)
                            LGameMsg.m_hangUpMsg:Change(CEnum.HangUpEvent.StartHangUp, opVal, taskid)--
                            self:SendMsg(LGameMsg.m_hangUpMsg)
                        end
                end
				LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, false)
				self:SendMsg(LGameMsg.m_baseMsgWithOne)
            end                 
              LGameMsg.m_autoPathMsg:ChangeToStart(id,endPos.x,endPos.y,op,bit.lshift(opVal,16),true,canJumpMap,AutoPachEndCallback)
              self:SendMsg(LGameMsg.m_autoPathMsg)
			LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, true)
			self:SendMsg(LGameMsg.m_baseMsgWithOne)
            --end
        end
    end
end

--[[
任务追踪打开UI
@param1:uiType,
@param1:uiTab, 
@param1:uiInd
]]
function TaskTrackSubUI:OpenUIByTask(uiType,uiTab, uiInd)
    if uiType == 1 then
        --打开副本
        self:OpenFubenByTask(uiTab,uiInd)
    elseif uiType == 2 then
        --打开锻造界面
        self:OpenDuanzaoUI(uiTab)
    elseif uiType == 3 then
        --打开人物技能界面
        self:OpenHeroSkillUI()
    elseif uiType == 4 then
        --打开神将界面
        self:OpenPetUI(uiTab)
    elseif uiType == 5 then
        --打开坐骑界面
        self:OpenMountUI(uiTab)
    elseif uiType == 6 then
        --打开帮派界面
        self:OpenBangUI(uiTab)
    elseif uiType == 7 then
        --打开竞技场界面
        self:OpenJingjiUI()
    elseif uiType == 8 then
        --打开日常玩法
        self:OpenRichangUI(uiTab)
    elseif uiType == 9 then
        --打开招募
        self:OpenChoukaUI(uiTab)
    elseif uiType == 10 then
        --打开运营活动
        self:OpenActivityUI()
    elseif uiType==11 then
        --打开神器
        self:OpenShengQiUI()
    elseif uiType==12 then
        --打开聊天
        self:OpenChatUI()
    elseif uiType==13 then
        --打开好友
        self:OpenFriendUI()
    elseif uiType==14 then
        --打开膜拜
        self:OpenMoBaiUI()
    elseif uiType==15 then
        --打开捐赠
        self:OpenJuanZeng()    
     elseif uiType==16 then
        --打开帮派种植
        self:BangPaiZhongZhiUI()    
     elseif uiType==17 then
        --打开神树
        self:BangPaiShenShuUI()    
    elseif uiType==18 then
        --使用藏宝图
        self:UseCangBaoTu(uiTab)
    elseif uiType==19 then
        --打开神器
        self:OpenShengQiUI()
    elseif uiType == 20 then
        --打开玩法
        self:OpenWanfa()
    elseif uiType == 21 then
        --充值界面
        self:OpenRecharge()
    elseif uiType == 22 then
        --首充界面
        Utils:OpenFunction(AppDef.EModuleID.EMID_SHOUCHONG)
    elseif uiType == 23 then
        --成长基金
        self:OpenFundRebate()
    elseif uiType == 24 then
        --斗神之路
        self:openMUBIAO()
    elseif uiType == 25 then
        --开服活动(活动)
        self:openWelfareActivity()
    elseif uiType == 26 then
        --打开称号
        Utils:OpenFunction(AppDef.EModuleID.EMID_CHENHAO)
    elseif uiType == 27 then
        --打开羽翼
        if uiTab == 1 then
            Utils:OpenFunction(AppDef.EModuleID.EMID_YUYI)
        else
            Utils:OpenFunction(AppDef.EModuleID.EMID_YYJINJIE)
        end
    elseif uiType == 28 then
        --打开排行榜
        Utils:OpenFunction(AppDef.EModuleID.EMID_PAIHANGBANG)
    elseif uiType == 29 then
        --打开商城
        Utils:OpenFunction(AppDef.EModuleID.EMID_SCCHANGYONG)
    elseif uiType == 30 then
        --打开背包
        Utils:OpenFunction(AppDef.EModuleID.EMID_BEIBAO)
    elseif uiType==31 then --打开跨服聊天
         self:OpenKuaFuChatUI()
    elseif uiType==32 then --找领奖天官    
         self:FindLingJingTianGuan()  
    elseif uiType==33 then --打开福利    
         self:OpenFuli(uiTab)  
     end
end
function TaskTrackSubUI:UseCangBaoTu(uiTab)
       if uiTab==1 then
           local pos=LRoleDataMgr.Equip:FindPackageItemById3(2441)
           if pos==nil or pos==0 then
               LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, GUITips.RSL_AY_MSG5)
               self:SendMsg(LGameMsg.m_scrollTipsMsg)
               return
            end
              LRoleDataMgr:useCangbaotu(pos)
        end


       if uiTab==2 then
          local pos=LRoleDataMgr.Equip:FindPackageItemById3(2442)
           if pos==nil or pos==0 then
              LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, GUITips.RSL_AY_MSG6)
               self:SendMsg(LGameMsg.m_scrollTipsMsg)
              return
            end        
              LRoleDataMgr:useCangbaotu(pos)
        end
end        
function TaskTrackSubUI:BangPaiShenShuUI()
    if LRoleDataMgr.Faction.Info.id <= 0 then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, GUITips.RSI_BP_TIP1)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
            return
        end
     LuaNetSendMsg:QueryBangPaiEnterZone(LRoleDataMgr.Faction.Info.id)
        if factionWarScene == true then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_GL_CPT_TIP7)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
            return
        end
        local endPos = cc.p(2182,546)
        LuaNetSendMsg:QueryCanBattle(2)
        --设置自动寻路状态
        if LRoleDataMgr.MyHeroInfo:IsTeam() == true and LRoleDataMgr.MyHeroInfo:IsLeader() == false then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_TTL_TIP1)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
        else
            --GAMELAYER->GetGameMap()->StopHeroMove()
            local canJumpMap = false
            --local delayWalk = 0.0
            if LRoleDataMgr.MyHeroInfo.level > 25 and LRoleDataMgr.MyHeroInfo.sid ~= 11 then--如果不在当前地图则传送
                canJumpMap = true
            end

            --护送任务忽略NPC
            local IsPassNPC = false
            if LRoleDataMgr.MyHeroInfo.ConvoyType ~= 0 and taskid == 213 then
                IsPassNPC = true
            end
            if LRoleDataMgr.MyHeroInfo.ConvoyType ~= 0 then
                canJumpMap = false
            end
            --short mid, short px, short pz, int pathType, int iid, bool isShowAni, bool jump, int callback
            local function AutoPachEndCallback(npcId, npcIdx)
                local BangPaiZoneDef = require('View.BangPaiZone.BangPaiZoneDef')      
                local pMsg = FactionZoneMsg:new(LPlantEvent.PlantEvent, 1, BangPaiZoneDef.OprType.ClickGodTree)
                self:SendMsg(pMsg)
				LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, false)
				self:SendMsg(LGameMsg.m_baseMsgWithOne)
            end
            LGameMsg.m_autoPathMsg:ChangeToStart(47,endPos.x,endPos.y,0,bit.lshift(0,16),true,canJumpMap,AutoPachEndCallback)
            self:SendMsg(LGameMsg.m_autoPathMsg)
			LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, true)
			self:SendMsg(LGameMsg.m_baseMsgWithOne)
        end
end
function TaskTrackSubUI:BangPaiZhongZhiUI()
       if LRoleDataMgr.Faction.Info.id <= 0 then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, GUITips.RSI_BP_TIP1)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
            return
        end
     LuaNetSendMsg:QueryBangPaiEnterZone(LRoleDataMgr.Faction.Info.id)
    local secneType = LRoleDataMgr.MyHeroInfo.SceneType
    local factionWarScene = secneType == AppDef.SceneType.MSI_FACTION_WAR or secneType == AppDef.SceneType.MSI_FACTION_WAR_PRE
        or secneType == AppDef.SceneType.MSI_MULTISER_FACTION_BATTLE_READY or secneType == AppDef.SceneType.MSI_MULTISER_FACTION_BATTLE
     if factionWarScene == true then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_GL_CPT_TIP7)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
            return
        end
        local endPos = cc.p(613,553)
        LuaNetSendMsg:QueryCanBattle(2)
        --设置自动寻路状态
        if LRoleDataMgr.MyHeroInfo:IsTeam() == true and LRoleDataMgr.MyHeroInfo:IsLeader() == false then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_TTL_TIP1)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
        else
            --GAMELAYER->GetGameMap()->StopHeroMove()
            local canJumpMap = false
            --local delayWalk = 0.0
            if LRoleDataMgr.MyHeroInfo.level > 25 and LRoleDataMgr.MyHeroInfo.sid ~= 11 then--如果不在当前地图则传送
                canJumpMap = true
            end

            --护送任务忽略NPC
            local IsPassNPC = false
            if LRoleDataMgr.MyHeroInfo.ConvoyType ~= 0 and taskid == 213 then
                IsPassNPC = true
            end
            if LRoleDataMgr.MyHeroInfo.ConvoyType ~= 0 then
                canJumpMap = false
            end
            --short mid, short px, short pz, int pathType, int iid, bool isShowAni, bool jump, int callback
            local function AutoPachEndCallback(npcId, npcIdx)
                    LuaNetSendMsg:QueryNpcChatOpen(169, 169,taskid)
                   --LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.RIS_LEFTUI_MSG42)
                   --self:SendMsg(LGameMsg.m_baseMsgWithOne)
					LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, false)
					self:SendMsg(LGameMsg.m_baseMsgWithOne)
            end
            LGameMsg.m_autoPathMsg:ChangeToStart(47,endPos.x,endPos.y,0,bit.lshift(0,16),true,canJumpMap,AutoPachEndCallback)
            self:SendMsg(LGameMsg.m_autoPathMsg)
			LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, true)
			self:SendMsg(LGameMsg.m_baseMsgWithOne)
        end
    -- body
end

function  TaskTrackSubUI:OpenJuanZeng()
     if LRoleDataMgr.Faction.Info.id <= 0 then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, GUITips.RSI_BP_TIP1)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
            return
      end
     LuaNetSendMsg:QueryFactionJuanXianMsg()
end
function TaskTrackSubUI:OpenMoBaiUI() --lxjGai
    if factionWarScene == true then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_GL_CPT_TIP7)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
            return
        end
        local endPos = cc.p(2090,1105)
        LuaNetSendMsg:QueryCanBattle(2)
        --设置自动寻路状态
        if LRoleDataMgr.MyHeroInfo:IsTeam() == true and LRoleDataMgr.MyHeroInfo:IsLeader() == false then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_TTL_TIP1)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
        else
            --GAMELAYER->GetGameMap()->StopHeroMove()
            local canJumpMap = false
            --local delayWalk = 0.0
            if LRoleDataMgr.MyHeroInfo.level > 25 and LRoleDataMgr.MyHeroInfo.sid ~= 11 then--如果不在当前地图则传送
                canJumpMap = true
            end

            --护送任务忽略NPC
            local IsPassNPC = false
            if LRoleDataMgr.MyHeroInfo.ConvoyType ~= 0 and taskid == 213 then
                IsPassNPC = true
            end
            if LRoleDataMgr.MyHeroInfo.ConvoyType ~= 0 then
                canJumpMap = false
            end
            --short mid, short px, short pz, int pathType, int iid, bool isShowAni, bool jump, int callback
            local function AutoPachEndCallback(npcId, npcIdx)
                --print("AutoPachEndCallback",npcId,npcIdx,"op=",op,"opVal",opVal)
                if LRoleDataMgr.m_bIsCrossServer then
                    Utils:ShowScrollTips(GUITips.RSI_CROSS_MOBAI_TIPS)
                else
                    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Arena.WarshipUI",AppDef.UIType.FirstClassLayer)
                    self:SendMsg(LGameMsg.m_initUIMsg)
                end
				LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, false)
				self:SendMsg(LGameMsg.m_baseMsgWithOne)
            end
            LGameMsg.m_autoPathMsg:ChangeToStart(11,endPos.x,endPos.y,0,bit.lshift(0,16),true,canJumpMap,AutoPachEndCallback)
            self:SendMsg(LGameMsg.m_autoPathMsg)
			LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, true)
			self:SendMsg(LGameMsg.m_baseMsgWithOne)
        end
   
end
function TaskTrackSubUI:OpenFriendUI() 
     LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Social.AddFriendLayer", AppDef.UIType.SecondClassLayer, 1)
    self:SendMsg(LGameMsg.m_initUIMsg)
end
function TaskTrackSubUI:OpenChatUI() 
      LGameMsg.m_baseMsgWithOne:Change(LUIChatEvent.showChat, string.format(GUITips.RSI_TASK_SJFY,LRoleDataMgr.MyHeroInfo.name))--"hi，大家好，我是"..LRoleDataMgr.MyHeroInfo.name.."，交个朋友吧！")
     self:SendMsg(LGameMsg.m_baseMsgWithOne)
   
end
--打开跨服聊天
function TaskTrackSubUI:OpenKuaFuChatUI() 
   
      if LRoleDataMgr.m_bIsCrossServer==false then   
           self:AutoPathKuaFuNpc()
           return
      end
      LGameMsg.m_baseMsgWithOne:Change(LUIChatEvent.showChat, string.format(GUITips.RSI_TASK_SJFY1,LRoleDataMgr.MyHeroInfo.name))--"hi，大家好，我是"..LRoleDataMgr.MyHeroInfo.name.."，交个朋友吧！")
      self:SendMsg(LGameMsg.m_baseMsgWithOne)
   
end

--打开神器界面
function  TaskTrackSubUI:OpenShengQiUI() 
    Utils:OpenFunction(AppDef.EModuleID.EMID_MUBIAO)
  
end
function TaskTrackSubUI:OpenActivityUI()
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Activity.ActivityMainUI",AppDef.UIType.FirstClassLayer,1)
    self:SendMsg(LGameMsg.m_initUIMsg)
end

function TaskTrackSubUI:OpenChoukaUI()
    Utils:OpenFunction(AppDef.EModuleID.EMID_CHOUKA)
end

--[[
打开日常界面
@param1:huodongId
]]
function TaskTrackSubUI:OpenRichangUI(huodongId)
--    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Activity.ActivityMainUI",AppDef.UIType.FirstClassLayer,1)
--    self:SendMsg(LGameMsg.m_initUIMsg)

--    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Activity.ActivityInfoUI",AppDef.UIType.PopWindow,huodongId)
--    self:SendMsg(LGameMsg.m_initUIMsg)
      Utils:OpenWanfaUI(huodongId)
end


--[[
打开竞技场界面
]]
function TaskTrackSubUI:OpenJingjiUI()
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Arena.ArenaMainUI",AppDef.UIType.FirstClassLayer)
    self:SendMsg(LGameMsg.m_initUIMsg)
end

--[[
打开帮派界面
]]
function TaskTrackSubUI:OpenBangUI(uiTab)
    Utils:OpenFunction(AppDef.EModuleID.EMID_BPLIEBIAO + uiTab - 1)
end

--[[
打开坐骑界面
]]
function TaskTrackSubUI:OpenMountUI(uiTab)
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Mount.MountMainUI",AppDef.UIType.FirstClassLayer,2)
    self:SendMsg(LGameMsg.m_initUIMsg)
end

--[[
打开神将界面
]]
function TaskTrackSubUI:OpenPetUI(uiTab)
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Pet.PetMainUI",AppDef.UIType.FirstClassLayer, uiTab or 1)
    self:SendMsg(LGameMsg.m_initUIMsg)
end

--[[
打开任务技能界面
]]
function TaskTrackSubUI:OpenHeroSkillUI()
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Skill.SkillUI",AppDef.UIType.FirstClassLayer)
    self:SendMsg(LGameMsg.m_initUIMsg)
end

--[[
打开锻造界面
@param1:uiTab锻造页签
]]
function TaskTrackSubUI:OpenDuanzaoUI(uiTab)
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Forge.ForgeMainUI",AppDef.UIType.FirstClassLayer,uiTab)
    self:SendMsg(LGameMsg.m_initUIMsg)
end

--[[
打开副本
]]
function TaskTrackSubUI:OpenFubenByTask(uiTab, uiInd)
    local ind = uiTab*100 + uiInd
    Utils:OpenInstance(ind)
end

--[[
打开玩法
]]
function TaskTrackSubUI:OpenWanfa(uiTab, uiInd)
   Utils:OpenFunction(AppDef.EModuleID.EMID_WANFA)
end

--[[
充值界面
]]
function TaskTrackSubUI:OpenRecharge(uiTab, uiInd)
   Utils:OpenRechargeMainUI()
end

--[[
成长基金
]]
function TaskTrackSubUI:OpenFundRebate(uiTab, uiInd)
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "WelfareActivity.FundRebateUI",AppDef.UIType.PopWindow)
    self:SendMsg(LGameMsg.m_initUIMsg)
end

--[[
斗神之路
]]
function TaskTrackSubUI:openMUBIAO(uiTab, uiInd)
    -- body
    Utils:OpenFunction(AppDef.EModuleID.EMID_MUBIAO)
end

--[[
打开活动
]]
function TaskTrackSubUI:openWelfareActivity( uiTab, uiInd )
    -- body
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "WelfareActivity.WelfareActivityUI",AppDef.UIType.Chat, uiTab)
    self:SendMsg(LGameMsg.m_initUIMsg)
end
--查找领奖天官
function TaskTrackSubUI:FindLingJingTianGuan()
    local secneType = LRoleDataMgr.MyHeroInfo.SceneType
    local factionWarScene = secneType == AppDef.SceneType.MSI_FACTION_WAR or secneType == AppDef.SceneType.MSI_FACTION_WAR_PRE
           or secneType == AppDef.SceneType.MSI_MULTISER_FACTION_BATTLE_READY or secneType == AppDef.SceneType.MSI_MULTISER_FACTION_BATTLE
    if factionWarScene == true then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_GL_CPT_TIP7)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
            return
    end 
    local function callback()
		LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, false)
		LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
        LRoleDataMgr.MyHeroInfo.isKuFuTaskAutoPath=true
        LuaNetSendMsg:QueryNpcChatOpen(1, 1,nil)  
    end 
    LGameMsg.m_autoPathMsg:ChangeToStart(11,2605,1181,1,bit.lshift(228,16),true,true,callback)
    LUIManager:SendMsg(LGameMsg.m_autoPathMsg)
	LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, true)
	LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
end
function TaskTrackSubUI:OpenFuli(uiTab)
    -- LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Welfare.WelfareUI",AppDef.UIType.Chat, uiTab)
    -- self:SendMsg(LGameMsg.m_initUIMsg)
end


return TaskTrackSubUI