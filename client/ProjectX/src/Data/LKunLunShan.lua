--[[
昆仑山任务
]]
LKunLunShanTask = {}
LKunLunShanTask.__index = LKunLunShanTask
function LKunLunShanTask:New()
    local o = {}
    setmetatable(o,LKunLunShanTask)    
    o:ctor()
    return o
end

function LKunLunShanTask:ctor(id)
    self.taskName = ""
    self.targetDesc = ""
    self.killNum = 0
    self.award1 = ""
    self.award2 = ""
    self.isComplete = false
end

function LKunLunShanTask:Delete()
    self.taskName = nil
    self.targetDesc = nil
    self.killNum = nil
    self.award1 = nil
    self.award2 = nil
    self.isComplete = nil
end

LKunLunShanPaiHang = {}
LKunLunShanPaiHang.__index = LKunLunShanPaiHang
function LKunLunShanPaiHang:New()
    local o = {}
    setmetatable(o,LKunLunShanPaiHang)    
    o:ctor()
    return o
end

function LKunLunShanPaiHang:ctor(id)
    self.rank = 0
    self.roleId = 0
    self.name = ""
    self.score = 0
end

function LKunLunShanPaiHang:Delete()
    self.rank = nil
    self.roleId = nil
    self.name = nil
    self.score = nil
end

LRoomInfo = {}
LRoomInfo.__index = LRoomInfo
function LRoomInfo:New()
    local o = {}
    setmetatable(o,LRoomInfo)    
    o:ctor()
    return o
end

function LRoomInfo:ctor(id)
    self.roomID = 0
    self.peopleNum = 0
    self.maxNum = 0
end

function LRoomInfo:Delete()
    self.roomID = nil
    self.peopleNum = nil
    self.maxNum = nil
end

LKunlunShanData = {}
LKunlunShanData.__index = LKunlunShanData
function LKunlunShanData:New()
    local o = {}
    setmetatable(o,LKunlunShanData)    
    o:ctor()
    return o
end

function LKunlunShanData:ctor()
    self.m_score = 0
    self.m_curRoom = 0
    self.m_isOnOpen = false -- 昆仑山活动是否开启 
    self.m_killRoleNum = 0
    self.m_killMonsterNum = 0
    self.m_nextFlushScecond = 0
    self.m_timeSpace = 0
    self.killMonsterTask = {}
    self.killRoleTask = {}
    self.m_paiHangList = {}
    self.vecRoomInfo = {}
end

function LKunlunShanData:Reset()
    self.m_score = 0
    self.m_curRoom = 0
    self.m_isOnOpen = false -- 昆仑山活动是否开启 
    self.m_killRoleNum = 0
    self.m_killMonsterNum = 0
    self.m_nextFlushScecond = 0
    self.m_timeSpace = 0
    self.killMonsterTask = {}
    self.killRoleTask = {}
    self.m_paiHangList = {}
    self.vecRoomInfo = {}
end

function LKunlunShanData:Delete()
    self.m_score = nil
    self.m_curRoom = nil
    self.m_isOnOpen = nil
    self.m_killRoleNum = nil
    self.m_killMonsterNum = nil
    self.m_nextFlushScecond = nil
    self.m_timeSpace = nil
    self.killMonsterTask = nil
    self.killRoleTask = nil
    self.vecRoomInfo = nil
end