local ShopDef = require("View.Shop.ShopDef")
local MysteryShop = require("View.Shop.MysteryShop")

local ShenPoShop = MysteryShop:New()
ShenPoShop.__index = ShenPoShop

-- -----------------------------------
function ShenPoShop:New(_table, rootUI)
    local o = MysteryShop:New(_table, rootUI)
    setmetatable(o, ShenPoShop)
    o:Init(_table, rootUI)
    return o
end

function ShenPoShop:flushCallback(sender)
    LuaNetSendMsg:QueryMarketInfo(25, 0)
end

--刷新按钮
function ShenPoShop:setShenMiFlushCallback()
    local flushBtn = self.m_pRootUI:getChildByName("btn_Refresh")
    flushBtn:addClickEventListener(handler(self, ShenPoShop.flushCallback))
end

function ShenPoShop:setTimer(leftTime)
    if self.m_timerLabel ~= nil then
        self.m_timerLabel:set(leftTime, handler(self, ShenPoShop.flushCallback))
        self.m_timerLabel:start()
    end
end

function ShenPoShop:buy(id, count)
    local index = self:findGoodByID(id)
    if index then
        local datas = self:getDataList()
        local data = datas[index+1]
        if data and LRoleDataMgr.MyHeroInfo:GetDetailData().shenHun < data.price then
            Utils:ShowScrollTips(GUITips.RSI_ML_TIP16)
            return
        end
        LuaNetSendMsg:QueryMarketInfo(24, index, id)
    end
end

function ShenPoShop:getMoneyType()
    return AppDef.MoneyType.SHENHUN
end

function ShenPoShop:getShopType()
    return ShopDef.MK_TP.SHENPO
end

return ShenPoShop