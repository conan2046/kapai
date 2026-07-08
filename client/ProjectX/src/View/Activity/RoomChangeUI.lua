local RoomChangeUI = LUIBase:New()
RoomChangeUI.__index = RoomChangeUI

local buffer = {
    [AppDef.SceneType.MSI_KUNLUN] = true,
    [AppDef.SceneType.MSI_LUNDAO] = true,
    [AppDef.SceneType.MSI_SHENJIEMIJING] = true,
}

function RoomChangeUI:New()
    local o = {}
    setmetatable(o,RoomChangeUI)  
    o:Init()
    return o
end

--[[
注册UI消息
]]
function RoomChangeUI:RegistMsgs()
    self.msgIds = 
    {
        LUIActivityEvent.RefreshKunlunRoom,
    }
    self:RegistSelf(self,self.msgIds)
end

function RoomChangeUI:ProcessEvent(msg)
    if msg.msgId == LUIActivityEvent.RefreshKunlunRoom then
        self:UpdateRoomView(msg.value)
    end
end

function RoomChangeUI:Init()
    self.Script = "Activity.RoomChangeUI"
    self:RegistMsgs()
    self.m_pUILayer = cc.CSLoader:createNode("csd/RoomChangeLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitData()
    self:AddTouchEvt()

    local sceneType = LRoleDataMgr.MyHeroInfo.SceneType
    if sceneType == AppDef.SceneType.MSI_KUNLUN then
        LuaNetSendMsg:QueryKunLunShanRoomInfo()
    elseif sceneType == AppDef.SceneType.MSI_FISHROOM then
        LuaNetSendMsg:QueryFishingInfo(1)
    elseif sceneType == AppDef.SceneType.MSI_LUNDAO then
        LuaNetSendMsg:QueryLunDaoInfo(4)
    elseif sceneType == AppDef.SceneType.MSI_SHENJIEMIJING then
        LuaNetSendMsg:QueryMsBossRoomInfo()
    else
        self:RemoveUI()
    end
end

function RoomChangeUI:onExit()
    self:Destory()
    self.Script = nil
    self.m_pUILayer = nil
    self.m_panelUI = nil
    self.m_BgUI= nil
    self.m_roomList = nil
    self.m_roomCell = nil
    self.m_pCloseBtn = nil
end

function RoomChangeUI:InitData()
    self.m_panelUI = self.m_pUILayer:getChildByName("Popup")
    self.m_BgUI= self.m_panelUI:getChildByName("bg")
    self.m_roomList = self.m_panelUI:getChildByName("ListView")
    self.m_roomCell = self.m_panelUI:getChildByName("Item")
    for i=1,4 do
        self.m_roomCell:getChildByName("Button_"..i):setVisible(false)
    end
    self.m_pCloseBtn = self.m_BgUI:getChildByName("Btn_close")
end

function RoomChangeUI:AddTouchEvt()
    -- 关闭
    local function CloseCallback(sender)
        self:RemoveUI()
    end
    self.m_pCloseBtn:addClickEventListener(CloseCallback)
	self:MarkIntaractCObj(self.m_pCloseBtn)
end

function RoomChangeUI:UpdateRoomView(list)
    self.m_roomList:removeAllItems()
    
    local function EnterCallback(sender)
        if LRoleDataMgr.MyHeroInfo:IsTeam() and (not LRoleDataMgr.MyHeroInfo:IsLeader()) then
            Utils:ShowScrollTips(GUITips.RSI_XLXY_TIPS_2)
            return
        end
        local tag = sender:getTag()
        local sceneType = LRoleDataMgr.MyHeroInfo.SceneType
        if sceneType == AppDef.SceneType.MSI_KUNLUN then
            if sender.userObject then
                Utils:ShowScrollTips(GUITips.REI_TIPS_KUNLUNSHAN_ROOMFULL)
                return
            end
            LuaNetSendMsg:QueryEnterKunlunRoom(tag)
        elseif sceneType == AppDef.SceneType.MSI_FISHROOM then
            LuaNetSendMsg:QueryFishingInfo(2, tag)
        elseif sceneType == AppDef.SceneType.MSI_LUNDAO then
            LuaNetSendMsg:QueryLunDaoInfo(5, tag)
        elseif sceneType == AppDef.SceneType.MSI_SHENJIEMIJING then
            LuaNetSendMsg:QueryMsBossChangeRoom(tag)
        end
    end

    local rooms = list
    local cell = nil
    for k,room in pairs(rooms) do
        local idx = math.max(((k-1) % 4) + 1, 1)

        if idx == 1 then
            cell = self.m_roomCell:clone()
            cell:setVisible(true)
            self.m_roomList:pushBackCustomItem(cell)
        end
        local button = cell:getChildByName("Button_"..idx)
        if button == nil then
            return
        end
        local nameStr = string.format("%d号房", room.roomID)
        button:getChildByName("Name"):setString(nameStr)
        local numStr = string.format("%d/%d", room.peopleNum, room.maxNum)
        button:getChildByName("Num"):setString(numStr)
        button:setVisible(true)
        button:setTag(room.roomID)

        --策划说绿点代表自己所在房间
        local state = button:getChildByName("State")
        state:setVisible(false)
        local sceneType = LRoleDataMgr.MyHeroInfo.SceneType
        
        if sceneType == AppDef.SceneType.MSI_FISHROOM then
            if LRoleDataMgr.FishRoomID and LRoleDataMgr.FishRoomID == k then
                button:setBright(true)
                state:setVisible(true)
            end
        elseif buffer and buffer[sceneType] then
            if LRoleDataMgr.m_kunlunShanData.m_curRoom == k then
                button:setBright(true)
                state:setVisible(true)
            end
        end
        button:setTag(k)
        button:addClickEventListener(EnterCallback)
		self:MarkIntaractCObj(button)
        button.userObject = room.peopleNum >= room.maxNum

    end
end

return RoomChangeUI