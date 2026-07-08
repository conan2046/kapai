LFastShopDataMgr = LUIBase:New()
LFastShopDataMgr.__index = LFastShopDataMgr

local targetPlatform = cc.Application:getInstance():getTargetPlatform()

-----------------------------------
function LFastShopDataMgr:RegistMsgs()
    self.msgIds = 
    {
        LUIShopEvent.ReloadShopData,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function LFastShopDataMgr:ProcessEvent(msg)
    if msg.msgId == LUIShopEvent.ReloadShopData then

        -- dump(msg.value.normalGoods, "ReloadShopData ---")
        -- dump(msg.value.limitedGoods, "ProcessEvent +++++")
        -- print("shop type =", msg.value.shopType)

        if msg.value.normalGoods and msg.value.shopType == 1 then
            self.m_pNormalShopData = msg.value.normalGoods
        end

        if msg.value.normalGoods and msg.value.shopType == 4 then
            self.m_bdShopData = msg.value.normalGoods
        end

    end
end

function LFastShopDataMgr:Init()
	self.m_pNormalShopData = {}
    self.m_bdShopData = {}
    self.m_curUseMattrial = AppDef.upgradeMaterial_ID.FM_funcion_none
	self:RegistMsgs()
end
function LFastShopDataMgr:ShowNeedBuyMaterialNEW(needBuyList, upgradeType,isbuy,isFirst)--isFirst 当前升级材料是否是一级
  
    if Utils:IsInGuide() then
        return
    end
    if needBuyList == nil then
        return
    end
    if upgradeType == nil then
        self.m_curUseMattrial = AppDef.upgradeMaterial_ID.FM_funcion_none
    else
        self.m_curUseMattrial = upgradeType 
    end
  
    local shopCanBuyList = {}
    local shopNoBuyList = {}
    local function addData(pCItem_arg, data_arg, useType)
        -- body
        local item1 = LUpgradeLackItem:New()
        item1.id = data_arg.id
        item1.name = pCItem_arg:Getm_name()
        item1.num = data_arg.num
        if useType == 3 then
            item1.price = self:getItemBdPrice(data_arg.id)
        else
            item1.price = self:getItemPrice(data_arg.id)
        end
        
        item1.quality = pCItem_arg.m_quality
        table.insert(shopCanBuyList, item1)
    end

    local bdYB = LRoleDataMgr.MyHeroInfo:GetDetailData().BindTongBao
    local price = self:getAllItemBdPrice(needBuyList)
    local useType = 1
    if self:AllCanBuyFromBDShop(needBuyList) and bdYB >= price then
        useType = 3
        for i=1, #needBuyList do
            local data = needBuyList[i]
            local pCItem = LItemMgr:getItem(data.id)
            if pCItem and self:isCanBuyFromBdShop(data.id) then
                addData(pCItem, data, useType)
            else
                table.insert(shopNoBuyList, data)
            end
        end
    else
        useType = 1
        for i=1, #needBuyList do
            local data = needBuyList[i]
            local pCItem = LItemMgr:getItem(data.id)
            if pCItem and self:isCanBuyFromShop(data.id) then
                addData(pCItem, data, useType)
            else
                table.insert(shopNoBuyList, data)
            end
        end
    end

   --要改
    local function okEvent()
        --local myPackCapacity =LRoleDataMgr.Equip:GetPackSurplusNum()
        LuaNetSendMsg:QuerySortPackage()
        local needByTimes = 1
        for i=1,#shopCanBuyList do
            local id = shopCanBuyList[i].id
            local count = shopCanBuyList[i].num
            --pageType 1 元宝购买 4 绑元购买
            local pageType = 1
            if useType == 3 then
                pageType = 4
            end
       
            -- if myPackCapacity<1  then
            --     Utils:ShowScrollTips(GUITips.RSI_PackCapacity_MSG1)
            --     return
            -- end
            local tempNum=shopCanBuyList[i].num      
            if shopCanBuyList[i].num>200 then
              while(true) do
                if tempNum<=200 then
                  local num = LRoleDataMgr.Equip:CountItemNumById(shopCanBuyList[i].id)
                    if tempNum+num>200 or num==0 then   
                      needByTimes=needByTimes+1  
                    end                                                           
                    break
                end
                needByTimes=needByTimes+1   
                tempNum=tempNum-200 

              end             
            else
               if tempNum+ math.fmod(LRoleDataMgr.Equip:CountItemNumById(shopCanBuyList[i].id),200)>200 then 
                  needByTimes=needByTimes+1  
               end                                                                       
            end
          
             if --[[needByTimes>myPackCapacity and]] (isFirst==nil or isFirst==false)  then
                Utils:ShowScrollTips(GUITips.RSI_PackCapacity_MSG1)
                return
             end
             if shopCanBuyList[i].num>200 then
              while(true) do
                if shopCanBuyList[i].num<=200 then
                    LuaNetSendMsg:QueryMarketInfo(2, pageType, id,shopCanBuyList[i].num)            
                    break
                end
                shopCanBuyList[i].num=shopCanBuyList[i].num-200
                LuaNetSendMsg:QueryMarketInfo(2, pageType, id,200)
              end             
            else
              LuaNetSendMsg:QueryMarketInfo(2, pageType, id, count)
            end
        end

    end

    local function cancelEvent()
    -- body
    end
    local Tempdata={}
    Tempdata.Id=needBuyList[1].CurId
    Tempdata.BuyList=shopCanBuyList
    if #shopCanBuyList > 0 then

        if isbuy~=nil and isbuy==true then
        
            okEvent()
        else
          Utils:ShowLackItemUINew(Tempdata, okEvent, cancelEvent, useType)
        end
    else
        if #shopNoBuyList > 0 then
            if shopNoBuyList[1].id == AppDef.AwrdItem.AWRD_ITEM_COIN or shopNoBuyList[1].id == AppDef.AwrdItem.AWRD_ITEM_SHENPO then
                Utils:ShowGoldTips(shopNoBuyList[1].id)
            else
                local pCItem = LItemMgr:getItem(shopNoBuyList[1].id)
                if pCItem then
                    local item = 
                    {
                        itemType = "CItem",
                        itemData = pCItem,
                    }
                    LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowItemInfo, item)
                    LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
                end
            end
        end
    end
end


function LFastShopDataMgr:ShowNeedBuyMaterial(needBuyList, upgradeType)
    -- body
    --引导时不弹出
    if Utils:IsInGuide() then
        return
    end

    if needBuyList == nil then
        return
    end

    if upgradeType == nil then
        self.m_curUseMattrial = AppDef.upgradeMaterial_ID.FM_funcion_none
    else
        self.m_curUseMattrial = upgradeType 
    end

    local shopCanBuyList = {}
    local shopNoBuyList = {}

    local function addData(pCItem_arg, data_arg, useType)
        -- body
        local item1 = LUpgradeLackItem:New()
        item1.id = data_arg.id
        item1.name = pCItem_arg:Getm_name()
        item1.num = data_arg.num
        if useType == 3 then
            item1.price = self:getItemBdPrice(data_arg.id)
        else
            item1.price = self:getItemPrice(data_arg.id)
        end
        
        item1.quality = pCItem_arg.m_quality
        table.insert(shopCanBuyList, item1)
    end

    local bdYB = LRoleDataMgr.MyHeroInfo:GetDetailData().BindTongBao
    local price = self:getAllItemBdPrice(needBuyList)
    local useType = 1
    if self:AllCanBuyFromBDShop(needBuyList) and bdYB >= price then
        useType = 3
        for i=1, #needBuyList do
            local data = needBuyList[i]
            local pCItem = LItemMgr:getItem(data.id)
            if pCItem and self:isCanBuyFromBdShop(data.id) then
                addData(pCItem, data, useType)
            else
                table.insert(shopNoBuyList, data)
            end
        end
    else
        useType = 1
        for i=1, #needBuyList do
            local data = needBuyList[i]
            local pCItem = LItemMgr:getItem(data.id)
            if pCItem and self:isCanBuyFromShop(data.id) then
                addData(pCItem, data, useType)
            else
                table.insert(shopNoBuyList, data)
            end
        end
    end


    local function okEvent()
    -- body
	    for i=1,#shopCanBuyList do
	    	local id = shopCanBuyList[i].id
	    	local count = shopCanBuyList[i].num
            --pageType 1 元宝购买 4 绑元购买
            local pageType = 1
            if useType == 3 then
                pageType = 4
            end
	    	LuaNetSendMsg:QueryMarketInfo(2, pageType, id, count)
	    end
    end

    local function cancelEvent()
    -- body
    end

    if #shopCanBuyList > 0 then
        Utils:ShowLackItemUI(shopCanBuyList, okEvent, cancelEvent, useType)
    else
    --    dump(shopNoBuyList, "from the world")
        if #shopNoBuyList > 0 then
            if shopNoBuyList[1].id == AppDef.AwrdItem.AWRD_ITEM_COIN or shopNoBuyList[1].id == AppDef.AwrdItem.AWRD_ITEM_SHENPO then
                Utils:ShowGoldTips(shopNoBuyList[1].id)
            else
                local pCItem = LItemMgr:getItem(shopNoBuyList[1].id)
                if pCItem then
                    local item = 
                    {
                        itemType = "CItem",
                        itemData = pCItem,
                    }
                    LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowItemInfo, item)
                    LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
                end
            end
        end
    end

end

function LFastShopDataMgr:isCanBuyFromShop(id)
    -- body
    --通过item表来源判断是否可以从商店购买
    for i=1, #self.m_pNormalShopData do
        if self.m_pNormalShopData[i].id == id then
            return true
        end
    end
    return false
end

function LFastShopDataMgr:isCanBuyFromBdShop(id)
    -- body
    --通过item表来源判断是否可以从绑元商店购买
    for i=1, #self.m_bdShopData do
        if self.m_bdShopData[i].id == id then
            return true
        end
    end
    return false
end

function LFastShopDataMgr:AllCanBuyFromBDShop(list)
    -- body
    for i=1, #list do
        if self:isCanBuyFromBdShop(list[i].id) then
            return true
        end
    end
    return false
end

function LFastShopDataMgr:getAllItemBdPrice(list)
    -- body
    local totalCost = 0
    for i=1, #list do
        local data = list[i]
        local price = self:getItemBdPrice(data.id)
--        print("getAllItemBdPrice =", price)
        totalCost = totalCost + price * data.num
    end
    return totalCost
end

function LFastShopDataMgr:getItemPrice(id)
	-- body
	for i=1, #self.m_pNormalShopData do
        if self.m_pNormalShopData[i].id == id then
            return self.m_pNormalShopData[i].price
        end
    end
    return 0
end

function LFastShopDataMgr:getItemBdPrice(id)
    -- body
    for i=1, #self.m_bdShopData do
        if self.m_bdShopData[i].id == id then
            return self.m_bdShopData[i].price
        end
    end
    return 0
end


LFastShopDataMgr:Init()