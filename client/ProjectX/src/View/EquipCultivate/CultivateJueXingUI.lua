
local CultivateJueXingUI = LUIBase:New()
CultivateJueXingUI.__index = CultivateJueXingUI
--local this = LTcpSocket
function CultivateJueXingUI:New()
	local o = LUIBase:New()
	setmetatable(o,CultivateJueXingUI)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function CultivateJueXingUI:RegistMsgs()
    self.msgIds = 
    {
        -- LUIKaPaiPetEvent.ShowPetLeftInfo,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function CultivateJueXingUI:ProcessEvent(msg)
    -- if msg.msgId == LUIKaPaiPetEvent.ShowPetLeftInfo then
    -- end
end

function CultivateJueXingUI:Init()
    self:InitMembers()
    self:AddTouchEvt()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end

    self.m_pUILayer:registerScriptHandler(onNodeEvent)

end

function CultivateJueXingUI:InitMembers()
    self.m_pUILayer = cc.CSLoader:createNode("csd/zhuangbeiyangcheng/zhuangbeijuexing.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    local bg = self.m_pUILayer:getChildByName("zhuangbeijuexingUI"):getChildByName("juexing")
	self.manji = bg:getChildByName("manji")
	self.title2 = bg:getChildByName("Title_2")
	self.title3 = bg:getChildByName("Title_3")
    local attrBg = bg:getChildByName("jichushuxing")
    self.attrExBg = bg:getChildByName("fujiashuxing")
    self.costBg = bg:getChildByName("juexingxiaohao")

	self.m_curLevel = attrBg:getChildByName("Level_1")
    self.m_nextLevel = attrBg:getChildByName("Level_2")


    self._listView = attrBg:getChildByName("ListView")
    self._pCell = self._listView:getChildByName("Panel_1")
    self._pCell:removeFromParent()
    self._pCell:retain()

    self.m_levelStr = self.attrExBg:getChildByName("Text_1")
    self.m_attrEx1 = self.attrExBg:getChildByName("Text_2")
	self.costListView = self.costBg:getChildByName("ListView_1")
	self.costListView:setTouchEnabled(false)
	self.itemcell = self.costBg:getChildByName("Item")
    --self.m_costItem = self.costBg:getChildByName("Item")
    --self.m_costName = self.costBg:getChildByName("Name")
    --self.m_costValue = self.costBg:getChildByName("Value")
    self.m_jueXingBtn = self.costBg:getChildByName("yijianjinglianBtn")
    self.m_moneyValue = self.costBg:getChildByName("ConsumeBg"):getChildByName("Value")
    self.m_jueXingBtn:getChildByName("Text"):setString(GUITips.RSI_ZQX_QEUIP_CULTIVATE3)
end

function CultivateJueXingUI:AddTouchEvt()
    local function AutoJueXingCallBack(sender)
        --if LRoleDataMgr.Equip:CountItemNumById(self.stoneCost[1]) < self.stoneCost[3] then
        --    Utils:ShowScrollTips(string.format(GUITips.RSI_ZQX_QEUIP_CULTIVATE13,
        --        Utils:getItemNameByID(self.stoneCost[1])))
        --    return
        --end

        if LRoleDataMgr.MyHeroInfo.DetailData:getMoney() < self.moneyCost[3] then
            Utils:ShowScrollTips(GUITips.RSI_BP_SKILL_UPTIPS3)
            return
        end

        for i=1,#self.itemCost do
            local cost = self.itemCost[i]
            if LRoleDataMgr.Equip:CountItemNumById(cost[1]) < cost[3] then
                Utils:ShowScrollTips(string.format(GUITips.RSI_ZQX_QEUIP_CULTIVATE13,
                    Utils:getItemNameByID(cost[1])), true)
                return
            end
        end
        LuaNetSendMsg:SendEquipCultivate(self.m_equipId, 14, 1)
    end
    self.m_jueXingBtn:addClickEventListener(AutoJueXingCallBack)
    self:MarkIntaractCObj(self.m_jueXingBtn)
end

function CultivateJueXingUI:onExit()
    self.m_pUILayer = nil
    self.m_curLevel = nil
    self.m_nextLevel = nil
    self.m_attrInfo = nil
    self.m_levelStr = nil
    self.m_attrEx1 = nil
    self.m_costItem = nil
    self.m_costName = nil
    self.m_costValue = nil
    self.m_costItem = nil
    self.m_jueXingBtn = nil
    self.m_moneyValue = nil
    self:Destory()
end

function CultivateJueXingUI:UpdateData(equipId, update)
    self.m_equipId = equipId
	self.isMax = false
    local equip = LRoleDataMgr.Pet.equipList.m_petEquips[equipId]
    local curLevel = equip.cultivateLevel[3] or 0
    local nextLevel = curLevel
    if nextLevel < #JsonConfig.m_equipJueXing.getList() then
		nextLevel = nextLevel + 1 

		self.manji:setVisible(false)
		self.title3:setVisible(true)
		self.costBg:setVisible(true)
		self.m_nextLevel:setVisible(true)
	else
		--已经到达满级
		self.manji:setVisible(true)
		self.title3:setVisible(false)
		self.costBg:setVisible(false)
		self.m_nextLevel:setVisible(false)
		self.isMax = true
	end
    local ecfg = JsonConfig.m_equipConfig.getDefByID(equip.m_id)
    local cjcfg = JsonConfig.m_equipJueXing.getDefByID(curLevel)
    local njcfg = JsonConfig.m_equipJueXing.getDefByID(nextLevel)
    local nextAttrCfg = JsonConfig.m_equipJueXing.getDefByID(1)
	local attrExt = {}
    while true do
        if #nextAttrCfg.attr_add ~= 0 then
			if #attrExt == 0 then
				local value = nextAttrCfg.attr_add[equip.m_wpos]
				for i = 1, #value do
					table.insert(attrExt, value[i])
				end
			else
				local value = nextAttrCfg.attr_add[equip.m_wpos]
				attrExt[3] = attrExt[3] + value[3]
			end
			if nextAttrCfg.level >= nextLevel then
				break
			end
        end
        nextAttrCfg = JsonConfig.m_equipJueXing.getDefByID(nextAttrCfg.level + 1)
    end 
    local levelStr = GUITips.RSI_ZQX_QEUIP_CULTIVATE9
    if cjcfg ~= nil then
        levelStr = cjcfg.name
    end
    self.m_curLevel:setString(levelStr)
    self.m_nextLevel:setString(njcfg.name)

    self._listView:removeAllItems()
    for i=1, #ecfg.attr_juexing do
        local qattr = ecfg.attr_juexing[i]
        -- dump(qattr, "UpdateData ===== 11111111111 >")
        local item = self._pCell:clone()

        local _attrName = item:getChildByName("Value_0")
        local _curValue = item:getChildByName("Value_1")
        local _nextValue = item:getChildByName("Value_2")
        local _addValue = item:getChildByName("Value_3")

        _attrName:setString(Utils:getAttrName(qattr[1]))
        _curValue:setString(tostring(qattr[2] * curLevel))
        _nextValue:setString(tostring(qattr[2] * nextLevel))
        _addValue:setString(tostring(qattr[2]))
        self._listView:pushBackCustomItem(item)
		
		if self.isMax == true then
			item:getChildByName("Image"):setVisible(false)
			item:getChildByName("To"):setVisible(false)
			_nextValue:setVisible(false)
			_addValue:setVisible(false)
		else
			item:getChildByName("Image"):setVisible(true)
			item:getChildByName("To"):setVisible(true)
			_nextValue:setVisible(true)
			_addValue:setVisible(true)
		end
    end

    self.stoneCost = {}
    self.moneyCost = {}
    self.itemCost = {}
    for i=1,#njcfg.cost do
        local cost = njcfg.cost[i]
        if cost[1] == 60000 then
            self.moneyCost = cost
        elseif cost[1] == 854 then
            self.stoneCost = cost
        else
            self.itemCost[#self.itemCost + 1] = cost
        end
    end
	table.insert(self.itemCost,1,self.stoneCost)
    --Utils:GetItemCellValue(self.m_costItem, 0, self.stoneCost[1], true, false, 1, nil, false, false)
    --self.m_costName:setString(Utils:getItemNameByID(self.stoneCost[1]))
    --self.m_costValue:setString(string.format(GUITips.RSI_ZQX_HERO_BOOK5, LRoleDataMgr.Equip:CountItemNumById(self.stoneCost[1]), self.stoneCost[3]))
    self.m_moneyValue:setString(tostring(self.moneyCost[3]))
    if nextAttrCfg ~= nil then
        local attr = attrExt --nextAttrCfg.attr_add[equip.m_wpos]
        self.m_levelStr:setString(string.format(GUITips.RSI_ZQX_QEUIP_CULTIVATE11, nextAttrCfg.name))
        self.m_attrEx1:setString(string.format(GUITips.RSI_ZQX_QEUIP_CULTIVATE12,
            Utils:getAttrName(attr[2]), attr[3]/100))
        self.m_levelStr:setVisible(true)
        self.m_attrEx1:setVisible(true)
    else
        self.m_levelStr:setVisible(false)
        self.m_attrEx1:setVisible(false)
    end
	self:ShowJuexingCost(self.itemCost)
    --LGameMsg.m_netDealMsg:Change(LUIRoleEquipChangeEvent.EquipeJXCost,self.itemCost)
    --self:SendMsg(LGameMsg.m_netDealMsg)
    if curLevel % 10 == 0 and update then
		local data = {}
		data.equipId  = self.m_equipId
		data.type = 1
        Utils:InitUI("EquipCultivate.EquipStarUpSuccUI", AppDef.UIType.PopWindow, data)
    end
    -- if update ~= nil then
    --     Utils:InitUI("EquipCultivate.EquipStarUpSuccUI", AppDef.UIType.PopWindow, self.m_equipId)
    -- end
end

function CultivateJueXingUI:ShowJuexingCost(cost)
    self.costListView:removeAllItems()
    if cost == nil or #cost < 0 then return end
    for i=1, #cost do
        local item = self.itemcell:clone()
        Utils:GetItemCellValue(item, 0, cost[i][1], true, false, cost[i][3], nil, true, true)
        item:getChildByName("Value"):setString(string.format(GUITips.RSI_ZQX_HERO_BOOK5,
        LRoleDataMgr.Equip:CountItemNumById(cost[i][1]),cost[i][3]))

        self.costListView:pushBackCustomItem(item)
    end
end

return CultivateJueXingUI
