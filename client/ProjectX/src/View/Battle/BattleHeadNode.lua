--[[
lua里面的游戏逻辑控制
]]
local HpPool = require("View.Battle.BattleHpTextPool")
local BattleHeadNode = {}
BattleHeadNode.__index = BattleHeadNode

BattleHeadNode.m_iHpAbovePos = nil
BattleHeadNode.m_iHpBeolwPos = nil
--local this = LTcpSocket
function BattleHeadNode:New()
	local o = {}
	setmetatable(o,BattleHeadNode)	
    o:Init()
	return o
end


function BattleHeadNode:Init()
    --self.m_pNode = cc.Node:create()

    self.m_pNode = cc.CSLoader:createNode("csd/HPNode.csb")
    self.m_pNode:setLocalZOrder(100)
    -- self._hplabel = cc.Label:createWithSystemFont("", AppDef.FNT_NAME, AppDef.UIFONTSIZELB);
    -- self.m_pNode:addChild(self._hplabel);
   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pNode:registerScriptHandler(onNodeEvent)
    self.m_curHpRes = ""
    self:InitData()
end

function BattleHeadNode:onExit()
    self.m_pNode = nil
end

function BattleHeadNode:SetVisible(isVisible)
    self.m_pNode:setVisible(isVisible)
end

function BattleHeadNode:SetReadyFlagVisible(isVisible)
    self.m_pReadySp:setVisible(isVisible)
end

function BattleHeadNode:AddChild(child)
    self.m_pNode:addChild(child)
end

function BattleHeadNode:Reset()
    self.m_HpBar:stopAllActions()
    -- self.m_damageLabel:stopAllActions()
    -- self.m_damageLabel:setVisible(false)
    -- self.m_recoverLabel:stopAllActions()
    -- self.m_recoverLabel:setVisible(false)
    self.m_pReadySp:setVisible(false)
    self.m_pQuality:setVisible(false)
    self.m_pQualityBg:setVisible(false)
    self.m_bIsShowHpEffect = false
    while #self.m_vecHpEffect > 0 do
        self.m_vecHpEffect[1] = nil
        table.remove(self.m_vecHpEffect,1)
    end
    self.m_pChatMsgPanel:setVisible(false)
    while #self.m_pHpLabelArr > 0 do
        self.m_pHpLabelArr[1] = nil
        table.remove(self.m_pHpLabelArr,1)
    end

    self.m_pStarList:removeAllItems()
end

function BattleHeadNode:ShowStar(starNum)
    self.m_pStarList:removeAllItems()
    for i = 1, starNum do
        local node = self.m_pStarCell:clone();
        node:setVisible(true);
        self.m_pStarList:pushBackCustomItem(node)
    end
end

function BattleHeadNode:ShowChat(msg, playTime)
    --print("msg",msg,"playTime",playTime)
    self.m_pChatMsgPanel:setVisible(true)
    self.m_pChatMsgPanel:stopAllActions()
    if self.m_pChatMsgLabel == nil then
        local label = self.m_pChatMsgPanel:getChildByName("Text")
        label:setVisible(false)
        local width = label:getContentSize().width - 10
        local fontSize = label:getFontSize()
        local fontColor = label:getTextColor()
        self.m_pChatMsgLabel = CCAysLabel:createWithString(msg,
            width,fontSize,fontColor)
        self.m_pChatMsgPanel:addChild(self.m_pChatMsgLabel)
    else
        self.m_pChatMsgLabel:setString(msg)
    end

    local msgSize = self.m_pChatMsgLabel:getSize()
    local panelSize = self.m_pChatMsgPanel:getContentSize()
    panelSize.height = msgSize.height + 25
    self.m_pChatMsgPanel:setContentSize(panelSize)
    self.m_pChatMsgLabel:setPosition(cc.p(10, msgSize.height + 15))
    if self.m_pChatCallback == nil then
        local function ChatEnd()
            self.m_pChatMsgPanel:setVisible(false)
        end
        self.m_pChatCallback = ChatEnd
    end
    
    performWithDelay(self.m_pChatMsgPanel, self.m_pChatCallback, playTime)
end

function BattleHeadNode:SetPosition(pos)
    self.m_pNode:setPosition(pos)
end

function BattleHeadNode:SetMySideFlag(isMySide)
    --local hpsp = self.m_HpBar:getSprite()
    local MyHpBarRes = "res/UI/ui_juese/ui_juese_jingyan.png"
    local EnemyHpBarRes = "res/UI/ui_juese/ui_juese_xuetiao.png"

    local sp
    local res
    if isMySide then
        --hpsp:setSpriteFrame(MyHpBarRes)
        res = MyHpBarRes
        sp = self.m_pGreenHpSp
    else
       -- hpsp:setSpriteFrame(EnemyHpBarRes)
        res = EnemyHpBarRes
        sp = self.m_pRedHpSp
    end
    if res == self.m_curHpRes then
        return
    end
    --local sp = self.m_HpBar:getSprite()
    --local sp = cc.Sprite:createWithSpriteFrameName(res)
    self.m_HpBar:setSprite(sp)
end
--显示品质
function BattleHeadNode:SetQuality(settype,type)

    if settype<1 or type~=AppDef.BTConst.Type.Pet then

         self.m_pQualityBg:setVisible(false)
        return
    end

       self.m_pQualityBg:setVisible(true)
       self.m_pQuality:setVisible(true)
       self.m_pQualityBg:setVisible(true)
       AppDef:GetPetQualityScore(self.m_pQuality,settype)
       

end
function BattleHeadNode:InitData()
    self.m_pHpLabelArr = {}
    self.m_pChatMsgPanel = self.m_pNode:getChildByName("Duihua")
    self.m_pChatMsgPanel:setVisible(false)
    self.m_pChatMsgLabel = nil--

    self.m_pStarCell = self.m_pNode:findChildByName("StarList/Star")
    self.m_pStarCell:retain()
    self.m_pStarCell:removeFromParent()
    self.m_pNode:addChild(self.m_pStarCell)
    self.m_pStarCell:release();
    self.m_pStarCell:setVisible(false)
    self.m_pStarList = self.m_pNode:getChildByName("StarList")
    self.m_pStarList:setVisible(true)
    self.m_pReadySp = self.m_pNode:getChildByName("Sprite_1")
    --伤血数字
    local damageLabel = self.m_pNode:getChildByName("Minus")
    damageLabel:setVisible(false)
    self.m_pNumLabelHeight = damageLabel:getContentSize().height
--    self.m_damageLabel:setGlobalZOrder(1)
    --加血数字
    local recoverLabel = self.m_pNode:getChildByName("Plus")
    recoverLabel:setVisible(false)

    damageLabel:retain()
    damageLabel:removeFromParent()

    recoverLabel:retain()
    recoverLabel:removeFromParent()
    HpPool:Init(damageLabel, recoverLabel)
    

    self.m_pQualityBg=self.m_pNode:getChildByName("Quality_bg")
  
    --self.m_pQualityBg:setCascadeOpacityEnabled(false)
    self.m_pQuality=self.m_pQualityBg:getChildByName("Quality")
    self.m_pQualityBg:setVisible(false)

    self.m_pXiShouHpLabel = self.m_pNode:getChildByName("Xishou")
    self.m_pXiShouHpLabel:setVisible(false)
--    self.m_recoverLabel:setGlobalZOrder(1)

    self.m_HpBarBg = self.m_pNode:getChildByName("bg")
    --local hpsp = self.m_pNode:getChildByName("HPSp")
    self.m_pRedHpSp = self.m_pNode:getChildByName("HPSp")
    self.m_pGreenHpSp = self.m_pNode:getChildByName("HPSp_0")
    self.m_hpHeight = self.m_pRedHpSp:getContentSize().height
    --hpsp:setAnchorPoint(cc.p(0,0))

    --hpsp:setSpriteFrame(MyHpBarRes)
    self.m_pGreenHpSp:retain()
    self.m_pGreenHpSp:removeFromParent()

    self.m_pRedHpSp:retain()
    self.m_pRedHpSp:removeFromParent()
    self.m_HpBar = cc.ProgressTimer:create(self.m_pRedHpSp)

    self.m_HpBar:setType(cc.PROGRESS_TIMER_TYPE_BAR)
    self.m_HpBar:setAnchorPoint(self.m_pRedHpSp:getAnchorPoint())
    local scx = self.m_pRedHpSp:getScaleX()
    local scy = self.m_pRedHpSp:getScaleY()
    self.m_HpBar:setScale(scx, scy)
    
    local pos = cc.p(self.m_pRedHpSp:getPosition())
    self.m_HpBar:setPosition(pos)
    self.m_HpBar:setMidpoint(cc.p(0,0.5))
    self.m_HpBar:setBarChangeRate(cc.p(1,0))
    self.m_HpBar:setPercentage(0)
    --self.m_HpBar:runAction(cc.ProgressTo:create(0.5, ratio*100))
    self.m_pNode:addChild(self.m_HpBar)

    self.m_pXiShouHpLabel:setLocalZOrder(self.m_HpBar:getLocalZOrder() + 1)

    self.m_pReadySp:setVisible(false)
    self.m_bIsShowHpEffect = false
    self.m_vecHpEffect = {}
   
    
    if BattleHeadNode.m_iHpAbovePos == nil then
        local hpSize = self.m_pRedHpSp:getContentSize()
        local scaleX = self.m_pRedHpSp:getScaleX()
        local scaleY = self.m_pRedHpSp:getScaleY()
        BattleHeadNode.m_iHpAbovePos = cc.p(pos.x - (hpSize.width*scaleX)/2,pos.y + (hpSize.height*scaleY)/2)
        BattleHeadNode.m_iHpBeolwPos = cc.p(pos.x - (hpSize.width*scaleX)/2,pos.y + (hpSize.height*scaleY)/2)
    end
end

function BattleHeadNode:GetHpAbovePos()
    return BattleHeadNode.m_iHpAbovePos
end

function BattleHeadNode:GetHpBelowPos()
    return BattleHeadNode.m_iHpBeolwPos
end

function BattleHeadNode:HpChangeEffect()
    if #self.m_vecHpEffect == 0 then
        self.m_bIsShowHpEffect = false
        return
    end
    self.m_bIsShowHpEffect = true
    local curHp = self.m_vecHpEffect[1][2]
    local damage = self.m_vecHpEffect[1][3]
    local maxHp = self.m_vecHpEffect[1][1]
    local xishou = self.m_vecHpEffect[1][4]
    local baoji = self.m_vecHpEffect[1][5]
    table.remove(self.m_vecHpEffect,1)
    local rat = (curHp + damage) * 100 / maxHp
    if rat > maxHp then
        rat = maxHp
    elseif rat < 0 then
        rat = 0
    end

    -- if self.m_pHpBarEndCallback == nil then
    --     local function HpBarAniEnd()
    --         self:HpChangeEffect()
    --     end
    --     self.m_pHpBarEndCallback = HpBarAniEnd
    -- end
    local function HpBarAniEnd()
        self:HpChangeEffect()
    end
    
    local pro = cc.ProgressTo:create(0.2, rat)
    -- local func = cc.CallFunc:create(HpBarAniEnd)
    -- local sq = cc.Sequence:create(pro, func)
    self.m_HpBar:stopAllActions()
    self.m_HpBar:runAction(pro)

    local function HpNumEnd(sender)
        sender:setVisible(false)
    end
    
    local function DamageHpNumEnd(sender)
        sender:setVisible(false)
        HpPool:UnUseText(BattleHpTextPool.TextColor_Red,sender)
        sender:removeFromParent()
        for i = 1, #self.m_pHpLabelArr do
            if self.m_pHpLabelArr[i] == sender then
                table.remove(self.m_pHpLabelArr,i)
                break
            end
        end
    end

    local function RecoverHpNumEnd(sender)
        sender:setVisible(false)
        HpPool:UnUseText(BattleHpTextPool.TextColor_Green, sender)
        sender:removeFromParent()
        for i = 1, #self.m_pHpLabelArr do
            if self.m_pHpLabelArr[i] == sender then
                table.remove(self.m_pHpLabelArr,i)
                break
            end
        end
    end
    
    -- if self.m_pHpNumEndCallback == nil then
    --     local function HpNumEnd(sender)
    --         sender:setVisible(false)
    --     end
    --     self.m_pHpNumEndCallback = HpNumEnd
    -- end
    
    local fightSpeedScale = LRoleDataMgr:GetFightSpeed() + 1
    --local fightSpeedScale = 1
    --暴击伤害数字显示效果不同
    local STAY_T = 0.8
    local moveby = cc.MoveBy:create(0.3 / fightSpeedScale,cc.p(0,125))
    local sinMov = cc.EaseSineIn:create(moveby)
    local seqMov = nil
    local seqFade = nil
    local labelActionEndCallback
    if damage < 0 then --伤害
        labelActionEndCallback = DamageHpNumEnd
    else
        labelActionEndCallback = RecoverHpNumEnd
    end
    if baoji then
        seqMov = cc.Sequence:create(cc.ScaleTo:create(0.3 / fightSpeedScale,3.0),
                    cc.ScaleTo:create(0.1 / fightSpeedScale,1.5),
                    cc.DelayTime:create(STAY_T / fightSpeedScale),
                    sinMov,
                    cc.CallFunc:create(labelActionEndCallback))
        seqFade = cc.Sequence:create(cc.DelayTime:create((0.3+0.1+STAY_T) / fightSpeedScale), 
                    cc.FadeTo:create(0.3 / fightSpeedScale,0))
    else  
        seqMov = cc.Sequence:create(cc.ScaleTo:create(0.1 / fightSpeedScale,1.0),
                    cc.DelayTime:create(STAY_T / fightSpeedScale),
                    sinMov,
                    cc.CallFunc:create(labelActionEndCallback))
        seqFade = cc.Sequence:create(cc.DelayTime:create((0.1+STAY_T) / fightSpeedScale),
                    cc.FadeTo:create(0.3 / fightSpeedScale,0))
    end

    --伤害或治疗显示
    if damage < 0 then --伤害
        local label = HpPool:UseText(BattleHpTextPool.TextColor_Red)
        label:stopAllActions()
        label:setString(0-damage)
        label:setOpacity(255)
        label:setVisible(true)
        label:setScale(0.0)
        label:setPositionY(30 + #self.m_pHpLabelArr*self.m_pNumLabelHeight)
        label:runAction(seqMov)
        label:runAction(seqFade)
        self.m_pNode:addChild(label)
        table.insert(self.m_pHpLabelArr,label)
    elseif damage >0 then --回血
        local label = HpPool:UseText(BattleHpTextPool.TextColor_Green)
        label:stopAllActions()
        label:setOpacity(255)
        label:setScale(0.0)
        label:setString(damage)
        label:setVisible(true)
        label:setPositionY(30 + #self.m_pHpLabelArr*self.m_pNumLabelHeight)
        label:runAction(seqMov)
        label:runAction(seqFade)
        self.m_pNode:addChild(label)
        table.insert(self.m_pHpLabelArr,label)
    end

    --Utils:DelayToCallFunc(self.m_pNode, 1,self.m_pHpBarEndCallback)
    --Utils:DelayToCallFunc(self.m_pNode, 0.1,HpBarAniEnd)

    if xishou > 0 then
        moveby = cc.MoveBy:create(0.3 / fightSpeedScale,cc.p(0,65))
        sinMov = cc.EaseSineIn:create(moveby)
        seqMov = nil
        seqFade = nil
        seqMov = cc.Sequence:create(cc.ScaleTo:create(0.1 / fightSpeedScale,1.0),
                    cc.DelayTime:create(STAY_T / fightSpeedScale),
                    sinMov,
                    cc.CallFunc:create(HpNumEnd))
        seqFade = cc.Sequence:create(cc.DelayTime:create((0.1+STAY_T) / fightSpeedScale),
                    cc.FadeTo:create(0.3,0))

        self.m_pXiShouHpLabel:stopAllActions()
        self.m_pXiShouHpLabel:setString(xishou)
        self.m_pXiShouHpLabel:setOpacity(255)
        self.m_pXiShouHpLabel:setVisible(true)
        self.m_pXiShouHpLabel:setScale(0.0)
        self.m_pXiShouHpLabel:setPositionY(-40)
        self.m_pXiShouHpLabel:runAction(seqMov)
        self.m_pXiShouHpLabel:runAction(seqFade)

    end
    -- CallFunc* resetPlayDamage = CallFunc::create(CC_CALLBACK_0(BattleUnitNode::ResetIsPlayDamage,this));
    -- runAction(Sequence::create(BAC_DL(1.f),resetPlayDamage,NULL));
end


function BattleHeadNode:ChangeHp(maxHp, curHp, damage, xishouHp, baoji, showEffect)

    
    damage = damage or 0
    xishouHp = xishouHp or 0
    baoji = baoji or false
    showEffect = showEffect or false
    -- self._hplabel:setString((curHp + damage) / maxHp);
    --ChangeHp  3333    3333    -850    0   true
    --print("ChangeHp",maxHp, curHp, damage, baoji, showEffect)
    if showEffect == false then
        local rat = (curHp + damage) * 100 / maxHp
        if rat > 100 then
            rat = 100
        elseif rat < 0 then
            rat = 0
        end
        self.m_HpBar:setPercentage(rat)
    else
        table.insert(self.m_vecHpEffect,{maxHp, curHp, damage, xishouHp, baoji})
        -- if self.m_bIsShowHpEffect == false then
        --     self:HpChangeEffect()
        -- end
        self:HpChangeEffect()
    end
end


-- function BattleHeadNode:ChangeHp(maxHp, curHp, damage, baoji, showEffect)
--     damage = damage or 0
--     baoji = baoji or false
--     showEffect = showEffect or false
--     --ChangeHp  3333    3333    -850    0   true
--     --print("ChangeHp",maxHp, curHp, damage, baoji, showEffect)
--     if showEffect == false then
--         local rat = (curHp + damage) * 100 / maxHp
--         if rat > 100 then
--             rat = 100
--         elseif rat < 0 then
--             rat = 0
--         end
--         self.m_HpBar:setPercentage(rat)
--     else
--         table.insert(self.m_vecHpEffect,{maxHp, curHp, damage, baoji})
--         if self.m_bIsShowHpEffect == false then
--             self:HpChangeEffect()
--         end
--     end
-- end

function BattleHeadNode:InitTouchEvt()
end

function BattleHeadNode:SetOpacity(opt)
    local isShow = Utils:ToBool(opt)
    self.m_HpBar:setVisible(isShow)
    self.m_HpBarBg:setVisible(isShow)
end

return BattleHeadNode