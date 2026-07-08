--[[
lua里面的游戏逻辑控制
]]

local RegisterUI = LUIBase:New()
RegisterUI.__index = RegisterUI
--local this = LTcpSocket
function RegisterUI:New()
	local o = LUIBase:New()
	setmetatable(o,RegisterUI)	
    o:Init()
	return o
end

--[[
注册UI消息
]]
function RegisterUI:RegistMsgs()
    self.msgIds = 
    {
        LUILoginEvent.RegisterCheckAccountResult,
        -- LUILoginEvent.RecvServerList,
        -- LUILoginEvent.RecvRoleServerList,
        -- LUILoginEvent.LoginSuccess,
    }
    self:RegistSelf(self,self.msgIds)
end

function RegisterUI:ProcessEvent(msg)
    if msg.msgId == LUILoginEvent.RegisterCheckAccountResult then
        self:CheckName(msg.value1, msg.value2)
    -- elseif msg.msgId == LUILoginEvent.RecvServerList then
    --     self.m_pQuList = msg.m_pQuList
    --     self.m_pTuijianList = msg.m_pTuijianList
    --     self.m_pServerList = msg.m_pServerList
    --     self:ShowServerList()
    -- elseif msg.msgId == LUILoginEvent.RecvRoleServerList then
    --     self.m_pRoleServerList = msg.m_pQuList
    --     --self:ShowServerList()
    --     --self:ShowLateLoginServer()
    -- elseif msg.msgId == LUILoginEvent.LoginSuccess then
    --     self:LoginSucess()
    end
end

function RegisterUI:CheckName(name, succ)
    local panel = self.m_pUILayer:getChildByName("Panel_1")
    panel = panel:getChildByName("bg")
    local inputUser = panel:getChildByName("InputField_user"):getChildByName("TextField"):getString()
    if inputUser ~= name then
        return
    end
    if succ == 1 then
        self.m_bAccountSuc = true
    else
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.Login_Register_Account_AlreadyExist)
        self:SendMsg(LGameMsg.m_scrollTipsMsg)
        self.m_bAccountSuc = false
    end
end


function RegisterUI:Init()
    self:RegistMsgs()
    --self.m_pNode = cc.Node:create()
    self.m_bAccountSuc = false
    self.PasswordSuc = false
    
    self.m_pUILayer = cc.CSLoader:createNode("csd/Login/RegisterLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)


    local panel = self.m_pUILayer:getChildByName("Panel_1")
    panel = panel:getChildByName("bg")

    local closeBtn = panel:getChildByName("Btn_close")
    local function CloseCallback(sender, eventType)
        if eventType ~= ccui.TouchEventType.ended then
            return
        end

        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Login.RegisterUI")
        self:SendMsg(LGameMsg.m_initUIMsg)

        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Login.LoginUI",AppDef.UIType.Normal,2)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    closeBtn:addTouchEventListener(CloseCallback)    
	self:MarkIntaractCObj(closeBtn)
    local regBtn = panel:getChildByName("Btn_Register")
     local function RegCallback(sender, eventType)
        if eventType ~= ccui.TouchEventType.ended then
            return
        end

        self:HandleRegister()
    end
    regBtn:addTouchEventListener(RegCallback)    
	self:MarkIntaractCObj(regBtn)

    -- local panel = self.m_pUILayer:getChildByName("Panel_1")
    -- panel = panel:getChildByName("bg")
    local inputUser = panel:getChildByName("InputField_user"):getChildByName("TextField")
    inputUser:setCursorEnabled(true)
    local function InputCallback(pSender, inputType)
        
        if inputType == ccui.TextFiledEventType.detach_with_ime then
            --print("inputType",inputType)
            self:checkAccount(pSender:getString())
        end
    end
    inputUser:addEventListener(InputCallback)


    local inputPsd = panel:getChildByName("InputField_ps"):getChildByName("TextField_Copy")
    inputPsd:setCursorEnabled(true)
    local function InputPsdCallback(pSender, inputType)
        
        if inputType == ccui.TextFiledEventType.detach_with_ime then
            --print("inputType",inputType)
            self:checkPassword(pSender:getString())
        end
    end
    inputPsd:addEventListener(InputPsdCallback)
end

function RegisterUI:checkPassword(psd)--检查密码
    local len = string.len(psd)
    if len == 0 then
        self.PasswordSuc = false
        return
    end
    if len < 6 then
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.Login_Register_Psd_LenLimit)
        self:SendMsg(LGameMsg.m_scrollTipsMsg)
        self.PasswordSuc = false
        return
    end

    local i = string.find(psd,"%W")

    if i ~= nil then
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.Login_Register_Psd_LenError)
        self:SendMsg(LGameMsg.m_scrollTipsMsg)
        self.PasswordSuc = false
        return
    end
    self.PasswordSuc = true
end

function RegisterUI:checkAccount(account)--检查账号
    local len = string.len(account)
    if len == 0 then
        self.m_bAccountSuc = false
        return
    end
    if len < 6 then
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.Login_Register_Account_LenLimit)
        self:SendMsg(LGameMsg.m_scrollTipsMsg)
        self.m_bAccountSuc = false
        return
    end

    local i = string.find(account,"%W")

    if i ~= nil then
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.Login_Register_Account_LenError)
        self:SendMsg(LGameMsg.m_scrollTipsMsg)
        self.m_bAccountSuc = false
        return
    end
    LuaNetSendMsg:QueryACCheckNickName(account)
end

function RegisterUI:HandleRegister()
    local panel = self.m_pUILayer:getChildByName("Panel_1")
    panel = panel:getChildByName("bg")
    local inputUser = panel:getChildByName("InputField_user"):getChildByName("TextField"):getString()
    local inputPsd = panel:getChildByName("InputField_ps"):getChildByName("TextField_Copy"):getString()

    if string.len(inputUser) == 0 then
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.Login_Register_Account_Input)
        self:SendMsg(LGameMsg.m_scrollTipsMsg)
        return
    elseif string.len(inputPsd) == 0 then
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.Login_Register_Psd_Input)
        self:SendMsg(LGameMsg.m_scrollTipsMsg)
        return
    end
    self:SetInfoInit()
    local userName = LUserConfigMgr:GetUserAccount()
    if string.len(userName) > 0 then
        isNewUser = 0
    else
        isNewUser = 1
    end
    local adCode = GameSdk.ChannelId
    local mobileInfo = GamePlatform:GetDeviceName()
    local panelRatio = ""
    local mac = GamePlatform:GetDeviceMacAddress()
    local imie = GamePlatform:GetDeviceIMEI()
    local phoneRegType = 0

    LRoleDataMgr.Account.userAccount.Account = inputUser
    LRoleDataMgr.Account.userAccount.Password = inputPsd


    local panel = self.m_pUILayer:getChildByName("Panel_1")
    panel = panel:getChildByName("bg")
    local regBtn = panel:getChildByName("Btn_Register")
    regBtn:setTouchEnabled(false)
    local function DelayToEnable()
        local regBtn = panel:getChildByName("Btn_Register")
        regBtn:setTouchEnabled(true)
    end
    performWithDelay(regBtn,DelayToEnable,0.5)


    LuaNetSendMsg:QueryACReg(inputUser, inputPsd, GameSdk.GameVersion , adCode, mobileInfo, panelRatio, mac, isNewUser, 0,imie,phoneRegType,"","")

    --LuaNetSendMsg:QueryACCheckNickName("")
    -- int adCode = ark_Download::GetClientADCode();
    -- if (adCode != AD_ARD_YAOSHENZHUAN && adCode != AD_ARD_2345 && adCode != AD_ARD_ZHONGHENET && adCode != AD_ARD_ANDROID && adCode != AD_ARD_ANDROID335 && adCode != AD_ARD_ANDROID325 && adCode != AD_ARD_ANDROID326 && adCode != AD_ARD_ANDROID321 && adCode != AD_ARD_320 && adCode != AD_ARD_OFFICE_327 && adCode != AD_IOS_SSJ)
    -- {
    --     adCode = adCode==AD_ARD_OFFICIAL?AD_ARD_OFFICIAL:adCode*10+1;
    -- }

    -- GetLoginMainLayer()->ConnectACLoginIfNeeded();
    -- string imie = "";
    -- if(CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    -- {
    --     imie = CallJava_PhoneIMIE();
    -- }
    -- CCLOG("====================================IMIE=========%s",imie.c_str());
    -- int regType = 0;
    -- string realName = _RealNameText;
    -- string cardID = _IDCardNumText;
    -- MsgDealMgr::QueryACReg(AccountBox->getText(),PasswordBox->getText(),ark_Download::GetClientVerion(),
    --     adCode,CallJava_GetAndroidVersion(),CallJava_GetAndroidPanelRatio(),CallJava_GetAndroidMacAddress(),isNewUser,0,imie,regType,realName,cardID);
    -- WaitAniMgr::GetInstance()->SetWaitAniByKey(MSG_CLIENT_ACC_REG);
end

function RegisterUI:SetInfoInit()
    LUserConfigMgr:SetLastSelServerName("")
    LUserConfigMgr:SetIsMusicClosed(false)
    LUserConfigMgr:SetIsEffectClosed(false)
end

function RegisterUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
end

return RegisterUI