local FailCopyDelegate = LUIBase:New()
FailCopyDelegate.__index = FailCopyDelegate

----------------------------------------------
function FailCopyDelegate:New()
    local o = {}
    setmetatable(o, FailCopyDelegate)
    o:Init()
    return o
end
----------------------------------------------
function FailCopyDelegate:onExit()
    self.m_pUI = nil
    self.m_pUILayer = nil
end
----------------------------------------------
function FailCopyDelegate:Init()
    self.Script = "FirstAward.FailCopyDelegate"
end

function FailCopyDelegate:UpdateUI()
    local pPanel = self.m_pUILayer
    ----------------------------------------------------
    local level = LRoleDataMgr.MyHeroInfo.level
    local list = LDataConstMgr:getDieWarningData(level)
    if list == nil or #list == 0 then
        performWithDelay(self.m_pUILayer, function()
            local _ = self.m_pUI and self.m_pUI:RemoveUI()
        end, 0)
        return
    end
    local pIconBg = pPanel:getChildByName("IconBg")
    pIconBg:setVisible(true)
    local pList = pIconBg:getChildByName("List")
    pList:setVisible(true)
    local items = {}
    for i=1,3 do
        table.insert(items, pList:getChildByName("IconBtn"..i))
    end
    
    self:updateItems(pList, list, items)
    ----------------------------------------------------
    self:updateTips()
    ----------------------------------------------------
    self:updateButton()
end

function FailCopyDelegate:updateTips()
    local pPanel = self.m_pUILayer
    local pText = pPanel:getChildByName("Text")
    pText:setString(GUITips.RSI_JIESUAN_TIP2)
    pText:setTextColor(cc.c4b(255,0,0,255))
    pText:setVisible(true)
end

function FailCopyDelegate:updateButton()
    local pPanel = self.m_pUILayer
    local pBtn_Confirm = pPanel:getChildByName("Btn_Confirm")
    pBtn_Confirm:addClickEventListener(function(sender)
        local _ = self.m_pUI and self.m_pUI:RemoveUI()
    end)
    self:MarkIntaractCObj(pBtn_Confirm)
    pBtn_Confirm:setVisible(true)
    local pText = pBtn_Confirm:getChildByName("Text")
    pText:setString(GUITips.RSI_KNOW)
end

function FailCopyDelegate:setData(data)
    self.m_pUI = data[1]
    self.m_pUILayer = data[2]
    self:UpdateUI()
    Utils:PlayEffect("GuideBGM", "id", 1)
end

function FailCopyDelegate:updateItems(pList, datas, items)
    local cData = #datas
    for i=1,#items do
        local pItemBtn = items[i]
        if i <= cData then
            local functionId = datas[i]
            pItemBtn:setVisible(true)
            pItemBtn:setTouchEnabled(true)
            pItemBtn:setTag(functionId)

            if functionId == AppDef.EActivityID.EAID_COMBAT then
                str = AppDef.GUIRes["Activity_Name"..functionId]
            else
                str = AppDef.GUIRes["Function_Name"..functionId]
            end
            local pSp = cc.Sprite:createWithSpriteFrameName(str)
            if pSp then
                local pSize = pItemBtn:getContentSize()
                pSp:setPosition(cc.p(pSize.width/2, pSize.height/2))
                local spSize = pSp:getContentSize()
                if spSize.width > pSize.width then
                    pSp:setScaleX(pSize.width/spSize.width)
                end
                if spSize.height > pSize.height then
                    pSp:setScaleY(pSize.height/spSize.height)
                end
                pSp:setScaleX(math.min(pSp:getScaleX(), pSp:getScaleY()))
                pItemBtn:addChild(pSp)
            end

            pItemBtn:addClickEventListener(handler(self, FailCopyDelegate.buttonClick))
        else
            pItemBtn:setVisible(false)
        end
    end
    Utils:AlignNodes(pList, items, {80}, 3)
end

function FailCopyDelegate:buttonClick(sender)
    if sender == nil then
        return
    end
    local tag = sender:getTag()
    if Utils:OpenFunction(tag) then
        local _ = self.m_pUI and self.m_pUI:RemoveUI()
    end
end

return FailCopyDelegate