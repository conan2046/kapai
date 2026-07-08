--[[
lua里面的游戏逻辑控制
]]


local function Debug(log)
    
end
local PetXiulianSubUI = LUIBase:New()
PetXiulianSubUI.__index = PetXiulianSubUI

function PetXiulianSubUI:New(petData)
	local o = LUIBase:New()
	setmetatable(o,PetXiulianSubUI)	
    o:Init(petData)
	return o
end


function PetXiulianSubUI:Init(petData)
    self:RegistMsgs()
    self:InitMemberVariable(petData)
    self:InitViewSize()
    self:InitUICtr()
    self:InitEvt()
    
    self:SetSelected(1)
    self:ShowPetInfo()
    self._buyItemTime = 0
end

function PetXiulianSubUI:RegistMsgs()
    self.msgIds = 
    {
        LUIPetEvent.SelectedPet,
        LUIPetEvent.ChangePetXiulian,
        LUILogicEvent.buyItemSucEvent,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function PetXiulianSubUI:ProcessEvent(msg)
    if msg.msgId == LUIPetEvent.SelectedPet then
        self:SetPetData(msg.value)
    elseif msg.msgId == LUIPetEvent.ChangePetXiulian then
        self:PetXiulianDataChanged(msg.value[1],msg.value[2])
    elseif msg.msgId == LUILogicEvent.buyItemSucEvent then
        if LFastShopDataMgr.m_curUseMattrial == AppDef.upgradeMaterial_ID.FM_Pet_xiulian then
            self._buyItemTime = self._buyItemTime + 1
            if self._buyItemTime == #self._materialArr then
                self._buyItemTime = 0 
                self:SetPetData(self.m_pPetData)
                LuaNetSendMsg:QueryPetXiulian(self.m_pPetData.id, self.m_curInd)
            end
        end
    end
end

function PetXiulianSubUI:PetXiulianDataChanged(pid, ind)
    if self.m_pPetData.id ~= pid then
        return
    end
    self:ShowPetInfo()

    local ani = ImodAnim:createWithFileSync("res2/fx/shengji_yuan")
    local function AniPlayEndCallback(sender)
        sender:removeFromParent()
    end
    ani:registerScriptEndCBHandler(AniPlayEndCallback)
    ani:PlayAction(0)
    local btnSize = self.m_pXiulianBtns[ind]:getContentSize()
    ani:setPosition(cc.p(btnSize.width/2,btnSize.height/2))
    self.m_pXiulianBtns[ind]:addChild(ani)
end

function PetXiulianSubUI:SetPetData(petData)
    self.m_pPetData = petData
    self:ShowPetInfo()
end

function PetXiulianSubUI:ShowPetInfo()
    self:ShowXiuLianLv()
    self:clearLackItemData()
    self:ShowCurXiulianInfo()
    self:CheckRedPointVisible()
end

function PetXiulianSubUI:ShowXiuLianLv()
    if self.m_pPetData == nil then
        return
    end
    local curNum = #self.m_pPetData.xiulianLv
    for i = 1, curNum do
        self.m_pXiulianLvLabels[i]:setString(self.m_pPetData.xiulianLv[i])
        local ret = LRoleDataMgr:PetCheckXiulianUp(self.m_pPetData, i)
        self.m_pXiulianRedPoints[i]:setVisible(ret)

    end
    for i = curNum + 1, AppDef.Pet.MaxXliulianType do
        self.m_pXiulianLvLabels[i]:setString("0")
        local ret = LRoleDataMgr:PetCheckXiulianUp(self.m_pPetData, i)
        self.m_pXiulianRedPoints[i]:setVisible(ret)
    end
end

function PetXiulianSubUI:CheckRedPointVisible()
    local ret = LRoleDataMgr:PetCheckXiulianUp(self.m_pPetData, self.m_curInd)
    local img = self.m_pXiulianBtn:getChildByName("Prompt")
    img:setVisible(ret)
    --PetCheckXiulianUp
end

function PetXiulianSubUI:ShowCurXiulianInfo()
    local lv = self.m_pPetData.xiulianLv[self.m_curInd]

    -- if lv == 0 then 
    --     --不可能等于0，等于0也不会走到这里的函数
    --     lv = 1
    -- end

    self.m_pXiulianNameLabel:setString(GUITips["UI_Pet_XiuLian" .. self.m_curInd])

    self.m_pXiulianLvLabel:setString("Lv." .. lv)

    self.m_pXiuLianImg:loadTexture(AppDef.Pet.XiulianRes[self.m_curInd],ccui.TextureResType.plistType)

    local basePetData = LDataConstMgr:GetPetData(self.m_pPetData.id)

    local xiulianData = LDataConstMgr:GetPetXiulianData(basePetData.quality, lv)
    
    local curArrtType1 = xiulianData.attrType1List[self.m_curInd]
    local curArrtValue1 = xiulianData.attrValue1List[self.m_curInd]

    local curArrtType2 = xiulianData.attrType2List[self.m_curInd]
    local curArrtValue2 = xiulianData.attrValue2List[self.m_curInd]

    curArrtValue1 = LDataConstMgr:GetPetFinalAttrAddValue(basePetData.petType, curArrtType1, curArrtValue1)

    curArrtValue2 = LDataConstMgr:GetPetFinalAttrAddValue(basePetData.petType, curArrtType2, curArrtValue2)
    local strType
    if curArrtType1 == AppDef.EAttrType.EAT_ATTACK then
        if self.m_pPetData.baseData.attackType == 1 then--攻击类型（1物攻2法攻）
            typeStr = GUITips.Item_Info_Attr178
        else
            typeStr = GUITips.Item_Info_Attr179
        end
    else
        typeStr = LDataConstMgr:GetItemAttrName(curArrtType1)
    end
    self.m_pAttrTypeLabel1:setString(typeStr .. ":")
    self.m_pAttrValueLabel1:setString(curArrtValue1)

    if curArrtType2 == AppDef.EAttrType.EAT_ATTACK then
        if self.m_pPetData.baseData.attackType == 1 then--攻击类型（1物攻2法攻）
            typeStr = GUITips.Item_Info_Attr178
        else
            typeStr = GUITips.Item_Info_Attr179
        end
    else
        typeStr = LDataConstMgr:GetItemAttrName(curArrtType2)
    end
    self.m_pAttrTypeLabel2:setString(typeStr .. ":")
    self.m_pAttrValueLabel2:setString(curArrtValue2)

    if lv >=AppDef.Pet.MaxXliulianLv then
        --达到最大等级
        self.m_pNextAttrTypeLabel1:setVisible(false)
        self.m_pNeedHeroLvLabel:getParent():setVisible(false)
        self.m_pNextAttrValueLabel1:setVisible(false)
        self.m_pNextAttrTypeLabel2:setVisible(false)
        self.m_pNextAttrValueLabel2:setVisible(false)
        self.m_pMaxLvTipsLabel:setVisible(true)
        self.m_pMatImg1:setVisible(false)
        self.m_pMatImg2:setVisible(false)
        self.m_pXiulianBtn:setVisible(false)
        return
    end
    self.m_pNeedHeroLvLabel:getParent():setVisible(true)
    self.m_pMatImg1:setVisible(true)
    self.m_pMatImg2:setVisible(true)
    self.m_pXiulianBtn:setVisible(true)
    self.m_pNextAttrTypeLabel1:setVisible(true)
    self.m_pNextAttrValueLabel1:setVisible(true)
    self.m_pNextAttrTypeLabel2:setVisible(true)
    self.m_pNextAttrValueLabel2:setVisible(true)
    self.m_pMaxLvTipsLabel:setVisible(false)

    xiulianData = LDataConstMgr:GetPetXiulianData(basePetData.quality, lv + 1)

    curArrtType1 = xiulianData.attrType1List[self.m_curInd]
    curArrtValue1 = xiulianData.attrValue1List[self.m_curInd]

    curArrtType2 = xiulianData.attrType2List[self.m_curInd]
    curArrtValue2 = xiulianData.attrValue2List[self.m_curInd]

    curArrtValue1 = LDataConstMgr:GetPetFinalAttrAddValue(basePetData.petType, curArrtType1, curArrtValue1)

    curArrtValue2 = LDataConstMgr:GetPetFinalAttrAddValue(basePetData.petType, curArrtType2, curArrtValue2)

    self.m_pNextAttrTypeLabel1:setString(LDataConstMgr:GetItemAttrName(curArrtType1) .. ":")
    self.m_pNextAttrValueLabel1:setString(curArrtValue1)

    if curArrtType2 == AppDef.EAttrType.EAT_ATTACK then
        if self.m_pPetData.baseData.attackType == 1 then--攻击类型（1物攻2法攻）
            typeStr = GUITips.Item_Info_Attr178
        else
            typeStr = GUITips.Item_Info_Attr179
        end
    else
        typeStr = LDataConstMgr:GetItemAttrName(curArrtType2)
    end
    self.m_pNextAttrTypeLabel2:setString(typeStr .. ":")
    self.m_pNextAttrValueLabel2:setString(curArrtValue2)
    xiulianData = LDataConstMgr:GetPetXiulianData(basePetData.quality, lv)
    local needHeroLv = xiulianData.heroLvList[self.m_curInd]
    self._needLv = needHeroLv
    for i = 1,2 do
        local itemId = xiulianData.needItemIdList[i]
        local itemNum = xiulianData.needItemNumList[i]
        local citem = LDataConstMgr:getCItemByID(itemId)
        local myItemNum = LRoleDataMgr.Equip:CountItemNumById(itemId)

        local itemName = citem.m_name
        local itemIconImg = self["m_pMatImg" .. i]:getChildByName("Icon")
        itemIconImg:loadTexture(string.format("item/equip%d.png", citem.m_pic), ccui.TextureResType.localType)
        local itemNumLabel =  self["m_pMatImg" .. i]:getChildByName("Value")
        itemNumLabel:setString( "" .. myItemNum .. "/" .. itemNum)
        if myItemNum >= itemNum then
            itemNumLabel:setTextColor(UICOLOR_GREEN)
        else
            itemNumLabel:setTextColor(UICOLOR_RED)
            self:addLackItemData(itemId, itemNum - myItemNum)
        end

        local nameLabel = self["m_pMatImg" .. i]:getChildByName("bg_Name"):getChildByName("Name")
        nameLabel:setString(itemName)
    end
    self.m_pNeedHeroLvLabel:setString(xiulianData.heroLvList[self.m_curInd])
    if needHeroLv > self.m_pPetData.level then
        self.m_pNeedHeroLvLabel:setTextColor(UICOLOR_RED)
    else
        self.m_pNeedHeroLvLabel:setTextColor(UICOLOR_GREEN)
    end
end

function PetXiulianSubUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/shenjiangxiulianLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

function PetXiulianSubUI:onExit()
    --节点放在主节点上删除
    --self.m_pUILayer = nil
    self.m_pPetData = nil--当前选中的宠物数据
    self.m_pXiulianBtns = nil--修炼按钮
    self.m_pXiulianLvLabels = nil--修炼等级label
    self.m_pXiulianRedPoints = nil--修炼红点提示
    self.m_pXiulianNameLabel = nil--当前选择的修炼名字
    self.m_pXiuLianImg = nil--当前修炼的图片
    self.m_pXiulianLvLabel = nil--当前选择的修炼等级
    self.m_pAttrTypeLabel1 = nil--当前属性类型
    self.m_pAttrValueLabel1 = nil--当前属性类型
    self.m_pAttrTypeLabel2 = nil--当前属性类型
    self.m_pAttrValueLabel2 = nil--当前属性类型

    self.m_pNextAttrLabel = nil--下级属性
    self.m_pNextAttrTypeLabel1 = nil--当前属性类型
    self.m_pNextAttrValueLabel1 = nil--当前属性类型
    self.m_pNextAttrTypeLabel2 = nil--当前属性类型
    self.m_pNextAttrValueLabel2 = nil--当前属性类型
    self.m_pMaxLvTipsLabel = nil--最大等级提示

    self.m_pMatImg1 = nil--材料1
    self.m_pMatImg2 = nil--材料2

    self.m_pXiulianBtn = nil--修炼按钮


    self.m_curInd = nil--当前选中的修炼类型
    self:Destory()
end

--[[
初始化成员变量
]]
function PetXiulianSubUI:InitMemberVariable(petData)
    self.m_pPetData = petData--当前选中的宠物数据
    self.m_pXiulianBtns = {}--修炼按钮
    self.m_pXiulianLvLabels = {}--修炼等级label
    self.m_pXiulianRedPoints = {}--修炼红点提示
    self.m_pXiulianNameLabel = nil--当前选择的修炼名字
    self.m_pXiuLianImg = nil--当前修炼的图片
    self.m_pXiulianLvLabel = nil--当前选择的修炼等级
    self.m_pAttrTypeLabel1 = nil--当前属性类型
    self.m_pAttrValueLabel1 = nil--当前属性类型
    self.m_pAttrTypeLabel2 = nil--当前属性类型
    self.m_pAttrValueLabel2 = nil--当前属性类型

    self.m_pNextAttrLabel = nil--下级属性
    self.m_pNextAttrTypeLabel1 = nil--当前属性类型
    self.m_pNextAttrValueLabel1 = nil--当前属性类型
    self.m_pNextAttrTypeLabel2 = nil--当前属性类型
    self.m_pNextAttrValueLabel2 = nil--当前属性类型
    self.m_pMaxLvTipsLabel = nil--最大等级提示
    self.m_pNeedHeroLvLabel = nil--需求神将等级

    self.m_pMatImg1 = nil--材料1
    self.m_pMatImg2 = nil--材料2

    self.m_pXiulianBtn = nil--修炼按钮


    self.m_curInd = 0--当前选中的修炼类型

    self._needLv = 0 --当前神将升级需要等级

--     AppDef.Pet.MaxXliulianType = 5--宠物最大的修炼类型数量
-- AppDef.Pet.MaxXliulianLv = 20--最大修炼等级
    
end

function PetXiulianSubUI:InitUICtr()
    local panel = self.m_pUILayer:getChildByName("shenjiangxiulianUI")
    local showPanel = panel:getChildByName("Show")
    for i = 1, AppDef.Pet.MaxXliulianType do
        self.m_pXiulianBtns[i] = showPanel:getChildByName("btn_" .. i)
        self.m_pXiulianBtns[i]:setTag(i)
        self.m_pXiulianLvLabels[i] = self.m_pXiulianBtns[i]:getChildByName("bg_Level"):getChildByName("Value")
        self.m_pXiulianRedPoints[i] = self.m_pXiulianBtns[i]:getChildByName("Prompt")
        local chooseImg = self.m_pXiulianBtns[i]:getChildByName("Choose")
        chooseImg:setVisible(false)
    end


    local infoPanel = panel:getChildByName("xiulian")
    local imgbg = infoPanel:getChildByName("bg_xuemai")
    self.m_pXiuLianImg = imgbg:getChildByName("Icon")

    self.m_pXiulianNameLabel = imgbg:getChildByName("Name")--当前选择的修炼名字
    self.m_pXiulianLvLabel = imgbg:getChildByName("Level")--当前选择的修炼等级
    local tmp = infoPanel:getChildByName("dangqianshuxing")
    self.m_pAttrTypeLabel1 = tmp:getChildByName("Attribute1")--当前属性类型
    self.m_pAttrValueLabel1 = self.m_pAttrTypeLabel1:getChildByName("Value")--当前属性类型
    self.m_pAttrTypeLabel2 = tmp:getChildByName("Attribute2")--当前属性类型
    self.m_pAttrValueLabel2 = self.m_pAttrTypeLabel2:getChildByName("Value")--当前属性类型

    self.m_pNextAttrLabel = infoPanel:getChildByName("xiajishuxing")--下级属性
    self.m_pNextAttrTypeLabel1 = self.m_pNextAttrLabel:getChildByName("Attribute1")--当前属性类型
    self.m_pNextAttrValueLabel1 = self.m_pNextAttrTypeLabel1:getChildByName("Value")--当前属性类型
    self.m_pNextAttrTypeLabel2 = self.m_pNextAttrLabel:getChildByName("Attribute2")--当前属性类型
    self.m_pNextAttrValueLabel2 = self.m_pNextAttrTypeLabel2:getChildByName("Value")--当前属性类型
    self.m_pMaxLvTipsLabel = self.m_pNextAttrLabel:getChildByName("Tips")--最大等级提示
    self.m_pNeedHeroLvLabel = infoPanel:getChildByName("Level"):getChildByName("Value")

    self.m_pMatImg1 = infoPanel:getChildByName("Material1")--材料1
    self.m_pMatImg2 = infoPanel:getChildByName("Material2")--材料2

    self.m_pXiulianBtn = infoPanel:getChildByName("btn_xiulian")--修炼按钮
end

function PetXiulianSubUI:InitEvt()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    local function XliulianBtnClicked(sender)
        local ind = sender:getTag()
        self:SetSelected(ind)
        self:clearLackItemData()
        self:ShowCurXiulianInfo()
        self:CheckRedPointVisible()
    end
    for i = 1, AppDef.Pet.MaxXliulianType do
        self.m_pXiulianBtns[i]:addClickEventListener(XliulianBtnClicked)
		self:MarkIntaractCObj(self.m_pXiulianBtns[i])
    end

    local function MatBtnClicked(sender)
        local ind = sender:getTag()
        self:ShowMatInfo(ind)
    end
    self.m_pMatImg1:addClickEventListener(MatBtnClicked)
	self:MarkIntaractCObj(self.m_pMatImg1)
    self.m_pMatImg1:setTag(1)
    self.m_pMatImg1:setTouchEnabled(true)
    self.m_pMatImg2:addClickEventListener(MatBtnClicked)
	self:MarkIntaractCObj(self.m_pMatImg2)
    self.m_pMatImg2:setTag(2)
    self.m_pMatImg2:setTouchEnabled(true)


    local function XiulianBtnClicked(sender)
        if self.m_curInd == 0 then
            return
        end

--升级材料不足
        if self._materialArr == nil then
            self:clearLackItemData()
        end

        if self._needLv <= self.m_pPetData.level and #self._materialArr > 0 then
            LFastShopDataMgr:ShowNeedBuyMaterial(self._materialArr, AppDef.upgradeMaterial_ID.FM_Pet_xiulian)
            return
        end
        LuaNetSendMsg:QueryPetXiulian(self.m_pPetData.id, self.m_curInd)
    end
    self.m_pXiulianBtn:addClickEventListener(XiulianBtnClicked)
	self:MarkIntaractCObj(self.m_pXiulianBtn)
end

function PetXiulianSubUI:ShowMatInfo(ind)
    local lv = self.m_pPetData.xiulianLv[self.m_curInd]
    
    if lv == 0 then 
        --不可能等于0，等于0也不会走到这里的函数
        lv = 1
    end
    
    local basePetData = LDataConstMgr:GetPetData(self.m_pPetData.id)

    local xiulianData = LDataConstMgr:GetPetXiulianData(basePetData.quality, lv)
    local itemId = xiulianData.needItemIdList[ind]

    local citem = LDataConstMgr:getCItemByID(itemId)
    --local pitem = 
    local item = 
    {
        itemType = "CItem",
        itemData = citem,
    }
    LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowItemInfo, item)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function PetXiulianSubUI:SetSelected(ind)
    if self.m_curInd == ind then
        return
    end
    local chooseImg
    if self.m_curInd > 0 then
        chooseImg = self.m_pXiulianBtns[self.m_curInd]:getChildByName("Choose")
        chooseImg:setVisible(false)
    end
    self.m_curInd = ind
    chooseImg = self.m_pXiulianBtns[self.m_curInd]:getChildByName("Choose")
    chooseImg:setVisible(true)
end

--材料升级
function PetXiulianSubUI:addLackItemData(id, num)
    -- body
    local material = {}
    material.id = id
    material.num = num
    table.insert(self._materialArr, material)
end

function PetXiulianSubUI:clearLackItemData( ... )
    -- body
    self._materialArr = {}
end

return PetXiulianSubUI