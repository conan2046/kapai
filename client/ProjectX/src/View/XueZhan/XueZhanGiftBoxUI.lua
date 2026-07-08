local XueZhanGiftBoxUI = LUIBase:New()
XueZhanGiftBoxUI.__index = XueZhanGiftBoxUI
XueZhanGiftBoxUI.IsHideInBattle = true
function XueZhanGiftBoxUI:New()
    local o = LUIBase:New()
    setmetatable(o,XueZhanGiftBoxUI) 
    o:Init()
    return o
end

function XueZhanGiftBoxUI:Init()
    self.Script = "XueZhan.XueZhanGiftBoxUI"
    self.m_pUILayer = cc.CSLoader:createNode("csd/xuezhan/Xuezhanjiangliyulan.csb")
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitData()
    self:ShowInfo()

    --Utils:SendMsg(LUISecondClassBgEvent.SetTitle, GUITips.UI_Title_XueZhan)
    Utils:SendMsg(LUISecondClassBgEvent.SetCloseCallback,handler(self,XueZhanGiftBoxUI.CloseUI))
end

function XueZhanGiftBoxUI:InitData()
    local panel = self.m_pUILayer:getChildByName("Popup")


    --领取按钮
    self.m_btn = panel:getChildByName("btn_lingqu")
    self.m_btn:addClickEventListener(handler(self, XueZhanGiftBoxUI.OnDrawClick))
    local closeBtn = panel:getChildByName("Btn_close")
    closeBtn:addClickEventListener(handler(self, XueZhanGiftBoxUI.CloseUI))
    
    local listPanel = panel:getChildByName("ItemList")
    self.m_stars = {}
    --self.m_passImgs = {}
    self.m_itemIcons = {}
    self.m_items = {}
    self.m_nameLabels = {}
    for i=1,3 do
        local item = listPanel:getChildByName("Panel_"..i)
        self.m_itemIcons[i] = item:getChildByName("ItemIcon")
        --self.m_passImgs[i] = item:getChildByName("Image2")
        --self.m_passImgs[i]:setVisible(false)
        self.m_stars[i] = item:getChildByName("Image_titlebg"):getChildByName("Num")
        self.m_nameLabels[i] = item:getChildByName("itemname")
    end
end

function XueZhanGiftBoxUI:OnDrawClick()
    --LuaNetSendMsg:QueryXueZhanInfo(5)
end

function XueZhanGiftBoxUI:ShowInfo()
    local data = LActivityManager:GetXueZhanData()
    local fiveLevelId = (math.floor((data.m_levelId-1)/5)+1)*5
    local cfg = JsonConfig.m_bloodBattle.getDefByID(fiveLevelId)
    if cfg == nil or cfg.reward_fixed == nil then
        return
    end
    local fiveStar = data.m_giftBoxs.fiveStar
    --local sign = false
    for i=1,3 do
        self.m_nameLabels[i]:setString("")
        local value = data.m_giftBoxs.box[i]
        local fixed = cfg.reward_fixed[i]
        local rewardCfg = nil
        if fixed ~= nil and fixed[2] ~= nil then
            rewardCfg = JsonConfig.m_BoxReward.getDefByID(fixed[2])
        end
        if rewardCfg ~= nil then
            self.m_items[i] = Utils:GetItemCellValue(self.m_itemIcons[i], 0, rewardCfg.reward[1][1], true, true, rewardCfg.reward[1][3], self.m_items[i], true, true)
            if self.m_stars[i] ~= nil and fixed[1] > 1 then
                self.m_stars[i]:setString(""..fixed[1])
            end
            local itemCfg = JsonConfig.m_Item.getDefByID(rewardCfg.reward[1][1])
            if itemCfg ~= nil then
                self.m_nameLabels[i]:setString(itemCfg.name)
            end
        end
        -- if value ~= nil then
        --     local star = value.star
        --     if self.m_passImgs[i] ~= nil then
        --         if fiveStar >= star then
        --             self.m_passImgs[i]:setVisible(true)
        --         end
        --     end
        --     -- if value.state == 1 and not sign then
        --     --     sign = true
        --     -- end
        -- end
    end

    --dump(sign)
    --领取按钮灰化
    --if not sign then
        self.m_btn:setBright(false)
        self.m_btn:setEnabled(false)
    --end
end

function XueZhanGiftBoxUI:CloseUI()
    LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "XueZhan.XueZhanGiftBoxUI")
    self:SendMsg(LGameMsg.m_deleteUIMsg)
end

function XueZhanGiftBoxUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_pNode = nil
    self.m_id = nil
    self.Script  = nil
end

return XueZhanGiftBoxUI