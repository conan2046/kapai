
local ShenZhuangShopUI = LUIBase:New()
ShenZhuangShopUI.__index = ShenZhuangShopUI

local WanFaShopDelegate = require("View.Shop.WanFaShopDelegate")

--local this = LTcpSocket
function ShenZhuangShopUI:New()
	local o = LUIBase:New()
	setmetatable(o,ShenZhuangShopUI)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function ShenZhuangShopUI:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function ShenZhuangShopUI:ProcessEvent(msg)

end

function ShenZhuangShopUI:Init()
    self:CreateUINode("csd/shop/wanfashop.csb")
    -- self.m_pUILayer = cc.CSLoader:createNode("csd/shop/wanfashop.csb")
    -- self.m_pUILayer:setContentSize(AppDef.frameSize)
    -- ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:initControlUI()
end

function ShenZhuangShopUI:initControlUI( ... )
    local value = {}
    value.size = 4
    self._WanFaShopDelegate = WanFaShopDelegate:New({pUILayer=self.m_pUILayer, value = value})
end

function ShenZhuangShopUI:CloseUI( ... )
    -- body
    Utils:DeleteUI("HappyDraw.ShenZhuangShopUI")
end

function ShenZhuangShopUI:onExit()
    self._WanFaShopDelegate:onExit()
    self.m_pUILayer = nil
    print("ShenZhuangShopUI ===================== 111111111111>")
    self:Destory()
end

return ShenZhuangShopUI