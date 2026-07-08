LTeamApplyData = {}
LTeamApplyData.__index = LTeamApplyData
function LTeamApplyData:New()
    local o = {}
    setmetatable(o,LTeamApplyData)    
    o:ctor()
    return o
end
function LTeamApplyData:ctor()
    self.id = 0
    self.type = 0--灵活字段，可自定义
    self.sex = 0
    self.level = 0
    self.profession = 0
    self.num = 0
    self.serzoneid = 0
    self.zhandouli = 0
    self.name = ""
end

function LTeamApplyData:Reset()
    self.id = 0
    self.type = 0--灵活字段，可自定义
    self.sex = 0
    self.level = 0
    self.profession = 0
    self.num = 0
    self.serzoneid = 0
    self.zhandouli = 0
    self.name = ""
end

function LTeamApplyData:Delete()
    self.id = nil
    self.type = nil--灵活字段，可自定义
    self.sex = nil
    self.level = nil
    self.profession = nil
    self.num = nil
    self.serzoneid = nil
    self.zhandouli = nil
    self.name = ""
end

LTeamSettingData = {}
LTeamSettingData.__index = LTeamSettingData
function LTeamSettingData:New()
    local o = {}
    setmetatable(o,LTeamSettingData)    
    o:ctor()
    return o
end
function LTeamSettingData:ctor()
    self.m_type = 0
    self.m_name = ""
    self.m_limitLv = 0
end

function LTeamSettingData:Delete()
    self.m_type = nil
    self.m_name = nil
    self.m_limitLv = nil
    
end


LTeamMemberData = {}
LTeamMemberData.__index = LTeamMemberData
function LTeamMemberData:New()
    local o = {}
    setmetatable(o,LTeamMemberData)    
    o:ctor()
    return o
end

function LTeamMemberData:ctor()
    self.m_type = 0
    self.m_srcPos = 0--队形位置
    self.m_lineupPos = 0--队形战斗位置
    self.m_id = 0
    self.m_name = ""
    self.m_lv = 0
    self.m_professnal = 0
    self.m_sex = 0
    self.m_weapon = 0
    self.m_wLight = 0
    self.m_titleNum = 0
    self.m_title = {}
    self.m_state = 0
    self.m_shap = 0
    self.m_power = 0
    self.m_star = 0
    self.m_subStar = 0
    self.m_serverZone = 0
    self.m_serverId = 0
    self.m_cap = 0
end

function LTeamMemberData:Reset()
    self.m_type = 0
    self.m_srcPos = 0
    self.m_lineupPos = 0
    self.m_id = 0
    self.m_name = ""
    self.m_lv = 0
    self.m_professnal = 0
    self.m_sex = 0
    self.m_weapon = 0
    self.m_wLight = 0
    self.m_titleNum = 0
    self.m_title = {}
    self.m_state = 0
    self.m_shap = 0
    self.m_power = 0
    self.m_star = 0
    self.m_subStar = 0
    self.m_serverZone = 0
    self.m_serverId = 0
    self.m_cap = false
end

function LTeamMemberData:Delete()
    self.m_type = nil
    self.m_srcPos = nil
    self.m_lineupPos = nil
    self.m_id = nil
    self.m_name = nil
    self.m_lv = nil
    self.m_professnal = nil
    self.m_sex = nil
    self.m_weapon = nil
    self.m_wLight = nil
    self.m_titleNum = nil
    self.m_title = nil
    self.m_state = nil
    self.m_shap = nil
    self.m_power = nil
    self.m_star = 0
    self.m_subStar = 0
    self.m_serverZone = nil
    self.m_serverId = nil
    self.m_cap = nil
end


LTeamPublishData = {}
LTeamPublishData.__index = LTeamPublishData
LTeamPublishData.MaxNum = 20
function LTeamPublishData:New()
    local o = {}
    setmetatable(o,LTeamPublishData)    
    o:ctor()
    return o
end

function LTeamPublishData:ctor()
    --[[
    op=22    type   teamNum  { minLevel   maxLevel   memberNum [  roleId   name   leaveFlag  zhongzu   sex   level  ]}
1byte   1byte    1byte       2byte      2byte     1byte        4byte  string    1byte     1byte   1byte  2byte
]]
    self:Reset()
end

function LTeamPublishData:Reset()
    self.m_byType = 0--队伍类型
    self.m_minLv = 0
    self.m_maxLv = 0
end

function LTeamPublishData:Delete()
    --[[
    op=22    type   teamNum  { minLevel   maxLevel   memberNum [  roleId   name   leaveFlag  zhongzu   sex   level  ]}
1byte   1byte    1byte       2byte      2byte     1byte        4byte  string    1byte     1byte   1byte  2byte
]]
    self.m_byType = nil
    self.m_minLv = nil
    self.m_maxLv = nil
end

--[[
玩家身上的队伍信息
]]
LTeamData = {}
LTeamData.__index = LTeamData
function LTeamData:New()
    local o = {}
    setmetatable(o,LTeamData)    
    o:ctor()
    return o
end

function LTeamData:ctor()
    self.m_byType = 0--队伍类型
    self.m_zhenfaId = 0--当前使用的战法id
    self.m_bIsTeam = false
    self.m_bIsCap = false
    self.m_pApplyList = {}
    self.m_pMembers = {}
    self.m_bIsSettingAutoApply = false--是否设置过自动招募
    self.m_bIsAutoApply = false--是否自动招募
    self.m_pInvateStates = {}
    -- for i = 1,5 do
    --     self.m_pMembers[i] = LTeamMemberData:New()
    -- end
    self.m_pPublishList = LTeamPublishData:New()
end

function LTeamData:Reset()
    self.m_byType = 0--队伍类型
    self.m_zhenfaId = 0--当前使用的战法id
    self.m_bIsTeam = false
    self.m_bIsCap = false
    self.m_pApplyList = {}
    
    self.m_bIsSettingAutoApply = false--是否设置过自动招募
    self.m_bIsAutoApply = false--是否自动招募
    self.m_pInvateStates = {}
    local num = #self.m_pMembers
    for i = 1,num do
        self.m_pMembers[i]:Delete()
        self.m_pMembers[i] = nil
    end
    self.m_pMembers = {}
    self.m_pPublishList:Reset()
end

function LTeamData:GetTeamMemberByInd(ind)
   
    if ind > #self.m_pMembers then
        local cnt = #self.m_pMembers
        for i = cnt, ind do
            local member = LTeamMemberData:New()
            table.insert(self.m_pMembers, member)
        end
    end
    return self.m_pMembers[ind]
end

function LTeamData:IsTeamInvated(heroId)
    if self.m_pInvateStates[heroId] == nil then
        return false
    end
    return true
end

function LTeamData:SetTeamInvated(heroId)
    self.m_pInvateStates[heroId] = 1
end

function LTeamData:ResetTeamTarget()
    self.m_pPublishList:Reset()
end

function LTeamData:GetHeroMemberById(id)
    for i = 1, #self.m_pMembers do
        if self.m_pMembers[i].m_id == id then
            return self.m_pMembers[i]
        end
    end
    return nil
end


function LTeamData:GetHeroMember(ind)
    if self.m_pMembers[ind].m_type == 1 then
        return self.m_pMembers[ind]
    else
        return nil
    end
end

function LTeamData:ResetMembers()
    for i = 1,#self.m_pMembers do
        self.m_pMembers[i]:Reset()
    end
end

function LTeamData:Delete()
    self.m_bIsTeam = nil
    self.m_zhenfaId = nil
    self.m_bIsCap = nil
    local num = #self.m_pMembers
    for i = 1,num do
        self.m_pMembers[i]:Delete()
        self.m_pMembers[i] = nil
    end
    self.m_pMembers = nil
    self.m_pPublishList:Delete()
    self.m_pPublishList = nil
end