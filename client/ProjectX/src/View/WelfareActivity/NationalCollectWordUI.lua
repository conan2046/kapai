
local NationalCollectWordUI = LUIBase:New()
NationalCollectWordUI.__index = NationalCollectWordUI
--local this = LTcpSocket
function NationalCollectWordUI:New(parent)
	local o = LUIBase:New()
	setmetatable(o,NationalCollectWordUI)	
    o:Init(parent)
	return o
end

--注册事件
-- -----------------------------------
function NationalCollectWordUI:RegistMsgs()
    self.msgIds = 
    {
        LUIWelfareActivityEvent.updateExchangeWordUI,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function NationalCollectWordUI:ProcessEvent(msg)
    if msg.msgId == LUIWelfareActivityEvent.updateExchangeWordUI then
        self:refrashUI(msg.value)
    end
end

function NationalCollectWordUI:Init(parent)
    self.m_pUILayer = cc.CSLoader:createNode("csd/ActivityRankingLayer.csb")
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
    self:initConstData()
    self:InitUIControl()

end

function NationalCollectWordUI:initConstData()
    -- body
    self._inited = false
    self.selWordIdx = 1
end

function NationalCollectWordUI:InitUIControl( ... )
    -- body
    local panel = self.m_pUILayer:getChildByName("Panel")
    local BtnList = panel:getChildByName("BtnList")
    BtnList:removeFromParent()

    self._rankingBg = panel:getChildByName("RankingBg")

    local function showSelItemlayer(pTouch, pEvent)
        if pEvent == ccui.TouchEventType.began then
        end

        if pEvent == ccui.TouchEventType.moved then
        end
        if pEvent == ccui.TouchEventType.ended then
            if self._isShowSelList then
                self:showSelectItemUI()
            end
        end
    end

    self._rankingBg:addTouchEventListener(showSelItemlayer)

    local powerBg = self._rankingBg:getChildByName("PowerBg")
    powerBg:setVisible(false)
    local rechargeBg = self._rankingBg:getChildByName("RechargeBg")
    rechargeBg:setVisible(false)
    self._JiziBg = self._rankingBg:getChildByName("JiziBg")
    self._JiziBg:setVisible(true)
    self._JiziBg:setSwallowTouches(false)

    self._ExchangeList = self._rankingBg:getChildByName("ExchangeList")
    self._ExchangeList:setVisible(true)
    self._ExchangeList:setSwallowTouches(false)

    local tips = self._rankingBg:getChildByName("Tips")
    tips:setVisible(false)

    self._btnList = {}
    for i=1, 5 do
        local exchange 
        local btn = self._ExchangeList:getChildByName("Exchange_" ..i):getChildByName("Button")
        table.insert(self._btnList, btn)
        btn:setTag(i)
        btn:addClickEventListener(handler(self, NationalCollectWordUI.exchangeEvent))
    end

    local firstItem = self._ExchangeList:getChildByName("Exchange_1")
    self._listBtn = firstItem:getChildByName("ListBtn")
    self._listBtn:addClickEventListener(handler(self, NationalCollectWordUI.showSelectItemUI))
    self._isShowSelList = false

    self._iconList = firstItem:getChildByName("Iconlist")
    self._iconCell = self._iconList:getChildByName("IconBg_1")
    self._iconCell:removeFromParent()
    self._iconCell:retain()
    self._selList = self._iconList:getChildByName("List")

    local list = self._rankingBg:getChildByName("List")
    list:setVisible(false)

    self._timeText1 = self._JiziBg:getChildByName("Time"):getChildByName("Text_1")
    self._desText = self._JiziBg:getChildByName("Desc"):getChildByName("Text")

    local haveItem = self._JiziBg:getChildByName("HaveItem")
    self._iconBgList = {}

    for i=1, 5 do
        local item = haveItem:getChildByName("IconBg_"..i)
        table.insert(self._iconBgList, item)
    end

end

function NationalCollectWordUI:exchangeEvent( sender )
    -- body
    local tag = sender:getTag()
    local theSelWordIdx = 0
    if tag == 1 then
        theSelWordIdx = self.selWordIdx
    end
    -- print("exchangeEvent  ====>", tag, theSelWordIdx, self.selWordIdx)
    LuaNetSendMsg:exchangeNationalDayCoWord(50, 2, tag, theSelWordIdx)
end

function NationalCollectWordUI:showSelectItemUI( sender )
    -- body
    local LDir = self._listBtn:getChildByName("L")
    local RDir = self._listBtn:getChildByName("R")
    self._isShowSelList = not self._isShowSelList
    LDir:setVisible(not self._isShowSelList)
    RDir:setVisible(self._isShowSelList)
    self._iconList:setVisible(self._isShowSelList)
end

function NationalCollectWordUI:SelectItem( sender )
    -- body
    if self._firstIcon == nil then
        return
    end

    local info = sender.userObject
    -- dump(info, "SelectItem ==>")
    local idx = sender:getTag()
    self.selWordIdx = idx
    -- print("selWordIdx ---->", idx)
    self._firstIcon:removeAllChildren()
    Utils:GetItemCellValue(self._firstIcon, 0, info.id, true, true, info.num, nil, true, true)

end

function NationalCollectWordUI:initData()
    LuaNetSendMsg:QueryNationalDayCoWord(50, 1)
end

function NationalCollectWordUI:updateData( data )
    -- body
    self._collectData = data
    --dump data
    -- for i=1, #self._collectData.allExchangeItems do
    --     dump(self._collectData.allExchangeItems[i], "NationalCollectWordUI")
    -- end
    -- dump(self._collectData.exchageMaterial, "NationalCollectWordUI own")
    ------------------------------------------------------------------------------------
    self:updateUI()
    local _ = self.m_pUILayer and self.m_pUILayer:setVisible(true)
end

function NationalCollectWordUI:updateUI()
    -- body
    --自己拥有的物品资料
    for i=1, #self._collectData.exchageMaterial do
        local item = self._iconBgList[i]
        local info = self._collectData.exchageMaterial[i]
        Utils:GetItemCellValue(item, 0, info.id, true, true, info.num, nil, true, true)
    end

    --刷新数据
    for i=1, #self._collectData.allExchangeItems do
        local item = self._ExchangeList:getItem(i - 1)
        local exchangeData = self._collectData.allExchangeItems[i]
        local timesLabel = item:getChildByName("Times")
        local exChangeTimes = timesLabel:getChildByName("Num")
        if exchangeData.totalExchangeTimes > 0 then
            timesLabel:setVisible(true)
            exChangeTimes:setString(string.format("%d/%d", exchangeData.exchangeTimes, exchangeData.totalExchangeTimes))
        else
            timesLabel:setVisible(false)
        end
    end

    --兑换资料
    if self._inited then
        return
    end

    for i=1, 5 do
        local selCell = self._iconCell:clone()
        local data = self:getIdByIndex(i)
        -- dump(data, "updateUI =================>")
        if data ~= nil then
            selCell.userObject = data
            selCell:setTag(i)
            Utils:GetItemCellValue(selCell, 0, data.id, true, false, data.num, nil, false, true)
            selCell:addClickEventListener(handler(self, NationalCollectWordUI.SelectItem))
            self._selList:pushBackCustomItem(selCell)
        end 
    end

    --活动时间
    self._timeText1:setString(self._collectData.timeMsg)
    for i=1, #self._collectData.allExchangeItems do
        local item = self._ExchangeList:getItem(i - 1)
        local exchangeData = self._collectData.allExchangeItems[i]
        -- dump(exchangeData, "NationalCollectWordUI -----------------")
        for j = 1, #exchangeData.exchangeItems do
            local icon = item:getChildByName("IconBg_".. j)
            if i == 1 then
                if j == 1 then
                    self._firstIcon = icon
                    local info = exchangeData.exchangeItems[j]
                    -- print("updateUI ====", info.id, info.num)
                    Utils:GetItemCellValue(icon, 0, info.id, true, true, info.num, nil, true, true)
                end
            else
                local info = exchangeData.exchangeItems[j]
                -- print("updateUI ====", info.id, info.num)
                Utils:GetItemCellValue(icon, 0, info.id, true, true, info.num, nil, true, true)
            end
        end

        if #exchangeData.gainItems > 0 then
            local icon = item:getChildByName("IconBg_6")
            local gainData = exchangeData.gainItems[1]
            Utils:GetItemCellValue(icon, 0, gainData.id, true, true, gainData.num, nil, true, true)
        end
        
    end
    self._inited = true
end

function NationalCollectWordUI:getIdByIndex( index )
    -- body
    if self._collectData == nil or self._collectData.allExchangeItems == nil or #self._collectData.allExchangeItems < 1 then
        return nil
    end

    local exchangeData = self._collectData.allExchangeItems[1]
    if exchangeData.exchangeItems == nil or index > #exchangeData.exchangeItems then
        return nil
    end
    local info = exchangeData.exchangeItems[index]
    return info
end

function NationalCollectWordUI:Reset()
    local _ = self.m_pUILayer and self.m_pUILayer:setVisible(false)
end

function NationalCollectWordUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
    self._inited = nil
    self.selWordIdx = nil
    self._collectData = nil
end

return NationalCollectWordUI