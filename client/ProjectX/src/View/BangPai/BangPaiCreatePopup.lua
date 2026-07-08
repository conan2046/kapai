local BangPaiCreatePopup = LUIBase:New()
BangPaiCreatePopup.__index = BangPaiCreatePopup

local BangPaiDef = require("View.BangPai.BangPaiDef")
-- -----------------------------------
function BangPaiCreatePopup:New()
    local o = {}
    setmetatable(o, BangPaiCreatePopup)
    o:Init()
    return o
end

-- -----------------------------------
function BangPaiCreatePopup:Init()
    self.Script = "BangPai.BangPaiCreatePopup"
    self.m_costLabel = nil
    self.m_nameLabel = nil
    self.m_gongGaoLabel = nil
    self.m_isEnough = false

    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
end

-- -----------------------------------
function BangPaiCreatePopup:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_costLabel = nil
    self.m_nameLabel = nil
    self.m_gongGaoLabel = nil
    self.m_isEnough = nil
end

-- -----------------------------------
function BangPaiCreatePopup:RegistMsgs()
    self.msgIds = 
    {
        LUIBangPaiEvent.CreateCost,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function BangPaiCreatePopup:ProcessEvent(msg)
    if msg.msgId == LUIBangPaiEvent.CreateCost then
        self:CreateCost(msg.value)
    end
end

function BangPaiCreatePopup:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    Utils:SendMsg(LUISecondClassBgEvent.SetCloseCallback, handler(self, LUIBase.RemoveUI))
    Utils:SendMsg(LUISecondClassBgEvent.SetTitle, GUITips.RSI_FACTION_TITLE1)
end

-- -----------------------------------
function BangPaiCreatePopup:InitViewSize()
    self:CreateUINode("csd/bangpai/GangsfoundLayer.csb")
end

-- -----------------------------------
function BangPaiCreatePopup:InitUIControl()
    local panel = self.m_pUILayer:getChildByName("FoundGuild")

    local pCancelBtn = panel:getChildByName("CancelBtn")
    pCancelBtn:addClickEventListener(function(sender)
        self:RemoveUI()
    end)
    self:MarkIntaractCObj(pCancelBtn)

    local pEnterBtn = panel:getChildByName("EnterBtn")
    pEnterBtn:addClickEventListener(function()
        self:createBangPai()
    end)
	self:MarkIntaractCObj(pEnterBtn)

    local pGoldBg = panel:getChildByName("GoldBg")
    self.m_costLabel = pGoldBg:getChildByName("Num")
    self.m_costLabel:setString("")

    local pSearchBg = panel:getChildByName("SearchBg")
    self.m_nameLabel = pSearchBg:getChildByName("TextField")
    self.m_nameLabel:setString("")
    self.m_nameLabel:setCursorEnabled(true)

    local pInputBg = panel:getChildByName("InputBg")
    self.m_gongGaoLabel = pInputBg:getChildByName("InputText")
    self.m_gongGaoLabel:setString("")
    self.m_gongGaoLabel:setCursorEnabled(true)

    self:InitLevelSet()
end

function BangPaiCreatePopup:InitLevelSet()
    local panel = self.m_pUILayer:getChildByName("FoundGuild")

    local config = LDataConstMgr:GetFunctionLevelData(AppDef.EModuleID.EMID_BANGPAI)
    local limitValue = 20
    if config and config.open_condition and #config.open_condition > 0 then
        if config.open_condition[1].cType == 1 then
            limitValue = config.open_condition[1].cValue
        end
    end
    local pLevelSet = panel:getChildByName("LevelSet")
    local pBg = pLevelSet:getChildByName("Bg")
    local pSlider = pBg:getChildByName("Slider_1")
    local pText = pSlider:getChildByName("Text")
    self.m_pSliderText = pText

    local maxLevel = 100-limitValue+1

    local function SetLevel(level)
        local Showlevel = level
        if level > 0 then
            Showlevel = level + limitValue - 1
        end
        pSlider:setPercent(level)
        pText:setString(tostring(Showlevel))
        local pro = level/maxLevel
        pText:setPositionX(pro*pSlider:getContentSize().width)
    end
    
    pSlider:setMaxPercent(maxLevel)
    SetLevel(1)
    pSlider:addEventListener(function(sender, event)
        local persent = sender:getPercent()
        --print("persent =========>", persent)
        if persent <= 0 then
            persent = 1
        end
        SetLevel(persent)
    end)

    local checkBox = pLevelSet:getChildByName("CheckBox_1")
    local function autoIntoBPEvent( sender )
        -- body
        local isSelect = sender:isSelected()
        if isSelect then
            SetLevel(1)
        end
    end
    checkBox:addClickEventListener(autoIntoBPEvent)
    local isSelect = checkBox:isSelected()
    if not isSelect then
        SetLevel(1)
    end
end

function BangPaiCreatePopup:CreateCost(cost)
    local mymoney = LRoleDataMgr.MyHeroInfo.DetailData.TongBao
    self.m_isEnough = mymoney >= cost
    if not self.m_isEnough then
        self.m_costLabel:setTextColor(cc.c4b(255,0,0,255))
    else
        self.m_costLabel:setTextColor(cc.c4b(110,56,48,255))
    end
    self.m_costLabel:setString(tostring(cost))
end

function BangPaiCreatePopup:createBangPai()
    local name = self.m_nameLabel:getString()
    local gongGao = self.m_gongGaoLabel:getString()
    if #name == 0 then
        Utils:ShowScrollTips(GUITips.RSI_BP_TIP7)
        return
    end
    if #name > 20 then
        Utils:ShowScrollTips(GUITips.RSI_GM_TIP15)
        return
    end
    local isLimited = Utils:IsLimitedMsg(name)
    if isLimited then
        Utils:ShowScrollTips(GUITips.REI_TIPS_LIMITE_WORLD)
        return
    end
    if #gongGao == 0 then
        Utils:ShowScrollTips(GUITips.RSI_BP_TIP8)
        return
    end
    if #gongGao > 150 then
        Utils:ShowScrollTips(GUITips.RSI_GM_TIP13)
        return
    end
    if not self.m_isEnough then
        Utils:ShowScrollTips(GUITips.RSI_DSL_TIP_MIN)
        return
    end
    gongGao = Utils:FilterLimitedMsg(gongGao)
    local level = tonumber(self.m_pSliderText:getString())
    if level == nil or type(level) ~= 'number' then
        level = 0
    end
    LuaNetSendMsg:QueryBangPaiCreateByMoney(name, gongGao, 0, level)
    self:RemoveUI()
end

return BangPaiCreatePopup