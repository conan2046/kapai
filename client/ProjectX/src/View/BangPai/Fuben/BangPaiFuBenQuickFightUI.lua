local BangPaiFuBenQuickFightUI = LUIBase:New()
BangPaiFuBenQuickFightUI.__index = BangPaiFuBenQuickFightUI


local BangPaiDef = require("View.BangPai.BangPaiDef")
local BPBuffs = require("ConfigData.guild_buff_dat")
local ScriptPath = "BangPai.Fuben.BangPaiFuBenQuickFightUI"

-- -----------------------------------
function BangPaiFuBenQuickFightUI:New(data)
    local o = {}
    setmetatable(o, BangPaiFuBenQuickFightUI)
    o:Init(data)
    return o
end

-- -----------------------------------
function BangPaiFuBenQuickFightUI:Init(data)
    self.Script = "BangPai.Fuben.BangPaiFuBenQuickFightUI"
    self._data = data;
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    self:initData()
end

function BangPaiFuBenQuickFightUI:initData()
    local mapId =  JsonConfig.getMapIdByStageID(self._data.stageId)
    LuaNetSendMsg:QueryBangPaiFubenQuickFight(mapId, self._data.copyData.id)
end

-- -----------------------------------
function BangPaiFuBenQuickFightUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
end

-- -----------------------------------
function BangPaiFuBenQuickFightUI:RegistMsgs()
    self.msgIds = {
        LUIBangPaiEvent.GotQuickFightData,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function BangPaiFuBenQuickFightUI:ProcessEvent(msg)
    if msg.msgId == LUIBangPaiEvent.GotQuickFightData then
        self:GotData(msg.value)
    end
end

function BangPaiFuBenQuickFightUI:GotData(data)
    self._fightData = data;
    self._curData = 1;
    --[[
local fightDataArr = {}
        local fightNum = stream:ReadByte();
        for i = 1, fightNum do
            local fightData = {}
            local itemNum = stream:ReadByte()
            for j = 1, itemNum do
                local item = {}
                item.itemId = stream:ReadWord()
                item.itemNum = stream:ReadInt()
                table.insert(fightData, item)
            end
            fightData.damage = stream:ReadULongInt();
            table.insert(fightDataArr,fightData);
        end
    ]]
    self:ShowResult();
end

function BangPaiFuBenQuickFightUI:ShowResult()
    local data = self._fightData[self._curData];
    local baseItem = self._baseResultNode:clone();
    baseItem:setVisible(true);
    self._listView:pushBackCustomItem(baseItem);
    self._listView:jumpToBottom();
    local itemList = baseItem:getChildByName("ListView");
    for i = 1, #data do
        local itemNode = self._bastItemNode:clone();
        itemNode:setVisible(true)
        Utils:ShowItemByConfigData(data[i], itemNode, nil, false, true)
        -- Utils:GetItemCellValue(itemNode, 0, data[i].itemId, true, true, data[i].itemNum, nil, true)
        itemList:pushBackCustomItem(itemNode);
    end
    local label = baseItem:findChildByName("TitleBg/Times");
    local msg = string.format(GUITips.SI_BP_TIP59,GUINumUper[self._curData]);
    label:setString(msg);
    msg = string.format(GUITips.SI_BP_TIP60,data.damage);
    label = baseItem:findChildByName("TitleBg/Times/Text");
    label:setString(msg);

    self._curData = self._curData + 1
    if self._curData > #self._fightData then
        return
    end
    local delayTime = cc.DelayTime:create(0.3);
    local func = cc.CallFunc:create(handler(self, BangPaiFuBenQuickFightUI.ShowResult));
    local sq = cc.Sequence:create(delayTime, func)
    self.m_pUILayer:runAction(sq);

end

function BangPaiFuBenQuickFightUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    Utils:SendMsg(LUISecondClassBgEvent.SetCloseCallback, handler(self, LUIBase.RemoveUI))
    Utils:SendMsg(LUISecondClassBgEvent.SetTitle, GUITips.RSI_FACTION_TITLE9)
end

-- -----------------------------------
function BangPaiFuBenQuickFightUI:InitViewSize()
    self:CreateUINode("csd/wanfa/Xunbao_souxunLayer.csb");
end

-- -----------------------------------
function BangPaiFuBenQuickFightUI:InitUIControl()
    self._baseResultNode = self.m_pUILayer:findChildByName("Souxun/Reward");
    self._baseResultNode:setVisible(false);
    self._bastItemNode = self.m_pUILayer:findChildByName("Souxun/Item");
    self._bastItemNode:setVisible(false);
    self._listView = self.m_pUILayer:findChildByName("Souxun/Popup/ListView");

    self.m_pUILayer:findChildByName("Souxun/Button_1"):setVisible(false);
end

return BangPaiFuBenQuickFightUI