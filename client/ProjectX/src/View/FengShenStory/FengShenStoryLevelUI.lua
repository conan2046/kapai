local FengShenStoryLevelUI = LUIBase:New()
FengShenStoryLevelUI.__index = FengShenStoryLevelUI
FengShenStoryLevelUI.IsHideInBattle = true
function FengShenStoryLevelUI:New(userData)
    local o = LUIBase:New()
    setmetatable(o,FengShenStoryLevelUI) 
    o:Init(userData)
    return o
end

function FengShenStoryLevelUI:Init(userData)
    self.m_levelId = userData
    self.Script = "Common.FengShenStoryLevelUI"
    self.m_pUILayer = cc.CSLoader:createNode("csd/fengshenliezhuan/fengshenliezhuanlevel.csb")
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitData()
    self:ShowInfo()

    --Utils:SendMsg(LUISecondClassBgEvent.SetTitle, GUITips.UI_Title_XueZhan)
    --Utils:SendMsg(LUISecondClassBgEvent.SetCloseCallback,handler(self,FengShenStoryLevelUI.CloseUI))
end

function FengShenStoryLevelUI:InitData()
    local panel = self.m_pUILayer:getChildByName("Popup")
    self.m_passImg = panel:getChildByName("Pass_bg")
    self.m_passLabel = panel:getChildByName("Pass")
    --挑战按钮
    self.m_fightBtn = panel:getChildByName("Btn_Confirm")
    self.m_fightBtn:addClickEventListener(handler(self, FengShenStoryLevelUI.OnFightClick))
    --布阵按钮
    self.m_btn = panel:getChildByName("Btn_buzhen")
    self.m_btn:addClickEventListener(handler(self, FengShenStoryLevelUI.OnFormationClick))
    --关闭按钮
    local closeBtn = panel:getChildByName("Btn_close")
    closeBtn:addClickEventListener(handler(self, FengShenStoryLevelUI.CloseUI))


    self.m_listView = panel:getChildByName("ListView")
    self.m_rewardGrids = {}
    self.m_rewardItem = {}
    for i=1,3 do
        self.m_rewardGrids[i] = self.m_listView:getChildByName("Icon_"..i)
    end
    self.m_descLabel = panel:getChildByName("Image_1"):getChildByName("description")
    self.m_titleLabel = panel:getChildByName("Title"):getChildByName("Title")
    self.m_tiliLabel = self.m_fightBtn:getChildByName("tili"):getChildByName("num")

    local enemyPanel = panel:getChildByName("Enemy")
    self.m_nameLabel = enemyPanel:getChildByName("Namebg"):getChildByName("Name")
    self.m_node =  enemyPanel:getChildByName("Node")
    self.m_node:setScale(0.8)
end

function FengShenStoryLevelUI:ShowInfo()
    self.m_titleLabel:setString("")
    self.m_descLabel:setString("")
    self.m_tiliLabel:setString("0")
    self.m_passImg:setVisible(false)
    self.m_passLabel:setVisible(false)
    self.m_btn:setVisible(false)
    self.m_fightBtn:setVisible(false)

    local cfg = JsonConfig.m_stageNodeConfig.getDefByID(self.m_levelId)
    if cfg == nil then
        return
    end
    self.m_titleLabel:setString(cfg.Name)
    self.m_descLabel:setString(cfg.Des)
    self.m_tiliLabel:setString(cfg.Hope)
    self:ShowReward(cfg.first_reward)
    local fightCfg = JsonConfig.m_vecFightConfig.getDefByID(cfg.fightID)
    if fightCfg == nil then
        return
    end
    self:ShowEnemyUnit(fightCfg.show)
    local data = LActivityManager:GetFengShenStoryData()
    if data.m_chapterId == nil then
        return
    end
    if data.m_curLevelId == self.m_levelId then
        self.m_btn:setVisible(true)
        self.m_fightBtn:setVisible(true)
    else
        self.m_passImg:setVisible(true)
    self.m_passLabel:setVisible(true)
    end
end

--敌方模型显示
function FengShenStoryLevelUI:ShowEnemyUnit(monsterId)
    local monsterCfg = LDataConstMgr:GetMonsterData(monsterId)--JsonConfig.m_MonsterBoss.getDefByID(monsterId)
    if monsterCfg == nil then
        return
    end
    print("FengShenStoryLevelUI:ShowEnemyUnit",monsterId,monsterCfg.pic)
    if self.m_node == nil then return end
    if self.m_pBossModel == nil then
        self.m_pBossModel = ModelAniNode:create(AppDef.CEnum.ModelAniType.MonsterBig,  monsterCfg.pic)
        self.m_node:addChild(self.m_pBossModel)
    else
        self.m_pBossModel:InitAni(AppDef.CEnum.ModelAniType.MonsterBig, monsterCfg.pic)
    end
    self.m_pBossModel:PlayStand(0)
    self.m_nameLabel:setString(monsterCfg.name)
end

--显示奖励
function FengShenStoryLevelUI:ShowReward(reward)
    for i=1,3 do
        local value = reward[i]
        if  value ~= nil then
            self.m_rewardItem[i] = Utils:GetItemCellValue(self.m_rewardGrids[i], 0, value[1], true, true, value[3], self.m_rewardItem[i], true, true)
        else
            self.m_rewardGrids[i]:setVisible(false)
        end
    end
end

function FengShenStoryLevelUI:OnFightClick(sender)
    LuaNetSendMsg:QueryFengShenStory(25)
    self:CloseUI()
end

function FengShenStoryLevelUI:OnFormationClick(sender)
    local cfg = JsonConfig.m_stageNodeConfig.getDefByID(self.m_levelId)
    if cfg == nil then
        return
    end
    local fightCfg = JsonConfig.m_vecFightConfig.getDefByID(cfg.fightID)
    if fightCfg == nil then
        return
    end
    local value = {}
    value.enemyZhenfaId = fightCfg.zhenfa[1]
    value.enemyInfos = {}
    local max = AppDef.Formation.MaxFightNum
    for i = 1,max do
        value.enemyInfos[i] = fightCfg["index"..i]
    end
    --dump(value)
    local fun = function()
        LuaNetSendMsg:QueryFengShenStory(25)
    end
    value.callback = fun
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Common.PetFormationUI",AppDef.UIType.FirstClassLayer,value)
    self:SendMsg(LGameMsg.m_initUIMsg)

    self:CloseUI()
end



function FengShenStoryLevelUI:CloseUI()
    LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "FengShenStory.FengShenStoryLevelUI")
    self:SendMsg(LGameMsg.m_deleteUIMsg)
end

function FengShenStoryLevelUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_levelId = nil
    self.m_pBossModel = nil
    self.Script  = nil
end

return FengShenStoryLevelUI