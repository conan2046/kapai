
local WwdxBettleUI = LUIBase:New()
WwdxBettleUI.__index = WwdxBettleUI
WwdxBettleUI.IsHideInBattle = true
local TimerLabelUI = require("View.Common.TimerLabelUI")
--local this = LTcpSocket
function WwdxBettleUI:New()
	local o = LUIBase:New()
	setmetatable(o,WwdxBettleUI)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function WwdxBettleUI:RegistMsgs()
    self.msgIds = 
    {
        LUIWeiWoDuXianEvent.ReadWWDXInfo,
        LUIWeiWoDuXianEvent.WWDXBattleCoundDown,
        LUIMapEvent.ChangeMapSuccess,

    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function WwdxBettleUI:ProcessEvent(msg)
    if msg.msgId == LUIWeiWoDuXianEvent.ReadWWDXInfo then
        self:LoadData(msg.value)
        self:updateUI()
    elseif msg.msgId == LUIWeiWoDuXianEvent.WWDXBattleCoundDown then
        self:timeLabel(msg.value)
    elseif msg.msgId == LUIMapEvent.ChangeMapSuccess then
        if not LWWDXMgr.m_enterBattle then
            self:CloseDialog()
        else
            Utils:ShowScrollTips(GUITips.RSI_CROSSSERVER_TIPS_14)
        end
        LWWDXMgr.m_enterBattle = false
    end
end

function WwdxBettleUI:Init()
    self.m_pUILayer = cc.CSLoader:createNode("csd/tianyuanzhengba.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:initControlUI()

    LuaNetSendMsg:QueryWWDXTimer()
    LuaNetSendMsg:QueryWWDXScore()
end

function WwdxBettleUI:initControlUI( ... )
    -- body
    local panel = self.m_pUILayer:getChildByName("tianyuanzhengbaUI"):getChildByName("Panel")
 -----------------------------------------------------------------
    local content = panel:getChildByName("Content")
    self._roundText = content:getChildByName("Time")

    self._myName = content:getChildByName("benfang")
    self._myScore = self._myName:getChildByName("Score")

    self._otherName = content:getChildByName("duifang")
    self._otherScore = self._otherName:getChildByName("Score")
    self._timeLabel = content:getChildByName("Time"):getChildByName("Value")
    self._timerLabel = TimerLabelUI:New(self._timeLabel, nil, nil, handler(self, self.TimeReduce))

end

function WwdxBettleUI:LoadData( data )
    -- body
    self._wwdxInfo = data
end

function WwdxBettleUI:updateUI( ... )
    -- body
--    dump(self._wwdxInfo, "WwdxBettleUI:updateUI")
    self._myName:setString(self._wwdxInfo.name1)
    self._myScore:setString(self._wwdxInfo.score1)

    self._otherName:setString(self._wwdxInfo.name2)
    self._otherScore:setString(self._wwdxInfo.score2)

    local curRound = self._wwdxInfo.score1 + self._wwdxInfo.score2 + 1
    if curRound == 1 then
        self._roundText:setString(GUITips.RSI_CROSSSERVER_TIPS_11)
    elseif curRound == 2 then
        self._roundText:setString(GUITips.RSI_CROSSSERVER_TIPS_12)
    elseif curRound == 3 then
        self._roundText:setString(GUITips.RSI_CROSSSERVER_TIPS_13)
    end
    
end

function WwdxBettleUI:timeLabel(data)
    -- body
    if self._timerLabel == nil then
        self._timerLabel = TimerLabelUI:New(self._timeLabel, nil, nil, handler(self, self.TimeReduce))
    end
    if data ~= nil then
        --data.second
        self._timerLabel:set(data.second)
        self._timerLabel:start()
    end

end

function WwdxBettleUI:TimeReduce(pText, h, m, s, left)
    if pText == nil then
        return
    end

    if left < 0 then
        self:RefreshPreview()
    end

    local str = ""
    local day = 0
    if h > 24 then
        day = math.floor(h / 24)
        h = math.fmod(h, 24)
    end
    if day > 0 then
        str = str..tostring(day)..GUITips.Item_Info_Day
        str = str..string.format("%02d:%02d", h, m)
    else
        str = str..string.format("%02d:%02d", m, s)
    end
    
    pText:setString(str)
end

function WwdxBettleUI:onExit()
    self.m_pUILayer = nil
    local _ = self._timerLabel and self._timerLabel:Destory()
    self:Destory()
end

function WwdxBettleUI:CloseDialog( ... )
    -- body
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "ZhengBa.WwdxBettleUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
end

return WwdxBettleUI