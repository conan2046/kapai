--[[
lua里面的游戏逻辑控制
]]

local VipMainUI = LUIBase:New()
VipMainUI.__index = VipMainUI

function VipMainUI:New(openTab)
	local o = LUIBase:New()
	setmetatable(o,VipMainUI)	
    o:Init(openTab)
	return o
end

function VipMainUI:Init(openTab)
    self.Script = "Vip.VipMainUI"
    self.m_pUILayer = cc.Node:create()
    self.m_pSubLayer = {}
    self.m_curUIInd = 0
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    self.m_titles = {GUITips.UI_Title_Recharge,GUITips.UI_Title_VIP}
    Utils:SendMsg(LUIFClassBgEvent.SetTitle, self.m_titles[openTab])
    local tabValues = 
    {
        {
            GUITips.UI_Title_Recharge,
            GUITips.UI_Title_VIP1,
        },
        handler(self,VipMainUI.TabClicked)
    }
    Utils:SendMsg(LUIFClassBgEvent.AddTabBtn, tabValues)
    Utils:SendMsg(LUIFClassBgEvent.SelectTab, openTab)
    Utils:SendMsg(LUIFClassBgEvent.SetCloseCallback, handler(self,VipMainUI.RemoveUI))
    self:TabClicked(openTab)
end

function VipMainUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
end

function VipMainUI:InitTouchEvt()

    local function ExitCallback(sender)
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Vip.VipMainUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    self.m_pCloseBtn:addClickEventListener(ExitCallback)
	self:MarkIntaractCObj(self.m_pCloseBtn)
end

function VipMainUI:TabClicked(ind)
    if self.m_curUIInd == ind then
        return
    end
    if self.m_curUIInd ~= 0 then
        self:HideCurUI()
    end
    self.m_curUIInd = ind
    self:ShowCurUI()
end

function VipMainUI:HideCurUI()
    if self.m_pSubLayer[self.m_curUIInd] == nil then
        return
    end
    self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(false)
end

function VipMainUI:ShowCurUI()
    
    if self.m_pSubLayer[self.m_curUIInd] == nil then
        self:DelayLoadSubUI(self.m_curUIInd)
    else
        self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(true)
    end
    Utils:SendMsg(LUIFClassBgEvent.SetTitle, self.m_titles[self.m_curUIInd])
end

function VipMainUI:DelayLoadSubUI(tabInd)
    local uinames = {"View.Vip.RechargeUI","View.Vip.NewVipUI"}
    local ind = tabInd
    local delay = cc.DelayTime:create(0.1)
    local function loadSubUI()
        if self.m_curUIInd ~= ind then
            return
        end
        self.m_pSubLayer[ind] = require(uinames[ind]):New()
        self.m_pUILayer:addChild(self.m_pSubLayer[ind].m_pUILayer)
    end
    local func = cc.CallFunc:create(loadSubUI)
    local sequence = cc.Sequence:create(delay, func)
    self.m_pUILayer:runAction(sequence)

    if tabInd == 1 and (LRoleDataMgr.MyHeroInfo.m_PayPricelist == nil or #LRoleDataMgr.MyHeroInfo.m_PayPricelist == 0) then
        LuaNetSendMsg:QueryPayPriceList()
    end
end

function VipMainUI:UpdateUserData(openTab)
    Utils:SendMsg(LUIFClassBgEvent.SelectTab, openTab)
    self:TabClicked(openTab)
end

return VipMainUI