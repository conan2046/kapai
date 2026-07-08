local BangPaiListPage = LUIBase:New()
BangPaiListPage.__index = BangPaiListPage


local BangPaiDef = require("View.BangPai.BangPaiDef")

local BTN_APPLY_JOIN = 100
local BTN_CREATE = 101
--local BTN_ENTER = 102

-- -----------------------------------
function BangPaiListPage:New()
    local o = {}
    setmetatable(o, BangPaiListPage)
    o:Init()
    return o
end

-- -----------------------------------
function BangPaiListPage:Init()
    self.Script = "BangPai.BangPaiListPage"
    self.m_tableCount = 0
    self.m_isDragging = false
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_pMyTableCell = nil
    self.m_pTablePanel = nil
    self.m_datas = nil
    self.m_selectIndex = -100
    self.m_pGongGao = nil
    self.m_pSearchTextField = nil
    self.m_buttons = {}

    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()

    LuaNetSendMsg:QueryFactionList()
end

-- -----------------------------------
function BangPaiListPage:onExit()
    self:Destory()
    self.Script = nil
    self.m_pUILayer = nil
    self.m_datas = nil
    self.m_tableCount = nil
    self.m_isDragging = nil
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_pMyTableCell = nil
    self.m_pTablePanel = nil
    self.m_selectIndex = nil
    self.m_pGongGao = nil
    self.m_pSearchTextField = nil
    Utils:FreeTable(self.m_buttons)
    self.m_buttons = nil
end

-- -----------------------------------
function BangPaiListPage:RegistMsgs()
    self.msgIds = 
    {
        LUIBangPaiEvent.ShowBangPaiList,
        LUIBangPaiEvent.UpdateAskJoinBangPai,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function BangPaiListPage:ProcessEvent(msg)
    if msg.msgId == LUIBangPaiEvent.ShowBangPaiList then
        self:ShowBangPaiList(msg.value.list)
    elseif msg.msgId == LUIBangPaiEvent.UpdateAskJoinBangPai then
        self:UpdateAskJoinBangPai(msg.value)
    end
end

-- -----------------------------------
function BangPaiListPage:InitViewSize()
    self:CreateUINode("csd/bangpai/GangsApplyLayer.csb");

    Utils:SendMsg(LUIPopFClassBgEvent.SetTitle, GUITips.RSI_BP_TIP13)
end

function BangPaiListPage:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    Utils:SendMsg(LUIPopFClassBgEvent.SetCloseCallback, handler(self, LUIBase.RemoveUI))
end

-- -----------------------------------
function BangPaiListPage:InitUIControl()
    local panel = self.m_pUILayer:getChildByName("Panel")

    local applyGuild = panel:getChildByName("ApplyGuild")

    local theCharts = applyGuild:getChildByName("TheCharts")

    self.m_pTablePanel = theCharts:getChildByName("List")

    self.m_pGridCell = theCharts:getChildByName("Name")
    self.m_pGridCell:setVisible(false)
    self.m_pGridCell:setTouchEnabled(false)

    self.m_pGongGao = applyGuild:getChildByName("GuildNotice"):getChildByName("Text")

    local function applyCallback(sender)
        self:applyBtnCallback()
    end
    self.m_buttons[BTN_APPLY_JOIN] = applyGuild:getChildByName("Btn1")
    self.m_buttons[BTN_APPLY_JOIN]:addClickEventListener(applyCallback)
	self:MarkIntaractCObj(self.m_buttons[BTN_APPLY_JOIN])
    local function createCallback(sender)
        self:createBtnCallback()
    end
    self.m_buttons[BTN_CREATE] = applyGuild:getChildByName("Btn2")
    self.m_buttons[BTN_CREATE]:addClickEventListener(createCallback)
	self:MarkIntaractCObj(self.m_buttons[BTN_CREATE])
    local function enterCallback(sender)
        self:enterBtnCallback()
    end
    applyGuild:getChildByName("Btn3"):setVisible(false)
 --    self.m_buttons[BTN_ENTER] = applyGuild:getChildByName("Btn3")
 --    self.m_buttons[BTN_ENTER]:addClickEventListener(enterCallback)
	-- self:MarkIntaractCObj(self.m_buttons[BTN_ENTER])
    local pSearchBg = applyGuild:getChildByName("SearchBg")
    self.m_pSearchTextField = pSearchBg:getChildByName("TextField")
    self.m_pSearchTextField:setString("")
    local pSearchBtn = pSearchBg:getChildByName("SearchBtn")
    local function searchCallback(sender)
        self:searchTouchCallback()
    end
    pSearchBtn:addClickEventListener(searchCallback)
	self:MarkIntaractCObj(pSearchBtn)
end

function BangPaiListPage:ShowBangPaiList(list)
    local mybangpaiInfo = LRoleDataMgr.Faction.Info
    local myBangPaiId = mybangpaiInfo.id
    local pScrollViewSize = self.m_pTablePanel:getContentSize()
    if myBangPaiId > 0 then
        local myBangPaiIdx = LRoleDataMgr.Faction:FindFactionInfo(myBangPaiId)

        local viewcell = self.m_pGridCell:clone()
        viewcell:setPosition(cc.p(self.m_pGridCell:getPosition()))
        viewcell:setVisible(true)
        self:updateItem(viewcell, list[myBangPaiIdx], 0, myBangPaiId)

        self.m_pGridCell:getParent():addChild(viewcell)

        self.m_pMyTableCell = viewcell
        --print("viewcell:getContentSize().height",viewcell:getContentSize().height)
        pScrollViewSize.height = pScrollViewSize.height - viewcell:getContentSize().height
        self.m_pTablePanel:setContentSize(pScrollViewSize)

        table.remove(list, myBangPaiIdx)

        self:TableCellTouched(-1)
    end

    if self.m_pTableView ~= nil then
        self.m_pTableView:removeFromParent(true)
        self.m_pTableView = nil
    end
    self.m_pTableView = self:InitTableView(self.m_pTablePanel)

    --TODO:注意顺序
    self.m_datas = list

    self.m_tableCount = #list
    if myBangPaiId <= 0 and #list > 0 then
        self.m_selectIndex = 0
        self:setGongGao(list[1].gongGao)
    end
    self.m_pTableView:reloadData()

    self:setMenuState(myBangPaiId)
end

function BangPaiListPage:InitTableView(tbPanel)
    local cfg = {}
    cfg.tbPanel = tbPanel
    cfg.cellSizeForTable = function(sender,idx)
        local width = self.m_pGridCell:getContentSize().width
        local height = self.m_pGridCell:getContentSize().height
        return width, height
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
        return self:TableCellTouched(cell:getIdx())
    end

    return Utils:createTableView(cfg)
end

function BangPaiListPage:TableCellTouched(idx)
    if idx == self.m_selectIndex then
        return
    end

    self.m_selectIndex = idx

    if idx == -1 and self.m_pMyTableCell ~= nil then
        self:setSelect(self.m_pMyTableCell, true)
        self:setGongGao(LRoleDataMgr.Faction.Info.gongGao)
    else
        self:setSelect(self.m_pMyTableCell, false)
        self:setGongGao((self.m_datas[idx+1] and {self.m_datas[idx+1].gongGao} or {""})[1])
    end

    if self.m_pTableView ~= nil then
        local offset = self.m_pTableView:getContentOffset()
        self.m_pTableView:reloadData()
        self.m_pTableView:setContentOffset(offset)
    end
end

function BangPaiListPage:TableCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild = nil
    
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pGridCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)
    else
        cellChild = cell:getChildByTag(123)
    end
    if cellChild ~= nil then
        self:updateItem(cellChild, self.m_datas[idx+1], idx, LRoleDataMgr.Faction.Info.id)
    end
    return cell
end

function BangPaiListPage:updateItem(cell, info, idx, myBangPaiId)
    print("updateItem",cell, info, idx, myBangPaiId)
    local bMyItem = (myBangPaiId==info.id)
    local color = bMyItem and cc.c4b(0,255,0,255) or cc.c4b(110,56,48,255)
    self:setSelect(cell, self.m_selectIndex == idx)

    local bShowBg = false
    if myBangPaiId > 0 then
        bShowBg = (not bMyItem) and (math.fmod(idx, 2) == 0)
    else
        bShowBg = math.fmod(idx, 2) == 1
    end
    if info.lvLimit == 0 then
        cell:findChildByName("AddLv"):setString(GUITips.SI_BP_TIP63)
    else
        cell:findChildByName("AddLv"):setString(info.lvLimit)
    end
    

    local bgSp = cell:getChildByName("Bg")
    bgSp:setVisible(bShowBg)

    local pPlaceNum = cell:getChildByName("PlaceNum")
    pPlaceNum:setString(tostring(info.level))
    pPlaceNum:setTextColor(color)

    local pPlaceName = cell:getChildByName("PlaceName")
    pPlaceName:setString(info.name)
    pPlaceName:setTextColor(color)

    local pPeopleNum = cell:getChildByName("PeopleNum")
    pPeopleNum:setString(string.format("%d/%d", info.memberNum,info.MaxMemberNum))
    pPeopleNum:setTextColor(color)

    local pPlantNum = cell:getChildByName("PlantNum")
    pPlantNum:setString(tostring(info.plantNum))
    pPlantNum:setTextColor(color)

    local pLeaderName = cell:getChildByName("LeaderName")
    pLeaderName:setString(info.bangZhuName)
    pLeaderName:setTextColor(color)

    local pShenqingSp = cell:getChildByName("AppliedImage")
    if pShenqingSp ~= nil then
        pShenqingSp:setVisible(myBangPaiId == 0 and info.isInAskJoin == 1)
    end

    if bMyItem then
        local function myCellTouched(sender)
            self:TableCellTouched(-1)
        end
        cell:setTouchEnabled(true)
        cell:addClickEventListener(myCellTouched)
		self:MarkIntaractCObj(cell)
    end
end

function BangPaiListPage:setSelect(cell, bSelected)
    if cell == nil then
        return
    end
    local pChooseSp = cell:getChildByName("ChooseBg")
    pChooseSp:setVisible(bSelected)
end

function BangPaiListPage:setGongGao(str)
    if self.m_pGongGao == nil then
        return
    end
    self.m_pGongGao:setString(str)
end

function BangPaiListPage:setMenuState(id)
    if id > 0 then
        local applyBtn = self.m_buttons[BTN_APPLY_JOIN]
        if applyBtn ~= nil then
            applyBtn:setBright(false)
            applyBtn:setEnabled(false)
        end

        local createBtn = self.m_buttons[BTN_CREATE]
        if createBtn ~= nil then
            createBtn:setBright(false)
            createBtn:setEnabled(false)
        end
    else
        if #self.m_datas <= 0 then
            local applyBtn = self.m_buttons[BTN_APPLY_JOIN]
            if applyBtn ~= nil then
                applyBtn:setBright(true)
                applyBtn:setEnabled(true)
            end

            -- local enterBtn = self.m_buttons[BTN_ENTER]
            -- if enterBtn ~= nil then
            --     enterBtn:setBright(true)
            --     enterBtn:setEnabled(true)
            -- end
        end
    end
end

function BangPaiListPage:UpdateAskJoinBangPai(bangPaiId)
    if bangPaiId == 0 or self.m_datas == nil then
        return
    end

    local i = 1
    for j=1,#self.m_datas do
        i = j
        if self.m_datas[i].id == bangPaiId then
            break
        end
    end
    if i > #self.m_datas then
        return
    end
    if self.m_pTableView == nil then
        return
    end

    self.m_datas[i].isInAskJoin = 1
    local offset = self.m_pTableView:getContentOffset()
    self.m_pTableView:reloadData()
    self.m_pTableView:setContentOffset(offset)
end

function BangPaiListPage:searchTouchCallback()
    if self.m_pSearchTextField == nil then
        return
    end
    local idx = -1
    local mybpinfo = LRoleDataMgr.Faction.Info
    local bangpaiName = self.m_pSearchTextField:getString()

    if #bangpaiName == 0 then
        Utils:ShowScrollTips(GUITips.RSI_BP_TIP29)
        return
    end

    if mybpinfo.name == bangpaiName then
        self:TableCellTouched(-1)
        return
    end

    local index = 0
    for i=1,#self.m_datas do
        local item = self.m_datas[i]
        if item.name == bangpaiName then
            index = i
            break
        end
    end
    if index > 0 then
        local min = self.m_pTableView:minContainerOffset().y
        local max = self.m_pTableView:maxContainerOffset().y
        if min < 0 then
            local cellHeight = self.m_pGridCell:getContentSize().height
            local offsetY = max - cellHeight * (#self.m_datas - index)
            offsetY = math.min(math.max(offsetY, min), max)
            local offset = self.m_pTableView:getContentOffset()
            self.m_pTableView:setContentOffset(cc.p(offset.x, offsetY))
        end
        self:TableCellTouched(index-1)
    else
        Utils:ShowScrollTips(GUITips.RSI_BP_TIP30)
    end
end

function BangPaiListPage:applyBtnCallback()
    local mybpinfo = LRoleDataMgr.Faction.Info
    if mybpinfo.id > 0 then
        Utils:ShowScrollTips(GUITips.RSI_BP_TIP25)
        return
    end

    if self.m_selectIndex < 0 then
        Utils:ShowScrollTips(GUITips.RSI_BP_TIP26)
        return
    end

    LuaNetSendMsg:QueryBangPaiJoin(self.m_datas[self.m_selectIndex + 1].id)
end

function BangPaiListPage:createBtnCallback()
    LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "BangPai.BangPaiUI",AppDef.UIType.FirstClassLayer)
    self:SendMsg(LGameMsg.m_deleteUIMsg)
    
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "BangPai.BangPaiCreatePopup",AppDef.UIType.SecondClassLayer)
    self:SendMsg(LGameMsg.m_initUIMsg)

    --local cost = stream:ReadWord()
    LGameMsg.m_netDealMsg:Change(LUIBangPaiEvent.CreateCost, 1000)
    self:SendMsg(LGameMsg.m_netDealMsg)


    --LuaNetSendMsg:QueryBangPaiCreateCost()
end

function BangPaiListPage:enterBtnCallback()
    local mybpinfo = LRoleDataMgr.Faction.Info
    --print(self.m_selectIndex)

    if LRoleDataMgr.m_bIsCrossServer then
        Utils:ShowScrollTips(GUITips.RSI_CS_TIP2)
        return
    end

    if self.m_selectIndex < 0 and mybpinfo.id > 0 then
        LuaNetSendMsg:QueryBangPaiEnterZone(mybpinfo.id)
    elseif self.m_selectIndex >= 0 and self.m_selectIndex < #self.m_datas then
        LuaNetSendMsg:QueryBangPaiEnterZone(self.m_datas[self.m_selectIndex+1].id)
    end
end

return BangPaiListPage