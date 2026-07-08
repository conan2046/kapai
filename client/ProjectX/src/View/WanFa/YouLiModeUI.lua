--local TimerLabelUI = require("View.Common.TimerLabelUI")
local YouLiModeUI = LUIBase:New()
YouLiModeUI.__index = YouLiModeUI
YouLiModeUI.IsHideInBattle = true
function YouLiModeUI:New()
    local o = LUIBase:New()
    setmetatable(o,YouLiModeUI) 
    o:Init()
    return o
end

function YouLiModeUI:Init()
    self.Script = "WanFa.YouLiModeUI"
    self:CreateUINode("csd/youli/youlifangshi.csb")
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

function YouLiModeUI:InitData()
    self.m_btns = {}
end

function YouLiModeUI:initControlUI()
    --关卡
    local panel = self.m_pUILayer:getChildByName("Popup")
    panel:getChildByName("Item"):removeFromParent()

    local listView = panel:getChildByName("ListView")
    self.m_btns[1] = listView:getChildByName("Btn_chuji")
    self.m_btns[2] = listView:getChildByName("Btn_zhongji")
    self.m_btns[3] = listView:getChildByName("Btn_gaoji")
    for i=1,3 do
        self.m_btns[i].userObject = i
        self.m_btns[i]:addClickEventListener(handler(self,YouLiModeUI.BtnCallBack))
    end

    local closeBtn1 = panel:getChildByName("Btn_close")
    local closeBtn2 = panel:getChildByName("Btn_Close")
    closeBtn1:addClickEventListener(handler(self,YouLiModeUI.RemoveUI))
    closeBtn2:addClickEventListener(handler(self,YouLiModeUI.RemoveUI))
end

function YouLiModeUI:BtnCallBack(sender)
    local idx = sender.userObject
    if idx < 1 or idx > 3 then
        idx = 1
    end
    Utils:SendMsg(LUIActivityEvent.YouLiModeChoose,idx)
    self:RemoveUI()
end


function YouLiModeUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.Script  = nil
    self.m_btns = nil
end

return YouLiModeUI