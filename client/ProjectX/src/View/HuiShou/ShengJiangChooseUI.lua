local ShengJiangChooseUI = LUIBase:New()
ShengJiangChooseUI.__index = ShengJiangChooseUI

ShengJiangChooseUI.IsHideInBattle = true

local EVERYLINENUM = 2
function ShengJiangChooseUI:New(data)
    local o = {}
    setmetatable(o, ShengJiangChooseUI)
    o:Init(data,limitColor)
    return o
end

function ShengJiangChooseUI:Init(data)
	--dump(data,"ShengJiangChooseUI data ===>")
	self.source = data[1] --1 神将选择 2 装备选择 3 法宝选择
    self.limitColor = data[2] or 0--限制当前品质（含）以下显示，0-不限制(游历用)
    self.ids = data[3] or {}--需要过滤的id列表(游历用)
    --print("===================>", self.source,self.limitColor)
	self.m_pUILayer = nil
	self.m_pTableView = nil
	self:InitViewSize()
	self:InUIControl()
	if self.source == 1 then
		Utils:SendMsg(LUIPopFClassBgEvent.SetTitle, GUITips.UI_HuiShou_ShengJiang_Choose_Title)
		self:LoadShengJiangData()
	elseif self.source == 2 then
		Utils:SendMsg(LUIPopFClassBgEvent.SetTitle, GUITips.UI_HuiShou_ZhuangBei_Choose_Title)
		self:LoadZhuangBeiData()
	elseif self.source == 3 then
		Utils:SendMsg(LUIPopFClassBgEvent.SetTitle, GUITips.UI_HuiShou_FaBao_Choose_Title)
		self:LoadFaBaoData()
	end
	self:setCloseCallback()
end

function ShengJiangChooseUI:InitViewSize()
	self.m_pUILayer = cc.Node:create()
	
	self.m_pChooseLayer = cc.CSLoader:createNode("csd/common/Choose.csb")
	self.m_pChooseLayer:setContentSize(AppDef.frameSize)
	ccui.Helper:doLayout(self.m_pChooseLayer)
	self.m_pUILayer:addChild(self.m_pChooseLayer)
    ccui.Helper:doLayout(self.m_pUILayer)
end

function ShengJiangChooseUI:InUIControl()
	local chooseui = self.m_pChooseLayer:getChildByName("ChooseUI")
	local popup = chooseui:getChildByName("Popup")
	self.tableviewPanel = popup:getChildByName("TableView")
	self.pCell =  popup:getChildByName("ItemList")	
	self.pCell:removeFromParent()
    self.pCell:retain()
	
	self:InitTableView()
end

function ShengJiangChooseUI:LoadShengJiangData()
	self.m_pPetList = {}
	local petlist = LRoleDataMgr.Pet.petlist
	for i = 1, #petlist do
		local petdata = petlist[i]
        if self:CheckIds(petdata.id) then
            if (self.limitColor == 0 and petdata.fightPos == 0 and petdata.level > 1 or petdata.breakLevel > 0) or (petdata.baseData ~= nil and self.limitColor > 0 and self.limitColor >= petdata.baseData.quality) then
               table.insert(self.m_pPetList, petdata)
            end
        end
	end
    --dump(self.m_pPetList)
	self.m_pTableView:reloadData()
end

function ShengJiangChooseUI:CheckIds(id)
    for i=1,#self.ids do
        if self.ids[i] == id then
            return false
        end
    end
    return true
end

function ShengJiangChooseUI:LoadZhuangBeiData()
	self.m_pEquipList = {}

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
                return jlLv1 > jlLv2
            else
                return qhLv1 > qhLv2
            end
        else
            return m1.m_quality > m2.m_quality
        end
    end
    table.sort(self.m_pEquipList, sortFuc)
	self.m_pTableView:reloadData()
end

function ShengJiangChooseUI:LoadFaBaoData()
	self.m_pFaBaoList = {}
	local fabaolist = LRoleDataMgr.Pet.faBaoList.m_petFaBaos
	for k,v in pairs(fabaolist) do
		local cfg = JsonConfig.GetHeChengEquipCfg(9, v.m_id)
		if v.m_fpos == 0 and cfg ~= nil and (v.qhLv > 0 or v.jlLv > 0) then
			table.insert(self.m_pFaBaoList, v)
		end
	end
	local function sortFuc(m1, m2)
        if m1.baseData.quality == m2.baseData.quality then
			local qhLv1 = m1.qhLv --m1.cultivateLevel[AppDef.PetFaBaoLevelType.QiangHua] or 0
			local qhLv2 = m2.qhLv --m2.cultivateLevel[AppDef.PetFaBaoLevelType.QiangHua] or 0
            if qhLv1 == qhLv2 then
				local jlLv1 = m1.jlLv --m1.cultivateLevel[AppDef.PetFaBaoLevelType.JingLian] or 0
				local jlLv2 = m2.jlLv --m2.cultivateLevel[AppDef.PetFaBaoLevelType.JingLian] or 0
                return jlLv1 > jlLv2
            else
                return qhLv1 > qhLv2
            end
        else
            return m1.baseData.quality > m2.baseData.quality
        end
    end
    table.sort(self.m_pFaBaoList, sortFuc)
	--dump(fabaolist, "=============fabaolist=================>>>>>>>>")
	self.m_pTableView:reloadData()
end

function ShengJiangChooseUI:InitTableView()
	local tableView = cc.TableView:create(self.tableviewPanel:getContentSize())
    tableView:setContentSize(self.tableviewPanel:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(cc.p(0, 0))
    tableView:setPosition(cc.p(0, 0))
    tableView:setDelegate()
    tableView:setSwallowsTouches(true)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
	--tableView:setBounceable(false)
    self.tableviewPanel:addChild(tableView)

	local function tableCellTouched(sender,cell)
        self:TableCellTouched(sender, cell)
    end

    local function cellSizeForTable(sender,idx)
        local width = self.pCell:getContentSize().width
        local height = self.pCell:getContentSize().height
        return width, height
    end

    local function tableCellAtIndex(sender, idx)
        return self:TableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
		if self.source == 1 then
			return math.ceil(#self.m_pPetList / EVERYLINENUM) 
		elseif self.source == 2 then
			return math.ceil(#self.m_pEquipList / EVERYLINENUM) 
		elseif self.source == 3 then
			return math.ceil(#self.m_pFaBaoList / EVERYLINENUM) 
		end
    end

    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量

	self.m_pTableView = tableView
end

function ShengJiangChooseUI:TableCellTouched(sender, cell)
	
end

function ShengJiangChooseUI:TableCellAtIndex(sender, idx)
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
			local chooseBtn = pitem:getChildByName("Btn_Choose")
			if self.source == 1 then
				chooseBtn:addClickEventListener(handler(self, self.ChooseShengJiangClicked)) 
				self:MarkIntaractCObj(chooseBtn)
				self:initPetCellInfo(pitem, index)
			elseif self.source == 2 then
				chooseBtn:addClickEventListener(handler(self, self.ChooseZhuangBeiClicked)) 
				self:MarkIntaractCObj(chooseBtn)
				self:initEquipCellInfo(pitem, index)
			elseif self.source == 3 then
				chooseBtn:addClickEventListener(handler(self, self.ChooseFaBaoClicked)) 
				self:MarkIntaractCObj(chooseBtn)
				self:initFaBaoCellInfo(pitem, index)
			end
        end      
    else
        cellChild = cell:getChildByTag(123)
        for i=1, EVERYLINENUM do
            local index = idx*EVERYLINENUM+i
            local pitem = cellChild:getChildByName("Item"..i)
            pitem:setTag(index)
			if self.source == 1 then
				self:initPetCellInfo(pitem, index)
			elseif self.source == 2 then
				self:initEquipCellInfo(pitem, index)
			end
        end
    end
    
    return cell
end

function ShengJiangChooseUI:initPetCellInfo(pItem, idx)
	if idx > #self.m_pPetList then
		pItem:setVisible(false)
		return
	end
	pItem:setVisible(true)
	local data = self.m_pPetList[idx]
	local name = pItem:getChildByName("Name")
	name:setColor(AppDef:GetQualityColor(data.baseData.quality))
	name:setString(data.name)
	local attr1 = pItem:getChildByName("Atrribute_1")
	attr1:setString( string.format("等级:%d",data.level))
	local attr2 = pItem:getChildByName("Atrribute_2")
	attr2:setString( string.format("突破:+%d",data.breakLevel))
	local icon = pItem:getChildByName("Icon")
	local attr3 = pItem:getChildByName("Atrribute_3")
	attr3:setVisible(false)
	--Utils:ShowPetHeadImg(icon,data.baseData.pic,nil,data.baseData.quality,data:IsShiny())
	Utils:GetPetHeadCellValue(icon, nil, data,true)
end

function ShengJiangChooseUI:initEquipCellInfo(pItem, idx)
	if idx > #self.m_pEquipList then
		pItem:setVisible(false)
		return
	end
	pItem:setVisible(true)
	local data = self.m_pEquipList[idx]
	local name = pItem:getChildByName("Name")
	name:setColor(AppDef:GetQualityColor(data.m_quality))
	name:setString(data.m_name)
	local icon = pItem:getChildByName("Icon")
	local attr1 = pItem:getChildByName("Atrribute_1")
	local jlLv = data.cultivateLevel[AppDef.PetEquipLevelType.JingLian] or 0
	attr1:setString( string.format("精炼:%d阶",jlLv))
	local attr2 = pItem:getChildByName("Atrribute_2")
	local jxLv = data.cultivateLevel[AppDef.PetEquipLevelType.JueXing] or 0
	if jxLv > 0 then
		local jcfg = JsonConfig.m_equipJueXing.getDefByID(jxLv)
		attr2:setString( string.format("觉醒:%s",jcfg.name))
	else
		attr2:setString( string.format("觉醒:%s",GUITips.RSI_ZQX_QEUIP_CULTIVATE9))
	end
	local attr3 = pItem:getChildByName("Atrribute_3")
	local szLv = data.cultivateLevel[AppDef.PetEquipLevelType.ShenZhu] or 0
	if szLv > 0 then
		local scfg = JsonConfig.m_equipShenZhu.getDefByID(szLv)
		attr3:setString( string.format("神铸:%s",scfg.name))
	else
		attr3:setString( string.format("神铸:%s",GUITips.RSI_ZQX_QEUIP_CULTIVATE10))
	end
	local qhLv = data.cultivateLevel[AppDef.PetEquipLevelType.QiangHua] or 0
	Utils:GetEquipCellValue(icon,nil,data.m_id,data.m_uid,qhLv,jlLv, szLv,jxLv,true,true, true)
end

function ShengJiangChooseUI:initFaBaoCellInfo(pItem, idx)
	if idx > #self.m_pFaBaoList then
		pItem:setVisible(false)
		return
	end
	pItem:setVisible(true)
	local data = self.m_pFaBaoList[idx]
	local name = pItem:getChildByName("Name")
	name:setColor(AppDef:GetQualityColor(data.m_quality))
	name:setString(data.baseData.name)
	local icon = pItem:getChildByName("Icon")
	local attr1 = pItem:getChildByName("Atrribute_1")
	--local qhLv = data.cultivateLevel[AppDef.PetFaBaoLevelType.QiangHua] or 0
	attr1:setString( string.format("强化:%d级",data.qhLv))
	local attr2 = pItem:getChildByName("Atrribute_2")
	--local jlLv = data.cultivateLevel[AppDef.PetFaBaoLevelType.JingLian] or 0
	attr2:setString( string.format("精炼:%d级",data.jlLv))
	local attr3 = pItem:getChildByName("Atrribute_3")
	attr3:setVisible(false)
	Utils:GetFaBaoCellValue(icon, nil, data.m_id, data.m_uid, false, 0, qhLv,jlLv,true,true)
end

function ShengJiangChooseUI:ChooseShengJiangClicked(sender)
	print("===============>",sender:getParent():getTag())
	local idx = sender:getParent():getTag()
	local petdata = self.m_pPetList[idx]
	Utils:SendMsg(LHuiShouEvent.SelectShengJiang, petdata.id)
	self:CloseUI()
end

function ShengJiangChooseUI:ChooseZhuangBeiClicked(sender)
	print("===============>",sender:getParent():getTag())
	local idx = sender:getParent():getTag()
	local equipdata = self.m_pEquipList[idx]
	Utils:SendMsg(LHuiShouEvent.SelectZhuangBei, equipdata.m_uid)
	self:CloseUI()
end

function ShengJiangChooseUI:ChooseFaBaoClicked(sender)
	print("===============>",sender:getParent():getTag())
	local idx = sender:getParent():getTag()
	local fabaodata = self.m_pFaBaoList[idx]
	Utils:SendMsg(LHuiShouEvent.SelectFaBao, fabaodata.m_uid)
	self:CloseUI()
end

function ShengJiangChooseUI:setCloseCallback()
	local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    Utils:SendMsg(LUIPopFClassBgEvent.SetCloseCallback, handler(self, ShengJiangChooseUI.CloseUI))
end

function ShengJiangChooseUI:onExit()
	self:Destory()
	self.m_pUILayer = nil
end

function ShengJiangChooseUI:CloseUI()
	Utils:DeleteUI("HuiShou.ShengJiangChooseUI")
    Utils:SendMsg(LUIActivityEvent.CloseShenJiangChooseUI)
end

return ShengJiangChooseUI