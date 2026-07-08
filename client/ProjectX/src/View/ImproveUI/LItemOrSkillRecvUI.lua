LItemOrSkillRecvUI = LUIBase:New()
LItemOrSkillRecvUI.__index = LItemOrSkillRecvUI

function LItemOrSkillRecvUI:New()
    local o = {}
    setmetatable(o, LItemOrSkillRecvUI)
    o:Init()
    return o
end

----------------------------------------------------------------------
function LItemOrSkillRecvUI:Init()
    --------------------------------------------
    self._Item = nil
    self._ItemId = nil
    self._ItemVal = nil
    self._ItemType = nil
    self._ItemNum = nil
    --------------------------------------------
    self.m_countDownSchedule = nil
    self.m_countDown = 0
    --------------------------------------------
    self.m_pPanel = nil
    self.m_pIcon = nil
    self.m_pName = nil
    self.m_pItem = nil
    self.m_pButton = nil
    self.m_pButtonText = nil
    --------------------------------------------
	self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
end
----------------------------------------------------------------------
function LItemOrSkillRecvUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self._Item = nil
    self._ItemId = nil
    self._ItemVal = nil
    self._ItemType = nil
    self._ItemNum = nil
    --------------------------------------------
    self.m_countDownSchedule = nil
    self.m_countDown = nil
    --------------------------------------------
    self.m_pPanel = nil
    self.m_pIcon = nil
    self.m_pName = nil
    self.m_pItem = nil
    self.m_pButton = nil
    self.m_pButtonText = nil
end
----------------------------------------------------------------------
function LItemOrSkillRecvUI:RegistMsgs()
	self.msgIds = {
        --LUIMainEvent.StartAutoUseItemCheck,
    }
    self:RegistSelf(self, self.msgIds)
end
----------------------------------------------------------------------
function LItemOrSkillRecvUI:ProcessEvent(msg)

	if msg.msgId == LUIMainEvent.StartAutoUseItemCheck then
        self:StartAutoUseItemCheck()
    end
end
----------------------------------------------------------------------
function LItemOrSkillRecvUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
----------------------------------------------------------------------
function LItemOrSkillRecvUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/WearPopupLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end
----------------------------------------------------------------------
function LItemOrSkillRecvUI:InitUIControl()
    self.m_pPanel = self.m_pUILayer:getChildByName("Panel")
    self.m_pPanel:setVisible(false)

    local pWearBg = self.m_pPanel:getChildByName("WearBg")
    local pIconBg = pWearBg:getChildByName("IconBg")
    local pIcon = pIconBg:getChildByName("Icon")
    pIcon:setVisible(false)
    self.m_pIcon = pIconBg
    self.m_pName = pIconBg:getChildByName("Text_1")
    self.m_pButton = pWearBg:getChildByName("Button")
    self.m_pButtonText = self.m_pButton:getChildByName("Text")
    self.m_pButton:addClickEventListener(handler(self, LItemOrSkillRecvUI.ButtonClick))
	self:MarkIntaractCObj(self.m_pButton)
end

function LItemOrSkillRecvUI:StartAutoUseItemCheck()
    performWithDelay(self.m_pUILayer, handler(self, LItemOrSkillRecvUI.OnAutoUseItemUpdate), 0.5)
end

function LItemOrSkillRecvUI:OnAutoUseItemUpdate(sender)
    if(self:isShowing()) then
        return
    end
    local hd = LRoleDataMgr.MyHeroInfo

    local vecUseId = {}
    table.insert(vecUseId, 2342)
    table.insert(vecUseId, 2341)

    --循环变量所有背包，判断是否需要使用
    local PackageMap = LRoleDataMgr.Equip.PackageMap
    for k,v in pairs(PackageMap) do
        local it = v
        if it and it.m_id > 0 then
            for j=1,#vecUseId do
                if self:isShowing() then
                    return
                end
                --有物品可以使用
                if (it.m_id == vecUseId[j]) then
                    self:AddUseItemInfo(it.m_id, it.m_num)
                    return
                end
            end
            --检测推送装备
            --LRoleDataMgr.Equip:CheckEquipPush(it, hd.professional, hd.level)
        end
    end

    self:hideUI()
    --如有可穿戴装备则推送
    self:DealMsgPushEquip()
end

function LItemOrSkillRecvUI:hideUI()
    self.m_pPanel:setVisible(false)
    if self.m_countDownSchedule and self.m_pButtonText ~= nil then
        self.m_pButtonText:stopAction(self.m_countDownSchedule)
        self.m_countDownSchedule = nil
    end
end

function LItemOrSkillRecvUI:isShowing()
    return self.m_pPanel:isVisible()
end

function LItemOrSkillRecvUI:AddUseItemInfo(itemId, itemNum)
    local pItem = LItemMgr:getItem(itemId)
    if pItem == nil then
        return
    end
    ---------------------------------------------------------
    self._ItemType = 3
    self._ItemId = itemId
    self._ItemVal = LRoleDataMgr.Equip:FindPackageItemById1(itemId)
    self._ItemNum = itemNum
    self._Item = LRoleDataMgr.Equip.PackageMap[self._ItemVal]
    ---------------------------------------------------------
    self:createArrow()
    self:updateItem()
    self.m_pName:setString(pItem.m_name)
    self.m_pButtonText:setText(GUITips.RSI_UIBUTTONLB_WUPINSHIYONG1)
    ---------------------------------------------------------
    self.m_pPanel:setVisible(true)
end

function LItemOrSkillRecvUI:MSG_DEAL_REWARD(pItem)
    if pItem == nil then
        return
    end
    ---------------------------------------------------------
    self._Item = pItem
    self._ItemId = pItem.m_id
    self._ItemVal = pItem.m_pos
    self._ItemType = 0
    ---------------------------------------------------------
    self:createArrow()
    self:updateItem()
    self.m_pName:setString(pItem.m_item.name)
    ---------------------------------------------------------
    self.m_countDown = 1
    local function buttonSchedule(sender)
        if self.m_countDown < 0 then
            self:ButtonClick(nil)
            self:hideUI()
            return
        end
        self.m_pButtonText:setString(string.format(GUITips.RSI_UIBUTTONLB_WUPINSHIYONG2, self.m_countDown))
        self.m_countDown = self.m_countDown - 1
    end
    if self.m_countDownSchedule == nil then
        self.m_countDownSchedule = schedule(self.m_pButtonText, handler(self, buttonSchedule), 1)
    end
    buttonSchedule()
    ---------------------------------------------------------
    self.m_pPanel:setVisible(true)

    local isGetFight = (not Utils:ToBool(LRoleDataMgr:GetSettingConfig(AppDef.ServerSetIndex.SSI_FIRST_GET_ZB)))
    if isGetFight then
        LuaNetSendMsg:DealMsgSaveSettingInfo(AppDef.ServerSetIndex.SSI_FIRST_GET_ZB, 1)
        Utils:PlayEffect("GuideBGM", "id", 5, nil, true)
    end
end

function LItemOrSkillRecvUI:updateItem()
    self.m_pItem = Utils:GetItemCellValue(self.m_pIcon, 0, self._ItemId, false, false, 0, self.m_pItem, true)
end

function LItemOrSkillRecvUI:createArrow()
end

function LItemOrSkillRecvUI:DealMsgPushEquip()
    -- dump('DealMsgPushEquip')
    local heroData = LRoleDataMgr.MyHeroInfo
    local equipList = LRoleDataMgr.Equip.GotEquip

    local function ShowPushItemLayer(itemlist, index)
        --当前部位没有装备或获得装备优于已有装备时进行推送
        if (heroData.EquipList[index].m_id == 0 or LItemMgr:CalcFTP(itemlist[index]) > LItemMgr:CalcFTP(heroData.EquipList[index])) then
            self:MSG_DEAL_REWARD(itemlist[index])
        end
    end
    local EEYaoDai      =   AppDef.EEquipmentType.EEYaoDai
    local EEMaoZi       =   AppDef.EEquipmentType.EEMaoZi 
    local EEXieZi       =   AppDef.EEquipmentType.EEXieZi
    local EEKuiJia      =   AppDef.EEquipmentType.EEKuiJia
    local EEXiangLian   =   AppDef.EEquipmentType.EEXiangLian
    local EEJieZhi      =   AppDef.EEquipmentType.EEYuPei
    local EEShouZhuo    =   AppDef.EEquipmentType.EEShouZhuo1
    local EEWuQi        =   AppDef.EEquipmentType.EEWuQi

    if (equipList[EEYaoDai].m_id ~= 0)then ShowPushItemLayer(equipList, EEYaoDai) end--腰带
    if (equipList[EEMaoZi].m_id ~= 0)then ShowPushItemLayer(equipList, EEMaoZi) end--头盔
    if (equipList[EEXieZi].m_id ~= 0)then ShowPushItemLayer(equipList, EEXieZi) end--鞋子
    if (equipList[EEKuiJia].m_id ~= 0)then ShowPushItemLayer(equipList, EEKuiJia) end--盔甲
    if (equipList[EEXiangLian].m_id ~= 0)then ShowPushItemLayer(equipList, EEXiangLian) end--项链
    if (equipList[EEJieZhi].m_id ~= 0)then ShowPushItemLayer(equipList, EEJieZhi) end--戒指
    if (equipList[EEShouZhuo].m_id ~= 0)then ShowPushItemLayer(equipList, EEShouZhuo) end--护腕
    if (equipList[EEWuQi].m_id ~= 0)then ShowPushItemLayer(equipList, EEWuQi) end--武器

    LRoleDataMgr.Equip:ResetGotEquip()
end

function LItemOrSkillRecvUI:ButtonClick(sender)
    if(self._ItemType == 0) then--装备是穿戴
        for k,v in pairs(LRoleDataMgr.Equip.PackageMap) do
            if v and v:IsEquip() then
                LuaNetSendMsg:QueryPutOnEquip(k - 1)
            end
        end
        self:hideUI()
    elseif(self._ItemType == 1) then--如果是技能，则学习
        if (LRoleDataMgr.MyHeroInfo:Getlevel() < 3) then
            -- Utils:ShowScrollTips(string.format(GUITips.RSI_ITEMINFO_MSG72, ))
            -- TipsMgr::GetInstance()->SetCenterTip(CCSTR_FMT1(RES_STRC(DataConsts::RSI_ITEMINFO_MSG72), m_skill->name.c_str()));
            self:hideUI()
            return
        end

        -- LearnSkillLayer* pLearnLayer = GAMELAYER->ShowLeanSkillLayer();
        -- pLearnLayer->setType(1);
        -- pLearnLayer->setPosition(ccp(300,50));
        
        -- int learnLevel = SKILL_MGR->GetLearnLevelById(m_skill->id);
        -- SkillDetail *pSkill = DATA_MGR->Hero.GetSkillDetailById(m_skill->id);
        -- if(pSkill == NULL)
        --     pSkill = m_skill;
        -- pLearnLayer->LoadSkillData(pSkill->id,learnLevel, pSkill->level+1);
        -- this->removeFromParent();
    elseif(self._ItemType == 3)then     --使用任务道具
        if(self._ItemId==1003)then--钓鱼任务暂时隐藏
            -- this->setVisible(false)
        --     GAMELAYER->RemoveHeroMainLayer();
        --     GAMELAYER->GetGameMap()->StartCommonCollect(2.f,this,RES_STRC(DataConsts::RSI_ITEMINFO_MSG73));
        else
            self:useItem()
            self:hideUI()
        end
    end
end

function LItemOrSkillRecvUI:useItem()
    local function NumInputCallback(num)
        if num == 0 or self._ItemVal == nil then
           self:hideUI()
           return
        end
        LuaNetSendMsg:SendItemUseReq(self._ItemVal-1, num, 0)
    end
    local heroInfo = LRoleDataMgr.MyHeroInfo
    if self._Item.m_locked then
        Utils:ShowScrollTips(GUITips.RSI_ITEM_MSG_LOCKED)
        return
    end
    if self._ItemId == 1816 then    
        --建帮令
        if RoleDataMgr.MyHeroInfo.FactionId > 0 then
            Utils:ShowScrollTips(GUITips.RSI_ITEM_MSG_1)
            return
        end
        --TODO暂无 打开建帮界面
        return
    end
    if self._ItemId == 1834 then
        --宠物解除绑定
        Utils:ShowScrollTips(GUITips.RSI_ITEM_MSG_2)
        self:hideUI()
        return
    end
        
    if self._ItemNum > 1 and LItemMgr:isNeedShowInputNumDialog(self._ItemId) then
        Utils:SendMsg(LUILogicEvent.ShowNumInputUI, {self._ItemNum, NumInputCallback})
    else
        LuaNetSendMsg:SendItemUseReq(self._ItemVal-1, 1, 0)
    end
end

return LItemOrSkillRecvUI
