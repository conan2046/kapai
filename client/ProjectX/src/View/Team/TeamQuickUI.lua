--[[
lua里面的游戏逻辑控制
]]


local function Debug(log)
    --
end
local TeamQuickUI = LUIBase:New()
TeamQuickUI.__index = TeamQuickUI

local MaxMember = 5
--local this = LTcpSocket
function TeamQuickUI:New()
    local o = LUIBase:New()
    setmetatable(o,TeamQuickUI)    
    o:Init()
    return o
end


function TeamQuickUI:Init()
    self:RegistMsgs()
    self:InitMemberVariable()
    self:InitViewSize()
    self:InitUICtr()
    self:InitTaskList()
    self:InitEvt()
    self:SetBtnVisible()
    self:SetDefaultSelect()
    --self:SetSelected(1)
end

function TeamQuickUI:SetDefaultSelect()

    local publishData = LRoleDataMgr.MyHeroInfo.m_pTeam.m_pPublishList
    if publishData.m_byType == 0 then
        self:SetSelected(1)
    else
        for i = 1, #self.m_pTeamSettingData do
            if self.m_pTeamSettingData[i].m_type == publishData.m_byType then
                self:SetSelected(i)
                break
            end
        end
    end
end

function TeamQuickUI:RegistMsgs()
    self.msgIds = 
    {
        LUIRoleTeamEvent.RecvTeamPublishList,
        LUIRoleTeamEvent.TeamMemberChanged,
        LUIRoleTeamEvent.AutoApplyChanged,
        LUIRoleTeamEvent.TeamTargetChanged,
        LUIRoleTeamEvent.SetQuickTeamInd,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function TeamQuickUI:ProcessEvent(msg)
    if msg.msgId == LUIRoleTeamEvent.RecvTeamPublishList then
        self:RecvTeamList(msg.value)
    elseif msg.msgId == LUIRoleTeamEvent.TeamMemberChanged then
        self:SetBtnVisible()
    elseif msg.msgId == LUIRoleTeamEvent.AutoApplyChanged then
        self:ChangeAutoBtnState()
    elseif msg.msgId == LUIRoleTeamEvent.TeamTargetChanged then
        self:ShowTeamTarget()
    elseif msg.msgId == LUIRoleTeamEvent.SetQuickTeamInd then
        self:SetSelected(msg.msgValue)
    end
    -- elseif msg.msgId == LUIRoleTeamEvent.TeamMemberChanged then
    --     self:ShowTeamInfo()
    -- end
end

function TeamQuickUI:ShowTeamTarget()
    self:SetDefaultSelect()
    self:ChangeAutoBtnState()
end


function TeamQuickUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/TeamQuickLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

function TeamQuickUI:onExit()
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
function TeamQuickUI:InitMemberVariable()
    self.m_pHeroData = LRoleDataMgr.MyHeroInfo
    self.m_pTeamSettingData = LDataConstMgr:GetTeamData()
    self.m_teamQueryFlag = {}
    self.m_pUILayer = nil
    self.m_pTaskListView = nil
    self.m_pLeftBtns = {}
    self.m_pTaskCell = nil
    self.m_pFlashBtn = nil
    self.m_pChatBtn = nil
    self.m_pLeaveBtn = nil
    self.m_pInviteBtn = nil
    self.m_pCreateBtn = nil
    self.m_pAutoBtn = nil
    self.m_pTeamCell = nil
    self.m_pTeamLayout = nil
    self.m_pTeamTableView = nil
    self.m_pTeamCellSize = nil
    self.m_listInd = 0
    self.m_teamInd = 0
    self.m_pTeamPublishList = {}
end

function TeamQuickUI:InitUICtr()
    local panel = self.m_pUILayer:getChildByName("Panel"):getChildByName("QuickTeam")
    self.m_pTaskListView = panel:getChildByName("TaskList")
    self.m_pTaskCell = self.m_pTaskListView:getChildByName("Button1")
    self.m_pTeamLayout = panel:getChildByName("TeamListBg"):getChildByName("TeamList")
    self.m_pTeamCell = self.m_pTeamLayout:getChildByName("TeamBtn")
    self.m_pTeamCell:setVisible(false)
    self.m_pTeamCellSize = self.m_pTeamCell:getContentSize()
    local btnPanel  = panel:getChildByName("BtnList1")
    btnPanel:setTouchEnabled(false)
    self.m_pFlashBtn = btnPanel:getChildByName("Btn1")
    self.m_pChatBtn = btnPanel:getChildByName("Btn2")
    btnPanel  = panel:getChildByName("BtnList2")
    btnPanel:setTouchEnabled(false)
    self.m_pLeaveBtn = btnPanel:getChildByName("Btn1")
    self.m_pInviteBtn = btnPanel:getChildByName("Btn2")
    self.m_pAutoBtn = btnPanel:getChildByName("Btn4")
    self.m_pCreateBtn = btnPanel:getChildByName("Btn3")

    self:InitTeamTableView()
end

function TeamQuickUI:InitTaskList()
    table.insert(self.m_pLeftBtns, self.m_pTaskCell)
    self.m_pTaskCell:setTag(1)
    self:ShowTaskInfo(self.m_pTaskCell,self.m_pTeamSettingData[1])
    for i = 2, #self.m_pTeamSettingData do
        local cell = self.m_pTaskCell:clone()
        table.insert(self.m_pLeftBtns, cell)
        self.m_pTaskListView:pushBackCustomItem(cell)
        cell:setTag(i)
        self:ShowTaskInfo(cell,self.m_pTeamSettingData[i])
    end
end

function TeamQuickUI:ShowTaskInfo(cell, taskinfo)
    local choseImg = cell:getChildByName("ChooseBg")
    choseImg:setVisible(false)
    local nameLabel = cell:getChildByName("BtnName")
    nameLabel:setString(taskinfo.m_name)
end

function TeamQuickUI:InitTeamTableView()
    local tableView = cc.TableView:create(self.m_pTeamLayout:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(self.m_pTeamLayout:getAnchorPoint())
    tableView:setPosition(self.m_pTeamLayout:getPosition())
    tableView:setDelegate()
    tableView:setSwallowsTouches(false)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.m_pTeamLayout:getParent():addChild(tableView)

    -- local function tableCellTouched(sender,cell)
    --     self:TableCellTouched(cell)
    -- end
    local function cellSizeForTable(sender,idx)
        return self.m_pTeamCellSize.width, self.m_pTeamCellSize.height
    end
    local function tableCellAtIndex(sender, idx)
        return self:TableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        return self:GetTeamNum()
        --self:NumberOfCellsInTableView()
    end
    --tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量
    tableView:reloadData()
    self.m_pTeamTableView = tableView
end

function TeamQuickUI:GetTeamNum()
    if self.m_listInd == 0 then
        return 0
    end
    local curType = self.m_pTeamSettingData[self.m_listInd].m_type
    if self.m_pTeamPublishList[curType] == nil then
        return 0
    else
        return #self.m_pTeamPublishList[curType]
    end
end

function TeamQuickUI:TableCellTouched(cell)
    -- local ind = cell:getIdx()
    --  if self.m_teamInd == ind then
    --     return
    -- end
    -- local cellChild = cell:getChildByTag(123)
    -- local oldCell = self.m_pTeamTableView:cellAtIndex(self.m_teamInd)
    -- if oldCell ~= nil then
    --     local oldCellChild = oldCell:getChildByTag(123)
    --     if oldCellChild ~= nil then
    --         oldCellChild:setSelected(false)
    --     end
    -- end
    -- self.m_teamInd = ind
    -- cellChild:setSelected(true)

    -- self:SelServerArea(ind)
end

function TeamQuickUI:TableCellAtIndex(sender,idx)
    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pTeamCell:clone()
        
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0,0))
        cellChild:setVisible(true)
        cell:addChild(cellChild)
        cellChild:setVisible(true)

    else
        cellChild = cell:getChildByTag(123)
    end
    self:ShowTeamCellInfo(cellChild,idx)
    -- print("self.m_selLeftInd=",self.m_selLeftInd,idx)
    -- if self.m_selLeftInd == idx then
    --     cellChild:setSelected(true)
    -- else
    --     cellChild:setSelected(false)
    -- end
    return cell
end

function TeamQuickUI:GetPublishTeamData(ind)
    if self.m_pTeamSettingData[self.m_listInd] == nil then
        return nil
    end
    local curType = self.m_pTeamSettingData[self.m_listInd].m_type
    if self.m_pTeamPublishList[curType] == nil then
        return nil
    else
        return self.m_pTeamPublishList[curType][ind]
    end
end


function TeamQuickUI:ShowTeamCellInfo(cellChild,idx)
    local data = self:GetPublishTeamData(idx + 1)
    if data == nil then
        return
    end
    Debug(data)

    local taskLabel = cellChild:getChildByName("TaskName")
    taskLabel:setString(self.m_pTeamSettingData[self.m_listInd].m_name)
    local taskLvLabel = cellChild:getChildByName("LevelNum")
    taskLvLabel:setString(data.minLevel .. "-" .. data.maxLevel .. GUITips.Common_Ji)

    local heroList = cellChild:getChildByName("IconList")
    local num = #data.members

    local function ApplyCallback(sender)
        --print("ApplyCallback")
        local ind = sender:getTag()

        local curData = self:GetPublishTeamData(ind)
        if curData ~= nil then
            LuaNetSendMsg:QueryApplyTeam(curData.members[1].roleId)
        end

    end
    local btn = cellChild:getChildByName("Btn")
    btn:addClickEventListener(ApplyCallback)
	self:MarkIntaractCObj(btn)
    btn:setTag(idx + 1)
    for i = 1, num do
        local heroIcon = heroList:getChildByName("Icon" .. i)
        heroIcon:setVisible(true)
        -- local size = heroIcon:getContentSize()
        local lvLabel = heroIcon:getChildByName("LevelNum")
        lvLabel:setString(data.members[i].level)
        local nameLabel = heroIcon:getChildByName("NameBg"):getChildByName("Name")
        nameLabel:setString(data.members[i].name)
        local str = AppDef:GetHeroPicFileName(data.members[i].zhongzu,AppDef.HeadType.HERO_IMAGE_HEAD)
        local img = heroIcon:getChildByName("RoleImage")
        -- heroIcon:loadTextureNormal(str,ccui.TextureResType.localType)
        -- heroIcon:setContentSize(cc.size(size.width,size.height))
        -- print(size.width,size.height)
        img:loadTexture(str,ccui.TextureResType.localType)
    end

    for i = num + 1, 5 do
        local heroIcon = heroList:getChildByName("Icon" .. i)
        heroIcon:setVisible(false)
    end

end

function TeamQuickUI:SetSelected(ind)
    if self.m_listInd == ind then
        return
    end
    if self.m_listInd ~= 0 and self.m_pLeftBtns[self.m_listInd] then
        local img = self.m_pLeftBtns[self.m_listInd]:getChildByName("ChooseBg")
        img:setVisible(false)
    end
    if self.m_pLeftBtns[ind] == nil then
        return
    end
    self.m_listInd = ind

    local img = self.m_pLeftBtns[self.m_listInd]:getChildByName("ChooseBg")
    img:setVisible(true)
    self:QueryTeamList()
    
end

function TeamQuickUI:QueryTeamList()
    local teamType = self.m_pTeamSettingData[self.m_listInd].m_type
    if self.m_pTeamPublishList[teamType] == nil then
        self.m_pTeamPublishList[teamType] = {}
        --LuaNetSendMsg:QueryGetPublishTeam(teamType)
    else
        -- self:ClearPublistTeamData(teamType)
        -- self.m_pTeamPublishList[teamType] = {}
        -- LuaNetSendMsg:QueryGetPublishTeam(teamType)
    end
    LuaNetSendMsg:QueryGetPublishTeam(teamType)
end

function TeamQuickUI:ShowTeamList(teamType)

    local teamPublishData = self.m_pTeamPublishList[teamType]
    
    if teamPublishData == nil then
        return
    end
    self.m_pTeamTableView:reloadData()
end

function TeamQuickUI:RecvTeamList(stream)
   
    --[[
        获取队伍列表
    op=22    type   teamNum  { minLevel   maxLevel   memberNum [  roleId   name   leaveFlag  zhongzu   sex   level  ]}
    1byte   1byte    1byte       2byte      2byte     1byte        4byte  string    1byte     1byte   1byte  2byte
        ]]
    local teamType = stream:ReadByte()
    self:ClearPublistTeamData(teamType)
    self.m_pTeamPublishList[teamType] = {}
    local num = stream:ReadByte()
    print("RecvTeamList",num,teamType)
    for i = 1, num do
        --local info = self.m_pTeamPublishList[teamType]
        local info = {}
        info.minLevel = stream:ReadWord()
        info.maxLevel = stream:ReadWord()
        info.memberNum = stream:ReadByte()
        info.members = {}
        for j = 1, info.memberNum do
            local minfo = {}
            minfo.roleId = stream:ReadUInt()
            minfo.name = stream:ReadString()
            minfo.leaveFlag = stream:ReadByte()
            minfo.zhongzu = stream:ReadByte()
            minfo.sex = stream:ReadByte()
            minfo.level = stream:ReadWord()
            table.insert(info.members, minfo)
        end
        table.insert(self.m_pTeamPublishList[teamType],info)
    end
    if teamType == self.m_pTeamSettingData[self.m_listInd].m_type then
        self:ShowTeamList(teamType)
    end
end

function TeamQuickUI:ClearPublistTeamData(teamType)
    if self.m_pTeamPublishList[teamType] == nil then
        return
    end
    local cnt = #self.m_pTeamPublishList[teamType]
    local curInfo = self.m_pTeamPublishList[teamType]
    for i = 1, cnt do
        curInfo[i].minLevel = nil
        curInfo[i].maxLevel = nil
        local memberNum = curInfo[i].memberNum
        for j = 1, memberNum do
            curInfo[i].members[j].roldId = nil
            curInfo[i].members[j].name = nil
            curInfo[i].members[j].leaveFlag = nil
            curInfo[i].members[j].zhongzu = nil
            curInfo[i].members[j].sex = nil
            curInfo[i].members[j].level = nil
            curInfo[i].members[j] = nil
        end
        curInfo[i].members = nil
        curInfo[i] = nil
    end
    self.m_pTeamPublishList[teamType] = nil

end

function TeamQuickUI:ChangeAutoBtnState()
    local btnName
    
    if LRoleDataMgr.MyHeroInfo:IsTeam() then
        if LRoleDataMgr.MyHeroInfo:IsLeader() then
            self.m_pAutoBtn:setVisible(true)
            if LRoleDataMgr.MyHeroInfo.m_pTeam.m_bIsAutoApply then
                btnName = GUITips.UI_Text_Team_Zidongzhaomuzhong
            else
                btnName = GUITips.UI_Text_Team_Zidongzhaomu
            end
        else
            self.m_pAutoBtn:setVisible(false)
            return
        end
    else
        self.m_pAutoBtn:setVisible(true)
        if LRoleDataMgr.MyHeroInfo.m_pTeam.m_bIsAutoApply then
            btnName = GUITips.UI_Btn_Team_inPiPei
        else
            btnName = GUITips.UI_Btn_Team_PiPei
        end
        
    end

    local nameLabel = self.m_pAutoBtn:getChildByName("BtnName")
    nameLabel:setString(btnName)    
end

function TeamQuickUI:SetBtnVisible()
    local teamData = self.m_pHeroData.m_pTeam
    if self.m_pHeroData:IsTeam() == true then
        if self.m_pHeroData:IsLeader() == true then
            self:ShowLeaderBtn()
        else
            self:ShowTeamMemberBtn()
        end
    else
        self:ShowNormalBtn()
    end
    self:ChangeAutoBtnState()
end

function TeamQuickUI:ShowNormalBtn()
    self.m_pFlashBtn:setVisible(true)
    self.m_pChatBtn:setVisible(false)
    self.m_pLeaveBtn:setVisible(false)
    self.m_pInviteBtn:setVisible(false)
    self.m_pCreateBtn:setVisible(true)
    self.m_pAutoBtn:setVisible(true)

end

function TeamQuickUI:ShowTeamMemberBtn()
    self.m_pFlashBtn:setVisible(true)
    self.m_pChatBtn:setVisible(false)
    self.m_pLeaveBtn:setVisible(true)
    self.m_pInviteBtn:setVisible(false)
    self.m_pCreateBtn:setVisible(false)
    self.m_pAutoBtn:setVisible(false)
end

function TeamQuickUI:ShowLeaderBtn()
    self.m_pFlashBtn:setVisible(true)
    self.m_pChatBtn:setVisible(true)
    self.m_pLeaveBtn:setVisible(true)
    self.m_pInviteBtn:setVisible(true)
    self.m_pCreateBtn:setVisible(false)
    self.m_pAutoBtn:setVisible(false)
end

function TeamQuickUI:InitEvt()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    local function targetBtnClicked(sender)
        local ind = sender:getTag()
        self:SetSelected(ind)
    end
    for i = 1, #self.m_pLeftBtns do
        self.m_pLeftBtns[i]:addClickEventListener(targetBtnClicked)
		self:MarkIntaractCObj(self.m_pLeftBtns[i])
    end

    local function AutoApplyCallback(sender)
        if LRoleDataMgr.MyHeroInfo:IsLeader() then
            local publishData = LRoleDataMgr.MyHeroInfo.m_pTeam.m_pPublishList
            if publishData.m_byType == 0 then
                local teamType = self.m_pTeamSettingData[self.m_listInd].m_type
                LuaNetSendMsg:QueryPublishTeam(1, teamType, 1, 120)
            else
                if LRoleDataMgr.MyHeroInfo.m_pTeam.m_bIsAutoApply then
                    LuaNetSendMsg:QueryPublishTeam(0, publishData.m_byType, publishData.m_minLv, publishData.m_maxLv)
                else
                    LuaNetSendMsg:QueryPublishTeam(1, publishData.m_byType, publishData.m_minLv, publishData.m_maxLv)
                    
                end
            end
        elseif LRoleDataMgr.MyHeroInfo:IsTeam() == false then
            if LRoleDataMgr.MyHeroInfo.m_pTeam.m_bIsAutoApply == false then
                local teamType = self.m_pTeamSettingData[self.m_listInd].m_type
                LuaNetSendMsg:QueryOpenAutoTeam(teamType)
            else
                LuaNetSendMsg:QueryCloseAutoTeam()
            end
        end
    end
    self.m_pAutoBtn:addClickEventListener(AutoApplyCallback)
	self:MarkIntaractCObj(self.m_pAutoBtn)
    local function CreateTeamCallback(sender)
        LuaNetSendMsg:QueryCreateTeam()
        local teamType = self.m_pTeamSettingData[self.m_listInd].m_type
        LuaNetSendMsg:QueryPublishTeam(1, teamType, 1, 120)

    end
    self.m_pCreateBtn:addClickEventListener(CreateTeamCallback)
	self:MarkIntaractCObj(self.m_pCreateBtn)

    local function QuitTeamCallback(sender)
        LuaNetSendMsg:QueryLeaveTeam()
    end
    self.m_pLeaveBtn:addClickEventListener(QuitTeamCallback)
	self:MarkIntaractCObj(self.m_pLeaveBtn)
    local function FlashCallback(sender)

        local teamType = self.m_pTeamSettingData[self.m_listInd].m_type
        LuaNetSendMsg:QueryGetPublishTeam(teamType)
    end
    self.m_pFlashBtn:addClickEventListener(FlashCallback)
	self:MarkIntaractCObj(self.m_pFlashBtn)

    --[[
    世界喊话
    ]]
    local function ChatClicked(sender)
        local publishData = LRoleDataMgr.MyHeroInfo.m_pTeam.m_pPublishList
        if publishData.m_byType == 0 then
            local teamType = self.m_pTeamSettingData[self.m_listInd].m_type
            LuaNetSendMsg:QueryPublishTeam(1, teamType, 1, 120)
            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Team.TeamSettingUI",AppDef.UIType.PopWindow)
            self:SendMsg(LGameMsg.m_initUIMsg)
        else
            LRoleDataMgr.MyHeroInfo:SendTeamMsg()
        end
    end
    self.m_pChatBtn:addClickEventListener(ChatClicked)
	self:MarkIntaractCObj(self.m_pChatBtn)
end

return TeamQuickUI