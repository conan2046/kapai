
local KaPaiBagSubUI = LUIBase:New()
KaPaiBagSubUI.__index = KaPaiBagSubUI
--local this = LTcpSocket
function KaPaiBagSubUI:New()
	local o = LUIBase:New()
	setmetatable(o,KaPaiBagSubUI)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function KaPaiBagSubUI:RegistMsgs()
    self.msgIds = 
    {
        LUIBagEvent.BagDataChanged,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function KaPaiBagSubUI:ProcessEvent(msg)
    if msg.msgId == LUIBagEvent.BagDataChanged then
        self:CheckRefresh(msg.value)
    end
end

function KaPaiBagSubUI:Init()

    self.m_pUILayer = cc.CSLoader:createNode("csd/zhujue/beibao.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:InitData()
end

function KaPaiBagSubUI:InitData()
    local panel = self.m_pUILayer:getChildByName("beibao_layer")
    panel:setTouchEnabled(false)
    self.m_show = panel:getChildByName("item")
    --展示部分
    self.m_nameLable = self.m_show:getChildByName("Namebg"):getChildByName("Name")
    self.m_iconNode = self.m_show:getChildByName("Node"):getChildByName("Icon")
    self.m_descLabel = self.m_show:getChildByName("miaoshu"):getChildByName("Content")
    --self.m_spNameLable = self.m_show:getChildByName("suipian_name")
    self.m_useBtn = self.m_show:getChildByName("Btn_use")
    self.m_useBtn:addClickEventListener(handler(self, KaPaiBagSubUI.UseBtnClicked))
    self.m_useBtnLabel = self.m_useBtn:getChildByName("Text")

    --self.m_maskNode = panel:getChildByName("Mask")
    --self.m_pointNode = panel:getChildByName("Point")
    --背包格
    local bag = panel:getChildByName("Bag")
    local rightView = bag:getChildByName("TableView")
    self.m_pGridCell = bag:getChildByName("ItemCell")
    self.m_pGridCell:setVisible(false)
    self.m_pGridCell:setTouchEnabled(false)
    rightView:setTouchEnabled(false)
    
    self.m_pItemLists = {}
    self.m_posList = {}
    self.m_sPos = 0
    self:InitRightTabView(rightView)
    self:SortItemList()
    self:RefreshIconItem()
    self:ShowDesc()
end

function KaPaiBagSubUI:CheckRefresh(pos)
    --print("KaPaiBagSubUI:CheckRefresh,",pos)
    pos = pos or 0
    local sign = false
    if pos > 0 then
        local info = LRoleDataMgr.Equip.PackageMap
        if info ~= nil and pos > 0 and  info[pos] ~= nil and info[pos].m_id > 0 and not self:IsShow(info[pos].m_type) then
            --print(pos,info[pos].m_id,info[pos].m_name)
            return
        end
        if self.m_sPos > 0 then
            local value = self.m_posList[self.m_sPos]
            if value == nil or info[value.pos] == nil or (info[pos] ~= nil and  value.id == info[pos].m_id) or info[value.pos].m_id ~= value.id then
                sign = true
                if value == nil or info[value.pos] == nil or info[value.pos].m_id ~= value.id then
                    self.m_sPos = 1
                end
            end
        end
        self:SortItemList()
        if #self.m_posList == 0 then
            self.m_sPos = 0
        end
    end
    if pos == 0 or sign then
        self:ShowDesc()
    end

    local offset = self.m_pRightTableView:getContentOffset()
    self:RefreshIconItem()                                         
    local min = self.m_pRightTableView:minContainerOffset().y
    local max = self.m_pRightTableView:maxContainerOffset().y
    offset.y = math.max(math.min(offset.y, max), min)
    self.m_pRightTableView:setContentOffset(offset)
end 

function KaPaiBagSubUI:IsShow(iType)
    if iType == AppDef.ItemType.PetEquipFrag or iType == AppDef.ItemType.PetFrag 
        or iType == AppDef.ItemType.ZiYuanDaoJu or iType == AppDef.ItemType.FaBaoSuiPian then 
        return false
    end
    return true
end

function KaPaiBagSubUI:SortItemList()
    local info = LRoleDataMgr.Equip.PackageMap
    if info == nil then
        return
    end
    self.m_posList= {}
    for k,v in pairs(info) do
        --dump(v,'bagInfo==>')
        if v.m_num > 0 and v.m_id > 0 and self:IsShow(v.m_type) then
            local sign = true
            for i = 1,#self.m_posList do
                if self.m_posList[i].id == v.m_id then
                    self.m_posList[i].num = self.m_posList[i].num + v.m_num
                    sign = false
                    break
                end
            end
            if sign then
                local value = {}
                value.id = v.m_id
                value.pos = k
                value.sign = v.m_item.sort_priority
                value.num = v.m_num
                value.name = v.m_name
                value.pic = v.m_item.pic
                value.quality = v.m_item.quality
                table.insert(self.m_posList,value)
            end
        end
    end

    local function sortFuc(m1, m2)
        return m1.sign < m2.sign
    end
    table.sort(self.m_posList, sortFuc)
    --dump(self.m_posList,"&&&&&&&&&&&&&&&&&&&&&&===>")
end

function KaPaiBagSubUI:RefreshIconItem()
    local max = #self.m_posList
    if max > 0 then
        self.m_show:setVisible(true)
        if self.m_sPos == 0 then
            self.m_sPos = 1
        end
    else
        self.m_show:setVisible(false)
    end
    self.m_curGridNum = math.ceil(max/5)
    self.m_pRightTableView:reloadData()
end

function KaPaiBagSubUI:InitRightTabView(rightView)
    local tableView = cc.TableView:create(rightView:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(rightView:getAnchorPoint())
    tableView:setPosition(rightView:getPosition())
    tableView:setDelegate()
    tableView:setSwallowsTouches(false)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    rightView:addChild(tableView)
    
    local function tableCellTouched(sender,cell)
        --print("tableCellTouched",sender,cell,cell:getIdx())
        self:RightTableCellTouched(cell)
    end
    local function cellSizeForTable(sender,idx)
        local width = self.m_pGridCell:getContentSize().width
        local height = self.m_pGridCell:getContentSize().height
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

function KaPaiBagSubUI:RightTableCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pGridCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cell:addChild(cellChild)
        cellChild:setTouchEnabled(false)
        for i=1,5 do
            local bagGrid = cellChild:getChildByName("Item"..i)
            bagGrid:setSwallowTouches(false)
            local index = idx*5+i
            bagGrid:setTag(index)
            local icon = bagGrid:getChildByName("Icon")
            local item = ItemCellUI:New(icon,{isChangeSize = true})
            item:SetIsNonAutoFree(true)
            table.insert(self.m_pItemLists, item)
            bagGrid.userObject = #self.m_pItemLists
            bagGrid:addClickEventListener(function(sender)
                if self.m_isDragging then
                    return
                end
                local ind = sender:getTag()
                if ind == nil or ind == 0 or ind > #self.m_posList then
                    return
                end
                if self.m_sPos ~= nil and self.m_sPos == ind then
                    return
                end
                self.m_sPos = ind
                self:CheckRefresh()
                self.m_isDragging = false
            end)
            --self:MarkIntaractCObj(bagGrid)
        end
    else
        cellChild = cell:getChildByTag(123)
        for i=1,5 do
            local bagGrid = cellChild:getChildByName("Item"..i)
            local index = idx*5+i
            bagGrid:setTag(index)
        end
    end
    self:ShowRightCellInfo(cellChild, idx)
    return cell
end

function KaPaiBagSubUI:ShowDesc()
    self:ClearDesc()
    if self.m_sPos == nil or self.m_sPos == 0 then
        return
    end
    local value = self.m_posList[self.m_sPos]
    if value == nil or value.id == nil or value.id == 0 then
        return
    end
    local cfg = JsonConfig.m_Item.getDefByID(value.id)
    if cfg == nil then
        return
    end
    self.m_nameLable:setString(value.name)
    self.m_nameLable:setColor(AppDef:GetQualityColor(value.quality))

    local desc = cfg.des
    local uType = cfg.use_type or 0
    local jumpId = cfg.use_jump or 0
    self.m_descLabel:setString(desc)
    self.m_icon = Utils:GetItemCellValue(self.m_iconNode, 0, value.id, true, true, value.num, self.m_icon, false, true, false)
    if cfg.type == AppDef.ItemType.NXuanYiBox then
        self.m_useBtn:setVisible(true)
        self.m_useBtnLabel:setString(GUITips.UI_Btn_Item_Open)
    elseif uType > 0 or jumpId > 0 then --
        self.m_useBtn:setVisible(true)
        if uType == 0 and jumpId > 0 then
            self.m_useBtnLabel:setString(GUITips.UI_Btn_Item_Jump)
        end
    end
end

function KaPaiBagSubUI:ClearDesc( ... )
    self.m_nameLable:setString("")
    self.m_descLabel:setString("")
    if self.m_icon == nil then
        self.m_icon = ItemCellUI:New(self.m_iconNode,{isChangeSize = true})
        self.m_icon:SetCanClick(true)
    end
    self.m_icon:UpdateItem(nil)
    self.m_useBtn:setVisible(false)
    self.m_useBtnLabel:setString(GUITips.UI_Btn_Item_Use)
end

function KaPaiBagSubUI:UseBtnClicked(sender)
    local function NumInputCallback(num)
        if num == 0 or self.m_sPos == nil then
           return
        end
        local value = self.m_posList[self.m_sPos]
        if value == nil or value.pos == 0 then
            return
        end
        LuaNetSendMsg:SendItemUseReq(value.pos-1,num,0)
    end

    if self.m_sPos == nil or self.m_sPos == 0 then
        return
    end
    local value = self.m_posList[self.m_sPos]
    if value == nil or value.id == nil or value.id == 0 then
        return
    end
    local cfg = JsonConfig.m_Item.getDefByID(value.id)
    if cfg == nil then
        return
    end
    local uType = cfg.use_type or 0
    local jumpId = cfg.use_jump or 0 
    if uType == 0 and jumpId == 0 then
        return
    end
    if cfg.type == AppDef.ItemType.NXuanYiBox then
        --print("info.m_id",info.m_id)
        Utils:InitUI("Common.GiftChooseUI", AppDef.UIType.PopFirstClassLayer, value.id)
        --Utils:InitUI("Common.GiftShowUI", AppDef.UIType.PopWindow, info.m_id)
    elseif uType > 0 then
        if value.num > 1 and uType == 2 then
            local max = math.min(value.num,200)--限制一次使用数量
            Utils:ShowNumInputUI(max,NumInputCallback)
        else
            LuaNetSendMsg:SendItemUseReq(value.pos-1,1,0)
        end
    elseif jumpId > 0 then
        Utils:OpenFunction(jumpId)
        if jumpId == AppDef.EModuleID.EMID_KAPAI_SJJINENG or jumpId==AppDef.EModuleID.EMID_KAPAI_SJXIULIAN then
            --调整神将养成界面
            Utils:SendMsg(LUIKaPaiPetEvent.ShowPetLeftInfo, LRoleDataMgr.Pet:GetPetByFightPos(fightPos))
        end
        Utils:DeleteUI("Role.KaPaiBagMainUI")
    end
end

function KaPaiBagSubUI:ShowRightCellInfo(cellChild, idx)
    --print("cell idx"..idx)
    local min = idx * 5;
    for i = 1,  5 do
        local index = i+min
        local bagGrid = cellChild:getChildByName("Item"..i)
        local num = bagGrid.userObject
        local item = self.m_pItemLists[num]
        self:UpdateBagCell(index,item,bagGrid)
        --self.m_indexTable[num] = index      
    end
end

function KaPaiBagSubUI:UpdateBagCell(pos,item,grid)
    if item == nil then
        return
    end
    --print("KaPaiBagSubUI:UpdateBagCell",pos)
    local nameLabel = grid:getChildByName("Name")
    local tipsNode = grid:getChildByName("Tips")
    local redImg = grid:getChildByName("Prompt")
    local chooseImg = grid:getChildByName("Choose")
    nameLabel:setString("")
    tipsNode:setVisible(false)
    grid:setVisible(false)
    redImg:setVisible(false)
    chooseImg:setVisible(false)
    local posList = self.m_posList[pos]
    if posList == nil then
        return
    end
    --local ind = posList.pos
    --local info = LRoleDataMgr.Equip.PackageMap[ind]
    --dump(info,"KaPaiBagSubUI:UpdateBagCell bagInfo===>")
    if posList.id == nil or posList.id == 0 then
        item:UpdateItem(nil)
        return
    end
    grid:setVisible(true)
    local sign = (pos == self.m_sPos)
    if sign then
        chooseImg:setVisible(true)
    end
    --print("KaPaiBagSubUI:UpdateBagCell",info.m_pos,self.m_sPos,sign)
    local itemValue = {
        isShowQualityBg = true,
        isShowNum = true,
        isChangeSize = true,
        isSelect = sign,
    }
    local userDefine =
    {
        picFilePath = string.format("item/equip%s.png", posList.pic),
        quality = posList.quality,
        itemId = posList.id,
        num = posList.num,
    }
    itemValue.userDefine = userDefine
    item:UpdateItem(itemValue)
    --Utils:GetItemCellValue(grid, 0, info.m_id, true, true,info.m_num,item,false,true,0,0,true)
    nameLabel:setString(posList.name)
    nameLabel:setColor(AppDef:GetQualityColor(posList.quality))
end

function KaPaiBagSubUI:onExit()
    for key,value in pairs(self.m_pItemLists) do 
        value:onExit(true)
    end
    self.m_pUILayer = nil
    self.m_pItemLists = nil
    self.m_posList = nil
    self:Destory()
end

return KaPaiBagSubUI