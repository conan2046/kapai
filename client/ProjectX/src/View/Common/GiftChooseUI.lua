
local GiftChooseUI = LUIBase:New()
GiftChooseUI.__index = GiftChooseUI
--local this = LTcpSocket
function GiftChooseUI:New(userData)
	local o = LUIBase:New()
	setmetatable(o,GiftChooseUI)	
    o:Init(userData)
	return o
end

--注册事件
-- -----------------------------------
function GiftChooseUI:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function GiftChooseUI:ProcessEvent(msg)

end

function GiftChooseUI:Init(userData)
    self.m_pUILayer = cc.CSLoader:createNode("csd/common/OpenBox_1Layer.csb")
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

function GiftChooseUI:InitData( data )
    self.m_id = data or 0
    self.m_cnt = 1
    self.m_checkBoxs = {}
end

function GiftChooseUI:InitControlUI()
    -- body
    local panel = self.m_pUILayer:getChildByName("OpenBox"):getChildByName("Panel")
    self.m_listView = panel:getChildByName("Bg"):getChildByName("ListView")
    --self.m_listView:setDirection(LISTVIEW_DIR_VERTICAL)
    self.m_cellItem = panel:getChildByName("Item")
    self.m_useBtn = panel:getChildByName("Button")
    self.m_useBtn:addClickEventListener(handler(self,GiftChooseUI.BtnCallBack))

    local numPanel = panel:getChildByName("TimesBg")
    self.m_numLabel = numPanel:getChildByName("Value")
    local subBtn = numPanel:getChildByName("Btn_L")
    subBtn:addClickEventListener(handler(self, GiftChooseUI.OnSubClick))
    local addBtn = numPanel:getChildByName("Btn_R")
    addBtn:addClickEventListener(handler(self, GiftChooseUI.OnAddClick))
    local sub2Btn = numPanel:getChildByName("Btn_L_0")
    sub2Btn:addClickEventListener(handler(self, GiftChooseUI.OnSub10Click))
    local add2Btn = numPanel:getChildByName("Btn_R_0")
    add2Btn:addClickEventListener(handler(self, GiftChooseUI.OnAdd10Click))
    
    Utils:SendMsg(LUIPopFClassBgEvent.SetCloseCallback, handler(self,GiftChooseUI.ColseUI))
    Utils:SendMsg(LUIPopFClassBgEvent.SetTitle, GUITips.RSI_ITEM_TIPS1)
end

function GiftChooseUI:UpdateUI()
    self:ShowCnt()
    self:ShowItemList()
end

function GiftChooseUI:ShowCnt()
    self.m_numLabel:setString(""..self.m_cnt)
end

function GiftChooseUI:ShowItemList()
    local cfg = JsonConfig.m_Item.getDefByID(self.m_id)
    if cfg == nil then
        return
    end
    local num = 1
    for i=1,#cfg.sub_value do
        local value = cfg.sub_value[i]
        if #value == 3 and self:ShowOneItem(value,num) then
            num = num +1
        end
    end

end

function GiftChooseUI:ShowOneItem(value,idx)
    local id = value[1] or 0
    if id == 0 then
        return false
    end
    local num = value[3] or 0
    if num == 0 then
        num = 1
    end
    --dump(value)
    local cell = self.m_cellItem:clone()
    self.m_listView:pushBackCustomItem(cell)

    local iconBgImg = cell:getChildByName("IconBg")
    local cntLabel = cell:getChildByName("Num")--拥有数量
    local nameLabel = iconBgImg:getChildByName("Name")
    local gird = iconBgImg:getChildByName("Bg")
    cntLabel:setString("")
    local name = ""
    local quality = 1
    local cfg = nil
    if id == AppDef.RewardItem.RD_ITEM_PET then
        local petData = LPetData:New(value[2])
        name = petData.baseData.name
        quality = petData.baseData.quality
        Utils:GetPetHeadCellValue(gird, nil, petData, true, true, true)
    elseif id == AppDef.RewardItem.RD_ITEM_EQUIP then
         cfg = JsonConfig.m_equipConfig.getDefByID(value[2])
        if cfg ~= nil then
            name = cfg.name
            quality = cfg.quality
        end
        Utils:GetEquipCellByEquipID(gird, nil, value[2], true, true,true)
    elseif id == AppDef.RewardItem.RD_ITEM_FABAO then
        cfg = JsonConfig.m_faBaoConfig.getDefByID(value[2])
        if cfg ~= nil then
            name = cfg.name
            quality = cfg.quality
        end
        Utils:GetFaBaoCellValue(gird,nil,value[2],0, true, num, 0,0,true,true)
    else
        cfg = JsonConfig.m_Item.getDefByID(id)
        if cfg ~= nil then
            name = cfg.name
            quality = cfg.quality
        end
        local cnt = LRoleDataMgr.Equip:CountItemNumById(id)
        cntLabel:setString(GUITips.RSI_ITEM_TIPS2..":"..cnt)
        local item = Utils:GetItemCellValue(gird, 0, id, true, true, num, nil, true, true)
        item:SetShowFrom(false)
    end
    nameLabel:setString(name)
    nameLabel:setColor(AppDef:GetQualityColor(quality))

    self.m_checkBoxs[idx] = cell:getChildByName("CheckBox")
    self.m_checkBoxs[idx]:setSelected(false)
    self.m_checkBoxs[idx].userObject = {idx,id} 
    self.m_checkBoxs[idx]:addEventListener(handler(self, GiftChooseUI.CheckBoxCallback))
    return true
end

function GiftChooseUI:CheckBoxCallback(sender,eventType)
    local value = sender.userObject
    local idx = value[1] or 1
    print("GiftChooseUI:CheckBoxCallback",idx,value[2])
    if eventType == ccui.CheckBoxEventType.selected then
        for k,v in pairs(self.m_checkBoxs) do
            if k ~= idx then
                self.m_checkBoxs[k]:setSelected(false)
            end
        end
        self.m_chooseValue = {value[1],value[2]}
    elseif eventType == ccui.CheckBoxEventType.unselected then
        self.m_chooseValue = nil
    end
end

function GiftChooseUI:OnAddClick()
    if self.m_id == 0 then
        return
    end
    local maxCnt = LRoleDataMgr.Equip:CountItemNumById(self.m_id)
    local max = math.min(maxCnt,100)
    if self.m_cnt >= max then
        return
    end
    self.m_cnt = self.m_cnt +1
    if self.m_cnt > max then
        self.m_cnt = max
    end
    self:ShowCnt()
end

function GiftChooseUI:OnSubClick()
    if self.m_id == 0 or self.m_cnt == 1 then
        return
    end
    self.m_cnt = self.m_cnt -1
    if self.m_cnt < 1 then
        self.m_cnt = 1
    end
    self:ShowCnt()
end

function GiftChooseUI:OnAdd10Click()
    if self.m_id == 0 then
        return
    end
    local maxCnt = LRoleDataMgr.Equip:CountItemNumById(self.m_id)
    local max = math.min(maxCnt,100)
    if self.m_cnt >= max then
        return
    end
    self.m_cnt = self.m_cnt +10
    if self.m_cnt > max then
        self.m_cnt = max
    end
    self:ShowCnt()
end

function GiftChooseUI:OnSub10Click()
    if self.m_id == 0 or self.m_cnt == 1 then
        return
    end
    self.m_cnt = self.m_cnt -10
    if self.m_cnt < 1 then
        self.m_cnt = 1
    end
    self:ShowCnt()
end

function GiftChooseUI:BtnCallBack()
    if self.m_chooseValue == nil or #self.m_chooseValue ~= 2 then
        Utils:SendMsg(LUILogicEvent.ShowSrcollTips,GUITips.RSI_ITEM_TIPS3)
        return
    end
    --使用道具（多选一礼包）
    --print("GiftChooseUI:BtnCallBack",self.m_chooseValue[1],self.m_chooseValue[2])
    local pos = LRoleDataMgr.Equip:FindPackageItemById1(self.m_id)
    if pos > 0 then
        LuaNetSendMsg:SendItemUseReq(pos-1,self.m_cnt,self.m_chooseValue[1])
    end
    self:ColseUI()
end

function GiftChooseUI:ColseUI()
    Utils:DeleteUI("Common.GiftChooseUI")
end

function GiftChooseUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
    self.m_id = nil
    self.m_cnt = nil
    self.m_checkBoxs = nil
    self.m_chooseValue = nil
end

return GiftChooseUI