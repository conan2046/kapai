LVoiceDataMgr = LUIBase:New()
LVoiceDataMgr.__index = LVoiceDataMgr

local targetPlatform = cc.Application:getInstance():getTargetPlatform()


function IosToLuaVoiceCallBack()
    -- body
    LVoiceDataMgr:IosVoiceRogCallBack()
end

function LVoiceDataMgr:Init()
	self.ChannelType = 0
	self.Content = ""
    self._isAutoPlay = false
    self._isInAutoPlay = false
    self._curPlayVoiceData = {}        --播放语音循环队列
    self._totalPlayVoiceData = {}
    self._isPlaying = false
end

--保存语音文件
function LVoiceDataMgr:saveVoice(data)
    -- body
    local writablePath = cc.FileUtils:getInstance():getWritablePath()
    local upLoadPath = writablePath .."outfile.pcm"

    --print("LVoiceDataMgr:saveVoice writablePath", upLoadPath)

--    io.writefile
    io.writefile(upLoadPath, data, "w+b");

end

function LVoiceDataMgr:startVoice()
    -- body
    --开始录音
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EAID_WORLDCHAT) then
        return
    end

    local bMusicMate = LUserConfigMgr:GetIsMusicClosed()
    if not bMusicMate then
        LGameMsg.m_audioMsg:Change(LAudioEvent.StartSpeakVoice)
        LUIManager:SendMsg(LGameMsg.m_audioMsg)
    end

    if (cc.PLATFORM_OS_ANDROID == targetPlatform) then
        local writablePath = cc.FileUtils:getInstance():getWritablePath()
    --                ------print("writablePath = ", writablePath)
        local path = writablePath .. "outfile.pcm"
        local args = {path}
        local sigs = "(Ljava/lang/String;)V"
        local luaj = require "cocos.cocos2d.luaj"
        local className = "org/cocos2dx/lua/AppActivity"
        local ok,ret  = luaj.callStaticMethod(className, "startLisening", args, sigs)
        if not ok then
            --print("luaj error:", ret)
        else
            --print("The ret is:", ret)
        end
    elseif targetPlatform == cc.PLATFORM_OS_IPHONE or targetPlatform == cc.PLATFORM_OS_IPAD then
        local writablePath = cc.FileUtils:getInstance():getWritablePath()
        local path = writablePath .. "outfile.pcm"
        local args = {voicePath = path}
        local luaoc = require "cocos.cocos2d.luaoc"
        local className = "LuaObjectCBridge"
        local ok = luaoc.callStaticMethod(className, "startListening", args)
        if not ok then
--                cc.Director:getInstance():resume()
            print("call ios error")
        else
            print("ios satrt listen call suc")
        end
    end
end

function LVoiceDataMgr:registerCallBack (ChatID)
    -- body
    if (cc.PLATFORM_OS_ANDROID == targetPlatform) then
        local args = {}
        local sigs = "()V"
        local luaj = require "cocos.cocos2d.luaj"
        local className = "org/cocos2dx/lua/AppActivity"

        local function callBackFrom(param)

            LGameMsg.m_baseMsgWithOne:Change(LUIChatEvent.showVoiceWindow, false)
            LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)

            local _content = param;
--                    self:uploadVoiceData();
            self.Content = _content
            self:uploadVoiceData(ChatID)
        end

        args = { "callBackFrom", callBackFrom }
        sigs = "(Ljava/lang/String;I)V"
        ok = luaj.callStaticMethod(className,"callBackFrom",args,sigs)
        if not ok then
            --print("call callback error")
        end
    elseif targetPlatform == cc.PLATFORM_OS_IPHONE or targetPlatform == cc.PLATFORM_OS_IPAD then
        print("call Back")
        self._curCharId = ChatID
--         local className = "LuaObjectCBridge"
--         local function callback(param)
--             print("result =", param)
--             print("object c call back success")
-- --             LGameMsg.m_baseMsgWithOne:Change(LUIChatEvent.showVoiceWindow, false)
-- --             LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)

-- --             local _content = param;
-- -- --                    self:uploadVoiceData();
-- --             self.Content = _content
-- --             self:uploadVoiceData(ChatID)
--         end
--         local luaoc = require "cocos.cocos2d.luaoc"
--         luaoc.callStaticMethod(className,"registerScriptHandler", {scriptHandler = callback } )

    end
end

function LVoiceDataMgr:IosVoiceRogCallBack()
    local function callback(param)
--        print("IosVoiceRogCallBack", param, self._curCharId)
        LGameMsg.m_baseMsgWithOne:Change(LUIChatEvent.showVoiceWindow, false)
        LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
        if param ~= nil then
            local _content = param;
--          self:uploadVoiceData();
            self.Content = _content
            self:uploadVoiceData(self._curCharId)
        end
    end
    local luaoc = require "cocos.cocos2d.luaoc"
    local className = "LuaObjectCBridge"
    luaoc.callStaticMethod(className,"registerScriptHandler", {scriptHandler = callback } )
    luaoc.callStaticMethod(className,"callbackScriptHandler")
end



function LVoiceDataMgr:endVoice()
    -- body
    if (cc.PLATFORM_OS_ANDROID == targetPlatform) then
        local writablePath = cc.FileUtils:getInstance():getWritablePath()
        local args = {}
        local sigs = "()V"
        local luaj = require "cocos.cocos2d.luaj"
        local className = "org/cocos2dx/lua/AppActivity"
        local ok,ret  = luaj.callStaticMethod(className, "stopListening", args, sigs)
        if not ok then
            --print("luaj error:", ret)
        else
            --print("The ret is:", ret)
        end
    elseif targetPlatform == cc.PLATFORM_OS_IPHONE or targetPlatform == cc.PLATFORM_OS_IPAD then
        print("ios end Voice")
        local args = {}
        local luaoc = require "cocos.cocos2d.luaoc"
        local className = "LuaObjectCBridge"
        local ok  = luaoc.callStaticMethod(className, "stopListening", nil)
        if not ok then
--                cc.Director:getInstance():resume()
            print("call ios error")
        else
            print("ios stopListening")
        end
    end

    local bMusicMate = LUserConfigMgr:GetIsMusicClosed()
    if not bMusicMate then
        LGameMsg.m_audioMsg:Change(LAudioEvent.StopSpeakVoice)
        LUIManager:SendMsg(LGameMsg.m_audioMsg)
    end
end

--语音
function LVoiceDataMgr:uploadVoiceData(chatID)
    --print("LVoiceDataMgr:uploadVoiceData")
    local targetPlatform = cc.Application:getInstance():getTargetPlatform()
    if targetPlatform == cc.PLATFORM_OS_WINDOWS then
        return
    end

    local dataName = "outfile.pcm"

    local xhr = cc.XMLHttpRequest:new()
    xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_ARRAY_BUFFER

    local writablePath = cc.FileUtils:getInstance():getWritablePath()
    local upLoadPath = writablePath .. dataName

    --print("LVoiceDataMgr:uploadVoiceData writablePath", upLoadPath)
--外网 111.231.62.116:8627
    local appAddr
    if GameSdk.AppId == AppDef.APPID_DOUSHENWUSHUANG then
        appAddr = "http://voice.play.cn:8627/upload"
    else
        appAddr = "http://jzzxyy.sp-pay.cn:8627/upload"
    end
    -- release_print("uploadVoiceData ==", GameSdk.AppId, appAddr)    
    xhr:open("post", appAddr)
--内网
--        xhr:open("post", "http://192.168.2.131:9812/upload")
    local function onReadyStateChanged()
        --print("function onReadyStateChanged ", xhr.readyState)
        if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
            local response   = xhr.response
            local size     = table.getn(response)
            local strInfo = ""

            for i = 1,size do
                if 1 == response[i] then
                    strInfo = strInfo.."\'\\0\'"
                else
                    strInfo = strInfo..string.char(response[i])
                end
            end

            local versionManifest = json.decode(strInfo, 1)
            -- release_print("versionManifest -------------------------------", versionManifest.res, versionManifest.fid, chatID)
            self._fid = versionManifest.fid            
            self:sendVoiceMsg(versionManifest.fid, chatID)

            local resetData = ""
            local isDone = io.writefile(upLoadPath, resetData, "w+b");
            -- print("onReadyStateChanged isDone", upLoadPath, isDone)

        else
            --print("xhr.readyState is:", xhr.readyState, "xhr.status is: ",xhr.status)
        end
        xhr:unregisterScriptHandler()
    end
    xhr:registerScriptHandler(onReadyStateChanged)

    local file = io.open(upLoadPath, "rb")
    local data;
    if not file then
        --print("not file", upLoadPath)
        return
    end

    data = file:read("*a")
    io.close(file)

    local dataLength = string.len(data)
    --print("data = ", dataLength);
    self._durTime = math.floor(dataLength / 32000)
    local filename = string.format("\"%s\"", dataName)
    --print("filename", filename)

    xhr:setRequestHeader("Accept-Encoding", "gzip, deflate");
    xhr:setRequestHeader("Content-Disposition", "form-data; name=\"file\"; filename=" .. filename);
    xhr:setRequestHeader("Content-Type", "application/octet-stream");
    xhr:send(data)

end

--
function LVoiceDataMgr:downloadVoiceData(fid, time)
    -- body
--测试代码
    -- self:execAutoPlay(fid)           
    -- self:playVoice()
--播放中，不允许再次播放
    if self._isPlaying then
        return
    end    

    local targetPlatform = cc.Application:getInstance():getTargetPlatform()
    if cc.PLATFORM_OS_ANDROID == targetPlatform or cc.PLATFORM_OS_IPHONE == targetPlatform then
        local xhr = cc.XMLHttpRequest:new()
        xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_BLOB
        --print("LVoiceDataMgr:downloadVoiceData fid", fid)
    --外网 111.231.62.116:8627
        --剑阵域名 47.102.106.254
        local appAddr
        -- release_print("downloadVoiceData ==", GameSdk.AppId)
        if GameSdk.AppId == AppDef.APPID_DOUSHENWUSHUANG then
            appAddr = "http://voice.play.cn:8627/listen?fid="
        else
            appAddr = "http://jzzxyy.sp-pay.cn:8627/listen?fid="
        end    
        -- release_print("downloadVoiceData appAddr ==", appAddr)
        local url  = appAddr..fid
    --内网
    --    local fid = "d29086a90ae399ab1f399fd5f0352a15"
--        local url  = "http://192.168.2.131:9812/listen?fid="..fid
        --print("LVoiceDataMgr:downloadVoiceData fid", url)

        xhr:open("GET", url)
        local function onReadyDownLoadStateChanged()
            --print("onReadyDownLoadStateChanged", xhr.readyState)
            if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
                local response   = xhr.response
                local size     = string.len(response)
                -- print("downLoad onReadyDownLoadStateChanged size =", size)
                local writablePath = cc.FileUtils:getInstance():getWritablePath()
                local path = writablePath .. "outfile2.pcm"
                local isDone = io.writefile(path, response, "w+b");
                self:execAutoPlay(fid)
                -- print("onReadyDownLoadStateChanged fid ", path, fid)
                self:playVoice(time)              
            else
                --print("xhr.readyState is:", xhr.readyState, "xhr.status is: ",xhr.status)
            end
            xhr:unregisterScriptHandler()
        end

        xhr:registerScriptHandler(onReadyDownLoadStateChanged)
        xhr:send()
    end

end

--发送声音消息
function LVoiceDataMgr:sendVoiceMsg(fid, chatID)
    local targetPlatform = cc.Application:getInstance():getTargetPlatform()
    if cc.PLATFORM_OS_ANDROID == targetPlatform or cc.PLATFORM_OS_IPHONE == targetPlatform then

        if self._durTime < 1 then
            self._durTime = 1
        end

        if self._durTime > 60 then
            self._durTime = 59;
        end
        
        local chatContent = {}
        chatContent.id = LRoleDataMgr.MyHeroInfo.id;
        chatContent.fid = fid
        chatContent.time = self._durTime
        chatContent.content = self.Content;

        local jsonValue = json.encode(chatContent)
        --print(jsonValue)

        local _inputString = jsonValue
        -- release_print("m_inputString : ", _inputString, self.ChannelType);

        if string.len(_inputString) > 0 then
        
--            print("LVoiceDataMgr:sendVoiceMsg self.ChannelType", self.ChannelType)
            if self.ChannelType ~= AppDef.ChatChanelType.CCT_PERSIONAL then
                -- release_print("m_inputString sendVoiceMsg ==", _inputString, self.ChannelType)
                LuaNetSendMsg:QuerySendChatMsg(self.ChannelType, _inputString);
            else
                LuaNetSendMsg:QuerySendPriateMsg(AppDef.ChatChanelType.CCT_PERSIONAL, chatID, _inputString);
            end
        end
    end

end

--调用java pcmTowav
function LVoiceDataMgr:pcmToWavfunc( ... )
    -- body
    local writablePath = cc.FileUtils:getInstance():getWritablePath()
--                --print("writablePath = ", writablePath)
    local pathWav = writablePath .. "outfile3.wav"
    local pathPCM = writablePath .. "outfile.pcm"


    local args = {pathPCM, pathWav}
    local sigs = "(Ljava/lang/String;Ljava/lang/String;)V"
    local luaj = require "cocos.cocos2d.luaj"
--                local className = "../../core/src/main/java/com/baidu/aip/asrwakeup3/core/mini/ActivityMiniRecog"
    local className = "org/cocos2dx/lua/AppActivity"
    local ok,ret  = luaj.callStaticMethod(className, "pcmToWav", args, sigs)
    if not ok then
        --print("luaj error:", ret)
    else
        --print("The ret is:", ret)
    end
end


function LVoiceDataMgr:writeInt(stringBytes,intNum)
--    local b1 = string.char(intNum%256) intNum = (intNum - intNum%256)/256
--    local b2 = string.char(intNum%256) intNum = (intNum - intNum%256)/256
--    local b3 = string.char(intNum%256) intNum = (intNum - intNum%256)/256
--    local b4 = string.char(intNum%256) intNum = (intNum - intNum%256)/256
    
    local b1 = bit._and(intNum,0xff)
    intNum = bit._rshift(intNum,8)
    
    local b2 = bit._and(intNum,0xff)
    intNum = bit._rshift(intNum,8)

    local b3 = bit._and(intNum,0xff)
    intNum = bit._rshift(intNum,8)

    local b4 = bit._and(intNum,0xff)
--    intNum = bit._rshift(intNum,1)

--    local b1 = string.char(bit._and(intNum,0xff)) intNum = (intNum - intNum%256)/256
--    local b2 = string.char(intNum%256) intNum = (intNum - intNum%256)/256
--    local b3 = string.char(intNum%256) intNum = (intNum - intNum%256)/256
--    local b4 = string.char(intNum%256) intNum = (intNum - intNum%256)/256
    stringBytes = stringBytes .. string.char(b1) .. string.char(b2) .. string.char(b3) .. string.char(b4)
    return stringBytes
end

function LVoiceDataMgr:writeShort(stringBytes,intNum)
    local b1 = bit._and(intNum,0xff)
    intNum = bit._rshift(intNum,8)
    local b2 = bit._and(intNum,0xff)
    stringBytes = stringBytes .. string.char(b1) .. string.char(b2)
    return stringBytes
end

function LVoiceDataMgr:ConvertPcmToWav(pcm, pcmlen, wavPath)
    local wavLen = pcmlen + 44
    local stringBytes = "RIFF"
    stringBytes = self:writeInt(stringBytes, pcmlen + 36)
    stringBytes = stringBytes .. "WAVEfmt "
    stringBytes = self:writeInt(stringBytes, 16)
    stringBytes = self:writeShort(stringBytes, 1)
    stringBytes = self:writeShort(stringBytes, 2)
    stringBytes = self:writeInt(stringBytes, 8000)
    stringBytes = self:writeInt(stringBytes, 32000)
    stringBytes = self:writeShort(stringBytes,4)
    stringBytes = self:writeShort(stringBytes,16)
    stringBytes = stringBytes .. "data"
    stringBytes = self:writeInt(stringBytes, pcmlen)
    stringBytes = stringBytes .. pcm
    --io.writefile(wavPath, stringBytes, "w+b")
    io.writefile(wavPath, stringBytes, "w+b")
end


function LVoiceDataMgr:playVoice(time)
    -- body
    --转换格式
    local writablePath = cc.FileUtils:getInstance():getWritablePath()
    local path = writablePath .. "outfile2.pcm"

    local file = io.open(path, "rb")
    if not file then
        print("not file", path)
        return
    end
    data = file:read("*a")
    io.close(file)

    local wavPath = writablePath .. "outfile2.wav"
    print("playVoice data length =", string.len(data))
    self:ConvertPcmToWav(data, string.len(data), wavPath)

    local file2 = io.open(wavPath, "rb")
    if not file2 then
        print("not file2", wavPath)
        return
    end
    local data3 = file2:read("*a")
    io.close(file2)
    print("playVoice wavData length =", string.len(data3))


    performWithDelay(AppDef.CurScene, function(sender)
            --开始播放
--            cc.SimpleAudioEngine:getInstance():pauseBackgroundMusic()
            local bMusicMate = LUserConfigMgr:GetIsMusicClosed()
            if not bMusicMate then
                LGameMsg.m_audioMsg:Change(LAudioEvent.PauseBgMusic)
                LUIManager:SendMsg(LGameMsg.m_audioMsg)
            end
            
            self:setAudioVolume()
            local targetPlatform = cc.Application:getInstance():getTargetPlatform() 
            if cc.PLATFORM_OS_ANDROID == targetPlatform then
                cc.SimpleAudioEngine:getInstance():unloadEffect(wavPath)
                cc.SimpleAudioEngine:getInstance():playEffect(wavPath)
            else
                self:IOSPlayVoice()
            end
            self._isPlaying = true
            
        end, 0.2)


    local playTime = 0.2 
    if time then
        playTime = playTime + time
    end
    performWithDelay(AppDef.CurScene, function(sender)
        --播放完毕
        self:resumeAudioVolume()
--        cc.SimpleAudioEngine:getInstance():resumeBackgroundMusic()
            local bMusicMate = LUserConfigMgr:GetIsMusicClosed()
            if not bMusicMate then
                LGameMsg.m_audioMsg:Change(LAudioEvent.ResumeBgMusic)
                LUIManager:SendMsg(LGameMsg.m_audioMsg)
            end
            self._isPlaying = false
        end, 0.2 + playTime)

end

function LVoiceDataMgr:setAudioVolume( ... )
    if (cc.PLATFORM_OS_ANDROID == targetPlatform) then
    -- body
        local args = {}
        local sigs = "()V"
        local luaj = require "cocos.cocos2d.luaj"
    --                local className = "../../core/src/main/java/com/baidu/aip/asrwakeup3/core/mini/ActivityMiniRecog"
        local className = "org/cocos2dx/lua/AppActivity"
        local ok,ret  = luaj.callStaticMethod(className, "setAudioVolume", args, sigs)
        if not ok then
            --print("setAudioVolume luaj error:", ret)
        else
            --print("setAudioVolume The ret is:", ret)
        end
    elseif targetPlatform == cc.PLATFORM_OS_IPHONE or targetPlatform == cc.PLATFORM_OS_IPAD then

    end

end

function LVoiceDataMgr:resumeAudioVolume( ... )
    -- body
    if (cc.PLATFORM_OS_ANDROID == targetPlatform) then
        local args = {}
        local sigs = "()V"
        local luaj = require "cocos.cocos2d.luaj"
    --                local className = "../../core/src/main/java/com/baidu/aip/asrwakeup3/core/mini/ActivityMiniRecog"
        local className = "org/cocos2dx/lua/AppActivity"
        local ok,ret  = luaj.callStaticMethod(className, "resumeAudioVolume", args, sigs)
        if not ok then
            --print("resumeAudioVolume luaj error:", ret)
        else
            --print("resumeAudioVolume The ret is:", ret)
        end
    elseif targetPlatform == cc.PLATFORM_OS_IPHONE or targetPlatform == cc.PLATFORM_OS_IPAD then
        
    end
end

function LVoiceDataMgr:addVoiceQuene(data)

--如果不是自动播放则return
    if not self._isAutoPlay then
        return
    end

    local idx = self:FindInPlayList(data.fid, self._totalPlayVoiceData)
--    --print("LVoiceDataMgr:addVoiceQuene idx", idx)
--超过最大数，则删除
    if #self._totalPlayVoiceData > AppDef.Chat_Msg_Type.CCT_NUM_VOICE then
        table.remove(self._totalPlayVoiceData, 1)
    end

    if idx <= 0 then
        table.insert(self._totalPlayVoiceData, data)
    end

--    --print("LVoiceDataMgr:addVoiceQuene", #self._totalPlayVoiceData)

    if data.chanel == self.ChannelType or self.ChannelType == AppDef.ChatChanelType.CCT_COMMON then

        if #self._curPlayVoiceData > AppDef.Chat_Msg_Type.CCT_NUM_VOICE then
            table.remove(self._curPlayVoiceData, 1)
        end

        local idxTmp = self:FindInPlayList(data.fid, self._curPlayVoiceData)

        if idxTmp <= 0 then 
            table.insert(self._curPlayVoiceData, data)
        end

--        --print("LVoiceDataMgr: 44444", #self._curPlayVoiceData, idxTmp)        
    end

    self:beginAutoPlayVoice()

end

function  LVoiceDataMgr:FindInPlayList(fid, voicePlayList)   --按Id查找 返回idx

    if(voicePlayList == nil) then
        return -1
    end

    for i = 1, #voicePlayList do
        if voicePlayList[i].fid == fid then
            return i
        end
    end
    return -1
end

function LVoiceDataMgr:beginAutoPlayVoice( ... )
    -- body
    if self._isAutoPlay and not self._isInAutoPlay then
        self._isInAutoPlay = true
        self:aotuPlayVoice()
    end
end

function LVoiceDataMgr:deleteVoiceQuene(id)
    -- body
    if not self._isInAutoPlay then
        self:clearVoiceQuene()
        return
    end

    local idxTmp = self:FindInPlayList(id, self._totalPlayVoiceData)
    if idxTmp > 0 then
        table.remove(self._totalPlayVoiceData, idxTmp)
    end

    local idx = self:FindInPlayList(id, self._curPlayVoiceData)
--    --print("LVoiceDataMgr:deleteVoiceQuene", idx, id)
--    Utils:dump(self._curPlayVoiceData)
    if idx > 0 then
        table.remove(self._curPlayVoiceData, idx)
    end

end

function LVoiceDataMgr:clearVoiceQuene()
    self._totalPlayVoiceData = {}
    self._curPlayVoiceData = {}
end

function LVoiceDataMgr:execAutoPlay(fid)
    -- body
    self:deleteVoiceQuene(fid)
    if self._curData == nil then
        return
    end

    performWithDelay(AppDef.CurScene, function(sender)
        self:aotuPlayVoice()
        end, self._curData.time)

end

function LVoiceDataMgr:IOSPlayVoice( ... )
    -- body
    local args = {}
    local luaoc = require "cocos.cocos2d.luaoc"
    local className = "LuaObjectCBridge"
    local ok  = luaoc.callStaticMethod(className, "startWinPlayer", nil)
    if not ok then
--                cc.Director:getInstance():resume()
        print("call ios error startWinPlayer")
    else
        print("ios startWinPlayer")
    end
end

--自动播放语音
function LVoiceDataMgr:aotuPlayVoice( ... )
    -- body
    if not self._isInAutoPlay then
        return
    end

    if #self._curPlayVoiceData <= 0 then
        self._isInAutoPlay = false
        return
    end
--    --print("aotuPlayVoice *******************************", #self._curPlayVoiceData)

    self._curData = self._curPlayVoiceData[1]
    self:downloadVoiceData(self._curData.fid, self._curData.time)
    
end


function LVoiceDataMgr:ChangeChannelEvent(channelType)
    -- body
    
    self._curPlayVoiceData = {}
    for i = 1, #self._totalPlayVoiceData do
        if self._totalPlayVoiceData[i].chanel == channelType or self.ChannelType == AppDef.ChatChanelType.CCT_COMMON then
            table.insert(self._curPlayVoiceData, self._totalPlayVoiceData[i])
        end
    end

    if #self._curPlayVoiceData > 0 then
        cc.SimpleAudioEngine:getInstance():stopAllEffects()
    end
end


LVoiceDataMgr:Init()