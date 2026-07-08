local ItemExchangeUI = LUIBase:New()
ItemExchangeUI.__index = ItemExchangeUI
ItemExchangeUI.IsHideInBattle = true
function ItemExchangeUI:New(userData)
    local o = LUIBase:New()
    setmetatable(o,ItemExchangeUI) 
    o:Init(userData)
    return o
end

function ItemExchangeUI:Init(userData)
    self.Script = "Common.ItemExchangeUI"
    self:CreateUINode("csd/common/daojuduihuan.csb")
    -- self.m_pUILayer = cc.CSLoader:createNode("csd/common/daojuduihuan.csb")
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:InitData(userData)
    self:GetShopData()
    self:ShowList()
    --Utils:SendMsg(LUISecondClassBgEvent.SetTitle, GUITips.UI_Title_XueZhan)
    --Utils:SendMsg(LUISecondClassBgEvent.SetCloseCallback,handler(self,ItemExchangeUI.CloseUI))
end

--[[
注册UI消息
]]
function ItemExchangeUI:RegistMsgs()
    self.msgIds = 
    {
        LUIShopEvent.ReloadShopData,
        LUIShopEvent.UpdateKaPaiShop,
    }
    self:RegistSelf(self,self.msgIds)
end

function ItemExchangeUI:ProcessEvent(msg)
    if msg.msgId == LUIShopEvent.ReloadShopData or msg.msgId == LUIShopEvent.UpdateKaPaiShop then
        self:ShowList()
    end
end

function ItemExchangeUI:InitData(userData)
    self.m_itemId = userData or 0
    self.m_cells = {}

    local panel = self.m_pUILayer:getChildByName("Popup")
    --关闭按钮
    local closeBtn = panel:getChildByName("Btn_close")
    closeBtn:addClickEventListener(handler(self, ItemExchangeUI.CloseUI))
    self.m_listView = panel:getChildByName("ListView")
    self.m_itemCell = panel:getChildByName("kuang")
end

function ItemExchangeUI:GetShopData()
    if self.m_itemId == 0 then
        return
    end
    self.m_shopIds = {}
    local shopTypes = {}
    local list = JsonConfig.m_ShopInfo.getList()
    for i=1,#list do
        if list[i].itemid[1] == self.m_itemId and list[i].price[1][1] == AppDef.EMoneyType.EMT_Cash then
            table.insert(self.m_shopIds,list[i].id)
            shopTypes[list[i].type] = true
        end
    end
    for k,v in pairs(shopTypes) do
        if PetkaPaiManager.m_AllShopData[k] == nil then
            LuaNetSendMsg:QueryKaPaiShopUI(1, k)
        end
    end
    --dump(self.m_shopIds)
end

function ItemExchangeUI:ShowList()
    for i=1,#self.m_shopIds do
        if self.m_cells[i] == nil then
            self.m_cells[i] = self.m_itemCell:clone()
            self.m_cells[i].userObject = self.m_shopIds[i]
            self.m_listView:pushBackCustomItem(self.m_cells[i])
            local btn = self.m_cells[i]:getChildByName("Btn_Confirm")
            btn.userObject = {self.m_shopIds[i]}
            btn:addClickEventListener(handler(self,ItemExchangeUI.BtnCallBack))
        end
        self:ShowOneItem(self.m_cells[i])
    end
end

function ItemExchangeUI:ShowOneItem(sender)
    local id = sender.userObject
    local cfg = JsonConfig.m_ShopInfo.getDefByID(id)
    if cfg == nil then
        return
    end
    local info = PetkaPaiManager.m_AllShopData[cfg.type]
    if info == nil then
        return
    end
    local moneyGrid = sender:getChildByName("Icon1")
    local itemGrid = sender:getChildByName("Icon2")
    local valuePanel = sender:getChildByName("Discount")
    local valueLabel = valuePanel:getChildByName("Value")
    local btn = sender:getChildByName("Btn_Confirm")
    
    moneyGrid:removeAllChildren()
    itemGrid:removeAllChildren()

    local buyCnt = 0
    for i=1,#info.itemList do
        if info.itemList[i].id == id then
            buyCnt = info.itemList[i].buyTimes
            break
        end
    end
    btn.userObject = {id,buyCnt}
    buyCnt = buyCnt + 1
    local idx = math.min(buyCnt,#cfg.price_real)
    local radio = cfg.price_real[idx]
    local money = math.floor(cfg.price[1][3]*radio/100)
    if idx == #cfg.price_real then
        valuePanel:setVisible(false)
    else
        valueLabel:setString(string.format(GUITips.RSI_DISCOUNTSHOP_DISCOUNT,radio/10))
    end
    print("ItemExchangeUI:ShowOneItem",cfg.price[1][1],money)
    Utils:GetItemCellValue(moneyGrid, 0, cfg.price[1][1], true, true, money, nil, false, true)
    Utils:GetItemCellValue(itemGrid, 0, cfg.itemid[1], true, true, cfg.itemid[3], nil, false, true)
end

function ItemExchangeUI:BtnCallBack(sender)
    local value = sender.userObject
    local id = value[1]
    local buyCnt = value[2]
    local cfg = JsonConfig.m_ShopInfo.getDefByID(id)
    local nextVip = 0
    local addCnt = 0
    -- local vipLv = LRoleDataMgr.MyHeroInfo.MyVIPInfo.vipLevel+1
    -- for i= vipLv,JsonConfig.m_maxVipLv do
    --     local cfg = JsonConfig.m_vipConfig.getDefByID(i)
    --     if cfg ~= nil then
    --         local cnt = cfg[self.m_vipFieldName] or 0
    --         if cnt > self.m_vipAddCnt then
    --             nextVip = i
    --             addCnt = cnt - self.m_vipAddCnt
    --             break
    --         end
    --     end
    -- end
    local maxCnt = 0xffff
    if #cfg.count == 2 then
        maxCnt = cfg.count[2]
    end
    local residueCnt = self:GetResidueCnt(buyCnt,maxCnt)
    print("ItemExchangeUI:BtnCallBack",self.m_buyCnt,nextVip)
    Utils:OpenBuyUI(id,residueCnt,nextVip,addCnt,buyCnt)
    self:CloseUI()
end

--获取剩余次数
--@curCnt 已经购买次数
--@maxCnt 基础最大购买次数
function ItemExchangeUI:GetResidueCnt(curCnt,maxCnt)
    print("ItemExchangeUI:GetResidueCnt",curCnt,maxCnt)
    if maxCnt == 0xffff then
        return maxCnt
    end
    local vipLv = LRoleDataMgr.MyHeroInfo.MyVIPInfo.vipLevel
    local vipAddCnt = 0
    -- local vipCfg = JsonConfig.m_vipConfig.getDefByID(vipLv)
    -- if vipCfg ~= nil then
    --     self.m_vipAddCnt = vipCfg[self.m_vipFieldName] or 0
    --     maxCnt = maxCnt + self.m_vipAddCnt
    -- end
    local cnt = maxCnt - curCnt
    if cnt < 0 then
        cnt = 0 
    end
    return cnt--剩余次数
end

function ItemExchangeUI:CloseUI()
    LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Common.ItemExchangeUI")
    self:SendMsg(LGameMsg.m_deleteUIMsg)
end

function ItemExchangeUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_itemId = nil
    self.m_shopIds = nil
    self.m_cells = nil
end

return ItemExchangeUI