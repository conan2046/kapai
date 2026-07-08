
local HeChengPopup = LUIBase:New()
HeChengPopup.__index = HeChengPopup
local ScriptPath = "Common.HeChengPopup"
function HeChengPopup:New(userData)
    userData = userData or {}
	local o = LUIBase:New()
	setmetatable(o,HeChengPopup)	
    o:Init(userData)
	return o
end
--[[userData 
        okCallback = OKCallback,
        cancelCallback = cancelCallback,
        lackItemInfo = lackItemArr,
        useType = useType,
        tips = GUITips.RSI_UPGRADE_BUYITEM_TIPS,
        title = GUITips.RSI_UPGRADE_BUYITEM_TITLE,
]]
function HeChengPopup:Init(userData)
    self.m_pUserData=userData
    self.m_pUILayer = cc.CSLoader:createNode("csd/HechengPopupLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
    local function onNodeEvent(event)        
         if "exit" == event then
             self:onExit()
         end
     end
     self.m_pUILayer:registerScriptHandler(onNodeEvent)
     self:RegistMsgs()
     self:InitData()
     self:ShowItemList()
     self:AddClickEvent()
     self:NeedItemList()
end

--[[
注册UI消息
]]
function HeChengPopup:AddClickEvent()
    local  function CloseBtn()
        self:HandleClose()-- body
    end     
    self.CloseBtn:addClickEventListener(CloseBtn)
    local  function ConfirmBtn()
        self:HandleOK()-- body
    end    
    self.OkBtn:addClickEventListener(ConfirmBtn)
     local function CancelBtn()
        self:HandleCancel()-- body
    end    
    self.CancelBtn:addClickEventListener(CancelBtn)
end
function HeChengPopup:ShowItemList()
    if self.m_pUserData==nil then      
      return 
    end
   
     self.m_pBagItemListView:removeAllChildren()
     local btns = {}
     local thisTypePropId={} 
   
     thisTypePropId=Utils:GetSameTypeProp(self.m_pUserData.lackItemInfo.Id)
     
    local myThisPropNum =LRoleDataMgr.Equip:CountItemNumById(self.m_pUserData.lackItemInfo.Id)  
    if myThisPropNum~=0 then
        local awardui = self.m_BHCell:clone()         
        awardui:setVisible(true)   
        Utils:GetItemCellValue(awardui, 0, self.m_pUserData.lackItemInfo.Id, true, true, myThisPropNum, nil, true)
        self.m_pBagItemListView:addChild(awardui)
        awardui:setAnchorPoint(cc.p(0.5, 0.5))
        awardui:setPositionY(self.m_pBagItemListView:getContentSize().height / 2)
        awardui:setTag(0)
        table.insert(btns, awardui)
    end          
     for i=1,#thisTypePropId do       
            local myThisPropNum =LRoleDataMgr.Equip:CountItemNumById(thisTypePropId[i])  
            if myThisPropNum~=0 then
                local awardui = self.m_BHCell:clone()         
                awardui:setVisible(true)   
                Utils:GetItemCellValue(awardui, 0, thisTypePropId[i], true, true, myThisPropNum, nil, true)
                self.m_pBagItemListView:addChild(awardui)
                awardui:setAnchorPoint(cc.p(0.5, 0.5))
                awardui:setPositionY(self.m_pBagItemListView:getContentSize().height / 2)
                awardui:setTag(i)
                table.insert(btns, awardui)
            end          
     end
  

    Utils:AlignNodes(self.m_pBagItemListView, btns, {30}, 1, false)
end
function HeChengPopup:NeedItemList()
    if self.m_pUserData.lackItemInfo==nil then      
      return 
    end
    local buyData =self.m_pUserData.lackItemInfo.BuyList
    self.m_NBItemListView:removeAllChildren()
    local btns = {}
     for i=1,#buyData do
        if buyData[i] then
            local awardui = self.m_NBCell:clone()  
            awardui:setVisible(true)
            data=buyData[i]
            local name = awardui:getChildByName("Text")
            name:setString(data.name)
            local color = AppDef:GetItemQualityColor(data.quality)
            name:setTextColor(color)
            local numBg = awardui:getChildByName("NumBg")
            local value = numBg:getChildByName("Text")
            value:setString(tostring(data.num))
            --元宝
            local spendIcon1 = awardui:getChildByName("SpendIcon_1")
            local cost1 = spendIcon1:getChildByName("Text")
            --金币
            local spendIcon2 = awardui:getChildByName("SpendIcon_2")
            local cost2 = spendIcon2:getChildByName("Text")
            --绑定元宝
            local spendIcon3 = awardui:getChildByName("SpendIcon_3")
            local cost3 = spendIcon3:getChildByName("Text")
            if self.m_pUserData.useType == 2 then
                spendIcon1:setVisible(false)
                spendIcon2:setVisible(true)
                spendIcon3:setVisible(false)
                cost2:setString(tostring(data.num * data.price))
            elseif self.m_pUserData.useType == 3 then
                spendIcon1:setVisible(false)
                spendIcon2:setVisible(false)
                spendIcon3:setVisible(true)
                cost3:setString(tostring(data.num * data.price))
            else
                spendIcon1:setVisible(true)
                spendIcon2:setVisible(false)
                spendIcon3:setVisible(false)
                cost1:setString(tostring(data.num * data.price))
            end
                Utils:GetItemCellValue(awardui, 0, buyData[i].id, true, true, buyData[i].num, nil, true)          
                self.m_NBItemListView:addChild(awardui)
                awardui:setAnchorPoint(cc.p(0, 0))
                awardui:setPositionY(63)
                awardui:setTag(i)
                table.insert(btns, awardui)
           end
    end
    Utils:AlignNodes(self.m_NBItemListView, btns, {30}, 3, false)
end

function HeChengPopup:RegistMsgs()
 
end

function HeChengPopup:ProcessEvent(msg)
end

function HeChengPopup:onExit()
    self.m_pUILayer = nil
    self.m_pUserData = nil
    self.m_pListView = nil
    self.m_pBaseBtn = nil
    self:Destory()
end

function HeChengPopup:InitData()
    self.m_HeChengPopupLayer=self.m_pUILayer:getChildByName("HechengPopupLayer")
    self.m_NeedBuyBG=self.m_HeChengPopupLayer:getChildByName("IconBg2")
    self.m_BackpackHaveBG=self.m_HeChengPopupLayer:getChildByName("IconBg1")
    self.m_GoldNum=self.m_HeChengPopupLayer:getChildByName("GoldNum")
    self.m_BHCell=self.m_BackpackHaveBG:getChildByName("IconBtn")
    self.m_NBCell=self.m_NeedBuyBG:getChildByName("IconBtn_0")
    self.CloseBtn=self.m_HeChengPopupLayer:getChildByName("bg"):getChildByName("Btn_close")
    self.OkBtn=self.m_HeChengPopupLayer:getChildByName("Btn_Confirm2")
    self.CancelBtn=self.m_HeChengPopupLayer:getChildByName("Btn_Confirm1")
    self.m_pBagItemListView=self.m_BackpackHaveBG:getChildByName("ListView")
    self.m_NBItemListView=self.m_NeedBuyBG:getChildByName("ListView")
    self.m_Gold=self.m_HeChengPopupLayer:getChildByName("GoldNum")
    self.m_BYuanBao=self.m_Gold:getChildByName("Icon_1"):getChildByName("Text")
    self.m_YuanBao=self.m_Gold:getChildByName("Icon_2"):getChildByName("Text")
    self.m_YuanBao:setString(LRoleDataMgr.MyHeroInfo:GetDetailData().TongBao)
    self.m_BYuanBao:setString(LRoleDataMgr.MyHeroInfo:GetDetailData().BindTongBao)
   
end


function HeChengPopup:HandleClose()
	LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, ScriptPath)
    self:SendMsg(LGameMsg.m_initUIMsg)
end
function HeChengPopup:HandleOK()
    if self.m_pUserData.okCallback ~= nil then
        self.m_pUserData.okCallback()
    end
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, ScriptPath)
    self:SendMsg(LGameMsg.m_initUIMsg)
end
function HeChengPopup:HandleCancel()
    if self.m_pUserData.cancelCallback ~= nil then
        self.m_pUserData.cancelCallback()
    end
   LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, ScriptPath)
    self:SendMsg(LGameMsg.m_initUIMsg)
end

return HeChengPopup