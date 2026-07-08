--[[
lua里面的游戏逻辑控制
]]

-- ----------------------------------------------
-- 常量区
local CsbFilePath = "csd/TeamInviteListLayer.csb"

local SeekHelpUI = LUIBase:New()
SeekHelpUI.__index = SeekHelpUI
--local this = LTcpSocket
function SeekHelpUI:New(type)
	local o = LUIBase:New()
	setmetatable(o,SeekHelpUI)	
    o:Init(type)
	return o
end


--[[
注册事件
]]
function SeekHelpUI:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

function SeekHelpUI:ProcessEvent(msg)
    -- if msg.msgId == LUISocialEvent.updateSeekHelpUI then
   
    -- end
end

function SeekHelpUI:Init(type)

    self.m_pUILayer = cc.CSLoader:createNode(CsbFilePath)
    ccui.Helper:doLayout(self.m_pUILayer)

    self._type = type
    self._isAddBlack = false;

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    self:RegistMsgs()
    self:InitData();
    self:AddTouchEvt();

    self:InitHelperList();

end


function SeekHelpUI:InitData()
    
    LGameMsg.m_baseMsgWithOne:Change(LUISecondClassBgEvent.SetTitle, GUITips.RSI_MONOPOLY_INVALTE)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local listBg = self.m_pUILayer:getChildByName("InviteList")
    self.m_pInvateList = listBg:getChildByName("ListBg")

    self._onLineHelpBtn = listBg:getChildByName("Button1")
    local bangpaiHelpBtn  = listBg:getChildByName("Button2")
    bangpaiHelpBtn:setVisible(false)
    local thirdBtn = listBg:getChildByName("Button3")
    thirdBtn:setVisible(false)

    self.m_pCell = listBg:getChildByName("List1")
    local item = self.m_pCell:getChildByName("Name")
    item:setName("Name_1")
    local item2 = item:clone()
    item2:setName("Name_2")
    self.m_pCell:addChild(item2)
    item2:setPosition(cc.p(item:getContentSize().width, 0))

    self._refrashBtn =  listBg:getChildByName("Btn1")
    self._invateBtn = listBg:getChildByName("Btn2")

end

function SeekHelpUI:AddTouchEvt()
    local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Monopoly.SeekHelpUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end

    LGameMsg.m_baseMsgWithOne:Change(LUISecondClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

-- 一键邀请
    local function OnInvateBtnButtonClick(sender)
        
    end
    self._invateBtn:addClickEventListener(OnInvateBtnButtonClick)
	self:MarkIntaractCObj(self._invateBtn)
    --刷新
    local function OnRefrashBtnButtonClick(sender)

    end
    self._refrashBtn:addClickEventListener(OnRefrashBtnButtonClick)
	self:MarkIntaractCObj(self._refrashBtn)

end

function SeekHelpUI:InitHelperList()

    --print("SeekHelpUI: InitAddfriendList =")

    local tableView = cc.TableView:create(self.m_pInvateList:getContentSize())
    --print("width = ".. self.m_pInvateList:getContentSize().width .. "height = " .. self.m_pInvateList:getContentSize().height);
    --print("width = ".. tableView:getContentSize().width .. "height = " .. tableView:getContentSize().height);
    tableView:setContentSize(self.m_pInvateList:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(cc.p(0, 0))
    tableView:setPosition(self.m_pInvateList:getPosition())
    tableView:setDelegate()
    tableView:setSwallowsTouches(true)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.m_pInvateList:addChild(tableView)

    local function tableCellTouched(sender,cell)
        --print("tableCellTouched".. cell:getIdx())
        self:InvateTableCellTouched(cell)
    end

    local function cellSizeForTable(sender,idx)
        local width = self.m_pCell:getContentSize().width
        local height = self.m_pCell:getContentSize().height
        --print("cellSizeForTable width = "..width .. " cellSizeForTable height = ",height)
        return width, height
    end

    local function tableCellAtIndex(sender, idx)
        --print("cellSizeForTable idx = ".. idx )
        return self:InvateTableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        local num = 0
        if #self._invateList % 2 == 0 then
            num = #self._invateList / 2
        else
            num = math.floor(#self._invateList / 2) + 1 
        end

        return num
    end

    local function scrollViewDisScroll(view)
        self.m_isDragging = view:isDragging()
    end

    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量

    tableView:registerScriptHandler(scrollViewDisScroll, cc.SCROLLVIEW_SCRIPT_SCROLL)
    --tableView:reloadData()
    self.m_pInvateTableView = tableView

    --print("SeekHelpUI:InitAddfriendList")
end

--点击选中处理
function SeekHelpUI:InvateTableCellTouched(cell)
    
    local ind = cell:getIdx()
    local cellChild = cell:getChildByTag(123)
    --print("tableview touched " ..ind.." ") 
end 


function SeekHelpUI:InvateTableCellAtIndex(sender, idx)

    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cell:addChild(cellChild)
    else
        cellChild = cell:getChildByTag(123)

    end
    --print("cell idx"..idx)
    self:ShowInvateCellInfo(cellChild, idx)
    return cell
end

function SeekHelpUI:ShowInvateCellInfo(cellChild, idx)

    local function addfriendTouched(sender)
        if self.m_isDragging then
            return
        end
        local ind = sender:getTag()
    end

    --print("cell idx = ", idx)
    if cellChild ~= nil then
        for i=1,2 do
            --print("self._invateList size = ", #self._invateList)
            local index = idx*2+i
            --print("self._invateList index =", index)
            if(index > #self._invateList) then
                cellChild:getChildByName("Name_2"):setVisible(false)
                return;
            end
       
            local invateCell = cellChild:getChildByName("Name_"..i)
            cellChild:setSwallowTouches(false)
            invateCell:setSwallowTouches(false)
            --实现选中状态
            local invateBtn = invateCell:getChildByName("Button")
            invateBtn:setBright(true)
            invateBtn:setSwallowTouches(false)
            
            local icon = invateBtn:getChildByName("Icon")
            local level = invateBtn:getChildByName("LevelNum")
            local roleSign  = invateBtn:getChildByName("Image_132") 

            local roleName = invateBtn:getChildByName("RoleName")
            local power = invateBtn:getChildByName("zhanli")
            
            invateBtn:setTag(index)
            invateBtn:addClickEventListener(addfriendTouched)

			self:MarkIntaractCObj(invateBtn)
        end
    end
end

function SeekHelpUI:onExit()
    self.m_pUILayer = nil
    self._invateList = nil
    self.m_pInvateTableView = nil
    self.m_pCell = nil
    self.m_pInvateList = nil
    self:Destory()
end

function SeekHelpUI:updateView(list)
    self._invateList = list;
    self._isAddBlack = false; 
    self.m_pInvateTableView:reloadData()
    --print("*****************************update lsit", #list)
end


return SeekHelpUI
