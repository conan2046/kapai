local TeamMainUI = LUIBase:New()
TeamMainUI.__index = TeamMainUI

--local TeamDef = require("View.Team.TeamUIDef")

local ScriptPath = "Team.TeamMainUI"

-- -----------------------------------
function TeamMainUI:New(openTab)
    openTab = openTab or AppDef.UITab.Team.Member
    local o = LUIBase:New()
    setmetatable(o, TeamMainUI)
    o:Init(openTab)
    return o
end

-- -----------------------------------
function TeamMainUI:Init(openTab)
    self:InitMemberVariable()
    self:RegistMsgs()
    self:InitViewSize()
    self:RegisterQuik(openTab)
end

--[[
初始化成员变量
]]
function TeamMainUI:InitMemberVariable()
    self.m_pUILayer = nil
    self.m_curTab = 0
    self.m_defaultQuickInd = nil
    self.m_pSubUIs = {}
end

-- -----------------------------------
function TeamMainUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
    
end

-- -----------------------------------
function TeamMainUI:RegistMsgs()
    self.msgIds = 
    {
        LUITeamEvent.ChangeTeamTab,
        LUIRoleTeamEvent.CreateTeam,
        LUIRoleTeamEvent.SetQuickTeamInd,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function TeamMainUI:ProcessEvent(msg)
    if msg.msgId == LUITeamEvent.ChangeTeamTab then
        LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, msg.value)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
        self:TabClicked(msg.value)
    elseif msg.msgId == LUIRoleTeamEvent.CreateTeam then
        LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, AppDef.UITab.Team.Member)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
        self:TabClicked(AppDef.UITab.Team.Member)
    elseif msg.msgId == LUIRoleTeamEvent.SetQuickTeamInd then
        self:SetQuickTeamType(msg.value)
    end
end

function TeamMainUI:SetQuickTeamType(teamType)
    if self.m_curTab ~= 3 then
        return
    end
    if self.m_pSubUIs[self.m_curTab] ~= nil then
        self.m_pSubUIs[self.m_curTab]:SetSelected(teamType)
    else
        self.m_defaultQuickInd = teamType
    end
    
end

-- -----------------------------------
function TeamMainUI:RegisterQuik(openTab)
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, ScriptPath)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end

    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.UI_Title_Team)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local function tabBtnClicked(ind)
        self:TabClicked(ind)
    end
    local tabValues = 
    {
        {GUITips.UI_Title_Team_Member, GUITips.UI_Title_Team_Lineup, GUITips.UI_Title_Team_Qiuci},
        tabBtnClicked
    }
    if LRoleDataMgr.MyHeroInfo:ISLunDaoScene() then
        tabValues[1] = {GUITips.UI_Title_Team_Member, GUITips.UI_Title_Team_Lineup}
        openTab = 1
    end
    --  local tabValues = 
    -- {
    --     {GUITips.UI_Title_Team_Member, GUITips.UI_Title_Team_Qiuci},
    --     tabBtnClicked
    -- }
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.AddTabBtn, tabValues)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

   LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, openTab)
   self:SendMsg(LGameMsg.m_baseMsgWithOne)
   self:TabClicked(openTab)
end

-- -----------------------------------
function TeamMainUI:TabClicked(ind)
    if  self.m_curTab == ind then
        return
    end
    if self.m_curTab ~= 0 then
        self:HideCurUI()
    end
    self.m_curTab = ind
    self:ShowCurUI()
end

function TeamMainUI:HideCurUI()
    if self.m_pSubUIs[self.m_curTab] == nil then
        return
    end
    self.m_pSubUIs[self.m_curTab].m_pUILayer:setVisible(false)
end

function TeamMainUI:ShowCurUI()
    if self.m_pSubUIs[self.m_curTab] == nil then
        self:DelayLoadSubUI(self.m_curTab)
    else
        self.m_pSubUIs[self.m_curTab].m_pUILayer:setVisible(true)
    end
end

function TeamMainUI:DelayLoadSubUI(tabInd)
    local uinames = {"View.Team.TeamMemberUI","View.Team.TeamFormationUI","View.Team.TeamQuickUI"}
    -- local uinames = {"View.Team.TeamMemberUI","View.Team.TeamQuickUI"}
    local ind = tabInd
    local delay = cc.DelayTime:create(0.1)
    local function loadSubUI()
        if self.m_curTab ~= ind then
            return
        end
        self.m_pSubUIs[ind] = require(uinames[ind]):New()
        self.m_pUILayer:addChild(self.m_pSubUIs[ind].m_pUILayer)

        if self.m_curTab == 3
            and self.m_defaultQuickInd ~= nil then
            self.m_pSubUIs[self.m_curTab]:SetSelected(self.m_defaultQuickInd)
        end
    end
    local func = cc.CallFunc:create(loadSubUI)
    local sequence = cc.Sequence:create(delay, func)
    self.m_pUILayer:runAction(sequence)
end

-- -----------------------------------
function TeamMainUI:InitViewSize()
    self.m_pUILayer = cc.Node:create()
end

return TeamMainUI