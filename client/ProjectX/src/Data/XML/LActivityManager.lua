LActivityData = {}
LActivityData.__index = LActivityData
function LActivityData:new()
    local o = {}
    setmetatable(o,LActivityData)
    o:ctor()
    return o
end

function LActivityData:ctor()
    self.id = -1
    self.types = {}
    self.name = ""
    self.target = ""
    self.finishState = ""
    self.finishrate = 0
    self.activeVal = ""
    self.stateinfo = ""
    self.openLv = 0
    self.opentime = ""
    self.instruction = ""
    self.state = 0
    self.isFinished = false --是否完成
    self.RevardId = {} --奖励:vector<int> 
    self.overCost = 0 --一键完成需要元宝数
    self.startLev = 0 --开启VIP级别
    self.oneKeyOpenLev = 0 --一键完成开启人物等级
    self.saodangMark = 0 --是否显示扫荡按钮
    self.canSaodangTimes = 0 --可扫荡次数
    self.gotoPrivilegeCard = 0 --月卡跳转
end

LMoneyTreeData = {}
LMoneyTreeData.__index = LMoneyTreeData
function LMoneyTreeData:new()
    local o = {}
    setmetatable(o,LMoneyTreeData)
    o:ctor()
    return o
end

function LMoneyTreeData:ctor()
    self.type = 0
    self.success = 0
    self.msg = ""
    self.useNum = 0
    self.freeNum = 0
    self.maxNum = 0
    self.costType = 0
    self.costValue = 0
    self.getType = 0
    self.getValue = 0
end

LDailyBossData = {}
LDailyBossData.__index = LDailyBossData
function LDailyBossData:new()
    local o = {}
    setmetatable(o,LDailyBossData)
    o:ctor()
    return o
end

function LDailyBossData:ctor()
    --每日Boss数据
    self.m_meiriBossTime = 0                      --每日boss次数
    self.m_bossAwardStar = 0                      --挑战boss获得星数
    self.m_isShowStarButton = false

    --每日boss 奖励
    self.m_awardInfos = {}
--  totalStar = 0                          --获得总星数
--	needStar = 0                           --领取奖励需要星数
--  yuanBao = 0                            --价值XX元宝
--	drawState = 0                          --领取状态 0:未领取，1已领取
--	vector<int> itemType
--	vector<int> itemID
--	vector<int> itemNum

    --Boss信息
    self.m_bossInfos = {}
--  vecIndex         -- 回传时调用的index
--	getStar		     -- 星级
--  difficulty       -- 难度
--	monsterID        -- 怪物ID
--	dropExp          -- 经验
--  monsterName      -- 怪物名字
end

function LDailyBossData:free()
    --每日Boss数据
    self.m_meiriBossTime = 0                      --每日boss次数
    self.m_bossAwardStar = 0                      --挑战boss获得星数
    self.m_isShowStarButton = false
    --每日boss 奖励
    self.m_awardInfos = nil
    --Boss信息
    self.m_bossInfos = nil
end

LDailyBossResultData = {}
LDailyBossResultData.__index = LDailyBossResultData
function LDailyBossResultData:new()
    local o = {}
    setmetatable(o,LDailyBossResultData)
    o:ctor()
    return o
end

function LDailyBossResultData:ctor()
    --每日Boss战斗结束数据
    self.m_battleStarNum = 0     --星数 
    self.m_totalStarNum = 0      --总星数
    self.m_addStarNum = 0        --增加星数
	self.m_battleExp1 = 0        --经验1
	self.m_battleExp2 = 0        --经验2
	self.m_openUIType = -1       --1-打开每日boss面板，0-不打开每日boss面板, 2-退出副本
    self.m_itemId = 0
    self.m_itemNum = 0
end

LLiLianInfo = {}
LLiLianInfo.__index = LLiLianInfo
function LLiLianInfo:new()
    local o = {}
    setmetatable(o,LLiLianInfo)
    o:ctor()
    return o
end

function LLiLianInfo:ctor()
    --每日Boss战斗结束数据
    self.m_chapNumId = 0     --章节ID
    self.m_chapName = ""     --章节名称
    self.m_perChapNum = 0    

    --关卡数据
	self.m_chapInfos = {}
--  index
--	name
--	winFlag
--	canFight
--	lock
--	type
--	paramId --type==1,为怪物id，type==2,为职业id
end

LBoxConfig = {}
LBoxConfig.__index = LBoxConfig
function LBoxConfig:new()
    local o = {}
    setmetatable(o,LBoxConfig)
    o:ctor()
    return o
end

function LBoxConfig:ctor()
    self.m_count = 0
    self.m_itemIdNums = {}
    self.m_activeVals = {}
end

LBoxInfo = {}
LBoxInfo.__index = LBoxInfo
function LBoxInfo:new()
    local o = {}
    setmetatable(o,LBoxInfo)
    o:ctor()
    return o
end

function LBoxInfo:ctor()
    self.m_activeVal = 0
    self.m_states = {}   --0-未领取，1-领取
end

LActivityManager = LDataBase:New()
LActivityManager.__index = LActivityManager
function LActivityManager:Awake()
	self.m_pActivityDataBuff = {}
	self.m_moneyTreeData = {}
    self.m_dailyBossResultData = nil
    self.m_dailyBossData = nil
    self.m_LiLianData = {}
    self.m_boxConfig = nil
    self.m_boxInfo = nil
    self.m_xueZhanData = nil
    self.m_fengShenStory = nil
    self.m_xunBaoData = nil
    self.m_worldBossData = nil
    self.m_youliData = nil
end

function LActivityManager:Free()
	self.m_pActivityDataBuff = {}
	self.m_moneyTreeData = {}
    --self.m_dailyBossResultData = nil
    --self.m_dailyBossData = nil
    self.m_LiLianData = {}
end

function LActivityManager:YouLiFree()
    self.m_youliData = nil
end

function LActivityManager:GetYouLiData()
    if self.m_youliData == nil then
       self.m_youliData = LYouLiData:New()
    end
    return self.m_youliData
end

function LActivityManager:WorldBossFree()
    self.m_worldBossData = nil
end

function LActivityManager:GetWorldBossData()
    if self.m_worldBossData == nil then
       self.m_worldBossData = LWorldBossData:New()
    end
    return self.m_worldBossData
end

function LActivityManager:XunBaoFree()
    self.m_xunBaoData = nil
end

function LActivityManager:GetXunBaoData()
    if self.m_xunBaoData == nil then
       self.m_xunBaoData = LXunBaoData:New()
    end
    return self.m_xunBaoData
end

function LActivityManager:XueZhanFree()
    self.m_xueZhanData = nil
end

function LActivityManager:GetXueZhanData()
    if self.m_xueZhanData == nil then
	   self.m_xueZhanData = LXunZhanData:New()
    end
    return self.m_xueZhanData
end

function LActivityManager:FengShenStoryFree()
    self.m_fengShenStory = nil
end

function LActivityManager:GetFengShenStoryData()
    if self.m_fengShenStory == nil then
       self.m_fengShenStory = LFengShenStoryData:New()
    end
    return self.m_fengShenStory
end

function LActivityManager:MoneyTreeFree()
    self.m_moneyTreeData = {}
end

function LActivityManager:GetBoxConfig()
	if self.m_boxConfig == nil then
        self.m_boxConfig = LBoxConfig:new()
    end
--    self.m_boxConfig.m_count = 5
--    for i=1,5 do
--        local itemIdNums = self.m_boxConfig.m_itemIdNums
--        if itemIdNums[i] == nil then
--            itemIdNums[i] = {}
--        end
--        local items = {["itemId"] = 0,["itemNum"] = 0}
--        items.itemId = 2811+i
--        items.itemNum = 1
--        table.insert(itemIdNums[i],items)
--        self.m_boxConfig.m_activeVals[i] = i*20
--    end
    return self.m_boxConfig
end

function LActivityManager:GetBoxInfo()
	if self.m_boxInfo == nil then
        self.m_boxInfo = LBoxInfo:new()
    end
--    self.m_boxInfo.m_activeVal = 50
--    self.m_boxInfo.m_states = {1,0,0,0,0}
    return self.m_boxInfo
end

function LActivityManager:DailyBossInit()
    if self.m_dailyBossResultData == nil then
        self.m_dailyBossResultData = LDailyBossResultData:new()
    end
    if self.m_dailyBossData == nil then
        self.m_dailyBossData = LDailyBossData:new()
    end
end

function LActivityManager:FreeDailyBoss()
    self.m_dailyBossResultData = nil
    if self.m_dailyBossData ~= nil then
       self.m_dailyBossData:free()
    end
    self.m_dailyBossData = nil
end

function LActivityManager:GetDailyBossData()
    if self.m_dailyBossData == nil then
        self.m_dailyBossData = LDailyBossData:new()
    end
    return self.m_dailyBossData
end

function LActivityManager:GetDailyBossResultData()
    if self.m_dailyBossResultData == nil then
        self.m_dailyBossResultData = LDailyBossResultData:new()
    end
    return self.m_dailyBossResultData
end

function LActivityManager:Instance()
	return self
end

function LActivityManager:GetActivityData(id)
    for i=1,#self.m_pActivityDataBuff do
        if self.m_pActivityDataBuff[i].id == id then
            return self.m_pActivityDataBuff[i]
        end
    end
    return nil
end

function LActivityManager:getLeftMonopolyTimes()
    -- body
    local monopolyData = self:GetActivityData(AppDef.EActivityID.EAID_ADVANCE)
    if monopolyData == nil then
        return 0
    end

    local splitData = string.split(monopolyData.finishState, "/")
    if splitData == nil then
        return 0
    end

    local leftTimes = tonumber(splitData[2]) - tonumber(splitData[1])
    return leftTimes
end

function LActivityManager:addMonopolyPlayTimes()
    -- body
    local monopolyData = self:GetActivityData(AppDef.EActivityID.EAID_ADVANCE)
    if monopolyData == nil then
        return 0
    end

    local splitData = string.split(monopolyData.finishState, "/")
    if splitData == nil then
        return 0
    end

    local alreadyPlayTimes = tonumber(splitData[1]) + 1
    if alreadyPlayTimes > tonumber(splitData[2]) then
        alreadyPlayTimes = tonumber(splitData[2])
    end
    local finishState = alreadyPlayTimes .. "/"..splitData[2]
    monopolyData.finishState = finishState
end

function LActivityManager:GetAllData()
    return self.m_pActivityDataBuff
end

function LActivityManager:CheckType(curTypes,activityType)
    if activityType == 0  then 
--        if curType == AppDef.EActivityType.EAT_EQUIP or curType == AppDef.EActivityType.EAT_PET
--             or curType == AppDef.EActivityType.EAT_EXP or curType == AppDef.EActivityType.EAT_OTHER
--             or curType == AppDef.EActivityType.EAT_GOLD then
--             return true
--        end
        return true
    elseif curTypes ~= nil and #curTypes > 0 then          
        for i=1,#curTypes do
            if curTypes[i] == activityType then
               return true
            end
        end
    end
    return false
end

--通过分类来查询玩法数量,返回数量，玩法索引列表
function LActivityManager:GetNum(activityType)
    
    if self.m_pActivityDataBuff == nil or #self.m_pActivityDataBuff == 0 then
        return 0,{}
    end
    local num = 0

    local datas = {}
    local tempDatas = {}--未开启
    local roleLv = LRoleDataMgr.MyHeroInfo:Getlevel()
    for k,v in ipairs(self.m_pActivityDataBuff) do
        if self:CheckType(v.types,activityType) then
            num = num +1
            if v.state ~= 1 or v.openLv > roleLv or (v.isFinished ) then 
                table.insert(tempDatas,k)
            else
                table.insert(datas,k)
            end       
        end
    end
    for i=1,#tempDatas do
        table.insert(datas,tempDatas[i])
    end
    return num,datas
end

--通过分类来查询该类型玩法是否有红点
function LActivityManager:CheckRedDot(activityType)
    if self.m_pActivityDataBuff == nil or #self.m_pActivityDataBuff == 0 then
        return false
    end
    for k,v in ipairs(self.m_pActivityDataBuff) do
        if v.state == 1 and self:CheckType(v.types,activityType) then
			local amin,amax,active = self:GetActivityActiveVal(k)
			local cmin,cmax,cnt = self:GetActivityCount(k)
			if amin == 0 and amax == 0 then
				if cnt > 0 then
					return true
				end 
			end
			if cmin== 0 and cmax == 0 then
				if active > 0 then
					return true
				end 
			end
			if active > 0 then
				if cnt > 0  then
					return true
				end
			end
        end
    end
    return false
end

--通过activeVal,获得活跃数
function LActivityManager:GetActivityActiveVal(index)
    if self.m_pActivityDataBuff == nil or #self.m_pActivityDataBuff < index  then
        return 0,0,0
    end
    local temp = string.split(self.m_pActivityDataBuff[index].activeVal,'/')
    local min = tonumber(temp[1])
    local max = tonumber(temp[2])
    if max > min then
        return min,max,max-min
    end
    return min,max,0
end

--通过finishState,获得剩余次数
function LActivityManager:GetActivityCount(index)
    if self.m_pActivityDataBuff == nil or #self.m_pActivityDataBuff < index  then
        return 0,0,0
    end
    local temp = string.split(self.m_pActivityDataBuff[index].finishState,'/')
    local min = tonumber(temp[1])
    local max = tonumber(temp[2])
	if max == 999 then
		max = 0
	end
    if max > min then
        return min,max,max-min
    end
    return min, max, 0
end

--通过finishState,获得活动最大次数，0表示未开启
function LActivityManager:GetMaxCount(index)
    if self.m_pActivityDataBuff == nil or #self.m_pActivityDataBuff < index  then
        return 0
    end
    local temp = string.split(self.m_pActivityDataBuff[index].finishState,'/')
    local max = tonumber(temp[2])
    return max
end

--是否显示活跃度
function LActivityManager:IsShowPoint(index)
    if self.m_pActivityDataBuff == nil or #self.m_pActivityDataBuff < index  then
        return false
    end
    local temp = string.split(self.m_pActivityDataBuff[index].activeVal,'/')
    local max = tonumber(temp[2])
    if max == 0 then
        return false
    end
    return true
end
--function LActivityManager:UpdateRewardData(activeness,isGet)
--	self.m_pRewardDataBuff[activeness] = isGet
--end

--[[
	设置按钮的位置，其实就是给按钮排序
	状态深度值 
	正在开启 1 
	今日尚未开启 2
	非今日活动与活动已结束 3
	等级不足 4
	已完成 5
]]
--function LActivityManager:SaveState(ActData)
--	--获取状态，然后获取深度，进行插入排序
--	if ActData.m_iFrequency == ActData.m_iMAXfrequency then
--		--已完成
--		ActData.m_iState = 2
--	elseif ActData.m_iType == 2 and ActData.m_iDay == os.date("%w") and 
--		(ActData.m_iHour*3600 + ActData.m_iMin*60) + ActData.m_iLimitTime < os.date("%H")*3600 + os.date("%M")*60 then
--		--当天时间,活动时间结束
--		ActData.m_iState = 6
--	elseif ActData.m_iState == 3 and ActData.m_iType == 2 and ActData.m_iDay == os.date("%w") and 
--		(ActData.m_iHour*3600 + ActData.m_iMin*60) > os.date("%H")*3600 + os.date("%M")*60 then
--		--当天未到时间
--		ActData.m_iState = 4
--	elseif ActData.m_iState == 3 and ActData.m_iDay ~= os.date("%w") then 
--		--非当天未到
--		ActData.m_iState = 7
--	elseif ActData.m_iLevel > LRoleData:Instance():GetRealLevel()then --等级未到
--		ActData.m_iState = 5
--	else
--		ActData.m_iState = 1
--	end
--end

return LActivityManager:Awake()


