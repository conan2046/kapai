
local WanFaShopDelegate = LUIBase:New()
WanFaShopDelegate.__index = WanFaShopDelegate
--local this = LTcpSocket

local ShopDef = require("View.Shop.ShopDef")

function WanFaShopDelegate:New(ShopData)
	local o = LUIBase:New()
	setmetatable(o,WanFaShopDelegate)	
    o:Init(ShopData)
	return o
end

local EVERYLINENUM = 2

--注册事件
-- -----------------------------------
function WanFaShopDelegate:RegistMsgs()
    self.msgIds = 
    {
        LUIShopEvent.UpdateShopUIAfterBuySuc,
        LUIRoleDataChangeEvent.ArenaSorceChanged,
        LUIRoleDataChangeEvent.XinXiuJingHuaChanged,
        LUIRoleDataChangeEvent.BangGongChanged,
        LUIRoleDataChangeEvent.KunlunMoneyChanged,
        LUIRedDotEvent.UpdateRedDotState,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function WanFaShopDelegate:ProcessEvent(msg)
    if msg.msgId == LUIShopEvent.UpdateShopUIAfterBuySuc then
        self:updateDataAfterBuy(msg.value)
    elseif msg.msgId == LUIRoleDataChangeEvent.ArenaSorceChanged then
        -- --print("LRoleDataMgr:GetMoney(60050) ===>", LRoleDataMgr:GetMoney(60050))
        local money = LRoleDataMgr:GetMoney(60050)
        self._huobiList[1]:getChildByName("Value"):setString(money)
    elseif msg.msgId == LUIRoleDataChangeEvent.XinXiuJingHuaChanged then
        local money = LRoleDataMgr:GetMoney(60025)
        self._huobiList[1]:getChildByName("Value"):setString(money)
    elseif msg.msgId == LUIRoleDataChangeEvent.TongBaoChanged then
        local money = LRoleDataMgr:GetMoney(AppDef.EMoneyType.EMT_Cash)
        self._huobiList[2]:setString(money)
    elseif msg.msgId == LUIRoleDataChangeEvent.BangGongChanged then
        local money = LRoleDataMgr:GetMoney(AppDef.EMoneyType.EMT_Banggong)
        print("ProcessEvent banggong ==>", money)
        self._huobiList[1]:getChildByName("Value"):setString(money)
    elseif msg.msgId == LUIRoleDataChangeEvent.KunlunMoneyChanged then
        local myKunLunBi = LRoleDataMgr.MyHeroInfo.DetailData:GetKunLunMoney()
        self._huobiList[1]:getChildByName("Value"):setString(myKunLunBi)
    elseif msg.msgId == LUIRedDotEvent.UpdateRedDotState then
        self:updateHotDot(msg.value)
    end
end

function WanFaShopDelegate:Init(ShopData)
    -- self:CreateUINode("csd/shop/WanFaShopDelegate.csb")
    self.m_pUILayer = ShopData.pUILayer
    self:RegistMsgs()
    self:initData(ShopData.value)
    self:initControlUI()
end

function WanFaShopDelegate:initData( data )
    -- body
    self._curTag = 1
    self._tabSize = {}
    self._TagData = data
    -- dump(data, "WanFaShopDelegate:initData =====>")
    self._listData = {}
    self._lastIdx = 0

end

function WanFaShopDelegate:updateData( data )
    -- body
    print("WanFaShopDelegate:updateData ==>", data.type, self._TagData[self._curTag].id, self._curTag)
    -- dump(data, "WanFaShopDelegate:updateData ===>")
    if data.type == self._TagData[self._curTag].id then
        self._listData[self._curTag] = data
        self._tabSize[self._curTag] = data.size
        self._tabTVList[self._curTag]:reloadData()
        
        self:setMoney()
        --更新红点
        self:updateHotDot()
    end
end

function WanFaShopDelegate:updateDataAfterBuy( data )
    -- body
    print("WanFaShopDelegate:updateData ==> 111111", data.shopType, self._listData[self._curTag].type)

    if self._listData[self._curTag].type == data.shopType then
        local curData = self._listData[self._curTag]
        for k,v in pairs(curData.itemList) do
            if v.id == data.index then
                v.buyTimes = data.buyTimes
            end
        end

        local curTagType = self._TagData[self._curTag].id
        if ShopDef.KP_SP.WANFA_GIFT == curTagType or ShopDef.KP_SP.XueZhan_4 == curTagType then
            --奖励商店排序
            self:sortCurListView()
        end

        local offset = self._tabTVList[self._curTag]:getContentOffset()
        self._tabTVList[self._curTag]:reloadData()
        self._tabTVList[self._curTag]:setContentOffset(offset)
    end
end

function WanFaShopDelegate:initControlUI( ... )
    self._TableViewPanel = self.m_pUILayer:getChildByName("TableView")
    -------------------------------------------------------------------
    self._pCell1 = self.m_pUILayer:getChildByName("ItemList_1")
    self._pCell1:setAnchorPoint(cc.p(0, 0))
    self._pCell1:removeFromParent()

    self._pCell1:retain()
    self._pCell2 = self.m_pUILayer:getChildByName("ItemList_2")
    self._pCell2:setAnchorPoint(cc.p(0, 0))
    self._pCell2:removeFromParent()
    self._pCell2:retain()
    -------------------------------------------------------------------
    local Panel_yeqian = self.m_pUILayer:findChildByName("ShopUI/Panel_yeqian_1")
    self._tabList = {}
    self._tabTVList = {}
    self._huobiTypeArr = {}
    self._huobiTypeArr[self._curTag] = {}
    local size = #self._TagData - 1
    if self._TagData.noAwardTab then
        size = #self._TagData
    end
    print("initControlUI = size = ", size, self._TagData.noAwardTab)
    self._tabPosArr = {}
    for i=1, 4 do
        local yeqian = Panel_yeqian:getChildByName("yeqian"..i)
        yeqian:setVisible(false)
        if size >= i then
            yeqian:setVisible(true)
            yeqian:setBright(true)
            yeqian:setTag(i)
            yeqian:getChildByName("Text"):setString(self._TagData[i].sub_name)
            yeqian:addClickEventListener(handler(self, WanFaShopDelegate.tabClicked))
            table.insert(self._tabList, yeqian)
            local tv = self:InitShopTabView()
            tv:setVisible(false)
            -- tv:reloadData()
            if i == self._curTag then
                tv:setVisible(true)
                yeqian:setBright(false)
            end
            table.insert(self._tabTVList, tv)
        end
        local x, y = yeqian:getPosition()
        table.insert(self._tabPosArr, cc.p(x, y))
    end
    
    --奖励
    local yeqian5 = Panel_yeqian:getChildByName("yeqian5")
    self._jiangliBtn = yeqian5
    self._jiangliBtn:getChildByName("Prompt"):setVisible(false)
    if self._TagData.noAwardTab then
        yeqian5:setVisible(false)
    else
        print("this is updateDataAfterBuy ======================>")
        local awardTv = self:InitAwardTabView()
        awardTv:setVisible(false)
        -- awardTv:reloadData()
        table.insert(self._tabTVList, awardTv)
        yeqian5:setVisible(true)
        yeqian5:setBright(true)
        yeqian5:setTag(size + 1)
        yeqian5:setPosition(self._tabPosArr[size + 1])
        yeqian5:getChildByName("Text"):setString(GUITips.UI_Title_PetFaBao_Tips9)
        table.insert(self._tabList, yeqian5)
        yeqian5:addClickEventListener(handler(self, WanFaShopDelegate.tabClicked))
    end

    ------------------------------------------------------------------------------------------
    local shopUI = self.m_pUILayer:getChildByName("ShopUI")
    local Mine = shopUI:getChildByName("Mine")

    self._huobiList = {}

    self._jianghun = Mine:getChildByName("jianghun")
    self._jianghun:setVisible(false)
    table.insert(self._huobiList, self._jianghun)

    self._yuanbao = Mine:getChildByName("yuanbao")
    self._yuanbao:setVisible(false)
    table.insert(self._huobiList, self._yuanbao)


end

function WanFaShopDelegate:tabClicked( sender )
    -- body
    local tag = sender:getTag()
    if tag == self._curTag then
        return
    end

    self._tabList[self._curTag]:setBright(true)
    self._tabList[tag]:setBright(false)

    self._tabTVList[self._curTag]:setVisible(false)
    self._tabTVList[tag]:setVisible(true)
    --print("self._curTag =", self._curTag, tag, self._TagData[tag].id)

    self._curTag = tag
    if self._listData[self._curTag] == nil then
        --print("WanFaShopDelegate:tabClicked ==>", self._curTag)
        if self._TagData[tag] then
            self._huobiTypeArr[self._curTag] = {}
            LuaNetSendMsg:QueryKaPaiShopUI(1, self._TagData[tag].id)
        end
    else
        self:setMoney()
    end

end

function WanFaShopDelegate:InitShopTabView()
    local tableView = cc.TableView:create(self._TableViewPanel:getContentSize())
    tableView:setContentSize(self._TableViewPanel:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(cc.p(0, 0))
    tableView:setPosition(cc.p(0, 0))
    tableView:setDelegate()
    tableView:setSwallowsTouches(true)
    tableView:setBounceable(true)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self._TableViewPanel:addChild(tableView)

    local function tableCellTouched(sender,cell)
        self:ShopTableCellTouched(sender, cell)
    end

    local function cellSizeForTable(sender,idx)
        local width = self._pCell1:getContentSize().width
        local height = self._pCell1:getContentSize().height
        return width, height
    end

    local function tableCellAtIndex(sender, idx)
        return self:ShopTableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        local size = 0
        -- if self._ownPetList then
        --     if #self._ownPetList % EVERYLINENUM == 0 then
        --         size = #self._ownPetList / EVERYLINENUM
        --     else
        --         size = math.floor(#self._ownPetList / EVERYLINENUM) + 1 
        --     end
        -- end
        if self._tabSize[self._curTag] % EVERYLINENUM == 0 then
            size = self._tabSize[self._curTag] / EVERYLINENUM
        else
            size = self._tabSize[self._curTag] / EVERYLINENUM + 1
        end
        return size
    end

    local function scrollViewDisScroll(view)
        self.m_isShopDragging = view:isDragging()
    end

    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量

    tableView:registerScriptHandler(scrollViewDisScroll, cc.SCROLLVIEW_SCRIPT_SCROLL)
    return tableView
end


--点击选中处理
function WanFaShopDelegate:ShopTableCellTouched(sender, cell)
    
    local ind = cell:getIdx()
    local cellChild = cell:getChildByTag(123)
end 


function WanFaShopDelegate:ShopTableCellAtIndex(sender, idx)

    local function petGridTouched(sender)--选中
        if self.m_isShopDragging then
            return
        end
        local ind = sender:getTag()
        --print("PetTableCellAtIndex =============>", idx)
        if self._lastIdx > 0 and self.m_pTheTableView then
            local lastidx = math.floor((self._lastIdx - 1) / EVERYLINENUM)
            local lastSelcetFace = self.m_pTheTableView:cellAtIndex(lastidx)
            if lastSelcetFace ~= nil then
                local cellChild = lastSelcetFace:getChildByTag(123)
                if cellChild ~= nil then
                    local i = (self._lastIdx - 1) % EVERYLINENUM + 1
                    local lastItem = cellChild:getChildByTag(i)
                    if lastItem ~= nil then
                        -- lastItem:getChildByName("Choose"):setVisible(false)
                    end
                end
            end
        end
         
        -- sender:getChildByName("Choose"):setVisible(true)
        self._lastIdx = ind;
    end


    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self._pCell1:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)
        cellChild:setTouchEnabled(false)
        for i=1, EVERYLINENUM do
            local giftGrid = cellChild:getChildByName("Item"..i)
            --实现选中状态
            -- giftGrid:setBright(true)
            giftGrid:setSwallowTouches(false)
            local index = idx * EVERYLINENUM + i 
            giftGrid:setTag(index)
            giftGrid:addClickEventListener(petGridTouched) 
            self:MarkIntaractCObj(giftGrid)
            giftGrid:setTouchEnabled(true)
            -- giftGrid:getChildByName("Choose"):setVisible(false)
            -- cellChild:pushBackCustomItem(giftGrid)
            self:showShopInfo(cellChild, giftGrid, index)
        end      
    else
        cellChild = cell:getChildByTag(123)
        for i=1, EVERYLINENUM do
            local index = idx*EVERYLINENUM+i
            local giftGrid = cellChild:getChildByName("Item"..i)
            giftGrid:setTag(index)
            self:showShopInfo(cellChild, giftGrid, index)
        end
    end
    
    return cell
end

function WanFaShopDelegate:showShopInfo(cellChild, giftGrid, index)
    -- body
    if cellChild == nil then
        return
    end
    local curData = self._listData[self._curTag]
    -- dump(curData, "showShopInfo ===== 1111111111111>")

    if index > #curData.itemList then
        giftGrid:setVisible(false)
        return
    end
    giftGrid:setVisible(true)
    -- --print("showKaPaiInfo ======== index >", index)
    local itemData = curData.itemList[index]
    self:showItemInfo(giftGrid, itemData)

end

function WanFaShopDelegate:showItemInfo( giftGrid, itemData )
    -- body
    --print("showItemInfo itemData.id ===>", itemData.id)
    local configData = JsonConfig.m_ShopInfo.getDefByID(itemData.id)
    if configData == nil then
        return
    end

    local Icon = giftGrid:getChildByName("Icon")
    Utils:GetItemCellValue(Icon, 0, configData.itemid[1], true, true, configData.itemid[3], nil, true, true)
    local name = giftGrid:getChildByName("Name")
    local nameStr = Utils:getItemNameByID(configData.itemid[1])
    name:setString(nameStr)
    
    local priceSize = #configData.price
    for i=1, 2 do
         local huobi = giftGrid:getChildByName("huobi_"..i)
         huobi:setVisible(false)
        if priceSize >= i then
            huobi:setVisible(true)
            local huobiValue = huobi:getChildByName("Value")
            huobiValue:setString(configData.price[i][3])

            local icon = huobi:getChildByName("Icon")
            --print("WanFaShopDelegate:showItemInfo === 1111>", configData.price[i][1], configData.price[i][3])
            local str = AppDef:GetMoneyIconById(configData.price[i][1])
            -- icon:loadTexture(str, UI_TEX_TYPE_PLIST)
            Utils:SafeLoadTexture(icon, str, ccui.TextureResType.plistType)
            if not self:isObtainHuobi(configData.price[i][1]) then
                table.insert(self._huobiTypeArr[self._curTag], configData.price[i][1])
            end
        end
    end 

    local txt1 = giftGrid:getChildByName("txt_1")
    txt1:getChildByName("num"):setVisible(false)
    
    local txt2 = giftGrid:getChildByName("txt_2")
    txt2:getChildByName("num"):setVisible(false)

    configData.buyTimes = itemData.buyTimes
    configData.leftTimes = -1
    local isDone = PetkaPaiManager:getShopConditionIsDone(configData.condition)
    if isDone then
        txt2:setVisible(false)
        if configData.count and #configData.count > 1 then
            txt1:setVisible(true)
            txt1:getChildByName("num"):setVisible(true)
            local leftTimes = configData.count[2] - itemData.buyTimes
            configData.leftTimes = leftTimes
            local tips = string.format(GUITips.RSI_WWDX_TIPS_2, leftTimes )
            --print("WanFaShopDelegate ==============>", tips)
            txt1:getChildByName("num"):setString(tips)
        else
            txt1:setVisible(false)
        end
    else
        txt1:setVisible(false)
        txt2:setVisible(true)
        local strTips = PetkaPaiManager:getAllShopConditionStr(configData.condition)
        txt2:setString(strTips)
    end

    local Recommend = giftGrid:getChildByName("Recommend")
    Recommend:setVisible(false)

    

    local Btn_Buy = giftGrid:getChildByName("Btn_Buy")
    --print("Btn_Buy === 111>", Btn_Buy:getContentSize().width, Btn_Buy:getContentSize().height)

    local costNum = PetkaPaiManager:getPetStrengthUpCost(configData)
    local havenum = giftGrid:getChildByName("havenum")
    if costNum > 0 then
        havenum:setVisible(true)
        local countNum = LRoleDataMgr.Equip:CountItemNumById(configData.itemid[1])
        havenum:setString(string.format("(%d/%d)", countNum, costNum))
    else
        havenum:setVisible(false)
    end

    if isDone then
        Btn_Buy:addClickEventListener(handler(self, WanFaShopDelegate.buyEvent))
        Btn_Buy:setTag(itemData.index)
        Btn_Buy.userObject = configData
        Btn_Buy:setBright(true)
        Btn_Buy:setTouchEnabled(true)
    else
        Btn_Buy:setBright(false)
        Btn_Buy:setTouchEnabled(false)
    end

end

function WanFaShopDelegate:isObtainHuobi( moneyId )
    -- body
    for i=1, #self._huobiTypeArr[self._curTag] do
        if moneyId == self._huobiTypeArr[self._curTag][i] then
            return true
        end
    end
    return false
end

function WanFaShopDelegate:buyEvent(sender)
    -- body
    local configData = sender.userObject
    -- dump(configData, "buyEvent ====================>")
    for k,v in pairs(configData.price) do
        local needMoney = LRoleDataMgr:GetMoney(v[1])
        --print("WanFaShopDelegate:buyEvent =====>", needMoney, v[3], v[1])
        if needMoney < v[3] then
            if v[1] == AppDef.SpecialItemId.JinjiMoney then
                Utils:ShowScrollTips(GUITips.UI_QiRi_Shop_tips8)
            elseif v[1] == AppDef.SpecialItemId.StarExp then
                Utils:ShowScrollTips(GUITips.UI_QiRi_Shop_tips9)
            elseif v[1] == AppDef.SpecialItemId.Cash then
                Utils:ShowScrollTips(GUITips.RSI_LD_TIP11)
            elseif  v[1] == AppDef.SpecialItemId.KunlunMoney then
                Utils:ShowScrollTips(GUITips.RSI_LD_TIP13)
            elseif v[1] == AppDef.SpecialItemId.Banggong then
                Utils:ShowScrollTips(GUITips.RSI_BP_SKILL_UPTIPS2)
            end
            return
        end
    end

    local tag = sender:getTag()
    local shopType = self._TagData[self._curTag].id
    --print("WanFaShopDelegate:buyEvent z", tag, shopType, count, configData.id )
    -- LuaNetSendMsg:QueryBuyProd(2, shopType, configData.id, count)
    local leftTimes = configData.leftTimes
    local buyTimes = configData.buyTimes
    -- -1表示没有购买限制
    if leftTimes == -1 then
        leftTimes = 200
        buyTimes = 0
    end
    print("WanFaShopDelegate:buyEvent =================>", leftTimes, buyTimes)
    if leftTimes <= 0 then
        Utils:ShowScrollTips(GUITips.RSI_PET_MSG40)
    elseif leftTimes == 1 then
        --只有一次则直接购买
        LuaNetSendMsg:QueryBuyProd(2, shopType, configData.id, leftTimes)
    else
        Utils:OpenBuyUI(configData.id, leftTimes, 0, 0, buyTimes)
    end
    
end

---------------------------------------------------------------------------------------------

function WanFaShopDelegate:InitAwardTabView()
    local tableView = cc.TableView:create(self._TableViewPanel:getContentSize())
    tableView:setContentSize(self._TableViewPanel:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(cc.p(0, 0))
    tableView:setPosition(cc.p(0, 0))
    tableView:setDelegate()
    tableView:setSwallowsTouches(true)
    tableView:setBounceable(true)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self._TableViewPanel:addChild(tableView)

    local function tableCellTouched(sender,cell)
        self:AwardTableCellTouched(sender, cell)
    end

    local function cellSizeForTable(sender,idx)
        local width = self._pCell2:getContentSize().width
        local height = self._pCell2:getContentSize().height
        return width, height
    end

    local function tableCellAtIndex(sender, idx)
        return self:AwardTableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        return self._tabSize[self._curTag]
    end

    local function scrollViewDisScroll(view)
        self.m_isDragging = view:isDragging()
    end

    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量

    tableView:registerScriptHandler(scrollViewDisScroll, cc.SCROLLVIEW_SCRIPT_SCROLL)
    return tableView
end


--点击选中处理
function WanFaShopDelegate:AwardTableCellTouched(sender, cell)
    
    local ind = cell:getIdx()
    local cellChild = cell:getChildByTag(123)
end 


function WanFaShopDelegate:AwardTableCellAtIndex(sender, idx)

    local function petGridTouched(sender)--选中
        if self.m_isDragging then
            return
        end
        local ind = sender:getTag()
        --print("PetTableCellAtIndex =============>", idx)
        if self._lastIdx > 0 and self.m_pTheTableView then
            local lastidx = math.floor((self._lastIdx - 1) / EVERYLINENUM)
            local lastSelcetFace = self.m_pTheTableView:cellAtIndex(lastidx)
            if lastSelcetFace ~= nil then
                local cellChild = lastSelcetFace:getChildByTag(123)
                if cellChild ~= nil then
                    local i = (self._lastIdx - 1) % EVERYLINENUM + 1
                    local lastItem = cellChild:getChildByTag(i)
                    if lastItem ~= nil then
                        -- lastItem:getChildByName("Choose"):setVisible(false)
                    end
                end
            end
        end
         
        -- sender:getChildByName("Choose"):setVisible(true)
        self._lastIdx = ind;
    end


    local cell = sender:dequeueCell()
    local cellChild
    local index = idx + 1 
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self._pCell2:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)
        cellChild:setTouchEnabled(false)

        local giftGrid = cellChild:getChildByName("Item1")
        --实现选中状态
        -- giftGrid:setBright(true)
        giftGrid:setSwallowTouches(false)
        
        giftGrid:setTag(index)
        giftGrid:addClickEventListener(petGridTouched) 
        self:MarkIntaractCObj(giftGrid)
        giftGrid:setTouchEnabled(true)
        -- giftGrid:getChildByName("Choose"):setVisible(false)
        -- cellChild:pushBackCustomItem(giftGrid)
        self:showAwardInfo(cellChild, giftGrid, index)
             
    else
        cellChild = cell:getChildByTag(123)
        local giftGrid = cellChild:getChildByName("Item1")
        self:showAwardInfo(cellChild, giftGrid, index)
    end
    return cell
end

function WanFaShopDelegate:setMoney( ... )
    -- body
    --print("setMoney =====>", self._TagData.shopType, ShopDef.KP_SP.WANFA_GIFT)

    for i=1, #self._huobiList do
        self._huobiList[i]:setVisible(false)
    end

    for i=1, #self._huobiTypeArr[self._curTag] do
        local huobi = self._huobiList[i]
        huobi:setVisible(true)
        local type = self._huobiTypeArr[self._curTag][i]

        local money = LRoleDataMgr:GetMoney(type)
        local value = huobi:getChildByName("Value")
        value:setString(tostring(money))
        local icon = huobi:getChildByName("Icon")
        local strImage =  AppDef:GetMoneyIconById(type)
        --print("WanFaShopDelegate:setMoney ==>", strImage, money)
        -- icon:loadTexture(strImage, UI_TEX_TYPE_PLIST)
        Utils:SafeLoadTexture(icon, strImage, ccui.TextureResType.plistType)
    end
    
end

function WanFaShopDelegate:getQiRiDataPriority(ItemData)
    -- body
    local configData = JsonConfig.m_ShopInfo.getDefByID(ItemData.id)
    local leftTimes = configData.count[2] - ItemData.buyTimes
    if configData == nil or leftTimes <= 0 then
        return ItemData.id
    end
    local Priority = 50000
    return Priority - ItemData.id
end

function WanFaShopDelegate:sortCurListView( ... )
    -- body
    -- body
    local function sortFuc(a, b)
        return self:getQiRiDataPriority(a) > self:getQiRiDataPriority(b)
    end

    local curData = self._listData[self._curTag]
    table.sort(curData.itemList, sortFuc)
end


function WanFaShopDelegate:showAwardInfo(cellChild, giftGrid, index)
    -- body
    if cellChild == nil then
        return
    end
    local curData = self._listData[self._curTag]
    self:sortCurListView()
    if index > #curData.itemList then
        giftGrid:setVisible(false)
        return
    end
    giftGrid:setVisible(true)
    --print("showKaPaiInfo ======== index >", index)
    local aData = curData.itemList[index]
    self:showAwardItemInfo(giftGrid, aData)

end

function WanFaShopDelegate:showAwardItemInfo(giftGrid, aData)
    -- body
    --print("showAwardItemInfo ===>", aData.id)
    local configData = JsonConfig.m_ShopInfo.getDefByID(aData.id)
    if configData == nil then
        return
    end
    local Icon = giftGrid:getChildByName("Icon")
    Icon:removeAllChildren()
    
    if configData.itemid[1] ==  AppDef.RewardItem.RD_ITEM_FABAO then
        Utils:GetFaBaoCellValue(Icon, nil, configData.itemid[2], 0, true, configData.itemid[3], 0, 0, true, true)
    elseif configData.itemid[1] ==  AppDef.RewardItem.RD_ITEM_EQUIP then
        Utils:GetEquipCellByEquipID(Icon, nil, configData.itemid[2], true, true,true)
    else
        Utils:GetItemCellValue(Icon, 0, configData.itemid[1], true, true, configData.itemid[3], nil, true, true)
    end

    local name = giftGrid:getChildByName("Name")
    local nameStr = Utils:getItemNameByID(configData.itemid[1])
    name:setString(nameStr)
    
    
    if not self:isObtainHuobi(configData.price[1][1]) then
        table.insert(self._huobiTypeArr[self._curTag], configData.price[1][1])
    end

    local huobi1 = giftGrid:getChildByName("huobi_1")
    local huobiValue1 = huobi1:getChildByName("Value")
    huobiValue1:setString(configData.price[1][3])

    local icon1 = huobi1:getChildByName("Icon")
    --print("aData aData.buyTimes ==> ", aData.buyTimes)
    local str = AppDef:GetMoneyIconById(configData.price[1][1])
    icon1:loadTexture(str, UI_TEX_TYPE_PLIST)

    local huobi2 = giftGrid:getChildByName("huobi_2")
    local huobiValue2 = huobi2:getChildByName("Value")

    local discountIndex = aData.buyTimes + 1
    if discountIndex > #configData.price_real then
        discountIndex = #configData.price_real
    end

    local value = configData.price_real[discountIndex]
    local rate = value / 100
    if rate < 1 then
        huobi2:setVisible(true)
        huobiValue2:setString(configData.price[1][3] * rate)
        local icon2 = huobi2:getChildByName("Icon")
        icon2:loadTexture(str, UI_TEX_TYPE_PLIST)
    else
        huobi2:setVisible(false)
    end

    local txt1 = giftGrid:getChildByName("txt_1")
    local strTips = PetkaPaiManager:getAllShopConditionStr(configData.condition)
    txt1:setString(strTips)
    local Btn_Buy = giftGrid:getChildByName("Btn_Buy")
    local times = giftGrid:getChildByName("times")

    local isDone = PetkaPaiManager:getShopConditionIsDone(configData.condition)
    if isDone then
        if #configData.count > 0 then
            local leftTimes = configData.count[2] - aData.buyTimes
            configData.leftTimes = leftTimes
            configData.buyTimes = aData.buyTimes
            --print("WanFaShopDelegate =============> ", leftTimes)
            times:setVisible(true)
            if leftTimes > 0 then
                local str = string.format(GUITips.UI_Shop_buyTimes, leftTimes)
                times:setString(str)

                Btn_Buy:addClickEventListener(handler(self, WanFaShopDelegate.buyEvent))
                Btn_Buy:setBright(true)
                Btn_Buy:setTouchEnabled(true)
            else
                times:setString(GUITips.UI_Shop_buyMax)
                Btn_Buy:setBright(false)
                Btn_Buy:setTouchEnabled(false)
            end

        else
            times:setVisible(false)
            Btn_Buy:setBright(true)
            Btn_Buy:setTouchEnabled(true)
        end
    else
        times:setVisible(false)
        Btn_Buy:setBright(false)
        Btn_Buy:setTouchEnabled(false)
    end
    
    Btn_Buy:setTag(aData.index)
    Btn_Buy.userObject = configData


end


function WanFaShopDelegate:updateHotDot(data)
    -- body
    local isShow = false
    if self._TagData.shopType == ShopDef.KP_TYPE.JINGJICHANGSHANGDIAN then
        isShow = Utils:GetRedDotState(RedDotDef.ID.ShopWanFaJingji)
    else
        isShow = Utils:GetRedDotState(RedDotDef.ID.ShopWanFaXueZhan)
    end

    self._jiangliBtn:getChildByName("Prompt"):setVisible(isShow)
    
end

------------------------------------------------------------------------------------------------

function WanFaShopDelegate:CloseUI( ... )
    -- body
    Utils:DeleteUI("Shop.WanFaShopDelegate")
end

function WanFaShopDelegate:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return WanFaShopDelegate