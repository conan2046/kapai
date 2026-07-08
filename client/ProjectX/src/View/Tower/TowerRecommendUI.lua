local TowerRecommendUI = LUIBase:New()
TowerRecommendUI.__index = TowerRecommendUI
TowerRecommendUI.IsHideInBattle = true

local Type = {
    ["Enemy"] = 1,
    ["Recommend"] = 2,
}
----------------------------------------------
function TowerRecommendUI:New()
    local o = {}
    setmetatable(o, TowerRecommendUI)
    o:Init()
    return o
end
----------------------------------------------
function TowerRecommendUI:Init()
    self.Script = "Tower.TowerRecommendUI"
    self.m_pMonsterVec = {}
    self.m_pMonsterBgVec = {}
    ----------------------------------------------
    self:InitViewSize()
    self:InitUIControl()
    self:RegisterQuik()
    self:RegistMsgs()
    ----------------------------------------------
end
----------------------------------------------
function TowerRecommendUI:RegistMsgs()
    self.msgIds = 
    {
        LUITowerEvent.TowerInfo,
        LUITowerEvent.TowerShowDetailInfo,
    }
    self:RegistSelf(self,self.msgIds)
end
----------------------------------------------
function TowerRecommendUI:ProcessEvent(msg)
    if msg.msgId == LUITowerEvent.TowerInfo then
        self.m_data = msg.value
    elseif msg.msgId == LUITowerEvent.TowerShowDetailInfo then
        self:DealTowerShowDetailInfo(msg.value)
    end
end
----------------------------------------------
function TowerRecommendUI:onExit()
    self:Destory()
    self.m_data = nil
    self.m_pUILayer = nil
    self.m_pPanel = nil
    self.m_pEnemyTitle = nil
    self.m_pRecommendTitle = nil
    self.m_pZhenFaImage = nil
    self.m_pListView = nil
    self.m_pItemModel = nil
    Utils:FreeTable(self.m_pMonsterVec, self.m_pMonsterBgVec)
    self.m_pMonsterVec = nil
    self.m_pMonsterBgVec = nil
end
----------------------------------------------
function TowerRecommendUI:RegisterQuik()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
----------------------------------------------
function TowerRecommendUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/TowerLayer4.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end
----------------------------------------------
function TowerRecommendUI:InitUIControl()
    self.m_pPanel = self.m_pUILayer:getChildByName("Panel")
    --------------------------------------------
    self.m_pPanel:addClickEventListener(handler(self, TowerRecommendUI.HideUI))
    self:MarkIntaractCObj(self.m_pPanel)
    --------------------------------------------
    local pTeamBg = self.m_pPanel:getChildByName("TeamBg")
    --------------------------------------------
    self.m_pEnemyTitle = pTeamBg:getChildByName("Title_1")
    self.m_pRecommendTitle = pTeamBg:getChildByName("Title_2")
    --------------------------------------------
    self.m_pZhenFaImage = pTeamBg:getChildByName("Zhenfa")
    --------------------------------------------
    local pFormation = pTeamBg:getChildByName("Formation")

    if self.m_pMonsterVec then
        Utils:FreeTable(self.m_pMonsterVec, self.m_pMonsterBgVec)
        self.m_pMonsterVec = nil
        self.m_pMonsterBgVec = nil
    end
    self.m_pMonsterVec = {}
    self.m_pMonsterBgVec = {}
    for i=1,9 do
        local pPos = pFormation:getChildByName("Position"..i)
        table.insert(self.m_pMonsterBgVec, pPos)

        local pIcon = pPos:getChildByName("IconColor")
        pIcon:setTouchEnabled(true)
        pIcon:addClickEventListener(handler(self, TowerRecommendUI.MonsterClick))
        self:MarkIntaractCObj(pIcon)
        table.insert(self.m_pMonsterVec, pIcon)
    end
    --------------------------------------------
    self.m_pPanel:setVisible(false)
end
----------------------------------------------
function TowerRecommendUI:DealTowerShowDetailInfo(info)
    if info == nil or info.index == nil or info.type == nil then
        return
    end
    if self.m_data.classMounster == nil or self.m_data.classMounster[info.index] == nil then
        return
    end
    if self.m_index ~= info.index or self.m_type ~= info.type then
        self.m_index = info.index
        self.m_type = info.type
        self:ShowTitle()
        self:ShowZhenFa()
        self:CreateMonsters()
    end
    self:ShowUI()
end
----------------------------------------------
function TowerRecommendUI:HideUI(sender)
    if self.m_pPanel ~= nil then
        self.m_pPanel:setVisible(false)
    end
end
----------------------------------------------
function TowerRecommendUI:ShowUI(sender)
    if self.m_pPanel ~= nil then
        self.m_pPanel:setVisible(true)
    end
end
----------------------------------------------
function TowerRecommendUI:ShowTitle()
    if self.m_type == Type.Enemy then
        self.m_pEnemyTitle:setVisible(true)
        self.m_pRecommendTitle:setVisible(false)
        local pText = self.m_pEnemyTitle:getChildByName("Text")
        if pText ~= nil then
            pText:setText(self.m_data.currClass + self.m_index)
        end
    elseif self.m_type == Type.Recommend then
        self.m_pEnemyTitle:setVisible(false)
        self.m_pRecommendTitle:setVisible(true)
    end
end
----------------------------------------------
function TowerRecommendUI:ShowZhenFa()
    local fid = nil
    if self.m_type == Type.Enemy then
        local data = self.m_data.classMounster[self.m_index]
        fid = data and data.fid or nil
    elseif self.m_type == Type.Recommend then

    end
    if fid then
        local iconRes = AppDef.Formation.IconRes .. fid .. ".png"
        self.m_pZhenFaImage:loadTexture(iconRes, UI_TEX_TYPE_LOCAL)

        local data = LDataConstMgr:GetFormationDataById(fid)
        if data then
            local pText = self.m_pZhenFaImage:getChildByName("Text")
            pText:setString(data.name or "")
        end
    end
end
----------------------------------------------
function TowerRecommendUI:CreateMonsters()
    local datas = nil
    if self.m_type == Type.Enemy then
        datas = self.m_data.classMounster[self.m_index].mounsters
    elseif self.m_type == Type.Recommend then
    end
    if datas == nil then
        return
    end

    local fid = nil
    if self.m_type == Type.Enemy then
        local data = self.m_data.classMounster[self.m_index]
        fid = data and data.fid or nil
    elseif self.m_type == Type.Recommend then

    end
    if fid == nil then
        for i=1,#self.m_pMonsterVec do
            self.m_pMonsterVec[i]:setVisible(false)
        end
        return
    end

    local fData = LDataConstMgr:GetFormationDataById(fid)
    if fData == nil then
        for i=1,#self.m_pMonsterVec do
            self.m_pMonsterVec[i]:setVisible(false)
        end
        return
    end
    local posCount = #fData.posList
    local dataCount = #datas

    local temp = {}
    for i=1,#self.m_pMonsterVec do
        temp[i] = self.m_pMonsterVec[i]
    end

    for i=1,posCount do
        local pos = fData.posList[i]
        local pItem = temp[pos]
        if i <= dataCount then
            if pItem then
                pItem:setVisible(true)
                self:UpdateMonster(pItem, datas[i], pos)
                self:UpdateMonsterBg(self.m_pMonsterBgVec[pos], i)
                temp[pos] = nil
            end
        end
    end
    for k,v in pairs(temp) do
        local pos = k
        if v ~= nil then
            v:setVisible(false)
        end
        self:UpdateMonsterBg(self.m_pMonsterBgVec[pos])
    end
end
----------------------------------------------
function TowerRecommendUI:UpdateMonster(pItem, pData, pos)
    if pItem == nil or pData == nil then
        return
    end
    if pData.id then
        pItem:setTag(pData.id)
    end

    if pData.pic then
        local headImg = pItem:getChildByName("Icon")
        Utils:ShowPetHeadImg(headImg, pData.pic, pItem, pData.quality)
    end

    if pData.quality then
        local scoreImage = pItem:getChildByName("Quality")
        AppDef:GetPetQualityScore(scoreImage, pData.quality)
    end
    
    if pData.data and pData.data.type then
        local typeImage = pItem:getChildByName("Career")
        AppDef:ShowPetType(typeImage, pData.data.type)
    end

    if pData.level then
        local label = pItem:getChildByName("Text")
        label:setString(pData.level or "")
    end

    -- local pEffect = pItem:getChildByName("Effect")
    -- if pData.quality >= 3 then
    --     if pEffect == nil then
    --         local posX = pItem:getContentSize().width / 2
    --         local posY = pItem:getContentSize().height / 2
    --         local pEffect = Utils:createAnimEffect(pItem, cc.p(posX, posY), "res2/fx/gaojiwupin")
    --         if pEffect ~= nil then
    --             pEffect:setName("Effect")
    --         end
    --     else
    --         pEffect:setVisible(true)
    --     end
    -- else
    --     if pEffect ~= nil then
    --         pEffect:setVisible(false)
    --     end
    -- end
end
----------------------------------------------
function TowerRecommendUI:UpdateMonsterBg(pItem, pos)
    if pItem == nil then
        return
    end
    local pNumBg = pItem:getChildByName("bg_Num")
    if pNumBg ~= nil then
        if pos then
            pItem:setOpacity(255)
            pNumBg:setVisible(true)
            pNumBg:getChildByName("Value"):setString(pos)
        else
            pNumBg:setVisible(false)
            pItem:setOpacity(100)
        end
    end
end
----------------------------------------------
function TowerRecommendUI:MonsterClick(sender)
    if sender == nil then
        return
    end
    local mid = sender:getTag()
    if mid > 0 then
        local level = nil
        local datas = self.m_data.classMounster[self.m_index].mounsters
        for i=1,#datas do
            if datas[i].id == mid then
                level = datas[i].level
                break
            end
        end
        Utils:SendMsg(LUILogicEvent.ShowMonsterInfo, {id=mid, level=level})
    end
end
----------------------------------------------
return TowerRecommendUI



