local LunDaoRankUI = LUIBase:New()
LunDaoRankUI.__index = LunDaoRankUI
-----------------------------------
function LunDaoRankUI:New()
    local o = {}
    setmetatable(o, LunDaoRankUI)
    o:Init()
    return o
end
-----------------------------------
function LunDaoRankUI:Init()
    self.Script = "Activity.LunDaoRankUI"
    --------------------------------------------------
    self.m_pGridCell = nil
    self.m_pGridCellSize = nil
    --------------------------------------------------
    self.m_lTableCount = 0
    self.m_pLTableView = nil
    self.m_pLTablePanel = nil
    self.m_lDatas = nil
    --------------------------------------------------
    self.m_rTableCount = 0
    self.m_pRTableView = nil
    self.m_pRTablePanel = nil
    self.m_rDatas = nil
    --------------------------------------------------
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    --------------------------------------------------
end
-----------------------------------
function LunDaoRankUI:onExit()
    self:Destory()
    self.Script = nil
    self.m_pUILayer = nil
    --------------------------------------------------
    self.m_pGridCell = nil
    self.m_pGridCellSize = nil
    --------------------------------------------------
    self.m_lTableCount = nil
    self.m_pLTableView = nil
    self.m_pLTablePanel = nil
    Utils:FreeTable(self.m_lDatas)
    self.m_lDatas = nil
    --------------------------------------------------
    self.m_rTableCount = nil
    self.m_pRTableView = nil
    self.m_pRTablePanel = nil
    Utils:FreeTable(self.m_rDatas)
    self.m_rDatas = nil

    Utils:FreeTable(self.m_data)
    self.m_data = nil

    self.m_pLeftRankTitleLabel = nil
    self.m_pRightRankTitleLabel = nil
    self.m_pLeftRankLabel = nil
    self.m_pLeftRankText = nil
    self.m_pRightRankLabel = nil
    self.m_pRightRankText = nil
    self.m_pLeftScoreLabel = nil
    self.m_pLeftScoreText = nil
    self.m_pRightScoreLabel = nil
    self.m_pRightScoreText = nil
end
-----------------------------------
function LunDaoRankUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/Lundao2Layer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
    if self.m_pUILayer ~= nil then
        self.m_pUILayer:setVisible(false)
    end
end
-----------------------------------
function LunDaoRankUI:InitUIControl()
    local panel = self.m_pUILayer:getChildByName("Panel_1")
    local pRanking = panel:getChildByName("Ranking")
    --------------------------------------------------
    self.m_pGridCell = pRanking:getChildByName("Name")
    self.m_pGridCell:setTouchEnabled(false)
    self.m_pGridCellSize = self.m_pGridCell:getContentSize()
    -------------------------------------------------- 
    self.m_pLTablePanel = pRanking:getChildByName("ListView_1")
    self.m_pLTablePanel:setTouchEnabled(false)
    self.m_pLTableView = self:InitTableView(self.m_pLTablePanel)
    -------------------------------------------------- 
    self.m_pRTablePanel = pRanking:getChildByName("ListView_2")
    self.m_pRTablePanel:setTouchEnabled(false)
    self.m_pRTableView = self:InitRTableView(self.m_pRTablePanel)
    -------------------------------------------------- 
    self.m_pLeftRankTitleLabel = pRanking:getChildByName("Image_1"):getChildByName("Text")
    self.m_pRightRankTitleLabel = pRanking:getChildByName("Image_2"):getChildByName("Text")

    local pPersonalBg = pRanking:getChildByName("PersonalBg")
    self.m_pLeftRankLabel = pPersonalBg:getChildByName("Ranking_1")
    self.m_pLeftRankText = self.m_pLeftRankLabel:getChildByName("Value")
    
    self.m_pRightRankLabel = pPersonalBg:getChildByName("Ranking_2")
    self.m_pRightRankText = self.m_pRightRankLabel:getChildByName("Value")
    -------------------------------------------------- 
    self.m_pLeftScoreLabel = pPersonalBg:getChildByName("PersonalScore")
    self.m_pLeftScoreText = self.m_pLeftScoreLabel:getChildByName("Value")

    self.m_pRightScoreLabel = pPersonalBg:getChildByName("ServerScore")
    self.m_pRightScoreText = self.m_pRightScoreLabel:getChildByName("Value")
    -------------------------------------------------- 
    local pCloseBtn = pRanking:getChildByName("CloseBtn")
    pCloseBtn:addClickEventListener(function(sender)
        self:setVisible(false)
    end)
	self:MarkIntaractCObj(pCloseBtn)
end
-----------------------------------
function LunDaoRankUI:RegistMsgs()
    self.msgIds = 
    {
        LUILunDaoEvent.UpdateRankEvent,
        LUIMiJingEvent.UpdateRankEvent,
    }
    self:RegistSelf(self, self.msgIds)
end
-----------------------------------
function LunDaoRankUI:ProcessEvent(msg)
    if msg.msgId == LUILunDaoEvent.UpdateRankEvent then
        self:UpdateRank(msg.value)
    elseif msg.msgId == LUIMiJingEvent.UpdateRankEvent then
        self:UpdateRank(msg.value)
    end
end
----------------------------------
function LunDaoRankUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
----------------------------------
function LunDaoRankUI:UpdateRank(datas)
    if datas == nil then
        return
    end
    Utils:FreeTable(self.m_data)
    self.m_data = nil
    self.m_data = datas

    Utils:FreeTable(self.m_lDatas)
    self.m_lDatas = nil
    self.m_lDatas = datas.leftRankList or {}
    self.m_lTableCount = #self.m_lDatas
    self.m_pLTableView:reloadData()

    Utils:FreeTable(self.m_rDatas)
    self.m_rDatas = nil
    self.m_rDatas = datas.rightRankList or {}
    self.m_rTableCount = #self.m_rDatas
    self.m_pRTableView:reloadData()

    self:UpdateRankLabel()
    self:UpdateMyInfo()

    self.m_pUILayer:setVisible(true)
end
----------------------------------
function LunDaoRankUI:cellSizeForTable(sender,idx)
    return self.m_pGridCellSize.width, self.m_pGridCellSize.height
end
----------------------------------
function LunDaoRankUI:InitTableView(tbPanel)
    local cfg = {}
    cfg.tbPanel = tbPanel
    cfg.cellSizeForTable = function(sender,idx)
        return self:cellSizeForTable(sender, idx)
    end
    cfg.tableCellAtIndex = function(sender, idx)
        return self:TableCellAtIndex(sender, idx)
    end

    cfg.numberOfCellsInTableView = function() 
        return self.m_lTableCount
    end

    return Utils:createTableView(cfg)
end
----------------------------------
function LunDaoRankUI:TableCellAtIndex(sender, idx)
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
        self:updateItem(cellChild, self.m_lDatas[idx+1], idx+1)
    end
    return cell
end
----------------------------------
function LunDaoRankUI:updateItem(cell, info, idx)
    if cell == nil or info == nil then
        return
    end

    local pBg = cell:getChildByName("Bg")
    if pBg ~= nil then
        pBg:setVisible(math.fmod(idx, 2) == 1)
    end

    local pRank = cell:getChildByName("PlaceNum")
    if pRank ~= nil then
        pRank:setString(tostring(info.rank or 0))
    end

    local pName = cell:getChildByName("PlaceName")
    if pName ~= nil then
        pName:setString(info.name)
    end

    local pScore = cell:getChildByName("HurtValue")
    if pScore ~= nil then
        pScore:setString(tostring(info.score or 0))
    end
end
----------------------------------
function LunDaoRankUI:InitRTableView(tbPanel)
    local cfg = {}
    cfg.tbPanel = tbPanel
    cfg.cellSizeForTable = function(sender,idx)
        return self:cellSizeForTable(sender, idx)
    end
    cfg.tableCellAtIndex = function(sender, idx)
        return self:RTableCellAtIndex(sender, idx)
    end

    cfg.numberOfCellsInTableView = function() 
        return self.m_rTableCount
    end

    return Utils:createTableView(cfg)
end
----------------------------------
function LunDaoRankUI:RTableCellAtIndex(sender, idx)
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
        self:updateRItem(cellChild, self.m_rDatas[idx+1], idx+1)
    end
    return cell
end
----------------------------------
function LunDaoRankUI:updateRItem(cell, info, idx)
    if cell == nil or info == nil then
        return
    end
    local pBg = cell:getChildByName("Bg")
    if pBg ~= nil then
        pBg:setVisible(math.fmod(idx, 2) == 1)
    end
    
    local pRank = cell:getChildByName("PlaceNum")
    if pRank ~= nil then
        pRank:setString(tostring(info.rank or 0))
    end

    local pName = cell:getChildByName("PlaceName")
    if pName ~= nil then
        pName:setString(info.name or "")
    end

    local pScore = cell:getChildByName("HurtValue")
    if pScore ~= nil then
        pScore:setString(tostring(info.score or 0))
    end
end
----------------------------------
function LunDaoRankUI:setVisible(isVisible)
    if isVisible then
        self.m_pUILayer:setVisible(true)
    else
        self:RemoveUI()
    end
end
----------------------------------
function LunDaoRankUI:UpdateMyInfo()
    if self.m_data == nil then
        return
    end
    local function _setRank(pText, rank)
        if pText == nil then
            return
        end
        if rank and rank > 0 then
            pText:setString(tostring(rank))
        else
            pText:setString("未入榜")
        end
    end
    _setRank(self.m_pLeftRankText, self.m_data.myRankinAll)
    _setRank(self.m_pRightRankText, self.m_data.myRankinSelf)
    self.m_pLeftScoreText:setString(tostring(self.m_data.myScore))
    self.m_pRightScoreText:setString(tostring(self.m_data.serScore))
end
----------------------------------
function LunDaoRankUI:UpdateRankLabel()
    local rankType = self.m_data.rankType or 1
    if rankType == 1 then
        self.m_pLeftRankTitleLabel:setString("跨服：个人积分榜")
        self.m_pRightRankTitleLabel:setString("跨服：本服积分榜")
        self.m_pLeftRankLabel:setString("跨服排名：")
        ccui.Helper:doLayout(self.m_pLeftRankLabel)
        self.m_pRightRankLabel:setString("本服排名：")
        ccui.Helper:doLayout(self.m_pRightRankLabel)
        self.m_pLeftScoreLabel:setString("个人积分：")
        ccui.Helper:doLayout(self.m_pLeftScoreLabel)
        self.m_pRightScoreLabel:setString("本服积分：")
        ccui.Helper:doLayout(self.m_pLeftScoreLabel)
    elseif rankType == 2 then
        self.m_pLeftRankTitleLabel:setString("跨服：个人伤害榜")
        self.m_pRightRankTitleLabel:setString("本服：个人伤害榜")
        self.m_pLeftRankLabel:setString("跨服排名：")
        ccui.Helper:doLayout(self.m_pLeftRankLabel)
        self.m_pRightRankLabel:setString("本服排名：")
        ccui.Helper:doLayout(self.m_pRightRankLabel)
        self.m_pLeftScoreLabel:setString("个人伤害：")
        ccui.Helper:doLayout(self.m_pLeftScoreLabel)
        self.m_pRightScoreLabel:setString("本服伤害：")
        ccui.Helper:doLayout(self.m_pLeftScoreLabel)
    end
end
----------------------------------
return LunDaoRankUI