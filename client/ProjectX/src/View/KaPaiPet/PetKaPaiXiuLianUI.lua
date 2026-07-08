
local PetKaPaiXiuLianUI = LUIBase:New()
PetKaPaiXiuLianUI.__index = PetKaPaiXiuLianUI
--local this = LTcpSocket
function PetKaPaiXiuLianUI:New()
	local o = LUIBase:New()
	setmetatable(o,PetKaPaiXiuLianUI)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function PetKaPaiXiuLianUI:RegistMsgs()
    self.msgIds = 
    {
        LUIRedDotEvent.UpdateRedDotState,
        LUIPetEvent.PetXLSuc,
        LUIPetEvent.PetJiHuoSuc,
        LUIKaPaiPetEvent.updatePetLvUp,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function PetKaPaiXiuLianUI:ProcessEvent(msg)
    if msg.msgId == LUIRedDotEvent.UpdateRedDotState then
        self:updateRedDot(msg.value)
    elseif msg.msgId == LUIPetEvent.PetXLSuc then
        self:reFrashData(msg.value)
        self:updateUI()
    elseif msg.msgId == LUIPetEvent.PetJiHuoSuc then
        self:reFrashJHData(msg.value)
        self:OpenTianMingJH(msg.value)
    elseif msg.msgId == LUIKaPaiPetEvent.updatePetLvUp then
        self:updateBtnState()
    end
end

function PetKaPaiXiuLianUI:Init()

    self.m_pUILayer = cc.CSLoader:createNode("csd/shenjiangyangcheng/yingxiongxiulian.csb")
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

    self.OldXlINfo = {}
    self:RegisterGuide()
end

function PetKaPaiXiuLianUI:ShowUseItemTips( ... )
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

function PetKaPaiXiuLianUI:UpdateData( petData )
    -- body
    if petData == nil then
        return
    end
    dump(petData.XLInfo, "UpdateData ===========>")
    self.m_pPetData = petData
    self._beforeLevel = petData.level
    self:updateUI()
    self:ShowUseItemTips()
end



function PetKaPaiXiuLianUI:OpenTianMingJH( xlData )
    -- body
    local function afterEffect( ... )
            -- body
        print("PetKaPaiXiuLianUI:CreatEffect 11111111111111111 ======>")
        xlData.unLockIM = true
        Utils:InitUI("KaPaiPet.PetXuLianSucMainUI", AppDef.UIType.PopFirstClassLayer, {openTab=1, xlData = xlData})
        --更新UI
        self:updateUI()
    end
    PetkaPaiManager:CreatEffect(self._effect, "effect_shenjiangyangcheng_5", 1.5, afterEffect)
end

function PetKaPaiXiuLianUI:reFrashData( data )
    -- body
    if data == nil then
        return
    end

    local addStrTips = ""
    for k,v in pairs(data) do
        local oldValue = self.OldXlINfo[k]
        self.m_pPetData.XLInfo[k] = v
        local addValue = (v - oldValue) * self._addAttrArr[k][2]
        if addValue > 0 then
            local attrName = Utils:getAttrName(k)
            addStrTips = addStrTips .. attrName .. "+" .. tostring(addValue)..","
        end
    end
    if string.len(addStrTips) > 0 then
        local tips = GUITips.RSI_XIULIAN_TIPS6 .. addStrTips
        Utils:ShowScrollTips(tips)
    end
    
end

function PetKaPaiXiuLianUI:reFrashJHData( data )
    -- body
    if data == nil then
        return
    end
    for k,v in pairs(data.xlInfo) do
        self.m_pPetData.XLInfo[k] = v
    end
    self.m_pPetData.XLLv = data.curXLLv
end

function PetKaPaiXiuLianUI:initControlUI( ... )
    -- body
    local shenjiangxiulian = self.m_pUILayer:getChildByName("shenjiangxiulian")
    local Info = shenjiangxiulian:getChildByName("Info")
    -----------------------------------------------------------------------
    self._manjiHideNodeArr = {}

    local jichu = Info:getChildByName("jichu")
    self._openTips = jichu:getChildByName("txt_5")
    self._openTips:setVisible(false)
    local attrTips = jichu:getChildByName("txt_4")
    self._attrTips = Utils:CreateColorText3(attrTips, true)

    self._extraTips = jichu:getChildByName("txt_3")
    self._tianMin = jichu:getChildByName("Image_bg") 
    self._attrArr = {}
    for i=1, 4 do
        local att = jichu:getChildByName("att_"..i)
        table.insert(self._attrArr, att)
    end

    local help = jichu:getChildByName("Button")
    help:addClickEventListener(function ( sender )
        -- body
        local xlData = {}
        xlData.curXLLv = self.m_pPetData.XLLv
        xlData.xlInfo = self.m_pPetData.XLInfo
        xlData.unLockIM = false
        Utils:InitUI("KaPaiPet.PetXuLianSucMainUI", AppDef.UIType.PopFirstClassLayer, {openTab=1, xlData = xlData})
    end)
    ------------------------------------------------------------------------
    local cailiao = Info:getChildByName("cailiao")
    self._cailiao = cailiao
    self._Item = cailiao:getChildByName("btn_Item_1")
    self._Item:addClickEventListener(function ( sender )
        -- body
        self:XiuLianEvent(1)
    end)

    self._btn_yjxl = cailiao:getChildByName("btn_yjxl")
    self._btn_yjxl:addClickEventListener(function ( sender )
        if not self:isXLOpen() then
            Utils:ShowScrollTips(GUITips.PET_XL_TIPS2)
            return
        end

        local itemNum = LRoleDataMgr.Equip:CountItemNumById(852)
        if itemNum < 1 then
            Utils:ShowScrollTips(GUITips.RSI_XIULIAN_TIPS7)
            return
        end

        --一键修炼
        local num = PetkaPaiManager:getMaxXiuLianNum(self.m_pPetData)
        print("PetKaPaiXiuLianUI:initControlUI num ==>", num)
        if num > 0 then
            self:XiuLianEvent(num)
        end
    end)

    self._btn_xl = cailiao:getChildByName("btn_xl")
    self._btn_xl:addClickEventListener(function ( sender )
        -- body

        local function NumInputCallback(num)
            --print("NumInputCallback",num)
            self:XiuLianEvent(num)
        end
        local maxNum = PetkaPaiManager:getMaxXiuLianNum(self.m_pPetData)

        if maxNum < 1 then
            Utils:ShowScrollTips(GUITips.RSI_XIULIAN_TIPS7)
            return
        end

        LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowNumInputUI, {maxNum,NumInputCallback})
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end)

    self._btn_dxl = cailiao:getChildByName("btn_dxl")
    self._effect = cailiao:getChildByName("effect_shenjiangyangcheng_5")
    self._btn_dxl:addClickEventListener(function ( sender )
        -- body
        if not self:isXLOpen() then
            Utils:ShowScrollTips(GUITips.PET_XL_TIPS2)
            return
        end
        --天命激活
        print("PetKaPaiXiuLianUI:initControlUI ========================>", self.m_pPetData.id)


        local minNum = LRoleDataMgr.Equip:CountItemNumById(853)
        local xiulian = JsonConfig.m_xiuLianConfig.getDefByID(self.m_pPetData.XLLv + 1)
        if xiulian == nil then
            return
        end
        if minNum < xiulian.cost_xiulian[1][3] then
            Utils:ShowScrollTips(GUITips.RSI_XIULIAN_TIPS5)
            return
        end

        LuaNetSendMsg:SendPetJiHuo(self.m_pPetData.id)
    end)

    ------------------------------------------------------------------------------------
    self._manji = Info:getChildByName("manji")


end

function PetKaPaiXiuLianUI:XiuLianEvent( num )
    -- body
    if num < 0 then
        return
    end

    if not self:isXLOpen() then
        Utils:ShowScrollTips(GUITips.PET_XL_TIPS2)
        return
    end

    local minNum = LRoleDataMgr.Equip:CountItemNumById(852)
    if minNum < num then
        Utils:ShowScrollTips(GUITips.RSI_XIULIAN_TIPS7)
        return
    end

    self.OldXlINfo = nil
    self.OldXlINfo = Utils:deepCopy(self.m_pPetData.XLInfo)
    --修炼
    LuaNetSendMsg:SendPetXiuLian(self.m_pPetData.id, num)
end

function PetKaPaiXiuLianUI:getCurPetIsShowRed( ... )
    -- body
    local isCanLvUp = PetkaPaiManager:getPetCanLevelUp(self.m_pPetData)
    return isCanLvUp
end

function PetKaPaiXiuLianUI:showLevelNode(isShow)
    for i=1, #self._manjiHideNodeArr do
        self._manjiHideNodeArr[i]:setVisible(isShow)
    end
end

function PetKaPaiXiuLianUI:updateUI( ... )
    -- body
    --红点
    self:updateRedDot()
    local level = self.m_pPetData.XLLv + 1
    local MaxLevel = #JsonConfig.m_xiuLianConfig.getList()
    local xiulian = JsonConfig.m_xiuLianConfig.getDefByID(level)
    if xiulian == nil then
        return
    end
    self._xiulian = xiulian
    local size = #xiulian.attr

    local addAttrStr = ""
    for i=1, 4 do
        local attrName = Utils:getAttrName(xiulian.attr[i][2])
        addAttrStr = addAttrStr .. attrName .. "、"
    end
    local addStr = "+%" .. (xiulian.attr[1][3]/ 100)
    addAttrStr = addAttrStr .. addStr
    self._extraTips:setString(addAttrStr)

    -- print("PetKaPaiXiuLianUI ===>", PetkaPaiManager:getXLAttrStr(self.m_pPetData), PetkaPaiManager:getXLExtraAttrStr(self.m_pPetData))
    
    if size > 4 then
        self._attrTips:setVisible(true)
        local attrStr = LDataConstMgr:GetHeroSkillDesc(xiulian.attr[5][2], 1)
        self._attrTips:setString(attrStr)
    else
        self._attrTips:setVisible(false)
    end

    --表没配置
    self._tianMin:getChildByName("txt_2"):setString(self._xiulian.name)

    local cfg = JsonConfig.m_config.getDefByID(23)
    local addAttrArr = json.decode("[".. cfg.value .. "]", 1)
    self._addAttrArr = addAttrArr
    -- dump(addAttrArr, "=======>")
    -- local XLTimesArr = {750, 750, 750, 750}
    local XLTimesArr = self.m_pPetData.XLInfo
    for i=1, #self._attrArr do
        local attr = self._attrArr[i]
        local bg_Bar = attr:getChildByName("bg_Bar")
        local ExpBar = bg_Bar:getChildByName("ExpBar")
        local XLTimes = XLTimesArr[i]
        local percent = XLTimes * 100 / xiulian.cost_type
        ExpBar:setPercent(percent)

        local barValue = bg_Bar:getChildByName("Value")
        local curStr = string.format("%d/%d", XLTimes * addAttrArr[i][2], xiulian.cost_type * addAttrArr[i][2])
        barValue:setString(curStr)

        local Value1 = attr:getChildByName("Value_1")

        if XLTimes == xiulian.cost_type then
            Value1:setVisible(false)
        else
            Value1:setVisible(true)
            Value1:setString(addAttrArr[i][2])
        end        
    end

    if level >= MaxLevel then
        self._manji:setVisible(true)
        self._cailiao:setVisible(false)
    else
        self._manji:setVisible(false)
        self._cailiao:setVisible(true)

        local itemIcon = self._Item:getChildByName("IconImage")
        itemIcon:removeAllChildren()
        -- itemIcon:setVisible(true)
        local Value_1 = self._Item:getChildByName("Value_1")

        local isMaxXL = self:isCurXLMAx(XLTimesArr)
        if isMaxXL then
            local id = xiulian.cost_xiulian[1][1]
            local num = LRoleDataMgr.Equip:CountItemNumById(id)
            Utils:GetItemCellValue(itemIcon, 0, id, true, false, 0, nil, false, true)
            Value_1:setVisible(true)
            local str = string.format("%d/%d", num, xiulian.cost_xiulian[1][3])
            Value_1:setString(str)
        else
            Value_1:setVisible(false)
            local id = 852
            local num = LRoleDataMgr.Equip:CountItemNumById(id)
            Utils:GetItemCellValue(itemIcon, 0, id, true, true, num, nil, false, true)
        end

        self._btn_yjxl:setVisible(not isMaxXL)
        self._btn_xl:setVisible(not isMaxXL)
        self._btn_dxl:setVisible(isMaxXL)

        self:updateBtnState()
    end
    
end

function PetKaPaiXiuLianUI:updateBtnState( ... )
    -- body
    if self:isXLOpen() then
        self._openTips:setVisible(false)

        self._btn_yjxl:setBright(true)
        self._btn_xl:setBright(true)
        self._btn_dxl:setBright(true)
    else
        self._openTips:setVisible(true)
        local tips = string.format(GUITips.PET_XL_TIPS1, self._xiulian.level_need)
        self._openTips:setString(tips)

        self._btn_yjxl:setBright(false)
        self._btn_xl:setBright(false)
        self._btn_dxl:setBright(false)
    end
end

function PetKaPaiXiuLianUI:isCurXLMAx( XLTimesArr )
    -- body
    if XLTimesArr == nil or #XLTimesArr < 4 then
        return false
    end
    for i=1, #XLTimesArr do
        if XLTimesArr[i] < self._xiulian.cost_type then
            return false
        end
    end
    return true
end

function PetKaPaiXiuLianUI:isXLOpen( ... )
    -- body
    return self.m_pPetData.level >= self._xiulian.level_need
end

function PetKaPaiXiuLianUI:UpgradeBtnClicked(pTouch, pEvent)
    local ind = pTouch:getTag()

    if pEvent == ccui.TouchEventType.began then
       local ind = pTouch:getTag()
       self:MatBtnTouchBegan(ind)
    elseif pEvent == ccui.TouchEventType.ended then
       self:MatBtnTouchEnd(ind)    
    end
end

function PetKaPaiXiuLianUI:UpdateImageSelect(parent)
    -- self.m_imageSelect:retain()
    -- self.m_imageSelect:removeFromParent();

    -- parent:addChild(self.m_imageSelect)
    -- self.m_imageSelect:release()
    -- parent:getChildByName("RedDot"):setLocalZOrder(1)
    -- self.m_imageSelect:setPosition(cc.p(44.0, 44.0))
    -- self.m_imageSelect:setVisible(true)
end

function PetKaPaiXiuLianUI:MatBtnTouchBegan(ind)
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
    local func = cc.CallFunc:create(handler(self,PetKaPaiXiuLianUI.AutoUseItem))
    local eq = cc.Sequence:create(delayTime, func)
    self.m_pMatBtns[self.m_pCurMatBtnTouched]:runAction(eq)
end


function PetKaPaiXiuLianUI:MatBtnTouchEnd()
    print("PetKaPaiXiuLianUI:MatBtnTouchEnd ===>", self.m_pCurMatBtnTouched)
    if self.m_pCurMatBtnTouched > 0 then
        self.m_upgradeBeforeUseItemNum = 0
        self.m_pMatBtns[self.m_pCurMatBtnTouched]:stopAllActions()
    end

    print("PetKaPaiXiuLianUI:MatBtnTouchEnd ===> ", self.m_bIsAutoUpgrade)
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

function PetKaPaiXiuLianUI:AutoUseItem()
    local tmp = self.m_bIsAutoUpgrade
    local success = self:UseItemToUpgrade()
    if tmp == false and success == true then
        self.m_bIsAutoUpgrade = true
        local delayTime = cc.DelayTime:create(0.1)
        local func = cc.CallFunc:create(handler(self, PetKaPaiXiuLianUI.AutoUseItem))
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
function PetKaPaiXiuLianUI:ShowMatRedDot() 
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
function PetKaPaiXiuLianUI:UseItemToUpgrade()
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

function PetKaPaiXiuLianUI:onExit()
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep,GuideDef.StepId.Guide_Pet1_4)
    self.m_pUILayer = nil
    self:Destory()
end

function PetKaPaiXiuLianUI:RegisterGuide()
end

function PetKaPaiXiuLianUI:updateRedDot(data)
    -- body
    if data then
        if data.id == RedDotDef.ID.ShenJiang_XiuLian then
            self:setLvUpRedDot()
        end
    else
        self:setLvUpRedDot()
    end
end

function PetKaPaiXiuLianUI:getCurPetIsShowRed( ... )
    -- body
    local isCanShow = PetkaPaiManager:isPetCanTianMingJH(self.m_pPetData)
    return isCanShow
end

function PetKaPaiXiuLianUI:setLvUpRedDot( ... )
    -- body
    local show = self:getCurPetIsShowRed()
    print("PetKaPaiXiuLianUI setLvUpRedDot == 111111111111111 > ", show)
    Utils:SendMsg(LUIRedDotEvent.SetRedDotState, {id=RedDotDef.ID.ShenJiang_XiuLian, isShow=show})
    self._btn_dxl:getChildByName("Prompt"):setVisible(show)
end

return PetKaPaiXiuLianUI