local KunlunShanUI = LUIBase:New()
KunlunShanUI.__index = KunlunShanUI
KunlunShanUI.IsHideInBattle = true
function KunlunShanUI:New()
    local o = {}
    setmetatable(o,KunlunShanUI)  
    o:Init()
    return o
end

--[[
注册UI消息
]]
function KunlunShanUI:RegistMsgs()
    self.msgIds = 
    {
        LUIActivityEvent.RefreshKunlunRank,
        LUIActivityEvent.RefreshKunlunInfo,
    }
    self:RegistSelf(self,self.msgIds)
end

function KunlunShanUI:ProcessEvent(msg)
    if msg.msgId == LUIActivityEvent.RefreshKunlunRank then
        self:UpdateRank()
    elseif msg.msgId == LUIActivityEvent.RefreshKunlunInfo then
        self:UpdateInfo(msg.value)
    end
end

function KunlunShanUI:Init()
    self:RegistMsgs()
    self.m_pUILayer = cc.CSLoader:createNode("csd/kunlunshanLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitData()
    self:AddTouchEvt()
    self:UpdateTimer()
    LuaNetSendMsg:QueryKunLunShanInfo()
    self:UpdateScore()
    self:UpdateQuest()
end

function KunlunShanUI:onExit()
    self:Destory()
    AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_schedulerID)
    self.m_schedulerID = nil
end

function KunlunShanUI:InitData()
    self.m_panelUI = self.m_pUILayer:getChildByName("kunlunshanUI")
    self.m_panelTop = self.m_panelUI:getChildByName("Panel_Top")
    self.m_panelQR = self.m_panelUI:getChildByName("Panel_QuestAndRanking")
    
    --顶部信息
    self.m_score = self.m_panelTop:getChildByName("Point"):getChildByName("Value")
    self.m_timeBg = self.m_panelTop:getChildByName("Time")
    self.m_timePercent = self.m_timeBg:getChildByName("LoadingBar")
    self.m_timeSec = self.m_timeBg:getChildByName("Value")

    -- 右侧信息
    -- 任务按钮
    self.m_questBtn = self.m_panelQR:getChildByName("CheckBox_Quest")
    -- 排名按钮
    self.m_rankBtn = self.m_panelQR:getChildByName("CheckBox_Ranking")
    -- 隐藏与显示
    self.m_visibleBtn = self.m_panelUI:getChildByName("btn_Locker")
    self.m_visibleImg = self.m_visibleBtn:getChildByName("Arrows")
    -- 任务背板
    self.m_questBg = self.m_panelQR:getChildByName("Panel_Quest")
    -- 排行背板
    self.m_rankBg = self.m_panelQR:getChildByName("Panel_Ranking")
    self.m_rankBg:setVisible(false)
	--帮助按钮
	
	local pHelpBtn = self.m_panelQR:getChildByName("btn_Help")
	self.m_rankBg:setVisible(true)
    pHelpBtn:addClickEventListener(function(sender)
        self:helpButtonCallback()
    end)
	self:MarkIntaractCObj(pHelpBtn)
    -- 杀敌
    self.m_shadiQuest = self.m_questBg:getChildByName("shadi")
    self.m_shadiName  = self.m_shadiQuest:getChildByName("Title")
    self.m_shadiTarget = self.m_shadiQuest:getChildByName("Target"):getChildByName("Target")
    self.m_shadiewardBg = self.m_shadiQuest:getChildByName("Reward")
    self.m_shadiReward1 = self.m_shadiewardBg:getChildByName("Reward1")
    self.m_shadiReward2 = self.m_shadiewardBg:getChildByName("Reward2")
    self.m_shadiFinish = self.m_shadiQuest:getChildByName("Finish")
    self.m_shadiFinish:setVisible(false)
    -- self.m_shadiColorReward1 = Utils:CreateColorText(self.m_shadiewardBg, self.m_shadiReward1, "NewReward1")
    -- self.m_shadiColorReward1 = Utils:CreateColorText(self.m_shadiewardBg, self.m_shadiReward2, "NewReward2")

    -- 杀怪
    self.m_shaguaiQuest = self.m_questBg:getChildByName("shaguai")
    self.m_shaguaiName  = self.m_shaguaiQuest:getChildByName("Title")
    self.m_shaguaiTarget = self.m_shaguaiQuest:getChildByName("Target"):getChildByName("Target")
    self.m_shaguaiRewardBg = self.m_shaguaiQuest:getChildByName("Reward")
    self.m_shaguaiReward1 = self.m_shaguaiRewardBg:getChildByName("Reward1")
    self.m_shaguaiReward2 = self.m_shaguaiRewardBg:getChildByName("Reward2")
    self.m_shaguaiFinish = self.m_shaguaiQuest:getChildByName("Finish")
    self.m_shaguaiFinish:setVisible(false)

    -- self.m_shaguaiColorTarget = Utils:CreateColorText(self.m_shaguaiRewardBg, self.m_shaguaiTarget, "NewReward1")
    -- self.m_shaguaiColorReward1 = Utils:CreateColorText(self.m_shaguaiRewardBg, self.m_shaguaiReward1, "NewReward1")
    -- self.m_shaguaiColorReward1 = Utils:CreateColorText(self.m_shaguaiRewardBg, self.m_shaguaiReward2, "NewReward2")

    -- 排行榜
    self.m_rankList = self.m_rankBg:getChildByName("ListView")
    self.m_rankCell = self.m_rankBg:getChildByName("Item")
    self.m_isOnQueryRank = false

    self.m_isShow = true
    local size = self.m_panelQR:getContentSize()
    self.m_pShowPos = cc.p(self.m_panelQR:getPosition())
    self.m_pHidePos = cc.p(self.m_pShowPos.x + size.width, self.m_pShowPos.y)

    self:selectQuest()
end

function KunlunShanUI:helpButtonCallback()

    str = string.format("%s%s%s%s%s%s", GUITips.RSI_HSD_TIP125, GUITips.RSI_HSD_TIP126, GUITips.RSI_HSD_TIP127, GUITips.RSI_HSD_TIP128, GUITips.RSI_HSD_TIP129, GUITips.RSI_HSD_TIP130) 

    local function OKCallback()
    end
    local msgData = {
        okCallback = OKCallback,
        desc = str
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIMsgBoxEvent.ShowMsgBox, msgData)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end


function KunlunShanUI:AddTouchEvt()
    -- 选择任务
    local function QuestCallback(pSender, inputType)
        self:selectQuest()
    end
    self.m_questBtn:addEventListener(QuestCallback)

    -- 选择排名
    local function RankCallback(pSender, inputType)
        self.m_questBtn:setSelected(false)
        self.m_questBg:setVisible(false)
        self.m_rankBtn:setSelected(true)
        self.m_rankBg:setVisible(true)
        self.m_isOnQueryRank = true
        self:RankTimer()
    end
    self.m_rankBtn:addEventListener(RankCallback)

    -- 选择排名
    local function VisibleCallback(pSender, inputType)
        self:Show()
    end
    self.m_visibleBtn:addClickEventListener(VisibleCallback)
	self:MarkIntaractCObj(self.m_visibleBtn)
end

function KunlunShanUI:selectQuest( ... )
    -- body
    self.m_questBtn:setSelected(true)
    self.m_questBg:setVisible(true)
    self.m_rankBtn:setSelected(false)
    self.m_rankBg:setVisible(false)
    self:UpdateQuest()
    self.m_isOnQueryRank = false
    self.m_rankBg:stopAllActions()
end

--[[
更新任务信息
]]
function KunlunShanUI:UpdateQuest()
    local data = LRoleDataMgr.m_kunlunShanData
    local kRole = data.killRoleTask
    for k,rTask in pairs(kRole) do
        if not rTask.isComplete or k == #kRole then
            self.m_shadiName:setString(string.format(GUITips.Rei_Quest_Kuohao, rTask.taskName))
            local curNum = data.m_killRoleNum
            if data.m_killRoleNum > rTask.killNum then
                curNum = rTask.killNum
            end
            self.m_shadiTarget:setString(string.format("%s(%d/%d)", rTask.targetDesc, curNum, rTask.killNum))
            self.m_shadiReward1:setString(rTask.award1)
            self.m_shadiReward2:setString(rTask.award2)
            self.m_shadiFinish:setVisible(rTask.isComplete)
            break
        end
    end

    local kMonster = data.killMonsterTask
    for k,mTask in pairs(kMonster) do
        if not mTask.isComplete or k == #kMonster then
            self.m_shaguaiName:setString(string.format(GUITips.Rei_Quest_Kuohao, mTask.taskName))
            local curNum = data.m_killMonsterNum
            if curNum > mTask.killNum then
                curNum = mTask.killNum
            end
            self.m_shaguaiTarget:setString(string.format("%s(%d/%d)", mTask.targetDesc, curNum, mTask.killNum))
            self.m_shaguaiReward1:setString(mTask.award1)
            self.m_shaguaiReward2:setString(mTask.award2)
            self.m_shaguaiFinish:setVisible(mTask.isComplete)
            break
        end
    end
end

--[[
更新历练
]]
function KunlunShanUI:UpdateScore()
    self.m_score:setString(tostring(LRoleDataMgr.m_kunlunShanData.m_score))
end

--[[
更新排行信息
]]
function KunlunShanUI:UpdateRank()
    self.m_rankList:removeAllItems()
    local ranks = LRoleDataMgr.m_kunlunShanData.m_paiHangList
    for k,rank in pairs(ranks) do
        local cell = self.m_rankCell:clone()
        cell:getChildByName("Ranking"):setString(tostring(rank.rank))
        cell:getChildByName("Name"):setString(tostring(rank.name))
        cell:getChildByName("Point"):setString(tostring(rank.score))
        self.m_rankList:pushBackCustomItem(cell)
    end
end

--[[
定时更新排行信息
]]
function KunlunShanUI:RankTimer()
    local function queryRank()
        self:RankTimer()
    end

    if self.m_isOnQueryRank then
        LuaNetSendMsg:QueryKunLunShanPaiHang()
        self.m_rankBg:stopAllActions()
        local action = cc.Sequence:create(cc.DelayTime:create(5),cc.CallFunc:create(queryRank))
        self.m_rankBg:runAction(action)
    end
end

--[[
定时实时信息
]]
function KunlunShanUI:UpdateInfo(op)
    if op == 1 then
        self:UpdateScore()
    elseif op >= 2 and op <= 5 then
        self:UpdateScore()
        self:UpdateQuest()
    end
end

--[[
]]
function KunlunShanUI:UpdateTimer()
    local function TimerCallBack()
        local data = LRoleDataMgr.m_kunlunShanData
        if data.m_nextFlushScecond == 0 then
            return
        end
        data.m_nextFlushScecond = data.m_nextFlushScecond -1
        local min = data.m_nextFlushScecond / 60
        local sec = data.m_nextFlushScecond % 60
        local str = string.format("%02d:%02d", min, sec)
        self.m_timeSec:setString(str)
        self.m_timePercent:setPercent(data.m_nextFlushScecond * 100 / data.m_timeSpace)
    end
    local scheduler =  AppDef.Director:getScheduler()
    self.m_schedulerID = scheduler:scheduleScriptFunc(TimerCallBack, 1, false)
end

function KunlunShanUI:Show()
    if self.m_isShow then
        self.m_isShow = false
        local action = cc.MoveTo:create(0.3, self.m_pHidePos)
        self.m_panelQR:runAction(action)
        self.m_visibleImg:setRotation(270)
    else
        self.m_isShow = true
        local action = cc.MoveTo:create(0.3, self.m_pShowPos)
        self.m_panelQR:runAction(action);
        self.m_visibleImg:setRotation(90)
    end
end

return KunlunShanUI