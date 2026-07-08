--唯我独仙
LGroupData = {}
LGroupData.__index = LGroupData

function LGroupData:New()
	local o = {}
	setmetatable(o,LGroupData)	
	o:Init()
	return o
end

function LGroupData:Init()
	self.myScore = 0
	self.myRank = 0
	self.boxId = 0
	self.boxText = ""
	self.groupId = 0
	self.isFreeRefersh = false
	self.leftTimes = 0
	self.maxTimes = 0
	self.coolTime = 0
	self.cost = 0
	self.groupHeroInfo = {} --玩家信息
--	vector<HeroData> groupHeroInfo;
end

function LGroupData:Reset()
	self.myScore = 0
	self.myRank = 0
	self.boxId = 0
	self.boxText = ""
	self.groupId = 0
	self.isFreeRefersh = false
	self.leftTimes = 0
	self.maxTimes = 0
	self.coolTime = 0
	self.cost = 0
	self.groupHeroInfo = {} --玩家信息
end

function LGroupData:Delete()
	self.myScore = nil
	self.myRank = nil
	self.boxId = nil
	self.boxText = nil
	self.groupId = nil
	self.isFreeRefersh = nil
	self.leftTimes = nil
	self.maxTimes = nil
	self.coolTime = nil
	self.cost = nil
	self.groupHeroInfo = nil --玩家信息
end



--
GroupRankInfo = {}
GroupRankInfo.__index = GroupRankInfo

function GroupRankInfo:New()
	local o = {}
	setmetatable(o,GroupRankInfo)	
	o:Init()
	return o
end

function GroupRankInfo:Init()
	self.id = 0
	self.name = ""
	self.score = 0
end

function GroupRankInfo:Delete()
	self.id = nil
	self.name = nil
	self.score = nil
end


--
MatchData = {}
MatchData.__index = MatchData

function MatchData:New()
	local o = {}
	setmetatable(o, MatchData)	
	o:Init()
	return o
end

function MatchData:Init()
	self.id = 0
	self.name = ""
	self.state = 0  --1 查看 2可投注 3 已经投注 4时间没到 灰色
end

function MatchData:Delete()
	self.id = nil
	self.name = nil
	self.state = nil
end