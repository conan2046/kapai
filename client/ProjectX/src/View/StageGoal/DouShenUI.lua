local DouShenUI = LUIBase:New()
DouShenUI.__index = DouShenUI

local tagFactor = 10000
local maxCount = 6

local proBarConfig = {
    [1] = 0,
    [2] = 15,
    [3] = 45,
    [4] = 63,
    [5] = 75,
    [6] = 100,
}

function DouShenUI:New(taskId)
    local o = {}
    setmetatable(o,DouShenUI)  
    o:Init(taskId)
    return o
end

function DouShenUI:Init(taskId)
    self.Script = "StageGoal.DouShenUI"
    self.m_initTask = taskId
    self.m_isInit = false
    -----------------------------------
    self.m_datas = {}
    self.m_selectIndex = -1
    self.m_pLeftButton = {}
    -----------------------------------
    self.m_rightTableCount = 0
    self.m_pRightTableView = nil
    self.m_pRightGridCell = nil
    self.m_pRightGridCellSize = nil
    self.m_pRightTablePanel = nil
    -----------------------------------
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    --self:RegisterGuide()
    -----------------------------------
    LuaNetSendMsg:QueryTaskGiftList()
end
--[[
注册UI消息
]]
function DouShenUI:RegistMsgs()
    self.msgIds = 
    {
        LUITaskGiftEvent.LoadDataEvent,
        LUITaskGiftEvent.GetRewardRetEvent,
        LUITaskGiftEvent.UpdateDataEvent,
        LUITaskGiftEvent.InitTaskEvent,
        LUITaskGiftEvent.UpdateTaskEvent,
    }
    self:RegistSelf(self,self.msgIds)
end

function DouShenUI:ProcessEvent(msg)
    if msg.msgId == LUITaskGiftEvent.LoadDataEvent then
        self:UpdateListData(msg.value)
    elseif msg.msgId == LUITaskGiftEvent.GetRewardRetEvent then
        self:GetRewardResult(msg.value)
    elseif msg.msgId == LUITaskGiftEvent.UpdateDataEvent then
        self:UpdateData(msg.value)
    elseif msg.msgId == LUITaskGiftEvent.InitTaskEvent then
        local taskId = msg.value
        self:DealInitTaskEvent(taskId)
    elseif msg.msgId == LUITaskGiftEvent.UpdateTaskEvent then
        self:DealUpdateTaskEvent()
    end
end

function DouShenUI:DealInitTaskEvent(taskId)
    self.m_initTask = taskId
end

-- -----------------------------------
function DouShenUI:InitViewSize()
    self:CreateUINode("csd/TargetLayer.csb")
    if self.m_pUILayer then
        self.m_pUILayer:setVisible(false)
    end
end
-- -----------------------------------
function DouShenUI:InitUIControl()
    if self.m_pUILayer == nil then
        return
    end
    local panel = self.m_pUILayer:getChildByName("Panel_0")
    if panel == nil then
        return
    end
    ----------------------------------
    local pFunction = panel:getChildByName("Function")
    for i=1,maxCount do
        local pItem = pFunction:getChildByName("Button_"..i)
        pItem:setTag(i)
        pItem:addClickEventListener(handler(self, DouShenUI.LeftItemClick))
		self:MarkIntaractCObj(pItem)
        self:ResetItem(pItem)
        table.insert(self.m_pLeftButton, pItem)
    end
    self.m_pUnLockArea = pFunction:getChildByName("LoadingBar_1")
    self.m_pUnLockArea:setPercent(0)
    ----------------------------------
    local pTaskBg = Utils:FindNodeByName(panel, "Reward/RewardBg/TaskBg")
    local pTitleImage = pTaskBg:getChildByName("TitleImage")
    local pLoadingBg = pTitleImage:getChildByName("LoadingBg")
    self.m_pLoadingBar = pLoadingBg:getChildByName("LoadingBar")
    self.m_pLoadingText = pLoadingBg:getChildByName("Text")
    
    self.m_pTargetRewardList = pTitleImage:getChildByName("ListView")
    self.m_pTargetRewardList:setTouchEnabled(false)
    self.m_pItemModel = pTitleImage:getChildByName("IconBg")

    self.m_pGetRewardButton = pTitleImage:getChildByName("Button")
    self.m_pGetRewardButton:setTag(-1)
    self.m_pGetRewardButton:addClickEventListener(handler(self, DouShenUI.GetLeftRewardClick))
	self:MarkIntaractCObj(self.m_pGetRewardButton)
    ----------------------------------
    self.m_pRightTablePanel = pTaskBg:getChildByName("List")
    self.m_pRightGridCell = pTaskBg:getChildByName("Target_1")
    self.m_pRightGridCellSize = self.m_pRightGridCell:getContentSize()
    self.m_pRightTableView = self:InitRightTableView(self.m_pRightTablePanel)
    self.m_pRightTableView:setName("TableView")
    ----------------------------------
    local pCloseButton = panel:getChildByName("CloseBtn")
    pCloseButton:addClickEventListener(handler(self, DouShenUI.RemoveUI))
	self:MarkIntaractCObj(pCloseButton)
end

function DouShenUI:onExit()
    self:Destory()
    if self.m_pRightTablePanel then
        self.m_pRightTablePanel:removeChildByName("TableView")
        self.m_pRightTablePanel = nil
    end
    self.m_pUILayer = nil
    Utils:FreeTable(self.m_pLeftButton)
    self.m_pLeftButton = nil
    self.m_pLoadingText = nil
    self.m_pTargetRewardList = nil
    self.m_pUnLockArea = nil
    self.m_pItemModel = nil
    self.m_pRightGridCell = nil
    self.m_pLoadingBar = nil
    self.m_pRightGridCellSize = nil
    self.m_pRightTableView = nil
    self.m_pGetRewardButton = nil
    self.m_datas = nil

    Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_DSZL_1)
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_DSZL_2)
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_DSZL_3)
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_DSZL_FINISH)
end

function DouShenUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

function DouShenUI:setItem(cell, data, ind)
    self:SetCellSelect(cell, ind == (self.m_selectIndex+1))
    self:setName(cell, data)
    self:setMark(cell, data)
    self:setLoading(cell, data)
    self:setItemRedDot(cell, data)
end

function DouShenUI:ResetItem(pItem)
    self:SetCellSelect(pItem, false)
    self:setName(pItem)
    self:setMark(pItem)
    self:setLoading(pItem)
    self:setItemRedDot(pItem)
end

function DouShenUI:setName(cell, data)
    local pTitle = cell:getChildByName("Title")
    local pName = pTitle:getChildByName("Text")
    if pName then
        local str = ''
        if data ~= nil and data.id then
            local cfg = LDataConstMgr:GetDouShenConfig(data.id)
            if cfg then
                str = cfg.name
            end
        else
            local ind = cell:getTag()
            local cfg = LDataConstMgr:GetDouShenConfig(ind)
            if cfg then
                str = cfg.name
            end
        end
        pName:setString(str or '')
    end
end

function DouShenUI:setMark(cell, data)
    local pMark = cell:getChildByName("Mark")
    if pMark then
        pMark:setVisible(data == nil)
    end
end

function DouShenUI:setLoading(cell, data)
    local pNode = cell:getChildByName("Node")
    if pNode == nil then
        return
    end
    local progressBar = pNode:getChildByName("Progress")
    if progressBar == nil then
        local pSp = cc.Sprite:createWithSpriteFrameName("res/UI/ui_common/ui_jindu_quan.png")
        progressBar = cc.ProgressTimer:create(pSp)
        progressBar:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
        progressBar:setIgnoreAnchorPointForPosition(false)
        progressBar:setAnchorPoint(cc.p(0.5, 0.5))
        progressBar:setPosition(cc.p(0, 0))
        progressBar:setName("Progress")
        pNode:addChild(progressBar)
        ----------------------------------
        local proBar = self.m_pUILayer:getChildByName("LoadingImage")
        if proBar then
            progressBar:setScale(proBar:getScale())
        end
    end
    if data == nil then
        progressBar:setPercentage(0)
    else
        progressBar:stopAllActions()
        progressBar:runAction(cc.ProgressTo:create(0.5, data.finishMissionCount/(#data.missions)*100))
    end
end

function DouShenUI:setItemRedDot(cell, data)
    if cell == nil then
        return
    end
    local pRedDot = cell:getChildByName("Dot")
    if pRedDot then
        if data == nil then
            pRedDot:setVisible(false)
        else
            pRedDot:setVisible(data.state == 1 or data.haveReward)
        end
    end
end

function DouShenUI:SetCellSelect(cell, isSelect)
    if cell == nil then
        return
    end
    cell:getChildByName("Choose"):setVisible(Utils:ToBool(isSelect))
end

function DouShenUI:LeftTableCellTouched(ind)
    -- dump({self.m_selectIndex, ind}, "ind------------------>")
    if self.m_selectIndex == ind or ind < 0 then
        return
    end
    if self.m_selectIndex >= 0 then
        local pCell = self.m_pLeftButton[self.m_selectIndex + 1]
        local _ = pCell and self:SetCellSelect(pCell, false)
    end

    self.m_selectIndex = ind
    local pCell = self.m_pLeftButton[self.m_selectIndex + 1]
    local _ = pCell and self:SetCellSelect(pCell, true)
    self:UpdateLeftContent()
end
--[[
刷新区间奖励数据
]]
function DouShenUI:UpdateLeftContent()
    self:UpdateTopReward()
    self:UpdateBottomContent()
end
--[[
刷新区间
]]
function DouShenUI:UpdateLeftList()
    for i=1,#self.m_pLeftButton do
        self:setItem(self.m_pLeftButton[i], self.m_datas[i], i)
    end
    if self.m_pUnLockArea then
        local count = #self.m_datas
        self.m_pUnLockArea:setPercent(proBarConfig[count] or 0)
    end
end

function DouShenUI:UpdateListData(datas)
    if self.m_isInit == true then
        self.m_datas = datas
        self:InitProgress()
        self:UpdateLeftList()
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
            if datas[i].haveReward or datas[i].state == 1 then
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
    self:InitProgress()
    self:UpdateLeftList()

    if index and index > 1 then
        self:LeftTableCellTouched(index - 1)
    else
        self:LeftTableCellTouched(0)
    end

    if subIndex then
        Utils:MoveToTableIdxSec(self.m_pRightTableView, self.m_pRightGridCellSize.height, subIndex - 1)
    end

    local _ = self.m_pUILayer and self.m_pUILayer:setVisible(true)
    self.m_isInit = true
end

function DouShenUI:InitRightTableView(tbPanel)
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

function DouShenUI:RightTableCellAtIndex(sender, idx)
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
        pButton:addClickEventListener(handler(self, DouShenUI.GetRewardClick))
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
function DouShenUI:createModel(pModel, parent, pData, isPet, num, item, noTouch, noEffect)
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

function DouShenUI:setRightItem(cell, data, ind)
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

function DouShenUI:setRightItemState(cell, data, ind)
    local isFinish = data.isFinish
    local state = data.state
    local isLocked = (not isFinish) and (state == 0)

    local pFinishImg = cell:getChildByName("ReceiveImage")
    pFinishImg:setVisible(isFinish)

    local pButton = cell:getChildByName("Button")
    pButton:setVisible(not isFinish)

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

function DouShenUI:UpdateTopButton()
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

function DouShenUI:InitProgress(id)
    for i=1,#self.m_datas do
        local data = self.m_datas[i]

        data.finishMissionCount = 0
        local totalCount = #data.missions
        if data.state == 1 or data.state == 2 then
            data.finishMissionCount = totalCount
        else
            for i=1,totalCount do
                local mission = data.missions[i]
                if mission.isFinish then
                    data.finishMissionCount = data.finishMissionCount + 1
                end
            end
        end
        if id and id == data.id then
            break
        end
    end
end

function DouShenUI:UpdateTopProgress()
    if not self:UpdateTopButton() then
        return false
    end
    local data = self.m_datas[self.m_selectIndex + 1]

    local finishCount = data.finishMissionCount
    local totalCount = #data.missions

    if totalCount <= 0 then
        self.m_pLoadingBar:setPercent(0)
        self.m_pLoadingText:setString("0/0")    
        return
    end
    
    self.m_pLoadingBar:setPercent(math.floor(finishCount/totalCount*100))
    self.m_pLoadingText:setString(string.format("%d/%d", finishCount, totalCount))
    return true
end

function DouShenUI:UpdateTopReward()
    if not self:UpdateTopProgress() then
        return
    end

    local ind = self.m_selectIndex + 1
    self.m_pGetRewardButton:setTag(ind)

    local data = self.m_datas[ind]
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

function DouShenUI:UpdateBottomContent()
    if self.m_pRightTableView == nil then
        return
    end
    local datas = self.m_datas[self.m_selectIndex+1].missions
    self.m_rightTableCount = #datas
    self.m_pRightTableView:reloadData()
end

function DouShenUI:GetLeftRewardClick(sender)
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

function DouShenUI:HandleGetReward(tag)
    if tag == nil then
        return
    end
    local data = self.m_datas[self.m_selectIndex+1]
    if data == nil then
        return
    end
    local ind = math.fmod(tag, tagFactor)
    if ind == nil then
        return
    end
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
            if taskdata.missId > 320 and taskdata.missId < 325 and LRoleDataMgr.MyHeroInfo.FactionId == 0 then
                Utils:ShowScrollTips(GUITips.RSI_TARGET_RD_TIPS21)
            end
        elseif taskdata.state == 1 then--前往任务
            Utils:SendMsg(LUITaskDataEvent.ClickTask, taskdata.missId)
            self:RemoveUI()
        end
    else--任务完成
        LuaNetSendMsg:QueryTaskAward(taskdata.missId)
    end
end

function DouShenUI:GetRewardClick(sender)
    if sender == nil then
        return
    end
    self:HandleGetReward(sender:getTag())
end

function DouShenUI:GetRewardResult(id)
    if id == nil then
        return
    end
    for i=1,#self.m_datas do
        if self.m_datas[i].id == id then
            self.m_datas[i].state = 2
            self:InitProgress(id)
            self:UpdateTopButton()
            self:setItemRedDot(self.m_pLeftButton[i], self.m_datas[i])
            break
        end
    end
end

function DouShenUI:UpdateData(itemData)
    if itemData == nil then
        return
    end

    for i=1,#self.m_datas do
        if self.m_datas[i].id == itemData.id then
            itemData.name = self.m_datas[i].name
            itemData.awardId = self.m_datas[i].awardId
            itemData.awardNum = self.m_datas[i].awardNum
            self.m_datas[i] = itemData
            self:InitProgress(itemData.id)
            self:setItemRedDot(self.m_pLeftButton[i], self.m_datas[i])
            self:setLoading(self.m_pLeftButton[i], self.m_datas[i])
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

function DouShenUI:UpdateGotTaskInfo(taskId)
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

function DouShenUI:DealUpdateTaskEvent()
    self.m_datas = Utils:SortTaskGiftData(self.m_datas)
    self:UpdateLeftList()
    local _ = self.m_pRightTableView and self.m_pRightTableView:reloadData()
end

function DouShenUI:LeftItemClick(sender)
    if sender == nil then
        return
    end
    local ind = sender:getTag()
    if ind <= 0 then
        return
    end
    local data = self.m_datas[ind]
    -- dump({ind, data}, "LeftItemClick-->")
    if data == nil then
        local cfg = LDataConstMgr:GetDouShenConfig(ind)
        -- dump(cfg, "cfg--->")
        if ind == maxCount or cfg == nil then
            Utils:ShowScrollTips("敬请期待")
        elseif cfg then
            Utils:ShowScrollTips(string.format(GUITips.RSI_TARGET_RD_TIPS6, cfg.minLevel))
        end
        return
    end
    self:LeftTableCellTouched(ind - 1)
end

function DouShenUI:RegisterGuide()
    -- local data = LDataConstMgr:GetGuideData(GuideDef.StepId.Guide_DSZL_1)
    -- Utils:RegisterGuide(data.stepId, nil, function()end, data.maskOffset, true)

    -- local data = LDataConstMgr:GetGuideData(GuideDef.StepId.Guide_DSZL_2)
    -- Utils:RegisterGuide(data.stepId, nil, nil, data.maskOffset, true)

    -- local data = LDataConstMgr:GetGuideData(GuideDef.StepId.Guide_DSZL_3)
    -- Utils:RegisterGuide(data.stepId, nil, nil, data.maskOffset, true)

    -- local data = LDataConstMgr:GetGuideData(GuideDef.StepId.Guide_DSZL_4)
    -- Utils:RegisterGuide(data.stepId, nil, function()end, data.maskOffset, true)

    -- local data = LDataConstMgr:GetGuideData(GuideDef.StepId.Guide_DSZL_FINISH)
    -- Utils:RegisterGuide(data.stepId, nil, nil, data.maskOffset, true)
end

return DouShenUI