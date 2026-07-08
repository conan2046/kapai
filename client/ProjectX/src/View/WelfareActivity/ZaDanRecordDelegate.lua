local ZaDanRecordDelegate = {}
ZaDanRecordDelegate.__index = ZaDanRecordDelegate
-----------------------------------
function ZaDanRecordDelegate:New(uiLayer, pCell)
    local o = {}
    setmetatable(o, ZaDanRecordDelegate)
    o:Init(uiLayer, pCell)
    return o
end
-----------------------------------
function ZaDanRecordDelegate:Init(uiLayer, pCell)
    self.Script = "WelfareActivity.ZaDanRecordDelegate"
    self.m_pUILayer = uiLayer
    self.m_tableCount = 0
    self.m_pTablePanel = uiLayer
    self.m_pGridCell = pCell
    self.m_pGridCellSize = pCell:getContentSize()
    self.m_datas = nil
    self.m_pTableView = self:InitTableView(self.m_pTablePanel)
    --------------------------------------
    self:setCloseCallback()

end
-----------------------------------
function ZaDanRecordDelegate:onExit()
    self.Script = nil
    self.m_pUILayer = nil
    self.m_tableCount = nil
    self.m_pTablePanel = nil
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_pGridCellSize = nil
    self.m_datas = nil
end
-----------------------------------
function ZaDanRecordDelegate:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
-----------------------------------
function ZaDanRecordDelegate:InitTableView(tbPanel)
    local cfg = {}
    cfg.tbPanel = tbPanel
    cfg.cellSizeForTable = function(sender,idx)
        local width = self.m_pGridCellSize.width
        local height = self.m_pGridCellSize.height
        return width, height
    end
    cfg.tableCellAtIndex = function(sender, idx)
        return self:TableCellAtIndex(sender, idx)
    end

    cfg.numberOfCellsInTableView = function() 
        return self.m_tableCount
    end

    return Utils:createTableView(cfg)
end
-----------------------------------
function ZaDanRecordDelegate:TableCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild = nil
    
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pGridCell:clone()
        cellChild:setAnchorPoint(cc.p(0, 0))
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)
        cellChild = Utils:CreateColorText2(cell, cellChild)
        cellChild:setTag(123)
    else
        cellChild = cell:getChildByTag(123)
    end
    if cellChild ~= nil then
        self:updateItem(cellChild, self.m_datas[idx+1])
    end
    return cell
end
-----------------------------------
function ZaDanRecordDelegate:updateItem(cell, info)
	if cell ~= nil then
		cell:setString(info or "")
	end
end
-----------------------------------
function ZaDanRecordDelegate:updateData(datas)
	self.m_datas = nil
	self.m_datas = datas or {}
	self.m_tableCount = #self.m_datas
	self.m_pTableView:reloadData()
end
-----------------------------------
function ZaDanRecordDelegate:appendData(datas)
	if datas == nil then
		return
	end
	self.m_datas = self.m_datas or {}
	for i=#datas,1,-1 do
		if datas[i] then
			table.insert(self.m_datas, 1, datas[i])
		end
	end
	self.m_tableCount = #self.m_datas
	self.m_pTableView:reloadData()
end

-----------------------------------
return ZaDanRecordDelegate