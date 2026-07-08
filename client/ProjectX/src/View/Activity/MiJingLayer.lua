local TimerLabelUI = require("View.Common.TimerLabelUI")

local MiJingLayer = LUIBase:New()
MiJingLayer.__index = MiJingLayer
----------------------------------
MiJingLayer.IsHideInBattle = true
local buffer = {
    "res/UI/ui_juese/ui_xuetiao_boss_03.png",
    "res/UI/ui_juese/ui_xuetiao_boss_04.png",
    "res/UI/ui_juese/ui_xuetiao_boss_01.png",
    "res/UI/ui_juese/ui_xuetiao_boss_02.png",
}
-----------------------------------
function MiJingLayer:New()
    local o = {}
    setmetatable(o, MiJingLayer)
    o:Init()
    return o
end
-----------------------------------
function MiJingLayer:Init()
    self.Script = "Activity.MiJingLayer"
    --------------------------------------------------
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    --------------------------------------------------
    LuaNetSendMsg:QueryMsBossInfo()
    LuaNetSendMsg:QueryMsBossReBorn(2)
    --------------------------------------------------
    self:DealTimeData(0)
end
-----------------------------------
function MiJingLayer:onExit()
    self:Destory()
    Utils:FreeTable(self.m_boss)
    self.m_boss = nil
    if self.m_pReBornTimer then
        self.m_pReBornTimer:Destory()
        self.m_pReBornTimer = nil
    end
    if self.m_pLeftTimer then
        self.m_pLeftTimer:Destory()
        self.m_pLeftTimer = nil
    end
    self.Script = nil
    self.m_pUILayer = nil
    self.m_pHead = nil
    self.m_pIcon = nil
    self.m_pName = nil
    self.m_pBloodProgress = nil
    self.m_pBloodProgress2 = nil
    self.m_pBloodText = nil
    self.m_pMsg = nil
    self.m_pLeftLoadingBar = nil
    self.m_pPanel = nil
    self.m_pIconSmall = nil 
    self.m_pNameSmall = nil
    self.m_pBadState = nil
    self.m_pGoodState = nil
    self.m_pReBornLoadingBar = nil
    self.m_pReBornText = nil
    self.m_pReBornBtn = nil
end
-----------------------------------
function MiJingLayer:InitUIControl()
    local pHead = self.m_pUILayer:getChildByName("Head")
    pHead:addClickEventListener(handler(self, MiJingLayer.GotoBossClick))
	self:MarkIntaractCObj(pHead)
    pHead:setVisible(false)
    self.m_pHead = pHead
    ------------------------------------------------------
    self.m_pIcon = pHead:getChildByName("Icon")
    ------------------------------------------------------
    self.m_pName = pHead:getChildByName("bg_name"):getChildByName("Value")
    ------------------------------------------------------
    local pBgBlood = pHead:getChildByName("bg_blood")
    local pBg = pBgBlood:getChildByName("Bg")
    self.m_pBloodProgress = pBg:getChildByName("LoadingBar_1")
    self.m_pBloodProgress2 = pBg:getChildByName("LoadingBar_2")
    self.m_pBloodText = pBg:getChildByName("Text")
    ------------------------------------------------------
    local pMsg = self.m_pUILayer:getChildByName("Lundao")
    pMsg:setVisible(false)
    self.m_pMsg = pMsg
    ------------------------------------------------------
    local pTopPanel = pMsg:getChildByName("Panel_Top")
    local pTime = pTopPanel:getChildByName("Time")
    self.m_pLeftLoadingBar = pTime:getChildByName("LoadingBar")
    local pLeftText = pTime:getChildByName("Value")
    self.m_pLeftTimer = TimerLabelUI:New(pLeftText, nil, nil, handler(self, MiJingLayer.LeftTimer))
    ------------------------------------------------------
    local pLocker = pMsg:getChildByName("btn_Locker")
    pLocker:addClickEventListener(handler(self, MiJingLayer.ShowHidePanel))
	self:MarkIntaractCObj(pLocker)
    ------------------------------------------------------
    self.m_pPanel = pMsg:getChildByName("Panel_QuestAndRanking")
    local pQuestPanel = self.m_pPanel:getChildByName("Panel_Quest")
    ------------------------------------------------------
    local pBoss = pQuestPanel:getChildByName("Boss")
    pBoss:setTouchEnabled(true)
    pBoss:addClickEventListener(handler(self, MiJingLayer.GotoBossClick))
	self:MarkIntaractCObj(pBoss)
    self.m_pIconSmall = pBoss:getChildByName("Head"):getChildByName("Icon")
    self.m_pNameSmall = pBoss:getChildByName("Name")
    ------------------------------------------------------
    local pState = pQuestPanel:getChildByName("state")
    self.m_pBadState = pState:getChildByName("Target")
    self.m_pGoodState = pState:getChildByName("Target_0")
    local pLoadingBg = pState:getChildByName("LoadingBg")
    self.m_pReBornLoadingBar = pLoadingBg:getChildByName("LoadingBar_1")
    self.m_pReBornText = pLoadingBg:getChildByName("Text")
    self.m_pReBornTimer = TimerLabelUI:New(self.m_pReBornText, nil, nil, handler(self, MiJingLayer.ReduceTimer))
    ------------------------------------------------------
    self.m_pReBornBtn = pState:getChildByName("Button")
    self.m_pReBornBtn:addClickEventListener(handler(self, MiJingLayer.ReBornClick))
	self:MarkIntaractCObj(self.m_pReBornBtn)
    ------------------------------------------------------
end
-----------------------------------
function MiJingLayer:RegistMsgs()
    self.msgIds = 
    {
        LUIMiJingEvent.UpdateHPEvent,
        LUIMiJingEvent.UpdateDataEvent,
        LUIMiJingEvent.UpdateFaildedTimeEvent,
        LUIMiJingEvent.UpdateBattleFailedEvent,
    }
    self:RegistSelf(self, self.msgIds)
end
-----------------------------------
function MiJingLayer:ProcessEvent(msg)
    if msg.msgId == LUIMiJingEvent.UpdateHPEvent then
        self:UpdateHPData(msg.value)
    elseif msg.msgId == LUIMiJingEvent.UpdateDataEvent then
        self:UpdateData(msg.value)
    elseif msg.msgId == LUIMiJingEvent.UpdateFaildedTimeEvent then
        self:DealTimeData(msg.value)
    elseif msg.msgId == LUIMiJingEvent.UpdateBattleFailedEvent then
        self:DealBattleFailedData(msg.value)
    end
end

function MiJingLayer:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
-----------------------------------
function MiJingLayer:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/MijingHpLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end
----------------------------------
function MiJingLayer:UpdateData(datas)
    for i=1,#datas do
        if datas[i] and datas[i].state and datas[i].state == 1 then
            self:UpdateReward(datas[i])
            if self.m_pHead ~= nil then
                self.m_pHead:setVisible(true)
            end
            if self.m_pMsg ~= nil then
                self.m_pMsg:setVisible(true)
            end
            return
        end
    end
    if self.m_pHead ~= nil then
        self.m_pHead:setVisible(false)
    end
    if self.m_pMsg ~= nil then
        self.m_pMsg:setVisible(false)
    end
end
----------------------------------
function MiJingLayer:UpdateHPData(data)
    -- dump(data, "data---->")
    if data == nil then
        local _ = self.m_pHead and self.m_pHead:setVisible(false)
        local _ = self.m_pMsg and self.m_pMsg:setVisible(false)
        return
    end
    Utils:FreeTable(self.m_boss)
    self.m_boss = nil
    self.m_boss = data
    self:UpdateBoss()
    if self.m_isInit == nil and self.m_pLeftTimer then
        self.m_pLeftTimer:set(data.leftTime)
        self.m_pLeftTimer:start()
        self.m_isInit = true
    end
end
----------------------------------
function MiJingLayer:UpdateBoss()
    if self.m_boss == nil then
        return
    end
    Utils:ShowPetHeadImg(self.m_pIcon, string.format('%dkf', self.m_boss.pic))
    Utils:ShowPetHeadImg(self.m_pIconSmall, self.m_boss.pic)
    self.m_pName:setString(self.m_boss.name)
    self.m_pNameSmall:setString(self.m_boss.name)
    self:UpdateProgress()
end
----------------------------------
function MiJingLayer:UpdateProgress()
    local max = self.m_boss.Maxhp
    local cur = self.m_boss.hp
    local curLevel = math.min(math.floor(cur/max*#buffer)+1, #buffer)
    local str = buffer[curLevel]
    local _ = str and self.m_pBloodProgress:loadTexture(str, UI_TEX_TYPE_PLIST)

    local str = tostring(math.max(math.floor(cur/10000), 1)) or ""
    str = str .. GUITips.RSI_FACTION_WAN .. "/"
    str = str .. tostring(math.floor(max/10000))
    str = str .. GUITips.RSI_FACTION_WAN
    self.m_pBloodText:setString(str)
    local full = max/#buffer
    local curLevelBlood = cur - (curLevel-1)*full
    -- dump({full, curLevelBlood, curLevel, curLevelBlood*100/full}, "UpdateProgress--->")
    self.m_pBloodProgress:setPercent(curLevelBlood*100/full)
    if curLevel > 1 and buffer[curLevel-1] then
        self.m_pBloodProgress2:setVisible(true)
        self.m_pBloodProgress2:loadTexture(buffer[curLevel-1], UI_TEX_TYPE_PLIST)
        self.m_pBloodProgress2:setPercent(100)
    else
        self.m_pBloodProgress2:setVisible(false)
    end
end
----------------------------------
function MiJingLayer:ReBornClick(sender, time)
    local left = time or self.m_pReBornTimer:get()
    if left > 0 then
        local okCallback = function()
            LuaNetSendMsg:QueryMsBossReBorn(1)
        end
        local msg = string.format(GUITips.RSI_MIJING_TIPS_3, left)
        Utils:ShowDialogOKCancel(msg, okCallback, nil, GUITips.RSI_MIJING_TIPS_4, nil, time ~= nil)
    else
        Utils:SendMsg(LUIMsgBoxEvent.HideMsgBox)
    end
end
----------------------------------
function MiJingLayer:DealTimeData(time)
    if time and time > 0 then
        self.m_pReBornTimer:set(time, function()
            self:ChangeWoundState(false)
        end)
        self.m_pReBornTimer:start()
        self:ChangeWoundState(true)
    else
        self.m_pReBornTimer:stop()
        self:ChangeWoundState(false)
    end
end
----------------------------------
function MiJingLayer:DealBattleFailedData()
    self:ReBornClick(nil, 60)
end
----------------------------------
function MiJingLayer:ReduceTimer(pText, h, m, s, left)
    if pText then
        local str = GUITips.RSI_MIJING_TIPS_2
        if h > 0 then
            str = str .. string.format("%02d:%02d:%02d", h, m, s)
        elseif m > 0 then
            str = str .. string.format("%02d:%02d", m, s)
        else
            str = str .. tostring(s) .. GUITips.UI_Arena_Msg4
        end
        pText:setString(str)
    end
    if self.m_pReBornLoadingBar then
        self.m_pReBornLoadingBar:setPercent(left*10/6)
    end
end
----------------------------------
function MiJingLayer:ShowHidePanel(sender)
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
function MiJingLayer:LeftTimer(pText, h, m, s, left)
    if pText then
        local str = nil
        if h > 0 then
            str = string.format("%02d:%02d:%02d", h, m, s)
        elseif m > 0 then
            str = string.format("%02d:%02d", m, s)
        else
            str = tostring(s)..GUITips.UI_Arena_Msg4
        end
        pText:setString(str or '')
    end
    if self.m_pLeftLoadingBar then
        self.m_pLeftLoadingBar:setPercent(left/18)
    end
end
----------------------------------
function MiJingLayer:GotoBossClick(sender)
    local sid = LRoleDataMgr.MyHeroInfo.sid
    LGameMsg.m_autoPathMsg:ChangeToStart(sid,-1,-1,1,bit.lshift(self.m_boss.id,16),true,false,nil)
    self:SendMsg(LGameMsg.m_autoPathMsg)
	LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, true)
	self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function MiJingLayer:ChangeWoundState(isWound)
    isWound = Utils:ToBool(isWound)
    self.m_pBadState:setVisible(isWound)
    self.m_pGoodState:setVisible(not isWound)
    self.m_pReBornLoadingBar:getParent():setVisible(isWound)
    if isWound then
        self.m_pReBornBtn:addClickEventListener(handler(self, MiJingLayer.ReBornClick))
		self:MarkIntaractCObj(self.m_pReBornBtn)
        self.m_pReBornBtn:getChildByName("Text"):setString(GUITips.RSI_MIJING_TIPS_4)
    else
        self.m_pReBornBtn:addClickEventListener(handler(self, MiJingLayer.GotoBossClick))
		self:MarkIntaractCObj(self.m_pReBornBtn)
        self.m_pReBornBtn:getChildByName("Text"):setString(GUITips.RSI_MIJING_TIPS_5)
        Utils:SendMsg(LUIMsgBoxEvent.HideMsgBox)
    end
end

function MiJingLayer:UpdateReward(info)
    if info == nil then
        return
    end
    local pBoss = self.m_pPanel:getChildByName("Panel_Quest"):getChildByName("Boss")
    local pListView = pBoss:getChildByName("ListView")
    local pItemModel = pBoss:getChildByName("Item")
    if pListView == nil or pItemModel == nil then
        return
    end
    pListView:removeAllItems()
    for i=1,#info.rewards do
        local pItem = pItemModel:clone()
        Utils:GetItemCellValue(pItem, 0, info.rewards[i], true, nil, nil, nil, true)
        pListView:pushBackCustomItem(pItem)
    end
end
----------------------------------
return MiJingLayer