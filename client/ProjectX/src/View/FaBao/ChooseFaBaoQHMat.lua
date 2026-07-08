
local ChooseFaBaoQHMat = LUIBase:New()
ChooseFaBaoQHMat.__index = ChooseFaBaoQHMat
--local this = LTcpSocket
--强化法宝 选择界面

function ChooseFaBaoQHMat:New(uidList)
	local o = LUIBase:New()
	setmetatable(o,ChooseFaBaoQHMat)	
    o:Init(uidList)
	return o
end

--注册事件
-- -----------------------------------
function ChooseFaBaoQHMat:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function ChooseFaBaoQHMat:ProcessEvent(msg)

end

function ChooseFaBaoQHMat:Init(uidList)

    self.m_pUILayer = cc.CSLoader:createNode("csd/huishou/Choose_fenjie.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end

    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:initData(uidList)
    self:initControlUI()
    self:InitTableView()
    self.m_pRightTableView:reloadData()
    local size = #self._selectList
    self._selectNum:setString(size)
end

function ChooseFaBaoQHMat:isContainFabao( uid )
    -- body
    for k,v in pairs(self._uidList) do
        if v == uid then
            return true
        end
    end
    return false
end

function ChooseFaBaoQHMat:initData( uidList )
    -- body
    self._uidList = uidList
    self._resutList = {}
    self.m_pItemLists = {}
    for k,v in pairs(LRoleDataMgr.Pet.faBaoList.m_petFaBaos) do
        --神将碎片
        -- dump(v, "PetBagFragmentSubUI:initData ===========>")
        if not self:isContainFabao(v.m_uid) and v.m_id > 0 then
            if (v.baseData.quality  <= 3 or (v.m_id >= AppDef.fabaoExpItemID.normal_fbExp and v.m_id <= AppDef.fabaoExpItemID.high_fbExp)) and v.m_fpos < 1 then
                if v.qhLv <= 0 and v.jlLv <= 0 then
                    table.insert(self._resutList, v)
                end
            end
        end
    end
    max = #self._resutList
    self.m_curGridNum = math.ceil(max/2)
    -- print("ChooseFaBaoQHMat:initData ==>", self.m_curGridNum, max)

    --最终选择的列表
    self._selectList = {}
end

function ChooseFaBaoQHMat:initControlUI( ... )
    -- body
    Utils:SendMsg(LUIPopFClassBgEvent.SetTitle, GUITips.UI_Title_PetFaBao_Tips2)

    Utils:SendMsg(LUIPopFClassBgEvent.SetCloseCallback, handler(self, ChooseFaBaoQHMat.CloseUI))

    local ChooseUI = self.m_pUILayer:getChildByName("ChooseUI")
    local Popup = ChooseUI:getChildByName("Popup")
    -- local Btn_close = Popup:getChildByName("Btn_close")
    -- Btn_close:addClickEventListener(function ( sender )
    --     -- body
    --     self:CloseUI()
    -- end)
    ---------------------------------------------------------
    -- local Title = Popup:getChildByName("Title")
    -- self._titleValue = Title:getChildByName("Title")

    -- self._titleValue:setString(GUITips.UI_Title_PetFaBao_Tips2)

    self._tableView = Popup:getChildByName("TableView")

    self._pCell = Popup:getChildByName("ItemList")
    self._pCell:removeFromParent()
    self._pCell:retain()
    self._pCell:setAnchorPoint(cc.p(0, 0))
    -------------------------------------------------------
    self._selectNum = Popup:getChildByName("Number"):getChildByName("Value")
    self._selectNum:setString(0)
    local Btn_Choose = Popup:getChildByName("Btn_Choose")
    Btn_Choose:addClickEventListener(handler(self, ChooseFaBaoQHMat.selectEvent))

end

function ChooseFaBaoQHMat:selectEvent( sender )
    -- body
    self:CloseUI()
    Utils:SendMsg(LUIFaBaoEvent.PetQHMaterialSelect, self._selectList)
end

function ChooseFaBaoQHMat:InitTableView()
    local tableView = cc.TableView:create(self._tableView:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(cc.p(0, 0))
    tableView:setPosition(cc.p(0, 0))
    tableView:setDelegate()
    tableView:setSwallowsTouches(false)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self._tableView:addChild(tableView)
    
    local function tableCellTouched(sender,cell)
        --print("tableCellTouched",sender,cell,cell:getIdx())
        self:RightTableCellTouched(cell)
    end
    local function cellSizeForTable(sender,idx)
        local width = self._pCell:getContentSize().width
        local height = self._pCell:getContentSize().height
        --print("width=",width, "height",height)
        return width, height
    end
    local function tableCellAtIndex(sender, idx)
        return self:RightTableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView() 
        return self.m_curGridNum
    end

    local function scrollViewDisScroll(view)
        self.m_isDragging = view:isDragging()
    end

    --tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量
    tableView:registerScriptHandler(scrollViewDisScroll,cc.SCROLLVIEW_SCRIPT_SCROLL)
    --tableView:reloadData()
    self.m_pRightTableView = tableView
end

--function RoleBagUI:RightTableCellTouched(cell)
--    local ind = cell:getIdx()
--    local cellChild = cell:getChildByTag(123)
--    print("tableview touched " ..ind.." ") 
--end 

function ChooseFaBaoQHMat:RightTableCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self._pCell:clone()
        cellChild:setTag(123)
        cellChild:setAnchorPoint(cc.p(0, 0))
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cell:addChild(cellChild)
        cellChild:setTouchEnabled(false)
        for i=1,2 do
            local bagGrid = cellChild:getChildByName("Item"..i)
            bagGrid:setSwallowTouches(false)
            local index = idx*2+i
 
            --为了不重复创建 item
            local item = ItemCellUI:New(bagGrid:getChildByName("Icon"), {isChangeSize = true})
            item:SetIsNonAutoFree(true)
            table.insert(self.m_pItemLists, item)
            
            -- dump(itemData, "RightTableCellAtIndex ================== 1111111111111 =====>>")
            local btn = bagGrid:getChildByName("CheckBox")
            btn:addClickEventListener(handler(self, ChooseFaBaoQHMat.CheckBoxCallback))
            self:MarkIntaractCObj(btn)
        end
    else
        cellChild = cell:getChildByTag(123)
        for i=1,2 do
            local bagGrid = cellChild:getChildByName("Item"..i)
            local index = idx*2+i
            bagGrid:setTag(index)
        end
    end
    self:ShowRightCellInfo(cellChild, idx)
    return cell
end

function ChooseFaBaoQHMat:CheckBoxCallback(sender)
    local uid = sender.userObject
    print("CheckBoxCallback ====>", sender:isSelected())
    print("CheckBoxCallback uid ==>", uid)
    if not sender:isSelected() then
        table.insert(self._selectList, LRoleDataMgr.Pet.faBaoList.m_petFaBaos[uid])
    else
        for i=1, #self._selectList do
            if self._selectList[i].m_uid == uid then
                table.remove(self._selectList, i)
            end
        end 
    end

    local size = #self._selectList
    self._selectNum:setString(size)
    
end

function ChooseFaBaoQHMat:ShowRightCellInfo(cellChild, idx)
    --print("cell idx"..idx)
    local min = idx * 2;
    for i = 1,  2 do
        local index = i+min
        local bagGrid = cellChild:getChildByName("Item"..i)
        local item = self.m_pItemLists[index]
        self:UpdateBagCell(index,item,bagGrid)
        --self.m_indexTable[num] = index      
    end
end

function ChooseFaBaoQHMat:UpdateBagCell(pos, pItem, grid)

    print("UpdateBagCell ==>", pos)
    if pItem == nil or grid == nil then
        return
    end

    grid:setVisible(false)

    if pos > #self._resutList then
        return
    end

    grid:setVisible(true)

    local data = self._resutList[pos]

    local btn = grid:getChildByName("CheckBox")
    btn.userObject = data.m_uid

    local itemIcon = grid:getChildByName("Icon")
    Utils:GetFaBaoCellValue(itemIcon,pItem,data.m_id, data.m_uid, false, 1, data.qhLv, data.jlLv,true,true)
    local name = grid:getChildByName("Name")
    name:setString(data.baseData.name)

    local tips = grid:getChildByName("Text_1")
    tips:setVisible(false)

    local tips2 = grid:getChildByName("Text_2")
    tips2:setVisible(false)

    local tips3 = grid:getChildByName("Text_3")
    tips3:setVisible(false)

    local Recommend = grid:getChildByName("Recommend")
    Recommend:setVisible(false)

end

function ChooseFaBaoQHMat:CloseUI( ... )
    -- body
    Utils:DeleteUI("FaBao.ChooseFaBaoQHMat")
end

function ChooseFaBaoQHMat:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return ChooseFaBaoQHMat