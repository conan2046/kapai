-- ------------------------------
-- 白金会员
--  ----------------------------------------------
-- 白金会员

local PlatinumUI = LUIBase:New()
PlatinumUI.__index = PlatinumUI

-- ----------------------------------------------
-- 常量区
local ScriptPath = "Welfare.PlatinumUI"
local CsbFilePath = "csd/huodong/PlatinumLayer.csb"
local modTag = 2010

-- ----------------------------------------------
local _DEBUG = false
local function Debug(msg)
    if not _DEBUG then return end
    
end


-- ----------------------------------------------
local function _ShowTipsWindow(ui, msg)
    LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, msg)
    ui:SendMsg(LGameMsg.m_scrollTipsMsg)
end

-- ----------------------------------------------
local function _BindClickFunctionToButton(btn,fuc)
    btn:addClickEventListener(fuc)
	PlatinumUI:MarkIntaractCObj(btn)
end

-- ----------------------------------------------
function PlatinumUI:New(parent)
    local o = LUIBase:New()
    setmetatable(o, PlatinumUI)
    o:Init(parent)
    return o
end

-- ----------------------------------------------
function PlatinumUI:RegistMsgs()
    self.msgIds = 
    {
        LUIPlatinumEvent.updateBuyPlatinum,
        LUIPlatinumEvent.updateAwardUI,
    }
    self:RegistSelf(self, self.msgIds)
end

-- ----------------------------------------------
function PlatinumUI:ProcessEvent(msg)
    if msg.msgId == LUIPlatinumEvent.updateBuyPlatinum then
        self:updateBuyUI()
        LGameMsg.m_baseMsgWithOne:Change(LUIOnlineAwardEvent.KaifuReddotRefresh,4)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end

    if msg.msgId == LUIPlatinumEvent.updateAwardUI then
        LGameMsg.m_baseMsgWithOne:Change(LUIOnlineAwardEvent.KaifuReddotRefresh, 4)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
        self:updateAwardUI()
    end

end

-- ----------------------------------------------
function PlatinumUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.rpanel = nil
    self.lpanel = nil
    if  self.m_schedulerID then
        AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_schedulerID)
        self.m_schedulerID=nil
    end
end

-- ----------------------------------------------
function PlatinumUI:RegisterQuik()
    local function onNodeEvent(event)        
        if "exit" == event then
            Debug("onNodeEvent")
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

end

-- ----------------------------------------------
function PlatinumUI:InitViewSize(parent)
    self:CreateUINode(CsbFilePath)
    parent:addChild(self.m_pUILayer)
end

-- ----------------------------------------------
local ITMENUM = 3
local tagid = 1886
function PlatinumUI:InitUIControl()
    self:AddTouchEvent()
end


function PlatinumUI:AddTouchEvent()
    local RootPanel = self.m_pUILayer:getChildByName("PlatinumUI")
    self._btnBuy = RootPanel:getChildByName("btn_Buy")
    local function buyPlatinum( sender )
        -- body     
        
--         local function okFunc()
--             LuaNetSendMsg:QueryVipInfo(2)           --购买白金会员
-- --            GameSdk:toPayUC(30)
--         end
--         local function cancelFunc()
--         end
--         local cardInfo = LDataConstMgr:GetMyCardInfo()
        
--         local msg = string.format(GUITips.RSI_VL_TIP_MIN, cardInfo.CardPrice)
-- --        local msg = string.format(GUITips.RSI_VL_TIP_MIN_MONEY, cardInfo.CardPrice)
--         Utils:ShowDialogOKCancel(msg, okFunc, cancelFunc)

        Utils:OpenRechargeMainUI()
        --用于快捷跳转
        LRechargeDataMgr.m_isBuyPlatinumUI = true
        LRechargeDataMgr.m_BuyPlatinumType = 1
    end
    self._btnBuy:addClickEventListener(buyPlatinum)
	self:MarkIntaractCObj(self._btnBuy)
    self._awardBtn = RootPanel:getChildByName("btn_lingqu")
    local function award()
        -- body
        local vipInfo = LRoleDataMgr.MyHeroInfo.MyVIPInfo
        if vipInfo.mcGiftMonState then
            LuaNetSendMsg:QueryMcCardAward(8, 1)
        end
         
    end
    self._awardBtn:addClickEventListener(award)
	self:MarkIntaractCObj(self._awardBtn)
    self._btnGift = RootPanel:getChildByName("btn_Gift")

    self._awardIcon = RootPanel:getChildByName("btn_yuanbao")
    local m_tempCard=RootPanel:getChildByName("Image")
    self.m_tempCardTime=m_tempCard:getChildByName("Bg"):getChildByName("Tiyan")--体验月卡时间
    self.m_lMIcon = RootPanel:getChildByName("Image_3")
    self._lMAwardIcon = RootPanel:getChildByName("btn_yuanbao_0")
    self._lMBtnBuy = RootPanel:getChildByName("btn_Buy_0")
    self._lMAward = RootPanel:getChildByName("btn_lingqu_0")
    self:createBtnAnim(RootPanel)
    self._deadLine = RootPanel:getChildByName("Deadline")
    local vipInfoTemp = LRoleDataMgr.MyHeroInfo.MyVIPInfo
    if vipInfoTemp.isHasMcCard then
        self._deadLine:setVisible(true)
        local leftDays = vipInfoTemp.mcLeftTime / (3600 * 24)
        local strLeft = string.format(GUITips.RSI_IMD_DTS_TIP11, leftDays)
        self._deadLine:setString(strLeft)
        
        if vipInfoTemp.mcGiftMonState then
            self._awardBtn:setVisible(true)
            self._btnBuy:setVisible(false)
            self.m_pCreateImod:setVisible(false)
        else
            self._awardBtn:setVisible(false)
            self._btnBuy:setVisible(true)
            self.m_pCreateImod:setVisible(false)
            self._btnBuy:setTouchEnabled(false)
            self._btnBuy:setBright(false)
        end
    else
        self._deadLine:setVisible(false)
        self._awardBtn:setVisible(false)
    end

    local function lMBuyEvent( sender )
        -- body
        Utils:OpenRechargeMainUI()
        LRechargeDataMgr.m_isBuyPlatinumUI = true
        LRechargeDataMgr.m_BuyPlatinumType = 2
    end
    self._lMBtnBuy:addClickEventListener(lMBuyEvent)

    local function lMAwardEvent( sender )
        -- body
        local vipInfo = LRoleDataMgr.MyHeroInfo.MyVIPInfo
        if vipInfo.mcLifeGiftMonState then
            LuaNetSendMsg:QueryMcCardAward(8, 2)
        end 
    end
    self._lMAward:addClickEventListener(lMAwardEvent)

end


-- ----------------------------------------------
function PlatinumUI:Init(parent)
    self:RegistMsgs()
    self:InitViewSize(parent)
    self:InitUIControl()
    self:RegisterQuik()
    self:updateAwardUI()
end

function PlatinumUI:updateBuyUI( ... )
    -- body
    self._btnBuy:setVisible(false)
    self.m_pCreateImod:setVisible(false)
    self._awardBtn:setVisible(true)
    self._awardBtn:setTouchEnabled(true)
    self._awardBtn:setBright(true)
    self._deadLine:setVisible(true)
    if self._btnGift then
        local imod = self._btnGift:getChildByTag(modTag)
        if imod then
            imod:removeFromParent()
        end
        
    end
end

function PlatinumUI:updateAwardUI( ... )
   
    self._btnGift:setVisible(false)
    self._awardIcon:setVisible(false)
    local vipInfo = LRoleDataMgr.MyHeroInfo.MyVIPInfo
    if vipInfo.isHasMcCard then
        if vipInfo.mcGiftMonState then
            self._awardIcon:setVisible(true)
            self._awardBtn:setTouchEnabled(true)
            self._awardBtn:setBright(true)
        else
            self._awardIcon:setVisible(true)
            self._btnBuy:setVisible(false)
            self.m_pCreateImod:setVisible(false)
            self._awardBtn:setVisible(true)
            self._awardBtn:setTouchEnabled(true)
            self._awardBtn:setBright(false)
        end
        self.m_tempCardTime:setVisible(false)
        self.m_tempCardTime:getParent():setVisible(false)
    elseif vipInfo.isHasMcCardTemp  then
        self.m_tempCardTime:setVisible(true)
        self:UpdateTempCardTime()
        function disPlayTime()
            self:UpdateTempCardTime()
        end
        self.m_schedulerID=AppDef.Director:getScheduler():scheduleScriptFunc(disPlayTime, 1.0, false)
        self._btnGift:setVisible(true)   
        self._btnBuy:setVisible(true)
        self.m_pCreateImod:setVisible(true)
        self._awardBtn:setVisible(false)    
        -- if self.m_imod == nil then
        --     local size = self._btnGift:getContentSize()
        --     self.m_imod = Utils:CreateImod("res2/fx/libao",cc.p(size.width/2,size.height/2),self._btnGift,1)
        --     self.m_imod:setTag(modTag)
        --     self.m_imod:PlayActionRepeat(0)
        -- end 
    else
        self._btnGift:setVisible(true)   
        self._btnBuy:setVisible(true)
        self.m_pCreateImod:setVisible(true)
        self._awardBtn:setVisible(false)	
	    -- if self.m_imod == nil then
     --        local size = self._btnGift:getContentSize()
     --        self.m_imod = Utils:CreateImod("res2/fx/libao",cc.p(size.width/2,size.height/2),self._btnGift,1)
     --        self.m_imod:setTag(modTag)
     --        self.m_imod:PlayActionRepeat(0)
     --    end	
        self.m_tempCardTime:setVisible(false)
        self.m_tempCardTime:getParent():setVisible(false)
    end

    local numLabel = self._awardIcon:getChildByName("Value")
    local cardInfo = LDataConstMgr:GetMyCardInfo()
    local num = cardInfo:getAwardValue(1)
    numLabel:setString(num)

    local lMNumLabel = self._lMAwardIcon:getChildByName("Value")
    local lmNum = cardInfo:getAwardValue(2)
    lMNumLabel:setString(lmNum)
    
    print("拥有终生月卡 ==========>", vipInfo.isHasLmCard)
    self:lmCardState(vipInfo)

end
function  PlatinumUI:UpdateTempCardTime()
    local vipInfo = LRoleDataMgr.MyHeroInfo.MyVIPInfo
    if  self.m_tempCardTime==nil then
        if  self.m_schedulerID then
            AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_schedulerID)
            self.m_schedulerID=nil
        end
        return
    end
    local Value = self.m_tempCardTime:getChildByName("Time")
    if Value==nil then
        if  self.m_schedulerID then
            AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_schedulerID)
            self.m_schedulerID=nil
        end
        return
    end
    local Time = vipInfo.mcLeftTime
    local Hour=math.floor(Time/3600)
    local Minute =math.floor(Time/60)
    local Seconds = Time%60
    local StrHour=nil
    local StrMin=nil
    local StrSecond=nil
    if Hour<10 then
       StrHour="0"..Hour
    else
       StrHour=Hour
    end

    if Minute<10 then
       StrMin="0"..Minute
    else
       StrMin=Minute
    end
    if Seconds<10 then
       StrSecond="0"..Seconds
    else
       StrSecond=Seconds
    end
   
    Value:setString(GUITips.RSI_MONTHCARDEN2..StrHour..":"..StrMin..":"..StrSecond)
end

function PlatinumUI:createBtnAnim( RootPanel )
    -- body
        --按钮动画
    self.m_pCreateImod = ImodAnim:create()
    self.m_pCreateImod:setPosition(self._btnBuy:getPosition())
    RootPanel:addChild(self.m_pCreateImod, 5, 666);

    -- local pngStr = "res2/fx/yueka.png"
    -- local aniStr = "res2/fx/yueka.ani"
    self.m_pCreateImod:initAnimWithNameSync("res2/fx/yueka")
    self.m_pCreateImod:PlayActionRepeat(0)
    self.m_pCreateImod:setScaleX(0.8)
    self.m_pCreateImod:setScaleY(0.8)

    self.m_pLmCreateImod = ImodAnim:create()
    self.m_pLmCreateImod:setPosition(self._lMBtnBuy:getPosition())
    RootPanel:addChild(self.m_pLmCreateImod, 5, 777);
    self.m_pLmCreateImod:initAnimWithNameSync("res2/fx/yueka")
    self.m_pLmCreateImod:PlayActionRepeat(0)
    self.m_pLmCreateImod:setScaleX(0.8)
    self.m_pLmCreateImod:setScaleY(0.8)
end

function PlatinumUI:lmCardState( vipInfo )
    -- body
    if vipInfo.isHasLmCard then
        self._lMBtnBuy:setVisible(false)
        self._lMAward:setVisible(true)
        self.m_pLmCreateImod:setVisible(false)
        if vipInfo.mcLifeGiftMonState then
            self._lMAward:setTouchEnabled(true)
            self._lMAward:setBright(true)
        else
            self._lMAward:setTouchEnabled(false)
            self._lMAward:setBright(false)
        end
    else
        self._lMBtnBuy:setVisible(true)
        self._lMAward:setVisible(false)
        
--        self._lMAwardIcon:setVisible(false)
        local icon = self._lMAwardIcon:getChildByName("Icon")
        icon:setVisible(false)

        local value = self._lMAwardIcon:getChildByName("Value")
        value:setVisible(false)

        local cardInfo = LDataConstMgr:GetMyCardInfo()
        local cardData = cardInfo:getMcAwardData(2)
        if cardData ~= nil then
--            print("cardData.awardType ====>", cardData.awardType, cardData.awardValue)
            local item = Utils:GetItemCellValue(self._lMAwardIcon, 0, cardData.awardType, false, true, cardData.awardValue, nil, true, true)
        end

        if self.m_imod == nil then
            local size = self._lMAwardIcon:getContentSize()
            self.m_imod = Utils:CreateImod("res2/fx/libao", cc.p(size.width/2,size.height/2), self._lMAwardIcon, 1)
            self.m_imod:setTag(modTag)
            self.m_imod:PlayActionRepeat(0)
        end

    end
end

function PlatinumUI:setVisible(visible)
    self.m_pUILayer:setVisible(visible)
end

return PlatinumUI