--信息走马灯界面（底部）
local FloatNoticeUI = LUIBase:New()
FloatNoticeUI.__index = FloatNoticeUI

function FloatNoticeUI:New()
    local o = LUIBase:New()
    setmetatable(o,FloatNoticeUI)   
    o:Init()
    return o
end

function FloatNoticeUI:Init()
    --self.m_pUILayer = cc.CSLoader:createNode("csd/LoginBgLayer.csb")
    --self.m_TipNodeTable = {}
    self.m_IsTiping = false

    self.m_pUILayer = cc.Node:create()
    self:InitLayout()

    -- local frameSize = cc.Director:getInstance():getVisibleSize()
    -- local pos = cc.p(frameSize.width/2,frameSize.height/2)
    -- self.m_pUILayer:setPosition(pos)

    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    LRoleDataMgr.m_isEnterIngForeground = false
    self._backToForegroundListener = cc.EventListenerCustom:create("event_come_to_foreground", function (eventCustom)
        -- body
        print("this is a enter foreground test")
        LRoleDataMgr.m_isEnterIngForeground = true
        self:perfromWithDelayEveny()
    end)
    AppDef.Director:getEventDispatcher():addEventListenerWithFixedPriority(self._backToForegroundListener, -1)

end

function FloatNoticeUI:perfromWithDelayEveny( ... )
    -- body
    performWithDelay(self.m_pUILayer, function(sender)
        LRoleDataMgr.m_isEnterIngForeground = false
    end, 1)

end

function FloatNoticeUI:onExit()
    self.m_pUILayer = nil
    self.m_bottomLayout = nil
    self.m_pText = nil
    self.m_IsTiping = nil
    self.m_pTipsArr = nil
    self:Destory()
end

function FloatNoticeUI:SetTexts(tips)
    if LRoleDataMgr.m_isEnterIngForeground then
        return
    end
    if not self.m_pUILayer:isVisible() then
        self.m_pUILayer:setVisible(true)
    end
    if self.m_pTipsArr == nil then
        self.m_pTipsArr = {}
    end
    
    if not self.m_IsTiping then
        self:CreateTips(tips)
        self.m_IsTiping = true
    elseif  #self.m_pTipsArr < AppDef.MAX_MSG_NUM then
        table.insert(self.m_pTipsArr,tips)
    end
    
end

function FloatNoticeUI:CreateTips(msg)
    self:OnTipsShow(msg)
end

--文字显示处理
function FloatNoticeUI:OnTipsShow(msg)
    local function MoveOut(sender)
        self:OnTipsMoveOut(sender)
    end

    local function GetDelayTime()
        local size = #self.m_pTipsArr
        if size == 0 then
            --只有当前一条时，显示时间为5
            return 5
        end 
        --根据消息数目动态调整显示时间(小于1/10时4秒,小于1/3时1.5秒，小于2/3时0.5秒，其余0.1秒)
        local msgRate = #self.m_pTipsArr / AppDef.MAX_MSG_NUM
        local delayTime = 0.1
        if msgRate < 0.1 then
            delayTime = 4
        elseif msgRate <1/3 then
            delayTime = 1.5
        elseif msgRate <2/3 then
            delayTime = 0.5
        end
        return delayTime
    end
    local node = self:GetTipsNode(msg)
    --local x = node:getPositionX()
    local moveIn = cc.MoveBy:create(0.3,cc.p(0,AppDef.UIFONTSIZELB*1.2))
    local textWidth = node:getSize().width
    if textWidth > AppDef.frameSize.width*0.9 then
        --消息滚动
        local sequence = transition.sequence({
            cc.EaseSineIn:create(moveIn),
            cc.MoveTo:create(4,cc.p(AppDef.frameSize.width*0.9 - textWidth,AppDef.UIFONTSIZELB*1.2)),
            cc.DelayTime:create(1),
            cc.CallFunc:create(MoveOut)
        })
        node:runAction(sequence)
        return
    end

    --消息显示
    local delayTime = GetDelayTime(textWidth)
    local sequence = transition.sequence({
        cc.EaseSineIn:create(moveIn),
        cc.DelayTime:create(delayTime),
        cc.CallFunc:create(MoveOut)
    })
    node:runAction(sequence)

end

function FloatNoticeUI:OnTipsMoveOut(pSender)
    local function ShowEnd(sender)
        --sender:removeFromParent()
        self:CloseUI()
    end
    local function ShowNext(sender)
        --sender:removeFromParent()
        self:OnTipsNext()
    end
    local x = pSender:getPositionX()
    local moveOut = cc.MoveTo:create(0.2,cc.p(x,AppDef.UIFONTSIZELB*2))
    local lastMove = cc.MoveTo:create(0.2,cc.p(x,-AppDef.UIFONTSIZELB))
    local callfun = cc.CallFunc:create(ShowEnd)
    local callfun2 = cc.CallFunc:create(ShowNext)
    if #self.m_pTipsArr == 0 then
        --最后一个消息，向下消失
        pSender:runAction(cc.Sequence:create(cc.EaseSineOut:create(lastMove),callfun))
    else
        --正常消息，向上消失
        pSender:runAction(cc.Sequence:create(cc.EaseBackOut:create(moveOut),callfun2))
    end
end

function FloatNoticeUI:OnTipsNext()
    local msg = table.remove(self.m_pTipsArr,1)
    self:OnTipsShow(msg)
end

function FloatNoticeUI:GetTipsNode(msg)
    
    -- local ttf = CCAysLabel:create()
    -- ttf:transToShadowColor(true)
    -- ttf:triggleInit(msg,cc.size(AppDef.frameSize.width*2,0),-130,UICOLOR_WHITE,AppDef.UIFONTSIZELB,false,0,0,0,true,false)
    -- self.m_bottomLayout:addChild(ttf,1,1)
    -- local posX = 0
    -- if AppDef.frameSize.width*0.9 >= ttf:getSize().width then
    --     posX = (AppDef.frameSize.width*0.9 - ttf:getSize().width)/2
    -- end
    -- ttf:setAnchorPoint(cc.p(0,0))
    -- ttf:setPosition(cc.p(posX, 0))
    -- --print(ttf:getSize().width)
    self.m_pText:setString(msg)
    local width = self.m_pText:getSize().width
    local posX = 0
    if AppDef.frameSize.width*0.9 >= width then
        posX = (AppDef.frameSize.width*0.9 - width)/2
    end
    self.m_pText:setPosition(cc.p(posX, 0))
    return self.m_pText
end

function FloatNoticeUI:InitLayout()
    local layout = ccui.Layout:create()
    layout:setContentSize(cc.size(AppDef.frameSize.width*0.9,AppDef.UIFONTSIZELB*1.5))
    layout:setAnchorPoint(cc.p(0,0))
    layout:setPosition(cc.p(70, 0))
    --layout:setBackGroundColorOpacity(0)
    layout:setClippingEnabled(true)
    layout:setBackGroundImageScale9Enabled(true)
    local bgImage = "res/UI/ui_shenjiang/ui_shenjiang_tips.png"
    layout:setBackGroundImage(bgImage,ccui.TextureResType.plistType)

    self.m_pUILayer:addChild(layout)
    self.m_bottomLayout = layout

    self.m_pText = CCAysLabel:createWithFixedWidth(AppDef.frameSize.width*2,AppDef.UIFONTSIZELB,UICOLOR_WHITE,false)
    self.m_pText:transToShadowColor(true)
    self.m_pText:setAnchorPoint(cc.p(0,0))
    self.m_bottomLayout:addChild(self.m_pText,1,1)
end

function FloatNoticeUI:CloseUI()
--    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Common.FloatNoticeUI")
--    self:SendMsg(LGameMsg.m_initUIMsg)
    self.m_pUILayer:setVisible(false)
    while #self.m_pTipsArr > 0 do
        table.remove(self.m_pTipsArr,1)
    end
    self.m_IsTiping = false
end

return FloatNoticeUI