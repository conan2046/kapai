--[[
lua里面的游戏逻辑控制
]]

-- ----------------------------------------------
-- 常量区
local CsbFilePath = "csd/SocialPopupLayer.csb"
local WhisperChat = 1
local AddFriendLayer = 2
local AddFriend = 1
local AddBlackList = 2; 

local AddFriendLayer = LUIBase:New()
AddFriendLayer.__index = AddFriendLayer
--local this = LTcpSocket
function AddFriendLayer:New(type)
	local o = LUIBase:New()
	setmetatable(o,AddFriendLayer)	
    o:Init(type)
	return o
end



--[[
注册事件
]]
function AddFriendLayer:RegistMsgs()
    self.msgIds = 
    {
         LUISocialEvent.updateAddFriendLayer,
         LUISocialEvent.updateBlackList,
         LUISocialEvent.updateSearchPlayer,
         LUIGuideEvent.GuideComplete,
    }
    self:RegistSelf(self,self.msgIds)
end

function AddFriendLayer:RegisterGuide()
    --------------------------------------------
    -- local data = LDataConstMgr:GetGuideData(GuideDef.StepId.Guide_SHEJ_3)
    -- Utils:RegisterGuide(GuideDef.StepId.Guide_SHEJ_3, nil, function()
    --     if #self._friendList > 0 then
    --         self:addfriendTouched(1)
    --     end
    -- end, data.maskOffset, true)
    -- --------------------------------------------
    -- LGameMsg.m_baseMsgWithOne:Change(LUISecondClassBgEvent.RegisterCloseGuide, GuideDef.StepId.Guide_SHEJ_4)
    -- self:SendMsg(LGameMsg.m_baseMsgWithOne)
--     local data = LDataConstMgr:GetGuideData(GuideDef.StepId.Guide_TJHY)
--     Utils:RegisterGuide(data.stepId, nil, nil, data.maskOffset, true)

--     data = LDataConstMgr:GetGuideData(GuideDef.StepId.Guide_TJHY_1)
--     Utils:RegisterGuide(data.stepId, nil, nil, data.maskOffset, true)

--     data = LDataConstMgr:GetGuideData(GuideDef.StepId.Guide_TJHY_FINISH)
--     Utils:RegisterGuide(data.stepId, nil, nil, data.maskOffset, true)
end

function AddFriendLayer:ProcessEvent(msg)

    if msg.msgId == LUISocialEvent.updateAddFriendLayer then

        self:updateView(msg.value)
    end

    if msg.msgId == LUISocialEvent.updateBlackList then

        self:updateView(msg.value)
    end

    if msg.msgId == LUISocialEvent.updateSearchPlayer then
        self:updateSearchPlayer(msg.value)
    end

    if msg.msgId == LUIGuideEvent.GuideComplete then
        if msg.value == GuideDef.StepId.Guide_TJHY_FINISH then
            performWithDelay(self.m_pUILayer, function(sender)
                Utils:DeleteUI("Social.AddFriendLayer")
            end, 1/30)
        end
    end
end

function AddFriendLayer:Init(type)

    self.m_pUILayer = cc.CSLoader:createNode(CsbFilePath)
    self.m_pUILayer:setContentSize(AppDef.frameSize)
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

    self:InitAddfriendList();
    if type == AddFriend then
        LuaNetSendMsg:QueryRecommendPlayer()
    elseif type == AddBlackList then
        LuaNetSendMsg:QueryBlackListInfo()
    end
    --self:RegisterGuide()
end


function AddFriendLayer:InitData()
    
    if self._type == AddFriend then
        LGameMsg.m_baseMsgWithOne:Change(LUISecondClassBgEvent.SetTitle, GUITips.RSI_MDSI_ADDFRIEND)
    elseif self._type == AddBlackList then
        LGameMsg.m_baseMsgWithOne:Change(LUISecondClassBgEvent.SetTitle, GUITips.RSI_MDSI_BLACKLIST)
    end
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
--    self.m_pUILayer:getChildByName("IntoGuild"):setSwallowTouches(false)
    local listBg = self.m_pUILayer:getChildByName("IntoGuild"):getChildByName("ListBg")
    self.m_pAddfriendTV = listBg:getChildByName("List")

    local refrashBtn = listBg:getChildByName("RefreshBtn")
    local function OnAddRefrashBtnButtonClick(sender)
        LuaNetSendMsg:QueryRecommendPlayer()
    end
    refrashBtn:addClickEventListener(OnAddRefrashBtnButtonClick)
	self:MarkIntaractCObj(refrashBtn)
    self.m_pCell = self.m_pUILayer:getChildByName("IntoGuild"):getChildByName("List")

    self._textField = self.m_pUILayer:getChildByName("IntoGuild"):getChildByName("SearchBg"):getChildByName("TextField")
    self._textField:setCursorEnabled(true)
    self._friendList = {}
end

function AddFriendLayer:AddTouchEvt()
    local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Social.AddFriendLayer")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end

    LGameMsg.m_baseMsgWithOne:Change(LUISecondClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

--  查找
    local searchBtn = self.m_pUILayer:getChildByName("IntoGuild"):getChildByName("SearchBg"):getChildByName("SearchBtn")
    local function OnSearchBtnButtonClick(sender)
        local string = self._textField:getString()
        if string.len(string) > 0 then
            --print("LuaNetSendMsg:QuerySerchPlayer string", string)
            LuaNetSendMsg:QuerySerchPlayer(string);
            self._textField:setString("")
        end
        
    end

    searchBtn:addClickEventListener(OnSearchBtnButtonClick)
	self:MarkIntaractCObj(searchBtn)
    --  刷新
    local refrashBtn = self.m_pUILayer:getChildByName("IntoGuild"):getChildByName("ListBg"):getChildByName("RefreshBtn")
    local function OnRefrashBtnButtonClick(sender)
        LuaNetSendMsg:QueryRecommendPlayer()
        self._textField:setString("")
    end
    refrashBtn:addClickEventListener(OnRefrashBtnButtonClick)
	self:MarkIntaractCObj(refrashBtn)
    if self._type == AddBlackList then
        refrashBtn:setVisible(false)
    end

end

function AddFriendLayer:InitAddfriendList()

    --print("AddFriendLayer: InitAddfriendList =")

    local tableView = cc.TableView:create(self.m_pAddfriendTV:getContentSize())
    --print("width = ".. self.m_pAddfriendTV:getContentSize().width .. "height = " .. self.m_pAddfriendTV:getContentSize().height);
    --print("width = ".. tableView:getContentSize().width .. "height = " .. tableView:getContentSize().height);
    tableView:setContentSize(self.m_pAddfriendTV:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(cc.p(0, 0))
    tableView:setPosition(0, 0)
    tableView:setDelegate()
    tableView:setSwallowsTouches(true)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.m_pAddfriendTV:addChild(tableView)

    local function tableCellTouched(sender,cell)
        --print("tableCellTouched".. cell:getIdx())
        self:FriendTableCellTouched(cell)
    end

    local function cellSizeForTable(sender,idx)
        local width = self.m_pCell:getContentSize().width
        local height = self.m_pCell:getContentSize().height
        --print("cellSizeForTable width = "..width .. " cellSizeForTable height = ",height)
        return width, height
    end

    local function tableCellAtIndex(sender, idx)
        --print("cellSizeForTable idx = ".. idx )
        return self:FriendTableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        local num = 0
        local listNum = #self._friendList
        if listNum % 2 == 0 then
            num = listNum / 2
        else
            num = math.floor(listNum / 2) + 1 
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
    self.m_pAddFriendTableView = tableView

    --print("AddFriendLayer:InitAddfriendList")
end

--点击选中处理
function AddFriendLayer:FriendTableCellTouched(cell)
    
    local ind = cell:getIdx()
    local cellChild = cell:getChildByTag(123)
    --print("tableview touched " ..ind.." ") 
end 


function AddFriendLayer:FriendTableCellAtIndex(sender, idx)

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
    self:ShowFriendCellInfo(cellChild, idx)
    return cell
end

--增加好友
function AddFriendLayer:addfriendTouched(ind, sender)
--    --print("sel idx friend", ind)
    local data = self._friendList[ind]
    if self._type == AddFriend then
        LuaNetSendMsg:QueryAddFriend(data.id);
        if sender then
            sender:setTouchEnabled(false)
            sender:setBright(false)
            local btnText = sender:getChildByName("Text1")
            btnText:setString(GUITips.RSI_ALREADYADD)
        end
    elseif self._type == AddBlackList then
        if self._isAddBlack then
            LuaNetSendMsg:QueryAddBlack(data.id);
        else
            LuaNetSendMsg:QueryDelBlack(data.id);
--刷新界面
            self:updateDelBlackList(ind)  
        end
        
    end
end

function AddFriendLayer:ShowFriendCellInfo(cellChild, idx)

    local function addfriendTouched(sender)
        if self.m_isDragging then
            return
        end
        local ind = sender:getTag()
--        --print("touch self._friendList", #self._friendList)
        self:addfriendTouched(ind, sender)
    end

    --print("cell idx = ", idx)
    if cellChild ~= nil then
        for i=1,2 do
            --print("self._friendList size = ", #self._friendList)
            local index = idx*2+i
            --print("self._friendList index =", index)
            if(index > #self._friendList) then
                cellChild:getChildByName("Name_2"):setVisible(false)
                return;
            end
       
            local frienCell = cellChild:getChildByName("Name_"..i)
            cellChild:setSwallowTouches(false)
            frienCell:setSwallowTouches(false)
            frienCell:setVisible(true)
            --实现选中状态
            local addFriendbtn = frienCell:getChildByName("Button")
            addFriendbtn:setBright(true)
            addFriendbtn:setSwallowTouches(false)

            if not addFriendbtn:isTouchEnabled() then
                addFriendbtn:setTouchEnabled(true)
            end
            
            local btnTextAdd = addFriendbtn:getChildByName("Text1")
            btnTextAdd:setString(GUITips.RSI_ADDFRIEND)

            local btnTextDel = addFriendbtn:getChildByName("Text2")
            
            if self._type == AddFriend then
                btnTextAdd:setVisible(true)
                btnTextDel:setVisible(false)
            elseif self._type == AddBlackList then
                if self._isAddBlack then
                    btnTextAdd:setVisible(true)
                    btnTextDel:setVisible(false)
                else
                    btnTextAdd:setVisible(false)
                    btnTextDel:setVisible(true)
                end
            end

            addFriendbtn:setTag(index)
            addFriendbtn:addClickEventListener(addfriendTouched)
            self:MarkIntaractCObj(addFriendbtn)

            local data = self._friendList[index]
            local face = frienCell:getChildByName("Icon")
            local strHeadImage = AppDef:GetHeroPicFileName(data.prof, AppDef.HeadType.HERO_IMAGE_HEAD_ROUND);
            face:loadTexture(strHeadImage, ccui.TextureResType.localType);

            local name = frienCell:getChildByName("RoleName")
            name:setString(data.name)

            local lv = frienCell:getChildByName("Icon"):getChildByName("LevelNum")
            lv:setString(data.level)

            local pro = frienCell:getChildByName("Career")
            pro:setString(data.profession)
            pro:setVisible(true)
            
            frienCell:getChildByName("LevelNum"):setVisible(false)
            
        end
    end
end

function AddFriendLayer:onExit()
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_SHEJ_3)
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_SHEJ_4)
    self:exitEvent()
    self:Destory()
end

function AddFriendLayer:updateView(list)
    self._friendList = list;
    self._isAddBlack = false; 
    self.m_pAddFriendTableView:reloadData()
    --print("*****************************update lsit", #list)
end

function AddFriendLayer:updateSearchPlayer(list)
    self._friendList = list;
    
    if self._type == AddFriend then
        self._isAddBlack = false;
    elseif self._type == AddBlackList then
        self._isAddBlack = true;
    end

    self.m_pAddFriendTableView:reloadData()
    --print("*****************************updateAddBlackList lsit", #list)
end

function AddFriendLayer:updateDelBlackList(ind)
    -- body
    --print("AddFriendLayer:updateDelBlackList ***********", ind)
    table.remove(self._friendList, ind)
    self.m_pAddFriendTableView:reloadData()
end

function AddFriendLayer:exitEvent( ... )
    -- body
    self.m_pAddfriendTV = nil
    self.m_pUILayer = nil
    self._type = nil
    self._textField = nil
    self._friendList = nil
    self.m_pAddFriendTableView = nil
    self.m_pCell = nil
end

return AddFriendLayer
