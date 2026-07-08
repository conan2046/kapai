--[[
lua里面的游戏逻辑控制
]]


local FuBenMainUI = LUIBase:New()
FuBenMainUI.__index = FuBenMainUI
--local this = LTcpSocket
function FuBenMainUI:New(openTab)
    local o = LUIBase:New()
    setmetatable(o,FuBenMainUI)   
    o:Init(openTab)
    return o
end


function FuBenMainUI:Init(openTab)

   self.m_pUILayer = cc.Node:create()
   self.m_pSubLayer = {}
   self.m_curUIInd = 0
   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
   
    if  LRoleDataMgr.m_bIsCrossServer==true then 
       LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.UI_Title_KuafuWorldMap)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    else

      LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.UI_Title_WorldMap)
      self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end

   
    local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "FuBenMap.FuBenMainUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local function tabBtnClicked(ind)
        self:TabClicked(ind)
    end

    local tabValues = 
    {
        {GUITips.UI_Title_WorldMap_TabName1,GUITips.UI_Title_WorldMap_TabName2},
        tabBtnClicked
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.AddTabBtn, tabValues)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local ind = 1
    if openTab ~= nil and openTab > 0 then
        ind = openTab
    end

    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, ind)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    self:TabClicked(ind)
end

function FuBenMainUI:TabClicked(ind)

    local function goBack(index)
        LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, index)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)

        Utils:ShowScrollTips(GUITips.RSI_MAP_TIPS_1)
    end

    if self.m_curUIInd == ind then
        return
    end
    local currMapSid = LRoleDataMgr.MyHeroInfo.sid
    if currMapSid == 47 and ind == 1 then
        goBack(self.m_curUIInd)
        return
    end    

    if self.m_curUIInd ~= 0 then
     self:HideCurUI()
    end
     self.m_curUIInd = ind
  
     self:ShowCurUI()
end

function FuBenMainUI:HideCurUI()
    if self.m_pSubLayer[self.m_curUIInd] == nil then
        return
    end
    self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(false)
end

function FuBenMainUI:ShowCurUI()
    
     if self.m_pSubLayer[self.m_curUIInd] == nil then
        self:DelayLoadSubUI(self.m_curUIInd)
      
    else
        self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(true)
    end
    
end

function FuBenMainUI:DelayLoadSubUI(tabInd)
    local uinames = {"View.FuBenMap.NormalFuBenUI", "View.FuBenMap.DailyFuBenUI"}
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

function FuBenMainUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    local uinames = {"View.FuBenMap.NormalFuBenUI","View.FuBenMap.DailyFuBenUI",}
    for i = 1,2 do
        --package.loaded[uinames[i]] = nil
        self.m_pSubLayer[i] = nil
    end
    self.m_pSubLayer = nil
    self.m_curUIInd = nil
end

return FuBenMainUI