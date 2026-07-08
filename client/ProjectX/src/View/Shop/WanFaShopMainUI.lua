--[[
lua  社交
]]
local WanFaShopMainUI = LUIBase:New()
WanFaShopMainUI.__index = WanFaShopMainUI
    
local funcArr = {
    AppDef.EModuleID.EMID_SHOP_JINGJI,
    AppDef.EModuleID.EMID_SHOP_XUEZHAN,
    AppDef.EModuleID.EMID_SHOP_BANGPAI,
    AppDef.EModuleID.EMID_SHOP_KUNLUN,
    AppDef.EModuleID.EMID_SHOP_TURNTABLE,
}

--local this = LTcpSocket
function WanFaShopMainUI:New(openTab)
	local o = LUIBase:New()
	setmetatable(o,WanFaShopMainUI)	
    o:Init(openTab)
	return o
end

function WanFaShopMainUI:Init(openTab)
    self.Script = "Shop.WanFaShopMainUI"
    self:RegistMsgs()
    self.m_pUILayer = cc.Node:create()
    self.m_pSubLayer = {}
    self.m_curUIInd = 0
    self:InitTouchEvt()

    --title
    LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.SetTitle, GUITips.RSI_SHOP_WANFA)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local function tabBtnClicked(ind)
        return self:TabClicked(ind)
    end
    local tabValues = 
    {
    --, GUITips.RSI_SOCIAL_MASTER, GUITips.RSI_SOCIAL_SPOUSE 屏蔽师徒和夫妻
        -- {GUITips.RSI_SHOP_WANFA_TAG1, GUITips.RSI_SHOP_WANFA_TAG2, RSI_SHOP_WANFA_TAG3, RSI_SHOP_WANFA_TAG4},
        {GUITips.RSI_SHOP_WANFA_TAG1, GUITips.RSI_SHOP_WANFA_TAG2, GUITips.RSI_SHOP_WANFA_TAG3, GUITips.RSI_SHOP_WANFA_TAG4, GUITips.RSI_SHOP_WANFA_TAG7},
        tabBtnClicked
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.AddTabBtn, tabValues)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    self._openTab = openTab
    --进商店前，先请求数据
    LuaNetSendMsg:QueryXueZhanInfo(15)
end

function WanFaShopMainUI:RegisterGuide()
    -- if true then
    --     return
    -- end
    -- if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SHOP_JINGJI, true) then
    --     return
    -- end
    -- --------------------------------------------------------------------------
    -- -- local msg = {}
    -- -- msg.stepId = GuideDef.StepId.Guide_SHEJ_1
    -- -- msg.tabIndex = 2
    -- -- LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.RegisterTabGuide, msg)
    -- -- self:SendMsg(LGameMsg.m_baseMsgWithOne)
    -- --------------------------------------------------------------------------
    -- LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.RegisterCloseGuide, GuideDef.StepId.Guide_SHEJ_FINISH)
    -- self:SendMsg(LGameMsg.m_baseMsgWithOne)
    -- --------------------------------------------------------------------------
end

--[[
注册消息
]]
function WanFaShopMainUI:RegistMsgs()
    self.msgIds = 
    {
        LUIXueZhanEvent.GetActivityInfo,
        LUIRedDotEvent.UpdateRedDotState,
    }
    self:RegistSelf(self,self.msgIds)
end

function WanFaShopMainUI:ProcessEvent(msg)
    if msg.msgId == LUIXueZhanEvent.GetActivityInfo then
        -- print("WanFaShopMainUI:ProcessEvent ===>", msg.msgId, self._openTab)
        self:TabClicked(self._openTab)
        LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.SelectTab, self._openTab)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
        --self:RegisterGuide()
    elseif msg.msgId == LUIRedDotEvent.UpdateRedDotState then
        self:updateHotDot(msg.value)
    end
end

function WanFaShopMainUI:onExit()
    -- Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_SHEJ_1)
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_SHEJ_FINISH)
    self.m_pUILayer = nil
    self.m_curUIInd = nil
    self._openTab = nil
    self:Destory()
end

function WanFaShopMainUI:InitTouchEvt()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    
    local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Shop.WanFaShopMainUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

end


function WanFaShopMainUI:HideCurUI()
    if self.m_pSubLayer[self.m_curUIInd] == nil then
        return
    end
    self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(false)
end

function WanFaShopMainUI:ShowCurUI()
    
     if self.m_pSubLayer[self.m_curUIInd] == nil then
        self:DelayLoadSubUI(self.m_curUIInd)
    else
        self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(true)
    end
    
end

function WanFaShopMainUI:TabClicked(ind)
    if  self.m_curUIInd == ind then
        return false
    end

    local funcId = funcArr[ind]
    if Utils:CheckModelNotOpened(funcId) then
        return false
    end

    if self.m_curUIInd ~= 0 then
     self:HideCurUI()
    end

    self.m_curUIInd = ind
    self:ShowCurUI()
    return true
end

function WanFaShopMainUI:DelayLoadSubUI(tabInd)
    --,"View.Social.MasterUI",
    local uinames = {"View.Shop.JingjiShopUI","View.Shop.XueZhanShopUI", "View.Shop.BangPaiShopUI", "View.Shop.KunLunShopUI", "View.Shop.TurntableShopUI"}
    local ind = tabInd
    local delay = cc.DelayTime:create(0.1)
    local function loadSubUI()
        if self.m_curUIInd ~= ind then
            return
        end
        self.m_pSubLayer[ind] = require(uinames[ind]):New()
        self.m_pUILayer:addChild(self.m_pSubLayer[ind].m_pUILayer)
        self:updateHotDot()
    end
    local func = cc.CallFunc:create(loadSubUI)
    local sequence = cc.Sequence:create(delay, func)
    self.m_pUILayer:runAction(sequence)
end

function WanFaShopMainUI:updateHotDot(data)
    -- body
    if data then
        print("PetKaPaiMainUI:updateHotDot ==>", data.id, data.isShow)
        if data.id == RedDotDef.ID.ShopWanFaJingji then
            LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.RedDotState, {1, data.isShow})
            self:SendMsg(LGameMsg.m_baseMsgWithOne)
        elseif data.id == RedDotDef.ID.ShopWanFaXueZhan then
            LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.RedDotState, {2, data.isShow})
            self:SendMsg(LGameMsg.m_baseMsgWithOne)
        end
    else
        local isJJOpen = not Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SHOP_JINGJI, true)
        local isShowJJ = Utils:GetRedDotState(RedDotDef.ID.ShopWanFaJingji) and isJJOpen

        LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.RedDotState, {1, isShowJJ})
        self:SendMsg(LGameMsg.m_baseMsgWithOne)

        local isXZOpen = not Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SHOP_XUEZHAN, true)
        local isShowXZ = Utils:GetRedDotState(RedDotDef.ID.ShopWanFaXueZhan) and isXZOpen
        -- print("WanFaShopMainUI:updateHotDot ==>", isShowJJ, isShowXZ)
        LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.RedDotState, {2, isShowXZ})
        self:SendMsg(LGameMsg.m_baseMsgWithOne)

    end
end


return WanFaShopMainUI