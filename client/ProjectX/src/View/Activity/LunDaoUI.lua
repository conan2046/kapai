local TimerLabelUI = require("View.Common.TimerLabelUI")
local LunDaoTaskDelegate = require("View.Activity.LunDaoTaskDelegate")

local LunDaoUI = LUIBase:New()
LunDaoUI.__index = LunDaoUI
----------------------------------
LunDaoUI.IsHideInBattle = true
-----------------------------------
function LunDaoUI:New()
    local o = {}
    setmetatable(o, LunDaoUI)
    o:Init()
    return o
end
-----------------------------------
function LunDaoUI:Init()
    self.Script = "Activity.LunDaoUI"
    --------------------------------------------------
    self.m_isInit = true
    --------------------------------------------------
    self.m_taskData = nil
    --------------------------------------------------
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    --------------------------------------------------
    LuaNetSendMsg:QueryLunDaoInfo(3)
    --------------------------------------------------
end

-----------------------------------
function LunDaoUI:onExit()
    self:Destory()
    Utils:FreeTable(self.m_taskData)
    self.m_taskData = nil

    local _ = self.m_pResetTimer and self.m_pResetTimer:Destory()
    if self.m_pShadiDelegate then
        self.m_pShadiDelegate:onExit()
        self.m_pShadiDelegate = nil
    end
    if self.m_pShaguaiDelegate then
        self.m_pShaguaiDelegate:onExit()
        self.m_pShaguaiDelegate = nil
    end
    self.m_pTopPanel = nil
    self.m_pPanel = nil
    self.m_pTaskCheck = nil
    self.m_pTeamCheck = nil
    self.m_pTaskPanel = nil
    self.m_pTeamPanel = nil
    self.m_pJiFenText = nil
    self.m_pResetBar = nil
end
-----------------------------------
function LunDaoUI:InitUIControl()
    local pPanel = self.m_pUILayer:getChildByName("Lundao")
    ------------------------------------------------------
    self.m_pTopPanel = pPanel:getChildByName("Panel_Top")
    self:InitTopUIControl()
    ------------------------------------------------------
    local pLocker = pPanel:getChildByName("btn_Locker")
    pLocker:addClickEventListener(handler(self, LunDaoUI.ShowHidePanel))
	self:MarkIntaractCObj(pLocker)
    ------------------------------------------------------
    local pRankingPanel = pPanel:getChildByName("Panel_QuestAndRanking")
    pRankingPanel:setVisible(false)
    self.m_pPanel = pRankingPanel
    ------------------------------------------------------
    local pHelpBtn = pRankingPanel:getChildByName("btn_Help")
    pHelpBtn:addClickEventListener(handler(self, LunDaoUI.HelpBtnClick))
	self:MarkIntaractCObj(pHelpBtn)
    ------------------------------------------------------
    local pTaskCheck = pRankingPanel:getChildByName("CheckBox_Quest")
    pTaskCheck:setTag(0)
    pTaskCheck:addClickEventListener(handler(self, LunDaoUI.ChangePanelClick))
	self:MarkIntaractCObj(pTaskCheck)
    self.m_pTaskCheck = pTaskCheck
    
    local pTeamCheck = pRankingPanel:getChildByName("CheckBox_Ranking")
    pTeamCheck:setTag(1)
    pTeamCheck:addClickEventListener(handler(self, LunDaoUI.ChangePanelClick))
	self:MarkIntaractCObj(pTeamCheck)
    self.m_pTeamCheck = pTeamCheck
    ------------------------------------------------------
    self.m_pTaskPanel = pRankingPanel:getChildByName("Panel_Quest")
    self:InitTaskUIControl()
    ------------------------------------------------------
    self.m_pTeamPanel = pRankingPanel:getChildByName("teamListView")
    self.m_pTeamPanel:setVisible(false)
    self:InitTeamUIControl()
    ------------------------------------------------------
end
----------------------------------
function LunDaoUI:InitTopUIControl()
    if self.m_pTopPanel == nil then
        return
    end
    self.m_pJiFenText = self.m_pTopPanel:getChildByName("Point"):getChildByName("Value")

    local pTime = self.m_pTopPanel:getChildByName("Time")
    self.m_pResetBar = pTime:getChildByName("LoadingBar")
    local pTimeText = pTime:getChildByName("Value")
    self.m_pResetTimer = TimerLabelUI:New(pTimeText, nil, nil, handler(self, LunDaoUI.UpdateResetTimer))
end
----------------------------------
function LunDaoUI:InitTaskUIControl()
    if self.m_pTaskPanel == nil then
        return
    end
    local pShadi = self.m_pTaskPanel:getChildByName("shadi")
    self.m_pShadiDelegate = LunDaoTaskDelegate:New(pShadi)

    local pShaguai = self.m_pTaskPanel:getChildByName("shaguai")
    self.m_pShaguaiDelegate = LunDaoTaskDelegate:New(pShaguai)
end
----------------------------------
function LunDaoUI:InitTeamUIControl()
    if self.m_pTeamPanel == nil then
        return
    end
    local heroData = LRoleDataMgr.MyHeroInfo
    if heroData == nil or heroData.m_pTeam == nil or heroData.m_pTeam.m_pMembers == nil then
    end
    local list = heroData.m_pTeam.m_pMembers
    if #list == 0 then
        return
    end

    local pTableView = self.m_pTeamPanel
    local pGridCell = pTableView:getParent():getChildByName("Item_Team")
    if pGridCell == nil then
        return
    end

    local members = {}
    for i=1,#list do
        local member = list[i]
        if member.m_type == 1 then
            if member.m_cap == 1 then--队长
                table.insert(members, 1, member)
            else
                table.insert(members, member)
            end
        end
    end
    local function TeamMemberClicked(sender)
        local ind = sender:getTag()
        local member = members[ind]
        local worldPos = sender:getParent():convertToWorldSpace(cc.p(sender:getPositionX(), sender:getPositionY()));
        local showPos = cc.p(worldPos.x - 306 - sender:getContentSize().width / 2, worldPos.y)
        if member.m_id ~= heroData.id then
            self:DoClickOthers(member.m_id, showPos)
        end
    end
    -- dump(members, "members-->")
    pTableView:removeAllItems()
    for i=1,#members do
        if members[i].m_type == 1 then
           local member = members[i]
           
           local curCell = pGridCell:clone()
           curCell:setTag(i)
           curCell:addClickEventListener(TeamMemberClicked)
           self:MarkIntaractCObj(curCell)
           local headBg = curCell:getChildByName("bg_Head")
           local headImg = headBg:getChildByName("Icon")
           local str = Utils:GetHeroIconRes(member.m_professnal, AppDef.HeadIconResType.Square)
           headImg:loadTexture(str, UI_TEX_TYPE_LOCAL)
           headImg:setScale(0.9)

           local capImg = curCell:getChildByName("Captain")
           if member.m_cap == 1 then--队长
               capImg:loadTexture("res/UI/ui_zudui/ui_zudui_duizhang.png", UI_TEX_TYPE_PLIST)
               capImg:setVisible(true)
           elseif member.m_state == 0 then
               capImg:loadTexture("res/UI/ui_zudui/ui_zudui_zanli.png", UI_TEX_TYPE_PLIST)
               capImg:setVisible(true)
           else
               capImg:setVisible(false)
           end

           local nameLabel = curCell:getChildByName("Name")
           nameLabel:setString(member.m_name)
           local lvLabel = curCell:getChildByName("Level")
           lvLabel:setString(member.m_lv)

           pTableView:pushBackCustomItem(curCell)
        end
    end
    if self.m_pPanel ~= nil then
        self.m_pPanel:setVisible(true)
    end
end
-----------------------------------
function LunDaoUI:RegistMsgs()
    self.msgIds = 
    {
        LUILunDaoEvent.UpdateDataEvent,
        LUILunDaoEvent.UpdateTaskEvent,
        LUIRoleTeamEvent.TeamMemberChanged,
    }
    self:RegistSelf(self, self.msgIds)
end
-----------------------------------
function LunDaoUI:ProcessEvent(msg)
    if msg.msgId == LUILunDaoEvent.UpdateDataEvent then
        self:UpdateData(msg.value)
        self.m_isInit = false
    elseif msg.msgId == LUILunDaoEvent.UpdateTaskEvent then
        self:UpdateTask(msg.value)
    elseif msg.msgId == LUIRoleTeamEvent.TeamMemberChanged then
        self:InitTeamUIControl()
    end
end

function LunDaoUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
-----------------------------------
function LunDaoUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/LundaoLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end
----------------------------------
function LunDaoUI:UpdateData(data)
    if data == nil then
        return
    end
    Utils:FreeTable(self.m_taskData)
    self.m_taskData = nil
    self.m_taskData = data
    if self.m_isInit then
        self:ChangePanel(false)
    end

    self:UpdateJiFen()

    if data.nextFlushScecond > 0 and self.m_pResetTimer then
        self.m_pResetTimer:set(data.nextFlushScecond)
        self.m_pResetTimer:start()
    end

    if self.m_pShadiDelegate then
        self.m_pShadiDelegate:UpdateData(data.killRole, data.killRoleNum)
    end

    if self.m_pShaguaiDelegate then
        self.m_pShaguaiDelegate:UpdateData(data.killManster, data.killMonsterNum)
    end
    if self.m_pUILayer ~= nil then
        self.m_pUILayer:setVisible(true)
    end
end
----------------------------------
function LunDaoUI:UpdateJiFen()
    if self.m_taskData and self.m_pJiFenText then
        self.m_pJiFenText:setString(self.m_taskData.score or 0)
    end
end
----------------------------------
function LunDaoUI:UpdateTask(taskData)
    local _type = taskData.type
    local _value = taskData.value
    local _idx = taskData.idx
    if _type == 1 then--修改协议后弃用
        if self.m_taskData then
            self.m_taskData.score = _value
            self:UpdateJiFen()
        end
    elseif _type == 2 then--杀敌
        self.m_taskData.killRoleNum = _value
        if self.m_pShadiDelegate then
            self.m_pShadiDelegate:UpdateProgress(_value)
        end
    elseif _type == 3 then--杀怪
        self.m_taskData.killMonsterNum = _value
        if self.m_pShaguaiDelegate then
            self.m_pShaguaiDelegate:UpdateProgress(_value)
        end
    elseif _type == 4 then--杀敌任务完成情况
        if self.m_taskData.killRole[_idx] then
            self.m_taskData.killRole[_idx].isComplete = true
            if self.m_pShadiDelegate then
                self.m_pShadiDelegate:UpdateData(self.m_taskData.killRole, self.m_taskData.killRoleNum)
            end
        end
    elseif _type == 5 then--杀怪任务完成情况
        if self.m_taskData.killManster[_idx] then
            self.m_taskData.killManster[_idx].isComplete = true
            if self.m_pShaguaiDelegate then
                self.m_pShaguaiDelegate:UpdateData(self.m_taskData.killManster, self.m_taskData.killMonsterNum)
            end
        end
    elseif _type == 6 then
        if self.m_taskData then
            self.m_taskData.timeSpace = _value
            self.m_taskData.nextFlushScecond = _value
            self.m_pResetTimer:set(_value)
            self.m_pResetTimer:start()
        end
    end
end
----------------------------------
function LunDaoUI:ShowHidePanel(sender)
    if sender == nil or self.m_pPanel == nil or self.m_pPanel:getNumberOfRunningActions() > 0 then
        return
    end
    local visibleSize = AppDef.frameSize
    local posX = self.m_pPanel:getPositionX()
    if math.floor(posX - visibleSize.width) > 0 then
        self.m_pPanel:runAction(cc.MoveTo:create(0.25, cc.p(visibleSize.width, self.m_pPanel:getPositionY())))
        sender:getChildByName("Arrows"):setScaleY(1)
    else
        self.m_pPanel:runAction(cc.MoveTo:create(0.25, cc.p(visibleSize.width+self.m_pPanel:getContentSize().width, self.m_pPanel:getPositionY())))
        sender:getChildByName("Arrows"):setScaleY(-1)
    end
end
----------------------------------
function LunDaoUI:HelpBtnClick(sender)
    local msg = string.format('%s|%s|%s|%s|%s|%s|%s|%s|%s|', GUITips.RSI_XLXY_HELP_1, GUITips.RSI_XLXY_HELP_2, GUITips.RSI_XLXY_HELP_3, GUITips.RSI_XLXY_HELP_4, GUITips.RSI_XLXY_HELP_5, GUITips.RSI_XLXY_HELP_6, GUITips.RSI_XLXY_HELP_7, GUITips.RSI_XLXY_HELP_8, GUITips.RSI_XLXY_HELP_9)
    Utils:ShowDialog(msg)
end
----------------------------------
function LunDaoUI:ChangePanel(isTeam)
    self.m_pTaskPanel:setVisible(not isTeam)
    self.m_pTeamPanel:setVisible(isTeam)
    self.m_pTaskCheck:getChildByName("Choose"):setVisible(not isTeam)
    self.m_pTeamCheck:getChildByName("Choose"):setVisible(isTeam)
    if isTeam then
        Utils:InitUI("Team.TeamMainUI",AppDef.UIType.FirstClassLayer)
    end
end
----------------------------------
function LunDaoUI:ChangePanelClick(sender)
    self:ChangePanel(sender:getTag() > 0)
end
----------------------------------
function LunDaoUI:UpdateResetTimer(pText, h, m, s, left)
    if pText then
        pText:setString(string.format("%02d:%02d", m, s))
    end
    if self.m_pResetBar and self.m_taskData and self.m_taskData.timeSpace then
        self.m_pResetBar:setPercent(left*100/self.m_taskData.timeSpace)
    end
end
----------------------------------
function LunDaoUI:DoClickOthers(pid, pos)
    local function ChangeLeaderCallback()
        LuaNetSendMsg:QueryTeamLeader(pid)
    end

    local function QueryInfoCallback()
        LuaNetSendMsg:QueryOtherPlayer(pid)
    end

    local function AddFriendCallback()
        LuaNetSendMsg:QueryAddFriend(pid)
    end

    local btndata = {}
    btndata.pos = pos
    if LRoleDataMgr.MyHeroInfo:IsLeader() == true then
        table.insert(btndata,{GUITips.UI_Team_ChangeLeader,ChangeLeaderCallback})
        table.insert(btndata,{GUITips.UI_Team_MemberInfo,QueryInfoCallback})
        table.insert(btndata,{GUITips.UI_Team_AddFriend,AddFriendCallback})
    else
        table.insert(btndata,{GUITips.UI_Team_MemberInfo,QueryInfoCallback})
        table.insert(btndata,{GUITips.UI_Team_AddFriend,AddFriendCallback})
    end

    Utils:SendMsg(LUILogicEvent.ShowCommomBtnList, btndata)
end
----------------------------------
return LunDaoUI