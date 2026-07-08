local RandPetUI = LUIBase:New()
RandPetUI.__index = RandPetUI

function RandPetUI:New(userData)
    local o = LUIBase:New()
    setmetatable(o,RandPetUI)  
    o:Init(userData)
    return o
end

--[[
注册UI消息
]]
RandPetUI.IsHideInBattle = false
function RandPetUI:RegistMsgs()
    self.msgIds = 
    {
        --LUIWingDataEvent.SetWingState,
    }
    self:RegistSelf(self,self.msgIds)
end

function RandPetUI:ProcessEvent(msg)
--    if msg.msgId == LUIWingDataEvent.SetWingState then
--    end
end

function RandPetUI:Init(userData)
    self:RegistMsgs()
    self.m_pUILayer = cc.CSLoader:createNode("csd/chouchongLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitData(userData)
    self:AddTouchEvt()
end

function RandPetUI:onExit()
    self:Destory()
    --self.m_pButton = nil    
end

function RandPetUI:AddTouchEvt()
    local function RotateCallback(sender)
        self:RotatePet()
    end
    self.m_pRotateBtn:addClickEventListener(RotateCallback)
	self:MarkIntaractCObj(self.m_pRotateBtn)
end

function RandPetUI:InitData(userData)
    self.m_type = userData[1]
    self.m_ItemList = userData[2]
    self.m_getSign = userData[3]
    self.m_msg = userData[4] or ""

    local panelUI = self.m_pUILayer:getChildByName("chouchong_UI")
    self.m_pUILayer:getChildByName("bg"):setTouchEnabled(true)
    self.m_pRotateBg = panelUI:getChildByName("bg")
    -- 抽按钮
    self.m_pPets = {}
    local petCnt = #self.m_ItemList or 0
    if petCnt > 8 then 
        petCnt = 8
    end
    for i=1,petCnt do
        self.m_pPets[i] = self.m_pRotateBg:getChildByName("Item_"..i):getChildByName("Icon")
        self.m_pPets[i]:loadTexture(string.format("item/equip%d.png", self.m_ItemList[i].picId), ccui.TextureResType.localType)
    end
    self.m_pSingleAngle = 360 / 8
    self.m_pOffsetAngle = 5  -- 为了避免不必要的麻烦，在接近2个奖项的交界处，左右偏移n角度的位置，统统不停留 否则停在交界线上，很难解释清楚 这个值必须小于最小奖项所占角度的1/2

    self.m_pRotateBtn = panelUI:getChildByName("Button")
    self.m_pIdex = self.m_getSign

    local titleLabel = panelUI:getChildByName("Title"):getChildByName("Text")
    if self.m_type == 2 then--，1:宠物抽取，2:礼盒抽取
        titleLabel:setString(GUITips.RSI_RANDPET_TITLE2)
        LRoleDataMgr.m_isShowRandPetUI = true
    else
        titleLabel:setString(GUITips.RSI_RANDPET_TITLE1)
    end

    
end

function RandPetUI:RotatePet()
    --self.m_pIdex = self.m_pIdex + 1
    if self.m_pIdex > 8 or self.m_pIdex < 1 then self.m_pIdex = 1 end
    local roundCount = math.random(5, 8)
    local num = self.m_pIdex -1
    local angleMin = 360 - num * self.m_pSingleAngle
    local angleTotal = 360*roundCount + angleMin
    local sec = math.random(15, 35)  -- 控制转的时间
    local function rotateEnd()
        self:ShowPet()
    end
    self.m_pRotateBtn:setTouchEnabled(false)
    self.m_pRotateBg:setRotation(0)
    local sq = cc.Sequence:create(cc.EaseExponentialOut:create(cc.RotateBy:create(sec / 10,angleTotal)), cc.CallFunc:create(rotateEnd))
    self.m_pRotateBg:runAction(sq)
end

function RandPetUI:ShowPet()
    local function scaleEnd()
        -- local data = {
        --     data = , --LLuckyDrawResultInfo
        --     castId = 0,--再抽一次需要消耗的道具ID
        --     continueCb = .,--再抽一次回调
        -- }
        -- LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "LuckyDraw.LDSingleRetUI", AppDef.UIType.PopWindow, data)
        -- self:SendMsg(LGameMsg.m_initUIMsg)
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Instances.RandPetUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    local sq = cc.Sequence:create(cc.ScaleTo:create(0.4,1.3), cc.ScaleTo:create(0.4,1.0), cc.CallFunc:create(scaleEnd))
    self.m_pPets[self.m_pIdex]:getParent():runAction(sq)

    if self.m_type == 2 then
        LRoleDataMgr.m_isShowRandPetUI = false
        local data = self.m_ItemList[self.m_getSign]
        if data == nil then return end
        local pic = data.picId
        if data.itemId == AppDef.AwrdItem.AWRD_ITEM_COIN then
            local flyItem = LFlyItem:New(LFlyItem.FlyType.Money,data.itemNum)
            Utils:SendMsg(LUILogicEvent.ShowFlyItems,flyItem)
        elseif data.itemId == AppDef.AwrdItem.AWRD_ITEM_POTEN then
            local flyItem = LFlyItem:New(LFlyItem.FlyType.Qianneng,data.itemNum)
            Utils:SendMsg(LUILogicEvent.ShowFlyItems,flyItem)
        elseif data.itemId == AppDef.AwrdItem.AWRD_ITEM_EXP then
            --暂无
        else
            local flyItem = LFlyItem:New(LFlyItem.FlyType.Item,data.itemId)
            Utils:SendMsg(LUILogicEvent.ShowFlyItems,flyItem)
        end
        if  #self.m_msg > 0 then
            Utils:ShowScrollTips(self.m_msg)
        end
    end

end

return RandPetUI