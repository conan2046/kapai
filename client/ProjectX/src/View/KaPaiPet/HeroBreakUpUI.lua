
local HeroBreakUpUI = LUIBase:New()
HeroBreakUpUI.__index = HeroBreakUpUI
--local this = LTcpSocket
function HeroBreakUpUI:New()
	local o = LUIBase:New()
	setmetatable(o,HeroBreakUpUI)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function HeroBreakUpUI:RegistMsgs()
    self.msgIds = 
    {
        LUIRedDotEvent.UpdateRedDotState,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function HeroBreakUpUI:ProcessEvent(msg)
    if msg.msgId == LUIRedDotEvent.UpdateRedDotState then
        self:updateRedDot()
    end
end

function HeroBreakUpUI:Init()
    self:InitMembers()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end

    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegisterGuide()
end

function HeroBreakUpUI:InitMembers()
    self.m_pUILayer = cc.CSLoader:createNode("csd/shenjiangyangcheng/yingxiongtupoLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
    local panel = self.m_pUILayer:getChildByName("shenjiangInfoUI")
    local info = panel:getChildByName("Info")
    local jichu = info:getChildByName("jichu")
    local tupo = info:getChildByName("tupo")
    self._tupo = tupo
    -- panel:getChildByName("Show"):setVisible(false)
    -------------------------------------------------
    self.beakTips = jichu:getChildByName("Level_1")
    self.afterBeakTips = jichu:getChildByName("Level_2")
    local Btn_xiangxi = jichu:getChildByName("Btn_xiangxi")
    Btn_xiangxi:addClickEventListener(function ( sender )
        -- body
        Utils:InitUI("KaPaiPet.PetBreakAdditionUI", AppDef.UIType.PopWindow, self.petData)
    end)
    self.tianfuText = jichu:getChildByName("text_tianfu")
    self.levelCond = tupo:getChildByName("cailiao"):getChildByName("Value")
    self._defaltColor = self.levelCond:getTextColor()
    self.itemIcon = tupo:getChildByName("Item")
    self.breakBtn = tupo:getChildByName("btn_shengji")
    self.moneyCostText = tupo:getChildByName("xiaohao"):getChildByName("Num")
    self.itemCostText = tupo:getChildByName("Value")
    self.itemCostNameText = tupo:getChildByName("Name")
    self.petData = {}
    self.attrVal = {}
    self._manjiHideNodeArr = {}
    for i=1,4 do
        local str = "Attribute_"..i
        local attr = {}
        attr.attrName = jichu:getChildByName(str)
        attr.curValue = attr.attrName:getChildByName("Value_1")
        attr.afterValue = attr.attrName:getChildByName("Value_2")
        attr.addValue = attr.attrName:getChildByName("Value_3")
        table.insert(self._manjiHideNodeArr, attr.afterValue)
        table.insert(self._manjiHideNodeArr, attr.addValue)
        local Image = attr.attrName:getChildByName("Image")
        table.insert(self._manjiHideNodeArr, Image)

        table.insert(self.attrVal, attr)
    end

    local jiantou = jichu:getChildByName("jiantou")
    table.insert(self._manjiHideNodeArr, jiantou)
    ----------------------------------------------------------------------
    self._manji = info:getChildByName("manji")

end

function HeroBreakUpUI:AddTouchEvt()
    self.breakBtn:addClickEventListener(handler(self,HeroBreakUpUI.BreakUpBtnCallback))
    self:MarkIntaractCObj(self.breakBtn)
end

function HeroBreakUpUI:BreakUpBtnCallback(sender)
    if self.petData.level < self.breakdata.level then
        Utils:ShowScrollTips(string.format(GUITips.RSI_ZQX_TUPO_TIANFU2, self.breakdata.level))
    elseif LRoleDataMgr.Equip:CountItemNumById(self.itemCostType) < self.itemCostData then
        Utils:ShowScrollTips(string.format(GUITips.RSI_ZQX_TUPO_TIANFU3, Utils:getItemNameByID(self.itemCostType)))
    else
        LuaNetSendMsg:PetBreakUp(self.petData.id)
    end
end

function HeroBreakUpUI:getCurPetIsShowRed( ... )
    -- body
    if self.petData.breakLevel == nil then
        return false
    end

    local isCanLvUp = PetkaPaiManager:isPetCanBreakUp(self.petData)
    print("getCurPetIsShowRed ==>", isCanLvUp)
    return isCanLvUp
end

function HeroBreakUpUI:onExit()
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep,GuideDef.StepId.Guide_FuBen2_7)
    self.m_pUILayer = nil
    self.beakTips = nil
    self.afterBeakTips = nil
    self.petData = nil
    self.costList = nil
    self.tianfuText = nil
    self.levelCond = nil
    self.itemIcon = nil
    self.breakBtn = nil
    self.moneyCostText = nil
    self.breakdata = nil
    self.moneyCostData = nil
    self.attrVal = nil
    self.heroCfg = nil
    self.breakTeamAttrCfg = nil
    self.breakSkillCfg = nil
    self.itemCostType = nil
    self.itemCostNameText = nil
    self:Destory()
end

function HeroBreakUpUI:UpdateData( petData )

    self.petData = petData

    self:updateRedDot()

    self:InitBreakConfig()

    self.beakTips:setString(string.format(GUITips.RSI_YINGXIONG_TIPS2, self.petData.breakLevel))

    for i=1,4 do
        local attrType  = i
        self.attrVal[i].attrName:setString(AppDef.EAttrTypeName[i]..": ")
        local addValue = self.petData.baseData.growAttrs[i] * self.breakdata.attr
        self.attrVal[i].curValue:setString(tostring(self.petData.attrs[attrType]))
        self.attrVal[i].afterValue:setString(tostring(self.petData.attrs[attrType] + addValue))
        self.attrVal[i].addValue:setString(tostring(addValue))
    end
   
    self:AddTouchEvt()

    if self.petData.breakLevel >= AppDef.Pet_MaxBreakLv then
        --突破到满级
        self._tupo:setVisible(false)
        self._manji:setVisible(true)

        self:HideMaxBreakUI(false)
        self.afterBeakTips:setVisible(false)
        --若无显示，则没有配置
        -- self.afterBeakTips:setString(string.format(GUITips.RSI_YINGXIONG_TIPS2, self.petData.breakLevel))
        self.afterBeakTips:setVisible(false)
        self.tianfuText:setString(PetkaPaiManager:getBreakAttrStrByLv(self.petData, self.petData.breakLevel))
        
    else
        self._tupo:setVisible(true)
        self._manji:setVisible(false)

        self:HideMaxBreakUI(true)

        if self.petData.level < self.breakdata.level then
            self.levelCond:setTextColor(UICOLOR_RED)
        else
            self.levelCond:setTextColor(self._defaltColor)
        end
        self.levelCond:setString(tostring(self.breakdata.level))
        self.moneyCostText:setString(tostring(self.moneyCostData))
        self.moneyCostText:setTextColor(self._defaltColor)
        local myMoney = LRoleDataMgr.MyHeroInfo.DetailData:getMoney()
        if self.moneyCostData > myMoney then
            self.moneyCostText:setTextColor(UICOLOR_RED)
        else
            self.moneyCostText:setTextColor(self._defaltColor)
        end

        Utils:GetItemCellValue(self.itemIcon, 0, self.itemCostType,
                        true, false, 1, nil, true, false)

        local ownNum = LRoleDataMgr.Equip:CountItemNumById(self.itemCostType)
        local strCostData = string.format("%d/%d", ownNum, self.itemCostData)
        self.itemCostText:setString(strCostData)
        self.itemCostText:setTextColor(self._defaltColor)
        if ownNum < self.itemCostData then
            self.itemCostText:setTextColor(UICOLOR_RED)
        else
            self.itemCostText:setTextColor(self._defaltColor)
        end

        self.afterBeakTips:setVisible(true)
        self.itemCostNameText:setString(Utils:getItemNameByID(self.itemCostType))
        self.afterBeakTips:setString(string.format(GUITips.RSI_YINGXIONG_TIPS2, self.petData.breakLevel + 1))
        self.tianfuText:setString(PetkaPaiManager:getBreakAttrStrByLv(self.petData, self.petData.breakLevel + 1))
    end
    self:setBreakUpRedDot()
end

function HeroBreakUpUI:HideMaxBreakUI(isShow)
    -- body
    for i=1, #self._manjiHideNodeArr do
        self._manjiHideNodeArr[i]:setVisible(isShow)
    end
end

function HeroBreakUpUI:InitBreakConfig()
    -- body
    local breakLevel = self.petData.breakLevel + 1
    if self.petData.breakLevel >= AppDef.Pet_MaxBreakLv then
        breakLevel = AppDef.Pet_MaxBreakLv
    end

    self.breakdata = JsonConfig.m_petBreakCost.getDefByID(breakLevel)

    self.heroCfg = JsonConfig.m_heroCfg.getDefByID(self.petData.id)
    self.costList = {}

    local quelityCfg = JsonConfig.m_quality.getDefByID(self.heroCfg.quality)
    local quelityRate = 1
    if quelityCfg ~= nil then
        quelityRate = quelityCfg.break_ratio / 10000
    end

    for i=1, #self.breakdata.cost do
        local rewardData = self.breakdata.cost[i]
        local cost = {}
        cost.id = rewardData[1]
        cost.petID = rewardData[2]
        cost.num = rewardData[3]

        if cost.id == AppDef.EMoneyType.EMT_Gold then
            self.moneyCostData = cost.num * quelityRate
        else
            self.itemCostData = cost.num * quelityRate
            self.itemCostType = cost.id
        end
        table.insert(self.costList, cost)

    end
end

function HeroBreakUpUI:RegisterGuide()
    Utils:RegisterGuide(GuideDef.StepId.Guide_FuBen2_7, self.breakBtn, handler(self,HeroBreakUpUI.BreakUpBtnCallback), nil, true)
end

function HeroBreakUpUI:updateRedDot(data)
    -- body
    if data then
        if data.id == RedDotDef.ID.ShenJiang_BreakUp then
            self:setBreakUpRedDot()
        end
    else
        self:setBreakUpRedDot()
    end
end

function HeroBreakUpUI:setBreakUpRedDot( ... )
    -- body
    local isCanBreakUp = self:getCurPetIsShowRed()
    print("setBreakUpRedDot ==>", isCanBreakUp)
    Utils:SendMsg(LUIRedDotEvent.SetRedDotState, {id=RedDotDef.ID.ShenJiang_BreakUp, isShow=isCanBreakUp})
    self.breakBtn:getChildByName("Prompt"):setVisible(isCanBreakUp)
    
end

return HeroBreakUpUI