
local FindOfflineExp = LUIBase:New()
FindOfflineExp.__index = FindOfflineExp
--local this = LTcpSocket
function FindOfflineExp:New(parent)
	local o = LUIBase:New()
	setmetatable(o,FindOfflineExp)	
    o:Init(parent)
	return o
end

--注册事件
-- -----------------------------------
function FindOfflineExp:RegistMsgs()
    self.msgIds = 
    {
        LUIResRecoveryEvent.updateResRecoveryUI,
        LUIResRecoveryEvent.convertBuyTimes,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function FindOfflineExp:ProcessEvent(msg)
    if msg.msgId == LUIResRecoveryEvent.updateResRecoveryUI then
        self:refrashUI(true)

        if #LRoleDataMgr.recoveryData == 0 then
            Utils:SetRedDotState(RedDotDef.ID.Fuli_ResRecovery, false)
        end
    end

    if msg.msgId == LUIResRecoveryEvent.convertBuyTimes then
        self._curBuyTimes = msg.value
    end
end

function FindOfflineExp:Init(parent)
    self.m_pUILayer = cc.CSLoader:createNode("csd/huodong/ziyuanzhaohui.csb")
    parent:addChild(self.m_pUILayer)
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:initData()
    self:initUI()    
    self:refrashUI(false)
    self._offset = cc.p(0, 0)
end

function FindOfflineExp:initData()
    -- body
    -- local panel = self.m_pUILayer:getChildByName("RewardBack")
    -- self._defaltBg = panel:getChildByName("Image_1")
    self._listView = self.m_pUILayer:findChildByName("Panel_ziyuanzhaohui/ListView");
    self._rewardsCell = self.m_pUILayer:findChildByName("Panel_ziyuanzhaohui/Panel_zhaohui1");
    self._rewardsCell:setVisible(false)
    self._itemCell = self.m_pUILayer:findChildByName("Panel_ziyuanzhaohui/Icon_1");
    self._itemCell:setVisible(false)

    self._TextBg = self.m_pUILayer:findChildByName("Panel_ziyuanzhaohui/RolePic/TextBg");
    
 --    local desBg = panel:getChildByName("DesBg")
 --    self._jinbiFind = desBg:getChildByName("Coin"):getChildByName("Text")
 --    self._jinbiColor = self._jinbiFind:getTextColor()
 --    self._jinbiFindBtn = desBg:getChildByName("Button_1")

 --    local function jinbiFindExpEvent(sender)
 --        -- body
 --        self:ShowFindAllDialog(1, self._recoveryData.coinFindPay)
 --    end
 --    self._jinbiFindBtn:addClickEventListener(jinbiFindExpEvent)
	-- self:MarkIntaractCObj(self._jinbiFindBtn)
 --    self._goldFind = desBg:getChildByName("Gold"):getChildByName("Text")
 --    self._goldFindColor = self._goldFind:getTextColor()

 --    self._goldFindBtn = desBg:getChildByName("Button_2")
 --    local function goldFindExpEvent(sender)
 --        -- body
 --        self:ShowFindAllDialog(2, self._recoveryData.goldFindPay)
 --    end
 --    self._goldFindBtn:addClickEventListener(goldFindExpEvent)
 --    self:MarkIntaractCObj(self._goldFindBtn)
	-- self._rewardsCell = panel:getChildByName("Item")
 --    self._iconCell = panel:getChildByName("IconBg")
 --    self._iconCell:setTouchEnabled(true)
 --    self._recoveryData = LOfflineResInfo:New()

 --    self._curBuyTimes = 0
end

function FindOfflineExp:initUI( ... )
    -- body
    if #LRoleDataMgr.recoveryData > 0 then
        self:initListTableView()
        self.m_pExpTableView:reloadData()
        self._TextBg:setVisible(false)
    else
        self._TextBg:setVisible(true)
    end
    
    -- self._jinbiFind:setString("0")
    -- self._goldFind:setString("0")
end

function FindOfflineExp:setVisible(visible)
    self.m_pUILayer:setVisible(visible)
end

function FindOfflineExp:initListTableView()
    local tableView = cc.TableView:create(self._listView:getContentSize())
--    --print("width = ".. self._listView:getContentSize().width .. "height = " .. self._listView:getContentSize().height);
--    --print("width = ".. tableView:getContentSize().width .. "height = " .. tableView:getContentSize().height);
    tableView:setContentSize(self._listView:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(cc.p(0, 0))
    tableView:setPosition(cc.p(0, 0))
    tableView:setDelegate()
    tableView:setSwallowsTouches(true)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self._listView:addChild(tableView)
    
    local function tableCellTouched(sender,cell)
        --print("tableCellTouched", cell:getIdx())
        self:expTableCellTouched(cell)
    end

    local function cellSizeForTable(sender,idx)
        local width = self._rewardsCell:getContentSize().width
        local height = self._rewardsCell:getContentSize().height
        return width, height
    end

    local function tableCellAtIndex(sender, idx)
--        --print("cellSizeForTable idx = ".. idx )
        return self:expTableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()

        local size = #LRoleDataMgr.recoveryData
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
    self.m_pExpTableView = tableView
end

function FindOfflineExp:expTableCellTouched(cell)
    local ind = cell:getIdx()
    local cellChild = cell:getChildByTag(123)
end

function FindOfflineExp:expTableCellAtIndex(sender, idx)

    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self._rewardsCell:clone()
        cellChild:getChildByName("item_layer"):setSwallowTouches(false)
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)
        cellChild:setTouchEnabled(false)         
    else
        cellChild = cell:getChildByTag(123)
    end
    --print("cell idx"..idx)
    self:ShowExpCellInfo(cellChild, idx)
    return cell
end

function FindOfflineExp:ShowExpCellInfo(cellChild, idx)
    -- body
    if cellChild == nil then
        return
    end

    if self._recoveryData == nil then
        return
    end

    local cellData = self._recoveryData[idx + 1]
    local config = JsonConfig.GetRevertData(cellData.funcId)
    local nameLabel = cellChild:findChildByName("title/name")
    nameLabel:setString(config.name)
    local timeValue = cellChild:getChildByName("times")
    timeValue:setString( string.format(GUITips.UI_Activity_LeftTimes, cellData.leftTimes))
    local listView = cellChild:getChildByName("item_layer")
    listView:removeAllItems()
    for i = 1, cellData.awardNum do
        local itemInfo = cellData.awardInfo[i]
        local awardIcon = self._itemCell:clone()
        awardIcon:setVisible(true)
        awardIcon:setTouchEnabled(true)
        awardIcon:setSwallowTouches(false)
        -- local dataArr = {itemInfo.awardId,0,itemInfo.awardNum}
        -- if itemInfo.awardId == AppDef.AwrdItem.AWRD_ITEM_EQUIP or itemInfo.awardId == AppDef.AwrdItem.AWRD_ITEM_FABAO then
        --     dataArr = {itemInfo.awardId,itemInfo.awardNum,1};
        -- end
        Utils:ShowItemByConfigData(itemInfo, awardIcon, nil, true, true)
        -- Utils:GetItemCellValue(awardIcon, 0, itemInfo.awardId, true, true, itemInfo.awardNum, nil, true)

        awardIcon:getChildByName("Name"):setString(Utils:getItemNameByID(itemInfo.awardId))
        listView:pushBackCustomItem(awardIcon)
    end 

    local str = AppDef:GetMoneyIconById(cellData.cost[1])
    cellChild:findChildByName("buyBtn/GoldIcon/Icon"):loadTexture(str, ccui.TextureResType.plistType)
    local numLabel = cellChild:findChildByName("buyBtn/GoldIcon/Num")
    numLabel:setString(cellData.cost[3]);

 --    local gainMark = cellChild:getChildByName("Mark")
 --    local coin = cellChild:getChildByName("Coin")
 --    local coinText = coin:getChildByName("Text")
 --    coinText:setString(cellData.normalFindPay * cellData.findTimes)
 --    local gold = cellChild:getChildByName("Gold")
 --    local goldText = gold:getChildByName("Text")
 --    goldText:setString(cellData.perfectFindPay * cellData.findTimes)
    local normalBackBtn = cellChild:getChildByName("buyBtn")
    local function normalBackEvent(sender)
        -- local dataInfo = Utils:deepCopy(cellData.awardInfo)
        -- for i=1, cellData.awardNum do
        --     table.insert(dataInfo, cellData.awardInfo[i])
        -- end
        self:ShowFindDialog(cellData)
    end
    normalBackBtn:addClickEventListener(normalBackEvent)
	-- self:MarkIntaractCObj(normalBackBtn)

 --    perfectBackBtn:addClickEventListener(perfectBackEvent)
	-- self:MarkIntaractCObj(perfectBackBtn)
 --    local isCanFind = cellData.findTimes > 0
 --    perfectBackBtn:setVisible(isCanFind)
 --    normalBackBtn:setVisible(isCanFind)
 --    coin:setVisible(isCanFind)
 --    gold:setVisible(isCanFind)
 --    gainMark:setVisible(not isCanFind)

end

function FindOfflineExp:ShowFindDialog(cellData)
    -- body
    local function OKCallback()
        -- print("self._curBuyTimes", self._curBuyTimes, findTimes)
        -- if self._curBuyTimes <= 0 or self._curBuyTimes > findTimes then
        --     return
        -- end

        -- local shouldPay = cost * self._curBuyTimes
        local myValue = LRoleDataMgr:GetMoney(cellData.cost[1])
        if cellData.cost[3] > myValue then
            Utils:ShowScrollTips(string.format(GUITips.RSI_GS_TIP_RECOVERY_LIMIT,AppDef.AwrdItemName[cellData.cost[1]]))
            return
        end
        -- if findType == 1 then
        --     local myMoney = LRoleDataMgr.MyHeroInfo.DetailData:getMoney()
            
        -- else
        --     local myTongo = LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao()
        --     if shouldPay > myTongo then
        --         Utils:ShowScrollTips(GUITips.RSI_GS_TIP_RECOVERY_NOGOLD)
        --         return
        --     end
        -- end
        
        -- print("self._curBuyTimes", self._curBuyTimes)
        LuaNetSendMsg:QueryResRecovery(2, cellData.funcId, cellData.leftTimes)
    end

    local function cancelCallback()

    end
    Utils:ShowResRecovery(cellData, OKCallback, cancelCallback)
end

-- function FindOfflineExp:ShowFindDialog(findType, findId, findName, findTimes, cost, awardInfo)
--     -- body
--     local function OKCallback()
--         print("self._curBuyTimes", self._curBuyTimes, findTimes)
--         if self._curBuyTimes <= 0 or self._curBuyTimes > findTimes then
--             return
--         end

--         local shouldPay = cost * self._curBuyTimes
--         if findType == 1 then
--             local myMoney = LRoleDataMgr.MyHeroInfo.DetailData:getMoney()
--             if shouldPay > myMoney then
--                 Utils:ShowScrollTips(GUITips.RSI_GS_TIP_RECOVERY_NOCOIN)
--                 return
--             end
--         else
--             local myTongo = LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao()
--             if shouldPay > myTongo then
--                 Utils:ShowScrollTips(GUITips.RSI_GS_TIP_RECOVERY_NOGOLD)
--                 return
--             end
--         end
        
--         print("self._curBuyTimes", self._curBuyTimes)
--         LuaNetSendMsg:QueryResRecovery(2, findType, findId, self._curBuyTimes)
--     end

--     local function cancelCallback()

--     end
--     Utils:ShowResRecovery(findType, findName, findTimes, cost, awardInfo, OKCallback, cancelCallback)
-- end

function FindOfflineExp:ShowFindAllDialog( findType,  cost)
    -- body
    local function OKCallback()
        
        -- LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUIInBattle, "Welfare.GainRewardUI", AppDef.UIType.PopWindow)
        -- self:SendMsg(LGameMsg.m_initUIMsg)
        if cost <= 0 then
            return
        end
        LuaNetSendMsg:QueryResRecovery(3, findType)
    end

    local function cancelCallback()

    end
    Utils:ShowResRecoveryAll(findType, cost, OKCallback, cancelCallback)
end

function FindOfflineExp:refrashUI(isTurnToOffset)
    -- body
--    print("refrashUI 1111111111111111111111111111111", self._curBuyTimes)
    self._recoveryData = LRoleDataMgr.recoveryData;
    -- dump(LRoleDataMgr.recoveryData,"LRoleDataMgr.recoveryDataLRoleDataMgr.recoveryData");
    
-- --    print("offset =", self._offset.x, self._offset.y)
    if #LRoleDataMgr.recoveryData > 0 then
        self._offset = self.m_pExpTableView:getContentOffset()
        self.m_pExpTableView:reloadData()
        self._TextBg:setVisible(false)
    else
        if self.m_pExpTableView then
            self.m_pExpTableView:setVisible(false)
        end
        self._TextBg:setVisible(true)
    end
    
--     local size = #self._recoveryData.offlineListInfo
--     if size > 0 then
--         self._defaltBg:setVisible(false)
--     else
--         self._defaltBg:setVisible(true)
--     end
    
    if isTurnToOffset then
        self.m_pExpTableView:setContentOffset(self._offset)
    end
--     self._jinbiFind:setString(self._recoveryData.coinFindPay)
--     self._goldFind:setString(self._recoveryData.goldFindPay)
--     self._jinbiFind:setTextColor(self._jinbiColor)
--     local myMoney = LRoleDataMgr.MyHeroInfo.DetailData:getMoney()
--     if myMoney < self._recoveryData.coinFindPay then
--         self._jinbiFind:setTextColor(UICOLOR_RED)
--     end
--     self._goldFind:setTextColor(self._goldFindColor)
--     local myGold = LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao()
--     if myGold < self._recoveryData.goldFindPay then
--         self._goldFind:setTextColor(UICOLOR_RED)
--     end

--     if self._recoveryData.coinFindPay <= 0 then
--         self._jinbiFindBtn:setTouchEnabled(false)
--         self._jinbiFindBtn:setBright(false)
--     else
--         self._jinbiFindBtn:setTouchEnabled(true)
--         self._jinbiFindBtn:setBright(true)
--     end
        
--     if self._recoveryData.goldFindPay <= 0 then
--         self._goldFindBtn:setTouchEnabled(false)
--         self._goldFindBtn:setBright(false)
--     else
--         self._goldFindBtn:setTouchEnabled(true)
--         self._goldFindBtn:setBright(true)
--     end

end

function FindOfflineExp:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return FindOfflineExp