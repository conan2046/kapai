local LDPosAnimController = {}
LDPosAnimController.__index = LDPosAnimController

--[[
data:
{
    rootUI:根节点UI，为了设置关闭回调
    nodes:{node,...}
}
]]
-------------------------------------
function LDPosAnimController:New(data)
    local o = {}
    setmetatable(o, LDPosAnimController)
    o:Init(data)
    return o
end

-------------------------------------
function LDPosAnimController:Init(data)
    self.m_center = cc.p(0, 0)
    self.m_centerIndex = 0
    self.m_space = 0
    self.m_prePosition = {}--上一帧的位置
    self.m_posVec = {}--固定位置
    self.m_ctrlPos1 = {}--控制点1位置，[1]左->右(上) [2]右->左
    self.m_ctrlPos2 = {}--控制点2位置，[1]左->右(上) [2]右->左
    ------------------------------------------------
    self.m_schedule = nil
    ------------------------------------------------
    self.m_itemMap = {}--节点Map
    if data then
        self:updateConfig(data)
        self:setCloseCallback()
    end
end

function LDPosAnimController:updateConfig(data)
    if data then
        ---------------------------------------------------------
        self.m_pUILayer = data.rootUI
        self.m_center = cc.p(self.m_pUILayer:getContentSize().width/2, self.m_pUILayer:getContentSize().height/2)
        self.m_centerIndex = math.floor((#data.nodes+1)/2)
        ---------------------------------------------------------
        for i=1,#data.nodes do
            local node = data.nodes[i]
            local tag = node:getTag()
            self.m_itemMap[tag] = node
        end
        if #data.nodes > 1 then
            self.m_space = math.abs(cc.p(data.nodes[1]:getPosition()).x - cc.p(data.nodes[2]:getPosition()).x)
        end
        self:initPos()
        ---------------------------------------------------------
        self:setCloseCallback()
        ---------------------------------------------------------
        if self.m_schedule ~= nil then
            Utils:unschedule(nil, self.m_schedule)
            self.m_schedule = nil
        end
        ---------------------------------------------------------
        self.m_schedule = Utils:schedule(nil, handler(self, LDPosAnimController.update), 1/30, false)
        self:update(0)
    end
end

-------------------------------------
function LDPosAnimController:onExit()
    if self.m_schedule ~= nil then
        Utils:unschedule(nil, self.m_schedule)
        self.m_schedule = nil
    end
    self.m_pUILayer = nil
    self.m_posVec = nil
    self.m_center = nil
    self.m_centerIndex = nil
    self.m_space = nil
    self.m_prePosition = nil
    self.m_posVec = nil
    self.m_ctrlPos1 = nil
    self.m_ctrlPos2 = nil
    ------------------------------------------------
    Utils:FreeTable(self.m_itemMap)
    self.m_itemMap = nil
end

function LDPosAnimController:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    if self.m_pUILayer then
        self.m_pUILayer:registerScriptHandler(onNodeEvent)
    end
end

function LDPosAnimController:update(dt)
    if self.m_space <= 0 then
        return
    end

    local center = self.m_center
    local factor = self.m_space
    -- for k,v in pairs(self.m_itemMap) do
    --     local item = v
    --     if item and item:getLocalZOrder() > 0 then
    --         local x = item:getPosition()
    --         local diff = math.abs(x-self.m_center.x)
    --         local scale = 1.2 - math.min(diff/factor*0.5, 0.5)
    --         item:setScale(scale)
    --     end
    -- end
    self:loadPosition()
end

function LDPosAnimController:loadPosition()
    for k,v in pairs(self.m_itemMap) do
        if k and v then
            self.m_prePosition[k] = cc.p(v:getPosition())
        end
    end
end

function LDPosAnimController:initPos()
    local center = cc.p(self.m_pUILayer:getContentSize().width/2, self.m_pUILayer:getContentSize().height/2)
    local centerIndex = self.m_centerIndex
    local spaceX = 50
    local spaceY = 50
    local width = nil
    local y = self.m_pUILayer:getContentSize().height/2
    self.m_posVec = {}
    for i,v in ipairs(self.m_itemMap) do
        local item = v
        if width == nil then
            width = item:getContentSize().width
        end
        local _x = center.x + (i-centerIndex)*(width+spaceX)
        local _y = y + math.min(math.abs(i-centerIndex), 1)*spaceY
        local pos = cc.p(_x, _y)
        item:setPosition(pos)

        table.insert(self.m_posVec, pos)
    end

    local function getCtrlPosition(pre, cur, lastIndex, dstPoint, curPoint)
        local vec = cc.pSub(dstPoint, curPoint)
        local fVec = nil
        if pre > cur then
            if cur == 1 and pre == lastIndex then
                fVec = cc.pMul(cc.pNormalize(cc.pPerp(vec)), 50)
            else
                fVec = cc.pMul(cc.pNormalize(cc.RPerp(vec)), 75)
            end
        else
            if pre == 1 and cur == lastIndex then
                fVec = cc.pMul(cc.pNormalize(cc.RPerp(vec)), 50)
            else
                fVec = cc.pMul(cc.pNormalize(cc.pPerp(vec)), 75)
            end
        end

        local ctrlPoint1 = cc.pAdd(fVec, dstPoint)
        local ctrlPoint2 = cc.pAdd(fVec, curPoint)
        return ctrlPoint1,ctrlPoint2
    end

    local lastIndex = #self.m_posVec
    for i=1,#self.m_posVec do
        local cur,dst = i,i+1
        if dst > lastIndex then
            dst = dst - lastIndex
        end
        local dstPoint = self.m_posVec[dst]
        local curPoint = self.m_posVec[cur]

        local ctrl1,ctrl2 = getCtrlPosition(dst, cur, lastIndex, dstPoint, curPoint)
        if dst > cur then
            self.m_ctrlPos1[cur] = {[1] = ctrl1}
            self.m_ctrlPos2[dst] = {[2] = ctrl2}
        else
            self.m_ctrlPos1[cur] = {[1] = ctrl2}
            self.m_ctrlPos2[dst] = {[2] = ctrl1}
        end
    end
    -- dump(self.m_ctrlPos1)
    -- dump(self.m_ctrlPos2)

    local vec = cc.p(-1, 0)
    --dump(cc.pPerp(vec))
    --dump(cc.RPerp(vec))

    self:loadPosition()
end

return LDPosAnimController