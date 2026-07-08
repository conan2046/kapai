--[[
lua里面的游戏逻辑控制
]]

local GameNoticeUI = LUIBase:New()
GameNoticeUI.__index = GameNoticeUI

function GameNoticeUI:New(str)
	local o = LUIBase:New()
	setmetatable(o,GameNoticeUI)	
    o:Init(str)
	return o
end

function GameNoticeUI:Init(str)
    self.Script = "Login.GameNoticeUI"
    ----------------------------------------------------------------
    self.m_pUILayer = cc.CSLoader:createNode("csd/GameNoticeLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    ----------------------------------------------------------------
    self:InitData(str)
    self:AddTouchEvt()
end

function GameNoticeUI:onExit()
    self:Destory()
end

function GameNoticeUI:InitData(str)
    local pScrollView = Utils:FindNodeByName(self.m_pUILayer, "GameNotice/bg/BgImage/ScrollView")
    local pText = Utils:FindNodeByName(self.m_pUILayer, "GameNotice/bg/Text")
    if pScrollView and pText then
        pScrollView:setScrollBarEnabled(false)

        local size = pText:getContentSize()
        local fontFilePath = pText:getFontName()
        local fontSize = pText:getFontSize()
        local color = pText:getTextColor()

        local pLabel = cc.Label:createWithTTF(str, fontFilePath, fontSize, cc.size(size.width, 0))
        pLabel:setTextColor(color)
        pLabel:setIgnoreAnchorPointForPosition(false)
        pLabel:setAnchorPoint(cc.p(0, 1))
        pLabel:setLineSpacing(6)

        local pTextSize = pLabel:getContentSize()
        local pInnerSize = pScrollView:getInnerContainerSize()
        if pTextSize.height > pInnerSize.height then
            pScrollView:setInnerContainerSize(cc.size(pInnerSize.width, pTextSize.height))
        end
        pLabel:setPosition(cc.p(0, pScrollView:getInnerContainerSize().height))
        pScrollView:addChild(pLabel)

        pText:removeFromParent(true)
    end

    local action = cc.CSLoader:createTimeline("csd/GameNoticeLayer.csb")
    action:gotoFrameAndPlay(0)
    self.m_pUILayer:runAction(action)
end

function GameNoticeUI:AddTouchEvt()
    local pCloseBtn = Utils:FindNodeByName(self.m_pUILayer, "GameNotice/bg/Title/Button_1")
    pCloseBtn:addClickEventListener(function(sender)
        self:RemoveUI()
    end)
	self:MarkIntaractCObj(pCloseBtn)
    local pButton = Utils:FindNodeByName(self.m_pUILayer, "GameNotice/bg/Button")
    pButton:addClickEventListener(function(sender)
        self:RemoveUI()
    end)
	self:MarkIntaractCObj(pButton)
end

return GameNoticeUI