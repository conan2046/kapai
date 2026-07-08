--公司logo

local GameScene = class("GameScene", cc.Scene)

function GameScene:create()
    local scene = GameScene.new()
    return scene
end

function GameScene:ctor()
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
    
    local CC_WINSIZE = cc.Director:getInstance():getVisibleSize()
    --加载信息
    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()
    if target == cc.PLATFORM_OS_WINDOWS then
        require  "Common.Tips"
        require  "core.AppDef"
        require  "core.GameSdk"
        GameSdk:InitGameVersion()
    end

    local strPath
    if GameSdk.AppId == AppDef.APPID_JIANZHENGZHUXIAN then
        strPath = "res/UI/ui_login/bg_jzzs.jpg"
    else
        --strPath = "res/UI/ui_login/bg.jpg"
		strPath = "res/UI/ui_login/bg_jzzs.jpg"
    end

    self.m_pBgImg =  cc.Sprite:create(strPath)

    self.m_pBgImg:setAnchorPoint(ccp(0.5,0.5));
    self.m_pBgImg:setPosition(ccp(CC_WINSIZE.width/2, CC_WINSIZE.height/2));
    local sradiox = CC_WINSIZE.width/self.m_pBgImg:getContentSize().width;
    local sradioy = CC_WINSIZE.height/self.m_pBgImg:getContentSize().height;
    local radio = (sradiox > sradioy) and sradiox or sradioy;
    self.m_pBgImg:setScale(radio);
    self:addChild(self.m_pBgImg)

    local bgImage = "res/UI/ui_login/tipbg.png"
    local bkgSpr = cc.Scale9Sprite:create(bgImage)
    bkgSpr:setPosition(ccp(CC_WINSIZE.width/2, CC_WINSIZE.height/2))
    self:addChild(bkgSpr)

    local LogeTips = cc.Label:createWithSystemFont("上仙，封神世界正在创建中，片刻即好...", "MicrosoftArial.ttf", 24)

    bkgSpr:setContentSize(cc.size(LogeTips:getContentSize().width + 100, bkgSpr:getContentSize().height))
    LogeTips:setColor(cc.c3b(255, 255, 255))
    LogeTips:setPosition(ccp(bkgSpr:getContentSize().width/2, bkgSpr:getContentSize().height/2))
    bkgSpr:addChild(LogeTips)
end

function GameScene:onEnter()
end

function GameScene:onExit()

end

function GameScene:onEnterTransitionFinish()
    self:init()
end

function GameScene:onExitTransitionStart()

end

function GameScene:onCleanup()

end

--[[
预加载一些常用资源
]]
function GameScene:PreloadCommonRes()

    local imgs = 
    {
        "csd/Plist/ui_loginPlist",
        "csd/Plist/ui_commonPlist",
        "csd/Plist/ui_mainPlist",
        "csd/Plist/ui_zhandouPlist",
        "csd/Plist/ui_huobi",
		"csd/Plist/ui_wanfaPlist",
    }
    local ind = 1
    local textureCache = cc.Director:getInstance():getTextureCache()
    
    local curLoadImg
    local function LoadImg()

        local function callback(texture)
            if texture then
                cc.SpriteFrameCache:getInstance():addSpriteFrames(curLoadImg .. ".plist", curLoadImg .. ".png")
            end
            if #imgs > 0 then
                LoadImg()
            else
                self:LoadCommonResComplete()
            end
        end
        curLoadImg = table.remove(imgs,1)
        textureCache:addImageAsync(curLoadImg .. ".png", callback) 
    end

    LoadImg()
    -- for i = 1, #imgs do
    --      textureCache:addImageAsync(imgs[i], callback) 
    -- end
end

function GameScene:LoadCommonResComplete(mapnme)
   self:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(function() 
                    self:GameStart()
                        end)
                ))
end

function GameScene:init()  
    self:InitGameFrame()

    self:PreloadCommonRes()
    
    
    
    
end

function GameScene:InitGameFrame()
    --MsgCenter:New()

     GameMain:InitGameMain()
    --local gameMain = GameMain:New()

end

function GameScene:GameStart()

    local loadFunc = require "LCommonRequire"
    -- local old = print
    -- print = function(...)
    --     Utils:Debug("print-->")
    --     old(...)
    -- end

    local function LoadCommonScriptsCallback()
        GameSdk:InitGameVersion()
        AppDef.CurScene = self
        local requireArr = {
            "Frame.Net.LTCPSocket",
            "Logic.LUILogic",
            "Logic.LResLogic",
            "Logic.LSoundLogic",
            "Logic.LBattleLogic",
            "Logic.LGameLogic",
        }
        local scheduler = nil 
        local function requireCallback(dt)
            if #requireArr > 0 then
                require(requireArr[1])
                table.remove(requireArr,1)
            else
                AppDef.Director:getScheduler():unscheduleScriptEntry(scheduler)
                scheduler = nil
                self.m_pBgImg:removeFromParent()
                self.m_pBgImg = nil
            end
        end 

        scheduler = AppDef.Director:getScheduler():scheduleScriptFunc(requireCallback, 0, false)
    end
    loadFunc(LoadCommonScriptsCallback)


    -- self:runAction(cc.Sequence:create(cc.DelayTime:create(0.9), cc.CallFunc:create(function() 
    --                 self.m_pBgImg:removeFromParent()
    --                 self.m_pBgImg = nil
    --                     require "Frame.Net.LTCPSocket"
    --                     require "Logic.LGameLogic"
    --                     end)
    --             ))
   

    -- for k,v in pairs(package.loaded) do
    --     print("加载的脚本",k,v)
    -- end
    -- local function LuaGameStart()
    --     require "Frame.Net.LTCPSocket"
    --     require "Logic.LGameLogic"
    -- end

    -- Utils:DelayToCallFunc(self,0.1,LuaGameStart)
    
    -- require "Data.XML.LXMLCenter"


    

   
end

return GameScene
