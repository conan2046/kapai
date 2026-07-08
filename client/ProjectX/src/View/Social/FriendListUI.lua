--[[
lua里面的游戏逻辑控制
]]

-- ----------------------------------------------
-- 常量区
local CsbFilePath = "csd/common/FriendLayer.csb"
local WhisperChatTab = 1
local FriendChatTab = 2

local FriendListUI = LUIBase:New()
FriendListUI.__index = FriendListUI
--local this = LTcpSocket
function FriendListUI:New()
	local o = LUIBase:New()
	setmetatable(o,FriendListUI)	
    o:Init()
	return o
end

--[[
注册事件
]]
function FriendListUI:RegistMsgs()
    self.msgIds = 
    {
        LUISocialEvent.updateFriendLayer,
        -- LUISocialEvent.addPcChatMsg,
        -- LUIChatEvent.addEmotion,
        -- LUIChatEvent.getRoleTeamId,--得到玩家的队伍信息
        LUISocialEvent.UpdateFriendGift,
    }
    self:RegistSelf(self,self.msgIds)
end

function FriendListUI:ProcessEvent(msg)
    if msg.msgId == LUISocialEvent.updateFriendLayer then
        self:updateFriendLayer();
        self:ShowFriendNum()
    elseif msg.msgId == LUISocialEvent.UpdateFriendGift then
        self:updateFriendLayer();
    end

    -- if msg.msgId == LUISocialEvent.addPcChatMsg then
    --     self:addChatLine(msg.value)
    -- end

    -- if msg.msgId == LUIChatEvent.addEmotion then
    --     self:addExpressiona(msg.value)
    -- end
    -- if msg.msgId ==LUIChatEvent.getRoleTeamId then

      
    --   if  self.ClickSender~=nil then    
    --       self:OnCheckBtnButtonClick(self.ClickSender,self.ClickIdx,msg.value.tID)
    --       self.ClickSender=nil
    --       self.ClickIdx=nil
    --   elseif self.currworldPos~=nil then
            
    
    --       self:ShowChatBtnList(self.currworldPos,msg.value.id,msg.value.tID, self.currName)
    --       self.currworldPos=nil
    --        self.currName=nil
    --   end
    -- end

end

--跳转到人
function FriendListUI:addPcTempChat(id)

    local idx = LRoleDataMgr.Social:FindFriend(id, LRoleDataMgr.Social:GetFriendData());
    if idx > 0 then
    -- is freind
        self._channel = FriendChatTab
        self:initLeftView();
        self:updateBtnStat();

        self._ChatId = id

        local cell =  self.m_pFriendTableView:cellAtIndex(idx - 1);
--cell不在显示状态
        if cell then
          local cellChild = cell:getChildByTag(123)
          cellChild:setBright(false)
        end
        self._lastSelCellIndex = idx - 1;

    else 
        local index = self:getWasperIndexById(id)
        if index <= 0 then
            return
        end 

        self._channel = WhisperChatTab
        self:initLeftView();
        self:updateBtnStat();

        self._WhisperChatId = id

        local cell =  self.m_pWhisperTableView:cellAtIndex(index - 1);
--cell不在显示状态
        if cell then
          local cellChild = cell:getChildByTag(123)
          cellChild:setBright(false)
        end
        self._lastWhisperSelIndex = index - 1;
    end
   
-- 聊天状态
   self:toChatState(true)

end

function FriendListUI:getWasperIndexById(id)
    local friendsData = LRoleDataMgr.Social:GetTmpChatList();
    for i = 1, #friendsData do
        if friendsData[i].id == id then
            return i
        end
    end
    return 0
end

function FriendListUI:toChatState(chatState)
    self._GuideImage:setVisible(not chatState)
    self._Btnbg:setVisible(chatState)
    self._ChatView:setVisible(chatState)
end

function FriendListUI:Init()
    self:CreateUINode(CsbFilePath);
    -- self.m_pUILayer = cc.CSLoader:createNode(CsbFilePath)
    -- self.m_pUILayer:setContentSize(AppDef.frameSize)
    -- ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    self:RegistMsgs();
    self:InitData();
    self:initFriendTableView();

    self:ShowFriendNum();
    self:AddTouchEvt();
    self.m_pFriendTableView:reloadData()
    self:OnEnabled()
    -- self:initLeftView();
    -- self:initRightView();
    -- self:RegisterGuide()
    -- self:enableSoundState(false)
    -- self._asyLoadImage = {}

    -- self._voiceTime = 15
    -- self._alreadyVoiceClose = false

end

function FriendListUI:OnEnabled()
    LuaNetSendMsg:QueryFriendList()
end

function FriendListUI:ShowFriendNum()
    local friendList = LRoleDataMgr.Social:GetFriendData()
   local size = #LRoleDataMgr.Social:GetFriendData();

   self._friendNumLabel:setString(size .. "/" .. LRoleDataMgr.Social._maxFriendNum);
end

function FriendListUI:InitData()
    self.m_pUILayer:findChildByName("None"):setVisible(false);
    self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/RewardsNum"):setVisible(false);
    self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/TuijianBtn"):setVisible(false);
    self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/ShenqingBtn"):setVisible(false);
    self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/Btn_1"):setVisible(true);
    -- self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/Btn_2"):setVisible(true);
    self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/Btn_3"):setVisible(true);
    self._listPanel =  self.m_pUILayer:findChildByName("Friend/FriendList/Friend1");
    self._listPanel:setVisible(true);
    self._listView = self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/Bg/ListView");
    -- self._applicationListPanel =  listPanel:getChildByName("Friend2");
    self._popUpPanel = self.m_pUILayer:findChildByName("Friend/FriendList/Popup");
    -- self._applicationListPanel:setVisible(false);
    self._popUpPanel:setVisible(false);
    self.m_pFriendCell = self.m_pUILayer:findChildByName("Friend/FriendList/Item");
    self.m_pFriendCell:getChildByName("Btn_Jiechu"):setVisible(false);
    self.m_pFriendCell:getChildByName("Btn_Get"):setVisible(false);
    self.m_pFriendCell:getChildByName("Btn_Give"):setVisible(true);
    self.m_pFriendCell:getChildByName("BtnGroup"):setVisible(false);
    self.m_pFriendCell:getChildByName("Btn"):setVisible(false);
    self.m_pFriendCell:setVisible(false);
    local tmp = self._listPanel:getChildByName("FriendsNum");
    tmp:setVisible(true);
    self._friendNumLabel = tmp:getChildByName("Text");
    
   
    -- local WhisperBg = panel:getChildByName("FriendsList"):getChildByName("WhisperBg")
    -- self.m_pWhisperView =  WhisperBg:getChildByName("WhisperTableView");
    -- self.m_pWhisperCell = self.m_pWhisperView:getChildByName("WhisperBtn_0");
    -- self.m_pWhisperCell:setVisible(false)

    -- self._channel = FriendChatTab;
    -- self._celIndex = 0;

    -- self._inited = false
    -- self._waperInited = false
    -- self._turnToPcChat = 0;
    self._lastSelCellIndex = -1
    -- self._lastWhisperSelIndex = -1;

end

function FriendListUI:initFriendTableView()
    local tableView = cc.TableView:create(self.m_pFriendView:getContentSize())
--    --print("width = ".. self.m_pFriendView:getContentSize().width .. "height = " .. self.m_pFriendView:getContentSize().height);
--    --print("width = ".. tableView:getContentSize().width .. "height = " .. tableView:getContentSize().height);
    tableView:setContentSize(self.m_pFriendView:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(cc.p(0, 0))
    tableView:setPosition(cc.p(0, 0))
    tableView:setDelegate()
    tableView:setSwallowsTouches(true)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.m_pFriendView:addChild(tableView)
    

    local function tableCellTouched(sender,cell)
        --print("tableCellTouched", cell:getIdx())
        self:FriendTableCellTouched(cell)
    end

    local function cellSizeForTable(sender,idx)
        local width = self.m_pFriendCell:getContentSize().width
        local height = self.m_pFriendCell:getContentSize().height
--        --print("cellSizeForTable width = "..width .. " cellSizeForTable height = ",height)
        return width, height
    end

    local function tableCellAtIndex(sender, idx)
--        --print("cellSizeForTable idx = ".. idx )
        return self:FriendTableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        LRoleDataMgr.Social:SortFriendData()
        local size = #LRoleDataMgr.Social:GetFriendData()
        return size
    end

    local function scrollViewDisScroll(view)
        self.m_isDragging = view:isDragging()
    end

    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量

    tableView:registerScriptHandler(scrollViewDisScroll, cc.SCROLLVIEW_SCRIPT_SCROLL)

    self.m_pFriendTableView = tableView
end

function FriendListUI:AddTouchEvt()
    -- local btn = self._listPanel:getChildByName("Btn_2");
    -- btn:setVisible(true);
    -- local function onFindClicked(sender)
    --     self:HandleFindClicked();
    -- end
    -- btn:addClickEventListener(onFindClicked)


    local btn = self._listPanel:getChildByName("Btn_1");
    btn:setVisible(true);
    --推荐好友
    local function onRecommendClicked(sender)
        Utils:SendMsg(LUIPopFClassBgEvent.ChangeTab, 4);
    end
    btn:addClickEventListener(onRecommendClicked)

    btn = self._listPanel:getChildByName("Btn_3");
    btn:setVisible(true);
    --一键赠送
    local function onSendClicked(sender)
        LuaNetSendMsg:QueryQuickSendGift();
    end
    btn:addClickEventListener(onSendClicked)

    -- btn = self._popUpPanel:getChildByName("bg"):getChildByName("Btn_close");
    -- local function onClosePopupClicked(sender)
    --     self._popUpPanel:setVisible(false);
    -- end
    -- btn:addClickEventListener(onClosePopupClicked);
    
    -- btn = self._popUpPanel:getChildByName("Btn");
    -- local function onSearchClicked(sender)
    --     self:onSearchClicked();
    -- end
    -- btn:addClickEventListener(onSearchClicked);
--     local panel = self.m_pUILayer:getChildByName("Panel"):getChildByName("FriendsList")

--     --私聊
--    self._btnPrivateChat = panel:getChildByName("Btn1")
--    self._btnPrivateChat:getChildByName("RedDot"):setVisible(false)
--    self._BtnNameFreind1 = self._btnPrivateChat:getChildByName("BtnName_1")
--    self._BtnNameFreind2 = self._btnPrivateChat:getChildByName("BtnName_2")

--     local function OnPrivateChatButtonClick(sender)
--         if(self._channel == WhisperChatTab) then
--             return
--         end
--         --清掉好友列表的状态
--         self._ChatId = 0
--         self._channel = WhisperChatTab
--         self:initLeftView();
--         self:updateBtnStat();

--     end
--     self._btnPrivateChat:addClickEventListener(OnPrivateChatButtonClick)
-- 	self:MarkIntaractCObj(self._btnPrivateChat)
--     --好友
--     self._btnFriendChat = panel:getChildByName("Btn2")
--     self._btnFriendChat:getChildByName("RedDot"):setVisible(false)
--     self._BtnNameWas1 = self._btnFriendChat:getChildByName("BtnName_1")
--     self._BtnNameWas2 = self._btnFriendChat:getChildByName("BtnName_2")
--     local function OnFriendChatButtonClick(sender)
--         if self._channel == FriendChatTab then
--             return
--         end
--        --清掉好友在私聊列表的状态
--        self._WhisperChatId = 0
--        self._channel = FriendChatTab
--        self:initLeftView();
--        self:updateBtnStat();
       
--     end
--     self._btnFriendChat:addClickEventListener(OnFriendChatButtonClick)
-- 	self:MarkIntaractCObj(self._btnFriendChat)
--    --添加好友
--    local friendBg = panel:getChildByName("FriendsBg")
--    self._AddFriendsBtn = friendBg:getChildByName("AddFriendsBtn")
--    self._AddFriendsBtn:addClickEventListener(handler(self, FriendListUI.OnAddFriendsBtnButtonClick))
-- 	self:MarkIntaractCObj(self._AddFriendsBtn)
--    --黑名单
--    self._AddBlacklistBtn = friendBg:getChildByName("AddBlacklistBtn")
--    local function OnAddBlacklistBtnButtonClick(sender)
--         LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Social.AddFriendLayer", AppDef.UIType.SecondClassLayer, 2)
--         self:SendMsg(LGameMsg.m_initUIMsg)
--    end
--    self._AddBlacklistBtn:addClickEventListener(OnAddBlacklistBtnButtonClick)
-- 	self:MarkIntaractCObj(self._AddBlacklistBtn)

--    local panelChat = self.m_pUILayer:getChildByName("Panel"):getChildByName("ChatScreem")
--    self._VoicePanel = self.m_pUILayer:getChildByName("Panel"):getChildByName("VoiceWindow")
--    self._onState = self._VoicePanel:getChildByTag(10533)
--    self._offState = self._VoicePanel:getChildByTag(10534)
--    self._voiceTxt = self._VoicePanel:getChildByTag(10535)

--    self._ChatView =  panelChat:getChildByName("ChatBg")
--    self._ChatView:setScrollBarEnabled(false)

--    self._OtherSide = panelChat:getChildByName("OtherSide")
--    local iconBg = self._OtherSide:getChildByName("IconBg")
--    self._otherBtnHeadHeight = iconBg:getPositionY()
--    self._otherChatTimeHeight = self._OtherSide:getChildByName("ChatTime"):getPositionY()
--    self._otherChatBgHeight = self._OtherSide:getChildByName("ChatBox"):getPositionY()
--    self._otherChatTextHeight = self._OtherSide:getChildByName("ChatText"):getPositionY()

--    self._OtherSideSound = panelChat:getChildByName("OtherSound")
--    self._otherSoundHeadHeight = self._OtherSideSound:getChildByName("IconBg"):getPositionY()
--    self._otherSoundTimeHeight = self._OtherSideSound:getChildByName("ChatTime"):getPositionY()
--    self._otherSoundBtnHeight = self._OtherSideSound:getChildByName("SoundBtn"):getPositionY()
--    self._otherSoundLengh = self._OtherSideSound:getChildByName("Time"):getPositionY()
--    self._otherSoundChatBgHeight = self._OtherSideSound:getChildByName("ChatBox"):getPositionY()
--    self._otherSoundChatTextHeight = self._OtherSideSound:getChildByName("ChatText"):getPositionY()


--    self._mySide = panelChat:getChildByName("MySide")
--    local myIconBg = self._mySide:getChildByName("IconBg")
--    self._myBtnHeadHeight = myIconBg:getPositionY()
--    self._myChatTimeHeight = self._mySide:getChildByName("ChatTime"):getPositionY()
--    self._myChatBgHeight = self._mySide:getChildByName("ChatBox"):getPositionY()
--    self._myChatTextHeight = self._mySide:getChildByName("ChatText"):getPositionY()


--    self._mySideSound = panelChat:getChildByName("MySound")
--    self._mySoundHeadHeight  = self._mySideSound:getChildByName("IconBg"):getPositionY()
--    self._mySoundTimeHeight = self._mySideSound:getChildByName("ChatTime"):getPositionY()
--    self._mySoundBtnHeight = self._mySideSound:getChildByName("SoundBtn"):getPositionY()
--    self._mySoundLengh = self._mySideSound:getChildByName("Time"):getPositionY()
--    self._mySoundChatBgHeight = self._mySideSound:getChildByName("ChatBox"):getPositionY()
--    self._mySoundChatTextHeight = self._mySideSound:getChildByName("ChatText"):getPositionY()


--    self._mySideSize = self._mySide:getContentSize()
--    self._OtherSideSize = self._OtherSide:getContentSize()
   
--    self._GuideImage = panelChat:getChildByName("GuideImage")
--    local btnBg =  panelChat:getChildByName("BtnBg");
--    self._Btnbg = btnBg;
--    self.m_pInputText = btnBg:getChildByName("Bg"):getChildByName("TextField")
--    self.m_pInputText:setCursorEnabled(true)

--    --赠礼
--    local giftButton = panelChat:getChildByName("Button_1")
--    local function OnOpenGiftButtonClick(sender)
--         --关闭自己
--         LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Social.SocialLayer")
--         self:SendMsg(LGameMsg.m_initUIMsg)

--         LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Social.GiveMainLayer", AppDef.UIType.FirstClassLayer, 1)
--         self:SendMsg(LGameMsg.m_initUIMsg)
--    end
--    giftButton:addClickEventListener(OnOpenGiftButtonClick)
-- 	self:MarkIntaractCObj(giftButton)
--    --亲密度
--    self._optExt =  panelChat:getChildByName("Tips"):getChildByName("Text")
--    local qinmidu = string.format(GUITips.RSI_FRIEND_QINMIDU, 0)
--    self._optExt:setString(qinmidu)

--    --语音
--    self._VoiceBtn = btnBg:getChildByName("VoiceBtn")
--    local function OnVoiceBtnButtonClick(sender)
--         self:enableSoundState(true)
--    end
--    self._VoiceBtn:addClickEventListener(OnVoiceBtnButtonClick)
-- 	self:MarkIntaractCObj(self._VoiceBtn)
--    self._SoundBtn = btnBg:getChildByName("SoundBtn")
--    local function OnSoundClick( sender )
--        -- body
--        self:enableSoundState(false)
--    end
--    self._SoundBtn:addClickEventListener(OnSoundClick)
-- 	self:MarkIntaractCObj(self._SoundBtn)

--    self._sendSoundBtn = self._SoundBtn:getChildByName("Sound")
--    local function showVoiceChatlayer(pTouch, pEvent)
--      if pEvent == ccui.TouchEventType.began then
--     --开始录音
-- --        self._VoicePanel:setVisible(true)
--           self:VoiceStartEvent()
--      end

--      if pEvent == ccui.TouchEventType.canceled then
-- --        self._VoicePanel:setVisible(false)

--         LGameMsg.m_baseMsgWithOne:Change(LUIChatEvent.showVoiceWindow, false)
--         LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)

--         local bMusicMate = LUserConfigMgr:GetIsMusicClosed()
--         if not bMusicMate then
--             LGameMsg.m_audioMsg:Change(LAudioEvent.StopSpeakVoice)
--             LUIManager:SendMsg(LGameMsg.m_audioMsg)
--         end

--      end

--      if pEvent == ccui.TouchEventType.moved then

--         if self._alreadyVoiceClose then
--           return
--         end

--         if not self._sendSoundBtn:getRendererClicked():isVisible() then
-- --          self._onState:setVisible(true)
-- --          self._offState:setVisible(false)
-- --          self._voiceTxt:setString(GUITips.RSI_VOICE_WINDOW_SHOW)
            
--             LGameMsg.m_baseMsgWithOne:Change(LUIChatEvent.cancelVoiceWindow)
--             LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
--         else
-- --          self._onState:setVisible(false)
-- --          self._offState:setVisible(true)
-- --          self._voiceTxt:setString(GUITips.RSI_VOICE_WINDOW_CANCEL)
--             LGameMsg.m_baseMsgWithOne:Change(LUIChatEvent.showVoiceWindow, true)
--             LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
--         end
--      end

--      if pEvent == ccui.TouchEventType.ended then
-- --        self._VoicePanel:setVisible(false)
--         if self._alreadyVoiceClose then
--           self._alreadyVoiceClose = false
--         end
--         self:UnFriendVoiceSchedule()
--         self:VoiceEndEvent()
--      end

--    end
--    self._sendSoundBtn:addTouchEventListener(showVoiceChatlayer)
-- 	self:MarkIntaractCObj(self._sendSoundBtn)
--     --表情
--    local EmogBtn = btnBg:getChildByName("EmogBtn")
--    local function OnEmogBtnButtonClick(sender)
--         LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Chat.ChatEmotionLayer", AppDef.UIType.PopWindow)
--         self:SendMsg(LGameMsg.m_initUIMsg)
--    end
--    EmogBtn:addClickEventListener(OnEmogBtnButtonClick)
-- 	self:MarkIntaractCObj(EmogBtn)
--    --发送
--    local EnterBtn = btnBg:getChildByName("EnterBtn")
--    local function OnEnterBtnButtonClick(sender)
-- 		local string = self.m_pInputText:getString()
-- 		if Utils:FilterAdLimitedMsg(string) == true then
-- 			local cMsg = LPcChatMsg:New()
-- 			cMsg.sendId = LRoleDataMgr.MyHeroInfo.id
-- 			cMsg.sendName = LRoleDataMgr.MyHeroInfo.name
-- 			cMsg.sendVip = LRoleDataMgr.MyHeroInfo.vipLevel
-- 			cMsg.sendProf = LRoleDataMgr.MyHeroInfo.professional
-- 			cMsg.sendSex = LRoleDataMgr.MyHeroInfo.sex
-- 			cMsg.sendLv = LRoleDataMgr.MyHeroInfo.level
-- 			cMsg.sendTeamId = LRoleDataMgr.MyHeroInfo.TeamId
-- 			cMsg.sendFactionId = LRoleDataMgr.MyHeroInfo.FactionId
-- 			if self._channel == WhisperChatTab then
-- 				cMsg.revId = self._WhisperChatId
-- 			else
-- 				cMsg.revId = self._ChatId
-- 			end
-- 			cMsg.time = os.time()
-- 			cMsg.msg = string

-- 			LRoleDataMgr.Social:AddPcChatMsg(cMsg.sendId,cMsg.revId,cMsg)
-- 			LRoleDataMgr.Social:UpdateTmpChatList(cMsg.sendId,cMsg)
-- 			--添加一条消息
-- 			LGameMsg.m_netDealMsg:Change(LUISocialEvent.addPcChatMsg, cMsg)
-- 			self:SendMsg(LGameMsg.m_netDealMsg)
-- 		else
-- 			if self._channel == WhisperChatTab then
-- 				LuaNetSendMsg:QuerySendPriateMsg(AppDef.ChatChanelType.CCT_PERSIONAL, self._WhisperChatId, string);
-- 			else
-- 				LuaNetSendMsg:QuerySendPriateMsg(AppDef.ChatChanelType.CCT_PERSIONAL, self._ChatId, string);
-- 			end
-- 		end
--         self.m_pInputText:setString("")
--    end
--    EnterBtn:addClickEventListener(OnEnterBtnButtonClick)
-- 	self:MarkIntaractCObj(EnterBtn)
--       --更新按钮状态
--     self:updateBtnStat();
end

-- function FriendListUI:onSearchClicked()
--     -- LuaNetSendMsg:QueryAddFriend(2000212)

--     local textField = self._popUpPanel:findChildByName("TextBg/TextField");
--     local string = textField:getString()
--     if string.len(string) > 0 then
--         LuaNetSendMsg:QuerySerchPlayer(string);
--         textField:setString("")
--         self._popUpPanel:setVisible(false);
--     end

-- end

-- function FriendListUI:HandleFindClicked()
--     self._popUpPanel:setVisible(true);
-- end

function FriendListUI:VoiceStartEvent()
  -- body
  LGameMsg.m_baseMsgWithOne:Change(LUIChatEvent.showVoiceWindow, true)
  LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)

  LVoiceDataMgr.ChannelType = AppDef.ChatChanelType.CCT_PERSIONAL
  LVoiceDataMgr:startVoice()

  self:FriendVoiceTimerCallBack()
  LVoiceDataMgr:registerCallBack(self:getCurChatId())
end

function FriendListUI:VoiceEndEvent()
  -- body
  LGameMsg.m_baseMsgWithOne:Change(LUIChatEvent.showVoiceWindow, false)
  LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
  LVoiceDataMgr:endVoice()

end

function FriendListUI:FriendVoiceTimerCallBack()
    local function UpdateCD()
        self._voiceTime = self._voiceTime - 1
        --print("self._voiceTime", self._voiceTime)
        if self._voiceTime <= 0 then
            self:VoiceEndEvent()
            self:UnFriendVoiceSchedule()
            self._alreadyVoiceClose = true
        end
    end
    self:UnFriendVoiceSchedule()
    self._voiceTime = 15
    self._alreadyVoiceClose = false
    local scheduler = AppDef.Director:getScheduler()
    self.m_schedulerVoiceID = scheduler:scheduleScriptFunc(UpdateCD, 1, false)

    LGameMsg.m_baseMsgWithOne:Change(LUIChatEvent.beginVoiceProgress, self._voiceTime)
    LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)

end

function FriendListUI:UnFriendVoiceSchedule()
    if self.m_schedulerVoiceID then
        AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_schedulerVoiceID)
        self.m_schedulerVoiceID = nil
    end
end

function FriendListUI:getCurChatId()
  -- body
  if self._channel == WhisperChatTab then
    return self._WhisperChatId
  else
    return self._ChatId
  end
end

function FriendListUI:OnAddFriendsBtnButtonClick(sender)
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Social.AddFriendLayer", AppDef.UIType.SecondClassLayer, 1)
    self:SendMsg(LGameMsg.m_initUIMsg)
end

function FriendListUI:RegisterGuide()
    if true then
        return
    end
    --Utils:RegisterGuide(GuideDef.StepId.Guide_SHEJ_2, self._AddFriendsBtn,handler(self, FriendListUI.OnAddFriendsBtnButtonClick), nil, true)
--    dump("RegisterGuide")
end

function FriendListUI:LoadData(id)
    if self._ChatId == id then
        return
    end
    local firendsDataList = LRoleDataMgr.Social:GetFriendData();
    local idx = LRoleDataMgr.Social:FindFriend(id, firendsDataList);
    if idx <= 0 then
        return
    end
    self._ChatId = id;
    local friendData = firendsDataList[idx]
    self:ReLoadChatContent(friendData);
    local qinmidu = string.format(GUITips.RSI_FRIEND_QINMIDU, friendData.qingMiDu)
    self._optExt:setString(qinmidu)
end

function FriendListUI:ShowGmList(pos)

        local function openGmMail()
            LGameMsg.m_baseMsgWithOne:Change(LUIMailEvent.OpenWriteMail, GUITips.RSI_UI_GM_NAME)
            self:SendMsg(LGameMsg.m_baseMsgWithOne)
        end

        local function openGmConnect()
            local msgData = {
                okCallback = OKCallback,
                desc = GUITips.UI_Title_Contact_Info,
                title = GUITips.RSI_GM_CONNECT_TITLE
            }
            LGameMsg.m_baseMsgWithOne:Change(LUIMsgBoxEvent.ShowMsgBox, msgData)
            self:SendMsg(LGameMsg.m_baseMsgWithOne)
        end

        local btndata = {}
        btndata.pos = pos
        table.insert(btndata,{GUITips.RSI_GM_MAIL,openGmMail})
        table.insert(btndata,{GUITips.RSI_GM_CONNECT,openGmConnect})
        LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowCommomBtnList, btndata)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)

        self:toChatState(false)

end

function FriendListUI:ReLoadChatContent(friendData)

    local msgList = friendData.msgList
    self._ChatView:removeAllItems();
    self._celIndex = 0;

    for k = 1, #msgList do
        self:addChatLine(msgList[k])
    end

end

function FriendListUI:addChatLine(msgNode)

--    --print("***********************", msgNode.sendId, self._ChatId, msgNode.revId)
    local myRoleId = LRoleDataMgr.MyHeroInfo.id
    if self._channel == WhisperChatTab then
        if(msgNode.sendId ~= self._WhisperChatId and msgNode.sendId ~= myRoleId) then
            return
        end
    else
        if(msgNode.sendId ~= self._ChatId and msgNode.sendId ~= myRoleId) then
            return
        end
    end
    

    if(self._celIndex >= 25) then
        self._ChatView:removeItem(0)
    end

    local userId = LRoleDataMgr.MyHeroInfo.id
    local isMe = (userId == msgNode.sendId);
    if isMe then
        self:addSelfSpeak(msgNode)
    else
        self:addOtherSpeak(msgNode)
    end    

end

function FriendListUI:addSelfSpeak(msgNode)
  
    if msgNode.ChatType == 2 then
       self:addSoundChat(msgNode)
    else
      self:addSelfTextChat(msgNode)
--      self:addSoundTextChat(msgNode)
    end

--测试代码
--    self:addOtherSoundSpeak(msgNode)

end

function FriendListUI:addSoundChat(msgNode)
  -- body
--  Utils:dump(msgNode)
--  --print("msgNode", msgNode.msg)
  local selfSoundCell = self._mySideSound:clone()
  --头像
  local iconBg = selfSoundCell:getChildByName("IconBg")
  local selfHeadIcon = iconBg:getChildByName("FriendIcon")

  local strHeadImage = AppDef:GetHeroPicFileName(msgNode.sendProf, AppDef.HeadType.HERO_IMAGE_HEAD);
--  selfHeadIcon:loadTexture(strHeadImage, ccui.TextureResType.localType);

  selfHeadIcon:setVisible(false)
  local function LoadImgComplete( tex )
      -- body
      selfHeadIcon:loadTexture(strHeadImage, ccui.TextureResType.localType)
      selfHeadIcon:setVisible(true)
  end
  LGameMsg.m_resMsg:Change(LResEvent.LoadImgSync, strHeadImage, LoadImgComplete)
  self:SendMsg(LGameMsg.m_resMsg)
  self:addAsyImage(strHeadImage)

  --聊天时间
  local descName = selfSoundCell:getChildByName("ChatTime");
  str = os.date("%Y-%m-%d", msgNode.time)
  descName:setString(str)

  --语音按钮
  local contentInfo = json.decode(msgNode.msg, 1)
  local soundBtn = selfSoundCell:getChildByName("SoundBtn")
  local function soundEvent( sender )
    -- body
    local fid = sender:getCallbackName()
    local time = sender.time
    LVoiceDataMgr:downloadVoiceData(fid, time)
  end
  soundBtn:addClickEventListener(soundEvent)
	self:MarkIntaractCObj(soundBtn)
  soundBtn:setCallbackName(contentInfo.fid)
  soundBtn.userObject = contentInfo.time

  --语音时长
  local voiceTime = selfSoundCell:getChildByName("Time")
  voiceTime:setString(contentInfo.time)

  --聊天内容
  local bg = selfSoundCell:getChildByName("ChatBox")
  local descLabel = selfSoundCell:getChildByName("ChatText")
  local chatString = string.format("[N%d][/N]%s", msgNode.sendId, contentInfo.content)

  local newLabel = CCAysLabel:create()
--  newLabel:transToShadowColor(true)
  newLabel:triggleInit(chatString, descLabel:getContentSize(), -130, UICOLOR_GREEN, 20, true, 5)
  newLabel:setAnchorPoint(cc.p(1, 1))
  newLabel:setPosition( cc.p(descLabel:getPositionX() - newLabel:getSize().width, descLabel:getPositionY()));
  newLabel:setName("NewContent")



  --调整背景条的大小
  local width = newLabel:getSize().width + 30;
  local height = newLabel:getSize().height + 22;
  bg:setContentSize(cc.size(width, height));

  selfSoundCell:addChild(newLabel)
  descLabel:removeFromParent()

  --调整cell的大小
  local cellHeight = height + descName:getContentSize().height
  if selfHeadIcon:getContentSize().height > height then
      cellHeight = selfHeadIcon:getContentSize().height + descName:getContentSize().height
  end

  selfSoundCell:setContentSize(cc.size( selfSoundCell:getContentSize().width, cellHeight));

  local soundCellHeight = self._mySideSound:getContentSize().height
  local fixHeight = soundCellHeight - cellHeight
  local spaceHeight = 8;
  iconBg:setPositionY(self._mySoundHeadHeight - fixHeight - spaceHeight)
  descName:setPositionY(self._mySoundTimeHeight - fixHeight - spaceHeight)
  soundBtn:setPositionY(self._mySoundBtnHeight - fixHeight - spaceHeight)
  voiceTime:setPositionY(self._mySoundLengh - fixHeight - spaceHeight)
  bg:setPositionY(self._mySoundChatBgHeight - fixHeight - spaceHeight)
  newLabel:setPositionY(self._mySoundChatTextHeight - fixHeight - spaceHeight)

  self._ChatView:pushBackCustomItem(selfSoundCell)
  self._celIndex =  self._celIndex + 1
  self._ChatView:jumpToBottom()

end


function FriendListUI:addSelfTextChat(msgNode)
  -- body
  local selfChatCell = self._mySide:clone()
    --头像
  local iconBg = selfChatCell:getChildByName("IconBg")

  local selfHeadIcon = iconBg:getChildByName("FriendIcon")
  local strHeadImage = AppDef:GetHeroPicFileName(msgNode.sendProf, AppDef.HeadType.HERO_IMAGE_HEAD);
  selfHeadIcon:loadTexture(strHeadImage, ccui.TextureResType.localType);

  -- local function LoadImgComplete( tex )
  --     -- body
  --     selfHeadIcon:loadTexture(strHeadImage, ccui.TextureResType.localType)
  --     selfHeadIcon:setVisible(true)
  -- end
  -- LGameMsg.m_resMsg:Change(LResEvent.LoadImgSync, strHeadImage, LoadImgComplete)
  -- self:SendMsg(LGameMsg.m_resMsg)
  -- self:addAsyImage(strHeadImage)

  --聊天时间
  local descName = selfChatCell:getChildByName("ChatTime");
  str = os.date("%Y-%m-%d", msgNode.time)
  descName:setString(str)

  --聊天内容
  local bg = selfChatCell:getChildByName("ChatBox")
  local descLabel = selfChatCell:getChildByName("ChatText")
  local chatString = string.format("[N%d][/N]%s", msgNode.sendId, msgNode.msg)

  local newLabel = CCAysLabel:create()
--  newLabel:transToShadowColor(true)
  newLabel:triggleInit(chatString, descLabel:getContentSize(), -130, UICOLOR_GREEN, 20, true, 5)
  newLabel:setAnchorPoint(cc.p(1, 1))
  newLabel:setPosition( cc.p(descLabel:getPositionX() - newLabel:getSize().width, descLabel:getPositionY()));
  newLabel:setName("NewContent")

  --调整背景条的大小
  local width = newLabel:getSize().width + 25;
--  --print("newLabel:getSize().width", newLabel:getSize().width, descLabel:getContentSize().width)
  if newLabel:getSize().width >= descLabel:getContentSize().width - 2 then
    width = newLabel:getSize().width + 60
    newLabel:setPositionX(newLabel:getPositionX() - 30)
  end

  local height = newLabel:getSize().height + 22;
  bg:setContentSize(cc.size(width, height));

  selfChatCell:addChild(newLabel)
  descLabel:removeFromParent()

  --调整cell的大小
  local cellHeight = height + descName:getContentSize().height
  if selfHeadIcon:getContentSize().height > height then
      cellHeight = selfHeadIcon:getContentSize().height + descName:getContentSize().height
  end

  selfChatCell:setContentSize(cc.size( selfChatCell:getContentSize().width, cellHeight));

  local fixHeight = self._mySideSize.height - cellHeight
  local spaceHeight = 8;
  iconBg:setPositionY(self._myBtnHeadHeight - fixHeight - spaceHeight)
  descName:setPositionY(self._myChatTimeHeight - fixHeight - spaceHeight)
  bg:setPositionY(self._myChatBgHeight - fixHeight - spaceHeight)
  newLabel:setPositionY(self._myChatTextHeight - fixHeight - spaceHeight)

  self._ChatView:pushBackCustomItem(selfChatCell)
  self._celIndex = self._celIndex + 1
  self._ChatView:jumpToBottom()

end

function FriendListUI:addOtherSpeak(msgNode)
  if msgNode.ChatType == 2 then
    self:addOtherSoundSpeak(msgNode)
  else
    self:addOtherTextSpeak(msgNode)
  end
end

function FriendListUI:addOtherSoundSpeak( msgNode )
  -- body
--  --print("msgNode", msgNode.msg)
  local otherSoundCell = self._OtherSideSound:clone()
  --头像
  local iconBg = otherSoundCell:getChildByName("IconBg")
  iconBg:setTouchEnabled(true)
  local function headEvent( sender )
    -- body
    local roleId = msgNode.sendId
   
    local userId = LRoleDataMgr.MyHeroInfo.id
    --local teamId = msgNode.sendTeamId
--    --print("roleId = ", roleId)

    if roleId ~= userId then
      local worldPos = sender:getParent():convertToWorldSpace(cc.p(sender:getPositionX(), sender:getPositionY()));
--      --print("ShowFriendCellInfo worldPos", worldPos.x, worldPos.y)
      self.currName=msgNode.sendName
      self.currworldPos=worldPos
      LuaNetSendMsg:ReqPlayerTeamInfo(roleId)

      --self:ShowChatBtnList(worldPos, roleId,teamId);
    end
  end
  iconBg:addClickEventListener(headEvent)
	self:MarkIntaractCObj(iconBg)
  local otherHeadIcon = iconBg:getChildByName("FriendIcon")
  local strHeadImage = AppDef:GetHeroPicFileName(msgNode.sendProf, AppDef.HeadType.HERO_IMAGE_HEAD);

  otherHeadIcon:setVisible(false)
  local function LoadImgComplete( tex )
      -- body
      otherHeadIcon:loadTexture(strHeadImage, ccui.TextureResType.localType)
      otherHeadIcon:setVisible(true)
  end
  LGameMsg.m_resMsg:Change(LResEvent.LoadImgSync, strHeadImage, LoadImgComplete)
  self:SendMsg(LGameMsg.m_resMsg)
  self:addAsyImage(strHeadImage)

--  otherHeadIcon:loadTexture(strHeadImage, ccui.TextureResType.localType);

  --聊天时间
  local descName = otherSoundCell:getChildByName("ChatTime");
  str = os.date("%Y-%m-%d", msgNode.time)
  descName:setString(str)

  --语音按钮
  local contentInfo = json.decode(msgNode.msg, 1)
  local soundBtn = otherSoundCell:getChildByName("SoundBtn")
  local function soundEvent( sender )
    -- body
    local fid = sender:getCallbackName()
    local time = sender.userObject
    LVoiceDataMgr:downloadVoiceData(fid, time)
  end
  soundBtn:addClickEventListener(soundEvent)
	self:MarkIntaractCObj(soundBtn)
  soundBtn:setCallbackName(contentInfo.fid)
  soundBtn.userObject = contentInfo.time

--  --print("contentInfo.time", contentInfo.time, contentInfo.fid, contentInfo.content)

  --语音时长
  local voiceTime = otherSoundCell:getChildByName("Time")
  voiceTime:setString(contentInfo.time)

  --聊天内容
  local bg = otherSoundCell:getChildByName("ChatBox")
  local descLabel = otherSoundCell:getChildByName("ChatText")
  
  local chatString = string.format("[N%d][/N]%s", msgNode.sendId, contentInfo.content)

--  local chatString = "this is test"
  local newLabel = CCAysLabel:create()
--  newLabel:transToShadowColor(true)
  newLabel:triggleInit(chatString, descLabel:getContentSize(), -130, UICOLOR_GREEN, 20, true, 5)
  newLabel:setAnchorPoint(cc.p(0, 1))
  newLabel:setPosition(cc.p(descLabel:getPositionX(), descLabel:getPositionY()));
  newLabel:setName("NewContent")

  --调整背景条的大小
  local width = newLabel:getSize().width + 25;
--  --print("newLabel:getSize().width", newLabel:getSize().width, descLabel:getContentSize().width)
  if newLabel:getSize().width >= descLabel:getContentSize().width - 2 then
    width = newLabel:getSize().width + 60
  end
  local height = newLabel:getSize().height + 22;
  bg:setContentSize(cc.size(width, height));

  otherSoundCell:addChild(newLabel)
  descLabel:removeFromParent()

  --调整cell的大小
  local cellHeight = height + descName:getContentSize().height
  if otherSoundCell:getContentSize().height > height then
      cellHeight = otherSoundCell:getContentSize().height + descName:getContentSize().height
  end

  otherSoundCell:setContentSize(cc.size( otherSoundCell:getContentSize().width, cellHeight));
  local soundCellHeight = self._OtherSideSound:getContentSize().height
  local fixHeight = soundCellHeight - cellHeight
  local spaceHeight = 8;
  iconBg:setPositionY(self._otherSoundHeadHeight - fixHeight - spaceHeight)
  descName:setPositionY(self._otherSoundTimeHeight - fixHeight - spaceHeight)
  soundBtn:setPositionY(self._otherSoundBtnHeight - fixHeight - spaceHeight)
  voiceTime:setPositionY(self._otherSoundLengh - fixHeight - spaceHeight)
  bg:setPositionY(self._otherSoundChatBgHeight - fixHeight - spaceHeight)
  newLabel:setPositionY(self._otherSoundChatTextHeight - fixHeight - spaceHeight)

  self._ChatView:pushBackCustomItem(otherSoundCell)
  self._celIndex =  self._celIndex + 1
  self._ChatView:jumpToBottom()

end

function FriendListUI:addOtherTextSpeak( msgNode )
 
  -- body
  local otherChatCell = self._OtherSide:clone()
    --头像
    local OtherIconBg = otherChatCell:getChildByName("IconBg")
    OtherIconBg:setTouchEnabled(true)
    local function headEvent( sender )
        -- body        
        
        local roleId = msgNode.sendId
        local userId = LRoleDataMgr.MyHeroInfo.id
       
--        --print("roleId = ", roleId)
        if roleId ~= userId then
          local worldPos = sender:getParent():convertToWorldSpace(cc.p(sender:getPositionX(), sender:getPositionY()));
--          --print("ShowFriendCellInfo worldPos", worldPos.x, worldPos.y)
          --self:ShowChatBtnList(worldPos, roleId,teamId);
            self.currName=msgNode.sendName
            self.currworldPos=worldPos
            LuaNetSendMsg:ReqPlayerTeamInfo(roleId)
        end
    end
    OtherIconBg:addClickEventListener(headEvent)
	self:MarkIntaractCObj(OtherIconBg)
    local otherHeadIcon = OtherIconBg:getChildByName("FriendIcon")
    local strHeadImage = AppDef:GetHeroPicFileName(msgNode.sendProf, AppDef.HeadType.HERO_IMAGE_HEAD);
--    otherHeadIcon:loadTexture(strHeadImage, ccui.TextureResType.localType);

    otherHeadIcon:setVisible(false)
    local function LoadImgComplete( tex )
        -- body
        otherHeadIcon:loadTexture(strHeadImage, ccui.TextureResType.localType)
        otherHeadIcon:setVisible(true)
    end
    LGameMsg.m_resMsg:Change(LResEvent.LoadImgSync, strHeadImage, LoadImgComplete)
    self:SendMsg(LGameMsg.m_resMsg)
    self:addAsyImage(strHeadImage)
    
    --发送时间
    local descName = otherChatCell:getChildByName("ChatTime");
    str = os.date("%Y-%m-%d", msgNode.time)
    descName:setString(str)

    --聊天内容
    local bg = otherChatCell:getChildByName("ChatBox")
    local descLabel = otherChatCell:getChildByName("ChatText")
    local chatString = string.format("[N%d][/N]%s", msgNode.sendId, msgNode.msg)
    
    local newLabel = CCAysLabel:create()
--    newLabel:transToShadowColor(true)
    newLabel:triggleInit(chatString, descLabel:getContentSize(), -130, UICOLOR_BROWN, 20, true, 5)
    newLabel:setAnchorPoint(cc.p(0, 1))
    newLabel:setPosition( cc.p(descLabel:getPositionX(), descLabel:getPositionY()));

    newLabel:setName("NewContent")
    otherChatCell:addChild(newLabel)
    descLabel:removeFromParent()

    local width = newLabel:getSize().width + 30;
    local height = newLabel:getSize().height + 22;

    bg:setContentSize(cc.size(width, height));


    --调整cell的大小
    local cellHeight = height + descName:getContentSize().height
    if otherHeadIcon:getContentSize().height > height then
        cellHeight = otherHeadIcon:getContentSize().height + descName:getContentSize().height
    end


    otherChatCell:setContentSize(cc.size( otherChatCell:getContentSize().width, cellHeight));
    local fixHeight = self._mySideSize.height - cellHeight
    local spaceHeight = 8;
    OtherIconBg:setPositionY(self._otherBtnHeadHeight - fixHeight - spaceHeight)
    descName:setPositionY(self._otherChatTimeHeight - fixHeight - spaceHeight)
    bg:setPositionY(self._otherChatBgHeight - fixHeight - spaceHeight)
    newLabel:setPositionY(self._otherChatTextHeight - fixHeight - spaceHeight)

    self._ChatView: pushBackCustomItem(otherChatCell)
    self._celIndex =  self._celIndex + 1
    self._ChatView:jumpToBottom()

end


function FriendListUI:EnableSendMsg(val)
    self._btnSend:setTouchEnabled(val)
    self._btnSend:setBright(val)
end


function FriendListUI:addExpressiona(idx)
    local inputString = self.m_pInputText:getString()
    self.m_pInputText:setString(inputString .. string.format("[E%d]",idx));
end

function FriendListUI:updateBtnStat()
    
    local isWhisperChat = (self._channel == WhisperChatTab)
    self.m_pFriendView:getParent():setVisible(not isWhisperChat)
    self.m_pWhisperView:getParent():setVisible(isWhisperChat)

    self._BtnNameFreind1:setVisible(isWhisperChat)
    self._BtnNameFreind2:setVisible(not isWhisperChat)

    self._BtnNameWas1:setVisible(not isWhisperChat)
    self._BtnNameWas2:setVisible(isWhisperChat)

--更新数据
--[[     
    if self.m_pWhisperTableView then
        self.m_pWhisperTableView:reloadData()
    end
]]

--默认状态
    self:toChatState(false)
    if self._lastSelCellIndex >= 0 then
        local lastSelectCell = self.m_pFriendTableView:cellAtIndex(self._lastSelCellIndex);
        if lastSelectCell then
          local cellChild = lastSelectCell:getChildByTag(123)
          if cellChild then
            cellChild:setBright(true)
            self._lastSelCellIndex = -1
          end
        end
    end

    if self._lastWhisperSelIndex >= 0 then
        local lastWhisperSelectCell = self.m_pWhisperTableView:cellAtIndex(self._lastWhisperSelIndex);
        if lastWhisperSelectCell then
          local cellWhisperChild = lastWhisperSelectCell:getChildByTag(123)
          if cellWhisperChild then
            cellWhisperChild:setBright(true)
            self._lastWhisperSelIndex = -1
          end
        end 
    end

    self._ChatView:removeAllItems();

    self._btnPrivateChat:setBright(not isWhisperChat)
    self._btnFriendChat:setBright(isWhisperChat)

    self._AddFriendsBtn:setVisible(not isWhisperChat)
    self._AddBlacklistBtn:setVisible(not isWhisperChat)
end

function FriendListUI:initLeftView()
  
    if self._channel == WhisperChatTab then
        if(self.m_pWhisperTableView == nil) then
            self:initWhisperTableview()
            if not self._inited then
                LuaNetSendMsg:QueryFriendList();
                self._inited = true
            else
                self:updateHotDot()
                self.m_pWhisperTableView:reloadData()
            end
           
        end
    else
        if(self.m_pFriendTableView == nil) then
            self:initFriendTableView()
            if not self._waperInited then
                LuaNetSendMsg:QueryFriendList();
                self._waperInited = true
            else
                self:updateHotDot()
                self.m_pFriendTableView:reloadData()
            end

        end
    end

    LRoleDataMgr.Social._isInfriend = true
    
end

function FriendListUI:initFriendTableView()
    local tableView = cc.TableView:create(self._listView:getContentSize())
--    --print("width = ".. self.m_pFriendView:getContentSize().width .. "height = " .. self.m_pFriendView:getContentSize().height);
--    --print("width = ".. tableView:getContentSize().width .. "height = " .. tableView:getContentSize().height);
    tableView:setContentSize(self._listView:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(cc.p(0, 0))
    tableView:setPosition(cc.p(0, 0))
    tableView:setDelegate()
    tableView:setSwallowsTouches(true)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self._listView:addChild(tableView)
    

    local function tableCellTouched(sender,cell)
        --print("tableCellTouched", cell:getIdx())
        self:FriendTableCellTouched(cell)
    end

    local function cellSizeForTable(sender,idx)
        local width = self.m_pFriendCell:getContentSize().width
        local height = self.m_pFriendCell:getContentSize().height
--        --print("cellSizeForTable width = "..width .. " cellSizeForTable height = ",height)
        return width, height
    end

    local function tableCellAtIndex(sender, idx)
--        --print("cellSizeForTable idx = ".. idx )
        return self:FriendTableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        local size = #LRoleDataMgr.Social:GetFriendData();
--        --print("numberOfCellsInTableView size = ", size)
        return size
    end

    local function scrollViewDisScroll(view)
        self.m_isDragging = view:isDragging()
    end

    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量

    tableView:registerScriptHandler(scrollViewDisScroll, cc.SCROLLVIEW_SCRIPT_SCROLL)

    self.m_pFriendTableView = tableView
end

function FriendListUI:initRightView()
    self:toChatState(false)
end

function FriendListUI:FriendTableCellTouched(cell)
    
    local ind = cell:getIdx()
    local cellChild = cell:getChildByTag(123)

    local selectRoleID = LRoleDataMgr.Social:GetFriendIdByIndex(ind)
    -- print("selectRoleID = ", selectRoleID, self._ChatId, self._lastSelCellIndex, ind)
    if cellChild:isBright() then
      cellChild:setBright(false)
    end
    
    if self._lastSelCellIndex >= 0 and self._lastSelCellIndex ~= ind then
      local lastSelectCell = self.m_pFriendTableView:cellAtIndex(self._lastSelCellIndex);
      if lastSelectCell then
        local cellChild = lastSelectCell:getChildByTag(123)
        if cellChild then
          cellChild:setBright(true)
        end
      end
    end
  
--     if selectRoleID == 0 then
--         local worldPos = cellChild:getParent():convertToWorldSpace(cc.p(cellChild:getPositionX(), cellChild:getPositionY()));
-- --        --print("ShowFriendCellInfo worldPos", worldPos.x, worldPos.y)
--         self:ShowGmList(worldPos)

--     else
--         self:LoadData(selectRoleID);
--         self:toChatState(true)
--     end

--     --print("tableview touched " , ind , selectRoleID)
--     self._ChatId = selectRoleID
    self._lastSelCellIndex = ind;

    -- cellChild:getChildByName("RedDot"):setVisible(false)
    -- LRoleDataMgr.Social:updateFriendReadMsgData(selectRoleID, false)
    -- self:updateHotDot()
    
end 

function FriendListUI:FriendTableCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pFriendCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(cellChild:getContentSize().width / 2, cellChild:getContentSize().height / 2))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)
        cellChild:setTouchEnabled(false)      
    else
        cellChild = cell:getChildByTag(123)
    end
    self:ShowFriendCellInfo(cellChild, idx,0)
    return cell
end
function FriendListUI:OnCheckBtnButtonClick(sender,idx,TeamId)
    local friendsData = LRoleDataMgr.Social:GetFriendData();
    local oneData = friendsData[idx + 1]
    local friendId = oneData.id
    if self.m_isDragging then
        return
    end

    local function QueryFriendInfoCallback()
       LuaNetSendMsg:QueryOtherPlayer(friendId)
    end

    local function InvateTeamCallback()
      if TeamId > 0 and LRoleDataMgr.MyHeroInfo:IsTeam() == false then
        LuaNetSendMsg:QueryApplyTeam(oneData.teamId)--申请入队()
     --   Utils:ShowScrollTips(string.format(GUITips.UI_FRIEND_TEAM2,oneData.name))
      else
        LuaNetSendMsg:QueryTeamInvite(friendId)--邀请组队()
        
--        Utils:ShowScrollTips(string.format(GUITips.UI_FRIEND_TEAM1,oneData.name))
      end
    end

    local function InvateBpCallback()
        LuaNetSendMsg:QueryFactionInvite(friendId)
    end

    local function getGiftCallback()
        
    end
    local function DelFriendCallback()
        LuaNetSendMsg:QuertDelFriend(friendId)
        LRoleDataMgr.Social:delFriend(friendId);
        local offset = self.m_pFriendTableView:getContentOffset()
        self.m_pFriendTableView:reloadData();
        self.m_pFriendTableView:setContentOffset(offset)
    end

    local function SendMailCallback()
      LGameMsg.m_baseMsgWithOne:Change(LUIMailEvent.OpenWriteMail, oneData.name)
      self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end

    local btndata = {}
    table.insert(btndata,{GUITips.UI_FRIEND_QUERY,QueryFriendInfoCallback})
    if TeamId>0 and LRoleDataMgr.MyHeroInfo:IsTeam() == false then
      table.insert(btndata,{GUITips.UI_FRIEND_INVATETEAM1,InvateTeamCallback})
    else
      table.insert(btndata,{GUITips.UI_FRIEND_INVATETEAM,InvateTeamCallback})
    end
    table.insert(btndata,{GUITips.UI_FRIEND_INVATEBP,InvateBpCallback})
    --        table.insert(btndata,{GUITips.UI_FRIEND_GIFT,getGiftCallback})
    table.insert(btndata,{GUITips.UI_TEAM_DELFRIEND,DelFriendCallback})
    table.insert(btndata,{GUITips.UI_TEAM_SENDMAIL,SendMailCallback})

    local worldPos = sender:getParent():convertToWorldSpace(cc.p(sender:getPositionX(), sender:getPositionY()));
    btndata.pos = worldPos
    LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowCommomBtnList, btndata)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function FriendListUI:ShowFriendCellInfo(cellChild, idx)
    if cellChild == nil then
        return
    end
    -- print("ShowFriendCellInfo",cellChild,"idx",idx);

    local friendsData = LRoleDataMgr.Social:GetFriendData();

    local oneData = friendsData[idx + 1]
    if oneData == nil then
        return
    end
    local friendId = oneData.id
    -- print("friendId = ", friendId)
    cellChild:setBright(true)
    if self._lastSelCellIndex == idx then
        cellChild:setBright(false)
    end
    local infoNode = cellChild:getChildByName("Icon_1");
    -- local imageIcon = cellChild:getChildByName("Image");
    local strHeadImage = AppDef:GetHeroPicFileName(oneData.head, AppDef.HeadType.HERO_IMAGE_HEAD);
    infoNode:getChildByName("Icon"):loadTexture(strHeadImage, ccui.TextureResType.localType)

    local nameLabel = infoNode:getChildByName("Name")
    --GM名字
    local nameStr = oneData.name
    if oneData.id == 0 then
        nameStr = nameStr .. GUITips.RSI_UI_GM_SYSTEMON
    end
    nameLabel:setString(nameStr);

    local offTimeLabel = nameLabel:getChildByName("Time");
    offTimeLabel:setString(Utils:getTimeString(oneData.offSecond))

    local lvLabel = infoNode:getChildByName("LevelNum")
    lvLabel:setString(GUITips.RSI_FACTION_MSG7 .. oneData.level);

    local powerLabel = cellChild:findChildByName("Power/Value");
    local powerValue, isWan = Utils:getNewPowerStr(oneData.fightPower);
    powerLabel:setString(powerValue);
    if isWan == true then
        powerLabel:getChildByName("Wan"):setVisible(true)
        powerLabel:getChildByName("Wan"):setPositionX(powerLabel:getContentSize().width)
    else
        powerLabel:getChildByName("Wan"):setVisible(false)
    end

    if oneData.bpId == 0 then
        cellChild:getChildByName("Group"):setVisible(false);
    else
        cellChild:findChildByName("Group/Name"):setString(oneData.bpName);
    end

    local btnGive = cellChild:getChildByName("Btn_Give");
    self:SetGiftBtnState(btnGive, oneData);

    local function OnSendGiftClicked(sender)
        self:HandleSendGiftClicked(sender)
    end
    btnGive.userData = oneData;
    btnGive:addClickEventListener(OnSendGiftClicked);

    local function OnDetailClicked(sender)
        print("OnDetailClicked")
        LuaNetSendMsg:QueryOtherPlayerInfo(sender.userData.id);
    end
    infoNode:setTouchEnabled(true);
    infoNode.userData = oneData;
    infoNode:addClickEventListener(OnDetailClicked);
--     local function OnCheckButtonClick(sender)
--            self.ClickSender=sender
--            self.ClickIdx=idx
--            LuaNetSendMsg:ReqPlayerTeamInfo(friendId)
--     end
    

--     if cellChild ~= nil then

--         local friendsData = LRoleDataMgr.Social:GetFriendData()
--         local oneData = friendsData[idx + 1]

--         if oneData ~= nil then
            
--             cellChild:setBright(true)
--             if self._lastSelCellIndex == idx then
--               cellChild:setBright(false)
--             end

--             local imageIcon = cellChild:getChildByName("Image")

--             --print("oneData.prof", oneData.prof)
--             local strHeadImage = AppDef:GetHeroPicFileName(oneData.prof, AppDef.HeadType.HERO_IMAGE_HEAD);
-- --GM头像
--             --print("oneData.id = ", oneData.id)
--             if oneData.id == 0 then
--                 strHeadImage = "res2/Monster_Bust/302_tou.png"
--             end

-- --            imageIcon:loadTexture(strHeadImage, ccui.TextureResType.localType)


--             imageIcon:setVisible(false)
--             local function LoadImgComplete( tex )
--                 -- body
--                 imageIcon:loadTexture(strHeadImage, ccui.TextureResType.localType)
--                 imageIcon:setVisible(true)
--             end
--             LGameMsg.m_resMsg:Change(LResEvent.LoadImgSync, strHeadImage, LoadImgComplete)
--             self:SendMsg(LGameMsg.m_resMsg)
--             self:addAsyImage(strHeadImage)


--             local Offline = cellChild:getChildByName("Offline_0")
--             local isonline = oneData.mapId > 0 or oneData.id == 0
--             Offline:setVisible(not isonline)

--             local lv = cellChild:getChildByName("LevelNum")
--             lv:setString(GUITips.Item_Info_Lv .. oneData.level)
--             lv:setVisible(true)

--             local name = cellChild:getChildByName("Name")
--             --GM名字
--             local nameStr = oneData.name
--             if oneData.id == 0 then
--                 nameStr = nameStr .. GUITips.RSI_UI_GM_SYSTEMON
--             end
--             name:setString(nameStr)
            
--             local btn = cellChild:getChildByName("CheckBtn")
--             btn:ignoreContentAdaptWithSize(true)
--     --        btn:setTag(idx + 1)
--             btn:addClickEventListener(OnCheckButtonClick)
-- 			self:MarkIntaractCObj(btn)
--             btn:ignoreContentAdaptWithSize(true)
--             btn:setVisible(true)

--             local pro = cellChild:getChildByName("Career")
--             pro:setString(oneData.profession)
--             pro:setVisible(true)

--             local GoodFeel = cellChild:getChildByName("GoodFeel")
--             local optValTemp = LRoleDataMgr.Social:getQingMiDu(oneData.qingMiDu)
--             local str = string.format("res/UI/ui_shejiao/friend_chenghao_%d.png", optValTemp) 
--             GoodFeel:loadTexture(str, ccui.TextureResType.plistType)

--             --红点
--             local redDot = cellChild:getChildByName("RedDot")
--             redDot:setVisible(oneData.msgUread)

--             if(oneData.id == 0) then
--                 btn:setVisible(false)
--                 pro:setVisible(false)
--                 lv:setVisible(false);
--                 GoodFeel:setVisible(false)
--             end
--         end
--     end
end

function FriendListUI:SetGiftBtnState(btnGive, oneData)
    if oneData:isGiftSended() then
        btnGive:setTouchEnabled(false);
        btnGive:setBright(false);
        btnGive:getChildByName("Text1"):setVisible(false);
        btnGive:getChildByName("Text2"):setVisible(true);
    else
        btnGive:setTouchEnabled(true);
        btnGive:setBright(true);
        btnGive:getChildByName("Text1"):setVisible(true);
        btnGive:getChildByName("Text2"):setVisible(false);
    end
end

function FriendListUI:HandleSendGiftClicked(sender)
    local data = sender.userData;
    if data == nil then
        return
    end
    LuaNetSendMsg:QuerySendGiftToFriend(data.id);
    data.sendFlag = 1;
    self:SetGiftBtnState(sender,data);
end


function FriendListUI:initWhisperTableview()
    local tableView = cc.TableView:create(self.m_pWhisperView:getContentSize())
    --print("width = ".. self.m_pWhisperView:getContentSize().width .. "height = " .. self.m_pWhisperView:getContentSize().height);
    --print("width = ".. tableView:getContentSize().width .. "height = " .. tableView:getContentSize().height);
    tableView:setContentSize(self.m_pWhisperView:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(cc.p(0, 0))
    tableView:setPosition(cc.p(0, 0))
    tableView:setDelegate()
    tableView:setSwallowsTouches(true)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.m_pWhisperView:addChild(tableView)
    
    local function tableCellTouched(sender,cell)
        --print("tableCellTouched".. cell:getIdx())
        self:WhisperTableCellTouched(cell)
    end

    local function cellSizeForTable(sender,idx)
        local width = self.m_pWhisperCell:getContentSize().width
        local height = self.m_pWhisperCell:getContentSize().height
        --print("cellSizeForTable width = "..width .. " cellSizeForTable height = ",height)
        return width, height
    end

    local function tableCellAtIndex(sender, idx)
        --print("cellSizeForTable idx = ".. idx )
        return self:WhisperTableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        local size = #LRoleDataMgr.Social:GetTmpChatList();
        return size
    end

    local function scrollViewDisScroll(view)
        self.m_isDragging = view:isDragging()
    end

    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量
    tableView:registerScriptHandler(scrollViewDisScroll, cc.SCROLLVIEW_SCRIPT_SCROLL)

    self.m_pWhisperTableView = tableView
end


--点击选中处理
function FriendListUI:WhisperTableCellTouched(cell)
    
    local ind = cell:getIdx()
    local cellChild = cell:getChildByTag(123)
    --print("self._lastWhisperSelIndex", self._lastWhisperSelIndex, ind)
    local selectRoleID = self:GetWhisperFriendIdByIndex(ind)

    if cellChild:isBright() then
      cellChild:setBright(false)
    end
    
    if self._lastWhisperSelIndex >= 0 and self._lastWhisperSelIndex ~= ind then
      local lastSelectCell = self.m_pWhisperTableView:cellAtIndex(self._lastWhisperSelIndex);
      if lastSelectCell then
        local cellChild = lastSelectCell:getChildByTag(123)
        if cellChild then
          cellChild:setBright(true)
        end
      end
    end

    if selectRoleID == 0 then
        local worldPos = cellChild:getParent():convertToWorldSpace(cc.p(cellChild:getPositionX(), cellChild:getPositionY()));
--        --print("ShowFriendCellInfo worldPos", worldPos.x, worldPos.y)
        self:ShowGmList(worldPos)

    else

        self:LoadWhisperData(selectRoleID);
        self:toChatState(true)
    end
    
    --print("tableview touched " , ind , selectRoleID)
    self._WhisperChatId = selectRoleID
    self._lastWhisperSelIndex = ind;

    cellChild:getChildByName("RedDot"):setVisible(false)
    LRoleDataMgr.Social:updateTmpReadMsgData(selectRoleID, false)
    self:updateHotDot()
    
end 

function FriendListUI:WhisperTableCellAtIndex(sender, idx)

    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pWhisperCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(cellChild:getContentSize().width / 2, cellChild:getContentSize().height / 2))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)
        cellChild:setTouchEnabled(false)
    else
        cellChild = cell:getChildByTag(123)

    end
    --print("cell idx"..idx)
    self:ShowWhisperCellInfo(cellChild, idx)
    return cell
end

function FriendListUI:ShowWhisperCellInfo(cellChild, idx)

    local function OnCheckBtnButtonClick(sender)
        if self.m_isDragging then
            return
        end
    end

    --print("cell idx"..idx)
    if cellChild ~= nil then
        
        cellChild:setBright(true)
        if self._lastWhisperSelIndex == idx then
          cellChild:setBright(false)
        end

        local friendsData = LRoleDataMgr.Social:GetTmpChatList()
        local oneData = friendsData[idx + 1]
        --print("oneData ****************** oneData.id =", oneData.id)

        if oneData ~= nil then

            local Offline = cellChild:getChildByName("Offline")
            local isonline = oneData.mapId > 0 or oneData.id == 0
            --print("-----------------------------------------------isonline", isonline)
            Offline:setVisible(not isonline)
            
            local imageIcon = cellChild:getChildByName("Image")
            --print("oneData.prof", oneData.prof)
            local strHeadImage = AppDef:GetHeroPicFileName(oneData.prof, AppDef.HeadType.HERO_IMAGE_HEAD);
            --GM头像
            --print("oneData.id = ", oneData.id)
            if oneData.id == 0 then
                strHeadImage = "res2/Monster_Bust/302_tou.png"
            end

            imageIcon:loadTexture(strHeadImage, ccui.TextureResType.localType)
            -- imageIcon:setVisible(false)
            -- local function LoadImgComplete( tex )
            --     -- body
            --     imageIcon:loadTexture(strHeadImage, ccui.TextureResType.localType)
            --     imageIcon:setVisible(true)
            -- end
            -- LGameMsg.m_resMsg:Change(LResEvent.LoadImgSync, strHeadImage, LoadImgComplete)
            -- self:SendMsg(LGameMsg.m_resMsg)
            -- self:addAsyImage(strHeadImage)

            local lv = cellChild:getChildByName("LevelNum")
            lv:setString(GUITips.Item_Info_Lv .. oneData.level)
            lv:setVisible(true)

            local txt = cellChild:getChildByTag(10102)
            if txt then
              txt:removeFromParent()
            end

            local name = cellChild:getChildByName("Name")
            local nameStr = oneData.name
            if oneData.id == 0 then
                nameStr = nameStr .. GUITips.RSI_UI_GM_SYSTEMON
            end
            name:setString(nameStr)

            if oneData.id > 0 then
              local nameLable
              local idx = LRoleDataMgr.Social:FindFriend(oneData.id, LRoleDataMgr.Social:GetFriendData())
              if idx > 0 then
                nameLable = GUITips.RSI_WASPER_FRIEND
              else
                nameLable = GUITips.RSI_WASPER_STRINGER
              end

              local labelMsg = cc.Label:createWithSystemFont(nameLable, AppDef.FNT_NAME, AppDef.UIFONTSIZELB);
              labelMsg:setColor(cc.c3b(0,128,0))
              cellChild:addChild(labelMsg, 3, 10102)



--              labelMsg:enableShadow()
              labelMsg:setAnchorPoint(name:getAnchorPoint())
              labelMsg:setPosition(cc.p(name:getPositionX() + name:getContentSize().width, name:getPositionY()))
            end

            local btn = cellChild:getChildByName("CheckBtn")
    --        btn:setTag(idx + 1)
            btn:ignoreContentAdaptWithSize(true)
            btn:addClickEventListener(OnCheckBtnButtonClick)
			self:MarkIntaractCObj(btn)
            btn:setVisible(true)

            local pro = cellChild:getChildByName("Career")
            pro:setString(oneData.profession)
            pro:setVisible(true)

            local GoodFeel = cellChild:getChildByName("GoodFeel")
            local optValTemp = LRoleDataMgr.Social:getQingMiDu(oneData.qingMiDu)
            --print("optValTemp = ", optValTemp)
            local str = string.format("res/UI/ui_shejiao/friend_chenghao_%d.png", optValTemp) 
            GoodFeel:loadTexture(str, ccui.TextureResType.plistType)

--红点
            local redDot = cellChild:getChildByName("RedDot")
            redDot:setLocalZOrder(3)
            local friendIdx = LRoleDataMgr.Social:FindFriend(oneData.id, LRoleDataMgr.Social:GetFriendData())
            if friendIdx > 0 then
              redDot:setVisible(false)
            else
              redDot:setVisible(oneData.msgUread)
            end

--系统
            if(oneData.id == 0) then
                btn:setVisible(false)
                lv:setVisible(false)
                --GM的头像资源headimg_system.png
                pro:setVisible(false)
                GoodFeel:setVisible(false)
--                local posY = name:getPositionY()
--                name:setPositionY(posY - 30);
            end

        end
    end
end

function FriendListUI:LoadWhisperData(id)
    if self._WhisperChatId == id then
        return
    end

    local firendsDataList = LRoleDataMgr.Social:GetTmpChatList();
    local idx = LRoleDataMgr.Social:FindFriend(id, firendsDataList);
    if idx <= 0 then
        return
    end
    self._WhisperChatId = id;
    local friendData = firendsDataList[idx]
    self:ReLoadChatContent(friendData);
end


function FriendListUI:GetWhisperFriendIdByIndex(idx)
    local friendsData = LRoleDataMgr.Social:GetTmpChatList();
    local oneData = friendsData[idx + 1]
    return oneData.id;
end

function FriendListUI:updateFriendLayer()
    local size = #LRoleDataMgr.Social:GetFriendData();
    if size == 0 then
        self.m_pUILayer:findChildByName("None"):setVisible(true);
        self.m_pUILayer:findChildByName("Friend"):setVisible(false);
        self.m_pUILayer:findChildByName("None/TextBg/Text"):setString(GUITips.RSI_SOCIAL_NoneFriendTip1);
    else
        self.m_pUILayer:findChildByName("None"):setVisible(false);
        self.m_pUILayer:findChildByName("Friend"):setVisible(true);
    end
    

    local offset = self.m_pFriendTableView:getContentOffset()
    LRoleDataMgr.Social:SortFriendData()
    self.m_pFriendTableView:reloadData()
    self.m_pFriendTableView:setContentOffset(offset)
    -- if self._inited then
    --     self.m_pFriendTableView:setContentOffset(offset)
    -- end


    -- self:updateHotDot()
    -- if self._channel == FriendChatTab then
    --     local offset = self.m_pFriendTableView:getContentOffset()
    --     self.m_pFriendTableView:reloadData();
    --     if self._inited then
    --       self.m_pFriendTableView:setContentOffset(offset)
    --     end
    -- else
    --     local offset = self.m_pWhisperTableView:getContentOffset()
    --     self.m_pWhisperTableView:reloadData();
    --     if self._inited then
    --       self.m_pWhisperTableView:setContentOffset(offset)
    --     end
    -- end

    -- if self._turnToPcChat > 0 then
    --     self:addPcTempChat(self._turnToPcChat)
    --     self._turnToPcChat = 0
    -- end

    -- LRoleDataMgr.Social._isInfriend = true
end

function FriendListUI:onExit()
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_SHEJ_2)
    LRoleDataMgr.Social._isInfriend = false
    self:exitEvent()
    Utils:UnbindAsyncImgArr(self._asyLoadImage)
    self:UnFriendVoiceSchedule()
    self:Destory()
end

function FriendListUI:setTurnToPcChat(roleId)
    -- body
    self._turnToPcChat = roleId

    if #LRoleDataMgr.Social:GetFriendData() > 0 then
      if self._turnToPcChat > 0 then
          self:addPcTempChat(self._turnToPcChat)
          self._turnToPcChat = 0
      end
    end

end

function FriendListUI:enableSoundState (enableSound)
    -- body
    self._VoiceBtn:setVisible(not enableSound)
    self._SoundBtn:setVisible(enableSound)
    self.m_pInputText:setVisible(not enableSound)
end

function FriendListUI:ShowChatBtnList(pos, pid,pTeamid,name)
    -- body
    -- local function InvateTeamCallback()
    --     LuaNetSendMsg:QueryTeamInvite(pid)
    -- end
    local function InvateTeamCallback()
      if pTeamid > 0 and LRoleDataMgr.MyHeroInfo:IsTeam() == false then
        LuaNetSendMsg:QueryApplyTeam(pTeamid)--申请入队()
        if name ~= nil then
           Utils:ShowScrollTips(string.format(GUITips.UI_FRIEND_TEAM2, name))
        end
       
      else
        LuaNetSendMsg:QueryTeamInvite(pid)--邀请组队()
        if name ~= nil then
          Utils:ShowScrollTips(string.format(GUITips.UI_FRIEND_TEAM2,name))
        end
      end
    end

    local function queryInfo()
        LuaNetSendMsg:QueryOtherPlayer(pid)
    end

    local function addFriend()
        LuaNetSendMsg:QueryAddFriend(pid)
    end

    local function addToBlackList()
        LuaNetSendMsg:QueryAddBlack(pid)
    end

    local btndata = {}
    if pTeamid>0 and LRoleDataMgr.MyHeroInfo:IsTeam() == false then
          table.insert(btndata,{GUITips.UI_FRIEND_INVATETEAM1,InvateTeamCallback})
    else
          table.insert(btndata,{GUITips.UI_FRIEND_INVATETEAM,InvateTeamCallback})
    end
    table.insert(btndata,{GUITips.UI_FRIEND_QUERY, queryInfo})
    table.insert(btndata,{GUITips.RSI_CHAT_MSG5, addFriend})
    table.insert(btndata,{GUITips.RSI_CHAT_MSG6, addToBlackList})

    btndata.pos = pos

    LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowCommomBtnList, btndata)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

end

function FriendListUI:updateHotDot( ... )
  -- body
  local redDotPri = self._btnPrivateChat:getChildByName("RedDot")
  local isShowPri = LRoleDataMgr.Social:HasWaspChatUnRead()
  --print("FriendListUI:updateHotDot isShowPri", isShowPri)
  redDotPri:setVisible(isShowPri)

  local redChat = self._btnFriendChat:getChildByName("RedDot")
  local isShowChat = LRoleDataMgr.Social:HasFreindChatUnRead()
  --print("FriendListUI:updateHotDot isShowChat", isShowChat)
  redChat:setVisible(isShowChat)

  local show = LRoleDataMgr.Social:IsUnReadMsg()
  LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RedDotState, {2, show})
  self:SendMsg(LGameMsg.m_baseMsgWithOne)

  LRedDotCheckMgr:SocialCheck()

end

function FriendListUI:addAsyImage(filePathKey)
  -- body
  if self:IsImageAlreadyAdd(filePathKey) then
    return
  end

  table.insert(self._asyLoadImage, filePathKey)

end

function FriendListUI:IsImageAlreadyAdd(filePathKey)
  -- body
  for i = 1, #self._asyLoadImage do
    if self._asyLoadImage[i] == filePathKey then
      return true
    end
  end
  return false
end

function FriendListUI:exitEvent( ... )
  -- body
  self.m_pUILayer = nil
  self.m_pFriendView = nil
  self.m_pFriendCell = nil
  self.m_pWhisperView = nil
  self.m_pWhisperCell = nil
  self._channel = nil
  self._celIndex = nil
  self._inited = nil
  self._waperInited = nil
  self._turnToPcChat = nil
  self._lastSelCellIndex = nil
  self._lastWhisperSelIndex = nil

  self._btnPrivateChat = nil
  self._BtnNameFreind1 = nil
  self._BtnNameFreind2 = nil

  --好友
  self._btnFriendChat = nil
  self._BtnNameWas1 = nil
  self._BtnNameWas2 = nil

  --添加好友
  self._AddFriendsBtn = nil
  --黑名单
  self._AddBlacklistBtn = nil

  self._VoicePanel = nil
  self._onState = nil
  self._offState = nil
  self._voiceTxt = nil

  self._ChatView = nil
  self._OtherSide = nil

  self._otherBtnHeadHeight = nil
  self._otherChatTimeHeight = nil
  self._otherChatBgHeight = nil
  self._otherChatTextHeight = nil

  self._OtherSideSound = nil
  self._otherSoundHeadHeight = nil
  self._otherSoundTimeHeight = nil
  self._otherSoundBtnHeight = nil
  self._otherSoundLengh = nil
  self._otherSoundChatBgHeight = nil
  self._otherSoundChatTextHeight = nil


  self._mySide = nil
  self._myBtnHeadHeight = nil
  self._myChatTimeHeight = nil
  self._myChatBgHeight = nil
  self._myChatTextHeight = nil

  self._mySideSound = nil
  self._mySoundHeadHeight = nil
  self._mySoundTimeHeight = nil
  self._mySoundBtnHeight = nil
  self._mySoundLengh = nil
  self._mySoundChatBgHeight = nil
  self._mySoundChatTextHeight = nil

  self._mySideSize = nil
  self._OtherSideSize = nil

  self._GuideImage = nil
  self._Btnbg = nil
  self.m_pInputText = nil

  self._VoiceBtn = nil
  self._SoundBtn = nil
  self._sendSoundBtn = nil
end

return FriendListUI