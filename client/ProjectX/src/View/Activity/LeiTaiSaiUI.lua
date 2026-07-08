local TimerLabelUI = require("View.Common.TimerLabelUI")

local LeiTaiSaiUI = LUIBase:New()
LeiTaiSaiUI.__index = LeiTaiSaiUI
----------------------------------
LeiTaiSaiUI.IsHideInBattle = true
-----------------------------------
function LeiTaiSaiUI:New()
    local o = {}
    setmetatable(o, LeiTaiSaiUI)
    o:Init()
    return o
end
-----------------------------------
function LeiTaiSaiUI:Init()
    self.Script = "Activity.LeiTaiSaiUI"
    --------------------------------------------------
    self.m_isInit = true
    --------------------------------------------------
    self.m_tableCount = 0
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_pTablePanel = nil
    self.m_datas = nil
    self.m_pGridCellSize = nil
    --------------------------------------------------
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    --------------------------------------------------
    LuaNetSendMsg:QueryLeiTaiInfo(2)
    --------------------------------------------------
end

-----------------------------------
function LeiTaiSaiUI:onExit()
    local _ = self.m_pActivityTimer and self.m_pActivityTimer:Destory()
    local _ = self.m_pMatchingTimer and self.m_pMatchingTimer:Destory()
    local _ = self.m_pCDTimer and self.m_pCDTimer:Destory()
    self:Destory()
    self.m_tableCount = nil
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_pTablePanel = nil
    self.m_datas = nil
    self.m_pGridCellSize = nil
    self.m_pPanel = nil
    self.m_pBattleCheck = nil
    self.m_pRankingCheck = nil
    self.m_pMyDataPanel = nil
    self.m_pMyRankPanel = nil
    self.m_pTimeProgress = nil
    self.m_pResultLabel = nil
    self.m_pJifenLabel = nil
    self.m_pLeftTimesLabel = nil
    self.m_pMatchingText = nil
end

-----------------------------------
function LeiTaiSaiUI:InitUIControl()
    local pPanel = self.m_pUILayer:getChildByName("Battle")
    ------------------------------------------------------
    local pLocker = pPanel:getChildByName("btn_Locker")
    pLocker:addClickEventListener(handler(self, LeiTaiSaiUI.ShowHidePanel))
	self:MarkIntaractCObj(pLocker)
    ------------------------------------------------------
    local pRankingPanel = pPanel:getChildByName("Panel_QuestAndRanking")
    pRankingPanel:setVisible(false)
    self.m_pPanel = pRankingPanel
    ------------------------------------------------------
    local pHelpBtn = pRankingPanel:getChildByName("btn_Help")
    pHelpBtn:addClickEventListener(handler(self, LeiTaiSaiUI.HelpBtnClick))
	self:MarkIntaractCObj(pHelpBtn)
    ------------------------------------------------------
    local pBattleCheck = pRankingPanel:getChildByName("CheckBox_Quest")
    pBattleCheck:setTag(0)
    pBattleCheck:addClickEventListener(handler(self, LeiTaiSaiUI.ChangePanelClick))
	self:MarkIntaractCObj(pBattleCheck)
    self.m_pBattleCheck = pBattleCheck
    
    local pRankingCheck = pRankingPanel:getChildByName("CheckBox_Ranking")
    pRankingCheck:setTag(1)
    pRankingCheck:addClickEventListener(handler(self, LeiTaiSaiUI.ChangePanelClick))
	self:MarkIntaractCObj(pRankingCheck)
    self.m_pRankingCheck = pRankingCheck
    ------------------------------------------------------
    self.m_pMyDataPanel = pRankingPanel:getChildByName("Panel_Battle")
    self:InitMyUIControl()
    ------------------------------------------------------
    self.m_pMyRankPanel = pRankingPanel:getChildByName("Panel_Ranking")
    self:InitRankUIControl()
    ------------------------------------------------------
end
----------------------------------
function LeiTaiSaiUI:InitMyUIControl()
    if self.m_pMyDataPanel == nil then
        return
    end
    local pBattle = self.m_pMyDataPanel:getChildByName("Battle")
    ------------------------------------------------------
    local pTimeBg = pBattle:getChildByName("TimeBg")
    self.m_pTimeProgress = pTimeBg:getChildByName("LoadingBar")
    local pTime = pTimeBg:getChildByName("Time")
    self.m_pActivityTimer = TimerLabelUI:New(pTime, nil, nil, handler(self, LeiTaiSaiUI.UpdateActTimer))
    ------------------------------------------------------
    self.m_pResultLabel = pBattle:getChildByName("Result"):getChildByName("Text")
    self.m_pJifenLabel = pBattle:getChildByName("Jifen"):getChildByName("Text")
    self.m_pLeftTimesLabel = pBattle:getChildByName("Times"):getChildByName("Text")
    ------------------------------------------------------
    local pMatching = pBattle:getChildByName("Matching")
    self.m_pMatchingText = pMatching:getChildByName("Time")
    local pTime = self.m_pMatchingText:getChildByName("Text")
    
    self.m_pCDTimer = TimerLabelUI:New(pTime, nil, nil, handler(self, LeiTaiSaiUI.UpdateCDTimer))
    self.m_pMatchingTimer = TimerLabelUI:New(pTime, nil, nil, handler(self, LeiTaiSaiUI.UpdateMatchingTimer), true, 1800)
end
----------------------------------
function LeiTaiSaiUI:InitRankUIControl()
    if self.m_pMyRankPanel == nil then
        return
    end
    self.m_pTablePanel = self.m_pMyRankPanel:getChildByName("ListView")
    self.m_pTableView = self:InitTableView(self.m_pTablePanel)
    self.m_pGridCell = self.m_pMyRankPanel:getChildByName("Item")
    self.m_pGridCellSize = self.m_pGridCell:getContentSize()
end
-----------------------------------
function LeiTaiSaiUI:RegistMsgs()
    self.msgIds = 
    {
        LUILeiTaiSaiEvent.UpdateDataEvent,
        LUILeiTaiSaiEvent.UpdateRankEvent,
    }
    self:RegistSelf(self, self.msgIds)
end
-----------------------------------
function LeiTaiSaiUI:ProcessEvent(msg)
    if msg.msgId == LUILeiTaiSaiEvent.UpdateDataEvent then
        self:UpdateData(msg.value)
        self.m_isInit = false
    elseif msg.msgId == LUILeiTaiSaiEvent.UpdateRankEvent then
        self:UpdateRank(msg.value)
    end
end

function LeiTaiSaiUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
-----------------------------------
function LeiTaiSaiUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/BattleLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end
----------------------------------
function LeiTaiSaiUI:UpdateData(data)
    if self.m_isInit then
        self:ChangePanel(false)
    end

    self.m_pActivityTimer:set(data.actTime)
    self.m_pActivityTimer:start()

    self.m_pResultLabel:setString(string.format(GUITips.RSI_LTS_TIPS_3, data.winCount or 0, data.loseCount or 0))
    self.m_pJifenLabel:setString(data.jiFen or 0)
    self.m_pLeftTimesLabel:setString(data.leftLoseCount or 0)

    if data.cdTime > 0 then
        self.m_pMatchingTimer:stop()
        self.m_pCDTimer:set(data.cdTime or 0, handler(self, LeiTaiSaiUI.Convert2Matching))
        self.m_pCDTimer:start()
    else
        self.m_pCDTimer:stop()
        self.m_pMatchingTimer:set(data.matchTime or 0)
        self.m_pMatchingTimer:start()
    end
    if self.m_pPanel ~= nil then
        self.m_pPanel:setVisible(true)
    end
end
----------------------------------
function LeiTaiSaiUI:UpdateRank(datas)
    if datas == nil then
        return
    end
    Utils:FreeTable(self.m_datas)
    self.m_datas = nil
    self.m_datas = datas
    self.m_tableCount = #datas
    if self.m_pTableView then
        self.m_pTableView:reloadData()
    end
end
----------------------------------
function LeiTaiSaiUI:ShowHidePanel(sender)
    if sender == nil or self.m_pPanel == nil or self.m_pPanel:getNumberOfRunningActions() > 0 then
        return
    end
    local visibleSize = AppDef.frameSize
    local posX = self.m_pPanel:getPositionX()
    if math.floor(posX - visibleSize.width) > 0 then
        self.m_pPanel:runAction(cc.MoveTo:create(0.25, cc.p(visibleSize.width, self.m_pPanel:getPositionY())))
        sender:getChildByName("Arrows"):setScaleY(1)
    else
        self.m_pPanel:runAction(cc.MoveTo:create(0.25, cc.p(visibleSize.width+self.m_pPanel:getContentSize().width, self.m_pPanel:getPositionY())))
        sender:getChildByName("Arrows"):setScaleY(-1)
    end
end
----------------------------------
function LeiTaiSaiUI:HelpBtnClick(sender)
    local msg = string.format('%s|%s|%s|%s|', GUITips.RSI_LTS_HELP_2, GUITips.RSI_LTS_HELP_3, GUITips.RSI_LTS_HELP_4, GUITips.RSI_LTS_HELP_5)
    Utils:ShowDialog(msg)
end
----------------------------------
function LeiTaiSaiUI:ChangePanel(isRank)
    self.m_pMyDataPanel:setVisible(not isRank)
    self.m_pMyRankPanel:setVisible(isRank)
    if isRank then
        LuaNetSendMsg:QueryLeiTaiInfo(3)
    end
    self.m_pBattleCheck:getChildByName("Choose"):setVisible(not isRank)
    self.m_pRankingCheck:getChildByName("Choose"):setVisible(isRank)
end
----------------------------------
function LeiTaiSaiUI:ChangePanelClick(sender)
    self:ChangePanel(sender:getTag() > 0)
end
----------------------------------
function LeiTaiSaiUI:UpdateActTimer(pText, h, m, s, left)
    if pText ~= nil then
        pText:setString(string.format("%02d:%02d:%02d", h, m, s))
    end
    if self.m_pTimeProgress ~= nil then
        self.m_pTimeProgress:setPercent(left*100/1800)--写死总时间30分钟
    end
end
----------------------------------
function LeiTaiSaiUI:UpdateMatchingTimer(pText, h, m, s, left)
    self.m_pMatchingText:setString(GUITips.RSI_LTS_TIPS_2)
    if pText ~= nil then
        pText:setString(string.format("%02d:%02d", m, s))
    end
end
--------------------------------
function LeiTaiSaiUI:UpdateCDTimer(pText, h, m, s, left)
    self.m_pMatchingText:setString(GUITips.RSI_LTS_TIPS_1)
    if pText ~= nil then
        pText:setString(string.format("%02d:%02d", m, s))
    end
end
----------------------------------
function LeiTaiSaiUI:cellSizeForTable(sender,idx)
    return self.m_pGridCellSize.width, self.m_pGridCellSize.height
end
----------------------------------
function LeiTaiSaiUI:InitTableView(tbPanel)
    local cfg = {}
    cfg.tbPanel = tbPanel
    cfg.cellSizeForTable = function(sender,idx)
        return self:cellSizeForTable(sender, idx)
    end
    cfg.tableCellAtIndex = function(sender, idx)
        return self:TableCellAtIndex(sender, idx)
    end

    cfg.numberOfCellsInTableView = function() 
        return self.m_tableCount
    end

    return Utils:createTableView(cfg)
end
----------------------------------
function LeiTaiSaiUI:TableCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild = nil
    
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pGridCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cell:addChild(cellChild)
    else
        cellChild = cell:getChildByTag(123)
    end
    if cellChild ~= nil then
        self:updateItem(cellChild, self.m_datas[idx+1], idx+1)
    end
    return cell
end
----------------------------------
function LeiTaiSaiUI:updateItem(cell, info, idx)
    if cell == nil or info == nil then
        return
    end
    local pRank = cell:getChildByName("Ranking")
    local _ = pRank and pRank:setString(tostring(idx))

    local pName = cell:getChildByName("Name")
    local _ = pName and pName:setString(info.name or '')

    local pScore = cell:getChildByName("Point")
    local _ = pScore and pScore:setString(tostring(info.score or 0))
end
----------------------------------
function LeiTaiSaiUI:Convert2Matching()
    if self.m_pMatchingTimer then
        self.m_pMatchingTimer:set(0)
        self.m_pMatchingTimer:start()
    end
end
----------------------------------
return LeiTaiSaiUI