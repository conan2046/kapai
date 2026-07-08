local BattleBossHpNode = require("View.Battle.BattleBossHpNode")
--[[
lua里面的游戏逻辑控制
]]

local BattleUI = LUIBase:New()
BattleUI.__index = BattleUI
--local this = LTcpSocket
function BattleUI:New()
	local o = LUIBase:New()
	setmetatable(o,BattleUI)	
    o:Init()
	return o
end

local PAGE_WIDTH = 380

function BattleUI:Init()
    --self.m_pNode = cc.Node:create()

    self.m_pUILayer = cc.CSLoader:createNode("csd/common/FightLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
   -- self:addChild(self.m_pUILayer)
   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    Utils:SendMsg(LBattleEvent.InitBattle, self.m_pUILayer:getChildByName("FightUI"):getChildByName("Position"))

    self:RegistMsgs()
    self:InitData()
    self:InitTouchEvt()
    self.m_pUILayer:setVisible(false)
end

--[[
注册新手引导
]]
function BattleUI:RegisterGuide()
    if self._battleInfo == nil then
        return
    end
    -- local isFirstBattle = (not Utils:ToBool(LRoleDataMgr:GetSettingConfig(AppDef.ServerSetIndex.SSI_FIRST_BATTLE)))
    -- local isAutoBattle = self._battleInfo[AppDef.battle_Info.TAG_ISAUTO]
    -- --------------------------------------------------------------------------
    -- local level = LRoleDataMgr.MyHeroInfo.level
    -- if not Utils:ToBool(isAutoBattle) then
    --     if #self._skillBtn > 0 and isFirstBattle then
    --         local pBtn = self._skillBtn[1]
    --         LRoleDataMgr:setGuideComplete(GuideDef.StepId.FirstBattle, true, true, false)
    --         Utils:RegisterGuide(GuideDef.StepId.FirstBattle, self._skillBtn[1], handler(self, BattleUI.OnBtnSkill5ButtonClick), nil, level <= 3, true)
    --     end
    --     if not LRoleDataMgr:isGuideComplete(GuideDef.StepId.AutoBattle, true) then
    --         local isAutoOpened = (not Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_AUTO_FIGHT, true))
    --         Utils:RegisterGuide(GuideDef.StepId.AutoBattle, self._btn_Auto, handler(self, BattleUI.OnBtnAutoButtonClick), nil, isAutoOpened, true)
    --     end
    -- end
    -- if not LRoleDataMgr:isGuideComplete(GuideDef.StepId.DoubleBattleSpeed, true) then
    --     if LRoleDataMgr:GetFightSpeed() > 1 then
    --         LRoleDataMgr:setGuideComplete(GuideDef.StepId.DoubleBattleSpeed, true, false, true)
    --         return
    --     end

    --     --local isDoubleOpened = (not Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_FIGHT_DOUBLE, true))
    --     Utils:RegisterGuide(GuideDef.StepId.DoubleBattleSpeed, self.m_btnSpeed, handler(self, BattleUI.SpeedButtonClick), nil, level == 9, true)
    --     if isDoubleOpened then
    --         performWithDelay(self.m_btnSpeed, function(sender)
    --             self:AutoFinishGuide()
    --         end, 3)
    --     end
    -- end

end

function BattleUI:onExit()
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.FirstBattle)
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.AutoBattle)
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.DoubleBattleSpeed)
    self.m_pUILayer = nil
    LRoleDataMgr.isInBattle = false
    -- self:UnSkillSchedule();
    self:UnRoundSchedule();
    -- self:UnRoundSkillTouchSchedule()
    self:Destory()
end
function  BattleUI:initBg()

    -- local panel = self.m_pUILayer:getChildByName("FightUI")
    -- local bg = panel:getChildByName("Scene")
    -- if LRoleDataMgr.MyHeroInfo:GetSceneType()==AppDef.SceneType.MSI_COPY 
    --     or LRoleDataMgr.MyHeroInfo:GetSceneType()==AppDef.SceneType.MSI_PETCOPY
    --     or LRoleDataMgr.MyHeroInfo:GetSceneType()==AppDef.SceneType.MSI_SHILIAN   
    --     then
    --      bg:loadTexture("res/UI/ui_zhandou/bg_fuben.jpg", ccui.TextureResType.localType)       
    -- elseif self._isJingji==true 
    --    or LRoleDataMgr.MyHeroInfo:GetSceneType()==AppDef.SceneType.MSI_SHENJIEMIJING
    --    or LRoleDataMgr.MyHeroInfo:GetSceneType()==AppDef.SceneType.MSI_WEIWODUXIAN
    --    or LRoleDataMgr.MyHeroInfo:GetSceneType()==AppDef.SceneType.MSI_LUNDAO      
    --    or LRoleDataMgr.MyHeroInfo:GetSceneType()==AppDef.SceneType.MSI_FACTION_ZONE
    --    or LRoleDataMgr.MyHeroInfo:GetSceneType()==AppDef.SceneType.MSI_FLYFARY
    --    or LRoleDataMgr.MyHeroInfo:GetSceneType()==AppDef.SceneType.MSI_FACTION_WAR
    --    or LRoleDataMgr.MyHeroInfo:GetSceneType()==AppDef.SceneType.MSI_KUNLUN
    --    or LRoleDataMgr.MyHeroInfo:GetSceneType()==AppDef.SceneType.MSI_LEITAISAI

    --  then
    --       bg:loadTexture("res/UI/ui_zhandou/bg_jingji.jpg", ccui.TextureResType.localType)  
    --       self._isJingji=false     
    -- else
    --     -- print("..LRoleDataMgr.MyHeroInfo.mid我的场景id..",LRoleDataMgr.MyHeroInfo.mid)
    --       bg:loadTexture("res/UI/ui_zhandou/bg"..LRoleDataMgr.MyHeroInfo.mid..".jpg", ccui.TextureResType.localType)
    -- end
end
function BattleUI:InitData()

    AppDef.spriteFrameCache:addSpriteFrames("csd/Plist/ui_main_iconPlist.plist","csd/Plist/ui_main_iconPlist.png")
    AppDef.spriteFrameCache:addSpriteFrames("csd/Plist/ui_zhandouPlist.plist","csd/Plist/ui_zhandouPlist.png")
    self._MapCurSkill = {}
    self._skillBtn = {}
    local panel = self.m_pUILayer:getChildByName("FightUI")

    BattleBossHpNode:New(panel:getChildByName("Head"))

    -- self._Round = panel:getChildByName("Round")
    -- self._num = self._Round:getChildByName("Num")
    -- self._num:setString("1")
    self:initBg()
    self._Round_Special = panel:getChildByName("Round_Special")
    -- self._Round_Special:setVisible(false)
    self._specialNum = self._Round_Special:getChildByName("Num")
    self._specialNum:setString("1")

    self._starArr = {}
    local tar1 = self._Round_Special:getChildByName("Star1")
    table.insert(self._starArr, tar1)

    local tar2 = self._Round_Special:getChildByName("Star2")
    table.insert(self._starArr, tar2)

    local tar3 = self._Round_Special:getChildByName("Star3")
    table.insert(self._starArr, tar3)

    self._CountDown = panel:getChildByName("CountDown")
    local Panel_Shortcut = panel:getChildByName("Panel_Shortcut")
--    Panel_Shortcut:setVisible(false)
    self._listView = Panel_Shortcut:getChildByName("ListView")
    self._listView:setItemsMargin(10)
    self._pCell = panel:getChildByName("Item")
    --阵法 --暂时没有
    self._btn_Formation_Enemy = panel:getChildByName("btn_Formation_Enemy") --敌人的阵法

    local function enemyFormationBtn( sender )
		if self._battleInfo == nil then
			return
		end
        -- body
        local posX = sender:getPositionX() - sender:getContentSize().width / 2 - self._formationInfoCell:getContentSize().width - 10;
        -- self._formationInfo:setPositionX(posX)
        -- self._formationInfo:setVisible(true)
        local lv = self._battleInfo.enemyZhenfaLv
        local enemyFormationID = self._battleInfo.enemyZhenfaId
        self:updateFormationUI(1, enemyFormationID, lv, posX)

    end    
    self._btn_Formation_Enemy:addClickEventListener(enemyFormationBtn)
	self:MarkIntaractCObj(self._btn_Formation_Enemy)

    self._btn_Formation_Oneself = panel:getChildByName("btn_Formation_Oneself") --自己的阵法

    local function myFormationBtn( sender )
        if self._battleInfo == nil then
            return
        end
        -- body
        local posX = sender:getPositionX() + sender:getContentSize().width / 2 + 10;
        -- self._formationInfo:setPositionX(posX)
        -- self._formationInfo:setVisible(true)
        local lv = self._battleInfo.myZhenfaLv
        local myFormationId = self._battleInfo.myZhenfaId
        self:updateFormationUI(2, myFormationId, lv, posX)
    end
    self._btn_Formation_Oneself:addClickEventListener(myFormationBtn)
	self:MarkIntaractCObj(self._btn_Formation_Oneself)
    self._firstRound = true
    self._curRound = 0

    --5个技能的CD时间
    self._cdTimeArr = {}
    for i=1, 5 do
        self._cdTimeArr[i] = 0;
    end

    self._touchTime = 1

    self._alreadyAddBtn = {} 
end

--[[
注册UI消息
]]
function BattleUI:RegistMsgs()
    self.msgIds = 
    {
        LUILogicEvent.EnterBattle,
        LUILogicEvent.ExitBattle,
        -- LUIBattleEvent.updateSkillData,
        -- LUIBattleEvent.InitSkillCD,
        LUIBattleEvent.SelectAction,
        LUIBattleEvent.ActionPlaying,
        LUILogicEvent.addBattleMenu,
        LUIBattleEvent.UpdateSpeed,
        LUILogicEvent.checkAllBattleRedPot,
        LUILogicEvent.EnterJingji,
    }
    self:RegistSelf(self,self.msgIds)
end

function BattleUI:DoEnterBattle(dataArr)
    self.m_pUILayer:setVisible(true)
    self._battleInfo = dataArr;

    self._canJump =  dataArr.showJumpFlag > 0;
    --if self._canJump == false then
        --self._btnJump:getChildByName("Mask"):setVisible(true)
        --self._btnJump:getChildByName("Image_suo"):setVisible(true)
    --else
        --self._btnJump:getChildByName("Mask"):setVisible(false)
        --self._btnJump:getChildByName("Image_suo"):setVisible(false)
    --end

    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_FIGHT_JUMP,true) then
        self._btnJump:setVisible(false)
    else
        self._btnJump:setVisible(true)
    end


    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_FIGHT_SPEEDUP_1,true) then
        self.m_btnSpeed:setVisible(false)
    else
        self.m_btnSpeed:setVisible(true)
    end
    self._curRound = self._battleInfo.curRound;
    -- self:loadSkillData();
    --self:ChangeMapSuccess(msg.value)
    --获取自动战斗
    -- self:getEnterAutoData();
    -- self:SetAutoBattle()
    --展示技能UI
    -- self._btn_Flee:setVisible(true)

    self:ShowRound();
    self:ShowZhenfa();
    --重置技能选中状态
    -- self:updateChooseState(0)
    --更新自动战斗UI
    self:udapteAutoBattleUI(self._battleInfo.isAuto);
    LRoleDataMgr.isInBattle = true

    --战斗中菜单栏,暂时隐藏        
    self:addMenu()
    --技能更新
    self.m_isFirst = true
    self.m_lastUseSkId = 0--上一回合使用的技能id
    self:ChangeSpeedBtn()
    self:initBg()
    if LRoleDataMgr.MyHeroInfo.m_CardBuffer==1 then
       Utils:ShowScrollTips(GUITips.RSI_CARDTIPS1)
       Utils:ShowBuffTips(AppDef.BuffType.PlatinumMC) 
       LRoleDataMgr.MyHeroInfo.m_CardBuffer=0
    end
end

function BattleUI:ProcessEvent(msg)
    --print("BattleUI:ProcessEvent")
    if msg.msgId == LUIBattleEvent.InitSkillCD then
        -- self:loadSkillData()
        -- self:InitSkillCD(msg.value)
    elseif msg.msgId == LUILogicEvent.EnterBattle then
        self:DoEnterBattle(msg.value);
    elseif msg.msgId == LUILogicEvent.ExitBattle then
        --self:ShowHeroExp(true,false)
        self._battleInfo = nil
        self.skill_infos = nil
        LRoleDataMgr.isInBattle = false
        if self.m_pUILayer:isVisible() == false then
            --第一次连接登录服失败也会有这里
            return
        end
        self.m_pUILayer:setVisible(false)
        local isFirstBattle = (not Utils:ToBool(LRoleDataMgr:GetSettingConfig(AppDef.ServerSetIndex.SSI_FIRST_BATTLE)))
        --------------------------------------------------------------------------
        if isFirstBattle then
            LuaNetSendMsg:DealMsgSaveSettingInfo(AppDef.ServerSetIndex.SSI_FIRST_BATTLE, 1)
        end
  

--重置回合数
        self._curRound = 1
        local total = 6
        local str = string.format("%02d/%02d", self._curRound, total)
        self._specialNum:setString(str)
        -- self._num:setString(self._curRound);

        self:AutoFinishGuide()
    elseif msg.msgId == LUIBattleEvent.SelectAction then
      --回合结束
      --不是自动战斗才可以恢复技能选择
        
        LGameMsg.m_baseMsgWithOne:Change(LBattleEvent.UseSkill, 0)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
        if self._curRound then
            self._curRound = self._curRound + 1
            --print("self._curRound *******************************", self._curRound)
            self:ShowRound();
            --self:updateRoundUI()
        end


--       self:RegisterGuide()
--       if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_AUTO_FIGHT, true) or not (self._battleInfo ~= nil and self._battleInfo[AppDef.battle_Info.TAG_ISAUTO]) then
--         self._firstRound  = false
--         self:enalbeUseSkillState(true)

--         --重置逃跑按钮
--         self._btn_Flee:setTouchEnabled(true)
--         self._btn_Flee:getChildByName("Mask"):setVisible(false)
        
-- 		if self._battleInfo == nil then
-- 			self.m_coldTime = 0
-- 		else
-- 			self.m_coldTime = self._battleInfo[AppDef.battle_Info.TAG_WAITSECS]
-- 		end
--         self:TimerCallBack()
--       else
--          LuaNetSendMsg:QueryBattleAct(AppDef.BTConst.ActOpt.ACT_AUTOFIGHT, 1)
--          self._firstRound  = false

--          --重置逃跑按钮
--         self._btn_Flee:setTouchEnabled(false)
--         self._btn_Flee:getChildByName("Mask"):setVisible(true)

--       end

--       self._btn_Flee:getChildByName("Choose"):setVisible(false)

--       if self._curRound then
--         self._curRound = self._curRound + 1
--         --print("self._curRound *******************************", self._curRound)
--         self:updateRoundUI()
--       end

-- --重置技能选中状态
--         self:updateChooseState(0)
--         self:UpdateSkillPlaying(self.m_lastUseSkId)
--         if not self.m_isFirst then
--             self:skillCDTimer()
--         else
--             self.m_isFirst = false
--         end
        
--         self:ShowSkillCD()

    elseif msg.msgId == LUIBattleEvent.ActionPlaying then
    --技能释放中
        
        --self:ShowSkillCD()
        self.m_lastUseSkId = msg.value
        --print("select Id = ", self.m_lastUseSkId)

--        if not self._battleInfo[AppDef.battle_Info.TAG_ISAUTO] then
--            self:UpdateSkillPlaying(msg.value);
--        end

        --print("updateChooseState value ------------------------- ", msg.value)
        -- self:updateChooseStateByID(msg.value)

    elseif msg.msgId == LUIBattleEvent.updateSkillData then
        -- if self.m_pUILayer:isVisible() then
        --     -- self:loadSkillData()
        --     self:getEnterAutoData()
        --     --print("LUIBattleEvent.updateSkillData isAuto", self._battleInfo[AppDef.battle_Info.TAG_ISAUTO])
        --     if not self._battleInfo[AppDef.battle_Info.TAG_ISAUTO] then
        --         self.m_coldTime = self._battleInfo[AppDef.battle_Info.TAG_WAITSECS]
        --         self:TimerCallBack()
        --     else

        --     end
        --     self:UpdateSkillMenu()
        --     --重置技能选中状态
        --     -- self:updateChooseState(0)
   
        --     --更新自动战斗UI
        --     self:udapteAutoBattleUI(self._battleInfo[AppDef.battle_Info.TAG_ISAUTO]);
        --     LRoleDataMgr.isInBattle = true
        -- end
    elseif msg.msgId == LUILogicEvent.addBattleMenu then
--        print("************************* addBattleMenu")
        self:addMenu()
   elseif msg.msgId == LUILogicEvent.EnterJingji then
--        print("************************* addBattleMenu")
     
         self._isJingji=true
    elseif msg.msgId == LUIBattleEvent.UpdateSpeed then
        self:ChangeSpeedBtn()
    elseif msg.msgId == LUILogicEvent.checkAllBattleRedPot then
        self:CheckAllPromptInBattle()
    end

end

-- function BattleUI:updateRoundUI()
--     if self._battleInfo == nil then
--         return
--     end
--     -- body
--     local maxRound = self._battleInfo.maxRound
--     local battleType = self._battleInfo.battleType
--     if battleType == AppDef.BTConst.BattleType.BT_BOSS or battleType == AppDef.BTConst.BattleType.BT_FENGSHEN then
--         local str = ""
--         local total = 3
--         if self._curRound <= 3 then
--             total = 3
--             self:updateStar(3)
--         elseif self._curRound <= 6 then
--             total = 6
--             self:updateStar(2)
--         elseif self._curRound <= maxRound then
--             total = maxRound
--             self:updateStar(1)
--         else
--             self:updateStar(0)
--         end
--         str = string.format("%02d/%02d", self._curRound, total)
--         self._specialNum:setString(str)
--     else
--         self._num:setString(self._curRound)
--     end
-- end

function BattleUI:updateStar(star)
    -- body
    -- for i = 1, #self._starArr do
    --     self._starArr[i]:setVisible(true)
    --     if i > star then
    --         self._starArr[i]:setVisible(false)
    --     end
    -- end
end

-- function BattleUI:enalbeUseSkillState(enableUseSkill)
--     for i = 1, #self._skillBtn do
--         if self:isSkillOpen(i) then
--             self._skillBtn[i]:getChildByName("Mask"):setVisible(not enableUseSkill)
--         end
--     end 

--     self._btn_Flee:setTouchEnabled(false)
--     self._btn_Flee:getChildByName("Mask"):setVisible(true)
-- end

-- function BattleUI:OnBtnSkill5ButtonClick(sender)
--     self:UseSkill(1)
-- end

-- function BattleUI:OnBtnSkillTouchEnvet(sender, pEvent)
--     -- body
--     --print("OnBtnSkillTouchEnvet touch")
--     if pEvent == ccui.TouchEventType.began then
--         --print("OnBtnSkillTouchEnvet sender.userObject", sender.userObject)
--         self:updateSkillTouchCountDown(sender.userObject, sender:getContentSize().width)
--     end

--     if pEvent == ccui.TouchEventType.moved then
--     end

--     if pEvent == ccui.TouchEventType.ended then
--         if self._touchTime < 1.5 then
--             self:UseSkill(sender.userObject)
--         end
--         self:UnRoundSkillTouchSchedule()
--     end
-- end

-- function BattleUI:updateSkillTouchCountDown(index, width)
--     local function UpdateCD()
--        self._touchTime = self._touchTime + 0.5
--        if self._touchTime >= 1.5 then
--         self:UnRoundSkillTouchSchedule()
--         --展示技描述
--         self:ShowSkillDes(index, width)
--        end
--     end

--     self:UnRoundSkillTouchSchedule()
--     self._touchTime = 1
--     local scheduler =  AppDef.Director:getScheduler()
--     self.m_schedulerSkillTouchID = scheduler:scheduleScriptFunc(UpdateCD, 0.5, false)
    
-- end

-- function BattleUI:UnRoundSkillTouchSchedule()
--     if self.m_schedulerSkillTouchID then
--         AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_schedulerSkillTouchID)
--         self.m_schedulerSkillTouchID = nil
--     end
-- end


function BattleUI:ShowSkillDes(index, width)
    -- body
--     if self.skill_infos == nil then
--         return
--     end

--     local info = self.skill_infos[index]
--     if info == nil then
--         return
--     end

--     local skillId = info.skill.id
--     if skillId <= 0 then
--         return
--     end

--     self._pupopSkill:setVisible(true)
--     local posX = self._SDBeginPos.x - (index - 1) * width
--     self._pupopSkill:setPositionX(posX)

--     local skillLevel = info.skill.level
--     if not self:isSkillOpen(index) then
--         skillLevel = info.skill.learnLevel
--     end

--     local curDesc = LDataConstMgr:GetHeroSkillDesc(info.skill.id, skillLevel)
--     self._explain:setString(curDesc)
--     local height = self._explain:getSize().height
    
--     local heightDiff = height - self._ExplainSize.height
--     self._SDBg:setContentSize(cc.size(self._sdBgContentSize.width, self._sdBgContentSize.height + heightDiff))

--     local heightOffset = heightDiff / 2
--     self._explain:setPositionY(self._SDExplainPosY + heightOffset)
--     self._pupopSkill:setPositionY(self._SDBeginPos.y + heightOffset)

-- --名字
--     self._SDTitle:setString(info.skill.name)
--     self._SDTitle:setPositionY(self._SDTitlePosY + heightOffset)

-- --技能图标
--     local imagefile = string.format("Skill/UI/skill_%d.png", info.skill.id)
--     self._SDIcon:loadTexture(imagefile, ccui.TextureResType.localType)
--     local skillIcon = self._pupopSkill:getChildByName("Skill")
--     skillIcon:setPositionY(self._SDIconPosY + heightOffset)

--    self._SDImage:setPositionY(skillIcon:getPositionY() - skillIcon:getContentSize().height / 2 + 3)
--    self._SDImage:setScaleY(2.0)

-- --技能CD
--     local cdStr = string.format(GUITips.RSI_SKILL_CD, info.skill.cd)
--     self._SDCD:setString(cdStr)
--     local cd = self._pupopSkill:getChildByName("CD")
--     cd:setPositionY(self._SDCDPosY + heightOffset)

end

function BattleUI:OnBtnJumpClick(sender)
    if  self._battleInfo == nil then
        return
    end
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_FIGHT_JUMP) then
        return
    end
    if self._canJump == false then
        Utils:ShowScrollTips(GUITips.RSI_JUMPBATTLE)
        return;
    end
    LGameMsg.m_baseMsgWithOne:Change(LBattleEvent.JumpBattle)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end


function BattleUI:OnBtnAutoButtonClick(sender)
     if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_AUTO_FIGHT) then
         return
     end
    if  self._battleInfo == nil then
        return
    end
     --自动战斗，1是 0不是
    local data = 1
    if self._battleInfo[AppDef.battle_Info.TAG_ISAUTO] then
        data = 0
    end
    LGameMsg.m_baseMsgWithOne:Change(LBattleEvent.AutoBattle, data)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
     --更新自动战斗UI
     if data == 0 then
         self:updateAutoBattleBtnUI(not self._battleInfo[AppDef.battle_Info.TAG_ISAUTO])
     else
         self:udapteAutoBattleUI(not self._battleInfo[AppDef.battle_Info.TAG_ISAUTO])
     end
     self:updateAutoData(not self._battleInfo[AppDef.battle_Info.TAG_ISAUTO])
     --关闭阵法属性ui
     if self._formationInfo then
         self._formationInfo:setVisible(false)
     end

     self:CloseSkillDesPopup()
end

function BattleUI:InitTouchEvt()
    local panel = self.m_pUILayer:getChildByName("FightUI")

    local function closeFormationLayer(pTouch, pEvent)
        if pEvent == ccui.TouchEventType.began then
            if self._formationInfo then
                self._formationInfo:setVisible(false)
            end

            self:CloseSkillDesPopup()
        end

        if pEvent == ccui.TouchEventType.ended then
            
        end
    end

    panel:addTouchEventListener(closeFormationLayer)
	self:MarkIntaractCObj(panel)
    local buttons = panel:getChildByName("Buttons")
    buttons:setSwallowTouches(false)

    self.m_btnSpeed = buttons:getChildByName("btn_Speed")
    self.m_btnSpeed:addClickEventListener(handler(self, BattleUI.SpeedButtonClick))
	self:MarkIntaractCObj(self.m_btnSpeed)
    self:ChangeSpeedBtn()

    --逃跑
    self._btn_Flee = buttons:getChildByName("btn_Flee")
 --    local function OnBtnFleeButtonClick(sender)
 --        LGameMsg.m_baseMsgWithOne:Change(LBattleEvent.RunAway)
 --        self:SendMsg(LGameMsg.m_baseMsgWithOne)

 --        -- self:enalbeUseSkillState(false)
 --        self:UnRoundSchedule()
 --        self._CountDown:setVisible(false)
 --        self._btn_Flee:getChildByName("Choose"):setVisible(true)

 --        --禁用逃跑按钮
 --        self._btn_Flee:setTouchEnabled(false)
 --        self._btn_Flee:getChildByName("Mask"):setVisible(true)

 --    end
 --    self._btn_Flee:addClickEventListener(OnBtnFleeButtonClick)
	-- self:MarkIntaractCObj(self._btn_Flee)
    self._btn_Flee:setVisible(false)

    local btnCancel = buttons:getChildByName("btn_Cancel")
    btnCancel:setVisible(false)

    self._btnJump = buttons:getChildByName("btn_jump");
    self._btnJump:addClickEventListener(handler(self, BattleUI.OnBtnJumpClick))

    --自动
    self._btn_Auto = buttons:getChildByName("btn_Auto")
    self._btn_Auto:addClickEventListener(handler(self, BattleUI.OnBtnAutoButtonClick))
	self:MarkIntaractCObj(self._btn_Auto)
    -------------------
    --技能1
 --    local btn_Skill_5 = buttons:getChildByName("btn_Skill_5")
 --    btn_Skill_5:addTouchEventListener(handler(self, BattleUI.OnBtnSkillTouchEnvet))
	-- self:MarkIntaractCObj(btn_Skill_5)
 --    btn_Skill_5.userObject = 1
 --    table.insert(self._skillBtn, btn_Skill_5)
    
 --    --技能2
 --    local btn_Skill_4 = buttons:getChildByName("btn_Skill_4")
 --    btn_Skill_4:addTouchEventListener(handler(self, BattleUI.OnBtnSkillTouchEnvet))
	-- self:MarkIntaractCObj(btn_Skill_4)
 --    btn_Skill_4.userObject = 2
 --    table.insert(self._skillBtn, btn_Skill_4)

 --    --技能3
 --    local btn_Skill_3 = buttons:getChildByName("btn_Skill_3")
 --    btn_Skill_3:addTouchEventListener(handler(self, BattleUI.OnBtnSkillTouchEnvet))
	-- self:MarkIntaractCObj(btn_Skill_3)
 --    btn_Skill_3.userObject = 3
 --    table.insert(self._skillBtn, btn_Skill_3)

 --    --技能4
 --    local btn_Skill_2 = buttons:getChildByName("btn_Skill_2")
 --    btn_Skill_2:addTouchEventListener(handler(self, BattleUI.OnBtnSkillTouchEnvet))
	-- self:MarkIntaractCObj(btn_Skill_2)
 --    btn_Skill_2.userObject = 4
 --    table.insert(self._skillBtn, btn_Skill_2)

 --    --技能5
 --    local btn_Skill_1 = buttons:getChildByName("btn_Skill_1")
 --    btn_Skill_1:addTouchEventListener(handler(self, BattleUI.OnBtnSkillTouchEnvet))
	-- self:MarkIntaractCObj(btn_Skill_1)
 --    btn_Skill_1.userObject = 5
 --    table.insert(self._skillBtn, btn_Skill_1)

    --btnLocker
    self._btn_Locker = panel:getChildByName("btn_Locker")
    local function OnBtnLockerButtonClick(sender)
        self:Show(not self._isShow)
    end
    self._btn_Locker:addClickEventListener(OnBtnLockerButtonClick)
	self:MarkIntaractCObj(self._btn_Locker)
    self._btn_Locker:setVisible(true)
    self._btnLockerRed = self._btn_Locker:getChildByName("Prompt")
    self._btn_Locker:setVisible(false)

    self._menuPanel = panel:getChildByName("Panel_Shortcut")
    self._isShow = false;
    self._isShowIng = false
    self._menuPanel:setPositionX(-PAGE_WIDTH);
    self._menuPanel:setVisible(true)
    self:arrowState()

    self._formationInfoCell = panel:getChildByName("Pupop_zhenfa")
    self._formationInfoCell:setSwallowTouches(false)
    self._formationInfoCell:setTouchEnabled(false)
    self._formationInfoCell:getChildByName("bg"):setTouchEnabled(true)
    self._formationInfoCell:setVisible(false)

    -- self._pupopSkill = panel:getChildByName("Pupop_Skill")
    -- self._pupopSkill:setVisible(false)
    -- self._SDBeginPos = cc.p(self._pupopSkill:getPosition())


    -- self._SDTitle = self._pupopSkill:getChildByName("Title")
    -- self._SDCD = self._pupopSkill:getChildByName("CD"):getChildByName("Value")
    -- self._SDIcon = self._pupopSkill:getChildByName("Skill"):getChildByName("Icon")
    -- self._SDExplain = self._pupopSkill:getChildByName("Explain")
    -- self._ExplainSize = self._SDExplain:getContentSize()
    -- self._SDBg = self._pupopSkill:getChildByName("bg")

    -- self._explain = Utils:CreateColorText2(self._pupopSkill, self._SDExplain, cc.size(self._ExplainSize.width - 15, self._ExplainSize.height))

    -- self._sdBgContentSize = self._SDBg:getContentSize()
    -- self._SDCDPosY = self._pupopSkill:getChildByName("CD"):getPositionY()
    -- self._SDTitlePosY = self._SDTitle:getPositionY()
    -- self._SDIconPosY = self._pupopSkill:getChildByName("Skill"):getPositionY()
    -- self._SDExplainPosY = self._SDExplain:getPositionY()

    -- self._SDImage = self._pupopSkill:getChildByName("Image")
    -- self._SDImagePosY = self._SDImage:getPositionY()


end

function BattleUI:UseSkill(index)
    -- body
--关闭阵法属性ui
--     if self._formationInfo then
--         self._formationInfo:setVisible(false)
--     end
--     self:CloseSkillDesPopup()
--     if self.skill_infos == nil then
--         return
--     end
--     local info = self.skill_infos[index]
--     if info == nil then
--         return
--     end

--     local skillId = info.skill.id
-- --技能没有解锁
--     if not self:isSkillOpenByID(skillId) then
--         return
--     end

-- --技能CD中
--     if self._cdTimeArr[index] > 0 then
--         return
--     end

-- --当前不可使用技能
--     local mask = self._skillBtn[index]:getChildByName("Mask")
--     if mask:isVisible() then
--         return
--     end

--     --玉虚宫使用三头六臂技能后下一回合选择技能时给出提示：休息中无法行动
--     if self.m_lastUseSkId and self.m_lastUseSkId == 33 then
--        Utils:ShowScrollTips(GUITips.RSI_TARGET_RD_TIPS8)
--     end

--     if skillId > 0 then
--         LGameMsg.m_baseMsgWithOne:Change(LBattleEvent.UseSkill, skillId)
--         self:SendMsg(LGameMsg.m_baseMsgWithOne)
--         self:enalbeUseSkillState(false)
--         self:updateChooseState(index)
--         --print("skillId===============================================", skillId)
--         self._CountDown:setVisible(false)
--         self:UnRoundSchedule();
--     end
    
end

-- function BattleUI:updateChooseStateByID( id )
--     -- body
--     local skillIndex = self:FindSkillIndex(id)
--     --print("skillIndex", skillIndex, id)
--     self:updateChooseState(skillIndex)
-- end


-- function BattleUI:updateChooseState(index)
--     -- body
--     for i = 1, 5 do
--         local chooseState = self._skillBtn[i]:getChildByName("Choose")
--         chooseState:setVisible(false)
--     end

--     if index <= 0 or index > 5 then
--         return
--     end

--     self._skillBtn[index]:getChildByName("Choose"):setVisible(true)
-- end


function BattleUI:Show(b)

    local function BlackPlayEnd(sender)
        self._isShowIng = false
    end

    if(self._isShow == b) then
        return
    end

--动作中不能连续点击
    if self._isShowIng then
        return
    end

    self._isShow = b
    self._isShowIng = true
    if(not b) then
        local action = cc.MoveTo:create( 0.3, cc.p(-PAGE_WIDTH, self._menuPanel:getPositionY()))
        local openSeq = cc.Sequence:create(action, cc.CallFunc:create(BlackPlayEnd)) 
        self._menuPanel:runAction(openSeq)
        self:arrowState()
    else
        local action = cc.MoveTo:create( 0.3, cc.p(55, self._menuPanel:getPositionY()))
        local openSeq = cc.Sequence:create(action, cc.CallFunc:create(BlackPlayEnd)) 
        self._menuPanel:runAction(openSeq);
        self:arrowState()
    end
end


function BattleUI:arrowState()
    -- body
    -- local arrow1 = self._btn_Locker:getChildByName("Arrows")
    -- arrow1:setVisible(not self._isShow)
    -- local arrow2 = self._btn_Locker:getChildByName("Arrows_0")
    -- arrow2:setVisible(self._isShow)
end

function BattleUI:isAutoBattleState(isAuto)
    local isAotuBattleOpen = Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_AUTO_FIGHT, true)
    if not isAotuBattleOpen and isAuto then
        self._CountDown:setVisible(false)
        self:UnRoundSchedule();
        -- self:enalbeUseSkillState(false)

        -- self._btn_Flee:setTouchEnabled(false)
        -- self._btn_Flee:getChildByName("Mask"):setVisible(true)
    else
        -- self:enalbeUseSkillState(true)

--自动战斗状态逃跑按钮
        -- self._btn_Flee:setTouchEnabled(true)
        -- self._btn_Flee:getChildByName("Mask"):setVisible(false)
    end
end

-- function BattleUI:UpdateBattleInfo(value)
--     self._battleInfo = value
--     -- for key, v in pairs(value) do
--     --     print("UpdateBattleInfo", key, v)
--     -- end
    
--     if  self._battleInfo == nil then
--         return
--     end

--     self._canJump = self._battleInfo[AppDef.battle_Info.TAG_SHOWRUNAWAYFLAG] > 0
-- end


-- function BattleUI:loadSkillData( ... )
--     -- body
--     --技能
--     self.skill_infos = {}
--     local skillIds,skillNum = LSkillMgr:GetSkillInfo(LRoleDataMgr.MyHeroInfo.professional)
--     -- --print("skillIds size =", skillIds, #skillIds)
--     for k,v in pairs(skillIds) do
--         local info = {}
--         info.skill = LSkillMgr:getSkillById(v[1])
-- --        print("skill data", info.skill.name, info.skill.desc, info.skill.id, info.skill.cd)
--         info.skill.learnLevel = v[2]
--         if info.skill.skillType and info.skill.skillType == 1 then
--             table.insert(self.skill_infos, info)
--         end
--     end
--     table.sort(self.skill_infos, function(a, b)
--         return a.skill.learnLevel <= b.skill.learnLevel
--     end)
-- end

function BattleUI:ShowZhenfa()
    local enemyFormationID = self._battleInfo.enemyZhenfaId
    local iconResEnemy = AppDef.Formation.IconRes .. enemyFormationID .. ".png"
    -- print("iconResEnemy",iconResEnemy)
    -- self._btn_Formation_Enemy:setVisible(false)
    local enemyBtn = self._btn_Formation_Enemy:getChildByName("Image")
    enemyBtn:loadTexture(iconResEnemy, ccui.TextureResType.localType)
    -- local function LoadImgCompleteOther( tex )
    --     -- body
    --     print("LoadImgCompleteOtherLoadImgCompleteOther")
    --     enemyBtn:loadTexture(iconResEnemy, ccui.TextureResType.localType)
    --     enemyBtn:setVisible(true)
    -- end
    -- local msg = LResMsg:New()

    -- msg:Change(LResEvent.LoadImgSync, iconResEnemy, LoadImgCompleteOther)
    -- self:SendMsg(msg)

    self._btn_Formation_Enemy:getChildByName("Text_name"):setString(self._battleInfo.enemyName);

    --Utils:AsyncLoadImg(self._btn_Formation_Enemy,iconResEnemy,callback)

--    self._btn_Formation_Enemy:loadTextureNormal(iconResEnemy, ccui.TextureResType.localType)

--self._battleInfo[AppDef.battle_Info.TAG_FORMATION_MINE]
    local myFormationId = self._battleInfo.myZhenfaId
    local iconRes = AppDef.Formation.IconRes .. myFormationId .. ".png"
    -- self._btn_Formation_Oneself:setVisible(false)
    local myBtn = self._btn_Formation_Oneself:getChildByName("Image")
    myBtn:loadTexture(iconRes, ccui.TextureResType.localType)
    -- local function LoadImgCompleteSelf( tex )
    --     -- body
    --     myBtn:loadTextureNormal(iconRes, ccui.TextureResType.localType)
    --     myBtn:setVisible(true)
    -- end
    
    -- msg:Change(LResEvent.LoadImgSync, iconRes, LoadImgCompleteSelf)
    -- self:SendMsg(msg)

    self._btn_Formation_Oneself:getChildByName("Text_name"):setString(self._battleInfo.myName);


    if self._formationInfo then
        self._formationInfo:setVisible(false)
    end

    self:CloseSkillDesPopup()

    if self._isShow then
        self:Show(not self._isShow)
    end
end

function BattleUI:ShowRound()
    if self._battleInfo == nil then
        return
    end
    local maxRound = self._battleInfo.maxRound
    

    -- local battleType = self._battleInfo.battleType
    -- if battleType == AppDef.BTConst.BattleType.BT_BOSS or battleType == AppDef.BTConst.BattleType.BT_FENGSHEN then
    --     local str = ""
    --     local total = 3
    --     if self._curRound <= 3 then
    --         total = 3
    --         self:updateStar(3)
    --     elseif self._curRound <= 6 then
    --         total = 6
    --         self:updateStar(2)
    --     elseif self._curRound <= maxRound then
    --         total = maxRound
    --         self:updateStar(1)
    --     else
    --         self:updateStar(0)
    --     end

    --     -- local str = string.format("%02d/%02d", self._curRound, maxRound)
    --     -- self._specialNum:setString(str)
    -- -- else
    -- --     self._specialNum:setString(self._curRound)
    -- end
    local total = 3
    if self._curRound <= 3 then
        total = 3
        self:updateStar(3)
    elseif self._curRound <= 6 then
        total = 6
        self:updateStar(2)
    elseif self._curRound <= maxRound then
        total = maxRound
        self:updateStar(1)
    else
        self:updateStar(0)
    end

    local str = string.format("%02d/%02d", self._curRound, maxRound)
    self._specialNum:setString(str)
end

function BattleUI:CloseSkillDesPopup()
    -- body
    -- if self._pupopSkill:isVisible() then
    --     self._pupopSkill:setVisible(false)
    -- end
end

--[[
根据9宫格下标获取出站位置
]]
function BattleUI:GetCurFormationPos(id, ind)
  
    local finfo = LDataConstMgr:GetFormationDataById(id)

    for i = 1, AppDef.Formation.MaxFightNum do
        if finfo.posList[i] == ind then
            return i
        end
    end
    return 0
end

function BattleUI:updateFormationUI(type, id, lv, posX)
    -- body
    --type 1 敌军阵容  2 我军阵容
--    print("BattleUI:updateFormationUI id", id, lv)
    local fdata = LDataConstMgr:GetFormationLvUpData(id, lv)
     
    --每个站位对应两个附加属性值
    local attrType
    local attrValue
    local arrName
    local strAttr = ""
    local attrStrArr = {}

    local posData = {}
    for i = 1, AppDef.BTConst.MaxHalfUnitNum do
        local ind = self:GetCurFormationPos(id, i)
        if ind > 0 then
            table.insert(posData, {i, ind})
        end
    end

    for i = 1, AppDef.Formation.MaxFightNum do
        strAttr = ""
        for j = 1,#fdata.addAttrType[i] do
            attrType = fdata.addAttrType[i][j]
            if attrType == AppDef.EAttrType.EAT_ATTACK then
                arrName = GUITips.Item_Info_Attr145
            else
                arrName = LDataConstMgr:GetItemAttrName(attrType)
            end
            attrValue = fdata.addAttrValue[i][j]

            if AppDef:IsRatioAttr(attrType) then
                attrValue = attrValue / 100.0
                tmp = "%"
            else
                tmp = ""
            end

            if attrValue > 0 then
                strAttr = strAttr .. arrName .. "+" .. attrValue .. tmp ..  "  "
            else
                strAttr = strAttr .. arrName .. attrValue .. tmp .. "  "
            end
        end
        local data = {}
        
		for j,value in pairs(posData) do
			if value[2] == i then
				data.pos = value[1]
				break
			end
		end
        data.str = strAttr
        --print("Formation arr", strAttr, data.pos)
        table.insert(attrStrArr, data)

    end

    local finalData = {}
    if type == 1 then
--        Utils:dump(self._battleInfo[AppDef.battle_Info.TAG_FORMATION_ENEMY_ATTR])
        --print("----------------------------------------------------------------------")
        -- Utils:dump(attrStrArr)
        for j = 1, #self._battleInfo.enemyZhenfa do
            local data = self._battleInfo.enemyZhenfa[j]
            for k=1, #attrStrArr do

                if attrStrArr[k].pos == data[1] then
                    local oneShowData = {}
                    oneShowData.pos = self:GetCurFormationPos(id, data[1]) 
                    oneShowData.name = data[2]
                    oneShowData.attr = attrStrArr[k].str
                    table.insert(finalData, oneShowData)
                end
            end
        end
    else

        --Utils:dump(self._battleInfo[AppDef.battle_Info.TAG_FORMATION_MINE_ATTR])
        --print("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
        --Utils:dump(attrStrArr)
        for j = 1, #self._battleInfo.myZhenfa do

            local data = self._battleInfo.myZhenfa[j]
            for k=1, #attrStrArr do
                if attrStrArr[k].pos == data[1] then
                    local oneShowData = {}
                    oneShowData.pos = self:GetCurFormationPos(id, data[1]) 
                    oneShowData.name = data[2]
                    oneShowData.attr = attrStrArr[k].str
                    table.insert(finalData, oneShowData)
                end
            end
        end
    end

    if self._formationInfo then
        self._formationInfo:removeFromParent()
    end
    self._formationInfo = self._formationInfoCell:clone()
    self._formationInfo:setVisible(true)
    local panel = self.m_pUILayer:getChildByName("FightUI")
    panel:addChild(self._formationInfo)
    self._formationInfo:setPositionX(posX)
    local title = self._formationInfo:getChildByName("Title")

    local formationData = LDataConstMgr:GetFormationDataById(id)
    local finalDataSize = #finalData
    --print("title name", formationData.name, lv, finalDataSize)
    local str = string.format("%sLV.%d", formationData.name, lv)
    title:setString(str)

    for i=1, AppDef.Formation.MaxFightNum do
        local Attribute = self._formationInfo:getChildByName(string.format("Attribute_%d", i))
        Attribute:setVisible(false)
    end


    function sortFunc(a, b) 
        return a.pos < b.pos 
    end 
    table.sort(finalData, sortFunc)

    local widthMax = 0
    local nameWidthMax = 0
    for i = 1, finalDataSize do
        local Attribute = self._formationInfo:getChildByName(string.format("Attribute_%d", i))
        Attribute:setVisible(true)
        local num = Attribute:getChildByName("Num")

        num:setString(finalData[i].pos)
        local name = Attribute:getChildByName("Name")
        local XSize = name:getContentSize()
        --print("updateFormationUI xSize =", XSize.width, XSize.height)
        name:setString(finalData[i].name)
        local XSize2 = name:getContentSize()
        if XSize2.width > nameWidthMax then
            nameWidthMax = XSize2.width
        end
        --print("updateFormationUI after xSize =", XSize2.width, XSize2.height)

        local value = name:getChildByName("Value")
        value:setPositionX(value:getPositionX() + XSize2.width - XSize.width)
        value:setString(finalData[i].attr)
        --print("BattleUI:isSkillOpen ", value:getContentSize().width)
        if value:getContentSize().width > widthMax then
            widthMax = value:getContentSize().width
        end
    end

    local size = self._formationInfo:getContentSize()
    --print("size =", size.width, size.height)
    local bgWidth = size.width + 30
    local posOffset = 0
    local space = 0
    if widthMax > 220 then
        bgWidth = bgWidth + 30
        posOffset = posOffset + 15
    end

--    print("nameWidthMax 77777777777777777777777777", nameWidthMax, widthMax, type)
    if nameWidthMax > 70 then
        bgWidth = bgWidth + nameWidthMax - 70
        posOffset = posOffset + (nameWidthMax - 70) / 2
        space = (nameWidthMax - 70) / 2
    end
--    self._formationInfo:setContentSize(cc.size(size.width, size.height - (AppDef.Formation.MaxFightNum - finalDataSize) * 30))
    local bg = self._formationInfo:getChildByName("bg")
    bg:setContentSize(cc.size(bgWidth, size.height - (AppDef.Formation.MaxFightNum - finalDataSize) * 30))
    local imageLine = self._formationInfo:getChildByName("Image")
 --   imageLine:setPositionY(imageLine:getPositionY())
    bg:setPositionY(bg:getPositionY() + (AppDef.Formation.MaxFightNum - finalDataSize) * 30 / 2)

    local kezhiBg = self._formationInfo:getChildByName("kezhi")
    if nameWidthMax > 80 then
        if type == 2 then
            bg:setPositionX(bg:getPositionX() + posOffset)
            imageLine:setContentSize(cc.size(imageLine:getContentSize().width + posOffset, imageLine:getContentSize().height))
            imageLine:setPositionX(imageLine:getPositionX() + posOffset)
        else
--            print("------------------- space =", space, posOffset)
            bg:setPositionX(bg:getPositionX() - posOffset)
            imageLine:setContentSize(cc.size(imageLine:getContentSize().width + posOffset, imageLine:getContentSize().height))
            imageLine:setPositionX(imageLine:getPositionX() - posOffset)
            kezhiBg:setPositionX(kezhiBg:getPositionX() - (posOffset + space))
            title:setPositionX(title:getPositionX() - (posOffset + space))
            for i = 1, finalDataSize do
                local Attribute = self._formationInfo:getChildByName(string.format("Attribute_%d", i))
                Attribute:setPositionX(Attribute:getPositionX() - (posOffset + space))
            end
            
        end
    end
    
    local size = self._formationInfo:getContentSize()
    --print("after size =", size.width, size.height)
    
    local kezhi = kezhiBg:getChildByName("Name")
    local kezhiAttr = ""
    for i = 1, #formationData.restraintList do
        local kezhiData = LDataConstMgr:GetFormationDataById(formationData.restraintList[i])
        kezhiAttr = kezhiAttr .. kezhiData.name .. "  "
    end
    --print("kezhiAttr", kezhiAttr)
    kezhi:setString(kezhiAttr)

    kezhiBg:setPositionY(kezhiBg:getPositionY() + (AppDef.Formation.MaxFightNum - finalDataSize) * 30)


end

function BattleUI:isSkillOpen(idx)
    -- body
    if self.skill_infos == nil then
        return
    end
    local info = self.skill_infos[idx]
    if info == nil then
        return
    end
    return self:isSkillOpenByID((info and info.skill) and info.skill.id or 0)
end

function BattleUI:isSkillOpenByID(id)
    if id == nil then
        return false
    end
    -- body
    local skill = LRoleDataMgr:GetSkillDetailById(id)
    if skill == nil then
        return false
    end
    return true
end

-- function BattleUI:DrawSkillInfo()
--     if self.skill_infos == nil then
--         return
--     end
--     for i = 1, #self.skill_infos do
-- --第6个技能是被动技能，战斗不显示
--         if i == 6 then
--             return
--         end

--         self._skillBtn[i]:setVisible(true)
--         local mask = self._skillBtn[i]:getChildByName("Mask")
--         mask:setVisible(false)

--         local info = self.skill_infos[i]

--         local skill = LDataConstMgr:GetSkillDetailList(info.skill.id)
--         --print("info.skill.id", info.skill.id)

--         local imagefile = string.format("Skill/UI/skill_%d.png", info.skill.id)
--         local icon = self._skillBtn[i]:getChildByName("Icon")

--         icon:setVisible(false)
--         local function LoadImgComplete( tex )
--             -- body
--             icon:loadTexture(imagefile, ccui.TextureResType.localType)
--             icon:setVisible(true)
--         end
--         local msg = LResMsg:New()
--         msg:Change(LResEvent.LoadImgSync, imagefile, LoadImgComplete)
--         self:SendMsg(msg)

--         self._skillBtn[i]:getChildByName("CD"):setVisible(false)

--         local typeIcon = self._skillBtn[i]:getChildByName("Type")
--         typeIcon:setVisible(true)
--         local strIcon = "res/UI/ui_common/ui_biaoqian_gongji_" .. info.skill.skillTypeTitle..".png"
--         typeIcon:loadTexture(strIcon, ccui.TextureResType.plistType)

--         local skillName = self._skillBtn[i]:getChildByName("SkillName")
--         skillName:setString(info.skill.name)
--         local skillLock = self._skillBtn[i]:getChildByName("Lock")
--         if info.skill.learnLevel > LRoleDataMgr.MyHeroInfo.level then
--             mask:setVisible(true)
--             skillLock:setString(tostring(info.skill.learnLevel)..GUITips.UI_JiKaiqi)
--             return
--         else
--             skillLock:setVisible(false)
--         end
        

--     end

-- end

--更新自动战斗的ui
function BattleUI:udapteAutoBattleUI(isAuto)
    self:updateAutoBattleBtnUI(isAuto)
    self:isAutoBattleState(isAuto)
end

--更新
function BattleUI:updateAutoBattleBtnUI(isAuto)
    -- body
    local text = self._btn_Auto:getChildByName("Text")
    local icon = self._btn_Auto:getChildByName("Icon")
    if isAuto then
        icon:loadTexture("res/UI/ui_zhandou/ui_zhandou_quxiaozidong_02.png", ccui.TextureResType.plistType)
        text:setString(GUITips.RSI_CANCEL_AUTOBATTLE)
    else
        icon:loadTexture("res/UI/ui_zhandou/ui_zhandou_zidongzhandou_01.png", ccui.TextureResType.plistType)
        text:setString(GUITips.RSI_AUTOBATTLE)
    end
end

function BattleUI:updateAutoData(isAuto)
    -- body
    if self._battleInfo == nil then
        return
    end
	if self._battleInfo[AppDef.battle_Info.TAG_ISAUTO] ~= nil then
		self._battleInfo[AppDef.battle_Info.TAG_ISAUTO] = isAuto
	end

   local pUserDefault = CCUserDefault:getInstance()
   local userId = LRoleDataMgr.MyHeroInfo.id
   local autoKey = LUserConfigMgr.USERCONFIG_LASTBATTLE_STATE..userId
   pUserDefault:setBoolForKey(autoKey, isAuto)
end

-- function BattleUI:SetAutoBattle()
--     if self._btn_Auto == nil then
--         return
--     end
--     ------------------------------------------------------
--     local autoId = AppDef.EModuleID.EMID_AUTO_FIGHT
--     local isDefaultShow = LDataConstMgr:isModuleDefaultShow(autoId)
--     local isNotOpen = Utils:CheckModelNotOpened(autoId, true)
--     local isShow = isNotOpen and isDefaultShow
--     -------------------
--     local pMask = self._btn_Auto:getChildByName("Mask")
--     if pMask then
--         pMask:setVisible(isShow)
--     end
--     -------------------
--     local pLock = self._btn_Auto:getChildByName("Lock")
--     if pLock then
--         pLock:setVisible(isShow)
--         if isShow then
--             pLock:setString("")
--             local level = LDataConstMgr:GetFuctionCondition(autoId, 1)
--             if level > 0 then
--                 pLock:setString(tostring(level)..GUITips.UI_JiKaiqi)
--             end
--         end
--     end
-- end

-- function BattleUI:getEnterAutoData()
--     -- body
--     if self._battleInfo.battleType == AppDef.BTConst.BattleType.BT_BOSS then
--         self._battleInfo.isAuto = false;
--     else
--         local pUserDefault = CCUserDefault:getInstance()
--         local userId = LRoleDataMgr.MyHeroInfo.id
--         local autoKey = LUserConfigMgr.USERCONFIG_LASTBATTLE_STATE..userId
--         local isAutoBattle = pUserDefault:getBoolForKey(autoKey, false)
--         self._battleInfo.isAuto = isAutoBattle
--     end
-- end

-- function BattleUI:InitSkillCD(skillCDs)
--     for i = 1,#skillCDs do
--         local idx = self:FindSkillIndex(skillCDs[i][1])
--         if idx > 0 and idx < 6 then
--             self._cdTimeArr[idx] = skillCDs[i][2]
--         end
--     end
-- end

-- function BattleUI:UpdateSkillPlaying(id)
--     local idx = self:FindSkillIndex(id)
-- --技能播放期间不能释放次技能
--     if idx > 6 or idx <= 0 then
--         return
--     end
--     if self.skill_infos == nil or self.skill_infos[idx] == nil then
--         return
--     end
--     self._cdTimeArr[idx] = self.skill_infos[idx].skill.cd

--     if self._cdTimeArr[idx] <= 0 then
--         return
--     end

--     local cdTxt = self._skillBtn[idx]:getChildByName("CD")
--     cdTxt:setVisible(true)
--     cdTxt:setString(self._cdTimeArr[idx])
-- end

-- function BattleUI:FindSkillIndex(id)
--     if self.skill_infos == nil then
--         return 0
--     end
--     for i = 1, #self.skill_infos do
--         if self.skill_infos[i].skill.id == id then
--             return i
--         end
--     end
--     return 0;
-- end

-- function BattleUI:ShowSkillCD()
--     for i = 1, #self._cdTimeArr do
--         local cdTxt = self._skillBtn[i]:getChildByName("CD")
--         cdTxt:setString(self._cdTimeArr[i])
--         if self._cdTimeArr[i] <= 0 then
-- --            self._skillBtn[i]:setTouchEnabled(true)
--             cdTxt:setVisible(false)
--         else
--             self._skillBtn[i]:getChildByName("Mask"):setVisible(true)
--         end
--     end
-- end

-- function BattleUI:skillCDTimer()
--     -- body
--     for i = 1, #self._cdTimeArr do
--         if self._cdTimeArr[i] > 0 then
--             self._cdTimeArr[i] = self._cdTimeArr[i] - 1
--         end
--     end
-- end

-- function BattleUI:UnSkillSchedule()
--     if self.m_SkillScheduler then
--         AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_SkillScheduler)
--         self.m_SkillScheduler = nil
--     end
-- end

function BattleUI:AutoFinishGuide()
    LGameMsg.m_baseMsgWithOne:Change(LUIGuideEvent.AutoFinishGuide, GuideDef.StepId.FirstBattle)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    LGameMsg.m_baseMsgWithOne:Change(LUIGuideEvent.AutoFinishGuide, GuideDef.StepId.AutoBattle)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    LGameMsg.m_baseMsgWithOne:Change(LUIGuideEvent.AutoFinishGuide, GuideDef.StepId.DoubleBattleSpeed)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function BattleUI:TimerCallBack()
    local function UpdateCD()
        self.m_coldTime = self.m_coldTime - 1
        if self.m_coldTime <= 1 then
            self:AutoFinishGuide()
        end
        self._CountDown:setString(self.m_coldTime)
        if self.m_coldTime <= 0 then
--倒计时结束
            self:udapteAutoBattleUI(true);
            self:updateAutoData(true)
            self._CountDown:setVisible(false)            
            LGameMsg.m_baseMsgWithOne:Change(LBattleEvent.AutoBattle, 1)
            self:SendMsg(LGameMsg.m_baseMsgWithOne)
            self:UnRoundSchedule()
        end
	end
    self:UnRoundSchedule()
    if self.m_coldTime > 0 then
        self._CountDown:setString(self.m_coldTime)
        local scheduler =  AppDef.Director:getScheduler()
        self.m_schedulerID = scheduler:scheduleScriptFunc(UpdateCD, 1, false)
        self._inCDTime = true
        self._CountDown:setVisible(true)
    end
end

function BattleUI:UnRoundSchedule()
    if self.m_schedulerID then
        AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_schedulerID)
        self.m_schedulerID = nil
    end
end

function BattleUI:IsListContainId(id)
    -- body
    for i = 1, #self._alreadyAddBtn do
        if self._alreadyAddBtn[i] == id then
            return true
        end
    end
    return false
end

function BattleUI:CheckAndAddButton(id, item, index, pic, callback)
    if item == nil then
        return index
    end

    if self:IsListContainId(id) then
        return index
    end

    if id > 0 then
        local isOpen = LDataConstMgr:isModuleDefaultShow(id) or (not Utils:CheckModelNotOpened(id, true))
        if not isOpen then
           return index 
        end
    end
    local btn = item:getChildByName("btn_"..index)
    if btn == nil then
        return index
    end
    
    btn:setVisible(true)
    if pic and type(pic) == "string" and #pic > 0 then
        btn:loadTextureNormal(pic, UI_TEX_TYPE_PLIST)
    end
    btn:setTag(id)
    btn:getChildByName("Text"):setVisible(false)
    
    local prompt = btn:getChildByName("Prompt")
--红点
    LRedDotCheckMgr:addBattleMenuPrompt(id, prompt)
    prompt:setVisible(false)
    table.insert(self._alreadyAddBtn, id)

    callback = callback or handler(self, BattleUI.LeftButtonClick)
    --[[
    本来就不显示战斗快捷按钮了，先注释掉，
    每一次战斗都要加一个事件，加太多会溢出闪退
    ]]
    btn:addClickEventListener(callback)
	self:MarkIntaractCObj(btn)
    -- if id == AppDef.EModuleID.EMID_DUANZAO then
    --     LRedDotCheckMgr:MainDuanzaoCheck()
    -- end

    return (index+1)
end

function BattleUI:LeftButtonClick(sender)
    if sender == nil then
        return
    end
    local functionId = sender:getTag()
    if functionId <= 0 then
        return
    end
    Utils:OpenFunction(functionId, false, false, true)
end

function BattleUI:CheckAllPromptInBattle( ... )
    -- body
    if LRedDotCheckMgr:CheckBattleAllPrompt() then
        self._btnLockerRed:setVisible(true)
    else
        self._btnLockerRed:setVisible(false)
    end
end

function BattleUI:addMenu()
--    self._listView:removeAllItems()

    --------------------------------------------------------------
    local maxColumn = self._pCell:getChildrenCount()
    local path = "res/UI/Icon/ui_main_icon/"
    local list = {}
    --------------------------------------------------------------
    --技能
    table.insert(list, {fid=AppDef.EModuleID.EMID_JINENG, pic=path.."ui_main_icon_jineng.png"})
    --神器
    table.insert(list, {fid=AppDef.EModuleID.EMID_SHENQI, pic=path.."ui_main_icon_shenqi.png"})
    --神将
    table.insert(list, {fid=AppDef.EModuleID.EMID_SHENJIANG, pic=path.."ui_main_icon_shenjiang.png"})
    --背包
    table.insert(list, {fid=AppDef.EModuleID.EMID_BEIBAO, pic=path.."ui_main_icon_baoguo.png"})
    --坐骑
    table.insert(list, {fid=AppDef.EModuleID.EMID_ZUOJI, pic=path.."ui_main_icon_zuoqi.png"})
    --羽翼
    table.insert(list, {fid=AppDef.EModuleID.EMID_YUYI, pic=path.."ui_main_icon_yuyi.png"})
        --锻造
    table.insert(list, {fid=AppDef.EModuleID.EMID_DUANZAO, pic=path.."ui_main_icon_duanzao.png"})
    --抽卡
    -- table.insert(list, {fid=AppDef.EModuleID.EMID_CHOUKA, pic=path.."ui_main_icon_chouka.png"})
    --目标
    table.insert(list, {fid=AppDef.EModuleID.EMID_MUBIAO, pic=path.."ui_main_icon_doushenzhilu.png"})
    --商城
    table.insert(list, {fid=AppDef.EModuleID.EMID_SCCHANGYONG, pic=path.."ui_main_icon_shangcheng.png"})
    --活动
    table.insert(list, {fid=AppDef.EModuleID.EMID_HUODONG, pic=path.."ui_main_icon_huodong.png"})
    -- --福利
    -- table.insert(list, {fid=AppDef.EModuleID.EMID_FULI, pic=path.."ui_main_icon_fuli.png"})
    --副本
    table.insert(list, {fid=AppDef.EModuleID.EMID_FUBEN, pic=path.."ui_main_icon_fuben.png"})
    --玩法
    table.insert(list, {fid=AppDef.EModuleID.EMID_WANFA, pic=path.."ui_main_icon_wanfa.png"})
    --排行榜
    table.insert(list, {fid=AppDef.EModuleID.EMID_PAIHANGBANG, pic=path.."ui_main_icon_paihangbang.png"})
    --帮派
    table.insert(list, {fid=AppDef.EModuleID.EMID_BANGPAI, pic=path.."ui_main_icon_bangpai.png"})
    --设置
    table.insert(list, {fid=AppDef.EModuleID.EMID_SHEZHI, pic=path.."ui_main_icon_shezhi.png"})
    --境界
     table.insert(list, {fid=AppDef.EModuleID.EMID_JINGJIE, pic=path.."ui_main_icon_shezhi.png"})--图片
   
    --------------------------------------------------------------
    local index = self:getLastListViewIndex()
    local item = nil
    local  isAlreadyAdd = false
    if index > 1 then
        item = self:getLastListViewItem()
        isAlreadyAdd = true
    end
    for i=1,#list do
        if index > maxColumn then
            if not isAlreadyAdd then
                local _ = item and self._listView:pushBackCustomItem(item)
            end
            item = nil
            index = 1
            isAlreadyAdd = false
        end
        if item == nil then
            item = self._pCell:clone()
        end
        index = self:CheckAndAddButton(list[i].fid, item, index, list[i].pic, list[i].callback)
    end
    --------------------------------------------------------------
    if index > 1 and item then
        for i=index,maxColumn do
            local pBtn = item:getChildByName("btn_"..i)
            if pBtn then
                pBtn:setVisible(false)
            end
        end
        if not isAlreadyAdd then
            self._listView:pushBackCustomItem(item)
        end
    end
    --------------------------------------------------------------
    self:CheckAllPromptInBattle()
end

function BattleUI:getLastListViewItem( ... )
    -- body
    local num = #self._listView:getItems()
    if num <= 0 then
        return nil
    end
    local item = self._listView:getItem(num - 1)
    return item
end

function BattleUI:getLastListViewIndex()
    -- body
    local item = self:getLastListViewItem()
    if item == nil then
        return 1
    end
    
    for i=1,3 do
        local btn1 = item:getChildByName("btn_" .. i)
        if btn1 and not btn1:isVisible() then
            return i
        end
    end
    return 1
end

function BattleUI:SpeedButtonClick(sender)
    local cur = LRoleDataMgr:GetFightSpeed() + 1
    if cur >= AppDef.MAX_FIGHT_SPEED then
        cur = 0
    end
    self:ChangeSpeed(cur)
end

function BattleUI:ChangeSpeed(speed)
    ----------------------------------------------------------------------------
    local function setSpeed(speed)
        -- LuaNetSendMsg:DealMsgSaveSettingInfo(AppDef.ServerSetIndex.SSI_FIGHT_SPEED, speed)
        -- LGameMsg.m_baseMsg:ChangeEventId(LBattleEvent.UpdateSpeed)
        -- self:SendMsg(LGameMsg.m_baseMsg)
        -- self:ChangeSpeedBtn()
        print("ChangeSpeed =====================>", speed)

        LRoleDataMgr:SetFightSpeed(speed)
        -- LuaNetSendMsg:QueryFightSpeed(speed)
    end
    ----------------------------------------------------------------------------
    if speed == 0 then
        setSpeed(speed)
        return
    end
    local canOpen =  (not Utils:CheckModelNotOpened(AppDef.EModuleID["EMID_FIGHT_SPEEDUP_" .. speed], false))
    if canOpen then
        setSpeed(speed)
    else
        setSpeed(0)
    end
    -- ----------------------------------------------------------------------------
    -- local showTips = false
    -- if speed == 1 then
    --     local isDoubleOpened = (not Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_FIGHT_DOUBLE, true))
    --     if isDoubleOpened then
    --         setSpeed(speed)
    --         return
    --     else
    --         showTips = true
    --         speed = AppDef.MAX_FIGHT_SPEED-1
    --     end
    -- end
    -- ----------------------------------------------------------------------------
    -- if speed == (AppDef.MAX_FIGHT_SPEED-1) then
    --     local haveMcCard = LRoleDataMgr.MyHeroInfo.MyVIPInfo.isHasMcCard or
    --     LRoleDataMgr.MyHeroInfo.MyVIPInfo.isHasMcCardTemp or LRoleDataMgr.MyHeroInfo.MyVIPInfo.isHasLmCard
    --     if haveMcCard then
    --         setSpeed(speed)
    --     else
    --         if showTips then
    --             Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_FIGHT_DOUBLE)
    --         end
    --         setSpeed(0)
    --     end
    -- end
    -- ----------------------------------------------------------------------------
end

function BattleUI:ChangeSpeedBtn()
    if self.m_btnSpeed == nil then
        return
    end
  
    local cur = LRoleDataMgr:GetFightSpeed()
      
    -- if cur==1 then     
    --    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_FIGHT_DOUBLE, true) then
    --       cur=cur-1
    --       self:ChangeSpeed(cur)
    --    end
    -- end
   
    -- if cur==2 then
    --     if  LRoleDataMgr.MyHeroInfo.MyVIPInfo.mcType == 1 or
    --     LRoleDataMgr.MyHeroInfo.MyVIPInfo.mcType==8 or LRoleDataMgr.MyHeroInfo.MyVIPInfo.mcType
    --     >8 then     
    --     else
    --         cur=cur-1
    --         self:ChangeSpeed(cur)
          
    --     end
    -- end
    local arr = {1,2,3,5,10,15}
    local pXText = self.m_btnSpeed:getChildByName("X1")
    pXText:setString("X"..arr[cur + 1])
    -- for i=1,AppDef.MAX_FIGHT_SPEED do
    --     local pXText = self.m_btnSpeed:getChildByName("X"..arr[i])
    --     if pXText then
    --         pXText:setVisible((i-1) == cur)
    --     end
    -- end
end

return BattleUI