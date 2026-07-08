
local EquipAutoStarUpUI = LUIBase:New()
EquipAutoStarUpUI.__index = EquipAutoStarUpUI
--local this = LTcpSocket
function EquipAutoStarUpUI:New(attr)
	local o = LUIBase:New()
	setmetatable(o,EquipAutoStarUpUI)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function EquipAutoStarUpUI:RegistMsgs()
    self.msgIds = 
    {
        -- LUIKaPaiPetEvent.ShowPetLeftInfo,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function EquipAutoStarUpUI:ProcessEvent(msg)
    -- if msg.msgId == LUIKaPaiPetEvent.ShowPetLeftInfo then
    -- end
end

function EquipAutoStarUpUI:Init()
    self:InitMembers()
    self:AddTouchEvt()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end

    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

function EquipAutoStarUpUI:InitMembers()
    self.m_pUILayer = cc.CSLoader:createNode("csd/zhuangbeiyangcheng/yijianshengxing.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    local bg = self.m_pUILayer:getChildByName("Popup")
    self.m_levelTips = bg:getChildByName("Tips_1")
    self.m_allItemlistView = bg:getChildByName("ListView")
    self.m_itemCellListView = bg:getChildByName("Item")
    self.m_itemCell = bg:getChildByName("ItemIcon")
    self.m_checkBox1 = bg:getChildByName("CheckBox1")
    self.m_checkBox2 = bg:getChildByName("CheckBox2")
    self.m_checkBox3 = bg:getChildByName("CheckBox3")
    self.m_closeBtn = bg:getChildByName("Btn_close")
    self.m_okBtn = bg:getChildByName("Btn_Confirm")
    self.m_cancelBtn = bg:getChildByName("Btn_Cancel")
end

function EquipAutoStarUpUI:AddTouchEvt()
    local function OkCallBack(sender)
        Utils:DeleteUI("EquipCultivate.EquipAutoStarUpUI")
    end
    self.m_okBtn:addClickEventListener(OkCallBack)
    self:MarkIntaractCObj(self.m_okBtn)


    local function CancelCallBack(sender)
        Utils:DeleteUI("EquipCultivate.EquipAutoStarUpUI")
    end
    self.m_cancelBtn:addClickEventListener(CancelCallBack)
    self:MarkIntaractCObj(self.m_cancelBtn)
    self.m_closeBtn:addClickEventListener(CancelCallBack)
    self:MarkIntaractCObj(self.m_closeBtn)
end

function EquipAutoStarUpUI:onExit()
    self.m_pUILayer = nil
    self.m_levelTips = nil
    self.m_allItemlistView = nil
    self.m_itemCellListView = nil
    self.m_itemCell = nil
    self.m_checkBox1 = nil
    self.m_checkBox2 = nil
    self.m_checkBox3 = nil
    self.m_closeBtn = nil
    self.m_okBtn = nil
    self.m_cancelBtn = nil
    self:Destory()
end

function EquipAutoStarUpUI:InitBreakConfig()
end

return EquipAutoStarUpUI