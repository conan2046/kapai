local BaseOprStrategy = require('View.BangPaiZone.BaseOprStrategy')
local BPZoneChooseSeed = BaseOprStrategy:New()
BPZoneChooseSeed.__index = BPZoneChooseSeed

local bufferConfig = {
    [1203] = 1,--金币
    [1211] = 1,--金币
    [1205] = 2,--元宝
    [1212] = 2,--元宝
    [1201] = 3,--内丹
    [1210] = 3,--内丹
    [1207] = 4,--经验
    [1209] = 4,--经验
}
-- -----------------------------------
function BPZoneChooseSeed:New(FactionZoneUI)
    local o = {}
    setmetatable(o, BPZoneChooseSeed)
    o:Init(FactionZoneUI)
    return o
end

-- -----------------------------------
function BPZoneChooseSeed:Init(FactionZoneUI)
    self.FactionZoneUI = FactionZoneUI
    self.m_index = 0
    self.m_datas = {}
end

function BPZoneChooseSeed:onExit()
    self.FactionZoneUI = nil
    self.m_index = nil
    self.m_datas = nil
end

function BPZoneChooseSeed:onClose()
    local cellData = self.FactionZoneUI:getCellData(self.m_index)
    Utils:SendMsg(LUIMainEvent.OpenOrCloseBtmBtn, true)

    if cellData and cellData:GetNode() then
        cellData:GetNode():SetSelectedEffect(false, false)
    end
end

function BPZoneChooseSeed:SetData(index)
    self.m_index = index + 1
    if not LRoleDataMgr.Faction:IsPlantFactionBelongMe() then
        return false
    end
    return true
end

function BPZoneChooseSeed:GetCellGray(index)
    return false
end

function BPZoneChooseSeed:initData()
    local map = LRoleDataMgr.Equip:FindPackageItemById2(1201, 1400)
    local list = {}
    for k,v in pairs(map) do
        if v > 0 then
            table.insert(list, v)
        end
    end
    if #list == 0 then
        Utils:ShowScrollTips(GUITips.RSI_GM_TIP4)
        return false
    end

    Utils:FreeTable(self.m_datas)
    self.m_datas = nil
    self.m_datas = {}
    for i=1,#list do
        table.insert(self.m_datas, LRoleDataMgr.Equip.PackageMap[list[i]])
    end
    return true
end

function BPZoneChooseSeed:checkData()
    return (self.m_datas ~= nil and #self.m_datas ~= 0 and self.m_index ~= 0)
end

function BPZoneChooseSeed:getItemCunt()
    return #self.m_datas
end

function BPZoneChooseSeed:updateIcon(pIcon, index)
    local item = self.m_datas[index]
    if item and item.m_item then
        local str = "item/equip" .. item.m_item.m_pic .. ".png"
        pIcon:loadTexture(str, UI_TEX_TYPE_LOCAL)
    end
end

function BPZoneChooseSeed:updateName(pName, index)
    local item = self.m_datas[index]
    if item and item.m_item then
        pName:setVisible(true)
        pName:setString(item.m_item.m_name or "")
    end
end

function BPZoneChooseSeed:updateNum(pNum, index)
    local item = self.m_datas[index]
    if item and item.m_item then
        pNum:setVisible(true)
        pNum:setString(tostring(item.m_num))
    end
end

function BPZoneChooseSeed:updateCount(pCount, index)
    local item = self.m_datas[index]
    if item and item.m_id then
        local index = bufferConfig[item.m_id]
        if index then
            local cfg = LRoleDataMgr.Faction._PlantExtraData[index]
            if cfg then
                pCount:setVisible(true)
                pCount:setString(string.format("(%d/%d)", cfg.subCount or 0, cfg.maxCount or 0))
            else
                pCount:setVisible(false)
            end
        else
            pCount:setVisible(false)
        end
    end
end

function BPZoneChooseSeed:ChooseCallback(index)
    local data = self.m_datas[index]
    local cellData = self.FactionZoneUI:getCellData(self.m_index)
    -- print("BPZoneChooseSeed", cellData:GetAreaIndex(), cellData:GetIndex())
    LuaNetSendMsg:QueryFactionPlantSeed(LRoleDataMgr.Faction:GetPlantFactionId(), cellData:GetAreaIndex(), cellData:GetIndex(), data.m_id)
end

return BPZoneChooseSeed