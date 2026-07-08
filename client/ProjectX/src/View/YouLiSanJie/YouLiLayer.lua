local YouLiLayer = LUIBase:New()
YouLiLayer.__index = YouLiLayer
function YouLiLayer:New()
    local o = LUIBase:New()
    setmetatable(o,YouLiLayer)  
    o:Init()
    return o
end
--[[
注册消息
]]
function YouLiLayer:RegistMsgs()
    self.msgIds = 
    {
        LUILogicEvent.InitUI,      
    }
    self:RegistSelf(self,self.msgIds)
end

function YouLiLayer:ProcessEvent(msg)
   
end
function YouLiLayer:Init()

    self:RegistMsgs()
    self.m_pUILayer = cc.CSLoader:createNode("csd/youli/youlisanjie.csb")
    ccui.Helper:doLayout(self.m_pUILayer)
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitVariable()
    self:InitData()
    self:AddTouchEvt()
    self:InitMianListView()
    self:UpdateHelpTime()
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.IsHideBgAndBtn,false)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback,function ()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "YouLiSanJie.YouLiLayer")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
	Utils:SendMsg(LUIFClassBgEvent.HelpBtn,AppDef.FCBHelp.YouLiSanJie)
end
function YouLiLayer:InitVariable()
    self.m_Config=JsonConfig.m_SanJieConfig
    self.YouData=LRoleDataMgr.MyHeroInfo.YouLi
end
function YouLiLayer:InitData()
    self.m_pContentCell=self:FindNode("Item")
    self.m_pHelpTimes=self:FindNode("xiezhuBg.Value")
    self.m_pOneClickYL=self:FindNode("Btn_youli")
    self.m_pOneClickLQ=self:FindNode("Btn_lingqu")
    self.m_pMineItem=self:FindNode("Panel.Head")
    self.m_pOtherItem=self:FindNode("Panel.Item")
    self.m_pOtherItemList=self:FindNode("Panel.List")
    self.m_pOtherLeftBtn=self:FindNode("Panel.Button_L")
    self.m_pOtherRightBtn=self:FindNode("Panel.Button_R")
end 
function YouLiLayer:AddTouchEvt()
    self.m_pOneClickYL:addClickEventListener(function(sender)
        self:m_pOneClickYLClicked(sender)     
    end)
    self.m_pOneClickYL:addClickEventListener(function(sender)
        self:OneClickLQClicked(sender)     
    end)

end
-- 一键游历
function YouLiLayer:OneClickYLClicked(sender)
 
end


-- 一键领取
function YouLiLayer:OneClickLQClicked(sender)
 
end

-- 游历
function YouLiLayer:YouLiClicked(sender)
    print(sender:getTag())
    
end

function YouLiLayer:InitMianListView()
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
function YouLiLayer:UpdatePanelItem(sender,idx)
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
function YouLiLayer:SetIsLocked(isLock,node,data,ind)
    local lock = node:getChildByName("Lock")
    local finish = node:getChildByName("Text_1")
    local doing = node:getChildByName("Text_2")
    local timeBg = node:getChildByName("TimeBg")
    local btn_YouLi = node:getChildByName("Btn_youli")
    local lockCon =lock:getChildByName("Condition")
  --  print("YouLiLayer:SetIsLocked(isLock,node,data)",isLock)
    lock:setVisible(isLock)  
    finish:setVisible(not isLock)
    doing:setVisible(not isLock)
    timeBg:setVisible(not isLock)
    if isLock==true then
        lockCon:setString(string.format(GUITips.RSI_YOULI_CONDITION,data.unlock)) 
        return   
    end
    local state =self:CheckYouLiState(ind) 
    if state==0 then
        btn_YouLi:setVisible(true)
        finish:setVisible(false)
        doing:setVisible(false)
        timeBg:setVisible(false)
    elseif state==1 then
        btn_YouLi:setVisible(false)
        finish:setVisible(false)
        doing:setVisible(true)
        timeBg:setVisible(true)
        self:SetLeftTime(timeBg,ind)
    
    elseif state==2 then
        btn_YouLi:setVisible(false)
        finish:setVisible(true)
        doing:setVisible(false)
        timeBg:setVisible(false)
    end   
end
-- 0 没有游历 1 正在游历中  2 游历完成
function YouLiLayer:CheckYouLiState(ind)
    return self.YouData:GetState(ind)
end
-- 剩余时间
function YouLiLayer:SetLeftTime(node,ind)
    local time = node:getChildByName("Time")
    time:setString(self.YouData:GetTimeLeft(ind))
   
end
-- 帮助次数
function YouLiLayer:UpdateHelpTime()
    local times = self:FindNode("xiezhuBg.Value")
    times:setString(self.YouData.HelpTiems.."/10")
end
function YouLiLayer:PanelItemClicked(cell)
    
end

function YouLiLayer:UpdateMineItem()

end
function YouLiLayer:UpdateOtherItem(node)
   
end
function YouLiLayer:onExit()
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.IsHideBgAndBtn,true)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end



 



-- 查找节点
function YouLiLayer:FindNode(str)
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




return YouLiLayer