--[[
     排名战界面角色数据
]]
LArenaWarInfo = {}
LArenaWarInfo.__index = LArenaWarInfo
function LArenaWarInfo:New()
    local o = {}
    setmetatable(o,LArenaWarInfo )    
    o:Init()
    return o
end

function LArenaWarInfo:Init( )
    self.name = ""             --名字
    self.Id = 0
    self.IdType = 0            --是否为机器人1 机器 0正常   
    self.level = 0             --等级
    self.model = 0             --模型
    self.slotIndex = 0         --排名
    self.fightpower = 0        --战斗力
    self.sex = 0               --性别
    self.head = 0              --头像
end

function LArenaWarInfo:Delete(id )
    self.name = nil
    self.Id = nil
    self.IdType = nil
    self.level = nil
    self.model = nil
    self.slotIndex = nil
    self.fightpower = nil
    self.sex = nil
    self.head = nil
end

--[[
     排名战界面其他数据
]]
LArenaWarOtherInfo = {}
LArenaWarOtherInfo.__index = LArenaWarOtherInfo
function LArenaWarOtherInfo:New()
    local o = {}
    setmetatable(o,LArenaWarOtherInfo )    
    o:Init()
    return o
end

function LArenaWarOtherInfo:Init( )
    self.coldTime = 0          --冷却时间
    self.curSlotIndex = 0      --当前排名
    self.usedTimes = 0         --还可以挑战的次数
    self.LSTimes = 0           --连胜次数
    self.jiFen = 0             --竞技积分
end

function LArenaWarOtherInfo:Delete(id )
    self.coldTime = nil
    self.curSlotIndex = nil
    self.usedTimes = nil
    self.LSTimes = nil
    self.jiFen = nil
end


--[[
     排名战界面奖励面板数据
]]
LArenaAward = {}
LArenaAward.__index = LArenaAward
function LArenaAward:New()
    local o = {}
    setmetatable(o,LArenaAward )    
    o:Init()
    return o
end

function LArenaAward:Init( )
    self.coldTime = 0          --冷却时间
    self.slotIndex = 0         --当前排名
    self.leftTimes = 0         --还可挑战次数
    self.LSTimes = 0           --连胜次数
    self.awardColdTimes = 0    --领奖倒计时
    self.awardInfo = ""        --可领取奖励
end

function LArenaAward:Delete(id )
    self.coldTime = nil
    self.slotIndex = nil
    self.leftTimes = nil
    self.LSTimes = nil
    self.awardColdTimes = nil
    self.awardInfo = nil
end

--[[
     英雄榜界面角色数据
]]
LArenaHeroInfo = {}
LArenaHeroInfo.__index = LArenaHeroInfo
function LArenaHeroInfo:New()
    local o = {}
    setmetatable(o,LArenaHeroInfo )    
    o:Init()
    return o
end

function LArenaHeroInfo:Init( )
    self.name = ""             --名字
    self.Id = 0
    self.IdType = 0            --是否为机器人1 机器 0正常   
    self.level = 0             --等级
    self.head = 0              --头像
    self.model = 0             --模型
    self.slotIndex = 0         --排名
    self.fightpower = 0        --战斗力
    self.sex = 0               --性别
    self.vipLevel = 0          --vip等级
    self.bangId = 0            --帮派ID
    self.bangName = ""         --帮派名称  
end

function LArenaHeroInfo:Delete( )
    self.name = nil
    self.Id = nil
    self.IdType = nil
    self.level = nil
    self.head = nil
    self.model = nil
    self.slotIndex = nil         --排名
    self.fightpower = nil
    self.sex = nil
    self.vipLevel = nil
    self.bangId = nil   
    self.bangName = nil 
end

--[[
     竞技场单个记录界面数据
]]
LArenaRegInfo = {}
LArenaRegInfo.__index = LArenaRegInfo
function LArenaRegInfo:New()
    local o = {}
    setmetatable(o,LArenaRegInfo )    
    o:Init()
    return o
end

function LArenaRegInfo:Init( )
    self.attackerInfo = LArenaHeroInfo:New() --攻击者数据（LArenaHeroInfo）
    self.victimInfo = LArenaHeroInfo:New() --被攻击者数据（LArenaHeroInfo）
    self.time = 0 --时间戳
    self.win = 0--1-成功，0-失败
    self.rank = 0 --排名（全服记录里面，挑战成功后的排名；自己记录里面，挑战成功or被挑战失败后的排名）
    self.oldRank = 0 --原排名
    self.replayId = 0 --视频回放ID
end

function LArenaRegInfo:Delete()
    self.attackerInfo = LArenaHeroInfo:Delete()
    self.victimInfo = LArenaHeroInfo:Delete()
    self.time = nil
    self.win = nil
    self.rank = nil 
    self.oldRank = nil
    self.replayId = nil
end

--[[
膜拜角色
]]
LWarshipPageInfo = {}
LWarshipPageInfo.__index = LWarshipPageInfo
function LWarshipPageInfo:New()
    local o = {}
    setmetatable(o,LWarshipPageInfo)    
    o:Init()
    return o
end

function LWarshipPageInfo:Init( )
    self.index = 0            -- 索引
    self.roleId = 0           -- 角色ID
    self.roleType = 0         -- 0:玩家  1：机器人
    self.roleName = ""        -- 角色名称
    self.profession = 0       -- 职业
    self.level = 0            -- 级别
    self.sex = 0              -- 性别
    self.bangpaiName = ""     -- 帮派名称
    self.bowCount = 0         -- 英雄被膜拜总数
    self.eggCount = 0         -- 英雄被鄙视总数
end

function LWarshipPageInfo:Delete(id )
    self.index = nil
    self.roleId = nil
    self.roleType = nil
    self.roleName = nil
    self.profession = nil
    self.level = nil
    self.sex = nil
    self.bangpaiName = nil
    self.bowCount = nil
    self.eggCount = nil
end

--[[
膜拜信息
]]
LWarshipInfo = {}
LWarshipInfo.__index = LWarshipInfo
function LWarshipInfo:New()
    local o = {}
    setmetatable(o,LWarshipInfo)    
    o:Init()
    return o
end

function LWarshipInfo:Init( )
    self.bowNum = 0           -- 点赞次数
    self.eggNum = 0           -- 鄙视次数
    self.MaxNum = 0           -- 可鄙视最大数量
    self.VecLog = {}          -- 记录信息
    self.VecPlayerID = {}     -- 操作膜拜功能的玩家roleId
    self.time = 0
    -- self.logNum = 0
    self.warshipPages = {}
end

function LWarshipInfo:Delete(id )
    self.bowNum = nil
    self.eggNum = nil
    self.MaxNum = nil
    self.VecLog = nil
    self.VecPlayerID = nil
    self.time = nil
    self.warshipPages = nil
end

--[[
膜拜主城雕像信息
]]
LWarshipModel = {}
LWarshipModel.__index = LWarshipModel
function LWarshipModel:New()
    local o = {}
    setmetatable(o,LWarshipModel)    
    o:Init()
    return o
end

function LWarshipModel:Init( )
	self.index = 0 --被膜拜英雄索引
	self.heroInfo = {}-- 角色信息
end

function LWarshipModel:Delete(id )
    self.index = nil
    Utils:FreeTable(self.heroInfo)
    self.heroInfo = nil       
end


--[[
    竞技场界面数据（临时存放，关闭面板后释放）
]]
LChallengeDataMgr = LDataBase:New()
LChallengeDataMgr.__index = LChallengeDataMgr
function LChallengeDataMgr:Init()
    self.ArenaWar = {} --排名战
    self.ArenaWarOther = LArenaWarOtherInfo:New() --排名战其他信息
    self.ArenaJiangli = LArenaAward:New()  --奖励
    self.ArenaHeroList = {} --英雄榜
    self.ArenaRegister = {} --记录
    --self.ArenaRegisterOth = {} --英雄榜记录
    self.Intro_msIntroduce = "" --介绍文字
    self.miSecond = 0
    self.miMinute = 0
    self.miRemainTimes = 0

    self._WarshipInfo = LWarshipInfo:New()
    self._MobaiModelList = {}
end


function LChallengeDataMgr:Free()
    self.ArenaWar = {}
    self.ArenaWarOther:Delete()
    self.ArenaJiangli:Delete()
    self.ArenaHeroList = {}
    self.ArenaRegister = {}
    --self.ArenaRegisterOth = {}
    self.Intro_msIntroduce = ""
    self.miSecond = 0
    self.miMinute = 0
    self.miRemainTimes = 0
end

LChallengeDataMgr:Init()


LArenaDataMgr = LDataBase:New()
LArenaDataMgr.__index = LArenaDataMgr
function LArenaDataMgr:Init()
    self.m_rankList = {} --竞技场排行榜信息(LArenaHeroInfo)
    self.m_toptenModelInfos = {} --显示前十模型的玩家信息(LArenaHeroInfo)
    self.m_modelInfos = {} --显示模型的玩家信息(LArenaHeroInfo)
    self.m_records = {} --前十战斗记录
    self.m_myrecords = {} --自己战斗记录
    self.m_rewards = {}--竞技场奖励
    self.m_myRank = 0 --我的排名
    self.m_score = 0  --竞技场积分
    self.m_cnt = 0  --挑战剩余次数
    self.m_tiaoZhCnt = 0 --已挑战次数
    self.m_buyCnt = 0 --挑战令已购买次数
    self.m_sweepInfo = {}--扫荡数据-临时存储，关闭扫荡界面后清除
end

function LArenaDataMgr:InitRankInfo()
    self.m_toptenModelInfos = {} --显示模型的玩家信息(LArenaHeroInfo)
    for i=1,10 do
        local data = LArenaWarInfo:New()
        table.insert(self.m_toptenModelInfos,data)
    end
end

-- function LArenaDataMgr:InitRankReward()
--     self.m_rewards = {0,0,0,0,0,0,0,0}--竞技场奖励领取情况
-- end

LArenaDataMgr:Init()

--[[
     排行榜通用角色数据
]]
LRankHeroInfo = {}
LRankHeroInfo.__index = LRankHeroInfo
function LRankHeroInfo:New()
    local o = {}
    setmetatable(o,LRankHeroInfo )    
    o:Init()
    return o
end

function LRankHeroInfo:Init( )
    self.name = ""             --名字
    self.Id = 0
    self.level = 0             --等级
    self.head = 0              --头像
    self.slotIndex = 0         --排名
    self.fightpower = 0        --战斗力
    self.sex = 0               --性别
    self.bangId = 0            --帮派ID
    self.bangName = ""         --帮派名称  
    self.data = 0              --排名数据
    self.value = 0             --特别参数
end

LRankDataMgr = LDataBase:New()
LRankDataMgr.__index = LRankDataMgr
function LRankDataMgr:Init()
    self.m_ranks = {} --key:rankType,value:LRankHeroInfo列表
    self.m_myInfo = {}
    self.m_value = 0--用于查看宠物
end

function LRankDataMgr:Delete(rankType)
    rankType = rankType or 0
    self.m_ranks[rankType] = nil
    self.m_myInfo[rankType] = nil
end

LRankDataMgr:Init()