
local PetFaBaoChangeUI = LUIBase:New()
PetFaBaoChangeUI.__index = PetFaBaoChangeUI
--local this = LTcpSocket
function PetFaBaoChangeUI:New(userdata)
	local o = LUIBase:New()
	setmetatable(o,PetFaBaoChangeUI)	
    o:Init(userdata)
	return o
end

--注册事件
-- -----------------------------------
function PetFaBaoChangeUI:RegistMsgs()
    self.msgIds = 
    {

    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function PetFaBaoChangeUI:ProcessEvent(msg)

end

function PetFaBaoChangeUI:Init(userdata)
    self.m_part = userdata[1] or 0
    self.m_fPos = userdata[2] or 0



    --记录另一个位置法宝的种类，不能戴重复法宝
    self._otherFabaoWearId = 0
    local fabaos = Utils:GetFaBaoByfPos(self.m_fPos)


    if fabaos then
        for k,v in pairs(fabaos) do
            if k ~= self.m_part and v > 0 then
                self._otherFabaoWearId = LRoleDataMgr.Pet.faBaoList.m_petFaBaos[v].m_id
                break
            end
        end
    end
    self.m_pUILayer = cc.CSLoader:createNode("csd/zhuangbeiyangcheng/zhuangbeigenghuan.csb")
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
    self:RegisterGuide()
end

function PetFaBaoChangeUI:InitData()
    local panel = self.m_pUILayer:getChildByName("Popup")
    panel:setTouchEnabled(false)
    local closeBtn = panel:getChildByName("Btn_close")
    closeBtn:addClickEventListener(function(sender)
        self:CloseUI()
    end)
    --背包部分
    --self.m_numLable = panel:getChildByName("Number")
    --self.m_numLable:setString(tostring(item.m_num))

    local titleStr = panel:getChildByName("Title"):getChildByName("Title")
    titleStr:setString(GUITips.UI_Title_PetFaBao_Tips7)
    

    self.m_checkBox = panel:getChildByName("CheckBox")
    self.m_checkBox:addEventListener(handler(self, PetFaBaoChangeUI.CheckBoxCallback))
    self.m_checkBox:setSelected(true)
    panel:reorderChild(self.m_checkBox, 10)
    --背包格
    local rightView = panel:getChildByName("TableView")
    self.m_pGridCell = self.m_pUILayer:getChildByName("ItemList")
    self.m_pGridCell:setVisible(false)
    rightView:setEnabled(false)

    self.m_hideWearing = true --隐藏已穿戴装备
    self.m_pItemLists = {}
    self.m_faBaoList = {}--未穿戴列表
    self.m_wearingIdList = {}--已穿戴列表（包含空格）
    self:InitRightTabView(rightView)
    self:RefreshIconItem()
    
end

function PetFaBaoChangeUI:SortFaBaoList()

    if LRoleDataMgr.Pet.faBaoList.m_petFaBaos == nil then
        LRoleDataMgr.Pet.faBaoList.m_petFaBaos = {}
    end
    self.m_equipList = {}
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

    self.m_faBaoList = {}
    local AllList = LRoleDataMgr.Pet.faBaoList.m_petFaBaos
    for k,v in pairs(AllList) do
        -- local cfg = JsonConfig.m_equipConfig.getDefByID(v.m_id)
        local cfg = v.baseData
        if cfg ~= nil and v.m_fpos == 0 and cfg.equip > 0 and self._otherFabaoWearId ~= v.m_id then
            table.insert(self.m_faBaoList, v)
        end
    end

    local function sortFuc(m1, m2)
        return PetkaPaiManager:getFabaoProp(m1) > PetkaPaiManager:getFabaoProp(m2)
    end
    table.sort(self.m_faBaoList, sortFuc)

end



function PetFaBaoChangeUI:CheckBoxCallback(sender,eventType)

    if eventType == ccui.CheckBoxEventType.selected then
        self.m_hideWearing = true
    elseif eventType == ccui.CheckBoxEventType.unselected then
        self.m_hideWearing = false
    end
    self:RefreshIconItem()
end

function PetFaBaoChangeUI:RefreshIconItem()
    --self.m_indexTable = {}--key为m_pItemList索引,value为背包索引
    self:SortFaBaoList()
    --print("self.m_hideWearing",self.m_hideWearing)
    local max = #self.m_faBaoList
    if not self.m_hideWearing and #self.m_wearingIdList > 0 then
        max = max + #self.m_wearingIdList
    end
    self.m_curGridNum = math.ceil(max/2)

    self.m_pRightTableView:reloadData()
    -- self.m_numLable:setString(GUITips.RSI_NUM.."："..max.."/"..AppDef.Pet.MaxSuitEquipBagNum)
end

function PetFaBaoChangeUI:InitRightTabView(rightView)
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

function PetFaBaoChangeUI:RightTableCellAtIndex(sender, idx)
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
        for i=1,2 do
            local bagGrid = cellChild:getChildByName("Item"..i)
            bagGrid:setSwallowTouches(false)
            local index = idx*2+i
            bagGrid:setTag(index)
            local item = ItemCellUI:New(bagGrid:getChildByName("Icon"))
            item:SetIsNonAutoFree(true)
            table.insert(self.m_pItemLists, item)
            bagGrid.userObject = #self.m_pItemLists
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

function PetFaBaoChangeUI:YangChengCallback(sender)
    local uid = sender.userObject

    if uid == nil or uid == 0 or self.m_fPos == 0 then
        return
    end

    --穿戴
    -- local tag = sender:getTag()
    LuaNetSendMsg:SendFaBaoTakeOn(uid, self.m_fPos, self.m_part)

    self:CloseUI()
end

function PetFaBaoChangeUI:ShowRightCellInfo(cellChild, idx)
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

function PetFaBaoChangeUI:UpdateBagCell(pos,item,grid)
    if item == nil or grid == nil then
        return
    end
    grid:setVisible(false)
    local cnt = #self.m_faBaoList
    if not self.m_hideWearing then
        cnt = cnt +#self.m_wearingIdList
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

    signNode:setVisible(false)
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
            uid = self.m_faBaoList[pos-max].m_uid
        end
    else
        uid = self.m_faBaoList[pos].m_uid
    end
    local info = LRoleDataMgr.Pet.faBaoList.m_petFaBaos[uid]

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
    nameLable:setTextColor(AppDef:GetQualityColor(info.quality))
    self:ShowFaBaoBaseAttr(attr1Lable, info)

end


--[[
显示法宝基础属性加成
]]
function PetFaBaoChangeUI:ShowFaBaoBaseAttr(sender, info)
    if sender == nil or info == nil then
        sender:setString("")
        return
    end

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

function PetFaBaoChangeUI:CloseUI()
    LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "FaBao.PetFaBaoChangeUI")
    self:SendMsg(LGameMsg.m_deleteUIMsg)
end


function PetFaBaoChangeUI:onExit()
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep,GuideDef.StepId.Guide_XunBao_11)
    for key,value in pairs(self.m_pItemLists) do 
        value:onExit(true)
    end
    self.m_pUILayer = nil
    self.m_pItemLists = nil
    self.m_idList = nil
    self:Destory()
    Utils:CheckGuide(GuideDef.StepId.Guide_XunBao_12)
end

function PetFaBaoChangeUI:RegisterGuide()
    local cell = self.m_pRightTableView:cellAtIndex(0)
    if cell == nil then
        return
    end
    local cellChild = cell:getChildByTag(123)
    self.m_guideBtn = cellChild:getChildByName("Item1"):getChildByName("Btn_yangcheng")
    if self.m_guideBtn ~= nil then
        Utils:RegisterGuide(GuideDef.StepId.Guide_XunBao_11, self.m_guideBtn ,function()
            self:YangChengCallback(self.m_guideBtn)
        end, nil, true)
    end
end

return PetFaBaoChangeUI