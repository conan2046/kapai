local ActiveCodeUI = LUIBase:New()
ActiveCodeUI.__index = ActiveCodeUI
--local this = LTcpSocket
function ActiveCodeUI:New()
    local o = LUIBase:New()
    setmetatable(o,ActiveCodeUI)    
    o:Init()
    return o
end


function ActiveCodeUI:Init()

    self.m_pUILayer = cc.CSLoader:createNode("csd/shenjiangInfoLayer.csb")
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    local shenjiangInfoUI = self.m_pUILayer:getChildByName("shenjiangInfoUI")
    local Show = shenjiangInfoUI:getChildByName("Show")
    Show:setVisible(false)

    local info = shenjiangInfoUI:getChildByName("Info")
    info:setVisible(false)

    local chongwugaiming = shenjiangInfoUI:getChildByName("chongwugaiming")
    chongwugaiming:setVisible(true)

    local closeBtn = chongwugaiming:getChildByName("bg"):getChildByName("Btn_close")
    local function closeEvent( sender )
        -- body
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Social.ActiveCodeUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    closeBtn:addClickEventListener(closeEvent)
	self:MarkIntaractCObj(closeBtn)
    local title = chongwugaiming:getChildByName("bg"):getChildByName("Title")
    title:setString(GUITips.RSI_IMD_DTS_TIP16)

    local des = chongwugaiming:getChildByName("Title")
    des:setString(GUITips.RSI_IMD_DTS_TIP7)

    self._textField = chongwugaiming:getChildByName("TextField")

    local btn_Confirm = chongwugaiming:getChildByName("Btn_Confirm")
    local function ConfirmEvent( sender )
        -- body
        local code = self._textField:getString()
        if string.len(code) <= 0 then
            return
        end
        LuaNetSendMsg:AccActivate(code)
        self._textField:setString("")
    end
    btn_Confirm:addClickEventListener(ConfirmEvent)
	self:MarkIntaractCObj(btn_Confirm)
end

function ActiveCodeUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return ActiveCodeUI