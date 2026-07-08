local ShopDef = require("View.Shop.ShopDef")


local NpcShop = LUIBase:New()
NpcShop.__index = NpcShop

-- -----------------------------------
function NpcShop:New(_table)
    local o = {}
    setmetatable(o, NpcShop)
    o:Init(_table)
    return o
end

-- -----------------------------------
function NpcShop:Init(_table)
    self.m_table = nil
    self.m_table = _table

    self.m_npcDatas = nil
end

function NpcShop:onExit()
    self.m_table = nil
    Utils:FreeTable(self.m_npcDatas)
    self.m_npcDatas = nil
end

function NpcShop:getDataList()
    if self.m_npcDatas == nil then
        return {}
    end
    return self.m_npcDatas.normalGoods
end

function NpcShop:getDataListCount()
    return #(self:getDataList())
end

function NpcShop:updateData(msg)
    Utils:FreeTable(self.m_npcDatas)
    self.m_npcDatas = nil
    self.m_npcDatas = msg
end

function NpcShop:setItem(item, data, index, itemIndex, bVisible)
    if item == nil then
        return
    end

    local goodData = data.m_item
    if goodData == nil then
        return
    end

    local pNameText = item:getChildByName("Name")
    pNameText:setString(goodData.m_name)

    local itemValue = {
        itemData = data,
        isShowQualityBg = false,
        isShowNum = false
    }

    self.m_table.m_pItemLists[tostring(itemIndex)]:UpdateItem(itemValue)

    local moneyBgSp = item:getChildByName("bg_Price")
    local moneyIcon = moneyBgSp:getChildByName("Icon")
    local str = AppDef:GetMoneyIcon( data.m_priceType )
    if #str > 0 then
        moneyIcon:loadTexture(str, ccui.TextureResType.plistType)
    end

    moneyBgSp:getChildByName("Value"):setString(tostring(data.m_price))

    item:getChildByName("Explain"):setVisible(false)

    item:getChildByName("Tag"):setVisible(false)
end

function NpcShop:selectItem(index)
    local datas = self:getDataList()
    local data = datas[index]
    if data == nil then
        return
    end
    local sData = ShopSelectInfo:New()
    sData.m_name = (data.m_item and {data.m_item.name} or "")[1]
    sData.m_desc = (data.m_item and {data.m_item.des} or "")[1]
    sData.m_id = data.m_id
    sData.m_count = 1
    sData.m_unitCount = 1
    sData.m_price = data.m_price
    if data.m_priceType == 1 then
        sData.m_priceType = AppDef.MoneyType.JINBI
    elseif data.m_priceType == 2 then
        sData.m_priceType = AppDef.MoneyType.YUANBAO
    end
    sData.m_isShowHave = true
    sData.m_isChangeCount = true

    self.m_table:selectItem(sData)
end

function NpcShop:setDataSource(tb)
    self.m_table = tb
end

function NpcShop:findGoodByID(id)
    local datas = self:getDataList()
    for i=1,#datas do
        if datas[i].m_id == id then
            return i
        end
    end
    return nil
end

function NpcShop:buy(id, count)
    local index = self:findGoodByID(id)
    if index ~= nil then
        LuaNetSendMsg:QuerySellOrBuyInfo(0, index-1, count)
    end
end

function NpcShop:getMoneyType()
    return AppDef.MoneyType.JINBI
end

function NpcShop:getShopType()
    return ShopDef.MK_TP.NPC
end

function NpcShop:getIsShowHave()
    return true
end

function NpcShop:getCanChangeCount()
    return true
end

function NpcShop:updateItemCount( index, count )
end

return NpcShop