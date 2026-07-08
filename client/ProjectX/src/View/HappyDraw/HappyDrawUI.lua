local HappyDrawUI = LUIBase:New()
HappyDrawUI.__index = HappyDrawUI

HappyDrawUI.IsHideInBattle = true

local TimerLabelUI = require("View.Common.TimerLabelUI")

-------------------------------------
function HappyDrawUI:New()
    local o = {}
    setmetatable(o, HappyDrawUI)
    o:Init()
    return o
end

local COSTITEMIDBEGIN = 999

local draw_need_num = {
    1, 10, 1, 10, 10, 100
}

local PrompArr = {
    RedDotDef.ID.HD_Normal_DanCi,
    RedDotDef.ID.HD_Normal_ShiLian,
    RedDotDef.ID.HD_GaoJi_DanCi,
    RedDotDef.ID.HD_GaoJi_ShiLian,
    RedDotDef.ID.HD_FriendLy_DanCi,
    RedDotDef.ID.HD_FriendLy_ShiLian,
}

-------------------------------------
function HappyDrawUI:Init()
    self.Script = "HappyDraw.HappyDrawUI"
    self.m_pInfo = nil
    ------------------------------------------------
    self._drawBtn = {}
    ------------------------------------------------
    self._DrawTipsArr = {}
    ------------------------------------------------
    self.m_data = {}

    ------------------------------------------------
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    self:RegisterQuik()
    LuaNetSendMsg:SendExtractPetMsg(1)
end

-------------------------------------
function HappyDrawUI:onExit()
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_Pet_3)
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_Pet_5)
    self:Destory()
    if self.m_schedule ~= nil then
        Utils:unschedule(nil, self.m_schedule)
        self.m_schedule = nil
    end
    if self.m_pScaleController then
        self.m_pScaleController:onExit()
        self.m_pScaleController = nil
    end
    self.m_pReturnBtn = nil
    self.m_pInfo = nil
    self.m_pDanChouButton = nil
    if self.m_pDanChouCostItem then
        self.m_pDanChouCostItem:onExit(true)
        self.m_pDanChouCostItem = nil
    end
    if self.m_pShiLianCostItem then
        self.m_pShiLianCostItem:onExit(true)
        self.m_pShiLianCostItem = nil
    end
    Utils:FreeTable(self._drawBtn)
    self._drawBtn = nil

    self._DrawTipsArr = nil

    self.m_pDanChouText = nil
    if self.m_pAnimController then
        self.m_pAnimController:onExit()
        self.m_pAnimController = nil
    end
    self.m_pDanChouTips = nil
    self.m_pDanChouText = nil
    self.m_pDanChouRedDot = nil
    self.m_pDanChouCostBg = nil
    self.m_pDanChouCostIcon = nil
    self.m_pDanChouCostNum = nil

    ------------------------------------------------
    self.m_pShiLianText = nil
    self.m_pShiLianRedDot = nil
    self.m_pShiLianTips = nil
    self.m_pShiLianCostBg = nil
    self.m_pShiLianCostIcon = nil
    self.m_pShiLianCostNum = nil
    Utils:CheckGuide(GuideDef.StepId.Guide_Pet_6,true)

    if self.m_isShowMsgBox then
        Utils:SendMsg(LUIMsgBoxEvent.HideMsgBox)
        self.m_isShowMsgBox = nil
    end
    self.m_pDanChouTips = nil

    local _ = self._timeLabel1 and self._timeLabel1:Destory()

end
function HappyDrawUI:HelpClicked(sender) 
    Utils:ShowDialogOKCancel(GUITips.ChouKa)
end

-------------------------------------
function HappyDrawUI:InitUIControl()

    -- local nodeBg = self.m_pUILayer:getChildByName("Node")
    self.m_pUILayer:setVisible(false)
    local nodeBg = self.m_pUILayer
    for i=1, 3 do
        local Popup1 = nodeBg:getChildByName("Popup"..i)
        for j=2, 1, -1 do
            local tempIdx = 3 - j 
            local DrawBtn = Popup1:getChildByName("Btn_Recruit_"..j)
            DrawBtn:setTag((i - 1) * 2 + tempIdx)

            DrawBtn:addClickEventListener(handler(self, HappyDrawUI.DrawCallBack))
            table.insert(self._drawBtn, DrawBtn)
        end

        local DrawConfig = JsonConfig.m_drawBasic.getDefByID(i) 
        local Description1 = Popup1:getChildByName("Description1")
        local des1 = string.format(GUITips.RSI_ZQX_CHOUKA_TIPS1, DrawConfig.must_get[1][3])
        Description1:setString(des1)
        local Description2 = Popup1:getChildByName("Description2")
        -- local des2 = string.format(GUITips.RSI_ZQX_CHOUKA_TIPS2, DrawConfig.must_be_out_times)
        -- Description2:setString(des2)
        table.insert(self._DrawTipsArr, Description2)
    end

    -----------------------------------------------------------
    local GoldCheck = self.m_pUILayer:getChildByName("GoldCheck")
    GoldCheck:setTouchEnabled(false)
    self:initMoneyPanel(GoldCheck)
    -----------------------------------------------------------
    local btnShop = nodeBg:getChildByName("Shop")
    self._btnShop = btnShop
    self._btnShop:getChildByName("Prompt"):setVisible(Utils:GetRedDotState(RedDotDef.ID.ShopJiangHun))
    btnShop:addClickEventListener(function (sender)
        -- body
        Utils:InitUI("Shop.JiangHunShop", AppDef.UIType.PopFirstClassLayer)
    end)
    local RewardPreview = nodeBg:getChildByName("RewardPreview")
    RewardPreview:addClickEventListener(function ( sender )
        -- body
        Utils:InitUI("HappyDraw.DrawRewardMainUI", AppDef.UIType.FirstClassLayer, 1)
    end)
    ----------------------------------------------
    local title = self.m_pUILayer:getChildByName("Title")
    local helpBtn = title:getChildByName("TitleName"):getChildByName("Button_1")
    helpBtn:addClickEventListener(function ( sender )
        -- body
        self:HelpClicked()
    end)
    local CloseBtn = title:getChildByName("CloseBtn")
    CloseBtn:addClickEventListener(function ( sender )
        -- body
        self:RemoveUI()
    end)
    self.m_pReturnBtn = CloseBtn
end

-------------------------------------
function HappyDrawUI:RegistMsgs()
    self.msgIds = {
        LUIDrawEvent.updateDrawUI,
        LUIRoleDataChangeEvent.TongBaoChanged,
        LUIDrawEvent.SingleDrawSuccess,
        LUIDrawEvent.TenDrawSuccess,
        LUIRedDotEvent.UpdateRedDotState,
        LUILogicEvent.buyItemSucEvent,
    }

    self:RegistSelf(self, self.msgIds)
end

-------------------------------------
function HappyDrawUI:ProcessEvent(msg)
    if msg.msgId == LUIDrawEvent.updateDrawUI then
        -- print("HappyDrawUI:ProcessEvent ===>", LUIDrawEvent.updateDrawUI)
        self:LoadData(msg.value)
        self:updateUI()
        self:RegisterGuide()
    elseif msg.msgId == LUIRoleDataChangeEvent.TongBaoChanged then
        self:updateMoney(AppDef.MoneyType.YUANBAO, LRoleDataMgr.MyHeroInfo:GetDetailData().TongBao)
    elseif msg.msgId == LUIDrawEvent.SingleDrawSuccess then
        self:updateData(msg.value)
        self:showDrawResult(msg.value, 1)
    elseif msg.msgId == LUIDrawEvent.TenDrawSuccess then
        self:updateData(msg.value)
        self:showDrawResult(msg.value, 2)
    elseif msg.msgId == LUIRedDotEvent.UpdateRedDotState then
        self:UpdateRedDot(msg.value)
    elseif msg.msgId== LUILogicEvent.buyItemSucEvent then

        self:updateCard()    
    end
end

function HappyDrawUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    local pPanel = self.m_pUILayer:getChildByName("Panel")
end

-------------------------------------
function HappyDrawUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/chouka/shenjiangzhaomu.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    self.m_timeline = cc.CSLoader:createTimeline("csd/chouka/shenjiangzhaomu.csb")
    self.m_pUILayer:runAction(self.m_timeline)
    self.m_timeline:gotoFrameAndPlay(0, false)
end

------------------------------------
function HappyDrawUI:RegisterQuik()
    
end

------------------------------------
function HappyDrawUI:LoadData(info)
    self.m_pInfo = info
    -------------------------------------------------------------
    if self.m_schedule then
        Utils:unschedule(nil, self.m_schedule)
        self.m_schedule = nil
    end
    self.m_schedule = Utils:schedule(nil, handler(self, HappyDrawUI.UpdateCD), 1, false)

end


function HappyDrawUI:updateData( info )
    -- body
    if info.type == AppDef.DrawType.OneDraw then
        if info.freeLeftTime then
            self.m_pInfo[info.kind].freeLeftTime = info.freeLeftTime
        end
        
        if info.leftDrawTimes then
            self.m_pInfo[info.kind].leftTimes = info.leftDrawTimes
        end
        
        self.m_pInfo[info.kind].TotalNum = self.m_pInfo[info.kind].TotalNum + 1
    else
        self.m_pInfo[info.kind].TotalNum = self.m_pInfo[info.kind].TotalNum + 10
    end
end


function HappyDrawUI:resetItems()
    self:updateChildren(0)
end

function HappyDrawUI:updateChildren(index)
    local childs = self.m_pAnimController.m_itemMap
    for i=1,#childs do
        local isSelected = i == index
        local item = childs[i]
        local pParticle = item:getChildByName("Particle_1")
        if pParticle then
            pParticle:setVisible(isSelected)
            if isSelected then
                pParticle:start()
            else
                pParticle:stop()
            end
        end
        if isSelected then
            item:setColor(cc.c3b(255,255,255))
        else
            item:setColor(cc.c3b(150,150,150))
        end
    end
end

function HappyDrawUI:initMoneyPanel(panel)
    self._CouponArr = {}
    for i=1, 4 do
        local GoldIcon = panel:getChildByName("GoldIcon"..i)
        local GoldNumBg = GoldIcon:getChildByName("GoldNumBg")
        local num = GoldNumBg:getChildByName("Num")
        table.insert(self._CouponArr, num)
        local AddBtn = GoldIcon:getChildByName("AddBtn")
        AddBtn:setTag(i)
        AddBtn:addClickEventListener(handler(self, HappyDrawUI.openMoney))
    end
    self:updateDrawMaterial()
end



function HappyDrawUI:updateCard( )
    self:updateUI()
end

function HappyDrawUI:updateDrawMaterial( ... )
    -- body
    local zhaoMuJuan = LRoleDataMgr.Equip:CountItemNumById(COSTITEMIDBEGIN + 1)
    self._CouponArr[1]:setString(zhaoMuJuan)
    local gaoJiJuan = LRoleDataMgr.Equip:CountItemNumById(COSTITEMIDBEGIN + 2)
    self._CouponArr[2]:setString(gaoJiJuan)
    local youQingJuan = LRoleDataMgr.Equip:CountItemNumById(COSTITEMIDBEGIN + 3)
    self._CouponArr[3]:setString(youQingJuan)
    local myGold = LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao()
    self._CouponArr[4]:setString(myGold)
end


function HappyDrawUI:updateMoney(_type, value)
    if _type == AppDef.MoneyType.YUANBAO then
        self._CouponArr[4]:setString(tostring(value))
    end
end

function HappyDrawUI:openMoney(sender)
    local tag = sender:getTag()
    if tag == 1 then
        Utils:ShowItemTips(1000)
    elseif tag == 2 then
        Utils:OpenExchangeUI(1001)
    elseif tag == 3 then
        Utils:OpenFunction(AppDef.EModuleID.EMID_FRIEND)
    end
end

function HappyDrawUI:updateUI( ... )
    -- body
    self.m_pUILayer:setVisible(true)
    for i=1, #self.m_pInfo do
        local data = self.m_pInfo[i]
        for j=1, 2 do
            local index = (i - 1) * 2 + j --索引转换,和UI对应
            local DrawBtn = self._drawBtn[index]
            local icon = DrawBtn:getChildByName("Icon")
            local itemId = COSTITEMIDBEGIN + i
            local ownNum = LRoleDataMgr.Equip:CountItemNumById(itemId)
            local itemNum  = draw_need_num[index]

            icon:removeAllChildren()
            local item = Utils:GetItemCellValue(icon, 0, itemId, true, true, itemNum, nil, false, true)
            item:setNumTextScale(2)

            if ownNum >= itemNum then
                item:setNumTextColor(UICOLOR_WHITE)
            else
                item:setNumTextColor(UICOLOR_RED)
            end

            self:updateBtnUI(DrawBtn, index, data, item, itemNum)
            self:initRedDot(DrawBtn, index)
        end

        --更新UI
        local tipsText =  self._DrawTipsArr[i]

        local drawConfigData = JsonConfig.m_drawBasic.getDefByID(i)
        local must_be = drawConfigData.must_be_out_times
        print("data.TotalNum ===> 111", data.TotalNum)
        local des2 
        if drawConfigData.type == 3 then
            des2 = string.format(GUITips.RSI_ZQX_CHOUKA_TIPS9, must_be - data.TotalNum % must_be)
        else
            des2 = string.format(GUITips.RSI_ZQX_CHOUKA_TIPS2, must_be - data.TotalNum % must_be)
        end
        tipsText:setString(des2)
    end

    --更新头部资源信息
    self:updateDrawMaterial()
end

function HappyDrawUI:updateBtnUI(DrawBtn, index, data, item, itemNum)
    -- body
    local text1 = DrawBtn:getChildByName("Text_1")
    local text2 = DrawBtn:getChildByName("Text_2")
    local Icon = DrawBtn:getChildByName("Icon")

    print("updateBtnUI 1111111111 ==>", data.freeLeftTime, data.leftTimes)

    if index == 1 then
        local text3 = DrawBtn:getChildByName("Text_3")
        -- data.freeLeftTime = 15
        local isHaveFreeTimes = data.leftTimes > 0
        local isInCd = data.freeLeftTime > 0
        
        text1:setVisible(not isHaveFreeTimes)
        text2:setVisible(isHaveFreeTimes and not isInCd)
        local Num = text2:getChildByName("Num")
        local drawConfigData = JsonConfig.m_drawBasic.getDefByID(data.type)
        if drawConfigData then
            --todo
        end
        Num:setString(string.format("%d/%d", data.leftTimes, drawConfigData.free_times))

        text3:setVisible(isHaveFreeTimes and isInCd)
        Icon:setVisible(not isHaveFreeTimes or isInCd)

        if isHaveFreeTimes and isInCd then
            self._coolDown1 = data.freeLeftTime
            self._coolText1 = text3:getChildByName("Comment"):getChildByName("Num")
            if self._timeLabel1 == nil then 
                self._timeLabel1 = TimerLabelUI:New(self._coolText1, nil, nil, handler(self, self.TimeReduce))
            end
            self._timeLabel1:set(data.freeLeftTime, function( ... )
            -- body
                --免费状态
                text1:setVisible(false)
                text2:setVisible(true)
                text3:setVisible(false)
                Icon:setVisible(false)
            end)
            self._timeLabel1:start()
        end

    elseif index == 3 then
        local isHaveFreeTimes = data.leftTimes > 0
        text1:setVisible(not isHaveFreeTimes)
        text2:setVisible(isHaveFreeTimes)
        Icon:setVisible(not isHaveFreeTimes)
    elseif index == 5 then

    end

end

function HappyDrawUI:TimeReduce(pText, h, m, s, left)
    if pText == nil then
        return
    end
    if h > 0 then 
        pText:setString(string.format("%02d:%02d:%02d", h, m,s))
    else
        pText:setString(string.format("%02d:%02d", m, s))
    end
end

function HappyDrawUI:DrawCallBack( sender )
    -- body

    if self.m_pInfo == nil then
        return
    end

    local tag = sender:getTag()
    print("HappyDrawUI:DrawCallBack ======= ", tag)
    local zhaoMuJuan = LRoleDataMgr.Equip:CountItemNumById(COSTITEMIDBEGIN + 1)
    local gaoJiJuan = LRoleDataMgr.Equip:CountItemNumById(COSTITEMIDBEGIN + 2)
    local youQingJuan = LRoleDataMgr.Equip:CountItemNumById(COSTITEMIDBEGIN + 3)

    if tag ==  1 then
		local data = self.m_pInfo[math.ceil(tag/2)]
		if zhaoMuJuan < 1 and data.leftTimes <= 0 then
			Utils:ShowItemTips(AppDef.Pet.UpgradsMats[AppDef.DrawKind.NormalDraw])
			return
		end
        LuaNetSendMsg:SendExtractPetMsg(2, AppDef.DrawKind.NormalDraw, AppDef.DrawType.OneDraw)
        PetkaPaiManager.m_curDarwKind = AppDef.DrawKind.NormalDraw
        PetkaPaiManager.m_curDarwType = AppDef.DrawType.OneDraw
    elseif tag == 2 then
		if zhaoMuJuan < 10 then
			Utils:ShowItemTips(AppDef.Pet.UpgradsMats[AppDef.DrawKind.NormalDraw])
			return
		end
        LuaNetSendMsg:SendExtractPetMsg(2, AppDef.DrawKind.NormalDraw, AppDef.DrawType.TenDraw)
        PetkaPaiManager.m_curDarwKind = AppDef.DrawKind.NormalDraw
        PetkaPaiManager.m_curDarwType = AppDef.DrawType.TenDraw
    elseif tag == 3 then
        
		local data = self.m_pInfo[math.ceil(tag/2)]
		if gaoJiJuan < 1 and data.leftTimes <= 0 then
			Utils:OpenExchangeUI(1001)
			return
		end
        LuaNetSendMsg:SendExtractPetMsg(2, AppDef.DrawKind.HighLevelDraw, AppDef.DrawType.OneDraw)
        PetkaPaiManager.m_curDarwKind = AppDef.DrawKind.HighLevelDraw
        PetkaPaiManager.m_curDarwType = AppDef.DrawType.OneDraw
    elseif tag == 4 then
		if gaoJiJuan < 10 then
			Utils:OpenExchangeUI(1001)
			return
		end
        LuaNetSendMsg:SendExtractPetMsg(2, AppDef.DrawKind.HighLevelDraw, AppDef.DrawType.TenDraw)
        PetkaPaiManager.m_curDarwKind = AppDef.DrawKind.HighLevelDraw
        PetkaPaiManager.m_curDarwType = AppDef.DrawType.TenDraw
    elseif tag == 5 then
		if youQingJuan < 10 then
			Utils:OpenFunction(AppDef.EModuleID.EMID_FRIEND)
			return
		end
        LuaNetSendMsg:SendExtractPetMsg(2, AppDef.DrawKind.FriendlyDraw, AppDef.DrawType.OneDraw)
        PetkaPaiManager.m_curDarwKind = AppDef.DrawKind.FriendlyDraw
        PetkaPaiManager.m_curDarwType = AppDef.DrawType.OneDraw
    elseif tag == 6 then
		if youQingJuan < 100 then
			Utils:OpenFunction(AppDef.EModuleID.EMID_FRIEND)
			return
		end
        LuaNetSendMsg:SendExtractPetMsg(2, AppDef.DrawKind.FriendlyDraw, AppDef.DrawType.TenDraw)
        PetkaPaiManager.m_curDarwKind = AppDef.DrawKind.FriendlyDraw
        PetkaPaiManager.m_curDarwType = AppDef.DrawType.TenDraw
    end
    
end

function HappyDrawUI:setCostNumber(pText, haveNum, castNum)
    if pText == nil then
        return
    end
    pText:setString(string.format("%d/%d", haveNum, castNum))
    if haveNum < castNum then
        pText:setTextColor(cc.c4b(255,0,0,255))
    else
        pText:setTextColor(cc.c4b(110,56,48,255))
    end
end

function HappyDrawUI:UpdateCD(dt)
    -- if self.m_pInfo then
    --     for i=1, #self.m_pInfo do
    --         local info = self.m_pInfo[i]
    --         if info then
    --             for j=1,#info.items do
    --                 if info.items[j].cd-1 >= 0 then
    --                     info.items[j].cd = info.items[j].cd - 1
    --                 end
    --             end
    --         end
    --     end
    --     self:UpdateCDLabel()
    --     self:updateDanChouRedDot()
    -- end
end

function HappyDrawUI:UpdateCDLabel()
    local index = self:getSelectIndex()
    local data = self.m_pInfo[index]
    local itemData = data.items[1]
    if itemData then
        if itemData.cd > 0 then
            local _h, _m, _s = Utils:getFormatTime(itemData.cd)
            self.m_pDanChouTips:setVisible(true)
            self.m_pDanChouTips:setString(string.format('%02d:%02d:%02d%s',_h, _m, _s, GUITips.RSI_LD_TIP3))
        else
            self.m_pDanChouTips:setVisible(false)
        end
    end
end

function HappyDrawUI:updateDanChouRedDot()
    local index = self:getSelectIndex()
    local data = self.m_pInfo[index]
    local itemData = data.items[1]
    if itemData == nil then
        return
    end
    if itemData.cd <= 0 then
        self.m_pDanChouRedDot:setVisible(true)
        return
    end
    self:CheckNeedItemMeet(self.m_pDanChouRedDot, itemData.needItemId, itemData.needItemNum)
end

function HappyDrawUI:CheckNeedItemMeet(pRed, itemId, itemNum)
    local _ = pRed and pRed:setVisible(LRoleDataMgr.Equip:CountItemNumById(itemId) >= itemNum)
end

------------------------------------
function HappyDrawUI:showMsgBox(needYB, name, okCallback)
    local data = {}
    data.desc = string.format(GUITips.RSI_LD_TIP6, needYB, name)
    data.okCallback = okCallback
    data.cancelCallback = function() self.m_isShowMsgBox = false end
    Utils:SendMsg(LUIMsgBoxEvent.ShowMsgBox, data)
    self.m_isShowMsgBox = true
end

function HappyDrawUI:showDrawResult(retInfo, type)
    self:updateUI()
    if type == 1 then
        if PetkaPaiManager.m_isInDrawResult then
            Utils:SendMsg(LUIDrawEvent.continueDanCiDrawSuc, retInfo)
        else
            Utils:InitUI("HappyDraw.SingleDrawResultUI", AppDef.UIType.MsgBox, retInfo)
        end
    elseif type == 2 then
        if PetkaPaiManager.m_isInTenDrawResult then
            Utils:SendMsg(LUIDrawEvent.continueDrawSuc, retInfo)
        else
            Utils:InitUI("HappyDraw.TenDrawResultUI", AppDef.UIType.PopWindow, retInfo)
        end
    end
end


function HappyDrawUI:getSelectIndex()
    if self.m_pAnimController then
        return self.m_pAnimController.m_selected
    end
    return 1
end

function HappyDrawUI:StartDraw()
    if self.m_pMaskTouchLayer == nil then
        if self.m_pSendInfo then
            LuaNetSendMsg:SendExtractPetMsg(2, self.m_pSendInfo.kind, self.m_pSendInfo.itemType)
        end
        self.m_pSendInfo = nil
        return
    end

    local viewsize = self.m_pMaskTouchLayer:getContentSize()
    
    local pAni = self.m_pMaskTouchLayer:getChildByTag(0xff)
    if pAni == nil then
        pAni = ImodAnim:createWithFileSync("res2/fx/choukaluzi")
        pAni:setScale(2)
        pAni:setIgnoreAnchorPointForPosition(false)
        pAni:setAnchorPoint(cc.p(0.5,0.5))
        pAni:setPosition(cc.p(viewsize.width/2-25, viewsize.height/2-65))
        self.m_pMaskTouchLayer:addChild(pAni, 1, 0xff)
    end
    pAni:PlayAction(0)

    --抽卡过程中屏蔽触摸
    self.m_pMaskTouchLayer:setVisible(true)
    pAni:stopActionByTag(0xff)
    local pAction = performWithDelay(pAni, function(sender)
        --dump(self.m_pSendInfo)
        if self.m_pSendInfo then
            LuaNetSendMsg:SendExtractPetMsg(2, self.m_pSendInfo.kind, self.m_pSendInfo.itemType)
            self.m_pSendInfo = nil
        end
        --抽卡完恢复触摸
        self.m_pMaskTouchLayer:setVisible(false)
    end, pAni:GetCurAniTime())
    local _ = pAction and pAction:setTag(0xff)
end

function HappyDrawUI:initRedDot( btn, index )
    -- body
    local isShow = Utils:GetRedDotState(PrompArr[index])
    print("initRedDot == >", PrompArr[index], isShow, btn)
    local prompt = btn:getChildByName("Prompt")
    print("initRedDot =========== 111111111111> ")
    prompt:setVisible(isShow)
end

function HappyDrawUI:UpdateRedDot(data)
    -- body
    -- dump(data, "UpdateRedDot ================>")
    if data.id == RedDotDef.ID.HD_Normal_DanCi then
        self._drawBtn[1]:getChildByName("Prompt"):setVisible(data.isShow)
    elseif data.id == RedDotDef.ID.HD_Normal_ShiLian then
        self._drawBtn[2]:getChildByName("Prompt"):setVisible(data.isShow)
    elseif data.id == RedDotDef.ID.HD_GaoJi_DanCi then
        self._drawBtn[3]:getChildByName("Prompt"):setVisible(data.isShow)
    elseif data.id == RedDotDef.ID.HD_GaoJi_ShiLian then
        self._drawBtn[4]:getChildByName("Prompt"):setVisible(data.isShow)
    elseif data.id == RedDotDef.ID.HD_FriendLy_DanCi then
        self._drawBtn[5]:getChildByName("Prompt"):setVisible(data.isShow)
    elseif data.id == RedDotDef.ID.HD_FriendLy_ShiLian then
        self._drawBtn[6]:getChildByName("Prompt"):setVisible(data.isShow)
    elseif data.id == RedDotDef.ID.ShopJiangHun then
        self._btnShop:getChildByName("Prompt"):setVisible(data.isShow)
    end
end

function HappyDrawUI:RegisterGuide()
    if self._drawBtn[3] ~= nil then
        Utils:RegisterGuide(GuideDef.StepId.Guide_Pet_3, self._drawBtn[3], function()
            if self._drawBtn[3] ~= nil and self.m_pUILayer ~= nil then
                self:DrawCallBack(self._drawBtn[3])
            end
        end, nil, true)
    end
    --------------------------------------------
    Utils:RegisterGuide(GuideDef.StepId.Guide_Pet_5, self.m_pReturnBtn, handler(self, HappyDrawUI.RemoveUI), nil, true)
end

return HappyDrawUI