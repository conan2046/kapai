
local CultivateDuiHuanUI = LUIBase:New()
CultivateDuiHuanUI.__index = CultivateDuiHuanUI
--local this = LTcpSocket
function CultivateDuiHuanUI:New()
	local o = LUIBase:New()
	setmetatable(o,CultivateDuiHuanUI)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function CultivateDuiHuanUI:RegistMsgs()
    self.msgIds = 
    {
        -- LUIKaPaiPetEvent.ShowPetLeftInfo,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function CultivateDuiHuanUI:ProcessEvent(msg)
    -- if msg.msgId == LUIKaPaiPetEvent.ShowPetLeftInfo then
    -- end
end

function CultivateDuiHuanUI:Init()
    self:InitMembers()
    self:AddTouchEvt()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end

    self.m_pUILayer:registerScriptHandler(onNodeEvent)

end

function CultivateDuiHuanUI:InitMembers()
    self.m_pUILayer = cc.CSLoader:createNode("csd/zhuangbeiyangcheng/yijianduihuan.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    local bg = self.m_pUILayer:getChildByName("Popup")
    self.m_duihuanListView = bg:getChildByName("ListView")
    self.m_closeBtn = bg:getChildByName("Btn_close")
    self.m_okBtn = bg:getChildByName("Btn_Confirm")
    self.m_cancelBtn = bg:getChildByName("Btn_Cancel")
    self.m_singleCell = bg:getChildByName("Item")
end

function CultivateDuiHuanUI:AddTouchEvt()
    local function OkCallBack(sender)
        Utils:DeleteUI("EquipCultivate.CultivateDuiHuanUI")
    end
    self.m_okBtn:addClickEventListener(OkCallBack)
    self:MarkIntaractCObj(self.m_okBtn)


    local function CancelCallBack(sender)
        Utils:DeleteUI("EquipCultivate.CultivateDuiHuanUI")
    end
    self.m_cancelBtn:addClickEventListener(CancelCallBack)
    self:MarkIntaractCObj(self.m_cancelBtn)
    self.m_closeBtn:addClickEventListener(CancelCallBack)
    self:MarkIntaractCObj(self.m_closeBtn)
end

function CultivateDuiHuanUI:onExit()
    self.m_pUILayer = nil
    self.m_duihuanListView = nil
    self.m_closeBtn = nil
    self.m_okBtn = nil
    self.m_cancelBtn = nil
    self.m_singleCell = nil
    self:Destory()
end

function CultivateDuiHuanUI:InitBreakConfig()
end

return CultivateDuiHuanUI