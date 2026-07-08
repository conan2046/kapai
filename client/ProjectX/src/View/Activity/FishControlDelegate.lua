local TimerLabelUI = require("View.Common.TimerLabelUI")

local fishAreaConfig = {}
table.insert(fishAreaConfig, {points={cc.p(623, 937), cc.p(490, 830), cc.p(1349, 305), cc.p(1520 ,435)}, dir=2, flip=true})
table.insert(fishAreaConfig, {points={cc.p(690, 958), cc.p(1576, 461), cc.p(1681, 549), cc.p(933, 1014)}, dir=6, flip=false})
table.insert(fishAreaConfig, {points={cc.p(1051, 242), cc.p(943, 328), cc.p(678, 151), cc.p(803, 59)}, dir=4, flip=true})

local FishControlDelegate = LUIBase:New()
FishControlDelegate.__index = FishControlDelegate

function FishControlDelegate:New(uiRoot)
    local o = {}
    setmetatable(o,FishControlDelegate)  
    o:Init(uiRoot)
    return o
end

--[[
注册UI消息
]]
function FishControlDelegate:RegistMsgs()
    self.msgIds = 
    {
        LUIFishEvent.UpdateState,
        LUIFishEvent.QuitFishState,
    }
    self:RegistSelf(self,self.msgIds)
end

function FishControlDelegate:ProcessEvent(msg)
    if msg.msgId == LUIFishEvent.UpdateState then
        local state = msg.value[1]
        self:ChangeYuGanState(state)
        if state then
            self:StartTime(msg.value[2])
        else
            self:StopTime()
        end
    elseif msg.msgId == LUIFishEvent.QuitFishState then
        if self.m_yuGanDrop then
            LuaNetSendMsg:QueryFishingInfo(10)
        end
    end
end

function FishControlDelegate:Init(uiRoot)
    self.m_yuGanDrop = false--true:放下鱼竿状态 false:收起鱼竿状态
    self.m_timeNum = 0
    self.m_timer = nil
    -------------------------------------
    self:RegistMsgs()
    self:InitViewSize(uiRoot)
    self:InitUIControl()
end

function FishControlDelegate:InitUIControl()
    if self.m_pUILayer == nil then
        return
    end
    -------------------------------------------------------------------------
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    -------------------------------------------------------------------------
    local pTime = self.m_pUILayer:getChildByName("Time")
    self.m_pTimeProgress = pTime:getChildByName("LoadingBar")
    self.m_pTimeProgress:setPercent(0)
    local pTimeText = pTime:getChildByName("Value")
    pTimeText:setString("00:00")
    self.m_pTimeText = pTimeText
    self.m_timer = TimerLabelUI:New(pTimeText, nil, nil, handler(self, FishControlDelegate.TimeReduce))
    -------------------------------------------------------------------------
    local pBtnYuGan = self.m_pUILayer:getChildByName("btn_shouqi")
    pBtnYuGan:addClickEventListener(handler(self, FishControlDelegate.YuGanClick))
	self:MarkIntaractCObj(pBtnYuGan)
    self.m_pYuGanBtnText = pBtnYuGan:getChildByName("Text")
    self.m_pYuGanBtnText:setString(GUITips.RSI_FISH_TIP1)
    -------------------------------------------------------------------------
    local pBtnYuLan = self.m_pUILayer:getChildByName("btn_yulan")
    pBtnYuLan:addClickEventListener(handler(self, FishControlDelegate.YuLanClick))
	self:MarkIntaractCObj(pBtnYuLan)
    -------------------------------------------------------------------------
end

function FishControlDelegate:InitViewSize(uiRoot)
    self.m_pUILayer = uiRoot
end

function FishControlDelegate:onExit()
    self:Destory()
    if self.m_timer then
        self.m_timer:Destory()
        self.m_timer = nil
    end
    self.m_pUILayer = nil
    self.m_yuGanDrop = nil
    self.m_timeNum = nil
    self.m_pTimeProgress = nil
    self.m_pTimeText = nil
    self.m_pYuGanBtnText = nil
end

function FishControlDelegate:YuGanClick(sender)
    if self.m_yuGanDrop then
        LuaNetSendMsg:QueryFishingInfo(10)
    else
        if LRoleDataMgr.MyHeroInfo.node then
            local pos = cc.p(LRoleDataMgr.MyHeroInfo.node:getPosition())
            --dump(pos)
            local data = nil
            for i=1,#fishAreaConfig do
                local cfg = fishAreaConfig[i]
                if Utils:PointInArea(pos, cfg.points) then
                    data = cfg
                    break
                end
            end
            if data and data.dir then
                LuaNetSendMsg:QueryFishingInfo(5, data.dir)
                LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.AutoPathEvent.PauseAutoPath)
                self:SendMsg(LGameMsg.m_cBaseMsg)
            else
                Utils:ShowScrollTips(GUITips.RSI_FISH_TIP13)
            end
        end
    end
end
--显示我的鱼篮
function FishControlDelegate:YuLanClick(sender)
    Utils:SendMsg(LUIFishEvent.ShowFishBasket, {true})
end

function FishControlDelegate:ChangeYuGanState(state)
    if state == nil then
        self.m_yuGanDrop = not self.m_yuGanDrop
    else
        self.m_yuGanDrop = Utils:ToBool(state)
    end
    if self.m_pYuGanBtnText then
        self.m_pYuGanBtnText:setString(self.m_yuGanDrop and GUITips.RSI_FISH_TIP2 or GUITips.RSI_FISH_TIP1)
    end
end

function FishControlDelegate:StartTime(time)
    self.m_initTime = time
    if self.m_timer then
        self.m_timer:set(time)
        self.m_timer:start()
    end
end

function FishControlDelegate:StopTime()
    if self.m_timer then
        self.m_timer:stop()
    end
    self.m_pTimeText:setString("00:00")
    self.m_pTimeProgress:setPercent(0)
end

function FishControlDelegate:TimeReduce(pText, h, m, s, left)
    if pText == nil then
        return
    end
    pText:setString(string.format("%02d:%02d", m, s))
    local pro = math.min(left*100/self.m_initTime, 100)
    self.m_pTimeProgress:setPercent(100 - math.floor(pro))
end

return FishControlDelegate