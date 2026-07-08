--[[
lua里面的游戏逻辑控制
]]

local TeamApplyListUI = LUIBase:New()
TeamApplyListUI.__index = TeamApplyListUI

local ScriptPath = "Team.TeamApplyListUI"
--local this = LTcpSocket
function TeamApplyListUI:New()
	local o = LUIBase:New()
	setmetatable(o,TeamApplyListUI)	
    o:Init()
	return o
end


function TeamApplyListUI:Init()
    self:RegistMsgs()
    self:InitMemberVariable()
    self:InitViewSize()
    self:InitUICtr()
    self:InitEvt()
    self:ShowApplyList()
end

function TeamApplyListUI:RegistMsgs()
    self.msgIds = 
    {
        --LUIRoleTeamEvent.CreateTeam,
        LUIRoleTeamEvent.TeamMemberChanged,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function TeamApplyListUI:ProcessEvent(msg)
    if msg.msgId == LUIRoleTeamEvent.TeamMemberChanged then
        self:HandleTeamMemberChanged()
    end
end

function TeamApplyListUI:HandleTeamMemberChanged()
    self.m_pApplyList = self.m_pHeroData:GetTeamApplyList()
    self:ShowApplyList()
end

function TeamApplyListUI:ShowApplyList()
    self.m_pListView:removeAllItems()
    local listPanel
    local applyCell
    for i = 1,#self.m_pApplyList do
        if i%2 == 1 then
            listPanel = self.m_pCellPanel:clone()
            self.m_pListView:pushBackCustomItem(listPanel)
            applyCell = listPanel:getChildByName("Name")
        else
            applyCell = self.m_pCellChild:clone()
            applyCell:setPosition(cc.p(self.m_cellWidth,0))
            listPanel:addChild(applyCell)
        end
        self:ShowApplyInfo(i, applyCell) 
    end
end

function TeamApplyListUI:ShowApplyInfo(ind, applyCell)
    local info = self.m_pApplyList[ind]
    local nameLabel = applyCell:getChildByName("RoleName")
    nameLabel:setString(info.name)
    local headImg = applyCell:getChildByName("Icon")

    local strHeadImage = AppDef:GetHeroPicFileName(info.profession, AppDef.HeadType.HERO_IMAGE_HEAD_ROUND)
    headImg:loadTexture(strHeadImage, ccui.TextureResType.localType);
    local lvLabel = headImg:getChildByName("LevelNum")
    lvLabel:setString(info.level)

    local powerLabel = applyCell:getChildByName("zhanli")
    powerLabel:setString(GUITips.UI_Shenqi_Zhanli .. ":" .. Utils:getPowerStr(info.zhandouli))
    local function AcceptCallback(sender)
        local idx = sender:getTag()
        local curInfo = self.m_pApplyList[idx]
        local pid = curInfo.id

        curInfo:Delete()
        self.m_pApplyList[idx] = nil
        table.remove(self.m_pApplyList,idx)
        if #self.m_pApplyList == 0 then
            Utils:SendMsg(LUIRoleTeamEvent.ApplyListChanged, false)
        end

        if LRoleDataMgr.MyHeroInfo:IsLeader() == true then
            LuaNetSendMsg:AccpetPlayerTeam(pid,1)
        elseif LRoleDataMgr.MyHeroInfo:IsTeam() == false then
            LuaNetSendMsg:AccpetJoinTeam(pid,1)
        end
        
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, ScriptPath)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    local btn = applyCell:getChildByName("Button1")
    btn:setTag(ind)
    btn:addClickEventListener(AcceptCallback)
	self:MarkIntaractCObj(btn)

    local function RefuseCallback(sender)
        local idx = sender:getTag()
        local curInfo = self.m_pApplyList[idx]
        local pid = curInfo.id

        curInfo:Delete()
        self.m_pApplyList[idx] = nil
        table.remove(self.m_pApplyList,idx)
        if #self.m_pApplyList == 0 then
            Utils:SendMsg(LUIRoleTeamEvent.ApplyListChanged, false)
        end
        
        if LRoleDataMgr.MyHeroInfo:IsLeader() == true then
            LuaNetSendMsg:AccpetPlayerTeam(pid,0)
        elseif LRoleDataMgr.MyHeroInfo:IsTeam() == false then
            LuaNetSendMsg:AccpetJoinTeam(pid,0)
        end
        
        self:ShowApplyList()
    end
    local btn = applyCell:getChildByName("Button2")
    btn:setTag(ind)
    btn:addClickEventListener(RefuseCallback)
	self:MarkIntaractCObj(btn)
    local pCareer = applyCell:getChildByName("Career")
    pCareer:setString(AppDef:GetHeroProfessionalName(info.profession))
end

function TeamApplyListUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/TeamIntoListLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)



    LGameMsg.m_baseMsgWithOne:Change(LUISecondClassBgEvent.SetTitle, GUITips.UI_Title_Team_ApplyList)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, ScriptPath)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    LGameMsg.m_baseMsgWithOne:Change(LUISecondClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function TeamApplyListUI:onExit()
    self.m_pUILayer = nil
    self.m_pUILayer = nil
    self.m_pListView = nil--
    self.m_pCellPanel = nil
    self.m_pCellChild = nil
    self.m_pClearBtn = nil
    self.m_pHeroData = nil
    self.m_pApplyList = nil
    self:Destory()
end

--[[
初始化成员变量
]]
function TeamApplyListUI:InitMemberVariable()
    self.m_pHeroData = LRoleDataMgr.MyHeroInfo
    self.m_pApplyList = self.m_pHeroData:GetTeamApplyList()
    self.m_pUILayer = nil
    self.m_pListView = nil--
    self.m_pCellPanel = nil
    self.m_pCellChild = nil
    self.m_pClearBtn = nil
    self.m_cellWidth = 0
end

function TeamApplyListUI:InitUICtr()
    local panel = self.m_pUILayer:getChildByName("IntoList")
    local btnlist = panel:getChildByName("BtnList")
    self.m_pListView = panel:getChildByName("ListBg"):getChildByName("ListView")--
    self.m_pCellPanel = panel:getChildByName("List")
    self.m_pCellChild = self.m_pCellPanel:getChildByName("Name")
    self.m_pClearBtn = panel:getChildByName("Btn1")
    self.m_cellWidth = self.m_pCellChild:getContentSize().width

end

function TeamApplyListUI:InitEvt()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    local function ClearListCallback(sender)
        --LuaNetSendMsg:QueryCreateTeam()
        self.m_pHeroData:CleatTeamApplyList()
        self.m_pListView:removeAllItems()
    end
    self.m_pClearBtn:addClickEventListener(ClearListCallback)
	self:MarkIntaractCObj(self.m_pClearBtn)
end

return TeamApplyListUI