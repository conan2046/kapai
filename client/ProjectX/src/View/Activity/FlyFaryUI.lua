local FlyFaryUI = LUIBase:New()
FlyFaryUI.__index = FlyFaryUI
FlyFaryUI.IsHideInBattle = true
function FlyFaryUI:New()
    local o = LUIBase:New()
    setmetatable(o,FlyFaryUI)  
    o:Init()
    return o
end

--[[
注册UI消息
]]
function FlyFaryUI:RegistMsgs()
    self.msgIds = 
    {
        LUIActivityEvent.RefreshFlyFary,
    }
    self:RegistSelf(self,self.msgIds)
end

function FlyFaryUI:ProcessEvent(msg)
    if msg.msgId == LUIActivityEvent.RefreshFlyFary then
    	self:UpdateInfo()
    end
end

function FlyFaryUI:Init()
    self:RegistMsgs()
    self.m_pUILayer = cc.CSLoader:createNode("csd/feixianzhanchangLayer.csb")
    local frameSize = AppDef.frameSize
    self.m_pUILayer:setContentSize(frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitData()
    self:AddTouchEvt()
    self:UpdateTimer()
    self:UpdateInfo()
end

function FlyFaryUI:onExit()
    self:Destory()
    if self.m_schedulerID then
        Utils:unschedule(nil, self.m_schedulerID)
        self.m_schedulerID = nil
    end
    if self.m_schedulerID2 then
        Utils:unschedule(nil, self.m_schedulerID2)
        self.m_schedulerID2 = nil
    end
    self.m_pVisibleBtn = nil
    self.m_pVisibleIcon = nil
    self.m_panel = nil
    self.m_pTitle = nil
end

function FlyFaryUI:InitData()
	local bg = self.m_pUILayer:getChildByName("feixianzhanchangUI")
    self.m_pVisibleBtn = bg:getChildByName("btn_Locker")
    self.m_pVisibleIcon = self.m_pVisibleBtn:getChildByName("Arrows")
    self.m_panel = bg:getChildByName("Panel")
    self.m_pTitle = self.m_panel:getChildByName("Title")
    local contentBg = self.m_panel:getChildByName("Content")
	
	local pHelpBtn = self.m_panel:getChildByName("btn_Help")
    pHelpBtn:addClickEventListener(function(sender)
        self:helpButtonCallback()
    end)
	self:MarkIntaractCObj(pHelpBtn)

    -- 奖励名称
    self.m_pRewardName = contentBg:getChildByName("Title_1")

    -- 经验奖励
    local expBg = contentBg:getChildByName("Reward_EXP")
    -- 经验
    self.m_pExpValue = expBg:getChildByName("EXP")
    -- 加成
    self.m_pExpVIP = expBg:getChildByName("VIP")
    --倒计时
    local expTimeBg = expBg:getChildByName("bgBar")
    self.m_pExpTime = expTimeBg:getChildByName("Time")
    self.m_pExpTimePercent = expTimeBg:getChildByName("LoadingBar")

    -- 物品奖励
    local thingBg = contentBg:getChildByName("Reward_Thing")
    -- 奖励1
    self.m_pRewardList = thingBg:getChildByName("ListView_1")
    self.m_pRewardCell = thingBg:getChildByName("Reward_1")
    --倒计时
    local thingTimeBg = thingBg:getChildByName("bgBar")
    self.m_pThingTime = thingTimeBg:getChildByName("Time")
    self.m_pThingTimePercent = thingTimeBg:getChildByName("LoadingBar")

    -- 进阶信息
    self.m_pUpText = contentBg:getChildByName("UP")
    self.m_pUpTarget = self.m_pUpText:getChildByName("Value")

    self.m_pDownText = contentBg:getChildByName("Down")
    self.m_pDownTarget = self.m_pDownText:getChildByName("Value")
    local BgSurpluerTime = bg:getChildByName("ActionBg")
    self.m_SurpluerTime=BgSurpluerTime:getChildByName("Time"):getChildByName("Value")
    self.m_isShow = true
    local size = self.m_panel:getContentSize()
    self.m_pShowPos = cc.p(self.m_panel:getPosition())
    self.m_pHidePos = cc.p(self.m_pShowPos.x + size.width, self.m_pShowPos.y)
    self.ActivityFinsihTime=0
    for i=1,#LRoleDataMgr.OpenedActData do
       local actId = LRoleDataMgr.OpenedActData[i].actID
       if actId==AppDef.EActivityID.EAID_FLYFARY then
            self.ActivityFinsihTime=LRoleDataMgr.OpenedActData[i].time
       end
    end 
end

function FlyFaryUI:helpButtonCallback()

    str = string.format("%s%s%s%s%s", GUITips.RSI_HSD_TIP131, GUITips.RSI_HSD_TIP132, GUITips.RSI_HSD_TIP133, GUITips.RSI_HSD_TIP134, GUITips.RSI_HSD_TIP135) 

    local function OKCallback()
    end
    local msgData = {
        okCallback = OKCallback,
        desc = str
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIMsgBoxEvent.ShowMsgBox, msgData)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function FlyFaryUI:AddTouchEvt()
    local function VisibleCallback(pSender, inputType)
    	self:Show()
    end
    self.m_pVisibleBtn:addClickEventListener(VisibleCallback)
	self:MarkIntaractCObj(self.m_pVisibleBtn)
end

--[[
实时信息
]]
function FlyFaryUI:UpdateInfo()
    local info = LDataConstMgr.m_FlyFaryInfo
	self.m_pRewardName:setString(string.format(GUITips.Res_Fly_Fary_Reward, info.CurLevel))
    self.m_pExpValue:setString(tostring(info.CurExp))
    self.m_pExpVIP:setString(string.format(GUITips.Res_Fly_Fary_VIP, info.BonusExp))
	if info.CurLevel >= 5 then
        self.m_pUpText:setString(GUITips.Res_Fly_Fary_Max)
        self.m_pUpTarget:setString("")
    else
        self.m_pUpText:setString(string.format(GUITips.Res_Fly_Fary_Up, info.CurLevel + 1))
        self.m_pUpTarget:setString(string.format(GUITips.Res_Fly_Fary_Kill, info.KillPoint, info.MaxKillPoint))
    end

	if info.CurLevel == 1 then
		self.m_pDownText:setVisible(false)
	else
		self.m_pDownText:setVisible(true)
		self.m_pDownText:setString(string.format(GUITips.Res_Fly_Fary_Down, info.CurLevel - 1))
		self.m_pDownTarget:setString(string.format(GUITips.Res_Fly_Fary_Bekill, info.BeAttackedPoint, info.MaxBeAttackedPoint))
	end

    self.m_pRewardList:removeAllItems()
    for i=1,#info.vecAwardId do
    	local cell = self.m_pRewardCell:clone()
    	Utils:GetItemCellValue(cell, 0, info.vecAwardId[i], false, true, info.vecAwardNum[i], nil, true)
		self.m_pRewardList:pushBackCustomItem(cell)
    end
    --dump(info)
end
function FlyFaryUI:SurpluerTime(dt)
    if self.ActivityFinsihTime == nil then
        return
    end
    self.ActivityFinsihTime=self.ActivityFinsihTime-1
    if self.ActivityFinsihTime<0 then
    self.ActivityFinsihTime=0
    end
    self.m_SurpluerTime:setString(string.format("%02d:%02d",self.ActivityFinsihTime/60,self.ActivityFinsihTime%60))
end
function FlyFaryUI:UpdateTimer()
    local function TimerCallBack(dt)
        local data = LDataConstMgr.m_FlyFaryInfo
        if data.m_nextFlushScecond == 0 then
            return
        end
        -- 物品倒计时
        data.LeftTime = math.max(data.LeftTime-1, 0)
        local thingStr = Utils:SecondFormat(data.LeftTime)
        self.m_pThingTime:setString(thingStr)
        self.m_pThingTimePercent:setPercent(data.LeftTime * 100 / 1800)

        -- 经验倒计时
        data.AddExpTime = math.max(data.AddExpTime-1, 0)
        local expStr = Utils:SecondFormat(data.AddExpTime)
        self.m_pExpTime:setString(expStr)
        self.m_pExpTimePercent:setPercent(data.AddExpTime * 100 / 60)
    end
    if self.m_schedulerID then
        Utils:unschedule(nil, self.m_schedulerID)
        self.m_schedulerID = nil
    end
    self.m_schedulerID = Utils:schedule(nil, TimerCallBack, 1)
    local function OnSysTimeUpdate(dt)
        self:SurpluerTime(dt)
    end
    if self.m_schedulerID2 then
        Utils:unschedule(nil, self.m_schedulerID2)
        self.m_schedulerID2 = nil
    end
    self.m_schedulerID2 = Utils:schedule(nil, OnSysTimeUpdate, 1)
end

function FlyFaryUI:Show()
    if self.m_isShow then
    	self.m_isShow = false
        local action = cc.MoveTo:create(0.3, self.m_pHidePos)
        self.m_panel:runAction(action)
        self.m_pVisibleIcon:setRotation(270)
    else
    	self.m_isShow = true
        local action = cc.MoveTo:create(0.3, self.m_pShowPos)
        self.m_panel:runAction(action);
        self.m_pVisibleIcon:setRotation(90)
    end
end

return FlyFaryUI