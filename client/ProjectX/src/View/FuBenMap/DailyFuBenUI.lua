
local DailyFuBenUI = LUIBase:New()
DailyFuBenUI.__index = DailyFuBenUI
--local this = LTcpSocket
function DailyFuBenUI:New()
	local o = LUIBase:New()
	setmetatable(o,DailyFuBenUI)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function DailyFuBenUI:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function DailyFuBenUI:ProcessEvent(msg)

end

function DailyFuBenUI:Init()

    self.m_pUILayer = cc.CSLoader:createNode("csd/SocialLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

end

function DailyFuBenUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return DailyFuBenUI