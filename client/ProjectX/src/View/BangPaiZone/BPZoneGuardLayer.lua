local BPZoneGuardLayer = LUIBase:New()
BPZoneGuardLayer.__index = BPZoneGuardLayer

-- -----------------------------------
function BPZoneGuardLayer:New(data)
    local o = {}
    setmetatable(o, BPZoneGuardLayer)
    o:Init(data)
    return o
end

-- -----------------------------------
function BPZoneGuardLayer:Init(data)
    self.Script = "BangPaiZone.BPZoneGuardLayer"
    self.m_data = data

    self.m_pHeroBg = nil
    self.m_pTipsBg = nil
    self.m_pNameBg = nil
    self.m_pNameText = nil

    self.m_pLevelText = nil
    self.m_pStateText = nil
    self.m_pDesText = nil
    self.m_pDesText2 = nil
    self.m_pGuardInfoBtn = nil
    self.m_pGuardDoBtn = nil
    self.m_pGuardReleaseBtn = nil

    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    self:RegisterQuik()
    self:UpdateLayerInfo(data)
end

function BPZoneGuardLayer:RegistMsgs()
    self.msgIds = 
    {
        LUIBangPaiEvent.UpdateFactionZoneGuard,
    }
    self:RegistSelf(self, self.msgIds)
end

function BPZoneGuardLayer:RegisterQuik()
    Utils:SendMsg(LUISecondClassBgEvent.SetTitle, GUITips.RSI_BP_TIP5)
end

-- -----------------------------------
function BPZoneGuardLayer:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.Script = nil
    self.m_data = nil
    self.m_pHeroBg = nil
    self.m_pTipsBg = nil
    self.m_pNameBg = nil
    self.m_pNameText = nil
    self.m_pLevelText = nil
    self.m_pStateText = nil
    self.m_pDesText = nil
    self.m_pDesText2 = nil
    self.m_pGuardInfoBtn = nil
    self.m_pGuardDoBtn = nil
    self.m_pGuardReleaseBtn = nil
end

function BPZoneGuardLayer:ProcessEvent(msg)
    if msg.msgId == LUIBangPaiEvent.UpdateFactionZoneGuard then
        self:UpdateLayerInfo(msg.value)
    end
end

-----------------------------------
function BPZoneGuardLayer:InitUIControl()
    local pPanel = self.m_pUILayer:getChildByName("panel")
    local pBgImage = pPanel:getChildByName("BgImage")
    self.m_pTipsBg = pBgImage:getChildByName("BaseBg")
    self.m_pHeroBg = self.m_pTipsBg:getChildByName("Node")
    self.m_pNameBg = pBgImage:getChildByName("NameBg")
    self.m_pNameBg:setVisible(false)
    self.m_pNameBg:setLocalZOrder(1)
    self.m_pNameText = self.m_pNameBg:getChildByName("Name")

    local pBtnList = pPanel:getChildByName("BtnList")
    local pDesBg1 = pBtnList:getChildByName("DesBg1")
    self.m_pLevelText = pDesBg1:getChildByName("Text")
    self.m_pLevelText:setString("")

    local pDesBg2 = pBtnList:getChildByName("DesBg2")
    self.m_pStateText = pDesBg2:getChildByName("Text")
    self.m_pStateText:setString("")

    local pDesBg3 = pBtnList:getChildByName("DesBg3")
    self.m_pDesText = pDesBg3:getChildByName("Text")
    self.m_pDesText:setVisible(false)
    self.m_pDesText:setString("")

    self.m_pGuardInfoBtn = pBtnList:getChildByName("Button_1")
    self.m_pGuardInfoBtn:addClickEventListener(handler(self, BPZoneGuardLayer.ShowGuardInfo))
	self:MarkIntaractCObj(self.m_pGuardInfoBtn)

    self.m_pGuardDoBtn = pBtnList:getChildByName("Button_2")
    self.m_pGuardDoBtn:addClickEventListener(handler(self, BPZoneGuardLayer.DoGuard))
	self:MarkIntaractCObj(self.m_pGuardDoBtn)

    self.m_pGuardReleaseBtn = pBtnList:getChildByName("Button_3")
    self.m_pGuardReleaseBtn:addClickEventListener(handler(self, BPZoneGuardLayer.ReleaseGuard))
	self:MarkIntaractCObj(self.m_pGuardReleaseBtn)
end

function BPZoneGuardLayer:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    Utils:SendMsg(LUISecondClassBgEvent.SetCloseCallback, handler(self, LUIBase.RemoveUI))
end

-----------------------------------
function BPZoneGuardLayer:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/GuildGuardLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

function BPZoneGuardLayer:UpdateLayerInfo(info)
    if info == nil or self.m_data == nil then
        return
    end
    if self.m_data:GetAreaIndex() ~= info:GetAreaIndex() then
        return
    end

    local finfo = LRoleDataMgr.Faction:GetFactionInfo(info:GetFactionId())
    if finfo == nil then
        return
    end
    if info:GetOpenLevel() > finfo.level then
        return
    else
        local herohead = self.m_pHeroBg:getChildByTag(0xff01)
        if info:GetDetailInfo():GetId() == 0 then
            self.m_pNameBg:setVisible(false)
            self.m_pLevelText:setString("")
            self.m_pStateText:setString(GUITips.RSI_BP_TIP12)
            if self.m_pDesText2 then
                self.m_pDesText2:setString("")
            end
            local _ = herohead and herohead:setVisible(false)
            return
        end
        if herohead == nil then
            herohead = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, 
                                            info:GetDetailInfo():GetProfessional(), 
                                            info:GetDetailInfo():GetWeaponId(), 
                                            info:GetDetailInfo():GetWeaponEffect(),
                                            info:GetDetailInfo():GetWingsId(),
                                            0,
                                            info:GetDetailInfo():GetShenQiId())
            herohead:setScale(1.2)
            herohead:setPosition(cc.p(self.m_pHeroBg:getContentSize().width/2, self.m_pHeroBg:getContentSize().height))
            self.m_pHeroBg:addChild(herohead,0,0xff01)
        else
            herohead:InitAni(AppDef.CEnum.ModelAniType.Hero, 
                                            info:GetDetailInfo():GetProfessional(), 
                                            info:GetDetailInfo():GetWeaponId(), 
                                            info:GetDetailInfo():GetWeaponEffect(),
                                            info:GetDetailInfo():GetWingsId(),
                                            0,
                                            info:GetDetailInfo():GetShenQiId())
        end
        herohead:setVisible(true)
        herohead:PlayStand(0)

        self.m_pStateText:setString(GUITips.RSI_FACTION_MSG13)

        local level = GUITips.RSI_FACTION_MSG14 .. tostring(info:GetDetailInfo():GetLv())
        self.m_pLevelText:setString(level)

        local name = info:GetDetailInfo():GetName()
        self.m_pNameText:setString(name)
        self.m_pNameBg:setVisible(true)

        local desc = string.format("%s[c3]%s[/c]", GUITips.RSI_FACTION_MSG16, info:GetDesc())
        self.m_pDesText:setString(desc)
        local newLabel = CCAysLabel:createWithString(desc, self.m_pDesText:getContentSize().width, self.m_pDesText:getFontSize(), self.m_pDesText:getTextColor(), false)
        -- newLabel:triggleInit(desc, self.m_pDesText:getContentSize(), -130, UICOLOR_BROWN, 21, true, 10)
        local x,y = self.m_pDesText:getPosition()
        local size = newLabel:getSize()
        newLabel:setPosition(cc.p(x-size.width/2, y+size.height/2))
        self.m_pDesText:getParent():removeChildByTag(0xff01)
        self.m_pDesText:getParent():addChild(newLabel, 0, 0xff01)
        self.m_pDesText2 = newLabel
    end
end

function BPZoneGuardLayer:ShowGuardInfo(sender)
    LuaNetSendMsg:QueryFactionGuardInfo(LRoleDataMgr.Faction:GetPlantFactionId(), self.m_data:GetAreaIndex(), true)
    self:RemoveUI()
end

function BPZoneGuardLayer:DoGuard(sender)
    LuaNetSendMsg:QueryFactionGuardSet(LRoleDataMgr.Faction:GetPlantFactionId(), self.m_data:GetAreaIndex())
end

function BPZoneGuardLayer:ReleaseGuard(sender)
    LuaNetSendMsg:QueryFactionGuardRemove(LRoleDataMgr.Faction:GetPlantFactionId(), self.m_data:GetAreaIndex())
end

return BPZoneGuardLayer