local ShopDef = require("View.Shop.ShopDef")


local SelectedGood = LUIBase:New()
SelectedGood.__index = SelectedGood

-- -----------------------------------
function SelectedGood:New(baseUI)
    local o = {}
    setmetatable(o, SelectedGood)
    o:Init(baseUI)
    return o
end

-- -----------------------------------
function SelectedGood:Init(baseUI)
    self.m_pUILayer = baseUI
    self.m_inputNumber = false

    self.m_npcSp = nil
    self.m_goodNameLabel = nil
    self.m_goodDescLabel = nil
    self.m_reduseButton = nil
    self.m_addButton = nil
    self.m_countButton = nil
    self.m_castLabel = nil
    self.m_haveLabel = nil
    self.m_buyButton = nil
    self.m_countImage = nil
    self.m_castIcon = nil
    self.m_haveIcon = nil
    self.m_haveBg = nil
    self.m_nameBg = nil

    self.m_data = nil
    self.m_initX = 0
    self.m_initWidth = 0
    self.m_shopMoneyType = AppDef.MoneyType.YUANBAO
    self.m_isShowHave = true
    self.m_isChangeCount = true

    self.m_buyCallback = nil

    self:RegistMsgs()
    self:InitUIControl()
    self:setCloseCallback()
end

function SelectedGood:onExit()
    self:Destory()
    self:UnSchedule()
    if self.m_inputNumber then
        Utils:DeleteUI("Common.InputNumUI")
        self.m_inputNumber = nil
    end

    self.m_pUILayer = nil
    self.m_inputNumber = nil
    self.m_npcSp = nil
    self.m_goodNameLabel = nil
    self.m_goodDescLabel = nil
    self.m_reduseButton = nil
    self.m_addButton = nil
    self.m_countButton = nil
    self.m_castLabel = nil
    self.m_haveLabel = nil
    self.m_buyButton = nil
    self.m_countImage = nil
    self.m_castIcon = nil
    self.m_haveIcon = nil
    self.m_haveBg = nil
    self.m_nameBg = nil

    self.m_data = nil
    self.m_initX = nil
    self.m_initWidth = nil
    self.m_shopMoneyType = nil
    self.m_isShowHave = nil
    self.m_isChangeCount = nil

    self.m_buyCallback = nil
end

-- -----------------------------------
function SelectedGood:RegistMsgs()
    self.msgIds = 
    {
        LUIRoleDataChangeEvent.TongBaoChanged,
        LUIRoleDataChangeEvent.BindTongBaoChanged,
        LUIRoleDataChangeEvent.MoneyChanged,
        LUIRoleDataChangeEvent.BindMoneyChanged,
        LUIRoleDataChangeEvent.CompeteScoreChanged,
        LUIRoleDataChangeEvent.BangGongChanged,
        LUIRoleDataChangeEvent.ShenHunChanged,
        LUIRoleDataChangeEvent.ZaDanJiFenChanged,
    }
    self:RegistSelf(self, self.msgIds)
end

-------------------------------------
function SelectedGood:ProcessEvent(msg)
    self:updateHaveMoney()
end

-------------------------------------
function SelectedGood:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

function SelectedGood:setBuyCallback(cb)
    if self.m_buyCallback ~= cb then
        self.m_buyCallback = cb
    end
end

function SelectedGood:InitUIControl()
    local baseUI = self.m_pUILayer

    local npcBgSp = baseUI:getChildByName("bg")
    
    -- self.m_npcSp = npcBgSp:getChildByName("npc")
    
    self.m_goodNameLabel = npcBgSp:getChildByName("name")
    self.m_goodDescLabel = npcBgSp:getChildByName("desc")
    self.m_nameBg = npcBgSp:getChildByName("bg_Name")
    self.m_nameBg:setVisible(false)

    self.m_reduseButton = npcBgSp:getChildByName("btn_Minus")
    self.m_addButton = npcBgSp:getChildByName("btn_Plus")

    self.m_countImage = npcBgSp:getChildByName("bg_Num")
    self.m_countButton = self.m_countImage:getChildByName("TextButton")
    self.m_countButton:setTouchEnabled(true)

    local castBgSp = baseUI:getChildByName("bg_Expenditure")
    self.m_castLabel = castBgSp:getChildByName("Value")
    self.m_castIcon = castBgSp:getChildByName("Icon")

    self.m_haveBg = baseUI:getChildByName("bg_Own")
    self.m_haveLabel = self.m_haveBg:getChildByName("Value")
    self.m_haveIcon = self.m_haveBg:getChildByName("Icon")

    self.m_buyButton = baseUI:getChildByName("btn_Buy")
    self.m_buyButtonTxt = self.m_buyButton:getChildByName("Text")
    self.m_buttonStr = self.m_buyButtonTxt:getString()

    local buyTimeBg = npcBgSp:getChildByName("Image_bg")
    self._buyTimeBg = buyTimeBg
    self._buyTimes = buyTimeBg:getChildByName("limitNum")

    self.m_initX = self.m_countImage:getPosition()
    self.m_initWidth = self.m_countImage:getContentSize().width
    
    local function reduseCallback(sender)
        if self.m_data == nil then
            return
        end
        self.m_data.m_count = math.max(self.m_data.m_count - self.m_data.m_unitCount, 0)
        self:setGoodCount(self.m_data.m_count)
    end

    local function addCallback(sender)
        if self.m_data == nil then
            return
        end
        -- print("addCallback ====>", self.m_data.m_count, self.m_data.m_leftTimes)
        if self.m_data.m_leftTimes == -1 or (self.m_data.m_count < 200 and self.m_data.m_count < self.m_data.m_leftTimes) then
            self.m_data.m_count = self.m_data.m_count + self.m_data.m_unitCount
        else
            Utils:ShowScrollTips(GUITips.RSI_PET_MSG40)
        end
        self:setGoodCount(self.m_data.m_count)
    end

    local function buyCallback(sender)
        if self.m_data == nil then
            return
        end
        self:buy()
    end

    local function countCallback(sender)
        if self.m_data == nil or (not self:getCanChangeCount()) then
            return
        end

        local function NumInputCallback(num)
            self:setGoodCount(num)
            self.m_inputNumber = false
        end
    
        Utils:SendMsg(LUILogicEvent.ShowNumInputUI, {math.min(self.m_data.m_maxCount, 200), NumInputCallback})
        self.m_inputNumber = true
    end  

    self.m_reduseButton:addClickEventListener(reduseCallback)
	self:MarkIntaractCObj(self.m_reduseButton)
    self.m_addButton:addClickEventListener(addCallback)
	self:MarkIntaractCObj(self.m_addButton)
    self.m_buyButton:addClickEventListener(buyCallback)
	self:MarkIntaractCObj(self.m_buyButton)
    self.m_countButton:addClickEventListener(countCallback)
	self:MarkIntaractCObj(self.m_countButton)
end

function SelectedGood:setPriceType(_type, isShowHave, isChangeCount)
    self.m_shopMoneyType = _type
    self.m_isShowHave = isShowHave
    self.m_isChangeCount = isChangeCount
end

function SelectedGood:updateData(data)
    if data ~= nil then
        self.m_data = data

        -- dump(self.m_data, "SelectedGood:updateData ==>")

        self.m_maxCount = data.m_price
        self:setNpc(false)
        self:setGoodName(string.format("【%s】", data.m_name))
        self:setGoodDesc(data.m_desc)
        print("SelectedGood ================================>", data.m_leftTimes)
        if data.m_leftTimes == nil then
            data.m_leftTimes = -1
        end
        self:setGoodBuyTimes(data.m_leftTimes)
        self:updateHaveMoney()
        self:updateMoneyIcon()
        self:setGoodCount(data.m_count)
        self:setCtrlButton(self:getCanChangeCount())
        print("self.m_data.m_price ==>", self.m_data.m_price, data.m_count)
        self:setCastCount(self.m_data.m_price)
    else
        self:resetAll()
    end
end

function SelectedGood:setNpc(bVisible)
    -- self.m_npcSp:setVisible(bVisible)
    self.m_nameBg:setVisible(not bVisible)
end

function SelectedGood:setLabel(label, str)
    if type(str) == "string" then
        if #str > 0 then
            label:setVisible(true)
            label:setString(str)
        else
            label:setVisible(false)
        end
    end
end

function SelectedGood:setGoodName(name)
    self:setLabel(self.m_goodNameLabel, name)
end

function SelectedGood:setGoodDesc(desc)
    self:setLabel(self.m_goodDescLabel, desc)
end

function SelectedGood:setGoodBuyTimes(buyTImes)
    -- body
    print("setGoodBuyTimes buyTImes ==>", buyTImes)
    if buyTImes < 0 then
        self._buyTimeBg:setVisible(true)
        -- self:setLabel(self._buyTimes, GUITips.UI_QiRi_Shop_tips18)
        self._buyTimes:setVisible(false)
    else
        self._buyTimeBg:setVisible(true)
        self:setLabel(self._buyTimes, string.format(GUITips.RSI_WWDX_TIPS_2, buyTImes))
    end
end

function SelectedGood:setCtrlButton(bVisible)
    self.m_reduseButton:setVisible(bVisible)
    self.m_addButton:setVisible(bVisible)
    self:setCountBg(bVisible)
end

function SelectedGood:setCountBg(btnVisible)
    local x, y = self.m_countImage:getPosition()
    local size = self.m_countImage:getContentSize()
    if btnVisible then
        self.m_countImage:setPosition(cc.p(self.m_initX, y))
        self.m_countImage:setContentSize(cc.size(self.m_initWidth, size.height))
    else
        self.m_countImage:setPosition(cc.p(self.m_initX+3, y))
        self.m_countImage:setContentSize(cc.size(self.m_initWidth+88, size.height))
    end
    ccui.Helper:doLayout(self.m_countImage)
end

function SelectedGood:setGoodCount(count)
    local price = 0
    if self.m_data ~= nil then
        self.m_data.m_count = count
        price = self.m_data.m_price
    end
    self.m_countButton:setTitleText(tostring(count))
    local cost = self:getTotalPrice(count)
    self:setCastCount(cost)
end

function SelectedGood:getTotalPrice( count )
    -- body
    local totalPrice = 0
    if count < 1 then
        return totalPrice
    end
    local buytimes = self.m_data.buyTimes
    print("getTotalPrice ==>", buytimes, count)
    for i= buytimes, buytimes + count - 1 do
        print("getTotalPrice == 111111111>", i, count)
        local price = self:getCurPrice(i)
        totalPrice = totalPrice + price
    end
    return totalPrice
end

function SelectedGood:getCurPrice(count)
    -- body
    print("SelectedGood:getCurPrice ==>", count)
    local discountIndex = count + 1
    if discountIndex < 1 then
        return 0
    end
    local configData = JsonConfig.m_ShopInfo.getDefByID(self.m_data.m_id)
    if discountIndex > #configData.price_real then
        discountIndex = #configData.price_real
    end
    local value = configData.price_real[discountIndex]
    local rate = value / 100
    local OriginalPrice = configData.price[1][3]
    local price =  rate * OriginalPrice

    return price
end

function SelectedGood:setCastCount(count)
    self:setLabel(self.m_castLabel, tostring(count))
    self:changeCastColor()
end

function SelectedGood:changeCastColor()
    if self.m_haveLabel ~= nil and self.m_castLabel ~= nil then
        local have = tonumber(self.m_haveLabel:getString())
        local cast = tonumber(self.m_castLabel:getString())
        if have ~= nil and cast ~= nil then
            if cast > have then
                self.m_castLabel:setTextColor(cc.c4b(255,0,0,255))
            else
                self.m_castLabel:setTextColor(cc.c4b(120,66,63,255))
            end
        end
    end
end

function SelectedGood:updateHaveMoney()
    local isShowHave = Utils:ToBool(self:getISShowMoney())

    print("isShowHave ===>", isShowHave)
    if self.m_haveBg ~= nil then
        self.m_haveBg:setVisible( isShowHave )
    end

    if isShowHave then
        local priceType = self:getMoneyType()
        -- dump({priceType, AppDef.MoneyType.SHENHUN, LRoleDataMgr.MyHeroInfo:GetDetailData().shenHun})
        print("updateHaveMoney ==>", priceType, AppDef.MoneyType.YUANBAO)
        if priceType == AppDef.MoneyType.YUANBAO then
            self:setHaveCount(LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao())
        elseif priceType == AppDef.MoneyType.YUANBAO_BANG then
            self:setHaveCount(LRoleDataMgr.MyHeroInfo:GetDetailData().BindTongBao)
        elseif priceType == AppDef.MoneyType.JINBI then
            self:setHaveCount(LRoleDataMgr.MyHeroInfo:GetDetailData().Money)
        elseif priceType == AppDef.MoneyType.BANGGONG then
            self:setHaveCount(LRoleDataMgr.Faction.Info:GetselfBangGong())
        elseif priceType == AppDef.MoneyType.SHENHUN then
            self:setHaveCount(LRoleDataMgr.MyHeroInfo:GetDetailData().shenHun)
        elseif priceType == AppDef.MoneyType.COMPETE_POINTS then
            self:setHaveCount(LRoleDataMgr.MyHeroInfo:GetDetailData().CompeteScore)
        elseif priceType == AppDef.MoneyType.ZADAN_POINTS then
            self:setHaveCount(LRoleDataMgr.MyHeroInfo:GetDetailData().ZaDanScore)
        end
    end
end

function SelectedGood:setHaveCount(count)
    print("SelectedGood:setHaveCount === 1111111>", count)
    self:setLabel(self.m_haveLabel, tostring(count))
end

function SelectedGood:updateMoneyIcon()
    local priceType = self:getMoneyType()
    local str = AppDef:GetMoneyIcon(priceType)
    if #str > 0 then
        self.m_castIcon:loadTexture(str, ccui.TextureResType.plistType)
        self.m_haveIcon:loadTexture(str, ccui.TextureResType.plistType)
    end
end

function SelectedGood:getISShowMoney()
    if self.m_data ~= nil then
        return self.m_data.m_isShowHave
    else
        return self.m_isShowHave
    end
end

function SelectedGood:getMoneyType()
    if self.m_data ~= nil then
        return self.m_data.m_priceType
    else
        return self.m_shopMoneyType
    end
end

function SelectedGood:getCanChangeCount()
    if self.m_data ~= nil then
        return self.m_data.m_isChangeCount
    else
        return self.m_isChangeCount
    end
end

function SelectedGood:resetAll()
    self.m_data = nil
    self:setNpc(true)
    self:setGoodName("")
    self:setGoodDesc("")
    self:setGoodBuyTimes(-1)
    self:setGoodCount(0)
    self:updateUI()
    self:setCtrlButton(self:getCanChangeCount())
end

function SelectedGood:updateUI()
    self:updateHaveMoney()
    self:updateMoneyIcon()
end

function SelectedGood:buy()
    if self.m_data == nil then
        Utils:ShowScrollTips(GUITips.RSI_MDSI_MSGI46)
        return
    end

    if self.m_buyCallback ~= nil then
        self.m_buyCallback(self.m_data.m_id, self.m_data.m_count, self.m_data.m_pid, self.m_data.m_pstar)
    end
    --手动购买后,自动购买应该停掉    
    self:UnSchedule()
    self:showBtnText(0)
end


function SelectedGood:TimerCallBack(itemInfo)

    self:setGoodCount(itemInfo.sel_num)
    local function UpdateCD()
        self:UpdateCoolTime()
    end
    self:UnSchedule()
    self.m_coldTime = 2
    self:showBtnText(self.m_coldTime)
    if self.m_coldTime > 0 then
        Utils:unschedule(nil, self.m_schedulerID)
        self.m_schedulerID = nil
        self.m_schedulerID = Utils:schedule(nil, UpdateCD, 1, false)
    end
end

function SelectedGood:UpdateCoolTime()
    self.m_coldTime = self.m_coldTime - 1
    self:showBtnText(self.m_coldTime)
    if self.m_coldTime <= 0 then
        self:showBtnText(self.m_coldTime)
        self:buy()
        self:UnSchedule()
    end
end

function SelectedGood:showBtnText(coldTime)
    -- body
    if coldTime > 0 then
        local str = string.format("(%d)", coldTime)
        self.m_buyButtonTxt:setString(self.m_buttonStr .. str)
    else
        self.m_buyButtonTxt:setString(self.m_buttonStr)
    end
end

function SelectedGood:UnSchedule()
    Utils:unschedule(nil, self.m_schedulerID)
    self.m_schedulerID = nil
end

return SelectedGood