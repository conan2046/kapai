--local TimerLabelUI = require("View.Common.TimerLabelUI")
local YouLiTimeUI = LUIBase:New()
YouLiTimeUI.__index = YouLiTimeUI
YouLiTimeUI.IsHideInBattle = true
function YouLiTimeUI:New()
    local o = LUIBase:New()
    setmetatable(o,YouLiTimeUI) 
    o:Init()
    return o
end

function YouLiTimeUI:Init()
    self.Script = "WanFa.YouLiTimeUI"
    self:CreateUINode("csd/youli/youlishichang.csb")
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    --self:RegistMsgs()
    self:InitData()
    self:initControlUI()
end

function YouLiTimeUI:InitData()
    self.m_btns = {}
end

function YouLiTimeUI:initControlUI()
    --关卡
    local panel = self.m_pUILayer:getChildByName("Popup")
    panel:getChildByName("Item"):removeFromParent()

    local listView = panel:getChildByName("ListView")
    self.m_btns[1] = listView:getChildByName("Btn_duanqi")
    self.m_btns[2] = listView:getChildByName("Btn_zhongqi")
    self.m_btns[3] = listView:getChildByName("Btn_changqi")
    for i=1,3 do
        self.m_btns[i].userObject = i
        self.m_btns[i]:addClickEventListener(handler(self,YouLiTimeUI.BtnCallBack))
    end

    local closeBtn1 = panel:getChildByName("Btn_close")
    local closeBtn2 = panel:getChildByName("Btn_Close")
    closeBtn1:addClickEventListener(handler(self,YouLiTimeUI.RemoveUI))
    closeBtn2:addClickEventListener(handler(self,YouLiTimeUI.RemoveUI))
end

function YouLiTimeUI:BtnCallBack(sender)
    local idx = sender.userObject
    if idx < 1 or idx > 3 then
        idx = 1
    end
    Utils:SendMsg(LUIActivityEvent.YouLiTimeChoose,idx)
    self:RemoveUI()
end


function YouLiTimeUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.Script  = nil
    self.m_btns = nil
end

return YouLiTimeUI