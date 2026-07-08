package.path = package.path..";src/?.lua";

cc.FileUtils:getInstance():setPopupNotify(false)
local writablePath = cc.FileUtils:getInstance():getWritablePath()
print("writablePath11:",writablePath)
--new
local searchpaths = cc.FileUtils:getInstance():getSearchPaths()
for k,v in pairs(searchpaths) do
	print("Origin_searchPath:",v)
end
--cc.FileUtils:getInstance():addSearchPath(writablePath.."package/",true)
cc.FileUtils:getInstance():addSearchPath(writablePath.."package/src/",true)
cc.FileUtils:getInstance():addSearchPath(writablePath.."package/res/",true)

cc.FileUtils:getInstance():addSearchPath("src/")
cc.FileUtils:getInstance():addSearchPath("res/")


require "config"
require "cocos.init"
CC_COCOS_SAVE_SCRIPT()



local function main()
	collectgarbage("collect")
    -- avoid memory leak
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 5000)
	math.randomseed(os.time())
	-- require "LCommonRequire"
	local sceneFile = require("View.LogoScene")
	local gsceme = sceneFile:create()
	--g_pGameScene = scene:create()
	if cc.Director:getInstance():getRunningScene() then
		cc.Director:getInstance():replaceScene(gsceme)
	else
		cc.Director:getInstance():runWithScene(gsceme)
	end

	-- local reader = creator.CreatorReader:createWithFilename("creator/testScene.ccreator")
	-- reader:setup()
	-- local scene = reader:getSceneGraph()
	-- if cc.Director:getInstance():getRunningScene() then
	-- 	cc.Director:getInstance():replaceScene(scene)
	-- else
	-- 	cc.Director:getInstance():runWithScene(scene)
	-- end

	-- --local resourceNode_ = cc.CSLoader:createNode("creator/New Layout")
	-- -- local resourceNode_ = cc.loader:loadRes("creator/New Layout")
	-- -- scene:addChild(resourceNode_)
	

	-- local m_pUILayer = cc.CSLoader:createNode("csd/loginLayer.csb")
 --    local frameSize = cc.Director:getInstance():getVisibleSize()
 --    m_pUILayer:setContentSize(frameSize)
 --    ccui.Helper:doLayout(m_pUILayer)
 --    gsceme:addChild(m_pUILayer)
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end
