--[[
lua里面的游戏逻辑控制
]]
local BattleHpScript = require("View.Battle.BattleHeadNode")
local BattleUnitNode = {}
BattleUnitNode.__index = BattleUnitNode

BattleUnitNode.TAG_UNIT_MODEL = 111           --模型
BattleUnitNode.TAG_CLICK_ANI = 348            --选择效果
BattleUnitNode.TAG_READY_SPR = 390            --准备文字
BattleUnitNode.TAG_ANI_SELECTED = 400         --选中动画
BattleUnitNode.TAG_ANI_CANSELECT = 401        --可以选择动画
BattleUnitNode.TAG_ANI_BURNING = 600         --怒气燃烧动画
BattleUnitNode.TAG_ANI_BOOM = 601             --怒气爆炸动画
BattleUnitNode.TAG_ANI_LIGHT_RING = 602       --光环

BattleUnitNode.ZORDER_UNIT_MODEL = 2 
BattleUnitNode.ZORDER_READY_SPR = 3
BattleUnitNode.ZORDER_ANI_SELECTED = 3000
BattleUnitNode.ZORDER_ANI_BURNING = 4000
BattleUnitNode.ZORDER_ANI_BOOM = 4001
BattleUnitNode.ZORDER_ANI_LIGHT_RING = 4002
BattleUnitNode.ZORDER_ANI_CANSELECT = 4100
BattleUnitNode.ZORDER_BEATTACK_EX = 5000      --被攻击扩展特效(闪避、暴击等)

--local this = LTcpSocket
function BattleUnitNode:New(battleLogic, node)
	local o = {}
	setmetatable(o,BattleUnitNode)	
    o:Init(battleLogic, node)
	return o
end

function BattleUnitNode:InitData()
    self.m_pBgAni = ImodAnim:create()
    self.m_pNode:addChild(self.m_pBgAni)

    self.m_pModelAni = ImodAnim:create()
    self.m_pNode:addChild(self.m_pModelAni)

    self.m_pHpNode = BattleHpScript:New()
    self.m_pNode:addChild(self.m_pHpNode.m_pNode)
    self.m_pNameLabel = nil
    self.m_pLvLabel = nil
    self.m_bIsShowLv = false
    self:InitNameLabel()
    self.m_pHitData = nil
    self.m_modelPicId = 0
    self.m_nameColor = nil
    --这个就是用来显示英雄武器的，不需要了
    --self.m_vecEffects = {}
    self.m_beAttackText = {}
    self.m_beAttackMsg = {}
    self.m_buffNum = 0
    self.m_pMoveAction = nil--当前移动的Action指针
    self.m_pMoveEndFunc = nil--当前移动结束的回调
    self.m_vecBuff = {}
    for i = 1,AppDef.BTConst.MaxBuffNum do
        self.m_vecBuff[i] = LBTBuffUnitData:New()
    end
  
    self.m_pActionData = nil

    --[[
    分身数据，{目标下标，动画Node}
    ]]
    self.m_pSplitAni = {}

    
    -- self.m_bIsPlayDamegeEffect = false
    -- self.m_vecDamege = {}
end

--[[
停止当前移动的Action
]]
function BattleUnitNode:StopLastMoveAction()
    if self.m_pMoveAction == nil then
        return
    end
    self.m_pNode:stopAction(self.m_pMoveAction)
    self.m_pMoveAction = nil

    if self.m_pMoveEndFunc then
        self.m_pMoveEndFunc(self.m_pNode)
        self.m_pMoveEndFunc = nil
    end
end

--[[
开始移动
]]
function BattleUnitNode:StartMoveAction(moveAction, moveFunc)
    self:StopLastMoveAction()
    self.m_pMoveEndFunc = moveFunc
    -- if self.m_pMoveEndCallback == nil then
    --     local function MoveEndCallback(sender)
    --         self.m_pMoveAction = nil
    --         if self.m_pMoveEndFunc then
    --             self.m_pMoveEndFunc(sender)
    --             self.m_pMoveEndFunc = nil
    --         end
    --     end
    --     self.m_pMoveEndCallback = MoveEndCallback
    -- end
    local function MoveEndCallback(sender)
        self.m_pMoveAction = nil
        if self.m_pMoveEndFunc then
            self.m_pMoveEndFunc(sender)
            self.m_pMoveEndFunc = nil
        end
    end
    
    local func = cc.CallFunc:create(MoveEndCallback)
    local sq = cc.Sequence:create(moveAction,func)
    self.m_pMoveAction = self.m_pNode:runAction(sq)
end

function BattleUnitNode:InitNameLabel()
    self.m_pNameLabel = cc.Label:createWithTTF("",AppDef.FNT_NAME,20)
    self.m_pNameLabel:enableShadow()
    self.m_pNode:addChild(self.m_pNameLabel)
    self.m_pNameLabel:setPositionY(-20)
    -- self.m_pLvLabel = cc.Label:createWithTTF("",AppDef.FNT_NAME,16)
    -- self.m_pLvLabel:enableShadow()
    -- self.m_pNameLabel:addChild(self.m_pLvLabel)
end

function BattleUnitNode:ClearBuff()
    for i = 1,AppDef.BTConst.MaxBuffNum do
        if self.m_vecBuff[i].buffNode ~= nil then
            self.m_vecBuff[i].buffNode:removeFromParent()
            self.m_vecBuff[i].buffNode = nil
        end
        self.m_vecBuff[i]:Reset()
    end
    self.m_buffNum = 0
end

function BattleUnitNode:Reset(isResetAni)
    isResetAni = isResetAni or true
    self.m_pHitData = nil
    self.m_modelPicId = 0
    self.m_bIsFlipPos = false
    self.m_isUpside = false
    self.m_pAniCallback = nil
    self.m_pTouchCallback = nil
    self.m_speakCallback = nil

    --self.m_buffState = 0
    --self.m_buffState = {}
    self.m_delayToNormalTime = 0.0
    self.m_isBeatBack = false 
    self.m_isPlayingText = false
    self.m_isPlayDamage = false
    -- self.m_tmpFlipX = -1
    -- self.m_tmpAnimateIdx = -1
    self.m_fileName = ""
    self.m_pActionData = nil
    self.m_bIsShowLv = false
    self.m_buffNum = 0
    for i = 1,AppDef.BTConst.MaxBuffNum do
        if self.m_vecBuff[i].buffNode ~= nil then
            self.m_vecBuff[i].buffNode:removeFromParent()
            self.m_vecBuff[i].buffNode = nil
        end
        self.m_vecBuff[i]:Reset()
    end

    if self.m_beAttackText == nil then
        self.m_beAttackText = {}
    else
        while #self.m_beAttackText > 0 do
            self.m_beAttackText[1] = nil
            table.remove(self.m_beAttackText,1)
        end
    end

    if self.m_beAttackMsg == nil then
        self.m_beAttackMsg = {}
    else
        while #self.m_beAttackMsg > 0 do
            self.m_beAttackMsg[1] = nil
            table.remove(self.m_beAttackMsg,1)
        end
    end
    if isResetAni then
        self.m_pModelAni:resetAniData()   
    end
    self.m_pBgAni:resetAniData()
    self.m_pHpNode:Reset()
    self:ClearSplitNode()
    self:StopLastMoveAction()

    if self.m_pOldModelAni ~= nil then
        self.m_pOldModelAni:removeFromParent()
        self.m_pOldModelAni = nil
    end

end

function BattleUnitNode:NewUnitIn(unit, nameColor, flipPos)
    self:Reset(false)
    self.m_pOldModelAni = self.m_pModelAni

    self.m_pModelAni = ImodAnim:create()
    self.m_pNode:addChild(self.m_pModelAni)
    self.m_pNameLabel:setLocalZOrder(self.m_pModelAni:getLocalZOrder() + 1)
    self.m_pData = unit
    self.m_bIsFlipPos = flipPos

    self.m_nameColor = nameColor
    self.m_state = AppDef.BTConst.UnitActState.NORMAL

    self:InitAni()

    if self:IsInDeadState() then
        self.m_pData.m_isDead = true
    else
        self.m_pData.m_isDead = false
    end
    if self.m_pData.m_isDead then
        self:SetState(AppDef.BTConst.UnitActState.DEATH)
        self:CheckBuff()
    else
        self:CheckBuff()
    end
    
    
    self:ShowQuality()
    self:PlayAniByName("pb")
    if self.m_pNewUnitCallback == nil then
        local function NewUnitInFinish()
            if self.m_pOldModelAni ~= nil then
                self.m_pOldModelAni:removeFromParent()
                self.m_pOldModelAni = nil
            end
            self.m_pModelAni:setPosition(cc.p(0,0))
            self:PlayAniByState()
        end
        self.m_pNewUnitCallback = NewUnitInFinish
    end
    
    local bornPos = cc.p(200,200)
    if self.m_isUpside then
        bornPos.x = -200
    end
    self.m_pModelAni:setPosition(bornPos)
    local func = cc.CallFunc:create(self.m_pNewUnitCallback)
    local sinMov = cc.EaseSineIn:create(cc.MoveTo:create(0.5,cc.p(0,0)))
    local seq = cc.Sequence:create(sinMov, func)
    self.m_pModelAni:runAction(seq)
end

function BattleUnitNode:InitPlayAniByStateCallback()
    if self.m_pPlayAniByStateFunc == nil then
        local function PlayCallback()
            self:PlayAniByState()
        end
        self.m_pPlayAniByStateFunc = PlayCallback
    end
end
function BattleUnitNode:SetBattleUnit(unit, nameColor, flipPos)
    self:Reset()
    self.m_pData = unit
    self.m_bIsFlipPos = flipPos
    self.m_nameColor = nameColor
    self.m_state = AppDef.BTConst.UnitActState.NORMAL
    self:InitAni()

    if self:IsInDeadState() then
        self.m_pData.m_isDead = true
    else
        self.m_pData.m_isDead = false
    end
    if self.m_pData.m_isDead then
        self:SetState(AppDef.BTConst.UnitActState.DEATH)
        self:CheckBuff()
    else
        self:CheckBuff()
    end
    self:PlayAniByState()
    self:ShowQuality()
end
function BattleUnitNode:ShowQuality()
    
    self.m_pHpNode:SetQuality(self.m_pData.m_quality,self.m_pData.m_type)
    if self.m_pData.m_type == AppDef.BTConst.Type.Pet and self.m_pData.m_quality > 1 then
        local bgAnim = nil
        if self.m_pData.m_quality == 2 then
            bgAnim = "res2/animation/battle/quality2"
        elseif self.m_pData.m_quality >= 3 and self.m_pData.m_quality < 7 then
            bgAnim = "res2/animation/battle/quality3"
        elseif self.m_pData.m_quality == 7 then
            bgAnim = "res2/animation/battle/quality7"
        elseif self.m_pData.m_quality >= 8 then
            bgAnim = "res2/animation/battle/quality8"
        end
        if bgAnim then
            self.m_pBgAni:initAnimWithNameSync(bgAnim)
            self.m_pBgAni:PlayActionRepeat(0)
        end
    end
    -- body
end

function BattleUnitNode:SetState(state)
    ----print("SetState","name=",self.m_pData.m_name,"state=",state)

    if self.m_state == state then
        return
    end
    self.m_state = state
end

function BattleUnitNode:PlayAniByState()
    if self.m_state == AppDef.BTConst.UnitActState.NORMAL then
        self:PlayStandAni()
    elseif self.m_state == AppDef.BTConst.UnitActState.DEATH then
         self:PlayDeathAni()
         --self:ClearBuff()
    end
end

function BattleUnitNode:PlayDeathAni()
    ------------print("PlayDeathAni")
    local loop = false
    local suffix = "sw"

    local IsFlipX = false
    local AnimateIdx = 0
    if self.m_isUpside == false then
        IsFlipX = true
        AnimateIdx = 1
    end

    local IsPlayRepeat = false

    --重新加载英雄模型
    local aniFile = self.m_fileName .. suffix
    --sw没有加到预加载里面，这个时候另外加一下
    BattlePreloadLogic:AddUsedTex2dArr(aniFile .. ".png")
    self.m_pModelAni:initAnimWithName(aniFile)
    if self.m_pData.m_type == AppDef.BTConst.Type.Hero then
        --英雄身上的特效跟着切换
        self:ReloadHeroWeapon(suffix)
    end
    self.m_pModelAni:setFlippedX(IsFlipX)
    self.m_pModelAni:PlayNewAction(AnimateIdx,loop)
    self.m_pHpNode:SetVisible(false)

    self:PlayDeathAudio()
end

function BattleUnitNode:PlayStandAni()

    local IsFlipX = false
    local AnimateIdx = 0
    if self.m_isUpside == false then
        IsFlipX = true
        AnimateIdx = 1
        -- if self.m_pData.m_type == AppDef.BTConst.Type.Monster 
        --     or self.m_pData.m_type == AppDef.BTConst.Type.Pet then
        --     AnimateIdx = 3
        -- end 
    end

    local IsPlayRepeat = false
    local suffix = "zd"

    --重新加载英雄模型
    local aniFile = self.m_fileName .. suffix
    self.m_pModelAni:initAnimWithName(aniFile)
    if self.m_pData.m_type == AppDef.BTConst.Type.Hero then
        --英雄身上的特效跟着切换
        self:ReloadHeroWeapon(suffix)
    end
    self.m_pModelAni:setFlippedX(IsFlipX)
    self.m_pModelAni:PlayNewAction(AnimateIdx,true)
    self.m_pModelAni:SetSpeedScale(1)
    --self.m_pModelAni:PlayActionRepeat(AnimateIdx,0.2)

    --分身播放待机
    for i = 1, #self.m_pSplitAni do
        local modelAni = self.m_pSplitAni[i][2]
        modelAni:initAnimWithName(aniFile)
        modelAni:setFlippedX(IsFlipX)
        
        if self.m_pData.m_type == AppDef.BTConst.Type.Hero then
            --英雄身上的特效跟着切换
            self:ReloadHeroWeapon(suffix,modelAni)
        end

        modelAni:PlayNewAction(AnimateIdx,true)
    end

end

function BattleUnitNode:InitAni()
    if self.m_pData.m_type == AppDef.BTConst.Type.Monster 
        or self.m_pData.m_type == AppDef.BTConst.Type.Spirit
        or self.m_pData.m_type == AppDef.BTConst.Type.Pet then
        self:InitMonsterAni()
    elseif self.m_pData.m_type == AppDef.BTConst.Type.Hero then
        self:InitHeroAni()
    end
end

function BattleUnitNode:InitMonsterAni()
    local isHolyBeast = false
    if self.m_pData.m_type == AppDef.BTConst.Type.Spirit then
        isHolyBeast = true
    end
    local fileName
    local hitId = self.m_pData.m_id
    if self.m_pData.m_type == AppDef.BTConst.Type.Pet then
        local mdata = LDataConstMgr:GetPetData(self.m_pData.m_id)
        if mdata == nil then
            mdata = LDataConstMgr:GetPetData(1)
        end
        fileName = "Monster/btm" .. mdata.pic .. "_"
        hitId = mdata.pic
    else
        fileName = "Monster/btm" .. self.m_pData.m_id .. "_"
    end
    
    self.m_modelPicId = self.m_pData.m_id
    --加入打击点
    --可以找到打击点时更改打击点位置
    local hitData = LDataConstMgr:GetMonsterHitById(hitId)
    self.m_pHitData = hitData
    local hpPoint = cc.p(self.m_pHitData.hpBarPos.x * self.m_pData.m_scaleRatio,self.m_pHitData.hpBarPos.y * self.m_pData.m_scaleRatio)
    local side
    if (self.m_bIsFlipPos == false and self.m_pData.m_posBid <= AppDef.BTConst.MaxHalfUnitNum)
        or (self.m_bIsFlipPos == true and self.m_pData.m_posBid > AppDef.BTConst.MaxHalfUnitNum) then
        side = 0
    else
        side = 1
    end

    self:InitWithFileName(fileName,side)
    self.m_pHpNode:SetVisible(true)
    self.m_pHpNode:SetMySideFlag(not self.m_isUpside)
    self.m_pHpNode:SetPosition(cc.p(hpPoint.x,hpPoint.y))
    self.m_pHpNode:ChangeHp(self.m_pData.m_maxHp, self.m_pData.m_curHp)
    self.m_pHpNode:SetOpacity(Utils:ToBool(self.m_pData.m_isBoss) and 0 or 255)
    self:ShowMonsterName()
    --在怪物名字前面加入怪物的等级
    

-- unitData.m_star = stream:ReadByte()
--     unitData.m_tupo = stream:ReadByte()
    if self.m_pData.m_type == AppDef.BTConst.Type.Pet then
        self.m_pHpNode:ShowStar(self.m_pData.m_star)
    else
        self.m_pHpNode:ShowStar(0)
    end
    
    --加入星级
    --这个好像没地方调用
    -- for(int i = 0i < Stari ++){
    --     float Scale = 0.5f
    --     CCSprite* Star = CCSprite::create("BattleUI/BattleStar.png")
    --     Star->setScale(Scale)
    --     Star->setAnchorPoint(cc.p(0,0))
    --     Star->setPosition(cc.p(i * Star->getContentSize().width * Scale,Spr1->getContentSize().height / 2 + 5))
    --     Spr1->addChild(Star,3)
    -- }
end

function BattleUnitNode:PlayDeathAudio()
    if self.m_pData.m_type == AppDef.BTConst.Type.Hero then
        self:PlayHeroDeathAudio()
    else
        self:PlayMonsterDeathAudio()
    end
end

function BattleUnitNode:PlayHeroDeathAudio()
    local soundStr = AppDef.HeroDeathBGM[self.m_pData.m_prof]
    local arr = string.split(soundStr,"|")
    local num = #arr
    local playFile = arr[math.random(1,num)]
    LGameMsg.m_baseMsgWithOne:Change(LAudioEvent.PlayBTEffect, playFile)
    LAudioManager:SendMsg(LGameMsg.m_baseMsgWithOne)
end

--[[
播放怪物死亡音效
]]
function BattleUnitNode:PlayMonsterDeathAudio()
    local monsterPic
    if self.m_pData.m_type == AppDef.BTConst.Type.Pet then
        local mdata = LDataConstMgr:GetPetData(self.m_pData.m_id)
        if mdata == nil then
            mdata = LDataConstMgr:GetPetData(1)
        end
        monsterPic = mdata.pic
    else
        monsterPic = self.m_pData.m_id
    end
    for i = 1,#AppDef.MonsterDeathBGM do
        if AppDef.MonsterDeathBGM[i].picId == monsterPic then
            local soundStr = AppDef.MonsterDeathBGM[i].bgm
            local arr = string.split(soundStr,"|")
            local num = #arr
            local playFile = arr[math.random(1,num)]
            LGameMsg.m_baseMsgWithOne:Change(LAudioEvent.PlayBTEffect, playFile)
            LAudioManager:SendMsg(LGameMsg.m_baseMsgWithOne)
            return
        end
    end
end

--[[
播放被击音效
]]
function BattleUnitNode:PlayHitAudio()
    if self.m_pData.m_type == AppDef.BTConst.Type.Hero then
        self:PlayHeroHitAudio()
    else
        self:PlayMonsterHitAudio()
    end
end

function BattleUnitNode:PlayHeroHitAudio()
    local soundStr = AppDef.HeroHitBGM[self.m_pData.m_prof]
    local arr = string.split(soundStr,"|")
    local num = #arr
    local playFile = arr[math.random(1,num)]
    LGameMsg.m_baseMsgWithOne:Change(LAudioEvent.PlayBTEffect, playFile)
    LAudioManager:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function BattleUnitNode:PlayMonsterHitAudio()
    local monsterPic
    if self.m_pData.m_type == AppDef.BTConst.Type.Pet then
        local mdata = LDataConstMgr:GetPetData(self.m_pData.m_id)
        if mdata == nil then
            mdata = LDataConstMgr:GetPetData(1)
        end
        monsterPic = mdata.pic
    else
        monsterPic = self.m_pData.m_id
    end
    for i = 1,#AppDef.MonsterHitBGM do
        if AppDef.MonsterHitBGM[i].picId == monsterPic then
            local soundStr = AppDef.MonsterHitBGM[i].bgm
            local arr = string.split(soundStr,"|")
            local num = #arr
            local playFile = arr[math.random(1,num)]
            LGameMsg.m_baseMsgWithOne:Change(LAudioEvent.PlayBTEffect, playFile)
            LAudioManager:SendMsg(LGameMsg.m_baseMsgWithOne)
            return
        end
    end
end


function BattleUnitNode:PlayRunAwayAction(success)
    local acitonTime = 1.4
    local Fade = cc.FadeTo:create(acitonTime,0)
    --CCCallFunc *AniEnd = CCCallFunc::create(this,(SEL_CallFunc)&BattleUnitNode::DoAnimateCallBackOnce)
    if self.m_pRunAwayCallback == nil then
        local function RunAwayCallback(sender)
            sender:removeFromParent()
            self:SetState(AppDef.BTConst.UnitActState.RUNAWAY)
            self:PlayAniByName("pb",true)
        end
        self.m_pRunAwayCallback = RunAwayCallback
    end
    
    local AniEnd2 = cc.CallFunc:create(self.m_pRunAwayCallback)
    --CCCallFuncN *AniEnd3 = CFUNC_REMOVE
    
    --逃跑成功
    local hpPoint = cc.p(self.m_pHitData.hpBarPos.x * self.m_pData.m_scaleRatio,self.m_pHitData.hpBarPos.y * self.m_pData.m_scaleRatio)
    if success == 1 then
        local escapeSpr = cc.Sprite:create("res2/fight/escapesucctext.png")
        --escapeSpr:setVisible(false)
        escapeSpr:setPosition(hpPoint)
        escapeSpr:runAction(cc.Sequence:create(Fade,AniEnd2))
        --escapeSpr:runAction(cc.Sequence:create(cc.DelayTime:create(0.5),AniEnd,NULL))
        self.m_pNode:addChild(escapeSpr,5)
        
        --让血条和名字也渐隐
        -- CCSprite* hpSpr = (CCSprite*)getChildByTag(TAG_HPBAR_SPR)
        -- hpSpr->runAction(Fade)
        -- CCSprite* hpBkg = (CCSprite*)getChildByTag(TAG_HPBAR_SPR_BK)
        -- hpBkg->runAction(Fade)
        -- CEffectStrokeLabel *NameLabel = (CEffectStrokeLabel *)getChildByTag(TAG_NAME_LABEL)
        -- NameLabel->GetTextureSprite()->runAction(Fade)
    else
        --逃跑失败
        local escapeSpr = cc.Sprite:create("res2/fight/escapefailuretext.png")
        escapeSpr:setPosition(hpPoint)
        escapeSpr:setOpacity(255)
        escapeSpr:setVisible(true)
        local FadeAction = cc.FadeTo:create(3.0,0)
        local callbackAction = cc.CallFunc:create(self.m_pRunAwayCallback)
        escapeSpr:runAction(cc.Sequence:create(FadeAction,callbackAction))
         self.m_pNode:addChild(escapeSpr,5000)
    end
    return 1.9
end

--说话相关
function BattleUnitNode:SetSpeakCallBack(func)
    self.m_speakCallback = func
end

--讲话泡泡
function BattleUnitNode:SpeakMsg(msg)
    --讲话label
    local Msg = CCAysLabel:create(msg,cc.Size(165,0),-132,cc.WHITE,FNT_SIZE_M)
    Msg:setAnchorPoint(cc.p(0,1))
    local msgHeight = Msg:getSize().height
    local thPos = cc.p(0 + self.m_pData.m_scrPos.x,self.m_pHitData.hpBarPos.y + msgHeight - 15 + self.m_pData.m_scrPos.y)
    Msg:runAction(cc.Sequence:create(cc.FadeTo:create(0.3,255),cc.DelayTime:create(2),cc.FadeTo:create(0.3,0)))

    --建立一个背景,战斗聊天背景
    local MsgBkg = cc.Scale9Sprite:create(cc.Rect(5,27,130,50), "UI/BattleSpeakBkg.png")
    MsgBkg:setPreferredSize(cc.Size(165 + 25,msgHeight + 20))
    MsgBkg:setPosition(thPos)
    Msg:setPosition(cc.p(7,msgHeight + 20))
    MsgBkg:addChild(Msg)
    if self.m_pSpeakCallback == nil then
        local function SpeakEndCallBack(sender)
            self:SpeakEndCallBack(sender)
        end
        self.m_pSpeakCallback = SpeakEndCallBack
    end
    
    local func = cc.CallFunc:create(self.m_pSpeakCallback)
    MsgBkg:runAction(cc.Sequence:create(cc.FadeTo:create(0.3,255),cc.DelayTime:create(2),cc.FadeTo:create(0.3,0),func))
    self.m_pBTCtr.m_pNode:addChild(MsgBkg, AppDef.BTConst.BTZorder.ZORDER_SPEAK_MSG)
end

function BattleUnitNode:SpeakEndCallBack(pSender)
    Utils:RemoveNode(pSender)
    if self.m_speakCallback then
        self.m_speakCallback(self)
        self.m_speakCallback = nil
    end
end

function BattleUnitNode:AssignBuff(normalState,stateNum , states)
    if self.m_pData == nil then
        return
    end
    self.m_pData.m_normalState = normalState;
    if self.m_pData.m_stateNum == stateNum then
        local isSame = true
        for i = 1, stateNum do
            if self.m_pData.m_states[i] ~= states[i] then
                isSame = false
            end
        end
        if isSame then
            return
        end
    end
    self.m_pData.m_stateNum = stateNum
    self.m_pData.m_states = {}
    for i = 1, stateNum do
        table.insert(self.m_pData.m_states,states[i])
    end
    self:CheckBuff()
    
end

function BattleUnitNode:CheckBuff()
    -- print("CheckBuff",self.m_pData.m_name);
    local buffList = LDataConstMgr:GetBTBuffList()
    for i = 1, #buffList do
        local curStateId = buffList[i].id
        -- print("curStateId",curStateId)
        local isExsit = false;
        for j = 1, #self.m_pData.m_states do
            -- print("self.m_pData.m_states[i]",self.m_pData.m_states[j])
            if curStateId == self.m_pData.m_states[j] then
                isExsit = true;
                break;
            end
        end
        if isExsit == true then
            self:AddBuff(buffList[i])
        else
            self:DeleteBuff(buffList[i].id)
        end
        -- local curState = self.m_pData.m_states[buffList[i].stateInd]
        -- if curState > 0 and (bit._and(buffList[i].stateValue,curState) == buffList[i].stateValue) then
        --     --新增
        --     self:AddBuff(buffList[i])
        -- else
        --     --删除
        --     self:DeleteBuff(buffList[i].id)
        -- end
    end
end

function BattleUnitNode:GetSkillTextRes(skillId)
    if skillId > 200000 then
        return "res2/skill_name/skill_" .. skillId .. ".png"
    end
    if skillId == 0 then
        return "res2/skill_name/skill_0.png"
    else
        local skData = LDataConstMgr:GetSkillDetailList(skillId)
        if skData == nil then
            return "res2/skill_name/skill_0.png"
        end

        local skillFile = LDataConstMgr:GetSkillDetailList(skillId).picFile
        return "res2/skill_name/" .. skillFile .. ".png"
    end
end

function BattleUnitNode.RemoveCallback(sender)
    sender:removeFromParent()
end

function BattleUnitNode:ShowSkillTextEffect(skillId)
    ------print("ShowSkillTextEffect",skillId)
    if self.m_pHitData == nil then
        return
    end
    local time = 0
    local skillTextRes = self:GetSkillTextRes(skillId)
    
    local txtSpr = cc.Sprite:create(skillTextRes)
    if txtSpr == nil then
        return time
    end
    time = 0.4
    txtSpr:setScale(0.8)
    local pos = self.m_pNode:convertToWorldSpace(cc.p(0,(self.m_pHitData.hpBarPos.y + 25) * self.m_pData.m_scaleRatio))
    txtSpr:setPosition(pos)
    local scaleto = cc.ScaleTo:create(0.1, 1.2)
    local delay = cc.DelayTime:create(0.3)
    local delay2 = cc.DelayTime:create(0.2)
    local fadeto = cc.FadeTo:create(0.4,0)

    local func = cc.CallFunc:create(BattleUnitNode.RemoveCallback)
    local seq = cc.Sequence:create(scaleto, delay, delay2, fadeto, func)
    txtSpr:runAction(seq)
    local delay3 = cc.DelayTime:create(0.6)
    local moveBy = cc.MoveBy:create(0.4,cc.p(0,80))
    local seq2 = cc.Sequence:create(delay3, moveBy, seq2)
    txtSpr:runAction(seq2)
    self.m_pNode:getParent():addChild(txtSpr,5)
    return time
end

function BattleUnitNode:ShowBuffText(text)
    if self.m_pData == nil then
        return
    end
    local textLabel = CCAysLabel:createWithString(text, 100,22)
    local msgSize = textLabel:getSize()
    local func = cc.CallFunc:create(BattleUnitNode.RemoveCallback)
    local sinMov
    local footy = 0
    if self.m_pHitData ~= nil then
        footy = self.m_pHitData.footPos.y
    end
    sinMov = cc.EaseSineIn:create(cc.MoveTo:create(1,cc.p(0 - msgSize.width/2,(footy + 95)*self.m_pData.m_scaleRatio)))
    textLabel:setPosition(cc.p(0 - msgSize.width/2,(footy + 30) * self.m_pData.m_scaleRatio))
    
    local seqMov = cc.Sequence:create(sinMov,func)
   
    textLabel:runAction(seqMov)
    self.m_pNode:addChild(textLabel, 10)
end

--[[
添加buff
@param1:LBTBuffCfg结构
]]
function BattleUnitNode:AddBuff(buffData)
    --
    --------print("AddBuff,id=",buffData.id)
    for i = 1, self.m_buffNum do
        if self.m_vecBuff[i].id == buffData.id then
            if self.m_pData.m_isDead == true  and  self.m_vecBuff[i].buffNode ~= nil then
                self.m_vecBuff[i].buffNode:setPositionY(10)
            end
            return
        end
    end

    if self.m_buffNum >= AppDef.BTConst.MaxBuffNum then
        --大于最大显示的bug数量就不显示了
        return
    end

    if self.m_pNode == nil then
        return
    end

    if string.len(buffData.showText) > 0 then
        local textLabel = CCAysLabel:createWithString(buffData.showText, 100,22)
        local msgSize = textLabel:getSize()

        local func = cc.CallFunc:create(BattleUnitNode.RemoveCallback)
        local sinMov
        local footy = 0
        if self.m_pHitData ~= nil then
            footy = self.m_pHitData.footPos.y
        end
        local offstY = 0
        if self.m_pNode:getChildByTag(888) ~= nil then
            offstY = -22
        end
        local fightSpeedScale = LRoleDataMgr:GetFightSpeed() + 1
        if buffData.textType == 1 then
            textLabel:setPosition(cc.p(0 - msgSize.width/2,(footy + 30) * self.m_pData.m_scaleRatio))
            sinMov = cc.EaseSineIn:create(cc.MoveBy:create(1 / fightSpeedScale,cc.p(0,65*self.m_pData.m_scaleRatio - offstY)))
             
        else
            textLabel:setPosition(cc.p(0 - msgSize.width/2,(footy + 95)*self.m_pData.m_scaleRatio))
            sinMov = cc.EaseSineIn:create(cc.MoveBy:create(1 / fightSpeedScale,cc.p(0,-65 * self.m_pData.m_scaleRatio - offstY)))
        end
        
        local seqMov = cc.Sequence:create(sinMov,func)
       
        textLabel:runAction(seqMov)
        self.m_pNode:addChild(textLabel, 10,888)
    end

    --[[
    self.showType = 0--1血条上方图标2特效
    self.resId = 0--资源编号
    self.hit = 0--打击点--走打击点规则
    self.offPoint = {0,0}--偏移
    self.showText = ""--特效上浮文字，len=0就是没有
    ]]
    local buffNode
    if buffData.showType == 1 then
        --显示血条上方图标
        local fileName = "res2/Skill/Buff_tips/" .. buffData.resName .. ".png"
        --buff没有加到预加载里面，这个时候另外加一下
        BattlePreloadLogic:AddUsedTex2dArr(fileName)
        buffNode = cc.Sprite:create(fileName)

    elseif buffData.showType == 2 then
        --显示buff特效
        local fileName = "res2/Skill/" .. buffData.resName
        --buff没有加到预加载里面，这个时候另外加一下
        BattlePreloadLogic:AddUsedTex2dArr(fileName .. ".png")
        buffNode = ImodAnim:createWithFileSync(fileName)
        buffNode:PlayActionRepeat(0)
    else
        ----------print("Error Buff Config:id=",buffData.id)
    end
    if buffNode == nil then
        ----------print("Error Buff Config:id=",buffData.id)
        return
    end
    self.m_pNode:addChild(buffNode)

    if buffData.hit < 3 then--0,1,2
        --走打击点配置
        local pos = self:GetHitPoint(buffData.hit + 1)
        if self.m_pData.m_isDead == true then
            buffNode:setPosition(cc.p(pos.x + buffData.offPoint.x,(0) * self.m_pData.m_scaleRatio))
        else
            buffNode:setPosition(cc.p(pos.x + buffData.offPoint.x,(pos.y + buffData.offPoint.y) * self.m_pData.m_scaleRatio))
        end
        
    else
        if buffData.hit == 3 or buffData.hit == 4 then--血条上方下方
            local pos = self:GetBuffIconPosInHp(buffData.hit)
            if buffData.hit == 3 then
                buffNode:setAnchorPoint(cc.p(0,0))
            else
                buffNode:setAnchorPoint(cc.p(0,1))
            end
            if self.m_pData.m_isDead == true then
                pos.y= 0
            end
            buffNode:setPosition(pos)
        else
            ----------print("Error Buff Config:id=",buffData.id)
        end
    end
    

    self.m_buffNum = self.m_buffNum + 1
    ------print("self.m_buffNum=",self.m_buffNum)
    local Buff = self.m_vecBuff[self.m_buffNum]
    Buff.id = buffData.id
    Buff.buffNode = buffNode
    Buff.hit = buffData.hit
end

function BattleUnitNode:GetBuffIconPosInHp(hit)
    local pos
    local sx = 0
    local sy = 0
    local width = 32
    if self.m_pHitData == nil then
        return cc.p(0,0)
    end
    if hit == 3 then
        pos = self.m_pHpNode:GetHpAbovePos()
    else
        pos = self.m_pHpNode:GetHpBelowPos()
        sy = -15
        sx = 15
    end
    for i = 1, self.m_buffNum do
        if self.m_vecBuff[i].hit == hit then
            sx = sx + width
        end
    end
    local hpPoint = cc.p(self.m_pHitData.hpBarPos.x * self.m_pData.m_scaleRatio,self.m_pHitData.hpBarPos.y * self.m_pData.m_scaleRatio)
    return cc.p(hpPoint.x + pos.x + sx, sy + hpPoint.y + pos.y)
end

function BattleUnitNode:ShowBuffTips(tipLayer, buffCell, oldSize)
    
    local panel = tipLayer
    local newPos = cc.p(self.m_pNode:getPosition())
    newPos.y = newPos.y + self.m_pHitData.hpBarPos.y

    if (self.m_bIsFlipPos == false and self.m_pData.m_posBid > AppDef.BTConst.MaxHalfUnitNum)
        or (self.m_bIsFlipPos == true and self.m_pData.m_posBid <= AppDef.BTConst.MaxHalfUnitNum) then
        newPos.x = newPos.x - oldSize.width
    end
    
    local nameLabel = panel:getChildByName("Name")
    nameLabel:setString(self.m_pData.m_name)

    local lvLabel = nameLabel:getChildByName("Level")
    lvLabel:setString(self.m_pData.m_level .. GUITips.Common_Ji)
    local listView = panel:getChildByName("ListView")
    listView:removeAllItems()
    local buffNum = self.m_buffNum
    -- if self.m_pData.m_isDead == true then
    --     buffNum = 0
    -- end
    for i = 1, buffNum  do
        local buffData = LDataConstMgr:GetBTBuffById(self.m_vecBuff[i].id)
        local cell = buffCell:clone()
        cell:setVisible(true)
        listView:pushBackCustomItem(cell)
        local buffNameLabel = cell:getChildByName("Name")
        buffNameLabel:setString(buffData.name)

        local buffDescLabel = cell:getChildByName("Desc")
        buffDescLabel:setString(buffData.desc)

        local timesLabel = cell:getChildByName("Times")
        timesLabel:setVisible(false)

        local buffImg = cell:getChildByName("IconBg"):getChildByName("Icon")
        local resIcon = "res2/Skill/Buff_tips/" .. buffData.tipIcon .. ".png"
        BattlePreloadLogic:AddUsedTex2dArr(resIcon)
        buffImg:loadTexture(resIcon,ccui.TextureResType.localType)
        
    end
    local oldHeight = listView:getContentSize().height


    
    local cellSize = buffCell:getContentSize()
    local height = cellSize.height * self.m_buffNum
    listView:setContentSize(cc.size(cellSize.width,height))
    oldHeight = oldHeight - height
    local size = panel:getContentSize()
    size.height = size.height - oldHeight
    panel:setContentSize(size)

    ccui.Helper:doLayout(tipLayer)
    panel:setPosition(newPos)

end

function BattleUnitNode:DeleteBuff(buffId)
    ----------print("DeleteBuff",buffId)
    local ind = 0
    local sx = 0
    local width = 32
    local changeType = 0
    for i = self.m_buffNum, 1, -1  do
        if self.m_vecBuff[i].id == buffId then
            self.m_vecBuff[i].buffNode:removeFromParent()
            self.m_vecBuff[i]:Reset()
            if self.m_vecBuff[i].hit == 3 or self.m_vecBuff[i].hit == 4 then
                sx = (i - 1) * width
                changeType = self.m_vecBuff[i].hit
            end
            local tmp = self.m_vecBuff[self.m_buffNum]
            self.m_vecBuff[self.m_buffNum] = self.m_vecBuff[i]
            self.m_vecBuff[i] = tmp
            self.m_buffNum = self.m_buffNum - 1
            ind = i
            break
        end
    end

    if changeType == 0 then
        return
    end
    if changeType == 4 then
        sx = 15
    end
    for i = ind, self.m_buffNum do
        if self.m_vecBuff[i].buffNode ~= nil then
            if self.m_vecBuff[i].hit == changeType then
                self.m_vecBuff[i].buffNode:setPositionX(sx)
                sx = sx + width
            end
        end
    end
end

function BattleUnitNode:ShowPreparingHint(val)
    self.m_pHpNode:SetReadyFlagVisible(val)
end

function BattleUnitNode:SetQualityEffect(quality)
    if quality < 1 then
        return
    end

    local pngFileName = "Monster/petpinzhi" .. quality 

    local QualityEffect = ImodAnim:createWithFileSync(pngFileName)
    QualityEffect:setTag(112)
    QualityEffect:setScale(0.8)
    QualityEffect:PlayActionRepeat(0,0.1)
    self.m_pNode:addChild(QualityEffect,1)
end

function BattleUnitNode:ShowMonsterName()
    local MName = "Lv."
    if self.m_pData.m_type == AppDef.BTConst.Type.Monster then
        MName = MName .. self.m_pData.m_level
    else
        MName = ""
    end

    local strName = self.m_pData.m_name
    if self.m_pData.m_type == AppDef.BTConst.Type.Pet and self.m_pData.m_tupo > 0 then
        strName = strName .. "+" .. self.m_pData.m_tupo
    end
    self.m_pNameLabel:setString(strName)
    self.m_pNameLabel:setTextColor(self.m_nameColor)
    --self.m_pNameLabel:setPosition(cc.p(0,-40))
    --this->addChild(NameLabel,2,TAG_NAME_LABEL)

    --显示LV
    -- if string.len(self.m_pData.m_name) > 0 and string.len(MName) > 0 then
    --     self.m_pLvLabel:setVisible(true)
    --     self.m_bIsShowLv = true
    --     self.m_pLvLabel:setString(MName)
    --     self.m_pLvLabel:setTextColor(self.m_nameColor)
    --     self.m_pLvLabel:setPosition(cc.p(-self.m_pLvLabel:getContentSize().width / 2,self.m_pNameLabel:getContentSize().height/2))
    -- else
    --     self.m_bIsShowLv = false
    --     self.m_pLvLabel:setVisible(false)
    -- end
end

function BattleUnitNode:ShowHeroName()
    --显示人物名字
    self.m_pNameLabel:setString(self.m_pData.m_name)
    self.m_pNameLabel:setTextColor(self.m_nameColor)
    --self.m_pNameLabel:setPosition(cc.p(0,-40))

    -- if string.len(self.m_pData.m_name) > 0 then
    --     self.m_pLvLabel:setVisible(true)
    --     self.m_bIsShowLv = true
    --     self.m_pLvLabel:setString("Lv." .. self.m_pData.m_level)
    --     self.m_pLvLabel:setTextColor(self.m_nameColor)
    --     self.m_pLvLabel:setPosition(cc.p(-self.m_pLvLabel:getContentSize().width / 2,self.m_pNameLabel:getContentSize().height/2))
    -- else
    --     self.m_bIsShowLv = false
    --     self.m_pLvLabel:setVisible(false)
    -- end
end

function BattleUnitNode:GetRunAwayRes(success)
    if success == 1 then
        return "res2/fight/escapesucctext.png"
    else
        return "res2/fight/escapefailuretext.png"
    end
end

--[[
说话
]]
function BattleUnitNode:PlayChatAni(msg,playTime)
    self.m_pHpNode:ShowChat(msg, playTime)
end

--[[
播放逃跑动画
@param1:success 1成功 0 失败
]]
function BattleUnitNode:PlayRunAwayAni(success,nextActionCallback)
    --逃跑成功
    if self.m_pRunAwayCallback == nil then
        local function RunAwayCallBack()
            self:RunAwayCallBack()
        end
        self.m_pRunAwayCallback = RunAwayCallBack
    end

    if self.m_pNextCallback == nil then
        local function nextFunc()
            nextActionCallback()
        end
        self.m_pNextCallback = nextFunc
    end
    
    local picRes = self:GetRunAwayRes(success)
    -- if success == 1 then
    --     local fade = cc.FadeTo:create(1.4,0)
    --     local escapeSpr = cc.Sprite:create(picRes)
    --     --escapeSpr:setVisible(false)
    --     escapeSpr:setPosition(self.m_pNode:convertToNodeSpace(cc.p(AppDef.frameSize.width/2,AppDef.frameSize.height/2)))
    --     escapeSpr:runAction(cc.Sequence:create(fade, cc.CallFunc:create(self.m_pRunAwayCallback)))
    --     Utils:DelayToCallFunc(escapeSpr, 0.5, self.m_pNextCallback)
    --     self.m_pNode:addChild(escapeSpr,5)
    -- else
    --     --逃跑失败
    --     local escapeSpr = cc.Sprite:create(picRes)
    --     escapeSpr:setPosition(cc.p(0,70))
    --     escapeSpr:setOpacity(255)
    --     escapeSpr:setVisible(true)
    --     local move = cc.MoveBy:create(0.5,cc.p(0,100))
    --     local fade = cc.FadeTo:create(3.0,0)
    --     Utils:DelayToCallFunc(escapeSpr, 1.1, self.m_pNextCallback)
    --     escapeSpr:runAction(move)
    --     escapeSpr:runAction(cc.Sequence:create(fade, cc.CallFunc:create(BattleUnitNode.RemoveCallback)))
    --     self.m_pNode:addChild(escapeSpr,5000)
    -- end
    local escapeSpr = cc.Sprite:create(picRes)
    escapeSpr:setPosition(cc.p(0,70))
    escapeSpr:setOpacity(255)
    escapeSpr:setVisible(true)
    local move = cc.MoveBy:create(0.5,cc.p(0,100))
    local fade = cc.FadeTo:create(3.0,0)
    Utils:DelayToCallFunc(escapeSpr, 1.1, self.m_pNextCallback)
    escapeSpr:runAction(move)
    escapeSpr:runAction(cc.Sequence:create(fade, cc.CallFunc:create(BattleUnitNode.RemoveCallback)))
    self.m_pNode:addChild(escapeSpr,5000)
end

function BattleUnitNode:InitHeroAni()
    if self.m_pData.m_prof == 0 then
        self.m_pData.m_prof = 1
    end
    self.m_modelPicId = AppDef:GetHipcIdx(self.m_pData.m_prof,self.m_pData.m_sex)

    --角色建立
    local heroFileName = AppDef.HeroFileList[self.m_modelPicId]
    --------------print("--------------------InitHeroAni--------------------------------------------",heroFileName,self.m_modelPicId,self.m_pData.m_prof,self.m_pData.m_sex)
    self.m_pHitData = LDataConstMgr:GetHeroHitByIdx(self.m_pData.m_prof)
    local hpPoint = cc.p(self.m_pHitData.hpBarPos.x * self.m_pData.m_scaleRatio,self.m_pHitData.hpBarPos.y * self.m_pData.m_scaleRatio)
    local side
    if (self.m_bIsFlipPos == false and self.m_pData.m_posBid <= AppDef.BTConst.MaxHalfUnitNum)
        or (self.m_bIsFlipPos == true and self.m_pData.m_posBid > AppDef.BTConst.MaxHalfUnitNum) then
        side = 0
    else
        side = 1
    end

    self:InitWithFileName(heroFileName, side)
    self.m_pHpNode:SetVisible(true)
    self.m_pHpNode:SetMySideFlag(not self.m_isUpside)
    self.m_pHpNode:SetPosition(cc.p(hpPoint.x,hpPoint.y))
    self.m_pHpNode:ChangeHp(self.m_pData.m_maxHp, self.m_pData.m_curHp)
    self.m_pHpNode:SetOpacity(Utils:ToBool(self.m_pData.m_isBoss) and 0 or 255)
    self:ShowHeroName()
end

function BattleUnitNode:GetHitPoint(htype)
    if self.m_pHitData == nil then
        return cc.p(0,0)
    end
    if htype == AppDef.BTConst.HitPointType.Foot then
        return self.m_pHitData.footPos
    elseif htype == AppDef.BTConst.HitPointType.Middle then
        return self.m_pHitData.waistPos
    elseif htype == AppDef.BTConst.HitPointType.Head then
        return self.m_pHitData.headPos
    else
        --default
        return self.m_pHitData.footPos
    end
end

function BattleUnitNode:InitWithFileName(FileName, Local)
    self.m_fileName = FileName
    if Local == 0 then
        self.m_isUpside = true
    else
        self.m_isUpside = false
    end
    self.m_pAniCallback = nil
    self.m_pTouchCallback = nil
    --self.m_buffState = {}
    self.m_pData.m_isDead = false
    self.m_delayToNormalTime = 0.0
    self.m_isBeatBack = false 
    self.m_isPlayingText = false
    self.m_isPlayDamage = false
    -- self.m_tmpFlipX = -1
    -- self.m_tmpAnimateIdx = -1
    self.m_pModelAni:setScale(self.m_pData.m_scaleRatio)
    self.m_pModelAni:setPosition(cc.p(0,0))
end

function BattleUnitNode:ShowLv(b)
    -- if self.m_bIsShowLv == false then
    --     return
    -- end
    -- self.m_pLvLabel:setVisible(b)
end

function BattleUnitNode:ShowSelfAniModel(b)
    self.m_pModelAni:setVisible(b)
    for i = 1, self.m_buffNum do
         self.m_vecBuff[i].buffNode:setVisible(b)
    end
end


function BattleUnitNode:Init(battleLogic,node)
    --self.m_pNode = cc.Node:create()

    self.m_pNode = node
    self.m_pBTCtr = battleLogic
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pNode:registerScriptHandler(onNodeEvent)

    self:InitData()
end

function BattleUnitNode:onExit()
    self.m_pNode = nil
end

function BattleUnitNode:InitTouchEvt()
end

function BattleUnitNode:DoAnimateCallBackOnce()
    --结束后清除战斗数据
    self.m_pActionData.ActionType = -1
    self.m_isBeatBack = false

    if self.m_pAniCallback ~= nil then
        self.m_pAniCallback(self)
        self.m_pAniCallback = nil
    end
end

--[[
替代ReloadModelEffects
原函数太大，没有必要，简直就是浪费。。。。。
]]
function BattleUnitNode:ReloadHeroWeapon(suffix, modelAni)
    local pWepName = ""
    if modelAni == nil then
        modelAni = self.m_pModelAni
    end
    pWepName = AppDef.HeroBaseFileList[self.m_pData.m_prof]
    local WeaponPng = pWepName .. self.m_pData.m_lightEffect .. "_d_"

    if suffix == "sw" then
        --sw没有加到预加载里面，这个时候另外加一下
        BattlePreloadLogic:AddUsedTex2dArr(WeaponPng .. suffix .. ".png")
    end
    modelAni:addAnimWithName(WeaponPng .. suffix .. ".png", WeaponPng .. suffix .. ".ani")
end

function BattleUnitNode:OnNextActionTextCallback(sender)
    self:OnNextActionText(sender)
end

function BattleUnitNode:OnTextDelayEndCallback(sender)
    self:OnTextDelayEnd(sender)
end

function BattleUnitNode:CreateText(img)
    self.m_isPlayingText = true
    --转换成父节点坐标,增加在父节点上避免出现模型间遮挡的问题
    local parentPt = cc.p(self.m_pNode:getPosition())
    BattlePreloadLogic:AddUsedTex2dArr(img)
    local text = cc.Sprite:create(img)
    local pos = cc.p(parentPt.x,parentPt.y + 20)
    text:setPosition(pos)

    pos.y = pos.y + 30
    local movUp = cc.MoveTo:create(0.1, pos)
    pos.y = pos.y - 10
    local movDown = cc.MoveTo:create(0.1, pos)
    local callBack = cc.CallFunc:create(handler(self,BattleUnitNode.OnNextActionTextCallback))
    text:runAction(cc.Sequence:create(movUp, movDown,callBack))
    local delay = cc.DelayTime:create(1.0)
    local fadeTo = cc.FadeTo:create(0.3,0)
    text:runAction(cc.Sequence:create(delay, fadeTo))
    self.m_pNode:getParent():addChild(text, self.m_pNode:getLocalZOrder()+1)

    local callBack2 = cc.CallFunc:create(handler(self,BattleUnitNode.OnTextDelayEndCallback))
    delay = cc.DelayTime:create(0.8)
    text:runAction(cc.Sequence:create(delay,callBack2))
end

function BattleUnitNode:IsPlayingText()
    return self.m_isPlayingText
end

function BattleUnitNode:ShowBeAttackActionExText(node, img)
    if node:IsPlayingText() == false then
        node:CreateText(img)
    else
        node:KeepAttackTextMsg(node,img)
    end
end

function BattleUnitNode:KeepAttackTextMsg(node, img)
    table.insert(self.m_beAttackMsg,{node, img})
        --self.m_beAttackMsg[node] = img
end

function BattleUnitNode:OnNextActionText(psender)
    local Move = cc.MoveBy:create(0.3,cc.p(0,30))
    psender:runAction(Move)
    ------------print("OnNextActionText",#self.m_beAttackText)
    for i = 1, #self.m_beAttackText do
        local tMove = cc.MoveBy:create(0.3,cc.p(0,30))
        self.m_beAttackText[i]:runAction(tMove)
    end
    table.insert(self.m_beAttackText,psender)
    if #self.m_beAttackMsg > 0 then
        self.m_beAttackMsg[1][1]:CreateText(self.m_beAttackMsg[1][2])
        self.m_beAttackMsg[1] = nil
        table.remove(self.m_beAttackMsg,1)
    else
        self.m_isPlayingText = false
    end
end

function BattleUnitNode:OnTextDelayEnd(pSender)

    local move = cc.MoveBy:create(0.3,cc.p(0,30))
    local sineMov = cc.EaseSineIn:create(move)
    local func = cc.CallFunc:create(BattleUnitNode.RemoveCallback)
    pSender:runAction(cc.Sequence:create(sineMov,func))

    for i = 1,#self.m_beAttackText do
        if pSender == self.m_beAttackText[i] then
            table.remove(self.m_beAttackText,i)
            break
        end
    end
end

-- function BattleUnitNode:SetLightRing(b, Opacity, color)
--     self.m_pNode:removeChildByTag(BattleUnitNode.TAG_ANI_LIGHT_RING)

--     if b == true then
--         local ring = ImodAnim:createWithFile("UI/mb_light_ring.png","UI/mb_light_ring.ani")
--         ring:PlayActionRepeat(0, 0.15)
--         ring:setOpacity(Opacity)
--         ring:setPosition(cc.p(10, -20))
--         ring:setColor(color)
--         ring:setScale(GetModelScale())
--         self.m_pNode:addChild(ring, 101, BattleUnitNode.TAG_ANI_LIGHT_RING)
--     end
-- end

function BattleUnitNode:PoisonDamage(damege,xishou, normalState, stateNum, states)
    self:BeAttacked(damege, 0,xishou, normalState, stateNum, states,true)
    --self:AssignBuff(stateNum, states)
end

function BattleUnitNode:AddHPSkill(hp, normalState, stateNum, states)
    self:BeAttacked(0,hp,0,normalState, stateNum, states,true)
    --self:AssignBuff(stateNum, states)
end

function BattleUnitNode:IsInDeadState()
    if self.m_pData == nil then
        return true
    end
    -- print("IsInDeadState",self.m_pData.m_name, self.m_pData.m_normalState)
    if bit._and(self.m_pData.m_normalState ,0x01) == 0x01 then
        return true
    end
    return false;
    -- local deadOffset = (AppDef.BTConst.UnitState.ESBUFF_Died - 1 )%32
    -- local curState = self.m_pData.m_states[2]
    -- if curState == 0 then
    --     return false
    -- end
    -- ------------print("curState",curState)
    -- local deadValue = math.abs(bit.lshift(1,deadOffset))
    -- ------------print("deadValue",deadValue)
    -- if bit._and(deadValue,curState) == deadValue then
    --     return true
    -- end
    -- return false
end

function BattleUnitNode:SetBuffState(stateNum, states)
    if self.m_pData.m_stateNum == stateNum then
        local isSame = true
        for i = 1, stateNum do
            if self.m_pData.m_states[i] ~= states[i] then
                isSame = false
            end
        end
        if isSame then
            return
        end
    end
    local oldDead = self.m_pData.m_isDead
    self.m_pData.m_stateNum = stateNum
    self.m_pData.m_states = {}
    for i = 1, stateNum do
        table.insert(self.m_pData.m_states,states[i])
    end
    self:CheckBuff()
end

function BattleUnitNode:AddHp(hp, normalState, stateNum, states, isNeedEffect)
    if self.m_pData == nil then
        return
    end
    if self.m_pData.m_isDead then
        --当前处于死亡状态，
        self.m_pData.m_curHp = 0--强制把血量清零后加血
    end
    local curHp = self.m_pData.m_curHp
    self.m_pData.m_curHp = self.m_pData.m_curHp + hp
    if self.m_pData.m_curHp > self.m_pData.m_maxHp then
        self.m_pData.m_curHp = self.m_pData.m_maxHp
    end
    
    if hp ~= 0 then
        if Utils:ToBool(self.m_pData.m_isBoss) then
            Utils:SendMsg(LUIBattleEvent.UpdateFightHP, {pos=self.m_pData.m_posBid, hp=self.m_pData.m_curHp})
        end
        self.m_pHpNode:ChangeHp(self.m_pData.m_maxHp, curHp, hp, 0, false,isNeedEffect)
    end
    local oldNormalState = self.m_pData.m_normalState
    self:SetBuffState(stateNum, states)
    if oldNormalState ~= normalState then
        self.m_pData.m_normalState = normalState;
        local oldDead = self.m_pData.m_isDead
        if self:IsInDeadState() then
            self.m_pData.m_isDead = true
        else
            self.m_pData.m_isDead = false
        end

        if self.m_pData.m_isDead then
            self:SetState(AppDef.BTConst.UnitActState.DEATH)
            self:CheckBuff()
        else
            if oldDead == true then
                --复活
                self.m_pHpNode:SetVisible(true)
                self.m_pHpNode:SetOpacity(Utils:ToBool(self.m_pData.m_isBoss) and 0 or 255)
                self:SetState(AppDef.BTConst.UnitActState.NORMAL)
                self:PlayAniByState()
            else
                self:CheckBuff()
            end
        end
    end
    
    
end

function BattleUnitNode:PlayFanzhenEffect()
    self:ShowBeAttackActionExText(self, "res2/skill_name/injurytext.png")
end

function BattleUnitNode:BeDodge()
    self:ShowBeAttackActionExText(self, "res2/skill_name/dodgetext.png")
end

function BattleUnitNode:FanjiActionStart(time)
    if time > 0 then
        local function DelayToPlay()
            self:PlayFanjiEffectFunc()
        end
        Utils:DelayToCallFunc(self.m_pBTCtr.m_pNode, self.m_pBTCtr:getFightTime(), DelayToPlay)
    else
        self:PlayFanjiEffectFunc()
    end
end

function BattleUnitNode:PlayFanjiEffectFunc()

    self:PlayFanjiEffect()
    self.m_pBTCtr:PlayBTFanjiAction(0)
    -- local function PlayFanjiAction()
    --     self.m_pBTCtr:PlayBTFanjiAction(time)
    -- end

    -- Utils:DelayToCallFunc(self.m_pBTCtr.m_pNode, self.m_pBTCtr:getFightTime(0.2), PlayFanjiAction)
end

function BattleUnitNode:PlayFanjiEffect()
    --print("播放反击文字",self.m_pData.m_name,self.m_pData.m_posBid)
    self:ShowBeAttackActionExText(self, "res2/skill_name/beatbacktext.png")
end

function BattleUnitNode:ShowComboEffect()
    self:ShowBeAttackActionExText(self, "res2/skill_name/combotext.png")
end

function BattleUnitNode:BeAttacked(Damage, RecoverHp, xishou, normalState, stateNum, states, isNeedEffect, combo, crit)
    --如果死亡播放数值
    -- if self.m_pData.m_isDead == false then
    --     HpChangeEffect(-Damage, crit)
    --     _IsPlayDamage = false
    --     return
    -- end
    if self.m_pData == nil then
        return
    end
    
    local curHp = self.m_pData.m_curHp
    -- print("BeAttacked",self.m_pData.m_name,normalState,stateNum)
    self.m_pData.m_curHp = self.m_pData.m_curHp - Damage
    if self.m_pData.m_curHp < 0 then
        self.m_pData.m_curHp = 0
    end
    if isNeedEffect == true then
        --连击
        if combo then
            self:ShowBeAttackActionExText(self, "res2/skill_name/combotext.png")
        end
        --暴击
        if crit then
            self:ShowBeAttackActionExText(self, "res2/skill_name/crittext.png")
        end
        if Damage > 0 then
            self:PlayHitAudio()
        end
    end
    if Damage ~= 0 or xishou ~= 0 then
        if Utils:ToBool(self.m_pData.m_isBoss) then
            Utils:SendMsg(LUIBattleEvent.UpdateFightHP, {pos=self.m_pData.m_posBid, hp=self.m_pData.m_curHp})
        end
        self.m_pHpNode:ChangeHp(self.m_pData.m_maxHp, curHp, -Damage, xishou, crit,isNeedEffect)
    end

    local curHp = self.m_pData.m_curHp
    self.m_pData.m_curHp = self.m_pData.m_curHp + RecoverHp
    if self.m_pData.m_curHp > self.m_pData.m_maxHp then
        self.m_pData.m_curHp = self.m_pData.m_maxHp
    end
    if RecoverHp ~= 0 then
        if Utils:ToBool(self.m_pData.m_isBoss) then
            Utils:SendMsg(LUIBattleEvent.UpdateFightHP, {pos=self.m_pData.m_posBid, hp=self.m_pData.m_curHp})
        end
        self.m_pHpNode:ChangeHp(self.m_pData.m_maxHp, curHp, RecoverHp, 0, false,isNeedEffect)
    end

    local oldNormalState = self.m_pData.m_normalState
    self:SetBuffState(stateNum, states)
    if oldNormalState ~= normalState then
        self.m_pData.m_normalState = normalState;
        self:CheckDeadState()
    end
end

function BattleUnitNode:CheckDeadState()
    if self.m_pData == nil then
        return
    end
    if self:IsInDeadState() then
        self.m_pData.m_isDead = true
    else
        self.m_pData.m_isDead = false
    end
    if self.m_pData.m_isDead then
        self:SetState(AppDef.BTConst.UnitActState.DEATH)
    end
end

function BattleUnitNode:SetAngerBoomEffect(v)
    if self.m_pData.m_type == AppDef.BTConst.Type.Hero then
        self:SetHeroAngerBoomEffect(v)
    else
        self:SetMonsterAngerBoomEffect(v)
    end
end

function BattleUnitNode:SetHeroAngerBoomEffect(v)
    self.m_pNode:removeChildByTag(BattleUnitNode.TAG_ANI_BOOM)

    if false == v then
        return
    end

    local imod = ImodAnim:createWithFile("res2/skill_name/battle_hero_anger_boom.png","res2/skill_name/battle_hero_anger_boom.ani")
    imod:PlayAction(0)
    imod:setPosition(cc.p(0,0))
    self.m_pNode:addChild(imod, BattleUnitNode.ZORDER_ANI_BOOM, BattleUnitNode.TAG_ANI_BOOM)
end

function BattleUnitNode:SetMonsterAngerBoomEffect(v)
    self.m_pNode:removeChildByTag(BattleUnitNode.TAG_ANI_BOOM)

    if false == v then
        return
    end

    local imod = ImodAnim:createWithFile("res2/skill_name/battle_pet_anger_boom.png","res2/skill_name/battle_pet_anger_boom.ani")
    imod:PlayAction(0)
    imod:setPosition(cc.p(0,0))
    self.m_pNode:addChild(imod, BattleUnitNode.ZORDER_ANI_BOOM, BattleUnitNode.TAG_ANI_BOOM)
end

function BattleUnitNode:SetAngerBurningEffect(v)
    if self.m_pData.m_type == AppDef.BTConst.Type.Hero then
        self:SetHeroAngerBurningEffect(v)
    else
        self:SetMonsterAngerBurningEffect(v)
    end
end

function BattleUnitNode:SetMonsterAngerBurningEffect(v)
    self.m_pNode:removeChildByTag(BattleUnitNode.TAG_ANI_BURNING)

    if false == v then
        return
    end
    local imod = ImodAnim:createWithFile("res2/skill_name/battle_pet_anger_burning.png","res2/skill_name/battle_pet_anger_burning.ani")
    imod:PlayAction(0)
    imod:setPosition(cc.p(0,0))
    self.m_pNode:addChild(imod, BattleUnitNode.ZORDER_ANI_BURNING, BattleUnitNode.TAG_ANI_BURNING)
end

function BattleUnitNode:SetHeroAngerBurningEffect(v)
    self.m_pNode:removeChildByTag(BattleUnitNode.TAG_ANI_BURNING)

    if false == v then
        return
    end
    local imod = ImodAnim:createWithFile("res2/skill_name/battle_hero_anger_burning.png","res2/skill_name/battle_hero_anger_burning.ani")
    imod:PlayAction(0)
    imod:setPosition(cc.p(0,0))
    self.m_pNode:addChild(imod, BattleUnitNode.ZORDER_ANI_BURNING, BattleUnitNode.TAG_ANI_BURNING)
end

function BattleUnitNode:GetCurAniTime()
    if self.m_state == AppDef.BTConst.UnitActState.HIT then
        return 0.8
    end
    return self.m_pModelAni:GetCurAniTime()
end

function BattleUnitNode:SetHurtEffect(modelAni)
    --播放被击移动效果和模型晃动效果(被击移动位置然后又回来)
    local backPos = cc.p(0,0)
    if modelAni == nil then
        modelAni = self.m_pModelAni
    else
        --分身位置
        backPos = cc.p(modelAni:getPosition())
    end
    local offset
    if (self.m_bIsFlipPos == false and self.m_pData.m_posBid <= AppDef.BTConst.MaxHalfUnitNum)
        or (self.m_bIsFlipPos == true and self.m_pData.m_posBid > AppDef.BTConst.MaxHalfUnitNum) then
        offset = cc.p(-20,20)
    else
        offset = cc.p(20,-20)
    end
    local move = cc.MoveBy:create(0.3,offset)

    local sinIn = cc.EaseSineIn:create(move)
    local move2 = cc.MoveTo:create(0.3,backPos)
    local sinOut = cc.EaseSineIn:create(move2)
    local delay = cc.DelayTime:create(0.2)
    modelAni:runAction(cc.Sequence:create(delay, sinIn, sinOut))
    modelAni:runAction(CEffectShake:create(0.2,5))
end

function BattleUnitNode:PlayAniByName(aniName, loop, speed)
    if self.m_pData == nil then
        
        return
    end
    loop = loop or false
    self.m_pModelAni:stopAllActions()
    self.m_pModelAni:setPosition(cc.p(0,0))

    local IsFlipX = false
    -- local AnimateIdx = 0
    -- if self.m_isUpside == false then
    --     IsFlipX = true
    --     AnimateIdx = 1
    -- end

    local AnimateIdx = 0
    if self.m_isUpside == false then
        IsFlipX = true
        AnimateIdx = 1
        -- if aniName == "zd" and ( self.m_pData.m_type == AppDef.BTConst.Type.Monster 
        --     or self.m_pData.m_type == AppDef.BTConst.Type.Pet) then
        --     AnimateIdx = 3
        -- end 
    end
    
    --重新加载英雄模型
    local aniFile = self.m_fileName .. aniName
    
    self.m_pModelAni:initAnimWithName(aniFile)
    self.m_pModelAni:setFlippedX(IsFlipX)
    
    if self.m_pData.m_type == AppDef.BTConst.Type.Hero then
        --英雄身上的特效跟着切换
        self:ReloadHeroWeapon(aniName)
    end

    self.m_pModelAni:PlayNewAction(AnimateIdx,loop)
    local _ = speed and self.m_pModelAni:SetSpeedScale(speed)
    -- if self.m_paniPlayEndCallback == nil then
    --     local function AniPlayEnd()
    --         self:AniPlayEnd()
    --     end
    --     self.m_paniPlayEndCallback = AniPlayEnd
    -- end
    local function AniPlayEnd()
        self:AniPlayEnd()
    end
    
    if loop == false then
        if self.m_state == AppDef.BTConst.UnitActState.HIT then
            self.m_pModelAni:unregisterScriptEndCBHandler()
            Utils:DelayToCallFunc(self.m_pNode, 0.8,AniPlayEnd)
        else
            self.m_pNode:stopAllActions()
            self.m_pModelAni:registerScriptEndCBHandler(AniPlayEnd)
        end
    else
        self.m_pModelAni:unregisterScriptEndCBHandler()
        if self.m_state == AppDef.BTConst.UnitActState.HIT then
            Utils:DelayToCallFunc(self.m_pNode, 0.8,AniPlayEnd)
        end
        
    end

    if self.m_state == AppDef.BTConst.UnitActState.HIT then
        self:SetHurtEffect()

        --分身播放被击
        for i = 1, #self.m_pSplitAni do
            local modelAni = self.m_pSplitAni[i][2]
            modelAni:initAnimWithName(aniFile)
            modelAni:setFlippedX(IsFlipX)
            
            if self.m_pData.m_type == AppDef.BTConst.Type.Hero then
                --英雄身上的特效跟着切换
                self:ReloadHeroWeapon(aniName,modelAni)
            end

            modelAni:PlayNewAction(AnimateIdx,loop)
            self:SetHurtEffect(modelAni)
        end
    elseif self.m_state == AppDef.BTConst.UnitActState.RUNAWAY then
            local fadeAction = cc.FadeOut:create(0.5)
            local scaleAction = cc.ScaleTo:create(0.5,0)
            local moveAction = cc.MoveBy:create(0.5,cc.p(0,500))
            local spawnAction = cc.Spawn:create(fadeAction,scaleAction,moveAction)
            
            if self.m_pRunAwayCallback == nil then
                local function RunAwayCallBack()
                    self:RunAwayCallBack()
                end
                self.m_pRunAwayCallback = RunAwayCallBack
            end
            local callbackAction = cc.CallFunc:create(self.m_pRunAwayCallback)
            local seqAction = cc.Sequence:create(spawnAction,callbackAction)
            self.m_pNode:runAction(seqAction)
    end
end

function BattleUnitNode:RunAwayCallBack()
    self.m_pNode:setVisible(false)
end

function BattleUnitNode:ClearSplitNode()
    for i = #self.m_pSplitAni, 1, -1 do
        self.m_pSplitAni[i][2]:removeFromParent()
        self.m_pSplitAni[i][2] = nil
        self.m_pSplitAni[i][1] = nil
        self.m_pSplitAni[i] = nil
        table.remove(self.m_pSplitAni,i)
        
    end
    --self.m_pSplitAni = {}
end

--[[
获取分身动画节点
sbid：分身的目标位置
]]
function BattleUnitNode:GetSplitNode(sbid)
    for i = 1, #self.m_pSplitAni do
        if self.m_pSplitAni[i][1] == sbid then
            return self.m_pSplitAni[i][2]
        end
    end
    return self.m_pNode
    --return nil
end

--
function BattleUnitNode:AniPlayEnd()
    ----print("AniPlayEnd","name=",self.m_pData.m_name,"state=",self.m_state)
    if self.m_state == AppDef.BTConst.UnitActState.ATTACK then
        self:SetState(AppDef.BTConst.UnitActState.NORMAL)
        self:PlayAniByState()
    elseif self.m_state == AppDef.BTConst.UnitActState.HIT then
        self:SetState(AppDef.BTConst.UnitActState.NORMAL)
        self:PlayAniByState()
    elseif self.m_state == AppDef.BTConst.UnitActState.DEATH then
        self:PlayAniByState()
    end
end

--[[
创造分身
]]
function BattleUnitNode:CreateSplit(aniName, tbid)

    local IsFlipX = false
    local AnimateIdx = 0
    if self.m_isUpside == false then
        IsFlipX = true
        AnimateIdx = 1
    end

    local aniFile = self.m_fileName .. aniName

    local modelAni = nil
    for i = 1, #self.m_pSplitAni do
        if self.m_pSplitAni[i][1] == tbid then
            modelAni = self.m_pSplitAni[i][2]
            break
        end
    end

    if modelAni == nil then
        modelAni = ImodAnim:createWithFile(aniFile)
        self.m_pBTCtr.m_pNode:addChild(modelAni)
        table.insert(self.m_pSplitAni,{tbid, modelAni})
    else
        modelAni:initAnimWithName(aniFile)
    end
    
    modelAni:setFlippedX(IsFlipX)
    
    if self.m_pData.m_type == AppDef.BTConst.Type.Hero then
        --英雄身上的特效跟着切换
        self:ReloadHeroWeapon(aniName,modelAni)
    end

    -- local function AnimateStateCallBack(sender)
    --     self:AnimateStateCallBack(sender)
    -- end
    modelAni:PlayNewAction(AnimateIdx,loop)
    return modelAni

end

return BattleUnitNode