local BangPaiZoneUI = LGameBase:New()
BangPaiZoneUI.__index = BangPaiZoneUI

local BangPaiZoneDef = require('View.BangPaiZone.BangPaiZoneDef')

BangPaiZoneUI.IsHideInBattle = true

-- -----------------------------------
function BangPaiZoneUI:New()
    local o = {}
    setmetatable(o, BangPaiZoneUI)
    o:Init()
    return o
end

-- -----------------------------------
function BangPaiZoneUI:Init()
    self.Script = "BangPaiZone.BangPaiZoneUI"

    self.m_plantAreaDataList = {}
    self.m_plantCellDataList = {}
    self.m_plantGuardDataList = {}

    self.m_pBPZoneOprLayer = nil

    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    self:RegisterQuik()
    
    performWithDelay(self.m_pUILayer, handler(self, BangPaiZoneUI.DelayShowPlantUI), 1)
end
-- -----------------------------------
function BangPaiZoneUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    LRoleDataMgr.Faction:ClearAllPlantData()
    Utils:FreeTable(self.m_plantAreaDataList, self.m_plantCellDataList, self.m_plantGuardDataList)
    self.m_plantAreaDataList = nil
    self.m_plantCellDataList = nil
    self.m_plantGuardDataList = nil
    self.m_pBPZoneOprLayer = nil
end

-- -----------------------------------
function BangPaiZoneUI:InitUIControl()
    AppDef.spriteFrameCache:addSpriteFrames("csd/Plist/faction_plant.plist", "csd/Plist/faction_plant.png")
end

-- -----------------------------------
function BangPaiZoneUI:RegistMsgs()
    self.msgIds = 
    {
        LPlantEvent.PlantEvent,
        LGameEvent.EnterBattle,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function BangPaiZoneUI:ProcessEvent(msg)
    if msg:GetMsgId() == LPlantEvent.PlantEvent then
        local index = msg:GetIndex()
        local opType = msg:GetType()
        if opType == BangPaiZoneDef.OprType.ChooseSeed then
            self:RegisterQuik()
            self:ShowChooseSeedLayer(index)
        elseif opType == BangPaiZoneDef.OprType.ClickSeed then
            self:RegisterQuik()
            self:ShowClickSeedLayer(index)
        elseif opType == BangPaiZoneDef.OprType.StartSteal then
            self:RegisterQuik()
            self:StartCommonCollect(10, GUITips.RSI_GM_TIP5, BangPaiZoneDef.Collect.PlantSteal, self.m_plantCellDataList[index+1])
        elseif opType == BangPaiZoneDef.OprType.StopCollectAnim then
            self:StopCommonCollect()
        elseif opType == BangPaiZoneDef.OprType.ClickGodTree then
            self:ShowGodTreeLayer()
        elseif opType == BangPaiZoneDef.OprType.ClickMagicFire then
            self:ShowMagicFireLayer()
        elseif opType == BangPaiZoneDef.OprType.ClickGuard then
            self:ShowGuardLayer(index)
        elseif opType == BangPaiZoneDef.OprType.UpdateGuard then
            self:RegisterQuik()
            self:UpdateGuardLayer(index)
        end
    elseif msg:GetMsgId() == LGameEvent.EnterBattle then
        if self.m_pBPZoneOprLayer and self.m_pBPZoneOprLayer.m_pUILayer then
            self.m_pBPZoneOprLayer.m_pUILayer:setVisible(false)
        end
    end
end

function BangPaiZoneUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

-- -----------------------------------
function BangPaiZoneUI:InitViewSize()
    self.m_pUILayer = cc.Node:create()
    self.m_pUILayer:setContentSize(AppDef.frameSize)
end

-- ----------------------------------
function BangPaiZoneUI:RegisterQuik()
    local msg = GetMapHerosMsg:new(CEnum.MapEvent.LuaGetFactionPlantData, function(cellList, areaList, guardList)
        Utils:FreeTable(self.m_plantAreaDataList, self.m_plantCellDataList, self.m_plantGuardDataList)
        self.m_plantAreaDataList = nil
        self.m_plantCellDataList = nil
        self.m_plantGuardDataList = nil
        self.m_plantAreaDataList = areaList
        self.m_plantCellDataList = cellList
        self.m_plantGuardDataList = guardList
    end)
    self:SendMsg(msg)
end

function BangPaiZoneUI:UpdateUserData(data)
    self:RegisterQuik()
end

function BangPaiZoneUI:getCellData(index)
    return self.m_plantCellDataList[index]
end

function BangPaiZoneUI:getAreaData(index)
    return self.m_plantAreaDataList[index]
end

function BangPaiZoneUI:getGuardData(index)
    return self.m_plantGuardDataList[index]
end

function BangPaiZoneUI:getGuardDataByIndex(index)
    for i=1,#self.m_plantGuardDataList do
        if self.m_plantGuardDataList[i]:GetAreaIndex() == index then
            return self.m_plantGuardDataList[i]
        end
    end
    return nil
end

function BangPaiZoneUI:DelayShowPlantUI()
    --显示进入提示
    local WEL_FMT_ME = GUITips.RSI_GM_TIP6
    local WEL_FMT = GUITips.RSI_GM_TIP7

    if(LRoleDataMgr.Faction:IsPlantFactionBelongMe()) then
        Utils:ShowScrollTips(string.format(WEL_FMT_ME, LRoleDataMgr.Faction:GetPlantFactionName()))
    else
        Utils:ShowScrollTips(string.format(WEL_FMT, LRoleDataMgr.Faction:GetPlantFactionName()))
    end
end

function BangPaiZoneUI:getPic(nodeType)
    if (nodeType == BangPaiZoneDef.Collect.PlantWater) then
        return 3
    elseif(nodeType == BangPaiZoneDef.Collect.PlantBug) then
        return 7
    elseif(nodeType == BangPaiZoneDef.Collect.PlantSteal) then
        return 4
    elseif(nodeType == BangPaiZoneDef.Collect.PlantGodTree) then
        return 4
    elseif(nodeType == BangPaiZoneDef.Collect.PlantMagicFire) then
        return 2
    elseif(nodeType == BangPaiZoneDef.Collect.PlantMagicUnFire) then
        return 5
    end
    return 1
end

function BangPaiZoneUI:StartCommonCollect(collectTime, msg, type, data)
    Utils:FreeTable(self.m_collectCfg)
    self.m_collectCfg = nil
    self.m_collectCfg = {type=type, data = data}
    
    if collectTime == 0 then
        self:CollectFinished()
    else
        local collectData = {}
        collectData["collectTip"] = msg
        collectData["seconds"] = collectTime
        collectData["pic"] = self:getPic(type)
        collectData["callback"] = handler(self, BangPaiZoneUI.CollectFinished)

        Utils:InitUI("Interact.NPCCollectUI", AppDef.UIType.PopWindow, collectData)
    end
end

function BangPaiZoneUI:CollectFinished()
    local nodeType = self.m_collectCfg.type
    
    local factionID = LRoleDataMgr.Faction:GetPlantFactionId()
    
    local areaIndex = nil
    local cellIndex = nil
    local cellData = self.m_collectCfg.data
    if cellData then
        areaIndex = cellData:GetAreaIndex()
        cellIndex = cellData:GetIndex()
    end

    if (nodeType == BangPaiZoneDef.Collect.PlantWater) then
        LuaNetSendMsg:QueryFactionPlantWater(factionID, areaIndex, cellIndex)
    elseif(nodeType == BangPaiZoneDef.Collect.PlantBug) then
        LuaNetSendMsg:QueryFactionPlantBug(factionID, areaIndex, cellIndex)
    elseif(nodeType == BangPaiZoneDef.Collect.PlantSteal) then
        LuaNetSendMsg:QueryFactionPlantSteal(factionID, areaIndex, cellIndex)
    elseif(nodeType == BangPaiZoneDef.Collect.PlantGodTree) then
        LuaNetSendMsg:QueryFactionGodGreeRob(factionID)
    elseif(nodeType == BangPaiZoneDef.Collect.PlantMagicFire) then
        LuaNetSendMsg:QueryFactionMagicFireOpr(LRoleDataMgr.Faction:GetPlantFactionId(), true)
    elseif(nodeType == BangPaiZoneDef.Collect.PlantMagicUnFire) then
        LuaNetSendMsg:QueryFactionMagicFireOpr(LRoleDataMgr.Faction:GetPlantFactionId(), false)
    end
end

function BangPaiZoneUI:StopCommonCollect()
    Utils:DeleteUI("Interact.NPCCollectUI")
end

function BangPaiZoneUI:GetOpLayer()
    if self.m_pBPZoneOprLayer == nil then
        self.m_pBPZoneOprLayer = require('View.BangPaiZone.BPZoneOprLayer'):New()
        self.m_pUILayer:addChild(self.m_pBPZoneOprLayer.m_pUILayer)
    end
    return self.m_pBPZoneOprLayer
end

function BangPaiZoneUI:ShowChooseSeedLayer(index)
    local layer = self:GetOpLayer()
    layer:setStrategy(require('View.BangPaiZone.BPZoneChooseSeed'):New(self))
    Utils:SendMsg(LUIMainEvent.OpenOrCloseBtmBtn, false)
    layer:SetData(index)
end

function BangPaiZoneUI:ShowClickSeedLayer(index)
    local layer = self:GetOpLayer()
    layer:setStrategy(require('View.BangPaiZone.BPZoneClickSeed'):New(self))
    layer:SetData(index)
end

function BangPaiZoneUI:ShowGodTreeLayer()
    if LRoleDataMgr.Faction:IsPlantFactionBelongMe() then
        LuaNetSendMsg:QueryFactionGodTreeDetail(LRoleDataMgr.Faction:GetPlantFactionId())
    else
        local layer = self:GetOpLayer()
        layer:setStrategy(require('View.BangPaiZone.BPZoneClickGodTree'):New(self))
        layer:SetData()
    end
end

function BangPaiZoneUI:ShowMagicFireLayer()
    local layer = self:GetOpLayer()
    layer:setStrategy(require('View.BangPaiZone.BPZoneClickMagicFire'):New(self))
    layer:SetData(index)
end

function BangPaiZoneUI:ShowGuardLayer(index)
    local data = self:getGuardData(index+1)
    if data ~= nil then
        local finfo = nil
        if LRoleDataMgr.Faction:IsSameFactionToMe(data:GetFactionId()) then
            finfo = LRoleDataMgr.Faction.Info
        else
            finfo = LRoleDataMgr.Faction:GetFactionInfo(data:GetFactionId())
        end
        if finfo == nil then
            return
        end
        if data:GetOpenLevel() > finfo.level then
            local str = string.format("[c1]%s%d%s[/c]", GUITips.RSI_FACTION_MSG68, data:GetOpenLevel(), GUITips.RSI_FACTION_MSG69)
            Utils:ShowScrollTips(str)
        else
            Utils:InitUI("BangPaiZone.BPZoneGuardLayer",AppDef.UIType.SecondClassLayer, data)
            LuaNetSendMsg:QueryFactionGuardInfo(data:GetFactionId(), data:GetAreaIndex(), false)
        end
    end
end

function BangPaiZoneUI:UpdateGuardLayer(index)
    local data = self:getGuardDataByIndex(index)
    if data then
        Utils:SendMsg(LUIBangPaiEvent.UpdateFactionZoneGuard, data)
    end
end 


return BangPaiZoneUI