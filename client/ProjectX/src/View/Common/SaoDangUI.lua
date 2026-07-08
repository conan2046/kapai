local SaoDangUI = LUIBase:New()
SaoDangUI.__index = SaoDangUI

SaoDangUI.IsHideInBattle = true

function SaoDangUI:New(data)
    local o = {}
    setmetatable(o, SaoDangUI)
    o:Init(data)
    return o
end

function SaoDangUI:Init(data)
	self._datas = data
	self:InitViewSize()
	self:InUIControl()
end

function SaoDangUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/common/saodang.csb")
	self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

	self.m_timeline = cc.CSLoader:createTimeline("csd/common/saodang.csb")
    self.m_pUILayer:runAction(self.m_timeline)
	self.m_timeline:gotoFrameAndPlay(0, false)
	local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

function SaoDangUI:InUIControl()
	local Panel = self.m_pUILayer:getChildByName("saodangchenggong")
    self._tableView = Panel:getChildByName("TableView")
	local function closeCallback(sender)
        self:CloseUI()
    end
    Panel:addClickEventListener(closeCallback)
	self:MarkIntaractCObj(Panel)

	local cell = Panel:getChildByName("ItemList")

	local listView = ccui.ListView:create()
    listView:setDirection(LISTVIEW_DIR_VERTICAL)
    listView:setPosition(cc.p(0, 0))
    listView:setAnchorPoint(cc.p(0, 0))
    listView:setContentSize(self._tableView:getContentSize())
    -- 关闭惯性滑动
    listView:setBounceEnabled(true)
    listView:setSwallowTouches(false)
    -- 设置间距
    listView:setItemsMargin(2)
    -- 隐藏滚动条
    listView:setScrollBarEnabled(false)
    
    self._tableView:addChild(listView)
	local size
    if #self._datas % 2 == 0 then
        size = #self._datas / 2 
    else
        size = #self._datas / 2 + 1
    end
    for i=1, size do
        local item = cell:clone()
        listView:pushBackCustomItem(item)
        for j=1, 7 do
            local index = (i - 1) * 7 + j
            local taskBtn = item:getChildByName("itemlayer_"..j)
            self:updateItem(taskBtn, index)
        end
    end
end

function SaoDangUI:updateItem( singleItem, index )
	if index > #self._datas then
        singleItem:setVisible(false)
        return
    end
	singleItem:setVisible(true)
	local data = self._datas[index]
	local _icon = singleItem:getChildByName("item")
	local _name = singleItem:getChildByName("Name")
	local name = Utils:getItemNameByID(data[1],data[2])
	_name:setString(name)
	Utils:ShowItemByConfigData(data, _icon, nil, true, true)
end

function SaoDangUI:CloseUI()
	LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Common.SaoDangUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
end

function SaoDangUI:onExit()
	self.m_pUILayer = nil
    self:Destory()
end

return SaoDangUI