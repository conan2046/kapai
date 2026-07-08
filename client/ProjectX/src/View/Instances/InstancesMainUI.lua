--[[
]]

local InstancesMainUI = LUIBase:New()
InstancesMainUI.__index = InstancesMainUI

function InstancesMainUI:New(openTab)
	local o = LUIBase:New()
	setmetatable(o,InstancesMainUI)	
    o:Init(openTab)
	return o
end

--[[
注册UI消息
]]
function InstancesMainUI:RegistMsgs()
    self.msgIds = 
    {
        LUIActivityEvent.CloseInstancesAndGetValue,
    }
    self:RegistSelf(self,self.msgIds)
end

function InstancesMainUI:ProcessEvent(msg)
    if msg.msgId == LUIActivityEvent.CloseInstancesAndGetValue then
        local value = nil
        if self.m_curUIInd == 0 then
            return
        end
        local ind = self.m_pSubLayer[self.m_curUIInd]:GetInd()
        if ind ~= nil then
            value = {self.m_curUIInd, ind}
        end
        msg.value = value
        

        LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Instances.InstancesMainUI")
        self:SendMsg(LGameMsg.m_deleteUIMsg)
   end
end

function InstancesMainUI:Init(openTab)
    self:RegistMsgs()
    self.m_pUILayer = cc.Node:create()
    self.m_pSubLayer = {}
    self.m_curUIInd = 0
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    
--    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.UI_Title_Role_Attr)
--    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.UI_Title_Copy_Tips)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local function closeCallback()
        LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Instances.InstancesMainUI")
        self:SendMsg(LGameMsg.m_deleteUIMsg)
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local function tabBtnClicked(ind)
        self:TabClicked(ind)
    end
    local tabValues = 
    {
        {GUITips.UI_Title_Copy_Pet,
        GUITips.UI_Title_Copy_Normal},
        tabBtnClicked
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.AddTabBtn, tabValues)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    self.m_SecondInd = 1
    if openTab == 6 then
        openTab = 2
        self.m_SecondInd = 3
    elseif openTab > 100 then  
        self.m_SecondInd = openTab % 100
        openTab = math.floor(openTab / 100)
        --print("openTab",openTab,"self.m_SecondInd",self.m_SecondInd)
    end

    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, openTab)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    self:TabClicked(openTab)
    -- LRedDotCheckMgr:MainInstancesCheck(1)
    -- LRedDotCheckMgr:MainInstancesCheck(2)

    -- if #LDataConstMgr.m_CopyData._CopyList == 0 then
    --     LuaNetSendMsg:QueryCopy(11)
    -- end
    -- if #LDataConstMgr.m_CopyData._PetCopyList == 0 then
    --     LuaNetSendMsg:QueryPetCopyList()
    -- end
end

function InstancesMainUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_pSubLayer = nil
end

function InstancesMainUI:InitTouchEvt()

    local function ExitCallback(sender)
        LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Instances.InstancesMainUI")
        self:SendMsg(LGameMsg.m_deleteUIMsg)
    end
    self.m_pCloseBtn:addClickEventListener(ExitCallback)
	self:MarkIntaractCObj(self.m_pCloseBtn)
end

function InstancesMainUI:TabClicked(ind)
    if  self.m_curUIInd == ind then
        return
    end
    if self.m_curUIInd ~= 0 then
     self:HideCurUI()
    end
    self.m_curUIInd = ind
    self:ShowCurUI()
end

function InstancesMainUI:HideCurUI()
    if self.m_pSubLayer[self.m_curUIInd] == nil then
        return
    end
    self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(false)
end

function InstancesMainUI:ShowCurUI()
    
     if self.m_pSubLayer[self.m_curUIInd] == nil then
        self:DelayLoadSubUI(self.m_curUIInd)
    else
        self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(true)
    end
    
end

function InstancesMainUI:DelayLoadSubUI(tabInd)
    local uinames = {
    "View.Instances.PetInstancesUI",
    "View.Instances.InstancesUI",
    }
    local ind = tabInd
    local delay = cc.DelayTime:create(0.1)
    local function loadSubUI()
        if self.m_curUIInd ~= ind then
            return
        end
        self.m_pSubLayer[ind] = require(uinames[ind]):New(self.m_SecondInd)
        self.m_pUILayer:addChild(self.m_pSubLayer[ind].m_pUILayer)
    end
    local func = cc.CallFunc:create(loadSubUI)
    local sequence = cc.Sequence:create(delay, func)
    self.m_pUILayer:runAction(sequence)
end

return InstancesMainUI