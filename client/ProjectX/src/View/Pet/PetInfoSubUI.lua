--[[
lua里面的游戏逻辑控制
]]

local PetInfoSubUI = LUIBase:New()
PetInfoSubUI.__index = PetInfoSubUI

function PetInfoSubUI:New(petData)
	local o = LUIBase:New()
	setmetatable(o,PetInfoSubUI)	
    o:Init(petData)
	return o
end


function PetInfoSubUI:Init(petData)
    self:RegistMsgs()
    self:InitMemberVariable(petData)
    self:InitViewSize()
    self:InitUICtr()
    self:InitEvt()
    self.m_pBaseInfoBtn:setSelected(true)
    self.m_pExterInfoBtn:setSelected(true)
    
    self:SetCurAttrTab(1)
    self:ShowPetInfo()

    self:ShowUpLvMat()

    self:CheckTujianRedPoint()
end

function PetInfoSubUI:RegistMsgs()
    self.msgIds = 
    {
        LUIPetEvent.SelectedPet,
        LUIPetEvent.PetDataChanged,
        LUIPetEvent.ChangePetName,
        LUIBagEvent.BagDataChanged,
        LUIPetEvent.ChangePetFollow,
        LUIPetEvent.ChangePetStar,
        LUIPetEvent.ChangePetSkill,
        LUIPetEvent.ComposionPet,
        LUIPetEvent.ResolveSucess,
        LUIPetEvent.PetExpRedDot,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function PetInfoSubUI:ProcessEvent(msg)
    if msg.msgId == LUIPetEvent.SelectedPet then
        self:SetPetData(msg.value)
    elseif msg.msgId == LUIPetEvent.PetDataChanged then
        self:CheckPetDataChanged(msg.value)
    elseif msg.msgId == LUIBagEvent.BagDataChanged then
        self:BagItemChanged()
    elseif msg.msgId == LUIPetEvent.ChangePetName then
        self:CheckPetNameChanged(msg.value)
    elseif msg.msgId == LUIPetEvent.ChangePetFollow then
        self:CheckPetFollow()
    elseif msg.msgId == LUIPetEvent.ChangePetStar then
        self:UpdateSkills()
    elseif msg.msgId == LUIPetEvent.ChangePetSkill then
        self:UpdateSkills()
    elseif msg.msgId == LUIPetEvent.ComposionPet or  msg.msgId == LUIPetEvent.ResolveSucess then
        self:CheckTujianRedPoint()
    elseif msg.msgId == LUIPetEvent.PetExpRedDot then
        self:ShowMatRedDot()
    end
end

function PetInfoSubUI:CheckPetFollow()
    self:ShowPetFollowState()
end

function PetInfoSubUI:CheckPetNameChanged(pid)
    if self.m_pPetData.id ~= pid then
        return
    end
    self:ShowName()
end

function PetInfoSubUI:BagItemChanged()
    self:UpdateUpLvMat()
end

function PetInfoSubUI:CheckPetDataChanged(pid)
    --print("CheckPetDataChanged",pid)
    if self.m_pPetData == nil then
        return
    end
    if self.m_pPetData.id ~= pid then
        --不是同一个宠物
        return
    end
    self:ShowLv()
    self:ShowExp()
    self:ShowQuality()
    self:ShowAttrInfo()
    self:ShowPower()
end

--[[
更新升级材料显示
]]
function PetInfoSubUI:UpdateUpLvMat()
    for i = 1, AppDef.Pet.MaxUpgradeItems do
        local itemNum = LRoleDataMgr.Equip:CountItemNumById(AppDef.Pet.UpgradsMats[i])
        if itemNum <= 0 then
            self.m_pMatMaskImgs[i]:setVisible(true)
            self.m_pMatNumLabels[i]:setString("0")
            self.m_pMatNumLabels[i]:setTextColor(AppDef.UIColor.RED)
            --self.m_pAddMatImgs[i]:setVisible(true)
        else
            self.m_pMatMaskImgs[i]:setVisible(false)
            --self.m_pAddMatImgs[i]:setVisible(false)
            self.m_pMatNumLabels[i]:setString(itemNum)
            self.m_pMatNumLabels[i]:setTextColor(AppDef.UIColor.GREEN)
            
        end
        local citem = LDataConstMgr:getCItemByID(AppDef.Pet.UpgradsMats[i])
        self.m_pAddExpLabels[i]:setString(GUITips.RSI_FACTION_MSG32 .. "+" .. citem.additionalValue)
    end
end

--[[
显示升级材料
]]
function PetInfoSubUI:ShowUpLvMat()
    
    for i = 1, AppDef.Pet.MaxUpgradeItems do
        local itemNum = LRoleDataMgr.Equip:CountItemNumById(AppDef.Pet.UpgradsMats[i])
        if itemNum <= 0 then
            self.m_pMatMaskImgs[i]:setVisible(true)
            self.m_pMatNumLabels[i]:setString("0")
            self.m_pMatNumLabels[i]:setTextColor(AppDef.UIColor.RED)
        else
            self.m_pMatMaskImgs[i]:setVisible(false)
            self.m_pMatNumLabels[i]:setString(itemNum)
            self.m_pMatNumLabels[i]:setTextColor(AppDef.UIColor.GREEN)
            
        end
        local citem = LDataConstMgr:getCItemByID(AppDef.Pet.UpgradsMats[i])
        self.m_pAddExpLabels[i]:setString(GUITips.RSI_FACTION_MSG32 .. "+" .. citem.additionalValue)
        Utils:GetItemCellValue(self.m_pMatIcons[i], 0, AppDef.Pet.UpgradsMats[i], false, false, 0)
    end
end

function PetInfoSubUI:SetPetData(petData)
    self.m_pPetData = petData  
    self:ShowPetInfo()
end

function PetInfoSubUI:ShowPetInfo()
    if self.m_pPetData == nil then
        return
    end
    self:UnLoadAllSkillIcon()
    self:ShowPetModel()
    self:ShowPower()
    self:ShowName()
    self:ShowPetFollowState()
    self:ShowLv()
    self:ShowExp()
    self:ShowQuality()
    self:ShowAttrInfo()
    self:ShowSkills()
    self:ShowMatRedDot()
    
end
--显示宠物经验丹小红点
function PetInfoSubUI:ShowMatRedDot() 
   if self.m_pPetData.level<LRoleDataMgr.MyHeroInfo.level and self.m_pPetData.fightPos ~= nil and self.m_pPetData.fightPos>0  then
        for i = 1, AppDef.Pet.MaxUpgradeItems do
           local itemNum = LRoleDataMgr.Equip:CountItemNumById(AppDef.Pet.UpgradsMats[i])

            if itemNum>0 then
                 self.m_pMatRedDot[i]:setVisible(true)
            else
                 self.m_pMatRedDot[i]:setVisible(false)
            end        
        end
   else
     for i = 1, AppDef.Pet.MaxUpgradeItems do
        self.m_pMatRedDot[i]:setVisible(false)
     end
   end

end

function PetInfoSubUI:UpdateSkills()
    self:UnLoadAllSkillIcon()
    self:ShowSkills()
end

--[[
显示天赋技能
]]
function PetInfoSubUI:ShowBornSkill(skillItem, curSk)
    local flagImg = skillItem:getChildByName("Mark")
    flagImg:setVisible(true)

    local lockImg = skillItem:getChildByName("Lock")
    local maskImg = skillItem:getChildByName("Mask")
    local iconImg = skillItem:getChildByName("SkillImage")
    local lvLabel = skillItem:getChildByName("Level")
    local addImg = skillItem:getChildByName("Icon")
    addImg:setVisible(false)
    if curSk.skDetail == nil then
        --未开启，未知技能
        lockImg:setVisible(true)
        maskImg:setVisible(false)
        lvLabel:setVisible(false)
        iconImg:setVisible(false)
    else
        if curSk.level == 0 then
            --未开启，等级0
            lockImg:setVisible(true)
            maskImg:setVisible(true)
            lvLabel:setVisible(false)
        else
            lockImg:setVisible(false)
            maskImg:setVisible(false)
            lvLabel:setVisible(true)
            lvLabel:setString(curSk.level)
        end
        local resFile = string.format("Skill/UI/skill_%d.png", curSk.skDetail.id)
        -- iconImg:loadTexture(resFile, ccui.TextureResType.localType)
        -- iconImg:setScale(0.88)
        self:ShowSkillIcon(iconImg, resFile)
    end
end

function PetInfoSubUI:UnLoadAllSkillIcon()
    if self.m_resArr == nil then
        return
    end
    for i = 1, #self.m_resArr do
        LGameMsg.m_resMsg:Change(LResEvent.UnLoadImgSync, self.m_resArr[i])
        self:SendMsg(LGameMsg.m_resMsg)
    end
    self.m_resArr = nil
end

function PetInfoSubUI:ShowSkillIcon(iconImg, resFile)
    local exit = false
    self.m_resArr = self.m_resArr or {}
    for i = 1, #self.m_resArr do
        if self.m_resArr[i] == iconImg then
            exit = true
            break
        end
    end
    if not exit then
        table.insert(self.m_resArr, resFile)
    end

    local  function LoadResCallback(tex)
        iconImg:setVisible(true)
        iconImg:loadTexture(resFile, ccui.TextureResType.localType)
        iconImg:setScale(0.88)
    end
    iconImg:setVisible(false)
    Utils:AsyncLoadImg(iconImg,resFile,LoadResCallback)
end

--[[
显示天书技能
]]
function PetInfoSubUI:ShowLearnSkill(skillItem, skill_id)
	local curSk = self.m_pPetData.skills[skill_id]
    local flagImg = skillItem:getChildByName("Mark")
    flagImg:setVisible(false)
    local lockImg = skillItem:getChildByName("Lock")
    local maskImg = skillItem:getChildByName("Mask")
    local iconImg = skillItem:getChildByName("SkillImage")
    local lvLabel = skillItem:getChildByName("Level")
    local addImg = skillItem:getChildByName("Icon")

    if curSk.skDetail == nil then
        --未开启，未知技能
        lockImg:setVisible(true)
		if self.m_pPetData.star >= AppDef.Pet.LearnOpenStar[skill_id - AppDef.Pet.MaxBornSkillNum] then
			lockImg:setVisible(false)
		end
        maskImg:setVisible(false)
        lvLabel:setVisible(false)
        iconImg:setVisible(false)
        addImg:setVisible(false)
    else
        if curSk.level == 0 then
            --未开启，等级0
            lockImg:setVisible(true)
            maskImg:setVisible(true)
            lvLabel:setVisible(false)
            iconImg:setVisible(false)
            addImg:setVisible(true)
        else
            lockImg:setVisible(false)
            maskImg:setVisible(false)
            addImg:setVisible(false)
            lvLabel:setVisible(true)
            lvLabel:setString(curSk.level)
            iconImg:setVisible(true)

            local resFile = string.format("Skill/UI/skill_%d.png", curSk.skDetail.id)
            self:ShowSkillIcon(iconImg, resFile)
            -- iconImg:loadTexture(string.format("Skill/UI/skill_%d.png", curSk.skDetail.id), ccui.TextureResType.localType)
            -- iconImg:setScale(0.88)
        end
    end
end

--[[
点击技能框
ind:点击的技能下表
]]
function PetInfoSubUI:ShowClickSkillTips(ind)
    local clickSk = self.m_pPetData.skills[ind]
    if ind <= AppDef.Pet.MaxBornSkillNum then--天赋技能
        if clickSk.skDetail == nil then
            return
        end
        local userdata = 
        {
            itemType = "PetSkill",
            itemData = clickSk,
            pos = ind,
            petQuality = self.m_pPetData.baseData.quality
        }
        LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowItemInfo, userdata)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    else
        if clickSk.skDetail == nil then
            return
        end
        local userdata = 
        {
            itemType = "PetSkill",
            itemData = clickSk,
            pos = ind,
            petQuality = self.m_pPetData.baseData.quality
        }
        LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowItemInfo, userdata)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end
end

function PetInfoSubUI:SkillClicked(sender)
    local ind = sender:getTag()
    self:ShowClickSkillTips(ind)
end

--[[
显示技能
]]
function PetInfoSubUI:ShowSkills()
    self.m_pSkillListView:removeAllItems()
    --前四个固定是天赋技能
    local skPanel = self.m_pSkillCell:clone()
    self.m_pSkillListView:pushBackCustomItem(skPanel)
    for j = 1, 4 do
        local curSk = self.m_pPetData.skills[j]
        local skillItem = skPanel:getChildByName("btn_skill_" .. j)
        skillItem:setTag(j)
        skillItem:addClickEventListener(handler(self, PetInfoSubUI.SkillClicked))
        self:MarkIntaractCObj(skillItem)
        self:ShowBornSkill(skillItem, curSk)
    end

    --天书技能
    for i = 5, AppDef.Pet.MaxSkillNum, 4 do
        local skPanel = self.m_pSkillCell:clone()
        self.m_pSkillListView:pushBackCustomItem(skPanel)
        for j = 0, 3 do
            local skillItem = skPanel:getChildByName("btn_skill_" .. (j+1))
            skillItem:setTag(i + j)
            skillItem:addClickEventListener(handler(self, PetInfoSubUI.SkillClicked))
            self:MarkIntaractCObj(skillItem)
            self:ShowLearnSkill(skillItem, i + j)
        end
    end
end

--[[
显示属性信息
]]
function PetInfoSubUI:ShowAttrInfo()
    --星级
    self.m_pStarListView:removeAllItems()
    for i = 1, self.m_pPetData.star do
        local star = self.m_pStarCell:clone()
        self.m_pStarListView:pushBackCustomItem(star)
    end
    AppDef:ShowProAttrImg(self.m_pProImg, self.m_pPetData.baseData.petType)
    --AppDef:ShowProAttrText(self.m_pProLabel, self.m_pPetData.baseData.petType)

    local ind = 1
    --攻击
    if self.m_pPetData.baseData.attackType == AppDef.Pet.AttackType.Physical then
        --物攻宠物
        self.m_pBaseAttrLabels[ind]:setString(GUITips.Item_Info_Attr178 .. "：")

    else
        --法攻宠物
        self.m_pBaseAttrLabels[ind]:setString(GUITips.Item_Info_Attr179 .. "：")
    end
    ind = ind + 1
    self.m_pBaseAttrLabels[ind]:setString(self.m_pPetData.attrs[AppDef.EAttrType.EAT_ATTACK])

    --气血
    ind = ind + 2
    self.m_pBaseAttrLabels[ind]:setString(self.m_pPetData.attrs[AppDef.EAttrType.EAT_HP])
    --物防
    ind = ind + 2
    self.m_pBaseAttrLabels[ind]:setString(self.m_pPetData.attrs[AppDef.EAttrType.EAT_DEFENSE])
    --法防
    ind = ind + 2
    self.m_pBaseAttrLabels[ind]:setString(self.m_pPetData.attrs[AppDef.EAttrType.EAT_MAGICD_EFENSE])
    --命中
    ind = ind + 2
    self.m_pBaseAttrLabels[ind]:setString(self.m_pPetData.attrs[AppDef.EAttrType.EAT_HIT])
    --闪避
    ind = ind + 2
    self.m_pBaseAttrLabels[ind]:setString(self.m_pPetData.attrs[AppDef.EAttrType.EAT_DODGE])
    --暴击
    ind = ind + 2
    self.m_pBaseAttrLabels[ind]:setString(self.m_pPetData.attrs[AppDef.EAttrType.EAT_CRIT])
    --抗暴
    ind = ind + 2
    self.m_pBaseAttrLabels[ind]:setString(self.m_pPetData.attrs[AppDef.EAttrType.EAT_RESISIT_CRIT])
    --速度
    ind = ind + 2
    self.m_pBaseAttrLabels[ind]:setString(self.m_pPetData.attrs[AppDef.EAttrType.EAT_SPEED])

    --增伤率
    ind = 2
    self.m_pSeniorAttrLabels[ind]:setString("" .. self.m_pPetData.attrs[AppDef.EAttrType.EAT_DAMAGE_RATE] .. "%")
    --物免率
    ind = ind + 2
    self.m_pSeniorAttrLabels[ind]:setString("" .. self.m_pPetData.attrs[AppDef.EAttrType.EAT_WM_RATE] .. "%")
    --法免率
    ind = ind + 2
    self.m_pSeniorAttrLabels[ind]:setString("" .. self.m_pPetData.attrs[AppDef.EAttrType.EAT_FM_RATE] .. "%")
    --暴击伤害
    ind = ind + 2
    self.m_pSeniorAttrLabels[ind]:setString("" .. self.m_pPetData.attrs[AppDef.EAttrType.EAT_CRIT_DAMAGE] .. "%")
    --反击率
    ind = ind + 2
    self.m_pSeniorAttrLabels[ind]:setString("" .. self.m_pPetData.attrs[AppDef.EAttrType.EAT_COUNTER_RATE] .. "%")
    --抗反率
    ind = ind + 2
    self.m_pSeniorAttrLabels[ind]:setString("" .. self.m_pPetData.attrs[AppDef.EAttrType.EAT_RCOUNTER_RATE] .. "%")
    --反击伤害
    ind = ind + 2
    self.m_pSeniorAttrLabels[ind]:setString("" .. self.m_pPetData.attrs[AppDef.EAttrType.EAT_COUNTER_DAMAGE] .. "%")
    --连击率
    ind = ind + 2
    self.m_pSeniorAttrLabels[ind]:setString("" .. self.m_pPetData.attrs[AppDef.EAttrType.EAT_DOUBLE_RATE] .. "%")
    --抗连率
    ind = ind + 2
    self.m_pSeniorAttrLabels[ind]:setString("" .. self.m_pPetData.attrs[AppDef.EAttrType.EAT_RDOUBLE_RATE] .. "%")
    --连击伤害
    ind = ind + 2
    self.m_pSeniorAttrLabels[ind]:setString("" .. self.m_pPetData.attrs[AppDef.EAttrType.EAT_DOUBLE_DAMAGE] .. "%")
    --反震率
    ind = ind + 2
    self.m_pSeniorAttrLabels[ind]:setString("" .. self.m_pPetData.attrs[AppDef.EAttrType.EAT_SHOCK_RATE] .. "%")
    --抗震率
    ind = ind + 2
    self.m_pSeniorAttrLabels[ind]:setString("" .. self.m_pPetData.attrs[AppDef.EAttrType.EAT_RSHOCK_RATE] .. "%")
    --反震伤害
    ind = ind + 2
    self.m_pSeniorAttrLabels[ind]:setString("" .. self.m_pPetData.attrs[AppDef.EAttrType.EAT_SHOCK_DAMAGE] .. "%")
    --负面强化
    ind = ind + 2
    self.m_pSeniorAttrLabels[ind]:setString("" .. self.m_pPetData.attrs[AppDef.EAttrType.EAT_FUMIANQIANGHUA] .. "%")
    --负面抵抗
    ind = ind + 2
    self.m_pSeniorAttrLabels[ind]:setString("" .. self.m_pPetData.attrs[AppDef.EAttrType.EAT_FUMIANDIKANG] .. "%")
end

--[[
显示品质评分
]]
function PetInfoSubUI:ShowQuality()

    AppDef:GetPetQualityScore(self.m_pQualityImg, self.m_pPetData.baseData.quality)
end

--[[
显示战斗力
]]
function PetInfoSubUI:ShowPower()
    self.m_pPowerLabel:setString(Utils:getPowerStr(self.m_pPetData.zhandouli))
end

--[[
显示名字
]]
function PetInfoSubUI:ShowName()
    self.m_pNameLabel:setString(self.m_pPetData.name)
    local color = AppDef:GetPetQualityColor(self.m_pPetData.baseData.quality)
    self.m_pNameLabel:setTextColor(color)
end

--[[
显示等级
]]
function PetInfoSubUI:ShowLv()
    self.m_pLvLabel:setString("Lv." .. self.m_pPetData.level)
    self.m_pLvInAttrLabel:setString(self.m_pPetData.level)
end

--[[
显示经验条
]]
function PetInfoSubUI:ShowExp()
    self.m_pExpLabel:setString(self.m_pPetData.exp .. "/" .. self.m_pPetData.expMax)
    local expRate = self.m_pPetData.exp * 100 / self.m_pPetData.expMax
    -- if expRate < 0 or expRate > 1 then
    --     expRate = 0
    -- end
    
    self.m_pExpBar:setPercent(expRate)
end

--[[
显示宠物模型
]]
function PetInfoSubUI:ShowPetModel()
    if self.m_pPetData == nil then
        self.m_pPetModelNode:setVisible(false)
        return
    end
    self.m_pPetModelNode:setVisible(true)
    self.m_pPetModelNode:InitAni(AppDef.CEnum.ModelAniType.Monster, self.m_pPetData.baseData.pic)
    self.m_pPetModelNode:PlayStand(self.m_pPetData.baseData.defaultFace)
end

function PetInfoSubUI:InitViewSize()
    self:CreateUINode("csd/shenjiangInfoLayer.csb")
end

function PetInfoSubUI:onExit()
    --节点放在主节点上删除
    --self.m_pUILayer = nil
    self:Destory()

    self:UnLoadAllSkillIcon()
    --self.m_pUILayer = nil
    self.m_imageSelect = nil
    self.m_pResolveBtn = nil
    self.m_pArchiveBtn = nil
    self.m_pArchiveBtnRedPImg = nil
    self.m_pPetData = nil--当前选中的宠物数据
    self.m_pPetNode = nil--宠物显示节点
    self.m_pPetModelNode = nil--宠物动画节点
    self.m_pNameLabel = nil--宠物名字
    self.m_pQualityImg = nil--品质ImageView
    self.m_pPowerLabel = nil--战斗力Label
    self.m_pLvLabel = nil--等级Label
    self.m_pMatRedDot=nil--经验丹小红点
    self.m_pLvInAttrLabel = nil--属性界面的等级Label
    self.m_pExpLabel = nil--经验Label
    self.m_pExpBar = nil--经验条
    self.m_pBaseInfoBtn = nil--基础信息按钮
    self.m_pExterInfoBtn = nil--高级信息按钮
    self.m_pStarListView = nil--星级ListView
    self.m_pStarCell = nil--星星复用子元素
    --self.m_pProLabel = nil--职业属性
    self.m_pProImg = nil--职业图片
    self.m_pAttrTypeLabel = nil--宠物类型
    self.m_pAttrTypeImg = nil--宠物类型图片
    self.m_pBaseAttrLabels = nil---基数属性集合
    self.m_pSeniorAttrLabels = nil---高级属性集合
    self.m_pMatBtns = nil---升级材料按钮
    self.m_pMatIcons = nil---材料icon
    self.m_pMatMaskImgs = nil---材料蒙版遮罩
    self.m_pAddMatImgs = nil---添加材料图片
    self.m_pMatNumLabels = nil---升级材料个数文本
    self.m_pAddExpLabels = nil---升级属性加成文本
   
    self.m_pCurMatBtnTouched = nil--当前材料按钮触摸的下标
    self.m_bIsAutoUpgrade = nil---是否自动使用材料升级
    self.m_strUpgradeTips = nil--升级提示
    self.m_upgradeUseItemNum = nil--总共使用的多少道具
	self.m_upgradeBeforeUseItemNum = nil--每次使用之前记录当前的初始数量
    self.m_pBaseAttrPanel = nil--基础属性面板
    self.m_pExterAttrPanel = nil--高级属性面板

    self.m_pSkillListView = nil--技能列表
    self.m_pSkillCell = nil--技能子控件

    self.m_pFollowBtn = nil--跟随按钮
    self.m_pChangeNameBtn = nil--改名按钮
    self.m_pChangeNamePanel = nil--改名层

    self.m_curAttrInd = nil--当前显示属性的下表
    
end

--[[
初始化成员变量
]]
function PetInfoSubUI:InitMemberVariable(petData)
    self.m_pPetData = petData--当前选中的宠物数据
    self.m_pPetNode = nil--宠物显示节点
    self.m_pPetModelNode = nil--宠物动画节点
    self.m_pNameLabel = nil--宠物名字
    self.m_pQualityImg = nil--品质ImageView
    self.m_pPowerLabel = nil--战斗力Label
    self.m_pLvLabel = nil--等级Label

    self.m_pLvInAttrLabel = nil--属性界面的等级Label
    self.m_pExpLabel = nil--经验Label
    self.m_pExpBar = nil--经验条
    self.m_pBaseInfoBtn = nil--基础信息按钮
    self.m_pExterInfoBtn = nil--高级信息按钮
    self.m_pStarListView = nil--星级ListView
    self.m_pStarCell = nil--星星复用子元素
    --self.m_pProLabel = nil--职业属性
    self.m_pProImg = nil--职业图片
    self.m_pAttrTypeLabel = nil--宠物类型
    self.m_pAttrTypeImg = nil--宠物类型图片
    self.m_pBaseAttrLabels = {}--基数属性集合
    self.m_pSeniorAttrLabels = {}--高级属性集合
    self.m_pMatRedDot={}--经验丹小红点
    self.m_pMatBtns = {}--升级材料按钮
    self.m_pMatIcons = {}--材料icon
    self.m_pMatMaskImgs = {}--材料蒙版遮罩
    self.m_pAddMatImgs = {}--添加材料图片
    self.m_pMatNumLabels = {}--升级材料个数文本
    self.m_pAddExpLabels = {}--升级属性加成文本

    self.m_pCurMatBtnTouched = 0--当前材料按钮触摸的下标
    self.m_bIsAutoUpgrade = false--是否自动使用材料升级
    self.m_strUpgradeTips = nil--升级提示
    self.m_upgradeUseItemNum = 0--总共使用的多少道具
	self.m_upgradeBeforeUseItemNum = 0--使用之前记录道具的初始数量
    self.m_pBaseAttrPanel = nil--基础属性面板
    self.m_pExterAttrPanel = nil--高级属性面板

    self.m_pSkillListView = nil--技能列表
    self.m_pSkillCell = nil--技能子控件

    self.m_pFollowBtn = nil--跟随按钮
    self.m_pChangeNameBtn = nil--改名按钮
    self.m_pChangeNamePanel = nil--改名层

    self.m_curAttrInd = 0--当前显示属性的下表

    --self.m_p
end

function PetInfoSubUI:InitUICtr()
    local node = self.m_pUILayer:getChildByName("shenjiangInfoUI")
    local modelPanel = node:getChildByName("Show")

    self.m_pPetNode = modelPanel:getChildByName("Node")
    self.m_pPetModelNode = self.m_pPetNode:getChildByTag(1)
    if self.m_pPetModelNode == nil then
        --UI有可能是从Res缓存里面读取的，这个时候ModelNode已经在上一次加载过了
        self.m_pPetModelNode = ModelAniNode:create(AppDef.CEnum.ModelAniType.Monster, 0)
        self.m_pPetNode:addChild(self.m_pPetModelNode)
        self.m_pPetModelNode:setTag(1)
    end
    self.m_pNameLabel = modelPanel:getChildByName("bg_Name"):getChildByName("Name")
    self.m_pQualityImg = modelPanel:getChildByName("bg_Quality"):getChildByName("Value")
    self.m_pPowerLabel = modelPanel:getChildByName("bg_zhanli"):getChildByName("Value")
    self.m_pLvLabel = modelPanel:getChildByName("Level")
    local expPanel = modelPanel:getChildByName("bg_Bar")
    self.m_pExpLabel = expPanel:getChildByName("Value")
    self.m_pExpBar = expPanel:getChildByName("ExpBar")

    self.m_pChangeNamePanel = node:getChildByName("chongwugaiming")
    self.m_pChangeNamePanel:setVisible(false)

    self.m_pFollowBtn = modelPanel:getChildByName("btn_gensui")--跟随按钮
    self.m_pChangeNameBtn = modelPanel:getChildByName("btn_gaiming")--改名按钮
    self.m_pArchiveBtn = modelPanel:getChildByName("btn_tujian")--图鉴按钮
    self.m_pArchiveBtnRedPImg = self.m_pArchiveBtn:getChildByName("Prompt")
    self.m_pResolveBtn = modelPanel:getChildByName("btn_lianhua")--炼化按钮

    for i = 1, AppDef.Pet.MaxUpgradeItems do
        self.m_pMatBtns[i] = modelPanel:getChildByName("btn_Item_" .. i)
        self.m_pMatIcons[i] = self.m_pMatBtns[i]:getChildByName("IconImage")
        self.m_pMatMaskImgs[i] = self.m_pMatBtns[i]:getChildByName("Mask")
        --self.m_pAddMatImgs[i] = self.m_pMatBtns[i]:getChildByName("Icon")
        self.m_pMatNumLabels[i] = self.m_pMatBtns[i]:getChildByName("Value")
        self.m_pAddExpLabels[i] = self.m_pMatBtns[i]:getChildByName("Text")
        self.m_pMatRedDot[i]=self.m_pMatBtns[i]:getChildByName("RedDot")

        
    end

	self.m_imageSelect = modelPanel:getChildByName("Image_select")
	self.m_imageSelect:setVisible(false)
    local infoPanel = node:getChildByName("Info")

    self.m_pBaseAttrPanel = infoPanel:getChildByName("jichu")
    for i = 1, 18, 2 do
        self.m_pBaseAttrLabels[i] = self.m_pBaseAttrPanel:getChildByName("Attribute_" .. (i + 1) / 2)
        self.m_pBaseAttrLabels[i + 1] = self.m_pBaseAttrLabels[i]:getChildByName("Value")
    end

    self.m_pStarListView = self.m_pBaseAttrPanel:getChildByName("Stars")
    self.m_pStarCell = self.m_pBaseAttrPanel:getChildByName("Star")
    local tmp = self.m_pBaseAttrPanel:getChildByName("Type")

    self.m_pLvInAttrLabel = self.m_pBaseAttrPanel:getChildByName("Level"):getChildByName("Value")

    --self.m_pProLabel = tmp:getChildByName("Value")--职业属性
    self.m_pProImg = tmp:getChildByName("Image")--职业图片
    --self.m_pProLabel:setString("")--不显示了，只显示图片
    self.m_pExterAttrPanel = infoPanel:getChildByName("gaoji")
    local ind
    for i = 1, 32, 2 do
        ind = (i + 1) / 2
        self.m_pSeniorAttrLabels[i] = self.m_pExterAttrPanel:getChildByName("Attribute_" .. ind)
        self.m_pSeniorAttrLabels[i + 1] = self.m_pSeniorAttrLabels[i]:getChildByName("Value")
    end

    self.m_pBaseInfoBtn = infoPanel:getChildByName("CheckBox_jichu")
    self.m_pExterInfoBtn = infoPanel:getChildByName("CheckBox_gaoji")

    self.m_pSkillListView = infoPanel:getChildByName("ListView")

    self.m_pSkillCell = infoPanel:getChildByName("Item")
end

function PetInfoSubUI:onNodeEvent(event)        
    if "exit" == event then
        self:onExit()
    end
end

function PetInfoSubUI:AttrBtnTouched(sender)
    if sender == self.m_pBaseInfoBtn then
        self:SetCurAttrTab(1)
    else
        self:SetCurAttrTab(2)
    end
end

function PetInfoSubUI:UpgradeBtnClicked(pTouch, pEvent)   
	local ind = pTouch:getTag()
	if self.m_pCurMatBtnTouched == ind and pEvent == ccui.TouchEventType.ended then
		if self.m_bIsAutoUpgrade == true then
			self:MatBtnTouchEnd(ind)
		else
			self:MatBtnTouchBegan(ind)
		end
	elseif self.m_pCurMatBtnTouched ~= ind and pEvent == ccui.TouchEventType.ended then
		if self.m_bIsAutoUpgrade == true then
			self:MatBtnTouchEnd(self.m_pCurMatBtnTouched)
		end
		self:UpdateImageSelect(pTouch)
		self:MatBtnTouchBegan(ind)
	end

    
    --if pEvent == ccui.TouchEventType.began then
    --    local ind = pTouch:getTag()
     --   self:MatBtnTouchBegan(ind)
    --elseif pEvent == ccui.TouchEventType.ended then
    --    self:MatBtnTouchEnd(ind)    
    --end
end

function PetInfoSubUI:UpdateImageSelect(parent)
	self.m_imageSelect:retain()
	self.m_imageSelect:removeFromParent();

	parent:addChild(self.m_imageSelect)
    self.m_imageSelect:release()
    parent:getChildByName("RedDot"):setLocalZOrder(1)
	self.m_imageSelect:setPosition(cc.p(44.0, 44.0))
	self.m_imageSelect:setVisible(true)
end

function PetInfoSubUI:FollowBtnClicked(sender)
    self:HandleFollowPet()
end

function PetInfoSubUI:ChangeNameBtnClicked(sender)
    self:HandleChangeName()
end

function PetInfoSubUI:ArchiveBtnClicked(sender)
    Utils:OpenPetArchiveUI(1)
end

function PetInfoSubUI:ResolveClicked(sender)
    Utils:OpenFunction(AppDef.EModuleID.EMID_BEIBAO)
    LGameMsg.m_baseMsgWithOne:Change(LUIBagEvent.SelectTab, 4)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)  
end

function PetInfoSubUI:InitEvt()
    self.m_pUILayer:registerScriptHandler(handler(self,PetInfoSubUI.onNodeEvent))
    self:MarkIntaractCObj(self.m_pUILayer)
    self.m_pBaseInfoBtn:addClickEventListener(handler(self, PetInfoSubUI.AttrBtnTouched))
    self:MarkIntaractCObj(self.m_pBaseInfoBtn)
    self.m_pExterInfoBtn:addClickEventListener(handler(self, PetInfoSubUI.AttrBtnTouched))
    self:MarkIntaractCObj(self.m_pExterInfoBtn)
    local function UpgradeBtnClicked(pTouch, pEvent)
        local ind = pTouch:getTag()
		if self.m_pCurMatBtnTouched == ind and pEvent == ccui.TouchEventType.ended then
			if self.m_bIsAutoUpgrade == true then
				self:MatBtnTouchEnd(ind)
			else
				self:MatBtnTouchBegan(ind)
			end
		elseif self.m_pCurMatBtnTouched ~= ind and pEvent == ccui.TouchEventType.ended then
			if self.m_bIsAutoUpgrade == true then
				self:MatBtnTouchEnd(self.m_pCurMatBtnTouched)
			end
			self:MatBtnTouchBegan(ind)
		end
        --if pEvent == ccui.TouchEventType.began then
        --    local ind = pTouch:getTag()
        --    self:MatBtnTouchBegan(ind)
        --elseif pEvent == ccui.TouchEventType.ended then
        --    self:MatBtnTouchEnd(ind)
        --end
    end
    for i = 1, AppDef.Pet.MaxUpgradeItems do
        self.m_pMatBtns[i]:addTouchEventListener(handler(self, PetInfoSubUI.UpgradeBtnClicked))
        self:MarkIntaractCObj(self.m_pMatBtns[i])
        self.m_pMatBtns[i]:setTag(i)
    end


    self.m_pFollowBtn:addClickEventListener(handler(self, PetInfoSubUI.FollowBtnClicked))
    self:MarkIntaractCObj(self.m_pFollowBtn)
    self.m_pChangeNameBtn:addClickEventListener(handler(self, PetInfoSubUI.ChangeNameBtnClicked))
    self:MarkIntaractCObj(self.m_pChangeNameBtn)
    
    self.m_pArchiveBtn:addClickEventListener(handler(self, PetInfoSubUI.ArchiveBtnClicked))
    self:MarkIntaractCObj(self.m_pArchiveBtn)
    
    self.m_pResolveBtn:addClickEventListener(handler(self, PetInfoSubUI.ResolveClicked))
    self:MarkIntaractCObj(self.m_pResolveBtn)
end

function PetInfoSubUI:CheckTujianRedPoint()
    local ret =  Utils:TujianRedDotCheck()
    --local redImg = self.m_pTujianBtn:getChildByName("Prompt")
    self.m_pArchiveBtnRedPImg:setVisible(ret)
end

function PetInfoSubUI:HandleFollowPet()
    if LRoleDataMgr.Pet.followPetId == self.m_pPetData.id then
        LuaNetSendMsg:QueryPetFollowHero(0)
    else
        LuaNetSendMsg:QueryPetFollowHero(self.m_pPetData.id)
    end
    
end

function PetInfoSubUI:ShowPetFollowState()
    local text = self.m_pFollowBtn:getChildByName("Text")
    if LRoleDataMgr.Pet.followPetId == self.m_pPetData.id then
        text:setString(GUITips.UI_Pet_UnFollow)
        self.m_pFollowBtn:setSelected(true)
    else
        text:setString(GUITips.UI_Pet_Follow)
        self.m_pFollowBtn:setSelected(false)
    end
end

function PetInfoSubUI:OKBtnCallback(sender)
    local nameLabel = self.m_pChangeNamePanel:getChildByName("TextField")
    local newName = nameLabel:getString()

    local isLimited = Utils:IsLimitedMsg(newName)
    if isLimited then
        nameLabel:setString("")
        Utils:ShowScrollTips(GUITips.REI_TIPS_LIMITE_WORLD)
        return
    end

    if newName ~= self.m_pPetData.name or string.len(newName) > 0 then
        LuaNetSendMsg:QueryPetChangeName(self.m_pPetData.id, newName)
    end
    self.m_pChangeNamePanel:setVisible(false)
end

function PetInfoSubUI:CloseBtnCallback(sender)
    self.m_pChangeNamePanel:setVisible(false)
end

function PetInfoSubUI:HandleChangeName()
    self.m_pChangeNamePanel:setVisible(true)

    local nameLabel = self.m_pChangeNamePanel:getChildByName("TextField")
    local okBtn = self.m_pChangeNamePanel:getChildByName("Btn_Confirm")
    local closeBtn = self.m_pChangeNamePanel:getChildByName("bg"):getChildByName("Btn_close")
    okBtn:addClickEventListener(handler(self,PetInfoSubUI.OKBtnCallback))
    self:MarkIntaractCObj(okBtn)
    closeBtn:addClickEventListener(handler(self,PetInfoSubUI.CloseBtnCallback))
    self:MarkIntaractCObj(closeBtn)
end

function PetInfoSubUI:AutoUseItem()
    local tmp = self.m_bIsAutoUpgrade
    local success = self:UseItemToUpgrade()
    if tmp == false and success == true then
		self.m_bIsAutoUpgrade = true
        local delayTime = cc.DelayTime:create(0.1)
        local func = cc.CallFunc:create(handler(self,PetInfoSubUI.AutoUseItem))
        local eq = cc.Sequence:create(delayTime, func)
        local rep = cc.RepeatForever:create(eq)
        self.m_pMatBtns[self.m_pCurMatBtnTouched]:runAction(rep)
    elseif tmp == true and success == false then
        self.m_pMatBtns[self.m_pCurMatBtnTouched]:stopAllActions()
	end
	if success == false then
		self.m_imageSelect:setVisible(false)
		self.m_upgradeBeforeUseItemNum = 0
		self.m_bIsAutoUpgrade = false
	end

  
end

function PetInfoSubUI:MatBtnTouchBegan(ind)
    self.m_upgradeUseItemNum = 0
    if self.m_pCurMatBtnTouched > 0 then
		self.m_imageSelect:setVisible(true)
        self.m_pMatBtns[self.m_pCurMatBtnTouched]:stopAllActions()
    end
    -- if ind == self.m_pCurMatBtnTouched then
    --     return
    -- end 
    self.m_pCurMatBtnTouched = ind
    self.m_bIsAutoUpgrade = false
    local function AutoUseItem()
        local tmp = self.m_bIsAutoUpgrade
        local success = self:UseItemToUpgrade()
        if tmp == false and success == true then
			self.m_bIsAutoUpgrade = true
            local delayTime = cc.DelayTime:create(0.03)
            local func = cc.CallFunc:create(AutoUseItem)
            local eq = cc.Sequence:create(delayTime, func)
            local rep = cc.RepeatForever:create(eq)
            self.m_pMatBtns[self.m_pCurMatBtnTouched]:runAction(rep)
        elseif tmp == true and success == false then
			self.m_imageSelect:setVisible(false)
            self.m_pMatBtns[self.m_pCurMatBtnTouched]:stopAllActions()
        end
        
    end
    local delayTime = cc.DelayTime:create(0.3)
    local func = cc.CallFunc:create(handler(self,PetInfoSubUI.AutoUseItem))
    local eq = cc.Sequence:create(delayTime, func)
    self.m_pMatBtns[self.m_pCurMatBtnTouched]:runAction(eq)
end

function PetInfoSubUI:MatBtnTouchEnd()
    if self.m_pCurMatBtnTouched > 0 then
		self.m_imageSelect:setVisible(false)
		self.m_upgradeBeforeUseItemNum = 0
        self.m_pMatBtns[self.m_pCurMatBtnTouched]:stopAllActions()
    end
    if self.m_bIsAutoUpgrade then
        --已经处于长按自动使用状态就返回
        if self.m_upgradeUseItemNum == 0 then
            return
        end
        local itemId = AppDef.Pet.UpgradsMats[self.m_pCurMatBtnTouched]
        local citem = LDataConstMgr:getCItemByID(itemId)
        if citem ~= nil then
            local msg = string.format(GUITips.UI_Pet_LvUp_Cost_Tips2,self.m_upgradeUseItemNum,
                                citem.m_name,
                                self.m_upgradeUseItemNum * citem.additionalValue)
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
        end
		self.m_bIsAutoUpgrade = false
        return
    end
    --self:UseItemToUpgrade()
    if self.m_upgradeUseItemNum <= 0 then
        return
    end
    local itemId = AppDef.Pet.UpgradsMats[self.m_pCurMatBtnTouched]
    local citem = LDataConstMgr:getCItemByID(itemId)
    if citem ~= nil then
        local msg = string.format(GUITips.UI_Pet_LvUp_Cost_Tips1,citem.m_name,citem.additionalValue)
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
        self:SendMsg(LGameMsg.m_scrollTipsMsg)
    end
    self.m_pCurMatBtnTouched = 0
	self.m_bIsAutoUpgrade = false
end

--[[
使用道具升级
]]
function PetInfoSubUI:UseItemToUpgrade()
    self:ShowMatRedDot()
    if self.m_pPetData.level >= LRoleDataMgr.MyHeroInfo.level then
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.UI_Pet_LvUp_Tip1)
        self:SendMsg(LGameMsg.m_scrollTipsMsg)
        return false
    elseif self.m_pPetData.level >= AppDef.Pet.MaxLevel then
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.UI_Pet_LvUp_Tip2)
        self:SendMsg(LGameMsg.m_scrollTipsMsg)
        return false
    end

    
    local itemId = AppDef.Pet.UpgradsMats[self.m_pCurMatBtnTouched]

    local itemNum = LRoleDataMgr.Equip:CountItemNumById(itemId)
  
	if self.m_upgradeBeforeUseItemNum == 0 then
		self.m_upgradeBeforeUseItemNum = itemNum
	end
	if self.m_upgradeUseItemNum > self.m_upgradeBeforeUseItemNum then
		  itemNum = 0
	end 
   
    if itemNum <= 0 then
    
        local citem = LDataConstMgr:getCItemByID(itemId)
        -- if citem.from ~= nil and string.len(citem.from) > 0 then
        --     LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,citem.from)
        --     self:SendMsg(LGameMsg.m_scrollTipsMsg)
        -- else
        --     local msg = string.format(GUITips.UI_Item_Num_Limit,citem.m_name)
        --     LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
        --     self:SendMsg(LGameMsg.m_scrollTipsMsg)
        -- end

        local item = 
        {
            itemType = "CItem",
            itemData = citem,
        }
        LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowItemInfo, item)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)

        if self.m_bIsAutoUpgrade == true then
            if self.m_pCurMatBtnTouched > 0 then
                self.m_pMatBtns[self.m_pCurMatBtnTouched]:stopAllActions()
            end
        end
       
        return false
    end
	local upgrade_rate = AppDef.Pet.UpgradsMatsRate[self.m_pCurMatBtnTouched]
	local costItemNum = math.pow(self.m_pPetData.level/30, 5)/upgrade_rate
	local localnum = self.m_upgradeBeforeUseItemNum - self.m_upgradeUseItemNum
	if costItemNum > itemNum then
		costItemNum = itemNum
	elseif costItemNum > localnum then
		costItemNum = localnum
	end
    self.m_upgradeUseItemNum = self.m_upgradeUseItemNum + math.ceil(costItemNum)
    LuaNetSendMsg:QueryPetLvUp(self.m_pPetData.id, itemId, math.ceil(costItemNum))
   -- self:ShowMatRedDot()
    return true
end

function PetInfoSubUI:SetCurAttrTab(ind)
    if self.m_curAttrInd == ind then
        if self.m_curAttrInd == 1 then
            self.m_pBaseInfoBtn:setSelected(false)
        else
            self.m_pExterInfoBtn:setSelected(false)
        end
        return
    end
    self.m_curAttrInd = ind
    self:SetAttrBtnState()
    self:SetAttrPanelVisible()
end

function PetInfoSubUI:SetAttrBtnState()
    local label1
    local label2
    if self.m_curAttrInd == 1 then
        label1 = self.m_pBaseInfoBtn:getChildByName("Text_choose")
        label1:setVisible(false)
        label2 = self.m_pBaseInfoBtn:getChildByName("Text")
        label2:setVisible(true)

        self.m_pExterInfoBtn:setSelected(false)

        label1 = self.m_pExterInfoBtn:getChildByName("Text_choose")
        label1:setVisible(true)
        label2 = self.m_pExterInfoBtn:getChildByName("Text")
        label2:setVisible(false)
    else
        self.m_pBaseInfoBtn:setSelected(false)
        label1 = self.m_pBaseInfoBtn:getChildByName("Text_choose")
        label1:setVisible(true)
        label2 = self.m_pBaseInfoBtn:getChildByName("Text")
        label2:setVisible(false)

        label1 = self.m_pExterInfoBtn:getChildByName("Text_choose")
        label1:setVisible(false)
        label2 = self.m_pExterInfoBtn:getChildByName("Text")
        label2:setVisible(true)
    end
end

function PetInfoSubUI:SetAttrPanelVisible()
    if self.m_curAttrInd == 1 then
        self.m_pBaseAttrPanel:setVisible(true)
        self.m_pExterAttrPanel:setVisible(false)
    else
        self.m_pBaseAttrPanel:setVisible(false)
        self.m_pExterAttrPanel:setVisible(true)
    end
end

return PetInfoSubUI