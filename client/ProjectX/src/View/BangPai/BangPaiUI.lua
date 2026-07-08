local BangPaiUI = LUIBase:New()
BangPaiUI.__index = BangPaiUI

local listLayerTag = 500
local infoLayerTag = 501
local memberLayerTag = 502
local taskLayerTag = 503
local warLayerTag = 504
local xiuLianLayerTag = 505
local shopLayerTag = 506

local LayerTabs = {
    [AppDef.EModuleID.EMID_BPLIEBIAO] = GUITips.RSI_BP_TIP14,
    [AppDef.EModuleID.EMID_BPXINXI] = GUITips.RSI_BP_TIP18,
    [AppDef.EModuleID.EMID_BPCHENGYUAN] = GUITips.RSI_BP_TIP15,
    [AppDef.EModuleID.EMID_BPHUODONG] = GUITips.RSI_BP_TIP16,
    -- [AppDef.EModuleID.EMID_BPXIULIAN] = GUITips.RSI_BP_TIP53,
    [AppDef.EActivityID.EAID_FACTION_WAR] = GUITips.RSI_BP_TIP46,
}
local LayerTabMap = {
    AppDef.EModuleID.EMID_BPLIEBIAO,
    AppDef.EModuleID.EMID_BPXINXI,
    AppDef.EModuleID.EMID_BPCHENGYUAN,
    AppDef.EModuleID.EMID_BPHUODONG,
    AppDef.EActivityID.EAID_FACTION_WAR,
    -- AppDef.EModuleID.EMID_BPXIULIAN,
}
-- -----------------------------------
function BangPaiUI:New(openTabInd)
    local o = {}
    setmetatable(o, BangPaiUI)
    o:Init(openTabInd)
    return o
end

-- -----------------------------------
function BangPaiUI:Init(openTabInd)
    self.Script = "BangPai.BangPaiUI"
    openTabInd = openTabInd or 1

    self.m_tabs = {}
    if LRoleDataMgr.Faction.Info.id <= 0 then
        self.m_openTab = AppDef.EModuleID.EMID_BPLIEBIAO
        table.insert(self.m_tabs, {tab=AppDef.EModuleID.EMID_BPLIEBIAO})
        -- table.insert(self.m_tabs, {tab=AppDef.EModuleID.EMID_BPXINXI})
        -- table.insert(self.m_tabs, {tab=AppDef.EModuleID.EMID_BPCHENGYUAN})
        -- table.insert(self.m_tabs, {tab=AppDef.EModuleID.EMID_BPHUODONG})
        -- table.insert(self.m_tabs, {tab=AppDef.EActivityID.EAID_FACTION_WAR})
    else
        self.m_openTab = LayerTabMap[openTabInd]
        if self.m_openTab == AppDef.EModuleID.EMID_BPLIEBIAO then
            table.insert(self.m_tabs, {tab=AppDef.EModuleID.EMID_BPLIEBIAO})
        else
            table.insert(self.m_tabs, {tab=AppDef.EModuleID.EMID_BPXINXI})
            table.insert(self.m_tabs, {tab=AppDef.EModuleID.EMID_BPCHENGYUAN})
            table.insert(self.m_tabs, {tab=AppDef.EModuleID.EMID_BPHUODONG})
            table.insert(self.m_tabs, {tab=AppDef.EActivityID.EAID_FACTION_WAR})
            -- table.insert(self.m_tabs, {tab=AppDef.EModuleID.EMID_BPXIULIAN})
        end
    end
    for i=1,#self.m_tabs do
        self.m_tabs[i].text = LayerTabs[self.m_tabs[i].tab]
    end
    -- dump(self.m_tabs, "self.m_tabs--->")

    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    self:RegisterQuik()
    self:OnEnter()
end

-- -----------------------------------
function BangPaiUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_openTab = nil
    
    LBangPaiWarDataMgr.BangPaiWarApplyInfo = nil
end

-- -----------------------------------
function BangPaiUI:InitUIControl()
    if LRoleDataMgr.Faction.Info.id > 0 then
        self:OnEnter()
    end
end

-- -----------------------------------
function BangPaiUI:RegistMsgs()
    self.msgIds = 
    {
        LUIRedDotEvent.UpdateRedDotState,
        LUIBangPaiEvent.CloseBangPaiPopup,
        LUIBangPaiEvent.JoinSuccess,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function BangPaiUI:ProcessEvent(msg)
    if msg.msgId == LUIRedDotEvent.UpdateRedDotState then
        self:DealUpdateRedDotState(msg.value)
    elseif msg.msgId == LUIBangPaiEvent.CloseBangPaiPopup then
        self:RemoveUI()
    elseif msg.msgId == LUIBangPaiEvent.JoinSuccess then
        self:RemoveUI()
        Utils:OpenFunction(AppDef.EModuleID.EMID_BPXINXI)
    end
end

function BangPaiUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    Utils:SendMsg(LUIFClassBgEvent.SetCloseCallback, handler(self, LUIBase.RemoveUI))
end

-- -----------------------------------
function BangPaiUI:InitViewSize()
    self.m_pUILayer = cc.Node:create()
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

-- ----------------------------------
function BangPaiUI:RegisterQuik()
    local tabValues = {}
    table.insert(tabValues, {})
    table.insert(tabValues, handler(self, BangPaiUI.TabClicked))

    local openTab = 0
    for i=1,#self.m_tabs do
        table.insert(tabValues[1], self.m_tabs[i].text)
        if self.m_openTab == self.m_tabs[i].tab then
            openTab = i
        end
    end

    Utils:SendMsg(LUIFClassBgEvent.AddTabBtn, tabValues)

    Utils:SendMsg(LUIFClassBgEvent.SelectTab, openTab)

    self:TabClicked(openTab)

    Utils:SendMsg(LUIFClassBgEvent.SetTitle, GUITips.RSI_BP_TIP13)
end

function BangPaiUI:getIndex(tab)
    for i=1,#self.m_tabs do
        if self.m_tabs[i].tab == tab then
            return i
        end
    end
    return 1
end

function BangPaiUI:TabClicked(ind)
    -- dump(ind, "ind--->")
    if ind == nil or ind == 0 then
        return
    end
    local key = self.m_tabs[ind].tab
    if key == nil then
        return
    end
    -- if key ~= AppDef.EModuleID.EMID_BPXIULIAN and Utils:CheckModelNotOpened(key) then
    --     Utils:SendMsg(LUIFClassBgEvent.SelectTab, self:getIndex(self.m_openTab))
    --     return
    -- end

    local oldTab = self.m_openTab
    
    if key ~= AppDef.EModuleID.EMID_BPLIEBIAO and LRoleDataMgr.Faction.Info.id <= 0 then
        Utils:ShowScrollTips(GUITips.RSI_BP_TIP1)
        Utils:SendMsg(LUIFClassBgEvent.SelectTab, 1)
        return
    end

    -- if LRoleDataMgr.m_bIsCrossServer and (key == AppDef.EModuleID.EMID_BPHUODONG or key == AppDef.EActivityID.EAID_FACTION_WAR or key == AppDef.EModuleID.EMID_BPXIULIAN) then
    if LRoleDataMgr.m_bIsCrossServer and (key == AppDef.EModuleID.EMID_BPHUODONG or key == AppDef.EActivityID.EAID_FACTION_WAR) then
        Utils:ShowScrollTips(GUITips.RSI_CS_TIP2)
        Utils:SendMsg(LUIFClassBgEvent.SelectTab, self:getIndex(oldTab))
        return
    end

    -- if key == AppDef.EModuleID.EMID_BPXIULIAN and LRoleDataMgr.Faction.Info.level < 3 then
    --     Utils:ShowScrollTips(GUITips.RSI_BP_TIP54)
    --     Utils:SendMsg(LUIFClassBgEvent.SelectTab, self:getIndex(oldTab))
    --     return
    -- end

    self.m_openTab = key
    self:removeAllLayers()

    if key == AppDef.EModuleID.EMID_BPLIEBIAO then
        local BangPaiListPage = require("View.BangPai.BangPaiListPage")
        local pLayer = BangPaiListPage:New(self)
        self.m_pUILayer:addChild(pLayer.m_pUILayer, 1000, listLayerTag)
        BangPaiListPage = nil
    elseif key == AppDef.EModuleID.EMID_BPXINXI then
        local BangPaiInfoUI = require("View.BangPai.BangPaiInfoUI")
        local pLayer = BangPaiInfoUI:New(self)
        self.m_pUILayer:addChild(pLayer.m_pUILayer, 1000, infoLayerTag)
    elseif key == AppDef.EModuleID.EMID_BPCHENGYUAN then
        local BangPaiMemList = require("View.BangPai.BangPaiMemList")
        local pLayer = BangPaiMemList:New(self)
        self.m_pUILayer:addChild(pLayer.m_pUILayer, 1000, memberLayerTag)
    elseif key == AppDef.EModuleID.EMID_BPHUODONG then
        local BangPaiActList = require("View.BangPai.BangPaiActList")
        local pLayer = BangPaiActList:New(self)
        self.m_pUILayer:addChild(pLayer.m_pUILayer, 1000, taskLayerTag)
    elseif key == AppDef.EActivityID.EAID_FACTION_WAR then
        local BangPaiWarUI = require("View.BangPai.BangPaiWarUI")
        local pLayer = BangPaiWarUI:New(self)
        self.m_pUILayer:addChild(pLayer.m_pUILayer, 1000, warLayerTag)
    -- elseif key == AppDef.EModuleID.EMID_BPXIULIAN then
    --     local BangPaiListPage = require("View.BangPai.BangPaiXiuLian")
    --     local pLayer = BangPaiListPage:New(self)
    --     self.m_pUILayer:addChild(pLayer.m_pUILayer, 1000, xiuLianLayerTag)
    end
end

function BangPaiUI:removeAllLayers()
    for i = listLayerTag,shopLayerTag do
        if self.m_pUILayer:getChildByTag(i) ~= nil then
            self.m_pUILayer:removeChildByTag(i)
        end
    end
end

function BangPaiUI:OnEnter()
    local function initRedDotState(id)
        local isShow = Utils:GetRedDotState(id)
        self:DealUpdateRedDotState({id=id, isShow=isShow})
    end
    initRedDotState(RedDotDef.ID.BPChengYuan)
    initRedDotState(RedDotDef.ID.BPHuoDong)
    initRedDotState(RedDotDef.ID.BPXinXi)
    initRedDotState(RedDotDef.ID.BPXiuLian)
end

function BangPaiUI:DealUpdateRedDotState(data)
    local ind = 0
    if data.id == RedDotDef.ID.BPChengYuan or data.id == RedDotDef.ID.BPXinXi then
        ind = self:getIndex(AppDef.EModuleID.EMID_BPXINXI)
    elseif data.id == RedDotDef.ID.BPHuoDong then
        ind = self:getIndex(AppDef.EModuleID.EMID_BPHUODONG)
    -- elseif data.id == RedDotDef.ID.BPXiuLian then
    --     ind = self:getIndex(AppDef.EModuleID.EMID_BPXIULIAN)
    end
    if ind > 0 then
        Utils:SendMsg(LUIFClassBgEvent.RedDotState, {ind, data.isShow})
    end
end

return BangPaiUI