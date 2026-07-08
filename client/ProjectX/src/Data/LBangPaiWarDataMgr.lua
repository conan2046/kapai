--帮派战参赛信息
LBangPaiWarApplyInfo = {}
LBangPaiWarApplyInfo.__index = LBangPaiWarApplyInfo
function LBangPaiWarApplyInfo:New()
	local o = {}
	setmetatable(o,LBangPaiWarApplyInfo)	
	o:Init()
	return o
end

function LBangPaiWarApplyInfo:Init()
    self.bpLvflag = false
    self.bpLvStr = ""
    self.bpMemNumflag = false
    self.bpMemNumStr = ""
    self.roleLvflag = false
    self.roleLvStr = ""
    self.enterTimeflag = false
    self.enterTimeStr = ""
    self.startFlag = false
    self.timeDesc = ""
    self.desc = ""
    self.BangPaiList = {}
    --{ id | name | level | bangzhu | jifen | memCnt}
end

function LBangPaiWarApplyInfo:Delete()
	self.bpLvflag = nil
    self.bpLvStr = nil
    self.bpMemNumflag = nil
    self.bpMemNumStr = nil
    self.roleLvflag = nil
    self.roleLvStr = nil
    self.enterTimeflag = nil
    self.enterTimeStr = nil
    self.startFlag = nil
    self.timeDesc = nil
    self.desc = nil
    self.BangPaiList = nil
end


--帮派战参赛信息
LBangPaiWarTowerInfo = {}
LBangPaiWarTowerInfo.__index = LBangPaiWarTowerInfo
function LBangPaiWarTowerInfo:New()
    local o = {}
    setmetatable(o,LBangPaiWarTowerInfo)    
    o:Init()
    return o
end

function LBangPaiWarTowerInfo:Init()
    self.id = 0 --塔的Id
    self.hp = 0 --血量
    self.maxHp = 0 --最大血量
    self.leftCd = 0 --剩余时间
    self.onwerId = 0 --占领塔的帮派ID
    self.name = "" --占领塔的帮派名字
end

function LBangPaiWarTowerInfo:Delete()
    self.id = nil --塔的Id
    self.hp = nil --血量
    self.maxHp = nil --最大血量
    self.leftCd = nil --剩余时间
    self.onwerId = nil --占领塔的帮派ID
    self.name = nil --占领塔的帮派名字
end

--帮派战积分排行信息
LBangPaiWarRankInfo = {}
LBangPaiWarRankInfo.__index = LBangPaiWarRankInfo
function LBangPaiWarRankInfo:New()
	local o = {}
	setmetatable(o,LBangPaiWarRankInfo)	
	o:Init()
	return o
end

function LBangPaiWarRankInfo:Init()
    self.mybpScore = 0
    self.mybpRank = 0
    self.bpScoreRankList = {}
    --{ rak | name | score }

    self.myScore = 0
    self.myRank = 0
    self.ScoreRankList = {}
    --{ rak | name | score }
end

function LBangPaiWarRankInfo:Delete()
	self.mybpScore = nil
    self.mybpRank = nil
    self.bpScoreRankList = nil

    self.myScore = nil
    self.myRank = nil
    self.ScoreRankList = nil
end

LBangPaiWarDataMgr = LDataBase:New()
LBangPaiWarDataMgr.__index = LBangPaiWarDataMgr
function LBangPaiWarDataMgr:Awake()
	self.BangPaiWarApplyInfo = nil --帮战报名信息
    self.BangPaiWarRankInfo = nil
    self.CountDown = 0 --倒计时
    self.ActionPower = 0 --行动力
	self.BoxCountDown = 0 --宝箱倒计时
    self.BangPaiWarTowerUIInfo = nil --塔的信息
    self.BPWTowerRank = nil --占塔排行榜
end

function LBangPaiWarDataMgr:Free()
	self.BangPaiWarApplyInfo = nil
    self.BangPaiWarRankInfo = nil
    self.CountDown = nil
    self.ActionPower = nil
	self.BoxCountDown = nil
    self.BangPaiWarTowerUIInfo = nil --塔的信息
    self.BPWTowerRank = nil --占塔排行榜
end

function LBangPaiWarDataMgr:GetWarData()
	if self.BangPaiWarApplyInfo == nil then
        self.BangPaiWarApplyInfo = LBangPaiWarApplyInfo:New()
    end
    return self.BangPaiWarApplyInfo
end

function LBangPaiWarDataMgr:GetWarRankData()
	if self.BangPaiWarRankInfo == nil then
        self.BangPaiWarRankInfo = LBangPaiWarRankInfo:New()
    end
    return self.BangPaiWarRankInfo
end



function LBangPaiWarDataMgr:GetWarRankData()
    if self.BPWTowerRank == nil then
        self.BPWTowerRank = {}
    end
    return self.BPWTowerRank
end

function LBangPaiWarDataMgr:getWarTowerInfo( ... )
    -- body
    if self.BangPaiWarTowerUIInfo == nil then
        self.BangPaiWarTowerUIInfo = {}
    end
    return self.BangPaiWarTowerUIInfo
end

function LBangPaiWarDataMgr:settWarTowerInfo( data )
    -- body
    self.BangPaiWarTowerUIInfo = data
end

function LBangPaiWarDataMgr:initBPWTowerRankData()
    -- body
    local bpwTowerUIInfo = self:getWarTowerInfo()
    local bpwTowerRank = self:GetWarRankData()
    bpwTowerRank = {}
    for i=1, #bpwTowerUIInfo do
        if bpwTowerUIInfo[i].onwerId > 0 then
            if bpwTowerRank[bpwTowerUIInfo[i].onwerId] == nil then
                bpwTowerRank[bpwTowerUIInfo[i].onwerId] = 1
            else
                bpwTowerRank[bpwTowerUIInfo[i].onwerId] = bpwTowerRank[bpwTowerUIInfo[i].onwerId] + 1
            end
        end
    end

    local info = self:GetWarRankData()
    for i=1, #info.bpScoreRankList do
        local data = info.bpScoreRankList[i]
        print("ShowRankUI =========>", data.bpId)
        if bpwTowerRank[data.bpId] ~= nil then
            data.towerNum = bpwTowerRank[data.bpId]
        end
    end

    local function sortFuc(m1, m2)
        -- body
        if m1.towerNum > m2.towerNum then
            return bpwTowerRank
        elseif m1.towerNum == m2.towerNum then
            return m1.score > m2.score
        else
            return false
        end
    end
    table.sort( info.bpScoreRankList, sortFuc )
    --重新设置排行
    for i=1, #info.bpScoreRankList do
        local value = info.bpScoreRankList[i]
        value.rak = i
    end
--    dump(info, "rankData")

end

return LBangPaiWarDataMgr:Awake()




