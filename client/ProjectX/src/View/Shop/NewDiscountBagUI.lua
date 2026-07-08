local TimerLabelUI = require("View.Common.TimerLabelUI")

local NewDiscountBagUI = LUIBase:New()
NewDiscountBagUI.__index = NewDiscountBagUI
NewDiscountBagUI.IsHideInBattle = true
--------------------------------------------
function NewDiscountBagUI:New(t)
	local o = {}
	setmetatable(o,NewDiscountBagUI)
    o:Init(t)
	return o
end
--------------------------------------------
function NewDiscountBagUI:onExit()
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
function NewDiscountBagUI:RegistMsgs()
    self.msgIds = 
    {
        LUIRoleDataChangeEvent.TongBaoChanged,
        LUIDiscountBagEvent.NewUpdateDataEvent,
        LUIDiscountBagEvent.NewBuyResultEvent,
    }
    self:RegistSelf(self,self.msgIds)
end
--------------------------------------------
function NewDiscountBagUI:Init(t)
    self.Script = "Shop.NewDiscountBagUI"
    self.m_bagType = t - 88
    --------------------------------------------
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    --------------------------------------------
    LuaNetSendMsg:QueryDiscountBag(self.m_bagType + 88, 1)
end
--------------------------------------------
function NewDiscountBagUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/huodong/DiscountShopLayer2.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    self.m_pBgLayer = cc.CSLoader:createNode("csd/huodong/ActivityLevelLayer.csb")
    self.m_pBgLayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pBgLayer)
    self.m_pBgLayer:setPosition(cc.p(0, 0))
    self.m_pUILayer:addChild(self.m_pBgLayer)
end
--------------------------------------------
function NewDiscountBagUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
--------------------------------------------
function NewDiscountBagUI:InitUIControl()
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
    self.m_pCountDownTimer = TimerLabelUI:New(self.m_pCountDown:getChildByName("Value"), nil, nil, handler(self, NewDiscountBagUI.TimeReduce))
    --------------------------------------------
    local pOwnBg = pMysticalShop:getChildByName("bg_Own")
    self.m_pOwnMoney = pOwnBg:getChildByName("Value")
    self:updateMoney()
    --------------------------------------------
    self.m_pTips = pMysticalShop:getChildByName("Tips")
    self.m_pTips:setVisible(false)
end
--------------------------------------------
function NewDiscountBagUI:ProcessEvent(msg)
    if msg.msgId == LUIRoleDataChangeEvent.TongBaoChanged then
        self:updateMoney()
    elseif msg.msgId == LUIDiscountBagEvent.NewUpdateDataEvent then
        self:DealUpdateData(msg.value)
    elseif msg.msgId == LUIDiscountBagEvent.NewBuyResultEvent then
        self:DealBuyResultEvent()
    end
end
--------------------------------------------
function NewDiscountBagUI:updateMoney()
    if self.m_pOwnMoney then
        self.m_pOwnMoney:setString(LRoleDataMgr.MyHeroInfo:GetDetailData().TongBao)
    end
end
--------------------------------------------
function NewDiscountBagUI:updatePrice()
    if self.m_pGiftNode == nil then
        return
    end
    local pPrice = self.m_pGiftNode:getChildByName("Price")
    local pGold = pPrice:getChildByName("Gold")

    if self.m_data and self.m_data.priceType then
        local str = nil
        if self.m_data.priceType == 1 then
            str = AppDef:GetMoneyIcon(AppDef.MoneyType.RENMINBI)
            self.m_pTips:setVisible(true)
        elseif self.m_data.priceType == 2 then
            str = AppDef:GetMoneyIcon(AppDef.MoneyType.YUANBAO)
        end
        if str then
            pGold:loadTexture(str, ccui.TextureResType.plistType)
        end
    end

    local pPriceValue1 = pGold:getChildByName("Text_1")
    pPriceValue1:setString(self.m_data.price or 0)

    local pPriceValue2 = pGold:getChildByName("Text_2")
    pPriceValue2:setString(self.m_data.buyPrice or 0)

    self.m_pBuyBtn = self.m_pGiftNode:getChildByName("BuyBtn")
    self.m_pBuyBtn:addClickEventListener(handler(self, NewDiscountBagUI.BuyClick))
end
--------------------------------------------
function NewDiscountBagUI:BuyClick(sender)
    if self.m_data and self.m_data.priceType then
        if self.m_data.priceType == 1 then
            if self.m_data.buyPrice and self.m_data.buyPrice > 0 then
                Utils:Payment(self.m_data.buyPrice)
            else
                print("ERROR!!!")
            end
        elseif self.m_data.priceType == 2 then
            LuaNetSendMsg:QueryDiscountBag(self.m_bagType + 88, 2)
        end
    end
end
--------------------------------------------
function NewDiscountBagUI:DealUpdateData(data)
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
function NewDiscountBagUI:TimeReduce(pText, h, m, s, left)
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
function NewDiscountBagUI:updateReward()
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
            local pItem = nil
            if id == AppDef.AwrdItem.AWRD_ITEM_PET then
                local data = rewards[i].petdata
                if data then
                    pItem = self:createModel(pPetItemModel, pList, data.id, true)
                end
            else
                local num = rewards[i].itemNum
                if num == nil then
                    num = rewards[i].num
                end
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
function NewDiscountBagUI:createModel(pModel, parent, pData, isPet, num, item, noTouch, noEffect, pid, pstar)
    noTouch = Utils:ToBool(noTouch)
    local pItem = pModel:clone()
    if noEffect == nil then
        noEffect = false
    end
    if isPet then
        Utils:ShowPet(pData, parent, pItem, noTouch)
        if not noEffect then
            local data = LPetDataMgr:FindPetDataById(pData)
            if data and data.quality >= 5 then
                local posX = pItem:getContentSize().width / 2
                local posY = pItem:getContentSize().height / 2
                Utils:createAnimEffect(pItem, cc.p(posX, posY), "res2/fx/gaojiwupin")
            end
        end
    else
        --local dataArr = {pData,0,num}
        --local item = Utils:ShowItemByConfigData(dataArr, pItem, pItem, true, true)
        print("22222222222222222222222222=>",pData,num)
        local item = Utils:GetItemCellValue(pItem, 0, pData, true, num ~= nil, num, nil, not noTouch, nil, pid, pstar)
        if not noEffect then
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
function NewDiscountBagUI:DealBuyResultEvent()
    self.m_pBuyBtn:setBright(false)
    self.m_pBuyBtn:setTouchEnabled(false)
    self.m_pBuyBtn:getChildByName("Text"):setString(GUITips.RSI_PET_DIS_TIPS2)
end
--------------------------------------------
return NewDiscountBagUI