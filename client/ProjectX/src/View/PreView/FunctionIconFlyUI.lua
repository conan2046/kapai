local FunctionIconFlyUI = LUIBase:New()
FunctionIconFlyUI.__index = FunctionIconFlyUI

FunctionIconFlyUI.flyTime = 0.5
FunctionIconFlyUI.delay = 0
FunctionIconFlyUI.isOpen = true
FunctionIconFlyUI.delayCfg = {
    [AppDef.EModuleID.EMID_BANGPAI] = true,
    [AppDef.EModuleID.EMID_DUANZAO] = true,
    [AppDef.EModuleID.EMID_ZUOJI] = true,
    [AppDef.EModuleID.EMID_SHENJIANG] = true,
    [AppDef.EModuleID.EMID_CHOUKA] = true,
    [AppDef.EModuleID.EMID_JINENG] = true,
    [AppDef.EModuleID.EMID_SHEZHI] = true,
    [AppDef.EModuleID.EMID_YUYI] = true,
    [AppDef.EModuleID.EMID_SHENQI] = true,
}

FunctionIconFlyUI.delayCfg2 = {
    [AppDef.EModuleID.EMID_GUAJI] = true,
    [AppDef.EModuleID.EMID_SCCHANGYONG] = true,
    [AppDef.EModuleID.EMID_FUBEN] = true,
    [AppDef.EModuleID.EMID_JINGJI] = true,
    [AppDef.EModuleID.EMID_PAIHANGBANG] = true,
}
-------------------------------------
function FunctionIconFlyUI:New(data)
    local o = {}
    setmetatable(o, FunctionIconFlyUI)
    o:Init(data)
    return o
end
-------------------------------------
function FunctionIconFlyUI:Init(data)
    self.Script = "PreView.FunctionIconFlyUI"
    self.m_pMaskPanel = nil
    ------------------------------------------------
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    self:UpdateUserData(data)
end
-------------------------------------
function FunctionIconFlyUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_pIconPos = nil
    self.m_pMaskPanel = nil
    self.m_functionId = nil
    self.m_pIconPos = nil
    self.m_isFInish = nil
end
-------------------------------------
function FunctionIconFlyUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
-------------------------------------
function FunctionIconFlyUI:InitViewSize()
    self.m_pUILayer = cc.Node:create()
    self.m_pUILayer:setContentSize(AppDef.frameSize)
end
-------------------------------------
function FunctionIconFlyUI:InitUIControl()
    if self.m_pMaskPanel == nil then
        self.m_pMaskPanel = ccui.Layout:create()
        self.m_pMaskPanel:setContentSize(self.m_pUILayer:getContentSize())
        self.m_pMaskPanel:setTouchEnabled(true)
        self.m_pMaskPanel:setPosition(cc.p(0, 0))
        self.m_pMaskPanel:setAnchorPoint(cc.p(0, 0))
        -- self.m_pMaskPanel:setBackGroundColorType(LAYOUT_COLOR_SOLID)
        -- self.m_pMaskPanel:setBackGroundColor(cc.c3b(0,0,0))
        -- self.m_pMaskPanel:setBackGroundColorOpacity(255)
        self.m_pUILayer:addChild(self.m_pMaskPanel)
    end
    self.m_pMaskPanel:setVisible(false)
end
-------------------------------------
function FunctionIconFlyUI:UpdateUserData(data)
    if data == nil then
        self:RemoveUI()
        return
    end
    self.m_functionId = data.functionId
    self.m_pIconPos = data.pos
    self.m_isFInish = data.isFinish
    self:updateDelay(self.m_functionId)
    self:flyTo(self.m_functionId)
end
-------------------------------------
function FunctionIconFlyUI:flyTo(functionId)
    if functionId <= 0 then
        self:RemoveUI()
        return
    end

    local str = nil
    local bplist = false
    if functionId < 100 and functionId ~= AppDef.EActivityID.EAID_COMBAT then
        str = AppDef.GUIRes["Activity_Name"..functionId]
    else
        if functionId == AppDef.EActivityID.EAID_COMBAT then
            str = AppDef.GUIRes["Activity_Name"..functionId]
        else
            str = AppDef.GUIRes["Function_Name"..functionId]
        end
        bplist = true
    end

    if str == nil then
        self:RemoveUI()
        return
    end
    
    local delay = FunctionIconFlyUI.getDelay(functionId)
    performWithDelay(self.m_pUILayer, function(dt)
        local data = {id=functionId, pos=cc.p(0,0)}
        if functionId < 100 then
            data.id = AppDef.EModuleID.EMID_WANFA
        end
        Utils:SendMsg(LUIMainEvent.GetMainBtnPos, data, true)
        
        local pIcon = nil
        if bplist then
            pIcon = cc.Sprite:createWithSpriteFrameName(str)
        else
            pIcon = cc.Sprite:create(str)
        end

        pIcon:setPosition(self.m_pIconPos)
        local pSeq = nil
        local pFlyFinishCallback = cc.CallFunc:create(function()
            Utils:SendMsg(LUIFunctionEvent.FunctionFinishFly, functionId)

            performWithDelay(AppDef.Director:getRunningScene(),function(sender)
                LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.AutoPathEvent.ReStartAutoPath)
                self:SendMsg(LGameMsg.m_cBaseMsg)
            end, 0)
        end)

        local pSetMaskCallback = cc.CallFunc:create(function()
            local _ = self.m_pMaskPanel and self.m_pMaskPanel:setVisible(false)
        end)
        local pRemoveCallback = cc.CallFunc:create(function()
            self:RemoveUI()
        end)
        if self.m_isFInish then
            local pCallback = cc.CallFunc:create(handler(self, FunctionIconFlyUI.flyFinished))
            pSeq = cc.Sequence:create(cc.MoveTo:create(FunctionIconFlyUI.flyTime, data.pos), pFlyFinishCallback, pCallback, pSetMaskCallback, pRemoveCallback)
        else
            pSeq = cc.Sequence:create(cc.MoveTo:create(FunctionIconFlyUI.flyTime, data.pos), pFlyFinishCallback, pSetMaskCallback, pRemoveCallback)
        end
        pIcon:runAction(pSeq)

        Utils:SendMsg(LUIFunctionEvent.FunctionStartFly, functionId)

        self.m_pUILayer:addChild(pIcon)

        local _ = self.m_pMaskPanel and self.m_pMaskPanel:setVisible(true)
    end, delay)
end

function FunctionIconFlyUI:updateDelay(functionId)
    local delay = 0
    local time = 0.5
    if FunctionIconFlyUI.delayCfg[functionId] ~= nil then
        local isOpenBtn = {isOpen=false}
        Utils:SendMsg(LUIMainEvent.ISOpenBtmBtn, isOpenBtn)

        local isOpen = Utils:ToBool(isOpenBtn.isOpen)
        FunctionIconFlyUI.isOpen = isOpen

        Utils:SendMsg(LUIMainEvent.OpenOrCloseBtmBtn, FunctionIconFlyUI.delayCfg[functionId])
        delay = (isOpen and 0 or time)
    elseif FunctionIconFlyUI.delayCfg2[functionId] ~= nil then
        local isOpenBtn = {isOpen=false}
        Utils:SendMsg(LUIMainEvent.ISOpenTopBtn, isOpenBtn)

        local isOpen = Utils:ToBool(isOpenBtn.isOpen)
        FunctionIconFlyUI.isOpen = isOpen
        Utils:SendMsg(LUIMainEvent.OpenOrCloseTopBtn, FunctionIconFlyUI.delayCfg2[functionId])
        delay = (isOpen and 0 or time)
    end
    FunctionIconFlyUI.delay = delay
end

function FunctionIconFlyUI.getDelay(functionId)
    return FunctionIconFlyUI.delay,FunctionIconFlyUI.isOpen
end

function FunctionIconFlyUI:flyFinished()
    if self.m_functionId == AppDef.EModuleID.EMID_FULI then
        Utils:SendMsg(LUITaskDataEvent.ContinueTask)
    end
    Utils:SendMsg(LUIFunctionEvent.FunctionFly, self.m_functionId)
end

return FunctionIconFlyUI