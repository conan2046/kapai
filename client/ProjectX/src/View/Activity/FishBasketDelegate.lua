local FishBasketDelegate = LUIBase:New()
FishBasketDelegate.__index = FishBasketDelegate


local init_count = 4

function FishBasketDelegate:New(uiRoot)
    local o = {}
    setmetatable(o,FishBasketDelegate)  
    o:Init(uiRoot)
    return o
end

--[[
注册UI消息
]]
function FishBasketDelegate:RegistMsgs()
    self.msgIds = 
    {
        LUIFishEvent.ShowFishBasket,
        LUIFishEvent.LoadFishBasketList,
    }
    self:RegistSelf(self,self.msgIds)
end

function FishBasketDelegate:ProcessEvent(msg)
    if msg.msgId == LUIFishEvent.ShowFishBasket then
        self:UpdateData(msg.value)
    elseif msg.msgId == LUIFishEvent.LoadFishBasketList then
        if self.m_pUILayer and not self.m_pUILayer:isVisible() then
            return
        end
        local isMe = msg.value[1]
        local list = msg.value[2]
        self.m_isMySelf = nil
        self.m_isMySelf = isMe
        self:updateButton()
        self:adjustHeroName()
        self:LoadListData(list)
    end
end

function FishBasketDelegate:Init(uiRoot)
    self.m_HeroIDNum = 0
    self.m_HeroNamecpy = nil
    self.m_nameLabel = nil
    self.m_isMySelf = true
    ----------------------------------------------------
    self.m_tableCount = 0
    self.m_isDragging = false
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_pTablePanel = nil
    self.m_datas = nil
    self.m_pGridCellSize = nil
    self.m_selected = 0
    ----------------------------------------------------
    self:RegistMsgs()
    self:InitViewSize(uiRoot)
    self:InitUIControl()
end

function FishBasketDelegate:InitUIControl()
    if self.m_pUILayer == nil then
        return
    end
    ---------------------------------------------------
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    ---------------------------------------------------
    local pRootUI = self.m_pUILayer
    pRootUI:setVisible(false)
    ---------------------------------------------------
    self.m_nameLabel = pRootUI:getChildByName("Title")
    ---------------------------------------------------
    local pBtnClose = pRootUI:getChildByName("btn_Close")
    pBtnClose:addClickEventListener(handler(self, FishBasketDelegate.Close))
	self:MarkIntaractCObj(pBtnClose)
    ---------------------------------------------------
    self.m_pTablePanel = pRootUI:getChildByName("ListView")
    self.m_pGridCell = pRootUI:getChildByName("Item")
    self.m_pGridCell:setVisible(false)
    self.m_pGridCell:setTouchEnabled(false)
    self.m_pGridCellSize = self.m_pGridCell:getContentSize()
    self.m_pTableView = self:InitTableView(self.m_pTablePanel)
    ---------------------------------------------------
    local pBtnGet = pRootUI:getChildByName("btn_shouhuo")
    pBtnGet:addClickEventListener(handler(self, FishBasketDelegate.GetButtonClick))
	self:MarkIntaractCObj(pBtnGet)
    self.m_pBtnText = pBtnGet:getChildByName("Text")
    ---------------------------------------------------
end

function FishBasketDelegate:InitViewSize(uiRoot)
    self.m_pUILayer = uiRoot
end

function FishBasketDelegate:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_nameLabel = nil
    self.m_pGridCell = nil
    self.m_pGridCellSize = nil
    self.m_HeroIDNum = nil
    self.m_HeroNamecpy = nil
    self.m_isMySelf = nil
    ----------------------------------------------------
    self.m_tableCount = nil
    self.m_isDragging = nil
    self.m_pTableView = nil
    self.m_pTablePanel = nil
    self.m_datas = nil
    self.m_selected = nil
    self.m_pBtnText = nil
end

function FishBasketDelegate:Close(sender)
    if self.m_pUILayer then
        self.m_pUILayer:setVisible(false)
    end
end

function FishBasketDelegate:Show()
    if self.m_pUILayer then
        self.m_pUILayer:setVisible(true)
    end
end


function FishBasketDelegate:UpdateData(msg)
    local isMe = msg[1]
    local info = msg[2]
    self.m_isMySelf = nil
    self.m_isMySelf = isMe
    if isMe then
        LuaNetSendMsg:QueryFishingInfo(4, LRoleDataMgr.MyHeroInfo.id)
    elseif info then
        self:setHeroID(info.id, info.name)
        LuaNetSendMsg:QueryFishingInfo(4, info.id)
    end
    self:updateButton()
    self:Show()
end

function FishBasketDelegate:setHeroID(id, name)
    self.m_HeroIDNum = nil
    self.m_HeroNamecpy = nil
    self.m_HeroIDNum = id
    self.m_HeroNamecpy = name
    self:adjustHeroName()
end

function FishBasketDelegate:adjustHeroName()
    if self.m_nameLabel == nil then
        return
    end
    if self.m_isMySelf then
        self.m_nameLabel:setString(GUITips.RSI_FISH_TIP4)
    else
        self.m_nameLabel:setString(string.format("【%s】", self.m_HeroNamecpy))
    end
end

function FishBasketDelegate:cellSizeForTable(sender,idx)
    return self.m_pGridCellSize.width, self.m_pGridCellSize.height
end

function FishBasketDelegate:InitTableView(tbPanel)
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

function FishBasketDelegate:TableCellTouched(idx)
    if self.m_isDragging then
        return
    end
    self.m_selected = idx + 1
    performWithDelay(self.m_pUILayer, function(sender)
        local offset = self.m_pTableView:getContentOffset()
        self.m_pTableView:reloadData()
        self.m_pTableView:setContentOffset(offset)
    end, 0)
end

function FishBasketDelegate:TableCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild = nil
    
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pGridCell:clone()
        cellChild:setTag(123)
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

function FishBasketDelegate:updateItem(cell, info, idx)
    local name = ""
    ----------------------------------------------------
    local pChoose = cell:getChildByName("Choose")
    pChoose:setVisible(idx == self.m_selected)
    ----------------------------------------------------
    local pIconBg = cell:getChildByName("bg_Icon")
    ----------------------------------------------------
    local pIcon = pIconBg:getChildByName("Icon")
    if idx <= #self.m_datas then
        local fishId = self.m_datas[idx]
        if fishId == 580 then
            name = GUITips.RSI_FISH_TIP5
        elseif fishId == 581 then
            name = GUITips.RSI_FISH_TIP6
        elseif fishId == 582 then
            name = GUITips.RSI_FISH_TIP7
        end
        pIcon:loadTexture(string.format(AppDef.GUIRes.Res_Item_Path, fishId), UI_TEX_TYPE_LOCAL)
    else
        name = GUITips.RSI_FISH_TIP8
        pIcon:loadTexture("res/UI/ui_common/ui_wenhao_00.png", UI_TEX_TYPE_PLIST)
    end
    ----------------------------------------------------
    -- local pNum = pIconBg:getChildByName("Value")
    ----------------------------------------------------
    local pName = cell:getChildByName("Name")
    pName:setString(name)
    ----------------------------------------------------
end

function FishBasketDelegate:updateButton()
    if self.m_pBtnText then
        self.m_pBtnText:setString(self.m_isMySelf and GUITips.RSI_FISH_TIP9 or GUITips.RSI_FISH_TIP10)
    end
end

function FishBasketDelegate:GetButtonClick(sender)
    if self.m_datas == nil then
        return
    end
    if self.m_selected > #self.m_datas then
        Utils:ShowScrollTips(self.m_isMySelf and GUITips.RSI_FISH_TIP12 or GUITips.RSI_FISH_TIP11)
        return
    end
    if self.m_isMySelf then
        LuaNetSendMsg:QueryFishingInfo(6, self.m_selected-1)
    else
        LuaNetSendMsg:QueryFishingInfo(7, self.m_HeroIDNum, self.m_selected-1)
        self:Close()
    end
end

function FishBasketDelegate:LoadListData(list)
    Utils:FreeTable(self.m_datas)
    self.m_datas = nil
    self.m_datas = list
    self.m_selected = 1
    self.m_tableCount = init_count
    if self.m_pTableView ~= nil then
        self.m_pTableView:reloadData()
    end
end


return FishBasketDelegate