local FriendRecommendListUI = LUIBase:New()
FriendRecommendListUI.__index = FriendRecommendListUI

local CsbFilePath = "csd/common/FriendLayer.csb"
-- -----------------------------------
function FriendRecommendListUI:New()
    local o = LUIBase:New()
    setmetatable(o, FriendRecommendListUI)
    o:Init(ctrl, node)
    return o
end

-- -----------------------------------
function FriendRecommendListUI:Init()
    self.Script = "Social.FriendRecommendListUI"
    self:RegistMsgs()
    self:InitViewSize();
    self:InitUIControl();
    self:IntEvtHandler();
    self:SetCloseCallback()
    self:InitData()
    --self:ShowList();
end

function FriendRecommendListUI:IntEvtHandler()
    local refreshBtn = self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/TuijianBtn/Btn_1");
    local searchBtn = self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/TuijianBtn/Btn_2");
    local quickAgresBtn = self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/TuijianBtn/Btn_3");
    local function onRefreshClicked()
        LuaNetSendMsg:QueryRecommendPlayer()
    end

    local function onAgreeClicked()
        self:HandleQuickAdd();
    end

    local function onFindClicked(sender)
        self:HandleFindClicked();
    end
    searchBtn:addClickEventListener(onFindClicked)

    refreshBtn:addClickEventListener(onRefreshClicked);
    quickAgresBtn:addClickEventListener(onAgreeClicked);


    btn = self._popUpPanel:findChildByName("bg/Btn_close");
    local function onClosePopupClicked(sender)
        self._popUpPanel:setVisible(false);
    end
    btn:addClickEventListener(onClosePopupClicked);
    
    btn = self._popUpPanel:getChildByName("Btn");
    local function onSearchClicked(sender)
        self:onSearchClicked();
    end
    btn:addClickEventListener(onSearchClicked);
end

function FriendRecommendListUI:onSearchClicked()
    local textField = self._popUpPanel:findChildByName("TextBg/TextField");
    local string = textField:getString()
    if string.len(string) > 0 then
        LuaNetSendMsg:QuerySerchPlayer(string);
        textField:setString("")
        self._popUpPanel:setVisible(false);
    end

end

function FriendRecommendListUI:HandleFindClicked()
    self._popUpPanel:setVisible(true);
end

function FriendRecommendListUI:HandleQuickAdd()
    if self._list == nil then
        return
    end
    for i = 1, #self._list do
        LuaNetSendMsg:QueryAddFriend(self._list[i].id);

    end

    local children = self._listView:getChildren();
    for i = 1, #children do
        local btn = children[i]:getChildByName("Btn");
        btn:getChildByName("Text1"):setVisible(false);
        btn:getChildByName("Text2"):setVisible(true);
        btn:setTouchEnabled(false);
        btn:setBright(false);
    end
end

--[[
注册事件
]]
function FriendRecommendListUI:RegistMsgs()
    self.msgIds = 
    {
         LUISocialEvent.updateSearchPlayer,
    }
    self:RegistSelf(self,self.msgIds)
end

function FriendRecommendListUI:InitData()
    LuaNetSendMsg:QueryRecommendPlayer()
end

function FriendRecommendListUI:OnEnabled()
    self:InitData();
end

function FriendRecommendListUI:InitViewSize()
    self:CreateUINode(CsbFilePath);
end

-- function FriendRecommendListUI:InitTestData()
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

function FriendRecommendListUI:ShowList()
    -- self:InitTestData()
    self._list = LRoleDataMgr.Social:GetFriendTuiJianList()
    self._listView:removeAllChildren();
    for i = 1, #self._list do
        local curNode = self._itemCell:clone();
        curNode:setVisible(true)
        self._listView:pushBackCustomItem(curNode);
        curNode:setVisible(true)
        local btn = curNode:getChildByName("Btn");
        btn.userData = i;
        btn:addClickEventListener(function(sender)
            self:OnOkClicked(sender)
        end)
        self:ShowData(curNode, self._list[i])
    end
end

function FriendRecommendListUI:OnOkClicked(sender)
    local ind = sender.userData;
    local parent = sender:getParent();
    LuaNetSendMsg:QueryAddFriend(self._list[ind].id);
    sender:getChildByName("Text1"):setVisible(false);
    sender:getChildByName("Text2"):setVisible(true);
    sender:setTouchEnabled(false);
    sender:setBright(false);
end

function FriendRecommendListUI:ShowData(node, data)


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
-- -----------------------------------
function FriendRecommendListUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

-- -----------------------------------
function FriendRecommendListUI:ProcessEvent(msg)
    if msg.msgId == LUISocialEvent.updateSearchPlayer then
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

function FriendRecommendListUI:SetCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
-- -----------------------------------
function FriendRecommendListUI:InitUIControl()
    self.m_pUILayer:findChildByName("None"):setVisible(false);
    self.m_pUILayer:findChildByName("Friend/FriendList/Popup"):setVisible(false);
    self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/TuijianBtn"):setVisible(true);
    self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/ShenqingBtn"):setVisible(false);
    self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/Btn_1"):setVisible(false);
    -- self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/Btn_2"):setVisible(false);
    self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/Btn_3"):setVisible(false);
    self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/FriendsNum"):setVisible(false);
    self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/RewardsNum"):setVisible(false);

    self._popUpPanel = self.m_pUILayer:findChildByName("Friend/FriendList/Popup");
    self._itemCell = self.m_pUILayer:findChildByName("Friend/FriendList/Item");
    self._itemCell:getChildByName("BtnGroup"):setVisible(false);
    self._itemCell:getChildByName("Btn_Give"):setVisible(false);
    self._itemCell:getChildByName("Btn_Jiechu"):setVisible(false);
    self._itemCell:getChildByName("Btn_Get"):setVisible(false);
    self._itemCell:getChildByName("Btn"):setVisible(true);
    self._itemCell:setVisible(false);
    self._listView = self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/Bg/ListView");
end

return FriendRecommendListUI