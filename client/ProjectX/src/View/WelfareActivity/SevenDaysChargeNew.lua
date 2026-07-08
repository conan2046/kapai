
local SevenDaysChargeNew = LUIBase:New()
SevenDaysChargeNew.__index = SevenDaysChargeNew
local TimerLabelUI = require("View.Common.TimerLabelUI")
--local this = LTcpSocket
function SevenDaysChargeNew:New(parent)
	local o = LUIBase:New()
	setmetatable(o,SevenDaysChargeNew)	
    o:Init(parent)
	return o
end

--注册事件
-- -----------------------------------
function SevenDaysChargeNew:RegistMsgs()
    self.msgIds = 
    {
        LUIWelfareEvent.updateSevenCharge,
        LUIWelfareEvent.refrashSevenChargeUI,
        LUIWelfareEvent.refrashAwardBtn,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function SevenDaysChargeNew:ProcessEvent(msg)
    -- if msg.msgId == LUIWelfareEvent.updateSevenCharge then
    --     print("SevenDaysChargeNew 7777777777777777")
    --     self:updateData()
    -- end

--购买成功后刷新界面
    if msg.msgId == LUIWelfareEvent.refrashSevenChargeUI then
        self:updateDayAwardBtn()
    end

--领取额外奖励
    if msg.msgId == LUIWelfareEvent.refrashAwardBtn then
        self:refrashOtherAwardUI()
    end

end

function SevenDaysChargeNew:Init(parent)
    self.m_pUILayer = cc.CSLoader:createNode("csd/huodong/SevenDaysLayer.csb")
    parent:addChild(self.m_pUILayer)
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:InitUIControl() 
    self._inited = false
    self._awardDay = 0

    self:initData()
    self:updateData()
end

function SevenDaysChargeNew:onExit()
    self.m_pUILayer = nil
    self:Destory()
    local _ = self.m_timerLabel and self.m_timerLabel:Destory()
end

function SevenDaysChargeNew:InitUIControl()
    local panel = self.m_pUILayer:getChildByName("SevenDays")
    local top = panel:getChildByName("Top")
    local chargeBtn = top:getChildByName("btn_0")
    local function toChargeEvent( sender )
        -- body
        Utils:OpenRechargeMainUI()
    end
    chargeBtn:addClickEventListener(toChargeEvent)
	self:MarkIntaractCObj(chargeBtn)
    self._time = top:getChildByName("Text_1"):getChildByName("Time")
    self._curChargeStr = top:getChildByName("Text_3"):getChildByName("Time")
    self._curChargeStr2 = top:getChildByName("Text_2"):getChildByName("Value")


    local into = panel:getChildByName("Into")
    self._listView = into:getChildByName("ListView")
    self._itemCell = into:getChildByName("Reward_1")
    local loading = into:getChildByName("Loading")
    local Bg = into:getChildByName("Bg")
    self._awardList = Bg:getChildByName("ListView")
    self._awardCell = Bg:getChildByName("Item")
    self._awardCellSize = self._awardCell:getContentSize()
    self._getAwardBtn = Bg:getChildByName("btn")
    self._petAwardCell = Bg:getChildByName("IconColor")
    self._AtlasLabel = Bg:getChildByName("AtlasLabel_2")

    self.m_LoadingBar = loading:getChildByName("LoadingBar")
    self._Receive = Bg:getChildByName("ImageReceive")

    local function GetAwardEvent( sender )
        -- body
        local lightStarNum = LRechargeDataMgr:getLightStarNum()
        local awardLightStarNum = LRechargeDataMgr:getCurAwardLightNum()
--        print("GetAwardEvent ----", lightStarNum, awardLightStarNum)
        LuaNetSendMsg:QuerySevenChargeStarAward(35, 2, 2, awardLightStarNum)
    end
    self._getAwardBtn:addClickEventListener(GetAwardEvent)
	self:MarkIntaractCObj(self._getAwardBtn)
    self._starArr = {}
    for i=1, 7 do
        local str = string.format("Image_%d", i)
        local star = loading:getChildByName(str):getChildByName("Star")
        table.insert(self._starArr, star)
    end
    self.m_timerLabel = nil

--展示时间
    self:setLabel(self._time)

end

function SevenDaysChargeNew:initData( ... )
    -- body
--    local isNeedQuery = LRechargeDataMgr:isNeedQueryData()
    if not self._inited then
        -- LuaNetSendMsg:QuerySevenChargeInfo(35, 1)
        self._curType = 1
        self._awardDay = 1
        local list = JsonConfig.m_lianChong.getList()
        self.m_datas = {}
        for i=1, #list do
            if list[i].type == self._curType then
                table.insert(self.m_datas, list[i])
            end
        end

        -- dump(self.m_datas, "SevenDaysChargeNew:initData =======================>")

    else
        self.m_pUILayer:setVisible(true)
    end
end

function SevenDaysChargeNew:updateData( ... )
    -- body

    self.m_pUILayer:setVisible(true)
    local sevenRechargeData = LRechargeDataMgr:GetSevenRechargeData()
    sevenRechargeData.m_ChargeType = self._curType --  --从服务器获取
    sevenRechargeData.m_curDay = 1        --从服务器获取
    sevenRechargeData.m_leftTime = 20000  -- 从服务器获取
    sevenRechargeData.m_curValue = 20    --从服务器获取
    sevenRechargeData.m_curLimit = self.m_datas[sevenRechargeData.m_curDay].count

    for k = 1, 7 do
        local dayInfo = {}
        dayInfo.dayIdx = k
        dayInfo.dayLimit = self.m_datas[k].count
        dayInfo.state = 1
--        print("每日奖励, day: ", dayInfo.dayIdx, "; limit: ", dayInfo.dayLimit, "; state: ", dayInfo.state)
        dayInfo.itemArr = self.m_datas[k].reward
        -- dump(dayInfo, "updateSevenChargeData ++++++++++++++++++++")
        table.insert(sevenRechargeData.m_dayItemDataArr, dayInfo)
    end

    local dataInfo = sevenRechargeData.m_dayItemDataArr
    self._time:setString(sevenRechargeData.m_leftTime)
    local str = string.format("%d/%d", sevenRechargeData.m_curValue, sevenRechargeData.m_curLimit)
    self._curChargeStr:setString(str)
    self._curChargeStr2:setString(tostring(sevenRechargeData.m_curLimit))
    local function getAwardEvent(sender )
        -- body
        local day = sender.userObject
        self._awardDay = day
--        print("day ----", day, self._awardDay)
        LuaNetSendMsg:QuerySevenChargeAward(35, 2, 1, day)
    end

    local function showAwardInfo( sender )
        -- body
        local idx = sender:getTag()
--        print("idx showAwardInfo ========================", idx)
        local data = LRechargeDataMgr:getItemDayData(idx)
        -- LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUIInBattle, "Welfare.GainRewardUI", AppDef.UIType.PopWindow, data.itemArr)
        -- self:SendMsg(LGameMsg.m_initUIMsg)

        LGameMsg.m_baseMsgWithOne:Change(LUIResRecoveryEvent.changeTitleTxt, GUITips.RSI_GS_TIP_RECOVERY_GAIN_PRE)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end
    local lightStarNum = LRechargeDataMgr:getLightStarNum()
    --print("lightStarNum = ", lightStarNum)
    self._listView:removeAllItems()
    for i=1, #dataInfo do
        local data = dataInfo[i]
        local item = self._itemCell:clone()
        local title = item:getChildByName("Title")
        local titleStr = string.format(GUITips.UI_Text_Login_Day, data.dayIdx)
        title:setString(titleStr)
        local itemIconArr = {} 
        local itemIcon = item:getChildByName("Item")
        table.insert(itemIconArr, itemIcon)

        local choose = item:getChildByName("Choose")
        if choose ~= nil then
            choose:setVisible(false)
            if i == sevenRechargeData.m_curDay then
                choose:setVisible(true)
            end
        end

        local itemIcon2 = item:getChildByName("Item_0")
        local itemIcon3 = item:getChildByName("Item_1")
        table.insert(itemIconArr, itemIcon2)
        table.insert(itemIconArr, itemIcon3)
--        dump(data.itemArr, "showAwardInfo")
        for i=1, #data.itemArr do
            local awardData = data.itemArr[i]
            -- dump(awardData, "======================== 2222222222222 >")
            local awardIcon = self._awardCell:clone()
            Utils:ShowItemByConfigData(awardData, awardIcon, nil, true, true)
            itemIconArr[i]:addChild(awardIcon)
            awardIcon:setPosition(cc.p(self._awardCellSize.width / 2, self._awardCellSize.height / 2))

    --         if awardData.awardType == AppDef.AwrdItem.AWRD_ITEM_PET  then
    --             -- dump(awardData.petData, "itemData petData ===>")
    --             if awardData.petData ~= nil then
    --                 local awardIcon = self._petAwardCell:clone()
    --                 Utils:ShowPetByData(awardData.petData, itemIconArr[i], awardIcon, false)
    --                 itemIconArr[i]:addChild(awardIcon)
    --             end
    --         else
    --             local awardIcon = self._awardCell:clone()
    --             Utils:GetItemCellValue(awardIcon, 0, awardData.awardType, true, true, awardData.awardValue, nil, true)
    -- --        awardIcon:loadTexture("item/equip3518.png", ccui.TextureResType.localType)
    --             itemIconArr[i]:addChild(awardIcon)
    --             awardIcon:setPosition(cc.p(self._awardCellSize.width / 2, self._awardCellSize.height / 2))
    --         end
        end
        
        -- itemIcon:addClickEventListener(showAwardInfo)
        -- itemIcon:setTag(i)

        self._listView:pushBackCustomItem(item)

        local btn = item:getChildByName("btn")
        btn:addClickEventListener(getAwardEvent)
		self:MarkIntaractCObj(btn)
        btn.userObject = i

        local imageReceive = item:getChildByName("ImageReceive")
        imageReceive:setVisible(false)
        if data.state == 1 then
            btn:setTouchEnabled(false)
            btn:setBright(false)
        elseif data.state == 3 then
            -- btn:setTouchEnabled(false)
            -- btn:setBright(false)
            -- local text =  btn:getChildByName("Text")
            -- text:setString(GUITips.RSI_RECHARGE_TIP2)
            imageReceive:setVisible(true)
            btn:setVisible(false)
        end

--        print("updateData time ---------------", i)
        
        if i <= lightStarNum then
            self._starArr[i]:setVisible(true)
        else
            self._starArr[i]:setVisible(false)
        end

    end

--    local index = LRechargeDataMgr:getFirstAwardIndex()
    if sevenRechargeData.m_curDay >= 5 then
        self._listView:jumpToItem(4, cc.p(0, 0), cc.p(0.5, 0.5))
    end
    
    self.m_LoadingBar:setPercent((lightStarNum - 1) * 100 / 6)
    self:updateOtherAwardUI()
    self:setTimer(sevenRechargeData.m_leftTime)
    if showStarNum == 3 and awardInfo.state == 3 then
        self._Receive:setVisible(true)
        self._getAwardBtn:setVisible(false)
    end

    self._inited = true
end

function SevenDaysChargeNew:updateOtherAwardUI( ... )
    -- body
    local showStarNum = LRechargeDataMgr:getAwardStarNum()

    self._AtlasLabel:setString(showStarNum)
    self._awardList:removeAllItems()
    
    local sevenRechargeData = LRechargeDataMgr:GetSevenRechargeData()
    -- print("RewardCount ==", RewardCount)
    local offsetPage = 0
    for i=1, 3 do
        local dayExtraInfo = {}
        dayExtraInfo.dayIdx = 3
        if sevenRechargeData.m_curValue < sevenRechargeData.m_curLimit then
            dayExtraInfo.dayOffset = dayExtraInfo.dayIdx - sevenRechargeData.m_curDay + 1  --今天还没有达到要求
        else
            dayExtraInfo.dayOffset = dayExtraInfo.dayIdx - sevenRechargeData.m_curDay  --距离领取还剩多少天,负值表示已经达到天数
        end
        dayExtraInfo.state = 1
        if dayExtraInfo.state == 3 then
            offsetPage = offsetPage + 1
        end
--        print("额外奖励, day: ", dayExtraInfo.dayIdx,  " offset: ", dayExtraInfo.dayOffset, "; state: ", dayExtraInfo.state, sevenRechargeData.m_curDay, sevenRechargeData.m_curValue)
        
        dayExtraInfo.itemArr = self.m_datas[3].reward_add

        -- dump(dayExtraInfo, "updateSevenChargeData ++++++++++++++++++++")
        table.insert(sevenRechargeData.m_rewardDataArr, dayExtraInfo) 
    end

    local awardInfo = sevenRechargeData.m_rewardDataArr[1]

--    dump(awardInfo.itemArr, "itemInfo")
    for i=1, #awardInfo.itemArr do
        local data = awardInfo.itemArr[i]
        local pCell = self._awardCell:clone()
        Utils:ShowItemByConfigData(data, pCell, nil, true, true)
--         if data.awardType == AppDef.AwrdItem.AWRD_ITEM_PET then
-- --            dump(data.petData, "petdata Info")
--             pCell = self._petAwardCell:clone()
--             if data.petData then
-- --                Utils:ShowPetHeadImg(pCell, data.petData.pic, nil, data.petData.quality, data.petData:IsShiny())
--                 Utils:ShowPet(data.petData.id, self._awardList, pCell, false)
--             end
--         else
--             pCell = self._awardCell:clone()
--             Utils:GetItemCellValue(pCell, 0, data.awardType, true, true, data.awardValue, nil, true)
--         end
        
        self._awardList:pushBackCustomItem(pCell)
    end

    --不可领取则按钮置灰
    if awardInfo.state == 1 then
        self._getAwardBtn:setTouchEnabled(false)
        self._getAwardBtn:setBright(false)
    elseif awardInfo.state == 2 then
        self._getAwardBtn:setTouchEnabled(true)
        self._getAwardBtn:setBright(true)
    else
        self._getAwardBtn:setTouchEnabled(false)
        self._getAwardBtn:setBright(false)
        local text = self._getAwardBtn:getChildByName("Text")
        text:setString(GUITips.RSI_RECHARGE_TIP2)
    end

end

function SevenDaysChargeNew:setLabel(label)
    if label ~= nil then
        self.m_timerLabel = TimerLabelUI:New(label, nil, nil, handler(self, self.TimeReduce))
    end
end

function SevenDaysChargeNew:TimeReduce(pText, h, m, s, left)
    if pText == nil then
        return
    end

    local str = ""
    local day = 0
    if h > 24 then
        day = math.floor(h / 24)
        h = math.fmod(h, 24)
    end
    if day > 0 then
        str = str..tostring(day)..GUITips.Item_Info_Day
    end
    str = str..string.format("%02d:%02d:%02d", h, m, s)
    pText:setString(str)
end

function SevenDaysChargeNew:setTimer(leftTime)
    --dump({leftTime, self.m_timerLabel})
    if self.m_timerLabel ~= nil then
        self.m_timerLabel:set(leftTime)
        self.m_timerLabel:start()
    end
end

function SevenDaysChargeNew:updateDayAwardBtn( ... )
    -- body
    if self._awardDay <= 0 then
        return
    end
    local item = self._listView:getItem(self._awardDay - 1)
    if item == nil then
        return
    end

    LRechargeDataMgr:updateDayChargeData(self._awardDay)

    local btn = item:getChildByName("btn")
    local imageReceive = item:getChildByName("ImageReceive")
    btn:setVisible(false)
    imageReceive:setVisible(true)

    LGameMsg.m_baseMsg:ChangeEventId(LUIWelfareActivityEvent.UpdateRedDot)
    self:SendMsg(LGameMsg.m_baseMsg)
    
end

function SevenDaysChargeNew:refrashOtherAwardUI( ... )
    -- body
    local index = LRechargeDataMgr:getCurShowIndex()
    LRechargeDataMgr:updateRewardDataByIndex(index, 3)

    self:updateOtherAwardUI()
    LGameMsg.m_baseMsg:ChangeEventId(LUIWelfareActivityEvent.UpdateRedDot)
    self:SendMsg(LGameMsg.m_baseMsg)
end

function SevenDaysChargeNew:HideDetail()

end

function SevenDaysChargeNew:setVisible(visible)
    self.m_pUILayer:setVisible(visible)
    self:HideDetail()
end

return SevenDaysChargeNew