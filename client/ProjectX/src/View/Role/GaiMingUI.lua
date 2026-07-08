
local GaiMingUI = LUIBase:New()
GaiMingUI.__index = GaiMingUI
--local this = LTcpSocket
local PLAYERNAME = 1
local BPNAME = 2

function GaiMingUI:New(type)
	local o = LUIBase:New()
	setmetatable(o,GaiMingUI)	
    o:Init(type)
	return o
end

--注册事件
-- -----------------------------------
function GaiMingUI:RegistMsgs()
    self.msgIds = 
    {
        LUILogicEvent.changeNameSuc,
        LUILogicEvent.changeBpNameSuc,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function GaiMingUI:ProcessEvent(msg)
    if msg.msgId == LUILogicEvent.changeNameSuc then
        -- self._textField:setString("")
        self:closeDialog()
    elseif msg.msgId == LUILogicEvent.changeBpNameSuc then
        -- self._textField:setString("")
        self:closeDialog()
    end
end

function GaiMingUI:Init(type)

    self.m_pUILayer = cc.CSLoader:createNode("csd/shenjiangyangcheng/gaiming.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    self._type = type or 1
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:initControlUI()
end

function GaiMingUI:initControlUI( ... )
    -- body
    local panel = self.m_pUILayer:getChildByName("Popup")
    local btn_Confirm = panel:getChildByName("Btn_Confirm")
    local function changeNameEvent( sender )
        -- body
        local str = self._textField:getString()
        print("initControlUI str =>", str)
        if string.len(str) < 1 then
            return
        end
        --改名卡
        --屏蔽字
        local islimiteMsg = Utils:IsLimitedMsg(str)
        if islimiteMsg then
            self._textField:setString("")
            Utils:ShowScrollTips(GUITips.REI_TIPS_LIMITE_WORLD)
            return
        end
        local sign = LRoleDataMgr:CheckIsEnough(self._value)
        if not sign then
            Utils:ShowScrollTips(string.format(GUITips.RSI_SHOP_TIPS3,AppDef.SpecialItemName[self._value[1]]))
            return
        end
        if self._type == BPNAME then
            LuaNetSendMsg:QueryAcrossSerChatMsg(2, str)
        else
            LuaNetSendMsg:QueryAcrossSerChatMsg(1, str)
        end
    end

    btn_Confirm:addClickEventListener(changeNameEvent)
    -------------------------------------------------------------
    local Btn_close = panel:getChildByName("Btn_close")
    local function closeEvent( sender )
        -- body
        self:closeDialog()
    end
    Btn_close:addClickEventListener(closeEvent)

    self._title = panel:getChildByName("Title"):getChildByName("Title")
    if self._type == BPNAME then
        self._title:setString(GUITips.RSI_BP_CHANGENAME_TIPS)
    end
    -------------------------------------------------------------
    self._textField = panel:getChildByName("TextField")
    self._textField:setCursorEnabled(true)
    -------------------------------------------------------------
    local moneyPanel = panel:getChildByName("Icon_yuanbao")
    local moneyImg = moneyPanel:getChildByName("Icon")
    moneyImg:setVisible(false)
    local moneyLabel = moneyImg:getChildByName("Num")
    moneyLabel:setString("")
    self._value = {}--改名价格
    local id = 20
    if self._type == BPNAME then
        id = 22
    end
    local cfg = JsonConfig.m_config.getDefByID(id)
    if cfg ~= nil then
        self._value = json.decode(cfg.value)
    end
    if #self._value == 3 then
        moneyImg:setVisible(true)
        local str = "res/UI/Icon/ui_huobi_icon/huobi_"..LRoleDataMgr.GetItemPicId(self._value[1])..".png"
        Utils:SafeLoadTexture(moneyImg,str,ccui.TextureResType.plistType)
        moneyLabel:setString(self._value[3])
    end
end

function GaiMingUI:closeDialog( ... )
    -- body
    Utils:DeleteUI("Role.GaiMingUI")
end

function GaiMingUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
    self._textField = nil
end

return GaiMingUI