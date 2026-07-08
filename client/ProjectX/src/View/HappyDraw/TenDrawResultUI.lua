local LDCellUI = require("View.LuckyDraw.LDCellUI")

local TenDrawResultUI = LUIBase:New()
TenDrawResultUI.__index = TenDrawResultUI
-------------------------------------
function TenDrawResultUI:New(data)
    local o = {}
    setmetatable(o, TenDrawResultUI)
    o:Init(data)
    return o
end
-------------------------------------
function TenDrawResultUI:Init(data)
    self.Script = "HappyDraw.TenDrawResultUI"
    ------------------------------------------------
    self.m_data = nil
    self.m_pLDCellUIS = {}
    ------------------------------------------------
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    -----------------------------------------------
    PetkaPaiManager.m_curDarwType = 0 --重置
    if data then
        self:updateData(data)
    end
end
-------------------------------------
function TenDrawResultUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    Utils:FreeTable(self.m_pLDCellUIS)
    self.m_pLDCellUIS = nil
    self.m_data = nil
    PetkaPaiManager.m_isInTenDrawResult = false
end
-------------------------------------
function TenDrawResultUI:InitUIControl()
    local pPanel = self.m_pUILayer:getChildByName("dancichoukaUI")
    -----------------------------------------------------------
    local pBg = pPanel:getChildByName("bg")
    pBg:setTouchEnabled(true)
    pBg:addClickEventListener(handler(self, TenDrawResultUI.RemoveUI))
    self:MarkIntaractCObj(pBg)

    ---------------------------------------------------------------------
    local Congratulations = pPanel:getChildByName("Congratulations")
    self._shenhun = Congratulations:getChildByName("shenhun")
    -- self._shenhun:setVisible(false)
    -------------------------------------------------------------------
    local btnClose = self.m_pUILayer:getChildByName("btn_Close")
    self:MarkIntaractCObj(btnClose)
    self._close = btnClose
    btnClose:addClickEventListener(function ( sender )
        -- body
        self:RemoveUI()
    end)
    -----------------------------------------------------------
    local pbtn_Continue = self.m_pUILayer:getChildByName("btn_Continue")
    pbtn_Continue:addClickEventListener(handler(self, TenDrawResultUI.continueCallback))
    self:MarkIntaractCObj(pbtn_Continue)
    self.m_pbtn_Continue = pbtn_Continue

    -----------------------------------------------------------
    for i=1,10 do
        local shenjiang = pPanel:getChildByName("shenjiang_"..i)
        local pSjNode = shenjiang:getChildByName("Node")
        local pDjNode = pPanel:getChildByName("Item_"..i)
        local pLevelBg = shenjiang:getChildByName("bg_Level")
        local pLDCellUI = LDCellUI:New({sjNode=pSjNode, djNode=pDjNode, levelBg=pLevelBg})
        table.insert(self.m_pLDCellUIS, pLDCellUI)
    end
    PetkaPaiManager.m_isInTenDrawResult = true

    -- Utils:PlayAction("csd/chouka/shilianchouka.csb", 0, 100, 100, nil)

    self.m_timeline = cc.CSLoader:createTimeline("csd/chouka/shilianchouka.csb")
    self.m_pUILayer:runAction(self.m_timeline)
    self.m_timeline:gotoFrameAndPlay(0, false)
    self._isPlaying = true
    self.m_pbtn_Continue:setTouchEnabled(false)
    self.m_pbtn_Continue:setBright(false)
    local function onCloseFrame()
        -- print("overAction ==== 1111111111111 >")
        self._isPlaying = false
        self.m_pbtn_Continue:setTouchEnabled(true)
        self.m_pbtn_Continue:setBright(true)
    end
    self.m_timeline:setAnimationEndCallFunc("animation0", onCloseFrame)

	local effect = pPanel:getChildByName("effect_zhaomu_5")
	local effcet = self:SetEffect()
    effcet:setName("effcet") 
    effect:addChild(effcet)	

end
-------------------------------------
function TenDrawResultUI:RegistMsgs()
    self.msgIds = {
        LUIDrawEvent.continueDrawSuc
    }
    self:RegistSelf(self, self.msgIds)
end
-------------------------------------
function TenDrawResultUI:ProcessEvent(msg)
    if msg.msgId == LUIDrawEvent.continueDrawSuc then
        self:updateData(msg.value)
        self:performDrawEvent()
    end
end
-------------------------------------

function TenDrawResultUI:continueCallback(sender)
    -- body
    if self._isPlaying then
        print("continueCallback playing ===>")
        -- Utils:ShowScrollTips(GUITips.UI_KunLun_Draw_Tips)
        return
    end
    -- dump(self.m_data, "continueCallback === 111111111111 >> ")
    self._isPlaying = true
    self.m_pbtn_Continue:setTouchEnabled(false)
    self.m_pbtn_Continue:setBright(false)
    LuaNetSendMsg:SendExtractPetMsg(2, self.m_data.kind, AppDef.DrawType.TenDraw)
    -- self:RemoveUI()
end

function TenDrawResultUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

function TenDrawResultUI:performDrawEvent( ... )
    -- body
    performWithDelay(self.m_pUILayer, function(sender)
        if self._isPlaying then
            self._isPlaying = false
            self.m_pbtn_Continue:setTouchEnabled(true)
            self.m_pbtn_Continue:setBright(true)
        end
    end, 1)
end

-------------------------------------
function TenDrawResultUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/chouka/shilianchouka.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

function TenDrawResultUI:updateData(data)
    if data == nil or data.items == nil or #data.items == 0 then
        return
    end
    local items = data.items

    -- dump(items, "TenDrawResultUI:updateData 111111111111 ===>")

    self.m_data = data

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

        -- dump(pInfo, "TenDrawResultUI ===================== >")

        pCell:updateData(pInfo)
        pCell:StartAnim()
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

    self:updateContiniuBtn()

    local num = PetkaPaiManager:getObtainDrawShenHun()
    local strTips = string.format(GUITips.RSI_ZQX_CHOUKA_TIPS5, num) .. GUITips.RSI_ML_TIP15
    self._shenhun:setString(strTips)

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

function TenDrawResultUI:SetEffect()
    local bgAnim = "res2/animation/effect_zhaomu_5"
    local m_pBgAni = ImodAnim:create()
    m_pBgAni:initAnimWithNameSync(bgAnim)
    m_pBgAni:PlayActionRepeat(0)
    m_pBgAni:setScale(scale or 1)
    return m_pBgAni
end

function TenDrawResultUI:updateContiniuBtn( ... )
    -- body
    local icon = self.m_pbtn_Continue:getChildByName("Icon")
    local Value = self.m_pbtn_Continue:getChildByName("Value")
    local itemID = PetkaPaiManager.m_curDarwKind + 999
    local num = LRoleDataMgr.Equip:CountItemNumById(itemID)
    Utils:GetItemCellValue(icon,0,itemID,true,true,num,nil,true,true)
    local needNum = 10
    if PetkaPaiManager.m_curDarwKind == 3 then
        needNum = 100
    end
    Value:setString(string.format("%d/%d", num, needNum))
end

return TenDrawResultUI