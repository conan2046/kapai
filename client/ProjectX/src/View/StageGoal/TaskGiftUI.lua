local TaskGiftUI = LUIBase:New()
TaskGiftUI.__index = TaskGiftUI

local tagFactor = 10000

function TaskGiftUI:New(taskId)
    local o = LUIBase:New()
    setmetatable(o,TaskGiftUI)  
    o:Init(taskId)
    return o
end

function TaskGiftUI:Init(taskId)
    self.Script = "StageGoal.TaskGiftUI"
    self.m_initTask = taskId
    self.m_isInit = false
    -----------------------------------
    self.m_datas = {}
    self.m_tableCount = 0
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_pGridCellSize = nil
    self.m_pTablePanel = nil
    self.m_selectIndex = 0
    self.m_isDragging = false
    -----------------------------------
    self.m_rightTableCount = 0
    self.m_pRightTableView = nil
    self.m_pRightGridCell = nil
    self.m_pRightGridCellSize = nil
    self.m_pRightTablePanel = nil
    -----------------------------------
    self:RegisterQuik()
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    -----------------------------------
    LuaNetSendMsg:QueryTaskGiftList()
end
--[[
注册UI消息
]]
function TaskGiftUI:RegistMsgs()
    self.msgIds = 
    {
        LUITaskGiftEvent.LoadDataEvent,
        LUITaskGiftEvent.GetRewardRetEvent,
        LUITaskGiftEvent.UpdateDataEvent,
        -- LUITaskDataEvent.GotTaskInfo,
        LUITaskGiftEvent.InitTaskEvent,
        LUITaskGiftEvent.UpdateTaskEvent,
    }
    self:RegistSelf(self,self.msgIds)
end

function TaskGiftUI:ProcessEvent(msg)
    if msg.msgId == LUITaskGiftEvent.LoadDataEvent then
        self:UpdateListData(msg.value)
    elseif msg.msgId == LUITaskGiftEvent.GetRewardRetEvent then
        self:GetRewardResult(msg.value)
    elseif msg.msgId == LUITaskGiftEvent.UpdateDataEvent then
        self:UpdateData(msg.value)
    -- elseif msg.msgId == LUITaskDataEvent.GotTaskInfo then
    --     local taskId = msg.value
    --     self:UpdateGotTaskInfo(taskId)
    elseif msg.msgId == LUITaskGiftEvent.InitTaskEvent then
        local taskId = msg.value
        self:DealInitTaskEvent(taskId)
    elseif msg.msgId == LUITaskGiftEvent.UpdateTaskEvent then
        self:DealUpdateTaskEvent()
    end
end

function TaskGiftUI:RegisterQuik()
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.UI_Title_Shenqi_Gift)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, handler(self, TaskGiftUI.RemoveUI))
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function TaskGiftUI:DealInitTaskEvent(taskId)
    self.m_initTask = taskId
end

-- -----------------------------------
function TaskGiftUI:InitViewSize()
    self:CreateUINode("csd/TargetLayer.csb")
    local _ = self.m_pUILayer and self.m_pUILayer:setVisible(false)
end
-- -----------------------------------
function TaskGiftUI:InitUIControl()
    if self.m_pUILayer == nil then
        return
    end
    local panel = self.m_pUILayer:getChildByName("Panel")
    if panel == nil then
        return
    end
    ----------------------------------
    self.m_pTablePanel = panel:getChildByName("BtnList")
    self.m_pTableView = self:InitTableView(self.m_pTablePanel)
    self.m_pTableView:setName("TableView")

    self.m_pGridCell = panel:getChildByName("Button1")
    self.m_pGridCellSize = self.m_pGridCell:getContentSize()
    ----------------------------------
    local pTaskBg = panel:getChildByName("TaskBg")
    local pTitleImage = pTaskBg:getChildByName("TitleImage")
    local pLoadingBg = pTitleImage:getChildByName("LoadingBg")
    self.m_pLoadingBar = pLoadingBg:getChildByName("LoadingBar")
    self.m_pLoadingText = pLoadingBg:getChildByName("Text")
    
    self.m_pTargetRewardList = pTitleImage:getChildByName("ListView")
    self.m_pTargetRewardList:setTouchEnabled(false)
    self.m_pItemModel = pTitleImage:getChildByName("IconBg")

    self.m_pGetRewardButton = pTitleImage:getChildByName("Button")
    self.m_pGetRewardButton:setTag(-1)
    self.m_pGetRewardButton:addClickEventListener(handler(self, TaskGiftUI.GetLeftRewardClick))
	self:MarkIntaractCObj(self.m_pGetRewardButton)
    ----------------------------------
    self.m_pRightTablePanel = pTaskBg:getChildByName("List")
    self.m_pRightGridCell = pTaskBg:getChildByName("Target_1")
    self.m_pRightGridCellSize = self.m_pRightGridCell:getContentSize()
    self.m_pRightTableView = self:InitRightTableView(self.m_pRightTablePanel)
    self.m_pRightTableView:setName("TableView")
    ----------------------------------
end

function TaskGiftUI:onExit()
    self:Destory()
    if self.m_pTablePanel then
        self.m_pTablePanel:removeChildByName("TableView")
    end
    if self.m_pRightTablePanel then
        self.m_pRightTablePanel:removeChildByName("TableView")
    end
    self.m_pUILayer = nil
    self.m_pTablePanel = nil
    self.m_pTableView = nil
    
    self.m_pGridCell = nil
    self.m_pGridCellSize = nil
    ----------------------------------
    self.m_pLoadingBar = nil
    self.m_pLoadingText = nil
    
    self.m_pTargetRewardList = nil
    self.m_pItemModel = nil

    self.m_pGetRewardButton = nil
    ----------------------------------
    self.m_pRightTablePanel = nil
    self.m_pRightGridCell = nil
    self.m_pRightGridCellSize = nil
    self.m_pRightTableView = nil
end

function TaskGiftUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

function TaskGiftUI:InitTableView(tbPanel)
    local cfg = {}
    cfg.tbPanel = tbPanel
    cfg.cellSizeForTable = function(sender,idx)
        return self.m_pGridCellSize.width, self.m_pGridCellSize.height
    end
    cfg.tableCellAtIndex = function(sender, idx)
        return self:LeftTableCellAtIndex(sender, idx)
    end

    cfg.numberOfCellsInTableView = function()
        return self.m_tableCount
    end

    cfg.tableCellTouched = function(sender, cell)
        return self:LeftTableCellTouched(cell:getIdx())
    end

    cfg.scrollViewDidScroll = function(view)
        self.m_isDragging = view:isDragging()
    end

    return Utils:createTableView(cfg)
end

function TaskGiftUI:SetCellSelect(cell, isSelect)
    if cell == nil then
        return
    end
    cell:getChildByName("ChooseBg"):setVisible(Utils:ToBool(isSelect))
end

function TaskGiftUI:LeftTableCellTouched(ind)
    -- dump({self.m_selectIndex, ind, self.m_isDragging}, "LeftTableCellTouched--------->")
    if self.m_selectIndex == ind then--or self.m_isDragging
        return
    end
    if self.m_selectIndex >= 0 then
        local pCell = self.m_pTableView:cellAtIndex(self.m_selectIndex)
        local _ = pCell and self:SetCellSelect(pCell:getChildByTag(123), false)
    end
    if ind >= 0 then
        local pCell = self.m_pTableView:cellAtIndex(ind)
        local _ = pCell and self:SetCellSelect(pCell:getChildByTag(123), true)
        self.m_selectIndex = ind
        self:UpdateLeftContent()
    end
end

function TaskGiftUI:UpdateLeftContent()
    self:UpdateTopReward()
    self:UpdateBottomContent()
end

function TaskGiftUI:LeftTableCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild = nil
    
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pGridCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setAnchorPoint(cc.p(0, 0))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)
    else
        cellChild = cell:getChildByTag(123)
    end
    if cellChild ~= nil then
        self:setItem(cellChild, self.m_datas[idx+1], idx+1)
    end
    return cell
end

function TaskGiftUI:UpdateListData(datas)
    if self.m_pTableView == nil then
        return
    end
    -- dump(self.m_initTask, "self.m_initTask---->")

    if self.m_isInit == true then
        local old = self.m_tableCount
        self.m_datas = datas
        self.m_tableCount = #self.m_datas
        if old ~= self.m_tableCount then
            local offset = self.m_pTableView:getContentOffset()
            self.m_pTableView:reloadData()
            self.m_pTableView:setContentOffset(offset)
        end
        self:UpdateLeftContent()
        return
    end

    --[[
    1：斗神有小红点，则打开后跳转到id最小的小红点等级区间界面。（优先级中间）
    2：斗神没有小红点，则打开后跳转到符合我当前等级的区间界面（优先级最低）
    3：通过支线任务完成点击，打开后跳转到该任务的等级区间界面(优先级最高)
    ]]
    local index,subIndex = nil
    if self.m_initTask and self.m_initTask > 0 then
        for i=1,#datas do
            local itemData = datas[i]
            for j=1,#itemData.missions do
                local missionData = itemData.missions[j]
                if missionData and missionData.missId == self.m_initTask then
                    index = i
                    subIndex = j
                    break
                end
            end
        end
    elseif self.m_initTask == 0 then
        for i=1,#datas do
            if datas[i].haveReward then
                index = i
                break
            end
        end
        if index == nil then
            for i=1,#datas do
                local itemData = datas[i]
                if (LRoleDataMgr.MyHeroInfo.level >= itemData.minLevel and LRoleDataMgr.MyHeroInfo.level <= itemData.maxLevel) then
                    index = i
                    break
                end
            end
        end
    end

    self.m_datas = datas
    self.m_tableCount = #self.m_datas
    self.m_pTableView:reloadData()

    -- dump({index, subIndex}, "index, subIndex-->")
    if index and index > 1 then
        Utils:MoveToTableIdxSec(self.m_pTableView, self.m_pGridCellSize.height, index - 1)
        self:LeftTableCellTouched(index - 1)
    else
        self:LeftTableCellTouched(0)
        self:UpdateLeftContent()
    end

    if subIndex then
        Utils:MoveToTableIdxSec(self.m_pRightTableView, self.m_pRightGridCellSize.height, subIndex - 1)
    end

    local _ = self.m_pUILayer and self.m_pUILayer:setVisible(true)
    self.m_isInit = true
end

function TaskGiftUI:setItem(cell, data, ind)
    -- dump({ind, (self.m_selectIndex+1)}, "ind == (self.m_selectIndex+1)--->")
    self:SetCellSelect(cell, ind == (self.m_selectIndex+1))
    local pName = cell:getChildByName("BtnName")
    -- local _ = pName and pName:setString(string.format(GUITips.RSI_TARGET_RD_TIPS1, data.minLevel, data.maxLevel))
    local _ = pName and pName:setString(data.name)
    self:setItemRedDot(cell, data)
end

function TaskGiftUI:setItemRedDot(cell, data)
    local pRedDot = cell:getChildByName("RedDot_0")
    local _ = pRedDot and pRedDot:setVisible(data.state == 1 or data.haveReward)
end

function TaskGiftUI:InitRightTableView(tbPanel)
    local cfg = {}
    cfg.tbPanel = tbPanel
    cfg.cellSizeForTable = function(sender,idx)
        return self.m_pRightGridCellSize.width, self.m_pRightGridCellSize.height
    end
    cfg.tableCellAtIndex = function(sender, idx)
        return self:RightTableCellAtIndex(sender, idx)
    end

    cfg.numberOfCellsInTableView = function()
        return self.m_rightTableCount
    end

    return Utils:createTableView(cfg)
end

function TaskGiftUI:RightTableCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild = nil
    
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pRightGridCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setAnchorPoint(cc.p(0, 0))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)

        local pButton = cellChild:getChildByName("Button")
        pButton:addClickEventListener(handler(self, TaskGiftUI.GetRewardClick))
		self:MarkIntaractCObj(pButton)
        local pItemModel = cellChild:getChildByName("IconBg_1")
        local _ = pItemModel and pItemModel:setVisible(false)
    else
        cellChild = cell:getChildByTag(123)
    end
    if cellChild ~= nil then
        local data = self.m_datas[self.m_selectIndex+1]
        if data then
            self:setRightItem(cellChild, data.missions[idx+1], idx+1)
        end
    end
    return cell
end

----------------------------------------------------------------
function TaskGiftUI:createModel(pModel, parent, pData, isPet, num, item, noTouch, noEffect)
    local pItem = pModel:clone()
    if isPet then
        Utils:ShowPet(pData, parent, pItem, noTouch)
        --宠物特效
        if (noEffect == nil or noEffect == false) then
            local data = LPetDataMgr:FindPetDataById(pData)
            if data and data.quality >= 3 then
                local posX = pItem:getContentSize().width / 2
                local posY = pItem:getContentSize().height / 2
                Utils:createAnimEffect(pItem, cc.p(posX, posY), "res2/fx/gaojiwupin")
            end
        end
    else
        local item = Utils:GetItemCellValue(pItem, 0, pData, true, num ~= nil, num, nil, (noTouch == nil or noTouch == false))
        --物品特效
        if (noEffect == nil or noEffect == false) then
            local quality = Utils:getQualityByItem(item)
            if quality >= 5 then
                local posX = pItem:getContentSize().width / 2
                local posY = pItem:getContentSize().height / 2
                Utils:createAnimEffect(pItem, cc.p(posX, posY), "res2/fx/gaojiwupin")
            end
        end
    end
    pItem:setVisible(true)
    return pItem
end

function TaskGiftUI:setRightItem(cell, data, ind)
    if data == nil or cell == nil then
        return
    end

    local pTitle = cell:getChildByName("Title")
    local pTitleText = pTitle:getChildByName("Text")

    if data.baseData == nil then
        pTitleText:setString("没有找到任务："..data.missId)
        return
    end

    pTitleText:setString(data.baseData.name)
    pTitle:setContentSize(cc.size(pTitleText:getContentSize().width+100, pTitle:getContentSize().height))

    local pDescPanel = pTitle:getChildByName("Panel_1")
    local pAysDesc = pDescPanel:getChildByName("AysDesc")
    if pAysDesc == nil then
        local pDesc = pDescPanel:getChildByName("Desc")
        if pDesc then
            pAysDesc = Utils:CreateColorText2(pDescPanel, pDesc, pDescPanel:getContentSize())
            pAysDesc:setName("AysDesc")
        end
    end
    
    local missId = data.missId
    local isFinish = data.isFinish
    local state = data.state

    if pAysDesc then
        local str = ""
        if isFinish or state == 2 then
            str = string.gsub(data.baseData.desc, '<num>', data.baseData.target.maxNum)
        else
            if state == 0 then
                str = string.gsub(data.baseData.desc, '<num>', '0')
            elseif state == 1 then
                local taskdata = data.taskData
                str = (taskdata and {taskdata.info} or {""})[1]
            end
        end
        -- if (str == nil or str == '') and (taskdata == nil or taskdata.info == nil) then
        --     -- Utils:Debug(isFinish, state, taskdata, "taskdata == nil or taskdata.info == nil")
        --     if AppDef.OPEN_BUGLY then
        --         local app = cc.Application:getInstance()
        --         local target = app:getTargetPlatform()
        --         if target == cc.PLATFORM_OS_ANDROID or target == cc.PLATFORM_OS_IPHONE or target == cc.PLATFORM_OS_IPAD then
        --             if isFinish == false then
        --                 buglyReportLuaException("isFinish->false", debug.traceback())
        --             end
        --             if state == nil then
        --                 buglyReportLuaException("state == nil", debug.traceback())
        --             else
        --                 buglyReportLuaException("state ->"..state, debug.traceback())
        --             end
        --             if taskdata == nil then
        --                 buglyReportLuaException("taskdata == nil", debug.traceback())
        --             elseif taskdata.info == nil then
        --                 buglyReportLuaException("taskdata.info == nil", debug.traceback())
        --             end
        --         end
        --     end
        -- end
        pAysDesc:setString(str or "")
    end

    local pListView = cell:getChildByName("ListView")
    pListView:setTouchEnabled(false)
    pListView:removeAllItems()

    -- dump(data.baseData.rewards, "data.baseData.rewards-->")

    for i=1,#data.baseData.rewards do
        local rewardData = data.baseData.rewards[i]
        local pItem = nil
        if rewardData and #rewardData > 0 then
            local subType = tonumber(rewardData[1])
            local idNum = tonumber(rewardData[2])
            if subType == AppDef.AwrdItem.AWRD_ITEM_PET then
                if self.m_pPetItemModel then
                    pItem = self:createModel(self.m_pPetItemModel, pListView, idNum, true)
                end
            else
                pItem = self:createModel(self.m_pItemModel, pListView, subType, false, idNum)
            end
            local _ = pItem and pListView:pushBackCustomItem(pItem)
        end
    end
    self:setRightItemState(cell, data, ind)
end

function TaskGiftUI:setRightItemState(cell, data, ind)
    local isFinish = data.isFinish
    local state = data.state
    local isLocked = (not isFinish) and (state == 0)

    local pFinishImg = cell:getChildByName("ReceiveImage")
    pFinishImg:setVisible(isFinish)

    local pButton = cell:getChildByName("Button")
    pButton:setVisible(not isFinish)
    -- local pLevelText = cell:getChildByName("LevelText")
    -- local pTaskText = cell:getChildByName("TaskText")
    -- if isLocked then
    --     pButton:setVisible(false)
    --     pLevelText:setVisible(true)
    --     pTaskText:setVisible(true)
    --     pLevelText:setString(string.format(GUITips.RSI_TARGET_RD_TIPS6, data.baseData.minLevel))
    --     if data.preTaskData == nil and data.baseData.premissionLimit then
    --         data.preTaskData = LDataConstMgr:GetMissionData(data.baseData.premissionLimit[1])
    --     end
    --     if data.preTaskData then
    --         pTaskText:setString(string.format(GUITips.RSI_TARGET_RD_TIPS7, data.preTaskData.name))
    --     elseif data.baseData.premissionLimit then
    --         print("找不到前置任务->", data.baseData.premissionLimit[1], debug.traceback())
    --     end
    -- else
    --     pButton:setVisible(not isFinish)
    --     pLevelText:setVisible(false)
    --     pTaskText:setVisible(false)
    -- end

    if pButton:isVisible() then
        local pBtnRedDot = pButton:getChildByName("RedDot")
        pBtnRedDot:setVisible(state == 2 and (not isFinish))

        local pBtnText = pButton:getChildByName("Text")
        if not isFinish then
            if state == 1 or state == 0 then
                pButton:setTag(ind)
            elseif state == 2 then
                pButton:setTag(ind + tagFactor)
            end

            if state == 0 then
                pButton:setBright(false)
            else
                pButton:setBright(true)
                pButton:setEnabled(true)
            end

            if state == 0 then
                pBtnText:setString(GUITips.RSI_TARGET_RD_TIPS2)
            elseif state == 1 then
                pBtnText:setString(GUITips.RSI_TARGET_RD_TIPS3)
            else
                pBtnText:setString(GUITips.RSI_TARGET_RD_TIPS4)
            end
        else
            pButton:setBright(false)
            pButton:setEnabled(false)
            pBtnText:setString(GUITips.RSI_TARGET_RD_TIPS10)
        end
    end
end

function TaskGiftUI:UpdateTopButton()
    if self.m_selectIndex < 0 or self.m_selectIndex >= #self.m_datas then
        return false
    end
    local data = self.m_datas[self.m_selectIndex + 1]
    -- dump(data, "--------->")
    if self.m_pGetRewardButton then
        local isCanGet = (data.state == 1)
        self.m_pGetRewardButton:setBright(isCanGet)
        self.m_pGetRewardButton:setEnabled(isCanGet)
        if data.state == 0 or data.state == 1 then
            self.m_pGetRewardButton:getChildByName("Text"):setString(GUITips.RSI_TARGET_RD_TIPS4)
        elseif data.state == 2 then
            self.m_pGetRewardButton:getChildByName("Text"):setString(GUITips.RSI_TARGET_RD_TIPS11)
        end

        local pRedDot = self.m_pGetRewardButton:getChildByName("RedDot_0")
        pRedDot:setVisible(isCanGet)
    end
    return true
end

function TaskGiftUI:UpdateTopProgress()
    if not self:UpdateTopButton() then
        return false
    end
    local data = self.m_datas[self.m_selectIndex + 1]

    local finishCount = 0
    local totalCount = #data.missions

    if data.state == 1 or data.state == 2 then
        finishCount = totalCount
    else
        for i=1,totalCount do
            local mission = data.missions[i]
            if mission.isFinish then
                finishCount = finishCount + 1
            end
        end
    end
    if totalCount <= 0 then
        self.m_pLoadingBar:setPercent(0)
        self.m_pLoadingText:setString("0/0")    
        return
    end
    
    self.m_pLoadingBar:setPercent(math.floor(finishCount/totalCount*100))
    self.m_pLoadingText:setString(string.format("%d/%d", finishCount, totalCount))
    return true
end

function TaskGiftUI:UpdateTopReward()
    if not self:UpdateTopProgress() then
        return
    end

    local ind = self.m_selectIndex + 1
    self.m_pGetRewardButton:setTag(ind)

    local data = self.m_datas[ind]
    -- if data.awardId == nil then
    --     dump({ind, data}, "data--->")
    -- end
    local cData = #data.awardId

    self.m_pTargetRewardList:removeAllItems()
    for i=1,#data.awardId do
        local pItem = self.m_pItemModel:clone()
        local id = data.awardId[i]
        if id == AppDef.AwrdItem.AWRD_ITEM_ARTIFACT then
            Utils:GetItemCellValue(pItem, 1, data.awardNum[i], true, nil, nil, nil, true)
        elseif id >= AppDef.AwrdItem.AWRD_ITEM_COIN then
            Utils:GetItemCellValue(pItem, 0, id, true, true, data.awardNum[i], nil, true)
        else
            Utils:GetItemCellValue(pItem, 0, id, true, true, data.awardNum[i], nil, true)
        end
        self.m_pTargetRewardList:pushBackCustomItem(pItem)
    end
end

function TaskGiftUI:UpdateBottomContent()
    if self.m_pRightTableView == nil then
        return
    end

    -- dump({self.m_selectIndex+1, #self.m_datas}, "=========>")

    local datas = self.m_datas[self.m_selectIndex+1].missions
    self.m_rightTableCount = #datas
    self.m_pRightTableView:reloadData()
end

function TaskGiftUI:GetLeftRewardClick(sender)
    if sender == nil then
        return
    end
    local tag = sender:getTag()
    if tag <= 0 then
        return
    end
    local data = self.m_datas[tag]
    LuaNetSendMsg:QueryGetTaskGiftReward(data.id)
end

function TaskGiftUI:GetRewardClick(sender)
    if sender == nil then
        return
    end
    local data = self.m_datas[self.m_selectIndex+1]
    if data == nil then
        return
    end

    local tag = sender:getTag()
    local ind = math.fmod(tag, tagFactor)
    local taskdata = data.missions[ind]
    if taskdata == nil then
        return
    end

    if tag < tagFactor then
        if taskdata.state == 0 then--任务未解锁
            if taskdata.preTaskData == nil and taskdata.baseData.premissionLimit then
                taskdata.preTaskData = LDataConstMgr:GetMissionData(taskdata.baseData.premissionLimit[1])
            end
            local str = string.format(GUITips.RSI_TARGET_RD_TIPS6, taskdata.baseData.minLevel)
            Utils:ShowScrollTips(str)
            if taskdata.preTaskData then
                str = string.format(GUITips.RSI_TARGET_RD_TIPS7, taskdata.preTaskData.name)
                Utils:ShowScrollTips(str)
            end
        elseif taskdata.state == 1 then--前往任务
            Utils:SendMsg(LUITaskDataEvent.ClickTask, taskdata.missId)
            self:RemoveUI()
        end
    else--任务完成
        LuaNetSendMsg:QueryTaskAward(taskdata.missId)
    end
end

function TaskGiftUI:GetRewardResult(id)
    if id == nil then
        return
    end
    for i=1,#self.m_datas do
        if self.m_datas[i].id == id then
            self.m_datas[i].state = 2
            self:UpdateTopButton()
            local pCell = self.m_pTableView:cellAtIndex(i-1)
            if pCell then
                local pCellChild = pCell:getChildByTag(123)
                self:setItemRedDot(pCellChild, self.m_datas[i])
            end
            break
        end
    end
end

function TaskGiftUI:UpdateData(itemData)
    if itemData == nil then
        return
    end

    for i=1,#self.m_datas do
        if self.m_datas[i].id == itemData.id then
            itemData.name = self.m_datas[i].name
            itemData.awardId = self.m_datas[i].awardId
            itemData.awardNum = self.m_datas[i].awardNum
            self.m_datas[i] = itemData

            local pCell = self.m_pTableView:cellAtIndex(i-1)
            if pCell then
                self:setItemRedDot(pCell:getChildByTag(123), itemData)
            end
            break
        end
    end
    self:UpdateTopProgress()
    if self.m_pRightTableView then
        for i=1,#itemData.missions do
            local pCell = self.m_pRightTableView:cellAtIndex(i-1)
            if pCell then
                local pCellChild = pCell:getChildByTag(123)
                self:setRightItem(pCellChild, itemData.missions[i], i)
            end
        end
    end
end

function TaskGiftUI:UpdateGotTaskInfo(taskId)
    -- dump({taskId, LRoleDataMgr.Task.taskIdMap[taskId]}, "taskId-->")
    if self.m_datas == nil or taskId == nil or LRoleDataMgr.Task.taskIdMap[taskId] == nil then
        return
    end
    local ind,subInd,itData = nil,nil,nil
    for i=1,#self.m_datas do
        local itemData = self.m_datas[i]
        local isExist = false
        for j=1,#itemData.missions do
            local misData = itemData.missions[j]
            -- dump({misData.missId, misData.state, misData.missId == taskId}, "misData.missId == taskId-->")
            if misData and misData.missId == taskId then
                local haveReward = Utils:UpdateTaskGiftState(misData)
                if haveReward then
                    itemData.haveReward = haveReward
                end
                isExist = true
                break
            end
        end
        if itemData.haveReward then
            itemData.haveReward = false
            for j=1,#itemData.missions do
                if itemData.missions[j].state == 2 then
                    itemData.haveReward = true
                    break
                end
            end
        end
        if isExist then
            break
        end
    end
    self.m_datas = Utils:SortTaskGiftData(self.m_datas)
    local _ = self.m_pRightTableView and self.m_pRightTableView:reloadData()
end

function TaskGiftUI:DealUpdateTaskEvent()
    self.m_datas = Utils:SortTaskGiftData(self.m_datas)
    local _ = self.m_pRightTableView and self.m_pRightTableView:reloadData()
end

return TaskGiftUI