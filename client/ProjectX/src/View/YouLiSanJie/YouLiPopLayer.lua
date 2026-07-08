local YouLiPopLayer = LUIBase:New()
YouLiPopLayer.__index = YouLiPopLayer
function YouLiPopLayer:New(data)
    local o = LUIBase:New()
    setmetatable(o,YouLiPopLayer)  
    o:Init(data)
    return o
end
--[[
注册消息
]]
function YouLiPopLayer:RegistMsgs()
    self.msgIds = 
    {
        LUILogicEvent.InitUI,      
    }
    self:RegistSelf(self,self.msgIds)
end

function YouLiPopLayer:ProcessEvent(msg)
   
end
function YouLiPopLayer:Init(data)
    self:RegistMsgs()
    self.m_pUILayer = cc.CSLoader:createNode("csd/youli/youli.csb")
    ccui.Helper:doLayout(self.m_pUILayer)
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitVariable()

    self:InitPanel()

    self:AddTouchEvt()
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.IsHideBgAndBtn,false)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback,function ()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "YouLiSanJie.YouLiPopLayer")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end


function YouLiPopLayer:InitVariable()
   
end
function YouLiPopLayer:InitPanel()
    self.m_pBtnAddPet=self:FindNode("Btn_add")
    self.m_pBtnChangePet=self:FindNode("Btn_Change")
    self.m_pInfo1=self:FindNode("Info_1")
    self.m_pInfo2=self:FindNode("Info_2")
    self.m_pInfo3=self:FindNode("Info_3")
   
end 
-- type 1  2  3
function YouLiPopLayer:SetInfoVisible(idx)
    self.m_pInfo1:setVisible(string.match(self.m_pInfo1:getName(),tostring(idx))) 
    self.m_pInfo2:setVisible(string.match(self.m_pInfo2:getName(),tostring(idx))) 
    self.m_pInfo3:setVisible(string.match(self.m_pInfo3:getName(),tostring(idx)))   
end



function YouLiPopLayer:AddTouchEvt()
    -- self.m_pOneClickYL:addClickEventListener(function(sender)
    --     self:m_pOneClickYLClicked(sender)     
    -- end)
    -- self.m_pOneClickYL:addClickEventListener(function(sender)
    --     self:OneClickLQClicked(sender)     
    -- end)

end
function YouLiPopLayer:InitMianListView()
    local listView = self:FindNode("ListView")
    local tableView = cc.TableView:create(listView:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_HORIZONTAL)  
    tableView:setAnchorPoint(cc.p(0,0)) 
    tableView:setPosition(cc.p(0,0))
    tableView:setDelegate()
    tableView:setSwallowsTouches(false)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    listView:addChild(tableView)
    local function tableCellTouched(sender,cell)
        self:PanelItemClicked(cell)
    end
    local function cellSizeForTable(sender,idx)
        local size = self.m_pContentCell:getContentSize()
        return size.width, size.height
    end
    local function tableCellAtIndex(sender, idx)
        return self:UpdatePanelItem(sender, idx)
    end

    local function numberOfCellsInTableView()
        return #self.m_Config.getList()
    end
    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量  
    tableView:reloadData()
end
function YouLiPopLayer:UpdatePanelItem(sender,idx)
    local cell = sender:dequeueCell()
    local cellChild=nil
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pContentCell:clone()
        cellChild:setTag(123)
        cellChild:setAnchorPoint(cc.p(0,0))
        cellChild:setPosition(cc.p(0,0))
        cellChild:setVisible(true)
        cell:addChild(cellChild)
        cellChild:setTouchEnabled(false)
        local btn =cellChild:getChildByName("Item"):getChildByName("Btn_youli")

        btn:addClickEventListener(function(sender)
             self:YouLiClicked(sender)     
        end)
    else
        cellChild = cell:getChildByTag(123)
    end
    local btn =cellChild:getChildByName("Item"):getChildByName("Btn_youli")
    btn:setTag(idx+1)
    local data = self.m_Config.getDefByID(idx+1)
    local item = cellChild:getChildByName("Item")
    local nameNode = item:getChildByName("Namebg"):getChildByName("Name")
    nameNode:setString(data.name)
    if data.unlock>LRoleDataMgr.MyHeroInfo.level then   
        self:SetIsLocked(false,item,data,idx+1)
    else
        self:SetIsLocked(true,item,data,idx+1)
    end    
    return cell
end



function YouLiPopLayer:onExit()
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.IsHideBgAndBtn,true)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

-- 查找节点
function YouLiPopLayer:FindNode(str)
    if string.len(str)<1 then
        return
    end
    local nodeName = string.split(str,'.')
    local node = self.m_pUILayer:getChildByName("youliUI")
    for i=1,#nodeName do
        node=node:getChildByName(nodeName[i])     
    end
    if node==nil then
        print("获取node失败")
    end
    return node
end




return YouLiPopLayer