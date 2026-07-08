--[[
lua chat 聊天
]]
require("ObjectPool.LObjPoolMgr")
local MainChatUI = LUIBase:New()
MainChatUI.__index = MainChatUI
--local this = LTcpSocket
local MRI = require("MemoryReferenceInfo")
local worldChannel = 1
local curChannelIndex = 2
local kuafuChannelIndex = 3

local targetPlatform = cc.Application:getInstance():getTargetPlatform()

function MainChatUI:New()
	local o = LUIBase:New()
	setmetatable(o,MainChatUI)	
    o:Init()
	return o
end

--[[
注册消息
]]
function MainChatUI:RegistMsgs()
    self.msgIds = 
    {
        LUISocialEvent.updateFriendLayer,
        LUIChatEvent.addMsg,
        LUIChatEvent.updateTextField,
        LUIChatEvent.showChat,
        LUIChatEvent.addEmotion,
        LUIMapEvent.ChangeMapSuccess, --跳转地图成功
        LUILogicEvent.ChangeScene,    --开始跳转场景
        LUIChatEvent.ShowOrCloseChatPanel,
        LUIChatEvent.intoLeiTaiSai,
        LUIChatEvent.getRoleTeamId,--得到玩家的队伍信息
        LUIGuideEvent.ShowingGuide,
        LUILogicEvent.updateRechargeUIAfterPay, --充值成功后,刷新聊天界面
        LUISocialEvent.addPcChatMsg,
        LUIChatEvent.OpenPrivateChat,
        LUIRedDotEvent.UpdateRedDotState,
    }
    self:RegistSelf(self,self.msgIds)
end


--[[
释放注册UI消息
]]
function MainChatUI:UnRegistMsgs()
    self.msgIds = 
    {
        LUISocialEvent.updateFriendLayer,
        LUIChatEvent.addMsg,
        LUIChatEvent.updateTextField,
        LUIChatEvent.showChat,
        LUIChatEvent.addEmotion,
        LUIMapEvent.ChangeMapSuccess, --跳转地图成功
        LUILogicEvent.ChangeScene,    --开始跳转场景
        LUIChatEvent.ShowOrCloseChatPanel,
        LUIChatEvent.getRoleTeamId,
        LUIGuideEvent.ShowingGuide,
        LUILogicEvent.updateRechargeUIAfterPay,
        LUISocialEvent.addPcChatMsg,
        LUIChatEvent.OpenPrivateChat,
        LUIRedDotEvent.UpdateRedDotState,
    }
--    ------print("MainChatUI:UnRegistMsgs ************************************")
    self:UnRegistSelf(self,self.msgIds)
end

function MainChatUI:ProcessEvent(msg)
    if msg.msgId == LUISocialEvent.updateFriendLayer then
        self:RefreshFriendList()
    elseif msg.msgId == LUISocialEvent.addPcChatMsg then
        self:addPrivateChatMsg(msg.value)
    elseif msg.msgId == LUIChatEvent.addMsg then
        self:addMsgData(msg.value)
    elseif msg.msgId == LUIChatEvent.updateTextField then
        self:ResetSendText();
    elseif msg.msgId == LUIChatEvent.showChat then
--        ------print("LUIChatEvent.showChat ======================================", LUIChatEvent.showChat)
        -- if Utils:CheckModelNotOpened(AppDef.EModuleID.EAID_WORLDCHAT) then
        --     return
        -- end
        self:Show(not self._isShow,msg.value)
    elseif msg.msgId == LUIChatEvent.addEmotion then
        self:addExpressiona(msg.value)
    elseif msg.msgId == LUIMapEvent.ChangeMapSuccess then
        self._isChangingMap = false
    elseif msg.msgId == LUILogicEvent.ChangeScene then
        self._isChangingMap = true
    elseif msg.msgId == LUIChatEvent.ShowOrCloseChatPanel then
        self:Show(Utils:ToBool(msg.value))
    elseif msg.msgId == LUIChatEvent.intoLeiTaiSai then
        if self._ChannelType ~=  AppDef.ChatChanelType.CCT_NEAR then
            self:chanelBtnState(self._curbtn)
            self._ChannelType = AppDef.ChatChanelType.CCT_NEAR
            self:ChangeChanelList(3)
            self:updateSendBtnState(curChannelIndex)
--            self:LoadData(AppDef.ChatChanelType.CCT_NEAR);
        end
    elseif msg.msgId==LUIChatEvent.getRoleTeamId then
       
        if self.CurworldPos ~= nil then
        self:ShowChatBtnList(self.CurworldPos, msg.value.id,msg.value.tID,self.currName)
        self.CurworldPos=nil
        self.currName=nil
        end
    elseif msg.msgId == LUIGuideEvent.ShowingGuide then
        if msg.value and msg.value == GuideDef.StepId.Guide_SJFY then
            self:Show(true, string.format(GUITips.RSI_TASK_SJFY,LRoleDataMgr.MyHeroInfo.name))
        end
    elseif msg.msgId == LUILogicEvent.updateRechargeUIAfterPay then
        self:updateChatUI()
    elseif msg.msgId == LUIChatEvent.OpenPrivateChat then
        self:OpenPvtChat(msg.value)
    elseif msg.msgId == LUIRedDotEvent.UpdateRedDotState then
        self:DealUpdateRedDotState(msg.value)
    end

end

function MainChatUI:OnEnter()
    local function initRedDotState(id)
        local isShow = Utils:GetRedDotState(id)
        self:DealUpdateRedDotState({id=id, isShow=isShow})
    end
    initRedDotState(RedDotDef.ID.Chat_Private)
end

function MainChatUI:DealUpdateRedDotState(data)
    local ind = 0
    if data.id == RedDotDef.ID.Chat_Private then
        self._pvtChatBtn:findChildByName("Prompt"):setVisible(data.isShow);
        if self._isShow then
            self._pvtCtrl:UpdateFriendRedDot()
        end
    end
end

function MainChatUI:OpenPvtChat(chatData)
    self:Show(true)
    if self._ChannelType ~=  AppDef.ChatChanelType.CCT_PERSIONAL then
        self:chanelBtnState(self._pvtChatBtn)
        self._ChannelType = AppDef.ChatChanelType.CCT_PERSIONAL
        self:ChangeChanelList(5)
        self:updateSendBtnState(5)
    end
    if chatData then
        self._pvtCtrl:OpenPvtChat(chatData)
    end
end

function MainChatUI:RefreshFriendList()
    self._pvtCtrl:RefreshFriendList()
end

function MainChatUI:addPrivateChatMsg(data)
    self._pvtCtrl:AddChatLine(data)
end

function MainChatUI:addMsgData(data)
    -- body
    --print("MainChatUI:addMsgData 111111111", #self._ChatList)
    ----print("addMsgData ===", data.chanel, self._ChannelType, AppDef.ChatChanelType.CCT_COMMON)
--    if data.chanel == self._ChannelType or self._ChannelType == AppDef.ChatChanelType.CCT_COMMON then
--        local num = LRoleDataMgr.Chat:getChannelMaxNum(self._ChannelType)
--缓冲池最多200条
        --刚从后台回来,暂停的聊天信息不再处理
        if LRoleDataMgr.m_isEnterIngForeground then
            return
        end

        local num = AppDef.Chat_Msg_Type.CCT_CUR_CHANNEL_All_MSG
        local myRoleId = LRoleDataMgr.MyHeroInfo.id
        if #self._ChatList > num then
            if self._ChatList[1].roleId == myRoleId then
                table.remove(self._ChatList, 2)
            else
                table.remove(self._ChatList, 1)
            end
        end
        self._idIndex = self._idIndex + 1
--防止id越来越大
        if self._idIndex > 1000 then
            self._idIndex = self._idIndex - 1000
        end
        data.id = self._idIndex

--        dump(data, "addMsgData 2222222222222222222222222222222")
--        --print("data.roleId = ", data.roleId, myRoleId)

        if data.roleId == myRoleId then
            table.insert(self._ChatList, 1, data)
        else
            table.insert(self._ChatList, data)
        end

        --print("MainChatUI:addMsgData 22222222222", #self._ChatList)
        local isCurInBottom = self:isCurListViewInBottom()
        if not isCurInBottom then
            self:updateUnReadMsgUI()
        end
--    end
end


function MainChatUI:Init()
    self:CreateUINode("csd/MainChatLayer.csb")
    -- self.m_pUILayer = cc.CSLoader:createNode("csd/MainChatLayer.csb")
    -- self.m_pUILayer:setContentSize(AppDef.frameSize)
    -- ccui.Helper:doLayout(self.m_pUILayer)
    
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:InitData()
    self:AddTouchEvt()

--    self:initChatView();
    -- self.m_pChatTableView:reloadData();
    -- self:ScrollToBottom()
    self._isShow = false;

    self:InitListView()
    self:showChatList(1)

    self.m_pUILayer:setPosition(cc.p(-self._chatWidth,0));

    self._HightInfo = {}

    self:voiceState(false)

    self._testCode = 1

    self._voiceTime = 15

    self._alreadyVoiceClose = false

--起一个更新, 用于新消息提醒隐藏
    self:updateEventCallBack()

--起一个更新,用于增加消息
    self:addMsgTimerCallBack()

    self._idIndex = 0
    self._curAddId = 0

    self._textCode = 0
    self.isClose=false-- 判断点击发送是否关闭
--    self:testAddMsg()
    self:OnEnter()

end


function MainChatUI:initCDTime()
    -- body
    for i=1, 3 do
        self._ChannelCDTimeArr[i] = 0
    end

--    Utils:dump(self._ChannelCDTimeArr)
    self:TimerCallBack()
end

function MainChatUI:onExit()
    self.m_pUILayer = nil
    self._HightInfo = nil
    LVoiceDataMgr._isAutoPlay = false
    self:UnupdateSchedule()
    self:UnAddMsgSchedule()
    self:UnTestAddMsgSchedule()
    self:Destory()
end

function MainChatUI:InitObjPool()
    local msgNode = self.m_pUILayer:findChildByName("MainChatUI/Content/Panel/OtherItem");
    msgNode:retain();
    msgNode:removeFromParent();
    LObjPoolMgr.CreateGameObjectPool("chatMsg_otherItem", 200, 200, msgNode);
    msgNode:release();

    msgNode = self.m_pUILayer:findChildByName("MainChatUI/Content/Panel/SelfItem");
    msgNode:retain();
    msgNode:removeFromParent();
    LObjPoolMgr.CreateGameObjectPool("chatMsg_selfItem", 200, 200, msgNode);
    msgNode:release();

    msgNode = self.m_pUILayer:findChildByName("MainChatUI/Content/Panel/SystemItem");
    msgNode:retain();
    msgNode:removeFromParent();
    LObjPoolMgr.CreateGameObjectPool("chatMsg_systemItem", 200, 200, msgNode);
    msgNode:release();
end

function MainChatUI:InitData()
    self._isChangingMap = false
    self._pvtCtrl = require("View.Chat.ChatPvtUI"):New(self.m_pUILayer:findChildByName("MainChatUI/Content/SiliaoBg"));

    local panel = self.m_pUILayer:getChildByName("MainChatUI")
    local bg = panel:getChildByName("Panel_bg")
    bg:setSwallowTouches(true)

    self._chatWidth = bg:getContentSize().width + 20
    local contentPanel = panel:getChildByName("Content")
    self.m_pChatList = contentPanel:getChildByName("ChatView")

    self.m_pCell = contentPanel:getChildByName("Panel")
    self.m_pCell:setVisible(false)

    self._newMsgButton = contentPanel:getChildByName("Button_1")
    self._newMsgButton:setVisible(false)
    self._newMsgButton:setPositionY(self._newMsgButton:getPositionY() + 3)
    self._Txt = self._newMsgButton:getChildByName("Text_1")
    self._Txt:setString(string.format(GUITips.RSI_GS_TIP_CHAT_UNREAD, 1))

    local function readNewMsg(sender)
        -- body
        if self._ChannelType == AppDef.ChatChanelType.CCT_COMMON then
            self._chatListView[1]:jumpToBottom()
        else
            local addtoChatList = self:getChatListByChannel(self._ChannelType)
            addtoChatList:jumpToBottom()
        end
        self:tooManyMsgReset()
        self._newMsgButton:setVisible(false)
        self._unReadNum = 0
        self._Txt:setString(string.format(GUITips.RSI_GS_TIP_CHAT_UNREAD, 1))
    end
    self._newMsgButton:addClickEventListener(readNewMsg)
	self:MarkIntaractCObj(self._newMsgButton)
    self._pSelfItem = self.m_pCell:getChildByTag(1531)
    self._selfTextContentSize = self._pSelfItem:getChildByTag(1537):getContentSize()
    self._pOtherItem = self.m_pCell:getChildByTag(1527)
    self._otherTextContentSize = self._pOtherItem:getChildByTag(1529):getContentSize()
    self._SysItem = self.m_pCell:getChildByTag(476)
    self._sysContentSize = self._SysItem:getChildByTag(480):getContentSize()

--系统信息Lable
    -- self._calcAsyLabel = CCAysLabel:create()
    -- self._selfChatLabel = CCAysLabel:create()
    -- self._otherChatLabel = CCAysLabel:create()

    self._cellSizeWidth = self.m_pCell:getContentSize().width
    self._cellSizeHeight = self.m_pCell:getContentSize().height


    local selfChatCell = self.m_pCell:getChildByName("SelfItem")
    self._selfBtnHeadHeight = selfChatCell:getChildByName("btn_Head"):getPositionY()
    self._selfChannelHeight = selfChatCell:getChildByName("Channel"):getPositionY()
    self._selfNameHeight = selfChatCell:getChildByName("Name_laba"):getPositionY()
    self._selfBgHeight = selfChatCell:getChildByName("bg_Content"):getPositionY()
    self._selfBtnTextH = selfChatCell:getChildByName("Text"):getPositionY()

    self._selfVoiceTxtH = selfChatCell:getChildByName("Translate"):getPositionY()
    self._selfVoiceLable = selfChatCell:getChildByName("btn_Voice"):getPositionY()
    self._VoiceImageHeight = selfChatCell:getChildByName("btn_Voice"):getChildByName("Image"):getPositionY()
    self._VoiceTimesHeight = selfChatCell:getChildByName("btn_Voice"):getChildByName("Time"):getPositionY()

    self._iconLabaHg = selfChatCell:getChildByName("Icon_laba"):getPositionY()
    self._nameLabaHg =  selfChatCell:getChildByName("Name_laba"):getPositionY()

    self._pvtCtrl:setData(self._cellSizeWidth, self._cellSizeHeight,
        self._selfBtnHeadHeight,self._selfNameHeight, 
        self._iconLabaHg, self._nameLabaHg,
        self._selfBgHeight, self._selfBtnTextH)

    local otherChatCell = self.m_pCell:getChildByName("OtherItem")
    self._otherBtnHeadHeight = otherChatCell:getChildByName("btn_Head"):getPositionY()
    self._otherChannelHeight = otherChatCell:getChildByName("Channel"):getPositionY()
    self._otherNameHeight = otherChatCell:getChildByName("Name_laba"):getPositionY()
    self._otherBgContentHeight = otherChatCell:getChildByName("bg_Content"):getPositionY()
    self._otherTextHeight = otherChatCell:getChildByName("Text"):getPositionY()

    self._otherVoiceTxtH = otherChatCell:getChildByName("Translate"):getPositionY()
    self._otherVoiceLable = otherChatCell:getChildByName("btn_Voice"):getPositionY()
    self._otherVoiceImageHeight = otherChatCell:getChildByName("btn_Voice"):getChildByName("Image"):getPositionY()
    self._otherVoiceTimesHeight = otherChatCell:getChildByName("btn_Voice"):getChildByName("Time"):getPositionY()

    self._otherIconLabaHg = otherChatCell:getChildByName("Icon_laba"):getPositionY()
    self._otherNameLabaHg = otherChatCell:getChildByName("Name_laba"):getPositionY()

    local sysChatCell = self.m_pCell:getChildByName("SystemItem")
    self.m_sysCellSize =  sysChatCell:getContentSize().height

    self._sysChatHeight = sysChatCell:getChildByName("Content"):getPositionY()

    local input = panel:getChildByName("Input")
    input:getChildByName("TextField")
    local pInputTextTemp = input:getChildByName("TextField")
    self._fontSize = pInputTextTemp:getFontSize()
    self._fontName = pInputTextTemp:getFontName()
    -- --print("GameSdk.androidTruePhone ================>", GameSdk.androidTruePhone)
    if GameSdk.androidTruePhone then
        self.m_pInputText = pInputTextTemp
        self.m_pInputText:setCursorEnabled(true)
        self.m_pInputText:setInsertText(true)
        self.m_pInputText:setPlaceHolderColor(AppDef.UIColor.WHITE)
    else
        pInputTextTemp:setVisible(false)
        local MsgBkg = cc.Scale9Sprite:create("res/UI/ui_common/ui_juese_bg_03.png")
        MsgBkg:setVisible(false)
        local sizeText = pInputTextTemp:getContentSize()
        self.m_pInputText = ccui.EditBox:create(cc.size(sizeText.width, sizeText.height + 8), MsgBkg, nil, nil)
        self.m_pInputText:setPosition(pInputTextTemp:getPosition())
        self.m_pInputText:setAnchorPoint(pInputTextTemp:getAnchorPoint())
        input:addChild(self.m_pInputText)
        self.m_pInputText:setPlaceholderFontColor(AppDef.UIColor.WHITE)
        -- self.m_pInputText:setFont(pInputTextTemp:getFontName(), pInputTextTemp:getFontSize())
        self.m_pInputText:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
        self.m_pInputText:setInputFlag(cc.EDITBOX_INPUT_FLAG_INITIAL_CAPS_WORD)
        self.m_pInputText:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
        self.m_pInputText:setMaxLength(50)
        -- self:updateChatUI()
    end

    -- local function textFiledEvent( sender, type )
    --     -- body
    --     if type == ccui.TextFiledEventType.insert_text or type == ccui.TextFiledEventType.delete_backward then
    --     end
    -- end
    -- self.m_pInputText:addEventListener(textFiledEvent)
    

    -- self.m_pInputTextTemp = input:getChildByName("TextField")
    -- self.m_pInputTextTemp:setCursorEnabled(true)
    -- self.m_pInputTextTemp:setVisible(false)

--    self.m_pInputText:setString("聊天测试中,请无视")

    self._btn_Voice = panel:findChildByName("Input/btn_Voice")
    local function showVoiceChatlayer(pTouch, pEvent)
        if pEvent == ccui.TouchEventType.began then
--            self._VoiceWindow:setVisible(true)
            self:VoiceStartEvent()
        end

        if pEvent == ccui.TouchEventType.canceled then
--            self._VoiceWindow:setVisible(false)

            LGameMsg.m_baseMsgWithOne:Change(LUIChatEvent.showVoiceWindow, false)
            LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)

            local bMusicMate = LUserConfigMgr:GetIsMusicClosed()
            if not bMusicMate then
                LGameMsg.m_audioMsg:Change(LAudioEvent.StopSpeakVoice)
                LUIManager:SendMsg(LGameMsg.m_audioMsg)
            end
        end

        if pEvent == ccui.TouchEventType.moved then
--            self._VoiceWindow:setVisible(false)
            if self._alreadyVoiceClose then
                return
            end

            local sender = self._btn_Voice
            if not sender:getRendererClicked():isVisible() then
                LGameMsg.m_baseMsgWithOne:Change(LUIChatEvent.cancelVoiceWindow)
                LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
            else
                LGameMsg.m_baseMsgWithOne:Change(LUIChatEvent.showVoiceWindow, true)
                LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
            end
        end
        
        if pEvent == ccui.TouchEventType.ended then

            if self._alreadyVoiceClose then
                self._alreadyVoiceClose = false
            end
            self:UnVoiceSchedule()
            self:VoiceEndEvent()
        end

    end

    self._btn_Voice:addTouchEventListener(showVoiceChatlayer)
	self:MarkIntaractCObj(self._btn_Voice)
    self.m_CheckBox = panel:findChildByName("Content/CheckBox")
    self.m_CheckBox:setSelected(false)
--    self.m_CheckBox:setVisible(false)
    
    local function OnAutoCheck(sender,evnetType)
        if evnetType == ccui.CheckBoxEventType.selected then
            LVoiceDataMgr._isAutoPlay = true
        elseif evnetType == ccui.CheckBoxEventType.unselected then
            LVoiceDataMgr._isAutoPlay = false
        end
    end
    self.m_CheckBox:addEventListener(OnAutoCheck)

    self._sysTips = panel:findChildByName("Content/Tips")
    self._sysTips:setVisible(false)

    self._pvtChatNode = panel:findChildByName("Content/SiliaoBg")
    self._pvtChatNode:setVisible(false)
    self._pvtDelNode = self._pvtChatNode:getChildByName("DeleTips")
    self._pvtDelNode:setVisible(false)

    self._celIndex = 0;
    self._ChannelType = AppDef.ChatChanelType.CCT_COMMON
    self._ChatList = {}

    self._ChannelCDTimeArr = {}
    self:initCDTime()

--未读邮件的数量
    self._unReadNum = 0


    self:InitObjPool();

end

function MainChatUI:VoiceStartEvent()
    -- body
    LGameMsg.m_baseMsgWithOne:Change(LUIChatEvent.showVoiceWindow, true)
    LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
    self:VoiceTimerCallBack()
    LVoiceDataMgr:startVoice()
    LVoiceDataMgr.ChannelType = self._ChannelType
    LVoiceDataMgr:registerCallBack()
end

function MainChatUI:VoiceEndEvent()
    -- body
    LGameMsg.m_baseMsgWithOne:Change(LUIChatEvent.showVoiceWindow, false)
    LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
    LVoiceDataMgr:endVoice()
end


function MainChatUI:VoiceTimerCallBack()
    local function UpdateCD()
        self._voiceTime = self._voiceTime - 1
--        --print("self._voiceTime", self._voiceTime)
        if self._voiceTime <= 0 then
            self:VoiceEndEvent()
            self:UnVoiceSchedule()
            self._alreadyVoiceClose = true
        end
    end
    self:UnVoiceSchedule()
    self._voiceTime = 15
    self._alreadyVoiceClose = false
    local scheduler = AppDef.Director:getScheduler()
    self.m_schedulerVoiceID = scheduler:scheduleScriptFunc(UpdateCD, 1, false)

    LGameMsg.m_baseMsgWithOne:Change(LUIChatEvent.beginVoiceProgress, self._voiceTime)
    LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)

end

function MainChatUI:UnVoiceSchedule()
    if self.m_schedulerVoiceID then
        AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_schedulerVoiceID)
        self.m_schedulerVoiceID = nil
    end
end

function MainChatUI:calcSysChatHeight(msgNode, idx)

--self._calcAsyLabel
    
    local Content = self._SysItem:getChildByTag(480)
    self._calcAsyLabel = CCAysLabel:create()
    self._calcAsyLabel:triggleInit(msgNode.chatContent, Content:getContentSize(), -130, UICOLOR_BROWN, 22, false, 10)

    local cellHeight = self._calcAsyLabel:getSize().height + 30;
    if self._HightInfo[idx + 1] == nil then
        table.insert(self._HightInfo, idx + 1, cellHeight)
    else 
        self._HightInfo[idx + 1] = cellHeight;
    end

end

function MainChatUI:calcSelfChatHeight(msgNode, idx)

    local chanelIcon = self._pSelfItem:getChildByTag(1534)
    local newString = nil;
    if msgNode.vipLevel > 0 then
    newString  = string.format("[c4]%s%d[/c][N%d]%s[/N]",GUITips.RSI_CHAT_MSG7, msgNode.vipLevel, msgNode.roleId, msgNode.roleName);
    else
        newString  = string.format("[N%d]%s[/N]", msgNode.roleId, msgNode.roleName);
    end
 
    --聊天内容

    local descLabel = self._pSelfItem:getChildByName("Text")

    local chatString = string.format("[N%d][/N]%s", msgNode.roleId, msgNode.chatContent)
    if msgNode.ChatType == 2 then
        descLabel = self._pSelfItem:getChildByName("Translate");
        local contentInfo = json.decode(msgNode.chatContent, 1)
        chatString = string.format("[N%d][/N]%s", msgNode.roleId, contentInfo.content)
    end

    
    self._selfChatLabel = CCAysLabel:create()
    self._selfChatLabel:triggleInit(chatString, descLabel:getContentSize(), -130, UICOLOR_GREEN, 20, true, 5)

    --调整背景条的大小
    local width = self._selfChatLabel:getSize().width + 30;
    local height = self._selfChatLabel:getSize().height + 22;

    local cellHeight = height + chanelIcon:getContentSize().height + 20

    local voiceLabel = self._pSelfItem:getChildByTag(3390):getChildByTag(3391)
    if msgNode.ChatType == 2 then
    --语音聊天
        cellHeight = cellHeight + voiceLabel:getContentSize().height
    end

    ----print("cellHeight", cellHeight)
    
    if self._HightInfo[idx + 1] == nil then
        table.insert(self._HightInfo, idx + 1, cellHeight)
    else 
        self._HightInfo[idx + 1] = cellHeight;
    end

end

function MainChatUI:calcOtherChatHeight(msgNode, idx)

    --频道
    local chanelIcon = self._pOtherItem:getChildByName("Channel");

    --聊天内容
    local descLabel = self._pOtherItem:getChildByName("Text")
    local chatString = string.format("[N%d][/N]%s", msgNode.roleId, msgNode.chatContent)
    
    if msgNode.ChatType == 2 then
        descLabel = self._pOtherItem:getChildByName("Translate");
        local contentInfo = json.decode(msgNode.chatContent, 1)
        chatString = string.format("[N%d][/N]%s", msgNode.roleId, contentInfo.content)
    end

    self._otherChatLabel = CCAysLabel:create()
    self._otherChatLabel:triggleInit(chatString, descLabel:getContentSize(), -130, UICOLOR_BROWN, 20, true, 5)
    local width = self._otherChatLabel:getSize().width + 40;
    local height = self._otherChatLabel:getSize().height + 22;


    local cellHeight = height + chanelIcon:getContentSize().height + 20

    local voiceLabel = self._pOtherItem:getChildByName("btn_Voice"):getChildByName("Image")
    if msgNode.ChatType == 2 then
    --语音聊天
        cellHeight = cellHeight + voiceLabel:getContentSize().height
    end

    if self._HightInfo[idx + 1] == nil then
        table.insert(self._HightInfo, idx + 1, cellHeight)
    else 
        self._HightInfo[idx + 1] = cellHeight;
    end
        
end
    

function MainChatUI:calcHeight(idx)
    local chatData = self._ChatList
    local msgNode = chatData[idx + 1]
--    ------print("MainChatUI:calcHeight msgNode.chanel = ", msgNode.chanel)
    if(msgNode.chanel == AppDef.ChatChanelType.CCT_SYS) then
        self:calcSysChatHeight(msgNode, idx)
    elseif msgNode.chanel == AppDef.ChatChanelType.CCT_BPSYS then
        self:calcSysChatHeight(msgNode, idx)
    else 
        self:ChangeChatChanel(msgNode.chanel);
        local userId = LRoleDataMgr.MyHeroInfo.id
        local isMe = (userId == msgNode.roleId);

        if isMe then
            self:calcSelfChatHeight(msgNode, idx)
        else
            self:calcOtherChatHeight(msgNode, idx)
        end

    end

end

-- function MainChatUI:initChatView()

--     local tableView = cc.TableView:create(self.m_pChatList:getContentSize())
-- --    ------print("width = ".. self.m_pChatList:getContentSize().width .. "height = " .. self.m_pChatList:getContentSize().height);
-- --    ------print("width = ".. tableView:getContentSize().width .. "height = " .. tableView:getContentSize().height);
--     tableView:setContentSize(self.m_pChatList:getContentSize())
--     tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_VERTICAL

--     tableView:setAnchorPoint(cc.p(0, 0))
--     tableView:setPosition(cc.p(0, 0))
--     tableView:setDelegate()
--     tableView:setSwallowsTouches(true)
--     tableView:setBounceable(false)
--     tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_BOTTOMUP)
--     self.m_pChatList:addChild(tableView)

--     local function tableCellTouched(sender,cell)
-- --        ------print("tableCellTouched".. cell:getIdx())
--         self:ChatTableCellTouched(cell)
--     end


--     local function cellSizeForTable(sender,idx)
--         local selfItem = self.m_pCell:getChildByName("SelfItem")
--         local width = selfItem:getContentSize().width
--         local height = selfItem:getContentSize().height
--         self:calcHeight(idx);
--         local cellHeight = self._HightInfo[idx + 1]
--         return width, cellHeight
--     end

--     local function tableCellAtIndex(sender, idx)
--         return self:ChatTableCellAtIndex(sender, idx)
--     end

--     local function numberOfCellsInTableView()
--         local size = #self._ChatList;
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

--     self.m_pChatTableView = tableView
-- end

function MainChatUI:InitListView()
    self._chatListView = {}

    -- local function listViewScrollEvent(sender, evnetType)
    --     -- body
    --     --print("listViewScrollEvent", evnetType)
    -- end

    for i=1, 7 do
        local listView = ccui.ListView:create()
        listView:setDirection(LISTVIEW_DIR_VERTICAL)
        listView:setContentSize(self.m_pChatList:getContentSize())
        listView:setAnchorPoint(cc.p(0, 0))
        listView:setPosition(cc.p(0, 0))
        -- 关闭惯性滑动
        listView:setBounceEnabled(false)
        listView:setSwallowTouches(false)
        -- 设置间距
        listView:setItemsMargin(2)
        -- 隐藏滚动条
        listView:setScrollBarEnabled(false)

--         if i == 1 then
-- --            --print("create listViewScrollEvent")
--             listView:addEventListener(listViewScrollEvent)
--         end
        
        self.m_pChatList:addChild(listView)
        table.insert(self._chatListView, listView)
    end
end


function MainChatUI:updateEventCallBack()
    local function UpdateShc(dt)
--        --print("updateEventCallBack", dt)
        if self._unReadNum == 0 then
            return
        end

        if self._ChannelType == AppDef.ChatChanelType.CCT_COMMON then
            local posBottom = self._chatListView[1]:getInnerContainerPosition()
            if posBottom.y > -10  then
                self:resetReadMsgUI()
            end
        else
            local addtoChatList = self:getChatListByChannel(self._ChannelType)
            local posBottom = addtoChatList:getInnerContainerPosition()
            if posBottom.y > -10  then
                self:resetReadMsgUI()
            end
        end

    end
    self:UnupdateSchedule()
    ----print("RoleDataMgr.MonopolyData.timediff", LRoleDataMgr.MonopolyData.timediff)
    local scheduler =  AppDef.Director:getScheduler()
    self.m_schedulerIDNewMsg = scheduler:scheduleScriptFunc(UpdateShc, 1, false)
end

function MainChatUI:UnupdateSchedule()
    if self.m_schedulerIDNewMsg then
        AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_schedulerIDNewMsg)
        self.m_schedulerIDNewMsg = nil
    end
end

function MainChatUI:showChatList(index)
    -- body
    for i=1, 7 do
        self._chatListView[i]:setVisible(false)
        if i == index then
            self._chatListView[i]:setVisible(true)
        end
    end
end

function MainChatUI:ChatTableCellTouched(cell)
    
    local ind = cell:getIdx()
    local cellChild = cell:getChildByTag(123)
--    ------print("tableview touched " , ind )

end 

-- function MainChatUI:ChatTableCellAtIndex(sender, idx)

--     local cell = sender:dequeueCell()
--     local msgNode = self._ChatList[idx + 1]
--     local cellChild
--     if cell == nil then
--         cell = cc.TableViewCell:new()
--         cellChild = self.m_pCell:clone()
--         cellChild:setTag(123)
--         cellChild:setPosition(cc.p(0, 0))
--         cellChild:setVisible(true)
--         cellChild:setEnabled(true)
--         cell:addChild(cellChild)
--         cellChild:setTouchEnabled(false)
        
--     else
--         cellChild = cell:getChildByTag(123)
--     end
-- --    ------print("cell idx"..idx)
--     self:ShowChatCellInfo(cellChild, idx, msgNode)
--     return cell
-- end
MainChatUI.TestUI = nil
function MainChatUI:Test(stringValue)
    local dumpName
    local function DumpMemory()
        for i = 1,10 do
            collectgarbage("collect")
        end
        local cnt = collectgarbage("count")
        --print(dumpName .. "内存：",cnt)
        MRI.m_cMethods.DumpMemorySnapshot("./", dumpName, -1)
    end

    local function DumpCompare()
        MRI.m_cMethods.DumpMemorySnapshotComparedFile("./", "Compared", -1, 
        "./LuaMemRefInfo-All-[Before].txt", 
        "./LuaMemRefInfo-All-[After].txt")
    end

    local function DumpCompare2()
        
    end
    if stringValue == "dumpA" then
        dumpName = "After"
        -- local action = performWithDelay(self.m_pUILayer,DumpMemory,0.2)
        -- action:retain()
        DumpMemory()
        return true
    elseif stringValue == "dumpB" then
        dumpName = "Before"
        -- local action = performWithDelay(self.m_pUILayer,DumpMemory,0.2)
        -- action:retain()
        DumpMemory()
        return true
    elseif stringValue == "dumpC" then
        -- local action = performWithDelay(self.m_pUILayer,DumpCompare,0.2)
        -- action:retain()
        MRI.m_cMethods.DumpMemorySnapshotComparedFile("./", "Compared", -1, 
        "./LuaMemRefInfo-All-[Before].txt", 
        "./LuaMemRefInfo-All-[After].txt")
        return true
    elseif stringValue == "dump" then
        for i = 1,100 do
            collectgarbage("collect")
        end
        local cnt = collectgarbage("count")
        --print("dump内存：",cnt)
        return true
    elseif stringValue == "openUI" then
        local worldMap = require("View.WorldMap.WorldMapMainUI")
        MainChatUI.TestUI = worldMap:New(1)
        AppDef.CurScene:addChild(MainChatUI.TestUI.m_pUILayer,100)
        return true
    elseif stringValue == "closeUI" then

        if MainChatUI.TestUI then
            MainChatUI.TestUI.m_pUILayer:removeFromParent()
            MainChatUI.TestUI = nil
        end
        package.loaded["View.WorldMap.WorldMapMainUI"] = nil
        return true
    elseif stringValue == "dumpSocket" then
        LuaNetSendMsg:QueryTest()
        return true
    elseif stringValue == "dumpTexture" then
        local size = AppDef.Director:getTextureCache():getCachedTextureInfo()
        --print("TextureSize=",size)
    elseif stringValue == "dumpRoot" then
        performWithDelay(self.m_pUILayer,DumpCompare2,0.2)
        -- local action = performWithDelay(self.m_pUILayer,DumpCompare2,0.2)
        -- action:retain()
        return true
    end
    return false
end

-- function MainChatUI:ShowChatCellInfo(cellChild, idx, msgNode)
-- --    ------print("cell idx"..idx)
--     if cellChild == nil then
--         return
--     end

--     self:addChatLine(cellChild, msgNode)
-- end

function MainChatUI:AddTouchEvt()

    local panel = self.m_pUILayer:getChildByName("MainChatUI")
    local returnBtn = panel:findChildByName("bg/btn_return")
    local function OnReturnButtonClick(sender)
       self:Show(not self._isShow)
    end
    returnBtn:addClickEventListener(OnReturnButtonClick)
	self:MarkIntaractCObj(returnBtn)
    --综合
    local btnZH = panel:findChildByName("Channel/zonghe")
    self._curSelectBtn = btnZH;

    local function OnZHChatButtonClick(sender)
        if self._ChannelType ~=  AppDef.ChatChanelType.CCT_COMMON then
            self:chanelBtnState(sender)
            self._curSelectBtn = btnZH;
            self._ChannelType = AppDef.ChatChanelType.CCT_COMMON
            self:ChangeChanelList(1)
            if LRoleDataMgr.m_bIsCrossServer == true then
                self:updateSendBtnState(kuafuChannelIndex)
            else
                self:updateSendBtnState(worldChannel)
            end
--            self:LoadData(AppDef.ChatChanelType.CCT_COMMON);
        end
    end
    btnZH:addClickEventListener(OnZHChatButtonClick)
	self:MarkIntaractCObj(btnZH)
 --    local kuafu = panel:getChildByName("Channel"):getChildByName("kuafu")
 --    local function kuaFuEvent( sender )
 --        -- body
 --        self:chanelBtnState(sender)
 --        self._ChannelType = AppDef.ChatChanelType.CCT_KUAFU
 --        self:ChangeChanelList(7)
 --        self:updateSendBtnState(kuafuChannelIndex)        
 --    end
 --    kuafu:addClickEventListener(kuaFuEvent)
	-- self:MarkIntaractCObj(kuafu)
     --世界
    local btnWorld = panel:findChildByName("Channel/shijie")
    local function OnWorldChatButtonClick(sender)
        if self._ChannelType ~=  AppDef.ChatChanelType.CCT_WORLD then
            self:chanelBtnState(sender)
            self._ChannelType = AppDef.ChatChanelType.CCT_WORLD
            self:ChangeChanelList(2)
            self:updateSendBtnState(worldChannel)
--            self:LoadData(AppDef.ChatChanelType.CCT_WORLD);
        end
        
    end
    btnWorld:addClickEventListener(OnWorldChatButtonClick)
	self:MarkIntaractCObj(btnWorld)
    --当前
    local btnCur = panel:findChildByName("Channel/dangqian")
    self._curbtn = btnCur
    local function OnCurChatButtonClick(sender)
        if self._ChannelType ~=  AppDef.ChatChanelType.CCT_NEAR then
            self:chanelBtnState(sender)
            self._ChannelType = AppDef.ChatChanelType.CCT_NEAR
            self:ChangeChanelList(3)
            self:updateSendBtnState(curChannelIndex)
--            self:LoadData(AppDef.ChatChanelType.CCT_NEAR);
        end
       
    end
    btnCur:addClickEventListener(OnCurChatButtonClick)
	self:MarkIntaractCObj(btnCur)
    self._curbtn:setVisible(false)
    --帮派
    local btnBP = panel:findChildByName("Channel/bangpai")
    local function OnBpChatButtonClick(sender)
        if self._ChannelType ~=  AppDef.ChatChanelType.CCT_FACTION then
            self:chanelBtnState(sender)
            self._ChannelType = AppDef.ChatChanelType.CCT_FACTION
            self:ChangeChanelList(4)
            self:updateSendBtnState(4)
--            self:LoadData(AppDef.ChatChanelType.CCT_FACTION);
        end
    end
    btnBP:addClickEventListener(OnBpChatButtonClick)
	self:MarkIntaractCObj(btnBP)
    --队伍
    local btnDW = panel:findChildByName("Channel/duiwu")
    local function OnDWChatButtonClick(sender)
        if self._ChannelType ~=  AppDef.ChatChanelType.CCT_TEAM then
            self:chanelBtnState(sender)
            self._ChannelType = AppDef.ChatChanelType.CCT_TEAM
            self:ChangeChanelList(5)
            self:updateSendBtnState(5)
--            self:LoadData(AppDef.ChatChanelType.CCT_TEAM);
        end
    end
    btnDW:addClickEventListener(OnDWChatButtonClick)
	self:MarkIntaractCObj(btnDW)
    btnDW:setVisible(false)

    --私聊
    self._pvtChatBtn = panel:findChildByName("Channel/siliao")
    local btnSL = self._pvtChatBtn
    local function OnSLChatButtonClick(sender)
        if self._ChannelType ~=  AppDef.ChatChanelType.CCT_PERSIONAL then
            self:chanelBtnState(sender)
            self._ChannelType = AppDef.ChatChanelType.CCT_PERSIONAL
            self:ChangeChanelList(5)
            self:updateSendBtnState(5)
--            self:LoadData(AppDef.ChatChanelType.CCT_TEAM);
        end
    end
    btnSL:addClickEventListener(OnSLChatButtonClick)
    self:MarkIntaractCObj(btnSL)

    -- local isRechargeEnough = info.totalRecharge >= AppDef.Chat_Msg_Type.CCT_CHAT_RECHARGE_LIMITE
    -- if not isRechargeEnough then
    -- end

    --系统
    local btnXT = panel:findChildByName("Channel/xitong")
    local function OnXTChatButtonClick(sender)
        if self._ChannelType ~=  AppDef.ChatChanelType.CCT_SYS then
            self:chanelBtnState(sender)
            self._ChannelType = AppDef.ChatChanelType.CCT_SYS
            self:ChangeChanelList(6)
--            self:LoadData(AppDef.ChatChanelType.CCT_SYS);
        end
    end
    btnXT:addClickEventListener(OnXTChatButtonClick)
	self:MarkIntaractCObj(btnXT)
    --表情
    local btnFace = panel:findChildByName("Input/btn_Face")
    self._btnFace = btnFace
    local function OnFaceChatButtonClick(sender)
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUIInBattle, "Chat.ChatEmotionLayer", AppDef.UIType.PopWindow)
        self:SendMsg(LGameMsg.m_initUIMsg)

        if not GameSdk.androidTruePhone then
            self.m_pInputText:touchDownAction(self.m_pInputText, ccui.TouchEventType.ended)
        end
    end
    btnFace:addClickEventListener(OnFaceChatButtonClick)
	self:MarkIntaractCObj(btnFace)
    --语音
    local btnMac = panel:findChildByName("Input/btn_Mike")
    self._btnMac = btnMac
    local function OnMacChatButtonClick(sender)
        self:voiceState(not self._isVoiceChat)
    end
    btnMac:addClickEventListener(OnMacChatButtonClick)
	self:MarkIntaractCObj(btnMac)

     --发送
    self._btnSend = panel:findChildByName("Input/btn_Send")
    self._btnSend:addClickEventListener(handler(self, MainChatUI.OnSendChatButtonClick))
	self:MarkIntaractCObj(self._btnSend)
    self._sendText = self._btnSend:getChildByName("Text")
    --self:RegisterGuide()
end

function MainChatUI:OnSendChatButtonClick(sender)
    local stringValue = self:getSendString()
   -- --print("OnSendChatButtonClick -----------", stringValue)
    if self:Test(stringValue) then
        return
    end

    --取消世界聊天等级的限制
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EAID_WORLDCHAT) then
        return
    end



    if not self._isVoiceChat then
        local string = self:getSendString()
        local sendType = self._ChannelType
        --在跨服界面，综合频道发送的是跨服消息
        if self._ChannelType == AppDef.ChatChanelType.CCT_COMMON then
            if LRoleDataMgr.m_bIsCrossServer == true then
                sendType = AppDef.ChatChanelType.CCT_KUAFU
            end
        end
        if Utils:FilterAdLimitedMsg(string) == true then
            if AppDef.ChatChanelType.CCT_FACTION == sendType and LRoleDataMgr.MyHeroInfo.FactionId == 0 then
                local errorMsg = GUITips.RSI_FACTION_MSG214
                LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,errorMsg)
                self:SendMsg(LGameMsg.m_scrollTipsMsg)
                return
            end
            if AppDef.ChatChanelType.CCT_TEAM == sendType and LRoleDataMgr.MyHeroInfo.TeamId == 0 then
                local errorMsg = GUITips.UI_Team_No
                LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,errorMsg)
                self:SendMsg(LGameMsg.m_scrollTipsMsg)
                return
            end
            --添加一条消息
            local msg = LChatMsgNode:New()
            msg.chanel = sendType
            msg.roleId = LRoleDataMgr.MyHeroInfo.id
            msg.roleName = LRoleDataMgr.MyHeroInfo.name
            msg.vipLevel = LRoleDataMgr.MyHeroInfo.vipLevel
            msg.head =  LRoleDataMgr.MyHeroInfo.head
            msg.sex =  LRoleDataMgr.MyHeroInfo.sex
            msg.chatContent = string
            LRoleDataMgr.Chat:AddChatMsg(msg)

            --    通知增加一条消息
            LGameMsg.m_netDealMsg:Change(LUIChatEvent.addMsg, msg)
            self:SendMsg(LGameMsg.m_netDealMsg)
        else
            if self._ChannelType == AppDef.ChatChanelType.CCT_PERSIONAL then
                self._pvtCtrl:SendChatMsg(string);
            else
                LuaNetSendMsg:QuerySendChatMsg(sendType, string);
            end
            
        end
        if string.len(string) > 0 then
         -- self:TimerCallBack();
           -- --print("self._ChannelType =", self._ChannelType)
            if self._ChannelType == AppDef.ChatChanelType.CCT_COMMON then
                if LRoleDataMgr.m_bIsCrossServer == true then
                    self._ChannelCDTimeArr[kuafuChannelIndex] = AppDef.Chat_Msg_Type.CCT_WORLD_CHANNEL_KUAFU_CD
                    self:updateSendBtnState(kuafuChannelIndex)
                else
                    self._ChannelCDTimeArr[worldChannel] = self:getWORLDCHANNELCD()
                    self:updateSendBtnState(worldChannel)
                end
            elseif self._ChannelType == AppDef.ChatChanelType.CCT_WORLD  then
                self._ChannelCDTimeArr[worldChannel] = self:getWORLDCHANNELCD()
                self:updateSendBtnState(worldChannel)
            elseif self._ChannelType == AppDef.ChatChanelType.CCT_NEAR then
                self._ChannelCDTimeArr[curChannelIndex] = AppDef.Chat_Msg_Type.CCT_CUR_CHANNEL_CD
                self:updateSendBtnState(curChannelIndex)
            elseif self._ChannelType == AppDef.ChatChanelType.CCT_KUAFU then
                self._ChannelCDTimeArr[kuafuChannelIndex] = AppDef.Chat_Msg_Type.CCT_WORLD_CHANNEL_KUAFU_CD
                self:updateSendBtnState(kuafuChannelIndex)
            end
        end
    end
    self:ResetSendText()
    if self.isClose==true then
     self:Show(not self._isShow)
     self.isClose=false
    end
end

function MainChatUI:getWORLDCHANNELCD( ... )
    -- body
    
    local info = LRoleDataMgr.MyHeroInfo.MyVIPInfo

    -- if info.vipLevel > 0 then
    --     return AppDef.Chat_Msg_Type.CCT_WORLD_CHANNEL_CD
    -- end

    -- local myLevel = LRoleDataMgr.MyHeroInfo.level
    -- --print("myLevel =", myLevel)
    -- local cd = AppDef.Chat_Msg_Type.CCT_WORLD_CHANNEL_CD_2
    -- if myLevel >= 30 and myLevel <= 34 then
    --     cd = AppDef.Chat_Msg_Type.CCT_WORLD_CHANNEL_CD_1
    -- elseif myLevel > 34 then
    --     cd = AppDef.Chat_Msg_Type.CCT_WORLD_CHANNEL_CD
    -- end
    -- return cd
    return 5
end

--updateBtnState
function MainChatUI:chanelBtnState( sender )
    -- body
    local choose = sender:getChildByName("choose")
    choose:setVisible(true)

    local lastChoose = self._curSelectBtn:getChildByName("choose")
    lastChoose:setVisible(false)



    self._curSelectBtn = sender

    if self._curSelectBtn == self._pvtChatBtn then
        self._pvtChatBtn:findChildByName("Prompt"):setVisible(false)
    else
        self:OnEnter();
    end

    
end

--切换频道
function MainChatUI:ChangeChanelList(index)
    -- body
    self:showChatList(index)
    self:ChangeChatChanel(self._ChannelType)
    LVoiceDataMgr:ChangeChannelEvent(self._ChannelType)
end

function MainChatUI:voiceState( b )
    -- body

--记录当前是否是语音
    LRoleDataMgr.Chat._IsVoiceClick = b
    self._isVoiceChat = b
    if not b then
        self._btn_Voice:setVisible(false)
        self.m_pInputText:setVisible(true)
        if self._ChannelCDTimeArr[worldChannel] < 1 then
            self._btnSend:setTouchEnabled(true)
            self._btnSend:setBright(true)
        end
    else
        self._btn_Voice:setVisible(true)
        self.m_pInputText:setVisible(false)

        self._btnSend:setTouchEnabled(false)
        self._btnSend:setBright(false)
    end

end

function MainChatUI:Show(b,value)
    
    if value~=nil then
         self.isClose=true
         local panel = self.m_pUILayer:getChildByName("MainChatUI")
         local btnWorld = panel:getChildByName("Channel"):getChildByName("shijie")
            if self._ChannelType ~=  AppDef.ChatChanelType.CCT_WORLD then
            local lastChoose = self._curSelectBtn:getChildByName("choose")
            lastChoose:setVisible(false)

            self._curSelectBtn = btnWorld;
            local choose = self._curSelectBtn:getChildByName("choose")
            choose:setVisible(true)

            self._ChannelType = AppDef.ChatChanelType.CCT_WORLD
            self:ChangeChanelList(2)
            self:updateSendBtnState(worldChannel)
--            self:LoadData(AppDef.ChatChanelType.CCT_WORLD);
            end
--            self:LoadData(AppDef.ChatChanelType.CCT_WORLD);   
    end
    self.m_pInputText:setText(value)
    if(self._isShow == b) then
        return
    end
    self._isShow = b
    if(not b) then

        if self.m_pUILayer:getPositionX() - 10  >  -self._chatWidth and  self.m_pUILayer:getPositionX() + 10 < -5 then
            return
        end
        local action = cc.MoveTo:create( 0.3, cc.p(-self._chatWidth, 0))
        self.m_pUILayer:runAction(action)
        LVoiceDataMgr._isAutoPlay = false

        local listView = self:getCurListView()
        if listView ~= nil then
            self:tooManyMsgReset()
            listView:jumpToBottom()
        end

    else

        if self.m_pUILayer:getPositionX() - 10 > -self._chatWidth and self.m_pUILayer:getPositionX() + 10 < -5 then
            return
        end
        local arr = {}
        table.insert(arr, cc.MoveTo:create( 0.3, cc.p(-5, 0)))
        --table.insert(arr, cc.CallFunc:create(handler(self, MainChatUI.CheckGuide)))
        local action = cc.Sequence:create(arr)
        self.m_pUILayer:runAction(action);

        local isSelect = self.m_CheckBox:isSelected()
--        --print("isSelect *******************", isSelect)
        LVoiceDataMgr._isAutoPlay = isSelect

    end

    if self._isShow then
        self._pvtCtrl:UpdateFriendRedDot()
    end
end

function MainChatUI:updateChatUI(isShow)
    -- body
    local info = LRoleDataMgr.MyHeroInfo.MyVIPInfo
    if not GameSdk.androidTruePhone then
        self.m_pInputText:setPlaceholderFont(self._fontName, self._fontSize)
    end
    self.m_pInputText:setPlaceHolder(GUITips.RSI_CHAT_MSG8)
    self.m_pInputText:setTouchEnabled(true)
    
    self._btnSend:setTouchEnabled(true)
    self._btnSend:setBright(true)
    self._btnMac:setTouchEnabled(true)
    self._btnMac:setBright(true)
    self._btnFace:setTouchEnabled(true)
    self._btnFace:setBright(true)
end

function MainChatUI:createSelfCell(cellChild, msgNode)

    -- body
    local selfChatCell = cellChild
    selfChatCell:setVisible(true)

    --头像
    local selfBtnHead = selfChatCell:getChildByTag(1532)
    ----print("selfBtnHead", selfBtnHead)

--    selfBtnHead:ignoreContentAdaptWithSize(false)
    selfBtnHead:setScale(0.62)
    local selfHeadIcon = selfBtnHead:getChildByTag(1533)
    selfHeadIcon:setScale(1.6)

    local strHeadImage = AppDef:GetHeroPicFileName(msgNode.head, AppDef.HeadType.HERO_IMAGE_HEAD_ROUND);
    selfHeadIcon:loadTexture(strHeadImage, ccui.TextureResType.localType);

    --频道
    local strChanelIcon = AppDef:getChannelIcon(msgNode.chanel)
    local chanelIcon = selfChatCell:getChildByTag(1534)
    if msgNode.channel ~= AppDef.ChatChanelType.CCT_COMMON and msgNode.channel ~= AppDef.ChatChanelType.CCT_WORLD then
        chanelIcon:loadTexture(strChanelIcon, ccui.TextureResType.plistType);
    end
    
    --名字
    local newString = nil;
    if msgNode.vipLevel > 0 then
       newString  = string.format("[c4]%s%d[/c][N%d]%s[/N]",GUITips.RSI_CHAT_MSG7, msgNode.vipLevel, msgNode.roleId, msgNode.roleName);
    else
       newString  = string.format("[N%d]%s[/N]", msgNode.roleId, msgNode.roleName);
    end

    local oldName = selfChatCell:getChildByTag(456)
    local newName
    if oldName ~= nil then
        newName = oldName
        newName:triggleInit(newString, cc.size(230, 26), -130, UICOLOR_BROWN, 21, true, 10)
    else
        newName = CCAysLabel:create()
        newName:triggleInit(newString, cc.size(230, 26), -130, UICOLOR_BROWN, 21, true, 10)
        
        selfChatCell:addChild(newName)
    end

    local descName 
    local nameLaba = selfChatCell:getChildByName("Name_laba")
    local nameChat = selfChatCell:getChildByTag(1535)
    if msgNode.chanel == AppDef.ChatChanelType.CCT_LABA then
       descName = nameLaba
    else
        descName = nameChat
    end

    newName:setAnchorPoint(cc.p(0, 0))
    local nameWidth = newName:getSize().width;
    local nameHeight = newName:getSize().height / 2
    newName:setPositionX(descName:getPositionX() - nameWidth);
    newName:setPositionY(descName:getPositionY() + nameHeight);
    newName:setTag(456)
    nameChat:setVisible(false)
    nameLaba:setVisible(false)

--    descName:removeFromParent()

    --聊天内容
    local bg = selfChatCell:getChildByTag(1536)
    local descLabel = selfChatCell:getChildByTag(1537)
    local chatString;
    local btn_Voice = selfChatCell:getChildByTag(3390)

    if msgNode.ChatType == 2 then

        btn_Voice:setVisible(true)
        descLabel = selfChatCell:getChildByTag(3393)
        descLabel:setVisible(false)
        local contentInfo = json.decode(msgNode.chatContent, 1)
        chatString = string.format("[N%d][/N]%s", msgNode.roleId, contentInfo.content)
        bg:setVisible(false)

        local time = btn_Voice:getChildByName("Time")
        time:setString(contentInfo.time .. "s")

        local function playChatVoice(sender)
            -- body
            local fid = sender:getCallbackName()
            local time = sender.userObject
            LVoiceDataMgr:downloadVoiceData(fid, time)
        end
        ScriptHandlerMgr:getInstance():removeObjectAllHandlers(btn_Voice);
        btn_Voice:addClickEventListener(playChatVoice)
		self:MarkIntaractCObj(btn_Voice)
        btn_Voice:setCallbackName(contentInfo.fid)
        btn_Voice.userObject = contentInfo.time

    else
        btn_Voice:setVisible(false)
        chatString = string.format("[N%d][/N]%s", msgNode.roleId, msgNode.chatContent)
        bg:setVisible(true)

        selfChatCell:getChildByTag(3393):setVisible(false)
    end

    
    local oldContent = selfChatCell:getChildByTag(789)
    local newLabel
    if oldContent ~= nil then
        newLabel = oldContent
        newLabel:triggleInit(chatString, self._selfTextContentSize, -130, UICOLOR_GREEN, 20, true, 5)
    else
        newLabel = CCAysLabel:create()
        newLabel:triggleInit(chatString, self._selfTextContentSize, -130, UICOLOR_GREEN, 20, true, 5)
        selfChatCell:addChild(newLabel)
    end

    newLabel:setAnchorPoint(cc.p(1,1))
    newLabel:setPosition( cc.p(descLabel:getPositionX() - newLabel:getSize().width, descLabel:getPositionY()));
    newLabel:setTag(789)


    local function contentEvent()
        -- body
        local worldPos = newLabel:getParent():convertToWorldSpace(cc.p(newLabel:getPositionX(), newLabel:getPositionY()));
        local worldPosAdjust = cc.p(worldPos.x + newLabel:getSize().width / 4, worldPos.y + 80)
        local userId = LRoleDataMgr.MyHeroInfo.id
        ------print("contentEvent", userId)
       
        LuaNetSendMsg:QueryApplyTeam(userId)--申请入队()
       
--        self:showContentBtnList(worldPosAdjust, userId);
    end
    newLabel:registerScriptTapHandler(contentEvent)

    --调整背景条的大小
    local width = newLabel:getSize().width + 30;
    local height = newLabel:getSize().height + 22;

    if msgNode.ChatType == 2 then
        local voiceLabelHeight = btn_Voice:getChildByTag(3391):getContentSize().height
        height = height + voiceLabelHeight
        btn_Voice:setContentSize(cc.size(width, height))
    else
        bg:setContentSize(cc.size(width, height));
    end
    
 --   descLabel:removeFromParent()
    
    --调整cell的大小
    selfChatCell:setContentSize(cc.size( selfChatCell:getContentSize().width, height + chanelIcon:getContentSize().height) );
    local fixHeight = self._cellSizeHeight - (height + chanelIcon:getContentSize().height)
    local spaceHeight = 4 + chanelIcon:getContentSize().height / 2
    selfBtnHead:setPositionY(self._selfBtnHeadHeight - fixHeight + spaceHeight)
    chanelIcon:setPositionY(self._selfChannelHeight - fixHeight + spaceHeight)
    newName:setPositionY(self._selfNameHeight + nameHeight - fixHeight + spaceHeight)

    local iconLaba = selfChatCell:getChildByName("Icon_laba")
    iconLaba:setPositionY(self._iconLabaHg - fixHeight + spaceHeight)
    nameLaba:setPositionY(self._nameLabaHg - fixHeight + spaceHeight)

    if msgNode.chanel == AppDef.ChatChanelType.CCT_LABA then
        chanelIcon:setVisible(false)
    else
        iconLaba:setVisible(false)
    end    

    if msgNode.ChatType == 2 then
    --语音聊天
        local voiceOffSet = 5
        newLabel:setPositionY(self._selfVoiceTxtH - fixHeight + spaceHeight - voiceOffSet - 5)
        btn_Voice:setPositionY(self._selfVoiceLable - fixHeight + spaceHeight - voiceOffSet)
        local image = btn_Voice:getChildByTag(3391)
        image:setPositionY(self._VoiceImageHeight - fixHeight + spaceHeight - voiceOffSet)
        local time = btn_Voice:getChildByTag(3392)
        time:setPositionY(self._VoiceTimesHeight - fixHeight + spaceHeight - voiceOffSet)

    else
        newLabel:setPositionY(self._selfBtnTextH - fixHeight + spaceHeight)
        bg:setPositionY(self._selfBgHeight - fixHeight + spaceHeight)
    end

    cellChild:setContentSize(cc.size(cellChild:getContentSize().width, height + chanelIcon:getContentSize().height + 20))

    return selfChatCell
end

function MainChatUI:addSelfSpeak(msgNode)
    --print("addSelfSpeakaddSelfSpeakaddSelfSpeak")

    local cellChild = LObjPoolMgr.GetGameObject("chatMsg_selfItem");
    cellChild:retain();
    cellChild:removeFromParent();
    self._chatListView[1]:pushBackCustomItem(cellChild);
    cellChild:release();

   local selfChatCell = self:createSelfCell(cellChild, msgNode)
 --综合   
    local maxNum = LRoleDataMgr.Chat:getChannelMaxNum(AppDef.ChatChanelType.CCT_COMMON)
    local comomNum  = #self._chatListView[1]:getItems()
    if comomNum > maxNum then
        self:PopChatItem(1);
        -- self._chatListView[1]:removeItem(0)
    end

    local isCommonListViewInBottom = self:getListViewIsInBottom(self._chatListView[1])
    -- self._chatListView[1]:pushBackCustomItem(selfChatCell)
    self._celIndex =  self._celIndex + 1
 --   self:CommomListViewNewMsg(isCommonListViewInBottom)
    self._chatListView[1]:jumpToBottom()
    --print("msgNode.chanel",msgNode.chanel)
    -- dump(msgNode,"msgNode")
    local maxNum = LRoleDataMgr.Chat:getChannelMaxNum(msgNode.chanel)

    local chatInd = self:getChatListIndByChannel(msgNode.chanel)
    local addtoChatList = self:getChatListByChannel(msgNode.chanel)
    local num = #addtoChatList:getItems()
    if num > maxNum then
        self:PopChatItem(chatInd);
    end

    local isCurListViewInBottom = self:getListViewIsInBottom(addtoChatList)

    local aOtherCell = LObjPoolMgr.GetGameObject("chatMsg_selfItem");
    aOtherCell:retain();
    aOtherCell:removeFromParent();
    addtoChatList:pushBackCustomItem(aOtherCell);
    aOtherCell:release();


    local aOtherCell = self:createSelfCell(aOtherCell, msgNode) 
    addtoChatList:jumpToBottom()
    self:resetReadMsgUI()

--判断是否要滚屏
--    self:curListViewNewMsg(msgNode.chanel, isCurListViewInBottom, addtoChatList)

end

function MainChatUI:CommomListViewNewMsg(isCommonListViewInBottom)
    -- body
--    --print("isCommonListViewInBottom ************", isCommonListViewInBottom, self._ChannelType)
    if self._ChannelType == AppDef.ChatChanelType.CCT_COMMON then
        if isCommonListViewInBottom then
            self._chatListView[1]:jumpToBottom()
        else
--            self:updateUnReadMsgUI()
        end
    else
        self._chatListView[1]:jumpToBottom()
    end
end

function MainChatUI:curListViewNewMsg(msgChanel, isCurListViewInBottom, addtoChatList)
    -- body
--    --print("curListViewNewMsg", msgChanel, isCurListViewInBottom, self._ChannelType)
    if msgChanel == self._ChannelType then
        if isCurListViewInBottom then
            addtoChatList:jumpToBottom()
        else
--            self:updateUnReadMsgUI()
        end
    else
        addtoChatList:jumpToBottom()
    end
end

function MainChatUI:updateUnReadMsgUI()
    -- body
    self._unReadNum = self._unReadNum + 1
    self._Txt:setString(string.format(GUITips.RSI_GS_TIP_CHAT_UNREAD, self._unReadNum))
    if not self._newMsgButton:isVisible() then
        self._newMsgButton:setVisible(true)
    end
end

function MainChatUI:resetReadMsgUI()
    self._unReadNum = 0
    if self._newMsgButton:isVisible() then
        self._newMsgButton:setVisible(false)
        self._Txt:setString(string.format(GUITips.RSI_GS_TIP_CHAT_UNREAD, 1))
    end
end

function MainChatUI:getChatListIndByChannel(ChannelType)
    -- body
    local index = 1
    if ChannelType == AppDef.ChatChanelType.CCT_COMMON then
        index = 2
    elseif ChannelType == AppDef.ChatChanelType.CCT_WORLD then
        index = 2
    elseif ChannelType == AppDef.ChatChanelType.CCT_NEAR then
        index = 3
    elseif ChannelType == AppDef.ChatChanelType.CCT_FACTION or ChannelType == AppDef.ChatChanelType.CCT_BPSYS then
        index = 4
    elseif ChannelType == AppDef.ChatChanelType.CCT_TEAM then
        index = 5
    elseif ChannelType == AppDef.ChatChanelType.CCT_SYS then
        index = 6
    elseif ChannelType == AppDef.ChatChanelType.CCT_KUAFU or ChannelType == AppDef.ChatChanelType.CCT_LABA then
        index = 7
    end
    return index
end

function MainChatUI:getChatListByChannel(ChannelType)
    -- body
    local index = self:getChatListIndByChannel(ChannelType)
    return self._chatListView[index]
end

function MainChatUI:getCurListView( ... )
    -- body
    if self._ChannelType == AppDef.ChatChanelType.CCT_COMMON then
        return self._chatListView[1]
    else
        return self:getChatListByChannel(self._ChannelType)
    end
end

function MainChatUI:addOtherSpeak(msgNode)

--综合
    local maxNum = LRoleDataMgr.Chat:getChannelMaxNum(AppDef.ChatChanelType.CCT_COMMON)
    local comomNum  = #self._chatListView[1]:getItems()
    if comomNum > maxNum then
        self:PopChatItem(1);
    end

    local cellChild = LObjPoolMgr.GetGameObject("chatMsg_otherItem");
    cellChild:retain();
    cellChild:removeFromParent();
    self._chatListView[1]:pushBackCustomItem(cellChild);
    cellChild:release();

    local otherChatCell  = self:createOtherCell(cellChild, msgNode)

    local isCommonListViewInBottom = self:getListViewIsInBottom(self._chatListView[1])
    
--判断是否要滚屏
    self:CommomListViewNewMsg(isCommonListViewInBottom)
    self._celIndex =  self._celIndex + 1

    local maxNum = LRoleDataMgr.Chat:getChannelMaxNum(msgNode.chanel)

    local chatInd = self:getChatListIndByChannel(msgNode.chanel)
    local addtoChatList = self:getChatListByChannel(msgNode.chanel)
    local num = #addtoChatList:getItems()
    if num > maxNum then
        self:PopChatItem(chatInd);
    end

    local isCurListViewInBottom = self:getListViewIsInBottom(addtoChatList)
    cellChild = LObjPoolMgr.GetGameObject("chatMsg_otherItem");
    cellChild:retain();
    cellChild:removeFromParent();
    addtoChatList:pushBackCustomItem(cellChild);
    cellChild:release();

    local anotherChatCell = self:createOtherCell(cellChild, msgNode)
--判断是否要滚屏
    self:curListViewNewMsg(msgNode.chanel, isCurListViewInBottom, addtoChatList)

end

function MainChatUI:isCurListViewInBottom( ... )
    -- body
    local curListView = self:getCurListView()
    return self:getListViewIsInBottom(curListView)
end

function MainChatUI:createOtherCell(cellChild, msgNode)
    -- body
    local otherChatCell = cellChild
    otherChatCell:setVisible(true)

    --头像
    local otherBtnHead = otherChatCell:getChildByName("btn_Head")

    otherBtnHead:setScale(0.62);

    local function ClickHeadIcon(sender)
        --print("ClickHeadIconClickHeadIcon")
        -- body
        local roleId = sender.userObject
        local userId = LRoleDataMgr.MyHeroInfo.id
        --print("roleId",roleId,"userId",userId)
        if roleId ~= userId then
            self.CurworldPos = sender:getParent():convertToWorldSpace(cc.p(sender:getPositionX(), sender:getPositionY()));
            ------print("ShowFriendCellInfo worldPos", worldPos.x, worldPos.y)
            self.currName=msgNode.roleName
            -- LuaNetSendMsg:ReqPlayerTeamInfo(roleId)
            self:ShowChatBtnList(worldPos, roleId);
        end
    end
    ScriptHandlerMgr:getInstance():removeObjectAllHandlers(otherBtnHead);
    otherBtnHead:addClickEventListener(ClickHeadIcon);
	--self:MarkIntaractCObj(otherBtnHead)
    otherBtnHead.userObject = msgNode.roleId

    local otherHeadIcon = otherBtnHead:getChildByName("Icon")
    otherHeadIcon:setScale(1.6)

    local strHeadImage = AppDef:GetHeroPicFileName(msgNode.head, AppDef.HeadType.HERO_IMAGE_HEAD_ROUND);
    otherHeadIcon:loadTexture(strHeadImage, ccui.TextureResType.localType);
    
    --频道
    local strChanelIcon = AppDef:getChannelIcon(msgNode.chanel)
    local chanelIcon = otherChatCell:getChildByName("Channel");
    if msgNode.channel ~= AppDef.ChatChanelType.CCT_COMMON and msgNode.channel ~= AppDef.ChatChanelType.CCT_WORLD then
        chanelIcon:loadTexture(strChanelIcon, ccui.TextureResType.plistType)
    end
    
     --名字
    local descName 
    local otherNameLaba = otherChatCell:getChildByName("Icon_laba")
    local otherName = otherChatCell:getChildByName("Name_laba")
    local namePosx
    if msgNode.chanel == AppDef.ChatChanelType.CCT_LABA then
       descName = otherNameLaba
       namePosx = otherNameLaba:getPositionX() + otherNameLaba:getContentSize().width
    else
        descName = otherName
        namePosx = chanelIcon:getPositionX() + chanelIcon:getContentSize().width
    end
    local newString = nil;
    if msgNode.vipLevel > 0 then
       newString  = string.format("[c4]%s%d[/c][N%d]%s[/N]",GUITips.RSI_CHAT_MSG7, msgNode.vipLevel, msgNode.roleId, msgNode.roleName);
    else
        newString  = string.format("[N%d]%s[/N]", msgNode.roleId, msgNode.roleName);
    end

    local oldName = otherChatCell:getChildByTag(456)
    local newName
    if oldName ~= nil then
        newName = oldName
        newName:setString(newString)
    else
        newName = CCAysLabel:createWithFixedWidth(230,21, UICOLOR_BROWN)
--    newName:transToShadowColor(true)
        newName:setString(newString)
        newName:setContentSize(descName:getContentSize());
        otherChatCell:addChild(newName)
    end

    newName:setAnchorPoint(cc.p(0, 0.5))
    newName:setPositionX(namePosx);
    local nameHeight = descName:getContentSize().height
    newName:setPositionY(descName:getPositionY() + nameHeight);
    newName:setTag(456);
    otherNameLaba:setVisible(false)
    otherName:setVisible(false)
 --   descName:removeFromParent()

    --聊天内容
    local bg = otherChatCell:getChildByName("bg_Content")
    local descLabel = otherChatCell:getChildByName("Text")
    local chatString = string.format("[N%d][/N]%s", msgNode.roleId, msgNode.chatContent)
    
    local btn_Voice = otherChatCell:getChildByName("btn_Voice")
    if msgNode.ChatType == 2 then
        btn_Voice:setVisible(true)

        descLabel = otherChatCell:getChildByName("Translate")
        descLabel:setVisible(false)
        local contentInfo = json.decode(msgNode.chatContent, 1)
        chatString = string.format("[N%d][/N]%s", msgNode.roleId, contentInfo.content)
        bg:setVisible(false)

        local time = btn_Voice:getChildByName("Time")
        time:setString(contentInfo.time .. "s")

        local function playChatVoice(sender)
            -- body
            local fid = sender:getCallbackName()
            local time = sender.userObject
            LVoiceDataMgr:downloadVoiceData(fid, time)
        end
        ScriptHandlerMgr:getInstance():removeObjectAllHandlers(btn_Voice);
        btn_Voice:addClickEventListener(playChatVoice)
		--self:MarkIntaractCObj(btn_Voice)
        btn_Voice:setCallbackName(contentInfo.fid)
        btn_Voice.userObject = contentInfo.time

    else
        btn_Voice:setVisible(false)
        --------print("msgNode.chatContent", msgNode.chatContent)
        chatString = string.format("[N%d][/N]%s", msgNode.roleId, msgNode.chatContent)
        bg:setVisible(true)
        otherChatCell:getChildByName("Translate"):setVisible(false)
    end

    local oldContent = otherChatCell:getChildByTag(789)
    local newLabel 
    if oldContent ~= nil then
        newLabel = oldContent
        newLabel:triggleInit(chatString, self._otherTextContentSize, -130, UICOLOR_BROWN, 20, true, 5)
    else
        newLabel = CCAysLabel:create()
        newLabel:triggleInit(chatString, self._otherTextContentSize, -130, UICOLOR_BROWN, 20, true, 5)
        otherChatCell:addChild(newLabel)
    end

    newLabel:setAnchorPoint(cc.p(0,1))
    newLabel:setPosition(descLabel:getPosition());
    newLabel:setTag(789)

    local function contentEvent()
        -- body
        local worldPos = newLabel:getParent():convertToWorldSpace(cc.p(newLabel:getPositionX(), newLabel:getPositionY()));
        local worldPosAdjust = cc.p(worldPos.x + newLabel:getSize().width / 4, worldPos.y)
        local teamInfo = self:getTeamId(msgNode.chatContent);
        ------print("contentEvent", tonumber(teamInfo))
        LuaNetSendMsg:QueryApplyTeam(tonumber(teamInfo))--申请入队()
        Utils:ShowScrollTips(string.format(GUITips.UI_FRIEND_TEAM2,msgNode.roleName))
--        self:showContentBtnList(worldPosAdjust, teamInfo);
    end
    newLabel:registerScriptTapHandler(contentEvent)

 --   descLabel:removeFromParent()

    local width = newLabel:getSize().width + 40;
    local height = newLabel:getSize().height + 22;
    local oldBgHeight = bg:getContentSize().height;
    
    local changeHeight = oldBgHeight - height;

    if msgNode.ChatType == 2 then
        local voiceLabelHeight = btn_Voice:getChildByName("Image"):getContentSize().height
        height = height + voiceLabelHeight
        btn_Voice:setContentSize(cc.size(width, height))
    else
        bg:setContentSize(cc.size(width, height));
    end

    --调整cell的大小
    otherChatCell:setContentSize(cc.size( otherChatCell:getContentSize().width, height + chanelIcon:getContentSize().height));
    
    local fixHeight = self._cellSizeHeight - (height + chanelIcon:getContentSize().height)
    local spaceHeight = 4 + chanelIcon:getContentSize().height / 2
    otherBtnHead:setPositionY(self._otherBtnHeadHeight - fixHeight + spaceHeight)
    chanelIcon:setPositionY(self._otherChannelHeight - fixHeight + spaceHeight)
    newName:setPositionY(self._otherNameHeight + nameHeight - fixHeight + spaceHeight)

    local otherIconLaba = otherChatCell:getChildByName("Icon_laba")
    otherIconLaba:setPositionY(self._otherIconLabaHg - fixHeight + spaceHeight)

    otherNameLaba:setPositionY(self._otherNameLabaHg - fixHeight + spaceHeight)

    if msgNode.chanel == AppDef.ChatChanelType.CCT_LABA then
        chanelIcon:setVisible(false)
    else
        otherIconLaba:setVisible(false)
    end

    if msgNode.ChatType == 2 then
    --语音聊天
        local voiceOffset = 5
        newLabel:setPositionY(self._otherVoiceTxtH - fixHeight + spaceHeight - voiceOffset - 5)
        btn_Voice:setPositionY(self._otherVoiceLable - fixHeight + spaceHeight - voiceOffset)
        local image = btn_Voice:getChildByName("Image")
        image:setPositionY(self._otherVoiceImageHeight - fixHeight + spaceHeight - voiceOffset)
        local time = btn_Voice:getChildByName("Time")
        time:setPositionY(self._otherVoiceTimesHeight - fixHeight + spaceHeight - voiceOffset)

    else
        newLabel:setPositionY(self._otherTextHeight - fixHeight + spaceHeight)
        bg:setPositionY(self._otherBgContentHeight - fixHeight + spaceHeight)
    end

    cellChild:setContentSize(cc.size(cellChild:getContentSize().width, height + chanelIcon:getContentSize().height + 20))

    return otherChatCell
end

function MainChatUI:getListViewIsInBottom(listViewNode)
    -- body
    if listViewNode == nil then
        return false
    end

    local posBottom = listViewNode:getInnerContainerPosition()
    -- local contentsizeTmp = listViewNode:getContentSize()
    -- local sizeTmp = listViewNode:getInnerContainerSize()
    return posBottom.y > -10
end

function MainChatUI:getIsMe(roleID)
    -- body
    local userId = LRoleDataMgr.MyHeroInfo.id
    return userId == roleID
end

function MainChatUI:getTeamId( msg )
    -- body
    local infoPos, posEnd = string.find(msg, "%[d|")
    local teamInfo = string.sub(msg, posEnd + 1, string.len(msg) - 1)
    ------print("teamInfo", teamInfo)
    local info = string.split(teamInfo, ",")
    return info[2]
end

function MainChatUI:showContentBtnList(pos, teamId)
    -- body
    local function joinTeamCallback()
--加入队伍
        ------print("teamId +++++++++++++++++++++++++++++++++++++", tonumber(teamId))
--        LuaNetSendMsg:ReqJoinTeam(tonumber(teamId))
        LuaNetSendMsg:QueryApplyTeam(tonumber(teamId))--申请入队()
    end

    local btndata = {}
    table.insert(btndata,{GUITips.UI_Team_Join, joinTeamCallback})
    btndata.pos = pos
    LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowCommomBtnList, btndata)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

end

function MainChatUI:createSysChatCell( childCell, msgNode )
    -- body
    local sysChatCell = childCell
    sysChatCell:setVisible(true)
    
    local Content = sysChatCell:getChildByTag(480)
    if Content == nil then
        return
    end
    Content:setAnchorPoint(cc.p(0, 1))
--    Content:setString(msgNode.chatContent);

    local oldName = sysChatCell:getChildByTag(789)
    local newName
    if oldName ~= nil then
        newName = oldName
        newName:triggleInit(msgNode.chatContent, self._sysContentSize, -130, UICOLOR_BROWN, 21, false, 5)
    else
        newName = CCAysLabel:create()
        newName:triggleInit(msgNode.chatContent, self._sysContentSize, -130, UICOLOR_BROWN, 21, false, 5)
        sysChatCell:addChild(newName);
    end

    newName:setAnchorPoint(cc.p(0, 1))
    newName:setPosition(Content:getPosition());
    newName:setTag(789)
    Content:setVisible(false)
 --   Content:removeFromParent();

    local cellHeight = newName:getSize().height + 12;
    sysChatCell:setContentSize(cc.size(sysChatCell:getContentSize().width, cellHeight))

--    table.insert(self._HightInfo, cellHeight)
    childCell:setContentSize(cc.size(childCell:getContentSize().width, cellHeight))
    --------print("self.m_sysCellSize = ", self.m_sysCellSize, cellHeight)
    local fixHeight = self.m_sysCellSize - cellHeight
    
    local Channel = sysChatCell:getChildByName("Channel")
    Channel:setAnchorPoint(cc.p(0, 1))
    local spaceHeight = 6
    newName:setPositionY(self._sysChatHeight - fixHeight + spaceHeight)
    Channel:setPositionY(self._sysChatHeight - fixHeight + spaceHeight)
    return sysChatCell
end

function MainChatUI:PopChatItem(ind)
    local itemNode = self._chatListView[ind]:getItem(0);
    itemNode:retain();
    self._chatListView[ind]:removeItem(0);
    LObjPoolMgr.ReleaseGameObject(itemNode:getName(),itemNode);
    itemNode:release();
end

function MainChatUI:addSysChat(msgNode)

--综合
    local isCurInBottom = self:isCurListViewInBottom()
    if not isCurInBottom then
        return
    end

    local maxNum = LRoleDataMgr.Chat:getChannelMaxNum(AppDef.ChatChanelType.CCT_COMMON)
    local comomNum  = #self._chatListView[1]:getItems()
    if comomNum > maxNum then
        self:PopChatItem(1)
    end

    local childCell = LObjPoolMgr.GetGameObject("chatMsg_systemItem");
    childCell:retain();
    childCell:removeFromParent();
    self._chatListView[1]:pushBackCustomItem(childCell);
    childCell:release();


    local sysChatCell = self:createSysChatCell(childCell, msgNode)
    local isCommonListViewInBottom = self:getListViewIsInBottom(self._chatListView[1])
    self:CommomListViewNewMsg(isCommonListViewInBottom)
    self._celIndex =  self._celIndex + 1
--    self._chatListView[1]:jumpToBottom()

--人擂台赛战斗信息显示在当前标签页
    if msgNode.chanel == AppDef.ChatChanelType.CCT_LEITAI then
        local maxNum = LRoleDataMgr.Chat:getChannelMaxNum(AppDef.ChatChanelType.CCT_LEITAI)
        local addtoChatList = self:getChatListByChannel(AppDef.ChatChanelType.CCT_NEAR)
        local chatInd = self:getChatListIndByChannel(AppDef.ChatChanelType.CCT_NEAR)
        local num = #addtoChatList:getItems()
        if num > maxNum then
            self:PopChatItem(chatInd)
            -- addtoChatList:removeItem(0)
        end
        childCell = LObjPoolMgr.GetGameObject("chatMsg_systemItem");
        childCell:retain();
        childCell:removeFromParent();
        addtoChatList:pushBackCustomItem(childCell);
        childCell:release();

        local showCell = self:createSysChatCell(childCell, msgNode)
        local isCurListViewInBottom = self:getListViewIsInBottom(addtoChatList)
        --    判断是否要滚屏
        self:curListViewNewMsg(AppDef.ChatChanelType.CCT_NEAR, isCurListViewInBottom, addtoChatList)
    else
        local maxNum = LRoleDataMgr.Chat:getChannelMaxNum(msgNode.chanel)
        local addtoChatList = self:getChatListByChannel(msgNode.chanel)
        local chatInd = self:getChatListIndByChannel(msgNode.chanel)
        local num = #addtoChatList:getItems()
        if num > maxNum then
            self:PopChatItem(chatInd)
            -- addtoChatList:removeItem(0)
        end
        childCell = LObjPoolMgr.GetGameObject("chatMsg_systemItem");
        childCell:retain();
        childCell:removeFromParent();
        addtoChatList:pushBackCustomItem(childCell);
        childCell:release();

        local AOtherSysChatCell = self:createSysChatCell(childCell, msgNode)
        local isCurListViewInBottom = self:getListViewIsInBottom(addtoChatList)
    --    addtoChatList:jumpToBottom()
    --    判断是否要滚屏
        self:curListViewNewMsg(msgNode.chanel, isCurListViewInBottom, addtoChatList)
    end
end

function MainChatUI:addChatLine(cellChild, msgNode)
    --print("addChatLine")
    -- if ( (msgNode.chanel ~= self._ChannelType) and (self._ChannelType ~= AppDef.ChatChanelType.CCT_COMMON) ) then
    --     return 
    -- end
--    --print("ScrollToBottom", msgNode.chanel)
    if msgNode.chanel == AppDef.ChatChanelType.CCT_SYS or msgNode.chanel == AppDef.ChatChanelType.CCT_BPSYS or msgNode.chanel == AppDef.ChatChanelType.CCT_LEITAI then
        self:addSysChat(msgNode)
    else 
        local userId = LRoleDataMgr.MyHeroInfo.id
        local isMe = (userId == msgNode.roleId);

        if isMe then
            -- cellChild = self._pSelfItem:clone()
            self:addSelfSpeak(msgNode)
        else
            self:addOtherSpeak(msgNode)
        end
    end

end

function MainChatUI:ScrollToBottom()
    ------print("MainChatUI:ScrollToBottom height = ", self.m_pChatTableView:getViewSize().height, self.m_pChatTableView:getContentSize().height)
    if self.m_pChatTableView:getContentSize().height > self.m_pChatTableView:getViewSize().height then
        self.m_pChatTableView:setContentOffset(cc.p(0, 0), false)
    end
    ------print("MainChatUI:ScrollToBottom height end")
end

function MainChatUI:ResetSendText()
    self.m_pInputText:setText("")
end

function MainChatUI:LoadData(type)
    self._ChannelType = type
    self._ChatList = {}
    local num = LRoleDataMgr.Chat:getChannelMaxNum(self._ChannelType)
    local totalList = LRoleDataMgr.Chat:GetChatMessageList()
    for i = #totalList, 1, -1 do
        if type == AppDef.ChatChanelType.CCT_COMMON then

            if #self._ChatList > num then
                table.remove(self._ChatList, 1)
            end

            table.insert(self._ChatList, totalList[i])
        else
            if totalList[i].chanel == type then
                if #self._ChatList > num then
                    table.remove(self._ChatList, 1)
                end
                table.insert(self._ChatList, totalList[i])
            end
        end        
    end
    self:ReLoadChatContent(self._ChatList);
    self:ChangeChatChanel(type)
end

function MainChatUI:ReLoadChatContent(chatList)
    if #chatList <= 0 then
        ------print("00 ==========================")
        self.m_pChatTableView:reloadData()
        ------print("11 ==========================")
        return
    end

    self._celIndex = 0

    -- local function ReloadData()
    --     self.m_pChatTableView:setVisible(true)
    --     ------print("MainChatUI:ReLoadChatContent begin")
    --     self.m_pChatTableView:reloadData()
    --     ------print("MainChatUI:ReLoadChatContent end")
    --     self:ScrollToBottom()
    -- end
    -- self.m_pChatTableView:setVisible(false)
    -- performWithDelay(self.m_pUILayer,ReloadData,0.2)


end

function MainChatUI:ChangeChatChanel(type)
    LRoleDataMgr.Chat:SetSendType(type)
    if type == AppDef.ChatChanelType.CCT_SYS then
        self:EnableSendMsg(false)
    else
        self:EnableSendMsg(true)
    end
    if type == AppDef.ChatChanelType.CCT_PERSIONAL then
        self._pvtChatNode:setVisible(true)
    else
        self._pvtChatNode:setVisible(false)
    end
    self._isChannelCanChat = (type == AppDef.ChatChanelType.CCT_TEAM or type ==  AppDef.ChatChanelType.CCT_FACTION )
    self:updateChatUI(self._isChannelCanChat)
end

function MainChatUI:EnableSendMsg(val)
   
    self._btnSend:setTouchEnabled(val)
    self._btnSend:setBright(val)

    self.m_CheckBox:setVisible(val)
--    self.m_CheckBox:setVisible(false)
    self._sysTips:setVisible(not val)
end

function MainChatUI:addExpressiona(idx)
    local inputString = self:getSendString()
    self.m_pInputText:setText(inputString .. string.format("[E%d]",idx))

    if not GameSdk.androidTruePhone then
        self.m_pInputText:touchDownAction(self.m_pInputText, ccui.TouchEventType.ended)
    end
    
end

function MainChatUI:TimerCallBack()
    local function UpdateCD()
		self:updateSendBtn()
	end
    self:UnSchedule()
    local scheduler =  AppDef.Director:getScheduler()
    self.m_schedulerID = scheduler:scheduleScriptFunc(UpdateCD, 1, false)
end

function MainChatUI:updateSendBtn()
    -- body
--世界频道的CD是10s 当前频道的CD是5s 其他频道没有cd
    if self._ChannelCDTimeArr[worldChannel] <= 0 and self._ChannelCDTimeArr[curChannelIndex] <= 0 and self._ChannelCDTimeArr[kuafuChannelIndex] <= 0 then
        return
    end

    self._ChannelCDTimeArr[worldChannel] = self._ChannelCDTimeArr[worldChannel] - 1
    self._ChannelCDTimeArr[curChannelIndex] = self._ChannelCDTimeArr[curChannelIndex] - 1
    self._ChannelCDTimeArr[kuafuChannelIndex] = self._ChannelCDTimeArr[kuafuChannelIndex] - 1
    if self._ChannelType == AppDef.ChatChanelType.CCT_COMMON then
        if LRoleDataMgr.m_bIsCrossServer == true then
            self:updateSendBtnState(kuafuChannelIndex)
        else
            self:updateSendBtnState(worldChannel)
        end
    elseif self._ChannelType == AppDef.ChatChanelType.CCT_WORLD then
        self:updateSendBtnState(worldChannel)
    elseif self._ChannelType == AppDef.ChatChanelType.CCT_NEAR then
        self:updateSendBtnState(curChannelIndex)
    elseif self._ChannelType == AppDef.ChatChanelType.CCT_KUAFU then
        self:updateSendBtnState(kuafuChannelIndex)
    end

end

function MainChatUI:updateSendBtnState(index)
    -- body
    if index <= kuafuChannelIndex and self._ChannelCDTimeArr[index] > 0 then
        self:UpdateCoolTime(index, self._ChannelCDTimeArr[index])
    else
        self:resetSendBtn()
        self._ChannelCDTimeArr[index] = 0
    end
end

function MainChatUI:UpdateCoolTime(index, cdTime)
    self._btnSend:setTouchEnabled(false)
    self._btnSend:setBright(false)
    self._sendText:setTextColor(CCNORMAL_RED)
--    --print("UpdateCoolTime cdTime = ", cdTime)
    self._sendText:setString(cdTime)
end

function MainChatUI:resetSendBtn()
    ----print("resetSendBtn index")
    self._btnSend:setTouchEnabled(true)
    self._btnSend:setBright(true)
    self._sendText:setString(GUITips.RSI_SEND)
    self._sendText:setTextColor(UICOLOR_BROWN)
--    self:UnSchedule()
end

function MainChatUI:UnSchedule()
    if self.m_schedulerID then
        AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_schedulerID)
        self.m_schedulerID = nil
    end
end

function MainChatUI:ShowChatBtnList(pos, pid,pteamID,name)
    -- body
    local function InvateTeamCallback()      
       -- LuaNetSendMsg:QueryTeamInvite(pid) 
        if pteamID > 0 and LRoleDataMgr.MyHeroInfo:IsTeam() == false then
             LuaNetSendMsg:QueryApplyTeam(pteamID)--申请入队()
           --  Utils:ShowScrollTips(string.format(GUITips.UI_FRIEND_TEAM2,name))
            
        else
            LuaNetSendMsg:QueryTeamInvite(pid)--邀请组队()
          --  Utils:ShowScrollTips(string.format(GUITips.UI_FRIEND_TEAM1,name))
        end      
    end
    local function queryInfo()
        LuaNetSendMsg:QueryOtherPlayer(pid)
    end

    local function addFriend()
        -- if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SJHAOYOU) then
        --     return
        -- end
        LuaNetSendMsg:QueryAddFriend(pid)
    end

    local function addToBlackList()
        if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SJHAOYOU) then
            return
        end
        LuaNetSendMsg:QueryAddBlack(pid)
    end

    local btndata = {}
    -- if pteamID>0 and LRoleDataMgr.MyHeroInfo:IsTeam() == false then
    --     table.insert(btndata,{GUITips.UI_FRIEND_INVATETEAM1,InvateTeamCallback})
    -- else
    --     table.insert(btndata,{GUITips.UI_FRIEND_INVATETEAM,InvateTeamCallback})
    -- end
    table.insert(btndata,{GUITips.UI_FRIEND_QUERY, queryInfo})
    table.insert(btndata,{GUITips.RSI_CHAT_MSG5, addFriend})
    table.insert(btndata,{GUITips.RSI_CHAT_MSG6, addToBlackList})

    btndata.pos = pos

    LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowCommomBtnList, btndata)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

end

function MainChatUI:addMsgTimerCallBack()
    -- body
    local function UpdateCD()
        if self:isAddAllMsg() then
            return
        end

        if self._isChangingMap == true then
            return
        end

        local isCurInBottom = self:isCurListViewInBottom()
        if isCurInBottom then
--            local msgNode = self:getCurChatMsgNode()
            local msgNode = self._ChatList[1]
            -- if msgNode then
            --     self._curAddId = msgNode.id
            --     self:addChatLine(nil, msgNode)
            -- else
            --     self:resetChatId()
            --     UpdateCD()
            -- end
            self:addChatLine(nil, msgNode)
            table.remove(self._ChatList, 1)
        else

        end
    end
    self:UnAddMsgSchedule()
    local scheduler = AppDef.Director:getScheduler()
    self.m_schedulerAddMsgID = scheduler:scheduleScriptFunc(UpdateCD, 0.5, false)
end

function MainChatUI:UnAddMsgSchedule()
    if self.m_schedulerAddMsgID then
        AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_schedulerAddMsgID)
        self.m_schedulerAddMsgID = nil
    end
end

function MainChatUI:getCurChatMsgNode()
    -- body
    local nextId = self:getNextChatId()
    for i = 1, #self._ChatList do
        if nextId == self._ChatList[i].id then
            return self._ChatList[i]
        end
    end
    return nil
end

--缓冲池消息增加太快，还没来得及显示就已经被删除了，如果没有找到则向后找
function MainChatUI:resetChatId( ... )
    -- body
    self._curAddId = self._ChatList[1].id
end

function MainChatUI:tooManyMsgReset( ... )
    -- body
    if self._unReadNum > 40 and #self._ChatList > 50 then
        local totalNum = #self._ChatList
        local lastId = self._ChatList[totalNum].id
        self._curAddId = lastId - AppDef.Chat_Msg_Type.CCT_CUR_CHANNEL_LASTMSG
        if self._curAddId <= 0 then
            self._curAddId = self._curAddId + 1000
        end
    end
end

function MainChatUI:getNextChatId( ... )
    -- body
    local nextChatId  = self._curAddId + 1
    if nextChatId > 1000 then
        nextChatId = nextChatId - 1000
    end
    return nextChatId
end

function MainChatUI:getSendString( ... )
    -- body
    local inputString 
    if GameSdk.androidTruePhone then
        inputString = self.m_pInputText:getString()
    else
        inputString = self.m_pInputText:getText()
    end
    return inputString
end

function MainChatUI:isAddAllMsg( ... )
    -- body
    local size = #self._ChatList
    if size < 1 then
        return true
    end
--    --print("msg", self._ChatList[size].id, self._curAddId)
    return self._ChatList[size].id == self._curAddId
end


function MainChatUI:testAddMsg()
    -- body
    local function UpdateCD()
        self:sendMsgTest()
    end
    self:UnTestAddMsgSchedule()
    local scheduler = AppDef.Director:getScheduler()
    self.m_schedulerTest = scheduler:scheduleScriptFunc(UpdateCD, 10, false)
end

function MainChatUI:sendMsgTest( ... )
    -- body
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EAID_WORLDCHAT, true) then
        return
    end

    if not self._isVoiceChat then          
        LuaNetSendMsg:QuerySendChatMsg(self._ChannelType, GUITips.RSI_TIANYUANZHENGBA_TIPS_24);
    end

end

function MainChatUI:UnTestAddMsgSchedule()
    if self.m_schedulerTest then
        AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_schedulerTest)
        self.m_schedulerTest = nil
    end
end

function MainChatUI:RegisterGuide()
    --Utils:RegisterGuide(GuideDef.StepId.Guide_SJFY, self._btnSend, handler(self, MainChatUI.OnSendChatButtonClick))
end

function MainChatUI:CheckGuide()
    --Utils:CheckGuide(GuideDef.StepId.Guide_SJFY)
end

 
return MainChatUI