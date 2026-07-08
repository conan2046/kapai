
local PetKaPaiStarUpUI = LUIBase:New()
PetKaPaiStarUpUI.__index = PetKaPaiStarUpUI
--local this = LTcpSocket
function PetKaPaiStarUpUI:New()
	local o = LUIBase:New()
	setmetatable(o,PetKaPaiStarUpUI)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function PetKaPaiStarUpUI:RegistMsgs()
    self.msgIds = 
    {
        LUIRedDotEvent.UpdateRedDotState,
        LUIBagEvent.BagDataChanged,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function PetKaPaiStarUpUI:ProcessEvent(msg)
    if msg.msgId == LUIRedDotEvent.UpdateRedDotState then
        self:updateRedDot(msg.value)
    elseif msg.msgId == LUIBagEvent.BagDataChanged then
        self:updateItemUI()
    end
end

function PetKaPaiStarUpUI:Init()

    self.m_pUILayer = cc.CSLoader:createNode("csd/shenjiangyangcheng/yingxiongshengxingLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    self:RegistMsgs()

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:initControlUI()
    self:RegisterGuide()
end

function PetKaPaiStarUpUI:UpdateData( petData )
    -- body
    self._petData = petData
    self:UpdateUI()
end

function PetKaPaiStarUpUI:initControlUI( ... )
    -- body
    local shenjiangInfoUI = self.m_pUILayer:getChildByName("yingxiongshengxingUI")

    ----------------------------------------------------------
    local info = shenjiangInfoUI:getChildByName("Info")
    
    local jichu = info:getChildByName("jichu")

    self._attrList = {}
    for i=1, 4 do
        local Attribute = jichu:getChildByName("Attribute_"..i)
        table.insert(self._attrList, Attribute)
    end

    self._StarList = jichu:getChildByName("StarList")

    local Btn_Skill =jichu:getChildByName("Btn_Skill")
    self._icon = Btn_Skill:getChildByName("Icon")
    
    self._skillName = jichu:getChildByName("SkillName")
    local ScrollView = jichu:getChildByName("ScrollView")
    ScrollView:setScrollBarEnabled(false)
    local _SkillInfo = ScrollView:getChildByName("SkillInfo")
    self._SkillInfo = Utils:CreateColorText3(_SkillInfo, true)

    local Btn_xiangxi = jichu:getChildByName("Btn_xiangxi")
    Btn_xiangxi:addClickEventListener(function ( sender )
        -- body
        Utils:InitUI("KaPaiPet.PetStarUpAdditionUI", AppDef.UIType.PopWindow, self._petData)
    end)

    ----------------------------------------------------------
    local cailiao = info:getChildByName("cailiao")
    self._cailiao = cailiao
    local wanNengSP = cailiao:getChildByName("Btn_suipian")
    wanNengSP:addClickEventListener(function(sender)
        -- body
        Utils:InitUI("Common.FragmentTransUI", AppDef.UIType.PopWindow, self._petData.baseData.itemId)
    end)
    wanNengSP:setVisible(false)

    local starUp = cailiao:getChildByName("Btn_shengxing")
    starUp:addClickEventListener(handler(self,PetKaPaiStarUpUI.BtnCallBack))
    self.m_guideBtn = starUp

    self._spName = cailiao:getChildByName("Name")


    self.spIcon = cailiao:getChildByName("Icon")

    local Slider_Bg = cailiao:getChildByName("Slider_Bg")
    self._LoadingBar = Slider_Bg:getChildByName("LoadingBar")

    self._value = Slider_Bg:getChildByName("Value")
    -------------------------------------------------------------------------
    self._manji = info:getChildByName("manji")

end

function PetKaPaiStarUpUI:BtnCallBack( ... )
    LRoleDataMgr.tempPetUpStarData = Utils:deepCopy(self._petData) 
    -- dump(LRoleDataMgr.tempPetUpStarData.attrs, "pDdata 22222222222222222222 =================================>")
    LuaNetSendMsg:QueryPetStarUp(self._petData.id)
end

function PetKaPaiStarUpUI:ResetStarState( ... )
    -- body
    for i=1, 8 do
        local Star = self._StarList:getChildByName("Star_"..i)
        Star:setVisible(false)
    end
end

function PetKaPaiStarUpUI:UpdateUI( ... )
    -- body
    self:ResetStarState()
    for i=1, self._petData.star do
        local Star = self._StarList:getChildByName("Star_"..i)
        Star:setVisible(true)
        Star:loadTexture("res/UI/ui_common_new/ui_common_xing.png", ccui.TextureResType.plistType)
    end

    local attr = PetkaPaiManager:GetPetStarGrowAttr(self._petData)
    if attr ~= nil then
        for i=1, #self._attrList do
            self._attrList[i]:setString(AppDef.EAttrTypeName[i]) 
            local text = self._attrList[i]:getChildByName("Value")
            if self._petData.star >= AppDef.Pet.MaxStar then
                text:setString(attr[i])
            else
                text:setString("+"..attr[i])
            end
        end
    end

    local petConfigData = JsonConfig.m_heroCfg.getDefByID(self._petData.id)
    if petConfigData and #petConfigData.skills > 0 then 
        local skillId = petConfigData.skills[1]
        local imagefile = string.format("Skill/UI/skill_%d.png", skillId)
        self._icon:loadTexture(imagefile, ccui.TextureResType.localType)

        local skillLevel = PetkaPaiManager:GetPetSkillLvByStar(self._petData.star)
        local curDesc = LDataConstMgr:GetHeroSkillDesc(skillId, skillLevel)
        self._SkillInfo:setString(curDesc)

        local skillData = LSkillMgr:getSkillById(skillId)
        self._skillName:setString(skillData.name)
    end

    if self._petData.star >= AppDef.Pet.MaxStar then
        --满星了
        self._cailiao:setVisible(false)
        self._manji:setVisible(true)
    else
        self._cailiao:setVisible(true)
        self._manji:setVisible(false)

        self:updateItemUI()

    end

    --初始化红点
    self:setLvUpRedDot()

end

function PetKaPaiStarUpUI:updateItemUI( ... )
    -- body
    local num = LRoleDataMgr.Equip:CountItemNumById(self._petData.baseData.itemId)
    print("self._petData.itemId =", self._petData.baseData.itemId, num)
    Utils:GetItemCellValue(self.spIcon, 0, self._petData.baseData.itemId, true, true, num, nil, true)
    local nameStr = Utils:getItemNameByID(self._petData.itemId)
    self._spName:setString(nameStr)

    local cost = PetkaPaiManager:getPetStarUpCost(self._petData)
    self._value:setString(string.format("%d/%d", num, cost))
    local percent = num / cost * 100
    if percent > 100 then 
        percent = 100
    end
    self._LoadingBar:setPercent(percent)
end

function PetKaPaiStarUpUI:getCurPetIsShowRed( ... )
    -- body
    local isCanLvUp = PetkaPaiManager:isPetCanStarUp( self._petData )
    return isCanLvUp
end

function PetKaPaiStarUpUI:onExit()
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep,GuideDef.StepId.Guide_FuBen3_7)
    self.m_pUILayer = nil
    self:Destory()
end

function PetKaPaiStarUpUI:RegisterGuide()
    Utils:RegisterGuide(GuideDef.StepId.Guide_FuBen3_7, self.m_guideBtn, handler(self,PetKaPaiStarUpUI.BtnCallBack), nil, true)
end

function PetKaPaiStarUpUI:updateRedDot(data)
    -- body
    if data then
        if data.id == RedDotDef.ID.ShenJiang_StarUp then
            self:setLvUpRedDot()
        end
    else
        self:setLvUpRedDot()
    end
end

function PetKaPaiStarUpUI:setLvUpRedDot( ... )
    -- body
    local isShow = self:getCurPetIsShowRed()
    Utils:SendMsg(LUIRedDotEvent.SetRedDotState, {id=RedDotDef.ID.ShenJiang_StarUp, isShow=isShow})
    self.m_guideBtn:getChildByName("Prompt"):setVisible(isShow)

end

return PetKaPaiStarUpUI