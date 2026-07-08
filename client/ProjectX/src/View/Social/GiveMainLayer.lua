--[[
lua  鲜花
]]
local GiveMainLayer = LUIBase:New()
GiveMainLayer.__index = GiveMainLayer
--local this = LTcpSocket
function GiveMainLayer:New(openTab)
	local o = LUIBase:New()
	setmetatable(o,GiveMainLayer)	
    o:Init(openTab)
	return o
end

function GiveMainLayer:Init(openTab)
    self:RegistMsgs()
    self.m_pUILayer = cc.Node:create()
    self.m_pSubLayer = {}
    self.m_curUIInd = 0

    self:InitTouchEvt();

    --title
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.RSI_GIVE)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local function tabBtnClicked(ind)
        self:TabClicked(ind)
    end
    local tabValues = 
    {
        {GUITips.RSI_GIVE_XIANHUA, GUITips.RSI_GIVE_RECORD},
        tabBtnClicked
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.AddTabBtn, tabValues)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, openTab)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    self:TabClicked(openTab)

end

--[[
注册消息
]]
function GiveMainLayer:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

function GiveMainLayer:ProcessEvent(msg)
    if  msg:GetMsgId() == LUISocialEvent.gotoMailUI then

    end
end

function GiveMainLayer:onExit()
    self.m_pUILayer = nil
end

function GiveMainLayer:InitTouchEvt()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    
    local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Social.GiveMainLayer")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

end


function GiveMainLayer:HideCurUI()
    if self.m_pSubLayer[self.m_curUIInd] == nil then
        return
    end
    self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(false)
end

function GiveMainLayer:ShowCurUI()
    
     if self.m_pSubLayer[self.m_curUIInd] == nil then
        self:DelayLoadSubUI(self.m_curUIInd)
    else
        self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(true)
        if self.m_curUIInd == 2 then
            self.m_pSubLayer[self.m_curUIInd]:refreshUI()
        end
    end
    
end

function GiveMainLayer:TabClicked(ind)
    if  self.m_curUIInd == ind then
        return
    end
    if self.m_curUIInd ~= 0 then
     self:HideCurUI()
    end
     self.m_curUIInd = ind
     self:ShowCurUI()
end

function GiveMainLayer:DelayLoadSubUI(tabInd)
    local uinames = {"View.Social.GiveGiftIUI","View.Social.GiftRecordUI"}
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



return GiveMainLayer