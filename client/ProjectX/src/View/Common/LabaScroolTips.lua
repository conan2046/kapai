local LabaScroolTips = LUIBase:New()
LabaScroolTips.__index = LabaScroolTips
--local this = LTcpSocket
function LabaScroolTips:New()
	local o = LUIBase:New()
	setmetatable(o,LabaScroolTips)	
    o:Init()
	return o
end

local speed = 70
local PRETXTSHOWTIME = 15

--注册事件
-- -----------------------------------
function LabaScroolTips:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function LabaScroolTips:ProcessEvent(msg)

end

function LabaScroolTips:Init()
    self.m_pUILayer = cc.CSLoader:createNode("csd/kuafulaba.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:initControlUI()

end

function LabaScroolTips:initControlUI()
    -- body
    local kuafulaba = self.m_pUILayer:getChildByName("kuafulaba")
    local panel = kuafulaba:getChildByName("Bg"):getChildByName("Panel")
    self._panelSize = panel:getContentSize()
    self._textTips = panel:getChildByName("Text")
    self._beginPos = cc.p(self._textTips:getPosition())
    self._tipsArr = {}
    self._isInUpdate = false
end

function LabaScroolTips:SetTexts(strMsg)
    table.insert(self._tipsArr, strMsg)
    if not self._isInUpdate then
        self.m_coldTime = PRETXTSHOWTIME
        self:TimerCallBack()
        self.m_pUILayer:setVisible(true)
    end
end

function LabaScroolTips:beginAction()
    -- body
    self._textTips:setString(self._tipsArr[1])
    self._textTips:setPosition(self._beginPos)
--    print("beginAction", self._panelSize.width, self._textTips:getContentSize().width)
    local spaceX = self._panelSize.width - self._textTips:getContentSize().width
    if spaceX > 0 then
        return
    end

    local moveTo = cc.MoveBy:create((-spaceX + self._panelSize.width) / 100, cc.p(spaceX - self._panelSize.width , 0))
    local function callfucPlayEnd( sender )
        -- body
        self._textTips:setPosition(self._beginPos)
    end
    local callfuc = cc.CallFunc:create(callfucPlayEnd)
    local delay = cc.DelayTime:create(2)
    local sequence = cc.Sequence:create(delay, moveTo, callfuc)
    self._textTips:runAction(cc.RepeatForever:create(sequence))

end

function LabaScroolTips:TimerCallBack()
    local function UpdateCD()
        self.m_coldTime = self.m_coldTime - 1
--        print("TimerCallBack", self.m_coldTime)
        if self.m_coldTime <= 0 then
--倒计时结束
            self:beginNextNotice()
        end
    end
    self:UnRoundSchedule()
    if self.m_coldTime > 0 then
        local scheduler =  AppDef.Director:getScheduler()
        self.m_schedulerID = scheduler:scheduleScriptFunc(UpdateCD, 1, false)
        self._isInUpdate = true
        self._textTips:stopAllActions()
        self:beginAction()
    end
end

function LabaScroolTips:beginNextNotice(  )
    -- body
    table.remove(self._tipsArr, 1)
    if #self._tipsArr < 1 then
        self:closeTipsUI()
        return
    end
    self.m_coldTime = PRETXTSHOWTIME
    self._textTips:stopAllActions()
    self:beginAction()
end

function LabaScroolTips:UnRoundSchedule()
    if self.m_schedulerID then
        AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_schedulerID)
        self.m_schedulerID = nil
    end
end


function LabaScroolTips:onExit()
    self._tipsArr = {}
    self:closeTipsUI()
    self:Destory()
end

function LabaScroolTips:closeTipsUI( ... )
    -- body
    self.m_pUILayer:setVisible(false)
    self:UnRoundSchedule()
    self._isInUpdate = false
end

return LabaScroolTips