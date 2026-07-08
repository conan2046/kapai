local AnswerUI = LUIBase:New()
AnswerUI.__index = AnswerUI

function AnswerUI:New()
    local o = LUIBase:New()
    setmetatable(o,AnswerUI)  
    o:Init()
    return o
end

--[[
注册UI消息
]]
function AnswerUI:RegistMsgs()
    self.msgIds = 
    {
        LUIActivityEvent.UpdateQuestion,
        LUIActivityEvent.UpdateAnswerInfo,
    }
    self:RegistSelf(self,self.msgIds)
end

function AnswerUI:ProcessEvent(msg)
    if msg.msgId == LUIActivityEvent.UpdateQuestion then
		if msg.value == false then
			Utils:DeleteUI("Activity.AnswerUI")
			return
		end
        self:ShowCurQuestion()
    elseif msg.msgId == LUIActivityEvent.UpdateAnswerInfo then
        self:UpdateAnswerInfo(true, msg.value)
    end
end

function AnswerUI:Init()
    self:RegistMsgs()
    self.m_pUILayer = cc.CSLoader:createNode("csd/dati/AnswerLayer.csb")
    local frameSize = AppDef.frameSize
    self.m_pUILayer:setContentSize(frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

	local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.AnswerUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
	LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.UI_Title_Answer)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    self:InitData()
    self:AddTouchEvt()
	self.m_pUILayer:setVisible(false)
	LuaNetSendMsg:QueryQuestion(1)
    --self:ShowCurQuestion()
	Utils:SendMsg(LUIFClassBgEvent.HelpBtn,AppDef.FCBHelp.DaTi)
end

function AnswerUI:onExit()
    self:Destory()
    self:StopTimer()
end

function AnswerUI:InitData()
    local bg = self.m_pUILayer:getChildByName("Panel"):getChildByName("AnswerBg")
    local rewardBg = bg:getChildByName("RewardBg")
    local subjectBg = bg:getChildByName("SubjectBg")

    -- 正确题目数
    self.m_pRightNum = rewardBg:getChildByName("RightBg"):getChildByName("Text")
    -- 答题时间
    self.m_pTimes = rewardBg:getChildByName("TimeBg"):getChildByName("Text")
    -- 剩余题目
    self.m_pSurplusNm = rewardBg:getChildByName("Bg1"):getChildByName("Value")
    rewardBg:getChildByName("Bg1"):getChildByName("Icon"):setVisible(false)
    -- 本题金币
    self.m_pCurReward = rewardBg:getChildByName("Bg2"):getChildByName("Value")
    -- 累计金币
    self.m_pRewardSum = rewardBg:getChildByName("Bg3"):getChildByName("Value")

    -- 当前题目数
    self.m_pCurQuestIdx = subjectBg:getChildByName("TitleBg"):getChildByName("Text")
    -- 题目内容
    self.m_pQuestTitle = subjectBg:getChildByName("Bg"):getChildByName("Text")
    self.m_pAnswerBtns = {}
    for i=1,4 do
        self.m_pAnswerBtns[i] = subjectBg:getChildByName("Button_"..i)
        self.m_pAnswerBtns[i]:setTag(i)
    end
    -- 答对了
    self.m_pRight = bg:getChildByName("RightText")
    -- 答错了
    self.m_pWrong = bg:getChildByName("WrongText")

--倒计时结束,不能再答题
    self._isAnserNoTime = false
end

function AnswerUI:AddTouchEvt()
    local function AnswerCallback(pSender, inputType)

        if self._isAnserNoTime then
            return
        end

        self.m_selectIdx = pSender:getTag()
        for i=1,4 do
            self.m_pAnswerBtns[i]:setTouchEnabled(false)
        end
        self:StopTimer()
        LuaNetSendMsg:AnswerQuestion(2, self.m_selectIdx)
    end
    for i=1,4 do
        self.m_pAnswerBtns[i]:addClickEventListener(AnswerCallback)
		self:MarkIntaractCObj(self.m_pAnswerBtns[i])
    end
end

--[[
显示问题信息
]]
function AnswerUI:ShowCurQuestion()
    local data = LRoleDataMgr.MyHeroInfo.m_pQuestion
	dump(data, "==========ShowCurQuestion===============>>>>>>>>>>>>>>>>>>>>>>>>>")
	self.m_pUILayer:setVisible(true)
    -- 答案
    local result = string.split(data.anwser, "|")
    for key,btn in pairs(self.m_pAnswerBtns) do
        if result[key] ~= nil then
            btn:setVisible(true)
            btn:setTitleText(GUITipsAnswer[key]..result[key])
            btn:setTouchEnabled(true)
        else
            btn:setVisible(false)
        end
    end
    -- 第几题
    self.m_pCurQuestIdx:setString(string.format(GUITips.UI_Title_Answer_Idx, data.idx))
    -- 题目内容
    self.m_pQuestTitle:setString(data.question)
    self.m_pWrong:setVisible(false)
    self.m_pRight:setVisible(false)

    self.second = 20
    self:UpdateAnswerInfo(false)
    -- 答题倒计时
    self:UpdateTimer()
end
-- 
--[[
答题记录跟新
]]
function AnswerUI:UpdateAnswerInfo(isAnswer, rightIdx)

    local data = LRoleDataMgr.MyHeroInfo.m_pQuestion
    -- 正确数
    if data.rightNum == nil then
        data.rightNum = 0
    end
    self.m_pRightNum:setString(string.format(GUITips.UI_Title_Answer_Rights, data.rightNum))
    -- 剩余题目
    self.m_pSurplusNm:setString(tostring(data.quenum))
    -- 本题金币
    self.m_pCurReward:setString(tostring(data.curReward))
    -- 累计金币
    self.m_pRewardSum:setString(tostring(data.reward))
    -- 剩余时间
    self.m_pTimes:setString(string.format(GUITips.UI_Title_Answer_Times, self.second))

    --重置答题倒计时结束标识
    if not isAnswer then
        self._isAnserNoTime = false
    end
    
    if not isAnswer then return end

    local function queryNextQuest()
        self.m_pRightBtn:getChildByName("RightImage"):setVisible(false)
        LuaNetSendMsg:QueryQuestion(1)
    end

    local function closeThisUI()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.AnswerUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end

    if rightIdx ~= nil then
        self.m_pRightBtn = self.m_pAnswerBtns[rightIdx]
        self.m_pWrong:setVisible(true)
    else
        self.m_pRightBtn = self.m_pAnswerBtns[self.m_selectIdx]
        self.m_pRight:setVisible(true)
    end
    self.m_pRightBtn:getChildByName("RightImage"):setVisible(true)

    self.m_selectIdx = nil
    local data = LRoleDataMgr.MyHeroInfo.m_pQuestion
    if data.quenum == 0 then
        local data = LRoleDataMgr.MyHeroInfo.m_pQuestion
        Utils:ShowScrollTips(string.format(GUITips.UI_Title_Answer_Sum, data.reward))
        Utils:DelayToCallFunc(self.m_pCurQuestIdx, 1, closeThisUI)
    else
        Utils:DelayToCallFunc(self.m_pCurQuestIdx, 1, queryNextQuest)
    end
end

--[[
倒计时
]]
function AnswerUI:UpdateTimer()
    local function TimerCallBack()
        if self.second > 0 then
            self.second = self.second - 1
            self.m_pTimes:setString(string.format(GUITips.UI_Title_Answer_Times, self.second))
        else
            self._isAnserNoTime = true
            self:StopTimer()
            LuaNetSendMsg:AnswerQuestion(2, 5)
        end
    end
    local scheduler =  AppDef.Director:getScheduler()
    self.m_schedulerID = scheduler:scheduleScriptFunc(TimerCallBack, 1, false)
end

--[[
倒计时停止
]]
function AnswerUI:StopTimer()
    if self.m_schedulerID ~= nil then
        AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_schedulerID)
        self.m_schedulerID = nil
    end
end

return AnswerUI
