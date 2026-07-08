local WelfareActivityDef = require("View.WelfareActivity.WelfareActivityDef")
local ShopDef = require("View.Shop.ShopDef")

LRedDotCheckMgr = LUIBase:New()
LRedDotCheckMgr.__index = LRedDotCheckMgr
function LRedDotCheckMgr:New()
    local o = LUIBase:New()
    setmetatable(o, self)
    self.__index = self
    o:Init()
    return o
end

function LRedDotCheckMgr:Init()
    self.mainUIType = 
    {
        --btn_jingji      = {handler(self, LRedDotCheckMgr.MainArenaCheck), nil, false},
        btn_paihangbang = {handler(self, LRedDotCheckMgr.MainRankCheck), nil, false},
        btn_mubiao      = {handler(self, LRedDotCheckMgr.MainMubiaoCheck), nil, false},
        btn_shouchong   = {handler(self, LRedDotCheckMgr.MainShouchongCheck), nil, false},
        btn_zhekou      = {handler(self, LRedDotCheckMgr.MainZhekouCheck), nil, false},
        btn_huodong     = {handler(self, LRedDotCheckMgr.MainHuodongCheck), nil, false},
        -- btn_fuli        = {handler(self, LRedDotCheckMgr.MainWelfareCheck), nil, false},
        btn_jineng      = {handler(self, LRedDotCheckMgr.MainSkillCheck), nil, false},
        btn_chouka      = {handler(self, LRedDotCheckMgr.MainCardCheck), nil, false},
        btn_zuoqi       = {handler(self, LRedDotCheckMgr.MainMountCheck), nil, false},
        --btn_duanzao     = {handler(self, LRedDotCheckMgr.MainDuanzaoCheck), nil, false},
        -- btn_bangpai     = {handler(self, LRedDotCheckMgr.MainGuildCheck), nil, false},
        btn_shenqi      = {handler(self, LRedDotCheckMgr.MainArtifactCheck), nil, false},
        btn_yuyi        = {handler(self, LRedDotCheckMgr.MainWingCheck), nil, false},
        btn_xitong      = {handler(self, LRedDotCheckMgr.MainSettingCheck), nil, false},
        locker          = {handler(self, LRedDotCheckMgr.MainChangeCheck), nil, false},
        btn_Bag         = {handler(self, LRedDotCheckMgr.MainBagCheck), nil, false},
        btn_wanfa       = {handler(self, LRedDotCheckMgr.WanFaRedDotCheck), nil, false},--{handler(self, LRedDotCheckMgr.MainActivityCheck), nil, false},
        btn_social      = {handler{self, LRedDotCheckMgr.SocialCheck}, nil, false},
        btn_jijin       = {handler{self, LRedDotCheckMgr.FundRebateCheck}, nil, false},
        -- btn_jijin2       = {handler{self, LRedDotCheckMgr.HuoYueJiJinCheck}, nil, false},
        btn_jingjie     = {handler{self, LRedDotCheckMgr.MianJingJieCheck}, nil, false},
        --btn_Activity    = {nil, nil, false},
        btn_bangpai = {handler{self, LRedDotCheckMgr.BangpaiCheck}, nil, false},
        btn_zhuangbei   = {handler{self, LRedDotCheckMgr.PetEquipAllRedCheck}, nil, false},
        btn_friend   = {handler{self, LRedDotCheckMgr.FriendRedCheck}, nil, false},
        btn_mail   = {handler{self, LRedDotCheckMgr.MailRedCheck}, nil, false},
		btn_huishou = {handler{self, LRedDotCheckMgr.HuiShouCheck}, nil, false},
        btn_chat      = {handler{self, LRedDotCheckMgr.ChatCheck}, nil, false},--私聊

        btn_zhenrong = {handler{self, LRedDotCheckMgr.ZhenRongCheck}, nil, false}, --阵容
        -----------------------------------------------------------------------------------------------------------
        --卡牌新加
        btn_shenjiangbeibao = {handler{self, LRedDotCheckMgr.PetBagRedCheck}, nil, false},

        ------------------------------------------------------------------------------------------
        btn_Qiri = {handler{self, LRedDotCheckMgr.QiriRedCheck}, nil, false},

        btn_fuben = {handler{self, LRedDotCheckMgr.MainFuBenCheck}, nil, false},
        btn_renwu = {handler{self, LRedDotCheckMgr.DaliyTaskCheck}, nil, false},
	    -----------------------------------------------------------------------------------------
        btn_arena_reward = {nil, nil, false},
        btn_arena_report = {nil, nil, false},
        -----------------------------------------------------------------------------------------
        btn_equip = {handler{self, LRedDotCheckMgr.PetEquipRedCheck}, nil, false},
        btn_equip_sui = {handler{self, LRedDotCheckMgr.PetEquipPiecesRedCheck}, nil, false},
        --btn_xunbao = {handler{self,LRedDotCheckMgr.XunBaoRedCheck}, nil, false},
        btn_xunbao_task = {nil, nil, false},
        btn_xunbao_hecheng = {handler{self,LRedDotCheckMgr.FaBaoHeChengRedCheck}, nil, false},
		btn_chuandai = {nil, nil, false},
		btn_fabao = {nil, nil, false},
        -------------------------------------------------------------------------------------------
        btn_shangcheng = {handler{self, LRedDotCheckMgr.MainShopCheck}, nil, false},
        btn_jianghun = {handler{self, LRedDotCheckMgr.JiangHunShopCheck}, nil, false},
        btn_wanfaShop = {handler{self, LRedDotCheckMgr.WanFaShopCheck}, nil, false},
    }

    self.m_dzRedDotData = {}--锻造红点数据
    self.lockerSelect = true
    self.cardCd = 99999
    self.onlineCd = 99999
    self._canAutoCheck = false
    self._mailCD = 10;--邮件60秒检测一次

    self:OnSecondTimer()
    self:RegistMsgs()
   -- self:MianJingJieCheck()
    --战斗内面板的小红点
    self.BattleMenuPrompt = {}
end

function LRedDotCheckMgr:onExit()
    self:UnRegistSelf(self, self.msgIds)
    self.m_pUILayer = nil
    self.msgIds = {}
end

function LRedDotCheckMgr:RegistMsgs()
    self.msgIds =
    {
        LUILogicEvent.RedDotState,
        LUILogicEvent.RedDotCheck,
        LUILogicEvent.RedDotItemCheck,
        LUILogicEvent.RedDotMoneyCheck,
        LUILogicEvent.RedDotLevelCheck,
        LUILogicEvent.RedDotStateUpdate,
        LUIFunctionEvent.FunctionOpen,
        LUIRedDotEvent.UpdateRedDotState,
        -- LUIRoleDataChangeEvent.LvUp,
        LUIFundRebateEvent.LoadDataEvent,
        LUIFundRebateEvent.paymentSuccess,
        LUITaskDataEvent.GotTaskInfo,
        LUIPetEvent.PetEquipAdd,
        LUIBangPaiEvent.ReloadFactionActivityList,
        LUIBangPaiEvent.FlushFactionActivity,
        LUIHuoyueLayerEvent.LoadDataEvent,
        LUIPetEvent.GotPetEquip,
        LUIMainEvent.StartAutoUseItemCheck,
        LUIMapEvent.ChangeMapSuccess,
        LUITaskDataEvent.WanFaDailyTaskInfo,
        LUIRoleDataChangeEvent.ArenaSorceChanged,
        LUIRoleDataChangeEvent.XinXiuJingHuaChanged,
		LUIFaBaoEvent.UpdateFaBaoSuc,
    }
    self:RegistSelf(self, self.msgIds)

end

function LRedDotCheckMgr:ProcessEvent(msg)
    if msg.msgId == LUIMapEvent.ChangeMapSuccess then
        self._canAutoCheck = true
    elseif msg.msgId == LUILogicEvent.RedDotState then -- 只需要判断一个条件的 可以直接修改
        local btnName = msg.value[1]
        local value  = self.mainUIType[btnName]
        if value ~= nil and not value[3] then -- 已经显示了 不需要重复判断
            value[3] = msg.value[2]
            self:RedDotShow(value)
        end
    elseif msg.msgId == LUILogicEvent.RedDotStateUpdate then
        self:DotStateUpdateFromServer(msg.value)
    elseif msg.msgId == LUILogicEvent.RedDotCheck then -- 需要判断多个条件的 需要在函数里面判断
        local btnName = msg.value
        local value  = self.mainUIType[btnName]
        self:CheckShow(value)
        if btnName == AppDef.RedDotBtnName.Group3Btn1 or
            btnName == AppDef.RedDotBtnName.Group3Btn2 or
            btnName == AppDef.RedDotBtnName.Group3Btn3 or
            btnName == AppDef.RedDotBtnName.Group3Btn4 or
            btnName == AppDef.RedDotBtnName.Group3Btn5 or
            btnName == AppDef.RedDotBtnName.Group3Btn6 or
            btnName == AppDef.RedDotBtnName.Group4Btn1 or
            btnName == AppDef.RedDotBtnName.Group4Btn2 or
            btnName == AppDef.RedDotBtnName.Group1Btn6 or
            btnName == AppDef.RedDotBtnName.Group4Btn3 then
            self:MainChangeCheck()
        end
    elseif msg.msgId == LUILogicEvent.RedDotItemCheck then -- 物品有变化 检查物品相关的红点
        self:MainArtifactCheck()
        self:MainWingCheck()
        --self:MainDuanzaoCheck()
        self:ZhenRongCheck()
        self:MainMountCheck()
        self:MainCardCheck()
        self:MianJingJieCheck()--境界检查
        self:MainChangeCheck()
        self:PetEquipAllRedCheck()
        self:PetBagRedCheck()
		self:FaBaoBeiBaoRedDotCheck()
		self:EquipZhenRongRedDotCheck()
    elseif msg.msgId == LUILogicEvent.RedDotMoneyCheck then -- 金钱有变化 检查金钱相关的红点
        --self:MainDuanzaoCheck()
        self:ZhenRongCheck()
        self:MainMountCheck()
        self:MainChangeCheck()
        self:MainSkillCheck()
        self:PetEquipRedCheck()
		self:FaBaoBeiBaoRedDotCheck()
		self:EquipZhenRongRedDotCheck()
    elseif msg.msgId == LUILogicEvent.RedDotLevelCheck then -- 等级有变化 检查等级相关的红点
        self:MainSkillCheck()
        self:ZhenRongCheck()
        self:MainCardCheck()
        self:MainChangeCheck()
        self:MainWelfareCheck()
    	--self:MainDuanzaoCheck()
        self:MianJingJieCheck()--境界检查
    elseif msg.msgId == LUIFunctionEvent.FunctionOpen then
        self:FunctionOpen(msg.value)
    elseif msg.msgId == LUIRedDotEvent.UpdateRedDotState then
        self:DealUpdateRedDotState(msg.value)
    -- elseif msg.msgId == LUIRoleDataChangeEvent.LvUp then
    elseif msg.msgId == LUIFundRebateEvent.LoadDataEvent then
        self:FundRebateCheck()
    elseif msg.msgId == LUIFundRebateEvent.paymentSuccess then
    elseif msg.msgId == LUIHuoyueLayerEvent.LoadDataEvent then
        -- self:HuoYueJiJinCheck()
    elseif msg.msgId == LUITaskDataEvent.GotTaskInfo then
        -- local taskId = msg.value
        -- if LRoleDataMgr.Task.taskIdMap[taskId] == nil then
        --     return
        -- end
        -- self:DealMuBiaoTaskData(taskId)
    elseif msg.msgId == LUIPetEvent.PetEquipAdd then
        self:ZhenRongCheck()
	elseif msg.msgId == LUIFaBaoEvent.UpdateFaBaoSuc then
		self:FaBaoBeiBaoRedDotCheck()
		self:EquipZhenRongRedDotCheck()
    elseif msg.msgId == LUIBangPaiEvent.ReloadFactionActivityList then
        self:BangPaiActivityCheck(msg.value)
    elseif msg.msgId == LUIBangPaiEvent.FlushFactionActivity then
        self:BangPaiActivityCheck()
    elseif msg.msgId == LUIPetEvent.GotPetEquip then
        self:PetEquipRedCheck()
    elseif msg.msgId == LUIMainEvent.StartAutoUseItemCheck then
        self:PetEquipPiecesRedCheck()
        self:FaBaoHeChengRedCheck()
    elseif msg.msgId == LUITaskDataEvent.WanFaDailyTaskInfo then
        self:WanFaTaskRedCheck(msg.value)
    elseif msg.msgId == LUIRoleDataChangeEvent.ArenaSorceChanged then
        LuaNetSendMsg:QueryRedDot(RedDotDef.SID.ShopWanFaJingji)
    elseif msg.msgId == LUIRoleDataChangeEvent.XinXiuJingHuaChanged then
        LuaNetSendMsg:QueryRedDot(RedDotDef.SID.ShopWanFaXueZhan)
    end
end

function LRedDotCheckMgr:DotStateUpdateFromServer(data)
    -- print("RedDotDef.SIDMap[data.id] ==>", RedDotDef.SIDMap[data.id], data.isShow, data.id)
    if RedDotDef.SIDMap[data.id] == nil then
        return
    end

    Utils:SetRedDotState(RedDotDef.SIDMap[data.id], data.isShow)
end

function LRedDotCheckMgr:FunctionOpen(value)
    local openFunctions = value[4]
    if openFunctions then
        if Utils:containValue(openFunctions, AppDef.EModuleID.EMID_FUBEN) then
            LuaNetSendMsg:QueryCopy(11)       --副本次数
            LuaNetSendMsg:QueryPetCopyList()       --副本次数
        end
        if Utils:containValue(openFunctions, AppDef.EModuleID.EMID_JINGJI) then
            LuaNetSendMsg:QueryMobaiInfo(1)--请求膜拜雕像信息
            LuaNetSendMsg:QueryMobaiInfo(2)--请求膜拜雕像信息
        end
    end
end

function LRedDotCheckMgr:RedDotItemCheck()
    -- self:MainArtifactCheck()
    self:MainWingCheck()
    --self:MainDuanzaoCheck()
    self:ZhenRongCheck()
    self:MainMountCheck()
    self:MainCardCheck()
    self:MainChangeCheck()
    self:MianJingJieCheck()
    self:PetBagRedCheck()
    self:PetEquipAllRedCheck()
end

function LRedDotCheckMgr:FriendRedCheck()
    return false
end

function LRedDotCheckMgr:MailRedCheck()
    return #LRoleDataMgr.Social.NewMailData > 0
end

function LRedDotCheckMgr:DaliyTaskCheck()
    return false
end

function LRedDotCheckMgr:ChatCheck()
    local v = self.mainUIType.btn_chat
    --local mailDot = self:MailCheck()
    local msgDot = self:msgCheck()

    local show =  msgDot
    ----print("LRedDotCheckMgr:SocialCheck", show)
    v[3] = show
    self:RedDotShow(v)
    local btn = v[2];
    if btn then
        local prompt = btn:getChildByName("Prompt")
        if show == true then
            local rot1 = cc.RotateTo:create(20/60,15);
            local rot2 = cc.RotateTo:create(10/60,0);
            local rot3 = cc.RotateTo:create(10/60,8);
            local rot4 = cc.RotateTo:create(15/60,0);
            local delay = cc.DelayTime:create(25/60);
            local seq = cc.Sequence:create(rot1,rot2,rot3,rot4, delay);
            
            prompt:stopAllActions();
            prompt:runAction(cc.RepeatForever:create(seq));
        else
            prompt:stopAllActions();
        end
    end
    
    return v[3]
end

function LRedDotCheckMgr:HuiShouCheck()
    return false
end

function LRedDotCheckMgr:QiriRedCheck()
    return false
end

function LRedDotCheckMgr:MainFuBenCheck()
    return false
end

function LRedDotCheckMgr:RedDotLevelCheck()
    self:MainSkillCheck()
    self:ZhenRongCheck()
    self:MainCardCheck()
    self:MainChangeCheck()
    self:MainWelfareCheck()
    --self:MainDuanzaoCheck()
end

function LRedDotCheckMgr:RedDotMoneyCheck()
    --self:MainDuanzaoCheck()
    self:MainMountCheck()
    self:MainChangeCheck()
    self:MainSkillCheck()
end

function LRedDotCheckMgr:Delete()
    self.mainUIType = nil
end

function LRedDotCheckMgr:OnSecondTimer()
    local function TimerTick()
        if self.cardCd ~= 0 then
            self.cardCd = self.cardCd - 1

            if self.cardCd == 0 then
                self:MainCardCheck()
            end
        end

        if self.onlineCd > 0 then
            self.onlineCd = self.onlineCd - 1

            if self.onlineCd == 0 then
                self:MainWelfareCheck()
            end
        end
        if self._canAutoCheck then
            self:TickCheck()
        end

    end 
    local scheduler =  AppDef.Director:getScheduler()
    self.scheduler =  scheduler:scheduleScriptFunc(TimerTick, 1, false)
end

--[[
定时请求器
]]
function LRedDotCheckMgr:TickCheck()
    if self._mailCD <= 0 then
        self._mailCD = 60;
        LuaNetSendMsg:QueryRedDot(RedDotDef.SID.MailNew);
    else
        self._mailCD = self._mailCD - 1;
    end
end

function LRedDotCheckMgr:AddCheckBtn(button, btnName)
    --print("AddCheckBtn:",button:getName(),"btnName:",btnName);
    local value  = self.mainUIType[btnName]
    -- dump(value,"value")
    if value == nil then
        --print("=====================LRedDotCheckMgr:RedDotCheck", btnName, value)
        return
    end
    value[2] = button
    button:getChildByName("Prompt"):setVisible(value[3])
end
function LRedDotCheckMgr:CloseCheckBtn(btnName)
    local value  = self.mainUIType[btnName]
    if value == nil then
        --print("=====================LRedDotCheckMgr:RedDotCheck", btnName, value)
        return
    end
     value[2]=nil


    
end


-- 清除注册的按钮 切换账号调用
function LRedDotCheckMgr:ClearAllBtn()
    for k,v in pairs(self.mainUIType) do
        if v~=nil then
            v[2]=nil
        end 
    end
end

function LRedDotCheckMgr:CheckAll()

    --请求开服第几天
    LuaNetSendMsg:QuerySeverOpenTime()

    -- 玩法
    LuaNetSendMsg:QueryDailyActivityList(1)
    LuaNetSendMsg:QueryDailyActivityList(2)

    if not Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_TUJIAN, true) then 
        LuaNetSendMsg:QueryRedDot(RedDotDef.SID.ShenJiangTuJian)--神将图鉴
    end

    -- 福利信息查询
    LuaNetSendMsg:QueryKaifuHuodong(7,3)    --请求等级礼包的奖励
    LuaNetSendMsg:QueryLoginGift(5,1)    --登陆奖励
    LuaNetSendMsg:QueryOnlineAward()
    LuaNetSendMsg:QueryOfflineExpInfo()
    LuaNetSendMsg:QueryDailySignInfo()

    -------------------帮派----------------
    if LRoleDataMgr.Faction.Info.id > 0 then
        -- LuaNetSendMsg:QueryIsExitApply()
        -- LuaNetSendMsg:QueryFactionTaskList()
        -- LuaNetSendMsg:QueryFactionActivityList()
        LuaNetSendMsg:QueryRedDot(RedDotDef.SID.BPSkillUpgrade)
        LuaNetSendMsg:QueryRedDot(RedDotDef.SID.BPShenQing)
        LuaNetSendMsg:QueryRedDot(RedDotDef.SID.BPFubenJiangLi)
    end
    LuaNetSendMsg:QueryRedDot(RedDotDef.SID.FriendGift);
    LuaNetSendMsg:QueryRedDot(RedDotDef.SID.FriendApply);
    LuaNetSendMsg:QueryRedDot(RedDotDef.SID.MailNew);

    LuaNetSendMsg:QueryRedDot(RedDotDef.SID.QiRiActivity)

    LuaNetSendMsg:QueryRedDot(RedDotDef.SID.FuBenAchievement)
    LuaNetSendMsg:QueryRedDot(RedDotDef.SID.FengShengShiLian)
    LuaNetSendMsg:QueryRedDot(RedDotDef.SID.FuBenMap)

    LuaNetSendMsg:QueryRedDot(RedDotDef.SID.Fuli_Tili)
    LuaNetSendMsg:QueryRedDot(RedDotDef.SID.Fuli_ResRecovery)
    LuaNetSendMsg:QueryRedDot(RedDotDef.SID.DaliyTask)

    --神器
    LuaNetSendMsg:QueryShenQiInfoNew(3);
    --首充、次充
    LuaNetSendMsg:QueryKaifuHuodong(9,2)
    LuaNetSendMsg:QueryKaifuHuodong(42,2)
    --资源找回
    LuaNetSendMsg:QueryResRecovery(1)

    --保存商店数据,用于升级快捷购买
    --常规商店
    -- LuaNetSendMsg:QueryMarketInfo(1, 1, nil, nil, true)
    --绑元商店
    -- LuaNetSendMsg:QueryMarketInfo(1, 4, nil, nil, true)

    --成长基金
    -- LuaNetSendMsg:QueryFundRebate(1)
    --活跃基金
    -- LuaNetSendMsg:QueryHuoYueFundRebate(1)

    --七日连冲礼包红点
    -- LuaNetSendMsg:QuerySevenChargeInfo(35, 1)
    --充值送礼红点
    -- LuaNetSendMsg:QueryTotalCost(20, 0)
    --消费送礼红点
    -- LuaNetSendMsg:QueryTotalCost(21, 0)

    -- 请求阶段目标奖励信息
    if (not Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_MUBIAO, true)) then
        LuaNetSendMsg:QueryTaskGiftList()
    end
    --付费预告
    -- LuaNetSendMsg:QueryPetDiscount(3)
    --检测排行榜显示
    LRechargeDataMgr.m_isInitWelfareACData = true
    LuaNetSendMsg:QueryWelFareInfo(0xff, 0)

    --体力
    LuaNetSendMsg:QueryTiLiInfo(1)

    LuaNetSendMsg:QueryHeroBook()

    --抽卡红点检测
    LuaNetSendMsg:SendExtractPetMsg(1)

    --请求法宝数据
    LuaNetSendMsg:SendFaBaoList()

    LuaNetSendMsg:QueryXueZhanInfo(15)

	--请求封神试炼数据
	LuaNetSendMsg:QueryFengshenShiLian()
	
	--昆仑决战请求数据
	LuaNetSendMsg:QuertKunLunData()


    LuaNetSendMsg:QueryRedDot(RedDotDef.SID.ArenaTask)--竞技场任务
    LuaNetSendMsg:QueryRedDot(RedDotDef.SID.XueZhanDraw)--XueZha奖励待领取 
    LuaNetSendMsg:QueryRedDot(RedDotDef.SID.XunBaoTask)--寻宝任务

    --请求将魂商店数据
    LuaNetSendMsg:QueryKaPaiShopUI(1, ShopDef.KP_SP.JIANGHUN)

    local isShow = LUserConfigMgr:GetArenaZbRed()
    Utils:SetRedDotState(RedDotDef.ID.AreanReport,isShow)

    if not Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SHOP_JINGJI, true) then
        LuaNetSendMsg:QueryRedDot(RedDotDef.SID.ShopWanFaJingji)
    end

    if not Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SHOP_XUEZHAN, true) then
        LuaNetSendMsg:QueryRedDot(RedDotDef.SID.ShopWanFaXueZhan)
    end
    
end

function LRedDotCheckMgr:RedDotShow(v)
    local button = v[2]
    if button == nil then return end

    button:getChildByName("Prompt"):setVisible(v[3])
end

function LRedDotCheckMgr:CheckShow(v)
    local func = v[1]
    local button = v[2]
    func()
end

-- 商城
function LRedDotCheckMgr:MainShopCheck()
    return false
end

function LRedDotCheckMgr:JiangHunShopCheck( ... )
    -- body
    local info = PetkaPaiManager.m_AllShopData[ShopDef.KP_SP.JIANGHUN]
    -- dump(info, "JiangHunShop ==>")
    local v = self.mainUIType.btn_jianghun
    if info == nil then
        v[3] = false
    else
        local jianghunShopConfig = JsonConfig.m_ShopConfig.getDefByID(ShopDef.KP_SP.JIANGHUN)
        v[3] = jianghunShopConfig.refresh_count - info.rafreshTimes > 0 and info.freeTimes > 0
        -- print("JiangHunShopCheck ==>", v[3])
    end
    
    Utils:SetRedDotState(RedDotDef.ID.ShopJiangHun, v[3])
    self:RedDotShow(v)
    return v[3]
end

function LRedDotCheckMgr:WanFaShopCheck( ... )
    return false
end


-- 排行
function LRedDotCheckMgr:MainRankCheck()
    return false
end

function LRedDotCheckMgr:DealMuBiaoTaskData(taskId)
    for i=1,#LRoleDataMgr.Task.m_targetTaskData do
        local itemData = LRoleDataMgr.Task.m_targetTaskData[i]
        if itemData then
            local isExist = false
            local isNeedCheck = true
            for j=1,#itemData.missions do
                local missData = itemData.missions[j]
                if missData and missData.missId == taskId then
                    local haveReward = Utils:UpdateTaskGiftState(missData)
                    if haveReward then
                        itemData.haveReward = haveReward
                        isNeedCheck = false
                    end
                    isExist = true
                    break
                end
            end
            if itemData.haveReward and isNeedCheck then
                itemData.haveReward = false
                for j=1,#itemData.missions do
                    if (not itemData.missions[j].isFinish) and itemData.missions[j].state == 2 then
                        itemData.haveReward = true
                        break
                    end
                end
            end
            if isExist then
                break
            end
        end
    end
    LRedDotCheckMgr:MainMubiaoCheck()
    Utils:SendMsg(LUITaskGiftEvent.UpdateTaskEvent)
end
-- 目标
function LRedDotCheckMgr:MainMubiaoCheck()
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_MUBIAO, true) then
        return false
    end

    local v = self.mainUIType.btn_mubiao
    v[3] = false
    for i=1,#LRoleDataMgr.Task.m_targetTaskData do
        local itemData = LRoleDataMgr.Task.m_targetTaskData[i]
        if itemData.state == 1 or itemData.haveReward == true then
            v[3] = true
            break
        end
    end
    self:showBattleBtnPrompt(AppDef.EModuleID.EMID_MUBIAO, v[3])
    self:RedDotShow(v)

    local list = LDataConstMgr:GetAllDouShenVector()
    local isAllFinish = (#LRoleDataMgr.Task.m_targetTaskData+1) == (#list)

    if isAllFinish and(not Utils:ToBool(self.IsDouShenFinish)) then
        for i=1,#LRoleDataMgr.Task.m_targetTaskData do
            local itemData = LRoleDataMgr.Task.m_targetTaskData[i]
            if itemData.state ~= 2 then
                isAllFinish = false
                break
            end
        end
    end

    if isAllFinish then
        self.IsDouShenFinish = true
        Utils:SendMsg(LUIMainEvent.SetFuncBtnVisible, {functionId=AppDef.EModuleID.EMID_MUBIAO, isShow=false})
    end
end

-- 首充
function LRedDotCheckMgr:MainShouchongCheck()
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SHOUCHONG, true) then
        return false
    end
    local v = self.mainUIType.btn_shouchong
    v[3] = false
    local state1 = LRoleDataMgr.m_firstRechargeState
    local state2 = LRoleDataMgr.m_secondRechargeState
    if state1 == 0 then
        local data = LRechargeDataMgr:GetFirstRechargeData()
        if data.isPaid then
            v[3] = true
        end
    elseif state2 == 0 then
        local data = LRechargeDataMgr:GetSecondRechargeData()
        if data.isPaid then
            v[3] = true
        end
    end
    self:RedDotShow(v)
    return v[3]
end

-- 折扣
function LRedDotCheckMgr:MainZhekouCheck()
    return true
end

-- 活动
function LRedDotCheckMgr:MainHuodongCheck(ind)
    -- local show = false
    -- local v = self.mainUIType.btn_huodong
    -- show = sevenRechargeCheck() or rechargeGiftCheck() or consumGiftCheck()
    -- v[3] = show
    -- self:RedDotShow(v)
    -- self:showBattleBtnPrompt(AppDef.EModuleID.EMID_HUODONG, v[3])

    local list = LRechargeDataMgr:GetWelFareActivityData()
    if list then
        if self.m_isInitActivity == nil then
            self.m_isShowActivity = {}
            if #list > 0 then
                for i=1,#list do
                    self.m_isShowActivity[i] = false
                    Utils:SetRedDotState(RedDotDef.ID.HDBase + i, true)
                end
                self.m_isInitActivity = true
            end
        else
            local function _MainHuodongCheck(index, item)
                if item then
                    local isShow = self.m_isShowActivity[index] == false
                    if item.tag == WelfareActivityDef.Type.SevenDaysChargeTag then
                        isShow = LRechargeDataMgr:getSevenRechargeRedDot() or self.m_isShowActivity[index] == false
                    elseif item.tag == WelfareActivityDef.Type.RechargeGift then
                        isShow = self:checkRechargeGiftRed() or self.m_isShowActivity[index] == false
                    elseif item.tag == WelfareActivityDef.Type.ConsumptionGift then
                        isShow = self:checkConsumGiftRed() or self.m_isShowActivity[index] == false
                    end
                    if isShow ~= nil then
                        Utils:SetRedDotState(RedDotDef.ID.HDBase + index, isShow)
                    end
                end
            end
            
            if ind then
                self.m_isShowActivity[ind] = true
                _MainHuodongCheck(ind, list[ind])
            else
                for i=1,#list do
                    _MainHuodongCheck(i, list[i])
                end
            end
        end
    end
    return false
end

-- 福利
function LRedDotCheckMgr:MainWelfareCheck(ind)
    --[[
    现在只有体力和资源找回
    ]]
--     if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_FULI, true) then
--         return false
--     end
--     -- 登录礼包
--     local function CheckLogin()
--         local loginGift = LRoleDataMgr.MyHeroInfo.m_pLoginGift
--         local ret = false

--         if loginGift.getNum <= 0 then
--             return ret
--         end

--         for i=1,loginGift.getNum do
--             if loginGift.dayInfo[i] and loginGift.dayInfo[i].haveGet ~= nil and loginGift.dayInfo[i].haveGet == false then
--                 ret = true
--                 break
--             end
--         end
--         Utils:SetRedDotState(RedDotDef.ID.FLDengLuItem, ret)
--         return ret
--     end

--     -- 等级礼包
--     local function CheckLevel()
--         local show = false
--         for k,v in pairs(LRoleDataMgr.MyHeroInfo.m_pLevelWard) do
--             if LRoleDataMgr.MyHeroInfo.level >= v.level and v.canBuy then
--                 show = true
--                 break
--             end
--         end
--         Utils:SetRedDotState(RedDotDef.ID.FLDengJiItem, show)
--         return show
--     end

--     -- 签到
--     local function CheckSigin()
--         local show = false
--         show = LRoleDataMgr.MyHeroInfo.dailyIsDone == 0
--         Utils:SetRedDotState(RedDotDef.ID.FLQianDaoItem, show)
--         return show
--     end

--     -- 会员
--     local function CheckHuiyuan()
--         local show = false
--         if LRoleDataMgr.MyHeroInfo.MyVIPInfo.isHasMcCard then
--             show = LRoleDataMgr.MyHeroInfo.MyVIPInfo.mcGiftMonState
--         end
--         if LRoleDataMgr.MyHeroInfo.MyVIPInfo.isHasLmCard then
--             show = LRoleDataMgr.MyHeroInfo.MyVIPInfo.mcLifeGiftMonState
--         end
--         Utils:SetRedDotState(RedDotDef.ID.FLBaiJinItem, show)
--         return show
--     end

--     -- 离线奖励
--     local function CheckOffline()
--         local show = false
--         if LRoleDataMgr.MyHeroInfo.offlineInfo ~= nil then
--             show = LRoleDataMgr.MyHeroInfo.offlineInfo.mianfei > 0
--         end
--         Utils:SetRedDotState(RedDotDef.ID.FLLiXianItem, show)
--         return show
--     end

-- --new 资源找回
--     local function CheckOfflineRes()
--         -- body
-- --         local show = false
-- --         if LRoleDataMgr.recoveryData ~= nil and not LRoleDataMgr.m_resRecoveryClicked then
-- --             for i = 1, #LRoleDataMgr.recoveryData.offlineListInfo do
-- --                 local data = LRoleDataMgr.recoveryData.offlineListInfo[i]
-- --                 if data.findTimes > 0 then
-- --                     show  = true
-- --                     break
-- --                 end
-- --             end
-- --         end
-- -- --        --print("CheckOfflineRes show", show)
-- --         Utils:SetRedDotState(RedDotDef.ID.FLFindResItem, show)
-- --         return show
--         return false
--     end

--     -- 在线奖励
--     local function CheckOnline()
--         local show = self.onlineCd == 0
--         Utils:SetRedDotState(RedDotDef.ID.FLZaiXianItem, show)
--         return show
--     end

--     local show = false
--     local v = self.mainUIType.btn_fuli
--     if ind == nil then
--         show = CheckLogin() or CheckLevel()
--         or CheckSigin() or CheckHuiyuan()
--         or CheckOffline() or CheckOnline() or CheckOfflineRes()
--         v[3] = show
--         -- self:RedDotShow(v)
--         self:showBattleBtnPrompt(AppDef.EModuleID.EMID_FULI, v[3])
--         return v[3]
--     elseif ind == 1 then
--         show = CheckLogin()
--     elseif ind == 2 then
--         show = CheckLevel()
--     elseif ind == 3 then
--         show = CheckSigin()
--     elseif ind == 4 then
--         show = CheckHuiyuan()
--     elseif ind == 5 then
--         show = CheckOffline()
--     elseif ind == 6 then
--         show = CheckOfflineRes()
--     elseif ind == 7 then
--         show = CheckOnline()
--     end
--     self:showBattleBtnPrompt(AppDef.EModuleID.EMID_FULI, show)
--     return show
    return false
end

-- 技能
function LRedDotCheckMgr:MainSkillCheck()
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_JINENG, true) then
        return false
    end
    local v = self.mainUIType.btn_jineng
    v[3] = false
    for i=1,#LRoleDataMgr.HeroSkills do
        local skill = LRoleDataMgr.HeroSkills[i]
        if Utils:CheckSkillLevelUp(i, skill.level, true) then
            v[3] = true
            break
        end
    end
    self:RedDotShow(v)
    self:showBattleBtnPrompt(AppDef.EModuleID.EMID_JINENG, v[3])
    return v[3]
end

-- 神将
function LRedDotCheckMgr:ZhenRongCheck(ind)
    -- 升级
    local function LevelUpCheck()
        if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_KAPAI_SJJINENG, true) then
            return false
        end
        local show = false
        for pk,pet in pairs(LRoleDataMgr.Pet.petlist) do
            if pet.fightPos > 0 then
                show = PetkaPaiManager:getPetCanLevelUp(pet)
                if show then break end
            end
        end
        return show
    end

    -- 上阵 
    local function InfoCheck()
        local show = false
        -- dump(LRoleDataMgr.Pet.ShowPosList, "=======================>")
        for i=1, #LRoleDataMgr.Pet.ShowPosList do
            if LRoleDataMgr.Pet.ShowPosList[i] <= 0 then
                local isOpen =  not Utils:CheckModelNotOpened(AppDef.PetFightPos[i], true)
                -- print("LRedDotCheckMgr:ZhenRongCheck isOpen ==>", isOpen)
                if  isOpen then
                    for pk, pet in pairs(LRoleDataMgr.Pet.petlist) do
                        if pet.fightPos <= 0 then
                            return true
                        end
                    end
                end
            end
        end
        return show
    end

    --可换将
    local function ChangePetCheck()
        local show = false
        local minQuliaty = 7
        for pk, pet in pairs(LRoleDataMgr.Pet.petlist) do
            if pet.baseData and pet.fightPos > 0 then
                if pet.baseData.quality < minQuliaty then
                    minQuliaty = pet.baseData.quality
                end
            end
        end

        for k,v in pairs(LRoleDataMgr.Pet.petlist) do
            if v.fightPos <= 0 and v.baseData and v.baseData.quality > minQuliaty then
                return true
            end
        end

        return show
    end

    -- 升星
    local function StarLevelCheck()
        if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_KAPAI_SJSHENGXING, true) then
            return false
        end
        local show = false
        for pk,pet in pairs(LRoleDataMgr.Pet.petlist) do
            if pet.fightPos > 0 then
                show = PetkaPaiManager:isPetCanStarUp( pet )
                if show then break end
            end
        end
        return show
    end

    -- 突破
    local function BreakUpCheck()
        if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_KAPAI_SJXIULIAN, true) then
            return false
        end
        local show = false
        for pk,pet in pairs(LRoleDataMgr.Pet.petlist) do
            if pet.fightPos > 0 then
                show = PetkaPaiManager:isPetCanBreakUp(pet)
                if show then break end
            end
        end
        return show
    end

    -- 布阵
    local function FomationCheck()
        if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SJBUZHEN, true) then
            return false
        end
        local show = false
        local list = LDataConstMgr:GetFormationDataList()
        local cnt = #list
        for i=1, cnt do
            show = LRoleDataMgr:FormationCheckUp(i)
            if show then break end
        end
        return show
    end

    -- 修炼
    local function XiuLianCheck( ... )
        -- body
        if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_KAPAI_SJXIULIAN_REALY, true) then
            return false
        end
        local show = PetkaPaiManager:isHasPetTianMingJH()
        print("XiuLianCheck ==================>", show)
        return show
    end

    local v = self.mainUIType.btn_zhenrong
    local isFomation =FomationCheck() 
    Utils:SetRedDotState(RedDotDef.ID.ShenJiang_BuZhen,isFomation)

    local isCanLevelUp = LevelUpCheck()
    Utils:SetRedDotState(RedDotDef.ID.ShenJiang_LVUp, isCanLevelUp)

    local isCanStarUp = StarLevelCheck()
    Utils:SetRedDotState(RedDotDef.ID.ShenJiang_StarUp, isCanStarUp)

    local isCanHangUp = InfoCheck()
   
    Utils:SetRedDotState(RedDotDef.ID.ShenJiang_ShangZhen, isCanHangUp)

    local isChangePet = ChangePetCheck()
    
    Utils:SetRedDotState(RedDotDef.ID.ShenJiang_Change, isChangePet)

    local isCanBreakUp = BreakUpCheck()
    Utils:SetRedDotState(RedDotDef.ID.ShenJiang_BreakUp, isCanBreakUp)

    local isCanTianMingJH = XiuLianCheck()
    Utils:SetRedDotState(RedDotDef.ID.ShenJiang_XiuLian, isCanTianMingJH)

    local IsEquipRed = false
    for i=1, #LRoleDataMgr.Pet.ShowPosList do
        --上阵检测,防止把装备的红点置掉
        if LRoleDataMgr.Pet.ShowPosList[i] > 0 then
            local key = "EquipShengJiang"..(i)
            IsEquipRed = Utils:GetRedDotState(RedDotDef.ID[key])
            if IsEquipRed then break end
        end
    end

    v[3] = isCanLevelUp or isCanStarUp or isCanHangUp or isCanBreakUp or isChangePet or isFomation or IsEquipRed or isCanTianMingJH
    self:RedDotShow(v)
--战斗UIBtn
    -- self:showBattleBtnPrompt(AppDef.EModuleID.EMID_SHENJIANG, v[3])
    return v[3]
end

-- 抽卡
function LRedDotCheckMgr:MainCardCheck()
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_KAPAI_CHOUKA, true) then
        return false
    end
   
    local v = self.mainUIType.btn_chouka
    local show = false

    local danci1 = false
    local shilian1 = false
    local itemNum1 = LRoleDataMgr.Equip:CountItemNumById(1000)
    if itemNum1 >= 10 then
        shilian1 = true
        danci1 = true
    elseif itemNum1 > 0 then
        danci1 = true
    end

    local danci2 = false
    local shilian2 = false
    local itemNum2 = LRoleDataMgr.Equip:CountItemNumById(1001)
    if itemNum2 >= 10 then
        shilian2 = true
        danci2 = true
    elseif itemNum2 > 0 then
        danci2 = true
    end

    local danci3 = false
    local shilian3 = false
    local itemNum3 = LRoleDataMgr.Equip:CountItemNumById(1002)
    if itemNum3 >= 100 then
        shilian3 = true
        danci3 = true
    elseif itemNum3 >= 10 then
        danci3 = true
    end
    Utils:SetRedDotState(RedDotDef.ID.HD_FriendLy_DanCi, danci3)
    Utils:SetRedDotState(RedDotDef.ID.HD_FriendLy_ShiLian, shilian3)

    --print("LRedDotCheckMgr:MainCardCheck ====>", itemNum1, itemNum2, itemNum3)

    -- dump(PetkaPaiManager.m_DrawInfo, "DealLuckDraw ===========================>")
    --抽卡信息
    if not danci1 and PetkaPaiManager.m_DrawInfo and #PetkaPaiManager.m_DrawInfo > 0 then
        danci1 = PetkaPaiManager.m_DrawInfo[1].leftTimes > 0 and PetkaPaiManager.m_DrawInfo[1].freeLeftTime <= 0
    end

    Utils:SetRedDotState(RedDotDef.ID.HD_Normal_DanCi, danci1)
    Utils:SetRedDotState(RedDotDef.ID.HD_Normal_ShiLian, shilian1)

    if not danci2 and PetkaPaiManager.m_DrawInfo and  #PetkaPaiManager.m_DrawInfo > 0 then
        danci2 = PetkaPaiManager.m_DrawInfo[2].leftTimes > 0 and PetkaPaiManager.m_DrawInfo[2].freeLeftTime <= 0
    end
    Utils:SetRedDotState(RedDotDef.ID.HD_GaoJi_DanCi, danci2)
    Utils:SetRedDotState(RedDotDef.ID.HD_GaoJi_ShiLian, shilian2)
    -- print("LRedDotCheckMgr:MainCardCheck  danci1 ========>",danci1, danci2, danci3)
    v[3] = danci1 or danci2 or danci3 or shilian1 or shilian2 or shilian3
    self:RedDotShow(v)
    return v[3]
end

function LRoleDataMgr:BangpaiCheck()
    return false;
end

--境界
function LRedDotCheckMgr:MianJingJieCheck(ind)
     if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_JINGJIE, true) then
        return false
    end
     local function Salary()--领取薪水
        return LRoleDataMgr:CheckJingJieSalary()
    end

                                 
    local function Break() -- 突破
        return LRoleDataMgr:CheckJingJieBreak()
    end

    -- 激活
   
    local v = self.mainUIType.btn_jingjie
    v[3] = Salary() or Break() 
    self:RedDotShow(v)
   -- self:showBattleBtnPrompt(AppDef.EModuleID.EMID_JINGJIE, v[3])
    return v[3]


end




-- 坐骑
function LRedDotCheckMgr:MainMountCheck(ind)
   
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_ZUOJI, true) then
        return false
    end
    -- 进阶
    local function Jinjie()
        return LRoleDataMgr:CheckMountUpgrade()
    end

    -- 强化
    local function Qianghua()
        return LRoleDataMgr:CheckMountEnforce()
    end

    -- 激活
    local function Jihuo()
        return LRoleDataMgr:CheckMountExChange()
    end

    local v = self.mainUIType.btn_zuoqi
    v[3] = Jinjie() or Qianghua() or Jihuo()
    self:RedDotShow(v)
    self:showBattleBtnPrompt(AppDef.EModuleID.EMID_ZUOJI, v[3])
    return v[3]
end

-- -- 锻造
-- function LRedDotCheckMgr:MainDuanzaoCheck()
--     --if true then return end
--     if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_DUANZAO, true) then
--         return false
--     end
--     local isAll = false
--     local uiInd = LUILogic:GetUIInBufferInd("Forge.ForgeMainUI")
-- 	if uiInd ~= 0 then
--        isAll = true
--     end
--     local v = self.mainUIType.btn_duanzao
--     v[3] = false
--     local show1 = self:DZ_UpgradeCheck(isAll)
--     if show1 then
--         v[3] = true
--         if not isAll then
--             self:RedDotShow(v)
--             self:showBattleBtnPrompt(AppDef.EModuleID.EMID_DUANZAO, v[3])
--             return v[3]
--         end
--     end
--     local show2 = self:DZ_StrenthenCheck(isAll)
--     if show2 then
--         v[3] = true
--         if not isAll then
--             self:RedDotShow(v)
--             self:showBattleBtnPrompt(AppDef.EModuleID.EMID_DUANZAO, v[3])
--             return v[3]
--         end
--     end
--     -- local show3 = self:DZ_QuenchCheck(isAll)
--     -- if show3 then
--     --     v[3] = true
--     --     if not isAll then
--     --         self:RedDotShow(v)
--     --         self:showBattleBtnPrompt(AppDef.EModuleID.EMID_DUANZAO, v[3])
--     --         return v[3]
--     --     end
--     -- end
--     local show4 = self:DZ_XiLianCheck()
--     if show4 then
--         v[3] = true
--         if not isAll then
--             self:RedDotShow(v)
--             self:showBattleBtnPrompt(AppDef.EModuleID.EMID_DUANZAO, v[3])
--             return v[3]
--         end
--     end
--     self:RedDotShow(v)
--     self:showBattleBtnPrompt(AppDef.EModuleID.EMID_DUANZAO, v[3])
--     return v[3]
-- end

-- function LRedDotCheckMgr:DZ_StrenthenCheck(isAll)
--     if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_DZQIANGHUA, true) then
--         return false
--     end
--     local isCheck = false
--     local equipList = LRoleDataMgr:GetEquipList()
--     local money = LRoleDataMgr.MyHeroInfo.DetailData.Money
--     -- = {}
--     self.m_dzRedDotData[AppDef.EquipForgeType.EFT_Strengthen] = {}
--     local indexs = self.m_dzRedDotData[AppDef.EquipForgeType.EFT_Strengthen] 
--     for k,v in pairs(equipList) do
--         local pItem = DZ_GetPItem(v.type, v.pos)
--         if pItem ~= nil and pItem.m_item ~= nil and pItem.m_qhLevel < AppDef.MAX_EQUIP_STRENGTH_LEVEL then
--             local dCost = LDataConstMgr:GetEquipStrengthenCost(pItem.m_item.m_pos,pItem.m_qhLevel)
--             if dCost ~= nil and dCost.m_itemId > 0 then 
--                local itemNum = LRoleDataMgr.Equip:CountItemNumById(dCost.m_itemId)          
--                if money < dCost.m_moneyValue then 
--                else 
--                      if itemNum >= dCost.m_itemNum then
--                         isCheck = true
--                         if isAll then
--                             indexs[k] = 1
--                         else
--                             break                        
--                         end                      
--                      else
--                         local data = Utils:AutoMaticPropSynthesis(dCost.m_itemId,dCost.m_itemNum-itemNum)
--                          if data.isTrue then
--                             isCheck = true
--                            if isAll then
--                              indexs[k] = 1
--                            else  
--                               break
--                            end           
--                          end    
--                      end
--                end
--             end
--         end
--     end
--     local uiInd = LUILogic:GetUIInBufferInd("Forge.ForgeMainUI")
-- 	if uiInd ~= 0 then
--         LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RedDotState, {2, isCheck})
--         self:SendMsg(LGameMsg.m_baseMsgWithOne)

--         LGameMsg.m_baseMsg:ChangeEventId(LUIForgeEvent.StrengthenRedDot)
--         self:SendMsg(LGameMsg.m_baseMsg)
--     end
--     return isCheck
-- end

-- function LRedDotCheckMgr:DZ_UpgradeCheck(isAll)
--     if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_DZSHENGJIE, true) then
--         return false
--     end
--     self.m_dzRedDotData[AppDef.EquipForgeType.EFT_Upgrade] = {}
--     local indexs = self.m_dzRedDotData[AppDef.EquipForgeType.EFT_Upgrade] 
--     local isCheck = false
--     local equipList = LRoleDataMgr:GetEquipList()
  
--     local money = LRoleDataMgr.MyHeroInfo.DetailData.Money
--     local level = LRoleDataMgr.MyHeroInfo.level
--     for k,v in pairs(equipList) do
--         local pItem = DZ_GetPItem(v.type, v.pos) 
     
--         if pItem ~= nil and pItem.m_item ~= nil and  pItem.m_item.m_level < AppDef.MAX_EQUIP_UPGRADE_LEVEL then
--             local pCItem = LItemMgr:getItem(pItem.m_id+1)--下一阶道具
--             if pCItem ~= nil and pCItem.m_type == pItem.m_type and pCItem.m_level <= level then
--                -- if pItem.m_item.m_pos==0 or pItem.m_item.m_level==0 then
--                 --   dump(pItem,"pItem===============>s")          
--                -- end
--                 local dCost = LDataConstMgr:GetEquipUpgradeData(pItem.m_item.m_pos,pItem.m_item.m_level)
--                 if dCost ~= nil and dCost.m_itemId > 0 then 

--                    local itemNum = LRoleDataMgr.Equip:CountItemNumById(dCost.m_itemId)
--                    if money < dCost.m_moneyValue then 
--                    else 
--                      if itemNum >= dCost.m_itemNum then
--                         isCheck = true
--                         if isAll then
--                             indexs[k] = 1
--                         else
--                             break                       
--                         end                      
--                      else
--                         local data = Utils:AutoMaticPropSynthesis(dCost.m_itemId,dCost.m_itemNum-itemNum)
--                          if data.isTrue then
--                             isCheck = true
--                            if isAll then
--                              indexs[k] = 1
--                            else  
--                               break
--                            end           
--                          end    
--                      end
--                    end
--                    -- if itemNum >= dCost.m_itemNum and money >= dCost.m_moneyValue then
--                    --     isCheck = true
--                    --     if isAll then
--                    --         indexs[k] = 1
--                    --     else
--                    --         break
--                    --     end
--                    -- end
--                 end
--             end
--         end
--     end
--     local uiInd = LUILogic:GetUIInBufferInd("Forge.ForgeMainUI")
-- 	if uiInd ~= 0 then
--         LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RedDotState, {1, isCheck})
--         self:SendMsg(LGameMsg.m_baseMsgWithOne)

--         LGameMsg.m_baseMsg:ChangeEventId(LUIForgeEvent.UpgradeRedDot)
--         self:SendMsg(LGameMsg.m_baseMsg)
--     end
--     return isCheck
-- end

-- function LRedDotCheckMgr:DZ_QuenchCheck(isAll)
--     local function CheckStoneAndMoney()
--         local numCrystal = LRoleDataMgr.Equip:CountItemNumById(612)--圣水晶
--         if numCrystal < 1 then
--             return false
--         end
--         local isLianhStone,stoneId = DZ_CheckItemType(AppDef.EItemListType.EILTLianHuaStone,1)
--         if not isLianhStone then
--              return false
--         end
--         local money = LRoleDataMgr.MyHeroInfo.DetailData.Money
--         local needMoney = math.floor(math.pow(3.0,(stoneId-801)) *1666)
--         if money < needMoney then
--             return false
--         end
--         return true
--     end

--     if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_DZCUILIAN, true) then

--         return false
--     end
--     self.m_dzRedDotData[AppDef.EquipForgeType.EFT_Baptize] = {}
--     if not CheckStoneAndMoney() then
--         local uiInd = LUILogic:GetUIInBufferInd("Forge.ForgeMainUI")
-- 	    if uiInd ~= 0 then
--             LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RedDotState, {4, isCheck})
--             self:SendMsg(LGameMsg.m_baseMsgWithOne)

--             LGameMsg.m_baseMsg:ChangeEventId(LUIForgeEvent.QuenchRedDot)
--             self:SendMsg(LGameMsg.m_baseMsg)
--         end
--         return false
--     end
--     local indexs = self.m_dzRedDotData[AppDef.EquipForgeType.EFT_Baptize] 
--     local isCheck = false
--     local equipList = LRoleDataMgr:GetEquipList()
--     for k,v in pairs(equipList) do
--         local pItem = DZ_GetPItem(v.type, v.pos)
--         if pItem ~= nil and pItem.m_id > 0 and pItem:IsEquip() then
--             if pItem.m_item == nil then
--                 pItem.m_item = LItemMgr:getItem(pItem.m_id)
--             end
--             local level = pItem.m_item.m_level
--             local dCuiLian =  LDataConstMgr:GetEquipCuiLianData(pItem.m_type) 
--             if dCuiLian ~= nil then     
--                 for i=1,#dCuiLian.m_level do
--                     local value = pItem:Get_addCuiLianAttrValByIdx(i) or 0
--                     if level >= dCuiLian.m_level[i] and value < dCuiLian.m_attrMaxVal[i] then
--                         isCheck = true
--                         if isAll then
--                             indexs[k] = 1
--                         end
--                         break
--                     end
--                 end
--             end
--         end
--         if not isAll and isCheck then
--             break
--         end
--     end
--     local uiInd = LUILogic:GetUIInBufferInd("Forge.ForgeMainUI")
-- 	if uiInd ~= 0 then
--         LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RedDotState, {4, isCheck})
--         self:SendMsg(LGameMsg.m_baseMsgWithOne)

--         LGameMsg.m_baseMsg:ChangeEventId(LUIForgeEvent.QuenchRedDot)
--         self:SendMsg(LGameMsg.m_baseMsg)
--     end
--     return isCheck
-- end

-- function LRedDotCheckMgr:DZ_XiLianCheck()
--     if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_DZXILIAN, true) then
--         return false
--     end
--     local isCheck = DZ_CheckItemType(AppDef.EItemListType.EILTXiLianStone,1)
--     local uiInd = LUILogic:GetUIInBufferInd("Forge.ForgeMainUI")
-- 	if uiInd ~= 0 then
--         LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RedDotState, {3, isCheck})
--         self:SendMsg(LGameMsg.m_baseMsgWithOne)
--     end
--     if not isCheck then
--         return false
--     end
--     return true
-- end

-- 公会
-- function LRedDotCheckMgr:MainGuildCheck()
--     local v = self.mainUIType.btn_bangpai
--     v[3] = Utils:GetRedDotState(RedDotDef.ID.BangPai)
--     self:RedDotShow(v)
--     --print("bangpai", v[3])
--     self:showBattleBtnPrompt(AppDef.EModuleID.EMID_BANGPAI, v[3])
--     return v[3]
-- end

-- 神器
-- function LRedDotCheckMgr:MainArtifactCheck()
--     local function peiyang()
--         if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SQJINJIE, true) then
--             return false
--         end    
--         local isMax = false
--         local info = LArtifactUIDataMgr.m_UIData
--         if info ~= nil then      
--             local level = info["cur_level"]
--             local star = info["cur_star"]   
--             if level == 10 and star == 5 then
--                isMax = true
--             end
--         end
--         if isMax or not  DZ_CheckItemType(AppDef.EItemListType.EILTWuSeStone,1) then
--             return false
--         end
--         return true
--     end

--     local function jihuo()
--         if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SHENQI, true) then
--             return false
--         end  
--         local info = LRoleDataMgr.m_ServerShenQiList
--         if info == nil or #info == 0 then
--             return false
--         end
--         for i=1,#info do
--             if info[i].state == 0 and info[i].itemId > 0 then
--                local value = LRoleDataMgr.Equip:CountItemNumById(info[i].itemId) 
--                if value >= info[i].needNum then
--                    return true
--                end
--             end
--         end
--         return false
--     end
   
--     local signs = {}
--     signs[2] = peiyang()
--     signs[1] = jihuo()
--     local v = self.mainUIType.btn_shenqi
--     v[3] = signs[1] or signs[2]
--     self:RedDotShow(v)
--     self:showBattleBtnPrompt(AppDef.EModuleID.EMID_SHENQI, v[3])
--     local uiInd = LUILogic:GetUIInBufferInd("Artifact.ArtifactMainUI")
-- 	if uiInd ~= 0 then
--         for i=1,2 do
--             LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RedDotState, {i, signs[i]})
--             self:SendMsg(LGameMsg.m_baseMsgWithOne)
--         end
--     end
    
--     return v[3]
-- end

-- 羽翼
function LRedDotCheckMgr:MainWingCheck()
    local isShow = false
    return isShow
end

-- 设置
function LRedDotCheckMgr:MainSettingCheck()
    return false
end

function LRedDotCheckMgr:SetLockerSelect(select)
    self.lockerSelect = select
    self:MainChangeCheck()
end

-- 扩展按钮
function LRedDotCheckMgr:MainChangeCheck()
   -- --print("扩展按钮检查")
    -- local v = self.mainUIType.locker
    -- if self.lockerSelect then
    --     v[3] = (self:MainWingCheck() or self:MainArtifactCheck() or self:PetEquipAllRedCheck())
    --     self:RedDotShow(v)
    -- else
    --     v[3] = self:MainMountCheck() or self:MainCardCheck() or self:MainSkillCheck()
    --     self:RedDotShow(v)
    -- end
end

-- 背包
function LRedDotCheckMgr:MainBagCheck()
    return false
end
 
-- 玩法
function LRedDotCheckMgr:MainActivityCheck()
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_WANFA, true) then
        return false
    end
    local v = self.mainUIType.btn_wanfa
    v[3] = false
    for k,value in pairs(LActivityManager.m_pActivityDataBuff) do
        if LActivityManager:GetMaxCount(k) > 0 then
            v[3] = true
            break
        end
    end
    self:RedDotShow(v)
    return v[3]
end

--社交
function LRedDotCheckMgr:SocialCheck()
    -- body
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SHEJIAO, true) then
        return false
    end
    local v = self.mainUIType.btn_social
    --local mailDot = self:MailCheck()
    local msgDot = self:msgCheck()

    local show =  msgDot
    ----print("LRedDotCheckMgr:SocialCheck", show)
    v[3] = show
    self:RedDotShow(v)
    return v[3]
end

function LRedDotCheckMgr:FundRebateShowCheck()
    local cd,buyId,datas = LRoleDataMgr.fundRebateData[1],LRoleDataMgr.fundRebateData[2],LRoleDataMgr.fundRebateData[3]
    if cd == nil or buyId == nil or datas == nil then
        return false
    end
    local show = false
    if cd > 0 and buyId > 0 then
        for i=1,#datas do
            if bit.band(buyId, bit.lshift(1, i)) > 0 then
                for j=1,#datas[i].dayArr do
                    local dayData = datas[i].dayArr[j]
                    --dump(dayData, "dayData----->")
                    if dayData.state ~= 3 then
                        show = true
                        break
                    end
                end

                if show then
                    break
                end
            else
                show = true
                break
            end
        end
    end
    return show
end

function LRedDotCheckMgr:FundRebateCheck()
    -- body
    local v = self.mainUIType.btn_jijin
    local show = false
    if v[2] and v[2]:isVisible() then
        local cd,buyId,datas = LRoleDataMgr.fundRebateData[1],LRoleDataMgr.fundRebateData[2],LRoleDataMgr.fundRebateData[3]
        if cd == nil or buyId == nil or datas == nil then
            return false
        end
        -- dump({cd, buyId}, "----------->")
        if cd > 0 and buyId > 0 then
            for i=1,#datas do
                if bit.band(buyId, bit.lshift(1, i)) > 0 then
                    -- dump({datas[i].id, datas[i].dayArr}, "datas[i].dayArr--->")
                    for j=1,#datas[i].dayArr do
                        local dayData = datas[i].dayArr[j]
                        if dayData.state == 2 then
                            show = true
                            break
                        end
                    end

                    if show then
                        break
                    end
                    
                end
            end
        end
    end
    ----print("LRedDotCheckMgr:FundRebateCheck", show)
    v[3] = show
    self:RedDotShow(v)
    return v[3]
end


function LRedDotCheckMgr:HuoYueJiJinShowCheck()
    local cd,buyId,datas = LRoleDataMgr.huoyueJiJinData[1],LRoleDataMgr.huoyueJiJinData[2],LRoleDataMgr.huoyueJiJinData[3]
    if cd == nil or buyId == nil or datas == nil then
        return false
    end
    local show = false
    if  buyId > 0 then
        for i=1,#datas do
            if bit.band(buyId, bit.lshift(1, i)) > 0 then
                for j=1,#datas[i].dayArr do
                    local dayData = datas[i].dayArr[j]
                    --dump(dayData, "dayData----->")
                    if dayData.state ~= 3 then
                        show = true
                        break
                    end
                end
                if show then
                    break
                end
            end
        end
    end
    return show
end

--活跃基金小红点
function LRedDotCheckMgr:HuoYueJiJinCheck()
    -- body
    -- local v = self.mainUIType.btn_jijin2
    -- local show = false
    -- if v[2] then
    --     local cd,buyId,datas = LRoleDataMgr.huoyueJiJinData[1],LRoleDataMgr.huoyueJiJinData[2],LRoleDataMgr.huoyueJiJinData[3]
    --     if cd == nil or buyId == nil or datas == nil then
    --         return false
    --     end
    --     -- dump({cd, buyId}, "----------->")
    --     -- dump(datas, "HuoYueJiJinCheck ===>")
    --     if cd > 0 and buyId > 0 then
    --         for i=1,#datas do
    --             if bit.band(buyId, bit.lshift(1, i)) > 0 then
    --                 -- dump({datas[i].id, datas[i].dayArr}, "datas[i].dayArr--->")
    --                 for j=1,#datas[i].dayArr do
    --                     local dayData = datas[i].dayArr[j]
    --                     -- dump(dayData, "HuoYueJiJinCheck ===>")
    --                     if dayData.state == 2 then
    --                         show = true
    --                         break
    --                     end
    --                 end

    --                 if show then
    --                     break
    --                 end
    --             end
    --         end
    --     end
    -- end

    -- v[3] = show
    -- self:RedDotShow(v)
    -- return v[3]
end

-- --新邮件
-- function LRedDotCheckMgr:newMailCheck()
--     -- body
--     local v = self.mainUIType.btn_social
--     v[3] = true
--     self:RedDotShow(v)
--     return v[3]
-- end

-- function LRedDotCheckMgr:MailCheck()
--     -- body
-- --    --print("LRedDotCheckMgr:MailCheck", #LRoleDataMgr.Social.NewMailData)
--     return #LRoleDataMgr.Social.NewMailData > 0
-- end

function LRedDotCheckMgr:msgCheck()
    -- body
    ----print("LRedDotCheckMgr:msgCheck", LRoleDataMgr.Social:IsUnReadMsg())
    return LRoleDataMgr.Social:IsUnReadMsg()
end

function LRedDotCheckMgr:DealUpdateRedDotState(data)
    -- dump(data, "data--->")
    local v = nil
    if data.id == RedDotDef.ID.BangPai then
        --战斗内红点
        v = self.mainUIType.btn_bangpai
        self:showBattleBtnPrompt(AppDef.EModuleID.EMID_BANGPAI, data.isShow)
    elseif data.id == RedDotDef.ID.Friend then
        v = self.mainUIType.btn_friend
    elseif data.id == RedDotDef.ID.Mail then
        v = self.mainUIType.btn_mail
    elseif data.id == RedDotDef.ID.BPHuoDong then
        v = self.mainUIType.btn_Activity
    elseif data.id == RedDotDef.ID.Fuli then
        v = self.mainUIType.btn_huodong
        --战斗内红点
        -- self:showBattleBtnPrompt(AppDef.EModuleID.EMID_FULI, data.isShow)
    elseif data.id == RedDotDef.ID.YuYi then
        v = self.mainUIType.btn_yuyi
        self:showBattleBtnPrompt(AppDef.EModuleID.EMID_YUYI, data.isShow)
    elseif data.id == RedDotDef.ID.HuoDong then
        -- v = self.mainUIType.btn_huodong
        -- self:showBattleBtnPrompt(AppDef.EModuleID.EMID_HUODONG, data.isShow)
    elseif data.id == RedDotDef.ID.ZhuangBei then
        v = self.mainUIType.btn_zhuangbei
    elseif data.id == RedDotDef.ID.QiRiActivity then
        v = self.mainUIType.btn_Qiri
    elseif data.id == RedDotDef.ID.FuBenMap then
        v = self.mainUIType.btn_fuben
    elseif data.id == RedDotDef.ID.ArenaTask then
        v = self.mainUIType.btn_arena_reward
    elseif data.id == RedDotDef.ID.DaliyTask then
        v = self.mainUIType.btn_renwu
    elseif data.id == RedDotDef.ID.AreanReport then
        v = self.mainUIType.btn_arena_report
        LUserConfigMgr:SetArenaZbRed(data.isShow)
        -- print("self.mainUIType.btn_fuben ==>", v[2])
    elseif data.id == RedDotDef.ID.ShenjiangBag  then
        v = self.mainUIType.btn_shenjiangbeibao
    elseif data.id == RedDotDef.ID.ShenJiangZhenRong  then
        v = self.mainUIType.btn_zhenrong
        -- dump(data, "=====================>")
    elseif data.id == RedDotDef.ID.XunBaoTask then
        v = self.mainUIType.btn_xunbao_task
    elseif data.id == RedDotDef.ID.ShopJiangHun then
        v = self.mainUIType.btn_jianghun
    elseif data.id == RedDotDef.ID.ShopMain then
        v = self.mainUIType.btn_shangcheng
    elseif data.id == RedDotDef.ID.ShopWanFa then
        v = self.mainUIType.btn_wanfaShop
    elseif data.id == RedDotDef.ID.ChuanDai then
        v = self.mainUIType.btn_chuandai
    end
    
    if v then
        v[3] = data.isShow
        self:RedDotShow(v)
    end
end

function LRedDotCheckMgr:getBattleMenuPrompt(btnType)
    -- body
    for i = 1, #self.BattleMenuPrompt do
        if self.BattleMenuPrompt[i].typeId == btnType then
            return self.BattleMenuPrompt[i]
        end
    end
end

function LRedDotCheckMgr:addBattleMenuPrompt(id, prompt)
    -- body
    for i = 1, #self.BattleMenuPrompt do
        if self.BattleMenuPrompt[i].typeId == id then
            return
        end
    end

    local btnData = {}
    btnData.typeId = id
    btnData.btnPrompt = prompt
    btnData.isShowPrompt = false
    table.insert(self.BattleMenuPrompt, btnData)
end

function LRedDotCheckMgr:showBattleBtnPrompt(type, isShow)
    -- body
--     local btnData = self:getBattleMenuPrompt(type)
--  --   --print("showBattleBtnPrompt", type)
--     if btnData == nil then
--         return
--     end
--     local prompt = btnData.btnPrompt
--     if prompt then
-- --        --print("showBattleBtnPrompt *****************", type)
--         btnData.isShowPrompt = isShow
--         prompt:setVisible(isShow)

--         Utils:SendMsg(LUILogicEvent.checkAllBattleRedPot)
--     end
end

function LRedDotCheckMgr:CheckBattleAllPrompt()
    -- body
    for i = 1, #self.BattleMenuPrompt do
        if self.BattleMenuPrompt[i].isShowPrompt then
            return true
        end
    end
    return false
end

function LRedDotCheckMgr:checkRechargeGiftRed()
    -- body
    local awards = LRoleDataMgr.MyHeroInfo.m_pRechargetGift
--    dump(awards, "checkRechargeGiftRed")
    local chongzhi = awards.chongzhi
    for k,v in pairs(awards.awardInfo) do
        if chongzhi >= v.yubao and not v.isGetAward then
            return true
        end
    end
    return false
end

function LRedDotCheckMgr:checkConsumGiftRed()
    -- body
    local awards = LRoleDataMgr.m_consumptionGiftData
--    dump(awards, "checkRechargeGiftRed")
    local chongzhi = awards.chongzhi
    for k,v in pairs(awards.awardInfo) do
        if chongzhi >= v.yubao and not v.isGetAward then
            return true
        end
    end
    return false
end

function LRedDotCheckMgr:BangPaiActivityCheck(datas)
    self.m_pFactionActivity = datas or self.m_pFactionActivity
    if self.m_pFactionActivity == nil then
        return
    end
    local info = LRoleDataMgr.Faction.Info
    local myActivity = info.selfActivity
    local totalActivity = info.totalActivity
    local isMyTrue,isTotalTrue = false,false

    for k,v in pairs(self.m_pFactionActivity) do
        if k and v and v.activityList then
            local list = v.activityList
            for i=1,#list do
                local pItem = list[i]
                if k == 1 then
                    if (not isMyTrue) and myActivity >= pItem.activity and pItem.state == 0 then
                        isMyTrue = true
                        Utils:SetRedDotState(RedDotDef.ID.BPHuoYueDu, true)
                    end
                elseif k == 2 then
                    if (not isTotalTrue) and totalActivity >= pItem.activity and pItem.state == 0 then
                        isTotalTrue = true
                        Utils:SetRedDotState(RedDotDef.ID.BPZongHuoYueDu, true)
                    end
                end
            end
        end
    end
    if not isMyTrue then
        Utils:SetRedDotState(RedDotDef.ID.BPHuoYueDu, false)
    end
    if not isTotalTrue then
        Utils:SetRedDotState(RedDotDef.ID.BPZongHuoYueDu, false)
    end
end

-- function LRedDotCheckMgr:qianghuaCheck(level)
--     if level >= LRoleDataMgr.MyHeroInfo.level or level >= #JsonConfig.m_equip_qianghua.getList() then
--         return false
--     end
--     local qhCfg = JsonConfig.m_equip_qianghua.getDefByID(level+1)
--     if qhCfg == nil then
--         return false
--     end
--     return LRoleDataMgr:CheckIsEnough(qhCfg.cost)
-- end

-- function LRedDotCheckMgr:jinglianCheck(level,quality,curexp)
--     if level >= (#JsonConfig.m_equipJingLian.getList()-1)  then
--         return false
--     end
--     local jlCfg = JsonConfig.m_equipJingLian.getDefByID(level)
--     if jlCfg == nil then
--         return false
--     end
--     local quelityCfg = JsonConfig.m_quality.getDefByID(quality)
--     local quelityRate = 1
--     if quelityCfg ~= nil then
--         quelityRate = quelityCfg.jinglian_ratio / 10000
--     end
--     local needExp = math.floor(jlCfg.exp * quelityRate) - curexp
--     local itemCfgs = JsonConfig.GetItemCfgByType(4)
--     local expValue = 0
--     for i=1,#itemCfgs do
--         local cfg = itemCfgs[i]
--         local cnt = LRoleDataMgr.Equip:CountItemNumById(cfg.id)
--         local subValue = cfg.sub_value[1][2]
--         expValue = expValue + cnt*subValue
--         if expValue >= needExp then
--             return true
--         end
--     end
--     return false
-- end

-- function LRedDotCheckMgr:juexingCheck(level)
--     if level >= #JsonConfig.m_equipJueXing.getList() then
--         return false
--     end
--     local jxCfg = JsonConfig.m_equipJueXing.getDefByID(level+1)
--     if jxCfg == nil or jxCfg.cost == nil then
--         return false
--     end
--     for i= 1,#jxCfg.cost do
--         local data = jxCfg.cost[i]
--         if not LRoleDataMgr:CheckIsEnough(data) then
--             return false
--         end
--     end
--     return true
-- end

-- function LRedDotCheckMgr:shenzhuCheck(level,quality,itemId)
--     if quality < 6 or itemId == 0 then
--         return false
--     end
--     if level >= #JsonConfig.m_equipShenZhu.getList() then
--         return false
--     end
--     local szCfg = JsonConfig.m_equip_qianghua.getDefByID(level+1)
--     if szCfg == nil then
--         return false
--     end
--     if not LRoleDataMgr:CheckIsEnough(szCfg.money) then
--         return false
--     end
--     local count = LRoleDataMgr.Equip:CountItemNumById(itemId)
--     if count < szCfg.cost_count then
--         return false
--     end
--     return true
-- end

--装备背包内装备（可以养成）
function LRedDotCheckMgr:PetEquipRedCheck()
    local show = false
    local info = LRoleDataMgr.Pet.equipList.m_petEquips
    for k,v in pairs(info) do
        local cfg = JsonConfig.m_equipConfig.getDefByID(v.m_id)
        if cfg ~= nil then 
            local isqianghua, isjinglian, isjuexing, isshenzhu = self:EquipCultivateRedDotCheck(v.m_uid)
            local result = isqianghua or isjinglian or isjuexing or isshenzhu     
            --强化
            if result then
                show = true
                break
            end
            
        end
    end
    Utils:SetRedDotState(RedDotDef.ID.ZBBeiBao, show)
    --print("LRedDotCheckMgr:PetEquipRedCheck",show)
    return show
end

--装备碎片（可以合成）
function LRedDotCheckMgr:PetEquipPiecesRedCheck()
    local show = false
    local info = LRoleDataMgr.Equip.PackageMap
    if info ~= nil then
        for k,v in pairs(info) do
            if v.m_num > 0 and v.m_id > 0 and v.m_type == AppDef.ItemType.PetEquipFrag then
                --print("PetEquipPieces",v.m_id,v.m_num)
                local cfg = JsonConfig.GetHeChengCfg(4,v.m_id)
                if cfg ~= nil and cfg.item[1][1] == v.m_id and cfg.item[1][3] <= v.m_num then
                    show = true
                    break
                end
            end
        end
    end
    Utils:SetRedDotState(RedDotDef.ID.ZBSuiPian, show)
    --print("LRedDotCheckMgr:PetEquipPiecesRedCheck",show)
    return show
end

--法宝碎片（可以合成）
function LRedDotCheckMgr:PetFaBaoPiecesRedCheck()
	local function getHeChengConfigData(id)
		local heChengList = JsonConfig.m_HeCheng.getList()
		for i=1, #heChengList do
			if heChengList[i].type == AppDef.HeChengType.Cop_FaBao then
				local items = heChengList[i].item
				for j=1, #items do
					local itemData = items[j]
					-- print("itemData ===>", itemData[1])
					if itemData[1] == id then
						return heChengList[i]
					end
				end
			end
		end
		return nil
	end
    local show = false
    local info = LRoleDataMgr.Equip.PackageMap
	local canHeChengFaBaos = {}
    if info ~= nil then
        for k,v in pairs(info) do
            if v.m_num > 0 and v.m_id > 0 and v.m_type == AppDef.ItemType.FaBaoFrag then
                --print("PetEquipPieces",v.m_id,v.m_num)
                local cfg = getHeChengConfigData(v.m_id)
                if cfg ~= nil then
					if canHeChengFaBaos[cfg.id] == nil then
						canHeChengFaBaos[cfg.id] = {}
					end
					for i = 1,#cfg.item do
						if cfg.item[i][1] == v.m_id and cfg.item[i][3] <= v.m_num then
							table.insert(canHeChengFaBaos[cfg.id], true)
						end
					end
					if #canHeChengFaBaos[cfg.id] == #cfg.item then
						show = true
						break
					end
                end
            end
        end
    end
	
    Utils:SetRedDotState(RedDotDef.ID.FBSuiPian, show)
    --print("LRedDotCheckMgr:PetEquipPiecesRedCheck",show)
    return show
end
-- --玩法界面寻宝红点
-- function LRedDotCheckMgr:XunBaoRedCheck()
--     local show = Utils:GetRedDotState(RedDotDef.ID.XunBaoTask) or LRedDotCheckMgr:FaBaoHeChengRedCheck()
--     Utils:SetRedDotState(RedDotDef.ID.XunBao, show)
--     --print("LRedDotCheckMgr:PetEquipPiecesRedCheck",show)
--     return show
-- end

function LRedDotCheckMgr:FaBaoHeChengRedCheck()
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_KAPAI_XUNBAO, true) then
        return false
    end
    local ret = false
    local ids = JsonConfig.GetHeChengIdsByType(8)
    if ids ~= nil and #ids > 0 then
        for i=1,#ids do
            local sign = false
            local cfg = JsonConfig.m_HeCheng.getDefByID(ids[i])
            if cfg ~= nil and cfg.type == 8 then
                sign = true
                for k=1,#cfg.item do
                    local value = cfg.item[k]
                    local num = LRoleDataMgr.Equip:CountItemNumById(value[1])
                    if num < value[3] then
                        sign = false
                        break
                    end
                end
            end
            if sign then
                ret = true
                break
            end
        end
    end
    --print("FaBaoHeChengRedCheck FaBaoHeChengRedCheck",ret)
    Utils:SetRedDotState(RedDotDef.ID.XunBaoHeCheng, ret)
    return ret
end


function LRedDotCheckMgr:PetEquipAllRedCheck()
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_KAPAI_EQUIP_BAG, true) then
        return false
    end
    local ret1 = self:PetEquipRedCheck()
    local ret2 = self:PetEquipPiecesRedCheck()
    local show = ret1 or ret2
    return show
end
-------------------------------------------------------------------------------------------------------
--每日任务-竞技场
function LRedDotCheckMgr:WanFaTaskRedCheck(value)
    local dType = value[1]
    if dType ~= 1 then--竞技场
        return
    end
    local show  = false
    local dValue = value[2]
    for i=1,#dValue do
        if dValue[i].state == 1 then
            show = true
            break
        end
    end
    if dType == 1 then
        Utils:SetRedDotState(RedDotDef.ID.ArenaTask, show)
    end
end
------------------------------------------------------------------------------------------------------
--卡牌新加

--神将背包
function LRedDotCheckMgr:PetBagRedCheck()
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_KAPAI_PET_BAGS, true) then
        return false
    end
    local v = self.mainUIType.btn_shenjiangbeibao
    v[3] = false
    ----print("LRedDotCheckMgr:PetEquipAllRedCheck",show)

    --神将页面升星红点检测
    local function CheckShenJiangTag(  )
    -- body
        --获取数据
        local ownPetList = Utils:deepCopy(LRoleDataMgr.Pet.petlist)
        for k,v in pairs(LRoleDataMgr.Equip:GetPackageMap()) do
            --神将碎片
            if v.m_type == AppDef.ItemType.PetFrag then
                local pidId = PetkaPaiManager:getPetIdByItem(v)
                local isOwnPet = LRoleDataMgr.Pet:IsOwnPetById(pidId)
                if pidId and pidId > 0 and not isOwnPet then
                    local Data = LPetData:New(pidId)
                    Data.isFragment = true
                    table.insert(ownPetList, Data)
                end
            end
        end

        for i=1, #ownPetList do
            local petData = ownPetList[i]
            -- --print("petData ===>", petData.id)

            local isCanStarUp = PetkaPaiManager:isPetCanStarUp(petData)
            if isCanStarUp then
                return true
            end

            if petData == nil or petData.baseData == nil then
                return false
            end

            local itemData = LRoleDataMgr:GetPItemFromBagById(petData.baseData.itemId)

            local isCanHecheng = PetkaPaiManager:isPetCanHeCheng(itemData)
            if isCanHecheng then
                return true
            end
        end

        ownPetList =nil
        return false
    end

    local function CheckSuiPianTag()
        local _ownFragmentList = {}
        for k,v in pairs(LRoleDataMgr.Equip:GetPackageMap()) do
            --神将碎片
            -- dump(v, "PetBagFragmentSubUI:initData ===========>")
            if v.m_type == AppDef.ItemType.PetFrag then
                table.insert(_ownFragmentList, v)
            end
        end

        for i=1, #_ownFragmentList do
            local itemData = _ownFragmentList[i]
            local isPetCanHeCheng = PetkaPaiManager:isPetCanHeCheng(itemData)
            if isPetCanHeCheng then
                return true
            end

            local isCanStarUp = PetkaPaiManager:isPetCanStarUpByItemID( itemData.m_id )
            if isCanStarUp then
                return true
            end
        end

        return false
        
    end

    local isShenJiangShow = CheckShenJiangTag()
    Utils:SetRedDotState(RedDotDef.ID.Shenjiang_tag, isShenJiangShow)
    local isSuiPianShop = CheckSuiPianTag()
    Utils:SetRedDotState(RedDotDef.ID.ShuiPian_tag, isSuiPianShop)

    local tujian = Utils:GetRedDotState(RedDotDef.ID.ShenJiangTuJian)

    local xiuLian = Utils:GetRedDotState(RedDotDef.ID.ShenJiang_XiuLian)

    local isShow = isShenJiangShow or isSuiPianShop or tujian or xiuLian

    print("PetBagRedCheck isShow ====================1 >>", isShow, isShenJiangShow, isSuiPianShop, openLv, xiuLian)
    v[3] = isShow
    self:RedDotShow(v)

    --再检测一次神将图鉴
    if not Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_TUJIAN, true) and not isShow then
        LuaNetSendMsg:QueryRedDot(RedDotDef.SID.ShenJiangTuJian)--神将图鉴
    end

    return isShow
end

function LRedDotCheckMgr:FuBenRedDotCheck()
	if LRoleDataMgr.m_fengshenshilianData == nil then
		LuaNetSendMsg:QueryFengshenShiLian()
		return
	end
	local mylevel = LRoleDataMgr.MyHeroInfo.level
	local funccfg = JsonConfig.m_functionConfig.getDefByID(1020)
	if mylevel < funccfg.open_condition[1][2] then
		return false
	end
	local v = self.mainUIType.btn_fuben
	local datas = LRoleDataMgr.m_fengshenshilianData

	local function CheckFengShengTab(index)
		local data = datas[index]
		local mapdata = JsonConfig.m_FuBenMapConfig.getDefByID(data.shilianId)
		if data.isOpen == false or mylevel < mapdata.OpenLv then
			return false
		end
		
		if data.saodangId > 0 and data.times > 0 then
			return true
		end
		--if data.tiaozhanId > 0 then 
		--	local stagedata = JsonConfig.m_stageNodeConfig.getDefByID(data.tiaozhanId)
		--	if mylevel >= stagedata.Levellimit then
		--		return true
		--	end
		--end
		return false
	end
	local isTab1 = CheckFengShengTab(1)
	Utils:SetRedDotState(RedDotDef.ID.FengShengTab1, isTab1)
	local isTab2 = CheckFengShengTab(2)
	Utils:SetRedDotState(RedDotDef.ID.FengShengTab2, isTab2)
	local isTab3 = CheckFengShengTab(3)
	Utils:SetRedDotState(RedDotDef.ID.FengShengTab3, isTab3)
	local isTab4 = CheckFengShengTab(4)
	Utils:SetRedDotState(RedDotDef.ID.FengShengTab4, isTab4)
	local isFengShenShiLianShow = isTab1 or isTab2 or isTab3 or isTab4
	Utils:SetRedDotState(RedDotDef.ID.FengShenShiLian, isFengShenShiLianShow)
	local ischengjiu = Utils:GetRedDotState(RedDotDef.ID.FuBenAchievement)
	local isShow = isFengShenShiLianShow or ischengjiu
	v[3] = isShow
    self:RedDotShow(v)
end

function LRedDotCheckMgr:WanFaRedDotCheck()
	if LRoleDataMgr.m_kunlunjuezhanData == nil then
		LuaNetSendMsg:QuertKunLunData()
		return
	end
	local mylevel = LRoleDataMgr.MyHeroInfo.level
	local funccfg = JsonConfig.m_functionConfig.getDefByID(7)
	if mylevel < funccfg.open_condition[1][2] then
		return false
	end
	local v = self.mainUIType.btn_wanfa
	local function CheckKunLunJueZhan()
		local kunlundata = LRoleDataMgr.m_kunlunjuezhanData
		local ceng = math.floor((kunlundata.pos-1) / 3) + 1
		if (ceng == 3 and kunlundata.ceng == 4) or kunlundata.zhandou_num == 0 then
			return false
		end
		return true
	end
	local isKunLunJueZhanShow = CheckKunLunJueZhan()
	Utils:SetRedDotState(RedDotDef.ID.KunLunJueZhan, isKunLunJueZhanShow)
	local isShow = isKunLunJueZhanShow
	v[3] = isShow
	-- print("=======================>>>>>>>>>>",v[2]:getName())
    self:RedDotShow(v)
end

function LRedDotCheckMgr:EquipZhenRongRedDotCheck()
	local isreddots = {}
	local petlist = LRoleDataMgr.Pet.ShowPosList
	for i=1,#petlist do
		if petlist[i] ~= 0 then
			local posreds = self:EquipPositionRedDotCheck(i)
			local value = false
			for k,v in pairs(posreds) do
				if v == true then
					value = true
					break
				end
			end
			isreddots[i] = value
		end
	end
	local isShow = false
    if not isShow then
        for k,v in pairs(isreddots) do
            local key = "EquipShengJiang"..k
            Utils:SetRedDotState(RedDotDef.ID[key], v)
            if isShow == false and v == true then
                isShow = true
            end
        end
    end
	self:PetEquipRedCheck()
	local v = self.mainUIType.btn_zhenrong
	v[3] = isShow or Utils:GetRedDotState(RedDotDef.ID.ShenJiangZhenRong)
    self:RedDotShow(v)
    return isShow
end

function LRedDotCheckMgr:EquipPetRedDotCheck(petPos, isoptions)
	local isShow = false
    if not isShow then
        for k,v in pairs(isoptions) do
            if isShow == false and v == true then
                isShow = true
            end
        end
    end
	
	local key = "EquipShengJiang"..petPos
	Utils:SetRedDotState(RedDotDef.ID[key], isShow)
	local v = self.mainUIType.btn_zhenrong
	v[3] = isShow
	self:RedDotShow(v)
    return isShow
end

function LRedDotCheckMgr:EquipPositionRedDotCheck(petPos)
	local isoptions = {}
	local equips = Utils:GetEquipsByfPos(petPos)
	if equips == nil then equips = {} end
	for i = 1,4 do
		local uid = equips[i]
		if uid ~= nil and uid ~= 0 then
			local isqianghua, isjinglian, isjuexing, isshenzhu = self:EquipCultivateRedDotCheck(uid)
			local result = isqianghua or isjinglian or isjuexing or isshenzhu
			if result == false then
				result = self:EquipChangeRedDotCheck(i,uid)
			end
			table.insert(isoptions, result)
		else
			local result = self:EquipChangeRedDotCheck(i,uid)
			table.insert(isoptions, result)
		end
	end
	local fabaos = Utils:GetFaBaoByfPos(petPos)
	if fabaos == nil then fabaos = {} end
	for i = 5,6 do
		local uid = fabaos[i]
		if uid ~= nil and uid ~= 0 then
			local isqianghua, isjinglian = self:FaBaoCultivateRedDotCheck(uid)
			local result = isqianghua or isjinglian
			if result == false then
				result = self:FaBaoChangeRedDotCheck(petPos,uid)
			end
			table.insert(isoptions, result)
		else
			local result = self:FaBaoChangeRedDotCheck(petPos,uid)
			table.insert(isoptions, result)
		end
	end
	return isoptions
end

function LRedDotCheckMgr:EquipCultivateRedDotCheck(uid)
	local money = LRoleDataMgr.MyHeroInfo.DetailData:getMoney()
	local level = LRoleDataMgr.MyHeroInfo.level
	local info = LRoleDataMgr.Pet.equipList.m_petEquips[uid]
	if info.m_fpos == 0 then
		return false, false, false, false
	end
	local function qianghua()
		local data = JsonConfig.m_functionConfig.getDefByID(1120)
		if level < data.open_condition[1][2] then
			return false
		end
		local curLevel = info.cultivateLevel[AppDef.PetEquipLevelType.QiangHua] or 0
		if curLevel >= level * 2 then
			return false
		end
		if curLevel < #JsonConfig.m_equip_qianghua.getList() then 
			curLevel = curLevel + 1 
		else
			return false
		end
		local scfg = JsonConfig.m_equip_qianghua.getDefByID(curLevel)
		local qcfg = JsonConfig.m_quality.getDefByID(info.m_quality)
		if money > scfg.cost[3] * qcfg.qianghua_ratio / 10000 then
			return true
		end
		return false
	end

	local function jinglian()
		local data = JsonConfig.m_functionConfig.getDefByID(1130)
		if level < data.open_condition[1][2] then
			return false
		end
		local curLevel = info.cultivateLevel[AppDef.PetEquipLevelType.JingLian] or 0
		if curLevel >= (#JsonConfig.m_equipJingLian.getList() - 1) then
			return false
		end
		local scfg = JsonConfig.m_equipJingLian.getDefByID(curLevel)
		local qcfg = JsonConfig.m_quality.getDefByID(info.m_quality)
		local cfglist = JsonConfig.m_Item.getList()
		local itemCfg = {}
		for i=1, #cfglist do
			local cfg = cfglist[i]
			if cfg.type == 4 then
				itemCfg[#itemCfg + 1] = cfg
			end
		end
		local allvalue = 0
		for i=1,#itemCfg do
			local cfg = itemCfg[i]
			local num = LRoleDataMgr.Equip:CountItemNumById(cfg.id)
			local subValue = cfg.sub_value[1]
			if num > 0 then
				allvalue = allvalue + subValue[2] * num
			end
			if (allvalue + info.m_jlExp) >= scfg.exp * qcfg.jinglian_ratio / 10000 then
				return true
			end
		end
		return false
	end

	local function juexing()
		local data = JsonConfig.m_functionConfig.getDefByID(1140)
		if level < data.open_condition[1][2] then
			return false
		end
		local curLevel = info.cultivateLevel[AppDef.PetEquipLevelType.JueXing] or 0
		if curLevel < #JsonConfig.m_equipJueXing.getList() then
			curLevel = curLevel + 1 
		else
			return false
		end
		local scfg = JsonConfig.m_equipJueXing.getDefByID(curLevel)
		local moneyCost = {}
		local itemCost = {}
		for i=1,#scfg.cost do
			local cost = scfg.cost[i]
			if cost[1] == 60000 then
				moneyCost = cost
			else
				itemCost[#itemCost + 1] = cost
			end
		end
		local iscoin = false
		if money >= moneyCost[3] then
			iscoin = true
		end
		local isitem = false
		for i=1, #itemCost do
			if itemCost[i][3] <= LRoleDataMgr.Equip:CountItemNumById(itemCost[i][1]) then
				isitem = true
			else
				isitem = false
				break
			end
		end
		return iscoin and isitem
	end

	local function shengzhu()
		local data = JsonConfig.m_functionConfig.getDefByID(1150)
		if level < data.open_condition[1][2] then
			return false
		end
		local curLevel = info.cultivateLevel[AppDef.PetEquipLevelType.ShenZhu] or 0
		if curLevel < #JsonConfig.m_equipShenZhu.getList() then 
			curLevel = curLevel + 1 
		else	
			return false			
		end
		local scfg = JsonConfig.m_equipShenZhu.getDefByID(curLevel)
		local ecfg = JsonConfig.m_equipConfig.getDefByID(info.m_id)
		if money > scfg.money[1][3] and LRoleDataMgr.Equip:CountItemNumById(ecfg.shenzhu_cost) >= scfg.cost_count then
			return true
		end
		return false
	end
	
	local isqianghua = qianghua()
	local isjinglian = jinglian()
	local isjuexing = juexing()
	local isshenzhu = shengzhu()

	return isqianghua, isjinglian, isjuexing, isshenzhu
end

function LRedDotCheckMgr:FaBaoBeiBaoRedDotCheck()
	local isbeibao = false
	for k,v in pairs(LRoleDataMgr.Pet.faBaoList.m_petFaBaos) do
		if v.m_id >= 1000 then
			local isqianghua, isjinglian = self:FaBaoCultivateRedDotCheck(k)
			if isqianghua or isjinglian then
				isbeibao = true
				break
			end
		end
	end
	Utils:SetRedDotState(RedDotDef.ID.FBBeiBao, isbeibao)

	local issuipian = self:PetFaBaoPiecesRedCheck()
	Utils:SetRedDotState(RedDotDef.ID.FBSuiPian, issuipian)
	local isShow = isbeibao or issuipian
	local v = self.mainUIType.btn_fabao
	v[3] = isShow
    self:RedDotShow(v)
	local v = self.mainUIType.btn_chuandai
	v[3] = isShow or Utils:GetRedDotState(RedDotDef.ID.ZhuangBei)
    self:RedDotShow(v)
end

function LRedDotCheckMgr:FaBaoCultivateRedDotCheck(uid)
	local money = LRoleDataMgr.MyHeroInfo.DetailData:getMoney()
	local info = LRoleDataMgr.Pet.faBaoList.m_petFaBaos[uid]
	if info.m_fpos == 0 then
		return false, false
	end

	local function qianghua()
		if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_KAPAI_FABAO_QIANGHUA, true) then
			return false
		end
		local curLevel = info.cultivateLevel[AppDef.PetFaBaoLevelType.QiangHua] or 0
		if curLevel < #JsonConfig.m_faBaoQiangHua.getList() then 
			curLevel = curLevel + 1 
		else
			return false
		end
		local scfg = JsonConfig.m_faBaoQiangHua.getDefByID(curLevel)
		local qcfg = JsonConfig.m_quality.getDefByID(info.baseData.quality)
		local needexp = scfg.exp * qcfg.fabao_qianghua / 10000
		local texp = info.qHExp
		local addexp = 0
		local materialList = {}
		for k,v in pairs(LRoleDataMgr.Pet.faBaoList.m_petFaBaos) do
			if (v.baseData.quality  <= 3 or (v.m_id >= AppDef.fabaoExpItemID.normal_fbExp and v.m_id <= AppDef.fabaoExpItemID.high_fbExp)) and v.m_fpos == 0 then
				local cfg = JsonConfig.m_faBaoConfig.getDefByID(v.m_id)
				table.insert(materialList, cfg)
			end
		end
		local function sortFunc(m1, m2)
			return m1.exp < m2.exp
		end
		table.sort(materialList, sortFunc)
		for i = 1,#materialList do
			local data = materialList[i]
			texp = texp + data.exp
			addexp = addexp + data.exp
			if texp >= needexp and money >= addexp then
				return true
			end
		end
		return false
	end

	local function jinglian()
		if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_KAPAI_FABAO_JINGLIAN, true) then
			return false
		end
		local curLevel = info.cultivateLevel[AppDef.PetFaBaoLevelType.JingLian] or 0
		if curLevel >= #JsonConfig.m_faBaoJingLian.getList() then 
			return false
		end
		local scfg = JsonConfig.m_faBaoJingLian.getDefByID(curLevel)
        if scfg == nil then
            return false
        end
		local cost = scfg.cost
		local itemnum = LRoleDataMgr.Equip:CountItemNumById(cost[1][1])
		if itemnum >= cost[1][3] and money >= cost[2][3] then
			return true
		end
		return false
	end

	local isqianghua = qianghua()
	local isjinglian = jinglian()
	return isqianghua, isjinglian
end

function LRedDotCheckMgr:EquipChangeRedDotCheck(pos, uid)
	if uid == nil then uid = 0 end
	local curData = LRoleDataMgr.Pet.equipList.m_petEquips[uid]
	local equipList = LRoleDataMgr.Pet.equipList.m_petEquips
	for k,v in pairs(equipList) do 
		local data = v
		if data.m_wpos == pos and data.m_fpos == 0 then
			if curData == nil then
				return true
			elseif data.m_quality > curData.m_quality then
				return true
			end
		end
	end
	return false
end

function LRedDotCheckMgr:FaBaoChangeRedDotCheck(fightpos, uid)
	if uid == nil then uid = 0 end
	local fabaos = Utils:GetFaBaoByfPos(fightpos)
	if fabaos == nil then fabaos = {} end
	local curData = LRoleDataMgr.Pet.faBaoList.m_petFaBaos[uid]
	local fabaoList = LRoleDataMgr.Pet.faBaoList.m_petFaBaos
	for k,v in pairs(fabaoList) do 
		local data = v
		if data.m_fpos == 0 and data.m_id > 1000 then
			local iscontain = false
			for m,n in pairs(fabaos) do
				local fdata = LRoleDataMgr.Pet.faBaoList.m_petFaBaos[n]
				if fdata ~= nil and data.m_id == fdata.m_id then
					iscontain = true
					break
				end
			end
			if iscontain == false then
				if curData == nil then
					return true
				elseif data.baseData.quality > curData.baseData.quality then
					return true
				end
			end
		end
	end
	return false
end

LRedDotCheckMgr:Init() 