--[[
邀请玩家
]]
local TeamDef = require("View.Team.TeamUIDef")

local TeamInviteListUI = LUIBase:New()
TeamInviteListUI.__index = TeamInviteListUI


local ScriptPath = "Team.TeamInviteUI"
--local this = LTcpSocket
function TeamInviteListUI:New()
	local o = LUIBase:New()
	setmetatable(o,TeamInviteListUI)	
    o:Init()
	return o
end


function TeamInviteListUI:Init()
    self:RegistMsgs()
    self:InitMemberVariable()
    self:InitViewSize()
    --self:InitInviteData()
    self:InitUICtr()
    self:InitEvt()
    self:SetCurTab(1)
end

-- function TeamInviteListUI:InitInviteData()
-- 	local function GetMapHeroListCallback(herolist)
--         self.m_pHeroList = herolist
--         local tmp = {}
--         for i = #self.m_pHeroList, 1, -1 do
--             if self.m_pHeroList[i]:IsTeam() then
--                 table.remove(self.m_pHeroList,i)
--             end
--         end
--         self:InitUICtr()
-- 	    self:InitEvt()
-- 	    self:SetCurTab(1)
-- 	end
-- 	local msg = GetMapHerosMsg:new(CEnum.MapEvent.LuaGetMapHeros,GetMapHeroListCallback)
-- 	self:SendMsg(msg)
-- end

function TeamInviteListUI:RegistMsgs()
    self.msgIds = 
    {
        LUIRoleTeamEvent.RecvNearPlayers,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function TeamInviteListUI:ProcessEvent(msg)
    if msg.msgId == LUIRoleTeamEvent.RecvNearPlayers then
        self:RecvList(msg.value[1],msg.value[2])
    end
end

function TeamInviteListUI:RecvList(listType, stream)
    --[[
    op=25   num   { roleId   name    zhongzu   sex   level  zhandouli  state}
    1byte  2byte     4byte  string    1byte   1byte  2byte    4byte    1byte
    ]]

    self.m_pInviteList[listType] = {}
    local num = stream:ReadWord()
    
    for i = 1, num do
        local data = {}
        data.roleId = stream:ReadUInt() 
        data.name = stream:ReadString()
        data.zhongzu = stream:ReadByte()
        data.sex = stream:ReadByte()
        data.level = stream:ReadWord()
        data.zhandouli = stream:ReadUInt()
        data.state = stream:ReadByte()
        table.insert(self.m_pInviteList[listType],data)
    end

    if self.m_curTab == listType then
        self.m_pTableView:setVisible(true)
        self.m_pTableView:reloadData()
    end
end

function TeamInviteListUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/TeamInviteListLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)



    LGameMsg.m_baseMsgWithOne:Change(LUISecondClassBgEvent.SetTitle, GUITips.UI_Title_Team_InviteList)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, ScriptPath)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    LGameMsg.m_baseMsgWithOne:Change(LUISecondClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function TeamInviteListUI:onExit()
    self.m_pUILayer = nil
    self.m_pUILayer = nil
    self.m_pListView = nil--
    self.m_pCellPanel = nil
    self.m_pCellChild = nil
    self.m_pClearBtn = nil
    self.m_pHeroData = nil
    self.m_pApplyList = nil

    self.m_pTabBtns = nil
    self.m_pListPanel = nil--
    self.m_pTableView = nil

    self.m_pQuickBtn = nil--一键邀请
    self.m_pFlashBtn = nil--刷新
    self.m_cellWidth = nil
    self.m_curTab = nil
    self.m_pFriendList = nil
    self.m_pFactionList = nil

    self.m_pInviteList = nil
    self:Destory()
end

--[[
初始化成员变量
]]
function TeamInviteListUI:InitMemberVariable()
    self.m_pHeroData = LRoleDataMgr.MyHeroInfo
    self.m_pUILayer = nil

    self.m_pTabBtns = {}
    self.m_pListPanel = nil--
    self.m_pTableView = nil
    self.m_pCellPanel = nil
    self.m_pCellChild = nil

    self.m_pQuickBtn = nil--一键邀请
    self.m_pFlashBtn = nil--刷新
    self.m_cellWidth = 0
    self.m_curTab = 0
    --self.m_pHeroList = nil
    --self.m_pHeroFlag = {}--是否已邀请标致
    self.m_pFriendList = nil
    self.m_pFactionList = nil

    self.m_pInviteList = {{},{},{}}
end

function TeamInviteListUI:InitUICtr()
    local panel = self.m_pUILayer:getChildByName("InviteList")
    for i = 1, 3 do
    	self.m_pTabBtns[i] = panel:getChildByName("Button" .. i)
    	self.m_pTabBtns[i]:setTag(i)
    	local img = self.m_pTabBtns[i]:getChildByName("ChooseBg")
		img:setVisible(false)
    end

    
    self.m_pListPanel = panel:getChildByName("ListBg"):getChildByName("List")--
    self.m_pTableView = nil
    self.m_pCellPanel = panel:getChildByName("List1")
    self.m_pCellChild = self.m_pCellPanel:getChildByName("Name")

    self.m_pQuickBtn = panel:getChildByName("Btn2")--一键邀请
    self.m_pFlashBtn = panel:getChildByName("Btn1")--刷新
    self.m_cellWidth = self.m_pCellChild:getContentSize().width
    self:InitTabView()
end

function TeamInviteListUI:InitTabView()
	local tableView = cc.TableView:create(self.m_pListPanel:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(self.m_pListPanel:getAnchorPoint())
    tableView:setPosition(self.m_pListPanel:getPosition())
    tableView:setDelegate()
    tableView:setSwallowsTouches(false)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.m_pListPanel:getParent():addChild(tableView)

    -- local function tableCellTouched(sender,cell)
    --     --self:LeftTableCellTouched(cell)
    -- end
    local function cellSizeForTable(sender,idx)
        local width = self.m_pCellPanel:getContentSize().width
        local height = self.m_pCellPanel:getContentSize().height
        --print("width=",width, "height",height)
        return width, height
    end
    local function tableCellAtIndex(sender, idx)
        return self:TableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        local cnt = self:GetCurTabCellNum()
        
        return cnt
    end
    --tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量
    tableView:reloadData()
    self.m_pTableView = tableView
end

function TeamInviteListUI:GetCurTabCellNum()
    if self.m_curTab == 0 then
        return 0
    end
    --print("GetCurTabCellNum",#self.m_pInviteList[self.m_curTab])
    return math.ceil(#self.m_pInviteList[self.m_curTab]/2)
end

function TeamInviteListUI:TableCellAtIndex(sender, idx)
	local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pCellPanel:clone()
        
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0,0))
        cellChild:setVisible(true)
        cell:addChild(cellChild)


    else
        cellChild = cell:getChildByTag(123)
    end
    self:ShowCellInfo(cellChild,idx)
    
    return cell
end

function TeamInviteListUI:ShowCellInfo(cellChild, idx)
    self:ShowHeroInfo(cellChild, idx)
	-- if self.m_curTab == TeamDef.InviteTab.NearHero then
	-- 	self:ShowHeroInfo(cellChild, idx)
	-- elseif self.m_curTab == TeamDef.InviteTab.Friends then
	-- 	self:ShowFriendInfo(cellChild, idx)
	-- elseif self.m_curTab == TeamDef.InviteTab.Faction then
	-- 	return self:ShowFactionInfo(cellChild, idx)
	-- end
end

function TeamInviteListUI:ShowHeroInfo(cellChild, idx)
	local ind = idx * 2 + 1
	local info = self.m_pInviteList[self.m_curTab][ind]
	local cell = cellChild:getChildByName("Name")
	cell:setTag(1)
	local nameLabel = cell:getChildByName("RoleName")
    nameLabel:setString(info.name)
    local headImg = cell:getChildByName("Icon")

    local strHeadImage = AppDef:GetHeroPicFileName(info.zhongzu, AppDef.HeadType.HERO_IMAGE_HEAD_ROUND)
    headImg:loadTexture(strHeadImage, ccui.TextureResType.localType);
    local lvLabel = headImg:getChildByName("LevelNum")
    lvLabel:setString(info.level)

    local powerLabel = cell:getChildByName("zhanli")
    powerLabel:setString(GUITips.UI_Shenqi_Zhanli .. ":" .. Utils:getPowerStr(info.zhandouli))

    local flag = cell:getChildByName("Mark")
    local btn = cell:getChildByName("Button")
    if info.state == 1 then
        --已邀请
        btn:setVisible(false)
        flag:setVisible(true)
    else
        btn:setVisible(true)
        flag:setVisible(false)
    end
    --GetZhandouli
    local function AcceptCallback(sender)
        local idx = sender:getTag()
        local curInfo = self.m_pInviteList[self.m_curTab][idx]
        curInfo.state = 1
        LRoleDataMgr.MyHeroInfo:SetTeamInvated(curInfo.roleId)
        sender:setVisible(false)
        sender:getParent():getChildByName("Mark"):setVisible(true)
        LuaNetSendMsg:QueryTeamInvite(curInfo.roleId)
        --LuaNetSendMsg:AccpetPlayerTeam(curInfo.id,1)
    end
    --local flag = cell:getChildByName("Mark")
    
    btn:setTag(ind)
    btn:addClickEventListener(AcceptCallback)
	self:MarkIntaractCObj(btn)
    -- if LRoleDataMgr.MyHeroInfo:IsTeamInvated(self.m_pInviteList[self.m_curTab][ind].roleId) then
    -- 	--已邀请
    -- 	btn:setVisible(false)
    -- 	flag:setVisible(true)
    -- else
    -- 	btn:setVisible(true)
    -- 	flag:setVisible(false)
    -- end
    local pCareer = cell:getChildByName("Career")
    pCareer:setString(AppDef:GetHeroProfessionalName(info.zhongzu))

    ind = ind  + 1
    if ind > #self.m_pInviteList[self.m_curTab] then
    	cell = cellChild:getChildByTag(2)
    	if cell ~= nil then
    		cell:removeFromParent()
    	end
    	return
    end
    info = self.m_pInviteList[self.m_curTab][ind]
    cell = cellChild:getChildByTag(2)
    if cell == nil then
	    cell = self.m_pCellChild:clone()
	    cell:setPosition(cc.p(self.m_cellWidth,0))
	    cellChild:addChild(cell)
	    cell:setTag(2)
	end
    nameLabel = cell:getChildByName("RoleName")
    nameLabel:setString(info.name)
    headImg = cell:getChildByName("Icon")

    strHeadImage = AppDef:GetHeroPicFileName(info.zhongzu, AppDef.HeadType.HERO_IMAGE_HEAD_ROUND)
    headImg:loadTexture(strHeadImage, ccui.TextureResType.localType);
    lvLabel = headImg:getChildByName("LevelNum")
    lvLabel:setString(info.level)
    powerLabel = cell:getChildByName("zhanli")
    powerLabel:setString(GUITips.UI_Shenqi_Zhanli .. ":" .. Utils:getPowerStr(info.zhandouli))
    local btn = cell:getChildByName("Button")
    btn:setTag(ind)
    btn:addClickEventListener(AcceptCallback)
	self:MarkIntaractCObj(btn)
    local flag = cell:getChildByName("Mark")
    btn:setTag(ind)
    btn:addClickEventListener(AcceptCallback)
	self:MarkIntaractCObj(btn)
    --if LRoleDataMgr.MyHeroInfo:IsTeamInvated(self.m_pInviteList[self.m_curTab][ind].roleId) then
    if info.state == 1 then
    	--已邀请
    	btn:setVisible(false)
    	flag:setVisible(true)
    else
    	btn:setVisible(true)
    	flag:setVisible(false)
    end
    local pCareer = cell:getChildByName("Career")
    local str = AppDef:GetHeroProfessionalName(info.zhongzu)
    pCareer:setString(str)
end

-- function TeamInviteListUI:ShowFriendInfo(cellChild, idx)
-- end

-- function TeamInviteListUI:ShowFactionInfo(cellChild, idx)
-- end

function TeamInviteListUI:InitEvt()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    local function FlashListCallback(sender)
        self:ReqList()
    end
    self.m_pFlashBtn:addClickEventListener(FlashListCallback)
	self:MarkIntaractCObj(self.m_pFlashBtn)
    local function QuickListCallback(sender)
        self:HandleQuickInvite()
    end
    self.m_pQuickBtn:addClickEventListener(QuickListCallback)
	self:MarkIntaractCObj(self.m_pQuickBtn)
    local function TabCallback(sender)
    	local ind = sender:getTag()
    	self:SetCurTab(ind)
	end
    for i = 1, 3 do
    	self.m_pTabBtns[i]:addClickEventListener(TabCallback)
		self:MarkIntaractCObj(self.m_pTabBtns[i])
    	self.m_pTabBtns[i]:setTag(i)
    end
end

function TeamInviteListUI:HandleQuickInvite()

    local num = math.ceil(#self.m_pInviteList[self.m_curTab]/2)
    for i = 1,num do
        local cell = self.m_pTableView:cellAtIndex(i - 1)
        if cell ~= nil then
            local cellChild = cell:getChildByTag(123)
            self:UpdateInviteFlagHeroInfo(cellChild, i - 1)
        end
    end
end

function TeamInviteListUI:UpdateInviteFlagHeroInfo(cellChild, idx)
    local ind = idx * 2 + 1
    local info = self.m_pInviteList[self.m_curTab][ind]
    local cell = cellChild:getChildByTag(1)
    if cell ~= nil then
        local flag = cell:getChildByName("Mark")
        local btn = cell:getChildByName("Button")
        if info.state == 0 then
            --已邀请
            info.state = 1
            LuaNetSendMsg:QueryTeamInvite(info.roleId)
            btn:setVisible(false)
            flag:setVisible(true)
        end
    end
    
    ind = ind  + 1
    local cell = cellChild:getChildByTag(2)
    if cell ~= nil then
        info = self.m_pInviteList[self.m_curTab][ind]
        local flag = cell:getChildByName("Mark")
        local btn = cell:getChildByName("Button")
        if info.state == 0 then
            --已邀请
            info.state = 1
            LuaNetSendMsg:QueryTeamInvite(info.roleId)
            btn:setVisible(false)
            flag:setVisible(true)
        end
    end
end

function TeamInviteListUI:ReqList()
    if  self.m_curTab == 1 then
        LuaNetSendMsg:ReqTeamNearHeros()
    elseif  self.m_curTab == 2 then
        LuaNetSendMsg:ReqTeamMyFriends()
    elseif  self.m_curTab == 3 then
        LuaNetSendMsg:ReqTeamMyFaction()
    end
    self.m_pTableView:setVisible(false)
end

function TeamInviteListUI:SetCurTab(tab)
	if self.m_curTab == tab then
		return
	end
	if self.m_curTab > 0 then
		local img = self.m_pTabBtns[self.m_curTab]:getChildByName("ChooseBg")
		img:setVisible(false)
	end
	self.m_curTab = tab
	local img = self.m_pTabBtns[self.m_curTab]:getChildByName("ChooseBg")
	img:setVisible(true)
    self:ReqList()
    
	--self.m_pTableView:reloadData()
end

return TeamInviteListUI