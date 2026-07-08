local BangPaiInvitePopup = LUIBase:New()
BangPaiInvitePopup.__index = BangPaiInvitePopup

local BangPaiDef = require("View.BangPai.BangPaiDef")

-- -----------------------------------
function BangPaiInvitePopup:New()
    local o = {}
    setmetatable(o, BangPaiInvitePopup)
    o:Init()
    return o
end

-- -----------------------------------
function BangPaiInvitePopup:Init()
    self.Script = "BangPai.BangPaiInvitePopup"
    --table view相关
    self.m_tableCount = 0
    self.m_isDragging = false
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_pTablePanel = nil
    self.m_datas = {}
    self.m_selectIndex = 0

    self.m_nameLabel = nil
    self.m_isInvited = {}

    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    self:initData()
end

function BangPaiInvitePopup:initData()
    local function GetCurMapCallback(_,_,_,_,mapSize)
        self.m_pMapSize = nil
        self.m_pMapSize = mapSize
    end
    local msg = GetMapChildMsg:new(CEnum.MapEvent.LuaGetCurMapObjData, GetCurMapCallback)
    self:SendMsg(msg)

    local function GetMapHeroListCallback(list)
        if LRoleDataMgr.MyHeroInfo.node == nil then
            return
        end
        local x,y = LRoleDataMgr.MyHeroInfo.node:getPosition()
        if self.m_pMapSize then
            y = self.m_pMapSize.height - y
        end
        local datalist = {}
        for i=1,#list do
            local item = list[i]
            if #datalist > 10 then
                break
            end
            local dvec = item:GetHeroPos()
            local dx = x - dvec.x
            local dy = y - dvec.y
            if (dx*dx + dy*dy) < 800*800 and item:GetFactionId() == 0 then
                local temp = LApplayInfo:New()
                temp.roleId = item:GetId()
                temp.name = item:GetName()
                temp.level = item:GetLv()
                temp.zhandouli = item:GetZhandouli()
                temp.professional = item:GetProfessional()
                temp.sex = item:GetSex()
                table.insert(datalist, temp)
            end
        end
        self:LoadData(datalist)
        datalist = nil
    end
    local msg = GetMapHerosMsg:new(CEnum.MapEvent.LuaGetMapHeros,GetMapHeroListCallback)
    self:SendMsg(msg)
end

-- -----------------------------------
function BangPaiInvitePopup:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_tableCount = nil
    self.m_isDragging = nil
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_pTablePanel = nil
    self.m_datas = nil
    self.m_selectIndex = nil

    self.m_nameLabel = nil
    self.m_isInvited = nil
end

-- -----------------------------------
function BangPaiInvitePopup:RegistMsgs()
    self.msgIds = {
        LUISocialEvent.updateSearchPlayer,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function BangPaiInvitePopup:ProcessEvent(msg)
    if msg.msgId == LUISocialEvent.updateSearchPlayer then
        local list = msg.value
        local datalist = {}
        for i=1,#list do
            local data = list[i]
            local temp = LApplayInfo:New()
            temp.roleId = data.id
            temp.name = data.name
            temp.level = data.level
            temp.zhandouli = data.fightPower
            temp.head = data.head
            temp.sex = data.sex
            table.insert(datalist, temp)
        end
        self:LoadData(datalist)
        datalist = nil
    end
end

function BangPaiInvitePopup:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    Utils:SendMsg(LUISecondClassBgEvent.SetCloseCallback, handler(self, LUIBase.RemoveUI))
    Utils:SendMsg(LUISecondClassBgEvent.SetTitle, GUITips.RSI_FACTION_TITLE2)
end

-- -----------------------------------
function BangPaiInvitePopup:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/bangpai/GangsIntoLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

-- -----------------------------------
function BangPaiInvitePopup:InitUIControl()
    local panel = self.m_pUILayer:getChildByName("IntoGuild")

    local pEnterBtn = panel:getChildByName("EnterBtn")
    pEnterBtn:addClickEventListener(function()
        self:inviteAll()
    end)
	self:MarkIntaractCObj(pEnterBtn)
    local pSearchBg = panel:getChildByName("SearchBg")
    self.m_nameLabel = pSearchBg:getChildByName("TextField")
    self.m_nameLabel:setString("")
    self.m_nameLabel:setCursorEnabled(true)

    local pSearchBtn = pSearchBg:getChildByName("SearchBtn")
    pSearchBtn:addClickEventListener(function()
        self:searchByName()
    end)
	self:MarkIntaractCObj(pSearchBtn)
    local pFlushBtn = pSearchBg:getChildByName("Button_1")
    pFlushBtn:addClickEventListener(function()
        self:initData()
    end)
	self:MarkIntaractCObj(pFlushBtn)
    local pListBg = panel:getChildByName("ListBg")
    self.m_pTablePanel = pListBg:getChildByName("List")

    self.m_pGridCell = panel:getChildByName("Name")
    self.m_pGridCell:setVisible(false)
    self.m_pGridCell:setTouchEnabled(false)
end

function BangPaiInvitePopup:LoadData(list)
    self.m_datas = list
    self.m_tableCount = #list
    if self.m_pTableView == nil then
        self.m_pTableView = self:InitTableView(self.m_pTablePanel)
    end
    self.m_pTableView:reloadData()
end

function BangPaiInvitePopup:InitTableView(tbPanel)
    local cfg = {}
    cfg.tbPanel = tbPanel
    cfg.cellSizeForTable = function(sender,idx)
        local size = self.m_pGridCell:getContentSize()
        return size.width, size.height
    end
    cfg.tableCellAtIndex = function(sender, idx)
        return self:TableCellAtIndex(sender, idx)
    end

    cfg.numberOfCellsInTableView = function() 
        return self.m_tableCount
    end

    return Utils:createTableView(cfg)
end

function BangPaiInvitePopup:TableCellAtIndex(sender, idx)
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
        self:updateItem(cellChild, self.m_datas[idx+1], idx)
    end
    return cell
end

function BangPaiInvitePopup:updateItem(cell, info, idx)
    local filestr = AppDef:GetHeroPicFileName(info.head, AppDef.HeadType.HERO_IMAGE_HEAD_ROUND);
    local pIcon = cell:getChildByName("Icon")
    pIcon:loadTexture(filestr, ccui.TextureResType.localType)

    local pRoleName = cell:getChildByName("RoleName")
    pRoleName:setString(info.name)

    local pCareerName = cell:getChildByName("CareerName")
    pCareerName:setString(AppDef:GetHeroProfessionalName(info.professional))

    local lev = GUITips.RSI_FACTION_MSG7 .. tostring(info.level)
    local pLevelNum = cell:getChildByName("LevelNum")
    pLevelNum:setString(lev)

    local pValue = cell:findChildByName("Power/Value")
    pValue:setString(Utils:getPowerStr(info.zhandouli))

    local pButton = cell:getChildByName("Button")
    local function btnTouched(sender)
        self:invite(sender:getTag() + 1)
    end
    pButton:setTag(idx)
    pButton:setSwallowTouches(false)
    pButton:addClickEventListener(btnTouched)
	self:MarkIntaractCObj(pButton)
end

function BangPaiInvitePopup:showTips(msg)
    Utils:ShowScrollTips(msg)
end

function BangPaiInvitePopup:invite(idx)
    if idx > #self.m_datas then
        return
    end

    local info = self.m_datas[idx]
    LuaNetSendMsg:QueryFactionInvite(info.roleId)

    self.m_isInvited[idx] = true

    table.remove(self.m_datas, idx)
    self.m_tableCount = #self.m_datas

    local offset = self.m_pTableView:getContentOffset()
    self.m_pTableView:reloadData()

    local min = self.m_pTableView:minContainerOffset().y
    local max = self.m_pTableView:maxContainerOffset().y
    local cellHeight = self.m_pGridCell:getContentSize().height
    offset.y = math.max(math.min(offset.y+cellHeight, max), min)

    self.m_pTableView:setContentOffset(offset)
end

function BangPaiInvitePopup:inviteAll()
    if #self.m_datas > 0 then
        LuaNetSendMsg:QueryFactionInviteAll(self.m_datas)
        self.m_datas = {}
        self.m_tableCount = 0
        self.m_pTableView:reloadData()
    end
end

function BangPaiInvitePopup:searchByName()
    local name = self.m_nameLabel:getString()
    if #name == 0 then
        Utils:ShowScrollTips(GUITips.RSI_INPUT_ERROR)
        return
    end
    local index = -1
    for i=1,#self.m_datas do
        if name == self.m_datas[i].name then
            index = i
            break
        end
    end
    if index == -1 then
        LuaNetSendMsg:QuerySimpleSerchPlayer(name)
    else
        local min = self.m_pTableView:minContainerOffset().y
        local max = self.m_pTableView:maxContainerOffset().y
        if min < 0 then
            local cellHeight = self.m_pGridCell:getContentSize().height
            local offsetY = max - cellHeight * (#self.m_datas - index)
            offsetY = math.min(math.max(offsetY, min), max)
            local offset = self.m_pTableView:getContentOffset()
            self.m_pTableView:setContentOffsetInDuration(cc.p(offset.x, offsetY), 0.1)
        end
    end
end

return BangPaiInvitePopup