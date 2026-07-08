GameSdk = {}
GameSdk.__index = GameSdk
GameSdk.JavaAppActivity = "org/cocos2dx/lua/AppActivity"
local md5 = require("core.MD5")

GameSdk.ServerId = nil
GameSdk.UserId = nil
GameSdk.Token = nil
GameSdk.IsLogined = false
--GameSdk.SDKUser = false
--[[
渠道号
]]
GameSdk.ChannelId = 1--
GameSdk.ChannelName = "none"--
GameSdk.ShowVersion = "10000"
GameSdk.GameVersion = "10000"
GameSdk.IMEI = ""
GameSdk.IsSDKInited = false
GameSdk.LoginScheduler = nil
GameSdk.androidTruePhone = true
GameSdk.AppId = AppDef.APPID_DOUSHENWUSHUANG
function GameSdk:InitSDKData()
	local app = cc.Application:getInstance()
	local target = app:getTargetPlatform()
	--print("UCInitSDK", GameSdk.ChannelId)
	if target == cc.PLATFORM_OS_ANDROID or target == cc.PLATFORM_OS_IPHONE or target == cc.PLATFORM_OS_IPAD then
        if self:IsSDKUser() then
            if not GameSdk.IsSDKInited then
                if self:IsQuickSDK() then
                    self:U8SDKLogin()    
                elseif self:IsYYB() then
                    if self:CheckYYBLastLogined() == false then
                        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Login.LoginUI",AppDef.UIType.Normal,3)
                        LGameManager:SendMsg(LGameMsg.m_initUIMsg)
                    end
                    
                else
                    self:U8SDKLogin()
                end
                
            else
                if self.UserId ~= nil then
                    LuaNetSendMsg:QueryACLogin(self.UserId, GameSdk.Token, GameSdk.GameVersion, GameSdk.ChannelId, GameSdk.IMEI)
                end
            end
        end
	elseif target == cc.PLATFORM_OS_IPHONE or target == cc.PLATFORM_OS_IPAD then
    	
	end
    --self:InitGameVersion()

end

function GameSdk:InitGameVersion()
    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()
    if target == cc.PLATFORM_OS_ANDROID then
        self:InitAndroidChannelInfo()
    elseif target == cc.PLATFORM_OS_WINDOWS then
        GameSdk.androidTruePhone = false
    else
        self:InitIOSChannelInfo()
        GameSdk.AppId = self:GetAPPID()
        self:InitIOSChannelId()
        GameSdk:InitIOSIAFD()
        print("IDFA InitGameVersion", GameSdk.IDFA)
    end


    local url = cc.FileUtils:getInstance():getWritablePath() .. "package/project.manifest"
    if not cc.FileUtils:getInstance():isFileExist(url) then
        url = "Manifest/ad"..GameSdk.ChannelId.."/project.manifest"
    end
    local str = cc.FileUtils:getInstance():getStringFromFile(url)
    local versionManifest = json.decode(str,1)

    GameSdk.ShowVersion = string.format(GUITips.Version, versionManifest["showVersion"])

    GameSdk.GameVersion = versionManifest["version"]

    --GameSdk.GameVersion = string.gsub(GameSdk.GameVersion,"%.","") .. "00"

    
    if target == cc.PLATFORM_OS_WINDOWS then
        GameSdk.ShowVersion = "102600"
        GameSdk.GameVersion = "102600"
    else
        local str = string.split(GameSdk.GameVersion,".")
        GameSdk.GameVersion = "" .. ((tonumber(str[1]) * 10000) + tonumber(str[2]) * 100 + tonumber(str[3]))
        print("GameSdk.GameVersion ios ", GameSdk.GameVersion)
    end
end

function GameSdk:InitChannelId()
    local luaj = require "cocos/cocos2d/luaj"
    local args = {}
    local sigs = "()I"
    local ok,ret  =luaj.callStaticMethod(GamePlatform.JavaAppActivity,"GetChannelId",args,sigs)
    release_print("InitChannelId ok,ret:",ok,ret)
    if ok then
        if ret then
            GameSdk.ChannelId = ret
        else
            print("InitChannelId nil ret:", ret)
            GameSdk.ChannelId = 1
        end
    else
        print("InitChannelId error")
        GameSdk.ChannelId = 1
    end
end

function GameSdk:InitAndroidChannelInfo()
    self:InitChannelId()
    GamePlatform:initGameAppID()
    -- release_print("InitAndroidChannelInfo = GameSdk.AppId", GameSdk.AppId, GameSdk.ChannelId)
    GameSdk.IMEI = GamePlatform:GetDeviceIMEI()
    GameSdk.androidTruePhone = (GamePlatform:GetAndroidDevicesType() ~= GamePlatform.AndroidDeviceType.ANDROIDSIMULATOR)
    if self:IsYiJieSDK() and self._yijie == nil then
        --获取lua易接接口，此接口不能作为全局变量使用
        require "sdkInterface.YijieInterface"
        self._yijie = YijieInterface.new()
        -- --注册SDK初始化回调
        self._yijie:setSDKInitListener(handler(self, GameSdk.sdkInitCallbackFunc))

        -- --注册登陆回调
        self._yijie:setLoginListener(handler(self, GameSdk.loginCallback))
        
        -- -- --监听手机返回键
        local key_listener = cc.EventListenerKeyboard:create()
        --返回键回调
        --lua中得回调，分清谁绑定，监听谁，事件类型是什么
        key_listener:registerScriptHandler(handler(self, GameSdk.key_return) ,cc.Handler.EVENT_KEYBOARD_RELEASED)

        local sceneGame = cc.Director:getInstance():getRunningScene()
        local eventDispatch = sceneGame:getEventDispatcher()
        eventDispatch:addEventListenerWithSceneGraphPriority(key_listener, sceneGame)
    end

end

function GameSdk:sdkInitCallbackFunc( param )
    -- body
    print("sdkInitCallbackFunc ========>")
    GameSdkYiJie:sdkInitCallbackFunc(param)
end

function GameSdk:loginCallback( param )
    -- body
    print("loginCallback ============>")
    GameSdkYiJie:loginCallback(param)
end

function GameSdk:key_return( keycode )
    -- body
    print("key_return exit =======>", keycode)
    --结束游戏
    print(keycode)
    local function exitCallback( jPrama )
        -- body
        GameSdkYiJie:exitCallback(jPrama)
    end
    if keycode == 6 then
        --return 
        self._yijie:exit(exitCallback)--退出游戏
    end
end

--[[
U8请求服务器登录
]]
function GameSdk:ReqLogin()
	--LuaNetSendMsg.ReqLogin(GameSdk.ChannelId,GameSdk.UserId,GameSdk.Token) 
end

--[[
sdk登录调用
@param1:callback,登录成功回调
]]
function GameSdk:SDKLogin(callback)
	-- local localcallback = callback
	-- function SDKLoginCallback(cid,uid,token)

	-- 	GameSdk.ChannelId = cid

	--     GameSdk.UserId = uid
	--     GameSdk.Token = token
	--     IsLogined = true
	--     print("SDKLoginCallback:uid=" .. uid .. "   token=" .. token)
	-- 	--localcallback()
	-- 	GameSdk:ReqLogin()
	-- end
	-- GameManager.GetInstance():LuaSDKLogin(SDKLoginCallback)
end

function GameSdk:SetUserType(params)
	
	-- if params[0] == true then
	-- 	GameSdk.SDKUser = true
	-- else
	-- 	GameSdk.SDKUser = false
	-- end
	
	-- local layer = UIManager:GetUI(GUIViewId.View_Login)
 --    layer:ConnectLoginSocketSucess()
end



-- function GameSdk:initUcSdk( ... )
-- 	-- body
-- 	print("start initUcSdk")
--     local args = {}
--     local sigs = "()V"
--     local luaj = require "cocos.cocos2d.luaj"
--     local className = "org/cocos2dx/lua/AppActivity"
--     local ok,ret  = luaj.callStaticMethod(className, "ucNetworkAndInitUCGameSDK", args, sigs)
--     if not ok then
--         print("luaj error:", ret)
--     else
--         print("The ret is:", ret)
--     end
-- end

-- function GameSdk:ucLoginSdk( ... )
--     print("start ucLoginSdk")
--     local args = {}
--     local sigs = "()V"
--     local luaj = require "cocos.cocos2d.luaj"
--     local className = "org/cocos2dx/lua/AppActivity"
--     local ok,ret  = luaj.callStaticMethod(className, "ucLoginGameSDK", args, sigs)
--     if not ok then
--         print("luaj error:", ret)
--     else
--         print("The ret is:", ret)
--     end
-- end

-- function GameSdk:UCLoginSuc( ... )
--     -- body
--     local args = {}
--     local sigs = "()V"
--     local luaj = require "cocos.cocos2d.luaj"
--     local className = "org/cocos2dx/lua/AppActivity"

--     local function LoginSucCallBackFrom(param)
--         print("param =============================", param)
--         self.UserId = param
--         GameSdk.IsSDKInited = true
--         LuaNetSendMsg:QueryACLogin("", self.UserId, GameSdk.GameVersion, GameSdk.ChannelId, GameSdk.IMEI)
--     end

--     args = { "LoginSucCallBackFrom", LoginSucCallBackFrom }
--     sigs = "(Ljava/lang/String;I)V"
--     ok = luaj.callStaticMethod(className,"LoginSucCallBackFrom",args,sigs)
--     if not ok then
--         print("call callback error")
--     end
-- end

-- function GameSdk:UCLoginServer( ... )
--     if self.UserId then
--         LuaNetSendMsg:QueryACLogin("", self.UserId, GameSdk.GameVersion, GameSdk.ChannelId, GameSdk.IMEI)
--     else
--         self:ucLoginSdk()
--     end
-- end


-- function GameSdk:UCPay(amount, accountId, callbackInfo, orderId, sign, signType)
--     -- body
--     local args = {amount, accountId, callbackInfo, orderId, sign, signType}
--     local sigs = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
--     local luaj = require "cocos.cocos2d.luaj"
--     local className = "org/cocos2dx/lua/AppActivity"
--     local ok,ret  = luaj.callStaticMethod(className, "payCash", args, sigs)
--     if not ok then
--         print("luaj error:", ret)
--     else
--         print("The ret is:", ret)
--     end
-- end

-- --[[
-- 支付成功回调
-- ]]
-- function GameSdk:UCPaySuc()
--     -- body
--     local args = {}
--     local sigs = "()V"
--     local luaj = require "cocos.cocos2d.luaj"
--     local className = "org/cocos2dx/lua/AppActivity"

--     local function UCPayCallBackFrom(param)
--         print("param =============================", param)
--         LGameMsg.m_netDealMsg:Change(LUILogicEvent.paymentSuccess)
--         LGameManager:SendMsg(LGameMsg.m_netDealMsg)
--     end

--     args = { "UCPayCallBackFrom", UCPayCallBackFrom }
--     sigs = "(Ljava/lang/String;I)V"
--     ok = luaj.callStaticMethod(className,"UCPayCallBackFrom",args,sigs)
--     if not ok then
--         print("call callback error")
--     end
-- end

function GameSdk:SDKShowChangeAccount()
    return GameSdk:IsYYB() --应用宝
end

--[[
是否是应用宝
]]
function GameSdk:IsYYB()
    return GameSdk.ChannelId == 1005 or GameSdk.ChannelId == 1505 --应用宝
end

function GameSdk:CheckYYBLastLogined()
    local str = LUserConfigMgr:GetYYBLoginFlag()
    if str == "QQ" then
        --上次使用QQ登录过
        self:U8SDKLogin(str)
        return true
    elseif str == "WX" then
        --上次使用微信登录过
        self:U8SDKLogin(str)
        return true
    end
    return false
end

--[[
是否是当乐
]]
function GameSdk:IsDownjoy()
    return GameSdk.ChannelId == 1008 or GameSdk.ChannelId == 1511 --
end

--[[
是否是爱奇艺pps
]]
function GameSdk:IsPPS()
    return GameSdk.ChannelId == 1018 --
end

--[[
是否是华为
]]
function GameSdk:IsHuaWei()
    return GameSdk.ChannelId == 1004 or GameSdk.ChannelId == 1504 --
end

--[[
是否是360
]]
function GameSdk:Is360()
    return GameSdk.ChannelId == 1009 or GameSdk.ChannelId == 1515 --
end

function GameSdk:IsUseNewSendInfoFunc()
    if self:IsDownjoy() or self:IsHuaWei() or self:IsPPS() or self:IsQuickSDK() or self:Is360() then
        return true
    else
        return false
    end
end

--[[
判断有没有渠道
]]
function GameSdk:IsSDKUser()
    -- release_print("IsSDKUser",GameSdk.ChannelId)
    return GameSdk.ChannelId > 1000 and GameSdk.ChannelId ~= 8888
    --return GameSdk.ChannelId == 3 or GameSdk.ChannelId == 4
end

function GameSdk:IsQuickSDK()
    return GameSdk.ChannelId > 3000 and GameSdk.ChannelId ~= 8888
end

function GameSdk:IsYiJieSDK( ... )
    -- body
    --暂时还不定
    return GameSdk.ChannelId > 4000 and GameSdk.ChannelId < 4200
end

function GameSdk:isDouShenQuick( ... )
    -- body
    return GameSdk.ChannelId == 3001 or GameSdk.ChannelId == 3101 or GameSdk.ChannelId == 3301
end

function GameSdk:IsGameInBackground( ... )
    -- body
    -- print("start ucLoginSdk")
    local args = {}
    local sigs = "()Z"
    local luaj = require "cocos.cocos2d.luaj"
    local className = "org/cocos2dx/lua/AppActivity"
    local ok,ret  = luaj.callStaticMethod(className, "isBackground", args, sigs)
    if not ok then
        print("luaj error:", ret)
    else
        print("The ret is:", ret)
    end
    return ret
end

function GameSdk:toPayUC(amount)
    -- body
    local xhr = cc.XMLHttpRequest:new()
    xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING
    
    -- local md5 = require("md5")
    -- local y = md5.sumhexa("admin")
    -- print(y)

    local strCon = string.format("%d&%s&%s&%d&%d", LRoleDataMgr.Account.uid, LRoleDataMgr.Account.sid, amount, LRoleDataMgr.MyHeroInfo.serverId,LRoleDataMgr.MyHeroInfo.id)
    local md5Str = md5.sumhexa(strCon)

    local strDes = string.format("id=%d&signature=%s&money=%s&serverId=%d&roleId=%d&sign=%s", LRoleDataMgr.Account.uid, LRoleDataMgr.Account.sid, amount, LRoleDataMgr.MyHeroInfo.serverId,LRoleDataMgr.MyHeroInfo.id, md5Str)
    local httpUrl = "http://111.231.62.116:18090/fxl_pay/get_order_info.php?" .. strDes
    xhr:open("GET",  httpUrl)
    -- print("strDes httpUrl -------", httpUrl)
    local function onReadyStateChanged()
        print("xhr.readyState", xhr.readyState)
        if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
            print(xhr.response)
            print("patTest rep", xhr.statusText)
            local resJson = json.decode(xhr.response, 1)
            local code = resJson.code
            if code == "success" then
                local accountId = resJson.data.accountId
                local callbackInfo = resJson.data.callbackInfo
                local orderId = resJson.data.orderId
                local signType = resJson.data.signType
                local money = resJson.data.money
                local sign = resJson.data.sign
                print("patTest getPayParam", accountId, callbackInfo, orderId, sign, signType)
                GameSdk:UCPay(money, accountId, callbackInfo, orderId, sign, signType)
            else
                Utils:ShowScrollTips(GUITips.RSI_PAY_HTTPERROR)
            end
        else
            print("xhr.readyState is:", xhr.readyState, "xhr.status is: ", xhr.status)
        end
        xhr:unregisterScriptHandler()
    end
    xhr:registerScriptHandler(onReadyStateChanged)
    xhr:send()
end

------------------U8--------------------------
--[[
上传用户信息
DataType:   1选择服务器
            2创建角色
            3进入游戏
            4等级提升
            5退出游戏
]]

function GameSdk:U8SendInfo(dataType, serverId, roleId, roleName)
    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()
    if target ~= cc.PLATFORM_OS_ANDROID or GameSdk:IsSDKUser() == false then
        return
    end
    if GameSdk:IsUseNewSendInfoFunc() == false then
        --兼容老的
        if dataType == 3 then
            local heroData = LRoleDataMgr.MyHeroInfo
            GameSdk:U8SendRoleInfo(0, 0,"0", heroData.DetailData:GetTongBao(), 
                heroData.id, LRoleDataMgr.MyHeroInfo.serverId,heroData.level,heroData.name,self:GetServerName(LRoleDataMgr.MyHeroInfo.serverId))
        end
        return
    end
    if dataType == 1 then
        if self:IsYiJieSDK() then
            GameSdk:yiJieSendRoleInfo("enterServer")
        else
            self:U8SendSelectServerInfo(serverId)
        end
    elseif dataType == 2 then
        if self:IsYiJieSDK() then
            GameSdk:yiJieSendRoleInfo("createrole")
        else
            self:U8SendCreateRoleInfo(roleId, roleName,serverId)
        end
    elseif dataType == 3 then
        if self:IsYiJieSDK() then
            GameSdk:yiJieSendRoleInfo("enterGame")
        else
            self:U8SendEnterGameInfo()
        end
    elseif dataType == 4 then
        if self:IsYiJieSDK() then
            GameSdk:yiJieSendRoleInfo("levelup")
        else
            self:U8SendLevelUpInfo()
        end
    elseif dataType == 5 then
        self:U8SendQuitInfo()
    end
end

function GameSdk:GetServerName(serverId)
    local serHInfo = LRoleDataMgr.Account:GetServerHeroInfo(serverId)
    local serverList = LRoleDataMgr.Account.serverList
    local serverInfo = nil

    if serverList ~= nil then
        for i = 1, #serverList do
            if serverList[i].id == serverId then
                serverInfo = serverList[i]
                break
            end
        end
    end
    local serName = "DefaultServer"
    if serverInfo ~= nil then
        serName = serverInfo.serName
    end
    return serName
end

function GameSdk:U8SendSelectServerInfo(serverId)
    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()
    if target ~= cc.PLATFORM_OS_ANDROID or GameSdk:IsSDKUser() == false then
        return
    end
    if GameSdk:IsUseNewSendInfoFunc() == false then
        return
    end
    local heroData = LRoleDataMgr.MyHeroInfo

    local serHInfo = LRoleDataMgr.Account:GetServerHeroInfo(serverId)
    local serverInfo = nil
    local pid = 0

    local roleId = 0
    local pName = "0"
    local pInfo = "0"
    local roleLevel = 0
    local roleName = "0"
    local serName = self:GetServerName(serverId)
    local money = 0
    if serHInfo ~= nil then
        roleId = serHInfo.id
        roleName = serHInfo.name
        roleLevel = serHInfo.level
    end
    GameSdk:U8NewSendRoleInfo(1, pid, pName,pInfo, money, roleId, serverId,roleLevel,roleName,serName)
        -- GameSdk:U8SendRoleInfo(0, 0,"", heroData.DetailData:GetTongBao(), 
        --         heroData.id, LRoleDataMgr.MyHeroInfo.serverId,heroData.level,heroData.name,"DefaultServer")
end

function GameSdk:U8SendCreateRoleInfo(roleId, roleName,serverId)
    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()
    if target ~= cc.PLATFORM_OS_ANDROID or GameSdk:IsSDKUser() == false then
        return
    end
    if GameSdk:IsUseNewSendInfoFunc() == false then
        return
    end
    local heroData = LRoleDataMgr.MyHeroInfo
    
    local pid = 0

    local pName = ""
    local pInfo = ""
    local serName = self:GetServerName(serverId)
    local money = heroData.DetailData:GetTongBao()
    local roleLevel = 1
    GameSdk:U8NewSendRoleInfo(2, pid, pName,pInfo, money, roleId, serverId,roleLevel,roleName,serName)
end

function GameSdk:U8SendEnterGameInfo()
    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()
    if target ~= cc.PLATFORM_OS_ANDROID or GameSdk:IsSDKUser() == false then
        return
    end
    if GameSdk:IsUseNewSendInfoFunc() == false then
        return
    end
    local heroData = LRoleDataMgr.MyHeroInfo
    local serverId = heroData.serverId
    local pid = 0

    local roleId = heroData.id
    local pName = ""
    local pInfo = ""
    local serName = self:GetServerName(serverId)
    local money = heroData.DetailData:GetTongBao()
    local roleName = heroData.name
    local roleLevel = heroData.level
    GameSdk:U8NewSendRoleInfo(3, pid, pName,pInfo, money, roleId, serverId,roleLevel,roleName,serName)
end

function GameSdk:yiJieSendRoleInfo(dataType)
    -- body
    local json = require "json"
    local tab = {}
    local heroData = LRoleDataMgr.MyHeroInfo
    local serverId = heroData.serverId
    tab["roleId"]= tostring(heroData.id)
    tab["roleName"]= heroData.name
    tab["roleLevel"]= tostring(heroData.level) 
    tab["zoneId"]= tostring(serverId)  
    tab["zoneName"]= self:GetServerName(serverId)
    tab["balance"]= "0"
    tab["vip"]= tostring(heroData.vipLevel)
    tab["partyName"]= ""
    tab["roleCTime"]= ""
    tab["roleLevelMTime"]= ""
    local jsonData = json.encode(tab)
    self._yijie:setDataString(dataType, jsonData);  -- 创建新角色时调用       必接
end

function GameSdk:yiJieSetHeroData( ... )
    -- body
    local heroData = LRoleDataMgr.MyHeroInfo
    self._yijie:setRoleData(tostring(heroData.id), heroData.name, tostring(heroData.level), tostring(heroData.serverId), self:GetServerName(heroData.serverId))
end

function GameSdk:U8SendLevelUpInfo()
    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()
    if target ~= cc.PLATFORM_OS_ANDROID or GameSdk:IsSDKUser() == false then
        return
    end
    if GameSdk:IsUseNewSendInfoFunc() == false then
        return
    end
    local heroData = LRoleDataMgr.MyHeroInfo
    local serverId = heroData.serverId
    local pid = 0

    local roleId = heroData.id
    local pName = ""
    local pInfo = ""
    local serName = self:GetServerName(serverId)
    local money = heroData.DetailData:GetTongBao()
    local roleName = heroData.name
    local roleLevel = heroData.level
    GameSdk:U8NewSendRoleInfo(4, pid, pName,pInfo, money, roleId, serverId,roleLevel,roleName,serName)
end

function GameSdk:U8SendQuitInfo()
    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()
    if target ~= cc.PLATFORM_OS_ANDROID or GameSdk:IsSDKUser() == false then
        return
    end
    if GameSdk:IsUseNewSendInfoFunc() == false then
        return
    end
    local heroData = LRoleDataMgr.MyHeroInfo
    local serverId = heroData.serverId
    
    local pid = 0

    local roleId = heroData.id
    local pName = ""
    local pInfo = ""
    local serName = self:GetServerName(serverId)
    local money = heroData.DetailData:GetTongBao()
    local roleName = heroData.name
    local roleLevel = heroData.level
    GameSdk:U8NewSendRoleInfo(5, pid, pName,pInfo, money, roleId, serverId,roleLevel,roleName,serName)
end

function GameSdk:U8SendRoleInfo(pid, pName,pInfo, money, roleId, serverId,roleLevel,roleName,serName)
    print("***CallJava_sendRoleInfo",pid, pName, money, roleId, serverId,roleLevel,roleName,serName)
    if pName == "" then
        pName = "0"
    end
    if pInfo == "" then
        pInfo = "0"
    end
    if roleName == "" then
        roleName = "0"
    end
    if serName == "" then
        serName = "0"
    end
    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()
    if target == cc.PLATFORM_OS_ANDROID then
        local luaj = require "cocos/cocos2d/luaj"
        local args = {tonumber(pid), pName,pInfo, tonumber(money), tonumber(roleId), tonumber(serverId), tonumber(roleLevel),roleName,serName }
        local sigs = "(ILjava/lang/String;Ljava/lang/String;IIIILjava/lang/String;Ljava/lang/String;)V"  --()Z
        local className = "org/cocos2dx/lua/AppActivity"
        local ok,ret = luaj.callStaticMethod(className,"sendRoleInfo",args,sigs)
        if ok then
            if ret then
               return ret
            else
                print("U8SendRoleInfo ret:", ret)
            end
        else
            print("U8SendRoleInfo error")
        end

    end
    return ""
end

function GameSdk:U8NewSendRoleInfo(dataType, pid, pName,pInfo, money, roleId, serverId,roleLevel,roleName,serName)
    print("***CallJava_sendRoleInfo",dataType,pid, pName, money, roleId, serverId,roleLevel,roleName,serName)
    if pName == "" then
        pName = "0"
    end
    if pInfo == "" then
        pInfo = "0"
    end
    if roleName == "" then
        roleName = "0"
    end
    if serName == "" then
        serName = "0"
    end
    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()
    if target == cc.PLATFORM_OS_ANDROID then
        local luaj = require "cocos/cocos2d/luaj"
        local args = {tonumber(dataType),tonumber(pid), pName,pInfo, tonumber(money), tonumber(roleId), tonumber(serverId), tonumber(roleLevel),roleName,serName }
        local sigs = "(IILjava/lang/String;Ljava/lang/String;IIIILjava/lang/String;Ljava/lang/String;)V"  --()Z
        local className = "org/cocos2dx/lua/AppActivity"
        local ok,ret = luaj.callStaticMethod(className,"sendNewRoleInfo",args,sigs)
        if ok then
            if ret then
               return ret
            else
                print("U8SendRoleInfo ret:", ret)
            end
        else
            print("U8SendRoleInfo error")
        end

    end
    return ""
end

function GameSdk:QuickSDKPayGetOrderIdSuccess(amount, orderId,extraData)
    self:SetU8PayCallback()
    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()
    local itemId = 0
    local itemName = "元宝"
    local itemInfo = "元宝"
    local yuanbao = amount * 200
    local serverName = self:GetServerName(LRoleDataMgr.MyHeroInfo.serverId)
    if target == cc.PLATFORM_OS_ANDROID then
        --myMoney,money,OrderId, roleId,serverId,roleLevel,roleName,serName

        local luaj = require "cocos/cocos2d/luaj"
        local args
        local sigs
        args = {
                    LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao(),
                    amount,
                    yuanbao,
                    orderId,
                    LRoleDataMgr.MyHeroInfo.id, 
                    LRoleDataMgr.MyHeroInfo.serverId,
                    LRoleDataMgr.MyHeroInfo.level,
                    LRoleDataMgr.MyHeroInfo.name,
                    serverName,
                    extraData
                }
        sigs = "(IIILjava/lang/String;IIILjava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"  --()Z
        local className = "org/cocos2dx/lua/AppActivity"
        local ok,ret = luaj.callStaticMethod(className,"doSDKPay",args,sigs)
        if ok then
            if ret then
               return ret
            else
                print("CallJava_QuickPay ret:", ret)
            end
        else
            print("CallJava_QuickPay error")
        end
    elseif target == cc.PLATFORM_OS_IPHONE or target == cc.PLATFORM_OS_IPAD then
        if GameSdk:IsQuickSDK() then
            GameSdk:QuickSDKDoPayment(amount, orderId, extraData)
        end
    end
    return ""
end

function GameSdk:QuickSDKPay(amount)

    local function GetOrderIdCallback(money,orderId,extraData)
        self:QuickSDKPayGetOrderIdSuccess(money,orderId,extraData)
    end
    -- body
    local xhr = cc.XMLHttpRequest:new()
    xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING
    
    -- local md5 = require("md5")
    -- local y = md5.sumhexa("admin")
    -- print(y)

    local strCon = string.format("%d&%s&%s&%d&%d", LRoleDataMgr.Account.uid, LRoleDataMgr.Account.sid, amount, LRoleDataMgr.MyHeroInfo.serverId,LRoleDataMgr.MyHeroInfo.id)
    local md5Str = md5.sumhexa(strCon)

    local strDes = string.format("id=%d&signature=%s&money=%s&serverId=%d&roleId=%d&sign=%s", LRoleDataMgr.Account.uid, LRoleDataMgr.Account.sid, amount, LRoleDataMgr.MyHeroInfo.serverId,LRoleDataMgr.MyHeroInfo.id, md5Str)
    --剑阵诛仙quick
    -- local httpUrl = "http://jzzxdl.sp-pay.cn:801/pay/quick_get_order_info.php?" .. strDes
    --斗神无双BT quick
    -- local httpUrl = "http://122.51.75.27:910/pay/quick_get_order_info.php?" .. strDes
    local httpUrl = "http://btrecharge.play.cn:910/pay/quick_get_order_info.php?" .. strDes
    xhr:open("GET",  httpUrl)
    print("strDes httpUrl -------", httpUrl)
    local function onReadyStateChanged()
        print("xhr.readyState", xhr.readyState)
        if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
            print(xhr.response)
            print("patTest rep", xhr.statusText)
            local resJson = json.decode(xhr.response, 1)
            local code = resJson.code
            if code == "success" then
                --local accountId = resJson.data.accountId
                local callbackInfo = resJson.data.callbackInfo
                local orderId = resJson.data.orderId
                --local signType = resJson.data.signType
                local money = resJson.data.money
                --local sign = resJson.data.sign
                --print("patTest getPayParam", accountId, callbackInfo, orderId, sign, signType)
                GetOrderIdCallback(money, orderId,callbackInfo)
            else
                Utils:ShowScrollTips(GUITips.RSI_PAY_HTTPERROR)
            end
        else
            print("xhr.readyState is:", xhr.readyState, "xhr.status is: ", xhr.status)
        end
        xhr:unregisterScriptHandler()
    end
    xhr:registerScriptHandler(onReadyStateChanged)
    xhr:send()
end

function GameSdk:execYiJiePay( amount, orderId, extraData)
    -- body
    local function payCallback( param )
        -- body
        dump(param, "execYiJiePay ===>")
        GameSdkYiJie:payCallback(param)
    end
    local finalPrice = amount * 100
    print("execYiJiePay", orderId, extraData, finalPrice)
    -- finalPrice = 1
    self._yijie:pay(finalPrice, "元宝", 1, extraData, GameSdkYiJie.cpPaySyncUrl, payCallback)
end

function GameSdk:YiJiePay( amount )
    -- body
    local function yiJieGetOrderIdCallback(money,orderId,extraData)
        self:execYiJiePay(money,orderId,extraData)
    end
    -- body
    print("YiJiePay ===>", amount)
    local xhr = cc.XMLHttpRequest:new()
    xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING
    
    local strCon = string.format("%d&%s&%s&%d&%d", LRoleDataMgr.Account.uid, LRoleDataMgr.Account.sid, amount, LRoleDataMgr.MyHeroInfo.serverId,LRoleDataMgr.MyHeroInfo.id)
    local md5Str = md5.sumhexa(strCon)

    local strDes = string.format("id=%d&signature=%s&money=%s&serverId=%d&roleId=%d&sign=%s", LRoleDataMgr.Account.uid, LRoleDataMgr.Account.sid, amount, LRoleDataMgr.MyHeroInfo.serverId,LRoleDataMgr.MyHeroInfo.id, md5Str)
    local httpUrl = "http://47.102.106.254:801/pay/get_order_info.php?" .. strDes
    xhr:open("GET",  httpUrl)
    print("strDes httpUrl -------", httpUrl)
    local function onReadyStateChanged()
        print("xhr.readyState", xhr.readyState)
        if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
            print(xhr.response)
            print("patTest rep", xhr.statusText)
            local resJson = json.decode(xhr.response, 1)
            local code = resJson.code
            if code == "success" then
                --local accountId = resJson.data.accountId
                local callbackInfo = resJson.data.callbackInfo
                local orderId = resJson.data.orderId
                --local signType = resJson.data.signType
                local money = resJson.data.money
                --local sign = resJson.data.sign
                --print("patTest getPayParam", accountId, callbackInfo, orderId, sign, signType)
                yiJieGetOrderIdCallback(money, orderId,callbackInfo)
            else
                Utils:ShowScrollTips(GUITips.RSI_PAY_HTTPERROR)
            end
        else
            print("xhr.readyState is:", xhr.readyState, "xhr.status is: ", xhr.status)
        end
        xhr:unregisterScriptHandler()
    end
    xhr:registerScriptHandler(onReadyStateChanged)
    xhr:send()
end

function GameSdk:U8Pay(amount)

    if self:IsYiJieSDK() then
        self:YiJiePay(amount)
        return
    end

    if self:IsQuickSDK() then
        self:QuickSDKPay(amount)
        return
    end
    self:SetU8PayCallback()

    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()
    local itemId = 888
    local itemName = "元宝"
    local itemInfo = "元宝"
    local serverName = self:GetServerName(LRoleDataMgr.MyHeroInfo.serverId)
    if target == cc.PLATFORM_OS_ANDROID then
        local luaj = require "cocos/cocos2d/luaj"
        local args
        local sigs
        args = {
                    itemId, 
                    itemName,
                    itemInfo, 
                    amount,
                    LRoleDataMgr.MyHeroInfo.id, 
                    LRoleDataMgr.MyHeroInfo.serverId,
                    LRoleDataMgr.MyHeroInfo.level,
                    LRoleDataMgr.MyHeroInfo.name,
                    serverName
                }
        sigs = "(ILjava/lang/String;Ljava/lang/String;IIIILjava/lang/String;Ljava/lang/String;)V"  --()Z
        local className = "org/cocos2dx/lua/AppActivity"
        local ok,ret = luaj.callStaticMethod(className,"doSDKPay",args,sigs)
        if ok then
            if ret then
               return ret
            else
                print("CallJava_U8Pay ret:", ret)
            end
        else
            print("CallJava_U8Pay error")
        end        
    end
    return ""
end

function GameSdk:SetU8PayCallback()
    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()
    if target == cc.PLATFORM_OS_ANDROID then
        local args = {}
        local sigs = "()V"
        local luaj = require "cocos.cocos2d.luaj"
        local className = "org/cocos2dx/lua/AppActivity"

        local function U8PayCallBackFrom(param)
            print("param =============================", param)

            local msg = LMsgBase:New()
            msg:ChangeEventId(LUILogicEvent.paymentSuccess)
            LGameManager:SendMsg(msg)
        end

        args = { "U8PayCallBackFrom", U8PayCallBackFrom }
        sigs = "(Ljava/lang/String;I)V"
        ok = luaj.callStaticMethod(className,"setPayCallBack",args,sigs)
        if not ok then
            print("call callback error")
        end
    end
end

function GameSdk:U8SDKSetLoginFailCallback()
    local args = {}
    local sigs = "()V"
    local luaj = require "cocos.cocos2d.luaj"
    local className = "org/cocos2dx/lua/AppActivity"

    local function U8LoginFailCallBackFrom(param)
        print("U8LogoutCallBackFrom")
        GameSdk.UserId = nil
        GameSdk.Token = nil
        if GameSdk.LoginScheduler then
            AppDef.Director:getScheduler():unscheduleScriptEntry(GameSdk.LoginScheduler)
            GameSdk.LoginScheduler = nil
        end
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Login.LoginUI",AppDef.UIType.Normal,3)
        LGameManager:SendMsg(LGameMsg.m_initUIMsg)
    end

    args = { "U8LoginFailCallBackFrom", U8LoginFailCallBackFrom }
    sigs = "(Ljava/lang/String;I)V"
    ok = luaj.callStaticMethod(className,"setLoginFailCallback",args,sigs)
    if not ok then
        print("call callback error")
    end
end

function GameSdk:U8SDKSetLogoutCallback()
    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()
    if target == cc.PLATFORM_OS_ANDROID then
        local args = {}
        local sigs = "()V"
        local luaj = require "cocos.cocos2d.luaj"
        local className = "org/cocos2dx/lua/AppActivity"

        local function U8LogoutCallBackFrom(param)
            GameSdk:GameLogoutCallBack()
        end

        args = { "U8LogoutCallBackFrom", U8LogoutCallBackFrom }
        sigs = "(Ljava/lang/String;I)V"
        ok = luaj.callStaticMethod(className,"setLogoutCallback",args,sigs)
        if not ok then
            print("call callback error")
        end
    end
end

function GameSdk:GameLogoutCallBack( ... )
    -- body
    print("U8LogoutCallBackFrom")
    GameSdk.UserId = nil
    GameSdk.Token = nil
    local msg = LMsgBase:New()
    msg:ChangeEventId(LGameEvent.LogoutFromSDK)
    LGameManager:SendMsg(msg)
end

--[[
sdk登录接口
loginStr：登录参数：只在应用宝有效。"QQ" "WX"
]]
function GameSdk:U8SDKLogin(loginStr)



    if GameSdk.LoginScheduler ~= nil then
        AppDef.Director:getScheduler():unscheduleScriptEntry(GameSdk.LoginScheduler)
        GameSdk.LoginScheduler = nil
    end
    local getResultCnt = 0
    local function checkLogResult()
        getResultCnt = getResultCnt + 1
        local uid = GameSdk:U8GetSid()
        local token = GameSdk:U8GetToken()

        print("sdk uid:"..uid.."token:"..token);
        -- if uid == "" and token == ""  then
        --     local IsFirstLogin = USER_CFG:GetIsFirstLogin():len() == 0;
        --     local IsExistUser = USER_CFG:GetUserAccount():len() > 0 and USER_CFG:GetUserPassword():len() > 0;
        --     if(IsFirstLogin == false and IsExistUser == true) then
        --         --TipsMgr:GetInstance():SetCenterTip(RES_STRC("RSI_LC_TIP40"));
        --     end
        -- end
        if string.len(uid) > 0 and  string.len(token) > 0 then
            GameSdk.UserId = uid
            GameSdk.Token = token
            AppDef.Director:getScheduler():unscheduleScriptEntry(GameSdk.LoginScheduler)
            GameSdk.LoginScheduler = nil

            LuaNetSendMsg:QueryACLogin(GameSdk.UserId, GameSdk.Token, GameSdk.GameVersion, GameSdk.ChannelId, GameSdk.IMEI)
        -- elseif getResultCnt >= 6 then
        --     AppDef.Director:getScheduler():unscheduleScriptEntry(GameSdk.LoginScheduler)
        --     GameSdk.LoginScheduler = nil
        --     self:U8SDKLogin()
        end
    end

    self:U8SDKSetLogoutCallback()
    if self:IsYYB() then
        self:U8SDKSetLoginFailCallback()
        if loginStr == "QQ" then
            LUserConfigMgr:SetYYBLoginFlag(loginStr)
            self:QuerySDKQQLogin()
        elseif loginStr == "WX" then
            LUserConfigMgr:SetYYBLoginFlag(loginStr)
            self:QuerySDKWXLogin()
        else
            self:QuerySDKLogin()
        end
    else
        local app = cc.Application:getInstance()
        local target = app:getTargetPlatform()
        if target == cc.PLATFORM_OS_ANDROID then
            if self:IsYiJieSDK() then
                self:yijieLogin()
            else
                self:QuerySDKLogin()
            end
        elseif (cc.PLATFORM_OS_IPHONE == target) or (cc.PLATFORM_OS_IPAD == target) then
            if GameSdk:IsQuickSDK() then
                self:QuickSDKLogin()
            end
        end
    end

    if not self:IsYiJieSDK() then
        GameSdk.LoginScheduler = AppDef.Director:getScheduler():scheduleScriptFunc(checkLogResult, 0.5, false)
    end
    
end

function GameSdk:yijieLogin()
    if self._yijie ~= nil then
        self._yijie:login("login")--登陆
        print("YijieInterface login ============================ 222222222222")
    end
end

function GameSdk:QuerySDKQQLogin()
    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()
    if target == cc.PLATFORM_OS_ANDROID then

        local luaj = require "cocos/cocos2d/luaj"
        local args = {}
        local sigs = "()V"  --
        local className = "org/cocos2dx/lua/AppActivity"
        local ok,ret  =luaj.callStaticMethod(className,"doSDKQQLogin",args,sigs)
        if ok then
            if ret then
                return ret
            else
                print("CallJava_goSDKLogin nil ret:", ret)
            end
        else
            print("CallJava_goSDKLogin error")
        end
    end
    return 0
end

function GameSdk:QuerySDKWXLogin()
    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()
    if target == cc.PLATFORM_OS_ANDROID then

        local luaj = require "cocos/cocos2d/luaj"
        local args = {}
        local sigs = "()V"  --
        local className = "org/cocos2dx/lua/AppActivity"
        local ok,ret  =luaj.callStaticMethod(className,"doSDKWXLogin",args,sigs)
        if ok then
            if ret then
                return ret
            else
                print("CallJava_goSDKLogin nil ret:", ret)
            end
        else
            print("CallJava_goSDKLogin error")
        end
    end
    return 0
end

function GameSdk:U8SDKSwitchAccount()
    if GameSdk.LoginScheduler ~= nil then
        AppDef.Director:getScheduler():unscheduleScriptEntry(GameSdk.LoginScheduler)
        GameSdk.LoginScheduler = nil
    end
    local getResultCnt = 0
    local function checkLogResult()
        getResultCnt = getResultCnt + 1
        local uid = GameSdk:U8GetSid()
        local token = GameSdk:U8GetToken()

        print("sdk uid:"..uid.."token:"..token);
        -- if uid == "" and token == ""  then
        --     local IsFirstLogin = USER_CFG:GetIsFirstLogin():len() == 0;
        --     local IsExistUser = USER_CFG:GetUserAccount():len() > 0 and USER_CFG:GetUserPassword():len() > 0;
        --     if(IsFirstLogin == false and IsExistUser == true) then
        --         --TipsMgr:GetInstance():SetCenterTip(RES_STRC("RSI_LC_TIP40"));
        --     end
        -- end
        if string.len(uid) > 0 and  string.len(token) > 0 then
            GameSdk.UserId = uid
            GameSdk.Token = token
            AppDef.Director:getScheduler():unscheduleScriptEntry(GameSdk.LoginScheduler)
            GameSdk.LoginScheduler = nil

            LuaNetSendMsg:QueryACLogin(GameSdk.UserId, GameSdk.Token, GameSdk.GameVersion, GameSdk.ChannelId, GameSdk.IMEI)
        -- elseif getResultCnt >= 6 then
        --     AppDef.Director:getScheduler():unscheduleScriptEntry(GameSdk.LoginScheduler)
        --     GameSdk.LoginScheduler = nil
        --     self:U8SDKLogin()
        end
    end


    self:QuerySDKSwitchAccount()
    GameSdk.LoginScheduler = AppDef.Director:getScheduler():scheduleScriptFunc(checkLogResult, 0.5, false)
end

function GameSdk:QuerySDKSwitchAccount()
    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()
    if target == cc.PLATFORM_OS_ANDROID then

        local luaj = require "cocos/cocos2d/luaj"
        local args = {}
        local sigs = "()V"  --
        local className = "org/cocos2dx/lua/AppActivity"
        local ok,ret  =luaj.callStaticMethod(className,"doSDKSwitchAccount",args,sigs)
        if ok then
            if ret then
                return ret
            else
                print("CallJava_doSDKSwitchAccount nil ret:", ret)
            end
        else
            print("CallJava_doSDKSwitchAccount error")
        end
    end
    return 0
end

function GameSdk:QuerySDKLogin()
    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()
    if target == cc.PLATFORM_OS_ANDROID then

        local luaj = require "cocos/cocos2d/luaj"
        local args = {}
        local sigs = "()V"  --
        local className = "org/cocos2dx/lua/AppActivity"
        local ok,ret  =luaj.callStaticMethod(className,"doSDKLogin",args,sigs)
        if ok then
            if ret then
                return ret
            else
                print("CallJava_goSDKLogin nil ret:", ret)
            end
        else
            print("CallJava_goSDKLogin error")
        end
    end
    return 0
end

function GameSdk:U8GetSid()
    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()
    if target == cc.PLATFORM_OS_ANDROID then --(CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)

        local luaj = require "cocos/cocos2d/luaj"
        local args = {}
        local sigs = "()Ljava/lang/String;"  -- 返回long型有问题？
        local className = "org/cocos2dx/lua/AppActivity"
        local ok,ret  =luaj.callStaticMethod(className,"get_userID",args,sigs)
        print("CallJava_GetSid ok,ret:",ok,ret)
        if ok then
            if ret then
                return ret
            else
                print("CallJava_GetSid nil ret:", ret)

            end
        else
            print("CallJava_GetSid error")
        end
    elseif (cc.PLATFORM_OS_IPHONE == target) or (cc.PLATFORM_OS_IPAD == target) then
        return GameSdk:getIOSSid()
    end
    return ""
end

--token
function GameSdk:U8GetToken()
    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()
    if target == cc.PLATFORM_OS_ANDROID then --(CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)

        local luaj = require "cocos/cocos2d/luaj"
        local args = {}
        local sigs = "()Ljava/lang/String;"  -- 返回long型有问题？
        local className = "org/cocos2dx/lua/AppActivity"
        local ok,ret  =luaj.callStaticMethod(className,"get_Token",args,sigs)
        print("CallJava_GetToken ok,ret:",ok,ret)
        if ok then
            if ret then
                return ret
            else
                print("CallJava_GetToken nil ret:", ret)

            end
        else
            print("CallJava_GetToken error")
        end
    elseif (cc.PLATFORM_OS_IPHONE == target) or (cc.PLATFORM_OS_IPAD == target) then
        return GameSdk:getIOSToken()
    end
    return ""
end

