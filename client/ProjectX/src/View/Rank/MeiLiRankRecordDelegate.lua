local _RC = require("View.Rank.NewRankConfig")

local MeiLiRankRecordDelegate = {}
MeiLiRankRecordDelegate.__index = MeiLiRankRecordDelegate
-----------------------------------
function MeiLiRankRecordDelegate:New(uiLayer)
	if uiLayer == nil then
		return nil
	end
    local o = {}
    setmetatable(o, MeiLiRankRecordDelegate)
    o:Init(uiLayer)
    return o
end
-----------------------------------
function MeiLiRankRecordDelegate:Init(uiLayer)
	self.m_pUILayer = uiLayer
	self.m_tableCount = 0
	self.m_isDragging = false
	self.m_pTableView = nil
	self.m_pGridCell = nil
	self.m_pGridCellSize = nil
	self.m_pTablePanel = nil
	self.m_datas = nil
    -----------------------------------
    self:InitUIControl()
end
-----------------------------------
function MeiLiRankRecordDelegate:onExit()
    self.m_pUILayer = nil
    self.m_tableCount = nil
    self.m_isDragging = nil
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_pGridCellSize = nil
    self.m_pTablePanel = nil
    self.m_datas = nil
    self.m_pClickCallback = nil
end
-----------------------------------
function MeiLiRankRecordDelegate:InitUIControl()
	self.m_pUILayer:addClickEventListener(handler(self, MeiLiRankRecordDelegate.CloseUI))
	self.m_pUILayer:setVisible(false)
	self.m_pUILayer:setSwallowTouches(false)

	self.m_pTablePanel = self.m_pUILayer:getChildByName("List")
	self.m_pTablePanel:setTouchEnabled(true)
	self.m_pTablePanel:setVisible(true)

	self.m_pGridCell = self.m_pUILayer:getChildByName("TextPanel")
	self.m_pGridCell:setTouchEnabled(false)
	self.m_pGridCellSize = self.m_pGridCell:getContentSize()

	self.m_pTableView = self:InitTableView(self.m_pTablePanel)
	self.m_pTableView:setSwallowTouches(false)
end
-----------------------------------
function MeiLiRankRecordDelegate:InitTableView(tbPanel)
    local cfg = {}
    cfg.tbPanel = tbPanel
    cfg.cellSizeForTable = function(sender,idx)
        local width = self.m_pGridCellSize.width
        local height = self.m_pGridCellSize.height
        return width, height
    end
    cfg.tableCellAtIndex = function(sender, idx)
        return self:TableCellAtIndex(sender, idx + 1)
    end

    cfg.numberOfCellsInTableView = function() 
        return self.m_tableCount
    end

    cfg.scrollViewDidScroll = function(view)
        self.m_isDragging = view:isDragging()
    end

    cfg.tableCellTouched = function(sender, cell)
        return self:TableCellTouched(cell:getIdx() + 1)
    end

    return Utils:createTableView(cfg)
end
-----------------------------------
function MeiLiRankRecordDelegate:TableCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild = nil
    
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pGridCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)
    else
        cellChild = cell:getChildByTag(123)
    end
    if cellChild ~= nil then
        self:updateItem(cellChild, idx)
    end
    return cell
end
-----------------------------------
function MeiLiRankRecordDelegate:updateItem(cell, idx)
	if cell == nil or idx == nil then
		return
	end
	local pText = cell:getChildByName("Text")
	local _ = pText and pText:setString(string.format(GUITips.RSI_TARGET_RD_TIPS20, idx))
end
-----------------------------------
function MeiLiRankRecordDelegate:updateData(count)
	if self.m_pTableView == nil then
		return
	end
	self.m_tableCount = count
	self.m_pTableView:reloadData()
	self.m_pUILayer:setVisible(true)
end
-----------------------------------
function MeiLiRankRecordDelegate:TableCellTouched(idx)
    if self.m_pClickCallback then
    	self.m_pClickCallback(idx)
    end
    self:CloseUI()
end
-----------------------------------
function MeiLiRankRecordDelegate:SetClickCallback(callback)
	self.m_pClickCallback = callback
end
-----------------------------------
function MeiLiRankRecordDelegate:CloseUI(sender)
	self.m_pUILayer:setVisible(false)
end
-----------------------------------
return MeiLiRankRecordDelegate