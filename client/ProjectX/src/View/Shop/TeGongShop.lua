local ShopDef = require("View.Shop.ShopDef")
local NormalShop = require("View.Shop.NormalShop")

local TeGongShop = NormalShop:New()
TeGongShop.__index = TeGongShop

-- -----------------------------------
function TeGongShop:New(m_table)
    local o = NormalShop:New(m_table)
    setmetatable(o, TeGongShop)
    return o
end

function TeGongShop:selectItem(index)
    local data = self.m_datas.normalGoods[index]

    local sData = ShopSelectInfo:New()
    sData.m_name = data.itemData.m_item.name
    sData.m_desc = data.itemData.m_item.des
    sData.m_id = data.id
    sData.m_count = 1
    sData.m_unitCount = 1
    sData.m_price = data.price
    sData.m_priceType = self:getMoneyType()
    sData.m_isShowHave = false
    sData.m_isChangeCount = false
    sData.m_count = data.num
    
    self.m_table:selectItem(sData)
end

function TeGongShop:getMoneyType()
    return AppDef.MoneyType.RENMINBI
end

function TeGongShop:getShopType()
    return ShopDef.MK_TP.TEGONG
end

function TeGongShop:getIsShowHave()
    return false
end

function TeGongShop:getCanChangeCount()
    return false
end

function TeGongShop:buy(id, count)
    Utils:ShowScrollTips(GUITips.RSI_ML_TIP1)
end

return TeGongShop