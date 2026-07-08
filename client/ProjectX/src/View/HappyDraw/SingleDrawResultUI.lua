local LDCellUI = require("View.LuckyDraw.LDCellUI")

local TimerLabelUI = require("View.Common.TimerLabelUI")

local SingleDrawResultUI = LUIBase:New()
SingleDrawResultUI.__index = SingleDrawResultUI
--local this = LTcpSocket
function SingleDrawResultUI:New(data)
	local o = LUIBase:New()
	setmetatable(o,SingleDrawResultUI)	
    o:Init(data)
	return o
end

--注册事件
-- -----------------------------------
function SingleDrawResultUI:RegistMsgs()
    self.msgIds = 
    {
        LUIDrawEvent.continueDanCiDrawSuc,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function SingleDrawResultUI:ProcessEvent(msg)
    if msg.msgId == LUIDrawEvent.continueDanCiDrawSuc then
        -- dump(msg.value, "SingleDrawResultUI =====>")
        self:UpdateUserData(msg.value)
        self:performDrawEvent()
    end
end

function SingleDrawResultUI:Init(data)

    self.m_pUILayer = cc.CSLoader:createNode("csd/chouka/dancichouka.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    self:RegistMsgs()
    self:InitUIControl()
    self.m_dataVec = {}
    if data then
        self:UpdateUserData(data)
    end

    LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.AutoPathEvent.PauseAutoPath)
    self:SendMsg(LGameMsg.m_cBaseMsg)
    PetkaPaiManager.m_isInDrawResult = true
    self._isPlaying = true
    self.m_pbtn_Continue:setTouchEnabled(false)
    self.m_pbtn_Continue:setBright(false)
    self:performDrawEvent()
end


function SingleDrawResultUI:performDrawEvent( ... )
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
function SingleDrawResultUI:InitUIControl()
    local pPanel = self.m_pUILayer:getChildByName("dancichoukaUI")
    -----------------------------------------------------------
    self.m_pChildren = pPanel:getChildren()
    self.m_pTitle = pPanel:getChildByName("Congratulations")
    self.m_pTitle:getChildByName("Teaser"):setVisible(false)
    self.m_pBg = pPanel:getChildByName("Bg")
    -- self.m_pClose = pPanel:getChildByName("Close")
    -----------------------------------------------------------
    local pBg = self.m_pBg
    pBg:setTouchEnabled(true)
    pBg:addClickEventListener(handler(self, SingleDrawResultUI.checkNext))
    self:MarkIntaractCObj(pBg)

    pBg:setOpacity(50)
    pBg:runAction(cc.FadeTo:create(0.1, 255))
    -- for i=1,#self.m_pChildren do
    --     if self.m_pChildren[i] == pBg then
    --         table.remove(self.m_pChildren, i)
    --         break
    --     end
    -- end
    -----------------------------------------------------------
	local effect = pPanel:getChildByName("effect_zhaomu_5")
	local effcet = self:SetEffect()
    effcet:setName("effcet") 
    effect:addChild(effcet)	
	
	
    local shenjiang = pPanel:getChildByName("shenjiang")
    local pSjNode = shenjiang:getChildByName("Node")
    local pDjNode = pPanel:getChildByName("Item")
    local pLevelBg = shenjiang:getChildByName("bg_Level")
    self.m_pLDCellUI = LDCellUI:New({sjNode=pSjNode, djNode=pDjNode, levelBg=pLevelBg})
    self.m_pLDCellUI:SetAnimFinishCallback(handler(self, SingleDrawResultUI.animFinished))
    local btnClose = pPanel:getChildByName("btn_Close")
    self:MarkIntaractCObj(btnClose)
    self._close = btnClose
    self._close:setVisible(false)
    btnClose:addClickEventListener(function ( sender )
        -- body
        -- self:CloseUI()
        self:checkNext()

    end)
    -----------------------------------------------------------
    local pbtn_Continue = pPanel:getChildByName("btn_Continue")
    pbtn_Continue:addClickEventListener(handler(self, SingleDrawResultUI.continueCallback))
    self:MarkIntaractCObj(pbtn_Continue)
    pbtn_Continue:setVisible(false)
    self.m_pbtn_Continue = pbtn_Continue
    -----------------------------------------------------------
    local pSkill = pPanel:getChildByName("Skill_1")
    self.m_pSkill = pSkill
    pSkill:addClickEventListener(handler(self, SingleDrawResultUI.SkillClick))
    pSkill:getChildByName("Icon"):setScale(0.85)
    self.m_pSuipian = pPanel:getChildByName("Suipian")
    -----------------------------------------------------------
end

function SingleDrawResultUI:setContinueCallback()
    if PetkaPaiManager.m_DrawResult.leftDrawTimes == nil then
        self.m_pbtn_Continue:setVisible(false)
        self._close:setPositionX(AppDef.frameSize.width/2)
        self.m_pTitle:getChildByName("shenhun"):setVisible(false)
        self.m_pTitle:getChildByName("Teaser"):setVisible(false)
        self:UpdateSkill(self.m_dataVec[1])
        return
    end
    self.m_pbtn_Continue:setVisible(true)
    local itemID = PetkaPaiManager.m_curDarwKind + 999
    local num = LRoleDataMgr.Equip:CountItemNumById(itemID)
    local Panel = self.m_pbtn_Continue:getChildByName("Panel_3")
    -- Panel:setSwallowTouches(false)
    Panel:setTouchEnabled(false)

    local icon = Panel:getChildByName("Icon")
    Utils:GetItemCellValue(icon, 0, itemID, true, false, num, nil, true, true)
    local Value = Panel:getChildByName("Value")
    local tips = string.format("%d/%d", num, 1)
    Value:setString(tips)
    local freeTxt = self.m_pbtn_Continue:getChildByName("free")
    local freeTimeValue = freeTxt:getChildByName("Num")
    local freeLeftTime = PetkaPaiManager.m_DrawResult.freeLeftTime
    
    local isHaveFreeTimes = PetkaPaiManager.m_DrawResult.leftDrawTimes > 0
    local isInCd = freeLeftTime > 0
    local totalDrawNum = PetkaPaiManager.m_DrawResult.totalNum
    -- print("totalDrawNum ==== 222222222222222>", totalDrawNum)
    --数据没有走一个地方协议224 op =2 还有协议 236
    -- dump(self.m_dataVec, "setContinueCallback 1111111111111 =====>")

    -- dump(PetkaPaiManager.m_DrawResult, "setContinueCallback 22222222222222222 =====>")

    Panel:setVisible(not isHaveFreeTimes or isInCd)
    freeTxt:setVisible(isHaveFreeTimes and isInCd)

    local Text_2 = self.m_pbtn_Continue:getChildByName("Text_2")
    local value = Text_2:getChildByName("Num")
    Text_2:setVisible(isHaveFreeTimes and not isInCd)
    local drawConfigData = JsonConfig.m_drawBasic.getDefByID(PetkaPaiManager.m_DrawResult.kind)
    value:setString(string.format("%d/%d", PetkaPaiManager.m_DrawResult.leftDrawTimes, drawConfigData.free_times))

    if isHaveFreeTimes and isInCd then
        if self._timeLabel1 == nil then 
            self._timeLabel1 = TimerLabelUI:New(freeTimeValue, nil, nil, handler(self, self.TimeReduce))
        end
        self._timeLabel1:set(freeLeftTime, function( ... )
            -- body
            Panel:setVisible(false)
            freeTxt:setVisible(false)
            Text_2:setVisible(true)
        end)
        self._timeLabel1:start()
    end

    local mustBeText = self.m_pTitle:getChildByName("Teaser")
    local leftTimes = totalDrawNum % drawConfigData.must_be_out_times
    if leftTimes == 0 then
        mustBeText:setVisible(false)
    else
        local des2 
        if drawConfigData.type == 3 then
            des2 = string.format(GUITips.RSI_ZQX_CHOUKA_TIPS9, drawConfigData.must_be_out_times - leftTimes)
        else
            des2 = string.format(GUITips.RSI_ZQX_CHOUKA_TIPS2, drawConfigData.must_be_out_times - leftTimes)
        end
        mustBeText:setVisible(true)
        mustBeText:setString(des2)
    end
    
end

function SingleDrawResultUI:continueCallback(sender)

    -- if self._isPlaying then
    --     print("continueCallback playing ===>")
    --     -- Utils:ShowScrollTips(GUITips.UI_KunLun_Draw_Tips)
    --     return
    -- end
    -- dump(self.m_data, "continueCallback === 111111111111 >> ")
    self.m_dataVec = {}
    self._isPlaying = true
    sender:setTouchEnabled(false)
    sender:setBright(false)
    -- print("continueCallback ======== 1111111111111 >", PetkaPaiManager.m_DrawResult.kind, PetkaPaiManager.m_DrawResult.type, self._isPlaying)
    LuaNetSendMsg:SendExtractPetMsg(2, PetkaPaiManager.m_DrawResult.kind, PetkaPaiManager.m_DrawResult.type)
    self.m_dataVec = {}
    self:CloseUI()
end


function SingleDrawResultUI:TimeReduce(pText, h, m, s, left)
    if pText == nil then
        return
    end
    if h > 0 then 
        pText:setString(string.format("%02d:%02d:%02d", h, m,s))
    else
        pText:setString(string.format("%02d:%02d", m, s))
    end
end

function SingleDrawResultUI:UpdateUserData(data)
    if data == nil then
        return
    end
    -- self.m_dataVec = data
    if data.transformId and data.transformId > 0 then
        data.tranItemId = data.transformId
        data.tranItemNum = data.transformNum
    end

    -- dump(data, "SingleDrawResultUI UpdateUserData === >")

    table.insert(self.m_dataVec, data)

    if not self.m_isAniming then
        self:checkNext(nil)
    end
end


function SingleDrawResultUI:updateCast(castId)
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
function SingleDrawResultUI:checkNext(sender)
    if self.m_isAniming then
        return
    end

    if self._isPlaying then
        return
    end

    if #self.m_dataVec == 0 then
        self:CloseUI()
        return
    end

    local data = self.m_dataVec[1]
    -- dump(data, "SingleDrawResultUI ================================>")
    if data then
        self:Reset()
        local havePet = data.petId and data.petId > 0
        local isTransform = data.tranItemId and data.tranItemId > 0
        local isShow = havePet and (not isTransform)
        self.m_pTitle:setVisible(true)
        local shenhun = self.m_pTitle:getChildByName("shenhun")
        local nameStr = Utils:getItemNameByID(data.itemId)
        local num = PetkaPaiManager:getObtainDrawShenHun()
        print("num ===========>", num, isShow, havePet, isTransform)
        local strTips = string.format(GUITips.RSI_ZQX_CHOUKA_TIPS5, num) .. GUITips.RSI_ML_TIP15
        shenhun:setString(strTips)

        self.m_pLDCellUI:updateData(data)

        self:StartAnim()
        self:UpdateSkill(data)
        -- self:UpdateSuiPian(data)
        LGameMsg.m_audioMsg:Change(LAudioEvent.StopEffect)
        self:SendMsg(LGameMsg.m_audioMsg)
        
        print("SingleDrawResultUI:StartAnim ==================>", AppDef.SysBGM.Happy_Draw)
        Utils:PlayKPEffect(AppDef.SysBGM.Happy_Draw)

        local function afterPlayVoice()
            if isShow then
                if data.petId == 36 then
                    Utils:PlayEffect("GuideBGM", "id", 12, false, true)
                elseif data.petId == 38 then
                    Utils:PlayEffect("GuideBGM", "id", 8, false, true)
                elseif data.petId == 40 then
                    Utils:PlayEffect("GuideBGM", "id", 9, false, true)
                else
                    Utils:PlayPetAudioEffect(data.petId)
                end
            end
        end
        performWithDelay(AppDef.CurScene, afterPlayVoice, 3)

    end
    table.remove(self.m_dataVec, 1)
end

function SingleDrawResultUI:Reset()
    -- for i=1,#self.m_pChildren do
    --     self.m_pChildren[i]:setVisible(false)
    -- end
end

function SingleDrawResultUI:StartAnim()
    self.m_isAniming = true
    self.m_pLDCellUI:StartAnim()
    --播放动画    
    self.m_timeline = cc.CSLoader:createTimeline("csd/chouka/dancichouka.csb")
    self.m_pUILayer:runAction(self.m_timeline)
    self.m_timeline:gotoFrameAndPlay(0, false)

end

function SingleDrawResultUI:animFinished()
    self:setContinueCallback()
    -- self.m_pClose:setVisible(true)
    self._close:setVisible(true)
    self.m_pTitle:setVisible(true)
    self.m_isAniming = false
    self:RegisterGuide()
end

function SingleDrawResultUI:UpdateSkill(data)
    if data == nil or data.petId == nil or self.m_pSkill == nil then
        return
    end

    if data.petId < 1 then
        self.m_pSkill:setVisible(false)
        return
    end

    
    local configData = JsonConfig.m_heroCfg.getDefByID(data.petId)
    self.m_pSkill:setTag(configData.skills[1])
    self.m_pSkill:setVisible(true)
    self:ShowSkill(self.m_pSkill, configData.skills[1])

end

function SingleDrawResultUI:ShowSkill(pSkill, skid)
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

function SingleDrawResultUI:SkillClick(sender)
    if sender == nil then
        return
    end
    local skid = sender:getTag()
    if skid > 0 then
        itemData = LSkillMgr:getSkillById(skid)

        -- dump(itemData, "SkillClick ===>")

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

 function SingleDrawResultUI:SetEffect()
    local bgAnim = "res2/animation/effect_zhaomu_5"
    local m_pBgAni = ImodAnim:create()
    m_pBgAni:initAnimWithNameSync(bgAnim)
    m_pBgAni:PlayActionRepeat(0)
    m_pBgAni:setScale(scale or 1)
    return m_pBgAni
end

function SingleDrawResultUI:CloseUI( ... )
    -- body
    Utils:DeleteUI("HappyDraw.SingleDrawResultUI")
end

function SingleDrawResultUI:onExit()
    self.m_pUILayer = nil
    self.m_pChildren = nil
    self:Destory()
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_Pet_4)
    Utils:CheckGuide(GuideDef.StepId.Guide_Pet_5, true)
    PetkaPaiManager.m_isInDrawResult = false
    
    --播放三次
    performWithDelay(AppDef.Director:getRunningScene(),function(sender)
        Utils:SendMsg(LUIGetPetWingEvent.CheckNext, nil, true)
        -- LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.AutoPathEvent.ReStartAutoPath)
        -- self:SendMsg(LGameMsg.m_cBaseMsg)
    end, 0)

end

function SingleDrawResultUI:RegisterGuide()
    Utils:RegisterGuide(GuideDef.StepId.Guide_Pet_4, self._close, handler(self, SingleDrawResultUI.CloseUI), nil, true)
end

return SingleDrawResultUI