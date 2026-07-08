local FindTimes = LUIBase:New()
FindTimes.__index = FindTimes
FindTimes.IsHideInBattle = true
function FindTimes:New(userData)
    local o = LUIBase:New()
    setmetatable(o,FindTimes) 
    o:Init(userData)
    return o
end

function FindTimes:Init(userData)
    self:CreateUINode("csd/common/ZhaohuiPopup.csb")
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:InitVariable(userData)
    self:InitPanel()
end

--[[
注册UI消息
]]
function FindTimes:RegistMsgs()
   
end

function FindTimes:ProcessEvent(msg)
  
end
function FindTimes:InitVariable(userData)
    self._data=userData.data
    self._findTimes=1 
end


function FindTimes:InitPanel()
    local panel = self.m_pUILayer:getChildByName("Popup")
    local closeBtn = panel:getChildByName("Btn_close")
    closeBtn:addClickEventListener(handler(self, FindTimes.CloseUI))
    self.m_pItemListView=panel:getChildByName("item_layer")
    self.m_pItem=panel:getChildByName("Icon_1")
    local buyBtn = panel:getChildByName("Btn_Buy")
    local leftOne = panel:findChildByName("Panel_3/Btn_Minus")
    local leftTen = panel:findChildByName("Panel_3/Btn_Minus10")
    local rightOne = panel:findChildByName("Panel_3/Btn_Plus")
    local rightTen = panel:findChildByName("Panel_3/Btn_Plus10")
    buyBtn:addClickEventListener(handler(self,FindTimes.RecoverResources))

    leftOne:addClickEventListener(handler(self,FindTimes.ChangeFindTimes))
    leftTen:addClickEventListener(handler(self,FindTimes.ChangeFindTimes))
    rightOne:addClickEventListener(handler(self,FindTimes.ChangeFindTimes))
    rightTen:addClickEventListener(handler(self,FindTimes.ChangeFindTimes))


    local findtimes = panel:findChildByName("Panel_4/text1/buy_num")
    findtimes:setString(self._data.leftTimes)
    local costImage = buyBtn:findChildByName("buy_layer/Icon_item")
    local str = AppDef:GetMoneyIconById(self._data.cost[1])
    costImage:loadTexture(str, ccui.TextureResType.plistType)
    local mineNum = buyBtn:findChildByName("buy_layer/text")
    mineNum:setVisible(true)
    local mineNumText = mineNum:getChildByName("mine")
    mineNumText:setString(LRoleDataMgr:GetMoney(self._data.cost[1]))
    self.costNumText = buyBtn:findChildByName("buy_layer/Text")
    self.findTimesText=panel:findChildByName("Panel_3/Count/Value")


    self:UpdateCostPrice()
    self:InitListView()
end
function FindTimes:UpdateCostPrice()
    self.findTimesText:setString(tostring(self._findTimes))
    self.costNumText:setString(self._data.cost[3]*self._findTimes)
end
function FindTimes:getSafeTimes(num)
    if num<1 then
        num=1
    end
    if num>self._data.leftTimes then
       num=self._data.leftTimes
    end
    return num
end

function FindTimes:ChangeFindTimes(sender)
    if sender:getName()=="Btn_Minus" then
        self._findTimes=self:getSafeTimes(self._findTimes-1)
    elseif sender:getName()=="Btn_Minus10" then
        self._findTimes=self:getSafeTimes(self._findTimes-10)
    elseif sender:getName()=="Btn_Plus" then
        self._findTimes=self:getSafeTimes(self._findTimes+1)
    elseif sender:getName()=="Btn_Plus10" then
        self._findTimes=self:getSafeTimes(self._findTimes+10)
    end   
    self:UpdateCostPrice()

end

function FindTimes:InitListView()
    for i=1,self._data.awardNum do
        local rewardData = self._data.awardInfo[i]
        local cell = self.m_pItem:clone()
        Utils:ShowItemByConfigData(rewardData, cell, nil, true, true)
        -- Utils:GetItemCellValue(cell, 0, rewardData.awardId, true, true, rewardData.awardNum,nil,true, true, false)
        cell:getChildByName("Name"):setString(Utils:getItemNameByID(rewardData.awardId))
        self.m_pItemListView:addChild(cell)   
    end

end
--[[
找回资源按钮
]]
function FindTimes:RecoverResources(sender)
    local myValue = LRoleDataMgr:GetMoney(self._data.cost[1])
    if self._data.cost[3]*self._findTimes > myValue then
        Utils:ShowScrollTips(string.format(GUITips.RSI_GS_TIP_RECOVERY_LIMIT,AppDef.AwrdItemName[self._data.cost[1]]))
        return
    end
    LuaNetSendMsg:QueryResRecovery(2, self._data.funcId, self._findTimes)
    self:CloseUI()
end





function FindTimes:ShowOneItem(sender)
    local id = sender.userObject
    local cfg = JsonConfig.m_ShopInfo.getDefByID(id)
    if cfg == nil then
        return
    end
    local info = PetkaPaiManager.m_AllShopData[cfg.type]
    if info == nil then
        return
    end
    local moneyGrid = sender:getChildByName("Icon1")
    local itemGrid = sender:getChildByName("Icon2")
    local valuePanel = sender:getChildByName("Discount")
    local valueLabel = valuePanel:getChildByName("Value")
    local btn = sender:getChildByName("Btn_Confirm")
    
    moneyGrid:removeAllChildren()
    itemGrid:removeAllChildren()

    local buyCnt = 0
    for i=1,#info.itemList do
        if info.itemList[i].id == id then
            buyCnt = info.itemList[i].buyTimes
            break
        end
    end
    btn.userObject = {id,buyCnt}
    buyCnt = buyCnt + 1
    local idx = math.min(buyCnt,#cfg.price_real)
    local radio = cfg.price_real[idx]
    local money = math.floor(cfg.price[1][3]*radio/100)
    if idx == #cfg.price_real then
        valuePanel:setVisible(false)
    else
        valueLabel:setString(string.format(GUITips.RSI_DISCOUNTSHOP_DISCOUNT,radio/10))
    end
    print("FindTimes:ShowOneItem",cfg.price[1][1],money)
    Utils:GetItemCellValue(moneyGrid, 0, cfg.price[1][1], true, true, money, nil, false, true)
    Utils:GetItemCellValue(itemGrid, 0, cfg.itemid[1], true, true, cfg.itemid[3], nil, false, true)
end

function FindTimes:BtnCallBack(sender)
    local value = sender.userObject
    local id = value[1]
    local buyCnt = value[2]
    local cfg = JsonConfig.m_ShopInfo.getDefByID(id)
    local nextVip = 0
    local addCnt = 0
    -- local vipLv = LRoleDataMgr.MyHeroInfo.MyVIPInfo.vipLevel+1
    -- for i= vipLv,JsonConfig.m_maxVipLv do
    --     local cfg = JsonConfig.m_vipConfig.getDefByID(i)
    --     if cfg ~= nil then
    --         local cnt = cfg[self.m_vipFieldName] or 0
    --         if cnt > self.m_vipAddCnt then
    --             nextVip = i
    --             addCnt = cnt - self.m_vipAddCnt
    --             break
    --         end
    --     end
    -- end
    local maxCnt = 0xffff
    if #cfg.count == 2 then
        maxCnt = cfg.count[2]
    end
    local residueCnt = self:GetResidueCnt(buyCnt,maxCnt)
    print("FindTimes:BtnCallBack",self.m_buyCnt,nextVip)
    Utils:OpenBuyUI(id,residueCnt,nextVip,addCnt,buyCnt)
    self:CloseUI()
end
function FindTimes:CloseUI()
    LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Welfare.FindTimes")
    self:SendMsg(LGameMsg.m_deleteUIMsg)
end
function FindTimes:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_itemId = nil
    self.m_shopIds = nil
    self.m_cells = nil
end
return FindTimes