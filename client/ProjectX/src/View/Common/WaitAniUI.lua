--滚动信息提示界面
local WaitAniUI = LUIBase:New()
WaitAniUI.__index = WaitAniUI
--local this = LTcpSocket
function WaitAniUI:New(userData)
    local o = LUIBase:New()
    setmetatable(o,WaitAniUI)   
    o:Init(userData)
    return o
end

function WaitAniUI:Init(userData)
    --self.m_pUILayer = cc.CSLoader:createNode("csd/LoginBgLayer.csb")
   	self.m_VecKeys = {}
	self.m_LayerTarget = nil
    self.m_DisplayBG = nil
    self.m_pMsgLabel = nil
    self.m_pAni = nil
    -- self.m_pUILayer = cc.Node:create()
    -- self.m_pUILayer:setContentSize(AppDef.frameSize)

    self.m_pUILayer = ccui.Layout:create()
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    self.m_pUILayer:setTouchEnabled(false)
    --self.m_pUILayer:addChild( self.m_DisplayBG)


    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    if userData ~= nil then
        self:SetUserData(userData)
    end

end

--[[
注册UI消息
]]
function WaitAniUI:RegistMsgs()
    self.msgIds = 
    {
        LUIWaitAni.ShowWait,
        LUIWaitAni.ClearWait,
        LUIWaitAni.ForceClearWait,
    }
    self:RegistSelf(self,self.msgIds)
end

function WaitAniUI:ProcessEvent(msg)
    
    if msg:GetMsgId() == LUIWaitAni.ShowWait then
        self:SetUserData(msg.value)
    elseif msg:GetMsgId() == LUIWaitAni.ClearWait then
        self:RemoveWaitAnimation(msg.value)
    elseif msg:GetMsgId() == LUIWaitAni.ForceClearWait then
        self:ClearWaitAni()
    end
end



function WaitAniUI:onExit()
    self:Destory()
    self:UnSchedule()
    self.m_waitKey = nil
	self.m_LayerTarget = nil
    self.m_DisplayBG = nil
    self.m_pAni = nil
    self.m_pMsgLabel = nil
    self.m_pUILayer = nil
end


function WaitAniUI:SetUserData(userData)
	--int key, const char* waitMsg=RES_STRC(DataConsts::RIS_LEFTUI_MSG51), WaitType waitType = WAIT_DEFAUIT, float autoClearTime = 10.0f
	table.insert(self.m_VecKeys,userData.key)
	self:createAnimation(userData.waitMsg, userData.autoClearTime)
end

function WaitAniUI:UpdateUserData(userData)
	self.m_waitKey = userData.key
	self:createAnimation(userData.waitMsg, userData.autoClearTime)
end

function WaitAniUI:RemoveWaitAnimation(key)
	if self.m_waitKey == nil or self.m_waitKey == key then
		self:ClearWaitAni()
	end
end

function WaitAniUI:ClearWaitAni()
    self.m_pUILayer:setTouchEnabled(false)
    self.m_waitKey = nil
    self:ClearAnimation()
    self:UnSchedule()   
end

function WaitAniUI:UpdateWait(waitMsg, autoClearTime)
    self.m_DisplayBG:setVisible(true)
    self.m_pAni:PlayActionRepeat(0, 0.1, true)
	self:UpdateMsg(waitMsg)
    self.m_pUILayer:setTouchEnabled(true)
	self:SetAutoClear(autoClearTime)
end

function WaitAniUI:SetAutoClear(autoClearTime)
	self:UnSchedule()
	local function OnAutoClearUpdate(dt)
		self:OnAutoClearUpdate(dt)
	end
	if autoClearTime ~= nil and autoClearTime > 0 then
		self.OnAutoClearUpdateEntry = AppDef.Director:getScheduler():scheduleScriptFunc(OnAutoClearUpdate,autoClearTime,false)
	end
end

function WaitAniUI:createAnimation(waitMsg, autoClearTime)
    if self.m_DisplayBG ~= nil then
        
    	self:UpdateWait(waitMsg, autoClearTime)
		return
	end

    self.m_DisplayBG = cc.Sprite:create("waiting_tip_bg.png")
    self.m_DisplayBG:setPosition(cc.p(AppDef.frameSize.width/2, AppDef.frameSize.height/2))
    self.m_pUILayer:addChild( self.m_DisplayBG)

    local bgSize =  self.m_DisplayBG:getContentSize()

    --
	local displayAni = ImodAnim:createWithFileSync("jiazaiquan")
	displayAni:PlayActionRepeat(0, 0.1, true);
	displayAni:setPosition(cc.p(bgSize.width/2, 50));  --bgSize,适配CC_WINSIZE
	displayAni:setAnchorPoint(cc.p(0.5,0.5));
	displayAni:setScale(0.6);
	self.m_DisplayBG:addChild(displayAni, 1, 100);
    self.m_pAni = displayAni

	local labelMsg = cc.Label:createWithSystemFont(waitMsg, AppDef.FNT_NAME, AppDef.UIFONTSIZELB);
	labelMsg:setColor(cc.c3b(255,255,255))
	labelMsg:setPosition(cc.p(bgSize.width/2, bgSize.height - 40))
	self.m_DisplayBG:addChild(labelMsg, 1, 101)
    self.m_pMsgLabel = labelMsg
    --
    self:SetAutoClear(autoClearTime)
   
	self.m_pUILayer:setTouchEnabled(true)
end

function WaitAniUI:ClearAnimation()
    self.m_DisplayBG:setVisible(false)
    self.m_pMsgLabel:setString("")
    self.m_pAni:stopCurrentAni()
 --    if self.m_DisplayBG then
 --        self.m_DisplayBG:removeFromParent()
 --        self.m_DisplayBG = nil
	-- end

 --    if self.m_pMsgLabel then
 --        self.m_pMsgLabel = nil
 --    end

    -- if self.m_pAni then
    --     self.m_pAni:stop()
    -- end
end

function WaitAniUI:UnSchedule()
	if self.OnAutoClearUpdateEntry then
		AppDef.Director:getScheduler():unscheduleScriptEntry(self.OnAutoClearUpdateEntry)
		self.OnAutoClearUpdateEntry  = nil
	end
end

function WaitAniUI:OnAutoClearUpdate(dt)
	self:UnSchedule()
    
	self.m_pUILayer:setTouchEnabled(false)
	
    self:ClearAnimation()
end

function WaitAniUI:UpdateMsg(waitMsg)
    if self.m_DisplayBG == nil then
    	return
    end
    if self.m_pMsgLabel then
        self.m_pMsgLabel:setString(waitMsg)
    end
    -- local lbMsg = self.m_DisplayBG:getChildByTag(101)
    -- if lbMsg ~= nil then
    --     lbMsg:setString(waitMsg)
    -- end
end

return WaitAniUI