local BangPaiFuBenInfoCtrl = {}
BangPaiFuBenInfoCtrl.__index = BangPaiFuBenInfoCtrl

-- -----------------------------------
function BangPaiFuBenInfoCtrl:New(ctrl, node)
    local o = {}
    setmetatable(o, BangPaiFuBenInfoCtrl)
    o:Init(ctrl, node)
    return o
end

-- -----------------------------------
function BangPaiFuBenInfoCtrl:Init(ctrl, node)
    self.Script = "BangPai.BangPaiFuBenInfoCtrl"
    self._data = nil
    self._ctrl = ctrl
    self.m_pUILayer = node
    self:InitUIControl()
    self:setCloseCallback()
end

function BangPaiFuBenInfoCtrl:setVisible(visible)
    self.m_pUILayer:setVisible(visible)
end

function BangPaiFuBenInfoCtrl:isVisible()
    return self.m_pUILayer:isVisible()
end

-- -----------------------------------
function BangPaiFuBenInfoCtrl:onExit()
    self.m_pUILayer = nil
end

function BangPaiFuBenInfoCtrl:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

function BangPaiFuBenInfoCtrl:SetData(copyData)
    self._data = copyData;
    self:ShowInfo();
end


-- -----------------------------------
function BangPaiFuBenInfoCtrl:InitUIControl()
    for i = 1, 4 do
        local btn = self.m_pUILayer:findChildByName("Panel_" .. i .. "/Btn");
        btn.userData = i;
        btn:addClickEventListener(function(sender)
            self:OnFubenClicked(sender)
        end)
        self.m_pUILayer:findChildByName("Panel_" .. i .. "/Btn/Finish"):setTouchEnabled(false);

        btn = self.m_pUILayer:findChildByName("Panel_" .. i .. "/Btn/Reward");
        btn.userData = i;
        btn:addClickEventListener(function(sender)
            self:OnRewardClicked(sender)
        end)
    end
end

function BangPaiFuBenInfoCtrl:EnterFight(copyData)

    local data = {}
    data.configData = JsonConfig.m_stageNodeConfig.getDefByID(copyData.id);
    data.fightNum = LRoleDataMgr.Faction.canFightNum;
    data.maxNum = LRoleDataMgr.Faction.factionChapterFightTotal;
    data.getStarNum = 0
    data.stageId = copyData.id
    data.copyData = copyData
    Utils:InitUI("FuBenMap.StageInfoUI", AppDef.UIType.SpecialLayer, data)

    -- local value = {}
    -- value.enemyZhenfaId = copyData.zhenfaId
    -- value.enemyInfos = {}
    -- local max = AppDef.Formation.MaxFightNum
    -- for i = 1, copyData.monsterNum do
    --     local data = copyData.fightInfo[i]
    --     value.enemyInfos[i] = data.id
    -- end

    -- local fun = function()
        
    --     LuaNetSendMsg:QueryBangPaiFubenFight(self._data.id, copyData.id)
    --     --LuaNetSendMsg:QuertKunLunById(id)
    -- end
    -- value.callback = fun
    -- LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Common.PetFormationUI",AppDef.UIType.FirstClassLayer,value)
    -- self._ctrl:SendMsg(LGameMsg.m_initUIMsg)
end

function BangPaiFuBenInfoCtrl:OnFubenClicked(sender)
    local ind = sender.userData;
    -- LuaNetSendMsg:QueryBangPaiFubenInfo(self._data.id, self._data.copyArr[ind].id)
    self:EnterFight(self._data.copyArr[ind]);
end

function BangPaiFuBenInfoCtrl:OnRewardClicked(sender)
    local ind = sender.userData;
    LuaNetSendMsg:QueryBangPaiFubenReward(self._data.id, self._data.copyArr[ind].id)
end

function BangPaiFuBenInfoCtrl:ShowInfo()
    --chapId   complete   copyNum  [ copyId  complete   monsterNum ( zhenfaPos  leftHp   maxHp  ) ]  firstRankName
    local copyDatas = JsonConfig.m_stageNodeByMapidDict[self._data.id]
    local copyNum = self._data.copyNum
    if copyNum > 4 then
        copyNum = 4
    end
    for i = 1, self._data.copyNum do
        if self._data.copyArr[i] ~= nil then
            self:ShowCopyInfo(self.m_pUILayer:findChildByName("Panel_" .. i),self._data.copyArr[i],copyDatas[self._data.copyArr[i].id])
        end
    end
end

function BangPaiFuBenInfoCtrl:UpdateCopy(copyData)
    local copyDatas = JsonConfig.m_stageNodeByMapidDict[self._data.id]
    for i = 1, self._data.copyNum do
        if self._data.copyArr[i].id == copyData.id then
            self:ShowCopyInfo(self.m_pUILayer:findChildByName("Panel_" .. i),self._data.copyArr[i],copyDatas[self._data.copyArr[i].id])
            break
        end
    end
end

function BangPaiFuBenInfoCtrl:ShowCopyInfo(node, data, baseData)
    local nameLabel = node:findChildByName("Btn/UI_Panel/Name");
    nameLabel:setString(baseData.Name);
    

    if data:IsComplete() then
        node:findChildByName("Btn/UI_Panel/Loading"):setVisible(false);
        node:findChildByName("Btn/Finish"):setVisible(true)
    else
        node:findChildByName("Btn/UI_Panel/Loading"):setVisible(true);
        local progressBar = node:findChildByName("Btn/UI_Panel/Loading/LoadingBar_1");
        progressBar:setPercent(data:GetHpProgress())
        node:findChildByName("Btn/Finish"):setVisible(false)
    end
    if string.len(data.firstRankName) > 0 then
        node:findChildByName("Btn/MVP"):setVisible(true);
        nameLabel = node:findChildByName("Btn/MVP/Text/Name");
        nameLabel:setString(data.firstRankName);
    else
        node:findChildByName("Btn/MVP"):setVisible(false);
    end
    

    local rewardNode = node:findChildByName("Btn/Reward");
    rewardNode:setVisible(data:CanGetReward());


    --[[
    local value = {}
    value.enemyZhenfaId = 0
    value.enemyInfos = {}
    local max = AppDef.Formation.MaxFightNum
    for i = 1,max do
        value.enemyInfos[i] = {}
    end

    local fun = function()
        LuaNetSendMsg:QuertKunLunById(id)
    end
    value.callback = fun
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Common.PetFormationUI",AppDef.UIType.FirstClassLayer,value)
    self:SendMsg(LGameMsg.m_initUIMsg)
    ]]
    
end

return BangPaiFuBenInfoCtrl