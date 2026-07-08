local TimerLabelUI = require("View.Common.TimerLabelUI")

local ShowWingHorseUI = LUIBase:New()
ShowWingHorseUI.__index = ShowWingHorseUI
-------------------------------------
function ShowWingHorseUI:New(data)
    local o = {}
    setmetatable(o, ShowWingHorseUI)
    o:Init(data)
    return o
end
-------------------------------------
function ShowWingHorseUI:Init(data)
    self.Script = "ImproveUI.ShowWingHorseUI"
    ------------------------------------------------
    self.m_datas = {}
    self.m_canClick = false
    ------------------------------------------------
    self.m_pBg = nil
    self.m_pNode = nil
    self.m_pTitle = nil
    self.m_pTimerLabel = nil
    ------------------------------------------------
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    if data then
        self:UpdateData(data.iType, data.id)
    end
end

--------------------------------- ----
function ShowWingHorseUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    if self.m_pTimerLabel then
        self.m_pTimerLabel:Destory()
        self.m_pTimerLabel = nil
    end
    Utils:FreeTable(self.m_datas)
    self.m_datas = nil
    self.m_canClick = nil
    self.m_pBtn = nil
    ------------------------------------------------
    self.m_pBg = nil
    self.m_pNode = nil
    self.m_pTitle = nil
    self.m_pTimerLabel = nil
    self.m_pDiZuo = nil
    self.m_pBtnText = nil
    performWithDelay(AppDef.Director:getRunningScene(),function(sender)
        Utils:SendMsg(LUIGetPetWingEvent.CheckNext, nil, true)
        LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.AutoPathEvent.ReStartAutoPath)
        self:SendMsg(LGameMsg.m_cBaseMsg)
    end, 0)
end
-------------------------------------
function ShowWingHorseUI:InitUIControl()
    --------------------------------------------------------
    local pPanel = self.m_pUILayer:getChildByName("xingongneng")
    --------------------------------------------------------
    local nodes = pPanel:getChildren()
    for i=1,#nodes do
        nodes[i]:setVisible(false)
    end
    --------------------------------------------------------
    local pDiZuo = pPanel:getChildByName("dizuo")
    self.m_pDiZuo = pDiZuo
    --------------------------------------------------------
    local pAnim = ImodAnim:createWithFileSync("res2/fx/shenqizhanshi")
    pAnim:setIgnoreAnchorPointForPosition(false)
    pAnim:setAnchorPoint(cc.p(0.5, 0))
    pAnim:PlayActionRepeat(0)
    pAnim:setPosition(cc.p(pDiZuo:getContentSize().width/2, pDiZuo:getContentSize().height/2+20))
    pDiZuo:addChild(pAnim)
    --------------------------------------------------------
    local pBg = pPanel:getChildByName("Mask")
    pBg:setTouchEnabled(true)
    pBg:addClickEventListener(handler(self, ShowWingHorseUI.CloseUI))
	self:MarkIntaractCObj(pBg)
    self.m_pBg = pBg
    --------------------------------------------------------
    self.m_pNode = pPanel:getChildByName("Node")
    --------------------------------------------------------
    self.m_pTitle = pPanel:getChildByName("Title")
    --------------------------------------------------------
    local pBtn = pPanel:getChildByName("btn_Confirm")
    self.m_pBtn = pBtn
    pBtn:addClickEventListener(handler(self, ShowWingHorseUI.CloseUI))
	self:MarkIntaractCObj(pBtn)
    self.m_pBtnText = pBtn:getChildByName("Text")
    --------------------------------------------------------
    local function updateCallback(_,_,_,countdown)
        self.m_pBtnText:setString(string.format(GUITips.RSI_PREVIEW_MSG1, countdown))
    end
    self.m_pTimerLabel = TimerLabelUI:New(self.m_pBtnText, 10, handler(self, ShowWingHorseUI.CloseUI), updateCallback)
end

-------------------------------------
function ShowWingHorseUI:RegistMsgs()
    self.msgIds = {
        LUIHorseEvent.AddNewHorse,
        LUIWingDataEvent.GotNewWing,
        LUIShenQiEvent.ShenQiStateChanged,
    }
    self:RegistSelf(self, self.msgIds)
end

-------------------------------------
function ShowWingHorseUI:ProcessEvent(msg)
    if msg.msgId == LUIHorseEvent.AddNewHorse then
        self:UpdateData(AppDef.AwrdItem.AWRD_ITEM_HORSE, msg.value)
    elseif msg.msgId == LUIShenQiEvent.ShenQiStateChanged then
        self:UpdateData(AppDef.AwrdItem.AWRD_ITEM_ARTIFACT, msg.value)
    elseif msg.msgId == LUIWingDataEvent.GotNewWing then
        self:UpdateData(AppDef.AwrdItem.AWRD_ITEM_WINDS, msg.value)
    end
end

function ShowWingHorseUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

-------------------------------------
function ShowWingHorseUI:InitViewSize()
    self:CreateUINode("csd/xingongnengLayer.csb")
end

function ShowWingHorseUI:CloseUI(sender)
    if not self.m_canClick then
        return
    end
    
    if not self:CheckNext() then
        self:RemoveUI()
    end
end

function ShowWingHorseUI:UpdateUserData(data)
    self:UpdateData(data.iType, data.id)
end

function ShowWingHorseUI:UpdateData(iType, id)
    if id == nil or iType == nil then
        return
    end
    for i=1,#self.m_datas do
        local data = self.m_datas[i]
        if data.type == iType and data.id == id then
            table.remove(self.m_datas, i)
            break
        end
    end
    table.insert(self.m_datas, {type=iType, id=id})
    if #self.m_datas == 1 then
        self:CheckNext()
    end
end

function ShowWingHorseUI:ShowStartAnim()
    self.m_pBg:stopAllActions()
    self.m_pBg:setOpacity(50)

    local pFadeAc = cc.EaseBackOut:create(cc.FadeTo:create(0.1, 255*0.8))
    local pCallback = cc.CallFunc:create(function()
        self.m_canClick = true
    end)
    self.m_canClick = false
    self.m_pBg:runAction(cc.Sequence:create(pFadeAc, pCallback))
    self.m_pBg:setVisible(true)
end

function ShowWingHorseUI:CheckNext()
    if #self.m_datas <= 0 then
        return false
    end
    -------------------------------------------------------------
    local data = self.m_datas[1]
    table.remove(self.m_datas, 1)
    local iType = data.type
    local iValue = data.id
    local pParent = self.m_pNode
    pParent:removeAllChildren()
    -------------------------------------------------------------
    self.m_pDiZuo:setVisible(true)
    -------------------------------------------------------------
    if iType == AppDef.AwrdItem.AWRD_ITEM_HORSE then--坐骑
        local pAnim = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, 0)
        pAnim:InitAni(AppDef.CEnum.ModelAniType.Hero,0,0,0,0,iValue,0)
        pParent:addChild(pAnim)
        pParent:setVisible(true)

        local data = LDataConstMgr:GetHorseConfigData(iValue)
        self.m_pTitle:setString(data and data.name or "")
        self.m_pTitle:setVisible(true)
    elseif iType == AppDef.AwrdItem.AWRD_ITEM_WINDS then--翅膀
        local pAnim = ModelAniNode:create(AppDef.CEnum.ModelAniType.Wing, 0)
        pAnim:InitAni(AppDef.CEnum.ModelAniType.Wing,0,0,0,iValue,0,0)
        pAnim:PlayStand(0)
        pParent:addChild(pAnim)
        pParent:setVisible(true)

        local data = LDataConstMgr:GetWingConfigData(iValue)
        --dump(data)
        self.m_pTitle:setString(data and data.name or "")
        self.m_pTitle:setVisible(true)
    elseif iType == AppDef.AwrdItem.AWRD_ITEM_ARTIFACT then--神器
        local pAnim = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, 0)
        pAnim:InitAni(AppDef.CEnum.ModelAniType.Hero,0,0,0,0,0,iValue)
        pAnim:setPosition(cc.p(30, -90))
        pParent:addChild(pAnim)
        pParent:setVisible(true)

        local data = LDataConstMgr:GetShenQiById(iValue)
        --dump(data)
        self.m_pTitle:setString(data and data.m_name or "")
        self.m_pTitle:setVisible(true)
    end
    -------------------------------------------------------------
    self:ShowStartAnim()
    -------------------------------------------------------------
    LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.AutoPathEvent.PauseAutoPath)
    self:SendMsg(LGameMsg.m_cBaseMsg)
    -------------------------------------------------------------
    self.m_pBtn:setVisible(true)

    local _ = self.m_pTimerLabel and self.m_pTimerLabel:start()
    
    return true
end

return ShowWingHorseUI