local ChongShengConfirmUI = LUIBase:New()
ChongShengConfirmUI.__index = ChongShengConfirmUI

ChongShengConfirmUI.IsHideInBattle = true

local EVERYLINENUM = 5
function ChongShengConfirmUI:New(data)
    local o = {}
    setmetatable(o, ChongShengConfirmUI)
    o:Init(data)
    return o
end

function ChongShengConfirmUI:Init(data)
	self.m_pUILayer = nil
	self.m_pTableView = nil
	self:InitViewSize()
	self:InUIControl()
	self:LoadData(data)
	self:setCloseCallback()
end

function ChongShengConfirmUI:InitViewSize()
	self.m_pUILayer = cc.CSLoader:createNode("csd/huishou/Popup_Confirm.csb")
	self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

function ChongShengConfirmUI:InUIControl()
	local popup = self.m_pUILayer:getChildByName("Popup")
	self.fanhuan = popup:getChildByName("fanhuan")
	local confirmBtn = popup:getChildByName("Btn_Confirm")
	confirmBtn:addClickEventListener(handler(self, self.onConfirmClicked))
	self:MarkIntaractCObj(confirmBtn)
	local cancelBtn = popup:getChildByName("Btn_Cancel")
	cancelBtn:addClickEventListener(handler(self, self.onCancelClicked))
	self:MarkIntaractCObj(cancelBtn)

	local closeBtn = popup:getChildByName("Btn_close")
	closeBtn:addClickEventListener(handler(self, self.onCancelClicked))
	self:MarkIntaractCObj(closeBtn)
end

function ChongShengConfirmUI:LoadData(data)
	self.petId = data.petid
	self.equipId = data.equipid
	self.equipIds = data.equipids
	self.fabaoId = data.fabaoid
	self.fabaoIds = data.fabaoids	
	self.m_pRewardList = data.fanhuanlist

	self.tableviewPanel = self.fanhuan:getChildByName("TableView")
	self.itemlist = self.fanhuan:getChildByName("ItemList")
	self.itemlist:setVisible(false)	
	self.item = self.fanhuan:getChildByName("Item")
	self.item:setVisible(false)
	self:InitTableView()
	self.m_pTableView:reloadData()
end

function ChongShengConfirmUI:InitTableView()
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

function ChongShengConfirmUI:TableCellAtIndex(sender, idx)
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
		for i=1, EVERYLINENUM do
			local index = idx * EVERYLINENUM + i
			local data = self.m_pRewardList[index]
			if data ~= nil then
				local itemNode = self.item:clone()
				itemNode:setVisible(true)
				itemNode:setName("Item"..i)
				itemNode:setTag(index)
				Utils:ShowItemByConfigData(data, itemNode, nil, true, true)
				cellChild:pushBackCustomItem(itemNode)
			end
        end      
    else
        cellChild = cell:getChildByTag(123)
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
					Utils:ShowItemByConfigData(data, itemNode, nil, true, true)
					cellChild:pushBackCustomItem(itemNode)
				else
					itemNode:setVisible(true)
					Utils:ShowItemByConfigData(data, itemNode, nil, true, true)
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

function ChongShengConfirmUI:onConfirmClicked(sender)
	if self.petId ~= nil then
		--神将重生
		LuaNetSendMsg:SendPetChongSheng(9, self.petId)
	elseif self.equipId ~= nil then
		--装备重生
		LuaNetSendMsg:SendPetEquipChongSheng(33, self.equipId)
	elseif self.equipIds ~= nil then
		--装备分解
		LuaNetSendMsg:SendPetEquipFenJie(33, self.equipIds)
	elseif self.fabaoId ~= nil then
		--法宝重生
		LuaNetSendMsg:SendPetFaBaoChongSheng(35, self.fabaoId)
	elseif self.fabaoIds ~= nil then
		--法宝分解
		LuaNetSendMsg:SendPetFaBaoFenJie(35, self.fabaoIds)
	end
	self:CloseUI()
end

function ChongShengConfirmUI:onCancelClicked(sender)
	self:CloseUI()
end

function ChongShengConfirmUI:setCloseCallback()
	local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    Utils:SendMsg(LUIPopFClassBgEvent.SetCloseCallback, handler(self, ChongShengConfirmUI.CloseUI))
end

function ChongShengConfirmUI:onExit()
	self:Destory()
	self.m_pUILayer = nil
end

function ChongShengConfirmUI:CloseUI()
	Utils:DeleteUI("HuiShou.ChongShengConfirmUI")
end

return ChongShengConfirmUI