
GameSdkYiJie = {}
GameSdkYiJie.__index = GameSdkYiJie

--CP服务器地址，支付结果同步地址
--如果客户端不设置，将以在易接后台创建游戏时设置的数据同步地址进行同步
--GameSdkYiJie.cpPaySyncUrl = "http://47.102.106.254:801/pay/yijie_callback.php"
GameSdkYiJie.cpPaySyncUrl = ""

--CP服务器地址:用作登录验证.因为有些渠道要求必须做登录验证，为了统一处理，所以只有登录验证成功之后才算真正的登陆成功
--登陆验证是由CP服务器实现的，供游戏客户端调用验证用户登录状态的接口。 游戏客户端和游戏服务器之间的登陆验证接口由CP自己定义 
--自建正服
--cpLoginCheckUrl = "http://testomsdk.xiaobalei.com:5555/cp/user/paylog/checkLoginZijianP"
--自建测服
--cpLoginCheckUrl = "http://testomsdk.xiaobalei.com:5555/cp/user/paylog/checkLoginZijian"
--测服
--cpLoginCheckUrl = "http://testomsdk.xiaobalei.com:5555/cp/user/paylog/checkLogin"
--正服
GameSdkYiJie.cpLoginCheckUrl = "http://testomsdk.xiaobalei.com:5555/cp/user/paylog/checkLoginP"

--登陆验证
function GameSdkYiJie:encodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

function GameSdkYiJie:loginEvent(userInfo)
    -- body
    local app = userInfo["productCode"]
    local sdk = userInfo["channelId"]
    local uin = userInfo["channelUserId"]
    local sess = userInfo["token"]
    local name = sdk .."|"..uin
    GameSdk.UserId = name
    GameSdk.Token = sess
    print("loginEvent app =", app, sdk, uin, sess, name)
    LuaNetSendMsg:QueryACLogin(GameSdk.UserId, GameSdk.Token, GameSdk.GameVersion, GameSdk.ChannelId, GameSdk.IMEI)
end

--支付回调
function GameSdkYiJie:payCallback(jPrama)
    require "json"
    local data = json.decode(jPrama);
    print("yj payCallback ", jPrama)
    if data["result"] == "success" then--支付成功
        print("yj payCallback 支付成功：", data["remain"])
        Utils:SendMsg(LUILogicEvent.paymentSuccess)
    elseif data["result"] == "oderno" then--获得订单号
        print("yj payCallback 订单号", data["remain"])
    elseif data["result"] == "fail" then--支付失败
        print("yj payCallback 支付失败", data["remain"])
    end
end


--退出回调
function GameSdkYiJie:exitCallback(jPrama)
    print("yj exitCallback end")
    print("yj exitCallback ", jPrama)
    require "json"
    local data = json.decode(jPrama);   
    print("yj exitCallback data[result]", data["result"])
    if data["result"] == "exit" then--退出游戏
        print("yj exitCallback exit")
        os.exit()
    elseif data["result"] == "noExit" then--用户取消退出，继续游戏
        print("yj exitCallback noExit")
    elseif data["result"] == "noProvide" then--使用游戏本身的退出界面
        print("yj exitCallback noProvide")
        --使用游戏自己的退出
        os.exit()
    end
end
    
--SDK初始化回调
function GameSdkYiJie:sdkInitCallbackFunc(jPrama)
    require "json"
    local data = json.decode(jPrama);   
    if data["tag"] == "success" then
        
    elseif data["tag"] == "fail" then
        
    end
end

--登陆回调
function GameSdkYiJie:loginCallback(jPrama)
    require "json"
    local data = json.decode(jPrama);
    print("yj loginCallback ", jPrama)
    if data["result"] == "success" then--登陆成功      
        --登陆成功之后需要去服务器验证登陆是否成功
        self:loginEvent(data)
    elseif data["result"] == "fail" then--登陆失败
        GameSdk:yijieLogin()
    elseif data["result"] == "logout" then--登出回调
--        YijieInterface.new():login("login")
        GameSdk:GameLogoutCallBack()
    end
end