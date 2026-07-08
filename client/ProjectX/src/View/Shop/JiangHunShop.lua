
local JiangHunShop = LUIBase:New()
JiangHunShop.__index = JiangHunShop
--local this = LTcpSocket

local TimerLabelUI = require("View.Common.TimerLabelUI")
local ShopDef = require("View.Shop.ShopDef")

local SHUAXINLING = 400

function JiangHunShop:New()
	local o = LUIBase:New()
	setmetatable(o,JiangHunShop)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function JiangHunShop:RegistMsgs()
    self.msgIds = 
    {
        LUIShopEvent.UpdateKaPaiShop,
        LUIShopEvent.UpdateShopUIAfterBuySuc,
        LUIRoleDataChangeEvent.TongBaoChanged,
        LUIRoleDataChangeEvent.ShenHunChanged,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function JiangHunShop:ProcessEvent(msg)
    if msg.msgId == LUIShopEvent.UpdateKaPaiShop then
        self:updateData(msg.value)
        self:updateShopUI()
    elseif msg.msgId == LUIShopEvent.UpdateShopUIAfterBuySuc then
        self:updateDataAfterBuySuc(msg.value)
    elseif msg.msgId == LUIRoleDataChangeEvent.TongBaoChanged then
        self:refrashMoney(1)
    elseif msg.msgId == LUIRoleDataChangeEvent.ShenHunChanged then
        self:refrashMoney(2)
    end
end

function JiangHunShop:Init()

    self.ScriptPath = "Shop.JiangHunShop"
    self:CreateUINode("csd/shop/jianghunshop.csb")

    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()

    local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, self.ScriptPath)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.SetTitle, GUITips.RSI_SHOP_WANFA_TAG5)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.HelpBtn, function ()

        Utils:ShowDialogOKCancel(GUITips.UI_JiangHunShop_help)
    end)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    self:initControlUI()

    LuaNetSendMsg:QueryKaPaiShopUI(1, ShopDef.KP_SP.JIANGHUN)
end

function JiangHunShop:initControlUI( ... )
    -- body
    local ShopUI = self.m_pUILayer:getChildByName("ShopUI")

    local mine = ShopUI:getChildByName("Mine")
    local yuanbaoAdd = mine:getChildByName("yuanbao"):getChildByName("add")
    yuanbaoAdd:addClickEventListener(function ( sender )
        -- body
        self:CloseUI()
        Utils:OpenRechargeMainUI()
    end)
    self._goldValue = mine:getChildByName("yuanbao"):getChildByName("Value")
    self:refrashMoney(1)

    local jianghunAdd = mine:getChildByName("jianghun"):getChildByName("add")
    jianghunAdd:addClickEventListener(function ( sender )
        -- body
        local item = 
        {
            itemType = "CItem",
            itemData ={m_item= LItemMgr:getItem(AppDef.SpecialItemId.Soul)}
        }
      
        LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowItemInfo, item)
        LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
    end)
    self._jiangHunValue = mine:getChildByName("jianghun"):getChildByName("Value")
    self:refrashMoney(2)

    ----------------------------------------------------------------------------
    local jianghunShop = ShopUI:getChildByName("jianghunShop")
    local list = jianghunShop:getChildByName("List")

    self._itemList = {}
    local Item = list:getChildByName("Item_1")
    for i=1, 6 do
        local item = Item:getChildByName("Item"..i)

        local buy = item:getChildByName("buy")
        buy:setTag(i)
        buy:addClickEventListener(handler(self, JiangHunShop.buyEvent))
        table.insert(self._itemList, item)
    end
    ---------------------------------------------------------------------------
    local Panel_1 = jianghunShop:getChildByName("Panel_1")
    local btn_Refresh = Panel_1:getChildByName("btn_Refresh")
    btn_Refresh:addClickEventListener(function ( sender )
        -- body
        LuaNetSendMsg:QueryKaPaiShopUI(3, ShopDef.KP_SP.JIANGHUN)
    end)

    local freetimes = Panel_1:getChildByName("freetimes")
    self._refrashNum = freetimes:getChildByName("num")
    self._cdPanel = freetimes:getChildByName("cd")
    self._cdTime = self._cdPanel:getChildByName("Value")

    if self._timerAddTimes == nil then
        self._timerAddTimes = TimerLabelUI:New(self._cdTime, nil, nil, handler(self, self.TimeReduce))
    end
    local Consumables = Panel_1:getChildByName("Consumables")
    self._ownToken = Consumables:getChildByName("Panel"):getChildByName("Value")


    local icon = Consumables:getChildByName("Panel"):getChildByName("Icon")
    local imagePath = AppDef:GetMoneyIconById(SHUAXINLING)
    icon:loadTexture(imagePath,UI_TEX_TYPE_PLIST)
    
    local Remaining = Panel_1:getChildByName("Remaining")
    self._todayLeftTimes = Remaining:getChildByName("num")

end

function JiangHunShop:TimeReduce(pText, h, m, s, left)
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
        str = str..string.format("%02d:%02d", h, m)
    else
        str = str..string.format("%02d:%02d:%02d", h, m, s)
    end
    
    pText:setString(str)
end

function JiangHunShop:updateData(data)
    -- body
    local itemList = {}
    for i=1, #data.itemList do
        local exitConfigData = JsonConfig.m_ShopInfo.getDefByID(data.itemList[i].id)
        if exitConfigData then
            local serverData = data.itemList[i]
            table.insert(itemList, serverData)
        end
    end

    if #itemList > 5 then
        data.itemList = itemList
        data.size = #data.itemList
        self._shopData = data
        return
    end

    --如果数据不够则补充数据
    local list = JsonConfig.m_ShopInfo.getList()
    local myLevel = LRoleDataMgr.MyHeroInfo.level
    for i=1, #list do
        local configData = list[i]
        if data.type == configData.type then
            local dataTemp = {}
            local conditionLv = 0
            if #configData.show > 0 then
                conditionLv = configData.show[1][2]
            end

            if myLevel >= conditionLv then
                dataTemp.id = configData.id
                dataTemp.buyTimes = 0
                dataTemp.index = configData.cell
                table.insert(itemList, dataTemp)
            end
        end
        --最多显示6个
        if #itemList > 5 then
            break
        end
    end
    data.itemList = itemList
    data.size = #data.itemList
    self._shopData = data
end

function JiangHunShop:getBuyTimes( id, itemlist )
    -- body
    for i=1, #itemlist do
        if itemlist[i].id == id then
            return itemlist[i]
        end
    end
    return nil
end

function JiangHunShop:updateDataAfterBuySuc( data )
    -- body
    for i=1, #self._shopData.itemList do
        local itemData = self._shopData.itemList[i]
        if data.index == itemData.id then
            local itemUI = self._itemList[i]
            itemData.buyTimes = data.buyTimes
            self:updateItem(itemUI, itemData)
            break
        end
    end

end

function JiangHunShop:updateShopUI()
    -- body
    if self._shopData.freeAddSec > 0 then
        self._timerAddTimes.m_label:setVisible(true)
        self._timerAddTimes:set(self._shopData.freeAddSec, handler(self, self.TimeCountDownEnd))
        self._timerAddTimes:start()
    else
        self._cdPanel:getChildByName("1"):setVisible(false)
        self._cdPanel:getChildByName("2"):setVisible(false)
        self._timerAddTimes.m_label:setVisible(false)
    end
    
    for i=1, #self._itemList do
        local itemData = self._shopData.itemList[i]
        local itemUI = self._itemList[i]
        if itemData then
            self:updateItem(itemUI, itemData)
        end
    end


    local jianghunShopConfig = JsonConfig.m_ShopConfig.getDefByID(ShopDef.KP_SP.JIANGHUN)
    -- local freeTimeLeft = jianghunShopConfig.free_time - self._shopData.freeTimes
    self._refrashNum:setString(string.format("%d/%d", self._shopData.freeTimes, jianghunShopConfig.free_time))

    -- local totayLeft = jianghunShopConfig.refresh_count - self._shopData.freeTimes
    self._todayLeftTimes:setString(string.format("%d/%d", jianghunShopConfig.refresh_count - self._shopData.rafreshTimes, jianghunShopConfig.refresh_count))

    -- local num = LRoleDataMgr.Equip:CountItemNumById(SHUAXINLING)
    local num = LRoleDataMgr.Equip:CountItemNumById(jianghunShopConfig.cost[1])
    -- print("updateShopUI num ===>", jianghunShopConfig.cost[1], num)
    self._ownToken:setString(num)
end

function JiangHunShop:TimeCountDownEnd( ... )
    -- body
    --刷新数据
    LuaNetSendMsg:QueryKaPaiShopUI(1, ShopDef.KP_SP.JIANGHUN)
end


function JiangHunShop:updateItem( itemUI, itemData )
    -- body
    local configData = JsonConfig.m_ShopInfo.getDefByID(itemData.id)
    if configData == nil then
        return
    end
    local bg_icon = itemUI:getChildByName("bg_icon")
    bg_icon:removeAllChildren()
    -- print("JiangHunShop:updateItem ==>", configData.itemid[1], configData.itemid[3])
    Utils:GetItemCellValue(bg_icon, 0, configData.itemid[1], true, true, configData.itemid[3], nil, true, true)

    local name = itemUI:getChildByName("Name")
    local nameStr = Utils:getItemNameByID(configData.itemid[1])
    -- print("updateItem === nameStr configData.itemid[1] >", nameStr, configData.itemid[1])
    name:setString(nameStr)

    local Discount = itemUI:getChildByName("Discount")
    local DiscountValue = Discount:getChildByName("Value")
    local discountIndex = itemData.buyTimes + 1
    if discountIndex > #configData.price_real then
        discountIndex = #configData.price_real
    end
    -- print("discountIndex === >", discountIndex)
    local value = configData.price_real[discountIndex]
    local rate = value / 100
    if value >= 100 then
        Discount:setVisible(false)
    else
        DiscountValue:setString(string.format(GUITips.RSI_DISCOUNTSHOP_DISCOUNT, value / 10))
    end
    
    local shangzhen = itemUI:getChildByName("shangzhen")
    local petID =  PetkaPaiManager:getPetIdByItemId(configData.itemid[1])
    if petID > 0 then
        local showPos = LRoleDataMgr.Pet:GetPetPos(petID)
        shangzhen:setVisible(showPos > 0)
    end

    local buy = itemUI:getChildByName("buy")
    local bg_yigoumai = itemUI:getChildByName("bg_yigoumai")
    if itemData.buyTimes > 0 then
        buy:setVisible(false)
        bg_yigoumai:setVisible(true)
    else
        buy:setVisible(true)
        bg_yigoumai:setVisible(false)

        local moneyValue = buy:getChildByName("Value")
        dump(configData.price, "the price_real is ===>")
        moneyValue:setString(configData.price[1][3] * rate)

        local icon = buy:getChildByName("Icon")
        local imagePath = AppDef:GetMoneyIconById(configData.price[1][1])
        icon:loadTexture(imagePath, UI_TEX_TYPE_PLIST)

    end
    

end

function JiangHunShop:refrashMoney( type )
    -- body
    if type == 1 then
        local myGold = LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao()
        self._goldValue:setString(myGold)
    else
        local myshenHun = LRoleDataMgr.MyHeroInfo:GetDetailData().shenHun
        print("refrashMoney ===> myshenHun", myshenHun)
        self._jiangHunValue:setString(myshenHun)
    end
end

function JiangHunShop:getDisCountValue( ... )
    -- body

end

function JiangHunShop:buyEvent( sender )
    -- body
    local tag = sender:getTag()
    local id = self._shopData.itemList[tag].id
    print("buyEvent ======>", tag, id)
    LuaNetSendMsg:QueryBuyProd(2, ShopDef.KP_SP.JIANGHUN, id, 1)
end


function JiangHunShop:CloseUI( ... )
    -- body
    Utils:DeleteUI("Shop.JiangHunShop")
end

function JiangHunShop:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return JiangHunShop