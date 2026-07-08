local LoginGiftUIPage = LUIBase:New()
LoginGiftUIPage.__index = LoginGiftUIPage
----------------------------------------------------------------
function LoginGiftUIPage:New()
    local o = {}
    setmetatable(o,LoginGiftUIPage)  
    o:Init()
    return o
end
----------------------------------------------------------------
function LoginGiftUIPage:RegistMsgs()
    self.msgIds = 
    {
        LUIWelfareEvent.RefreshLoginGiftPage,
    }
    self:RegistSelf(self,self.msgIds)
end
----------------------------------------------------------------
function LoginGiftUIPage:ProcessEvent(msg)
    if msg.msgId == LUIWelfareEvent.RefreshLoginGiftPage then
        self:FlushLayer(msg.value + 1)
    end
end
----------------------------------------------------------------
function LoginGiftUIPage:Init()
    ---------------------------------------------
    self.m_pItemModel = nil
    self.m_pPetItemModel = nil
    ---------------------------------------------
    self.m_pGridCell = nil
    self.m_pTablePanel = nil
    self.m_selectIndex = 0
    ---------------------------------------------
    self.m_pRDTablePanel = nil
    ---------------------------------------------
    self.m_pAnimNode = nil
    self.m_pTitle = nil
    self.m_pButton = nil
    ---------------------------------------------
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    --self:RegisterGuide()
end
----------------------------------------------------------------
function LoginGiftUIPage:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
----------------------------------------------------------------
function LoginGiftUIPage:InitViewSize()
    self:CreateUINode("csd/huodong/LoginCarnivalLayer.csb")
end
----------------------------------------------------------------
function LoginGiftUIPage:onExit()
    --Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_FL_1)
    --Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_FL_2)
    --Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_FL_FINISH)
    self:Destory()
    self.m_pGridCell = nil
    self.m_pTablePanel = nil
    self.m_selectIndex = nil
    ---------------------------------------------
    self.m_pRDTablePanel = nil
    ---------------------------------------------
    self.m_pAnimNode = nil
    self.m_pButton = nil
    self.m_pItemModel = nil
    self.m_pPetItemModel = nil
    self.m_pAnimBg = nil
    self.m_pTitle = nil
    self.m_pItemAnimBgEffect = nil
    self.m_pAnimBgEffect = nil
    ---------------------------------------------
end
----------------------------------------------------------------
function LoginGiftUIPage:InitUIControl()
    local panel = self.m_pUILayer:getChildByName("LoginCarnivalUI")
    ---------------------------------------------------------------------
    self.m_pTablePanel = panel:getChildByName("ListView")
    self.m_pGridCell = panel:getChildByName("ItemBtn")
    self.m_pGridCell:setVisible(false)
    self.m_pGridCell:setAnchorPoint(cc.p(0, 0))
    self.m_pGridCell:setTouchEnabled(true)
    self.m_pGridCell:setSwallowTouches(false)
    self.m_pGridCell:addClickEventListener(handler(self, LoginGiftUIPage.ItemClick))
	self:MarkIntaractCObj(self.m_pGridCell)
    ---------------------------------------------------------------------
    self.m_pItemModel = panel:getChildByName("Item")
    self.m_pPetItemModel = panel:getChildByName("IconColor")
    self.m_pItemModel:setVisible(false)
    self.m_pPetItemModel:setVisible(false)
    ---------------------------------------------------------------------
    local pReward = panel:getChildByName("Reward")
    ---------------------------------------------------------------------
    local pBase = pReward:getChildByName("Base")
    self.m_pAnimBg = pBase
    self.m_pAnimNode = pBase:getChildByName("Node")
    self.m_pAnimNode:setScale(1.5)
    self.m_pAnimNode:setLocalZOrder(1)
    local pTitleBg = pBase:getChildByName("TitleBg")
    self.m_pTitle = pTitleBg:getChildByName("Text")
    ---------------------------------------------------------------------
    self.m_pItemAnimBgEffect = self.m_pAnimNode:getChildByName("ItemAnimBgEffect")
    self.m_pAnimBgEffect = pBase:getChildByName("AnimBgEffect")
    ---------------------------------------------------------------------
    local pRewardBg = pReward:getChildByName("RewardBg")
	pRewardBg:setVisible(false)
    self.m_pRDTablePanel = pRewardBg:getChildByName("ListView")
    ---------------------------------------------------------------------
    self.m_pButton = pReward:getChildByName("Button")
    self.m_pButton:addClickEventListener(handler(self, LoginGiftUIPage.GetRewardClick))
	self:MarkIntaractCObj(self.m_pButton)
    ---------------------------------------------------------------------
	local closeBtn = panel:getChildByName("btn_Close")
	closeBtn:addClickEventListener(handler(self, LoginGiftUIPage.CloseUI))
	self:MarkIntaractCObj(closeBtn)
	---------------------------------------------------------------------
    self:initData()
end
----------------------------------------------------------------
function LoginGiftUIPage:createModel(pModel, parent, pData, isPet, num, item, noTouch, noEffect,value)
    local pItem = pModel:clone()
    if isPet then
        Utils:ShowPet(pData[1], parent, pItem, noTouch)
        if (noEffect == nil or noEffect == false) then
            local data = LPetDataMgr:FindPetDataById(pData[1])
            if data and data.quality >= 3 then
                local posX = pItem:getContentSize().width / 2
                local posY = pItem:getContentSize().height / 2
                Utils:createAnimEffect(pItem, cc.p(posX, posY), "res2/fx/gaojiwupin")
            end
        end
    else
        if pData[1]== AppDef.AwrdItem.AWRD_ITEM_EQUIP then--神将装备
			local item = Utils:GetEquipCellValue(pItem, nil, pData[2],0, 0, 0, 0, (noTouch == nil or noTouch == false),true,true)
        elseif pData[1] ==  AppDef.AwrdItem.AWRD_ITEM_FABAO then
			local item = Utils:GetFaBaoCellValue(pItem, nil, 1201,0,false, 0, 0, 0, (noTouch == nil or noTouch == false),true)
		else
			local item = Utils:GetItemCellValue(pItem, 0, pData[1], true, num ~= nil, num, nil, (noTouch == nil or noTouch == false))
        end
        if (noEffect == nil or noEffect == false) then
            local quality = Utils:getQualityByItem(item)
            if quality >= 5 then
                local posX = pItem:getContentSize().width / 2
                local posY = pItem:getContentSize().height / 2
                Utils:createAnimEffect(pItem, cc.p(posX, posY), "res2/fx/gaojiwupin")
            end
        end
    end
    pItem:setVisible(true)
    return pItem
end
----------------------------------------------------------------
function LoginGiftUIPage:initData()
    local gifts = LRoleDataMgr.MyHeroInfo.m_pLoginGift
	dump(gifts,"=============================>>>>>>>>>>>>>>>>>>>>>>>")
    if self.m_pTablePanel == nil then
        return
    end
    local list = self.m_pTablePanel
    list:removeAllItems()
    local datas = JsonConfig.m_loginReward.getList() --LDataConstMgr:GetLoginRewardData()
    for i=1,#datas do
        local pData = datas[i]
        local pItem = self.m_pGridCell:clone()
        pItem:setVisible(true)
        pItem:setTag(i)
        self:updateItem(pItem, i)
        list:pushBackCustomItem(pItem)
    end
    local pScrollItem = nil
    local pSelectInd = gifts.getNum
    for i=1,gifts.getNum do
        local info = gifts.dayInfo[i]
        if info and (not info.haveGet) then
            pSelectInd = i
            if i >= 2 then
                pScrollItem = list:getItem(i-2)
            else
                pScrollItem = list:getItem(i-1)
            end
            break
        end
    end
    if pScrollItem == nil and gifts.getNum >= 1 then
        pScrollItem = list:getItem(gifts.getNum - 1)
    end
    if gifts.getNum <= #datas then
        self:TableCellTouched(pSelectInd)
        Utils:ScrollToListItem(list, pScrollItem, pSelectInd, #datas, 4, 0.5)
    end
end
----------------------------------------------------------------
function LoginGiftUIPage:ItemClick(sender)
    if sender == nil then
        return
    end
    local tag = sender:getTag()
    self:TableCellTouched(tag)
end
----------------------------------------------------------------
function LoginGiftUIPage:TableCellTouched(idx)
    if idx == self.m_selectIndex then
        return
    end
    local items = self.m_pTablePanel:getItems()
    if self.m_pTablePanel and idx <= #items then
        if self.m_selectIndex > 0 then
            self:setSelect(self.m_pTablePanel:getItem(self.m_selectIndex-1), false)
        end
        self.m_selectIndex = idx
        self:setSelect(self.m_pTablePanel:getItem(self.m_selectIndex-1), true)
        self:ChangeSelectDay()
    end
end
----------------------------------------------------------------
function LoginGiftUIPage:updateItem(cell, day)
    local data = JsonConfig.m_loginReward.getDefByID(day) --LDataConstMgr:GetLoginRewardDataByIndex(day)
    local gifts = LRoleDataMgr.MyHeroInfo.m_pLoginGift
    if data == nil or gifts == nil then
        return
    end
   
    --------------------------------------------------------------------
    local pTitleBg = cell:getChildByName("Title")
    local pTitle = pTitleBg:getChildByName("Text")
    local dayStr = ""
    dayStr = GUINumUper[day]
    pTitle:setString( string.format(GUITips.REI_TIPS_LOGIN_REWARD1, dayStr))
    --------------------------------------------------------------------
    local pIconBg = cell:getChildByName("IconPanel")
    local state = self:GetState(day)
    --------------------------------------------------------------------
    if pIconBg then
        local pSubItem = nil
        pIconBg:removeChildByName("SubItem")
        if data.reward[1][1] == AppDef.AwrdItem.AWRD_ITEM_PET then
            pSubItem = self:createModel(self.m_pPetItemModel, pIconBg, data.reward[1], true, nil, nil, true, state == 1)
        else
            pSubItem = self:createModel(self.m_pItemModel, pIconBg, data.reward[1], false, data.reward[1][3], nil, true, state == 1)
        end
        if pSubItem then
            pSubItem:setName("SubItem")
            pSubItem:setVisible(true)
            pSubItem:setAnchorPoint(cc.p(0.5, 0.5))
            pSubItem:setPosition(cc.p(pIconBg:getContentSize().width/2, pIconBg:getContentSize().height/2))
            pIconBg:addChild(pSubItem)
        end
    end
    --------------------------------------------------------------------
    self:setMask(cell, state == 1)
    --------------------------------------------------------------------
    local pName = pIconBg:getChildByName("Name")
    pName:setLocalZOrder(1)
    --------------------------------------------------------------------
    local pNameText = pName:getChildByName("Text")
    pNameText:setString(data.name and data.name or "")
    --------------------------------------------------------------------
    local pChoose = cell:getChildByName("Choose")
    pChoose:setVisible(self.m_selectIndex == day)
    --------------------------------------------------------------------
    local pRedDot = cell:getChildByName("RedDot")
    local _ = pRedDot and pRedDot:setVisible((state and {state==0} or {false})[1])
end
----------------------------------------------------------------
function LoginGiftUIPage:setSelect(cell, isSelected)
    if cell == nil then
        return
    end
    local pChoose = cell:getChildByName("Choose")
    pChoose:setVisible(isSelected)
end
----------------------------------------------------------------
function LoginGiftUIPage:setMask(cell, isGeted)
    if cell == nil then
        return
    end
    local pIconBg = cell:getChildByName("IconPanel")
    local pMaskBg = pIconBg:getChildByName("Mark_bg")
    pMaskBg:setLocalZOrder(1)
    pMaskBg:setVisible(isGeted)
end
----------------------------------------------------------------
function LoginGiftUIPage:ChangeSelectDay()
    local data = JsonConfig.m_loginReward.getDefByID(self.m_selectIndex) --LDataConstMgr:GetLoginRewardDataByIndex(self.m_selectIndex)
    self:UpdateAnimNode(data)
    self:UpdateButton()
    --self:UpdateReward()
end
----------------------------------------------------------------
function LoginGiftUIPage:UpdateAnimNode(data)
    if self.m_pAnimNode == nil or data == nil then
        return
    end
    
    local itemY = 75

    local pItemNode = self.m_pAnimNode:getChildByTag(0xff)
    local pPetNode = self.m_pAnimNode:getChildByTag(0xf0)
    local pNode = nil
    if #data.reward > 0 then
		local reward = data.reward[1]
		local cfg = nil
		local path = ""
		if reward[1] == AppDef.AwrdItem.AWRD_ITEM_EQUIP then
			cfg = JsonConfig.m_equipConfig.getDefByID(reward[2])
			path = "item/"..cfg.pic..".png"
		elseif reward[1] == AppDef.AwrdItem.AWRD_ITEM_FABAO then
			cfg = JsonConfig.m_faBaoConfig.getDefByID(reward[2])
			path = "item/"..cfg.pic..".png"
		else
			cfg = LItemMgr:getItem(reward[1])
			path = "item/equip" .. cfg.pic .. ".png"
		end
		if cfg == nil then
			return
		end
        if pItemNode == nil then
            pItemNode = cc.Sprite:create(path)
            pItemNode:setPositionY(itemY)
            self.m_pAnimNode:addChild(pItemNode, 1, 0xff)
        else
            pItemNode:setTexture(path)
        end
        pItemNode:setVisible(true)
        if self.m_pAnimBgEffect then
            self.m_pAnimBgEffect:setVisible(false)
        end
        if pPetNode then
            pPetNode:setVisible(false)
        end
        --------------------------------------------
        if self.m_pItemAnimBgEffect == nil then
            self.m_pItemAnimBgEffect = Utils:createAnimEffect(self.m_pAnimNode, cc.p(self.m_pAnimNode:getContentSize().width/2, pItemNode:getPositionY()), "res2/fx/background")
            self.m_pItemAnimBgEffect:setIgnoreAnchorPointForPosition(false)
            self.m_pItemAnimBgEffect:setAnchorPoint(cc.p(0.5, 0.5))
            self.m_pItemAnimBgEffect:PlayActionRepeat(0)
            self.m_pItemAnimBgEffect:setLocalZOrder(0)
            self.m_pItemAnimBgEffect:setName("ItemAnimBgEffect")
        end
        self.m_pItemAnimBgEffect:setVisible(true)
        --------------------------------------------
        pNode = pItemNode
    else
        if #data.type >= 2 then
            --------------------------------------------
            local isAdd = pPetNode == nil
            pPetNode = self:CreateAnimModel(data.type[1], data.type[2], pPetNode)
            if isAdd and pPetNode then
                self.m_pAnimNode:addChild(pPetNode, 1, 0xf0)
            end
            pPetNode:setVisible(true)
            --------------------------------------------
            if self.m_pAnimBgEffect == nil then
                self.m_pAnimBgEffect = Utils:createAnimEffect(self.m_pAnimBg, cc.p(self.m_pAnimBg:getContentSize().width/2, self.m_pAnimBg:getContentSize().height/2+18), "res2/fx/shenqizhanshi")
                self.m_pAnimBgEffect:setIgnoreAnchorPointForPosition(false)
                self.m_pAnimBgEffect:setAnchorPoint(cc.p(0.5, 0))
                self.m_pAnimBgEffect:PlayActionRepeat(0)
                self.m_pAnimBgEffect:setLocalZOrder(0)
                self.m_pAnimBgEffect:setName("AnimBgEffect")
            end
            self.m_pAnimBgEffect:setVisible(true)
            --------------------------------------------
            pNode = pPetNode
        else
            Utils:Debug("ERROR")
        end
        if pItemNode then
            pItemNode:setVisible(false)
        end
        if self.m_pItemAnimBgEffect then
            self.m_pItemAnimBgEffect:setVisible(false)
        end
    end
    if self.m_pTitle then
        self.m_pTitle:setString(data.name)
    end
    if pNode and data.isAnim then
        local sequence = cc.Sequence:create(cc.MoveTo:create(1, cc.p(pNode:getPositionX(), itemY+5)), cc.MoveTo:create(1, cc.p(pNode:getPositionX(), itemY-5)))
        local action = cc.RepeatForever:create(sequence)
        pNode:stopAllActions()
        pNode:runAction(action)
    end
end
----------------------------------------------------------------
function LoginGiftUIPage:CreateAnimModel(iType, iValue, pAnimNode)
    if iType == AppDef.AwrdItem.AWRD_ITEM_PET then
        local pAnim = nil
        local cfg = LPetDataMgr:FindPetDataById(iValue)
        if cfg then
            if pAnimNode == nil then
                pAnim = ModelAniNode:create(AppDef.CEnum.ModelAniType.Monster, 0)
            else
                pAnim = pAnimNode
            end
            pAnim:InitAni(AppDef.CEnum.ModelAniType.Monster, cfg.pic)
            pAnim:PlayStand(0)
        end
        return pAnim
    elseif iType == AppDef.AwrdItem.AWRD_ITEM_HORSE then
        local pAnim = nil
        if pAnimNode == nil then
            pAnim = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, 0)
        else
            pAnim = pAnimNode
        end
        pAnim:InitAni(AppDef.CEnum.ModelAniType.Hero,0,0,0,0,iValue,0)
        return pAnim
        -- local data = LDataConstMgr:GetHorseConfigData(iValue)
        -- self.m_pTitle:setString(data and data.name or "")
        -- self.m_pTitle:setVisible(true)
    elseif iType == AppDef.AwrdItem.AWRD_ITEM_WINDS then
        local pAnim = nil
        if pAnimNode == nil then
            pAnim = ModelAniNode:create(AppDef.CEnum.ModelAniType.Wing, 0)
        else
            pAnim = pAnimNode
        end
        pAnim:InitAni(AppDef.CEnum.ModelAniType.Wing,0,0,0,iValue,0,0)
        pAnim:PlayStand(0)
        return pAnim
        -- local data = LDataConstMgr:GetWingConfigData(iValue)
        -- self.m_pTitle:setString(data and data.name or "")
        -- self.m_pTitle:setVisible(true)
    elseif iType == AppDef.AwrdItem.AWRD_ITEM_ARTIFACT then
        local pAnim = nil
        if pAnimNode == nil then
            pAnim = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, 0)
        else
            pAnim = pAnimNode
        end
        pAnim:InitAni(AppDef.CEnum.ModelAniType.Hero,0,0,0,0,0,iValue)
        pAnim:setPosition(cc.p(30, -90))
        return pAnim
        -- local data = LDataConstMgr:GetShenQiById(iValue)
        -- self.m_pTitle:setString(data and data.m_name or "")
        -- self.m_pTitle:setVisible(true)
    end
    return nil
end
----------------------------------------------------------------
function LoginGiftUIPage:GetRewardClick(sender)
    if self.m_selectIndex <= 0 then
        return
    end
    LuaNetSendMsg:QueryLoginGift(5, 2, self.m_selectIndex-1)
end
----------------------------------------------------------------
function LoginGiftUIPage:FlushLayer(day)
    local gifts = LRoleDataMgr.MyHeroInfo.m_pLoginGift
  
    if gifts.dayInfo[day] then
        gifts.dayInfo[day].haveGet = true
    end
    self:updateItem(self.m_pTablePanel:getItem(day-1), day)
    if day < #gifts.dayInfo then
        local pScrollItem = self.m_pTablePanel:getItem(day)
        self:TableCellTouched(day + 1)
        if pScrollItem then
            Utils:ScrollToListItem(self.m_pTablePanel, pScrollItem, day, #gifts.dayInfo, 4, 0.5)
        end
    else
        self:ChangeSelectDay()
    end
    Utils:SendMsg(LUIOnlineAwardEvent.KaifuReddotRefresh, 1)
end
----------------------------------------------------------------
function LoginGiftUIPage:UpdateButton()
    if self.m_pButton ~= nil then
        local canGet = false
        local state = self:GetState(self.m_selectIndex)
        if state then
            canGet = (state  == 0)
        end
        self.m_pButton:setBright(canGet)
        self.m_pButton:setEnabled(canGet)

        local pText = self.m_pButton:getChildByName("Text")
        pText:setString(string.format(GUITips.REI_TIPS_LOGIN_REWARD1, tostring(self.m_selectIndex))..GUITips.RSI_FACTION_MSG203)
    end
end
----------------------------------------------------------------
--day(1-8)
function LoginGiftUIPage:GetState(day)
    local gifts = LRoleDataMgr.MyHeroInfo.m_pLoginGift
    local info = gifts.dayInfo[day]
    if info == nil then
        return nil
    end

    if day <= gifts.getNum then
        return (info.haveGet and 1 or 0)
    else
        return 2
    end
end
----------------------------------------------------------------
function LoginGiftUIPage:UpdateReward()
    if self.m_pRDTablePanel == nil then
        return
    end
    local gifts = LRoleDataMgr.MyHeroInfo.m_pLoginGift

    local info = gifts.dayInfo[self.m_selectIndex]
    
    if info == nil then
        return
    end
    local list = self.m_pRDTablePanel
    list:removeAllItems()

    local petNum = #info.petdata
    for i= 1, petNum do
        local pet = info.petdata[i]
        local pItem = self:createModel(self.m_pPetItemModel, list, pet.id, true)
        list:pushBackCustomItem(pItem)
    end

    for i = 1, #info.ItemId do
        local itemId = info.ItemId[i]
        local itemNum = info.ItemNum[i]
        local value = info.value[i]
       -- LoginGiftUIPage:createModel(pModel, parent, pData, isPet, num, item, noTouch, noEffect,value)
        local pItem = self:createModel(self.m_pItemModel, list, itemId, nil, itemNum,nil,nil,nil,value)
        list:pushBackCustomItem(pItem)
    end
end
----------------------------------------------------------------
function LoginGiftUIPage:RegisterGuide()
    --------------------------------------------
    -- Utils:RegisterGuide(GuideDef.StepId.Guide_FL_1, self.m_pButton, handler(self, LoginGiftUIPage.GetRewardClick), nil, true)
    -- --------------------------------------------
    -- local data = LDataConstMgr:GetGuideData(GuideDef.StepId.Guide_FL_2)
    -- if data then
    --     Utils:RegisterGuide(GuideDef.StepId.Guide_FL_2, nil, nil, data.maskOffset, true)
    -- end
    -- --------------------------------------------
    -- local data = LDataConstMgr:GetGuideData(GuideDef.StepId.Guide_FL_FINISH)
    -- if data then
    --     Utils:RegisterGuide(GuideDef.StepId.Guide_FL_FINISH, nil, nil, data.maskOffset, true)
    -- end
end
----------------------------------------------------------------
function LoginGiftUIPage:CloseUI()
	Utils:DeleteUI("Welfare.LoginGiftUIPage")
end
return LoginGiftUIPage