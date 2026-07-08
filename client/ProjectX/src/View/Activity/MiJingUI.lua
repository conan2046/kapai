local MiJingUI = LUIBase:New()
MiJingUI.__index = MiJingUI
-----------------------------------
local stateBuffer = {
    ['0'] = "res/UI/ui_common/ui_biaoqian_weishuaxin.png",
    ['1'] = "res/UI/ui_common/ui_biaoqian_yishuaxin.png",
    ['2'] = "res/UI/ui_common/ui_biaoqian_yijibai.png",
    ['3'] = "res/UI/ui_common/ui_biaoqian_yitaotuo.png",
}
local buffer = {
    [508] = 1,
    [605] = 2,
    [311] = 3,
}
-----------------------------------
function MiJingUI:New()
    local o = {}
    setmetatable(o, MiJingUI)
    o:Init()
    return o
end
-----------------------------------
function MiJingUI:Init()
    self.Script = "Activity.MiJingUI"
    --------------------------------------------------
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    --------------------------------------------------
    LuaNetSendMsg:QueryMsBossInfo()
    --------------------------------------------------
end
-----------------------------------
function MiJingUI:onExit()
    self:Destory()
    self.m_pListView = nil
    ------------------------------------------------------
    self.m_pCellModel = nil
    ------------------------------------------------------
    self.m_pItemModel = nil
    self.m_pUILayer = nil
    Utils:FreeTable(self.m_data)
    self.m_data = nil
end
-----------------------------------
function MiJingUI:InitUIControl()
    local pPanel = self.m_pUILayer:getChildByName("Mijing_1")
    ------------------------------------------------------
    self.m_pListView = pPanel:getChildByName("BossList")
    ------------------------------------------------------
    self.m_pCellModel = pPanel:getChildByName("ImageBg1")
    self.m_pCellModel:setVisible(false)
    ------------------------------------------------------
    self.m_pItemModel = pPanel:getChildByName("Item")
    self.m_pItemModel:setVisible(false)
    ------------------------------------------------------
    local pEnterButton = pPanel:getChildByName("Button")
    pEnterButton:addClickEventListener(handler(self, MiJingUI.EnterButtonClick))
	self:MarkIntaractCObj(pEnterButton)
    ------------------------------------------------------
end
-----------------------------------
function MiJingUI:RegistMsgs()
    self.msgIds = 
    {
        LUIMiJingEvent.UpdateDataEvent,
    }
    self:RegistSelf(self, self.msgIds)
end
-----------------------------------
function MiJingUI:ProcessEvent(msg)
    if msg.msgId == LUIMiJingEvent.UpdateDataEvent then
        self:UpdateData(msg.value)
    end
end

function MiJingUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    Utils:SendMsg(LUIFClassBgEvent.SetCloseCallback, handler(self, LUIBase.RemoveUI))
    Utils:SendMsg(LUIFClassBgEvent.SetTitle, GUITips.RSI_MIJING_TIPS_1)
end
-----------------------------------
function MiJingUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/MijingLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
    if self.m_pUILayer ~= nil then
        self.m_pUILayer:setVisible(false)
    end
end
----------------------------------
function MiJingUI:UpdateData(data)
    if data == nil then
        return
    end
    Utils:FreeTable(self.m_data)
    self.m_data = nil
    self.m_data = data
    self:UpdateList()
    if self.m_pUILayer ~= nil then
        self.m_pUILayer:setVisible(true)
    end
end
----------------------------------
function MiJingUI:EnterButtonClick(sender)
    LuaNetSendMsg:QueryJoinMsBoss()
end
----------------------------------
function MiJingUI:UpdateList()
    if self.m_data == nil or type(self.m_data) ~= 'table' then
        return
    end
    self.m_pListView:removeAllItems()
    local datas = self.m_data
    for i=1,#datas do
        local pItem = self:CreateCell(i, datas[i])
        if pItem then
            self.m_pListView:pushBackCustomItem(pItem)
        end
    end
end
----------------------------------
function MiJingUI:CreateCell(idx, info)
    if idx == nil or info == nil then
        return nil
    end
    local pItem = self.m_pCellModel:clone()
    pItem:setVisible(true)

    self:UpdateName(pItem, info, idx)
    self:UpdateTime(pItem, info, idx)
    self:UpdateReward(pItem, info, idx)
    self:UpdateBg(pItem, info, idx)
    self:UpdateModel(pItem, info, idx)
    self:UpdateState(pItem, info, idx)

    return pItem
end
----------------------------------
function MiJingUI:UpdateName(pItem, info, idx)
    if pItem == nil or info == nil then
        return
    end
    local pName = pItem:getChildByName("TitleBg"):getChildByName("TitleName")
    if pName ~= nil then
        pName:setString(info.name)
    end
end
----------------------------------
function MiJingUI:UpdateTime(pItem, info, idx)
    if pItem == nil or info == nil then
        return
    end
    local pTime = Utils:FindNodeByName(pItem, 'Reward/Time/Text')
    if pTime ~= nil then
        pTime:setString(info.time)
    end
end
----------------------------------
function MiJingUI:UpdateReward(pItem, info, idx)
    if pItem == nil or info == nil then
        return
    end
    local pRewardList = pItem:getChildByName("Reward"):getChildByName("ListView")
    if pRewardList ~= nil and info.rewards then
        for i=1,#info.rewards do
            local pCellModel = self.m_pItemModel:clone()
            pCellModel:setVisible(true)
            Utils:GetItemCellValue(pCellModel, 0, info.rewards[i], true, nil, nil, nil, true)
            pRewardList:pushBackCustomItem(pCellModel)
        end
    end
end
----------------------------------
function MiJingUI:UpdateBg(pItem, info, idx)
    if pItem == nil or idx == nil then
        return
    end
    for i=1,3 do
        local pNode = pItem:getChildByName("Bg_"..i)
        if pNode ~= nil then
            pNode:setVisible(buffer[info.id] and buffer[info.id] == i)
        end
    end
end
----------------------------------
function MiJingUI:UpdateModel(pItem, info, idx)
    if pItem == nil or info == nil then
        return
    end
    local pBase = pItem:getChildByName("Base"):getChildByName("Node")
    local pAnimModel = ModelAniNode:create(AppDef.CEnum.ModelAniType.Monster, 0)
    if pBase ~= nil and pAnimModel ~= nil then
        pAnimModel:InitAni(AppDef.CEnum.ModelAniType.Monster, info.id)
        pAnimModel:PlayStand(0)
        pBase:addChild(pAnimModel)
    end
end
----------------------------------
function MiJingUI:UpdateState(pItem, info, idx)
    if pItem == nil or info == nil then
        return
    end
    local pState = pItem:getChildByName("State")
    if pState ~= nil then
        if stateBuffer[tostring(info.state)] then
            pState:setVisible(true)
            pState:loadTexture(stateBuffer[tostring(info.state)], UI_TEX_TYPE_PLIST)
        end
    end
end
----------------------------------
return MiJingUI