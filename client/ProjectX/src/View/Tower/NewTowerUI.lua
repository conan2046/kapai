local NewTowerDelegate = require("View.Tower.NewTowerDelegate")
local TowerRecommendUI = require("View.Tower.TowerRecommendUI")
--  ----------------------------------------------
-- 福利UI逻辑
local NewTowerUI = LUIBase:New()
NewTowerUI.__index = NewTowerUI

local Button = {
    ["Reset"] = 1,
    ["SaoDang"] = 2,
    ["FightMonster"] = 3,
    ["FightKing"] = 4,
}

--战斗中是否隐藏
NewTowerUI.IsHideInBattle = true
----------------------------------------------
function NewTowerUI:New()
    local o = {}
    setmetatable(o, NewTowerUI)
    o:Init()
    return o
end
----------------------------------------------
function NewTowerUI:Init()
    self.Script = "Tower.NewTowerUI"
    self.m_isShowKing = false
    self.m_isInit = true
    self.m_selectKing = 1
    ----------------------------------------------
    self.m_pTitleText = nil 
    self.m_pDescText = nil
    self.m_pTitleText2 = nil
    self.m_pDescText2 = nil
    self.m_pRewardList = nil
    self.m_pItemModel = nil
    self.m_pResetTimesText = nil
    self.m_pResetTimes = nil
    self.m_pResetButtonText = nil
    self.m_pTargetRewardPanel = nil
    self.m_pTowerDelegate = nil
    self.towerKingInfo = nil
    self.m_pResetButton = nil
    self.m_pFightButton = nil

    self.m_pDefaultLayer = {}
    ----------------------------------------------
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:RegisterQuik()
    ----------------------------------------------
    LuaNetSendMsg:QueryTowerInfo(6)
    LuaNetSendMsg:QueryTowerInfo(2)
end
----------------------------------------------
function NewTowerUI:RegistMsgs()
    self.msgIds = 
    {
        LUITowerEvent.TowerInfo,
        LUITowerEvent.TowerSaoDang,
        LUITowerEvent.TowerKingData,
        LUITowerEvent.TowerReset,
        LUITowerEvent.TowerShowReward,
        LUITowerEvent.TowerStartChange,
        LUIRoleTeamEvent.TeamMemberChanged,
    }
    self:RegistSelf(self,self.msgIds)
end

----------------------------------------------
function NewTowerUI:ProcessEvent(msg)
    if msg.msgId == LUITowerEvent.TowerInfo then
        self:OnTowerInfo(msg.value)
    elseif msg.msgId == LUITowerEvent.TowerSaoDang then
        self:OnTowerSaoDang(msg.value)
    elseif msg.msgId == LUITowerEvent.TowerKingData then
        self:OnTowerKingDatag(msg.value)
    elseif msg.msgId == LUITowerEvent.TowerReset then
        self:OnTowerReset(msg.value)
    elseif msg.msgId == LUITowerEvent.TowerShowReward then
        self:OnTowerShowReward(msg.value)
    elseif msg.msgId == LUITowerEvent.TowerStartChange then
        self:StateChangeCallback(msg.value)
        self:OnTowerStartChange()
    elseif msg.msgId == LUIRoleTeamEvent.TeamMemberChanged then
        self:enterCallback()
    end
end

----------------------------------------------
function NewTowerUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_pTitleText = nil
    self.m_pDescText = nil
    self.m_pTitleText2 = nil
    self.m_pDescText2 = nil
    self.m_pRewardList = nil
    self.m_pItemModel = nil
    self.m_pResetTimesText = nil
    self.m_pResetTimes = nil
    self.m_pResetButtonText = nil
    self.m_pTargetRewardPanel = nil
    self.m_pTowerDelegate = nil
    self.towerKingInfo = nil
    self.m_pResetButton = nil
    self.m_pFightButton = nil
    Utils:FreeTable(self.m_pDefaultLayer)
    self.m_pDefaultLayer = nil
    self.m_timeline = nil
    self.m_pTowerDelegate = nil
    self.m_pTowerRecommendUI = nil
    Utils:FreeTable(self.m_data)
    self.m_data = nil
end

function NewTowerUI:RegisterQuik()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
----------------------------------------------
function NewTowerUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/TowerLayer2.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    self.m_timeline = cc.CSLoader:createTimeline("csd/TowerLayer2.csb")
    self.m_timeline:pause()

    local timeline = ccs.Timeline:create()
    local frame = ccs.EventFrame:create()
    frame:setEvent("ChangeState")
    frame:setFrameIndex(30)
    timeline:addFrame(frame)
    self.m_timeline:addTimeline(timeline)
    
    self.m_timeline:clearFrameEventCallFunc()
    self.m_timeline:setFrameEventCallFunc(handler(self, NewTowerUI.FrameEventCallFunc))
    self.m_pUILayer:runAction(self.m_timeline)
end
----------------------------------------------
function NewTowerUI:InitUIControl()
    local panel = self.m_pUILayer:getChildByName("Panel_0")
    local pReward = panel:getChildByName("Reward")
    pReward:setVisible(false)
    table.insert(self.m_pDefaultLayer, pReward)
    local pRewardBg = pReward:getChildByName("RewardBg")
    --------------------------------------------
    self.m_pTitleText = pRewardBg:getChildByName("Title_1"):getChildByName("Text")
    self.m_pDescText = pRewardBg:getChildByName("Des_1")
    
    self.m_pTitleText2 = pRewardBg:getChildByName("Title_2"):getChildByName("Text")
    self.m_pDescText2 = pRewardBg:getChildByName("Des_2")
    --------------------------------------------
    self.m_pRewardList = pRewardBg:getChildByName("RewardList")
    self.m_pItemModel = pRewardBg:getChildByName("Item")
    --------------------------------------------
    self.m_pResetTimes = pRewardBg:getChildByName("RefreshTime")
    self.m_pResetTimesText = self.m_pResetTimes:getChildByName("Text")
    --------------------------------------------
    local pResetButton = pRewardBg:getChildByName("Button_1")
    self.m_pResetButton = pResetButton
    pResetButton:setTag(0)
    pResetButton:addClickEventListener(handler(self, NewTowerUI.ResetButtonClick))
	self:MarkIntaractCObj(pResetButton)
    self.m_pResetButtonText = pResetButton:getChildByName("Text")

    local pFightButton = pRewardBg:getChildByName("Button_2")
    pFightButton:setTag(Button.FightMonster)
    pFightButton:addClickEventListener(handler(self, NewTowerUI.FightButtonClick))
	self:MarkIntaractCObj(pFightButton)
    self.m_pFightButton = pFightButton
    --------------------------------------------
    local pFunction = panel:getChildByName("Function")
    pFunction:setVisible(false)
    table.insert(self.m_pDefaultLayer, pFunction)
    self.m_pCurrentLevel = Utils:FindNodeByName(pFunction, "LevelBg/LayerNum/Num")
    self.m_pTargetRewardPanel = pFunction:getChildByName("Reward")
    self.m_pTargetRewardPanel:setTag(0)
    self.m_pTargetRewardPanel:addClickEventListener(handler(self, NewTowerUI.ShowPetInfoClick))
	self:MarkIntaractCObj(self.m_pTargetRewardPanel)
    --------------------------------------------
    local pRankButton = pFunction:getChildByName("PaiHangBtn")
    pRankButton:addClickEventListener(handler(self, NewTowerUI.RankButtonClick))
	self:MarkIntaractCObj(pRankButton)
    --------------------------------------------
    local pPetBtn = pFunction:getChildByName("PetBtn")
    pPetBtn:addClickEventListener(handler(self, NewTowerUI.PetButtonClick))
    self:MarkIntaractCObj(pPetBtn)
    --------------------------------------------
    local pDuanzaoBtn = pFunction:getChildByName("DuanzaoBtn")
    pDuanzaoBtn:addClickEventListener(handler(self, NewTowerUI.DuanZaoButtonClick))
    self:MarkIntaractCObj(pDuanzaoBtn)
    --------------------------------------------
    local pCloseButton = panel:getChildByName("CloseBtn")
    pCloseButton:addClickEventListener(handler(self, NewTowerUI.RemoveUI))
	self:MarkIntaractCObj(pCloseButton)
    --------------------------------------------
    local pTower = panel:getChildByName("Tower")
    pTower:setVisible(false)
    table.insert(self.m_pDefaultLayer, pTower)
    self.m_pTowerDelegate = NewTowerDelegate:New()
    -- self.m_pTowerDelegate:SetStateChangeCallback(handler(self, NewTowerUI.StateChangeCallback))
    pTower:addChild(self.m_pTowerDelegate.m_pUILayer)
    --------------------------------------------
    self.m_pTowerRecommendUI = TowerRecommendUI:New()
    panel:addChild(self.m_pTowerRecommendUI.m_pUILayer)
    --------------------------------------------
end
----------------------------------------------
function NewTowerUI:createModel(pModel, parent, pData, isPet, num, item, noTouch, noEffect)
    local pItem = pModel:clone()
    if isPet then
        Utils:ShowPet(pData, parent, pItem, noTouch)
        --宠物特效
        if (noEffect == nil or noEffect == false) then
            local data = LPetDataMgr:FindPetDataById(pData)
            if data and data.quality >= 3 then
                local posX = pItem:getContentSize().width / 2
                local posY = pItem:getContentSize().height / 2
                Utils:createAnimEffect(pItem, cc.p(posX, posY), "res2/fx/gaojiwupin")
            end
        end
    else
        local item = Utils:GetItemCellValue(pItem, 0, pData, true, num ~= nil, num, nil, (noTouch == nil or noTouch == false))
        --物品特效
        if (noEffect == nil or noEffect == false) then
            local quality = Utils:getQualityByItem(item)
            if quality >= 5 then
                local posX = pItem:getContentSize().width / 2
                local posY = pItem:getContentSize().height / 2
                Utils:createAnimEffect(pItem, cc.p(posX, posY), "res2/fx/gaojiwupin")
            end
        end
    end
    pItem:setVisible(true)
    return pItem
end
----------------------------------------------
function NewTowerUI:CreateBgEffect(parent)
    local pAnimBgEffect = parent:getChildByName("AnimBgEffect")
    if pAnimBgEffect == nil then
        pAnimBgEffect = Utils:createAnimEffect(parent, cc.p(parent:getContentSize().width/2, parent:getContentSize().height/2+18), "res2/fx/shenqizhanshi")
        pAnimBgEffect:setIgnoreAnchorPointForPosition(false)
        pAnimBgEffect:setAnchorPoint(cc.p(0.5, 0))
        pAnimBgEffect:PlayActionRepeat(0)
        pAnimBgEffect:setLocalZOrder(0)
        pAnimBgEffect:setName("AnimBgEffect")
    end
    return pAnimBgEffect
end
----------------------------------------------
function NewTowerUI:DrawTargetReward()
    -- dump(self.m_data, "self.m_data-->")
    if self.m_pTargetRewardPanel then
        local pNextRewardData,ind = LDataConstMgr:GetNextTowerTargetRewardData(self.m_data.MaxClass)
        if pNextRewardData then
            local pid = pNextRewardData.targetReward[2]
            self.m_pTargetRewardPanel:setTag(pid)
            self.m_pTargetRewardPanel:setVisible(true)
            local pTitle = self.m_pTargetRewardPanel:getChildByName("Title")
            if ind then
                pTitle:getChildByName("Text"):setString(string.format(GUITips.RSI_TOWER_TIP2, ind))
                pTitle:setVisible(true)
            else
                pTitle:setVisible(false)
            end

            local pDizuo = self.m_pTargetRewardPanel:getChildByName("dizuo")
            self:CreateBgEffect(pDizuo)

            local pNode = self.m_pTargetRewardPanel:getChildByName("Node")
            pNode:removeChildByName("AnimNode")
            local pAnimNode = Utils:CreateAnimModel(AppDef.AwrdItem.AWRD_ITEM_PET, pid)
            if pAnimNode then
                pNode:addChild(pAnimNode)
                pAnimNode:setName("AnimNode")
            end

            self.m_pTargetRewardPanel:getChildByName("Name"):setString(pNextRewardData.targetRewardName)
            -- dump(pNextRewardData.targetReward, "pNextRewardData.targetReward-->")
        else
            self.m_pTargetRewardPanel:setVisible(false)
        end
    end
end
----------------------------------------------
function NewTowerUI:ResetButtonClick(sender)
    if sender == nil then
        return
    end

    local tag = sender:getTag()
    if tag == Button.Reset then
        LuaNetSendMsg:QueryTowerInfo(10)
    elseif tag == Button.SaoDang then
        LuaNetSendMsg:QueryTowerInfo(4)
    end
end
----------------------------------------------
function NewTowerUI:FightButtonClick(sender)
    if sender == nil then
        return
    end

    if self:outTeamAndfight() then
        return
    end
    self:enterCallback()
end
----------------------------------------------
function NewTowerUI:enterCallback( ... )
    local tag = self.m_pFightButton:getTag()
    if tag == Button.FightMonster then
        LuaNetSendMsg:QueryTowerInfo(3)
    elseif tag == Button.FightKing then
        LuaNetSendMsg:QueryTowerInfo(5, self.m_selectKing and (self.m_selectKing-1) or 0)
    end
end
----------------------------------------------
function NewTowerUI:outTeamAndfight( ... )
    -- body
    if LRoleDataMgr.MyHeroInfo:IsTeam() then
        local function okFunc()
            LuaNetSendMsg:QueryLeaveTeam()
        end
        local function canelFunc()
            
        end
        Utils:ShowDialogOKCancel(GUITips.RSI_TARGET_RD_TIPS12, okFunc,canelFunc)
        return true
    end
    return false
end
----------------------------------------------
function NewTowerUI:RankButtonClick(sender)
    if sender == nil then
        return
    end
    Utils:OpenFunction(AppDef.EModuleID.EMID_PAIHANGBANG)
    Utils:SendMsg(LUIRankEvent.ShowIndexRank, 8)
end
----------------------------------------------
function NewTowerUI:PetButtonClick(sender)
    Utils:OpenFunction(AppDef.EModuleID.EMID_SHENJIANG)
end
----------------------------------------------
function NewTowerUI:DuanZaoButtonClick(sender)
    Utils:OpenFunction(AppDef.EModuleID.EMID_DUANZAO)
end
----------------------------------------------
function NewTowerUI:ShowInfo()
    self:DrawTargetReward()
    self:UpdateCurrentLayer()
    self:ShowDesc()
    self:ShowRewardDesc()
    self:ShowReward()
    self:ShowTowerTimes()
    self:UpdateResetButton()
end
----------------------------------------------
function NewTowerUI:OnTowerInfo(data)
    -- dump(data, "OnTowerInfo--->")
    Utils:FreeTable(self.m_data)
    self.m_data = nil
    self.m_data = data
    self:ShowInfo()
    if self.m_isInit then
        for i=1,#self.m_pDefaultLayer do
            self.m_pDefaultLayer[i]:setVisible(true)
        end
    end
    self.m_isInit = false
end
----------------------------------------------
function NewTowerUI:ShowPetInfoClick(sender)
    if sender == nil then
        return
    end
    local id = sender:getTag()
    Utils:SendMsg(LUILogicEvent.ShowPetInfo, {id})
end
----------------------------------------------
function NewTowerUI:UpdateCurrentLayer()
    if self.m_data == nil or self.m_pCurrentLevel == nil then
        return
    end
    self.m_pCurrentLevel:setString(self.m_data.currClass)
end
----------------------------------------------
function NewTowerUI:ShowDesc()
    if self.m_isShowKing then
        self.m_pDescText:setString("首次通关20层，60层，100层，150层，200层的玩家即可成为本层的霸主。")
    else
        self.m_pDescText:setString("首次通关20层，60层，100层，150层，200层的玩家会自动成为霸主。其他玩家可以挑战。")
    end
end
----------------------------------------------
function NewTowerUI:ShowRewardDesc()
    if self.m_isShowKing then
        if self.towerKingInfo then
            local class = self.towerKingInfo.classinfo[self.m_selectKing].class
            local _ = class and self.m_pDescText2:setString(class.."层霸主奖励(每天24点发放)")
        end
    else
        self.m_pDescText2:setString("通关可获得神魂之魄和坐骑精魄\n首次通关还会获得绝版神将")
    end
end
----------------------------------------------
function NewTowerUI:ShowReward()
    if self.m_isShowKing then
        self:ShowBaZhuReward()
    else
        self:ShowTowerReward()
    end
end
----------------------------------------------
function NewTowerUI:CreateRewards(rewards)
    if rewards == nil then
        return
    end
    self.m_pRewardList:removeAllItems()
    if #rewards == 0 then
        return
    end

    local rewardCount = #rewards
    local width = rewardCount*self.m_pItemModel:getContentSize().width + (rewardCount-1)*self.m_pRewardList:getItemsMargin()
    self.m_pRewardList:setContentSize(cc.size(width, self.m_pRewardList:getContentSize().height))
    if width < 370 then
        self.m_pRewardList:setTouchEnabled(false)
        self.m_pRewardList:setInnerContainerSize(self.m_pRewardList:getContentSize())
    end
    for i=1,#rewards do
        local itemId = rewards[i].itemId
        local num = rewards[i].itemNum
        local grid = self.m_pItemModel:clone()
        Utils:GetItemCellValue(grid, 0, itemId, true, num > 0, num, nil, true, true)
        self.m_pRewardList:pushBackCustomItem(grid)
    end
end
----------------------------------------------
function NewTowerUI:ShowTowerReward()
    if self.m_isShowKing then
        return
    end
    local data = LDataConstMgr:GetTowerData(self.m_data.currClass + 1)
    if data ~= nil then
        local rewards = {}
        if self.m_data.firstClimbBattle == 1 then
            for i = 1,#data.rewards do
                local reward = {}
                reward.itemId = data.rewards[i].itemId
                reward.itemNum = data.rewards[i].itemNum
                table.insert(rewards,reward)
            end
        else
            for i = 1,#data.sweepRewards do
                local reward = {}
                reward.itemId = data.sweepRewards[i].itemId
                reward.itemNum = data.sweepRewards[i].itemNum
                table.insert(rewards,reward)
            end
        end
        self:CreateRewards(rewards)
    end
end
----------------------------------------------
function NewTowerUI:ShowBaZhuReward()
    if not self.m_isShowKing then
        return
    end
    local rewards = {}
    local reward = {}
    reward.itemId = AppDef.AwrdItem.AWRD_ITEM_SHENPO
    reward.itemNum = 0
    table.insert(rewards,reward)
    self:CreateRewards(rewards)
end
----------------------------------------------
function NewTowerUI:ShowTowerTimes()
    local str = string.format("%d/%d", self.m_data.currTimes, self.m_data.MaxTimes)
    self.m_pResetTimesText:setString(str)
end
----------------------------------------------
function NewTowerUI:OnTowerReset(rsp)
    -- dump(rsp, "rsp-->")
    if rsp.errmsg then
        Utils:ShowScrollTips(rsp.errmsg)
        return 
    end
    self.m_data.currTimes = self.m_data.currTimes + 1
    self:UpdateResetButton()
    LuaNetSendMsg:QueryTowerInfo(6)
end
----------------------------------------------
function NewTowerUI:OnTowerSaoDang(rsp)
    if rsp.errmsg then 
        Utils:ShowScrollTips(rsp.errmsg)
        return
    end
    LuaNetSendMsg:QueryTowerInfo(6)
    self:UpdateResetButton()
end
----------------------------------------------
function NewTowerUI:OnTowerKingDatag(rsp)
    -- dump(rsp.classinfo, "OnTowerKingDatag-->")
    self.towerKingInfo = rsp
end
----------------------------------------------
function NewTowerUI:UpdateResetButton()
    --TODO:策划需求
    if self.m_data.currTimes >= self.m_data.MaxTimes and (self.m_data.currClass+1) < self.m_data.MaxClass then
        self.m_pResetButtonText:setString("扫荡")
        self.m_pResetButton:setTag(Button.SaoDang)
        self.m_pResetButton:setBright(true)
    else
        self.m_pResetButtonText:setString("重置")
        self.m_pResetButton:setTag(Button.Reset)
        self.m_pResetButton:setBright(self.m_data.currTimes < self.m_data.MaxTimes)
    end
end 
----------------------------------------------
function NewTowerUI:StateChangeCallback(isKing)
    if self.m_isShowKing ~= isKing then
        self.m_isShowKing = isKing
        -- self:ShowDesc()
        -- self:ShowRewardDesc()
        -- self:ShowReward()
        
        -- if isKing then
        --     self.m_pFightButton:setTag(Button.FightKing)
        --     self.m_pResetButton:setVisible(false)
        --     self.m_pResetTimes:setVisible(false)
        --     self.m_pFightButton:setPositionX(205)
        -- else
        --     self.m_pFightButton:setTag(Button.FightMonster)
        --     self.m_pResetButton:setVisible(true)
        --     self.m_pResetTimes:setVisible(true)
        --     self.m_pFightButton:setPositionX(295)
        -- end
    end
end
----------------------------------------------
function NewTowerUI:OnTowerShowReward(ind)
    self.m_selectKing = ind
    self:ShowRewardDesc()
end
----------------------------------------------
function NewTowerUI:OnTowerStartChange()
    if self.m_timeline == nil then
        return
    end
    self.m_timeline:gotoFrameAndPlay(0, false)
end
----------------------------------------------
function NewTowerUI:FrameEventCallFunc(frame)
    self:ShowDesc()
    self:ShowRewardDesc()
    self:ShowReward()

    if self.m_isShowKing then
        self.m_pFightButton:setTag(Button.FightKing)
        self.m_pResetButton:setVisible(false)
        self.m_pResetTimes:setVisible(false)
        self.m_pFightButton:setPositionX(205)
    else
        self.m_pFightButton:setTag(Button.FightMonster)
        self.m_pResetButton:setVisible(true)
        self.m_pResetTimes:setVisible(true)
        self.m_pFightButton:setPositionX(295)
    end
end
----------------------------------------------
return NewTowerUI



