
local PetEquipPiecesSubUI = LUIBase:New()
PetEquipPiecesSubUI.__index = PetEquipPiecesSubUI
--local this = LTcpSocket
function PetEquipPiecesSubUI:New()
	local o = LUIBase:New()
	setmetatable(o,PetEquipPiecesSubUI)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function PetEquipPiecesSubUI:RegistMsgs()
    self.msgIds = 
    {
        LUIBagEvent.BagDataChanged,
        LUIPetEvent.PetBagEquipChanged,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function PetEquipPiecesSubUI:ProcessEvent(msg)
    if msg.msgId == LUIBagEvent.BagDataChanged then
        self:CheckRefresh(msg.value)
    elseif msg.msgId == LUIPetEvent.PetBagEquipChanged then
        if msg.value1 ~= 1 then
            return
        end
        local data = msg.value2
        if data == nil then
            return
        end
        LGameMsg.m_baseMsgTwo:Change(LUILogicEvent.ShowEquipGetUI, data.m_id,1)
        self:SendMsg(LGameMsg.m_baseMsgTwo)
    end
end

function PetEquipPiecesSubUI:Init()

    self.m_pUILayer = cc.CSLoader:createNode("csd/zhuangbeiyangcheng/zhuangbeisuipian.csb")
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

function PetEquipPiecesSubUI:InitData()
    local panel = self.m_pUILayer:getChildByName("suipianUI")
    -- panel:setTouchEnabled(false)
    self.m_show = panel:getChildByName("suipian")
    --碎片展示部分
    self.m_nameLable = self.m_show:getChildByName("Namebg"):getChildByName("Name")
    self.m_iconNode = self.m_show:getChildByName("Node"):getChildByName("Icon")
    local sliderNode = self.m_show:getChildByName("Slider_Bg")
    self.m_slider = sliderNode:getChildByName("LoadingBar")
    self.m_numLabel = sliderNode:getChildByName("Value")
    self.m_descLabel = self.m_show:getChildByName("miaoshu"):getChildByName("Content")
    --self.m_spNameLable = self.m_show:getChildByName("suipian_name")
    self.m_getBtn = self.m_show:getChildByName("Btn_huoqu")
    self.m_syntheticBtn = self.m_show:getChildByName("Btn_hecheng")
    self.m_getBtn:addClickEventListener(handler(self, PetEquipPiecesSubUI.GetBtnClicked))
    self.m_syntheticBtn:addClickEventListener(handler(self, PetEquipPiecesSubUI.SyntheticBtnClicked))
    self.m_recycleBtn = panel:getChildByName("recycle")
    self.m_recycleBtn:addClickEventListener(function (sender)
        Utils:InitUI("HuiShou.HuiShouMainUI", AppDef.UIType.FirstClassLayer, 2)
    end)
    self.m_cellBtn = panel:getChildByName("cell")
    self.m_cellBtn:setBright(false)
    --self.m_maskNode = panel:getChildByName("Mask")
    self.m_pointNode = panel:getChildByName("Point")
    self.m_pointLabel = self.m_pointNode:getChildByName("txt")
    --背包格
    local bag = panel:getChildByName("Bag")
    local rightView = bag:getChildByName("TableView")
    self.m_pGridCell = bag:getChildByName("ItemCell")
    self.m_pGridCell:setVisible(false)
    self.m_pGridCell:setTouchEnabled(false)
    self.m_pGridCell:setAnchorPoint(cc.p(0,0))
    rightView:setTouchEnabled(false)
    
    self.m_pItemLists = {}
    self.m_posList = {}
    self.m_sPos = 0
    self:InitRightTabView(rightView)
    self:SortItemList()
    self:RefreshIconItem()
    self:ShowDesc()
end

function PetEquipPiecesSubUI:CheckRefresh(pos)
    --print("PetEquipPiecesSubUI:CheckRefresh,",pos)
    if pos == nil then
        return
    end
    local info = LRoleDataMgr.Equip:GetPackageMap()
    if info ~= nil and pos > 0 and  info[pos] ~= nil and info[pos].m_id > 0 and info[pos].m_type ~= AppDef.ItemType.PetEquipFrag then
        --print("111111111")
        return
    end
    if info[self.m_sPos] == nil or info[self.m_sPos].m_id == nil or info[self.m_sPos].m_id == 0 then
        self.m_sPos = 0
    end
    --print("CheckRefresh",self.m_sPos)
    self:SortItemList()

    local offset = self.m_pRightTableView:getContentOffset()
    self:RefreshIconItem()                                         
    local min = self.m_pRightTableView:minContainerOffset().y
    local max = self.m_pRightTableView:maxContainerOffset().y
    offset.y = math.max(math.min(offset.y, max), min)
    self.m_pRightTableView:setContentOffset(offset)
    
    self:ShowDesc()
end 

function PetEquipPiecesSubUI:CheckHeChengSign(id,num)
    local cfg = JsonConfig.GetHeChengCfg(4,id)
    if cfg == nil then
        return 0
    end
    for i=1,#cfg.item do
        local data =cfg.item[i] 
        if data[1] == id and data[3] <= num then
            return 1
        end
    end
    return 0
end

function PetEquipPiecesSubUI:SortItemList()
    local info = LRoleDataMgr.Equip.PackageMap
    if info == nil then
        return
    end
    self.m_posList= {}
    for k,v in pairs(info) do
        --dump(v,'bagInfo==>')
        if v.m_num > 0 and v.m_id > 0 and v.m_type == AppDef.ItemType.PetEquipFrag then
            local value = {}
            value.id = v.m_id
            value.pos = k
            value.quality = v.m_quality
            value.num = v.m_num
            value.sign = self:CheckHeChengSign(v.m_id,v.m_num)
            table.insert(self.m_posList,value)
        end
    end

    local function sortFuc(m1, m2)
        if m1.sign == m2.sign then
            if m1.quality == m2.quality then
                if m1.num == m2.num then
                    return m1.id > m2.id
                else
                    return m1.num > m2.num
                end
            else
                return m1.quality > m2.quality
            end
        else
            return m1.sign > m2.sign
        end
    end
    table.sort(self.m_posList, sortFuc)
    --dump(self.m_posList)
end

function PetEquipPiecesSubUI:RefreshIconItem()
    local max = #self.m_posList
    if max > 0 then
        self.m_show:setVisible(true)
        --self.m_maskNode:setVisible(false)
        self.m_pointNode:setVisible(false)
        if self.m_sPos == 0 then
            self.m_sPos = self.m_posList[1].pos
        end
    else
        self.m_show:setVisible(false)
        --self.m_maskNode:setVisible(true)
        self.m_pointNode:setVisible(true)
        self.m_pointLabel:setString(GUITips.RSI_EQUIP_SUIPIAN_NONE)
    end
    self.m_curGridNum = math.ceil(max/5)
    self.m_pRightTableView:reloadData()
end

function PetEquipPiecesSubUI:InitRightTabView(rightView)
    local tableView = cc.TableView:create(rightView:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(cc.p(0, 0))
    tableView:setPosition(cc.p(0, 0))
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

    local p = self.m_pRightTableView:getParent()
end

--function RoleBagUI:RightTableCellTouched(cell)
--    local ind = cell:getIdx()
--    local cellChild = cell:getChildByTag(123)
--    print("tableview touched " ..ind.." ") 
--end 

function PetEquipPiecesSubUI:RightTableCellAtIndex(sender, idx)
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
                if self.m_sPos ~= nil and self.m_sPos == self.m_posList[ind].pos then
                    return
                end
                self.m_sPos = self.m_posList[ind].pos
                self:CheckRefresh(self.m_sPos)
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

function PetEquipPiecesSubUI:ShowDesc()
    self:ClearDesc()
    if self.m_sPos == nil or self.m_sPos == 0 then
        return
    end
    local info = LRoleDataMgr.Equip.PackageMap[self.m_sPos]
    if info == nil or info.m_id == nil or info.m_id == 0 then
        return
    end
    local cfg = JsonConfig.GetHeChengCfg(4,info.m_id)
    if cfg == nil  then
        return
    end
    local equipCfg = JsonConfig.m_equipConfig.getDefByID(cfg.target[2])
    if equipCfg ~= nil then
        self.m_nameLable:setString(equipCfg.name)
        self.m_nameLable:setColor(AppDef:GetQualityColor(equipCfg.quality))
        self.m_descLabel:setString(equipCfg.des)
        -- local itemValue = {isChangeSize = true,isShowQualityBg = false}
        -- local petEquipData = {
        --     id = equipCfg.id,
        -- }
        -- itemValue.petEquipData = petEquipData
        -- self.m_icon:UpdateItem(itemValue)
        local path = "item/"..equipCfg.pic..".png"
        Utils:SafeLoadTexture(self.m_iconNode, path, ccui.TextureResType.localType)
    end
    --print("item quality",info.m_quality)
    --self.m_spNameLable:setString(info.m_name)
    --self.m_spNameLable:setColor(AppDef:GetQualityColor(info.m_quality))
    local item_num = 1
    for i=1,#cfg.item do
        local data = cfg.item[i]
        if data[1] == info.m_id then
            item_num = data[3] 
        end
    end
    self.m_numLabel:setString(""..info.m_num.."/"..item_num)
    local percent = math.floor(info.m_num*100/item_num)
    if percent > 100 then
        percent = 100 
    end
    self.m_slider:setPercent(percent)
    --self.m_getBtn:setBright(true)
    if percent == 100 then
        --self.m_syntheticBtn:setBright(true)
        self.m_syntheticBtn:setEnabled(true)
    end
    self.m_getBtn:setEnabled(true)
end

function PetEquipPiecesSubUI:ClearDesc( ... )
    self.m_nameLable:setString("")
    self.m_numLabel:setString("")
    self.m_descLabel:setString("")
    --self.m_spNameLable:setString("")
    self.m_slider:setPercent(0)
    -- if self.m_icon == nil then
    --     self.m_icon = ItemCellUI:New(self.m_iconNode,{isChangeSize = true,isShowQualityBg = true})
    --     --self.m_icon.m_pUILayer:setAnchorPoint(cc.p(0.5, 0.5))
    --     self.m_icon:SetCanClick(true)
    -- end
    --self.m_icon:UpdateItem(nil)
    --self.m_getBtn:setBright(false)
    self.m_getBtn:setEnabled(false)
    --self.m_syntheticBtn:setBright(false)
    self.m_syntheticBtn:setEnabled(false)
end

function PetEquipPiecesSubUI:GetBtnClicked(sender)
    if self.m_sPos == nil or self.m_sPos == 0 then
        return
    end
    local info = LRoleDataMgr.Equip.PackageMap[self.m_sPos]
    if info == nil or info.m_id == nil or info.m_id == 0 then
        return
    end
    Utils:ShowItemTips(info.m_id)
    --print("PetEquipPiecesSubUI:GetBtnClicked")
end

function PetEquipPiecesSubUI:SyntheticBtnClicked(sender)
    if self.m_sPos == nil or self.m_sPos == 0 then
        return
    end
    local info = LRoleDataMgr.Equip.PackageMap[self.m_sPos]
    if info == nil or info.m_id == nil or info.m_id == 0 then
        return
    end
    --print("PetEquipPiecesSubUI:SyntheticBtnClicked",info.m_id)
    LuaNetSendMsg:SendPetEquipHeChengReq(info.m_id)
end

function PetEquipPiecesSubUI:ShowRightCellInfo(cellChild, idx)
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

function PetEquipPiecesSubUI:UpdateBagCell(pos,item,grid)
    if item == nil then
        return
    end
    --print("PetEquipPiecesSubUI:UpdateBagCell",pos)
    local nameLabel = grid:getChildByName("Name")
    local tipsNode = grid:getChildByName("Tips")
    local redImg = grid:getChildByName("Prompt")
    local chooseImg = grid:getChildByName("Choose")
    local otherNode = grid:getChildByName("keshengxing")
    nameLabel:setString("")
    tipsNode:setVisible(false)
    grid:setVisible(false)
    redImg:setVisible(false)
    chooseImg:setVisible(false)
    otherNode:setVisible(false)
    local posList = self.m_posList[pos]
    if posList == nil then
        return
    end
    local ind = posList.pos
    local info = LRoleDataMgr.Equip.PackageMap[ind]
    --dump(info,"PetEquipPiecesSubUI:UpdateBagCell bagInfo===>")
    if info == nil or info.m_id == nil or info.m_id == 0 then
        item:UpdateItem(nil)
        return
    end
    grid:setVisible(true)
    local sign = (info.m_pos == self.m_sPos)
    if sign then
        chooseImg:setVisible(true)
    end
    --print("PetEquipPiecesSubUI:UpdateBagCell",info.m_pos,self.m_sPos,sign)
    local itemValue = {
        isShowQualityBg = true,
        isShowNum = true,
        isChangeSize = true,
        isSelect = sign,
    }
    local userDefine =
    {
        picFilePath = string.format("item/equip%s.png", info.m_item.pic),
        quality = info.m_quality,
        itemId = info.m_id,
        num = info.m_num,
        isSuiPian = true,
    }
    itemValue.userDefine = userDefine
    item:UpdateItem(itemValue)
    --Utils:GetItemCellValue(grid, 0, info.m_id, true, true,info.m_num,item,false,true,0,0,true)
    nameLabel:setString(info.m_name)
    nameLabel:setColor(AppDef:GetQualityColor(info.m_quality))
    local cfg = JsonConfig.GetHeChengCfg(4,info.m_id)
    if cfg == nil then
        return
    end
    for i=1,#cfg.item do
        local data = cfg.item[i]
        if data[1] == info.m_id and data[3] <= info.m_num then
            tipsNode:setVisible(true)
            redImg:setVisible(true)
        end
    end
end

function PetEquipPiecesSubUI:onExit()
    for key,value in pairs(self.m_pItemLists) do 
        value:onExit(true)
    end
    self.m_pUILayer = nil
    self.m_pItemLists = nil
    self.m_posList = nil
    self:Destory()
end

return PetEquipPiecesSubUI