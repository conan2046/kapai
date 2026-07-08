local ShenshouMainUI = LUIBase:New()
ShenshouMainUI.__index = ShenshouMainUI

function ShenshouMainUI:New(openTab)
    local o = LUIBase:New()
    setmetatable(o,ShenshouMainUI)
    o:Init(openTab)
    return o
end

function ShenshouMainUI:Init(openTab)
    self.m_pUILayer = cc.Node:create()
    self.m_pSubLayer = {}
    self.m_curUIInd = 0
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.UI_Title_Husong_Shenshou)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.ShenshouMainUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.AddTabBtn, nil)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    self:TabClicked(1)
end

function ShenshouMainUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
end

function ShenshouMainUI:InitTouchEvt()

    local function ExitCallback(sender)
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.ShenshouMainUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    self.m_pCloseBtn:addClickEventListener(ExitCallback)
	self:MarkIntaractCObj(self.m_pCloseBtn)
end

function ShenshouMainUI:TabClicked(ind)
    if  self.m_curUIInd == ind then
        return
    end
    if self.m_curUIInd ~= 0 then
     self:HideCurUI()
    end
     self.m_curUIInd = ind
     self:ShowCurUI()
end

function ShenshouMainUI:HideCurUI()
    if self.m_pSubLayer[self.m_curUIInd] == nil then
        return
    end
    self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(false)
end

function ShenshouMainUI:ShowCurUI()
    
     if self.m_pSubLayer[self.m_curUIInd] == nil then
        self:DelayLoadSubUI(self.m_curUIInd)
    else
        self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(true)
    end
    
end

function ShenshouMainUI:DelayLoadSubUI(tabInd)
    local uinames = {"View.Activity.ShenshouUI",}
    local ind = tabInd
    local delay = cc.DelayTime:create(0.1)
    local function loadSubUI()
        if self.m_curUIInd ~= ind then
            return
        end
        self.m_pSubLayer[ind] = require(uinames[ind]):New()
        self.m_pUILayer:addChild(self.m_pSubLayer[ind].m_pUILayer)
    end
    local func = cc.CallFunc:create(loadSubUI)
    local sequence = cc.Sequence:create(delay, func)
    self.m_pUILayer:runAction(sequence)
end

return ShenshouMainUI