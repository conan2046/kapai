local FishUserListDelegate = LUIBase:New()
FishUserListDelegate.__index = FishUserListDelegate

local init_count = 20

function FishUserListDelegate:New(uiRoot)
    local o = {}
    setmetatable(o,FishUserListDelegate)  
    o:Init(uiRoot)
    return o
end

--[[
注册UI消息
]]
function FishUserListDelegate:RegistMsgs()
    self.msgIds = 
    {
        LUIFishEvent.LoadUserList,
        LUIFishEvent.UpdateUserList,
    }
    self:RegistSelf(self,self.msgIds)
end

function FishUserListDelegate:ProcessEvent(msg)
    if msg.msgId == LUIFishEvent.LoadUserList then
        --dump(msg.value)
        self:LoadData(msg.value)
    elseif msg.msgId == LUIFishEvent.UpdateUserList then
        local isAdd = msg.value[1]
        local id = msg.value[2]
        local name = msg.value[3]
        --dump(msg.value)
        if isAdd then
            self:addOtherList(id, name)
        else
            self:removeOtherList(id)
        end
    end
end

function FishUserListDelegate:Init(uiRoot)
    self.m_tweening = 1--0:ing 1:In 2:Out
    self.m_viewSize = AppDef.frameSize
    self.m_pRootPanel = nil
    self.m_pLockBtn = nil
    ----------------------------------------------------
    self.m_init = false
    ----------------------------------------------------
    self.m_tableCount = 0
    self.m_isDragging = false
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_pTablePanel = nil
    self.m_datas = nil
    ----------------------------------------------------
    self:InitData()
    self:RegistMsgs()
    self:InitViewSize(uiRoot)
    self:InitUIControl()
    self:setIn()
    LuaNetSendMsg:QueryFishingInfo(3)
end

function FishUserListDelegate:InitUIControl()
    if self.m_pUILayer == nil then
        return
    end
    --------------------------------------------------------
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    --------------------------------------------------------
    local pRootUI = self.m_pUILayer
    --------------------------------------------------------
    local pLockBtn = pRootUI:getChildByName("btn_Locker")
    pLockBtn:setVisible(false)
    self.m_pLockBtn = pLockBtn
    pLockBtn:addClickEventListener(function(sender)
        if self.m_tweening == 1 then
            self:tweenOut()
        elseif self.m_tweening == 2 then
            self:tweenIn()
        end
    end)
	self:MarkIntaractCObj(pLockBtn)
    --------------------------------------------------------
    local pPanel = pRootUI:getChildByName("Panel")
    pPanel:setVisible(false)
    self.m_pRootPanel = pPanel
    --------------------------------------------------------
    self.m_pTablePanel = pPanel:getChildByName("ListView")
    self.m_pGridCell = pPanel:getChildByName("Item_Team")
    self.m_pGridCell:setVisible(false)
    self.m_pGridCell:setTouchEnabled(false)
    self.m_pGridCellSize = self.m_pGridCell:getContentSize()
    self.m_pTableView = self:InitTableView(self.m_pTablePanel)
end

function FishUserListDelegate:InitViewSize(uiRoot)
    self.m_pUILayer = uiRoot
end

function FishUserListDelegate:onExit()
    self:Destory()
    self.m_tweening = nil
    self.m_viewSize = nil
    self.m_pRootPanel = nil
    self.m_pLockBtn = nil
    self.m_init = nil
    self.m_tableCount = nil
    self.m_isDragging = nil
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_pTablePanel = nil
    self.m_datas = nil
end

function FishUserListDelegate:InitData()
end

function FishUserListDelegate:cellSizeForTable(sender,idx)
    return self.m_pGridCellSize.width, self.m_pGridCellSize.height
end

function FishUserListDelegate:InitTableView(tbPanel)
    local cfg = {}
    cfg.tbPanel = tbPanel
    cfg.cellSizeForTable = function(sender,idx)
        return self:cellSizeForTable(sender, idx)
    end
    cfg.tableCellAtIndex = function(sender, idx)
        return self:TableCellAtIndex(sender, idx)
    end

    cfg.numberOfCellsInTableView = function() 
        return self.m_tableCount
    end

    cfg.scrollViewDidScroll = function(view)
        self.m_isDragging = view:isDragging()
    end

    cfg.tableCellTouched = function(sender, cell)
        self:TableCellTouched(cell:getIdx())
    end

    return Utils:createTableView(cfg)
end

function FishUserListDelegate:TableCellTouched(idx)
    if self.m_isDragging or idx >= #self.m_datas then
        return
    end
    local info = self.m_datas[idx + 1]
    if info == nil then
        return
    end
    local isMe = LRoleDataMgr.MyHeroInfo:IsMe(info.id)

    Utils:SendMsg(LUIFishEvent.ShowFishBasket, {isMe, info})
end

function FishUserListDelegate:TableCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild = nil
    
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pGridCell:clone()
        cellChild:setTag(123)
        cellChild:setAnchorPoint(cc.p(0, 0))
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cell:addChild(cellChild)
    else
        cellChild = cell:getChildByTag(123)
    end
    if cellChild ~= nil then
        self:updateItem(cellChild, self.m_datas[idx+1], idx+1)
    end
    return cell
end

function FishUserListDelegate:updateItem(cell, info, idx)
    local pHeadBg = cell:getChildByName("bg_Head")
    local pIcon = pHeadBg:getChildByName("Icon")
    local pName = cell:getChildByName("Name")

    if idx > #self.m_datas then--无人
        ------------------------------------------------------
        pName:setString(GUITips.RSI_FISH_TIP3)
        pName:setTextColor(cc.c4b(0xff, 0xff, 0xff, 0xff))
        ------------------------------------------------------
        pIcon:loadTexture("res/UI/ui_common/ui_wenhao_00.png", UI_TEX_TYPE_PLIST)
    else--有人
        local info = self.m_datas[idx]
        ------------------------------------------------------
        pName:setString(info.name)
        if LRoleDataMgr.MyHeroInfo:IsMe(info.id) then
            pName:setTextColor(cc.c4b(0xdc, 0xab, 0, 0xff))
        else
            pName:setTextColor(cc.c4b(0xff, 0xff, 0xff, 0xff))
        end
        ------------------------------------------------------
        pIcon:loadTexture("res/UI/ui_wanfa/ui_icon_yulou_01.png", UI_TEX_TYPE_PLIST)
    end
end

function FishUserListDelegate:LoadData(list)
    if self.m_pTableView then
        Utils:FreeTable(self.m_datas)
        self.m_datas = nil
        self.m_datas = list
        self.m_tableCount = math.max(#list, init_count)
        local offset = nil
        if self.m_init then
            offset = self.m_pTableView:getContentOffset()
        end
        self.m_pTableView:reloadData()
        if self.m_init and offset then
            self.m_pTableView:setContentOffset(offset)
        end
        self.m_init = true
    end
end

function FishUserListDelegate:tweenIn()
    if self.m_tweening == 0 or self.m_pRootPanel == nil then
        return
    end
    self.m_tweening = 0
    self.m_pRootPanel:stopAllActions()
    local cfg = {}
    table.insert(cfg, cc.MoveTo:create(0.2, cc.p(self.m_viewSize.width, self.m_pRootPanel:getPositionY())))
    table.insert(cfg, cc.CallFunc:create(handler(self, FishUserListDelegate.setIn)))
    self.m_pRootPanel:runAction(cc.Sequence:create(cfg))
end

function FishUserListDelegate:tweenOut()
    if self.m_tweening == 0 or self.m_pRootPanel == nil then
        return
    end
    self.m_tweening = 0
    self.m_pRootPanel:stopAllActions()
    local cfg = {}
    table.insert(cfg, cc.MoveTo:create(0.2, cc.p(self.m_viewSize.width+self.m_pRootPanel:getContentSize().width, self.m_pRootPanel:getPositionY())))
    table.insert(cfg, cc.CallFunc:create(handler(self, FishUserListDelegate.setOut)))
    self.m_pRootPanel:runAction(cc.Sequence:create(cfg))
end

function FishUserListDelegate:setIn()
    self.m_tweening = 1
    self.m_pLockBtn:setScaleX(1)
    self.m_pLockBtn:setVisible(true)
    self.m_pRootPanel:setVisible(true)
end

function FishUserListDelegate:setOut()
    self.m_tweening = 2
    self.m_pLockBtn:setScaleX(-1)
    self.m_pLockBtn:setVisible(true)
    self.m_pRootPanel:setVisible(false)
end

function FishUserListDelegate:pushOtherList(id, name)
    if self.m_datas then
        table.insert(self.m_datas, {id=id, name=name})
    end
end

function FishUserListDelegate:addOtherList(id, name)
    self:pushOtherList(id, name)
    if self.m_pTableView and self.m_datas then
        if #self.m_datas > self.m_tableCount then
            self.m_tableCount = #self.m_datas
            local offset = self.m_pTableView:getContentOffset()
            local _, height = self:cellSizeForTable()
            self.m_pTableView:reloadData()
            self.m_pTableView:setContentOffset(cc.p(offset.x, offset.y-height))
        else
            self.m_pTableView:updateCellAtIndex(#self.m_datas - 1)
        end
    end
end

function FishUserListDelegate:popOtherList(id)
    if self.m_datas == nil then
        return nil
    end
    for i=1,#self.m_datas do
        if self.m_datas[i].id == id then
            table.remove(self.m_datas, i)
            return i
        end
    end
    return nil
end

function FishUserListDelegate:removeOtherList(id)
    local idx = self:popOtherList(id)
    if idx then
        if self.m_pTableView == nil then
            return
        end
        local dataCount = #self.m_datas
        self.m_tableCount = math.max(dataCount, init_count)
        
        if dataCount >= init_count  then
            local offset = self.m_pTableView:getContentOffset()
            self.m_pTableView:reloadData()
            local min = self.m_pTableView:minContainerOffset().y
            local max = self.m_pTableView:maxContainerOffset().y
            local _, height = self:cellSizeForTable()
            offset.y = math.max(math.min(offset.y+height, max), min)
            self.m_pTableView:setContentOffset(offset)
        else
            self.m_pTableView:reloadData()
        end
    end
end

return FishUserListDelegate