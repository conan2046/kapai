local ZhuangBeiFenJieUI = LUIBase:New()
ZhuangBeiFenJieUI.__index = ZhuangBeiFenJieUI

ZhuangBeiFenJieUI.IsHideInBattle = true
local EVERYLINENUM = 5
function ZhuangBeiFenJieUI:New()
    local o = {}
    setmetatable(o, ZhuangBeiFenJieUI)
    o:Init()
    return o
end

function ZhuangBeiFenJieUI:RegistMsgs()
    self.msgIds = 
    {
        LHuiShouEvent.SelectFenJieZhuangBei,
		LHuiShouEvent.FenJieZhuangBeiChaXun,
		LHuiShouEvent.FenJieZhuangBei,
    }
    self:RegistSelf(self, self.msgIds)
end

function ZhuangBeiFenJieUI:ProcessEvent(msg)
	if msg.msgId == LHuiShouEvent.SelectFenJieZhuangBei then
		self:UpdateEquipInfo(msg.value)
	elseif msg.msgId == LHuiShouEvent.FenJieZhuangBeiChaXun then
		self:UpdateRewardInfo(msg.value)
	elseif msg.msgId == LHuiShouEvent.FenJieZhuangBei then
		self:ResetUI()
	end
end

function ZhuangBeiFenJieUI:Init()
	self.m_pUILayer = nil
	self.m_pTableView = nil
	self.m_pEquipNodeList = {}
	self.m_pEquipIds = {}
	self:RegistMsgs()
	self:InitViewSize()
	self:InUIControl()
	self:setCloseCallback()
end

function ZhuangBeiFenJieUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/huishou/zhuangbeifenjie.csb")
	self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

function ZhuangBeiFenJieUI:InUIControl()
	local zhuangbeifenjie = self.m_pUILayer:getChildByName("zhuangbeifenjieUI")
	local bglayer = zhuangbeifenjie:getChildByName("Bg")
	for i = 1, 5 do
		local node = bglayer:getChildByName("Item_"..i)
		node:setTag(i)
		local addBtn = node:getChildByName("Btn_add")
		addBtn:addClickEventListener(handler(self,self.onOpenChooseUIClicked))
		self:MarkIntaractCObj(addBtn)

		local closeBtn = node:getChildByName("Btn_Close")
		closeBtn:addClickEventListener(handler(self,self.onDeleteItemClicked))
		self:MarkIntaractCObj(closeBtn)
		table.insert(self.m_pEquipNodeList, node)
	end
	local addBtn = bglayer:getChildByName("Btn_add")
	addBtn:addClickEventListener(handler(self,self.onQuickAddClicked))
	self:MarkIntaractCObj(addBtn)
	
	self.text = zhuangbeifenjie:getChildByName("Text")
	self.fenjie = zhuangbeifenjie:getChildByName("fenjie")
	self.fenjie:setVisible(false)
	local fenjieBtn = self.fenjie:getChildByName("Btn_fenjie")
	fenjieBtn:addClickEventListener(handler(self, self.onFenjieClicked))
	self:MarkIntaractCObj(fenjieBtn)

	local fanhuan = self.fenjie:getChildByName("fanhuan")
	self.tableviewPanel = fanhuan:getChildByName("TableView")
	self.itemlist = fanhuan:getChildByName("ItemList")
	self.itemlist:setVisible(false)
	self.item = fanhuan:getChildByName("Item")
	self.item:setVisible(false)
	self:InitTableView()
end

function ZhuangBeiFenJieUI:ResetUI()
	self.fenjie:setVisible(false)
	self.text:setVisible(true)
	for i = 1, #self.m_pEquipNodeList do
		self.m_pEquipNodeList[i]:removeChildByTag(222)
		self.m_pEquipNodeList[i]:getChildByName("Btn_Close"):setVisible(false)
	end
	self.m_pEquipIds = {}
end

function ZhuangBeiFenJieUI:UpdateEquipInfo(equipids)
	self:ResetUI()
	self.m_pEquipIds = equipids
	local equiplist = LRoleDataMgr.Pet.equipList.m_petEquips
	for i = 1, #equipids do
		local uid = equipids[i]
		local data = equiplist[uid]
		self.m_pEquipNodeList[i]:removeChildByTag(222)
		local pItem = Utils:GetEquipCellValue(self.m_pEquipNodeList[i],nil,data.m_id,data.m_uid)
		pItem:setPosition(cc.p(2,2))
		pItem:setTag(222)
		self.m_pEquipNodeList[i]:getChildByName("Btn_Close"):setZOrder(10000)
		self.m_pEquipNodeList[i]:getChildByName("Btn_Close"):setVisible(true)
	end
	self.fenjie:setVisible(true)
	self.text:setVisible(false)
	LuaNetSendMsg:SendPetEquipFenJie(32, equipids)
end

function ZhuangBeiFenJieUI:UpdateRewardInfo(data)
	self.m_pRewardList = data
	--资源返还
	self.m_pTableView:reloadData()
end

function ZhuangBeiFenJieUI:InitTableView()
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

    local function cellSizeForTable(sender,idx)
        local width = self.itemlist:getContentSize().width
        local height = self.itemlist:getContentSize().height
        return width, height
    end

    local function tableCellAtIndex(sender, idx)
        return self:TableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
		return math.ceil(#self.m_pRewardList / EVERYLINENUM)
    end

    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量

	self.m_pTableView = tableView
end

function ZhuangBeiFenJieUI:TableCellAtIndex(sender, idx)
	local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.itemlist:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)
        cellChild:setTouchEnabled(false)
		cellChild:setSwallowTouches(false)
		for i=1, EVERYLINENUM do
			local index = idx * EVERYLINENUM + i
			local data = self.m_pRewardList[index]
			if data ~= nil then
				local itemNode = self.item:clone()
				itemNode:setVisible(true)
				itemNode:setName("Item"..i)
				itemNode:setTag(index)
				itemNode:setTouchEnabled(false)
				local pitem = Utils:GetItemCellValue(itemNode,0, data[1],true,true, data[3],nil,true,true,false)
				pitem:setSwallowTouches(false)
				cellChild:pushBackCustomItem(itemNode)
			end
        end      
    else
        cellChild = cell:getChildByTag(123)
		cellChild:setTouchEnabled(false)
		for i=1, EVERYLINENUM do
			local index = idx*EVERYLINENUM+i
			local data = self.m_pRewardList[index]
			if data ~= nil then
				local itemNode = cellChild:getChildByName("Item"..i)
				if itemNode == nil then
					local itemNode = self.item:clone()
					itemNode:setVisible(true)
					itemNode:setName("Item"..i)
					itemNode:setTag(index)
					itemNode:setTouchEnabled(false)
					local pitem = Utils:GetItemCellValue(itemNode,0, data[1],true,true, data[3],nil,true,true,false)
					cellChild:pushBackCustomItem(itemNode)
				else
					itemNode:setVisible(true)
					local pitem = Utils:GetItemCellValue(itemNode,0, data[1],true,true, data[3],nil,true,true,false)
				end
			else
				local itemNode = cellChild:getChildByName("Item"..i)
				if itemNode ~= nil then
					itemNode:setVisible(false)
				end
			end
        end
    end
    
    return cell
end

function ZhuangBeiFenJieUI:onOpenChooseUIClicked(sender)
	local equipids = {}
	for i = 1, #self.m_pEquipIds do
		if self.m_pEquipIds[i] ~= 0 then
			table.insert(equipids, self.m_pEquipIds[i])
		end
	end
	Utils:OpenFunction(AppDef.EModuleID.EMID_ZHUANGBEI_FENJIE_CHOOSE, {0,equipids})
end
function ZhuangBeiFenJieUI:onDeleteItemClicked(sender)
	local tag = sender:getParent():getTag()
	local pItem = self.m_pEquipNodeList[tag]
	pItem:removeChildByTag(222)
	pItem:getChildByName("Btn_Close"):setVisible(false)
	self.m_pEquipIds[tag] = 0
	local equipids = {}
	for i = 1, #self.m_pEquipIds do
		if self.m_pEquipIds[i] ~= 0 then
			table.insert(equipids, self.m_pEquipIds[i])
		end
	end
	if #equipids == 0 then
		self:ResetUI()
	else
		LuaNetSendMsg:SendPetEquipFenJie(32, equipids)
	end
end


function ZhuangBeiFenJieUI:onQuickAddClicked(sender)
	local equipids = {}
	for i = 1, #self.m_pEquipIds do
		if self.m_pEquipIds[i] ~= 0 then
			table.insert(equipids, self.m_pEquipIds[i])
		end
	end
	
	local equiplist = {}
	local equipdatas = LRoleDataMgr.Pet.equipList.m_petEquips
	for k,v in pairs(equipdatas) do
		local cfg = JsonConfig.GetHeChengEquipCfg(5, v.m_id)
		if v.m_fpos == 0 and cfg ~= nil then
			table.insert(equiplist, v)
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
                return qhLv1 < qhLv1
            end
        else
            return m1.m_quality < m2.m_quality
        end
    end
	table.sort(equiplist, sortFuc)
	for k,v in pairs(equiplist) do
		if #equipids == 5 then
			break
		end
		local cfg = JsonConfig.GetHeChengEquipCfg(5, v.m_id)
		if v.m_quality < 4 and v.m_fpos == 0 and cfg ~= nil then
			local ishas = false
			for i = 1, #equipids do
				if v.m_uid == equipids[i] then
					ishas = true
					break
				end
			end
			if ishas == false then
				table.insert(equipids, v.m_uid)
			end
		end
	end
	if #equipids == 0 then
		Utils:ShowScrollTips("暂无可一键添加的装备")
		return
	end
	self:UpdateEquipInfo(equipids)
end

function ZhuangBeiFenJieUI:onFenjieClicked(sender)
	local data = {}
	local equipids = {}
	for i = 1, #self.m_pEquipIds do
		if self.m_pEquipIds[i] ~= 0 then
			table.insert(equipids, self.m_pEquipIds[i])
		end
	end
	data.equipids = equipids
	data.fanhuanlist = self.m_pRewardList
	Utils:OpenFunction(AppDef.EModuleID.EMID_CHONGSHENG_CONFIRM, data)
end

function ZhuangBeiFenJieUI:SetVisible(isShow)
	self.m_pUILayer:setVisible(true)
	self:CheckEquip()
end

function ZhuangBeiFenJieUI:CheckEquip()
	local equipids = {}
	for i = 1, #self.m_pEquipIds do
		if self.m_pEquipIds[i] ~= 0 then
			local data = LRoleDataMgr.Pet.equipList.m_petEquips[self.m_pEquipId]
			if data ~= nil then
				table.insert(equipids, self.m_pEquipIds[i])
			end
		end
	end
	if #equipids == 0 then
		self:ResetUI()
		return
	end
	self:UpdateEquipInfo(equipids)
end

function ZhuangBeiFenJieUI:setCloseCallback()
	local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

function ZhuangBeiFenJieUI:onExit()
	self:Destory()
	self.m_pUILayer = nil
end

function ZhuangBeiFenJieUI:CloseUI()
	Utils:DeleteUI("HuiShou.ZhuangBeiFenJieUI")
end

return ZhuangBeiFenJieUI