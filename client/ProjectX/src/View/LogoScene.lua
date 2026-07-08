--公司logo

local LogoScene = class("LogoScene", cc.Scene)

function LogoScene:create()
    local scene = LogoScene.new()
    return scene
end

function LogoScene:ctor()
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
    
    self:init()
end

function LogoScene:onEnter()

end

function LogoScene:onExit()
    self:unregisterScriptHandler()
end

function LogoScene:onEnterTransitionFinish()

end

function LogoScene:onExitTransitionStart()

end

function LogoScene:onCleanup()

end

function LogoScene:init()  
    
	local CC_WINSIZE = cc.Director:getInstance():getVisibleSize()
	local spImg = cc.Sprite:create("res/UI/ui_login/bg3.png")
    spImg:setAnchorPoint(ccp(0.5,0.5));
    spImg:setPosition(ccp(CC_WINSIZE.width/2, CC_WINSIZE.height/2));
	local sradiox = CC_WINSIZE.width/spImg:getContentSize().width;
	local sradioy = CC_WINSIZE.height/spImg:getContentSize().height;
	local radio = (sradiox > sradioy) and sradiox or sradioy;
	spImg:setScale(radio);
	self:addChild(spImg)
  
    spImg:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), cc.CallFunc:create(function() 
        local app = cc.Application:getInstance()
        local target = app:getTargetPlatform()

        if target == cc.PLATFORM_OS_WINDOWS then
            --[[
            模拟器环境不检查热更
            ]]
            local preLoadFile = require("View.GameScene")
            if cc.Director:getInstance():getRunningScene() then
                cc.Director:getInstance():replaceScene(preLoadFile:create())
            else
                cc.Director:getInstance():runWithScene(preLoadFile:create())
            end
        else
            local preLoadFile = require("View.UpdateScene")
            if cc.Director:getInstance():getRunningScene() then
                cc.Director:getInstance():replaceScene(preLoadFile:create())
            else
                cc.Director:getInstance():runWithScene(preLoadFile:create())
            end
        end
        
    end)))
end

function LogoScene:G_Resolution_BgImage(bg, layerSize, autoscale)   --根据适配方案，调整代码创建的背景图片
    if CC_DESIGN_RESOLUTION then
        --local view = cc.Director:getInstance():getOpenGLView()
        local framesize = layerSize  --view:getFrameSize()
        local bgSize = bg:getContentSize()
        local scaleX = framesize.width/bgSize.width
        local scaleY = framesize.height/bgSize.height

        if autoscale == "FIXED_WIDTH" then
            scaleY = scaleX
        elseif autoscale == "FIXED_HEIGHT" then
            scaleX = scaleY
        elseif autoscale == "NO_BORDER" then
            scaleX = math.max(scaleX, scaleY)
            scaleY = math.max(scaleX, scaleY)
        elseif autoscale == "SHOW_ALL" then
            scaleX = math.min(scaleX, scaleY)
            scaleY = math.min(scaleX, scaleY)
        else
            G_Log_Warning(string.format("display - invalid r.autoscale \"%s\"", autoscale))
            return 
        end

        --G_Log_Info("G_Resolution_BgImage scaleX = %0.2f, scaleY = %0.2f", scaleX, scaleY)
        bg:setContentSize(cc.size(scaleX*bgSize.width, scaleY*bgSize.height))
    end
end

return LogoScene
