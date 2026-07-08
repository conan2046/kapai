local ShopUI = LUIBase:New()
ShopUI.__index = ShopUI

local ShopDef = require("View.Shop.ShopDef")

local TAB_PAGE_MAP = {
    ShopDef.PAGE_FOR_.CHANGYONGDAOJU,    --常用道具
    ShopDef.PAGE_FOR_.SHENMISHANGDIAN,     --神秘商店
    ShopDef.PAGE_FOR_.BINDYUANBAO,     --绑定元宝
    ShopDef.PAGE_FOR_.JIFEN,
    ShopDef.PAGE_FOR_.BANGGONG,
}

local TAB_MK_MAP = {
    ShopDef.MK_TP.CHANGYONG,
    ShopDef.MK_TP.MYSTERY,
    ShopDef.MK_TP.BANGDING,
    ShopDef.MK_TP.COMPETE,
    ShopDef.MK_TP.GONGOFFER,
}

local TAB_MK_KEY = {
    AppDef.EModuleID.EMID_SCCHANGYONG,
    AppDef.EModuleID.EMID_SCSHENMI,
    AppDef.EModuleID.EMID_SCBANGDING,
    AppDef.EModuleID.EMID_SCJIFEN,
    AppDef.EModuleID.EMID_SHOP_BANGPAI,
}

-- -----------------------------------
function ShopUI:New(userdata)
    local o = {}
    setmetatable(o, ShopUI)
    if type(userdata) == "table" then
        o:Init(userdata.shopType, userdata.npcType)
    else
        o:Init(userdata)
    end
    return o
end

-- -----------------------------------
function ShopUI:Init(shopType, npcType)
    self.Script = "Shop.ShopUI"

    self.m_shopType = shopType or TAB_MK_MAP[1] --默认是第一个常用道具
    self.m_npcType = npcType or 0 --1武器2防具店3药品4杂货店
    self.m_curTabInd = 0
    self.m_shopPanel = nil

    self:setTitle()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    if shopType ~= ShopDef.MK_TP.NPC and shopType ~= ShopDef.MK_TP.ZADAN then
        self:RegisterQuik()
    end
    if shopType == ShopDef.MK_TP.ZADAN then
        LuaNetSendMsg:QueryMarketInfo(11)
    end
end

-- -----------------------------------
function ShopUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_shopPanel = nil
end

-- -----------------------------------
function ShopUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    Utils:SendMsg(LUIFClassBgEvent.SetCloseCallback, handler(self, ShopUI.CloseShop))
end

function ShopUI:getOpenTab()
    for i,v in ipairs(TAB_MK_MAP) do
        if v == self.m_shopType then
            return i
        end
    end
    return 0
end

-- -----------------------------------
function ShopUI:RegisterQuik()
    local function tabBtnClicked(ind)
        self:TabClicked(ind)
    end
    self.tabValues = 
    {
        {GUITips.RSI_SHOP_DAOJU_BUY},
        tabBtnClicked
    }

    

    self:initShopTab()
    local openTab = self:getOpenTab()
    print("ShopUI:RegisterQuik ===>", openTab)
    self:SetSelectedTab(openTab)
    self:TabClicked(openTab)
end

-- -----------------------------------
function ShopUI:TabClicked(ind)
    print("ShopUI:TabClicked ============>", ind)
    if  self.m_curTabInd == ind then
        return
    end

    self.m_curTabInd = ind
    local curMkType = TAB_MK_MAP[ind]
    print("TabClicked curMkType =", curMkType, ShopDef.MK_TP.TEGONG, ShopDef.MK_TP.MYSTERY)
    self.m_shopPanel:setShopType(curMkType)

    if curMkType == ShopDef.MK_TP.TEGONG then
        -- LuaNetSendMsg:QueryMarketInfo(15)
        LuaNetSendMsg:QueryKaPaiShopUI(1, ShopDef.KP_SP.YUANBAO)
    elseif curMkType == ShopDef.MK_TP.MYSTERY then
        -- LuaNetSendMsg:QueryMarketInfo(6)
        -- LuaNetSendMsg:QueryMarketInfo(15)
        Utils:ShowScrollTips("暂无数据")
    elseif curMkType == ShopDef.MK_TP.SHENPO then
        LuaNetSendMsg:QueryMarketInfo(23)
    elseif curMkType == ShopDef.MK_TP.ZADAN then
        LuaNetSendMsg:QueryMarketInfo(11)
    else
        if curMkType == ShopDef.MK_TP.GONGOFFER then
            LuaNetSendMsg:QueryFactionInfo()
        end
        LuaNetSendMsg:QueryMarketInfo(1, TAB_PAGE_MAP[ind])
    end
end

-- -----------------------------------
function ShopUI:InitViewSize()
    self.m_pUILayer = cc.Node:create()
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

-- -----------------------------------
function ShopUI:InitUIControl()
    self.m_shopPanel = require("View.Shop.ShopPanel"):New( self.m_shopType )
    self.m_shopPanel:setNpcType(self.m_npcType)
    self.m_pUILayer:addChild(self.m_shopPanel.m_pUILayer)

    self.m_pTabBtns = {}

    performWithDelay(self.m_pUILayer, function(sender)
        Utils:SendMsg(LUIRoleDataChangeEvent.BGVisible, false)
    end, 0.3)
end

function ShopUI:touchTab(ind)
    self:SetSelectedTab(ind)
    if self.m_pTabFunc then
        self.m_pTabFunc(ind)
    end
end

function ShopUI:SetSelectedTab(ind)

    if self.m_pTabBtns == nil then
        return
    end

    if ind == nil or ind > #self.m_pTabBtns or ind <= 0 then 
        return
    end
    if self.m_curTabInd == ind then
        return
    end
    
    if self.m_curTabInd > 0 and self.m_curTabInd <=  #self.m_pTabBtns then
        local btn =  self.m_pTabBtns[self.m_curTabInd]:getChildByName("Button_1")
        btn:setBright(true)
        btn:setEnabled(true)
    end
    -- self.m_curTabInd = ind
    local btn =  self.m_pTabBtns[ind]:getChildByName("Button_1")
    btn:setEnabled(false)
    btn:setBright(false)

end

function ShopUI:initShopTab( ... )
    -- body
    self.m_pTabBtnList = self.m_shopPanel.m_pUILayer:getChildByName("ShopUI"):getChildByName("ListView_left")
    self.m_pTabBtn = self.m_pTabBtnList:getChildByName("Panel_button")
    self.m_pTabBtn:removeFromParent()
    self.m_pTabBtn:retain()

    local function tablefunc(sender)
        local ind = sender:getTag()
        self:touchTab(ind)
    end

    self.m_pTabFunc = self.tabValues[2]
    for i = 1, #self.tabValues[1] do
        local tab = self.m_pTabBtn:clone()
        local btn = tab:getChildByName("Button_1")
        btn:setTag(i)

        local chooseName = btn:getChildByName("Text")
        chooseName:setString(self.tabValues[1][i])

        btn:addClickEventListener(tablefunc)

        self.m_pTabBtnList:pushBackCustomItem(tab)

        table.insert(self.m_pTabBtns, tab)
    end
end

function ShopUI:setTitle()
    if self.m_npcType > 0 then
        local npcType = self.m_npcType
        local str = ""
        if npcType == ShopDef.ST_.WEPONSHOP then
        elseif npcType == ShopDef.ST_.WEPONSHOP then
            str = GUITips.RIS_LEFTUI_MSG38
        elseif npcType == ShopDef.ST_.ARMORSHOP then 
            str = GUITips.RIS_LEFTUI_MSG39
        elseif npcType == ShopDef.ST_.DRUGSHOP then 
            str = GUITips.RIS_LEFTUI_MSG40
        elseif npcType == ShopDef.ST_.GROCERYSHOP then 
            str = GUITips.RIS_LEFTUI_MSG41
        elseif npcType == ShopDef.ST_.SEEDSHOP then 
            str = GUITips.RIS_LEFTUI_MSG42
        end
        Utils:SendMsg(LUIFClassBgEvent.SetTitle, str)
    else
        if self.m_shopType == ShopDef.MK_TP.ZADAN then
            Utils:SendMsg(LUIFClassBgEvent.SetTitle, GUITips.RSI_ML_TIP19)
        else
            Utils:SendMsg(LUIFClassBgEvent.SetTitle, GUITips.RSI_ML_TIP13)
        end
    end
end

function ShopUI:CloseShop()
    if self.m_shopType == ShopDef.MK_TP.ZADAN then
        Utils:DeleteUI("WelfareActivity.ZaDanUI")
        Utils:InitUI("WelfareActivity.ZaDanUI", AppDef.UIType.PopWindow)
    end
    Utils:SendMsg(LUIRoleDataChangeEvent.BGVisible, true)
    self:RemoveUI()
end

return ShopUI