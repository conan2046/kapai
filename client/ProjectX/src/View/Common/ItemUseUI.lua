local ItemUseUI = LUIBase:New()
ItemUseUI.__index = ItemUseUI
ItemUseUI.IsHideInBattle = true
function ItemUseUI:New(userData)
    local o = LUIBase:New()
    setmetatable(o,ItemUseUI) 
    o:Init(userData)
    return o
end

function ItemUseUI:Init(userData)
    self.Script = "Common.ItemUseUI"
    self:CreateUINode("csd/common/daojushiyong.csb")
    -- self.m_pUILayer = cc.CSLoader:createNode("csd/common/daojushiyong.csb")
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:InitData(userData)
    self:ShowInfo()

    --Utils:SendMsg(LUISecondClassBgEvent.SetTitle, GUITips.UI_Title_XueZhan)
    --Utils:SendMsg(LUISecondClassBgEvent.SetCloseCallback,handler(self,ItemUseUI.CloseUI))
    if self.m_shopType == 0 or self.m_itemId == 0 then
        return
    end
    if PetkaPaiManager.m_AllShopData[self.m_shopType] == nil then
        LuaNetSendMsg:QueryKaPaiShopUI(1, self.m_shopType)
    else
        self:GetShopData()
    end
end

--[[
注册UI消息
]]
function ItemUseUI:RegistMsgs()
    self.msgIds = 
    {
        LUIShopEvent.ReloadShopData,
    }
    self:RegistSelf(self,self.msgIds)
end

function ItemUseUI:ProcessEvent(msg)
    --dump(msg)
    -- if msg.msgId == LUIShopEvent.QueryBuyCntResult then
    --     self:ShowBuyCnt()
    if msg.msgId == LUIShopEvent.ReloadShopData then
        self:GetShopData()
    end
end

function ItemUseUI:InitData(userData)
    self.m_itemId = userData[1] or 0
    self.m_shopType = userData[2] or 0 --商店类型
    --self.m_vipFieldName = userData[3] or ""--vip表字段名
    local panel = self.m_pUILayer:getChildByName("Popup")
    --关闭按钮
    local closeBtn = panel:getChildByName("Btn_close")
    closeBtn:addClickEventListener(handler(self, ItemUseUI.CloseUI))
    self.m_buyBtn = panel:getChildByName("Btn_Buy")
    self.m_buyBtn:addClickEventListener(handler(self, ItemUseUI.OnBuyClick))
    self.m_useBtn = panel:getChildByName("Btn_Use")
    self.m_useBtn:addClickEventListener(handler(self, ItemUseUI.OnUseClick))

    self.m_buyLabel = self.m_buyBtn:getChildByName("text"):getChildByName("num")
    self.m_numLabel = self.m_useBtn:getChildByName("text"):getChildByName("num")

    local itemPanel = panel:getChildByName("Panel_1")
    self.m_grid = itemPanel:getChildByName("Icon")
    self.m_nameLabel = itemPanel:getChildByName("Name")
    self.m_typeLabel = itemPanel:getChildByName("text")
    self.m_valueLabel = self.m_typeLabel:getChildByName("mine")

    self.m_buyCnt = 0
    --self.m_idx = 0
end

function ItemUseUI:GetShopData()
    local info = PetkaPaiManager.m_AllShopData[self.m_shopType]
    if info.itemList == nil then
        return
    end
    for i=1,#info.itemList do
        local cfg = JsonConfig.m_ShopInfo.getDefByID(info.itemList[i].id)
        if cfg ~= nil and cfg.itemid[1] == self.m_itemId then
            self.m_shopCfg = cfg
            self.m_buyCnt = info.itemList[i].buyTimes
            --self.m_idx = i
            break
        end
    end
    --print("ItemUseUI:GetShopData",self.m_idx,self.m_shopCfg.id)
    self:ShowBuyCnt()
end

--获取剩余次数
function ItemUseUI:GetResidueCnt()
    local vipLv = LRoleDataMgr.MyHeroInfo.MyVIPInfo.vipLevel
    local maxCnt = 0
    if self.m_shopCfg == nil then
        self.m_residueCnt = 0
    end
    if #self.m_shopCfg.count == 0 then
        self.m_residueCnt  = 0xffff
        return
    end
    maxCnt = self.m_shopCfg.count[2]
    
    -- self.m_vipAddCnt = 0
    -- local vipCfg = JsonConfig.m_vipConfig.getDefByID(vipLv)
    -- if vipCfg ~= nil then
    --     self.m_vipAddCnt = vipCfg[self.m_vipFieldName] or 0
    --     maxCnt = maxCnt + self.m_vipAddCnt
    -- end
    local cnt = self.m_buyCnt or 0
    local buyCnt = maxCnt-cnt 
    if buyCnt < 0 then
        buyCnt = 0 
    end
    
    self.m_residueCnt  = buyCnt--剩余次数
end

function ItemUseUI:ShowInfo()
    self.m_typeLabel:setString("")
    self.m_valueLabel:setString("")
    self.m_buyLabel:getParent():setVisible(false)
    --self.m_buyBtn:setBright(false)
    self.m_buyBtn:setEnabled(false)
    if self.m_itemId == 0 then
        return
    end
    local cfg = JsonConfig.m_Item.getDefByID(self.m_itemId)
    if cfg == nil then
        return
    end
    
    self.m_item = Utils:GetItemCellValue(self.m_grid, 0, self.m_itemId, true, false, 0, self.m_item, false, true)
    
    local num = LRoleDataMgr.Equip:CountItemNumById(self.m_itemId)
    self.m_numLabel:setString(""..num)
    self.m_nameLabel:setString(""..cfg.name)
    self.m_nameLabel:setColor(AppDef:GetQualityColor(cfg.quality))
    if num < 1 then
        self.m_useBtn:setBright(false)
        self.m_useBtn:setEnabled(false)
    end
    
    if cfg.use_type == 0 or #cfg.sub_value == 0 then
        return
    end
    self.m_typeLabel:setString(AppDef.SpecialItemName[cfg.sub_value[1][1]]..": ")
    local pos = cc.p(self.m_valueLabel:getPosition())
    self.m_valueLabel:setPosition(self.m_typeLabel:getAutoRenderSize().width,pos.y)
    self.m_valueLabel:setString("+"..cfg.sub_value[1][2])
end

function ItemUseUI:ShowBuyCnt()
    self:GetResidueCnt()
    self.m_buyLabel:setString(""..self.m_residueCnt..GUITips.RSI_COUNT)
    if self.m_residueCnt > 0 then
        --self.m_buyBtn:setBright(true)
        self.m_buyBtn:setEnabled(true)
    end
    self.m_buyLabel:setString(""..self.m_residueCnt..GUITips.RSI_COUNT)
    if self.m_residueCnt ~= 0xffff then
        self.m_buyLabel:getParent():setVisible(true)
    end
end

function ItemUseUI:OnBuyClick()
    if self.m_residueCnt < 1 then
        return
    end
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
    print("ItemUseUI:OnBuyClick",self.m_buyCnt,nextVip,self.m_shopCfg.id)
    Utils:OpenBuyUI(self.m_shopCfg.id,self.m_residueCnt,nextVip,addCnt,self.m_buyCnt)
    self:CloseUI()
end

function ItemUseUI:OnUseClick()
    local function NumInputCallback(num)
        if num == 0 or self.m_pos == nil then
           return
        end
        LuaNetSendMsg:SendItemUseReq(self.m_pos-1,num,0)
        self:CloseUI()
    end

    self.m_pos = LRoleDataMgr.Equip:FindPackageItemById1(self.m_itemId)
    if self.m_pos == 0 then
        return
    end
    local info = LRoleDataMgr.Equip.PackageMap[self.m_pos]
    if info == nil then
        return
    end
    local sign = false
    if info.m_item.use_type == 1 then
        sign = true
    elseif info.m_item.use_type == 2 then
        if info.m_num == 1 then
            sign = true
        else
            Utils:ShowNumInputUI(info.m_num,NumInputCallback)
        end
    end
    if sign then
        LuaNetSendMsg:SendItemUseReq(self.m_pos-1,1,0)
        self:CloseUI()
    end
end

function ItemUseUI:CloseUI()
    LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Common.ItemUseUI")
    self:SendMsg(LGameMsg.m_deleteUIMsg)
end

function ItemUseUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_itemId = nil
    self.m_shopType = nil
    self.m_buyCnt = nil
    --self.m_idx = nil
    self.Script  = nil
end

return ItemUseUI