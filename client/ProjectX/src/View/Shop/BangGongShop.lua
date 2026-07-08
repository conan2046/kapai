local ShopDef = require("View.Shop.ShopDef")
local NormalShop = require("View.Shop.NormalShop")

local BangGongShop = NormalShop:New()
BangGongShop.__index = BangGongShop

-- -----------------------------------
function BangGongShop:New(m_table)
    local o = NormalShop:New(m_table)
    setmetatable(o, BangGongShop)
    return o
end

function BangGongShop:getMoneyType()
    return AppDef.MoneyType.BANGGONG
end

function BangGongShop:getShopType()
    return ShopDef.MK_TP.GONGOFFER
end

function BangGongShop:updateItemCount( index, count )
	
end

return BangGongShop