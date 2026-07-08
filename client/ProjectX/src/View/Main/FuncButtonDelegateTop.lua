local FuncButtonDelegateTop = LUIBase:New()
FuncButtonDelegateTop.__index = FuncButtonDelegateTop

function FuncButtonDelegateTop:New(cfg)
	local o = {}
	setmetatable(o, FuncButtonDelegateTop)
	o:Init(cfg)
	return o
end

function FuncButtonDelegateTop:Init(cfg)
    self.m_config = cfg
    self.m_data = {}
    if cfg then
        if cfg.btn then
            local pos = cc.p(cfg.btn:getContentSize().width/2, cfg.btn:getContentSize().height/2)
            self.m_btnpos = cfg.btn:convertToWorldSpace(pos)
        end
        if cfg.groups then
            for i=1,#cfg.groups do
                local pGroup = cfg.groups[i]
                local btns = pGroup:getChildren()
                for j=1,#btns do
                    if btns[j] then
                        self.m_data[btns[j]:getName()] = btns[j]:getPositionY()
                    end
                end
            end
        end
    end
    self:RegistMsgs()
end

function FuncButtonDelegateTop:onExit()
    self:Destory()
end

function FuncButtonDelegateTop:RegistMsgs()
    self.msgIds = 
    {
        LUIMainEvent.ISOpenTopBtn,
        LUIMainEvent.OpenOrCloseTopBtn,
        LUIRedDotEvent.UpdateRedDotState,
    }
    self:RegistSelf(self,self.msgIds)
end

function FuncButtonDelegateTop:ProcessEvent(msg)
    if msg.msgId == LUIMainEvent.OpenOrCloseTopBtn then
        if msg.value then
            self:Open()
        else
            self:Close()
        end
    elseif msg.msgId == LUIRedDotEvent.UpdateRedDotState then
        self:DealUpdateRedDotState(msg.value)
    elseif msg.msgId == LUIMainEvent.ISOpenTopBtn then
        local ret = msg.value
        ret.isOpen = not self.m_config.isClose
    end
end

function FuncButtonDelegateTop:ShowGroupAnim(pGroup, isShow, callback)
    if pGroup == nil then
        return
    end
    local duration = 0.1
    local arr = {}
    if isShow then
        table.insert(arr, cc.FadeTo:create(duration, 255))
        if callback then
            table.insert(arr, cc.CallFunc:create(callback))
        end
        pGroup:stopAllActions()
        pGroup:runAction(cc.Sequence:create(arr))
    else
        table.insert(arr, cc.FadeTo:create(duration, 0))
        if callback then
            table.insert(arr, cc.CallFunc:create(callback))
        end
        pGroup:stopAllActions()
        pGroup:runAction(cc.Sequence:create(arr))
    end
end

function FuncButtonDelegateTop:ShowGroupBtnMoveAnim(pBtn, pos, initpos)
    if pBtn == nil or pos == nil or (pBtn:isVisible() == false) then
        return
    end
    local duration = 0.15
    local arr = {}
    table.insert(arr, cc.MoveTo:create(duration, pos))
    
    if initpos then
        pBtn:setPosition(initpos)
    end
    pBtn:stopAllActions()
    pBtn:runAction(cc.Sequence:create(arr))
end

function FuncButtonDelegateTop:ShowAllGroupBtnMoveAnim(pGroup, pos)
    if pGroup == nil then
        return
    end
    pos = pGroup:convertToNodeSpace(pos)
    local btns = pGroup:getChildren()
    for i=1,#btns do
        self:ShowGroupBtnMoveAnim(btns[i], pos)
    end
end

function FuncButtonDelegateTop:ButtonClick()
    local data = self.m_config
    if data == nil or data.btn == nil then
        return
    end
    
    if data.isClose then
        self:Open()
    else
        self:Close()
    end
end

function FuncButtonDelegateTop:Open()
    local data = self.m_config
    if data == nil or data.btn == nil or (not data.isClose) then
        return
    end

    for i=1,#data.groups do
        local pGroup = data.groups[i]
        self:ShowGroupAnim(pGroup, true, function()
            pGroup:setOpacity(255)
        end)
    end

    local pArraw = data.btn:getChildByName("Jiantou")
    pArraw:setVisible(false)

    local pRedDot = self.m_config.btn:getChildByName("Prompt")
    if pRedDot then
        pRedDot:setVisible(false)
    end

    for i=1,#data.groups do
        local pGroup = data.groups[i]
        local btns = pGroup:getChildren()
        local rNodes,xes = Utils:GetAlignPos(pGroup, btns, {0}, 1)
        local initpos = pGroup:convertToNodeSpace(self.m_btnpos)
        for j=1,#rNodes do
            self:ShowGroupBtnMoveAnim(rNodes[j], cc.p(xes[j], self.m_data[rNodes[j]:getName()] or 0), initpos)
        end
    end
    data.isClose = false
end

function FuncButtonDelegateTop:Close()
    local data = self.m_config
    if data == nil or data.btn == nil or data.isClose then
        return
    end

    for i=1,#data.groups do
        local pGroup = data.groups[i]
        self:ShowGroupAnim(pGroup, false, function()
            pGroup:setOpacity(0)
        end)
    end
    local pArraw = data.btn:getChildByName("Jiantou")
    pArraw:setVisible(true)

    local pRedDot = self.m_config.btn:getChildByName("Prompt")
    if pRedDot then
        pRedDot:setVisible(Utils:GetRedDotState(RedDotDef.ID.DingBu))
    end

    for i=1,#data.groups do
        self:ShowAllGroupBtnMoveAnim(data.groups[i], self.m_btnpos)
    end
    data.isClose = true
end

function FuncButtonDelegateTop:SetButtionVisible(isVisible)
    if self.m_config and self.m_config.btn ~= nil then
        self.m_config.btn:setVisible(isVisible)
    end
end

function FuncButtonDelegateTop:DealUpdateRedDotState(data)
    if data == nil then
        return
    end
    if data.id == RedDotDef.ID.DingBu then
        local pRedDot = self.m_config.btn:getChildByName("Prompt")
        if pRedDot then
            if data.isShow then
                if self.m_config.isClose then
                    pRedDot:setVisible(true)
                else
                    pRedDot:setVisible(false)
                end
            else
                pRedDot:setVisible(false)
            end
        end
    end
end

return FuncButtonDelegateTop