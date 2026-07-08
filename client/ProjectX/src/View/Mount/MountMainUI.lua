--[[坐骑
]]
--[[
lua里面的游戏逻辑控制
]]

local MountMainUI = LUIBase:New()
MountMainUI.__index = MountMainUI
--local this = LTcpSocket
function MountMainUI:New(openTab)
	local o = LUIBase:New()
	setmetatable(o,MountMainUI)	
    o:Init(openTab)
	return o
end

--[[
注册UI消息
]]
function MountMainUI:RegistMsgs()
    self.msgIds = 
    {
        LUIHorseEvent.RecvEnforceValue,
        LUIHorseEvent.HorseListChange,
    }
    self:RegistSelf(self,self.msgIds)
end

function MountMainUI:ProcessEvent(msg)
    if msg.msgId == LUIHorseEvent.RecvEnforceValue
    or  msg.msgId == LUIHorseEvent.HorseListChange then
        for i = 1, 3 do
            local ret = self:CheckRedPointVisible(i)
            LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RedDotState, {i, ret})
            self:SendMsg(LGameMsg.m_baseMsgWithOne)
        end
    end
end


function MountMainUI:Init(openTab)
    --self.m_pNode = cc.Node:create()

    -- self.m_pUILayer = cc.CSLoader:createNode("csd/RoleLayer.csb")
    -- local frameSize = cc.Director:getInstance():getVisibleSize()
    -- self.m_pUILayer:setContentSize(frameSize)
    -- ccui.Helper:doLayout(self.m_pUILayer)
   -- self:addChild(self.m_pUILayer)
   self.m_pUILayer = cc.Node:create()
   self.m_pSubLayer = {}
   self.m_curUIInd = 0
   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)


    -- local waitAniData = {
    --                         key = LuaNetCmd.MSG_ACC_LINEUP, 
    --                         waitMsg = GUITips.Login_Connect_Server, 
    --                         autoClearTime = 0
    --                     }
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.UI_Title_Mount)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Mount.MountMainUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local function tabBtnClicked(ind)
        self:TabClicked(ind)
    end
    local tabValues = 
    {
        {GUITips.UI_Title_Mount_TabName1,GUITips.UI_Title_Mount_TabName2,GUITips.UI_Title_Mount_TabName3},
        tabBtnClicked
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.AddTabBtn, tabValues)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, openTab)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    self:TabClicked(openTab)
    self:RegistMsgs()
    --self:InitTouchEvt()
    --self:ShowVersion()
end

--[[
检测坐骑是否有小红点
@param1:checkInd,检测的页签下标
@return:true,显示小红点，false不显示小红点
]]
function MountMainUI:CheckRedPointVisible(checkInd)
    if checkInd == 1 then
        return LRoleDataMgr:CheckMountExChange()
    elseif checkInd == 2 then
        return LRoleDataMgr:CheckMountUpgrade()
    elseif checkInd == 3 then
        return LRoleDataMgr:CheckMountEnforce()
    end
    return false
end

function MountMainUI:TabClicked(ind)
         
      
    if  self.m_curUIInd == ind then
        return
    end
    if ind==1 then
          LGameMsg.m_initUIMsg:ChangeWithMsgId(LUIHorseEvent.UpdateHorseTotalAttr,"View.Mount.MountInfoUI")
          self:SendMsg(LGameMsg.m_initUIMsg)
    end
    if ind == 1 and Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_ZUOJI) then
        return
    elseif ind == 2 and Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_ZJJINJIE) then
        LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, self.m_curUIInd)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
        return
    elseif ind == 3 and Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_ZJQIANGHUA) then
        LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, self.m_curUIInd)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
        return
    end

    if self.m_curUIInd ~= 0 then
     self:HideCurUI()
    end
    self.m_curUIInd = ind

    self:ShowCurUI()
     


    for i = 1, 3 do
        local ret = self:CheckRedPointVisible(i)
        LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RedDotState, {i, ret})
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end
end

function MountMainUI:HideCurUI()
    if self.m_pSubLayer[self.m_curUIInd] == nil then
        return
    end
    self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(false)
end

function MountMainUI:ShowCurUI()
     if self.m_pSubLayer[self.m_curUIInd] == nil then
        self:DelayLoadSubUI(self.m_curUIInd)
    else
        self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(true)
    end
    
end

function MountMainUI:DelayLoadSubUI(tabInd)
    local uinames = {"View.Mount.MountInfoUI","View.Mount.MountUpgradeUI","View.Mount.MountEnforceUI"}
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

function MountMainUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

function MountMainUI:InitTouchEvt()
    local panel = self.m_pUILayer:getChildByName("Main_UI")
    local roleBtn = panel:getChildByName("Head")
    local function RoleTouchCallback(sender)
    end
    roleBtn:addClickEventListener(RoleTouchCallback)
	self:MarkIntaractCObj(roleBtn)
end

return MountMainUI