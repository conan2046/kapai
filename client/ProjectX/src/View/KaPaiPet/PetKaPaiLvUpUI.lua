
local PetKaPaiLvUpUI = LUIBase:New()
PetKaPaiLvUpUI.__index = PetKaPaiLvUpUI
--local this = LTcpSocket
function PetKaPaiLvUpUI:New()
	local o = LUIBase:New()
	setmetatable(o,PetKaPaiLvUpUI)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function PetKaPaiLvUpUI:RegistMsgs()
    self.msgIds = 
    {
        LUIKaPaiPetEvent.updatePetLvUp,
        LUIRedDotEvent.UpdateRedDotState,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function PetKaPaiLvUpUI:ProcessEvent(msg)
    if msg.msgId == LUIKaPaiPetEvent.updatePetLvUp then
        self._useItemList = msg.value
    elseif msg.msgId == LUIRedDotEvent.UpdateRedDotState then
        self:updateRedDot(msg.value)
    end
end

function PetKaPaiLvUpUI:Init()

    self.m_pUILayer = cc.CSLoader:createNode("csd/shenjiangyangcheng/yingxiongshuxingLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:initControlUI()

    self.m_pCurMatBtnTouched = 0--当前材料按钮触摸的下标
    self.m_bIsAutoUpgrade = false
    self.m_strUpgradeTips = nil--升级提示
    self.m_upgradeUseItemNum = 0--总共使用的多少道具
    self.m_upgradeBeforeUseItemNum = 0--使用之前记录道具的初始数量

    self:RegisterGuide()
end

function PetKaPaiLvUpUI:ShowUseItemTips( ... )
    -- body
    if self._useItemList == nil then
        return
    end
    -- dump(self._useItemList, "ShowUseItemTips ===>")
    local strFirst =""
    local totalExp = 0
    for i=1, #self._useItemList do
        local citem = LDataConstMgr:getCItemByID(self._useItemList[i].itemId)
        strFirst = strFirst .. string.format(GUITips.UI_Pet_LvUp_Cost_Tips3, self._useItemList[i].itemNum, citem.name)
        totalExp = totalExp + citem.sub_value[1][2] * self._useItemList[i].itemNum
    end

    local strSecend = string.format(GUITips.UI_Pet_LvUp_Cost_Tips4, totalExp)

    local msg = strFirst .. strSecend

    LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, msg)
    self:SendMsg(LGameMsg.m_scrollTipsMsg)

    self._useItemList = nil
end

function PetKaPaiLvUpUI:UpdateData( petData )
    -- body
    if petData == nil then
        return
    end
    -- dump(petData, "UpdateData ===========>")
    self.m_pPetData = petData
    self._beforeLevel = petData.level
    self:updateUI()
    self:ShowUseItemTips()
    Utils:CheckGuide(GuideDef.StepId.Guide_Pet1_5,true)
end

function PetKaPaiLvUpUI:initControlUI( ... )
    -- body

    -- LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.UI_Shengjiang_Btn_LvUp)
    -- self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local shenjiangInfoUI = self.m_pUILayer:getChildByName("shenjiangInfoUI")
    -- local chongwugaiming = shenjiangInfoUI:getChildByName("chongwugaiming")
    -- chongwugaiming:setVisible(false)

    local show = shenjiangInfoUI:getChildByName("Show")

    local Info = shenjiangInfoUI:getChildByName("Info")
    -----------------------------------------------------------------------
    self._manjiHideNodeArr = {}

    local jichu = Info:getChildByName("jichu")

    local jiantou = jichu:getChildByName("jiantou")
    table.insert(self._manjiHideNodeArr, jiantou)

    self._levelStr = jichu:getChildByName("Level_1")
    self._nextLvStr = jichu:getChildByName("Level_2")

    local Attribute1 = jichu:getChildByName("Attribute_1")
    self._AttributeAtk = Attribute1
    self._curAtk = Attribute1:getChildByName("Value_1")
    self._nextAtk = Attribute1:getChildByName("Value_2")
    self._addAtk = Attribute1:getChildByName("Value_3")

    table.insert(self._manjiHideNodeArr, self._nextAtk)
    table.insert(self._manjiHideNodeArr, self._addAtk)
    table.insert(self._manjiHideNodeArr, Attribute1:getChildByName("Image"))

    local Attribute2 = jichu:getChildByName("Attribute_2")
    self._AttributeDef = Attribute2
    self._curDef = Attribute2:getChildByName("Value_1")
    self._nextDef = Attribute2:getChildByName("Value_2")
    self._addDef = Attribute2:getChildByName("Value_3")
    table.insert(self._manjiHideNodeArr, self._nextDef)
    table.insert(self._manjiHideNodeArr, self._addDef)
    table.insert(self._manjiHideNodeArr, Attribute2:getChildByName("Image"))

    local Attribute3 = jichu:getChildByName("Attribute_3")
    self._AttributeFaFang = Attribute3
    self._curFaFang = Attribute3:getChildByName("Value_1")
    self._nextFaFang = Attribute3:getChildByName("Value_2")
    self._addFaFang = Attribute3:getChildByName("Value_3")

    table.insert(self._manjiHideNodeArr, self._nextFaFang)
    table.insert(self._manjiHideNodeArr, self._addFaFang)
    table.insert(self._manjiHideNodeArr, Attribute3:getChildByName("Image"))

    local Attribute4 = jichu:getChildByName("Attribute_4")
    self._AttributeHp = Attribute4
    self._curHp = Attribute4:getChildByName("Value_1")
    self._nextHp = Attribute4:getChildByName("Value_2")
    self._addHp = Attribute4:getChildByName("Value_3")

    table.insert(self._manjiHideNodeArr, self._nextHp)
    table.insert(self._manjiHideNodeArr, self._addHp)
    table.insert(self._manjiHideNodeArr, Attribute4:getChildByName("Image"))

    ------------------------------------------------------------------------
    local cailiao = Info:getChildByName("cailiao")
    self._cailiao = cailiao
    self._lvValue = cailiao:getChildByName("Level"):getChildByName("Value")
    self._ExpBar = cailiao:getChildByName("bg_Bar"):getChildByName("ExpBar")
    self._expValue = cailiao:getChildByName("bg_Bar"):getChildByName("Value")
    self._MaxLevel = cailiao:getChildByName("Tips"):getChildByName("value")

    self.m_pMatBtns = {}
    for i=1, 4 do
        local btn_Item = cailiao:getChildByName("btn_Item_"..i)
        btn_Item:addTouchEventListener(handler(self, PetKaPaiLvUpUI.UpgradeBtnClicked))
        btn_Item:setTag(i)
        self:MarkIntaractCObj(btn_Item)
        table.insert(self.m_pMatBtns, btn_Item)
    end

    local btn_yjShengji = cailiao:getChildByName("btn_yjShengji")
    self._btn_yjShengji = btn_yjShengji
    btn_yjShengji:addClickEventListener(function( sender )
        -- body
        --一键升级

        if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_KAPAI_SJJINENG_EXTRA) then
            return
        end

        if self.m_pPetData.level >= LRoleDataMgr.MyHeroInfo.level then
            Utils:ShowScrollTips(GUITips.RSI_GS_TIP17)
            return
        end

        print("PetKaPaiLvUpUI:initControlUI 111111111111111111111111===>")

        Utils:InitUI("KaPaiPet.PetOneKeyLvUpUI", AppDef.UIType.PopWindow, self.m_pPetData)
    end)

    local btn_shengji = cailiao:getChildByName("btn_shengji")
    self._btn_shengji = btn_shengji
    btn_shengji:addClickEventListener(function ( sender )
        -- body
        --升级
        if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_KAPAI_SJJINENG) then
            return
        end

        if self.m_pPetData.level >= LRoleDataMgr.MyHeroInfo.level then
            Utils:ShowScrollTips(GUITips.RSI_GS_TIP17)
            return
        end

        local toLevel = 1 + self.m_pPetData.level
        if toLevel > LRoleDataMgr.MyHeroInfo.level then
            toLevel = LRoleDataMgr.MyHeroInfo.level
        end

        local itemList, itemExp = PetkaPaiManager:getPetLevelUpData(self.m_pPetData, toLevel)
        local resultLevel = PetkaPaiManager:getCanToLvByExp(self.m_pPetData, itemExp)

        -- dump(itemList, "initControlUI 1111 ===>")
        

        if resultLevel <= 0 or #itemList < 1  then
            Utils:ShowScrollTips(GUITips.UI_QiRi_Shop_tips19)
            return
        end
        toLevel =  resultLevel + self.m_pPetData.level
        self._useItemList = itemList
        LuaNetSendMsg:QueryOneKeyPetLvUp(self.m_pPetData.id, toLevel, itemList)
    end)
    ------------------------------------------------------------------------------------
    self._manji = Info:getChildByName("manji")


end

function PetKaPaiLvUpUI:getCurPetIsShowRed( ... )
    -- body
    local isCanLvUp = PetkaPaiManager:getPetCanLevelUp(self.m_pPetData)
    return isCanLvUp
end

function PetKaPaiLvUpUI:showLevelNode(isShow)
    for i=1, #self._manjiHideNodeArr do
        self._manjiHideNodeArr[i]:setVisible(isShow)
    end
end

function PetKaPaiLvUpUI:updateUI( ... )
    -- body
    --红点
    self:updateRedDot()

    local curAtk = self.m_pPetData.attrs[AppDef.EAttrType.EAT_ATTACK]
    self._curAtk:setString(curAtk)
    local attrData = LDataConstMgr:GetAttrConfigData(attyType)
    self._AttributeAtk:setString(AppDef.EAttrTypeName[AppDef.EAttrType.EAT_ATTACK])

    local curHp = self.m_pPetData.attrs[AppDef.EAttrType.EAT_HP]
    self._curHp:setString(curHp)
    self._AttributeHp:setString(AppDef.EAttrTypeName[AppDef.EAttrType.EAT_HP])

    local curDef = self.m_pPetData.attrs[AppDef.EAttrType.EAT_DEFENSE]
    self._curDef:setString(curDef)
    self._AttributeDef:setString(AppDef.EAttrTypeName[AppDef.EAttrType.EAT_DEFENSE])

    local curFaFang = self.m_pPetData.attrs[AppDef.EAttrType.EAT_MAGICD_EFENSE]
    self._curFaFang:setString(curFaFang)
    self._AttributeFaFang:setString(AppDef.EAttrTypeName[AppDef.EAttrType.EAT_MAGICD_EFENSE])

    if self.m_pPetData.level < AppDef.Pet.MaxLevel then
        self:showLevelNode(true)
        self._cailiao:setVisible(true)
        self._manji:setVisible(false)


        self._levelStr:setString(tostring(self.m_pPetData.level) .. "级")
        self._nextLvStr:setString(tostring(self.m_pPetData.level + 1) .. "级")

        local addLevel = self.m_pPetData.level - self._beforeLevel
        if addLevel <= 0 then
            addLevel = 1
        end
        -- local growAttr = LDataConstMgr:GetPetGrowAttr(self.m_pPetData.id, self.m_pPetData.star)
        local growAttr = PetkaPaiManager:GetPetLvGrowAttr(self.m_pPetData.id, self.m_pPetData.star)
        local addAtk = 0 
        local addHp = 0
        local addDef = 0 
        local addFaFang = 0

        if growAttr ~= nil then
            addAtk = growAttr[1] * addLevel 
            addDef = growAttr[2] * addLevel 
            addFaFang = growAttr[3] * addLevel
            addHp = growAttr[4] * addLevel
        end

        self._addAtk:setString(addAtk)
        self._addDef:setString(addDef)
        self._addHp:setString(addHp)
        self._addFaFang:setString(addFaFang)

        self._nextAtk:setString(addAtk + curAtk)
        self._nextHp:setString(addHp + curHp)
        self._nextDef:setString(addDef + curDef)
        self._nextFaFang:setString(addFaFang + curFaFang)

        self._lvValue:setString(self.m_pPetData.level)
        local configData = JsonConfig.m_petLvUpExp.getDefByID(self.m_pPetData.level)
        self._expValue:setString(string.format("%d/%d", self.m_pPetData.exp, configData.exp_hero))
        local rate = self.m_pPetData.exp / configData.exp_hero
        self._ExpBar:setPercent(rate * 100)

        for i=1, #self.m_pMatBtns do
            local id = LRoleDataMgr.upgradeItems[i]
            local itemNum = LRoleDataMgr.Equip:CountItemNumById(id)
            local info = self.m_pMatBtns[i]
            Utils:GetItemCellValue(info, 0, id, true, true, itemNum, nil, itemNum <= 0, true)
            info:getChildByName("Value"):setVisible(false)
            local Text = info:getChildByName("Text")
            local itemConfigData = JsonConfig.m_Item.getDefByID(id)
            -- dump(itemConfigData.sub_value," updateUI ==============>")
            Text:setString(string.format(GUITips.RSI_ZQX_HERO_LV_UP, itemConfigData.sub_value[1][2]))
        end

        self._MaxLevel:setString( string.format("%d", LRoleDataMgr.MyHeroInfo.level))
    else
        --满级了

        self._levelStr:setString(tostring(self.m_pPetData.level) .. "级")
        self._nextLvStr:setVisible(false)

        self:showLevelNode(false)
        self._cailiao:setVisible(false)
        self._manji:setVisible(true)
    end

end

function PetKaPaiLvUpUI:UpgradeBtnClicked(pTouch, pEvent)   
    local ind = pTouch:getTag()
    -- if self.m_pCurMatBtnTouched == ind and pEvent == ccui.TouchEventType.ended then
    --     if self.m_bIsAutoUpgrade == true then
    --         self:MatBtnTouchEnd(ind)
    --     else
    --         self:MatBtnTouchBegan(ind)
    --     end
    -- elseif self.m_pCurMatBtnTouched ~= ind and pEvent == ccui.TouchEventType.ended then
    --     if self.m_bIsAutoUpgrade == true then
    --         self:MatBtnTouchEnd(self.m_pCurMatBtnTouched)
    --     end
    --     self:UpdateImageSelect(pTouch)
    --     self:MatBtnTouchBegan(ind)
    -- end

    if pEvent == ccui.TouchEventType.began then
       local ind = pTouch:getTag()
       self:MatBtnTouchBegan(ind)
    elseif pEvent == ccui.TouchEventType.ended then
       self:MatBtnTouchEnd(ind)    
    end
end

function PetKaPaiLvUpUI:UpdateImageSelect(parent)
    -- self.m_imageSelect:retain()
    -- self.m_imageSelect:removeFromParent();

    -- parent:addChild(self.m_imageSelect)
    -- self.m_imageSelect:release()
    -- parent:getChildByName("RedDot"):setLocalZOrder(1)
    -- self.m_imageSelect:setPosition(cc.p(44.0, 44.0))
    -- self.m_imageSelect:setVisible(true)
end

function PetKaPaiLvUpUI:MatBtnTouchBegan(ind)
    self.m_upgradeUseItemNum = 0
    if self.m_pCurMatBtnTouched > 0 then
        -- self.m_imageSelect:setVisible(true)
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
            -- self.m_imageSelect:setVisible(false)
            self.m_pMatBtns[self.m_pCurMatBtnTouched]:stopAllActions()
        end
        
    end
    local delayTime = cc.DelayTime:create(0.3)
    local func = cc.CallFunc:create(handler(self,PetKaPaiLvUpUI.AutoUseItem))
    local eq = cc.Sequence:create(delayTime, func)
    self.m_pMatBtns[self.m_pCurMatBtnTouched]:runAction(eq)
end


function PetKaPaiLvUpUI:MatBtnTouchEnd()
    print("PetKaPaiLvUpUI:MatBtnTouchEnd ===>", self.m_pCurMatBtnTouched)
    if self.m_pCurMatBtnTouched > 0 then
        self.m_upgradeBeforeUseItemNum = 0
        self.m_pMatBtns[self.m_pCurMatBtnTouched]:stopAllActions()
    end

    print("PetKaPaiLvUpUI:MatBtnTouchEnd ===> ", self.m_bIsAutoUpgrade)
    if self.m_bIsAutoUpgrade then
        --已经处于长按自动使用状态就返回
        if self.m_upgradeUseItemNum == 0 then
            return
        end
        local itemId = AppDef.Pet.UpgradsMats[self.m_pCurMatBtnTouched]
        local citem = LDataConstMgr:getCItemByID(itemId)
        if citem ~= nil then
            local msg = string.format(GUITips.UI_Pet_LvUp_Cost_Tips2,self.m_upgradeUseItemNum,
                                citem.name,
                                self.m_upgradeUseItemNum * citem.sub_value[1][2])
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
        end
        self.m_bIsAutoUpgrade = false
        return
    else
        --使用一次
        self:UseItemToUpgrade()
    end

    if self.m_upgradeUseItemNum <= 0 then
        return
    end
    local itemId = AppDef.Pet.UpgradsMats[self.m_pCurMatBtnTouched]
    local citem = LDataConstMgr:getCItemByID(itemId)
    if citem ~= nil then
        local msg = string.format(GUITips.UI_Pet_LvUp_Cost_Tips1,citem.name,citem.sub_value[1][2])
        print("citem.additionalValue ====>", citem.sub_value[1][2], itemId, msg)
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
        self:SendMsg(LGameMsg.m_scrollTipsMsg)
    end
    self.m_pCurMatBtnTouched = 0
    self.m_bIsAutoUpgrade = false
end

function PetKaPaiLvUpUI:AutoUseItem()
    local tmp = self.m_bIsAutoUpgrade
    local success = self:UseItemToUpgrade()
    if tmp == false and success == true then
        self.m_bIsAutoUpgrade = true
        local delayTime = cc.DelayTime:create(0.1)
        local func = cc.CallFunc:create(handler(self, PetKaPaiLvUpUI.AutoUseItem))
        local eq = cc.Sequence:create(delayTime, func)
        local rep = cc.RepeatForever:create(eq)
        self.m_pMatBtns[self.m_pCurMatBtnTouched]:runAction(rep)
    elseif tmp == true and success == false then
        self.m_pMatBtns[self.m_pCurMatBtnTouched]:stopAllActions()
    end
    if success == false then
        -- self.m_imageSelect:setVisible(false)
        self.m_upgradeBeforeUseItemNum = 0
        self.m_bIsAutoUpgrade = false
    end

end

--显示宠物经验丹小红点
function PetKaPaiLvUpUI:ShowMatRedDot() 
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

--[[
使用道具升级
]]
function PetKaPaiLvUpUI:UseItemToUpgrade()
    -- self:ShowMatRedDot()
    -- print("self.m_pPetData.level ====>", self.m_pPetData.level, LRoleDataMgr.MyHeroInfo.level)

    local itemId = AppDef.Pet.UpgradsMats[self.m_pCurMatBtnTouched]
    local itemNum = LRoleDataMgr.Equip:CountItemNumById(itemId)
    if itemNum <= 0 then
        return
    end

    if self.m_pPetData.level >= LRoleDataMgr.MyHeroInfo.level then
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.UI_Pet_LvUp_Tip1)
        self:SendMsg(LGameMsg.m_scrollTipsMsg)
        return false
    elseif self.m_pPetData.level >= AppDef.Pet.MaxLevel then
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.UI_Pet_LvUp_Tip2)
        self:SendMsg(LGameMsg.m_scrollTipsMsg)
        return false
    end
  
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
    print("self.m_upgradeUseItemNum ==", self.m_upgradeUseItemNum, math.ceil(costItemNum))
    LuaNetSendMsg:QueryPetLvUp(self.m_pPetData.id, itemId, math.ceil(costItemNum))
   -- self:ShowMatRedDot()
    return true
end

function PetKaPaiLvUpUI:onExit()
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep,GuideDef.StepId.Guide_Pet1_4)
    self.m_pUILayer = nil
    self:Destory()
end

function PetKaPaiLvUpUI:RegisterGuide()
    Utils:RegisterGuide(GuideDef.StepId.Guide_Pet1_4, self.m_pMatBtns[1], function()
        self.m_pCurMatBtnTouched = 1
        self:UseItemToUpgrade()
        self.m_upgradeBeforeUseItemNum = 0
        self.m_pCurMatBtnTouched = 0
    end, nil, true)
end

function PetKaPaiLvUpUI:updateRedDot(data)
    -- body
    if data then
        if data.id == RedDotDef.ID.ShenJiang_LVUp then
            self:setLvUpRedDot()
        end
    else
        self:setLvUpRedDot()
    end
end

function PetKaPaiLvUpUI:setLvUpRedDot( ... )
    -- body
    local isCanLvUp = self:getCurPetIsShowRed()
    Utils:SendMsg(LUIRedDotEvent.SetRedDotState, {id=RedDotDef.ID.ShenJiang_LVUp, isShow=isCanLvUp})
    self._btn_yjShengji:getChildByName("Prompt"):setVisible(isCanLvUp)
    self._btn_shengji:getChildByName("Prompt"):setVisible(isCanLvUp)

end

return PetKaPaiLvUpUI