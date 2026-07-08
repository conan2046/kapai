local TimerLabelUI = require("View.Common.TimerLabelUI")

local FundRebate = LUIBase:New()
FundRebate.__index = FundRebate
-- -----------------------------------
function FundRebate:New(parent)
    local o = {}
    setmetatable(o, FundRebate)
    o:Init(parent)
    return o
end

-- -----------------------------------
function FundRebate:Init(parent)
    self.Script = "WelfareActivity.FundRebate"
    --------------------------------------
    self.m_isInit = false
    self.m_datas = nil
    self.m_curFundId = 0
    self.m_curShowTag = 0
    self._buyId = 0
    self.m_cdTime = 0
	--------------------------------------
    self.m_Descs = {{}, {}}
    self.m_Poses = {}
    self.m_pItems = {}
    --------------------------------------
    self:RegistMsgs()
    self:InitViewSize(parent)
    self:InitUIControl()
    self:setCloseCallback()
    local _ = self.m_pUILayer and self.m_pUILayer:setVisible(false)

    LuaNetSendMsg:QueryFundRebate(1)
end

-- -----------------------------------
function FundRebate:onExit()
    --self:HideDetail()
    self.m_pUILayer = nil
    if self.m_timer then
        self.m_timer:Destory()
        self.m_timer = nil
    end
    self.m_pItemModel = nil
    if self.m_Descs ~= nil then
        for i=1,#self.m_Descs do
            Utils:FreeTable(self.m_Descs[i])
            self.m_Descs[i] = nil
        end
        self.m_Descs = nil
    end
    Utils:FreeTable(self.m_Poses)
    self.m_Poses = nil
    if self.m_pItems then
        for k,v in pairs(self.m_pItems) do
            if k and v then
                v:onExit(true)
            end
        end
    end
    Utils:FreeTable(self.m_pItems)
    self:Destory()
    self.m_pItems = nil
    self.m_pLeftTime = nil
    self.m_ZHPPanel = nil
    self.m_ZGPanel = nil
    self.m_pListBg = nil
    self.m_pListViewBg = nil
    self.m_pListView = nil
    self.m_pRechargeBtn = nil
    self.m_pDescPanel = nil
end

-- -----------------------------------
function FundRebate:RegistMsgs()
    self.msgIds = 
    {
        LUIFundRebateEvent.LoadDataEvent,
        LUIFundRebateEvent.GetRewardDataEvent,
        LUILogicEvent.paymentSuccess,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function FundRebate:ProcessEvent(msg)
    if msg.msgId == LUIFundRebateEvent.LoadDataEvent then
        self:parseData(msg.value)
    elseif msg.msgId == LUIFundRebateEvent.GetRewardDataEvent then
        self:GetRewardRet(msg.value)
    elseif msg.msgId == LUILogicEvent.paymentSuccess then
        self.m_pRechargeBtn:setTouchEnabled(false)
        self.m_pRechargeBtn:setBright(false)
        performWithDelay(self.m_pUILayer, function(sender)
            LuaNetSendMsg:QueryFundRebate(1)
        end, 0.5)
    end
end
-- -----------------------------------
function FundRebate:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
-- -----------------------------------
function FundRebate:InitViewSize(parent)
    self:CreateUINode("csd/huodong/ChengZhangLayer.csb")
    parent:addChild(self.m_pUILayer)
end
-- -----------------------------------
function FundRebate:InitUIControl()
    local panel = self.m_pUILayer:getChildByName("ChengZhang")
    panel:setLocalZOrder(1)

    local pText_1 = panel:getChildByName("Text_1")
    self.m_pLeftTime = pText_1:getChildByName("Time")
    self.m_pLeftTime:setString("")
    self.m_timer = TimerLabelUI:New(self.m_pLeftTime, nil, nil, handler(self, FundRebate.TimeReduce))

    local pContent = panel:getChildByName("Content")
    ---------------------------------------------------------
    self.m_ZHPPanel = pContent:getChildByName("Content_1")--杂货铺
    self.m_ZHPPanel:setTouchEnabled(true)
    self.m_ZHPPanel:addClickEventListener(handler(self, FundRebate.Click))
	self:MarkIntaractCObj(self.m_ZHPPanel)
    table.insert(self.m_Poses, self.m_ZHPPanel:getPositionX())
    
    self.m_ZGPanel = pContent:getChildByName("Content_2")--朝歌会所
    self.m_ZGPanel:addClickEventListener(handler(self, FundRebate.Click))
	self:MarkIntaractCObj(self.m_ZGPanel)
    self.m_ZGPanel:setTouchEnabled(true)
    table.insert(self.m_Poses, self.m_ZGPanel:getPositionX())
    ---------------------------------------------------------
    self.m_pListBg = pContent:getChildByName("ListBg")
    local pBg = self.m_pListBg:getChildByName("Bg")
    self.m_pListViewBg = pBg
    self.m_pListView = pBg:getChildByName("ListView_1")
    self.m_pItemModel = pBg:getChildByName("Reward_1")
    ---------------------------------------------------------
    local pDesc = self.m_pListBg:getChildByName("Desc")
    self.m_pDescPanel = pDesc
    for i=1,#self.m_Descs do
    	if self.m_Descs[i] == nil then
    		self.m_Descs[i] = {}
    	end
    	table.insert(self.m_Descs[i], pDesc:getChildByName("Text_"..i.."_1"))
	    table.insert(self.m_Descs[i], pDesc:getChildByName("Text_"..i.."_2"))
    end
    ---------------------------------------------------------
    self.m_pRechargeBtn = pDesc:getChildByName("Btn")
    self.m_pRechargeBtn:setTag(0)
    self.m_pRechargeBtn:addClickEventListener(handler(self, FundRebate.DoRechanre))
	self:MarkIntaractCObj(self.m_pRechargeBtn)
    ---------------------------------------------------------
end

function FundRebate:loadData()
    local _ = self.m_pUILayer and self.m_pUILayer:setVisible(true)

    if self.m_curFundId and self.m_curFundId > 0 then
        self.m_pLeftTime:getParent():setVisible(false)
    else
        self.m_pLeftTime:getParent():setVisible(true)
    end

    if self.m_cdTime then
        self.m_timer:set(self.m_cdTime)
        self.m_timer:start()
    end
    -- dump(self.m_curFundId, "self.m_curFundId--->")
    local temp = {self.m_ZHPPanel, self.m_ZGPanel}
    local ind = 0
    for i=1,math.min(#self.m_datas, #temp) do
        temp[i]:setTag(i)
        -- dump(self.m_datas[i].id, "self.m_datas[i].id--->")
        if self.m_curFundId == self.m_datas[i].id then
            ind = i
        end
    end
    -- dump(ind, "ind------->")
    if self.m_isInit == false and ind > 0 then
        self:DoClick(ind)
        -- for i=1,#temp do
        --     temp[i]:setEnabled(false)
        -- end
    end

    -- print("loadData =====>", ind, self.m_curFundId)

    self:updateDescPanel(self.m_curFundId > 0)

    self:SetContentInfo()
    self.m_isInit = true
end
--------------------------------------------
function FundRebate:SetContentInfo()
    --------------------------------------------
    local items = {self.m_ZHPPanel, self.m_ZGPanel}
    for i=1,#self.m_datas do
        if i > #items then
            break
        end
        local pItem = items[i]
        local data = self.m_datas[i]
        local pRateText = pItem:getChildByName("Text")
        pRateText:setString(string.format(GUITips.RSI_FUND_TIPS9, data.rate))

        local pMoneyBg = Utils:FindNodeByName(pItem, "Image_1/Base/Text")
        if pMoneyBg then
            local pNeedMoney = pMoneyBg:getChildByName("AtlasLabel_1")
            pNeedMoney:setString(data.price)
            local pGetMoney = pMoneyBg:getChildByName("AtlasLabel_2")
            pGetMoney:setString(data.totalNum)
        end
        --------------------------------------------
        self:UpdateMoney(self.m_Descs[i], data)
    end
end

function FundRebate:updateDescPanel( isAlreadyBuy )
    -- body
    local height = 350
    if isAlreadyBuy then
        height = 456
    else
        if self.m_curShowTag > 0 then
            self:UpdateMoney(self.m_Descs[self.m_curShowTag], self.m_datas[self.m_curShowTag])
        end
    end

    self.m_pDescPanel:setVisible(not isAlreadyBuy)
    self.m_pRechargeBtn:setTouchEnabled(not isAlreadyBuy)
    self.m_pRechargeBtn:setBright(not isAlreadyBuy)

    self.m_pListViewBg:setContentSize(cc.size(self.m_pListViewBg:getContentSize().width, height))
    ccui.Helper:doLayout(self.m_pListViewBg)
    self.m_pListView:jumpToTop()

end

function FundRebate:UpdateMoney(paneles, info)
    if #paneles == 2 then
        local pNode1 = paneles[1]
        pNode1:setVisible(true)
        local pNeedMoney = pNode1:getChildByName("AtlasLabel_1")
        pNeedMoney:setString(info.price or 0)

        local pGetMoney = pNode1:getChildByName("AtlasLabel_2")
        pGetMoney:setString(info.getNum or 0)

        local pNode2 = paneles[2]
        pNode2:setVisible(true)
        local pTotalMoney = pNode2:getChildByName("AtlasLabel_1")
        pTotalMoney:setString(info.totalNum or 0)
    else
        for i=1,#paneles do
            paneles[i]:setVisible(false)
        end
    end
end

function FundRebate:updateItem(pItem, info, idx)
    if pItem == nil or info == nil then
        return
    end
    -- dump(self.m_curFundId)
    -- dump(info)
    ------------------------------------------
    local pText = pItem:getChildByName("Text")
    pText:setString(string.format(GUITips.RSI_FUND_TIPS1, info.level))
    ------------------------------------------
    local pBtn = pItem:getChildByName("Btn")
    local pRecieveImage = pItem:getChildByName("ImageReceive")
    if pBtn and pRecieveImage then
        if info.state == 3 then
            pRecieveImage:setVisible(true)
            pBtn:setVisible(false)
        else
            pRecieveImage:setVisible(false)
            pBtn:setVisible(true)

        end
        if pBtn:isVisible() then
            pBtn:setSwallowTouches(false)
            pBtn:setTag(idx)
            pBtn:addClickEventListener(handler(self, FundRebate.GetReward))
			self:MarkIntaractCObj(pBtn)
            local pBtnText = pBtn:getChildByName("Text")
            if pBtnText then
                if LRoleDataMgr.MyHeroInfo.level < info.level then
                    pBtnText:setString(GUITips.RSI_FUND_TIPS2)
                    pBtn:setBright(false)
                    pBtn:setTouchEnabled(true)
                else
                    if self.m_curFundId <= 0 then
                        pBtnText:setString(GUITips.RSI_FUND_TIPS7)
                        pBtn:setBright(true)
                        pBtn:setTouchEnabled(true)
                    elseif info.state == 2 then
                        pBtnText:setString(GUITips.RSI_FUND_TIPS3)
                        pBtn:setBright(true)
                        pBtn:setTouchEnabled(true)
                    elseif info.state == 3 then
                        pBtnText:setString(GUITips.RSI_FUND_TIPS4)
                        pBtn:setBright(false)
                        pBtn:setTouchEnabled(false)
                        pBtn:setVisible(false)
                    else
                        --dump(info, "状态有误！")
                    end
                end
            end
        end
    end
    ------------------------------------------
    local itemInfo = info.itemArr[1]
    local tmp = pItem:getChildByName("ListView")
    tmp:setTouchEnabled(false)
    local pImageBg = tmp:getChildByName("ItemBg")
    if pImageBg and itemInfo and itemInfo.itemId > 0 then
        self.m_pItems[idx] = Utils:GetItemCellValue(pImageBg, 0, itemInfo.itemId, false, true, itemInfo.itemNum, self.m_pItems[idx])
    end
end

function FundRebate:Click(sender)
	if sender == nil then
		return
	end
	local tag = sender:getTag()
	-- print("Click---------------------->", tag)
	self:DoClick(tag)
end

function FundRebate:DoClick(tag)
    if tag <= 0 then
        return
    end
    self.m_curShowTag = tag
    self:ChangeData()
    if self.m_pRechargeBtn:getTag() == 0 then
        self:ShowDetail(tag)
    else
        self:HideDetail()
    end
end

function FundRebate:DoRechanre(sender)
	if sender == nil then
		return
	end
    local isMax = self:IsMaxPrice()
    -- dump(isMax, "isMax--------->")
    if isMax ~= nil then
        if isMax then
            local tag = sender:getTag()
            self:Rechanre(tag)
        else
            self:ShowMsgBox()
        end
    end
end

function FundRebate:Rechanre(tag)
    local data = self.m_datas[tag]
    --dump({tag, data}, "充值---------------------->")
    if data and data.price then
        Utils:Payment(data.price)
    end
end

function FundRebate:ShowDetail(tag)
	-----------------------------------------
	if tag == 1 then
		self.m_ZHPPanel:setVisible(true)
		self.m_ZHPPanel:setPositionX(self.m_Poses[1])
		self.m_ZGPanel:setVisible(false)
        self.m_pListView:scrollToTop(0, true)
	elseif tag == 2 then
		self.m_ZHPPanel:setVisible(false)
		self.m_ZGPanel:setVisible(true)
		self.m_ZGPanel:setPositionX(self.m_Poses[1])
        self.m_pListView:scrollToTop(0, true)
	else
		return
	end
	-----------------------------------------
	for i=1,#self.m_Descs do
		local isVisible = (i == tag)
		for j=1,#self.m_Descs[i] do
			self.m_Descs[i][j]:setVisible(isVisible)
		end
	end
	-----------------------------------------
	self:FlushRecordList(tag)
	-----------------------------------------
	self.m_pRechargeBtn:setTag(tag)
    --------------------------------
    self:updateDescPanel(bit.band(self._buyId, bit.lshift(1, self.m_curShowTag)) > 0 )

end

function FundRebate:HideDetail()
	self.m_ZHPPanel:setVisible(true)
	self.m_ZGPanel:setVisible(true)
	self.m_ZHPPanel:setPositionX(self.m_Poses[1])
	self.m_ZGPanel:setPositionX(self.m_Poses[2])
	self.m_pRechargeBtn:setTag(0)
end

function FundRebate:FlushRecordList(tag)
    local datas = self.m_datas[tag]
    if datas == nil or datas.dayArr == nil or #datas.dayArr == 0 then
        return
    end
    local items = self.m_pListView:getItems()
    local dayArrs = datas.dayArr
    local itemCount,dayArrCount = #items,#dayArrs
    local scrollIndex,pScrollItem = nil,nil
    for i=1,math.max(itemCount, dayArrCount) do
        local pItem = nil
        if i > itemCount then
            pItem = self.m_pItemModel:clone()
            self.m_pListView:pushBackCustomItem(pItem)
        else
            pItem = self.m_pListView:getItem(i - 1)
        end

        if i > dayArrCount then
            local _ = pItem and pItem:setVisible(false)
        else
            local data = dayArrs[i]
            if data.state == 2 and pScrollItem == nil then
                pScrollItem = pItem
                scrollIndex = i
            end
            self:updateItem(pItem, data, i)
        end
    end
    if dayArrCount > 5 and pScrollItem and scrollIndex then
        local list = self.m_pListView

        local space = list:getItemsMargin()
        performWithDelay(list, function(sender)
            local time = 1
            if dayArrCount-scrollIndex < 4 then
                list:scrollToPercentVertical(100, time, true)
            else
                local posX = list:getInnerContainerSize().height-pScrollItem:getPositionY()+space*0.5
                local diff = list:getInnerContainerSize().height - list:getContentSize().height
                local persent = math.floor(posX / diff * 100)
                list:scrollToPercentVertical(math.min(persent, 100), time, true)
            end
        end, 1/10)
    end
end

function FundRebate:parseData(serverData)
    self.m_cdTime = serverData[1] or 0
    self.m_datas = serverData[3]
    -- dump(self.m_datas, "parseData =====>")

    self._buyId = serverData[2]
    if self.m_datas == nil then
        return
    end

    self:ChangeData()

    self:loadData()
end

function FundRebate:ChangeData( ... )
    -- body
    if self.m_datas == nil then
        return
    end

    self.m_curFundId = 0
    if self.m_curShowTag > 0 then
        local data = self.m_datas[self.m_curShowTag]
        if bit.band(self._buyId, bit.lshift(1, self.m_curShowTag)) > 0 then
            self.m_curFundId = data.id
        end
    end
end

function FundRebate:FindDataById(id)
    if id == nil then
        return nil
    end
    for i=1,#self.m_datas do
        if self.m_datas[i].id == id then
            return self.m_datas[i],i
        end
    end
    return nil
end

function FundRebate:IsMaxPrice()
    local curInd = self.m_pRechargeBtn:getTag()
    local data = self.m_datas[curInd]
    -- dump({curInd, data}, "IsMaxPrice--->")
    -- dump(self.m_datas, "self.m_datas--->")
    if data then
        for i=1,#self.m_datas do
            if self.m_datas[i].price > data.price then
                return false
            end
        end
        return true
    end
    return nil
end

function FundRebate:GetReward(sender)
    if sender == nil then
        return
    end
    local data = nil
    if self.m_curFundId > 0 then
        data = self:FindDataById(self.m_curFundId)
    else
        self:DoRechanre(self.m_pRechargeBtn)
        return
    end
    -- dump(data, "data---------------------------->")
    if data == nil then
        return
    end
    local ind = sender:getTag()
    local dayData = data.dayArr[ind]
    if dayData == nil then
        return
    end
    -- dump(dayData, "获取奖励----->")
    if LRoleDataMgr.MyHeroInfo.level < dayData.level then
        Utils:ShowScrollTips(string.format(GUITips.RSI_FUND_TIPS6, dayData.level))
        return
    end
    LuaNetSendMsg:QueryFundRebate(2, data.id, ind)
end

function FundRebate:TimeReduce(pText, h, m, s, left)
    if pText == nil then
        return
    end
    -- dump({h, m, s}, "FundRebate:TimeReduce-->")
    local str = ""
    local day = 0
    if h > 24 then
        day = math.floor(h / 24)
        h = math.fmod(h, 24)
    end
    -- dump({day, h, m, s}, "FundRebate:TimeReduce-->")
    if day > 0 then
        str = str..tostring(day)..GUITips.Item_Info_Day
    end
    -- print("str----->", str)
    str = str..string.format("%02d:%02d:%02d", h, m, s)
    pText:setString(str)
end

function FundRebate:GetRewardRet(stream)
    local id = stream:ReadByte()
    local ind = stream:ReadByte()
    local succ = stream:ReadByte()
    if succ == 0 then
        Utils:ShowScrollTips(stream:ReadString())
        return
    end
    local data,idIndex = self:FindDataById(id)
    -- dump({id, ind, idIndex}, "GetRewardRet--->")
    if idIndex then
        data.dayArr[ind].state = 3
        local pItem = self.m_pListView:getItem(ind - 1)
        self:updateItem(pItem, data.dayArr[ind], ind)
        LuaNetSendMsg:QueryFundRebate(1)
    end
end

function FundRebate:ShowMsgBox()
    local function okFunc()
        local curInd = self.m_pRechargeBtn:getTag()
        self:Rechanre(curInd)
    end
    Utils:ShowDialogOKCancel(GUITips.RSI_FUND_TIPS8, okFunc, function()end)
end

function FundRebate:setVisible(visible)
    self.m_pUILayer:setVisible(visible)
    self:HideDetail()
end

return FundRebate