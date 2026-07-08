local LGetPetWingManager = LUIBase:New()
LGetPetWingManager.__index = LGetPetWingManager

-------------------------------------
function LGetPetWingManager:New(data)
    local o = {}
    setmetatable(o, LGetPetWingManager)
    o:Init(data)
    return o
end
-------------------------------------
function LGetPetWingManager:Init(data)
    self.Script = "LuckyDraw.LGetPetWingManager"
    ------------------------------------------------
    self.m_isShowing = false
    self.m_timestamp = 0
    ------------------------------------------------
    self.m_dataVec = {} --获得的列表
    ------------------------------------------------
    self:RegistMsgs()
    self:InitViewSize()
    self:setCloseCallback()
    -----------------------------------------------
    self:UpdateUserData(data)
end
-------------------------------------
function LGetPetWingManager:RegistMsgs()
    self.msgIds = {
        LUIGetPetWingEvent.CheckNext
    }
    self:RegistSelf(self, self.msgIds)
end
-------------------------------------
function LGetPetWingManager:ProcessEvent(msg)
    if msg.msgId == LUIGetPetWingEvent.CheckNext then
        self.m_isShowing = false
        self:checkNext()
    end
end
-------------------------------------
function LGetPetWingManager:onExit()
    self:Destory()
    self.Script = nil
    self.m_pUILayer = nil
    Utils:FreeTable(self.m_dataVec)
    self.m_dataVec = nil
    self.m_isShowing = nil
    self.m_timestamp = nil

end
-------------------------------------
function LGetPetWingManager:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
-------------------------------------
function LGetPetWingManager:InitViewSize()
    self.m_pUILayer = cc.Node:create()
end
-------------------------------------
function LGetPetWingManager:UpdateUserData(data)
    if data == nil then
        return
    end
    table.insert(self.m_dataVec, data)

    self:UpdateShowingState()
    if not self.m_isShowing then
        self:checkNext()
    end
end
--[[
检查显示下一个
]]
function LGetPetWingManager:checkNext()
    self:UpdateShowingState()
    if self.m_isShowing then
        return
    end
    if #self.m_dataVec == 0 then
        return
    end
    local data = self.m_dataVec[1]
    
    if data then
        local isNext = false
        if data.type == AppDef.AwrdItem.AWRD_ITEM_PET then
            -- Utils:Debug("show the track path = 111111111")
            -- print("LGetPetWingManager:checkNext 111111111111111111111111 ==================== 1111111111 >", PetkaPaiManager.m_isInDrawResult)
            -- LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "LuckyDraw.LDSingleRetUI", AppDef.UIType.PopWindow, data.data)
            -- self:SendMsg(LGameMsg.m_initUIMsg)
            -- dump(data.data, "LGetPetWingManager ================>")

            if not PetkaPaiManager.m_isInDrawResult then
                Utils:InitUI("HappyDraw.SingleDrawResultUI", AppDef.UIType.MsgBox, data.data)
            else
                Utils:SendMsg(LUIDrawEvent.continueDanCiDrawSuc, data.data)
            end
            
            self.m_isShowing = true
            self.m_timestamp = os.time()
        elseif data.type == AppDef.AwrdItem.AWRD_ITEM_HORSE or data.type == AppDef.AwrdItem.AWRD_ITEM_ARTIFACT or data.type == AppDef.AwrdItem.AWRD_ITEM_WINDS then
            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "ImproveUI.ShowWingHorseUI", AppDef.UIType.PopWindow, {iType=data.type, id=data.data})
            self:SendMsg(LGameMsg.m_initUIMsg)
            self.m_isShowing = true
            self.m_timestamp = os.time()
        else
            isNext = true
        end
        table.remove(self.m_dataVec, 1)
        if isNext then
            self:checkNext()
        end
    end
end

function LGetPetWingManager:UpdateShowingState()
    if self.m_isShowing then
        if (os.time() - self.m_timestamp) > 1 then
            self.m_isShowing = false
        end
    end
end

return LGetPetWingManager