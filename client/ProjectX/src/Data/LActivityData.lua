--[[
灵气信息
]]
LLingqiInfo = {}
LLingqiInfo.__index = LLingqiInfo
function LLingqiInfo:New()
    local o = {}
    setmetatable(o,LLingqiInfo)    
    o:ctor()
    return o
end

function LLingqiInfo:ctor()
    self.nowCnt = 0 -- 当前灵气
    self.times = ""  -- 剩余次数
    self.ids = {}    -- 物品id
    self.exps = {}   -- 经验
end

function LLingqiInfo:Reset()
    self.nowCnt = 0 -- 当前灵气
    self.times = ""  -- 剩余次数
    self.ids = {}    -- 物品id
    self.exps = {}   -- 经验
end

function LLingqiInfo:Delete()
    self.nowCnt = nil
    self.times = nil
    self.ids = nil
    self.exps = nil
end

--[[
飞仙战场信息
]]
LFlyFaryFieldInfo = {}
LFlyFaryFieldInfo.__index = LFlyFaryFieldInfo
function LFlyFaryFieldInfo:New()
    local o = {}
    setmetatable(o,LFlyFaryFieldInfo)    
    o:ctor()
    return o
end

function LFlyFaryFieldInfo:ctor(id)
    self.LeftTime=0               --剩余时间
    self.vecAwardId={}            --奖励Id
    self.vecAwardNum={}           --奖励数量
    self.CurLevel=0               --当前层数
    self.KillPoint=0              --击杀点数
    self.MaxKillPoint=0           --最大击杀点数
    self.BeAttackedPoint=0        --被杀点数
    self.MaxBeAttackedPoint=0     --最大被杀点数
    self.CurExp=0                 --本层经验
    self.BonusExp=0               --vip加成经验
    self.MaxTime=0                --最大时间
    self.State=0                  --状态1飞仙0不是
    self.AddExpTime=0             --经验时间
end

function LFlyFaryFieldInfo:Delete()
    self.LeftTime=nil
    self.vecAwardId=nil
    self.vecAwardNum=nil
    self.CurLevel=nil
    self.KillPoint=nil
    self.MaxKillPoint=nil
    self.BeAttackedPoint=nil
    self.MaxBeAttackedPoint=nil
    self.CurExp=nil
    self.BonusExp=nil
    self.MaxTime=nil
    self.State=nil
    self.AddExpTime=nil
end

--[[
藏宝图信息
]]
LCangBaotuData = {}
LCangBaotuData.__index = LCangBaotuData
function LCangBaotuData:New()
    local o = {}
    setmetatable(o,LCangBaotuData)    
    o:ctor()
    return o
end

function LCangBaotuData:ctor()
    self.isQuery=false    --是否是查询的数据
    self.isWa=false       --是否在挖宝中
    self.numLimit=0       --次数限制  
    self.completeNum=0    --完成次数
    self.sid=0            --地图ID
    self.posX=0           --地图坐标X
    self.posY=0           --地图坐标y
end

function LCangBaotuData:Delete()
    self.numLimit=nil
    self.completeNum=nil
    self.sid=nil
    self.posX=nil
    self.posY=nil
end

--[[
充值消费通用
]]
LActiveAward = {}
LActiveAward.__index = LActiveAward
function LActiveAward:New()
    local o = {}
    setmetatable(o,LActiveAward)    
    o:ctor()
    return o
end

function LActiveAward:ctor()
    self.chongzhi=0       --充值消费通用  
    self.desTime=""       --充值描述
    self.awardInfo={}
end

function LActiveAward:Reset()
    self.chongzhi=0       --充值消费通用  
    self.desTime=""       --充值描述
    self.awardInfo={}
end

function LActiveAward:Delete()
    self.chongzhi=nil
    self.desTime=nil
    self.awardInfo=nil
end

LAwardInfo = {}
LAwardInfo.__index = LAwardInfo
function LAwardInfo:New()
    local o = {}
    setmetatable(o,LAwardInfo)    
    o:ctor()
    return o
end

function LAwardInfo:ctor()
    self.index = 0
    self.yubao = 0
    self.isGetAward = 0
    self.awardItemId = {}
    self.awardItemNum = {}
    self.awardPet = {}
end

function LAwardInfo:Delete()
    self.index = nil
    self.yubao = nil
    self.isGetAward = nil
    self.awardItemId = nil
    self.awardItemNum = nil
    self.awardPet = nil
end

LTowerData = {}
LTowerData.__index = LTowerData
function LTowerData:New()
    local o = {}
    setmetatable(o,LTowerData)    
    o:ctor()
    return o
end

function LTowerData:ctor()
    self.id = 0
    self.rewards = {} --首通奖励
    self.sweepRewards = {} --扫荡奖励
    self.targetReward = {} --目标奖励
    self.targetRewardName = "" --目标奖励名称
end

--loading背景
LLoadingBgData = {}
LLoadingBgData.__index = LLoadingBgData
function LLoadingBgData:New()
    local o = {}
    setmetatable(o,LLoadingBgData)    
    o:ctor()
    return o
end

function LLoadingBgData:ctor()
    self.id = 0
    self.bgPic = ""
    self.iconPic = 0
    self.name = ""
    self.quality = 0
    self.value = {}
    self.content = {}
end

LNationalCollectWrodData = {}
LNationalCollectWrodData.__index = LNationalCollectWrodData
function LNationalCollectWrodData:New()
    local o = {}
    setmetatable(o, LNationalCollectWrodData)    
    o:ctor()
    return o
end

function LNationalCollectWrodData:ctor()
    self.timeMsg = ""
    self.allExchangeItems = {}
    self.exchageMaterial = {}
end


LExchangeWrodData = {}
LExchangeWrodData.__index = LExchangeWrodData
function LExchangeWrodData:New()
    local o = {}
    setmetatable(o, LExchangeWrodData)    
    o:ctor()
    return o
end

function LExchangeWrodData:ctor()
    self.index = 0
    self.isSelAny = 0
    self.exchangeTimes = 0
    self.totalExchangeTimes = 0
    self.exchangeItems = {}
    self.gainItems = {}
end

LXunZhanData = {}
LXunZhanData.__index = LXunZhanData
function LXunZhanData:New()
    local o = {}
    setmetatable(o, LXunZhanData)    
    o:ctor()
    return o
end

function LXunZhanData:ctor()
    self.m_openSign = false  --打开标识（今日正在挑战，则跳过主界面）
    self.m_maxChapterId = 0 --今日最高章节
    self.m_maxLevelId = 0--今日最高关卡
    self.m_maxLevelStar = 0 --今日累计获得星数
    self.m_forecastTime = 0 --请求今日排名时间戳（用于不要频繁请求）
    self.m_forecastRankId = 0 --预测今日排名
    self.m_forecastAwards = {} --预测今日奖励
    self.m_ayerRank = 0 --昨日排行
    self.m_enemyZhenId = {0,0,0} --敌方阵容ID(下标简单、普通、困难)，对应m_bloodArrays表Id
    --self.m_drawSign = false  --领取标识（排行奖励）
    self.m_sweepLevelId = 0 --扫荡最高关卡（可以扫荡到的关卡）
    self.m_chapterId = 0 --当前章节
    self.m_levelId = 0 --当前关卡（一章100关）
    self.m_attrs = {} --属性加成
    self.m_cnt = 0 --剩余闯关次数
    self.m_maxCnt = 0 --今日总计闯关次数
    self.m_reviveCnt = 0 --复活次数
    self.m_curStar = 0 --当前可用星数
    self.m_totalStar = 0 --累计星数
    self.m_maxStar = 0 --历史最高星
    self.m_difficulty = 0 --难度
    self.m_firstLevelId = 0 --当前最高首通关卡ID

    --可选buf
    self.m_bufs = {}
    --首通奖励状态
    --self.m_firstState = 0 --首通奖励状态 1 可以领取 2 已经领取 0 不能领取
    --状态
    self.m_state = 0 --状态 0-默认 1 战斗 2 死亡 3 不复活(没有复活次数的死亡) 4全通状态 7-扫荡buff待领取
    self.m_rewardState = 0 --奖励领取状态 0-未领取，1-已领取
    --关底奖励（5关宝箱）
    self.m_giftBoxs = {}
    self.m_items1 = {}--首通奖励展示
    self.m_items2 = {}--关底奖励展示
    self.m_items3 = {}--昨日排行奖励展示
    self.m_rewards = {}--上线后获得前面章节奖励
    self.m_rewardNum = 0
    --扫荡设置
    self.m_sweepInfo = {}
end

function LXunZhanData:UpdateData(chapterId)
    chapterId = chapterId or 0
    state = state or 0
    if chapterId > 0 then
        local cfg = JsonConfig.m_bloodChapter.getDefByID(chapterId)
        if cfg ~= nil then
            self.m_maxCnt = cfg.challenge_time
        end
    end
    if self.m_maxLevelId > 0 then
        local cfg = JsonConfig.m_bloodBattle.getDefByID(self.m_maxLevelId)
        if cfg ~= nil then
            self.m_maxChapterId = cfg.chapter
        end
    end
    if self.m_levelId > 0 then
        local cfg = JsonConfig.m_bloodBattle.getDefByID(self.m_levelId)
        if cfg ~= nil then
            self.m_chapterId = cfg.chapter
        end
    end
    if self.m_forecastRankId > 0 then
        local cfg = JsonConfig.GetRewardRankCfg(22,self.m_forecastRankId)
        if cfg ~= nil then
            self.m_forecastAwards = {}
            for i = 1,#cfg.reward do
                local value = {}
                value.id = cfg.reward[i][1]
                value.num = cfg.reward[i][3]
                table.insert(self.m_forecastAwards,value)
            end
        end
    end
    if self.m_cnt > self.m_maxCnt then
        self.m_cnt = self.m_maxCnt
    end
    if self.m_levelId < 1 then
        self.m_levelId = 1 
    end
    if self.m_sweepInfo == nil then
        self.m_sweepInfo = {}
    end
    --self.m_sweepInfo.sType = --LUserConfigMgr:GetXueZhanSType()
    if self.m_sweepInfo.sType == nil then
        self.m_sweepInfo.sType = 0xffffffff
        LuaNetSendMsg:SendXueZhanSweepSetting(0xffffffff)
    end
    if self.m_sweepInfo.sType ~= 0 and self.m_sweepInfo.sType ~= 0xffffffff then
        local types = {10,11,12,13,15,16,17,18,19,22}
        local value = bit._d2b(self.m_sweepInfo.sType)
        local sign = true
        for i=1,#types do
            if value[32-types[i]+1] == 1 then
                sign = false
                break
            end
        end
        if sign then
            self.m_sweepInfo.sType = 0xffffffff
            LuaNetSendMsg:SendXueZhanSweepSetting(0xffffffff)
        end
    end
    if self.m_sweepInfo.bufIdx == nil then
        self.m_sweepInfo.bufIdx = 0--已扫荡的buff索引（1-第三关，2-第六关...）
    end
    if self.m_sweepInfo.bufs == nil then
        self.m_sweepInfo.bufs = {}
    end
    if self.m_sweepInfo.rewards == nil then
        self.m_sweepInfo.rewards = {}
    end
end

function LXunZhanData:SelectBuff(idx)
    if idx < 1 or idx > 3 then
        return
    end
    local attr = self.m_bufs[idx]
    if attr ~= nil then
        self:AddAttr(attr.attrType,attr.attrVal)
        self.m_curStar = self.m_curStar - attr.star
    end
    --print("LXunZhanData:SelectBuff star",self.m_curStar)
    self.m_bufs = {}
end

function LXunZhanData:AddAttr(attrtype,attrval)
    local sign = false
    for i= 1,#self.m_attrs do 
        if self.m_attrs[i].type == attrtype then
            self.m_attrs[i].val = self.m_attrs[i].val + attrval
            sign = true
            break
        end
    end
    if sign then
        return
    end
    local attr = {}
    attr.type = attrtype
    attr.val = attrval
    table.insert(self.m_attrs,attr)
end

function LXunZhanData:SweepUpdate()
    local stars = {}
    local configData = JsonConfig.m_config.getDefByID(2)
    if configData ~= nil then
        stars = json.decode(configData.value)
    end
    if self.m_sweepLevelId +1 <= self.m_levelId then
        return
    end
    local val = self.m_sweepLevelId +1 - self.m_levelId
    self.m_levelId = self.m_sweepLevelId+1
    if #stars == 0 then
        return
    end
    local star = stars[#stars]
    local add = val *star
    self.m_totalStar = self.m_totalStar + add
    self.m_curStar = self.m_curStar + add
    self.m_maxLevelStar = self.m_maxLevelStar + add
    print("SweepUpdate m_curStar",self.m_curStar)
end

LFengShenStoryData = {}
LFengShenStoryData.__index = LFengShenStoryData
function LFengShenStoryData:New()
    local o = {}
    setmetatable(o, LFengShenStoryData)    
    o:ctor()
    return o
end

function LFengShenStoryData:ctor()
    self.m_chapterId = 0 --当前章节
    self.m_curLevelId = 0 --当前关卡
    self.m_cnt = 0 --剩余次数
    self.m_maxCnt = 0 --总次数
    --首通奖励状态
    self.m_firstState = 0 --首通奖励状态 1 可以领取 2 已经领取 0 不能领取
    --状态
    self.m_state = 0 --1 战斗 2 死亡 3 领取奖励 4全通状态
    --关底奖励（关底宝箱）
    self.m_giftBoxs = {}
    --通关奖励
    self.m_rewards = {}
    --关卡数据（需本地存储）
    self.m_mapChapterInfo = {}
end

--@id 章节ID，@num 关卡数量
function LFengShenStoryData:GetChapterInfo(id,num)
    if self.m_mapChapterInfo[id] == nil then
        self.m_mapChapterInfo[id] = {}
    end
    local list = self.m_mapChapterInfo[id]
    if #list == 0 then
        local roleId = LRoleDataMgr.MyHeroInfo.id
        local pUserDefault = CCUserDefault:getInstance()
        local info = pUserDefault:getStringForKey(""..roleId.."_"..id)
        local posList = string.split(info, ",")
        if posList ~= nil and #posList > 0 then     
            for i=1,#posList do
                table.insert(list,tonumber(posList[i]))
            end
        end
    end
    if #list == 0 then
        num = num or 4
        local tmp = 0
        for i= 1,num do
            local idxs = {1,2,3}
            if tmp > 0 then
                table.remove(idxs,tmp)
            end
            local pos = math.random(1,#idxs)
            table.insert(list,idxs[pos])
            tmp = idxs[pos]
        end
    end
    return list
end

function LFengShenStoryData:SetChapterInfo(id,posList)
    if id == nil or id == 0 or posList == nil or #posList == 0 then
        return
    end
    if self.m_mapChapterInfo[id] == nil then
        self.m_mapChapterInfo[id] = {}
    end
    local str = ""
    local list = self.m_mapChapterInfo[id]
    for i = 1,#posList do
        table.insert(list,posList[i])
        str = str .. posList[i]..","
    end
    str = string.sub(str,1,-2)
    local roleId = LRoleDataMgr.MyHeroInfo.id
    local pUserDefault = CCUserDefault:getInstance()
    pUserDefault:setStringForKey(""..roleId.."_"..id,str)
    pUserDefault:flush()
end


LXunBaoData = {}
LXunBaoData.__index = LXunBaoData
function LXunBaoData:New()
    local o = {}
    setmetatable(o, LXunBaoData)    
    o:ctor()
    return o
end

function LXunBaoData:ctor()
    self.m_cnt = 0 --剩余次数
    self.m_useCnt = 0 --已寻宝次数
    self.m_sec = 0 --倒计时
    self.m_oneKeySign = 0 --一键寻宝设置不弹框提示
    self.m_autoUse = 0 --一键寻宝自动使用道具
    self.m_buyCnt = 0
    self.m_records = {}--寻宝结果
end

LWorldBossData = {}
LWorldBossData.__index = LWorldBossData
function LWorldBossData:New()
    local o = {}
    setmetatable(o, LWorldBossData)    
    o:ctor()
    return o
end

function LWorldBossData:ctor()
    self.m_cnt = 0 --剩余次数
    self.m_sec = 0 --倒计时
    self.m_hurts  = {0,0}
    self.m_myRanks = {0,0}
    self.m_bossInfo = {}
    self.m_bossInfo.id = 0
    self.m_leftRanks = {}
    self.m_rightRanks = {}
    self.m_myRanks = {}
end

function LWorldBossData:InitData()
    self.m_cnt = 2 --剩余次数
    self.m_sec = 10 --倒计时
    self.m_hurts  = {100000,1000} --本帮伤害、本人伤害
    self.m_bossInfo = {}
    self.m_bossInfo.id = 50003
    self.m_leftRanks = {}
    self.m_rightRanks = {}
    self.m_myRanks = {11,0}
    for i=1,10 do
        local value = {}
        value.rank = i
        value.name = "rank1_"..i
        value.sorce = 1000000- i*1000
        value.id = i*11
        table.insert(self.m_leftRanks,value)
    end
    for i=1,20 do
        local value = {}
        value.rank = i
        value.name = "rank2_"..i
        value.sorce = 1000000- i*100
        value.id = i*15
        table.insert(self.m_rightRanks,value)
    end
end

LYouLiData = {}
LYouLiData.__index = LYouLiData
function LYouLiData:New()
    local o = {}
    setmetatable(o, LYouLiData)    
    o:ctor()
    return o
end

function LYouLiData:ctor()
    self.m_youlis = {}
    local cfgList = JsonConfig.m_youliConfig.getList()
    for i=1,#cfgList do
        local cfg = cfgList[i]
        self.m_youlis[i] = {}
        self.m_youlis[i].id = cfg.id
        self.m_youlis[i].heroId = 0
    end
end

function LYouLiData:SetData(value)
    for i=1,#self.m_youlis do
        if self.m_youlis[i].id == value.id then
            self.m_youlis[i] = value
            break
        end
    end
end

