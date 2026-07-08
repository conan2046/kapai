--[[
折扣商店
]]

local DiscountShop = LUIBase:New()
DiscountShop.__index = DiscountShop

function DiscountShop:New()
	local o = LUIBase:New()
	setmetatable(o,DiscountShop)	
    o:Init()
	return o
end

--[[
注册消息
]]
function DiscountShop:RegistMsgs()
    self.msgIds = 
    {
        LUIShopEvent.UpdateDiscountShop,
        LUIShopEvent.UpdateCountByItemId,
    }
    self:RegistSelf(self,self.msgIds)
end

function DiscountShop:ProcessEvent(msg)
   if msg.msgId == LUIShopEvent.UpdateDiscountShop then
       self:refrashUI(msg.value)
   end

   if msg.msgId == LUIShopEvent.UpdateCountByItemId then
       self:updateUIByID(msg.value)
   end
end

function DiscountShop:Init()

    self:RegistMsgs()
    --ShopLayer
    self.m_pUILayer = cc.CSLoader:createNode("csd/DiscountShopLayer.csb")
    self._bg = cc.CSLoader:createNode("csd/ActivityLevelLayer.csb")
    self._bg:setPosition(cc.p(0, 0))
    self.m_pUILayer:addChild(self._bg)


    self.m_pUILayer:setContentSize(AppDef.frameSize)

    self._bg:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
    ccui.Helper:doLayout(self._bg)
    
    self:InitData()
    self:AddTouchEvt();

    LuaNetSendMsg:QueryMarketInfo(4,0);

end

function DiscountShop:InitData()
    
    --title
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.RSI_DISCOUNTSHOP_TITLE)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    
    local panel =  self.m_pUILayer:getChildByName("ShopUI")
    panel:setLocalZOrder(1)
    self.m_pCell = panel:getChildByName("Item")
    self.SelcetItem = nil;
    self.m_pCell:setVisible(false)

    self._DiscountDesc = panel:getChildByName("DiscountDesc")
    self._DiscountDesc:setVisible(true)

    self._itemDesc = self._DiscountDesc:getChildByName("desc")
    self._buyTimes = self._DiscountDesc:getChildByName("ItemValue")
    self._ItemName = self._buyTimes:getChildByName("ItemName")

    self._IconBg = {}
    local _IconBg_1 = self._DiscountDesc:getChildByName("IconList"):getChildByName("IconBg_1")
    table.insert(self._IconBg, _IconBg_1);
    local _IconBg_2 = self._DiscountDesc:getChildByName("IconList"):getChildByName("IconBg_2")
    table.insert(self._IconBg, _IconBg_2);
    local _IconBg_3 = self._DiscountDesc:getChildByName("IconList"):getChildByName("IconBg_3")
    table.insert(self._IconBg, _IconBg_3);

    self._MysticalShop = panel:getChildByName("MysticalShop")
    self._MysticalShop:setSwallowTouches(false)
    self._ownValue = self._MysticalShop:getChildByName("bg_Own"):getChildByName("Value")
    self._ownValue:setString(LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao())

    local mysticalShop = self._MysticalShop
    local countDown = mysticalShop:getChildByName("CountDown")
    countDown:setVisible(false)

    self.m_pTvPanel = mysticalShop:getChildByName("List")

    local DiscountTips = mysticalShop:getChildByName("DiscountTips")
    DiscountTips:setVisible(true)
    self._updateTipsDec = DiscountTips:getChildByName("Text")
    self._updateTips = Utils:CreateColorText2(DiscountTips, self._updateTipsDec)

    self:InitShopTabView();

    self._curSelectIndex = 1
end 

function DiscountShop:AddTouchEvt()
    local bgPanel = self._bg:getChildByName("Panel")
    local bg = bgPanel:getChildByName("Bg")
--    bg:setSwallowTouches(false)
    local closeBtn = bg:getChildByName("CloseBtn")
    local function closeEvent( sender )
        -- body
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Shop.DiscountShop")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    closeBtn:addClickEventListener(closeEvent)
	self:MarkIntaractCObj(closeBtn)
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    local tabValues = 
    {
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.AddTabBtn, tabValues)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local buyBtn = self._DiscountDesc:getChildByName("btn_Buy")
    self._DiscountDesc:setSwallowTouches(false)
    local function OKCallbackToRecharge()
        Utils:OpenRechargeMainUI()
    end

    local function OKCallback()
    end

    local function OnBuyButtonClick(sender)

        if LRoleDataMgr.m_firstRechargeState ~= 1 then
            Utils:ShowDialogOKCancel(GUITips.RSI_UILABEL_SHOUCHONG2, OKCallback)
            return;
        end

        --购买元宝不足判断
        local data = self._DiscountShopInfo.shopdata[self._curSelectIndex]

        --至尊等级不足
        local userVip = LRoleDataMgr.MyHeroInfo.vipLevel
        if data.vip > userVip then
            local strMsg = string.format(GUITips.RIS_LEFTUI_MSG56, data.vip)
            Utils:ShowDialogOKCancel(strMsg, OKCallbackToRecharge)
            return
        end

        --该礼包售完判断
        if userVip >= 15 and data.canBuyNum == 0  then
            Utils:ShowDialogOKCancel(GUITips.RSI_DSL_SP_TIP3, OKCallback)
            return
        end

        local myTongo = LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao()
        if data.curPrice > myTongo then
            Utils:ShowDialogOKCancel(GUITips.RSI_GL_CPT_TIP6, OKCallbackToRecharge)
            return
        end

--购买
--        --print("LuaNetSendMsg:QueryMarketInfo", data.id)
        LuaNetSendMsg:QueryMarketInfo(5, data.id);
    end
    buyBtn:addClickEventListener(OnBuyButtonClick)
	self:MarkIntaractCObj(buyBtn)

    local btn_Rcharge = self._DiscountDesc:getChildByName("btn_Rcharge")
    local function toRechage(sender)
        Utils:OpenRechargeMainUI()
    end
    btn_Rcharge:addClickEventListener(toRechage)
	self:MarkIntaractCObj(btn_Rcharge)
end

function DiscountShop:onExit()
    self.m_pUILayer = nil
    self:UnRoundSchedule()
    self:Destory();
end

function DiscountShop:InitShopTabView(panel)
    
    local tableView = cc.TableView:create(self.m_pTvPanel:getContentSize())
    --print("width = ".. self.m_pTvPanel:getContentSize().width .. "height = " .. self.m_pTvPanel:getContentSize().height);
    --print("width = ".. tableView:getContentSize().width .. "height = " .. tableView:getContentSize().height);
    tableView:setContentSize(self.m_pTvPanel:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(cc.p(0, 0))
    tableView:setPosition(cc.p(0, 0))
    tableView:setDelegate()
    tableView:setSwallowsTouches(true)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.m_pTvPanel:addChild(tableView)

    local function tableCellTouched(sender,cell)
        --print("tableCellTouched".. cell:getIdx())
        self:GoodsTableCellTouched(cell)
    end

    local function cellSizeForTable(sender,idx)
        local width = self.m_pCell:getContentSize().width
        local height = self.m_pCell:getContentSize().height
--        --print("cellSizeForTable width = "..width .. " cellSizeForTable height = ",height)
        return width, height
    end

    local function tableCellAtIndex(sender, idx)
        --print("cellSizeForTable idx = ".. idx )
        return self:GoodsTableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        local size = 0
        if #self._DiscountShopInfo then
            if #self._DiscountShopInfo.shopdata % 3 == 0 then
                size = #self._DiscountShopInfo.shopdata / 3
            else
                size = math.floor(#self._DiscountShopInfo.shopdata / 3) + 1 
            end
        end
        return size
    end

    local function scrollViewDisScroll(view)
        self.m_isDragging = view:isDragging()
    end

    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量

    tableView:registerScriptHandler(scrollViewDisScroll, cc.SCROLLVIEW_SCRIPT_SCROLL)
    --tableView:reloadData()
    self.m_pFaceTableView = tableView
--    --print("DiscountShop:InitFaceTabView")
end


function DiscountShop:DefaultUI(  )
    -- body
    if self._DiscountShopInfo == nil then
        return
    end

    if #self._DiscountShopInfo.shopdata <= 0 then
        return
    end

    local data = self._DiscountShopInfo.shopdata[self._curSelectIndex]        
    self._itemDesc:setString(data.desc)

    local strLeftNum = string.format(GUITips.RSI_DISCOUNT_ITEM_LEFTNUM, data.canBuyNum)
    self._buyTimes:setString(strLeftNum)

    self._ItemName:setString(data.name)



    for  j = 1, data.awardCount do
        local itemInfo = data.itemInfos[j]
        self._IconBg[j]:removeAllChildren()
        if itemInfo.awardType == 2 then
            Utils:ShowPetHeadImg(self._IconBg[j], itemInfo.petInfo.id, self._IconBg[j]:getParent(), true, true)
        else
            Utils:GetItemCellValue(self._IconBg[j], 0, itemInfo.itemId, true, true, itemInfo.num, nil, true)
        end
    end

end

--点击选中处理
function DiscountShop:GoodsTableCellTouched(cell)
    
    local ind = cell:getIdx()
    local cellChild = cell:getChildByTag(123)
    --print("tableview touched " ..ind.." ") 
end 


function DiscountShop:GoodsTableCellAtIndex(sender, idx)

    local function ItemGridTouched(sender)--商品点击
        if self.m_isDragging then
            return
        end
        local ind = sender:getTag()
        --print("GoodsTableCellAtIndex ind", ind)
        self._curSelectIndex = ind
        if self.SelcetItem ~= nil then
            self.SelcetItem:getChildByName("Choose"):setVisible(false)
        end
         
         sender:getChildByName("Choose"):setVisible(true)

        self.SelcetItem = sender;

        local data = self._DiscountShopInfo.shopdata[ind]        
        self._itemDesc:setString(data.desc)

        local strLeftNum = string.format(GUITips.RSI_DISCOUNT_ITEM_LEFTNUM, data.canBuyNum)
        self._buyTimes:setString(strLeftNum)
        self._ItemName:setString(data.name)

        for i = 1, #self._IconBg do
            self._IconBg[i]:removeAllChildren()
        end

        for  j = 1, data.awardCount do
            local itemInfo = data.itemInfos[j]
            if itemInfo.awardType == 2 then
                Utils:ShowPetHeadImg(self._IconBg[j], itemInfo.petInfo.id, self._IconBg[j]:getParent(), true, true)
            else
                Utils:GetItemCellValue(self._IconBg[j], 0, itemInfo.itemId, true, true, itemInfo.num, nil, true)
            end
        end

    end


    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()

        cellChild = self.m_pCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)
        cellChild:setTouchEnabled(false)
        
        for i=1,3 do
            local faceGrid = cellChild:getChildByName("Item"..i)
            --实现选中状态
            faceGrid:setBright(true)
            faceGrid:setSwallowTouches(false)
            local index = idx*3+i
            faceGrid:setTag(index)
            faceGrid:setTouchEnabled(true)
            faceGrid:addClickEventListener(ItemGridTouched) 
			self:MarkIntaractCObj(faceGrid)
            faceGrid:getChildByName("Choose"):setVisible(false)
            if self.SelcetItem ~= nil then
                if index == self.SelcetItem:getTag() then
                    self.SelcetItem:getChildByName("Choose"):setVisible(true)
                end
            else
                --默认UI
                if index == 1 then
                    faceGrid:getChildByName("Choose"):setVisible(true)
                    self.SelcetItem = faceGrid
                end
            end
--            faceGrid:getChildByName("Explain"):setVisible(false)

        end      
    else
        cellChild = cell:getChildByTag(123)
        for i=1,3 do
            local faceGrid = cellChild:getChildByName("Item"..i)

            local pre = faceGrid:getTag()
            local index = idx*3+i
            faceGrid:setTag(index)
            faceGrid:addClickEventListener(ItemGridTouched)
			self:MarkIntaractCObj(faceGrid)
            faceGrid:getChildByName("Choose"):setVisible(false)
			
            if self.SelcetItem ~= nil then
                if index == self.SelcetItem:getTag() then
                    self.SelcetItem:getChildByName("Choose"):setVisible(true)
                end
            else
                --默认UI
                if index == 1 then
                    faceGrid:getChildByName("Choose"):setVisible(true)
                    self.SelcetItem = faceGrid
                end
            end

--            faceGrid:getChildByName("Explain"):setVisible(false)
        end

    end
    --print("cell idx"..idx)
    self:ShowFaceCellInfo(cellChild, idx)
    return cell
end


function DiscountShop:ShowFaceCellInfo(cellChild, idx)
    --print("cell idx"..idx)
    if cellChild ~= nil then
        for i=1,3 do
            --print("********************************** index", index)
            local index = idx * 3 + i
            if index > #self._DiscountShopInfo.shopdata then
                cellChild:getChildByName("Item".. i):setVisible(false)
                return
            end

            local data = self._DiscountShopInfo.shopdata[index]
            local faceGrid = cellChild:getChildByName("Item"..i)
            local icon = faceGrid:getChildByName("bg_icon")

            --print("ShowFaceCellInfo data", data.id)
            if data.itemInfos[1].awardType == 2 then
            --宠物
                Utils:ShowPetHeadImg(icon, data.itemInfos[1].petInfo.id, icon:getParent(), true, true)
            else
                Utils:GetItemCellValue(icon, 0, data.itemInfos[1].itemId, true, false, 0, nil, false)
            end

            local name = faceGrid:getChildByName("Name")
            name:setString(data.name)

            local bg_Price = faceGrid:getChildByName("bg_Price")
            local priceTxt = bg_Price:getChildByName("Value")
    

            local costPrice = faceGrid:getChildByName("CostPrice")
            local costPriceLine = costPrice:getChildByName("Line")
            
            local discountIcon = faceGrid:getChildByName("Discount")
            local myVipLevel = LRoleDataMgr.MyHeroInfo.vipLevel
            if data.vip > myVipLevel then
                costPriceLine:setVisible(false)
                costPrice:setVisible(true)
                local strVip = GUITips.RSI_CHAT_MSG_VIP..data.vip
                costPrice:setString(strVip)
                costPrice:setTextColor(cc.c4b(255, 0, 0, 255))
                bg_Price:setVisible(false)
                discountIcon:setVisible(false)
            else
                costPrice:setVisible(true)
                costPrice:setString(string.format(GUITips.RSI_DISCOUNTSHOP_PREPRICE, data.srcPrice))

                priceTxt:setVisible(true)
                priceTxt:setString(data.curPrice)

                discountIcon:setVisible(true)
                local dicount = discountIcon:getChildByName("Value")
                dicount:setVisible(true)
                local strDisCount = string.format(GUITips.RSI_DISCOUNTSHOP_DISCOUNT, data.discount / 10)
                dicount:setString(strDisCount)

            end

            if data.canBuyNum <= 0 then
                discountIcon:setVisible(false)
            end
            
            local Tag = faceGrid:getChildByName("Tag")
 
            if myVipLevel >= 15 and data.canBuyNum <= 0 then
                Tag:setVisible(true)
            else
                Tag:setVisible(false)

            end
        end
    end
end

function DiscountShop:ccTouchBegin(pTouch, pEvent) 
	LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Chat.DiscountShop")
    self:SendMsg(LGameMsg.m_initUIMsg)
end

function DiscountShop:refrashUI(info)
    -- body
    self._DiscountShopInfo = info
    self.m_pFaceTableView:reloadData();

    if self._DiscountShopInfo.type == 1 then
        self._leftTime = self._DiscountShopInfo.time
--商城更新倒计时
        self:updateCountDown()
    else
        self._leftTime = Utils:getTodayLeftSec()
--商城更新倒计时
        self:updateCountDown()
    end
    self:DefaultUI();
end

function DiscountShop:updateUIByID(info)
    -- body
--    --print("DiscountShop:updateUIByID", info.id, info.canBuyNum)
    for i = 1, #self._DiscountShopInfo.shopdata do
        if self._DiscountShopInfo.shopdata[i].id == info.id then
            self._DiscountShopInfo.shopdata[i].canBuyNum = info.canBuyNum
        end
    end

    local strLeftNum = string.format(GUITips.RSI_DISCOUNT_ITEM_LEFTNUM, info.canBuyNum)
    self._buyTimes:setString(strLeftNum)

    self._ownValue:setString(LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao())
end

function DiscountShop:updateCountDown()
    local function UpdateCD()
        self._leftTime = self._leftTime - 1
        self:showCountDown()
    end

    self:UnRoundSchedule()
    self:showCountDown()

    local scheduler =  AppDef.Director:getScheduler()
    self.m_schedulerID = scheduler:scheduleScriptFunc(UpdateCD, 1, false)
    
end

function DiscountShop:UnRoundSchedule()
    if self.m_schedulerID then
        AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_schedulerID)
        self.m_schedulerID = nil
    end
end

function DiscountShop:showCountDown()
    -- body
    local _h, _m, _s = Utils:getFormatTime(self._leftTime)
    local countDown = string.format("[c36]%02d:%02d:%02d[/c36]", _h, _m, _s)
    local updateStr = GUITips.RSI_DISCOUNT_SHOP..countDown
    self._updateTips:setString(updateStr)
end

return DiscountShop