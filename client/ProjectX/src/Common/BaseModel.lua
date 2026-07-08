BaseModel = {}
BaseModel.InValid = 0xffff

BaseModel.__index = function(tb, key)
    if key == 'Get' then
        return function(self)
            return self['Data']
        end
    elseif key == 'Set' then
        return function(self, value)
            local temp = self['Data']
            if temp == nil or temp ~= value then
                self['Data'] = value
                if self._event then
                    self._event(value, temp)
                end
            end
        end
    end
end

local function Init(o, ...)
    o._initValue, o._event = ...
    o['Data'] = o._initValue or BaseModel.InValid
end

function BaseModel:New(...)
    local o = {}
    setmetatable(o, BaseModel)
    Init(o, ...)
    return o
end

return BaseModel