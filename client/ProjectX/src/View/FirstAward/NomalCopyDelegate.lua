local NomalCopyDelegate = LUIBase:New()
NomalCopyDelegate.__index = NomalCopyDelegate

----------------------------------------------
function NomalCopyDelegate:New()
    local o = {}
    setmetatable(o, NomalCopyDelegate)
    o:Init()
    return o
end
----------------------------------------------
function NomalCopyDelegate:Init()
    self.Script = "FirstAward.NomalCopyDelegate"
    self.m_countDown = 10
    self.m_countDownLabel = nil
    ------------------------------------------
    self:RegisterQuik()
end

function NomalCopyDelegate:setData(cfg)
	if cfg == nil then
		return
	end
	self.m_pUI = cfg[1]
	self.m_pUILayer = cfg[2]
	self.m_data = cfg[3]
	self:RegisterQuik()
	self:UpdateUI()
	Utils:PlayEffect("GuideBGM", "id", 2)
end
----------------------------------------------
function NomalCopyDelegate:onExit()
    self.m_pUI = nil
    self.m_pUILayer = nil
     if self.m_countSchedule then
        Utils:unschedule(nil, self.m_countSchedule)
        self.m_countSchedule = nil
    end
end
----------------------------------------------
function NomalCopyDelegate:RegisterQuik()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    if self.m_pUILayer ~= nil then
    	self.m_pUILayer:registerScriptHandler(onNodeEvent)
    end
end
----------------------------------------------
function NomalCopyDelegate:UpdateUI()
	local pPanel = self.m_pUILayer
	----------------------------------------------
	self:updateTips()
	----------------------------------------------
	local pIconBg = pPanel:getChildByName("IconBg")
	pIconBg:setVisible(true)
	local pList = pIconBg:getChildByName("List")
	pList:setVisible(true)
	local items = {}
	for i=1,2 do
		table.insert(items, pList:getChildByName("IconBtn"..i))
	end
	--self._petCell = pList:getChildByName("IconColor")
	--table.insert(items, self._petCell)
	pList:getChildByName("IconBtn3"):setVisible(false)

	local datas = self:getItemConfig()
	self:updateItems(pList, datas, items)
	----------------------------------------------
	self:updateButton()
	----------------------------------------------
	self:UpdateSelfUI()
end


function NomalCopyDelegate:UpdateSelfUI()
end

function NomalCopyDelegate:updateTips()
	local pPanel = self.m_pUILayer
	local pText = pPanel:getChildByName("Text")
	local x = pText:getPositionX()
	local pAysLabel = Utils:CreateColorText2(pPanel, pText, cc.size(480, pText:getContentSize().height))

	local ret = {}
	Utils:SendMsg(LUIMainEvent.GetMapName, ret)

	pAysLabel:setString(string.format(GUITips.RSI_JIESUAN_TIP1, ret.mapName or ""))

	pAysLabel:setPositionX(x - pAysLabel:getSize().width/2)
	 local Iconbg = pPanel:getChildByName("IconBg")
	 local list = Iconbg:getChildByName("List")
	 for i=1,#self.m_data.itemVal1 do
        local btn=list:getChildByName("IconBtn"..i)
        if btn then
	        local pName = btn:getChildByName("Name")
			local name = Utils:getItemNameByID(self.m_data.itemId[i])
			if #name > 0 then
				pName:setVisible(true)
				pName:setString(name)
			else
				pName:setVisible(false)
			end
        end
    end
end

function NomalCopyDelegate:updateButton()
	local pBtnList = self.m_pUILayer:getChildByName("BtnList")
	pBtnList:setVisible(true)
	---------------------------------------------------------------------------
	local pShareBtn = pBtnList:getChildByName("Btn_1")
	pShareBtn:addClickEventListener(handler(self, NomalCopyDelegate.ShareBtnClick))
	---------------------------------------------------------------------------
	local pCloseBtn = pBtnList:getChildByName("Btn_2")
	pCloseBtn:addClickEventListener(handler(self, self.GetBtnClick))
	self.m_countDownLabel = pCloseBtn:getChildByName("Text")
	---------------------------------------------------------------------------
	--TODO:暂时隐藏
	pShareBtn:setVisible(false)
	pCloseBtn:setPositionX((pShareBtn:getPositionX()+pCloseBtn:getPositionX())/2)
	---------------------------------------------------------------------------
    if self.m_countSchedule then
        Utils:unschedule(nil, self.m_countSchedule)
        self.m_countSchedule = nil
    end
	self.m_countSchedule = Utils:schedule(nil, function(dt)
		if self.m_countDown < 0 then
			Utils:unschedule(nil, self.m_countSchedule)
			self.m_countSchedule = nil
			self:GetBtnClick(pCloseBtn)
			return
		end
		self.m_countDownLabel:setString(string.format("%s(%d)", GUITips.RSI_FACTION_MSG203, self.m_countDown))
		self.m_countDown = self.m_countDown - 1
	end, 1, false)
end

function NomalCopyDelegate:updateItems(pList, datas, items)
	local cData = #datas
	for i=1,#items do
		local pItemBtn = items[i]
		if i <= cData then
			pItemBtn:setVisible(true)
			pItemBtn:setTouchEnabled(false)
			if datas[i].id == AppDef.AwrdItem.AWRD_ITEM_PET then
				--宠物 不显示
				-- local iconImg = ccui.ImageView:create()
				-- pItemBtn:addChild(iconImg)
				-- iconImg:setContentSize(pItemBtn:getContentSize())
				-- iconImg:setPositionY(pItemBtn:getContentSize().height / 2)
				-- Utils:ShowPet(datas[i].num, pList, self._petCell)
				-- self._petCell:setVisible(true)
			else
				--物品
				Utils:GetItemCellValue(pItemBtn, 0, datas[i].id, true, true, datas[i].num, nil, true)
			end
		else
			pItemBtn:setVisible(false)
		end
	end
	--dump(items, "items---->")
	Utils:AlignNodes(pList, items, {80}, 3)
end

function NomalCopyDelegate:getItemConfig()
	local datas = {}
	if self.m_data.Money > 0 then
		table.insert(datas, {id=AppDef.AwrdItem.AWRD_ITEM_COIN, num=self.m_data.Money})
	end
	if self.m_data.extraExp > 0 then
		table.insert(datas, {id=AppDef.AwrdItem.AWRD_ITEM_EXP, num=self.m_data.extraExp})
	end
	if self.m_data.qianneng > 0 then
		table.insert(datas, {id=AppDef.AwrdItem.AWRD_ITEM_POTEN, num=self.m_data.qianneng})
	end
	for i=1,#self.m_data.itemId do
		table.insert(datas, {id=self.m_data.itemId[i], num=self.m_data.itemVal1[i]})
	end
	return datas
end

----------------------------------------------
function NomalCopyDelegate:ShareBtnClick(sender)
end
----------------------------------------------
function NomalCopyDelegate:GetBtnClick(sender)
     if self.m_countSchedule then
        Utils:unschedule(nil, self.m_countSchedule)
        self.m_countSchedule = nil
    end
    if self.m_pUI then
    	self.m_pUI:RemoveUI()
    end
    LuaNetSendMsg:QueryCopyExit()
end

return NomalCopyDelegate