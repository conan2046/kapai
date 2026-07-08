local RechargeUI = LUIBase:New()
RechargeUI.__index = RechargeUI

function RechargeUI:New()
    local o = LUIBase:New()
    setmetatable(o,RechargeUI)  
    o:Init()
    return o
end

--[[
注册UI消息
]]
function RechargeUI:RegistMsgs()
    self.msgIds = 
    {
        LUIPlatinumEvent.goToBuyPlatinum,
        LUILogicEvent.paymentSuccess,
        LUILogicEvent.updateRechargeUIAfterPay,
    }
    self:RegistSelf(self,self.msgIds)
end

function RechargeUI:ProcessEvent(msg)
    if msg.msgId == LUIPlatinumEvent.goToBuyPlatinum then
        self:BuyPlatinum()
        LRechargeDataMgr.m_isBuyPlatinumUI = false
    elseif msg.msgId == LUILogicEvent.paymentSuccess then
        if self._curSelectIdx ~= nil then
            local price = LRoleDataMgr.MyHeroInfo.m_PayPricelist[self._curSelectIdx]
            if price ~= nil then
                price.showDouble = 0

                --若购买的是终身月卡,则刷新界面,去掉终身月卡防止重复购买
                if price.type == 7 then
                    LRoleDataMgr.MyHeroInfo.MyVIPInfo.isHasLmCard = true
                    self:updateUI()
                end
            end
        end
--重新获取VIp信息
        LuaNetSendMsg:QueryVipInfo(1)
    elseif msg.msgId == LUILogicEvent.updateRechargeUIAfterPay then
        self:updateUI()
    end
end

function RechargeUI:Init()
    AppDef.spriteFrameCache:addSpriteFrames("res/csd/Plist/ui_shopPlist.plist", "res/csd/Plist/ui_shopPlist.png")
    AppDef.spriteFrameCache:addSpriteFrames("res/csd/Plist/ui_vipPlist.plist", "res/csd/Plist/ui_vipPlist.png")
    self:RegistMsgs()
    self:CreateUINode("csd/shop/shop_chongzhi.csb")
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitData()
    self:AddTouchEvt()
    self:InitCurVipExp()
    self:InitRechargeBtns()
end

function RechargeUI:onExit()
    -- AppDef.spriteFrameCache:removeSpriteFramesFromFile("res/csd/Plist/ui_shopPlist.plist")
    -- AppDef.spriteFrameCache:removeSpriteFramesFromFile("res/csd/Plist/ui_vipPlist.plist")
    self:Destory()
    -- self.m_pButton = nil    
end

function RechargeUI:AddTouchEvt()
    local function LookRightsCallback(sender)
        Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_VIP)
    end
    --self.m_pLookRightsBtn:addClickEventListener(LookRightsCallback)
	--self:MarkIntaractCObj(self.m_pLookRightsBtn)
end

function RechargeUI:InitData()
    self.m_panelUI = self.m_pUILayer:getChildByName("Panel")

    -- 奖励控件
    self.m_itemUIs = {}
    -- vip等级显示
    local vipDes = self.m_panelUI:getChildByName("VIPDes")

    -- VIP信息区--------------------------------------------------
    self.m_pVipTitle = vipDes:getChildByName("Title")
    -- vip等级
    self.m_pVipNum = self.m_pVipTitle:getChildByName("VIPNumBg"):getChildByName("Num")
    local loadingBg = self.m_pVipTitle:getChildByName("LoadingBg")
    -- 进度条
    self.m_pPercentBar = loadingBg:getChildByName("LoadingBar")
    -- 经验
    self.m_pExpStr = loadingBg:getChildByName("Num")
    -- 查看权利
    self.m_pLookRightsBtn = self.m_pVipTitle:getChildByName("Btn")
    --升级描述
    self.m_pTipsUp = self.m_pVipTitle:getChildByName("TipsUp")
    -----------------------------------------------------------

    -- 充值区--------------------------------------------------
    local des = vipDes:getChildByName("Des")
    des:setTouchEnabled(false)
    -- 充值列表
    self.m_pRechargeList = des:getChildByName("ListView")
    -- 充值元素
    self.m_pCell = des:getChildByName("Bg1")
    self.m_pCell:setTouchEnabled(false)
    for i=1,4 do
        local img = self.m_pCell:getChildByName("Image"..i)
        img:setVisible(false)
        img:getChildByName("LableImage"):getChildByName("Text"):setRotation(0)
    end
    self.m_curSelect = nil
end

--[[
显示当前vip信息
]]
function RechargeUI:InitCurVipExp()
    local info = LRoleDataMgr.MyHeroInfo.MyVIPInfo
    local award
    if info.vipLevel == 0 then
        self.m_selIdx = 0
        award = LDataConstMgr.m_VipAwardInfo[1]
    else
        self.m_selIdx = info.vipLevel
        if self.m_selIdx == #LDataConstMgr.m_VipAwardInfo then
            award = LDataConstMgr.m_VipAwardInfo[info.vipLevel]
        else
            award = LDataConstMgr.m_VipAwardInfo[info.vipLevel + 1]
        end
    end
    local tips
    local curExp = info.vipMoney
    if award.CardPrice > info.vipMoney then -- 
        tips = string.format(GUITips.RSI_VIP_NEXT_INFO, award.CardPrice - info.vipMoney, info.vipLevel + 1)
    else
        curExp = award.CardPrice
        tips = GUITips.RSI_VIP_FULL
    end
    local percentStr = curExp.."/"..award.CardPrice

    --报错处理
    if award.CardPrice <= 0 then
        award.CardPrice = 1
    end
    self.m_pPercentBar:setPercent(curExp*100/award.CardPrice)
    self.m_pExpStr:setString(percentStr)
    self.m_pVipNum:setString(info.vipLevel)

    local pFontSize = self.m_pTipsUp:getFontSize()
    local cellSize = self.m_pTipsUp:getContentSize()
    local color = self.m_pTipsUp:getTextColor()
    if self.m_pNextVipText == nil then
        self.m_pNextVipText = CCAysLabel:create() -- 创建一个带颜色的文本框
        self.m_pNextVipText:setName("Condition")
        self.m_pNextVipText:setPosition(self.m_pTipsUp:getPosition())
        self.m_pTipsUp:setVisible(false)      -- 删除老节点
        self.m_pVipTitle:addChild(self.m_pNextVipText)
    end
    self.m_pNextVipText:triggleInit(tips, cellSize, -132,
        color, pFontSize,false,0,0,0,true,false)
    self.m_pNextVipText:setPositionY(self.m_pTipsUp:getPositionY() + cellSize.height)
end

--[[
充值按钮初始化
]]
function RechargeUI:InitRechargeBtns()
    local btnNum = #LRoleDataMgr.MyHeroInfo.m_PayPricelist
--    dump(LRoleDataMgr.MyHeroInfo.m_PayPricelist, "m_PayPricelist ----------------------")
    self.m_curSelect = nil
    self.m_pRechargeList:removeAllItems()
    local haveLmMcCard = LRoleDataMgr.MyHeroInfo.MyVIPInfo.isHasLmCard
    local cell
    local k = 1
    for i=1, btnNum do
        local data = LRoleDataMgr.MyHeroInfo.m_PayPricelist[i]
        local isNeedShowLmMcCard = haveLmMcCard and data.type == 7
        --如果已经买终身月卡，则不再显示
        if not isNeedShowLmMcCard then
            local idx = (k-1) % 4 + 1
            if idx == 1 then -- 新的一行
                cell = self.m_pCell:clone()
                self.m_pRechargeList:pushBackCustomItem(cell)
            end
            local img = cell:getChildByName("Image"..idx)
            self:InitImg(img, i)
            k = k + 1
        end
    end
end

function RechargeUI:DealRecharge(idx)
    -- print("==========================DealRecharge", idx)
    -- body
    --临时写死
    local priceInfo = LRoleDataMgr.MyHeroInfo.m_PayPricelist[idx]
    if priceInfo == nil then
        return
    end
    local  price = priceInfo.chongzhi / 200
--    dump(priceInfo, "DealRecharge =================>>>>>")
    local haveLmMcCard = LRoleDataMgr.MyHeroInfo.MyVIPInfo.isHasLmCard
    if priceInfo.type == 7 and haveLmMcCard then
        Utils:ShowScrollTips(GUITips.RSI_BUY_SUC_LMMCCARD)
        return
    end
--    print("the price is", price)
    Utils:Payment(price)
    
end

function RechargeUI:InitImg(img, idx)
    function RechargeBtnCallBack(sender)
        if self.m_curSelect ~= nil then
            self.m_curSelect:setVisible(false)
        end
        self.m_curSelect = sender:getChildByName("ChooseBg")
        self.m_curSelect:setVisible(true)
        self.m_curSelect:setLocalZOrder(0)
        self:DealRecharge(sender:getTag())
        self._curSelectIdx = idx
    end
    img:setTouchEnabled(true)
    img:setVisible(true)
    img:setTag(idx)
    img:getChildByName("ChooseBg"):setVisible(false)
    img:addClickEventListener(RechargeBtnCallBack)
	self:MarkIntaractCObj(img)
    for k,v in pairs(img:getChildren()) do
        v:setLocalZOrder(2)
    end
    -- 价格
    local price = LRoleDataMgr.MyHeroInfo.m_PayPricelist[idx]
    local RechargeBg = img:getChildByName("RechargeBg")
    RechargeBg:getChildByName("Value"):setString(tostring(price.chongzhi/10))
    local GoldBg = img:getChildByName("GoldBg")
    GoldBg:getChildByName("Value"):setString(tostring(price.chongzhi))
    -- 返利
    local discountImage = img:getChildByName("DiscountImage")
    if price.fanli > 0 then
        local imageValue = discountImage:getChildByName("Value")
        imageValue:setString(tostring(price.fanli))
    else
        discountImage:setVisible(false)
    end
    
    -- 双倍1可首充，0首充过了
    local doubleBg = img:getChildByName("LableImage")
    if price.showDouble == 1 then
        doubleBg:setVisible(true)
        doubleBg:getChildByName("Text"):setRotation(-41)
    else
        doubleBg:setVisible(false)
    end
    -- 物品
    local GiveImage = img:getChildByName("GiveImage")
    local grid = GiveImage:getChildByName("IconBg")
    grid:setTouchEnabled(true)
    if price.itemId ~= 0 then
        Utils:GetItemCellValue(grid, 0, price.itemId, true, true, price.itemNum)
    else
        GiveImage:setVisible(false)
    end
    local imgStr = string.format(AppDef.GUIRes.Recharg_Level_Img_Format, price.picId)
    if price.type == 6 or price.picId == 0 then
        --月卡
        imgStr = "res/UI/ui_shop/ui_zhizun_tubiao_yueka.png"
    end
    local oldImg = img:getChildByName("GoldImage")

    local imgProd = Utils:CreateSpriteWithFrame(img, oldImg, imgStr)
    local imgProdZOrder = imgProd:getLocalZOrder()
    --print("imgProd ===", imgProdZOrder)

    local pFunction = img:getChildByName("Function")
    pFunction:setLocalZOrder(imgProdZOrder + 1)
    GoldBg:setLocalZOrder(imgProdZOrder + 1)
    GiveImage:setLocalZOrder(imgProdZOrder + 1)
    discountImage:setLocalZOrder(imgProdZOrder + 1)
    RechargeBg:setLocalZOrder(imgProdZOrder + 1)
    --月卡和终身月卡显示
    local _ = pFunction and pFunction:setVisible(price.type == 6 or price.type == 7)
end

function RechargeUI:getMonthCardIndex(type)
    -- body
    for i=1, #LRoleDataMgr.MyHeroInfo.m_PayPricelist do
        local price = LRoleDataMgr.MyHeroInfo.m_PayPricelist[i]
        if price.type == type then
            return i
        end
    end
    return 0
end


function RechargeUI:BuyPlatinum( ... )
    -- body
    local function selecetPlatinum( ... )
        -- body
        -- local items = self.m_pRechargeList:getItems()
        -- print("items ---------------", #items)
        local index = 1
        if LRechargeDataMgr.m_BuyPlatinumType == 1 then
            index = self:getMonthCardIndex(6)
        elseif LRechargeDataMgr.m_BuyPlatinumType == 2 then
            index = self:getMonthCardIndex(7)
        end
        -- print("BuyPlatinum ============>", index)
        local idx = math.floor((index - 1) / 4)
        local raw = 1 + (index - 1) % 4
        -- print("BuyPlatinum ----------->", idx, raw)
        local platinumCell = self.m_pRechargeList:getItem(idx)
        local sender = platinumCell:getChildByName("Image"..raw)
        if self.m_curSelect ~= nil then
            self.m_curSelect:setVisible(false)
        end
        self.m_curSelect = sender:getChildByName("ChooseBg")
        self.m_curSelect:setVisible(true)
        self.m_curSelect:setLocalZOrder(0)
        self:DealRecharge(sender:getTag())
        --超过两排，则滑至底端
        if idx > 1 then
            self.m_pRechargeList:jumpToBottom()
        end
    end
--    self.m_pRechargeList:jumpToBottom()
    performWithDelay(AppDef.CurScene, selecetPlatinum, 0.1)
end

function RechargeUI:updateUI( ... )
    -- body
    self:InitCurVipExp()
    self:InitRechargeBtns()
end

return RechargeUI