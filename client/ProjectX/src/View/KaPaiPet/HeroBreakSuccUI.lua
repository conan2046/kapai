local HeroBreakSuccUI = LUIBase:New()
HeroBreakSuccUI.__index = HeroBreakSuccUI
--local this = LTcpSocket
function HeroBreakSuccUI:New(petId)
    local o = LUIBase:New()
    setmetatable(o,HeroBreakSuccUI)    
    o:Init(petId)
    return o
end

--注册事件
-- -----------------------------------
function HeroBreakSuccUI:RegistMsgs()
    self.msgIds = 
    {
        -- LUIKaPaiPetEvent.ShowPetLeftInfo,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function HeroBreakSuccUI:ProcessEvent(msg)
    -- if msg.msgId == LUIKaPaiPetEvent.ShowPetLeftInfo then
    -- end
end

function HeroBreakSuccUI:Init(petId)
    self.Script = "KaPaiPet.HeroBreakSuccUI"
    self:InitMembers(petId)
    self:AddTouchEvt()
    self:InitBreakConfig()
    self:InitShow()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    self:RegisterGuide()
end

function HeroBreakSuccUI:InitMembers(petId)
    self.m_pUILayer = cc.CSLoader:createNode("csd/shenjiangyangcheng/yingxiongtupoendLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    local infoBg = self.m_pUILayer:getChildByName("shengxingchenggongUI"):getChildByName("Info")
    self.m_blackBg = self.m_pUILayer:getChildByName("shengxingchenggongUI"):getChildByName("Mask")
    self.m_preIconColor = infoBg:getChildByName("IconColor")
    self.leftAddName = self.m_preIconColor:getChildByName("add")
    self.m_preIcon = self.m_preIconColor:getChildByName("Icon")
    self.m_curIconColor = infoBg:getChildByName("IconColor_0")
    self.rightAddName = self.m_curIconColor:getChildByName("add")
    self.m_curIcon = self.m_curIconColor:getChildByName("Icon")

    self.m_attrText = {}
    for i=1,4 do
        self.m_attrText[i] = infoBg:getChildByName("Attribute_"..i)
    end
    self.m_tianfuText =  infoBg:getChildByName("Value_1")
    self.m_petData = LRoleDataMgr.Pet:GetPetById(petId)
    if self.m_petData == nil then
        return
    end
    self.m_closeBtn = self.m_pUILayer:getChildByName("shengxingchenggongUI"):getChildByName("Close")
end

function HeroBreakSuccUI:AddTouchEvt()
    local function ClickCallback(sender)
        LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "KaPaiPet.HeroBreakSuccUI")
        LUIManager:SendMsg(LGameMsg.m_deleteUIMsg)
    end
    self.m_blackBg:addTouchEventListener(ClickCallback)
    self:MarkIntaractCObj(self.m_blackBg)
end

function HeroBreakSuccUI:onExit()
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_FuBen2_8)
    self.m_pUILayer = nil
    self.m_blackBg = nil
    self.m_preIconColor = nil
    self.m_preIcon = nil
    self.m_curIconColor = nil
    self.m_curIcon = nil
    self.m_heroCfg = nil
    self.m_breakAttrCfg = nil
    self.m_breakTeamAttrCfg = nil
    self.m_breakSkillCfg = nil
    self.m_attrText = nil
    self.Script = nil
    self:Destory()
    Utils:CheckGuide(GuideDef.StepId.Guide_FuBen2_9, true)
end

function HeroBreakSuccUI:InitBreakConfig()
    self.m_heroCfg = JsonConfig.m_heroCfg.getDefByID(self.m_petData.id)
    print("InitBreakConfig ===>", self.m_petData.breakLevel)
    self.breakdata = JsonConfig.m_petBreakCost.getDefByID(self.m_petData.breakLevel)
end

function HeroBreakSuccUI:InitShow()
    if self.breakdata == nil then
        return
    end
    Utils:ShowPetHeadImg(self.m_preIcon, self.m_petData.baseData.pic,
        self.m_preIconColor, self.m_petData.baseData.quality, self.m_petData:IsShiny())
    Utils:ShowPetHeadImg(self.m_curIcon, self.m_petData.baseData.pic,
        self.m_curIconColor, self.m_petData.baseData.quality, self.m_petData:IsShiny())

    self.leftAddName:setString(self.m_petData.baseData.name .. "+"..(self.m_petData.breakLevel - 1))
    self.rightAddName:setString(self.m_petData.baseData.name .. "+"..self.m_petData.breakLevel)

    for i=1, 4 do
        self.m_attrText[i]:setString(AppDef.EAttrTypeName[i])
        local addValue = self.m_petData.baseData.growAttrs[i] * self.breakdata.attr
        self.m_attrText[i]:getChildByName("Value"):setString(tostring(self.m_petData.attrs[i] + addValue))
    end

    self.m_tianfuText:setString(PetkaPaiManager:getBreakAttrStrByLv(self.m_petData, self.m_petData.breakLevel))

end

function HeroBreakSuccUI:RegisterGuide()
    Utils:RegisterGuide(GuideDef.StepId.Guide_FuBen2_8, self.m_closeBtn, handler(self, HeroBreakSuccUI.RemoveUI), nil, true)
end

return HeroBreakSuccUI