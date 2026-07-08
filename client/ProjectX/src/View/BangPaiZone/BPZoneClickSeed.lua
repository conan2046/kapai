local BaseOprStrategy = require('View.BangPaiZone.BaseOprStrategy')
local BangPaiZoneDef = require('View.BangPaiZone.BangPaiZoneDef')

local BPZoneClickSeed = BaseOprStrategy:New()
BPZoneClickSeed.__index = BPZoneClickSeed

local TAG_BTN_WATER = 1
local TAG_BTN_BUG = 2
local TAG_BTN_REMOVE = 3

-- -----------------------------------
function BPZoneClickSeed:New(FactionZoneUI)
    local o = {}
    setmetatable(o, BPZoneClickSeed)
    o:Init(FactionZoneUI)
    return o
end

-- -----------------------------------
function BPZoneClickSeed:Init(FactionZoneUI)
    self.FactionZoneUI = FactionZoneUI
    self.m_index = 0
    self.m_datas = {}
end

function BPZoneClickSeed:onExit()
    self.FactionZoneUI = nil
    Utils:FreeTable(self.m_datas)
    self.m_datas = nil
    self.m_index = nil
    self.m_opr = nil
end

function BPZoneClickSeed:onClose()
    self:SetSellect(false)
end

function BPZoneClickSeed:SetData(index, opr)
    -- if not LRoleDataMgr.Faction:IsPlantFactionBelongMe() then
    --     return false
    -- end
    self.m_index = index + 1
    self.m_opr = nil
    self.m_opr = opr
    if opr then
        self:SetSellect(true)
    end
    return true
end

function BPZoneClickSeed:ShowListBg()
    return false
end

function BPZoneClickSeed:initData()
    Utils:FreeTable(self.m_datas)
    self.m_datas = nil

    local cellData = self.FactionZoneUI:getCellData(self.m_index)
    self.m_datas = {}
    local isNotGray = Utils:ToBool(cellData:IsNeedWater()) and (self.m_opr == nil or self.m_opr ~= 4)
    table.insert(self.m_datas, {res="res/UI/faction_plant/plant_btn_flag_water.png", txt=GUITips.RSI_BP_TIP34, tag=TAG_BTN_WATER, isNotGray = isNotGray})
    isNotGray = Utils:ToBool(cellData:IsNeedBug()) and (self.m_opr == nil or self.m_opr ~= 5)
    table.insert(self.m_datas, {res="res/UI/faction_plant/plant_btn_flag_bug.png", txt=GUITips.RSI_BP_TIP35, tag=TAG_BTN_BUG, isNotGray = isNotGray})
    table.insert(self.m_datas, {res="res/UI/faction_plant/plant_btn_flag_remove.png", txt=GUITips.RSI_BP_TIP36, tag=TAG_BTN_REMOVE, isNotGray = Utils:ToBool(cellData:IsCanRemove())})
    return true
end

function BPZoneClickSeed:GetCellTag(index)
    return self.m_datas[index].tag
end

function BPZoneClickSeed:getItemCunt()
    return #(self.m_datas)
end

function BPZoneClickSeed:updateIcon(pIcon, index)
    pIcon:loadTexture(self.m_datas[index].res, UI_TEX_TYPE_PLIST)
end

function BPZoneClickSeed:updateName(pName, index)
    pName:setVisible(true)
    pName:setString(self.m_datas[index].txt)
end

function BPZoneClickSeed:ChooseCallback(index)
    local cellData = self.FactionZoneUI:getCellData(self.m_index)
    local factionID = LRoleDataMgr.Faction:GetPlantFactionId()
    local areaIndex = cellData:GetAreaIndex()
    local cellIndex = cellData:GetIndex()
    --print("BPZoneClickSeed", self.m_index, areaIndex, cellIndex)

    if index == TAG_BTN_WATER then
        if Utils:ToBool(cellData:IsNeedWater()) then
            self.FactionZoneUI:StartCommonCollect(2, GUITips.RSI_FACTION_MSG57, BangPaiZoneDef.Collect.PlantWater, cellData)
        else
            LuaNetSendMsg:QueryFactionPlantWater(factionID, areaIndex, cellIndex)
        end
    elseif index == TAG_BTN_BUG then
        if Utils:ToBool(cellData:IsNeedBug()) then
            self.FactionZoneUI:StartCommonCollect(2, GUITips.RSI_FACTION_MSG58, BangPaiZoneDef.Collect.PlantBug, cellData)
        else
            LuaNetSendMsg:QueryFactionPlantBug(factionID, areaIndex, cellIndex)
        end
    elseif index == TAG_BTN_REMOVE then
        local data = GUITips.RSI_BP_TIP_MIN
        local function okCallback()
            LuaNetSendMsg:QueryFactionPlantDig(factionID, areaIndex, cellIndex)

            LGameMsg.m_baseMsgWithOne:Change(LUIBangPaiEvent.CloseFactionZoneOpLayer, true)
            self:SendMsg(LGameMsg.m_baseMsgWithOne)
        end
        local function cancelCallback()
        end
        Utils:ShowDialogOKCancel(data, okCallback, cancelCallback)
    end
end

function BPZoneClickSeed:GetCellGray(index)
    return not(self.m_datas[index].isNotGray)
end

function BPZoneClickSeed:SetSellect(isSellect, isForever)
    if self.m_index == nil then
        return
    end
    local cellData = self.FactionZoneUI:getCellData(self.m_index)
    if cellData and cellData:GetNode() then
        cellData:GetNode():SetSelectedEffect(isSellect or false, isForever or false)
    end
end

return BPZoneClickSeed