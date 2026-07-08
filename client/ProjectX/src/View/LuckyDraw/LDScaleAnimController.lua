local LDScaleAnimController = {}
LDScaleAnimController.__index = LDScaleAnimController

--[[
data:
{
    rootUI:根节点UI，为了设置关闭回调
    nodes:{node,...}
}
]]
-------------------------------------
function LDScaleAnimController:New(data)
    local o = {}
    setmetatable(o, LDScaleAnimController)
    o:Init(data)
    return o
end

-------------------------------------
function LDScaleAnimController:Init(data)
    self.m_center = nil
    self.m_space = 0
    ------------------------------------------------
    self.m_schedule = nil
    ------------------------------------------------
    self.m_itemMap = {}--节点Map
    if data then
        self:updateConfig(data)
        self:setCloseCallback()
    end
end

function LDScaleAnimController:updateConfig(data)
    if data then
        ---------------------------------------------------------
        self.m_pUILayer = data.rootUI
        self.m_center = cc.p(self.m_pUILayer:getContentSize().width/2, self.m_pUILayer:getContentSize().height/2)
        ---------------------------------------------------------
        for i=1,#data.nodes do
            local node = data.nodes[i]
            local tag = node:getTag()
            self.m_itemMap[tag] = node
        end
        if #data.nodes > 1 then
            self.m_space = math.abs(cc.p(data.nodes[1]:getPosition()).x - cc.p(data.nodes[2]:getPosition()).x)
        end
        ---------------------------------------------------------
        self:setCloseCallback()
        ---------------------------------------------------------
        if self.m_schedule ~= nil then
            Utils:unschedule(nil, self.m_schedule)
            self.m_schedule = nil
        end
        ---------------------------------------------------------
        self.m_schedule = Utils:schedule(nil, handler(self, LDScaleAnimController.update), 1/30, false)
        self:update(0)
    end
end

-------------------------------------
function LDScaleAnimController:onExit()
    self.m_pUILayer = nil

    if self.m_schedule ~= nil then
        Utils:unschedule(nil, self.m_schedule)
        self.m_schedule = nil
    end
    Utils:FreeTable(self.m_itemMap)
    self.m_itemMap = nil

    self.m_center = nil
    self.m_space = nil
end

function LDScaleAnimController:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

function LDScaleAnimController:update(dt)
    if self.m_space <= 0 then
        return
    end

    local center = self.m_center
    local factor = self.m_space
    for k,v in pairs(self.m_itemMap) do
        local item = v
        if item and item:getLocalZOrder() > 0 then
            local x = item:getPosition()
            local diff = math.abs(x-self.m_center.x)
            local scale = 1.2 - math.min(diff/factor*0.5, 0.5)
            item:setScale(scale)
        end
    end
end

return LDScaleAnimController