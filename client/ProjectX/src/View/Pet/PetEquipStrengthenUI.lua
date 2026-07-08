--[[
lua里面的游戏逻辑控制
神将装备强化-弹框
]]

local PetEquipStrengthenUI = LUIBase:New()
PetEquipStrengthenUI.__index = PetEquipStrengthenUI
function PetEquipStrengthenUI:New(userData)
    local o = LUIBase:New()
    setmetatable(o, PetEquipStrengthenUI)
    o:Init(userData)
    return o
end


function PetEquipStrengthenUI:Init(userData)
    self.m_pUILayer = cc.CSLoader:createNode("csd/shenjiangEquip2Layer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:InitData()
    self:InitEvt()
    self:setEquipData(userData)
end

function PetEquipStrengthenUI:onExit()
    self.m_pUILayer = nil
    Utils:unschedule(nil, self.m_scheduleId)
    self:Destory()
end

function PetEquipStrengthenUI:setEquipData(userData)
    self.m_changeType = userData[3]  or 0
    self.m_oldValue = 0
    self.m_addInd = 0
    if self.m_pEquipdata ~= nil and self.m_pEquipdata.m_id > 0 then
         self.m_oldLv = self.m_pEquipdata.m_stoneLevel 
         self.m_olduid =  self.m_pEquipdata.m_uid
         if self.m_changeType > 0 then     
             for i=1,#self.m_pEquipdata.m_addTypes do
                 if self.m_pEquipdata.m_addTypes[i] == self.m_changeType then
                     self.m_oldValue = self.m_pEquipdata.m_addValues[i]
                     self.m_addInd = i
                     break
                 end
             end  
         end    
    end
    self.m_pEquipdata = Utils:deepCopy(userData[1])
    if self.m_pEquipdata == nil or self.m_pEquipdata.m_id < 1 then 
        return
    end

    self.m_petId = userData[2] or 0   
    self.m_starCfgData = LDataConstMgr:GetPetEquipStarCfgData(self.m_pEquipdata.m_star)
    if self.m_changeType == 0 then
       self:ShowInfo()
       if self.m_oldLv == nil or self.m_olduid ~= self.m_pEquipdata.m_uid then
           self:RefreshIcon()
       end
    elseif self.m_addInd > 0 then
       self:RefreshInfo()
       local valueLabel =  self["m_addAttrVal"..self.m_addInd]
       self:ShowValueEffect(valueLabel)
       --self:ShowAttrInfo()
    else
       self:RefreshInfo()
       self:ShowAttrInfo()
       local addAttr = self["m_addAttrName"..#self.m_pEquipdata.m_addTypes]
       self:ShowAddEffect(addAttr)
    end
    if self.m_oldLv ~= nil and self.m_olduid == self.m_pEquipdata.m_uid then
        self:ShowIconEffect()
    end
end

function PetEquipStrengthenUI:InitData()
    local panel = self.m_pUILayer:getChildByName("Node"):getChildByName("Bg")
    --装备图标
    local equipPanel = panel:getChildByName("EquipBg")
    self.m_iconPanel = equipPanel:getChildByName("IconBg")
    self.m_nameLabel = self.m_iconPanel:getChildByName("Name")
	self.m_staressenceLabel1 = equipPanel:getChildByName("ConsumeBg_1"):getChildByName("Value")
	self.m_staressenceLabel2 = equipPanel:getChildByName("HaveBg_1"):getChildByName("Value")
    self.m_moneyLabel1 = equipPanel:getChildByName("ConsumeBg"):getChildByName("Value")
    self.m_moneyLabel2 = equipPanel:getChildByName("HaveBg"):getChildByName("Value")

    --装备属性
    local infoPanel = panel:getChildByName("DescBg")
    local baseAttrPanel = infoPanel:getChildByName("BaseAttribute")
    self.m_baseAttrName = baseAttrPanel:getChildByName("Atrribute_1")
    self.m_baseAttrValue = self.m_baseAttrName:getChildByName("Value")
    self.m_StoneAttrValue = self.m_baseAttrName:getChildByName("AddValue")
    local addAttrPanel = infoPanel:getChildByName("AddAttribute")
    for i=1,4 do
        self["m_addAttrName"..i] = addAttrPanel:getChildByName("Atrribute_"..i)
        self["m_addAttrVal"..i] = self["m_addAttrName"..i]:getChildByName("Value")
    end
    self.m_descLabel = infoPanel:getChildByName("Desc"):getChildByName("Atrribute_1")
    self.m_strengthenBtn = infoPanel:getChildByName("StrongBtn")
    self.m_closeBtn = panel:getChildByName("CloseBtn")
    self.m_leftBtn = self.m_pUILayer:getChildByName("Node"):getChildByName("Button_L")
    self.m_rightBtn = self.m_pUILayer:getChildByName("Node"):getChildByName("Button_R")

    self.m_equipIcon = ItemCellUI:New(self.m_iconPanel,itemValue)
    self.m_scheduleId = 0
    self.m_oldInd = 0
end

function PetEquipStrengthenUI:InitEvt()
    local function StrengthenCallback(sender)
        if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SJEQUIPQH) then
            return
        end
        if self.m_pEquipdata == nil or self.m_pEquipdata.m_uid == nil or self.m_pEquipdata.m_uid < 1 then
            return
        end
        if self.m_starCfgData ~= nil and self.m_pEquipdata.m_stoneLevel >=  self.m_starCfgData.maxStoneLv then
            Utils:ShowScrollTips(GUITips.RSI_PET_SUIT_TIPS12)
            return
        end
		if self.m_pbugXingxiu == true then
			Utils:ShowGoldTips(AppDef.AwrdItem.AWRD_ITEM_XINXIUJINHUA)
			return
		end
        if self.m_pbugGold == true then
			Utils:ShowGoldTips(AppDef.AwrdItem.AWRD_ITEM_COIN)
			return
		end
        LuaNetSendMsg:QueryPetEquip(4,self.m_pEquipdata.m_uid,self.m_petId)
    end
    self.m_strengthenBtn:addClickEventListener(StrengthenCallback)
	self:MarkIntaractCObj(self.m_strengthenBtn)
    local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Pet.PetEquipStrengthenUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    self.m_closeBtn:addClickEventListener(closeCallback)
	self:MarkIntaractCObj(self.m_closeBtn)
    local function leftCallback()
        self:GetLeftEquip()
    end
    self.m_leftBtn:addClickEventListener(leftCallback)
	self:MarkIntaractCObj(self.m_leftBtn)
    local function rightCallback()
        self:GetRightEquip()
    end
    self.m_rightBtn:addClickEventListener(rightCallback)
	self:MarkIntaractCObj(self.m_rightBtn)
end

function PetEquipStrengthenUI:ShowInfo()
    self:ShowEquipName()
    self:ShowAttrInfo()
    --self:RefreshIcon()
    self:ShowDesc()
	self:ShowStarEssence()
    self:ShowMoney()
    self:ShowBtn()
end

function PetEquipStrengthenUI:RefreshInfo()
    self:ShowEquipName()
    self:ShowDesc()
	self:ShowStarEssence()
    self:ShowMoney()
end

--[[
显示属性
]]
function PetEquipStrengthenUI:ShowAttrInfo()
    if self.m_pEquipdata == nil or self.m_pEquipdata.m_id < 1 then 
        return
    end
    --基础属性
    if #self.m_pEquipdata.m_baseTypes > 0 then
        local attrData = LDataConstMgr:GetAttrConfigData(self.m_pEquipdata.m_baseTypes[1])
        self.m_baseAttrName:setString(attrData.attrName)
        if self.m_pEquipdata.m_baseTypes[1] > AppDef.EAttrType.EAT_RESISIT_CRIT then
            self.m_baseAttrValue:setString(string.format("%.2f",self.m_pEquipdata.m_baseValues[1]/100).."%")
        else
            self.m_baseAttrValue:setString(self.m_pEquipdata.m_baseValues[1])
        end

		local stoneStr = ""
        local cfgData = LDataConstMgr:GetPetEquipQHCfgData(self.m_pEquipdata.m_stoneLevel)
        if cfgData ~= nil then
            local tempAttr = math.floor(self.m_pEquipdata.m_baseValues[1]*cfgData.upRatio/10000)
            if self.m_pEquipdata.m_baseTypes[1] > AppDef.EAttrType.EAT_RESISIT_CRIT then
                stoneStr = "+"..string.format("%.2f",tempAttr/100).."%"
            else
                stoneStr = "+"..tempAttr
            end
			self.m_baseAttrValue:removeAllChildren()
            local parentSize = self.m_baseAttrValue:getContentSize()
            self:AddSubLabel(self.m_baseAttrValue,stoneStr, AppDef.FNT_NAMEC, AppDef.UIFONTSIZETITLE, UICOLOR_GREEN_TIPS,cc.p(parentSize.width + 15, parentSize.height/2))
        end

        cfgData = LDataConstMgr:GetPetEquipQHCfgData(self.m_pEquipdata.m_stoneLevel+1)
        if cfgData ~= nil then
            local tempAttr = math.floor(self.m_pEquipdata.m_baseValues[1]*cfgData.upRatio/10000)
            if self.m_pEquipdata.m_baseTypes[1] > AppDef.EAttrType.EAT_RESISIT_CRIT then
                self.m_StoneAttrValue:setString("+"..string.format("%.2f",tempAttr/100).."%")
            else
                self.m_StoneAttrValue:setString("+"..tempAttr)
            end
        else
            self.m_StoneAttrValue:setString("")
        end
    end

    --附加属性（含强化属性）
    local num = #self.m_pEquipdata.m_addTypes
    if num > 4 then num = 4 end
    for i=1,num do
        local attrType = self.m_pEquipdata.m_addTypes[i]
        local attrVal = self.m_pEquipdata.m_addValues[i]
        local strName = ""
        local strValues = ""
        
        strName = LDataConstMgr:GetItemAttrName(attrType)
        if attrType > AppDef.EAttrType.EAT_RESISIT_CRIT then
            strValues = string.format("%.2f", attrVal / 100) .. "%"
        else
            strValues = attrVal
        end
        
        self["m_addAttrName"..i]:setString(strName)
        self["m_addAttrVal"..i]:setString(strValues)
        self["m_addAttrVal"..i]:setScale(1)
    end
    for i=num+1,4 do
        self["m_addAttrName"..i]:setString("")
        self["m_addAttrVal"..i]:setString("")
    end
end

function PetEquipStrengthenUI:AddSubLabel(parent, str,fontname,fontsize,color, pos)
    local label = ccui.Text:create(str,fontname,fontsize)
    label:setAnchorPoint(cc.p(0, 0.5))
    label:setColor(color)
    parent:addChild(label)
    label:setPosition(pos)
    return label
end
--[[
显示 装备名称
]]
function PetEquipStrengthenUI:ShowEquipName()
    local cfgData = LDataConstMgr:GetPetEquipCfgData(self.m_pEquipdata.m_id)
    if cfgData == nil then return end
    self.m_nameLabel:setString(cfgData.name)
    local color = AppDef:GetPetQualityColor(cfgData.quality)
    self.m_nameLabel:setTextColor(color)
    self.m_nameLabel:enableShadow()
end

--[[
显示 装备Icon
]]
function PetEquipStrengthenUI:RefreshIcon()
    local resFile = string.format("item/%s.png", self.m_pEquipdata.m_pic)
    local userDefine ={picFilePath = resFile,quality = self.m_pEquipdata.m_quality, star =self.m_pEquipdata.m_star, strengthenLv = self.m_pEquipdata.m_stoneLevel,suitId =  self.m_pEquipdata.m_suitType}
    local itemValue = {}
    itemValue.userDefine = userDefine
    if self.m_equipIcon ~= nil then
        self.m_equipIcon:UpdateItem(itemValue)
    end
end

--显示强化描述
function PetEquipStrengthenUI:ShowDesc()
    local param = LDataConstMgr:GetPetEquipQHStrParam(self.m_pEquipdata.m_stoneLevel)
    if param == 0 then 
        self.m_descLabel:setString("")
        return
    end
    local str = string.format(GUITips.RSI_PET_SUIT_TIPS8,param)
    self.m_descLabel:setString(str)
end

--显示星宿精华
function PetEquipStrengthenUI:ShowStarEssence()
    local staressence = LRoleDataMgr.MyHeroInfo:GetDetailData().xinXiuJingHua or 0
    self.m_staressenceLabel2:setString(staressence)
    if self.m_starCfgData == nil or self.m_pEquipdata.m_stoneLevel >= self.m_starCfgData.maxStoneLv  then
        self.m_staressenceLabel1:setString("")
        return
    end
    local cfgData = LDataConstMgr:GetPetEquipQHCfgData(self.m_pEquipdata.m_stoneLevel+1)
    if cfgData ~= nil then
        local cost = math.floor(cfgData.costStarVal*self.m_starCfgData.costRatio/10000)
        self.m_staressenceLabel1:setString(cost)
        local color = AppDef.UIColor.WHITE
		self.m_pbugXingxiu = false
        if staressence < cost then
            color = AppDef.UIColor.RED
			self.m_pbugXingxiu = true
        end
        self.m_staressenceLabel1:setTextColor(color)
    else
        self.m_staressenceLabel1:setString("")
    end
end

--显示金钱
function PetEquipStrengthenUI:ShowMoney()
    local money = LRoleDataMgr.MyHeroInfo:GetDetailData().Money or 0
    self.m_moneyLabel2:setString(money)
    if self.m_starCfgData == nil or self.m_pEquipdata.m_stoneLevel >= self.m_starCfgData.maxStoneLv  then
        self.m_moneyLabel1:setString("")
        return
    end
    local cfgData = LDataConstMgr:GetPetEquipQHCfgData(self.m_pEquipdata.m_stoneLevel+1)
    if cfgData ~= nil then
        local cost = math.floor(cfgData.costMoneyVal*self.m_starCfgData.costRatio/10000)
        self.m_moneyLabel1:setString(cost)
        local color = AppDef.UIColor.WHITE
		self.m_pbugGold = false
        if money < cost then
            color = AppDef.UIColor.RED
			self.m_pbugGold = true
        end
        self.m_moneyLabel1:setTextColor(color)
    else
        self.m_moneyLabel1:setString("")
    end
end

--属性变化特效显示
function PetEquipStrengthenUI:ShowValueEffect(sender)
    local function showEnd(sender1)
        sender1:setScale(1)
        self.m_scheduleId = 0
        self.m_oldInd = 0
        self:ShowAttrInfo()
        --sender1:setAnchorPoint(cc.p(0,0.5))
    end
    local function numChange(count)
        --
        local sender1 =  self["m_addAttrVal"..self.m_addInd]
        if sender1 == nil then return end
        local number = self.m_pEquipdata.m_addValues[self.m_addInd] - self.m_oldValue
        if  number >= 100 then
            self.m_oldValue = self.m_oldValue + 100
        elseif  number >= 10 then
            self.m_oldValue = self.m_oldValue + 10
        else
            self.m_oldValue = self.m_oldValue + 1
        end
        if self.m_changeType > AppDef.EAttrType.EAT_RESISIT_CRIT then
            sender1:setString("+"..string.format("%.2f",self.m_oldValue/100).."%")
        else
            sender1:setString("+"..self.m_oldValue)
        end       
        if self.m_oldValue >= self.m_pEquipdata.m_addValues[self.m_addInd] then
            Utils:unschedule(nil, self.m_scheduleId)
            local actions = {}
            local scaleto = cc.ScaleTo:create(0.3,2)
            table.insert(actions, scaleto)
            local func = cc.CallFunc:create(showEnd)
            table.insert(actions, func)
            sender1:stopAllActions()
            sender1:runAction(cc.Sequence:create(actions)) 
        end
    end
    local function scaleEnd(sender1)
        self.m_scheduleId = Utils:schedule(nil, numChange, 0.1)
    end

    if sender == nil or self.m_oldValue == 0 or self.m_changeType == 0 or self.m_addInd == 0 then return end
    --sender:setAnchorPoint(cc.p(0.5,0.5))
    if self.m_oldInd ~= self.m_addInd then
        local sender2 =  self["m_addAttrVal"..self.m_oldInd]
        if sender2 ~= nil then
            sender2:setScale(1)
        end
    end
    if self.m_scheduleId > 0 then
        Utils:unschedule(nil, self.m_scheduleId)
    end
    local actions = {}
    local scaleto = cc.ScaleTo:create(0.2,2)
    table.insert(actions, scaleto)
    local func = cc.CallFunc:create(scaleEnd)
    table.insert(actions, func)
    sender:stopAllActions()
    sender:runAction(cc.Sequence:create(actions)) 
    self.m_oldInd = self.m_addInd   
end

--属性增加特效显示
function PetEquipStrengthenUI:ShowAddEffect(sender)
    local function showEnd(sender1)
        --sender1:setAnchorPoint(cc.p(0,0.5))
    end

    if sender == nil or self.m_changeType == 0 then return end
    --sender:setAnchorPoint(cc.p(0.5,0.5))
    sender:setScale(2)

    local actions = {}
    local scaleto = cc.ScaleTo:create(0.3,1)
    table.insert(actions, scaleto)
    --local func = cc.CallFunc:create(showEnd)
    --table.insert(actions, func)
    sender:stopAllActions()
    sender:runAction(cc.Sequence:create(actions))    
end

--Icon特效显示
function PetEquipStrengthenUI:ShowIconEffect()
    local function showEnd(sender)
        self:RefreshIcon()
        self.m_imod:removeFromParent()
        self.m_imod = nil
    end

    if self.m_imod ~= nil then
        self.m_imod:removeFromParent()
    end
    local size = self.m_iconPanel:getContentSize()
    self.m_imod = Utils:CreateImod("res2/fx/pet_equip_qh",cc.p(size.width/2,size.height/2),self.m_iconPanel,1)
    self.m_imod:PlayAction(0)
    local actions = {}
    local delay = cc.DelayTime:create(1)
    table.insert(actions, delay)
    local func = cc.CallFunc:create(showEnd)
    table.insert(actions, func)
    self.m_iconPanel:stopAllActions()
    self.m_iconPanel:runAction(cc.Sequence:create(actions))    
end

function PetEquipStrengthenUI:ShowBtn()
    if self.m_pEquipdata == nil then return end
    if self.m_petId > 0 then
        --装备栏
        local info = LRoleDataMgr.Pet:GetPetById(self.m_petId)
        if info == nil then return end
        if self.m_pEquipdata.m_wpos == 1 then
            self.m_leftBtn:setVisible(false)
        elseif self.m_pEquipdata.m_wpos == AppDef.Pet.MaxEquipPosNum then
            self.m_rightBtn:setVisible(false)
        end
        for i=1,self.m_pEquipdata.m_wpos-1 do
            local equip = info.petEquips[i]
            if equip ~= nil and equip.m_uid > 0 then
                self.m_leftBtn:setVisible(true)
                break
            end
        end
        for i=self.m_pEquipdata.m_wpos+1,AppDef.Pet.MaxEquipPosNum do
            local equip = info.petEquips[i]
            if equip ~= nil and equip.m_uid > 0 then
                self.m_rightBtn:setVisible(true)
                break
            end
        end
        return
    end
    --背包
    if self.m_bagInfo == nil then
        self.m_bagInfo = LRoleDataMgr:GetPetEquipBagInfo(self.m_pEquipdata.m_suitType,0,false) 
        if self.m_bagInfo == nil then  self.m_bagInfo = {} end
    end
    local num = #self.m_bagInfo
    if num < 1 then return end
    self.m_leftBtn:setVisible(true)
    self.m_rightBtn:setVisible(true)

    if self.m_bagInfo[1].m_uid == self.m_pEquipdata.m_uid  then
        self.m_leftBtn:setVisible(false)
    end
    if self.m_bagInfo[num].m_uid == self.m_pEquipdata.m_uid then
        self.m_rightBtn:setVisible(false)
    end
end

function PetEquipStrengthenUI:GetLeftEquip()
    if self.m_pEquipdata == nil then return end
    if self.m_petId > 0 then
        local info = LRoleDataMgr.Pet:GetPetById(self.m_petId)
        if info == nil then return end
        local pos = 0
        for i=self.m_pEquipdata.m_wpos-1,1,-1 do
            local equip = info.petEquips[i]
            if equip ~= nil and equip.m_uid > 0 then
                pos = i
                break
            end
        end 
        if pos == 0 then return end
        local value = {info.petEquips[pos],self.m_petId}
        self:setEquipData(value)
        return
    end
    self:GetBagNextEquip(false)
end

function PetEquipStrengthenUI:GetRightEquip()
    if self.m_pEquipdata == nil then return end
    if self.m_petId > 0 then
        local info = LRoleDataMgr.Pet:GetPetById(self.m_petId)
        if info == nil then return end
        local pos = 0
        for i=self.m_pEquipdata.m_wpos+1,AppDef.Pet.MaxEquipPosNum do
            local equip = info.petEquips[i]
            if equip ~= nil and equip.m_uid > 0 then
                pos = i
                break
            end
        end 
        if pos == 0 then return end
        local value = {info.petEquips[pos],self.m_petId}
        self:setEquipData(value)
        return
    end
    self:GetBagNextEquip(true)
end

function PetEquipStrengthenUI:GetBagNextEquip(isNext)
    if self.m_pEquipdata == nil then return end
    if self.m_bagInfo == nil then
        self.m_bagInfo = LRoleDataMgr:GetPetEquipBagInfo(self.m_pEquipdata.m_suitType,0,false) 
        if self.m_bagInfo == nil then  self.m_bagInfo = {} end
    end
    local num = #self.m_bagInfo
    local pos = 0
    for i=1,num do
       if self.m_pEquipdata.m_uid == self.m_bagInfo[i].m_uid then
           pos = i
           break
       end
    end
    if pos == 0 then return end
    
    if isNext then
        pos = pos +1
    else
        pos = pos -1
    end
    if pos == 0 or pos > num then return end
    local equipData = self.m_bagInfo[pos]
    if equipData == nil then return end
    local value = {equipData,0}
    self:setEquipData(value)
end

function PetEquipStrengthenUI:RegistMsgs()
    self.msgIds = 
    {
        LUIPetEvent.PetEquipStrengthenSuc,
    }
    self:RegistSelf(self, self.msgIds)
end

function PetEquipStrengthenUI:ProcessEvent(msg)
    if msg.msgId == LUIPetEvent.PetEquipStrengthenSuc then
        self:setEquipData(msg.value)
    end
end

return PetEquipStrengthenUI