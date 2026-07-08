local BangPaiJuanXianUI = LUIBase:New()
BangPaiJuanXianUI.__index = BangPaiJuanXianUI

local BangPaiDef = require("View.BangPai.BangPaiDef")

-----------------------------------
function BangPaiJuanXianUI:New()
    local o = {}
    setmetatable(o, BangPaiJuanXianUI)
    o:Init()
    return o
end

-----------------------------------
function BangPaiJuanXianUI:Init()
    self.Script = "BangPai.BangPaiJuanXianUI"

    -------------------------------------------------------
    self.m_pDonate = nil
    self.m_pListBg = nil
    -------------------------------------------------------
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
end

-----------------------------------
function BangPaiJuanXianUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.Script = nil
    -------------------------------------------------------
    self.m_pDonate = nil
    self.m_pListBg = nil
    -------------------------------------------------------
    --table view相关
    self.m_tableCount = nil
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_pTablePanel = nil
    self.m_datas = nil
    Utils:FreeTable(self.m_panelDatas)
    self.m_panelDatas = nil
end

-----------------------------------
function BangPaiJuanXianUI:RegistMsgs()
    self.msgIds = {
        LUIBangPaiEvent.UpdateJuanXianRecord,
        LUIBangPaiEvent.ReloadJuanXianMsg,
    }
    self:RegistSelf(self, self.msgIds)
end

-----------------------------------
function BangPaiJuanXianUI:ProcessEvent(msg)
    if msg.msgId == LUIBangPaiEvent.UpdateJuanXianRecord then
        self:updateData(msg.value)
    elseif msg.msgId == LUIBangPaiEvent.ReloadJuanXianMsg then
        self:updatePanel(msg.value)
    end
end

function BangPaiJuanXianUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    Utils:SendMsg(LUIFClassBgEvent.SetCloseCallback, handler(self, LUIBase.RemoveUI))
    Utils:SendMsg(LUIFClassBgEvent.SetTitle, GUITips.RSI_FACTION_TITLE5)
    Utils:SendMsg(LUIFClassBgEvent.AddTabBtn, nil)
end

-----------------------------------
function BangPaiJuanXianUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/bangpai/GangsDonateLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

-----------------------------------
function BangPaiJuanXianUI:InitUIControl()
    local panel = self.m_pUILayer:getChildByName("Panel")

    local pBg = panel:getChildByName("Bg")
    local pDonate = pBg:getChildByName("Donate")
    self.m_pDonate = pDonate
    for i=1,3 do
        local pNode = pDonate:getChildByName("Bg"..i)
        if pNode then
            local pButton = pNode:getChildByName("Button")
            pButton:setTag(i)
            pButton:addClickEventListener(handler(self, BangPaiJuanXianUI.juanXianCallback))
			self:MarkIntaractCObj(pButton)
        end
    end

    local pButton = pDonate:getChildByName("Button")
    pButton:addClickEventListener(handler(self, BangPaiJuanXianUI.jxRecordCallback))
	self:MarkIntaractCObj(pButton)
    -----------------------------------
    local pListBg = panel:getChildByName("ListBg")
    pListBg:setVisible(false)
    self.m_pListBg = pListBg

    local pPanel_1 = pListBg:getChildByName("Panel_1")
    pPanel_1:addClickEventListener(function(sender)
        self.m_pListBg:setVisible(false)
    end)
	self:MarkIntaractCObj(pPanel_1)
    self.m_pTablePanel = pListBg:getChildByName("List")
    self.m_pGridCell = pListBg:getChildByName("Panel_7")
    self.m_pGridCell:setVisible(false)
    self.m_pTableView = self:InitTableView(self.m_pTablePanel)
end

function BangPaiJuanXianUI:InitTableView(tbPanel)
    local cfg = {}
    cfg.tbPanel = tbPanel
    cfg.cellSizeForTable = function(sender,idx)
        local size = self.m_pGridCell:getContentSize()
        return size.width, size.height
    end
    cfg.tableCellAtIndex = function(sender, idx)
        return self:TableCellAtIndex(sender, idx + 1)
    end

    cfg.numberOfCellsInTableView = function() 
        return self.m_tableCount
    end

    return Utils:createTableView(cfg)
end

function BangPaiJuanXianUI:TableCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild = nil

    local info = self.m_datas[idx]
    
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pGridCell:clone()
        cellChild:setTouchEnabled(false)
        cellChild:setAnchorPoint(cc.p(0, 0))
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cell:addChild(cellChild)

        local pText = cellChild:getChildByName("Text1")
        Utils:CreateColorText2(cellChild, pText, cellChild:getContentSize())
    else
        cellChild = cell:getChildByTag(123)
    end
    if cellChild ~= nil then
        self:updateItem(cellChild, info, idx)
    end
    return cell
end

function BangPaiJuanXianUI:updateItem(cell, info, idx)
    local pText = cell:getChildByName("Text1")
    pText:setString(string.format("%s  %s", info.time, info.desc))

    local pLine = cell:getChildByName("LineImage")
    pLine:setVisible(idx < self.m_tableCount)
end

-------------------------------------------------------------------------------------------
function BangPaiJuanXianUI:jxRecordCallback(sender)
    LuaNetSendMsg:QueryFactionJuanXianRecord()
end

function BangPaiJuanXianUI:updateData(datas)
    self.m_datas = datas.mInfo
    self.m_tableCount = #(self.m_datas)
    self.m_pTableView:reloadData()
    self.m_pListBg:setVisible(true)
end

function BangPaiJuanXianUI:updatePanel(datas)
    Utils:FreeTable(self.m_panelDatas)
    self.m_panelDatas = nil
    self.m_panelDatas = datas
    for i=1, #datas do
        local pNode = self.m_pDonate:getChildByName("Bg"..i)
        if pNode then
            pNode:setTag(i)
            self:updatePanelItem(pNode, datas[i])
        end
    end
end

function BangPaiJuanXianUI:updatePanelItem(pNode, info)
    local pImage = pNode:getChildByName("Image")
    local pIcon_1 = pImage:getChildByName("Icon_1")
    pIcon_1:getChildByName("Value"):setString(tostring(info.bangpaiMoney))
    local pIcon_2 = pImage:getChildByName("Icon_2")
    pIcon_2:getChildByName("Value"):setString(tostring(info.banggong))

    local pIconBg = pNode:getChildByName("IconBg")
    pIconBg:getChildByName("Value"):setString(tostring(info.money)..GUITips.RSI_FACTION_WAN)
end

function BangPaiJuanXianUI:juanXianCallback(sender)
    local tag = sender:getTag()
    local data = self.m_panelDatas[tag]
    LuaNetSendMsg:QueryFactionJuanXian(data.type)
end

return BangPaiJuanXianUI