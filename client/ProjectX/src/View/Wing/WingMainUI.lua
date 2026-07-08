--[[
]]

local WingMainUI = LUIBase:New()
WingMainUI.__index = WingMainUI
--local this = LTcpSocket
function WingMainUI:New(openTab)
	local o = LUIBase:New()
	setmetatable(o,WingMainUI)	
    o:Init(openTab)
	return o
end

--[[
注册UI消息
]]
function WingMainUI:RegistMsgs()
    self.msgIds = 
    {
        LUIWingDataEvent.UpgradWing,
        LUIRedDotEvent.UpdateRedDotState,
    }
    self:RegistSelf(self,self.msgIds)
end

function WingMainUI:ProcessEvent(msg)
    if msg.msgId == LUIWingDataEvent.UpgradWing then
        LRedDotCheckMgr:MainWingCheck()
    elseif msg.msgId == LUIRedDotEvent.UpdateRedDotState then
        self:DealUpdateRedDotState(msg.value)
    end
end

function WingMainUI:OnEnter()
    local function initRedDotState(id)
        local isShow = Utils:GetRedDotState(id)
        self:DealUpdateRedDotState({id=id, isShow=isShow})
    end
    initRedDotState(RedDotDef.ID.YuYiXinXi)
    initRedDotState(RedDotDef.ID.YuYiJinJie)
end

function WingMainUI:DealUpdateRedDotState(data)
    local ind = 0
    if data.id == RedDotDef.ID.YuYiXinXi then
        ind = 1
    elseif data.id == RedDotDef.ID.YuYiJinJie then
        ind = 2
    end
    if ind > 0 then
        Utils:SendMsg(LUIFClassBgEvent.RedDotState, {ind, data.isShow})
    end
end

function WingMainUI:Init(openTab)
    self.m_pUILayer = cc.Node:create()
    self.m_pSubLayer = {}
    self.m_curUIInd = 0
    self:RegistMsgs()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    
    Utils:SendMsg(LUIFClassBgEvent.SetTitle, GUITips.UI_Title_Artifact_TabName1)

    local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Wing.WingMainUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    Utils:SendMsg(LUIFClassBgEvent.SetCloseCallback, closeCallback)

    local function tabBtnClicked(ind)
        self:TabClicked(ind)
    end
    local tabValues = 
    {
        {GUITips.UI_Title_Artifact_TabName1,GUITips.UI_Title_Artifact_TabName2},
        tabBtnClicked
    }
    Utils:SendMsg(LUIFClassBgEvent.AddTabBtn, tabValues)

    Utils:SendMsg(LUIFClassBgEvent.SelectTab, openTab)
    self:TabClicked(openTab)

    self:OnEnter()
    Utils:SendMsg(LUIFClassBgEvent.RedDotState, {2, LRedDotCheckMgr:MainWingCheck()})
end

function WingMainUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
end

function WingMainUI:InitTouchEvt()

    local function ExitCallback(sender)
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Role.WingMainUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    self.m_pCloseBtn:addClickEventListener(ExitCallback)
	self:MarkIntaractCObj(self.m_pCloseBtn) 
end

function WingMainUI:TabClicked(ind)
    if ind == 2 then
        if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_YYJINJIE) then
            LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, self.m_curUIInd)
            self:SendMsg(LGameMsg.m_baseMsgWithOne)
            return
        end
        if #LRoleDataMgr.MyHeroInfo.MyChiBangVec == 0 then
            LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, 1)
            self:SendMsg(LGameMsg.m_baseMsgWithOne)
            Utils:ShowScrollTips(GUITips.Wing_Tips_Error1)
            return
        end
    end
    if  self.m_curUIInd == ind then
        return
    end
    if self.m_curUIInd ~= 0 then
     self:HideCurUI()
    end
    self.m_curUIInd = ind
    self:ShowCurUI()
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips["UI_Title_Artifact_TabName"..self.m_curUIInd])
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function WingMainUI:HideCurUI()
    if self.m_pSubLayer[self.m_curUIInd] == nil then
        return
    end
    self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(false)
end

function WingMainUI:ShowCurUI()
    
     if self.m_pSubLayer[self.m_curUIInd] == nil then
        self:DelayLoadSubUI(self.m_curUIInd)
    else
        self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(true)
    end
    
end

function WingMainUI:DelayLoadSubUI(tabInd)
    local uinames = {"View.Wing.WingAttrUI","View.Wing.WingDevelopUI",}
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

return WingMainUI