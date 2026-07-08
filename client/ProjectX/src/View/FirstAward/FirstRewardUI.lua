local FirstRewardDef = require("View.FirstAward.FirstRewardDef")
----------------------------------------------
local FirstRewardUI = LUIBase:New()
FirstRewardUI.__index = FirstRewardUI
--战斗中是否隐藏
FirstRewardUI.IsHideInBattle = true
----------------------------------------------
function FirstRewardUI:New(userData)
    local o = {}
    setmetatable(o, FirstRewardUI)
    o:Init(userData)
    return o
end
----------------------------------------------
function FirstRewardUI:Init(userData)
    self.Script = "FirstAward.FirstRewardUI"
    ------------------------------------------
    self.m_type = userData[1]
    Utils:FreeTable(self.m_data)
    self.m_data = nil
    self.m_data = userData[2]
    self.m_pDelegate = nil
    ------------------------------------------
    self:InitViewSize()
    self:InitUIControl()
    self:RegisterQuik()
    self:UpdateUI()
end
----------------------------------------------
function FirstRewardUI:onExit()
    self:Destory()
    if self.m_pDelegate then
        for k,v in pairs(self.m_pDelegate) do
            if v and v.onExit then
                v:onExit()
            end
        end
    end
    self.m_pUILayer = nil
    self.rpanel = nil
    self.lpanel = nil
    self.m_type = nil
    Utils:FreeTable(self.m_data)
    self.m_data = nil
    self.m_pRootUI = nil
    self.m_pTitleText = nil
    self.m_pTitleImage = nil
end
----------------------------------------------
function FirstRewardUI:RegisterQuik()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
----------------------------------------------
function FirstRewardUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/FirstRewardLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end
----------------------------------------------
function FirstRewardUI:Reset()
    local pPanel = self.m_pUILayer:getChildByName("Reward")
    local pChildren = pPanel:getChildren()
    for i=1,#pChildren do
        pChildren[i]:setVisible(false)
    end
end
----------------------------------------------
function FirstRewardUI:InitUIControl()
    self:Reset()
    ----------------------------------------------
    local pPanel = self.m_pUILayer:getChildByName("Reward")
    self.m_pRootUI = pPanel

    local pBg = pPanel:getChildByName("bg")
    pBg:setVisible(true)

    local pPanel_1 = pPanel:getChildByName("Panel_1")
    pPanel_1:setVisible(true)
    ----------------------------------------------
    self.m_pTitleText = Utils:FindNodeByName(pBg, "Title/TitleBg/Text")
    self.m_pTitleImage = Utils:FindNodeByName(pBg, "Title/TitleBg/Image")
    -----------------------------------------
end
----------------------------------------------
function FirstRewardUI:updateDelegate()
    self.m_pDelegate = self.m_pDelegate or {}
    if self.m_pDelegate[tostring(self.m_type)] then
        return self.m_pDelegate[tostring(self.m_type)]
    end
    local pDeleagate = nil
    if self.m_type == FirstRewardDef.Type.TongTianTa then
        pDeleagate = require("View.FirstAward.TTTCopyDelegate"):New()
    elseif self.m_type == FirstRewardDef.Type.NomalFuBen then
        pDeleagate = require("View.FirstAward.NomalCopyDelegate"):New()
    elseif self.m_type == FirstRewardDef.Type.BattleFail then
        pDeleagate = require("View.FirstAward.FailCopyDelegate"):New()
    elseif self.m_type == FirstRewardDef.Type.FengShen then
        pDeleagate = require("View.FirstAward.FengShenDelegate"):New()
    end
    if pDeleagate then
        self.m_pDelegate[tostring(self.m_type)] = pDeleagate
    end
    return pDeleagate
end
----------------------------------------------
function FirstRewardUI:UpdateUI()
    if self.m_type == nil or self.m_type < FirstRewardDef.Type.BattleFail then 
        return 
    end
    self:UpdateTitle()
    local pDelegate = self:updateDelegate()
    if pDelegate and pDelegate.setData then
        pDelegate:setData({self, self.m_pRootUI, self.m_data})
    end
end
----------------------------------------------
function FirstRewardUI:UpdateTitle()
    if self.m_pTitleText then
        self.m_pTitleText:setString(GUITips["RSI_JIESUAN_TITLE" .. self.m_type])
    end 
    if self.m_type == FirstRewardDef.Type.BattleFail and self.m_pTitleImage then
        self.m_pTitleImage:loadTexture("res/UI/ui_xingongneng/ui_shibai_title_bg.png", UI_TEX_TYPE_PLIST)
    end
end
----------------------------------------------
return FirstRewardUI