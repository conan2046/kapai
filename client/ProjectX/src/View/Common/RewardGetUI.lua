local RewardGetUI = LUIBase:New()
RewardGetUI.__index = RewardGetUI
RewardGetUI.IsHideInBattle = true
function RewardGetUI:New(userData)
    local o = LUIBase:New()
    setmetatable(o,RewardGetUI) 
    o:Init(userData)
    return o
end

function RewardGetUI:Init(userData)
    self.Script = "Common.RewardGetUI"
    self:CreateUINode("csd/common/tanchuangjiangli.csb")
    -- self.m_pUILayer = cc.CSLoader:createNode("csd/common/tanchuangjiangli.csb")
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:InitParam(userData)
    self:InitData()
    self:ShowInfo()
    --self:RegisterGuide()
    --Utils:SendMsg(LUISecondClassBgEvent.SetTitle, GUITips.UI_Title_XueZhan)
    --Utils:SendMsg(LUISecondClassBgEvent.SetCloseCallback,handler(self,RewardGetUI.CloseUI))
end

--[[
注册UI消息
]]
function RewardGetUI:RegistMsgs()
    self.msgIds = 
    {
        LUIRewardGetEvent.RegisterDrawGuide,
    }
    self:RegistSelf(self,self.msgIds)
end

function RewardGetUI:ProcessEvent(msg)
    if msg:GetMsgId() == LUIRewardGetEvent.RegisterDrawGuide then
        self:RegisterDrawGuide(msg.value)
    end
end

function RewardGetUI:InitParam(userData)
    self.m_closedCallBack = userData["closedCallBack"]
    self.m_callback = userData["callback"]
    self.m_rewards = userData["rewards"] or {}
    self.m_title = userData["title"] or ""
    self.m_isShowBtn = userData["isShowBtn"]
    if self.m_isShowBtn  then
        self.m_tips = userData["tips"] or GUITips.RSI_GS_TIP_RECOVERY_DRAW
    else
        self.m_tips = userData["tips"] or GUITips.RSI_BOX_TIP1
    end
end

function RewardGetUI:InitData()
    
    local panel = self.m_pUILayer:getChildByName("Popup")
    --领取按钮
    self.m_btn = panel:getChildByName("btn_lingqu")
    self.m_btn:addClickEventListener(handler(self, RewardGetUI.OnDrawClick))
    --关闭按钮
    local closeBtn = self.m_pUILayer:findChildByName("Popup/Btn_close")
    closeBtn:addClickEventListener(handler(self, RewardGetUI.OnCloseClick))

    local titlePanel = panel:getChildByName("Title")
    self.m_titleLabel = titlePanel:getChildByName("Title_1")
    titlePanel:getChildByName("Title_2"):setString("")

    self.m_listView = panel:getChildByName("ListView")
    self.m_cell = panel:getChildByName("ItemList")
    self.m_moneyCell = panel:getChildByName("ItemList")
    self.m_tipsLabel = panel:getChildByName("tips")

    self._petCell = self.m_pUILayer:getChildByName("petCell")
    self._petCell:setVisible(false)

    self.m_item = {}
    self.m_itemRewards = {}
    self.m_moneyRewards = {}
end

function RewardGetUI:OnDrawClick()
    if self.m_callback ~= nil then
        self.m_callback()
        Utils:CheckGuide(GuideDef.StepId.Guide_FuBen2_2,true)
        Utils:CheckGuide(GuideDef.StepId.Guide_FuBen3_2,true)
    end
    self:RemoveUI()
end

function RewardGetUI:GetRewardInfo()
    self.m_itemRewards = {}
    self.m_moneyRewards = {}
    for i=1,#self.m_rewards do
        local data = self.m_rewards[i]
        -- local cfg = JsonConfig.m_Item.getDefByID(data.id)
        -- if cfg ~= nil then
        --     if cfg.type == 13 then
        --         table.insert(self.m_moneyRewards,data)
        --     else
                
        --     end
        -- end
        table.insert(self.m_itemRewards,data)
    end
end

function RewardGetUI:ShowInfo()
    self:GetRewardInfo()
    self.m_titleLabel:setString(""..self.m_title)
    self.m_tipsLabel:setString("")
    local max = math.floor((#self.m_itemRewards -1)/4)+1

    -- dump(self.m_itemRewards,"---------->self.m_itemRewards")
    self.m_listView:removeAllItems()
    for i=1,max do
        local node = self.m_cell:clone()
        node.userObject = i
        for k=1,4 do
            local idx = (i-1)*4+k
            local value = self.m_itemRewards[idx]
            local cell = node:getChildByName("itemlayer_"..k)
            cell.userObject = idx
            self:ShowCellInfo(cell,value)
        end
        self.m_listView:pushBackCustomItem(node)
    end
    -- max = math.floor((#self.m_moneyRewards -1)/4)+1
    -- for i=1,max do
    --     local node = self.m_moneyCell:clone()
    --     node.userObject = i
    --     for k=1,4 do
    --         local idx = (i-1)*4+k
    --         local value = self.m_moneyRewards[idx]
    --         local cell = node:getChildByName("huobi_"..k)
    --         cell.userObject = idx
    --         self:ShowMoneyCellInfo(cell,value)
    --     end
    --     self.m_listView:pushBackCustomItem(node)
    -- end

    if not self.m_isShowBtn then
        self.m_btn:setVisible(false)
        self.m_tipsLabel:setString(self.m_tips)
    else
        local btnLabel = self.m_btn:getChildByName("Text1")
        btnLabel:setString(self.m_tips)
    end
end

-- function RewardGetUI:ShowMoneyCellInfo(cell,data)
--     local numLabel = cell:getChildByName("GoldNumBg"):getChildByName("Num")
--     if data == nil then
--         cell:setVisible(false)
--         numLabel:setString("")
--         return
--     end
--     cell:setVisible(true)
--     numLabel:setString(data.num)
--     local str = "item/equip"..LRoleDataMgr.GetItemPicId(data.id)..".png"
--     Utils:SafeLoadTexture(cell,str,ccui.TextureResType.localType)
-- end

function RewardGetUI:ShowCellInfo(cell,data)
    if data == nil then
        cell:setVisible(false)
        return
    end

    cell:setVisible(true)
    local idx = cell.userObject
    local nameLabel = cell:getChildByName("Name")
    local grid = cell:getChildByName("item")
    
    local strName = ""
    local quality = 0;
    -- local addNum = data[2]
    if data[1] == AppDef.RewardItem.RD_ITEM_EQUIP then
        -- data[2] = data[3]
        -- if addNum > 0 then
        --     data[3] = addNum
        -- end
        local cfg = JsonConfig.m_equipConfig.getDefByID(data[2])
        if cfg ~= nil then
            strName = cfg.name;
            quality = cfg.quality;
            
        end
    elseif data[1]== AppDef.RewardItem.RD_ITEM_PET then
        -- data[2] = data[3]
        -- if addNum > 0 then
        --     data[3] = addNum
        -- end
        local info = LPetDataMgr:FindPetDataById(data[2])
        strName = info.name;
        quality = info.quality;
    elseif data[1] == AppDef.RewardItem.RD_ITEM_FABAO then
        -- data[2] = data[3]
        -- if addNum > 0 then
        --     data[3] = addNum
        -- end
        local info = JsonConfig.m_faBaoConfig.getDefByID(data[2])
        strName = info.name;
        quality = info.quality;
    else
        local info = JsonConfig.m_Item.getDefByID(data[1])
        strName = info.name;
        quality = info.quality;
    end
    nameLabel:setString(strName)
    nameLabel:setColor(AppDef:GetQualityColor(quality))

    Utils:ShowItemByConfigData(data, grid, nil, true, true)

    -- if data.type and data.type == 1 then
    --     self.m_item[idx] = Utils:GetEquipCellValue(grid,self.m_item[idx],data.id,0,nil,nil,nil,nil,false,false,true)
    --     local cfg = JsonConfig.m_equipConfig.getDefByID(data.id)
    --     if cfg ~= nil then
    --         nameLabel:setString(cfg.name)
    --         nameLabel:setColor(AppDef:GetQualityColor(cfg.quality))
    --     end
    -- elseif data.type and data.type == 2 then
    --     local info = LPetDataMgr:FindPetDataById(data.id)
    --     local iconNode = self._petCell:clone()
    --     iconNode:setVisible(true);
    --     grid:addChild(iconNode);
    --     iconNode:setPosition(cc.p(0,0));
    --     Utils:ShowPet(data.id, grid, iconNode)
    --     nameLabel:setString(info.name)
    --     nameLabel:setColor(AppDef:GetQualityColor(info.quality))
    -- elseif data.type and data.type == 3 then
    --     --grid,pItem,faBaoId,uid, isShowNum, num, qhLv,jlLv,isOpenTouch,isChangeSize
    --     --print("fabao",data.id)
    --     self.m_item[idx] = Utils:GetFaBaoCellValue(grid,self.m_item[idx],data.id,nil,false)
    --     local cfg = JsonConfig.m_faBaoConfig.getDefByID(data.id)
    --     if cfg ~= nil then
    --         nameLabel:setString(cfg.name)
    --         nameLabel:setColor(AppDef:GetQualityColor(cfg.quality))
    --     end
    -- else
    --     self.m_item[idx] = Utils:GetItemCellValue(grid, 0, data.id, true, true, data.num, self.m_item[idx], false, true)
    --     local cfg = JsonConfig.m_Item.getDefByID(data.id)
    --     if cfg ~= nil then
    --         nameLabel:setString(cfg.name)
    --         nameLabel:setColor(AppDef:GetQualityColor(cfg.quality))
    --     end
    -- end
end

function RewardGetUI:UpdateUserData(userData)
    self:InitParam(userData)
    self:ShowInfo()
end

function RewardGetUI:CloseUI()
    LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Common.RewardGetUI")
    self:SendMsg(LGameMsg.m_deleteUIMsg)
end

function RewardGetUI:OnCloseClick(sender )
    if self.m_closedCallBack ~= nil then
        self.m_closedCallBack()
    end
    self:RemoveUI()
end

function RewardGetUI:onExit()
    if self.m_guideStep then
        for k,v in pairs(self.m_guideStep) do
            Utils:SendMsg(LUIGuideEvent.UnRegisterStep, v)
            self.m_guideStep[k] = nil
        end
        self.m_guideStep = nil
    end
    self:Destory()
    self.m_pUILayer = nil
    self.m_callback = nil
    self.m_closedCallBack = nil
    self.m_rewards = nil
    self.m_title = nil
    self.Script  = nil
end

-- function RewardGetUI:RegisterGuide()
--     if self.m_callback ~= nil then
--         Utils:RegisterGuide(GuideDef.StepId.Guide_FuBen2_1,self.m_btn,handler(self,RewardGetUI.OnDrawClick), nil)
--         Utils:RegisterGuide(GuideDef.StepId.Guide_FuBen3_1,self.m_btn,handler(self,RewardGetUI.OnDrawClick), nil)
--     end
-- end

function RewardGetUI:RegisterDrawGuide(stepId)
    self.m_guideStep = self.m_guideStep or {}
    self.m_guideStep[stepId] = stepId
    Utils:RegisterGuide(stepId, self.m_btn, handler(self, RewardGetUI.OnDrawClick), nil, true)
end

return RewardGetUI