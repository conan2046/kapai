--[[
lua里面的游戏逻辑控制
]]

local LoginUI = LUIBase:New()
LoginUI.__index = LoginUI
--local this = LTcpSocket
--[[
openType = 0--请求登录界面
openType = 1--显示服务器界面
openType = 2--显示用户名密码输入界面
]]
function LoginUI:New(openType)
	local o = LUIBase:New()
	setmetatable(o,LoginUI)	
    o:Init(openType)
	return o
end


function LoginUI:Init(openType)
    --self.m_pNode = cc.Node:create()
    
    self.m_pUILayer = cc.CSLoader:createNode("csd/Login/loginLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)


    self:InitData()
    self:AddTouchEvt()
    self:UpdateUserData(openType)

    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Login.ServerListUI")
    self:SendMsg(LGameMsg.m_initUIMsg)

   -- self:addChild(self.m_pUILayer)
end

function LoginUI:UpdateUserData(openType)

    if openType == nil or openType == 0 then
        self:ReqServerList()
    elseif openType == 1 then
        self:InitLoginServerInfo()
        self:ShowServerInfo(self.m_serverInfo)
        if AppDef.LOCAL_TEST == true and AppDef.LOCAL_TEST_AUTO_ENTER == true then
            performWithDelay(self.m_pUILayer, function()
                self:EnterGame()
            end, 0.5)
        end
    elseif openType == 2 then
        self:ShowLoginInput()
    elseif openType == 3 then
        self:ShowSdkLogin()
    end
end

function LoginUI:ShowSdkLogin()
    self.m_pAccountPanel:setVisible(false)
    self.m_pPsdPanel:setVisible(false)
    self.m_pRegBtn:setVisible(false)
    self.m_pLoginBtn:setVisible(false)
    --self.m_pForgetPsgBtn:setVisible(false)
    self.m_pEnterBtn:setVisible(false)
    self.m_pChangeBtn:setVisible(false)
    self.m_pServerBtn:setVisible(false)
    self.m_pSdkQQLoginBtn:stopAllActions()
    self.m_pSdkQQLoginBtn:setVisible(true)
    self.m_pSdkWXLoginBtn:stopAllActions()
    self.m_pSdkWXLoginBtn:setVisible(true)
    self.m_pSdkQQLoginBtn:setTouchEnabled(true)
    self.m_pSdkWXLoginBtn:setTouchEnabled(true)
    self.m_pImgBg:setVisible(false)
end

function LoginUI:ShowLoginInput()
    self.m_pAccountPanel:setVisible(true)

    self.m_pAccountPanel:getChildByName("TextField"):setCursorEnabled(true)
    self.m_pPsdPanel:getChildByName("TextField_Copy"):setCursorEnabled(true)
    self.m_pPsdPanel:setVisible(true)
    self.m_pRegBtn:setVisible(true)
    self.m_pLoginBtn:setVisible(true)
    --self.m_pForgetPsgBtn:setVisible(true)
    self.m_pEnterBtn:setVisible(false)
    self.m_pChangeBtn:setVisible(false)
    self.m_pServerBtn:setVisible(false)
    self.m_pSdkQQLoginBtn:stopAllActions()
    self.m_pSdkQQLoginBtn:setVisible(false)
    self.m_pSdkWXLoginBtn:stopAllActions()
    self.m_pSdkWXLoginBtn:setVisible(false)
    self.m_pImgBg:setVisible(true)


    local ac = LUserConfigMgr:GetUserAccount()
    local pwd = LUserConfigMgr:GetUserPassword()
    -- LRoleDataMgr.Account.userAccount.Account = ac
    -- LRoleDataMgr.Account.userAccount.Password = pwd
    if ac ~= nil and string.len(ac) > 0 and pwd ~= nil and string.len(pwd) then
        self.m_pAccountPanel:getChildByName("TextField"):setString(ac)
        self.m_pPsdPanel:getChildByName("TextField_Copy"):setString(pwd)
    end
end


function LoginUI:onExit()
    self:Destory()
    self.m_serverInfo = nil
    self.m_pAccountPanel = nil
    self.m_pPsdPanel = nil
    self.m_pRegBtn = nil
    self.m_pLoginBtn = nil
    self.m_pEnterBtn = nil
    --self.m_pForgetPsgBtn = nil
    self.m_pServerBtn = nil
    self.m_pUILayer = nil
    self.m_pChangeBtn = nil
    self.m_pSdkLoginBtn = nil
    self.m_pSdkQQLoginBtn = nil
    self.m_pSdkWXLoginBtn = nil
    self.m_pImgBg = nil
end

function LoginUI:InitData()
    self.m_serverInfo = nil
    local panel = self.m_pUILayer:getChildByName("Login")
    self._loginPanel = panel
    self.m_pImgBg = panel:getChildByName("bg")
    self.m_pAccountPanel = panel:getChildByName("InputField_user")
    self.m_pPsdPanel = panel:getChildByName("InputField_ps")
    self.m_pServerBtn = panel:getChildByName("Btn_Sever")
    self.m_pRegBtn = panel:getChildByName("Btn_Register")
    self.m_pLoginBtn = panel:getChildByName("Btn_Login")
    self.m_pSdkLoginBtn = panel:getChildByName("Btn_Login_sdk")
    self.m_pSdkQQLoginBtn = panel:getChildByName("Btn_Login_qq")
    self.m_pSdkWXLoginBtn = panel:getChildByName("Btn_Login_wx")
    self.m_pEnterBtn = panel:getChildByName("Btn_Play")
    self.m_pChangeBtn = panel:getChildByName("Btn_handover")
    --self.m_pForgetPsgBtn = panel:getChildByName("Text")
end

function LoginUI:AddTouchEvt()
    local function PlayCallback(sender)
        self:EnterGame()
    end
    self.m_pEnterBtn:addClickEventListener(PlayCallback)   
	self:MarkIntaractCObj(self.m_pEnterBtn)
    local function ChangeCallback(sender)
        if GameSdk:IsSDKUser() then
            if GameSdk:IsYYB() then
                --GameSdk:U8SDKSwitchAccount()
                self:ShowSdkLogin()
            else
                LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Login.LoginUI")
                self:SendMsg(LGameMsg.m_initUIMsg)
                GameSdk:U8SDKSwitchAccount()
            end
        else
            self:ShowLoginInput()
        end
        
        -- LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Login.LoginUI",AppDef.UIType.Normal,2)
        -- self:SendMsg(LGameMsg.m_initUIMsg)
    end
    self.m_pChangeBtn:addClickEventListener(ChangeCallback)   
	self:MarkIntaractCObj(self.m_pChangeBtn)
    local function RegCallback(sender)
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Login.LoginUI")
        self:SendMsg(LGameMsg.m_initUIMsg)

        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Login.RegisterUI",AppDef.UIType.Normal)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    self.m_pRegBtn:addClickEventListener(RegCallback)    
	self:MarkIntaractCObj(self.m_pRegBtn)
    local function LoginCallback(sender)
        self:HandleLogin()
    end
    self.m_pLoginBtn:addClickEventListener(LoginCallback)    
	self:MarkIntaractCObj(self.m_pLoginBtn)

    -- local function SDKLoginCallback(sender)
    --     self:HandleSdkLogin()
    -- end
    -- self.m_pSdkLoginBtn:addClickEventListener(SDKLoginCallback)    
    -- self:MarkIntaractCObj(self.m_pSdkLoginBtn)

    local function SDKQQLoginCallback(sender)
        self:HandleSdkQQLogin()
    end
    self.m_pSdkQQLoginBtn:addClickEventListener(SDKQQLoginCallback)    
    self:MarkIntaractCObj(self.m_pSdkQQLoginBtn)

    local function SDKWXLoginCallback(sender)
        self:HandleSdkWXLogin()
    end
    self.m_pSdkWXLoginBtn:addClickEventListener(SDKWXLoginCallback)    
    self:MarkIntaractCObj(self.m_pSdkWXLoginBtn)
    local function SelectServerCallback(sender)
        self:HandleSelectServer()
    end
    self.m_pServerBtn:addClickEventListener(SelectServerCallback)    
	self:MarkIntaractCObj(self.m_pServerBtn)
    -- local function CloseCallback(sender, eventType)
    --     if eventType ~= ccui.TouchEventType.ended then
    --         return
    --     end

    --     LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Login.RegisterUI")
    --     self:SendMsg(LGameMsg.m_initUIMsg)
    -- end
end

--[[
进入游戏
]]
function LoginUI:EnterGame()
    local server
    server = self.m_serverInfo
    if server == nil then
        return
    end
    --判断服务器是否有维护
    if server.serState ~= 0 then
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,server.errMsg)
        self:SendMsg(LGameMsg.m_scrollTipsMsg)
        return
    end
    local waitAniData = {
                            key = nil,
                            waitMsg = GUITips.Login_Connect_Server, 
                            autoClearTime = 0
                        }
    LGameMsg.m_baseMsgWithOne:Change(LUIWaitAni.ShowWait, waitAniData)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local function ConnectGameSocket()
        LGameMsg.m_baseMsgWithOne:Change(LGameNetEvent.TCPSelectedGameServer, server)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end

    performWithDelay(self.m_pUILayer,ConnectGameSocket,0.2)
    


    -- GetLoginMainLayer()->StartGameLogin(server)
    -- LUserConfigMgr:SetIsFirstLogin("false")
end


function LoginUI:UCLoginSuc( ... )
    -- body
    local args = {}
    local sigs = "()V"
    local luaj = require "cocos.cocos2d.luaj"
    local className = "org/cocos2dx/lua/AppActivity"

    local function LoginSucCallBackFrom(param)
        print("param =============================", param)
    end

    args = { "LoginSucCallBackFrom", LoginSucCallBackFrom }
    sigs = "(Ljava/lang/String;I)V"
    ok = luaj.callStaticMethod(className,"LoginSucCallBackFrom",args,sigs)
    if not ok then
        print("call callback error")
    end
end

function LoginUI:HandleSelectServer()
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Login.LoginUI")
    self:SendMsg(LGameMsg.m_initUIMsg)

    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Login.ServerListUI",AppDef.UIType.Normal)
    self:SendMsg(LGameMsg.m_initUIMsg)

    
end

function LoginUI:CheckAccount(account)

    if string.len(account) < 0 then
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.Login_Register_Account_LenLimit)
        self:SendMsg(LGameMsg.m_scrollTipsMsg)
        return false
    end

    local i = string.find(account,"%W")

    if i ~= nil then
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.Login_Register_Account_LenError)
        self:SendMsg(LGameMsg.m_scrollTipsMsg)
        return false
    end

    return true
end

function LoginUI:CheckPsd(psd)
    if string.len(psd) < 0 then
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.Login_Register_Psd_LenLimit)
        self:SendMsg(LGameMsg.m_scrollTipsMsg)
        return false
    end

    local i = string.find(psd,"%W")

    if i ~= nil then
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.Login_Register_Psd_LenError)
        self:SendMsg(LGameMsg.m_scrollTipsMsg)
        return false
    end

    return true
end

-- function LoginUI:HandleSdkLogin()

--     GameSdk:U8SDKLogin()
--     self.m_pSdkLoginBtn:setTouchEnabled(false)
--     local function DelayToEnable()
--         self.m_pSdkLoginBtn:setTouchEnabled(true)
--     end
--     performWithDelay(self.m_pSdkLoginBtn,DelayToEnable,1)
-- end

function LoginUI:HandleSdkQQLogin()
    GameSdk:U8SDKLogin("QQ")
    self.m_pSdkQQLoginBtn:setTouchEnabled(false)
    self.m_pSdkWXLoginBtn:setTouchEnabled(false)
    local function DelayToEnable()
        self.m_pSdkQQLoginBtn:setTouchEnabled(true)
        self.m_pSdkWXLoginBtn:setTouchEnabled(true)
    end
    performWithDelay(self.m_pSdkQQLoginBtn,DelayToEnable,5)
end


function LoginUI:HandleSdkWXLogin()

    GameSdk:U8SDKLogin("WX")
    self.m_pSdkQQLoginBtn:setTouchEnabled(false)
    self.m_pSdkWXLoginBtn:setTouchEnabled(false)
    local function DelayToEnable()
        self.m_pSdkQQLoginBtn:setTouchEnabled(true)
    self.m_pSdkWXLoginBtn:setTouchEnabled(true)
    end
    performWithDelay(self.m_pSdkWXLoginBtn,DelayToEnable,5)
end

function LoginUI:HandleLogin()
    local account = self.m_pAccountPanel:getChildByName("TextField"):getString()
    local psd = self.m_pPsdPanel:getChildByName("TextField_Copy"):getString()

    local isOK = self:CheckAccount(account)
    if isOK == false then
        return
    end

    isOK = self:CheckPsd(psd)
    if isOK == false then
        return
    end

    
    --保存登陆的信息
    LRoleDataMgr.Account.userAccount.Account = account
    LRoleDataMgr.Account.userAccount.Password = psd
    local ad = GameSdk.ChannelId
    --ad = ad==AD_ARD_OFFICIAL and AD_ARD_OFFICIAL or (ad*10+1)
    


    self.m_pLoginBtn:setTouchEnabled(false)
    local function DelayToEnable()
        self.m_pLoginBtn:setTouchEnabled(true)
    end
    performWithDelay(self.m_pLoginBtn,DelayToEnable,0.5)
    self:StartACLogin(account, psd, GameSdk.GameVersion,ad)
    LUserConfigMgr:SetUserAccountAndPsd(account, psd)
end

function LoginUI:ReqServerList()
    self.m_pAccountPanel:setVisible(false)
    self.m_pPsdPanel:setVisible(false)
    self.m_pRegBtn:setVisible(false)
    self.m_pLoginBtn:setVisible(false)
    --self.m_pForgetPsgBtn:setVisible(false)
    self.m_pEnterBtn:setVisible(false)
    self.m_pChangeBtn:setVisible(false)
    self.m_pServerBtn:setVisible(false)
    -- self.m_pSdkLoginBtn:stopAllActions()
    -- self.m_pSdkLoginBtn:setVisible(false)
    self.m_pSdkQQLoginBtn:stopAllActions()
    self.m_pSdkQQLoginBtn:setVisible(false)
    self.m_pSdkWXLoginBtn:stopAllActions()
    self.m_pSdkWXLoginBtn:setVisible(false)
    self.m_pImgBg:setVisible(true)
    local function onScheduleOnce()
        self:DelayStartLogin(0.5)
    end
    --停留500秒后自动进入服务器列表界面
    local action = cc.Sequence:create(cc.DelayTime:create(0.5),cc.CallFunc:create(onScheduleOnce))
    self.m_pUILayer:runAction(action)
end

function LoginUI:DelayStartLogin(t)
    
    local ac = LUserConfigMgr:GetUserAccount()
    local pwd = LUserConfigMgr:GetUserPassword()
    LRoleDataMgr.Account.userAccount.Account = ac
    LRoleDataMgr.Account.userAccount.Password = pwd
    
    local ad = GameSdk.ChannelId
    --ad = ad==AD_ARD_OFFICIAL and AD_ARD_OFFICIAL or (ad*10+1)
    self:StartACLogin(ac, pwd, GameSdk.GameVersion,ad)
end


function LoginUI:StartACLogin(name, password, version, adCode)
    --print("--------------------StartACLogin")
    -- CCLog("name:%s password:%s version: %s adCode: %d",name.c_str(),password.c_str(),version.c_str(),adCode);
    -- ConnectACLoginIfNeeded();
    --登陆之前清除角色信息
    LRoleDataMgr.Account.serverHeroInfo = {}
    local imie = ""
    -- if(CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    -- {
    --     imie = CallJava_PhoneIMIE();
    -- }
    --CCLOG("====================================IMIE=========%s",imie.c_str());
    local waitAniData = {
                            key = LuaNetCmd.MSG_ACC_LOGIN, 
                            waitMsg = GUITips.Login_Connect_Server, 
                            autoClearTime = 0
                        }
    LGameMsg.m_baseMsgWithOne:Change(LUIWaitAni.ShowWait, waitAniData)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)


    -- LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Common.WaitAniUI",AppDef.GameZOrder.UIWaitLoading,waitAniData)
    -- self:SendMsg(LGameMsg.m_initUIMsg)


    LuaNetSendMsg:QueryACLogin(name,password,version,adCode,imie)
    -- _LoginMsgBuf = MsgDealMgr::QueryACLogin(name,password,version,adCode,imie);
    -- WaitAniMgr::GetInstance()->SetWaitAniByKey(MSG_CLIENT_ACC_LOGIN, GUITips.Login_Connect_Server, WaitAniMgr::WAIT_DEFAUIT, 5*60.0f);
     
    -- //启动检测重连Timer
    -- _ReLoginTimes = 0;
    -- _ReLoginIp = SERVER_HOST;
    -- _ReLoginPort = SERVER_PORT;
    -- this->schedule(schedule_selector(LoginMainLayer::OnReLoginUpdate), 60.0f);
end

function LoginUI:ShowServerInfo(serverInfo)
    self.m_serverInfo = serverInfo
    self.m_pAccountPanel:setVisible(false)
    self.m_pPsdPanel:setVisible(false)
    self.m_pRegBtn:setVisible(false)
    self.m_pLoginBtn:setVisible(false)
    --self.m_pForgetPsgBtn:setVisible(false)
    self.m_pServerBtn:setVisible(true)
    self.m_pEnterBtn:setVisible(true)
    self.m_pChangeBtn:setVisible(true)
    -- self.m_pSdkLoginBtn:stopAllActions()
    -- self.m_pSdkLoginBtn:setVisible(false)
    self.m_pSdkQQLoginBtn:stopAllActions()
    self.m_pSdkQQLoginBtn:setVisible(false)
    self.m_pSdkWXLoginBtn:stopAllActions()
    self.m_pSdkWXLoginBtn:setVisible(false)
    self.m_pImgBg:setVisible(false)

    if GameSdk:IsSDKUser() and GameSdk:IsYYB() == false then
        self.m_pChangeBtn:setVisible(false)
        local size  = self._loginPanel:getContentSize()
        self.m_pEnterBtn:setPositionX(size.width / 2)
    end
    
    local serverText = self.m_pServerBtn:getChildByName("SeverName")

     if serverInfo == nil then
        local function okEvent()
            -- body
        end
        Utils:ShowDialogOKCancel(GUITips.RSI_SERVERLIST_ERROR, okEvent)
        return
     end

    serverText:setString(serverInfo.serName)

    local pState = self.m_pServerBtn:getChildByName("type")
    if serverInfo.onlineState ==0 then--流畅
        pState:loadTexture("res/UI/ui_severlist/ui_biaoshi_liuchang.png", UI_TEX_TYPE_PLIST)
    elseif serverInfo.onlineState ==2 then--拥挤
        pState:loadTexture("res/UI/ui_severlist/ui_biaoshi_baoman.png", UI_TEX_TYPE_PLIST)
    end
end

function LoginUI:InitLoginServerInfo()
    local serverList = LRoleDataMgr.Account.serverList
    local lastServerId = LUserConfigMgr:GetLastSelServerId()
    local vecRecommendServer = {}--推荐服列表
    local vecNewServer = {}--新服列表
    for k = 1, #serverList do
        if serverList[k].serType == 2 then--新服
            table.insert(vecNewServer,serverList[k])
        elseif serverList[k].serType == 1 then--新服或推荐服
            table.insert(vecRecommendServer,serverList[k])
        end
    end
    if lastServerId == 0 then
        if #vecNewServer > 0 then
            self.m_serverInfo = vecNewServer[1]
            return
        end
        if #vecRecommendServer > 0 then
            self.m_serverInfo = self:GetRecommendServer(vecRecommendServer)
            return
        else
            self.m_serverInfo = self:GetRecommendServer(serverList)
            return
        end 
    end

    for i = 1, #serverList do
        if serverList[i].serId == lastServerId then
            self.m_serverInfo = serverList[i]
            return
        end
    end

    if #vecNewServer > 0 then
        self.m_serverInfo = vecNewServer[1]
        return
    end

    if #vecRecommendServer > 0 then
        self.m_serverInfo = vecRecommendServer[1]
        return
    end
    self.m_serverInfo = self:GetRecommendServer(serverList)
end

function LoginUI:GetRecommendServer(vecRecommendServer)
    local maxId = 0
    local serverInfo
    local ad = GameSdk.ChannelId
    for i = 1, #vecRecommendServer do
        if vecRecommendServer[i].id > maxId then
            serverInfo = vecRecommendServer[i]
            maxId = vecRecommendServer[i].id
        end
    end
    return serverInfo
end

return LoginUI
