--[[
lua里面的游戏逻辑控制
]]


local function Debug(log)
    
end
local PetUpgradeSubUI = LUIBase:New()
PetUpgradeSubUI.__index = PetUpgradeSubUI

function PetUpgradeSubUI:New(petData)
	local o = LUIBase:New()
	setmetatable(o,PetUpgradeSubUI)	
    o:Init(petData)
	return o
end


function PetUpgradeSubUI:Init(petData)
    self:RegistMsgs()
    self:InitMemberVariable(petData)
    self:InitViewSize()
    self:InitUICtr()
    self:InitEvt()
    self:ShowPetInfo()
end

function PetUpgradeSubUI:RegistMsgs()
    self.msgIds = 
    {
        LUIPetEvent.SelectedPet,
        LUIPetEvent.ChangePetStar,
        LUIRoleDataChangeEvent.ShenHunChanged,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function PetUpgradeSubUI:ProcessEvent(msg)
    if msg.msgId == LUIPetEvent.SelectedPet then
        self:SetPetData(msg.value)
    elseif msg.msgId == LUIPetEvent.ChangePetStar then
        self:PetStarChanged(msg.value[1],msg.value[2],msg.value[3])
    elseif msg.msgId == LUIRoleDataChangeEvent.ShenHunChanged then
        self:ShowMats()
        self:ShowBtnRedPoint()
    end
end

function PetUpgradeSubUI:tempPetAttr()
    LRoleDataMgr.tempPetUpStarData.power = self.m_pPetData.zhandouli
    LRoleDataMgr.tempPetUpStarData.attrs = clone(self.m_pPetData.attrs)
end

function PetUpgradeSubUI:PetStarChanged(pid,isStarChange, isSubStarChange)
    if self.m_pPetData.id ~= pid then
        return
    end
    self:ShowStar(isStarChange)
    self:ShowSubStar(isSubStarChange)
    self:ShowMats()
    self:ShowBtnRedPoint()
    self:ShowPower()
    self:ShowNeedLevel()
    if isStarChange then
        self:ShowGrowAttrs()
    end
end

function PetUpgradeSubUI:ShowGrowAttrs()
    if self.m_pPetData == nil then
        return
    end
    local basePetData = LDataConstMgr:GetPetData(self.m_pPetData.id)
    if basePetData == nil then
        return
    end
    
    local attrs = LDataConstMgr:GetPetGrowAttr(self.m_pPetData.id, self.m_pPetData.star)
    if attrs and self.m_growAttrValue then
        for k,v in pairs(self.m_growAttrValue) do
            if k and v and v.valueText and attrs[k] then
                v.valueText:setString(attrs[k])
            end
        end
    end
end

function PetUpgradeSubUI:SetPetData(petData)
    self.m_pPetData = petData
    self:ShowPetInfo()
    self:ShowBtnRedPoint()
end

function PetUpgradeSubUI:ShowPetInfo()
    if self.m_pPetData == nil then
        return
    end
    self:ShowPetModel()
    self:ShowPower()
    self:ShowName()
    self:ShowLv()
    self:ShowExp()
    self:ShowQuality()
    self:ShowStar()
    self:ShowSubStar()
    self:ShowMats()
    self:ShowBtnRedPoint()
    self:ShowGrowAttrs()
    self:ShowNeedLevel()
    -- self:ShowAttrInfo()
    -- self:ShowSkills()
    
end

--[[
显示该宠物的宠物碎片
]]
function PetUpgradeSubUI:ShowMats()
    local costNum = LDataConstMgr:GetPetShenXingCost(self.m_pPetData.id, self.m_pPetData.star, self.m_pPetData.starStep + 1)
    self._costShenhun = costNum
    local myNum = LRoleDataMgr.MyHeroInfo:GetDetailData().shenHun

    local haveNumLabel = self.m_havePanel:getChildByName("Value")
    local _ = haveNumLabel and haveNumLabel:setString(tostring(myNum))

    local costNumLabel = self.m_costPanel:getChildByName("Value")
    if costNumLabel then
        costNumLabel:setString(tostring(costNum))
        if myNum >= costNum then
            costNumLabel:setTextColor(cc.c3b(120, 66, 63))
        else
            costNumLabel:setTextColor(UICOLOR_RED)
        end
    end
end

function PetUpgradeSubUI:ShowNeedLevel()
    if self.m_levelPanel then
        local pValue = self.m_levelPanel:getChildByName("Level")
        if pValue then
            local levelLimit = LDataConstMgr:GetPetStarLevelLimit(self.m_pPetData.star)
            pValue:setString(tostring(levelLimit))
            if self.m_pPetData.level then
                if levelLimit <= self.m_pPetData.level then
                    pValue:setTextColor(AppDef.UIColor.GREEN)
                else
                    pValue:setTextColor(AppDef.UIColor.RED)
                end
            end
        end
    end
end

function PetUpgradeSubUI:ShowBtnRedPoint()
    local ret = LRoleDataMgr:PetCheckStarUp(self.m_pPetData)

    local redPointImg = self.m_pStarUpBtn:getChildByName("Prompt")
    redPointImg:setVisible(ret)
end

--[[
显示品质评分
]]
function PetUpgradeSubUI:ShowQuality()
    AppDef:GetPetQualityScore(self.m_pQualityImg, self.m_pPetData.baseData.quality)
end

--[[
显示星级
param1:isNewStar:是否升级
]]
function PetUpgradeSubUI:ShowStar(isLvUp)
    isLvUp = isLvUp or false
    local lightStarRes = "res/UI/ui_common/ui_zuoqi_xing_01.png"
    local grayStarRes = "res/UI/ui_common/ui_zuoqi_xing_02.png"


    for i = 1, self.m_pPetData.star do
        local starImg = self.m_pStarListView:getItem(i - 1)
        starImg:loadTexture(lightStarRes,ccui.TextureResType.plistType)  
    end


    for i = self.m_pPetData.star + 1, AppDef.Pet.MaxStar  do
        local starImg = self.m_pStarListView:getItem(i - 1)
        starImg:loadTexture(grayStarRes,ccui.TextureResType.plistType)
    end

    if isLvUp then
        local starImg = self.m_pStarListView:getItem(self.m_pPetData.star - 1)
        local ani = ImodAnim:createWithFileSync("res2/fx/shengxing")
        local function AniPlayEndCallback(sender)
            sender:removeFromParent()
        end
        ani:registerScriptEndCBHandler(AniPlayEndCallback)
        ani:PlayAction(0)
        local btnSize = starImg:getContentSize()
        ani:setPosition(cc.p(btnSize.width/2,btnSize.height/2))
        starImg:addChild(ani)
    end
end

--[[
获取子星级属性加成
]]
function PetUpgradeSubUI:GetSubStarAddValue(ind)
    local basePetData = LDataConstMgr:GetPetData(self.m_pPetData.id)
    if basePetData == nil then
        return "Error"
    end
    local attrType, attrValue = LDataConstMgr:GetPetAddAttr(self.m_pPetData.id, self.m_pPetData.star, ind)
    if attrType == nil or attrValue == nil then
       return "Error" 
    end
    local typeStr
    if attrType == AppDef.EAttrType.EAT_ATTACK then
        if self.m_pPetData.baseData.attackType == 1 then--攻击类型（1物攻2法攻）
            typeStr = GUITips.Item_Info_Attr178
        else
            typeStr = GUITips.Item_Info_Attr179
        end
    else
        typeStr = LDataConstMgr:GetItemAttrName(attrType)
    end
    
    return typeStr , "+" .. attrValue
end

--[[
显示子星级
]]
function PetUpgradeSubUI:ShowSubStar(isLvUp)
    isLvUp = isLvUp or false
    local lightStarRes = "res/UI/ui_shenjiang/ui_shenjiang_shengxing_xingdian_dianliang.png"
    local grayStarRes = "res/UI/ui_shenjiang/ui_shenjiang_shengxing_xingdian.png"

    local starPanel = self.m_pSubStarPanel

    local bg = self.m_pSubStarPanel:getChildByName("bg")
    for i = 1, self.m_pPetData.starStep do
        local starImg = self.m_pSubStarPanel:getChildByName("Point_" .. i)
        starImg:loadTexture(lightStarRes,ccui.TextureResType.plistType)
        local strType, strValue = self:GetSubStarAddValue(i)
        local textLabel = starImg:getChildByName("Attribute")
        textLabel:setOpacity(255)
        textLabel:setString(strType)
        textLabel:setVisible(true)
        textLabel:setTextColor(AppDef.UIColor.BLACK)
        local valueLabel = textLabel:getChildByName("Value")
        valueLabel:setString(strValue)
        valueLabel:setTextColor(AppDef.UIColor.GREEN)
        valueLabel:setOpacity(255)
        if i < AppDef.Pet.MaxSubStar then
            local cb = bg:getChildByName("Road_" .. i)
            cb:setSelected(true)
        end
    end

    if isLvUp then
        local starImg = self.m_pSubStarPanel:getChildByName("Point_" .. self.m_pPetData.starStep)
        if starImg ~= nil then
            local ani = ImodAnim:createWithFileSync("res2/fx/lvdian")
            local function AniPlayEndCallback(sender)
                sender:removeFromParent()
            end
            ani:registerScriptEndCBHandler(AniPlayEndCallback)
            ani:PlayAction(0)
            local btnSize = starImg:getContentSize()
            ani:setPosition(cc.p(btnSize.width/2,btnSize.height/2))
            starImg:addChild(ani)
        end
    end

    for i = self.m_pPetData.starStep + 1, AppDef.Pet.MaxSubStar  do
        local starImg = self.m_pSubStarPanel:getChildByName("Point_" .. i)
        starImg:loadTexture(grayStarRes,ccui.TextureResType.plistType)
        local textLabel = starImg:getChildByName("Attribute")
        -- if i == self.m_pPetData.starStep + 1 then
            local strType, strValue = self:GetSubStarAddValue(i)
            textLabel:setString(strType)
            textLabel:setVisible(true)
            --textLabel:setTextColor(AppDef.UIColor.RED)
            local valueLabel = textLabel:getChildByName("Value")
            valueLabel:setString(strValue)
            valueLabel:setOpacity(128)
            valueLabel:setTextColor(AppDef.UIColor.BLACK)
            --valueLabel:setTextColor(AppDef.UIColor.RED)
        -- else
        --     textLabel:setVisible(false)
        -- end
        
        if i < AppDef.Pet.MaxSubStar then
            local cb = bg:getChildByName("Road_" .. i)
            cb:setSelected(false)
        end
        
        
    end
end

--[[
显示战斗力
]]
function PetUpgradeSubUI:ShowPower()
    self.m_pPowerLabel:setString(self.m_pPetData.zhandouli)
end

--[[
显示名字
]]
function PetUpgradeSubUI:ShowName()
    self.m_pNameLabel:setString(self.m_pPetData.name)
    local color = AppDef:GetPetQualityColor(self.m_pPetData.baseData.quality)
    self.m_pNameLabel:setTextColor(color)
end

--[[
显示等级
]]
function PetUpgradeSubUI:ShowLv()
    self.m_pLvLabel:setString("Lv." .. self.m_pPetData.level)
end

--[[
显示经验条
]]
function PetUpgradeSubUI:ShowExp()
    self.m_pExpLabel:setString(self.m_pPetData.exp .. "/" .. self.m_pPetData.expMax)
    local expRate = self.m_pPetData.exp * 100 / self.m_pPetData.expMax
    
    self.m_pExpBar:setPercent(expRate)
end

--[[
显示宠物模型
]]
function PetUpgradeSubUI:ShowPetModel()
    if self.m_pPetData == nil then
        self.m_pPetModelNode:setVisible(false)
        return
    end
    self.m_pPetModelNode:setVisible(true)
    self.m_pPetModelNode:InitAni(AppDef.CEnum.ModelAniType.Monster, self.m_pPetData.baseData.pic)
    self.m_pPetModelNode:PlayStand(self.m_pPetData.baseData.defaultFace)
end

function PetUpgradeSubUI:InitViewSize()
    
    self.m_pUILayer = cc.CSLoader:createNode("csd/shenjiangshengxingLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

function PetUpgradeSubUI:onExit()
    --节点放在主节点上删除
    --self.m_pUILayer = nil
    self.m_pPetData = nil--当前选中的宠物数据
    self.m_pPetNode = nil--宠物显示节点
    self.m_pPetModelNode = nil--宠物动画节点
    self.m_pNameLabel = nil--宠物名字
    self.m_pStarUpBtn = nil--升星按钮
    self.m_pQualityImg = nil--品质ImageView
    self.m_pStarListView = nil--星级ListView
    self.m_pSubStarPanel = nil--子星级Panel
    self.m_pItemPanel = nil--碎片道具Panel
    self.m_pPowerLabel = nil--战斗力Label
    self.m_pLvLabel = nil--等级Label
    self.m_pExpLabel = nil--经验Label
    self.m_pExpBar = nil--经验条
    self:Destory()
end

--[[
初始化成员变量
]]
function PetUpgradeSubUI:InitMemberVariable(petData)
    self.m_pPetData = petData--当前选中的宠物数据
    self.m_pPetNode = nil--宠物显示节点
    self.m_pPetModelNode = nil--宠物动画节点
    self.m_pNameLabel = nil--宠物名字
    self.m_pStarUpBtn = nil--升星按钮
    self.m_pQualityImg = nil--品质ImageView
    self.m_pStarListView = nil--星级ListView
    self.m_pSubStarPanel = nil--子星级Panel
    self.m_pItemPanel = nil--碎片道具Panel
    self.m_pPowerLabel = nil--战斗力Label
    self.m_pLvLabel = nil--等级Label
    self.m_pExpLabel = nil--经验Label
    self.m_pExpBar = nil--经验条
    self._costShenhun = 0 --花费神魂
end

function PetUpgradeSubUI:InitUICtr()
    local node = self.m_pUILayer:getChildByName("shenjiangshengxingUI")
    local modelPanel = node:getChildByName("Show")

    self.m_pPetNode = modelPanel:getChildByName("Node")
    self.m_pPetModelNode = ModelAniNode:create(AppDef.CEnum.ModelAniType.Monster, 0)
    self.m_pPetNode:addChild(self.m_pPetModelNode)
    self.m_pNameLabel = modelPanel:getChildByName("bg_Name"):getChildByName("Name")
    self.m_pQualityImg = modelPanel:getChildByName("bg_Quality"):getChildByName("Value")
    self.m_pPowerLabel = modelPanel:getChildByName("bg_zhanli"):getChildByName("Value")

    self.m_pLvLabel = modelPanel:getChildByName("Level")
    local expPanel = modelPanel:getChildByName("bg_Bar")
    self.m_pExpLabel = expPanel:getChildByName("Value")
    self.m_pExpBar = expPanel:getChildByName("ExpBar")

    local infoPanel = node:getChildByName("shengxing")
    self.m_pStarListView = infoPanel:getChildByName("Stars")
    self.m_pSubStarPanel = infoPanel:getChildByName("Points")
    -- self.m_pItemPanel = infoPanel:getChildByName("bg_Material")
    self.m_havePanel = infoPanel:getChildByName("bg_Own")
    self.m_costPanel = infoPanel:getChildByName("bg_Expenditure")
    self.m_levelPanel = infoPanel:getChildByName("LevelBg")

    self.m_pStarUpBtn = infoPanel:getChildByName("btn_shengxing")

    local pImageBg = modelPanel:getChildByName("Image_bg")
    self.m_growAttrValue = {}
    local temp = {
        AppDef.EAttrGrowType.EAT_ATTACK_CHENGZHANG,
        AppDef.EAttrGrowType.EAT_DEFENSE_CHENGZHANG,
        AppDef.EAttrGrowType.EAT_MD_CHENGZHANG,
        AppDef.EAttrGrowType.EAT_HP_CHENGZHANG,
    }
    for i=1,#temp do
        local it = {}
        it.nameText = pImageBg:getChildByName("Attribute_"..i)
        it.nameText:setString((AppDef.EAttrGrowName[temp[i]] or "").."：")
        it.valueText = it.nameText:getChildByName("Value")
        it.valueText:setString("0")
        self.m_growAttrValue[temp[i]] = it
    end
end

function PetUpgradeSubUI:InitEvt()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)


    -- local function MatItemClicked(sender)
    --     local cpdData = LDataConstMgr:GetPetCpdData(self.m_pPetData.id)
    --     if cpdData ~= nil then
    --         local itemId = cpdData.itemId
    --         local citem = LDataConstMgr:getCItemByID(itemId)
    --         --local pitem = 
    --         local item = 
    --         {
    --             itemType = "CItem",
    --             itemData = citem,
    --         }
    --         LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowItemInfo, item)
    --         self:SendMsg(LGameMsg.m_baseMsgWithOne)
    --     end
    -- end
    -- self.m_pItemPanel:addClickEventListener(MatItemClicked)
    -- self.m_pItemPanel:setTouchEnabled(true)

    local function StarUpBtnClicked(sender)

        if self.m_pPetData.star >= AppDef.Pet.MaxStar and self.m_pPetData.starStep >= AppDef.Pet.MaxSubStar then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.UI_Pet_LvUp_Max_Tip)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
            return
        end

--神魂不足,弹来源
        local myNum = LRoleDataMgr.MyHeroInfo:GetDetailData().shenHun
        if self._costShenhun > myNum then
            Utils:ShowGoldTips(AppDef.AwrdItem.AWRD_ITEM_SHENPO)
            return
        end

        self:tempPetAttr()
        LuaNetSendMsg:QueryPetStarUp(self.m_pPetData.id)
    end
    self.m_pStarUpBtn:addClickEventListener(StarUpBtnClicked)
	self:MarkIntaractCObj(self.m_pStarUpBtn)

end

return PetUpgradeSubUI