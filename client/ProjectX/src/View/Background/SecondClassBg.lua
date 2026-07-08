--[[
lua里面的游戏逻辑控制
]]

local SecondClassBg = LUIBase:New()
SecondClassBg.__index = SecondClassBg
--local this = LTcpSocket
function SecondClassBg:New()
	local o = LUIBase:New()
	setmetatable(o,SecondClassBg)	
    o:Init()
	return o
end


function SecondClassBg:Init()
    --self.m_pNode = cc.Node:create()

    self.m_pUILayer = cc.CSLoader:createNode("csd/SecondLevelLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
   -- self:addChild(self.m_pUILayer)
   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitData()
    self:RegistMsgs()
    --self:ShowVersion()
end

function SecondClassBg:CloseCallback(sender)
    if self.m_pClassCallback then
        self.m_pClassCallback()
        self.m_pClassCallback = nil
    end
end

function SecondClassBg:InitData()
    local closeBtn = self.m_pUILayer:findChildByName("Popup/PopupBg/Btn_close");
    closeBtn:addClickEventListener(handler(self, SecondClassBg.CloseCallback))
	--self:MarkIntaractCObj(closeBtn)
    self.m_pCloseBtn = closeBtn

    self.m_pTitleLabel = self.m_pUILayer:findChildByName("Popup/PopupBg/Title/Title");
end

function SecondClassBg:SetBgVisible(visible, clearData)
    if clearData == nil then
        clearData = true
    end
    self.m_pUILayer:setVisible(visible)
    if visible == false and clearData == true then
        self.m_pClassCallback = nil
        self.m_pTitleLabel:setString("")
    end
end

--[[
注册UI消息
]]
function SecondClassBg:RegistMsgs()

    self.msgIds = 
    {
        LUISecondClassBgEvent.SetTitle,
        LUISecondClassBgEvent.SetCloseCallback,
        LUISecondClassBgEvent.RegisterCloseGuide,
    }
    self:RegistSelf(self,self.msgIds)
end

function SecondClassBg:ProcessEvent(msg)
    if msg.msgId == LUISecondClassBgEvent.SetTitle then
        self:SetTitle(msg.value)
    elseif msg.msgId == LUISecondClassBgEvent.SetCloseCallback then
        self:AddCloseBtnCallback(msg.value)
    elseif msg.msgId == LUISecondClassBgEvent.RegisterCloseGuide then
        self:RegisterCloseGuide(msg.value)
    end
end

function SecondClassBg:SetTitle(title)
    self.m_pTitleLabel:setString(title)
end

function SecondClassBg:AddCloseBtnCallback(func)
    self.m_pClassCallback = func
end

function SecondClassBg:onExit()
    self:Destory()
    self.m_pUILayer = nil
end

-- function SecondClassBg:ShowVersion()
--     local panel = self.m_pUILayer:getChildByName("UI_Login")
--     local versionLabel = panel:getChildByName("Versions")


--     local url = "Manifest/ad"..GameSdk.ChannelId.."/version.manifest"
--     local str = cc.FileUtils:getInstance():getStringFromFile(url)
--     local versionManifest = json.decode(str,1)

--     local verStr = string.format(GUITips.Version, versionManifest["showVersion"])
--     versionLabel:setString(verStr)
-- end

function SecondClassBg:RegisterCloseGuide(stepId)
    if self.m_pCloseBtn and stepId then
        Utils:RegisterGuide(stepId, self.m_pCloseBtn, handler(self, SecondClassBg.CloseCallback), nil, true)
    end
end

return SecondClassBg