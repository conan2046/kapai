--[[
福利界面
]]
local LimitGaChaActivity = LUIBase:New()
LimitGaChaActivity.__index = LimitGaChaActivity

local WelfareActivityDef = require("View.WelfareActivity.WelfareActivityDef")
-----------------------------------
function LimitGaChaActivity:New(openTab)
    local o = {}
    setmetatable(o, LimitGaChaActivity)
    o:Init(openTab)
    return o
end
-----------------------------------
function LimitGaChaActivity:Init(openTab)
    self.Script = "WelfareActivity.LimitGaChaActivity"
    --------------------------------------------------
    self:InitData(openTab);
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:InitTabBtn();
    self:InitTouchEvt();
    self:RegisterQuik();
    self:ShowCurTab();

    self:ShowMoney();
    self:ShowTongbao();
    self:ShowTili();
    self:OnEnter();
    -- LuaNetSendMsg:QueryWelFareInfo(0xff, 0)
end

function LimitGaChaActivity:InitData(openTab)
    self.m_tabData = {};
    self._funcConfigs = {}

    --test code
    local data = {}
    data.tag = WelfareActivityDef.Type.RechargeGift
    data.uname = "充值送礼"
    data.state = 1
    data.newMask = 0
    data.endTime = LDataConstMgr.m_serverTime + 100000
    table.insert(self._funcConfigs, data)

    local data2 = {}
    data2.tag = WelfareActivityDef.Type.ConsumptionGift
    data2.uname = "消费送礼"
    data2.state = 1
    data2.newMask = 0
    data2.endTime = LDataConstMgr.m_serverTime + 5000

    table.insert(self._funcConfigs, data2)

    local data3 = {}
    data3.tag = WelfareActivityDef.Type.SevenDaysChargeTag
    data3.uname = "七日连冲"
    data3.state = 1
    data3.newMask = 0
    data3.endTime = LDataConstMgr.m_serverTime + 100000
    table.insert(self._funcConfigs, data3)

    self.m_controlNodeList = {}
    self.m_pDelegates = {}
    self.m_pRankDelegate = nil
    self.m_openTab = openTab or 1
    self.curOpenTag = self._funcConfigs[self.m_openTab].tag
    --------------------------------------------------
    self.m_tableCount = 0
    self.m_isDragging = false
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_pTablePanel = nil
    self.m_datas = nil
    self.m_selectIndex = 0--从1开始
end
-----------------------------------
function LimitGaChaActivity:onExit()
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
    self.m_pDailyRechargeNode = nil
    self.m_pSevenRechargeNode = nil
    self.m_datas = nil
end

-----------------------------------
function LimitGaChaActivity:InitUIControl()
    self.m_pTabNodeCell = self.m_pUILayer:findChildByName("Panel_1/Btn_ListView/Panel_1");
    self.m_pListView = self.m_pUILayer:findChildByName("Panel_1/Btn_ListView");

    --test code
    self.m_pRankingBg = self.m_pUILayer
end

-----------------------------------
function LimitGaChaActivity:RegistMsgs()
    self.msgIds = 
    {
        LUIWelfareActivityEvent.InitListData,
        LUIWelfareActivityEvent.ReloadData,
        LUIWelfareActivityEvent.ClosePopup,
        LUILogicEvent.DeleteUI,
        LUIRedDotEvent.UpdateRedDotState,
        LUIRoleDataChangeEvent.MoneyChanged,
        LUIRoleDataChangeEvent.TongBaoChanged,
        LUIRoleDataChangeEvent.TiliChanged,
    }
    self:RegistSelf(self, self.msgIds)
end

-----------------------------------
function LimitGaChaActivity:ProcessEvent(msg)
    if msg.msgId == LUIRoleDataChangeEvent.MoneyChanged then
        self:ShowMoney()
    elseif msg.msgId == LUIRoleDataChangeEvent.TongBaoChanged then
        self:ShowTongbao()
    elseif msg.msgId == LUIRoleDataChangeEvent.TiliChanged then
        self:ShowTili()
    elseif msg.msgId == LUIWelfareActivityEvent.InitListData then
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
        self:UpdateRedDot(msg.value)
    end
end

function LimitGaChaActivity:UpdateRedDot(data)
    self:DealUpdateRedDotState(data)
end

function LimitGaChaActivity:OnEnter()
    local function initRedDotState(id)
        local isShow = Utils:GetRedDotState(id)
        self:DealUpdateRedDotState({id=id, isShow=isShow})
    end
    initRedDotState(RedDotDef.ID.Fuli_Tili);
    initRedDotState(RedDotDef.ID.Fuli_ResRecovery);
end

function LimitGaChaActivity:DealUpdateRedDotState(data)
    local ind = 0
    if data.id == RedDotDef.ID.Fuli_Tili then
        self.m_pTabBtns[1]:getChildByName("Prompt"):setVisible(data.isShow)
    elseif data.id == RedDotDef.ID.Fuli_ResRecovery then
        self.m_pTabBtns[2]:getChildByName("Prompt"):setVisible(data.isShow)
    end
end

-----------------------------------
function LimitGaChaActivity:InitTouchEvt()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    
    local function closeCallback()
        self:RemoveUI()
    end
    local btn = self.m_pUILayer:findChildByName("Panel_1/Title/CloseBtn");
    btn:addClickEventListener(closeCallback);

    btn = self.m_pUILayer:findChildByName("Panel_1/GoldCheck/GoldIcon1/AddBtn");
    btn:addClickEventListener(function(sender)
        self:onTiliClicked();
    end)

    btn = self.m_pUILayer:findChildByName("Panel_1/GoldCheck/GoldIcon3/AddBtn");
    btn:addClickEventListener(function(sender)
        self:onMoneyClicked();
    end)

    btn = self.m_pUILayer:findChildByName("Panel_1/GoldCheck/GoldIcon4/AddBtn");
    btn:setEnabled(false)
end

function LimitGaChaActivity:onTiliClicked()
    Utils:OpenUseUI(500,1)
end

function LimitGaChaActivity:onMoneyClicked()
    print("onMoneyClicked")
    Utils:OpenFunction(AppDef.EModuleID.EMID_SCCHANGYONG)
end

function LimitGaChaActivity:onYuanbaoClicked()
    print("onYuanbaoClicked")
end
-----------------------------------
function LimitGaChaActivity:InitViewSize()
    self:CreateUINode("csd/huodong/huodong_bg.csb")
end

function LimitGaChaActivity:ShowTili()
    local moneyLabel = self.m_pUILayer:findChildByName("Panel_1/GoldCheck/GoldIcon1/GoldNumBg/Num");
    local myTili = LRoleDataMgr.MyHeroInfo:GetDetailData():getTili()
    moneyLabel:setString(Utils:getTiliStr(myTili))
end

function LimitGaChaActivity:ShowTongbao()
    local moneyLabel = self.m_pUILayer:findChildByName("Panel_1/GoldCheck/GoldIcon4/GoldNumBg/Num");
    local myGold = LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao()
    moneyLabel:setString(myGold)
end

function LimitGaChaActivity:ShowMoney()
    local moneyLabel = self.m_pUILayer:findChildByName("Panel_1/GoldCheck/GoldIcon3/GoldNumBg/Num");
    local myMoney = Utils:getGoldStr()
    moneyLabel:setString(myMoney)
end

function LimitGaChaActivity:InitTabBtn()
    local function tabBtnClicked(sender)
        local ind = sender.userData;
        self:TabBtnClicked(ind);
    end
    self.m_pTabBtns = {}
    for i = 1, #self._funcConfigs do
        local data = self._funcConfigs[i];
        local btnNode = nil;
        if i == 1 then
            btnNode = self.m_pTabNodeCell;
        else
            btnNode = self.m_pTabNodeCell:clone();
            self.m_pListView:pushBackCustomItem(btnNode);
        end
        local btn = btnNode:findChildByName("Button");
        btn.userData = i
        data.name = "累计充值"
        btnNode:findChildByName("Button/BtnName"):setString(data.uname);
        btnNode:findChildByName("Button/ChooseBg/BtnName"):setString(data.uname);
        btn:addClickEventListener(tabBtnClicked);
        table.insert(self.m_pTabBtns,btn);
    end
end

function LimitGaChaActivity:TabBtnClicked(ind)
    if self.m_openTab == ind then
        return
    end
    if self.m_pDelegates[self.curOpenTag] then
        self.m_pDelegates[self.curOpenTag]:setVisible(false);
    end
    self.m_openTab = ind
    self.curOpenTag = self._funcConfigs[self.m_openTab].tag
    self:ShowCurTab()
end

function LimitGaChaActivity:SetBtnState()
    local redArr = {RedDotDef.ID.Fuli_Tili,RedDotDef.ID.Fuli_ResRecovery}
    for i = 1, #self.m_pTabBtns do
        if i == self.m_openTab then
            self.m_pTabBtns[i]:getChildByName("ChooseBg"):setVisible(true);
            self.m_pTabBtns[i]:setTouchEnabled(false);
            self.m_pTabBtns[i]:getChildByName("Prompt"):setVisible(false);
        else
            self.m_pTabBtns[i]:getChildByName("ChooseBg"):setVisible(false);
            self.m_pTabBtns[i]:setTouchEnabled(true);
            local isShow = Utils:GetRedDotState(redArr[i])
            self:DealUpdateRedDotState({id=redArr[i], isShow=isShow})
        end
    end
end

function LimitGaChaActivity:ShowCurTab()
    self:SetBtnState()
    if self:getDelegate(self.curOpenTag) then
        self:getDelegate(self.curOpenTag):setVisible(true)
    end
end

-- ----------------------------------
function LimitGaChaActivity:RegisterQuik()
    Utils:SendMsg(LUIFClassBgEvent.SetTitle, GUITips.RSI_WACT_TITLE)
    Utils:SendMsg(LUIFClassBgEvent.AddTabBtn, nil)
end
-----------------------------------
function LimitGaChaActivity:getDelegate(tag)

    print("LimitGaChaActivity:getDelegate ==== tag>", tag)

    if self.m_pRankDelegate == nil then
        local ActivityRankUI = require("View.WelfareActivity.ActivityRankUI")
        --排行榜暂时删掉了
        -- self.m_pRankDelegate = ActivityRankUI:New(self.m_pRankingBg)
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
    elseif tag == WelfareActivityDef.Type.RechargeGift and self.m_pDelegates[tag] == nil then -- 充值送礼
        local RechargeGiftUI = require("View.WelfareActivity.RechargeGiftUI")
        -- self.m_pDelegates[tag] = RechargeGiftUI:New(self.m_pRankingBg)
    elseif tag == WelfareActivityDef.Type.ConsumptionGift and self.m_pDelegates[tag] == nil then --累计消费
        local ConsumptionGiftUI = require("View.WelfareActivity.ConsumptionGiftUI")
        -- self.m_pDelegates[tag] = ConsumptionGiftUI:New(self.m_pRankingBg)
    elseif tag == WelfareActivityDef.Type.MeiRiShouChong and self.m_pDelegates[tag] == nil then
        local DailyRechargeUI = require("View.WelfareActivity.DailyRechargeUI")
        self.m_pDelegates[tag] = DailyRechargeUI:New(self.m_pUILayer)
        self.m_pDailyRechargeNode = self.m_pDelegates[tag].m_pUILayer
    elseif tag == WelfareActivityDef.Type.SevenDaysChargeTag and self.m_pDelegates[tag] == nil then --七日充值
        local SevenDaysCharge = require("View.WelfareActivity.SevenDaysCharge")
        self.m_pDelegates[tag] = SevenDaysCharge:New(self.m_pUILayer)
        self.m_pSevenRechargeNode = self.m_pDelegates[tag].m_pUILayer
    elseif tag == WelfareActivityDef.Type.PetDiscount and self.m_pDelegates[tag] == nil then
        local PetDiscountUI = require("View.WelfareActivity.PetDiscountUI")
        self.m_pDelegates[tag] = PetDiscountUI:New(self.m_pUILayer)
    elseif tag == WelfareActivityDef.Type.NationalDayGift and self.m_pDelegates[tag] == nil then
        local NationalDayGiftUI = require("View.WelfareActivity.NationalDayGiftUI")
        self.m_pDelegates[tag] = NationalDayGiftUI:New(self.m_pUILayer)
    elseif tag ==  WelfareActivityDef.Type.NationDayCollectWord and self.m_pDelegates[tag] == nil then
        local NationalCollectWordUI = require("View.WelfareActivity.NationalCollectWordUI")
        self.m_pDelegates[tag] = NationalCollectWordUI:New(self.m_pUILayer)
    elseif tag ==  WelfareActivityDef.Type.GetTiLi and self.m_pDelegates[tag] == nil then
        local ReceiveTiliUI = require("View.WelfareActivity.ReceiveTiliUI")
        self.m_pDelegates[tag] = ReceiveTiliUI:New(self.m_pUILayer)
    end

    return self.m_pDelegates[tag]
end

function LimitGaChaActivity:TabClicked(ind)
    print("TabClicked ====>", ind)
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
        end
    end
    LRedDotCheckMgr:MainHuodongCheck(ind)
end

function LimitGaChaActivity:Reset()
    self.m_pRankingBg:setVisible(false)
    if self.m_pDailyRechargeNode ~= nil then
        self.m_pDailyRechargeNode:setVisible(false)
    end
    if self.m_controlNodeList then
        for i=1,#self.m_controlNodeList do
            self.m_controlNodeList[i]:setVisible(false)
        end
    end
    if self.m_pSevenRechargeNode ~= nil then
        self.m_pSevenRechargeNode:setVisible(false)
    end
end

-- function LimitGaChaActivity:InitTableView(tbPanel)
--     local cfg = {}
--     cfg.tbPanel = tbPanel
--     cfg.cellSizeForTable = function(sender,idx)
--         local width = self.m_pGridCell:getContentSize().width
--         local height = self.m_pGridCell:getContentSize().height
--         return width, height
--     end
--     cfg.tableCellAtIndex = function(sender, idx)
--         return self:TableCellAtIndex(sender, idx)
--     end

--     cfg.numberOfCellsInTableView = function()
--         return self.m_tableCount
--     end

--     cfg.scrollViewDidScroll = function(view)
--         self.m_isDragging = view:isDragging()
--     end

--     cfg.tableCellTouched = function(view, cell)
--         self:tableCellTouched(cell:getIdx()+1)
--     end

--     return Utils:createTableView(cfg)
-- end

function LimitGaChaActivity:TableCellAtIndex(sender, idx)
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

function LimitGaChaActivity:tableCellTouched(idx, updateImmediately)
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

function LimitGaChaActivity:updateItem(cell, info, idx)
    local pChooseBg = cell:getChildByName("ChooseBg")
    pChooseBg:setVisible(idx == self.m_selectIndex)

    local pBtnName = cell:getChildByName("BtnName")
    pBtnName:setString(info.uname and info.uname or "")

    local prompt = cell:getChildByName("Prompt")
    prompt:setVisible(Utils:GetRedDotState(RedDotDef.ID.HDBase + idx))
end

function LimitGaChaActivity:ReloadData(value)
    local tag = value[1]
    if type(self.m_datas) == 'table' then
        local data = self.m_datas[self.m_selectIndex]
        local curTag = ((data and data.tag) and {data.tag} or 0)[1]
        if curTag and curTag == tag then
            local pDelegate = self:getDelegate(tag)
            local _ = pDelegate and pDelegate:updateData(value[2])
        end
    end
end

function LimitGaChaActivity:ReloadListData(list)
    self.m_pUILayer:setVisible(true)
    self.m_datas = nil
    self.m_datas = list
    self.m_tableCount = #self.m_datas
    self:tableCellTouched(self.m_openTab, true)
    Utils:MoveToTableIdx(self.m_pTableView, self.m_pGridCell, self.m_openTab - 1)
end 


return LimitGaChaActivity