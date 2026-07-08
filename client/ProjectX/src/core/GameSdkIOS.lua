
GameSdk.isFullScreen = false
GameSdk.IDFA = ""
GameSdk.payMoney = 0
GameSdk.iapOrderId = 0
GameSdk.IapReceipt = ""

function IOSCloseWaiting()
    -- body
    Utils:RemoveWaiting(LuaNetCmd.MSG_CLIENT_MARKET)
end

function IOSLogoutFromSDK()
    -- body
    GameSdk:GameLogoutCallBack()
end

function IOSQuickPaySucCallBack()
    -- body
    GameSdk:updateQuickPlayerInfo()
    GameSdk:IOSQuickPaySucCB()
end

function updatePlayerInfo()
    -- body
    GameSdk:updateQuickPlayerInfo()
end

function GameSdk:InitIOSChannelInfo()
    local app = cc.Application:getInstance()
    local targetPlatform = app:getTargetPlatform()
    if (cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform) or (cc.PLATFORM_OS_MAC == targetPlatform) then
            local args = nil
            local luaoc = require "cocos.cocos2d.luaoc"
            local className = "LuaObjectCBridge"
            local ok,ret  = luaoc.callStaticMethod(className, "isFullScreenToLua", args)
            if not ok then
--                cc.Director:getInstance():resume()
                print("call ios error")
            else
                print("The ret is:", ret)
                GameSdk.isFullScreen = ret
            end

            local function callback(param)
                if "success" == param then
                    print("object c call back success")
                end
            end
            luaoc.callStaticMethod(className,"registerScriptHandler", {scriptHandler = callback } )
            luaoc.callStaticMethod(className,"callbackScriptHandler")
    end
end

function GameSdk:getIOSSid( ... )
    -- body
    local luaoc = require "cocos.cocos2d.luaoc"
    local args = nil
    local className = "LuaObjectCBridge"
    local ok,ret  =luaoc.callStaticMethod(className, "luaGetSid", args)
    print("InitChannelId ok,ret:",ok,ret)
    if ok then
        if ret then
            return ret
        else
            print("CallIOS_GetSid nil ret:", ret)
        end
    else
        print("CallIOS_GetSid error")
    end
    return ""
end

function GameSdk:getIOSToken( ... )
    -- body
    local luaoc = require "cocos.cocos2d.luaoc"
    local args = nil
    local className = "LuaObjectCBridge"
    local ok,ret  =luaoc.callStaticMethod(className, "luaGetToken",args)
    print("CallIOS_GetToken ok,ret:", ok, ret)
    if ok then
        if ret then
            return ret
        else
            print("CallIOS_GetSid nil ret:", ret)
        end
    else
        print("CallIOS_GetSid error")
    end
    return ""
end


function GameSdk:InitIOSChannelId()
    local luaoc = require "cocos.cocos2d.luaoc"
    local args = nil
    local className = "LuaObjectCBridge"
    local ok,ret  =luaoc.callStaticMethod(className, "GetChannelId",args)
    print("InitChannelId ok,ret:",ok,ret)
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

function GameSdk:InitIOSIAFD()
    local luaoc = require "cocos.cocos2d.luaoc"
    local args = nil
    local className = "LuaObjectCBridge"
    local ok,ret  =luaoc.callStaticMethod(className, "getIDFA",args)
    print("InitChannelId ok,ret:",ok,ret)
    if ok then
        if ret then
            GameSdk.IDFA = ret
        else
            print("InitChannelId nil ret:", ret)
            GameSdk.IDFA = ""
        end
    else
        print("InitChannelId error")
        GameSdk.IDFA = ""
    end
end

function GameSdk:IAPPay(price)
    -- body
    local args = {money = tonumber(price)}
    local luaoc = require "cocos.cocos2d.luaoc"
    local className = "LuaObjectCBridge"
    local ok  = luaoc.callStaticMethod(className, "buyProduct", args)
    print("InitIOSChannelInfo IAPPay", ok)
end

function GameSdk:regesterIosPaySucCallBack()
    local function iapPayCallback(param)
        GameSdk.IapReceipt = param
        self:SendReceiptToServer()
    end
    local luaoc = require "cocos.cocos2d.luaoc"
    local className = "LuaObjectCBridge"
    luaoc.callStaticMethod(className,"registerScriptHandlerPaySuc", {scriptHandler = iapPayCallback } )

end

function GameSdk:SendReceiptToServer( ... )
     -- body
     print("SendReceiptToServer ", GameSdk.ChannelId, GameSdk.iapOrderId, GameSdk.IapReceipt, GameSdk.payMoney, GameSdk.IDFA)
     LuaNetSendMsg:QueryIAPInfoToServer(GameSdk.ChannelId, GameSdk.iapOrderId, GameSdk.IapReceipt, GameSdk.payMoney, "", "", "", GameSdk.IDFA)
end 

function GameSdk:GetAPPID()
    return AppDef.APPID_DOUSHENWUSHUANG
end

function GameSdk:fetchProductIdentifier( ... )
    -- body
    local args = nil
    local luaoc = require "cocos.cocos2d.luaoc"
    local className = "LuaObjectCBridge"
    local ok  = luaoc.callStaticMethod(className, "fetchProductIdentifier", args)
    -- print("InitIOSChannelInfo fetchProductIdentifier", ok)
end

function GameSdk:QuickSDKLogin( ... )
    -- body
    local args = nil
    local luaoc = require "cocos.cocos2d.luaoc"
    local className = "LuaObjectCBridge"
    local ok  = luaoc.callStaticMethod(className, "QuickSDKLogin", args)
end

function GameSdk:QuickSDKDoPayment(money, orderId, callbackInfo)
    -- body
    local payInfo = {}
    payInfo.money = money
    payInfo.roleId = tostring(LRoleDataMgr.MyHeroInfo.id)
    local heroData = LRoleDataMgr.MyHeroInfo
    local serverId = heroData.serverId
    payInfo.serverId = serverId
    payInfo.roleLevel = LRoleDataMgr.MyHeroInfo.level
    payInfo.roleName = LRoleDataMgr.MyHeroInfo.name
    payInfo.serName = LUserConfigMgr:GetLastSelServerName()
    local info = LRoleDataMgr.MyHeroInfo.MyVIPInfo
    payInfo.Vip = info.vipLevel
    local args = {money = payInfo.money, orderId = orderId, serverId = payInfo.serverId, serverName = payInfo.serName,
                   roleName = payInfo.roleName, roleId = payInfo.roleId, roleLevel = payInfo.roleLevel, vipLevel = payInfo.Vip, extrasParams = callbackInfo}
    local luaoc = require "cocos.cocos2d.luaoc"
    local className = "LuaObjectCBridge"
    print("QuickSDKDoPayment", QuickSDKDoPayment)
    local ok  = luaoc.callStaticMethod(className, "QuickSDKPay", args)

end

function GameSdk:IOSQuickPaySucCB()
    -- body
    Utils:SendMsg(LUILogicEvent.paymentSuccess)
end

function GameSdk:updateQuickPlayerInfo( ... )
    -- body
    if not GameSdk:IsQuickSDK() then
        return
    end
    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()

    if target == cc.PLATFORM_OS_IPHONE or target == cc.PLATFORM_OS_IPAD then
        local payInfo = {}
        local heroData = LRoleDataMgr.MyHeroInfo
        payInfo.roleId = tostring(LRoleDataMgr.MyHeroInfo.id)
        local serverId = heroData.serverId
        payInfo.serverId = serverId
        payInfo.serName = LUserConfigMgr:GetLastSelServerName()
        local info = LRoleDataMgr.MyHeroInfo.MyVIPInfo
        payInfo.Vip = info.vipLevel
        payInfo.serverId = serverId
        payInfo.roleName = LRoleDataMgr.MyHeroInfo.name
        payInfo.roleLevel = LRoleDataMgr.MyHeroInfo.level
        local args = {serverId = payInfo.serverId, serverName = payInfo.serName,
                       roleName = payInfo.roleName, roleId = payInfo.roleId, roleLevel = payInfo.roleLevel, vipLevel = payInfo.Vip}
        local luaoc = require "cocos.cocos2d.luaoc"
        local className = "LuaObjectCBridge"
        print("QuickSDKDoPayment", QuickSDKDoPayment)
        local ok  = luaoc.callStaticMethod(className, "updateGameInfo", args)
    end
end

function GameSdk:setIapOrderId(iapOrderId)
    -- body
    local args = {orderId = iapOrderId}
    local luaoc = require "cocos.cocos2d.luaoc"
    local className = "LuaObjectCBridge"
    local ok  = luaoc.callStaticMethod(className, "setIapOrderId", args)
end




