local TimerLabelUI = require("View.Common.TimerLabelUI")
local RoleHeadScript = require("View.Role.RoleHeadNode")
local WorldBossMainUI = LUIBase:New()
WorldBossMainUI.__index = WorldBossMainUI
WorldBossMainUI.IsHideInBattle = true
function WorldBossMainUI:New()
    local o = LUIBase:New()
    setmetatable(o,WorldBossMainUI) 
    o:Init()
    return o
end

function WorldBossMainUI:Init()
    self.Script = "WanFa.WorldBossMainUI"
    self:CreateUINode("csd/shijieboss/WorldBoss.csb")
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:InitData()
    self:initControlUI()
    self:OnRankTabChange(self.m_checkBox1,ccui.CheckBoxEventType.selected)
    self:ShowBgMoney(1)
    self:ShowMyRoleModel()
    --测试代码
    --查询数据(世界Boss数据返回后再查询)
    LuaNetSendMsg:QueryRankList(3)--排行榜数据
    local data = LActivityManager:GetWorldBossData()
    data:InitData()
    self:ShowRankList()
    self:ShowMyRank()
    self:UpdateTimer()
    self:ShowBoss()
    self:ShowCnt()
end

--[[
注册UI消息
]]
function WorldBossMainUI:RegistMsgs()
    self.msgIds = 
    {
        LUIRoleDataChangeEvent.MoneyChanged,
        LUIRoleDataChangeEvent.TongBaoChanged, 
        LUIRoleDataChangeEvent.TiliChanged,
        LUIRankEvent.RankListInfo,
    }
    self:RegistSelf(self,self.msgIds)
end

function WorldBossMainUI:ProcessEvent(msg)
    if msg.msgId == LUIRoleDataChangeEvent.MoneyChanged 
        or msg.msgId == LUIRoleDataChangeEvent.TongBaoChanged 
        or msg.msgId == LUIRoleDataChangeEvent.TiliChanged then
        self:ShowBgMoney()
    elseif msg.msgId == LUIRankEvent.RankListInfo then
        if msg.value == 3 then
            self:ShowOtherRoleModel()
        end
    end
end

function WorldBossMainUI:InitData()
    self.m_rankCells = {}
    self.m_chooseIdx = 0
    self.m_rankInd = 1

	local helpBtn = self.m_pUILayer:getChildByName("Title"):getChildByName("TitleName"):getChildByName("btn_help")
    helpBtn:addClickEventListener(function ( sender )
        self:HelpClicked()
    end)
end

function WorldBossMainUI:HelpClicked(sender) 
    Utils:ShowDialogOKCancel(GUITips.WorldBoss)
end

function WorldBossMainUI:initControlUI()
    self.m_pUILayer:getChildByName("Bg"):setTouchEnabled(true)
    self.m_closeBtn = self.m_pUILayer:findChildByName("Title/CloseBtn")
    self.m_closeBtn:addClickEventListener(handler(self,WorldBossMainUI.RemoveUI))

    self.m_fightBtn = self.m_pUILayer:getChildByName("Btn_tiaozhan")--挑战按钮
    self.m_fightBtn:addClickEventListener(handler(self,WorldBossMainUI.FightCallBack))
    self.m_cdLabel = self.m_fightBtn:getChildByName("lengque")
    self.m_cdLabel:setString("")
    self.m_cntLabel = self.m_fightBtn:getChildByName("cishu")
    self.m_fightBtn:setLocalZOrder(999)

    self.m_rewardBtn = self.m_pUILayer:getChildByName("Btn_yulan")--奖励按钮
    self.m_rewardBtn:addClickEventListener(handler(self,WorldBossMainUI.RewardCallBack))

    self.m_timePanel = self.m_pUILayer:getChildByName("Panel_Top")
    self.m_timeDes = self.m_timePanel:getChildByName("Reset")
    self.m_timeLabel = self.m_timePanel:getChildByName("Value")--剩余时间
    self.m_timeLabel:setString("")
    --self.m_Timer = TimerLabelUI:New(timeLabel, 0,nil,handler(self,WorldBossMainUI.OnTimerEnd),false)
    --self.m_Timer:start()
    self.m_bossNode = self.m_pUILayer:getChildByName("Node")--Boss显示节点

    --Boss头像
    local headPanel = self.m_pUILayer:getChildByName("Head")
    self.m_bossNameLabel = headPanel:getChildByName("Name")
    self.m_bossImg = headPanel:getChildByName("Icon")

    --BossHp
    self.m_hpLabel = headPanel:getChildByName("Text")
    self.m_hpBar = headPanel:getChildByName("LoadingBar")

    --排行榜
    local rankPanel = self.m_pUILayer:getChildByName("Ranking")
    rankPanel:setLocalZOrder(990)
    self.m_checkBox1 = rankPanel:getChildByName("CheckBox_Guild")
    self.m_checkBox1.userObject = 1
    self.m_checkBox2 = rankPanel:getChildByName("CheckBox_geren")
    self.m_checkBox2.userObject = 2
    self.m_checkBox1:addEventListener(handler(self,WorldBossMainUI.OnRankTabChange))
    self.m_checkBox2:addEventListener(handler(self,WorldBossMainUI.OnRankTabChange))

    self.m_listView = rankPanel:getChildByName("ListView")
    self.m_cell = rankPanel:getChildByName("Item")
    self.m_cell:retain()
    self.m_cell:removeFromParent()
    local myRankPanel = rankPanel:getChildByName("Own")
    self.m_myRankLabel = myRankPanel:getChildByName("PlaceNum")
    self.m_myNameLabel = myRankPanel:getChildByName("PlaceName")
    self.m_myHurtLabel = myRankPanel:getChildByName("HurtValue")

    --右上，金钱
    local moneyPanel = self.m_pUILayer:getChildByName("GoldCheck")
	moneyPanel:setTouchEnabled(false)
    local money1 = moneyPanel:getChildByName("GoldIcon1")
    self.m_tiliImg = money1:getChildByName("Icon")--体力
    self.m_tiliLabel = money1:getChildByName("GoldNumBg"):getChildByName("Num")
    local tiliAddBtn = money1:getChildByName("AddBtn")
    tiliAddBtn:addClickEventListener(function ( sender )
        Utils:OpenUseUI(500,1)
    end)
    local money2 = moneyPanel:getChildByName("GoldIcon3")
    self.m_goldImg = money2:getChildByName("Icon")--金币
    self.m_goldLabel = money2:getChildByName("GoldNumBg"):getChildByName("Num")
    local goldAddBtn = money2:getChildByName("AddBtn")
    goldAddBtn:addClickEventListener(function ( sender )
        Utils:OpenFunction(AppDef.EModuleID.EMID_SCCHANGYONG)
    end)
    local money3 = moneyPanel:getChildByName("GoldIcon4")
    self.m_cashImg = money3:getChildByName("Icon")--元宝
    self.m_cashLabel = money3:getChildByName("GoldNumBg"):getChildByName("Num")
    local cashAddBtn = money3:getChildByName("AddBtn")
    cashAddBtn:setVisible(false)
end

function WorldBossMainUI:ShowBgMoney(init)
    init = init or 0
    local value1 = Utils:getTiliStr(LRoleDataMgr.MyHeroInfo.DetailData:getTili())
    if self.m_tiliLabel ~= nil then
        self.m_tiliLabel:setString(value1)
    end
    local value2 = Utils:getGoldStr()
    self.m_goldLabel:setString(""..value2)
    local value3 =  LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao()
    self.m_cashLabel:setString(""..value3)
    --print("showmoney",value1,value2,value3)
    if init == 1 then
        local imgPath1 = "res/UI/Icon/ui_huobi_icon/huobi_"..LRoleDataMgr.GetItemPicId(AppDef.SpecialItemId.Tili)..".png"
        Utils:SafeLoadTexture(self.m_tiliImg,imgPath1,ccui.TextureResType.plistType)
        local imgPath2 = "res/UI/Icon/ui_huobi_icon/huobi_"..LRoleDataMgr.GetItemPicId(AppDef.SpecialItemId.Gold)..".png"
        Utils:SafeLoadTexture(self.m_goldImg,imgPath2,ccui.TextureResType.plistType)
        local imgPath3 = "res/UI/Icon/ui_huobi_icon/huobi_"..LRoleDataMgr.GetItemPicId(AppDef.SpecialItemId.Cash)..".png"
        Utils:SafeLoadTexture(self.m_cashImg,imgPath3,ccui.TextureResType.plistType)
    end
end

--活动倒计时
function WorldBossMainUI:UpdateTimer()
    local data = LActivityManager:GetWorldBossData()
    if data.m_sec == 0 then
        self:OnTimerEnd()
        return
    end
    self.m_timeDes:setString(GUITips.RSI_WANFA_TIPS2.."：")
    if self.m_secTimer == nil then
        self.m_secTimer = TimerLabelUI:New(self.m_timeLabel,data.m_sec,handler(self,WorldBossMainUI.OnTimerEnd),handler(self,WorldBossMainUI.OnTimerUpdate),false,0)
    end
    self.m_secTimer:start()
end

function WorldBossMainUI:OnTimerUpdate(label,h,m,s,leftTime)
    self.m_sec = leftTime
    label:setString(string.format("%02d:%02d:%02d", h, m, s))
    self:ShowBossHp(leftTime)
end

function WorldBossMainUI:OnTimerEnd()
    self.m_timeDes:setString(GUITips.RSL_AY_MSG2.."：")
    local str = ""
    local cfg = JsonConfig.m_functionConfig.getDefByID(AppDef.EModuleID.EMID_WORLDBOSS)
    if cfg ~= nil and cfg.start_time > 0 then
        str = str .. string.format("%02d:%02d",math.floor(cfg.start_time/100),cfg.start_time%100).."-"
        str = str .. string.format("%02d:%02d",math.floor(cfg.end_time/100),cfg.end_time%100)
    end
    self.m_timeLabel:setString(str)
end

function WorldBossMainUI:StartCdTime()
    self.m_fightBtn:setEnabled(false)
    if self.m_cdTimer == nil then
        self.m_cdTimer = TimerLabelUI:New(self.m_cdLabel,10,handler(self,WorldBossMainUI.OnCdTimerEnd),nil,false,0)
    end
    self.m_cdTimer:start()
end

function WorldBossMainUI:OnCdTimerEnd()
    self.m_cdLabel:setString("")
    self.m_fightBtn:setEnabled(true)
end

function WorldBossMainUI:ShowCnt()
    local data = LActivityManager:GetWorldBossData()
    if data.m_cnt == nil then
        return
    end
    self.m_cntLabel:setString(GUITips.RSI_WANFA_TIPS3.."："..data.m_cnt)
end

function WorldBossMainUI:ShowBossHp(sec)
    local max = 2*3600
    self.m_maxSec =  self.m_maxSec or max
    local cur = sec or self.m_maxSec
    local percent = math.floor(cur*100/self.m_maxSec)
    if percent == 0 and cur > 0 then
        percent = 1
    end
    self.m_hpBar:setPercent(percent)
    self.m_hpLabel:setString(""..percent.."%")
end

function WorldBossMainUI:ShowRankList()
    local data = LActivityManager:GetWorldBossData()
    local info = data.m_leftRanks
    if self.m_rankInd == 2 then
        info = data.m_rightRanks
    end
    if info == nil then
        return
    end
    for i=1,#info do
        local value = info[i]
        if self.m_rankCells[i] == nil then
            self.m_rankCells[i] = self.m_cell:clone()
            self.m_rankCells[i].userObject = i
            --self.m_rankCells[i]:addTouchEventListener(handler(self,WorldBossMainUI.OnRankCellTouch))
            self.m_listView:pushBackCustomItem(self.m_rankCells[i])
        end
        self:ShowOneRank(self.m_rankCells[i],value)
    end
    for i=#info+1,#self.m_rankCells do
        self.m_listView:removeChild(self.m_rankCells[i], true)
        self.m_rankCells[i] = nil
    end
end

function WorldBossMainUI:ShowOneRank(sender,data)
    local idx = sender.userObject
    local rankLabel = sender:getChildByName("PlaceNum")
    local nameLabel = sender:getChildByName("PlaceName")
    local hurtLabel = sender:getChildByName("HurtValue")
    local chooseImg = sender:getChildByName("ChooseBg")
    rankLabel:setString(data.rank)
    nameLabel:setString(data.name)
    hurtLabel:setString(Utils:getPowerStr(data.sorce))
    if chooseImg ~= nil then 
        -- if self.m_chooseIdx > 0 and self.m_chooseIdx == idx then
        --     chooseImg:setVisible(true)
        -- else
            chooseImg:setVisible(false)
        --end
    end
end

function WorldBossMainUI:ShowMyRank()
    local data = LActivityManager:GetWorldBossData()
    local hurt = data.m_hurts[self.m_rankInd]
    self.m_myHurtLabel:setString(Utils:getPowerStr(hurt))
    self.m_myNameLabel:setString(LRoleDataMgr.MyHeroInfo.name)
    local myRank = data.m_myRanks[self.m_rankInd]
    local str = GUITips.Common_None
    if myRank ~= nil and myRank > 0 then
        str = ""..myRank
    end
    self.m_myRankLabel:setString(str)
end

function WorldBossMainUI:UpdateBossHp()

end

function WorldBossMainUI:ShowBoss()
    local data = LActivityManager:GetWorldBossData()
    if data.m_bossInfo == nil or data.m_bossInfo.id == nil or data.m_bossInfo.id == 0 then
        return
    end
    --模型
    if self.m_bossModel == nil then
        self.m_bossModel = Utils:CreateAnimModel(AppDef.AwrdItem.AWRD_ITEM_MONSTER, data.m_bossInfo.id, self.m_bossModel)
        self.m_bossNode:addChild(self.m_bossModel)
        self.m_bossModel:setScale(1.6)
    end
    self.m_bossModel:PlayStand(3)
    --头像
    local cfg = LDataConstMgr:GetMonsterData(data.m_bossInfo.id)
    if cfg == nil then
        return
    end
    self.m_bossNameLabel:setString(cfg.name)
    self.m_bossNameLabel:setColor(AppDef:GetQualityColor(cfg.quality))
    local imgPath = "res2/Monster_Bust/" .. cfg.pic .. "_tou.png"
    Utils:SafeLoadTexture(self.m_bossImg,imgPath,ccui.TextureResType.localType)

    local cfgData = JsonConfig.m_functionConfig.getDefByID(AppDef.EModuleID.EMID_WORLDBOSS)
    if cfgData ~= nil and cfgData.start_time > 0 then
        local startHour = math.floor(cfgData.start_time/100)
        local starMin = cfgData.start_time%100
        local endHour = math.floor(cfgData.end_time/100)
        local endMin = cfgData.end_time%100
        local hour = endHour - startHour
        local min = endMin - starMin
        if hour < 0 then hour = 0 end
        if min < 0 then min = 0 end
        self.m_maxSec = hour*3600+min*60
    end
end

function WorldBossMainUI:ShowOtherRoleModel()
    local rankData = LRankDataMgr.m_ranks[3]
    if rankData == nil or #rankData == 0 then
        return
    end
    if self.m_otherRoles == nil then
        self.m_otherRoles = {}
    end
    local min = math.min(5,#rankData)
    local max = math.min(20,#rankData)
    local num = math.random(min,max)
    local ranks = {}
    for i=1,#rankData do
        ranks[i] = i 
    end
    for i=1,num do
        local idx = math.random(1,#ranks)
        if rankData[ranks[idx]].Id ~= LRoleDataMgr.MyHeroInfo.id then
            table.insert(self.m_otherRoles,rankData[ranks[idx]])
        end
        table.remove(ranks,idx)
    end
    for i=1,#self.m_otherRoles do
        local data = self.m_otherRoles[i]
        local x = math.random(15,60)/100*AppDef.frameSize.width
        local y = math.random(10,40)/100*AppDef.frameSize.height
        local node = cc.Node:create()
        node:setName("Other_"..i)
        self.m_pUILayer:addChild(node)
        node:setPosition(cc.p(x,y))
        local model = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, data.head, 0,0,0,0,0)
        node:addChild(model)
        local face = math.random(0,7)
        model:PlayStand(face)
        local nameNode = RoleHeadScript:New(data)
        node:addChild(nameNode.m_pNode)
        --nameLabel:setAnchorPoint(cc.p(0.5,0.5))
        nameNode:SetPosition(cc.p(0,150))
    end
end

function WorldBossMainUI:ShowMyRoleModel()
    if self.m_myNode == nil then
        self.m_myNode = cc.Node:create()
        self.m_pUILayer:addChild(self.m_myNode)
        self.m_myNode:setLocalZOrder(998)
    end
    if self.m_myModel == nil then
        local bodyId = LRoleDataMgr.MyHeroInfo:GetModel()
        self.m_myModel = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, bodyId, 0,0,0,0,0)
        self.m_myNode:addChild(self.m_myModel)
        local value = {}
        value.Id = LRoleDataMgr.MyHeroInfo.id
        value.name = LRoleDataMgr.MyHeroInfo.name
        value.jingjie = LRoleDataMgr.MyHeroInfo.jingJieOtherInfo.curId
        local nameNode = RoleHeadScript:New(value)
        self.m_myNode:addChild(nameNode.m_pNode)
        nameNode:SetPosition(cc.p(0,150))
    end
    self.m_myNode:setPosition(cc.p(AppDef.frameSize.width*0.3,self.m_bossNode:getPositionY()))
    self.m_myModel:PlayStand(0)
end

function WorldBossMainUI:FightCallBack()
    local data = LActivityManager:GetWorldBossData()
    if data.m_cnt == nil or data.m_cnt < 1 then
        Utils:ShowScrollTips(GUITips.RSI_FENGSHEN_TIPS1)
        return
    end
    if data.m_sec < 1 then
        Utils:ShowScrollTips(self.m_timeDes:getString())
        return
    end
    self:MyRoleMove()
end

function WorldBossMainUI:RewardCallBack()
    Utils:InitUI("WanFa.RankRewardUI",AppDef.UIType.SecondClassLayer)
end

-- function WorldBossMainUI:OnRankCellTouch(sender, event)
--     if event == ccui.TouchEventType.began then
--         self.m_idx = sender.userObject
--         local touchBeginPosTemp = sender:getTouchBeganPosition()
--         self.m_touchBeginPos = self.m_listView:convertToWorldSpace(cc.p(touchBeginPosTemp.x, touchBeginPosTemp.y))
--     elseif event == ccui.TouchEventType.ended then
--         if self.m_idx ~= sender.userObject then
--             return
--         end
--         local touchEndPosTemp = sender:getTouchEndPosition()
--         local touchEndPos = self.m_listView:convertToWorldSpace(cc.p(touchEndPosTemp.x, touchEndPosTemp.y))
--         local distance = math.sqrt(math.pow(touchEndPos.x - self.m_touchBeginPos.x, 2) + math.pow(touchEndPos.y - self.m_touchBeginPos.y, 2))
--         if distance < 10 then
--             self.m_chooseIdx = self.m_idx
--             self:ShowRankList()
--         end
--     end
-- end

function WorldBossMainUI:OnRankTabChange(sender,evnetType)
    if evnetType == ccui.CheckBoxEventType.selected then
        self.m_rankInd = sender.userObject
        if self.m_rankInd ==  1 then
            self.m_checkBox1:setTouchEnabled(false)
            self.m_checkBox2:setTouchEnabled(true)
            self.m_checkBox2:setSelected(false)
        else
            self.m_checkBox2:setTouchEnabled(false)
            self.m_checkBox1:setTouchEnabled(true)
            self.m_checkBox1:setSelected(false)
        end
        self:ShowRankList()
        self:ShowMyRank()
    end
end

function WorldBossMainUI:MyRoleMove()
    local pos = cc.p(self.m_myNode:getPosition())
    local targetPos = cc.p(self.m_bossNode:getPosition())
    local face = 7
    self.m_myModel:PlayRun(face)
    local moveAc = cc.MoveTo:create(2, targetPos)

    local moveEnd = cc.CallFunc:create(function()
        self.m_myModel:PlayStand(0)
        --进入战斗
    end)
    self.m_myNode:runAction(cc.Sequence:create(moveAc, moveEnd))
end

function WorldBossMainUI:UpdateUserData()
    self:ShowMyRoleModel()
end

function WorldBossMainUI:onExit()
    if self.m_cdTimer ~= nil then
        self.m_cdTimer:Destory()
    end
    if self.m_secTimer~= nil then
        self.m_secTimer:Destory()
    end
    self.m_cdTimer = nil
    self.m_secTimer = nil
    self:Destory()
    self.m_pUILayer = nil
    self.Script  = nil
    self.m_rankCells = nil
    self.m_chooseIdx = nil
    self.m_rankInd = nil
    LActivityManager:WorldBossFree()
end

return WorldBossMainUI