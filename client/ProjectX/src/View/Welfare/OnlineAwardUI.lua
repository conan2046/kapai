-- ------------------------------
-- 在线奖励


local OnlineAwardUI = LUIBase:New()
OnlineAwardUI.__index = OnlineAwardUI

-- ----------------------------------------------
-- 常量区
local ScriptPath = "Welfare.OnlineAwardUI"
local CsbFilePath = "csd/OnlineGiftLayer.csb"

-- ----------------------------------------------
local _DEBUG = false
local function Debug(msg)
    if not _DEBUG then return end
    
end


-- ----------------------------------------------
local function _ShowTipsWindow(ui, msg)
    LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, msg)
    ui:SendMsg(LGameMsg.m_scrollTipsMsg)
end

-- ----------------------------------------------
local function _BindClickFunctionToButton(btn,fuc)
    btn:addClickEventListener(fuc)
	OnlineAwardUI:MarkIntaractCObj(btn)
end

-- ----------------------------------------------
function OnlineAwardUI:New()
    local o = LUIBase:New()
    setmetatable(o, OnlineAwardUI)
    o:Init()
    return o
end

-- ----------------------------------------------
function OnlineAwardUI:RegistMsgs()
    self.msgIds = 
    {
        LUIOnlineAwardEvent.OnlineAwardInfo,
        LUIOnlineAwardEvent.OnlineAward,
    }
    self:RegistSelf(self, self.msgIds)
end

-- ----------------------------------------------
function OnlineAwardUI:ProcessEvent(msg)
    if msg.msgId == LUIOnlineAwardEvent.OnlineAwardInfo then
        self:OnlineAwardInfo(msg.value)
    elseif msg.msgId == LUIOnlineAwardEvent.OnlineAward then
        self:OnlineAward(msg.value)
    end

end


function  OnlineAwardUI:OnlineAward(rsp)
    if rsp.errmsg then 
        _ShowTipsWindow(self, rsp.errmsg)
    else 
        self:QueryAwardInfo()
    end 
    --LGameMsg.m_baseMsgWithOne:Change(LUIOnlineAwardEvent.KaifuReddotRefresh,5)
    --elf:SendMsg(LGameMsg.m_baseMsgWithOne)
end 


-- ----------------------------------------------
function OnlineAwardUI:OnlineAwardInfo(rsp)
    -- ========================
    -- 
    Debug(rsp)
    self.award = rsp.award 
    self.awards = rsp
    self:NewDrawAward()
end 

-- ----------------------------------------------
function OnlineAwardUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.rpanel = nil
    self.lpanel = nil
    self.curaward_btn_label = nil
    self:CancelUpdate()
    
end

-- ----------------------------------------------
function OnlineAwardUI:RegisterQuik()
    local function onNodeEvent(event)        
        if "exit" == event then
            Debug("onNodeEvent")
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

end

-- ----------------------------------------------
function OnlineAwardUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode(CsbFilePath)
    local RootPanel = self.m_pUILayer:getChildByName("LoginGiftUI")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

-- ----------------------------------------------
local ITMENUM = 3
local tagid = 1886
function OnlineAwardUI:InitUIControl()
    local rootnode = self.m_pUILayer:getChildByName("LoginGiftUI")
    self.main_list_view = rootnode:getChildByName("ListView")

    self.award_cell = rootnode:getChildByName("Item1")
    self.award_cell:setTouchEnabled(true)

    local function OnButtonClick(btn)
        self:AwardOnlineAward()
    end 
    
    self.award_btn = rootnode:getChildByName("Item"):getChildByName("btn_Get")
    _BindClickFunctionToButton(self.award_btn, OnButtonClick)



end 
-- ----------------------------------------------
local tick = 1

function OnlineAwardUI:NewDrawAward()
    if not self.awards then return end 
    self.main_list_view:removeAllItems()
    local rootnode = self.m_pUILayer:getChildByName("LoginGiftUI")
    local anum = #self.awards.award
    --dump(self.awards)
    for i  = 1, anum do
        local award = self.awards.award[i]
        local award_item = rootnode:getChildByName("Item"):clone()
        award_item:getChildByName("btn_Get"):setTag(award.onlinetime)
        award_item:getChildByName("Title"):setString(award.onlinetime.."分钟")

        local awardui = self.award_cell:clone()  -- 奖励物品控件
        Utils:GetItemCellValue(awardui, 0, award.itemid, true, true, award.num, nil, true)
        award_item:getChildByName("ListView"):pushBackCustomItem(awardui)

        self.main_list_view:pushBackCustomItem(award_item) -- 添加到主列表
        
        if award.state == 0 then 
            award_item:getChildByName("btn_Get"):setVisible(false)
            award_item:getChildByName("Mark"):setVisible(false) 
            --award_item:getChildByName("btn_Get"):setEnabled(false)
        end 

        -- ========================
        -- 倒计时和可领奖绑定按钮函数
        if award.state == 1  or  award.state == 2 then 
            local btn = award_item:getChildByName("btn_Get")
            local function OnButtonClick(btn)
                local tag = btn:getTag()
                self:AwardOnlineAward(tag)
            end 
            _BindClickFunctionToButton(btn, OnButtonClick)
        end 


        -- ===========================
        -- 倒计时当前及时的
        if award.onlinetime == self.awards.curidx then 
            self.lefttime = award.lefttime
            self.curaward_btn = award_item:getChildByName("btn_Get")

            if self.curaward_btn ~= nil then
                self.curaward_btn:setEnabled(false)
                self.curaward_btn_label = self.curaward_btn:getChildByName("Text")
                self.curaward_btn_label:setString(os.date("%M:%S", award.lefttime))
            end

            local function TimerTick()
                self:NewDrawTextTick()
            end 
            local scheduler =  AppDef.Director:getScheduler()
            self:CancelUpdate()
            self.scheduler =  scheduler:scheduleScriptFunc(TimerTick, tick, false)
        end 

        if  award.state == 2 then 
            -- ================
            -- 可以领奖
            award_item:getChildByName("btn_Get"):setVisible(true) --
            award_item:getChildByName("btn_Get"):getChildByName("Text"):setString(GUITips.RSI_GMN_TIP23)
            award_item:getChildByName("Mark"):setVisible(false) 
        end 

        if award.state == 3 then
            -- ================
            -- 已领
            award_item:getChildByName("btn_Get"):setVisible(false) 
            award_item:getChildByName("Mark"):setVisible(true) 
        end 

    end  

end 

function OnlineAwardUI:CancelUpdate()
    if self.scheduler ~= nil then
        AppDef.Director:getScheduler():unscheduleScriptEntry(self.scheduler)
        self.scheduler = nil
    end 
end

function OnlineAwardUI:NewDrawTextTick()
    self.lefttime = self.lefttime - tick
    if self.curaward_btn_label ~= nil then
        self.curaward_btn_label:setString("")
    end
    if self.lefttime <= 0 then 
        self.curaward_btn:setEnabled(true)
        self:CancelUpdate()
        if self.curaward_btn_label ~= nil then
            self.curaward_btn_label:setString(GUITips.RSI_GMN_TIP23)
        end
    else
        local timestr = os.date("%M:%S", self.lefttime)
        if self.curaward_btn_label ~= nil then
            self.curaward_btn_label:setString(timestr)
        end
    end
end 


-- ----------------------------------------------
function OnlineAwardUI:QueryAwardInfo()
    LuaNetSendMsg:QueryOnlineAward()
end


-- ----------------------------------------------
function OnlineAwardUI:AwardOnlineAward(index)
    LuaNetSendMsg:AwardOnlineAward(index)
end

-- ----------------------------------------------
function OnlineAwardUI:Init()
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:RegisterQuik()
    self:QueryAwardInfo()
end



-- ----------------------------------------------
return OnlineAwardUI