--[[
lua里面的游戏逻辑控制
]]

local ArtifactMainUI = LUIBase:New()
ArtifactMainUI.__index = ArtifactMainUI
--local this = LTcpSocket
function ArtifactMainUI:New()
	local o = LUIBase:New()
	setmetatable(o,ArtifactMainUI)	
    o:Init()
	return o
end


function ArtifactMainUI:Init()
   self.m_pUILayer = cc.Node:create()
   self.m_pSubLayer = {}
   self.m_curUIInd = 0
   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.UI_Title_Artifact)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Artifact.ArtifactMainUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local function tabBtnClicked(ind)
        self:TabClicked(ind)
    end
    local tabValues = 
    {
        {GUITips.UI_Title_Artifact_TabName1,GUITips.UI_Title_Artifact_TabName2},
        tabBtnClicked
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.AddTabBtn, tabValues)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, 1)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    self:TabClicked(1)

    --请求神器培养信息
    LuaNetSendMsg:QueryShenQiInfoNew(3)
end

function ArtifactMainUI:TabClicked(ind)
    if  self.m_curUIInd == ind then
        return
    end

    if ind == 2 and Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SQJINJIE) then
        LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, self.m_curUIInd)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
        return
    end
    if self.m_curUIInd ~= 0 then
     self:HideCurUI()
    end
     self.m_curUIInd = ind
     self:ShowCurUI()
end

function ArtifactMainUI:HideCurUI()
    if self.m_pSubLayer[self.m_curUIInd] == nil then
        return
    end
    self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(false)
end

function ArtifactMainUI:ShowCurUI()
    
     if self.m_pSubLayer[self.m_curUIInd] == nil then
        self:DelayLoadSubUI(self.m_curUIInd)
    else
        self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(true)
    end
    
end

function ArtifactMainUI:DelayLoadSubUI(tabInd)
    local uinames = {"View.Artifact.ArtifactUI","View.Artifact.ArtifactDevelopUI"}
    local ind = tabInd
    local delay = cc.DelayTime:create(0.1)
    local function loadSubUI()
        if self.m_curUIInd ~= ind then
            return
        end
        self.m_pSubLayer[ind] = require(uinames[ind]):New()
        self.m_pUILayer:addChild(self.m_pSubLayer[ind].m_pUILayer)
    end
    local func = cc.CallFunc:create(loadSubUI)
    local sequence = cc.Sequence:create(delay, func)
    self.m_pUILayer:runAction(sequence)
end

function ArtifactMainUI:onExit()
    self.m_pUILayer = nil
    LArtifactUIDataMgr:Free()--神器培养信息释放
end


return ArtifactMainUI