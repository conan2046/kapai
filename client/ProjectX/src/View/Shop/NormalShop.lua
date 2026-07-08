local ShopDef = require("View.Shop.ShopDef")


local NormalShop = LUIBase:New()
NormalShop.__index = NormalShop

local SECNUM_THREE = 259200

-- -----------------------------------
function NormalShop:New(m_table)
    local o = {}
    setmetatable(o, NormalShop)
    o:Init(m_table)
    return o
end

-- -----------------------------------
function NormalShop:Init(m_table)
    self.m_datas = {}
    self.m_table = nil
    self.m_table = m_table
end

function NormalShop:onExit()
    self:Destory()
    Utils:FreeTable(self.m_datas)
    self.m_datas = nil
    self.m_table = nil
end

function NormalShop:getDataList()
    return self.m_datas.normalGoods.itemList
end

function NormalShop:getDataListCount()
    if self.m_datas.normalGoods == nil then
        return 0
    end
    return #(self:getDataList())
end

function NormalShop:updateData(msg)
    Utils:FreeTable(self.m_datas)
    self.m_datas = nil

    self.m_datas = msg

    --初始化数据
    local list = self:getDataList()
    for i=1, #list do
        local data = list[i]
        print("NormalShop:updateData ==> data.id ", data.id)
        local configData = JsonConfig.m_ShopInfo.getDefByID(data.id)
        local discountIndex = data.buyTimes + 1
        print("updateData =====>", discountIndex)
        if discountIndex > #configData.price_real then
            discountIndex = #configData.price_real
        end
        local value = configData.price_real[discountIndex]
        data.rate = value / 100
        data.OriginalPrice = configData.price[1][3]
        data.price =  data.rate * data.OriginalPrice
        data.itemId = configData.itemid[1]
        data.num = configData.itemid[3]
        data.pricePic =  configData.price[1][1]
        -- -1表示没有购买限制
        data.leftTimes = -1
        if #configData.count > 1 then
            data.leftTimes = configData.count[2] - data.buyTimes
        end
        -- print("getDataListCount == data.pricePic", data.pricePic, data.leftTimes, #configData.count)
        if data.itemId == AppDef.RewardItem.RD_ITEM_FABAO then
            local itemConfigData = JsonConfig.m_faBaoConfig.getDefByID(configData.itemid[2])
            if itemConfigData then
                data.name = itemConfigData.name
                data.des = itemConfigData.des
            end
        else
            local itemConfigData = JsonConfig.m_Item.getDefByID(data.itemId)
            if itemConfigData then
                data.name = itemConfigData.name
                data.des = itemConfigData.des
            end
        end
        
    end

    -- dump(self.m_datas.itemList, "updateData ===== 1111>")
end


function NormalShop:setItem(item, data, index, itemIndex, bVisible)

    -- dump(data, "setItem ==== 111>")

    local moneyBgSp = item:getChildByName("bg_Price")
    moneyBgSp:getChildByName("Value"):setString(data.price or 0)

    local Discount = item:getChildByName("Discount")
    local value = Discount:getChildByName("Value")
    if data.rate >= 1 then
        Discount:setVisible(false)
    else
        Discount:setVisible(true)
        value:setString(string.format(GUITips.RSI_DISCOUNTSHOP_DISCOUNT, data.rate * 10))
    end
    

    local pNameText = item:getChildByName("Name")
    -- dump(data, "NormalShop:setItem ===>")
    pNameText:setString(data.name)

    if itemIndex then
        local pItem = self.m_table.m_pItemLists[tostring(itemIndex)]
        if pItem and pItem.m_pNode then
            -- dump(data, "setItem 111 =====>")
            if data.itemId ==  AppDef.RewardItem.RD_ITEM_FABAO then
                local shopConfig = JsonConfig.m_ShopInfo.getDefByID(data.id)
                if shopConfig then
                    print("tableview setItem === 11111111111111111 ==>", shopConfig.itemid[2], shopConfig.itemid[3])
                    Utils:GetFaBaoCellValue(pItem.m_pNode, nil, shopConfig.itemid[2], 0, true, shopConfig.itemid[3], 0, 0, true, true)
                end 
            else
                Utils:GetItemCellValue(pItem.m_pNode, 0, data.itemId, true, true, data.num, pItem, false, true)
            end
        end
    end

    local moneyIcon = moneyBgSp:getChildByName("Icon")
    local str = AppDef:GetMoneyIconById(data.pricePic)
    moneyIcon:loadTexture(str, ccui.TextureResType.plistType)

    item:getChildByName("Explain"):setVisible(false)

    item:getChildByName("Tag"):setVisible(false)

    local tag = item:getChildByName("Tag")
    tag:setVisible(false)
    if data.leftTimes == 0 then
        tag:setVisible(true)
    end

    local CostPrice = item:getChildByName("CostPrice")
    if data.rate >= 1 then
        CostPrice:setVisible(false)
    else
        CostPrice:setVisible(true)
        CostPrice:setString(string.format(GUITips.RSI_DISCOUNTSHOP_PREPRICE, data.OriginalPrice))
    end
    
end

function NormalShop:selectItem(index)
    -- print("NormalShop:selectItem ===>", index)
    local data = self.m_datas.normalGoods.itemList[index]
    -- dump(data, "selectItem =====>")

    local sData = ShopSelectInfo:New()
    sData.m_name = data.name
    sData.m_desc = data.des
    sData.m_id = data.id
    sData.m_count = 1
    sData.m_unitCount = 1
    sData.m_maxCount = data.leftTimes
    sData.m_price = data.price
    sData.m_isShowHave = true
    sData.m_isChangeCount = true
    sData.m_pid = 0
    sData.m_pstar = 0
    sData.m_index = index
    sData.m_leftTimes = data.leftTimes
    sData.m_priceType = AppDef.MoneyType.YUANBAO
    sData.buyTimes = data.buyTimes
    self.m_table:selectItem(sData)
end

function NormalShop:setDataSource(tb)
    self.m_table = nil
    self.m_table = tb
end

function NormalShop:buy(index, count, pid, pstar)
    local pageType = self:getShopType()
    if pageType ~= nil then
        -- LuaNetSendMsg:QueryMarketInfo(2, pageType, index, count, nil, pid, pstar)
        print('NormalShop:buy ===>', index, count)
        LuaNetSendMsg:QueryBuyProd(2, pageType, index, count)
    end
end

function NormalShop:getMoneyType()
    return AppDef.MoneyType.YUANBAO
end

function NormalShop:getShopType()
    return ShopDef.KP_TYPE.SHANGCHENG
end

function NormalShop:getIsShowHave()
    return true
end

function NormalShop:getCanChangeCount()
    return true
end

function NormalShop:updateItemCount( index, count )
end

return NormalShop