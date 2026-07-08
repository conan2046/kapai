local ShopTable = LUIBase:New()
ShopTable.__index = ShopTable



local CountOfRaw = 3

-- -----------------------------------
function ShopTable:New(tbPanel, gridCell)
    local o = {}
    setmetatable(o, ShopTable)
    o:Init(tbPanel, gridCell)
    return o
end

-- -----------------------------------
function ShopTable:Init(tbPanel, gridCell)
    self.m_pGridCell = gridCell  --单元格模板
    self.m_pTablePanel = tbPanel
    self.m_isDragging = false  --是否正在拖拽列表
    self.m_curGridNum = 0      --当前Cell的数量
    self.m_pItemLists = {} --道具Item Map表
    self.m_curSelectedIdx = 0 --当前选中的道具Index
    self.m_cellCount = 0      --单元格计数，为m_pItemLists服务

    self.m_curDelegate = nil
    self.m_selectCallback = nil

    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
end

-- -----------------------------------
function ShopTable:onExit()
    self:Destory()
    self.m_pUILayer = nil

    for key,value in pairs(self.m_pItemLists) do 
       value:onExit(true)
       self.m_pItemLists[key] = nil
    end
    self.m_pItemLists = nil

    self.m_curDelegate = nil

    self.m_pGridCell = nil  --单元格模板
    self.m_pTablePanel = nil
    self.m_isDragging = nil  --是否正在拖拽列表
    self.m_curGridNum = nil      --当前Cell的数量
    self.m_pItemLists = nil
    self.m_curSelectedIdx = nil
    self.m_cellCount = nil

    self.m_curDelegate = nil
    self.m_selectCallback = nil
    self.m_pTableView = nil
end
-------------------------------------
function ShopTable:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

-------------------------------------
function ShopTable:InitViewSize()
    self.m_pUILayer = self.m_pTablePanel
end

function ShopTable:InitUIControl()
    self.m_pTableView = self:InitTableView(self.m_pTablePanel)
end

function ShopTable:setDelegate(delegate)
    if self.m_curDelegate and self.m_curDelegate.Reset then
        self.m_curDelegate:Reset()
    end
    self.m_curDelegate = delegate
    if self.m_curDelegate ~= nil then
        self.m_curDelegate:setDataSource(self)
    end
end

function ShopTable:getDelegate()
    return self.m_curDelegate
end

function ShopTable:setSelectCallback(cb)
    self.m_selectCallback = nil
    self.m_selectCallback = cb
end

function ShopTable:updateData(msg)
    self.m_curDelegate:updateData(msg)
end

function ShopTable:InitTableView(tbPanel)
    local cfg = {}
    cfg.tbPanel = tbPanel
    cfg.cellSizeForTable = function(sender,idx)
        local size = self.m_pGridCell:getContentSize()
        return size.width, size.height
    end
    cfg.tableCellAtIndex = function(sender, idx)
        return self:TableCellAtIndex(sender, idx)
    end

    cfg.numberOfCellsInTableView = function() 
        return self.m_curGridNum
    end

    cfg.scrollViewDidScroll = function(view)
        self.m_isDragging = view:isDragging()
    end

    cfg.tableCellTouched = function(sender, cell)end

    return Utils:createTableView(cfg)
end

function ShopTable:refreshTableView()
    if self.m_curDelegate ~= nil then
        local max = self.m_curDelegate:getDataListCount() or 0
        self.m_curGridNum = math.ceil(max / CountOfRaw)

        if self.m_pTableView ~= nil then
            self.m_pTableView:reloadData()
        end
    end
end

function ShopTable:refreshTableView2()
    local max = self.m_curDelegate:getDataListCount() or 0
    self.m_curGridNum = math.ceil(max / CountOfRaw)

    if self.m_pTableView ~= nil then
        local offset = self.m_pTableView:getContentOffset()
        self.m_pTableView:reloadData()
        self.m_pTableView:setContentOffset(offset)
    end
end

function ShopTable:CellTouched(index)
    if self.m_isDragging then
        return
    end
    local temp = self.m_curSelectedIdx
    self.m_curSelectedIdx = index
    local function reload(idx)
        local floor = math.floor((idx-1)/CountOfRaw)
        self.m_pTableView:updateCellAtIndex(floor)
    end

    if temp > 0 then
        reload(temp)
    end
    if self.m_curSelectedIdx > 0 then
        reload(self.m_curSelectedIdx)
    end

    if self.m_curDelegate then
        self.m_curDelegate:selectItem(index)
    end
end

function ShopTable:TableCellAtIndex(sender, idx)
    local function CellTouched(sender)
        local index = sender:getTag()
        self:CellTouched( index )
    end

    local info = self.m_curDelegate:getDataList()
    -- dump(info, "TableCellAtIndex ==>")

    local max = self.m_curDelegate:getDataListCount()
    
    local cell = sender:dequeueCell()
    local cellChild = nil
    local tbTag = sender:getTag()
    
    if cell == nil then
        local cellTag = self.m_cellCount
        self.m_cellCount = self.m_cellCount + 1

        cell = cc.TableViewCell:new()
        cell:setTag(cellTag)
        cellChild = self.m_pGridCell:clone()
        cellChild:setTag(123)
        cellChild:setAnchorPoint(cc.p(0, 0))
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cellChild:setTouchEnabled(false)

        for i=1,CountOfRaw do
            local index = idx * CountOfRaw + i
            local itemIndex = cellTag * CountOfRaw + i + tbTag

            local itemCell = cellChild:getChildByName("Item"..i)
            itemCell:setTag(index)
            itemCell:setTouchEnabled(true)
            itemCell:setSwallowTouches(false)

            local bgIcon = itemCell:getChildByName("bg_icon")
            self.m_pItemLists[tostring(itemIndex)] = ItemCellUI:New(bgIcon, {isChangeSize = true})
            self.m_pItemLists[tostring(itemIndex)]:SetIsNonAutoFree(true)
            self.m_pItemLists[tostring(itemIndex)]:SetCanClick(false)

            local icon = bgIcon:getChildByName("Icon")
            icon:setVisible(false)

            self:setItem(itemCell, info[index], index, itemIndex, index <= max)
            itemCell:addClickEventListener(CellTouched)
        end
        
        cell:addChild(cellChild)
    else
        cellChild = cell:getChildByTag(123)
        for i=1,CountOfRaw do
            local itemCell = cellChild:getChildByName("Item"..i)
            local index = idx*CountOfRaw+i
            local itemIndex = cell:getTag() * CountOfRaw + i + tbTag
            
            self:setItem(itemCell, info[index], index, itemIndex, index <= max)
        end
    end
    return cell
end

function ShopTable:setItem(item, data, index, itemIndex, bVisible)
    if item == nil then
        return
    end

    if not bVisible then
        item:setVisible(false)
        return
    end

    item:setTag(index)
    item:setVisible(true)

    self:setChoose(item, item:getTag() == (self.m_curSelectedIdx))

    self.m_curDelegate:setItem(item, data, index, itemIndex, bVisible)
end

function ShopTable:setChoose(item, isShow)
    if item == nil then
        return
    end
    local pChooseSp = item:getChildByName("Choose")
    local _ = pChooseSp and pChooseSp:setVisible(isShow)
end

function ShopTable:reset()
    self.m_curSelectedIdx = 0
    self:refreshTableView()
end

function ShopTable:reset2()
    self.m_curSelectedIdx = 0
    self:refreshTableView2()
end

function ShopTable:setVisible(bVisible)
    self.m_pTablePanel:setVisible(bVisible)
end

function ShopTable:getDataList()
    return self.m_curDelegate:getDataList()
end

function ShopTable:selectItem(data)
    if self.m_selectCallback ~= nil then
        self.m_selectCallback(data)
    end
end

function ShopTable:selectShopItem(itemId)
    local dataList = self:getDataList()
    --dump(dataList,"选择商店信息---->")
    local maxCellCount = #dataList
    local index = 0
    for i=1,maxCellCount do
        if dataList[i].id ~= nil and dataList[i].id == itemId then
            index = i
            break
        end

        if dataList[i].m_id ~= nil and dataList[i].m_id == itemId then
            index = i
            break
        end
    end
    if index <= 0 or index > maxCellCount then
        return
    end

    self:CellTouched( index )

    local curLine = math.ceil(index / CountOfRaw)
    if curLine > 0 and curLine <= self.m_curGridNum then
        local offset = self.m_pTableView:getContentOffset()

        local min = self.m_pTableView:minContainerOffset().y
        local max = self.m_pTableView:maxContainerOffset().y
        local cellHeight = self.m_pGridCell:getContentSize().height
        offset.y = math.max(math.min((curLine - self.m_curGridNum)*cellHeight, max), min)
        
        self.m_pTableView:setContentOffset(offset)
    end
end

return ShopTable