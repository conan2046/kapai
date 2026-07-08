--[[
lua里面的游戏逻辑控制
玩法-信息显示界面
]]

local ActivityInfoUI = LUIBase:New()
ActivityInfoUI.__index = ActivityInfoUI
--local this = LTcpSocket
function ActivityInfoUI:New(id)
	local o = LUIBase:New()
	setmetatable(o,ActivityInfoUI)	
    o:Init(id)
	return o
end

--[[
注册UI消息
]]
function ActivityInfoUI:RegistMsgs()
    self.msgIds =
    {
        LUIRoleTeamEvent.TeamMemberChanged, --用于退出队伍,快捷战斗
    }
    self:RegistSelf(self, self.msgIds)
end

function ActivityInfoUI:ProcessEvent(msg)
    if msg.msgId == LUIRoleTeamEvent.TeamMemberChanged then
        if self.m_id == nil then
            return
        end

        if self.m_id ~= AppDef.EActivityID.EAID_ADVANCE then
            return
        end

        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.ActivityMainUI")
        self:SendMsg(LGameMsg.m_initUIMsg)

        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.ActivityInfoUI")
        self:SendMsg(LGameMsg.m_initUIMsg)

        LGameMsg.m_baseMsg:ChangeEventId(LUILoadingEvt.ShowLoading)
        LUIManager:SendMsg(LGameMsg.m_baseMsg)

        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Monopoly.MonopolyBaseUI",AppDef.UIType.Normal)
        LUIManager:SendMsg(LGameMsg.m_initUIMsg)

    end
end

function ActivityInfoUI:Init(id)
    --self.m_pNode = cc.Node:create()

    self.m_pUILayer = cc.CSLoader:createNode("csd/TaskPopupLayer.csb")
    local frameSize = AppDef.frameSize
    self.m_pUILayer:setContentSize(frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    self:RegistMsgs()
    self:InitData(id)
    self:AddTouchEvt()
    self:ShowInfo()
end

function ActivityInfoUI:onExit()
    LGameMsg.m_baseMsg:ChangeEventId(LUIActivityEvent.CloseActivityInfoUI)
    self:SendMsg(LGameMsg.m_baseMsg)
    self.m_pUILayer = nil
    self:Destory()
end

function ActivityInfoUI:InitData(id)
    self.m_id = id
    self.m_panel = self.m_pUILayer:getChildByName("QuestDialogUI")
    --button
    self.m_btnPanel = self.m_panel:getChildByName("bg")
    self.m_enterButton = self.m_btnPanel:getChildByName("ListView"):getChildByName("Btn_1")
    local infoPanel = self.m_panel:getChildByName("Panel")
    --信息部分  
    local taskPanel = infoPanel:getChildByName("TaskIcon")
    self.m_nameLabel = taskPanel:getChildByName("Text")
    self.m_iconImg = taskPanel:getChildByName("Icon")
    self.m_cntNameLabel = infoPanel:getChildByName("cishu")
    self.m_cntLabel = self.m_cntNameLabel:getChildByName("Text")
    self.m_activeValLabel = infoPanel:getChildByName("Activity"):getChildByName("Text")
    self.m_timeLabel = infoPanel:getChildByName("Time"):getChildByName("Text")
    self.m_lvLabel = infoPanel:getChildByName("Level"):getChildByName("Text")
    self.m_teamLabel = infoPanel:getChildByName("Team"):getChildByName("Text")
    local descPanel = infoPanel:getChildByName("Desc")
    self.m_text = descPanel:getChildByName("Text")
    self.m_text:setVisible(false)
    self.m_descListView = descPanel:getChildByName("ListView")
    self.m_drawListView = infoPanel:getChildByName("Reward"):getChildByName("ListView")
    self.m_iconBg = infoPanel:getChildByName("Reward"):getChildByName("IconBg")
end

function ActivityInfoUI:AddTouchEvt()
    local function OnEnterCallBack(sender)
        if not self:TeamEvent() then
            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.ActivityMainUI")
            self:SendMsg(LGameMsg.m_initUIMsg)

            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.ActivityInfoUI")
            self:SendMsg(LGameMsg.m_initUIMsg)

            EnterBtnTouched(self.m_id)
        end
    end
    self.m_enterButton:addClickEventListener(OnEnterCallBack)
	self:MarkIntaractCObj(self.m_enterButton)

    local function OnCloseCallBack(sender)
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.ActivityInfoUI")
	    self:SendMsg(LGameMsg.m_initUIMsg)
    end
    self.m_panel:addClickEventListener(OnCloseCallBack)
	self:MarkIntaractCObj(self.m_panel)
end

function ActivityInfoUI:TeamEvent()
    if self.m_id == AppDef.EActivityID.EAID_ADVANCE then
        if LRoleDataMgr.MyHeroInfo:IsTeam() then
            local function okFunc()
                LuaNetSendMsg:QueryLeaveTeam()
            end
            local function canelFunc()
                
            end
            Utils:ShowDialogOKCancel(GUITips.RSI_TARGET_RD_TIPS14, okFunc,canelFunc)

            return true
        end
    end
    return false
end
    
function ActivityInfoUI:ShowInfo()
    if self.m_id == nil then return end
    local info = LActivityManager:GetActivityData(self.m_id)
    if info == nil then return end
    self.m_nameLabel:setString(info.name)
    self.m_iconImg:loadTexture(AppDef.GUIRes["Activity_Name"..self.m_id],ccui.TextureResType.localType)

    local temp = string.split(info.finishState,'/')
    local cnt = tonumber(temp[1])
    local max = tonumber(temp[2])
	if info.state ~= 1 then
	    self.m_cntNameLabel:setString(GUITips.Activity_Cnt_1)
        self.m_cntLabel:setString("")
    elseif max == 999 then
        self.m_cntNameLabel:setVisible(false)
    else
        if self.m_id == AppDef.EActivityID.EAID_ORDEAL then
            self.m_cntNameLabel:setString(GUITips.Activity_Cnt_3)
        else
            self.m_cntNameLabel:setString(GUITips.Activity_Cnt_2)
        end
        self.m_cntLabel:setString(info.finishState)
    end
    --btn显示
    if info.state ~= 1 or (max ~= 999 and cnt >= max and self.m_id ~= AppDef.EActivityID.EAID_BOSS and self.m_id ~= AppDef.EActivityID.EAID_SHAKEMONEYTREE) then
        self.m_btnPanel:setVisible(false)
        self.m_btnPanel:setTouchEnabled(false)
    end
    --print("ActivityInfoUI:ShowInfo()",self.m_id,info.state,cnt,max)
    temp = string.split(info.activeVal,'/')
    max = tonumber(temp[2])
    if max == 0 then
        self.m_activeValLabel:getParent():setVisible(false)
    else
        self.m_activeValLabel:setString(info.activeVal)
    end
    self.m_timeLabel:setString(info.opentime)
    self.m_lvLabel:setString(""..info.openLv)
    local str = GUITips.RSI_DA_MSG2
    if  self.m_id == AppDef.EActivityID.EAID_FACTIONROB 
      or self.m_id == AppDef.EActivityID.EAID_ZHUAGUI  or self.m_id == AppDef.EActivityID.EAID_LIUJIESHILIAN 
      or self.m_id == AppDef.EActivityID.EAID_SHENJIELUNDAO then
        str = GUITips.RSI_DA_MSG3
    elseif self.m_id == AppDef.EActivityID.EAID_QUBAO then
        str = str.."/"..GUITips.RSI_DA_MSG3
    end
    self.m_teamLabel:setString(str)
    self:ShowDesc()
    self:ShowItemList()
end

function ActivityInfoUI:ShowItemList()
    if self.m_id == nil then return end
    local info = LActivityManager:GetActivityData(self.m_id)
    if info == nil or info.RevardId == nil or #info.RevardId == 0 then
        return
    end
    self.m_drawListView:removeAllChildren()
    for i=1,#info.RevardId do
        local itemId = tonumber(info.RevardId[i])
        if itemId ~= nil and itemId > 0 then
            local iconBg = self.m_iconBg:clone()
            Utils:GetItemCellValue(iconBg, 0, itemId, true, false, 1, nil, true)
            self.m_drawListView:addChild(iconBg)
        else
           local picName = GetOtherItemData(itemId)
           if picName ~= nil and #picName then
                local iconBg = self.m_iconBg:clone()
                local userDefine ={picFilePath = picName, quality = 0}
                local itemValue = {}
                itemValue.userDefine = userDefine
                ItemCellUI:New(iconBg, itemValue)
                self.m_drawListView:addChild(iconBg)
           end
        end
    end
end

function ActivityInfoUI:ShowDesc()
    if self.m_id == nil then return end
    local str = nil
--    for i=1,10 do
--        str = GUITips["RSI_DA_MSG"..self.m_id..i]
--        if str ~= nil then
--            local width = self.m_text:getContentSize().width
--            local label = self:CreateLabel(str,self.m_text:getFontName(),self.m_text:getFontSize(),width)
--            label:setTextColor(self.m_text:getTextColor())
--            self.m_descListView:addChild(label)
--        end
--    end
    if str == nil then
        local info = LActivityManager:GetActivityData(self.m_id)
        if info == nil then return end
        str = info.instruction
        local width = self.m_text:getContentSize().width
        local label = self:CreateLabel(str,self.m_text:getFontName(),self.m_text:getFontSize(),width)
        label:setTextColor(self.m_text:getTextColor())
        self.m_descListView:addChild(label)
    end
end

function ActivityInfoUI:CreateLabel(str,fontName,fontSize,width)
    local label = ccui.Text:create(str,fontName,fontSize)
    local curWidth = label:getAutoRenderSize().width
    local count = 1
    if curWidth > width then
        if width == 0 then width = 1 end
        count = math.ceil(curWidth/width)
    end
    label:ignoreContentAdaptWithSize(false)
    label:setTextAreaSize(cc.size(width,count*(fontSize+3)))
    return label
end

return ActivityInfoUI