local ShenqiGiftUI = LUIBase:New()
ShenqiGiftUI.__index = ShenqiGiftUI

function ShenqiGiftUI:New()
    local o = LUIBase:New()
    setmetatable(o,ShenqiGiftUI)  
    o:Init()
    return o
end

--[[
注册UI消息
]]
function ShenqiGiftUI:RegistMsgs()
    self.msgIds = 
    {
        LUIWelfareEvent.RefreshStageGoal,
    }
    self:RegistSelf(self,self.msgIds)
end

function ShenqiGiftUI:ProcessEvent(msg)
    if msg.msgId == LUIWelfareEvent.RefreshStageGoal then
        self:ShowTargetList()
    end
end

function ShenqiGiftUI:Init()
    self:RegistMsgs()
    self.m_pUILayer = cc.CSLoader:createNode("csd/shenqiGiftLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitData()
    self:AddTouchEvt()
    self:ShowTargetList(LRoleDataMgr.MyHeroInfo.ShenQi.zhangjie)
end

function ShenqiGiftUI:onExit()
    if self.m_pItem then
        self.m_pItem:onExit(true)
    end
    self:Destory()
    --self.m_pButton = nil    
end

function ShenqiGiftUI:AddTouchEvt()
    local function LeftCallback(sender)
        if self.m_pCurShow == 1 then return end
        self.m_pCurShow = self.m_pCurShow - 1
        self:ShowTargetList()
        self:ShowLeftRight()
    end
    self.m_pLeftBtn:addClickEventListener(LeftCallback)
	self:MarkIntaractCObj(self.m_pLeftBtn)
    local function RightCallback(sender)
        if self.m_pCurShow == #LRoleDataMgr.MyHeroInfo.ShenQi.allUnit then return end
        self.m_pCurShow = self.m_pCurShow + 1
        self:ShowTargetList()
        self:ShowLeftRight()
    end
    self.m_pRightBtn:addClickEventListener(RightCallback)
	self:MarkIntaractCObj(self.m_pRightBtn)
    local function ShowTips(sender)
       local ShenQi = LRoleDataMgr.MyHeroInfo.ShenQi
       if ShenQi == nil or self.m_pCurShow == nil or self.m_pCurShow <= 0 then return end
       local unit = ShenQi.allUnit[self.m_pCurShow]
       if unit == nil or unit.unit_id == nil or unit.unit_id <= 0 then return end
       Utils:OpenWearTips("Artifact",unit.unit_id)
    end
    self.m_pUnitRewards[2]:addClickEventListener(ShowTips)
	self:MarkIntaractCObj(self.m_pUnitRewards[2])
    -- local function ccTouchMove(pTouch, pEvent)
    --     if pEvent == ccui.TouchEventType.ended then
    --         self:ccTouchBegin(pTouch, pEvent);
    --     end
    -- end
    
    -- local swallowTouchbg = self.m_pUILayer:getChildByName("swallowTouchbg")
    -- swallowTouchbg:addTouchEventListener(ccTouchBegin)
end

function ShenqiGiftUI:InitData()
    local panel = self.m_pUILayer:getChildByName("shenqiGiftUI")
    -- 左上部
    self.m_leftUpBg = panel:getChildByName("Show")
    -- 左移按钮
    self.m_pLeftBtn = self.m_leftUpBg:getChildByName("btn_Left")
    self.m_pLeftRedDot = self.m_pLeftBtn:getChildByName("Prompt")
    -- 右移按钮
    self.m_pRightBtn = self.m_leftUpBg:getChildByName("btn_Right")
    self.m_pRightRedDot = self.m_pRightBtn:getChildByName("Prompt")
    -- 章节名称
    self.m_pChapterName = self.m_leftUpBg:getChildByName("Name"):getChildByName("Text")
    -- 动画节点
    self.m_pImodNode = self.m_leftUpBg:getChildByName("Node")
    self.m_pArtifactImod = ImodAnim:create()
    local size = self.m_pImodNode:getContentSize()
    self.m_pArtifactImod:setPosition(cc.p(size.width/2, size.height/2))
    self.m_pImodNode:addChild(self.m_pArtifactImod,5,666)

    -- 奖励区--------------------------------------------------
    -- 章节奖励
    local chapterRewardBg = panel:getChildByName("Reword"):getChildByName("ChapterReword")
    -- 领取章节奖励
    self.m_pGetTagetBtn = chapterRewardBg:getChildByName("btn_Get")

    -- 已经领取
    self.m_pAlreadyGet = chapterRewardBg:getChildByName("yilingqu")
    -- 奖励
    self.m_pUnitRewards = {}
    for i=1,3 do
        self.m_pUnitRewards[i] = chapterRewardBg:getChildByName("Reword_"..i)
    end
    self.m_pUnitRewards[2]:setTouchEnabled(true)

    -- 阶段目标 --------------------------------------------------
    local chapterTarget = panel:getChildByName("Target")
    -- 目标列表
    self.m_pTargetList = chapterTarget:getChildByName("ListView")
    -- 目标单元
    self.m_pTargetCell = chapterTarget:getChildByName("Item")
    self.m_pTargetCell:setTouchEnabled(true)

    self.m_pCurShow = LRoleDataMgr.MyHeroInfo.ShenQi.zhangjie
    if self.m_pCurShow == nil or self.m_pCurShow < 1 then 
        self.m_pCurShow = 1
    end
    self:ShowLeftRight()
end

function ShenqiGiftUI:ShowLeftRight()

    local function hasRedDot(idx)
        local ShenQi = LRoleDataMgr.MyHeroInfo.ShenQi
        if ShenQi == nil or idx < 1  then return false end
        local unit = ShenQi.allUnit[idx]
        if unit == nil then return false end
        if unit.unit_wancheng and not unit.unit_lingqu then
            return true
        end

        for key,target in pairs(ShenQi.allTarget) do
            if target.unitid == unit.unit_id then
                if target.isWancheng and not target.isLingqu then
                    return true
                end
            end
        end

        return false
    end

    if self.m_pCurShow == 1 then
        self.m_pLeftBtn:setBright(false)
        self.m_pRightRedDot:setVisible(hasRedDot(2) or hasRedDot(3))
        self.m_pLeftRedDot:setVisible(false)
    elseif self.m_pCurShow == 3 then
        self.m_pRightBtn:setBright(false)
        self.m_pLeftRedDot:setVisible(hasRedDot(2) or hasRedDot(1))
        self.m_pRightRedDot:setVisible(false)
    elseif self.m_pCurShow == 2 then
        self.m_pRightRedDot:setVisible(hasRedDot(3))
        self.m_pLeftRedDot:setVisible(hasRedDot(1))
        self.m_pLeftBtn:setBright(true)
        self.m_pRightBtn:setBright(true)
    end
end

--[[
阶段目标显示
]]
function ShenqiGiftUI:ShowTargetList()
    local ShenQi = LRoleDataMgr.MyHeroInfo.ShenQi
    if self.m_pCurShow == nil or self.m_pCurShow < 1 then
        self.m_pCurShow = 1
    end
    local unit = ShenQi.allUnit[self.m_pCurShow]
    if unit == nil then return end
    self.m_pTargetList:removeAllItems()
    for key,target in pairs(ShenQi.allTarget) do
        if target.unitid == unit.unit_id then
            local cell = self.m_pTargetCell:clone()
            self:ShowTargetCell(cell, target)
            self.m_pTargetList:pushBackCustomItem(cell)
        end
    end

    self:ShowUnitReward(unit)

    if self.m_imod == nil then
        local deskImg = self.m_leftUpBg:getChildByName("Image"):getChildByName("Image_0_0")
        local size = deskImg:getContentSize()
        self.m_imod = Utils:CreateImod("res2/fx/shenqizhanshi",cc.p(size.width/2,size.height/2),deskImg,1)
        self.m_imod:PlayActionRepeat(0)
    end
end

--[[
目标奖励显示
]]
function ShenqiGiftUI:ShowUnitReward(unit)
    self.m_pAlreadyGet:setVisible(false)
    for i=1,3 do
        self.m_pUnitRewards[i]:setVisible(false)
    end
    self.m_pItem = Utils:GetItemCellValue(self.m_pUnitRewards[2], 1, unit.unit_id, true, false, 0, self.m_pItem)
    self.m_pItem:SetIsNonAutoFree(true)
    self.m_pUnitRewards[2]:setVisible(true)

    local png = string.format("%s%s",AppDef.GUIRes["Shenqi_Stage_Ani_"..unit.unit_id], AppDef.GUIRes.Res_Suffix_Png)
    local ani = string.format("%s%s",AppDef.GUIRes["Shenqi_Stage_Ani_"..unit.unit_id], AppDef.GUIRes.Res_Suffix_Ani)
    self.m_pArtifactImod:initAnimWithName(png, ani)
    self.m_pArtifactImod:PlayNewAction(0, true)
    self.m_pChapterName:setString(unit.unitName)

    function GetRewardCallBack(sender)
        LuaNetSendMsg:QueryStageGoalInfo_L(3, self.m_pCurShow)
    end

    self.m_pAlreadyGet:setVisible(false)
    if unit.unit_wancheng then
        self.m_pGetTagetBtn:setBright(true)
        if unit.unit_lingqu then
            self.m_pGetTagetBtn:setVisible(false)
            self.m_pAlreadyGet:setVisible(true)
        else -- 完全 未领取才注册事件
            self.m_pGetTagetBtn:setVisible(true)
            self.m_pAlreadyGet:setVisible(false)
            self.m_pGetTagetBtn:addClickEventListener(GetRewardCallBack)
			self:MarkIntaractCObj(self.m_pGetTagetBtn)
        end
    else
        self.m_pGetTagetBtn:setBright(false)
    end
end

--[[
阶段单元显示
]]
function ShenqiGiftUI:ShowTargetCell(cell, target)
    -- 领取奖励
    function GetRewardCallBack(sender)
        LuaNetSendMsg:QueryStageGoalInfo_L(2, sender.unit, sender.chapter)
    end
    cell:getChildByName("Target"):setString(target.TargetName)
    local btn = cell:getChildByName("btn_Get")
    btn.unit = target.unitid
    btn.chapter = target.senderServerID
    local stateAlget = cell:getChildByName("yilingqu")
    local stateNoFinish = cell:getChildByName("State")
    local btnName
    if target.isWancheng then
        if target.isLingqu then
            btn:setVisible(false)
            stateAlget:setVisible(true)
            stateNoFinish:setVisible(false)
        else
            btn:setVisible(true)
            stateAlget:setVisible(false)
            stateNoFinish:setVisible(false)
            btn:addClickEventListener(GetRewardCallBack)
			self:MarkIntaractCObj(btn)
        end
    else
        btn:setVisible(false)
        stateAlget:setVisible(false)
        stateNoFinish:setVisible(true)
    end
    local grid = cell:getChildByName("Reword")
    grid:removeAllChildren()
    grid:setTouchEnabled(true)
    local id
    local num
    if target.jiangli == 0 then
        id = AppDef.AwrdItem.AWRD_ITEM_COIN
        num = target.jinbi
    elseif target.jiangli == 1 then
        id = AppDef.AwrdItem.AWRD_ITEM_BDYB
        num = target.bangyuan
    elseif target.jiangli == 2 then
        id = target.itemID
        num = target.itemNum
    end
    Utils:GetItemCellValue(grid, 0, id, true, true, num)
end

return ShenqiGiftUI