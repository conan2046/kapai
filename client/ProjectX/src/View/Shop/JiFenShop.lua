local ShopDef = require("View.Shop.ShopDef")
local NormalShop = require("View.Shop.NormalShop")

local JiFenShop = NormalShop:New()
JiFenShop.__index = JiFenShop

-- -----------------------------------
function JiFenShop:New(m_table)
    local o = NormalShop:New(m_table)
    setmetatable(o, JiFenShop)
    return o
end

function JiFenShop:getMoneyType()
    return AppDef.MoneyType.COMPETE_POINTS
end

function JiFenShop:getShopType()
    return ShopDef.MK_TP.COMPETE
end

function JiFenShop:updateItemCount( index, count )
end

return JiFenShop