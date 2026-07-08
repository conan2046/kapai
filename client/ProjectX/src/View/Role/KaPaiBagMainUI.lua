--[[
lua  社交
]]
local KaPaiBagMainUI = LUIBase:New()
KaPaiBagMainUI.__index = KaPaiBagMainUI
--local this = LTcpSocket
function KaPaiBagMainUI:New(openTab)
	local o = LUIBase:New()
	setmetatable(o,KaPaiBagMainUI)	
    o:Init(openTab)
	return o
end

function KaPaiBagMainUI:Init(openTab)
    self.Script = "Role.KaPaiBagMainUI"
    self:RegistMsgs()
    self.m_pUILayer = cc.Node:create()
    self.m_pSubLayer = {}
    self.m_curUIInd = 0
    self:InitTouchEvt()

    --title
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.UI_Title_Bag)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local function tabBtnClicked(ind)
        self:TabClicked(ind)
    end
    local tabValues = 
    {
        {GUITips.UI_Title_Bag_TabName1},
        tabBtnClicked
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.AddTabBtn, tabValues)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, openTab)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    self:TabClicked(openTab)
    
    self:OnEnter()
end

-- function KaPaiBagMainUI:RegisterGuide()
--     if true then
--         return
--     end
--     if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SJHAOYOU, true) then
--         return
--     end
    
--     LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RegisterCloseGuide, GuideDef.StepId.Guide_SHEJ_FINISH)
--     self:SendMsg(LGameMsg.m_baseMsgWithOne)
--     --------------------------------------------------------------------------
-- end

--[[
注册消息
]]
function KaPaiBagMainUI:RegistMsgs()
    self.msgIds = 
    {
         LUIRedDotEvent.SetRedDotState,--红点
    }
    self:RegistSelf(self,self.msgIds)
end

function KaPaiBagMainUI:ProcessEvent(msg)

    if msg.msgId == LUIRedDotEvent.SetRedDotState then
        local ret = msg.value
        if ret == nil or ret.id == nil or ret.id == 0 then
            return
        end
        -- if ret.id == RedDotDef.ID.ZBBeiBao then
        --     self:InitRedDotState(RedDotDef.ID.ZBBeiBao)
        -- elseif ret.id == RedDotDef.ID.ZBSuiPian then
        --     self:InitRedDotState(RedDotDef.ID.ZBSuiPian)
        -- end
    end

end

function KaPaiBagMainUI:onExit()
    --Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_SHEJ_FINISH)
    self.m_pUILayer = nil
    self.m_curUIInd = nil
    self:Destory()
end

function KaPaiBagMainUI:OnEnter()
    --self:InitRedDotState(RedDotDef.ID.ZBBeiBao)
    --self:InitRedDotState(RedDotDef.ID.ZBSuiPian)
end

function KaPaiBagMainUI:InitRedDotState(id)
    if not self.m_pUILayer:isVisible() then
        return
    end
    local isShow = Utils:GetRedDotState(id)
    self:DealUpdateRedDotState({id=id, isShow=isShow})
end

function KaPaiBagMainUI:DealUpdateRedDotState(data)
    -- local ind = 0
    -- if data.id == RedDotDef.ID.ZBBeiBao then
    --     ind = 1
    -- elseif data.id == RedDotDef.ID.ZBSuiPian then
    --     ind = 2
    -- end
    -- if ind > 0 then
    --     --print("KaPaiBagMainUI:DealUpdateRedDotState",ind,data,isShow)
    --     Utils:SendMsg(LUIFClassBgEvent.RedDotState, {ind, data.isShow})
    -- end
end

function KaPaiBagMainUI:InitTouchEvt()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    
    local function closeCallback()
        LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, self.Script)
        self:SendMsg(LGameMsg.m_deleteUIMsg)
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

end


function KaPaiBagMainUI:HideCurUI()
    if self.m_pSubLayer[self.m_curUIInd] == nil then
        return
    end
    self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(false)
end

function KaPaiBagMainUI:ShowCurUI()
    if self.m_pSubLayer[self.m_curUIInd] == nil then
        self:DelayLoadSubUI(self.m_curUIInd)
    else
        self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(true)
    end
    
end

function KaPaiBagMainUI:TabClicked(ind)
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
end

function KaPaiBagMainUI:DelayLoadSubUI(tabInd)
    --,"View.Social.MasterUI",
    local uinames = {"View.Role.KaPaiBagSubUI"}
    local ind = tabInd
    local delay = cc.DelayTime:create(0.1)
    local function loadSubUI()
        if ind == nil or self.m_curUIInd ~= ind then
            return
        end
        self.m_pSubLayer[ind] = require(uinames[ind]):New()
        self.m_pUILayer:addChild(self.m_pSubLayer[ind].m_pUILayer)
        --self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(true)
    end
    local func = cc.CallFunc:create(loadSubUI)
    local sequence = cc.Sequence:create(delay, func)
    self.m_pUILayer:runAction(sequence)
end

return KaPaiBagMainUI