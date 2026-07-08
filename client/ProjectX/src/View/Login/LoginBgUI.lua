--[[
lua里面的游戏逻辑控制
]]

local LoginBgUI = LUIBase:New()
LoginBgUI.__index = LoginBgUI
--local this = LTcpSocket
function LoginBgUI:New()
	local o = LUIBase:New()
	setmetatable(o,LoginBgUI)	
    o:Init()
	return o
end


function LoginBgUI:Init()
    --self.m_pNode = cc.Node:create()
    local csbPath = "csd/Login/LoginBgLayer.csb";
    -- if GameSdk.AppId == AppDef.APPID_JIANZHENGZHUXIAN then
    --     csbPath = "csd/LoginBgLayer2.csb";
    -- end
    self.m_pUILayer = cc.CSLoader:createNode(csbPath)
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
   -- self:addChild(self.m_pUILayer)
   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    local panel = self.m_pUILayer:getChildByName("UI_Login")
    local bg = panel:getChildByName("Bg")
    local bgSize = bg:getContentSize()
    local size = AppDef.frameSize
    local scaleRateX =  size.width / bgSize.width
    local scaleRateY = size.height / bgSize.height
    local radio = (scaleRateX > scaleRateY) and scaleRateX or scaleRateY;
    bg:setScale(radio)
	
	local effect = panel:getChildByName("effect_chuangjue_1")
	local effcet = self:SetEffect()
    effcet:setName("effcet") 
    effect:addChild(effcet)

    local Logo = panel:getChildByName("Logo")
    if GameSdk.AppId == AppDef.APPID_JIANZHENGZHUXIAN then
        Utils:CreateSpriteWithPath(panel, Logo, "res/UI/ui_login/ui_logo_jzzs.png")
        bg:loadTexture("res/UI/ui_login/bg_jzzs.jpg", ccui.TextureResType.localType)
    end
--    print("getChildByName ----------------------------", scaleRate)

    self:ShowVersion()
end

function LoginBgUI:SetEffect()
    local bgAnim = "res2/animation/effect_chuangjue_1"
    local m_pBgAni = ImodAnim:create()
    m_pBgAni:initAnimWithNameSync(bgAnim)
    m_pBgAni:PlayActionRepeat(0)
    m_pBgAni:setScale(scale or 1)
    return m_pBgAni
end


function LoginBgUI:onExit()
    self.m_pUILayer = nil
end

function LoginBgUI:UpdateUserData()
    self:ShowVersion()
end

function LoginBgUI:ShowVersion()
    local panel = self.m_pUILayer:getChildByName("UI_Login")
    local versionLabel = panel:getChildByName("Versions")
    if GameSdk:IsSDKUser() then
        versionLabel:setString(GameSdk.ShowVersion)
        return
    end
    


    -- local url = "Manifest/ad"..GameSdk.ChannelId.."/project.manifest"
    -- local str = cc.FileUtils:getInstance():getStringFromFile(url)
    -- local versionManifest = json.decode(str,1)

    -- local verStr = string.format(GUITips.Version, versionManifest["showVersion"])
    local verStr = GameSdk.ShowVersion
    versionLabel:setString(verStr)
    --versionLabel:setString("SVN版本号:" .. 5426)
end

return LoginBgUI