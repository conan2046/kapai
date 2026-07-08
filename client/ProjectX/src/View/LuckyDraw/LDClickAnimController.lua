local LDClickAnimController = {}
LDClickAnimController.__index = LDClickAnimController

--[[
data:
{
    rootUI:根节点UI，为了设置关闭回调
    nodes:{node,...}
    callback:选中回调
}
]]
-------------------------------------
function LDClickAnimController:New(data)
    local o = {}
    setmetatable(o, LDClickAnimController)
    o:Init(data)
    return o
end

-------------------------------------
function LDClickAnimController:Init(data)
    ------------------------------------------------
    self.m_schedule = nil
    self.m_pDrawNode = nil
    ------------------------------------------------
    self.m_selected = 0
    self.m_itemMap = {}--节点Map
    self.m_itemIndexVec = {}--索引Vector
    self.m_preItemIndexVec = {}--上一次索引Vector
    self.m_center = 0 --第几个是中间位置
    self.m_gotoIndex = 0--下一次的中间位置索引,大于0表示正在播放动画
    self.m_posVec = {}
    self.m_pSelectCallback = nil--选中回调
    if data then
        self:updateConfig(data)
        self:setCloseCallback()
    end
end

function LDClickAnimController:updateConfig(data)
    if data then
        self.m_pUILayer = data.rootUI
        self.m_center = math.floor((#data.nodes+1)/2)
        for i=1,#data.nodes do
            local node = data.nodes[i]
            local tag = node:getTag()
            self.m_itemMap[tag] = node
            table.insert(self.m_itemIndexVec, tag)
        end
        self.m_pSelectCallback = data.callback
        self:setCloseCallback()
        self:initPos()

        -- local draw = cc.DrawNode:create()
        -- self.m_pUILayer:addChild(draw, 10)
        -- self.m_pDrawNode = draw
    end
end

-------------------------------------
function LDClickAnimController:onExit()
    if self.m_schedule ~= nil then
        self.m_pUILayer:stopAction(self.m_schedule)
        self.m_schedule = nil
    end
    self.m_pUILayer = nil
    self.m_preItemIndexVec = nil
    self.m_posVec = nil
    self.m_center = nil
    self.m_itemMap = nil
    self.m_pSelectCallback = nil
    self.m_pDrawNode = nil
end

function LDClickAnimController:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    if self.m_pUILayer then
        self.m_pUILayer:registerScriptHandler(onNodeEvent)
    end
end

--设置选中
function LDClickAnimController:setSelectIndex(index)
    if self.m_selected == index then
        return
    end
    self.m_selected = index
    self.m_gotoIndex = nil
    if self.m_pSelectCallback then
        self.m_pSelectCallback(index)
    end
end

--炉子被点击
function LDClickAnimController:itemClick(index, isImmediately)
    -- print(index, self.m_selected, isImmediately)
    if self.m_selected == index or index < 0 then
        return
    end
    if isImmediately then
        self:setCenterIndex(index)
        self:animFinished()
        self:setSelectIndex(index)
        return
    end

    if self.m_gotoIndex then
        self:animFinished()
    end
    self:setCenterIndex(index)
    self:startAnim()
    self.m_gotoIndex = index
end

--获取队列中间的索引
function LDClickAnimController:getCurCenterIndex()
    return self.m_itemIndexVec[self.m_center]
end
--查找Index在队列中的索引
function LDClickAnimController:findIndex(index)
    for i=1,#self.m_itemIndexVec do
        if self.m_itemIndexVec[i] == index then
            return i
        end
    end
    return nil
end
--设置中间索引，重新排列索引队列
function LDClickAnimController:setCenterIndex(index)
    local curCenter = self.m_center
    local curIndex = self:findIndex(index)
    if curIndex == curCenter then
        return
    end
    self.m_preItemIndexVec = clone(self.m_itemIndexVec)
    local isAtLeft = curIndex < curCenter
    if isAtLeft then
        for i=1,curCenter-curIndex do
            local v = self.m_itemIndexVec[#self.m_itemIndexVec]
            table.remove(self.m_itemIndexVec, #self.m_itemIndexVec)
            table.insert(self.m_itemIndexVec, 1, v)
        end
    else
        for i=1,curIndex-curCenter do
            local v = self.m_itemIndexVec[1]
            table.remove(self.m_itemIndexVec, 1)
            table.insert(self.m_itemIndexVec, v)
        end
    end
end
--动画结束，设置结束位置坐标
function LDClickAnimController:animFinished()
    if self.m_gotoIndex then
        for i=1,#self.m_itemIndexVec do
            local item = self.m_itemMap[self.m_itemIndexVec[i]]
            item:stopActionByTag(123)
            item:setPosition(self.m_posVec[i])
        end
        self.m_gotoIndex = nil
    end
end
--开始转动
function LDClickAnimController:startAnim()
    local animCfg = {}
    for i=1,#self.m_preItemIndexVec do
        local pre = self.m_preItemIndexVec[i]
        for j=1,#self.m_itemIndexVec do
            local cur = self.m_itemIndexVec[j]
            if pre == cur then
                table.insert(animCfg, {pre, i, j})
            end
        end
    end

    local function animFinished()
        performWithDelay(self.m_pUILayer, function(dt)
            -- self:animFinished()
            self:setSelectIndex(self:getCurCenterIndex())
        end, 1/30)
    end

    -- self.m_pDrawNode:clear()
    local offset = 75
    local lastIndex = #animCfg
    for i=1,lastIndex do
        local pair = animCfg[i]
        local tag = pair[1]
        local pre = pair[2]
        local cur = pair[3]
        local item = self.m_itemMap[tag]
        if item then
            local prePoint = self.m_posVec[pre]
            local curPoint = self.m_posVec[cur]
            local vec = cc.pSub(prePoint, curPoint)
            local fVec = nil
            if pre > cur then
                if cur == 1 and pre == lastIndex then
                    item:setLocalZOrder(0)
                    fVec = cc.pMul(cc.pNormalize(cc.pPerp(vec)), 50)
                else
                    item:setLocalZOrder(1)
                    fVec = cc.pMul(cc.pNormalize(cc.RPerp(vec)), offset)
                end
            else
                if pre == 1 and cur == lastIndex then
                    item:setLocalZOrder(0)
                    fVec = cc.pMul(cc.pNormalize(cc.RPerp(vec)), 50)
                else
                    item:setLocalZOrder(1)
                    fVec = cc.pMul(cc.pNormalize(cc.pPerp(vec)), offset)
                end
            end

            local ctrlPoint1 = cc.pAdd(fVec, prePoint)
            local ctrlPoint2 = cc.pAdd(fVec, curPoint)
            local bezierCfg = {ctrlPoint1, ctrlPoint2, curPoint}
            item:stopActionByTag(123)
            local bezierAc = cc.EaseSineOut:create(cc.BezierTo:create(0.5, bezierCfg))
            local action = nil
            if i == #animCfg then
                local pCallfunc = cc.CallFunc:create(animFinished)
                action = cc.Sequence:create(bezierAc, pCallfunc)
            else
                action = bezierAc
            end
            action:setTag(123)
            item:runAction(action)

            -- self.m_pDrawNode:drawCubicBezier(prePoint, ctrlPoint1,ctrlPoint2, curPoint,100, cc.c4f(1,0,0,1))
        end
    end
end

function LDClickAnimController:initPos()
    local center = cc.p(self.m_pUILayer:getContentSize().width/2, self.m_pUILayer:getContentSize().height/2)
    local centerIndex = self.m_center
    local spaceX = 50
    local spaceY = 50
    local width = nil
    local y = self.m_pUILayer:getContentSize().height/2

    for i=1,#self.m_itemIndexVec do
        local index = self.m_itemIndexVec[i]
        local item = self.m_itemMap[index]
        if width == nil then
            width = item:getContentSize().width
        end
        local _x = center.x + (i-centerIndex)*(width+spaceX)
        local _y = y + math.min(math.abs(i-centerIndex), 1)*spaceY
        table.insert(self.m_posVec, cc.p(_x, _y))
    end
end

function LDClickAnimController:isAniming()
    return self.m_gotoIndex ~= nil
end

return LDClickAnimController