local WelfareActivityDef = require("View.WelfareActivity.WelfareActivityDef")

local RechargeGiftUI = LUIBase:New()
RechargeGiftUI.__index = RechargeGiftUI

local g_cellTag = 0
local m_pTableView = nil
local m_tableCount = 0
local m_isDragging = false
local m_datas = nil
----------------------------------------------------------------------
function RechargeGiftUI:New(uiLayer)
    local o = LUIBase:New()
    setmetatable(o, RechargeGiftUI)
    o:Init(uiLayer)
    return o
end

----------------------------------------------------------------------
function RechargeGiftUI:Init(uiLayer)
    self.Script = "WelfareActivity.RechargeGiftUI"
    ----------------------------------------------------------------------
    self.m_pUILayer = uiLayer
    self.m_pTimeBg = nil
    self.m_vecHeroInfo = nil
    ----------------------------------------------------------------------
    self.m_pGridCell = nil
    self.m_pTablePanel = nil
    self:RegistMsgs()
    ----------------------------------------------------------------------
    self:InitUIControl()
    self:setCloseCallback()
end

----------------------------------------------------------------------
function RechargeGiftUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    m_pTableView = nil
    m_tableCount = 0
    m_isDragging = false
    m_datas = nil
end

----------------------------------------------------------------------
function RechargeGiftUI:InitUIControl()
    local pPanel = self.m_pUILayer
    Utils:setVisible(pPanel, "PowerBg", false)
    local pRechargeBg = pPanel:getChildByName("RechargeBg")
    pRechargeBg:setVisible(true)

    self.m_pTime = pRechargeBg:getChildByName("Time"):getChildByName("Text_1")
    local text = self.m_pTime:getChildByName("Text_2")
    text:setVisible(false)
    
    
    local desc = pRechargeBg:getChildByName("Desc")
    desc:getChildByName("Text"):setString(GUITips.RSI_RECHARGE_TIP3)
    desc:setString(GUITips.RSI_RECHARGE_TIP9)
    local bg = pRechargeBg:getChildByName("Bg")
    bg:getChildByName("Text"):setString(GUITips.RSI_RECHARGE_TIP5)
    -- 充值数量
    self.m_pRechargeValue = bg:getChildByName("Value")
    ----------------------------------------------------------------------
    local pButton = pRechargeBg:getChildByName("RechargeBtn")
    pButton:getChildByName("Text"):setString(GUITips.RSI_RECHARGE_TIP8)
    pButton:addClickEventListener(handler(self, RechargeGiftUI.RechargeClick))
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
    if m_pTableView == nil then
        m_pTableView = self:InitTableView(self.m_pTablePanel)
    end

    local tips = self.m_pUILayer:getChildByName("Tips")
    tips:setVisible(true)
end

function RechargeGiftUI:initData()
    self._awardIndex = 0
    LuaNetSendMsg:QueryTotalCost(20, 0)

end
----------------------------------------------------------------------
function RechargeGiftUI:setCloseCallback()
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
function RechargeGiftUI:InitTableView(tbPanel)
    local cfg = {}
    cfg.tbPanel = tbPanel
    cfg.cellSizeForTable = function(sender,idx)
        local width = self.m_pGridCell:getContentSize().width
        local height = self.m_pGridCell:getContentSize().height
        return width, height
    end
    cfg.tableCellAtIndex = function(sender, idx)
        return self:TableCellAtIndex(sender, idx)
    end

    cfg.numberOfCellsInTableView = function()
        return m_tableCount
    end

    cfg.scrollViewDidScroll = function(view)
        m_isDragging = view:isDragging()
    end

    return Utils:createTableView(cfg)
end
----------------------------------------------------------------------
function RechargeGiftUI:TableCellAtIndex(sender, idx)
    idx = idx + 1
    local cell = sender:dequeueCell()
    local cellChild = nil
    
    if cell == nil then
        g_cellTag = g_cellTag + 1
        cell = cc.TableViewCell:new()
        cell:setTag(g_cellTag)

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

--注册事件
-- -----------------------------------
function RechargeGiftUI:RegistMsgs()
    self.msgIds = 
    {
        LUIWelfareActivityEvent.updateRechargeUI,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function RechargeGiftUI:ProcessEvent(msg)
    if msg.msgId == LUIWelfareActivityEvent.updateRechargeUI then
        self:upAfterAwardUI()
    end
end

function RechargeGiftUI:ShowItem(cell, idx)
	local awards = LRoleDataMgr.MyHeroInfo.m_pRechargetGift
	local award = awards.awardInfo[idx]
    if award == nil then
        return
    end
	local bg = cell:getChildByName("Num_1")
	bg:getChildByName("Text"):setString(GUITips.RSI_RECHARGE_TIP10)
	bg:getChildByName("IconImage"):getChildByName("Value"):setString(tostring(award.yubao))

	local get = cell:getChildByName("ReceiveImage")
	local button = cell:getChildByName("Button")
    button:setTag(award.index)
    function giftButtonTouch(sender)
        self._selectId = sender:getTag()
        LuaNetSendMsg:QueryReChargeInfo(20, 1, sender:getTag())
    end
    button:addClickEventListener(giftButtonTouch)
	self:MarkIntaractCObj(button)
    --[[
    按钮显示
    ]]
    --dump(awards, "ShowItem -----------------")
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
         
            Utils:ShowPet(data.id, listView, awardUI, false,data.star)
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
function RechargeGiftUI:honorButtonClick(sender)
    local tag = sender:getTag()
end

function RechargeGiftUI:updateData(data)
    self:InitUIControl()
	local info = LRoleDataMgr.MyHeroInfo.m_pRechargetGift
	self.m_pTime:setString(info.desTime)
	self.m_pRechargeValue:setString(tostring(info.chongzhi))
    self.m_pTablePanel:setVisible(true)
    m_pTableView:setVisible(true)
    m_tableCount = #info.awardInfo
    m_pTableView:reloadData()
    self.m_pUILayer:setVisible(true)
end

----------------------------------------------------------------------
function RechargeGiftUI:updateTop()
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

function RechargeGiftUI:checkNode(pNode)
    if pNode == nil then
        return false
    end
    pNode:setVisible(true)
    return true
end

function RechargeGiftUI:RechargeClick(sender)
    LuaNetSendMsg:QueryPayPriceList()
end

function RechargeGiftUI:Reset()
    local _ = m_pTableView and m_pTableView:setVisible(false)
end

function RechargeGiftUI:upAfterAwardUI( ... )
    -- body
    if self._selectId == nil then
        return
    end
    local awards = LRoleDataMgr.MyHeroInfo.m_pRechargetGift
    local award = awards.awardInfo[self._selectId + 1]
    award.isGetAward = true 
    local offset = m_pTableView:getContentOffset()
    m_pTableView:reloadData()
    m_pTableView:setContentOffset(offset)
--刷新小红点
    LGameMsg.m_baseMsg:ChangeEventId(LUIWelfareActivityEvent.UpdateRedDot)
    self:SendMsg(LGameMsg.m_baseMsg)
end 

return RechargeGiftUI
