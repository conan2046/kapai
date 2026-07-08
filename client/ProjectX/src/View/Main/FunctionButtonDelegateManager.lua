local FunctionButtonDelegateManager = {}
FunctionButtonDelegateManager.__index = FunctionButtonDelegateManager

function FunctionButtonDelegateManager:New()
	local o = {}
	setmetatable(o, FunctionButtonDelegateManager)
	o:Init()
	return o
end

function FunctionButtonDelegateManager:Init()
    self.m_configVec = {}
end

function FunctionButtonDelegateManager:onExit()
    if self.m_configVec then
        for k,v in pairs(self.m_configVec) do
            if k and v and v.delegate and v.delegate.onExit then
                v.delegate:onExit()
            end
            self.m_configVec[k] = nil
        end
        self.m_configVec = nil
    end
end
--[[
index:
btn:
groups:
]]
function FunctionButtonDelegateManager:AddConfig(cfg)
    if cfg == nil or cfg.index == nil or cfg.btn == nil or cfg.groups == nil then
        return
    end
    cfg.isClose = false
    self:SetDelegate(cfg)
    cfg.btn:setTag(cfg.index)
    cfg.btn:addClickEventListener(handler(self, FunctionButtonDelegateManager.ButtonClick))
    cfg.btn:getChildByName("Prompt"):setVisible(false)
    self.m_configVec[cfg.index] = cfg
end

function FunctionButtonDelegateManager:SetDelegate(cfg)
    if cfg.index == 1 then
        cfg.delegate = require("View.Main.FuncButtonDelegateTop"):New(cfg)
    end
end

function FunctionButtonDelegateManager:ButtonClick(sender)
    if sender == nil or self.m_configVec == nil then
        return
    end
    local tag = sender:getTag()
    local data = self.m_configVec[tag]
    if data == nil or data.delegate == nil or data.delegate.ButtonClick == nil then
        return
    end
    data.delegate:ButtonClick()
end

function FunctionButtonDelegateManager:SetCtrlButtionVisible(index, isVisible)
    isVisible = Utils:ToBool(isVisible)
    if index and self.m_configVec[index] and self.m_configVec[index].delegate then
        self.m_configVec[index].delegate:SetButtionVisible(isVisible)
    end
end

return FunctionButtonDelegateManager