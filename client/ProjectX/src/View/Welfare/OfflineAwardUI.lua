-- ------------------------------
-- 离线奖励


local OfflineAwardUI = LUIBase:New()
OfflineAwardUI.__index = OfflineAwardUI

-- ----------------------------------------------
-- 常量区
local ScriptPath = "Welfare.OfflineAwardUI"
local CsbFilePath = "csd/OffLineLayer.csb"

-- ----------------------------------------------
local _DEBUG = false
-- local function --Debug(msg)
--     if not _DEBUG then return end
--     
-- end


-- ----------------------------------------------
local function _ShowTipsWindow(ui, msg)
    LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, msg)
    ui:SendMsg(LGameMsg.m_scrollTipsMsg)
end

-- ----------------------------------------------
local function _BindClickFunctionToButton(btn,fuc)
    btn:addClickEventListener(fuc)
	OfflineAwardUI:MarkIntaractCObj(btn)
end

-- ----------------------------------------------
function OfflineAwardUI:New()
    local o = LUIBase:New()
    setmetatable(o, OfflineAwardUI)
    o:Init()
    return o
end

-- ----------------------------------------------
function OfflineAwardUI:RegistMsgs()
    self.msgIds = 
    {
        LUIOfflineAwardEvent.OfflineInfo,
        LUIOfflineAwardEvent.GetOfflineExp, 
    }
    self:RegistSelf(self, self.msgIds)
end

-- ----------------------------------------------
function OfflineAwardUI:ProcessEvent(msg)
    if msg.msgId == LUIOfflineAwardEvent.OfflineInfo then
        self:OnOfflineInfo(msg.value)
    end

    if msg.msgId == LUIOfflineAwardEvent.GetOfflineExp then
        self:OnGetOfflineExp(msg.value)
    end

end

function OfflineAwardUI:OnOfflineInfo(rsp)
    self.expinfo = rsp
    --Debug(rsp)
    self:DrawInfo()

    LGameMsg.m_baseMsgWithOne:Change(LUIOnlineAwardEvent.KaifuReddotRefresh,5)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end 

function OfflineAwardUI:OnGetOfflineExp(rsp)
    --Debug(rsp)
    self:QueryOfflineExpInfo()
end 


-- ----------------------------------------------
function OfflineAwardUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.rpanel = nil
    self.lpanel = nil
end

-- ----------------------------------------------
function OfflineAwardUI:RegisterQuik()
    local function onNodeEvent(event)        
        if "exit" == event then
            --Debug("onNodeEvent")
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

end

-- ----------------------------------------------
function OfflineAwardUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode(CsbFilePath)
    local rootnode = self.m_pUILayer:getChildByName("OffLineUI")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    self.topui = rootnode:getChildByName("Top")
    self.freeui = rootnode:getChildByName("free")
    self.freeui:getChildByName("Describe"):setString("")
    self.freeui:getChildByName("Exp"):setString("")
    self.goldui = rootnode:getChildByName("Gold")
    self.goldui:getChildByName("Describe"):setString("")
    self.goldui:getChildByName("Exp"):setString("")
    self.vipui = rootnode:getChildByName("Vip")
    self.vipui:getChildByName("Describe"):setString("")
    self.vipui:getChildByName("Exp"):setString("")
    
    self.topui:getChildByName("Text"):setVisible(false)
    self.type = -1

    local function getOfflineExp()
        if self.type >= 0 and self.type <= 2 then
            LuaNetSendMsg:GeOfflineExp(self.type)
        end
    end

    local function cancelCallback( ... )
        self.type = -1
    end

    local function msgBox(string)
        local userData =
        {
            okCallback = getOfflineExp,
            cancelCallback = cancelCallback,
            desc = string
        }
        -- LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Common.MsgBoxUI",AppDef.UIType.FirstClassLayer, userData)
        -- LUIManager:SendMsg(LGameMsg.m_initUIMsg)
        Utils:SendMsg(LUIMsgBoxEvent.ShowMsgBox, userData)
    end
    -- =============================
    -- 绑定button函数
    local function OnFreeButtonClick(btn)
        self.type = 0
        msgBox(GUITips.RSI_WOLEL_TIP_MIN)
    end
    
    local function OnGoldButtonClick(btn)
        if not self.expinfo then return end 
        self.type = 1
        msgBox(string.format(GUITips.RSI_WOLEL_TIP2, self.expinfo.shoufeiMoney))
    end
    
    local function OnVipButtonClick(btn)
        local vip = LRoleDataMgr.MyHeroInfo.vipLevel
        if vip == 0 then
            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Vip.VipMainUI",AppDef.UIType.FirstClassLayer, 1)
            self:SendMsg(LGameMsg.m_initUIMsg)
        else
            self.type = 2
            msgBox(string.format(GUITips.RSI_WOLEL_TIP3, vip))
        end
    end

    local btn = self.freeui:getChildByName("btn_Retrieve")
    _BindClickFunctionToButton(btn, OnFreeButtonClick)
    btn = self.goldui:getChildByName("btn_Retrieve")
    _BindClickFunctionToButton(btn, OnGoldButtonClick)
    btn = self.vipui:getChildByName("btn_Retrieve")
    _BindClickFunctionToButton(btn, OnVipButtonClick)

end

function OfflineAwardUI:DrawInfo()
    if not self.expinfo then return end 

    -- ========================
    -- 画上top
    local totaltime = self.expinfo.minu_t.."分钟"
    self.topui:getChildByName("Time"):getChildByName("Value"):setString(totaltime)
    local expsum = self.expinfo.shoufei
    self.topui:getChildByName("Exp"):getChildByName("Value"):setString(expsum)


    local function ColorText(text, str)
        text:removeAllChildren()
        ttf = CCAysLabel:createWithString(str, text:getContentSize().width, text:getFontSize(), text:getTextColor())
        ttf:setPositionY(text:getPositionY() - text:getContentSize().height/2)
        ttf:setTag(123)
        text:addChild(ttf,1,1)
    end
    -- ======================
    -- 画免费
    local ratstr = string.format(GUITips.RSI_WOLEL_TIP4, self.expinfo.belv_outLine, self.expinfo.mianfei)
    ColorText(self.freeui:getChildByName("Describe"), "\r\n"..ratstr)
    if self.expinfo.mianfei <= 0 then 
        self.freeui:getChildByName("btn_Retrieve"):setEnabled(false)
    end 
    
    ratstr = string.format(GUITips.RSI_WOLEL_TIP5, self.expinfo.shoufeiRate, self.expinfo.shoufei)
    ColorText(self.goldui:getChildByName("Describe"), "\r\n"..ratstr)
    if self.expinfo.shoufei <= 0 then 
        self.goldui:getChildByName("btn_Retrieve"):setEnabled(false)
    end 
    
    local vip = LRoleDataMgr.MyHeroInfo.vipLevel
    if vip == 0 then
        ColorText(self.vipui:getChildByName("Describe"), "\r\n"..GUITips.RSI_WOLEL_TIP7)
        self.vipui:getChildByName("btn_Retrieve"):getChildByName("Text"):setString(GUITips.RSI_WOLEL_TIP8)
    else
        ratstr = string.format(GUITips.RSI_WOLEL_TIP6, LRoleDataMgr.MyHeroInfo.vipLevel, self.expinfo.vipRate, self.expinfo.vip)
        ColorText(self.vipui:getChildByName("Describe"), "\r\n"..ratstr)
        if self.expinfo.vip <= 0 then 
            self.vipui:getChildByName("btn_Retrieve"):setEnabled(false)
        end
    end
end 

-- ----------------------------------------------
local ITMENUM = 3
local tagid = 1886
function OfflineAwardUI:InitUIControl()

end 


-- ----------------------------------------------
function OfflineAwardUI:Init()
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:RegisterQuik()
    self:QueryOfflineExpInfo()
end

function OfflineAwardUI:QueryOfflineExpInfo()
    LuaNetSendMsg:QueryOfflineExpInfo()
end


-- ----------------------------------------------
return OfflineAwardUI