local BaseOprStrategy = require('View.BangPaiZone.BaseOprStrategy')
local BangPaiZoneDef = require('View.BangPaiZone.BangPaiZoneDef')

local BPZoneClickMagicFire = BaseOprStrategy:New()
BPZoneClickMagicFire.__index = BPZoneClickMagicFire

local TAG_BTN_FIRE = 1
local TAG_BTN_UNFIRE = 2
-- -----------------------------------
function BPZoneClickMagicFire:New(FactionZoneUI)
    local o = {}
    setmetatable(o, BPZoneClickMagicFire)
    o:Init(FactionZoneUI)
    return o
end

-- -----------------------------------
function BPZoneClickMagicFire:Init(FactionZoneUI)
    self.FactionZoneUI = FactionZoneUI
    self.m_datas = {}
end

function BPZoneClickMagicFire:onExit()
    self.FactionZoneUI = nil
    Utils:FreeTable(self.m_datas)
    self.m_datas = nil
end

function BPZoneClickMagicFire:ShowListBg()
    return false
end

function BPZoneClickMagicFire:SetData(index)
    return true
end

function BPZoneClickMagicFire:GetCellTag(index)
    return self.m_datas[index].tag
end

function BPZoneClickMagicFire:initData()
    Utils:FreeTable(self.m_datas)
    self.m_datas = nil
    self.m_datas = {}
    if LRoleDataMgr.Faction:IsPlantFactionBelongMe() then
        table.insert(self.m_datas, {res="res/UI/faction_plant/plant_btn_flag_outfire.png", tag=TAG_BTN_UNFIRE, txt=GUITips.RSI_FACTION_MSG67, isNotGray = true})
    else
        table.insert(self.m_datas, {res="res/UI/faction_plant/ui_icon_bangpai_huoba.png", tag=TAG_BTN_FIRE, txt=GUITips.RSI_FACTION_MSG66, isNotGray = true})
    end
    return true
end

function BPZoneClickMagicFire:checkData()
    return #self.m_datas > 0
end

function BPZoneClickMagicFire:getItemCunt()
    return #self.m_datas
end

function BPZoneClickMagicFire:updateIcon(pIcon, index)
    local sp = cc.Sprite:createWithSpriteFrameName(self.m_datas[index].res)
    sp:setName(pIcon:getName())
    sp:setPosition(cc.p(pIcon:getPosition()))
    pIcon:getParent():addChild(sp)
    pIcon:removeFromParent(true)
end

function BPZoneClickMagicFire:updateName(pName, index)
    pName:setVisible(true)
    pName:setString(self.m_datas[index].txt or "")
end

function BPZoneClickMagicFire:ChooseCallback(tag)
    if tag == TAG_BTN_FIRE then
        if LRoleDataMgr.Faction:GetMagicFireBurning() == false then
            self.FactionZoneUI:StartCommonCollect(20, GUITips.RSI_FACTION_MSG60, BangPaiZoneDef.Collect.PlantMagicFire)
        else
            LuaNetSendMsg:QueryFactionMagicFireOpr(LRoleDataMgr.Faction:GetPlantFactionId(), true)
        end
    elseif tag == TAG_BTN_UNFIRE then
        if LRoleDataMgr.Faction:GetMagicFireBurning() then
            self.FactionZoneUI:StartCommonCollect(20, GUITips.RSI_FACTION_MSG61, BangPaiZoneDef.Collect.PlantMagicUnFire)
        else
            LuaNetSendMsg:QueryFactionMagicFireOpr(LRoleDataMgr.Faction:GetPlantFactionId(), false)
        end
    end
end

return BPZoneClickMagicFire