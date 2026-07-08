
local PetEquipBagSubUI = LUIBase:New()
PetEquipBagSubUI.__index = PetEquipBagSubUI
--local this = LTcpSocket
function PetEquipBagSubUI:New()
	local o = LUIBase:New()
	setmetatable(o,PetEquipBagSubUI)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function PetEquipBagSubUI:RegistMsgs()
    self.msgIds = 
    {
        --LUIPetEvent.GotPetEquip,
        LUIPetEvent.PetBagEquipChanged,
        LUIPetEvent.PetEquipWear,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function PetEquipBagSubUI:ProcessEvent(msg)
    if msg.msgId == LUIPetEvent.PetBagEquipChanged then
        self:RefreshIconItem()
    elseif msg.msgId == LUIPetEvent.PetEquipWear then
        self:RefreshIconItem()
    end
end

function PetEquipBagSubUI:Init()

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

function PetEquipBagSubUI:InitData()
    local panel = self.m_pUILayer:getChildByName("zhuangbeibeibaoUI")
    -- panel:setTouchEnabled(false)
    --背包部分
    self.m_numLable = panel:getChildByName("Number")
    --self.m_numLable:setString(tostring(item.m_num))
    self.m_checkBox = panel:getChildByName("CheckBox")
    self.m_checkBox:addEventListener(handler(self, PetEquipBagSubUI.CheckBoxCallback))
    self.m_checkBox:setSelected(false)
    panel:reorderChild(self.m_checkBox, 10)
    self.m_recycleBtn = panel:getChildByName("recycle")
    self.m_recycleBtn:addClickEventListener(function (sender)
        Utils:InitUI("HuiShou.HuiShouMainUI", AppDef.UIType.FirstClassLayer, 2)
    end)
    --self.m_recycleBtn:setBright(false)
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
    self.m_equipList = {}--未穿戴列表
    self.m_wearingIdList = {}--已穿戴列表（包含空格）
    self:InitRightTabView(rightView)
    

    self._Point = panel:getChildByName("Point")
    local txt = self._Point:getChildByName("txt")
    txt:setVisible(true)
    txt:setString(GUITips.RSI_EQUIP_NONE)
    self:RefreshIconItem()

    --LuaNetSendMsg:QueryPetEquip(1)
end

function PetEquipBagSubUI:SortEquipList()
    if LRoleDataMgr.Pet.equipList.m_formationEquips == nil then
        LRoleDataMgr.Pet.equipList.m_formationEquips = {}
    end
    if LRoleDataMgr.Pet.equipList.m_petEquips == nil then
        LRoleDataMgr.Pet.equipList.m_petEquips = {}
    end
    self.m_wearingIdList = {}
    self.m_equipList = {}
    local wearingEquips = LRoleDataMgr.Pet.equipList.m_formationEquips
    for i=1,AppDef.Formation.MaxFightNum do 
        local equips =  wearingEquips[i]
        local pet = LRoleDataMgr.Pet:GetPetByFightPos(i)
        if equips ~= nil and pet ~= nil then
            for k = 1,AppDef.Pet.MaxEquipPosNum do
                local id = equips[k]
                if id ~= nil and id > 0  then
                    local value ={}
                    value.uid = id
                    value.name = pet.name
                    table.insert(self.m_wearingIdList,value)
                end
            end
        end
    end
    local info = LRoleDataMgr.Pet.equipList.m_petEquips
    for k,v in pairs(info) do
        local cfg = JsonConfig.m_equipConfig.getDefByID(v.m_id)
        if cfg ~= nil and v.m_fpos == 0 then        
            local value = {}
            value.uid = v.m_uid
            value.name = ""
            value.quality = v.m_quality
            value.wpos = v.m_wpos
            value.qhLv = v.cultivateLevel[AppDef.PetEquipLevelType.QiangHua] or 0
            value.jlLv = v.cultivateLevel[AppDef.PetEquipLevelType.JingLian] or 0
            table.insert(self.m_equipList,value)
        end
    end

    local function sortFuc(m1, m2)
        if m1.quality == m2.quality then
            if m1.qhLv == m2.qhLv then
                if m1.jlLv == m2.jlLv then
                    return m1.wpos > m2.wpos
                else
                    return m1.jlLv > m2.jlLv
                end
            else
                return m1.qhLv > m2.qhLv
            end
        else
            return m1.quality > m2.quality
        end
    end
    table.sort(self.m_equipList, sortFuc)
    --dump(self.m_equipList,"petequip  m_equipList ==>")
end

function PetEquipBagSubUI:CheckBoxCallback(sender,eventType)
    if eventType == ccui.CheckBoxEventType.selected then
        self.m_hideWearing = true
    elseif eventType == ccui.CheckBoxEventType.unselected then
        self.m_hideWearing = false
    end
    self:RefreshIconItem()
end

function PetEquipBagSubUI:RefreshIconItem()
    --self.m_indexTable = {}--key为m_pItemList索引,value为背包索引
    self:SortEquipList()

    local max = #self.m_equipList
    if not self.m_hideWearing and #self.m_wearingIdList > 0 then
        max = max + #self.m_wearingIdList
    end
    self.m_curGridNum = math.ceil(max/2)

    if self.m_curGridNum > 0 then
        self.m_pRightTableView:reloadData()
        self:isNoEquipUIState(false)
    else
        self:isNoEquipUIState(true)
    end

    self.m_numLable:setString(GUITips.RSI_NUM.."："..max.."/"..AppDef.Pet.MaxSuitEquipBagNum)
end


function PetEquipBagSubUI:isNoEquipUIState( isNoFragment )
    -- body
    self._Point:setVisible(isNoFragment)
    self._TableViewPanel:setVisible(not isNoFragment)
    self.m_recycleBtn:setVisible(not isNoFragment)
    --self.m_cellBtn:setVisible(not isNoFragment)
end

function PetEquipBagSubUI:InitRightTabView(rightView)
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

function PetEquipBagSubUI:RightTableCellAtIndex(sender, idx)
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
            local equipData = self.m_pItemLists[index]
            local btn = bagGrid:getChildByName("Btn_yangcheng")
            btn:addClickEventListener(function(sender)
                self:YangChengCallback(sender)
            end)
            --self:MarkIntaractCObj(bagGrid)
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

function PetEquipBagSubUI:YangChengCallback(sender)
    local uid = sender.userObject
    if uid == nil or uid == 0 then
        return
    end


    Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_EQUIPSRENGTH, {1, uid})
end

function PetEquipBagSubUI:ShowRightCellInfo(cellChild, idx)
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

function PetEquipBagSubUI:UpdateBagCell(pos,item,grid)
    if item == nil or grid == nil then
        return
    end
    grid:setVisible(false)
    local cnt = #self.m_equipList
    if not self.m_hideWearing then
        cnt = cnt +#self.m_wearingIdList
    end
    if pos > cnt then
        return
    end
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
            uid = self.m_equipList[pos-max].uid
        end
    else
        uid = self.m_equipList[pos].uid
    end
    btn.userObject = uid
    --Icon
    local info = LRoleDataMgr.Pet.equipList.m_petEquips[uid]
    if info == nil or info.m_id == 0 then
        item:UpdateItem(nil)
        return
    end
    local cfg = JsonConfig.m_equipConfig.getDefByID(info.m_id)
    if cfg == nil then
        return
    end
    grid:setVisible(true)
    local qhLv = info.cultivateLevel[AppDef.PetEquipLevelType.QiangHua] or 0
    local jlLv = info.cultivateLevel[AppDef.PetEquipLevelType.JingLian] or 0
    local jxLv = info.cultivateLevel[AppDef.PetEquipLevelType.JueXing] or 0
    local szLv = info.cultivateLevel[AppDef.PetEquipLevelType.ShenZhu] or 0
    Utils:GetEquipCellValue(grid,item,info.m_id,info.m_uid,qhLv,jlLv,szLv,jxLv,true,true)

    --其他
    local strName = info.m_name
    if qhLv > 0 then
        strName = strName.."+"..qhLv
    end
    nameLable:setString(strName)
    nameLable:setColor(AppDef:GetQualityColor(cfg.quality))
    self:ShowEquipAttr(attr1Lable,cfg.attr[1],cfg.attr[2],info)

    --红点
    local isqianghua, isjinglian, isjuexing, isshenzhu = LRedDotCheckMgr:EquipCultivateRedDotCheck(info.m_uid)
    if isqianghua or isjinglian or isjuexing or isshenzhu then
        redImg:setVisible(true)
    end
end

--[[
显示装备属性
]]
function PetEquipBagSubUI:ShowEquipAttr(sender,attrType,attrVal,info)
    if sender == nil or attrType == nil or attrVal == nil or info == nil then
        sender:setString("")
        return
    end
    for k,v in pairs(info.qhAttrs) do 
        if k == attrType then
            attrVal = attrVal +v
        end
    end
    for k,v in pairs(info.jlAttrs) do 
        if k == attrType then
            attrVal = attrVal +v
        end
    end
    for k,v in pairs(info.jxAttrs) do 
        if k == attrType then
            attrVal = attrVal +v
        end
    end
    for k,v in pairs(info.szAttrs) do 
        if k == attrType then
            attrVal = attrVal +v
        end
    end
    sender:setString(Utils:getAttrStr(attrType,attrVal))
end


function PetEquipBagSubUI:onExit()
    for key,value in pairs(self.m_pItemLists) do 
        value:onExit(true)
    end
    self.m_pUILayer = nil
    self.m_pItemLists = nil
    self.m_idList = nil
    self:Destory()
end

return PetEquipBagSubUI