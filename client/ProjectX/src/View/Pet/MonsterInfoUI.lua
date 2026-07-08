local MonsterInfoUI = LUIBase:New()
MonsterInfoUI.__index = MonsterInfoUI
function MonsterInfoUI:New(userData)
    local o = {}
    setmetatable(o, MonsterInfoUI)
    o:Init(userData)
    return o
end


function MonsterInfoUI:Init(userData)
    self.Script = "Pet.MonsterInfoUI"
    self.m_pUILayer = cc.CSLoader:createNode("csd/PetShowLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitData()
    self:InitEvt()
    self:setId(userData)
end

function MonsterInfoUI:onExit()
    self:Destory()
    self.Script = nil
    self.m_pUILayer = nil
    self.m_pMonsterData = nil
    self.m_pCMonsterData = nil
    self.m_level = nil
    self.m_powerLabel = nil
    self.m_qualityImage = nil
    self.m_nameLabel = nil
    self.m_node = nil
    self.m_pMonsterModelNode = nil
    self.m_basePanel = nil
    self.m_highPanel = nil
    self.m_baseBtn = nil
    self.m_highBtn = nil
    self.m_haseBtnLabel1 = nil
    self.m_haseBtnLabel2 = nil
    self.m_highBtnLabel1 = nil
    self.m_highBtnLabel2 = nil
    self.m_MonsterTypeImage = nil
    self.m_attackNameLabel = nil
    self.m_levelLabel = nil

    Utils:FreeTable(self.m_baseAttrLabels, self.m_highAttrLabels, self.m_skills)
    self.m_baseAttrLabels = nil
    self.m_highAttrLabels = nil
    self.m_skills = nil
end

function MonsterInfoUI:setId(userData)
    local id = userData.id
    local data = userData.data
    local level = userData.level
    if id == nil then 
        return
    end
    self.m_pMonsterData = LDataConstMgr:GetMonsterData(id)
    if self.m_pMonsterData == nil then 
        return 
    end
    if data ~= nil then
        self.m_pCMonsterData = data
    else
        self.m_level = level
    end
    self:ShowMonsterInfo()
end

function MonsterInfoUI:InitData()
    local panel = self.m_pUILayer:getChildByName("Panel")
    --模型
    local modelPanel = panel:getChildByName("Show")
    local powerPanel = modelPanel:getChildByName("bg_zhanli")
    powerPanel:setVisible(false)
    self.m_powerLabel = powerPanel:getChildByName("Value")
    self.m_qualityImage = modelPanel:getChildByName("bg_Quality"):getChildByName("Value")
    local pNameBg = modelPanel:getChildByName("bg_Name")
    pNameBg:setContentSize(cc.size(pNameBg:getContentSize().width, 230))
    pNameBg:setPositionY(modelPanel:getContentSize().height/2)
    self.m_nameLabel = pNameBg:getChildByName("Name")
    self.m_nameLabel:setTextAreaSize(cc.size(30, 180))
    self.m_nameLabel:setPositionY(pNameBg:getContentSize().height/2)
    self.m_nameLabel:enableShadow()

    self.m_node = modelPanel:getChildByName("Image_1"):getChildByName("Node")
    self.m_pMonsterModelNode = ModelAniNode:create(AppDef.CEnum.ModelAniType.Monster, 0)
    self.m_node:addChild(self.m_pMonsterModelNode)
    local pStarsList = modelPanel:getChildByName("StarsList")
    pStarsList:setVisible(false)
    --信息
    local infoPanel = panel:getChildByName("Info")
    local tabPanel = infoPanel:getChildByName("bg_Info")
    self.m_basePanel = tabPanel:getChildByName("jichu")
    self.m_highPanel = tabPanel:getChildByName("gaoji")
    self.m_highPanel:setVisible(false)
    self.m_baseBtn = infoPanel:getChildByName("CheckBox_jichu")
    self.m_highBtn = infoPanel:getChildByName("CheckBox_gaoji")
    self.m_haseBtnLabel1 = self.m_baseBtn:getChildByName("Text")
    self.m_haseBtnLabel2 = self.m_baseBtn:getChildByName("Text_choose")
    self.m_highBtnLabel1 = self.m_highBtn:getChildByName("Text")
    self.m_highBtnLabel2 = self.m_highBtn:getChildByName("Text_choose")
    --星级
    local pStarListText = self.m_basePanel:getChildByName("xingji")
    pStarListText:setVisible(false)
    local pStarListView = self.m_basePanel:getChildByName("Stars")
    pStarListView:setVisible(false)
    
    local offset = 33
    --类型
    local pMonsterType = self.m_basePanel:getChildByName("Type")
    pMonsterType:setPositionY(pMonsterType:getPositionY() + offset)
    self.m_MonsterTypeImage = pMonsterType:getChildByName("Image")
    
    --物攻、法攻名称
    self.m_attackNameLabel = self.m_basePanel:getChildByName("Attribute_1")
    
    --等级
    local pLevel = self.m_basePanel:getChildByName("Level")
    pLevel:setPositionY(pLevel:getPositionY() + offset)
    self.m_levelLabel = pLevel:getChildByName("Value")


    self.m_baseAttrLabels = {}
    self.m_highAttrLabels = {}
    --基础属性值
    for i = 1,9 do
        local pAttribute = self.m_basePanel:getChildByName("Attribute_"..i)
        pAttribute:setPositionY(pAttribute:getPositionY() + offset)
        self.m_baseAttrLabels[i] = pAttribute:getChildByName("Value")
    end
    --高级属性值
     for i = 1,16 do
        self.m_highAttrLabels[i] = self.m_highPanel:getChildByName("Attribute_"..i):getChildByName("Value")
    end

    local skillPanel = infoPanel:getChildByName("bg_Skill"):getChildByName("Item")
    self.m_skills = {}
    for i =1,4 do
        self.m_skills[i] = skillPanel:getChildByName("btn_skill_"..i)
        self.m_skills[i]:getChildByName("Level"):enableOutline(AppDef.UIColor.BLACK, 1)
        self.m_skills[i]:setTag(i)
    end
end

function MonsterInfoUI:InitEvt()
    local function baseShow(sender,evnetType)
        if evnetType == ccui.CheckBoxEventType.selected then
            self.m_basePanel:setVisible(true)
            self.m_highPanel:setVisible(false)
            self.m_baseBtn:setTouchEnabled(false)
            self.m_highBtn:setTouchEnabled(true)
            self.m_highBtn:setSelected(false)
            self.m_haseBtnLabel1:setVisible(true)
            self.m_haseBtnLabel2:setVisible(false)
            self.m_highBtnLabel1:setVisible(false)
            self.m_highBtnLabel2:setVisible(true)
        end
    end
    self.m_baseBtn:addEventListener(baseShow)
    self:MarkIntaractCObj(self.m_baseBtn)

    local function highShow(sender,evnetType)
        if evnetType == ccui.CheckBoxEventType.selected then
            self.m_basePanel:setVisible(false)
            self.m_highPanel:setVisible(true)
            self.m_highBtn:setTouchEnabled(false)
            self.m_baseBtn:setTouchEnabled(true)
            self.m_baseBtn:setSelected(false)
            self.m_haseBtnLabel1:setVisible(false)
            self.m_haseBtnLabel2:setVisible(true)
            self.m_highBtnLabel1:setVisible(true)
            self.m_highBtnLabel2:setVisible(false)
        end
    end
    self.m_highBtn:addEventListener(highShow)
    self:MarkIntaractCObj(self.m_highBtn)

    local function ShowSkillTips(sender)
        if sender ~= nil then
            self:ShowSkillTips(sender:getTag())
        end
    end
    for i = 1,4 do
        self.m_skills[i]:addClickEventListener(ShowSkillTips)
		self:MarkIntaractCObj(self.m_skills[i])
    end

    Utils:SendMsg(LUISecondClassBgEvent.SetCloseCallback, handler(self, MonsterInfoUI.RemoveUI))
    Utils:SendMsg(LUISecondClassBgEvent.SetTitle, GUITips.UI_Shenjiang_TabName1)
end

function MonsterInfoUI:ShowMonsterInfo()
    self:ShowQuality()
    self:ShowName()
    self:ShowSkills()
    self:ShowAttrInfo()
    self:ShowModel()
end

function MonsterInfoUI:ShowQuality()
    AppDef:GetPetQualityScore(self.m_qualityImage, self.m_pMonsterData.quality)
end

function MonsterInfoUI:ShowName()
    self.m_nameLabel:setString(self.m_pMonsterData.name)
    local color = AppDef:GetPetQualityColor(self.m_pMonsterData.quality)
    self.m_nameLabel:setTextColor(color)
end

function MonsterInfoUI:ShowSkills()
    for i=1,#self.m_skills do
        local curSk = self.m_pMonsterData.skills[i]
        self:ShowBornSkill(self.m_skills[i], curSk)
    end
end

function MonsterInfoUI:ShowBornSkill(skillItem, skConfig)
    if skillItem == nil then
        return
    end
    if skConfig == nil or #skConfig < 2 then
        skillItem:setVisible(false)
        return
    end
    skillItem:setVisible(true)

    local curSk = skConfig[1]
    local skLevel = skConfig[2]

    local flagImg = skillItem:getChildByName("Mark")
    flagImg:setVisible(true)

    local lockImg = skillItem:getChildByName("Lock")
    lockImg:setVisible(false)

    local maskImg = skillItem:getChildByName("Mask")
    maskImg:setVisible(false)

    local addImg = skillItem:getChildByName("Icon")
    addImg:setVisible(false)

    local lvLabel = skillItem:getChildByName("Level")
    lvLabel:setVisible(true)
    lvLabel:setString(skLevel)
    
    local iconImg = skillItem:getChildByName("SkillImage")
    iconImg:loadTexture(string.format("Skill/UI/skill_%d.png", curSk), UI_TEX_TYPE_LOCAL)
    iconImg:setScale(0.88)
end

function MonsterInfoUI:ShowSkillTips(ind)
    local cfg = self.m_pMonsterData.skills[ind]
    if cfg == nil then
        return
    end
    local id = cfg[1]
    local level = cfg[2]
    local userdata =
    {
        itemType = "CPetSkill",
        itemData = LSkillMgr:getSkillById(id),
        pos = ind,
        petQuality = self.m_pMonsterData.quality,
        skLevel = level,
    }
    Utils:SendMsg(LUILogicEvent.ShowItemInfo, userdata)
end

function MonsterInfoUI:ShowAttrInfo()
    --等级
    local level = self.m_level or 0
    if self.m_pCMonsterData ~= nil then
        level = self.m_pCMonsterData.level
    end
    self.m_levelLabel:setString(""..level)
    AppDef:ShowProAttrImg(self.m_MonsterTypeImage, self.m_pMonsterData.type)

    local attrs = self.m_pMonsterData.baseAttrs
    if self.m_pCMonsterData ~= nil then
        attrs = self.m_pCMonsterData.attrs
    end
    
    local ind = 1
    --攻击
    if self.m_pMonsterData.attackType == AppDef.Pet.AttackType.Physical then
        --物攻宠物
        self.m_attackNameLabel:setString(" "..GUITips.Item_Info_Attr178 .. "：")

    else
        --法攻宠物
        self.m_attackNameLabel:setString(" "..GUITips.Item_Info_Attr179 .. "：")
    end
    local ind = 1
    self.m_baseAttrLabels[ind]:setString(" "..attrs[AppDef.EAttrType.EAT_ATTACK])

    --气血
    ind = ind + 1
    self.m_baseAttrLabels[ind]:setString(attrs[AppDef.EAttrType.EAT_HP])
    --物防
    ind = ind + 1
    self.m_baseAttrLabels[ind]:setString(attrs[AppDef.EAttrType.EAT_DEFENSE])
    --法防
    ind = ind + 1
    self.m_baseAttrLabels[ind]:setString(attrs[AppDef.EAttrType.EAT_MAGICD_EFENSE])
    --命中
    ind = ind + 1
    self.m_baseAttrLabels[ind]:setString(attrs[AppDef.EAttrType.EAT_HIT])
    --闪避
    ind = ind + 1
    self.m_baseAttrLabels[ind]:setString(attrs[AppDef.EAttrType.EAT_DODGE])
    --暴击
    ind = ind + 1
    self.m_baseAttrLabels[ind]:setString(attrs[AppDef.EAttrType.EAT_CRIT])
    --抗暴
    ind = ind + 1
    self.m_baseAttrLabels[ind]:setString(attrs[AppDef.EAttrType.EAT_RESISIT_CRIT])
    --速度
    ind = ind + 1
    self.m_baseAttrLabels[ind]:setString(attrs[AppDef.EAttrType.EAT_SPEED])

    --增伤率
    ind = 1
    self.m_highAttrLabels[ind]:setString(attrs[AppDef.EAttrType.EAT_DAMAGE_RATE].."%")
    --物免率
    ind = ind + 1
    self.m_highAttrLabels[ind]:setString(attrs[AppDef.EAttrType.EAT_WM_RATE].."%")
    --法免率
    ind = ind + 1
    self.m_highAttrLabels[ind]:setString(attrs[AppDef.EAttrType.EAT_FM_RATE].."%")
    --暴击伤害
    ind = ind + 1
    self.m_highAttrLabels[ind]:setString(attrs[AppDef.EAttrType.EAT_CRIT_DAMAGE].."%")
    --反击率
    ind = ind + 1
    self.m_highAttrLabels[ind]:setString(attrs[AppDef.EAttrType.EAT_COUNTER_RATE].."%")
    --抗反率
    ind = ind + 1
    self.m_highAttrLabels[ind]:setString(attrs[AppDef.EAttrType.EAT_RCOUNTER_RATE].."%")
    --反击伤害
    ind = ind +1
    self.m_highAttrLabels[ind]:setString(attrs[AppDef.EAttrType.EAT_COUNTER_DAMAGE].."%")
    --连击率
    ind = ind + 1
    self.m_highAttrLabels[ind]:setString(attrs[AppDef.EAttrType.EAT_DOUBLE_RATE].."%")
    --抗连率
    ind = ind + 1
    self.m_highAttrLabels[ind]:setString(attrs[AppDef.EAttrType.EAT_RDOUBLE_RATE].."%")
    --连击伤害
    ind = ind + 1
    self.m_highAttrLabels[ind]:setString(attrs[AppDef.EAttrType.EAT_DOUBLE_DAMAGE].."%")
    --反震率
    ind = ind + 1
    self.m_highAttrLabels[ind]:setString(attrs[AppDef.EAttrType.EAT_SHOCK_RATE].."%")
    --抗震率
    ind = ind + 1
    self.m_highAttrLabels[ind]:setString(attrs[AppDef.EAttrType.EAT_RSHOCK_RATE].."%")
    --反震伤害
    ind = ind + 1
    self.m_highAttrLabels[ind]:setString(attrs[AppDef.EAttrType.EAT_SHOCK_DAMAGE].."%")
    --负面强化
    ind = ind +1
    self.m_highAttrLabels[ind]:setString(attrs[AppDef.EAttrType.EAT_FUMIANQIANGHUA].."%")
    --负面抵抗
    ind = ind + 1
    self.m_highAttrLabels[ind]:setString(attrs[AppDef.EAttrType.EAT_FUMIANDIKANG].."%")
end

function MonsterInfoUI:ShowModel()
     if self.m_pMonsterData == nil then
        self.m_pMonsterModelNode:setVisible(false)
        return
    end
    self.m_pMonsterModelNode:setVisible(true)
    self.m_pMonsterModelNode:InitAni(AppDef.CEnum.ModelAniType.Monster, self.m_pMonsterData.pic)
    self.m_pMonsterModelNode:PlayStand(0)
end

return MonsterInfoUI