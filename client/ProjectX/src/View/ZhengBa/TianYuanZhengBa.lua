
local TianYuanZhengBa = LUIBase:New()
TianYuanZhengBa.__index = TianYuanZhengBa
local TimerLabelUI = require("View.Common.TimerLabelUI")
--local this = LTcpSocket
function TianYuanZhengBa:New()
	local o = LUIBase:New()
	setmetatable(o,TianYuanZhengBa)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function TianYuanZhengBa:RegistMsgs()
    self.msgIds = 
    {
        LUIWeiWoDuXianEvent.UpdateWWDXPreUIEvent,
        LUIWeiWoDuXianEvent.UpdateWWDXLeftSecond,
        LUIWeiWoDuXianEvent.UpdateWWDXLeftTimes,
        LUIWeiWoDuXianEvent.UpdateWWDXGroupEvent,
        LUIWeiWoDuXianEvent.UpdateWWDXCostEvent,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function TianYuanZhengBa:ProcessEvent(msg)
    local msgId = msg:GetMsgId()
    if msgId == LUIWeiWoDuXianEvent.UpdateWWDXPreUIEvent then
        self:loadData(msg.value)
        self:refreshUI()
    elseif msgId == LUIWeiWoDuXianEvent.UpdateWWDXLeftSecond then
--        print("second", msg.value[2])
        self:resetCDTime(msg.value[2])
    elseif msgId == LUIWeiWoDuXianEvent.UpdateWWDXLeftTimes then
        self:updateBuyCost(msg.value)
        self:refrashLeftTimes()
    elseif msgId == LUIWeiWoDuXianEvent.UpdateWWDXGroupEvent then
        if msg.value == nil then
            return
        end
        self:updatePaiHang(msg.value[1])
    elseif msgId == LUIWeiWoDuXianEvent.UpdateWWDXCostEvent then
        
    end
end

function TianYuanZhengBa:Init()

    self.m_pUILayer = cc.CSLoader:createNode("csd/ZhengbaLayer.csb")
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

function TianYuanZhengBa:initControlUI( ... )
    -- body
    local panel = self.m_pUILayer:getChildByName("Panel_0")
    local imageBg = panel:getChildByName("ImageBg")
    local closeUIBtn = panel:getChildByName("CloseBtn")
    local function closeEvent( sender )
        -- body
        self:CloseDialog()
    end
    closeUIBtn:addClickEventListener(closeEvent)
	self:MarkIntaractCObj(closeUIBtn)
-----------------------------------------------------------------------
    local roleList = panel:getChildByName("RoleList")
    self._roleListPanel = roleList
    self._roleList = {}

    local function enterbattleEvent( sender )
        -- body
        local index = sender.userObject
--        print("enterbattleEvent --------------", index)
--       self:CloseDialog()
        if self.GroupData.leftTimes <= 0 then
            Utils:ShowScrollTips(GUITips.RIS_LEFTUI_MSG173)
            return
        elseif self._leftTime > 0 then
            Utils:ShowScrollTips(GUITips.RIS_LEFTUI_MSG166)
            return
        else
            self:goFight(index)
        end
        
    end

    for i=1, 5 do
        local strConfig = string.format("BaseImage_%d", i)
        local baseImage = roleList:getChildByName(strConfig)
        table.insert(self._roleList, baseImage)
        local touchPanel = baseImage:getChildByName("Panel")
        touchPanel:addClickEventListener(enterbattleEvent)
		self:MarkIntaractCObj(touchPanel)
        touchPanel.userObject = i
    end

-----------------------------------------------------------------------
--报名界面
    self._readyUI = panel:getChildByName("Ready")
    self._readyUI:setTouchEnabled(false)
    
    --报名参加
    self._baoMingBtn = self._readyUI:getChildByName("Button_3")
    local function baoMingBtnEvent( sender )
        -- body
        self._enroll:setVisible(true)
    end
    self._baoMingBtn:addClickEventListener(baoMingBtnEvent)
	self:MarkIntaractCObj(self._baoMingBtn)
-----------------------------------------------------------------------
    local title = panel:getChildByName("Title")
    self._titlePanel = title

    local levelBg = title:getChildByName("LevelBg")
    self._match = levelBg:getChildByName("Match")
    self._GroupIcon = levelBg:getChildByName("Group")

    local paihang = title:getChildByName("Paihang")
    local function paihangEvent( sender )
        -- body
        LuaNetSendMsg:QuerySingleImmortalInfo(3, self.GroupData.groupId)
    end
    paihang:addClickEventListener(paihangEvent)
	self:MarkIntaractCObj(paihang)
        --预览规则
    local preRule = title:getChildByName("Button_1")
    local function preRuleEvent( sender )
        -- body
--        Utils:ShowDialog(GUITips.RSI_WWDX_TIPS_3, GUITips.RSI_WELFARE_MSG38)
        self:helpButtonCallback()
    end
    preRule:addClickEventListener(preRuleEvent)
	self:MarkIntaractCObj(preRule)
--上届对战
    local lastBattle = title:getChildByName("Button_2")
    local function lastBattleEvent( sender )
        -- body
--        self:CloseDialog()

--临时这样写
        -- LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "ZhengBa.PreliminnaryUI", AppDef.UIType.Chat )
        -- LUIManager:SendMsg(LGameMsg.m_initUIMsg)

--战斗UI面板, 测试使用
        -- LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "ZhengBa.WwdxBettleUI", AppDef.UIType.Chat )
        -- LUIManager:SendMsg(LGameMsg.m_initUIMsg)

--请求上届信息
        LuaNetSendMsg:QueryWWDXFinalInfo(0, false)

    end
    lastBattle:addClickEventListener(lastBattleEvent)
	self:MarkIntaractCObj(lastBattle)
-----------------------------------------------------------------------
    local functionNode = panel:getChildByName("Function")
    self._functionNode = functionNode
--宝箱
    self._boxBtn = functionNode:getChildByName("BoxBtn")
    local function boxBtnEvent ( sender )
        -- body
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "ZhengBa.BoxInfoUI", AppDef.UIType.PopWindow)
        self:SendMsg(LGameMsg.m_initUIMsg)

        LGameMsg.m_baseMsgWithOne:Change(LUIWeiWoDuXianEvent.UpdateBoxInfo, {self.GroupData.boxId, self.GroupData.boxText})
        self:SendMsg(LGameMsg.m_baseMsgWithOne)

    end
    self._boxBtn:addClickEventListener(boxBtnEvent)
	self:MarkIntaractCObj(self._boxBtn)
    self._totalSocre = self._boxBtn:getChildByName("AllFen"):getChildByName("Value")
    local loading = functionNode:getChildByName("Loading")
    self._loadingBar = loading:getChildByName("LoadingBar")
    self._loadingBar:setPercent(60)

    self._myRankValue = self._boxBtn:getChildByName("Paiming"):getChildByName("Value")

    self._icon1 = loading:getChildByName("Icon_1")
    --icon 的 child Text
    self._icon2 = loading:getChildByName("Icon_2")
    self._icon3 = loading:getChildByName("Icon_3")
    self._curActiveValue = loading:getChildByName("Activity"):getChildByName("Value")
    local activeAwardBtn = functionNode:getChildByName("Button_3")    
    local function activeAwardEvent( sender )
        -- body
    end
    activeAwardBtn:addClickEventListener(activeAwardEvent)
	self:MarkIntaractCObj(activeAwardBtn)
    local times = functionNode:getChildByName("Times")
    self._leftTimes = times:getChildByName("Text"):getChildByName("Text")
    self._greenColor = self._leftTimes:getTextColor()

    local btnBuyTimes = times:getChildByName("Button")
    local function addTimes( sender )
        -- body
        local strCost = string.format(GUITips.RIS_LEFTUI_MSG159, self.GroupData.cost) 
        Utils:ShowDialogOKCancel(strCost, function()
            --请求预赛增加挑战次数
            if self.GroupData.leftTimes >= self.GroupData.maxTimes then
                Utils:ShowScrollTips(GUITips.RIS_LEFTUI_MSG162)
            else
                LuaNetSendMsg:QueryWeiWoDuXian(6)
            end
        end, function()end)

    end
    btnBuyTimes:addClickEventListener(addTimes)
	self:MarkIntaractCObj(btnBuyTimes)
    local CDTime = functionNode:getChildByName("CDtime")
    self._cdText = CDTime:getChildByName("Text"):getChildByName("Text")
    self._cdColor = self._cdText:getTextColor()
    local clearTime = CDTime:getChildByName("Button_0")
    local function clearTimeEvent( sender )
        -- body
        --请求预赛清除CD时间
        local myGold = LRoleDataMgr.MyHeroInfo:GetDetailData().TongBao
        local cost = 50
        if  myGold >= cost then
            local str = string.format(GUITips.RIS_LEFTUI_MSG160, cost)
            Utils:ShowDialogOKCancel(str, function()
                LuaNetSendMsg:QueryWeiWoDuXian(7)
            end, function()end)
        else
            Utils:ShowScrollTips(GUITips.RIS_LEFTUI_MSG161)
        end
    end
    clearTime:addClickEventListener(clearTimeEvent)
	self:MarkIntaractCObj(clearTime)
    local refrashImage = functionNode:getChildByName("Refresh")
    local reFrashBtn = refrashImage:getChildByName("Button_0")
    local function refrashEvent( sender )
        -- body
        local strTips
        if self.GroupData.isFreeRefersh then
            strTips = GUITips.RIS_LEFTUI_MSG167
        else
            strTips = GUITips.RIS_LEFTUI_MSG163
        end
        
        Utils:ShowDialogOKCancel(strTips, function()
            --刷新敌人
            LuaNetSendMsg:QueryWeiWoDuXian(5)
        end, function()end)
    end
    reFrashBtn:addClickEventListener(refrashEvent)
	self:MarkIntaractCObj(reFrashBtn)
    self._refrashText = refrashImage:getChildByName("Text")
    self._refrashText:setString(GUITips.RIS_LEFTUI_MSG169)
--报名
-----------------------------------------------------------------------
    self._enroll = panel:getChildByName("Enroll")
    self._enroll:setVisible(false)
    local baoming = self._enroll:getChildByName("Baoming")
    local bg = baoming:getChildByName("bg")

    local btnClose = bg:getChildByName("Btn_close")
    local function btnCloseEvent( sender )
        -- body
        self._enroll:setVisible(false)
    end
    btnClose:addClickEventListener(btnCloseEvent)
	self:MarkIntaractCObj(btnClose)

    self._tipsText = baoming:getChildByName("TipsText")

    local btnCon = baoming:getChildByName("Btn_Confirm")
    local function btnConfirmEvent( sender )
        -- body
        self._enroll:setVisible(false)
        LuaNetSendMsg:QueryWeiWoDuXian(2)
    end
    btnCon:addClickEventListener(btnConfirmEvent)
	self:MarkIntaractCObj(btnCon)
----------------------------------------------------------------------
    self._PaihangTips = panel:getChildByName("PaihangTips")
    self._paihangListView = self._PaihangTips:getChildByName("ListView_1")
    self._paihangTitle = self._PaihangTips:getChildByName("Title")
    local paihangColse = self._PaihangTips:getChildByName("CloseBtn")
    local function paihangClose( sender )
        -- body
        self._PaihangTips:setVisible(false)
    end
    paihangColse:addClickEventListener(paihangClose)
	self:MarkIntaractCObj(paihangColse)
    self._paiHangCell = self._PaihangTips:getChildByName("Name")
    self._paiHangCell2 = self._PaihangTips:getChildByName("Name_0")

end

function TianYuanZhengBa:helpButtonCallback()
    local str = GUITips.RSI_WWDX_TIPS_3
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

function TianYuanZhengBa:CloseDialog( ... )
    -- body

    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "ZhengBa.TianYuanZhengBa")
    self:SendMsg(LGameMsg.m_initUIMsg)

end

function TianYuanZhengBa:showBuyTimesUI(value)
    local function OKCallback()

    end

    local function cancelCallback()

    end

    Utils:ShowBuyTimesDialog(value.price, value.useType, value.buyNum, value.maxBuyNum, OKCallback, cancelCallback)
end

function TianYuanZhengBa:loadData( data )
    -- body
    if data.boxId == nil then
        return
    end

    self.GroupData = data
    
--    dump(self.GroupData, "loadData---")
end

function TianYuanZhengBa:updateUIState()
    self._baoMingBtn:setVisible(false)
    self._readyUI:setVisible(false)
    self._enroll:setVisible(false)
    self._titlePanel:setVisible(true)
    self._roleListPanel:setVisible(true)
    self._functionNode:setVisible(true)
end

function TianYuanZhengBa:refreshUI( ... )

--宝箱
--    self.GroupData.boxId
    if self.GroupData.boxId == nil then
        return
    end
    self:updateUIState()

--    dump(self.GroupData, "TianYuanZhengBa:refreshUI")

    --宝箱资源编号和boxId是相反的, 这里转换一下
    local strBox = string.format("res/UI/ui_wanfa/ui_weiwoduxian_baoxiang%d.png", 6 - self.GroupData.boxId)
    self._boxBtn:loadTextureNormal(strBox, UI_TEX_TYPE_PLIST)

--    self._match:setString()
    local str = string.format("res/UI/ui_wanfa/ui_weiwoduxian_wenzi_0%d.png", self.GroupData.groupId)
    self._GroupIcon:loadTexture(str, UI_TEX_TYPE_PLIST)

    if self._timerLabel == nil then
        self._timerLabel = TimerLabelUI:New(self._cdText, nil, nil, handler(self, self.TimeReduce))
--        print("refreshUI----- coolTime", self.GroupData.coolTime)
        if self.GroupData.coolTime > 0 then
            self._timerLabel:set(self.GroupData.coolTime)
            self._timerLabel:start()
        else
            self:TimeReduce(self._cdText, 0, 0 ,0, 0)
        end
        
    end

    if self.GroupData.isFreeRefersh then

    else
        local strDes = string.format(GUITips.RSI_WWDX_TIPS_1, self.GroupData.refrashCost)
        self._refrashText:setString(strDes)
    end

    self:refrashLeftTimes()

    self._myRankValue:setString(self.GroupData.myRank)
    self._totalSocre:setString(self.GroupData.myScore)

    self:updateRole()

end

function TianYuanZhengBa:updateBuyCost(data)
    -- body
    self.GroupData.cost = data[3]
    self.GroupData.leftTimes = data[2]
end

function TianYuanZhengBa:refrashLeftTimes( ... )
    -- body
    local str = string.format(GUITips.RSI_WWDX_TIPS_2, self.GroupData.leftTimes)
    self._leftTimes:setString(str)
end


function TianYuanZhengBa:updateRole( ... )
    -- body
    for i=1, #self.GroupData.groupHeroInfo do
        local UINode = self._roleList[i]
        local data = self.GroupData.groupHeroInfo[i]

--        print("hero info", data.professional, data:GetWeaponId(), data.LightEffect, data.WingsId, data.name, data.vipLevel)
        local pRoleModel = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, 
                                    data.professional, 
                                    data.weponId, 
                                    data.LightEffect,
                                    data.WingsId,
                                    0,
                                    0)
        local node = UINode:getChildByName("Node")
        local lastCode = node:getChildByTag(10234 + i)
        if lastCode then
            lastCode:removeFromParent()
        end

        node:addChild(pRoleModel)
        pRoleModel:PlayStand(0)
        pRoleModel:setTag(10234 + i)

        local nameBg = UINode:getChildByName("NameBg")
        local nameStr = nameBg:getChildByName("Text")
        nameStr:setString(data.name)

        local VIPImage = nameBg:getChildByName("VIPImage")
        local vipValue = VIPImage:getChildByName("AtlasLabel")
        if data.vipLevel <= 0 then
            VIPImage:setVisible(false)
        else
            vipValue:setString(data.vipLevel)
        end

        local powerBg = UINode:getChildByName("PowerBg")
        local powerValue = powerBg:getChildByName("Text"):getChildByName("Value")
        powerValue:setString(data.zhanDouLi)

        local jifenBg = UINode:getChildByName("JifenBg")
        local jifenValue = jifenBg:getChildByName("Text"):getChildByName("Value")
        jifenValue:setString(data.mid)
    end

end

function TianYuanZhengBa:TimeReduce(pText, h, m, s, left)
    if pText == nil then
        return
    end

    self._leftTime = left

    if left <= 0 then
        pText:setTextColor(self._greenColor)
    else
        pText:setTextColor(self._cdColor)
    end

    local str = ""
    local day = 0
    if h > 24 then
        day = math.floor(h / 24)
        h = math.fmod(h, 24)
    end
    if day > 0 then
        str = str..tostring(day)..GUITips.Item_Info_Day
        str = str..string.format("%02d:%02d", h, m)
    else
        str = str..string.format("%02d:%02d:%02d", h, m, s)
    end
    
    pText:setString(str)
end

function TianYuanZhengBa:resetCDTime( second )
    -- body
    if second > 0 then
        self._timerLabel:set(second)
        self._timerLabel:start()
    else
        self.GroupData.coolTime = second
        self._timerLabel:stop()
        self:TimeReduce(self._cdText, 0, 0 ,0, 0)
    end
end

function TianYuanZhengBa:updatePaiHang(rankInfo)
    -- body
    self._PaihangTips:setVisible(true)
--    dump(rankInfo, "rankInfo *********************")
    self._paihangListView:removeAllItems()

--测试代码
    -- rankInfo = {}
    -- for i=1, 10 do
    --     local temp = GroupRankInfo:New()
    --     if i == 5 then
    --         temp.id = 0;
    --         temp.name = "";
    --         temp.score = 0;
    -- --                rankInfo.push_back(temp);
    --         table.insert(rankInfo, temp)
    --     end
    --     temp.id = 20
    --     temp.name = "天元争霸优化"
    --     temp.score = 300
    --     table.insert(rankInfo, temp)
    -- end

    local paiHangIndex = 1
    for i=1, #rankInfo do
        local item 
        if i == 5 then
            item = self._paiHangCell2:clone()
        else
            item = self._paiHangCell:clone()
            local placeImage1 = item:getChildByName("PlaceImage1")
            local placeImage2 = item:getChildByName("PlaceImage2")
            local placeImage3 = item:getChildByName("PlaceImage3")
            local placeNum = item:getChildByName("PlaceNum")
            if i == 1 then
                placeImage1:setVisible(true)
                placeImage2:setVisible(false)
                placeImage3:setVisible(false)
                placeNum:setVisible(false)
            elseif i == 2 then
                placeImage1:setVisible(false)
                placeImage2:setVisible(true)
                placeImage3:setVisible(false)
                placeNum:setVisible(false)
            elseif i == 3 then
                placeImage1:setVisible(false)
                placeImage2:setVisible(false)
                placeImage3:setVisible(true)
                placeNum:setVisible(false)
            else
                placeImage1:setVisible(false)
                placeImage2:setVisible(false)
                placeImage3:setVisible(false)
                placeNum:setVisible(true)
                placeNum:setString(paiHangIndex)
            end
            
            local placeName = item:getChildByName("PlaceName")
            placeName:setString(rankInfo[i].name)

            local PowerNum = item:getChildByName("PowerNum")
            PowerNum:setString(rankInfo[i].score)

            paiHangIndex = paiHangIndex + 1

        end
        self._paihangListView:pushBackCustomItem(item)

        local str = string.format("res/UI/ui_wanfa/ui_weiwoduxian_wenzi_0%d.png", self.GroupData.groupId)
--        local str = string.format("res/UI/ui_wanfa/ui_weiwoduxian_wenzi_0%d.png", 1)
        self._paihangTitle:loadTexture(str, UI_TEX_TYPE_PLIST)
    end

end

function TianYuanZhengBa:goFight(index)
    local data = self.GroupData.groupHeroInfo[index]
    LWWDXMgr:loadCurBattleData(data)
    local str = string.format(GUITips.RIS_LEFTUI_MSG168, data.name, data.mid)
    local function okFunc()
        self:CloseDialog()

        LuaNetSendMsg:QuerySingleImmortalInfo(4, index)
    end
    local function cancelFunc()
    end
    Utils:ShowDialogOKCancel(str, okFunc, cancelFunc)
end

function TianYuanZhengBa:onExit()
    self.m_pUILayer = nil
    local _ = self._timerLabel and self._timerLabel:Destory()
    self._roleListPanel = nil
    Utils:FreeTable(self._roleList)
-----------------------------------------------------------------------
--报名界面
    self._readyUI = nil
    --报名参加
    self._baoMingBtn = nil
-----------------------------------------------------------------------
    self._titlePanel = nil
    self._match = nil
    self._GroupIcon = nil
-----------------------------------------------------------------------
    self._functionNode = nil
--宝箱
    self._boxBtn = nil
    self._totalSocre = nil
    self._loadingBar = nil
    self._myRankValue = nil
    self._icon1 = nil
    --icon 的 child Text
    self._icon2 = nil
    self._icon3 = nil
    self._curActiveValue = nil
    self._leftTimes = nil
    self._greenColor = nil

    self._cdText = nil
    self._cdColor = nil
    self._refrashText = nil

--报名
-----------------------------------------------------------------------
    self._enroll = nil
    self._tipsText = nil
----------------------------------------------------------------------
    self._PaihangTips = nil
    self._paihangListView = nil
    self._paihangTitle = nil
    self._paiHangCell = nil
    self._paiHangCell2 = nil
    self:Destory()
end

return TianYuanZhengBa