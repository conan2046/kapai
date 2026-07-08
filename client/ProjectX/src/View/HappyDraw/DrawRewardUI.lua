
local DrawRewardUI = LUIBase:New()
DrawRewardUI.__index = DrawRewardUI
--local this = LTcpSocket
function DrawRewardUI:New()
	local o = LUIBase:New()
	setmetatable(o,DrawRewardUI)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function DrawRewardUI:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function DrawRewardUI:ProcessEvent(msg)

end

function DrawRewardUI:Init()

    self.m_pUILayer = cc.CSLoader:createNode("csd/chouka/jiangliyulan.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

end

function DrawRewardUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return DrawRewardUI