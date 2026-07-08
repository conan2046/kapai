local FunctionIconFlyUI = require("View.PreView.FunctionIconFlyUI")

local initDelay = 1.5

local OpenCheckUI = LUIBase:New()
OpenCheckUI.__index = OpenCheckUI
OpenCheckUI.IsHideInBattle = true
-------------------------------------
function OpenCheckUI:New(ids)
    local o = {}
    setmetatable(o, OpenCheckUI)
    o:Init(ids)
    return o
end
-------------------------------------
function OpenCheckUI:Init(ids)
    self.Script = "PreView.OpenCheckUI"
    ------------------------------------------------
    self.m_index = 1
    self.m_datas = {}
    ------------------------------------------------
    self.m_pBg = nil
    self.m_pLight = nil
    self.m_pIcon = nil
    self.m_pText = nil
    self.m_canClick = false
    ------------------------------------------------
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    if ids then
        self:UpdateData(ids)
        self:CheckNext()
    end
end

--------------------------------- ----
function OpenCheckUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_pIcon = nil
    self.m_pIconPos = nil
    self.Script = nil
    ------------------------------------------------
    self.m_index = nil
    Utils:FreeTable(self.m_datas)
    self.m_datas = nil
    ------------------------------------------------
    self.m_pBg = nil
    self.m_pLight = nil
    self.m_pText = nil
    self.m_canClick = nil
end
-------------------------------------
function OpenCheckUI:InitUIControl()
    local pPanel = self.m_pUILayer:getChildByName("Panel")
    -----------------------------------------------------------
    local pPanel_1 = self.m_pUILayer:getChildByName("Panel_1")
    pPanel_1:addClickEventListener(handler(self, OpenCheckUI.CloseUI))
	self:MarkIntaractCObj(pPanel_1)
    pPanel_1:setOpacity(0)
    performWithDelay(pPanel_1, function(sender)
        pPanel_1:setOpacity(255)
    end, initDelay)
    -----------------------------------------------------------
    local pBg = pPanel:getChildByName("Bg")
    self.m_pBg = pBg

    self.m_pLight = pBg

    local pIconBg = pBg:getChildByName("IconBg")
    local pIcon = pIconBg:getChildByName("Icon")
    local _ = pIcon and pIcon:setVisible(true)
    local pSkillIcon = pIconBg:getChildByName("SkillIcon")
    local _ = pSkillIcon and pSkillIcon:setVisible(false)

    pIcon:setTag(0)
    self.m_pIcon = pIcon
    self.m_pIconPos = pIcon:convertToWorldSpace(cc.p(pIcon:getContentSize().width/2, pIcon:getContentSize().height/2))

    local pTitle = pBg:getChildByName("Title")
    local _ = pTitle and pTitle:setVisible(true)
    local pSkillTitle = pBg:getChildByName("SkillTitle")
    local _ = pSkillTitle and pSkillTitle:setVisible(false)

    local pTextBg = pBg:getChildByName("TextBg")
    pTextBg:setVisible(true)
    self.m_pText = pTextBg:getChildByName("Text")
end
-------------------------------------
function OpenCheckUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self.m_pUILayer:setVisible(true)
end

-------------------------------------
function OpenCheckUI:InitViewSize()
    self:CreateUINode("csd/NewFunctionLayer.csb")
end

function OpenCheckUI:CloseUI(sender)
    if not self.m_canClick then
        return
    end
    local time = self:flyTo(self.m_pIcon:getTag(), self.m_index > #self.m_datas)
    performWithDelay(self.m_pUILayer, function(dt)
        if not self:CheckNext() then
            self:RemoveUI()
        end
    end, time/2)
end

function OpenCheckUI:UpdateUserData(ids)
    self:UpdateData(ids)
end

function OpenCheckUI:UpdateData(ids)
    if ids == nil or #ids == 0 then
        return
    end
    for i=1,#ids do
        if not Utils:containValue(self.m_datas, ids[i]) then
            table.insert(self.m_datas, ids[i])
        end
    end
    if #self.m_datas <= 0 then
        self:RemoveUI()
        return
    else
        Utils:SendMsg(LUIFunctionEvent.PushFuncOpenList, self.m_datas)
    end
end

function OpenCheckUI:ShowStartAnim()
    self.m_pBg:stopAllActions()
    self.m_pBg:setScale(0)

    local pScaleAc = cc.EaseBackOut:create(cc.ScaleTo:create(0.25, 1))
    local pCallback = cc.CallFunc:create(function()
        self.m_canClick = true
    end)
    self.m_canClick = false
    self.m_pBg:runAction(cc.Sequence:create(cc.DelayTime:create(initDelay), cc.CallFunc:create(handler(self, OpenCheckUI.PlaySound)), pScaleAc, pCallback))
    self.m_pBg:setVisible(true)
end

function OpenCheckUI:CheckNext()
    if self.m_pIcon == nil then
        return false
    end
    if self.m_index > #self.m_datas then
        return false
    end

    local functionId = self.m_datas[self.m_index]
    self.m_fid = functionId
    self.m_index = self.m_index + 1
    -- table.remove(self.m_datas, 1)
    local str = nil
    if functionId < 100 and functionId ~= AppDef.EActivityID.EAID_COMBAT then
        str = AppDef.GUIRes["Activity_Name"..functionId]
        self.m_pIcon:loadTexture(str, UI_TEX_TYPE_LOCAL)
    else
        if functionId == AppDef.EActivityID.EAID_COMBAT then
            str = AppDef.GUIRes["Activity_Name"..functionId]
        else
            str = AppDef.GUIRes["Function_Name"..functionId]
        end
        self.m_pIcon:loadTexture(str, UI_TEX_TYPE_PLIST)
    end
    if str then
        self.m_pIcon:setTag(functionId)
    end

    local cfg = LDataConstMgr:GetFunctionLevelData(functionId)
    self.m_pText:setString(cfg and cfg.tips or "")
    
    self:ShowStartAnim()

    LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.AutoPathEvent.PauseAutoPath)
    self:SendMsg(LGameMsg.m_cBaseMsg)

    return true
end

function OpenCheckUI:PlaySound()
    local function _checkSingle(fid)
        local cfg = LDataConstMgr:GetFunctionLevelData(fid)
        if cfg == nil or cfg.sound == nil or #cfg.sound == 0 then
            return
        end
        LGameMsg.m_audioMsg:Change(LAudioEvent.PlayEffect, cfg.sound)
        self:SendMsg(LGameMsg.m_audioMsg)
    end
    _checkSingle(self.m_fid)
    --音效
    LGameMsg.m_audioMsg:Change(LAudioEvent.PlayBTEffect, AppDef.SysBGM.Equip_Enhanced)
    self:SendMsg(LGameMsg.m_audioMsg)
end

function OpenCheckUI:flyTo(functionId, isFinish)
    Utils:InitUI("PreView.FunctionIconFlyUI",AppDef.UIType.WaitLoading, {functionId=functionId, pos=self.m_pIconPos, isFinish=isFinish})

    local delay = FunctionIconFlyUI.getDelay(functionId)
    performWithDelay(self.m_pUILayer, function(dt)
        self.m_pBg:setVisible(false)
    end, delay)
    self.m_canClick = false
    return (delay*2 + FunctionIconFlyUI.flyTime)
end

return OpenCheckUI