
local MasterUI = LUIBase:New()
MasterUI.__index = MasterUI
--local this = LTcpSocket
function MasterUI:New()
	local o = LUIBase:New()
	setmetatable(o,MasterUI)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function MasterUI:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function MasterUI:ProcessEvent(msg)

end

function MasterUI:Init()

    self.m_pUILayer = cc.CSLoader:createNode("csd/SocialLayer.csb")
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
end

function MasterUI:initControlUI( ... )
    -- body
    local Popup = self.m_pUILayer:getChildByName("Popup")
    local Btn_close = Popup:getChildByName("Btn_close")
    Btn_close:addClickEventListener(function ( sender )
        -- body
        self:CloseUI()
    end)
end

function MasterUI:CloseUI( ... )
    -- body
    Utils:DeleteUI("HappyDraw.MasterUI")
end

function MasterUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return MasterUI