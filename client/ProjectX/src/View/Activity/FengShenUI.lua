local FengShenUI = LUIBase:New()
FengShenUI.__index = FengShenUI
----------------------------------
local animConfig = {
    [1] = {
        pos = {{x=667, y=375},{x=380, y=375},{x=300, y=375}},
        scale = {1,0.5},
    },
    [2] = {
        pos = {{x=1067, y=375},{x=950, y=375},{x=667, y=375}},
        scale = {0.5,1},
    },
    [3] = {
        pos = {{x=667, y=412.5},{x=950, y=392.5},{x=1067, y=375}},
        scale = {0.3,0.5},
        opacity = {51,255},
    },
    [4] = {
        pos = {{x=300, y=375},{x=500, y=395},{x=667, y=412.5}},
        scale = {0.5,0.3},
        opacity = {255,51},
    }
}
FengShenUI.IsHideInBattle = true
-----------------------------------
function FengShenUI:New(initTab)
    local o = {}
    setmetatable(o, FengShenUI)
    o:Init(initTab)
    return o
end

-----------------------------------
function FengShenUI:Init(initTab)
    self.Script = "Activity.FengShenUI"
    --------------------------------------------------
    self.m_initTab = initTab or 1
    self.m_datas = nil
    self.m_bossNodeVec = {}
    self.m_timeline = nil
    self.m_indexVec = {}
    --------------------------------------------------
    self.m_pRewardList = nil
    self.m_pRewardModel = nil
    self.m_pPetRewardModel = nil
    self.m_pPetList = nil
    self.m_pDesc = nil
    self.m_isInit = true
    --------------------------------------------------
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    --------------------------------------------------
    LuaNetSendMsg:QueryFengShen(1)
end

-----------------------------------
function FengShenUI:onExit()
    self:Destory()
    self.Script = nil
    self.m_initTab = nil
    self.m_datas = nil
    Utils:FreeTable(self.m_bossNodeVec)
    self.m_bossNodeVec = nil
    self.m_timeline = nil
    Utils:FreeTable(self.m_indexVec)
    self.m_indexVec = nil
    --------------------------------------------------
    self.m_pRewardList = nil
    self.m_pRewardModel = nil
    self.m_pPetRewardModel = nil
    self.m_pPetList = nil
    self.m_pDesc = nil
    self.m_isInit = nil
    self._bossId = nil
end

-----------------------------------
function FengShenUI:InitUIControl()
    local pPanel = self.m_pUILayer:getChildByName("Panel")
    ------------------------------------------------------
    local pPetList = pPanel:getChildByName("PetList")
    ------------------------------------------------------
    local pBtnL = pPetList:getChildByName("BtnL")
    pBtnL:setTag(1)
    pBtnL:addClickEventListener(handler(self, FengShenUI.ArrawBtnClick))
	self:MarkIntaractCObj(pBtnL)
    local pBtnR = pPetList:getChildByName("BtnR")
    pBtnR:setTag(2)
    pBtnR:addClickEventListener(handler(self, FengShenUI.ArrawBtnClick))
	self:MarkIntaractCObj(pBtnR)
    ------------------------------------------------------
    local pUILayer = cc.CSLoader:createNode("csd/FengShenLayer2.csb")
    pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(pUILayer)
    Utils:FreeTable(self.m_bossNodeVec, self.m_indexVec)
    self.m_indexVec = nil
    self.m_bossNodeVec = nil
    self.m_indexVec = {}
    self.m_bossNodeVec = {}
    for i=0,3 do
        local pBoss = pUILayer:getChildByName("PetBg_"..i)
        pBoss:setVisible(false)
        pBoss:retain()
        pBoss:removeFromParent(false)
        pPetList:addChild(pBoss)
        pBoss:release()
        table.insert(self.m_bossNodeVec, pBoss)
        table.insert(self.m_indexVec, i+1)
    end
    self:ResetZOrder()
    ------------------------------------------------------
    local pTitleBg = pPetList:getChildByName("TitleBg")
    pTitleBg:setLocalZOrder(1)

    local pCloseBtn = pPetList:getChildByName("CloseBtn")
    pCloseBtn:setLocalZOrder(1)
    pCloseBtn:addClickEventListener(handler(self, FengShenUI.RemoveUI))
	self:MarkIntaractCObj(pCloseBtn)
    ------------------------------------------------------
    local pReward = pPanel:getChildByName("Reward")
    local pRewardBg = pReward:getChildByName("RewardBg")
    self.m_pRewardList = pRewardBg:getChildByName("RewardList")
    self.m_pRewardModel = pRewardBg:getChildByName("Item")
    self.m_pPetRewardModel = pRewardBg:getChildByName("IconColor")

    self.m_pPetList = pRewardBg:getChildByName("PetList")
    -- self.m_pPetList:setTouchEnabled(false)
    ------------------------------------------------------
    local pDesc = pPanel:getChildByName("Desc")
    local pDescBg = pDesc:getChildByName("DescBg")
    self.m_pDesc = pDescBg:getChildByName("Text")
    self.m_pDesc:setString("")
    ------------------------------------------------------
end

function FengShenUI:ResetZOrder()
    local maxZOrder = #self.m_indexVec
    for i=1,#self.m_bossNodeVec do
        local ind = self:FindIndex(i)
        self.m_bossNodeVec[i]:setLocalZOrder(maxZOrder - ind)
        -- dump({maxZOrder - ind, ind, self.m_bossNodeVec[i]:getName()}, "zORder-->")
    end
    -- dump(self.m_indexVec, "self.m_indexVec-->")
end

-----------------------------------
function FengShenUI:RegistMsgs()
    self.msgIds = 
    {
        LUIFengShenEvent.LoadDataEvent,
        LUIRoleTeamEvent.TeamMemberChanged,
    }
    self:RegistSelf(self, self.msgIds)
end

-----------------------------------
function FengShenUI:ProcessEvent(msg)
    if msg.msgId == LUIFengShenEvent.LoadDataEvent then
        self:LoadData(msg.value)
        self.m_isInit = false
    elseif msg.msgId == LUIRoleTeamEvent.TeamMemberChanged then
        if self._bossId ~= nil then
            LuaNetSendMsg:QueryFengShen(2, self._bossId)
            self._bossId = nil
        end
    end
end

function FengShenUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
-----------------------------------
function FengShenUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/FengShenLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    self.m_timeline = cc.CSLoader:createTimeline("csd/FengShenLayer.csb")
    self.m_timeline:pause()
    self.m_pUILayer:runAction(self.m_timeline)
end
----------------------------------
function FengShenUI:LoadData(datas)
    -- dump(datas)
    --TODO:暂不支持传入的节点顺序，因为BUG1348
    -- if self.m_initTab and self.m_initTab > 1 then
    --     for i=1,#self.m_datas do
    --         if i == self.m_initTab then
    --             break
    --         end
    --         local temp = self.m_datas[1]
    --         table.remove(self.m_datas, 1)
    --         table.insert(self.m_datas, temp)
    --     end
    -- end

    if datas then
        --TODO:BUG1348可以打的两个boss需要前后挨着显示
        self:SortData(datas)

        local ncount = #self.m_bossNodeVec
        local dcount = #self.m_datas
        for i=1,math.max(ncount, dcount) do
            if i <= ncount then
                self:UpdateItem(self.m_bossNodeVec[i], self.m_datas[i], i)
            elseif i > dcount and self.m_bossNodeVec[i] ~= nil then
                self.m_bossNodeVec[i]:setVisible(false)
            end
        end
        if self.m_isInit then
            self:PlayCocosAnim("L_up")
            self:UpdateRewardInfo()
        end
    end
end
----------------------------------
function FengShenUI:SortData(datas)
    -------------------
    local dcount = #datas
    local open = {}
    local open2 = {}
    local close = {}
    for i=1,dcount do
        if datas[i].isOpen then
            if datas[i].times > 0 then
                table.insert(open, datas[i])
            else
                table.insert(open2, datas[i])
            end
        else
            table.insert(close, datas[i])
        end
    end
    -- dump(open, "open--->")
    -- dump(open2, "open2--->")
    -- dump(close, "close--->")
    -------------------
    for i=1,#open2 do
        table.insert(open, open2[i])
    end
    for i=1,#close do
        table.insert(open, close[i])
    end

    local isNeedRet = false
    if self.m_datas then
        local curData = self.m_datas[self.m_indexVec[1]]
        for i=1,#datas do
            if datas[i].bossId == curData.bossId then
                isNeedRet = datas[i].times <= 0
                break
            end
        end
        -- dump(curData, "curData--->")
        -- dump(self.m_indexVec, "self.m_indexVec--->")
        -- dump(isNeedRet, "isNeedRet--->")
        if isNeedRet then
            self:ResetAll()
        end
    end

    -- for i=1,#self.m_indexVec do
    --     local ind = self.m_indexVec[i]
    --     local pItem = self.m_bossNodeVec[ind]
    -- end
    Utils:FreeTable(self.m_datas)
    self.m_datas = nil
    self.m_datas = open
    if isNeedRet then
        self:UpdateRewardInfo()
    end
    -- dump(self.m_datas, "self.m_datas--->")
end
----------------------------------
function FengShenUI:ResetAll()
    for i=1,#self.m_bossNodeVec do
        local pItem = self.m_bossNodeVec[i]
        pItem:setPosition(animConfig[i].pos[1])
        pItem:setScale(animConfig[i].scale[1])
        pItem:setOpacity(animConfig[i].opacity and animConfig[i].opacity[1] or 255)
        self.m_indexVec[i] = i
    end
    self:ResetZOrder()
end
----------------------------------
function FengShenUI:FindIndex(tag)
    for i=1,#self.m_indexVec do
        if self.m_indexVec[i] == tag then
            return i
        end
    end
    return nil
end
----------------------------------
function FengShenUI:createModel(pModel, parent, pData, isPet, num, item, noTouch, noEffect)
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
----------------------------------
function FengShenUI:UpdateRewardInfo()
    if self.m_datas == nil or self.m_indexVec == nil then
        return
    end
    ----------------------------------
    local ind = self.m_indexVec[1]
    local data = self.m_datas[ind]
    if data == nil then
        return
    end
    self.m_pDesc:setString(data.desc)
    ----------------------------------
    self.m_pRewardList:removeAllItems()
    for i=1,#data.showAwardId do
        local pItem =self:createModel(self.m_pRewardModel, self.m_pRewardList, data.showAwardId[i], false)
        local _ = pItem and self.m_pRewardList:pushBackCustomItem(pItem)
    end
    ----------------------------------
    self.m_pPetList:removeAllItems()
    for i=1,#data.recommendPetId do
        local pItem =self:createModel(self.m_pPetRewardModel, self.m_pPetList, data.recommendPetId[i], true)
        local _ = pItem and self.m_pPetList:pushBackCustomItem(pItem)
    end
end
----------------------------------
function FengShenUI:PlayBossAnim(isReverse)
    for i=1,#self.m_bossNodeVec do
        local ind = self:FindIndex(i)
        if ind then
            if not isReverse then
                ind = math.fmod(ind, 4) + 1
            end
            -- dump({ind, self.m_bossNodeVec[i]:getName(), isReverse}, "ind------>")
            local ac = self:createCocosAnim(ind, animConfig[ind], self.m_bossNodeVec[i], isReverse)
            if ac then
                self.m_bossNodeVec[i]:stopAllActions()
                self.m_bossNodeVec[i]:runAction(ac)
            end
        end
    end
    self:ResetZOrder()
    performWithDelay(self.m_pUILayer, function(sender)
        self:PlayCocosAnim("L_up")
    end, 15/60)
    self:UpdateRewardInfo()
end
----------------------------------
function FengShenUI:ArrawBtnClick(sender)
    if sender == nil then
        return
    end
    local tag = sender:getTag()
    local toRight = tag == 1
    if toRight then
        -- dump(self.m_indexVec, "---------->")
        local ind = self.m_indexVec[#self.m_indexVec]
        table.remove(self.m_indexVec, #self.m_indexVec)
        table.insert(self.m_indexVec, 1, ind)
        -- dump(self.m_indexVec, "<-----------")
    else
        -- dump(self.m_indexVec, "---------->")
        local ind = self.m_indexVec[1]
        table.remove(self.m_indexVec, 1)
        table.insert(self.m_indexVec, ind)
        -- dump(self.m_indexVec, "<-----------")
    end
    self:PlayCocosAnim("L_down")
    performWithDelay(self.m_pUILayer, function(sender)
        self:PlayBossAnim(toRight)
    end, 25/60)
end
----------------------------------
function FengShenUI:PlayCocosAnim(key)
    if self.m_timeline == nil or key == nil then
        return
    end
    self.m_timeline:play(key, false)
end
----------------------------------
function FengShenUI:UpdateItem(pItem, data, ind)
    if pItem == nil or data == nil or ind == nil then
        return
    end
    pItem:setVisible(true)
    -- dump({pItem:getName(), data.name, ind}, "UpdateItem----->")
    ----------------------------------
    local pImageBase = pItem:getChildByName("ImageBase")
    local pImodNode = pImageBase:getChildByName("Node")

    pImodNode:removeAllChildren()
    local imod = Utils:CreateImod("Monster/btm"..data.pic.."_zd", cc.p(0,0), pImodNode, 1)
    imod:PlayActionRepeat(0)
    ----------------------------------
    local pNameBg = pItem:getChildByName("NameBg")
    local pName = pNameBg:getChildByName("Name")
    pName:setString(data.name or "")
    ----------------------------------
    local pClose = pItem:getChildByName("Close")
    pClose:setVisible(not data.isOpen)
    ----------------------------------
    local pFightBtn = pItem:getChildByName("FightBtn")
    if not data.isOpen then
        pFightBtn:setEnabled(false)
        pFightBtn:setBright(false)
    else
        pFightBtn:setTag(ind)
        pFightBtn:addClickEventListener(handler(self, FengShenUI.DoFight))
		self:MarkIntaractCObj(pFightBtn)
    end
    ----------------------------------
    local pTimes = pItem:getChildByName("Times")
    local pOpenTimes = pTimes:getChildByName("Text_1")
    local pCloseTimes = pTimes:getChildByName("Text_2")
    pOpenTimes:setVisible(data.isOpen)
    pCloseTimes:setVisible(not data.isOpen)
    if data.isOpen then
        local pNum = pOpenTimes:getChildByName("Num")
        pNum:setString(data.times)
    else
        local pNum = pCloseTimes:getChildByName("Num")
        local str = GUITips.RSI_COMMON_ZHOU

        for i=1,7 do
            local lMove = math.fmod(i, 7)
            local bValue = bit.lshift(0x01, lMove)
            local bRet = bit.band(data.openFlag, bValue)
            -- dump({ind, i, lMove, bValue, bRet}, "--------------------->")
            if Utils:ToBool(bRet) then
                str = str .. GUITipsWeek[i]
            end
        end
        pNum:setString(str)
    end
    ----------------------------------
end
----------------------------------
function FengShenUI:DoFight(sender)
    if sender == nil then
        return
    end
    local ind = sender:getTag()
    local data = self.m_datas[ind]
    -- if data.times <= 0 then
    --     Utils:ShowScrollTips(GUITips.RSI_FENGSHEN_TIPS1)
    --     return
    -- end
    local bossId = data.bossId
    if bossId then
        self._bossId = bossId
        if not self:teamEvent() then
            LuaNetSendMsg:QueryFengShen(2, bossId)
        end
    end
end
----------------------------------
function FengShenUI:teamEvent( ... )
    -- body
    if LRoleDataMgr.MyHeroInfo:IsTeam() then
        local function okFunc()
            LuaNetSendMsg:QueryLeaveTeam()
        end
        local function canelFunc()
            
        end
        Utils:ShowDialogOKCancel(GUITips.RSI_TARGET_RD_TIPS15, okFunc,canelFunc)
        return true
    end
    return false
end
----------------------------------
function FengShenUI:createCocosAnim(tag, cfg, pNode, isReverse)
    local action = nil
    local time = 15/60
    local viewsize = AppDef.frameSize
    if tag == 1 or tag == 2 then
        -----------------
        local start,mid,finish = 1,2,3
        if isReverse then
            start,finish = finish,start
        end
        local seqSubArr = {}
        table.insert(seqSubArr, cc.MoveTo:create(8/60, cc.p(cfg.pos[mid].x/1334*viewsize.width, cfg.pos[mid].y)))
        table.insert(seqSubArr, cc.MoveTo:create(7/60, cc.p(cfg.pos[finish].x/1334*viewsize.width, cfg.pos[finish].y)))
        -----------------
        local from,to = cfg.scale[1],cfg.scale[2]
        if isReverse then
            from,to = to,from
        end
        local spawnArr = {}
        table.insert(spawnArr, cc.Sequence:create(seqSubArr))
        table.insert(spawnArr, cc.ScaleTo:create(time, to))
        -----------------
        local seqArr = {}
        table.insert(seqArr, cc.CallFunc:create(function()
            pNode:setOpacity(255)
            pNode:setScale(from)
            pNode:setPosition(cc.p(cfg.pos[start].x/1334*viewsize.width, cfg.pos[start].y))
        end))
        table.insert(seqArr, cc.Spawn:create(spawnArr))
        local _ = callback and table.insert(seqArr, cc.CallFunc:create(callback))
        action = cc.Sequence:create(seqArr)
    else
        local start,mid,finish = 1,2,3
        if isReverse then
            start,finish = finish,start
        end
        local seqSubArr = {}
        table.insert(seqSubArr, cc.MoveBy:create(8/60, cc.p((cfg.pos[mid].x-cfg.pos[start].x)/1334*viewsize.width, 0)))
        table.insert(seqSubArr, cc.MoveBy:create(7/60, cc.p((cfg.pos[finish].x-cfg.pos[mid].x)/1334*viewsize.width, 0)))
        -----------------
        local from,to = cfg.scale[1],cfg.scale[2]
        if isReverse then
            from,to = to,from
        end
        local spawnArr = {}
        table.insert(spawnArr, cc.Sequence:create(seqSubArr))
        table.insert(spawnArr, cc.MoveBy:create(time, cc.p(0, cfg.pos[finish].y-cfg.pos[start].y)))
        table.insert(spawnArr, cc.ScaleTo:create(time, to))
        local fadeArr = {}
        local startOp,finishOp = cfg.opacity[1],cfg.opacity[2]
        if isReverse then
            startOp,finishOp = finishOp,startOp
        end
        if tag == 4 or (tag == 3 and isReverse) then
            table.insert(fadeArr, cc.DelayTime:create(8/60))
        end
        table.insert(fadeArr, cc.FadeTo:create(7/60, finishOp))
        if tag == 3 or (tag == 4 and isReverse) then
            table.insert(fadeArr, cc.DelayTime:create(8/60))
        end
        table.insert(spawnArr, cc.Sequence:create(fadeArr))
        -----------------
        local seqArr = {}
        table.insert(seqArr, cc.CallFunc:create(function()
            pNode:setOpacity(startOp)
            pNode:setScale(from)
            pNode:setPosition(cc.p(cfg.pos[start].x/1334*viewsize.width, cfg.pos[start].y))
        end))
        table.insert(seqArr, cc.Spawn:create(spawnArr))
        local _ = callback and table.insert(seqArr, cc.CallFunc:create(callback))
        action = cc.Sequence:create(seqArr)
    end
    return action,name
end
----------------------------------
return FengShenUI