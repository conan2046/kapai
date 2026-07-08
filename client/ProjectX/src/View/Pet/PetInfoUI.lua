--[[
lua里面的游戏逻辑控制
神将-信息弹框
]]

local PetInfoUI = LUIBase:New()
PetInfoUI.__index = PetInfoUI
function PetInfoUI:New(userData)
    local o = LUIBase:New()
    setmetatable(o, PetInfoUI)
    o:Init(userData)
    return o
end


function PetInfoUI:Init(userData)
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
    self:setPetId(userData)
end

function PetInfoUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

function PetInfoUI:setPetId(userData)

 --  dump(userData, "PetInfoUIs ++++++++++++++++++++")
    local id = userData[1]
    
    local data = userData[2]
    -- print("宠物数据"..data)
    local star= userData[3]
    if id == nil then 
        return
    end
    self.m_pPetData = LDataConstMgr:GetPetData(id)
    if star~=nil then
    self.m_pPetData.initStar=star
    end
    if self.m_pPetData == nil then 
        return 
    end
    self.m_id = id
    if data ~= nil then
        self.m_pCPetData = data
    end
    self:ShowPetInfo()
end

function PetInfoUI:InitData()
    local panel = self.m_pUILayer:getChildByName("Panel")
    --模型
    local modelPanel = panel:getChildByName("Show")
    local powerPanel = modelPanel:getChildByName("bg_zhanli")
    powerPanel:setVisible(false)
    self.m_powerLabel = powerPanel:getChildByName("Value")
    self.m_qualityImage = modelPanel:getChildByName("bg_Quality"):getChildByName("Value")
    self.m_nameLabel = modelPanel:getChildByName("bg_Name"):getChildByName("Name")
    self.m_node = modelPanel:getChildByName("Image_1"):getChildByName("Node")
    self.m_pPetModelNode = ModelAniNode:create(AppDef.CEnum.ModelAniType.Monster, 0)
    self.m_node:addChild(self.m_pPetModelNode)
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
    self.m_starListView = self.m_basePanel:getChildByName("Stars")
    self.m_star = self.m_basePanel:getChildByName("Star")
    --类型
    self.m_petTypeImage = self.m_basePanel:getChildByName("Type"):getChildByName("Image")
    --物攻、法攻名称
    self.m_attackNameLabel = self.m_basePanel:getChildByName("Attribute_1")
    --等级
    self.m_levelLabel = self.m_basePanel:getChildByName("Level"):getChildByName("Value")
    self.m_baseAttrLabels = {}
    self.m_highAttrLabels = {}
    --基础属性值
    for i = 1,9 do
        self.m_baseAttrLabels[i] = self.m_basePanel:getChildByName("Attribute_"..i):getChildByName("Value")
    end
    --高级属性值
     for i = 1,16 do
        self.m_highAttrLabels[i] = self.m_highPanel:getChildByName("Attribute_"..i):getChildByName("Value")
    end

    local skillPanel = infoPanel:getChildByName("bg_Skill"):getChildByName("Item")
    self.m_skills ={}
    for i =1,4 do
        self.m_skills[i] = skillPanel:getChildByName("btn_skill_"..i)
        self.m_skills[i].userObject = i
    end
end

function PetInfoUI:InitEvt()
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

    local function ShowSkillTips(sender)
        local index = sender.userObject
        self:ShowSkillTips(index)
    end
    for i = 1,4 do
        self.m_skills[i]:addClickEventListener(ShowSkillTips)
		self:MarkIntaractCObj(self.m_skills[i])
    end

    local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Pet.PetInfoUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    LGameMsg.m_baseMsgWithOne:Change(LUISecondClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

     LGameMsg.m_baseMsgWithOne:Change(LUISecondClassBgEvent.SetTitle, GUITips.UI_Shenjiang_TabName1)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function PetInfoUI:ShowPetInfo()
    self:ShowQuality()
    --self:ShowPower()
    self:ShowName()
    self:ShowSkills()
    self:ShowAttrInfo()
    self:ShowModel()
end

--[[
显示品质评分
]]
function PetInfoUI:ShowQuality()
    AppDef:GetPetQualityScore(self.m_qualityImage, self.m_pPetData.quality)
end

--[[
显示战斗力
]]
function PetInfoUI:ShowPower()
    --self.m_powerLabel:setString(GUITips.Item_Power .. ":" .. self.m_pPetData.power)
end

--[[
显示名字
]]
function PetInfoUI:ShowName()
    self.m_nameLabel:setString(self.m_pPetData.name)
    local color = AppDef:GetPetQualityColor(self.m_pPetData.quality)
    self.m_nameLabel:setTextColor(color)
    self.m_nameLabel:enableShadow()
end

--[[
显示技能
]]
function PetInfoUI:ShowSkills()
    --四个固定的天赋技能
    for i = 1, 4 do
        local curSk = self.m_pPetData.skills[i]
        self:ShowBornSkill(self.m_skills[i], curSk)
    end
end

--[[
显示天赋技能
]]
function PetInfoUI:ShowBornSkill(skillItem, curSk)
    local flagImg = skillItem:getChildByName("Mark")
    flagImg:setVisible(true)

    local lockImg = skillItem:getChildByName("Lock")
    local maskImg = skillItem:getChildByName("Mask")
    local iconImg = skillItem:getChildByName("SkillImage")
    local lvLabel = skillItem:getChildByName("Level")
    local addImg = skillItem:getChildByName("Icon")
    lockImg:setVisible(false)
    addImg:setVisible(false)
    maskImg:setVisible(false)
    lvLabel:setVisible(false)
    
    iconImg:loadTexture(string.format("Skill/UI/skill_%d.png", curSk), ccui.TextureResType.localType)
    iconImg:setScale(0.88)
end

--[[
点击技能框
ind:点击的技能下表
]]
function PetInfoUI:ShowSkillTips(ind)
    local id = self.m_pPetData.skills[ind]
    if id == nil then return end
    local userdata = 
    {
        itemType = "CPetSkill",
        itemData = LSkillMgr:getSkillById(id),
        pos = ind,
        petQuality = self.m_pPetData.quality
    }
    LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowItemInfo, userdata)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

--[[
显示属性信息
]]
function PetInfoUI:ShowAttrInfo()
    --等级
    local level = 1
    if self.m_pCPetData ~= nil then
        level = self.m_pCPetData.level
    end
    self.m_levelLabel:setString(""..level)
    --星级
    local starLv = self.m_pPetData.initStar
    if self.m_pCPetData ~= nil then
        starLv = self.m_pCPetData.star
    end
    self.m_starListView:removeAllItems()
    for i = 1, starLv do
        local star = self.m_star:clone()
        self.m_starListView:pushBackCustomItem(star)
    end
    AppDef:ShowProAttrImg(self.m_petTypeImage, self.m_pPetData.petType)

    local attrs = Utils:deepCopy(self.m_pPetData.baseAttrs)
    if self.m_pCPetData ~= nil then
        attrs = Utils:deepCopy(self.m_pCPetData.attrs)
    else
        local attrTypes,attrValues = LDataConstMgr:GetPetAttr(self.m_pPetData.id, self.m_pPetData.initStar, 0, 1)
        for i=1,#attrTypes do
            if attrs[attrTypes[i]] == nil then
                attrs[attrTypes[i]] = 0
            end
            attrs[attrTypes[i]] = attrs[attrTypes[i]]+attrValues[i]
        end
    end
     
    local ind = 1
    --攻击
    if self.m_pPetData.attackType == AppDef.Pet.AttackType.Physical then
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

--显示模型
function PetInfoUI:ShowModel()
     if self.m_pPetData == nil then
        self.m_pPetModelNode:setVisible(false)
        return
    end
    self.m_pPetModelNode:setVisible(true)
    self.m_pPetModelNode:InitAni(AppDef.CEnum.ModelAniType.Monster, self.m_pPetData.pic)
    self.m_pPetModelNode:PlayStand(self.m_pPetData.defaultFace)
end

return PetInfoUI