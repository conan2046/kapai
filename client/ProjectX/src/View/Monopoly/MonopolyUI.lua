local MonopolyUI = LUIBase:New()
MonopolyUI.__index = MonopolyUI
--local this = LTcpSocket
function MonopolyUI:New()
	local o = LUIBase:New()
	setmetatable(o,MonopolyUI)	
    o:Init()
	return o
end

local OPENAUTOLEVEL = 56  
--    local OPENAUTOLEVEL = 99

--[[
注册消息
]]
function MonopolyUI:RegistMsgs()
    self.msgIds = 
    {
        LUIMonopolyEvent.RoleMoveOver,
        LUIMonopolyEvent.RoleOnMove,
        LUIMonopolyEvent.updateMonopoly,
        LUIMonopolyEvent.recvRoleMove,
        LUIMonopolyEvent.recvRandomEvent,
        LUIMonopolyEvent.updateAwardUI,
        LUIMonopolyEvent.afterBattleUIMove,
        LUIMonopolyEvent.updateBattleUI,
        LUIMonopolyEvent.udaptePlayTimes,
        LUIMonopolyEvent.showBuyTicket,
        LUIMonopolyEvent.finishEvent,
        LUIMonopolyEvent.afterMoveEvent,
        LUILogicEvent.EnterBattle,
        LUILogicEvent.ExitBattle,
        LUIRoleDataChangeEvent.LvUp,
        LUIRoleDataChangeEvent.MoneyChanged,
        LUIRoleDataChangeEvent.TongBaoChanged,
        LUIRoleDataChangeEvent.TiliChanged,
    }
    self:RegistSelf(self,self.msgIds)
end


function MonopolyUI:ProcessEvent(msg)

    if msg.msgId == LUIMonopolyEvent.RoleMoveOver then
        self._EnterBtn:setTouchEnabled(true)
        self._EnterBtn:setBright(true)
        self._EnterBtn:setVisible(true)
        --移动完成协议
        print("ProcessEvent QueryMonopolyInfo 4")
        self._roleIsMoving = false
        LuaNetSendMsg:QueryMonopolyInfo(4)
        
    end

    if msg.msgId == LUIMonopolyEvent.RoleOnMove then
        self._EnterBtn:setTouchEnabled(true)
        self._EnterBtn:setBright(true)
        self._EnterBtn:setVisible(true)
        self._roleIsMoving = false
    end

    if msg.msgId == LUIMonopolyEvent.updateMonopoly then
        self:assignUiData();
    end

    if msg.msgId == LUIMonopolyEvent.recvRoleMove then
        self:updateMoveUI(msg.value);
    end

    if msg.msgId == LUIMonopolyEvent.afterBattleUIMove then
--战斗结束消息记录剩余步数,exitbattle后才开始走
        local temp = msg.value.destcell - self._num
        print("temp =", temp)
        if temp > 0 then
            self._afterFightStep = temp
        end
    end

    if msg.msgId == LUIMonopolyEvent.recvRandomEvent then
        local msgStr
        local stepNum = msg.value.targetPos - self._num
        if stepNum > 0 then
            msgStr = string.format(GUITips.RSI_MONOPOLY_RANDOMEVENT_FORWARD, stepNum)
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, msgStr)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
        elseif stepNum < 0 then
            msgStr = string.format(GUITips.RSI_MONOPOLY_RANDOMEVENT_BACKWARD, - stepNum)
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, msgStr)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
        else
            self:ShowBattleChatUI();
        end

        local function callback(node, value)
            -- body
            self._EnterBtn:setTouchEnabled(true)
            self._EnterBtn:setVisible(true)
            self._roleIsMoving = false
            self:randomEventAction(value.randomValue);
        end
--随机事件移动做一个延迟
        local delay = cc.DelayTime:create(2)
        local sequence = cc.Sequence:create(delay, cc.CallFunc:create(callback, {randomValue = msg.value}))
        self._EnterBtn:runAction(sequence)
        self._EnterBtn:setTouchEnabled(false)
        self._roleIsMoving = true
    end

    if msg.msgId == LUIMonopolyEvent.updateAwardUI then
        self:updateAwardUI(msg.value)
    end

    if msg.msgId == LUIMonopolyEvent.updateBattleUI then
        self:updateBattleUI(msg.value)
    end
    
    if msg.msgId == LUIMonopolyEvent.udaptePlayTimes then
        self:updateTimes(msg.value)
    end

    if msg.msgId == LUIMonopolyEvent.showBuyTicket then
        self:showBuyTicketUI(msg.value);
    end

    if msg.msgId == LUIMonopolyEvent.finishEvent then
        self._isFinish = true
        local leftTimes = self:getLeftPlayTimes()
        print("finishEvent leftTimes", leftTimes)
        if leftTimes > 1 then
            self:ShowNeedNextBattle()
        else
            self:ShowFinishAlert()
        end
    end
    
    if msg.msgId == LUIMonopolyEvent.afterMoveEvent then
        print("show Auto battle")
        self:ShowBattleChatUI();
    end

    if msg.msgId == LUILogicEvent.EnterBattle then
        self._isInBattle = true
        self.m_pUILayer:setVisible(false)
    end

    if msg.msgId == LUILogicEvent.ExitBattle then
        self._isInBattle = false
        self.m_pUILayer:setVisible(true)
        --退出战斗,走完剩下的步数
--        print("self._afterFightStep 2222222222222========>", self._afterFightStep)
        if self._afterFightStep and self._afterFightStep > 0 then
            LRechargeDataMgr.isShowBattleChatNow = false
            self._EnterBtn:setTouchEnabled(true)
            self._EnterBtn:setVisible(true)
            self._roleIsMoving = false
            self:RoleMove(self._afterFightStep);
            self._afterFightStep = 0
        else
--            print("退出战斗,没有剩下的步数要走==========================>")
            LRechargeDataMgr.isShowBattleChatNow = false
            self._roleIsMoving = false
            self._afterFightStep = 0
            if LRechargeDataMgr.isMonopolyBattleWin then
                self:execAutoSaiZiEvent(true)
                LRechargeDataMgr.isMonopolyBattleWin = false
            end
        end
    elseif msg.msgId == LUIRoleDataChangeEvent.LvUp then
        local level = LRoleDataMgr.MyHeroInfo:Getlevel()
        if level >= OPENAUTOLEVEL then
            self._isAutoPlay:setVisible(true)
        else
            self._isAutoPlay:setVisible(true)
            self._isAutoPlay:setSelected(false)
        end
    elseif msg.msgId == LUIRoleDataChangeEvent.MoneyChanged then
        local myMoney = Utils:getGoldStr()
        self._Gold:setString(myMoney)
    elseif msg.msgId == LUIRoleDataChangeEvent.TongBaoChanged then
        local myGold = LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao()
        self._cash:setString(myGold)
    elseif msg.msgId == LUIRoleDataChangeEvent.TiliChanged then
        local myTili = LRoleDataMgr.MyHeroInfo:GetDetailData():getTili()
        print("LUIRoleDataChangeEvent.TiliChanged myTili ==>", myTili)
        self._TiLi:setString(Utils:getTiliStr(myTili))
    end
end

function MonopolyUI:getLeftPlayTimes()
    -- body
    return LActivityManager:getLeftMonopolyTimes()
end

function MonopolyUI:Init()
   
    self.m_pUILayer = cc.CSLoader:createNode("csd/kunlunxunbao/GameLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

   self:RegistMsgs()
   self:initUI();
   self._num = 1 --当前所在格子
   self._curStep = 0 --当前走了几步
   self._curSaiziNum = 0 -- 当前骰子
   self._isFinish = false --是否走到终点
   self._isInBattle = false --是否在战斗中
   --不遇怪
    LuaNetSendMsg:QueryCanBattle(2)

end

function MonopolyUI:onExit()
    self.m_pUILayer = nil
    self:UnSchedule()
    --恢复遇怪
    LuaNetSendMsg:QueryCanBattle(3)
    self._num = nil
    self._curStep = nil
    self._curSaiziNum = nil
    self._isFinish = nil
    self._isInBattle = nil
    self._EnterBtn = nil
    self._rollTimes = nil
    self.m_pCreateImod = nil
    self._animPos = nil
    self._killValue = nil

    -- self._expValue = nil
    self._coinValue = nil
    self._goldValue = nil
    self._roleIsMoving = nil
    self:Destory()
end

function MonopolyUI:initUI()
    local panel = self.m_pUILayer:getChildByName("Panel")
    panel:setSwallowTouches(false)

    -- 元宝 金币 体力
    local GoldCheck = panel:getChildByName("GoldCheck")
    self._cash = GoldCheck:findChildByName("GoldIcon4/GoldNumBg/Num")
    local cashAddBtn = GoldCheck:findChildByName("GoldIcon4/AddBtn")
    cashAddBtn:setEnabled(false)
    

    self._Gold =  GoldCheck:findChildByName("GoldIcon3/GoldNumBg/Num")
    local goldAddBtn = GoldCheck:findChildByName("GoldIcon3/AddBtn")
    goldAddBtn:addClickEventListener(function ( sender )
        Utils:OpenFunction(AppDef.EModuleID.EMID_SCCHANGYONG)
    end)

    self._TiLi = GoldCheck:findChildByName("GoldIcon1/GoldNumBg/Num")
    local tiliAddBtn = GoldCheck:findChildByName("GoldIcon1/AddBtn")
    tiliAddBtn:addClickEventListener(function ( sender )
        Utils:OpenUseUI(500,1)
    end)

    if LRoleDataMgr then
        local myMoney = LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao()
        self._cash:setString(myMoney)
        local myGold = Utils:getGoldStr();
        self._Gold:setString(myGold)
        local tili = LRoleDataMgr.MyHeroInfo:GetDetailData():getTili()
        self._TiLi:setString(Utils:getTiliStr(tili))
    end

    local title = panel:getChildByName("Title")
    local OutBtn = title:getChildByName("CloseBtn")
    local function OnOutButtonClick(sender)
        if self._roleIsMoving and self._EnterBtn:isVisible() then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, GUITips.RSI_MONOPOLY_ROLE_ISMOVING)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
        else
            self:closeMonopoly()
        end
    end
    OutBtn:addClickEventListener(OnOutButtonClick)
	self:MarkIntaractCObj(OutBtn)
--重置按钮
    local refrashBtn = panel:getChildByName("Refresh")
    self._refrashBtn = refrashBtn
    local function refrashEvent(sender)
        -- body
        self:ShowResetUI()
    end
    refrashBtn:addClickEventListener(refrashEvent)
	self:MarkIntaractCObj(refrashBtn)
    local btnPanel = panel:getChildByName("BtnPanel")
    self._EnterBtn = btnPanel:getChildByName("EnterBtn")
    local function OnEnterButtonClick(sender)
        self:execSaiziEvent(sender)
    end
    self._EnterBtn:addClickEventListener(OnEnterButtonClick)
	self:MarkIntaractCObj(self._EnterBtn)
    local  addBtn = btnPanel:getChildByName("Times"):getChildByName("AddBtn")
    local function buyShaiziTimes( sender )
        -- body
        LuaNetSendMsg:QueryMonopolyInfo(22) --购买次数
        --print("LuaNetSendMsg QueryMonopolyInfo")
    end
    addBtn:addClickEventListener(buyShaiziTimes)
	self:MarkIntaractCObj(addBtn)
    self._rollTimes = btnPanel:getChildByName("Times"):getChildByName("Value")

    self._isAutoPlay = btnPanel:getChildByName("CheckBox_1")
    local level = LRoleDataMgr.MyHeroInfo:Getlevel()
    local isAutoPlay = LUserConfigMgr:GetMonoPolyAutoPlay()
    if level >= OPENAUTOLEVEL then
        self._isAutoPlay:setVisible(true)
        self._isAutoPlay:setSelected(isAutoPlay)
    else
        self._isAutoPlay:setVisible(true)
        self._isAutoPlay:setSelected(false)
    end

    local function AutoPlayEvent( sender )
        -- body
        if level < OPENAUTOLEVEL then
            Utils:ShowScrollTips(GUITips.RSI_MONOPOLY_AUTOPLAY)
            sender:setSelected(true)
            return
        end
        local isSelected = sender:isSelected()
        print("AutoPlayEvent ====>", not isSelected)
        LUserConfigMgr:SetMonoPolyAutoPlay(not isSelected)
    end
    self._isAutoPlay:addClickEventListener(AutoPlayEvent)

--骰子动画
    self.m_pCreateImod = ImodAnim:create()
    local posX, posY = self._EnterBtn:getPosition()
    self._animPos = cc.p(posX - 350, posY + 130)
    self.m_pCreateImod:setPosition(self._animPos)
--    print("m_pCreateImod ************")
    btnPanel:addChild(self.m_pCreateImod, 5, 666);
    self.m_pCreateImod:setVisible(false)
    self.m_pCreateImod:SetSpeedScale(1 / 2)

    local killBg = panel:getChildByName("KillBg")
    self._killValue = killBg:getChildByName("Image"):getChildByName("Value")

    local reward = panel:getChildByName("Reward")
    local listView = reward:getChildByName("ListView")
    -- self._expValue = listView:getChildByName("EXP"):getChildByName("Value")
    self._coinValue = listView:getChildByName("Coin"):getChildByName("Value")
    self._goldValue = listView:getChildByName("Gold"):getChildByName("Value")
    self._kunlunValue = listView:getChildByName("kunlunbi"):getChildByName("Value")
    self._roleIsMoving = false

	local helpBtn = self.m_pUILayer:getChildByName("Panel"):getChildByName("Title"):getChildByName("TitleName"):getChildByName("btn_help")
    helpBtn:addClickEventListener(function ( sender )
        self:HelpClicked()
    end)
end

function MonopolyUI:HelpClicked(sender) 
    Utils:ShowDialogOKCancel(GUITips.KunLunXunBao)
end

function MonopolyUI:execSaiziEvent( sender )
    -- body

    --测试代码
    if self._roleIsMoving then
        return
    end

 --       self._num = self._num + 2
    if self._isFinish then
        -- self:ShowFinishAlert()
        return
    end

    if LRoleDataMgr.MonopolyData.roll_use <= 0 then
        LuaNetSendMsg:QueryMonopolyInfo(22) --购买次数
        return
    end


    LuaNetSendMsg:QueryMonopolyInfo(3) --骰子
    self._EnterBtn:setVisible(false)
    
--防止协议丢失,筛子消失的bug
    performWithDelay(self.m_pUILayer, function(sender)
        self._EnterBtn:setVisible(true)
    end, 1)

    self._roleIsMoving = true
--角色还原位置
    LGameMsg.m_baseMsgWithOne:Change(LUIMonopolyEvent.ResetRolePos)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

end

function MonopolyUI:assignUiData(  )
    -- body
    -- self:TimerCallBack();
    local str = string.format("%d/%d", LRoleDataMgr.MonopolyData.kill_monster, LRoleDataMgr.MonopolyData.monster_num)
    self._killValue:setString(str);
    -- self._expValue:setString(LRoleDataMgr.MonopolyData.exp)
    self._coinValue:setString(LRoleDataMgr.MonopolyData.coin)
    self._goldValue:setString(LRoleDataMgr.MonopolyData.gold)
    self._kunlunValue:setString(LRoleDataMgr.MonopolyData.exp) --换成了昆仑币
    -- local strRollTimes = string.format("%d/%d", LRoleDataMgr.MonopolyData.roll_use, LRoleDataMgr.MonopolyData.roll_max)
    self._rollTimes:setString(LRoleDataMgr.MonopolyData.roll_use)
    self._num = LRoleDataMgr.MonopolyData.curPos
    if self._num <= 0 then
        self._num = 1
    end
    self._isFinish = false
    self._roleIsMoving = false
    local leftTime = self:getLeftPlayTimes()
    local leftTimes = string.format(GUITips.RSI_XIULIAN_TIPS8, leftTime - 1)
    self._refrashBtn:getChildByName("Text"):setString(leftTimes)
end

function MonopolyUI:shaiziAni(stepNum, value)
    local function OnAniEndCallBack()
        --骰子动画
        self._EnterBtn:setVisible(true)
        if value > 6 or value < 1 then
            return
        end

        local  strNum = string.format("UI/shaizi_%d.png", value)
        -- self._EnterBtn:loadTextureNormal(strNum, ccui.TextureResType.localType)
        -- self._EnterBtn:loadTexturePressed(strNum, ccui.TextureResType.localType)
        self.m_pCreateImod:setVisible(false)


        local sp = cc.Sprite:create(strNum)
        local panel = self.m_pCreateImod:getParent()
        panel:addChild(sp)
        sp:setTag(1010)
        sp:setPosition(cc.p(self._animPos.x, self._animPos.y))

        local function afterFadeOut( sender )
            -- body
            sp:removeFromParent()
        end

        performWithDelay(AppDef.CurScene, function(sender)
            --开始播放
            if self.m_pUILayer == nil then
                return
            end
            local fadeAction = cc.FadeOut:create(0.5)
            local seq = cc.Sequence:create(fadeAction, cc.CallFunc:create(afterFadeOut))
            sp:runAction(seq)
        end, 2)


--步数为0,则不走
        self:RoleMove(stepNum)
    end

--骰子动画
    local pngStr = "UI/shaizi.png"
    local aniStr = "UI/shaizi.ani"
    self.m_pCreateImod:setVisible(true)
    self.m_pCreateImod:resetAniData()
    self.m_pCreateImod:initAnimWithName(pngStr, aniStr);
    self.m_pCreateImod:PlayAction(0)
    self.m_pCreateImod:registerScriptEndCBHandler(OnAniEndCallBack)

 --    local jump = cc.JumpBy:create(0.5, cc.p(0,80),30,1);
	-- local jump1 = cc.JumpBy:create(0.5, cc.p(0,-80),30,1);
	-- local seq = cc.Sequence:create(jump,jump1);
	-- self.m_pCreateImod:runAction(seq);

    local panel = self.m_pCreateImod:getParent()
    local lastShaizi =  panel:getChildByTag(1010)
    if lastShaizi then
        lastShaizi:setVisible(false)
    end

end

--角色移动
function MonopolyUI:RoleMove(stepNum)
    -- body
        self._curStep = stepNum
        if stepNum == 0 then
            return
        end
        self._EnterBtn:setTouchEnabled(false)
        self._num = self._num + stepNum
        LGameMsg.m_baseMsgWithOne:Change(LUIMonopolyEvent.RoleMove, self._num)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
        self._roleIsMoving = true
end

function MonopolyUI:updateMoveUI( value )
    -- body
    local strRollTimes = string.format("%d/%d", value.roll_use, value.roll_max)
    LRoleDataMgr.MonopolyData.roll_use = value.roll_use
    LRoleDataMgr.MonopolyData.roll_max = value.roll_max
    self._rollTimes:setString(value.roll_use)
    self:updateSeziAction(value);
end


function MonopolyUI:updateSeziAction(value)
    --掷骰子
    self._curSaiziNum = value.rollNum
    local stepNum = value.destcell - self._num
--    print("stepNum", stepNum)
    self:shaiziAni(stepNum, value.rollNum);
end


function MonopolyUI:randomEventAction(value)
    -- body

    if value == nil then
        return
    end

    if value.targetPos == 0 then
        return
    end
    self._EnterBtn:setTouchEnabled(false)
    self._roleIsMoving = true
    self._num = value.targetPos
    LGameMsg.m_baseMsgWithOne:Change(LUIMonopolyEvent.RoleMove, self._num)
    LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)

end

function MonopolyUI:TimerCallBack()
    local function UpdateCD()
		self:UpdateCoolTime()
	end
    self:UnSchedule()
    print("RoleDataMgr.MonopolyData.timediff", LRoleDataMgr.MonopolyData.timediff)
    self.m_coldTime =  LRoleDataMgr.MonopolyData.timediff;
    if self.m_coldTime > 0 then
        local scheduler =  AppDef.Director:getScheduler()
        self.m_schedulerID = scheduler:scheduleScriptFunc(UpdateCD, 1, false)
        self._inCDTime = true
    end
end

function MonopolyUI:UpdateCoolTime()
    -- local panelTemp = self.m_pUILayer:getChildByName("Panel")
    -- local timeTxt = panelTemp:getChildByName("OutBtn"):getChildByName("Time")
    -- self.m_coldTime = self.m_coldTime - 1;
    -- local hour = math.floor(self.m_coldTime / 3600)
    -- local minite = math.floor((self.m_coldTime % 3600) / 60)
    -- local sec = math.floor((self.m_coldTime % 3600) % 60)
    -- timeTxt:setString(string.format("%02d:%02d:%02d", hour, minite, sec))
    -- if self.m_coldTime <= 0 then
    --     self:UnSchedule()
    -- end
end

function MonopolyUI:UnSchedule()
    if self.m_schedulerID then
        AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_schedulerID)
        self.m_schedulerID = nil
    end
end

function MonopolyUI:updateAwardUI(info)
    -- body
    --得到奖励或者击杀小贼更新界面
    -- self._expValue:setString(info.exp)
    self._coinValue:setString(info.coin)
    self._goldValue:setString(info.gold)
    self._kunlunValue:setString(info.exp)
end

function MonopolyUI:updateBattleUI( info )
    -- body
    self._killValue:setString(string.format("%d/%d",info.curKill, info.maxKill))
end


function MonopolyUI:updateTimes(value)
    -- body
    LRoleDataMgr.MonopolyData.roll_use = value.curTimes
    -- local strRollTimes = string.format("%d/%d", value.curTimes, value.maxTimes)
    self._rollTimes:setString(value.curTimes)
end

function MonopolyUI:showBuyTicketUI(value)
    local function OKCallback()
--        --print("MonopolyUI:showBuyTicketUI", LRoleDataMgr.MonopolyData.roll_use, LRoleDataMgr.MonopolyData.roll_max)

        if LRoleDataMgr.MonopolyData.roll_use >= LRoleDataMgr.MonopolyData.roll_max then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, GUITips.Rsi_Tip_buyTimes_error)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
            return
        end

        local myTongo = LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao()
        if value.price > myTongo then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, GUITips.RSI_DSL_TIP_MIN)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
            return
        end          
        LuaNetSendMsg:QueryMonopolyInfo(21) --购买次数
    end

    local function cancelCallback()

    end

    Utils:ShowBuyTimesDialog(value.price * 10, value.useType, value.buyNum, value.maxBuyNum, OKCallback, cancelCallback)
end

function MonopolyUI:ShowBattleChatUI( ... )
    -- body
--刚好走到没有触发战斗
    print("MonopolyUI:ShowBattleChatUI curStep =", self._curStep, self._curSaiziNum, LRechargeDataMgr.isShowBattleChatNow)
    local pUserDefault = CCUserDefault:getInstance()
    local userId = LRoleDataMgr.MyHeroInfo.id
    local monopolyIsCanBattle = userId.."monopoly"
    if self._curStep == self._curSaiziNum or self._curStep < 0 then
--记录是否可以出发战斗
        pUserDefault:setBoolForKey(monopolyIsCanBattle, false)
        self:execAutoSaiZiEvent()
        return
    end

    pUserDefault:setBoolForKey(monopolyIsCanBattle, true)
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Interact.NPCChatUI")
    self:SendMsg(LGameMsg.m_initUIMsg)

    if self._num + 1 <= 0 then
        print()
        self:execAutoSaiZiEvent()
        return
    end

    if self._num + 1 > 82 then
        self:execAutoSaiZiEvent()
        return
    end

--    --print("self._num = ", self._num)
    --如果前方不是战斗类型则不处理
    local data =LRoleDataMgr.MonopolyData.cellData[self._num + 1]
    if data == nil or data.eventid ~= 2 then
        self:execAutoSaiZiEvent()
        return
    end

--    print("monopoly justShowBattleChatLayer 222222222222222222222======>")
    Utils:SendMsg(LUIMonopolyEvent.justShowBattleChatLayer)

    LRechargeDataMgr.isShowBattleChatNow = false
    

end

function MonopolyUI:execAutoSaiZiEvent( isAfterBattle )
    -- body
    -- --自动摇骰子
--    print("execAutoSaiZiEvent", self._curStep, LRechargeDataMgr.isShowBattleChatNow, self._isAutoPlay:isSelected())
    if not self._isAutoPlay:isSelected() then
        return
    end
    
    if isAfterBattle ~= nil and isAfterBattle then
        if not LRechargeDataMgr.isShowBattleChatNow then
--            print("execAutoSaiZiEvent =》》》》》》》》》》》》》》》》》》》》》》》")
            self:execSaiziEvent(self._EnterBtn)
        end
    else
        if self._curStep ~= 0 and not LRechargeDataMgr.isShowBattleChatNow then
--            print("execAutoSaiZiEvent =》》》》》》》》》》》》》》》》》》》》》》》")
            self:execSaiziEvent(self._EnterBtn)
        end
    end
    LRechargeDataMgr.isShowBattleChatNow = false
    
end

function MonopolyUI:ShowResetUI( ... )
    -- body
    local function okFunc()
        local leftTime = self:getLeftPlayTimes()
        print("=========== leftTime", leftTime)
        if leftTime > 1 then
            LuaNetSendMsg:QueryMonopolyInfo(8)
        else
            Utils:ShowScrollTips(GUITips.Rsi_Tip_Monopoly_reset)
        end
    end

    local function cancelFunc( ... )
        -- body
    end

    Utils:ShowDialogOKCancel(GUITips.RSI_MONOPOLY_REFRESH, okFunc, cancelFunc)
end

function MonopolyUI:ShowNeedNextBattle( ... )
    -- body
    local function okFunc()
        LuaNetSendMsg:QueryMonopolyInfo(15)
        LActivityManager:addMonopolyPlayTimes()
    end

    local function cancelFunc( ... )
        self:closeMonopoly()
        -- body
    end
    Utils:ShowDialogOKCancel(GUITips.RSI_MONOPOLY_PLAYAGAIN, okFunc, cancelFunc, nil, nil, nil, true)
end

function MonopolyUI:ShowFinishAlert( ... )
    -- body
    local function okFunc()
        self:closeMonopoly()
    end

    Utils:ShowDialogOKCancel(GUITips.RSI_MONOPOLY_FINISH_TADAY, okFunc)
end

function MonopolyUI:closeMonopoly()
    -- body
    LGameMsg.m_baseMsgWithOne:Change(LUIMsgBoxEvent.HideMsgBox)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Monopoly.MonopolyUI")
    self:SendMsg(LGameMsg.m_initUIMsg)

    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Monopoly.MonopolyBaseUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
end

 
return MonopolyUI