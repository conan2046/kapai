--[[
lua里面的游戏逻辑控制
]]
local ShopDef = require("View.Shop.ShopDef")
local DateTime = require("Common.DateTime")
local FastActDelegate = require("View.Main.FastActDelegate")
local TimerLabelUI = require("View.Common.TimerLabelUI")
local FunctionButtonDelegateManager = require("View.Main.FunctionButtonDelegateManager")

--------------------------------------------------
local BTN_NAME_ButtonGroup = "ButtonGroup"
--------------------------
--ButtonGroup1
local BTN_NAME_ShenJiang = "btn_zhenrong"
local BTN_NAME_PetBag = "btn_shenjiangbeibao"
local BTN_NAME_PetEquip = "btn_chuandai"
local BTN_NAME_Bag = "btn_Bag"
local BTN_NAME_ZhuJue = "btn_zhujue"

local BTN_NAME_btn_fuben = "btn_fuben"
---------------------------------------------
--ButtonGroup3
local BTN_NAME_WanFa = "btn_wanfa"
local BTN_NAME_Rank = "btn_paihangbang"
local BTN_NAME_ChouKa = "btn_zhaomu"
local BTN_NAME_Bp_Act = "btn_bangpai"
--------------------------------------------
--ButtonGroup4
local BTN_NAME_ShouChong = "btn_shouchong"
local BTN_NAME_PetZhekou = "btn_PetZhekou"
local BTN_NAME_Denglu = "btn_Denglu"
local BTN_NAME_kaifuRank = "btn_kaifuRank"
local BTN_NAME_zhuanpan = "btn_zhuanpan"


--------------------------------------------
--ButtonGroup5
local BTN_NAME_huodong = "btn_huodong"
local BTN_NAME_FL = "btn_fuli"
local BTN_NAME_task = "btn_renwu"
local BTN_NAME_Vip = "btn_guibin"
local BTN_NAME_ShangCheng = "btn_shangcheng"
local BTN_NAME_chongzhi = "btn_chongzhi"
local BTN_NAME_QIRI = "btn_Qiri"

---------------------------------------------
--ButtonGroup6
--金币

------------------------------
--ButtonGroup7
local BTN_NAME_XiTong = "btn_xitong"
local BTN_NAME_mail = "btn_mail"
local BTN_NAME_Friend = "btn_friend"
local BTN_NAME_huishou = "btn_huishou"
---------------------------------------
--ButtonGroup8
local BTN_NAME_Gift = "btn_Libao"
local BTN_NAME_GiftZhekou1 = "btn_Zhekou1"
local BTN_NAME_GiftZhekou2 = "btn_Zhekou2"
local BTN_NAME_GiftZhekou3 = "btn_Zhekou3"
---------------------------------------


local BTN_NAME_ONLINE= "btn_online"

--------------------------------------------------
local MainUI = LUIBase:New()
MainUI.__index = MainUI
MainUI.IsHideInBattle = true
function MainUI:New()
	local o = {}
    setmetatable(o, MainUI)
    o:Init()
	return o
end

function MainUI:Init()
    self.m_pUILayer = cc.CSLoader:createNode("csd/common/UImainLayer_new.csb")
    local frameSize = AppDef.frameSize
    self.m_pUILayer:setContentSize(frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
    
    
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end

    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:initButtonGroup()
    self:initBtns()
    self:InitData()
    self:InitOther()
    self:InitTouchEvt()
    self:ShowHeroInfo()
    -- self:sortButtonGroup(1)
    -- self:sortButtonGroup(2)
    -- self:sortButtonGroup(3)
    -- self:sortButtonGroup(4)
   
    self:QueryDataEnterGame()
    GameSdk:updateQuickPlayerInfo()
    --增加战斗menu
    LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.addBattleMenu)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    performWithDelay(self.m_pUILayer, function(sender)
        local aniNode = cc.CSLoader:createNode("csd/common/UImain_cloudLayer.csb")
        self.m_pUILayer:getChildByName("Bg"):addChild(aniNode);
        local ani = cc.CSLoader:createTimeline("csd/common/UImain_cloudLayer.csb")
        aniNode:runAction(ani)
        ani:gotoFrameAndPlay(0, true)

        LRedDotCheckMgr:CheckAll()
        self:RegisterGuide()
        LRoleDataMgr:CheckPetCompound()
       LRoleDataMgr.m_bIsmainInited = true
    end, 1)

    if AppDef.LOCAL_TEST == true and type(AppDef.LOCAL_TEST_AUTO_OPEN_MODULE) == "number" then
        local autoOpenModule = AppDef.LOCAL_TEST_AUTO_OPEN_MODULE
        performWithDelay(self.m_pUILayer, function()
            Utils:OpenFunction(autoOpenModule, nil, true)
            if autoOpenModule == AppDef.EModuleID.EMID_KAPAI_SHENJIANG
                and AppDef.LOCAL_TEST_AUTO_FORMATION_POPUP == true then
                performWithDelay(AppDef.CurScene, function()
                    Utils:OpenFunction(AppDef.EModuleID.EMID_SJBUZHEN, nil, true)
                    local popupMove = AppDef.LOCAL_TEST_AUTO_FORMATION_MOVE
                    if type(popupMove) == "table" and #popupMove == 2 then
                        performWithDelay(AppDef.CurScene, function()
                            LuaNetSendMsg:QueryFormationChangePos(popupMove[1], popupMove[2])
                        end, 1)
                    end
                end, 3)
            end
            local autoMove = AppDef.LOCAL_TEST_AUTO_FORMATION_MOVE
            if autoOpenModule == AppDef.EModuleID.EMID_SJBUZHEN
                and type(autoMove) == "table" and #autoMove == 2 then
                performWithDelay(self.m_pUILayer, function()
                    LuaNetSendMsg:QueryFormationChangePos(autoMove[1], autoMove[2])
                end, 2)
            end
        end, 2)
    end

    if GameSdk.isFullScreen then
        self:UIAdaptation()
    end
	self.total_time = 200
	self.curTime = 0
	--self:InitScheduler()
    self._totalCoolTime = 2
    self._coolTime = 0
    --self:InitHangUpScheduler()
    -- self:UpdateOnLineTime()
end

function MainUI:InitScheduler()
    --启用一个玩家是否原地挂机的定时器
	local function checkState(dt)
		if self.curTime == -1 then
			return
		end
		------print("=======Scheduler=========", LRoleDataMgr.IsAutoPath)
		if (LRoleDataMgr.MyHeroInfo.sid > 11 and LRoleDataMgr.MyHeroInfo.sid ~= 38 and LRoleDataMgr.MyHeroInfo.sid ~= 47) 
			or LRoleDataMgr.isHangUp == true or LRoleDataMgr.m_bIsInBattle == true or LRoleDataMgr.MyHeroInfo.level <= 38 or LRoleDataMgr.IsAutoPath == true or LRoleDataMgr.MonopolyData.isMonopolyState == true then
			self.curTime = 0
			return
		end
		if self.curTime >= self.total_time then
			--展示日常界面
			Utils:OpenWanfaUI(0)
			self.curTime = -1
		else
			self.curTime = self.curTime + dt
		end
	end
	self.m_SchedulerID = Utils:schedule(nil, checkState, 1, false)
end

function MainUI:InitHangUpScheduler()
    --启用一个玩家是否原地挂机的定时器
    local function checkHangUpState(dt)
        if self._coolTime == -1 then
            return
        end
        ------print("=======Scheduler=========", LRoleDataMgr.MyHeroInfo.sid)
        if LRoleDataMgr.MyHeroInfo.sid > 173 or LRoleDataMgr.MyHeroInfo.sid < 161 or  LRoleDataMgr.MyHeroInfo.sid == 166 or LRoleDataMgr.MyHeroInfo.sid == 168
            or LRoleDataMgr.isHangUp == true or LRoleDataMgr.m_bIsInBattle == true or LRoleDataMgr.IsAutoPath == true or LRoleDataMgr.MonopolyData.isMonopolyState == true then
            self._coolTime = 0
            return
        end

        if self._coolTime >= self._totalCoolTime then
            --开始挂机
            self:HandleHangUp()
            self._coolTime = -1
        else
            self._coolTime = self._coolTime + dt
        end
    end
    self.m_hangUpSchedulerID = Utils:schedule(nil, checkHangUpState, 1, false)
end

function MainUI:QueryDataEnterGame( ... )
    -- body
    -- 体力是主界面基础资源，进入主界面后立即向服务端同步。
    -- 不依赖延迟执行的红点批量查询，避免批量流程中断时一直显示默认值 0。
    LuaNetSendMsg:QueryTiLiInfo(1)
    --折扣商店图标
    -- LuaNetSendMsg:QueryMarketInfo(4,0);
    --七天开服活动换Icon
    LuaNetSendMsg:QueryLingQiButton(20)
    --折扣礼包
    -- LuaNetSendMsg:QueryDiscountBag(86, 1)
    -- LuaNetSendMsg:QueryDiscountBag(87, 1)
    -- LuaNetSendMsg:QueryDiscountBag(88, 1)
    LuaNetSendMsg:QueryDiscountBag(89, 1)
    LuaNetSendMsg:QueryDiscountBag(90, 1)
    LuaNetSendMsg:QueryDiscountBag(91, 1)
end

function MainUI:UpdateUserData(data)
    performWithDelay(self.m_pUILayer, function(sender)
        LRedDotCheckMgr:CheckAll()
    end, 1)
end

function MainUI:InitOther()
    ------------------------------------------------------------------------
    LCheckImproveMgr:getInstance()
    DateTime:getInstance()

    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "PreView.PreViewCheckControl",AppDef.UIType.UnderUI, self.m_pPreviewBtn)
    self:SendMsg(LGameMsg.m_initUIMsg)
    ---------------------------------------------------------------------
    JsonConfig.LoadHeroConfigComplete()
    ------------------------------------------------------------------------
    if LRoleDataMgr.MyHeroInfo.level > 35 then --大于16级关闭引导
        AppDef.OPEN_GUIDE = false
    end
    if AppDef.OPEN_GUIDE then
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Guide.GuideManager", AppDef.UIType.UnderUI)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    ------------------------------------------------------------------------
    performWithDelay(self.m_pUILayer, function(sender)
        local ret = {}
        ret.script = "Guide.GuideLayer"
        Utils:SendMsg(LUILogicEvent.CheckLayerExist, ret)
        if ret.isExist then
            return
        end
        LuaNetSendMsg:QueryMsgHeader()
    end, 1)
    ------------------------------------------------------------------------
    require("View.ImproveUI.RedDotSystem"):New()
    ------------------------------------------------------------------------
    performWithDelay(self.m_pUILayer, function(sender)
        if LRoleDataMgr.MyHeroInfo.level >= 26 then
            -- Utils:OpenFunction(AppDef.EModuleID.EMID_FULI, 0)
        end
    end, 1)
end

function MainUI:onExit()
    LRedDotCheckMgr:ClearAllBtn()
    self:Destory()
    self.m_pUILayer = nil
    self.m_pMainUI = nil
    if  self.m_expSchedulerID ~= nil then
        AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_expSchedulerID)
        self.m_expSchedulerID = nil
    end
    if self.m_sysTimeUpdateEntry ~= nil then
        Utils:unschedule(nil, self.m_sysTimeUpdateEntry)
        self.m_sysTimeUpdateEntry = nil
    end
    -- self.m_pTaskTradkView:onExit()
    -- self.m_pTaskTradkView = nil
    local _ = self.m_actBtnPool and self.m_actBtnPool:onExit()
    self.m_actBtnPool = nil
    local _ = self.m_jijinTimer and self.m_jijinTimer:Destory()
    self.m_jijinTimer = nil

    local _ = self.m_HuoyueJijinTimer and self.m_HuoyueJijinTimer:Destory()
    self.m_HuoyueJijinTimer = nil
    
    local _ = self.m_timerLabel and self.m_timerLabel:Destory()
    self.m_timerLabel = nil
    local _ = self._timerPets and self._timerPets:Destory()
    self._timerPets = nil
    local _ = self._TimerPetss and self._TimerPetss:Destory()
    self._TimerPetss = nil
    local _ = self._TimerLabelChrage and self._TimerLabelChrage:Destory()
    self._TimerLabelChrage = nil
    local _ = self._TimerZhuanPan and self._TimerZhuanPan:Destory()
    local _ = self.timer1 and self.timer1:Destory()
    local _ = self.timer2 and self.timer2:Destory()
    
    self._TimerZhuanPan = nil
    if self.m_pDiscountBagTimer then
        for k,v in pairs(self.m_pDiscountBagTimer) do
            if k and v then
                v:Destory()
                self.m_pDiscountBagTimer[k] = nil
            end
        end
        self.m_pDiscountBagTimer = nil
    end
    Utils:unschedule(nil, self.m_schedulerID)
    Utils:unschedule(nil, self.m_hangUpSchedulerID)
    Utils:unschedule(nil, self.m_EffectSchedulerID)

end

function MainUI:InitData()
    if self.m_pMainUI  == nil then
        self.m_pMainUI = self.m_pUILayer:getChildByName("Main_UI")
    end
    local panel = self.m_pMainUI

    require("View.Main.AutoPlayShiLian"):New()
    
    --头像
    self.m_pHeroHeadPanel = panel:getChildByName("Head")
    self.m_pHeadImg = self.m_pHeroHeadPanel:getChildByName("Icon")

    --等级
    self.m_pLvLabel = self.m_pHeroHeadPanel:getChildByName("bg_Level"):getChildByName("Value")
    --战斗力
    self.m_expSchedulerID = nil
    self.m_curExpRate = 0
    self.m_nextExpRate = {}
    self.m_bIsShowExpAni = false
    self.m_pPowerLabel = self.m_pHeroHeadPanel:getChildByName("bg_CombatEffetiveness"):getChildByName("Value")
    --VIP等级
    self.m_pVipLabel = self.m_pHeroHeadPanel:getChildByName("bg_VIP"):getChildByName("Value")
    self.m_pIsSendPosNodeToC = false

    local name_bg = self.m_pHeroHeadPanel:getChildByName("name_bg")
    self._name = name_bg:getChildByName("name")
    self._name:setString(LRoleDataMgr.MyHeroInfo.name)

    self.m_pShortBtnGp = panel:getChildByName("ShortcutButtonGroup")
    self.m_pShortBtnSx = 0
    self.m_pShortBtnWidth = 0

    self.m_bIsChangingScene = false
    -- local tmp = panel:getChildByName("Target_One")
    -- tmp:setVisible(false)
    -- tmp = panel:getChildByName("Target_More")
    -- tmp:setVisible(false)
    --时间显示 
    self.m_time = 0
    -- self.m_pTimeLabel = self.m_pMapBtn:getChildByName("Time")
    local function OnSysTimeUpdate(dt)
        self:OnSysTimeUpdate(dt)
    end
    self.m_sysTimeUpdateEntry = Utils:schedule(nil, OnSysTimeUpdate, 1, false)
    --AppDef.Director:getScheduler():scheduleScriptFunc(OnSysTimeUpdate, 1.0, false)
    self:OnSysTimeUpdate(0)

    local ButtonGroup6 = panel:getChildByName("ButtonGroup6")
    local Icon_yuanbao = ButtonGroup6:getChildByName("Icon_yuanbao")
    self._GoldValue = Icon_yuanbao:getChildByName("GoldNumBg"):getChildByName("Num")
    local goldAddBtn = Icon_yuanbao:getChildByName("AddBtn")
    goldAddBtn:setEnabled(false)
    self:showMoneyByType(AppDef.AwrdItem.AWRD_ITEM_YUANBAO)

    local Icon_jinbi = ButtonGroup6:getChildByName("Icon_jinbi")
    self._coinValue = Icon_jinbi:getChildByName("NumBg"):getChildByName("Num")
    local coinAddBtn = Icon_jinbi:getChildByName("AddBtn")
    coinAddBtn:addClickEventListener(function ( sender )
        Utils:OpenFunction(AppDef.EModuleID.EMID_SCCHANGYONG)
    end)
    self:showMoneyByType(AppDef.AwrdItem.AWRD_ITEM_COIN)

    local Icon_tili = ButtonGroup6:getChildByName("Icon_tili")
    self._tiliValue = Icon_tili:getChildByName("NumBg"):getChildByName("Num")
    local tiliAddBtn = Icon_tili:getChildByName("AddBtn")
    tiliAddBtn:addClickEventListener(function ( sender )
        -- body
        --购买体力丹
        Utils:OpenUseUI(500,1)--,"arenabuy"
    end)
    self:showMoneyByType(AppDef.AwrdItem.AWRD_ITEM_TILI)

end

function MainUI:showMoneyByType( type )
    --print("MainUI:showMoneyByType",type)
    -- body
    if type == AppDef.AwrdItem.AWRD_ITEM_YUANBAO then
        local myGold = LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao()
        self._GoldValue:setString(myGold)
        --print("tongbao",myGold)
    elseif type == AppDef.AwrdItem.AWRD_ITEM_COIN then
        local myMoney = Utils:getGoldStr()
        self._coinValue:setString(myMoney)
    elseif type == AppDef.AwrdItem.AWRD_ITEM_TILI then
        local tili = LRoleDataMgr.MyHeroInfo:GetDetailData():getTili()
        self._tiliValue:setString(Utils:getTiliStr(tili))
    end
end


function MainUI:SetButtonVisible(functionId, isVisible, isIgnore)
    if functionId == nil then
        return
    end

    local btn = self.m_btnMap[functionId]
    if btn == nil then
        return
    end
    if isIgnore then
        self.m_ignoreFID = self.m_ignoreFID or {}
        self.m_ignoreFID[functionId] = Utils:ToBool(isIgnore)
    end
    if isVisible == nil or Utils:ToBool(isVisible) then
        if LDataConstMgr:isModuleDefaultShow(functionId) or (not Utils:CheckModelNotOpened(functionId, true)) then
            btn:setVisible(true)
            return
        end
    end
    btn:setVisible(false)
end

--[[
注册新手引导
]]
function MainUI:RegisterGuide()
    local function _RegisterGuide(fid, gid, callback,isCheck)
        if fid == nil or gid == nil or callback == nil then  
            return
        end
        local pBtn = self.m_btnMap[fid]
        if pBtn then
            --local isOpen = (not Utils:CheckModelNotOpened(fid, true))
            Utils:RegisterGuide(gid, pBtn, callback, nil, Utils:ToBool(isCheck),true)
        end
    end
    --------------------------------------------------------------------------
    if LRoleDataMgr.MyHeroInfo.level == 1 then
        local isCheck = true
        if LRoleDataMgr.m_bIsInBattle  then
            isCheck = false
        end
        _RegisterGuide(AppDef.EModuleID.EMID_KAPAI_ZHUXIANFUBEN, GuideDef.StepId.Guide_FuBen, handler(self, MainUI.FuBenTouchCallback),isCheck)
    end
    _RegisterGuide(AppDef.EModuleID.EMID_KAPAI_ZHUXIANFUBEN, GuideDef.StepId.Guide_Pet_11, handler(self, MainUI.FuBenTouchCallback),true)
    _RegisterGuide(AppDef.EModuleID.EMID_KAPAI_ZHUXIANFUBEN, GuideDef.StepId.Guide_FuBen2_11, handler(self, MainUI.FuBenTouchCallback),true)
    _RegisterGuide(AppDef.EModuleID.EMID_KAPAI_ZHUXIANFUBEN, GuideDef.StepId.Guide_FuBen3_11, handler(self, MainUI.FuBenTouchCallback),true)
    _RegisterGuide(AppDef.EModuleID.EMID_KAPAI_ZHUXIANFUBEN, GuideDef.StepId.Guide_Equip_10, handler(self, MainUI.FuBenTouchCallback),true)
    _RegisterGuide(AppDef.EModuleID.EMID_KAPAI_ZHUXIANFUBEN, GuideDef.StepId.Guide_Pet1_Finish, handler(self, MainUI.FuBenTouchCallback),true)
    _RegisterGuide(AppDef.EModuleID.EMID_KAPAI_ZHUXIANFUBEN, GuideDef.StepId.Guide_XunBao_Finish, handler(self, MainUI.FuBenTouchCallback),true)
    --------------------------------------------------------------------------
    _RegisterGuide(AppDef.EModuleID.EMID_KAPAI_SHENJIANG, GuideDef.StepId.Guide_Pet_6, handler(self, MainUI.PetTouchCallback),true)
    _RegisterGuide(AppDef.EModuleID.EMID_KAPAI_SHENJIANG, GuideDef.StepId.Guide_FuBen2_4, handler(self, MainUI.PetTouchCallback),true)
    _RegisterGuide(AppDef.EModuleID.EMID_KAPAI_SHENJIANG, GuideDef.StepId.Guide_FuBen3_4, handler(self, MainUI.PetTouchCallback),true)
    _RegisterGuide(AppDef.EModuleID.EMID_KAPAI_SHENJIANG, GuideDef.StepId.Guide_Equip_2, handler(self, MainUI.PetTouchCallback),true)
    _RegisterGuide(AppDef.EModuleID.EMID_KAPAI_SHENJIANG, GuideDef.StepId.Guide_Pet1_2, handler(self, MainUI.PetTouchCallback),true)
    _RegisterGuide(AppDef.EModuleID.EMID_KAPAI_SHENJIANG, GuideDef.StepId.Guide_XunBao_9, handler(self, MainUI.PetTouchCallback),true)
    --------------------------------------------------------------------------
    _RegisterGuide(AppDef.EModuleID.EMID_WANFA, GuideDef.StepId.Guide_Arena_2, handler(self, MainUI.WanFaCallback),true)
    _RegisterGuide(AppDef.EModuleID.EMID_WANFA, GuideDef.StepId.Guide_XunBao_2, handler(self, MainUI.WanFaCallback),true)
    --------------------------------------------------------------------------
    _RegisterGuide(AppDef.EModuleID.EMID_KAPAI_CHOUKA, GuideDef.StepId.Guide_Pet_2, handler(self, MainUI.LuckDrawTouchCallback),true)
    --------------------------------------------------------------------------
    _RegisterGuide(AppDef.EModuleID.EMID_KAPAI_PET_BAGS, GuideDef.StepId.Guide_Tujian_1, handler(self, MainUI.PetBagCallBack))
end

--[[
初始化功能按钮
]]
function MainUI:initBtns()
    ------------------------------------------------------------------------
    self.m_idMap = {}
    self.m_btnMap = {} 
    self.m_btnMap[AppDef.EModuleID.EMID_KAPAI_ZHUXIANFUBEN] = self.m_buttonGroupMap[BTN_NAME_btn_fuben]--副本
    self.m_btnMap[AppDef.EModuleID.EMID_KAPAI_CHOUKA] = self.m_buttonGroupMap[BTN_NAME_ChouKa]--招募
    self.m_btnMap[AppDef.EModuleID.EMID_KAPAI_SHENJIANG] = self.m_buttonGroupMap[BTN_NAME_ShenJiang]--阵容
    self.m_btnMap[AppDef.EModuleID.EMID_WANFA] = self.m_buttonGroupMap[BTN_NAME_WanFa]--玩法
    self.m_btnMap[AppDef.EModuleID.EMID_KAPAI_PET_BAGS] = self.m_buttonGroupMap[BTN_NAME_PetBag]--神将背包
	self.m_btnMap[AppDef.EModuleID.EMID_KAPAI_ZHUJUE] = self.m_buttonGroupMap[BTN_NAME_ZhuJue]--主角
end
--[[
初始化按钮分组
]]
function MainUI:initButtonGroup()
    if self.m_pMainUI == nil then
        self.m_pMainUI = self.m_pUILayer:getChildByName("Main_UI")
    end
    local panel = self.m_pMainUI
    local pButtonGroup1 = panel:getChildByName("ButtonGroup1")
    local pButtonGroup3 = panel:getChildByName("ButtonGroup3")
    local pButtonGroup4 = panel:getChildByName("ButtonGroup4")
    local pButtonGroup5 = panel:getChildByName("ButtonGroup5")
    local pButtonGroup6 = panel:getChildByName("ButtonGroup6")
    local pButtonGroup7 = panel:getChildByName("ButtonGroup7")
    local pButtonGroup8 = panel:getChildByName("ButtonGroup8")
    ------------------------------------------------------------------------
    self.m_buttonGroupMap = {}
    self.m_buttonGroup = {{},{},{},{},{},{},{},{}}

    table.insert(self.m_buttonGroup[1], pButtonGroup1:getChildByName(BTN_NAME_ShenJiang))
    table.insert(self.m_buttonGroup[1], pButtonGroup1:getChildByName(BTN_NAME_PetBag))
    table.insert(self.m_buttonGroup[1], pButtonGroup1:getChildByName(BTN_NAME_PetEquip))
    table.insert(self.m_buttonGroup[1], pButtonGroup1:getChildByName(BTN_NAME_Bag))
	table.insert(self.m_buttonGroup[1], pButtonGroup1:getChildByName(BTN_NAME_ZhuJue))
    ------------------------------------------------------------------------
    table.insert(self.m_buttonGroup[3], pButtonGroup3:getChildByName(BTN_NAME_Rank))
    table.insert(self.m_buttonGroup[3], pButtonGroup3:getChildByName(BTN_NAME_ChouKa))
    table.insert(self.m_buttonGroup[3], pButtonGroup3:getChildByName(BTN_NAME_Bp_Act))
    ------------------------------------------------------------------------
    table.insert(self.m_buttonGroup[4], pButtonGroup4:getChildByName(BTN_NAME_ShouChong))
    table.insert(self.m_buttonGroup[4], pButtonGroup4:getChildByName(BTN_NAME_QIRI))
    table.insert(self.m_buttonGroup[4], pButtonGroup4:getChildByName(BTN_NAME_PetZhekou))
    table.insert(self.m_buttonGroup[4], pButtonGroup4:getChildByName(BTN_NAME_Denglu))
    table.insert(self.m_buttonGroup[4], pButtonGroup4:getChildByName(BTN_NAME_kaifuRank))
    table.insert(self.m_buttonGroup[4], pButtonGroup4:getChildByName(BTN_NAME_zhuanpan))
    -----------------------------------------------------------------------------------
    table.insert(self.m_buttonGroup[5], pButtonGroup5:getChildByName(BTN_NAME_huodong))
    table.insert(self.m_buttonGroup[5], pButtonGroup5:getChildByName(BTN_NAME_FL))
    table.insert(self.m_buttonGroup[5], pButtonGroup5:getChildByName(BTN_NAME_task))
    table.insert(self.m_buttonGroup[5], pButtonGroup5:getChildByName(BTN_NAME_ShangCheng))
    table.insert(self.m_buttonGroup[5], pButtonGroup5:getChildByName(BTN_NAME_Vip))
    table.insert(self.m_buttonGroup[5], pButtonGroup5:getChildByName(BTN_NAME_chongzhi))
    
    --------------------------------------------------------------------------------
    table.insert(self.m_buttonGroup[7], pButtonGroup7:getChildByName(BTN_NAME_XiTong))
    table.insert(self.m_buttonGroup[7], pButtonGroup7:getChildByName(BTN_NAME_mail))
    table.insert(self.m_buttonGroup[7], pButtonGroup7:getChildByName(BTN_NAME_Friend))
    table.insert(self.m_buttonGroup[7], pButtonGroup7:getChildByName(BTN_NAME_huishou))
    --------------------------------------------------------------------------------
    table.insert(self.m_buttonGroup[8], pButtonGroup8:getChildByName(BTN_NAME_Gift))
    table.insert(self.m_buttonGroup[8], pButtonGroup8:getChildByName(BTN_NAME_GiftZhekou1))
    table.insert(self.m_buttonGroup[8], pButtonGroup8:getChildByName(BTN_NAME_GiftZhekou2))
    table.insert(self.m_buttonGroup[8], pButtonGroup8:getChildByName(BTN_NAME_GiftZhekou3))


    --------------------------------------------------------------------------------

    self.m_buttonGroupMap[BTN_NAME_WanFa] = panel:getChildByName(BTN_NAME_WanFa)
    self.m_buttonGroupMap[BTN_NAME_btn_fuben] = panel:getChildByName(BTN_NAME_btn_fuben)
    ------------------------------------------------------------------------
    self.m_buttonGroupMap[BTN_NAME_ButtonGroup..1] = pButtonGroup1
    -- self.m_buttonGroupMap[BTN_NAME_ButtonGroup..2] = pButtonGroup2
    self.m_buttonGroupMap[BTN_NAME_ButtonGroup..3] = pButtonGroup3
    self.m_buttonGroupMap[BTN_NAME_ButtonGroup..4] = pButtonGroup4
    self.m_buttonGroupMap[BTN_NAME_ButtonGroup..5] = pButtonGroup5
    self.m_buttonGroupMap[BTN_NAME_ButtonGroup..6] = pButtonGroup6
    self.m_buttonGroupMap[BTN_NAME_ButtonGroup..7] = pButtonGroup7
    self.m_buttonGroupMap[BTN_NAME_ButtonGroup..8] = pButtonGroup8


    ------------------------------------------------------------------------
    for i=1,#self.m_buttonGroup do
        for j=1,#self.m_buttonGroup[i] do
            local pBtn = self.m_buttonGroup[i][j]
            if pBtn then
                self.m_buttonGroupMap[pBtn:getName()] = pBtn
            end
        end
    end
end

function MainUI:GetButtonByName(index, name)
	local panel = self.m_pMainUI
    local pButtonGroup = panel:getChildByName("ButtonGroup"..index)
	return pButtonGroup:getChildByName(name)
end
--[[
根据分组排列按钮位置
]]
function MainUI:sortButtonGroup(ind, time)
    if ind == nil then
        return
    end

    --temp code
    if ind == 8 then
        return
    end

    if ind < 1 or ind > #self.m_buttonGroup then
        return
    end
    local panel = self.m_buttonGroupMap[BTN_NAME_ButtonGroup..ind]
    if panel == nil then
        return
    end
    local space = 0
    local buttons = self.m_buttonGroup[ind]
    local temp = {}
    for i=1,#buttons do
        local btn = buttons[i]
        if btn and btn:isVisible() and btn:getParent() then
            table.insert(temp, btn)
        end
    end
    if ind == 1 then
        Utils:AlignNodes(panel, temp, {space}, 1, false, time)
    elseif ind == 3 or ind == 4 then
        Utils:AlignNodes(panel, temp, {space}, 2, false, time)
    elseif ind == 2 then
        -- Utils:AlignNodes(panel, temp, {space}, 4, false, time)
    elseif ind == 6 and self.m_pFastActDelegate ~= nil then
        self.m_pFastActDelegate:SortActButtonGroup()
    elseif ind == 7 then
        Utils:AlignNodes(panel, temp, {space}, 1, false, time)
    elseif ind == 8 then
        Utils:AlignNodes(panel, temp, {space}, 1, false, time)
    elseif ind == 5 then
        Utils:AlignNodes(panel, temp, {space}, 2, false, time)
    end
end

function MainUI:OnSysTimeUpdate(dt)
    self.m_time = self.m_time + dt
    if self.m_time >= 1*60.0 then
        self.m_time = 0.0
        LuaNetSendMsg:QuerySYSTime()
        LuaNetSendMsg:QueryHeart()
    end
    if self.m_pTimeLabel == nil then
        --return
    end
    --更新系统时间
    LDataConstMgr.m_serverTime = LDataConstMgr.m_serverTime +dt
    local str = LDataConstMgr:GetSysTimeStr()
    if self.m_checkNextDay == nil then
        self.m_checkNextDay = true
    end
    local arr = string.split(str, ":")
    if #arr > 0 then
        local num = tonumber(arr[1])
        if self.m_checkNextDay then
            if num == 0 then
--使用跨天协议
                self:GetUserData()
                self.m_checkNextDay = false
            end
        elseif num == 23 then
            self.m_checkNextDay = true
        end
    end
    --self.m_pTimeLabel:setString(str)

    self:updateUIData(dt)
end

function MainUI:updateUIData( dt )
    -- body

    if self.m_pRebateStoreBtn == nil then
        return
    end

    if not self.m_pRebateStoreBtn:isVisible() then
        return
    end

    LRoleDataMgr.m_DisCountShopEndTime = LRoleDataMgr.m_DisCountShopEndTime - 1
    if LRoleDataMgr.m_DisCountShopEndTime <= 0 then
        self.m_pRebateStoreBtn:setVisible(false)
    end
end

function MainUI:GetUserData()
    -- ----print("MainUI:GetUserData=======================>")
   -- LuaNetSendMsg:QueryWelFareInfo(0xff, 0)--刷新活动列表
    --任务
   -- LuaNetSendMsg:QueryUnGetTaskList(4)--可接任务追踪列表
    --福利信息查询
    --LuaNetSendMsg:QueryKaifuHuodong(7,3)--请求等级礼包的奖励
	print("=============GetUserData================>>>>>>>>>>>")
    LuaNetSendMsg:QueryLoginGift(5,1)--登陆奖励
	--LuaNetSendMsg:QueryJingJieInfo(1) --境界
   -- LuaNetSendMsg:QueryOnlineAward()
   -- LuaNetSendMsg:QueryOfflineExpInfo()
   -- LuaNetSendMsg:QueryDailySignInfo()

    --帮派
   -- if LRoleDataMgr.Faction.Info.id > 0 then
   --     LuaNetSendMsg:QueryFactionTaskList()
   -- end
    --首充、次充
   -- LuaNetSendMsg:QueryKaifuHuodong(9,2)
   -- LuaNetSendMsg:QueryKaifuHuodong(42,2)

    --七日活动, 更新开服时间
   LuaNetSendMsg:QuerySeverOpenTime()
end

--[[
显示人物总战斗力
]]
function MainUI:ShowHeroPower()
    local powerValue, isWan = Utils:getNewPowerStr(LRoleDataMgr.MyHeroInfo.zhanDouLiInAll);
    self.m_pPowerLabel:setString(powerValue);
    if isWan == true then
        self.m_pPowerLabel:getChildByName("Wan"):setVisible(true)
        self.m_pPowerLabel:getChildByName("Wan"):setPositionX(self.m_pPowerLabel:getContentSize().width)
    else
        self.m_pPowerLabel:getChildByName("Wan"):setVisible(false)
    end
    -- self.m_pPowerLabel:setString(Utils:getPowerStr(LRoleDataMgr.MyHeroInfo.zhanDouLiInAll))
end

function MainUI:ShowVipLv()
    self.m_pVipLabel:setString(GUITips.RSI_VIP_ITEM .. LRoleDataMgr.MyHeroInfo.MyVIPInfo.vipLevel)
end

--[[
显示人物等级
]]
function MainUI:ShowHeroLv()
    self.m_pLvLabel:setString(LRoleDataMgr.MyHeroInfo.level)


end

--[[
初始化的时候显示人物信息
]]
function MainUI:ShowHeroInfo()
    local heroData = LRoleDataMgr.MyHeroInfo
    --等级
    self:ShowHeroLv()
    self:ShowHeroExp()
    --战斗力

    self:ShowHeroPower()
    self:ShowVipLv()
    self:ShowHeroHead()
end

function MainUI:ShowHeroHead()
    local heroData = LRoleDataMgr.MyHeroInfo
    local str = AppDef:GetHeroPicFileName(LRoleDataMgr.MyHeroInfo.head,AppDef.HeadType.HERO_IMAGE_HEAD_ROUND)
    self.m_pHeadImg:loadTexture(str,ccui.TextureResType.localType)
    --self.m_pHeadImg:setScale(0.8)
end

--[[
注册UI消息
]]
function MainUI:RegistMsgs()
    self.msgIds = 
    {
        LUIMainEvent.ShowUI,
        LUIMainEvent.HideUI,
        LUILogicEvent.ChangeScene,
        LUIMapEvent.ChangeMapSuccess,
        LUIRoleDataChangeEvent.ExpChanged,
        LUIRoleDataChangeEvent.LvUp,
        LUIRoleDataChangeEvent.VIPChanged,
        LUIRoleDataChangeEvent.PowerChanged,
        LUIRoleTeamEvent.ApplyListChanged,
        LUIActivityEvent.ShenshouState,
        LUIActivityEvent.ShenshouFinish,
        LUIMainEvent.ClickNearHeros,
        LUIBangPaiEvent.EnterBPPlantArea,
        LUIMainEvent.ShowImproveBtn,
        LUIMailEvent.NewMail,
        LUIMailEvent.delAllMail,
        LUIMainEvent.CheckFirstRechargeBtn,
        LUIActivityEvent.LeaveShilian,
        LUIMainEvent.OpenOrCloseBtmBtn,
        LUIMainEvent.GetMainBtnPos,
        LUIMainEvent.ISOpenBtmBtn,
        LUIFunctionEvent.FunctionOpen,
        LUIRoleDataChangeEvent.StartHangUp,
        LUIRoleDataChangeEvent.StopHangUp,
        LUIFunctionEvent.FunctionStartFly,
        LUIFunctionEvent.FunctionFinishFly,
        LUIFunctionEvent.PushFuncOpenList,
        LUIGuideEvent.PreGuide,
        LUIMainEvent.GetMapName,
        LUISkillEvent.SkillNewUnLock,
        LUIMainEvent.WorshipEvent,
        LUIHorseEvent.AddNewHorse,
        LUILogicEvent.ShowGuide,
        LUIGiveGiftEvent.showXianhua,
        LUIMainEvent.ChangeHookEvent,
        LUIMainEvent.CheckFactionBtn,
        LUIMainEvent.ShowActivityIcon,
        LUIShopEvent.UpdateDiscountShop,
        LUIFundRebateEvent.LoadDataEvent,
        LUIHuoyueLayerEvent.LoadDataEvent,
        LUITaskDataEvent.GetCompletedTask,
        LUITaskDataEvent.TaskCellTouchPos,
        LUIActivityEvent.RefreshFirstRechargeUI,
        LUIMainEvent.SetFuncBtnVisible,
        LUIPlatinumEvent.updateBuyPlatinum,
        LUILogicEvent.updatePreViewUI,
        LUIMiJingEvent.UpdateDataEvent,
        LUILogicEvent.DataTimeEvent,
        LUIRoleDataChangeEvent.CheckOpenBuffTips,
        LUIRoleDataChangeEvent.ClickBuffItem,
        LUIRoleDataChangeEvent.UpdateBuffTime,
		LUILogicEvent.RoleActiveGame,
		LUILogicEvent.IsAutoPath,
        LUIMainEvent.ChangeDayMsg,
        LUIRoleDataChangeEvent.MoneyChanged,
        LUIRoleDataChangeEvent.TongBaoChanged,
        LUIRoleDataChangeEvent.TiliChanged,
        LOnLineEvent.GetReward,
        LOnLineEvent.DeleteTimeFun,
        LOnLineEvent.AddTimeFun,
        LOnLineEvent.UpdateTime,
        LUILogicEvent.changeNameSuc,
        LUILogicEvent.ExitBattle,
        LUIMainEvent.UpdateDiscountBag,
    }
    self:RegistSelf(self,self.msgIds)
end

function MainUI:SetMapName(name)
    -- self.m_pCurName = name
    -- if self.m_pMapNameLabel then
    --     if LRoleDataMgr.m_bIsCrossServer then
    --         self.m_pMapNameLabel:setString(GUITips.CrossServer .. "-" .. name)
    --     else
    --         self.m_pMapNameLabel:setString(name)
    --     end
        
    --     if LRoleDataMgr.MyHeroInfo.SceneType ~= AppDef.SceneType.MSI_FACTION_ZONE then
    --         self.m_pMapNameLabel:setTextColor(UICOLOR_WHITE)
    --     end
    -- end
end

function MainUI:StartChangeScene()
    self.m_bIsChangingScene = true
end


function MainUI:ChangeMapSuccess(mapName)
    
end

--检查任务、组队框是否显示
function MainUI:CheckQuestTeamPanelVisible(sceneType)
    if sceneType == nil then return true end
    if sceneType == AppDef.SceneType.MSI_NORMAL 
        or sceneType == AppDef.SceneType.MSI_CROSSSERVER 
        or sceneType == AppDef.SceneType.MSI_FACTION_ZONE 
        or sceneType == AppDef.SceneType.MSI_FACTION_WAR
        or sceneType == AppDef.SceneType.MSI_FACTION_WAR_PRE then

        return true
    end
    return false   
end

--[[
检查退出副本按钮是否显示
]]
function MainUI:CheckQuitCopyBtnVisible()
    local panel = self.m_pMainUI
    ----------------------------------------------------
    
    -- 处理上一个场景的显示
    if self.m_laseSceneType == AppDef.SceneType.MSI_KUNLUN then
        self:KunlunShanShow(false)
    elseif self.m_laseSceneType == AppDef.SceneType.MSI_FLYFARY then
        self:FlyFaryShow(false)
    elseif self.m_laseSceneType == AppDef.SceneType.MSI_FISHROOM then
        self:FishShow(false)
    elseif self.m_laseSceneType == AppDef.SceneType.MSI_FACTION_ZONE then
        self:FactionZone(false)
    elseif self.m_laseSceneType == AppDef.SceneType.MSI_LEITAISAI then
        self:LeiTaiSaiShow(false)
    elseif self.m_laseSceneType == AppDef.SceneType.MSI_LUNDAO then
        self:LunDaoShow(false)
    elseif self.m_laseSceneType == AppDef.SceneType.MSI_FACTION_WAR then
        self:UpdateHurtButton(false)
    elseif self.m_laseSceneType == AppDef.SceneType.MSI_SHENJIEMIJING then
        self:MiJingShow(false)
    end

    ----------------------------------------------------
    local sceneType = LRoleDataMgr.MyHeroInfo.SceneType
    local isNomal = (sceneType == AppDef.SceneType.MSI_NORMAL or sceneType == AppDef.SceneType.MSI_CROSSSERVER)

    local btngp2 = self._panelQuestAndTeam
    local _ = btngp2 and btngp2:setVisible(self:CheckQuestTeamPanelVisible(sceneType))
    local btngp1 = self.m_buttonGroupMap[BTN_NAME_ButtonGroup..1]
    local _ = btngp1 and btngp1:setVisible(isNomal)
    local btngp6 = self.m_buttonGroupMap[BTN_NAME_ButtonGroup..6]
    local _ = btngp6 and btngp6:setVisible(isNomal)
    local btngp7 = self.m_buttonGroupMap[BTN_NAME_ButtonGroup..7]
    local _ = btngp7 and btngp7:setVisible(isNomal)
    -- self.m_pFuncBtnDelegateManager:SetCtrlButtionVisible(1, isNomal)
    ----------------------------------------------------
    if sceneType == AppDef.SceneType.MSI_KUNLUN then
        self:KunlunShanShow(true)
    elseif sceneType == AppDef.SceneType.MSI_FISHROOM then
        self:FishShow(true)
    elseif sceneType == AppDef.SceneType.MSI_FACTION_ZONE then
        self:FactionZone(true)
    elseif sceneType == AppDef.SceneType.MSI_LEITAISAI then
        self:LeiTaiSaiShow(true)
        Utils:SendMsg(LUIChatEvent.intoLeiTaiSai)
    elseif sceneType == AppDef.SceneType.MSI_LUNDAO then
        self:LunDaoShow(true)
    elseif sceneType == AppDef.SceneType.MSI_FACTION_WAR then
        Utils:SendMsg(LUITaskDataEvent.ShowTaskPanel, false)
        self:UpdateHurtButton(true)
--		LuaNetSendMsg:QueryBangPaiWarInfo(3)
        LuaNetSendMsg:QueryBangPaiWarInfo(8)
        LuaNetSendMsg:QueryBangPaiWarInfo(7)
    elseif sceneType == AppDef.SceneType.MSI_FACTION_WAR_PRE then
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "BangPai.BangPaiWarMenuUI",AppDef.UIType.SpecialLayer)
        self:SendMsg(LGameMsg.m_initUIMsg)
        Utils:SendMsg(LUITaskDataEvent.ShowTaskPanel, true)
        LuaNetSendMsg:QueryBangPaiWarInfo(2)
        LGameMsg.m_baseMsg:ChangeEventId(LUITaskDataEvent.ChangeTeamTab)
        self:SendMsg(LGameMsg.m_baseMsg)
    elseif sceneType == AppDef.SceneType.MSI_SHENJIEMIJING then
        self:MiJingShow(true)
    end

    if sceneType ~= AppDef.SceneType.MSI_FACTION_WAR and  sceneType ~=  AppDef.SceneType.MSI_FACTION_WAR_PRE then
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "BangPai.BangPaiWarMenuUI")
	    self:SendMsg(LGameMsg.m_initUIMsg)
    end
    ----------------------------------------------------
    self.m_laseSceneType = sceneType

    if isNomal or sceneType == AppDef.SceneType.MSI_FACTION_ZONE then
        Utils:SendMsg(LUIActivityEvent.ExitFuBen)
    else
        Utils:SendMsg(LUIActivityEvent.EnterFubBen)
    end

    if LRoleDataMgr.m_bLastCrossServerState and LRoleDataMgr.m_bIsCrossServer then
        self:CrossServer(true)
    elseif LRoleDataMgr.m_bLastCrossServerState and not LRoleDataMgr.m_bIsCrossServer then
        LRoleDataMgr.m_bLastCrossServerState = false
        self:CrossServer(false)
    end
end

--[[
处理昆仑山的显示
]]
function MainUI:KunlunShanShow(isIn)
    if isIn then -- 进去了
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Activity.KunlunShanUI",AppDef.UIType.Normal)
        self:SendMsg(LGameMsg.m_initUIMsg)
        self.m_ChangeRoomBtn:setVisible(true)
    else -- 出来了
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.KunlunShanUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.RoomChangeUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
        self.m_ChangeRoomBtn:setVisible(false)
    end
end

--[[
处理飞仙战场的显示
]]
function MainUI:FlyFaryShow(isIn)
    if isIn then -- 进去了
        -- if LDataConstMgr.m_FlyFaryInfo == nil then -- 没有获取过数据
        --     LuaNetSendMsg:QueryFlyFaryField(1)
        --     return
        -- end
        -- LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Activity.FlyFaryUI",AppDef.UIType.Normal)
        -- self:SendMsg(LGameMsg.m_initUIMsg)
    else -- 出来了
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.FlyFaryUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
end

--[[
跨服切换
]]
function MainUI:CrossServer(isIn)

    local panel = self.m_pMainUI
    
    local btngp2 = self.m_buttonGroupMap[BTN_NAME_ButtonGroup..2]
    local _ = btngp2 and btngp2:setVisible(not isIn)
    local btngp7 = self.m_buttonGroupMap[BTN_NAME_ButtonGroup..7]
    local _ = btngp7 and btngp7:setVisible(self:GetPreviewShow())

    if isIn then -- 进去了
        self:SetButtonVisible(AppDef.EModuleID.EMID_BANGPAI, LRoleDataMgr.MyHeroInfo.FactionId > 0, 1)
        self:SetButtonVisible(AppDef.EModuleID.EMID_JINGJI, false, 1)
        self:SetButtonVisible(AppDef.EModuleID.EMID_HUODONG, false, 1)
        self:sortButtonGroup(self.m_idMap[AppDef.EModuleID.EMID_BANGPAI])
        self:sortButtonGroup(self.m_idMap[AppDef.EModuleID.EMID_JINGJI])
    else -- 出来了
        self:SetButtonVisible(AppDef.EModuleID.EMID_BANGPAI, true, 0)
        self:SetButtonVisible(AppDef.EModuleID.EMID_JINGJI, true, 0)
        self:SetButtonVisible(AppDef.EModuleID.EMID_HUODONG, true, 0)
        self:sortButtonGroup(self.m_idMap[AppDef.EModuleID.EMID_BANGPAI])
        self:sortButtonGroup(self.m_idMap[AppDef.EModuleID.EMID_JINGJI])
        self:sortButtonGroup(self.m_idMap[AppDef.EModuleID.EMID_HUODONG])
    end
end
--[[
钓鱼的显示
]]
function MainUI:FishShow(isIn)
    local panel = self.m_pMainUI
    local pLockBtn = panel:getChildByName("locker")
    if isIn then -- 进去了
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Activity.FishUI",AppDef.UIType.UnderUI)
        self:SendMsg(LGameMsg.m_initUIMsg)
        
        self.m_ChangeRoomBtn:setVisible(true)

        local panel1 = self.m_buttonGroupMap[BTN_NAME_ButtonGroup..1]
        local _ = panel1 and panel1:setVisible(true)
        -- self.m_pFuncBtnDelegateManager:SetCtrlButtionVisible(1, true)
        
        self:SetButtonVisible(AppDef.EModuleID.EMID_FUBEN, false, 1)
        self:SetButtonVisible(AppDef.EModuleID.EMID_PAIHANGBANG, false, 1)
        self:SetButtonVisible(AppDef.EModuleID.EMID_JINGJI, false, 1)
        self:SetButtonVisible(AppDef.EModuleID.EMID_MUBIAO, false, 1)
        self:SetButtonVisible(AppDef.EModuleID.EMID_GUAJI, false, 1)
        self:sortButtonGroup(1)
        self:sortButtonGroup(8)

        local ret = {}
        self:getOpenBtmBtnOpenOrNot(ret)
        if ret.isOpen then
            self:openOrCloseBtmBtnNew(false, true)
            self.m_recoveLocker = true
        end
    else -- 出来了
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.FishUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
        
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.RoomChangeUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
        
        self.m_ChangeRoomBtn:setVisible(false)
        
        self:SetButtonVisible(AppDef.EModuleID.EMID_FUBEN, true, 0)
        self:SetButtonVisible(AppDef.EModuleID.EMID_PAIHANGBANG, true, 0)
        self:SetButtonVisible(AppDef.EModuleID.EMID_JINGJI, true, 0)
        self:SetButtonVisible(AppDef.EModuleID.EMID_MUBIAO, true, 0)
        self:SetButtonVisible(AppDef.EModuleID.EMID_GUAJI, true, 0)
        self:sortButtonGroup(1)
        self:sortButtonGroup(8)
        
        if self.m_recoveLocker then
            self:openOrCloseBtmBtnNew(true, true)
            self.m_recoveLocker = nil
        end
    end
end
--[[
帮派领地
]]
function MainUI:FactionZone(isIn)
    isIn = Utils:ToBool(isIn)
    local function setVisible(btn, isVisible)
        if btn == nil then
            return
        end
        btn:setVisible(isVisible)
    end
    setVisible(self.m_buttonGroupMap[BTN_NAME_Bp_Act], isIn and LRoleDataMgr.Faction:IsPlantFactionBelongMe())
    setVisible(self.m_buttonGroupMap[BTN_NAME_Bp_GodTree], isIn and LRoleDataMgr.Faction:IsPlantFactionBelongMe())
    setVisible(self.m_buttonGroupMap[BTN_NAME_Bp_Shop], isIn and LRoleDataMgr.Faction:IsPlantFactionBelongMe())
    setVisible(self.m_buttonGroupMap[BTN_NAME_Bp_List], isIn)
    if not isIn then
        Utils:DeleteUI("BangPaiZone.BangPaiZoneUI")
    end
    self:sortButtonGroup(5)
end
--[[
擂台赛
]]
function MainUI:LeiTaiSaiShow(isIn)
    if isIn then -- 进去了
        Utils:InitUI("Activity.LeiTaiSaiUI", AppDef.UIType.Normal)
    else -- 出来了
        Utils:DeleteUI("Activity.LeiTaiSaiUI")
    end
end
--[[
神界论道
]]
function MainUI:LunDaoShow(isIn)
    if isIn then -- 进去了
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Activity.LunDaoUI",AppDef.UIType.Normal)
        self:SendMsg(LGameMsg.m_initUIMsg)
        
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Team.TeamMainUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    else -- 出来了
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.LunDaoUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.RoomChangeUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    self.m_ChangeRoomBtn:setVisible(isIn)
    self:UpdateHurtButton(isIn)
end
--[[
神界秘境
]]
function MainUI:MiJingShow(isIn)
    if isIn then -- 进去了
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.MiJingUI")
        self:SendMsg(LGameMsg.m_initUIMsg)

        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Activity.MiJingLayer",AppDef.UIType.Normal)
        self:SendMsg(LGameMsg.m_initUIMsg)
    else -- 出来了
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.MiJingLayer")
        self:SendMsg(LGameMsg.m_initUIMsg)
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.RoomChangeUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    self.m_ChangeRoomBtn:setVisible(isIn)
    self:UpdateHurtButton(isIn)
end


function MainUI:UpdateHurtButton(isVisible)
    local pHurtBtn = self.m_buttonGroupMap[BTN_NAME_Hurt]
    if pHurtBtn == nil then
        return
    end
    pHurtBtn:setVisible(isVisible)
    self:sortButtonGroup(5)
    if isVisible then
        local temp = {
        [AppDef.SceneType.MSI_LUNDAO] = "res/UI/Icon/ui_main_icon/ui_main_icon_jifen.png",
        [AppDef.SceneType.MSI_FACTION_WAR] = "res/UI/Icon/ui_main_icon/ui_main_icon_jifen.png",
        [AppDef.SceneType.MSI_SHENJIEMIJING] = "res/UI/Icon/ui_main_icon/ui_main_icon_shanghaibang.png",
        }
        local sceneType = LRoleDataMgr.MyHeroInfo.SceneType
        if temp[sceneType] then
            pHurtBtn:loadTextureNormal(temp[sceneType], UI_TEX_TYPE_PLIST)
        end
    end
end

function MainUI:ShowHeroExp()
    local data = LRoleDataMgr.MyHeroInfo

    local nextExp = LDataConstMgr:GetHeroLevelUpExp(data.level)
    local expRate = data.DetailData.exp/nextExp
    if expRate < 0 or expRate > 1 then
        expRate = 0
    end
    expRate = expRate * 100
    self.m_pUILayer:findChildByName("Main_UI/Head/EXPBar"):setPercent(expRate);
end

function MainUI:HandleHeroLvUp(addExp)
    self:ShowHeroLv()
    LRedDotCheckMgr:RedDotLevelCheck()
end

function MainUI:ShowFirstRechargeTips()
    -- body
    if self._isInitFirstRech and self._isInitFirstRech == true then
        return
    end
    local roleLv = LRoleDataMgr.MyHeroInfo:Getlevel()
    local data = LRechargeDataMgr:GetFirstRechargeData()
--    ----print("ShowFirstRechargeTips", roleLv, data.isPaid, self._isInitFirstRech)
    if roleLv <= AppDef.FirstRecharge.show_Lv5 and not data.isPaid then
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Recharge.FirstRechargeTips",AppDef.UIType.Normal)
        self:SendMsg(LGameMsg.m_initUIMsg)
        self._isInitFirstRech = true
    end
end

--[[
自动护送按钮不需要了，直接点击任务追踪
]]
function MainUI:SetEscortBtnVisible()
    -- if LRoleDataMgr.MyHeroInfo.ConvoyType ~= 1 then
    --     self.m_husongBtn:setVisible(false)
    --     return
    -- else
    --     self.m_husongBtn:setVisible(true)
    -- end

    -- local Data = LRoleDataMgr.MyHeroInfo.m_Convoy
    -- local text = self.m_husongBtn:getChildByName("Text")
    -- if Data.IsAutoYunShou then
    --     text:setString(GUITips.RSI_Auto_YunShou_true)
    -- else
    --     text:setString(GUITips.RSI_Auto_YunShou_false)
    --     LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.RoleEvent.BreakMove)
    --     self:SendMsg(LGameMsg.m_cBaseMsg)
    -- end

    -- if LRoleDataMgr.MyHeroInfo.m_Convoy.IsAutoYunShou then
    --     local function AutoPachEndCallback(npcId, npcIdx)
    --         -- ----print("AutoPachEndCallback",npcId,npcIdx,"op=",op,"opVal",opVal)
    --         LRoleDataMgr.MyHeroInfo.m_Convoy.IsAutoYunShou = false
    --         if npcId ~= nil and npcIdx ~= nil then
    --             LuaNetSendMsg:QueryNpcChatOpen(npcId, npcIdx,LRoleDataMgr.MyHeroInfo.m_Convoy.taskId)
    --             LuaNetSendMsg:QueryConvoyNote()
    --         end
    --     end

    --     local Data = LRoleDataMgr.MyHeroInfo.m_Convoy
    --     LGameMsg.m_autoPathMsg:ChangeToStart(Data.taskId,-1,-1,0,bit.lshift(Data.npcId,16),true,false,AutoPachEndCallback)
    --     self:SendMsg(LGameMsg.m_autoPathMsg)
    -- end
end

function MainUI:EscortFinish()
    local function ok()
        EnterBtnTouched(AppDef.EActivityID.EAID_CONVOY)
    end

    local function cancel()
    end
    local data = LRoleDataMgr.MyHeroInfo.m_Convoy
	    local NUM
    if data.AvaNum > 0 then
        NUM=data.AvaNum-1
    else
        NUM=0
    end
    local userData =
    {
        okCallback = ok,
        cancelCallback = cancel,
        desc = string.format(GUITips.RSI_Husong_Tips_Format, NUM)
    }
	if NUM > 0 then
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Common.MsgBoxUI",AppDef.UIType.FirstClassLayer, userData)
        LUIManager:SendMsg(LGameMsg.m_initUIMsg)
    else
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Common.MsgBoxUI",AppDef.UIType.SecondClassLayer, userData)
        LUIManager:SendMsg(LGameMsg.m_initUIMsg)
    end
end

function MainUI:ProcessEvent(msg)
    local function quitCallback()
        -- self.levelTime
        if self.levelTime == 0 then
            local secneType = LRoleDataMgr.MyHeroInfo.SceneType
            if secneType == AppDef.SceneType.MSI_SHILIAN then
                LuaNetSendMsg:QueryCopyExit()
            end
        else
            Utils:ShowScrollTips(string.format(GUITips.RSI_GMN_TIP27, self.levelTime))
            self.levelTime = self.levelTime - 1
        end
    end
    
    local msgId = msg:GetMsgId()
    if msgId == LUIMainEvent.ShowUI then
        self.m_pUILayer:setVisible(true)
    elseif msgId == LUIMainEvent.HideUI then
        self.m_pUILayer:setVisible(false)
    elseif msgId == LUIMapEvent.ChangeMapSuccess then
        self:ChangeMapSuccess(msg.value)
    elseif msgId == LUILogicEvent.ChangeScene then
        self:StartChangeScene()
    elseif msgId == LUIRoleDataChangeEvent.ExpChanged then
        --self:ShowHeroExp(true,false, msg.value)
        self:ShowHeroExp()
    elseif msgId == LUIRoleDataChangeEvent.LvUp then
        self:HandleHeroLvUp(msg.value)
        self:ShowFirstRechargeTips()
        GameSdk:updateQuickPlayerInfo()
    elseif msgId == LUIRoleDataChangeEvent.PowerChanged then
        self:ShowHeroPower()
    elseif msgId == LUIRoleDataChangeEvent.VIPChanged then
        self:ShowVipLv()
    elseif msgId == LUIRoleTeamEvent.ApplyListChanged then
        self:SetTeamApplyBtnVisible(msg.value)
    elseif msgId == LUIActivityEvent.ShenshouState then
        self:SetEscortBtnVisible()
    elseif msgId == LUIActivityEvent.ShenshouFinish then
        self:EscortFinish()
    elseif msgId == LUIMainEvent.ClickNearHeros then
        self:ClickNearHeros(msg:GetOp(), msg:GetHeroList())
    elseif msgId == LUIBangPaiEvent.EnterBPPlantArea then
        self:FactionZone(true)
        if LRoleDataMgr.Faction:IsPlantFactionBelongMe() then
            -- self:SetMapName(GUITips.RSI_FACTION_MSG111)
            -- self.m_pMapNameLabel:setTextColor(UICOLOR_GRAYM)
        else
            -- self:SetMapName(LRoleDataMgr.Faction:GetPlantFactionName())
            -- self.m_pMapNameLabel:setTextColor(UICOLOR_RED)
        end
    elseif msgId == LUIMainEvent.ShowImproveBtn then
        --称号现在不再提示
        if true then
            return
        end
        self:setImproveBtnVisible(msg.value)
    elseif msgId == LUIMailEvent.NewMail then
        self:setNewMailBtnVisible()
    elseif msgId == LUIMailEvent.delAllMail then
        self:setNewMailBtnNoVisible()
    elseif msgId == LUIRoleDataChangeEvent.StopHangUp then
        -- self:SetHangUpBtnState(true)
    elseif msgId == LUIRoleDataChangeEvent.StartHangUp then
        -- self:SetHangUpBtnState(false)
    elseif msgId == LUIMainEvent.CheckFirstRechargeBtn--[[ or msgId == LUIRoleDataChangeEvent.TongBaoChanged]] then
        self:CheckFirstRechargeBtn()
    elseif msgId == LUIActivityEvent.LeaveShilian then
        self.levelTime = msg.value
        quitCallback()
    elseif msgId == LUIMainEvent.OpenOrCloseBtmBtn then
       self:openOrCloseBtmBtnNew(msg.value)
    elseif msgId == LUIMainEvent.GetMainBtnPos then
        self:getMainBtnPos(msg.value)
    elseif msgId == LUIMainEvent.ISOpenBtmBtn then
        self:getOpenBtmBtnOpenOrNot(msg.value)
    elseif msgId == LUIFunctionEvent.FunctionOpen then
        self:dealFunctionOpen(msg.value)
    elseif msgId == LUIFunctionEvent.FunctionStartFly then
        self:dealFunctionStartFly(msg.value)
    elseif msgId == LUIFunctionEvent.FunctionFinishFly then
        self:dealFunctionFinishFly(msg.value)
    elseif msgId == LUIFunctionEvent.PushFuncOpenList then
        self:dealPushFuncOpenList(msg.value)
    -- elseif msgId == LUIGuideEvent.PreGuide then
    --     self:dealGuideCheck(msg.value)
    elseif msgId == LUIMainEvent.GetMapName then
        if type(msg.value) == "table" then
            msg.value.mapName = self.m_pCurName
        end
    elseif msgId == LUISkillEvent.SkillNewUnLock then
        local ret = {}
        ret.script = "Guide.GuideLayer"
        local pMsg = LUIMsg1.New(LUILogicEvent.InitUI)
        pMsg:Change(LUILogicEvent.CheckLayerExist, ret)
        self:SendMsg(pMsg)
        if ret.isExist then
            return
        end
        
        -- LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "ImproveUI.SkillOpenUI",AppDef.UIType.PopWindow, msg.value)
        -- self:SendMsg(LGameMsg.m_initUIMsg)
    elseif msgId == LUIMainEvent.WorshipEvent then
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Arena.WarshipUI",AppDef.UIType.FirstClassLayer)
        self:SendMsg(LGameMsg.m_initUIMsg)

    elseif msgId == LUIHorseEvent.AddNewHorse or msgId == LUIWingDataEvent.GotNewWing or msgId == LUIShenQiEvent.ShenQiStateChanged then
        local iType = nil
        --BUG 1522 解锁新的坐骑，新的翅膀的时候，自动穿上
        if msgId == LUIHorseEvent.AddNewHorse then
            iType = AppDef.AwrdItem.AWRD_ITEM_HORSE
            LuaNetSendMsg:QueryHorseRideInfo(4, msg.value)--发送骑乘消息
        elseif msgId == LUIWingDataEvent.GotNewWing then
            iType = AppDef.AwrdItem.AWRD_ITEM_WINDS
            LuaNetSendMsg:QueryChiBangInfo(3, msg.value)
            LRedDotCheckMgr:MainWingCheck()
        elseif msgId == LUIShenQiEvent.ShenQiStateChanged then
            iType = AppDef.AwrdItem.AWRD_ITEM_ARTIFACT
            LuaNetSendMsg:SendShenQiReq(2, msg.value, 2)
        end
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "LuckyDraw.LGetPetWingManager", AppDef.UIType.PopWindow, {type=iType,data=msg.value})
        self:SendMsg(LGameMsg.m_initUIMsg)
    -- elseif msgId == LUILogicEvent.ShowGuide then
    --     local data = msg.value
    --     if data and data.stepId then
    --         local temp = {  GuideDef.StepId.Guide_DZ, 
    --                         GuideDef.StepId.Guide_SHEJ, 
    --                         GuideDef.StepId.Guide_ZM, 
    --                         GuideDef.StepId.Guide_SHENJ,
    --                         GuideDef.StepId.Guide_JJ,
    --                         GuideDef.StepId.Guide_DSZL,
    --                         GuideDef.StepId.Guide_FL,
    --                     }
    --         if Utils:containValue(temp, data.stepId) then
    --             LGameMsg.m_baseMsg:ChangeEventId(LUILogicEvent.CloseAllPopup)
    --             self:SendMsg(LGameMsg.m_baseMsg)
    --         end
    --     end
    elseif msgId == LUIGiveGiftEvent.showXianhua then
        if LUserConfigMgr:getShieldXianHuaPar() == 1 then
            return
        end
        local id = msg.value.itemId 
        if id == 2989 then
            local BiaoBaiEffect = require("View.Social.xianhuapar_biaobai")
            BiaoBaiEffect:Init(AppDef.CurScene)
            BiaoBaiEffect:playAction()
        elseif id == 2990 then
            local HehuaEffect = require("View.Social.xianhuapar_hehua")
            HehuaEffect:Init(AppDef.CurScene)
            HehuaEffect:playAction()
        else
            LRoleDataMgr.Social:createEffectAnim(id)
        end
    elseif msgId == LUIMainEvent.ChangeHookEvent then
        self:HandleHangUp()
    elseif msgId == LUIMainEvent.CheckFactionBtn then
        self:CheckFactionBtn()
    elseif msgId == LUIMainEvent.ShowActivityIcon then
        self:ShowActivityIcon(msg.value)
    elseif msgId == LUIShopEvent.UpdateDiscountShop then
        self:UpdateDiscountIcon()
    elseif msgId == LUIFundRebateEvent.LoadDataEvent then
        -- self:DealFundRebateData(msg.value)
    elseif msgId == LUIHuoyueLayerEvent.LoadDataEvent then
        self:DealHuoyueFundRebateData(msg.value)
    elseif msgId == LUITaskDataEvent.GetCompletedTask then
--        self:beginExpEffect()
    elseif msgId == LUITaskDataEvent.TaskCellTouchPos then
        self._isShouldShowEffect = true
        self._taskEffcetPos = msg.value
    elseif msgId == LUIActivityEvent.RefreshFirstRechargeUI then
        self:ShowFirstRechargeTips()
    elseif msgId == LUIMainEvent.SetFuncBtnVisible then
        local fid = msg.value.functionId
        local isVisible = msg.value.isShow
        self:SetButtonVisible(fid, isVisible, Utils:ToBool(isVisible) and 0 or 1)
        local group = self.m_idMap[fid]
        if group then
            self:sortButtonGroup(group)
        end
    elseif msg.msgId == LUIPlatinumEvent.updateBuyPlatinum then
        -- self:RefreshPreview()
    elseif msg.msgId == LUILogicEvent.updatePreViewUI then
        -- self:RefreshPreview()
    elseif msg.msgId == LUIMiJingEvent.UpdateDataEvent then
        self:DealMiJingData(msg.value)
    elseif msg.msgId == LUIMainEvent.UpdateDiscountBag then
        self:DealDiscountBagData(msg.value)
    elseif msg.msgId == LUILogicEvent.DataTimeEvent then
        local data = msg.value
        if data and data.t and data.t == DateTime.hour then
            --折扣礼包
            -- LuaNetSendMsg:QueryDiscountBag(86, 1)
            -- LuaNetSendMsg:QueryDiscountBag(87, 1)
            -- LuaNetSendMsg:QueryDiscountBag(88, 1)
            LuaNetSendMsg:QueryDiscountBag(89, 1)
            LuaNetSendMsg:QueryDiscountBag(90, 1)
            LuaNetSendMsg:QueryDiscountBag(91, 1)
        end
    elseif msg.msgId==LUIRoleDataChangeEvent.CheckOpenBuffTips then
        if self.IsClickBuffItem and msg.value then 
           Utils:ShowBuffTips(msg.value)
           self.IsClickBuffItem=false
        end
    elseif msg.msgId==LUIRoleDataChangeEvent.ClickBuffItem then
       self.IsClickBuffItem=true
    elseif msg.msgId==LUIRoleDataChangeEvent.UpdateBuffTime then

	elseif msg.msgId==LUILogicEvent.RoleActiveGame then
		self.curTime = 0
        self._coolTime = 0
	elseif msg.msgId==LUILogicEvent.IsAutoPath then
		------print("--------------------autopath-------------",msg.value)
		LRoleDataMgr.IsAutoPath = msg.value
    elseif msg.msgId == LUIMainEvent.ChangeDayMsg then
        --跨天刷新
        self:GetUserData()
    elseif msg.msgId == LUIRoleDataChangeEvent.MoneyChanged then
        self:showMoneyByType(AppDef.AwrdItem.AWRD_ITEM_COIN)
    elseif msg.msgId == LUIRoleDataChangeEvent.TongBaoChanged then
        self:showMoneyByType(AppDef.AwrdItem.AWRD_ITEM_YUANBAO)
    elseif msg.msgId == LUIRoleDataChangeEvent.TiliChanged then
        self:showMoneyByType(AppDef.AwrdItem.AWRD_ITEM_TILI)
    elseif  msg.msgId == LOnLineEvent.GetReward then
        self:OnLineClicked()
    elseif msg.msgId==LOnLineEvent.DeleteTimeFun then
        self.m_finishFunCB=nil
        self.m_updateFunCB=nil

    elseif msg.msgId==LOnLineEvent.AddTimeFun then
        self.m_finishFunCB=msg.value.finish
        self.m_updateFunCB=msg.value.update
    elseif msg.msgId== LOnLineEvent.UpdateTime then
        --print("执行LOnLineEvent.UpdateTime")
        self:UpdateOnLineTime() 
    elseif msg.msgId == LUILogicEvent.changeNameSuc then
        self._name:setString(LRoleDataMgr.MyHeroInfo.name)
    elseif msg.msgId == LUILogicEvent.ExitBattle then
        if LRoleDataMgr.MyHeroInfo.level == 1 then
            Utils:CheckGuide(GuideDef.StepId.Guide_FuBen)
        end
    end  
end

--[[
设置挂机按钮状态
@param1:state false开始挂机 true取消挂机
]]
function MainUI:SetHangUpBtnState(state)
    if self.m_bIsChangingScene then
        self.m_hangUpState = state
        return
    end
    self.m_hangUpState = nil
    local iconRes = "res/UI/Icon/ui_main_icon/ui_main_icon_guaji.png"
    if not state then
        iconRes = "res/UI/Icon/ui_main_icon/ui_main_icon_quxiaoguaji.png"
    end
    self.m_pHangUpBtn:loadTextureNormal(iconRes,ccui.TextureResType.plistType)
end

--显示、隐藏首充按钮
function MainUI:CheckFirstRechargeBtn()
    if LRoleDataMgr.m_bIsCrossServer then
        return
    end

    if self.m_bIsChangingScene then
        self.m_checkRechargeState = true
        return
    end

    self.m_checkRechargeState = nil

    local state = LRoleDataMgr.m_firstRechargeState
    --显示首充
    print("CheckFirstRechargeBtn", LRoleDataMgr.m_firstRechargeState)
    local temp_bg = self.m_pFirstRechargeBtn:getChildByName("temp_bg")
    if state == 0 then
        local isFirstOpen = (not Utils:ToBool(LRoleDataMgr:GetSettingConfig(
            AppDef.ServerSetIndex.SSI_FIRST_OPEN_SC)))
        if isFirstOpen then
            Utils:OpenFunction(AppDef.EModuleID.EMID_RECHARGE_SHOWCHONG)
            LuaNetSendMsg:DealMsgSaveSettingInfo(AppDef.ServerSetIndex.SSI_FIRST_OPEN_SC, 1)
        end
        -- self:SetButtonVisible(AppDef.EModuleID.EMID_RECHARGE_SHOWCHONG, true)
        self.m_pFirstRechargeBtn:setVisible(true)
        -- self.m_pFirstRechargeBtn:loadTextureNormal("res/UI/Icon/ui_main_icon/ui_main_icon_shouchong.png",ccui.TextureResType.plistType)
        -- Utils:safeLoa
        -- Utils:SafeLoadTexture(temp_bg, "res/UI/Icon/ui_main_icon/ui_main_icon_shouchong.png" ,ccui.TextureResType.plistType)
        self.m_pFirstRechargeBtn:getChildByName("temp_text"):setString("首充")
    else
        if LRoleDataMgr.m_secondRechargeState == 0 then
            -- self.m_pFirstRechargeBtn:loadTextureNormal("res/UI/Icon/ui_main_icon/ui_main_icon_cichong.png",ccui.TextureResType.plistType)
            -- self:SetButtonVisible(AppDef.EModuleID.EMID_RECHARGE_SHOWCHONG,true)
            self.m_pFirstRechargeBtn:getChildByName("temp_text"):setString("次充")
            -- Utils:SafeLoadTexture(temp_bg, "res/UI/Icon/ui_main_icon/ui_main_icon_cichong.png" ,ccui.TextureResType.plistType)
            self.m_pFirstRechargeBtn:setVisible(true)
        else
            -- self:SetButtonVisible(AppDef.EModuleID.EMID_RECHARGE_SHOWCHONG,false)
            self.m_pFirstRechargeBtn:setVisible(false)
        end
        if LRoleDataMgr.m_DisCountShopEndTime > 0 then
            self.m_pRebateStoreBtn:setVisible(true)
        end
    end
end

function MainUI:ClickNearHerosInFactionWar(enemyData)
    if enemyData == nil then return end
    if enemyData:GetFactionId() == LRoleDataMgr.MyHeroInfo.FactionId then
        self:ShowOneHeroTarget(enemyData)
        return
    end
    local id = enemyData:GetId()
--    local teamId = enemyData:GetTeamId()
--    if teamId > 0 and enemyData:IsTeamPause() == false then
--        id = teamId
--    end
    if id > 0 then
        LuaNetSendMsg:SendBangPaiWarAttack(id)
    end
end

function MainUI:ClickNearHerosInFaction(enemyData, noCheckFaction)
    --是否攻击XXX(Lv.51)?
    local tipMsg = ""
    local enemyFactionName = enemyData:GetFactionName()
    if (not Utils:ToBool(noCheckFaction)) and string.len(enemyFactionName) > 0 then
        tipMsg = string.format(GUITips.RSI_GM_TIP1, enemyFactionName, enemyData:GetName(), enemyData:GetLv())
    else
        tipMsg = string.format(GUITips.RSI_GM_TIP2, enemyData:GetName(), enemyData:GetLv())
    end
    local pid = enemyData:GetId()
    local function OKCallback()
        LuaNetSendMsg:QueryFactionZonePK(pid)
    end
    local function cancelCallback()
    end

    local msgData = 
    {
        okCallback = OKCallback,
        cancelCallback = cancelCallback,
        desc = tipMsg,
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIMsgBoxEvent.ShowMsgBox, msgData)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function MainUI:ClickNearHeros(op, herList)
    if op == 1 then
        --[[
        组队时候队员点击的时候回触发，相当于提示玩家组队不能寻路
        ]]
        Utils:ShowScrollTips(GUITips.UI_Team_Member_ClickMap_Tip)
        return
    end
    if herList == nil or #herList < 1 then
        self.m_pHeroTgtsPanel:setVisible(false)
        self.m_pHeroTgtHead:setVisible(false)
        return
    end
    if LRoleDataMgr.MyHeroInfo:IsTeam() == true 
        and LRoleDataMgr.MyHeroInfo:IsLeader() == false
        and LRoleDataMgr.MyHeroInfo:IsTeamPause() == false then
        Utils:ShowScrollTips(GUITips.UI_Team_Member_ClickMap_Tip)
        return
    end
    local st = LRoleDataMgr.MyHeroInfo:GetSceneType()
    if st == AppDef.SceneType.MSI_FLYFARY then
        --飞仙战场屏蔽
        return
    end
    if #herList>= 1 then        
        if st == AppDef.SceneType.MSI_FACTION_ZONE and 
            LRoleDataMgr.MyHeroInfo.FactionId ~= herList[1]:GetFactionId() then--帮派领地
            self:ClickNearHerosInFaction(herList[1])
            return
        elseif st == AppDef.SceneType.MSI_FACTION_WAR then
            self:ClickNearHerosInFactionWar(herList[1])
            return
        elseif st == AppDef.SceneType.MSI_SHENJIEMIJING then
            local id = herList[1]:GetId()
            local teamId = herList[1]:GetTeamId()
            local serZoneId = herList[1]:GetSerZoneId()
            if LRoleDataMgr.MyHeroInfo:GetSerZoneId() ~= serZoneId then
                self:ClickNearHerosInFaction(herList[1], true)
                return
            end
        end
    end

    if #herList == 1 then
        self:ShowOneHeroTarget(herList[1])
    else
        self:ShowHeroTargetList(herList)
    end
end

--[[
被选中玩家是否在护送状态
]]
function MainUI:IsTargetHusong(heroData)
    if heroData:IsInHuSongState() == false then
        return false
    end

    local tipMsg = ""
    local enemyFactionName = heroData:GetFactionName()
    if string.len(enemyFactionName) > 0 then
        tipMsg = string.format(GUITips.RSI_GM_TIP1, enemyFactionName, heroData:GetName(), heroData:GetLv())
    else
        tipMsg = string.format(GUITips.RSI_GM_TIP2, heroData:GetName(), heroData:GetLv())
    end
    local pid = heroData:GetId()
    local function OKCallback()
        LuaNetSendMsg:QueryConvoyFight(pid)
    end
    local function cancelCallback()
    end

    local msgData = 
    {
        okCallback = OKCallback,
        cancelCallback = cancelCallback,
        desc = tipMsg,
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIMsgBoxEvent.ShowMsgBox, msgData)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)


    return true
end

function MainUI:ShowOneHeroTarget(cherodata)
    if self:IsTargetHusong(cherodata) then
        return
    end

    self.m_pHeroTgtHead:stopAllActions()
    self.m_pHeroTgtsPanel:setVisible(false)
    self.m_pHeroTgtHead:setVisible(true)
    self.m_pHeroTgtHead:setTouchEnabled(true)
    local hid = cherodata:GetId()
    
    local function HeroCallback(sender)
        local worldPos = sender:getParent():convertToWorldSpace(cc.p(sender:getPositionX(), sender:getPositionY()));
        local showPos = cc.p(worldPos.x - 306 - sender:getContentSize().width / 2, worldPos.y + 180)
        self:SceneHeroClicked(cherodata, showPos)
        --self.m_pHeroTgtHead:setVisible(false)
    end
    self.m_pHeroTgtHead:addClickEventListener(HeroCallback)
	self:MarkIntaractCObj(self.m_pHeroTgtHead)
    local imgHead = self.m_pHeroTgtHead:getChildByName("Icon")

    local str = AppDef:GetHeroPicFileName(cherodata:GetProfessional(),AppDef.HeadType.HERO_IMAGE_HEAD)
    imgHead:loadTexture(str,ccui.TextureResType.localType)

    local lvLabel = self.m_pHeroTgtHead:getChildByName("Level")
    lvLabel:setString(cherodata:GetLv())
    local function HideHeroIcon()
        self.m_pHeroTgtHead:setVisible(false)
    end
    --Utils:DelayToCallFunc(self.m_pHeroTgtHead,5,HideHeroIcon)
    
end

function MainUI:ShowHeroTargetList(herolist)

    if self:IsTargetHusong(herolist[1]) then
        return
    end

    self.m_pHeroTgtsPanel:setVisible(true)
    self.m_pHeroTgtsPanel:stopAllActions()
    self.m_pHeroTgtHead:setVisible(false)
    -- local function HideHeroIcon()
    --     self.m_pHeroTgtsPanel:setVisible(false)
    -- end
    -- Utils:DelayToCallFunc(self.m_pHeroTgtsPanel,5,HideHeroIcon)

    local function HeroCallback(sender)
        local hid = sender:getTag()
        local heroData = sender.userObject
        local worldPos = sender:getParent():convertToWorldSpace(cc.p(sender:getPositionX(), sender:getPositionY()));
        local showPos = cc.p(worldPos.x - 306 - sender:getContentSize().width / 2, worldPos.y + 180)
        self:SceneHeroClicked(heroData, showPos)
        
        --self.m_pHeroTgtsPanel:setVisible(false)
    end
    self.m_pHeroTgtListView:removeAllItems()
    for i = 1, #herolist do
        local heroBtn = self.m_pHeroTgtCell:clone()
        local imgHead = heroBtn:getChildByName("Icon")
        local str = AppDef:GetHeroPicFileName(herolist[i]:GetProfessional(),AppDef.HeadType.HERO_IMAGE_HEAD)
        imgHead:loadTexture(str,ccui.TextureResType.localType)

        local lvLabel = heroBtn:getChildByName("Name")
        lvLabel:setString(herolist[i]:GetName())
        self.m_pHeroTgtListView:pushBackCustomItem(heroBtn)
        heroBtn:setTag(herolist[i]:GetId())
        heroBtn.userObject = herolist[i]
        heroBtn:addClickEventListener(HeroCallback)
		self:MarkIntaractCObj(heroBtn)
    end
    
end

function MainUI:InitTouchEvt()
    local panel = self.m_pMainUI
--    panel:setTouchEnabled(false)
    panel:setTouchEnabled(true)
    panel:setSwallowTouches(false)
    panel:addClickEventListener(function(sender)
        local sceneType = LRoleDataMgr.MyHeroInfo.SceneType
        if sceneType == AppDef.SceneType.MSI_FACTION_WAR then
            if LRoleDataMgr.m_isNPCCollecting then
                ------print("33333333333333333333333333333333333333333333")
                LuaNetSendMsg:QueryBangPaiWarInfo(10)
            end
        end
        
        LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.interruptCollectUI, nil)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)

		LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, false)
		self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end)
	self:MarkIntaractCObj(panel)
    local roleBtn = panel:getChildByName("Head")

    local bagBtn = self.m_buttonGroupMap[BTN_NAME_Bag]
    self:SetButtonVisible(AppDef.EModuleID.EMID_BEIBAO)
    local function RoleTouchCallback(sender)

        -- local function Test()
        --     LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Role.RoleMainUI",AppDef.UIType.FirstClassLayer,1)
        --     self:SendMsg(LGameMsg.m_initUIMsg)
        -- end
        -- local function Test2()
        --     LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Role.RoleMainUI")
        --     self:SendMsg(LGameMsg.m_initUIMsg)
        -- end

        -- Utils:TestMemery(Test,Test2)
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Role.RoleMainUI",AppDef.UIType.FirstClassLayer,1)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    roleBtn:addClickEventListener(RoleTouchCallback)
	self:MarkIntaractCObj(roleBtn)
    local btnSize = roleBtn:getContentSize()
    local pos = roleBtn:convertToWorldSpace(cc.p(btnSize.width/2,btnSize.height/2))
    LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.InitHeroBtnPos,pos)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    LRedDotCheckMgr:AddCheckBtn(bagBtn, AppDef.RedDotBtnName.BagBtn)

    -- 护送处理
    -- local function EscortCallback(sender)
    --     LRoleDataMgr.MyHeroInfo.m_Convoy.IsAutoYunShou = not LRoleDataMgr.MyHeroInfo.m_Convoy.IsAutoYunShou
    --     self:SetEscortBtnVisible()
    -- end
    -- self.m_husongBtn:addClickEventListener(EscortCallback)

    -----------------------------------
    --装备背包
    local petEquipBtn = self.m_buttonGroupMap[BTN_NAME_PetEquip]
    petEquipBtn:addClickEventListener(function ( sender )
        -- body
        if not self._isWearShow then
            self:PlayEquipAppearAni();
            -- Utils:PlayAction("csd/common/UImainLayer_new.csb", 30, 45, 15, nil) 
            self._isWearShow = true
            
        else
            self:PlayEquipDisappearAni();
            -- Utils:PlayAction("csd/common/UImainLayer_new.csb", 40, 55, 5, nil)
            self._isWearShow = false
        end
    end)
    LRedDotCheckMgr:AddCheckBtn(petEquipBtn, AppDef.RedDotBtnName.ChuangDai)
    
    -- self:SetButtonVisible(AppDef.EModuleID.EMID_SJEQUIP)
    local function OnPetEquipButtonClick(sender)
        -- LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "PetEquip.PetEquipMainUI", AppDef.UIType.FirstClassLayer, 1)
        -- LUIManager:SendMsg(LGameMsg.m_initUIMsg)
         Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_EQUIP_BAG)
    end
    
    self._ChuanDai = self.m_pMainUI:getChildByName("tankuang2")

    local btn_zhuangbei = self._ChuanDai:getChildByName("btn_zhuangbei")
    btn_zhuangbei:addClickEventListener(OnPetEquipButtonClick)
    --self:SetButtonVisible(AppDef.EModuleID.EMID_KAPAI_EQUIP_BAG)
    LRedDotCheckMgr:AddCheckBtn(btn_zhuangbei, AppDef.RedDotBtnName.PetEquipBtn)

    local btn_fabao = self._ChuanDai:getChildByName("btn_fabao")
    btn_fabao:addClickEventListener(function ( sender )
        -- body
        -- Utils:InitUI("FaBao.FaBaoMainUI", AppDef.UIType.FirstClassLayer, 1)
        Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_FABAO_SYS)
    end)
	LRedDotCheckMgr:AddCheckBtn(btn_fabao, AppDef.RedDotBtnName.FaBaoBtn)
    -- ---------------------------

    --mini聊天
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUIInBattle, "Chat.ChatMiniShowLayer",AppDef.UIType.Chat, 1)
    self:SendMsg(LGameMsg.m_initUIMsg)

    --聊天
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUIInBattle, "Chat.MainChatUI",AppDef.UIType.Chat)
    self:SendMsg(LGameMsg.m_initUIMsg)

    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUIInBattle, "Chat.VoiceWindowUI",AppDef.UIType.MsgBox)
    self:SendMsg(LGameMsg.m_initUIMsg)
    
    local function BagTouchCallback(sender)
        Utils:OpenFunction(AppDef.EModuleID.EMID_BEIBAO);
        -- LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Role.KaPaiBagMainUI", AppDef.UIType.FirstClassLayer, 1)
        -- self:SendMsg(LGameMsg.m_initUIMsg)
    end
    bagBtn:addClickEventListener(BagTouchCallback)
	self:MarkIntaractCObj(bagBtn)
    btnSize = bagBtn:getContentSize()
    local bagPos = bagBtn:convertToWorldSpace(cc.p(btnSize.width/2,btnSize.height/2))
    LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.InitBagBtnPos,bagPos)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)


    local btngp1 = panel:getChildByName("ButtonGroup4")
    local btngp2 = panel:getChildByName("ButtonGroup3")

    local btngp4 = panel:getChildByName("ButtonGroup1")

    local btngp5 = panel:getChildByName("ButtonGroup5")--右上角按钮
    local btngp6 = panel:getChildByName("ButtonGroup6")--右上角按钮

    local btngp8 = panel:getChildByName("ButtonGroup8")--三排按钮



    self.m_pFirstRechargeBtn = self.m_buttonGroupMap[BTN_NAME_ShouChong]
    LRedDotCheckMgr:AddCheckBtn(self.m_pFirstRechargeBtn, AppDef.RedDotBtnName.Group2Btn1)
    --首充、次充按钮
    local function FirstRechargeCallback(sender)
        Utils:OpenFunction(AppDef.EModuleID.EMID_RECHARGE_SHOWCHONG)
    end
    self.m_pFirstRechargeBtn:addClickEventListener(FirstRechargeCallback)
	self:MarkIntaractCObj(self.m_pFirstRechargeBtn)

    --神将折扣
    local petZheKou = self.m_buttonGroupMap[BTN_NAME_PetZhekou]
    local function petZheKouCallBack( sender )
        -- body
    end
    petZheKou:addClickEventListener(petZheKouCallBack)
    self:MarkIntaractCObj(petZheKou)


    --七日登录
    local btn_Denglu = self.m_buttonGroupMap[BTN_NAME_Denglu]
    local function sevendDayDengluCallBack( ... )
        -- body
        Utils:OpenFunction(AppDef.EModuleID.EMID_SEVENDAY_LOGIN)
    end
    btn_Denglu:addClickEventListener(sevendDayDengluCallBack)
    self:MarkIntaractCObj(btn_Denglu)


    local btn_kaifuRank = self.m_buttonGroupMap[BTN_NAME_kaifuRank]
    local function ServerRankCallBack( ... )
        -- body
        Utils:OpenFunction(AppDef.EModuleID.EMID_RECHARGE_HYJJ)
    end
    btn_kaifuRank:addClickEventListener(ServerRankCallBack)
    self:MarkIntaractCObj(btn_kaifuRank)
    
    local btn_zhuanpan = self.m_buttonGroupMap[BTN_NAME_zhuanpan]
    local function zhuanPanCallBack( ... )
        -- body
        --WelfareActivityDef.Type.ZaDan2
        Utils:InitUI("WelfareActivity.ZaDanUI", AppDef.UIType.PopWindow, 92)
    end
    btn_zhuanpan:addClickEventListener(zhuanPanCallBack)
    self:MarkIntaractCObj(btn_zhuanpan)
    

    self._huodong = self.m_buttonGroupMap[BTN_NAME_huodong]
    -- self._huodong:setVisible(false)
    LRedDotCheckMgr:AddCheckBtn(self._huodong, AppDef.RedDotBtnName.Group2Btn3)
    self._huodong:addClickEventListener(function ( sender )
        -- body
        -- Utils:InitUI("WelfareActivity.LimitGaChaActivity", AppDef.UIType.SpecialLayer, 3)
        Utils:InitUI("WelfareActivity.WelfareActivityFormerUI", AppDef.UIType.SpecialLayer, 1)
    end)

    self._fuli = self.m_buttonGroupMap[BTN_NAME_FL]
    LRedDotCheckMgr:AddCheckBtn(self._fuli, AppDef.RedDotBtnName.Group2Btn4)
    self._fuli:addClickEventListener(function ( sender )
        -- body
        Utils:OpenFunction(AppDef.EModuleID.EMID_HUODONG)
    end)

    local taskBtn = self.m_buttonGroupMap[BTN_NAME_task]
    LRedDotCheckMgr:AddCheckBtn(taskBtn, AppDef.RedDotBtnName.Group2Btn5)
    taskBtn:addClickEventListener(function ( sender )
        -- body
        Utils:OpenFunction(AppDef.EModuleID.EMID_TASK_DALIY)
    end)

    --玩法
    local activityBtn = self.m_buttonGroupMap[BTN_NAME_WanFa]
    --self:SetButtonVisible(AppDef.EModuleID.EMID_WANFA)
    -- local function ActivityTouchCallback(sender)
    --     -- Utils:OpenFunction(AppDef.EModuleID.EMID_WANFA)
    --     Utils:InitUI("Main.WanFaEntranceUI", AppDef.UIType.PopFirstClassLayer)
    -- end
    activityBtn:addClickEventListener(handler(self,MainUI.WanFaCallback))
	self:MarkIntaractCObj(activityBtn)
    LRedDotCheckMgr:AddCheckBtn(activityBtn, AppDef.RedDotBtnName.WanFa)

    --抽卡
    local chouKaBtn = self.m_buttonGroupMap[BTN_NAME_ChouKa]
    self:SetButtonVisible(AppDef.EModuleID.EMID_KAPAI_CHOUKA)
    chouKaBtn:addClickEventListener(handler(self, MainUI.LuckDrawTouchCallback))
	self:MarkIntaractCObj(chouKaBtn)
    LRedDotCheckMgr:AddCheckBtn(chouKaBtn, AppDef.RedDotBtnName.Group3Btn3)

    --排行榜
    local rankBtn = self.m_buttonGroupMap[BTN_NAME_Rank]
    --self:SetButtonVisible(AppDef.EModuleID.EMID_KAPAI_CHOUKA)
    rankBtn:addClickEventListener(handler(self, MainUI.RankCallback))
    self:MarkIntaractCObj(rankBtn)
    LRedDotCheckMgr:AddCheckBtn(rankBtn,BTN_NAME_Rank)

    --[[
    帮派活动
    ]]
    local bpActBtn = self.m_buttonGroupMap[BTN_NAME_Bp_Act]
    local function BpActCallback(sender)
        if LRoleDataMgr.Faction.Info.id <= 0 then
            Utils:OpenFunction(AppDef.EModuleID.EMID_BANGPAI, 4)
        else
            --Utils:SetRedDotState(RedDotDef.ID.BPSkillUpgrade, true)
            Utils:OpenFunction(AppDef.EModuleID.EMID_BPXINXI)
        end
        
    end
    bpActBtn:addClickEventListener(BpActCallback)
	self:MarkIntaractCObj(bpActBtn)
    LRedDotCheckMgr:AddCheckBtn(bpActBtn, AppDef.RedDotBtnName.Group5Btn1)

    --神将按钮
    local petBtn = self.m_buttonGroupMap[BTN_NAME_ShenJiang]
    -- self:SetButtonVisible(AppDef.EModuleID.EMID_SHENJIANG)
    petBtn:addClickEventListener(handler(self, MainUI.PetTouchCallback))
	self:MarkIntaractCObj(petBtn)
    LRedDotCheckMgr:AddCheckBtn(petBtn, AppDef.RedDotBtnName.Group3Btn2)

	--主角
	local zhujueBtn = self.m_buttonGroupMap[BTN_NAME_ZhuJue]
	local function zhujueTouchCallback(sender)
		if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_JINGJIE) then
			return
		end

		Utils:OpenFunction(AppDef.EModuleID.EMID_JINGJIE)
	end
    zhujueBtn:addClickEventListener(zhujueTouchCallback)
	self:MarkIntaractCObj(zhujueBtn)
    --LRedDotCheckMgr:AddCheckBtn(petBtn, AppDef.RedDotBtnName.Group3Btn2)
    -- ---------------------------
    -- 系统
    local settingBtn = self.m_buttonGroupMap[BTN_NAME_XiTong]
    -- self:SetButtonVisible(AppDef.EModuleID.EMID_SHEZHI)
    local function OnSettingButtonClick(sender)
        Utils:OpenFunction(AppDef.EModuleID.EMID_SHEZHI)
    end
    settingBtn:addClickEventListener(OnSettingButtonClick)
	self:MarkIntaractCObj(settingBtn)
    LRedDotCheckMgr:AddCheckBtn(settingBtn, AppDef.RedDotBtnName.Group4Btn3)


    local mailBtn = self.m_buttonGroupMap[BTN_NAME_mail]
    local function OnMailButtonClick(sender)
        Utils:OpenFunction(AppDef.EModuleID.EMID_SHEJIAO)
    end
    mailBtn:addClickEventListener(OnMailButtonClick)
    LRedDotCheckMgr:AddCheckBtn(mailBtn, AppDef.RedDotBtnName.PetMail)


    local friendBtn = self.m_buttonGroupMap[BTN_NAME_Friend]
    local function OnFriendBtnButtonClick(sender)
        Utils:OpenFunction(AppDef.EModuleID.EMID_FRIEND)
    end
    friendBtn:addClickEventListener(OnFriendBtnButtonClick)
    LRedDotCheckMgr:AddCheckBtn(friendBtn, BTN_NAME_Friend)

	local huishouBtn = self.m_buttonGroupMap[BTN_NAME_huishou]
	local function OnHuiShouBtnButtonClick(sender)
        Utils:OpenFunction(AppDef.EModuleID.EMID_HUISHOU)
    end
	huishouBtn:addClickEventListener(OnHuiShouBtnButtonClick)
    LRedDotCheckMgr:AddCheckBtn(huishouBtn, BTN_NAME_huishou)

    -- 副本
    local fuben = self.m_buttonGroupMap[BTN_NAME_btn_fuben]
    fuben:addClickEventListener(handler(self,MainUI.FuBenTouchCallback))
    self:MarkIntaractCObj(fuben)
    print("add it in Check ==============>")
    LRedDotCheckMgr:AddCheckBtn(fuben, AppDef.RedDotBtnName.FuBen)

    --折扣礼包
    local zhekouBtn1 = self.m_buttonGroupMap[BTN_NAME_GiftZhekou1]
    zhekouBtn1:addClickEventListener(handler(self,MainUI.ZheKou1Callback))
    local zhekouBtn2 = self.m_buttonGroupMap[BTN_NAME_GiftZhekou2]
    zhekouBtn2:addClickEventListener(handler(self,MainUI.ZheKou2Callback))
    local zhekouBtn3 = self.m_buttonGroupMap[BTN_NAME_GiftZhekou3]
    zhekouBtn3:addClickEventListener(handler(self,MainUI.ZheKou3Callback))
    --LRedDotCheckMgr:AddCheckBtn(zhekouBtn1, AppDef.RedDotBtnName.FuBen)

    --左上角按钮
    --商城按钮
    local shopBtn = self.m_buttonGroupMap[BTN_NAME_ShangCheng]
    LRedDotCheckMgr:AddCheckBtn(shopBtn, AppDef.RedDotBtnName.btn_shangcheng)
    self._tankuang = self.m_pMainUI:getChildByName("tankuang1")
    local NormalShopBtn = self._tankuang:getChildByName("btn_shangcheng")
    NormalShopBtn:addClickEventListener(function ( sender )
        -- body
        Utils:OpenFunction(AppDef.EModuleID.EMID_SCCHANGYONG)
    end)
    NormalShopBtn:getChildByName("Prompt"):setVisible(false)
    

    --将魂商店
    local btn_jianghun = self._tankuang:getChildByName("btn_jianghun")
    btn_jianghun:addClickEventListener(function ( sender )
        -- body
        Utils:OpenFunction(AppDef.EModuleID.EMID_SHOP_HUN)
    end)
    LRedDotCheckMgr:AddCheckBtn(btn_jianghun, AppDef.RedDotBtnName.btn_jianghun)

    --玩法商店
    local btn_wanfaShop = self._tankuang:getChildByName("btn_wanfa")
    btn_wanfaShop:addClickEventListener(function ( sender )
        -- body
        Utils:OpenFunction(AppDef.EModuleID.EMID_SHOP_JINGJI)
    end)
    LRedDotCheckMgr:AddCheckBtn(btn_wanfaShop, AppDef.RedDotBtnName.btn_wanfaShop)

    
    --充值
    local rechargeBtn = self.m_buttonGroupMap[BTN_NAME_chongzhi]
    rechargeBtn:addClickEventListener(function ( sender )
        -- body
        Utils:OpenRechargeMainUI()
    end)

    local qiriBtn = self.m_buttonGroupMap[BTN_NAME_QIRI]
    qiriBtn:addClickEventListener(function( sender)
        -- body 
        local level = Utils:getFucnOpenLevel( AppDef.EModuleID.EMID_QIRI )
        -- --print(" 11111111111111 level ===>", level)
        if LRoleDataMgr.MyHeroInfo.level < level then
            Utils:ShowScrollTips(string.format(GUITips.RSI_PREVIEW_MSG2, level))
            return
        end

        self:SevenDay()
    end)
    LRedDotCheckMgr:AddCheckBtn(qiriBtn, AppDef.RedDotBtnName.btn_Qiri)

    --贵宾特权
    local VipBtn = self.m_buttonGroupMap[BTN_NAME_Vip]
    VipBtn:addClickEventListener(function ( sender )
        -- body
        Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_VIP)
    end)

    local function shopTouchCallback(sender)
        if not self._isShopShow then
            -- local action = cc.MoveTo:create( 0.2, cc.p(self._tankuang:getPositionX(), self._tankuang:getPositionY() - 200))
            -- self._tankuang:runAction(action)
            self:PlayShopAppearAni();
            --Utils:PlayAction("csd/common/UImainLayer_new.csb", 0, 5, 25, nil) 
            self._isShopShow = true
            
        else
            -- local action = cc.MoveTo:create( 0.2, cc.p(self._tankuang:getPositionX(), self._tankuang:getPositionY() + 200))
            -- self._tankuang:runAction(action)
            self:PlayShopDisappearAni();
            --Utils:PlayAction("csd/common/UImainLayer_new.csb", 20, 25, 25, nil)
            self._isShopShow = false
            

        end 
    end
    shopBtn:addClickEventListener(shopTouchCallback)
	self:MarkIntaractCObj(shopBtn)
    LRedDotCheckMgr:AddCheckBtn(shopBtn, AppDef.RedDotBtnName.Group1Btn1)
    self._isShopShow = false
    self._isShowNow = true


 --    --[[
 --    新邮件提示
 --    ]]
 --    local newMailBtn = self.m_pShortBtnGp:getChildByName("Mail")
 --    local function NewMailCallback(sender)
 --        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Social.SocialLayer",AppDef.UIType.FirstClassLayer, 1)
 --        self:SendMsg(LGameMsg.m_initUIMsg)
 --        newMailBtn:setVisible(false)
 --        self:SetShortBtnsPosition()
 --    end
 --    newMailBtn:addClickEventListener(NewMailCallback)
	-- self:MarkIntaractCObj(newMailBtn)
 --    newMailBtn:setVisible(false)

 --    --[[
 --    提升提示
 --    ]]
 --    local upBtn = self.m_pShortBtnGp:getChildByName("tisheng")
 --    self.m_pShortBtnSx = upBtn:getPositionX()
 --    self.m_pShortBtnWidth = upBtn:getContentSize().width
 --    local function UpCallback(sender)
 --        local worldPos = sender:getParent():convertToWorldSpace(cc.p(sender:getPositionX(), sender:getPositionY()));
 --        local showPos = cc.p(worldPos.x - sender:getContentSize().width * 3, worldPos.y + sender:getContentSize().height * 0.5)
 --        LGameMsg.m_baseMsgWithOne:Change(LUIMainEvent.ShowImproveView, showPos)
 --        self:SendMsg(LGameMsg.m_baseMsgWithOne)
 --    end
 --    upBtn:addClickEventListener(UpCallback)
	-- self:MarkIntaractCObj(upBtn)
 --    upBtn:setVisible(false)


 --    --[[
 --    有新聊天提示
 --    ]]
 --    local newChatBtn = self.m_pShortBtnGp:getChildByName("Chat")
 --    local function HasNewChatCallback(sender)
 --    end
 --    newChatBtn:addClickEventListener(HasNewChatCallback)
	-- self:MarkIntaractCObj(newChatBtn)
 --    newChatBtn:setVisible(false)

 --    --[[
 --    入队快捷键
 --    ]]
 --    local teamApplyBtn = self.m_pShortBtnGp:getChildByName("Team")
 --    local function TeamApplyCallback(sender)
 --        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Team.TeamApplyListUI",AppDef.UIType.SecondClassLayer)
 --        self:SendMsg(LGameMsg.m_initUIMsg)
 --        --teamApplyBtn:setVisible(false)
 --    end
 --    teamApplyBtn:addClickEventListener(TeamApplyCallback)
	-- self:MarkIntaractCObj(teamApplyBtn)
 --    teamApplyBtn:setVisible(false)
 --    --[[
 --    邀请入帮快捷键
 --    ]]
 --    local invoteJoinFactionBtn = self.m_pShortBtnGp:getChildByName("tishi")
 --    local function InvoteJoinFactionCallback(sender)
 --        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "BangPai.BangPaiInviteList",AppDef.UIType.SecondClassLayer)
 --        self:SendMsg(LGameMsg.m_initUIMsg)
 --    end
 --    invoteJoinFactionBtn:addClickEventListener(InvoteJoinFactionCallback)
	-- self:MarkIntaractCObj(invoteJoinFactionBtn)
 --    invoteJoinFactionBtn:setVisible(false)



    local petBagBtn = self.m_buttonGroupMap[BTN_NAME_PetBag]
    -- self:SetButtonVisible(AppDef.EModuleID.EMID_KAPAI_PET_BAGS)
    self:MarkIntaractCObj(petBagBtn)
    petBagBtn:addClickEventListener(handler(self, MainUI.PetBagCallBack))
    LRedDotCheckMgr:AddCheckBtn(petBagBtn, AppDef.RedDotBtnName.PetBagBtn)
    
 --    local xueZhanBtn = self.m_buttonGroupMap[BTN_NAME_Xuezhan]
 --    -- self:SetButtonVisible(AppDef.EModuleID.EMID_KAPAI_PET_BAGS)
 --    self:MarkIntaractCObj(xueZhanBtn)
 --    xueZhanBtn:addClickEventListener(handler(self, MainUI.XueZhanCallBack))
	
	-- local fengShenBtn = self.m_buttonGroupMap[BTN_NAME_Fengshen]
	-- self:MarkIntaractCObj(fengShenBtn)
 --    fengShenBtn:addClickEventListener(handler(self, MainUI.WelfareBtnClicked))

 --    local fengShenStoryBtn = self.m_buttonGroupMap[BTN_NAME_FengShenStory]
 --    self:MarkIntaractCObj(fengShenStoryBtn)
 --    fengShenStoryBtn:addClickEventListener(handler(self, MainUI.FengShenStoryCallBack))
    --[[
    限时活动
    ]]

    local wanfaBtn = self.m_buttonGroupMap[BTN_NAME_WanFa]
    -- local group6 = self.m_buttonGroupMap[BTN_NAME_ButtonGroup..6]
    -- self.m_pFastActDelegate = FastActDelegate:New(wanfaBtn, group6)
    local onLineBtn = self.m_pMainUI:getChildByName(BTN_NAME_ONLINE)
    onLineBtn:addClickEventListener(handler(self, MainUI.OnLineClicked))
end

--[[
播放装备出现动画
]]
function MainUI:PlayShopAppearAni()
    local node = self.m_pUILayer:findChildByName("Main_UI/tankuang1");
    if self._srcShopPanelPosY == nil then
        self._srcShopPanelPosY = node:getPositionY();
    end
    --108
    node:stopAllActions()

    local move = cc.MoveTo:create(0.17,cc.p(node:getPositionX(),self._srcShopPanelPosY - 126))
    local fade = cc.FadeTo:create(0.17,255)
    local sp = cc.Spawn:create(move,fade)
    node:runAction(sp);

end

--[[
播放装备结束动画
]]
function MainUI:PlayShopDisappearAni()
    if self._srcShopPanelPosY == nil then
        return
    end
    local node = self.m_pUILayer:findChildByName("Main_UI/tankuang1");
    node:stopAllActions()
    local move = cc.MoveTo:create(0.17,cc.p(node:getPositionX(),self._srcShopPanelPosY))
    local fade = cc.FadeTo:create(0.17,0)
    local sp = cc.Spawn:create(move,fade)
    node:runAction(sp);
end

--[[
播放装备出现动画
]]
function MainUI:PlayEquipAppearAni()
    local node = self.m_pUILayer:findChildByName("Main_UI/tankuang2");
    if self._srcEquipPanelPosY == nil then
        self._srcEquipPanelPosY = node:getPositionY();
        -- node:setPositionX(self.m_pUILayer:findChildByName("Main_UI/ButtonGroup1"):getPositionX() - 155)
    end
    --108
    node:stopAllActions()

    local move = cc.MoveTo:create(0.17,cc.p(node:getPositionX(),self._srcEquipPanelPosY + 112))
    local fade = cc.FadeTo:create(0.17,255)
    local sp = cc.Spawn:create(move,fade)
    node:runAction(sp);

end

--[[
播放装备结束动画
]]
function MainUI:PlayEquipDisappearAni()
    if self._srcEquipPanelPosY == nil then
        return
    end
    local node = self.m_pUILayer:findChildByName("Main_UI/tankuang2");
    node:stopAllActions()
    local move = cc.MoveTo:create(0.17,cc.p(node:getPositionX(),self._srcEquipPanelPosY))
    local fade = cc.FadeTo:create(0.17,0)
    local sp = cc.Spawn:create(move,fade)
    node:runAction(sp);
end

function MainUI:SevenDay()
    -- if PetkaPaiManager._serverOpenTime > 7 then
    --     Utils:ShowScrollTips(GUITips.RSI_NATIONALGIFT_TIPS3)
    --     return
    -- end
    Utils:OpenFunction(AppDef.EModuleID.EMID_QIRI)
end


-------------------------  在线奖励---------------------
 -- LRoleDataMgr.MyHeroInfo.OnLine:UpdateInd(LRoleDataMgr.MyHeroInfo.OnLine.ind+1)
      --  LRoleDataMgr.MyHeroInfo.OnLine:UpdateTime((JsonConfig.m_OnLineConfig.getDefByID(LRoleDataMgr.MyHeroInfo.OnLine.ind).time-JsonConfig.m_OnLineConfig.getDefByID( LRoleDataMgr.MyHeroInfo.OnLine.ind-1).time)*60)
       -- self:UpdateOnLineTime()
function MainUI:OnLineClicked(sender)
    local OLData = LRoleDataMgr.MyHeroInfo.OnLine
    if OLData:IsCanGet()==true then
        LuaNetSendMsg:AwardOnlineAward()
    else
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "OperationalActivity.OnLine",AppDef.UIType.Normal)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
end
function MainUI:DisPlayCurRewardItem()
    local OLData = LRoleDataMgr.MyHeroInfo.OnLine
    local OLConfig = JsonConfig.m_OnLineConfig
    item=self.m_pMainUI:getChildByName(BTN_NAME_ONLINE)
    local effect=item:getChildByTag(100)
    if  effect==nil then
        effect= Utils:ReceivableEffect(0.6)
        effect:setTag(100)
        effect:setPositionX(effect:getPositionX()+44)
        effect:setPositionY(effect:getPositionY()+44)
        item:addChild(effect)
    end
   -- effect:setPosition(item:getPosition())


    local data = OLConfig.getDefByID(OLData.ind)
    if data then
        local num =0
            if data.reward[2]>0 then
                num=data.reward[2]
            else
                num=data.reward[3]
            end
        Utils:GetItemCellValue(item,0,data.reward[1],false,true,num,nil,false)
    end
    item:reorderChild(effect,0)
    local cell =item:getChildByName("ItemIconLayer.csb") 
    item:reorderChild(cell,1)
    effect:setVisible(false)
end


-- 在线奖励
function MainUI:UpdateOnLineTime()

    local OLData = LRoleDataMgr.MyHeroInfo.OnLine
    local OLConfig = JsonConfig.m_OnLineConfig
      --print("在线奖励",OLData.curtime)
    if self.m_OnLineTimer~=nil then
        self.m_OnLineTimer:Destory()
        self.m_OnLineTimer=nil
    end
    if OLData.ind>#(OLConfig.getList()) then
        self.m_pMainUI:getChildByName(BTN_NAME_ONLINE):setVisible(false) 
        return
    end

    local Time = self.m_pMainUI:getChildByName(BTN_NAME_ONLINE):getChildByName("Time")
   
    local Text = Time:getChildByName("temp_text")
    Time:setVisible(true)  


    self.m_OnLineTimer = TimerLabelUI:New(Text,OLData.curtime, function()
                Time:setVisible(false)   
                local effect =self.m_pMainUI:getChildByName(BTN_NAME_ONLINE):getChildByTag(100)   
                effect:setVisible(true)
                if self.m_finishFunCB then
                    self.m_finishFunCB()
                end
            end,function(label, _h, _m, _s, iLeftTime)
                if self.m_updateFunCB then
                  self.m_updateFunCB(_h, _m, _s)
                end
               label:setString(string.format("%02d:%02d:%02d", _h, _m, _s))
               LRoleDataMgr.MyHeroInfo.OnLine:SubTime()
            end,false)
    self.m_OnLineTimer:start()
    self:DisPlayCurRewardItem()

end

function MainUI:OnLineFinish()
    if self.m_OnLineTimer~=nil then
        self.m_OnLineTimer:Destory()
        self.m_OnLineTimer=nil
    end

end
-- function MainUI:OnLineEffect()
--     local bgAnim = "res2/animation/effect_tuitu_1"
--     local m_pBgAni = ImodAnim:create()
--     m_pBgAni:initAnimWithNameSync(bgAnim)
--     m_pBgAni:PlayActionRepeat(0)
--     m_pBgAni:setScale(0.6)
--     m_pBgAni:setTag(101)
--     return m_pBgAni
-- end
---------------------------------------------------------------------------------

function MainUI:HanleCrossServer()
    local npcid = 228
    local mapid = 11
    if LRoleDataMgr.m_bIsCrossServer then
        npcid = 26
        mapid = 70
    end
    LGameMsg.m_autoPathMsg:ChangeToStart(mapid,-1,-1,0,bit.lshift(npcid,16),true,true, nil)
    if LRoleDataMgr.m_bIsCrossServer then
        LGameMsg.m_autoPathMsg:SetQuitCrossServer(true)
    end
    self:SendMsg(LGameMsg.m_autoPathMsg)
	LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, true)
	self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function MainUI:HurtCallback(sender)
    local sceneType = LRoleDataMgr.MyHeroInfo.SceneType
    if sceneType == AppDef.SceneType.MSI_LUNDAO then
        LuaNetSendMsg:QueryLunDaoInfo(2)--请求排行信息
    elseif sceneType == AppDef.SceneType.MSI_FACTION_WAR then
        LuaNetSendMsg:QueryBangPaiWarInfo(4)
    elseif sceneType == AppDef.SceneType.MSI_SHENJIEMIJING then
        LuaNetSendMsg:QueryMsBossRankList()--请求排行信息
    end
end

function MainUI:ArenaTouchCallback(sender)
    Utils:OpenFunction(AppDef.EModuleID.EMID_JINGJI)
end

function MainUI:ShenshouGiftCallback(sender)
    Utils:OpenFunction(AppDef.EModuleID.EMID_MUBIAO)
end
--境界
 function MainUI:jingJieCallback(sender)
 
  Utils:OpenFunction(AppDef.EModuleID.EMID_JINGJIE)
end

--神将背包
function MainUI:PetBagCallBack(sender) 
  Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_PET_BAGS)
end

--英勇试炼
function MainUI:XueZhanCallBack(sender) 
    LuaNetSendMsg:QueryXueZhanInfo(1)
end

--封神列传
function MainUI:FengShenStoryCallBack(sender) 
    -- local data = LActivityManager:GetFengShenStoryData()
    -- data.m_curLevelId = 40122
    -- data.m_chapterId = 12
    -- data.m_cnt = 99
    --print("MainUI:FengShenStoryCallBack")
    Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_FENGSHEN_STORY)
end

function MainUI:WelfareBtnClicked(sender)
    --Utils:OpenFunction(AppDef.EModuleID.EMID_FULI)
	Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_FENGSHEN)
end

function MainUI:ShowActivityIcon(type)
    -- body
    -- local qiriBtn = self.m_buttonGroupMap[BTN_NAME_QIRI]
    -- print("PetkaPaiManager._serverOpenTime ==>", PetkaPaiManager._serverOpenTime, PetkaPaiManager.m_createRoleDays)
    -- if PetkaPaiManager._serverOpenTime <= 14 and PetkaPaiManager.m_createRoleDays <= 7 then
    --     qiriBtn:setVisible(true)
    -- else
    --     qiriBtn:setVisible(false)
    -- end

end

function MainUI:UpdateDiscountIcon( ... )
    -- body
    if LRoleDataMgr.m_DisCountShopEndTime > 0 and LRoleDataMgr.m_firstRechargeState > 0 then
        self.m_pRebateStoreBtn:setVisible(true)
    end
end

function MainUI:SceneHeroClicked(hearData, pos)
    --[[
    信息查询
    邀请组队
    加为好友
    切磋武功
    发送信件
    发起私聊
    ]]

    local pid = hearData:GetId()
    local pName = hearData:GetName()
    local function QueryInfoCallback()
        LuaNetSendMsg:QueryOtherPlayer(pid)
    end

    local function TeamInviteCallback()
        if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_ZUDUI) then
            return
        end
        local teamId = hearData:GetTeamId()
        if teamId > 0 and LRoleDataMgr.MyHeroInfo:IsTeam() == false then
            LuaNetSendMsg:QueryApplyTeam(teamId)--申请入队()
        --    Utils:ShowScrollTips(string.format(GUITips.UI_FRIEND_TEAM2,pName))
        else
            LuaNetSendMsg:QueryTeamInvite(pid)--邀请组队()
--            Utils:ShowScrollTips(string.format(GUITips.UI_FRIEND_TEAM1,pName))
        end
    end

    local function AddFriendCallback()
        if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SJHAOYOU) then
            return
        end
        LuaNetSendMsg:QueryAddFriend(pid)
    end

    local function PKCallback()
        if Utils:CheckModelNotOpened(AppDef.EModuleID.EAID_PK) then
            return
        end
        Utils:ShowScrollTips(string.format(GUITips.RSI_MACTH_TIPS,pName))
        LuaNetSendMsg:QueryMatchWithPlayer(0, 1, pid)
    end

    local function SendMailCallback()
        LGameMsg.m_baseMsgWithOne:Change(LUIMailEvent.OpenWriteMail, hearData:GetName())
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end

    local function SendChatCallback()
        if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SJHAOYOU) then
            return
        end

        local data = {}
        data.id = pid
        data.level = hearData:GetLv()
        data.head = hearData:GetProfessional()
        data.name = hearData:GetName()
        Utils:SendMsg(LUIChatEvent.OpenPrivateChat, data)
-- --私聊
--         local cMsg = LPcChatMsg:New()
--         ------print("SendChatCallback pid = ", pid)
--         cMsg.sendId = pid
--         cMsg.sendLv = hearData:GetLv()
--         ------print("hearData.professional", hearData:GetProfessional(), hearData:GetSex(), hearData:GetName())
--         cMsg.sendProf = hearData:GetProfessional()
--         cMsg.sendSex = hearData:GetSex()
--         cMsg.sendName = hearData:GetName()
--         LRoleDataMgr.Social:UpdateTmpChatList(cMsg.sendId, cMsg)
-- --发送私聊消息
--         LGameMsg.m_baseMsgWithOne:Change(LUIChatEvent.addPcTempChat, pid)
--         self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end

    
    local btndata = {}
    table.insert(btndata,{GUITips.UI_Team_MemberInfo,QueryInfoCallback})
    local teamId = hearData:GetTeamId()
    if teamId > 0 and LRoleDataMgr.MyHeroInfo:IsTeam() == false then
        table.insert(btndata,{GUITips.RSI_FACTION_MSG18,TeamInviteCallback})
    else
        table.insert(btndata,{GUITips.UI_Title_Team_InviteList,TeamInviteCallback})
    end
    
    table.insert(btndata,{GUITips.UI_Team_AddFriend,AddFriendCallback})
    table.insert(btndata,{GUITips.UI_Text_PK,PKCallback})
    table.insert(btndata,{GUITips.UI_TEAM_SENDMAIL,SendMailCallback})
    table.insert(btndata,{GUITips.RSI_FACTION_MSG24,SendChatCallback})

    btndata.pos = pos
    LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowCommomBtnList, btndata)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

--[[
处理挂机
]]
function MainUI:HandleHangUp()
    if LRoleDataMgr.isHangUp == true then
        LRoleDataMgr.isHangUp = false
        LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.HangUpEvent.StopHangUp)--
        self:SendMsg(LGameMsg.m_cBaseMsg)

        LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.RoleEvent.BreakMove)--
        self:SendMsg(LGameMsg.m_cBaseMsg)
        return
    end
    --主城和师门不能挂机
    local heroData = LRoleDataMgr.MyHeroInfo
    if not heroData:CheckCanHangUp() then
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, GUITips.RSI_GMN_TIP4)
        self:SendMsg(LGameMsg.m_scrollTipsMsg)
        return
    end
            
    --运镖、护送时不能挂机
    if heroData.ConvoyType ~= 0 then
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, GUITips.RSI_GMN_TIP5)
        self:SendMsg(LGameMsg.m_scrollTipsMsg)
        return
    end

    LRoleDataMgr.isHangUp = true
    LGameMsg.m_hangUpMsg:Change(CEnum.HangUpEvent.StartHangUp, 0, 0)--
    self:SendMsg(LGameMsg.m_hangUpMsg)
end

function MainUI:SetTeamApplyBtnVisible(visible)
    local teamApplyBtn = self.m_pShortBtnGp:getChildByName("Team")
    teamApplyBtn:setVisible(visible)
    self:SetShortBtnsPosition()
end

function MainUI:HandleQuitCopy()
    local function OKCallback()
        if LRoleDataMgr.MyHeroInfo.SceneType == AppDef.SceneType.MSI_FISHROOM then
            Utils:SendMsg(LUIFishEvent.QuitFishState)
        end
        LuaNetSendMsg:QueryCopyExit()
        self.levelTime = 0
    end

    local msgData = {
        okCallback = OKCallback,
    }
    local sceneType = LRoleDataMgr.MyHeroInfo.SceneType
    if sceneType == AppDef.SceneType.MSI_COPY or sceneType == AppDef.SceneType.MSI_PETCOPY then
        msgData.desc = string.format(GUITips.RSI_Quit_Scene_Tips_Format2, self.m_pCurName)
    elseif sceneType == AppDef.SceneType.MSI_KUNLUN then
        msgData.desc = string.format(GUITips.RSI_Quit_Scene_Tips_Format1, self.m_pCurName)
    elseif sceneType == AppDef.SceneType.MSI_FACTION_ZONE then
        msgData.desc = string.format(GUITips.RSI_Quit_Scene_Tips_Format3, self.m_pCurName)
    else
        local buffer = {
            [AppDef.SceneType.MSI_LUNDAO] = true,
        }
        if buffer[sceneType] and (not LRoleDataMgr.MyHeroInfo:IsLeader()) then
            Utils:ShowScrollTips(GUITips.RSI_XLXY_TIPS_1)
            return
        end
        msgData.desc = string.format(GUITips.RSI_Quit_Scene_Tips_Format, self.m_pCurName)
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIMsgBoxEvent.ShowMsgBox, msgData)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    
end

function MainUI:setImproveBtnVisible(isVisible)
    local st = LRoleDataMgr.MyHeroInfo:GetSceneType()
    if LRoleDataMgr:IsInSpaicialScene() and st == AppDef.SceneType.MSI_COPY then
        return
    end

    local isLimited = LDataConstMgr:IsLimitedLevel2(GUITips.RSI_LVL_TIP22, LRoleDataMgr.MyHeroInfo.level)
    if isLimited then
        return
    end
    self.m_pShortBtnGp:getChildByName("tisheng"):setVisible(isVisible)
    self:SetShortBtnsPosition()
end

function MainUI:SetShortBtnsPosition()
    local btnArrs = {"tisheng","Mail","Team","Chat","tishi"}
    local sx = self.m_pShortBtnSx
    local width = self.m_pShortBtnWidth
    for i = 1, #btnArrs do
        local btn = self.m_pShortBtnGp:getChildByName(btnArrs[i])
        if btn:isVisible() then
            btn:setPositionX(sx)
            sx = sx + width
        end
    end
end

function MainUI:setNewMailBtnVisible()
    -- body
    if self.m_pShortBtnGp == nil then
        return
    end
    local Mail = self.m_pShortBtnGp:getChildByName("Mail")
    Mail:setVisible(true)
    self:SetShortBtnsPosition()
end

function MainUI:setNewMailBtnNoVisible()
    -- body
    if self.m_pShortBtnGp == nil then
        return
    end
    local Mail = self.m_pShortBtnGp:getChildByName("Mail")
    Mail:setVisible(false)
    self:SetShortBtnsPosition()
end

--[[
isOpen:true-展开 false-折叠
]]
function MainUI:openOrCloseBtmBtn(isOpen, noAnim)
    local panel = self.m_pMainUI
    local sender = panel:getChildByName("locker")
    sender:setSelected(isOpen)

    local btngp1 = panel:getChildByName("ButtonGroup4")
    local btngp2 = panel:getChildByName("ButtonGroup3")
    
    btngp2:stopAllActions()
    btngp1:stopAllActions()
    self._isShowNow = isOpen
    if sender:isSelected() then
        if noAnim then
            btngp2:setPosition(self.m_pShowPos)
            btngp1:setPosition(self.m_hidePos)
        else
            btngp2:runAction(cc.MoveTo:create(0.5, self.m_pShowPos))
            btngp1:runAction(cc.MoveTo:create(0.5, self.m_hidePos))
        end
    else
        if noAnim then
            btngp2:setPosition(self.m_hidePos)
            btngp1:setPosition(self.m_pShowPos)
        else
            btngp2:runAction(cc.MoveTo:create(0.5, self.m_hidePos))
            btngp1:runAction(cc.MoveTo:create(0.5, self.m_pShowPos))
        end
    end
end

--[[
isOpen:true-展开 false-折叠
新的特效
]]
function MainUI:openOrCloseBtmBtnNew(isOpen, noAnim)
    -- body
    if self._isShowNow == isOpen then
        return
    end
    local panel = self.m_pMainUI
    local sender = panel:getChildByName("locker")
    sender:setSelected(isOpen)
    local btngp1 = panel:getChildByName("ButtonGroup4")
    local btngp2 = panel:getChildByName("ButtonGroup3")
    local btngp8 = panel:getChildByName("ButtonGroup8")
    local size1 = btngp1:getContentSize()
    local size2 = btngp2:getContentSize()
    local size3 = btngp8:getContentSize()

    btngp2:stopAllActions()
    btngp1:stopAllActions()
    btngp8:stopAllActions()
    self._isShowNow = isOpen
--    ----print("openOrCloseBtmBtnNew sender:isSelected()", sender:isSelected())
    if not sender:isSelected() then
        if noAnim then
            btngp2:setPosition(cc.p(self.m_pShowPos.x + size1.width, self.m_pShowPos.y))
            btngp1:setPosition(cc.p(self.m_hidePos.x + size2.width, self.m_hidePos.y))
            btngp8:setPosition(cc.p(self.m_ShowPosGp8.x + size3.width, self.m_ShowPosGp8.y))
        else
            btngp2:runAction(cc.MoveTo:create(0.5, cc.p(self.m_pShowPos.x + size1.width, self.m_pShowPos.y)))
            btngp1:runAction(cc.MoveTo:create(0.5, cc.p(self.m_hidePos.x + size2.width, self.m_hidePos.y)))
            btngp8:runAction(cc.MoveTo:create(0.5, cc.p(self.m_ShowPosGp8.x + size3.width, self.m_ShowPosGp8.y)))
        end
    else
        if noAnim then
            btngp2:setPosition(self.m_pShowPos)
            btngp1:setPosition(self.m_hidePos)
            btngp8:setPosition(self.m_ShowPosGp8)
        else
            btngp2:runAction(cc.MoveTo:create(0.5, self.m_pShowPos))
            btngp1:runAction(cc.MoveTo:create(0.5, self.m_hidePos))
            btngp8:runAction(cc.MoveTo:create(0.5, self.m_ShowPosGp8))
        end
    end
end

function MainUI:getMainBtnPos(ret)
    local id = ret.id
    local btn = self.m_btnMap[id]
    if btn then
        ret.pos = btn:convertToWorldSpace(cc.p(btn:getContentSize().width/2, btn:getContentSize().height/2))
    end
end

function MainUI:getOpenBtmBtnOpenOrNot(ret)
    -- local panel = self.m_pMainUI
    -- local sender = panel:getChildByName("locker")
    -- ret.isOpen = sender:isSelected()
end

function MainUI:dealFunctionOpen(value)
    local function CheckShouchongState(id)
        if id ~= AppDef.EModuleID.EMID_SHOUCHONG then
            return true
        end
        local state1 = LRoleDataMgr.m_firstRechargeState
        local state2 = LRoleDataMgr.m_secondRechargeState
        if state1 == 0 or state2 == 0 then
            return true
        end
        if state1 == -1 then
            LuaNetSendMsg:QueryKaifuHuodong(9,1)   --请求首充信息
        end
        return false 
    end
    local ids = value[4]
    -- dump(ids, "MainUI:dealFunctionOpen-->")
    if #ids <= 0 then
        return
    end
    local idstemp = {}
    for i=1,#ids do
        idstemp[ids[i]] = true
    end
    ids = idstemp

    local index = {}
    ----------------------------------------------
    local newOpenTb = {}
    Utils:SendMsg(LUIFunctionEvent.GetFuncOpenList, newOpenTb, true)
    ----------------------------------------------

    if self.m_ignoreFID then
        for k,v in pairs(ids) do
            if self.m_ignoreFID[k] then
                ids[k] = nil
            end
        end
    end
    ----------------------------------------------
    for k,v in pairs(ids) do
        local id = k
        local btn = self.m_btnMap[id]
        if btn and (not btn:isVisible()) and CheckShouchongState(id) then 
            btn:setVisible(true)
            if Utils:ToBool(newOpenTb[id]) then
                btn:setOpacity(0)
            end
            if self.m_idMap[id] then
                index[self.m_idMap[id]] = true
            end
        end
    end
    -- dump(index)
    -- for k,v in pairs(index) do
    --     self:sortButtonGroup(k)
    -- end

    local openFunctions = value[4]
    if Utils:containValue(openFunctions, AppDef.EModuleID.EMID_SJBUZHEN) then
        LuaNetSendMsg:QueryFormationInfo()
    end
end

function MainUI:ForgeTouchCallback(sender)
    Utils:OpenFunction(AppDef.EModuleID.EMID_DUANZAO)
end

function MainUI:FuBenTouchCallback(sender)
    Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_ZHUXIANFUBEN)
end

function MainUI:ZheKou1Callback(sender)
    Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_GIFT_ZHEKOU1,nil,true)
end

function MainUI:ZheKou2Callback(sender)
    Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_GIFT_ZHEKOU2,nil,true)
end

function MainUI:ZheKou3Callback(sender)
    Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_GIFT_ZHEKOU3,nil,true)
end

function MainUI:PetTouchCallback(sender)
    if #LRoleDataMgr.Pet.petlist < 1 then
        Utils:ShowScrollTips(GUITips.UI_No_Shenjiang_Tips)
        return
    end
    Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_SHENJIANG)
end

function MainUI:LuckDrawTouchCallback(sender)
    -- -- Utils:OpenFunction(AppDef.EModuleID.EMID_CHOUKA)
      Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_CHOUKA)
      -- local data = {}
      -- data.petId = 39
      -- data.petLevel = 1
      -- data.petStar = 1
      -- Utils:InitUI("HappyDraw.SingleDrawResultUI", AppDef.UIType.PopWindow, data)
end

function MainUI:WanFaCallback(sender)
    Utils:OpenFunction(AppDef.EModuleID.EMID_WANFA,nil,true)
end

function MainUI:RankCallback(sender)
    Utils:OpenRankUI(AppDef.EModuleID.EMID_RANK_Fuben)
end

function MainUI:dealFunctionStartFly(factionId)
    if factionId == nil or factionId < 100 then
        return
    end
    performWithDelay(self.m_pUILayer, function(sender)
        local btn = self.m_btnMap[factionId]
        if btn then
            btn:setVisible(true)
            btn:setOpacity(1)
        end
        local index = self.m_idMap[factionId]
        -- ----print('dealFunctionStartFly:factionId------------------>', factionId, index)
        if index then
            self:sortButtonGroup(index, 0.1)
        end
    end, 0.435)
end

function MainUI:dealFunctionFinishFly(factionId)
    if factionId == nil or factionId < 100 then
        return
    end
    -- ----print('dealFunctionFinishFly:factionId------------------>', factionId)
    local btn = self.m_btnMap[factionId]
    if btn then
        btn:setVisible(true)
        btn:setOpacity(255)
    end
end

function MainUI:dealPushFuncOpenList(ids)
    local index = {}
    ----------------------------------------------
    for i=1,#ids do
        local id = ids[i]
        local btn = self.m_btnMap[id]
        if btn and btn:isVisible() and self.m_idMap[id] then
            -- ----print('MainUI:dealPushFuncOpenList-->', btn:getName())
            btn:setOpacity(0)
            index[self.m_idMap[id]] = true
        end
    end
    -- dump(index)
    for k,v in pairs(index) do
        self:sortButtonGroup(k)
    end
end

-- function MainUI:dealGuideCheck(stepId)
--     local threePanel = {}
--     threePanel[GuideDef.StepId.Guide_DZ] = 1
--     threePanel[GuideDef.StepId.Guide_SHENJ] = 1
--     threePanel[GuideDef.StepId.Guide_ZM] = 1
--     local fourPanel = {}
--     local ret = {}
--     self:getOpenBtmBtnOpenOrNot(ret)
--     if threePanel[stepId] then
--         if not ret.isOpen then
--            self:openOrCloseBtmBtnNew(true, true)
--         end
--     elseif fourPanel[stepId] then
--         if ret.isOpen then
--            self:openOrCloseBtmBtnNew(false, true)
--         end
--     end
-- end

function MainUI:CheckFactionBtn()
    local isVisible = false
    if LRoleDataMgr.Faction.InviteList then
        isVisible = #LRoleDataMgr.Faction.InviteList > 0
    end
    self.m_pShortBtnGp:getChildByName("tishi"):setVisible(isVisible)
    self:SetShortBtnsPosition()
end

function MainUI:DealFundRebateData(msg)
    local jiJinBtn = self.m_buttonGroupMap[BTN_NAME_JiJin]
    if jiJinBtn then
        -- dump(msg, "msg---->")
        local cdTime,buyId,datas = msg[1],msg[2],msg[3]
        if cdTime == nil and buyId == nil then
            jiJinBtn:setVisible(false)
        elseif cdTime <= 0 and buyId <= 0 then
            jiJinBtn:setVisible(false)
        elseif buyId > 0 and datas ~= nil then
            jiJinBtn:setVisible(LRedDotCheckMgr:FundRebateShowCheck())
        elseif cdTime > 0 and buyId <= 0 then
            jiJinBtn:setVisible(true)
            self:sortButtonGroup(2)
            if self.m_jijinTimer then
                self.m_jijinTimer:Destory()
                self.m_jijinTimer = nil
            end
            self.m_jijinTimer = TimerLabelUI:New(jiJinBtn, cdTime, function(pNode)
                local _ = pNode and pNode:setVisible(LRedDotCheckMgr:FundRebateShowCheck())
            end, function()
            end)
            self.m_jijinTimer:start()
        end
    end
end

function MainUI:DealHuoyueFundRebateData(msg)
    -- body
    local huoyueJiJin = self.m_buttonGroupMap[BTN_NAME_huoyueJiJin]
    if huoyueJiJin then
        -- dump(msg, "msg---->")
        local cdTime,buyId,datas = msg[1],msg[2],msg[3]

        --print("DealHuoyueFundRebateData ==>", cdTime)
        if cdTime == nil then
            huoyueJiJin:setVisible(false)
        elseif cdTime <= 0 then
            if buyId > 0 then
                huoyueJiJin:setVisible(LRedDotCheckMgr:HuoYueJiJinShowCheck())
            else
                huoyueJiJin:setVisible(false)
            end
        else
            huoyueJiJin:setVisible(true)
            self:sortButtonGroup(2)
            if self.m_HuoyueJijinTimer then
                self.m_HuoyueJijinTimer:Destory()
                self.m_HuoyueJijinTimer = nil
            end
            self.m_HuoyueJijinTimer = TimerLabelUI:New(huoyueJiJin, cdTime, function(pNode)
                local _ = pNode and pNode:setVisible(false)
            end, function()
            end)
            self.m_HuoyueJijinTimer:start()
        end
    end
end


function MainUI:UIAdaptation( ... )
    -- body
    local adaptSpace = 88
    local panel = self.m_pMainUI
    local pButtonGroup2 = panel:getChildByName("ButtonGroup2")
    pButtonGroup2:setPositionX(pButtonGroup2:getPositionX() + adaptSpace)
    self.m_pPreviewBtn:setPositionX(self.m_pPreviewBtn:getPositionX() + adaptSpace)

    self._panelQuestAndTeam:setPositionX(self._panelQuestAndTeam:getPositionX() - adaptSpace)
    self.m_pHeroTgtsPanel:setPositionX(self.m_pHeroTgtsPanel:getPositionX() - adaptSpace)
end


function MainUI:TimeCountDownEnd( label )
    -- body
    --刷新倒计时
    local tag = label:getTag()
--    ----print("TimeCountDownEnd", tag)
    if tag < 4 then
        LuaNetSendMsg:QueryWelFareInfo(0xff, 0)
    else
        LuaNetSendMsg:QuerySevenChargeInfo(35, 1)
    end  
--    self:RefreshPreview()
end

function MainUI:TimeReduce(pText, h, m, s, left)
    if pText == nil then
        return
    end

    -- if left < 0 then
    --     self:RefreshPreview()
    -- end

    local str = ""
    local day = 0
    if h > 24 then
        day = math.floor(h / 24)
        h = math.fmod(h, 24)
    end
    if day > 0 then
        str = str..tostring(day)..GUITips.Item_Info_Day
        str = str..string.format("%02d:%02d", h, m)
    else
        str = str..string.format("%02d:%02d:%02d", h, m, s)
    end
    
    pText:setString(str)
end


function MainUI:DealMiJingData(datas)
    if LRoleDataMgr.MyHeroInfo.SceneType ~= AppDef.SceneType.EAID_SHENJIEMIJING then
        return
    end
    if datas == nil or type(datas) ~= 'table' then
        self:UpdateHurtButton(false)
        return
    end
    for i=1,#datas do
        if datas[i].state == 1 then
            self:UpdateHurtButton(true)
            return
        end
    end
    self:UpdateHurtButton(false)
end

function MainUI:MyVIPTimeUpdate()
   
     local vipInfo = LRoleDataMgr.MyHeroInfo.MyVIPInfo
    if vipInfo.isHasMcCardTemp then   
        if self.bufferTimer then
           
            if self.pro == nil then
                local unlockSprite = cc.Sprite:createWithSpriteFrame(AppDef.spriteFrameCache:getSpriteFrame("res/UI/ui_juese/ui_jineng_kuang_xuanzhong_mask_02.png"))             
                self.pro = cc.ProgressTimer:create(unlockSprite)
                self.bufferTimer:addChild(self.pro) 
                self.pro:setScale(0.5)
                self.pro:setPosition(cc.p(self.bufferTimer:getContentSize().width/2,self.bufferTimer:getContentSize().height/2))
              --  pro:setPosition(-1, -1)
                self.pro:setAnchorPoint(cc.p(0.5,0.5))
                self.pro:setType(kCCProgressTimerTypeRadial)--顺时针旋转

                self.pro:setReverseProgress(false)
                self.pro:setPercentage(100-100*vipInfo.mcLeftTime/480)--开始位置
                self.pro:setTag(9999)
               
            else

                self.pro:setPercentage(100-100*vipInfo.mcLeftTime/480)
                self.pro:setVisible(true)
            end
        end    
        vipInfo.mcLeftTime=vipInfo.mcLeftTime-1 
        if vipInfo.mcLeftTime<=0 then
         vipInfo.mcLeftTime=0
        end
    else
        if self.m_schedulerID then
            AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_schedulerID)
            self.m_schedulerID=nil
        end
         self.bufferTimer=nil
         self.pro=nil       
    end
end

function MainUI:DealNationalActivity( ... )
    -- body
    local btnWordCol = self.m_buttonGroupMap[BTN_NAME_wordCol]
    -- local isBtnWordCol = LRechargeDataMgr:isWelfareActivityOpen(38)
    -- btnWordCol:setVisible(isBtnWordCol)
    --之前是国庆集字活动, 现在改成双12集字活动,主界面先隐藏掉
    local isBtnWordCol = false
    btnWordCol:setVisible(isBtnWordCol)
    if isBtnWordCol then
        local data = LRechargeDataMgr:getTagDataById(38)
        local text = btnWordCol:getChildByName("Image"):getChildByName("Text")
        if self.timer1 == nil then
            self.timer1 = TimerLabelUI:New(text, nil, nil, handler(self, self.TimeReduce))
        end
        self.timer1:set(data.endTime, function( ... )
            -- body
            btnWordCol:setVisible(false)
            self:sortButtonGroup(7)
        end)
        self.timer1:start()
    end

    local btnNatGift = self.m_buttonGroupMap[BTN_NAME_nationalGift]
    -- local isBtnNatGift = LRechargeDataMgr:isWelfareActivityOpen(21)
    --之前是国庆送礼活动, 现在改成双12集字活动,主界面先隐藏掉
    local isBtnNatGift = false
    btnNatGift:setVisible(isBtnNatGift)
    if isBtnNatGift then
        local data = LRechargeDataMgr:getTagDataById(21)
        local text = btnNatGift:getChildByName("Image"):getChildByName("Text")
        if self.timer2 == nil then
            self.timer2 = TimerLabelUI:New(text, nil, nil, handler(self, self.TimeReduce))
        end
 
        self.timer2:set(data.endTime, function( ... )
            -- body
            btnNatGift:setVisible(false)
            self:sortButtonGroup(7)
        end)
        self.timer2:start()
    end
end

function MainUI:DealZaDanButon()
    local list = {20, 92}
    local tag = nil
    for i=1,#list do
        if LRechargeDataMgr:isWelfareActivityOpen(list[i]) then
            tag = list[i]
            break
        end
    end
    if tag == nil then
        return
    end
    local pBtn = self.m_buttonGroupMap[BTN_NAME_zhuanpan]
    if tag then
        local info = LRechargeDataMgr:getWelfareActivityData(tag)
        if info == nil or info.endTime <= 0 then
            return
        end
        local function zadanFinish()
            info.endTime = 0
            pBtn:setVisible(false)
            self:sortButtonGroup(7)
        end
        local textName = pBtn:getChildByName("Image"):getChildByName("Text")
        if self._TimerZhuanPan == nil then
            self._TimerZhuanPan = TimerLabelUI:New(textName, info.endTime or 1, zadanFinish, function(pText, h, m, s, left)
                info.endTime = left
                if h >= 24 then
                    local day = math.floor(h/24)
                    h = h - day*24
                    pText:setString(string.format("%d%s%02d:%02d", day, GUITips.UI_Arena_Msg1, h, m))
                elseif h > 0 then 
                    pText:setString(string.format("%02d:%02d:%02d", h, m, s))
                else
                    pText:setString(string.format("%02d:%02d", m, s))
                end
            end)
        else
            self._TimerZhuanPan:set(info.endTime, zadanFinish)
        end
        self._TimerZhuanPan:start()
        pBtn:setVisible(true)
        pBtn:setTag(tag)
    else
        pBtn:setVisible(false)
    end
    self:sortButtonGroup(7)
end

function MainUI:DealDiscountBagData(data)
    --dump(data.info,"DealDiscountBagData DealDiscountBagData=>")
    local op = data.type
    if op == nil then
        return
    end
    if data.info and data.info.leftTime and data.info.leftTime > 0 then
        self:AddDiscountBag(op, data.info)
    else
        self:RemoveDiscountBag(op)
    end
end

function MainUI:DiscountBagTimeReduce(pText, h, m, s, leftTime)
    if pText == nil then
        return
    end
    local day = math.floor(h / 24)
    if day > 0 then
        h = h - day * 24
        pText:setString(string.format("%d天%02d:%02d", day, h, m))
    else
        pText:setString(string.format("%02d:%02d:%02d", h, m, s))
    end
end

function MainUI:AddDiscountBag(index, info)
    if index == nil or info == nil or info.leftTime == nil then
        return
    end
    --insert/update data
    self.m_pDiscountBagData = self.m_pDiscountBagData or {}
    self.m_pDiscountBagTimer = self.m_pDiscountBagTimer or {}
    
    local isFind = false
    local data = {op=index, info=info}
    for i=1,#self.m_pDiscountBagData do
        local item = self.m_pDiscountBagData[i]
        if item and item.op == index then
            isFind = true
            self.m_pDiscountBagData[i] = data
            break
        end
    end
    if not isFind then
        table.insert(self.m_pDiscountBagData, data)
    end
    self:UpdateDiscountBag()
end

function MainUI:UpdateDiscountBag()
    if self.m_pDiscountBagData == nil then
        return
    end
    local si = 0
    local max = math.min(#self.m_pDiscountBagData, 3)
    for i=1,max do
        local item = self.m_pDiscountBagData[i]
        if item and item.op and item.info then
            local btn = self.m_buttonGroupMap["btn_Zhekou"..i]
            if btn ~= nil then
                si = i
                btn:setTag(item.op)
                btn:setVisible(true)

                local name = btn:getName()
                local pTimer = self.m_pDiscountBagTimer[name]
                if pTimer == nil then
                    local pText = btn:getChildByName("Image"):getChildByName("Text")
                    pTimer = TimerLabelUI:New(pText, nil, nil, handler(self, MainUI.DiscountBagTimeReduce))
                    self.m_pDiscountBagTimer[name] = pTimer
                end
                if pTimer then
                    pTimer:set(item.info.leftTime, function()
                        self:RemoveDiscountBag(btn:getTag())
                    end)
                    pTimer:start()
                end
            end
        end
    end
    for i=si+1,3 do
        local btn = self.m_buttonGroupMap["btn_Zhekou"..i]
        if btn ~= nil then
            btn:setTag(0)
            btn:setVisible(false)
            local pTimer = self.m_pDiscountBagTimer[btn:getName()]
            if pTimer then
                pTimer:stop()
            end
        end
    end
    self:sortButtonGroup(8)
end

function MainUI:RemoveDiscountBag(tag)
    if tag == nil or self.m_pDiscountBagData == nil then
        return
    end
    
    local isFind = false
    for i=1,#self.m_pDiscountBagData do
        local item = self.m_pDiscountBagData[i]
        if item and item.op == tag then
            isFind = true
            table.remove(self.m_pDiscountBagData, i)
            break
        end
    end
    if not isFind then
        return
    end
    self:UpdateDiscountBag()
end

return MainUI
