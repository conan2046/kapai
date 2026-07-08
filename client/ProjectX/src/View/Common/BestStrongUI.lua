local BestStrongUI = LUIBase:New()
BestStrongUI.__index = BestStrongUI

-----------------------------------
function BestStrongUI:New()
    local o = {}
    setmetatable(o, BestStrongUI)
    o:Init()
    return o
end

-----------------------------------
function BestStrongUI:Init()
    self.Script = "Common.BestStrongUI"
    --------------------------------------------------
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    self:RegisterQuik()
end

-----------------------------------
function BestStrongUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.Script = nil
end

-----------------------------------
function BestStrongUI:InitUIControl()
    local pPanel = self.m_pUILayer:getChildByName("Popup")
    ------------------------------------------------------
    local pBestrongBg = pPanel:getChildByName("BestrongBg")
    local pList = pBestrongBg:getChildByName("List")
    local pItems = pList:getItems()
    local index = 0
    for i=1,#pItems do
        local pItem = pItems[i]
        index = (i-1)*2+1
        local pBtn1 = pItem:getChildByName("Button_1")
        if pBtn1 ~= nil then
            pBtn1:setTag(index)
            pBtn1:setSwallowTouches(false)
            pBtn1:addClickEventListener(handler(self, BestStrongUI.Click))
			self:MarkIntaractCObj(pBtn1)
        end
        local pBtn2 = pItem:getChildByName("Button_2")
        if pBtn2 ~= nil then
            pBtn2:setTag(index+1)
            pBtn2:setSwallowTouches(false)
            pBtn2:addClickEventListener(handler(self, BestStrongUI.Click))
			self:MarkIntaractCObj(pBtn2)
        end
    end
    if #pItems < 4 then
        pList:setTouchEnabled(false)
    end
    ------------------------------------------------------
end

function BestStrongUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    Utils:SendMsg(LUISecondClassBgEvent.SetCloseCallback, handler(self, LUIBase.RemoveUI))
end

-----------------------------------
function BestStrongUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/BestrongLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

-- ----------------------------------
function BestStrongUI:RegisterQuik()
    Utils:SendMsg(LUISecondClassBgEvent.SetTitle, GUITips.RSI_BESTSTRONG_TITLE)
end

function BestStrongUI:Click(sender)
    local tag = sender:getTag()
    local isRemove = false
    if tag == 1 then
        isRemove = Utils:OpenFunction(AppDef.EModuleID.EMID_DUANZAO)
    elseif tag == 2 then
        isRemove = Utils:OpenFunction(AppDef.EModuleID.EMID_SJSHENGXING)
        if Utils:OpenFunction(AppDef.EModuleID.EMID_SJSHENGXING) then
            self:RemoveUI()
        end
    elseif tag == 3 then
        isRemove = Utils:OpenFunction(AppDef.EModuleID.EMID_ZJQIANGHUA)
        if Utils:OpenFunction(AppDef.EModuleID.EMID_ZJQIANGHUA) then
            self:RemoveUI()
        end
    elseif tag == 4 then
        isRemove = Utils:OpenFunction(AppDef.EModuleID.EMID_JINENG)
    elseif tag == 5 then
        isRemove = Utils:OpenFunction(AppDef.EModuleID.EMID_WANFA)
    end
    if isRemove then
        self:RemoveUI()
    end
end

return BestStrongUI