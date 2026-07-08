local ShopDef = require("View.Shop.ShopDef")
local NormalShop = require("View.Shop.NormalShop")

local BindYuanBaoShop = NormalShop:New()
BindYuanBaoShop.__index = BindYuanBaoShop

-- -----------------------------------
function BindYuanBaoShop:New(m_table)
    local o = NormalShop:New(m_table)
    setmetatable(o, BindYuanBaoShop)
    return o
end

function BindYuanBaoShop:getMoneyType()
    return AppDef.MoneyType.YUANBAO_BANG
end

function BindYuanBaoShop:getShopType()
    return ShopDef.MK_TP.BANGDING
end

function BindYuanBaoShop:updateItemCount( index, count )
end

return BindYuanBaoShop