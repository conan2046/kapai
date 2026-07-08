--[[
lua里面的游戏逻辑控制
]]

local OtherRoleMainUI = LUIBase:New()
OtherRoleMainUI.__index = OtherRoleMainUI
--local this = LTcpSocket
function OtherRoleMainUI:New(openTab)
	local o = LUIBase:New()
	setmetatable(o,OtherRoleMainUI)	
    o:Init(openTab)
	return o
end


function OtherRoleMainUI:Init(openTab)
    self.m_pUILayer = cc.Node:create()
    self.m_pSubLayer = {}
    self.m_curUIInd = 0
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    LRoleDataMgr.OtherHeroInfo.m_idx = 0

    -- local waitAniData = {
    --                         key = LuaNetCmd.MSG_ACC_LINEUP, 
    --                         waitMsg = GUITips.Login_Connect_Server, 
    --                         autoClearTime = 0
    --                     }
    LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.SetTitle, GUITips.UI_Title_Target_Role)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "OtherRole.OtherRoleMainUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    -- local function tabBtnClicked(ind)
    --     self:TabClicked(ind)
    -- end
    
    local tabValues = 
    {
        {
            GUITips.UI_Title_Target_Role_TabName1,
            GUITips.UI_Title_Target_Role_TabName2,
        },
        handler(self,OtherRoleMainUI.TabClicked)
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.AddTabBtn, tabValues)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.SelectTab, openTab)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    
    self:TabClicked(openTab)

    self:RegistMsgs()
end

function OtherRoleMainUI:RegistMsgs()
    self.msgIds = 
    {
        LUILogicEvent.ChangeOtherTab,
    }
    self:RegistSelf(self,self.msgIds)
end

function OtherRoleMainUI:ProcessEvent(msg)
    if msg.msgId == LUILogicEvent.ChangeOtherTab then
        self:ChangeOtherPetUI(msg.value)
    end
end

function OtherRoleMainUI:TabClicked(ind)
    if  self.m_curUIInd == ind or ind == 0 or ind > 2 then
        return false
    end
    if self.m_curUIInd > 0 then
        self:HideCurUI()
    end
    self.m_curUIInd = ind
    self:ShowCurUI()
    return true
end

function OtherRoleMainUI:HideCurUI()
    if self.m_pSubLayer[self.m_curUIInd] == nil then
        return
    end
    self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(false)
end

function OtherRoleMainUI:ShowCurUI()
    if self.m_pSubLayer[self.m_curUIInd] == nil then
        self:DelayLoadSubUI(self.m_curUIInd)
    else
        self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(true)
        self.m_pSubLayer[self.m_curUIInd]:OnEnter()
    end
    
end

function OtherRoleMainUI:DelayLoadSubUI(tabInd)
    local uinames = {
        "View.OtherRole.OtherRoleAttrUI",
        "View.OtherRole.OtherRolePetUI",
    }
    local ind = tabInd
    local delay = cc.DelayTime:create(0.1)
    local function loadSubUI()
        if self.m_curUIInd ~= ind or ind == 0 or ind > #uinames then
            return
        end
        self.m_pSubLayer[ind] = require(uinames[ind]):New()
        self.m_pUILayer:addChild(self.m_pSubLayer[ind].m_pUILayer)
    end
    local func = cc.CallFunc:create(loadSubUI)
    local sequence = cc.Sequence:create(delay, func)
    self.m_pUILayer:runAction(sequence)
end

function OtherRoleMainUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    LRoleDataMgr.OtherHeroInfo:Reset()
end

function OtherRoleMainUI:ChangeOtherPetUI(tab)
    if tab < 1 or tab > 2 then 
        return
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.SelectTab, tab)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    self:TabClicked(tab)
end

-- function OtherRoleMainUI:InitTouchEvt()
--     local panel = self.m_pUILayer:getChildByName("Main_UI")
--     local roleBtn = panel:getChildByName("Head")
--     local function RoleTouchCallback(sender)
--     end
--     roleBtn:addClickEventListener(RoleTouchCallback)
-- 	self:MarkIntaractCObj(roleBtn)
-- end

-- function OtherRoleMainUI:ShowVersion()
--     local panel = self.m_pUILayer:getChildByName("UI_Login")
--     local versionLabel = panel:getChildByName("Versions")


--     local url = "Manifest/ad"..GameSdk.ChannelId.."/version.manifest"
--     local str = cc.FileUtils:getInstance():getStringFromFile(url)
--     local versionManifest = json.decode(str,1)

--     local verStr = string.format(GUITips.Version, versionManifest["showVersion"])
--     versionLabel:setString(verStr)
-- end

return OtherRoleMainUI