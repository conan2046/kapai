local ShopDef = require("View.Shop.ShopDef")
local NormalShop = require("View.Shop.NormalShop")

local ZaDanShop = NormalShop:New()
ZaDanShop.__index = ZaDanShop

-- -----------------------------------
function ZaDanShop:New()
    local o = {}
    setmetatable(o, ZaDanShop)
    return o
end

function ZaDanShop:getMoneyType()
    return AppDef.MoneyType.ZADAN_POINTS
end

function ZaDanShop:getShopType()
    return ShopDef.MK_TP.ZADAN
end

function ZaDanShop:updateItemCount( index, count )
	
end

function ZaDanShop:buy(id, count, pid, pstar)
    LuaNetSendMsg:QueryBuyZaDan(id, count)
end

function ZaDanShop:setItem(item, data, index, itemIndex, bVisible)
	local mt = getmetatable(ZaDanShop)
	if mt == nil then
		return
	end
	local setItemFunc = rawget(mt, "setItem")
	if setItemFunc == nil then
		return
	end
	setItemFunc(self, item, data, index, itemIndex, bVisible)
    if data.id == AppDef.AwrdItem.AWRD_ITEM_PETEQUIP then
    	local info = LDataConstMgr:GetPetEquipCfgData(data.petEquipId)
    	if info == nil then
    	    return
    	end
    	local pNameText = item:getChildByName("Name")
    	local color = AppDef:GetItemQualityColor(info.quality)
    	pNameText:setTextColor(color)
    else
    	if data.itemData == nil then
    	    return
    	end
    	local goodData = data.itemData.m_item
    	local pNameText = item:getChildByName("Name")
    	local color = AppDef:GetItemQualityColor(goodData.m_quality)
    	pNameText:setTextColor(color)
    end
end

return ZaDanShop