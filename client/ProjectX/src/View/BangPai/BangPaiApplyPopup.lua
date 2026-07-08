local BangPaiApplyPopup = LUIBase:New()
BangPaiApplyPopup.__index = BangPaiApplyPopup


local BangPaiDef = require("View.BangPai.BangPaiDef")

local ScriptPath = "BangPai.BangPaiApplyPopup"

-- -----------------------------------
function BangPaiApplyPopup:New()
    local o = {}
    setmetatable(o, BangPaiApplyPopup)
    o:Init()
    return o
end

-- -----------------------------------
function BangPaiApplyPopup:Init()
    self.Script = "BangPai.BangPaiApplyPopup"
    --table view相关
    self.m_tableCount = 0
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_pTablePanel = nil
    self.m_datas = {}

    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    self:initData()
end

function BangPaiApplyPopup:initData()
    LuaNetSendMsg:QueryFactionApplyList()
end

-- -----------------------------------
function BangPaiApplyPopup:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_tableCount = nil
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_pTablePanel = nil
    self.m_datas = nil
end

-- -----------------------------------
function BangPaiApplyPopup:RegistMsgs()
    self.msgIds = {
        LUIBangPaiEvent.LoadJoinApplyList
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function BangPaiApplyPopup:ProcessEvent(msg)
    if msg.msgId == LUIBangPaiEvent.LoadJoinApplyList then
        self:LoadData(msg.value)
    end
end

function BangPaiApplyPopup:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    Utils:SendMsg(LUISecondClassBgEvent.SetCloseCallback, handler(self, LUIBase.RemoveUI))
    Utils:SendMsg(LUISecondClassBgEvent.SetTitle, GUITips.RSI_FACTION_TITLE3)
end

-- -----------------------------------
function BangPaiApplyPopup:InitViewSize()
    -- print("BangPaiApplyPopup")
    self:CreateUINode("csd/bangpai/GangsApplyListLayer.csb");
end

-- -----------------------------------
function BangPaiApplyPopup:InitUIControl()
    local panel = self.m_pUILayer:getChildByName("InviteGuild")

    local pBtn1 = panel:getChildByName("Btn1")
    pBtn1:addClickEventListener(function()
        self:DealAllApply(1)
    end)
	self:MarkIntaractCObj(pBtn1)
    local pBtn2 = panel:getChildByName("Btn2")
    pBtn2:addClickEventListener(function()
        self:DealAllApply(2)
    end)
	self:MarkIntaractCObj(pBtn2)
    local pListBg = panel:getChildByName("ListBg")
    self.m_pTablePanel = pListBg:getChildByName("List")

    self.m_pGridCell = panel:getChildByName("Name")
    self.m_pGridCell:setVisible(false)
    self.m_pGridCell:setTouchEnabled(false)
end

function BangPaiApplyPopup:LoadData(list)
    self.m_datas = list or {}
    self.m_tableCount = #list
    self.m_pTableView = self:InitTableView(self.m_pTablePanel)
    self.m_pTableView:reloadData()
    if self.m_tableCount == 0 then
        Utils:SetRedDotState(RedDotDef.ID.BPShenQing, false)
    end
end

function BangPaiApplyPopup:InitTableView(tbPanel)
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

function BangPaiApplyPopup:TableCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild = nil
    
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pGridCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cell:addChild(cellChild)

        local pButton = cellChild:getChildByName("Button")
        pButton:setSwallowTouches(false)
        pButton:addClickEventListener(function(sender)
            self:agree(sender:getTag())
        end)
        self:MarkIntaractCObj(pButton)
    else
        cellChild = cell:getChildByTag(123)
    end
    if cellChild ~= nil then
        self:updateItem(cellChild, self.m_datas[idx+1], idx)
    end
    return cell
end

function BangPaiApplyPopup:updateItem(cell, info, idx)
    local filestr = Utils:GetHeroIconRes(info.professional, AppDef.HeadIconResType.Square)
    local pIcon = cell:getChildByName("Icon")
    pIcon:loadTexture(filestr)

    local pRoleName = cell:getChildByName("RoleName")
    pRoleName:setString(info.name)

    -- local str = AppDef:GetHeroProfessionalName(info.professional)
    -- local pCareerName = cell:getChildByName("CareerName")
    -- pCareerName:setString(str or "")

    local lev = GUITips.RSI_FACTION_MSG7 .. tostring(info.level)
    local pLevelNum = cell:getChildByName("LevelNum")
    pLevelNum:setString(lev)

    local pbg_CombatEffetiveness = cell:getChildByName("Power")
    local pValue = pbg_CombatEffetiveness:getChildByName("Value")

    local powerValue, isWan = Utils:getNewPowerStr(info.zhandouli);
    pValue:setString(powerValue);
    if isWan == true then
        pValue:getChildByName("Wan"):setVisible(true)
        pValue:getChildByName("Wan"):setPositionX(pValue:getContentSize().width)
    else
        pValue:getChildByName("Wan"):setVisible(false)
    end

    -- pValue:setString(Utils:getPowerStr(info.zhandouli))

    cell:getChildByName("GuildBg"):setVisible(false)

    local pButton = cell:getChildByName("Button")
    pButton:setTag((idx+1)*100 + 1)
end

function BangPaiApplyPopup:showTips(msg)
    Utils:ShowScrollTips(msg)
end

function BangPaiApplyPopup:agree(index)
    local idx = math.floor(index/100)
    local typ = math.fmod(index, 100)

    if idx > #self.m_datas then
        return
    end

    local info = self.m_datas[idx]
    LuaNetSendMsg:QueryFactionDealApply(typ, info.roleId)

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

function BangPaiApplyPopup:DealAllApply(tag)
    if self.m_datas == nil then
        return
    end
    if #self.m_datas > 0 then
        if tag == 1 then --全部同意
            LuaNetSendMsg:QueryFactionDealAllApply(1)
        elseif tag == 2 then --全部拒绝
            LuaNetSendMsg:QueryFactionDealAllApply(0)
        end
        self.m_datas = {}
        self.m_tableCount = 0
        self.m_pTableView:reloadData()
    end
end

return BangPaiApplyPopup