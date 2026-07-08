local BangPaiXianZunGeUI = LUIBase:New()
BangPaiXianZunGeUI.__index = BangPaiXianZunGeUI

-----------------------------------
function BangPaiXianZunGeUI:New()
    local o = {}
    setmetatable(o, BangPaiXianZunGeUI)
    o:Init()
    return o
end

-----------------------------------
function BangPaiXianZunGeUI:Init()
    self.Script = "BangPai.BangPaiXianZunGeUI"
    -------------------------------------------------------
    self.m_pCurYingXiangLi = nil
    self.m_pCurZiJin = nil
    self.m_pCurLevel = nil
    self.m_pCurEffect = nil
    self.m_pNextLevel = nil
    self.m_pNextEffect = nil
    self.m_pNeedYingXiangLi = nil
    self.m_pNeedZiJin = nil
    -------------------------------------------------------

    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()

    LuaNetSendMsg:QueryFactionXianZunGe()
end

-----------------------------------
function BangPaiXianZunGeUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_pCurYingXiangLi = nil
    self.m_pCurZiJin = nil
    self.m_pCurLevel = nil
    self.m_pCurEffect = nil
    self.m_pNextLevel = nil
    self.m_pNextEffect = nil
    self.m_pNeedYingXiangLi = nil
    self.m_pNeedZiJin = nil
end

-----------------------------------
function BangPaiXianZunGeUI:RegistMsgs()
    self.msgIds = {
        LUIBangPaiEvent.ReloadXianZunGeMsg,
    }
    self:RegistSelf(self, self.msgIds)
end

-----------------------------------
function BangPaiXianZunGeUI:ProcessEvent(msg)
    if msg.msgId == LUIBangPaiEvent.ReloadXianZunGeMsg then
        self:updateData(msg.value)
    end
end

function BangPaiXianZunGeUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    Utils:SendMsg(LUIFClassBgEvent.SetCloseCallback, handler(self, LUIBase.RemoveUI))
    Utils:SendMsg(LUIFClassBgEvent.SetTitle, GUITips.RSI_FACTION_TITLE6)
    Utils:SendMsg(LUIFClassBgEvent.AddTabBtn, nil)
end

-----------------------------------
function BangPaiXianZunGeUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/GuildXianzunLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

-----------------------------------
function BangPaiXianZunGeUI:InitUIControl()
    local panel = self.m_pUILayer:getChildByName("Panel")
    -----------------------------------
    local pImageBg = panel:getChildByName("ImageBg")
    local pBg1 = pImageBg:getChildByName("Bg1")
    self.m_pCurYingXiangLi = pBg1:getChildByName("Value")
    local pBg2 = pImageBg:getChildByName("Bg2")
    self.m_pCurZiJin = pBg2:getChildByName("Value")
    -----------------------------------
    local pDesBg = panel:getChildByName("DesBg")
    local pDes = pDesBg:getChildByName("Des")
    local pNowLevel = pDes:getChildByName("NowLevel")
    self.m_pCurLevel = pNowLevel:getChildByName("Text")

    local pNowEffect = pDes:getChildByName("NowEffect")
    self.m_pCurEffect = pNowEffect:getChildByName("Text")

    local pNextLevel = pDes:getChildByName("NextLevel")
    self.m_pNextLevelBg = pNextLevel
    self.m_pNextLevel = pNextLevel:getChildByName("Text")

    local pNextEffect = pDes:getChildByName("NextEffect")
    self.m_pNextEffectBg = pNextEffect
    self.m_pNextEffect = pNextEffect:getChildByName("Text")
    -----------------------------------
    local pNeedBg = pDesBg:getChildByName("NeedBg")
    local pBg1 = pNeedBg:getChildByName("Bg1")
    self.m_pNeedYingXiangLi = pBg1:getChildByName("Value")
    local pBg2 = pNeedBg:getChildByName("Bg2")
    self.m_pNeedZiJin = pBg2:getChildByName("Value")
    -----------------------------------
    local pButton = pNeedBg:getChildByName("Button")
    self.mUpButton = pButton
    pButton:addClickEventListener(handler(self, BangPaiXianZunGeUI.upgradeCallback))
	self:MarkIntaractCObj(pButton)
end

function BangPaiXianZunGeUI:updateData(info)
    self.mInfo = info

    self.m_pCurYingXiangLi:setString(tostring(info.yingxiangli))
    self.m_pCurZiJin:setString(tostring(info.money))
    self.m_pCurLevel:setString(info.level..GUITips.RSI_FACTION_MSG20)
    self.m_pCurEffect:setString(GUITips.RSI_FACTION_MSG21..info.ratio.."%")
    local function setNextVisible(visible)
        self.m_pNextLevel:setVisible(visible)
        self.m_pNextEffect:setVisible(visible)
        self.m_pNextLevelBg:setVisible(visible)
        self.m_pNextEffectBg:setVisible(visible)
    end

    if info.level == info.nextLv then
        setNextVisible(false)
    else
        setNextVisible(true)
        local nextUp = info.ratio + 1
        self.m_pNextLevel:setString(info.nextLv..GUITips.RSI_FACTION_MSG20)
        self.m_pNextEffect:setString(GUITips.RSI_FACTION_MSG21..nextUp.."%")
    end

    self.m_pNeedYingXiangLi:setString(tostring(info.LvUpYingXiangLi))
    self.m_pNeedZiJin:setString(tostring(info.LvUpMoney))
    
    if info.showLevelUpButton == 1 then
        self.mUpButton:setVisible(true)
    else
        self.mUpButton:setVisible(false)
    end
end

function BangPaiXianZunGeUI:upgradeCallback(sender)
    LuaNetSendMsg:QueryFactionUpXianZunGe()
end

return BangPaiXianZunGeUI