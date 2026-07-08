--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
local TouchUI = LUIBase:New()
TouchUI.__index = TouchUI
TouchUI.IsHideInBattle = true
function TouchUI:New()
	local o = {}
    setmetatable(o, TouchUI)
    o:Init()
	return o
end

function TouchUI:Init()
	self.m_pUILayer = cc.CSLoader:createNode("csd/TouchLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
	local panel = self.m_pUILayer:getChildByName("TouchLayer")
	panel:setTouchEnabled(true)
    panel:setSwallowTouches(false)
    panel:addClickEventListener(function(sender)
        --print("==============touch==============")
		LGameMsg.m_baseMsg:ChangeEventId(LUILogicEvent.RoleActiveGame)
		self:SendMsg(LGameMsg.m_baseMsg)
    end)
	self:MarkIntaractCObj(panel)
end

return TouchUI

--endregion
