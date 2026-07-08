--[[
lua里面的游戏逻辑控制
]]

local jingjieMainUI = LUIBase:New()
jingjieMainUI.__index = jingjieMainUI
--local this = LTcpSocket
function jingjieMainUI:New(openTab)
	local o = LUIBase:New()
	setmetatable(o,jingjieMainUI)	
    o:Init(openTab)
	return o
end


function jingjieMainUI:Init(openTab)
   self.m_pUILayer = cc.Node:create()
   self.m_pSubLayer=nil
   self.m_curUIInd = 1
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
     LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.UI_Title_JingJie)
     self:SendMsg(LGameMsg.m_baseMsgWithOne)
	self.tabNames = {GUITips.UI_Title_JingJie}

	local function tabBtnClicked(ind)
		self:TabClicked(ind)
    end
	local tabValues = 
    {
        self.tabNames,
        tabBtnClicked
    }
    Utils:SendMsg(LUIFClassBgEvent.AddTabBtn, tabValues)
	Utils:SendMsg(LUIFClassBgEvent.SelectTab, self.m_curUIInd)
    local function closeCallback()
         LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "JingJie.jingjieMainUI")
         self:SendMsg(LGameMsg.m_initUIMsg)
     end
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    self:LoadSubUI()
end
function jingjieMainUI:LoadSubUI()
    local uiname ="View.JingJie.jingjieUI"-- {,"View.WorldMap.CurMapSubUI",}
    local delay = cc.DelayTime:create(0.1)
    local function loadSubUI()
        self.m_pSubLayer= require(uiname):New()
        self.m_pUILayer:addChild(self.m_pSubLayer.m_pUILayer)
    end
    local func = cc.CallFunc:create(loadSubUI)
    local sequence = cc.Sequence:create(delay, func)
    self.m_pUILayer:runAction(sequence)
end

function jingjieMainUI:TabClicked(ind)

end

function jingjieMainUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
end

function jingjieMainUI:InitTouchEvt()
    local panel = self.m_pUILayer:getChildByName("Main_UI")
    local roleBtn = panel:getChildByName("Head")
    local function RoleTouchCallback(sender)
    end
    roleBtn:addClickEventListener(RoleTouchCallback)
	self:MarkIntaractCObj(roleBtn)
end

-- function WorldMapMainUI:ShowVersion()
--     local panel = self.m_pUILayer:getChildByName("UI_Login")
--     local versionLabel = panel:getChildByName("Versions")


--     local url = "Manifest/ad"..GameSdk.ChannelId.."/version.manifest"
--     local str = cc.FileUtils:getInstance():getStringFromFile(url)
--     local versionManifest = json.decode(str,1)

--     local verStr = string.format(GUITips.Version, versionManifest["showVersion"])
--     versionLabel:setString(verStr)
-- end

return jingjieMainUI