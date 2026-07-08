--[[
NPC对话
]]

local NPCChatDialogUI = LUIBase:New()
NPCChatDialogUI.__index = NPCChatDialogUI
NPCChatDialogUI.IsHideInBattle = true

NPCChatDialogUI.ImgPosX = nil
NPCChatDialogUI.NamePosX = nil
NPCChatDialogUI.DescPosX = nil
NPCChatDialogUI.UpImgPosY = nil
NPCChatDialogUI.DownImgPosY = nil
function NPCChatDialogUI:New(chatData)
    local o = LUIBase:New()
    setmetatable(o,NPCChatDialogUI)  
    o:Init(chatData)
    return o
end

--[[
注册消息
]]
function NPCChatDialogUI:RegistMsgs()
    -- self.msgIds = 
    -- {
    --     -- LUILoginEvent.RecvCheckHeroName,
    --     -- LUILoginEvent.RecvServerList,
    --     -- LUILoginEvent.RecvRoleServerList,
    --     -- LUILoginEvent.LoginSuccess,
    -- }
    -- self:RegistSelf(self,self.msgIds)
end

function NPCChatDialogUI:ProcessEvent(msg)
--    if msg.msgId == LUILoginEvent.RecvCheckHeroName then
--        self:SaveRandomName(msg.value)
--    end
end

function NPCChatDialogUI:Init(chatData)
    self:RegistMsgs()
    self:CreateUINode("csd/common/DialogLayer.csb")
    self.m_pUILayer:setVisible(true)
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    
    self:InitData()
    self:AddTouchEvt()
    self:DoAnimation()
    self:UpdateUserData(chatData)
    self:RegisterGuide()
end

function NPCChatDialogUI:InitData()
    local panel = self.m_pUILayer:getChildByName("DialogUI")
    self.m_pNamePanel = panel:getChildByName("bg_Name")
    self.m_pUpBgImg = panel:getChildByName("Image_1")
    self.m_pNameLabel = self.m_pNamePanel:getChildByName("Name")
    self.m_pNPCImg = panel:getChildByName("NPC")
    
    self.m_pDescLabel = panel:getChildByName("Content")
    self.m_pDescLabel:setString("")
    self.m_pSkipBtn = self.m_pUpBgImg:getChildByName("btn_Skip")
    self.m_pSkipLabel = self.m_pUpBgImg:getChildByName("Text_3")
    self.m_pSkipLabel:setTouchEnabled(true)
    self.m_pDownBgImg = panel:getChildByName("Image_1_0")

    if NPCChatDialogUI.ImgPosX == nil then
        NPCChatDialogUI.ImgPosX = self.m_pNPCImg:getPositionX()
        NPCChatDialogUI.NamePosX = self.m_pNamePanel:getPositionX()
        NPCChatDialogUI.DescPosX = self.m_pDescLabel:getPositionX()

        NPCChatDialogUI.UpImgPosY = self.m_pUpBgImg:getPositionY()
        NPCChatDialogUI.DownImgPosY = self.m_pDownBgImg:getPositionY()
    else
        self.m_pNPCImg:setPositionX(NPCChatDialogUI.ImgPosX)
        self.m_pNamePanel:setPositionX(NPCChatDialogUI.NamePosX)
        self.m_pDescLabel:setPositionX(NPCChatDialogUI.DescPosX)

        self.m_pUpBgImg:setPositionY(NPCChatDialogUI.UpImgPosY)
        self.m_pDownBgImg:setPositionY(NPCChatDialogUI.DownImgPosY)
    end


    -- NPCChatDialogUI.ImgPosX = self.m_pNPCImg:getPositionX()
    -- NPCChatDialogUI.NamePosX = self.m_pNamePanel:getPositionX()
    -- NPCChatDialogUI.DescPosX = self.m_pDescLabel:getPositionX()

    -- NPCChatDialogUI.UpImgPosY = self.m_pUpBgImg:getPositionY()
    -- NPCChatDialogUI.DownImgPosY = self.m_pDownBgImg:getPositionY()

    self._VecChatData = {}       --对话列表
    self._IsAnimating = true       --正在播放动画状态
    self._IsAlive = true           --是否结束

    self._LastSecs = 3          --倒计时时间
    self._DoRequest = false         --是否发起请求
    self.m_headRes = nil
    self._canTouch = true
    self:ResetShow()
    self._IsTimerBegin = false           --是否结束
    self._curDec = ""

end 

function NPCChatDialogUI:ResetShow()
    if self.m_pNPCImg ~= nil then
        self.m_pNPCImg:setVisible(false)
    end
    if self.m_pSkipLabel ~= nil then
        self.m_pSkipLabel:setVisible(false)
    end
    if self.m_pSkipBtn ~= nil then
        self.m_pSkipBtn:setVisible(false)
    end
    if self.m_pDescLabel ~= nil then
        self.m_pDescLabel:setVisible(false)
    end
    if self.m_pNamePanel ~= nil then
        self.m_pNamePanel:setVisible(false)
    end
end

function NPCChatDialogUI:DoAnimation()
    self._IsAnimating = true       --正在播放动画状态
    self._LastSecs = 3          --倒计时时间
    self:ResetShow()
    self.m_pUpBgImg:setPositionY(AppDef.frameSize.height)
    self.m_pDownBgImg:setPositionY(0)

    local function AnimateEnd()
        self:AnimatePlayEnd()
    end
    local upMoveTo = cc.MoveTo:create(0.5,cc.p(self.m_pUpBgImg:getPositionX(),NPCChatDialogUI.UpImgPosY))
    self.m_pUpBgImg:runAction(upMoveTo)
    local downMoveTo = cc.MoveTo:create(0.5,cc.p(self.m_pDownBgImg:getPositionX(),NPCChatDialogUI.DownImgPosY))
    local sequence = cc.Sequence:create(downMoveTo, cc.CallFunc:create(AnimateEnd))
    self.m_pDownBgImg:runAction(sequence)
end

function NPCChatDialogUI:RequestChatData(sender)
    LuaNetSendMsg:QueryNpcChatOption(0)
    self._DoRequest = true
    self._LastSecs = 3
end

function NPCChatDialogUI:ClickToNext(sender)
    --print("ClickToNext")
    --传消息或者显示下一个
    if #self._VecChatData <= 0 then
        self:UnSchedule()
        self._IsTimerBegin = false
        self:DeleteUI()
        return
    end

    local ChatData = self._VecChatData[1]
    if #self._VecChatData == 1 then--结束
        self:RequestChatData(sender)
        self:UnSchedule()
        self._IsTimerBegin = false
        table.remove(self._VecChatData,1)
        -- ChatData:Delete()
        self._IsAlive = false
        self:ResetShow()
        self._IsAnimating = true

        local function AnimateEnd()
            self:AnimatePlayEnd()
        end
        local upMoveTo = cc.MoveTo:create(0.5,cc.p(self.m_pUpBgImg:getPositionX(),AppDef.frameSize.height))
        self.m_pUpBgImg:runAction(upMoveTo)
        local downMoveTo = cc.MoveTo:create(0.5,cc.p(self.m_pDownBgImg:getPositionX(),0))
        local sequence = cc.Sequence:create(downMoveTo, cc.CallFunc:create(AnimateEnd))
        self.m_pDownBgImg:runAction(sequence)
    else
        table.remove(self._VecChatData,1)
        -- ChatData:Delete()
        if #self._VecChatData > 0 then
            self:UpdateINF()
        else
            self:RequestChatData(sender)
        end
    end
    self:DeleteRole()

end

function NPCChatDialogUI:AnimatePlayEnd()
  
    self._IsAnimating = false
    if #self._VecChatData > 0 then
        self:UpdateINF()      
        self.m_pSkipBtn:setVisible(true)  
        self.m_pSkipLabel:setVisible(true)
        local seq = cc.Sequence:create(cc.FadeTo:create(1.0,50),cc.FadeTo:create(1.0,255))
        local rep = cc.RepeatForever:create(seq)
        self.m_pSkipBtn:stopAllActions()
        self.m_pSkipBtn:runAction(rep)
        seq = cc.Sequence:create(cc.FadeTo:create(1.0,50),cc.FadeTo:create(1.0,255))
        rep = cc.RepeatForever:create(seq)
        self.m_pSkipLabel:stopAllActions()
        self.m_pSkipLabel:runAction(rep)
        -- --创建点击继续按钮
        -- if(!this->getChildByTag(TAG_SPR_GOON))
        -- {
        --     CCSize frameSize = CC_WINSIZE;
        --     if (frameSize.width < 960)
        --     {
        --         frameSize.width = 960;
        --     }
        --     if (frameSize.height < 640)
        --     {
        --         frameSize.height = 640;
        --     }
        --     CCSprite* sprGoOn = CCSprite::create("UI/PlotContinue.mydp");
        --     sprGoOn->setPosition(ccp(frameSize.width - 100,565));
        --     sprGoOn->runAction(CCRepeatForever::create(CCSequence::create(AC_F2(1.0f,50), AC_F2(1.0f,255),NULL)));
        --     this->addChild(sprGoOn,3,TAG_SPR_GOON);

        --     --开启倒计时
        --     schedule(schedule_selector(PlotChatLayer::AutoEndUpdate), 1.0f, 999, 4.0f);
        -- }
    end
    
    --判断是否需要关闭
    if self._IsAlive == false then
        self:DeleteUI()
    end
end

function NPCChatDialogUI:DeleteUI()
    LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.PlotChatOver, self._isStageDialog)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Common.NPCChatDialogUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
end

function NPCChatDialogUI:UpdateUserData(data)
    local panel = self.m_pUILayer:getChildByName("DialogUI")
    --panel:setTouchEnabled(true)

    self._canTouch = true
    self._DoRequest = false
    self._dialogNum = 0
    self._isStageDialog = data.isStageDialog
    local dialogid = data.DialogueId
    local missionConfig = JsonConfig.m_missionConfig.getList()
    -- table.insert(self._VecChatData,data)

    for i=1, #missionConfig do
        if missionConfig[i].dialogid == dialogid then
            local missData = Utils:deepCopy(missionConfig[i])
            table.insert(self._VecChatData, missData)
            self._dialogNum = self._dialogNum + 1
        end
    end

    self:UpdateINF()
end

function NPCChatDialogUI:GetNpcBodyTexture(npcPicId)
    if npcPicId == 10000 then  --NPC
        return Utils:GetHeroIconRes(LRoleDataMgr.MyHeroInfo:GetModel(), AppDef.HeadIconResType.Body)
    else
        local configData = JsonConfig.m_NPCtemplate.getDefByID(npcPicId)
        if configData then
            local imgPath = "res2/Monster_Bust/" .. configData.picture.. ".png"
            return imgPath
        end 
    end
    return nil
end

function NPCChatDialogUI:DeleteRole()
    if self.m_pRole ~= nil then
        self.m_pRole:removeFromParent()
        self.m_pRole = nil
    end
end

function NPCChatDialogUI:UpdateINF()
    if self._IsAnimating == true then
        return
    end
    self._canTouch = true
    self:DeleteRole()
    self.m_pNamePanel:setScaleX(1)
    --先贴一张图
    self.m_pNPCImg:setVisible(true)
    self.m_pSkipLabel:setVisible(true)
    self.m_pSkipBtn:setVisible(true)
    self.m_pDescLabel:setVisible(true)
    self.m_pNamePanel:setVisible(true)

    local ChatData = self._VecChatData[1]
    local NameColor = cc.WHITE
    local frameSize = AppDef.frameSize

    local imgFilePath = self:GetNpcBodyTexture(ChatData.npcid)
    self.m_pNPCImg:setVisible(true)
    if ChatData.position == 0 then--NPC
        self.m_pNamePanel:setScaleX(1)
        self.m_pNameLabel:setScaleX(1)
        
        self.m_pNPCImg:setPositionX(NPCChatDialogUI.ImgPosX)
        self.m_pDescLabel:setAnchorPoint(cc.p(0,1))
        self.m_pDescLabel:setTextHorizontalAlignment(0)--左对齐
        self.m_pDescLabel:setPositionX(NPCChatDialogUI.DescPosX)
        self.m_pNamePanel:setPositionX(NPCChatDialogUI.NamePosX)
        NameColor = UICOLOR_BLUE_STROKE
    elseif ChatData.position == 2 then--玩家
        self.m_pDescLabel:setAnchorPoint(cc.p(1,1))
        -- print("1111111111111 ====>",NPCChatDialogUI.NamePosX, NPCChatDialogUI.DescPosX)
        self.m_pDescLabel:setTextHorizontalAlignment(0)--左对齐
        self.m_pDescLabel:setPositionX(frameSize.width - NPCChatDialogUI.DescPosX * 2)
        
        
        self.m_pNamePanel:setPositionX(frameSize.width - NPCChatDialogUI.NamePosX-(NPCChatDialogUI.NamePosX/2))--)


        self.m_pNamePanel:setScaleX(-1)
        self.m_pNameLabel:setScaleX(-1)
        -- self.m_pNPCImg:setAnchorPoint(cc.p(1,0))
        -- self.m_pNPCImg:setScaleX(0.8f)
        -- self.m_pNPCImg:setScaleY(0.8f)
        -- self.m_pNPCImg:setAnchorPoint(cc.p(1,0))
        self.m_pNPCImg:setPositionX(frameSize.width - NPCChatDialogUI.ImgPosX)
        NameColor = UICOLOR_YELLOW
    elseif ChatData.type == 1 then--旁白
        NameColor = UICOLOR_BLUE_STROKE
        self.m_pNPCImg:setVisible(false)
    end

    self:UnLoadHeadIcon()
    self.m_headRes = imgFilePath
    self.m_pNPCImg:setVisible(false)
    
    if self.m_headRes ~= nil then
        local function LoadImgComplete(tex)
            if self.m_pNPCImg == nil then
                return
            end
            self.m_pNPCImg:loadTexture(imgFilePath, ccui.TextureResType.localType)
            self.m_pNPCImg:setVisible(true)
            self.m_pNPCImg:ignoreContentAdaptWithSize(true)
        end
        LGameMsg.m_resMsg:Change(LResEvent.LoadImgSync, self.m_headRes, LoadImgComplete)
        self:SendMsg(LGameMsg.m_resMsg)
    end


    -- if imgFilePath ~= nil then
    --     self.m_pNPCImg:loadTexture(imgFilePath,ccui.TextureResType.localType)
    --     self.m_pNPCImg:ignoreContentAdaptWithSize(true)
    -- end

    if ChatData.npcid == 10000 then
        self.m_pNameLabel:setString(LRoleDataMgr.MyHeroInfo.name)
    else
        local configData = JsonConfig.m_NPCtemplate.getDefByID(ChatData.npcid)
        self.m_pNameLabel:setString(configData.name)
    end
    
    --self.m_pDescLabel:setString(ChatData.dialog)
    self.m_pNameLabel:setColor(NameColor)
    --ChatData.dialog = "[c5]竞技场[/c]每日可挑战[c7]次数[/c]增至[c3]8[/c]次,[c2]竞技场[/c]每日可挑战[c4]次数[/c]增至[c8]8[/c]次,[c6]竞技场[/c]每日可挑战[c10]次数[/c]增至[c9]8[/c]次.[c5]竞技场[/c]每日可挑战[c7]次数[/c]增至[c3]8[/c]次,[c2]竞技场[/c]每日可挑战[c4]次数[/c]增至[c8]8[/c]次,[c6]竞技场[/c]每日可挑战[c10]次数[/c]增至[c9]8[/c]次."
    -- if self.m_ttf ~= nil then
    --     self.m_ttf:removeFromParent()
    -- end
    self.m_ttf = self.m_pDescLabel:getChildByName("content")

    self._curDec = ChatData.dialog
    self:resetColdTime()
    --print("ChatData.dialog =", ChatData.dialog)
    if self.m_ttf == nil then
        self.m_ttf = self:CreateColorText(self.m_pDescLabel,self.m_pDescLabel,"content",ChatData.dialog)
    else
        --self.m_ttf:triggleInit(ChatData.dialog,self.m_pDescLabel:getContentSize(),-130,self.m_pDescLabel:getTextColor(),self.m_pDescLabel:getFontSize(),false,0,0,0,true,false)
        self.m_ttf:setString(ChatData.dialog)
    end
    self.m_ttf:setPosition(cc.p(0,self.m_pDescLabel:getContentSize().height))
    --self.m_ttf:setTag(1)
    if not self._IsTimerBegin then
        self:TimerCallBack()
        self._IsTimerBegin = true
    end
end

function NPCChatDialogUI:UnLoadHeadIcon()
    if self.m_headRes then
        LGameMsg.m_resMsg:Change(LResEvent.UnLoadImgSync, self.m_headRes)
        self:SendMsg(LGameMsg.m_resMsg)
        self.m_headRes = nil
    end
end

function NPCChatDialogUI:CreateColorText(parent, oldText, newName, strContent)
    
    local newText = CCAysLabel:createWithString(strContent,oldText:getContentSize().width,oldText:getFontSize(),oldText:getTextColor(),false)
    --newText:triggleInit(strContent,oldText:getContentSize(),-130,oldText:getTextColor(),oldText:getFontSize(),false,0,0,0,true,false)
    newText:setName(newName)
    --newText:setPosition(oldText:getPosition())
    newText:setAnchorPoint(cc.p(0,0))
    parent:addChild(newText)
    return newText
end

function NPCChatDialogUI:onExit()
    self:UnSchedule()
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
        -- self.m_pChatData:Delete()
        self.m_pChatData = nil
    end
    self.m_pChatData = nil
    self.m_pSkipBtn = nil
    self.m_pSkipLabel = nil
    self._VecChatData = nil
    self._curDec = nil
    self.m_pNamePanel = nil
    self.m_pUpBgImg = nil
    self.m_pNameLabel = nil
    self.m_pNPCImg = nil
    
    self.m_pDescLabel = nil
    self.m_pSkipBtn = nil
    self.m_pSkipLabel = nil
    self.m_pDownBgImg = nil
    self.m_ttf = nil
    self._canTouch = nil
end

function NPCChatDialogUI:AddTouchEvt()
    local panel = self.m_pUILayer:getChildByName("DialogUI")
    local function ExitCallback(sender)
       --sender:setTouchEnabled(false)
        if self._canTouch == false then
            return
        end
       self._canTouch = false
       self:ClickToNext(sender)
   end
   panel:addClickEventListener(ExitCallback)
    self:MarkIntaractCObj(panel)
   local function SkipCallback(sender)
    if self._canTouch == false then
            return
        end
        self._canTouch = false
       LuaNetSendMsg:SendSkipPlot()
       self:DeleteUI()
   end
   self.m_pSkipBtn:addClickEventListener(SkipCallback)
    self:MarkIntaractCObj(self.m_pSkipBtn)
   self.m_pSkipLabel:addClickEventListener(SkipCallback)
    self:MarkIntaractCObj(self.m_pSkipLabel)
end

function NPCChatDialogUI:RegisterGuide()
    --TODO:test data
    --------------------------------------------------------------------------
    -- local steps = {}
    -- table.insert(steps, GuideDef.StepId.Guide_TASK1)
    -- table.insert(steps, GuideDef.StepId.Guide_TASK1_1)
    -- table.insert(steps, GuideDef.StepId.Guide_TASK2)
    -- table.insert(steps, GuideDef.StepId.Guide_TASK2_1)
    -- for i=1,#steps do
    --     local data = LDataConstMgr:GetGuideData(steps[i])
    --     Utils:RegisterGuide(steps[i], nil, function()
    --         self:ClickToNext()
    --     end, data.deviant, true)
    -- end
end

function NPCChatDialogUI:TimerCallBack()
    local function UpdateCD()
        self:UpdateCoolTime()
    end
    self:UnSchedule()
    self:resetColdTime()

    if self.m_coldTime > 0 then
        self.m_schedulerID = Utils:schedule(nil, UpdateCD, 1, false)
    end
end

--对话中有空的,可以等到有值了,再更新
function NPCChatDialogUI:resetColdTime( ... )
    -- body
    local strLen = string.len(self._curDec)
    --print("strLen = ", strLen, self._curDec)
    if strLen < 1 then
        self.m_coldTime = 5
    else
        self.m_coldTime = math.floor(strLen / 3 / 6)
        if self.m_coldTime < 1 then
            self.m_coldTime = 1
        end
    end
end

function NPCChatDialogUI:UpdateCoolTime()
    self.m_coldTime = self.m_coldTime - 1
    --print("UpdateCoolTime", self.m_coldTime)
    if self.m_coldTime <= 0 then
        self:ClickToNext()
    end
end

function NPCChatDialogUI:UnSchedule()
    if self.m_schedulerID then
        Utils:unschedule(nil, self.m_schedulerID)
        self.m_schedulerID = nil
    end
end


return NPCChatDialogUI