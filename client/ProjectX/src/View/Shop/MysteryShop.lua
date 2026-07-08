local ShopDef = require("View.Shop.ShopDef")

local TimerLabelUI = require("View.Common.TimerLabelUI")

local MysteryShop = LUIBase:New()
MysteryShop.__index = MysteryShop

-- -----------------------------------
function MysteryShop:New(_table, rootUI)
    local o = {}
    setmetatable(o, MysteryShop)
    if rootUI then
        o:Init(_table, rootUI)
    end
    return o
end

-- -----------------------------------
function MysteryShop:Init(_table, rootUI)
    self.m_table = _table
    self.m_pRootUI = rootUI
    self.m_priceType = self:getMoneyType()

    self.m_mysteryInfo = {}
    self.m_timerLabel = nil

    if self.m_pRootUI then
        self:InitUIControl()
    end
end

function MysteryShop:onExit()
    self:Destory()
    self.m_table = nil
    self.m_pRootUI = nil
    self.m_priceType = nil
    Utils:FreeTable(self.m_mysteryInfo)
    self.m_mysteryInfo = nil
    if self.m_timerLabel then
        self.m_timerLabel:Destory()
        self.m_timerLabel = nil
    end
end

function MysteryShop:InitUIControl()
    self:setTimerLabel()
    self:setShenMiFlushCallback()
end

function MysteryShop:setTimerLabel()
    local pCountDown = self.m_pRootUI:getChildByName("CountDown")
    self:setLabel(pCountDown:getChildByName("Value"))
end

function MysteryShop:flushCallback(sender)
    LuaNetSendMsg:QueryMarketInfo(8, 0)
end

function MysteryShop:setShenMiFlushCallback()
    local flushBtn = self.m_pRootUI:getChildByName("btn_Refresh")
    flushBtn:addClickEventListener(handler(self, MysteryShop.flushCallback))
		self:MarkIntaractCObj(flushBtn)
end

function MysteryShop:setLabel(label)
    if label ~= nil then
        self.m_timerLabel = TimerLabelUI:New(label, nil, nil)
    end
end

function MysteryShop:setTimer(leftTime)
    if self.m_timerLabel ~= nil then
        self.m_timerLabel:set(leftTime, handler(self, MysteryShop.flushCallback))
        self.m_timerLabel:start()
    end
end

function MysteryShop:getDataList()
    if self.m_mysteryInfo == nil then
        return {}
    end
    return self.m_mysteryInfo.ItemData
end

function MysteryShop:getDataListCount()
    if self.m_mysteryInfo == nil then
        return 0
    end
    return self.m_mysteryInfo.num
end

function MysteryShop:updateData(msg)
    local info = msg.normalGoods
    if info.ItemData == nil then
        return
    end
    self:setTimer(info.time)

    for i=1,#info.ItemData do
        local data = info.ItemData[i]
        if data.vipLimit <= LRoleDataMgr.MyHeroInfo.vipLevel and info.ItemData[i].itemId then
            local itemBaseData = LItemMgr:getItem(data.itemId)
            if itemBaseData ~= nil then
                local pItem = LPItem:New(itemBaseData.id)
                pItem.m_num = data.itemNum
                pItem.m_item = itemBaseData
                info.ItemData[i].itemData = pItem
            end
        end
    end
    Utils:FreeTable(self.m_mysteryInfo)
    self.m_mysteryInfo = nil
    self.m_mysteryInfo = info
end

function MysteryShop:setPetEquipItem(item, data, itemIndex)
    if item == nil or data == nil then
        return
    end
    local info = LDataConstMgr:GetPetEquipCfgData(data.petEquipId)
    if info == nil then
        return
    end
    local pNameText = item:getChildByName("Name")
    local _ = pNameText and pNameText:setString(info.name)

    if itemIndex then
        local pItem = self.m_table.m_pItemLists[tostring(itemIndex)]
        if pItem == nil or pItem.m_pNode == nil then
            return
        end
        Utils:GetItemCellValue(pItem.m_pNode, 0, data.itemId, true, true, data.itemNum, pItem, nil, nil, data.petEquipId, data.petEquipStar)
    end
end

function MysteryShop:setItem(item, data, index, itemIndex, bVisible)
    local pNameText = item:getChildByName("Name")
    local tipsText = item:getChildByName("Explain")
    local moneyBgSp = item:getChildByName("bg_Price")
    local bgIcon = item:getChildByName("bg_icon")
    local icon = bgIcon:getChildByName("Icon")
    if data.vipLimit > LRoleDataMgr.MyHeroInfo.vipLevel then
        pNameText:setString(string.format(GUITips.RSI_ML_TIP7, data.vipLimit))
        tipsText:setVisible(true)
        moneyBgSp:setVisible(false)
        self.m_table.m_pItemLists[tostring(itemIndex)]:UpdateItem(nil)

        icon:setVisible(true)

        item:getChildByName("Tag"):setVisible(false)
    else
        tipsText:setVisible(false)
        icon:setVisible(false)
        --售完
        item:getChildByName("Tag"):setVisible(data.itemNum == 0 and data.id > 0)

        moneyBgSp:setVisible(true)
        local moneyIcon = moneyBgSp:getChildByName("Icon")
        local str = AppDef:GetMoneyIcon( self:getMoneyType() )
        moneyIcon:loadTexture(str, ccui.TextureResType.plistType)
        moneyBgSp:getChildByName("Value"):setString(tostring(data.price))

        if data.itemId == AppDef.AwrdItem.AWRD_ITEM_PETEQUIP then
            self:setPetEquipItem(item, data, itemIndex)
            return
        end
        
        local goodData = data.itemData.m_item
        pNameText:setString(goodData.m_name)
        
        if itemIndex then
            local pItem = self.m_table.m_pItemLists[tostring(itemIndex)]
            if pItem and pItem.m_pNode then
                Utils:GetItemCellValue(pItem.m_pNode, 0, data.itemId, true, true, data.itemData.m_num, pItem)
            end
        end
    end
end

function MysteryShop:selectItem(index)
    local datas = self:getDataList()
    local data = datas[index]
    if data.vipLimit > LRoleDataMgr.MyHeroInfo.vipLevel then
        self:showMsgBox(data.vipLimit, index - 1)
        self.m_table:reset2()
        self.m_table:selectItem(nil)
    else
        local sData = ShopSelectInfo:New()
        if data.itemId == AppDef.AwrdItem.AWRD_ITEM_PETEQUIP then
            local info = LDataConstMgr:GetPetEquipCfgData(data.petEquipId)
            if info then
                sData.m_name = info.name
                sData.m_desc = info.unKnowDesc
                sData.m_count = data.itemNum
            else
                sData.m_name = "查找不到-"..data.petEquipId
                sData.m_desc = ""
            end
        else
            if data.itemData and data.itemData.m_item then
                sData.m_name = data.itemData.m_item.name or ""
                sData.m_desc = data.itemData.m_item.des or ""
                sData.m_count = data.itemData.m_num or 0
            else
                sData.m_name = ""
                sData.m_desc = ""
                sData.m_count = 0
            end
        end
        sData.m_id = data.id
        sData.m_unitCount = 0
        sData.m_price = data.price
        sData.m_priceType = self.m_priceType
        sData.m_isShowHave = true
        sData.m_isChangeCount = false
        sData.m_pid = data.petEquipId
        sData.m_pstar = data.petEquipStar

        self.m_table:selectItem(sData)
    end
end

function MysteryShop:setDataSource(tb)
    self.m_table = nil
    self.m_table = tb
    self:setShenMiFlushCallback()
end

function MysteryShop:showMsgBox(vipLimit, ind)
    local vec = {700,701,702,703,704,705,706,707,708}
    local index = 700 + ind
    if Utils:containValue(vec, index) then
        local function OKCallback()
            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Shop.ShopUI")
            self:SendMsg(LGameMsg.m_initUIMsg)

            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Vip.VipMainUI",AppDef.UIType.FirstClassLayer, vipLimit)
            self:SendMsg(LGameMsg.m_initUIMsg)
        end
        local function Cancelback() end
        local msgData = {
            okCallback = OKCallback,
            cancelCallback = Cancelback,
            desc = string.format("%s[c3]%s%d[/c],%s", GUITips.RIS_LEFTUI_MSG27, GUITips.RSI_CHAT_MSG7, vipLimit, GUITips.RIS_LEFTUI_MSG28),
        }
        Utils:SendMsg(LUIMsgBoxEvent.ShowMsgBox, msgData)
    end
end

function MysteryShop:findGoodByID(id, pid, pstar)
    local datas = self:getDataList()
    for i=1,#datas do
        if datas[i].id == id and datas[i].petEquipId == pid and datas[i].petEquipStar == pstar then
            return i-1
        end
    end
    return nil
end

function MysteryShop:buy(id, count, pid, pstar)
    local index = self:findGoodByID(id, pid, pstar)
    if index then
        LuaNetSendMsg:QueryMarketInfo(7, index, id, 0)
    end
end

function MysteryShop:getMoneyType()
    return AppDef.MoneyType.YUANBAO
end

function MysteryShop:getShopType()
    return ShopDef.MK_TP.MYSTERY
end

function MysteryShop:getIsShowHave()
    return true
end

function MysteryShop:getCanChangeCount()
    return false
end

function MysteryShop:updateItemCount( index, count )
    index = index + 1
    local datas = self:getDataList()
    if datas[index] then
        if datas[index].itemData then
          datas[index].itemData.m_num = count
        end
        
        datas[index].itemNum = count
    end
end

function MysteryShop:Reset()
    local _ = self.m_timerLabel and self.m_timerLabel:stop()
end

return MysteryShop