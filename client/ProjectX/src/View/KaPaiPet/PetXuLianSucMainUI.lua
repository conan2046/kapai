--[[
lua  社交
]]
local PetXuLianSucMainUI = LUIBase:New()
PetXuLianSucMainUI.__index = PetXuLianSucMainUI
    
local funcArr = {
    AppDef.EModuleID.EMID_SHOP_JINGJI,
    AppDef.EModuleID.EMID_SHOP_XUEZHAN,
}

--local this = LTcpSocket
function PetXuLianSucMainUI:New(openTabData)
    local o = LUIBase:New()
    setmetatable(o,PetXuLianSucMainUI) 
    o:Init(openTabData)
    return o
end

function PetXuLianSucMainUI:Init(openTabData)
    self.Script = "KaPaiPet.PetXuLianSucMainUI"
    self:RegistMsgs()
    self.m_pUILayer = cc.Node:create()
    self.m_pSubLayer = {}
    self.m_curUIInd = 0
    self:InitTouchEvt()

    --title
    LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.SetTitle, GUITips.RSI_XIULIAN_TIPS4)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local function tabBtnClicked(ind)
        return self:TabClicked(ind)
    end
    local tabValues = 
    {
        {GUITips.RSI_XIULIAN_TIPS2, GUITips.RSI_XIULIAN_TIPS3},
        tabBtnClicked
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.AddTabBtn, tabValues)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    Utils:SendMsg(LUIPopFClassBgEvent.ChangeBg, {filePath = "res/UI/ui_bg/bg_shenjiangtujian.png", resType = ccui.TextureResType.localType})

    self._openTab = openTabData.openTab

    self._xlData = openTabData.xlData

    self:TabClicked(self._openTab)
    LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.SelectTab, self._openTab)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function PetXuLianSucMainUI:RegisterGuide()

end

--[[
注册消息
]]
function PetXuLianSucMainUI:RegistMsgs()
    self.msgIds = 
    {
        LUIRedDotEvent.UpdateRedDotState,
    }
    self:RegistSelf(self,self.msgIds)
end

function PetXuLianSucMainUI:ProcessEvent(msg)
    if msg.msgId == LUIRedDotEvent.UpdateRedDotState then
        self:updateHotDot(msg.value)
    end
end

function PetXuLianSucMainUI:onExit()
    self.m_pUILayer = nil
    self.m_curUIInd = nil
    self._openTab = nil
    Utils:SendMsg(LUIPopFClassBgEvent.ResetBg)
    self:Destory()
end

function PetXuLianSucMainUI:InitTouchEvt()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    
    local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "KaPaiPet.PetXuLianSucMainUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

end


function PetXuLianSucMainUI:HideCurUI()
    if self.m_pSubLayer[self.m_curUIInd] == nil then
        return
    end
    self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(false)
end

function PetXuLianSucMainUI:ShowCurUI()
    
     if self.m_pSubLayer[self.m_curUIInd] == nil then
        self:DelayLoadSubUI(self.m_curUIInd)
    else
        self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(true)
    end
    
end

function PetXuLianSucMainUI:TabClicked(ind)
    if  self.m_curUIInd == ind then
        return false
    end

    if self.m_curUIInd ~= 0 then
     self:HideCurUI()
    end

    self.m_curUIInd = ind
    self:ShowCurUI()
    return true
end

function PetXuLianSucMainUI:DelayLoadSubUI(tabInd)
    --,"View.Social.MasterUI",
    local uinames = {"View.KaPaiPet.PetJiHuoSucUI","View.KaPaiPet.PetJiHuoSucSecUI"}
    local ind = tabInd
    local delay = cc.DelayTime:create(0.1)
    local function loadSubUI()
        if self.m_curUIInd ~= ind then
            return
        end
        self.m_pSubLayer[ind] = require(uinames[ind]):New()
        self.m_pUILayer:addChild(self.m_pSubLayer[ind].m_pUILayer)

        self.m_pSubLayer[ind]:updateData(self._xlData)
        
        self:updateHotDot()
    end
    local func = cc.CallFunc:create(loadSubUI)
    local sequence = cc.Sequence:create(delay, func)
    self.m_pUILayer:runAction(sequence)
end

function PetXuLianSucMainUI:updateHotDot(data)
    -- body
    -- if data then
    --     print("PetKaPaiMainUI:updateHotDot ==>", data.id, data.isShow)
    --     if data.id == RedDotDef.ID.ShopWanFaJingji then
    --         LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.RedDotState, {1, data.isShow})
    --         self:SendMsg(LGameMsg.m_baseMsgWithOne)
    --     elseif data.id == RedDotDef.ID.ShopWanFaXueZhan then
    --         LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.RedDotState, {2, data.isShow})
    --         self:SendMsg(LGameMsg.m_baseMsgWithOne)
    --     end
    -- else
    --     local isJJOpen = not Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SHOP_JINGJI, true)
    --     local isShowJJ = Utils:GetRedDotState(RedDotDef.ID.ShopWanFaJingji) and isJJOpen

    --     LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.RedDotState, {1, isShowJJ})
    --     self:SendMsg(LGameMsg.m_baseMsgWithOne)

    --     local isXZOpen = not Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SHOP_XUEZHAN, true)
    --     local isShowXZ = Utils:GetRedDotState(RedDotDef.ID.ShopWanFaXueZhan) and isXZOpen
    --     -- print("PetXuLianSucMainUI:updateHotDot ==>", isShowJJ, isShowXZ)
    --     LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.RedDotState, {2, isShowXZ})
    --     self:SendMsg(LGameMsg.m_baseMsgWithOne)
    -- end
end


return PetXuLianSucMainUI