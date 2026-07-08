local BangPaiInviteList = LUIBase:New()
BangPaiInviteList.__index = BangPaiInviteList

-- -----------------------------------
function BangPaiInviteList:New()
    local o = {}
    setmetatable(o, BangPaiInviteList)
    o:Init()
    return o
end

-- -----------------------------------
function BangPaiInviteList:Init()
    self.Script = "BangPai.BangPaiInviteList"
    --table view相关
    self.m_tableCount = 0
    self.m_isDragging = false
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_pTablePanel = nil
    self.m_datas = {}

    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    self:initData()
end

function BangPaiInviteList:initData()
    self:LoadData(LRoleDataMgr.Faction.InviteList)
end

-- -----------------------------------
function BangPaiInviteList:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_tableCount = nil
    self.m_isDragging = nil
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_pTablePanel = nil
    self.m_datas = nil
end

function BangPaiInviteList:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    Utils:SendMsg(LUISecondClassBgEvent.SetCloseCallback, handler(self, BangPaiInviteList.RemoveUI))
    Utils:SendMsg(LUISecondClassBgEvent.SetTitle, GUITips.RSI_FACTION_TITLE2)
end

-- -----------------------------------
function BangPaiInviteList:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/GuildApplyListLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

-- -----------------------------------
function BangPaiInviteList:InitUIControl()
    local panel = self.m_pUILayer:getChildByName("InviteGuild")

    local pBtn1 = panel:getChildByName("Btn1")
    local _ = pBtn1 and pBtn1:setVisible(false)
    local pBtn2 = panel:getChildByName("Btn2")
    local _ = pBtn2 and pBtn2:setVisible(false)

    local pListBg = panel:getChildByName("ListBg")
    self.m_pTablePanel = pListBg:getChildByName("List")

    self.m_pGridCell = panel:getChildByName("Name")
    self.m_pGridCell:setVisible(false)
    self.m_pGridCell:setTouchEnabled(false)
end

function BangPaiInviteList:LoadData(list)
    self.m_datas = list
    self.m_tableCount = #list
    self.m_pTableView = self:InitTableView(self.m_pTablePanel)
    self.m_pTableView:reloadData()
end

function BangPaiInviteList:InitTableView(tbPanel)
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

function BangPaiInviteList:TableCellAtIndex(sender, idx)
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

function BangPaiInviteList:updateItem(cell, info, idx)
    local filestr = Utils:GetHeroIconRes(info.invtProfessional, AppDef.HeadIconResType.Square)
    local pIcon = cell:getChildByName("Icon")
    pIcon:loadTexture(filestr)

    local pRoleName = cell:getChildByName("RoleName")
    pRoleName:setString(info.invtName)

    local pCareerName = cell:getChildByName("CareerName")
    pCareerName:setVisible(false)

    local lev = GUITips.RSI_FACTION_MSG7 .. tostring(info.invtLevel)
    local pLevelNum = cell:getChildByName("LevelNum")
    pLevelNum:setString(lev)

    local pbg_CombatEffetiveness = cell:getChildByName("bg_CombatEffetiveness")
    pbg_CombatEffetiveness:setVisible(false)

    local pGuildBg = cell:getChildByName("GuildBg")
    pGuildBg:setVisible(true)
    local pName = pGuildBg:getChildByName("zhanli")
    pName:setString(info.bangPaiName)

    local pYesButton = cell:getChildByName("Button")
    pYesButton:setVisible(true)
    local function yesTouched(sender)
        self:agree(sender:getTag())
    end
    pYesButton:setTag(idx)
    pYesButton:setSwallowTouches(false)
    pYesButton:addClickEventListener(yesTouched)
	self:MarkIntaractCObj(pYesButton)

    local pRefuseButton = cell:getChildByName("Button_2")
    pRefuseButton:setVisible(true)
    local function refuseTouched(sender)
        self:refuse(sender:getTag())
    end
    pRefuseButton:setTag(idx + 1000)
    pRefuseButton:setSwallowTouches(false)
    pRefuseButton:addClickEventListener(refuseTouched)
	self:MarkIntaractCObj(pRefuseButton)
end

function BangPaiInviteList:agree(index)
    local info = self.m_datas[index]
    if info == nil then
        return
    end
    LuaNetSendMsg:QueryFactionDealInvite(1, info.invideRoleId)
end

function BangPaiInviteList:refuse(index)
    local idx = index - 1000
    local info = self.m_datas[idx]
    if info == nil then
        return
    end
    LuaNetSendMsg:QueryFactionDealInvite(0, info.invideRoleId)
    
    table.remove(self.m_datas, idx)
    self.m_tableCount = #self.m_datas
    
    local offset = self.m_pTableView:getContentOffset()
    self.m_pTableView:reloadData()

    local min = self.m_pTableView:minContainerOffset().y
    local max = self.m_pTableView:maxContainerOffset().y
    local cellHeight = self.m_pGridCell:getContentSize().height
    offset.y = math.max(math.min(offset.y+cellHeight, max), min)
    
    self.m_pTableView:setContentOffset(offset)

    if self.m_tableCount == 0 then
        Utils:SendMsg(LUIMainEvent.CheckFactionBtn)
    end
end

return BangPaiInviteList