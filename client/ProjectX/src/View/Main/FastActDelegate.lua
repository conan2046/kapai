local ObjectPool = require("Common.ObjectPool")
local TimerLabelUI = require("View.Common.TimerLabelUI")

local FastActDelegate = LUIBase:New()
FastActDelegate.__index = FastActDelegate

local GUITipsActivity = {
    [AppDef.EActivityID.EAID_FISH] = {{12,30}},
    [AppDef.EActivityID.EAID_LINGMO] = {{16,30}},
    [AppDef.EActivityID.EAID_KUNLUN] = {{20,30}},
    [AppDef.EActivityID.EAID_FLYFARY] = {{21,00}},
    [AppDef.EActivityID.EAID_LIUJIESHILIAN] = {{13,00},{15,00},{17,00}},
    [AppDef.EActivityID.EAID_BAIHUA] = {{19,30}},
    [AppDef.EActivityID.EAID_CONVOY] = {{12,00}},
    [AppDef.EActivityID.EAID_FACTIONROB] = {{20,00}},
    [AppDef.EActivityID.EAID_NIANSHOU] = {{14,00}},
    [AppDef.EActivityID.EAID_DOUBLEEXP] = {{22,30}},
    [AppDef.EActivityID.EAID_LEITAI] = {{20,00}},
    [AppDef.EActivityID.EAID_FACTION_WAR] = {{19,55}},
    [AppDef.EActivityID.EAID_SHENJIELUNDAO] = {{20,30}},
    [AppDef.EActivityID.EAID_SHENJIEMIJING] = {{11,30},{15,30},{19,00}},
    [AppDef.EActivityID.EAID_WEIWODUXIAN] = {{00,00}},
}

local GUICrossServerActivity = {
    [AppDef.EActivityID.EAID_SHENJIELUNDAO] = {{20,30}},
    [AppDef.EActivityID.EAID_SHENJIEMIJING] = {{11,30},{15,30},{19,00}},
    [AppDef.EActivityID.EAID_WEIWODUXIAN] = {{00,00}},
    [AppDef.EActivityID.EAID_FISH] = {{12,30}},
    [AppDef.EActivityID.EAID_BAIHUA] = {{19,30}},
    [AppDef.EActivityID.EAID_CONVOY] = {{12,00}},
    [AppDef.EActivityID.EAID_NIANSHOU] = {{14,00}},
    [AppDef.EActivityID.EAID_LIUJIESHILIAN] = {{13,00},{15,00},{17,00}},
}

function FastActDelegate:New(btn, wanfaBtn, btnGroup)
	if btn == nil or wanfaBtn == nil or btnGroup == nil then
		return nil
	end
	local o = {}
	setmetatable(o, FastActDelegate)
	o:Init(btn, wanfaBtn, btnGroup)
	return o
end

function FastActDelegate:Init(btn, wanfaBtn, btnGroup)
	self.m_pBtnModel = btn
	self.m_pBtnGroup = btnGroup
    if self.m_pBtnGroup then
        self.m_pBtnGroup:retain()
    end
	self.m_pWanfaBtn = wanfaBtn
    if self.m_pWanfaBtn then
        self.m_pWanfaBtn:retain()
    end
	self.m_pTimers = {}

	self.m_actBtnPool = ObjectPool:New(btn)
	btn:removeFromParent(false)

    self.m_data = {}

	self:RegistMsgs()
    self:InitViewSize()
    self:setCloseCallback()
    self:addWWDXIcon()
end
function FastActDelegate:onExit()
    self:Destory()
    self.m_pUILayer = nil
    if self.m_pTimers then
        for k,v in pairs(self.m_pTimers) do
            local _ = v and v:Destory()
            self.m_pTimers[k] = nil
        end
    end
    if self.m_pBtnGroup then
        self.m_pBtnGroup:release()
        self.m_pBtnGroup = nil
    end
    if self.m_pWanfaBtn then
        self.m_pWanfaBtn:release()
        self.m_pWanfaBtn = nil
    end
    if self.m_actBtnPool then
        self.m_actBtnPool:onExit()
        self.m_actBtnPool = nil
    end
    self.m_data = nil
    self._wwdxPTextBg = nil
    self._wwdxPText = nil
end
-------------------------------------
function FastActDelegate:RegistMsgs()
    self.msgIds = {
    	LUIMainEvent.FlushOpenActivity,
        LUIMainEvent.GetOpenActivity,
        LUIMiJingEvent.UpdateRedDotEvent,
        LUIMapEvent.ChangeMapSuccess,
        LUIRoleDataChangeEvent.LvUp,
        LUIWeiWoDuXianEvent.WWDXUpdateCound,
    }
    self:RegistSelf(self, self.msgIds)
end

function FastActDelegate:InitViewSize()
    self.m_pUILayer = self.m_pBtnGroup
end

function FastActDelegate:setCloseCallback()
    if self.m_pUILayer == nil then
        return
    end
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

function FastActDelegate:ProcessEvent(msg)
	if msg.msgId == LUIMainEvent.FlushOpenActivity then
        self:UpdateFastActBtn()
        self:SortActButtonGroup()
    elseif msg.msgId == LUIMiJingEvent.UpdateRedDotEvent then
        self:DealMiJingData(msg.value)
        if msg.value then
            LuaNetSendMsg:QueryMsBossInfo()
        end
    elseif msg.msgId == LUIMapEvent.ChangeMapSuccess then
        self:DealChangeMapSuccess()
    elseif msg.msgId == LUIMainEvent.GetOpenActivity then
        msg.value.list = GUITipsActivity
    elseif msg.msgId == LUIRoleDataChangeEvent.LvUp then    
        self:addWWDXIcon()
        LWWDXMgr:beginCountDown()
    elseif msg.msgId == LUIWeiWoDuXianEvent.WWDXUpdateCound then
        self:HandleWWDXIconFuc()
    end
end

local function getOpenTime(actId, timestamp)
	local cfg = GUITipsActivity[actId]
	if cfg == nil then
		cfg = GUICrossServerActivity[actId]
        if cfg == nil then
            return nil
        end
	end
    -- dump(cfg, "cfg--->")
    local temp = os.date("*t", timestamp)
    -- dump({temp.hour , temp.min}, "temp--->")
	local tmins = temp.hour * 60 + temp.min
	for i=1,#cfg do
		local timeData = cfg[i]
		if #timeData >= 2 then
			local cmins = timeData[1]*60 + timeData[2]
			local diff = cmins - tmins
            -- dump({diff , cmins , tmins})
			-- if diff > 0 and diff < 31 then
				-- return string.format("%02d:%02d", timeData[1], timeData[2])
			-- end
            -- if (temp.hour < timeData[1]) or (temp.hour == timeData[1] and temp.min < timeData[2]) then
            if diff > 0 then
                return string.format("%02d:%02d", timeData[1], timeData[2])
            end
		end
	end
	return nil
end

function FastActDelegate:UpdateFastActBtn()
    if self.m_actBtnPool == nil then
        return
    end

    local pBtnGroup = self.m_pBtnGroup
    if pBtnGroup == nil then
        return
    end

    local list = self.m_actBtnPool:GetUsed()
    local buffer = {}
    for i=1,#list do
        buffer[list[i]:getTag()] = i
    end
    -- dump(LRoleDataMgr.OpenedActData, "LRoleDataMgr.OpenedActData-->")
    
    self.m_data = {}
    for i=1,#LRoleDataMgr.OpenedActData do
        local actId = LRoleDataMgr.OpenedActData[i].actID
        if LRoleDataMgr.OpenedActData[i].time then
            self.m_data[actId] = LRoleDataMgr.OpenedActData[i]
        end
    end

    for i=1,#LRoleDataMgr.OpenedActData do
        local actId = LRoleDataMgr.OpenedActData[i].actID
        local isNoTime = Utils:ToBool(LRoleDataMgr.OpenedActData[i].isNoTime)

        local pBtn = nil
        if buffer[actId] ~= nil then
            pBtn = list[buffer[actId]]
        else
            pBtn = self.m_actBtnPool:Pop()
            pBtn:setTag(actId)
            pBtn:addClickEventListener(handler(self, FastActDelegate.EnterFastActCallback))
			self:MarkIntaractCObj(pBtn)
            pBtnGroup:addChild(pBtn)
        end
        if pBtn then
            local str = AppDef.GUIRes["Activity_Name"..actId]
            if str and #str > 0 and buffer[actId] == nil then
                pBtn:loadTextures(str, "", "", UI_TEX_TYPE_LOCAL)
            end
            local pTextBg = pBtn:getChildByName("Image")
            local pText = pBtn:getChildByName("Text")
            if pText and pTextBg then
                pText:setTag(actId)
                if actId == AppDef.EActivityID.EAID_WEIWODUXIAN then
                    self._wwdxPTextBg = pTextBg
                    self._wwdxPText = pText
                else
                    pTextBg:setVisible(not isNoTime)
                    pText:setVisible(not isNoTime)
                    if not isNoTime then
                        local time = LRoleDataMgr.OpenedActData[i].time
                        local timestamp = LRoleDataMgr.OpenedActData[i].timestamp
                     
                        if time then
                            if self.m_pTimers[actId] == nil then
                                self.m_pTimers[actId] = TimerLabelUI:New(pText, time, nil, handler(self, FastActDelegate.TimeReduce))
                            end
                            self.m_pTimers[actId]:set(time, handler(self, FastActDelegate.TimeEnd))
                            self.m_pTimers[actId]:start()
                        else
                            if self.m_pTimers[actId] ~= nil then
                                self.m_pTimers[actId]:stop()
                            end
                            local str = getOpenTime(actId, timestamp)
                            if str == nil then
                                actId = nil
                            else
                                pText:setString(string.format("%s%s", str, GUITips.RSI_TIPS_OPEN))
                            end
                        end
                    end
                end
            end
        end
        if actId then
        	buffer[actId] = nil
        end
    end
    list = self.m_actBtnPool:GetUsed()
    local _list = {}
    for k,v in pairs(buffer) do
    	if self.m_pTimers[k] ~= nil then
    		self.m_pTimers[k]:stop()
    	end
        table.insert(_list, list[v])
    end
    for i=1,#_list do
        self.m_actBtnPool:Push(_list[i])
        _list[i] = nil
    end
    _list = nil
end

function FastActDelegate:EnterFastActCallback(sender)
    if sender == nil then
        return
    end
    EnterBtnTouched(sender:getTag(), true)
end

function FastActDelegate:TimeReduce(pText, h, m, s, left)
    if pText == nil then
        return
    end
    if h > 0 then 
        pText:setString(string.format("%02d:%02d:%02d", h, m,s))
    else
        pText:setString(string.format("%02d:%02d", m, s))
    end
    local actId = pText:getTag()
    if self.m_data and self.m_data[actId] and self.m_data[actId].time then
        self.m_data[actId].time = left
    end
end

function FastActDelegate:TimeEnd(pText)
    if pText == nil then
        return
    end
    local actId = pText:getTag()
    if actId and actId > 0 then
        LuaNetRecvdMsg.checkOpenAct(actId, 2)
    end
end

function FastActDelegate:TimeReduceWWDXEnd()
    -- body
    --刷新倒计时
    local tag, leftTime = LWWDXMgr:getWWDXCountDownTime()
    local actId = AppDef.EActivityID.EAID_WEIWODUXIAN
    self.m_pTimers[actId]:set(leftTime, handler(self, FastActDelegate.TimeReduceWWDXEnd))
    LWWDXMgr.m_curCountDownTag = tag
    self.m_pTimers[actId]:start()
end

function FastActDelegate:TimeReduceWWDX(pText, h, m, s, left)
    if pText == nil then
        return
    end
    
    local tag, strTimeFormat = LWWDXMgr:getWWDXCountDownStr()
    local str = ""
    if tag == 1 then
        local day = 0
        if h > 24 then
            day = math.floor(h / 24)
            h = math.fmod(h, 24)
        end

        if day > 0 then
            str = str.. GUITips.RSI_CROSSSERVER_TIPS_23..tostring(day)..GUITips.Item_Info_Day 
            str = str..string.format("%02d:%02d", h, m)
        else
            str = str..string.format(strTimeFormat, h, m, s)
        end
    elseif tag == 2 then
        if h > 1 then
            str = str..string.format(strTimeFormat, h, m)
        else
            str = str..string.format(strTimeFormat, m, s)
        end
    elseif tag == 8 then
        str = str..string.format(strTimeFormat, h, m, s)
    else
        str = str..string.format(strTimeFormat, m, s)
    end
    pText:setString(str)
end

function FastActDelegate:SortActButtonGroup()
    local wfBtn = self.m_pWanfaBtn
    if wfBtn == nil then
        return
    end

    local wfPos = cc.p(wfBtn:getPosition())
    local isHaveWanfa = wfBtn:isVisible()

    local list = self.m_actBtnPool:GetUsed()
    local buffer = {}
    for i=1,#list do
        local pBtn = list[i]
        if pBtn then
            buffer[pBtn:getTag()] = pBtn
        end
    end

    local index = isHaveWanfa and 1 or 0
    
    for i=1,#LRoleDataMgr.OpenedActData do
        local actId = LRoleDataMgr.OpenedActData[i].actID
        local pBtn = buffer[actId]
        if pBtn then
            if index <= 2 then
                pBtn:setPosition(cc.p(wfPos.x-index*100, wfPos.y))
            else
                pBtn:setPosition(cc.p(wfPos.x-(index-3)*100, wfPos.y-135))
            end
            if pBtn:isVisible() then
                index = index + 1
            end
        end
    end
end

function FastActDelegate:DealMiJingData(isShow)
    local list = self.m_actBtnPool:GetUsed()
    for i=1,#list do
        if list[i] then
            local tag = list[i]:getTag()
            if tag == AppDef.EActivityID.EAID_SHENJIEMIJING then
                list[i]:getChildByName("Prompt"):setVisible(isShow)
                break
            end
        end
    end
end

function FastActDelegate:DealChangeMapSuccess()
    if LRoleDataMgr.m_bIsCrossServer then
        LuaNetSendMsg:QueryMsBossInfo()
    end

    local list = self.m_actBtnPool:GetUsed()
    for i=1,#list do
        if list[i] then
            local act = list[i]:getTag()
            if act > 0 then
                if LRoleDataMgr.m_bIsCrossServer then
                    list[i]:setVisible(GUICrossServerActivity[act] ~= nil)
                else
                    list[i]:setVisible(GUITipsActivity[act] ~= nil)
                end
            end
        end
    end
    self:SortActButtonGroup()
end

function FastActDelegate:HandleWWDXIconFuc()
    -- body
    --天元争霸显示决赛倒计时
    if self._wwdxPTextBg == nil then
        return
    end

    if self._wwdxPText == nil then
        return
    end
    local pText = self._wwdxPText
    self._wwdxPTextBg:setVisible(true)
    pText:setVisible(true)
    local actId = AppDef.EActivityID.EAID_WEIWODUXIAN
    local tag, leftTime = LWWDXMgr:getWWDXCountDownTime()
    if leftTime > 0 then
        if self.m_pTimers[actId] == nil then
            self.m_pTimers[actId] = TimerLabelUI:New(pText, leftTime, nil, handler(self, FastActDelegate.TimeReduceWWDX))            
        end
        self.m_pTimers[actId]:set(leftTime, handler(self, FastActDelegate.TimeReduceWWDXEnd))
        LWWDXMgr.m_curCountDownTag = tag
        self.m_pTimers[actId]:start()
    end
end

function FastActDelegate:addWWDXIcon()
    if Utils:CheckModelNotOpened(AppDef.EActivityID.EAID_WEIWODUXIAN, true) then
        return
    end
    if self.m_data[actId] == nil then
        LuaNetRecvdMsg.checkOpenAct(AppDef.EActivityID.EAID_WEIWODUXIAN, 1)
    end
end

return FastActDelegate