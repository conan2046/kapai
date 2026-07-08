local BangPaiSkillUI = LUIBase:New()
BangPaiSkillUI.__index = BangPaiSkillUI


local BangPaiDef = require("View.BangPai.BangPaiDef")
local BPBuffs = require("ConfigData.guild_buff_dat")
local ScriptPath = "BangPai.BangPaiSkillUI"

-- -----------------------------------
function BangPaiSkillUI:New()
    local o = {}
    setmetatable(o, BangPaiSkillUI)
    o:Init()
    return o
end

-- -----------------------------------
function BangPaiSkillUI:Init()
    self.Script = "BangPai.Fuben.BangPaiSkillUI"

    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    self:initData()
    self:ShowBPInfo()
end

function BangPaiSkillUI:initData()
    LuaNetSendMsg:QueryBangPaiBuff()
end

function BangPaiSkillUI:ShowBPInfo()
    local huoyueLabel = self.m_pUILayer:findChildByName("GangsPopup/SkillPopup/TimesBg/Num");
    huoyueLabel:setString(LRoleDataMgr.Faction.copyHuoyue);
end

-- -----------------------------------
function BangPaiSkillUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    -- display.removeUnusedSpriteFrames()
end

-- -----------------------------------
function BangPaiSkillUI:RegistMsgs()
    self.msgIds = {
        LUIBangPaiEvent.GotBuffData,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function BangPaiSkillUI:ProcessEvent(msg)
    if msg.msgId == LUIBangPaiEvent.GotBuffData then
        self:ShowSkill();
        self:ShowBPInfo();
    end
end

function BangPaiSkillUI:ShowSkill()
    local skills = LRoleDataMgr.Faction.buffList;
    local curItemPanel;
    local listView = self.m_pUILayer:findChildByName("GangsPopup/SkillPopup/Image2/ListView");
    listView:removeAllItems();

    local textListView = self.m_pUILayer:findChildByName("GangsPopup/SkillPopup/Tips/ListView");
    textListView:removeAllItems();
    for i = 1, #skills do
        if i % 2 == 1 then
            curItemPanel = self._baseSkillNode:clone();
            curItemPanel:setVisible(true);
            listView:pushBackCustomItem(curItemPanel);
        end
        local ind = (i - 1) % 2 + 1;
        local buffNode = curItemPanel:getChildByName("Item" .. ind);
        buffNode:setVisible(true)
        local btn = buffNode:getChildByName("Btn");
        btn.userData = i
        btn:addClickEventListener(handler(self, BangPaiSkillUI.OnUpLevelClicked))
        




        if i % 4 == 1 then
            curTipPanel = self._baseTipNode:clone();
            curTipPanel:setVisible(true);
            textListView:pushBackCustomItem(curTipPanel);
        end
        ind = (i - 1) % 4 + 1;
        local tipLabel = curTipPanel:getChildByName("Value" .. ind);
        tipLabel:setVisible(true)

        self:ShowOneBuff(buffNode, tipLabel, i,skills[i])
    end

    

end

function BangPaiSkillUI:OnUpLevelClicked(sender)

    local ind = sender.userData;
    local skillData = LRoleDataMgr.Faction.buffList[ind];
    local baseInfo = BPBuffs[skillData.buffId]
    -- print("OnUpLevelClicked",baseInfo.cost)
    if baseInfo.cost > LRoleDataMgr.Faction.copyHuoyue then
        --活跃度不够
        Utils:SendMsg(LUILogicEvent.ShowSrcollTips,GUITips.RSI_FACTION_MSG216)
        return
    end
    LuaNetSendMsg:QueryBangPaiBuffLvUp(skillData.buffId)
end

function BangPaiSkillUI:ShowOneBuff(node, tipLabel, ind,skillData)
    local baseInfo = BPBuffs[skillData.buffId]
    local attrData = LDataConstMgr:GetAttrConfigData(baseInfo.buff[1]);
    local attrLabel = node:findChildByName("Power");
    attrLabel:setString(attrData.attrName .. ":");

    local nameLabel = node:findChildByName("Name");
    nameLabel:setString(baseInfo.name);

    tipLabel:setString(attrData.attrName .. "+" .. skillData.level * baseInfo.buff[2]);
    local valueLabel = node:findChildByName("Power/Value");
    valueLabel:setString(skillData.level * baseInfo.buff[2]);

    local addLabel = node:findChildByName("IconBg/Add/AtlasLabel_1");
    addLabel:setString(skillData.level);

    if skillData.level >= baseInfo.max then
        node:getChildByName("Lable"):setVisible(true);
        node:getChildByName("Get"):setVisible(true);
        node:getChildByName("Btn"):setVisible(false);
    else
        node:getChildByName("Lable"):setVisible(false);
        node:getChildByName("Power"):setVisible(true);
        node:getChildByName("Get"):setVisible(false);
        node:getChildByName("Btn"):setVisible(true);
    end

    local iconSp = node:findChildByName("IconBg/Icon");
    local resName = "res/Skill/guild_skill/guild_skill_" .. baseInfo.pic .. ".png"
    iconSp:loadTexture(resName, ccui.TextureResType.localType);

end

function BangPaiSkillUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    Utils:SendMsg(LUISecondClassBgEvent.SetCloseCallback, handler(self, LUIBase.RemoveUI))
    Utils:SendMsg(LUISecondClassBgEvent.SetTitle, GUITips.RSI_FACTION_TITLE7)
end

-- -----------------------------------
function BangPaiSkillUI:InitViewSize()
    self:CreateUINode("csd/bangpai/GangsPopupLayer.csb");
end

-- -----------------------------------
function BangPaiSkillUI:InitUIControl()
    self.m_pUILayer:findChildByName("GangsPopup/Popup"):setVisible(false);
    self.m_pUILayer:findChildByName("GangsPopup/SkillPopup"):setVisible(true);
    self._baseSkillNode = self.m_pUILayer:findChildByName("GangsPopup/SkillPopup/ItemPanel");
    self._baseSkillNode:getChildByName("Item1"):setVisible(false);
    self._baseSkillNode:getChildByName("Item2"):setVisible(false);
    self._baseSkillNode:setVisible(false);


    self._baseTipNode = self.m_pUILayer:findChildByName("GangsPopup/SkillPopup/Tips/Shuxing");
    self._baseTipNode:getChildByName("Value1"):setVisible(false);
    self._baseTipNode:getChildByName("Value2"):setVisible(false);
    self._baseTipNode:getChildByName("Value3"):setVisible(false);
    self._baseTipNode:getChildByName("Value4"):setVisible(false);
    self._baseTipNode:setVisible(false);


end

function BangPaiSkillUI:showTips(msg)
    Utils:ShowScrollTips(msg)
end

return BangPaiSkillUI