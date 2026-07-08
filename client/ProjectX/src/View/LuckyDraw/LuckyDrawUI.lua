local LuckyDrawUI = LUIBase:New()
LuckyDrawUI.__index = LuckyDrawUI

local ShopDef = require('View.Shop.ShopDef')
local LDClickAnimController = require('View.LuckyDraw.LDClickAnimController')
local LDScaleAnimController = require('View.LuckyDraw.LDScaleAnimController')
local LDSingleRetUI = require('View.LuckyDraw.LDSingleRetUI')

LuckyDrawUI.IsHideInBattle = true

-------------------------------------
function LuckyDrawUI:New()
    local o = {}
    setmetatable(o, LuckyDrawUI)
    o:Init()
    return o
end

-------------------------------------
function LuckyDrawUI:Init()
    self.Script = "LuckyDraw.LuckyDrawUI"
    self.m_pInfo = nil
    ------------------------------------------------
    self.m_pNodes = {}
    ------------------------------------------------
    self.m_pSendInfo = {}
    ------------------------------------------------
    self.m_pCenterView = nil
    self.m_pPageItem = nil
    self.m_pAnimController = nil
    self.m_pScaleController = nil
    self.m_pPosController = nil
    ------------------------------------------------
    self.m_starItem = nil
    ------------------------------------------------
    self.m_data = {}
    self.m_pTablePanel = nil
    self.m_pTableView = nil
    self.m_pTableCell = nil
    self.m_tableCount = 0
    ----------------------------------------------------
    self.m_pMaskTouchLayer = nil
    --单抽----------------------------------------------
    self.m_pDanChouBg = nil
    self.m_pDanChouBgImage = nil
    self.m_pDanChouText = nil
    self.m_pDanChouBgNum = nil
    self.m_pDanChouRedDot = nil
    self.m_pDanChouCostItem = nil
    --十连----------------------------------------------
    self.m_pShiLianBg = nil
    self.m_pShiLianBgImage = nil
    self.m_pShiLianText = nil
    self.m_pShiLianBgNum = nil
    self.m_pShiLianRedDot = nil
    self.m_pShiLianTips = nil
    self.m_pShiLianCostItem = nil
    ------------------------------------------------
    self.m_pYBNum = nil
    self.m_pBindYBNum = nil
    self.m_pJBNum = nil

    ------------------------------------------------
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    self:RegisterQuik()
    LuaNetSendMsg:SendExtractPetMsg(1)
end

-------------------------------------
function LuckyDrawUI:onExit()
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_ZM_1)
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_ZM_FINISH)
    self:Destory()
    if self.m_schedule ~= nil then
        Utils:unschedule(nil, self.m_schedule)
        self.m_schedule = nil
    end
    self.m_pUILayer = nil
    self.m_pMoneyNum1 = nil
    if self.m_pScaleController then
        self.m_pScaleController:onExit()
        self.m_pScaleController = nil
    end
    self.m_pReturnBtn = nil
    self.m_pInfo = nil
    self.m_pPageItem:release()
    self.m_pPageItem = nil
    self.m_starItem:release()
    self.m_starItem = nil
    self.m_pTableView = nil
    self.m_pDanChouButton = nil
    if self.m_pDanChouCostItem then
        self.m_pDanChouCostItem:onExit(true)
        self.m_pDanChouCostItem = nil
    end
    if self.m_pShiLianCostItem then
        self.m_pShiLianCostItem:onExit(true)
        self.m_pShiLianCostItem = nil
    end
    Utils:FreeTable(self.m_pNodes)
    self.m_pNodes = nil
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
    --Utils:CheckGuide(GuideDef.StepId.Guide_SHENJ)
    local pAni = self.m_pMaskTouchLayer:getChildByTag(0xff)
    if pAni then
        pAni:stopAllActions()
    end
    if self.m_isShowMsgBox then
        Utils:SendMsg(LUIMsgBoxEvent.HideMsgBox)
        self.m_isShowMsgBox = nil
    end
    self.m_pMaskTouchLayer = nil
    self.m_pDanChouTips = nil
end

-------------------------------------
function LuckyDrawUI:InitUIControl()
    local pPanel = self.m_pUILayer:getChildByName("Panel")
    self.m_pMaskTouchLayer = self.m_pUILayer:getChildByName("Panel_1")
    if self.m_pMaskTouchLayer ~= nil then
        self.m_pMaskTouchLayer:setVisible(false)
    end
    -----------------------------------------------------------
    local pPreviewList = pPanel:getChildByName("PreviewList")
    table.insert(self.m_pNodes, pPreviewList)

    local pFunction = pPanel:getChildByName("Function")
    table.insert(self.m_pNodes, pFunction)

    self.m_pCenterView = pPanel:getChildByName("PositionList")
    self.m_pCenterView:setContentSize(cc.size(790, 275))
    self.m_pCenterView:setClippingEnabled(true)
    table.insert(self.m_pNodes, self.m_pCenterView)

    self.m_pPageItem = self.m_pCenterView:getChildByName("Position1")
    self.m_pPageItem:retain()
    self.m_pPageItem:removeFromParent(false)
    self.m_pPageItem:setVisible(false)
    -----------------------------------------------------------
    local pTitleBg = pPreviewList:getChildByName('TitleBg')
    pTitleBg:addClickEventListener(function(sender)
        self:preview()
    end)
	self:MarkIntaractCObj(pTitleBg)
    self.m_pTablePanel = pPreviewList:getChildByName("ListView")
    self.m_pTablePanel:setTouchEnabled(false)

    local pItem = pPreviewList:getChildByName("IconBg")
    pItem:setVisible(false)

    self.m_pTableCell = pItem
    self.m_starItem = pItem:getChildByName("Star")
    self.m_starItem:retain()
    self.m_starItem:removeFromParent(false)
    self.m_starItem:setTouchEnabled(false)

    self.m_pTableView = self:InitTableView(self.m_pTablePanel)
    -----------------------------------------------------------
    self:initMoneyPanel(pFunction)
    self:initButton(pFunction)
    -----------------------------------------------------------
    self:SetNodeVisible(false)
end

function LuckyDrawUI:SetNodeVisible(isVisible)
    for i=1,#self.m_pNodes do
        local _ = self.m_pNodes[i] and self.m_pNodes[i]:setVisible(isVisible)
    end
end

-------------------------------------
function LuckyDrawUI:RegistMsgs()
    self.msgIds = {
        LUILuckDrawEvent.ReloadLDData,
        LUIRoleDataChangeEvent.TongBaoChanged,
        LUILuckDrawEvent.DrawSuccess,
        LUIPetEvent.GetPet,
    }

    self:RegistSelf(self, self.msgIds)
end

-------------------------------------
function LuckyDrawUI:ProcessEvent(msg)
    if msg.msgId == LUILuckDrawEvent.ReloadLDData then
        self:RegisterGuide()
        self:SetNodeVisible(true)
        self:LoadData(msg.value)
    elseif msg.msgId == LUIRoleDataChangeEvent.TongBaoChanged then
        self:updateMoney(AppDef.MoneyType.YUANBAO, LRoleDataMgr.MyHeroInfo:GetDetailData().TongBao)
    elseif msg.msgId == LUILuckDrawEvent.DrawSuccess then
        self:showDrawResult(msg.value)
    elseif msg.msgId == LUIPetEvent.GetPet then
        if self.m_pTableView then
            local offset = self.m_pTableView:getContentOffset()
            self.m_pTableView:reloadData()
            self.m_pTableView:setContentOffset(offset)
        end
    end
end

function LuckyDrawUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    local pPanel = self.m_pUILayer:getChildByName("Panel")

    local pBtn_back = pPanel:getChildByName("ReturnBtn")
    self.m_pReturnBtn = pBtn_back
    pBtn_back:addClickEventListener(function(sender)
        self:RemoveUI()
    end)
	self:MarkIntaractCObj(pBtn_back)
end

-------------------------------------
function LuckyDrawUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/DrawCardsLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

------------------------------------
function LuckyDrawUI:RegisterQuik()
    
end

function LuckyDrawUI:InitTableView(tbPanel)
    local cfg = {}
    cfg.tbPanel = tbPanel
    cfg.direction = cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    cfg.cellSizeForTable = function(sender,idx)
        local size = self.m_pTableCell:getContentSize()
        if idx == self.m_tableCount - 1 then
            return size.width, size.height
        end
        return size.width+10, size.height
    end
    cfg.tableCellAtIndex = function(sender, idx)
        return self:TableCellAtIndex(sender, idx+1)
    end

    cfg.numberOfCellsInTableView = function() 
        return self.m_tableCount
    end
    cfg.scrollViewDidScroll = function(view) 
        self.m_isDraging = view:isDragging() 
    end
    cfg.tableCellTouched = function(sender, cell)
        self:tableCellTouched(cell:getIdx() + 1)
    end

    return Utils:createTableView(cfg)
end

------------------------------------
function LuckyDrawUI:LoadData(info)
    Utils:FreeTable(self.m_pInfo)
    self.m_pInfo = nil
    self.m_pInfo = info
    -------------------------------------------------------------
    self.m_pCenterView:setContentSize(cc.size(AppDef.frameSize.width, self.m_pCenterView:getContentSize().height + 200))
    -------------------------------------------------------------
    local pParticleNode = self.m_pPageItem:getChildByName("Particle_1")
    local plist = pParticleNode:getResourceFile()
    -------------------------------------------------------------
    local cfg = {}
    cfg.rootUI = self.m_pCenterView
    cfg.nodes = {}
    cfg.callback = handler(self, LuckyDrawUI.selectCallback)
    -------------------------------------------------------------
    --TODO：补丁，只显示一个炉子
    while(#info > 1) do
        table.remove(info, #info)
    end
    -------------------------------------------------------------
    local initIndex = 1
    for i=1,#info do
        local data = info[i]
        local item = self.m_pPageItem:clone()
        self:setCellItem(item, i, data, pParticleNode, plist)
        self.m_pCenterView:addChild(item)
        table.insert(cfg.nodes, item)
        if Utils:ToBool(data.isOpen) and i > initIndex then
            initIndex = i
        end
    end
    -------------------------------------------------------------
    if self.m_schedule then
        Utils:unschedule(nil, self.m_schedule)
        self.m_schedule = nil
    end
    self.m_schedule = Utils:schedule(nil, handler(self, LuckyDrawUI.UpdateCD), 1, false)

    -------------------------------------------------------------
    if self.m_pAnimController == nil then
        self.m_pAnimController = LDClickAnimController:New(cfg)
    else
        self.m_pAnimController:updateConfig(cfg)
    end
    self.m_pAnimController:itemClick(initIndex, true)
    -------------------------------------------------------------
    if self.m_pScaleController == nil then
        self.m_pScaleController = LDScaleAnimController:New(cfg)
    end
end

function LuckyDrawUI:selectCallback(index)
    local data = self.m_pInfo[index]
    Utils:FreeTable(self.m_data)
    self.m_data = nil
    self.m_data = data.showPetIds
    self.m_pTablePanel:setVisible(true)
    self.m_tableCount = #self.m_data
    self.m_pTableView:reloadData()

    self:updateDanChou()
    self:updateShiLian()
    self:updateChildren(index)
end

function LuckyDrawUI:resetItems()
    self:updateChildren(0)
end

function LuckyDrawUI:updateChildren(index)
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

function LuckyDrawUI:TableCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild = nil
    local data = self.m_data[idx]
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pTableCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cellChild:setTouchEnabled(false)
        cellChild:setSwallowTouches(false)
        cell:addChild(cellChild)

        local pBg = cellChild:getChildByName('Bg')
        local pIconParent = pBg:getChildByName('Icon')
        pIconParent:setTouchEnabled(false)
    else
        cellChild = cell:getChildByTag(123)
    end
    self:setItem(cellChild, data, idx)
    return cell
end

--[[
idx:从1开始
]]
function LuckyDrawUI:tableCellTouched(idx)
    if self.m_isDraging then
        return
    end
    local data = self.m_data[idx]
    Utils:SendMsg(LUILogicEvent.ShowPetInfo, {data})
end

function LuckyDrawUI:setItem(cell, id, index)
    local data = LPetDataMgr:FindPetDataById(id)
    if data == nil then
        return
    end

    local pBg = cell:getChildByName('Bg')
    local pColor = pBg:getChildByName('Color')
    local pIcon = pBg:getChildByName('Icon')
    Utils:ShowPetHeadImg(pIcon, data.pic, pColor, data.quality, PetkaPaiManager:IsShiny(data))

    local pQuality = pBg:getChildByName('Quality')
    AppDef:GetPetQualityScore(pQuality, data.quality)

    local pCareer = pBg:getChildByName('Career')
    AppDef:ShowProAttrImg(pCareer, data.petType)
    local pName = pBg:getChildByName('Name')
    pName:setString(data.name)
    pName:setTextColor(AppDef:GetPetQualityColor(data.quality))
    pName:enableShadow()

    local pHave = pBg:getChildByName('Have')
    pHave:setVisible(Utils:ToBool(LRoleDataMgr.Pet:GetPetById(data.id)))

    local pStarList = cell:getChildByName("StarsList")
    pStarList:setTouchEnabled(false)
    pStarList:removeAllItems()
    for i=1,data.initstar do
        local pStar = self.m_starItem:clone()
        pStarList:pushBackCustomItem(pStar)
    end
end

function LuckyDrawUI:preview()
    local data = self.m_pInfo[self:getSelectIndex()]
    Utils:InitUI("LuckyDraw.LDPetRewardUI",AppDef.UIType.SecondClassLayer, data.kind)
end

function LuckyDrawUI:initMoneyPanel(panel)
    local pGold = panel:getChildByName("Gold")
    pGold:getChildByName("Button"):addClickEventListener(handler(self, LuckyDrawUI.openMoney))
	self:MarkIntaractCObj(pGold:getChildByName("Button"))
    self.m_pMoneyNum1 = pGold:getChildByName("Num")
    self:ProcessEvent({msgId=LUIRoleDataChangeEvent.TongBaoChanged})
end

function LuckyDrawUI:initButton(panel)
    local pButton1 = panel:getChildByName("Button1")
    pButton1:addClickEventListener(handler(self, LuckyDrawUI.SingleCallback))
	self:MarkIntaractCObj(pButton1)
    self.m_pDanChouButton = pButton1

    local pButton2 = panel:getChildByName("Button2")
    pButton2:addClickEventListener(handler(self, LuckyDrawUI.ShiLianCallback))
	self:MarkIntaractCObj(pButton2)
    local pRanksBtn = panel:getChildByName("RanksBtn")
    pRanksBtn:addClickEventListener(handler(self, LuckyDrawUI.RecommendCallback))
	self:MarkIntaractCObj(pRanksBtn)
    local pPetBtn = panel:getChildByName("PetBtn")
    pPetBtn:addClickEventListener(handler(self, LuckyDrawUI.PetCallback))
	self:MarkIntaractCObj(pPetBtn)
    ------------------------------------------------
    self.m_pDanChouTips = pButton1:getChildByName("Des_0")
    self.m_pDanChouText = pButton1:getChildByName("Text")
    self.m_pDanChouRedDot = pButton1:getChildByName("Dot")
    self.m_pDanChouCostBg = pButton1:getChildByName("Bg")
    self.m_pDanChouCostIcon = self.m_pDanChouCostBg:getChildByName("GoldImage")
    self.m_pDanChouCostNum = self.m_pDanChouCostBg:getChildByName("Num")
    self.m_pDanChouRedDot:setVisible(false)
    self.m_pDanChouTips:setString("")

    ------------------------------------------------
    self.m_pShiLianText = pButton2:getChildByName("Text")
    self.m_pShiLianRedDot = pButton2:getChildByName("Dot")
    self.m_pShiLianTips = pButton2:getChildByName("Des")
    self.m_pShiLianCostBg = pButton2:getChildByName("Bg")
    self.m_pShiLianCostIcon = self.m_pShiLianCostBg:getChildByName("GoldImage")
    self.m_pShiLianCostNum = self.m_pShiLianCostBg:getChildByName("Num")
    self.m_pShiLianRedDot:setVisible(false) --TODO:目前先隐藏
end

function LuckyDrawUI:updateMoney(_type, value)
    if _type == AppDef.MoneyType.YUANBAO then
        self.m_pMoneyNum1:setString(tostring(value))
    end
end

function LuckyDrawUI:updateItem(pIcon, str, pNum, value)
    if pIcon and str then
        pIcon:loadTexture(str, ccui.TextureResType.localType)
    end
    pNum:setString(tostring(value))
end

function LuckyDrawUI:openMoney()
    Utils:InitUI("Vip.VipMainUI",AppDef.UIType.FirstClassLayer)
end

function LuckyDrawUI:RecommendCallback(sender)
    Utils:OpenPetArchiveUI(2)
end

function LuckyDrawUI:PetCallback(sender)
    Utils:OpenPetArchiveUI(1) 
end

function LuckyDrawUI:SingleCallback(sender)
    if self.m_pAnimController and self.m_pAnimController:isAniming() then
        Utils:ShowScrollTips(GUITips.RSI_LD_TIP8)
        return
    end
    if self.m_pInfo == nil then
        return
    end
    
    local data = self.m_pInfo[self:getSelectIndex()]
    local itemData = data.items[1]
    self:buyCheck(data, itemData, true)
end

function LuckyDrawUI:ShiLianCallback(sender)
    if self.m_pAnimController and self.m_pAnimController:isAniming() then
        Utils:ShowScrollTips(GUITips.RSI_FACTION_MSG204)
        return
    end
    local data = self.m_pInfo[self:getSelectIndex()]
    local itemData = data.items[2]
    self:buyCheck(data, itemData)
end

function LuckyDrawUI:buyCheck(data, itemData, isSingle)
    if data.isOpen == 0 then
        Utils:ShowScrollTips(GUITips.RSI_LD_TIP7)
        return
    end

    if (itemData.type == 1 and itemData.cd > 0) or (itemData.type == 2) then
        local num = LRoleDataMgr.Equip:CountItemNumById(itemData.needItemId)
        local p = LItemMgr:getItem(itemData.needItemId)
        if p and (num < itemData.needItemNum) then
            local name = p:Getm_name()
            self:showMsgBox(itemData.needYB, name, function()
                if itemData.needYB > LRoleDataMgr.MyHeroInfo:GetDetailData().TongBao then
                    Utils:ShowScrollTips(GUITips.RSI_LD_TIP11)
                    return
                end

                self:SendNetMsg(data.kind, itemData.type)
                self.m_isShowMsgBox = false
            end)
        else
            self:SendNetMsg(data.kind, itemData.type)
        end
    else
        self:SendNetMsg(data.kind, itemData.type)
    end
    if isSingle then
        LDSingleRetUI.castId = itemData.needItemId
        LDSingleRetUI.continueCb = handler(self, LuckyDrawUI.continueCallback)
        LDSingleRetUI.isDrawInit = true
    end
end

function LuckyDrawUI:updateDanChou()
    if self.m_pAnimController and self.m_pAnimController:isAniming() then
        Utils:ShowScrollTips(GUITips.RSI_FACTION_MSG204)
        return
    end
    local data = self.m_pInfo[self:getSelectIndex()]
    local itemData = data.items[1]
    self.m_pDanChouCostItem = Utils:GetItemCellValue(self.m_pDanChouCostIcon, 0, itemData.needItemId, false, false, 0, self.m_pDanChouCostItem, false, true)
    self.m_pDanChouCostItem:SetCanClick(true)
    self.m_pDanChouCostItem:SetIsNonAutoFree(true)

    if itemData.cd > 0 then
        self.m_pDanChouText:setString(GUITips.RSI_LD_TIP4)
    else
        self.m_pDanChouText:setString(GUITips.RSI_LD_TIP2)
    end
    self:UpdateCDLabel()
    local num = LRoleDataMgr.Equip:CountItemNumById(itemData.needItemId)
    self:setCostNumber(self.m_pDanChouCostNum, num, itemData.needItemNum)
    self:updateDanChouRedDot()
end

function LuckyDrawUI:setCostNumber(pText, haveNum, castNum)
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

function LuckyDrawUI:updateShiLian()
    if self.m_pAnimController and self.m_pAnimController:isAniming() then
        Utils:ShowScrollTips(GUITips.RSI_FACTION_MSG204)
        return
    end
    local data = self.m_pInfo[self:getSelectIndex()]
    local itemData = data.items[2]
    self.m_pShiLianCostItem = Utils:GetItemCellValue(self.m_pShiLianCostIcon, 0, itemData.needItemId, false, false, 0, self.m_pShiLianCostItem, false, true)
    self.m_pShiLianCostItem:SetIsNonAutoFree(true)
    self.m_pShiLianCostItem:SetCanClick(true)
    if itemData.isFirstTimes then
        self.m_pShiLianTips:setString(GUITips.RSI_LD_TIP12)
    else
        if itemData.mustBeOrangeTimes == 1 then
            self.m_pShiLianTips:setString(GUITips.RSI_LD_TIP10)
        else
            self.m_pShiLianTips:setString(string.format(GUITips.RSI_LD_TIP5, itemData.mustBeOrangeTimes))
        end
    end
    local num = LRoleDataMgr.Equip:CountItemNumById(itemData.needItemId)
    self:setCostNumber(self.m_pShiLianCostNum, num, itemData.needItemNum)
    self:CheckNeedItemMeet(self.m_pShiLianRedDot, itemData.needItemId, itemData.needItemNum)
end

function LuckyDrawUI:UpdateCD(dt)
    if self.m_pInfo then
        for i=1,#self.m_pInfo do
            local info = self.m_pInfo[i]
            if info then
                for j=1,#info.items do
                    if info.items[j].cd-1 >= 0 then
                        info.items[j].cd = info.items[j].cd - 1
                    end
                end
            end
        end
        self:UpdateCDLabel()
        self:updateDanChouRedDot()
    end
end

function LuckyDrawUI:UpdateCDLabel()
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

function LuckyDrawUI:updateDanChouRedDot()
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

function LuckyDrawUI:CheckNeedItemMeet(pRed, itemId, itemNum)
    local _ = pRed and pRed:setVisible(LRoleDataMgr.Equip:CountItemNumById(itemId) >= itemNum)
end

------------------------------------
function LuckyDrawUI:showMsgBox(needYB, name, okCallback)
    local data = {}
    data.desc = string.format(GUITips.RSI_LD_TIP6, needYB, name)
    data.okCallback = okCallback
    data.cancelCallback = function() self.m_isShowMsgBox = false end
    Utils:SendMsg(LUIMsgBoxEvent.ShowMsgBox, data)
    self.m_isShowMsgBox = true
end

function LuckyDrawUI:showDrawResult(retInfo)
    if self.m_pInfo == nil or self.m_pInfo[retInfo.kind] == nil then
        return
    end
    local kindData = self.m_pInfo[retInfo.kind]
    local itemData = kindData.items[1]
    local data = {
        data=retInfo
    }
    if retInfo.opType == 1 then
        self:showDanChouResult(retInfo)
    elseif retInfo.opType == 2 then
        self:showShiLianResult(retInfo)
        Utils:InitUI("LuckyDraw.LDTenRetUI", AppDef.UIType.PopWindow, data)
    end
    retInfo:Delete()
    local _ = self.m_pMaskTouchLayer and self.m_pMaskTouchLayer:setVisible(false)
end

function LuckyDrawUI:showDanChouResult(retInfo)
    local kindData = self.m_pInfo[retInfo.kind]
    local itemData = kindData.items[1]
    for i=1,#self.m_pInfo do
        self.m_pInfo[i].items[1].cd = retInfo.cd
    end

    self:UpdateCDLabel()
    if itemData.cd > 0 then
        self.m_pDanChouText:setString(GUITips.RSI_LD_TIP4)
    else
        self.m_pDanChouText:setString(GUITips.RSI_LD_TIP2)
    end

    local num = LRoleDataMgr.Equip:CountItemNumById(itemData.needItemId)
    self:setCostNumber(self.m_pDanChouCostNum, num, itemData.needItemNum)
    self:CheckNeedItemMeet(self.m_pDanChouRedDot, itemData.needItemId, itemData.needItemNum)
end

function LuckyDrawUI:showShiLianResult(retInfo)
    local kindData = self.m_pInfo[retInfo.kind]
    local itemData = kindData.items[2]
    itemData.mustBeOrangeTimes = retInfo.mustBeOrangeTimes

    if itemData.mustBeOrangeTimes == 1 then
        self.m_pShiLianTips:setString(GUITips.RSI_LD_TIP10)
    else
        self.m_pShiLianTips:setString(string.format(GUITips.RSI_LD_TIP5, itemData.mustBeOrangeTimes))
    end

    local num = LRoleDataMgr.Equip:CountItemNumById(itemData.needItemId)
    self:setCostNumber(self.m_pShiLianCostNum, num, itemData.needItemNum)
    self:CheckNeedItemMeet(self.m_pShiLianRedDot, itemData.needItemId, itemData.needItemNum)
end

function LuckyDrawUI:setCellItem(item, i, info, pParticleNode, plist)
    if item == nil then
        return
    end
    item:setLocalZOrder(1)
    item:setAnchorPoint(cc.p(0.5, 0.5))
    item:setTag(i)
    item:setTouchEnabled(true)
    item:setVisible(true)
    item:addClickEventListener(handler(self, LuckyDrawUI.itemClick))
	self:MarkIntaractCObj(item)
    local pParNode = cc.ParticleSystemQuad:create(plist)
    pParNode:setPosition(cc.p(pParticleNode:getPosition()))
    pParNode:setScaleX(pParticleNode:getScaleX())
    pParNode:setScaleY(pParticleNode:getScaleY())
    item:addChild(pParNode)
    pParNode:setName(pParticleNode:getName())

    local pNameBg = item:getChildByName("NameBg")
    local pText = pNameBg:getChildByName("Text")
    if info.items and #info.items > 0 then
        pText:setString(info.items[1].name)
    end
end

function LuckyDrawUI:itemClick(sender)
    local index = sender:getTag()
    local data = self.m_pInfo[index]
    if not Utils:ToBool(data.isOpen) then
        Utils:ShowScrollTips(string.format(GUITips.RSI_LD_TIP9, data.items[1].openLevel))
        return
    end
    if self.m_pAnimController and not self.m_pAnimController:isAniming() and self:getSelectIndex() ~= index then
        self:resetItems()
        self.m_pAnimController:itemClick(index)
    end
end

function LuckyDrawUI:continueCallback()
    if self.m_pAnimController and self.m_pAnimController:isAniming() then
        Utils:ShowScrollTips(GUITips.RSI_FACTION_MSG204)
        return
    end
    if self.m_pInfo == nil then
        return
    end
    local data = self.m_pInfo[self:getSelectIndex()]
    local itemData = data.items[1]
    -- LuaNetSendMsg:SendExtractPetMsg(2, data.kind, itemData.type)
    self:buyCheck(data, itemData, true)
end

function LuckyDrawUI:getSelectIndex()
    if self.m_pAnimController then
        return self.m_pAnimController.m_selected
    end
    return 1
end

function LuckyDrawUI:SendNetMsg(kind, itemType)
    self.m_pSendInfo = {}
    self.m_pSendInfo.kind = kind
    self.m_pSendInfo.itemType = itemType
    self:StartDraw()
end

function LuckyDrawUI:StartDraw()
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

function LuckyDrawUI:RegisterGuide()
    --------------------------------------------
    Utils:RegisterGuide(GuideDef.StepId.Guide_ZM_1, self.m_pDanChouButton, handler(self, LuckyDrawUI.SingleCallback), nil, true)
    --------------------------------------------
    Utils:RegisterGuide(GuideDef.StepId.Guide_ZM_FINISH, self.m_pReturnBtn, handler(self, LuckyDrawUI.RemoveUI), nil, true)
end

return LuckyDrawUI