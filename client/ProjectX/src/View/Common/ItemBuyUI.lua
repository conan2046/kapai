local ItemBuyUI = LUIBase:New()
ItemBuyUI.__index = ItemBuyUI
ItemBuyUI.IsHideInBattle = true
function ItemBuyUI:New(userData)
    local o = LUIBase:New()
    setmetatable(o,ItemBuyUI) 
    o:Init(userData)
    return o
end

function ItemBuyUI:Init(userData)
    self.Script = "Common.ItemBuyUI"
    self:CreateUINode("csd/common/daojugoumai.csb")
    -- self.m_pUILayer = cc.CSLoader:createNode("csd/common/daojugoumai.csb")
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitData(userData)
    self:GetShopData()
    self:ShowInfo()

    --Utils:SendMsg(LUISecondClassBgEvent.SetTitle, GUITips.UI_Title_XueZhan)
    --Utils:SendMsg(LUISecondClassBgEvent.SetCloseCallback,handler(self,ItemBuyUI.CloseUI))
end

function ItemBuyUI:InitData(userData)
    --dump(userData,"userData:")
    self.isUsed=true
    self.m_shopId = userData[1] or 0
    self.m_buyCnt = userData[2] or 0 --还可购买次数
    self.m_nextVip = userData[3] or 0--下一级增加次数的Vip，0-表示不显示
    self.m_addCnt = userData[4] or 0--增加的次数
    --self.m_index = userData[5] or 0
    self.m_curCnt = userData[5] or 0 --已购买次数
    --print("m_curCnt",self.m_curCnt)

    local panel = self.m_pUILayer:getChildByName("Popup")
    --关闭按钮
    local closeBtn = panel:getChildByName("Btn_close")
    closeBtn:addClickEventListener(handler(self, ItemBuyUI.CloseUI))
    self.m_CheckBox=panel:getChildByName("CheckBox")
    self.m_CheckBox:addEventListener(handler(self,ItemBuyUI.OnUsedClick))

    self.m_buyBtn = panel:getChildByName("Btn_Buy")
    self.m_buyBtn:addClickEventListener(handler(self, ItemBuyUI.OnBuyClick))
    self.m_buyLabel = self.m_buyBtn:getChildByName("use")
    self.m_buyLabel:setVisible(false)
    self.m_buyLayer = self.m_buyBtn:getChildByName("buy_layer")
    self.m_buyLayer:setTouchEnabled(false)
    self.m_moneyGrid = self.m_buyLayer:getChildByName("Icon_item")
    self.m_moneyNumLabel = self.m_buyLayer:getChildByName("Text")
    self.m_bagMoneyNumLabel = self.m_buyLayer:getChildByName("text"):getChildByName("mine")

    local itemPanel = panel:getChildByName("Panel_1")
    self.m_grid = itemPanel:getChildByName("Icon")
    self.m_nameLabel = itemPanel:getChildByName("Name")
    self.m_shopNumLabel = self.m_nameLabel:getChildByName("item_num")
    self.m_HavePanel = itemPanel:getChildByName("text")
    self.m_bagNumLabel = self.m_HavePanel:getChildByName("mine")
 

    local panel2 = panel:getChildByName("Panel_2")
    panel2:setVisible(false)

    local panel3 = panel:getChildByName("Panel_3")
    self.m_numLabel = panel3:getChildByName("Count"):getChildByName("Value")
    local subBtn = panel3:getChildByName("Btn_Minus")
    subBtn:addClickEventListener(handler(self, ItemBuyUI.OnSubClick))
    local addBtn = panel3:getChildByName("Btn_Plus")
    addBtn:addClickEventListener(handler(self, ItemBuyUI.OnAddClick))
    local sub2Btn = panel3:getChildByName("Btn_Minus10")
    sub2Btn:addClickEventListener(handler(self, ItemBuyUI.OnSub10Click))
    local add2Btn = panel3:getChildByName("Btn_Plus10")
    add2Btn:addClickEventListener(handler(self, ItemBuyUI.OnAdd10Click))

    local panel4 = panel:getChildByName("Panel_4")
    local buyLabel = panel4:getChildByName("text1")
    self.m_buyNumLabel = buyLabel:getChildByName("buy_num")
    self.m_vipLabel = buyLabel:getChildByName("vip")

   

    self.m_cnt = 1
end

function ItemBuyUI:ShowCnt()
    self.m_numLabel:setString(""..self.m_cnt)
end

function ItemBuyUI:GetShopData()
    self.m_shopCfg = JsonConfig.m_ShopInfo.getDefByID(self.m_shopId)
    self.m_type = 0
    self.m_itemId = self.m_shopCfg.itemid[1]
    if self.m_itemId == AppDef.RewardItem.RD_ITEM_EQUIP 
        or self.m_itemId == AppDef.RewardItem.RD_ITEM_FABAO 
        or self.m_itemId == AppDef.RewardItem.RD_ITEM_PET then
        self.m_type = self.m_itemId
        self.m_itemId = self.m_shopCfg.itemid[2]
    end
end

function ItemBuyUI:GetMoney(index)
    if self.m_shopCfg == nil or index < 1 then
        return 0
    end
    local cfg = self.m_shopCfg
    local cnt = self.m_curCnt + index
    local idx = math.min(cnt,#cfg.price_real)
    local radio = cfg.price_real[idx]
    local money = math.floor(cfg.price[1][3]*radio/100)
    return money
end

function ItemBuyUI:ShowMoney()
    if self.m_cnt < 1 then
        return
    end
    if self.m_shopCfg == nil then
        return
    end
    local cfg = self.m_shopCfg
    local money = 0
    for i=1,self.m_cnt do
        money = money + self:GetMoney(i)
    end
    self.m_moneyNumLabel:setString("*"..money)
    self.m_moneyItem = Utils:GetItemCellValue(self.m_moneyGrid, 0, cfg.price[1][1], true, false, 0, self.m_moneyItem, false, true)
    local width  = self.m_nameLabel:getAutoRenderSize().width
    self.m_shopNumLabel:setString("*"..cfg.itemid[3])
    self.m_shopNumLabel:setPositionX(width+5)
    self.m_bagMoneyNumLabel:setString("*"..LRoleDataMgr:GetMoney(cfg.price[1][1]))
end

function ItemBuyUI:ShowVipTips()
    self.m_vipLabel:setString("")
    --print("ItemBuyUI:ShowVipTips",self.m_nextVip,self.m_addCnt)
    if self.m_nextVip == 0 then
        return
    end
    self.m_vipLabel:setString(string.format(GUITips.RSI_SHOP_TIPS2,self.m_nextVip,self.m_addCnt))
end

function ItemBuyUI:ShowInfo()
    self.m_buyNumLabel:getParent():setVisible(false)
    if self.m_itemId == 0 then
        return
    end
    local cfg = nil 
    local num = 0
    if self.m_type == AppDef.RewardItem.RD_ITEM_EQUIP then
        cfg = JsonConfig.m_equipConfig.getDefByID(self.m_itemId)
    elseif self.m_type == AppDef.RewardItem.RD_ITEM_FABAO then
        cfg = JsonConfig.m_faBaoConfig.getDefByID(self.m_itemId)
    elseif self.m_type == AppDef.RewardItem.RD_ITEM_PET then
        cfg = JsonConfig.m_heroCfg.getDefByID(self.m_itemId)
    else
        cfg = JsonConfig.m_Item.getDefByID(self.m_itemId)
        num = LRoleDataMgr.Equip:CountItemNumById(self.m_itemId)
    end
    if cfg == nil then
        return
    end
    if self.m_itemId==500 then
        self.m_CheckBox:setVisible(true)
    else
        self.m_CheckBox:setVisible(false)
    end

    self.m_item = Utils:ShowItemByConfigData(self.m_shopCfg.itemid, self.m_grid, self.m_item, false, true)
    --self.m_item = Utils:GetItemCellValue(self.m_grid, 0, self.m_itemId, true, isShow, itemNum, self.m_item, false, true)
    if self.m_type == 0 then
        self.m_HavePanel:setVisible(true)
        self.m_bagNumLabel:setString("*"..num)
    else
        self.m_HavePanel:setVisible(false)
    end
    self.m_nameLabel:setString(""..cfg.name)
    self.m_nameLabel:setColor(AppDef:GetQualityColor(cfg.quality))
    self.m_buyNumLabel:setString(""..self.m_buyCnt..GUITips.RSI_COUNT)
    if self.m_buyCnt ~= 0xffff then
        self.m_buyNumLabel:getParent():setVisible(true)
    end
    self:ShowMoney()
    self:ShowCnt()
    self:ShowVipTips()
end


function ItemBuyUI:OnBuyClick()
    if self.m_shopCfg == nil then
        return
    end
    local used = 0
    if self.m_itemId==500 and self.isUsed==true then
        used=1

    end    
    print(used,self.m_itemId,self.isUsed)
    --print("OnBuyClick",self.m_shopCfg.type, self.m_index)
    LuaNetSendMsg:QueryBuyProd(2, self.m_shopCfg.type, self.m_shopId, self.m_cnt,used)
    self:CloseUI()
end

function ItemBuyUI:OnUsedClick()
    self.isUsed=(not self.isUsed)
    self.m_CheckBox:setSelectedState(self.isUsed) 
end


function ItemBuyUI:OnAddClick()
    if self.m_shopCfg == nil then
        return
    end
    if self.m_cnt >= self.m_buyCnt then
        Utils:ShowScrollTips(GUITips.RSI_SHOP_TIPS1)
        return
    end
    local money = 0
    for i=1,self.m_cnt+1 do
        money = money + self:GetMoney(i)
    end
    local data = {}
    data[1] = self.m_shopCfg.price[1][1]
    data[2] = 0
    data[3] = money
    --dump(data)
    local sign = LRoleDataMgr:CheckIsEnough(data)
    if not sign then
        Utils:ShowScrollTips(string.format(GUITips.RSI_SHOP_TIPS3,AppDef.SpecialItemName[data[1]]))
        return
    end
    self.m_cnt = self.m_cnt +1
    if self.m_cnt > self.m_buyCnt then
        self.m_cnt = self.m_buyCnt
    end
    self:ShowMoney()
    self:ShowCnt()
end

function ItemBuyUI:OnSubClick()
    if self.m_shopCfg == nil or self.m_cnt == 1 then
        return
    end
    self.m_cnt = self.m_cnt -1
    if self.m_cnt < 1 then
        self.m_cnt = 1
    end
    self:ShowMoney()
    self:ShowCnt()
end

function ItemBuyUI:OnAdd10Click()
    if self.m_shopCfg == nil then
        return
    end
    if self.m_cnt >= self.m_buyCnt then
        Utils:ShowScrollTips(GUITips.RSI_SHOP_TIPS1)
        return
    end
    local money = 0
    local add = 10
    for i=1,self.m_cnt+10 do
        money = money + self:GetMoney(i)
        local data = {}
        data[1] = self.m_shopCfg.price[1][1]
        data[2] = 0
        data[3] = money
        local sign = LRoleDataMgr:CheckIsEnough(data)
        if not sign then
            if i <= self.m_cnt +1  then
                Utils:ShowScrollTips(string.format(GUITips.RSI_SHOP_TIPS3,AppDef.SpecialItemName[data[1]]))
                return
            else
                add = i-self.m_cnt -1
                break
            end
        end
    end
    self.m_cnt = self.m_cnt +add
    if self.m_cnt > self.m_buyCnt then
        self.m_cnt = self.m_buyCnt
    end
    self:ShowMoney()
    self:ShowCnt()
end

function ItemBuyUI:OnSub10Click()
    if self.m_shopCfg == nil or self.m_cnt == 1  then
        return
    end
    self.m_cnt = self.m_cnt -10
    if self.m_cnt < 1 then
        self.m_cnt = 1
    end
    self:ShowMoney()
    self:ShowCnt()
end

function ItemBuyUI:CloseUI()
    LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Common.ItemBuyUI")
    self:SendMsg(LGameMsg.m_deleteUIMsg)
end

function ItemBuyUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_itemId = nil
    self.m_buyCnt = nil
    self.Script  = nil
end

return ItemBuyUI