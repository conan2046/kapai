
local PetBagFragmentSubUI = LUIBase:New()
PetBagFragmentSubUI.__index = PetBagFragmentSubUI
--local this = LTcpSocket
function PetBagFragmentSubUI:New()
	local o = LUIBase:New()
	setmetatable(o,PetBagFragmentSubUI)	
    o:Init()
	return o
end

local EVERYLINENUM = 5

--注册事件
-- -----------------------------------
function PetBagFragmentSubUI:RegistMsgs()
    self.msgIds = 
    {
        LUIPetEvent.ComposionPet,
        LUIPetEvent.PetDataChanged,
        LUIFuBenMapEvent.updateSaoDangEvent,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function PetBagFragmentSubUI:ProcessEvent(msg)
    if msg.msgId == LUIPetEvent.ComposionPet then
        self:initFragmentItems()
        self.m_pFragMentTableView:reloadData()
        self:updateDetailInfoUI()
    elseif msg.msgId == LUIPetEvent.PetDataChanged then
        self:initFragmentItems()
        self.m_pFragMentTableView:reloadData()
        self:updateDetailInfoUI()
    elseif msg.msgId == LUIFuBenMapEvent.updateSaoDangEvent then
        performWithDelay(self.m_pUILayer, function(sender)
            -- print("PetBagFragmentSubUI:ProcessEvent ==> update")
            self:initFragmentItems()
            local offset = self.m_pFragMentTableView:getContentOffset() 
            self.m_pFragMentTableView:reloadData()
            self.m_pFragMentTableView:setContentOffset(offset)
            self:updateDetailInfoUI()
        end, 1)
    end
end

function PetBagFragmentSubUI:Init()

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
    self:initData()
    self:initControlUI()
    --默认数据
    self:updateDetailInfoUI()

end

function PetBagFragmentSubUI:initData( ... )
    -- body
    -- dump(LRoleDataMgr.Equip:GetPackageList(), "PetBagFragmentSubUI ========>")
    self:initFragmentItems();
    self._curIndex = 1
end

function PetBagFragmentSubUI:initFragmentItems()
    self._ownFragmentList = {}
    local Num = 0
    for k,v in pairs(LRoleDataMgr.Equip:GetPackageMap()) do
        --神将碎片
        -- dump(v, "PetBagFragmentSubUI:initData ===========>")
        if v.m_type == AppDef.ItemType.PetFrag then
            table.insert(self._ownFragmentList, v)
            Num = Num + 1
        end
    end
    -- print("PetBagFragmentSubUI:initData ===>", Num)

    self:SortPetList()
end

function PetBagFragmentSubUI:SortPetList( ... )
    -- body
    local function sortFuc(a, b)
        return PetkaPaiManager:getPetFragMentCanUpgrade(a) > PetkaPaiManager:getPetFragMentCanUpgrade(b)
    end
    table.sort(self._ownFragmentList, sortFuc)
end

-- yingxiongbeibaoUI
function PetBagFragmentSubUI:initControlUI( ... )
   local suipianUI = self.m_pUILayer:getChildByName("suipianUI")
   -- suipianUI:setTouchEnabled(false)


   local suipian = suipianUI:getChildByName("suipian")
   self._suipian = suipian
   self._bg = suipian:getChildByName("Bg")
   self._Node = suipian:getChildByName("Node")
   self._itemName = suipian:getChildByName("Namebg"):getChildByName("Name")
   self._Node = suipian:getChildByName("Node")
   local Slider_Bg = suipian:getChildByName("Slider_Bg")
   self._loadingBar = Slider_Bg:getChildByName("LoadingBar")
   self._value = Slider_Bg:getChildByName("Value")

   -- self._signText = suipian:getChildByName("Text")

   -- local suipian_name = suipian:getChildByName("suipian_name")
   -- suipian_name:setVisible(false)

   self._contentDes = suipian:getChildByName("miaoshu"):getChildByName("Content")


   local Btn_huoqu = suipian:getChildByName("Btn_huoqu")
   Btn_huoqu:addClickEventListener(function ( sender )
        local itemData = self._ownFragmentList[self._curIndex]
        if itemData == nil then
            return
        end
        Utils:ShowItemTips(itemData.m_id)
   end)

   local Btn_hecheng = suipian:getChildByName("Btn_hecheng")
   self._heChengBtn = Btn_hecheng
   Btn_hecheng:addClickEventListener(function ( sender )
       -- body
        local tag = sender:getTag()
        if tag == 1 then
            --升星
            local itemData = self._ownFragmentList[self._curIndex]
            -- local hechengConfig = JsonConfig.m_HeCheng.getDefByID(itemData.m_id)
            local hechengConfig = JsonConfig.GetHeChengCfg(AppDef.ItemType.PetFrag, itemData.m_id)
            local petId = hechengConfig.target[2]

            LRoleDataMgr.tempPetUpStarData = Utils:deepCopy(LRoleDataMgr.Pet:GetPetById(petId))
            
            print("hechengConfig.target[2] =", petId)
            LuaNetSendMsg:QueryPetStarUp(petId)
        elseif tag == 2 then
            --升级
            local itemData = self._ownFragmentList[self._curIndex]
            -- local hechengConfig = JsonConfig.m_HeCheng.getDefByID(itemData.m_id)
            -- print("hechengConfig.target[2] =", hechengConfig.target[3])
            print("itemData.m_id ======", itemData.m_id)
            LuaNetSendMsg:QueryGetPet(11, itemData.m_id)
        end
   end)

   -----------------------------------------------------
   local Bag = suipianUI:getChildByName("Bag")
   self._bag = Bag
   self._TableViewPanel = Bag:getChildByName("TableView")
   self._pCell = Bag:getChildByName("ItemCell")
   self._pCell:removeFromParent()
   self._pCell:retain()
   self._pCell:setAnchorPoint(cc.p(0, 0))

   self:InitRightTabView()

   self.m_pFragMentTableView:reloadData()
   -------------------------------------------------
   self._Point = suipianUI:getChildByName("Point")
   self._Point:getChildByName("txt"):setString(GUITips.UI_Pet_SuiPianBag_Tips)

end

function PetBagFragmentSubUI:InitRightTabView()
    
    local tableView = cc.TableView:create(self._TableViewPanel:getContentSize())
    tableView:setContentSize(self._TableViewPanel:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(cc.p(0, 0))
    tableView:setPosition(cc.p(0, 0))
    tableView:setDelegate()
    tableView:setSwallowsTouches(true)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self._TableViewPanel:addChild(tableView)

    local function tableCellTouched(sender,cell)
        self:TableCellTouched(sender, cell)
    end

    local function cellSizeForTable(sender,idx)
        local width = self._pCell:getContentSize().width
        local height = self._pCell:getContentSize().height
        return width, height
    end

    local function tableCellAtIndex(sender, idx)
        return self:PetFragTableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        local size = 0
        local listLength = #self._ownFragmentList
        if self._ownFragmentList then
            if listLength % EVERYLINENUM == 0 then
                size = listLength / EVERYLINENUM
            else
                size = math.floor(listLength / EVERYLINENUM) + 1 
            end
        end
        return size
    end

    local function scrollViewDisScroll(view)
        self.m_isDragging = view:isDragging()
    end

    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量
    tableView:registerScriptHandler(scrollViewDisScroll, cc.SCROLLVIEW_SCRIPT_SCROLL)
    --tableView:reloadData()
    self.m_pFragMentTableView = tableView
end

function PetBagFragmentSubUI:TableCellTouched(sender, cell)
    
    local ind = cell:getIdx()
    local cellChild = cell:getChildByTag(123)
end 


function PetBagFragmentSubUI:PetFragTableCellAtIndex(sender, idx)

    local function petGridTouched(sender)--选中
        if self.m_isDragging then
            return
        end
        local ind = sender:getTag()
        print("PetFragTableCellAtIndex =============>", idx, ind)
        if self._curIndex > 0 then
            local lastidx = math.floor((self._curIndex - 1) / EVERYLINENUM)
            local lastSelcetFace = self.m_pFragMentTableView:cellAtIndex(lastidx)
            if lastSelcetFace ~= nil then
                local cellChild = lastSelcetFace:getChildByTag(123)
                if cellChild ~= nil then
                    local i = (self._curIndex - 1) % EVERYLINENUM + 1
                    print("PetFragTableCellAtIndex i =", i, self._curIndex)
                    local lastItem = cellChild:getChildByTag(self._curIndex)
                    if lastItem ~= nil then
                        lastItem:getChildByName("Choose"):setVisible(false)
                    end
                end
            end
        end
        sender:getChildByName("Choose"):setVisible(true)
        self._curIndex = ind
        --更新UI
        self:updateDetailInfoUI()
    end


    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self._pCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)
        cellChild:setTouchEnabled(false)
        
        for i=1, EVERYLINENUM do
            local giftGrid = cellChild:getChildByName("Item"..i)
            --实现选中状态
            giftGrid:setBright(true)
            giftGrid:setSwallowTouches(false)
            local index = idx * EVERYLINENUM + i 
            giftGrid:setTag(index)
            giftGrid:addClickEventListener(petGridTouched) 
            self:MarkIntaractCObj(giftGrid)
            giftGrid:setTouchEnabled(true)
            self:showKaPaiInfo(cellChild, giftGrid, index)
        end      
    else
        cellChild = cell:getChildByTag(123)
        for i=1, EVERYLINENUM do
            local index = idx*EVERYLINENUM+i
            local giftGrid = cellChild:getChildByName("Item"..i)
            giftGrid:setTag(index)
            self:showKaPaiInfo(cellChild, giftGrid, index)
        end

    end
    
    return cell
end

function PetBagFragmentSubUI:showKaPaiInfo(cellChild, giftGrid, index)
    -- body
    if cellChild == nil then
        return
    end
    if index > #self._ownFragmentList then
        giftGrid:setVisible(false)
        return
    end
    giftGrid:setVisible(true)
    local itemData = self._ownFragmentList[index]
    self:showItemInfo(giftGrid, itemData, index)

end

function PetBagFragmentSubUI:showItemInfo(giftGrid, itemData, index)
    -- body
    -- dump(itemData, "showItemInfo ==")
    local name = giftGrid:getChildByName("Name")
    name:setString(itemData.m_name)

    local Tips = giftGrid:getChildByName("Tips")
    local isPetCanHeCheng = PetkaPaiManager:isPetCanHeCheng(itemData)
    -- isPetCanHeCheng = false
    Tips:setVisible(isPetCanHeCheng)

    local Icon = giftGrid:getChildByName("Icon")
    Utils:GetItemCellValue(Icon, 0, itemData.m_id, true, true, itemData.m_num, nil , false)

    local Choose = giftGrid:getChildByName("Choose")
    Choose:setVisible(false)


    local isCanStarUp = PetkaPaiManager:isPetCanStarUpByItemID(itemData.m_id)
    -- isCanStarUp = false
    local Prompt = giftGrid:getChildByName("Prompt")
    Prompt:setVisible(isPetCanHeCheng or isCanStarUp)

    if index == self._curIndex then
        Choose:setVisible(true)
    end

    local  keshengxing = giftGrid:getChildByName("keshengxing")
    print("keshengxing ==>", isCanStarUp)
    keshengxing:setVisible(isCanStarUp)

    
end

function PetBagFragmentSubUI:isNoFragmentUIState( isNoFragment )
    -- body
    self._Point:setVisible(isNoFragment)
    self._suipian:setVisible(not isNoFragment)
    self._bag:setVisible(not isNoFragment)
end

function PetBagFragmentSubUI:updateDetailInfoUI( ... )
    -- body
    if #self._ownFragmentList < 1 then
        self:isNoFragmentUIState(true)
        return
    end
    self:isNoFragmentUIState(false)
    local itemData = self._ownFragmentList[self._curIndex]
    self._contentDes:setString(itemData.m_item.des)
    self._itemName:setString(itemData.m_name)


    local hechengConfig = JsonConfig.GetHeChengCfg(AppDef.ItemType.PetFrag, itemData.m_id)

    self._Node:removeAllChildren()
    local itemCell = Utils:GetItemCellValue(self._Node, 0, itemData.m_id, true, true, itemData.m_num, nil, true)
    itemCell:adjustPostion()

    local petId = hechengConfig.target[2]
    local isOwn = LRoleDataMgr.Pet:IsOwnPetById(petId)
    local btnName = self._heChengBtn:getChildByName("Text")
    if isOwn then
        local curPet = LRoleDataMgr.Pet:GetPetById(petId)
        local isCanStarUp = PetkaPaiManager:isPetCanStarUp(curPet)
        
        local costNum = PetkaPaiManager:getPetStarUpCost(curPet)
        local percent = itemData.m_num / costNum * 100
        self._loadingBar:setPercent(percent)
        self._value:setString(string.format("%d/%d", itemData.m_num, costNum))

        btnName:setString(GUITips.RSI_ZQX_HERO_LIVE_BTN)
        -- self._signText:setString(GUITips.RSI_ZQX_HERO_LIVE_BTN)
        self._heChengBtn:setTouchEnabled(isCanStarUp)
        self._heChengBtn:setBright(isCanStarUp)
        self._heChengBtn:setTag(1)



    else
        local isPetCanHeCheng = PetkaPaiManager:isPetCanHeCheng(itemData)
        self._heChengBtn:setTouchEnabled(isPetCanHeCheng)
        self._heChengBtn:setBright(isPetCanHeCheng)
        -- UI_Btn_Item_Hecheng

        local percent = itemData.m_num / hechengConfig.item[1][3] * 100
        self._loadingBar:setPercent(percent)
        self._value:setString(string.format("%d/%d", itemData.m_num, hechengConfig.item[1][3]))


        btnName:setString(GUITips.UI_Btn_Item_Hecheng)

        if isPetCanHeCheng then
            btnName:setString(GUITips.UI_Btn_Item_Hecheng)
        end
        -- self._signText:setString(GUITips.UI_Btn_Item_Hecheng)
        self._heChengBtn:setTag(2)
    end

end

function PetBagFragmentSubUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return PetBagFragmentSubUI