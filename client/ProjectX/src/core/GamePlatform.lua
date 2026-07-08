--[[
游戏运行平台的一些信息
]]

GamePlatform = {}
GamePlatform.__index = GamePlatform
GamePlatform.NetType = {
	GPRS = 1,--gprs连接
	WIFI = 2,--wifi连接
	NONE = 3,--没网络
}

GamePlatform.AndroidDeviceType = {
    TRUEPHONE = 1,--真机
    ANDROIDSIMULATOR = 2,--模拟器
}

GamePlatform.JavaAppActivity = "org/cocos2dx/lua/AppActivity"

--[[
获取设备存储空间
]]
function GamePlatform:GetStorageAvailableSize()
	--确认磁盘空间
	local app = cc.Application:getInstance()
	local target = app:getTargetPlatform()
	if target == cc.PLATFORM_OS_WINDOWS
		or target == cc.PLATFORM_OS_MAC then
		return 5024*1024*1024
	elseif target == cc.PLATFORM_OS_ANDROID then
    	return self:GetAndroidStorageAvailableSize()
	elseif target == cc.PLATFORM_OS_IPHONE or target == cc.PLATFORM_OS_IPAD then
    	return self:GetIOSStorageAvailableSize()
	end
end

function GamePlatform:GetDeviceIMEI()
    if GamePlatform.imei ~= nil then
        return GamePlatform.imei
    end 
    GamePlatform.imei = ""
    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()
    if target == cc.PLATFORM_OS_ANDROID then
        return self:GetAndroidIMEI()
    end
end

function GamePlatform:GetDeviceName()
    if GamePlatform.DeviceName ~= nil then
        return GamePlatform.DeviceName
    end
    GamePlatform.DeviceName = "Test"
    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()
    if target == cc.PLATFORM_OS_ANDROID then
        return self:GetAndroidDeviceName()
    end
end

function GamePlatform:GetAndroidDeviceName()
    local luaj = require "cocos/cocos2d/luaj"
    local args = {}
    local sigs = "()Ljava/lang/String;"  -- 返回long型有问题？
    local ok,ret  =luaj.callStaticMethod(GamePlatform.JavaAppActivity,"GetDeviceName",args,sigs)
    print("GetDeviceName ok,ret:",ok,ret)
    if ok then
        if ret then
            return ret
        else
            print("GetDeviceName nil ret:", ret)
            return ""
        end
    else
        print("GetDeviceName error")
        return ""
    end
end

function GamePlatform:GetAndroidIMEI()
    local luaj = require "cocos/cocos2d/luaj"
    local args = {}
    local sigs = "()Ljava/lang/String;"  -- 返回long型有问题？
    local ok,ret  =luaj.callStaticMethod(GamePlatform.JavaAppActivity,"getIMEI",args,sigs)
    print("getIMEI ok,ret:",ok,ret)
    if ok then
        if ret then
            return ret
        else
            print("getIMEI nil ret:", ret)
            return ""
        end
    else
        print("getIMEI error")
        return ""
    end
end

function GamePlatform:initGameAppID( ... )
    -- body
    if ((GameSdk.ChannelId > 1500 and GameSdk.ChannelId < 4000 ) and not GameSdk:isDouShenQuick()) 
        or GameSdk.ChannelId == 998 or GameSdk:IsYiJieSDK() then
        GameSdk.AppId = AppDef.APPID_JIANZHENGZHUXIAN
    else
        GameSdk.AppId = AppDef.APPID_DOUSHENWUSHUANG
    end
end

function GamePlatform:GetAPPID()
    local luaj = require "cocos/cocos2d/luaj"
    local args = {}
    local sigs = "()I"  -- 返回long型有问题？
    local ok,ret  =luaj.callStaticMethod(GamePlatform.JavaAppActivity,"getAppId",args,sigs)
    print("GetAPPID ok,ret:",ok,ret)
    if ok then
        if ret then
            return ret
        else
            print("getAppId nil ret:", ret)
            return AppDef.APPID_DOUSHENWUSHUANG
        end
    else
        print("getAppId error")
        return AppDef.APPID_DOUSHENWUSHUANG
    end
end

function GamePlatform:GetDeviceMacAddress()
    if GamePlatform.mac ~= nil then
        return GamePlatform.mac
    end 
    GamePlatform.mac = ""
    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()
    if target == cc.PLATFORM_OS_ANDROID then
        return self:GetAndroidMacAddress()
    end
end

function GamePlatform:GetAndroidMacAddress()
    local luaj = require "cocos/cocos2d/luaj"
    local args = {}
    local sigs = "()Ljava/lang/String;"  -- 返回long型有问题？
    local ok,ret  =luaj.callStaticMethod(GamePlatform.JavaAppActivity,"GetPhoneMacAddress",args,sigs)
    print("GetPhoneMacAddress ok,ret:",ok,ret)
    if ok then
        if ret then
            return ret
        else
            print("GetPhoneMacAddress nil ret:", ret)
            return ""
        end
    else
        print("GetPhoneMacAddress error")
        return ""
    end
end
--[[
获取设备信息
]]
function GamePlatform:GetNerworkInfo()
    local net = self:GetNetConnectType()
    if net ==  GamePlatform.NetType.WIFI then
        return "WIFI"
    elseif net == GamePlatform.NetType.GPRS then
        return "GPRS"
    else
        return "Unknown"
    end
end

function GamePlatform:GetAndroidStorageAvailableSize()
	local luaj = require "cocos/cocos2d/luaj"
    local args = {}
    local sigs = "()Ljava/lang/String;"  -- 返回long型有问题？
    local ok,ret  =luaj.callStaticMethod(GamePlatform.JavaAppActivity,"GetStorageAvailableSize",args,sigs)
	print("CallJava_GetStorageAvailableSize ok,ret:",ok,ret)
    if ok then
        if ret then
			return tonumber(ret)
        else
            print("CallJava_GetStorageAvailableSize nil ret:", ret)
            return 0
        end
    else
        print("CallJava_GetStorageAvailableSize error")
        return 0
    end
end

function GamePlatform:GetIOSStorageAvailableSize()
    local luaoc = require "cocos.cocos2d.luaoc"
    local args = nil
    local className = "LuaObjectCBridge"
    local ok,ret  =luaoc.callStaticMethod(className, "freeDiskSpace",args)
    -- print("GetIOSStorageAvailableSize,ret: ",ok,ret)
    if ok then
        if ret then
            return tonumber(ret)
        else
            return 0
        end
    else
        return 0
    end
end

--[[
是否是wifi连接
]]
function GamePlatform:IsWIFTConnect()
	if self:GetNetConnectType() == GamePlatform.NetType.WIFI then
		return true
	end
	return false
end

--[[
获取网络连接类型
return:GamePlatform.NetType
]]
function GamePlatform:GetNetConnectType()

	local app = cc.Application:getInstance()
	local target = app:getTargetPlatform()
	if target == cc.PLATFORM_OS_WINDOWS
		or target == cc.PLATFORM_OS_MAC then
		return GamePlatform.NetType.WIFI
	elseif target == cc.PLATFORM_OS_ANDROID then
    	return self:GetAndroidNetType()
	elseif target == cc.PLATFORM_OS_IPHONE or target == cc.PLATFORM_OS_IPAD then
    	return self:GetIOSNetType()
	end
end

function GamePlatform:GetAndroidNetType()
	local luaj = require "cocos/cocos2d/luaj"
    local args = {}
    local sigs = "()I"  --return int
    local ok,ret  =luaj.callStaticMethod(GamePlatform.JavaAppActivity,"GetNetworkType",args,sigs)
    if ok then
        if ret then
			return ret
        else
            print("CallJava_GetNetworkType nil ret:", ret)
            return GamePlatform.NetType.NONE
        end
    else
        print("CallJava_GetNetworkType error")
        return GamePlatform.NetType.NONE
    end
end

function GamePlatform:GetIOSNetType()
	return GamePlatform.NetType.NONE
end

function GamePlatform:GetAndroidDevicesType()
    -- body
    local luaj = require "cocos/cocos2d/luaj"
    local args = {}
    local sigs = "()I"  --return int
    local ok,ret  =luaj.callStaticMethod(GamePlatform.JavaAppActivity,"GetAndroidDevicesType",args,sigs)
    if ok then
        if ret then
            print("ret =", ret)
            return ret
        else
            print("CallJava_GetNetworkType nil ret:", ret)
            return GamePlatform.AndroidDeviceType.TRUEPHONE
        end
    else
        print("CallJava_GetNetworkType error")
        return GamePlatform.AndroidDeviceType.TRUEPHONE
    end
end
