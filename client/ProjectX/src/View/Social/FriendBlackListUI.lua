local FriendBlackListUI = LUIBase:New()
FriendBlackListUI.__index = FriendBlackListUI

local CsbFilePath = "csd/common/FriendLayer.csb"
-- -----------------------------------
function FriendBlackListUI:New()
    local o = LUIBase:New()
    setmetatable(o, FriendBlackListUI)
    o:Init(ctrl, node)
    return o
end

-- -----------------------------------
function FriendBlackListUI:Init()
    self.Script = "Social.FriendBlackListUI"
    self:RegistMsgs();
    self:InitViewSize();
    self:InitUIControl()
    self:SetCloseCallback()
    self:InitData();
end

function FriendBlackListUI:InitData()
    LuaNetSendMsg:QueryBlackListInfo()
end

function FriendBlackListUI:OnEnabled()
    self:InitData();
end

function FriendBlackListUI:InitViewSize()
    self:CreateUINode(CsbFilePath);
end

-- function FriendBlackListUI:InitTestData()
--     self._list = {}
--     for i = 1, 50 do
--         local data = {};
--         data.id = i;
--         data.name = "name" .. i
--         data.head = 1;
--         data.level = i;
--         data.fightPower = i*100;
--         data.bpId = i;
--         data.bpName = "adsf";
--         data.offSecond = 0;
--         table.insert(self._list, data)
--     end
-- end

function FriendBlackListUI:ShowList()
    self._list = LRoleDataMgr.Social.BlackList;
    self._listView:removeAllItems();

    local size = #self._list;
    if size == 0 then
        self.m_pUILayer:findChildByName("None"):setVisible(true);
        self.m_pUILayer:findChildByName("Friend"):setVisible(false);
        self.m_pUILayer:findChildByName("None/TextBg/Text"):setString(GUITips.RSI_SOCIAL_NoneFriendTip4);
    else
        self.m_pUILayer:findChildByName("None"):setVisible(false);
        self.m_pUILayer:findChildByName("Friend"):setVisible(true);
    end
    for i = 1, #self._list do
        local curNode = self._itemCell:clone();
        curNode:setVisible(true)
        self._listView:pushBackCustomItem(curNode);
        
        local btn = curNode:getChildByName("Btn_Jiechu");
        btn:setVisible(true)
        btn.userData = i;
        btn:addClickEventListener(function(sender)
            self:OnOkClicked(sender)
        end)
        self:ShowData(curNode, self._list[i])
    end
end

function FriendBlackListUI:OnOkClicked(sender)
    local ind = sender.userData;
    self._listView:removeItem(ind - 1);
    LuaNetSendMsg:QueryDelBlack(self._list[ind].id)
    LRoleDataMgr.Social:DelBlack(self._list[ind].id);

end

function FriendBlackListUI:ShowData(node, data)
    node:findChildByName("Icon_1/Name"):setString(data.name);
    node:findChildByName("Icon_1/LevelNum"):setString(GUITips.RSI_FACTION_MSG7 .. data.level);
    node:findChildByName("Icon_1/Name/Time"):setString(Utils:getTimeString(data.offSecond));
    -- node:findChildByName("Power/Value"):setString(Utils:getPowerStr(data.fightPower));
    local powerValue, isWan = Utils:getNewPowerStr(data.fightPower);
    node:findChildByName("Power/Value"):setString(powerValue);
    if isWan == true then
        node:findChildByName("Power/Value/Wan"):setVisible(true)
        node:findChildByName("Power/Value/Wan"):setPositionX(node:findChildByName("Power/Value"):getContentSize().width)
    else
        node:findChildByName("Power/Value/Wan"):setVisible(false)
    end
    if data.bpId == 0 then
        node:getChildByName("Group"):setVisible(false);
    else
        node:findChildByName("Group/Name"):setString(data.bpName);
    end

    local strHeadImage = AppDef:GetHeroPicFileName(data.head, AppDef.HeadType.HERO_IMAGE_HEAD_ROUND);
    local infoNode = node:findChildByName("Icon_1/Icon");
    infoNode:loadTexture(strHeadImage, ccui.TextureResType.localType);


    local function OnDetailClicked(sender)
        print("OnDetailClicked")
        LuaNetSendMsg:QueryOtherPlayerInfo(sender.userData.id);
    end
    infoNode:setTouchEnabled(true);
    infoNode.userData = data;
    infoNode:addClickEventListener(OnDetailClicked);
end

-- -----------------------------------
function FriendBlackListUI:onExit()
    self.m_pUILayer = nil
    self:Destory();
end

--[[
注册事件
]]
function FriendBlackListUI:RegistMsgs()
    self.msgIds = 
    {
         LUISocialEvent.updateBlackList,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function FriendBlackListUI:ProcessEvent(msg)
    if msg.msgId == LUISocialEvent.updateBlackList then
        self:ShowList()
    end
    -- elseif msg.msgId == LUIBangPaiEvent.UpdateGongGao then
    --     self:UpdateGongGao()
    -- elseif msg.msgId == LUIBangPaiEvent.UpdateNameShow then
    --     self:updateBPNameVisible(msg.value)
    -- elseif msg.msgId == LUIBangPaiEvent.UpdateManorInfo then
    --     self:setDetailUI()
    -- elseif msg.msgId == LUIBangPaiEvent.ReloadFactionActivityList then
    --     self:ReloadActivityData(msg.value)
    -- elseif msg.msgId == LUIBangPaiEvent.FlushFactionActivity then
    --     self:SetActivity(LRoleDataMgr.Faction.Info.totalActivity)
    -- elseif msg.msgId == LUIRedDotEvent.UpdateRedDotState then
    --     self:UpdateRedDot(msg.value)
    -- elseif msg.msgId == LUILogicEvent.changeBpNameSuc then
    --     self:setBpName()
    -- end
end

function FriendBlackListUI:SetCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
-- -----------------------------------
function FriendBlackListUI:InitUIControl()
    self.m_pUILayer:findChildByName("None"):setVisible(false);
    self.m_pUILayer:findChildByName("Friend/FriendList/Popup"):setVisible(false);
    self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/TuijianBtn"):setVisible(false);
    self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/ShenqingBtn"):setVisible(false);
    self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/Btn_1"):setVisible(false);
    -- self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/Btn_2"):setVisible(false);
    self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/Btn_3"):setVisible(false);
    self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/FriendsNum"):setVisible(false);
    self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/RewardsNum"):setVisible(false);

    self._itemCell = self.m_pUILayer:findChildByName("Friend/FriendList/Item");
    self._itemCell:getChildByName("BtnGroup"):setVisible(false);
    self._itemCell:getChildByName("Btn_Give"):setVisible(false);
    self._itemCell:getChildByName("Btn_Jiechu"):setVisible(true);
    self._itemCell:getChildByName("Btn_Get"):setVisible(false);
    self._itemCell:setVisible(false);
    self._listView = self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/Bg/ListView");
end

return FriendBlackListUI