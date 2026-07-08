--[[
lua  社交
]]
local FriendLayer = LUIBase:New()
FriendLayer.__index = FriendLayer

--local this = LTcpSocket
function FriendLayer:New(openTab)
	local o = LUIBase:New()
	setmetatable(o,FriendLayer)	
    o:Init(openTab)
	return o
end

function FriendLayer:Init(openTab)

    self.Script = "Social.FriendLayer"
    self:RegistMsgs()
    self.m_pUILayer = cc.Node:create()
    self.m_pSubLayer = {}
    self.m_curUIInd = 0
    self.m_defaultRoleName = nil
    self._defaultPCRoleId = nil
    self:InitTouchEvt();
    

    --title
    LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.SetTitle, GUITips.RSI_SOCIAL)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local function tabBtnClicked(ind)
        self:TabClicked(ind)
    end
    local tabValues = 
    {
    --, GUITips.RSI_SOCIAL_MASTER, GUITips.RSI_SOCIAL_SPOUSE 屏蔽师徒和夫妻

        {GUITips.RSI_SOCIAL_FIRNDLIST, GUITips.RSI_SOCIAL_RECEIVE_GIFTS, GUITips.RSI_SOCIAL_APPLICATION_LIST,GUITips.RSI_SOCIAL_RECOMMEND_LIST, GUITips.RSI_SOCIAL_BLACK_LIST},
        tabBtnClicked
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.AddTabBtn, tabValues)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.SelectTab, openTab)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    self:TabClicked(openTab)
    self:OnEnter();
    -- self:RegisterGuide()
end

function FriendLayer:OnEnter()
    local function initRedDotState(id)
        local isShow = Utils:GetRedDotState(id)
        self:DealUpdateRedDotState({id=id, isShow=isShow})
    end
    initRedDotState(RedDotDef.ID.FriendApply);
    initRedDotState(RedDotDef.ID.FriendGift);
end

function FriendLayer:OnEnabled()
    
end

function FriendLayer:DealUpdateRedDotState(data)
    local ind = 0

    local ind = 0
    if data.id == RedDotDef.ID.FriendApply then
        ind = 3
    elseif data.id == RedDotDef.ID.FriendGift then
        ind = 2
    end
    if ind > 0 then
        Utils:SendMsg(LUIPopFClassBgEvent.RedDotState, {ind, data.isShow})
    end
end

function FriendLayer:SetRedDotState(value)
    local ind = value[1]
    local show = value[2]
    if self.m_pTabBtns[ind] == nil then return end
    local btn = self.m_pTabBtns[ind]:getChildByName("Button1")
    if btn ~= nil then
        btn:getChildByName("Prompt"):setVisible(show)
    end
end

-- function FriendLayer:RegisterGuide()
--     if true then
--         return
--     end
--     if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SJHAOYOU, true) then
--         return
--     end
--     --------------------------------------------------------------------------
--     -- local msg = {}
--     -- msg.stepId = GuideDef.StepId.Guide_SHEJ_1
--     -- msg.tabIndex = 2
--     -- LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RegisterTabGuide, msg)
--     -- self:SendMsg(LGameMsg.m_baseMsgWithOne)
--     --------------------------------------------------------------------------
--     LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RegisterCloseGuide, GuideDef.StepId.Guide_SHEJ_FINISH)
--     self:SendMsg(LGameMsg.m_baseMsgWithOne)
--     --------------------------------------------------------------------------
-- end

--[[
注册消息
]]
function FriendLayer:RegistMsgs()
    self.msgIds = 
    {
        LUIRedDotEvent.UpdateRedDotState,
        -- LUIMailEvent.TurnWriteMail,   --写邮件
        -- LUIChatEvent.turnToPcChatState,   --跳转到私聊
    }
    self:RegistSelf(self,self.msgIds)
end

function FriendLayer:ProcessEvent(msg)
    if msg.msgId == LUIRedDotEvent.UpdateRedDotState then
        self:DealUpdateRedDotState(msg.value)
    end
    -- if  msg:GetMsgId() == LUISocialEvent.gotoMailUI then
    --     LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, 1)
    --     self:SendMsg(LGameMsg.m_baseMsgWithOne)
    --     self:TabClicked(1)
    -- end

    -- if msg.msgId == LUIMailEvent.TurnWriteMail then
    --     self:SetQuickMailType(msg.value)
    -- end

    -- if msg.msgId == LUIChatEvent.turnToPcChatState then
    --     self:SetQuickPcChatType(msg.value)
    -- end

end

function FriendLayer:onExit()
    -- Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_SHEJ_FINISH)
    self.m_pUILayer = nil
    self.m_defaultRoleName = nil
    self.m_curUIInd = nil
    self._defaultPCRoleId = nil
    self:Destory()
end

function FriendLayer:InitTouchEvt()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    
    local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Social.FriendLayer")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

end


function FriendLayer:HideCurUI()
    if self.m_pSubLayer[self.m_curUIInd] == nil then
        return
    end
    self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(false)
end

function FriendLayer:ShowCurUI()
    
    if self.m_pSubLayer[self.m_curUIInd] == nil then
        self:DelayLoadSubUI(self.m_curUIInd)
    else
        self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(true)
        self.m_pSubLayer[self.m_curUIInd]:OnEnabled();
        if self.m_curUIInd == 1 or self.m_curUIInd == 2 then
            
        end
    end
    
end

function FriendLayer:TabClicked(ind)
    if  self.m_curUIInd == ind then
        return
    end

    local function goBack(index)
        LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, index)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end

    -- if ind == 1 and Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SJYOUJIAN) then
    --     goBack(self.m_curUIInd)
    --     return
    -- elseif ind == 2 and Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SJHAOYOU) then
    --     goBack(self.m_curUIInd)
    --     return
    -- end

    if self.m_curUIInd ~= 0 then
     self:HideCurUI()
    end
     self.m_curUIInd = ind
     self:ShowCurUI()
    Utils:SendMsg(LUIPopFClassBgEvent.RedDotState, {ind, false});

end

function FriendLayer:DelayLoadSubUI(tabInd)
    --,"View.Social.MasterUI",
    --local uinames = {"View.Mail.MailUI","View.Social.FriendChat"}
    local uinames = {"View.Social.FriendListUI","View.Social.FriendGetGiftUI","View.Social.FriendApplyListUI","View.Social.FriendRecommendListUI","View.Social.FriendBlackListUI"}
    local ind = tabInd
    local delay = cc.DelayTime:create(0.1)
    local function loadSubUI()
        if self.m_curUIInd ~= ind then
            return
        end
        self:updateHotDot()
        self.m_pSubLayer[ind] = require(uinames[ind]):New()
        self.m_pUILayer:addChild(self.m_pSubLayer[ind].m_pUILayer)
        -- if ind == 1 then
        --     if self.m_defaultRoleName ~= nil then
        --         self.m_pSubLayer[self.m_curUIInd]:setShowMail(self.m_defaultRoleName)
        --     end
        --     self.m_pSubLayer[ind]:QueryMails()
        -- end

        -- if ind == 2 then
        --     if self._defaultPCRoleId ~= nil then
        --         self.m_pSubLayer[self.m_curUIInd]:setTurnToPcChat(self._defaultPCRoleId)
        --     end
        -- end
    end
    local func = cc.CallFunc:create(loadSubUI)
    local sequence = cc.Sequence:create(delay, func)
    self.m_pUILayer:runAction(sequence)

end


function FriendLayer:SetQuickMailType(toRoleId)
    if self.m_curUIInd ~= 1 then
        LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, 1)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
        self:TabClicked(1)
    end

    if self.m_pSubLayer[self.m_curUIInd] ~= nil then
        self.m_pSubLayer[self.m_curUIInd]:showWriteMailDirect(toRoleId)
        self.m_defaultRoleName = toRoleId;
    else
        self.m_defaultRoleName = toRoleId
    end
    
end

function FriendLayer:SetQuickPcChatType(id)
    -- body
    if self.m_curUIInd ~= 2 then
        return
    end

    if self.m_pSubLayer[self.m_curUIInd] ~= nil then
        self.m_pSubLayer[self.m_curUIInd]:setTurnToPcChat(id)
    else    
        self._defaultPCRoleId = id
    end

end

function FriendLayer:updateHotDot()
    -- body
    local show = LRoleDataMgr.Social:IsUnReadMsg()

    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RedDotState, {2, show})
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

return FriendLayer