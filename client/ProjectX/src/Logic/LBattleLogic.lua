--[[
lua里面的游戏逻辑控制
]]

local BattleHpTextPool = require("View.Battle.BattleHpTextPool")
local BattleUnitScript = require("View.Battle.BattleUnitNode")
LBattleLogic = LGameBase:New()
LBattleLogic.__index = LBattleLogic

--local this = LTcpSocket
function LBattleLogic:New()
	local o = LGameBase:New()
	setmetatable(o,LBattleLogic)
	o:Init()
	return o
end

function LBattleLogic:Init()
	self:RegistMsg()
	self:InitData()
end

function LBattleLogic:InitData()
	self.m_speed = 1--战斗速度
	self.m_serverSpeed = 0--服务器控制战斗速度,如果为0就是客户端控制
	self.m_pNode = nil
	self.m_pBuffLayer = nil--buff提示
	self.m_pBuffCell = nil--buff子元素
	self.m_pBuffSize = nil--buff提示框的初始尺寸
	self.m_centerPos = nil--中心位置
	self.m_pBattleUnitNodes = {}--战斗单元父节点
	self.m_pBtUnitPos = {}--战斗单元站位节点
	self.m_pBtUnitAppearAnis = {}
	self.m_pScrUnitPos = {}--战斗单元原始位置
	self.m_pBattleUnits = {}--战斗单元类
	self.m_pUnitDatas = {}--战斗单元数据
	self.m_pNewUnitDatas = {}--每回合新增的战斗单位数据
	self.m_state = AppDef.BTConst.BTState.None--战斗状态，AppDef.BTConst.BTState
	self.m_battleId = 0
	self.m_battleType = 0
	self.m_isAuto = false
	self.m_isLockAuto = false
	self.m_isOver = false
	self.m_isWin = false;
	self.m_isJump = false;
	self.m_waitSecs = 0
	self.m_jumpFlag = 0
	self.m_battleRoundMax = 0
	self.m_battleRoundIdx = 0
	self.m_myZhenfaId = 0
	self.m_myZhenfaLv = 0
	self.m_enemyZhenfaId = 0
	self.m_enemyZhenfaLv = 0
	self.m_bIsFlipPos = false--位置翻转
	self.m_myHeroBid = 0--我自己的位置
	self.m_buffNum = 0
	self.m_vecBuff = {0,0,0,0,0,0,0,0,0,0}
	self.m_isReplay = false;

	-- self.m_hbActionNum = 0
	-- self.m_vecHbActions = {}--灵兽动作
	self.m_actionNum = 0
	self.m_curActionInd = 0--当前播放的动作下表
	self.m_vecActions = {}
	for i = 1,AppDef.BTConst.MaxActionNum do
		self.m_vecActions[i] = LBTActionData:New()
	end
	self.m_roundEndStates = {}--回合结束后的状态变化

	local scene = AppDef.Director:getRunningScene()
    if scene then
    	local function LoadBattleUI()
	        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Battle.BattleUI",AppDef.UIType.Battle)
			self:SendMsg(LGameMsg.m_initUIMsg)
	    end
    	Utils:DelayToCallFunc(scene,self:getFightTime(0.3),LoadBattleUI)
    end
    --每回合播放技能bgm的单位
    self.m_bgmSrces = {}
	

	--self:InitBattleUnit()

end

function LBattleLogic:RegistMsg()
	self.msgIds = 
	{
	    LBattleEvent.InitBattle,
	    LBattleEvent.RecvEnterBattle,
	    LBattleEvent.RecvEnterBattleReplay,
    	LBattleEvent.RecvBattleWatch,
    	LBattleEvent.RecvDoBattle,
    	LBattleEvent.RecvJumpBattle,
    	LBattleEvent.RecvBattleOver,
    	LBattleEvent.BreakBattle,
    	LBattleEvent.SocketClosed,
    	LBattleEvent.JumpBattle,
    	LBattleEvent.UseSkill,
    	LBattleEvent.AutoBattle,
    	LBattleEvent.RunAway,
    	LBattleEvent.UpdateSpeed,
    	LBattleEvent.UpdateFightHP,
	}
	self:RegistSelf(self,self.msgIds)
end

function LBattleLogic:ProcessEvent(msg)
	local msgId = msg:GetMsgId()
	if msgId == LBattleEvent.InitBattle then
		self:InitBattle(msg.value)
	elseif msgId == LBattleEvent.RecvEnterBattle then
		self.m_isReplay = false;
		self:RecvEnterBattle(msg.value)
	elseif msgId == LBattleEvent.RecvEnterBattleReplay then
		self.m_isReplay = true;
		self:RecvEnterBattle(msg.value)
	elseif msgId == LBattleEvent.RecvBattleWatch then
	elseif msgId == LBattleEvent.RecvDoBattle then
		self:RecvDoBattle(msg.value)
	elseif msgId == LBattleEvent.RecvBattleOver then
		self:RecvBattleOver(msg.value)
	elseif msgId == LBattleEvent.BreakBattle then
		self:BreakBattle()
	elseif msgId == LBattleEvent.SocketClosed then
		self:SocketClosed()
	elseif msgId == LBattleEvent.JumpBattle then
		self:JumpBattle()
	elseif msgId == LBattleEvent.UseSkill then
		self:DoUseSkill(msg.value)
	elseif msgId == LBattleEvent.AutoBattle then
		self:DoAutoBattle(msg.value)
	elseif msgId == LBattleEvent.RunAway then
		self:DoRunAway(msg.value)
	elseif msgId == LBattleEvent.UpdateSpeed then
		self:UpdateFightSpeed()
	elseif msgId == LBattleEvent.UpdateFightHP then
		self:DealUpdateFightHP(msg.value)
	elseif msgId ==  LBattleEvent.RecvJumpBattle then
		self:DealJumpBattle(msg.value)
	end
end

function LBattleLogic:JumpBattle()
	--print("---------------JumpBattle----------------------",self.m_isReplay,self.m_isOver)
	if self.m_isReplay == true then
		LRoleDataMgr:GenReplayResult();
		self:BreakBattle()
	else
		self.m_isJump = true;
		if self.m_isOver == true then
			self.m_pNode:stopAllActions();
			self:BattleEndAnimateCallBack()
		else
			LuaNetSendMsg:SendJumpBattle();
		end
		
	end
end

function LBattleLogic:DealJumpBattle(stream)
	local op = stream:ReadByte();
    --print("DealJumpBattle",op)
    if op == 3 then
        local num = stream:ReadWord();
        --print("num",num)
        for i = 1, num do
        	local tmpStream = stream:ReadNetMsg();
        	--print("tmpStream.msgId",tmpStream:GetNetCmdId());
        end
    end
end

function LBattleLogic:SocketClosed()
	--不弹战斗结算面板
	self.m_isReplay = true;
	LRoleDataMgr.m_rePlayType = 4;
	self:BreakBattle();
end

function LBattleLogic:BreakBattle()
	self.m_isOver = true
	self:BattleEndAnimateCallBack()
end

function LBattleLogic:DoUseSkill(sid)
	--print("DoUseSkill",sid)
	if self.m_state == AppDef.BTConst.BTState.Action then
		if self.m_isReplay == false then
			LuaNetSendMsg:QueryBattleAct(AppDef.BTConst.ActOpt.ACT_SKATK, sid)
		else
			local function DoReplay()
				LRoleDataMgr:ReplayBattle(false)
			end
			Utils:DelayToCallFunc(self.m_pNode,0.5,DoReplay)
		end
		
		self.m_state = AppDef.BTConst.BTState.Wait
	end
end

function LBattleLogic:DoAutoBattle(auto)
	--print("DoAutoBattle",auto)
	if self.m_state == AppDef.BTConst.BTState.Action then
		if self.m_isReplay == false then
			LuaNetSendMsg:QueryBattleAct(AppDef.BTConst.ActOpt.ACT_AUTOFIGHT, auto);
		else
			local function DoReplay()
				LRoleDataMgr:ReplayBattle(false)
			end
			Utils:DelayToCallFunc(self.m_pNode,0.5,DoReplay)
		end
		self.m_state = AppDef.BTConst.BTState.Wait
	end
end

function LBattleLogic:DoRunAway()
	
	if self.m_state == AppDef.BTConst.BTState.Action then
		LuaNetSendMsg:QueryBattleAct(AppDef.BTConst.ActOpt.ACT_RUNAWAY,1)
		self.m_state = AppDef.BTConst.BTState.Wait
	end
end

function LBattleLogic:SetOtherHeroPreparing(val)
	for i = 1, AppDef.BTConst.MaxUnitNum do
		if self.m_pUnitDatas[i]:HasData() 
			and self.m_pUnitDatas[i].m_type == AppDef.BTConst.Type.Hero
			and self.m_pUnitDatas[i].m_id ~= LRoleDataMgr.MyHeroInfo.id then
			self.m_pBattleUnits[i]:ShowPreparingHint(val)
		end
		
	end
end

function LBattleLogic:InitBattle(battleLayer)
	local tmpStr = "Node_"
	self.m_pNode = battleLayer
	self.m_pBuffLayer = self.m_pNode:getParent():getChildByName("ListBg")
	self.m_pBuffSize = self.m_pBuffLayer:getContentSize()
	self.m_pBuffLayer:setVisible(false)
	self.m_pBuffCell = self.m_pBuffLayer:getChildByName("Buff")
	self.m_pBuffCell:setVisible(false)
	local size = battleLayer:getContentSize()
	self.m_centerPos = cc.p(size.width/2,size.height/2)
	for i = 1, AppDef.BTConst.MaxUnitNum do
		self.m_pBattleUnitNodes[i] = battleLayer:getChildByName(tmpStr .. i)
		
		self.m_pBtUnitPos[i] = battleLayer:getChildByName("Image_" .. i)
		local _ = self.m_pBtUnitPos[i] and self.m_pBtUnitPos[i]:setLocalZOrder(-1000000)

		self.m_pScrUnitPos[i] = cc.p(self.m_pBattleUnitNodes[i]:getPosition())

		self.m_pBattleUnits[i] = BattleUnitScript:New(self, self.m_pBattleUnitNodes[i])

		self.m_pUnitDatas[i] = LBTUnitData:New()
		self.m_pNewUnitDatas[i] = LBTUnitData:New()
	end

	local function BattleUnitClickCallback(pTouch, pEvent)
        if pEvent == ccui.TouchEventType.began then
            local tag = pTouch:getTag()
            local function DelayToShowBuffTips()
            	self:ShowBattleUnitBuffTips(tag)
            end
            Utils:DelayToCallFunc(self.m_pBuffLayer,self:getFightTime(0.5),DelayToShowBuffTips)
        elseif pEvent == ccui.TouchEventType.ended then
        	if self.m_pBuffLayer:isVisible() == false then
        		self.m_pBuffLayer:stopAllActions()
        	end
        end
	end

	for i = 1, AppDef.BTConst.MaxUnitNum do
		local panel = self.m_pBattleUnitNodes[i]:getChildByName("Panel")
		panel:setTag(i)
		panel:addTouchEventListener(BattleUnitClickCallback)
	end

	local function BgClicked()
		if self.m_pBuffLayer:isVisible() == true then
			self.m_pBuffLayer:setVisible(false)
    		self.m_pBuffLayer:stopAllActions()
    	end
	end
	local parent = self.m_pNode:getParent()
	parent:addClickEventListener(BgClicked)
	parent:setTouchEnabled(true)
	--parent:setSwallowTouches(false)
end

function LBattleLogic:ShowBattleUnitBuffTips(touchTag)
	if self.m_pUnitDatas[touchTag]:HasData() == false then
		return
	end
	-- if self.m_pUnitDatas[touchTag].m_isDead == true then
	-- 	return
	-- end
    self.m_pBuffLayer:setVisible(true)
	self.m_pBattleUnits[touchTag]:ShowBuffTips(self.m_pBuffLayer,self.m_pBuffCell,self.m_pBuffSize)

	-- local function DelayToHide()
	-- 	self.m_pBuffLayer:setVisible(false)
	-- end
	-- Utils:DelayToCallFunc(self.m_pBuffLayer,5,DelayToHide)
end


function LBattleLogic:ReadActionChat(stream, AcData)
	--print("ReadActionChat")
	AcData.Val = 0--
	AcData.LianjiNum =  1
	AcData.LianjiNum = stream:ReadByte()
	AcData.Msg = stream:ReadString()
	--print("Msg=",AcData.Msg)
end


--[[
被动技能触发，没有动作
]]
function LBattleLogic:ReadActionPassiveBuff(stream, AcData)
	--[[
	=6 被动加血,扣血    targetNum   [  target   addHp   tarStateVal  ]
				            1byte        1byte    4byte   stateStruct
	]]
	AcData.Val = stream:ReadWord()--没有src
	AcData.Msg = stream:ReadString()
	--print("AcData.Val",AcData.Val)
	AcData.LianjiNum = 1
	for i = 1, AcData.LianjiNum do
		AcData.DestNum[i] =  stream:ReadByte()
		--print("AcData.DestNum[i]",AcData.DestNum[i])
		AcData.DestBid[i] = AcData.DestBid[i] or {}
		AcData.Damage[i] = AcData.Damage[i] or {}
		AcData.AbsorpionHp[i] = AcData.AbsorpionHp[i] or {}
		AcData.RecoverDemage[i] = AcData.RecoverDemage[i] or {}
		AcData.DestStateNum[i] = AcData.DestStateNum[i] or {}
		AcData.DestState[i] = AcData.DestState[i] or {}
		for j = 1, AcData.DestNum[i] do
			AcData.DestBid[i][j] = stream:ReadByte()--目标
			AcData.IsHit[i][j] = 1
			--print("AcData.Target[i][j]",AcData.DestBid[i][j])
			AcData.Damage[i][j] = stream:ReadInt()
			--print("AcData.Damage[i]",AcData.Damage[i][j])
			AcData.AbsorpionHp[i][j] = stream:ReadInt()
			--print("AcData.AbsorpionHp[i]",AcData.AbsorpionHp[i][j])
			AcData.RecoverDemage[i][j] = stream:ReadUInt()
			--print("AcData.RecoverDemage[i]",AcData.RecoverDemage[i][j])
			AcData.DestState[i] = AcData.DestState[i] or {}
			AcData.DestState[i][j] = stream:ReadByte()
			AcData.DestStateNum[i] = AcData.DestStateNum[i] or {}
			AcData.DestStateNum[i][j] = stream:ReadByte()
			--print("AcData.TargetStateNum[i][j]=",AcData.DestStateNum[i][j])
			AcData.DestBuffArr[i][j] = {}
			for k = 1, AcData.DestStateNum[i][j] do
				table.insert(AcData.DestBuffArr[i][j],stream:ReadByte())
				--print("AcData.DestBuffArr[i][j][k]=",AcData.DestBuffArr[i][j][k])
			end
		end
	end
	
end

function LBattleLogic:ReadActionAddBuff(stream, AcData)
--[[
 =3 buff        skillId    targetNum [  target  isActive  tarStateVal ]  srcStateVal
                 2byte       1byte       1byte   1byte    stateStruct    stateStruct
				                                 =1 生效
												 =2 未生效
]]
	local hit
	AcData.Val = stream:ReadWord()
	--print("AcData.SkillId",AcData.Val)

	AcData.LianjiNum = 1
	for i = 1, AcData.LianjiNum do
		AcData.DestNum[i] =  stream:ReadByte()
		--print("AcData.DestNum[i]",AcData.DestNum[i])
		AcData.DestBid[i] = AcData.DestBid[i] or {}
		AcData.IsHit[i] = AcData.IsHit[i] or {}
		AcData.DestStateNum[i] = AcData.DestStateNum[i] or {}
		AcData.DestState[i] = AcData.DestState[i] or {}
		for j = 1, AcData.DestNum[i] do
			AcData.DestBid[i][j] = stream:ReadByte()--目标
			--print("AcData.Target[i]",AcData.DestBid[i][j])
			AcData.IsHit[i][j] = stream:ReadByte()
			--print("AcData.IsHit[i][j]",AcData.IsHit[i][j])
			AcData.DestState[i] = AcData.DestState[i] or {}
			AcData.DestState[i][j] = stream:ReadByte()
			AcData.DestStateNum[i] = AcData.DestStateNum[i] or {}
			AcData.DestStateNum[i][j] = stream:ReadByte()
			--print("AcData.TargetStateNum[i][j]=",AcData.DestStateNum[i][j])
			AcData.DestBuffArr[i][j] = {}
			for k = 1, AcData.DestStateNum[i][j] do
				table.insert(AcData.DestBuffArr[i][j],stream:ReadByte())
				--print("AcData.DestBuffArr[i][j][k]=",AcData.DestBuffArr[i][j][k])
			end
		end
	end
	
	AcData.SrcState = stream:ReadByte()
	AcData.SrcStateNum = stream:ReadByte()
	--print("AcData.SrcStateNum=",AcData.SrcStateNum)
	AcData.SrcBuffArr = {}
	for k = 1, AcData.SrcStateNum do
		table.insert(AcData.SrcBuffArr,stream:ReadByte())
		--print("AcData.SrcBuffArr[k]",AcData.SrcBuffArr[k])
	end
	self:ReadAddBuff(AcData,stream)
	
end

function LBattleLogic:ReadActionAddHp(stream, AcData)
--[[
=2 加血        skillId    targetNum [  target   addHp   tarStateVal  ]  srcStateVal 
				2byte       1byte       1byte   4byte   stateStruct     stateStruct
]]
	AcData.Val = stream:ReadWord()
	AcData.LianjiNum = 1
	for i = 1, AcData.LianjiNum do
		AcData.DestNum[i] =  stream:ReadByte()
		--print("AcData.DestNum[i]",AcData.DestNum[i])
		AcData.DestBid[i] = AcData.DestBid[i] or {}
		AcData.IsHit[i] = AcData.IsHit[i] or {}
		AcData.Crit[i] = AcData.Crit[i] or {}
		AcData.Damage[i] = AcData.Damage[i] or {}
		AcData.DestStateNum[i] = AcData.DestStateNum[i] or {}
		AcData.DestState[i] = AcData.DestState[i] or {}
		for j = 1, AcData.DestNum[i] do
			
			AcData.DestBid[i][j] = stream:ReadByte()--目标
			--print("AcData.TargetBid[i][j]",AcData.DestBid[i][j])
			
			AcData.IsHit[i][j] = 1
			
			AcData.Crit[i][j] = stream:ReadByte()
			
			AcData.Damage[i][j] = stream:ReadUInt()
			--print("AcData.Damage[i][j]",AcData.Damage[i][j])
			AcData.DestState[i] = AcData.DestState[i] or {}
			AcData.DestState[i][j] = stream:ReadByte()
			AcData.DestStateNum[i] = AcData.DestStateNum[i] or {}
			AcData.DestStateNum[i][j] = stream:ReadByte()
			--print("AcData.TargetStateNum[i][j]=",AcData.DestStateNum[i][j])
			AcData.DestBuffArr[i][j] = {}
			for k = 1, AcData.DestStateNum[i][j] do
				table.insert(AcData.DestBuffArr[i][j],stream:ReadByte())
				--print("AcData.DestBuffArr[i][j][k]=",AcData.DestBuffArr[i][j][k])
			end


		end
	end
	
	AcData.SrcState = stream:ReadByte()
	AcData.SrcStateNum = stream:ReadByte()
	--print("AcData.SrcStateNum=",AcData.SrcStateNum)
	AcData.SrcBuffArr = {}
	for k = 1, AcData.SrcStateNum do
		table.insert(AcData.SrcBuffArr,stream:ReadByte())
		--print("AcData.SrcBuffArr[k]",AcData.SrcBuffArr[k])
	end
	self:ReadAddBuff(AcData,stream)
end

function LBattleLogic:ReadAttackDamage(AcData, stream, tind, lind)
	AcData.Protects[tind] = AcData.Protects[tind] or {}
	AcData.Protects[tind][lind] = stream:ReadByte()
	--print("AcData.Protects[tind][lind]",AcData.Protects[tind][lind])
	if AcData.Protects[tind][lind] > 0 then
		AcData.ProtectDamages[tind] = AcData.ProtectDamages[tind] or {}
		AcData.ProtectDamages[tind][lind] = stream:ReadUInt()
		AcData.ProtectAbsorpionHp[tind] = AcData.ProtectAbsorpionHp[tind] or {}
		AcData.ProtectAbsorpionHp[tind][lind] = stream:ReadUInt()
		--print("AcData.ProtectAbsorpionHp[tind][lind]",AcData.ProtectAbsorpionHp[tind][lind])
		AcData.ProtectRecover[tind] = AcData.ProtectRecover[tind] or {}
		AcData.ProtectRecover[tind][lind] = stream:ReadUInt()
		AcData.ProtectState[tind][lind] = stream:ReadByte()
		AcData.ProtectStateNum[tind] = AcData.ProtectStateNum[tind] or {}
		AcData.ProtectStateNum[tind][lind] = stream:ReadByte()
		AcData.ProtectStates[tind][lind] = {}
		for i = 1, AcData.ProtectStateNum[tind][lind] do
			table.insert(AcData.ProtectStates[tind][lind],stream:ReadByte())
		end
	end
	AcData.Crit[tind] = AcData.Crit[tind] or {}
	AcData.Crit[tind][lind] = stream:ReadByte()--1暴击0无
	AcData.Damage[tind] = AcData.Damage[tind] or {}
	AcData.Damage[tind][lind] = stream:ReadUInt()
	--print("AcData.Damage[tind][lind]",AcData.Damage[tind][lind])
	AcData.AbsorpionHp[tind] = AcData.AbsorpionHp[tind] or {}
	AcData.AbsorpionHp[tind][lind] = stream:ReadUInt()
	--print("AcData.AbsorpionHp[tind][lind]",AcData.AbsorpionHp[tind][lind])
	AcData.RecoverDemage[tind] = AcData.RecoverDemage[tind] or {}
	AcData.RecoverDemage[tind][lind] = stream:ReadUInt()
	AcData.RespC[tind] = AcData.RespC[tind] or {}
	AcData.RespC[tind][lind] = stream:ReadByte()
	--print("AcData.RespC[tind][lind]",AcData.RespC[tind][lind])
	if AcData.RespC[tind][lind] == 1 then--有反震
		AcData.RespVal[tind] = AcData.RespVal[tind] or {}
		AcData.RespVal[tind][lind] = stream:ReadUInt()
		--print("AcData.RespVal[tind][lind]",AcData.RespVal[tind][lind])
		AcData.RespAbsorpionVal[tind] = AcData.RespAbsorpionVal[tind] or {}
		AcData.RespAbsorpionVal[tind][lind] = stream:ReadUInt()
		--print("AcData.RespAbsorpionVal[tind][lind]",AcData.RespAbsorpionVal[tind][lind])
		AcData.RecoverResp[tind] = AcData.RecoverResp[tind] or {}
		AcData.RecoverResp[tind][lind] = stream:ReadUInt()
		--print("AcData.RecoverResp[tind][lind]",AcData.RecoverResp[tind][lind])
	end
	AcData.BeatBack[tind] = AcData.BeatBack[tind] or {}
	AcData.BeatBack[tind][lind] = stream:ReadByte()--反击
	--print("AcData.BeatBack[tind][lind]",AcData.BeatBack[tind][lind])
	if AcData.BeatBack[tind][lind] == 1 then--有反击
		AcData.BeatBackHit[tind] = AcData.BeatBackHit[tind] or {}
		AcData.BeatBackHit[tind][lind] = stream:ReadByte()--反击命中
		--print("AcData.BeatBackHit[tind][lind]",AcData.BeatBackHit[tind][lind])
		if AcData.BeatBackHit[tind][lind] == 1 then
			AcData.BeatBackCrit[tind] = AcData.BeatBackCrit[tind] or {}
			AcData.BeatBackCrit[tind][lind] = stream:ReadByte()--反击暴击
			AcData.BeatBackDamage[tind] = AcData.BeatBackDamage[tind] or {}
			AcData.BeatBackDamage[tind][lind] = stream:ReadUInt()
			--print("AcData.BeatBackDamage[tind][lind]",AcData.BeatBackDamage[tind][lind])
			AcData.BeatBackAbsorpionDamage[tind] = AcData.BeatBackAbsorpionDamage[tind] or {}
			AcData.BeatBackAbsorpionDamage[tind][lind] = stream:ReadUInt()
			--print("AcData.BeatBackAbsorpionDamage[tind][lind]",AcData.BeatBackAbsorpionDamage[tind][lind])
			AcData.BeatBackRecoverDemage[tind] = AcData.BeatBackRecoverDemage[tind] or {}
			AcData.BeatBackRecoverDemage[tind][lind] = stream:ReadUInt()
		end
	end
end

function LBattleLogic:ReadActionAttack(stream, AcData)
--[[
damageNum  { src     action       skillId      targetNum [  target  lianjiNum (  damageVal ) tarStateVal  ]  srcStateVal  }
    1byte     1byte     1byte      > 0 技能id      1byte      1byte     1byte      ValStruct   stateStruct     stateStruct
	                =1 技能或普攻  = 0 普攻                                         
					                                                 

注： =========================================================================================================================																					 
ValStruct：
    hit     protect                            baoji     damage   rdamage  fanzhen                              fanji                                 
   1byte     1byte                             1byte      4byte    4byte   1byte                                1byte
  =1命中   =0无保护者                          =1暴击                      =1反震                              =0不反击(continue)
  =0闪避   >0有保护者  proStateVal  proDamage  =0不暴击                    =0不反震   fanzhenDamage  frdamage  =1反击                  fhit
(=0闪避continue)       stateStruct    4byte               					              4byte        4byte                         =0闪避(continue)
																	                                                                 =1命中      fbaoji   fdamage  frdamage2
																		                                                                         1byte    4byte      4byte
																				                                                                =0不暴击
																			                                                                    =1暴击																			  
]]
	

	local hit
	AcData.Val = stream:ReadWord()
	--print("AcData.SkillId=",AcData.Val)
	--AcData.DestNum =  stream:ReadByte()
	AcData.LianjiNum = stream:ReadByte()
	--print("AcData.LianjiNum=",AcData.LianjiNum)
	for i = 1, AcData.LianjiNum do
		
		AcData.DestNum[i] = stream:ReadByte()--目标
		--print("AcData.DestNum[i]=",AcData.DestNum[i])
		for j = 1, AcData.DestNum[i] do
			AcData.DestBid[i] = AcData.DestBid[i] or {}
			AcData.DestBid[i][j] = stream:ReadByte()--目标
			--print("AcData.Target[i][j]=",AcData.DestBid[i][j])
			AcData.IsHit[i] = AcData.IsHit[i] or {}
			AcData.IsHit[i][j] = stream:ReadByte()
			--print("AcData.IsHit[i][j]=",AcData.IsHit[i][j])
			if AcData.IsHit[i][j] == 1 then
				self:ReadAttackDamage(AcData, stream, i, j)
			end
			AcData.DestState[i] = AcData.DestState[i] or {}
			AcData.DestState[i][j] = stream:ReadByte()
			--print("AcData.DestState[i][j]=",AcData.DestState[i][j])
			AcData.DestStateNum[i] = AcData.DestStateNum[i] or {}
			AcData.DestStateNum[i][j] = stream:ReadByte()
			--print("AcData.TargetStateNum[i][j]=",AcData.DestStateNum[i][j])
			AcData.DestBuffArr[i][j] = {}
			for k = 1, AcData.DestStateNum[i][j] do
				table.insert(AcData.DestBuffArr[i][j],stream:ReadByte())
				--print("AcData.DestBuffArr[i][j][k]=",AcData.DestBuffArr[i][j][k])
			end
		end
	end
	AcData.SrcDamage = stream:ReadInt()
	--print("AcData.SrcDamage",AcData.SrcDamage)
	AcData.SrcAbsorpionHp = stream:ReadInt()
	--print("AcData.SrcAbsorpionHp",AcData.SrcAbsorpionHp)
	AcData.SrcRecover = stream:ReadInt()
	--print("AcData.SrcRecover",AcData.SrcRecover)
	AcData.SrcState = stream:ReadByte()
	AcData.SrcStateNum = stream:ReadByte()
	--print("AcData.SrcStateNum=",AcData.SrcStateNum)
	AcData.SrcBuffArr = {}
	for k = 1, AcData.SrcStateNum do
		table.insert(AcData.SrcBuffArr,stream:ReadByte())
		--print("AcData.SrcBuffArr[k]",AcData.SrcBuffArr[k])
	end
	self:ReadAddBuff(AcData,stream)
end

function LBattleLogic:ReadAddBuff(AcData,stream)
	AcData.DestBuffNum = stream:ReadByte()
	--print("AcData.DestBuffNum",AcData.DestBuffNum)
	for i = 1, AcData.DestBuffNum do
		AcData.DestBuffBid[i] = stream:ReadByte()--目标
		--print("AcData.DestBuffBid[i]",AcData.DestBuffBid[i])
		AcData.DestBuffHpChanged[i] = stream:ReadInt()
		--print("AcData.DestBuffHpChanged[i]",AcData.DestBuffHpChanged[i])
		AcData.DestBuffAbsorpion[i] = stream:ReadInt()
		--print("AcData.DestBuffAbsorpion[i]",AcData.DestBuffAbsorpion[i])
		AcData.DestBuffHpRecover[i] = stream:ReadInt()
		--print("AcData.DestBuffHpRecover[i]",AcData.DestBuffHpRecover[i])

		AcData.DestBuffState[i] = stream:ReadByte()

		AcData.DestBuffStateNum[i] = stream:ReadByte()
		--print("AcData.DestBuffStateNum[i]",AcData.DestBuffStateNum[i])
		AcData.DestBuffStateArr[i] = {}
		for k = 1, AcData.DestBuffStateNum[i] do
			table.insert(AcData.DestBuffStateArr[i],stream:ReadByte())
			--print("AcData.DestBuffStateArr[i][k]",AcData.DestBuffStateArr[i][k])
		end
	end
end

function LBattleLogic:ReadActionRunAway(stream, AcData)
	AcData.Val = -1
	AcData.IsHit[1][1] = stream:ReadByte()
	AcData.DestBuffNum = stream:ReadByte()
	--print("AcData.DestBuffNum",AcData.DestBuffNum)
	for i = 1, AcData.DestBuffNum do
		AcData.DestBuffBid[i] = stream:ReadByte()--目标
	end
	
	-- AcData.Val = stream:ReadByte()                     --是否成功
	-- if(AcData.Val == 1 && AcData.SrcBid == _SelfPosId)  --如果逃跑成功
	-- 	_SoonClose = true
	-- _VecActions.push_back(AcData)
end

function LBattleLogic:ReadActionNewUnitIn(stream, AcData)
	--[[
targetNum   [  unitType                                                                                                             ]
		        1byte          1byte
				              =0 怪     pos     pic    scale   name   level   maxHp   hp    firstCartonType   monsterType    stateVal    quality
							           1byte   4byte   4byte  string  2byte   4byte  4byte        1byte          1byte     stateStruct    1byte
							  =2 宠物   pos    petId   scale   name   level   maxHp   hp      stateVal     petOwner    quality
							           1byte   4byte   4byte  string  2byte   4byte  4byte   stateStruct     1byte      1byte
	]]

	AcData.LianjiNum = 1
	
	AcData.DestNum[AcData.LianjiNum] = stream:ReadByte()
	--print("Num=",AcData.DestNum[AcData.LianjiNum]) 
	for i = 1, AcData.DestNum[AcData.LianjiNum] do
		local utype = stream:ReadByte()
		local bid = stream:ReadByte()
		
		local unitData = self.m_pNewUnitDatas[bid]
        unitData.m_type = utype
        unitData.m_posBid = bid
		unitData.m_id = stream:ReadUInt()
		unitData.m_scaleRatio = stream:ReadUInt() / 100.0
		unitData.m_name = stream:ReadString()
		--print("ReadBattleUnitData",utype, unitData.m_name,unitData.m_posBid)
		unitData.m_level = stream:ReadWord()
		if unitData.m_type == AppDef.BTConst.Type.Monster then  --怪物
			self:ReadMonsterData(unitData, stream)
		elseif unitData.m_type == AppDef.BTConst.Type.Pet then  --宠物神将
			self:ReadPetData(unitData, stream)
		end

		AcData.DestBid[AcData.LianjiNum] = AcData.DestBid[AcData.LianjiNum] or {}
		AcData.DestBid[AcData.LianjiNum][i] = bid
	end
end

function LBattleLogic:ReadMonster(stream, UnitData)
	UnitData.m_id = stream:ReadUInt()
	UnitData.m_scaleRatio = stream:ReadUInt() / 100.0
	UnitData.m_name = stream:ReadString()
	UnitData.m_level = stream:ReadWord()
	UnitData.m_maxHp = stream:ReadUInt()
	UnitData.m_curHp = stream:ReadUInt()
	UnitData.m_stateNum = stream:ReadByte()
	for i = 1, UnitData.m_stateNum do
		UnitData.m_states[i] = stream:ReadUInt()
	end
	
	UnitData.m_quality = stream:ReadByte()
	-- ccColor3B NameColor = quality >= 1 ? PET_QCOLOR(quality-1) : ccWHITE
	-- BattleMonster *battleMonster = BattleMonster::spriteWithData(UnitData, NameColor)
	-- battleMonster->SetTouchCallBack(this, (SEL_CallFuncNI)&BattleLayer::TouchUnitCallBack)
	-- battleMonster->AssignBuff(state)
	-- battleMonster->setTag(UnitData.posBid)
	-- battleMonster->setPosition(BT_UNIT_POS(UnitData.posBid - 1))
	-- battleMonster->ShowLv(IsShowLv)
	-- this->addChild(battleMonster,BT_UNIT_ZOR(UnitData.posBid - 1))
	-- if(quality >= 3)
	-- 	battleMonster->SetQualityEffect(quality)

	-- battleMonster->setVisible(false)
	-- _VecDelayShowUnit.push_back(battleMonster)
end

function LBattleLogic:ReadHero(stream, UnitData)
	UnitData.m_id = stream:ReadUInt()
	UnitData.m_scaleRatio = stream:ReadUInt() / 100.0
	UnitData.m_name = stream:ReadString()
	UnitData.m_level = stream:ReadWord()
	UnitData.m_prof = stream:ReadByte()
	UnitData.m_sex = stream:ReadByte()
	UnitData.m_wp = stream:ReadByte()
	UnitData.m_maxHp = stream:ReadUInt()
	UnitData.m_curHp = stream:ReadUInt()
	UnitData.m_stateNum = stream:ReadByte()
	for i = 1, UnitData.m_stateNum do
		UnitData.m_states[i] = stream:ReadUInt()
	end

	-- BattleHero *battleHero = BattleHero::spriteWithData(UnitData)
	-- battleHero->setTag(UnitData.posBid)
	-- battleHero->SetTouchCallBack(this, (SEL_CallFuncNI)&BattleLayer::TouchUnitCallBack)
	-- battleHero->setPosition(BT_UNIT_POS(UnitData.posBid - 1))
	-- battleHero->ShowLv(IsShowLv)
	-- this->addChild(battleHero,BT_UNIT_ZOR(UnitData.posBid - 1))
	-- battleHero->AssignBuff(state)
	
 --    --载入特效
	-- battleHero->AddEffect(DATA_CST->GetEffectDataByInf(HeroEffectData::HE_WEAPON, UnitData.lightEffect, UnitData.prof, UnitData.sex))
	-- battleHero->PlayAnimateByState(BattleUnitNode::BUS_NORMAL)

	-- --判断自己在什么位置
	-- if(DATA_MGR->Hero.IsMe(UnitData.id))
 --    {
	-- 	_SelfPosId = UnitData.posBid
		
 --        --需要更新界面怒气
	-- 	if(BattleMainMenu* menu = GetBattleMainMenu())
	-- 		menu->UpdateAnger(UnitData.curAnger, UnitData.maxAnger)
	-- }

	-- battleHero->setVisible(false)
	-- _VecDelayShowUnit.push_back(battleHero)
end

-- function LBattleLogic:ReadPet(stream, UnitData)
-- 	UnitData.m_id = stream:ReadUInt()
-- 	UnitData.m_scaleRatio = stream:ReadUInt() / 100.0
-- 	UnitData.m_name = stream:ReadString()
-- 	UnitData.m_level = stream:ReadWord()
-- 	UnitData.m_maxHp = stream:ReadUInt()
-- 	UnitData.m_curHp = stream:ReadUInt()
-- 	UnitData.m_stateNum = stream:ReadByte()
-- 	for i = 1, UnitData.m_stateNum do
-- 		UnitData.m_states[i] = stream:ReadUInt()
-- 	end
-- 	unitData.m_ownerPosBid = stream:ReadUInt()
-- 	unitData.m_quality = stream:ReadByte()
-- end

function LBattleLogic:InitDelayToPlayAniCallback()
	if self.m_pDelayToPlayAni == nil then
		local function DelayToPlayAni(sender)
			self:DelayToPlayAni()
		end
		self.m_pDelayToPlayAni = DelayToPlayAni
	end
end

function LBattleLogic:AddActors(actors1, actors2, bid)
	
	if bid == 0 then
		return
	end
	local btSrc = self:GetBTUnitBySid(bid)
	if btSrc ~= nil and btSrc.m_pData ~= nil and btSrc.m_pData:HasData() then
		if btSrc.m_pData.m_type == AppDef.BTConst.Type.Hero 
			or btSrc.m_pData.m_type == AppDef.BTConst.Type.Pet then
			if bid > AppDef.BTConst.MaxHalfUnitNum then
				table.insert(actors1,bid)
			else
				table.insert(actors2,bid)
			end
		end
	end
end

function LBattleLogic:DeleteBgmSrces()
	if self.m_bgmSrces == nil then
		self.m_bgmSrces = {}
		return
	end
	while #self.m_bgmSrces > 0 do
		table.remove(self.m_bgmSrces,1)
	end
end
function LBattleLogic:DealBattleAction(stream)
	--收到消息以后首先重置计时器
	-- LGameMsg.m_baseMsgWithOne:Change(LUIBattleEvent.ResetTime, self.m_waitSecs)
 --    self:SendMsg(LGameMsg.m_baseMsgWithOne)


    
	
    --设置准备状态
	self:SetOtherHeroPreparing(false)
	
	self.m_curActionInd = 0--
	self.m_actionNum = stream:ReadByte()
	local isDataError = false
	if self.m_actionNum > AppDef.BTConst.MaxActionNum then
	-- if true then
		--数据出错了
		self.m_actionNum = 0
		if self.m_state == AppDef.BTConst.BTState.Wait 
			or self.m_state == AppDef.BTConst.BTState.Action then
			self.m_state = AppDef.BTConst.BTState.Playing
			
			self:InitDelayToPlayAniCallback()
			Utils:DelayToCallFunc(self.m_pNode, self:getFightTime(1), self.m_pDelayToPlayAni)
		end
		return
	end
	--print("DOACTION",self.m_actionNum)
	self:DeleteBgmSrces()
	local actors1 = {}
	local actors2 = {}
	self:AddActors(actors1, actors2, bid)
	
	for i = 1, self.m_actionNum do
		if self.m_vecActions[i] == nil then
			AppDef.BTConst.MaxActionNum = AppDef.BTConst.MaxActionNum + 1
			self.m_vecActions[i] = LBTActionData:New()
		end
		local AcData = self.m_vecActions[i]
		AcData:Reset()
		--print("AcData",AcData)
		local action = stream:ReadByte()
		AcData.ActionType = action
		--print("AcData.ActionType",AcData.ActionType)
		if action == AppDef.BTConst.ActionType.BAT_ATTACK then--攻击
			AcData.SrcBid = stream:ReadByte()
			--print("AcData.SrcBid",AcData.SrcBid)
			self:ReadActionAttack(stream, AcData)
			self:AddActors(actors1, actors2, AcData.SrcBid)
		elseif action == AppDef.BTConst.ActionType.BAT_ADDHP then -- 加血技能
			AcData.SrcBid = stream:ReadByte()
			--print("AcData.SrcBid",AcData.SrcBid)
        	self:ReadActionAddHp(stream, AcData)
        	self:AddActors(actors1, actors2, AcData.SrcBid)
        elseif action == AppDef.BTConst.ActionType.BAT_BUFF then -- 加血技能
        	AcData.SrcBid = stream:ReadByte()
			--print("AcData.SrcBid",AcData.SrcBid)
        	self:ReadActionAddBuff(stream, AcData)
        	self:AddActors(actors1, actors2, AcData.SrcBid)
        elseif action == AppDef.BTConst.ActionType.BAT_RUNAWAY then -- 逃跑
        	AcData.SrcBid = stream:ReadByte()
			--print("AcData.SrcBid",AcData.SrcBid)
        	self:ReadActionRunAway(stream, AcData)
        elseif action == AppDef.BTConst.ActionType.BAT_PASSIVE then -- 被动buff
        	AcData.SrcBid = stream:ReadByte()
        	--print("AcData.SrcBid",AcData.SrcBid)
        	self:ReadActionPassiveBuff(stream, AcData)

        	if AcData.SrcBid > 0 then
        		if AcData.Val > 0 then
        			local hasAct = LDataConstMgr:HasBTAction(AcData.Val + 200000)
        			if hasAct then
        				AcData.Val = AcData.Val + 200000
        				AcData.ActionType = AppDef.BTConst.ActionType.BAT_BUFF
        			end
        		end
        	end
        elseif action  == AppDef.BTConst.ActionType.BAT_CHAT then--说话
        	AcData.SrcBid = stream:ReadByte()
        	--print("AcData.SrcBid",AcData.SrcBid)
        	self:ReadActionChat(stream, AcData)
        	--self:ReadActionRunAway(stream, AcData)
        elseif action == AppDef.BTConst.ActionType.BAT_CALLMONSTER then  --召唤小怪
        	self:ReadActionNewUnitIn(stream, AcData)
		end
	end


	--[[
	每回合每方随机去一到两个单位播放技能bgm
	]]
	self:DeleteBgmSrces()
	local minNum = 0
	local maxNum = 0
	if LRoleDataMgr:GetFightSpeed() == 0 then
		minNum = 3
		maxNum = 5
	elseif LRoleDataMgr:GetFightSpeed() == 1 then
		minNum = 1
		maxNum = 4
	end
	local num = math.random(minNum,maxNum)
	for i = 1,num do
		if #actors1 == 0 then
			break
		end
		local ind = math.random(1,#actors1)
		local bid = actors1[ind]
		table.remove(actors1,ind)
		table.insert(self.m_bgmSrces,bid)
	end

	num = math.random(minNum,maxNum)
	for i = 1,num do
		if #actors2 == 0 then
			break
		end
		local ind = math.random(1,#actors2)
		local bid = actors2[ind]
		table.remove(actors2,ind)
		table.insert(self.m_bgmSrces,bid)
	end
	if LRoleDataMgr:GetFightSpeed() == 3 then
		for i = 1, #actors1 do
			if actors1[i] == self.m_myHeroBid then
				table.insert(self.m_bgmSrces,actors1[i])
				break
			end
		end
		for i = 1, #actors2 do
			if actors2[i] == self.m_myHeroBid then
				table.insert(self.m_bgmSrces,actors2[i])
				break
			end
		end
	end

    --读取回合结束怒气值并缓存，在回合开始时进行更新操作

    --读取并缓存回合结束状态
	num = stream:ReadByte()
	--print("ActionEndStateNum",num)
	if num > 0 then
		self.m_actionNum = self.m_actionNum + 1
		if self.m_vecActions[self.m_actionNum] == nil then
			AppDef.BTConst.MaxActionNum = AppDef.BTConst.MaxActionNum + 1
			self.m_vecActions[self.m_actionNum] = LBTActionData:New()
		end
		local AcData = self.m_vecActions[self.m_actionNum]
		
		AcData:Reset()
		AcData.ActionType = AppDef.BTConst.ActionType.BAT_PASSIVE
		AcData.Val = 0--没有src
		AcData.LianjiNum = 1
		for i = 1, AcData.LianjiNum do
			AcData.DestNum[i] =  num
			for j = 1, AcData.DestNum[i] do
				AcData.DestBid[i] = AcData.DestBid[i] or {}
				AcData.DestBid[i][j] = stream:ReadByte()--目标
				--print("AcData.Target[i]",AcData.DestBid[i][j])
				AcData.Damage[i] = AcData.Damage[i] or {}
				AcData.Damage[i][j] = 0

				AcData.DestState[i] = AcData.DestState[i] or {}
				AcData.DestState[i][j] = stream:ReadByte()
				--print("AcData.DestState[i][j]=",AcData.DestState[i][j])
				AcData.DestStateNum[i] = AcData.DestStateNum[i] or {}
				AcData.DestStateNum[i][j] = stream:ReadByte()
				--print("AcData.DestStateNum[i][j]=",AcData.DestStateNum[i][j])
				AcData.DestBuffArr[i][j] = {}
				for k = 1, AcData.DestStateNum[i][j] do
					table.insert(AcData.DestBuffArr[i][j],stream:ReadByte())
					--print("AcData.DestBuffArr[i][j][k]=",AcData.DestBuffArr[i][j][k])
				end

				-- AcData.DestStateNum[i] = AcData.DestStateNum[i] or {}
				-- AcData.DestStateNum[i][j] = stream:ReadByte()
				-- --print("AcData.DestStateNum[i][j]",AcData.DestStateNum[i][j])
				-- for k = 1, AcData.DestStateNum[i][j] do
				-- 	AcData.DestState[i][j] = AcData.DestState[i][j] or {}
				-- 	AcData.DestState[i][j][k] = stream:ReadUInt()
				-- 	--print("AcData.DestState[i][j][k]",AcData.DestState[i][j][k])
				-- end
			end
		end
	end
	
	local heroSkillId = 0
	for i = 1, self.m_actionNum do
		local AcData = self.m_vecActions[i]
		if AcData.ActionType == AppDef.BTConst.ActionType.BAT_ATTACK
			or AcData.ActionType == AppDef.BTConst.ActionType.BAT_ADDHP
			or AcData.ActionType == AppDef.BTConst.ActionType.BAT_BUFF then
			if AcData.SrcBid == self.m_myHeroBid then
				heroSkillId = AcData.Val
			end
		end
	end
	LGameMsg.m_baseMsgWithOne:Change(LUIBattleEvent.ActionPlaying,heroSkillId)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

     --开始执行回合动画(延时1s)
	if self.m_state == AppDef.BTConst.BTState.Wait 
		or self.m_state == AppDef.BTConst.BTState.Action then
		self.m_state = AppDef.BTConst.BTState.Playing
		self:InitDelayToPlayAniCallback()
		Utils:DelayToCallFunc(self.m_pNode, self:getFightTime(1), self.m_pDelayToPlayAni)
	end
end

--[[
当前回合播放结束
]]
function LBattleLogic:PlayingOver()
	--print("PlayingOver",self.m_isOver)
	if self.m_isOver then
		self:StartEndAnimate()
	else
		self.m_state = AppDef.BTConst.BTState.Action

		if self.m_isReplay == false or LRoleDataMgr:IsReplayBattleOver() == false then
			LGameMsg.m_baseMsg:ChangeEventId(LUIBattleEvent.SelectAction)
    		self:SendMsg(LGameMsg.m_baseMsg)
    	else
    		self:DoUseSkill(0)
    	end
		-- LGameMsg.m_baseMsg:ChangeEventId(LUIBattleEvent.SelectAction)
  --   	self:SendMsg(LGameMsg.m_baseMsg)
    	--设置准备状态
		self:SetOtherHeroPreparing(true)

		Utils:SendMsg(LBattleEvent.UpdateFightHP, LRoleDataMgr.m_bossHpData)
		Utils:SendMsg(LUIBattleEvent.UpdateFightHP, LRoleDataMgr.m_bossHpData)
		-- local function TestAction()
		-- 	--print("TestAction")
		-- 	LuaNetSendMsg:QueryBattleAct(AppDef.BTConst.ActOpt.ACT_SKATK, 0)
		-- end
		-- Utils:DelayToCallFunc(self.m_pNode, 1.0,TestAction)
	end
end

function LBattleLogic:DelayToPlayAni()
	self:ActionStart()
end

function LBattleLogic:PrepareToPlayNextAction()
	for i = 1, AppDef.BTConst.MaxUnitNum do
		if self.m_pBattleUnits[i].m_pData ~= nil and self.m_pBattleUnits[i].m_pData:HasData() then
			self.m_pBattleUnits[i].m_pNode:setPosition(self.m_pBattleUnits[i].m_pData.m_srcPos)
			self.m_pBattleUnits[i]:ClearSplitNode()
		end
	end
	self:ReorderUnitByPosY()
end

--[[
处理被动buff行为
]]
function LBattleLogic:DoPassiveBuff(curAction)
	--[[
	=6 被动加血,扣血    targetNum   [  target   addHp   tarStateVal  ]
				            1byte        1byte    4byte   stateStruct
	]]
	local time = 0
	if curAction.SrcBid > 0 and curAction.Msg ~= nil and string.len(curAction.Msg) > 0 then
		local btSrc = self:GetBTUnitBySid(curAction.SrcBid)
		if btSrc then
			btSrc:ShowBuffText(curAction.Msg)
		end
	end
	for i = 1, curAction.LianjiNum do
		for j = 1, curAction.DestNum[i] do
			local btid = curAction.DestBid[i][j]
			local unitData = self.m_pUnitDatas[btid]
			local curTime = 0
			if unitData ~= nil and unitData:HasData() == true then
				
				local btDest = self:GetBTUnitBySid(curAction.DestBid[i][j])
				if curAction.Damage[i][j] > 0 then
					--加血
					curTime = curTime + 0.5

					btDest:AddHp(curAction.Damage[i][j],curAction.DestState[i][j], curAction.DestStateNum[i][j], curAction.DestBuffArr[i][j],true)
					if curAction.RecoverDemage[i][i] > 0 then
						btDest:AddHp(curAction.RecoverDemage[i][j],curAction.DestState[i][j], curAction.DestStateNum[i][j], curAction.DestBuffArr[i][j],true)
					end
				elseif curAction.Damage[i][j] < 0 then
					--扣血
					curTime = curTime + 0.5
					if curAction.RecoverDemage[i][i] > 0 then
						btDest:BeAttacked(0 - curAction.Damage[i][j],
							curAction.RecoverDemage[i][j],
							curAction.AbsorpionHp[i][j],
							curAction.DestState[i][j], 
							curAction.DestStateNum[i][j], 
							curAction.DestBuffArr[i][j],
							true, false,false)
					else
						btDest:PoisonDamage(0 - curAction.Damage[i][j],
							curAction.AbsorpionHp[i][j],
							curAction.DestState[i][j],
							curAction.DestStateNum[i][j], curAction.DestBuffArr[i][j])
					end
					
					if btDest.m_pData.m_isDead then
						btDest:InitPlayAniByStateCallback()
						Utils:DelayToCallFunc(btDest.m_pNode, self:getFightTime(0.5), btDest.m_pPlayAniByStateFunc)
					end
				else
					if curAction.RecoverDemage[i][i] > 0 then
						curTime = curTime + 0.5
						btDest:AddHp(curAction.RecoverDemage[i][j],curAction.DestState[i][j], curAction.DestStateNum[i][j], curAction.DestBuffArr[i][j],true)
					end
				end

			end
			if curTime > time then
				time = curTime
			end
		end
		
	end
	--print("DoPassiveBuff2",curAction.DestNum[1])
	for i = 1, curAction.DestNum[1] do
		local btid = curAction.DestBid[1][i]
		--print("btid",btid)
		local unitData = self.m_pUnitDatas[btid]
		if unitData ~= nil and unitData:HasData() == true then
			local btDest = self:GetBTUnitBySid(curAction.DestBid[1][i])
			--print("curAction.DestStateNum[1][i]",curAction.DestStateNum[1][i])
			--print("curAction.DestState[1][i]",curAction.DestState[1][i])
			btDest:AssignBuff(curAction.DestState[1][i], curAction.DestStateNum[1][i], curAction.DestBuffArr[1][i])
		end
	end
	return time
end

--[[
开始播放动作
]]
function LBattleLogic:ActionStart()
	self.m_curActionInd = self.m_curActionInd + 1
	if self.m_curActionInd > self.m_actionNum then
		self:PlayingOver()
		return
	end
	--print("ActionStart,",self.m_curActionInd)
	--local curAction
	
	local waitTime = 0
	while true do
		--print("self.m_curActionInd",self.m_curActionInd)
		--print("self.m_actionNum",self.m_actionNum)
		if self.m_curActionInd > self.m_actionNum then
			self:PlayingOver()
			return
		end
		--curAction = self.m_vecActions[self.m_curActionInd]
		if self.m_vecActions[self.m_curActionInd].ActionType == AppDef.BTConst.ActionType.BAT_PASSIVE then
			local buffTime = self:DoPassiveBuff(self.m_vecActions[self.m_curActionInd])
			if waitTime < buffTime then
				waitTime = buffTime
			end
		else
			break
		end
		self.m_curActionInd = self.m_curActionInd + 1
	end

	local isDataError = self:IsActionDataError(self.m_vecActions[self.m_curActionInd])
	if isDataError == true then
		--容错处理，如果没有src进行下一个动作
		self:ActionStart()
		return
	end
	if self.m_pActionLoadCallback == nil then
		local function LoadActionResComplete()
			--print("LoadActionResComplete")
			self:PlayAction(self.m_vecActions[self.m_curActionInd],waitTime)
		end
		self.m_pActionLoadCallback = LoadActionResComplete
	end
	BattlePreloadLogic:PreloadActionRes(self, self.m_vecActions[self.m_curActionInd], self.m_pActionLoadCallback)
end

--[[
检查当前回合数据有没有错误
]]
function LBattleLogic:IsActionDataError(curAction)
	if curAction.ActionType == AppDef.BTConst.ActionType.BAT_CALLMONSTER then
		return false
	end
	if curAction.ActionType == AppDef.BTConst.ActionType.BAT_ATTACK
		or curAction.ActionType == AppDef.BTConst.ActionType.BAT_ADDHP 
		or curAction.ActionType == AppDef.BTConst.ActionType.BAT_BUFF
	    or curAction.ActionType == AppDef.BTConst.ActionType.BAT_RUNAWAY
	    or curAction == AppDef.BTConst.ActionType.BAT_CHAT then -- 逃跑
        local btSrc = self:GetBTUnitBySid(curAction.SrcBid)
		if btSrc == nil then
			local app = cc.Application:getInstance()
	        local target = app:getTargetPlatform()
	        local errorMsg = "ErrorActor:" .. curAction.SrcBid
	        if AppDef.OPEN_BUGLY and target == cc.PLATFORM_OS_ANDROID then
	            -- report lua exception
	            buglyReportLuaException(errorMsg, "LBattleLogic:IsActionDataError")
	        elseif target == cc.PLATFORM_OS_IPHONE or target == cc.PLATFORM_OS_IPAD then

	        else
	        	--print(errorMsg)
	        end  
			return true
		end
    end

    if curAction.ActionType == AppDef.BTConst.ActionType.BAT_RUNAWAY
    	or curAction.ActionType == AppDef.BTConst.ActionType.BAT_CHAT then
    	return false
    end

    if curAction.ActionType == AppDef.BTConst.ActionType.BAT_ATTACK
		or curAction.ActionType == AppDef.BTConst.ActionType.BAT_ADDHP 
		or curAction.ActionType == AppDef.BTConst.ActionType.BAT_BUFF then

		for i = 1, curAction.DestBuffNum do
			local tid = curAction.DestBuffBid[i]
			local btTar = self:GetBTUnitBySid(tid)
			if btTar == nil then
				--print("Error BuffTarget=",tid)
				local app = cc.Application:getInstance()
		        local target = app:getTargetPlatform()
		        local errorMsg = "Error BuffTarget:" .. tid
		        if AppDef.OPEN_BUGLY and target == cc.PLATFORM_OS_ANDROID then
		            -- report lua exception
		            
		            buglyReportLuaException(errorMsg, "LBattleLogic:IsActionDataError")
		        else
		        	--print(errorMsg)
		        end 
				return true
			end
		end
	end
    
    for i = 1, curAction.LianjiNum do
		for j = 1, curAction.DestNum[i] do
			local tid = curAction.DestBid[i][j]
			local btTar = self:GetBTUnitBySid(tid)
			if btTar == nil then
				local app = cc.Application:getInstance()
		        local target = app:getTargetPlatform()
		        local errorMsg = "Error Target:" .. tid .. "Actor:" .. curAction.SrcBid
		        errorMsg = errorMsg .. "SkillId:" .. curAction.Val
		        if AppDef.OPEN_BUGLY and target == cc.PLATFORM_OS_ANDROID then
		            -- report lua exception
		            buglyReportLuaException(errorMsg, "LBattleLogic:IsActionDataError")
		        elseif target == cc.PLATFORM_OS_IPHONE or target == cc.PLATFORM_OS_IPAD then

		        else
		        	--print(errorMsg)
		        end 
				return true
			end
		end
	end
    
    if curAction.ActionType == AppDef.BTConst.ActionType.BAT_ATTACK then
    	for i = 1, curAction.LianjiNum do
			for j = 1, curAction.DestNum[i] do
				if curAction.Protects[i][j] > 0 then
					local protector = self:GetBTUnitBySid(curAction.Protects[i][j])
					if protector == nil then
						local errorMsg = "Error Protector:" .. tid .. "Actor:" .. curAction.SrcBid
			            errorMsg = errorMsg .. "SkillId:" .. curAction.Val
			            if AppDef.OPEN_BUGLY and target == cc.PLATFORM_OS_ANDROID then
		                -- report lua exception
		           			buglyReportLuaException(errorMsg, "LBattleLogic:IsActionDataError")
				        elseif target == cc.PLATFORM_OS_IPHONE or target == cc.PLATFORM_OS_IPAD then

				        else
				        	--print(errorMsg)
				        end
						--print("Error Protector=",protector)
						return true
					end
				end
			end
		end
	end
	return false
end

function LBattleLogic:InitDelayPlayBTActionCallback()
	if self.m_pDelayPlayFunc == nil then
		local function DelayPlayBTAction(sender)
			self:PlayBTAction()
		end
		self.m_pDelayPlayFunc = DelayPlayBTAction
	end
end

function LBattleLogic:InitDoActionCallback()
	if self.m_pDoActionFunc == nil then
		local function DoAction(curAction)
			local btSrc = self:GetBTUnitBySid(curAction.SrcBid)
			local time = 0
			if curAction.ActionType == AppDef.BTConst.ActionType.BAT_ATTACK 
				or curAction.ActionType == AppDef.BTConst.ActionType.BAT_ADDHP 
				or curAction.ActionType == AppDef.BTConst.ActionType.BAT_BUFF then -- 加血技能
				--if curAction.Val < 200000 then--buff效果大于200000
					time = btSrc:ShowSkillTextEffect(curAction.Val)
				--end
			end 
			if curAction.ActionType == AppDef.BTConst.ActionType.BAT_ATTACK then
				self:CheckAttackProtecters(curAction)
			end

	        if curAction.ActionType ~= AppDef.BTConst.ActionType.BAT_CALLMONSTER then
			    self:PlayHeroSFAudio()
	        end
	        self:InitDelayPlayBTActionCallback()
	        if btSrc then
			    Utils:DelayToCallFunc(btSrc.m_pNode, self:getFightTime(time), self.m_pDelayPlayFunc)
	        else
	            Utils:DelayToCallFunc(self.m_pNode, self:getFightTime(time), self.m_pDelayPlayFunc)
	        end
		end
		self.m_pDoActionFunc = DoAction
	end
end

function LBattleLogic:PlayAction(curAction,waitTime)
	if curAction == nil then
		self:ActionStart()
		return
	end
	if curAction ~= nil then
		curAction.StartPlayTime = os.time()
		curAction.ActCfgData = LDataConstMgr:GetBTAction(curAction.Val,curAction.ActionType)
		curAction.CurAniInd = curAction.CurAniInd + 1--
		curAction.CurTarInd = 1--
		curAction.CurLianjiInd = 1--
	end

	local btSrc = self:GetBTUnitBySid(curAction.SrcBid)
	if btSrc == nil and curAction.ActionType ~= AppDef.BTConst.ActionType.BAT_CALLMONSTER then
		self:ActionStart()
		return
	end
	self:InitDoActionCallback()
	if waitTime > 0 then
		if btSrc == nil then
			self:ActionStart()
			return
		end
		Utils:DelayToCallFunc(btSrc.m_pNode, self:getFightTime(waitTime), self.m_pDoActionFunc)
	else
		self.m_pDoActionFunc(curAction)
	end
end

function LBattleLogic:GetHeroSFAudio(curAction,isDelete)
	local hasBgm = false
	isDelete = isDelete or false
	for i = 1, #self.m_bgmSrces do
		if curAction.SrcBid == self.m_bgmSrces[i] then
			hasBgm = true
			if isDelete then
				table.remove(self.m_bgmSrces,i)
			end
			break
		end
	end

	if not hasBgm then
		return ""
	end
	local btSrc = self:GetBTUnitBySid(curAction.SrcBid)
	local soundStr
	local playFile = ""
	if btSrc.m_pData.m_type == AppDef.BTConst.Type.Hero then
		soundStr = LDataConstMgr:GetHeroSkillBgm(btSrc.m_pData.m_prof,curAction.Val)
		if soundStr == nil or string.len(soundStr) == 0 then
			soundStr = AppDef.HeroSFBGM[btSrc.m_pData.m_prof]
		    local arr = string.split(soundStr,"|")
		    local num = #arr
		    playFile = arr[math.random(1,num)]
		else
            local arr = string.split(soundStr,"|")
		    local num = #arr
		    playFile = "skill_cv/" .. arr[math.random(1,num)]
		end
	elseif btSrc.m_pData.m_type == AppDef.BTConst.Type.Pet then
		local petData = LDataConstMgr:GetPetData(btSrc.m_pData.m_id)
		if petData ~= nil then
			-- soundStr = petData:GetSkillBgm(curAction.Val)
			soundStr = PetkaPaiManager:GetSkillBgm(petData, curAction.Val)
			if soundStr ~= nil and string.len(soundStr) > 0 then
				playFile = "skill_cv/" .. soundStr
			end
		end
	end
    -- local soundStr = AppDef.HeroSFBGM[btSrc.m_pData.m_prof]
    -- local arr = string.split(soundStr,"|")
    -- local num = #arr
    -- local playFile = arr[math.random(1,num)]
    return playFile
end

function LBattleLogic:PlayHeroSFAudio()
	local curAction = self.m_vecActions[self.m_curActionInd]
    local playFile = self:GetHeroSFAudio(curAction, true)
    if LRoleDataMgr:GetFightSpeed() > 1 then
    	return
    end
    if playFile ~= nil and string.len(playFile) > 0 then
    	LGameMsg.m_baseMsgWithOne:Change(LAudioEvent.PlayBTEffect, playFile)
    	self:SendMsg(LGameMsg.m_baseMsgWithOne)
	end
end

function LBattleLogic:InitPlayActionCallback()
	if self.m_pPlayActionFunc == nil then
		local function PlayAction(curAction,isPlayAtSameTime)
			local clipData = curAction.ActCfgData.m_cfgBuf[curAction.CurAniInd]
			if clipData.m_clipType == AppDef.BTConst.ActAniType.ModelAni then
				local actData = LDataConstMgr:GetBTModelAct(clipData.m_id)
				
				if isPlayAtSameTime then
					for i = 2, curAction.DestNum[curAction.CurLianjiInd] do
						self:PlayBTModelAction(actData,i,curAction.CurLianjiInd)
					end
				end
				self:PlayBTModelAction(actData,curAction.CurTarInd,curAction.CurLianjiInd)
			elseif clipData.m_clipType == AppDef.BTConst.ActAniType.SkillAni then
				local actData = LDataConstMgr:GetBTSkAct(clipData.m_id)
				
				if isPlayAtSameTime then
					for i = 2, curAction.DestNum[curAction.CurLianjiInd] do
						self:PlayBTSkillAction(actData,i,curAction.CurLianjiInd)
					end
				end
				self:PlayBTSkillAction(actData,curAction.CurTarInd,curAction.CurLianjiInd)
			elseif clipData.m_clipType == AppDef.BTConst.ActAniType.HurtAni then
				local actData = LDataConstMgr:GetBTHurtAct(clipData.m_id)
				local lianjiInd = curAction.CurLianjiInd
				local tarInd = curAction.CurTarInd
				
				local isSplit, time = self:PlayBTHurtAction(actData,curAction.CurTarInd,curAction.CurLianjiInd)
				if isPlayAtSameTime then
					for i = 2, curAction.DestNum[curAction.CurLianjiInd] do
						self:PlayBTHurtAction(actData,i,curAction.CurLianjiInd)
					end
				end

				if isSplit == false then
					if curAction.BeatBack[lianjiInd][tarInd] == 1 then
						--有反击
						self:FanjiActionStart(time)
					else
						self:PlayNextActionClip(time)
					end
				end
				
			else
				Utils:Debug("错误的动作配置类型：" .. clipData.m_clipType)
			end
		end
		self.m_pPlayActionFunc = PlayAction
	end
end

function LBattleLogic:PlayBTAction()
	--print("PlayBTAction")
	local curAction = self.m_vecActions[self.m_curActionInd]

	if (curAction == nil or curAction.ActCfgData == nil) then
		self:ActionStart()
		return
	end

	-- if (curAction == nil or curAction.ActCfgData == nil)
 --    and curAction.ActionType ~= AppDef.BTConst.ActionType.BAT_CALLMONSTER then
	-- 	self:ActionStart()
	-- 	return
	-- end
	
	--print("PlayBTAction",self.m_curActionInd, curAction.CurAniInd,curAction.ActCfgData.m_mulitTgtInd)
	local clipData = curAction.ActCfgData.m_cfgBuf[curAction.CurAniInd]
	if clipData == nil and curAction.ActionType ~= AppDef.BTConst.ActionType.BAT_CALLMONSTER then
		self:ActionStart()
		return
	end
	local playTime = curAction.StartPlayTime

	local isPlayAtSameTime = false
	if curAction.CurAniInd >= curAction.ActCfgData.m_mulitTgtInd 
		and  curAction.ActCfgData.m_mulitType == 0 then
		--[[
		多目标同时播放
		]]
		isPlayAtSameTime = true

	end

	self:InitPlayActionCallback()

	if self.m_pRunAwayFunc == nil then
		local function RunAwayAction()
			self:PlayRunAwayAction()
		end
		self.m_pRunAwayFunc = RunAwayAction
	end

	if self.m_pChatFunc == nil then
		local function ChatAction()
			self:PlayChatAction()
		end
		self.m_pChatFunc = ChatAction
	end
	
	if self.m_pNewUnitInFunc == nil then
		local function NewUnitInAction()
			self:PlayNewUnitInAction()
		end
		self.m_pNewUnitInFunc = NewUnitInAction
	end
	

	if curAction.ActionType == AppDef.BTConst.ActionType.BAT_RUNAWAY then
		self.m_pRunAwayFunc()
	elseif curAction.ActionType == AppDef.BTConst.ActionType.BAT_CHAT then
		self.m_pChatFunc()
	elseif curAction.ActionType == AppDef.BTConst.ActionType.BAT_CALLMONSTER then
		self.m_pNewUnitInFunc()
	else
		self.m_pPlayActionFunc(curAction,isPlayAtSameTime)
	end
end

function LBattleLogic:InitNextCallback()
	if self.m_pNextCallback == nil then
		local function NextCallback()
			self:ActionStart()
		end
		self.m_pNextCallback = NextCallback
	end
end

function LBattleLogic:InitLoadBattleUnitCompleteCallback()
	if self.m_pLoadBattleUnitCompleteCallback ~= nil then
		return
	end
	local function LoadBattleUnitComplete()
		--print("LoadBattleUnitComplete")
		local curAction = self.m_vecActions[self.m_curActionInd]
		for i = 1, curAction.DestNum[1] do
			local ind
			local newBid = curAction.DestBid[1][i]
			--print("newBid",newBid)
			if self.m_bIsFlipPos then
				if newBid <= AppDef.BTConst.MaxHalfUnitNum then
					ind = newBid + AppDef.BTConst.MaxHalfUnitNum
				else
					ind = newBid - AppDef.BTConst.MaxHalfUnitNum
				end
			else
				ind = newBid
			end
			
			local btSrc = self:GetBTUnitBySid(newBid)
			if self.m_pNewUnitDatas[newBid].m_type == AppDef.BTConst.Type.Hero then
				if self.m_pNewUnitDatas[newBid].m_id == LRoleDataMgr.MyHeroInfo.id then
					color = cc.YELLOW
				else
					color = cc.WHITE
				end
				if self.m_pNewUnitDatas[newBid].m_sex == 3 then--现在改为颜色标志，只有3是红色，非3不处理
					color = cc.RED
				end
			elseif self.m_pNewUnitDatas[newBid].m_type == AppDef.BTConst.Type.Pet then
				--color = cc.WHITE
				color = AppDef:GetPetQualityColor(self.m_pNewUnitDatas[newBid].m_quality)
			else
				if self.m_pNewUnitDatas[newBid].m_quality >= 1 then
					color = AppDef:GetPetQualityColor(self.m_pUnitDatas[newBid].m_quality)
				else
					color = cc.WHITE
				end
			end
			self.m_pBattleUnitNodes[newBid]:setVisible(true)
			btSrc:NewUnitIn(self.m_pNewUnitDatas[newBid], color, self.m_bIsFlipPos)
			if self.m_pBtUnitPos[newBid] then
				self.m_pBtUnitPos[newBid]:setVisible(true)
				self.m_pBtUnitPos[newBid]:setOpacity(255)
			end
			self.m_pNewUnitDatas[newBid]:Clone(self.m_pUnitDatas[newBid])
			self.m_pUnitDatas[newBid].m_srcPos.x = self.m_pScrUnitPos[ind].x
			self.m_pUnitDatas[newBid].m_srcPos.y = self.m_pScrUnitPos[ind].y
			btSrc.m_pData = self.m_pUnitDatas[newBid]

		end

		performWithDelay(self.m_pNode, self.m_pNextCallback, 1)
	end
	self.m_pLoadBattleUnitCompleteCallback = LoadBattleUnitComplete
end

function LBattleLogic:PlayNewUnitInAction()

	self:InitNextCallback()
	self:InitLoadBattleUnitCompleteCallback()
	--print("PlayNewUnitInAction",self.m_pLoadBattleUnitCompleteCallback)
	BattlePreloadLogic:PreLoadBattleUnit(self.m_pNewUnitDatas,self.m_pLoadBattleUnitCompleteCallback)
end

function LBattleLogic:PlayChatAction()
	local curAction = self.m_vecActions[self.m_curActionInd]

	local btSrc = self:GetBTUnitBySid(curAction.SrcBid)

	self:InitNextCallback()
	if string.len(curAction.Msg) > 0 then
		btSrc:PlayChatAni(curAction.Msg,3)
	end
	performWithDelay(btSrc.m_pNode, self.m_pNextCallback, curAction.LianjiNum)
end

function LBattleLogic:RunAwayNextCallback()
	if self.m_pRunAwayNextCallback == nil then
		local function NextCallback()
			local curAction = self.m_vecActions[self.m_curActionInd]
			if curAction.IsHit[1][1] == 1 then
				local isMe = false
				for i = 1, curAction.DestBuffNum do
					local tarSrc = self:GetBTUnitBySid(curAction.DestBuffBid[i])
					if curAction.DestBuffBid[i] == self.m_myHeroBid then
						isMe = true
					end
					if tarSrc then
						tarSrc:RunAwayCallBack()
					end
				end
				if isMe then
					--主角逃跑，跳过后面动画
					self.m_curActionInd = self.m_actionNum
				end
			end
			self:ActionStart()
		end

		self.m_pRunAwayNextCallback = NextCallback
	end
end

function LBattleLogic:PlayRunAwayAction()
	local curAction = self.m_vecActions[self.m_curActionInd]

	local btSrc = self:GetBTUnitBySid(curAction.SrcBid)

	self:RunAwayNextCallback()
	btSrc:PlayRunAwayAni(curAction.IsHit[1][1],self.m_pRunAwayNextCallback)
end

--[[
回合开始前判断被击这有没有保护，有保护那么保护者移动到被击者前方
]]
function LBattleLogic:CheckAttackProtecters(curAction)
	local moveType = AppDef.BTConst.MoveType.TgtSrcPos
	for i = 1, curAction.LianjiNum do
		for j = 1, curAction.DestNum[i] do
			if curAction.Protects[i][j] > 0 then
				local protector = self:GetBTUnitBySid(curAction.Protects[i][j])
				local srcPoint, dstPoint = self:GetMoveSrcPoint(curAction.Protects[i][j], moveType, curAction.DestBid[i][j], moveType)
				protector.m_pNode:setPosition(dstPoint)
				self:TargetMoveBack(curAction.DestBid[i][j])
				break
			end
		end
	end
	self:ReorderUnitByPosY()
end

function LBattleLogic:InitHandleBuffFunc()
	if self.m_pHandleBuffFunc ~= nil then
		return
	end
	local function HandleBuff(curAction, buffSrc,i)
		if buffSrc == nil then
			return
		end
		if curAction.DestBuffHpChanged[i] < 0 then
			buffSrc:BeAttacked(0 - curAction.DestBuffHpChanged[i], 
					curAction.DestBuffHpRecover[i], 
					curAction.DestBuffAbsorpion[i],
					curAction.DestBuffState[i], 
					curAction.DestBuffStateNum[i], 
					curAction.DestBuffStateArr[i], 
					true, 
					false, 
					false)

			if curAction.DestBid[curAction.LianjiNum][tarInd] ~= curAction.DestBuffBid[i] then
				if buffSrc.m_pData.m_isDead then
					buffSrc:InitPlayAniByStateCallback()
					Utils:DelayToCallFunc(buffSrc.m_pNode, self:getFightTime(0.5), buffSrc.m_pPlayAniByStateFunc)
				end
			end
		elseif curAction.DestBuffHpChanged[i] > 0 then
			buffSrc:AddHp(curAction.DestBuffHpChanged[i],
					curAction.DestBuffState[i], 
					curAction.DestBuffStateNum[i], 
					curAction.DestBuffStateArr[i], 
					true)
			if curAction.DestBuffHpRecover[i] > 0 then
				buffSrc:AddHp(curAction.DestBuffHpRecover[i],
					curAction.DestBuffState[i], 
					curAction.DestBuffStateNum[i], 
					curAction.DestBuffStateArr[i], 
					true)
			end
		else
			if curAction.DestBuffHpRecover[i] > 0 then
				buffSrc:AddHp(curAction.DestBuffHpRecover[i],
					curAction.DestBuffState[i], 
					curAction.DestBuffStateNum[i], 
					curAction.DestBuffStateArr[i], 
					true)
			else
				buffSrc:AssignBuff(curAction.DestBuffState[i], 
					curAction.DestBuffStateNum[i], 
					curAction.DestBuffStateArr[i])
			end
			
		end
	end
	self.m_pHandleBuffFunc = HandleBuff
end


function LBattleLogic:DoAdditionalBuff(curAction,tarInd)
	self:InitHandleBuffFunc()
	for i = 1, curAction.DestBuffNum do
		local buffUnit = self:GetBTUnitBySid(curAction.DestBuffBid[i])
		self.m_pHandleBuffFunc(curAction, buffUnit, i)
	end
end

--[[
播放被击动画
]]
function LBattleLogic:PlayBTHurtAction(modelAct, tarInd, lianjiInd)
	--print("PlayBTHurtAction",tarInd, lianjiInd)
	local curAction = self.m_vecActions[self.m_curActionInd]
	local isSplit = false--是否是分身
	if tarInd > curAction.CurTarInd then
		isSplit = true
	end
	
	--local clipData = curAction.ActCfgData.m_cfgBuf[curAction.CurAniInd]
	local src = curAction.SrcBid
	local srcUnit = self:GetBTUnitBySid(src)
	local aniName = modelAct.m_file
	local dstSrc = self:GetBTUnitBySid(curAction.DestBid[lianjiInd][tarInd])
	local time = 0.5
	--print("PlayBTHurtAction",aniName,curAction.DestBid[lianjiInd][tarInd])
	if string.len(aniName) > 0 then
		-- if dstSrc == nil then
		-- 	self:ActionStart()
		-- end
		dstSrc:SetState(AppDef.BTConst.UnitActState.HIT)
		local loop = false
		if curAction.IsHit[lianjiInd][tarInd] == 0 then
			--闪避播放待机动作
			aniName = "zd"
			loop = true
		end
		playTime = dstSrc:PlayAniByName(aniName, loop, 1/self.m_speed)
		
		time = dstSrc:GetCurAniTime()
	end
	

	local combo = false
	if lianjiInd == 1 and tarInd == 1 and curAction.LianjiNum > 1 then
		if srcUnit then
			srcUnit:ShowComboEffect()
		end
	end
	local crit = false
	if curAction.Crit[lianjiInd][tarInd] == 1 then
		crit = true
	end
	local damage = curAction.Damage[lianjiInd][tarInd]
	local recover = curAction.RecoverDemage[lianjiInd][tarInd]
	local xishou = curAction.AbsorpionHp[lianjiInd][tarInd]
	--Damage, RecoverHp, stateNum, states, isNeedEffect, combo, crit
	
	if curAction.IsHit[lianjiInd][tarInd] == 1 then
		if curAction.ActionType == AppDef.BTConst.ActionType.BAT_ATTACK then
			dstSrc:BeAttacked(damage, 
							recover, 
							xishou,
							curAction.DestState[lianjiInd][tarInd], 
							curAction.DestStateNum[lianjiInd][tarInd], 
							curAction.DestBuffArr[lianjiInd][tarInd], 
							true, 
							combo, 
							crit)
			if curAction.Protects[lianjiInd][tarInd] > 0 then
				local protector = self:GetBTUnitBySid(curAction.Protects[lianjiInd][tarInd])
                protector:SetState(AppDef.BTConst.UnitActState.HIT)
		        protector:PlayAniByName("bj", false)
				protector:BeAttacked(curAction.ProtectDamages[lianjiInd][tarInd], 
							curAction.ProtectRecover[lianjiInd][tarInd], 
							curAction.ProtectAbsorpionHp[lianjiInd][tarInd], 
							curAction.ProtectState[lianjiInd][tarInd], 
							curAction.ProtectStateNum[lianjiInd][tarInd], 
							curAction.ProtectStates[lianjiInd][tarInd], 
							true, 
							false, 
							false)
			end
		elseif curAction.ActionType == AppDef.BTConst.ActionType.BAT_ADDHP then
			--print("curAction.ActionType == AppDef.BTConst.ActionType.BAT_ADDHP")
			dstSrc:AddHp(damage, 
						curAction.DestState[lianjiInd][tarInd],
						curAction.DestStateNum[lianjiInd][tarInd], 
						curAction.DestBuffArr[lianjiInd][tarInd], 
						true)
		elseif curAction.ActionType == AppDef.BTConst.ActionType.BAT_BUFF then
			if curAction.Val > 200000 then
				local oldDead = dstSrc.m_pData.m_isDead
				if damage > 0 then--加血
					dstSrc:AddHp(damage, 
						curAction.DestState[lianjiInd][tarInd],
						curAction.DestStateNum[lianjiInd][tarInd], 
						curAction.DestBuffArr[lianjiInd][tarInd], 
						true)
					if recover > 0 then
						dstSrc:AddHp(damage, 
							curAction.DestState[lianjiInd][tarInd],
							curAction.DestStateNum[lianjiInd][tarInd], 
							curAction.DestBuffArr[lianjiInd][tarInd], 
							true)
					end
				else
					dstSrc:BeAttacked(0 - damage, 
							recover, 
							xishou,
							curAction.DestStateNum[lianjiInd][tarInd], 
							curAction.DestState[lianjiInd][tarInd], 
							true, 
							false, 
							false)
				end
				
			    if not dstSrc.m_pData.m_isDead then
			        if oldDead == true then
			            --复活
			            dstSrc.m_pHpNode:SetVisible(true)
			            dstSrc:SetState(AppDef.BTConst.UnitActState.NORMAL)
			            dstSrc:PlayAniByState()
			        end
			    end
			else
				dstSrc:AssignBuff(curAction.DestStateNum[lianjiInd][tarInd], 
						curAction.DestState[lianjiInd][tarInd])
			end
			
		end
	else
		if curAction.ActionType == AppDef.BTConst.ActionType.BAT_ATTACK then
			dstSrc:BeDodge()
		end
	end

	if curAction.RespC[lianjiInd][tarInd] == 1 then--有反震
		dstSrc:PlayFanzhenEffect()
		-- srcUnit:BeAttacked(curAction.RespVal[lianjiInd][tarInd], 
		-- 			curAction.RecoverResp[lianjiInd][tarInd], 
		-- 			curAction.RespAbsorpionVal[lianjiInd][tarInd], 
		-- 			curAction.SrcStateNum, 
		-- 			curAction.SrcState, 
		-- 			true, 
		-- 			false, 
		-- 			false)
		-- if srcUnit.m_pData.m_isDead then
		-- 	srcUnit:InitPlayAniByStateCallback()
		-- 	Utils:DelayToCallFunc(srcUnit.m_pNode, self:getFightTime(0.5), srcUnit.m_pPlayAniByStateFunc)
		-- end
		--反震不处理死亡判断，在攻击结束后统一判断
		if srcUnit.m_pData then
			srcUnit:BeAttacked(curAction.RespVal[lianjiInd][tarInd], 
						curAction.RecoverResp[lianjiInd][tarInd], 
						curAction.RespAbsorpionVal[lianjiInd][tarInd], 
						srcUnit.m_pData.m_normalState, 
						srcUnit.m_pData.m_stateNum, 
						srcUnit.m_pData.m_states, 
						true, 
						false, 
						false)
		end
	end

	if  tarInd == curAction.DestNum[lianjiInd] and lianjiInd == curAction.LianjiNum then
		--最后一个被击者后面处理buff
		self:DoAdditionalBuff(curAction, tarInd)
	end

	return isSplit, time
end

function LBattleLogic.BTSkillPlayEndCallback(sender)
	sender:removeFromParent()
end

function LBattleLogic:PlayBTSkillAction(modelAct, tarInd, lianjiInd)
	--[[
	self.m_id = nil--技能效果id	
	self.m_file = nil--特效文件名称	
	self.m_moveStartType = nil--type1：初始位置；type2：播放位置
	self.m_moveEndType = nil--	type1：结束位置；type2：播放位置，和movestart一致
	self.m_moveTime = nil--	type1：位移时间ms；type2：不需要位移时间，填0
	self.m_leftOff = nil--	从左至右攻击时的偏移
	self.rightOff = nil--	从右至左攻击时的偏移
	self.m_hitpoint = nil--	1-脚；2-腰；3-头
	self.m_soundFile = nil
	self.m_shakeId = nil
	]]

	--print("PlayBTSkillAction","tarInd=",tarInd,"lianjiInd=",lianjiInd)
	local curAction = self.m_vecActions[self.m_curActionInd]
	if modelAct == nil then
		--print("ErrorAction",curAction.Val)
	end
	local isSplit = false--是否是分身
	if tarInd > curAction.CurTarInd then
		isSplit = true
	end
	
	local clipData = curAction.ActCfgData.m_cfgBuf[curAction.CurAniInd]
	local src = curAction.SrcBid
	--print("GetMoveSrcPoint",curAction.SrcBid, modelAct.m_moveStartType, curAction.DestBid[lianjiInd][tarInd], modelAct.m_moveEndType)
	local srcPoint, dstPoint = self:GetMoveSrcPoint(curAction.SrcBid, modelAct.m_moveStartType, curAction.DestBid[lianjiInd][tarInd], modelAct.m_moveEndType)
	local playTime = 0

	local skillPath = "Skill/" .. modelAct.m_file
	--[[
	AppDef.BTConst.MoveType ={
	ActSrcPos = 1,--施法者原位置
	TgtFwdPos = 2,--目标正前位置	
	TgtBakPos = 3,--目标正后位置	
	TgtColumnPos = 4,--目标列排位置	
	TgtLinePos = 5,--目标行位置	
	FightCenterPos = 6,--交战中心位置	
	ActCenterPos = 7,--我方中心位置	
	TgtCenterPos = 8,--敌方中心位置	
	ActBakPos = 9,--我方后方位置	
	TgtSrcPos = 10,--目标位置
	}
	]]
	local dir = "_l"
	local flipx = false
	local targetBid
	if modelAct.m_moveEndType == AppDef.BTConst.MoveType.ActSrcPos
		or modelAct.m_moveEndType == AppDef.BTConst.MoveType.ActCenterPos
		or modelAct.m_moveEndType == AppDef.BTConst.MoveType.TgtCenterPos then
		targetBid = src
		
	else
		targetBid = curAction.DestBid[lianjiInd][tarInd]
	end
	if self:IsInRightSide(targetBid) then
		dir = "_r"
		--1单方向不要翻转2单方向要翻转3双方向不需要翻转
		if modelAct.m_resType == 2 then
			flipx = true
		end
	else
		dir = "_l"
	end


	----1单方向不要翻转2单方向要翻转3双方向不需要翻转
	if modelAct.m_resType == 3 then
		skillPath = skillPath .. dir
	end
	
	local ani = ImodAnim:createWithFile(skillPath)
	
	ani:setScale(modelAct.m_scale)
	if flipx then
		ani:setFlippedX(flipx)
	end
	if modelAct.m_moveTime == 0 then
		
		ani:PlayNewAction(0)
		ani:SetSpeedScale(1/self.m_speed)
		local btSrc = self:GetBTUnitBySid(curAction.SrcBid)
		local btDst = self:GetBTUnitBySid(curAction.DestBid[lianjiInd][tarInd])
		if modelAct.m_moveEndType == AppDef.BTConst.MoveType.ActSrcPos then
			if btSrc ~= nil then
				btSrc.m_pNode:addChild(ani)
			end
			local tmpPoint = btSrc:GetHitPoint(modelAct.m_hitpoint)
			dstPoint.x = tmpPoint.x
			dstPoint.y = tmpPoint.y
		elseif modelAct.m_moveEndType == AppDef.BTConst.MoveType.TgtSrcPos then
			if btDst ~= nil then
				btDst.m_pNode:addChild(ani)
			end
			local tmpPoint = cc.p(0,0)
			if btDst ~= nil then
				tmpPoint = btDst:GetHitPoint(modelAct.m_hitpoint)
			end

			dstPoint.x = tmpPoint.x
			dstPoint.y = tmpPoint.y
		else
			self.m_pNode:addChild(ani)
		end
		ani:setPosition(dstPoint)

		ani:registerScriptEndCBHandler(LBattleLogic.BTSkillPlayEndCallback)
		if isSplit == false then
			local time = ani:GetCurAniTime()
			playTime = time
			self:PlayNextActionClip(time)
		end
	else
		--[[
		有移动
		]]
		ani:PlayNewAction(0,true)
		ani:SetSpeedScale(1/self.m_speed)
		self.m_pNode:addChild(ani)
		local btSrc = self:GetBTUnitBySid(curAction.SrcBid)
		local btDst = self:GetBTUnitBySid(curAction.DestBid[lianjiInd][tarInd])
		if modelAct.m_moveStartType == AppDef.BTConst.MoveType.ActSrcPos then
			local tmpPoint = cc.p(0,0)
			if btSrc ~= nil then
				tmpPoint = btSrc:GetHitPoint(modelAct.m_hitpoint)
			end
			srcPoint.x = srcPoint.x + tmpPoint.x
			srcPoint.y = srcPoint.y + tmpPoint.y
		elseif modelAct.m_moveStartType == AppDef.BTConst.MoveType.TgtSrcPos then
			local tmpPoint = cc.p(0,0)
			if btDst ~= nil then
				tmpPoint = btDst:GetHitPoint(modelAct.m_hitpoint)
			end
			srcPoint.x = srcPoint.x + tmpPoint.x
			srcPoint.y = srcPoint.y + tmpPoint.y
		end


		if modelAct.m_moveEndType == AppDef.BTConst.MoveType.ActSrcPos then
			local tmpPoint = cc.p(0,0)
			if btSrc ~= nil then
				tmpPoint = btSrc:GetHitPoint(modelAct.m_hitpoint)
			end
			dstPoint.x = dstPoint.x + tmpPoint.x
			dstPoint.y = dstPoint.y + tmpPoint.y
		elseif modelAct.m_moveEndType == AppDef.BTConst.MoveType.TgtSrcPos then
			local tmpPoint = cc.p(0,0)
			if btDst ~= nil then
				tmpPoint = btDst:GetHitPoint(modelAct.m_hitpoint)
			end
			dstPoint.x = dstPoint.x + tmpPoint.x
			dstPoint.y = dstPoint.y + tmpPoint.y
		end

		--根据目标方向调整动画的旋转方向
		-- local stepY = srcPoint.y - dstPoint.y
		-- local tan = (srcPoint.x - dstPoint.x)/stepY
		-- local ratation = math.atan(tan) * 180 / 3.14 - 90
		--print("ratation=",ratation)
		-- if stepY > 0 then
		-- 	ratation = ratation + 180
		-- end
		-- ratation = ratation + 180
		--print("ratation2=",ratation)
		local dis = cc.pSub(srcPoint, dstPoint)
		local angle = cc.pToAngleSelf(dis)/ 3.14 * 180
		--print("angle=",angle)
		-- if angle < 0 then
		-- 	angle = 0 - angle
		-- else
		-- 	angle = 90 + angle
		-- end
		angle = 0 - angle
		ani:setRotation(angle)



		local moveTime = modelAct.m_moveTime
		ani:setPosition(srcPoint)
		local sq = cc.Sequence:create(cc.MoveTo:create(self:getFightTime(moveTime), dstPoint),
						cc.CallFunc:create(LBattleLogic.BTSkillPlayEndCallback))
		ani:runAction(sq)
		if isSplit == false then
			playTime = moveTime
			self:PlayNextActionClip(moveTime)
		end
	end
	if isSplit == false then
		if string.len(modelAct.m_soundFile) > 0 then
			self:PlaySoundEffect(modelAct.m_soundFile)
		end
		if modelAct.m_shakeId > 0 then
			self:PlayScreenShake(playTime, modelAct.m_shakeId)
			--self:PlayScreenShake(modelAct.m_shakeId)
		end
	end
end

function LBattleLogic:InitMoveEndCallback()
	if self.m_pMoveEndCallback ~= nil then
		return
	end
	local function MoveEndCallback(sender)
		sender:setVisible(true)
		self:ReorderUnitByPosY()
	end
	self.m_pMoveEndCallback = MoveEndCallback
end
--[[
播放模型动作
modelAct：LBtActCfg数据结构类型
tarInd:目标下标，如果目标下标比当前目标大，说明是同时播放的，这个时候动作要搞分身，并且不检查下个动画播放
]]
function LBattleLogic:PlayBTModelAction(modelAct, tarInd, lianjiInd)
	--print("self.m_curActionInd=",self.m_curActionInd)

	local curAction = self.m_vecActions[self.m_curActionInd]
	local isSplit = false--是否是分身
	if tarInd > curAction.CurTarInd then
		isSplit = true
	end
	local dstBid = curAction.DestBid[lianjiInd][tarInd]
	local btSrc = self:GetBTUnitBySid(curAction.SrcBid)
	local btDst = self:GetBTUnitBySid(dstBid)

	-- local function SplitAniEnd(sender)
	-- 	sender:removeFromParent()
	-- end
	local playTime = 0
	local srcPoint, dstPoint = self:GetMoveSrcPoint(curAction.SrcBid, modelAct.m_moveStartType, curAction.DestBid[lianjiInd][tarInd], modelAct.m_moveEndType)
	if modelAct.m_moveTime == 0 then--不需要移动
		if not isSplit then
			--不需要分身，正常显示
			--print("不移动",dstPoint.x,dstPoint.y)
			btSrc:StopLastMoveAction()
			btSrc.m_pNode:setPosition(dstPoint)
			if string.len(modelAct.m_act) > 0 then
				btSrc:SetState(AppDef.BTConst.UnitActState.ATTACK)
				local playTime = btSrc:PlayAniByName(modelAct.m_act)--, nil, 1/self.m_speed
				local time = btSrc:GetCurAniTime()
				playTime = time
				self:PlayNextActionClip(time)
			else
				self:PlayNextActionClip(0)
			end
		else
			if string.len(modelAct.m_act) > 0 then
				local node = btSrc:CreateSplit(modelAct.m_act,dstBid)
				node:setPosition(dstPoint)
			end
		end
		
	else
		--[[
		有移动
		]]
		if not isSplit then
			--[[
			没有分身
			]]
			local isHide = false
			if string.len(modelAct.m_act) > 0 then
				btSrc:PlayAniByName(modelAct.m_act)--, nil, 1/self.m_speed
			else
				--没有动作就是闪现
				isHide = true
			end
			isHide = false
			btSrc:StopLastMoveAction()
			btSrc.m_pNode:setPosition(srcPoint)
			--print("移动=",dstPoint.x,dstPoint.y)
			
			local move = cc.MoveTo:create(self:getFightTime(modelAct.m_moveTime), dstPoint)
			--modelAct.m_moveTime = modelAct.m_moveTime * 50
			--print("modelAct.m_moveTime=",modelAct.m_moveTime)
			if isHide == false then
				--btSrc.m_pNode:runAction(move)
				btSrc:StartMoveAction(move)
			else
				btSrc.m_pNode:setVisible(false)
				self:InitMoveEndCallback()
				btSrc:StartMoveAction(move,self.m_pMoveEndCallback)
			end
			playTime = modelAct.m_moveTime
			self:PlayNextActionClip(modelAct.m_moveTime)
		elseif string.len(modelAct.m_act) > 0 then
			--[[
			有分身并且有动作
			]]
			local node = btSrc:CreateSplit(modelAct.m_act,dstBid)
			node:setPosition(srcPoint)
			local move = cc.MoveTo:create(self:getFightTime(modelAct.m_moveTime), dstPoint)
			-- local func = cc.CallFunc:create(SplitAniEnd)
			-- local sq = cc.Sequence:create(move,func)
			-- node:runAction(sq)
			node:runAction(move)
		end
		
	end
	if isSplit == false then
		if string.len(modelAct.m_soundFile) > 0 then
			self:PlaySoundEffect(modelAct.m_soundFile)
		end

		if modelAct.m_shakeId > 0 then
			self:PlayScreenShake(playTime, modelAct.m_shakeId)
			--self:PlayScreenShake(modelAct.m_shakeId)
		end
	end
	
end

function LBattleLogic:GetBTUnitBySid(bid)
	return self.m_pBattleUnits[bid]
end

--[[
目标向后移动一点
]]
function LBattleLogic:TargetMoveBack(tbid)
	local btDst = self:GetBTUnitBySid(tbid)
	if btDst == nil or btDst.m_pNode == nil then
		return
	end
	local dstSrcPoint = cc.p(btDst.m_pNode:getPosition())
	local offset = 20
	if self:IsInRightSide(tbid) then--
		dstSrcPoint.x = dstSrcPoint.x + offset
		dstSrcPoint.y = dstSrcPoint.y - offset
	else
		dstSrcPoint.x = dstSrcPoint.x - offset
		dstSrcPoint.y = dstSrcPoint.y + offset
	end
	btDst.m_pNode:setPosition(dstSrcPoint)
end

function LBattleLogic:GetMovePoint(sbid,tbid,mtype,btSrc,btDst,dstSrcPoint)
	local offset = 60
	local offsetY = 35
	local point = cc.p(0,0)
	if mtype == AppDef.BTConst.MoveType.ActSrcPos then
		point = cc.p(btSrc.m_pNode:getPosition())
	elseif mtype == AppDef.BTConst.MoveType.TgtFwdPos then
		point.x = dstSrcPoint.x
		point.y = dstSrcPoint.y
		if self:IsInRightSide(tbid) then--
			point.x = point.x - offset
			point.y = point.y + offsetY
		else
			point.x = point.x + offset
			point.y = point.y - offsetY
		end
	elseif mtype == AppDef.BTConst.MoveType.TgtBakPos then
		point.x = dstSrcPoint.x
		point.y = dstSrcPoint.y
		if self:IsInRightSide(tbid) == false then--
			point.x = point.x - offset
			point.y = point.y + offsetY
		else
			point.x = point.x + offset
			point.y = point.y - offsetY
		end
	elseif mtype == AppDef.BTConst.MoveType.TgtColumnPos then
		point = self:GetColumnPos(tbid)
	elseif mtype == AppDef.BTConst.MoveType.TgtColumnFwdPos then--目标列排正前位置
		point = self:GetColumnPos(tbid)
		if self:IsInRightSide(tbid) then--
			point.x = point.x - offset
			point.y = point.y + offset
		else
			point.x = point.x + offset
			point.y = point.y - offset
		end
	elseif mtype == AppDef.BTConst.MoveType.TgtLineFwdPos then
 		point = self:GetLinePos(tbid)
		if self:IsInRightSide(tbid) then--
			point.x = point.x - offset
			point.y = point.y + offset
		else
			point.x = point.x + offset
			point.y = point.y - offset
		end
	elseif mtype == AppDef.BTConst.MoveType.TgtLinePos then
		point = self:GetLinePos(tbid)
	elseif mtype == AppDef.BTConst.MoveType.FightCenterPos then
		point.x = self.m_centerPos.x
		point.y = self.m_centerPos.y
	elseif mtype == AppDef.BTConst.MoveType.ActCenterPos then
		point = self:GetSideCenterPos(sbid)
	elseif mtype == AppDef.BTConst.MoveType.TgtCenterPos then
		point = self:GetTargetSideCenterPos(sbid)
	elseif mtype == AppDef.BTConst.MoveType.ActBakPos then
		if self:IsInRightSide(sbid) == false then--
			point.x = point.x - offset
			point.y = point.y + offsetY
		else
			point.x = point.x + offset
			point.y = point.y - offsetY
		end
	elseif mtype == AppDef.BTConst.MoveType.TgtSrcPos then
		point.x = dstSrcPoint.x
		point.y = dstSrcPoint.y
	end
	return point
end
--[[
获取移动目的地
sbid:目的位置
stype:起始位置类型
tbid:目的位置
ttype:目的位置类型
isSplit:是否是移到分身位置
]]
function LBattleLogic:GetMoveSrcPoint(sbid,stype, tbid, ttype, isSplit)
	--[[
	ActSrcPos = 1,--施法者原位置
	TgtFwdPos = 2,--目标正前位置	
	TgtBakPos = 3,--目标正后位置	
	TgtAlignmentPos = 4,--目标列排位置	
	TgtLinePos = 5,--目标行位置	
	FightCenterPos = 6,--交战中心位置	
	ActCenterPos = 7,--我方中心位置	
	TgtCenterPos = 8,--敌方中心位置	
	ActBakPos = 9,--我方后方位置	
	TgtSrcPos = 10,--目标位置
	]]
	if isSplit == nil then
		isSplit = false
	end
	local btSrc = self:GetBTUnitBySid(sbid)
	local btDst = self:GetBTUnitBySid(tbid)
	local dstSrcPoint = cc.p(0,0)
	if btDst ~= nil and btDst.m_pNode ~= nil then
		dstSrcPoint = cc.p(btDst.m_pNode:getPosition())
	end

	if isSplit and btDst ~= nil then
		local splitNode = btDst:GetSplitNode(sbid)
		if splitNode ~= nil then
			dstSrcPoint = cc.p(splitNode:getPosition())
		end
	end

	local startPoint = cc.p(0,0)
	local dstPoint = cc.p(0,0)
	
	
	startPoint = self:GetMovePoint(sbid,tbid,stype,btSrc,btDst,dstSrcPoint)
	dstPoint = self:GetMovePoint(sbid,tbid,ttype,btSrc,btDst,dstSrcPoint)
	--print("startPoint",startPoint.x,startPoint.y,"dstPoint",dstPoint.x,dstPoint.y)
	return startPoint,dstPoint
end

--[[
获取敌方中心位置
]]
function LBattleLogic:GetTargetSideCenterPos(sbid)
	local pos = cc.p(0,0)
	if not self:IsInRightSide(sbid) then--
		local mid = AppDef.BTConst.MaxHalfUnitNum + AppDef.BTConst.ColumnUnitNum + 2
        pos.x = self.m_pScrUnitPos[mid].x
        pos.y = self.m_pScrUnitPos[mid].y
	else
		local mid = AppDef.BTConst.ColumnUnitNum + 2
		pos.x = self.m_pScrUnitPos[mid].x
        pos.y = self.m_pScrUnitPos[mid].y
	end
    return pos
end

function LBattleLogic:GetSideCenterPos(bid)
    local pos = cc.p(0,0)
	if self:IsInRightSide(bid) then--
		local mid = AppDef.BTConst.MaxHalfUnitNum + AppDef.BTConst.ColumnUnitNum + 2
        pos.x = self.m_pScrUnitPos[mid].x
        pos.y = self.m_pScrUnitPos[mid].y
	else
		local mid = AppDef.BTConst.ColumnUnitNum + 2
		pos.x = self.m_pScrUnitPos[mid].x
        pos.y = self.m_pScrUnitPos[mid].y
	end
    return pos
end
function LBattleLogic:GetColumnPos(bid)
    local pos = cc.p(0,0)
    local cbid = bid
    if bid ==1 or bid == 4 or bid == 7 then
    	cbid = 1
	elseif bid == 2 or bid == 5 or bid == 8 then
		cbid = 2
	elseif bid == 3 or bid == 6 or bid == 9 then
		cbid = 3
	elseif bid == 10 or bid == 13 or bid == 16 then
		cbid = 10
	elseif bid == 11 or bid == 14 or bid == 17 then
		cbid = 11
	else
		cbid = 12
	end
	
	if self.m_bIsFlipPos == false then
        pos.x = self.m_pScrUnitPos[cbid].x
        pos.y = self.m_pScrUnitPos[cbid].y
	else
		if cbid > AppDef.BTConst.MaxHalfUnitNum then
            pos.x = self.m_pScrUnitPos[cbid - AppDef.BTConst.MaxHalfUnitNum].x
            pos.y = self.m_pScrUnitPos[cbid - AppDef.BTConst.MaxHalfUnitNum].y
		else
            pos.x = self.m_pScrUnitPos[AppDef.BTConst.MaxHalfUnitNum + cbid].x
            pos.y = self.m_pScrUnitPos[AppDef.BTConst.MaxHalfUnitNum + cbid].y
		end
	end
    return pos
end

function LBattleLogic:GetLinePos(bid)
    local pos = cc.p(0,0)
    if bid >=1 and bid <= 3 then
    	bid = 2
	elseif bid >= 4 and bid<= 6 then
		bid = 5
	elseif bid >= 7 and bid <= 9 then
		bid = 8
	elseif bid >= 10 and bid <= 12 then
		bid = 11
	elseif bid >= 13 and bid <= 15 then
		bid = 14
	else
		bid = 17
	end
	-- if bid > AppDef.BTConst.MaxHalfUnitNum then
	-- 	bid = (bid - 1)%AppDef.BTConst.LineUnitNum + AppDef.BTConst.ColumnUnitNum * AppDef.BTConst.LineUnitNum
	-- else
	-- 	bid = (bid - 1)%AppDef.BTConst.LineUnitNum + AppDef.BTConst.ColumnUnitNum
	-- end
	if self.m_bIsFlipPos == false then
        pos.x = self.m_pScrUnitPos[bid].x
        pos.y = self.m_pScrUnitPos[bid].y
	else
		if bid > AppDef.BTConst.MaxHalfUnitNum then
            pos.x = self.m_pScrUnitPos[bid - AppDef.BTConst.MaxHalfUnitNum].x
            pos.y = self.m_pScrUnitPos[bid - AppDef.BTConst.MaxHalfUnitNum].y
		else
            pos.x = self.m_pScrUnitPos[AppDef.BTConst.MaxHalfUnitNum + bid].x
            pos.y = self.m_pScrUnitPos[AppDef.BTConst.MaxHalfUnitNum + bid].y
		end
	end
    return pos
end

--[[
是否在右方
]]
function LBattleLogic:IsInRightSide(tbid)
	local ret = false
	if self.m_bIsFlipPos == false 
	and tbid > AppDef.BTConst.MaxHalfUnitNum then--
		ret = true
	elseif self.m_bIsFlipPos == true 
		and tbid <= AppDef.BTConst.MaxHalfUnitNum then
		ret = true
	else
		ret = false
	end
	return ret
end

function LBattleLogic:PlaySoundEffect(sound)
	LGameMsg.m_baseMsgWithOne:Change(LAudioEvent.PlayBTEffect, "battle/" ..  sound)
	self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function LBattleLogic:PlayScreenShake(time, id)
	local shakeData = LDataConstMgr:GetBTShakeData(id)
	-- local function StartShake()
	-- end
	time = time* shakeData.m_delayTime
	local delay = cc.DelayTime:create(time)
	local shake = CEffectShake:create(shakeData.m_time, shakeData.m_strength)
	local seq = cc.Sequence:create(delay, shake)
	self.m_pNode:runAction(seq)
end

function LBattleLogic:DoNextAction(lastActionTime)

	local curAction = self.m_vecActions[self.m_curActionInd]

	if curAction.ActionType ~= AppDef.BTConst.ActionType.BAT_PASSIVE then
		local btSrc = self:GetBTUnitBySid(curAction.SrcBid)
		if curAction.SrcDamage > 0 then
			btSrc:AddHp(curAction.SrcDamage,curAction.SrcState, curAction.SrcStateNum, curAction.SrcBuffArr,true)
			if curAction.SrcRecover > 0 then
				btSrc:AddHp(curAction.SrcRecover,curAction.SrcState, curAction.SrcStateNum, curAction.SrcBuffArr,true)
			end
		elseif curAction.SrcDamage < 0 then
			btSrc:BeAttacked(0 - curAction.SrcDamage, 
				curAction.SrcRecover,
				curAction.SrcAbsorpionHp,
				curAction.SrcState, curAction.SrcStateNum, curAction.SrcBuffArr,true,false,false)
			--btSrc:PoisonDamage(0 - curAction.SrcDamage,curAction.SrcStateNum, curAction.SrcState)
		else
			if curAction.SrcRecover > 0 then
				btSrc:AddHp(curAction.SrcRecover,curAction.SrcState, curAction.SrcStateNum, curAction.SrcBuffArr,true)
			else
				btSrc:AssignBuff(curAction.SrcState, curAction.SrcStateNum, curAction.SrcBuffArr)
				btSrc:CheckDeadState()
				if btSrc.m_pData ~= nil and btSrc.m_pData.m_isDead then
					btSrc:InitPlayAniByStateCallback()
					Utils:DelayToCallFunc(btSrc.m_pNode, self:getFightTime(0.5), btSrc.m_pPlayAniByStateFunc)
				end
			end
		end

	end
	
	
	if self.m_pResetPosCallback == nil then
		local function ResetPos()
			self:PrepareToPlayNextAction()
		end
		self.m_pResetPosCallback = ResetPos
	end
	self:InitDelayToPlayAniCallback()

	Utils:DelayToCallFunc(self.m_pNode, self:getFightTime(lastActionTime+0.1), self.m_pResetPosCallback)
	
	Utils:DelayToCallFunc(self.m_pNode, self:getFightTime(lastActionTime+0.2), self.m_pDelayToPlayAni)
end

--[[
开始播放动作
]]
function LBattleLogic:FanjiActionStart(time)
	--print("FanjiActionStart",self.m_curActionInd)
	local curAction = self.m_vecActions[self.m_curActionInd]
	curAction.CurFanjiAniInd = 1--

	
	local srcBid = curAction.DestBid[curAction.CurLianjiInd][curAction.CurTarInd]
	local dstBid = curAction.SrcBid

	local btSrc = self:GetBTUnitBySid(srcBid)
	btSrc:FanjiActionStart(time)
	-- if self.m_pPlayFanJiEffectFunc == nil then
	-- 	local function PlayFanJiEffect()
	-- 		btSrc:PlayFanjiEffect()

	-- 		if self.m_pPlayFanjiActionFunc == nil then
	-- 			local function PlayFanjiAction()
	-- 				self:PlayBTFanjiAction(time)
	-- 			end
	-- 			self.m_pPlayFanjiActionFunc = PlayFanjiAction
	-- 		end
	-- 		Utils:DelayToCallFunc(self.m_pNode, self:getFightTime(0.2), self.m_pPlayFanjiActionFunc)
	-- 	end
	-- 	self.m_pPlayFanJiEffectFunc = PlayFanJiEffect
	-- end
	
	-- if time > 0 then
	-- 	Utils:DelayToCallFunc(self.m_pNode, self:getFightTime(time), self.m_pPlayFanJiEffectFunc)
	-- else
	-- 	self.m_pPlayFanJiEffectFunc()
	-- end
end

function LBattleLogic:InitPlayFanjiActionCallback()
	if self.m_pFanjiActionCallback ~= nil then
		return
	end
	local function PlayAction()
		local curAction = self.m_vecActions[self.m_curActionInd]
		local fanjiCfgData = LDataConstMgr:GetBTAction(0)
		local clipData = fanjiCfgData.m_cfgBuf[curAction.CurFanjiAniInd]
		local isPlayAtSameTime = false
		if curAction.CurAniInd >= curAction.ActCfgData.m_mulitTgtInd 
			and  curAction.ActCfgData.m_mulitType == 0 then
			--[[
			多目标同时播放
			]]
			isPlayAtSameTime = true

		end
		local delayTime = 0.2
		if clipData.m_clipType == AppDef.BTConst.ActAniType.ModelAni then
			local actData = LDataConstMgr:GetBTModelAct(clipData.m_id)
			
			if isPlayAtSameTime then
				for i = 2, curAction.DestNum[curAction.CurLianjiInd] do
					if curAction.BeatBack[curAction.CurLianjiInd][i] == 1 then
						local tarInd = i
						local lianjiInd = curAction.CurLianjiInd
						local function DoFanjiActionCallback()
							self:PlayBTModelFanjiAction(actData,tarInd,lianjiInd)
						end
						Utils:DelayToCallFunc(self.m_pNode, self:getFightTime(delayTime), DoFanjiActionCallback)
						delayTime = delayTime + 0.2
					end
				end
			end
			self:PlayBTModelFanjiAction(actData,curAction.CurTarInd,curAction.CurLianjiInd)
		elseif clipData.m_clipType == AppDef.BTConst.ActAniType.SkillAni then
			local actData = LDataConstMgr:GetBTSkAct(clipData.m_id)
			local isSplit, time = self:PlayBTSkillFanjiAction(actData,curAction.CurTarInd,curAction.CurLianjiInd)
			if isPlayAtSameTime then
				for i = 2, curAction.DestNum[curAction.CurLianjiInd] do
					if curAction.BeatBack[curAction.CurLianjiInd][i] == 1 then
						local tarInd = i
						local lianjiInd = curAction.CurLianjiInd
						local function DoFanjiActionCallback()
							self:PlayBTSkillFanjiAction(actData,tarInd,lianjiInd)
						end
						Utils:DelayToCallFunc(self.m_pNode, self:getFightTime(delayTime), DoFanjiActionCallback)
						delayTime = delayTime + 0.2

						--self:PlayBTSkillFanjiAction(actData,i,curAction.CurLianjiInd)
					end
					
				end
			end
			if isSplit == false then
				self:PlayNextFanjiActionClip(time)
			end
		elseif clipData.m_clipType == AppDef.BTConst.ActAniType.HurtAni then
			local actData = LDataConstMgr:GetBTHurtAct(clipData.m_id)
			local isSplit, time = self:PlayBTHurtFanjiAction(actData,curAction.CurTarInd,curAction.CurLianjiInd)
			if isPlayAtSameTime then
				for i = 2, curAction.DestNum[curAction.CurLianjiInd] do
					if curAction.BeatBack[curAction.CurLianjiInd][i] == 1 then
						local tarInd = i
						local lianjiInd = curAction.CurLianjiInd
						local function DoFanjiActionCallback()
							self:PlayBTHurtFanjiAction(actData,tarInd,lianjiInd)
						end
						Utils:DelayToCallFunc(self.m_pNode, self:getFightTime(delayTime), DoFanjiActionCallback)
						delayTime = delayTime + 0.2

						--self:PlayBTHurtFanjiAction(actData,i,curAction.CurLianjiInd)
					end
					
				end
			end
			if isSplit == false then
				self:PlayNextFanjiActionClip(time)
			end
			
		else
			Utils:Debug("错误的动作配置类型：" .. clipData.m_clipType)
		end
	end
	self.m_pFanjiActionCallback = PlayAction
end
--[[
播放反击
]]
function LBattleLogic:PlayBTFanjiAction(lastActionTime)

	--[[
	获取普通攻击当成反击的配置表
	]]
	local fanjiCfgData = LDataConstMgr:GetBTAction(0)

	local curAction = self.m_vecActions[self.m_curActionInd]
	if curAction == nil then
		self:PlayNextActionClip(lastActionTime)
		return
	end
	local clipData = fanjiCfgData.m_cfgBuf[curAction.CurFanjiAniInd]
	if clipData == nil then
		self:PlayNextActionClip(lastActionTime)
		return
	end
	
	self:InitPlayFanjiActionCallback()
	if lastActionTime > 0 then
		Utils:DelayToCallFunc(self.m_pNode, self:getFightTime(lastActionTime), self.m_pFanjiActionCallback)
	else
		self.m_pFanjiActionCallback()
	end
end

function LBattleLogic:PlayBTHurtFanjiAction(modelAct, tarInd, lianjiInd)
	local curAction = self.m_vecActions[self.m_curActionInd]
	local isSplit = false--
	if tarInd > curAction.CurTarInd then
		isSplit = true--多目标同时反击
	end
	local srcBid = curAction.DestBid[lianjiInd][tarInd]
	local dstBid = curAction.SrcBid

	local btSrc = self:GetBTUnitBySid(srcBid)
	local btDst = self:GetBTUnitBySid(dstBid)

	local aniName = modelAct.m_file
	local time = 0
	
	if isSplit == false then
		if string.len(aniName) > 0 then
			btDst:SetState(AppDef.BTConst.UnitActState.HIT)
			playTime = btDst:PlayAniByName(aniName, nil, 1/self.m_speed)
			time = btDst:GetCurAniTime()
		end
	end

	local combo = false
	
	local crit = false
	if curAction.BeatBackCrit[lianjiInd][tarInd] == 1 then
		crit = true
	end
	local damage = curAction.BeatBackDamage[lianjiInd][tarInd]
	local recover = curAction.BeatBackRecoverDemage[lianjiInd][tarInd]
	local xishou = curAction.BeatBackAbsorpionDamage[lianjiInd][tarInd]
	--Damage, RecoverHp, stateNum, states, isNeedEffect, combo, crit
	btDst:BeAttacked(damage, 
					recover, 
					xishou,
					curAction.SrcState, 
					curAction.SrcStateNum, 
					curAction.SrcBuffArr,
					true, 
					combo, 
					crit)

	-- if isSplit == false then
	-- 	self:PlayNextFanjiActionClip(time)
	-- end
	return isSplit, time
end

function LBattleLogic:PlayBTSkillFanjiAction(modelAct, tarInd, lianjiInd)
	
	local curAction = self.m_vecActions[self.m_curActionInd]
	local isSplit = false--
	--print("tarInd",tarInd,"curAction.CurTarInd",curAction.CurTarInd)
	if tarInd > curAction.CurTarInd then
		isSplit = true--多目标同时反击
	end

	local srcBid = curAction.DestBid[lianjiInd][tarInd]
	local dstBid = curAction.SrcBid
	--print("PlayBTSkillFanjiAction","srcBid",srcBid,"dstBid",dstBid)
	local btSrc = self:GetBTUnitBySid(srcBid)
	local btDst = self:GetBTUnitBySid(dstBid)
	--print("btDst",btDst,"name",btDst.m_pData.m_name,"isSplit",isSplit)
	local dstSrcNode = btDst.m_pNode
	if isSplit == true then
		dstSrcNode = btDst:GetSplitNode(dstBid)
	end

	local srcPoint, dstPoint = self:GetMoveSrcPoint(srcBid, modelAct.m_moveStartType, dstBid, modelAct.m_moveEndType, isSplit)

	local skillPath = "Skill/" .. modelAct.m_file
	
	local dir = "_l"
	local flipx = false
	local targetBid
	if modelAct.m_moveEndType == AppDef.BTConst.MoveType.ActSrcPos
		or modelAct.m_moveEndType == AppDef.BTConst.MoveType.ActCenterPos
		or modelAct.m_moveEndType == AppDef.BTConst.MoveType.TgtCenterPos then
		targetBid = srcBid
		
	else
		targetBid = curAction.DestBid[lianjiInd][tarInd]
	end
	if self:IsInRightSide(targetBid) then
		dir = "_l"
		--1单方向不要翻转2单方向要翻转3双方向不需要翻转
		if modelAct.m_resType == 2 then
			flipx = true
		end
	else
		dir = "_r"
	end


	----1单方向不要翻转2单方向要翻转3双方向不需要翻转
	if modelAct.m_resType == 3 then
		skillPath = skillPath .. dir
	end
	local ani = ImodAnim:createWithFile(skillPath)
	if flipx then
		ani:setFlippedX(flipx)
	end
	local playTime = 0
	if modelAct.m_moveTime == 0 then
		ani:PlayNewAction(0)
		ani:SetSpeedScale(1/self.m_speed)
		if modelAct.m_moveEndType == AppDef.BTConst.MoveType.ActSrcPos then
			btSrc.m_pNode:addChild(ani)
			local tmpPoint = btSrc:GetHitPoint(modelAct.m_hitpoint)
			dstPoint.x = tmpPoint.x
			dstPoint.y = tmpPoint.y
		elseif modelAct.m_moveEndType == AppDef.BTConst.MoveType.TgtSrcPos then
			dstSrcNode:addChild(ani)
			local tmpPoint = btDst:GetHitPoint(modelAct.m_hitpoint)
			dstPoint.x = tmpPoint.x
			dstPoint.y = tmpPoint.y
		else
			self.m_pNode:addChild(ani)
		end
		ani:setPosition(dstPoint)
		ani:registerScriptEndCBHandler(LBattleLogic.BTSkillPlayEndCallback)
		if isSplit == false then
			local time = ani:GetCurAniTime()
			playTime = time
			--self:PlayNextFanjiActionClip(time)
		end
	else
		--[[
		有移动
		]]
		ani:PlayNewAction(0,true)
		ani:SetSpeedScale(1/self.m_speed)
		self.m_pNode:addChild(ani)

		if modelAct.m_moveStartType == AppDef.BTConst.MoveType.ActSrcPos then
			local tmpPoint = btSrc:GetHitPoint(modelAct.m_hitpoint)
			srcPoint.x = srcPoint.x + tmpPoint.x
			srcPoint.y = srcPoint.y + tmpPoint.y
		elseif modelAct.m_moveStartType == AppDef.BTConst.MoveType.TgtSrcPos then
			local tmpPoint = btDst:GetHitPoint(modelAct.m_hitpoint)
			srcPoint.x = srcPoint.x + tmpPoint.x
			srcPoint.y = srcPoint.y + tmpPoint.y
		end


		if modelAct.m_moveEndType == AppDef.BTConst.MoveType.ActSrcPos then
			local tmpPoint = btSrc:GetHitPoint(modelAct.m_hitpoint)
			dstPoint.x = dstPoint.x + tmpPoint.x
			dstPoint.y = dstPoint.y + tmpPoint.y
		elseif modelAct.m_moveEndType == AppDef.BTConst.MoveType.TgtSrcPos then
			local tmpPoint = btDst:GetHitPoint(modelAct.m_hitpoint)
			dstPoint.x = dstPoint.x + tmpPoint.x
			dstPoint.y = dstPoint.y + tmpPoint.y
		end
		local moveTime = modelAct.m_moveTime
		ani:setPosition(srcPoint)
		local sq = cc.Sequence:create(cc.MoveTo:create(moveTime, dstPoint),
						cc.CallFunc:create(LBattleLogic.BTSkillPlayEndCallback))
		ani:runAction(cc.MoveTo:create(self:getFightTime(modelAct.m_moveTime), dstPoint))
		if isSplit == false then
			playTime = moveTime
			--self:PlayNextFanjiActionClip(moveTime)
		end
	end
	if isSplit == false then
		if string.len(modelAct.m_soundFile) > 0 then
			self:PlaySoundEffect(modelAct.m_soundFile)
		end

		if modelAct.m_shakeId > 0 then
			self:PlayScreenShake(playTime, modelAct.m_shakeId)
		end
	end
	return isSplit, playTime
end

function LBattleLogic:PlayBTModelFanjiAction(modelAct, tarInd, lianjiInd)
	--print("PlayBTModelFanjiAction=",self.m_curActionInd)
	local curAction = self.m_vecActions[self.m_curActionInd]

	local isSplit = false--
	if tarInd > curAction.CurTarInd then
		isSplit = true--多目标同时反击
	end


	
	local srcBid = curAction.DestBid[lianjiInd][tarInd]
	local dstBid = curAction.SrcBid

	local btSrc = self:GetBTUnitBySid(srcBid)
	local btDst = self:GetBTUnitBySid(dstBid)

	local srcPoint, dstPoint = self:GetMoveSrcPoint(srcBid, 
										modelAct.m_moveStartType, 
										dstBid, 
										modelAct.m_moveEndType,
										isSplit)

	local playTime = 0
	if modelAct.m_moveTime == 0 then
		--[[
		不需要移动
		]]
		btSrc:StopLastMoveAction()
		btSrc.m_pNode:setPosition(dstPoint)
		if string.len(modelAct.m_act) > 0 then
			btSrc:SetState(AppDef.BTConst.UnitActState.ATTACK)
			local playTime = btSrc:PlayAniByName(modelAct.m_act, nil, 1/self.m_speed)
			if isSplit == false then
				local time = btSrc:GetCurAniTime()
				playTime = time
				self:PlayNextFanjiActionClip(time)
			end
		else
			if isSplit == false then
				self:PlayNextFanjiActionClip(0)
			end
			--Utils:DelayToCallFunc(self.m_pNode, modelAct.m_moveTime / 1000.0, PlayAction)
		end
	else
		--[[
		有移动
		]]
		--print("modelAct.m_act=",modelAct.m_act)
		local isHide = false
		if string.len(modelAct.m_act) > 0 then
			btSrc:PlayAni(modelAct.m_act)
		else
			--没有动作就是闪现
			isHide = true
		end
		btSrc:StopLastMoveAction()
		btSrc.m_pNode:setPosition(srcPoint)
		local move = cc.MoveTo:create(self:getFightTime(modelAct.m_moveTime), dstPoint)
		if isHide == false then
			--btSrc.m_pNode:runAction(move)
			btSrc:StartMoveAction(move)
		else
			btSrc.m_pNode:setVisible(false)
			self:InitMoveEndCallback()
			btSrc:StartMoveAction(move,self.m_pMoveEndCallback)
		end
		if isSplit == false then
			playTime = modelAct.m_moveTime
			self:PlayNextFanjiActionClip(modelAct.m_moveTime)
		end
	end
	if isSplit == false then
		if string.len(modelAct.m_soundFile) > 0 then
			self:PlaySoundEffect(modelAct.m_soundFile)
		end

		if modelAct.m_shakeId > 0 then
			self:PlayScreenShake(playTime, modelAct.m_shakeId)
		end
	end
end

function LBattleLogic:PlayNextFanjiActionClip(lastActionTime)
	
	local curAction = self.m_vecActions[self.m_curActionInd]
	if curAction == nil then
		self:PlayNextActionClip(1)
		
		return
	end
	curAction.CurFanjiAniInd =  curAction.CurFanjiAniInd + 1--
	local fanjiCfgData = LDataConstMgr:GetBTAction(0)
	if curAction.CurFanjiAniInd > #fanjiCfgData.m_cfgBuf then
		--当前动作播放完成
		self:PlayNextActionClip(lastActionTime)
		
		return
	end
	local clipData = curAction.ActCfgData.m_cfgBuf[curAction.CurAniInd]
	local delayTime = clipData.m_delay * lastActionTime

	if delayTime > 0 then
		local function PlayAction()
			self:PlayBTFanjiAction(0)
		end
		Utils:DelayToCallFunc(self.m_pNode, self:getFightTime(delayTime), PlayAction)
	else
		self:PlayBTFanjiAction(0)
	end
end

--[[
lastActionTime:上一个动作播放的时间
]]
function LBattleLogic:PlayNextActionClip(lastActionTime)
	local curAction = self.m_vecActions[self.m_curActionInd]
	if curAction == nil then
		self:PlayBTAction()
		return
	end
	curAction.CurAniInd =  curAction.CurAniInd + 1--
	--print("PlayNextActionClip")
	if curAction.CurAniInd > #curAction.ActCfgData.m_cfgBuf then
		--当前动作播放完成
		local nextLianji = curAction.CurLianjiInd + 1
		if nextLianji <= curAction.LianjiNum then
			--继续连击
			--m_lianjiInd
			self:InitDelayPlayBTActionCallback()
			--print("PlayNextActionClip:curAction.CurLianjiInd",curAction.CurLianjiInd)
			curAction.CurLianjiInd = curAction.CurLianjiInd + 1
			curAction.CurAniInd = curAction.ActCfgData.m_lianjiInd
			Utils:DelayToCallFunc(self.m_pNode, self:getFightTime(lastActionTime), self.m_pDelayPlayFunc)
		else
			if curAction.CurTarInd < curAction.DestNum[curAction.CurTarInd] 
				and curAction.ActCfgData.m_mulitType == 1 then
				curAction.CurTarInd = curAction.CurTarInd + 1
				curAction.CurLianjiInd = 1
				curAction.CurAniInd = curAction.ActCfgData.m_mulitTgtInd
				local clipData = curAction.ActCfgData.m_cfgBuf[curAction.CurAniInd]
				--local delayTime = clipData.m_delay * lastActionTime
				lastActionTime = lastActionTime + 0.2
				if lastActionTime > 0 then
					self:InitDelayPlayBTActionCallback()
					Utils:DelayToCallFunc(self.m_pNode, self:getFightTime(lastActionTime), self.m_pDelayPlayFunc)
				else
					self:PlayBTAction()
				end
			else
				self:DoNextAction(lastActionTime)
			end

			
		end
		
		return
	end
	local clipData = curAction.ActCfgData.m_cfgBuf[curAction.CurAniInd]
	local delayTime = clipData.m_delay * lastActionTime

	if delayTime > 0 then
		self:InitDelayPlayBTActionCallback()
		Utils:DelayToCallFunc(self.m_pNode, self:getFightTime(delayTime), self.m_pDelayPlayFunc)
	else
		self:PlayBTAction()
	end
end


function LBattleLogic:ActionSelectOver(stream)
	local posBid = stream:ReadByte()
    local IsUseSkill = stream:ReadByte()  --是否使用技能
    local skillId = stream:ReadWord()
    local anger = stream:ReadUInt()

	-- if(DATA_MGR->Guide.IsGuiding)
	-- {
	-- 	int guideidx = GuideMgr::GetInstance()->GetCurGuideIndex()
	-- 	switch(guideidx)
	-- 	{
	-- 	case GuideMgr::GT_DRAG_SKILL_WAR:
	-- 	case GuideMgr::GT_DRAG_SKILL_WARI:
	-- 		GuideMgr::GetInstance()->CloseCurrGuide()
	-- 		break
	-- 	default:
	-- 		break
	-- 	}
	-- }

    --如果是自己，需要更新怒气值
    if self.m_myHeroBid == posBid then
        --技能释放失败
    --     if(IsUseSkill == 1 && skillId == 0)
    --     {
    --         if(BattleMainMenu* menu = GetBattleMainMenu())
    --         {
    --             menu->ShowSkillMask(false)
    --             menu->ShowMainNode(BT_PARAMS.GetAutoMode() == false)
    --             menu->ShowMiniChatLayer(BT_PARAMS.GetAutoMode())
    --         }
            
    --         TipsMgr::GetInstance()->SetCenterTip(RES_STRC(DataConsts::RSI_BL_BTT_MIN))
    --         return
    --     }

    --     --更新怒气
    --     if(BattleUnitNode* unit = (BattleUnitNode*)getChildByTag(posBid))
    --     {
    --         unit->UpdateCurrentAnger(anger)

    --         if(BattleMainMenu* menu = GetBattleMainMenu())
    --         {
    --             --立即显示怒气
    --             menu->UpdateAnger(unit->GetBattleUnitData().curAnger, unit->GetBattleUnitData().maxAnger)
    --             --显示技能屏蔽界面
    --             menu->ShowSkillMask(true, skillId)
				-- --清除技能拖拽图标
				-- CCNODE_REMOVE(_SkillDragSpr)
    --         }

    --         --怒气技能显示怒气效果
    --         if(BT_PARAMS.GetSkillAnger(skillId) > 0)
    --         {
    --             unit->SetAngerBurningEffect(true)
    --             unit->SetAngerBoomEffect(true)
    --         }
    --     }


        return
    end

    --如果不是自己并且是玩家，需要改变准备状况
    if self.m_pUnitDatas[posBid].m_type == AppDef.BTConst.Type.Hero then
    	self.m_pBattleUnits[posBid]:ShowPreparingHint(false)
	end
end

--[[
战斗协议解析
]]
function LBattleLogic:RecvDoBattle(stream)
	--[[
	
	]]
	local opt = stream:ReadByte()
	--print("RecvDoBattle",opt)
	if opt == 1 then        --回合数据
		self:DealBattleAction(stream)
	elseif opt == 2 then   --玩家下线
		--local leaveB = stream:ReadByte()
	elseif opt == 3 then   --取消自动
	elseif opt == 4 then   --剩余回合数
	elseif opt == 6 then   --技能选择完毕，准备阶段结束
		self:ActionSelectOver(stream)
	elseif opt == 7 then
	elseif opt == 8 then --Buff状态	
	end

end

--[[
根据Y坐标重置Zorder
]]
function LBattleLogic:ReorderUnitByPosY()
	for i = 1, AppDef.BTConst.MaxUnitNum do
		self.m_pNode:reorderChild(self.m_pBattleUnitNodes[i], 0 - self.m_pBattleUnitNodes[i]:getPositionY())
	end
end

--[[
进入战斗场景
]]
function LBattleLogic:RecvEnterBattle(stream)
	--print("LBattleLogic进入战斗场景 ")
	--[[
	告诉服务器不遇怪
	]]

	-- LuaNetSendMsg:QueryCanBattle(2)
	AppDef.spriteFrameCache:addSpriteFrames("csd/Plist/ui_main_iconPlist.plist","csd/Plist/ui_main_iconPlist.png")
    AppDef.spriteFrameCache:addSpriteFrames("csd/Plist/ui_zhandouPlist.plist","csd/Plist/ui_zhandouPlist.png")
	LRoleDataMgr.tmpPetUpInfo = nil
	LRoleDataMgr.isInBattle = true
	self.m_pNode:stopAllActions()
	self:ResetData()
	BattlePreloadLogic:EnterBattle()
	self.m_battleId = stream:ReadUInt()
	self.m_battleType = stream:ReadByte()
	local IsAuto = stream:ReadByte()
	if IsAuto == 1 then
		self.m_isAuto = true
	else
		self.m_isAuto = false
	end
	self.m_serverSpeed = stream:ReadByte()
	print("self.m_serverSpeed",self.m_serverSpeed)
	
	self:UpdateFightSpeed()
	-- local IsLockAuto = stream:ReadByte()
	-- if IsLockAuto == 1 then
	-- 	self.m_isLockAuto = true
	-- else
	-- 	self.m_isLockAuto = false
	-- end

	self.m_isOver = false;
	self.m_isWin = false;
	self.m_waitSecs = stream:ReadByte()
	self.m_jumpFlag = stream:ReadByte()
	self.m_battleRoundMax = stream:ReadWord()
	self.m_battleRoundIdx = stream:ReadWord()
    --LRoleDataMgr:SetFightSpeed( stream:ReadByte())
    LRoleDataMgr:SetFightSpeed(LUserConfigMgr:GetBattleSpeed())
    
	self.m_myZhenfaId = stream:ReadWord();
	self.m_myZhenfaLv = stream:ReadByte();
	self.m_enemyZhenfaId = stream:ReadWord();
	self.m_enemyZhenfaLv = stream:ReadByte();
	self.m_myFightName = stream:ReadString();
	self.m_enemyFightName = stream:ReadString();

	--print("self.m_myZhenfaId",self.m_myZhenfaId,"self.m_myZhenfaLv",self.m_myZhenfaLv,"self.m_enemyZhenfaId",self.m_enemyZhenfaId)

	self.m_bIsFlipPos = false
	--BT_PARAMS.SetBattleType(battleType, IsAuto == 1, IsLockAuto == 1, WaitSecs, battleRoundIdx, battleRoundMax, showRunAwayFlag)
	num = stream:ReadByte()
	--print("BattleUnitNum=",num)
	for i = 1, num do
		self:ReadBattleUnitData(stream)
	end

	--self:InitBattleUnit()
	
	
	local function preloadRes()
		--print("preloadRes")
		self.m_isLoadComplete = false
		self.m_isPlayStartAniComplete = false
		self.m_state = AppDef.BTConst.BTState.Wait
		self:InitBattleUI()
		self:PlayBattleStartAnimate()
		self:PreLoadBattleUnit()
	end
	--performWithDelay(self.m_pNode,preloadRes,0.2)
	preloadRes();
	
	local data = LRoleDataMgr:GetFightDatum()
	data.Names = {}
	data.Names[1] = self.m_myFightName
	data.Names[2] = self.m_enemyFightName
	data.Units = {}
	data.Units[1] = {}
	data.Units[2] = {}
	for i = 1, AppDef.BTConst.MaxUnitNum do
		if self.m_pUnitDatas[i]:HasData() then
			local tmp = {}
			tmp.name = self.m_pUnitDatas[i].m_name
			tmp.id = self.m_pUnitDatas[i].m_id
			tmp.type = self.m_pUnitDatas[i].m_type
			tmp.quality = self.m_pUnitDatas[i].m_quality
			tmp.pos = i
			if self.m_pUnitDatas[i].m_ownerPosBid == LRoleDataMgr.MyHeroInfo.id then
				table.insert(data.Units[1],tmp)
			elseif self.m_pUnitDatas[i].m_ownerPosBid == 0 then
				table.insert(data.Units[2],tmp)
			elseif tmp.pos > AppDef.BTConst.MaxHalfUnitNum then
				table.insert(data.Units[2],tmp)
			else
				table.insert(data.Units[1],tmp)
			end
		end
	end
end

function LBattleLogic:CheckBattleStart()
	if self.m_isLoadComplete and self.m_isPlayStartAniComplete then
		self.m_state = AppDef.BTConst.BTState.Action
		LGameMsg.m_baseMsg:ChangeEventId(LUIBattleEvent.SelectAction)
    	self:SendMsg(LGameMsg.m_baseMsg)

    	--设置准备状态
		self:SetOtherHeroPreparing(true)
	end
end

function LBattleLogic.AppearAniPlayEnd(sender)
	sender:stop()
	sender:setVisible(false)
end

function LBattleLogic:LoadAppearEffect()
	-- local function AniPlayEnd(sender)
	-- 	sender:stop()
	-- 	sender:setVisible(false)
	-- end
	for i = 1, AppDef.BTConst.MaxUnitNum do
		local ind
		if self.m_bIsFlipPos then
			if i <= AppDef.BTConst.MaxHalfUnitNum then
				ind = i + AppDef.BTConst.MaxHalfUnitNum
			else
				ind = i - AppDef.BTConst.MaxHalfUnitNum
			end
		else
			ind = i
		end
		self.m_pBattleUnitNodes[i]:setVisible(false)
		if self.m_pBtUnitAppearAnis[ind] == nil then
			self.m_pBtUnitAppearAnis[ind] = ImodAnim:createWithFileSync("res2/fx/loading")
			self.m_pNode:addChild(self.m_pBtUnitAppearAnis[ind],-1)
			self.m_pBtUnitAppearAnis[ind]:setPosition(cc.p(self.m_pBattleUnitNodes[ind]:getPosition()))
		end
		if self.m_pUnitDatas[i]:HasData() then
			if self.m_bIsFlipPos then
				self.m_pBtUnitAppearAnis[ind]:setVisible(true)
				self.m_pBtUnitAppearAnis[ind]:PlayAction(0)
				self.m_pBtUnitAppearAnis[ind]:registerScriptEndCBHandler(LBattleLogic.AppearAniPlayEnd)
			else
				self.m_pBtUnitAppearAnis[ind]:setVisible(true)
				self.m_pBtUnitAppearAnis[ind]:PlayAction(0)
				self.m_pBtUnitAppearAnis[ind]:registerScriptEndCBHandler(LBattleLogic.AppearAniPlayEnd)
			end
		else
			self.m_pBtUnitAppearAnis[ind]:setVisible(false)
		end
	end
end

function LBattleLogic:PreLoadBattleUnit()
	self:LoadAppearEffect()
	local function LoadBattleUnitComplete()
		--print("LoadBattleUnitComplete")
		self:InitBattleUnit()
		
		self.m_isLoadComplete = true
		self:CheckBattleStart()
	end
	BattlePreloadLogic:PreLoadBattleUnit(self.m_pUnitDatas,LoadBattleUnitComplete)
	-- self.m_loadCnt = 1
	-- local function LoadBattleUnit()
	-- 	local i = self.m_loadCnt
	-- 	local ind
	-- 	if self.m_bIsFlipPos then
	-- 		if i <= AppDef.BTConst.MaxHalfUnitNum then
	-- 			ind = i + AppDef.BTConst.MaxHalfUnitNum
	-- 		else
	-- 			ind = i - AppDef.BTConst.MaxHalfUnitNum
	-- 		end
	-- 	else
	-- 		ind = i
	-- 	end
	-- 	if self.m_pUnitDatas[i]:HasData() then
	-- 		if self.m_pUnitDatas[i].m_type == AppDef.BTConst.Type.Hero then
	-- 			if self.m_pUnitDatas[i].m_id == LRoleDataMgr.MyHeroInfo.id then
	-- 				color = cc.YELLOW
	-- 			else
	-- 				color = cc.WHITE
	-- 			end
	-- 		elseif self.m_pUnitDatas[i].m_type == AppDef.BTConst.Type.Pet then
	-- 			--color = cc.WHITE
	-- 			color = AppDef:GetPetQualityColor(self.m_pUnitDatas[i].m_quality)
	-- 		else
	-- 			if self.m_pUnitDatas[i].m_quality >= 1 then
	-- 				color = AppDef:GetPetQualityColor(self.m_pUnitDatas[i].m_quality)
	-- 			else
	-- 				color = cc.WHITE
	-- 			end
	-- 		end
	-- 		self.m_pUnitDatas[i].m_srcPos = self.m_pScrUnitPos[ind]
	-- 		self.m_pBattleUnits[i]:SetBattleUnit(self.m_pUnitDatas[i], color, self.m_bIsFlipPos)
	-- 		--self.m_pBattleUnitNodes[i]:setVisible(true)
	-- 	end
	-- end

	-- local function LoadComplete()
	-- 	for i = 1, AppDef.BTConst.MaxUnitNum do
	-- 		if self.m_pUnitDatas[i]:HasData() then
	-- 			self.m_pBattleUnitNodes[i]:setVisible(true)
	-- 			self.m_pNode:reorderChild(self.m_pBattleUnitNodes[i], 0 - self.m_pBattleUnitNodes[i]:getPositionY())
	-- 		end
	-- 	end
	-- 	--self:ReorderUnitByPosY()
	-- 	self.m_isLoadComplete = true
	-- 	self:CheckBattleStart()
	-- end

	-- local function DelayToLoad()
	-- 	LoadBattleUnit()
	-- 	self.m_loadCnt = self.m_loadCnt + 1
	-- 	if self.m_loadCnt <= AppDef.BTConst.MaxUnitNum then
	-- 		Utils:DelayToCallFunc(self.m_pNode,0.05,DelayToLoad)
	-- 	else
	-- 		Utils:DelayToCallFunc(self.m_pNode,0.05,LoadComplete)
	-- 	end
	-- end
	-- self.m_loadCnt = 1
	-- Utils:DelayToCallFunc(self.m_pNode,0.05,DelayToLoad)
end

function LBattleLogic:InitBattleUI()
	-- local unitData = self.m_pUnitDatas[self.m_myHeroBid]
	-- LGameMsg.m_baseMsgWithOne:Change(LUIBattleEvent.InitSkillCD,unitData.skillInfo)
 --    self:SendMsg(LGameMsg.m_baseMsgWithOne)

	local dataArr = {}
	dataArr.battleId = self.m_battleId;
	dataArr.battleType = self.m_battleType;
	dataArr.isAuto = self.m_isAuto;
	dataArr.isLockAuto = self.m_isLockAuto;
	dataArr.waitSec = self.m_waitSecs;
	dataArr.showJumpFlag = self.m_jumpFlag;
	dataArr.maxRound = self.m_battleRoundMax;
	dataArr.curRound = self.m_battleRoundIdx;
	-- table.insert(dataArr, self.m_battleId)
	-- table.insert(dataArr, self.m_battleType)
	-- table.insert(dataArr, self.m_isAuto)
	-- table.insert(dataArr, self.m_isLockAuto)
	-- table.insert(dataArr, self.m_waitSecs)
	-- table.insert(dataArr, self.m_jumpFlag)
	-- table.insert(dataArr, self.m_battleRoundMax)
	-- table.insert(dataArr, self.m_battleRoundIdx)
	

	local zhenfa1 = {}
	local zhenfa2 = {}
	
	for i = 1, AppDef.BTConst.MaxUnitNum do
		
		if self.m_pUnitDatas[i]:HasData() then
			if i > AppDef.BTConst.MaxHalfUnitNum then
				table.insert(zhenfa1,{i - AppDef.BTConst.MaxHalfUnitNum,self.m_pUnitDatas[i].m_name})
			else
				table.insert(zhenfa2,{i,self.m_pUnitDatas[i].m_name})
			end
		end
	end
	local myZhenfa
	local enemyZhenfa


	if not self.m_bIsFlipPos then
		dataArr.myZhenfa = zhenfa2;
		dataArr.enemyZhenfa = zhenfa1;
		dataArr.enemyZhenfaId = self.m_myZhenfaId;
		dataArr.enemyZhenfaLv = self.m_myZhenfaLv;
		dataArr.enemyName = self.m_myFightName;
		dataArr.myZhenfaId = self.m_enemyZhenfaId;
		dataArr.myZhenfaLv = self.m_enemyZhenfaLv;
		dataArr.myName = self.m_enemyFightName;
		-- myZhenfa = zhenfa2
		-- enemyZhenfa = zhenfa1
		-- table.insert(dataArr, self.m_enemyZhenfaId)
		-- table.insert(dataArr, self.m_enemyZhenfaLv)
		-- table.insert(dataArr, self.m_myZhenfaId)
		-- table.insert(dataArr, self.m_myZhenfaLv)

	else
		dataArr.myZhenfa = zhenfa1;
		dataArr.enemyZhenfa = zhenfa2;
		dataArr.enemyZhenfaId = self.m_enemyZhenfaId;
		dataArr.enemyZhenfaLv = self.m_enemyZhenfaLv;
		dataArr.enemyName = self.m_enemyFightName;
		dataArr.myZhenfaId = self.m_myZhenfaId;
		dataArr.myZhenfaLv = self.m_myZhenfaLv;
		dataArr.myName = self.m_myFightName;

		-- myZhenfa = zhenfa1
		-- enemyZhenfa = zhenfa2
		-- table.insert(dataArr, self.m_myZhenfaId)
		-- table.insert(dataArr, self.m_myZhenfaLv)
		-- table.insert(dataArr, self.m_enemyZhenfaId)
		-- table.insert(dataArr, self.m_enemyZhenfaLv)
		
		
	end
	--dump(dataArr,"------------->dataArr");
	-- table.insert(dataArr, myZhenfa)
	-- table.insert(dataArr, enemyZhenfa)
    Utils:SendMsg(LUILogicEvent.EnterBattle, dataArr, true)
end

function LBattleLogic:InitBattleUnit()
	local color
	if self.m_bIsFlipPos then
		--把节点位置翻转一下
		for i = 1, AppDef.BTConst.MaxUnitNum do
			local ind
			if i <= AppDef.BTConst.MaxHalfUnitNum then
				ind = i + AppDef.BTConst.MaxHalfUnitNum
			else
				ind = i - AppDef.BTConst.MaxHalfUnitNum
			end
			self.m_pBattleUnitNodes[i]:setPosition(self.m_pScrUnitPos[ind])
			self.m_pBtUnitPos[i]:setPosition(self.m_pScrUnitPos[ind])
			self.m_pBtUnitPos[i]:setVisible(false)
		end
	else
		for i = 1, AppDef.BTConst.MaxUnitNum do
			self.m_pBattleUnitNodes[i]:setPosition(self.m_pScrUnitPos[i])
			self.m_pBtUnitPos[i]:setPosition(self.m_pScrUnitPos[i])
			self.m_pBtUnitPos[i]:setVisible(false)
		end
	end
	----dump(self.m_pUnitDatas, "self.m_pUnitDatas--->")
	for i = 1, AppDef.BTConst.MaxUnitNum do
		local ind
		if self.m_bIsFlipPos then
			if i <= AppDef.BTConst.MaxHalfUnitNum then
				ind = i + AppDef.BTConst.MaxHalfUnitNum
			else
				ind = i - AppDef.BTConst.MaxHalfUnitNum
			end
		else
			ind = i
		end
		if self.m_pUnitDatas[i]:HasData() then
			
			if self.m_pUnitDatas[i].m_type == AppDef.BTConst.Type.Hero then
				if self.m_pUnitDatas[i].m_id == LRoleDataMgr.MyHeroInfo.id then
					color = cc.YELLOW
				else
					color = cc.WHITE
				end
				if self.m_pUnitDatas[i].m_sex == 3 then--现在改为颜色标志，只有3是红色，非3不处理
					color = cc.RED
				end
			elseif self.m_pUnitDatas[i].m_type == AppDef.BTConst.Type.Pet then
				--color = cc.WHITE
				color = AppDef:GetPetQualityColor(self.m_pUnitDatas[i].m_quality)
			else
				if self.m_pUnitDatas[i].m_quality >= 1 then
					color = AppDef:GetPetQualityColor(self.m_pUnitDatas[i].m_quality)
				else
					color = cc.WHITE
				end
			end
			self.m_pUnitDatas[i].m_srcPos.x = self.m_pScrUnitPos[ind].x
			self.m_pUnitDatas[i].m_srcPos.y = self.m_pScrUnitPos[ind].y
			self.m_pBattleUnits[i]:SetBattleUnit(self.m_pUnitDatas[i], color, self.m_bIsFlipPos)
			self.m_pBattleUnitNodes[i]:setVisible(true)
			
			if self.m_pBtUnitPos[i] then
				self.m_pBtUnitPos[i]:setOpacity(255)
				self.m_pBtUnitPos[i]:setVisible(true)
				----dump({i}, "--------------------->true")
			end
		else
			self.m_pBattleUnitNodes[i]:setVisible(false)

			local fid,index = nil,nil
			if self.m_pBtUnitPos[i] then
				-- self.m_pBtUnitPos[i]:setVisible(false)

				if i <= AppDef.BTConst.MaxHalfUnitNum then
					
					fid = self.m_enemyZhenfaId
					if self.m_bIsFlipPos then
						fid = self.m_myZhenfaId
					end
					index = i
				else
					fid = self.m_myZhenfaId
					if self.m_bIsFlipPos then
						fid = self.m_enemyZhenfaId
					end
					index = i - AppDef.BTConst.MaxHalfUnitNum
				end
			end
			
			--if fid and index then
				----dump({i, index, fid}, "--------------------->")
				local data = LDataConstMgr:GetFormationDataById(fid)
				-- --print("index",index)
				-- --dump(data.posList,"data.posList")
				if data and data.posList and Utils:containValue(data.posList, index) then
					self.m_pBtUnitPos[i]:setOpacity(100)
					self.m_pBtUnitPos[i]:setVisible(true)
					----dump("=================>true:125")
				else
					self.m_pBtUnitPos[i]:setVisible(false)
				-- 	-- --dump("=================:false")
				end
			--end
		end
	end
	self:ReorderUnitByPosY()
end

-- --[[
-- 获取战斗单元初始位置
-- param1:bid,逻辑站位
-- return:pos
-- ]]
-- function LBattleLogic:GetBattleUnitSrcPos(bid)
-- 	if self.m_bIsFlipPos then
-- 		return self.m_pScrUnitPos[AppDef.BTConst.MaxUnitNum - bid + 1]
-- 	else
-- 		return self.m_pScrUnitPos[bid]
-- 	end
-- end

--播放开始战斗动画
function LBattleLogic:PlayBattleStartAnimate()
	local function BlackPlayEnd(sender)
		sender:removeFromParent()
	end
    local layerBlack = cc.LayerColor:create(cc.c4b(0,0,0,150))
    layerBlack:setAnchorPoint(cc.p(0,0))
    layerBlack:setPosition(cc.p(AppDef.Director:getVisibleOrigin()))
    layerBlack:setContentSize(AppDef.Director:getVisibleSize())
    self.m_pNode:addChild(layerBlack, 4999)

    layerBlack:runAction(cc.Sequence:create(cc.DelayTime:create(0.9), cc.FadeTo:create(0.2, 0), cc.CallFunc:create(BlackPlayEnd)))

	if self.m_startAni == nil then
		self.m_startAni = ImodAnim:createWithFileSync("res2/fx/zhandoukaishi")
		self.m_startAni:setPosition(cc.p(AppDef.frameSize.width/2,AppDef.frameSize.height - 353))
		self.m_pNode:addChild(self.m_startAni, 5001)

		local function AniPlayEnd(sender)
			self.m_startAni:stop()
			self.m_startAni:setVisible(false)
		end
		self.m_startAni:registerScriptEndCBHandler(AniPlayEnd)
	else
		self.m_startAni:setVisible(true)
	end
	
	self.m_startAni:PlayAction(0)
	
	-- if self.m_pStartAniFunc == nil then
		
	-- 	self.m_pStartAniFunc = AniPlayEnd
	-- end

	
    
	

    -- local layerBlack = cc.LayerColor:create(cc.c4b(0,0,0,150))
    -- layerBlack:setAnchorPoint(cc.p(0,0))
    -- -- layerBlack:setContentSize(wsize)  --960,640
    -- self.m_pNode:addChild(layerBlack, 4999)

    -- layerBlack:runAction(cc.Sequence:create(cc.DelayTime:create(0.9), cc.FadeTo:create(0.2, 0), cc.CallFunc:create(AniPlayEnd)))
    if self.m_pStartEffOverCallback == nil then
    	local function StartEffectPlayOverAction()
    		--print("StartEffectPlayOverAction")
			self.m_isPlayStartAniComplete = true
			self:CheckBattleStart()
		end
		self.m_pStartEffOverCallback = StartEffectPlayOverAction
    end
	

	Utils:DelayToCallFunc(self.m_pNode, self:getFightTime(1), self.m_pStartEffOverCallback)
end

function LBattleLogic:ReadHeroData(unitData, stream)
	unitData.m_maxPlaySpeed = stream:ReadByte()
    unitData.m_fixedPlaySpeed = stream:ReadByte()
	unitData.m_prof = stream:ReadByte()
	unitData.m_sex = stream:ReadByte()--现在改为颜色标志，只有3是红色，非3不处理
	unitData.m_wp = stream:ReadByte()
    unitData.m_lightEffect = stream:ReadByte()
	unitData.m_maxHp = stream:ReadUInt()
	unitData.m_curHp = stream:ReadUInt()
	unitData.m_stateNum = stream:ReadByte()
	--print("unitData.m_stateNum",unitData.m_stateNum)
	for i = 1, unitData.m_stateNum do
		unitData.m_states[i] = stream:ReadUInt()
		--print("unitData.m_states",unitData.m_states[i])
	end

	--[[
	2、在人物信息读取最后添加  num   {  skillId    CD  }
								1byte    2byte    1byte
	]]
	local num = stream:ReadByte()
	for i = 1, num do
		local skillId = stream:ReadWord()
		local curCd = stream:ReadByte()
		table.insert(unitData.skillInfo,{skillId,curCd})
	end
end

function LBattleLogic:ReadMonsterData(unitData, stream)
	unitData.m_maxHp = stream:ReadULongInt()
	--print("unitData.m_maxHp",unitData.m_maxHp)
	unitData.m_curHp = stream:ReadULongInt()
	--print("unitData.m_curHp",unitData.m_curHp)
	if stream:ReadByte() == 1 then
		unitData.m_spShow = true
	else
		unitData.m_spShow = false
	end
	
	local enemyType = stream:ReadByte()
	unitData.m_normalState = stream:ReadByte()
	unitData.m_stateNum = stream:ReadByte()
	--print("unitData.m_stateNum",unitData.m_stateNum)
	unitData.m_states = {}
	for i = 1, unitData.m_stateNum do
		table.insert(unitData.m_states,stream:ReadByte())
		--print("unitData.m_states",unitData.m_states[i])
	end

	unitData.m_quality = stream:ReadByte()
	unitData.m_isBoss = (stream:ReadByte() == 1)
	if unitData.m_isBoss then
		Utils:SendMsg(LUIBattleEvent.ShowFightHP, unitData)
	end
	--print("unitData.m_quality",unitData.m_quality)
end

function LBattleLogic:ReadPetData(unitData, stream)
	unitData.m_maxHp = stream:ReadULongInt()
	unitData.m_curHp = stream:ReadULongInt()
	unitData.m_normalState = stream:ReadByte()
	unitData.m_stateNum = stream:ReadByte()
	--print("unitData.m_stateNum",unitData.m_stateNum)
	unitData.m_states = {}
	for i = 1, unitData.m_stateNum do
		table.insert(unitData.m_states,stream:ReadByte())
		--print("unitData.m_states",unitData.m_states[i])
	end
	unitData.m_ownerPosBid = stream:ReadUInt()
	unitData.m_quality = stream:ReadByte()
	unitData.m_star = stream:ReadByte()
	unitData.m_tupo = stream:ReadByte()
	--print("unitData.m_quality",unitData.m_quality)
end

function LBattleLogic:ReadBattleUnitData(stream)
	local utype = stream:ReadByte()
	local bid = stream:ReadByte()
	--print("ReadBattleUnitData",utype,bid)
	local unitData = self.m_pUnitDatas[bid]
	unitData.m_type = utype
	unitData.m_posBid = bid
    unitData.m_id = stream:ReadUInt()
	unitData.m_scaleRatio = stream:ReadUInt() / 100.0
	unitData.m_name = stream:ReadString();
	--print("ReadBattleUnitData",utype, unitData.m_name,unitData.m_posBid)
	unitData.m_level = stream:ReadWord()
	--print("unitData.m_level",unitData.m_level)
	-- if unitData.m_type == AppDef.BTConst.Type.Hero then  --英雄
	-- 	if unitData.m_id == LRoleDataMgr.MyHeroInfo.id then
	-- 		self.m_myHeroBid = bid
	-- 		if bid <= AppDef.BTConst.MaxHalfUnitNum then
	-- 			self.m_bIsFlipPos = true
	-- 		else
	-- 			self.m_bIsFlipPos = false
	-- 		end
	-- 	end
	-- 	self:ReadHeroData(unitData, stream)
	-- elseif unitData.m_type == AppDef.BTConst.Type.Monster then  --怪物
	if unitData.m_type == AppDef.BTConst.Type.Monster then  --怪物
		self:ReadMonsterData(unitData, stream)
	elseif unitData.m_type == AppDef.BTConst.Type.Pet then  --宠物神将
		self:ReadPetData(unitData, stream)
		--print("unitData.m_ownerPosBid",unitData.m_ownerPosBid, "LRoleDataMgr.MyHeroInfo.id",LRoleDataMgr.MyHeroInfo.id)
		if unitData.m_ownerPosBid == LRoleDataMgr.MyHeroInfo.id then
			self.m_myHeroBid = bid
			if bid <= AppDef.BTConst.MaxHalfUnitNum then
				self.m_bIsFlipPos = true
			else
				self.m_bIsFlipPos = false
			end
		end
	end
end

function LBattleLogic:ResetData()
	for i = 1, AppDef.BTConst.MaxUnitNum do
		self.m_pBattleUnits[i]:Reset()
		self.m_pUnitDatas[i]:Reset()
		self.m_pBattleUnitNodes[i]:stopAllActions()
	end
	for i = 1,AppDef.BTConst.MaxActionNum do
		self.m_vecActions[i]:Reset()
	end
	self:DeleteBgmSrces()
	self.m_isOver = false
	self.m_isWin = false;
	self.m_isJump = false;
	self.m_state = AppDef.BTConst.BTState.Wait
	self.m_pBuffLayer:setVisible(false)
	self:UpdateFightSpeed()

	BattleHpTextPool:Reset()
end

--[[
退出战斗场景
]]
function LBattleLogic:RecvBattleOver(stream)
	--print("RecvBattleOver")
	--关闭BattleLayer
	local mid = stream:ReadUInt()--4字节战斗id
	local succ = false
	self.m_isWin = false;
	if stream:ReadByte() == 1 then
		--print("WinWinWinWinWinWinWin")
		self.m_isWin = true;
		succ = true
	end

	local num = stream:ReadByte()
	for i=1,num do
		local values = {}
		local pos = stream:ReadByte()
		for k = 1,3 do
			values[k] = stream:ReadULongInt()
		end
		--print("RecvBattleOver pos,value",pos,values[1],values[2],values[3])
		LRoleDataMgr:SetFightDatum(pos,values)
	end
	LRoleDataMgr:UpdateFightDatum()

	if LWWDXMgr:isInWWDXBattle() then
		LWWDXMgr:loadAfterBattleData(succ)
	end
    
	if not succ then
		LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Tower.NewTowerUI")
        self:SendMsg(LGameMsg.m_initUIMsg)

        -- if LRoleDataMgr.MyHeroInfo.SceneType ~= AppDef.SceneType.MSI_SHENJIEMIJING and not LWWDXMgr:isInWWDXBattle()  then
        -- 	LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "FirstAward.FirstRewardUI",AppDef.UIType.PopWindow, {0})
        -- 	self:SendMsg(LGameMsg.m_initUIMsg)
        -- end
        if LRoleDataMgr.MyHeroInfo.SceneType == AppDef.SceneType.MSI_FIARYLAND
        	or LRoleDataMgr.MyHeroInfo.SceneType == AppDef.SceneType.MSI_LUNDAO then
        	--指定场景战斗失败暂停寻路
        	LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.AutoPathEvent.StopAutoPath)
    		self:SendMsg(LGameMsg.m_cBaseMsg)
        end
	end
	
	self.m_isOver = false
	--print("self.m_state",self.m_state)
	if self.m_state == AppDef.BTConst.BTState.Playing then
		--print("11111111111111111111111")
		self.m_isOver = true
	else
		--print("22222222222222222222")
		self:StartEndAnimate()
	end
	--print("RecvBattleOver  isOver=",self.m_isOver)
	if self.m_isJump == true then
		self:StartEndAnimate()
	end
    local st = LRoleDataMgr.MyHeroInfo:GetSceneType()
    if st == AppDef.SceneType.MSI_FACTION_WAR then
		LuaNetSendMsg:QueryBangPaiWarInfo(7)
    end
end

function LBattleLogic:StartEndAnimate()
	--print("StartEndAnimate")
    --结束战斗动画
    local function BattleEndAnimateCallBack()
		self:BattleEndAnimateCallBack()
	end
    
    Utils:DelayToCallFunc(self.m_pNode, self:getFightTime(1), BattleEndAnimateCallBack)
end

function LBattleLogic:EndBattle()
	self.m_pNode:stopAllActions()
	self:ResetData()
	BattlePreloadLogic:ExitBattle()
end

--战斗结束动画回调
function LBattleLogic:BattleEndAnimateCallBack()
	--print("BattleEndAnimateCallBack")
	local isWin = self.m_isWin;
	self:EndBattle()

	if self.m_isReplay == true and LRoleDataMgr.m_rePlayType == 4 then
		LGameMsg.m_baseMsg:ChangeEventId(LGameEvent.ExitBattle)
    	self:SendMsg(LGameMsg.m_baseMsg)
		return
	end
	--print("========== BattleEndAnimateCallBack ================>>")
	if LRoleDataMgr.m_fightResultData == nil then
		print("========== BattleEndAnimateCallBack 11111111111111 ================>>")
		-- LRoleDataMgr.m_fightResultData = {}
		LGameMsg.m_baseMsg:ChangeEventId(LGameEvent.ExitBattle)
    	self:SendMsg(LGameMsg.m_baseMsg)
	else

		print("========== BattleEndAnimateCallBack 2222222222222222 ================>>")

		LRoleDataMgr.m_fightResultData.win = isWin;
		Utils:InitUI("FuBenMap.FirstFightResultUI", AppDef.UIType.SpecialLayer, LRoleDataMgr.m_fightResultData)
	end
end

-------------------------------------------------------------------------------------------
-------------------------预加载相关-----------------------------------------------------
BattlePreloadLogic = {}
BattlePreloadLogic.isPreloading = false
--需要预加载的资源列表
BattlePreloadLogic.PicResArr = {}
--需要预加载的资源列表
BattlePreloadLogic.AudioResArr = {}

--整场战斗用到的资源列表
BattlePreloadLogic.UsedTex2DArr = {}
--整场战斗用到的资源列表
BattlePreloadLogic.UsedAudioResArr = {}

BattlePreloadLogic.TextureCache = nil
BattlePreloadLogic.AudioEngine = nil
--[[
添加到待异步加载的资源数组
]]
function BattlePreloadLogic:AddResBuffer(picRes)
	for i = 1, #BattlePreloadLogic.PicResArr do
		if BattlePreloadLogic.PicResArr[i] == picRes then
			return
		end
	end
	table.insert(BattlePreloadLogic.PicResArr,picRes)
end

--[[
添加到待异步加载的资源数组
]]
function BattlePreloadLogic:AddAudioResBuffer(audioRes)
	if audioRes == nil or string.len(audioRes) == 0 then
		return
	end
	for i = 1, #BattlePreloadLogic.AudioResArr do
		if BattlePreloadLogic.AudioResArr[i] == audioRes then
			return
		end
	end
	table.insert(BattlePreloadLogic.AudioResArr,audioRes)
end

function BattlePreloadLogic:AddUsedAudioArr(audioRes)
	for i = 1, #BattlePreloadLogic.UsedAudioResArr do
		if BattlePreloadLogic.UsedAudioResArr[i] == audioRes then
			return
		end
	end
	table.insert(BattlePreloadLogic.UsedAudioResArr,audioRes)
end


--[[
添加到使用列表
@param1:filePath, 路径
@param2:tex，Texture2D变量，可以为空
]]
function BattlePreloadLogic:AddUsedTex2dArr(filePath, tex)
	for i = 1, #BattlePreloadLogic.UsedTex2DArr do
		if BattlePreloadLogic.UsedTex2DArr[i][1] == filePath then
			return
		end
	end
	if tex ~= nil then
		tex:retain()
		-- --dump({filePath, tex:getReferenceCount()}, "tex:getReferenceCount()retain-->")
	end
	table.insert(BattlePreloadLogic.UsedTex2DArr, {filePath,tex})
end

--[[
退出战斗，清空图片资源
]]
function BattlePreloadLogic:EnterBattle()
	self:InitUsedTex2DArr()
	BattlePreloadLogic.UsedAudioResArr = {}
end

function BattlePreloadLogic:InitUsedTex2DArr()
	if BattlePreloadLogic.UsedTex2DArr then
		while #BattlePreloadLogic.UsedTex2DArr > 0 do
			local tex = BattlePreloadLogic.UsedTex2DArr[1][2]
			local filePath = BattlePreloadLogic.UsedTex2DArr[1][1]
			if tex == nil then
				BattlePreloadLogic.TextureCache:removeTextureForKey(filePath)
			else
				if tex:getReferenceCount() == 1 then
					BattlePreloadLogic.TextureCache:removeTextureForKey(filePath)
				elseif tex:getReferenceCount() == 2 then
					tex:release()
					BattlePreloadLogic.TextureCache:removeTextureForKey(filePath)
				end
			end
			BattlePreloadLogic.UsedTex2DArr[1][2] = nil
			BattlePreloadLogic.UsedTex2DArr[1][1] = nil
			table.remove(BattlePreloadLogic.UsedTex2DArr,1)
		end
	else
		BattlePreloadLogic.UsedTex2DArr = {}
	end
	
end

function BattlePreloadLogic:DeleteAudioRes()
	if BattlePreloadLogic.AudioResArr ~= nil then
		while #BattlePreloadLogic.AudioResArr > 0 do
			table.remove(BattlePreloadLogic.AudioResArr,1)
		end
	end
end

function BattlePreloadLogic:DeletePicRes()
	if BattlePreloadLogic.PicResArr ~= nil then
		while #BattlePreloadLogic.PicResArr > 0 do
			table.remove(BattlePreloadLogic.PicResArr,1)
		end
	end
end

--[[
退出战斗，清空图片和音效资源
]]
function BattlePreloadLogic:ExitBattle()
	if BattlePreloadLogic.UsedAudioResArr ~= nil then
		local cnt = #BattlePreloadLogic.UsedAudioResArr
		for i = 1, cnt do
			BattlePreloadLogic.AudioEngine:uncache(BattlePreloadLogic.UsedAudioResArr[i])
			BattlePreloadLogic.UsedAudioResArr[i] = nil
		end
		BattlePreloadLogic.UsedAudioResArr = nil
	end
	self:DeleteAudioRes()

	if BattlePreloadLogic.TextureCache == nil then
		BattlePreloadLogic.TextureCache = AppDef.textureCache
	end

	self:DeletePicRes()
	self:InitUsedTex2DArr()
	BattlePreloadLogic.UsedAudioResArr = nil


end

function BattlePreloadLogic.IsInDeadState(unitData)
	if bit._and(unitData.m_normalState ,0x01) == 0x01 then
        return true
    end

	return false

end

function BattlePreloadLogic:GetUnitAniResByState(unitData)

	local fileName
	if unitData.m_type == AppDef.BTConst.Type.Monster 
        or unitData.m_type == AppDef.BTConst.Type.Spirit
        or unitData.m_type == AppDef.BTConst.Type.Pet then

        if unitData.m_type == AppDef.BTConst.Type.Pet then
	    	local mdata = LDataConstMgr:GetPetData(unitData.m_id)
	        if mdata == nil then
	            mdata = LDataConstMgr:GetPetData(1)
	        end
	        fileName = "Monster/btm" .. mdata.pic .. "_"
	    else
	        fileName = "Monster/btm" .. unitData.m_id .. "_"
	    end
    elseif unitData.m_type == AppDef.BTConst.Type.Hero then
        if unitData.m_prof == 0 then
	        unitData.m_prof = 1
	    end
	    local picId = AppDef:GetHipcIdx(unitData.m_prof,unitData.m_sex)

	    --角色建立
	    fileName = AppDef.HeroFileList[picId]
    end
    local isDead = false
    local actionName = "zd"
    if BattlePreloadLogic.IsInDeadState(unitData) then
        actionName = "sw"
    end
    local picFile = fileName .. actionName .. ".png"
    self:AddResBuffer(picFile)
    if unitData.m_type == AppDef.BTConst.Type.Hero then
        pWepName = AppDef.HeroBaseFileList[unitData.m_prof]
	    local WeaponPng = pWepName .. unitData.m_lightEffect .. "_d_"
	    self:AddResBuffer(WeaponPng .. actionName .. ".png")
    end
end

--[[
预加载资源
]]
function BattlePreloadLogic:PreloadReses(completeCallback)
	--print("BattlePreloadLogic:PreloadReses completeCallback=",completeCallback)
	self:PreloadAudioReses()
	self:PreloadPicReses(completeCallback)
end

--[[
预加载声音资源
]]
function BattlePreloadLogic:PreloadAudioReses()
	if BattlePreloadLogic.AudioEngine == nil then
		BattlePreloadLogic.AudioEngine = ccexp.AudioEngine
	end

	for i = 1, #BattlePreloadLogic.AudioResArr do
		
		local filePath = LSoundLogic.SoundPath .. BattlePreloadLogic.AudioResArr[i] .. ".mp3"
		--print("preload audio",filePath)
		BattlePreloadLogic.AudioEngine:preload(filePath) 
	end
end

--[[
开始预加载资源
]]
function BattlePreloadLogic:PreloadPicReses(completeCallback)
	if #BattlePreloadLogic.PicResArr == 0 then
		completeCallback()
		return
	end

	if BattlePreloadLogic.TextureCache == nil then
		BattlePreloadLogic.TextureCache = AppDef.textureCache
	end
	--print("PreloadPicReses completeCallback",completeCallback)
	local curLoadImg
	BattlePreloadLogic.BattleCompleteCallback = completeCallback
	if BattlePreloadLogic.LoadImgFunc == nil then
		local function LoadImg()
			if BattlePreloadLogic.LoadImgCallback == nil then
				local function callback(texture)
					--print("callback",#BattlePreloadLogic.PicResArr)
		    		if texture ~= nil then
		    			self:AddUsedTex2dArr(curLoadImg, texture)
		    		end
					if #BattlePreloadLogic.PicResArr > 0 then
						BattlePreloadLogic.LoadImgFunc()
					else
						--print("completeCallback",completeCallback)
						--print("completeCallback",BattlePreloadLogic.BattleCompleteCallback)
						if BattlePreloadLogic.BattleCompleteCallback then
							BattlePreloadLogic.BattleCompleteCallback()
							BattlePreloadLogic.BattleCompleteCallback = nil
						end
					end
			    end
			    BattlePreloadLogic.LoadImgCallback = callback
			end
	    	
			curLoadImg = table.remove(BattlePreloadLogic.PicResArr,1)
			--print("curLoadImg",curLoadImg)
			BattlePreloadLogic.TextureCache:addImageAsync(curLoadImg, BattlePreloadLogic.LoadImgCallback) 
		end
		BattlePreloadLogic.LoadImgFunc = LoadImg
	end
	

    BattlePreloadLogic.LoadImgFunc()
end

--[[
战斗开始预加载
]]
function BattlePreloadLogic:PreLoadBattleUnit(units,completeCallback)
	--print("PreLoadBattleUnit")
	self:DeletePicRes()
	for i = 1, AppDef.BTConst.MaxUnitNum do
		if units[i]:HasData() then
			self:GetUnitAniResByState(units[i])
		end
	end
	self:PreloadReses(completeCallback)
end

--[[
战斗回合资源预加载
]]
function BattlePreloadLogic:PreloadActionRes(btCtr, curAction, completeCallback)
	--print("BattlePreloadLogic:PreloadActionRes")
	self:DeletePicRes()
	self:DeleteAudioRes()
	if curAction.ActionType == AppDef.BTConst.ActionType.BAT_CHAT
		or curAction.ActionType == AppDef.BTConst.ActionType.BAT_CALLMONSTER  then
		if completeCallback then
			completeCallback()
		end
		return
	end 
	if curAction == nil then
		completeCallback()
		return
	end
	local btSrc = btCtr:GetBTUnitBySid(curAction.SrcBid)
	if btSrc == nil then
		completeCallback()
		return
	end
	if curAction.ActionType == AppDef.BTConst.ActionType.BAT_ATTACK 
		or curAction.ActionType == AppDef.BTConst.ActionType.BAT_ADDHP 
		or curAction.ActionType == AppDef.BTConst.ActionType.BAT_BUFF then -- 加血技能
		local picRes = btSrc:GetSkillTextRes(curAction.Val)
		self:AddResBuffer(picRes)
	end 
	local audioRes = btCtr:GetHeroSFAudio(curAction)
	self:AddAudioResBuffer(audioRes)
	
	if curAction.ActionType == AppDef.BTConst.ActionType.BAT_RUNAWAY then
		local btSrc = btCtr:GetBTUnitBySid(curAction.SrcBid)
		local picRes = btSrc:GetRunAwayRes(curAction.IsHit[1][1])
		self:AddResBuffer(picRes)
		self:PreloadReses(completeCallback)
		return
	end
	curAction.ActCfgData = LDataConstMgr:GetBTAction(curAction.Val,curAction.ActionType)

	local actionNum = #curAction.ActCfgData.m_cfgBuf
	for i = 1, actionNum do
		local clipData = curAction.ActCfgData.m_cfgBuf[i]
		if clipData.m_clipType == AppDef.BTConst.ActAniType.ModelAni then
			local actData = LDataConstMgr:GetBTModelAct(clipData.m_id)
			self:AddBTModelActionRes(btCtr, curAction, actData)
		elseif clipData.m_clipType == AppDef.BTConst.ActAniType.SkillAni then
			local actData = LDataConstMgr:GetBTSkAct(clipData.m_id)
			for i = 1, curAction.LianjiNum do
				for j = 1, curAction.DestNum[i] do
					self:AddBTSkillActionRes(btCtr, curAction, actData,j,i)
				end
			end
		elseif clipData.m_clipType == AppDef.BTConst.ActAniType.HurtAni then
			local actData = LDataConstMgr:GetBTHurtAct(clipData.m_id)
			for i = 1, curAction.LianjiNum do
				for j = 1, curAction.DestNum[i] do
					self:AddBTHurtActionRes(btCtr, curAction, actData,j,i)
				end
			end
			
		end
	end

	self:PreloadReses(completeCallback)
end


--[[
播放模型动作
modelAct：LBtActCfg数据结构类型
tarInd:目标下标，如果目标下标比当前目标大，说明是同时播放的，这个时候动作要搞分身，并且不检查下个动画播放
]]
function BattlePreloadLogic:AddBTModelActionRes(btCtr, curAction, modelAct)
	local btSrc = btCtr:GetBTUnitBySid(curAction.SrcBid)
	if btSrc == nil or btSrc.m_pData == nil then
		return
	end
	if string.len(modelAct.m_act) > 0 then
		local res = btSrc.m_fileName .. modelAct.m_act .. ".png"
		self:AddResBuffer(res)
		if btSrc.m_pData.m_type == AppDef.BTConst.Type.Hero then
			pWepName = AppDef.HeroBaseFileList[btSrc.m_pData.m_prof]
		    local WeaponPng = pWepName .. btSrc.m_pData.m_lightEffect .. "_d_"
		    self:AddResBuffer(WeaponPng .. modelAct.m_act .. ".png")
		end
	end
	
	if string.len(modelAct.m_soundFile) > 0 then
		self:AddAudioResBuffer("battle/" .. modelAct.m_soundFile)
	end
end

function BattlePreloadLogic:AddBTSkillActionRes(btCtr,curAction, modelAct, tarInd, lianjiInd)
	if modelAct == nil then
		return
	end

	local src = curAction.SrcBid
	
	local skillPath = "Skill/" .. modelAct.m_file
	
	local dir = "_l"
	local targetBid
	if modelAct.m_moveEndType == AppDef.BTConst.MoveType.ActSrcPos
		or modelAct.m_moveEndType == AppDef.BTConst.MoveType.ActCenterPos
		or modelAct.m_moveEndType == AppDef.BTConst.MoveType.TgtCenterPos then
		targetBid = src
	else
		targetBid = curAction.DestBid[lianjiInd][tarInd]
	end
	if btCtr:IsInRightSide(targetBid) then
		dir = "_r"
	else
		dir = "_l"
	end
	if modelAct.m_resType == 3 then
		skillPath = skillPath .. dir
	end
	
	local ani = ImodAnim:createWithFile(skillPath)
	self:AddResBuffer(skillPath .. ".png")

	if string.len(modelAct.m_soundFile) > 0 then
		self:AddAudioResBuffer("battle/" .. modelAct.m_soundFile)
	end
end

function BattlePreloadLogic:AddBTHurtActionRes(btCtr, curAction, modelAct, tarInd, lianjiInd)
	--local clipData = curAction.ActCfgData.m_cfgBuf[curAction.CurAniInd]
	local src = curAction.SrcBid
	local srcUnit = btCtr:GetBTUnitBySid(src)
	local aniName = modelAct.m_file
	local dstSrc = btCtr:GetBTUnitBySid(curAction.DestBid[lianjiInd][tarInd])
	if dstSrc == nil or dstSrc.m_pData == nil then
		return
	end
	if string.len(aniName) > 0 then
		dstSrc:SetState(AppDef.BTConst.UnitActState.HIT)
		local loop = false
		if curAction.IsHit[lianjiInd][tarInd] == 0 then
			--闪避播放待机动作
			aniName = "zd"
		end
		
		local res = dstSrc.m_fileName .. aniName .. ".png"
		self:AddResBuffer(res)
		if dstSrc.m_pData.m_type == AppDef.BTConst.Type.Hero then
			pWepName = AppDef.HeroBaseFileList[dstSrc.m_pData.m_prof]
		    local WeaponPng = pWepName .. dstSrc.m_pData.m_lightEffect .. "_d_"
		    self:AddResBuffer(WeaponPng .. aniName .. ".png")
		end
	end
	

	local combo = false
	if lianjiInd == 1 and curAction.LianjiNum > 1 then
		if srcUnit then
			self:AddResBuffer("res2/skill_name/combotext.png")
		end
	end
	local crit = false
	if curAction.Crit[lianjiInd][tarInd] == 1 then
		self:AddResBuffer("res2/skill_name/crittext.png")
	end
	

	if curAction.BeatBack[lianjiInd][tarInd] == 1 then
	end
end

function LBattleLogic:UpdateFightSpeed()
	self.m_speed = LRoleDataMgr:GetFightSpeedFactor(self.m_serverSpeed)
end

function LBattleLogic:getFightTime(time)
	if time == nil then
		time = 1
	end
	return (self.m_speed and (time/self.m_speed) or time)
end

function LBattleLogic:DealUpdateFightHP(msg)
    if msg == nil or msg.pos == nil or msg.hp == nil then
        return
    end
    local pos = msg.pos
    local newHp = msg.hp
    local pData = self.m_pNewUnitDatas[pos]
    if pData then
    	pData.m_curHp = newHp
    end
    pData = self.m_pUnitDatas[pos]
    if pData then
    	pData.m_curHp = newHp
    end
end


LBattleLogic:Init()
