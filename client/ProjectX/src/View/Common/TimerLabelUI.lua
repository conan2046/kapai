local TimerLabelUI = {}
TimerLabelUI.__index = TimerLabelUI

-- -----------------------------------
function TimerLabelUI:New(label, time, callback, updateCallback, isAdd, overflow)
    local o = {}
    setmetatable(o, TimerLabelUI)
    o:Init(label, time, callback, updateCallback, isAdd, overflow)
    return o
end

function TimerLabelUI:Init(label, time, callback, updateCallback, isAdd, overflow)
    self.m_label = label
    if label then
        label:retain()
    end
    self.m_initTime = time or 0
	self.m_leftTime = self.m_initTime + 1
    self.m_callback = callback
    self.m_updateCallback = updateCallback
    self.m_schedule = nil
    self.m_isAdd = isAdd
    self.m_overflow = overflow
end
--[[
需要手动调用Destory方法，否则会有内存泄漏
]]
function TimerLabelUI:Destory()
    self:stop()
    if self.m_label ~= nil then
        self.m_label:release()
        self.m_label = nil
    end
    self.m_callback = nil
    self.m_updateCallback = nil
end

function TimerLabelUI:start()
	if self.m_label == nil then
        return
    end
    self:stop()
    
    self.m_leftTime = self.m_initTime
    
    if self.m_leftTime ~= nil and self.m_leftTime >= 0 then
        self.m_schedule = Utils:schedule(nil, handler(self, TimerLabelUI.updateTime), 1)
        self:updateTime(0)
    end
end

function TimerLabelUI:setLabel( label )
    -- body
    if label == nil then
        return
    end
    self.m_label = label
end

function TimerLabelUI:updateTime(dt)
    if self.m_isAdd then
        self.m_leftTime = self.m_leftTime + dt
        if self.m_leftTime >= self.m_overflow then
            self.m_leftTime = self.m_overflow
            self:stop()
            self:scheduleEnd()
        end
    else
        self.m_leftTime = self.m_leftTime - dt
        if self.m_leftTime <= 0 then
            self.m_leftTime = 0
            self:stop()
            self:scheduleEnd()
        end
    end
    
    local iLeftTime = math.floor(self.m_leftTime)
    local _h, _m, _s = Utils:getFormatTime(iLeftTime)
    if self.m_updateCallback ~= nil then
        self.m_updateCallback(self.m_label, _h, _m, _s, iLeftTime)
    else
        if _h >= 24 then
            local day = math.floor(_h/24)
            _h = _h - day*24
            self.m_label:setString(string.format("%d%s%02d:%02d:%02d", day, GUITips.UI_Arena_Msg1, _h, _m, _s))
        else
            self.m_label:setString(string.format("%02d:%02d:%02d", _h, _m, _s))
        end
    end
end

function TimerLabelUI:stop()
	Utils:unschedule(nil, self.m_schedule)
    self.m_schedule = nil
end

function TimerLabelUI:set(time, callback)
    self.m_initTime = time or 0
	self.m_callback = callback
end

function TimerLabelUI:get()
    return math.floor(self.m_leftTime)
end

function TimerLabelUI:scheduleEnd()
    performWithDelay(self.m_label, function(sender)
        if self.m_callback ~= nil then
            self.m_callback(self.m_label)
        end
    end, 0.25)
end

return TimerLabelUI