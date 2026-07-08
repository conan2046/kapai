--[[
lua chat 聊天
]]

local ChatMiniShowLayer = LUIBase:New()
ChatMiniShowLayer.IsHideInBattle = true
ChatMiniShowLayer.__index = ChatMiniShowLayer

local TXT_SPACE = 5;       --行间距
local BTN_FIXSPACE = 15    --调整按钮动作的距离

function ChatMiniShowLayer:New()
    
    local o = LUIBase:New()
    setmetatable(o,ChatMiniShowLayer)   
    o:Init()
    return o
end

--[[
注册消息
]]
function ChatMiniShowLayer:RegistMsgs()
    self.msgIds = 
    {
        LUIChatEvent.addMsg,
        LUIBangPaiEvent.UpdateMyFactionInfo,
        LUIFunctionEvent.FunctionOpen,
        LUIMailEvent.OpenWriteMail,   --写邮件
        LUIChatEvent.addPcTempChat,   --私聊
        LUIMapEvent.ChangeMapSuccess, --跳转地图成功
        LUILogicEvent.ChangeScene,    --开始跳转场景
        LUIChatEvent.openSendLabaUI,
    }
    self:RegistSelf(self,self.msgIds)
end

function ChatMiniShowLayer:ProcessEvent(msg)
    if msg.msgId == LUIChatEvent.addMsg then

--        table.insert(self._miniChatList, msg.value)
--        self:createMsg(msg.value)
        --刚从后台回来,暂停的聊天信息不再处理
        if LRoleDataMgr.m_isEnterIngForeground then
            return
        end
         self:addMsgData(msg.value)
    end

    if msg.msgId == LUIFunctionEvent.FunctionOpen then
        self:dealFunctionOpen(msg.value)
    end

--跳转写信
    if msg.msgId == LUIMailEvent.OpenWriteMail then
        local name = msg.value;
        self:OnFriendButtonClick();

        LGameMsg.m_baseMsgWithOne:Change(LUIMailEvent.TurnWriteMail, name)
        LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
    end

    if msg.msgId == LUIChatEvent.addPcTempChat then

        local roleId = msg.value

        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Social.SocialLayer",AppDef.UIType.FirstClassLayer, 2)
        self:SendMsg(LGameMsg.m_initUIMsg)

        LGameMsg.m_baseMsgWithOne:Change(LUIChatEvent.turnToPcChatState, roleId)
        LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
    elseif msg.msgId == LUIMapEvent.ChangeMapSuccess then
        self._isChangingMap = false
    elseif msg.msgId == LUILogicEvent.ChangeScene then
        self._isChangingMap = true
    elseif msg.msgId == LUIBangPaiEvent.UpdateMyFactionInfo then
        self:updateFactionBtn()
    elseif msg.msgId == LUIChatEvent.openSendLabaUI then
        self:openSendLabaDialog()
    end

end

function ChatMiniShowLayer:Init()
    self.m_poses = {}
    self._miniChatList = {}
    self:RegistMsgs()
    self.m_pUILayer = cc.CSLoader:createNode("csd/ChatLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    if GameSdk.isFullScreen then
        self.m_pUILayer:setPositionX(self.m_pUILayer:getPositionX() + 88 * 0.9)
    end

    self.m_mainNode = self.m_pUILayer:getChildByName("Panel_Chat");
    self.m_mainNode:setTouchEnabled(true);
    self.m_mainNode:setSwallowTouches(false)
    self:InitData()
    self:AddTouchEvt();
    --self:RegisterGuide()

    self._voiceTime = 15
    self._alreadyVoiceClose = false

    self:addMsgTimerCallBack()
end

function ChatMiniShowLayer:InitData()

    self.m_pChatListView = self.m_mainNode:getChildByName("ListView")
    self.m_pChatListView:setTouchEnabled(true);
    self.m_pChatListView:setSwallowTouches(false)
    self.m_pChatListView:setScrollBarEnabled(false)
    self.m_pBaseChatCell = self.m_mainNode:getChildByName("Item");
    self.m_pBaseChatCell:setVisible(false)
    self._tagHeight = self.m_pBaseChatCell:getChildByName("Tag"):getPositionY()
    self._contentHeight = self.m_pBaseChatCell:getChildByName("Content"):getPositionY()
    self._cellSize = self.m_pBaseChatCell:getContentSize()
    self._celIndex = 0;
    self.oneTouch = false;
    self.spaceHeight = self.m_pChatListView:getContentSize().height;
    self.isShowAll = false
    self._isChangingMap = false
end

function ChatMiniShowLayer:AddTouchEvt()
   
   --显示聊天界面
   LRedDotCheckMgr:AddCheckBtn(self.m_mainNode, AppDef.RedDotBtnName.chatBtn)


    local Panel_Bg = self.m_mainNode:getChildByName("Panel_Bg")
    local function showMainChatlayer(pTouch, pEvent)

        if pEvent == ccui.TouchEventType.began then
            self.oneTouch  = true
            local touchBeginPosTemp = Panel_Bg:getTouchBeganPosition()
            self._touchBeginPos = Panel_Bg:getParent():convertToWorldSpace(cc.p(touchBeginPosTemp.x, touchBeginPosTemp.y))
        end

        if pEvent == ccui.TouchEventType.moved then
            local touchMovePosTmp = Panel_Bg:getTouchMovePosition()
            local touchMovePos = Panel_Bg:getParent():convertToWorldSpace(cc.p(touchMovePosTmp.x, touchMovePosTmp.y))
            local distance = math.sqrt(math.pow(touchMovePos.x - self._touchBeginPos.x, 2) + math.pow(touchMovePos.y - self._touchBeginPos.y, 2))
--            --print("-------------distance", distance)
            if distance > 10 then
                self.oneTouch  = false
            end
        end

        if pEvent == ccui.TouchEventType.ended then

            if(not self.oneTouch) then 
                return
            end
            LGameMsg.m_baseMsgWithOne:Change(LUIChatEvent.showChat)
            self:SendMsg(LGameMsg.m_baseMsgWithOne)
        end
    end
    Panel_Bg:addTouchEventListener(showMainChatlayer)

    local function showChatLayer()
        if Utils:CheckModelNotOpened(AppDef.EModuleID.EAID_WORLDCHAT) then
            return
        end
        LGameMsg.m_baseMsgWithOne:Change(LUIChatEvent.OpenPrivateChat)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end
    self.m_mainNode:getChildByName("Prompt"):addClickEventListener(showChatLayer)
    self:MarkIntaractCObj(Panel_Bg)

--社交
   local friendBtn = self.m_mainNode:getChildByName("btn_Friend")
   -- LRedDotCheckMgr:AddCheckBtn(friendBtn, AppDef.RedDotBtnName.socialBtn)

   table.insert(self.m_poses, friendBtn:getPositionX())
   local isShowFriend = LDataConstMgr:isModuleDefaultShow(AppDef.EModuleID.EMID_SHEJIAO)
   local isOpened = {id = AppDef.EModuleID.EMID_SHEJIAO, open = false}
   LGameMsg.m_baseMsgWithOne:Change(LUIFunctionEvent.GetFuncOpen, isOpened)
   LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
   isShowFriend = isShowFriend or isOpened.open
   friendBtn:setVisible(isShowFriend)
   -- dump({isShowFriend, isShowFriend, isOpened.open})
   friendBtn:addClickEventListener(handler(self, ChatMiniShowLayer.OnFriendButtonClick))
    self:MarkIntaractCObj(friendBtn)
   self.m_pFriendBtn = friendBtn

--世界语音
    local worldVoiceBtn = self.m_mainNode:getChildByName("btn_Voice_shi")
    table.insert(self.m_poses, worldVoiceBtn:getPositionX())
    if not isShowFriend then
        worldVoiceBtn:setPositionX(self.m_poses[1])

    end
    
    local function showWorldVoiceChatlayer(pTouch, pEvent)
        if Utils:CheckModelNotOpened(AppDef.EModuleID.EAID_WORLDCHAT) then
            return
        end
        self:ShowVoiceChatUI(pEvent, AppDef.ChatChanelType.CCT_WORLD, worldVoiceBtn)
    end

    worldVoiceBtn:addTouchEventListener(showWorldVoiceChatlayer)
    self:MarkIntaractCObj(worldVoiceBtn)
    self.m_pWorldVoiceBtn = worldVoiceBtn

--帮派语音
    self.bpBtn = self.m_mainNode:getChildByName("btn_Voice_bang")
    table.insert(self.m_poses, self.bpBtn:getPositionX())
    if not isShowFriend then
        self.bpBtn:setPositionX(self.m_poses[2])
    end
    local function showBpVoiceChatlayer(pTouch, pEvent)
        self:ShowVoiceChatUI(pEvent, AppDef.ChatChanelType.CCT_FACTION, self.bpBtn)
    end

    local isHasBp = LRoleDataMgr.MyHeroInfo.FactionId > 0
    self.bpBtn:addTouchEventListener(showBpVoiceChatlayer)
    self:MarkIntaractCObj(self.bpBtn)

    local labaBtn = self.m_mainNode:getChildByName("btn_laba")
    table.insert(self.m_poses, labaBtn:getPositionX())
    self._labaBtn = labaBtn
    print("AddTouchEvt", isShowFriend, isHasBp)
    if not isShowFriend then
        if not isHasBp then
            self._labaBtn:setPositionX(self.m_poses[2])
        else
            self._labaBtn:setPositionX(self.m_poses[3])
        end
    else
        if not isHasBp then
            self._labaBtn:setPositionX(self.m_poses[3])
        else
            self._labaBtn:setPositionX(self.m_poses[4])
        end
    end
    labaBtn:setVisible(false)
    
    local function sendLabaMsgEvent( sender )
        -- body
        if Utils:CheckModelNotOpened(AppDef.EModuleID.EAID_WORLDCHAT) then
            return
        end

        if LRoleDataMgr.m_bIsCrossServer then
            self:openSendLabaDialog()
        else
            LuaNetSendMsg:QueryLaBaIsOpen(1)
        end
    end
    labaBtn:addClickEventListener(sendLabaMsgEvent)
    self:MarkIntaractCObj(labaBtn)
--箭头
    local arrrowBtn = self.m_mainNode:getChildByName("btn_Arrows")
    local function OnArrowButtonClick(sender)
        
        local width = self.m_pChatListView:getContentSize().width;
        local height = self.m_pChatListView:getContentSize().height;
        local bg = self.m_mainNode:getChildByName("bg")
        local bgWidth = bg:getContentSize().width;
        local bgHeght = bg:getContentSize().height;
        
        if self.isShowAll then

            self.m_pChatListView:setContentSize(cc.size(width, height - self.spaceHeight))
            bg:setContentSize(cc.size(bgWidth, bgHeght - self.spaceHeight));
            self.isShowAll = false

            local action = cc.MoveBy:create( 0.3, cc.p(0, -self.spaceHeight - BTN_FIXSPACE))
            
            sender:setPositionY(sender:getPositionY() + (-self.spaceHeight - BTN_FIXSPACE))
            sender:setRotation(0);

--            local friendAction = cc.MoveBy:create( 0.3, cc.p(0, -self.spaceHeight - BTN_FIXSPACE))
            local friendBtn = self.m_mainNode:getChildByName("btn_Friend")
            friendBtn:setPositionY(friendBtn:getPositionY() + (-self.spaceHeight - BTN_FIXSPACE))

--            local voiceAction = cc.MoveBy:create( 0.3, cc.p(0, -self.spaceHeight - BTN_FIXSPACE))
            local voiceBtn = self.m_mainNode:getChildByName("btn_Voice_shi")
            voiceBtn:setPositionY(voiceBtn:getPositionY() + (-self.spaceHeight - BTN_FIXSPACE))

--            local bangAction = cc.MoveBy:create( 0.3, cc.p(0, -self.spaceHeight - BTN_FIXSPACE))
            local voiceBang = self.m_mainNode:getChildByName("btn_Voice_bang")
            voiceBang:setPositionY(voiceBang:getPositionY() + (-self.spaceHeight - BTN_FIXSPACE))

            self._labaBtn:setPositionY(self._labaBtn:getPositionY() + (-self.spaceHeight - BTN_FIXSPACE))

        else
            self.m_pChatListView:setContentSize(cc.size(width, height + self.spaceHeight))
            bg:setContentSize(cc.size(bgWidth, bgHeght + self.spaceHeight));
            self.isShowAll = true

 --           local action = cc.MoveBy:create( 0.3, cc.p(0, self.spaceHeight + BTN_FIXSPACE))
            local arrrowBtn = self.m_mainNode:getChildByName("btn_Arrows")
            arrrowBtn:setPositionY(arrrowBtn:getPositionY() + (self.spaceHeight + BTN_FIXSPACE))
            arrrowBtn:setRotation(180)

--            local friendAction = cc.MoveBy:create( 0.3, cc.p(0, self.spaceHeight + BTN_FIXSPACE))
            local friendBtn = self.m_mainNode:getChildByName("btn_Friend")
            friendBtn:setPositionY(friendBtn:getPositionY() + (self.spaceHeight + BTN_FIXSPACE))

--            local voiceAction = cc.MoveBy:create( 0.3, cc.p(0, self.spaceHeight + BTN_FIXSPACE))
            local voiceBtn = self.m_mainNode:getChildByName("btn_Voice_shi")
            voiceBtn:setPositionY(voiceBtn:getPositionY() + (self.spaceHeight + BTN_FIXSPACE))

--            local bangAction = cc.MoveBy:create( 0.3, cc.p(0, self.spaceHeight + BTN_FIXSPACE))
            local voiceBang = self.m_mainNode:getChildByName("btn_Voice_bang")
            voiceBang:setPositionY(voiceBang:getPositionY() + (self.spaceHeight + BTN_FIXSPACE))

            self._labaBtn:setPositionY(self._labaBtn:getPositionY() + (self.spaceHeight + BTN_FIXSPACE))
        end
        self.m_pChatListView:jumpToBottom()
    end
    arrrowBtn:addClickEventListener(OnArrowButtonClick)
    self:MarkIntaractCObj(arrrowBtn)
--设置
    local setBtn = self.m_mainNode:getChildByName("btn_Set")
    local function OnSetButtonClick(sender)
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUIInBattle, "Chat.ChatSetting", AppDef.UIType.PopWindow)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    setBtn:setVisible(false)
    setBtn:addClickEventListener(OnSetButtonClick)
    self:MarkIntaractCObj(setBtn)
end

--test code
-- function ChatMiniShowLayer:ShowNeedNextBattle( ... )
--     -- body
--     local function okFunc()
--         print("just do it")
--     end

--     local function cancelFunc( ... )
--         -- body
--     end
--     Utils:ShowDialogOKCancel(GUITips.RSI_MONOPOLY_PLAYAGAIN, okFunc, cancelFunc, nil, nil, nil, true)
-- end

function ChatMiniShowLayer:ShowVoiceChatUI(pEvent, type, sender)
    -- body
    local info = LRoleDataMgr.MyHeroInfo.MyVIPInfo
    if pEvent == ccui.TouchEventType.began then
--            self._VoiceWindow:setVisible(true)
            if LRoleDataMgr.MyHeroInfo.level < 15 then
                return
            end
            self:VoiceStartEvent(type)
        end

        if pEvent == ccui.TouchEventType.moved then
--            self._VoiceWindow:setVisible(false)
            if LRoleDataMgr.MyHeroInfo.level < 15 then
                return
            end

            if self._alreadyVoiceClose then
                return
            end

            if not sender:getRendererClicked():isVisible() then
                LGameMsg.m_baseMsgWithOne:Change(LUIChatEvent.cancelVoiceWindow)
                LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
            else
                LGameMsg.m_baseMsgWithOne:Change(LUIChatEvent.showVoiceWindow, true)
                LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
            end
            
        end

        if pEvent == ccui.TouchEventType.canceled then

            if LRoleDataMgr.MyHeroInfo.level < 15 then
                return
            end

            LGameMsg.m_baseMsgWithOne:Change(LUIChatEvent.showVoiceWindow, false)
            LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)

            local bMusicMate = LUserConfigMgr:GetIsMusicClosed()
            if not bMusicMate then
                LGameMsg.m_audioMsg:Change(LAudioEvent.StopSpeakVoice)
                LUIManager:SendMsg(LGameMsg.m_audioMsg)
            end
        end
        
        if pEvent == ccui.TouchEventType.ended then
--            self._VoiceWindow:setVisible(false)

            if LRoleDataMgr.MyHeroInfo.level < 15 then
                Utils:ShowScrollTips(string.format(GUITips.RSI_CHAT_LIMITE_TIPS4, info.totalRecharge))
                return
            end

            if self._alreadyVoiceClose then
                self._alreadyVoiceClose = false
            end
            self:UnVoiceSchedule()
            self:VoiceEndEvent()
            
        end
end


function ChatMiniShowLayer:VoiceStartEvent(chatType)
    -- body
    LGameMsg.m_baseMsgWithOne:Change(LUIChatEvent.showVoiceWindow, true)
    LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)

    self:VoiceTimerCallBack()
    LVoiceDataMgr.ChannelType = chatType
    LVoiceDataMgr:registerCallBack()
    LVoiceDataMgr:startVoice()
end

function ChatMiniShowLayer:VoiceEndEvent()
    -- body
    LGameMsg.m_baseMsgWithOne:Change(LUIChatEvent.showVoiceWindow, false)
    LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)

    LVoiceDataMgr:endVoice()
end


function ChatMiniShowLayer:VoiceTimerCallBack()
    local function UpdateCD()
        self._voiceTime = self._voiceTime - 1
--        print("self._voiceTime", self._voiceTime)
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

function ChatMiniShowLayer:UnVoiceSchedule()
    if self.m_schedulerVoiceID then
        AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_schedulerVoiceID)
        self.m_schedulerVoiceID = nil
    end
end


function ChatMiniShowLayer:createMsg(msgNode)

   if self._celIndex >= 10 then
        self.m_pChatListView:removeItem(0)
        self._celIndex = self._celIndex - 1
   end

   --频道
    local chatCell = self.m_pBaseChatCell:clone()
    local strChanelIcon = AppDef:getChannelIcon(msgNode.chanel)
    local chanelIcon = chatCell:getChildByName("Tag");
    chanelIcon:setAnchorPoint(cc.p(0, 1))
    chanelIcon:loadTexture(strChanelIcon, ccui.TextureResType.plistType);

    chatCell:setEnabled(true)
    chatCell:setVisible(true)
    chatCell:setSwallowTouches(false)

    local descLabel
    local descLabelTemp = chatCell:getChildByName("Content")
    local contentLaba =  chatCell:getChildByName("Content_laba")

    if msgNode.chanel == AppDef.ChatChanelType.CCT_LABA then
        descLabel = contentLaba
    else
        descLabel = descLabelTemp
    end


    local _ChatString = msgNode.chatContent
    if msgNode.ChatType ~= nil and msgNode.ChatType == 2 then
        local contentInfo = json.decode(msgNode.chatContent, 1)
        _ChatString = contentInfo.content
    end

    local newString
    if msgNode.chanel == AppDef.ChatChanelType.CCT_SYS  then
        newString = msgNode.chatContent
    else
        if msgNode.vipLevel > 0 then
           newString  = string.format("[c4]%s%d[/c][N%d]%s[/N]:%s",GUITips.RSI_CHAT_MSG7, msgNode.vipLevel, msgNode.roleId, msgNode.roleName, _ChatString);
        else
            newString  = string.format("[N%d]%s[/N]:%s", msgNode.roleId, msgNode.roleName, _ChatString);
        end
    end

        
    --富文本
    local newLabel = CCAysLabel:create()
    newLabel:triggleInit(newString, descLabel:getContentSize(), -130, UICOLOR_YELLOW_PALE, 21, true, 7)
    newLabel:setAnchorPoint(cc.p(0, 1))
    newLabel:setPosition(descLabel:getPosition());
    newLabel:setName("NewContent")
    chatCell:addChild(newLabel)
    descLabel:removeFromParent()

    local function contentEvent()
        -- body
        local worldPos = newLabel:getParent():convertToWorldSpace(cc.p(newLabel:getPositionX(), newLabel:getPositionY()));
        local worldPosAdjust = cc.p(worldPos.x + newLabel:getSize().width / 4, worldPos.y + 80)
        local teamInfo = self:getTeamId(msgNode.chatContent);
--        --print("contentEvent +++++++++++++++++++++++++++ teamInfo", teamInfo)
        LuaNetSendMsg:QueryApplyTeam(tonumber(teamInfo))
--        self:showContentBtnList(worldPosAdjust, teamInfo);
    end
    newLabel:registerScriptTapHandler(contentEvent)
    
    local cellHeight = newLabel:getSize().height + 10;
    chatCell:setContentSize(cc.size(chatCell:getContentSize().width, cellHeight))

    local fixHeight = self._cellSize.height - cellHeight
    local spaceHeight = 5;
        
    local Tag_laba = chatCell:getChildByName("Tag_laba")

    newLabel:setPositionY(self._contentHeight - fixHeight - spaceHeight)
    chanelIcon:setPositionY(self._contentHeight - fixHeight - spaceHeight)
    Tag_laba:setPositionY(self._contentHeight - fixHeight - spaceHeight)

    if msgNode.chanel == AppDef.ChatChanelType.CCT_LABA then
        chanelIcon:setVisible(false)
        Tag_laba:setVisible(true)
        descLabelTemp:setVisible(false)
    else
        chanelIcon:setVisible(true)
        Tag_laba:setVisible(false)
        contentLaba:setVisible(false)
    end


    self.m_pChatListView:insertCustomItem(chatCell, self._celIndex)
    self._celIndex = self._celIndex + 1
--    self.m_pChatListView:setItemsMargin(TXT_SPACE);
    self.m_pChatListView:jumpToBottom()



end

function ChatMiniShowLayer:getTeamId( msg )
    -- body
    local infoPos, posEnd = string.find(msg, "%[d|")
    local teamInfo = string.sub(msg, posEnd + 1, string.len(msg) - 1)
--    --print("teamInfo", teamInfo)
    local info = string.split(teamInfo, ",")
    return info[2]
end

function ChatMiniShowLayer:showContentBtnList(pos, teamId)
    -- body
    local function joinTeamCallback()
--加入队伍
--        --print("teamId +++++++++++++++++++++++++++++++++++++", tonumber(teamId))
        LuaNetSendMsg:QueryApplyTeam(tonumber(teamId))
    end

    local btndata = {}
    table.insert(btndata,{GUITips.UI_Team_Join, joinTeamCallback})
    btndata.pos = pos
    LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowCommomBtnList, btndata)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end


function ChatMiniShowLayer:onExit()
    self.m_pUILayer = nil
    self:UnAddMsgSchedule()
    self:Destory()
end

function ChatMiniShowLayer:updateFactionBtn()
    local bangPai = LRoleDataMgr.MyHeroInfo.FactionId
    if bangPai > 0 then
        self.bpBtn:setVisible(true)
        Utils:SendMsg(LUIMainEvent.SetFuncBtnVisible, {functionId=AppDef.EModuleID.EMID_BANGPAI, isShow=true})
        self._labaBtn:setPositionX(self.m_poses[4])
    else
        self.bpBtn:setVisible(false)
        self._labaBtn:setPositionX(self.m_poses[3])
    end
    --先屏蔽
    self.bpBtn:setVisible(false)
end

function ChatMiniShowLayer:dealFunctionOpen(value)
    local ids = value[1]
    -- dump(ids)
    if Utils:ToBool(ids[AppDef.EModuleID.EMID_SHEJIAO]) then
        self.m_pFriendBtn:setVisible(true)
        self.m_pFriendBtn:setPositionX(self.m_poses[1])
        self.m_pWorldVoiceBtn:setPositionX(self.m_poses[2])
        self.bpBtn:setPositionX(self.m_poses[3])
        local bangPai = LRoleDataMgr.MyHeroInfo.FactionId
        if bangPai > 0 then
            self._labaBtn:setPositionX(self.m_poses[4])
        else
            self._labaBtn:setPositionX(self.m_poses[3])
        end
    end
end

function ChatMiniShowLayer:RegisterGuide()
    if true then
        return
    end
    ------------------------------------------------------------------------
    -- if self.m_pFriendBtn then
    --     local isOpen = (not Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SJHAOYOU, true))
    --     Utils:RegisterGuide(GuideDef.StepId.Guide_SHEJ, self.m_pFriendBtn, function()
    --         Utils:OpenFunction(AppDef.EModuleID.EMID_SJHAOYOU)
    --     end, nil, isOpen)
    -- end
end

function ChatMiniShowLayer:OnFriendButtonClick(sender)
    Utils:OpenFunction(AppDef.EModuleID.EMID_SJYOUJIAN)
end

function ChatMiniShowLayer:addMsgTimerCallBack()
    -- body
    local function UpdateCD()
        if self:isAddAllMsg() then
            return
        end

        if self._isChangingMap == true then
            return
        end
--        print("self._miniChatList num =", #self._miniChatList)
        local data = self._miniChatList[1]
        self:createMsg(data)
        table.remove(self._miniChatList, 1)
    end
    self:UnAddMsgSchedule()
    local scheduler = AppDef.Director:getScheduler()
    self.m_schedulerAddMsgID = scheduler:scheduleScriptFunc(UpdateCD, 0.5, false)
end

function ChatMiniShowLayer:UnAddMsgSchedule()
    if self.m_schedulerAddMsgID then
        AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_schedulerAddMsgID)
        self.m_schedulerAddMsgID = nil
    end
end

function ChatMiniShowLayer:isAddAllMsg( ... )
    -- body
    if #self._miniChatList < 1 then
        return true
    end
    return false
end

function ChatMiniShowLayer:openSendLabaDialog( ... )
    -- body
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUIInBattle, "Chat.SendLabaMsgUI", AppDef.UIType.Chat)
    self:SendMsg(LGameMsg.m_initUIMsg)
end

function ChatMiniShowLayer:addMsgData(data)
--缓冲池最多100条
    num = AppDef.Chat_Msg_Type.CCT_CUR_CHANNEL_All_MSG
    local myRoleId = LRoleDataMgr.MyHeroInfo.id
    if #self._miniChatList > num then
        if self._miniChatList[1].roleId == myRoleId then
            table.remove(self._miniChatList, 2)
        else
            table.remove(self._miniChatList, 1)
        end
    end

    if data.roleId == myRoleId then
        table.insert(self._miniChatList, 1, data)
    else
        table.insert(self._miniChatList, data)
    end
    
end


return ChatMiniShowLayer