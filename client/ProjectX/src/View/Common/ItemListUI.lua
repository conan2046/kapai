--[[
lua里面的游戏逻辑控制
     道具选择UI
]]

local ItemListUI = LUIBase:New()
ItemListUI.__index = ItemListUI
--[[
userData:
userData[1]:itemType
userData[2]:value
]]
function ItemListUI:New(userData)
	local o = LUIBase:New()
	setmetatable(o,ItemListUI)	
    o:Init(userData)
	return o
end

function ItemListUI:Init(userData)
    self.m_pUILayer = cc.CSLoader:createNode("csd/DevelopChooseLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
   -- self:addChild(self.m_pUILayer)
   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitData(userData)
    self:InitTouchEvt()
    self:ShowTitle()
end

function ItemListUI:InitData(userData)
    self.m_itemType = userData[1]--道具类型
    self.m_value = userData[2]
    local panel = self.m_pUILayer:getChildByName("DevelopChooseUI")
    local listPanel = panel:getChildByName("bg")
    self.m_closeButton = listPanel:getChildByName("btn_Close")
    self.m_titleLabel = listPanel:getChildByName("Title")
    --tableview
    local listView = listPanel:getChildByName("ListView")
    self.m_pCell = self.m_pUILayer:getChildByName("Item")
    --self.m_pCell:retain()
    --self.m_pCell:removeFromParent()
    self.m_pCell:setVisible(false)

    --self.m_selectIdx = -1
    self:InitTabView(listView)
    self:RefreshCell()
 
end

function ItemListUI:InitTouchEvt()
    local function CloseCallBack(sender)
       self:CloseUI()
    end
    self.m_closeButton:addClickEventListener(CloseCallBack)
	self:MarkIntaractCObj(self.m_closeButton)
end

function ItemListUI:RefreshCell()
    local info = LRoleDataMgr.Equip.PackageMap

    self.m_itemDatas = {}
    local datas = {}
    self.m_idName = {}

    for k,v in pairs(info) do
        if v.m_id > 0 and LRoleDataMgr:GetItemType(v.m_id) == self.m_itemType then
            local count = datas[v.m_id]
            if count == nil then
                count = 0
            end
            datas[v.m_id] = count + v.m_num

            self.m_idName[v.m_id] = v.m_name
        end
    end

    self.m_curGridNum = 0
    for i,v in pairs(datas) do
        local obj = {}
		obj["id"] = i
		obj["num"] = v
		table.insert(self.m_itemDatas,obj)
        self.m_curGridNum = self.m_curGridNum +1
    end
    self.m_pTableView:reloadData()
end

function ItemListUI:InitTabView(listView)
    local tableView = cc.TableView:create(listView:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(listView:getAnchorPoint())
    tableView:setPosition(listView:getPosition())
    tableView:setDelegate()
    tableView:setSwallowsTouches(false)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    listView:getParent():addChild(tableView)

    local function tableCellTouched(sender,cell)
       -- print("tableCellTouched",sender,cell,cell:getIdx())
        self:TabCellTouched(cell)
    end
    local function cellSizeForTable(sender,idx)
        local width = self.m_pCell:getContentSize().width
        local height = self.m_pCell:getContentSize().height
        --print("width=",width, "height",height)
        return width, height
    end
    local function tableCellAtIndex(sender, idx)
        return self:LeftTableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView() 
        return self.m_curGridNum
    end


    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量

    --tableView:registerScriptHandler(scrollViewDisScroll,cc.SCROLLVIEW_SCRIPT_SCROLL)
    --tableView:reloadData()
    self.m_pTableView = tableView
end


--点击选中处理
function ItemListUI:TabCellTouched(cell)
    local ind = cell:getIdx()+1
    if ind > self.m_curGridNum or self.m_itemDatas[ind] == nil then
        return
    end
    if self.m_itemType == AppDef.EItemListType.EILTXingYunCharm then
        local function NumInputCallback(num)
            --print("NumInputCallback",num)
            self.m_itemDatas[ind].num = num
            LGameMsg.m_baseMsgWithOne:Change(LUIItemListUIEvent.SelectItem,self.m_itemDatas[ind])
            self:SendMsg(LGameMsg.m_baseMsgWithOne)
            self:CloseUI()
        end
        LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowNumInputUI, {self.m_itemDatas[ind].num,NumInputCallback})
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
        return
    end
    --self.m_selectIdx = ind
    --将itemId,itemNum反馈出去
    LGameMsg.m_baseMsgWithOne:Change(LUIItemListUIEvent.SelectItem,self.m_itemDatas[ind])
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local function onScheduleOnce()
        self:CloseUI()
    end
    --停留0.5秒后关闭界面界面
    local action = cc.Sequence:create(cc.DelayTime:create(0.5),cc.CallFunc:create(onScheduleOnce))
    self.m_pUILayer:runAction(action)
end 


function ItemListUI:LeftTableCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pCell:clone()

        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)
        cellChild:setTouchEnabled(false)             
    else
        cellChild = cell:getChildByTag(123)
    end
    self:ShowCellInfo(cellChild, idx)
    return cell
end

function ItemListUI:ShowCellInfo(cellChild, idx)
    --print("cell idx"..idx)
    local index = idx+1;
    local bgPanel = cellChild:getChildByName("bg_Icon")
    local iconImage = bgPanel:getChildByName("Icon")  
    local numLabel = bgPanel:getChildByName("Value")   
    local nameLabel = cellChild:getChildByName("Name")

    local id = self.m_itemDatas[index]["id"]
    local num = self.m_itemDatas[index]["num"]

    local icon = iconImage:getChildByTag(999)
    if icon == nil then
        icon = ItemCellUI:New(iconImage)
        icon.m_pUILayer:setTag(999)
    end
    local item = LPItem:New(id)
    item.m_item = LItemMgr:getItem(id)
    item.m_num = num
    item.m_name = item.m_item.name
    local itemValue = {
        itemData = item,
        isShowQualityBg = true,
        isShowNum = true
    }
    icon:UpdateItem(itemValue)
    numLabel:setVisible(false)
    --iconImage:loadTexture(LItemMgr:GetItemPicFileName(id),ccui.TextureResType.localType)
    
    nameLabel:setString(item.m_name)


--    if num > 1 then
--        numLabel:setVisible(true)
--        numLabel:setString(self.m_itemDatas[index]["num"])
--    else
--        numLabel:setVisible(false)
--    end
end


function ItemListUI:ShowTitle()
    if self.m_itemType == AppDef.EItemListType.EILTNone then
        return
    end
    self.m_titleLabel:setString("【"..GUITips["UI_ItemListType"..self.m_itemType].."】")
end

function ItemListUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_itemType = nil
    self.m_pTableView = nil
    self.m_itemDatas = nil
    self.m_idName = nil
    self.m_pCell = nil
end

function ItemListUI:CloseUI()
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Common.ItemListUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
end

return ItemListUI