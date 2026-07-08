local LuckTableUI = {}
LuckTableUI.__index = LuckTableUI

local ALLROATE = 360--360度
-----------------------------------
function LuckTableUI:New(pNode)
    if pNode == nil then
        return nil
    end
    local o = {}
    setmetatable(o, LuckTableUI)
    o:Init(pNode)
    return o
end
-----------------------------------
function LuckTableUI:Init(pNode)
    self.Script = "Common.LuckTableUI"
    self.m_pUILayer = pNode
    self.m_lastIndex = 0
    --------------------------------------------------
    self:setCloseCallback()
end
-----------------------------------
function LuckTableUI:onExit()
    self:ScheduleEnd()
    self.m_pUILayer = nil
    self.Script = nil
    Utils:FreeTable(self.m_data)
    self.m_data = nil
    Utils:FreeTable(self.m_zpData)
    self.m_zpData = nil
end
-----------------------------------
function LuckTableUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
-----------------------------------
--[[
data.duration:转盘持续时间(默认5)
data.count:转盘有几个格子(默认10)
data.rtCount:转动圈数(默认5)
data.sCallback:转动前的回调
data.fCallback:转动后的回调
data.indexChanged:索引变化的回调
data.rate:转动速率
]]
function LuckTableUI:SetData(data)
    self.m_data = data
    self.m_data.duration = self.m_data.duration or 5
    self.m_data.rtCount = self.m_data.rtCount or 5
    
    Utils:FreeTable(self.m_zpData)
    self.m_zpData = nil
    self.m_zpData = {}

    local num = self.m_data.count or 10
    local cellRotation = ALLROATE/num
    for i=1,num do
        table.insert(self.m_zpData, {start=(i-1.5)*cellRotation, ended=(i-0.5)*cellRotation})
    end
    -- dump(self.m_zpData)
end
-----------------------------------
function LuckTableUI:GetRotation(index)
    local data = self.m_zpData[index]
    if data == nil then
        return 0,0
    end
    return data.start,data.ended
end
-----------------------------------
--[[
开始转动
]]
function LuckTableUI:Start(index)
    if self.m_pUILayer == nil or self.m_data == nil or self.m_zpData == nil then
        return
    end
    local rotateNum = self.m_data.rtCount
    local targetData = self.m_zpData[index]
    if targetData == nil then
        return
    end
    math.randomseed(os.time())

    local arr = {}
    table.insert(arr, cc.CallFunc:create(function()
        self:ScheduleStart()
        if self.m_data.sCallback then
            self.m_data.sCallback()
        end
    end))

    local rotateNum = self.m_data.rtCount
    -- local randRotation = (targetData.start + targetData.ended)/2--math.random(targetData.start, targetData.ended)
    local randRotation = math.random(targetData.start+3, targetData.ended-3)
    local offset = self.m_pUILayer:getRotation()
    offset = math.fmod(offset, ALLROATE)
    local rotateAngle = randRotation - offset + ALLROATE*rotateNum
    -- dump({randRotation, offset, rotateAngle}, "============>")
    local action = cc.RotateBy:create(self.m_data.duration, rotateAngle)
    -- table.insert(arr, cc.EaseCubicActionInOut:create(action))
    table.insert(arr, cc.EaseInOut:create(action, self.m_data.rate or 3.5))

    table.insert(arr, cc.CallFunc:create(function()
        self:ScheduleEnd()
        self:CheckIndex(0)
        if self.m_data.fCallback then
            self.m_data.fCallback()
        end
        Utils:SendMsg(LAudioEvent.PlayShortEffect, AppDef.LuckTableAudio.Single)
    end))

    self.m_pUILayer:stopAllActions()
    self.m_pUILayer:runAction(cc.Sequence:create(arr))
end
-----------------------------------
--[[
停止转动（未实现）
]]
function LuckTableUI:Stop(index)
end
-----------------------------------
function LuckTableUI:ScheduleStart()
    if self.m_data.indexChanged then
        self:ScheduleEnd()
        self.m_schedule = Utils:schedule(nil, handler(self, self.CheckIndex), 1/20, false)
    end
end
-----------------------------------
function LuckTableUI:ScheduleEnd()
    if self.m_schedule then
        Utils:unschedule(nil, self.m_schedule)
    end
    self.m_schedule = nil
end
-----------------------------------
function LuckTableUI:CheckIndex(dt)
    local rotation = self.m_pUILayer:getRotation()
    rotation = math.fmod(rotation, ALLROATE)
    if rotation >= (ALLROATE + self.m_zpData[1].start) then
        self:IndexChanged(1)
    else
        for i=1,#self.m_zpData do
            local info = self.m_zpData[i]
            if info and info.start <= rotation and info.ended > rotation then
                self:IndexChanged(i)
                break
            end
        end
    end
end

function LuckTableUI:IndexChanged(index)
    if self.m_lastIndex ~= index then
        self.m_data.indexChanged(index, self.m_lastIndex)
        self.m_lastIndex = index
        local index = math.random(1, 7)
        local str = AppDef.LuckTableAudio["Single_"..index]
        if str then
            Utils:SendMsg(LAudioEvent.PlayShortEffect2, str)
        end
    end
end
-----------------------------------
return LuckTableUI