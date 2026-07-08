--[[
私聊
]]

local ChatPvtUI = {}
ChatPvtUI.__index = ChatPvtUI

local FriendNodeName = "chatFriendNode";
--local this = LTcpSocket
function ChatPvtUI:New(node)
	local o = LUIBase:New()
	setmetatable(o,ChatPvtUI)	
    o:Init(node)
	return o
end

function ChatPvtUI:OpenPvtChat(chatData)
	local ind = self:GetFriendTab(chatData.id);
	if ind <= 0 then
		local friendData = LRoleDataMgr.Social:GetChatFriendData(chatData.id);
		if friendData == nil then
			local ret = LRoleDataMgr.Social:addATmpChatList(chatData)
			if ret == false then
				return
			end
			friendData = LRoleDataMgr.Social:GetChatFriendData(chatData.id);
			if friendData == nil then
				return
			end
			self:RefreshFriendList()
		end
		
		ind = self:CreateFriendTab(friendData)
	end
	self:ChangeTab(ind + 1)
end

function ChatPvtUI:RefreshFriendList()
	local items = self._friendListView:getItems()
	for i=1,#items do
		items[i]:retain();
	    items[i]:removeFromParent();
	    LObjPoolMgr.ReleaseGameObject(FriendNodeName, items[i]);
	    items[i]:release();
	end
	self._friendListView:removeAllItems();
	self:ShowFriendList();
end

function ChatPvtUI:ShowFriendList()
	local size = #LRoleDataMgr.Social:GetTmpChatList();
	for i = 1, size do
		local cellChild = LObjPoolMgr.GetGameObject(FriendNodeName);
		cellChild:retain();
	    cellChild:removeFromParent();
		self._friendListView:pushBackCustomItem(cellChild);
		cellChild:release();
		self:ShowFriendCellInfo(cellChild, i);
	end
end

function ChatPvtUI:Init(node)

    self.m_pUILayer = node

   local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent);
    self:InitData()
    self:InitObjPool();
    
    self:InitControlUI();
    self:InitTouchEvt();
    self:RefreshFriendList();
    self:ShowChatFriendTab();
    -- self:loadData()
    -- self:initControlUI()
    -- self:updateUI()
end

function ChatPvtUI:InitTouchEvt()
	local btn = self.m_pUILayer:findChildByName("DeleTips/DeleBtn");
	local function deleteCurChat()
		self:DeleteFriendChat();
	end
	btn:addClickEventListener(deleteCurChat)

	local function HandleChageTab(sender)
		self:ChangeTab(sender.userData)
	end

	for i = 1, #self._tabArr do
		self._tabArr[i].userData = i
		self._tabArr[i]:addClickEventListener(HandleChageTab);
	end
end

function ChatPvtUI:DeleteFriendChat()
	if self._curTab == 1 then
		return
	end
	self._tabListView:removeChild(self._tabArr[self._curTab]);
	-- self._tabArr[self._curTab]:removeFromParent();
	table.remove(self._tabArr,self._curTab);
	local friendInd = self._curTab - 1;
	table.remove(self._curChatFriends,friendInd);
	

	for i = 1, #self._tabArr do
		self._tabArr[i].userData = i
	end

	if friendInd > #self._curChatFriends then
		self._curTab = 0;
		self:ChangeTab(friendInd);
	else
		local old = self._curTab
		self._curTab = 0;
		self:ChangeTab(old);
	end

	
end

function ChatPvtUI:InitData()
	self.m_isDragging = false;
	self._friendNodeSize = self.m_pUILayer:findChildByName("Item"):getContentSize();
	self._curTab = 0;
	self._curChatMsgNum = 0;
	self._curChatFriends = {}
end

function ChatPvtUI:setData(msgWidth, msgHeight,headHeight,nameHeight,labaHeight,nameHg, bgHeight, textheight)
	self._cellSizeWidth = msgWidth
    self._cellSizeHeight = msgHeight
    self._selfBtnHeadHeight = headHeight
    self._selfNameHeight = nameHeight
    self._iconLabaHg = labaHeight
    self._nameLabaHg = nameHg
    self._selfBgHeight = bgHeight
    self._selfBtnTextH = textheight
end

function ChatPvtUI:ShowChatFriendTab()
	-- for i = 1,#self._curChatFriends do
	-- 	local tabNode = nil
	-- 	if i == 1 then
	-- 		tabNode = self._tabArr[2];
	-- 	else
	-- 		tabNode = self._tabArr[2]:clone();
	-- 	end
	-- end


end

function ChatPvtUI:InitControlUI()
	self._friendListView = self.m_pUILayer:getChildByName("Siliao");
	self._msgListView = self.m_pUILayer:getChildByName("ListView");
	self._msgListView:setVisible(false)

	self._tabNodeCell = self.m_pUILayer:getChildByName("CheckBox_1");
	self._tabNodeCell:setVisible(false);
	self._tabListView = self.m_pUILayer:getChildByName("BtnList");
	self._tabArr = {}
	table.insert(self._tabArr,self.m_pUILayer:findChildByName("BtnList/Add"));
    -- self:CreateFriendList()
end

-- function ChatPvtUI:CreateFriendList()
--     local listView = self.m_pUILayer:getChildByName("Siliao");
--     local tableView = cc.TableView:create(listView:getContentSize())
--     tableView:setContentSize(listView:getContentSize())
--     tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
--     tableView:setAnchorPoint(cc.p(0, 0))
--     tableView:setPosition(cc.p(0, 0))
--     tableView:setDelegate()
--     tableView:setSwallowsTouches(true)
--     tableView:setBounceable(false)
--     tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
--     listView:addChild(tableView)
    

--     local function tableCellTouched(sender,cell)
--         --print("tableCellTouched", cell:getIdx())
--         self:FriendTableCellTouched(cell)
--     end

--     local function cellSizeForTable(sender,idx)
--         local width = self._friendNodeSize.width
--         local height = self._friendNodeSize.height
--         print("cellSizeForTable",width, height)
--         return width, height
--     end

--     local function tableCellAtIndex(sender, idx)
-- --        --print("cellSizeForTable idx = ".. idx )
--         return self:FriendTableCellAtIndex(sender, idx)
--     end

--     local function numberOfCellsInTableView()
--         local size = #LRoleDataMgr.Social:GetFriendData();
-- --        --print("numberOfCellsInTableView size = ", size)
--         return size
--     end

--     local function scrollViewDisScroll(view)
--         self.m_isDragging = view:isDragging()
--     end

--     tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
--     tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
--     tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
--     tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量

--     tableView:registerScriptHandler(scrollViewDisScroll, cc.SCROLLVIEW_SCRIPT_SCROLL)

--     self._friendTableView = tableView
-- end

-- function ChatPvtUI:FriendTableCellAtIndex(sender, idx)
-- 	local cell = sender:dequeueCell()
--     local cellChild
--     if cell == nil then
--         cell = cc.TableViewCell:new()
--         cellChild = LObjPoolMgr.GetGameObject(FriendNodeName)
--         cellChild:setTag(123)
--         cellChild:setPosition(cc.p(0, 0))
--         cellChild:setVisible(true)
--         cellChild:retain()
--         cellChild:removeFromParent()
--         cell:addChild(cellChild)
--         cellChild:release();     
--         cellChild:setVisible(true)
--     else
--         cellChild = cell:getChildByTag(123)
--     end
--     self:ShowFriendCellInfo(cellChild, idx)
--     return cell
-- end

function ChatPvtUI:UpdateFriendRedDot()
	local curFriend = self._curChatFriends[self._curTab - 1];
	local chatListData = LRoleDataMgr.Social:GetTmpChatList();
	local isChange = false
	for i = 1, #chatListData do
		local oneData = chatListData[i];
		local cellChild = self._friendListView:getItem(i- 1);
		if cellChild ~= nil then
			if curFriend and curFriend.id == oneData.id and oneData.msgUread == true then
				oneData.msgUread = false	
				isChange = true
			end
			cellChild:getChildByName("Prompt"):setVisible(oneData.msgUread);
		end
	end
	if isChange then
		Utils:SetRedDotState(RedDotDef.ID.Chat_Private, LRedDotCheckMgr:ChatCheck());
	end
end

function ChatPvtUI:ShowFriendCellInfo(cellChild, idx)
	if cellChild == nil then
        return
    end

    local chatListData = LRoleDataMgr.Social:GetTmpChatList();

    local oneData = chatListData[idx]
    if oneData == nil then
        return
    end
    cellChild:getChildByName("Prompt"):setVisible(oneData.msgUread)
    local friendId = oneData.id
    
    -- cellChild:setBright(true)

    local infoNode = cellChild:getChildByName("Icon_1");
    -- local imageIcon = cellChild:getChildByName("Image");
    local strHeadImage = AppDef:GetHeroPicFileName(oneData.head, AppDef.HeadType.HERO_IMAGE_HEAD);
    infoNode:loadTexture(strHeadImage, ccui.TextureResType.localType)

    local nameLabel = infoNode:getChildByName("Name")
    --GM名字
    local nameStr = oneData.name
    if oneData.id == 0 then
        nameStr = nameStr .. GUITips.RSI_UI_GM_SYSTEMON
	elseif LRoleDataMgr.Social:IsMyFriend(friendId) == false then
		nameStr = nameStr .. GUITips.RSI_WASPER_STRINGER
    end
    nameLabel:setString(nameStr);

    local offTimeLabel = cellChild:getChildByName("Time");
    offTimeLabel:setString(Utils:getTimeString(oneData.offSecond))

    -- local lvLabel = infoNode:getChildByName("LevelNum")
    -- lvLabel:setString(GUITips.RSI_FACTION_MSG7 .. oneData.level);

    -- local powerLabel = cellChild:findChildByName("Power/Value");
    -- powerLabel:setString(oneData.fightPower)
    if oneData.bpId == 0 then
        cellChild:getChildByName("Gangs"):setVisible(false);
    else
    	cellChild:getChildByName("Gangs"):setVisible(true);
        cellChild:findChildByName("Gangs/Value"):setString(oneData.bpName);
    end

    local chatBtn = cellChild:getChildByName("Btn");

    local function OnChatClicked(sender)
        sender:getParent():getChildByName("Prompt"):setVisible(false)
		

        self:AddFriendChat(sender.userData)
    end
    chatBtn.userData = oneData;
    ScriptHandlerMgr:getInstance():removeObjectAllHandlers(chatBtn);
    chatBtn:addClickEventListener(OnChatClicked);

    -- local function OnDetailClicked(sender)
    --     print("OnDetailClicked")
    --     LuaNetSendMsg:QueryOtherPlayerInfo(sender.userData.id);
    -- end
    -- infoNode:setTouchEnabled(true);
    -- infoNode.userData = oneData;
    -- infoNode:addClickEventListener(OnDetailClicked);
end

function ChatPvtUI:GetFriendTab(friendId)
	for i = 1,#self._curChatFriends do
		if self._curChatFriends[i].id == friendId then
			return i
		end
	end
	return 0
end

function ChatPvtUI:CreateFriendTab(friendData)
	local tabNode
	tabNode = self._tabNodeCell:clone();
	tabNode:setVisible(true)
	self._tabListView:pushBackCustomItem(tabNode);
	-- self._tabListView:jumpToPercentHorizontal(100);
	table.insert(self._tabArr,tabNode);
	tabNode:findChildByName("Choose/Text_1"):setString(friendData.name);
	tabNode:getChildByName("Text_2"):setString(friendData.name);
	table.insert(self._curChatFriends,friendData);


	local function HandleChageTab(sender)
		self:ChangeTab(sender.userData)
	end
	tabNode.userData = #self._tabArr
	tabNode:addClickEventListener(HandleChageTab);
	return #self._curChatFriends
end

function ChatPvtUI:SendChatMsg(msgStr)
	if self._curTab <= 1 then
		Utils:ShowScrollTips(GUITips.RSI_CHAT_MSG10);
		return
	end
	local curFriend = self._curChatFriends[self._curTab - 1];
	LuaNetSendMsg:QuerySendPriateMsg(AppDef.ChatChanelType.CCT_PERSIONAL, curFriend.id, msgStr);
end

function ChatPvtUI:getCurChatFriendId(fid)
	if self._curTab <= 1 then
		return 0
	end

	if self._curChatFriends[self._curTab - 1] and self._curChatFriends[self._curTab - 1].id == fid then
		return self._curChatFriends[self._curTab - 1].id
	end
	-- for i = 1,#self._curChatFriends do
	-- 	if self._curChatFriends[i].id == fid then
	-- 		return self._curChatFriends[i].id
	-- 	end
	-- end
	return 0;
end

function ChatPvtUI:AddChatLine(msgNode)

	
	local myRoleId = LRoleDataMgr.MyHeroInfo.id
	print("***********************", msgNode.sendId, myRoleId, msgNode.revId)
    local isMe = (myRoleId == msgNode.sendId);
    local curId = 0;
    if isMe then
    	curId = self:getCurChatFriendId(msgNode.revId);
    else
    	curId = self:getCurChatFriendId(msgNode.sendId);
    end
	print("curId",curId)
	if curId <= 0 then
		return
	end
    
    -- if self._channel == WhisperChatTab then
    --     if(msgNode.sendId ~= self._WhisperChatId and msgNode.sendId ~= myRoleId) then
    --         return
    --     end
    -- else
    --     if(msgNode.sendId ~= self._ChatId and msgNode.sendId ~= myRoleId) then
    --         return
    --     end
    -- end
    

    if self._curChatMsgNum >= 25 then
    	self:PopChatMsg()
    end

    local userId = LRoleDataMgr.MyHeroInfo.id
    local isMe = (userId == msgNode.sendId);
    if isMe then
        self:addSelfSpeak(msgNode)
    else
        self:addOtherSpeak(msgNode)
    end    
end

function ChatPvtUI:PopChatMsg()
	local itemNode = self._msgListView:getItem(0);
	itemNode:retain();
    self._msgListView:removeItem(0);
    LObjPoolMgr.ReleaseGameObject(itemNode:getName(),itemNode);
    itemNode:release();
    self._curChatMsgNum = self._curChatMsgNum - 1
end

function ChatPvtUI:addSelfSpeak(msgNode)
  --   if msgNode.ChatType == 2 then
		-- self:addSoundChat(msgNode)
  --   else
		
  --   end
    self:addSelfTextChat(msgNode)
end

function ChatPvtUI:addOtherSpeak(msgNode)
	self:addOtherTextSpeak(msgNode)
end

function ChatPvtUI:addOtherTextSpeak(msgNode)
	local cellChild = LObjPoolMgr.GetGameObject("chatMsg_otherItem");
	cellChild:retain();
	cellChild:removeFromParent();
	self._msgListView:pushBackCustomItem(cellChild);
	cellChild:release();
	cellChild:setVisible(true)


	local selfChatCell = cellChild
	--头像
	local iconBg = selfChatCell:findChildByName("btn_Head/Icon")
	local strHeadImage = AppDef:GetHeroPicFileName(msgNode.sendProf, AppDef.HeadType.HERO_IMAGE_HEAD);
	iconBg:loadTexture(strHeadImage, ccui.TextureResType.localType);
	local chanelIcon = selfChatCell:getChildByName("Channel");
	chanelIcon:setVisible(false);
	selfChatCell:getChildByName("Icon_laba"):setVisible(false);
	selfChatCell:getChildByName("Name_laba"):setVisible(false);
	selfChatCell:getChildByName("Fu"):setVisible(false);
	local posx = selfChatCell:getChildByName("Channel"):getPositionX();

	--名字
    local newString = nil;
    if msgNode.sendVip > 0 then
       newString  = string.format("[c4]%s%d[/c][N%d]%s[/N]",GUITips.RSI_CHAT_MSG7, msgNode.sendVip, msgNode.sendId, msgNode.sendName);
    else
       newString  = string.format("[N%d]%s[/N]", msgNode.sendId, msgNode.sendName);
    end
    local oldNameLabel = selfChatCell:getChildByName("Name_laba")
    local nameLabel = selfChatCell:getChildByName("NewNameLabel");
    if nameLabel == nil then
    	nameLabel = CCAysLabel:createWithFixedWidth(oldNameLabel:getContentSize().width,20, UICOLOR_GREEN)
		nameLabel:setName("NewNameLabel")
		selfChatCell:addChild(nameLabel)
		nameLabel:setAnchorPoint(cc.p(0, 0))
		oldNameLabel:setVisible(false)
    end
    nameLabel:setString(newString);

    local nameWidth = nameLabel:getSize().width;
    local nameHeight = nameLabel:getSize().height / 2
    nameLabel:setPositionX(chanelIcon:getPositionX());
    -- nameLabel:setPositionY(descName:getPositionY() + nameHeight);
    -- newName:setTag(456)
    -- nameChat:setVisible(false)
    -- nameLaba:setVisible(false)

    local bg = selfChatCell:getChildByName("bg_Content")
    local btnVoice = selfChatCell:getChildByName("btn_Voice");
    local msgLabel = selfChatCell:getChildByName("Text")
    local voiceLabel = selfChatCell:getChildByName("Translate")
    voiceLabel:setVisible(false)
    local descLabel
    if msgNode.ChatType == 2 then
    	--语音聊天
    	descLabel = voiceLabel;
        btnVoice:setVisible(true)
        local contentInfo = json.decode(msgNode.chatContent, 1)
        chatString = string.format("[N%d][/N]%s", msgNode.roleId, contentInfo.content)
        bg:setVisible(false)

        local time = btnVoice:getChildByName("Time")
        time:setString(contentInfo.time .. "s")

        local function playChatVoice(sender)
            -- body
            local fid = sender:getCallbackName()
            local time = sender.userObject
            LVoiceDataMgr:downloadVoiceData(fid, time)
        end
        ScriptHandlerMgr:getInstance():removeObjectAllHandlers(btnVoice);
        btnVoice:addClickEventListener(playChatVoice)
		self:MarkIntaractCObj(btn_Voice)
        btnVoice:setCallbackName(contentInfo.fid)
        btnVoice.userObject = contentInfo.time

    else
    	descLabel = msgLabel;
    	btnVoice:setVisible(false)
    	chatString = string.format("[N%d][/N]%s", msgNode.sendId, msgNode.msg)
    end



	--聊天时间
	-- local descName = selfChatCell:getChildByName("ChatTime");
	-- str = os.date("%Y-%m-%d", msgNode.time)
	-- descName:setString(str)

	--聊天内容
	local newLabel = selfChatCell:getChildByName("NewContent");
	if newLabel == nil then
		newLabel = CCAysLabel:createWithFixedWidth(descLabel:getContentSize().width,20, UICOLOR_GREEN)
		newLabel:setName("NewContent")
		selfChatCell:addChild(newLabel)
		newLabel:setAnchorPoint(cc.p(1, 1))
		descLabel:setVisible(false)
	end
	newLabel:setString(chatString)

	local msgSize = newLabel:getSize()
  	newLabel:setPosition( cc.p(descLabel:getPositionX(), descLabel:getPositionY()));

  	

	--调整背景条的大小
	local width = msgSize.width + 25;
	-- print("newLabel:getSize().width", newLabel:getSize().width, descLabel:getContentSize().width)
	-- if msgSize.width >= descLabel:getContentSize().width then
	-- 	width = msgSize.width + 60
	-- 	newLabel:setPositionX(newLabel:getPositionX() - 30)
	-- end

	local height = newLabel:getSize().height + 22;
	bg:setContentSize(cc.size(width, height));

	

  
  --descLabel:removeFromParent()

  --调整cell的大小
  	local width = newLabel:getSize().width + 30;
    local height = newLabel:getSize().height + 22;

    if msgNode.ChatType == 2 then
        local voiceLabelHeight = btnVoice:getChildByTag(3391):getContentSize().height
        height = height + voiceLabelHeight
        btnVoice:setContentSize(cc.size(width, height))
    -- else
    --     bg:setContentSize(cc.size(width, height));
    end
    
 --   descLabel:removeFromParent()
    
    --调整cell的大小
    selfChatCell:setContentSize(cc.size( selfChatCell:getContentSize().width, height + chanelIcon:getContentSize().height) );
    local fixHeight = self._cellSizeHeight - (height + chanelIcon:getContentSize().height)
    local spaceHeight = 4 + chanelIcon:getContentSize().height / 2

    selfChatCell:getChildByName("btn_Head"):setPositionY(self._selfBtnHeadHeight - fixHeight + spaceHeight)
    -- chanelIcon:setPositionY(self._selfChannelHeight - fixHeight + spaceHeight)
    nameLabel:setPositionY(self._selfNameHeight + nameHeight - fixHeight + spaceHeight)

    
    -- local iconLaba = selfChatCell:getChildByName("Icon_laba")
    -- iconLaba:setPositionY(self._iconLabaHg - fixHeight + spaceHeight)
    -- nameLaba:setPositionY(self._nameLabaHg - fixHeight + spaceHeight)

    -- if msgNode.chanel == AppDef.ChatChanelType.CCT_LABA then
    --     chanelIcon:setVisible(false)
    -- else
    --     iconLaba:setVisible(false)
    -- end


    if msgNode.ChatType == 2 then
    --语音聊天
        local voiceOffSet = 5

        newLabel:setPositionY(self._selfBtnTextH - fixHeight + spaceHeight)
		bg:setPositionY(self._selfBgHeight - fixHeight + spaceHeight)

        -- newLabel:setPositionY(self._selfVoiceTxtH - fixHeight + spaceHeight - voiceOffSet - 5)
        -- btnVoice:setPositionY(self._selfVoiceLable - fixHeight + spaceHeight - voiceOffSet)
        -- local image = btn_Voice:getChildByTag(3391)
        -- image:setPositionY(self._VoiceImageHeight - fixHeight + spaceHeight - voiceOffSet)
        -- local time = btn_Voice:getChildByTag(3392)
        -- time:setPositionY(self._VoiceTimesHeight - fixHeight + spaceHeight - voiceOffSet)

    else
        newLabel:setPositionY(self._selfBtnTextH - fixHeight + spaceHeight)
		bg:setPositionY(self._selfBgHeight - fixHeight + spaceHeight)
    end
    

    cellChild:setContentSize(cc.size(cellChild:getContentSize().width, height + chanelIcon:getContentSize().height + 20))
	self._msgListView:jumpToBottom()
end

function ChatPvtUI:addSelfTextChat(msgNode)
  -- body

  	local cellChild = LObjPoolMgr.GetGameObject("chatMsg_selfItem");
	cellChild:retain();
	cellChild:removeFromParent();
	self._msgListView:pushBackCustomItem(cellChild);
	cellChild:release();
	cellChild:setVisible(true)


	local selfChatCell = cellChild
	--头像
	local iconBg = selfChatCell:findChildByName("btn_Head/Icon")
	local strHeadImage = AppDef:GetHeroPicFileName(msgNode.sendProf, AppDef.HeadType.HERO_IMAGE_HEAD);
	iconBg:loadTexture(strHeadImage, ccui.TextureResType.localType);
	local chanelIcon = selfChatCell:getChildByName("Channel");
	chanelIcon:setVisible(false);
	selfChatCell:getChildByName("Icon_laba"):setVisible(false);
	selfChatCell:getChildByName("Name_laba"):setVisible(false);
	selfChatCell:getChildByName("Fu"):setVisible(false);
	local posx = selfChatCell:getChildByName("Channel"):getPositionX();

	--名字
    local newString = nil;
    if msgNode.sendVip > 0 then
       newString  = string.format("[c4]%s%d[/c][N%d]%s[/N]",GUITips.RSI_CHAT_MSG7, msgNode.sendVip, msgNode.sendId, msgNode.sendName);
    else
       newString  = string.format("[N%d]%s[/N]", msgNode.sendId, msgNode.sendName);
    end
    local oldNameLabel = selfChatCell:getChildByName("Name_laba")
    local nameLabel = selfChatCell:getChildByName("NewNameLabel");
    if nameLabel == nil then
    	nameLabel = CCAysLabel:createWithFixedWidth(oldNameLabel:getContentSize().width,20, UICOLOR_GREEN)
		nameLabel:setName("NewNameLabel")
		selfChatCell:addChild(nameLabel)
		nameLabel:setAnchorPoint(cc.p(0, 0))
		oldNameLabel:setVisible(false)
    end
    nameLabel:setString(newString);

    local nameWidth = nameLabel:getSize().width;
    local nameHeight = nameLabel:getSize().height / 2
    nameLabel:setPositionX(chanelIcon:getPositionX() - nameWidth);
    -- nameLabel:setPositionY(descName:getPositionY() + nameHeight);
    -- newName:setTag(456)
    -- nameChat:setVisible(false)
    -- nameLaba:setVisible(false)

    local bg = selfChatCell:getChildByName("bg_Content")
    local btnVoice = selfChatCell:getChildByName("btn_Voice");
    local msgLabel = selfChatCell:getChildByName("Text")
    local voiceLabel = selfChatCell:getChildByName("Translate")
    voiceLabel:setVisible(false)
    local descLabel
    if msgNode.ChatType == 2 then
    	--语音聊天
    	descLabel = voiceLabel;
        btnVoice:setVisible(true)
        local contentInfo = json.decode(msgNode.chatContent, 1)
        chatString = string.format("[N%d][/N]%s", msgNode.roleId, contentInfo.content)
        bg:setVisible(false)

        local time = btnVoice:getChildByName("Time")
        time:setString(contentInfo.time .. "s")

        local function playChatVoice(sender)
            -- body
            local fid = sender:getCallbackName()
            local time = sender.userObject
            LVoiceDataMgr:downloadVoiceData(fid, time)
        end
        ScriptHandlerMgr:getInstance():removeObjectAllHandlers(btnVoice);
        btnVoice:addClickEventListener(playChatVoice)
		self:MarkIntaractCObj(btn_Voice)
        btnVoice:setCallbackName(contentInfo.fid)
        btnVoice.userObject = contentInfo.time

    else
    	descLabel = msgLabel;
    	btnVoice:setVisible(false)
    	chatString = string.format("[N%d][/N]%s", msgNode.sendId, msgNode.msg)
    end



	--聊天时间
	-- local descName = selfChatCell:getChildByName("ChatTime");
	-- str = os.date("%Y-%m-%d", msgNode.time)
	-- descName:setString(str)

	--聊天内容
	local newLabel = selfChatCell:getChildByName("NewContent");
	if newLabel == nil then
		newLabel = CCAysLabel:createWithFixedWidth(descLabel:getContentSize().width,20, UICOLOR_GREEN)
		newLabel:setName("NewContent")
		selfChatCell:addChild(newLabel)
		newLabel:setAnchorPoint(cc.p(1, 1))
		descLabel:setVisible(false)
	end
	newLabel:setString(chatString)

	local msgSize = newLabel:getSize()
  	newLabel:setPosition( cc.p(descLabel:getPositionX() - msgSize.width, descLabel:getPositionY()));

  	

	--调整背景条的大小
	local width = msgSize.width + 25;
	-- print("newLabel:getSize().width", newLabel:getSize().width, descLabel:getContentSize().width)
	-- if msgSize.width >= descLabel:getContentSize().width then
	-- 	width = msgSize.width + 60
	-- 	newLabel:setPositionX(newLabel:getPositionX() - 30)
	-- end

	local height = newLabel:getSize().height + 22;
	bg:setContentSize(cc.size(width, height));

	

  
  --descLabel:removeFromParent()

  --调整cell的大小
  	local width = newLabel:getSize().width + 30;
    local height = newLabel:getSize().height + 22;

    if msgNode.ChatType == 2 then
        local voiceLabelHeight = btnVoice:getChildByTag(3391):getContentSize().height
        height = height + voiceLabelHeight
        btnVoice:setContentSize(cc.size(width, height))
    -- else
    --     bg:setContentSize(cc.size(width, height));
    end
    
 --   descLabel:removeFromParent()
    
    --调整cell的大小
    selfChatCell:setContentSize(cc.size( selfChatCell:getContentSize().width, height + chanelIcon:getContentSize().height) );
    local fixHeight = self._cellSizeHeight - (height + chanelIcon:getContentSize().height)
    local spaceHeight = 4 + chanelIcon:getContentSize().height / 2

    selfChatCell:getChildByName("btn_Head"):setPositionY(self._selfBtnHeadHeight - fixHeight + spaceHeight)
    -- chanelIcon:setPositionY(self._selfChannelHeight - fixHeight + spaceHeight)
    nameLabel:setPositionY(self._selfNameHeight + nameHeight - fixHeight + spaceHeight)

    
    -- local iconLaba = selfChatCell:getChildByName("Icon_laba")
    -- iconLaba:setPositionY(self._iconLabaHg - fixHeight + spaceHeight)
    -- nameLaba:setPositionY(self._nameLabaHg - fixHeight + spaceHeight)

    -- if msgNode.chanel == AppDef.ChatChanelType.CCT_LABA then
    --     chanelIcon:setVisible(false)
    -- else
    --     iconLaba:setVisible(false)
    -- end


    if msgNode.ChatType == 2 then
    --语音聊天
        local voiceOffSet = 5

        newLabel:setPositionY(self._selfBtnTextH - fixHeight + spaceHeight)
		bg:setPositionY(self._selfBgHeight - fixHeight + spaceHeight)

        -- newLabel:setPositionY(self._selfVoiceTxtH - fixHeight + spaceHeight - voiceOffSet - 5)
        -- btnVoice:setPositionY(self._selfVoiceLable - fixHeight + spaceHeight - voiceOffSet)
        -- local image = btn_Voice:getChildByTag(3391)
        -- image:setPositionY(self._VoiceImageHeight - fixHeight + spaceHeight - voiceOffSet)
        -- local time = btn_Voice:getChildByTag(3392)
        -- time:setPositionY(self._VoiceTimesHeight - fixHeight + spaceHeight - voiceOffSet)

    else
        newLabel:setPositionY(self._selfBtnTextH - fixHeight + spaceHeight)
		bg:setPositionY(self._selfBgHeight - fixHeight + spaceHeight)
    end
    

    cellChild:setContentSize(cc.size(cellChild:getContentSize().width, height + chanelIcon:getContentSize().height + 20))

  -- self._ChatView:pushBackCustomItem(selfChatCell)
  -- self._celIndex = self._celIndex + 1
  self._msgListView:jumpToBottom()

end

function ChatPvtUI:AddFriendChat(friendData)
	local ind = self:GetFriendTab(friendData.id)
	if ind <= 0 then
		ind = self:CreateFriendTab(friendData)
	end
	LRoleDataMgr.Social:updateFriendReadMsgData(friendData.id, false)
	
	self:ChangeTab(ind + 1)
end

function ChatPvtUI:ChangeTab(tab)
	print("ChangeTab",tab, self._curTab,"self._curChatFriends",#self._curChatFriends)
	if self._curTab == tab then
		self._tabListView:jumpToPercentHorizontal(self._curTab * 100 / (#self._curChatFriends + 1));
		return
	end
	self._curTab = tab;
	self:SetTabVisible();
	self._tabListView:jumpToPercentHorizontal(self._curTab * 100 / (#self._curChatFriends + 1));
	if self._curTab == 1 then
		self._msgListView:setVisible(false);
		self._friendListView:setVisible(true)
	else
		self._msgListView:setVisible(true);
		self._friendListView:setVisible(false)
	end

	if self._curTab == 1 then
		return
	end
	-- print("self._curChatFriends",#self._curChatFriends)
	if #self._curChatFriends >= self._curTab - 1 then
		local friendData = self._curChatFriends[self._curTab - 1];
		self:ReLoadChatContent(friendData)
		
	end
end

function ChatPvtUI:ReLoadChatContent(friendData)
	LRoleDataMgr.Social:updateTmpReadMsgData(friendData.id,false)
	Utils:SetRedDotState(RedDotDef.ID.Chat_Private, LRedDotCheckMgr:ChatCheck());
	local items = self._msgListView:getItems()
	for i=1,#items do
		items[i]:retain();
	    items[i]:removeFromParent();
	    LObjPoolMgr.ReleaseGameObject(items[i]:getName(), items[i]);
	    items[i]:release();
	end
	self._msgListView:removeAllItems();

    local msgList = friendData.msgList
    self._curChatMsgNum = 0;

    for k = 1, #msgList do
        self:AddChatLine(msgList[k])
    end

end

function ChatPvtUI:SetTabVisible()
	for i = 1,#self._tabArr do
		local tabNode = self._tabArr[i]
		if i == self._curTab then
			tabNode:setTouchEnabled(false);
			tabNode:getChildByName("Text_2"):setVisible(false)
			tabNode:getChildByName("Choose"):setVisible(true)
		else
			tabNode:setTouchEnabled(true);
			tabNode:getChildByName("Text_2"):setVisible(true)
			tabNode:getChildByName("Choose"):setVisible(false)
		end
	end
	if self._curTab == 1 then
		self.m_pUILayer:getChildByName("DeleTips"):setVisible(false)
	else
		self.m_pUILayer:getChildByName("DeleTips"):setVisible(true)
	end
end

function ChatPvtUI:InitObjPool()
    local msgNode = self.m_pUILayer:findChildByName("Item");

    msgNode:retain();
    msgNode:removeFromParent();
    LObjPoolMgr.CreateGameObjectPool(FriendNodeName, 20, 20, msgNode);
    msgNode:removeFromParent();
end

function ChatPvtUI:onExit()
    self.m_pUILayer = nil
end

return ChatPvtUI