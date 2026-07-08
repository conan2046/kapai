
local FuBenDetailUI = LUIBase:New()
FuBenDetailUI.__index = FuBenDetailUI
--local this = LTcpSocket
function FuBenDetailUI:New(stageData)
	local o = LUIBase:New()
	setmetatable(o,FuBenDetailUI)	
    o:Init(stageData)
	return o
end

local ONESCREENWIDTH = 1334
local INNERCONTAINERWIDTH = ONESCREENWIDTH * 3
local INNERCONTAINERHEIGHT = 750

--图是按照 1920 * 1080的比例做的 所以要有一个缩放 高度是1041
local SCREENRATE = 750 / 1080
local SCREENSPEED = 500

local YLIMIT = 1500 * SCREENRATE - 750

local ZXCJOPENCHP = 1003

--注册事件
-- -----------------------------------
function FuBenDetailUI:RegistMsgs()
    self.msgIds = 
    {
        LUIFuBenMapEvent.refrashStageMapUI,
        LUILogicEvent.EnterBattle,
        LUILogicEvent.ExitBattle,
        LUIFuBenMapEvent.refrashUIAfterFight,
        LUIFuBenMapEvent.getBoxAwardSuc,
        LUIFuBenMapEvent.resetFightTimesSuc,
        LUIRoleDataChangeEvent.MoneyChanged,
        LUIRoleDataChangeEvent.TongBaoChanged,
        LUIRoleDataChangeEvent.TiliChanged,
        LUILogicEvent.PlotChatOver,
        LUIRedDotEvent.UpdateRedDotState,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function FuBenDetailUI:ProcessEvent(msg)
    local msgId = msg:GetMsgId()
    -- print("FuBenDetailUI:ProcessEvent ==>", LUIRedDotEvent.UpdateRedDotState, msgId)
    if msgId == LUIFuBenMapEvent.refrashStageMapUI then
        self:refrashData(msg.value)
        self:refreshUI()
        self:OpenChallenge()
        self:RegisterGuide()
    elseif msgId ==LUILogicEvent.EnterBattle then
        self.m_pUILayer:setVisible(false)
    elseif  msgId ==  LUILogicEvent.ExitBattle then
        self.m_pUILayer:setVisible(true)
        if LRoleDataMgr.m_fightResultData == nil then
            return
        end
        if LRoleDataMgr.m_fightResultData.unLockMap == nil then
            return
        end
        performWithDelay(self.m_pUILayer, function(sender)
            
            --通关章节
            if LRoleDataMgr.m_fightResultData == nil then
                return
            end
            if LRoleDataMgr.m_fightResultData.unLockMap > 0 and LRoleDataMgr.m_fightResultData.unLockMap ~= self._stageData.curChapterID then
                    self:closeDialog()
                    Utils:InitUI("FuBenMap.TongguanChapter", AppDef.UIType.SpecialLayer, self._stageData)
            else
            --角色移动
                if self._isNeedMove then
                    self:ModelMove()
                    self._isNeedMove = false
                end
            end
        end, 0.2)
    elseif msgId == LUIFuBenMapEvent.refrashUIAfterFight then
        self:updateOriginalData(msg.value)
        self:updateUIAfterFight(msg.value)
    elseif msgId == LUIFuBenMapEvent.getBoxAwardSuc then
        --更新宝箱数据
        self:updateUIAfterGetBoxAward(msg.value)
    elseif msgId == LUIFuBenMapEvent.resetFightTimesSuc then
        --更新重置数据
        self:updateUIAfterResetStage(msg.value)
    elseif msgId == LUIRoleDataChangeEvent.MoneyChanged then
        local myMoney = Utils:getGoldStr()
        self._coin:setString(myMoney)
    elseif msgId == LUIRoleDataChangeEvent.TongBaoChanged then
        local myGold = LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao()
        self._Gold:setString(myGold)
    elseif msgId == LUIRoleDataChangeEvent.TiliChanged then
        local myTili = LRoleDataMgr.MyHeroInfo:GetDetailData():getTili()
        self._TiLi:setString(Utils:getTiliStr(myTili))
    elseif msgId == LUILogicEvent.PlotChatOver then
        if msg.value then
            self:OpenStageChallenge()
        end
    elseif msgId == LUIRedDotEvent.UpdateRedDotState then
        self:UpdateRedDot()
    end
end

function FuBenDetailUI:Init(stageData)

    self.m_pUILayer = cc.CSLoader:createNode("csd/fuben/kapaiguaiwuLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end

    Utils:SendMsg(LAudioEvent.PlayMapMusic,stageData.selectChapterId);
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self._curPosY = 0
    self._UILayer = cc.CSLoader:createNode("csd/fuben/DadituuiLayer.csb")
    self._UILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self._UILayer)
    self._UI = self._UILayer;
    self._UILayer:setPosition(cc.p(0, 0))
    self.m_pUILayer:addChild(self._UILayer)
    self:RegistMsgs()
    self:initData(stageData)
    self:initControlUI()
    LuaNetSendMsg:QueryStageInfo(2, 1, self._stageData.selectChapterId)
    self:AddSchedule()
    self:ScheduleStart()
    self:UpdateRedDot()
end

function FuBenDetailUI:initData(stageData)
    -- body
        self._stageData = stageData
        self._fightStageID = 0
        self._stageBoxList = {}
        self._StarBoxList = {}
        self._speakList = {}
        self._isNeedMove = false
        self._scroolToAim = false
end

function FuBenDetailUI:updateOriginalData( data )
    -- body
    --print("data.stageId ==", data.stageId)
    for i=1, #self._datas.stageNodeList do
        if self._datas.stageNodeList[i].stageId == self._fightStageID then
            self._datas.stageNodeList[i].fightNum = JsonConfig.getFightMaxNum(self._fightStageID) - data.alreadyFightTimes

            --星星刷新了才更新累加
            -- print("updateOriginalData ==>", self._datas.stageNodeList[i].getStarNum, data.starNum)
            if self._datas.stageNodeList[i].getStarNum < data.starNum then
                local addStar = data.starNum - self._datas.stageNodeList[i].getStarNum
                self._datas.stageNodeList[i].getStarNum = data.starNum
                self._stageData.ownChapterStarNum = self._stageData.ownChapterStarNum + addStar

                self._stageData.ownTotalStarNum = self._stageData.ownTotalStarNum + addStar

                --最大判断
                if self._stageData.ownChapterStarNum > self._stageData.maxStarNum then
                    self._stageData.ownChapterStarNum = self._stageData.maxStarNum
                end
            end
            break
        end
    end



    self._jindutiao:setPercent(self._stageData.ownChapterStarNum / self._stageData.maxStarNum * 100.0)
    self._xingshu:setString(string.format("%d/%d", self._stageData.ownChapterStarNum, self._stageData.maxStarNum))
    -- --dump(self._datas, "closeDialog ==== 111>")
    self._jindutiao:setPercent(self._stageData.ownChapterStarNum / self._stageData.maxStarNum * 100.0)
    
end

function FuBenDetailUI:scrollToAimPos()
    -- body
    --滑动到中央

    self._scroolToAim = true

    -- local action = cc.MoveTo:create(2, cc.p(-self._fightPosition.x, -self._fightPosition.y))
    -- self._scrollView:runAction(action)

end

function FuBenDetailUI:updateUIAfterFight(data)
    -- body
    --更新星星
    if self._fightStageID <= 0 then
        return
    end

    local index = self._fightStageID % 10
    if index == 0 then
        index = 10
    end
    local node1 = self._scrollView:getChildByName("Node_"..index)

    --print("index ===>", index, self._fightStageID, data.starNum)
    for i=1, data.starNum do
        local star = node1:getChildByName("laingxing_".. i -1)
        star:setVisible(true)

        local starGrey = node1:getChildByName("anxing_".. i -1)
        starGrey:setVisible(false)
    end

    if data.unLockBox > 0 then
        local box = self:getBoxByBoxId(data.unLockBox)
        --print(" 111111111111111111 box =============================> ", data.unLockBox)
        --解锁箱子
        box:getChildByName("Button1").userObject.boxState = 1
        --红点
        box:getChildByName("Button1"):getChildByName("Image_1"):setVisible(true)
        box:getChildByName("effect_tuitu_1"):setVisible(true) 
    end


    if data.unLockstarBox > 0 then
        --红点
        local box = self:getStarBoxByBoxId(data.unLockstarBox)
        --解锁箱子
        box:getChildByName("Button1").userObject.boxState = 1
        box:getChildByName("Button1"):getChildByName("Image_1"):setVisible(true)
        box:getChildByName("effect_tuitu_1"):setVisible(true) 

    end

    --解锁了新的关卡
    --print("FuBenDetailUI:updateUIAfterFight ===>", data.stageId, self._stageData.curStageID)
    if data.stageId > self._stageData.curStageID then
        LUserConfigMgr:SetStageDialogOver(false)
        self._isNeedMove = true
        node1:getChildByName("zhandou"):setVisible(false)
        self._curSpeakNode:setVisible(false)
        self._stageData.curStageID = data.stageId
        self._fightStageID = data.stageId

        local curIndex = self._fightStageID % 10
        if curIndex == 0 then
            curIndex = 10
        end
        local curNode = self._scrollView:getChildByName("Node_"..curIndex)


        self._curSpeakNode = curNode:getChildByName("Image_qipao")
        --记录上一个点
        self._lastPostion = self._fightPosition
        --print("curIndex ===>", curIndex)
        self._fightPosition = cc.p(self._nodePosConfig.role_coor[curIndex][1], self._nodePosConfig.role_coor[curIndex][2])

        local Text_name = curNode:getChildByName("Text_name")
        Text_name:setVisible(true)
        curNode:getChildByName("zhandou"):setVisible(true)

    end
end


function FuBenDetailUI:updateUIAfterGetBoxAward(data)
    -- body
    --dump(data, "updateUIAfterGetBoxAward")
    --print("updateUIAfterGetBoxAward ===>", data.boxId)
    local boxCell = self:getBoxByBoxId(data.boxId)
    if boxCell ~= nil then
        --print("====================================================>")
        ----关卡宝箱
        self:OpenChapterBox(boxCell)
    else
        local starBoxCell = self:getStarBoxByBoxId(data.boxId)
        if starBoxCell ~= nil then
            self:OpenChapterBox(starBoxCell)
        end
    end

end

function FuBenDetailUI:updateUIAfterResetStage(data)
    -- body
    for i=1, #self._datas.stageNodeList do
        if self._datas.stageNodeList[i].stageId == data.stageId then
            self._datas.stageNodeList[i].fightNum = JsonConfig.getFightMaxNum(data.stageId)
            -- self._datas.stageNodeList[i].leftResetTimes = self._datas.stageNodeList[i].leftResetTimes - 1
        end
    end
end

function FuBenDetailUI:OpenChapterBox( boxItem )
    -- body
    local box = boxItem:getChildByName("Button1")
    box.userObject.boxState = 2
    box:setVisible(false)
    local boxOpen = boxItem:getChildByName("Button")
    boxOpen.userObject.boxState = 2
    boxOpen:setVisible(true)
    local effect = boxItem:getChildByName("effect_tuitu_1")
    effect:setVisible(false)
end

function FuBenDetailUI:isCurStageOpen(stageId)
    -- body
    --print("self._stageData.curChapterID ===>", self._stageData.curChapterID, self._stageData.selectChapterId, stageId, self._stageData.curStageID)
    if self._stageData.curChapterID == self._stageData.selectChapterId then
        return self._stageData.curStageID >= stageId
    end

    return self._stageData.curChapterID > self._stageData.selectChapterId
end

function FuBenDetailUI:initControlUI( ... )
    -- body
    self._scrollView = self.m_pUILayer:getChildByName("ScrollPanel")

    --self._stageBg = self._scrollView:getChildByName("Sprite_1")
    self._stageBg = self._scrollView:getChildByName("MapPanel")
    local mapCtrl = require("View.FuBenMap.FubenDetailMap"):New(self._stageData, self._stageBg)
    local nodePosConfig = JsonConfig.m_mapRes.getDefByID(self._stageData.BundleId)

    -- local mapPath = string.format("fuben/%s.jpg", nodePosConfig.name)
    --print("FuBenDetailUI:isCurStageOpen ==>", mapPath)
    -- self._stageBg:initWithFile(mapPath)
    self._stageBg:setScale(SCREENRATE)
    self._stageBg:setAnchorPoint(cc.p(0, 0))
    self._stageBg:setPosition(cc.p(0, 0))

    self:PanelScrollEvent()

    --print("initControlUI ============>", self._stageBg:getContentSize().width, self._stageBg:getContentSize().height)

    -- self._innerContentSize = cc.size(self._stageBg:getContentSize().width * SCREENRATE, self._stageBg:getContentSize().height * SCREENRATE)
    -- self._scrollView:setInnerContainerSize(self._innerContentSize)
    -- self._image:loadTexture("fuben/map_1.png",ccui.TextureResType.localType)

    local boxCell = self.m_pUILayer:getChildByName("Box")
    --print(boxCell:getChildByName("effect_tuitu_1"),"boxCell:getChildByName")
    self._boxCell = boxCell
    boxCell:setVisible(false)

    local HeadBg_1 = self.m_pUILayer:getChildByName("HeadBg_1")
    HeadBg_1:setVisible(false)
    local HeadBg_2 = self.m_pUILayer:getChildByName("HeadBg_2")
    HeadBg_2:setVisible(false)

    ----------------------------------------------------------
    local GoldCheck = self._UILayer:getChildByName("GoldCheck")
    self._coin = GoldCheck:getChildByName("GoldIcon1"):getChildByName("GoldNumBg"):getChildByName("Num")
    local myMoney = Utils:getGoldStr()
    self._coin:setString(myMoney)
    local coinAddBtn = GoldCheck:findChildByName("GoldIcon1/AddBtn")
    coinAddBtn:addClickEventListener(function ( sender )
        Utils:OpenFunction(AppDef.EModuleID.EMID_SCCHANGYONG)
    end)
    self._Gold =  GoldCheck:getChildByName("GoldIcon3"):getChildByName("GoldNumBg"):getChildByName("Num")
    local myGold = LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao()
    self._Gold:setString(myGold)
    local goldAddBtn = GoldCheck:findChildByName("GoldIcon3/AddBtn")
    goldAddBtn:setEnabled(false)
    self._TiLi = GoldCheck:getChildByName("GoldIcon4"):getChildByName("GoldNumBg"):getChildByName("Num")
    local tili = LRoleDataMgr.MyHeroInfo:GetDetailData():getTili()
    self._TiLi:setString(Utils:getTiliStr(tili))
    local tiliAddBtn = GoldCheck:findChildByName("GoldIcon4/AddBtn")
    tiliAddBtn:addClickEventListener(function ( sender )
        Utils:OpenUseUI(500,1)
    end)
    -----------------------------------------------------
    --------------------------------------------------------------------------------------------
    local Panel_zuoshang = self._UI:getChildByName("Panel_zuoshang")
    local Image_bg2 = Panel_zuoshang:getChildByName("Image_bg2")
    self._fubenName = Image_bg2:getChildByName("guanqia")

    local Button_xiala = Panel_zuoshang:getChildByName("Button_xiala")
    Button_xiala:setVisible(false)

    ------------------------------------------------------------------------
    local title = self._UILayer:getChildByName("Title")
    local guanbi = title:getChildByName("CloseBtn")
    guanbi:addClickEventListener(handler(self, FuBenDetailUI.closeDialog))
    self._guideBtn = guanbi

    for i=1, 10 do
        local node1 = self._scrollView:getChildByName("Node_"..i)
        node1:setVisible(false)
        local touchLayer = node1:getChildByName("touchLayer")
        touchLayer:setTag(i)
        touchLayer:addClickEventListener(handler(self, FuBenDetailUI.showStageInfoUI))
        touchLayer:setSwallowTouches(false)


        local zhandou = node1:getChildByName("zhandou")
        zhandou:setVisible(false)
        local effect =Utils:FightEffect(1) 
        zhandou:addChild(effect)
       -- effect:setPosition(cc.p(effect:getContentSize().width/2,effect:getContentSize().height/2))
    end

    local panel1 = self._UILayer:getChildByName("Panel_1")

    self._StarBoxList = {}
    for i=1, 3 do
        local tempBoxCell = panel1:getChildByName("Box"..i)
        local boxOpen1 = tempBoxCell:getChildByName("Button")
        local box1 = tempBoxCell:getChildByName("Button1")
        boxOpen1:addClickEventListener(handler(self, FuBenDetailUI.showBoxInfo))
        box1:addClickEventListener(handler(self, FuBenDetailUI.showBoxInfo))
        box1:getChildByName("Image_1"):setVisible(false)
        --print("initControlUI ======>", tempBoxCell)
        table.insert(self._StarBoxList, tempBoxCell)
    end
    

    local duiwu = panel1:getChildByName("duiwu")
    -- duiwu:setVisible(false)
    duiwu:addClickEventListener(function( sender)
        -- body
        -- self._scrollView:scrollToPercentHorizontal(70, 0.5, false)

        if #LRoleDataMgr.Pet.petlist == 0 then
            Utils:ShowScrollTips(GUITips.UI_No_Shenjiang_Tips)
            return
        end
        Utils:OpenFunction(AppDef.EModuleID.EMID_SJBUZHEN)
    end)

    local rankBtn = panel1:getChildByName("Button_paihangbang")
    rankBtn:addClickEventListener(function( sender)
        Utils:OpenRankUI(AppDef.EModuleID.EMID_RANK_Fuben)
    end)

    local btn_zhenrong = panel1:getChildByName("btn_zhenrong")
    btn_zhenrong:setVisible(true)
    local isShowRed = Utils:GetRedDotState(RedDotDef.ID.ShenJiangZhenRong)
    btn_zhenrong:getChildByName("Prompt"):setVisible(isShowRed)
    self._btn_zhenrong = btn_zhenrong
    btn_zhenrong:addClickEventListener(function ( sender )
        -- body
        if #LRoleDataMgr.Pet.petlist < 1 then
            Utils:ShowScrollTips(GUITips.UI_No_Shenjiang_Tips)
            return
        end

        Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_SHENJIANG)

    end)

    --------------------------------------------------------------------
    local Panel_youxia = self._UI:getChildByName("Panel_youxia")
    Panel_youxia:setTouchEnabled(false)

    local Button_zhuxianchengjiu = Panel_youxia:getChildByName("Button_zhuxianchengjiu")
    self._Button_zhuxianchengjiu = Button_zhuxianchengjiu
    self._achiPrompt = Button_zhuxianchengjiu:getChildByName("Prompt")
    Button_zhuxianchengjiu:addClickEventListener(function ( sender )
        -- body
        local ownTatalStar = 0
        if self._datas then
            ownTatalStar = self._stageData.ownTotalStarNum
        end
        Utils:InitUI("FuBenMap.FuBenAchievementsUI", AppDef.UIType.SpecialLayer, ownTatalStar)
    end)

    local Button_fengshenshilian = Panel_youxia:getChildByName("Button_fengshenshilian")
    Button_fengshenshilian:setVisible(false)

    ------------------------------------------------------------------------
end

function FuBenDetailUI:getBeginPos( ... )
    -- body
    if self._camera_coor == nil or #self._camera_coor < 1 then
        return {0, 0}
    end
    return self._camera_coor[1]
end

function FuBenDetailUI:getEndPos( ... )
    -- body
    if self._camera_coor == nil or #self._camera_coor < 1 then
        return {0, 0}
    end
    local length = #self._camera_coor
    return self._camera_coor[length]
end

--test code
function FuBenDetailUI:PanelScrollEvent( ... )
    -- body
    --test code
    self._scrollView:setContentSize(self._stageBg:getContentSize())
    self._scrollView:setPosition(cc.p(0, 0))
    local function processScrool(pTouch, pEvent)

        if pEvent == ccui.TouchEventType.began then
           -- if self._isMoveing then
           --      return
           -- end
           self._touchBeginPos = self._scrollView:getTouchBeganPosition()
           self._touchMovePos = self._touchBeginPos
        end

        if pEvent == ccui.TouchEventType.moved then

            -- if self._isMoveing then
            --     return
            -- end
            if self._beginPos == nil then
                return
            end
            local movey = self._scrollView:getTouchMovePosition()
            -- self._stageBg:setPosition(cc.p(movey.x, movey.y))

            local offetX = 0
            local offsetY = 0
            if self._touchMovePos then
                offetX = movey.x - self._touchMovePos.x
                offsetY = movey.y - self._touchMovePos.y
            end

            self._touchMovePos = movey

            --边界判断
            local posX = self._scrollView:getPositionX() + offetX
            if -posX < self._beginPos[1] then 
                posX = -self._beginPos[1]
            end

            -- --print("PanelScrollEvent ====>", posX, self._beginPos[1], self._endPos[1])
            local view = cc.Director:getInstance():getOpenGLView():getFrameSize()
            local tempPos =self._endPos[1]*1334/750/(view.width/view.height) 
            if -posX > tempPos  then
                posX = -tempPos
            end

            local posY = self._scrollView:getPositionY() + offsetY
            if posY > 0 then
                posY = 0
            end

            if posY < YLIMIT then
                posY = YLIMIT
            end

            local finalPosY = self:FindScreenPosY(posX, posY)
            -- local exChangeY = (finalPosY - 750) / 2
            -- --print("finalPosY ==>", posX, -finalPosY)
            self._scrollView:setPosition(cc.p(posX, -finalPosY))

            self._scroolToAim = false

        end

        if pEvent == ccui.TouchEventType.ended then
            -- local endPistion = pLayer:getTouchEndPosition()
        end

        if pEvent == ccui.TouchEventType.canceled then

        end

    end

    self._scrollView:addTouchEventListener(processScrool)

end

function FuBenDetailUI:initBgPosition( ... )
	-- body
	self._beginPos = self:getBeginPos()
    -- self._scrollView:setPosition(cc.p(-self._beginPos[1], (self._beginPos[2] - 750) / 2))
    self._scrollView:setPosition(cc.p(-self._beginPos[1], -self._beginPos[2]))
    self._endPos = self:getEndPos()
end

function FuBenDetailUI:getLeftPosX( ... )
    -- body
    local nodePosConfig = JsonConfig.m_mapRes.getDefByID(self._stageData.BundleId)
    return nodePosConfig.monster_coor[1][1] - 120
end

function FuBenDetailUI:getRightPosX( ... )
    -- body
    local nodePosConfig = JsonConfig.m_mapRes.getDefByID(self._stageData.BundleId)
    local length = #nodePosConfig.monster_coor
    return nodePosConfig.monster_coor[length][1] + 200
end

function FuBenDetailUI:getContontSizeRate( ... )
    -- body
    local posX = self:getRightPosX()
    return posX / self._innerContentSize.width
end

function FuBenDetailUI:OpenChallenge()
    if self._stageData.openStageId==nil then
        return
    end
    local data = nil
    for i=1,#self._datas.stageNodeList do
        if self._datas.stageNodeList[i].stageId==self._stageData.openStageId then
            data=self._datas.stageNodeList[i]
            break
        end
    end
    if not self:isCurStageOpen(data.stageId) then
        Utils:ShowScrollTips(GUITips.RSI_FUBENMAP_RES4)
        return
    end
    self._curSelectData = data
    self:OpenStageChallenge()

    -- body
end

function FuBenDetailUI:showStageInfoUI( sender )
    -- body
    local index = sender:getTag()
    local data = self._datas.stageNodeList[index]

    if not self:isCurStageOpen(data.stageId) then
        Utils:ShowScrollTips(GUITips.RSI_FUBENMAP_RES4)
        return
    end
    self._fightStageID = data.stageId
    local configData = JsonConfig.m_stageNodeConfig.getDefByID(data.stageId)

    local isOver = LUserConfigMgr:GetStageDialogOver()
    self._curSelectData = data
    --点击的是最新的关卡才会触发
    if not isOver and configData.DialogueId > 0 and data.stageId == self._stageData.curStageID then
        Utils:InitUI("Common.NPCChatDialogUI", AppDef.UIType.Plot,  {DialogueId = configData.DialogueId, isStageDialog = true})
        LUserConfigMgr:SetStageDialogOver(true)
        return
    end

    self:OpenStageChallenge()
    
end

function FuBenDetailUI:OpenStageChallenge( ... )
    -- body
    Utils:InitUI("FuBenMap.StageInfoUI", AppDef.UIType.SpecialLayer, self._curSelectData)
end

function FuBenDetailUI:showBoxInfo( sender )
    -- body
    local boxId = sender:getTag()
    local boxData = sender.userObject
    -- Utils:InitUI("Common.BoxAwardList", AppDef.UIType.PopWindow, boxData)
    if boxData == nil then
        return
    end
    local function getAwardCallBack()
        -- body
        LuaNetSendMsg:QueryGetBoxReward(4, boxData.type, boxData.chapterId, boxData.boxId)
    end
    
    local data = JsonConfig.m_BoxReward.getDefByID(boxData.boxId)
    if data == nil then
        return
    end

    if boxData.boxState == 0 then
        --未解锁
        local tipStr = ""
        if boxData.isStarType then
            tipStr = string.format(GUITips.RSI_FUBENMAP_RES13, boxData.needStarNum)
        else
            local configData = JsonConfig.m_stageNodeConfig.getDefByID(boxData.stageId)
            -- --dump(configData, "configData ====>")
            if configData then
                tipStr = string.format(GUITips.RSI_FUBENMAP_RES14, configData.Name)
            end
        end

        Utils:OpenRewardBoxFromConfig(GUITips.RSI_BOX_TIP2, data.reward, false, tipStr, nil, nil)
    elseif boxData.boxState == 1 then
        --解锁可领取
        Utils:OpenRewardBoxFromConfig(GUITips.RSI_BOX_TIP2, data.reward, true, GUITips.RSI_GS_TIP_RECOVERY_DRAW, getAwardCallBack, nil)
        if boxData.chapterId == 1001 then
            if boxData.isStarType then
                Utils:SendMsg(LUIRewardGetEvent.RegisterDrawGuide,GuideDef.StepId.Guide_FuBen2_1)
            else
                Utils:SendMsg(LUIRewardGetEvent.RegisterDrawGuide,GuideDef.StepId.Guide_FuBen3_1)
            end
        end
    else
        --已领取
        Utils:OpenRewardBoxFromConfig(GUITips.RSI_BOX_TIP2, data.reward, true, GUITips.RSI_FUND_TIPS4, nil, nil)
    end  
end


function FuBenDetailUI:ShowRoleModel(node, petId,quality)
    if node == nil or petId <= 0 then
        return
    end
    if quality ==  2 then
        local imod = ImodAnim:createWithFile("res2/animation/battle/quality2.png","res2/animation/battle/quality2.ani")
        imod:PlayAction(0)
        imod:setPosition(cc.p(0, - 80))
        node:addChild(imod,-2)
    elseif quality == 3 then
        local imod = ImodAnim:createWithFile("res2/animation/battle/quality7.png","res2/animation/battle/quality7.ani")
        imod:PlayAction(0)
        imod:setPosition(cc.p(0, - 80))
        node:addChild(imod,-2)
    end
    local _pRoleModel = Utils:CreateAnimModel(AppDef.AwrdItem.AWRD_ITEM_MONSTER, petId)
    node:addChild(_pRoleModel,-1)
    _pRoleModel:PlayStand(3)
    _pRoleModel:setPosition(cc.p(_pRoleModel:getPositionX(), _pRoleModel:getPositionY() - 85))


    -- --print(" 111  ==================>", _pRoleModel:getAnchorPoint().x, _pRoleModel:getAnchorPoint().y)
end

function FuBenDetailUI:ShowMyModel( ... )
    -- body
    self._myNode = cc.Node:create()
    self._myNode:setPosition(cc.p(self._fightPosition.x, self._fightPosition.y + 33))

    self._scrollView:addChild(self._myNode)
    local data = LRoleDataMgr.MyHeroInfo
    self._pMyRoleModel = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero,
                                            data:GetModel(), 
                                            data:GetWeaponId(), 
                                            data.LightEffect,
                                            data.WingsId,
                                            data:GetHorseId(),
                                            data:GetShenQiId())
    self._myNode:addChild(self._pMyRoleModel)
    self._pMyRoleModel:PlayStand(7)
    --print(" 222  ==================>", self._pMyRoleModel:getAnchorPoint().x, self._pMyRoleModel:getAnchorPoint().y)
end

function FuBenDetailUI:ModelMove( ... )
    -- body
    -- --print("ModelMove ==", self._fightPosition.x, self._fightPosition.y)
    local targetPos = cc.p(self._fightPosition.x, self._fightPosition.y)
    print("targetPos:"..targetPos)
    self._pMyRoleModel:PlayRun(self:getRoldDir(self._lastPostion, targetPos))
    local moveAc = cc.MoveTo:create(2, targetPos)
    local moveEnd = cc.CallFunc:create(function( ... )
        --
        self._pMyRoleModel:PlayStand(7)
        --人物移动完再移动镜头
        self:scrollToAimPos()
    end)
    self._myNode:runAction(cc.Sequence:create(dealy, moveAc, moveEnd))
end

function FuBenDetailUI:getRoldDir(pos, targetPos)
    if targetPos == nil then
        return 0
    end
    if targetPos.x > pos.x and targetPos.y < pos.y then
        return 0
    elseif targetPos.x < pos.x and targetPos.y < pos.y then
        return 2
    elseif targetPos.x < pos.x and targetPos.y > pos.y then
        return 4
    elseif targetPos.x >= pos.x and targetPos.y >= pos.y then
        return 6
    end
end

function FuBenDetailUI:refrashData( data )
    -- body
    self._datas = data
end

function FuBenDetailUI:refreshUI( ... )
    -- body
    local panel1 = self._UI:getChildByName("Panel_1")
    self._jindutiao = panel1:getChildByName("jindutiao")

    local xing_0 = panel1:getChildByName("xing_0")
    self._xingshu = panel1:getChildByName("xingshu")

    self._nodePosConfig = JsonConfig.m_mapRes.getDefByID(self._stageData.BundleId)

    self._camera_coor = self._nodePosConfig.camera_coor

    self:initBgPosition()

    self._speakList = {}
    self._guideBtn1 = {}
    self._guideBtn2 = {}

    local btns = nil
    if self._stageData.curChapterID == 1001 then
        btns = self._guideBtn1
    elseif self._stageData.curChapterID == 1002 then
        btns = self._guideBtn2
    end
    for i=1, #self._datas.stageNodeList do
        local data = self._datas.stageNodeList[i]
        local node1 = self._scrollView:getChildByName("Node_"..i)
        node1:setVisible(true)
        if btns ~= nil then
            if btns[i] == nil then
                btns[i] = {}
            end
            btns[i][1] = node1
            btns[i][2] = node1:getChildByName("touchLayer")
        end

        local Image_shuo = node1:getChildByName("Image_qipao")
        local textSpeak = Image_shuo:getChildByName("Text_1_4")
        --print(" ================ data.stageId ===>", data.stageId)
        local configData = JsonConfig.m_stageNodeConfig.getDefByID(data.stageId)
        -- dump(configData,"configData")
        -- textSpeak:ignoreContentAdaptWithSize(false);
        local parentSize = Image_shuo:getContentSize();
        local textWidth = parentSize.width - textSpeak:getPositionX()*2;
        textSpeak:setTextAreaSize(cc.size(textWidth, 0));
        
        textSpeak:setString(configData.Des)
        table.insert(self._speakList, textSpeak)
        local size = textSpeak:getVirtualRendererSize();
        local parentSize = Image_shuo:getContentSize();
        local off = (parentSize.width - textWidth)/2;
        parentSize.height = size.height + off;
        Image_shuo:setContentSize(parentSize);
        ccui.Helper:doLayout(Image_shuo)
        Image_shuo:setVisible(false)

        --设置位置
        if self._nodePosConfig then
            if #self._nodePosConfig.monster_coor >= i then
                local posX = self._nodePosConfig.monster_coor[i][1]
                local posY = self._nodePosConfig.monster_coor[i][2]
                --print("refreshUI =============>", posX, posY)
                node1:setPosition(cc.p(posX, posY + 100))
            end
        end

        local fight_config = JsonConfig.m_vecFightConfig.getDefByID(configData.fightID)
        --print("fight_config.show == 1111 >", fight_config.show)
        self:ShowRoleModel(node1, fight_config.show, configData.type)

        --关卡名字
        local Text_name = node1:getChildByName("Text_name")
        Text_name:setVisible(false)
        Text_name:setString(data.stageName)
        Text_name:setColor(AppDef:GetQualityColor(configData.quality))
        --关卡星星
        for j=1, data.getStarNum do
            local star = node1:getChildByName("laingxing_".. j -1)
            star:setVisible(true)

            local starGrey = node1:getChildByName("anxing_".. j -1)
            starGrey:setVisible(false)
        end

        if self._stageData.selectChapterId == self._stageData.curChapterID then
            if data.stageId == self._stageData.curStageID then
                local zhandou = node1:getChildByName("zhandou")
                zhandou:setVisible(true)
                --记录当前位置
                self._fightPosition = cc.p(self._nodePosConfig.role_coor[i][1], self._nodePosConfig.role_coor[i][2]) 
                --直接移
                self:SetFightPos()
             
       
            
               
                self._curSpeakNode = Image_shuo
                Text_name:setVisible(true)

                --显示自己
                self:ShowMyModel()

            elseif data.stageId < self._stageData.curStageID then
                Text_name:setVisible(true)
            end
        else
            Text_name:setVisible(true)
            --不是当前章节，则默认第一个
            if i == 1 then
                -- self._fightPosition = cc.p(node1:getPosition())
                self._fightPosition = cc.p(self._nodePosConfig.role_coor[1][1], self._nodePosConfig.role_coor[1][2]) 
                self._curSpeakNode = Image_shuo
            end
        end
        
        --关卡宝箱
        --print("refreshUI data.boxId ====>", data.boxId)
        if data.boxId > 0 then
            local itemBox = self._boxCell:clone()
            node1:addChild(itemBox)
            itemBox:setPosition(cc.p(itemBox:getPositionX() + 120, itemBox:getPositionY() - 50))
            itemBox:setVisible(true)
            itemBox:getChildByName("effect_tuitu_1"):addChild(Utils:ReceivableEffect(0.8))
          --  local effect = itemBox:getParent()
            -- --print("打印关卡宝箱",self._boxCell:getChildrenCount())
            -- --print("打印关卡宝箱数量",self._boxCell:getChildByName("effect_tuitu_1"):getName())
            -- --print("打印关卡宝箱数量",:getName())
            --:addChild(self:SetBoxEffect1())
           
            local boxOpen = itemBox:getChildByName("Button")
            -- boxOpen:setScale(0.5)
            boxOpen:setVisible(data.boxState == 2)
            local box = itemBox:getChildByName("Button1")
            -- box:setScale(0.5)
            table.insert(self._stageBoxList, itemBox)
            box:setVisible(data.boxState ~= 2)
            box:getChildByName("Image_1"):setVisible(data.boxState == 1)
            itemBox:getChildByName("effect_tuitu_1"):setVisible(data.boxState == 1)
            box:setTag(data.boxId)
            local boxData = {}
            boxData.boxId = data.boxId
            boxData.boxState =  data.boxState
            boxData.type = self._datas.type
            boxData.chapterId = self._datas.chapterId
            boxData.stageId = data.stageId
            boxData.isStarType = false
            box.userObject = boxData
            box:addClickEventListener(handler(self, FuBenDetailUI.showBoxInfo))
            boxOpen.userObject = boxData
            boxOpen:addClickEventListener(handler(self, FuBenDetailUI.showBoxInfo))
            if self._stageData.curChapterID == 1001 then
                self._guideBoxBtn = box
            end
        end

    end
    self._fubenName:setString(tostring(self._datas.chapterId%1000).." "..self._datas.curStageName)

    --星星宝箱
    for i=1, #self._datas.starBoxlist do
        local data = self._datas.starBoxlist[i]
        self._StarBoxList[i]:getChildByName("Button"):setVisible(data.boxState >= 2)
        self._StarBoxList[i]:getChildByName("Button1"):setVisible(data.boxState < 2)
        self._StarBoxList[i]:getChildByName("Button1"):getChildByName("Image_1"):setVisible(data.boxState == 1)
       
        self._StarBoxList[i]:getChildByName("effect_tuitu_1"):setVisible(data.boxState == 1)
        self._StarBoxList[i]:getChildByName("effect_tuitu_1"):addChild(Utils:ReceivableEffect(0.6))   
        data.type = self._datas.type
        data.chapterId = self._datas.chapterId
        data.isStarType = true
        data.needStarNum = data.needStarNum
        self._StarBoxList[i]:getChildByName("Button1").userObject = data
        self._StarBoxList[i]:getChildByName("Button").userObject = data
    end

    self._xingshu:setString(string.format("%d/%d", self._stageData.ownChapterStarNum, self._stageData.maxStarNum))
    -- --dump(self._datas, "closeDialog ==== 111>")
    self._jindutiao:setPercent(self._stageData.ownChapterStarNum / self._stageData.maxStarNum * 100.0)

    self._Button_zhuxianchengjiu:setVisible(self._stageData.curChapterID >= ZXCJOPENCHP)

    self:scrollToAimPos()

end
function FuBenDetailUI:SetFightPos()
    local curPosX = self._scrollView:getPositionX()
    local posY = self._scrollView:getPositionY()

    local view = cc.Director:getInstance():getOpenGLView():getFrameSize()
    local tmepEndPos = self._endPos[1]*16/9/(view.width/view.height)
    local halfScreen = view.width / 2
    if  self._fightPosition.x < halfScreen then
        return
    end
    local aimPosX = curPosX - self._fightPosition.x

    if -aimPosX>tmepEndPos then
        aimPosX=-tmepEndPos
    else
        aimPosX=aimPosX+halfScreen
    end
    local aimPosY = self:FindScreenPosY(aimPosX, posY)
    self._scrollView:setPosition(cc.p(aimPosX, -aimPosY))
   
end
-- function FuBenDetailUI:SetBoxEffect()
--     local bgAnim = "res2/animation/effect_tuitu_1"
--     local m_pBgAni = ImodAnim:create()
--     m_pBgAni:initAnimWithNameSync(bgAnim)
--     m_pBgAni:PlayActionRepeat(0)
--     m_pBgAni:setScale(0.6)
--     return m_pBgAni
-- end
-- function FuBenDetailUI:SetBoxEffect1()
--     local bgAnim = "res2/animation/effect_tuitu_1"
--     local m_pBgAni = ImodAnim:create()
--     m_pBgAni:initAnimWithNameSync(bgAnim)
--     m_pBgAni:PlayActionRepeat(0)
--     m_pBgAni:setScale(0.8)
--     return m_pBgAni
-- end
function FuBenDetailUI:getBoxByBoxId( boxId )
    -- body
    --dump(self._stageBoxList, "getBoxByBoxId ===>")
    for i=1, #self._stageBoxList do
        local boxCell = self._stageBoxList[i]
        local box = boxCell:getChildByName("Button1")
        --dump(box.userObject, "box.userObject ==>")
        if box.userObject.boxId == boxId then
            return boxCell
        end
    end
    return nil
end

function FuBenDetailUI:FindScreenPosY(screenX, screenY)
    if self._camera_coor == nil then
        return 0
    end
    local converX = -screenX
    -- --print("FindScreenPosY ==>", converX)
    local converY = -screenY
    for i=1, #self._camera_coor - 1 do
        local pos = self._camera_coor[i]
        local nextPos = self._camera_coor[i + 1]
        if converX > pos[1] and converX < nextPos[1] then
        	-- --print("FindScreenPos x = ", converX, pos[1], pos[2], nextPos[1], nextPos[2])
        	if nextPos[2] > pos[2] then
        		return (converX - pos[1])*(nextPos[2] - pos[2]) / (nextPos[1] - pos[1]) + pos[2]
            elseif nextPos[2] == pos[2] then
                return nextPos[2]
        	else
        		return pos[2] - (converX - pos[1])*(pos[2] - nextPos[2]) / (nextPos[1] - pos[1])
        	end
        elseif converX >= self._endPos[1] then
            return self._endPos[2]
        elseif converX <= self._beginPos[1] then
            return self._beginPos[2]
        end
    end
    return 0
end

function FuBenDetailUI:ScrollEvent(sender, ScrollviewEventType)
    --暂时关闭
    -- --print("ScrollEvent ===", ScrollviewEventType, SCROLLVIEW_EVENT_SCROLLING, SCROLLVIEW_EVENT_CONTAINER_MOVED)
    local pos = sender:getInnerContainerPosition()
    -- local posX  = self:getLeftPosX()
    -- if ScrollviewEventType == SCROLLVIEW_EVENT_CONTAINER_MOVED then
    --     --print("ScrollEvent == x = , y =", pos.x, pos.y, posX)
    --     if (-pos.x) < posX then
    --         sender:setInnerContainerPosition(cc.p(-posX, pos.y))
    --     end
    -- end

    -- --print("ScrollEvent  pos.x, pos.y ===>", pos.x, pos.y)
    if ScrollviewEventType == SCROLLVIEW_EVENT_CONTAINER_MOVED then
        local finalPosY = self:FindScreenPosY(pos.x, pos.y)
        -- --print("ScrollEvent finalPosY ---", finalPosY)
        -- sender:setInnerContainerPosition(cc.p(pos.x, finalPosY))
        local rate = ((-finalPosY - 291) / 291) * 100.0
        -- --print("ScrollEvent rate ==", rate)
        sender:scrollToPercentVertical(rate, 0.3, true)
        -- sender:scrollToPercentVertical(50, 0.3, true)
    end


end

function FuBenDetailUI:getStarBoxByBoxId(boxId)
    -- body
    for i=1, #self._StarBoxList  do
        local boxCell = self._StarBoxList[i]
        --print("boxCell ===", boxCell)
        local box = boxCell:getChildByName("Button1")
        if box.userObject.boxId == boxId then
            return boxCell
        end
    end
    return nil
end

function FuBenDetailUI:closeDialog( sender )
    -- body
    Utils:DeleteUI("FuBenMap.FuBenDetailUI")
end

function FuBenDetailUI:DeleteSchedule()
    if self.m_refreshHandler then
        
        Utils:unschedule(nil, self.m_refreshHandler)
        self.m_refreshHandler = nil
    end
end

function FuBenDetailUI:AddSchedule()
    self:DeleteSchedule()
    local function RefreshCallback(dt)
        -- --print("AddSchedule ===============================================>")
        -- local scale1 = cc.ScaleTo:create(0.1, 0.1)
        if self._curSpeakNode == nil then
            return
        end
        local scale2 = cc.ScaleTo:create(0.2, 1.2)
        local scale3 = cc.ScaleTo:create(0.2, 1.0)
        local dealy = cc.DelayTime:create(2)
        local func = cc.CallFunc:create(function( ... )
            -- body
            self._curSpeakNode:setVisible(false)
        end )
        self._curSpeakNode:setVisible(true)
        self._curSpeakNode:runAction(cc.Sequence:create(scale2, scale3, dealy, func))

    end
    self.m_refreshHandler = Utils:schedule(nil, RefreshCallback, 5, false)
end

-----------------------------------
function FuBenDetailUI:ScheduleStart()
    self:ScheduleEnd()
    self.m_schedule = Utils:schedule(nil, handler(self, self.updateSchedule), 1/30, false)

end
-----------------------------------
function FuBenDetailUI:ScheduleEnd()
    if self.m_schedule then
        Utils:unschedule(nil, self.m_schedule)
    end
    self.m_schedule = nil
end
-- self._scrollView:setPosition(cc.p(self._fightPosition.x, self:FindScreenPosY(self._fightPosition.x, self._scrollView:getPositionY())))
function FuBenDetailUI:updateSchedule( dt )
    -- body

    if self._scroolToAim then
        local curPosX = self._scrollView:getPositionX()
        local posY = self._scrollView:getPositionY()
        local view = cc.Director:getInstance():getOpenGLView():getFrameSize()
       
        local halfScreen = view.width / 2
        local tmepEndPos = self._endPos[1]*1334/750/(view.width/view.height)
        --local halfScreen = 1334 / 2
        -- --print("updateSchedule == 1111111111111>", curPosX, posY, self._fightPosition.x)
        if self._fightPosition.x < halfScreen or -curPosX > (self._fightPosition.x - halfScreen) or -curPosX >tmepEndPos then
            self._scroolToAim = false
        end

        local addLength = SCREENSPEED * dt
        -- --print("updateSchedule == 11111111111 >", addLength)
        local aimPosX = curPosX - addLength
        local aimPosY = self:FindScreenPosY(aimPosX, posY)

        self._scrollView:setPosition(cc.p(aimPosX, -aimPosY))
        if not self._scroolToAim then
            local curGuideId = LUserConfigMgr:GetUserCurGuide()
            if curGuideId == 201 or curGuideId == 316  then
                Utils:CheckGuide(curGuideId,true)
            end
        end
    end
end

function FuBenDetailUI:onExit()
    Utils:SendMsg(LAudioEvent.PlayBgMusic, AppDef.MainBGM)
    local guideIds = {GuideDef.StepId.Guide_FuBen_2,GuideDef.StepId.Guide_FuBen1,GuideDef.StepId.Guide_Pet_13
        ,GuideDef.StepId.Guide_Pet_15,GuideDef.StepId.Guide_FuBen2_13,GuideDef.StepId.Guide_FuBen3_13
        ,GuideDef.StepId.Guide_FuBen4_1,GuideDef.StepId.Guide_Equip_12,GuideDef.StepId.Guide_Pet
        ,GuideDef.StepId.Guide_FuBen2_2,GuideDef.StepId.Guide_FuBen3_2,GuideDef.StepId.Guide_Equip
        ,GuideDef.StepId.Guide_Pet1,GuideDef.StepId.Guide_Arena,GuideDef.StepId.Guide_XunBao
        ,GuideDef.StepId.Guide_FuBen2,GuideDef.StepId.Guide_FuBen3}
    for i=1,#guideIds do
        Utils:SendMsg(LUIGuideEvent.UnRegisterStep, guideIds[i])
    end
    guideIds = {GuideDef.StepId.Guide_Pet_1,GuideDef.StepId.Guide_FuBen2_3,GuideDef.StepId.Guide_FuBen3_3
        ,GuideDef.StepId.Guide_Equip_1,GuideDef.StepId.Guide_Pet1_1,GuideDef.StepId.Guide_Arena_1
        ,GuideDef.StepId.Guide_XunBao_1}
    for i=1,#guideIds do
        Utils:CheckGuide(guideIds[i],true)
    end
    self:Destory()
    self:DeleteSchedule()
    self:ScheduleEnd()
    self.m_pUILayer = nil
    self._stageBoxList = nil
    self._StarBoxList = nil
end

function FuBenDetailUI:RegisterGuide()
    --print("FuBenDetailUI:RegisterGuide")
    local guideIds = {{GuideDef.StepId.Guide_FuBen_2,true},{GuideDef.StepId.Guide_FuBen1,false},{GuideDef.StepId.Guide_Pet_13,true}
        ,{GuideDef.StepId.Guide_Pet_15,true},{GuideDef.StepId.Guide_FuBen2_13,true},{GuideDef.StepId.Guide_FuBen3_13,true}}
    if self._guideBtn1 ~= nil then
        for i=1,#self._guideBtn1 do
            local btn = self._guideBtn1[i]
            if btn ~= nil then
                Utils:RegisterGuide(guideIds[i][1], btn[1], function()
                    if btn[2] ~= nil and self.m_pUILayer ~= nil then
                        self:showStageInfoUI(btn[2])
                    end
                end, nil, guideIds[i][2])
            end
        end
    end
    guideIds = {GuideDef.StepId.Guide_FuBen4_1,GuideDef.StepId.Guide_Equip_12}
    if self._guideBtn2 ~= nil then
        for i=1,#self._guideBtn2 do
            local btn = self._guideBtn2[i]
            if btn ~= nil then
                Utils:RegisterGuide(guideIds[i], btn[1], function()
                    if btn[2] ~= nil and self.m_pUILayer ~= nil then
                        self:showStageInfoUI(btn[2])
                    end
                end, nil,true)
            end
        end
    end

    guideIds = {{GuideDef.StepId.Guide_Pet,false},{GuideDef.StepId.Guide_FuBen2_2,false},{GuideDef.StepId.Guide_FuBen3_2,false}
        ,{GuideDef.StepId.Guide_Equip,false},{GuideDef.StepId.Guide_Pet1,false},{GuideDef.StepId.Guide_Arena,false}
        ,{GuideDef.StepId.Guide_XunBao,false}}
    if self._guideBtn then
        for i=1,#guideIds do
            Utils:RegisterGuide(guideIds[i][1],self._guideBtn,handler(self,FuBenDetailUI.closeDialog), nil,guideIds[i][2])
        end
    end

    if self._guideBoxBtn ~= nil then
        Utils:RegisterGuide(GuideDef.StepId.Guide_FuBen3,self._guideBoxBtn,function ()
            self:showBoxInfo(self._guideBoxBtn)
        end, nil,false)
    end

    self._guideStarBoxBtn = self._StarBoxList[1]:getChildByName("Button1") 
    if self._guideStarBoxBtn ~= nil then
        Utils:RegisterGuide(GuideDef.StepId.Guide_FuBen2,self._guideStarBoxBtn,function()
            self:showBoxInfo(self._guideStarBoxBtn)
        end, nil,false)
    end
end

function FuBenDetailUI:UpdateRedDot()

    local showFBAc = Utils:GetRedDotState(RedDotDef.ID.FuBenAchievement)
    print("FuBenDetailUI:UpdateRedDot ========== 111 >", showFBAc)
    self._achiPrompt:setVisible(showFBAc)

    local isShowRed = Utils:GetRedDotState(RedDotDef.ID.ShenJiangZhenRong)
    self._btn_zhenrong:getChildByName("Prompt"):setVisible(isShowRed)
    
end

return FuBenDetailUI