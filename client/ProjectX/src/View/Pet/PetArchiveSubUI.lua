--[[
lua里面的游戏逻辑控制
神将-图鉴
]]

local PetArchiveSubUI = LUIBase:New()
PetArchiveSubUI.__index = PetArchiveSubUI
function PetArchiveSubUI:New()
    local o = LUIBase:New()
    setmetatable(o, PetArchiveSubUI)
    o:Init()
    return o
end


function PetArchiveSubUI:Init()
    self.m_pUILayer = cc.CSLoader:createNode("csd/IllustrationsLayer.csb")
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
    self:LoadPetList()

end

function PetArchiveSubUI:onExit()
    self.m_pUILayer = nil
    self.m_pTableView = nil
    if self.m_subPanel then
        self.m_subPanel:release()
        self.m_subPanel = nil
    end
    if self.m_subItem then
        self.m_subItem:release()
        self.m_subItem = nil
    end
    if self.m_starCell:clone() then
        self.m_starCell:release()
        self.m_starCell = nil
    end
    self.m_petListView = nil
    self.m_petType = nil
    self.m_checkBoxList = nil
    self._itemCell = nil
    self:Destory()
end

----[[
--注册UI消息
--]]
function PetArchiveSubUI:RegistMsgs()
   self.msgIds =
   {
        LUIPetEvent.ComposionPet,
   }
   --print(" PetArchiveSubUI:RegistMsgs",LUIPetEvent.ComposionPet)
   self:RegistSelf(self, self.msgIds)
end

function PetArchiveSubUI:ProcessEvent(msg)
   --print("PetArchiveSubUI:ProcessEvent",msg.msgId)
   if msg.msgId == LUIPetEvent.ComposionPet then
       --print("PetArchiveSubUI:ProcessEvent id", msg.value)
       self:updateItem(msg.value)
   end

end

function PetArchiveSubUI:InitData()
    local function callback(sender,eventType)
        local index = sender.userObject
        if eventType == ccui.CheckBoxEventType.selected then
            self:SelectType(index)
        end
    end

    local panel = self.m_pUILayer:getChildByName("Panel")
    --信息
    local infoPanel = panel:getChildByName("IllustrationsBg")
    --神将图标ListView
    self.m_petListView = infoPanel:getChildByName("IllustrationsList")

    self.m_subPanel = infoPanel:getChildByName("Image1")
    self.m_subPanel:retain()
    self.m_subPanel:removeFromParent()
    self.m_subItem = self.m_subPanel:getChildByName("IconList")
    self.m_subItem:retain()
    self.m_subItem:removeFromParent()
    self.m_starCell = self.m_subItem:getChildByName("IconBg_1"):getChildByName("StarsList"):getChildByName("Star")
    self.m_starCell:retain()
    self.m_starCell:removeFromParent()
    --checkBox
    self.m_petType = 0 --所有
    local boxPanel = panel:getChildByName("CheckList"):getChildByName("List")
    self.m_checkBoxList = {}
    for i = 1,7 do
        local checkBox = boxPanel:getChildByName("CheckBox_"..i)
        table.insert(self.m_checkBoxList,checkBox)
        if i == 1 then
            checkBox:setSelected(true)
            checkBox:setTouchEnabled(false)
        else
            checkBox:setSelected(false)
        end
        checkBox.userObject = i-1
        checkBox:addEventListener(callback)
    end

    self.m_pTableView = self:InitTableView(self.m_petListView:getParent())
    self.m_petListView:setVisible(false)
    self.m_petListView:setEnabled(false)
    --self.m_petListView:removeFromParent()
    self._itemCell = {}
end

function PetArchiveSubUI:SelectType(petType)
    if self.m_petType == petType then return end
    self.m_petType = petType
    for i= 1,7 do
        if i == petType+1 then
            self.m_checkBoxList[i]:setSelected(true)
            self.m_checkBoxList[i]:setTouchEnabled(false)
        else
            self.m_checkBoxList[i]:setSelected(false)
            self.m_checkBoxList[i]:setTouchEnabled(true)
        end
    end
    self:LoadPetList()
end

function PetArchiveSubUI:GetTableSize(idx)
    local width = self.m_subPanel:getContentSize().width
    local height = self.m_subItem:getContentSize().height
    local tempHeight = self.m_subPanel:getContentSize().height-height
    local num = 1 
    if self.m_datas ~= nil and self.m_datas[idx+1] ~= nil and self.m_datas[idx+1].value ~= nil then
        num = math.ceil(#self.m_datas[idx+1].value/6)
        if num < 1 then num = 1 end
    end
    return width, height*num+tempHeight
end

function PetArchiveSubUI:InitTableView()
    local tableView = cc.TableView:create(self.m_petListView:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    tableView:setAnchorPoint(cc.p(0, 0))
    tableView:setPosition(self.m_petListView:getPosition())
    tableView:setDelegate()
    tableView:setSwallowsTouches(false)
    tableView:setBounceable(true)
    tableView:setVerticalFillOrder( cc.TABLEVIEW_FILL_TOPDOWN)
    self.m_petListView:getParent():addChild(tableView)

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

function PetArchiveSubUI:TableCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()

        cellChild = self.m_subPanel:clone()
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

function PetArchiveSubUI:ShowTableCellInfo(cellChild, idx)
    if self.m_datas[idx+1] == nil or self.m_datas[idx+1].value == nil then   
        return
    end
    local width,height = self:GetTableSize(idx)
    cellChild:setContentSize(cc.size(width,height))
    --print("ShowTableCellInfo",idx,width,height)

    local tag = self.m_datas[idx+1].tag
    self:ShowItemList(cellChild,tag,self.m_datas[idx+1].value)
end

--加载总的列表
function PetArchiveSubUI:LoadPetList()
    if self.m_pTableView == nil then return end
    self.m_datas  = LPetDataMgr:GetPetListByType(self.m_petType)
    if self.m_datas == nil then self.m_datas = {} return end
    self._itemCell = {}
--    local cnt = 1
--    for i = 1,AppDef.MAX_PET_TAG do

--        if self.m_datas[i] ~= nil then   
--            local cell = self.m_petListView:getItem(cnt-1)
--            if cell == nil then
--                cell = self.m_subPanel:clone()
--                self.m_petListView:pushBackCustomItem(cell)
--            end
--            local tag = i
--            self:ShowItemList(cell,tag,self.m_datas[i])
--            cnt = cnt +1
--        end
--    end
--    for i=cnt,AppDef.MAX_PET_TAG do
--        self.m_petListView:removeItem(cnt-1)
--    end
    --self.m_petListView:refreshView()
    self.m_pTableView:reloadData()
end

--加载一个推荐的Icon列表
function PetArchiveSubUI:ShowItemList(parent,tag,petIds)
    local num = math.ceil(#petIds/6)
    if num == 0 then return end
   
    local itemHeight = self.m_subItem:getContentSize().height
    local preSize = self.m_subPanel:getContentSize()
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
        for j = 1,6 do 
            local item = itemPanel:getChildByName("IconBg_"..j)
            if item == nil then break end
            if index > #petIds then 
                item:setVisible(false)
                item:setTouchEnabled(false) 
            else
                self:ShowItem(item,petIds[index])
            end
            index = index+1
        end    
    end
end

--加载单个神将
function PetArchiveSubUI:ShowItem(item,id)

--用于刷新界面
    self._itemCell[id] = item;

    item:setVisible(true)
    item.userObject = id
    item:setTouchEnabled(true)     
    item:setSwallowTouches(false)
    local info = LPetDataMgr:FindPetDataById(id)
    if info == nil then return end
    
    local iconPanel = item:getChildByName("Bg")
    local nameLabel = iconPanel:getChildByName("Name")
    nameLabel:setString(info.name)
    nameLabel:setTextColor(AppDef:GetPetQualityColor(info.quality))
    --icon
    local icon = iconPanel:getChildByName("Icon")
    Utils:ShowPetHeadImg(icon,info.pic,iconPanel,info.quality,info:IsShiny())
    --评分
    local scoreImage = iconPanel:getChildByName("Quality")
    AppDef:GetPetQualityScore(scoreImage,info.quality)
    --神将类型
    local typeImage = iconPanel:getChildByName("Career")
    AppDef:ShowPetType(typeImage,info.petType)
    --招募按钮
    local btn = item:getChildByName("Button")
    btn.userObject = id
    --碎片
    local loadingBarPanel = item:getChildByName("LoadingBg")
    local bar = loadingBarPanel:getChildByName("LoadingBar")
    local text = loadingBarPanel:getChildByName("Text")
    --拥有标识
    local sign = iconPanel:getChildByName("Have")   
    local signHave = LRoleDataMgr.Pet:GetPetById(id)
    if signHave ~= nil then
        sign:setVisible(true)
        btn:setVisible(false)
        btn:setTouchEnabled(false)
        loadingBarPanel:setVisible(false)
    else
        sign:setVisible(false)
		local redPoint = item:getChildByName("Prompt")
		redPoint:setVisible(false)
        local percent = self:ShowMats(text,id)
        if percent >= 100 then 
            percent = 100 
            btn:setVisible(true)
            btn:setTouchEnabled(true)
            bar:setVisible(false)
            redPoint:setVisible(true)
        else
            loadingBarPanel:setVisible(true)
            bar:setPercent(percent)
            btn:setVisible(false)
            btn:setTouchEnabled(false)
            bar:setVisible(true)
        end
    end
    --初始星级
    local starListView = item:getChildByName("StarsList")
    starListView:removeAllItems()
    for i=1,info.initStar do
        local star = self.m_starCell:clone()
        starListView:pushBackCustomItem(star)
    end

    
    local function Callback(sender)--按钮点击
        local id = sender.userObject
        local cpdData = LDataConstMgr:GetPetCpdData(id)
        --print("Callback ...id", id, cpdData.itemId);
        LuaNetSendMsg:QueryGetPet(11, id)
    end
    btn:addClickEventListener(Callback)
	self:MarkIntaractCObj(btn)
    local function ShowPetInfo(sender)--查看信息
        if self.m_isDragging then return end
        local id = sender.userObject
        LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowPetInfo, {id})
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end
    item:addClickEventListener(ShowPetInfo)
	self:MarkIntaractCObj(item)
end

function PetArchiveSubUI:SetPosPercentY(node,flag,height)
    if node == nil then return end
    local x,y = node:getPosition()
    y = flag*height
    node:setPosition(cc.p(x,y)) 
end

function PetArchiveSubUI:SetPosDifY(node,flag,height)
    if node == nil then return end
    local x,y = node:getPosition()
    y = height-flag
    node:setPosition(cc.p(x,y))
end

--[[
显示宠物碎片数量
]]
function PetArchiveSubUI:ShowMats(numLabel,id)
    if numLabel == nil then return nil end
    local cpdData = LDataConstMgr:GetPetCpdData(id)
    if cpdData == nil then return nil end

    local itemId = cpdData.itemId
    local itemNum = cpdData.itemNum
    if itemNum < 1 then itemNum = 1 end
    local citem = LDataConstMgr:getCItemByID(itemId)
    local myItemNum = LRoleDataMgr.Equip:CountItemNumById(itemId)
    numLabel:setString( "" .. myItemNum .. "/" .. itemNum)
    return (myItemNum/itemNum)*100
end

function PetArchiveSubUI:updateItem(id)
    -- body
    if self._itemCell[id] == nil then
        return
    end

    local item = self._itemCell[id]
    local btn = item:getChildByName("Button")
    btn:setVisible(false)

    --拥有标识
    local iconPanel = item:getChildByName("Bg")
    local sign = iconPanel:getChildByName("Have") 
    sign:setVisible(true)

    local loadingBarPanel = item:getChildByName("LoadingBg")
    loadingBarPanel:setVisible(false)

    item:getChildByName("Prompt"):setVisible(false)

end

 
return PetArchiveSubUI