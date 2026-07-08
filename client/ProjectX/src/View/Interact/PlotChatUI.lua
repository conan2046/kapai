--[[
NPC对话
]]

local PlotChatUI = LUIBase:New()
PlotChatUI.__index = PlotChatUI
PlotChatUI.IsHideInBattle = true

PlotChatUI.ImgPosX = nil
PlotChatUI.NamePosX = nil
PlotChatUI.DescPosX = nil
PlotChatUI.UpImgPosY = nil
PlotChatUI.DownImgPosY = nil
function PlotChatUI:New(chatData)
	local o = LUIBase:New()
	setmetatable(o,PlotChatUI)	
    o:Init(chatData)
	return o
end

--[[
注册消息
]]
function PlotChatUI:RegistMsgs()
    -- self.msgIds = 
    -- {
    --     -- LUILoginEvent.RecvCheckHeroName,
    --     -- LUILoginEvent.RecvServerList,
    --     -- LUILoginEvent.RecvRoleServerList,
    --     -- LUILoginEvent.LoginSuccess,
    -- }
    -- self:RegistSelf(self,self.msgIds)
end

function PlotChatUI:ProcessEvent(msg)
--    if msg.msgId == LUILoginEvent.RecvCheckHeroName then
--        self:SaveRandomName(msg.value)
--    end
end

function PlotChatUI:Init(chatData)
    self:RegistMsgs()
    self:CreateUINode("csd/DialogLayer.csb")
    -- self.m_pUILayer = cc.CSLoader:createNode("csd/DialogLayer.csb")
    -- local frameSize = cc.Director:getInstance():getVisibleSize()
    -- self.m_pUILayer:setContentSize(frameSize)
    -- ccui.Helper:doLayout(self.m_pUILayer)
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

function PlotChatUI:InitData()
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

    if PlotChatUI.ImgPosX == nil then
        PlotChatUI.ImgPosX = self.m_pNPCImg:getPositionX()
        PlotChatUI.NamePosX = self.m_pNamePanel:getPositionX()
        PlotChatUI.DescPosX = self.m_pDescLabel:getPositionX()

        PlotChatUI.UpImgPosY = self.m_pUpBgImg:getPositionY()
        PlotChatUI.DownImgPosY = self.m_pDownBgImg:getPositionY()
    else
        self.m_pNPCImg:setPositionX(PlotChatUI.ImgPosX)
        self.m_pNamePanel:setPositionX(PlotChatUI.NamePosX)
        self.m_pDescLabel:setPositionX(PlotChatUI.DescPosX)

        self.m_pUpBgImg:setPositionY(PlotChatUI.UpImgPosY)
        self.m_pDownBgImg:setPositionY(PlotChatUI.DownImgPosY)
    end


    -- PlotChatUI.ImgPosX = self.m_pNPCImg:getPositionX()
    -- PlotChatUI.NamePosX = self.m_pNamePanel:getPositionX()
    -- PlotChatUI.DescPosX = self.m_pDescLabel:getPositionX()

    -- PlotChatUI.UpImgPosY = self.m_pUpBgImg:getPositionY()
    -- PlotChatUI.DownImgPosY = self.m_pDownBgImg:getPositionY()

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

function PlotChatUI:ResetShow()
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

function PlotChatUI:DoAnimation()
    self._IsAnimating = true       --正在播放动画状态
    self._LastSecs = 3          --倒计时时间
    self:ResetShow()
    self.m_pUpBgImg:setPositionY(AppDef.frameSize.height)
    self.m_pDownBgImg:setPositionY(0)

    local function AnimateEnd()
        self:AnimatePlayEnd()
    end
    local upMoveTo = cc.MoveTo:create(0.5,cc.p(self.m_pUpBgImg:getPositionX(),PlotChatUI.UpImgPosY))
    self.m_pUpBgImg:runAction(upMoveTo)
    local downMoveTo = cc.MoveTo:create(0.5,cc.p(self.m_pDownBgImg:getPositionX(),PlotChatUI.DownImgPosY))
    local sequence = cc.Sequence:create(downMoveTo, cc.CallFunc:create(AnimateEnd))
    self.m_pDownBgImg:runAction(sequence)

    --  CCSize frameSize = CC_WINSIZE;
    -- if (frameSize.width < 960)
    -- {
    --     frameSize.width = 960;
    -- }
    -- if (frameSize.height < 640)
    -- {
    --     frameSize.height = 640;
    -- }
    -- --创建背景
    -- CCScale9Sprite *bgSpr = CCScale9Sprite::create("UI/BlackBkg.mydp");
    -- bgSpr->setAnchorPoint(ccp(0,0));
    -- bgSpr->setPreferredSize(frameSize);
    -- bgSpr->setPosition(ccp(0,0));
    -- this->addChild(bgSpr);

    -- --创建黑幕
    -- CCScale9Sprite *topSpr = CCScale9Sprite::create("UI/BlackBkg_top.mydp");
    -- topSpr->setPreferredSize(CCSizeMake(frameSize.width,110));
    -- topSpr->setTag(TAG_BLACK_MASK);
    -- topSpr->setAnchorPoint(ccp(0,1));
    -- topSpr->setPosition(ccp(0,frameSize.height+110));
    -- CCMoveTo *topMove = CCMoveTo::create(0.5f,ccp(0,frameSize.height));
    -- topSpr->runAction(topMove);
    -- this->addChild(topSpr,1);

    -- --中间花纹
    -- CCSprite *topHua = CCSprite::create("UI/Plot_hua.mydp");
    -- topHua->setAnchorPoint(ccp(0.5,0));
    -- topHua->setPosition(ccp(frameSize.width/2,0));
    -- topSpr->addChild(topHua,2);
    
    -- --建线条
    -- CCScale9Sprite *topLine = CCScale9Sprite::create("UI/Plot_xian.mydp");
    -- topLine->setPreferredSize(CCSizeMake(frameSize.width,1));
    -- topLine->setAnchorPoint(ccp(0,0));
    -- topSpr->addChild(topLine,2);

    -- CCScale9Sprite *bottomSpr = CCScale9Sprite::create("UI/BlackBkg_bottom.mydp");
    -- bottomSpr->setPreferredSize(CCSizeMake(frameSize.width,160));
    -- bottomSpr->setAnchorPoint(ccp(0,0));
    -- bottomSpr->setTag(TAG_BOTTOM_BG);
    -- bottomSpr->setPosition(ccp(0,-160));
    -- CCMoveTo *bottomMove = CCMoveTo::create(0.5f,ccp(0,0));
    -- CCCallFuncN *AnimateEnd = CCCallFuncN::create(this,(SEL_CallFuncN)&PlotChatLayer::AnimatePlayEnd);
    -- bottomSpr->runAction(CCSequence::create(bottomMove,AnimateEnd,NULL));
    -- this->addChild(bottomSpr,1);

    -- --停止人物移动
    -- GAMELAYER->GetGameMap()->StopHeroMove();
    -- if(DATA_MGR->Hero.MyHeroInfo.ConvoyType == 2 && DATA_MGR->Hero.MyHeroInfo.IsAutoConvoy)--自动运镖状态切换手动状态
    --     if(GameMenu* menu = GAMELAYER->GetMainMenuLayer())
    --         menu->ChangeConvoyBtnState(NULL);
end

function PlotChatUI:RequestChatData(sender)
    LuaNetSendMsg:QueryNpcChatOption(0)
    self._DoRequest = true
    self._LastSecs = 3
    -- unschedule(schedule_selector(PlotChatLayer::AutoEndUpdate));
    -- schedule(schedule_selector(PlotChatLayer::AutoEndUpdate), 1.0f);
end

function PlotChatUI:ClickToNext(sender)
    ----print("ClickToNext")
    --传消息或者显示下一个
    if #self._VecChatData <= 0 then
        self:RequestChatData(sender)
--        --print("1111111111111111111111")
        self:UnSchedule()
        self._IsTimerBegin = false
        return
    end

    local ChatData = self._VecChatData[1]
    if ChatData.op == 3 then--结束
        self:RequestChatData(sender)
--        --print("2222222222222222222222")
        self:UnSchedule()
        self._IsTimerBegin = false
        table.remove(self._VecChatData,1)
        ChatData:Delete()
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
        ChatData:Delete()
        if #self._VecChatData > 0 then
            self:UpdateINF()
        else
            self:RequestChatData(sender)
        end
    end
    self:DeleteRole()

end

function PlotChatUI:AnimatePlayEnd()
  
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

function PlotChatUI:DeleteUI()
    LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.PlotChatModel, false)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Interact.PlotChatUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
end

function PlotChatUI:UpdateUserData(data)
    local panel = self.m_pUILayer:getChildByName("DialogUI")
    --panel:setTouchEnabled(true)

    self._canTouch = true
    self._DoRequest = false
    table.insert(self._VecChatData,data)
    self:UpdateINF()
end

function PlotChatUI:GetNpcBodyTexture(npcType, npcPicId)
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

function PlotChatUI:DeleteRole()
    if self.m_pRole ~= nil then
        self.m_pRole:removeFromParent()
        self.m_pRole = nil
    end
end

function PlotChatUI:UpdateINF()
    if self._IsAnimating == true then
        return
    end
    self._canTouch = true
    self:DeleteRole()
    self.m_pNamePanel:setScaleX(1)
    self.m_pNameLabel:setScaleX(1)
    --先贴一张图
    self.m_pNPCImg:setVisible(true)
    self.m_pSkipLabel:setVisible(true)
    self.m_pSkipBtn:setVisible(true)
    self.m_pDescLabel:setVisible(true)
    self.m_pNamePanel:setVisible(true)

    local ChatData = self._VecChatData[1]
    local NameColor = cc.WHITE
    local frameSize = AppDef.frameSize
    local imgFilePath = self:GetNpcBodyTexture(ChatData.type, ChatData.picId)
    self.m_pNPCImg:setVisible(true)
    if ChatData.type == 0 then--NPC
        self.m_pNPCImg:setPositionX(PlotChatUI.ImgPosX)
        self.m_pDescLabel:setAnchorPoint(cc.p(0,1))
        self.m_pDescLabel:setTextHorizontalAlignment(0)--左对齐
        self.m_pDescLabel:setPositionX(PlotChatUI.DescPosX)
        self.m_pNamePanel:setPositionX(PlotChatUI.NamePosX)
        NameColor = UICOLOR_BLUE_STROKE
    elseif ChatData.type == 1 then--玩家
        self.m_pDescLabel:setAnchorPoint(cc.p(1,1))
        self.m_pDescLabel:setTextHorizontalAlignment(0)--左对齐
        self.m_pDescLabel:setPositionX(frameSize.width - PlotChatUI.DescPosX)
        self.m_pNamePanel:setPositionX(frameSize.width - PlotChatUI.NamePosX)
        self.m_pNamePanel:setScaleX(-1)
        self.m_pNameLabel:setScaleX(-1)
        -- self.m_pNPCImg:setAnchorPoint(cc.p(1,0))
        -- self.m_pNPCImg:setScaleX(0.8f)
        -- self.m_pNPCImg:setScaleY(0.8f)
        -- self.m_pNPCImg:setAnchorPoint(cc.p(1,0))
        self.m_pNPCImg:setPositionX(frameSize.width - PlotChatUI.ImgPosX)
        NameColor = UICOLOR_YELLOW
    elseif ChatData.type == 2 then--怪物
        self.m_pDescLabel:setAnchorPoint(cc.p(0,1))
        self.m_pDescLabel:setTextHorizontalAlignment(0)--左对齐
        self.m_pNPCImg:setPositionX(PlotChatUI.ImgPosX)
        self.m_pDescLabel:setPositionX(PlotChatUI.DescPosX)
        self.m_pNamePanel:setPositionX(PlotChatUI.NamePosX)
        NameColor = UICOLOR_BLUE_STROKE
    elseif ChatData.type == 3 then--坐骑
        self.m_pNPCImg:setPositionX(PlotChatUI.ImgPosX)
        self.m_pDescLabel:setAnchorPoint(cc.p(0,1))
        self.m_pDescLabel:setTextHorizontalAlignment(0)--左对齐
        self.m_pDescLabel:setPositionX(PlotChatUI.DescPosX)
        self.m_pNamePanel:setPositionX(PlotChatUI.NamePosX)
        NameColor = UICOLOR_BLUE_STROKE
    elseif ChatData.type == 9 then--旁白
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

    self.m_pNameLabel:setString(ChatData.Name)
    --self.m_pDescLabel:setString(ChatData.Desc)
    self.m_pNameLabel:setColor(NameColor)
    --ChatData.Desc = "[c5]竞技场[/c]每日可挑战[c7]次数[/c]增至[c3]8[/c]次,[c2]竞技场[/c]每日可挑战[c4]次数[/c]增至[c8]8[/c]次,[c6]竞技场[/c]每日可挑战[c10]次数[/c]增至[c9]8[/c]次.[c5]竞技场[/c]每日可挑战[c7]次数[/c]增至[c3]8[/c]次,[c2]竞技场[/c]每日可挑战[c4]次数[/c]增至[c8]8[/c]次,[c6]竞技场[/c]每日可挑战[c10]次数[/c]增至[c9]8[/c]次."
    -- if self.m_ttf ~= nil then
    --     self.m_ttf:removeFromParent()
    -- end
    self.m_ttf = self.m_pDescLabel:getChildByName("content")

    self._curDec = ChatData.Desc
    self:resetColdTime()
    --print("ChatData.Desc =", ChatData.Desc)
    if self.m_ttf == nil then
        self.m_ttf = self:CreateColorText(self.m_pDescLabel,self.m_pDescLabel,"content",ChatData.Desc)
    else
        --self.m_ttf:triggleInit(ChatData.Desc,self.m_pDescLabel:getContentSize(),-130,self.m_pDescLabel:getTextColor(),self.m_pDescLabel:getFontSize(),false,0,0,0,true,false)
        self.m_ttf:setString(ChatData.Desc)
    end
    self.m_ttf:setPosition(cc.p(0,self.m_pDescLabel:getContentSize().height))
    --self.m_ttf:setTag(1)
    if not self._IsTimerBegin then
        self:TimerCallBack()
        self._IsTimerBegin = true
    end
end

function PlotChatUI:UnLoadHeadIcon()
    if self.m_headRes then
        LGameMsg.m_resMsg:Change(LResEvent.UnLoadImgSync, self.m_headRes)
        self:SendMsg(LGameMsg.m_resMsg)
        self.m_headRes = nil
    end
end

function PlotChatUI:CreateColorText(parent, oldText, newName, strContent)
    
    local newText = CCAysLabel:createWithString(strContent,oldText:getContentSize().width,oldText:getFontSize(),oldText:getTextColor(),false)
    --newText:triggleInit(strContent,oldText:getContentSize(),-130,oldText:getTextColor(),oldText:getFontSize(),false,0,0,0,true,false)
    newText:setName(newName)
    --newText:setPosition(oldText:getPosition())
    newText:setAnchorPoint(cc.p(0,0))
    parent:addChild(newText)
    return newText
end

function PlotChatUI:onExit()
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
        self.m_pChatData:Delete()
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

function PlotChatUI:AddTouchEvt()
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

function PlotChatUI:RegisterGuide()
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

function PlotChatUI:TimerCallBack()
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
function PlotChatUI:resetColdTime( ... )
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

function PlotChatUI:UpdateCoolTime()
    self.m_coldTime = self.m_coldTime - 1
    --print("UpdateCoolTime", self.m_coldTime)
    if self.m_coldTime <= 0 then
        self:ClickToNext()
    end
end

function PlotChatUI:UnSchedule()
    if self.m_schedulerID then
        Utils:unschedule(nil, self.m_schedulerID)
        self.m_schedulerID = nil
    end
end


return PlotChatUI