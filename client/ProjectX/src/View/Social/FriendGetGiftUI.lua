local FriendGetGiftUI = LUIBase:New()
FriendGetGiftUI.__index = FriendGetGiftUI

local CsbFilePath = "csd/common/FriendLayer.csb"
-- -----------------------------------
function FriendGetGiftUI:New()
    local o = LUIBase:New()
    setmetatable(o, FriendGetGiftUI)
    o:Init(ctrl, node)
    return o
end

-- -----------------------------------
function FriendGetGiftUI:Init()
    self.Script = "Social.FriendGetGiftUI"
    self:RegistMsgs()
    self:InitViewSize();
    self:InitUIControl();
    self:IntEvtHandler();
    self:SetCloseCallback()
    self:InitData()
    self:ShowMaxNum()
    --self:ShowList();
end

function FriendGetGiftUI:IntEvtHandler()
    local quickGetBtn = self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/Btn_3");
    local function onQuickGet()
        LuaNetSendMsg:QueryFriendQuickGetGift();
    end

    quickGetBtn:addClickEventListener(onQuickGet);


end

--[[
注册事件
]]
function FriendGetGiftUI:RegistMsgs()
    self.msgIds = 
    {
         LUISocialEvent.UpdateFriendGift,
         LUISocialEvent.UpdateGiftLeft,
    }
    self:RegistSelf(self,self.msgIds)
end

function FriendGetGiftUI:InitData()
    LuaNetSendMsg:QueryFriendGiftList()
end

function FriendGetGiftUI:OnEnabled()
    self:InitData();
end

function FriendGetGiftUI:InitViewSize()
    self:CreateUINode(CsbFilePath);
end

-- function FriendGetGiftUI:InitTestData()
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

function FriendGetGiftUI:ShowList()
    -- self:InitTestData()
    self._list = LRoleDataMgr.Social:GetFriendGiftList()
    self._listView:removeAllItems();

    local size = #self._list;
    if size == 0 then
        self.m_pUILayer:findChildByName("None"):setVisible(true);
        self.m_pUILayer:findChildByName("Friend"):setVisible(false);
        self.m_pUILayer:findChildByName("None/TextBg/Text"):setString(GUITips.RSI_SOCIAL_NoneFriendTip2);
    else
        self.m_pUILayer:findChildByName("None"):setVisible(false);
        self.m_pUILayer:findChildByName("Friend"):setVisible(true);
    end


    for i = 1, #self._list do
        local curNode = self._itemCell:clone();
        curNode:setVisible(true)
        self._listView:pushBackCustomItem(curNode);
        curNode:setVisible(true)
        btn = curNode:getChildByName("Btn_Get");
        btn.userData = i;
        btn:addClickEventListener(function(sender)
            self:OnOkClicked(sender)
        end)
        self:ShowData(curNode, self._list[i])
    end
    self:ShowMaxNum()
end

function FriendGetGiftUI:ShowMaxNum()
   self._giftNumLabel:setString(LRoleDataMgr.Social._friendGetGiftLeft .. "/" .. LRoleDataMgr.Social._friendMaxGetGift)
end

function FriendGetGiftUI:OnOkClicked(sender)
    local ind = sender.userData;
    if self._list[ind] == nil then
        return
    end

    LuaNetSendMsg:QueryFriendGetGift(self._list[ind].id);
    if LRoleDataMgr.Social._friendGetGiftLeft <= 0 then
        return
    end
    sender:setTouchEnabled(false);
    sender:setBright(false);
    sender:getChildByName("Text"):setString(GUITips.RSI_FUND_TIPS4);
    -- local parent = sender:getParent();
    -- LuaNetSendMsg:QueryAddFriendAct(self._list[ind].id, 1);
    -- parent:getChildByName("Jujue"):setVisible(false);
    -- parent:getChildByName("Tongyi"):setVisible(true);
    -- parent:getChildByName("Btn_1"):setVisible(false);
    -- parent:getChildByName("Btn_2"):setVisible(false);
end

function FriendGetGiftUI:ShowData(node, data)
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
function FriendGetGiftUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

-- -----------------------------------
function FriendGetGiftUI:ProcessEvent(msg)
    if msg.msgId == LUISocialEvent.UpdateFriendGift then
        self:ShowList()
    elseif msg.msgId == LUISocialEvent.UpdateGiftLeft then
        self:ShowMaxNum()
    end
end

function FriendGetGiftUI:SetCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
-- -----------------------------------
function FriendGetGiftUI:InitUIControl()
    self.m_pUILayer:findChildByName("None"):setVisible(false);
    self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/FriendsNum"):setVisible(false);
    self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/RewardsNum"):setVisible(true);
    self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/ShenqingBtn"):setVisible(false);
    self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/TuijianBtn"):setVisible(false);

    self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/Btn_1"):setVisible(false);
    -- self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/Btn_2"):setVisible(false);
    self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/Btn_3"):setVisible(true);
    self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/Btn_3/Text"):setString(GUITips.RSI_SOCIAL_QUICK_GET);
    self.m_pUILayer:findChildByName("Friend/FriendList/Popup"):setVisible(false);

    self._itemCell = self.m_pUILayer:findChildByName("Friend/FriendList/Item");
    self._itemCell:getChildByName("BtnGroup"):setVisible(false);
    self._itemCell:getChildByName("Btn_Give"):setVisible(false);
    self._itemCell:getChildByName("Btn_Jiechu"):setVisible(false);
    self._itemCell:getChildByName("Btn_Get"):setVisible(true);
    self._itemCell:setVisible(false);
    self._listView = self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/Bg/ListView");


    self._giftNumLabel = self.m_pUILayer:findChildByName("Friend/FriendList/Friend1/RewardsNum/Text");
end

return FriendGetGiftUI