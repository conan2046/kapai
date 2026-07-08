
local PreliminnaryUI = LUIBase:New()
PreliminnaryUI.__index = PreliminnaryUI
--local this = LTcpSocket
function PreliminnaryUI:New()
	local o = LUIBase:New()
	setmetatable(o,PreliminnaryUI)	
    o:Init()
	return o
end

local CAN_CHECK = 1
local CAN_BET = 2
local TAG_FIXX = 1021
local GREEN = cc.c3b(0,250,0)

--注册事件
-- -----------------------------------
function PreliminnaryUI:RegistMsgs()
    self.msgIds = 
    {
        LUIWeiWoDuXianEvent.WWDXUIEvent,  --上半场,下半场面板
        LUIWeiWoDuXianEvent.WWDXUpdateBetData,
        LUIWeiWoDuXianEvent.WWDXFinalDataEvent,  --更新决赛面板你
        LUIWeiWoDuXianEvent.EnterWWDXBattleSuc,  --前往战场成功
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function PreliminnaryUI:ProcessEvent(msg)
    if msg.msgId == LUIWeiWoDuXianEvent.WWDXUIEvent then
        self:loadData(msg.value)
        self:updateUI()
    elseif msg.msgId == LUIWeiWoDuXianEvent.WWDXUpdateBetData then
        self:updateBetNodeInfo(msg.value)
    elseif msg.msgId == LUIWeiWoDuXianEvent.WWDXFinalDataEvent then
        self:updateFinalUI(msg.value)
    elseif msg.msgId == LUIWeiWoDuXianEvent.EnterWWDXBattleSuc then
        self:openBattleInfoUI()
        self:CloseDialog()
    end
end

function PreliminnaryUI:Init()

    self.m_pUILayer = cc.CSLoader:createNode("csd/zhengba_2.csb")
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
    self:initData()
end

function PreliminnaryUI:initData( ... )
    -- body
    self._curType = 0
end

function PreliminnaryUI:onExit()
    self.m_pUILayer = nil
    self._curType = nil
    self._CheckBox_1 = nil
    self._CheckBox_2 = nil
    self._CheckBox_3 = nil
    self._roadPanel = nil
    Utils:FreeTable(self._roundLine1)
    Utils:FreeTable(self._roundLine2)
    Utils:FreeTable(self._roundLine3)
    Utils:FreeTable(self._roundLine4)
    Utils:FreeTable(self._BetBtn1)
    Utils:FreeTable(self._queryBtn1)
    Utils:FreeTable(self._BetBtn2)
    Utils:FreeTable(self._queryBtn2)
    Utils:FreeTable(self._BetBtn3)
    Utils:FreeTable(self._queryBtn3)
    Utils:FreeTable(self._BetBtn4)
    Utils:FreeTable(self._queryBtn4)

    self._ChampionBg = nil
    self._image = nil
    self._ChampionIcon = nil
    self._ChampionName = nil
    self._ChampionLV = nil

----------------------------------------------------------------------
--总决赛面板
    self._zongjuesai = nil
    self._left = nil
    self._leftNameBg = nil
    self._leftName = nil

    self._leftNode = nil
    self._leftVipImage = nil
    self._leftVipValue = nil
    self._leftPowerBg = nil
    self._leftPower = nil
    self._leftDes = nil
    self._leftWin = nil
    self.leftImage = nil
    self._right = nil
    self._rightNameBg = nil
    self._rightName = nil
    self._rightNode = nil
    self._rightVipImage = nil
    self._rightVipValue = nil
    self._rightPowerBg = nil
    self._rightPower = nil
    self._rightDes = nil
    self._rightWin = nil
    self.rightImage = nil
    self._finalBetBtn = nil

    self._finalQueryBtn = nil
----------------------------------------------------------------------
--前往战场
    self._btn_qianwang = nil
    self._LoadingBar = nil
    Utils:FreeTable(self._nameTxt)
    self:Destory()
end

function PreliminnaryUI:initControlUI( ... )
    -- body
    local panel = self.m_pUILayer:getChildByName("Panel")
----------------------------------------------------------------------
    local title = panel:getChildByName("Title")
    local closeUIBtn = title:getChildByName("CloseBtn")
    local function closeEvent( sender )
        -- body
        self:CloseDialog()
    end
    closeUIBtn:addClickEventListener(closeEvent)
	self:MarkIntaractCObj(closeUIBtn) 
    local function CheckBoxClicked(sender)
        local ind = sender.userObject
--        print("CheckBoxClicked", petInd)
        self:changeScene(ind)
        LWWDXMgr.m_isNotNeedChangeMyPos = true
 --       print("updateBtnState ind = ", ind, LWWDXMgr.m_isCurLastMatch)
        LuaNetSendMsg:QueryWWDXFinalInfo(ind - 1, not LWWDXMgr.m_isCurLastMatch)

    end

    self._CheckBox_1 = title:getChildByName("CheckBox_1")
    self._CheckBox_1.userObject = 1
    self._CheckBox_1:addClickEventListener(CheckBoxClicked)
	self:MarkIntaractCObj(self._CheckBox_1) 
    self._CheckBox_2 = title:getChildByName("CheckBox_2")
    self._CheckBox_2.userObject = 2
    self._CheckBox_2:addClickEventListener(CheckBoxClicked)
	self:MarkIntaractCObj(self._CheckBox_2) 
    self._CheckBox_3 = title:getChildByName("CheckBox_3")
    self._CheckBox_3.userObject = 3
    self._CheckBox_3:addClickEventListener(CheckBoxClicked)
	self:MarkIntaractCObj(self._CheckBox_3) 
----------------------------------------------------------------------
    self._roleList = panel:getChildByName("RoleList")
--    self._roleList:setTouchEnabled(false)
    local roadPanel = self._roleList:getChildByName("Road")
    self._roadPanel = roadPanel
    roadPanel:setTouchEnabled(false)

    self._roundLine1 = {}
    for i=1, 16 do
        local str = string.format("Road_1_%d", i)
        local roadRound1 = roadPanel:getChildByName(str)
        table.insert(self._roundLine1, roadRound1)
    end

    self._roundLine2 = {}
    local str
    for i=1, 8 do
        str = string.format("Road_2_%d", i)
        local roadRound2 = roadPanel:getChildByName(str)
        table.insert(self._roundLine2, roadRound2)
    end

    self._roundLine3 = {}
    for i=1, 4 do
        str = string.format("Road_3_%d", i)
        local roadRound3 = roadPanel:getChildByName(str)
        table.insert(self._roundLine3, roadRound3)
    end

    self._roundLine4 = {}
    for i=1, 2 do
        str = string.format("Road_4_%d", i)
        local roadRound4 = roadPanel:getChildByName(str)
        table.insert(self._roundLine4, roadRound4)
    end

    self._BetBtn1 = {}
    self._queryBtn1 = {}
    for i=1, 8 do
        str = string.format("Button_1_%d", i)
        local betBtn = roadPanel:getChildByName(str)
        betBtn.userObject = i
        betBtn:addClickEventListener(handler(self, PreliminnaryUI.QueryBetEvent))
		self:MarkIntaractCObj(betBtn) 
        table.insert(self._queryBtn1, betBtn)

        str = string.format("CheckBox_1_%d", i)
        local queryBtn = roadPanel:getChildByName(str)
        queryBtn.userObject = i
        queryBtn:setTag(TAG_FIXX + i)
        queryBtn:addClickEventListener(handler(self, PreliminnaryUI.GoBetEvent))
		self:MarkIntaractCObj(queryBtn) 
        table.insert(self._BetBtn1, queryBtn)

    end

    self._BetBtn2 = {}
    self._queryBtn2 = {}
    for i=1, 4 do
        str = string.format("Button_2_%d", i)
        local betBtn = roadPanel:getChildByName(str)
        betBtn.userObject = 8 + i
        betBtn:addClickEventListener(handler(self, PreliminnaryUI.QueryBetEvent))
		self:MarkIntaractCObj(betBtn)
        table.insert(self._queryBtn2, betBtn)

        str = string.format("CheckBox_2_%d", i)
        local queryBtn = roadPanel:getChildByName(str)
        queryBtn.userObject = 8 + i
        queryBtn:setTag(TAG_FIXX + 8 + i)
        queryBtn:addClickEventListener(handler(self, PreliminnaryUI.GoBetEvent))
		self:MarkIntaractCObj(queryBtn)
        table.insert(self._BetBtn2, queryBtn)
    end

    self._BetBtn3 = {}
    self._queryBtn3 = {}
    for i=1, 2 do
        str = string.format("Button_3_%d", i)
        local betBtn = roadPanel:getChildByName(str)
        betBtn.userObject = 12 + i
        
        betBtn:addClickEventListener(handler(self, PreliminnaryUI.QueryBetEvent))
		self:MarkIntaractCObj(betBtn)
        table.insert(self._queryBtn3, betBtn)

        str = string.format("CheckBox_3_%d", i)
        local queryBtn = roadPanel:getChildByName(str)
        queryBtn.userObject = 12 + i
        queryBtn:setTag(TAG_FIXX + 12 + i)
        queryBtn:addClickEventListener(handler(self, PreliminnaryUI.GoBetEvent))
		self:MarkIntaractCObj(queryBtn)
        table.insert(self._BetBtn3, queryBtn)
    end

    self._BetBtn4 = {}
    self._queryBtn4 = {}
    local fanelBtn = roadPanel:getChildByName("Button_0")
    table.insert(self._queryBtn4, fanelBtn)
    fanelBtn.userObject = 15
    fanelBtn:addClickEventListener(handler(self, PreliminnaryUI.QueryBetEvent))
	self:MarkIntaractCObj(fanelBtn)

    local fanelBet = roadPanel:getChildByName("CheckBox_0")
    fanelBet.userObject = 15
    table.insert(self._BetBtn4, fanelBet)
    fanelBet:setTag(TAG_FIXX + 15)
    fanelBet:addClickEventListener(handler(self, PreliminnaryUI.GoBetEvent))
	self:MarkIntaractCObj(fanelBet)
    local function CheckBoxClicked(sender)
        -- if self._lastSelect ~= nil then
        --     self._lastSelect:getChildByName("")
        -- end
        local petInd = sender.userObject
        self._lastSelect = sender
        print("select role  =", petInd)
        local data = self._matchData.player[petInd]
        if data.id > 0 then
            LuaNetSendMsg:QueryOtherPlayer(data.id, 1)
        end
    end

    local listLeft = self._roleList:getChildByName("List_Left")
    self._nameTxt = {}
    for i=1, 8 do
        local strBox = string.format("CheckBox_%d", i)
        local CheckBox_ = listLeft:getChildByName(strBox)
        CheckBox_.userObject = i
        CheckBox_:addClickEventListener(CheckBoxClicked)
		self:MarkIntaractCObj(CheckBox_)
        CheckBox_:setTitleText("")
        local text = CheckBox_:getChildByName("Text")
        table.insert(self._nameTxt, text)

    end

    local listRight = self._roleList:getChildByName("List_Right")
    for i=1, 8 do
        local strBox = string.format("CheckBox_%d", i)
        local CheckBox_ = listRight:getChildByName(strBox)
        CheckBox_.userObject = i + 8
        CheckBox_:addClickEventListener(CheckBoxClicked)
		self:MarkIntaractCObj(CheckBox_)
        CheckBox_:setTitleText("")
        local text = CheckBox_:getChildByName("Text")
        table.insert(self._nameTxt, text)
    end

    local Champion = self._roleList:getChildByName("Champion")
    self._ChampionBg = Champion:getChildByName("bg")
    self._image = Champion:getChildByName("Image")
    self._ChampionIcon = self._ChampionBg:getChildByName("Icon")
    self._ChampionName = Champion:getChildByName("Name")
    self._ChampionLV = Champion:getChildByName("Level")

----------------------------------------------------------------------
--总决赛面板
    self._zongjuesai = panel:getChildByName("zongjuesai")
    self._zongjuesai:setVisible(false)
    self._left = self._zongjuesai:getChildByName("Left")
    self._leftNameBg = self._left:getChildByName("NameBg")
    self._leftName = self._leftNameBg:getChildByName("Text")
    local baseImage = self._left:getChildByName("BaseImage")
    self._leftNode = baseImage:getChildByName("Node")
    self._leftVipImage = self._left:getChildByName("VIPImage")
    self._leftVipValue = self._leftVipImage:getChildByName("AtlasLabel")
    self._leftPowerBg = self._left:getChildByName("PowerBg")
    self._leftPower = self._leftPowerBg:getChildByName("Value")
    self._leftDes = self._left:getChildByName("Text")
    self._leftWin = self._left:getChildByName("Win")
    self.leftImage = self._left:getChildByName("Image")
    self.leftImage:setTouchEnabled(true)
    local function leftQueryEvent( sender )
        
--        print("left event -----------")
        if self._finalData.roleId1 > 0 then
            LuaNetSendMsg:QueryOtherPlayer(self._finalData.roleId1, 1)                
        end
    end
    self.leftImage:addClickEventListener(leftQueryEvent)
	self:MarkIntaractCObj(self.leftImage)
    self._right = self._zongjuesai:getChildByName("Right")
    self._rightNameBg = self._right:getChildByName("NameBg")
    self._rightName = self._rightNameBg:getChildByName("Text")
    local baseNode = self._right:getChildByName("BaseImage")
    self._rightNode = baseNode:getChildByName("Node")
    self._rightVipImage = self._right:getChildByName("VIPImage")
    self._rightVipValue = self._rightVipImage:getChildByName("AtlasLabel")
    self._rightPowerBg = self._right:getChildByName("PowerBg")
    self._rightPower = self._rightPowerBg:getChildByName("Value")
    self._rightDes = self._right:getChildByName("Text")
    self._rightWin = self._right:getChildByName("Win")

    self.rightImage = self._right:getChildByName("Image")
    self.rightImage:setTouchEnabled(true)
    local function rightQueryEvent( sender )
        -- body
        
        if self._finalData.roleId2 > 0 then
            LuaNetSendMsg:QueryOtherPlayer(self._finalData.roleId2, 1)          
        end
        
    end
    self.rightImage:addClickEventListener(rightQueryEvent)
	self:MarkIntaractCObj(self.rightImage)
    self._finalBetBtn = self._zongjuesai:getChildByName("CheckBox")
    self._finalBetBtn.userObject = 1
    self._finalBetBtn:setTag(TAG_FIXX + 1)
    self._finalBetBtn:addClickEventListener(handler(self, PreliminnaryUI.GoBetEvent))
	self:MarkIntaractCObj(self._finalBetBtn)
    self._finalQueryBtn = self._zongjuesai:getChildByName("Button")
    self._finalQueryBtn.userObject = 1
    self._finalQueryBtn:addClickEventListener(handler(self, PreliminnaryUI.QueryBetEvent))
	self:MarkIntaractCObj(self._finalQueryBtn)
----------------------------------------------------------------------
--前往战场
    self._btn_qianwang = panel:getChildByName("btn_qianwang")
    local function qianwangEvent( sender )
        -- body
        LuaNetSendMsg:QueryWWDXBattle()
    end
    self._btn_qianwang:addClickEventListener(qianwangEvent)
	self:MarkIntaractCObj(self._btn_qianwang)
----------------------------------------------------------------------
--round
    local round = panel:getChildByName("Round")
    self._LoadingBar = round:getChildByName("LoadingBar")

    self._RoundStar = {}
    for i=1, 5 do
        local str = string.format("Round_%d", i)
        local star = round:getChildByName(str)
        table.insert(self._RoundStar, star)
    end

----------------------------------------------------------------------
    local btn_guize = panel:getChildByName("btn_guize")
    local function guizeEvent( sender )
        -- body
        self:helpButtonCallback()

    -- LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "ZhengBa.WwdxBettleUI", AppDef.UIType.Chat )
    -- LUIManager:SendMsg(LGameMsg.m_initUIMsg)

    end
    btn_guize:addClickEventListener(guizeEvent)
	self:MarkIntaractCObj(btn_guize)
----------------------------------------------------------------------
end

--刷新线路
function PreliminnaryUI:ShowRoundState(beforeRound, afterRound, roundLine)
    -- body
    for i=1, #roundLine do
        roundLine[i]:setColor(UICOLOR_GRAY)
    end

    for i = 1, #afterRound do
        if afterRound[i].id > 0 then
            if beforeRound[2*i].id == afterRound[i].id then
                if self._matchData.round4[1].id == afterRound[i].id then
                    roundLine[2*i]:setColor(cc.RED)
                else
                    roundLine[2*i]:setColor(GREEN)
                end
            elseif beforeRound[2*i - 1].id == afterRound[i].id then
                if self._matchData.round4[1].id == afterRound[i].id  then
                    roundLine[2*i - 1]:setColor(cc.RED)
                else
                    roundLine[2*i - 1]:setColor(GREEN)
                end
            end
        end
    end

end

--刷新按钮
function PreliminnaryUI:ShowRoundBtn(nodeInfo, roundBet, roundQuery)
    -- body
    for i=1, #nodeInfo do
        local state = nodeInfo[i].state
        local betBtn = roundBet[i]
        local queryBtn = roundQuery[i]
        self:updateBetBtnState(state, betBtn, queryBtn)
    end
end

--更新下注按钮状态
function PreliminnaryUI:updateBetBtnState(state, betBtn, queryBtn)
    -- body
    --1 查看 2可投注 3 不可投注 4时间没到 灰色
    if state == 1 then
        queryBtn:setVisible(true)
        betBtn:setVisible(false)
    elseif state == 2 then
        queryBtn:setVisible(false)
        betBtn:setVisible(true)
        betBtn:setTouchEnabled(true)
        betBtn:setBright(true)
        local image = betBtn:getChildByName("Image")
        image:setVisible(true)
    elseif state == 3 then
        queryBtn:setVisible(false)
        betBtn:setVisible(true)
        betBtn:setTouchEnabled(false)
        betBtn:setBright(false)
        local image = betBtn:getChildByName("Image")
        image:setVisible(false)
    elseif state == 4 then
        queryBtn:setVisible(false)
        betBtn:setVisible(true)
        betBtn:setTouchEnabled(false)
        betBtn:setBright(false)
        local image = betBtn:getChildByName("Image")
        image:setVisible(false)
    elseif state == 5 then
        queryBtn:setVisible(false)
        betBtn:setVisible(true)
        betBtn:setTouchEnabled(true)
        betBtn:setBright(true)
        local image = betBtn:getChildByName("Image")
        image:setVisible(false)
    end
end

function PreliminnaryUI:GoBetEvent(sender)
--下注
    local ind = sender.userObject
--    print("********GoBetEvent 1111", ind)
    LWWDXMgr.m_nodeEvent = LWWDXMgr.betEventType.MSI_BET
    LuaNetSendMsg:QueryWWDXNodeInfo(self._curType, ind, not LWWDXMgr.m_isCurLastMatch)
end

function PreliminnaryUI:QueryBetEvent(sender)
   local ind = sender.userObject
--   print("********QueryBetEvent 2222", ind)
   LWWDXMgr.m_nodeEvent = LWWDXMgr.betEventType.MSI_QUERY
   LuaNetSendMsg:QueryWWDXNodeInfo(self._curType, ind, not LWWDXMgr.m_isCurLastMatch)
end

function PreliminnaryUI:changeScene( ind )
    -- body
    self:updateSceneState(ind)
    self:updateBtnState(ind)
end

function PreliminnaryUI:updateSceneState( ind )
    if ind == 1 then
        self._roleList:setVisible(true)
        self._zongjuesai:setVisible(false)
    elseif ind == 2 then
        self._roleList:setVisible(true)
        self._zongjuesai:setVisible(false)
    elseif ind == 3 then
        self._roleList:setVisible(false)
        self._zongjuesai:setVisible(true)
    end

end

function PreliminnaryUI:updateBtnState( ind )
    -- body
    if ind == 1 then
        self._CheckBox_1:getChildByName("Choose"):setVisible(true)
        self._CheckBox_2:getChildByName("Choose"):setVisible(false)
        self._CheckBox_3:getChildByName("Choose"):setVisible(false)

    elseif ind == 2 then
        self._CheckBox_1:getChildByName("Choose"):setVisible(false)
        self._CheckBox_2:getChildByName("Choose"):setVisible(true)
        self._CheckBox_3:getChildByName("Choose"):setVisible(false)

    elseif ind == 3 then
        self._CheckBox_1:getChildByName("Choose"):setVisible(false)
        self._CheckBox_2:getChildByName("Choose"):setVisible(false)
        self._CheckBox_3:getChildByName("Choose"):setVisible(true)
    end

    

end

function PreliminnaryUI:loadData ( data )
    -- body
    self._matchData = data   --总数据
    self._nodeIdArr = {} --用于获取节点id
    for i=1, #self._matchData.round1 do
        table.insert(self._nodeIdArr, self._matchData.round1[i].id)
    end
    for i=1, #self._matchData.round2 do
        table.insert(self._nodeIdArr, self._matchData.round2[i].id)
    end
    for i=1, #self._matchData.round3 do
        table.insert(self._nodeIdArr, self._matchData.round3[i].id)
    end
    for i=1, #self._matchData.round4 do
        table.insert(self._nodeIdArr, self._matchData.round4[i].id)
    end

    self._curType = self._matchData.type
end



function PreliminnaryUI:updateUI()
    -- body
    self:changeScene(self._matchData.type + 1)

    self:ShowRoundState(self._matchData.player, self._matchData.round1, self._roundLine1)
    self:ShowRoundState(self._matchData.round1, self._matchData.round2, self._roundLine2)
    self:ShowRoundState(self._matchData.round2, self._matchData.round3, self._roundLine3)
    self:ShowRoundState(self._matchData.round3, self._matchData.round4, self._roundLine4)

    self:ShowRoundBtn(self._matchData.round1, self._BetBtn1, self._queryBtn1)
    self:ShowRoundBtn(self._matchData.round2, self._BetBtn2, self._queryBtn2)
    self:ShowRoundBtn(self._matchData.round3, self._BetBtn3, self._queryBtn3)
    self:ShowRoundBtn(self._matchData.round4, self._BetBtn4, self._queryBtn4)

    self:resetSelectState()

    for i=1, #self._matchData.player do
        local data = self._matchData.player[i]
        if string.len(data.name) > 0 then
            self._nameTxt[i]:setString(data.name)
            local myRoleId = LRoleDataMgr.MyHeroInfo.id
            if myRoleId == data.id then
                local btn = self._nameTxt[i]:getParent()
                if btn then
                    local Choose = btn:getChildByName("Choose")
                    Choose:setVisible(true)
                end
            end
        else
            self._nameTxt[i]:setString(GUITips.RSI_PAGE_MSG20)
        end
    end

--刷新进度条
    if self._matchData.curntRoundIdx > 0 then
        self._LoadingBar:setPercent((self._matchData.curntRoundIdx - 1) / 4 * 100)
    end

--    print("grayStar =", #self._RoundStar, self._matchData.curntRoundIdx)
    for i = 1, #self._RoundStar do
        local grayStar = self._RoundStar[i]:getChildByName("Image")
        if i <= self._matchData.curntRoundIdx then
            grayStar:setVisible(false)
        else
            grayStar:setVisible(true)
        end
    end

--冠军头像
    local FinalData = self._matchData.round4[1]
--    print("PreliminnaryUI:updateUI = FinalData.finalType", FinalData.finalType)
    if FinalData.finalType == 1 then
        self:isSHowChampionIcon(false)
--        print("PreliminnaryUI:updateUI 222222222222", LWWDXMgr.m_isCurLastMatch, LWWDXMgr.m_isNoBaoMing)
        if LWWDXMgr.m_isCurLastMatch or LWWDXMgr.m_isNoBaoMing then
            self._btn_qianwang:setTouchEnabled(false)
            self._btn_qianwang:setBright(false)
        else
            self._btn_qianwang:setTouchEnabled(true)
            self._btn_qianwang:setBright(true)
        end
    else
        if FinalData.id > 0 then
            self:isSHowChampionIcon(true)
            local str = AppDef:GetHeroPicFileName(FinalData.prof, AppDef.HeadType.HERO_IMAGE_HEAD)
            self._ChampionIcon:loadTexture(str,ccui.TextureResType.localType)

            self._ChampionName:setString(FinalData.name)
            self._ChampionLV:setString(FinalData.level)
        else
            self:isSHowChampionIcon(false)
        end

        self._btn_qianwang:setTouchEnabled(false)
        self._btn_qianwang:setBright(false)

    end

end

function PreliminnaryUI:isSHowChampionIcon( isShow )
    -- body
    self._ChampionBg:setVisible(isShow)
    self._ChampionLV:setVisible(isShow)
    self._ChampionName:setVisible(isShow)
    self._image:setVisible(not isShow)
    self._ChampionIcon:setVisible(isShow)

end

function PreliminnaryUI:updateFinalUI( data )
    -- body
    self._finalData = data
--    dump(self._finalData, "PreliminnaryUI:updateFinalUI")
    self._curType = self._finalData.type
    self:changeScene(3)
    if self._finalData.prof1 ~= nil then
        self._leftNode:removeAllChildren()
        local pLRoleModel = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, self._finalData.prof1)
        self._leftNode:addChild(pLRoleModel)
        pLRoleModel:PlayStand(0)
    end

    if self._finalData.prof2 ~= nil then
        self._rightNode:removeAllChildren()
        local pLRoleModel = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, self._finalData.prof2)
        self._rightNode:addChild(pLRoleModel)
        pLRoleModel:PlayStand(0)
    end

    self:refrashFinalUI()

    self._leftName:setString(self._finalData.name1)
    self._rightName:setString(self._finalData.name2)

    self._leftPower:setString(Utils:getPowerStr(self._finalData.zhandouli1))
    self._rightPower:setString(Utils:getPowerStr(self._finalData.zhandouli2))

    if self._finalData.vip1 > 0 then
        self._leftVipValue:setString(self._finalData.vip1)
    else
        self._leftVipImage:setVisible(false)
    end
        
    if self._finalData.vip2 > 0 then
        self._rightVipValue:setString(self._finalData.vip2)
    else
        self._rightVipImage:setVisible(false)
    end

    self:updateBetBtnState(self._finalData.state, self._finalBetBtn, self._finalQueryBtn)

    if self._finalData.winer == self._finalData.roleId1 then
        self._leftWin:setVisible(true)
        self._rightWin:setVisible(false)
    elseif self._finalData.winer == self._finalData.roleId2 then
        self._leftWin:setVisible(false)
        self._rightWin:setVisible(true)
    end

    if LWWDXMgr.m_isCurLastMatch then
        self._btn_qianwang:setTouchEnabled(false)
        self._btn_qianwang:setBright(false)
    else
--        print("isAfterFinal = ", LWWDXMgr:isAfterFinal(), LWWDXMgr.m_isNoBaoMing)
        local myRoleId = LRoleDataMgr.MyHeroInfo.id
        local isIntoFinal = self._finalData.roleId1 == myRoleId or  self._finalData.roleId2 == myRoleId
        if LWWDXMgr:isAfterFinal() or not isIntoFinal then
            self._btn_qianwang:setTouchEnabled(false)
            self._btn_qianwang:setBright(false)
        else
            self._btn_qianwang:setTouchEnabled(true)
            self._btn_qianwang:setBright(true)
        end
    end

    --刷新进度条
    if LWWDXMgr.m_curBattleIndex > 0 then
        self._LoadingBar:setPercent((LWWDXMgr.m_curBattleIndex - 1) / 4 * 100)
    end

    for i = 1, #self._RoundStar do
        local grayStar = self._RoundStar[i]:getChildByName("Image")
        if i <= LWWDXMgr.m_curBattleIndex then
            grayStar:setVisible(false)
        else
            grayStar:setVisible(true)
        end
    end

end

function PreliminnaryUI:refrashFinalUI( ... )
    -- body
    if self._finalData.roleId1 <= 0 and self._finalData.roleId2 <= 0 then
        self._leftNameBg:setVisible(false)
        self._leftPowerBg:setVisible(false)

        self._rightNameBg:setVisible(false)
        self._rightPowerBg:setVisible(false)

        self._leftDes:setVisible(true)
        self._rightDes:setVisible(true)
    else
        self._leftNameBg:setVisible(true)
        self._leftPowerBg:setVisible(true)

        self._rightNameBg:setVisible(true)
        self._rightPowerBg:setVisible(true)

        self._leftDes:setVisible(false)
        self._rightDes:setVisible(false)
    end
end

function PreliminnaryUI:resetSelectState( ... )
    -- body
    for i = 1, #self._nameTxt do
        local btn = self._nameTxt[i]:getParent()
        if btn then
            local Choose = btn:getChildByName("Choose")
            Choose:setVisible(false)
        end
    end
end

function PreliminnaryUI:CloseDialog( ... )
    -- body
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "ZhengBa.PreliminnaryUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
end

function PreliminnaryUI:helpButtonCallback()
    local str = GUITips.RIS_LEFTUI_MSG176
    local function OKCallback()
    end
    local msgData = {
        title = GUITips.RSI_WELFARE_MSG38,
        okCallback = OKCallback,
        desc = str,
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIMsgBoxEvent.ShowMsgBox, msgData)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function PreliminnaryUI:updateBetNodeInfo(data)
    -- body
    if self._curType == 2 then
        --决赛
        local image = self._finalBetBtn:getChildByName("Image")
        image:setVisible(false)
    else
        local btn = self._roadPanel:getChildByTag(data.nodeIdx + TAG_FIXX)
--        print("updateBetNodeInfo", data.nodeIdx)
        if btn then
--            print("msg is update")
            local image = btn:getChildByName("Image")
            image:setVisible(false)
        end
    end
end

function PreliminnaryUI:openBattleInfoUI( ... )
    -- body
    LWWDXMgr.m_enterBattle = true
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "ZhengBa.WwdxBettleUI", AppDef.UIType.Chat )
    LUIManager:SendMsg(LGameMsg.m_initUIMsg)
end

return PreliminnaryUI