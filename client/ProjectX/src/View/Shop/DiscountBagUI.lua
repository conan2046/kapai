local TimerLabelUI = require("View.Common.TimerLabelUI")

local DiscountBagUI = LUIBase:New()
DiscountBagUI.__index = DiscountBagUI
DiscountBagUI.IsHideInBattle = true
--------------------------------------------
function DiscountBagUI:New(t)
	local o = {}
	setmetatable(o,DiscountBagUI)	
    o:Init(t)
	return o
end
--------------------------------------------
function DiscountBagUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_pBgLayer = nil
    self.m_pGiftNode = nil
    self.m_pCountDown = nil 
    self.m_pOwnMoney = nil
    self.m_pBuyBtn = nil
    if self.m_pCountDownTimer then
        self.m_pCountDownTimer:Destory()
        self.m_pCountDownTimer = nil
    end
end
--------------------------------------------
function DiscountBagUI:RegistMsgs()
    self.msgIds = 
    {
        LUIRoleDataChangeEvent.TongBaoChanged,
        LUIDiscountBagEvent.UpdateDataEvent,
        LUIDiscountBagEvent.BuyResultEvent,
    }
    self:RegistSelf(self,self.msgIds)
end
--------------------------------------------
function DiscountBagUI:Init(t)
    self.Script = "Shop.DiscountBagUI"
    self.m_bagType = t - 85
    --------------------------------------------
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    --------------------------------------------
    LuaNetSendMsg:QueryDiscountBag(self.m_bagType + 85, 1)
end
--------------------------------------------
function DiscountBagUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/DiscountShopLayer2.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    self.m_pBgLayer = cc.CSLoader:createNode("csd/ActivityLevelLayer.csb")
    self.m_pBgLayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pBgLayer)
    self.m_pBgLayer:setPosition(cc.p(0, 0))
    self.m_pUILayer:addChild(self.m_pBgLayer)
end
--------------------------------------------
function DiscountBagUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
--------------------------------------------
function DiscountBagUI:InitUIControl()
    --------------------------------------------
    local pBackBtn = Utils:FindNodeByName(self.m_pBgLayer, "Panel/Bg/CloseBtn")
    if pBackBtn ~= nil then
        pBackBtn:addClickEventListener(handler(self, LUIBase.RemoveUI))
    end
    --------------------------------------------
    local panel = self.m_pUILayer:getChildByName("Shop")
    panel:setLocalZOrder(1)
    --------------------------------------------
    for i=1,3 do
        local isShow = (i == self.m_bagType)
        local pNode = panel:getChildByName("Gift_"..i)
        if pNode then
            pNode:setVisible(isShow)
            if isShow then
                self.m_pGiftNode = pNode
            end
        end
    end
    --------------------------------------------
    local pMysticalShop = panel:getChildByName("MysticalShop")
    self.m_pCountDown = pMysticalShop:getChildByName("CountDown")
    self.m_pCountDownTimer = TimerLabelUI:New(self.m_pCountDown:getChildByName("Value"), nil, nil, handler(self, DiscountBagUI.TimeReduce))
    --------------------------------------------
    local pOwnBg = pMysticalShop:getChildByName("bg_Own")
    self.m_pOwnMoney = pOwnBg:getChildByName("Value")
    self:updateMoney()
    --------------------------------------------
end
--------------------------------------------
function DiscountBagUI:ProcessEvent(msg)
    if msg.msgId == LUIRoleDataChangeEvent.TongBaoChanged then
        self:updateMoney()
    elseif msg.msgId == LUIDiscountBagEvent.UpdateDataEvent then
        self:DealUpdateData(msg.value)
    elseif msg.msgId == LUIDiscountBagEvent.BuyResultEvent then
        self:DealBuyResultEvent()
    end
end
--------------------------------------------
function DiscountBagUI:updateMoney()
    if self.m_pOwnMoney then
        self.m_pOwnMoney:setString(LRoleDataMgr.MyHeroInfo:GetDetailData().TongBao)
    end
end
--------------------------------------------
function DiscountBagUI:updatePrice()
    if self.m_pGiftNode == nil then
        return
    end
    local pPrice = self.m_pGiftNode:getChildByName("Price")
    local pGold = pPrice:getChildByName("Gold")
    local pPriceValue1 = pGold:getChildByName("Text_1")
    pPriceValue1:setString(self.m_data.price or 0)

    local pPriceValue2 = pGold:getChildByName("Text_2")
    pPriceValue2:setString(self.m_data.buyPrice or 0)

    self.m_pBuyBtn = self.m_pGiftNode:getChildByName("BuyBtn")
    self.m_pBuyBtn:addClickEventListener(handler(self, DiscountBagUI.BuyClick))
end
--------------------------------------------
function DiscountBagUI:BuyClick(sender)
    LuaNetSendMsg:QueryDiscountBag(self.m_bagType + 85, 2)
end
--------------------------------------------
function DiscountBagUI:DealUpdateData(data)
    Utils:FreeTable(self.m_data)
    self.m_data = nil
    self.m_data = data
    self:updateReward()
    self:updatePrice()
    if self.m_pCountDownTimer then
        self.m_pCountDownTimer:set(self.m_data.leftTime or 0)
        self.m_pCountDownTimer:start()
    end
end
--------------------------------------------
function DiscountBagUI:TimeReduce(pText, h, m, s, left)
    if pText == nil then
        return
    end
    local day = math.floor(h/24)
    if day > 0 then
        h = h - day * 24
        pText:setString(string.format("%d天%02d:%02d:%02d", day, h, m, s))
    else
        pText:setString(string.format("%02d:%02d:%02d", h, m, s))
    end
end
--------------------------------------------
function DiscountBagUI:updateReward()
    if self.m_pGiftNode == nil then
        return
    end
    local pPackage = self.m_pGiftNode:getChildByName("Package")
    local pItemModel = pPackage:getChildByName("Item")
    local pPetItemModel = pPackage:getChildByName("IconColor")

    local function setReward(pList, rewards)
        if pList == nil then
            return
        end
        if rewards == nil or #rewards == 0 then
            pList:setVisible(false)
            return
        end
        pList:setVisible(true)
        pList:removeAllItems()
        for i=1,#rewards do
            local id = rewards[i].id
            local num = rewards[i].num
            local pstar = rewards[i].pstar
            local level = rewards[i].level
            local pItem = nil
            if id == AppDef.AwrdItem.AWRD_ITEM_PET then
                pItem = self:createModel(pPetItemModel, pList, id, true)
            elseif id == AppDef.AwrdItem.AWRD_ITEM_PETEQUIP then
                pItem = self:createModel(pItemModel, pList, id, false, nil, nil, nil, nil, num, pstar)
            else
                pItem = self:createModel(pItemModel, pList, id, false, num)
            end
            if pItem then
                pList:pushBackCustomItem(pItem)
            end
        end
    end
    local buffer = {{},{}}
    for i=1,#self.m_data.rewards do
        if i <= 3 then
            table.insert(buffer[1], self.m_data.rewards[i])
        elseif i <= 5 then
            table.insert(buffer[2], self.m_data.rewards[i])
        end
    end
    setReward(pPackage:getChildByName("ListView_1"), buffer[1])
    setReward(pPackage:getChildByName("ListView_2"), buffer[2])
end
--------------------------------------------
function DiscountBagUI:createModel(pModel, parent, pData, isPet, num, item, noTouch, noEffect, pid, pstar)
    noTouch = Utils:ToBool(noTouch)
    local pItem = pModel:clone()
    if isPet then
        Utils:ShowPet(pData, parent, pItem, noTouch)
        if (noEffect == nil or noEffect == false) then
            local data = LPetDataMgr:FindPetDataById(pData)
            if data and data.quality >= 3 then
                local posX = pItem:getContentSize().width / 2
                local posY = pItem:getContentSize().height / 2
                Utils:createAnimEffect(pItem, cc.p(posX, posY), "res2/fx/gaojiwupin")
            end
        end
    else
        local item = Utils:GetItemCellValue(pItem, 0, pData, true, num ~= nil, num, nil, not noTouch, nil, pid, pstar)
        if (noEffect == nil or noEffect == false) then
            local quality = Utils:getQualityByItem(item)
            if quality >= 5 then
                local posX = pItem:getContentSize().width / 2
                local posY = pItem:getContentSize().height / 2
                Utils:createAnimEffect(pItem, cc.p(posX, posY), "res2/fx/gaojiwupin")
            end
        end
    end
    pItem:setVisible(true)
    return pItem
end
--------------------------------------------
function DiscountBagUI:DealBuyResultEvent()
    self.m_pBuyBtn:setBright(false)
    self.m_pBuyBtn:setTouchEnabled(false)
    self.m_pBuyBtn:getChildByName("Text"):setString(GUITips.RSI_PET_DIS_TIPS2)
end
--------------------------------------------
return DiscountBagUI