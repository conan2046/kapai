--[[
lua  社交
]]
local PetBagMainUI = LUIBase:New()
PetBagMainUI.__index = PetBagMainUI
--local this = LTcpSocket
function PetBagMainUI:New(openTab)
	local o = LUIBase:New()
	setmetatable(o,PetBagMainUI)	
    o:Init(openTab)
	return o
end

function PetBagMainUI:Init(openTab)
    self.Script = "KaPaiPet.PetBagMainUI"
    self:RegistMsgs()
    self.m_pUILayer = cc.Node:create()
    self.m_pSubLayer = {}
    self.m_curUIInd = 0
    self.m_defaultRoleName = nil
    self._defaultPCRoleId = nil
    self:InitTouchEvt()

    --title
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.RIS_LEFTUI_MSG43)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local function tabBtnClicked(ind)
        self:TabClicked(ind)
    end
    local tabValues = 
    {
    --, GUITips.RSI_SOCIAL_MASTER, GUITips.RSI_SOCIAL_SPOUSE 屏蔽师徒和夫妻
        {GUITips.UI_Title_Pet, GUITips.RIS_LEFTUI_MSG44},
        tabBtnClicked
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.AddTabBtn, tabValues)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, openTab)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    self:TabClicked(openTab)
    --self:RegisterGuide()
end

function PetBagMainUI:RegisterGuide()
    if true then
        return
    end
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SJHAOYOU, true) then
        return
    end
    
    -- LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RegisterCloseGuide, GuideDef.StepId.Guide_SHEJ_FINISH)
    -- self:SendMsg(LGameMsg.m_baseMsgWithOne)
    --------------------------------------------------------------------------
end

--[[
注册消息
]]
function PetBagMainUI:RegistMsgs()
    self.msgIds = 
    {
        LUIRedDotEvent.UpdateRedDotState,
        LUILogicEvent.ClosePetYangChengUI,
    }
    self:RegistSelf(self,self.msgIds)
end

function PetBagMainUI:ProcessEvent(msg)

    if msg.msgId == LUIRedDotEvent.UpdateRedDotState then
        self:updateHotDot()
    elseif msg.msgId == LUILogicEvent.ClosePetYangChengUI then
        --刷新天命激活红点
        print("ProcessEvent =========>", LUIPetEvent.PetJiHuoSuc)
        performWithDelay(self.m_pUILayer, function ( ... )
            -- body
            self:updateHotDot()
        end, 0.2)
        
    end

end

function PetBagMainUI:onExit()
    -- Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_SHEJ_1)
    --Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_SHEJ_FINISH)
    self.m_pUILayer = nil
    self.m_defaultRoleName = nil
    self.m_curUIInd = nil
    self._defaultPCRoleId = nil
    self:Destory()
end

function PetBagMainUI:InitTouchEvt()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    
    local function closeCallback()
        if self.m_pSubLayer[1] then
            self.m_pSubLayer[1]:closeUI()
        end
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "KaPaiPet.PetBagMainUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

end


function PetBagMainUI:HideCurUI()
    if self.m_pSubLayer[self.m_curUIInd] == nil then
        return
    end
    self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(false)
end

function PetBagMainUI:ShowCurUI()
    
     if self.m_pSubLayer[self.m_curUIInd] == nil then
        self:DelayLoadSubUI(self.m_curUIInd)
    else
        self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(true)
    end
    
end

function PetBagMainUI:TabClicked(ind)
    print("PetBagMainUI:TabClicked ==================== ind >", ind, self.m_curUIInd)
    if  self.m_curUIInd == ind then
        return
    end

    local function goBack(index)
        LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, index)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end

    if ind == 1 and Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_KAPAI_PET_BAGS) then
        goBack(self.m_curUIInd)
        return
    elseif ind == 2 and Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_KAPAI_FRAGMENT_BAGS) then
        goBack(self.m_curUIInd)
        return
    end


    if self.m_curUIInd ~= 0 then
     self:HideCurUI()
    end

    self.m_curUIInd = ind
    self:ShowCurUI()
end

function PetBagMainUI:DelayLoadSubUI(tabInd)
    --,"View.Social.MasterUI",
    local uinames = {"View.KaPaiPet.PetBagPetSubUI","View.KaPaiPet.PetBagFragmentSubUI"}
    local ind = tabInd
    local delay = cc.DelayTime:create(0.1)
    local function loadSubUI()
        if self.m_curUIInd ~= ind then
            return
        end
       
        self.m_pSubLayer[ind] = require(uinames[ind]):New()
        self.m_pUILayer:addChild(self.m_pSubLayer[ind].m_pUILayer)
        self:updateHotDot()
    end
    local func = cc.CallFunc:create(loadSubUI)
    local sequence = cc.Sequence:create(delay, func)
    self.m_pUILayer:runAction(sequence)

end


function PetBagMainUI:updateHotDot()
    -- body
    local xiulianPianShow = Utils:GetRedDotState(RedDotDef.ID.ShenJiang_XiuLian)
    local show = Utils:GetRedDotState(RedDotDef.ID.Shenjiang_tag)
    print("PetBagMainUI:updateHotDot ===>", show, xiulianPianShow)
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RedDotState, {1, show or xiulianPianShow})
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local suiPianShow = Utils:GetRedDotState(RedDotDef.ID.ShuiPian_tag)
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RedDotState, {2, suiPianShow})
    self:SendMsg(LGameMsg.m_baseMsgWithOne)


   
end

return PetBagMainUI