local ShopDef = require("View.Shop.ShopDef")
local WelfareActivityDef = require("View.WelfareActivity.WelfareActivityDef")

local ConsumptionGiftUI = LUIBase:New()
ConsumptionGiftUI.__index = ConsumptionGiftUI


function ConsumptionGiftUI:New(uiLayer)
    local o = LUIBase:New()
    setmetatable(o, ConsumptionGiftUI)
    o:Init(uiLayer)
    return o
end

----------------------------------------------------------------------
function ConsumptionGiftUI:Init(uiLayer)
    self.m_pUILayer = uiLayer
    self.m_pTimeBg = nil
    self.m_vecHeroInfo = nil
    ----------------------------------------------------------------------
    self.m_pGridCell = nil
    self.m_pTablePanel = nil
    self.m_pTableView = nil
    self.m_tableCount = 0
    ----------------------------------------------------------------------

    self:RegistMsgs()
    self:InitUIControl()
    self:InitTableView()
    self:setCloseCallback()
end


--[[
注册消息
]]
function ConsumptionGiftUI:RegistMsgs()
    self.msgIds = 
    {
        LUIWelfareActivityEvent.updateConsumAwardUI
    }
    self:RegistSelf(self,self.msgIds)
end

function ConsumptionGiftUI:ProcessEvent(msg)
   if msg.msgId == LUIWelfareActivityEvent.updateConsumAwardUI then
        self:upAfterAwardUI()
    end
end

----------------------------------------------------------------------
function ConsumptionGiftUI:onExit()
    self.m_pUILayer = nil
    self.m_pTableView = nil
    self.m_tableCount = nil
    --print("ConsumptionGiftUI:onExit ================================================")
    self:Destory()
end

----------------------------------------------------------------------
function ConsumptionGiftUI:InitUIControl()
    --print("ConsumptionGiftUI:InitUIControl --------------------------------------------")
    local pPanel = self.m_pUILayer
    Utils:setVisible(pPanel, "PowerBg", false)
    local pRechargeBg = pPanel:getChildByName("RechargeBg")
    pRechargeBg:setVisible(true)

    self.m_pTime = pRechargeBg:getChildByName("Time"):getChildByName("Text_1")
    local text = self.m_pTime:getChildByName("Text_2")
    text:setVisible(false)

    local desc = pRechargeBg:getChildByName("Desc")
    desc:getChildByName("Text"):setString(GUITips.RSI_RECHARGE_TIP4)
    desc:setString(GUITips.RSI_RECHARGE_TIP9)
    local bg = pRechargeBg:getChildByName("Bg")
    bg:getChildByName("Text"):setString(GUITips.RSI_RECHARGE_TIP6)
    -- 充值数量
    self.m_pRechargeValue = bg:getChildByName("Value")
    ----------------------------------------------------------------------

    local pButton = pRechargeBg:getChildByName("RechargeBtn")
    pButton:getChildByName("Text"):setString(GUITips.RSI_RECHARGE_TIP7)
    pButton:addClickEventListener(handler(self, ConsumptionGiftUI.RechargeClick))
	self:MarkIntaractCObj(pButton)
    ----------------------------------------------------------------------
    self.m_pTablePanel = pPanel:getChildByName("List")
    self.m_pTablePanel:setVisible(true)
    self.m_pTablePanel:setTouchEnabled(false)
    ----------------------------------------------------------------------
    self.m_pGridCell = pPanel:getChildByName("Recharge")
    self.m_pGridCell:setAnchorPoint(cc.p(0,0))
    self.m_pGridCell:setTouchEnabled(false)
    self.m_pGridCell:setVisible(false)
    self.m_pPetCell = self.m_pGridCell:getChildByName("IconColor")
    self.m_pPetCell:setVisible(false)
    self.m_pItemCell = self.m_pGridCell:getChildByName("IconBg_1")
    self.m_pItemCell:setVisible(false)
    ----------------------------------------------------------------------

    local tips = self.m_pUILayer:getChildByName("Tips")
    tips:setVisible(true)
end

function ConsumptionGiftUI:initData()
    LuaNetSendMsg:QueryTotalCost(21, 0)
end
----------------------------------------------------------------------
function ConsumptionGiftUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    local node = cc.Node:create()
    self.m_pUILayer:addChild(node)
    node:registerScriptHandler(onNodeEvent)
end
----------------------------------------------------------------------
function ConsumptionGiftUI:InitTableView()

    local tableView = cc.TableView:create(self.m_pTablePanel:getContentSize())
    
    tableView:setContentSize(self.m_pTablePanel:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(cc.p(0, 0))
    tableView:setPosition(cc.p(0, 0))
    tableView:setDelegate()
    tableView:setSwallowsTouches(true)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.m_pTablePanel:addChild(tableView)

    local function tableCellTouched(sender,cell)
        
    end

    local function  cellSizeForTable (sender,idx)
        local width = self.m_pGridCell:getContentSize().width
        local height = self.m_pGridCell:getContentSize().height
        return width, height
    end

    local function tableCellAtIndex(sender, idx)
        return self:TableCellAtIndex(sender, idx)
    end


    local function numberOfCellsInTableView() 
        return self.m_tableCount
    end

    local function scrollViewDisScroll(view)
        self.m_isDragging = view:isDragging()
    end

    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量
    tableView:registerScriptHandler(scrollViewDisScroll, cc.SCROLLVIEW_SCRIPT_SCROLL)

    self.m_pTableView = tableView 
end
----------------------------------------------------------------------
function ConsumptionGiftUI:TableCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild = nil
    
    if cell == nil then
        cell = cc.TableViewCell:new()
        cell:setTag(idx)

        cellChild = self.m_pGridCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)
    else
        cellChild = cell:getChildByTag(123)
    end
    if cellChild ~= nil then
        self:ShowItem(cellChild, idx)
    end
    return cell
end

function ConsumptionGiftUI:ShowItem(cell, idx)
	local awards = LRoleDataMgr.m_consumptionGiftData
    -- dump(awards, "ShowItem ----------------")
	local award = awards.awardInfo[idx + 1]

	local bg = cell:getChildByName("Num_1")
	bg:getChildByName("Text"):setString(GUITips.RSI_RECHARGE_TIP11)
	bg:getChildByName("IconImage"):getChildByName("Value"):setString(tostring(award.yubao))

	local get = cell:getChildByName("ReceiveImage")
	local button = cell:getChildByName("Button")
    button:setTag(award.index)
    function giftButtonTouch(sender)
        if self.m_isDragging then
            return
        end
        self._selectId = sender:getTag()
        LuaNetSendMsg:QueryReChargeInfo(21, 1, self._selectId)
    end
    button:addClickEventListener(giftButtonTouch)
	self:MarkIntaractCObj(button)
    --[[
    按钮显示
    ]]
    if awards.chongzhi >= award.yubao then
        if award.isGetAward then  -- 可以领
            get:setVisible(true)
            button:setVisible(false)
        else
            button:setVisible(true)
            button:setTouchEnabled(true)
            button:setBright(true)
            get:setVisible(false)
        end
    else
        get:setVisible(false)
        button:setVisible(true)
        button:setBright(false)
    end

    --[[
    礼物显示
    ]]
    local listView = cell:getChildByName("ListView_1")
    listView:setSwallowTouches(false)
    listView:removeAllItems()
    for i= 1, #award.awardItemId do
        local itemId = award.awardItemId[i]
        local data = award.awardPet[i]
        local awardUI
        if itemId == AppDef.AwrdItem.AWRD_ITEM_PET then
            awardUI = self.m_pPetCell:clone()
            awardUI:setVisible(true)
            Utils:ShowPet(data.id, listView, awardUI, false)
            if data.quality >= 3 then
                local posX = awardUI:getContentSize().width / 2
                local posY = awardUI:getContentSize().height / 2
                Utils:createAnimEffect(awardUI, cc.p(posX, posY), "res2/fx/gaojiwupin")
            end
        else
            awardUI = self.m_pItemCell:clone()
            awardUI:setVisible(true)
            local item = Utils:GetItemCellValue(awardUI, 0, itemId, true, true, award.awardItemNum[i], nil, true)
            local quality = Utils:getQualityByItem(item)
            if quality >= 5 then
                local posX = awardUI:getContentSize().width / 2
                local posY = awardUI:getContentSize().height / 2
                Utils:createAnimEffect(awardUI, cc.p(posX, posY), "res2/fx/gaojiwupin")
            end
        end
        listView:pushBackCustomItem(awardUI)
    end
end

----------------------------------------------------------------------
function ConsumptionGiftUI:honorButtonClick(sender)
    local tag = sender:getTag()
end

function ConsumptionGiftUI:updateData(data)
    self:InitUIControl();
	local info = LRoleDataMgr.m_consumptionGiftData
	self.m_pTime:setString(info.desTime)
	self.m_pRechargeValue:setString(tostring(info.chongzhi))
    self.m_pTablePanel:setVisible(true)
    self.m_pTableView:setVisible(true)
    self.m_tableCount = #info.awardInfo
    self.m_pTableView:reloadData()
    local _ = self.m_pUILayer and self.m_pUILayer:setVisible(true)
end

----------------------------------------------------------------------
function ConsumptionGiftUI:updateTop()
    local pPowerBg = self.m_pUILayer:getChildByName("PowerBg")
    pPowerBg:setVisible(true)
    ------------------------------------------------------------------
    local pButton = pPowerBg:getChildByName("Button")
    do
        local _ = self:checkNode(self.m_pTimeBg)
        self:updateTime(self.m_pTimeBg, self.m_result.desc, self.m_result.state)
        local pNode = pPowerBg:getChildByName("MyRanking")
        local _ = self:checkNode(pNode) and self:updateMyRank(pNode, self.m_result.my_paihang or 0)
    end
end

function ConsumptionGiftUI:checkNode(pNode)
    if pNode == nil then
        return false
    end
    pNode:setVisible(true)
    return true
end

function ConsumptionGiftUI:RechargeClick(sender)
    Utils:OpenShop(ShopDef.MK_TP.CHANGYONG)
end

function ConsumptionGiftUI:Reset()
    local _ = self.m_pUILayer and self.m_pUILayer:setVisible(false)
end

function ConsumptionGiftUI:upAfterAwardUI( ... )
    -- body
    if self._selectId == nil then
        return
    end
    local awards = LRoleDataMgr.m_consumptionGiftData
    local award = awards.awardInfo[self._selectId + 1]
    award.isGetAward = true
    local offset = self.m_pTableView:getContentOffset()
    self.m_pTableView:reloadData()
    self.m_pTableView:setContentOffset(offset)
--刷新小红点
    LGameMsg.m_baseMsg:ChangeEventId(LUIWelfareActivityEvent.UpdateRedDot)
    self:SendMsg(LGameMsg.m_baseMsg)
end


return ConsumptionGiftUI
