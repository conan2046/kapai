
local SendLabaMsgUI = LUIBase:New()
SendLabaMsgUI.__index = SendLabaMsgUI
--local this = LTcpSocket
function SendLabaMsgUI:New()
	local o = LUIBase:New()
	setmetatable(o,SendLabaMsgUI)	
    o:Init()
	return o
end

local LABAID = 2815

--注册事件
-- -----------------------------------
function SendLabaMsgUI:RegistMsgs()
    self.msgIds = 
    {
        LUIChatEvent.updateSendLabaMsg,
        LUILogicEvent.buyItemSucEvent,

    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function SendLabaMsgUI:ProcessEvent(msg)
    if msg.msgId == LUIChatEvent.updateSendLabaMsg then
        self:loadData()
        self:updateUI()
    end

    if msg.msgId == LUILogicEvent.buyItemSucEvent then
        if LFastShopDataMgr.m_curUseMattrial == AppDef.upgradeMaterial_ID.FM_Chat_Laba then
            self:loadData()
            self:updateUI()
            local isSelect = self._checkBox:isSelected()
            if isSelect then
                self:sendLabaMsg()
            end
        end
    elseif msg.msgId == LUIMapEvent.ChangeMapSuccess then
        self:closeDialog()
    end
    
end

function SendLabaMsgUI:Init()

    self.m_pUILayer = cc.CSLoader:createNode("csd/kuafuliaotian.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:loadData()
    self:initControlUI()
    self:updateUI()
end

function SendLabaMsgUI:initControlUI( ... )
    -- body
    local panel = self.m_pUILayer:getChildByName("Panel")
    local mask = panel:getChildByName("Mask")
    mask:setVisible(true)

    local bgPanel = panel:getChildByName("Bg")
    self._textField = bgPanel:getChildByName("bg"):getChildByName("TextField")
    self._textField:setCursorEnabled(true)
    local titleBg = bgPanel:getChildByName("TitleBg")

    local Btn_close = titleBg:getChildByName("Btn_close")
    local function closeEvent( sender )
        -- body
        self:closeDialog()
    end
    Btn_close:addClickEventListener(closeEvent)

    self._labaValue = bgPanel:getChildByName("GoldBg"):getChildByName("Value")
    self._checkBox = bgPanel:getChildByName("CheckBox")
    self._sendMsg = bgPanel:getChildByName("btn_fasong")
    local function sendEvent( sender )
        -- body
        local strContent = self._textField:getString()
        if string.len(strContent) < 1 then
            Utils:ShowScrollTips(GUITips.RSI_CROSSSERVER_TIPS_5)
            return
        end

        local isSelect = self._checkBox:isSelected()
        if not isSelect then
            if self._laBaNum > 0 then
                self:sendLabaMsg()
            else
--                Utils:ShowScrollTips(GUITips.RSI_CROSSSERVER_TIPS_4)
                local materialArr = {}
                local material = {}
                material.id = LABAID
                material.num = 1
                table.insert(materialArr, material)
                LFastShopDataMgr:ShowNeedBuyMaterial(materialArr, AppDef.upgradeMaterial_ID.FM_Chat_Laba)
            end
        else
            local myTongo = LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao()
            local labaItem = LItemMgr:getItem(LABAID)
--            dump(labaItem, "initControlUI 2222222222222222")
            if self._laBaNum > 0 then
                self:sendLabaMsg()
            else
                if labaItem.m_price > myTongo then
                    Utils:OpenNotEnoughGold()
                else
                    --元宝发送喇叭
                    LFastShopDataMgr.m_curUseMattrial = AppDef.upgradeMaterial_ID.FM_Chat_Laba
                    LuaNetSendMsg:QueryMarketInfo(2, 1, LABAID, 1)
                end
            end

        end
    end
    self._sendMsg:addClickEventListener(sendEvent)

    if LRoleDataMgr.MyHeroInfo.level < 15 then
        self._sendMsg:setTouchEnabled(false)
        self._sendMsg:setBright(false)
        self._textField:setPlaceHolder(string.format(GUITips.RSI_CHAT_LIMITE_TIPS4, info.totalRecharge))
    end

end

function SendLabaMsgUI:loadData( ... )
    -- body
    self._laBaNum = LRoleDataMgr.Equip:CountItemNumById(LABAID)
end

function SendLabaMsgUI:updateUI( ... )
    -- body
    self._labaValue:setString(self._laBaNum)
end

function SendLabaMsgUI:resetString(  )
    -- body
    self._textField:setString("")
end

function SendLabaMsgUI:sendLabaMsg( ... )
    -- body
    local strContent = self._textField:getString()
--    print("strContent 2222", strContent)
    if string.len(strContent) < 1 then
        Utils:ShowScrollTips(GUITips.RSI_CROSSSERVER_TIPS_5)
        return
    end
    LuaNetSendMsg:QueryAcrossSerChatMsg(LABAID, strContent)
    self:resetString()
end

function SendLabaMsgUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

function SendLabaMsgUI:closeDialog( ... )
    -- body
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Chat.SendLabaMsgUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
end

return SendLabaMsgUI