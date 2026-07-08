local NewTowerDelegate = LUIBase:New()
NewTowerDelegate.__index = NewTowerDelegate

local animConfig = {
    ["animation1"] = {0, 30, 60},
    ["animation2"] = {75, 115, 145},
}

local TowerState = {
    ["None"] = 0,--无
    ["Monster"] = 1,--通天塔
    ["Boss"] = 2,--霸主
}

----------------------------------------------
function NewTowerDelegate:New()
    local o = {}
    setmetatable(o, NewTowerDelegate)
    o:Init()
    return o
end
----------------------------------------------
function NewTowerDelegate:Init()
    self.Script = "Tower.NewTowerDelegate"
    -- self.m_pCallback = nil
    self.m_isInit = true
    self.m_data = nil
    self.m_data2 = nil
    self.towerKingInfo = nil
    self.m_pMonsterTower = {}
    self.m_pBossTower = {}
    self.m_pTowerMonster = nil
    self.m_initTowerPosY = 0

    self.m_selectMonster = 1
    self.m_selectBoss = -1
    self.m_state = TowerState.Monster
    ---------------------------
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:RegisterQuik()
end
----------------------------------------------
function NewTowerDelegate:RegistMsgs()
    self.msgIds = 
    {
        LUITowerEvent.TowerInfo,
        LUITowerEvent.TowerKingData,
    }
    self:RegistSelf(self,self.msgIds)
end

----------------------------------------------
function NewTowerDelegate:ProcessEvent(msg)
    if msg.msgId == LUITowerEvent.TowerInfo then
        self:OnTowerInfo(msg.value)
    elseif msg.msgId == LUITowerEvent.TowerKingData then
        self:OnTowerKingData(msg.value)
    elseif msg.msgId == LUILogicEvent.ExitBattle then
        self:ShowMoveAnim()
    end
end

----------------------------------------------
function NewTowerDelegate:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_timeline = nil
    self.m_pLeftButton = nil
    self.m_pRightButton = nil

    self.Script = nil
    self.m_isInit = nil
    Utils:FreeTable(self.m_data)
    self.m_data = nil
    Utils:FreeTable(self.m_data2)
    self.m_data2 = nil
    Utils:FreeTable(self.towerKingInfo)
    self.towerKingInfo = nil
    Utils:FreeTable(self.m_pMonsterTower)
    self.m_pMonsterTower = nil
    Utils:FreeTable(self.m_pBossTower)
    self.m_pBossTower = nil
    self.m_pTowerMonster = nil
    self.m_initTowerPosY = nil
    self.m_pScrollView = nil

    self.m_selectMonster = nil
    self.m_selectBoss = nil
    self.m_state = nil
end

function NewTowerDelegate:RegisterQuik()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
----------------------------------------------
function NewTowerDelegate:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/TowerLayer3.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    self.m_timeline = cc.CSLoader:createTimeline("csd/TowerLayer3.csb")
    self.m_timeline:pause()

    local function addEvent(key, index)
        local timeline = ccs.Timeline:create()
        local frame = ccs.EventFrame:create()
        frame:setEvent(key)
        frame:setFrameIndex(index)
        timeline:addFrame(frame)
        self.m_timeline:addTimeline(timeline)
    end

    for k,v in pairs(animConfig) do
        local midIndex,endIndex = v[2],v[3]
        if midIndex then
            addEvent("UpdateState"..midIndex, midIndex)
        end
        if endIndex then
            addEvent("UpdateState"..endIndex, endIndex)
        end
    end
    
    self.m_timeline:clearFrameEventCallFunc()
    self.m_timeline:setFrameEventCallFunc(handler(self, NewTowerDelegate.FrameEventCallFunc))
    self.m_pUILayer:runAction(self.m_timeline)
end
----------------------------------------------
function NewTowerDelegate:InitUIControl()
    local panel = self.m_pUILayer:getChildByName("PetList")
    ------------------------------
    local pTowerAll = panel:getChildByName("TowerAll")
    self.m_pTowerMonster = pTowerAll
    self.m_initTowerPosY = pTowerAll:getPositionY()
    pTowerAll:setTouchEnabled(true)
    pTowerAll:addClickEventListener(handler(self, NewTowerDelegate.ChangeToMonster))
	self:MarkIntaractCObj(pTowerAll)
    for i=1,6 do
        local pTower = pTowerAll:getChildByName("Tower_"..(i-1))
        pTower:setTag(i)
        pTower:setTouchEnabled(false)
        
        local pGroup = pTower:getChildByName("Group")
        if pGroup ~= nil then
            local pZBtn = pGroup:getChildByName("Button_1")
            pZBtn:setTag(i)
            self:MarkIntaractCObj(pZBtn)
            pZBtn:addClickEventListener(handler(self, NewTowerDelegate.ZhenFaClick))

            local pTBtn = pGroup:getChildByName("Button_2")
            pTBtn:setTag(100+i)
            self:MarkIntaractCObj(pTBtn)
            pTBtn:addClickEventListener(handler(self, NewTowerDelegate.TuiJianClick))
        end
        
        table.insert(self.m_pMonsterTower, pTower)
    end
    ------------------------------
    local pTowerBoss = panel:getChildByName("TowerBoss")
    pTowerBoss:setTouchEnabled(true)
    pTowerBoss:addClickEventListener(handler(self, NewTowerDelegate.ChangeToBoss))
	self:MarkIntaractCObj(pTowerBoss)
    self.m_pScrollView = pTowerBoss:getChildByName("ScrollView")
    self.m_pScrollView:setSwallowTouches(false)
    self.m_pScrollView:setScrollBarEnabled(false)
    self.m_pScrollView:jumpToBottom()
    for i=1,6 do
        table.insert(self.m_pBossTower, self.m_pScrollView:getChildByName("Tower_"..(i-1)))
        self.m_pBossTower[i]:setTag(i)
        self.m_pBossTower[i]:setTouchEnabled(true)
        self.m_pBossTower[i]:setSwallowTouches(false)
        self.m_pBossTower[i]:addClickEventListener(handler(self, NewTowerDelegate.ClickBoss))
		self:MarkIntaractCObj(self.m_pBossTower[i])
    end
    ------------------------------
    self.m_pLeftButton = panel:getChildByName("L")
    self.m_pLeftButton:addClickEventListener(handler(self, NewTowerDelegate.LeftButtonClick))
	self:MarkIntaractCObj(self.m_pLeftButton)

    self.m_pRightButton = panel:getChildByName("R")
    self.m_pRightButton:setVisible(false)
    self.m_pRightButton:addClickEventListener(handler(self, NewTowerDelegate.RightButtonClick))
	self:MarkIntaractCObj(self.m_pRightButton)
end
----------------------------------------------
function NewTowerDelegate:createModel(pModel, parent, pData, isPet, num, item, noTouch, noEffect)
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
        local item = Utils:GetItemCellValue(pItem, 0, pData, true, num ~= nil, num, nil, (noTouch == nil or noTouch == false))
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
----------------------------------------------
function NewTowerDelegate:OnTowerInfo(data)
    -- if self.m_isInit then
        Utils:FreeTable(self.m_data)
        self.m_data = nil
        self.m_data = data
        self:UpdateMonterTower()
        self:UpdateAnimNodeByState()
    -- else
    --     self.m_data2 = data
    -- end
    -- self.m_isInit = false
end
----------------------------------------------
function NewTowerDelegate:OnTowerKingData(data)
    Utils:FreeTable(self.towerKingInfo)
    self.towerKingInfo = nil
    self.towerKingInfo = data
    self:UpdateBossTower()
end
----------------------------------------------
function NewTowerDelegate:LeftButtonClick(sender)
    if self.m_state == TowerState.Monster then
        self:ChangeToBoss()
    elseif self.m_state == TowerState.Boss then
        self:ChangeToMonster()
    end
end
----------------------------------------------
function NewTowerDelegate:RightButtonClick(sender)
    self:ChangeToMonster()
end
----------------------------------------------
-- function NewTowerDelegate:SetStateChangeCallback(cb)
--     self.m_pCallback = cb
-- end
----------------------------------------------
function NewTowerDelegate:UpdateTower(pList, pData, pUpdate, startIndex)
    startIndex = startIndex or 1
    local cList = #pList
    local cData = #pData
    local idata = 1
    for i=startIndex,cList do
        if idata <= cData then
            pUpdate(pList[i], pData[idata], idata)
        else
            pUpdate(pList[i], nil, idata)
        end
        idata = idata + 1
    end
end
----------------------------------------------
function NewTowerDelegate:UpdateMonterTower()
    self:UpdateTower(self.m_pMonsterTower, self.m_data.mounsters, handler(self, NewTowerDelegate.UpdateOneMonster), 2)
    -- self:DrawHero(self.m_pMonsterTower[2])
end
----------------------------------------------
function NewTowerDelegate:UpdateBossTower()
    self:UpdateTower(self.m_pBossTower, self.towerKingInfo.classinfo, handler(self, NewTowerDelegate.UpdateOneBoss), 2)
end
----------------------------------------------
function NewTowerDelegate:UpdateOneMonster(pItem, data, ind)
    if pItem == nil then
        return
    end
    self:UpdateSelect(pItem, ind == self.m_selectMonster and data ~= nil)
    self:DrawMonster(pItem, data)
    pItem:setVisible(true)
end
----------------------------------------------
function NewTowerDelegate:UpdateOneBoss(pItem, data, ind)
    if pItem == nil or data == nil then
        return
    end
    self:UpdateSelect(pItem, ind == self.m_selectBoss)
    self:DrawBoss(pItem, data)

    pItem:setVisible(true)
end
----------------------------------------------
function NewTowerDelegate:UpdateSelect(pItem, isSelect)
    local pTower = pItem:getChildByName("Tower")
    pTower:setVisible(isSelect)
end
----------------------------------------------
function NewTowerDelegate:UpdateName(pItem, str)
    local pName = pItem:getChildByName("Name")
    pName:setString(str)
end
----------------------------------------------
function NewTowerDelegate:UpdateText(pItem, str)
    local pText = pItem:getChildByName("Text")
    pText:setString(str)
end
----------------------------------------------
function NewTowerDelegate:DrawHero(pItem)
    if pItem == nil then
        return
    end
    local pNode = pItem:getChildByName("Node")

    local pModel = pNode:getChildByName("Hero")
    if pModel == nil then
        pModel = ModelAniNode:create(AppDef.CEnum.ModelAniType.None, 0)
        pModel:setName("Hero")
        pNode:addChild(pModel)
    end 
    local hdata = LRoleDataMgr.MyHeroInfo
    pModel:InitAni(AppDef.CEnum.ModelAniType.Hero, hdata.professional, hdata:GetWeaponId(), hdata.LightEffect, 0, 0, 0)
    pModel:PlayStand(0)

    self:UpdateText(pItem, hdata.name)
end
----------------------------------------------
function NewTowerDelegate:DrawMonster(pItem, data)
    local pNode = pItem:getChildByName("Node")
    local pModel = pNode:getChildByName("Monster")
    if pModel == nil then
        pModel = ModelAniNode:create(AppDef.CEnum.ModelAniType.None, 0)
        pModel:setName("Monster")
        pNode:addChild(pModel)
    end
    if data then
        pModel:setVisible(true)
        pModel:InitAni(AppDef.CEnum.ModelAniType.Monster, data.pic)
        pModel:PlayStand(data.face)
        self:UpdateText(pItem, data.name)
    else
        pModel:setVisible(false)
        self:UpdateText(pItem, "")
    end
end
----------------------------------------------
function NewTowerDelegate:DrawBoss(pItem, data)
    if data == nil then
        return
    end
    local heros = data.heros
    if #heros <= 0 then 
        pItem:getChildByName("Name"):setVisible(false)
        self:UpdateText(pItem, string.format("第%d层霸主", data.class))
        return
    end
    local pNode = pItem:getChildByName("Node")
    local hero = heros[1]
    local model = ModelAniNode:create(AppDef.CEnum.ModelAniType.None, 0)
    model:setName("Hero")
    pNode:addChild(model)
    model:InitAni(AppDef.CEnum.ModelAniType.Hero, hero.professional, hero.heroWuqi, 0, 0, 0, 0)
    model:PlayStand(0)

    self:UpdateName(pItem, hero.name)
    self:UpdateText(pItem, string.format("第%d层霸主", data.class))
end
----------------------------------------------
function NewTowerDelegate:ClickBoss(sender)
    if sender == nil or self.m_state ~= TowerState.Boss then
        return
    end
    local tag = sender:getTag()
    if tag < 2 then
        return
    end

    local data = self.towerKingInfo.classinfo[tag - 1]
    if data == nil or data.heros == nil then
        return
    end

    if self.m_selectBoss > 0 then
        self:UpdateSelect(self.m_pBossTower[self.m_selectBoss + 1], false)
    end
    
    self.m_selectBoss = tag - 1

    if self.m_selectBoss > 0 then
        self:UpdateSelect(self.m_pBossTower[self.m_selectBoss + 1], true)
    end
    Utils:SendMsg(LUITowerEvent.TowerShowReward, self.m_selectBoss)
end
----------------------------------------------
function NewTowerDelegate:ChangeToMonster(sender)
    -- dump({self.m_state, self.m_timeline:isPlaying()}, "ChangeToMonster->")
    if self.m_state == TowerState.Monster or self.m_timeline:isPlaying() then
        return
    end
    self.m_timeline:play("animation2", false)
    self.m_state = TowerState.Monster
    Utils:SendMsg(LUITowerEvent.TowerStartChange, false)
end
----------------------------------------------
function NewTowerDelegate:ChangeToBoss(sender)
    -- dump({self.m_state, self.m_timeline:isPlaying()}, "ChangeToBoss->")
    if self.m_state == TowerState.Boss or self.m_timeline:isPlaying() then
        return
    end
    self.m_timeline:play("animation1", false)
    self.m_state = TowerState.Boss
    Utils:SendMsg(LUITowerEvent.TowerStartChange, true)
end
----------------------------------------------
function NewTowerDelegate:UpdateAnimNodeByState()
    local function _setVisible(pItem, isVisible)
        if pItem == nil then
            return
        end
        local pNode = pItem:getChildByName("Node")
        local _ = pNode and pNode:setVisible(isVisible)

        local pName = pItem:getChildByName("Name")
        local _ = pName and pName:setVisible(isVisible)

        local pText = pItem:getChildByName("Text")
        local _ = pText and pText:setVisible(isVisible)
    end
    for i=1,#self.m_pMonsterTower do
        local pItem = self.m_pMonsterTower[i]
        local isSelect = (self.m_state == TowerState.Monster) and ((self.m_selectMonster+1) == i)
        self:UpdateSelect(pItem, isSelect)
        _setVisible(pItem, self.m_state == TowerState.Monster)
    end
    for i=1,#self.m_pBossTower do
        local pItem = self.m_pBossTower[i]
        local isSelect = (self.m_state == TowerState.Boss) and ((self.m_selectBoss+1) == i)
        self:UpdateSelect(pItem, isSelect)
        _setVisible(pItem, self.m_state == TowerState.Boss)
    end
    self.m_pScrollView:setEnabled(self.m_state == TowerState.Boss)
end
----------------------------------------------
function NewTowerDelegate:FrameEventCallFunc(frame)
    if frame == nil then
        return
    end
    local index = frame:getFrameIndex()
    for k,v in pairs(animConfig) do
        local midIndex,endIndex = v[2],v[3]
        if midIndex and index == midIndex then
            self:UpdateAnimNodeByState()
        end
        -- if endIndex and index == endIndex then
        --     local _ = self.m_pCallback and self.m_pCallback(self.m_state == TowerState.Boss)
        -- end
    end
end
----------------------------------------------
function NewTowerDelegate:ShowMoveAnim()
    if self.m_data2 == nil or self.m_pTowerMonster == nil then
        return
    end
    self.m_pTowerMonster:stopAllActions()
    local arr = {}
    table.insert(arr, cc.DelayTime:create(0.25))
    table.insert(arr, cc.MoveBy:create(1, cc.p(0, -250)))
    local function moveFinish()
        self.m_data,self.m_data2 = self.m_data2
        self:UpdateMonterTower()
        self.m_pTowerMonster:setPositionY(self.m_initTowerPosY)
    end
    table.insert(arr, cc.CallFunc:create(moveFinish))
    self.m_pTowerMonster:runAction(cc.Sequence:create(arr))
end
----------------------------------------------
function NewTowerDelegate:ZhenFaClick(sender)
    if self.m_state == TowerState.Boss then
        return
    end
    if sender ~= nil then
        local tag = sender:getTag()
        -- self.m_data
        local data = {}
        data.index = tag
        data.type = 1
        Utils:SendMsg(LUITowerEvent.TowerShowDetailInfo, data)
    end
end
----------------------------------------------
function NewTowerDelegate:TuiJianClick(sender)
    if self.m_state == TowerState.Boss then
        return
    end
    if sender ~= nil then
        local tag = sender:getTag() - 100
        local data = {}
        data.index = tag
        data.type = 2
        Utils:SendMsg(LUITowerEvent.TowerShowDetailInfo, data)
    end
end
----------------------------------------------
return NewTowerDelegate