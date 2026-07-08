
local CultivateJiBanUI = LUIBase:New()
CultivateJiBanUI.__index = CultivateJiBanUI
--local this = LTcpSocket
function CultivateJiBanUI:New()
	local o = LUIBase:New()
	setmetatable(o,CultivateJiBanUI)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function CultivateJiBanUI:RegistMsgs()
    self.msgIds = 
    {
        -- LUIKaPaiPetEvent.ShowPetLeftInfo,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function CultivateJiBanUI:ProcessEvent(msg)
    -- if msg.msgId == LUIKaPaiPetEvent.ShowPetLeftInfo then
    -- end
end

function CultivateJiBanUI:Init()
    self:InitMembers()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end

    self.m_pUILayer:registerScriptHandler(onNodeEvent)

end

function CultivateJiBanUI:InitMembers()
    self.m_pUILayer = cc.CSLoader:createNode("csd/zhuangbeiyangcheng/Common_jiban.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    local jbBg = self.m_pUILayer:getChildByName("jibanUI"):getChildByName("zhuangbeiqianghua")
    self.m_Title = jbBg:getChildByName("Title")
    self.m_Text = jbBg:getChildByName("Text")
    self.m_attrText = {}
    for i=1, 4 do
        self.m_attrText[i] = jbBg:getChildByName("shuxing_"..i)
    end
    self.m_btn = jbBg:getChildByName("Btn_Close")
end

function CultivateJiBanUI:AddTouchEvt()
    local function BreakUpBtnCallback(sender)
        LuaNetSendMsg:PetBreakUp(self.petData.id)
    end
    self.breakBtn:addClickEventListener(BreakUpBtnCallback)
    self:MarkIntaractCObj(self.breakBtn)
end

function CultivateJiBanUI:onExit()
    self.m_pUILayer = nil
    self.m_Title = nil
    self.m_Text = nil
    self.m_attrText = nil
    self.m_btn = nil
    self:Destory()
end

function CultivateJiBanUI:InitBreakConfig()
end

return CultivateJiBanUI