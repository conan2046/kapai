
local GiftShowUI = LUIBase:New()
GiftShowUI.__index = GiftShowUI
--local this = LTcpSocket
function GiftShowUI:New(userData)
	local o = LUIBase:New()
	setmetatable(o,GiftShowUI)	
    o:Init(userData)
	return o
end

--注册事件
-- -----------------------------------
function GiftShowUI:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function GiftShowUI:ProcessEvent(msg)

end

function GiftShowUI:Init(userData)

    self.m_pUILayer = cc.CSLoader:createNode("csd/common/OpenBox_2Layer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:InitData(userData)
    self:InitControlUI()
    self:UpdateUI()
end

function GiftShowUI:InitData( data )
    self.m_id = data or 0
end

function GiftShowUI:InitControlUI()
    -- body
    local panel = self.m_pUILayer:getChildByName("OpenBox")

    self.m_listView = panel:getChildByName("Image_Bg"):getChildByName("ListView")
    --self.m_listView:setDirection(LISTVIEW_DIR_VERTICAL)
    self.m_cellItem = panel:getChildByName("IconGroup")
    self.m_closeBtn = panel:getChildByName("Btn_close")
    self.m_closeBtn:addClickEventListener(handler(self,GiftShowUI.ColseUI))
    self.m_itemGrid = panel:getChildByName("Item")
    self.m_nameLabel = self.m_itemGrid:getChildByName("Name")
    self.m_numLabel = self.m_itemGrid:getChildByName("Text")
end

function GiftShowUI:UpdateUI()
    self:ShowCnt()
    self:ShowItemList()
end

function GiftShowUI:ShowCnt()
    if self.m_id == 0 then
        return
    end
    local num = LRoleDataMgr.Equip:CountItemNumById(self.m_id)
    self.m_numLabel:setString(GUITips.RSI_ITEM_TIPS2..": "..num)
    Utils:GetItemCellValue(self.m_itemGrid, 0, self.m_id, true, false, 0, nil, false, true) 
end

function GiftShowUI:ShowItemList()
    local cfg = JsonConfig.m_Item.getDefByID(self.m_id)
    if cfg == nil then
        return
    end
    self.m_nameLabel:setString(cfg.name)
    self.m_nameLabel:setColor(AppDef:GetQualityColor(cfg.quality))
    local max = math.ceil(#cfg.sub_value/6)
    for i=1,max do
        local cell = self.m_cellItem:clone()  
        for k=1,6 do
            local idx = (i-1)*6+k
            print("GiftShowUI:ShowItemList",idx)
            local data = cfg.sub_value[idx]
            local sender = cell:getChildByName("IconBg"..k)
            sender.userObject = idx
            self:ShowOneItem(sender,data)
        end
        self.m_listView:pushBackCustomItem(cell)
    end

end

function GiftShowUI:ShowOneItem(sender,value)
    if sender == nil then
        return
    end

    if value == nil or #value ~= 2 then
        sender:setVisible(false)
        return
    end
    local id = value[1] or 0
    local cfg = JsonConfig.m_Item.getDefByID(id)
    if cfg == nil then
        return
    end
    local num = value[2] or 0
    if num == 0 then
        num = 1
    end
    Utils:GetItemCellValue(sender, 0, id, true, true, num, nil, true, true)    
end

function GiftShowUI:ColseUI()
    Utils:DeleteUI("Common.GiftShowUI")
end

function GiftShowUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
    self.m_id = nil
end

return GiftShowUI