local BangPaiEventPopup = LUIBase:New()
BangPaiEventPopup.__index = BangPaiEventPopup


local BangPaiDef = require("View.BangPai.BangPaiDef")
-- -----------------------------------
function BangPaiEventPopup:New()
    local o = {}
    setmetatable(o, BangPaiEventPopup)
    o:Init()
    return o
end

-- -----------------------------------
function BangPaiEventPopup:Init()
    self.Script = "BangPai.BangPaiEventPopup"
    --table view相关
    self.m_tableCount = 0
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_pTablePanel = nil
    self.m_datas = {}
    self.m_selectIndex = 0
    self:RegistMsgs();
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    self:initData()
end

function BangPaiEventPopup:initData()
    self:LoadData(LRoleDataMgr.Faction:GetManorInfo().VecLog)
    LuaNetSendMsg:QueryFactionZoneInfo();
end

function BangPaiEventPopup:RegistMsgs()
    self.msgIds = {
        LUIBangPaiEvent.UpdateManorInfo,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function BangPaiEventPopup:ProcessEvent(msg)
    if msg.msgId == LUIBangPaiEvent.UpdateManorInfo then
        if LRoleDataMgr.Faction:GetManorInfo().VecLog == nil then
            self.m_tableCount = 0
        else
            self.m_datas = LRoleDataMgr.Faction:GetManorInfo().VecLog
            self.m_tableCount = #LRoleDataMgr.Faction:GetManorInfo().VecLog
        end
        self.m_pTableView:reloadData()
    end
end

-- -----------------------------------
function BangPaiEventPopup:onExit()
    self:Destory()
    self.m_tableCount = nil
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_pTablePanel = nil
    self.m_datas = nil
    self.m_selectIndex = nil
    self.m_pUILayer = nil
    self.m_fontSize = nil
    self.m_fontColor = nil
    self.m_descSize = nil
end
-- -----------------------------------
function BangPaiEventPopup:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    Utils:SendMsg(LUISecondClassBgEvent.SetCloseCallback, handler(self, LUIBase.RemoveUI))
    Utils:SendMsg(LUISecondClassBgEvent.SetTitle, GUITips.RSI_FACTION_TITLE4)
end

-- -----------------------------------
function BangPaiEventPopup:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/bangpai/GangsEventLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

-- -----------------------------------
function BangPaiEventPopup:InitUIControl()
    local panel = self.m_pUILayer:getChildByName("EventPopup")

    self.m_pTablePanel = self.m_pUILayer:findChildByName("EventPopup/Bg/List")

    self.m_pGridCell = self.m_pUILayer:findChildByName("EventPopup/Name")
    self.m_pGridCell:setVisible(false)
    self.m_pGridCell:setTouchEnabled(false)

    local pCareerName = self.m_pGridCell:getChildByName("CareerName")
    self.m_fontSize = pCareerName:getFontSize()
    self.m_fontColor = pCareerName:getTextColor()
    self.m_descSize = pCareerName:getContentSize()
end

function BangPaiEventPopup:LoadData(list)
    if list == nil then
        self.m_tableCount = 0
    else
        self.m_datas = list
        self.m_tableCount = #list
    end
    self.m_pTableView = self:InitTableView(self.m_pTablePanel)
    self.m_pTableView:reloadData()

    Utils:SetRedDotState(RedDotDef.ID.BPShiJian, false);
end

function BangPaiEventPopup:InitTableView(tbPanel)
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

    cfg.scrollViewDidScroll = function(view)end

    cfg.tableCellTouched = function(sender, cell)
        return self:TableCellTouched(cell:getIdx())
    end

    return Utils:createTableView(cfg)
end

function BangPaiEventPopup:TableCellTouched(idx)
    self.m_selectIndex = idx
    local offset = self.m_pTableView:getContentOffset()
    self.m_pTableView:reloadData()
    self.m_pTableView:setContentOffset(offset)
end

function BangPaiEventPopup:TableCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild = nil
    
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pGridCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cell:addChild(cellChild)
        local pCareerName = cellChild:getChildByName("CareerName")
        Utils:CreateColorText2(cellChild, pCareerName)
    else
        cellChild = cell:getChildByTag(123)
    end
    if cellChild ~= nil then
        self:updateItem(cellChild, self.m_datas[idx+1], idx)
    end
    return cell
end

function BangPaiEventPopup:updateItem(cell, info, idx)
    local pBg = cell:getChildByName("Bg")
    pBg:setVisible(math.fmod(idx, 2) == 1)

    local pChooseBg = cell:getChildByName("ChooseBg")
    pChooseBg:setVisible(idx == self.m_selectIndex)

    local pPlaceNum = cell:getChildByName("PlaceNum")
    pPlaceNum:setString(GUITipsBPEventIdMap[info.type])

    local pPlaceName = cell:getChildByName("PlaceName")
    pPlaceName:setString(info.dateStr)

    local pCareerName = cell:getChildByName("CareerName")
    pCareerName:setString(info.log)
end

return BangPaiEventPopup