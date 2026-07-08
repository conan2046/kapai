--[[
lua里面的游戏逻辑控制
]]

local PetArchiveMainUI = LUIBase:New()
PetArchiveMainUI.__index = PetArchiveMainUI
--local this = LTcpSocket
function PetArchiveMainUI:New(openTab)
	local o = LUIBase:New()
	setmetatable(o,PetArchiveMainUI)	
    o:Init(openTab)
	return o
end


function PetArchiveMainUI:Init(openTab)
   self.m_pUILayer = cc.Node:create()
   self.m_pSubLayer = {}
   self.m_curUIInd = 0
   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

--    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.UI_Title_PetArchive)
--    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Pet.PetArchiveMainUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local function tabBtnClicked(ind)
        self:TabClicked(ind)
    end
    local tabValues = 
    {
        {
            GUITips.UI_PetArchive_TabName1,GUITips.UI_PetArchive_TabName2
        },
        tabBtnClicked
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.AddTabBtn, tabValues)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, openTab)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    self:TabClicked(openTab)

end

function PetArchiveMainUI:TabClicked(ind)
    if  self.m_curUIInd == ind then
        return
    end
    if self.m_curUIInd ~= 0 then
     self:HideCurUI()
    end
     self.m_curUIInd = ind
     self:ShowCurUI()
end

function PetArchiveMainUI:HideCurUI()
    if self.m_pSubLayer[self.m_curUIInd] == nil then
        return
    end
    self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(false)
end

function PetArchiveMainUI:ShowCurUI()
    
     if self.m_pSubLayer[self.m_curUIInd] == nil then
        self:DelayLoadSubUI(self.m_curUIInd)
    else
        self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(true)
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips["UI_Title_PetArchive_"..self.m_curUIInd])
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function PetArchiveMainUI:DelayLoadSubUI(tabInd)
    local uinames = {"View.Pet.PetArchiveSubUI","View.Pet.PetArchiveFormationSubUI"}
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

function PetArchiveMainUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end


return PetArchiveMainUI