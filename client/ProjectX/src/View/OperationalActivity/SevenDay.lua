
local SevenDay = LUIBase:New()
SevenDay.__index = SevenDay
function SevenDay:New()
	local o = LUIBase:New()
	setmetatable(o,SevenDay)	
    o:Init()
	return o
end

local DayBtn_Titles = {
    "第一天",
    "第二天",
    "第三天",
    "第四天",
    "第五天",
    "第六天",
    "第七天",
}

local DayBtn_ShopType = {
    10,
    11,
    12,
    13,
    14,
    15,
    16,
}


local MAXACTIVITYTIME = 7

function SevenDay:Init()
    self.m_pUILayer = cc.CSLoader:createNode("csd/huodong/QiriLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:InitData()
    self:InitPanel()
    -- self:updateUI()

    --请求数据
    LuaNetSendMsg:QueryGotQiRiTask()
end
function SevenDay:RegistMsgs()
    self.msgIds = 
    {
      LUIRoleDataChangeEvent.TongBaoChanged,
      LUIRoleDataChangeEvent.TiliChanged,
      LUIRoleDataChangeEvent.MoneyChanged,
      LUITaskDataEvent.GotTaskInfo,
      LUITaskDataEvent.updateQiRiUIAfterAward,
      LUIShopEvent.UpdateShopUIAfterBuySuc,
      LUIShopEvent.UpdateKaPaiShop,

      LUITaskDataEvent.updateQiriAwardUI,

    }
    self:RegistSelf(self,self.msgIds)
end

function SevenDay:ProcessEvent(msg)
    if msg.msgId == LUIRoleDataChangeEvent.TongBaoChanged then
        local myGold = LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao()
        self._cash:setString(myGold)
    elseif msg.msgId == LUIRoleDataChangeEvent.TiliChanged then
        local myTili = LRoleDataMgr.MyHeroInfo:GetDetailData():getTili()
        self._TiLi:setString(Utils:getTiliStr(myTili))
    elseif msg.msgId == LUIRoleDataChangeEvent.MoneyChanged then
        local myMoney = Utils:getGoldStr()
        self._Gold:setString(myMoney)
    elseif msg.msgId == LUITaskDataEvent.GotTaskInfo then
        self:initExtraData()
        self:updateRedPoint()
        self:updateUI()
    elseif msg.msgId == LUITaskDataEvent.updateQiRiUIAfterAward then
      
        if self:isExtraDataFromAward(msg.value) then
         
            self:updateExtraDataFromAward(msg.value)
            self:updateLeftUI()
        else
            --刷新左边数据
            self:addExtraDataFromAward()
            self:updateUIAfterReward()
            self:updateRedPoint()
        end
    elseif msg.msgId == LUIShopEvent.UpdateKaPaiShop then
        -- dump(msg.value, "SevenDay:ProcessEvent ===>")
        self:updateShopData(msg.value)
        self:RefrishPanel()
    elseif msg.msgId == LUIShopEvent.UpdateShopUIAfterBuySuc then
        self:updateShopState(msg.value)
        self:updateUIAfterReward()
    end
end

function SevenDay:getQiRiDataPriority(cellInfo)
    -- body
    local data = PetkaPaiManager:getTaskDataById(cellInfo.id)
    local maxTaskNum = 30000
    if data == nil then
        return maxTaskNum - cellInfo.id
    end
    if data.state == 1 then --完成
        return 2 * maxTaskNum - cellInfo.id
    elseif data.state == 2 then --已领取
        return cellInfo.id - maxTaskNum
    else                       --未达成条件
        return maxTaskNum - cellInfo.id
    end
end

function SevenDay:getShopDataPriority( shopData )
    -- body
    local isFinish = self:getShopTaskIsBought(shopData.id, shopData.count[2])
    if isFinish then
        return 1
    end
    return 2
end



function SevenDay:InitData()
    self.m_ptitleIdx = 1 --活动索引
    self.m_curDayIdx = 1 --天数索引
    -- self._pastDays = PetkaPaiManager._serverOpenTime
    self._pastDays = PetkaPaiManager.m_createRoleDays
    if self._pastDays < 1 then
        self._pastDays = 1
    end

    if self._pastDays > MAXACTIVITYTIME then
        self._pastDays = MAXACTIVITYTIME
    end
    self.m_ptableViewList = {}
    self._totalDatas = {}
    self._titleTabRedPoint = {}  --记录title的红点数据
    self._dayRedPoint = {} --记录每天红点数据
    self._itemIconList = {}
    self._extraList = {}
    local sevenDayConfigData = JsonConfig.m_sevendays.getList()

    --显示明天的活动，但是不可以购买
    for i=1, self._pastDays + 1 do
        local dayData = {}
        dayData[AppDef.QiRiActivityType.DailyFuLi] = {}
        dayData[AppDef.QiRiActivityType.NormalFuBen] = {}
        dayData[AppDef.QiRiActivityType.EquipStrength] = {}
        dayData[AppDef.QiRiActivityType.ShopDisCount] = {}

        for j=1, #sevenDayConfigData do
            local sdData = sevenDayConfigData[j]
            if sdData.time == i  and sdData.show > 0 then
                if AppDef.QiRiActivityType.DailyFuLi == sdData.type then
                    table.insert(dayData[AppDef.QiRiActivityType.DailyFuLi], sdData)
                end

                if AppDef.QiRiActivityType.NormalFuBen == sdData.type then
                    table.insert(dayData[AppDef.QiRiActivityType.NormalFuBen], sdData)
                end

                if AppDef.QiRiActivityType.EquipStrength == sdData.type then
                    table.insert(dayData[AppDef.QiRiActivityType.EquipStrength], sdData)
                end

            end

            --只用加载一次
            if i == 1 then
                if AppDef.QiRiActivityType.TakeTaskCumulative == sdData.type then
                    table.insert(self._extraList, sdData)
                end
            end

        end

        --打折商店
        local shopConfigData = JsonConfig.m_ShopInfo.getList()
        --商店配置,从10开始
        for k=1, #shopConfigData do
            if shopConfigData[k].type == DayBtn_ShopType[i] then
                table.insert(dayData[AppDef.QiRiActivityType.ShopDisCount], shopConfigData[k])
            end
        end
        
        self._totalDatas[i] = dayData
    end

    -- dump(self._extraList, "SevenDay:InitData 111======================>")
    
end


function SevenDay:initExtraData( ... )
    -- body
    local taskgot = LRoleDataMgr.Task:GetTaskTrackData()
    self._extraServerData = {}
    for k, v in pairs(taskgot) do
        local configData = JsonConfig.m_sevendays.getDefByID(v.task_id)
        -- print("initExtraData ==>", configData.type, v.task_id)
        if configData and configData.type == 5 then
            table.insert(self._extraServerData, v)
        end
    end

    local function sortFuc(a, b)
        return a.task_id < b.task_id
    end

    table.sort(self._extraServerData, sortFuc)
    -- dump(self._extraServerData, "initExtraData 111111111111")
end

function SevenDay:InitPanel()

    local Panel = self.m_pUILayer:getChildByName("Panel")
    Panel:setTouchEnabled(true)
    --------------------------------------------------------------
    local Reward = Panel:getChildByName("Reward")
    local LoadingBg = Reward:getChildByName("LoadingBg")
    self._loadingBar = LoadingBg:getChildByName("LoadingBar")
    self._loadingNum=LoadingBg:getChildByName("Num")
    self._awardList = {}
    self._pointNum = {}
    self._extraItemList = {}

    for i=1, 5 do
        local item = LoadingBg:getChildByName("IconBg_"..i)
        table.insert(self._awardList, item)

        local Particle = item:getChildByName("Particle")
        Particle:setVisible(false)
        local yilingqu = item:getChildByName("yilingqu")
        yilingqu:setVisible(false)

        local itemData = self._extraList[i]
        --显示图标
        local bg_icon = item:getChildByName("bg_icon")
        bg_icon:removeAllChildren()

        local ExtraItem = Utils:GetItemCellValue(bg_icon, 0, itemData.reward[1][1], true, true, itemData.reward[1][3], nil, true, true)
        table.insert(self._extraItemList, ExtraItem)
        item:setTag(i)

        item:setTouchEnabled(false)
        item:addClickEventListener(handler(self, SevenDay.getExtraAwardEvent))

        local text = LoadingBg:getChildByName("Point_"..i):getChildByName("Text")
        table.insert(self._pointNum, text)

        self._pointNum[i]:setString(itemData.condition[2])

    end

    ------------------------------------------------------------
    local Renwu = Panel:getChildByName("Renwu")
    local bg = Renwu:getChildByName("bg")
    local Image2 = bg:getChildByName("Image2")
    self._checkList = Image2:getChildByName("CheckList")
    self._titleBtnList = {}

    for i=1, 4 do
        local Type1 = self._checkList:getChildByName("Type"..i)
        Type1:setTag(i)
        table.insert(self._titleBtnList, Type1)
        Type1:addClickEventListener(handler(self, SevenDay.TitleBtnClicked))
    end
    self.m_pCellList = Image2:getChildByName("ListView")


    local DaysList = bg:getChildByName("DaysList")
    self._dayBtnList = {}
    self._shopState = {}
    for i=1, MAXACTIVITYTIME do
        local dayBtn = DaysList:getChildByName("Btn_"..i)
        dayBtn:setTouchEnabled(false)

        local LockTxt = dayBtn:getChildByName("Lock"):getChildByName("Text")
        local strText = DayBtn_Titles[i]
        LockTxt:setString(strText)
        local chooseTxt = dayBtn:getChildByName("Choose"):getChildByName("Text")
        chooseTxt:setString(strText)

        table.insert(self._dayBtnList, dayBtn)
        dayBtn:setTag(i)
        dayBtn:addClickEventListener(handler(self, SevenDay.DayBtnClicked))

        --限时购买状态
        -- self._shopState[i] = {}
    end

    self._activityTime = Renwu:getChildByName("Tips")

    self.m_pCell = Renwu:getChildByName("Item")
    self.m_pCell:removeFromParent()
    self.m_pCell:retain()
    self.m_pCell:setAnchorPoint(cc.p(0, 0))

    self._itemCell = Renwu:getChildByName("IconBg")
    ------------------------------------------------------------
    local title = Panel:getChildByName("Title")
    local CloseBtn = title:getChildByName("CloseBtn")
    CloseBtn:addClickEventListener(function (sender)
        -- body
        self:CloseUI()
    end)
    -------------------------------------------------------------
    local GoldCheck = Panel:getChildByName("GoldCheck")
    self._cash = GoldCheck:getChildByName("GoldIcon4"):getChildByName("GoldNumBg"):getChildByName("Num")
    local cashAddBtn = GoldCheck:findChildByName("GoldIcon4/AddBtn")
    cashAddBtn:setVisible(false)
    local myMoney = LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao()
    self._cash:setString(myMoney)
    self._Gold =  GoldCheck:getChildByName("GoldIcon3"):getChildByName("GoldNumBg"):getChildByName("Num")
    local goldAddBtn = GoldCheck:findChildByName("GoldIcon3/AddBtn")
    goldAddBtn:addClickEventListener(function ( sender )
        Utils:OpenFunction(AppDef.EModuleID.EMID_SCCHANGYONG)
    end)
    local myGold = Utils:getGoldStr()
    self._Gold:setString(myGold)
    self._TiLi = GoldCheck:getChildByName("GoldIcon1"):getChildByName("GoldNumBg"):getChildByName("Num")
    local tiliAddBtn = GoldCheck:findChildByName("GoldIcon1/AddBtn")
    tiliAddBtn:addClickEventListener(function ( sender )
        Utils:OpenUseUI(500,1)
    end)
    local tili = LRoleDataMgr.MyHeroInfo:GetDetailData():getTili()
    self._TiLi:setString(Utils:getTiliStr(tili))

    ------------------------------------------------------------------------------------------------------

    self._isInitedSign = {}
    for i=1, #self._totalDatas do
        self.m_ptableViewList[i] = {}
        self._isInitedSign[i] = {}
        for j=1, 4 do
            local _firstTableView = self:InitItemList(i, j)
            _firstTableView:setVisible(false)
            self._isInitedSign[i][j] = false
            if i == self.m_curDayIdx and  j == self.m_ptitleIdx then
                _firstTableView:setVisible(true)
                self._curTableView = _firstTableView
                self._isInitedSign[i][j] = true
            end
            self.m_ptableViewList[i][j] = _firstTableView
        end
    end

    -- dump(self._isInitedSign, "InitPanel 111 ======>")

    self.m_timeline = cc.CSLoader:createTimeline("csd/huodong/QiriLayer.csb")
    self.m_pUILayer:runAction(self.m_timeline)
    self.m_timeline:gotoFrameAndPlay(0, false)

end

function SevenDay:getExtraAwardEvent(sender)
    -- body
    local tag = sender:getTag()
    print("SevenDay:getExtraAwardEvent tag =", tag)
    local info = self._extraList[tag]
    -- dump(info, "getExtraAwardEvent ========>")
    LuaNetSendMsg:QueryGotQiRiAward(info.id)
end

-- 天数点击
function SevenDay:DayBtnClicked(sender)
    local tag = sender:getTag()
    print("DayBtnClicked ===> tag", tag)
    if self.m_curDayIdx == tag then
        return
    end

    self.m_curDayIdx = tag

    if self.m_curDayIdx < self._pastDays + 1 then
        local Lock = sender:getChildByName("Lock")
        Lock:setVisible(false)
    elseif self.m_curDayIdx == self._pastDays + 1 then
        local Lock = sender:getChildByName("Lock")
        local choose_bg = Lock:getChildByName("choose_bg")
        choose_bg:setVisible(true)

    elseif self.m_curDayIdx > self._pastDays + 1 then
        Utils:ShowScrollTips(GUITips.UI_QiRi_Shop_tips21)
        return
    end

    if self._lastDaySelect ~= nil then
        self._lastDaySelect:setVisible(false)

        local lastLock = self._lastDaySelect:getParent():getChildByName("Lock")
        local lastChoose_bg = lastLock:getChildByName("choose_bg")
        lastChoose_bg:setVisible(false)
    end

    local choose = sender:getChildByName("Choose")
    choose:setVisible(true)

    self._lastDaySelect = choose

    self:updateTitleUI()
    if self.m_ptitleIdx == 4 and self._shopState[self.m_curDayIdx] == nil then
        LuaNetSendMsg:QueryKaPaiShopUI(1, DayBtn_ShopType[self.m_curDayIdx])
    else
        self:RefrishPanel()
    end

    self:UpdateTabRedPoint()
end

--活动点击
function SevenDay:TitleBtnClicked(sender)
    local tag = sender:getTag()
    if self.m_ptitleIdx == tag then
        return
    end

    self.m_ptitleIdx = tag
    if self._lastSelect ~= nil then
        self._lastSelect:setVisible(false)
    end
    local choose = sender:getChildByName("Choose")
    choose:setVisible(true)
    self._lastSelect = choose
    if tag == 4 and self._shopState[self.m_curDayIdx] == nil then
        LuaNetSendMsg:QueryKaPaiShopUI(1, DayBtn_ShopType[self.m_curDayIdx])
    else
        self:RefrishPanel()
    end
end


function SevenDay:InitItemList( day, tabIndex)

    local curListData = self._totalDatas[day][tabIndex]
    local tvSize = 0 
    if curListData then
        tvSize = #curListData
    end

    -- dump(curListData, "SevenDay:InitItemList 111111111111111 ===>")
    -- print("InitItemList tvSize  =========================", tvSize)

    local tableView = cc.TableView:create(self.m_pCellList:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(cc.p(0, 0))  
    tableView:setPosition(cc.p(0, 0))
    tableView:setDelegate()
    tableView:setSwallowsTouches(false)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.m_pCellList:addChild(tableView)
    local function tableCellTouched(sender,cell)
        self:LeftTableCellTouched(cell)
    end
    local function cellSizeForTable(sender,idx)
    local size = self.m_pCell:getContentSize()
        return size.width, size.height
    end
    local function tableCellAtIndex(sender, idx)
        return self:RefrishActivityItem(sender, idx, curListData, day)
    end

    local function numberOfCellsInTableView()
        return tvSize
    end
    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量  
    return tableView
end

function SevenDay:LeftTableCellTouched(cell)
    -- body
end

--刷新界面
function SevenDay:RefrishPanel()
    if self._curTableView ~= nil then
        self._curTableView:setVisible(false)
    end
    print("RefrishPanel =================>", self.m_curDayIdx, self.m_ptitleIdx)
    local isInited = self._isInitedSign[self.m_curDayIdx][self.m_ptitleIdx]
    local tableView = self.m_ptableViewList[self.m_curDayIdx][self.m_ptitleIdx]
    if not isInited then
        self._isInitedSign[self.m_curDayIdx][self.m_ptitleIdx] = true
        tableView:reloadData()
    end
    tableView:setVisible(true)
    self._curTableView = tableView
    
end


function SevenDay:RefrishActivityItem(sender,idx, curListData, day)
    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pCell:clone()

        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cell:addChild(cellChild)
        -- cellChild:setTouchEnabled(false)
        cellChild:setSwallowTouches(false)
    else
        cellChild = cell:getChildByTag(123)
    end
    self:SetActivityItemInfo(cellChild, idx, curListData, day)
    return cell 
end

-- 设置活动cell 内容
function SevenDay:SetActivityItemInfo(cellChild, idx, curListData, dayIdx)

    print("SetActivityItemInfo ===>", idx, dayIdx)
    -- dump(curListData, "curListData =====>")
    if curListData == nil then
        return
    end

    local Panel_1 = cellChild:getChildByName("Panel_1")
    local Panel_2 = cellChild:getChildByName("Panel_2")
    local cellInfo = curListData[idx + 1]
    print("curListData ==== ", cellInfo.type)
    if cellInfo.type < AppDef.QiRiActivityType.TakeTaskCumulative then
        Panel_1:setVisible(false)
        Panel_2:setVisible(true)

        local des = Panel_2:getChildByName("TitleBg"):getChildByName("Text")
        des:setString(cellInfo.des)
        local list = Panel_2:getChildByName("ListView")
        list:setSwallowTouches(false)
        list:removeAllItems()
        for i=1, #cellInfo.reward do
            local item = cellInfo.reward[i]
            local Icon = self._itemCell:clone()
            Icon.userObject = item
            Icon:setTouchEnabled(true)
            Icon:addClickEventListener(handler(self,SevenDay.ItemCallBack))
            if item[1] ==  AppDef.RewardItem.RD_ITEM_FABAO then
                Utils:GetFaBaoCellValue(Icon, nil, item[2], 0, true, item[3], 0, 0, false, true)
            elseif item[1] ==  AppDef.RewardItem.RD_ITEM_PET then
                local petData = LPetData:New(item[2])
                Utils:GetPetHeadCellValue(Icon, nil, petData, true, true, true)
            else
                Utils:GetItemCellValue(Icon, 0, item[1], true, true, item[3], nil, false, true)
            end
            
            list:pushBackCustomItem(Icon)
        end

        local alGet = Panel_2:getChildByName("Get")
        alGet:setVisible(false)

        local GetBtn = Panel_2:getChildByName("Btn")
        local BtnAward = Panel_2:getChildByName("Btn_0")
        local Panel_weikaiqi = Panel_2:getChildByName("Panel_weikaiqi")
        print("dayIdx ==222222>", dayIdx, self._pastDays)
        local Times = Panel_2:getChildByName("Times")

        local condition = cellInfo.condition
        -- dump(cellInfo.condition, "SetActivityItemInfo == 111>")
        local targetNum = 1
        if condition[1] ~= 40 then
            targetNum = condition[2]
        end

        if dayIdx > self._pastDays then
            Panel_weikaiqi:setVisible(true)
            GetBtn:setVisible(false)
            BtnAward:setVisible(false)
            local data = PetkaPaiManager:getTaskDataById(cellInfo.id)
            local actiNum = 0
            if data ~= nil then
                actiNum = data.taskActiveNum
            end
  
            local finishTimesStr = string.format("%d/%d", actiNum, targetNum)
            Times:setString(finishTimesStr)
        else
            Panel_weikaiqi:setVisible(false)
            GetBtn:addClickEventListener(handler(self, SevenDay.GoToEvent))
            BtnAward:addClickEventListener(handler(self, SevenDay.OwnAwardEvent))
            GetBtn.userObject = cellInfo
            BtnAward.userObject = cellInfo
            GetBtn:setTag(1)
            BtnAward:setTag(2)

            
            local data = PetkaPaiManager:getTaskDataById(cellInfo.id)
            -- dump(data, "SetActivityItemInfo  1111111111111 ===>")
            local actiNum = 0
            if data ~= nil then
                print("PetkaPaiManager cellInfo.id ===>", cellInfo.id, data.state)
                actiNum = data.taskActiveNum
                if data.state == 1 then
                    BtnAward:setVisible(true)
                    GetBtn:setVisible(false)
                elseif data.state == 2 then
                    BtnAward:setVisible(false)
                    GetBtn:setVisible(false)
                    alGet:setVisible(true)
                else
                    BtnAward:setVisible(false)
                    GetBtn:setVisible(cellInfo.jump > 0)
                    alGet:setVisible(false)
                end
            else
                BtnAward:setVisible(false)
                GetBtn:setVisible(true)
                alGet:setVisible(false)
            end
            
            -- print("PetkaPaiManager 1111111 ==>", targetNum, condition[1], condition[2], actiNum)

            local finishTimesStr = string.format("%d/%d", actiNum, targetNum)
            Times:setString(finishTimesStr)
        
        end
    else
        Panel_1:setVisible(true)
        Panel_2:setVisible(false)

        local Times = Panel_1:getChildByName("Times")

        local itemIcon = Panel_1:getChildByName("Icon_1")
        itemIcon:setTouchEnabled(true)
        -- print("SetActivityItemInfo itemIcon ==>", cellInfo.itemid[1], cellInfo.itemid[3])
        Utils:GetItemCellValue(itemIcon, 0, cellInfo.itemid[1], true, true, cellInfo.itemid[3], nil, true, true)
        -- if self._itemIconList[idx + 1] then
        --     Utils:GetItemCellValue(itemIcon, 0, cellInfo.itemid[1], true, true, cellInfo.itemid[3], self._itemIconList[idx + 1], true, true)
        -- else
        --     local itemTemp = Utils:GetItemCellValue(itemIcon, 0, cellInfo.itemid[1], true, true, cellInfo.itemid[3], nil, true, true)
        --     self._itemIconList[idx + 1] = itemTemp
        -- end

        local name = itemIcon:getChildByName("Name")


        local nameStr = Utils:getItemNameByID(cellInfo.itemid[1])
        name:setString(nameStr)

        local discountLable = Panel_1:getChildByName("Lable"):getChildByName("Text")

        local discountIndex = 1
        if discountIndex > #cellInfo.price_real then
            discountIndex = #cellInfo.price_real
        end
        local value = cellInfo.price_real[discountIndex]
        local rate = value / 100
        discountLable:setString(string.format(GUITips.RSI_DISCOUNTSHOP_DISCOUNT, rate * 10))
        local OriginalPrice = cellInfo.price[1][3]
        local finalPrice = OriginalPrice * rate
        local CostPrice = Panel_1:getChildByName("CostPrice")
        CostPrice:setString(OriginalPrice)

        local bg_Price = Panel_1:getChildByName("bg_Price")
        local priceValue = bg_Price:getChildByName("Value")
        priceValue:setString(finalPrice)

        local Panel_weikaiqi = Panel_1:getChildByName("Panel_weikaiqi")

        local alOwn = Panel_1:getChildByName("Get_0")
        local btn = Panel_1:getChildByName("Btn")


        print("dayIdx ==1111>", dayIdx, self._pastDays)

        if dayIdx > self._pastDays then
            Times:setVisible(false)
            Panel_weikaiqi:setVisible(true)
            alOwn:setVisible(false)
            btn:setVisible(false)
        else
            local isFinish = self:getShopTaskIsBought(cellInfo.id, cellInfo.count[2])
            Times:setVisible(true)
            Panel_weikaiqi:setVisible(false)
            local leftTimes = self:getShopCanBuyTimes(cellInfo.id, cellInfo.count[2])
            Times:setString(string.format(GUITips.UI_QiRi_Shop_tips20, leftTimes))

            btn.userObject = cellInfo
            btn:addClickEventListener(handler(self, SevenDay.ShopDiscountEvent))

            alOwn:setVisible(isFinish)
            btn:setVisible(not isFinish)
        end

    end
end

function SevenDay:ItemCallBack(sender)
    local data = sender.userObject
    Utils:ShowItemSource(data)
end

function SevenDay:getShopCanBuyTimes( id, buyTimes )
    -- body
    if self._shopState[self.m_curDayIdx] == nil then
        return 1
    end
    local itemList = self._shopState[self.m_curDayIdx].itemList
    for i=1, #itemList do
        if itemList[i].id == id then
            return  buyTimes - itemList[i].buyTimes 
        end
    end
    return 1
end



function SevenDay:getShopTaskIsBought( id, buyTimes)
    -- body
    return self:getShopCanBuyTimes(id, buyTimes) < 1
end


function SevenDay:updateShopData(msgValue)
    -- body
    self._shopState[self.m_curDayIdx] = msgValue
    --商城数据排序
    self:sortShopData()
end



function SevenDay:sortData( ... )
    -- body
    local function sortFuc( a, b )
    -- body
        return self:getQiRiDataPriority(a) > self:getQiRiDataPriority(b)
    end

    for i=1, self._pastDays do
        local dayData = self._totalDatas[i]
        table.sort(dayData[AppDef.QiRiActivityType.DailyFuLi], sortFuc)
        table.sort(dayData[AppDef.QiRiActivityType.NormalFuBen], sortFuc)
        table.sort(dayData[AppDef.QiRiActivityType.EquipStrength], sortFuc)
    end

end

function SevenDay:sortShopData( ... )
    -- body
    local function shopSortFuc( a, b )
        -- body
        return self:getShopDataPriority(a) > self:getShopDataPriority(b)
    end

    local dayData = self._totalDatas[self.m_curDayIdx]

    table.sort(dayData[AppDef.QiRiActivityType.ShopDisCount], shopSortFuc)

end

--对当前所在的页签数据排序，方便刷新
function SevenDay:sortCurData( ... )
    -- body
    local function sortFuc( a, b )
    -- body
        return self:getQiRiDataPriority(a) > self:getQiRiDataPriority(b)
    end

    if self.m_ptitleIdx == AppDef.QiRiActivityType.ShopDisCount then
        self:sortShopData()
    else
        local dayData = self._totalDatas[self.m_curDayIdx]
        table.sort(dayData[self.m_ptitleIdx], sortFuc)
    end
    
end


function SevenDay:updateUI( ... )
    -- body
    --七日配置表中数据排序
    self:sortData()

    print("SevenDay:updateUI ===> ", self._pastDays)
    for i=1, self._pastDays + 1 do
        if i <= MAXACTIVITYTIME then
            local dayBtn =self._dayBtnList[i]
            dayBtn:setTouchEnabled(true)

            local Lock = dayBtn:getChildByName("Lock")
            if i < self._pastDays + 1 then
                Lock:setVisible(false)
            end
        end 
    end


    if self._pastDays > MAXACTIVITYTIME then
        self._activityTime:setString(GUITips.RSI_NATIONALGIFT_TIPS3)
    else
        self._activityTime:setString(string.format(GUITips.UI_QiRi_Shop_tips6, MAXACTIVITYTIME - self._pastDays))
    end
    
    local dayBtn =self._dayBtnList[self.m_curDayIdx]
    dayBtn:setTouchEnabled(true)
    local Lock = dayBtn:getChildByName("Lock")
    Lock:setVisible(false)
    self._lastDaySelect = dayBtn:getChildByName("Choose")
    self._lastDaySelect:setVisible(true)

    local Type = self._titleBtnList[self.m_ptitleIdx]
    self._lastSelect = Type:getChildByName("Choose")
    self._lastSelect:setVisible(true)

    local tableView = self.m_ptableViewList[self.m_curDayIdx][self.m_ptitleIdx]
    if tableView then
        tableView:reloadData()
    end
    
    self:updateLeftUI()
    self:updateTitleUI()
end


function SevenDay:updateTitleUI( ... )
    -- body
    local curListData = self._totalDatas[self.m_curDayIdx]
    -- dump(curListData, "updateTitleUI 111 =====>")
    self._tilteName = {}
    for i=1, #curListData do
        local tabData = curListData[i]
        for j=1, #tabData do
            local type = tabData[j].type
            -- print("updateTitleUI type ==", type, tabData[j].name)
            if self._tilteName[type] == nil then
                self._tilteName[type] = tabData[j].name
                break
            end
        end
        if #self._tilteName >= 3 then
            break
        end
    end

    -- dump(self._tilteName, "updateTitleUI ===>")

    self._tilteName[4] = GUITips.UI_QiRi_Shop_tips

    for i=1, #self._titleBtnList do
        local titleBtn = self._titleBtnList[i]
        local txt = titleBtn:getChildByName("Text")
        txt:setString(self._tilteName[i])

        local chooseTxt = titleBtn:getChildByName("Choose"):getChildByName("Text")
        chooseTxt:setString(self._tilteName[i])
    end

end

function SevenDay:updateExtraDataFromAward( finishID )
    -- body
    for i=1, #self._extraServerData do
        if self._extraServerData[i].task_id == finishID then
            self._extraServerData[i].state = 2
            break
        end
    end
end

function SevenDay:addExtraDataFromAward()
    -- body
    for i=1, #self._extraServerData do
        local data = self._extraServerData[i]
        data.taskActiveNum = data.taskActiveNum + 1
        local configData = JsonConfig.m_sevendays.getDefByID(data.task_id)
        if data.state == 0 and data.taskActiveNum >= configData.condition[2] then
            data.state = 1
        end
    end
end

function SevenDay:isExtraDataFromAward( finishID )
    -- body
    for i=1, #self._extraServerData do
        if self._extraServerData[i].task_id == finishID then
            return true
        end
    end
    return false
end

--左边精度条UI
function SevenDay:updateLeftUI( ... )
    -- body
    -- local num = PetkaPaiManager:getFinishTaskNum()

    local size = #self._extraList
   
    local itemData = self._extraList[size]

    local serverDataTemp = self._extraServerData[size]
    local num = 0
    if serverDataTemp then
        num = serverDataTemp.taskActiveNum
    end

    local maxNeedNum = itemData.condition[2]
    self._loadingBar:setPercent(num/maxNeedNum * 100)

    self._loadingNum:setString(tostring(num).."/"..maxNeedNum)

    --如果可以领取则关闭点击事件
    for i=1, 5 do
        local data = self._extraList[i]
        local serverData = self._extraServerData[i]
        -- dump(serverData, "=========================>")
        local Item = self._awardList[i]
        local Particle = Item:getChildByName("Particle")
        if serverData then
            Particle:setVisible(serverData.state == 1)
            local yilingqu = Item:getChildByName("yilingqu")
            yilingqu:setVisible(serverData.state == 2)
            self._extraItemList[i]:SetCanClick(serverData.state ~= 1)
            Item:setTouchEnabled(serverData.state == 1)
        end
    end

end

function SevenDay:updateUIAfterReward( ... )
    -- body
    local tableView = self.m_ptableViewList[self.m_curDayIdx][self.m_ptitleIdx]
    if tableView == nil then
        return
    end

    self:sortCurData()

    print("updateUIAfterReward ==>")
    local offset = tableView:getContentOffset()
    tableView:reloadData()
    tableView:setContentOffset(offset)

    --完成任务数量
    self:updateLeftUI()
end

function SevenDay:updateRedPoint(  )
    -- body

    for i=1, self._pastDays do
        local dayData = self._totalDatas[i]
        self._titleTabRedPoint[i] = {}
        self._dayRedPoint[i] = false
        for j=1, 4 do
            local tabData = dayData[j]
            self._titleTabRedPoint[i][j] = false
            for k,v in pairs(tabData) do
                local data = PetkaPaiManager:getTaskDataById(v.id)
                if data and data.state == 1 then
                    self._dayRedPoint[i] = true
                    self._titleTabRedPoint[i][j] = true
                    break
                end
            end
        end
    end

    self:UpdateTabRedPoint()

    for i=1, #self._dayRedPoint do
        local dayBtn = self._dayBtnList[i]
        local Prompt = dayBtn:getChildByName("Prompt")
        Prompt:setVisible(self._dayRedPoint[i])
    end

end


function SevenDay:UpdateTabRedPoint( sender )
    -- body
    --后面的没有红点
    if self.m_curDayIdx > self._pastDays then
        for i=1, 4 do
            local titleBtn = self._titleBtnList[i]
            local Prompt = titleBtn:getChildByName("Prompt")
            Prompt:setVisible(false)
        end
        return
    end 

    local curTabData = self._titleTabRedPoint[self.m_curDayIdx]
    for i=1, #curTabData do
        local titleBtn = self._titleBtnList[i]
        local Prompt = titleBtn:getChildByName("Prompt")
        Prompt:setVisible(curTabData[i])
    end
end

function SevenDay:GoToEvent( sender )
    -- body
    local tag = sender:getTag()
    local info = sender.userObject

    self:CloseUI()
    if info.jump == AppDef.EModuleID.EMID_KAPAI_EQUIPSRENGTH then
        local datas =  LRoleDataMgr.Pet.equipList.m_petEquips
        for k,v in pairs(datas) do
            Utils:OpenFunction(info.jump, {1, v.m_uid})
            return
        end
        Utils:ShowScrollTips(GUITips.UI_QiRi_Shop_tips2)
    elseif info.jump == AppDef.EModuleID.EMID_KAPAI_SJXIULIAN or 
            info.jump == AppDef.EModuleID.EMID_KAPAI_SJSHENGXING or 
            info.jump == AppDef.EModuleID.EMID_KAPAI_SJJINENG then
        Utils:OpenFunction(info.jump)
        Utils:SendMsg(LUIKaPaiPetEvent.ShowPetLeftInfo, LRoleDataMgr.Pet:GetPetByFightPos(1))
    elseif info.jump == AppDef.EModuleID.EMID_KAPAI_EQUIP_jinglian then
        local datas =  LRoleDataMgr.Pet.equipList.m_petEquips
        for k,v in pairs(datas) do
            Utils:OpenFunction(info.jump, {2, v.m_uid})
            return
        end
        Utils:ShowScrollTips(GUITips.UI_QiRi_Shop_tips2)
    else
        Utils:OpenFunction(info.jump)
    end
end

function SevenDay:OwnAwardEvent( sender )
    local info = sender.userObject
    LuaNetSendMsg:QueryGotQiRiAward(info.id)
end

function SevenDay:ShopDiscountEvent( sender )
    -- body
    local info = sender.userObject
    LuaNetSendMsg:QueryBuyProd(2, info.type, info.id, 1)
end

function SevenDay:updateShopState( info )
    -- body
    for i=1, #self._shopState[self.m_curDayIdx].itemList  do
        local data = self._shopState[self.m_curDayIdx].itemList[i]
        if data.id == info.index then
            data.buyTimes = info.buyTimes
        end
    end

end

function SevenDay:CloseUI( ... )
    -- body
    Utils:DeleteUI("OperationalActivity.SevenDay")
end

function SevenDay:onExit()
     self:UnRegistSelf(self,self.msgIds)
    LGameMsg.m_baseMsgWithOne:Change(LOnLineEvent.DeleteTimeFun,nil)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

end

return SevenDay