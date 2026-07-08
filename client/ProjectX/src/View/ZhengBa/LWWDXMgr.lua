LWWDXMgr = LUIBase:New()
LWWDXMgr.__index = LWWDXMgr

LWWDXMgr.betEventType = 
{
    MSI_NORMAL = 0,             --默认值
    MSI_QUERY = 1,              --查询
    MSI_BET = 2,               --下注
}


function LWWDXMgr:Awake()
	self.msgIds = 
	{
		LUILogicEvent.ExitBattle,
	}
	self:RegistSelf(self,self.msgIds)
	self.m_IsAfterBattle = false --战斗结束打开预赛界面
	self.mGroupData = {} --预赛数据
    self.mFinalData = {} --预赛数据
    self.m_isCurLastMatch = false
    self.m_isHasLastMatchData = false
    self.m_nodeEvent = LWWDXMgr.betEventType.MSI_NORMAL
    self._strBattleGetScore = ""
    self.m_curBattleData = {}
    self.m_isNotNeedChangeMyPos = false
    self.m_enterBattle = false
    self.m_curBattleIndex = 0
    self.m_isNoBaoMing = false
    self.m_curCountDownTag = 0
    self.m_needRefrashCountDown = true
end

--争霸解析
function LWWDXMgr:DealWeiWoDuXianFinal(op, stream)
    -- body
    --type 0上半场 1下半场 2总决赛

    if op == 28 then
        self.m_isCurLastMatch = true
    else
        self.m_isCurLastMatch = false
    end

    local type = stream:ReadByte()
--    print("DealWeiWoDuXianFinal type = ", type)
    if type == 0 then
        self:DealFirstHalf(type, stream)
    elseif type  == 1 then
        self:DealFirstHalf(type, stream)
    elseif type == 2 then
        self:FinalHalf(type, stream)
    end
end

function LWWDXMgr:initIsHasLastMatchData(playerData)
    for i=1, #playerData do
        if playerData[i].id > 0 then
            self.m_isHasLastMatchData = true
            return
        end
    end
    self.m_isHasLastMatchData = false
end 

--上半场 下半场
function LWWDXMgr:DealFirstHalf(type, stream)
    -- body
--    print("type =", type)
    local matchData = {}
    matchData.type = type
    matchData.curntRoundIdx = stream:ReadByte()
    self.m_curBattleIndex = matchData.curntRoundIdx
--    print("self.m_curBattleIndex --------", self.m_curBattleIndex)
    --选手信息
    matchData.player = {}
    local roleNum = stream:ReadByte()
    for i=1, roleNum do
        local data = MatchData:New()
        data.id = stream:ReadInt()
        data.name = stream:ReadString()
        table.insert(matchData.player, data)
    end

    matchData.round1 = {}
    --第一轮状态
    local roundNum1 = stream:ReadByte()
    for i=1, roundNum1 do
        local data1 = MatchData:New()
        data1.state = stream:ReadByte()
        data1.id = stream:ReadInt()
        table.insert(matchData.round1, data1)
    end

    matchData.round2 = {}
    --第二轮状态
    local roundNum2 = stream:ReadByte()
    for i=1, roundNum2 do
        local data2 = MatchData:New()
        data2.state = stream:ReadByte()
        data2.id = stream:ReadInt()
        table.insert(matchData.round2, data2)
    end

    matchData.round3 = {}
    --第三轮状态
    local roundNum3 = stream:ReadByte()
    for i=1, roundNum3 do
        local data3 = MatchData:New()
        data3.state = stream:ReadByte()
        data3.id = stream:ReadInt()
        table.insert(matchData.round3, data3)
    end

    matchData.round4 = {}
    local finalType = stream:ReadByte()
    local FinalData = {}
    FinalData.finalType = finalType
    if finalType == 1 then
        --冠军还未产生
        FinalData.state = stream:ReadByte();
        FinalData.id = stream:ReadInt();
    else
        --产生冠军
        FinalData.state = 1
        FinalData.id= stream:ReadInt();
--        print("FinalData.id ----", FinalData.id)
        FinalData.name = stream:ReadString();
--        print("FinalData name ----", FinalData.name)
        FinalData.prof = stream:ReadByte()
        FinalData.sex = stream:ReadByte()
        FinalData.level = stream:ReadWord()

    end
    table.insert(matchData.round4, FinalData)

--    dump(matchData, "match data -----------")

--只用上半场的数据计算是否有上届数据
    if type == 0 then
        self:initIsHasLastMatchData(matchData.player)
        self.mFinalData = matchData
    end

    if self.m_isCurLastMatch and not self.m_isHasLastMatchData then
        Utils:ShowScrollTips(GUITips.RIS_LEFTUI_MSG178)
    else
        if not self.m_isNotNeedChangeMyPos then
            if self:isInCurType(matchData.player) then
                self.m_isNoBaoMing = false
                if self:isAfterHalfFinal() then
                    --如果半决赛结束,则显示界面界面
                    LuaNetSendMsg:QueryWWDXFinalInfo(2, not self.m_isCurLastMatch)
                else
                    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "ZhengBa.PreliminnaryUI", AppDef.UIType.Chat)
                    LUIManager:SendMsg(LGameMsg.m_initUIMsg)
                    Utils:SendMsg(LUIWeiWoDuXianEvent.WWDXUIEvent, matchData)
                    self.m_isNotNeedChangeMyPos = false
                end
            else
                if not self:isAfterHalfFinal() then
                    if type == 0 then
                        LuaNetSendMsg:QueryWWDXFinalInfo(1, not self.m_isCurLastMatch)
                    elseif type == 1 then
                        LuaNetSendMsg:QueryWWDXFinalInfo(2, not self.m_isCurLastMatch)
                        self.m_isNoBaoMing = true
                    end
                else
                    LuaNetSendMsg:QueryWWDXFinalInfo(2, not self.m_isCurLastMatch)
                end
            end
        else
            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "ZhengBa.PreliminnaryUI", AppDef.UIType.Chat)
            LUIManager:SendMsg(LGameMsg.m_initUIMsg)
            Utils:SendMsg(LUIWeiWoDuXianEvent.WWDXUIEvent, matchData)
            self.m_isNotNeedChangeMyPos = false
        end
    end

end

--决赛
function LWWDXMgr:FinalHalf(type, stream)
    -- body
    local matchData = {}
    matchData.type = type
    matchData.name1 = ""
    matchData.sex1 = 0
    matchData.vip1 = 0
    matchData.zhandouli1 = 0
    matchData.roleId1 = stream:ReadInt()
    if matchData.roleId1 > 0 then
        matchData.name1 = stream:ReadString()
        matchData.prof1 = stream:ReadByte()
        matchData.sex1 = stream:ReadByte()
        matchData.level1 = stream:ReadWord()
        matchData.vip1 = stream:ReadUInt()
        matchData.zhandouli1 = stream:ReadUInt()

    end
    matchData.name2 = ""
    matchData.sex2 = 0
    matchData.vip2 = 0
    matchData.zhandouli2 = 0
    matchData.roleId2 = stream:ReadInt()
    if matchData.roleId2 > 0 then
        matchData.name2 = stream:ReadString()
        matchData.prof2 = stream:ReadByte()
        matchData.sex2 = stream:ReadByte()
        matchData.level2 = stream:ReadWord()
        matchData.vip2 = stream:ReadUInt()
        matchData.zhandouli2 = stream:ReadUInt()
    end

    matchData.state = stream:ReadByte()

    matchData.winer = stream:ReadUInt()
    self._winnerData = {}
    self._winnerData.winer = matchData.winer
    self._winnerData.roleId1 = matchData.roleId1
    self._winnerData.roleId2 = matchData.roleId2
--    dump(matchData, "FinalHalf data")
    
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "ZhengBa.PreliminnaryUI", AppDef.UIType.Chat)
    LUIManager:SendMsg(LGameMsg.m_initUIMsg)

    if not self.m_isNotNeedChangeMyPos then
        if self:isAfterHalfFinal() then
            Utils:SendMsg(LUIWeiWoDuXianEvent.WWDXFinalDataEvent, matchData)
        else
            Utils:SendMsg(LUIWeiWoDuXianEvent.WWDXUIEvent, self.mFinalData)
        end
    else
        Utils:SendMsg(LUIWeiWoDuXianEvent.WWDXFinalDataEvent, matchData)
    end

    self.m_isNotNeedChangeMyPos = false
end

function LWWDXMgr:loadCurBattleData(data)
    -- body
    self.m_curBattleData = data
    self.m_curBattleData.IntoBattle = true
end

function LWWDXMgr:isInCurType( list )
    -- body
    local myRoleId = LRoleDataMgr.MyHeroInfo.id
    for i=1, #list do
        if list[i].id == myRoleId then
            return true
        end
    end
    return false
end

function LWWDXMgr:inInFinalBattle(role1, role2)
    -- body
    local myRoleId = LRoleDataMgr.MyHeroInfo.id
    return myRoleId == role1 or myRoleId == role2
end

function LWWDXMgr:isInWWDXBattle()
    -- body
    return Utils:ToBool(self.m_curBattleData.IntoBattle)
end

function LWWDXMgr:loadAfterBattleData( suc )
    -- body
    if suc then
        self._strBattleGetScore = string.format(GUITips.RSI_CROSSSERVER_TIPS_9, self.m_curBattleData.mid)
    else
        self._strBattleGetScore = string.format(GUITips.RSI_CROSSSERVER_TIPS_10, self.m_curBattleData.failScore)
    end

end

function LWWDXMgr:ProcessEvent(msg)
	local msgId = msg:GetMsgId()
    if msgId == LUILogicEvent.ExitBattle then
        if self.m_IsAfterBattle == true then
            --战斗结束再显示
            Utils:ShowScrollTips(self._strBattleGetScore)
        	LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "ZhengBa.TianYuanZhengBa", AppDef.UIType.Chat)
            LUIManager:SendMsg(LGameMsg.m_initUIMsg)

            Utils:SendMsg(LUIWeiWoDuXianEvent.UpdateWWDXPreUIEvent, self.mGroupData)

            self.m_IsAfterBattle = false
            self.m_curBattleData.IntoBattle = false
        end
    end
end

function LWWDXMgr:isAfterHalfFinal()
    -- body
    return self.m_curBattleIndex >= 4
end

function LWWDXMgr:isbeginFinal()
    -- body
    return self.m_curBattleIndex >= 5
end

function LWWDXMgr:isHasWinner( ... )
    -- body
    if self._winnerData == nil then
        return false
    end
    local isWined = (self._winnerData.winer == self._winnerData.roleId1 or self._winnerData.winer == self._winnerData.roleId2)
    print("isHasWinner ----", isWined)
    return isWined
end

function LWWDXMgr:isAfterFinal( ... )
    -- body
    local isAfterMatch = (self:isbeginFinal() and self:isHasWinner())
--    print("isAfterFinal ==", isAfterMatch)
    return isAfterMatch
end


--获取到天元争霸决赛剩余时间
function LWWDXMgr:getWWDXFinalLastTime(toWeek, sHour,  sMin)
    -- body
    local sYear = tonumber(os.date("%Y", LDataConstMgr.m_serverTime))
    local sMonth = tonumber(os.date("%m", LDataConstMgr.m_serverTime))
    local SDay = tonumber(os.date("%d", LDataConstMgr.m_serverTime))
    local sWeek = tonumber(os.date("%w", LDataConstMgr.m_serverTime))
--    print("SYear", sYear, sMonth, SDay, sWeek, LDataConstMgr.m_serverTime)
    if sWeek == 0 then
        sWeek = 7
    end
    local spaceDay = toWeek - sWeek

    local finalTime = os.time({year = sYear, month = sMonth, day = SDay + spaceDay , hour = sHour, min = sMin - 1, sec = 59})

    local lero_time = finalTime - LDataConstMgr.m_serverTime
    return lero_time

end

--天元争霸总决赛获结束到天元争霸预赛开始的时间
function LWWDXMgr:getWWDXYusaiNextTime()
    -- body
    local sYear = tonumber(os.date("%Y", LDataConstMgr.m_serverTime))
    local sMonth = tonumber(os.date("%m", LDataConstMgr.m_serverTime))
    local SDay = tonumber(os.date("%d", LDataConstMgr.m_serverTime))
    local sWeek = tonumber(os.date("%w", LDataConstMgr.m_serverTime))
    if sWeek == 0 then
        sWeek = 7
    end
    --预赛下周一0点开始
    local spaceDay = (1 + 7) - sWeek
    local finalTime = os.time({year = sYear, month = sMonth, day = SDay + spaceDay , hour = 23, min = 59, sec = 59})

    local lero_time = finalTime - LDataConstMgr.m_serverTime

    return lero_time

end

function LWWDXMgr:getWWDXCountDownTime( ... )
    -- body
    --1 决赛开始倒计时  2第一轮开始倒计时 3 第二轮开始倒计时 4 第三轮开始倒计时 5 半决赛开始倒计时 6 总决赛开始倒计时   7 总决赛结束 8预赛开始
    local beginFinalTime = self:getWWDXFinalLastTime(6, 23, 60)
    local firstCountTime = self:getWWDXFinalLastTime(7, 20, 30)
    local secondCountTime = self:getWWDXFinalLastTime(7, 20, 45)
    local thirdCountTime = self:getWWDXFinalLastTime(7, 20, 60)
    local fourCountTime = self:getWWDXFinalLastTime(7, 21, 15)
    local fiveCountTime = self:getWWDXFinalLastTime(7, 21, 30)
    local finalCountTimeEnd = self:getWWDXFinalLastTime(7, 21, 45)

--    print("firstCountTime =", firstCountTime, secondCountTime, thirdCountTime, fourCountTime, fiveCountTime, finalCountTimeEnd)
    
    if beginFinalTime > 0 then
        return 1, beginFinalTime
    end
    
    if beginFinalTime < 1 and firstCountTime > 0 then
        return 2, firstCountTime
    end

    if firstCountTime < 1 and secondCountTime > 0 then
        return 3, secondCountTime
    end

    if secondCountTime < 1 and thirdCountTime > 0 then
        return 4, thirdCountTime
    end

    if thirdCountTime < 1 and fourCountTime > 0 then
        return 5, fourCountTime
    end

    if fourCountTime < 1 and fiveCountTime > 0 then
        return 6, fiveCountTime
    end

    if fiveCountTime < 1 and finalCountTimeEnd > 0 then
        return 7, finalCountTimeEnd
    end

    if finalCountTimeEnd < 1 then
        return 8, self:getWWDXYusaiNextTime()
    end

end

function LWWDXMgr:getWWDXCountDownStr()
    -- body
    --1 决赛开始倒计时 2 第二轮开始倒计时 3 第三轮开始倒计时 4 半决赛开始倒计时 5 总决赛开始倒计时  6 总决赛开始倒计时   7 总决赛结束 8预赛开始
    if self.m_curCountDownTag == 1 then
        return self.m_curCountDownTag, GUITips.RSI_CROSSSERVER_TIPS_16
    elseif self.m_curCountDownTag == 2 then
        return self.m_curCountDownTag, GUITips.RSI_CROSSSERVER_TIPS_17
    elseif self.m_curCountDownTag == 3 then
        return self.m_curCountDownTag, GUITips.RSI_CROSSSERVER_TIPS_18
    elseif self.m_curCountDownTag == 4 then
        return self.m_curCountDownTag, GUITips.RSI_CROSSSERVER_TIPS_19
    elseif self.m_curCountDownTag == 5 then
        return self.m_curCountDownTag, GUITips.RSI_CROSSSERVER_TIPS_20
    elseif self.m_curCountDownTag == 6 then
        return self.m_curCountDownTag, GUITips.RSI_CROSSSERVER_TIPS_21
    elseif self.m_curCountDownTag == 7 then
        return self.m_curCountDownTag, GUITips.RSI_CROSSSERVER_TIPS_22
    elseif self.m_curCountDownTag == 8 then
        return self.m_curCountDownTag, GUITips.RSI_CROSSSERVER_TIPS_15
    end
    return 1, "%02d:%02d:%02d"
end

function LWWDXMgr:beginCountDown(isAfterfrash)
    -- body
    if Utils:CheckModelNotOpened(AppDef.EActivityID.EAID_WEIWODUXIAN, true) then
        return
    end
    if self.m_needRefrashCountDown then
        Utils:SendMsg(LUIWeiWoDuXianEvent.WWDXUpdateCound)
        if isAfterfrash~= nil and isAfterfrash then
            self.m_needRefrashCountDown = false
        end
    end
end

function LWWDXMgr:Free()

end


return LWWDXMgr:Awake()


