local ShopPanel = LUIBase:New()
ShopPanel.__index = ShopPanel


local ShopDef = require("View.Shop.ShopDef")
local ShopTable = require("View.Shop.ShopTable")
local SelectedGood = require("View.Shop.SelectedGood")

-- -----------------------------------
function ShopPanel:New(shopType)
    local o = {}
    setmetatable(o, ShopPanel)
    o:Init(shopType)
    return o
end

-- -----------------------------------
function ShopPanel:Init(shopType)
    self.m_shopType = shopType

    self.m_pShopTable = nil
    self.m_pMysteryShopTable = nil
    self.m_curShopTable = nil

    self.m_pSGDelegate = nil

    self.m_delegates = {}

    self.m_pMysteryPanel = nil --神秘商店根节点

    self.m_selectItemId = 0--默认选中的道具Id

    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    self.m_npcType = nil
end
-----------------------------------
function ShopPanel:getDelegate(shopType)
    if self.m_delegates[shopType] ~= nil then
        return self.m_delegates[shopType]
    end

    if shopType == ShopDef.MK_TP.XIANSHI then --限时抢购
        self.m_delegates[shopType] = nil

    elseif shopType == ShopDef.MK_TP.CHANGYONG then --常用道具
        self.m_delegates[shopType] = require("View.Shop.NormalShop"):New()

    elseif shopType == ShopDef.MK_TP.DUANZAO then --装备锻造
        self.m_delegates[shopType] = nil

    elseif shopType == ShopDef.MK_TP.PETHORSE then --宠物坐骑
        self.m_delegates[shopType] = nil

    elseif shopType == ShopDef.MK_TP.BANGDING then --绑定元宝
        self.m_delegates[shopType] = require("View.Shop.BindYuanBaoShop"):New()

    elseif shopType == ShopDef.MK_TP.COMPETE then --竞技场积分
        self.m_delegates[shopType] = require("View.Shop.JiFenShop"):New()

    elseif shopType == ShopDef.MK_TP.MYSTERY then --神秘商店
        self.m_delegates[shopType] = require("View.Shop.MysteryShop"):New(nil, self.m_pMysteryPanel)

    elseif shopType == ShopDef.MK_TP.GONGOFFER then --帮贡商店
        self.m_delegates[shopType] = require("View.Shop.BangGongShop"):New()

    elseif shopType == ShopDef.MK_TP.NPC then --NPC商店
        self.m_delegates[shopType] = require("View.Shop.NpcShop"):New()

    elseif shopType == ShopDef.MK_TP.TEGONG then --特供商品
        self.m_delegates[shopType] = require("View.Shop.TeGongShop"):New()
    elseif shopType == ShopDef.MK_TP.SHENPO then --神魄商品
        self.m_delegates[shopType] = require("View.Shop.ShenPoShop"):New(nil, self.m_pMysteryPanel)
    elseif shopType == ShopDef.MK_TP.ZADAN then --砸蛋商店
        self.m_delegates[shopType] = require("View.Shop.ZaDanShop"):New()
    end
    return self.m_delegates[shopType]
end
-----------------------------------
function ShopPanel:setTableDelegate()
    local shopType = self.m_shopType
    if shopType ~= ShopDef.MK_TP.MYSTERY and shopType ~= ShopDef.MK_TP.SHENPO then
       if self.m_pShopTable ~= nil then
            self.m_pShopTable:setDelegate( self:getDelegate(shopType) )
        end 
    else
        if self.m_pMysteryShopTable ~= nil then
            self.m_pMysteryShopTable:setDelegate( self:getDelegate(shopType) )
        end
    end
end
-----------------------------------
function ShopPanel:setShopType(shopType)
    if self.m_shopType == shopType then
        return
    end

    self.m_shopType = shopType
    self:setTableDelegate()
    self:changeTable()
end
-----------------------------------
function ShopPanel:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_pMysteryPanel = nil
    self.m_pShopTable = nil
    self.m_pMysteryShopTable = nil
    self.m_pSGDelegate = nil
    for k,v in pairs(self.m_delegates) do
        if k and v then
            if v.onExit then
                v:onExit()
            end
            self.m_delegates[k] = nil
        end
    end
    self.m_delegates = nil
end

-----------------------------------
function ShopPanel:RegistMsgs()
    self.msgIds = 
    {
        LUIShopEvent.ReloadShopData,
        LUIShopEvent.SelectShopItem,
        LUIShopEvent.ReloadShopCount,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function ShopPanel:ProcessEvent(msg)
    if msg.msgId == LUIShopEvent.ReloadShopData then
        print("ProcessEvent ====>", self.m_shopType, msg.value.shopType)
        if msg.value.shopType and self.m_shopType ~= msg.value.shopType then
            return
        end
        self.m_curShopTable:updateData(msg.value)
        self:refreshTableView()
        
        local selectIndex = 1
        if self.m_curShopTable.m_curSelectedIdx > 1 then
            --默认选择第一个商品
            selectIndex = self.m_curShopTable.m_curSelectedIdx
        end

        local dataList = self.m_curShopTable:getDataList()
        if #dataList > 0 then
            local selectItem = {}
            selectItem.sel_id = dataList[selectIndex].id
            selectItem.sel_num = selectIndex
            Utils:SendMsg(LUIShopEvent.SelectShopItem, selectItem)
        end
        
    elseif msg.msgId == LUIShopEvent.SelectShopItem then
        if #self.m_curShopTable:getDataList() == 0 then
            self.m_selectItemId = msg.value.sel_id
            return
        end

        if self.m_selectItemId > 0 then
            self.m_curShopTable:selectShopItem(self.m_selectItemId)
            self.m_selectItemId = 0
        else
            self.m_curShopTable:selectShopItem(msg.value.sel_id)
        end
        if msg.value.sel_id ~= nil then
            if self.m_shopType == ShopDef.MK_TP.NPC and self.m_npcType and self.m_npcType == ShopDef.ST_.DRUGSHOP then
                self.m_pSGDelegate:TimerCallBack(msg.value)
            end
        end
    elseif msg.msgId == LUIShopEvent.ReloadShopCount then
        self.m_curShopTable:getDelegate():updateItemCount(msg.value.index, msg.value.count)
        self.m_curShopTable:reset2()
        self.m_pSGDelegate:resetAll()
    end
end

-------------------------------------
function ShopPanel:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

--商城切换
function ShopPanel:changeTable()
    local isMysteryShop = self.m_shopType == ShopDef.MK_TP.MYSTERY or self.m_shopType == ShopDef.MK_TP.SHENPO

    self.m_pShopTable:setVisible(not isMysteryShop)
    -- self.m_pMysteryShopTable:setVisible(isMysteryShop)
    -- self.m_pMysteryPanel:setVisible(isMysteryShop)

    if not isMysteryShop then
        self.m_curShopTable = self.m_pShopTable
    else
        self.m_curShopTable = self.m_pMysteryShopTable
    end
    if self.m_curShopTable ~= nil then
        self.m_curShopTable:reset()
    end
end

-------------------------------------
function ShopPanel:refreshTableView()
    if self.m_pSGDelegate ~= nil then
        local isShowHave = self.m_curShopTable:getDelegate():getIsShowHave()
        local shopMoneyType = self.m_curShopTable:getDelegate():getMoneyType()
        local isChangeCount = self.m_curShopTable:getDelegate():getCanChangeCount()
        self.m_pSGDelegate:setPriceType( shopMoneyType, isShowHave, isChangeCount )
        self.m_pSGDelegate:resetAll()
    end

    if self.m_curShopTable ~= nil then
        self.m_curShopTable:refreshTableView()
    end
end

-------------------------------------
function ShopPanel:InitViewSize()
    self:CreateUINode("csd/shop/shangcheng.csb")
    -- self.m_pUILayer = cc.CSLoader:createNode("csd/shop/shangcheng.csb")
    -- self.m_pUILayer:setContentSize(AppDef.frameSize)
    -- ccui.Helper:doLayout(self.m_pUILayer)
end

-- -----------------------------------
function ShopPanel:InitUIControl()
    -----------------------------------------------------
    local shopPanel = self.m_pUILayer:getChildByName("ShopUI")
    local Panel_bg = shopPanel:getChildByName("Panel_bg")
    Panel_bg:setTouchEnabled(false)
    -----------------------------------------------------
    local pGridCell = shopPanel:getChildByName("Item")
    pGridCell:setVisible(false)

    local pTablePanel = shopPanel:getChildByName("List")
    pTablePanel:setVisible(true)
    pTablePanel:setTouchEnabled(false)

    -- self.m_pMysteryPanel = shopPanel:getChildByName("MysticalShop")
    -- self.m_pMysteryPanel:setVisible(false)
    -- self.m_pMysteryPanel:setTouchEnabled(false)

    -- local pSMTablePanel = self.m_pMysteryPanel:getChildByName("List")
    -- pSMTablePanel:setVisible(true)
    -- pSMTablePanel:setTouchEnabled(false)

    -----------------------------------------------------
    self.m_pShopTable = ShopTable:New( pTablePanel, pGridCell )
    -- self.m_pMysteryShopTable = ShopTable:New( pSMTablePanel, pGridCell )
    self:setTableDelegate()
    self:changeTable()

    -----------------------------------------------------
    local pSGDelegate = SelectedGood:New(shopPanel)
    self.m_pSGDelegate = pSGDelegate
    self.m_pSGDelegate:setBuyCallback(function(id, count, pid, pstar)
        if not LRoleDataMgr.Equip:IsPackFull() then
            self.m_curShopTable:getDelegate():buy(id, count, pid, pstar)
        else
            Utils:ShowScrollTips(GUITips.RSI_MDSI_MSGI35)
        end
    end)

    -----------------------------------------------------
    local function updateData(data)
        pSGDelegate:updateData(data)
    end
    self.m_pShopTable:setSelectCallback( updateData )
    -- self.m_pMysteryShopTable:setSelectCallback( updateData )
end

function ShopPanel:getDatas()
    if self.m_curShopTable ~= nil then
        return self.m_curShopTable:getDataList()
    else
        return {}
    end
end

function ShopPanel:setNpcType( npcType )
    -- body
    self.m_npcType = npcType
end

return ShopPanel