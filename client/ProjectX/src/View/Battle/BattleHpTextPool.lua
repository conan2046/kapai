BattleHpTextPool = {}
BattleHpTextPool.__index = BattleHpTextPool
BattleHpTextPool.TextColor_Red = 0
BattleHpTextPool.TextColor_Green = 1

BattleHpTextPool._greenTextUsedArr = {}
BattleHpTextPool._redTextUsedArr = {}
BattleHpTextPool._greenTextFreeArr = {}
BattleHpTextPool._redTextFreeArr = {}
BattleHpTextPool._pGreenText = nil
BattleHpTextPool._pRedText = nil
BattleHpTextPool._isInited = false
function BattleHpTextPool:Init(redText, greenText)
    if BattleHpTextPool._pGreenText == nil then
        BattleHpTextPool._pGreenText = greenText
    end

    if BattleHpTextPool._pRedText == nil then
        BattleHpTextPool._pRedText = redText
    end
    self:UnUseRedText(redText)
    self:UnUseGreenText(greenText)
end

function BattleHpTextPool:Reset()
    while #BattleHpTextPool._redTextUsedArr > 0 do
        local label = BattleHpTextPool._redTextUsedArr[1]
        label:stopAllActions()
        label:setVisible(false)
        label:removeFromParent()
        table.remove(BattleHpTextPool._redTextUsedArr,1)
        table.insert(BattleHpTextPool._redTextFreeArr,label)
    end

    while #BattleHpTextPool._greenTextUsedArr > 0 do
        local label = BattleHpTextPool._greenTextUsedArr[1]
        label:stopAllActions()
        label:setVisible(false)
        label:removeFromParent()
        table.remove(BattleHpTextPool._greenTextUsedArr,1)
        table.insert(BattleHpTextPool._greenTextFreeArr,label)
    end
end

function BattleHpTextPool:UnUseText(textColorType, text)
    if textColorType == BattleHpTextPool.TextColor_Red then
        self:UnUseRedText(text)
    elseif textColorType == BattleHpTextPool.TextColor_Green then
        self:UnUseGreenText(text)
    end
end

function BattleHpTextPool:UnUseRedText(text)
    for i = 1,#BattleHpTextPool._redTextUsedArr do
        if BattleHpTextPool._redTextUsedArr[i] == text then
            local text = BattleHpTextPool._redTextUsedArr[i]
            table.remove(BattleHpTextPool._redTextUsedArr,i)
            table.insert(BattleHpTextPool._redTextFreeArr,text)
            return
        end
    end
    table.insert(BattleHpTextPool._redTextFreeArr,text)
end

function BattleHpTextPool:UnUseGreenText(text)
    for i = 1,#BattleHpTextPool._greenTextUsedArr do
        if BattleHpTextPool._greenTextUsedArr[i] == text then
            local text = BattleHpTextPool._greenTextUsedArr[i]
            table.remove(BattleHpTextPool._greenTextUsedArr,i)
            table.insert(BattleHpTextPool._greenTextFreeArr,text)
            return
        end
    end
    table.insert(BattleHpTextPool._greenTextFreeArr,text)
end



function BattleHpTextPool:UseText(textColorType)
    if textColorType == BattleHpTextPool.TextColor_Red then
        return self:GetRedText()
    elseif textColorType == BattleHpTextPool.TextColor_Green then
        return self:GetGreenText()
    end
    return nil
end

function BattleHpTextPool:GetGreenText()
    if #BattleHpTextPool._greenTextFreeArr == 0 then
        local text = BattleHpTextPool._pGreenText:clone()
        text:retain()
        table.insert(BattleHpTextPool._greenTextUsedArr,text)
        return text
    else
        local text = BattleHpTextPool._greenTextFreeArr[1]
        table.remove(BattleHpTextPool._greenTextFreeArr,1)
        table.insert(BattleHpTextPool._greenTextUsedArr,text)
        return text
    end
end

function BattleHpTextPool:GetRedText()
    if #BattleHpTextPool._redTextFreeArr == 0 then
        local text = BattleHpTextPool._pRedText:clone()
        text:retain()
        table.insert(BattleHpTextPool._redTextUsedArr,text)
        return text
    else
        local text = BattleHpTextPool._redTextFreeArr[1]
        table.remove(BattleHpTextPool._redTextFreeArr,1)
        table.insert(BattleHpTextPool._redTextUsedArr,text)
        return text
    end
end

return BattleHpTextPool