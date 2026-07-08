local LDPetRewardUI = LUIBase:New()
LDPetRewardUI.__index = LDPetRewardUI

--[[
    data=kind
]]
-------------------------------------
function LDPetRewardUI:New(data)
    local o = LUIBase:New()
    setmetatable(o, LDPetRewardUI)
    o:Init(data)
    return o
end
-------------------------------------
function LDPetRewardUI:Init(data)
    self.Script = "LuckyDraw.LDPetRewardUI"
    ------------------------------------------------
    self.m_data = nil
    ------------------------------------------------
    self.m_pPetList = nil
    self.m_pListModel = nil
    self.m_pRewardList = nil
    self.m_pItemModel = nil
    ------------------------------------------------
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()

    -----------------------------------------------
    if data then
        self:updateData(data)
    end
end
-------------------------------------
function LDPetRewardUI:onExit()
    self:Destory()
    Utils:FreeTable(self.m_data)
    self.m_data = nil
    self.m_pUILayer = nil
    self.m_pListModel:release()
    self.m_pListModel = nil
    self.m_pItemModel:release()
    self.m_pItemModel = nil

    self.m_pPetList = nil
    self.m_pRewardList = nil
end
-------------------------------------
function LDPetRewardUI:InitUIControl()
    local pPanel = self.m_pUILayer:getChildByName("Panel")
    -----------------------------------------------------------
    local pReward = pPanel:getChildByName("Reward")
    -----------------------------------------------------------
    local pBg1 = pReward:getChildByName("Bg1")
    self.m_pPetList = pBg1:getChildByName("List")
    -----------------------------------------------------------
    local pBg2 = pReward:getChildByName("Bg2")
    self.m_pListModel = pBg2:getChildByName("List")
    self.m_pListModel:retain()
    self.m_pListModel:setTouchEnabled(false)
    self.m_pListModel:removeFromParent(false)
    -----------------------------------------------------------
    self.m_pRewardList = pBg2:getChildByName("RewardList")
    -----------------------------------------------------------
    self.m_pItemModel = pBg2:getChildByName("IconBg_1")
    self.m_pItemModel:retain()
    self.m_pItemModel:removeFromParent(false)
end
-------------------------------------
function LDPetRewardUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    
    Utils:SendMsg(LUISecondClassBgEvent.SetCloseCallback, handler(self, LUIBase.RemoveUI))
    Utils:SendMsg(LUISecondClassBgEvent.SetTitle, GUITips.RSI_LD_TITLE)
end
-------------------------------------
function LDPetRewardUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/PetRewardLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

function LDPetRewardUI:updateData(id)
    if id == nil then
        return
    end

    local data = LDataConstMgr:getPetDrawDetailConfig(id)
    if data == nil then
        return
    end
    Utils:FreeTable(self.m_data)
    self.m_data = nil
    self.m_data = {{},{}}
    for i=1,#data do
        local it = data[i]
        if it.id ~= nil then
            table.insert(self.m_data[1], it)
        elseif it.itemID ~= nil then
            table.insert(self.m_data[2], it)
        end
    end

    self:updatePetReward()
    self:updateItemReward()
end

function LDPetRewardUI:updatePetReward()
    local datas = self.m_data[1]
    self.m_pPetList:removeAllItems()
    for i=1,#datas do
        local item = self.m_pItemModel:clone()
        item:setVisible(true)
        item:setTag(datas[i].id)
        item:setTouchEnabled(true)
        item:setSwallowTouches(false)
        item:addClickEventListener(handler(self, LDPetRewardUI.ShowPetInfo))
		self:MarkIntaractCObj(item)
        self:setPetItem(item, datas[i])
        self.m_pPetList:pushBackCustomItem(item)
    end
end

function LDPetRewardUI:ShowPetInfo(sender)
    local id = sender:getTag()
    if id <= 0 then
        return
    end
    self:RemoveUI()
    Utils:SendMsg(LUILogicEvent.ShowPetInfo, {id})
end

function LDPetRewardUI:setPetItem(item, info)
    if item == nil or info == nil then
        return
    end
    local data = LPetDataMgr:FindPetDataById(info.id)
    if data == nil then
        return
    end
    ----------------------------------------------------------------
    local pIcon = item:getChildByName("Icon")
    local pColor = item:getChildByName('Color')
    Utils:ShowPetHeadImg(pIcon, data.pic, pColor, data.quality, data:IsShiny())
    ----------------------------------------------------------------
    local pQualityImage = item:getChildByName("QualityImage")
    pQualityImage:setLocalZOrder(1)
    AppDef:GetPetQualityScore(pQualityImage, data.quality)
    ----------------------------------------------------------------
    local pStarsList = item:getChildByName("StarsList")
    pStarsList:setLocalZOrder(1)
    local pStar = item:getChildByName("Star")
    pStar:retain()
    pStar:removeFromParent(false)
    for i=1,info.star do
        pStarsList:pushBackCustomItem(pStar:clone())
    end
    pStar:release()
    ----------------------------------------------------------------
    local pCareer = item:getChildByName("Career")
    pCareer:setLocalZOrder(1)
    AppDef:ShowProAttrImg(pCareer, data.petType)
    ----------------------------------------------------------------
end

function LDPetRewardUI:updateItemReward()
    local datas = self.m_data[2]
    self.m_pRewardList:removeAllItems()
    local pList = nil

    for i=1,#datas do
        if pList == nil or math.fmod(i, 10) == 0 then
            pList = self.m_pListModel:clone()
            self.m_pRewardList:pushBackCustomItem(pList)
        end
        local pBg = self.m_pItemModel:clone()
        local pItem = pBg:getChildByName("Icon")
        local pIcon = Utils:GetItemCellValue(pBg, 0, datas[i].itemID, true, true, datas[i].itemNum)
        pIcon:SetIsNonAutoFree(true)
        pIcon.m_pUILayer:setAnchorPoint(pItem:getAnchorPoint())
        pIcon.m_pUILayer:setPosition(cc.p(pItem:getPosition()))
        pList:pushBackCustomItem(pBg)

        pItem:setVisible(false)
        pBg:getChildByName("QualityImage"):setVisible(false)
        pBg:getChildByName("StarsList"):setVisible(false)
        pBg:getChildByName("Star"):setVisible(false)
        pBg:getChildByName("Career"):setVisible(false)
        pBg:getChildByName("Color"):setVisible(false)
    end
end

return LDPetRewardUI