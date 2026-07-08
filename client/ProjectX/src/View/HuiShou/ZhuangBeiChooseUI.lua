local ZhuangBeiChooseUI = LUIBase:New()
ZhuangBeiChooseUI.__index = ZhuangBeiChooseUI

ZhuangBeiChooseUI.IsHideInBattle = true

local EVERYLINENUM = 2
function ZhuangBeiChooseUI:New(data)
    local o = {}
    setmetatable(o, ZhuangBeiChooseUI)
    o:Init(data)
    return o
end

function ZhuangBeiChooseUI:Init(data)
	self.source = data[1]
	self.m_pUILayer = nil
	self.m_pTableView = nil
	self.selectedList = {}
	self:InitViewSize()
	self:InUIControl()
	if data[1] == 0 then
		Utils:SendMsg(LUIPopFClassBgEvent.SetTitle, GUITips.UI_HuiShou_ZhuangBei_Choose_Title)
		self:LoadEquipData(data[2])
	elseif data[1] == 1 then
		Utils:SendMsg(LUIPopFClassBgEvent.SetTitle, GUITips.UI_HuiShou_FaBao_Choose_Title)
		self:LoadFaBaoData(data[2])
	end
	self:setCloseCallback()
end

function ZhuangBeiChooseUI:InitViewSize()
	self:CreateUINode("csd/huishou/Choose_fenjie.csb");
	self.m_pChooseLayer = self.m_pUILayer;
	-- self.m_pUILayer = cc.Node:create()
	-- self.m_pUILayer:setContentSize(AppDef.frameSize)
	-- self.m_pChooseLayer = cc.CSLoader:createNode("csd/huishou/Choose_fenjie.csb")
	-- self.m_pChooseLayer:setContentSize(AppDef.frameSize)
	-- ccui.Helper:doLayout(self.m_pChooseLayer)
	-- self.m_pUILayer:addChild(self.m_pChooseLayer)
 --    ccui.Helper:doLayout(self.m_pUILayer)
end

function ZhuangBeiChooseUI:InUIControl()
	local chooseui = self.m_pChooseLayer:getChildByName("ChooseUI")
	local popup = chooseui:getChildByName("Popup")
	self.tableviewPanel = popup:getChildByName("TableView")
	self.pCell =  popup:getChildByName("ItemList")	
	self.pCell:removeFromParent()
    self.pCell:retain()
	
	self.number = popup:getChildByName("Number"):getChildByName("Value")
	self.number:setString(0)
	local chooseBtn = popup:getChildByName("Btn_Choose")
	chooseBtn:addClickEventListener(handler(self, self.onSelectClicked))
	self:MarkIntaractCObj(chooseBtn)

	self:InitTableView()
end

function ZhuangBeiChooseUI:InitTableView()
	local tableView = cc.TableView:create(self.tableviewPanel:getContentSize())
    tableView:setContentSize(self.tableviewPanel:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(cc.p(0, 0))
    tableView:setPosition(cc.p(0, 0))
    tableView:setDelegate()
    tableView:setSwallowsTouches(true)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
	tableView:setBounceable(false)
    self.tableviewPanel:addChild(tableView)

    local function cellSizeForTable(sender,idx)
        local width = self.pCell:getContentSize().width
        local height = self.pCell:getContentSize().height
        return width, height
    end

    local function tableCellAtIndex(sender, idx)
        return self:TableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
		if self.source == 0 then
			return math.ceil(#self.m_pEquipList / EVERYLINENUM)
		elseif self.source == 1 then
			return math.ceil(#self.m_pFaBaoList / EVERYLINENUM)
		end
    end

    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量

	self.m_pTableView = tableView
end

function ZhuangBeiChooseUI:LoadEquipData(uids)
	self.m_pEquipList = {}
	self.m_pEquipIds = uids
	local equiplist = LRoleDataMgr.Pet.equipList.m_petEquips
	for k,v in pairs(equiplist) do
		local cfg = JsonConfig.GetHeChengEquipCfg(5, v.m_id)
		if v.m_fpos == 0 and cfg ~= nil then
			table.insert(self.m_pEquipList, v)
		end
	end
	local function sortFuc(m1, m2)
        if m1.m_quality == m2.m_quality then
			local qhLv1 = m1.cultivateLevel[AppDef.PetEquipLevelType.QiangHua] or 0
			local qhLv2 = m2.cultivateLevel[AppDef.PetEquipLevelType.QiangHua] or 0
            if qhLv1 == qhLv2 then
				local jlLv1 = m1.cultivateLevel[AppDef.PetEquipLevelType.JingLian] or 0
				local jlLv2 = m2.cultivateLevel[AppDef.PetEquipLevelType.JingLian] or 0
                return jlLv1 < jlLv2
            else
                return qhLv1 < qhLv2
            end
        else
            return m1.m_quality < m2.m_quality
        end
    end
    table.sort(self.m_pEquipList, sortFuc)
	self.m_pTableView:reloadData()
end

function ZhuangBeiChooseUI:LoadFaBaoData(uids)
	self.m_pFaBaoList = {}
	self.m_pFaBaoIds = uids
	local fabaolist = LRoleDataMgr.Pet.faBaoList.m_petFaBaos
	for k,v in pairs(fabaolist) do
		local cfg = JsonConfig.GetHeChengEquipCfg(9, v.m_id)
		if v.m_fpos == 0 and cfg ~= nil then
			table.insert(self.m_pFaBaoList, v)
		end
	end
	local function sortFuc(m1, m2)
        if m1.baseData.quality == m2.baseData.quality then
			local qhLv1 = m1.qhLv--m1.cultivateLevel[AppDef.PetEquipLevelType.QiangHua] or 0
			local qhLv2 = m2.qhLv--m2.cultivateLevel[AppDef.PetEquipLevelType.QiangHua] or 0
            if qhLv1 == qhLv2 then
				local jlLv1 = m1.jlLv--m1.cultivateLevel[AppDef.PetEquipLevelType.JingLian] or 0
				local jlLv2 = m2.jlLv--m2.cultivateLevel[AppDef.PetEquipLevelType.JingLian] or 0
                return jlLv1 < jlLv2
            else
                return qhLv1 < qhLv2
            end
        else
            return m1.baseData.quality < m2.baseData.quality
        end
    end
    table.sort(self.m_pFaBaoList, sortFuc)
	--dump(self.m_pFaBaoList, "=============fabaolist=================>>>>>>>>")
	self.m_pTableView:reloadData()
end

function ZhuangBeiChooseUI:TableCellAtIndex(sender, idx)
	local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.pCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)
        cellChild:setTouchEnabled(false)
        
        for i=1, EVERYLINENUM do
            local pitem = cellChild:getChildByName("Item"..i)
            pitem:setSwallowTouches(false)
            local index = idx * EVERYLINENUM + i 
            pitem:setTag(index)
			local function tablefunc(sender, event)
				local ind = sender:getParent():getTag()
				if event == ccui.CheckBoxEventType.selected then
					if #self.selectedList == 5 then
						Utils:ShowScrollTips(GUITips.UI_Euqip_FenJie_Max)
						sender:setSelected(false)
						return
					end
					self:selectedItem(ind)
				elseif event == ccui.CheckBoxEventType.unselected then
					self:unselectedItem(ind)
				end
			end
			local checkbox = pitem:getChildByName("CheckBox")
			checkbox:addEventListener(tablefunc)
			if self.source == 0 then
				self:initEquipCellInfo(pitem, index)
			elseif self.source == 1 then
				self:initFaBaoCellInfo(pitem, index)
			end
        end      
    else
        cellChild = cell:getChildByTag(123)
        for i=1, EVERYLINENUM do
            local index = idx*EVERYLINENUM+i
            local pitem = cellChild:getChildByName("Item"..i)
            pitem:setTag(index)
			if self.source == 0 then
				self:initEquipCellInfo(pitem, index)
			elseif self.source == 1 then
				self:initFaBaoCellInfo(pitem, index)
			end
        end
    end
    
    return cell
end

function ZhuangBeiChooseUI:initEquipCellInfo(pItem, idx)
	if idx > #self.m_pEquipList then
		pItem:setVisible(false)
		return
	end
	pItem:setVisible(true)
	local data = self.m_pEquipList[idx]
	local name = pItem:getChildByName("Name")
	name:setColor(AppDef:GetQualityColor(data.m_quality))
	name:setString(data.m_name)
	local text1 = pItem:getChildByName("Text_1")
	local jlLv = data.cultivateLevel[AppDef.PetEquipLevelType.JingLian] or 0
	text1:setString( string.format("精炼:%d阶",jlLv))
	local text2 = pItem:getChildByName("Text_2")
	local jxLv = data.cultivateLevel[AppDef.PetEquipLevelType.JueXing] or 0
	if jxLv > 0 then
		local jcfg = JsonConfig.m_equipJueXing.getDefByID(jxLv)
		text2:setString( string.format("觉醒:%s",jcfg.name))
	else
		text2:setString( string.format("觉醒:%s",GUITips.RSI_ZQX_QEUIP_CULTIVATE9))
	end
	local text3 = pItem:getChildByName("Text_3")
	local szLv = data.cultivateLevel[AppDef.PetEquipLevelType.ShenZhu] or 0
	if szLv > 0 then
		local scfg = JsonConfig.m_equipShenZhu.getDefByID(szLv)
		text3:setString( string.format("神铸:%s",scfg.name))
	else
		text3:setString( string.format("神铸:%s",GUITips.RSI_ZQX_QEUIP_CULTIVATE10))
	end
	local qhLv = data.cultivateLevel[AppDef.PetEquipLevelType.QiangHua] or 0

	local icon = pItem:getChildByName("Icon")
	Utils:GetEquipCellValue(icon,nil,data.m_id,data.m_uid,qhLv,jlLv,szLv,jxLv,true,true, true)
	local checkbox = pItem:getChildByName("CheckBox")
	checkbox:setSelected(false)
	for i = 1, #self.m_pEquipIds do
		if self.m_pEquipIds[i] == data.m_uid then
			checkbox:setSelected(true)
			self:selectedItem(idx)
		end
	end
end

function ZhuangBeiChooseUI:initFaBaoCellInfo(pItem, idx)
	if idx > #self.m_pFaBaoList then
		pItem:setVisible(false)
		return
	end
	pItem:setVisible(true)
	local data = self.m_pFaBaoList[idx]
	local name = pItem:getChildByName("Name")
	name:setColor(AppDef:GetQualityColor(data.m_quality))
	name:setString(data.baseData.name)
	local text1 = pItem:getChildByName("Text_1")
	local qhLv = data.qhLv --data.cultivateLevel[AppDef.PetFaBaoLevelType.QiangHua] or 0
	text1:setString( string.format("强化:%d级",qhLv))
	local text2 = pItem:getChildByName("Text_2")
	local jlLv = data.jlLv --data.cultivateLevel[AppDef.PetFaBaoLevelType.JingLian] or 0
	text2:setString( string.format("精炼:%d级",jlLv))
	local text3 = pItem:getChildByName("Text_3")
	text3:setVisible(false)

	local icon = pItem:getChildByName("Icon")
	Utils:GetFaBaoCellValue(icon, nil, data.m_id, data.m_uid, false, 0, qhLv,jlLv,true,true)
	local checkbox = pItem:getChildByName("CheckBox")
	checkbox:setSelected(false)
	for i = 1, #self.m_pFaBaoIds do
		if self.m_pFaBaoIds[i] == data.m_uid then
			checkbox:setSelected(true)
			self:selectedItem(idx)
		end
	end
end

function ZhuangBeiChooseUI:selectedItem(ind)
	for k,v in pairs(self.selectedList) do
		if v == ind then
			return
		end
	end
	table.insert(self.selectedList, ind)
	self.number:setString(#self.selectedList)
end

function ZhuangBeiChooseUI:unselectedItem(ind)
	for k,v in pairs(self.selectedList) do
		if v == ind then
			table.remove(self.selectedList, k)
			break	
		end
	end
	self.number:setString(#self.selectedList)
end

function ZhuangBeiChooseUI:onSelectClicked(sender)
	local data = {}
	for k,v in pairs(self.selectedList) do
		if self.source == 0 then
			table.insert(data, self.m_pEquipList[v].m_uid)
		elseif self.source == 1 then
			table.insert(data, self.m_pFaBaoList[v].m_uid)
		end
	end
	if self.source == 0 then
		Utils:SendMsg(LHuiShouEvent.SelectFenJieZhuangBei, data)
	elseif self.source == 1 then
		Utils:SendMsg(LHuiShouEvent.SelectFenJieFaBao, data)
	end
	self:CloseUI()
end

function ZhuangBeiChooseUI:setCloseCallback()
	local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    Utils:SendMsg(LUIPopFClassBgEvent.SetCloseCallback, handler(self, ZhuangBeiChooseUI.CloseUI))
end

function ZhuangBeiChooseUI:onExit()
	self:Destory()
	self.m_pUILayer = nil
end

function ZhuangBeiChooseUI:CloseUI()
	Utils:DeleteUI("HuiShou.ZhuangBeiChooseUI")
end

return ZhuangBeiChooseUI