--[[
NPC对话
]]

local NPCChatUI = LUIBase:New()
NPCChatUI.__index = NPCChatUI
--战斗中是否隐藏
NPCChatUI.IsHideInBattle = true
function NPCChatUI:New(chatData)
	local o = LUIBase:New()
	setmetatable(o,NPCChatUI)	
    o:Init(chatData)
	return o
end

--[[
注册消息
]]
function NPCChatUI:RegistMsgs()
    self.msgIds = 
    {
        -- LUILoginEvent.RecvCheckHeroName,
        -- LUILoginEvent.RecvServerList,
        -- LUILoginEvent.RecvRoleServerList,
        -- LUILoginEvent.LoginSuccess,
    }
    self:RegistSelf(self,self.msgIds)
end

function NPCChatUI:ProcessEvent(msg)
--    if msg.msgId == LUILoginEvent.RecvCheckHeroName then
--        self:SaveRandomName(msg.value)
--    end
end

function NPCChatUI:Init(chatData)
    self:RegistMsgs()
    self:CreateUINode("csd/QuestDialogLayer.csb")
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    
    self:InitData()
    self:AddTouchEvt()
    self:UpdateUserData(chatData)
end

function NPCChatUI:InitData()
    local panel = self.m_pUILayer:getChildByName("QuestDialogUI")
    local namePanel = panel:getChildByName("bg_Name")
    self.m_pNameLabel = namePanel:getChildByName("Name")
    self.m_pNPCImg = panel:getChildByName("NPC")
    self.m_pDescLabel = panel:getChildByName("Content")
    self.m_pListViewBg = panel:getChildByName("bg")
    self.m_pBgLabel = self.m_pListViewBg:getChildByName("Text")
    self.m_pListView = panel:getChildByName("ListView")
    self.m_pBaseBtn =panel:getChildByName("Item")
    self.m_pBaseBtn:setVisible(false)

    self._monopolyPanel = panel:getChildByName("Panel")
    self._PowerValue = self._monopolyPanel:getChildByName("tuijian"):getChildByName("Value")
    self._awardListView = self._monopolyPanel:getChildByName("ListView")
    self._awardCell = self._monopolyPanel:getChildByName("Item")
    local Reward = self._monopolyPanel:getChildByName("Reward")
    Reward:setVisible(false)

    self.m_headRes = nil

end 

function NPCChatUI:UpdateUserData(data)
    self.m_pChatData = data
    self.m_pNameLabel:setString(self.m_pChatData.Name)
    local panel = self.m_pUILayer:getChildByName("QuestDialogUI")
    local ttf = panel:getChildByTag(1)
    if ttf == nil then
        ttf = CCAysLabel:createWithString(self.m_pChatData.Desc, self.m_pDescLabel:getContentSize().width,AppDef.FontSize.Normal,AppDef.UIColor.Quest_Color)
        ttf:setPosition(self.m_pDescLabel:getPosition())
        panel:addChild(ttf)
        ttf:setTag(1)
    else
        ttf:setString(self.m_pChatData.Desc)
    end
    self.m_pDescLabel:setVisible(false)

    local strIcon = self:GetNpcBodyTexture(self.m_pChatData.type, self.m_pChatData.picId)
    if self.m_pChatData.type == 4 then
        self._awardListView:removeAllItems()
        strIcon = self:GetHeroBodyTexture(self.m_pChatData.type, self.m_pChatData.prof)
        -- self.m_pDescLabel:setVisible(false)
        self._monopolyPanel:setVisible(true)
        self._PowerValue:setString(Utils:getPowerStr(self.m_pChatData.monopolyChatData.power))
-- --显示奖励
--         local awardui = self._awardCell:clone()
--         Utils:GetItemCellValue(awardui, 0, self.m_pChatData.monopolyChatData.awardType, false, true, self.m_pChatData.monopolyChatData.awardNum, nil, true)
--         self._awardListView:pushBackCustomItem(awardui)
    else
        -- self.m_pDescLabel:setVisible(true)
        self._monopolyPanel:setVisible(false)
    end

    self:UnLoadHeadIcon()

    self.m_headRes = strIcon
    self.m_pNPCImg:setVisible(false)
    
    if self.m_headRes ~= nil then
        local function LoadImgComplete(tex)
            self.m_pNPCImg:loadTexture(strIcon, ccui.TextureResType.localType)
            self.m_pNPCImg:setVisible(true)
            self.m_pNPCImg:ignoreContentAdaptWithSize(true)
        end
        LGameMsg.m_resMsg:Change(LResEvent.LoadImgSync, self.m_headRes, LoadImgComplete)
        self:SendMsg(LGameMsg.m_resMsg)
    end
	
    

    -- self.m_pNPCImg:loadTexture(strIcon, ccui.TextureResType.localType)
    -- self.m_pNPCImg:ignoreContentAdaptWithSize(true)
    if #self.m_pChatData.Text > 0 then
        self.m_pListViewBg:setVisible(true)
        self.m_pListView:setVisible(true)
        self:ShowOptions()
    else
        self.m_pListViewBg:setVisible(false)
        self.m_pListView:setVisible(false)
    end

    self:TimerCallBack()
end

function NPCChatUI:UnLoadHeadIcon()
    if self.m_headRes then
        LGameMsg.m_resMsg:Change(LResEvent.UnLoadImgSync, self.m_headRes)
        self:SendMsg(LGameMsg.m_resMsg)
        self.m_headRes = nil
    end
end

function NPCChatUI:ShowOptions()
    self.m_pListView:removeAllItems()
    local height = 0
    local function btnClicked(sender)
        local ind = sender:getTag()
        self:OptionClicked(ind)
    end
    local cellHeight = self.m_pBaseBtn:getContentSize().height + self.m_pListView:getItemsMargin()
    for i = 1, #self.m_pChatData.Text do
        local btn = self.m_pBaseBtn:clone()
        btn:setVisible(true)
        btn:setTitleText(self.m_pChatData.Text[i])
        btn:setTag(i)
        btn:addClickEventListener(btnClicked)
		self:MarkIntaractCObj(btn)
        self.m_pListView:pushBackCustomItem(btn)
        height = height + cellHeight
    end
    local csize = self.m_pListView:getContentSize()
    local addHeight = height - csize.height
    csize.height = height
    self.m_pListView:setContentSize(csize)

    csize = self.m_pListViewBg:getContentSize()
    csize.height = csize.height + addHeight
    self.m_pListViewBg:setContentSize(csize)

    self.m_pBgLabel:setPositionY(self.m_pBgLabel:getPositionY() + addHeight)
end

function NPCChatUI:OptionClicked(ind)
    if self.m_pChatData ~= nil and self.m_pChatData.type == 4 then
        --多人闯关点击事件
        LGameMsg.m_baseMsgWithOne:Change(LUIMonopolyEvent.monopolyChatDialog, ind)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end    
    local indId = self.m_pChatData.TextIndex[ind]
    if indId == nil then
        return
    end
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Interact.NPCChatUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
   
    LuaNetSendMsg:QueryNpcChatOption(indId)
    
end

function NPCChatUI:GetNpcBodyTexture(npcType, npcPicId)
    if npcType == 0 then  --NPC
        return Utils:GetNPCIconRes(npcPicId, AppDef.HeadIconResType.Body)
    elseif npcType == 1 then --玩家
        return Utils:GetHeroIconRes(LRoleDataMgr.MyHeroInfo.professional, AppDef.HeadIconResType.Body)
    elseif npcType == 2 then --怪物
        return Utils:GetMonsterIconRes(npcPicId, AppDef.HeadIconResType.Body)
    elseif npcType == 3 then --坐骑
        return Utils:GetHorseIconRes(npcPicId, AppDef.HeadIconResType.Body)
    else
        return nil
    end
end

function NPCChatUI:GetHeroBodyTexture(npcType, professional)
    local str = AppDef:GetHeroPicFileName(professional, AppDef.HeadType.HERO_IMAGE_HALF_BODY)
    return str
end

function NPCChatUI:onExit()
    self:UnLoadHeadIcon()
    self:Destory()
    self.m_pUILayer = nil
    self.m_pNameLabel = nil
    self.m_pNPCImg = nil
    self.m_pDescLabel = nil
    self.m_pListView = nil
    self.m_pBaseBtn = nil
    self.m_pListViewBg = nil
    self.m_pBgLabel = nil
    if self.m_pChatData ~= nil then
        self.m_pChatData:Delete()
    end
    self._PowerValue = nil
    self._awardListView = nil
    self._awardCell = nil
    self.m_pNameLabel = nil
    self.m_pNPCImg = nil
    self.m_pDescLabel = nil
    self.m_pListViewBg = nil
    self.m_pBgLabel = nil
    self.m_pListView = nil
    self.m_pBaseBtn = nil
    self._monopolyPanel = nil
    self:UnSchedule()
    self.m_pChatData = nil
    self._changeBtn = nil
end

function NPCChatUI:AddTouchEvt()
   local panel = self.m_pUILayer:getChildByName("QuestDialogUI")
   local function ExitCallback(sender)
       LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Interact.NPCChatUI")
       self:SendMsg(LGameMsg.m_initUIMsg)
   end
   panel:addClickEventListener(ExitCallback)
	self:MarkIntaractCObj(panel)
end

function NPCChatUI:TimerCallBack()
    --    print("self.m_pChatData.picId", self.m_pChatData.picId)
    --领奖天官没有此功能，补偿天官也不要
    
    if self.m_pChatData == nil or self.m_pChatData.picId == nil then
        return
    end

--    print("self.m_pChatData.picId ==========", self.m_pChatData.picId)
    if self.m_pChatData.picId == 97 or self.m_pChatData.picId == 106 then
        return
    end

    local function UpdateCD()
        self:UpdateCoolTime()
    end
    self:UnSchedule()
    self.m_coldTime = 5
    self._changeBtn = self.m_pListView:getChildByTag(1)
    self:showBtnText(self.m_coldTime)
    if self.m_coldTime > 0 then
        local scheduler =  AppDef.Director:getScheduler()
        self.m_schedulerID = scheduler:scheduleScriptFunc(UpdateCD, 1, false)
    end
end

function NPCChatUI:UpdateCoolTime()
    self.m_coldTime = self.m_coldTime - 1
--    print("self.m_coldTime UpdateCoolTime", self.m_coldTime)
    self:showBtnText(self.m_coldTime)
    if self.m_coldTime <= 0 then
        self:OptionClicked(1)
        self:UnSchedule()
    end
end

function NPCChatUI:showBtnText(coldTime)
    -- body
    if self._changeBtn then
        local str = string.format("(%d)", coldTime)
        if #self.m_pChatData.Text <= 0 or self.m_pChatData.Text[1] == nil then
            return
        end
--        print("UpdateCoolTime", self.m_pChatData.Text[1]..str)
        self._changeBtn:setTitleText(self.m_pChatData.Text[1] .. str)
    end
end

function NPCChatUI:UnSchedule()
    if self.m_schedulerID then
        AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_schedulerID)
        self.m_schedulerID = nil
    end
end

return NPCChatUI