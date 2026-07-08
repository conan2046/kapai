
local VoiceWindowUI = LUIBase:New()
VoiceWindowUI.__index = VoiceWindowUI
--local this = LTcpSocket
function VoiceWindowUI:New()
	local o = LUIBase:New()
	setmetatable(o,VoiceWindowUI)	
    o:Init()
	return o
end

function VoiceWindowUI:Init()
    self.m_pUILayer = cc.CSLoader:createNode("csd/VoiceWindow.csb")
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self.m_pUILayer:setVisible(false)

    self:RegistMsgs()
    self:initUI()
end

function VoiceWindowUI:onExit()
    self.m_pUILayer = nil
    self:UnVoiceSchedule()
    self:Destory()
end

function VoiceWindowUI:initUI( ... )
    -- body
    local panel = self.m_pUILayer:getChildByName("VoiceWindow")
    self._off = panel:getChildByName("off")
    self._on = panel:getChildByName("on")
    self._text = panel:getChildByName("Text")

    self._on:setVisible(true)

    -- local function callback(frame)
    --     --动画播放完成
    -- end

    self._action = cc.CSLoader:createTimeline("csd/VoiceWindow.csb")
    local timeline = ccs.Timeline:create()
    local frame = ccs.EventFrame:create()
    frame:setEvent("End")
--    frame:setFrameIndex(60)
    timeline:addFrame(frame)
    self._action:addTimeline(timeline)
    self.m_pUILayer:runAction(self._action)
    self._action:pause()
    self._action:clearFrameEventCallFunc()

    --action:setFrameEventCallFunc(callback)

    local pLoading = self._on:getChildByName("Loading")
    pLoading:setVisible(false)

    local pSp = cc.Sprite:createWithSpriteFrameName("res/UI/ui_bangpai/ui_bangpai_jingyan.png")
    self._progressBar = cc.ProgressTimer:create(pSp)
    self._progressBar:setScale(1.3)
    self._progressBar:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
--    progressBar:setIgnoreAnchorPointForPosition(true)
    self._progressBar:setAnchorPoint(pLoading:getAnchorPoint())
    self._progressBar:setPosition(cc.p(pLoading:getPosition()))
    self._progressBar:setPercentage(0)
    self._on:addChild(self._progressBar)

end

--[[
注册消息
]]
function VoiceWindowUI:RegistMsgs()
    self.msgIds = 
    {
        LUIChatEvent.showVoiceWindow,
        LUIChatEvent.cancelVoiceWindow,
        LUIChatEvent.beginVoiceProgress,
    }
    self:RegistSelf(self,self.msgIds)
end

function VoiceWindowUI:ProcessEvent(msg)
    if msg.msgId == LUIChatEvent.showVoiceWindow then
        if msg.value then
            self._off:setVisible(false)
            self._on:setVisible(true)
            self._text:setString(GUITips.RSI_VOICE_WINDOW_SHOW)
            self._action:gotoFrameAndPlay(0,110,true)
        else
            self:UnVoiceSchedule()
            self._action:stop()
        end
        self.m_pUILayer:setVisible(msg.value)
    end

    if msg.msgId == LUIChatEvent.cancelVoiceWindow then
        self._off:setVisible(true)
        self._on:setVisible(false)
        self._text:setString(GUITips.RSI_VOICE_WINDOW_CANCEL)
        self._action:stop()
    end

    if msg.msgId == LUIChatEvent.beginVoiceProgress then
        --print("begin voice")
        self:VoiceTimerCallBack(msg.value)
    end

end


function VoiceWindowUI:VoiceTimerCallBack(time)
    local totalTime = time
    local function UpdateCD()
        self._voiceTime = self._voiceTime - 0.2
        local rate = (totalTime - self._voiceTime) / totalTime
--        print("self._voiceTime 222222222222222222", self._voiceTime, totalTime)
        self._progressBar:setPercentage(rate * 100)
        if self._voiceTime <= 0 then
            self:UnVoiceSchedule()
        end
    end
    self:UnVoiceSchedule()
    self._voiceTime = time

    local scheduler = AppDef.Director:getScheduler()
    self.m_schedulerVoiceID = scheduler:scheduleScriptFunc(UpdateCD, 0.2, false)


end

function VoiceWindowUI:UnVoiceSchedule()
    if self.m_schedulerVoiceID then
        AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_schedulerVoiceID)
        self.m_schedulerVoiceID = nil
    end
end


return VoiceWindowUI