local ObjectPool = require("Common.ObjectPool")

local NewVipUI = LUIBase:New()
NewVipUI.__index = NewVipUI
----------------------------------------------------------------
function NewVipUI:New()
    local o = {}
    setmetatable(o,NewVipUI)  
    o:Init()
    return o
end
----------------------------------------------------------------
function NewVipUI:Init()
    AppDef.spriteFrameCache:addSpriteFrames("res/csd/Plist/ui_vipPlist.plist", "res/csd/Plist/ui_vipPlist.png")
    self.m_pTablePanel = nil
    self.m_pVipNum = nil
    self.m_pPercentBar = nil
    self.m_pExpStr = nil
    self.m_pTipsUp = nil
    self.m_pRechargeBtn = nil
    self.m_pAnimBg = nil
    self.m_pAnimNode = nil
    self.m_pTitle = nil
    self.m_pRDTablePanel = nil
    self.m_pItemModel = nil
    self.m_pPetItemModel = nil
    self.m_pTQTablePanel = nil
    -- self.m_pTQItemModel = nil
    self.m_pNextVipText = nil

    self.m_selectIndex = 0
    self.m_items = {}
    -- self.m_actBtnPool = nil
    -------------------------------------------------
    self:InitViewSize()
    self:setCloseCallback()
    self:InitUIControl()
end
----------------------------------------------------------------
function NewVipUI:InitUIControl()
    if self.m_pUILayer == nil then
        return
    end
    local panel = self.m_pUILayer:getChildByName("Panel")
    -------------------------------------------------
    local pTitle = panel:getChildByName("Title")
    self.m_pVipNum = pTitle:getChildByName("VIPNumBg"):getChildByName("Num")
    local pLoadingBg = pTitle:getChildByName("LoadingBg")
    self.m_pPercentBar = pLoadingBg:getChildByName("LoadingBar")
    self.m_pExpStr = pLoadingBg:getChildByName("Num")
    self.m_pTipsUp = pTitle:getChildByName("TipsUp")
    self.m_pRechargeBtn = pTitle:getChildByName("Btn")
    self:SetCurrentVipInfo()
    self:SetRechargeTouch()
    -------------------------------------------------
    local pDes = panel:getChildByName("Des")
    self:InitVipList(pDes:getChildByName("BtnList"), pDes:getChildByName("Button_1"))
    -------------------------------------------------
    local pDesBg = pDes:getChildByName("Bg")
    local pBase = pDesBg:getChildByName("Base")
    self.m_pAnimBg = pBase
    self.m_pAnimNode = pBase:getChildByName("Node")
    self.m_pAnimNode:setScale(1.25)
    self.m_pAnimNode:setLocalZOrder(1)
    local pTitleBg = pBase:getChildByName("TitleBg")
    self.m_pTitle = pTitleBg:getChildByName("Text")
    -------------------------------------------------
    local pRewardBg = pDesBg:getChildByName("RewardBg")
    self.m_pRDTablePanel = pRewardBg:getChildByName("ListView")
    self.m_pItemModel = pDes:getChildByName("Item")
    self.m_pPetItemModel = pDes:getChildByName("IconColor")
    -------------------------------------------------
    self.m_pTQTablePanel = pDesBg:getChildByName("DesList")
    -- self.m_pTQItemModel = pDes:getChildByName("Des_1")
    -- self.m_pTQItemModel:setTouchEnabled(false)
    -- self.m_actBtnPool = ObjectPool:New(self.m_pTQItemModel)
    -------------------------------------------------
    local info = LRoleDataMgr.MyHeroInfo.MyVIPInfo
    self:TableCellTouched(info.vipLevel and math.max(info.vipLevel, 1) or 1)
    if self.m_pTablePanel and info.vipLevel and info.vipLevel > 1 then
        local pScrollItem = self.m_pTablePanel:getItem(info.vipLevel - 1)
        if pScrollItem then
            local space = self.m_pTablePanel:getItemsMargin()
            self.m_pTablePanel:stopAllActions()
            performWithDelay(self.m_pTablePanel, function(sender)
                local time = 0.5
                if (info.vipLevel) == #self.m_pTablePanel:getItems() then
                    self.m_pTablePanel:scrollToPercentHorizontal(100, time, true)
                else
                    local posX = pScrollItem:getPositionX()-pScrollItem:getContentSize().width/2-space*0.5
                    local diff = self.m_pTablePanel:getInnerContainerSize().width - self.m_pTablePanel:getContentSize().width
                    local persent = posX / diff * 100
                    self.m_pTablePanel:scrollToPercentHorizontal(math.min(persent, 100), time, true)
                end
            end, 1/10)
        end
    end
end
----------------------------------------------------------------
function NewVipUI:setCloseCallback()
    if self.m_pUILayer == nil then
        return
    end
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
----------------------------------------------------------------
function NewVipUI:InitViewSize()
    self:CreateUINode("csd/shop/GuiZuLayer.csb")
end
----------------------------------------------------------------
function NewVipUI:onExit()
    self:Destory()
    -- AppDef.spriteFrameCache:removeSpriteFramesFromFile("res/csd/Plist/ui_vipPlist.plist")
    self.m_pUILayer = nil
    self.m_pTablePanel = nil
    self.m_pVipNum = nil
    self.m_pPercentBar = nil
    self.m_pExpStr = nil
    self.m_pTipsUp = nil
    self.m_pRechargeBtn = nil
    self.m_pAnimBg = nil
    self.m_pAnimNode = nil
    self.m_pTitle = nil
    self.m_pRDTablePanel = nil
    self.m_pItemModel = nil
    self.m_pPetItemModel = nil
    self.m_pTQTablePanel = nil
    -- self.m_pTQItemModel = nil
    self.m_pNextVipText = nil

    self.m_selectIndex = nil
    Utils:FreeTable(self.m_items)
    self.m_items = nil
    self.m_pAnimNode = nil
    self.m_pItemAnimBgEffect = nil
    self.m_pAnimBgEffect = nil
    self.m_pItemAnimBgEffect = nil

    if self.m_actBtnPool then
        self.m_actBtnPool:onExit()
        self.m_actBtnPool = nil
    end
end
----------------------------------------------------------------
function NewVipUI:SetRechargeTouch()
    if self.m_pRechargeBtn == nil then
        return
    end
    local function RechargeCallback(sender)
        Utils:OpenRechargeMainUI()
    end
    self.m_pRechargeBtn:addClickEventListener(RechargeCallback)
	self:MarkIntaractCObj(self.m_pRechargeBtn)
end
----------------------------------------------------------------
function NewVipUI:SetCurrentVipInfo()
    local info = LRoleDataMgr.MyHeroInfo.MyVIPInfo
    local award = nil
    if info.vipLevel == 0 then
        self.m_selIdx = 0
        award = LDataConstMgr.m_VipAwardInfo[1]
    else
        self.m_selIdx = info.vipLevel - 1
        if info.vipLevel == #LDataConstMgr.m_VipAwardInfo then
            award = LDataConstMgr.m_VipAwardInfo[info.vipLevel]
        else
            award = LDataConstMgr.m_VipAwardInfo[info.vipLevel + 1]
        end
    end
    if award == nil then
        return
    end
    local tips = nil
    local curExp = info.vipMoney
    if award.CardPrice > info.vipMoney then -- 
        tips = string.format(GUITips.RSI_VIP_NEXT_INFO, award.CardPrice - info.vipMoney, info.vipLevel + 1)
    else
        curExp = award.CardPrice
        tips = GUITips.RSI_VIP_FULL
    end
    local percentStr = curExp.."/"..award.CardPrice
    self.m_pPercentBar:setPercent(curExp*100/award.CardPrice)
    self.m_pExpStr:setString(percentStr)
    self.m_pVipNum:setString(info.vipLevel)

    if self.m_pNextVipText == nil and self.m_pTipsUp ~= nil then
        self.m_pNextVipText = Utils:CreateColorText2(nil, self.m_pTipsUp)
    end
    self.m_pNextVipText:setString(tips)
end
----------------------------------------------------------------
function NewVipUI:InitVipList(pListView, pItemModel)
    if pListView == nil or pItemModel == nil then
        return
    end
    self.m_pTablePanel = pListView
    pItemModel:setSwallowTouches(false)
    local info = LDataConstMgr.m_VipAwardInfo
    local cInfo = #info
    local pItems = pListView:getItems()
    local cItem = #pItems
    for i=1,math.max(cInfo, cItem) do
        if i > cInfo then
            local _ = pItems[i] and pItems[i]:setVisible(false)
        end
        local pItem = nil
        if i > cItem then
            pItem = pItemModel:clone()
            if pItem ~= nil then
                pItem:addClickEventListener(handler(self, NewVipUI.ItemClick))
				self:MarkIntaractCObj(pItem)
                pListView:pushBackCustomItem(pItem)
            end
        else
            pItem = pItems[i]
        end
        if pItem then
            pItem:setTag(i)
            local pItemInfo = info[i]
            self:setSelect(pItem, false)

            local pText = pItem:getChildByName("Text")
            local _ = pText and pText:setString(GUITips.RSI_VIP_ITEM..i)
            
            local pTips = pItem:getChildByName("Tips")
            local pTipsText = pTips:getChildByName("Text")
            local cfg = LDataConstMgr:GetVIPConfigDataByIndex(i)
            if pTips ~= nil then
                pTips:setVisible(false)

                if cfg and cfg.tips and #cfg.tips > 0 then
                    pTips:setVisible(true)
                    local _ = pTipsText and pTipsText:setString(cfg.tips)
                end
            end
            pItem:setVisible(true)
        end
    end
end
----------------------------------------------------------------
function NewVipUI:ItemClick(sender)
    if sender == nil then
        return
    end
    local tag = sender:getTag()
    self:TableCellTouched(tag)
end
----------------------------------------------------------------
function NewVipUI:TableCellTouched(idx)
    if idx == self.m_selectIndex then
        return
    end
    local items = self.m_pTablePanel:getItems()
    if self.m_pTablePanel and idx <= #items then
        if self.m_selectIndex > 0 then
            self:setSelect(items[self.m_selectIndex], false)
        end
        self.m_selectIndex = idx
        self:setSelect(items[self.m_selectIndex], true)
        self:ChangeSelect()
    end
end
----------------------------------------------------------------
function NewVipUI:setSelect(cell, isSelected)
    if cell == nil then
        return
    end
    local pChoose = cell:getChildByName("Choose")
    pChoose:setVisible(isSelected)
end
----------------------------------------------------------------
function NewVipUI:ChangeSelect()
    local data = LDataConstMgr:GetVIPConfigDataByIndex(self.m_selectIndex)
    self:UpdateAnimNode(data)
    self:UpdateTeQuan()
    self:UpdateReward()
end
----------------------------------------------------------------
function NewVipUI:createModel(pModel, parent, pData, isPet, num, item, noTouch, noEffect,pid,pstar)
       
    local pItem = pModel:clone()
    if isPet then
        Utils:ShowPet(pData, parent, pItem, noTouch)
        --宠物特效
        if (noEffect == nil or noEffect == false) then
            local data = LPetDataMgr:FindPetDataById(pData)
            if data and data.quality >= 3 then
                local posX = pItem:getContentSize().width / 2
                local posY = pItem:getContentSize().height / 2
                Utils:createAnimEffect(pItem, cc.p(posX, posY), "res2/fx/gaojiwupin")
            end
        end
    else
        local item = Utils:GetItemCellValue(pItem, 0, pData, true, num ~= nil, num, nil, (noTouch == nil or noTouch == false),nil, pid, pstar)
        --物品特效
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
function NewVipUI:UpdateAnimNode(data)
    if self.m_pAnimNode == nil or data == nil then
        return
    end
    
    local itemY = 75

    local pItemNode = self.m_pAnimNode:getChildByTag(0xff)
    local pPetNode = self.m_pAnimNode:getChildByTag(0xf0)
    local pNode = nil
    if #data.path > 0 then
        if pItemNode == nil then
            pItemNode = cc.Sprite:create(data.path)
            pItemNode:setPositionY(itemY)
            self.m_pAnimNode:addChild(pItemNode, 1, 0xff)
        else
            pItemNode:setTexture(data.path)
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
            Utils:Debug("配置有误")
        end
        if pItemNode then
            pItemNode:setVisible(false)
        end
        if self.m_pItemAnimBgEffect then
            self.m_pItemAnimBgEffect:setVisible(false)
        end
    end
    
    local _ = self.m_pTitle and self.m_pTitle:setString(data.name)

    if pNode and data.isAnim then
        local sequence = cc.Sequence:create(cc.MoveTo:create(1, cc.p(pNode:getPositionX(), itemY+5)), cc.MoveTo:create(1, cc.p(pNode:getPositionX(), itemY-5)))
        local action = cc.RepeatForever:create(sequence)
        pNode:stopAllActions()
        pNode:runAction(action)
    end
end
----------------------------------------------------------------
function NewVipUI:CreateAnimModel(iType, iValue, pAnimNode)
    if iType == AppDef.AwrdItem.AWRD_ITEM_PET then--宠物
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
            pAnim:setPosition(cc.p(0, 0))
        end
        return pAnim
    elseif iType == AppDef.AwrdItem.AWRD_ITEM_HORSE then--坐骑
        local pAnim = nil
        if pAnimNode == nil then
            pAnim = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, 0)
        else
            pAnim = pAnimNode
        end
        pAnim:InitAni(AppDef.CEnum.ModelAniType.Hero,0,0,0,0,iValue,0)
        pAnim:setPosition(cc.p(0, 0))
        return pAnim
    elseif iType == AppDef.AwrdItem.AWRD_ITEM_WINDS then--翅膀
        local pAnim = nil
        if pAnimNode == nil then
            pAnim = ModelAniNode:create(AppDef.CEnum.ModelAniType.Wing, 0)
        else
            pAnim = pAnimNode
        end
        pAnim:InitAni(AppDef.CEnum.ModelAniType.Wing,0,0,0,iValue,0,0)
        pAnim:PlayStand(0)
        pAnim:setPosition(cc.p(0, 0))
        return pAnim
    elseif iType == AppDef.AwrdItem.AWRD_ITEM_ARTIFACT then--神器
        local pAnim = nil
        if pAnimNode == nil then
            pAnim = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, 0)
        else
            pAnim = pAnimNode
        end
        pAnim:InitAni(AppDef.CEnum.ModelAniType.Hero,0,0,0,0,0,iValue)
        pAnim:setPosition(cc.p(30, -90))
        return pAnim
    -- elseif iType == AppDef.AwrdItem.AWRD_ITEM_PETEQUIP then--神将装备
    --     local pAnim = nil
    --     if pAnimNode == nil then
    --         pAnim = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, 0)
    --     else
    --         pAnim = pAnimNode
    --     end
    --     pAnim:InitAni(AppDef.CEnum.ModelAniType.Hero,0,0,0,0,0,iValue)
    --     pAnim:setPosition(cc.p(30, -90))
    --     return pAnim
     end
    return nil
end
----------------------------------------------------------------
function NewVipUI:UpdateTeQuan()
    if self.m_pTQTablePanel == nil or self.m_pTQItemModel == nil then
        return
    end
    local info = LDataConstMgr.m_VipAwardInfo[self.m_selectIndex]
    if info == nil then
        return
    end
    local cfg = LDataConstMgr:GetVIPConfigDataByIndex(self.m_selectIndex)
    local items = self.m_pTQTablePanel:getItems()
    if self.m_actBtnPool then
        for i=1,#items do
            self.m_actBtnPool:Push(items[i])
            items[i] = nil
        end
        self.m_pTQTablePanel:removeAllItems()
    end
    local tqList = info.Vipright
    local cItem = #items
    local cTqList = #tqList
    if self.loadImageKey then
        for k,v in pairs(self.loadImageKey) do
            local _ = k and Utils:UnbindAsyncImg(k)
            self.loadImageKey[k] = nil
        end
    end
    for i=1,math.max(cItem, cTqList) do
        local pItem = nil
        if i > cItem then
            if self.m_actBtnPool then
                pItem = self.m_actBtnPool:Pop()
            else
                pItem = self.m_pTQItemModel:clone()
            end
            self.m_pTQTablePanel:pushBackCustomItem(pItem)
        else
            pItem = items[i]
        end
        if pItem ~= nil then
            if i > cTqList then
                pItem:setVisible(false)
            else
                local pIcon = pItem:getChildByName("Image_104")
                if pIcon then
                    if cfg and cfg.tqIcons and cfg.tqIcons[i] and #cfg.tqIcons[i] > 0 then
                        local str = cfg.tqIcons[i]
                        self.loadImageKey[str] = true
                        Utils:AsyncLoadImg(pIcon, str, function(pTexture)
                            self.loadImageKey[str] = nil
                            pIcon:loadTexture(str, UI_TEX_TYPE_LOCAL)
                        end)
                        pIcon:setVisible(true)
                    else
                        pIcon:setVisible(false)
                    end
                end
                local pTextBg = pItem:getChildByName("TextBg")
                self.m_items[i] = pTextBg:getChildByName("AysText")
                if self.m_items[i] == nil then
                    local pText = pTextBg:getChildByName("Text_45")
                    self.m_items[i] = Utils:CreateColorText2(nil, pText, cc.size(pText:getContentSize().width-4, pText:getContentSize().height))
                    self.m_items[i]:setName("AysText")
                end
                self.m_items[i]:setString(tqList[i] or "")
                pItem:setVisible(true)
            end
        end
    end
    self.m_pTQTablePanel:jumpToLeft()
end
----------------------------------------------------------------
function NewVipUI:UpdateReward()
    if self.m_pRDTablePanel == nil then
        return
    end
    local info = LDataConstMgr.m_VipAwardInfo[self.m_selectIndex]
    if info == nil then
        return
    end
    local list = self.m_pRDTablePanel
    list:removeAllItems()

    for i = 1, #info.AwardNum do
        local itemId = info.AwardId[i]
        local itemNum = info.AwardNum[i]
      --  local star = info.AwardStar[i]
      --  local pid = info.Awardpid[i]
    

        local pItem = nil
        --添加神将装备
        if false and AppDef.PetMap[itemId] then
            pItem = self:createModel(self.m_pPetItemModel, list, AppDef.PetMap[itemId], true)
        else
            pItem = self:createModel(self.m_pItemModel, list, itemId, nil, itemNum,nil,false,false,pid,pstar)
        end
        local _ = pItem and list:pushBackCustomItem(pItem)
    end
end
----------------------------------------------------------------
return NewVipUI