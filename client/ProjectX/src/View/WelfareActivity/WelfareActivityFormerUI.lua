local WelfareActivityFormerUI = LUIBase:New()
WelfareActivityFormerUI.__index = WelfareActivityFormerUI

local WelfareActivityDef = require("View.WelfareActivity.WelfareActivityDef")
-----------------------------------
function WelfareActivityFormerUI:New(openTab)
    local o = {}
    setmetatable(o, WelfareActivityFormerUI)
    o:Init(openTab)
    return o
end
-----------------------------------
function WelfareActivityFormerUI:Init(openTab)
    self.Script = "WelfareActivity.WelfareActivityFormerUI"
    --------------------------------------------------
    self.m_controlNodeList = {}
    self.m_pDelegates = {}
    self.m_pRankDelegate = nil
    self.m_openTab = openTab or 1
    --------------------------------------------------
    self.m_tableCount = 0
    self.m_isDragging = false
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_pTablePanel = nil
    self.m_datas = nil
    self.m_selectIndex = 0--从1开始
    --------------------------------------------------
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    self:RegisterQuik()
    LuaNetSendMsg:QueryWelFareInfo(0xff, 0)
end
-----------------------------------
function WelfareActivityFormerUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_pTablePanelOld = nil
    self.m_pTablePanel = nil
    self.m_pTableView = nil
    self.m_pGridCellOld = nil
    self.m_pGridCell = nil
    self.m_pRankingBg = nil
    self._bg = nil

    if self.m_pRankDelegate and self.m_pRankDelegate.onExit then
        self.m_pRankDelegate:onExit()
        self.m_pRankDelegate = nil
    end
    if self.m_pDelegates then
        for k,v in pairs(self.m_pDelegates) do
            if v and v.onExit then
                v:onExit()
            end
            self.m_pDelegates[k] = nil
        end
        self.m_pDelegates = nil
    end
    Utils:FreeTable(self.m_controlNodeList)
    self.m_controlNodeList = nil
    self.m_datas = nil
end

-----------------------------------
function WelfareActivityFormerUI:InitUIControl()
    local pPanel = self.m_pUILayer:getChildByName("Panel")
    pPanel:setLocalZOrder(1)
    ------------------------------------------------------
    self.m_pTablePanelOld = pPanel:getChildByName("BtnList")
    self.m_pTablePanelOld:setVisible(false)
    local bgPanel = self._bg:getChildByName("Panel")
    self.m_pTablePanel = bgPanel:getChildByName("BtnList")
    self.m_pTableView = self:InitTableView(self.m_pTablePanel)
    self.m_pGridCellOld = pPanel:getChildByName("Button1")
    self.m_pGridCell = self._bg:getChildByName("Panel"):getChildByName("Button1")
    self.m_pGridCell:setAnchorPoint(cc.p(0,0))
    self.m_pGridCell:setTouchEnabled(false)
    self.m_pGridCell:setVisible(false)
    ------------------------------------------------------
    local pRankingBg = pPanel:getChildByName("RankingBg")
    pRankingBg:setVisible(false)
    self.m_pRankingBg = pRankingBg

    local pChildren = pRankingBg:getChildren()
    for i=1,#pChildren do
        table.insert(self.m_controlNodeList, pChildren[i])
    end
    ------------------------------------------------------
    local bg = bgPanel:getChildByName("Bg")
    local closeBtn = bg:getChildByName("CloseBtn")
    local function closeEvent( sender )
        Utils:DeleteUI("WelfareActivity.WelfareActivityFormerUI")
    end
    closeBtn:addClickEventListener(closeEvent)
	self:MarkIntaractCObj(closeBtn)
end

-----------------------------------
function WelfareActivityFormerUI:RegistMsgs()
    self.msgIds = 
    {
        LUIWelfareActivityEvent.InitListData,
        LUIWelfareActivityEvent.ReloadData,
        LUIWelfareActivityEvent.ClosePopup,
        LUILogicEvent.DeleteUI,
        LUIRedDotEvent.UpdateRedDotState,
    }
    self:RegistSelf(self, self.msgIds)
end

-----------------------------------
function WelfareActivityFormerUI:ProcessEvent(msg)
    if msg.msgId == LUIWelfareActivityEvent.InitListData then
        self:ReloadListData(msg.value)
    elseif msg.msgId == LUIWelfareActivityEvent.ReloadData then
        self:ReloadData(msg.value)
    elseif msg.msgId == LUIWelfareActivityEvent.ClosePopup then
        self:RemoveUI()
    elseif msg.msgId == LUILogicEvent.DeleteUI then
        local script = msg.m_pScript
        local index = string.find(script, "%.")
        if index == nil then
            index = 0
        end
        local uiName = string.sub(script, index + 1)
        if uiName == 'BestStrongUI' then
            self:RemoveUI()
        end
    elseif msg.msgId == LUIRedDotEvent.UpdateRedDotState then
        if msg.value.id >= RedDotDef.ID.HDBase and msg.value.id <= RedDotDef.ID.HuoDongEnd then
            local offset = self.m_pTableView:getContentOffset()
            self.m_pTableView:reloadData()
            self.m_pTableView:setContentOffset(offset)
        end
    end
end
-----------------------------------
function WelfareActivityFormerUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    Utils:SendMsg(LUIFClassBgEvent.SetCloseCallback, handler(self, LUIBase.RemoveUI))
end
-----------------------------------
function WelfareActivityFormerUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/huodong/ActivityRankingLayer.csb")
    self.m_pUILayer:setVisible(false)
    self._bg = cc.CSLoader:createNode("csd/huodong/ActivityLevelLayer.csb")
    self._bg:setPosition(cc.p(0, 0))
    self.m_pUILayer:addChild(self._bg)

    self.m_pUILayer:setContentSize(AppDef.frameSize)
    self._bg:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
    ccui.Helper:doLayout(self._bg)
end
-- ----------------------------------
function WelfareActivityFormerUI:RegisterQuik()
    Utils:SendMsg(LUIFClassBgEvent.SetTitle, GUITips.RSI_WACT_TITLE)
    Utils:SendMsg(LUIFClassBgEvent.AddTabBtn, nil)
end
-----------------------------------
function WelfareActivityFormerUI:getDelegate(tag)
    if self.m_pRankDelegate == nil then
        local ActivityRankUI = require("View.WelfareActivity.ActivityRankUI")
        self.m_pRankDelegate = ActivityRankUI:New(self.m_pRankingBg)
    end

    if tag == WelfareActivityDef.Type.DengJiChongCiBang or 
           tag == WelfareActivityDef.Type.QunXianZhanLiBang or
           tag == WelfareActivityDef.Type.ZuiQiangShenChongBang or
           tag == WelfareActivityDef.Type.XianJiaQiangHuaBang or
           tag == WelfareActivityDef.Type.ShenJiYuYiBang or
           tag == WelfareActivityDef.Type.XinFuChongZhiBang or
           tag == WelfareActivityDef.Type.XianHuaBang then
            if self.m_pDelegates[tag] == nil then
                self.m_pDelegates[tag] = self.m_pRankDelegate
            end
        self.m_pDelegates[tag]:setTag(tag)
    elseif (tag == WelfareActivityDef.Type.RechargeGift or tag == WelfareActivityDef.Type.RechargeGift_copy1 or
                    tag == WelfareActivityDef.Type.RechargeGift_copy2 or tag == WelfareActivityDef.Type.RechargeGift_copy3 ) then -- 充值送礼
        tag = WelfareActivityDef.Type.RechargeGift
        if self.m_pDelegates[tag] == nil then
            local RechargeGiftUI = require("View.WelfareActivity.RechargeGiftUI")
            self.m_pDelegates[tag] = RechargeGiftUI:New(self.m_pRankingBg)
        end
    elseif (tag == WelfareActivityDef.Type.ConsumptionGift or tag == WelfareActivityDef.Type.ConsumptionGift_copy1) then --累计消费
        tag = WelfareActivityDef.Type.ConsumptionGift
        if self.m_pDelegates[tag] == nil then
            local ConsumptionGiftUI = require("View.WelfareActivity.ConsumptionGiftUI")
            self.m_pDelegates[tag] = ConsumptionGiftUI:New(self.m_pRankingBg)
        end
    elseif tag == WelfareActivityDef.Type.MeiRiShouChong and self.m_pDelegates[tag] == nil then
        local DailyRechargeUI = require("View.WelfareActivity.DailyRechargeUI")
        self.m_pDelegates[tag] = DailyRechargeUI:New(self.m_pUILayer)
    elseif (tag == WelfareActivityDef.Type.SevenDaysChargeTag or tag == WelfareActivityDef.Type.SevenDaysChargeTag_copy1 or tag == WelfareActivityDef.Type.SevenDaysChargeTag_copy2
          or tag == WelfareActivityDef.Type.SevenDaysChargeTag_copy3 or tag == WelfareActivityDef.Type.SevenDaysChargeTag_copy4) then
        tag = WelfareActivityDef.Type.SevenDaysChargeTag
        if self.m_pDelegates[tag] == nil then
            local SevenDaysCharge = require("View.WelfareActivity.SevenDaysCharge")
            self.m_pDelegates[tag] = SevenDaysCharge:New(self.m_pUILayer)
        end
    elseif tag == WelfareActivityDef.Type.PetDiscount and self.m_pDelegates[tag] == nil then
        local PetDiscountUI = require("View.WelfareActivity.PetDiscountUI")
        self.m_pDelegates[tag] = PetDiscountUI:New(self.m_pUILayer)
    elseif tag == WelfareActivityDef.Type.NationalDayGift and self.m_pDelegates[tag] == nil then
        local NationalDayGiftUI = require("View.WelfareActivity.NationalDayGiftUI")
        self.m_pDelegates[tag] = NationalDayGiftUI:New(self.m_pUILayer)
    elseif tag ==  WelfareActivityDef.Type.NationDayCollectWord and self.m_pDelegates[tag] == nil then
        local NationalCollectWordUI = require("View.WelfareActivity.NationalCollectWordUI")
        self.m_pDelegates[tag] = NationalCollectWordUI:New(self.m_pUILayer)
    end
    return self.m_pDelegates[tag]
end

function WelfareActivityFormerUI:TabClicked(ind)
    -- print("TabClicked ====>", ind)
    if ind == self.m_selectIndex then
        return
    end
    self:Reset()
    local data = self.m_datas[self.m_selectIndex]
    if data then
        local pDelegate = self:getDelegate(data.tag)
        local _ = pDelegate and pDelegate.Reset and pDelegate:Reset()
    end
    local data = self.m_datas[ind]
    -- print("TabClicked --------------------------------", data.tag, ind)
    -- dump(data, "TabClicked")
    if data and data.tag then
        local pDelegate = self:getDelegate(data.tag)
        if pDelegate then
            pDelegate:initData()
        elseif data.tag == WelfareActivityDef.Type.ZaDan or data.tag == WelfareActivityDef.Type.ZaDan2 or data.tag == WelfareActivityDef.Type.ZaDan_Copy1
         or data.tag == WelfareActivityDef.Type.ZaDan_Copy2 or data.tag == WelfareActivityDef.Type.ZaDan_Copy3 or data.tag == WelfareActivityDef.Type.ZaDan_Copy4 then
            performWithDelay(self.m_pUILayer, function(sender)
                self:RemoveUI()
            end, 0.1)
            Utils:DeleteUI("WelfareActivity.ZaDanUI")
            Utils:InitUI("WelfareActivity.ZaDanUI", AppDef.UIType.PopWindow, data.tag)
        end
    end
    LRedDotCheckMgr:MainHuodongCheck(ind)
end

function WelfareActivityFormerUI:Reset()
    self.m_pRankingBg:setVisible(false)

    if self.m_controlNodeList then
        for i=1,#self.m_controlNodeList do
            self.m_controlNodeList[i]:setVisible(false)
        end
    end
end

function WelfareActivityFormerUI:InitTableView(tbPanel)
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
        return self.m_tableCount
    end

    cfg.scrollViewDidScroll = function(view)
        self.m_isDragging = view:isDragging()
    end

    cfg.tableCellTouched = function(view, cell)
        self:tableCellTouched(cell:getIdx()+1)
    end

    return Utils:createTableView(cfg)
end

function WelfareActivityFormerUI:TableCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild = nil
    
    if cell == nil then
        cell = cc.TableViewCell:new()
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
        self:updateItem(cellChild, self.m_datas[idx+1], idx+1)
    end
    return cell
end

function WelfareActivityFormerUI:tableCellTouched(idx, updateImmediately)
    if ind == self.m_selectIndex then
        return
    end
    self:TabClicked(idx)
    self.m_selectIndex = idx
    if updateImmediately then
        self.m_pTableView:reloadData()
    else
        performWithDelay(self.m_pUILayer, function(dt)
            local offset = self.m_pTableView:getContentOffset()
            self.m_pTableView:reloadData()
            self.m_pTableView:setContentOffset(offset)
        end, 1/30)
    end
end

function WelfareActivityFormerUI:updateItem(cell, info, idx)
    local pChooseBg = cell:getChildByName("ChooseBg")
    pChooseBg:setVisible(idx == self.m_selectIndex)

    local pBtnName = cell:getChildByName("BtnName")
    pBtnName:setString(info.uname and info.uname or "")

    local prompt = cell:getChildByName("Prompt")
    prompt:setVisible(Utils:GetRedDotState(RedDotDef.ID.HDBase + idx))
end

function WelfareActivityFormerUI:ReloadData(value)
    local tag = value[1]
    if type(self.m_datas) == 'table' then
        local data = self.m_datas[self.m_selectIndex]
        local curTag = ((data and data.tag) and {data.tag} or 0)[1]
        print("ReloadData ==> 11111", tag, curTag)
        if curTag and self:IsSameActivity(tag, curTag) then
            local pDelegate = self:getDelegate(tag)
            local _ = pDelegate and pDelegate:updateData(value[2])
        end
    end
end

function WelfareActivityFormerUI:IsSameActivity( tag,  curTag)
    -- body
    if(curTag == WelfareActivityDef.Type.SevenDaysChargeTag_copy1 or curTag == WelfareActivityDef.Type.SevenDaysChargeTag_copy2
          or curTag == WelfareActivityDef.Type.SevenDaysChargeTag_copy3 or curTag == WelfareActivityDef.Type.SevenDaysChargeTag_copy4) then
        curTag = WelfareActivityDef.Type.SevenDaysChargeTag
    end

    if (curTag == WelfareActivityDef.Type.RechargeGift_copy1 or curTag == WelfareActivityDef.Type.RechargeGift_copy2
          or curTag == WelfareActivityDef.Type.RechargeGift_copy3) then
        curTag = WelfareActivityDef.Type.RechargeGift
    end
    
    if (curTag == WelfareActivityDef.Type.ConsumptionGift_copy1) then
        curTag = WelfareActivityDef.Type.ConsumptionGift
    end
    return tag == curTag
end

function WelfareActivityFormerUI:ReloadListData(list)
    self.m_pUILayer:setVisible(true)
    self.m_datas = nil
    self.m_datas = list
    self.m_tableCount = #self.m_datas
    self:tableCellTouched(self.m_openTab, true)
    Utils:MoveToTableIdx(self.m_pTableView, self.m_pGridCell, self.m_openTab - 1)
end 


return WelfareActivityFormerUI