--[[
lua里面的游戏逻辑控制
]]

local MoneyTreeMainUI = LUIBase:New()
MoneyTreeMainUI.__index = MoneyTreeMainUI
--local this = LTcpSocket
function MoneyTreeMainUI:New(openTab)
	local o = LUIBase:New()
	setmetatable(o,MoneyTreeMainUI)	
    o:Init(openTab)
	return o
end


function MoneyTreeMainUI:Init(openTab)
   self.m_pUILayer = cc.Node:create()
   self.m_pSubLayer = {}
   self.m_curUIInd = 0
   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.UI_Title_MoneyTree)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.MoneyTreeMainUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.AddTabBtn, nil)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    self:DelayLoadSubUI()
end

function MoneyTreeMainUI:DelayLoadSubUI()
    local uinames = {"View.Activity.MoneyTreeUI"}
    local delay = cc.DelayTime:create(0.1)
    local function loadSubUI()
        self.m_pSubLayer = require(uinames[1]):New()
        self.m_pUILayer:addChild(self.m_pSubLayer.m_pUILayer)
    end
    local func = cc.CallFunc:create(loadSubUI)
    local sequence = cc.Sequence:create(delay, func)
    self.m_pUILayer:runAction(sequence)
end

function MoneyTreeMainUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
    LActivityManager:MoneyTreeFree()
end


return MoneyTreeMainUI