local LDCellUI = require("View.LuckyDraw.LDCellUI")

local LDTenRetUI = LUIBase:New()
LDTenRetUI.__index = LDTenRetUI
-------------------------------------
function LDTenRetUI:New(data)
    local o = {}
    setmetatable(o, LDTenRetUI)
    o:Init(data)
    return o
end
-------------------------------------
function LDTenRetUI:Init(data)
    self.Script = "LuckyDraw.LDTenRetUI"
    ------------------------------------------------
    self.m_data = nil
    self.m_pLDCellUIS = {}
    ------------------------------------------------
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    -----------------------------------------------
    if data then
        self:updateData(data)
    end
end
-------------------------------------
function LDTenRetUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    Utils:FreeTable(self.m_pLDCellUIS)
    self.m_pLDCellUIS = nil
    self.m_data = nil
end
-------------------------------------
function LDTenRetUI:InitUIControl()
    local pPanel = self.m_pUILayer:getChildByName("dancichoukaUI")
    -----------------------------------------------------------
    local pBg = pPanel:getChildByName("bg")
    pBg:setTouchEnabled(true)
    pBg:addClickEventListener(handler(self, LDTenRetUI.RemoveUI))
	self:MarkIntaractCObj(pBg)
    -----------------------------------------------------------
    for i=1,10 do
        local pSjNode = pPanel:getChildByName("shenjiang_"..i)
        local pDjNode = pPanel:getChildByName("Item_"..i)
        local pLevelBg = pSjNode:getChildByName("bg_Level")
        local pLDCellUI = LDCellUI:New({sjNode=pSjNode, djNode=pDjNode, levelBg=pLevelBg})
        table.insert(self.m_pLDCellUIS, pLDCellUI)
    end
end
-------------------------------------
function LDTenRetUI:RegistMsgs()
    self.msgIds = {
        LUILuckDrawEvent.ShowDrawResult
    }
    self:RegistSelf(self, self.msgIds)
end
-------------------------------------
function LDTenRetUI:ProcessEvent(msg)
    if msg.msgId == LUILuckDrawEvent.ShowDrawResult then
        self:updateData(msg.value)
    end
end
-------------------------------------
function LDTenRetUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
-------------------------------------
function LDTenRetUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/shilianchouLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

function LDTenRetUI:updateData(data)
    if data == nil or data.data == nil or data.data.items == nil or #data.data.items == 0 then
        return
    end
    local items = data.data.items
    self.m_data = items
    local audioPetId = nil
    local quality = 0
    ---------------------
    local time = 0.5
    local delay = 0
    ---------------------
    for i=1,#items do
        -------------------------------
        local pInfo = {}
        pInfo.petId = items[i].petId
        pInfo.petLevel = 1
        pInfo.petStar = items[i].petStar
        pInfo.tranItemId = items[i].transformId
        pInfo.tranItemNum = items[i].transformNum
        pInfo.itemId = items[i].itemId
        pInfo.itemNum = items[i].itemNum
        -------------------------------
        local _delay = (i-1)*time
        local pCell = self.m_pLDCellUIS[i]
        pCell:updateData(pInfo)
        pCell:StartAnim()
        -- performWithDelay(pCell.m_pUILayer, function(sender)
            
        -- end, _delay)
        -------------------------------
        if pInfo.petId > 0 and pInfo.tranItemId == 0 then
            if audioPetId == nil then
                audioPetId = pInfo.petId
                quality = pInfo.petStar
                delay = _delay
            elseif quality < pInfo.petStar then
                audioPetId = pInfo.petId
                quality = pInfo.petStar
                delay = _delay
            end
        end
        -------------------------------
    end

    if audioPetId and audioPetId > 0 then
        Utils:PlayPetAudioEffect(audioPetId)
        LGameMsg.m_audioMsg:Change(LAudioEvent.StopEffect)
        self:SendMsg(LGameMsg.m_audioMsg)
        if audioPetId == 36 then
            Utils:PlayEffect("GuideBGM", "id", 12, false, true)
        elseif audioPetId == 38 then
            Utils:PlayEffect("GuideBGM", "id", 8, false, true)
        elseif audioPetId == 40 then
            Utils:PlayEffect("GuideBGM", "id", 9, false, true)
        else
            Utils:PlayPetAudioEffect(audioPetId)
        end
    end
end

return LDTenRetUI