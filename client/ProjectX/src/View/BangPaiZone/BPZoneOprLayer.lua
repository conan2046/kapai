local BPZoneOprLayer = LUIBase:New()
BPZoneOprLayer.__index = BPZoneOprLayer

-- -----------------------------------
function BPZoneOprLayer:New()
    local o = {}
    setmetatable(o, BPZoneOprLayer)
    o:Init()
    return o
end

-- -----------------------------------
function BPZoneOprLayer:Init()
    self.m_pPlantList = nil
    if self.m_pPlantListItem then
        self.m_pPlantListItem:release()
        self.m_pPlantListItem = nil
    end
    self.pPlantListBg = nil

    self.m_strategy = nil

    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    self:Close()
end

function BPZoneOprLayer:setStrategy(strategy)
    if self.m_strategy and self.m_strategy.onExit then
        self.m_strategy:onExit()
        self.m_strategy = nil
    end
    self.m_strategy = strategy
    self:Reset()
end

function BPZoneOprLayer:RegistMsgs()
    self.msgIds = 
    {
        LUIBangPaiEvent.CloseFactionZoneOpLayer,
        LUIBangPaiEvent.UpdateRobButton,
        LUIBangPaiEvent.PlantResultEvent,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function BPZoneOprLayer:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_pPlantList = nil
    self.pPlantListBg = nil

    if self.m_pPlantListItem ~= nil then
        self.m_pPlantListItem:release()
        self.m_pPlantListItem = nil
    end
    if self.m_strategy and self.m_strategy.onExit then
        self.m_strategy:onExit()
        self.m_strategy = nil
    end
end

function BPZoneOprLayer:ProcessEvent(msg)
    if msg.msgId == LUIBangPaiEvent.CloseFactionZoneOpLayer then
        if msg.value then
            self:Close()
        else
            self:Reset()
        end
    elseif msg.msgId == LUIBangPaiEvent.UpdateRobButton then
        self.m_strategy:SetRobBtnEnabled(self.m_pPlantList, msg.value)
        self:Reset()
    elseif msg.msgId == LUIBangPaiEvent.PlantResultEvent then
        if self.m_strategy then
            self:SetData(self.m_strategy.m_index - 1, msg.value)
        end
    end
end

-----------------------------------
function BPZoneOprLayer:InitUIControl()
    local pPanel = self.m_pUILayer:getChildByName("Panel")
    pPanel:setTouchEnabled(true)
    pPanel:setSwallowTouches(false)
    pPanel:addClickEventListener(function(sender)
        self.m_strategy:onClose()
        self:Close()
    end)
	self:MarkIntaractCObj(pPanel)

    self.pPlantListBg = pPanel:getChildByName("PlantListBg")
    self.m_pPlantList = pPanel:getChildByName("PlantList")
    self.m_pPlantList:setScrollBarEnabled(false)
    self.m_pPlantListItem = pPanel:getChildByName("IconBg")
    self.m_pPlantListItem:retain()
    self.m_pPlantListItem:removeFromParent(false)
end

function BPZoneOprLayer:setListBgVisible()
    self.pPlantListBg:setVisible(self.m_strategy and self.m_strategy:ShowListBg())
    if self.pPlantListBg:isVisible() then
        self.pPlantListBg:setTouchEnabled(true)
        self.pPlantListBg:setSwallowTouches(true)
        self.pPlantListBg:setOpacity(0)
        self.pPlantListBg:addClickEventListener(function(sender)
            if self.pPlantListBg:getOpacity() == 0 then
                self:showBg()
            end
        end)
		self:MarkIntaractCObj(self.pPlantListBg)
    end
    self.m_pPlantList:setSwallowTouches(not self.pPlantListBg:isVisible())
end

function BPZoneOprLayer:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

-----------------------------------
function BPZoneOprLayer:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/PlantListLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

function BPZoneOprLayer:SetData(index, opr)
    if not self.m_strategy:SetData(index, opr) then
        self.m_strategy:onClose()
        self:Close()
        return
    end

    if not self.m_strategy:initData() then
        self.m_strategy:onClose()
        self:Close()
        return 
    end
    self:initList()
    self:Reset()
end

function BPZoneOprLayer:Close()
    self.m_pUILayer:setVisible(false)
    if self.m_strategy then
        self.m_strategy:onClose()
    end
end

function BPZoneOprLayer:initList()
    if not self.m_strategy:checkData() then
        self:Close()
        return
    end
    self.m_pPlantList:removeAllChildren()
    local num = self.m_strategy:getItemCunt()
    local space,lSpace,rSpace = self:updateListSize(num)
    local nodes = {}
    local innerSize = self.m_pPlantList:getInnerContainerSize()
    for i=1,num do
        local cell = self.m_pPlantListItem:clone()
        cell:setPositionY(innerSize.height * cell:getAnchorPoint().y)
        cell:setTag(self.m_strategy:GetCellTag(i))
        cell:setTouchEnabled(true)
        cell:setSwallowTouches(false)
        cell:addClickEventListener(handler(self, BPZoneOprLayer.ChooseCallback))
		self:MarkIntaractCObj(cell)
        if self.m_strategy:GetCellGray(i) then
            cell:setColor(CCGRAY)
        end

        self.m_strategy:updateCell(cell, i)

        local pIcon = cell:getChildByName("Icon")
        self.m_strategy:updateIcon(pIcon, i)
        
        local pName = cell:getChildByName("Name")
        pName:setVisible(false)
        self.m_strategy:updateName(pName, i)

        local pNum = cell:getChildByName("Num")
        pNum:setVisible(false)
        self.m_strategy:updateNum(pNum, i)

        local pCount = cell:getChildByName("Count")
        pCount:setVisible(false)
        self.m_strategy:updateCount(pCount, i)

        self.m_pPlantList:addChild(cell)

        table.insert(nodes, cell)
    end

    local allSize = Utils:AlignNodes(self.m_pPlantList:getInnerContainer(), nodes, {space,lSpace,rSpace}, 3, true)
    local viewSize = self.m_pPlantList:getContentSize()
    if allSize < viewSize.width then
        self.m_pPlantList:setInnerContainerSize(cc.size(viewSize.width, self.m_pPlantList:getInnerContainerSize().height))
        Utils:AlignNodes(self.m_pPlantList:getInnerContainer(), nodes, {space,lSpace,rSpace}, 3)
    end
end

function BPZoneOprLayer:updateListSize(num)
    local lSpace,rSpace = 10,10
    local space = 50
    local size = self.m_pPlantList:getInnerContainerSize()
    local csize = self.m_pPlantListItem:getContentSize()
    local size2 = cc.size(lSpace+(csize.width+space)*(num-1)+csize.width+rSpace, size.height)
    if size2.width <= self.m_pPlantList:getContentSize().width then
        size2.width = self.m_pPlantList:getContentSize().width
    end
    self.m_pPlantList:setInnerContainerSize(size2)
    return space,lSpace,rSpace
end

function BPZoneOprLayer:showBg()
    self.pPlantListBg:setOpacity(0)
    self.pPlantListBg:runAction(cc.FadeIn:create(0.15))
end

function BPZoneOprLayer:Reset()
    self.m_pUILayer:setVisible(true)
    self.pPlantListBg:setOpacity(0)
    if self.m_strategy and self.m_strategy:ShowListBg() then
        self:setListBgVisible()
    end
end

function BPZoneOprLayer:ChooseCallback(sender)
    local index = sender:getTag()
    self.m_strategy:ChooseCallback(index)
    self:Close()
end

return BPZoneOprLayer