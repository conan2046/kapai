local FishBasketDelegate = require("View.Activity.FishBasketDelegate")
local FishControlDelegate = require("View.Activity.FishControlDelegate")
local FishUserListDelegate = require("View.Activity.FishUserListDelegate")

local FishUI = LUIBase:New()
FishUI.__index = FishUI
FishUI.IsHideInBattle = true

function FishUI:New()
    local o = {}
    setmetatable(o,FishUI)  
    o:Init()
    return o
end

--[[
注册UI消息
]]
function FishUI:RegistMsgs()
    self.msgIds = 
    {
        LUIFishEvent.UpdateState,
    }
    self:RegistSelf(self,self.msgIds)
end

function FishUI:ProcessEvent(msg)
    if msg.msgId == LUIFishEvent.UpdateState then
        local isFishing = msg.value[1]
        self.m_pFishUI:setTouchEnabled(isFishing)
    end
end

function FishUI:Init()
    self.m_pFishUI = nil
    -------------------------------
    self.m_pFishBasketDelegate = nil
    self.m_pFishControlDelegate = nil
    self.m_pFishUserListDelegate = nil
    -------------------------------
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
end

function FishUI:InitUIControl()
    local pFishUI = self.m_pUILayer:getChildByName("FishUI")
    pFishUI:addClickEventListener(handler(self, FishUI.AutoMoveClick))
	self:MarkIntaractCObj(pFishUI)
    self.m_pFishUI = pFishUI
    ---------------------------------------
    local pPanel_caozuo = pFishUI:getChildByName("Panel_caozuo")
    self.m_pFishControlDelegate = FishControlDelegate:New(pPanel_caozuo)
    ---------------------------------------
    local pyulan = pFishUI:getChildByName("yulan")
    self.m_pFishBasketDelegate = FishBasketDelegate:New(pyulan)
    ---------------------------------------
    self.m_pFishUserListDelegate = FishUserListDelegate:New(pFishUI)
	
    local pPanel = self.m_pFishUI:getChildByName("Panel")
	local pHelpBtn = pPanel:getChildByName("btn_Help")
    pHelpBtn:addClickEventListener(function(sender)
        self:helpButtonCallback()
    end)
	self:MarkIntaractCObj(pHelpBtn)
end

function FishUI:helpButtonCallback()

    str = string.format("%s%s%s%s%s", GUITips.RSI_HSD_TIP120, GUITips.RSI_HSD_TIP121, GUITips.RSI_HSD_TIP122, GUITips.RSI_HSD_TIP123, GUITips.RSI_HSD_TIP124) 

    local function OKCallback()
    end
    local msgData = {
        okCallback = OKCallback,
        desc = str
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIMsgBoxEvent.ShowMsgBox, msgData)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function FishUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/FishLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

function FishUI:onExit()
    self:Destory()
    self.m_pFishUI = nil
    -------------------------------
    self.m_pFishBasketDelegate = nil
    self.m_pFishControlDelegate = nil
    self.m_pFishUserListDelegate = nil
end

function FishUI:AutoMoveClick(sender)
    local function okFunc()
        LuaNetSendMsg:QueryFishingInfo(10)
    end
    local function cancelFunc()
    end
    Utils:ShowDialogOKCancel(GUITips.RSI_FISH_TIP14, okFunc, cancelFunc)
end

return FishUI