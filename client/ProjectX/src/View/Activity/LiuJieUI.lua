--[[
六界使者
]]
local LiuJieUI = LUIBase:New()
LiuJieUI.__index = LiuJieUI
LiuJieUI.IsHideInBattle = true

function LiuJieUI:New(userData)
    local o = LUIBase:New()
    setmetatable(o,LiuJieUI)  
    o:Init(userData)
    return o
end

--[[
注册UI消息
]]
function LiuJieUI:RegistMsgs()
end

function LiuJieUI:ProcessEvent(msg)
end

function LiuJieUI:Init(userData)
    self:RegistMsgs()
    self:InitData()
    self:InitViewSize()
    self:InitUIControl()
    self:AddSchedule()
    self:UpdateData(userData)
end

function LiuJieUI:UpdateData(userData)
    self.m_pList:removeAllItems()
    if userData == nil then
        return
    end
    for i = 1, #userData do
        self:ShowListCell(userData[i],i)
    end
end

function LiuJieUI:ShowListCell(userData,ind)
    local cell = self.m_pCell:clone()
    self.m_pList:pushBackCustomItem(cell)
    local bg = cell:getChildByName("Bg")
    if ind % 2 == 0 then
        bg:setVisible(true)
    else
        bg:setVisible(false)
    end
    local chooseBg = cell:getChildByName("ChooseBg")
    chooseBg:setVisible(false)

    local sceneLabel = cell:getChildByName("Sence")
    sceneLabel:setString(userData[2])
    local finish = cell:getChildByName("End")

    local killLabel = cell:getChildByName("Kill")
    killLabel:setString(userData[3] .. "/" .. userData[4])
    
    local function SelectBtnCallback(sender)
        local currMapSid = LRoleDataMgr.MyHeroInfo.sid
        if LRoleDataMgr.MyHeroInfo:IsTeam() == true and LRoleDataMgr.MyHeroInfo:IsLeader() == false
        and LRoleDataMgr.MyHeroInfo:IsTeamPause() == false then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_VAWL_TIP_MIN)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
            return
        end

        if currMapSid == userData[1] then
            Utils:ShowScrollTips(GUITips.RSI_Liujie_TIPS1)
            return
        end
        LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.AutoPathEvent.StopAutoPath)
        self:SendMsg(LGameMsg.m_cBaseMsg)

        LuaNetSendMsg:QueryChangeCity(userData[1])
        Utils:DeleteUI("Activity.LiuJieUI")
    end
    local btn = cell:getChildByName("GoBtn")
    btn:addClickEventListener(SelectBtnCallback)
    if tonumber(userData[3]) / tonumber(userData[4])==1 then
       btn:setVisible(false)
       finish:setVisible(true)
    end
end

function LiuJieUI:InitData()
    self.m_pCell = nil
    self.m_pList = nil
    self.m_pCloseBtn = nil
    self.m_refreshHandler = nil
end

function LiuJieUI:InitUIControl()

    local function CloseCallback(sender)
        Utils:DeleteUI("Activity.LiuJieUI")
    end
    local panel = self.m_pUILayer:getChildByName("LiujieUI")
    local bgPanel = panel:getChildByName("bg")

    self.m_pCloseBtn = bgPanel:getChildByName("Btn_close")
    self.m_pCloseBtn:addClickEventListener(CloseCallback)
    local descPanel = bgPanel:getChildByName("Desc")
    self.m_pCell = descPanel:getChildByName("Name")
    self.m_pList = descPanel:getChildByName("List")
end

function LiuJieUI:DeleteSchedule()
    if self.m_refreshHandler then
        
        Utils:unschedule(nil, self.m_refreshHandler)
        self.m_refreshHandler = nil
    end
end

function LiuJieUI:AddSchedule()
    self:DeleteSchedule()
    local function RefreshCallback(dt)
        LuaNetSendMsg:QueryXunChaShiInfo() --六界巡查
    end
    self.m_refreshHandler = Utils:schedule(nil, RefreshCallback, 5*60, false)
end

function LiuJieUI:InitViewSize()
    self:CreateUINode("csd/LiujieLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

function LiuJieUI:onExit()
    self:Destory()
    self:DeleteSchedule()
    self.m_pUILayer = nil
    self.m_pCell = nil
    self.m_pList = nil
    self.m_pCloseBtn = nil
end

function LiuJieUI:AutoMoveClick(sender)
    
end

return LiuJieUI