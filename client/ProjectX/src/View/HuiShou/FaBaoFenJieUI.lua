local FaBaoFenJieUI = LUIBase:New()
FaBaoFenJieUI.__index = FaBaoFenJieUI

FaBaoFenJieUI.IsHideInBattle = true
local EVERYLINENUM = 5
function FaBaoFenJieUI:New()
    local o = {}
    setmetatable(o, FaBaoFenJieUI)
    o:Init()
    return o
end

function FaBaoFenJieUI:RegistMsgs()
    self.msgIds = 
    {
        LHuiShouEvent.SelectFenJieFaBao,
		LHuiShouEvent.FenJieFaBaoChaXun,
		LHuiShouEvent.FenJieFaBao,
    }
    self:RegistSelf(self, self.msgIds)
end

function FaBaoFenJieUI:ProcessEvent(msg)
	if msg.msgId == LHuiShouEvent.SelectFenJieFaBao then
		self:UpdateFaBaoInfo(msg.value)
	elseif msg.msgId == LHuiShouEvent.FenJieFaBaoChaXun then
		self:UpdateRewardInfo(msg.value)
	elseif msg.msgId == LHuiShouEvent.FenJieFaBao then
		self:ResetUI()
	end
end

function FaBaoFenJieUI:Init()
	self.m_pUILayer = nil
	self.m_pTableView = nil
	self.m_pFaBaoNodeList = {}
	self.m_pFaBaoIds = {}
	self:RegistMsgs()
	self:InitViewSize()
	self:InUIControl()
	self:setCloseCallback()
end

function FaBaoFenJieUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/huishou/fabaofenjie.csb")
	self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

function FaBaoFenJieUI:InUIControl()
	local zhuangbeifenjie = self.m_pUILayer:getChildByName("fabaofenjieUI")
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
		table.insert(self.m_pFaBaoNodeList, node)
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

function FaBaoFenJieUI:ResetUI()
	self.fenjie:setVisible(false)
	self.text:setVisible(true)
	for i = 1, #self.m_pFaBaoNodeList do
		self.m_pFaBaoNodeList[i]:removeChildByTag(222)
		self.m_pFaBaoNodeList[i]:getChildByName("Btn_Close"):setVisible(false)
	end
	self.m_pFaBaoIds = {}
end

function FaBaoFenJieUI:UpdateFaBaoInfo(fabaoids)
	self:ResetUI()
	self.m_pFaBaoIds = fabaoids
	local fabaolist = LRoleDataMgr.Pet.faBaoList.m_petFaBaos
	for i = 1, #fabaoids do
		local uid = fabaoids[i]
		local data = fabaolist[uid]
		self.m_pFaBaoNodeList[i]:removeChildByTag(222)
		local pItem = Utils:GetFaBaoCellValue(self.m_pFaBaoNodeList[i], nil, data.m_id, data.m_uid, false, 0, 0, 0,false,true)
		--pItem:setPosition(cc.p(2,2))
		pItem:setTag(222)
		self.m_pFaBaoNodeList[i]:getChildByName("Btn_Close"):setZOrder(10000)
		self.m_pFaBaoNodeList[i]:getChildByName("Btn_Close"):setVisible(true)
	end
	self.fenjie:setVisible(true)
	self.text:setVisible(false)
	LuaNetSendMsg:SendPetFaBaoFenJie(34, fabaoids)
end

function FaBaoFenJieUI:UpdateRewardInfo(data)
	self.m_pRewardList = data
	--资源返还
	self.m_pTableView:reloadData()
end

function FaBaoFenJieUI:InitTableView()
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

function FaBaoFenJieUI:TableCellAtIndex(sender, idx)
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
				Utils:ShowItemByConfigData(data, itemNode, nil, true, true)
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
					local pitem = Utils:ShowItemByConfigData(data, itemNode, nil, true, true)
					cellChild:pushBackCustomItem(itemNode)
				else
					itemNode:setVisible(true)
					local pitem = Utils:ShowItemByConfigData(data, itemNode, nil, true, true)
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

function FaBaoFenJieUI:onOpenChooseUIClicked(sender)
	local fabaoids = {}
	for i = 1, #self.m_pFaBaoIds do
		if self.m_pFaBaoIds[i] ~= 0 then
			table.insert(fabaoids, self.m_pFaBaoIds[i])
		end
	end
	Utils:OpenFunction(AppDef.EModuleID.EMID_FABAO_FENJIE_CHOOSE, {1,fabaoids})
end
function FaBaoFenJieUI:onDeleteItemClicked(sender)
	local tag = sender:getParent():getTag()
	local pItem = self.m_pFaBaoNodeList[tag]
	pItem:removeChildByTag(222)
	pItem:getChildByName("Btn_Close"):setVisible(false)
	self.m_pFaBaoIds[tag] = 0
	local fabaoids = {}
	for i = 1, #self.m_pFaBaoIds do
		if self.m_pFaBaoIds[i] ~= 0 then
			table.insert(fabaoids, self.m_pFaBaoIds[i])
		end
	end
	if #fabaoids == 0 then
		self:ResetUI()
	else
		LuaNetSendMsg:SendPetFaBaoFenJie(34, fabaoids)
	end
end


function FaBaoFenJieUI:onQuickAddClicked(sender)
	local fabaoids = {}
	for i = 1, #self.m_pFaBaoIds do
		if self.m_pFaBaoIds[i] ~= 0 then
			table.insert(fabaoids, self.m_pFaBaoIds[i])
		end
	end
	
	local fabaolist = {}
	local fabaodatas = LRoleDataMgr.Pet.faBaoList.m_petFaBaos
	for k,v in pairs(fabaodatas) do
		local cfg = JsonConfig.GetHeChengEquipCfg(9, v.m_id)
		if v.m_fpos == 0 and cfg ~= nil then
			table.insert(fabaolist, v)
		end
	end
	local function sortFuc(m1, m2)
        if m1.baseData.quality == m2.baseData.quality then
			local qhLv1 = m1.qhLv
			local qhLv2 = m2.qhLv
            if qhLv1 == qhLv2 then
				local jlLv1 = m1.jlLv
				local jlLv2 = m2.jlLv
                return jlLv1 < jlLv2
            else
                return qhLv1 < qhLv1
            end
        else
            return m1.baseData.quality < m2.baseData.quality
        end
    end
	table.sort(fabaolist, sortFuc)
	for k,v in pairs(fabaolist) do
		if #fabaoids == 5 then
			break
		end
		local cfg = JsonConfig.GetHeChengEquipCfg(9, v.m_id)
		if v.baseData.quality < 4 and v.m_fpos == 0 and cfg ~= nil then
			local ishas = false
			for i = 1, #fabaoids do
				if v.m_uid == fabaoids[i] then
					ishas = true
					break
				end
			end
			if ishas == false then
				table.insert(fabaoids, v.m_uid)
			end
		end
	end
	if #fabaoids == 0 then
		Utils:ShowScrollTips("暂无可一键添加的装备")
		return
	end
	self:UpdateFaBaoInfo(fabaoids)
end

function FaBaoFenJieUI:onFenjieClicked(sender)
	local data = {}
	local fabaoids = {}
	for i = 1, #self.m_pFaBaoIds do
		if self.m_pFaBaoIds[i] ~= 0 then
			table.insert(fabaoids, self.m_pFaBaoIds[i])
		end
	end
	data.fabaoids = fabaoids
	data.fanhuanlist = self.m_pRewardList
	Utils:OpenFunction(AppDef.EModuleID.EMID_CHONGSHENG_CONFIRM, data)
end

function FaBaoFenJieUI:SetVisible(isShow)
	self.m_pUILayer:setVisible(true)
	self:CheckFaBao()
end

function FaBaoFenJieUI:CheckFaBao()
	local fabaoids = {}
	for i = 1, #self.m_pFaBaoIds do
		if self.m_pFaBaoIds[i] ~= 0 then
			table.insert(fabaoids, self.m_pFaBaoIds[i])
		end
	end
	if #fabaoids == 0 then
		return
	end
	self:UpdateFaBaoInfo(fabaoids)
end

function FaBaoFenJieUI:setCloseCallback()
	local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

function FaBaoFenJieUI:onExit()
	self:Destory()
	self.m_pUILayer = nil
end

function FaBaoFenJieUI:CloseUI()
	Utils:DeleteUI("HuiShou.FaBaoFenJieUI")
end

return FaBaoFenJieUI
