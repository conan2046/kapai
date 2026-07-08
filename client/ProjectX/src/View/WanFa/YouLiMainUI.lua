local TimerLabelUI = require("View.Common.TimerLabelUI")
local YouLiMainUI = LUIBase:New()
YouLiMainUI.__index = YouLiMainUI
YouLiMainUI.IsHideInBattle = true
function YouLiMainUI:New()
    local o = LUIBase:New()
    setmetatable(o,YouLiMainUI) 
    o:Init()
    return o
end

--[[
注册消息
]]
function YouLiMainUI:RegistMsgs()
    self.msgIds = 
    {
         LUIActivityEvent.RefreshYouLiUI,--游历数据返回
         LUIActivityEvent.StartYouLi,--开始游历
    }
    self:RegistSelf(self,self.msgIds)
end

function YouLiMainUI:ProcessEvent(msg)
    if msg.msgId == LUIActivityEvent.RefreshYouLiUI then
        self:ShowYouLiList()
    elseif msg.msgId == LUIActivityEvent.StartYouLi then
        LuaNetSendMsg:QueryYouLiInfo()--请求数据
    end
end


function YouLiMainUI:Init()
    self.Script = "WanFa.YouLiMainUI"
    self:CreateUINode("csd/youli/youlisanjie.csb")
    -- self.m_pUILayer = cc.CSLoader:createNode("csd/fengshenliezhuan/fengshenliezhuanlLayer.csb")
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:InitData()
    self:initControlUI()

    LuaNetSendMsg:QueryYouLiInfo()--请求数据
end

function YouLiMainUI:InitData()
    self.m_cells = {}
    self.m_timers = {}
end

function YouLiMainUI:initControlUI()
    --关卡
    local panel = self.m_pUILayer:getChildByName("youliUI")
    local xiezhuPanel = panel:getChildByName("xiezhuBg")
    xiezhuPanel:setVisible(false)
    self.m_mainListView = panel:getChildByName("ListView")
    self.m_mainCell = panel:getChildByName("Item")
    self.m_mainCell:retain()
    self.m_mainCell:removeFromParent()
    self.m_friendPanel = panel:getChildByName("Panel")
    self.m_friendPanel:setVisible(false)

    local youliBtn = panel:getChildByName("Btn_youli")
    youliBtn:addClickEventListener(handler(self,YouLiMainUI.OneKeyYouLiCallBack))
    local lingquBtn = panel:getChildByName("Btn_lingqu")
    lingquBtn:addClickEventListener(handler(self,YouLiMainUI.OneKeyLingQuCallBack))

    Utils:SendMsg(LUIFClassBgEvent.SetTitle, GUITips.RSI_YOULI_TITLE)
    Utils:SendMsg(LUIRoleDataChangeEvent.BGVisible, false)
    Utils:SendMsg(LUIFClassBgEvent.SetCloseCallback,handler(self,YouLiMainUI.RemoveUI))
    Utils:SendMsg(LUIFClassBgEvent.HelpBtn,AppDef.FCBHelp.YouLiSanJie)
end

function YouLiMainUI:ShowYouLiList()
    local data = LActivityManager:GetYouLiData()
    if data.m_youlis == nil then
        return
    end
    for i=1,#data.m_youlis do
        if self.m_cells[i] == nil then
            self.m_cells[i] = self.m_mainCell:clone()
            self.m_mainListView:pushBackCustomItem(self.m_cells[i])
            self.m_cells[i]:addClickEventListener(handler(self,YouLiMainUI.MainCellCallBack))
        end
        self:ShowOneYouLi(self.m_cells[i],data.m_youlis[i])
    end
end

function YouLiMainUI:ShowOneYouLi(sender,value)
    sender.userObject = value.id
    local panel = sender:getChildByName("Item")
    local lockPanel = panel:getChildByName("Lock")
    local lockLabel = lockPanel:getChildByName("Condition")
    local bgImg = panel:getChildByName("Image")
    local nameLabel = panel:findChildByName("Namebg/Name")
    local stateLabel1 = panel:getChildByName("Text_1")--游历完成
    local stateLabel2 = panel:getChildByName("Text_2")--游历中
    local timePanel = panel:getChildByName("TimeBg")
    local timeLabel = timePanel:getChildByName("Time")
    stateLabel1:setVisible(false)
    stateLabel2:setVisible(false)
    timePanel:setVisible(false)
    local cfg = JsonConfig.m_youliConfig.getDefByID(value.id)
    if cfg == nil then
        return
    end
    nameLabel:setString(cfg.name)
    if #cfg.pic1 > 0 then
        bgImg:setContentSize(panel:findChildByName("Bg/bg2"):getContentSize())
        local imgPath = "res2/InstancesBg/"..cfg.pic1..".png"
        Utils:SafeLoadTexture(bgImg,imgPath,ccui.TextureResType.localType)
    end
    local level = LRoleDataMgr.MyHeroInfo.level
    if level < cfg.unlock then
        lockPanel:setVisible(true)
        lockLabel:setString(string.format(GUITips.RSI_YOULI_CONDITION,cfg.unlock))
    else
        lockPanel:setVisible(false)
    end
    if value.heroId > 0 then
        local now = LDataConstMgr.m_serverTime--os.time()
        if value.endTime > now then
            local time = value.endTime - now
            stateLabel2:setVisible(true)
            timePanel:setVisible(true)
            if self.m_timers[value.id] == nil then
                self.m_timers[value.id] = TimerLabelUI:New(timeLabel,time,handler(self,YouLiMainUI.OnTimerEnd),nil,false,0)
            end
            self.m_timers[value.id]:start()
        else
            stateLabel1:setVisible(true)
        end
    end
end

function YouLiMainUI:OnTimerEnd(sender)
    sender:setVisible(false)
    local parent = sender:getParent()
    parent:getChildByName("Text_1"):setVisible(true)
    parent:getChildByName("TimeBg"):setVisible(false)
end

function YouLiMainUI:MainCellCallBack(sender)
    local id = sender.userObject or 0
    if id == 0 then
        return
    end
    local cfg = JsonConfig.m_youliConfig.getDefByID(id)
    if cfg == nil then
        return
    end
    local level = LRoleDataMgr.MyHeroInfo.level
    if level < cfg.unlock then
        Utils:ShowScrollTips(string.format(GUITips.RSI_YOULI_CONDITION,cfg.unlock))
        return
    end
    Utils:InitUI("WanFa.YouLiUI",AppDef.UIType.FirstClassLayer,id)
end

function YouLiMainUI:OneKeyYouLiCallBack(sender)
    local data = LActivityManager:GetYouLiData()
    if data.m_youlis == nil then
        return
    end
    Utils:InitUI("WanFa.YouLiOneKeyUI",AppDef.UIType.ThirdClassLayer)
end

function YouLiMainUI:OneKeyLingQuCallBack(sender)
    local data = LActivityManager:GetYouLiData()
    if data.m_youlis == nil then
        return
    end
    local ids = {}
    local level = LRoleDataMgr.MyHeroInfo.level
    local now = LDataConstMgr.m_serverTime--os.time()
    for i=1,#data.m_youlis do
        local value = data.m_youlis[i]
        local cfg = JsonConfig.m_youliConfig.getDefByID(value.id)
        if level >= cfg.unlock and value.heroId > 0 and value.endTime <= now then
            table.insert(ids,value.id)
        end
    end
    if #ids == 0 then
        Utils:ShowScrollTips(GUITips.RSI_WANFA_TIPS6)
        return
    end
    LuaNetSendMsg:SendYouLiPrizeReq(ids)
end

function YouLiMainUI:onExit()
    Utils:SendMsg(LUIRoleDataChangeEvent.BGVisible, true)
    LActivityManager:YouLiFree()
    self:Destory()
    self.m_pUILayer = nil
    self.Script  = nil
    self.m_cells = nil
end

function YouLiMainUI:OnEnter()
    Utils:SendMsg(LUIRoleDataChangeEvent.BGVisible, false)
end

return YouLiMainUI