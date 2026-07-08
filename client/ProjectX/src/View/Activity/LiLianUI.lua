--[[
lua里面的游戏逻辑控制
玩法-修仙历练界面
]]

local LiLianUI = LUIBase:New()
LiLianUI.__index = LiLianUI
--战斗中是否隐藏
LiLianUI.IsHideInBattle = true
--local this = LTcpSocket
function LiLianUI:New()
	local o = LUIBase:New()
	setmetatable(o,LiLianUI)	
    o:Init()
	return o
end

function LiLianUI:Init()
    self.m_pUILayer = cc.CSLoader:createNode("csd/LilianLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    self:RegistMsgs()
    self:InitData()
    self:AddTouchEvt()
	self:ShowAwardList()
    if size == 0 then
        LuaNetSendMsg:QueryLiLianInfo(1,nil)
    else
        self:ShowTitleText(1)
        --self:CreateUI()
        --临时去除动画
        self:CreateUIEnd()
        self:LoadChapList()
    end
end

function LiLianUI:CreateUI()
     local function callback(frame)
        print("LiLianUI:CreateUI()")
        --动画播放完成
        self:CreateUIEnd()
        self:LoadChapList()
     end

     local action = cc.CSLoader:createTimeline("csd/LilianLayer.csb")
     local timeline = ccs.Timeline:create()
     local frame = ccs.EventFrame:create()
     frame:setEvent("End")
     frame:setFrameIndex(60)
     timeline:addFrame(frame)
     action:addTimeline(timeline)
     self.m_pUILayer:runAction(action)
     action:pause()
     action:clearFrameEventCallFunc()
     action:gotoFrameAndPlay(0,60,false)
     action:setFrameEventCallFunc(callback)
end

function LiLianUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    if self.m_pCell then
        self.m_pCell:release()
        self.m_pCell = nil
    end
    self.m_pInfoPageView = nil
    
    self.m_cellList = nil
    self.m_leftButton = nil
    self.m_rightButton = nil
    self.m_closeButton = nil
    self.m_titleLabel = nil
    self.m_quickTeamBtn = nil
    self.m_teamBtn = nil
    self._paiHangBangBtn = nil
    self.m_teamBtnLabel1 =  nil
    self.m_teamBtnLabel2 =  nil
    
    self.m_item1 = nil
    self.m_item2 = nil
    self.m_item3 = nil
    
    self.m_item1_icon = nil
    self.m_item2_icon = nil
    self.m_item3_icon = nil
    self.m_item1_name = nil
    self.m_item2_name = nil
    self.m_item3_name = nil
    self.m_pRoleModels = nil
    self.m_autoSign = nil
end

--[[
注册UI消息
]]
function LiLianUI:RegistMsgs()
    self.msgIds = 
    {
        LUIActivityEvent.RefreshLiLianInfo,          --更新
        LUIRoleTeamEvent.AutoApplyChanged,           --自动组队开启
        LUIRoleTeamEvent.CreateTeam,                 --自己加入队伍
    }
    self:RegistSelf(self,self.msgIds)
end

function LiLianUI:ProcessEvent(msg)
    if msg.msgId == LUIActivityEvent.RefreshLiLianInfo then
        self:LoadChapter(msg.value)
    elseif msg.msgId == LUIRoleTeamEvent.AutoApplyChanged then
        self:ShowAutoTeam()
    elseif msg.msgId == LUIRoleTeamEvent.CreateTeam then
        self:LoadTeam()
    end
end

function LiLianUI:InitData()
    local panel = self.m_pUILayer:getChildByName("Panel")
    local listPanel = panel:getChildByName("ListBg")
    local titlePanel = panel:getChildByName("TitleBg")
    --pageview部分
    self.m_pInfoPageView = listPanel:getChildByName("PageView")
    self.m_pInfoPageView:setTouchEnabled(false)
    self.m_pCell = self.m_pInfoPageView:getChildByName("List")
    self.m_pCell:retain()
    --self.m_pCell:removeFromParent()
    self.m_cellList = {}
    --button
    self.m_leftButton = listPanel:getChildByName("LeftBtn")
    self.m_leftButton:setTouchEnabled(false)
    self.m_leftButton.userObject = 1
    self.m_rightButton = listPanel:getChildByName("RightBtn")
    self.m_rightButton:setTouchEnabled(false)
    self.m_rightButton.userObject = 2
    self.m_closeButton = titlePanel:getChildByName("CloseBtn")
    --信息部分  
    self.m_titleLabel = titlePanel:getChildByName("Title")
    --跳转按钮
    local bottomPanel = panel:getChildByName("DesBg")
    self.m_quickTeamBtn = bottomPanel:getChildByName("Button_1")
    self.m_teamBtn = bottomPanel:getChildByName("Button_2")
    self._paiHangBangBtn = bottomPanel:getChildByName("Button_3")
    self.m_teamBtnLabel1 =  self.m_teamBtn:getChildByName("Text_1")
    self.m_teamBtnLabel2 =  self.m_teamBtn:getChildByName("Text_2")
	
	self.m_item1 = bottomPanel:getChildByName("award"):getChildByName("TaskIcon")
	self.m_item2 = bottomPanel:getChildByName("award"):getChildByName("TaskIcon_0")
	self.m_item3 = bottomPanel:getChildByName("award"):getChildByName("TaskIcon_1")

	self.m_items = {}
	table.insert(self.m_items, self.m_item1)
	table.insert(self.m_items, self.m_item2)
	table.insert(self.m_items, self.m_item3)
	
	--self.m_item2:addClickEventListener(OnOpenTipsClick)
	--self.m_item3:addClickEventListener(OnOpenTipsClick)
	

	
    --角色模型
    self.m_pRoleModels = {}

    if LRoleDataMgr.MyHeroInfo.m_pTeam.m_bIsAutoApply then 
        self.m_autoSign = true
        self.m_teamBtnLabel1:setString(GUITips.UI_Btn_Team_inPiPei)
    end
end

function LiLianUI:ShowAwardList()
	local info = LActivityManager:GetActivityData(AppDef.EActivityID.EAID_XIUXIANLILIAN)
    if info == nil or info.RevardId == nil or #info.RevardId == 0 then
        return
    end

	for i=1,#info.RevardId do
        local itemId = tonumber(info.RevardId[i])
        if itemId ~= nil and itemId > 0 then
            local iconBg = self.m_items[i]
			local item_name = iconBg:getChildByName("Text")
			item_name:setVisible(false)
			--local itemData = LDataConstMgr:getCItemByID(itemId)
			--item_name:setString(itemData.m_name)
            Utils:GetItemCellValue(iconBg, 0, itemId, true, false, 1, nil, true)
        end
    end
end

function LiLianUI:CreateUIEnd()
    self.m_pInfoPageView:setTouchEnabled(true)
    self.m_leftButton:setTouchEnabled(true)
    self.m_rightButton:setTouchEnabled(true)
end

function LiLianUI:AddTouchEvt()
    local function OnMoveCallBack(sender)
        if self.m_chapNum < 1 then return end
        local index = self.m_pInfoPageView:getCurrentPageIndex()
        local userObject = sender.userObject
        if userObject == 1 then 
            if index > 0 then
               self.m_pInfoPageView:scrollToPage(index-1,0.3)              
            end
        elseif userObject == 2 then 
            if index < self.m_chapNum - 1 then
               self.m_pInfoPageView:scrollToPage(index+1,0.3)
            else
                Utils:ShowScrollTips(GUITips.RSI_HL_TIP15)
            end
        end
    end
    self.m_leftButton:addClickEventListener(OnMoveCallBack)
	self:MarkIntaractCObj(self.m_leftButton)
    self.m_rightButton:addClickEventListener(OnMoveCallBack) 
	self:MarkIntaractCObj(self.m_rightButton)

    local function OnCloseCallBack(sender)
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.LiLianUI")
	    self:SendMsg(LGameMsg.m_initUIMsg)
    end
    self.m_closeButton:addClickEventListener(OnCloseCallBack)
	self:MarkIntaractCObj(self.m_closeButton)

    local function OnStopCallBack(sender,event)
       if event == ccui.PageViewEventType.turning then
           local index = self.m_pInfoPageView:getCurrentPageIndex()+1
           self:ShowTitleText(index)
           self:ShowButton(index)
       end
    end
    self.m_pInfoPageView:addEventListener(OnStopCallBack)


    local function FindTeamBtnCallback(sender)
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Team.TeamMainUI",AppDef.UIType.FirstClassLayer,AppDef.UITab.Team.Quick)
        self:SendMsg(LGameMsg.m_initUIMsg)

        Utils:SendMsg(LUIRoleTeamEvent.SetQuickTeamInd,4)
    end
    self.m_quickTeamBtn:addClickEventListener(FindTeamBtnCallback)
	self:MarkIntaractCObj(self.m_quickTeamBtn)

    local isTeam = LRoleDataMgr.MyHeroInfo:IsTeam()
    if isTeam then
       -- self.m_teamBtn.userObject = true
        self.m_teamBtnLabel1:setVisible(false)
        self.m_teamBtnLabel2:setVisible(true)
    else 
        --self.m_teamBtn.userObject = false
        self.m_teamBtnLabel1:setVisible(true)
        self.m_teamBtnLabel2:setVisible(false)
    end
    local function TeamBtnCallback(sender)
        local isTeam = LRoleDataMgr.MyHeroInfo:IsTeam()
        if isTeam then
           LuaNetSendMsg:QueryPublishTeam(1,4,1,AppDef.MAX_TEAM_TARGET_LEVEL)
           LRoleDataMgr.MyHeroInfo:SendTeamMsg()
        elseif self.m_autoSign ~= nil and self.m_autoSign then
           LuaNetSendMsg:QueryCloseAutoTeam()
           self.m_teamBtnLabel1:setString(GUITips.UI_Text_Team_AutoPiPei)
           self.m_autoSign = false
        else
           LuaNetSendMsg:QueryOpenAutoTeam(4)
           self.m_teamBtnLabel1:setString(GUITips.UI_Btn_Team_inPiPei)
           self.m_autoSign = true
        end
    end
    self.m_teamBtn:addClickEventListener(TeamBtnCallback)
	self:MarkIntaractCObj(self.m_teamBtn)
--历练排行榜
    local function paiHangBangEvent( sender )
        -- body
        Utils:OpenFunction(AppDef.EModuleID.EMID_PAIHANGBANG_LILIAN)
        LGameMsg.m_baseMsgWithOne:Change(LUIRankEvent.ShowIndexRank, 9)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end
    self._paiHangBangBtn:addClickEventListener(paiHangBangEvent)
	self:MarkIntaractCObj(self._paiHangBangBtn)
end

function LiLianUI:LoadTeam()
    local isTeam = LRoleDataMgr.MyHeroInfo:IsTeam()
    if isTeam then
        self.m_teamBtnLabel1:setVisible(false)
        self.m_teamBtnLabel2:setVisible(true)
    end
end

function LiLianUI:ShowAutoTeam()
    if LRoleDataMgr.MyHeroInfo.m_pTeam.m_bIsAutoApply then
       Utils:ShowScrollTips(GUITips.UI_Text_Team_OpenAutoPiPei)
    end
end

function LiLianUI:LoadChapter(index)
    local info = LActivityManager.m_LiLianData
    if info == nil or index > #info then return end
    local data = info[index]
    local cell = nil
    if  self.m_cellList[data.m_chapInfos[1].index] == nil then
        cell = self.m_pCell:clone()
        cell:setTag(index)
        cell:setPosition(cc.p(0, 0))
        self.m_pInfoPageView:addPage(cell)
    else
        cell = self.m_pInfoPageView:getChildByTag(index)
    end

    if cell == nil then return end

    for i=1,5 do
        local item = cell:getChildByName("Lilian"..i)
        if item ~= nil then
            if data.m_chapInfos[i] ~= nil then
                local idx = data.m_chapInfos[i].index
                item:setTag(idx)
                item:setVisible(true)
                item:setEnabled(true)
                self:ShowChapInfo(item,idx)
                self.m_cellList[idx] = item
            else
                item:setVisible(false)
                item:setEnabled(false)
            end
        end
    end    
    if data.m_chapInfos[1].lock == 0 and self.m_chapNum < index then
        self.m_chapNum = index
        self.m_pInfoPageView:jumpToRight()
        self:ShowTitleText(self.m_chapNum)
        self:ShowButton(self.m_chapNum)
    end
end

function LiLianUI:LoadChapList()
    local info = LActivityManager.m_LiLianData
    if info == nil then return end
    self.m_cellList = {}
    self.m_pInfoPageView:removeAllChildren()
    self.m_chapNum = #info
    for i = 1, #info do
        if info[i].m_chapInfos[1].lock == 1 then
            self.m_chapNum = i-1
            break
        end
        local cell = self.m_pCell:clone()
        cell:setTag(i)
        cell:setPosition(cc.p(0, 0))
        self.m_pInfoPageView:addPage(cell)
        for j = 1,5 do
            local item = cell:getChildByName("Lilian"..j)
            if item ~= nil then
                if info[i].m_chapInfos[j] ~= nil then
                    --local idx = (i-1)*5+j
                    local idx = info[i].m_chapInfos[j].index
                    item:setTag(idx)
                    item:setVisible(true)
                    item:setEnabled(true)
                    self:ShowChapInfo(item,idx)
                    self.m_cellList[idx] = item
                else
                    item:setVisible(false)
                    item:setEnabled(false)
                end
            end
        end
    end
    self.m_pInfoPageView:jumpToRight()
    self:ShowTitleText(self.m_chapNum)
    self:ShowButton(self.m_chapNum)
end

function LiLianUI:ShowButton(pageId)
     local info = LActivityManager.m_LiLianData
    if info == nil then return end
    if pageId == 1 then
        --左边按钮不显示
        self.m_leftButton:setVisible(false)
        self.m_leftButton:setEnabled(false)

        self.m_rightButton:setVisible(true)
        self.m_rightButton:setEnabled(true)
    elseif pageId == #info then
        --右边按钮不显示
        self.m_rightButton:setVisible(false)
        self.m_rightButton:setEnabled(false)

        self.m_leftButton:setVisible(true)
        self.m_leftButton:setEnabled(true)
    else
        self.m_rightButton:setVisible(true)
        self.m_rightButton:setEnabled(true)

        self.m_leftButton:setVisible(true)
        self.m_leftButton:setEnabled(true)
    end
end

function LiLianUI:ShowTitleText(idx)
    local info = LActivityManager.m_LiLianData[idx]
    if info == nil then return end
    self.m_titleLabel:setString(tostring(info.m_chapName))
end

function LiLianUI:ShowChapInfo(cell,idx)
    if cell == nil then return end
    local ind = math.floor((idx-1)/5)+1
    local info = LActivityManager.m_LiLianData[ind]
    if info == nil then return end

    local ownImage = cell:getChildByName("ChooseBg")
    ownImage:setVisible(false)
    local titlePanel = cell:getChildByName("TitleBg")
    local nameLabel = titlePanel:getChildByName("TitleName")
    local indexLabel = titlePanel:getChildByName("NumBg"):getChildByName("Text")
    local nodeParent = cell:getChildByName("Base")
    local lockImage = cell:getChildByName("Close")
    local endImg = cell:getChildByName("EndImage")
    local roleModelNode = nodeParent:getChildByTag(123)


   
    local index = math.fmod(idx-1, 5) + 1
    if info.m_chapInfos[index] and info.m_chapInfos[index].lock == 0 then
        if roleModelNode == nil then
            roleModelNode = display.newNode()
            nodeParent:addChild(roleModelNode)
            roleModelNode:setPosition(cc.p(85, 57))
        end 
        self:ShowRoleModel(roleModelNode,idx)
        lockImage:setVisible(false)
    else 
        lockImage:setVisible(true)
    end    
    
    if info.m_chapInfos[index].winFlag == 1 then
        endImg:setVisible(true)
    else
        endImg:setVisible(false)
    end
    local count = "(0/1)"
    if info.m_chapInfos[index].canFight == 0 then
        count = "(1/1)"
    end
    nameLabel:setString(info.m_chapInfos[index].name..count)
    indexLabel:setString(info.m_chapInfos[index].index)
    
    local function Callback(sender)--点击战斗
        local tag = sender:getTag()
        if tag > 0 then
           LuaNetSendMsg:QueryLiLianInfo(2,tag)
        end
    end
    cell:addClickEventListener(Callback) 
	self:MarkIntaractCObj(cell)
end

--模型显示
function LiLianUI:ShowRoleModel(roleModelNode,idx)
    local chapId = math.ceil(idx/5)
    local data = LActivityManager.m_LiLianData[chapId]
    if data == nil or roleModelNode == nil then
         return
    end
    local index = math.floor((idx-1)%5)+1
    if self.m_pRoleModels[idx] == nil then
        self.m_pRoleModels[idx] = ModelAniNode:create(data.m_chapInfos[index].type,data.m_chapInfos[index].paramId)
        roleModelNode:addChild(self.m_pRoleModels[idx])
    else
        self.m_pRoleModels[idx]:InitAni(data.m_chapInfos[index].type, data.m_chapInfos[index].paramId)
    end
    self.m_pRoleModels[idx]:PlayStand(0)
end

return LiLianUI