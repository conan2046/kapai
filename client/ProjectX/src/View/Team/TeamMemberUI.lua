--[[
lua里面的游戏逻辑控制
]]


local function Debug(log)
    --
end
local TeamMemberUI = LUIBase:New()
TeamMemberUI.__index = TeamMemberUI

local MaxMember = 5
--local this = LTcpSocket
function TeamMemberUI:New()
	local o = LUIBase:New()
	setmetatable(o,TeamMemberUI)	
    o:Init()
	return o
end

function TeamMemberUI:Init()
    self:RegistMsgs()
    self:InitMemberVariable()
    self:InitViewSize()
    self:InitUICtr()
    self:InitEvt()
    self:ShowTeamInfo()
    self:ShowTeamTarget()
end

function TeamMemberUI:RegistMsgs()
    self.msgIds = 
    {
        --LUIRoleTeamEvent.CreateTeam,
        LUIRoleTeamEvent.TeamMemberChanged,
        LUIRoleTeamEvent.TeamTargetChanged,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function TeamMemberUI:ProcessEvent(msg)
    if msg.msgId == LUIRoleTeamEvent.TeamMemberChanged then
        self:ShowTeamInfo()
    elseif msg.msgId == LUIRoleTeamEvent.TeamTargetChanged then
        self:ShowTeamTarget()
    end
end

--[[
显示队伍目标
]]
function TeamMemberUI:ShowTeamTarget()
    self:SetAutoApplyBtnState()
    local teamData = self.m_pHeroData.m_pTeam
    if teamData.m_pPublishList.m_byType == 0 then
        self.m_pTargetLabel:setString(GUITips.UI_Text_Team_UnSetup)
        self.m_pTargetLvLabel:setString(GUITips.UI_Text_Team_UnSetup)
    else
        local settingData = LDataConstMgr:GetTeamDataByType(teamData.m_pPublishList.m_byType)
        self.m_pTargetLabel:setString(settingData.m_name)
        self.m_pTargetLvLabel:setString(teamData.m_pPublishList.m_minLv .. "-" .. teamData.m_pPublishList.m_maxLv)
    end
end

function TeamMemberUI:CreateTeam()
    self.m_pCreateTeamBtnList:setVisible(false)
    self.m_pMyTeamBtnList:setVisible(true)
end

function TeamMemberUI:ShowTeamInfo()
    self:SetAutoApplyBtnState()
    if self.m_pHeroData:IsTeam() == true then
        self.m_pCreateTeamBtnList:setVisible(false)
        self.m_pMyTeamBtnList:setVisible(true)
        self:ShowMyTeamMember()
    else
        self.m_pCreateTeamBtnList:setVisible(true)
        self.m_pMyTeamBtnList:setVisible(false)
        self:ShowNoTeamInfo()
    end
end

function TeamMemberUI:ShowMyTeamMember()
    local members = self.m_pHeroData.m_pTeam.m_pMembers
    local showInds = {1,1,1,1,1}
    --[[
    优先显示玩家
    ]]
    for i = 1,#members do
        if members[i].m_type == 1 then
            showInds[members[i].m_srcPos] = 0
            self:ShowOneMember(members[i])
        end
    end
    --[[
    剩下空位显示宠物
    ]]
    for i = 1,#members do
        if showInds[members[i].m_srcPos] == 1 then
            if members[i].m_type == 2 then
                showInds[members[i].m_srcPos] = 0
                self:ShowOneMember(members[i])
            end
        end
    end

    -- for i = 1,MaxMember do
    --     if members[i].m_type == 1 or members[i].m_type == 2 then
    --         showInds[members[i].m_srcPos] = 0
    --         self:ShowOneMember(members[i])
    --     end
    -- end
    for i = 1,#showInds do
        if showInds[i] == 1 then
            self.m_pMemberNames[i]:setVisible(false)
            self.m_pMemberLvs[i]:setVisible(false)
            self.m_pMemberAniNodes[i]:setVisible(false)
            self.m_pProfessals[i]:setVisible(false)
            self.m_pCaps[i]:setVisible(false)
            self.m_pPauses[i]:setVisible(false)
            self.m_pPetStars[i]:setVisible(false)
            self.m_pLineupPoses[i]:setVisible(false)
        end
    end
end

function TeamMemberUI:ShowOneMember(member)
    local ind = member.m_srcPos
    
    if member.m_type == 1 then
        self:ShowHeroMember(ind, member)
    elseif member.m_type == 2 then
        self:ShowPetMember(ind,member)
    end
    self.m_pMemberNames[ind]:setVisible(true)
    self.m_pMemberNames[ind]:setString(member.m_name)

    if member.m_id ~= self.m_pHeroData.id then
        self.m_pMemberNames[ind]:setTextColor(self.m_pDefauleNameColor)
    else
        self.m_pMemberNames[ind]:setTextColor(CCGREEN)
    end
    

    self.m_pMemberLvs[ind]:setVisible(true)
    self.m_pMemberLvs[ind]:setString(member.m_lv .. GUITips.Common_Ji)  
    self.m_pLineupPoses[ind]:setVisible(true)
    self.m_pMemberAnis[ind]:PlayStand(AppDef.SceneModelFace.Down)
end

function TeamMemberUI:ShowHeroMember(ind, member)
    self.m_pPetStars[ind]:setVisible(false)
    self.m_pProfessals[ind]:setVisible(true)
    if member.m_cap == 1 then--队长
        self.m_pCaps[ind]:setVisible(true)
        self.m_pCaps[ind]:loadTexture(self.m_pCapImgRes, ccui.TextureResType.plistType)
        self.m_pPauses[ind]:setVisible(false)
    elseif member.m_state == 0 then
        self.m_pCaps[ind]:setVisible(false)
        self.m_pPauses[ind]:setVisible(true)
    else
        self.m_pCaps[ind]:setVisible(false)
        self.m_pPauses[ind]:setVisible(false)
    end
    self.m_pMemberAniNodes[ind]:setVisible(true)
    if member.m_shap <= 0 then
        self.m_pMemberAnis[ind]:InitAni(AppDef.CEnum.ModelAniType.Hero, 
                                    member.m_professnal, 
                                    member.m_weapon, 
                                    member.m_wLight,
                                    0,
                                    0,
                                    0)
    else
        self.m_pMemberAnis[ind]:InitAni(AppDef.CEnum.ModelAniType.Monster, 
                                    member.m_shap)
    end
    self.m_pLineupPoses[ind]:setVisible(true)

    AppDef:ShowProAttrImg(self.m_pProfessals[ind], member.m_professnal)
end

function TeamMemberUI:ShowPetMember(ind, member)
    self.m_pProfessals[ind]:setVisible(true)
    self.m_pCaps[ind]:setVisible(true)
    self.m_pCaps[ind]:loadTexture(self.m_pPetImgRes, ccui.TextureResType.plistType)
    self.m_pPauses[ind]:setVisible(false)
    self.m_pMemberAniNodes[ind]:setVisible(true)


    self:ShowPetStars(self.m_pPetStars[ind],member.m_star)
    local basePet = LDataConstMgr:GetPetData(member.m_id)
    self.m_pMemberAnis[ind]:InitAni(AppDef.CEnum.ModelAniType.Monster, basePet.pic)

    AppDef:ShowProAttrImg(self.m_pProfessals[ind], basePet.petType)
end

function TeamMemberUI:ShowNoTeamInfo()
    for i = 1,MaxMember do
        self.m_pMemberNames[i]:setVisible(false)
        self.m_pMemberLvs[i]:setVisible(false)
        self.m_pMemberAniNodes[i]:setVisible(false)
        self.m_pProfessals[i]:setVisible(false)
        self.m_pCaps[i]:setVisible(false)
        self.m_pPauses[i]:setVisible(false)
        self.m_pPetStars[i]:setVisible(false)
    end
    self:ShowMyHero(1)
end

function TeamMemberUI:ShowMyHero(ind)
    local hdata = LRoleDataMgr.MyHeroInfo
    self.m_pMemberNames[ind]:setVisible(true)
    self.m_pMemberNames[ind]:setString(hdata.name)
    self.m_pMemberNames[ind]:setTextColor(CCGREEN)
    self.m_pMemberLvs[ind]:setVisible(true)
    self.m_pMemberLvs[ind]:setString(hdata.level .. GUITips.Common_Ji)  
    --self.m_pLineupPoses[ind]:setString(member.m_lineupPos .. GUITips.Common_Haowei)
    


    self.m_pPetStars[ind]:setVisible(false)
    self.m_pProfessals[ind]:setVisible(true)
    self.m_pCaps[ind]:setVisible(false)
    self.m_pCaps[ind]:setVisible(false)
    self.m_pPauses[ind]:setVisible(false)
    self.m_pMemberAniNodes[ind]:setVisible(true)

    AppDef:ShowProAttrImg(self.m_pProfessals[ind], hdata.professional)
    
    self.m_pMemberAnis[ind]:InitAni(AppDef.CEnum.ModelAniType.Hero, 
                                            hdata.professional, 
                                            hdata:GetWeaponId(), 
                                            hdata.LightEffect,
                                            0,
                                            0,
                                            0)
    self.m_pMemberAnis[ind]:PlayStand(AppDef.SceneModelFace.Down)

    
    
end

function TeamMemberUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/TeamMembersLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

function TeamMemberUI:onExit()
    self.m_pUILayer = nil
    self.m_pMapIds = nil
    self.m_pCurAni = nil
    self.m_pMapPanel = nil
    self.m_pHeroData = nil
    self:Destory()
end

--[[
初始化成员变量
]]
function TeamMemberUI:InitMemberVariable()
    self.m_pHeroData = LRoleDataMgr.MyHeroInfo
    self.m_pUILayer = nil
    self.m_pCreateTeamBtnList = nil
    self.m_pMyTeamBtnList = nil

    self.m_pCreateBtn = nil--创建队伍
    self.m_pQuickCreateBtn = nil--便捷组队

    self.m_pInviteBtn = nil--邀请好友
    self.m_pApplyListBtn = nil--申请列表
    self.m_pRecallBtn = nil--召回好友
    self.m_pQiutBtn = nil--退出
    self.m_pFightBtn = nil--前往挑战

    self.m_pMemberBtns = {}
    self.m_pMemberNames = {}
    self.m_pMemberLvs = {}
    self.m_pMemberAniNodes = {}
    self.m_pMemberAnis = {}
    self.m_pProfessals = {}
    self.m_pCaps = {}
    self.m_pPauses = {}
    self.m_pPetStars = {}
    self.m_pLineupPoses = {}

    self.m_pChatBtn = nil
    self.m_pAutoBtn = nil
    self.m_pSetupBtn = nil
    self.m_pTargetLabel = nil
    self.m_pTargetLvLabel = nil

    --self.m_pPauseImgRes = "res/UI/ui_zudui/ui_zudui_zanli.png"
    self.m_pCapImgRes = "res/UI/ui_zudui/ui_zudui_duizhang.png"
    self.m_pPetImgRes = "res/UI/ui_zudui/ui_zudui_huoban.png"
end

function TeamMemberUI:InitUICtr()
    local panel = self.m_pUILayer:getChildByName("Panel"):getChildByName("TeamMembers")
    local btnlist = panel:getChildByName("BtnList")
    self.m_pCreateTeamBtnList = btnlist:getChildByName("List1")
    self.m_pMyTeamBtnList = btnlist:getChildByName("List2")

    self.m_pCreateBtn = self.m_pCreateTeamBtnList:getChildByName("Btn1")--创建队伍
    self.m_pQuickCreateBtn = self.m_pCreateTeamBtnList:getChildByName("Btn2")--便捷组队

    self.m_pInviteBtn = self.m_pMyTeamBtnList:getChildByName("Btn1")--邀请好友
    self.m_pApplyListBtn = self.m_pMyTeamBtnList:getChildByName("Btn2")--申请列表
    self.m_pRecallBtn = self.m_pMyTeamBtnList:getChildByName("Btn3")--召回好友
    self.m_pQiutBtn = self.m_pMyTeamBtnList:getChildByName("Btn4")--退出
    self.m_pFightBtn = self.m_pMyTeamBtnList:getChildByName("Btn5")--前往挑战
    self.m_pFightBtn:setVisible(false)
    local menberPanel = panel:getChildByName("MembersList")
    for i = 1, MaxMember do
        self.m_pMemberBtns[i] = menberPanel:getChildByName("Btn" .. i)
        self.m_pMemberBtns[i]:setTag(i)
        local bg = self.m_pMemberBtns[i]:getChildByName("Bg1")
        self.m_pMemberNames[i] = bg:getChildByName("RoleName")
        self.m_pMemberLvs[i] = bg:getChildByName("LeveNum")
        self.m_pMemberAniNodes[i] = self.m_pMemberBtns[i]:getChildByName("Bg2"):getChildByName("Node")
        self.m_pMemberAnis[i] = ModelAniNode:create(AppDef.CEnum.ModelAniType.None, 0)
        self.m_pMemberAniNodes[i]:addChild(self.m_pMemberAnis[i])
        self.m_pProfessals[i] = self.m_pMemberBtns[i]:getChildByName("CareerImage")
        self.m_pCaps[i] = self.m_pMemberBtns[i]:getChildByName("TeamLeader")
        self.m_pPauses[i] = self.m_pMemberBtns[i]:getChildByName("LeaveImage")
        self.m_pPetStars[i] = self.m_pMemberBtns[i]:getChildByName("PetStar")
        self.m_pLineupPoses[i] = self.m_pMemberBtns[i]:getChildByName("StationNum")
    end
    self.m_pDefauleNameColor = self.m_pMemberNames[1]:getTextColor()
    local setupPanel = panel:getChildByName("SetupList")
    self.m_pChatBtn = setupPanel:getChildByName("CallBtn")
    self.m_pAutoBtn = setupPanel:getChildByName("RecruitBtn")

    self.m_pSetupBtn = setupPanel:getChildByName("SetupBg"):getChildByName("SetupBtn")

    local setupBg = setupPanel:getChildByName("SetupBg")
    self.m_pTargetLabel = setupBg:getChildByName("Target"):getChildByName("Name")
    self.m_pTargetLvLabel = setupBg:getChildByName("Level"):getChildByName("Num")

    if LRoleDataMgr.MyHeroInfo:ISLunDaoScene() then
        btnlist:setVisible(false)
        setupPanel:setVisible(false)
    end
end

function TeamMemberUI:ShowPetStars(panel, starNum)
    -- starLayout:removeAllChildren()
    -- local panelSize = starLayout:getContentSize()
    -- local size = self.m_pStarImg:getContentSize()
    -- local sizeWith =size.width
    --
    -- local width = sizeWith*star
    -- local sx = (panelSize.width - width)/2 + sizeWith/2
    -- local sy = size.height/2
    -- for i = 1, star do

    --     local starImg = self.m_pStarImg:clone()
    --     starLayout:addChild(starImg)
    --     starImg:setPosition(cc.p(sx, sy))
    --     sx = sx + sizeWith
    -- end
    
    if starNum == 0 then
        panel:setVisible(false)
        return
    end
    panel:setVisible(true)
    local star = panel:getChildByName("Star_1")
    local children = panel:getChildren()
    local curChildNum = #children
    if curChildNum > starNum then
        local deleteNum = curChildNum - starNum
        for i = curChildNum, starNum + 1, -1 do
            children[i]:removeFromParent()
            table.remove(children,i)
        end
    elseif curChildNum < starNum then
        for i = curChildNum + 1, starNum do
            local starImg = children[1]:clone()
            panel:addChild(starImg)
            table.insert(children, starImg)
        end
    end

    local panelSize = panel:getContentSize()
    local size = children[1]:getContentSize()
    local sizeWith =size.width
    if starNum>6 then
       sizeWith =size.width-9
    end
    local width = sizeWith*starNum
    local sx = (panelSize.width+18 - width)/2
    local sy = size.height/2
    for i = 1, #children do
        children[i]:setPosition(cc.p(sx, sy))
        sx = sx + sizeWith
    end 
end

function TeamMemberUI:InitEvt()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)


    local panel = self.m_pUILayer:getChildByName("Panel"):getChildByName("TeamMembers")
    local setupPanel = panel:getChildByName("SetupList")
    local tipsBtn = setupPanel:getChildByName("TeamUp"):getChildByName("Button_1")
    local function TipCallback(sender)
        Utils:ShowBuffTips(AppDef.BuffType.Team)
    end
    tipsBtn:addClickEventListener(TipCallback)
    self:MarkIntaractCObj(tipsBtn)

    local function CreateTeamCallback(sender)
        LuaNetSendMsg:QueryCreateTeam()
    end
    self.m_pCreateBtn:addClickEventListener(CreateTeamCallback)
	self:MarkIntaractCObj(self.m_pCreateBtn)



    local function QuitTeamCallback(sender)
        LuaNetSendMsg:QueryLeaveTeam()
    end
    self.m_pQiutBtn:addClickEventListener(QuitTeamCallback)
	self:MarkIntaractCObj(self.m_pQiutBtn)
    --[[
    便捷组队，写死测试
    ]]
    local function QuickTeamCallback(sender)
        --LuaNetSendMsg:QueryApplyTeam(3000011)
        --LuaNetSendMsg:QueryApplyTeam(3000088)
        LGameMsg.m_baseMsgWithOne:Change(LUITeamEvent.ChangeTeamTab, AppDef.UITab.Team.Quick)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
        
    end
    self.m_pQuickCreateBtn:addClickEventListener(QuickTeamCallback)
	self:MarkIntaractCObj(self.m_pQuickCreateBtn)
    --[[
    申请列表
    ]]
    local function ApplyListCallback(sender)
        if self.m_pHeroData:IsLeader() == false then
            return
        end
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Team.TeamApplyListUI",AppDef.UIType.SecondClassLayer)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    self.m_pApplyListBtn:addClickEventListener(ApplyListCallback)
	self:MarkIntaractCObj(self.m_pApplyListBtn)
    --[[
    邀请组队
    ]]
    local function InviteListCallback(sender)
        if self.m_pHeroData:IsTeam() == false then
            return
        end
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Team.TeamInviteUI",AppDef.UIType.SecondClassLayer)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    self.m_pInviteBtn:addClickEventListener(InviteListCallback)
	self:MarkIntaractCObj(self.m_pInviteBtn)
    --[[
    召回好友
    ]]
    local function CallFriendCallback(sender)
        if self.m_pHeroData:IsLeader() then
            local memberPause = self:LeaderCheckPauseMembers()
            if memberPause then
                LuaNetSendMsg:QueryTeamReCall()
            end
        elseif self.m_pHeroData:IsTeam() then
            --是队员的时候变成暂离功能
            if self.m_pHeroData:IsPause() then
                LuaNetSendMsg:QueryBackTeam()
            else
                LuaNetSendMsg:QueryPauseTeam()
            end
        end
    end
    self.m_pRecallBtn:addClickEventListener(CallFriendCallback)
	self:MarkIntaractCObj(self.m_pRecallBtn)
    local function FightBtnCallback(sender)
        local publishData = LRoleDataMgr.MyHeroInfo.m_pTeam.m_pPublishList
        if publishData.m_byType == 0 then
            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Team.TeamSettingUI",AppDef.UIType.PopWindow)
            self:SendMsg(LGameMsg.m_initUIMsg)
        else
            if publishData.m_byType == 3 then--捉鬼
                LGameMsg.m_autoPathMsg:ChangeToStart(11,-1,-1,0,bit.lshift(184,16),true,true, nil)
                self:SendMsg(LGameMsg.m_autoPathMsg)
				LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, true)
				self:SendMsg(LGameMsg.m_baseMsgWithOne)
            end
            -- if LRoleDataMgr.MyHeroInfo.m_pTeam.m_bIsAutoApply then
            --     LuaNetSendMsg:QueryPublishTeam(0, publishData.m_byType, publishData.m_minLv, publishData.m_maxLv)
            -- else
            --     LuaNetSendMsg:QueryPublishTeam(1, publishData.m_byType, publishData.m_minLv, publishData.m_maxLv)
                
            -- end
        end
    end
    self.m_pFightBtn:addClickEventListener(FightBtnCallback)
	self:MarkIntaractCObj(self.m_pFightBtn)
    local function MemberBtnClicked(sender)
        local ind = sender:getTag()
        local worldPos = sender:getParent():convertToWorldSpace(cc.p(sender:getPositionX(), sender:getPositionY()));
        self:MemberClicked(ind, worldPos)
    end
    for i = 1, MaxMember do
        self.m_pMemberBtns[i]:addClickEventListener(MemberBtnClicked)
		self:MarkIntaractCObj(self.m_pMemberBtns[i])
    end

    --[[
    组队设置
    ]]
    local function SetupBtnClicked(sender)
        if self.m_pHeroData:IsLeader() == true or self.m_pHeroData:IsTeam() == false then
            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Team.TeamSettingUI",AppDef.UIType.PopWindow)
            self:SendMsg(LGameMsg.m_initUIMsg)
        end
        
    end
    self.m_pSetupBtn:addClickEventListener(SetupBtnClicked)
	self:MarkIntaractCObj(self.m_pSetupBtn)
    --[[
    自动招募
    ]]
    local function AutoApplyClicked(sender)
        local publishData = LRoleDataMgr.MyHeroInfo.m_pTeam.m_pPublishList
        if publishData.m_byType == 0 then
            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Team.TeamSettingUI",AppDef.UIType.PopWindow)
            self:SendMsg(LGameMsg.m_initUIMsg)
        else
            if LRoleDataMgr.MyHeroInfo.m_pTeam.m_bIsAutoApply then
                LuaNetSendMsg:QueryPublishTeam(0, publishData.m_byType, publishData.m_minLv, publishData.m_maxLv)
            else
                LuaNetSendMsg:QueryPublishTeam(1, publishData.m_byType, publishData.m_minLv, publishData.m_maxLv)
                
            end
        end
        
    end
    self.m_pAutoBtn:addClickEventListener(AutoApplyClicked)
	self:MarkIntaractCObj(self.m_pAutoBtn)
    --[[
    世界喊话
    ]]
    local function ChatClicked(sender)
        local publishData = LRoleDataMgr.MyHeroInfo.m_pTeam.m_pPublishList
        if publishData.m_byType == 0 then
            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Team.TeamSettingUI",AppDef.UIType.PopWindow)
            self:SendMsg(LGameMsg.m_initUIMsg)
        else
            LRoleDataMgr.MyHeroInfo:SendTeamMsg()
        end
    end
    self.m_pChatBtn:addClickEventListener(ChatClicked)
	self:MarkIntaractCObj(self.m_pChatBtn)
end

function TeamMemberUI:HasTeamMember()
    local members = self.m_pHeroData.m_pTeam.m_pMembers
    local hasMember = false
    for i = 1,#members do
        if members[i].m_type == 1 then
            if members[i].m_cap ~= 1 then
                return true
            end
        end
    end
    return false
end

--[[
队长检查有没有暂离的队员
]]
function TeamMemberUI:LeaderCheckPauseMembers()
    if self.m_pHeroData:IsLeader() == false then
        return false
    end
    local members = self.m_pHeroData.m_pTeam.m_pMembers
    local hasMember = false
    for i = 1,#members do
        if members[i].m_type == 1 and members[i].m_cap ~= 1 then
            hasMember = true
            if members[i].m_state == 0 then--不是队长并且暂离
                return true
            end
        end
    end
    if hasMember == false then
        return true
    end
    return false
end

function TeamMemberUI:LeaderSetReCallBtnState()
    local memberPause = self:LeaderCheckPauseMembers()
    if memberPause then
        self.m_pRecallBtn:setTouchEnabled(true)
        self.m_pRecallBtn:setBright(true)
    else
        self.m_pRecallBtn:setTouchEnabled(false)
        self.m_pRecallBtn:setBright(false)
    end

end

function TeamMemberUI:SetAutoApplyBtnState()
    local panel = self.m_pUILayer:getChildByName("Panel"):getChildByName("TeamMembers")
    if self.m_pHeroData:IsLeader() == true then
        self.m_pAutoBtn:setVisible(true)
        local label = self.m_pAutoBtn:getChildByName("Text")
        if LRoleDataMgr.MyHeroInfo.m_pTeam.m_bIsAutoApply then
            label:setString(GUITips.UI_Text_Team_Zidongzhaomuzhong)
        else
            label:setString(GUITips.UI_Text_Team_Zidongzhaomu)
            
        end
        self.m_pSetupBtn:setVisible(true)
        self.m_pChatBtn:setVisible(true)
        self.m_pApplyListBtn:setVisible(true)
        --self.m_pFightBtn:setVisible(true)


        self.m_pRecallBtn:getChildByName("BtnName"):setString(GUITips.UI_Team_CallFriend)
        self:LeaderSetReCallBtnState()
        local setupPanel = panel:getChildByName("SetupList")
        local setupBg = setupPanel:getChildByName("SetupBg")
        setupBg:setVisible(true)
        local tipsBg = setupPanel:getChildByName("TipsBg")
        tipsBg:setVisible(false)

        tipsBg = setupPanel:getChildByName("TeamUp")
        tipsBg:setVisible(false)
    elseif self.m_pHeroData:IsTeam() == true then
        local setupPanel = panel:getChildByName("SetupList")
        local setupBg = setupPanel:getChildByName("SetupBg")
        setupBg:setVisible(true)
        self.m_pSetupBtn:setVisible(false)
        local tipsBg = setupPanel:getChildByName("TipsBg")
        tipsBg:setVisible(false)
        tipsBg = setupPanel:getChildByName("TeamUp")
        tipsBg:setVisible(false)

        if self.m_pHeroData:IsPause() then
            self.m_pRecallBtn:getChildByName("BtnName"):setString(GUITips.UI_Team_ReturnTeam)
        else
            self.m_pRecallBtn:getChildByName("BtnName"):setString(GUITips.UI_Team_PauseTeam)
        end
        
        self.m_pAutoBtn:setVisible(false)
        self.m_pChatBtn:setVisible(false)
        self.m_pApplyListBtn:setVisible(false)
        --self.m_pFightBtn:setVisible(false)
    else
        local setupPanel = panel:getChildByName("SetupList")
        local setupBg = setupPanel:getChildByName("SetupBg")
        setupBg:setVisible(false)
        local tipsBg = setupPanel:getChildByName("TipsBg")
        tipsBg:setVisible(true)
        tipsBg = setupPanel:getChildByName("TeamUp")
        tipsBg:setVisible(true)


        self.m_pAutoBtn:setVisible(false)
        self.m_pChatBtn:setVisible(false)
    end
end

function TeamMemberUI:MemberClicked(ind, pos)
    if self.m_pHeroData:IsTeam() == false then
        return
    end

    local members = self.m_pHeroData.m_pTeam.m_pMembers
    local member
    local showInds = {1,1,1,1,1}
    for i = 1,MaxMember do
        if members ~= nil and members[i] ~= nil and (members[i].m_type == 1 or members[i].m_type == 2) then
            if members[i].m_srcPos == ind then
                member = members[i]
                break
            end
        end
    end
    if member == nil then
        return
    end

    if member.m_id == self.m_pHeroData.id then
        self:DoClickSelf(member, pos)
    else
        if member.m_type == 2 then
            self:DoClickPet(member)
        else
            self:DoClickOthers(member.m_id, pos)
        end
        
    end
end

function TeamMemberUI:DoClickOthers(pid, pos)

    local function ChangeLeaderCallback()
        --退出队伍
        --LuaNetSendMsg:QueryLeaveTeam()
        LuaNetSendMsg:QueryTeamLeader(pid)
    end

    local function AddFriendCallback()
        LuaNetSendMsg:QueryAddFriend(pid)
    end

    local function QueryInfoCallback()
        LuaNetSendMsg:QueryOtherPlayer(pid)
    end

    local function KickoutCallback()
        LuaNetSendMsg:QueryExpelTeam(pid)

    end
    local btndata = {}
    btndata.pos = pos
    if self.m_pHeroData:IsLeader() == true then
        table.insert(btndata,{GUITips.UI_Team_ChangeLeader,ChangeLeaderCallback})
        table.insert(btndata,{GUITips.UI_Team_MemberInfo,QueryInfoCallback})
        table.insert(btndata,{GUITips.UI_Team_AddFriend,AddFriendCallback})
        if not LRoleDataMgr.MyHeroInfo:ISLunDaoScene() then
            table.insert(btndata,{GUITips.UI_Team_Kickout,KickoutCallback})
        end
    else
        table.insert(btndata,{GUITips.UI_Team_MemberInfo,QueryInfoCallback})
        table.insert(btndata,{GUITips.UI_Team_AddFriend,AddFriendCallback})
    end

    LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowCommomBtnList, btndata)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function TeamMemberUI:DoClickPet(member)

end

function TeamMemberUI:DoClickSelf(member, pos)
    if LRoleDataMgr.MyHeroInfo:ISLunDaoScene() then
        return
    end
    local function LeaveTeamCallback()
        --退出队伍
        LuaNetSendMsg:QueryLeaveTeam()
    end

    local function PauseTeamCallback()
        --暂离队伍
        LuaNetSendMsg:QueryPauseTeam()
    end

    --[[
    归队
    ]]
    local function ReturnTeamCallback()
        LuaNetSendMsg:QueryBackTeam()
    end

    local btndata = {}
    btndata.pos = pos
    if self.m_pHeroData:IsLeader() == true then
        table.insert(btndata,{GUITips.UI_Team_LeaveTeam,LeaveTeamCallback})
    else
        if member.m_state == 0 then
            table.insert(btndata,{GUITips.UI_Team_ReturnTeam,ReturnTeamCallback})
            table.insert(btndata,{GUITips.UI_Team_LeaveTeam,LeaveTeamCallback})
        else
            table.insert(btndata,{GUITips.UI_Team_PauseTeam,PauseTeamCallback})
            table.insert(btndata,{GUITips.UI_Team_LeaveTeam,LeaveTeamCallback})
        end
       
    end
    LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowCommomBtnList, btndata)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

return TeamMemberUI