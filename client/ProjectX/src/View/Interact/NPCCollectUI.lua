--Loading提示界面
local NPCCollectUI = LUIBase:New()
NPCCollectUI.__index = NPCCollectUI
--local this = LTcpSocket
NPCCollectUI.IsHideInBattle = true
local ScriptPath = "Interact.NPCCollectUI"
local CsbFilePath = "csd/LoadingCommonLayer.csb"

--[[
lua里面的游戏逻辑控制

userData数据结构：
{
    selectType-- 1采集中... 2开启中 ... 3礼盒领取中 ... 4宝箱开启中
    npcId
    serialNum
    seconds--秒数
    callback --进度完成回调
    type -- 
}
]]
NPCCollectUI.tempData = nil
function NPCCollectUI:New(userData)
    local o = LUIBase:New()
    setmetatable(o,NPCCollectUI)   
    o:Init(userData)
    return o
end

function NPCCollectUI:Init(userData)
    self:RegistMsgs()
    self:InitViewSize()
    self:InitData()
    self:InitTouchEvt()
    self:UpdateData(userData)
end

function NPCCollectUI:RegistMsgs()
    self.msgIds = 
    {
        LUILogicEvent.interruptCollectUI,
        LUIRoleDataChangeEvent.StartHangUp,
    }
    self:RegistSelf(self, self.msgIds)
end

function NPCCollectUI:ProcessEvent(msg)
    if msg.msgId == LUILogicEvent.interruptCollectUI then
        self:CloseUI()
    elseif msgId == LUIRoleDataChangeEvent.StartHangUp then
        self:CloseUI()
    end
end

function NPCCollectUI:IsHaveTemp(userData)
    if NPCCollectUI.tempData == nil then
        return false
    end

    local temp = {"npcId", "collectTip", "seconds", "serialNum", "pic"}
    for i=1,#temp do
        local k = temp[i]
        local tempValue = NPCCollectUI.tempData[k]
        local userValue = userData[k]
        if tempValue ~= nil and userValue ~= nil and tempValue ~= userValue then
            return false
        end
    end
    return true
end

function NPCCollectUI:UpdateUserData(userData)
    if userData and userData.collectTip then
        local tips = string.format(GUITips.RSI_COLLECT_TIPS, userData.collectTip)
        Utils:ShowScrollTips(tips)
    end
end

function NPCCollectUI:UpdateData(userData)
    -- self:DeleteScheduler()
    local collectTip = userData.collectTip

    self.m_tipLabel:setString(collectTip)
    self.m_tipLabel2:setString(collectTip)
    -- self.m_loadingBar:setPercent(0)
    self.m_time = userData.seconds
    if self:IsHaveTemp(userData) then
        self.m_curTime = NPCCollectUI.tempData.curTime
        local tips = string.format(GUITips.RSI_COLLECT_TIPS, collectTip)
        Utils:ShowScrollTips(tips)
    else
        NPCCollectUI.tempData = userData
        self.m_curTime = 0
    end
    self.m_curTime = self.m_curTime or 0
    --self.m_curTime = 0
    self.m_npcId = userData.npcId
    self.m_serialNum = userData.serialNum
    self.m_callback = userData.callback
    -- local type = userData.type or 1
    --self.m_Img:loadTexture(AppDef.GUIRes["Res_UI_Collect_Img"..type], ccui.TextureResType.localType)
    self.m_imgRes = "res2/Icon/ui_caozuo_icon/caozuo_" .. userData.pic..".png"
    local function LoadImgCallback(tex)
        if self.m_Img == nil then
            return
        end
        self.m_Img:setVisible(true)
        self.m_Img:loadTexture(self.m_imgRes, UI_TEX_TYPE_LOCAL)
    end
    self.m_Img:setVisible(false)
    Utils:AsyncLoadImg(self.m_Img,self.m_imgRes,LoadImgCallback)
    
    LRoleDataMgr.m_isNPCCollecting = true

    self:Loading()
    if NPCCollectUI.scheduler then
        Utils:unschedule(nil, NPCCollectUI.scheduler)
        NPCCollectUI.scheduler = nil
    end

    -- local function tick(dt)
    --     self.m_curTime = self.m_curTime + dt
    --     self:ShowProcess(self.m_curTime*100/self.m_time)
    --     if self.m_curTime >= self.m_time then
    --         self:CollectEnd()
    --     end
        
    -- end 

    -- self.m_schedulerID = AppDef.Director:getScheduler():scheduleScriptFunc(tick, 0.1, false)
end

function NPCCollectUI:Loading()
    local function collectEnd()
        self:CollectEnd()
    end 
    local progressBar = self.m_loadingBar:getChildByTag(1)
    if progressBar == nil then
        local pSp = cc.Sprite:createWithSpriteFrameName("res/UI/ui_common/ui_jindu_quan.png")
        progressBar = cc.ProgressTimer:create(pSp)
        progressBar:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
        progressBar:setAnchorPoint(self.m_Img:getAnchorPoint())
        progressBar:setPosition(cc.p(self.m_Img:getPosition()))
        self.m_loadingBar:addChild(progressBar)
        progressBar:setTag(1)
    end
    
    progressBar:setPercentage(self.m_curTime/self.m_time*100)
    local action = cc.Sequence:create(cc.ProgressTo:create(math.max(self.m_time-self.m_curTime, 0.01), 100), cc.CallFunc:create(collectEnd))
    progressBar:stopActionByTag(0xfd)
    action:setTag(0xfd)
    progressBar:runAction(action)
    
end

function NPCCollectUI:CollectEnd()
    --print("CollectEnd")
    local serNum = self.m_serialNum
    if self.m_callback then
        self.m_callback()
    else
        LuaNetSendMsg:QueryNpcChatOption(serNum)
    end
    NPCCollectUI.tempData = nil
    self:CloseUI()
end

function NPCCollectUI:DeleteScheduler()
    if self.m_schedulerID ~= nil then
        AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_schedulerID)
        self.m_schedulerID = nil
    end
end

function NPCCollectUI:InitData()
    local panel = self.m_pUILayer:getChildByName("Panel")
    local viewsize = AppDef.frameSize
    panel:setPositionX(viewsize.width / 2)
    self.m_pBgPanel = self.m_pUILayer:getChildByName("Panel_1")
    self.m_loadingBar = panel:getChildByName("GuildImageBg")
    self.m_Img = self.m_loadingBar:getChildByName("GuildImage")
    self.m_tipLabel = panel:getChildByName("TitleBg"):getChildByName("Text")
    self.m_tipLabel2 = self.m_loadingBar:getChildByName("NameBg"):getChildByName("Text")
    self.m_schedulerID = nil
    self.m_time = 0
    self.m_curTime = 0
    self.m_npcId = 0
    self.m_serialNum = 0
    self.m_imgRes = nil
end

function NPCCollectUI:CloseUI()
    LRoleDataMgr.m_isNPCCollecting = false
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, ScriptPath)
    self:SendMsg(LGameMsg.m_initUIMsg)
end

function NPCCollectUI:tempPercent()
    if NPCCollectUI.tempData and self.m_loadingBar then
        local progressBar = self.m_loadingBar:getChildByTag(1)
        if progressBar then
            NPCCollectUI.tempData.curTime = self.m_time * progressBar:getPercentage() / 100
            NPCCollectUI.scheduler = Utils:schedule(nil, function(dt)
                NPCCollectUI.tempData = nil
                Utils:unschedule(nil, NPCCollectUI.scheduler)
                NPCCollectUI.scheduler = nil
            end, 1, false)
        end
    end
end

function NPCCollectUI:InitTouchEvt()
    local function BgTouchedCallback(sender)
        self:tempPercent()
--        self:CloseUI()
    end
    -- self.m_pBgPanel:setTouchEnabled(false)
    self.m_pBgPanel:setSwallowTouches(false)
    self.m_pBgPanel:addClickEventListener(BgTouchedCallback)
	self:MarkIntaractCObj(self.m_pBgPanel)
end

function NPCCollectUI:InitViewSize()
    self:CreateUINode(CsbFilePath)
    -- self.m_pUILayer = cc.CSLoader:createNode(CsbFilePath)
    -- local viewsize = AppDef.Director:getVisibleSize()
    -- self.m_pUILayer:setContentSize(viewsize)
    -- ccui.Helper:doLayout(self.m_pUILayer)

    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end


function NPCCollectUI:onExit()
    if self.m_imgRes and string.len(self.m_imgRes) > 0 then
        Utils:UnbindAsyncImg(self.m_imgRes)
        self.m_imgRes = nil
    end
    self:Destory()
    self:DeleteScheduler()
    self.m_pBgPanel = nil
    self.m_loadingBar = nil
    self.m_tipLabel = nil
    self.m_tipLabel2 = nil
    self.m_schedulerID = nil
    self.m_Img = nil
    self.m_time = nil
    self.m_curTime = nil
    self.m_npcId = nil
    self.m_serialNum = nil
    self.m_callback = nil
end

function NPCCollectUI:ShowProcess(rate)
    self.m_loadingBar:setPercent(rate)
end

return NPCCollectUI