local XueZhanSetUI = LUIBase:New()
XueZhanSetUI.__index = XueZhanSetUI
XueZhanSetUI.IsHideInBattle = true
function XueZhanSetUI:New()
    local o = LUIBase:New()
    setmetatable(o,XueZhanSetUI) 
    o:Init()
    return o
end

function XueZhanSetUI:Init()
    self.Script = "XueZhan.XueZhanSetUI"
    self.m_pUILayer = cc.CSLoader:createNode("csd/xuezhan/Xuezhanbuffchoose.csb")
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitData()
    self:ShowInfo()

    --Utils:SendMsg(LUISecondClassBgEvent.SetTitle, GUITips.UI_Title_XueZhan)
    --Utils:SendMsg(LUISecondClassBgEvent.SetCloseCallback,handler(self,XueZhanSetUI.CloseUI))
end

function XueZhanSetUI:InitData()
    local panel = self.m_pUILayer:getChildByName("Popup")

    local closeBtn  = panel:getChildByName("Btn_close")
    closeBtn:addClickEventListener(handler(self, XueZhanSetUI.CloseUI))

    local okBtn = panel:getChildByName("Btn_Confirm")
    okBtn:addClickEventListener(function (sender)
        local value = bit._b2d(self.m_setId)
        --print("SendXueZhanSweepSetting",value)
        local ret = false
        for i=1,#self.m_types do
            local aType = 32- self.m_types[i]+1
            if self.m_setId[aType] ~= nil and self.m_setId[aType] == 1 then
                ret = true
                break
            end
        end
        if not ret then
            Utils:ShowScrollTips(GUITips.RSI_XUEZHAN_TIP31)
            return
        end
        LUserConfigMgr:SetXueZhanSType(value)
        LuaNetSendMsg:SendXueZhanSweepSetting(value)
        self:CloseUI()
    end)

    self.m_setId = {}
    for i=1,32 do
        self.m_setId[i] = 0
    end
    self.m_types = {10,11,12,13,15,16,17,18,19,22}

    self.m_checkBoxs = {}
    for i = 1,10 do
        self.m_checkBoxs[i] = panel:getChildByName("Attribute_"..i):getChildByName("CheckBox")
        self.m_checkBoxs[i]:addEventListener(handler(self, XueZhanSetUI.CheckBoxCallback))
        self.m_checkBoxs[i]:setSelected(false)
        self.m_checkBoxs[i].userObject = i
    end
end

function XueZhanSetUI:ShowInfo()
    local data = LActivityManager:GetXueZhanData()
    if data.m_sweepInfo == nil then
        return
    end
    --print("data.m_sweepInfo.sType",data.m_sweepInfo.sType)
    local sType = data.m_sweepInfo.sType
    if data.m_sweepInfo.sType == 0 or data.m_sweepInfo.sType == 0xffffffff then
        sType = LUserConfigMgr:GetXueZhanSType()
    end
    self.m_setId = bit._d2b(sType)
    --dump(self.m_setId,"&&&&&&&&&&&&& setID")
    for i=1,10 do
        local aType = 32- self.m_types[i]+1
        if self.m_setId[aType] ~= nil and self.m_setId[aType] == 1 then
            self.m_checkBoxs[i]:setSelected(true)
        end
    end
end

function XueZhanSetUI:CheckBoxCallback(sender,eventType)
    local idx = sender.userObject
    if eventType == ccui.CheckBoxEventType.selected then
        local aType = 32-self.m_types[idx]+1
        self.m_setId[aType] = 1 
    elseif eventType == ccui.CheckBoxEventType.unselected then
        local aType = 32-self.m_types[idx]+1
        self.m_setId[aType] = 0 
    end
    --dump(self.m_setId,"&&&&&&&&&&&&& setID #############")
end

function XueZhanSetUI:CloseUI()
    LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "XueZhan.XueZhanSetUI")
    self:SendMsg(LGameMsg.m_deleteUIMsg)
end

function XueZhanSetUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_pNode = nil
    self.Script  = nil
end

return XueZhanSetUI