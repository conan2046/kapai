local BaseOprStrategy = LUIBase:New()
BaseOprStrategy.__index = BaseOprStrategy

-- -----------------------------------
function BaseOprStrategy:New()
    local o = {}
    setmetatable(o, BaseOprStrategy)
    return o
end

function BaseOprStrategy:onExit()
end

function BaseOprStrategy:onClose()
end

function BaseOprStrategy:ShowListBg()
    return true
end

function BaseOprStrategy:SetData(index)
    return true
end

function BaseOprStrategy:GetCellTag(index)
    return index
end

function BaseOprStrategy:GetCellGray(index)
    return false
end

function BaseOprStrategy:initData()
end

function BaseOprStrategy:checkData()
    return true
end

function BaseOprStrategy:getItemCunt()
    return 0
end

function BaseOprStrategy:updateCell(pCell, index)
end

function BaseOprStrategy:updateIcon(pIcon, index)
end

function BaseOprStrategy:updateName(pName, index)
end

function BaseOprStrategy:updateNum(pNum, index)
end

function BaseOprStrategy:updateCount(pCount, index)
end

function BaseOprStrategy:ChooseCallback(index)
end

return BaseOprStrategy