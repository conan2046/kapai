--[[
lua  奖池
]]
local DrawRewardMainUI = LUIBase:New()
DrawRewardMainUI.__index = DrawRewardMainUI
--local this = LTcpSocket
function DrawRewardMainUI:New(openTab)
	local o = LUIBase:New()
	setmetatable(o,DrawRewardMainUI)	
    o:Init(openTab)
	return o
end

function DrawRewardMainUI:Init(openTab)
    self.Script = "HappyDraw.DrawRewardMainUI"
    self:RegistMsgs()
    self.m_pUILayer = cc.Node:create()
    self.m_pSubLayer = {}
    self.m_curUIInd = 0
    self.m_defaultRoleName = nil
    self._defaultPCRoleId = nil
    self:InitTouchEvt();

    --title
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.UI_Draw_preView)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local function tabBtnClicked(ind)
        self:TabClicked(ind)
    end
    local tabValues = 
    {
    --, GUITips.RSI_SOCIAL_MASTER, GUITips.RSI_SOCIAL_SPOUSE 屏蔽师徒和夫妻
        {GUITips.RSI_ZQX_CHOUKA_TIPS3, GUITips.RSI_ZQX_CHOUKA_TIPS8, GUITips.RSI_ZQX_CHOUKA_TIPS4},
        tabBtnClicked
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.AddTabBtn, tabValues)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)


    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, openTab)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    self:TabClicked(openTab)
    --self:RegisterGuide()
end

function DrawRewardMainUI:RegisterGuide()
    if true then
        return
    end
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SJHAOYOU, true) then
        return
    end
    
    -- LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RegisterCloseGuide, GuideDef.StepId.Guide_SHEJ_FINISH)
    -- self:SendMsg(LGameMsg.m_baseMsgWithOne)
    --------------------------------------------------------------------------
end

--[[
注册消息
]]
function DrawRewardMainUI:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

function DrawRewardMainUI:ProcessEvent(msg)

    if msg.msgId == LUIChatEvent.turnToPcChatState then
        self:SetQuickPcChatType(msg.value)
    end

end

function DrawRewardMainUI:onExit()
    -- Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_SHEJ_1)
    --Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_SHEJ_FINISH)
    self.m_pUILayer = nil
    self.m_defaultRoleName = nil
    self.m_curUIInd = nil
    self._defaultPCRoleId = nil
    self:Destory()
end

function DrawRewardMainUI:InitTouchEvt()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    
    local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "HappyDraw.DrawRewardMainUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

end


function DrawRewardMainUI:HideCurUI()
    if self.m_pSubLayer[self.m_curUIInd] == nil then
        return
    end
    self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(false)
end

function DrawRewardMainUI:ShowCurUI()
    
     if self.m_pSubLayer[self.m_curUIInd] == nil then
        self:DelayLoadSubUI(self.m_curUIInd)
    else
        self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(true)
    end
    
end

function DrawRewardMainUI:TabClicked(ind)
    if  self.m_curUIInd == ind then
        return
    end

    local function goBack(index)
        LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, index)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end

    if ind == 1 and Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_KAPAI_PET_BAGS) then
        goBack(self.m_curUIInd)
        return
    elseif ind == 2 and Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_KAPAI_FRAGMENT_BAGS) then
        goBack(self.m_curUIInd)
        return
    end

    if self.m_curUIInd ~= 0 then
     self:HideCurUI()
    end
     self.m_curUIInd = ind
     self:ShowCurUI()
end

function DrawRewardMainUI:DelayLoadSubUI(tabInd)
    --,"View.Social.MasterUI",
    local uinames = {"View.HappyDraw.NormalDrawRewardUI",  "View.HappyDraw.HighlyDrawRewardUI", "View.HappyDraw.FriendlyDrawRewardUI"}
    local ind = tabInd
    local delay = cc.DelayTime:create(0.1)
    local function loadSubUI()
        if self.m_curUIInd ~= ind then
            return
        end
        self:updateHotDot()
        self.m_pSubLayer[ind] = require(uinames[ind]):New()
        self.m_pUILayer:addChild(self.m_pSubLayer[ind].m_pUILayer)
    end
    local func = cc.CallFunc:create(loadSubUI)
    local sequence = cc.Sequence:create(delay, func)
    self.m_pUILayer:runAction(sequence)

end



function DrawRewardMainUI:updateHotDot()
    -- body
    local show = false
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RedDotState, {2, show})
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

return DrawRewardMainUI