
local AccessWayUI = LUIBase:New()
AccessWayUI.__index = AccessWayUI
--local this = LTcpSocket
function AccessWayUI:New()
	local o = LUIBase:New()
	setmetatable(o,AccessWayUI)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function AccessWayUI:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function AccessWayUI:ProcessEvent(msg)

end

function AccessWayUI:Init()

    self.m_pUILayer = cc.CSLoader:createNode("csd/common/huoqutujing.csb")
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

function AccessWayUI:initControlUI( ... )
    -- body
    local Popup = self.m_pUILayer:getChildByName("Popup")
    local Btn_close = Popup:getChildByName("Btn_close")
    Btn_close:addClickEventListener(function ( sender )
        -- body
        self:CloseUI()
    end)
end

function AccessWayUI:CloseUI( ... )
    -- body
    Utils:DeleteUI("HappyDraw.AccessWayUI")
end

function AccessWayUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return AccessWayUI