--帮派成员信息
LFactionMemberInfo = {}
LFactionMemberInfo.__index = LFactionMemberInfo
function LFactionMemberInfo:New()
	local o = {}
	setmetatable(o,LFactionMemberInfo)	
	o:ctor()
	return o
end

function LFactionMemberInfo:ctor()
	self.roleId = 0
	self.roleLevel = 0
	self.roleWeiJie = 0		-- 位阶
	self.roleHead = 0	-- 头像
	self.roleName = ""		-- 角色名
	self.gongXian = 0			-- 贡献
	self.sex = 0 --性别
	self.zhandouli = 0 --战斗力
	self.lastOnlineTime = 0		-- 最后在线时间
	self.activity = 0		-- 活跃度
end

function LFactionMemberInfo:Delete()
	self.roleId = nil
	self.roleLevel = nil
	self.roleWeiJie = nil		-- 位阶
	self.roleHead = nil	-- 头像
	self.roleName = nil		-- 角色名
	self.gongXian = nil			-- 贡献
	self.lastOnlineTime = nil		-- 最后在线时间
	self.activity = nil		-- 活跃度
end

function LFactionMemberInfo:GetroleId() return self.roleId end
function LFactionMemberInfo:GetroleLevel() return self.roleLevel end
function LFactionMemberInfo:GetroleWeiJie() return self.roleWeiJie end		-- 位阶
function LFactionMemberInfo:GetRoleHead() return self.roleHead end	-- 头像
function LFactionMemberInfo:GetroleName() return self.roleName end		-- 角色名
function LFactionMemberInfo:GetgongXian() return self.gongXian end			-- 贡献
function LFactionMemberInfo:GetlastOnlineTime() return self.lastOnlineTime end		-- 最后在线时间


--帮派邀请信息
LFactionInviteInfo = {}
LFactionInviteInfo.__index = LFactionInviteInfo
function LFactionInviteInfo:New()
	local o = {}
	setmetatable(o,LFactionInviteInfo)	
	o:ctor()
	return o
end

function LFactionInviteInfo:ctor()
	self.bangPaiName = ""
	self.invideRoleId = 0
	self.bangPaiId = 0
	self.invtName = ""
	self.invtProfessional = 0
	self.invtSex = 0
	self.invtLevel = 0
end

function LFactionInviteInfo:Delete()
	self.bangPaiName = nil
	self.invideRoleId = nil
	self.bangPaiId = nil
	self.invtName = nil
	self.invtProfessional = nil
	self.invtSex = nil
	self.invtLevel = nil
end

--帮派申请信息
LApplayInfo = {}
LApplayInfo.__index = LApplayInfo
function LApplayInfo:New()
	local o = {}
	setmetatable(o,LApplayInfo)	
	o:ctor()
	return o
end

function LApplayInfo:ctor()
	self.roleId = 0
	self.level = 0
	self.zhandouli = 0
	self.name = ""
	self.professional = 0
	self.sex = 0
end

function LApplayInfo:Delete()
	self.roleId = nil
	self.level = nil
	self.zhandouli = nil
	self.name = nil
	self.professional = nil
	self.sex = nil
end

LFactionTaskInfo = {}
LFactionTaskInfo.__index = LFactionTaskInfo
function LFactionTaskInfo:New()
	local o = {}
	setmetatable(o,LFactionTaskInfo)	
	o:ctor()
	return o
end

function LFactionTaskInfo:ctor()
	self.taskType = 0           --任务类型1  种植 2  浇水 3  除虫 4  偷窃
    self.taskAward = ""
    self.totalTimes = 0
    self.curTimes = 0
    self.getAward = false           --是否已领取奖励
end

function LFactionTaskInfo:Delete()
	self.taskType = nil           --任务类型1  种植 2  浇水 3  除虫 4  偷窃
    self.taskAward = nil
    self.totalTimes = nil
    self.curTimes = nil
    self.getAward = nil           --是否已领取奖励
end

--帮派信息
LFactionInfo = {}
LFactionInfo.__index = LFactionInfo

function LFactionInfo:New()
	local o = {}
	setmetatable(o,LFactionInfo)	
	o:ctor()
	return o
end

function LFactionInfo:ctor()
	self.id = 0
	self.rank = 0			    -- 帮派排名
	self.bangZhuName = ""
	self.name = ""
	self.gongGao = ""
	self.level = 0
	self.memberNum = 0
	self.isInAskJoin = 0		-- 是否已申请入帮
	self.MaxMemberNum = 0		-- 帮派人数上限
	self.selfBangGong = 0		-- 个人帮贡
	self.selfRank = AppDef.FactionInfo.BPRT_NONE			-- 个人位阶
    self.Exp = 0                --帮派经验
    self.MaxExp = 0             --经验上限 
    self.plantNum = 0           --植物数量
	self.isExistApply = 0       --是否存在入帮申请 = 0
	self.isShowBPName = 0       --是否显示帮派名称;
	self.picId = 0                --帮派图标
	self.bpMoney = 0		    -- 帮派资金
	self.isGetedAward = 1       --是否已领取职位奖励
	self.isExistActAward = 0       --是否存在活动奖励
	self.limitLevel = 0--限制自动入帮等级
	self.selfActivity = 0--个人活跃度
	self.totalActivity = 0--总活跃度
	self.lvLimit = 0--入帮等级
	self.kejiInfo = {}
end

function LFactionInfo:Reset()
    self.id = 0
    self.rank = 0               -- 帮派排名
    self.bangZhuName = ""
    self.name = ""
    self.gongGao = ""
    self.level = 0
    self.memberNum = 0
    self.isInAskJoin = 0        -- 是否已申请入帮
    self.MaxMemberNum = 0       -- 帮派人数上限
    self.selfBangGong = 0       -- 个人帮贡
    self.selfRank = AppDef.FactionInfo.BPRT_NONE            -- 个人位阶
    self.Exp = 0                --帮派经验
    self.MaxExp = 0             --经验上限 
    self.plantNum = 0           --植物数量
    self.isExistApply = 0       --是否存在入帮申请 = 0
    self.isShowBPName = 0       --是否显示帮派名称;
    self.picId = 0                --帮派图标
    self.bpMoney = 0		    -- 帮派资金
	self.isGetedAward = 1       --是否已领取职位奖励
	self.isExistActAward = 0       --是否存在活动奖励
	self.limitLevel = 0--限制自动入帮等级
	self.selfActivity = 0--个人活跃度
	self.totalActivity = 0--总活跃度
	self.kejiInfo = {}
end

function LFactionInfo:Delete()
	self.id = nil
	self.rank = nil			    -- 帮派排名
	self.bangZhuName = nil
	self.name = nil
	self.gongGao = nil
	self.level = nil
	self.memberNum = nil
	self.isInAskJoin = nil		-- 是否已申请入帮
	self.MaxMemberNum = nil		-- 帮派人数上限
	self.selfBangGong = nil		-- 个人帮贡
	self.selfRank = nil			-- 个人位阶
    self.Exp = nil                --帮派经验
    self.MaxExp = nil             --经验上限 
    self.plantNum = nil           --植物数量
	self.isExistApply = nil       --是否存在入帮申请 = 0
	self.isShowBPName = nil       --是否显示帮派名称;
	self.picId = nil                --帮派图标
    self.bpMoney = nil		    -- 帮派资金
	self.isGetedAward = nil       --是否存在职位奖励
	self.isExistActAward = nil       --是否存在活动奖励
	self.limitLevel = nil--限制自动入帮等级
	self.selfActivity = nil--个人活跃度
	self.totalActivity = nil--总活跃度
	self.kejiInfo = nil     --帮派科技
end
function LFactionInfo:Getid() return self.id end
function LFactionInfo:Getrank() return self.rank end
function LFactionInfo:GetbangZhuName() return self.bangZhuName end
function LFactionInfo:Getname() return self.name end
function LFactionInfo:GetgongGao() return self.gongGao end
function LFactionInfo:Getlevel() return self.level end
function LFactionInfo:GetmemberNum() return self.memberNum end
function LFactionInfo:GetisInAskJoin() return self.isInAskJoin end
function LFactionInfo:GetMaxMemberNum() return self.MaxMemberNum end
function LFactionInfo:GetselfBangGong() return self.selfBangGong end
function LFactionInfo:SetselfBangGong(value)
	if self.selfBangGong ~= value then
		self.selfBangGong = value
		Utils:SendMsg(LUIRoleDataChangeEvent.BangGongChanged)
	end
end

function LFactionInfo:GetselfRank() return self.selfRank end
function LFactionInfo:GetExp() return self.Exp end
function LFactionInfo:GetMaxExp() return self.MaxExp end
function LFactionInfo:GetplantNum() return self.plantNum end
function LFactionInfo:GetisExistApply() return self.isExistApply end
function LFactionInfo:GetisShowBPName() return self.isShowBPName end

--帮战信息
LFactionBattleInfo = {}
LFactionBattleInfo.__index = LFactionBattleInfo
function LFactionBattleInfo:New()
	local o = {}
	setmetatable(o,LFactionBattleInfo)	
	o:ctor()
	return o
end

function LFactionBattleInfo:ctor()
	self.levelFlag = 0         --表示显示的颜色 0 红 1绿
	self.bpLvLimit = ""      --帮战等级限制
	self.memberFlag = 0	       --表示显示的颜色 0 红 1绿
	self.bpMenLimit = ""     --帮战帮派成员数量限制
	self.rolelevelFlag = 0     --表示显示的颜色 0 红 1绿
	self.bpRoleLvLimit = 0  --帮战角色等级限制
	self.entertimeFlag = 0     --表示显示的颜色 0 红 1绿
	self.bpEnterTimeLimit = ""--进入时间限制
	self.timeFlag = 0          --时间描述颜色
	self.bpTimeDesc = ""     --时间描述
	self.bpBattleNotice = "" --帮战提示

	self.bpid = {}      --帮派id
	self.bpname = {} --帮派名称
	self.bplevel = {}   --帮派等级
	self.bpmaster = {}--帮主名称
	self.bpscore = {}	--帮派积分
	self.bpgroup = {}     --跨服帮战分组
end

function LFactionBattleInfo:Delete()
	self.levelFlag = nil         --表示显示的颜色 0 红 1绿
	self.bpLvLimit = nil      --帮战等级限制
	self.memberFlag = nil	       --表示显示的颜色 0 红 1绿
	self.bpMenLimit = nil     --帮战帮派成员数量限制
	self.rolelevelFlag = nil     --表示显示的颜色 0 红 1绿
	self.bpRoleLvLimit = nil  --帮战角色等级限制
	self.entertimeFlag = nil     --表示显示的颜色 0 红 1绿
	self.bpEnterTimeLimit = nil--进入时间限制
	self.timeFlag = nil          --时间描述颜色
	self.bpTimeDesc = nil     --时间描述
	self.bpBattleNotice = nil --帮战提示
	self:clear()
	self.bpid = nil      --帮派id
	self.bpname = nil --帮派名称
	self.bplevel = nil   --帮派等级
	self.bpmaster = nil--帮主名称
	self.bpscore = nil	--帮派积分
	self.bpgroup = nil     --跨服帮战分组
end
function LFactionBattleInfo:clear()
	self.bpid = {}
	self.bpname = {}
	self.bplevel = {}
	self.bpmaster = {}
	self.bpscore = {}
	self.bpgroup = {}
end


--帮派积分榜
LFactionBattleScoreInfo = {}
LFactionBattleScoreInfo.__index = LFactionBattleScoreInfo
function LFactionBattleScoreInfo:New()
	local o = {}
	setmetatable(o,LFactionBattleScoreInfo)	
	o:ctor()
	return o
end

function LFactionBattleScoreInfo:ctor()
	self.mybpScore = 0		--本帮积分
	self.mybpRank = 0		--本帮排名
	self.myScore = 0		--我的积分
	self.myRank = 0			--我的排名
	self.bpRank = {} --帮派排名
	self.bpName = {}--帮派名字
	self.bpScore = {}--帮派积分
	self._rank = {}	--玩家排名
	self._name = {}--玩家名字
	self._score = {}	--玩家积分 
end

function LFactionBattleScoreInfo:Delete()
	self.mybpScore = nil		--本帮积分
	self.mybpRank = nil		--本帮排名
	self.myScore = nil		--我的积分
	self.myRank = nil			--我的排名
	self:clear()
	self.bpRank = nil --帮派排名
	self.bpName = nil--帮派名字
	self.bpScore = nil--帮派积分
	self._rank = nil	--玩家排名
	self._name = nil--玩家名字
	self._score = nil	--玩家积分 
end
function LFactionBattleScoreInfo:clear()
	self.bpRank = {}
	self.bpName = {}
	self.bpScore = {}
	self._rank = {}
	self._name = {}
	self._score = {}
end


--种植地块简要信息
LPlantCellBrief = {}
LPlantCellBrief.__index = LPlantCellBrief
function LPlantCellBrief:New()
	local o = {}
	setmetatable(o,LPlantCellBrief)	
	o:ctor()
	return o
end

function LPlantCellBrief:ctor()
	self.treeName = ""       --种植植物名字
    self.state = 0          --状态
    self.leftTimes = 0      --剩余时间
end

function LPlantCellBrief:Delete()
	self.treeName = nil       --种植植物名字
    self.state = nil          --状态
    self.leftTimes = nil      --剩余时间
end

--种植地块信息
LPlantCell = {}
LPlantCell.__index = LPlantCell
function LPlantCell:New()
	local o = {}
	setmetatable(o,LPlantCell)	
	o:ctor()
	return o
end

function LPlantCell:ctor()
	self.AreaIndex = 0      --所属区域索引
    self.Index = 0          --索引
    self.ItemId = 0         --种子ID
    self.RoleId = 0         --角色ID
    self.RoleName = ""       --角色名称
    self.Quality = 0        --品质
    self.State = 0          --状态
    self.StoleNum = 0       --已偷次数
    self.StealMax = 0       --最大可偷次数
    self.RipeTime = 0       --成熟时间
    self.TotalTime = 0      --总时间
    self.TreeName = ""       --树名称
    self.PicId = 0          --图片ID
    self.GainType = 0       --收获物品类型(1-金币 2-元宝 3-物品)
    self.GainItemId = 0     --收获物品id
    self.GainValue = 0      --收获物品数量
    self.MyCanStealNum = 0  --自己可偷取次数
    self.IsOpened = false       --是否开垦
    self.OpenLevel = 0      --开启等级（帮派等级）
end

function LPlantCell:Delete()
	self.AreaIndex = nil      --所属区域索引
    self.Index = nil          --索引
    self.ItemId = nil         --种子ID
    self.RoleId = nil         --角色ID
    self.RoleName = nil       --角色名称
    self.Quality = nil        --品质
    self.State = nil          --状态
    self.StoleNum = nil       --已偷次数
    self.StealMax = nil       --最大可偷次数
    self.RipeTime = nil       --成熟时间
    self.TotalTime = nil      --总时间
    self.TreeName = nil       --树名称
    self.PicId = nil          --图片ID
    self.GainType = nil       --收获物品类型(1-金币 2-元宝 3-物品)
    self.GainItemId = nil     --收获物品id
    self.GainValue = nil      --收获物品数量
    self.MyCanStealNum = nil  --自己可偷取次数
    self.IsOpened = false       --是否开垦
    self.OpenLevel = nil      --开启等级（帮派等级）
end

function LPlantCell:IsRipe() return bit._and(self.State, 0x01) == 0x01 end
function LPlantCell:IsNeedWater() return bit._and(self.State , 0x02) == 0x02 end 
function LPlantCell:IsNeedBug() return bit._and(self.State, 0x04) == 0x04 end
function LPlantCell:IsCanRemove() return bit._and(self.State, 0x08) == 0x08 end

--种植区域信息
LPlantArea = {}
LPlantArea.__index = LPlantArea
function LPlantArea:New()
	local o = {}
	setmetatable(o,LPlantArea)	
	o:ctor()
	return o
end

function LPlantArea:ctor()
	self.Index = 0          --索引
    self.CellMaxSize = 0    --最大块数
    self.CellSize = 0       --可用块数
    self.ColumnNum = 0      --每行最大块数
    self.Level = 0          --等级
    self.OpenLevel = 0      --开启等级
    self.SpecialType = 0    --特殊类别(1-特殊菜地 0-普通菜地)
    self.VecPlantData = {}--vector<PlantCell>   --种植数据
end

function LPlantArea:Delete()
	self.Index = nil          --索引
    self.CellMaxSize = nil    --最大块数
    self.CellSize = nil       --可用块数
    self.ColumnNum = nil      --每行最大块数
    self.Level = nil          --等级
    self.OpenLevel = nil      --开启等级
    self.SpecialType = nil    --特殊类别(1-特殊菜地 0-普通菜地)
    local num = #self.VecPlantData
    for i = 1, num do
    	self.VecPlantData[i]:Delete()
    	self.VecPlantData[i] = nil
    end
    self.VecPlantData = nil

end

--种植护卫信息
LPlantGuard = {}
LPlantGuard.__index = LPlantGuard
function LPlantGuard:New()
	local o = {}
	setmetatable(o,LPlantGuard)	
	o:ctor()
	return o
end

function LPlantGuard:ctor()
	self.FactionId = 0      --帮派ID
    self.AreaIndex = 0      --所属区块
    self.OpenLevel = 0      --开启等级
    self.Desc = ""

    self.IsBriefInfo = false    --是否仅包含简要信息
    self.IsDetailInfo = false   --是否包含详细信息
    self.DetailInfo = nil     --角色信息
end

function LPlantGuard:Delete()
	self.FactionId = nil      --帮派ID
    self.AreaIndex = nil      --所属区块
    self.OpenLevel = nil      --开启等级
    self.Desc = nil

    self.IsBriefInfo = nil    --是否仅包含简要信息
    self.IsDetailInfo = nil   --是否包含详细信息
    self.DetailInfo = nil     --角色信息
end

--帮派神树信息
LPlantGodTree = {}
LPlantGodTree.__index = LPlantGodTree
function LPlantGodTree:New()
	local o = {}
	setmetatable(o,LPlantGodTree)	
	o:ctor()
	return o
end

function LPlantGodTree:ctor()
	self.FactionId = 0                  --帮派Id
    self.TreeExp = 0                    --帮派产出经验
    self.MaxTreeExp = 0                 --最大产出经验
    self.PrayExp = 0                    --祈福经验
    self.RobbedTimes = 0                --被掠夺次数
    self.MaxRobbedTimes = 0             --最大被掠夺次数
    self.RobbedExp = 0                  --掠夺损失经验
    self.PrayCost = 0                   --祈福消耗的元宝数
    self.LeftYBPrayTimes = 0            --剩余元宝祈福次数
    self.LeftNormalPrayTimes = 0        --剩余普通祈福次数
    self.RipeTimeString = ""             --成熟时间
    self.RobTimeString = ""              --掠夺时间
    self.VecLog = {}                    --记录信息
end

function LPlantGodTree:Reset()
    self.FactionId = 0                  --帮派Id
    self.TreeExp = 0                    --帮派产出经验
    self.MaxTreeExp = 0                 --最大产出经验
    self.PrayExp = 0                    --祈福经验
    self.RobbedTimes = 0                --被掠夺次数
    self.MaxRobbedTimes = 0             --最大被掠夺次数
    self.RobbedExp = 0                  --掠夺损失经验
    self.PrayCost = 0                   --祈福消耗的元宝数
    self.LeftYBPrayTimes = 0            --剩余元宝祈福次数
    self.LeftNormalPrayTimes = 0        --剩余普通祈福次数
    self.RipeTimeString = ""             --成熟时间
    self.RobTimeString = ""              --掠夺时间
    if self.VecLog then
    	for k,v in pairs(self.VecLog) do
    		self.VecLog[k] = nil
    	end
    end
end

function LPlantGodTree:Delete()
	self.FactionId = nil                  --帮派Id
    self.TreeExp = nil                    --帮派产出经验
    self.MaxTreeExp = nil                 --最大产出经验
    self.PrayExp = nil                    --祈福经验
    self.RobbedTimes = nil                --被掠夺次数
    self.MaxRobbedTimes = nil             --最大被掠夺次数
    self.RobbedExp = nil                  --掠夺损失经验
    self.PrayCost = nil                   --祈福消耗的元宝数
    self.LeftYBPrayTimes = nil            --剩余元宝祈福次数
    self.LeftNormalPrayTimes = nil        --剩余普通祈福次数
    self.RipeTimeString = nil             --成熟时间
    self.RobTimeString = nil              --掠夺时间
    if self.VecLog then
    	for k,v in pairs(self.VecLog) do
    		self.VecLog[k] = nil
    	end
    	self.VecLog = nil                    --记录信息
    end
end

--帮派领地基本信息
LFactionZoneInfo = {}
LFactionZoneInfo.__index = LFactionZoneInfo
function LFactionZoneInfo:New()
	local o = {}
	setmetatable(o,LFactionZoneInfo)	
	o:ctor()
	return o
end

function LFactionZoneInfo:ctor()
	self.GodTreeLevel = 0               --神树等级
    self.PrayTimes = 0                  --神树祈福次数
    self.GuardNums = 0                  --护卫栏数量
    self.MaxFields = 0                 --剩余地块
    self.LeftFields = 0                --已种植地块
   	self.VecLog = {}                     --记录信息
	self.VecFileds = {}             --地块信息
end

function LFactionZoneInfo:Reset()
    self.GodTreeLevel = 0               --神树等级
    self.PrayTimes = 0                  --神树祈福次数
    self.GuardNums = 0                  --护卫栏数量
    self.MaxFields = 0                 --剩余地块
    self.LeftFields = 0                --已种植地块
    self.VecLog = {}                     --记录信息
    local num = #self.VecFileds
    for i = 1, num do
        self.VecFileds[i]:Delete()
        self.VecFileds[i] = nil
    end
    self.VecFileds = {}             --地块信息
end

function LFactionZoneInfo:Delete()
	self.GodTreeLevel = nil               --神树等级
    self.PrayTimes = nil                  --神树祈福次数
    self.GuardNums = nil                  --护卫栏数量
    self.MaxFields = nil                --剩余地块
    self.LeftFields = nil                --已种植地块
   	self.VecLog = nil                     --记录信息
   	local num = #self.VecFileds
   	for i = 1, num do
   		self.VecFileds[i]:Delete()
   		self.VecFileds[i] = nil
   	end
	self.VecFileds = nil
end

--帮派领地基本信息
LFactionZoneLog = {}
LFactionZoneLog.__index = LFactionZoneLog
function LFactionZoneLog:New()
	local o = {}
	setmetatable(o,LFactionZoneLog)	
	o:ctor()
	return o
end

function LFactionZoneLog:ctor()
	self.type = 0               --类型
    self.date = ""                  --日期
    self.log = ""                  --描述
end

function LFactionZoneLog:Delete()
	self.type = nil               --类型
    self.date = nil                  --日期
    self.log = nil                 --描述
end

--帮派章节信息
LFactionChapterData = {}
LFactionChapterData.__index = LFactionChapterData
function LFactionChapterData:New()
	local o = {}
	setmetatable(o,LFactionChapterData)	
	o:ctor()
	return o
end

function LFactionChapterData:ctor()
	self.id = 0
    self.complete = 0
    self.copyNum = 0
    self.copyArr = {}
end

function LFactionChapterData:InitFromServer(stream)
	self.id = stream:ReadInt();
	self.complete = stream:ReadByte();
	self.copyNum = stream:ReadByte();
	self.copyArr = {}
	for i = 1, self.copyNum do
		local data = LFactionCopyData:New()
		data:InitFromServer(stream)
		table.insert(self.copyArr,data)
	end
end

-- function LFactionChapterData:ReadFromServer(stream)
-- 	self.id = stream:ReadInt();
-- 	self.complete = stream:ReadByte();
-- 	self.copyNum = stream:ReadByte();
-- 	self.copyArr = {}
-- 	for i = 1, self.copyNum do
-- 		local data = LFactionCopyData:New()
-- 		data:ReadFromServer(stream)
-- 		table.insert(self.copyArr,data)
-- 	end
-- end

function LFactionChapterData:OpenFromServer(fid, stream)
	self.id = fid;
	self.complete = 0;
	self.copyNum = stream:ReadByte();
	self.copyArr = {}
	for i = 1, self.copyNum do
		local data = LFactionCopyData:New()
		data:OpenFromServer(stream)
		table.insert(self.copyArr,data)
	end
end

-- function LFactionChapterData:UpdateFromServer(stream)
-- 	self.id = stream:ReadInt();
-- 	self.complete = stream:ReadByte();
-- 	self.copyNum = stream:ReadByte();
-- 	self.copyArr = {}
-- 	for i = 1, self.copyNum do
-- 		local data = LFactionCopyData:New()
-- 		data:ReadFromServer(stream)
-- 		table.insert(self.copyArr,data)
-- 	end
-- end

function LFactionChapterData:GetCopyData(cid)
	for i = 1, self.copyNum do
		if self.copyArr[i].id == cid then
			return self.copyArr[i]
		end
	end
	return nil
end

function LFactionChapterData:IsComplete()
	if self.complete == 0 then
		return false;
	else
		return true
	end
end

function LFactionChapterData:HasReward()
	for i = 1, self.copyNum do
		if self.copyArr[i]:HasReward() then
			return true
		end
	end
	return false;
end

function LFactionChapterData:GetHpProgress()
	local curHp = 0;
	local maxHp = 0;
	-- local list = JsonConfig.m_stageNodeByMapidDict[self.id];
	-- local idArr = {}

	for i = 1, self.copyNum do
		-- idArr[self.copyArr[i].id] = true;
		curHp = curHp + self.copyArr[i]:GetCurHp();
		maxHp = maxHp + self.copyArr[i]:GetMaxHp();
	end
	-- for k, v in pairs(list) do
	-- 	if idArr[k] == nil then
	-- 		local fightBaseData = JsonConfig.m_vecFightConfig.getDefByID(v.fightID);
	-- 		if fightBaseData then
	-- 			for i = 1, 5 do
	-- 				if fightBaseData["index" .. i] > 0 then
	-- 					local monsterData = LDataConstMgr:GetMonsterData(fightBaseData["index" .. i]);
	-- 					if monsterData then
	-- 						curHp = curHp + monsterData.qixue;
	-- 						maxHp = maxHp + monsterData.qixue;
	-- 					end
	-- 				end
	-- 			end
	-- 		end
	-- 	end
	-- end
	return math.floor(curHp * 100 / maxHp)
end

function LFactionChapterData:GetProgress()
	--[[
	章节里面每个副本的最大血量相差太大，按四舍五入血量算有可能打完2个副本后进度还有0%。
	经沟通，按照完成度来算，四个副本，完成一个就是25%，完成2个就是50%
	]]
	-- local curHp = 0;
	-- local maxHp = 0;
	-- local list = JsonConfig.m_stageNodeByMapidDict[self.id];
	-- local idArr = {}
	local completeNum = 0
	for i = 1, self.copyNum do
		-- idArr[self.copyArr[i].id] = true;
		if self.copyArr[i]:IsComplete() == true then
			completeNum = completeNum + 1;
		end
		-- curHp = curHp + self.copyArr[i]:GetCurHp();
		-- maxHp = maxHp + self.copyArr[i]:GetMaxHp();
	end
	return math.floor(completeNum * 100 / self.copyNum)
	-- --print("self.copyNum",self.copyNum)
	-- dump(idArr,"idArr")
	-- dump(list,"list")
	-- for k, v in pairs(list) do
	-- 	--print("k",k)
	-- 	if idArr[k] == nil then
	-- 		--print("v.fightID",v.fightID)
	-- 		local fightBaseData = JsonConfig.m_vecFightConfig.getDefByID(v.fightID);
	-- 		if fightBaseData then
	-- 			for i = 1, 5 do
	-- 				if fightBaseData["index" .. i] > 0 then
	-- 					local monsterData = LDataConstMgr:GetMonsterData(fightBaseData["index" .. i]);
	-- 					if monsterData then
	-- 						curHp = curHp + monsterData.qixue;
	-- 						maxHp = maxHp + monsterData.qixue;
	-- 					end
	-- 				end
	-- 			end
	-- 		end
	-- 	end
	-- end
	-- return 100 - math.floor(curHp * 100 / maxHp)
end

function LFactionChapterData:Delete()
	self.id = 0
    self.complete = 0
    self.copyNum = 0
end

LFactionCopyData = {}
LFactionCopyData.__index = LFactionCopyData
function LFactionCopyData:New()
	local o = {}
	setmetatable(o,LFactionCopyData)
	o:ctor()
	return o
end

function LFactionCopyData:ctor()
	--copyId  complete   monsterNum ( zhenfaPos  leftHp   maxHp  )

	self.id = 0
    self.complete = 0
    self.monsterNum = 0
    self.fightInfo = {}
    self.firstRankName = ""
    self.rankNum = 0
    self.rewardFlag = 0
end

function LFactionCopyData:IsComplete()
	if self.complete == 0 then
		return false
	else
		return true
	end
end


function LFactionCopyData:HasReward()
	if self.rewardFlag == 1 then
		return true
	else
		return false
	end
end

function LFactionCopyData:GetHpProgress()
	local curHp = self:GetCurHp()
	local maxHp = self:GetMaxHp();
	return math.floor(curHp * 100 / maxHp);
end

function LFactionCopyData:GetProgress()
	local curHp = self:GetCurHp()
	local maxHp = self:GetMaxHp();
	--curHp = maxHp - curHp;
	return 100 - math.floor(curHp * 100 / maxHp);
end

function LFactionCopyData:GetCurHp()
	local value = 0;
	for i = 1, self.monsterNum do
		local data = self.fightInfo[i]
		value = value + data.leftHp
	end
	-- --print("GetCurHp",value)
	return value;
end

function LFactionCopyData:GetMaxHp()
	local value = 0;
	for i = 1, self.monsterNum do
		local data = self.fightInfo[i]
		value = value + data.maxHp
	end
	--print("GetMaxHp",value)
	return value;
end

function LFactionCopyData:CanGetReward()
	if self.rewardFlag == 1 then
		return true
	end
	return false
end

function LFactionCopyData:OpenFromServer(stream)
	--opyId  complete   monsterNum ( zhenfaPos  leftHp   maxHp  )
	self.id = stream:ReadInt();
	local baseData = JsonConfig.m_stageNodeConfig.getDefByID(self.id);
	local fightBaseData = JsonConfig.m_vecFightConfig.getDefByID(baseData.fightID);
	-- dump(fightBaseData,"fightBaseData")
	self.complete = 0;
	self.rewardFlag = 0--0 不可领取 1 可领取 2 已领取
	self.zhenfaId = fightBaseData.zhenfa[1];
	self.monsterNum = stream:ReadByte();
	--print("self.monsterNum",self.monsterNum);
	self.fightInfo = {}
	for i = 1, self.monsterNum do
		local data = {}
		data.fightPos = stream:ReadByte();
		--print("data.fightPos",data.fightPos);
		data.leftHp = stream:ReadULongInt();
		--print("data.leftHp",data.leftHp);
		data.id = fightBaseData["index" .. data.fightPos];
		local monsterData = LDataConstMgr:GetMonsterData(data.id);
		data.maxHp = monsterData.qixue;
		table.insert(self.fightInfo,data)
	end
	self.firstRankName = "";
end


function LFactionCopyData:InitFromServer(stream)
	--opyId  complete   monsterNum ( zhenfaPos  leftHp   maxHp  )
	self.id = stream:ReadInt();
	--print("self.id",self.id)
	local baseData = JsonConfig.m_stageNodeConfig.getDefByID(self.id);
	local fightBaseData = JsonConfig.m_vecFightConfig.getDefByID(baseData.fightID);
	-- dump(fightBaseData,"fightBaseData")
	self.complete = stream:ReadByte();
	--print("self.complete",self.complete)
	self.rewardFlag = stream:ReadByte();--0 不可领取 1 可领取 2 已领取
	--print("self.rewardFlag",self.rewardFlag);
	self.zhenfaId = fightBaseData.zhenfa[1];
	self.monsterNum = stream:ReadByte();
	--print("self.monsterNum",self.monsterNum);
	self.fightInfo = {}
	for i = 1, self.monsterNum do
		local data = {}
		data.fightPos = stream:ReadByte();
		--print("data.fightPos",data.fightPos);
		data.leftHp = stream:ReadULongInt();
		--print("data.leftHp",data.leftHp);
		data.id = fightBaseData["index" .. data.fightPos];
		local monsterData = LDataConstMgr:GetMonsterData(data.id);
		data.maxHp = monsterData.qixue;
		table.insert(self.fightInfo,data);
		data.isDie = stream:ReadByte();
		--print("data.isDie",data.isDie);
	end
	self.firstRankName = stream:ReadString();
end

function LFactionCopyData:ReadDetailFromServer(stream)
	--[[
	=1 success  complete  zhenfaId  monsterNum [ zhenfaPos   pic   leftHp   maxHp  isDie ]  rankNum [ roleId   damage   name   head   power  level  vipLv ]  
				1byte      2byte     1byte       1byte     4byte  8byte    8byte  1byte     1byte     4byte    8byte  string  1byte  4byte  2byte  1byte
	]]
	self.complete = stream:ReadByte();
	--print("self.complete",self.complete)
	self.monsterNum = stream:ReadByte();
	local baseData = JsonConfig.m_stageNodeConfig.getDefByID(self.id);
	local fightBaseData = JsonConfig.m_vecFightConfig.getDefByID(baseData.fightID);

	self.fightInfo = {}
	for i = 1, self.monsterNum do
		local data = {}
		data.fightPos = stream:ReadByte();
		data.id = fightBaseData["index" .. data.fightPos];
		data.leftHp = stream:ReadULongInt();
		local monsterData = LDataConstMgr:GetMonsterData(data.id);
		data.maxHp = monsterData.qixue;
		data.isDie = stream:ReadByte();
		table.insert(self.fightInfo,data)
	end
end

function LFactionCopyData:UpdateFromServer(stream, isSaodao)
	local baseData = JsonConfig.m_stageNodeConfig.getDefByID(self.id);
	local fightBaseData = JsonConfig.m_vecFightConfig.getDefByID(baseData.fightID);
	-- dump(fightBaseData,"fightBaseData")
	self.complete = stream:ReadByte();
	--print("self.complete",self.complete)
	self.rewardFlag = stream:ReadByte();--0 不可领取 1 可领取 2 已领取
	--print("self.rewardFlag",self.rewardFlag);
	self.monsterNum = stream:ReadByte();
	--print("self.monsterNum",self.monsterNum);
	self.fightInfo = {}
	for i = 1, self.monsterNum do
		local data = {}
		data.fightPos = stream:ReadByte();
		--print("data.fightPos",data.fightPos);
		data.leftHp = stream:ReadULongInt();
		--print("data.leftHp",data.leftHp);
		data.id = fightBaseData["index" .. data.fightPos];
		local monsterData = LDataConstMgr:GetMonsterData(data.id);
		data.maxHp = monsterData.qixue;
		data.isDie = stream:ReadByte();
		--print("data.isDie",data.isDie);
		table.insert(self.fightInfo,data)
	end
	self.firstRankName = stream:ReadString();
end

function LFactionCopyData:ReadRankFromServer(stream)
	--[[
	=1 success  complete  zhenfaId  monsterNum [ zhenfaPos   pic   leftHp   maxHp  isDie ]  rankNum [ roleId   damage   name   head   power  level  vipLv ]  
				1byte      2byte     1byte       1byte     4byte  8byte    8byte  1byte     1byte     4byte    8byte  string  1byte  4byte  2byte  1byte
	]]
	self.rankNum = stream:ReadWord();
	self.rankInfoArr = {};
	for i = 1, self.rankNum do
		local info = {};
		info.roleId = stream:ReadUInt();
		info.damage = stream:ReadULongInt();
		info.name = stream:ReadString();
		info.head = stream:ReadByte();
		info.power = stream:ReadULongInt();
		info.level = stream:ReadWord();
		info.vipLv = stream:ReadByte();
		info.rank = i;
		table.insert(self.rankInfoArr, info);
	end
	self.lastHitId = stream:ReadUInt();
end

function LFactionCopyData:Delete()
	
end