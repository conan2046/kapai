local AnswerMainUI = LUIBase:New()
AnswerMainUI.__index = AnswerMainUI

function AnswerMainUI:New(openTab)
    local o = LUIBase:New()
    setmetatable(o,AnswerMainUI)
    o:Init(openTab)
    return o
end

function AnswerMainUI:Init(openTab)
    self.m_pUILayer = cc.Node:create()
    self.m_pSubLayer = {}
    self.m_curUIInd = 0
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.UI_Title_Answer)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.AnswerMainUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.AddTabBtn, nil)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    self:TabClicked(openTab)
end

function AnswerMainUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

function AnswerMainUI:InitTouchEvt()

    local function ExitCallback(sender)
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.AnswerMainUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    self.m_pCloseBtn:addClickEventListener(ExitCallback)
	self:MarkIntaractCObj(self.m_pCloseBtn)
end

function AnswerMainUI:TabClicked(ind)
    if  self.m_curUIInd == ind then
        return
    end
    if self.m_curUIInd ~= 0 then
     self:HideCurUI()
    end
     self.m_curUIInd = ind
     self:ShowCurUI()
end

function AnswerMainUI:HideCurUI()
    if self.m_pSubLayer[self.m_curUIInd] == nil then
        return
    end
    self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(false)
end

function AnswerMainUI:ShowCurUI()
    
     if self.m_pSubLayer[self.m_curUIInd] == nil then
        self:DelayLoadSubUI(self.m_curUIInd)
    else
        self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(true)
    end
end

function AnswerMainUI:DelayLoadSubUI(tabInd)
    local uinames = {"View.Activity.AnswerUI",}
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

return AnswerMainUI