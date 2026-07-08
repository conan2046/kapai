local DateTime = {}
DateTime.__index = DateTime
---------------------------------------------------
DateTime.instance = nil
---------------------------------------------------
DateTime.year   = 1
DateTime.month  = 2
DateTime.day    = 3
DateTime.hour   = 4
DateTime.min    = 5
DateTime.sec    = 6
---------------------------------------------------
function DateTime:getInstance()
    if self.instance == nil then
        self.instance = self:_New()
    end
    return self.instance
end
---------------------------------------------------
function DateTime:_New()
    local o = {}
    setmetatable(o, DateTime)
    o:_Init()
    return o
end
---------------------------------------------------
function DateTime:_Init()
    self.m_date = nil
    self.m_serverTime = nil
    self.m_schedule = Utils:schedule(nil, handler(self, DateTime._Update), 1, false)
    self:_Update(0)
    ---------------------------------------------------
end
---------------------------------------------------
function DateTime:_Update(dt)
    if LDataConstMgr.m_serverTime == nil then
        return
    end
    if self.m_serverTime and self.m_serverTime == LDataConstMgr.m_serverTime then
        return
    end

    local temp = os.date("*t", LDataConstMgr.m_serverTime)
    if self.m_date == nil then
        self.m_date = temp
        return
    end

    -- dump(LDataConstMgr.m_serverTime, "LDataConstMgr.m_serverTime--->")
    -- dump(temp, "_Update-->")
    if self.m_date.year ~= temp.year then
        Utils:SendMsg(LUILogicEvent.DataTimeEvent, {t=DateTime.year, new=temp.year, old=self.m_date.year})
    end
    if self.m_date.month ~= temp.month then
        Utils:SendMsg(LUILogicEvent.DataTimeEvent, {t=DateTime.month, new=temp.month, old=self.m_date.month})
    end
    if self.m_date.day ~= temp.day then
        Utils:SendMsg(LUILogicEvent.DataTimeEvent, {t=DateTime.day, new=temp.day, old=self.m_date.day})
    end
    if self.m_date.hour ~= temp.hour then
        Utils:SendMsg(LUILogicEvent.DataTimeEvent, {t=DateTime.hour, new=temp.hour, old=self.m_date.hour})
    end
    if self.m_date.min ~= temp.min then
        Utils:SendMsg(LUILogicEvent.DataTimeEvent, {t=DateTime.min, new=temp.min, old=self.m_date.min})
    end
    if self.m_date.sec ~= temp.sec then
        Utils:SendMsg(LUILogicEvent.DataTimeEvent, {t=DateTime.sec, new=temp.sec, old=self.m_date.sec})
    end
    self.m_date = temp
    self.m_serverTime = LDataConstMgr.m_serverTime
end
---------------------------------------------------
return DateTime