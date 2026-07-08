
local FriendlyDrawRewardUI = LUIBase:New()
FriendlyDrawRewardUI.__index = FriendlyDrawRewardUI
--local this = LTcpSocket
function FriendlyDrawRewardUI:New()
    local o = LUIBase:New()
    setmetatable(o,FriendlyDrawRewardUI)  
    o:Init()
    return o
end

local EVERYLINENUM = 8

--注册事件
-- -----------------------------------
function FriendlyDrawRewardUI:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function FriendlyDrawRewardUI:ProcessEvent(msg)

end

function FriendlyDrawRewardUI:Init()

    self.m_pUILayer = cc.CSLoader:createNode("csd/chouka/jiangliyulan.csb")
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
end

function FriendlyDrawRewardUI:initData( ... )
    local function IsAlreadyInList( list, id )
        -- body
        for i=1, #list do
            if list[i] == id then
                return true
            end
        end
        return false
    end

    -- body
    self.m_datas = {}
    local drawConfig = JsonConfig.m_drawConfig.getList()
    local petList = {}
    for i=1, #drawConfig do
        local data = drawConfig[i]
        -- dump(data, "FriendlyDrawRewardUI:initData ===>")
        if data.type == 5 or data.type == 6 then
            if data.award[1] == AppDef.AwrdItem.AWRD_ITEM_PET then
                local petId = data.award[2]
                if not IsAlreadyInList(petList, petId) then
                    table.insert(petList, petId)
                end
            end
        end
    end

    --按照品质分类
    for i=7, 1, -1 do
        local cellInfo = {}
        cellInfo.tag = 8 - i
        cellInfo.value = {}
        for j=1, #petList do
            -- print(i)
            local data = JsonConfig.m_heroCfg.getDefByID(petList[j])
            if i == data.quality then
                table.insert(cellInfo.value, petList[j])
            end
        end
        if #cellInfo.value > 0 then
            table.insert(self.m_datas, cellInfo)
        end
    end
end

function FriendlyDrawRewardUI:initControlUI( ... )
    -- body
    local Panel = self.m_pUILayer:getChildByName("Panel")
    local IllustrationsBg = Panel:getChildByName("IllustrationsBg")
    self._IllustrationsList = IllustrationsBg:getChildByName("IllustrationsList")
    self._pCell = IllustrationsBg:getChildByName("Image1")
    self._pCell:removeFromParent()
    self._pCell:retain()

    self.m_subItem = self._pCell:getChildByName("IconList")
    self.m_subItem:removeFromParent()
    self.m_subItem:retain()

    --奖池列表
    self._tableView = self:InitTableView()
    self._tableView:reloadData()
end

function FriendlyDrawRewardUI:GetTableSize(idx)
    local width = self._pCell:getContentSize().width
    local height = self.m_subItem:getContentSize().height
    local tempHeight = self._pCell:getContentSize().height-height
    local num = 1 
    if self.m_datas ~= nil and self.m_datas[idx+1] ~= nil and self.m_datas[idx+1].value ~= nil then
        num = math.ceil(#self.m_datas[idx+1].value / EVERYLINENUM )
        if num < 1 then num = 1 end
    end
    return width, height*num+tempHeight
end

function FriendlyDrawRewardUI:InitTableView()
    local tableView = cc.TableView:create(self._IllustrationsList:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    tableView:setAnchorPoint(cc.p(0, 0))
    tableView:setPosition(self._IllustrationsList:getPosition())
    tableView:setDelegate()
    tableView:setSwallowsTouches(false)
    tableView:setBounceable(true)
    tableView:setVerticalFillOrder( cc.TABLEVIEW_FILL_TOPDOWN)
    self._IllustrationsList:getParent():addChild(tableView)

    local function cellSizeForTable(sender,idx)
        return self:GetTableSize(idx)
    end
    local function tableCellAtIndex(sender, idx)
        return self:TableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        local cnt = 0
        for k,v in pairs(self.m_datas) do 
            cnt = cnt +1
        end 
        if cnt < 1 then cnt = 1 end
        return cnt
    end

    local function scrollViewDidScroll(view)
        self.m_isDragging = view:isDragging()
    end

    --tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)--此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)--此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)--此回调需要返回TableView中Cell的数量
    tableView:registerScriptHandler(scrollViewDidScroll,cc.SCROLLVIEW_SCRIPT_SCROLL)

    return tableView
end

function FriendlyDrawRewardUI:TableCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()

        cellChild = self._pCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))  
        cellChild:setAnchorPoint(cc.p(0, 0))
        cellChild:setTouchEnabled(false)
        cell:addChild(cellChild)
    else
        cellChild = cell:getChildByTag(123)
    end
    self:ShowTableCellInfo(cellChild, idx)
    return cell
end

function FriendlyDrawRewardUI:ShowTableCellInfo(cellChild, idx)
    if self.m_datas[idx+1] == nil or self.m_datas[idx+1].value == nil then   
        return
    end
    local width,height = self:GetTableSize(idx)
    cellChild:setContentSize(cc.size(width,height))

    local tag = self.m_datas[idx+1].tag
    self:ShowItemList(cellChild,tag,self.m_datas[idx+1].value)
end

--加载一个推荐的Icon列表
function FriendlyDrawRewardUI:ShowItemList(parent,tag,petIds)

    local num = math.ceil(#petIds / EVERYLINENUM)
    if num == 0 then return end
   
    local itemHeight = self.m_subItem:getContentSize().height
    local preSize = self._pCell:getContentSize()
    local temp = preSize.height - itemHeight
    preSize.height = itemHeight *num+temp
    parent:setContentSize(preSize)
    local title = parent:getChildByName("TitleBg")
    self:SetPosPercentY(title,1,preSize.height)
    local lvLabel = title:getChildByName("Text")
    if lvLabel ~= nil then
        lvLabel:setString(GUITips["RSI_PET_MSG"..tag])
    end
    local listview = parent:getChildByName("List")
    listview:setTouchEnabled(false)
    local temp = math.floor(preSize.height - self.m_subItem:getContentSize().height*num)/2
    self:SetPosDifY(listview,temp,preSize.height)

    local nodes = listview:getItems()
    local count =  #nodes
    for i = num+1,count do
        listview:removeItem(num)
    end

    local index = 1
    for i = 1,num do        
        local itemPanel = nodes[i]      
        if itemPanel == nil then
            itemPanel = self.m_subItem:clone() 
            listview:pushBackCustomItem(itemPanel)
        end
        for j = 1, EVERYLINENUM do 
            local item = itemPanel:getChildByName("IconBg_"..j)
            if item == nil then break end
            if index > #petIds then 
                item:setVisible(false)
                item:setTouchEnabled(false) 
            else
                --显示宠物头像
                item:setSwallowTouches(false)
                self:ShowItem(item,petIds[index])

            end
            index = index+1
        end    
    end
end

--加载单个神将
function FriendlyDrawRewardUI:ShowItem(item,id)

--用于刷新界面
    -- self._itemCell[id] = item;

    item:setVisible(true)
    item.userObject = id
    item:setTouchEnabled(true)     
    item:setSwallowTouches(false)
    local info = LPetDataMgr:FindPetDataById(id)
    if info == nil then return end
    
    local iconPanel = item:getChildByName("Bg")
    local nameLabel = iconPanel:getChildByName("Name")
    nameLabel:setString(info.name)
    nameLabel:setTextColor(AppDef:GetQualityColor(info.quality))
    --icon
    local icon = iconPanel:getChildByName("Icon")
    Utils:ShowPetHeadImg(icon,info.pic,iconPanel,info.quality,info:IsShiny())

    local function ShowPetInfo(sender)--查看信息
        if self.m_isDragging then return end
        local id = sender.userObject
        LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowPetInfo, {id})
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end
    item:addClickEventListener(ShowPetInfo)
    self:MarkIntaractCObj(item)
end

function FriendlyDrawRewardUI:SetPosPercentY(node,flag,height)
    if node == nil then return end
    local x,y = node:getPosition()
    y = flag*height
    node:setPosition(cc.p(x,y)) 
end

function FriendlyDrawRewardUI:SetPosDifY(node,flag,height)
    if node == nil then return end
    local x,y = node:getPosition()
    y = height-flag
    node:setPosition(cc.p(x,y))
end

function FriendlyDrawRewardUI:CloseUI( ... )
    -- body
    Utils:DeleteUI("HappyDraw.FriendlyDrawRewardUI")
end

function FriendlyDrawRewardUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return FriendlyDrawRewardUI