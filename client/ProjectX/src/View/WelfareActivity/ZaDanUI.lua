local LuckTableUI = require("View.Common.LuckTableUI")
local TimerLabelUI = require("View.Common.TimerLabelUI")
local ZaDanRecordDelegate = require("View.WelfareActivity.ZaDanRecordDelegate")
local ShopDef = require("View.Shop.ShopDef")

local costItem = 2384--钥匙
local cost10Num = 9--10连转消耗道具数量
local s_lastOp = nil

local buffer = {
	[20] = 33,
	[92] = 92,
}

local ZaDanUI = LUIBase:New()
ZaDanUI.__index = ZaDanUI
-----------------------------------
function ZaDanUI:New(op)
    local o = {}
    setmetatable(o, ZaDanUI)
    o:Init(op)
    return o
end
-----------------------------------
function ZaDanUI:Init(op)
	op = buffer[op]
    self.Script = "WelfareActivity.ZaDanUI"
    self.m_op = op or s_lastOp
    --------------------------------------
    self.m_pUILayer = nil
    self.m_pRotatePanel = nil
    self.m_pLuckTableUI = nil
    self.m_pRotations = {}
    self.m_pRewardList = {}
    self.m_pRewardItemList = {}
    self.m_pClearTimer = nil
    self.m_pLeftTimer = nil
    self.m_pMyRecordDelegate = nil
	self.m_pAllRecordDelegate = nil
	self.m_pScoreText = nil
	self.m_pHaveItemText = nil
	self.m_pHaveMoneyText = nil
	self.m_isRotating = nil
	self.m_pBg = nil
	self.m_pRedDot1 = nil
	self.m_pRedDot10 = nil
	self.m_itemPrice = nil
    --------------------------------------
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    --------------------------------------
    LuaNetSendMsg:QueryZaDanInfo(self.m_op)
end
-----------------------------------
function ZaDanUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_pRotatePanel = nil
    self.m_pLuckTableUI = nil
    
    Utils:FreeTable(self.m_pRotations)
    self.m_pRotations = nil
    Utils:FreeTable(self.m_pRewardList)
    self.m_pRewardList = nil

    for k,v in pairs(self.m_pRewardItemList) do
    	if v and v.onExit then
    		v:onExit(true)
    	end
    	self.m_pRewardItemList[k] = nil
    end
    self.m_pRewardItemList = nil

    if self.m_pClearTimer then
    	self.m_pClearTimer:Destory()
    end
    self.m_pClearTimer = nil
    if self.m_pLeftTimer then
    	self.m_pLeftTimer:Destory()
    end
    self.m_pLeftTimer = nil
    self.m_pMyRecordDelegate = nil
	self.m_pAllRecordDelegate = nil
	self.m_pScoreText = nil
	self.m_pHaveItemText = nil
	self.m_pHaveMoneyText = nil
	self.m_isRotating = nil
	self.m_pBg = nil
	self.m_pRedDot1 = nil
	self.m_pRedDot10 = nil
	Utils:FreeTable(self.m_retData)
	self.m_retData = nil
	self.m_itemPrice = nil
end
-----------------------------------
function ZaDanUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
-----------------------------------
function ZaDanUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/huodong/ZhuanpanLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end
-----------------------------------
function ZaDanUI:InitUIControl()
	local panel = self.m_pUILayer:getChildByName("Panel")
	local pBg = panel:getChildByName("Bg")
	pBg:setVisible(false)
	self.m_pBg = pBg
	-------------------------------------
	local pTitleBg = pBg:getChildByName("TitleBg")
	local pTime = pTitleBg:getChildByName("Text"):getChildByName("Time")
	self.m_pLeftTimer = TimerLabelUI:New(pTime, 0, handler(self, ZaDanUI.RemoveUI), handler(self, ZaDanUI.TimeReduce))
	-------------------------------------
	local pCloseBtn = panel:getChildByName("CloseBtn")
	pCloseBtn:addClickEventListener(handler(self, ZaDanUI.CloseButtonClick))
	-------------------------------------
	local pPanel17 = pBg:getChildByName("Panel_17")
	-------------------------------------
	local pRewardBg = pPanel17:getChildByName("RewardBg")
	for i=1,10 do
		local pCell = pRewardBg:getChildByName("RewardBg"..i)
		if pCell ~= nil then
			table.insert(self.m_pRotations, pCell:getRotation())
		end
		table.insert(self.m_pRewardList, pRewardBg:getChildByName("IconBg_"..i))
	end
	-------------------------------------
	self.m_pChoose = pRewardBg:getChildByName("Choose")
	-------------------------------------
	local pZhiZhen = pPanel17:getChildByName("ZhenImage")
	
	self.m_pLuckTableUI = LuckTableUI:New(pZhiZhen)
	local data = {}
	data.sCallback = handler(self, ZaDanUI.StartRotate)
	data.fCallback = handler(self, ZaDanUI.RotateEnd)
	data.indexChanged = handler(self, ZaDanUI.IndexChanged)
	self.m_pLuckTableUI:SetData(data)
	-------------------------------------
	local pDraw = pBg:getChildByName("Draw")
	-------------------------------------
	do
		local pButton1 = pDraw:getChildByName("Button1")
		pButton1:setTag(0)
		pButton1:addClickEventListener(handler(self, ZaDanUI.ZaDanClick))
		local pBg = pButton1:getChildByName("Bg")
		self.m_pSingleNum = pBg:getChildByName("Num")
		self.m_pSingleNum:setString("1/0")
		self.m_pRedDot1 = pButton1:getChildByName("Dot")
		self.m_pRedDot1:setVisible(false)
	end
	do
		local pButton2 = pDraw:getChildByName("Button2")
		pButton2:setTag(1)
		pButton2:addClickEventListener(handler(self, ZaDanUI.ZaDanClick))
		local pBg = pButton2:getChildByName("Bg")
		self.m_pTenNum = pBg:getChildByName("Num")
		self.m_pTenNum:setString(string.format("%d/0",cost10Num))
		self.m_pRedDot10 = pButton2:getChildByName("Dot")
		self.m_pRedDot10:setVisible(false)
	end
	do
		local pButton3 = pDraw:getChildByName("Button3")
		pButton3:addClickEventListener(handler(self, ZaDanUI.CangBaoGeClick))
		local pBg1 = pButton3:getChildByName("Bg1")
		self.m_pScoreText = pBg1:getChildByName("Num")
		self:UpdateScoreCount()
		local pBg2 = pButton3:getChildByName("Bg2")
		local pNum2 = pBg2:getChildByName("Num")
		self.m_pClearTimer = TimerLabelUI:New(pNum2, 0, nil, handler(self, ZaDanUI.TimeReduce))
	end
	-------------------------------------
	local pRecordBg = pBg:getChildByName("RecordBg")
	local pTitleBg1 = pRecordBg:getChildByName("TitleBg1")
	local pRecordSubBg1 = pTitleBg1:getChildByName("bg")
	local pList = pRecordSubBg1:getChildByName("List")
	local pText = pRecordSubBg1:getChildByName("Text")
	pText:setVisible(false)
	self.m_pMyRecordDelegate = ZaDanRecordDelegate:New(pList, pText)

	local pTitleBg2 = pRecordBg:getChildByName("TitleBg2")
	local pRecordSubBg2 = pTitleBg2:getChildByName("bg")
	local pList = pRecordSubBg2:getChildByName("List")
	local pText = pRecordSubBg2:getChildByName("Text")
	pText:setVisible(false)
	self.m_pAllRecordDelegate = ZaDanRecordDelegate:New(pList, pText)
	-------------------------------------
	do
		local pHaveBg1 = pBg:getChildByName("HaveBg_1")
		self.m_pHaveItemText = pHaveBg1:getChildByName("Value")
		self:UpdateItemCount()
		local pHaveBg2 = pBg:getChildByName("HaveBg")
		self.m_pHaveMoneyText = pHaveBg2:getChildByName("Value")
		self:UpdateMoneyCount()
	end
	-------------------------------------
end
-------------------------------------
function ZaDanUI:RegistMsgs()
    self.msgIds = {
	    LUIZaDanEvent.UpdateDataEvent,
		LUIZaDanEvent.BuyResultEvent,
		LUIBagEvent.BagDataChanged,
		LUIRoleDataChangeEvent.TongBaoChanged,
		LUIRoleDataChangeEvent.ZaDanJiFenChanged,
    }
    self:RegistSelf(self, self.msgIds)
end
-----------------------------------
function ZaDanUI:ProcessEvent(msg)
	if msg.msgId == LUIZaDanEvent.UpdateDataEvent then
		self:DealInitData(msg.value)
	elseif msg.msgId == LUIZaDanEvent.BuyResultEvent then
		self:DealBuyData(msg.value)
	elseif msg.msgId == LUIRoleDataChangeEvent.TongBaoChanged then
		self:UpdateMoneyCount()
	elseif msg.msgId == LUIBagEvent.BagDataChanged then
		self:UpdateItemCount()
	elseif msg.msgId == LUIRoleDataChangeEvent.ZaDanJiFenChanged then
		self:UpdateScoreCount()
    end
end
-----------------------------------
function ZaDanUI:DealInitData(datas)
	LRoleDataMgr.MyHeroInfo:GetDetailData():setZaDanScore(datas.score or 0)
	if self.m_pLeftTimer then
		self.m_pLeftTimer:set(datas.leftTime, handler(self, self.RemoveUI))
		self.m_pLeftTimer:start()
	end
	if self.m_pClearTimer then
		self.m_pClearTimer:set(datas.clearTime)
		self.m_pClearTimer:start()
	end

	if self.m_pMyRecordDelegate then
		self.m_pMyRecordDelegate:updateData(datas.myRecords)
	end
	if self.m_pAllRecordDelegate then
		self.m_pAllRecordDelegate:updateData(datas.allRecords)
	end
	--dump(datas.awards, "=======DealInitData=======>>>>>>>>>>>>>>>>>>>>>>>>")
	for i=1,math.min(#self.m_pRewardList, #datas.awards) do
		local pItem = self.m_pRewardList[i]
		local data = datas.awards[i]
		if data.petdata then
			self.m_pRewardItemList[i] = Utils:GetItemCellValue(pItem, 0, AppDef.AwrdItem.AWRD_ITEM_PETEQUIP, true, nil, nil, self.m_pRewardItemList[i], true, nil, data.itemId, data.petdata.star)
		else
			self.m_pRewardItemList[i] = Utils:GetItemCellValue(pItem, 0, data.itemId, true, true, data.itemNum, self.m_pRewardItemList[i], true)
		end
	end
	if datas.extraInfo and #datas.extraInfo > 0 then
		self.m_itemPrice = datas.extraInfo[1].price
	end
	self.m_pBg:setVisible(true)
end
-----------------------------------
function ZaDanUI:DealBuyData(data)
	local isSingle = data.isSingle
	data = data.data

	if self.m_pLuckTableUI then
		self.m_pLuckTableUI:Start((data.index or 1) + 1)
	end
	Utils:FreeTable(self.m_retData)
	self.m_retData = nil
	self.m_retData = data
end
-----------------------------------
function ZaDanUI:StartRotate()
	self.m_pChoose:stopAllActions()
	self.m_isRotating = true
	--添加补丁，防止卡死
	self.m_pBg:stopAllActions()
	performWithDelay(self.m_pBg, function(sender)
		self.m_isRotating = false
	end, 5)
end
-----------------------------------
function ZaDanUI:RotateEnd()
	self.m_isRotating = false
	LRoleDataMgr.MyHeroInfo:GetDetailData():setZaDanScore(self.m_retData.score or 0)
	if self.m_pMyRecordDelegate then
		self.m_pMyRecordDelegate:appendData(self.m_retData.myRecords)
	end
	if self.m_pAllRecordDelegate then
		self.m_pAllRecordDelegate:appendData(self.m_retData.allRecords)
	end
	LRoleDataMgr:ShowAwardAnim()
	self.m_pChoose:stopAllActions()
	self.m_pChoose:runAction(cc.Blink:create(0.5, 2))
	--TODO:添加补丁，防止动画不显示
	LRoleDataMgr:SetDelayShowAward(false)
end
-----------------------------------
function ZaDanUI:IndexChanged(new, old)
	if self.m_pChoose then
		self.m_pChoose:setRotation(self.m_pRotations[new] or 0)
	end
end
-----------------------------------
function ZaDanUI:CloseButtonClick(sender)
	self:RemoveUI()
end
-----------------------------------
function ZaDanUI:ZaDanClick(sender)
	if sender == nil then
		return
	end
	if self.m_isRotating then
		Utils:ShowScrollTips(GUITips.RSI_LUCK_DRAW_TIPS1)
		return
	end
	local tag = sender:getTag()
	local count = LRoleDataMgr.Equip:CountItemNumById(costItem)

	local limit = 0
	if tag == 0 then
		limit = 1
	else
		limit = cost10Num
	end
	if count < limit then
		if self.m_itemPrice == nil then
			local info = LDataConstMgr:getCItemByID(costItem)
			if info == nil then
				return
			end
			self.m_itemPrice = info.m_price
		end
		local str = string.format(GUITips.RSI_LUCK_DRAW_TIPS2, limit-count, (limit-count)*(self.m_itemPrice or 0))
		Utils:ShowDialogOKCancel(str, function()
			LuaNetSendMsg:QueryZaDan(tag, self.m_op)
		end, function() end)
	else
		LuaNetSendMsg:QueryZaDan(tag, self.m_op)
	end
end
-----------------------------------
function ZaDanUI:CangBaoGeClick(sender)
	s_lastOp = self.m_op
	self:RemoveUI()
	Utils:OpenShop(ShopDef.MK_TP.ZADAN)
end
-----------------------------------
function ZaDanUI:TimeReduce(pText, h, m, s, left)
    if pText == nil then
        return
    end
    if h >= 24 then
    	local day = math.floor(h/24)
    	h = h - day*24
    	pText:setString(string.format("%d%s%02d:%02d:%02d", day, GUITips.UI_Arena_Msg1, h, m, s))
    elseif h > 0 then 
        pText:setString(string.format("%02d:%02d:%02d", h, m, s))
    else
        pText:setString(string.format("%02d:%02d", m, s))
    end
end
-----------------------------------
function ZaDanUI:UpdateItemCount()
	local count = LRoleDataMgr.Equip:CountItemNumById(costItem)
	self.m_pHaveItemText:setString(count or "0")
	self.m_pRedDot1:setVisible(count >= 1)
	self.m_pRedDot10:setVisible(count >= cost10Num)
	self.m_pSingleNum:setString(string.format("%d/%d", count, 1))
	self.m_pTenNum:setString(string.format("%d/%d", count, cost10Num))
end
-----------------------------------
function ZaDanUI:UpdateMoneyCount()
	self.m_pHaveMoneyText:setString(LRoleDataMgr.MyHeroInfo:GetDetailData().TongBao)
end
-----------------------------------
function ZaDanUI:UpdateScoreCount()
	self.m_pScoreText:setString(LRoleDataMgr.MyHeroInfo:GetDetailData().ZaDanScore)
end
-----------------------------------
function ZaDanUI:RemoveUI()
	LRoleDataMgr:SetDelayShowAward(false)
	if self.m_isRotating then
		LRoleDataMgr:ShowAwardAnim()
	end
	
	if Utils:ToBool(self.Script) then
	    Utils:DeleteUI(self.Script)
	end
end
-----------------------------------
return ZaDanUI