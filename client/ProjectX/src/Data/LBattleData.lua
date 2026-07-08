--[[
战斗动作配置数据
]]
LBtActCfg = {}
LBtActCfg.__index = LBtActCfg
function LBtActCfg:New()
	local o = {}
	setmetatable(o,LBtActCfg)	
	o:Init()
	return o
end

function LBtActCfg:Init()
	self.m_id = 0
	self.m_act = ""--动作
	self.m_moveStartType = 0--开始移动类型--对应AppDef.BTConst.MoveType值
	self.m_moveEndType = 0--结束移动类型--对应AppDef.BTConst.MoveType值
	self.m_moveTime = 0--移动时间，0没有移动
	self.m_soundFile = ""
	self.m_shakeId = 0
end

function LBtActCfg:Delete()
	self.m_id = nil
	self.m_act = nil
	self.m_moveStartType = nil
	self.m_moveEndType = nil
	self.m_moveTime = nil
	self.m_soundFile = nil
	self.m_shakeId = nil
end

LBTBuffCfg = {}
LBTBuffCfg.__index = LBTBuffCfg
function LBTBuffCfg:New()
	local o = {}
	setmetatable(o,LBTBuffCfg)	
	o:Init()
	return o
end

function LBTBuffCfg:Init()
	self.id = 0--	
	self.name = ""
	self.showType = 0--1血条上方图标2特效
	self.textType = 0--1增益2减益
	self.resName = 0--资源编号
	self.hit = 0--打击点--走打击点规则
	self.offPoint = {0,0}--偏移
	self.showText = ""--特效上浮文字，len=0就是没有

	self.tipIcon = ""--提示icon
	self.desc = ""--描述

	self.stateInd = 0
    self.stateOffset = 0
    self.stateValue = 0
end

LBTSkillCfg = {}
LBTSkillCfg.__index = LBTSkillCfg
function LBTSkillCfg:New()
	local o = {}
	setmetatable(o,LBTSkillCfg)	
	o:Init()
	return o
end

function LBTSkillCfg:Init()
	self.m_id = 0--技能效果id	
	self.m_file = ""--特效文件名称	
	self.m_resType = 0--1单方向不要翻转2单方向要翻转3双方向不需要翻转
	self.m_moveStartType = 0--type1：初始位置；type2：播放位置
	self.m_moveEndType = 0--	type1：结束位置；type2：播放位置，和movestart一致
	self.m_moveTime = 0--	type1：位移时间ms；type2：不需要位移时间，填0
	self.m_leftOff = cc.p(0,0)--	从左至右攻击时的偏移
	self.m_rightOff = cc.p(0,0)--	从右至左攻击时的偏移
	self.m_hitpoint = 0--	0-地面；1-脚；2-腰；3-头
	self.m_scale = 1
	self.m_soundFile = ""
	self.m_shakeId = 0
end

function LBTSkillCfg:Delete()
	self.m_id = nil--技能效果id	
	self.m_file = nil--特效文件名称	
	self.m_resType = nil
	self.m_moveStartType = nil--type1：初始位置；type2：播放位置
	self.m_moveEndType = nil--	type1：结束位置；type2：播放位置，和movestart一致
	self.m_moveTime = nil--	type1：位移时间ms；type2：不需要位移时间，填0
	self.m_leftOff = nil--	从左至右攻击时的偏移
	self.m_rightOff = nil--	从右至左攻击时的偏移
	self.m_hitpoint = nil--	0-地面；1-脚；2-腰；3-头
	self.m_soundFile = nil
	self.m_shakeId = nil
end

LBTHitCfg = {}
LBTHitCfg.__index = LBTHitCfg
function LBTHitCfg:New()
	local o = {}
	setmetatable(o,LBTHitCfg)	
	o:Init()
	return o
end

function LBTHitCfg:Init()
	self.m_id = 0--技能效果id	
	self.m_file = ""--特效文件名称	
end

function LBTHitCfg:Delete()
	self.m_id = nil--技能效果id	
	self.m_file = nil--特效文件名称	
end

--[[
震屏
]]
LBTShakeCfg = {}
LBTShakeCfg.__index = LBTShakeCfg
function LBTShakeCfg:New()
	local o = {}
	setmetatable(o,LBTShakeCfg)	
	o:Init()
	return o
end

function LBTShakeCfg:Init()
	self.m_id = 0--
	self.m_delayTime = 0
	self.m_strength = 0
	self.m_time = 0
end

function LBTShakeCfg:Delete()
	self.m_id = nil
	self.m_delayTime = nil
	self.m_strength = nil
	self.m_time = nil
end

LBTClipCfg = {}
LBTClipCfg.__index = LBTClipCfg
function LBTClipCfg:New()
	local o = {}
	setmetatable(o,LBTClipCfg)	
	o:Init()
	return o
end

function LBTClipCfg:Init()
	self.m_id = 0--技能效果id	
	self.m_delay = 0
	self.m_clipType = 0--1模型动作，2技能动作，3被击动作
end

function LBTClipCfg:Delete()
	self.m_id = 0--技能效果id	
	self.m_delay = 0
	self.m_clipType = 0--1模型动作，2技能动作，3被击动作
end

LBTCfg = {}
LBTCfg.__index = LBTCfg
function LBTCfg:New()
	local o = {}
	setmetatable(o,LBTCfg)	
	o:Init()
	return o
end

function LBTCfg:Init()
	self.m_id = 0--技能效果id
	self.m_cfgBuf = {}--对应LBTClipCfg
	self.m_lianjiInd = 0
	self.m_mulitTgtInd = 0
	self.m_mulitType = 0
end

function LBTCfg:Delete()
	self.m_id = nil
	self.m_cfgBuf = nil
	self.m_lianjiInd = nil
	self.m_mulitTgtInd = nil
	self.m_mulitType = nil
end

--普通打击点信息
LBTUnitHitData = {}
LBTUnitHitData.__index = LBTUnitHitData
function LBTUnitHitData:New()
	local o = {}
	setmetatable(o,LBTUnitHitData)	
	o:Init()
	return o
end

function LBTUnitHitData:Init()
	self.id = 0--1- n为怪物的id
	self.hpBarPos = cc.p(0,100)--血条位置
	self.footPos = cc.p(0,10)--脚
	self.waistPos = cc.p(0,40)--腰
	self.headPos = cc.p(0,70)--头
end

function LBTUnitHitData:GetId() 
	return self.id 
end

function LBTUnitHitData:GetHpBarPos() 
	return self.hpBarPos
end

function LBTUnitHitData:GetFootPos() 
	return self.footPos
end
function LBTUnitHitData:GetWaitPos() 
	return self.waistPos
end

function LBTUnitHitData:GetHeadPos() 
	return self.headPos
end

--[[
战斗出站单元数据
]]
LBTUnitData = {}
LBTUnitData.__index = LBTUnitData

function LBTUnitData:New()
	local o = {}
	setmetatable(o,LBTUnitData)	
	o:Init()
	return o
end

function LBTUnitData:Init()
	self:Reset()
end

function LBTUnitData:Clone(btData)
	btData.m_srcPos.x = self.m_srcPos.x
	btData.m_srcPos.y = self.m_srcPos.y
	btData.m_posBid = self.m_posBid            --1-18代表位置
	btData.m_id = self.m_id                 --编号
	btData.m_name = self.m_name--名字
	btData.m_level = self.m_level              --等级
	btData.m_curHp = self.m_curHp
	btData.m_maxHp = self.m_maxHp        --当前最大HP
	btData.m_type = self.m_type               --0怪物、1玩家、2宠物、3灵兽
	--以下为玩家专有属性
	btData.m_prof = self.m_prof               --职业
	btData.m_sex = self.m_sex                --性别
	btData.m_wp = self.m_wp                 --
	btData.m_scaleRatio = self.m_scaleRatio--缩放比例1-1000
	btData.m_maxPlaySpeed = self.m_maxPlaySpeed       --最大播放速度
	btData.m_fixedPlaySpeed = self.m_fixedPlaySpeed     --当前播放速度
	btData.m_lightEffect = self.m_lightEffect        --光效
	btData.m_spShow = self.m_spShow			--特效出场
	btData.m_ownerPosBid = self.m_ownerPosBid--如果是宠物的话这个字段就是宠物所属玩家的位置
	btData.m_quality = self.m_quality
	btData.m_isDead = self.m_isDead
	btData.m_normalState = self.m_normalState
	btData.m_stateNum = self.m_stateNum
	btData.m_isBoss = self.m_isBoss

	btData.m_state = {}
	for i = 1, self.m_stateNum do
		table.insert(btData.m_state, self.m_state[i])
	end
	for i = 1, #btData.skillInfo do
		btData.skillInfo[i] = {self.skillInfo[i][1],skillInfo[i][2]}
	end
	
end
function LBTUnitData:Reset()
	if self.m_srcPos == nil then
		self.m_srcPos = cc.p(0,0)
	else
		self.m_srcPos.x = 0
		self.m_srcPos.y = 0
	end
	
	self.m_posBid = 0             --1-18代表位置
	self.m_id = 0                 --编号
	self.m_name = ""            --名字
	self.m_level = 0              --等级
	self.m_curHp = 0
	self.m_maxHp = 0        --当前最大HP
	self.m_type = 0               --0怪物、1玩家、2宠物、3灵兽
	--以下为玩家专有属性
	self.m_prof = 0               --职业
	self.m_sex = 0                --性别
	self.m_wp = 0                 --
	self.m_scaleRatio = 1	        --缩放比例1-1000
	self.m_maxPlaySpeed = 0       --最大播放速度
	self.m_fixedPlaySpeed = 0     --当前播放速度
	self.m_lightEffect = 0        --光效
	self.m_spShow = 0			--特效出场
	self.m_ownerPosBid = 0--如果是宠物的话这个字段就是宠物所属玩家的位置
	self.m_quality = 0
	self.m_isDead = false
	self.m_normalState = 0;
	self.m_stateNum = 0
	if self.m_states == nil then
		self.m_states = {}
	end

	if self.skillInfo == nil then
		self.skillInfo = {}
	else
		while #self.skillInfo > 0 do
			table.remove(self.skillInfo,1)
		end
	end
	self.m_isBoss = false
end

function LBTUnitData:HasData()
	if self.m_id == 0 then
		return false
	else
		return true
	end
end

function LBTUnitData:Delete()
	self.m_srcPos = nil
	self.m_posBid = nil             --1-18代表位置
	self.m_id = nil                 --编号
	self.m_name = nil            --名字
	self.m_level = nil             --等级
	self.m_curHp = nil
	self.m_maxHp = nil        --当前最大HP
	self.m_type = nil               --0怪物、1玩家、2宠物、3灵兽
	--以下为玩家专有属性
	self.m_prof = nil
	self.m_sex = nil
	self.m_wp = nil
	self.m_scaleRatio = nil
	self.m_maxPlaySpeed = nil       --最大播放速度
	self.m_fixedPlaySpeed = nil     --当前播放速度
	self.m_lightEffect = nil
	self.m_spShow = nil
	self.m_ownerPosBid = nil
	self.m_quality = nil
	self.m_normalState = nil
	self.m_stateNum = nil
	self.m_states = nil
	self.m_isDead = nil
	self.m_isBoss = nil
end

--Buff信息
LBTBuffUnitData = {}
LBTBuffUnitData.__index = LBTBuffUnitData
function LBTBuffUnitData:New()
	local o = {}
	setmetatable(o,LBTBuffUnitData)	
	o:Init()
	return o
end

function LBTBuffUnitData:Init()
	self:Reset()
end

function LBTBuffUnitData:Reset()
	self.id = -1            --buff的id
	self.buffNode = nil
	self.hit = 0--
end

LBTActionData = {}
LBTActionData.__index = LBTActionData

function LBTActionData:New()
	local o = {}
	setmetatable(o,LBTActionData)	
	o:Init()
	return o
end

--[[
应该是包含目标数量*连击数量
]]
function LBTActionData:Init()
	self.CurAniInd = 0--当前播放的动作下标
	self.CurFanjiAniInd = 0--当前反击播放的动作下标
	self.CurTarInd = 0--当前目标下标
	self.CurLianjiInd = 0--当前连击次数
	self.ActCfgData = nil--使用的动作配置表
	self.StartPlayTime = 0--开始播放的时间
	self.ActionType = 0         --动作类型
	self.SrcBid = 0             --源的posBid
	self.SrcStateNum = 0
	self.SrcState = 0--攻击者状态
	self.SrcBuffArr = {}
	self.SrcDamage = 0--行动结束后伤血
	self.SrcAbsorpionHp = 0--行动结束后伤血
	self.SrcRecover = 0--行动结束后加血
	
	self.Val = 0--技能ID、宠物Pos、物品pos
	self.Msg = ""                --提示信息
	--self.DestNum = 0
	self.DestNum = {}
	self.DestBid = {}--目标posBid

	self.DestBuffBid = {}--目标附加buff
	self.DestBuffNum = 0
	self.DestBuffHpChanged = {}
	self.DestBuffAbsorpion = {}
	self.DestBuffHpRecover = {}
	self.DestBuffState = {}--攻击者状态
	self.DestBuffStateNum = {}
	self.DestBuffStateArr = {}--攻击者状态


	--self.LianjiNum = {}        --连击次数，等于1就是没有连击
	self.LianjiNum = 0
	self.IsHit = {}--是否击中
	self.Crit = {}--暴击
	self.Damage = {}--伤害列表
	self.AbsorpionHp = {}--伤害吸收列表
	self.RecoverDemage = {}--复活血量

	self.Protects = {}--保护者id
	self.ProtectDamages = {}--伤害列表
	self.ProtectAbsorpionHp = {}--伤害吸收列表
	self.ProtectRecover = {}--保护者回血
	self.ProtectStateNum = {}
	self.ProtectState = {}
	self.ProtectStates = {}

	
	
	
	self.RespC = {}--反震
	self.RespVal = {}--反震血量
	self.RespAbsorpionVal = {}--反震吸收血量
	self.RecoverResp = {}--反震复活
	
	self.BeatBack = {}--反击
	self.BeatBackHit = {}--反击命中
	self.BeatBackCrit = {}--反击暴击
	self.BeatBackDamage = {}--反击
	self.BeatBackAbsorpionDamage = {}--反击
	self.BeatBackRecoverDemage = {}--反击血量


	
	self.SrcStateNum = 0
	self.SrcState = 0--攻击者状态
	self.SrcBuffArr = {}
	self.SrcDamage = 0
	self.SrcAbsorpionHp = 0
	self.SrcRecover = 0
	self.DestStateNum = {}
	self.DestState = {}--目标状态--二位数组
	self.DestBuffArr = {}--
	self.UnitDataNum = 0
	self.UnitData = {}           --单位信息
	--for i = 1, LBTBuffUnitData.MaxBuffNum*2 then
	for i = 1, AppDef.BTConst.MaxLianjiNum do
		self.Damage[i] = {}
		self.AbsorpionHp[i] = {}
		self.RecoverDemage[i] = {}
		self.IsHit[i] = {}
		self.RespVal[i] = {}--反震血量
		self.RespAbsorpionVal[i] = {}--反震血量
		self.RecoverResp[i] = {}--反震复活
		self.RespC[i] = {}--反震
		self.BeatBack[i] = {}--反击
		self.BeatBackHit[i] = {}
		self.BeatBackCrit[i] = {}
		self.BeatBackRecoverDemage[i] = {}
		self.BeatBackDamage[i] = {}
		self.BeatBackAbsorpionDamage[i] = {}
		self.DestStateNum[i] = {}
		self.DestState[i] = {}--状态位
		self.DestBuffArr[i] = {}
		self.Crit[i] = {}
		self.Protects[i] = {}--保护者id
		self.ProtectDamages[i] = {}--伤害列表
		self.ProtectAbsorpionHp[i] = {}
		self.ProtectRecover[i] = {}
		self.ProtectStates[i] = {}
		self.ProtectStateNum[i] = {}
		self.ProtectState[i] = {}
		self.DestBid[i] = {}
		for j = 1, AppDef.BTConst.MaxUnitNum do
			self.Damage[i][j] = 0
			self.AbsorpionHp[i][j] = 0
			self.RecoverDemage[i][j] = 0
			self.IsHit[i][j] = 0
			self.RespVal[i][j] = 0
			self.RespAbsorpionVal[i][j] = 0
			self.RecoverResp[i][j] = 0
			self.RespC[i][j] = 0
			self.BeatBackRecoverDemage[i][j] = 0
			self.BeatBackDamage[i][j] = 0
			self.BeatBackAbsorpionDamage[i][j] = 0
			self.BeatBack[i][j] = 0--反击
			self.BeatBackHit[i][j] = 0
			self.BeatBackCrit[i][j] = 0
			self.DestStateNum[i][j] = 0
			self.DestState[i][j] = 0
			self.DestBuffArr[i][j] = {}
			self.Crit[i][j] = 0
			self.Protects[i][j] = 0
			self.ProtectDamages[i][j] = 0
			self.ProtectAbsorpionHp[i][j] = 0
			self.ProtectRecover[i][j] = 0
			self.ProtectStateNum[i][j] = 0
			self.ProtectState[i][j] = 0
			self.ProtectStates[i][j] = {}
			self.DestBid[i][j] = 0
		end
		self.DestNum[i] = 0
		
		self.DestBuffBid[i] = 0
		self.DestBuffHpChanged[i] = 0
		self.DestBuffAbsorpion[i] = 0
		self.DestBuffHpRecover[i] = 0
		self.DestBuffState[i] = 0
		self.DestBuffStateNum[i] = 0
		self.DestBuffStateArr[i] = {}

		self.UnitData[i] = LBTUnitData:New()
	end
end

function LBTActionData:Reset()
	self.CurAniInd = 0
	self.CurFanjiAniInd = 0--当前反击播放的动作下标
	self.CurTarInd = 0--当前目标下标
	self.CurLianjiInd = 0--当前连击次数
	self.ActCfgData = nil--使用的动作配置表
	self.StartPlayTime = 0--开始播放的时间
	self.ActionType = 0         --动作类型
	self.SrcBid = 0             --源的posBid
	self.SrcDamage = 0
	self.SrcAbsorpionHp = 0
	self.SrcRecover = 0
	self.SrcState = 0--攻击者状态
	self.SrcBuffArr = {}
	-- for k = self.SrcStateNum, 5, -1 do
	-- 	self.SrcState[k] = nil
	-- end
	self.SrcStateNum = 0
	--self.DestNum = 0
	
	self.LianjiNum = 0
	
	self.Val = 0--技能ID、宠物Pos、物品pos
	self.Msg = ""                --提示信息
	self.UnitDataNum = 0
	for i = 1, self.DestBuffNum do
		self.DestBuffBid[i] = 0
		self.DestBuffHpChanged[i] = 0
		self.DestBuffAbsorpion[i] = 0
		self.DestBuffHpRecover[i] = 0
		self.DestBuffStateNum[i] = 0
		self.DestBuffStateArr[i] = {}
	end
	self.DestBuffNum = 0
	--for i = 1, LBTBuffUnitData.MaxBuffNum*2 then
	for i = 1, AppDef.BTConst.MaxLianjiNum do
		for j = 1, AppDef.BTConst.MaxUnitNum do
			self.Damage[i][j] = 0
			self.AbsorpionHp[i][j] = 0
			self.RecoverDemage[i][j] = 0
			self.IsHit[i][j] = 0
			self.RespVal[i][j] = 0
			self.RespAbsorpionVal[i][j] = 0
			self.RecoverResp[i][j] = 0
			self.RespC[i][j] = 0
			self.BeatBackRecoverDemage[i][j] = 0
			self.BeatBackDamage[i][j] = 0
			self.BeatBackAbsorpionDamage[i][j] = 0
			self.BeatBack[i][j] = 0--反击
			self.BeatBackHit[i][j] = 0
			self.BeatBackCrit[i][j] = 0
			self.DestStateNum[i][j] = 0
			self.Crit[i][j] = 0
			self.Protects[i][j] = 0
			self.ProtectDamages[i][j] = 0
			self.ProtectAbsorpionHp[i][j] = 0
			self.DestState[i][j] = 0
			self.DestBuffArr[i][j] = {}
			self.ProtectStateNum[i][j] = 0
			self.ProtectState[i][j] = 0
			self.ProtectStates[i][j]  = {}
			self.DestBid[i][j] = 0
		end
		self.DestNum[i] = 0
		--self.LianjiNum[i] = 0
		
		
		self.UnitData[i]:Reset()
	end

	
end


