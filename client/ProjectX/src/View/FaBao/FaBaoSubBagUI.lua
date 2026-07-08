
local FaBaoSubBagUI = LUIBase:New()
FaBaoSubBagUI.__index = FaBaoSubBagUI
--local this = LTcpSocket
function FaBaoSubBagUI:New()
	local o = LUIBase:New()
	setmetatable(o,FaBaoSubBagUI)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function FaBaoSubBagUI:RegistMsgs()
    self.msgIds = 
    {
        LUIFaBaoEvent.GotPetFaBao,
        LUIFaBaoEvent.PetFaBaoWear,
        LUIFaBaoEvent.UpdateFaBaoSuc,
        LUIFaBaoEvent.PetQHSuc,
    }
    self:RegistSelf(self,self.msgIds)

end

-- -----------------------------------
function FaBaoSubBagUI:ProcessEvent(msg)
    if msg.msgId == LUIFaBaoEvent.PetFaBaoWear then
        self:RefreshIconItem()
    elseif msg.msgId == LUIFaBaoEvent.GotPetFaBao then
        print("ProcessEvent === LUIFaBaoEvent.GotPetFaBao>")
        self:RefreshIconItem()
    elseif msg.msgId == LUIFaBaoEvent.UpdateFaBaoSuc then
        self:RefreshIconItem()
    elseif msg.msgId == LUIFaBaoEvent.PetQHSuc then
        self:RefreshIconItem()
    end
end

function FaBaoSubBagUI:Init()

    self.m_pUILayer = cc.CSLoader:createNode("csd/zhuangbeiyangcheng/zhuangbeibeibao.csb")
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

function FaBaoSubBagUI:InitData()
    local panel = self.m_pUILayer:getChildByName("zhuangbeibeibaoUI")
    -- panel:setTouchEnabled(false)
    --背包部分
    self.m_numLable = panel:getChildByName("Number")
    self.m_numLable:setString(GUITips.RSI_NUM.."：".."0".."/"..AppDef.Pet.MaxFaBaoBagNum)
    self.m_checkBox = panel:getChildByName("CheckBox")
    self.m_checkBox:addEventListener(handler(self, FaBaoSubBagUI.CheckBoxCallback))
    self.m_checkBox:setSelected(false)
    panel:reorderChild(self.m_checkBox, 10)
    self.m_recycleBtn = panel:getChildByName("recycle")
    self.m_recycleBtn:addClickEventListener(function ( sender )
        -- body
        Utils:OpenFunction(AppDef.EModuleID.EMID_HUISHOU, 3)
    end)
	self.m_recycleBtn:setVisible(false)
    self.m_cellBtn = panel:getChildByName("cell")
    self.m_cellBtn:setVisible(false)
    --背包格
    local rightView = panel:getChildByName("TableView")
    self._TableViewPanel = rightView
    self.m_pGridCell = panel:getChildByName("ItemList")
    self.m_pGridCell:setVisible(false)
    rightView:setEnabled(false)

    self.m_hideWearing = false --隐藏已穿戴装备
    self.m_pItemLists = {}
    self.m_fabaoList = {}--未穿戴列表
    self.m_wearingIdList = {}--已穿戴列表（包含空格）

    self._Point = panel:getChildByName("Point")
    local txt = self._Point:getChildByName("txt")
    txt:setVisible(true)
    txt:setString(GUITips.RSI_FABAO_NONE)

    self:InitRightTabView(rightView)
    -- self:RefreshIconItem()
    LuaNetSendMsg:SendFaBaoList()
end

function FaBaoSubBagUI:SortFaBaoList()

    if LRoleDataMgr.Pet.faBaoList.m_petFaBaos == nil then
        LRoleDataMgr.Pet.faBaoList.m_petFaBaos = {}
    end
    self.m_wearingIdList = {}

    local wearingFaBaos = LRoleDataMgr.Pet.faBaoList.m_formationFaBaos
    for i=1,AppDef.Formation.MaxFightNum do 
        local faBaos =  wearingFaBaos[i]
        local pet = LRoleDataMgr.Pet:GetPetByFightPos(i)
        if faBaos ~= nil and pet ~= nil then
            for k = 1,AppDef.Pet.MaxEquipPosNum do
                local id = faBaos[k]
                if id ~= nil and id > 0  then
                    local value ={}
                    value.uid = id
                    value.name = pet.name
                    table.insert(self.m_wearingIdList, value)
                end
            end
        end
    end


    self.m_fabaoList = {}
    local AllList = LRoleDataMgr.Pet.faBaoList.m_petFaBaos
    -- dump(AllList, "SortFaBaoList 1111 ===>")

    for k,v in pairs(AllList) do
        -- local cfg = JsonConfig.m_equipConfig.getDefByID(v.m_id)
        local cfg = v.baseData
        if cfg ~= nil and v.m_id > 0 and v.m_fpos == 0 then
            table.insert(self.m_fabaoList, v)
        end
    end

    local function sortFuc(m1, m2)
        return PetkaPaiManager:getFabaoProp(m1) > PetkaPaiManager:getFabaoProp(m2)
    end
    table.sort(self.m_fabaoList, sortFuc)
    -- dump(self.m_fabaoList,"fabaoList  m_fabaoList ==>")
end

function FaBaoSubBagUI:isNoFaBaoUIState( isNoFragment )
    -- body
    self._Point:setVisible(isNoFragment)
    self._TableViewPanel:setVisible(not isNoFragment)
    self.m_recycleBtn:setVisible(not isNoFragment)
    -- self.m_cellBtn:setVisible(not isNoFragment)
end

function FaBaoSubBagUI:CheckBoxCallback(sender,eventType)
    if eventType == ccui.CheckBoxEventType.selected then
        self.m_hideWearing = true
    elseif eventType == ccui.CheckBoxEventType.unselected then
        self.m_hideWearing = false
    end
    self:RefreshIconItem()
end


function FaBaoSubBagUI:RefreshIconItem()
    self:SortFaBaoList()
    -- local AllList = LRoleDataMgr.Pet.faBaoList.m_petFaBaos
    -- dump(AllList, "SortFaBaoList 1111 ===>")
    local max = #self.m_fabaoList
    if not self.m_hideWearing and #self.m_wearingIdList > 0 then
        max = max + #self.m_wearingIdList
    end

    self.m_curGridNum = math.ceil(max/2)
    
    print("RefreshIconItem == self.m_curGridNum >", self.m_curGridNum)
    if self.m_curGridNum > 0 then
        self.m_pRightTableView:reloadData()
        self:isNoFaBaoUIState(false)
    else
        self:isNoFaBaoUIState(true)
    end
    
    self.m_numLable:setString(GUITips.RSI_NUM.."："..max.."/"..AppDef.Pet.MaxFaBaoBagNum)
end

function FaBaoSubBagUI:InitRightTabView(rightView)
    local tableView = cc.TableView:create(rightView:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(rightView:getAnchorPoint())
    tableView:setPosition(rightView:getPosition())
    tableView:setDelegate()
    tableView:setSwallowsTouches(false)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    rightView:getParent():addChild(tableView)
    
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

function FaBaoSubBagUI:RightTableCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pGridCell:clone()
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
            bagGrid:setTag(index)
            local item = ItemCellUI:New(bagGrid:getChildByName("Icon"), {isChangeSize = true})
            item:SetIsNonAutoFree(true)
            table.insert(self.m_pItemLists, item)
            bagGrid.userObject = #self.m_pItemLists
            
            -- dump(itemData, "RightTableCellAtIndex ================== 1111111111111 =====>>")
            local btn = bagGrid:getChildByName("Btn_yangcheng")
            btn:addClickEventListener(handler(self, FaBaoSubBagUI.YangChengCallback))
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

function FaBaoSubBagUI:YangChengCallback(sender)
    local uid = sender.userObject
    -- print("YangChengCallback ===> 111", uid, sender, sender.userObject)
    if uid == nil or uid == 0 then
        return
    end

    print("YangChengCallback ===>", uid)
    -- Utils:InitUI("FaBao.FaBaoCultivateMainUI", AppDef.UIType.FirstClassLayer, {1, uid})
    Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_FABAO_QIANGHUA, {1, uid})
end

function FaBaoSubBagUI:ShowRightCellInfo(cellChild, idx)
    --print("cell idx"..idx)
    local min = idx * 2;
    for i = 1,  2 do
        local index = i+min
        local bagGrid = cellChild:getChildByName("Item"..i)
        local num = bagGrid.userObject
        local item = self.m_pItemLists[num]
        self:UpdateBagCell(index,item,bagGrid)
        --self.m_indexTable[num] = index      
    end
end

function FaBaoSubBagUI:UpdateBagCell(pos,item,grid)
    if item == nil or grid == nil then
        return
    end
    grid:setVisible(false)
    local cnt = #self.m_fabaoList
    if not self.m_hideWearing then
        cnt = cnt + #self.m_wearingIdList
    end
    if pos > cnt then
        return
    end
    grid:setVisible(true)
    local signNode = grid:getChildByName("yichuandai")--已穿戴标识
    local nameLable = grid:getChildByName("Name_1")--装备名
    local petNameLable = grid:getChildByName("Name_2")--英雄名
    local attr1Lable = grid:getChildByName("Atrribute_1")--基础属性
    local attr2Lable = grid:getChildByName("Atrribute_2")--暂时空着
    local btn = grid:getChildByName("Btn_yangcheng") 
    local redImg = btn:getChildByName("Prompt")--红点
    signNode:setVisible(false)
    redImg:setVisible(false)
    petNameLable:setString("")
    nameLable:setString("")
    attr2Lable:setString("")
    local uid = 0
    if not self.m_hideWearing then
        local max = #self.m_wearingIdList
        if pos <= max then
            uid = self.m_wearingIdList[pos].uid
            signNode:setVisible(true)
            petNameLable:setString(self.m_wearingIdList[pos].name)
        else
            uid = self.m_fabaoList[pos-max].m_uid
        end
    else
        uid = self.m_fabaoList[pos].m_uid

    end
    local info = LRoleDataMgr.Pet.faBaoList.m_petFaBaos[uid]

    -- dump(LRoleDataMgr.Pet.faBaoList.m_petFaBaos, "==============>")
    -- print("22222222222222 -------- =====>", uid)

    if info == nil then
        return
    end
    btn.userObject = uid
    btn:setVisible(true)
    if info.m_id >= 615 and info.m_id <= 617 then
        btn:setVisible(false)
    end

    local qhLv = info.qhLv
    local jlLv = info.jlLv

    Utils:GetFaBaoCellValue(grid, item, info.m_id, info.m_uid, false, 10, qhLv, jlLv, true, true)

    --其他
    local strName = info.baseData.name
    if qhLv > 0 then
        strName = strName.."+"..qhLv
    end
    nameLable:setString(strName)
    nameLable:setColor(AppDef:GetQualityColor(info.baseData.quality))
    self:ShowFaBaoBaseAttr(attr1Lable, info)

    --红点
	local isqianghua, isjinglian = LRedDotCheckMgr:FaBaoCultivateRedDotCheck(info.m_uid)
    redImg:setVisible(isqianghua or isjinglian)
end

--[[
显示法宝基础属性加成
]]
function FaBaoSubBagUI:ShowFaBaoBaseAttr(sender, info)
    if sender == nil or info == nil then
        sender:setString("")
        return
    end

    print("FaBaoSubBagUI:ShowFaBaoBaseAttr ===>", info.m_id)
    if info.m_id >= 615 and info.m_id <= 617 then
        sender:setString("+" .. info.baseData.exp)
        return
    end

    local baseAttr = info.baseData.attr
    local totalAttr = baseAttr[2]
    --强化加成

    local qianghuaData = info.baseData.atrr_qianghua
    if qianghuaData[1] == baseAttr[1] then
        totalAttr = totalAttr + qianghuaData[2] * info.qhLv
    end
    

    --精炼加成
    for i=1, #info.baseData.attr_jinglian do
        local data = info.baseData.attr_jinglian[i]
        if data[1] == baseAttr[1] then
            totalAttr = totalAttr + data[2] * info.jlLv
        end
    end

    sender:setString(Utils:getAttrStr(qianghuaData[1], totalAttr))
    
end


function FaBaoSubBagUI:onExit()
    for key,value in pairs(self.m_pItemLists) do 
        value:onExit(true)
    end
    self.m_pUILayer = nil
    self.m_pItemLists = nil
    self.m_idList = nil
    self:Destory()
end

return FaBaoSubBagUI