--[[
热更新检测场景
]]

local UpdateScene = class("UpdateScene", cc.Scene)

function UpdateScene:create()
    local scene = UpdateScene.new()
    return scene
end

function UpdateScene:ctor()
    local function onNodeEvent(eventName)  
        if "enter" == eventName then 
            self:onEnter() 
        elseif "exit" == eventName then  
            self:onExit()
        elseif "enterTransitionFinish" == eventName then
            self:onEnterTransitionFinish()
        elseif "exitTransitionStart" == eventName then    
            self:onExitTransitionStart()
        elseif "cleanup" == eventName then
            self:onCleanup()
        end  
    end  
  
    self:registerScriptHandler(onNodeEvent) 
    
    
end

function UpdateScene:onEnter()
	
end

function UpdateScene:RequireFrameScripts()
	
end

function UpdateScene:UnRequireFrameScripts()
	local ignoreKeys = {} --重登无需重新加载的模块,
	local isCocosScripts = false
	local strKey 
	for k,v in pairs(package.loaded) do
		isCocosScripts = false
		strKey = tostring(k)
		for i = 1, #CC_COCOS_SCRIPT_ARRAY do
			if CC_COCOS_SCRIPT_ARRAY[i] == strKey then
				isCocosScripts = true
				break
			end
		end
		if isCocosScripts == false then
			package.loaded[k] = nil	
		end
	end
end

function UpdateScene:InitBg()
	local csbPath = "csd/Login/LoginBgLayer.csb";
	-- if GameSdk.AppId == AppDef.APPID_JIANZHENGZHUXIAN then
	-- 	csbPath = "csd/LoginBgLayer2.csb";
	-- end
	self.m_pBgLayer = cc.CSLoader:createNode(csbPath)
    local frameSize = AppDef.frameSize
    self.m_pBgLayer:setContentSize(frameSize)
    ccui.Helper:doLayout(self.m_pBgLayer)
    self:addChild(self.m_pBgLayer)

    local panel = self.m_pBgLayer:getChildByName("UI_Login")
    local bg = panel:getChildByName("Bg")
    if GameSdk.AppId == AppDef.APPID_JIANZHENGZHUXIAN then
    	bg:loadTexture("res/UI/ui_login/bg2_jzzx.jpg", ccui.TextureResType.localType)
    else
    	bg:loadTexture("res/UI/ui_login/bg2.jpg", ccui.TextureResType.localType)
    end
    
    local bgSize = bg:getContentSize()
    local scaleRateX =  frameSize.width / bgSize.width
    local scaleRateY = frameSize.height / bgSize.height
    local radio = (scaleRateX > scaleRateY) and scaleRateX or scaleRateY;
    local logo = panel:getChildByName("Logo")
    logo:setVisible(false)
    bg:setScale(radio)

    local pInfo = panel:getChildByName("Panel_1")
    local _ = pInfo and pInfo:setVisible(false)

    local versionLabel = panel:getChildByName("Versions")
    if GameSdk:IsSDKUser() == false then
        local url = "Manifest/ad"..GameSdk.ChannelId.."/project.manifest"
        local str = cc.FileUtils:getInstance():getStringFromFile(url)
        local versionManifest = json.decode(str,1)

        local verStr = string.format(GUITips.Version, versionManifest["showVersion"])
        verStr = "Version:" .. verStr
        versionLabel:setString(verStr)
    else
        versionLabel:setVisible(false)
    end

    if Utils:isIOSPlatform() then
    	self:ShowWaitTips(GUITips.Game_Check_Version_IOS)
    else
    	self:ShowWaitTips(GUITips.Game_Check_Version)
    end
    
end

function UpdateScene:onExit()
    self:unregisterScriptHandler()
	self.m_pBgLayer = nil
end

function UpdateScene:onEnterTransitionFinish()
	self:init()
	self:InitData()
	self:InitBg()

	self:InitAssetsMgr()
end

function UpdateScene:onExitTransitionStart()

end

function UpdateScene:onCleanup()

end

function UpdateScene:InitData()
	GameSdk:InitGameVersion()

	self.m_manifest = nil--热更新文件位置
	self.m_assetsMgr = nil--热更管理类
	self.m_storagePaths = nil--热更新存储路径
	self.m_totalBytes = 0
	self.m_curBytes = 0
	self.m_bIsCheckingVersion = true--是否在检测版本中


	


	self.m_manifest = "Manifest/ad" .. GameSdk.ChannelId .. "/project.manifest"
	self.m_storagePaths = "package"
end


function UpdateScene:InitAssetsMgr()
	print("InitAssetsMgr")
	if self.m_assetsMgr ~= nil then
		return
	end
	print("InitAssetsMgr create")
	self.m_assetsMgr = cc.AssetsManagerEx:create(self.m_manifest, cc.FileUtils:getInstance():getWritablePath() .. self.m_storagePaths)
	self.m_assetsMgr:retain()


	--退出游戏
	local function onExit(target, pNode )
		AppDef.Director:endToLua()
	end

	local function connectFail()
		self:ConnectFail()
	end

	local function onUpdateEvent(event)
		self:HandleAssetsUpdateEvt(event)
	end


	if self.m_assetsMgr:getLocalManifest():isLoaded() then
		print("isLoaded true")
		local listener = cc.EventListenerAssetsManagerEx:create(self.m_assetsMgr,onUpdateEvent)
		AppDef.Director:getEventDispatcher():addEventListenerWithFixedPriority(listener, 1)
		self.m_bIsCheckingVersion = true
		self.m_assetsMgr:checkUpdate()
    else
        self:ConnectFail()
	end
end

function UpdateScene:ConnectFail()
	-- local function okFunc()
 --        self:StartGame()
 --    end
 --    local function cancelFunc()
 --        self:StartGame()
 --    end
 --    self:ClearWaitTips()
 --    local msg = GUITips.Game_Update_ConnectFail
 --    Utils:ShowDialogOKCancel(msg,okFunc,cancelFunc)
    self:StartGame()
end

function UpdateScene:SetPercent(percent)

end

function UpdateScene:ClearWaitTips()
	LGameMsg.m_baseMsgWithOne:Change(LUIWaitAni.ClearWait, 0)
	LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function UpdateScene:ShowWaitTips(tips)
	local waitAniData = {
                            key = 0,
                            waitMsg = tips, 
                            autoClearTime = 0
                        }
    LGameMsg.m_baseMsgWithOne:Change(LUIWaitAni.ShowWait, waitAniData)
    LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
end

--[[
退出游戏
]]
function UpdateScene:ExitGame()
	AppDef.Director:endToLua()
end

function UpdateScene:HandleAssetsUpdateEvt(event)

	local function ExitGame()
		self:ExitGame()
	end

	local strInfo = ""
	local eventCode = event:getEventCode()
	print("HandleAssetsUpdateEvt:eventCode=",eventCode)
	if eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_NO_LOCAL_MANIFEST then
        print("No local manifest file found, skip assets update.")
		self:ConnectFail()
    elseif  eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_PROGRESSION then
    	if self.m_bIsCheckingVersion == true then
    		return
    	end
        local percent = event:getPercent()
        if assetId == cc.AssetsManagerExStatic.VERSION_ID then
            strInfo = string.format("Version file: %d%%", percent)
        elseif assetId == cc.AssetsManagerExStatic.MANIFEST_ID then
            strInfo = string.format("Manifest file: %d%%", percent)
        else
			self.m_curBytes = self.m_totalBytes*percent/100
			local cur_str = self.m_curBytes/1024/1024 > 0.02 and string.format("%.2fMB",self.m_curBytes/1024/1024) or string.format("%.2fKB",self.m_curBytes/1024)
            local total_str = self.m_totalBytes/1024/1024 > 0.02 and string.format("%.2fMB",self.m_totalBytes/1024/1024) or string.format("%.2fKB",self.m_totalBytes/1024)
			--strInfo = string.format("%s/%s", cur_str,total_str)
			strInfo = string.format(GUITips.Game_Dowloading_New_Res.."(%s/%s)", percent, cur_str, total_str)   --"资源下载中...%d%%"
        end
        -- progress:setString(strInfo)
        -- self.timer:setPercentage(percent)
        self:SetPercent(percent)
        --print("*******   PROGRESSION percent = ", percent)
        -- print(strInfo)
        if percent >= 100 then
        	self:ShowWaitTips(GUITips.Game_Update_UNZIPPING)
        else
        	self:ShowWaitTips(strInfo)
        end
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.UNZIPPING_START then
		self:ShowWaitTips(GUITips.Game_Update_UNZIPPING)
    elseif eventCode == cc.EventAssetsManagerEx.EventCode.NEW_VERSION_FOUND then
    	if self.m_bIsCheckingVersion == false then
    		return
    	end
    	-- print("********************ISSTART******************",event:getMessage())
    	--确认磁盘空间
    	self:ClearWaitTips()
		local availableSize = GamePlatform:GetStorageAvailableSize()
		
		--继续下载
    	local function DowloadCallback(target, pNode )
    		self.m_bIsCheckingVersion = false
			self.m_assetsMgr:update()
        end
        print("event:getMessage()=",event:getMessage())
        local bytes = tonumber(event:getMessage())
        if bytes == nil then
        	bytes = 0
        end
		print("availableSize:",(availableSize/1024/1024).."MB"," ,need:",(bytes*2/1024/1024).."MB")
		if availableSize < bytes*2 then
			--剩余空间不足2倍
			local function okFunc()
				self:ExitGame()
		    end
		    Utils:ShowDialogOKCancel(GUITips.Game_Update_NOTENOUGHSIZE,okFunc,okFunc)
		else
			--空间足够
			--WiFi情况直接下载
			local isWiFi = GamePlatform:IsWIFTConnect()	
			print("isWiFi=",isWiFi) 
			self.m_totalBytes = bytes
			if isWiFi then
				--[[
				wifi情况下不提示用户直接下载
				]]
				DowloadCallback()
			else
				local mnum = bytes/1024/1024 > 0.02 and string.format("%.2fMB",bytes/1024/1024) or string.format("%.2fKB",bytes/1024)
				local tipMsg = string.format(GUITips.Game_Update_Confirm,mnum)
				Utils:ShowDialogOKCancel(tipMsg,DowloadCallback,ExitGame)
			end
		end 
    elseif eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_DOWNLOAD_MANIFEST or 
           eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_PARSE_MANIFEST then
        print("Fail to download manifest file, update skipped.")
		self:ConnectFail()
    elseif eventCode == cc.EventAssetsManagerEx.EventCode.ALREADY_UP_TO_DATE or 
           eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_FINISHED then --finish 
            print("Update finished.",eventCode)
			local total_str = self.m_totalBytes/1024/1024 > 0.02 and string.format("%.2fMB",self.m_totalBytes/1024/1024) or string.format("%.2fKB",self.m_totalBytes/1024)
			
			if Utils:isIOSPlatform() then
				strInfo = GUITips.Game_Update_Finish_IOS    --"正在进入游戏！"
			else
				strInfo = GUITips.Game_Update_Finish    --"已经是最新版本，正在进入游戏！"
			end
			
			self:ShowWaitTips(strInfo)
			-- self.timer:setPercentage(100)
			self:SetPercent(100)
            local localManifest = self.m_assetsMgr:getLocalManifest()
			print("Update finished.version",localManifest:getVersion())
			-- local versionManifest = json.decode(localManifest:getVersionContent(),1)
			-- dump(versionManifest)
			local function func1()
				-- self.download_label:setString(strInfo)
				-- -- self.timer:setPercentage(100)
				self:SetPercent(100)
				-- self:removeChildByTag(self.waitImodAnimTag);
			end
			local function func2()
				self:StartGame(eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_FINISHED)
			end
			local action  = cc.Sequence:create(cc.CallFunc:create(func1),cc.CallFunc:create(func2))
			self:runAction(action)
    elseif eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_UPDATING then
            print("Asset ", event:getAssetId(), ", ", event:getMessage())
            self:ConnectFail()
    elseif eventCode == cc.EventAssetsManagerEx.EventCode.NEW_PACKAGE_FOUND then
            print("---------提示去应用商店下载----------")
            local localManifest = self.m_assetsMgr:getRemoteManifest()
            self:ClearWaitTips()
            self:DowloadNewPackage(localManifest:getPackageUrl())
    end
end

function UpdateScene:DowloadNewPackage(downloadURL)
    print("DowloadNewPackage",downloadURL)
    local function ExitGame()
        self:ExitGame()
    end

    local function DowloadCallback()
        cc.Application:getInstance():openURL(downloadURL)
        cc.Director:getInstance():endToLua() --暂时作为退出
    end

    Utils:ShowDialogOKCancel(GUITips.Game_Update_Package_Confirm,DowloadCallback,ExitGame)
end

function UpdateScene:StartGame()
	print("StartGame")
	self:UnRequireFrameScripts()

	local preLoadFile = require("View.GameScene")
    if AppDef.Director:getRunningScene() then
		AppDef.Director:replaceScene(preLoadFile:create())
	else
		AppDef.Director:runWithScene(preLoadFile:create())
	end
end


function UpdateScene:init()  
	require "LFrameRequire"
	require "Logic.LUILogic"
end


return UpdateScene