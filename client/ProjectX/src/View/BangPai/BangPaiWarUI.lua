local BangPaiWarUI = LUIBase:New()
BangPaiWarUI.__index = BangPaiWarUI


--local BangPaiDef = require("View.BangPai.BangPaiDef")
--local ShopDef = require("View.Shop.ShopDef")
local ScriptPath = "BangPai.BangPaiWarUI"

-- -----------------------------------
function BangPaiWarUI:New(bpUI)
    local o = LUIBase:New()
    setmetatable(o, BangPaiWarUI)
    o:Init(bpUI)
    return o
end

-- -----------------------------------
function BangPaiWarUI:Init(bpUI)
    self.m_bpUI = bpUI
    self.m_pMessageBoxUI = nil
    self.m_pBasicNews = nil
    self.m_pDetailedNews = nil
    self.m_pGongGaoButtons = {}
    --self.m_schedule = nil

    --table view相关
    self.m_pTableView = nil
    if self.m_pGridCell then
        self.m_pGridCell:release()
        self.m_pGridCell = nil
    end
    self.m_pTablePanel = nil
    self.m_datas = {}

    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()

    LuaNetSendMsg:QueryBangPaiWarInfo(1)

end

-- -----------------------------------
function BangPaiWarUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
    self.m_bpUI = nil
    self.m_pMessageBoxUI = nil
    self.m_pBasicNews = nil
    self.m_pDetailedNews = nil
    self.m_pGongGaoButtons = nil
    --self.m_schedule = nil

    --table view相关
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_pTablePanel = nil
    self.m_datas = nil
end

-- -----------------------------------
function BangPaiWarUI:RegistMsgs()
    self.msgIds = {
        LUIBangPaiEvent.UpdateBangPaiWarInfo,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function BangPaiWarUI:ProcessEvent(msg)
    if msg.msgId == LUIBangPaiEvent.UpdateBangPaiWarInfo then
        self:RefreshPage()
    end
end

function BangPaiWarUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

-- -----------------------------------
function BangPaiWarUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/GuildWarLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

-- -----------------------------------
function BangPaiWarUI:InitUIControl()
    local panel = self.m_pUILayer:getChildByName("Node")
    local pGuildNews = panel:getChildByName("Guild")
    local guildListPanel = pGuildNews:getChildByName("GuildList")

    self.m_pTablePanel = guildListPanel:getChildByName("List")
    self.m_pGridCell = guildListPanel:getChildByName("Name")
    self.m_pGridCell:setTouchEnabled(false)
    self.m_pGridCell:retain()
    self.m_pGridCell:removeFromParent() 
    ---------------------------------------------
    local conditionPanel1 = pGuildNews:getChildByName("Condition_1")
    self.m_bpLvLabel = conditionPanel1:getChildByName("Name")
    self.m_bpLvImg = conditionPanel1:getChildByName("Image")
    self.m_bpLvLabel:getChildByName("Text"):setVisible(false)
    local conditionPanel2 = pGuildNews:getChildByName("Condition_2")
    self.m_bpMemCntLabel = conditionPanel2:getChildByName("Name")
    self.m_bpMemCntImg = conditionPanel2:getChildByName("Image")
    self.m_bpMemCntLabel:getChildByName("Text"):setVisible(false)
    local conditionPanel3 = pGuildNews:getChildByName("Condition_3")
    self.m_roleLvLabel = conditionPanel3:getChildByName("Name")
    self.m_roleLvImg = conditionPanel3:getChildByName("Image")
    self.m_roleLvLabel:getChildByName("Text"):setVisible(false)
    local conditionPanel4 = pGuildNews:getChildByName("Condition_4")
    self.m_joinTimeLabel = conditionPanel4:getChildByName("Name")
    self.m_joinTimeImg = conditionPanel4:getChildByName("Image")
    self.m_joinTimeLabel:getChildByName("Text"):setVisible(false)
    local conditionPanel5 = pGuildNews:getChildByName("Condition_5")
    self.m_openTimeLabel = conditionPanel5:getChildByName("Text")
    self.m_openTimeImg = conditionPanel5:getChildByName("Image")

    self.m_tipLabel = pGuildNews:getChildByName("Tips"):getChildByName("Text")
    ---------------------------------------------
    --local pHelpBtn = pBasicNews:getChildByName("HelpBtn")
    --pHelpBtn:addClickEventListener(function(sender)
    --    self:helpButtonCallback()
    --end)
    ---------------------------------------------
    self.m_enterBtn = pGuildNews:getChildByName("Btn")
    self:AddTouchEvt()
end

function BangPaiWarUI:AddTouchEvt()
    self.m_enterBtn:addClickEventListener(function(sender)
        self:JoinWar()
    end)
	self:MarkIntaractCObj(self.m_enterBtn)
end

function BangPaiWarUI:JoinWar()
    --进入帮战准备场景
    --LuaNetSendMsg:QueryBangPaiWarInfo(6)
    -- local info = LBangPaiWarDataMgr:GetWarData()
    -- if not info.startFlag then 
    --     Utils:ShowScrollTips(GUITips.RSI_FACTION_MGS210)
    --     return
    -- end
    -- if not info.bpLvflag or not info.bpMemNumflag or not info.roleLvflag or not info.enterTimeflag then
    --     Utils:ShowScrollTips(GUITips.RSI_FACTION_MGS209)
    --     return
    -- end
    --寻路到帮派接引人
    LGameMsg.m_autoPathMsg:ChangeToStart(11,-1,-1,0,bit.lshift(10,16),true,true, nil)
    self:SendMsg(LGameMsg.m_autoPathMsg)
	LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, true)
	self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function BangPaiWarUI:ShowBangPaiList(list)
    --local mybangpaiInfo = LRoleDataMgr.Faction.Info
    --local myBangPaiId = mybangpaiInfo.id
    local pScrollViewSize = self.m_pTablePanel:getContentSize()

    if self.m_pTableView ~= nil then
        self.m_pTableView:removeFromParent(true)
        self.m_pTableView = nil
    end
    self.m_pTableView = self:InitTableView(self.m_pTablePanel)

    --TODO:注意顺序
    self.m_datas = list

    self.m_tableCount = #list
    self.m_pTableView:reloadData()
end

function BangPaiWarUI:InitTableView(tbPanel)
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

--    cfg.tableCellTouched = function(sender, cell)
--        return self:TableCellTouched(cell:getIdx())
--    end

    return Utils:createTableView(cfg)
end

--function BangPaiWarUI:TableCellTouched(idx)
--    if idx == self.m_selectIndex then
--        return
--    end

--    self.m_selectIndex = idx

--    if idx == -1 and self.m_pMyTableCell ~= nil then
--        self:setSelect(self.m_pMyTableCell, true)
--        self:setGongGao(LRoleDataMgr.Faction.Info.gongGao)
--    else
--        self:setSelect(self.m_pMyTableCell, false)
--        self:setGongGao((self.m_datas[idx+1] and {self.m_datas[idx+1].gongGao} or {""})[1])
--    end

--    if self.m_pTableView ~= nil then
--        local offset = self.m_pTableView:getContentOffset()
--        self.m_pTableView:reloadData()
--        self.m_pTableView:setContentOffset(offset)
--    end
--end

function BangPaiWarUI:TableCellAtIndex(sender, idx)
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

function BangPaiWarUI:updateItem(cell, info, idx, myBangPaiId)
    local bMyItem = (myBangPaiId==info.id)
    local color = bMyItem and cc.c4b(0,255,0,255) or cc.c4b(110,56,48,255)

    --self:setSelect(cell, self.m_selectIndex == idx)

    local bShowBg = false
    if myBangPaiId > 0 then
        bShowBg = (math.fmod(idx, 2) == 0)
    else
        bShowBg = math.fmod(idx, 2) == 1
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
    pPeopleNum:setString(tostring(info.memCnt))
    pPeopleNum:setTextColor(color)

    local pLeaderName = cell:getChildByName("LeaderName")
    pLeaderName:setString(info.masterName)
    pLeaderName:setTextColor(color)

--    local pShenqingSp = cell:getChildByName("AppliedImage")
--    if pShenqingSp ~= nil then
--        pShenqingSp:setVisible(myBangPaiId == 0 and info.isInAskJoin == 1)
--    end

    local pScore = cell:getChildByName("WarScore")
    pScore:setString(info.score)
    pScore:setTextColor(color)

end

--function BangPaiWarUI:setSelect(cell, bSelected)
--    if cell == nil then
--        return
--    end
--    local pChooseSp = cell:getChildByName("ChooseBg")
--    pChooseSp:setVisible(bSelected)
--end

--function BangPaiWarUI:helpButtonCallback()
--    local str = string.format("%s%s%s%s%s", GUITips.RSI_BP_TIP19, GUITips.RSI_BP_TIP20, GUITips.RSI_BP_TIP21, GUITips.RSI_BP_TIP22, GUITips.RSI_BP_TIP23)

--    local function OKCallback()
--    end
--    local msgData = {
--        okCallback = OKCallback,
--        desc = str
--    }
--    LGameMsg.m_baseMsgWithOne:Change(LUIMsgBoxEvent.ShowMsgBox, msgData)
--    self:SendMsg(LGameMsg.m_baseMsgWithOne)
--end
function BangPaiWarUI:ShowCondition(info)
    if info == nil then return end
    local color = cc.c3b(0x6e,0x38,0x30)
    local imgColor = cc.c3b(0x7f,0x7f,0x7f)
    self.m_bpLvLabel:setString(info.bpLvStr)
    if info.bpLvflag then
        self.m_bpLvLabel:setTextColor(color)
        self.m_bpLvImg:setColor(AppDef.UIColor.WHITE)
    else
        self.m_bpLvLabel:setTextColor(AppDef.UIColor.RED)
        self.m_bpLvImg:setColor(imgColor)
    end
    
    self.m_bpMemCntLabel:setString(info.bpMemNumStr)
    if info.bpMemNumflag then
        self.m_bpMemCntLabel:setTextColor(color)
        self.m_bpMemCntImg:setColor(AppDef.UIColor.WHITE)
    else
        self.m_bpMemCntLabel:setTextColor(AppDef.UIColor.RED)
        self.m_bpMemCntImg:setColor(imgColor)
    end

    self.m_roleLvLabel:setString(info.roleLvStr)
    if info.roleLvflag then
        self.m_roleLvLabel:setTextColor(color)
        self.m_roleLvImg:setColor(AppDef.UIColor.WHITE)
    else
        self.m_roleLvLabel:setTextColor(AppDef.UIColor.RED)
        self.m_roleLvImg:setColor(imgColor)
    end

    self.m_joinTimeLabel:setString(info.enterTimeStr)
    if info.enterTimeflag then
        self.m_joinTimeLabel:setTextColor(color)
        self.m_joinTimeImg:setColor(AppDef.UIColor.WHITE)
    else
        self.m_joinTimeLabel:setTextColor(AppDef.UIColor.RED)
        self.m_joinTimeImg:setColor(imgColor)
    end

    self.m_openTimeLabel:setString(info.timeDesc)
    if info.startFlag then
        self.m_openTimeLabel:setTextColor(color)
        self.m_openTimeImg:setColor(AppDef.UIColor.WHITE)
    else
        self.m_openTimeLabel:setTextColor(AppDef.UIColor.RED)
        self.m_openTimeImg:setColor(imgColor)
    end

    self.m_tipLabel:setString(info.desc)
end

function BangPaiWarUI:ShowBtnState(info)
    if info.bpLvflag and info.bpMemNumflag and info.roleLvflag and info.enterTimeflag then
        self.m_enterBtn:setBright(true)
    else
        self.m_enterBtn:setBright(false)
    end
end

function BangPaiWarUI:RefreshPage()
    local info = LBangPaiWarDataMgr:GetWarData()
    self:ShowBangPaiList(info.BangPaiList)
    self:ShowCondition(info)
    self:ShowBtnState(info)
end

return BangPaiWarUI