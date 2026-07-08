local BattleBossHpNode = LUIBase:New()
BattleBossHpNode.__index = BattleBossHpNode

local buffer = {
    "res/UI/ui_juese/ui_xuetiao_boss_03.png",
    "res/UI/ui_juese/ui_xuetiao_boss_04.png",
    "res/UI/ui_juese/ui_xuetiao_boss_01.png",
    "res/UI/ui_juese/ui_xuetiao_boss_02.png",
}
function BattleBossHpNode:New(pHead)
    if pHead == nil then
        return nil
    end
	local o = {}
	setmetatable(o, BattleBossHpNode)
	o:Init(pHead)
	return o
end

function BattleBossHpNode:Init(pHead)
    self.m_pUILayer = pHead
    ----------------------------------
	self:RegistMsgs()
    self:InitUIControl()
    self:setCloseCallback()
end
function BattleBossHpNode:onExit()
    self:Destory()
    if self.m_pBloodProgress then
        self.m_pBloodProgress:release()
        self.m_pBloodProgress = nil
    end
    if self.m_pBloodProgressBg then
        self.m_pBloodProgressBg:release()
        self.m_pBloodProgressBg = nil
    end
    self.m_pBloodText = nil
    self.m_pBossHeadImage = nil
    self.m_pBossNameText = nil
    self.m_pUILayer = nil
    Utils:FreeTable(self.m_pBossData)
    self.m_pBossData = nil
end
-------------------------------------
function BattleBossHpNode:RegistMsgs()
    self.msgIds = {
        LUIBattleEvent.UpdateFightHP,
        LUIBattleEvent.ShowFightHP,
        LUILogicEvent.ExitBattle,
    }
    self:RegistSelf(self, self.msgIds)
end

function BattleBossHpNode:InitUIControl()
    local pHead = self.m_pUILayer
    self.m_pBossHeadImage = pHead:getChildByName("Icon")
    self.m_pBossNameText = pHead:getChildByName("bg_VIP"):getChildByName("Value")
    local pBloodBg = pHead:getChildByName("bg_blood"):getChildByName("Bg")
    
    local function createLoadingBar(pSp)
        if pSp == nil then
            return nil
        end
        local spTemp = cc.Sprite:createWithSpriteFrameName(buffer[1])
        spTemp:setName(pSp:getName())
        local progressBar = cc.ProgressTimer:create(spTemp)
        progressBar:retain()
        progressBar:setType(cc.PROGRESS_TIMER_TYPE_BAR)
        progressBar:setAnchorPoint(pSp:getAnchorPoint())
        progressBar:setPosition(cc.p(pSp:getPosition()))
        progressBar:setScale(pSp:getScaleX(), pSp:getScaleY())
        progressBar:setMidpoint(cc.p(0, 0))
        progressBar:setBarChangeRate(cc.p(1, 0))
        progressBar:setPercentage(0)
        pSp:getParent():addChild(progressBar)
        pSp:removeFromParent()
        return progressBar
    end

    self.m_pBloodProgress = createLoadingBar(pBloodBg:getChildByName("LoadingBar_1"))
    if self.m_pBloodProgress then
        self.m_pBloodProgress:setName('self.m_pBloodProgress')
        self.m_pBloodProgress:setVisible(true)
        self.m_pBloodProgress:setLocalZOrder(1)
    end

    self.m_pBloodProgressBg = createLoadingBar(pBloodBg:getChildByName("LoadingBar_2"))
    if self.m_pBloodProgressBg then
        self.m_pBloodProgressBg:setName('self.m_pBloodProgressBg')
        self.m_pBloodProgressBg:setPercentage(100)
        self.m_pBloodProgressBg:setVisible(true)
    end

    self.m_pBloodText = pBloodBg:getChildByName("Text")
    self.m_pBloodText:setLocalZOrder(2)
end

function BattleBossHpNode:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

function BattleBossHpNode:ProcessEvent(msg)
	if msg.msgId == LUIBattleEvent.UpdateFightHP then
        self:DealUpdateFightHP(msg.value)
    elseif msg.msgId == LUIBattleEvent.ShowFightHP then
        self:DealInitHPLayer(msg.value)
    elseif msg.msgId == LUILogicEvent.ExitBattle then
        self.m_bloodLevel = nil
        Utils:FreeTable(self.m_animQueue)
        self.m_animQueue = nil
        if self.m_pUILayer ~= nil then
            self.m_pUILayer:setVisible(false)
        end
    end
end

function BattleBossHpNode:UpdateHPText(cur, max)
    -- dump({cur, max}, "UpdateHPText-->")
    if self.m_pBloodText then
        self.m_pBloodText:setString(string.format("%d/%d", cur, max))
    end
end

function BattleBossHpNode:DealInitHPLayer(data)
    if data == nil then
        return
    end
    
    if self.m_pBossHeadImage then
        Utils:ShowPetHeadImg(self.m_pBossHeadImage, string.format('%dkf', data.m_id))
        if self.m_pBossHeadImage:getParent() ~= nil then
            self.m_pBossHeadImage:getParent():setVisible(true)
        end
    end
    local _ = self.m_pBossNameText and self.m_pBossNameText:setString(data.m_name or '')

    self.m_pBossData = self.m_pBossData or {}
    self.m_pBossData.m_maxHp = data.m_maxHp or 1
    self.m_pBossData.m_fullHp = self.m_pBossData.m_maxHp/(#buffer)
    
    self:DealUpdateFightHP({hp=data.m_curHp})
end

function BattleBossHpNode:DealUpdateFightHP(msg)
    if msg == nil or msg.hp == nil or self.m_pBossData == nil then
        return
    end
    local cur = msg.hp

    self:DealHPAnim(cur)

    -- dump({msg, self.m_pBossData}, "DealUpdateFightHP---->")
    self:UpdateHPText(cur, self.m_pBossData.m_maxHp)
end

function BattleBossHpNode:GetHPLevel(hp)
    local max = self.m_pBossData.m_maxHp
    return math.min(math.floor(hp/max*#buffer)+1, #buffer)
end

function BattleBossHpNode:DealHPAnim(newHP)
    self.m_animQueue = self.m_animQueue or {}
    for i=1,#self.m_animQueue do
        local data = self.m_animQueue[i]
        if data then
            if math.abs(data.Hp - newHP) < 0.1 then
                table.remove(self.m_animQueue, i)
                break
            end
        end
    end
    local function _getRatio(hp, level, full)
        return (hp-(level-1)*full)*100/full
    end
    
    local full = self.m_pBossData.m_fullHp
    
    local data = {}
    data.Hp = newHP
    data.level = self:GetHPLevel(data.Hp)
    data.ratio = _getRatio(data.Hp, data.level, full)

    if #self.m_animQueue >= 1 then
        local preData = self.m_animQueue[#self.m_animQueue]
        if preData.level > data.level then
            if preData.ratio ~= 0 then
                local info = {}
                info.Hp = full*(preData.level-1)
                info.ratio = 0
                info.level = preData.level
                table.insert(self.m_animQueue, info)
            end

            local info = {}
            info.Hp = full*(preData.level-1)
            info.ratio = 100
            info.level = preData.level - 1
            info.gotoBrage = true
            table.insert(self.m_animQueue, info)
        elseif preData.level < data.level then
            if preData.ratio ~= 100 then
                local info = {}
                info.Hp = full*preData.level
                info.ratio = 100
                info.level = preData.level
                table.insert(self.m_animQueue, info)
            end

            local info = {}
            info.Hp = full*preData.level
            info.ratio = 0
            info.level = preData.level + 1
            info.gotoBrage = true
            table.insert(self.m_animQueue, info)
        end
    end
    table.insert(self.m_animQueue, data)

    if #self.m_animQueue > 1 then
        self:ShowNextAnim()
    elseif #self.m_animQueue == 1 then
        self:ChangeHpSprite(data.level, data.Hp)
    end
end

function BattleBossHpNode:ShowNextAnim()
    if self.m_pBloodProgress == nil or #self.m_animQueue < 2 then
        return
    end
    if self.m_pBloodProgress:getNumberOfRunningActions() > 0 then
        self.m_pBloodProgress:stopAllActions()
    end
    local first = self.m_animQueue[1]
    local second = self.m_animQueue[2]
    if second.gotoBrage then
        self:ChangeHpSprite(second.level)
        self.m_pBloodProgress:setPercentage(second.ratio)
        table.remove(self.m_animQueue, 1)
        return
    end

    local ratio = first.ratio or 0
    self.m_pBloodProgress:setPercentage(ratio)
    self:ChangeHpSprite(first.level)

    ratio = second.ratio or 0
    local arr = {}
    table.insert(arr, cc.EaseOut:create(cc.ProgressTo:create(0.1, ratio), 2))
    local seq = cc.Sequence:create(arr)
    self.m_pBloodProgress:runAction(seq)
    table.remove(self.m_animQueue, 1)
end

function BattleBossHpNode:ChangeHpSprite(level, cur)
    if level == nil then
        return
    end
    
    local curLevel = level
    -- dump({self.m_bloodLevel, curLevel}, "ChangeHpSprite-->")
    if self.m_bloodLevel == nil or self.m_bloodLevel ~= curLevel then
        if self.m_pBloodProgress and buffer[curLevel] then
            -- local pSp = self.m_pBloodProgress:getSprite()
            -- local _ = pSp and pSp:setSpriteFrame(buffer[curLevel])
            self.m_pBloodProgress:setSprite(cc.Sprite:createWithSpriteFrameName(buffer[curLevel]))
        end
        if self.m_pBloodProgressBg then
            if curLevel > 1 and buffer[curLevel-1] then
                -- local pSp = self.m_pBloodProgressBg:getSprite()
                -- local _ = pSp and pSp:setSpriteFrame(buffer[curLevel-1])
                --TODO:不知道为啥设置图片不成功，换成切换精灵的方式来做
                self.m_pBloodProgressBg:setSprite(cc.Sprite:createWithSpriteFrameName(buffer[curLevel-1]))
                self.m_pBloodProgressBg:setVisible(true)
            else
                self.m_pBloodProgressBg:setVisible(false)
            end
        end
    end

    if self.m_bloodLevel == nil and self.m_pBloodProgress and cur then
        local full = self.m_pBossData.m_fullHp
        local curLevelBlood = cur - (level-1)*full
        self.m_pBloodProgress:setPercentage(curLevelBlood*100/full)
    end
    
    self.m_bloodLevel = curLevel
end

return BattleBossHpNode