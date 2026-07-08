--[[
lua里面的游戏逻辑控制
]]

local RoleMainUI = LUIBase:New()
RoleMainUI.__index = RoleMainUI
--local this = LTcpSocket
function RoleMainUI:New(openTab)
	local o = LUIBase:New()
	setmetatable(o,RoleMainUI)	
    o:Init(openTab)
	return o
end


function RoleMainUI:Init(openTab)
    self.Script = "Role.RoleMainUI"
    self.m_pUILayer = cc.Node:create()
    self.m_pSubLayer = {}
    self.m_curUIInd = 0
    self:InitTouchEvt()

    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.UI_Title_Role_Attr)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local function tabBtnClicked(ind)
        self:TabClicked(ind)
    end
    local tabValues = 
    {
        {
            GUITips.UI_Title_Role_TabName1,
            --GUITips.UI_Title_Role_TabName2,
            GUITips.UI_Title_Role_TabName3,
        },
        tabBtnClicked
    }
    self.m_tabNum = 3
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.AddTabBtn, tabValues)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, openTab)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    self:TabClicked(openTab)

    self:RegistMsgs()
    LuaNetSendMsg:SendXunBaoInfoReq()
end

function RoleMainUI:TabClicked(ind)
    if  self.m_curUIInd == ind then
        return
    end
    local function goBack(index)
        LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, index)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end
    if ind == 3 and Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_KAPAI_TITLE) then
        goBack(self.m_curUIInd)
        return
    end
    if self.m_curUIInd ~= 0 then
         self:HideCurUI()
    end
     self.m_curUIInd = ind
     self:ShowCurUI()
end

function RoleMainUI:HideCurUI()
    if self.m_pSubLayer[self.m_curUIInd] == nil then
        return
    end
    self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(false)
end

function RoleMainUI:ShowCurUI()
    
     if self.m_pSubLayer[self.m_curUIInd] == nil then
        self:DelayLoadSubUI(self.m_curUIInd)
    else
        self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(true)
        if self.m_curUIInd == 4 then
            local itemGridNum = self.m_pSubLayer[self.m_curUIInd].m_itemGridNum
            local petGridNum = self.m_pSubLayer[self.m_curUIInd].m_petGridNum
            if itemGridNum == 0 and petGridNum == 0 then        
                Utils:ShowScrollTips(GUITips.UI_Resolve_Tip_1)
            end
        end
    end
    -- LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips["UI_Title_Role_TabName"..self.m_curUIInd])
    -- self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function RoleMainUI:DelayLoadSubUI(tabInd)
    --local uinames = {"View.Role.RoleAttrUI","View.Role.RoleTitleUI","View.Setting.SettingUI"}
    local uinames = {"View.Role.RoleAttrUI","View.Setting.SettingUI"}
    local ind = tabInd
    local delay = cc.DelayTime:create(0.1)
    local function loadSubUI()
        if ind == nil or self.m_curUIInd ~= ind or ind == 0 or ind > #uinames then
            return
        end
        self.m_pSubLayer[ind] = require(uinames[ind]):New()
        self.m_pUILayer:addChild(self.m_pSubLayer[ind].m_pUILayer)
    end
    local func = cc.CallFunc:create(loadSubUI)
    local sequence = cc.Sequence:create(delay, func)
    self.m_pUILayer:runAction(sequence)
end

function RoleMainUI:onExit()
    self:Destory()
    --local uinames = {"View.Role.RoleAttrUI","View.Role.RoleTitleUI","View.Setting.SettingUI"}
    local uinames = {"View.Role.RoleAttrUI","View.Setting.SettingUI"}
    for i = 1, #uinames do
        --package.loaded[uinames[i]] = nil
        self.m_pSubLayer[i] = nil
    end
    self.m_pSubLayer = nil
    self.m_pUILayer = nil
    
end

function RoleMainUI:InitTouchEvt()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    local function closeCallback()
        LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, self.Script)
        self:SendMsg(LGameMsg.m_deleteUIMsg)
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

-- function RoleMainUI:ShowVersion()
--     local panel = self.m_pUILayer:getChildByName("UI_Login")
--     local versionLabel = panel:getChildByName("Versions")


--     local url = "Manifest/ad"..GameSdk.ChannelId.."/version.manifest"
--     local str = cc.FileUtils:getInstance():getStringFromFile(url)
--     local versionManifest = json.decode(str,1)

--     local verStr = string.format(GUITips.Version, versionManifest["showVersion"])
--     versionLabel:setString(verStr)
-- end

--[[
注册UI消息
]]
function RoleMainUI:RegistMsgs()
    self.msgIds =
    {
        LUIBagEvent.SelectTab,--切页签
    }
    self:RegistSelf(self, self.msgIds)
end

function RoleMainUI:ProcessEvent(msg)
    if msg.msgId == LUIBagEvent.SelectTab then
        local openTab = msg.value
        if openTab == nil or openTab > self.m_tabNum then
           return
        end
        
        LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, openTab)
        self:SendMsg(LGameMsg.m_baseMsgWithOne) 
        self:TabClicked(openTab)               
    end
end
return RoleMainUI