local TimerCenter = {}
TimerCenter.__index = TimerCenter
TimerCenter.instance = nil
---------------------------------------------------
function TimerCenter:getInstance()
    if self.instance == nil then
        self.instance = self:_New()
    end
    return self.instance
end
---------------------------------------------------
--[[
handler:回调
interval:间隔
]]
function TimerCenter:schedule(handler, interval)
    if handler == nil then
        return nil
    end
    return self:_Register(handler, interval)
end
---------------------------------------------------
function TimerCenter:unschedule(scheduleID)
    if scheduleID == nil then
        return
    end
    self:_UnRegister(scheduleID)
end
---------------------------------------------------
function TimerCenter:scheduleOnce(handler, interval)
    if handler == nil then
        return nil
    end
    return self:_Register(handler, interval, true)
end
---------------------------------------------------
function TimerCenter:_New()
    local o = {}
    setmetatable(o, TimerCenter)
    o:_Init()
    return o
end
---------------------------------------------------
function TimerCenter:_Init()
    self.m_map = {}
    self.m_id = 0
    ---------------------------------------------------
    self:_InitScheduler()
end
---------------------------------------------------
function TimerCenter:_InitScheduler()
    if self.m_pScheduler then
        return
    end
    self.m_pScheduler = AppDef.Director:getScheduler()
    self.m_pScheduler:scheduleScriptFunc(handler(self, TimerCenter._Update), 1/30, false)
end
---------------------------------------------------
function TimerCenter:_Update(dt)
    for id,cfg in pairs(self.m_map) do
        if id and cfg and cfg.handler then
            cfg.interval = cfg.interval or 1
            cfg.time = (cfg.time or 0) + dt
            if cfg.time >= cfg.interval then
                cfg.time = cfg.time - cfg.interval
                cfg.handler(cfg.interval)
                if cfg.isOnce then
                    self:_UnRegister(id)
                end
            end
        end
    end
end
---------------------------------------------------
function TimerCenter:_IDGrowUp()
    self.m_id = self.m_id + 1
    return self.m_id
end
---------------------------------------------------
function TimerCenter:_Register(handler, interval, isOnce)
    local scheduleID = self:_IDGrowUp()
    local cfg = {}
    cfg.handler = handler
    cfg.interval = interval or 1
    cfg.time = 0
    cfg.isOnce = isOnce
    self.m_map[scheduleID] = cfg
    return scheduleID
end
---------------------------------------------------
function TimerCenter:_UnRegister(scheduleID)
    self.m_map[scheduleID] = nil
end
---------------------------------------------------
return TimerCenter