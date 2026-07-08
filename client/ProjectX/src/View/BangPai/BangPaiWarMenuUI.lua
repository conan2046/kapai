--[[
lua里面的游戏逻辑控制
帮派战
]]

local BangPaiWarMenuUI = LUIBase:New()
BangPaiWarMenuUI.__index = BangPaiWarMenuUI
local TimerLabelUI = require("View.Common.TimerLabelUI")

local SID = 56
local NPCIDBEGIN = 76

--战斗中是否隐藏
BangPaiWarMenuUI.IsHideInBattle = true
--local this = LTcpSocket
function BangPaiWarMenuUI:New()
	local o = LUIBase:New()
	setmetatable(o,BangPaiWarMenuUI)	
    o:Init()
	return o
end

function BangPaiWarMenuUI:Init()
    self.m_pUILayer = cc.CSLoader:createNode("csd/GuildWar2Layer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    self:RegistMsgs()
    self:InitData()
    self:AddTouchEvt()
end

function BangPaiWarMenuUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
    self:UnSchedule()
    --检测活动结束
    Utils:unschedule(self.m_schedule)
    self.m_rankPanel = nil
    --排行榜部分
    self.m_rankCloseBtn = nil
    self.m_pLeftListView = nil
    self.m_pRightListView = nil
    if self.m_pCell then
        self.m_pCell:release()
        self.m_pCell = nil
    end
    self.m_mySorceLabel = nil
    self.m_myBpSorceLabel = nil
    self.m_myRankLabel = nil
    self.m_myBpRankLabel = nil
    self.m_actionPanel = nil
    self.m_actionPowerLabel = nil
    self.m_countDownPanel = nil
    self.m_countDownLabel = nil
    self.m_helpBtn = nil
    self._TimerList = nil
    if self._timerAct then
        self._timerAct:Destory()
        self._timerAct = nil
    end
    self.towerData = nil
    self.m_panelQR = nil
    self.towerList = nil

    if self._TimerList then
        for k,v in pairs(self._TimerList) do
            if v ~= nil then
                v:Destory()
            end
        end
    end
end

--[[
注册UI消息
]]
function BangPaiWarMenuUI:RegistMsgs()
    self.msgIds = 
    {
       LUIBangPaiWarEvent.ShowRankInfo,
       LUIBangPaiWarEvent.ShowCountDown,
       LUIBangPaiWarEvent.ShowActionPower,
	   LUIBangPaiWarEvent.ShowBoxCountDown,
       LUIBangPaiEvent.ShowBangPaiWarTask,
       LUITaskDataEvent.ShowTaskPanel,
       LUIBangPaiWarEvent.updateBpWarTowerUI,
       LUIBangPaiWarEvent.updateBpWarData,
       LUIBangPaiWarEvent.ShowBpWarHurtRank,
       LUIBangPaiWarEvent.ShowTakeTowerEvent,
       LUILogicEvent.EnterBattle,
    }
    self:RegistSelf(self,self.msgIds)
end

function BangPaiWarMenuUI:ProcessEvent(msg)
    if msg.msgId == LUIBangPaiWarEvent.ShowRankInfo then
        self:ShowRankUI(true)
    elseif msg.msgId == LUIBangPaiWarEvent.ShowCountDown then
        self:ShowCountDown(msg.msgId)
    elseif msg.msgId == LUIBangPaiWarEvent.ShowActionPower then
        self:ShowActionPower()
	elseif msg.msgId == LUIBangPaiWarEvent.ShowBoxCountDown then
		self:ShowCountDown(msg.msgId)
    elseif msg.msgId == LUIBangPaiEvent.ShowBangPaiWarTask then
        self.m_panelQR:setVisible(true)
    elseif msg.msgId == LUITaskDataEvent.ShowTaskPanel then
        self.m_panelQR:setVisible(not msg.value)
    elseif msg.msgId == LUIBangPaiWarEvent.updateBpWarTowerUI then
        self:updateTowerUI(msg.value)
    elseif msg.msgId == LUIBangPaiWarEvent.updateBpWarData then
        self:updateTowerInfo(msg.value)
    elseif msg.msgId == LUIBangPaiWarEvent.ShowBpWarHurtRank then
        self:initRankData(msg.value)
        self:updateRankUI()
    elseif msg.msgId == LUIBangPaiWarEvent.ShowTakeTowerEvent then
        self:ShowTakeTowerEvent(msg.value)
    elseif msg.msgId == LUILogicEvent.EnterBattle then
        LuaNetSendMsg:QueryBangPaiWarInfo(10)
    end
end

function BangPaiWarMenuUI:InitData()
    local panel = self.m_pUILayer:getChildByName("War")
    self.m_rankPanel = panel:getChildByName("Ranking")
    self.m_rankPanel:setVisible(false)
    self._TimerList = {}
    --------------------------------------------------
    self.m_rankTowerPanel = panel:getChildByName("Ranking_1")
    self.m_rankTowerPanel:setVisible(false)
    self._hurtList = {}
    local hurt1 = self.m_rankTowerPanel:getChildByName("Hurt_1")
    table.insert(self._hurtList, hurt1)
    local hurt2 = self.m_rankTowerPanel:getChildByName("Hurt_2")
    table.insert(self._hurtList, hurt2)
    local hurt3 = self.m_rankTowerPanel:getChildByName("Hurt_3")
    table.insert(self._hurtList, hurt3)

    self._nameList = {}
    local name1 = self.m_rankTowerPanel:getChildByName("zhanling_1"):getChildByName("Text"):getChildByName("Name")
    table.insert(self._nameList, name1)
    local name2 = self.m_rankTowerPanel:getChildByName("zhanling_2"):getChildByName("Text"):getChildByName("Name")
    table.insert(self._nameList, name2)
    local name3 = self.m_rankTowerPanel:getChildByName("zhanling_3"):getChildByName("Text"):getChildByName("Name")
    table.insert(self._nameList, name3)

    self._ListViewList = {}
    local ListView1 = self.m_rankTowerPanel:getChildByName("ListView_1")
    table.insert(self._ListViewList, ListView1)
    local ListView2 = self.m_rankTowerPanel:getChildByName("ListView_2")
    table.insert(self._ListViewList, ListView2)
    local ListView3 = self.m_rankTowerPanel:getChildByName("ListView_3")
    table.insert(self._ListViewList, ListView3)

    self._hertCell = self.m_rankTowerPanel:getChildByName("Name")
    self._hertCell:removeFromParent()
    self._hertCell:retain()

    local closeHurtRankBtn = self.m_rankTowerPanel:getChildByName("CloseBtn")
    local function closeHurtRankEvent( sender )
        -- body
        self.m_rankTowerPanel:setVisible(false)
    end
    closeHurtRankBtn:addClickEventListener(closeHurtRankEvent)

    ---------------------------------------------------
    local menuPanel = panel:getChildByName("ActionBg")
    menuPanel:setVisible(true)

    --排行榜部分
    self.m_rankCloseBtn = self.m_rankPanel:getChildByName("CloseBtn")
    self.m_pLeftListView = self.m_rankPanel:getChildByName("ListView_1")
    self.m_pRightListView = self.m_rankPanel:getChildByName("ListView_2")
 
    self.m_pCell = self.m_rankPanel:getChildByName("Name")
    self.m_pCell:retain()
    self.m_pCell:removeFromParent()

    self.m_bpCell = self.m_rankPanel:getChildByName("Name_0")
    self.m_bpCell:retain()
    self.m_bpCell:removeFromParent()

    local myRankPanel = self.m_rankPanel:getChildByName("PersonalBg")
    self.m_mySorceLabel = myRankPanel:getChildByName("PersonalScore"):getChildByName("Value")--我的积分
    self.m_myBpSorceLabel = myRankPanel:getChildByName("ServerScore"):getChildByName("Value")--本帮积分
    self.m_myRankLabel = myRankPanel:getChildByName("Ranking_1"):getChildByName("Value")--我的排行
    self.m_myBpRankLabel = myRankPanel:getChildByName("Ranking_2"):getChildByName("Value")--本帮排行

    --行动力
    self.m_actionPanel = menuPanel:getChildByName("Action")
    self.m_actionPowerLabel = self.m_actionPanel:getChildByName("Value")
    self.m_actionPanel:setVisible(false)

    --倒计时
    self.m_countDownPanel = menuPanel:getChildByName("Time")
    self.m_countDownLabel = self.m_countDownPanel:getChildByName("Value")
    self.m_countDownPanel:setVisible(false)

    --帮助按钮
    self.m_helpBtn = menuPanel:getChildByName("HelpBtn")
    ---------------------------------------------------------------------
    self.m_panelQR = panel:getChildByName("Panel_QuestAndRanking")
    ---------------------------------------------------------------------
    -- 右侧信息
    -- 任务按钮
    local pTaskCheck = self.m_panelQR:getChildByName("CheckBox_Quest")
    pTaskCheck:setTag(0)
    pTaskCheck:addClickEventListener(handler(self, BangPaiWarMenuUI.ChangePanelClick))
    self:MarkIntaractCObj(pTaskCheck)
    self.m_pTaskCheck = pTaskCheck
    self.m_pTaskCheck:getChildByName("Choose"):setVisible(true)
    
    
    local pTeamCheck = self.m_panelQR:getChildByName("CheckBox_Ranking")
    pTeamCheck:setTag(1)
    pTeamCheck:addClickEventListener(handler(self, BangPaiWarMenuUI.ChangePanelClick))
    self:MarkIntaractCObj(pTeamCheck)
    self.m_pTeamCheck = pTeamCheck
    self.m_pTeamCheck:getChildByName("Choose"):setVisible(false)
    ---------------------------------------------------------------------
    -- 隐藏与显示
    ---------------------------------------------------------------------
    local pLocker = panel:getChildByName("btn_Locker")
    pLocker:addClickEventListener(handler(self, BangPaiWarMenuUI.ShowHidePanel))
    self:MarkIntaractCObj(pLocker)

    local pHelpBtn = self.m_panelQR:getChildByName("btn_Help")
    pHelpBtn:addClickEventListener(handler(self, BangPaiWarMenuUI.HelpBtnClick))
    self:MarkIntaractCObj(pHelpBtn)
    ---------------------------------------------------------------------
    local allList = self.m_panelQR:getChildByName("AllList")
    self.towerList = allList:getChildByName("TowerList")
    self._towerTeamCell = allList:getChildByName("Tower_Team")
    self.towerList:setBounceEnabled(false)
    ---------------------------------------------------------------------
end

---------------------------------------------------------------------
function BangPaiWarMenuUI:ChangePanel(isTeam)
    --队伍的显示隐藏
    self.m_panelQR:setVisible(not isTeam)
    if isTeam then
        Utils:SendMsg(LUITaskDataEvent.ShowTaskPanel, true)
    end
end
---------------------------------------------------------------------
function BangPaiWarMenuUI:ChangePanelClick(sender)
    self:ChangePanel(sender:getTag() > 0)
end

---------------------------------------------------------------------
function BangPaiWarMenuUI:HelpBtnClick(sender)
    -- local msg = string.format('%s|%s|%s|%s|%s|%s|%s|%s|%s|', GUITips.RSI_XLXY_HELP_1, GUITips.RSI_XLXY_HELP_2, GUITips.RSI_XLXY_HELP_3, GUITips.RSI_XLXY_HELP_4, GUITips.RSI_XLXY_HELP_5, GUITips.RSI_XLXY_HELP_6, GUITips.RSI_XLXY_HELP_7, GUITips.RSI_XLXY_HELP_8, GUITips.RSI_XLXY_HELP_9)
    -- Utils:ShowDialog(msg)
    LuaNetSendMsg:QueryBangPaiWarInfo(19)
end

---------------------------------------------------------------------
function BangPaiWarMenuUI:ShowHidePanel(sender)
    if sender == nil or self.m_panelQR == nil or self.m_panelQR:getNumberOfRunningActions() > 0 then
        return
    end
    local visibleSize = AppDef.frameSize
    local posX = self.m_panelQR:getPositionX()
    if math.floor(posX - visibleSize.width) > 0 then
        self.m_panelQR:runAction(cc.MoveTo:create(0.25, cc.p(visibleSize.width, self.m_panelQR:getPositionY())))
        sender:getChildByName("Arrows"):setScaleY(1)
    else
        self.m_panelQR:runAction(cc.MoveTo:create(0.25, cc.p(visibleSize.width+self.m_panelQR:getContentSize().width, self.m_panelQR:getPositionY())))
        sender:getChildByName("Arrows"):setScaleY(-1)
    end
end
---------------------------------------------------------------------
function BangPaiWarMenuUI:AddTouchEvt()
--    local function OnCloseCallBack(sender)
--        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.BangPaiWarMenuUI")
--	    self:SendMsg(LGameMsg.m_initUIMsg)
--    end
--    self.m_closeButton:addClickEventListener(OnCloseCallBack)
	
    local function OnHelpCallBack(sender)
        local function OnOk()
        end
        Utils:ShowDialogOKCancel(GUITips.RSI_Help_Str13,OnOk)
    end
    self.m_helpBtn:addClickEventListener(OnHelpCallBack)
	self:MarkIntaractCObj(self.m_helpBtn)
    local function OnCloseRank(sender)
        self:ShowRankUI(false)
    end
    self.m_rankCloseBtn:addClickEventListener(OnCloseRank)
	self:MarkIntaractCObj(self.m_rankCloseBtn)
end

--排行榜-个人积分
function BangPaiWarMenuUI:LoadLeftRank(info)
    self.m_pLeftListView:removeAllChildren()
    for i=1,#info.ScoreRankList do
        local cell =  self.m_pCell:clone()
        local sign = false
        if info.ScoreRankList[i].name == LRoleDataMgr.MyHeroInfo.name then
            sign = true
        end
        self:ShowRankCell(cell,info.ScoreRankList[i],i,sign, false)
        self.m_pLeftListView:pushBackCustomItem(cell)
    end
end

--排行榜-帮派积分
function BangPaiWarMenuUI:LoadRightRank(info)
    self.m_pRightListView:removeAllChildren()
    for i=1,#info.bpScoreRankList do
        local cell =  self.m_bpCell:clone()
        local sign = false
        if info.bpScoreRankList[i].name == LRoleDataMgr.MyHeroInfo.FactionName then
            sign = true
        end
        self:ShowRankCell(cell,info.bpScoreRankList[i],i,sign, true)
        self.m_pRightListView:pushBackCustomItem(cell)
    end
end

--排行榜显示
function BangPaiWarMenuUI:ShowRankCell(cell,info,idx,sign, isBpRank)
    local bShowBg = math.fmod(idx, 2) == 1

    local bgSp = cell:getChildByName("Bg")
    bgSp:setVisible(bShowBg)

    local color = AppDef.UIColor.WHITE
    if sign then color = CCORANGE end

    local pPlaceNum = cell:getChildByName("PlaceNum")
    pPlaceNum:setString(tostring(info.rak))
    pPlaceNum:setTextColor(color)

    local pPlaceName = cell:getChildByName("PlaceName")
    pPlaceName:setString(info.name)
    pPlaceName:setTextColor(color)

    local pHurtValue = cell:getChildByName("HurtValue")
    pHurtValue:setString(tostring(info.score)) 
    pHurtValue:setTextColor(color)

    if isBpRank then
        local occupyNum = cell:getChildByName("OccupyNum")
        occupyNum:setString(tostring(info.towerNum))
        occupyNum:setTextColor(color)
    end

end

--隐藏显示帮派战积分排行榜
function BangPaiWarMenuUI:ShowRankUI(isShow)
   self.m_rankTowerPanel:setVisible(false)
   self.m_rankPanel:setVisible(isShow)
   if isShow then
       local info = LBangPaiWarDataMgr:GetWarRankData()
       self:ShowMyRankInfo(info)
       self:LoadLeftRank(info)
       self:LoadRightRank(info)
   end
end

--显示个人\帮派 积分信息
function BangPaiWarMenuUI:ShowMyRankInfo(info)
--    dump(info, "ShowMyRankInfo ----------->")
    self.m_mySorceLabel:setString(info.myScore)
    self.m_myBpSorceLabel:setString(info.mybpScore)
    self.m_myRankLabel:setString(info.myRank)
    self.m_myBpRankLabel:setString(info.mybpRank)

    local color = AppDef.UIColor.RED
    if info.myScore > 0 then
        color = AppDef.UIColor.GREEN
    end
    self.m_mySorceLabel:setTextColor(color) 
    color = AppDef.UIColor.RED
    if info.mybpScore > 0 then
        color = AppDef.UIColor.GREEN
    end
    self.m_myBpSorceLabel:setTextColor(color)
end

--显示行动力
function BangPaiWarMenuUI:ShowActionPower()
--行动力显示不再显示
    self.m_countDownPanel:setVisible(false)
    self.m_actionPanel:setVisible(true)
--    self.m_actionPanel:setString(GUITips.RSI_BPWAR_TIPS2)
    self.m_actionPowerLabel:setVisible(true)
    if self._timerAct == nil then
        self._timerAct = TimerLabelUI:New(self.m_actionPowerLabel, nil, nil, handler(self, BangPaiWarMenuUI.TimeReduce))
    end
    local leftTime = Utils:getFunctionTime(AppDef.EActivityID.EAID_FACTION_WAR)
    if leftTime > 0 then
        self._timerAct:set(leftTime, handler(self, BangPaiWarMenuUI.TimeCountDownEnd))
        self._timerAct:start()
    end
--    self.m_actionPowerLabel:setString(LBangPaiWarDataMgr.ActionPower)
end

function BangPaiWarMenuUI:TimeReduce( pText, h, m, s, left )
    -- body
    if pText == nil then
        return
    end

    local str = ""
    local day = 0
    if h > 24 then
        day = math.floor(h / 24)
        h = math.fmod(h, 24)
    end
    if day > 0 then
        str = str..tostring(day)..GUITips.Item_Info_Day
        str = str..string.format("%02d:%02d", h, m)
    else
        str = str..string.format("%02d:%02d", m, s)
    end
    
    pText:setString(str)
end

function BangPaiWarMenuUI:TimeCountDownEnd( ... )
    -- body
    self.m_actionPanel:setVisible(false)
    self._isActivityTimeOver = true
end

--显示倒计时
function BangPaiWarMenuUI:ShowCountDown(msgId)
    local function UpdateCD()
        self.m_coldTime = self.m_coldTime -1
		self:UpdateCoolTime()
	end
    self:ResetColdTime()
    --检测活动结束
    self:timeOutTips()
    self.m_countDownPanel:setVisible(true)
    self.m_actionPanel:setVisible(false)
	if msgId == LUIBangPaiWarEvent.ShowCountDown then
		self.m_coldTime = LBangPaiWarDataMgr.CountDown
	elseif msgId == LUIBangPaiWarEvent.ShowBoxCountDown then
		self.m_coldTime = LBangPaiWarDataMgr.BoxCountDown
        if self.m_coldTime > 0 then
            self._isActivityTimeOver = true
        end
	end
	self.m_msgId = msgId
    if self.m_coldTime > 0 then
        self:UpdateCoolTime()
        local scheduler =  AppDef.Director:getScheduler()
        self.m_schedulerID = scheduler:scheduleScriptFunc(UpdateCD,1,false)
		if msgId == LUIBangPaiWarEvent.ShowCountDown then
			self.m_countDownPanel:setString(GUITips.RSI_FACTION_MSG208)
		elseif msgId == LUIBangPaiWarEvent.ShowBoxCountDown then
			self.m_countDownPanel:setString(GUITips.RSI_FACTION_MSG212)
		end 
        self.m_countDownPanel:setTextColor(AppDef.UIColor.WHITE)
    else
		self.m_coldTime = 0
		if msgId == LUIBangPaiWarEvent.ShowCountDown then
		    self.m_countDownPanel:setString(GUITips.RSI_FACTION_MSG207)
		    self.m_countDownPanel:setTextColor(AppDef.UIColor.YELLOW)
		elseif msgId == LUIBangPaiWarEvent.ShowBoxCountDown then
			self.m_countDownPanel:setString(GUITips.RSI_FACTION_MSG213)
		    self.m_countDownPanel:setTextColor(AppDef.UIColor.YELLOW)
		end
    end
end

function BangPaiWarMenuUI:UnSchedule()
	if self.m_schedulerID ~= nil then
		AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_schedulerID)
		self.m_schedulerID  = nil
	end
end

function BangPaiWarMenuUI:ResetColdTime()
	self:UnSchedule()
	self.m_coldTime = 0;
	self.m_miMinute = 0;
	self.m_miSecond = 0;
    self.m_countDownLabel:setString("")
end

function BangPaiWarMenuUI:UpdateCoolTime()
	if self.m_coldTime <= 0 then
		self:ResetColdTime()
		if self.m_msgId == LUIBangPaiWarEvent.ShowCountDown then
			self.m_countDownPanel:setString(GUITips.RSI_FACTION_MSG207)
			self.m_countDownPanel:setTextColor(AppDef.UIColor.YELLOW)
		elseif self.m_msgId == LUIBangPaiWarEvent.ShowBoxCountDown then
			self.m_countDownPanel:setString(GUITips.RSI_FACTION_MSG213)
			self.m_countDownPanel:setTextColor(AppDef.UIColor.YELLOW)
		end
        return
    else
	    self.m_miMinute = math.floor(self.m_coldTime/60)
	    self.m_miSecond = self.m_coldTime%60;
    end
    local str = string.format("%02d:%02d",self.m_miMinute,self.m_miSecond) 
	self.m_countDownLabel:setString(str)

end

function BangPaiWarMenuUI:taskMoveToTower( sender )
    -- body
    if sender == nil then
        return
    end
    local npcId = sender:getTag()
    Utils:DeleteUI("Interact.NPCCollectUI")
    LuaNetSendMsg:QueryBangPaiWarInfo(10)
    LRoleDataMgr:autoPathToShiLian(SID, npcId)
end

function BangPaiWarMenuUI:updateTowerUI( data )
    -- body
    self:ShowActionPower()
    self.towerList:removeAllItems()
    self.towerData = data
    if self.towerData == nil then
        return
    end
    for i=1, #self.towerData do
        local data = self.towerData[i]
        local item = self._towerTeamCell:clone()
        local bg_head = item:getChildByName("bg_Head")
        local icon = bg_head:getChildByName("Icon")
        local Zhanling = item:getChildByName("Zhanling")
        local name = Zhanling:getChildByName("Name")
        self:updateTowerState(bg_head, name, data)
        local loading = item:getChildByName("Loading")
        local loadingBar = loading:getChildByName("LoadingBar")
        local num = loading:getChildByName("Num")
        local strNum = string.format("%d/%d", data.hp, data.maxHp)
        num:setString(strNum)
        local rate = data.hp / data.maxHp
        loadingBar:setPercent(rate * 100)

        local button = item:getChildByName("Button")
        button:setTag(data.id)
        button:addClickEventListener(handler(self, BangPaiWarMenuUI.taskMoveToTower))

        local strHead = Utils:GetNPCIconRes(data.picId, AppDef.HeadIconResType.Square)
        icon:loadTexture(strHead, ccui.TextureResType.localType)
        self.towerList:pushBackCustomItem(item)
    end

--    performWithDelay(self.m_pUILayer, function(sender)
        self:initLockStateCountDone()
    -- end, 0.2)
end

function BangPaiWarMenuUI:initLockStateCountDone( ... )
    -- body
    for i=1, 3 do
        local item = self.towerList:getItem(i - 1)
        if item ~= nil then
            local data = self.towerData[i]
            if data ~= nil then
                local bg_head = item:getChildByName("bg_Head")
--                data.leftCd = 100
                if data.leftCd > 0 then
                    local closeTag = bg_head:getChildByName("Close")
                    local closeEndTime = closeTag:getChildByName("Time")
                    closeTag:setVisible(true)
                    closeEndTime:setVisible(true)
                    self:showLockStateTimer(i, data.leftCd, closeEndTime)
                end
            end
        end
    end
end

function BangPaiWarMenuUI:showLockStateTimer( index, leftTime, timeText )
    -- body
    if  self._TimerList[index] == nil then
        self._TimerList[index] = TimerLabelUI:New(timeText, nil, nil, handler(self, BangPaiWarMenuUI.lockStateTimeReduce))
    else
        self._TimerList[index]:setLabel(timeText)
    end
    timeText:setTag(index)
    self._TimerList[index]:set(leftTime, handler(self, BangPaiWarMenuUI.lockStateTimeCountDownEnd))
    self._TimerList[index]:start()
end

--刷新单个数据
function BangPaiWarMenuUI:updateTowerInfo(twData)
    -- body
    --dump(twData, "updateTowerInfo ==========>")
    if self.towerData == nil then
        return
    end

    local index = 1
    for i=1, #self.towerData do
        local data = self.towerData[i]
        if data.id == twData.id then
            index = i
            self.towerData[i] = twData
            break
        end
    end
    self:updateTaskInfo(index - 1)
end

function BangPaiWarMenuUI:updateTaskInfo(index)
    -- body
    local item = self.towerList:getItem(index)
    if item == nil then
        return
    end
    local dataIndex = index + 1
    local data = self.towerData[dataIndex]
    if data == nil then
        return
    end
    local bg_head = item:getChildByName("bg_Head")
    local Zhanling = item:getChildByName("Zhanling")
    local name = Zhanling:getChildByName("Name")
    self:updateTowerState(bg_head, name, data)
    if data.leftCd > 0 then
        local closeEndTime = bg_head:getChildByName("Close"):getChildByName("Time")
        closeEndTime:setVisible(true)
        self:showLockStateTimer(dataIndex, data.leftCd, closeEndTime)
    end
    local loading = item:getChildByName("Loading")
    local loadingBar = loading:getChildByName("LoadingBar")
    local num = loading:getChildByName("Num")
    local strNum = string.format("%d/%d", data.hp, data.maxHp)
    num:setString(strNum)
    local rate = data.hp / data.maxHp
    loadingBar:setPercent(rate * 100)

end

function BangPaiWarMenuUI:updateTowerState(bg_head, name, data)
    -- body
    local close = bg_head:getChildByName("Close")
    local none = bg_head:getChildByName("None")
    local isHave = bg_head:getChildByName("Have")
    if data.onwerId > 0 then
        --锁定
        if data.leftCd > 0 then
            isHave:setVisible(false)
            close:setVisible(true)
            none:setVisible(false)
        else
            --占领
            isHave:setVisible(true)
            close:setVisible(false)
            none:setVisible(false)
        end
        name:setString(data.name)
    else
        --未占领
        isHave:setVisible(false)
        close:setVisible(false)
        none:setVisible(true)
        name:setString(GUITips.RSI_BPWAR_TIPS)
    end
end

function BangPaiWarMenuUI:initRankData(rankData)
    -- body
    if rankData == nil then
        return
    end
    self._rankData = rankData

    local function sortFuc(m1, m2)
        -- body
        return m1.shanghai > m2.shanghai
    end

    for i=1, #self._rankData do
        if #self._rankData[i] > 1 then
            table.sort(self._rankData[i], sortFuc)
        end
    end
    
end

function BangPaiWarMenuUI:updateRankUI( ... )
    -- body
    if self.m_rankPanel:isVisible() then
        self.m_rankPanel:setVisible(false)
    end
    self.m_rankTowerPanel:setVisible(true)

    for i=1, #self.towerData do
        local strTemp = "LoadingBar_1"
        local loadingBar = self._hurtList[i]:getChildByName("LoadingBar_1")
        local num = self._hurtList[i]:getChildByName("Text")
        local strNum = string.format("%d/%d", self.towerData[i].hp, self.towerData[i].maxHp)
        num:setString(strNum)
        local rate = self.towerData[i].hp / self.towerData[i].maxHp
        loadingBar:setPercent(rate * 100)

        if self.towerData[i].onwerId > 0 then
            self._nameList[i]:setString(self.towerData[i].name)
        else
            self._nameList[i]:setString(GUITips.RSI_BPWAR_TIPS)
        end
            
    end
    
    if self._rankData == nil then
        return
    end

    --dump(self._rankData, "777777777777777777777777777777777777777")

    for i=1, #self._rankData do
        self._ListViewList[i]:removeAllItems()
        for j=1, #self._rankData[i] do
            local data = self._rankData[i][j]
            local item = self._hertCell:clone()
            local placeNum = item:getChildByName("PlaceNum")
            placeNum:setString(j)
            local PlaceName = item:getChildByName("PlaceName")
            PlaceName:setString(data.name)
            local HurtValue = item:getChildByName("HurtValue")
            HurtValue:setString(data.shanghai)
            self._ListViewList[i]:pushBackCustomItem(item)
        end
    end

end

function BangPaiWarMenuUI:lockStateTimeReduce( pText, h, m, s, left )
    -- body
    if pText == nil then
        return
    end
    local str = ""
    local day = 0
    if h > 24 then
        day = math.floor(h / 24)
        h = math.fmod(h, 24)
    end
    if day > 0 then
        str = str..tostring(day)..GUITips.Item_Info_Day
        str = str..string.format("%02d:%02d", h, m)
    else
        str = str..string.format("%02d:%02d", m, s)
    end
    pText:setString(str)
end

function BangPaiWarMenuUI:lockStateTimeCountDownEnd( label )
    -- body
    local tag = label:getTag()
    local data = self.towerData[tag]
    if data == nil then
        return
    end
    data.leftCd = 0
    self:updateTaskInfo(tag - 1)
end

function BangPaiWarMenuUI:timeOutTips( ... )
    -- body
    local leftTime = Utils:getFunctionTime(AppDef.EActivityID.EAID_FACTION_WAR)
    if leftTime <= 0 then
        local sceneType = LRoleDataMgr.MyHeroInfo.SceneType
        if sceneType == AppDef.SceneType.MSI_FACTION_WAR_PRE then
            self.m_countDownPanel:setString(GUITips.RSI_BPWAR_TIPS2)
        else
            self.m_countDownPanel:setVisible(false)
        end
    else
        self._leftTime = leftTime
        self.m_schedule = Utils:schedule(self.m_pUILayer, handler(self, self.CheckTimeOut), 1, false)
    end

end

function BangPaiWarMenuUI:CheckTimeOut( ... )
    -- body
    if self._leftTime == nil then
        return
    end
    self._leftTime = self._leftTime - 1
    if self._leftTime < 0 then
        local sceneType = LRoleDataMgr.MyHeroInfo.SceneType
        if sceneType == AppDef.SceneType.MSI_FACTION_WAR_PRE then
            if self.m_countDownPanel ~= nil then
                self.m_countDownPanel:setString(GUITips.RSI_BPWAR_TIPS2)
            end
        end
        Utils:unschedule(self.m_schedule)
    end
end

function BangPaiWarMenuUI:ShowTakeTowerEvent( collectData )
    -- body
    local index = collectData.npcId - NPCIDBEGIN
    local data = self.towerData[index]
    if data == nil then
        return
    end

    if self._isActivityTimeOver ~= nil and self._isActivityTimeOver then
        Utils:ShowScrollTips(GUITips.RSI_FACTION_MSG215)
        return
    end

    if data.onwerId > 0 then
        --锁定
        if data.leftCd > 0 then
            if LRoleDataMgr.MyHeroInfo.FactionId == data.onwerId then
                Utils:ShowScrollTips(GUITips.RSI_BPWAR_TIPS_LOCK_BS)
            else
                local str = string.format(GUITips.RSI_BPWAR_TIPS_LOCK, data.name)
                Utils:ShowScrollTips(str)
            end
        else
            --占领
            if LRoleDataMgr.MyHeroInfo.FactionId == data.onwerId then
                Utils:ShowScrollTips(GUITips.RSI_BPWAR_TIPS_ALREADY_TAKE_BS)
            else
                LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Interact.NPCCollectUI",AppDef.UIType.PopWindow, collectData)
                self:SendMsg(LGameMsg.m_initUIMsg)
            end
        end
        return
    else
        --未占领
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Interact.NPCCollectUI",AppDef.UIType.PopWindow, collectData)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
end

return BangPaiWarMenuUI