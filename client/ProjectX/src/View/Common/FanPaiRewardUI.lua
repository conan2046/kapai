
local FanPaiRewardUI = LUIBase:New()
FanPaiRewardUI.__index = FanPaiRewardUI
--local this = LTcpSocket
function FanPaiRewardUI:New(data)
	local o = LUIBase:New()
	setmetatable(o,FanPaiRewardUI)	
    o:Init(data)
	return o
end

local state_fanpai = 1
local state_end = 2

--注册事件
-- -----------------------------------
function FanPaiRewardUI:RegistMsgs()
    self.msgIds = 
    {
        LUIActivityEvent.FanPaiShiLian,
        LUILogicEvent.ExitBattle,
        LUIActivityEvent.closeFanPai,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function FanPaiRewardUI:ProcessEvent(msg)
    if msg.msgId == LUIActivityEvent.FanPaiShiLian then
        local idx = msg.value
--        print("FanPaiShiLian idx", idx)
        local sender = self:getCardByIndex(idx)
        if sender ~= nil then
            self:execFanPai(sender)
        end
    elseif msg.msgId == LUILogicEvent.ExitBattle then
        self.m_pUILayer:setVisible(true)
        self:selectCountDown()
    elseif msg.msgId == LUIActivityEvent.closeFanPai then
        self:closeDialog()
    end
end

function FanPaiRewardUI:Init(data)

    self.m_pUILayer = cc.CSLoader:createNode("csd/fanpai.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:initData(data)
    self:initUI()
    self:refrashUI()
end

function FanPaiRewardUI:initUI( ... )
    -- body
    local panel = self.m_pUILayer:getChildByName("fanpaiUI")
    local exitBtn = panel:getChildByName("Button")
    local function exitEvent( sender )
        -- body
        if self._isFixing then
            Utils:ShowScrollTips(GUITips.RSI_FANPAI_TIPS)
            return
        end

        if self._curState == state_fanpai then
            if self._fanPaiNum < 1 then
    --            self:execFanPai(self._cardArr[1])
                LuaNetSendMsg:QueryShiLianLottery(4, 1)
                self._isAutoSelect = true
            else
                self:EndFanPai()
            end
        else
            Utils:unschedule(nil, self.m_showFrontScheduler)
            LuaNetSendMsg:QueryShiLianInfo(5)
            --self:closeDialog()
        end
    end
    exitBtn:addClickEventListener(exitEvent)
--卡牌翻牌事件
    for i=1, 5 do
        local str = "Card_" .. i
        local card = panel:getChildByName(str)
        card:setTouchEnabled(true)
        table.insert(self._cardArr, card)
        card.userObject = false
        card:setTag(i)
        card:addClickEventListener(handler(self, FanPaiRewardUI.fanpaiEvent))
    end

    self._leftTimes = panel:getChildByName("Text_1"):getChildByName("Value")
    self._curCost = panel:getChildByName("Text_2"):getChildByName("Value")

    self._flipLeftTimeOld = panel:getChildByName("Time")
    self._flipLeftTime = Utils:CreateColorText3(self._flipLeftTimeOld, true)

    local strTemp = string.format(GUITips.RSI_YINGYONGSHILIAN_TIPS_1, self._awardData.countTime)
    self._flipLeftTime:setString(strTemp)
--    print("LRoleDataMgr.m_bIsInBattle ----------------------------", LRoleDataMgr.m_bIsInBattle)
    if LRoleDataMgr.m_bIsInBattle then
        self.m_pUILayer:setVisible(false)
    else
        --开始倒计时
        self:selectCountDown()
    end
    
end

function FanPaiRewardUI:initData( data )
    -- body
    --记录已经翻牌了几次
    self._fanPaiNum = 0
    self._awardData = data
    self._awardData.maxNum = 3
    -- self._awardData.itemInfo = {}
    -- for i=1,5 do
    --     local item = {}
    --     item.id = 834
    --     item.num = 2
    --     table.insert(self._awardData.itemInfo, item)
    -- end
    self._awardData.countTime = 15
    self._awardData.showTime = 5
--    dump(self._awardData, "initData---------------------------->")
    self._isAutoSelect = false

    self._cardArr = {}
    self._curState = state_fanpai  -- 1、选牌阶段 2、展示阶段
    self._isFixing = false
end

function FanPaiRewardUI:fanpaiEvent(sender)
    -- body

    if self._awardData.countTime < 0 then
        Utils:ShowScrollTips(GUITips.RSI_FANPAI_TIPS)
        return
    end

    if self:isAlreadyFanPai(sender) then
        Utils:ShowScrollTips(GUITips.RSI_YINGYONGSHILIAN_TIPS_4)
        return
    end

    local _curCost = self:getCurCost()
    local myTongo = LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao()
--    print("fanpaiEvent", _curCost, myTongo)
    if myTongo < _curCost then
        -- Utils:ShowScrollTips(GUITips.RSI_LD_TIP11)
        Utils:OpenNotEnoughGold()
        return
    end

--    self:execFanPai(sender)
    local tag = sender:getTag()
    LuaNetSendMsg:QueryShiLianLottery(4, tag)
end

function FanPaiRewardUI:execFanPai(sender)
    -- body
    local tag = sender:getTag()
    local function RotateCallBack()
        local image = sender:getChildByName("Image")
        if image:isVisible() then
            image:setVisible(false)
        else
            image:setVisible(true)
        end
        sender:setScaleX(-1)
        local item = sender:getChildByName("Item")
        local data = self:getAwardIdByIndex(tag)
        if data then
            item:setVisible(true)
            Utils:GetItemCellValue(item, 0, data.id, true, true, data.num, nil, false, true)
        end

        local FX = sender:getChildByName("FX")
        if self._curState == state_end then
            FX:setVisible(false)
        else
            FX:setVisible(true)
            local particle = FX:getChildByName("Particle")
            particle:setVisible(true)
        end
        
    end

    local flipBack = cc.OrbitCamera:create(0.25, 1, 0, 0, 90, 0, 0)
    local showFront = cc.CallFunc:create(RotateCallBack)
    local flipFront = cc.OrbitCamera:create(0.25, 1, 0, -90, -90, 0, 0)
    local function RotateOverCallBack( )
        -- body
        sender.userObject = true
        self._fanPaiNum = self._fanPaiNum + 1
        self:refrashUI()

        if self._isAutoSelect then
            self:EndFanPai()
            self._isAutoSelect = false
        else
            if self._curState == state_fanpai then
                if self._fanPaiNum > self._awardData.maxNum - 1 then
                    self:EndFanPai()
                end
            end
        end
        self._isFixing = false
    end
    local showFrontOver = cc.CallFunc:create(RotateOverCallBack)
    local flipSeq = cc.Sequence:create(flipBack, showFront, flipFront, showFrontOver)
    sender:runAction(flipSeq)
    self._isFixing = true
end

function FanPaiRewardUI:getAwardIdByIndex(idx)
    -- body
    if idx > #self._awardData.itemInfo or idx < 0 then
        return nil
    end

    return self._awardData.itemInfo[idx]
end

function FanPaiRewardUI:isAlreadyFanPai( sender )
    -- body
    return self._fanPaiNum > self._awardData.maxNum - 1 or sender.userObject
end

function FanPaiRewardUI:EndFanPai( ... )
    -- body
    Utils:unschedule(nil, self.m_fanPaiScheduler)
    self._curState = state_end
    for i = 1, #self._cardArr do
        local sender = self._cardArr[i]
        if not sender.userObject then
            self:execFanPai(sender)
        end
    end
    self:showFrontCountDown()
end

function FanPaiRewardUI:refrashUI( ... )
    -- body
    if self._fanPaiNum > self._awardData.maxNum then
        return
    end
    local _leftTimes = self._awardData.maxNum - self._fanPaiNum
    self._leftTimes:setString(_leftTimes)
    if _leftTimes < 1 then
        self._leftTimes:setTextColor(UICOLOR_RED)
    end

--    print("self._fanPaiNum refrashUI", self._fanPaiNum)
    local _curCost = self:getCurCost()
    self._curCost:setString(_curCost)
end

function FanPaiRewardUI:closeDialog( ... )
    -- body
    LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Common.FanPaiRewardUI")
    self:SendMsg(LGameMsg.m_deleteUIMsg)
end

function FanPaiRewardUI:selectCountDown()
    self.m_fanPaiScheduler = Utils:schedule(nil, handler(self, FanPaiRewardUI.scheduler), 1, false)
end

function FanPaiRewardUI:scheduler( ... )
    -- body
    if self._isFixing then
        return
    end

    if self._awardData.countTime < 1 then
        Utils:unschedule(nil, self.m_fanPaiScheduler)

        if self._fanPaiNum < 1 then
--            self:execFanPai(self._cardArr[1])
            LuaNetSendMsg:QueryShiLianLottery(4, 1)
            self._isAutoSelect = true
        else
            self:EndFanPai()
        end
        return
    end
    
    self._awardData.countTime = self._awardData.countTime - 1

    local strTemp = string.format(GUITips.RSI_YINGYONGSHILIAN_TIPS_1, self._awardData.countTime)
    self._flipLeftTime:setString(strTemp)

    
end


function FanPaiRewardUI:showFrontCountDown( ... )
    -- body
    self.m_showFrontScheduler = Utils:schedule(nil, handler(self, FanPaiRewardUI.showFrontScheduler), 1, false)
    local strTemp = string.format(GUITips.RSI_YINGYONGSHILIAN_TIPS_3, self._awardData.showTime)
    self._flipLeftTime:setString(strTemp)
end

function FanPaiRewardUI:showFrontScheduler( ... )
    -- body
    if self._awardData.showTime < 1 then
        LuaNetSendMsg:QueryShiLianInfo(5)
        --self:closeDialog()
        return
    end
    
    self._awardData.showTime = self._awardData.showTime - 1

    local strTemp = string.format(GUITips.RSI_YINGYONGSHILIAN_TIPS_3, self._awardData.showTime)
    self._flipLeftTime:setString(strTemp)
end

function FanPaiRewardUI:getCardByIndex(idx)
    -- body
    if idx > #self._cardArr or idx < 1 then
        return nil
    end

    return self._cardArr[idx]
end

function FanPaiRewardUI:getCurCost( ... )
    -- body
    if self._fanPaiNum == 0 then
        return 0
    elseif self._fanPaiNum == 1 then
        return self._awardData.costYB1
    elseif self._fanPaiNum == 2 then
        return self._awardData.costYB2
    end
    return 0
end

function FanPaiRewardUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
    Utils:unschedule(nil, self.m_fanPaiScheduler)
    Utils:unschedule(nil, self.m_showFrontScheduler)
end

return FanPaiRewardUI