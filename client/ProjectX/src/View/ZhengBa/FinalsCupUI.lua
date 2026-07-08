
local FinalsCupUI = LUIBase:New()
FinalsCupUI.__index = FinalsCupUI
--local this = LTcpSocket
function FinalsCupUI:New()
	local o = LUIBase:New()
	setmetatable(o,FinalsCupUI)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function FinalsCupUI:RegistMsgs()
    self.msgIds = 
    {
        LUIWeiWoDuXianEvent.WWDXBetDialogEvent,
        LUIWeiWoDuXianEvent.WWDXUpdateBetData,
        LUIWeiWoDuXianEvent.WWDXUpdateAfterBetUI,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function FinalsCupUI:ProcessEvent(msg)
    if msg.msgId == LUIWeiWoDuXianEvent.WWDXBetDialogEvent then
        self:loadData(msg.value)
        self:updateUI()
    elseif msg.msgId == LUIWeiWoDuXianEvent.WWDXUpdateBetData then
        self:refrashBetUI(msg.value)
    elseif msg.msgId == LUIWeiWoDuXianEvent.WWDXUpdateAfterBetUI then
        self:CloseDialog()
    end
end

function FinalsCupUI:Init()
    self.m_pUILayer = cc.CSLoader:createNode("csd/zhengba_3.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:initControlUI()
end

function FinalsCupUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end


function FinalsCupUI:initControlUI( ... )
    -- body
    local panel = self.m_pUILayer:getChildByName("Panel")
----------------------------------------------------------------------
    local titleBg = panel:getChildByName("Bg"):getChildByName("TitleBg")
    local closeBtn = titleBg:getChildByName("Btn_close")
    local function closeEvent( sender )
        -- body
        self:CloseDialog()
    end
    closeBtn:addClickEventListener(closeEvent)
	self:MarkIntaractCObj(closeBtn) 
    local goldBg = titleBg:getChildByName("GoldBg")
    self._goldValue = goldBg:getChildByName("Value")

----------------------------------------------------------------------   
    local left = panel:getChildByName("Left")
    self._leftName = left:getChildByName("Name")
    self.leftImage = left:getChildByName("Image")
    self.leftImage:setTouchEnabled(true)
    local function leftQueryEvent( sender )
        -- body
        print("left event -----------")
        if self._nodeInfo._VecRoleId1 > 0 then
            LuaNetSendMsg:QueryOtherPlayer(self._nodeInfo._VecRoleId1, 1)
        end
    end
    self.leftImage:addClickEventListener(leftQueryEvent)
	self:MarkIntaractCObj(self.leftImage) 
    local baseImage = left:getChildByName("BaseImage")
    self._leftNode = baseImage:getChildByName("Node")
    self._leftVipImage = left:getChildByName("VIPImage")
    self._leftVipValue = self._leftVipImage:getChildByName("AtlasLabel")

    self._leftPower = left:getChildByName("Power")
    self._leftPowerValue = self._leftPower:getChildByName("Value")
    self._leftPrometText=left:getChildByName("Text_1")

    self._leftShenjiaValue = left:getChildByName("shenjia"):getChildByName("Value")
    self._leftRate = left:getChildByName("peilv"):getChildByName("Value")
    self.leftBetBtn = left:getChildByName("btn_xiazhu")
    self._leftConsume = left:getChildByName("bg_Consume"):getChildByName("Value")
    local function leftBetEvent( sender )
        -- body
		local myMoney = LRoleDataMgr.MyHeroInfo.DetailData:getMoney()
        if self._nodeInfo.VoteMoney > myMoney then
            --Utils:ShowScrollTips(GUITips.RSI_CROSSSERVER_TIPS_23)
			Utils:ShowGoldTips(AppDef.AwrdItem.AWRD_ITEM_COIN)
            return
        end
        if self._nodeInfo._VecRoleId1 > 0 then
            self._voteTag = 1
            LuaNetSendMsg:QueryWWDXBet(self._nodeInfo.type, self._nodeInfo.nodeIdx, self._nodeInfo._VecRoleId1)
        end
        

    end
    self.leftBetBtn:addClickEventListener(leftBetEvent)
	self:MarkIntaractCObj(self.leftBetBtn) 
    self._leftWin = left:getChildByName("Win")
----------------------------------------------------------------------
    local right = panel:getChildByName("Right")
    self._rightName = right:getChildByName("Name")
    self.rightImage = right:getChildByName("Image")
    self.rightImage:setTouchEnabled(true)
    local function rightQueryEvent( sender )
        -- body
        local myMoney = LRoleDataMgr.MyHeroInfo.DetailData:getMoney()
        if self._nodeInfo.VoteMoney > myMoney then
            Utils:ShowScrollTips(GUITips.RSI_TIANYUANZHENGBA_TIPS_23)
            return
        end
        if self._nodeInfo._VecRoleId2 > 0 then
            LuaNetSendMsg:QueryOtherPlayer(self._nodeInfo._VecRoleId2, 1)
        end
        
    end
    self.rightImage:addClickEventListener(rightQueryEvent)
	self:MarkIntaractCObj(self.rightImage) 

    local baseNode = right:getChildByName("BaseImage")
    self._rightNode = baseNode:getChildByName("Node")
    self._rightVipImage = right:getChildByName("VIPImage")
    self._rightVipValue = self._rightVipImage:getChildByName("AtlasLabel")
    self._rightPrometText=right:getChildByName("Text_1")
    self._rightPower = right:getChildByName("Power")
    self._rightPowerValue = self._rightPower:getChildByName("Value")

    self._rightShenJiaValue = right:getChildByName("shenjia"):getChildByName("Value")
    self._rightRate = right:getChildByName("peilv"):getChildByName("Value")
    self.rightBetBtn = right:getChildByName("btn_xiazhu")
    local text = self.rightBetBtn:getChildByName("Text")
    self._rightConsume = right:getChildByName("bg_Consume"):getChildByName("Value")
    local function rightBetEvent( sender )
        -- body
        local myMoney = LRoleDataMgr.MyHeroInfo.DetailData:getMoney()
        if self._nodeInfo.VoteMoney > myMoney then
            --Utils:ShowScrollTips(GUITips.RSI_CROSSSERVER_TIPS_23)
			Utils:ShowGoldTips(AppDef.AwrdItem.AWRD_ITEM_COIN)
            return
        end
        if self._nodeInfo._VecRoleId2 > 0 then
            self._voteTag = 2
            LuaNetSendMsg:QueryWWDXBet(self._nodeInfo.type, self._nodeInfo.nodeIdx, self._nodeInfo._VecRoleId2)
        end
    end
    self.rightBetBtn:addClickEventListener(rightBetEvent)
	self:MarkIntaractCObj(self.rightBetBtn) 
    self._rightWin = right:getChildByName("Win")
----------------------------------------------------------------------
    self._result = panel:getChildByName("Result")

end

function FinalsCupUI:loadData(info)
    -- body
    self._nodeInfo = info

end

function FinalsCupUI:updateUI()
    -- body

    if self._nodeInfo  == nil then
        return
    end

    if self._nodeInfo.canVote == 0 then

        self.leftBetBtn:setTouchEnabled(false)
        self.leftBetBtn:setBright(false)

        self.rightBetBtn:setTouchEnabled(false)
        self.rightBetBtn:setBright(false)

        if self._nodeInfo.voteId > 0 then
            if self._nodeInfo.voteId == self._nodeInfo._VecRoleId1 then
                local text = self.leftBetBtn:getChildByName("Text")
                text:setString(GUITips.RIS_LEFTUI_MSG177)
            elseif self._nodeInfo.voteId == self._nodeInfo._VecRoleId2 then
                local text = self.rightBetBtn:getChildByName("Text")
                text:setString(GUITips.RIS_LEFTUI_MSG177)
            end
        end
    end

    self._leftName:setString(self._nodeInfo.name1)
    self._rightName:setString(self._nodeInfo.name2)

    if self._nodeInfo.professional1 ~= nil then
        local pLRoleModel = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, self._nodeInfo.professional1)
        self._leftNode:addChild(pLRoleModel)
        pLRoleModel:PlayStand(0)
    end

    self._leftPowerValue:setString(Utils:getPowerStr(self._nodeInfo.power1))
    self._rightPowerValue:setString(Utils:getPowerStr(self._nodeInfo.power2))
   
    if self._nodeInfo.professional2 ~= nil then
        local pRightRoleModel = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, self._nodeInfo.professional2)
        self._rightNode:addChild(pRightRoleModel)
        pRightRoleModel:PlayStand(0)
    end
    
    self._leftRate:setString(string.format("%.2f",self._nodeInfo.ratio1/100))
    self._rightRate:setString(string.format("%.2f",self._nodeInfo.ratio2/100))

    self._leftShenjiaValue:setString(self._nodeInfo.shenjia1)
    self._rightShenJiaValue:setString(self._nodeInfo.shenjia2)

    if self._nodeInfo._VecRoleId1 == self._nodeInfo.winerId then
        self._leftWin:setVisible(true)
        self._rightWin:setVisible(false)
    elseif self._nodeInfo._VecRoleId2 == self._nodeInfo.winerId then
        self._leftWin:setVisible(false)
        self._rightWin:setVisible(true)
    else
        self._leftWin:setVisible(false)
        self._rightWin:setVisible(false)
    end  
     
    if self._nodeInfo._VecRoleId1<=0 then
        self._leftPrometText:setVisible(true) 
        self._leftPower:setVisible(false)
    end
    if self._nodeInfo._VecRoleId2 <=0 then
        self._rightPrometText:setVisible(true) 
        self._rightPower:setVisible(false)
      
    end


    local strResult = string.format("%d:%d", self._nodeInfo.score1, self._nodeInfo.score2)
    self._result:setString(strResult)

    local myMoney = Utils:getGoldStr()
    self._goldValue:setString(myMoney)

    self._leftConsume:setString(self._nodeInfo.VoteMoney)
    self._rightConsume:setString(self._nodeInfo.VoteMoney)
    
end

function FinalsCupUI:refrashBetUI( betData )
    -- body
    self._nodeInfo.type = betData.type
    self._nodeInfo.nodeIdx = betData.nodeIdx
    if betData.voteId > 0 then
        self._nodeInfo.shenjia1 = betData.shenjia1
        self._nodeInfo.shenjia2 = betData.shenjia2
        self._leftShenjiaValue:setString(self._nodeInfo.shenjia1)
        self._rightShenJiaValue:setString(self._nodeInfo.shenjia2)
    end

    local myMoney = Utils:getGoldStr()
    self._goldValue:setString(myMoney)

    self:UpdateAfterBetUI()
end

function FinalsCupUI:UpdateAfterBetUI()
    if self._voteTag == nil then
        return
    end

    if self._voteTag == 1 then
        local leftText = self.leftBetBtn:getChildByName("Text")
        leftText:setString(GUITips.RIS_LEFTUI_MSG177)
        self.leftBetBtn:setTouchEnabled(false)
        self.leftBetBtn:setBright(false)
        self.rightBetBtn:setTouchEnabled(false)
        self.rightBetBtn:setBright(false)
    else
        local text = self.rightBetBtn:getChildByName("Text")
        text:setString(GUITips.RIS_LEFTUI_MSG177)
        self.rightBetBtn:setTouchEnabled(false)
        self.rightBetBtn:setBright(false)
        self.leftBetBtn:setTouchEnabled(false)
        self.leftBetBtn:setBright(false)
    end
end

function FinalsCupUI:CloseDialog( ... )
    -- body
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "ZhengBa.FinalsCupUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
end

return FinalsCupUI