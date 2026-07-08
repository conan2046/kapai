
local NationalDayGiftUI = LUIBase:New()
NationalDayGiftUI.__index = NationalDayGiftUI
local TimerLabelUI = require("View.Common.TimerLabelUI")
--local this = LTcpSocket
function NationalDayGiftUI:New(parent)
	local o = LUIBase:New()
	setmetatable(o,NationalDayGiftUI)	
    o:Init(parent)
	return o
end

local NAL_SENDTYPE = 1
local NAL_ACCEPTTYPE = 2

--注册事件
-- -----------------------------------
function NationalDayGiftUI:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function NationalDayGiftUI:ProcessEvent(msg)

end

function NationalDayGiftUI:Init(parent)
    self.m_pUILayer = cc.CSLoader:createNode("csd/ZengsongLayer.csb")
    parent:addChild(self.m_pUILayer)
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:initOriData()
    self:InitUIControl()
    self:initAcceptTableView()
end

function NationalDayGiftUI:initOriData( ... )
    -- body
    self._curType = NAL_SENDTYPE
end

function NationalDayGiftUI:InitUIControl( ... )
    -- body
    local panel = self.m_pUILayer:getChildByName("Zengsong")
    local charts = panel:getChildByName("TheCharts")
    self._tableview = charts:getChildByName("List")
    self._pCell = charts:getChildByName("Name")
    self.PersonalBg = charts:getChildByName("PersonalBg")
    self.personalNum = self.PersonalBg:getChildByName("PersonalNum")
    self.personalName = self.PersonalBg:getChildByName("PersonalName")
    self.jifen = self.PersonalBg:getChildByName("Jifen")

    self.wuAward = self.PersonalBg:getChildByName("wu")
    self.buttonSend = charts:getChildByName("Button_1")
    self.buttonSend:getChildByName("Choose"):setVisible(true)
    self.buttonSend:getChildByName("Text_1"):setVisible(false)
    self.buttonSend:getChildByName("Text_2"):setVisible(true)
    local function sendRankEvent( sender )
        -- body
        if self._curType == NAL_SENDTYPE then
            return
        end
        self._curType = NAL_SENDTYPE
        sender:getChildByName("Choose"):setVisible(true)
        sender:getChildByName("Text_1"):setVisible(false)
        sender:getChildByName("Text_2"):setVisible(true)
        self.buttonAccept:getChildByName("Choose"):setVisible(false)
        self.buttonAccept:getChildByName("Text_1"):setVisible(true)
        self.buttonAccept:getChildByName("Text_2"):setVisible(false)
        self.m_pSendTableView:setVisible(true)
        self.m_pAcceptTableView:setVisible(false)
        LuaNetSendMsg:QueryNationalGiftData(34, 1, 1)
    end
    self.buttonSend:addClickEventListener(sendRankEvent)

    self.buttonAccept = charts:getChildByName("Button_2")
    local function acceptRankEvent( sender )
        -- body
        if self._curType == NAL_ACCEPTTYPE then
            return
        end
        self._curType = NAL_ACCEPTTYPE
        sender:getChildByName("Choose"):setVisible(true)
        sender:getChildByName("Text_1"):setVisible(false)
        sender:getChildByName("Text_2"):setVisible(true)
        self.m_pSendTableView:setVisible(false)
        self.m_pAcceptTableView:setVisible(true)
        self.buttonSend:getChildByName("Choose"):setVisible(false)
        self.buttonSend:getChildByName("Text_1"):setVisible(true)
        self.buttonSend:getChildByName("Text_2"):setVisible(false)
        LuaNetSendMsg:QueryNationalGiftData(34, 1, 2)
    end
    self.buttonAccept:addClickEventListener(acceptRankEvent)

    local helpBtn = charts:getChildByName("HelpBtn")
    local function helpBtnEvent( sender )
        -- body
        self:helpButtonCallback()
    end
    helpBtn:addClickEventListener(helpBtnEvent)

    local giveBtn = charts:getChildByName("GiveBtn")
    local function giveEvent( sender )
        -- body
    end
    giveBtn:addClickEventListener(giveEvent)
    self.Tips = charts:getChildByName("Tips")

    self._textTimeOri = panel:getChildByName("Text_1")
    self.acLeftTime = self._textTimeOri:getChildByName("Time")
    self.m_timerLabel = TimerLabelUI:New(self.acLeftTime, nil, nil, handler(self, NationalDayGiftUI.TimeReduce))
    self:initSendTableView()
    self:initAcceptTableView()

    local giveBtn = charts:getChildByName("GiveBtn")
    giveBtn:addClickEventListener(function( sender )
        -- body
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Social.GiveMainLayer", AppDef.UIType.FirstClassLayer, 1)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end)
end

function NationalDayGiftUI:helpButtonCallback()
    local str = GUITips.RSI_NATIONALGIFT_TIPS1
    local function OKCallback()
    end
    local msgData = {
        title = GUITips.RSI_WELFARE_MSG38,
        okCallback = OKCallback,
        desc = str,
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIMsgBoxEvent.ShowMsgBox, msgData)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function NationalDayGiftUI:initData()
    LuaNetSendMsg:QueryNationalGiftData(34, 1, 1)
    local _ = self.m_pUILayer and self.m_pUILayer:setVisible(true)
end

function NationalDayGiftUI:updateData( data )
    -- dump(data, "data ============>")
    self._rankData = data

    local listData = {}
    if self._rankData.rankType == NAL_SENDTYPE then
        listData = self._rankData.sendRankDataList
    else
        listData = self._rankData.acceptDataList
    end

    if #listData > 0 then
        self.PersonalBg:setVisible(true)
        self.Tips:setVisible(false)

        self.personalName:setString(LRoleDataMgr.MyHeroInfo.name)
        if self._rankData.ownRank > 0 then
            self.personalNum:setString(self._rankData.ownRank)
        else
            self.personalNum:setString(GUITips.RSI_WELFARE_MSG29)
        end
        self.jifen:setString(self._rankData.ownRankScore)


        for i=1, 3 do
            local strCong = "Reward_"..i
            local reward = self.PersonalBg:getChildByName(strCong)
            reward:setVisible(false)
        end

        if #self._rankData.myItemInfo < 1 then
            self.wuAward:setVisible(true)
        else
            self.wuAward:setVisible(false)
            for i=1, #self._rankData.myItemInfo do
                --最多现实三个
                if i < 4 then
                    local strCong = "Reward_"..i
                    local reward = self.PersonalBg:getChildByName(strCong)
                    local oneData = self._rankData.myItemInfo[i]
                    if oneData.itemID > 0 then
                        reward:setVisible(true)
                        reward:removeAllChildren()
                        Utils:GetItemCellValue(reward, 0, oneData.itemID, true, true, oneData.itemNum, nil, true, true)
                    end
                end
            end
        end
    else
        --无数据
        self.Tips:setVisible(true)
        self.PersonalBg:setVisible(false)
    end
    
    if self._rankData.leftTime > 0 then
        if self.m_timerLabel ~= nil then
            self.m_timerLabel:set(self._rankData.leftTime, handler(self, self.TimeCountDownEnd))
            self.m_timerLabel:start()
        end
    else
        self.acLeftTime:setString("")
        self._textTimeOri:setString(GUITips.RSI_NATIONALGIFT_TIPS3)
    end
    

    if self._rankData.rankType == NAL_SENDTYPE then
        self.m_pSendTableView:reloadData()
    else
        self.m_pAcceptTableView:reloadData()
    end
    

end

function NationalDayGiftUI:TimeReduce(pText, h, m, s, left)
    if pText == nil then
        return
    end

    local str = ""
    local day = 0
    if h > 24 then
        day = math.floor(h / 24)
        h = math.fmod(h, 24)
    end
    if day > 0 then
        str = str..tostring(day)..GUITips.Item_Info_Day
        str = str..string.format("%02d:%02d", h, m)
    else
        str = str..string.format("%02d:%02d:%02d", h, m, s)
    end
    
    pText:setString(str)
end

function NationalDayGiftUI:TimeCountDownEnd()
    self.acLeftTime:setString("")
    self._textTimeOri:setString(GUITips.RSI_NATIONALGIFT_TIPS3)
end

function NationalDayGiftUI:initSendTableView()
    local tableView = cc.TableView:create(self._tableview:getContentSize())
--    --print("width = ".. self.m_pFriendView:getContentSize().width .. "height = " .. self.m_pFriendView:getContentSize().height);
--    --print("width = ".. tableView:getContentSize().width .. "height = " .. tableView:getContentSize().height);
    -- tableView:setContentSize(self._tableview:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(cc.p(0, 0))
    tableView:setPosition(cc.p(0, 0))
    tableView:setDelegate()
    tableView:setSwallowsTouches(true)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self._tableview:addChild(tableView)
    

    local function tableCellTouched(sender,cell)
        --print("tableCellTouched", cell:getIdx())
        self:natlTableCellTouched(sender, cell)
    end

    local function cellSizeForTable(sender,idx)
        local width = self._pCell:getContentSize().width
        local height = self._pCell:getContentSize().height
--        --print("cellSizeForTable width = "..width .. " cellSizeForTable height = ",height)
        return width, height
    end

    local function tableCellAtIndex(sender, idx)
--        --print("cellSizeForTable idx = ".. idx )
        return self:natlRankTableCellAtIndex(sender, idx, NAL_SENDTYPE)
    end

    local function numberOfCellsInTableView()
        local size = #self._rankData.sendRankDataList
--        --print("numberOfCellsInTableView size = ", size)
        return size
    end

    local function scrollViewDisScroll(view)
        self.m_isDragging = view:isDragging()
    end

    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量
    tableView:registerScriptHandler(scrollViewDisScroll, cc.SCROLLVIEW_SCRIPT_SCROLL)
    self.m_pSendTableView = tableView
end

function NationalDayGiftUI:natlTableCellTouched(sender, cell)
    -- body

end

function NationalDayGiftUI:natlRankTableCellAtIndex(sender, idx, type)
    -- body
    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self._pCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)
        cellChild:setTouchEnabled(false)
    else
        cellChild = cell:getChildByTag(123)
    end
    self:ShowCellInfo(cellChild, idx, type)
    return cell
end

function NationalDayGiftUI:ShowCellInfo(cellChild, idx, type)
    -- print("cell idx", idx)
    if cellChild == nil then
        return
    end
    local index = idx + 1

    local data
    -- print("type ==============", type)
    if type == NAL_SENDTYPE then
        data = self._rankData.sendRankDataList[index]
    else
        data = self._rankData.acceptDataList[index]
    end
    if data == nil then
        return
    end

    --背景条
    local Bg = cellChild:getChildByName("Bg")
    local ChooseBg = cellChild:getChildByName("ChooseBg")
    local isShowBg = (idx + 1) %2 > 0 
    Bg:setVisible(isShowBg)
    ChooseBg:setVisible(not isShowBg)

    local PlaceImage1 = cellChild:getChildByName("PlaceImage1")
    PlaceImage1:setVisible(false)
    local PlaceImage2 = cellChild:getChildByName("PlaceImage2")
    PlaceImage2:setVisible(false)
    local PlaceImage3 = cellChild:getChildByName("PlaceImage3")
    PlaceImage3:setVisible(false)
    local PlaceNum = cellChild:getChildByName("PlaceNum")
    PlaceNum:setVisible(false)
    -- print("ShowCellInfo index =", index)
    if index == 1 then
        PlaceImage1:setVisible(true)
    elseif index == 2 then
        PlaceImage2:setVisible(true)
    elseif index == 3 then
        PlaceImage3:setVisible(true)
    elseif index >= 4 then
        PlaceNum:setVisible(true)
        PlaceNum:setString(tostring(index))
    end

    local PlaceName = cellChild:getChildByName("PlaceName")
    PlaceName:setString(data.name)

    local VIPImage = cellChild:getChildByName("VIPImage")
    VIPImage:setVisible(false)
    if data.vip > 0 then
        VIPImage:setVisible(true)
        local vipLabel = VIPImage:getChildByName("AtlasLabel")
        vipLabel:setString(data.vip)
    else
        VIPImage:setVisible(false)
    end

    local Jifen = cellChild:getChildByName("Jifen")
    Jifen:setString(tostring(data.score))


    for i=1, 3 do
        local strCong = "Title_"..i
        local Title = cellChild:getChildByName(strCong)
        Title:setVisible(false)
    end

    for i=1, #data.itemInfo do
    --最多现实三个
        if i < 4 then
            local strCong = "Title_"..i
            local Title = cellChild:getChildByName(strCong)
            local oneData = data.itemInfo[i]
            if oneData.itemID > 0 then
                Title:setVisible(true)
                Title:removeAllChildren()
                Utils:GetItemCellValue(Title, 0, oneData.itemID, true, true, oneData.itemNum, nil, true, true)
            end
        end
    end

end

function NationalDayGiftUI:initAcceptTableView()
    local tableView = cc.TableView:create(self._tableview:getContentSize())
--    --print("width = ".. self.m_pFriendView:getContentSize().width .. "height = " .. self.m_pFriendView:getContentSize().height);
--    --print("width = ".. tableView:getContentSize().width .. "height = " .. tableView:getContentSize().height);
    -- tableView:setContentSize(self._tableview:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(cc.p(0, 0))
    tableView:setPosition(cc.p(0, 0))
    tableView:setDelegate()
    tableView:setSwallowsTouches(true)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self._tableview:addChild(tableView)
    

    local function tableCellTouched(sender,cell)
        --print("tableCellTouched", cell:getIdx())
        self:natlTableCellTouched(sender, cell)
    end

    local function cellSizeForTable(sender,idx)
        local width = self._pCell:getContentSize().width
        local height = self._pCell:getContentSize().height
--        --print("cellSizeForTable width = "..width .. " cellSizeForTable height = ",height)
        return width, height
    end

    local function tableCellAtIndex(sender, idx)
--        --print("cellSizeForTable idx = ".. idx )
        return self:natlRankTableCellAtIndex(sender, idx, NAL_ACCEPTTYPE)
    end

    local function numberOfCellsInTableView()
        local size = #self._rankData.acceptDataList
--        --print("numberOfCellsInTableView size = ", size)
        return size
    end

    local function scrollViewDisScroll(view)
        self.m_isDragging = view:isDragging()
    end

    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量
    tableView:registerScriptHandler(scrollViewDisScroll, cc.SCROLLVIEW_SCRIPT_SCROLL)
    self.m_pAcceptTableView = tableView
    self.m_pAcceptTableView:setVisible(false)
end

function NationalDayGiftUI:Reset()
    local _ = self.m_pUILayer and self.m_pUILayer:setVisible(false)
end

function NationalDayGiftUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
    self.PersonalBg = nil
    self.buttonSend = nil
    self.buttonAccept = nil
    self._textTimeOri = nil
end

return NationalDayGiftUI