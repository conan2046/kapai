local LDCellUI = require("View.LuckyDraw.LDCellUI")

local LDSingleRetUI = LUIBase:New()
LDSingleRetUI.__index = LDSingleRetUI
--战斗中是否隐藏
LDSingleRetUI.IsHideInBattle = true

LDSingleRetUI.continueCb = nil
LDSingleRetUI.castId = 0
LDSingleRetUI.isDrawInit = false

-------------------------------------
function LDSingleRetUI:New(data)
    local o = {}
    setmetatable(o, LDSingleRetUI)
    o:Init(data)
    return o
end
-------------------------------------
function LDSingleRetUI:Init(data)
    self.Script = "LuckyDraw.LDSingleRetUI"
    ------------------------------------------------
    self.m_dataVec = {} --获得的神将列表
    self.m_isAniming = false
    ------------------------------------------------
    self.m_pLDCellUI = nil
    self.m_pChildren = {}
    ------------------------------------------------
    self.m_pbtn_Continue = nil
    self.m_pTitle = nil
    self.m_pBg = nil
    ------------------------------------------------
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()

    -----------------------------------------------
    if data then
        self:UpdateUserData(data)
    end
    LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.AutoPathEvent.PauseAutoPath)
    self:SendMsg(LGameMsg.m_cBaseMsg)
end
-------------------------------------
function LDSingleRetUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_dataVec =  nil
    self.m_isAniming = nil
    self.m_pContinueCallback = nil
    Utils:FreeTable(self.m_pChildren)
    self.m_pChildren = nil
    self.m_pLDCellUI = nil
    self.m_pbtn_Continue = nil
    self.m_pTitle = nil
    self.m_pBg = nil
    self.m_pClose = nil
    LDSingleRetUI.continueCb = nil
    LDSingleRetUI.castId = 0
    LDSingleRetUI.isDrawInit = false
    
    performWithDelay(AppDef.Director:getRunningScene(),function(sender)
        Utils:SendMsg(LUIGetPetWingEvent.CheckNext, nil, true)
        LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.AutoPathEvent.ReStartAutoPath)
        self:SendMsg(LGameMsg.m_cBaseMsg)
    end, 0)
end
-------------------------------------
function LDSingleRetUI:InitUIControl()
    local pPanel = self.m_pUILayer:getChildByName("dancichoukaUI")
    -----------------------------------------------------------
    self.m_pChildren = pPanel:getChildren()
    self.m_pTitle = pPanel:getChildByName("Text")
    self.m_pBg = pPanel:getChildByName("bg")
    self.m_pClose = pPanel:getChildByName("Close")
    -----------------------------------------------------------
    local pBg = self.m_pBg
    pBg:setTouchEnabled(true)
    pBg:addClickEventListener(handler(self, LDSingleRetUI.checkNext))
	self:MarkIntaractCObj(pBg)
    pBg:setOpacity(50)
    pBg:runAction(cc.FadeTo:create(0.1, 255))
    for i=1,#self.m_pChildren do
        if self.m_pChildren[i] == pBg then
            table.remove(self.m_pChildren, i)
            break
        end
    end
    -----------------------------------------------------------
    local pSjNode = pPanel:getChildByName("shenjiang")
    local pDjNode = pPanel:getChildByName("Item")
    local pLevelBg = pPanel:getChildByName("bg_Level")
    self.m_pLDCellUI = LDCellUI:New({sjNode=pSjNode, djNode=pDjNode, levelBg=pLevelBg})
    self.m_pLDCellUI:SetAnimFinishCallback(handler(self, LDSingleRetUI.animFinished))
    -----------------------------------------------------------
    local pbtn_Continue = pPanel:getChildByName("btn_Continue")
    pbtn_Continue:addClickEventListener(handler(self, LDSingleRetUI.continueCallback))
	self:MarkIntaractCObj(pbtn_Continue)
    self.m_pbtn_Continue = pbtn_Continue
    -----------------------------------------------------------
    self.m_pSkill = pPanel:getChildByName("Skill")
    for i=1,4 do
        local pSkill = self.m_pSkill:getChildByName("Skill_"..i)
        pSkill:addClickEventListener(handler(self, LDSingleRetUI.SkillClick))
        pSkill:getChildByName("Icon"):setScale(0.85)
    end
    self.m_pSuipian = pPanel:getChildByName("Suipian")
    -----------------------------------------------------------
    if LDSingleRetUI.isDrawInit then
        self:RegisterGuide()
    end
end

function LDSingleRetUI:RegisterGuide()
    --------------------------------------------
    local data = LDataConstMgr:GetGuideData(GuideDef.StepId.Guide_ZM_2)
    Utils:RegisterGuide(GuideDef.StepId.Guide_ZM_2, nil, handler(self, LDSingleRetUI.RemoveUI), data.maskOffset, true)
end
-------------------------------------
function LDSingleRetUI:RegistMsgs()
    self.msgIds = {
        LUILuckDrawEvent.ShowDrawResult
    }
    self:RegistSelf(self, self.msgIds)
end
-------------------------------------
function LDSingleRetUI:ProcessEvent(msg)
    if msg.msgId == LUILuckDrawEvent.ShowDrawResult then
        self:updateData(msg.value)
    end
end
-------------------------------------
function LDSingleRetUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
-------------------------------------
function LDSingleRetUI:InitViewSize()
    self:CreateUINode("csd/danciLayer.csb")
    self.m_pUILayer:setVisible(true)
end

function LDSingleRetUI:setContinueCallback(cb, castId)
    self.m_pContinueCallback = cb
    if cb then
        self:updateCast(castId)
        self.m_pbtn_Continue:setVisible(true)
    else
        self.m_pbtn_Continue:setVisible(false)
    end
end

function LDSingleRetUI:continueCallback(sender)
    local temp = self.m_pContinueCallback
    self.m_dataVec = {}
    self:RemoveUI()
    if temp then
        temp()
    end
end

function LDSingleRetUI:UpdateUserData(data)
    if data == nil then
        return
    end
    table.insert(self.m_dataVec, data)
    if not self.m_isAniming then
        self:checkNext(nil)
    end
end

function LDSingleRetUI:updateCast(castId)
    local itemCfg = LItemMgr:getItem(castId)
    if itemCfg == nil then
        return
    end
    local str = "item/equip" .. itemCfg.m_pic .. ".png"

    local pIcon = self.m_pbtn_Continue:getChildByName("Icon")
    pIcon:loadTexture(str, ccui.TextureResType.localType)

    local num = LRoleDataMgr.Equip:CountItemNumById(castId)
    local pValue = self.m_pbtn_Continue:getChildByName("Value")
    pValue:setString(string.format("%d/%d", num, 1))
end

--[[
检查显示下一个
]]
function LDSingleRetUI:checkNext(sender)
    if self.m_isAniming then
        return
    end
    if #self.m_dataVec == 0 then
        self:RemoveUI()
        return
    end
    local data = self.m_dataVec[1]
    if data then
        self:Reset()
        local havePet = Utils:ToBool(data.petId)
        local isTransform = Utils:ToBool(data.tranItemId)
        local isShow = havePet and (not isTransform)
        self.m_pTitle:setVisible(isShow)
        self.m_pLDCellUI:updateData(data)
        self:StartAnim()
        self:UpdateSkill(data)
        self:UpdateSuiPian(data)
        if isShow then
            LGameMsg.m_audioMsg:Change(LAudioEvent.StopEffect)
            self:SendMsg(LGameMsg.m_audioMsg)
            if data.petId == 36 then
                Utils:PlayEffect("GuideBGM", "id", 12, false, true)
            elseif data.petId == 38 then
                Utils:PlayEffect("GuideBGM", "id", 8, false, true)
            elseif data.petId == 40 then
                Utils:PlayEffect("GuideBGM", "id", 9, false, true)
            else
                Utils:PlayPetAudioEffect(data.petId)
            end
        elseif (not havePet) then
            LGameMsg.m_audioMsg:Change(LAudioEvent.PlayEffect, AppDef.SysBGM.Pet_Card)
            self:SendMsg(LGameMsg.m_audioMsg)
        end
    end
    table.remove(self.m_dataVec, 1)
end

function LDSingleRetUI:Reset()
    for i=1,#self.m_pChildren do
        self.m_pChildren[i]:setVisible(false)
    end
end

function LDSingleRetUI:StartAnim()
    self.m_isAniming = true
    self.m_pLDCellUI:StartAnim()
end

function LDSingleRetUI:animFinished()
    self:setContinueCallback(LDSingleRetUI.continueCb, LDSingleRetUI.castId)
    self.m_pClose:setVisible(true)
    self.m_isAniming = false
end

function LDSingleRetUI:UpdateSkill(data)
    if data == nil or self.m_pSkill == nil then
        return
    end
    local petId = data.petId
    if petId == nil and data.itemId then
        local info = LDataConstMgr:GetPetCpdDataByItemId(data.itemId)
        petId = info.targetId - 60002
    end
    if petId == nil then
        self.m_pSkill:setVisible(false)
        return
    end
    local data = LDataConstMgr:GetPetData(petId)
    if data == nil or data.skills == nil then
        self.m_pSkill:setVisible(false)
        return
    end
    local index = 1
    for i=1,#data.skills do
        index = index + 1
        local skid = data.skills[i]
        local pSkill = self.m_pSkill:getChildByName("Skill_"..i)
        self:ShowSkill(pSkill, skid)
    end
    for i=index,4 do
        local pSkill = self.m_pSkill:getChildByName("Skill_"..i)
        if pSkill then
            pSkill:setTag(0)
            pSkill:setVisible(false)
        end
    end
    self.m_pSkill:setVisible(true)
end

function LDSingleRetUI:ShowSkill(pSkill, skid)
    if pSkill == nil or skid == nil then
        return
    end
    local skillInfo = LDataConstMgr:GetSkillDetailList(skid)
    if skillInfo == nil then
        pSkill:setTag(0)
        pSkill:setVisible(false)
        return
    end
    local pIcon = pSkill:getChildByName("Icon")
    pIcon:loadTexture(string.format("Skill/UI/skill_%d.png", skid), UI_TEX_TYPE_LOCAL)

    local pName = pSkill:getChildByName("Name")
    pName:setString(skillInfo.name or "")
    pSkill:setVisible(true)
    pSkill:setTag(skid)
end

function LDSingleRetUI:UpdateSuiPian(data)
    if data == nil or self.m_pSuipian == nil then
        return
    end
    if data.petId and data.tranItemId == nil then
        self.m_pSuipian:setVisible(false)
        return
    end

    local itemId = data.itemId or data.tranItemId
    if itemId == nil and data.petId then
        local info = LDataConstMgr:GetPetData(data.petId)
        itemId = info.itemId
    end
    if itemId == nil then
        self.m_pSuipian:setVisible(false)
        return
    end
    local pInfo = LDataConstMgr:GetPetCpdDataByItemId(itemId)
    if pInfo == nil or pInfo.itemNum == nil or pInfo.itemNum <= 0 then
        self.m_pSuipian:setVisible(false)
        return
    end

    local count = LRoleDataMgr.Equip:CountItemNumById(itemId)
    local max = pInfo.itemNum

    local pLoadingBar = self.m_pSuipian:getChildByName("LoadingBar")
    pLoadingBar:setPercent(math.floor(count*100/max))

    local pNum = pLoadingBar:getChildByName("Num")
    pNum:setString(string.format("%d/%d", count, max))

    self.m_pSuipian:setVisible(true)
end

function LDSingleRetUI:SkillClick(sender)
    if sender == nil then
        return
    end
    local skid = sender:getTag()
    if skid > 0 then
        local userdata = 
        {
            itemType = "CPetSkill",
            itemData = LSkillMgr:getSkillById(skid),
            -- pos = ind,
            -- petQuality = self.m_pPetData.quality
        }
        Utils:SendMsg(LUILogicEvent.ShowItemInfo, userdata)
    end
end

return LDSingleRetUI