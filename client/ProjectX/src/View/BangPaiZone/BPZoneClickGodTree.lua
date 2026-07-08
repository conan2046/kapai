local BaseOprStrategy = require('View.BangPaiZone.BaseOprStrategy')
local BangPaiZoneDef = require('View.BangPaiZone.BangPaiZoneDef')

local BPZoneClickGodTree = BaseOprStrategy:New()
BPZoneClickGodTree.__index = BPZoneClickGodTree

local TAG_BTN_ROB = 1
-- -----------------------------------
function BPZoneClickGodTree:New(FactionZoneUI)
    local o = {}
    setmetatable(o, BPZoneClickGodTree)
    o:Init(FactionZoneUI)
    return o
end

-- -----------------------------------
function BPZoneClickGodTree:Init(FactionZoneUI)
    self.FactionZoneUI = FactionZoneUI
    self.m_datas = {}

    Utils:SendMsg(LUIBangPaiEvent.CloseFactionZoneOpLayer, true)
end

function BPZoneClickGodTree:onExit()
    self.FactionZoneUI = nil
    Utils:FreeTable(self.m_datas)
    self.m_datas = nil
end

function BPZoneClickGodTree:SetRobBtnEnabled(plantList, canClick)
    local items = plantList:getChildren()
    for i=1,#items do
        if items[i]:getTag() == TAG_BTN_ROB then
            items[i]:setColor(canClick and CCWHITE or CCGRAY)
            break
        end
    end
end

function BPZoneClickGodTree:ShowListBg()
    return false
end

function BPZoneClickGodTree:SetData()
    return (not LRoleDataMgr.Faction:IsPlantFactionBelongMe())
end

function BPZoneClickGodTree:GetCellTag(index)
    return self.m_datas[index].tag
end

function BPZoneClickGodTree:initData()
    Utils:FreeTable(self.m_datas)
    self.m_datas = nil
    self.m_datas = {}
    table.insert(self.m_datas, {res="res/UI/faction_plant/plant_btn_flag_rob.png", tag=TAG_BTN_ROB, txt=GUITips.RSI_FACTION_MSG65, isNotGray = false})
    LuaNetSendMsg:QueryFactionGodGreeCanRob(LRoleDataMgr.Faction:GetPlantFactionId())
    return true
end

function BPZoneClickGodTree:checkData()
    return #self.m_datas > 0
end

function BPZoneClickGodTree:getItemCunt()
    return #self.m_datas
end

function BPZoneClickGodTree:updateIcon(pIcon, index)
    local sp = cc.Sprite:createWithSpriteFrameName(self.m_datas[index].res)
    sp:setName(pIcon:getName())
    sp:setPosition(cc.p(pIcon:getPosition()))
    pIcon:getParent():addChild(sp)
    pIcon:removeFromParent(true)
end

function BPZoneClickGodTree:updateName(pName, index)
    pName:setVisible(true)
    pName:setString(self.m_datas[index].txt)
end

function BPZoneClickGodTree:ChooseCallback(index)
    local factionID = LRoleDataMgr.Faction:GetPlantFactionId()
    
    if LRoleDataMgr.Faction:GetGodTreeCanRob() then
        self.FactionZoneUI:StartCommonCollect(20, GUITips.RSI_FACTION_MSG59, BangPaiZoneDef.Collect.PlantGodTree)
    else
        LuaNetSendMsg:QueryFactionGodGreeRob(factionID)
    end
end

return BPZoneClickGodTree