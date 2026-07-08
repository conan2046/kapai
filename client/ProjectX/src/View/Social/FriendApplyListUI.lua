local FriendApplyListUI = LUIBase:New()
FriendApplyListUI.__index = FriendApplyListUI

local CsbFilePath = "csd/common/FriendLayer.csb"
-- -----------------------------------
function FriendApplyListUI:New()
    local o = LUIBase:New()
    setmetatable(o, FriendApplyListUI)
    o:Init(ctrl, node)
    return o
end

-- -----------------------------------
function FriendApplyListUI:Init()
    self.Script = "Social.FriendApplyListUI"
    self:RegistMsgs()
    self:InitViewSize();
    self:InitUIControl();
    self:IntEvtHandler();
    self:SetCloseCallback()
    self:InitData()
    --self:ShowList();
end

function FriendApplyListUI:IntEvtHandler()
    local quickRefuseBtn = self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/ShenqingBtn/Btn_1");
    local quickAgresBtn = self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/ShenqingBtn/Btn_2");
    local function onRefuseClicked()
        self._listView:removeAllItems();
        LuaNetSendMsg:QueryQuickAddFriendAct(0)
    end

    local function onAgreeClicked()
        self._listView:removeAllItems();
        LuaNetSendMsg:QueryQuickAddFriendAct(1)
    end

    quickRefuseBtn:addClickEventListener(onRefuseClicked);
    quickAgresBtn:addClickEventListener(onAgreeClicked);


end

--[[
注册事件
]]
function FriendApplyListUI:RegistMsgs()
    self.msgIds = 
    {
         LUISocialEvent.updateFriendApplyListLayer,
    }
    self:RegistSelf(self,self.msgIds)
end

function FriendApplyListUI:InitData()
    LuaNetSendMsg:QueryFriendApplyList()
end

function FriendApplyListUI:OnEnabled()
    self:InitData();
end

function FriendApplyListUI:InitViewSize()
    self:CreateUINode(CsbFilePath);
end

-- function FriendApplyListUI:InitTestData()
--     self._list = {}
--     for i = 1, 50 do
--         local data = {};
--         data.id = i;
--         data.name = "name" .. i
--         data.head = 1;
--         data.power = i*100;
--         data.bangpai = "adsf";
--         data.time = 0;
--         table.insert(self._list, data)
--     end
-- end

function FriendApplyListUI:ShowList()
    -- self:InitTestData()
    self._list = LRoleDataMgr.Social:GetFriendApplyList()
    self._listView:removeAllItems();

    local size = #self._list;
    if size == 0 then
        self.m_pUILayer:findChildByName("None"):setVisible(true);
        self.m_pUILayer:findChildByName("Friend"):setVisible(false);
        self.m_pUILayer:findChildByName("None/TextBg/Text"):setString(GUITips.RSI_SOCIAL_NoneFriendTip3);
    else
        self.m_pUILayer:findChildByName("None"):setVisible(false);
        self.m_pUILayer:findChildByName("Friend"):setVisible(true);
    end

    for i = 1, #self._list do
        local curNode = self._itemCell:clone();
        curNode:setVisible(true)
        self._listView:pushBackCustomItem(curNode);
        curNode:setVisible(true)
        local btn = curNode:findChildByName("BtnGroup/Btn_1");
        btn.userData = i;
        btn:addClickEventListener(function(sender)
            self:OnRefuseClicked(sender)
        end)

        btn = curNode:findChildByName("BtnGroup/Btn_2");
        btn.userData = i;
        btn:addClickEventListener(function(sender)
            self:OnOkClicked(sender)
        end)
        self:ShowData(curNode, self._list[i])
    end
end

function FriendApplyListUI:OnRefuseClicked(sender)
    local ind = sender.userData;
    LuaNetSendMsg:QueryAddFriendAct(self._list[ind].id, 0);
    local parent = sender:getParent();
    parent:getChildByName("Jujue"):setVisible(true);
    parent:getChildByName("Tongyi"):setVisible(false);
    parent:getChildByName("Btn_1"):setVisible(false);
    parent:getChildByName("Btn_2"):setVisible(false);
end

function FriendApplyListUI:OnOkClicked(sender)
    local ind = sender.userData;
    local parent = sender:getParent();
    LuaNetSendMsg:QueryAddFriendAct(self._list[ind].id, 1);
    parent:getChildByName("Jujue"):setVisible(false);
    parent:getChildByName("Tongyi"):setVisible(true);
    parent:getChildByName("Btn_1"):setVisible(false);
    parent:getChildByName("Btn_2"):setVisible(false);
end

function FriendApplyListUI:ShowData(node, data)


    node:findChildByName("Icon_1/Name"):setString(data.name);
    node:findChildByName("Icon_1/LevelNum"):setString(GUITips.RSI_FACTION_MSG7 .. data.level);
    node:findChildByName("Icon_1/Name/Time"):setString(Utils:getTimeString(data.offSecond));

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

-- local function getTimeString(time)
--         if 0 == time then
--             return GUITips.RSI_FACTION_MSG43
--         else
--             local day = math.floor(time / (24 * 3600))
--             local hour = math.floor(time / 3600)
--             if day > 0 then
--                 return string.format("%d%s", day, GUITips.RSI_FACTION_MSG44)
--             elseif hour > 0 then
--                 return string.format("%d%s", hour, GUITips.RSI_FACTION_MSG45)
--             else
--                 return string.format("%d%s", math.floor(time / 60), GUITips.RSI_FACTION_MSG46)
--             end
--         end
--     end

-- -----------------------------------
function FriendApplyListUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

-- -----------------------------------
function FriendApplyListUI:ProcessEvent(msg)
    if msg.msgId == LUISocialEvent.updateFriendApplyListLayer then
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

function FriendApplyListUI:SetCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
-- -----------------------------------
function FriendApplyListUI:InitUIControl()
    self.m_pUILayer:findChildByName("None"):setVisible(false);
    self.m_pUILayer:findChildByName("Friend/FriendList/Popup"):setVisible(false);
    self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/TuijianBtn"):setVisible(false);
    self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/ShenqingBtn"):setVisible(true);
    self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/Btn_1"):setVisible(false);
    -- self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/Btn_2"):setVisible(false);
    self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/Btn_3"):setVisible(false);
    self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/FriendsNum"):setVisible(false);
    self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/RewardsNum"):setVisible(false);

    self._itemCell = self.m_pUILayer:findChildByName("Friend/FriendList/Item");
    self._itemCell:getChildByName("BtnGroup"):setVisible(true);
    self._itemCell:getChildByName("Btn_Give"):setVisible(false);
    self._itemCell:getChildByName("Btn_Jiechu"):setVisible(false);
    self._itemCell:getChildByName("Btn_Get"):setVisible(false);
    self._itemCell:setVisible(false);
    self._listView = self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/Bg/ListView");
end

return FriendApplyListUI