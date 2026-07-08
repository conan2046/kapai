local TimerLabelUI = require("View.Common.TimerLabelUI")

local PetDiscountUI = LUIBase:New()
PetDiscountUI.__index = PetDiscountUI
-- -----------------------------------
function PetDiscountUI:New(uiLayer)
    local o = LUIBase:New()
    setmetatable(o, PetDiscountUI)
    o:Init(uiLayer)
    return o
end

-- -----------------------------------
function PetDiscountUI:Init(uiLayer)
    self.m_pParentUILayer = uiLayer
    self.Script = "WelfareActivity.PetDiscountUI"
    --------------------------------------
    self.m_datas = nil
    self.m_cdTime = 0
    self.m_timer = nil

    self.m_pDiscountText1 = nil
    self.m_pDiscountText2 = nil
    self.m_pListView = nil
    self.m_pListPanel = nil
    self.m_pCellModel = nil
    self.m_pLeftArraw = nil
    self.m_pRightArraw = nil
    --------------------------------------
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    self:Reset()
end

function PetDiscountUI:initData()
    LuaNetSendMsg:QueryPetDiscount(1)
end

-- -----------------------------------
function PetDiscountUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    if self.m_timer then
        self.m_timer:Destory()
        self.m_timer = nil
    end
end

-- -----------------------------------
function PetDiscountUI:RegistMsgs()
    self.msgIds = 
    {
        LUIPetDiscountEvent.BuyResultEvent,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function PetDiscountUI:ProcessEvent(msg)
    if msg.msgId == LUIPetDiscountEvent.BuyResultEvent then
        self:BuyRet(msg.value)
        self:CheckPetAllBuy()
    end
end

function PetDiscountUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

-- -----------------------------------
function PetDiscountUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/PetDiscountLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
    self.m_pParentUILayer:addChild(self.m_pUILayer)
end
-- -----------------------------------
function PetDiscountUI:InitUIControl()
    local panel = self.m_pUILayer:getChildByName("PetDiscount")
    ---------------------------------------------------------
    local pTop = panel:getChildByName("Top")
    self.m_pDiscountText1 = pTop:getChildByName("AtlasLabel_1")
    self.m_pDiscountText2 = pTop:getChildByName("AtlasLabel_2")

    local pText_1 = pTop:getChildByName("Text_1")
    self.m_pLeftTime = pText_1:getChildByName("Time")
    self.m_pLeftTime:setString("")
    self.m_timer = TimerLabelUI:New(self.m_pLeftTime, nil, nil, handler(self, self.TimeReduce))
    ---------------------------------------------------------
    local pInfo = panel:getChildByName("Into")
    self.m_pListView = pInfo:getChildByName("ListView")
    self.m_pListPanel = pInfo:getChildByName("List")
    self.m_pCellModel = pInfo:getChildByName("Reward_1")
    self.m_pCellModel:setTouchEnabled(true)
    self.m_pCellModel:setSwallowTouches(false)
    self.m_pCellModel:addClickEventListener(handler(self, PetDiscountUI.ShowPetInfoClick))
	self:MarkIntaractCObj(self.m_pCellModel)
    self.m_pCellModel:setVisible(false)

    self.m_pLeftArraw = pInfo:getChildByName("Image_L")
    -- self.m_pLeftArraw:setVisible(false)
    self.m_pRightArraw = pInfo:getChildByName("Image_R")
    -- self.m_pRightArraw:setVisible(false)
    ---------------------------------------------------------
end

function PetDiscountUI:ShowPetInfoClick(sender)
    if sender == nil then
        return
    end
    local tag = sender:getTag()
    if tag <= 0 then
        return
    end
    Utils:SendMsg(LUILogicEvent.ShowPetInfo, {tag})
end

function PetDiscountUI:updateData(datas)
    self.m_datas = datas.datas or {}
    self.m_cdTime = datas.cdTime or 0
    self.m_discount = datas.discount or 10

    self.m_pDiscountText1:setString(self.m_discount)
    self.m_pDiscountText2:setString(self.m_discount)

    if self.m_cdTime > 0 and self.m_timer then
        self.m_timer:set(self.m_cdTime)
        self.m_timer:start()
    end
    self:CheckPetAllBuy()
    self:loadData()

    local _ = self.m_pUILayer and self.m_pUILayer:setVisible(true)
end

function PetDiscountUI:Reset()
    local _ = self.m_pUILayer and self.m_pUILayer:setVisible(false)
end

function PetDiscountUI:TimeReduce(pText, h, m, s, left)
    if pText == nil then
        return
    end

    local str = ""
    local day = 0
    if h > 24 then
        day = math.floor(h / 24)
        h = math.fmod(h, 24)
    end
    if day > 0 then
        str = str..tostring(day)..GUITips.Item_Info_Day
    end
    str = str..string.format("%02d:%02d:%02d", h, m, s)
    pText:setString(str)
end

function PetDiscountUI:loadData()
    -- dump(self.m_datas, "self.m_datas-->")
    self.m_pListPanel:removeAllChildren()
    self.m_pListView:removeAllItems()
    local buffer = {}
    local count = #self.m_datas
    for i=1,count do
        local pItem = self.m_pCellModel:clone()
        self:updateItem(pItem, self.m_datas[i], i)
        if count <= 3 then
            table.insert(buffer, pItem)
            self.m_pListPanel:addChild(pItem)
        else
            self.m_pListView:pushBackCustomItem(pItem)
        end
    end
    if #buffer > 0 then
        Utils:AlignNodes(self.m_pListPanel, buffer, {10,0,0}, 3)
    end
    self.m_pLeftArraw:setVisible(count > 3)
    self.m_pRightArraw:setVisible(count > 3)

    local pScrollItem = nil
    local scrollIndex = nil
    if count > 3 then
        for i=1,#self.m_datas do
            if self.m_datas[i].state == 0 then
                pScrollItem = self.m_pListView:getItem(i - 1)
                scrollIndex = i
                break
            end
        end
    end
    if scrollIndex and pScrollItem then
        if scrollIndex <= (#self.m_datas) and scrollIndex > 1 then
            local list = self.m_pListView
            local space = list:getItemsMargin()
            performWithDelay(list, function(sender)
                local time = 1
                if scrollIndex > (#self.m_datas - 3) then
                    list:scrollToPercentHorizontal(100, time, true)
                else
                    local posX = pScrollItem:getPositionX()-space*0.5 - pScrollItem:getAnchorPoint().x*pScrollItem:getContentSize().width
                    local diff = list:getInnerContainerSize().width - list:getContentSize().width
                    local persent = posX / diff * 100
                    list:scrollToPercentHorizontal(math.min(persent, 100), time, true)
                end
            end, 1/10)
        end
    end
end

function PetDiscountUI:updateItem(pItem, pData, ind)
    if pItem == nil or pData == nil or ind == nil then
        return
    end
    pItem:setTag(pData.petId)
    pItem:setVisible(true)

    local pNode = pItem:getChildByName("Node")
    local pAnim = ModelAniNode:create(AppDef.CEnum.ModelAniType.Monster, 0)
    pAnim:InitAni(AppDef.CEnum.ModelAniType.Monster, pData.baseData.pic)
    pAnim:PlayStand(0)
    pNode:addChild(pAnim)
    ------------------------------
    local pDiscount = pItem:getChildByName("Discount")
    local pDiscountText = pDiscount:getChildByName("Text")
    pDiscountText:setString(string.format(GUITips.RSI_PET_DIS_TIPS1, self.m_discount))
    ------------------------------
    local pQuality = pItem:getChildByName("Quality")
    AppDef:GetPetQualityScore(pQuality, pData.baseData.quality)
    ------------------------------
    local pName = pItem:getChildByName("NameBg"):getChildByName("Name")
    pName:setString(pData.baseData.name)
    local color = AppDef:GetPetQualityColor(pData.baseData.quality)
    pName:setTextColor(color)
    ------------------------------
    local pStarList = pItem:getChildByName("NameBg"):getChildByName("StarList")
    local items = pStarList:getItems()
    for i=1,math.max(#items, pData.petStar) do
        local pStarItem = nil
        if i > #items then
            pStarItem = items[1]:clone()
            pStarList:pushBackCustomItem(pStarItem)
        else
            pStarItem = items[i]
        end
        if pStarItem then
            pStarItem:setVisible(i <= pData.petStar)
        end
    end
    pStarList:setContentSize(cc.size(items[1]:getContentSize().width*pData.petStar + pStarList:getItemsMargin()*(pData.petStar-1), pStarList:getContentSize().height))
    ------------------------------
    local pPrice = pItem:getChildByName("Price")
    local pNomalPrice = Utils:FindNodeByName(pPrice, "Gold/Text_1")
    pNomalPrice:setString(pData.price)
    local pDisPrice = Utils:FindNodeByName(pPrice, "Gold/Text_2")
    pDisPrice:setString(pData.discount)
    ------------------------------
    local pType = pItem:getChildByName("Type")
    AppDef:ShowProAttrImg(pType, pData.baseData.petType)
    ------------------------------
    local pBtn = pItem:getChildByName("btn")
    if pData.state == 1 then
        pBtn:setEnabled(true)
        pBtn:setBright(false)
        pBtn:getChildByName("Text"):setString(GUITips.RSI_PET_DIS_TIPS2)
    else
        pBtn:setTag(ind)
        pBtn:setBright(true)
        pBtn:setEnabled(true)
        pBtn:addClickEventListener(handler(self, PetDiscountUI.BuyClick))
		self:MarkIntaractCObj(pBtn)
    end
end

function PetDiscountUI:BuyClick(sender)
    local ind = sender:getTag()
    if ind <= 0 or ind > #self.m_datas then
        return
    end
    local data = self.m_datas[ind]
    if data == nil then
        return
    end
    if data.discount > LRoleDataMgr.MyHeroInfo:GetDetailData().TongBao then
        local function okCallback()
            Utils:OpenRechargeMainUI()
        end
        Utils:ShowDialogOKCancel(GUITips.RSI_GL_CPT_TIP6, okCallback, function()end)
        return
    end
    LuaNetSendMsg:QueryPetDiscount(2, ind)
end

function PetDiscountUI:BuyRet(ind)
    if ind == nil or self.m_datas[ind] == nil then
        return
    end
    self.m_datas[ind].state = 1
    self:updateItem(self.m_pListView:getItem(ind - 1), self.m_datas[ind], ind)
end

function PetDiscountUI:CheckPetAllBuy( ... )
    -- body

    LRechargeDataMgr.m_isTwoSPetIconShow = self:CheckIsNoTwoSPetAllBuy()
    LRechargeDataMgr.m_isThreePetIconShow = self:CheckIsNoThreeSPetAllBuy()

--    print("CheckPetAllBuy", LRechargeDataMgr.m_isTwoSPetIconShow, LRechargeDataMgr.m_isThreePetIconShow)
    --更新付费预告
    Utils:SendMsg(LUILogicEvent.updatePreViewUI)
end

function PetDiscountUI:CheckIsNoTwoSPetAllBuy( ... )
    -- body
    local count = #self.m_datas
--    dump(self.m_datas, "CheckIsTwoSPetAllBuy")
    for i=1, count do
        local quality = Utils:GetPetQuality(self.m_datas[i])
        --红色以下
        if quality < 7 then
            if self.m_datas[i].state == 0 then
                return true
            end
        end
    end
    return false
end

function PetDiscountUI:CheckIsNoThreeSPetAllBuy ( ... )
    -- body
    local count = #self.m_datas
--    dump(self.m_datas, "CheckIsTwoSPetAllBuy")
    for i=1, count do
        local quality = Utils:GetPetQuality(self.m_datas[i])
        print("look it state", self.m_datas[i].state)
        --红色以上
        if quality >= 7 then
            if self.m_datas[i].state == 0 then
                return true
            end
        end
    end
    return false
end

return PetDiscountUI