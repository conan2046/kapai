local EquipGetUI = LUIBase:New()
EquipGetUI.__index = EquipGetUI
--local this = LTcpSocket
function EquipGetUI:New(userdata)
    local o = LUIBase:New()
    setmetatable(o,EquipGetUI) 
    o:Init(userdata)
    return o
end

function EquipGetUI:SetClickCallback(func, tag)
    local panel = self.m_pUILayer:getChildByName("btn_skill")
    if tag ~= nil then
        panel:setTag(tag)
    end
    panel:addClickEventListener(func)
end


function EquipGetUI:Init(userdata)
    self.Script = "PetEquip.EquipGetUI"
    self.m_pUILayer = cc.CSLoader:createNode("csd/common/ItemGet.csb")
    if userdata ~= nil then
        self.m_id = userdata[1]
        self.m_num = userdata[2]
    end
    self.m_id = self.m_id or 0
    self.m_num = self.m_num or 1
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitData()
    self:ShowInfo()
end

function EquipGetUI:InitData()
    local panel = self.m_pUILayer:getChildByName("ItemGetUI")
    local maskImg = panel:getChildByName("Mask")
    local itemPanel = panel:getChildByName("Item")
    self.m_nameLabel = itemPanel:getChildByName("Name")
    self.m_numLabel = itemPanel:getChildByName("Num")
    self.m_attrLabel = itemPanel:getChildByName("Attributes")
    self.m_iconNode = itemPanel:getChildByName("Node")

    maskImg:addClickEventListener(function (sender)
        self:CloseUI()
    end)
end

function EquipGetUI:ShowInfo()
    if self.m_id == 0 then
        return
    end
    local cfg = JsonConfig.m_equipConfig.getDefByID(self.m_id)
    if cfg == nil then
        return
    end
    self.m_nameLabel:setString(cfg.name)
    self.m_nameLabel:setColor(AppDef:GetQualityColor(cfg.quality))
    self.m_numLabel:setString("x"..self.m_num)

    local str = GUITips.RSI_EQUIP_INIT_ATTR..": "..Utils:getAttrStr(cfg.attr[1],cfg.attr[2])
    self.m_attrLabel:setString(str)

    if self.m_icon == nil then
        self.m_icon = ItemCellUI:New(self.m_iconNode)
        self.m_icon.m_pUILayer:setAnchorPoint(cc.p(0.5, 0.5))
    end

    local itemValue = {isShowQualityBg = true}
    local petEquipData = {
        id = self.m_id,
    }
    itemValue.petEquipData = petEquipData
    self.m_icon:UpdateItem(itemValue)
end

function EquipGetUI:CloseUI()
    LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "PetEquip.EquipGetUI")
    self:SendMsg(LGameMsg.m_deleteUIMsg)
end

function EquipGetUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_pNode = nil
    self.m_id = nil
    self.Script  = nil
end

return EquipGetUI