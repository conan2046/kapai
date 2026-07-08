--[[
lua里面的游戏逻辑控制
滚动效率不高，有空优化一下
]]

local TeamSettingUI = LUIBase:New()
TeamSettingUI.__index = TeamSettingUI

local ScriptPath = "Team.TeamSettingUI"
local MaxLv = 120
--local this = LTcpSocket
function TeamSettingUI:New()
	local o = LUIBase:New()
	setmetatable(o,TeamSettingUI)	
    o:Init()
	return o
end


function TeamSettingUI:Init()
    self:RegistMsgs()
    self:InitMemberVariable()
    self:InitViewSize()
    self:InitUICtr()
    
    self:ShowSetting()
    self:InitEvt()
end

function TeamSettingUI:RegistMsgs()
    -- self.msgIds = 
    -- {
    --     LUIRoleTeamEvent.CreateTeam,
    --     LUIRoleTeamEvent.TeamMemberChanged,
    -- }
    -- self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function TeamSettingUI:ProcessEvent(msg)
    -- if msg.msgId == LUIRoleTeamEvent.CreateTeam then
    --     self:CreateTeam()
    -- elseif msg.msgId == LUIRoleTeamEvent.TeamMemberChanged then
    --     self:ShowTeamInfo()
    -- end
end

function TeamSettingUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/TeamSetupLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)


    
    
end

function TeamSettingUI:onExit()
    self:StopRightAutoScroll()
    self:StopLeftAutoScroll()
    self.m_pUILayer = nil
    self.m_pTeamSettingData = nil
    self.m_curInd = nil
    self.m_pListView = nil--
    self.m_pCellPanel = nil
    self.m_pCellChild = nil
    self.m_pClearBtn = nil
    self.m_pApplyList = nil

    self.m_pListView = nil
    if self.m_pTargetBtnCell then
        self.m_pTargetBtnCell:release()
        self.m_pTargetBtnCell = nil
    end
    
    self.m_pLowLvLayout = nil
    self.m_pHighLvLayout = nil

    self.m_pLowLvPanel = nil
    self.m_pHighLvPanel = nil
    self.m_pLvCell = nil
    self.m_pOKBtn = nil
    self.m_pAutoCB = nil
    self.m_pChatCb = nil

    self.m_pCloseBtn = nil
    self.m_pTextSize = nil

    self.m_textMidY = nil
    self.m_lowLvStartY = nil
    self.m_leftScrollSpd = nil
    self.m_rightScrollSpd = nil
    self.m_leftScrollUp = nil
    self.m_rightScrollUp = nil
    self.m_bIsScrollLeft = nil
    self.m_pLeftScrollUpdateEntry = nil
    self.m_pRightScrollUpdateEntry = nil
    self.m_pLowInd = nil
    self.m_pHighInd = nil
    self.m_lowPanelHeight = nil
    self.m_highPanelHeight = nil
    self:Destory()
end

--[[
初始化成员变量
]]
function TeamSettingUI:InitMemberVariable()
    self.m_pUILayer = nil
    self.m_pTeamSettingData = LDataConstMgr:GetTeamData()
    self.m_curInd = 0
    self.m_pLeftBtns = {}
end

function TeamSettingUI:InitUICtr()
    local panel = self.m_pUILayer:getChildByName("Panel"):getChildByName("Setupbg")
    local taskBg = panel:getChildByName("TaskBg")
    self.m_pListView = taskBg:getChildByName("TaskList")
    self.m_pTargetBtnCell = taskBg:getChildByName("Button1")
    self.m_pTargetBtnCell:retain()
    self.m_pTargetBtnCell:removeFromParent()
    local lvPanel = panel:getChildByName("LevelBg")
    self.m_pLowLvLayout = lvPanel:getChildByName("LowLevelList")
    self.m_pHighLvLayout = lvPanel:getChildByName("HightLevelList")

    self.m_pLowLvPanel = self.m_pLowLvLayout:getChildByName("lvPanel")
    self.m_pHighLvPanel = self.m_pHighLvLayout:getChildByName("lvPanel")
    self.m_pLvCell = lvPanel:getChildByName("Text")
    self.m_pOKBtn = panel:getChildByName("Btn")
    self.m_pAutoCB = panel:getChildByName("CheckBox_1")
    self.m_pChatCb = panel:getChildByName("CheckBox_1_0")

    local myTeamData = LRoleDataMgr.MyHeroInfo.m_pTeam
    if myTeamData.m_bIsAutoApply or myTeamData.m_bIsSettingAutoApply == false then
        self.m_pAutoCB:setSelected(true)
    else
        self.m_pAutoCB:setSelected(false)
    end

    
    if myTeamData.m_bIsSettingAutoApply == false then
        self.m_pChatCb:setSelected(true)
        self.m_bIsSettingAutoApply = true
    else
        self.m_pChatCb:setSelected(false)
    end
    --ChatCallback

    self.m_pCloseBtn = panel:getChildByName("TitleBg"):getChildByName("Btn_close")--
    self.m_pTextSize = self.m_pLvCell:getContentSize()

    self.m_textMidY = self.m_pLowLvLayout:getContentSize().height/2
    self.m_lowLvStartY = 0
    self.m_leftScrollSpd = 0
    self.m_rightScrollSpd = 0
    self.m_leftScrollUp = false
    self.m_rightScrollUp = false
    self.m_bIsScrollLeft = false
    self.m_pLeftScrollUpdateEntry = nil
    self.m_pRightScrollUpdateEntry = nil
    self.m_pLowInd = 1
    self.m_pHighInd = 1
    self.m_lowPanelHeight = 0
    self.m_highPanelHeight = 0
end

function TeamSettingUI:ShowSetting()  
    self:ShowLeftList()
    self:SetDefaultSelect()
    self:ShowLowLvLimit()
    self:ShowHighLvLimit()
end

function TeamSettingUI:ShowHighLvLimit()
    self.m_pHighLvPanel:removeAllChildren()
    local curSetting = self.m_pTeamSettingData[self.m_curInd]
    local cnt = MaxLv - curSetting.m_limitLv + 1
    local height = self.m_pTextSize.height*cnt
    self.m_highPanelHeight = height
    self.m_pHighLvPanel:setContentSize(cc.size(self.m_pTextSize.width,height))
    local dy = height
    for i = curSetting.m_limitLv, MaxLv do
        local textLabel = self.m_pLvCell:clone()
        textLabel:setTag(i)
        textLabel:setString(i)
        self.m_pHighLvPanel:addChild(textLabel)
        textLabel:setPosition(cc.p(self.m_pTextSize.width/2,dy - self.m_pTextSize.height/2))
        dy = dy - self.m_pTextSize.height
    end
    self.m_highLvStartY = self.m_textMidY - self.m_pTextSize.height/2
    self.m_pHighLvPanel:setPositionY(self.m_highLvStartY)
    self.m_pHighInd = (self.m_highPanelHeight + self.m_highLvStartY - self.m_textMidY + self.m_pTextSize.height/2)/self.m_pTextSize.height
end

function TeamSettingUI:ShowLowLvLimit()
    self.m_pLowLvPanel:removeAllChildren()
    local curSetting = self.m_pTeamSettingData[self.m_curInd]
    local cnt = MaxLv - curSetting.m_limitLv + 1
    local height = self.m_pTextSize.height*cnt
    self.m_lowPanelHeight = height
    self.m_pLowLvPanel:setContentSize(cc.size(self.m_pTextSize.width,height))
    local dy = height
    for i = curSetting.m_limitLv, MaxLv do
        local textLabel = self.m_pLvCell:clone()
        textLabel:setTag(i)
        textLabel:setString(i)
        self.m_pLowLvPanel:addChild(textLabel)
        textLabel:setPosition(cc.p(self.m_pTextSize.width/2,dy - self.m_pTextSize.height/2))
        dy = dy - self.m_pTextSize.height
    end
    self.m_lowLvStartY = -height + self.m_textMidY + self.m_pTextSize.height/2
    self.m_pLowLvPanel:setPositionY(self.m_lowLvStartY)

    self.m_pLowInd = (self.m_lowPanelHeight + self.m_lowLvStartY - self.m_textMidY + self.m_pTextSize.height/2)/self.m_pTextSize.height
end

function TeamSettingUI:SetDefaultSelect()
    self.m_curInd = 1
    self:SetLeftBtnState()
end

function TeamSettingUI:SetSelected(ind)
    if self.m_curInd == ind then
        return
    end
    self.m_curInd = ind
    self:SetLeftBtnState()
    self:ShowLowLvLimit()
    self:ShowHighLvLimit()
end

function TeamSettingUI:SetLeftBtnState()
    for i = 1, #self.m_pLeftBtns do
        local selectImg = self.m_pLeftBtns[i]:getChildByName("ChooseBg")
        
        local selectCB = self.m_pLeftBtns[i]:getChildByName("CheckBox")
        
        if i == self.m_curInd then
            selectImg:setVisible(true)
            selectCB:setSelected(true)
        else
            selectImg:setVisible(false)
            selectCB:setSelected(false)
        end
    end

end

function TeamSettingUI:ShowLeftList()
    for i = 1, #self.m_pTeamSettingData do
        local cell = self.m_pTargetBtnCell:clone()
        cell:setTag(i)
        local nameLabel = cell:getChildByName("BtnName")
        nameLabel:setString(self.m_pTeamSettingData[i].m_name)
        local selectImg = cell:getChildByName("ChooseBg")
        selectImg:setVisible(false)
        local selectCB = cell:getChildByName("CheckBox")
        selectCB:setSelected(false)
        self.m_pListView:pushBackCustomItem(cell)
        table.insert(self.m_pLeftBtns,cell)
    end
end

function TeamSettingUI:InitEvt()
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
    self.m_pCloseBtn:addClickEventListener(closeCallback)
	self:MarkIntaractCObj(self.m_pCloseBtn)
    local function targetBtnClicked(sender)
        local ind = sender:getTag()
        self:SetSelected(ind)
    end
    for i = 1, #self.m_pLeftBtns do
        self.m_pLeftBtns[i]:addClickEventListener(targetBtnClicked)
		self:MarkIntaractCObj(self.m_pLeftBtns[i])
    end

    local function LowLvPanelTouched(sender,event)
        if event == ccui.TouchEventType.began then
            self:LowLvPanelTouchBegin()
        elseif event == ccui.TouchEventType.moved then
            self:LowLvPanelTouchMoved()
        elseif event == ccui.TouchEventType.ended then
            self:LowLvPanelTouchEnd()
        elseif event == ccui.TouchEventType.canceled then
            self:LowLvPanelTouchEnd()
        end
    end
    self.m_pLowLvLayout:addTouchEventListener(LowLvPanelTouched)
	self:MarkIntaractCObj(self.m_pLowLvLayout)

    local function HighLvPanelTouched(sender,event)
        if event == ccui.TouchEventType.began then
            self:HighLvPanelTouchBegin()
        elseif event == ccui.TouchEventType.moved then
            self:HighLvPanelTouchMoved()
        elseif event == ccui.TouchEventType.ended then
            self:HighLvPanelTouchEnd()
        elseif event == ccui.TouchEventType.canceled then
            self:HighLvPanelTouchEnd()
        end
    end
    self.m_pHighLvLayout:addTouchEventListener(HighLvPanelTouched)
	self:MarkIntaractCObj(self.m_pHighLvLayout)

    local function OKCallback(sender)
        self:HandlePublish()
    end
    self.m_pOKBtn:addClickEventListener(OKCallback)
	self:MarkIntaractCObj(self.m_pOKBtn)
    -- local function AutoApplyCallback(sender)
    --     print("AutoApplyCallback")
    -- end
    -- self.m_pAutoCB:addClickEventListener(AutoApplyCallback)


    -- local function ChatCallback(sender)
    --     print("ChatCallback")
    -- end
    -- self.m_pChatCb:addClickEventListener(ChatCallback)
end

function TeamSettingUI:HandlePublish()
    local curSetting = self.m_pTeamSettingData[self.m_curInd]
    local teamId = LRoleDataMgr.MyHeroInfo:GetTeamId()

    local minlv = curSetting.m_limitLv + self.m_pLowInd - 1
    local maxlv = curSetting.m_limitLv + self.m_pHighInd - 1
    local isAutoApply = self.m_pAutoCB:isSelected()

    local isChat = self.m_pChatCb:isSelected()

    local flag
    if isAutoApply then
        flag = 1
    else
        flag = 0
    end

    if LRoleDataMgr.MyHeroInfo:IsTeam() == false then
        LuaNetSendMsg:QueryCreateTeam()
    end


    if minlv > maxlv then
        LuaNetSendMsg:QueryPublishTeam(flag, curSetting.m_type, maxlv, minlv)
    else
        LuaNetSendMsg:QueryPublishTeam(flag, curSetting.m_type, minlv, maxlv)
    end

    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, ScriptPath)
    self:SendMsg(LGameMsg.m_initUIMsg)

    if isChat then
        if minlv > maxlv then
            LRoleDataMgr.MyHeroInfo:SendTeamMsg(curSetting.m_type, maxlv, minlv)
        else
            LRoleDataMgr.MyHeroInfo:SendTeamMsg(curSetting.m_type, minlv, maxlv)
        end
    end
    -- local self.m_pLowInd = 1
    -- self.m_pHighInd = 1

    
end

function TeamSettingUI:LowLvPanelTouchBegin()
    self:StopLeftAutoScroll()
    self.m_touchBeginY = self.m_pLowLvLayout:getTouchBeganPosition().y
    self.m_bIsScrollLeft = true
end

function TeamSettingUI:LowLvPanelTouchMoved()
    local movey = self.m_pLowLvLayout:getTouchMovePosition().y
    local dy = movey - self.m_touchBeginY
    self.m_leftScrollSpd = dy
    if self.m_leftScrollSpd > 0 then
        self.m_leftScrollUp = false
    else
        self.m_leftScrollUp = true
    end
    self:SetLowPanelPos(dy)
    -- local curY = self.m_pLowLvPanel:getPositionY()
    -- self.m_leftScrollSpd = math.floor(dy) * 2
    -- dy = dy + curY
    -- if dy > (self.m_textMidY - self.m_pTextSize.height/2) then
    --     dy = (self.m_textMidY - self.m_pTextSize.height/2)
    -- elseif dy < self.m_lowLvStartY then
    --     dy = self.m_lowLvStartY
    -- end
    -- self.m_pLowLvPanel:setPositionY(dy)
    self.m_touchBeginY = movey
end

function TeamSettingUI:SetLowPanelPos(dy)
    local curY = self.m_pLowLvPanel:getPositionY()
    dy = dy + curY
    if dy > (self.m_textMidY - self.m_pTextSize.height/2) then
        dy = (self.m_textMidY - self.m_pTextSize.height/2)
    elseif dy < self.m_lowLvStartY then
        dy = self.m_lowLvStartY
    end
    self.m_pLowLvPanel:setPositionY(dy)
end

function TeamSettingUI:LowLvPanelTouchEnd()
    self:DoAutoScroll()
   
end

function TeamSettingUI:OnLeftScrollUpdate(dt)
    local isEnd = false
    local offset = 4*dt
    if self.m_leftScrollUp == false then
        self.m_leftScrollSpd = self.m_leftScrollSpd - offset
        if (self.m_leftScrollSpd) <= 0 then
            isEnd = true
        end
    else
        self.m_leftScrollSpd = self.m_leftScrollSpd + offset
        if self.m_leftScrollSpd >= 0 then
            isEnd = true
        end
    end

    if isEnd == true then
        self:DoLowLvAutoScrollEnd()
    else
        self:SetLowPanelPos(self.m_leftScrollSpd)
    end
end

function TeamSettingUI:OnRightScrollUpdate(dt)
    local isEnd = false
    local offset = 4*dt
    if self.m_rightScrollUp == false then
        self.m_rightScrollSpd = self.m_rightScrollSpd - offset
        if self.m_rightScrollSpd <= 0 then
            isEnd = true
        end
    else
        self.m_rightScrollSpd = self.m_rightScrollSpd + offset
        if self.m_rightScrollSpd >= 0 then
            isEnd = true
        end
    end
    if isEnd == true then
        self:DoHighLvAutoScrollEnd()
    else
        self:SetHighPanelPos(self.m_rightScrollSpd)
    end
end

function TeamSettingUI:DoLowLvAutoScrollEnd()
    
    local curY = self.m_pLowLvPanel:getPositionY()
    local offset = (curY + self.m_lowPanelHeight - self.m_textMidY) % (self.m_pTextSize.height) - self.m_pTextSize.height/2
    curY = curY - offset--math.floor(curY + self.m_pTextSize.height/2) % 
    self.m_pLowLvPanel:setPositionY(curY)
    self.m_pLowInd = (self.m_lowPanelHeight + curY - self.m_textMidY + self.m_pTextSize.height/2)/self.m_pTextSize.height
    self:StopLeftAutoScroll()
end

function TeamSettingUI:DoHighLvAutoScrollEnd()
    local curY = self.m_pHighLvPanel:getPositionY()
    
    local offset = (curY + self.m_highPanelHeight - self.m_textMidY) % (self.m_pTextSize.height) - self.m_pTextSize.height/2
    curY = curY - offset--math.floor(curY + self.m_pTextSize.height/2) % 
    self.m_pHighLvPanel:setPositionY(curY)

    self.m_pHighInd = (self.m_highPanelHeight + curY - self.m_textMidY + self.m_pTextSize.height/2)/self.m_pTextSize.height
    self:StopRightAutoScroll()
end

function TeamSettingUI:HighLvPanelTouchBegin()
    self:StopRightAutoScroll()
    self.m_bIsScrollLeft = false
    self.m_touchBeginY = self.m_pHighLvLayout:getTouchBeganPosition().y
end

function TeamSettingUI:DoAutoScroll()
    if self.m_bIsScrollLeft == true then
        local function OnLeftScrollUpdate(dt)
            self:OnLeftScrollUpdate(dt)
        end
        self:StopLeftAutoScroll()
        self.m_pLeftScrollUpdateEntry = AppDef.Director:getScheduler():scheduleScriptFunc(OnLeftScrollUpdate, 0.02, false)
    else
        local function OnRightScrollUpdate(dt)
            self:OnRightScrollUpdate(dt)
        end
        self:StopRightAutoScroll()
        self.m_pRightScrollUpdateEntry = AppDef.Director:getScheduler():scheduleScriptFunc(OnRightScrollUpdate, 0.02, false)
    end
end

function TeamSettingUI:StopRightAutoScroll()
     if self.m_pRightScrollUpdateEntry ~= nil then
        AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_pRightScrollUpdateEntry)
        self.m_pRightScrollUpdateEntry = nil
    end
end

function TeamSettingUI:StopLeftAutoScroll()
    if self.m_pLeftScrollUpdateEntry ~= nil then
        AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_pLeftScrollUpdateEntry)
        self.m_pLeftScrollUpdateEntry = nil
    end
end

function TeamSettingUI:HighLvPanelTouchMoved()

    local movey = self.m_pHighLvLayout:getTouchMovePosition().y
    local dy = movey - self.m_touchBeginY
    self.m_rightScrollSpd = dy
    if self.m_rightScrollSpd > 0 then
        self.m_rightScrollUp = false
    else
        self.m_rightScrollUp = true
    end
    self:SetHighPanelPos(dy)
    -- self.m_rightScrollSpd = math.floor(dy) * 5
    -- local curY = self.m_pHighLvPanel:getPositionY()
    -- dy = dy + curY
    -- if dy > (self.m_textMidY - self.m_pTextSize.height/2) then
    --     dy = (self.m_textMidY - self.m_pTextSize.height/2)
    -- elseif dy < self.m_lowLvStartY then
    --     dy = self.m_lowLvStartY
    -- end
    -- self.m_pHighLvPanel:setPositionY(dy)
    self.m_touchBeginY = movey
end

function TeamSettingUI:SetHighPanelPos(dy)
    local curY = self.m_pHighLvPanel:getPositionY()
    dy = dy + curY
    if dy > (self.m_textMidY - self.m_pTextSize.height/2) then
        dy = (self.m_textMidY - self.m_pTextSize.height/2)
    elseif dy < self.m_lowLvStartY then
        dy = self.m_lowLvStartY
    end
    self.m_pHighLvPanel:setPositionY(dy)

end

function TeamSettingUI:HighLvPanelTouchEnd()
    self:DoAutoScroll()
end

return TeamSettingUI