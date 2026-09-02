--[[
@通信接受处理命令，一部分在c#
@作者：陈伟
@创建日期：2016-04-22
]]
local WelfareActivityDef = require("View.WelfareActivity.WelfareActivityDef")
local ShopDef = require("View.Shop.ShopDef")
local function Debug(log)
end

local function LocalTestLog(log)
    if AppDef ~= nil and AppDef.LOCAL_TEST == true then
        local file = io.open("local_client.log", "a+")
        if file ~= nil then
            file:write(tostring(log), "\n")
            file:close()
        end
    end
end

LuaNetRecvdMsg = LNetBase:New()
LuaNetRecvdMsg.__index = LuaNetRecvdMsg
local this  = LuaNetRecvdMsg
-- function LuaNetRecvdMsg.New()
--     local o = {}
--     setmetatable(o,LuaNetRecvdMsg)
--     o.Init()
--     return o
-- end

function LuaNetRecvdMsg.Init()
    this.m_pRegisterMsg = RegisterNetRecvdMsg:new(CEnum.TCPRecvdEvent.RegisterMsg)
    this.AddNetFunctions()
    --this.InitCommonMsgs()
end

--[[
初始化一些常用的消息
]]
function LuaNetRecvdMsg.InitCommonMsgs()
end

--接受新功能，需要在此注册协议
function LuaNetRecvdMsg.AddNetFunctions()
    --登录服相关命令
    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_ACC_REG,this.DealMsgAcLoginReg)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_ACC_LOGIN,this.DealMsgAcLogining)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_ACC_ANNOUNCEMENT,this.DealMsgBehalfAnnouncement)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_ACC_GAME_ROLES,this.DealMsgRoles)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_ACC_LINEUP,this.DealMsgLineUpStatus)
    this:SendMsg(this.m_pRegisterMsg)

    ---------------------------------游戏服相关-------------------------------------------
    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_LOGIN,this.DealMsgLogin)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_CHECKNAME,this.DealMsgCheckHeroName)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_CREATE_HERO,this.DealMsgCreateHero)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_CHOOSE_HERO,this.DealMsgStartGame)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_QUERY_PACK,this.DealMsgPackageList)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_REQ_ITEM,this.DealMsgItemDetail)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_QUERY_EQUIP,this.DealMsgEquipList)
    this:SendMsg(this.m_pRegisterMsg)

    -- this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_GET_ALL_SKILL,this.DealMsgHeroSkillList)
    -- this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_UPDATE_SKILL,this.DealMsgUpdateHeroSkill)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_UPDATE_CHAR,this.DealMsgUpdateChar)
    this:SendMsg(this.m_pRegisterMsg)
    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_PET_UPDATE,this.DealMsgUpdatePet)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_EQUIP_ITEM,this.DealMsgUpdateEquipItem)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_UPDATE_EQUIP,this.DealMsgUpdateEquip)
    this:SendMsg(this.m_pRegisterMsg)
    -- this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_MISSION_NOGET_LIST,this.DealMsgUnGetTaskInfo)
    -- this:SendMsg(this.m_pRegisterMsg)


    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_MISSION_LIST,this.DealMsgTaskInfo)
    this:SendMsg(this.m_pRegisterMsg)


    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_CHIBANG_DO,this.DealMsgChiBangInfo)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_UPDATE_PACKAGE,this.DealMsgUpdatePackage)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_OPEN_PACKAGE_OPTION,this.DealMsgUnLockPackage)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_CLIENT_SKILLPART_INFO,this.DealMsgHeroSkillNextLvDep)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_CLIENT_LEARN_SKILL,this.DealMsgHeroSkillUpGradeOneTime)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_CLIENT_RANKLIST, this.DealMsgRankList)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_CLIENT_XIANHUA, this.DealMsgXianHuaRankList)
    this:SendMsg(this.m_pRegisterMsg)
    
    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_HE_CHENG_OPTION,this.DealMsgSynthesis)
    this:SendMsg(this.m_pRegisterMsg)

    -- this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_PRO_EQUIP_FORGE,this.DealMsgEquipForgeRes)
    -- this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_SHENQI,this.DealMsgShenQi)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_ARENA,this.DealMsgArenaInfo)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_DAILY_ACTIVITY,this.DealMsgActivityList)
    this:SendMsg(this.m_pRegisterMsg)   

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_SERVER_SYSTEM_TIP,this.DealMsgSystemTips)
    this:SendMsg(this.m_pRegisterMsg)
   
    -- this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_NPC_CHAT,this.DealMsgNpcChat)
    -- this:SendMsg(this.m_pRegisterMsg)

    -- this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_MISSION_CHANGED,this.DealMsgTaskUpdate)
    -- this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_HORSE_DO,this.DealMsgHorseInfo)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_CLIENT_XINSHI,this.DealMsgQueryMails)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_QUIRY_COPYINFO,this.DealMsgCopyInfo)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_PET_COPY,this.DealMsgPetCopyInfo)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_UPDATE_CST,this.DealUpdateClientCST)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_VIP_INFO,this.DealMsgVIPInfo)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_CLIENT_MARKET,this.DealMsgShop)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_SYS_TIME,this.DealMsgSYSTime)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_CHAT,this.DealMsgChatMsg)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_SYS_MSG, this.DealMsgSYSAnoncement)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_SYS_LEITAISAI, this.DealMsgSYSLeiTaiAnoncement)
    this:SendMsg(this.m_pRegisterMsg)
    
    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_CHAT_BPSYS, this.DealBPSysMsg)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_TEAM_OPERATION, this.DealMsgTeamOperation)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_GUESSFIST, this.DealMsgGuessFist)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_BANGPAI, this.DealMsgBangPaiOption)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_BANGPAIWAR, this.DealMsgBangPaiWar)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_CLIENT_HUODONG_OPTION, this.DealHuoDong, true)
    this:SendMsg(this.m_pRegisterMsg)

    -- this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_QUERY_FRIENDS, this.DealMsgFriendsList)
    -- this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_DEAL_GUIDE_INDO, this.DealMsgGuideIndo)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_MY_BANG, this.DealMsgMyBangPai)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_FACTION_ZONE, this.DealMsgFactionZone, true)
    this:SendMsg(this.m_pRegisterMsg)
    
    -- this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_ADD_HOT, this.DealMsgAddFriends)
    -- this:SendMsg(this.m_pRegisterMsg)

    -- this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_LIST_BLACK, this.DealMsgBlackList)
    -- this:SendMsg(this.m_pRegisterMsg)

    -- this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_ADD_BLACK, this.DealMsgAddBlack)
    -- this:SendMsg(this.m_pRegisterMsg)

    -- this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_DEL_BLACK, this.DealMsgDelBlack)
    -- this:SendMsg(this.m_pRegisterMsg)

    -- this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_SERCHPLAYER, this.DealMsgSerchPlayer)
    -- this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_KAIFUHUODONG, this.DealMsgKaifuHuodong)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_DAILYBOSSTASK, this.DealMsgDailyBoss)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_CONVOY, this.DealMsgConvoy)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_PLAYER_DETAIL, this.DealMsgOtherPlayerInfo)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_SERVER_TOWER_SHOWBAZHU, this.DealMsgTower)
    this:SendMsg(this.m_pRegisterMsg)
    

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_LIST_TITLE, this.DealMsgMedalList)
    this:SendMsg(this.m_pRegisterMsg)
   
    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_USE_TITLE, this.DealMsgUseMedal)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_GET_PET, this.DealLuckDraw)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_STAGE_GOAL, this.DealStageGoal)
    this:SendMsg(this.m_pRegisterMsg)

    --战斗
    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_ENTER_BATTLE, this.RecvServerEnterBattle)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_BATTLE, this.RecvDoBattle)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_BATTLE_OVER, this.RecvBattleOver)
    this:SendMsg(this.m_pRegisterMsg)
    ------------------------------------------
    
    -- this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_CLIENT_OUTLINEEXP, this.DealOfflineExp)
    -- this:SendMsg(this.m_pRegisterMsg)
    
    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_PAY_PRICE_LIST, this.DealMsgPayPricelist)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_PET_INFO, this.DealMsgPetInfo)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_PET_DO, this.DealMsgPetUpdate)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MGS_PETEQUIP_BAG, this.DealMsgPetEquip)
    this:SendMsg(this.m_pRegisterMsg)
    
    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_XIUXIANLILIAN, this.DealMsgLiLianInfo)
    this:SendMsg(this.m_pRegisterMsg)
    
    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_FLYFARY, this.DealMsgFlyFaryField)
    this:SendMsg(this.m_pRegisterMsg)
    
    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_CANGBAOTU, this.DealMsgCangBaotuInfo)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_ADVANCEPATH_INFO, this.DealMsgMonopoly)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_EVERY_QUETION, this.DealAnswerQuestion)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_WORSHIP_INFO, this.DealMsgMobaiInfo, true)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_ITEM_DEF, this.DealMsgUnExistItemInfo)
    this:SendMsg(this.m_pRegisterMsg)

    -----阵法-----------------
    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_FORMATION, this.DealMsgFormation)
    this:SendMsg(this.m_pRegisterMsg)
    
    --------------------------

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_SHILIAN, this.DealMsgShilian)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_PET_ANI_NOTIFY, this.DealPetAnimNotify)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_LEVELUP_SERVER, this.DealMsgUpgrade)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_GET_SAVE_VAL, this.DealMsgSetttingInfo)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_SAVE_STR_VAL, this.DealMsgSetttingStringInfo)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_MATCH, this.DealMsgMatchInfo)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_TASK_LIST, this.DealMsgTaskList)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_TIPSJUMP, this.DealMsgJumpRechargeUI)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_AUTOPATH_POS, this.DealMsgAutoPath)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_AUDIO_PLAY, this.DealMsgAudioPlay)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_FISHING_INFO, this.DealMsgFish, true)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_ACC_ANNOUNCEMENT, this.DealMsgLoginNotice)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_CLIENT_ACCOUNT, this.DealMsgGameNotice)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_BATTLE_OVER_INFO, this.DealBattleOverInfo)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_XIANHUA_EFFECT, this.DealReceivedFlower)
    this:SendMsg(this.m_pRegisterMsg)
      
    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_HOOK_STATE, this.DealServerHookState)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_TASK_QUERY_PET, this.DealQueryPetInfo)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_FIGHT_SPEED, this.DealFightSpeed)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_QUERY_RESRECOVERY, this.DealQueryResRecovery)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_ACT_FENGSHEN, this.DealActivityFengShen)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_CROSS_SERVER, this.DealCrossServer)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_LEITAISAI, this.DealLeiTaiSai)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_LUNDAO, this.DealLunDao)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_WEIWODUXIAN, this.DealWeiWoDuXian)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_MULTISERVER_BOSS, this.DealMulitiServerBoss)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_UPDATE_FIGHT_HP, this.DealUpdateFightHp)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_JINGJIE,this.DealMsgJingjie)--境界
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.NPC_DIA_CLICK, this.DealMsgChangeName)--使用特殊物品
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_ACROSSSER, this.DealMsgCrossser)--境界
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_PK, this.DealMsgPK)--境界
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_KUAFU_LABA, this.DealLaBaIsOpen)--跨服喇叭
    this:SendMsg(this.m_pRegisterMsg)
    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_WORLDLEVEL, this.DealWorldLevel)--世界等级
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_IOS_GET_ORDERID, this.DealGetIAPOrderId)--获取IOS的orderId
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_PRO_CHARGE, this.DealIapValidateResulet)--获取IOS的orderId
    this:SendMsg(this.m_pRegisterMsg)


    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_OVER_DAY, this.DealOverDayMsg)--获取IOS的orderId
    this:SendMsg(this.m_pRegisterMsg)

-----------------------------------------------------------------------------------
    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_QUERY_FUBENMAP, this.DealBigMapMsg)--推图版本,副本协议
    this:SendMsg(this.m_pRegisterMsg)


    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_QUERY_TILI, this.DealTili)--体力协议
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_HERO_BOOK, this.DealHeroBook)--图鉴协议
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_XUEZHAN, this.DealXueZhan)--英勇试炼(血战)
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_JUMP_BATTLE, this.DealJumpBattle)--跳过战斗
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_BP_Fuben, this.DealBPFuben)--
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_FRIENDS, this.DealFriends)--
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_RED_POINT, this.DealRedPoint)--
    this:SendMsg(this.m_pRegisterMsg)

    this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_YOULI, this.DealYouLi)--
    this:SendMsg(this.m_pRegisterMsg)
end

--游历三界
function LuaNetRecvdMsg.DealYouLi(stream)
    local op = stream:ReadByte()
    print("DealYouLi DealYouLi DealYouLi op",op)
    if op == 1 then--当前游历信息获取
        local data = LActivityManager:GetYouLiData()
        local num = stream:ReadByte()
        print("DealYouLi DealYouLi DealYouLi num",num)
        for i=1,num do
            local value = {}
            value.id = stream:ReadByte()
            value.mType = stream:ReadByte()--1,2,3初级、中级、高级
            value.cnt = stream:ReadByte()
            value.heroId = stream:ReadWord()
            value.lastTime = stream:ReadUInt()--上次收获的时间戳
            value.endTime = stream:ReadUInt()--本次游历结束时间
            value.suiNum = stream:ReadWord()--英雄碎片数量
            value.rewards = {}
            local rewardNum = stream:ReadByte()
            for n=1,rewardNum do
                value.rewards[n] = {}
                this.ReadRewardData(value.rewards[n],stream)
            end
            value.dialogIds = {}
            local dialogNum = stream:ReadByte()
            for n=1,dialogNum do
                value.dialogIds[n]= stream:ReadWord()
            end
            data:SetData(value)
            dump(value.rewards)
            dump(value.dialogIds)
        end
        dump(data,"DealYouLi DealYouLi DealYouLi 1")
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIActivityEvent.RefreshYouLiUI)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
    elseif op == 2 then--开始游历
        local suc = stream:ReadByte()
        print("DealYouLi DealYouLi DealYouLi 2",suc)
        if suc == 0 then
            local msg = stream:ReadString()
            if #msg > 0 then
                Utils:ShowScrollTips(msg)
            end
            return
        end
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIActivityEvent.StartYouLi)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
    elseif op == 3 then--领取奖励
        local suc = stream:ReadByte()
        print("DealYouLi DealYouLi DealYouLi 3",suc)
        if suc == 0 then
            local msg = stream:ReadString()
            if #msg > 0 then
                Utils:ShowScrollTips(msg)
            end
            return
        end
        
    end
end

function LuaNetRecvdMsg.DealRedPoint(stream)
    local op = stream:ReadByte()
    --print("------------------DealRedPoint-----------------------------",op)
    if op ~= 1 and op ~= 2 then
        return
    end
    local redType = stream:ReadWord();
    local status = stream:ReadByte();
    print("redType",redType,"status",status)
    local data = {};
    data.id = redType;
    if status == 1 then
        data.isShow = true;
    else
        data.isShow = false;
    end
    
    Utils:SendMsg(LUILogicEvent.RedDotStateUpdate,data);
end

function LuaNetRecvdMsg.DealFriends(stream)
    local op = stream:ReadByte();
    -- print("=------------------------DealFriends---------------------------------",op)
    if op == 1 then
        this.ReadFriendList(stream);
    elseif op == 2 then
        this.ReadFriendApplyList(stream);
    elseif op == 3 or op == 5 or op == 6 then
        if op ~= 6 then
            local roleId = stream:ReadUInt();
        end
        local success = stream:ReadByte()
        if success == 0 then
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg);   
        else
            if op == 3 then
                local msg = stream:ReadString()
                Utils:ShowScrollTips(msg);   
                LuaNetSendMsg:QueryFriendList()
            elseif op == 5 then
                local msg = stream:ReadString()
                Utils:ShowScrollTips(msg);   
            elseif op == 6 then
                --一键赠送
                local num = stream:ReadByte();
                --print("num",num)
                for i = 1, num do
                    local id = stream:ReadUInt();
                    --print("id",id)
                    local friendData = LRoleDataMgr.Social:GetMyFriendData(id);
                    if friendData then
                        friendData.sendFlag = 1
                    end
                end
                LGameMsg.m_netDealMsg:Change(LUISocialEvent.UpdateFriendGift)
                this:SendMsg(LGameMsg.m_netDealMsg)
            end
        end
    elseif op == 4 then
        this.DealMsgAddFriends(stream);
    elseif op == 7 then
        this.DealGotGift(stream);
    elseif op == 8 then
        --一键领取礼物
        local success = stream:ReadByte();
        if success == 0 then
            local msg = stream:ReadString();
            if string.len(msg) > 0 then
                Utils:ShowScrollTips(msg);
            end
        else
            LRoleDataMgr.Social._friendGetGiftLeft = stream:ReadByte();
            local num = stream:ReadByte();
            --print("num",num)
            local arr = {};
            for i = 1, num do
                LRoleDataMgr.Social:DeleteFriendGift(stream:ReadUInt());
            end

            LRoleDataMgr.Social:CheckFriendGiftRedDot();
            Utils:SendMsg(LUISocialEvent.UpdateFriendGift)
        end
    elseif op == 9 then
        LRoleDataMgr.Social:DecodeFriendGiftFromServer(stream);
        Utils:SendMsg(LUISocialEvent.UpdateFriendGift)
    elseif op == 10 then
        --[[
        删除好友
        ]]
        local roleId = stream:ReadUInt();
        --print("delete roleId",roleId);
        local success = stream:ReadByte()
        if success == 1 then
            LRoleDataMgr.Social:delFriend(roleId);
            LGameMsg.m_netDealMsg:Change(LUISocialEvent.updateFriendLayer)
            this:SendMsg(LGameMsg.m_netDealMsg)
        else
        
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg);
        end
    elseif op == 11 then
        --一键接受/拒绝好友申请
        --[[
        op=11   accept  isSuccess    msg
        1byte   1byte     1byte    string
        ]]
        local accept = stream:ReadByte();
        local success = stream:ReadByte();
        local msg = stream:ReadString();
        if string.len(msg) > 0 then
            Utils:ShowScrollTips(msg);
        end
        if success == 0 then
            
        else
            local num = stream:ReadByte();
            local arr = {};
            for i = 1, num do
                LRoleDataMgr.Social:DeleteFriendApplyList(stream:ReadUInt());
            end
            if accept == 1 then
                LuaNetSendMsg:QueryFriendList();
            end

            LRoleDataMgr.Social:CheckFriendApplyRedDot()
        end
    elseif op == 12 then
        this.DealMsgBlackList(stream);
    elseif op == 13 or op == 14 then
        --删除黑名单返回
        --[[
        op=13  roleId  isSuccess   msg
        1byte  4byte     1byte    string
        ]]
        local roleId = stream:ReadUInt();
        --print("delete roleId",roleId);
        local success = stream:ReadByte()
        if success == 1 then
            if op == 13 then
                LRoleDataMgr.Social:delFriend(roleId);

                LGameMsg.m_netDealMsg:Change(LUISocialEvent.updateFriendLayer)
                this:SendMsg(LGameMsg.m_netDealMsg)
            elseif op == 14 then
                LRoleDataMgr.Social:DelBlack(roleId);
                Utils:SendMsg(LUISocialEvent.updateBlackList);
            end
        end
        local msg = stream:ReadString()
        Utils:ShowScrollTips(msg);
    elseif op == 15 then
        this.DealRecommendList(stream);
    elseif op == 16 then
        local success = stream:ReadByte();
        if success == 0 then
            local msg = stream:ReadString();
            Utils:SendMsg(LUILogicEvent.ShowSrcollTips,msg)
        end
    elseif op == 17 then
        --[[
        ]]
        local name = stream:ReadString();
        local suc = stream:ReadByte()
        if suc == 0 then
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg);     
            return;
        end

        local data = LFriendsData:New()
        data:DecodeApplyDataFromServer(stream);
        local fList = {data};
        LGameMsg.m_netDealMsg:Change(LUISocialEvent.updateSearchPlayer, fList)
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 31 then
        --[[
        数据更新
        ]]
        local opt = stream:ReadByte();
        if opt == 1 then
            --通知添加
            LuaNetSendMsg:QueryFriendList()
        elseif opt == 2 then
            --通知删除
            LuaNetSendMsg:QueryFriendList()
        end
    end
end

--[[
查找好友返回
]]
-- function LuaNetRecvdMsg.DealMsgSerchPlayer(stream)
--     local op = stream:ReadByte()
--     --print("DealMsgSerchPlayer",op)
--     if op == 1 then
--         local num = stream:ReadByte()
--         if num == 0 then
-- --          TipsMgr::GetInstance()->SetCenterTip(RES_STR(DataConsts::RSI_BSL_TIP2))
--             LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, GUITips.RSI_BSL_TIP2)
--             this:SendMsg(LGameMsg.m_scrollTipsMsg)
--             return
--         end
-- --        vector<FriendsData> fList
--         local fList = {}
--         for i = 1, num do
--             local data = LFriendsData:New()
--             data.id = stream:ReadUInt()
--             data.prof = stream:ReadByte()
--             data.profession = AppDef:GetProfNameBy5BaseIndex(data.prof)
--             data.sex = stream:ReadByte()
--             data.level = stream:ReadWord()
--             data.fightPower = stream:ReadUInt()
--             data.name = stream:ReadString()
--             table.insert(fList, data)
--         end
--         --更新列表
--         LGameMsg.m_netDealMsg:Change(LUISocialEvent.updateSearchPlayer, fList)
--         this:SendMsg(LGameMsg.m_netDealMsg)

--     elseif op == 2 then
--         local suc = stream:ReadByte()
--         if suc == 0 then        
-- --          TipsMgr::GetInstance()->SetCenterTip(stream:ReadString())
--             LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, stream:ReadString())
--             this:SendMsg(LGameMsg.m_scrollTipsMsg)
--         else
-- --          vector<FriendsData> fList
--             local fList = {}
--             local num = stream:ReadByte()
--             for i = 1, num do
--                 local data = LFriendsData:New()
--                 data.id = stream:ReadUInt()
--                 data.prof = stream:ReadByte()
--                 data.profession = AppDef:GetProfNameBy5BaseIndex(data.prof)
--                 data.sex = stream:ReadByte()
--                 data.level = stream:ReadWord()
--                 data.fightPower = stream:ReadUInt()
--                 data.name = stream:ReadString()
--                 table.insert(fList, data)
-- --              fList.push_back(data)
--             end 

--             LGameMsg.m_netDealMsg:Change(LUISocialEvent.updateSearchPlayer, fList)
--             this:SendMsg(LGameMsg.m_netDealMsg)

-- --          if(SerchPlayerPage* spage = GAMELAYER->GetSerchPlayerPage())
-- --          {
-- --              if(USELUAENV && OPENSOCIALMAINLUA)
-- --              {
-- --                  LuaMgr::GetInstance()->executeGlobalFunctionByUserData("SerchPlayerPage_LoadPlayer", (void*)&fList)
        
-- --              }else
-- --              {
-- --                  spage->LoadPlayer(fList)
-- --              }
--  --           }
      
--         end
--     end
-- end

--[[
推荐好友
]]
function LuaNetRecvdMsg.DealRecommendList(stream)
    local ret = LRoleDataMgr.Social:DecodeRecommendList(stream);
    if ret then
        Utils:SendMsg(LUISocialEvent.updateSearchPlayer);
    end
end

--黑名单
function LuaNetRecvdMsg.DealMsgBlackList(stream)
    LRoleDataMgr.Social:DecodeBlackList(stream)
    Utils:SendMsg(LUISocialEvent.updateBlackList);
end

--[[
收到礼物
]]
function LuaNetRecvdMsg.DealGotGift(stream)
    --[[
    op=7   roleId   isSuccess
    1byte   4byte     1byte
                     =0 failed    msg
                                string
                     =1 success  leftTimes   awardNum  { awardId   num }
                                   1byte       1byte      2byte   4byte
    ]]
    local roleId = stream:ReadUInt();
    --print("roleId",roleId);
    local success = stream:ReadByte()
    if success == 0 then
        local msg = stream:ReadString()
        Utils:ShowScrollTips(msg);
    else
        LRoleDataMgr.Social._friendGetGiftLeft = stream:ReadByte();

        local num = stream:ReadByte();
        --print("num",num,"left",LRoleDataMgr.Social._friendGetGiftLeft);
        local itemArr = {}
        for i = 1, num do
            -- local itemType = stream:ReadWord();
            -- local itemNum = stream:ReadUInt();
            -- table.insert(itemArr,{itemType,0,itemNum});
            local arr = LuaNetRecvdMsg.ReadCommonReward(stream)
            table.insert(itemArr,arr);
            --print("itemType",itemType,"itemNum",itemNum)
            
        end
        Utils:OpenRewardBox(GUITips.RSI_BOX_TIP2,itemArr,false,"",nil,nil);

        LRoleDataMgr.Social:DeleteFriendGift(roleId);
        LRoleDataMgr.Social:CheckFriendGiftRedDot();

        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUISocialEvent.UpdateGiftLeft)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
    end
end

--添加朋友
function LuaNetRecvdMsg.DealMsgAddFriends(stream)
--  stream:CreateReadStreamFromBuf(buf, len)
    local roleId = stream:ReadUInt();
    local accept = stream:ReadByte();
    local success = stream:ReadByte();
    --print("roleId",roleId,"success",success)
    local msg = stream:ReadString();
    Utils:ShowScrollTips(msg);
    if success == 1 then
        if accept == 1 then
            LuaNetSendMsg:QueryFriendList();
        end

        local ret = LRoleDataMgr.Social:DeleteFriendApplyList(roleId);
        if ret then
            Utils:SendMsg(LUISocialEvent.updateFriendApplyListLayer)

            LRoleDataMgr.Social:CheckFriendApplyRedDot()
        end
    end
end

function LuaNetRecvdMsg.ReadFriendList(stream)
    LRoleDataMgr.Social:DecodeFriendList(stream)
    LGameMsg.m_netDealMsg:Change(LUISocialEvent.updateFriendLayer)
    this:SendMsg(LGameMsg.m_netDealMsg)
end

function LuaNetRecvdMsg.ReadFriendApplyList(stream)
    LRoleDataMgr.Social:DecodeApplyList(stream);
    LGameMsg.m_netDealMsg:Change(LUISocialEvent.updateFriendApplyListLayer)
    this:SendMsg(LGameMsg.m_netDealMsg)
    LRoleDataMgr.Social:CheckFriendApplyRedDot()
end

function LuaNetRecvdMsg.DealBPFuben(stream)
    Utils:RemoveWaiting(LuaNetCmd.MSG_BP_Fuben);
    local op = stream:ReadByte();
    if op == 1 then
        --[[
        op=1   chapterNum {  chapId   complete   copyNum  [ copyId  complete   monsterNum ( zhenfaPos  leftHp   maxHp  ) ]  firstRankName }
        1byte    1byte        4byte     1byte     1byte      1byte    1byte       1byte        1byte    8byte   4byte          string
        ]]
        LRoleDataMgr.Faction.chapterArr = {}
        LRoleDataMgr.Faction.canFightNum = stream:ReadByte();
        LRoleDataMgr.Faction.factionChapterFightTotal = stream:ReadByte();
        local num  = stream:ReadByte();
        LRoleDataMgr.Faction._curChapter = nil
        for i = 1, num do
            local data = LFactionChapterData:New();
            data:InitFromServer(stream)
            LRoleDataMgr.Faction.chapterArr[data.id] = data
            -- table.insert(LRoleDataMgr.Faction.chapterArr,data)
        end
        Utils:SendMsg(LUIBangPaiEvent.GotChapterData)
    -- elseif op == 2 then
    --     --[[
    --     op=2   chapId  copyId   isSuccess    
    --     1byte   4byte   4byte     1byte      
    --                              =0 failed    msg
    --                                         string
    --                              =1 success  complete  zhenfaId  monsterNum [ zhenfaPos   pic   leftHp   maxHp  isDie ]  rankNum [ roleId   damage   name   head   power  level  vipLv ]  
    --                                           1byte      2byte     1byte       1byte     4byte  8byte    8byte  1byte     1byte     4byte    8byte  string  1byte  4byte  2byte  1byte
    --     ]]
    --     local cpId = stream:ReadUInt();
    --     --print("cpId",cpId)
    --     if LRoleDataMgr.Faction.chapterArr[cpId] == nil then
    --         return
    --     end
    --     local chData = LRoleDataMgr.Faction.chapterArr[cpId];
    --     local copyId = stream:ReadUInt();
    --     local success = stream:ReadByte();
    --     --print("success",success,"copyId",copyId)
    --     if success == 0 then
    --         local msg = stream:ReadString();
    --         Utils:SendMsg(LUILogicEvent.ShowSrcollTips,msg)
    --         return
    --     end

    --     local copyData = chData:GetCopyData(copyId);
    --     if copyData == nil then
    --         return
    --     end
    --     copyData:ReadDetailFromServer(stream);
    --     Utils:SendMsg(LUIBangPaiEvent.GotCopyData,copyData)
    elseif op == 3 then
        local cpId = stream:ReadUInt();
        --print("cpId",cpId)
        local copyId = stream:ReadUInt();
        local success = stream:ReadByte();
        --print("success",success,"copyId",copyId)
        if success == 0 then
            local msg = stream:ReadString();
            Utils:SendMsg(LUILogicEvent.ShowSrcollTips,msg)
            return
        end
        local fightData = {}
        fightData.wanFaId = AppDef.EModuleID.EMID_BPFUBEN
        LuaNetRecvdMsg.ReadBattleResult(stream,fightData)
        local damage = stream:ReadULongInt();
        --print("damage",damage)
        fightData.damage = damage;
        LRoleDataMgr.Faction.canFightNum = stream:ReadByte();
        --print("LRoleDataMgr.Faction.canFightNum",LRoleDataMgr.Faction.canFightNum)
        Utils:SendMsg(LUIBangPaiEvent.UpdateFightTimes)
    elseif op == 4 then
        --[[
        op=4   chapId  copyId  fightNum  { awardNum [ awardType   num ]  damage }  monsterNum  { zhenfaPos  leftHp  isDie }  canFightNum
        1byte   4byte   4byte   1byte        1byte      2byte    4byte   8byte       1byte        1byte      8byte  1byte       1byte
        ]]
        local cpId = stream:ReadUInt();
        --print("cpId",cpId)
        local copyId = stream:ReadUInt();
        local success = stream:ReadByte();
        --print("success",success,"copyId",copyId)
        if success == 0 then
            local msg = stream:ReadString();
            --print("msg",msg)
            Utils:SendMsg(LUILogicEvent.ShowSrcollTips,msg)
            return
        end

        local fightDataArr = {}
        local fightNum = stream:ReadByte();
        --print("fightNum",fightNum)
        for i = 1, fightNum do
            local fightData = {}
            local itemNum = stream:ReadByte()
            for j = 1, itemNum do
                local item = LuaNetRecvdMsg.ReadCommonReward(stream)
                
                -- item.itemId = stream:ReadWord()
                -- item.itemNum = stream:ReadInt()
                --print("item.itemId",item.itemId,"item.itemNum",item.itemNum)
                table.insert(fightData, item)
            end
            fightData.damage = stream:ReadULongInt();
            table.insert(fightDataArr,fightData);
        end
        LRoleDataMgr.Faction.canFightNum = stream:ReadByte();
        Utils:SendMsg(LUIBangPaiEvent.GotQuickFightData, fightDataArr)

        Utils:SendMsg(LUIBangPaiEvent.UpdateFightTimes)
    elseif op == 5 then

        local buffId = stream:ReadWord();
        local success = stream:ReadByte();
        --print("success",success,"buffId",buffId)
        if success == 0 then
            local msg = stream:ReadString();
            Utils:SendMsg(LUILogicEvent.ShowSrcollTips,msg)
            return
        end
        LRoleDataMgr.Faction.copyHuoyue = stream:ReadUInt();
        local num = stream:ReadByte();
        --print("num",num)
        LRoleDataMgr.Faction.buffList = {}
        for i = 1, num do
            local data = {}
            data.buffId = stream:ReadWord();
            data.level = stream:ReadByte();
            --print("data.buffId",data.buffId,"data.level",data.level)
            table.insert(LRoleDataMgr.Faction.buffList, data)
        end
        Utils:SendMsg(LUIBangPaiEvent.GotBuffData)
    elseif op == 6 then
        LRoleDataMgr.Faction.copyHuoyue = stream:ReadUInt();
        --print(" LRoleDataMgr.Faction.copyHuoyue", LRoleDataMgr.Faction.copyHuoyue)
        local num = stream:ReadByte();
        --print("num",num)
        LRoleDataMgr.Faction.buffList = {}
        for i = 1, num do
            local data = {}
            data.buffId = stream:ReadWord();
            data.level = stream:ReadByte();
            --print("data.buffId",data.buffId,"data.level",data.level)
            table.insert(LRoleDataMgr.Faction.buffList, data)
        end
        Utils:SendMsg(LUIBangPaiEvent.GotBuffData)
    elseif op == 7 then
        local cpId = stream:ReadUInt();
        --print("cpId",cpId)
        if LRoleDataMgr.Faction.chapterArr[cpId] == nil then
            return
        end
        local chData = LRoleDataMgr.Faction.chapterArr[cpId];
        
        local success = stream:ReadByte();
        --print("success",success,"copyId",copyId)
        if success == 0 then
            local msg = stream:ReadString();
            Utils:SendMsg(LUILogicEvent.ShowSrcollTips,msg)
            return
        end
        local num  = stream:ReadByte();
        --print("num",num)
        for i = 1, num do
            local copyId = stream:ReadUInt();
            --print("copyId",copyId)
            local copyData = chData:GetCopyData(copyId);
            if copyData == nil then
                break
            end
            copyData:ReadRankFromServer(stream);
        end
        
        Utils:SendMsg(LUIBangPaiEvent.GotRankData)
    elseif op == 8 then
        local cpId = stream:ReadUInt();
        --print("cpId",cpId)
        local copyId = stream:ReadUInt();
        local success = stream:ReadByte();
        --print("success",success,"copyId",copyId)
        if success == 0 then
            local msg = stream:ReadString();
            --print("msg",msg)
            Utils:SendMsg(LUILogicEvent.ShowSrcollTips,msg)
            return
        end
        local chData = LRoleDataMgr.Faction.chapterArr[cpId];
        if chData == nil then
            return
        end
        local copyData = chData:GetCopyData(copyId);
        if copyData == nil then
            return
        end
        copyData.rewardFlag = 2;

        local num = stream:ReadByte();
        --print("num",num)
        local itemArr = {}
        for i = 1, num do
            -- local itemType = stream:ReadWord();
            -- local itemNum = stream:ReadUInt();
            -- table.insert(itemArr,{itemType,0,itemNum});
            local arr = LuaNetRecvdMsg.ReadCommonReward(stream)
            table.insert(itemArr,arr);
        end
        Utils:OpenRewardBox(GUITips.RSI_BOX_TIP2,itemArr,false,"",nil,nil);
        Utils:SendMsg(LUIBangPaiEvent.UpdateCopyData,copyData);
    elseif op == 9 then
        LRoleDataMgr.Faction.todayHuoyue = stream:ReadUInt();
        --print("LRoleDataMgr.Faction.todayHuoyue",LRoleDataMgr.Faction.todayHuoyue)
        local num = stream:ReadByte();
        --print("num",num)
        LRoleDataMgr.Faction.huoyueAward = {};--活跃奖励
        for i = 1, num do
            local data = {}
            data.huoyueId = stream:ReadWord();
            --print("data.huoyueId",data.huoyueId)
            data.isGet = stream:ReadByte();
            --print("data.isGet",data.isGet)
            table.insert(LRoleDataMgr.Faction.huoyueAward, data);
        end
        Utils:SendMsg(LUIBangPaiEvent.UpdateTodayHuoyue);
    elseif op == 10 then
        local hid = stream:ReadWord();
        local success = stream:ReadByte();
        --print("success",success,"copyId",copyId)
        if success == 0 then
            local msg = stream:ReadString();
            --print("msg",msg)
            Utils:SendMsg(LUILogicEvent.ShowSrcollTips,msg)
            return
        end

        for i = 1, #LRoleDataMgr.Faction.huoyueAward do
            if LRoleDataMgr.Faction.huoyueAward[i].huoyueId == hid then
                LRoleDataMgr.Faction.huoyueAward[i].isGet = 2;
                break
            end
        end
        
        local num = stream:ReadByte();
        --print("num",num)
        local itemArr = {}
        for i = 1, num do
            -- local itemType = stream:ReadWord();
            -- local itemNum = stream:ReadUInt();
            -- table.insert(itemArr,{itemType,0,itemNum});
            local arr = LuaNetRecvdMsg.ReadCommonReward(stream)
            table.insert(itemArr,arr);
        end
        -- Utils:OpenRewardBox(GUITips.RSI_BOX_TIP2,itemArr,false,"",nil,nil);
        Utils:SendMsg(LUIBangPaiEvent.UpdateTodayHuoyue);
    elseif op == 21 then
        --章节新开启
        local cpId = stream:ReadUInt();
        print("章节新开启cpId",cpId)
        local chData = LRoleDataMgr.Faction.chapterArr[cpId];
        if chData ~= nil then
            return
        end
        chData = LFactionChapterData:New();
        chData:OpenFromServer(cpId, stream)
        LRoleDataMgr.Faction.chapterArr[chData.id] = chData
        Utils:SendMsg(LUIBangPaiEvent.UpdateChapterData, cpId);
    elseif op == 22 then
        --章节完成更新
        local cpId = stream:ReadUInt();
        --print("cpId",cpId)
        local chData = LRoleDataMgr.Faction.chapterArr[cpId];
        if chData == nil then
            return
        end
        chData.complete = stream:ReadByte();
        Utils:SendMsg(LUIBangPaiEvent.UpdateChapterData, cpId);
    elseif op == 23 then
        local cpId = stream:ReadUInt();
        --print("cpId",cpId)
        if LRoleDataMgr.Faction.chapterArr[cpId] == nil then
            return
        end
        
        local copyId = stream:ReadUInt();
        --print("copyId",copyId)
        local chData = LRoleDataMgr.Faction.chapterArr[cpId];
        if chData == nil then
            return
        end
        local copyData = chData:GetCopyData(copyId);
        if copyData == nil then
            return
        end
        copyData:UpdateFromServer(stream);
        Utils:SendMsg(LUIBangPaiEvent.UpdateCopyData,copyData)
    end
end


--[[
---跨服
]]
function LuaNetRecvdMsg.DealCrossServer(stream)
    LGameMsg.m_netDealMsg:Change(LGameEvent.CrossServer, stream)
    this:SendMsg(LGameMsg.m_netDealMsg)
end
function LuaNetRecvdMsg.DealBattleOverInfo(stream)
    local endMsg = stream:ReadString()
    Utils:ShowScrollTips(endMsg,true)
end

--[[
服务器告诉前端自动寻路
]]
function LuaNetRecvdMsg.DealMsgAutoPath(stream)
    LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.CanAutoPath)
    this:SendMsg(LGameMsg.m_baseMsgWithOne)
    if not LGameMsg.m_baseMsgWithOne.value then
        
        return
    end

    local params = {
        opt = stream:ReadByte(),--0代表Npc1代表怪物
        mapId = stream:ReadWord(),
        posx = stream:ReadWord(),
        posy = stream:ReadWord(),
        nId = stream:ReadWord(),
        missionId = stream:ReadWord(),
    }
    -- ------dump(params, "DealMsgAutoPath--->")
    if LRoleDataMgr.isInBattle then
        local function autoPath()
            LuaNetRecvdMsg.DealMsgAutoPath2(params)
        end
        Utils:SendMsg(LGameEvent.RegisterExitBattleCb, autoPath)
    else
        LuaNetRecvdMsg.DealMsgAutoPath2(params)
    end
end

function LuaNetRecvdMsg.DealMsgAutoPath2(params)
    if params == nil then
        return
    end
    local opt = params.opt
    local mapId = params.mapId
    local posx = params.posx
    local posy = params.posy
    local nId = params.nId
    local missionId = params.missionId

    if LRoleDataMgr.isHangUp == true then
        LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.HangUpEvent.StopHangUp)--
        this:SendMsg(LGameMsg.m_cBaseMsg)
    end

    if opt == 0 or opt == 1 then
        LuaNetSendMsg:QueryCanBattle(2)
    end
    local canJumpMap = true
    if LRoleDataMgr.MyHeroInfo.ConvoyType ~= 0 then
        canJumpMap = false
    end

    local function AutoPachEndCallback(npcId, npcIdx)
        LuaNetSendMsg:QueryCanBattle(3)
        if (npcId ~= nil and npcIdx ~= nil)
            and npcId > 0 
            and (nId == npcId) then
            if (opt == 0 or opt == 2) then
                LuaNetSendMsg:QueryNpcChatOpen(npcId, npcIdx, missionId)
            elseif opt == 1 then
                --挂机
                LGameMsg.m_baseMsgWithOne:Change(LUIRoleDataChangeEvent.StartHangUp, {0, npcId})
                this:SendMsg(LGameMsg.m_baseMsgWithOne)
                LGameMsg.m_hangUpMsg:Change(CEnum.HangUpEvent.StartHangUp, nId, 0)--
                this:SendMsg(LGameMsg.m_hangUpMsg)
            end
        end
		LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, false)
		this:SendMsg(LGameMsg.m_baseMsgWithOne)
    end

    LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Shop.ShopUI")
    this:SendMsg(LGameMsg.m_deleteUIMsg)

    LGameMsg.m_autoPathMsg:ChangeToStart(mapId,posx,posy,opt,bit.lshift(nId,16),true,canJumpMap,AutoPachEndCallback)
    this:SendMsg(LGameMsg.m_autoPathMsg)
	LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, true)
	this:SendMsg(LGameMsg.m_baseMsgWithOne)
end

-- local buffer = {}
-- function LuaNetRecvdMsg.DealMsgAutoPath(stream)
--     ------------print("DealMsgAutoPath")
    
--     local _opt = stream:ReadByte()--0代表Npc1代表怪物
--     local _mapId = stream:ReadWord()
--     local _posx = stream:ReadWord()
--     local _posy = stream:ReadWord()
--     local _nId = stream:ReadWord()
--     -- if buffer == nil then
--     --     buffer = {opt=0,mapId=0,posx=0,posy=0,nId=0}
--     -- end
--     -- if buffer.opt == _opt and buffer.mapId == _mapId and buffer.posx == _posx and buffer.posy == _posy and buffer.nId == _nId then
--     --     return
--     -- end
--     buffer.opt = _opt
--     buffer.mapId = _mapId
--     buffer.posx = _posx
--     buffer.posy = _posy
--     buffer.nId = _nId

--     local function AutoPachEndCallback(npcId, npcIdx)
--         LuaNetSendMsg:QueryCanBattle(3)
--         if (npcId ~= nil and npcIdx ~= nil)
--             and npcId > 0 
--             and (buffer.nId == npcId) then
--             if (buffer.opt == 0 or buffer.opt == 2) then
--                 LuaNetSendMsg:QueryNpcChatOpen(npcId, npcIdx)
--             elseif buffer.opt == 1 then
--                 --挂机
--                 LGameMsg.m_baseMsgWithOne:Change(LUIRoleDataChangeEvent.StartHangUp, {0, npcId})
--                 this:SendMsg(LGameMsg.m_baseMsgWithOne)
--                 LGameMsg.m_hangUpMsg:Change(CEnum.HangUpEvent.StartHangUp, buffer.nId, 0)--
--                 this:SendMsg(LGameMsg.m_hangUpMsg)
--             end
--         end
--         buffer.opt = nil
--     end

--     local function callback()
--         while true do
--             if buffer.opt ~= nil then
--                 local pMsg = LUIMsg1.New(LUILogicEvent.InitUI)
--                 pMsg:Change(LUILogicEvent.CanAutoPath)
--                 this:SendMsg(pMsg)
--                 if pMsg.value then
--                    if LRoleDataMgr.isHangUp == true then
--                        LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.HangUpEvent.StopHangUp)--
--                        this:SendMsg(LGameMsg.m_cBaseMsg)
--                    end

--                    if buffer.opt == 1 then
--                        LuaNetSendMsg:QueryCanBattle(2)
--                    end
--                    local canJumpMap = true
--                    if LRoleDataMgr.MyHeroInfo.ConvoyType ~= 0 then
--                        canJumpMap = false
--                    end

--                    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Shop.ShopUI")
--                    this:SendMsg(LGameMsg.m_initUIMsg)

--                    LGameMsg.m_autoPathMsg:ChangeToStart(buffer.mapId, buffer.posx, buffer.posy, buffer.opt, bit.lshift(buffer.nId,16), true, canJumpMap, AutoPachEndCallback)
--                    this:SendMsg(LGameMsg.m_autoPathMsg) 
--                 end
--             end

--             coroutine.yield()
--         end
--     end

--     if LRoleDataMgr.autoPathCor == nil then
--         LRoleDataMgr.autoPathCor = coroutine.create(callback)
--     end
--     local pMsg = LUIMsg1.New(LUILogicEvent.InitUI)
--     pMsg:Change(LUILogicEvent.CanAutoPath)
--     this:SendMsg(pMsg)
--     if pMsg.value then
--         coroutine.resume(LRoleDataMgr.autoPathCor)
--     end
-- end

--[[
处理切磋消息
]]
function LuaNetRecvdMsg.DealMsgMatchInfo(stream)
    local op = stream:ReadByte()

    if op == 1 then--被邀请切磋
        local id = stream:ReadUInt()
        local name = stream:ReadString()
        local tips = string.format(GUITips.RSI_MDSI_MATCH,name)

        if LUserConfigMgr:getShieldQieChuo() == 1 then
            LuaNetSendMsg:QueryMatchWithPlayer(1, 0, id)
            return
        end
        local function okCallback()
            LuaNetSendMsg:QueryMatchWithPlayer(1, 1, id)
        end

        local function cancelCallback()
            LuaNetSendMsg:QueryMatchWithPlayer(1, 0, id)
        end
        local msgData = 
        {
            isMatch=true,
            okCallback = okCallback,
            cancelCallback = cancelCallback,
            desc = tips,
        }
        LGameMsg.m_netDealMsg:Change(LUIMsgBoxEvent.ShowMsgBox, msgData)
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 2 then
        local succ = stream:ReadByte()
        if succ == 0 then
            Utils:ShowScrollTips(GUITips.RSI_MDSI_MSGI3)
        end
    end
end

function LuaNetRecvdMsg.DealMsgFormation(stream)
    local op = stream:ReadByte()
    if op == 1 then
        --[[
        阵容初始化数据
        ]]
        local fdata = LRoleDataMgr.myFormation
        -- fdata.myHeroPos = stream:ReadByte()
        fdata.useId = stream:ReadWord()
        local num = stream:ReadByte()
        local list = fdata:ResetMyFormations()
        for i = 1, num do
            local fid = stream:ReadWord()
            local flv = stream:ReadByte()
            table.insert(list,{fid,flv})
        end
        
        LRoleDataMgr.Pet.ShowPosList = {}
        local fightNum = stream:ReadByte()
        -- print("fightNum ===>", fightNum)

        --阵容展示位置
        for i=1, fightNum do
            local pid = stream:ReadWord()
            LRoleDataMgr.Pet.ShowPosList[i] = pid
        end

        --充值布阵位置
        LRoleDataMgr.Pet:ResetFightPos()

        --出站位置
        local formationPosNum = stream:ReadByte()
        -- print("formationPosNum ==>", formationPosNum)
        for i=1, formationPosNum do
            local pid = stream:ReadWord()
            -- print("formationPosNum pid ==>", pid)
            if pid > 0 then
                local petData = LRoleDataMgr.Pet:GetPetById(pid)
                if petData then
                    petData.fightPos = i
                end
            end
 
        end

        --dump(LRoleDataMgr.Pet.ShowPosList, "DealMsgFormation ====>")
        Utils:SendMsg(LUIFormationEvent.updateZhengRongUI)

    elseif op == 2 then
        --[[
        学习阵法或阵法升级
        ]]
        local fid = stream:ReadWord()
        local success = stream:ReadByte()
        if success == 0 then
            local msg = stream:ReadString()
            if string.len(msg) > 0 then
                LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
                this:SendMsg(LGameMsg.m_scrollTipsMsg)
            end
            return
        end
        local flv = stream:ReadByte()
        local fdata = LRoleDataMgr.myFormation
        fdata:AddFormation(fid, flv)
        LGameMsg.m_netDealMsg:Change(LUIFormationEvent.ZhenfaChanged, fid)
        this:SendMsg(LGameMsg.m_netDealMsg)
        --[[
        LUIFormationEvent = 
        {
            GotList = MsgIdAdd(),
            ZhenfaChanged = MsgIdAdd(),--阵法信息改变，升级或学习
            UseZhenfaChanged = MsgIdAdd(),--切换使用阵法
            PetFight = MsgIdAdd(),--宠物出站
            ChangePos = MsgIdAdd(),--更换出站位置
        }
        ]]

    elseif op == 3 then
        --[[
        切换阵法
        ]]
        local fdata = LRoleDataMgr.myFormation
        fdata.useId = stream:ReadWord()
        local success = stream:ReadByte()
        if success == 0 then
            local msg = stream:ReadString()
            if string.len(msg) > 0 then
                LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
                this:SendMsg(LGameMsg.m_scrollTipsMsg)
            end
            return
        end
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIFormationEvent.UseZhenfaChanged)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
    elseif op == 4 then
        --[[
        宠物上下阵
        ]]
        local pid = stream:ReadWord()
        local curPos = LRoleDataMgr.Pet:GetPetPos(pid)

        local fightPos = stream:ReadByte()
        local success = stream:ReadByte()
        -- print("fightPos  1111111111111111111 =====>", fightPos, success)
        if success > 0 then
        else
            local msg = stream:ReadString()
            if string.len(msg) > 0 then
                LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, msg)
                this:SendMsg(LGameMsg.m_scrollTipsMsg)
            end
        end

    elseif op == 5 then
        --[[
        更换出阵位置
        ]]
        local pos1 = stream:ReadByte()
        local pos2 = stream:ReadByte()
        local success = stream:ReadByte()
        -- print("WanFaEntranceUI 1111111111 ===>", pos1, pos2, success)
        if success == 0 then
            local msg = stream:ReadString()
            if string.len(msg) > 0 then
                LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
                this:SendMsg(LGameMsg.m_scrollTipsMsg)
            end
            return
        end

        local petData1 = LRoleDataMgr.Pet:GetPetByFightPosFormation(pos1)

        local petData2 = LRoleDataMgr.Pet:GetPetByFightPosFormation(pos2)
        if petData2 ~= nil then
            -- print("petData2 name ==>", petData2.name)
            petData2.fightPos = pos1
        end
        if petData1 ~= nil then
            -- print("petData1 name ==>", petData1.name)
            petData1.fightPos = pos2
        end

        LGameMsg.m_netDealMsg:Change(LUIFormationEvent.ChangePos, {pos1,pos2})
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 11 then
        --[[
        组队切换阵法
        ]]
         local teamData = LRoleDataMgr.MyHeroInfo.m_pTeam
        teamData.m_zhenfaId = stream:ReadWord()
        local success = stream:ReadByte()
        if success == 0 then
            local msg = stream:ReadString()
            if string.len(msg) > 0 then
                LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
                this:SendMsg(LGameMsg.m_scrollTipsMsg)
            end
            return
        end
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIFormationEvent.UseTeamZhenfaChanged)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
    elseif op == 12 then
        --[[
        组队宠物上下阵
        ]]
        local pid = stream:ReadWord()
        local petData = LRoleDataMgr.Pet:GetPetById(pid)
        if petData == nil then
            return
        end
        local state = stream:ReadByte()
        local success = stream:ReadByte()
        
        if success == 0 then
            local msg = stream:ReadString()
            if string.len(msg) > 0 then
                LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
                this:SendMsg(LGameMsg.m_scrollTipsMsg)
            end
        else

        end
    end
    LRedDotCheckMgr:ZhenRongCheck()
end

function LuaNetRecvdMsg.DealMsgPetUpdate(stream)
    
    local op = stream:ReadByte()
    if op == 1 then
        --[[
        增加宠物
        ]]
        local pid = stream:ReadWord()
        local Data = LRoleDataMgr.Pet:GetPetById(pid)
        if Data == nil then
            Data = LPetData:New(pid)
            table.insert(LRoleDataMgr.Pet.petlist,Data)
        end
        LuaNetRecvdMsg.ReadPetInfo(Data,stream)
        
        LRoleDataMgr.Pet:SortPetList()
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIPetEvent.GetPet)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
    elseif op == 2 then
        --[[
        更新宠物
        ]]
        print("更新宠物 ==============================>1111111111111111111111")
        local pid = stream:ReadWord()
        local Data = LRoleDataMgr.Pet:GetPetById(pid)
        if Data == nil then
            return
        end
        local oldLv = Data.level
        local oldPower = Data.zhandouli

        local oldStar = Data.star
        
        local oldBreakLevel = Data.breakLevel
        LuaNetRecvdMsg.ReadPetInfo(Data,stream)
        -- print("Data.breakLevel ==>", Data.breakLevel, oldBreakLevel)
        if Data.breakLevel ~= 0 and oldBreakLevel~= Data.breakLevel then
            Utils:PlayKPEffect(AppDef.SysBGM.Pet_Breach)--神将突破音效

            Utils:InitUI("KaPaiPet.HeroBreakSuccUI", AppDef.UIType.PopWindow, pid)
        end
        
        local newLv = Data.level
        if oldLv ~= newLv then
            local msgValue = {}
            msgValue.pid = pid
            msgValue.lv = newLv
            LGameMsg.m_netDealMsg:Change(LUIPetEvent.ChangePetLv, msgValue)
            this:SendMsg(LGameMsg.m_netDealMsg)
            if LRoleDataMgr.isInBattle then
                LRoleDataMgr.tmpPetUpInfo = LRoleDataMgr.tmpPetUpInfo or {}
                LRoleDataMgr.tmpPetUpInfo[pid] = true
            end
            Utils:PlayKPEffect(AppDef.SysBGM.Upgrade)--神将升级音效
        end

        local newPower = Data.zhandouli
        if oldPower ~= newPower then
            local msgValue = {}
            msgValue.pid = pid
            msgValue.power = newPower
            Utils:SendMsg(LUIPetEvent.ChangePetPower, msgValue, true)
        end

        if oldStar ~= Data.star then
            --[[
            升星有变化
            ]]
            local changeData = {}
            table.insert(changeData,pid)
            if oldStar ~= Data.star then
                table.insert(changeData,true)
            else
                table.insert(changeData,false)
            end

            if oldbreakLevel ~= Data.breakLevel then
                table.insert(changeData,true)
            else
                table.insert(changeData,false)
            end
            LGameMsg.m_netDealMsg:Change(LUIPetEvent.ChangePetStar, changeData)
            this:SendMsg(LGameMsg.m_netDealMsg)

            --音效
            LGameMsg.m_audioMsg:Change(LAudioEvent.PlayEffect, AppDef.SysBGM.Pet_Star)
            this:SendMsg(LGameMsg.m_audioMsg)

            --print("oldStar ================ 11111111111111111111111111>", oldStar, Data.star)
            if oldStar ~= Data.star then

                Utils:InitUI("KaPaiPet.PetStarUpSucUI", AppDef.UIType.PopWindow, pid)

				LGameMsg.m_baseMsgWithOne:Change(LUIPetEvent.UpdatePetData, Data)
				LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)

                LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIPetEvent.PetStarAdd)
                this:SendMsg(LGameMsg.m_netDealBaseMsg)
            end
        end

        LGameMsg.m_netDealMsg:Change(LUIPetEvent.PetDataChanged, pid)
        this:SendMsg(LGameMsg.m_netDealMsg)

    elseif op == 0 then
        --删除
        local pid = stream:ReadWord()
        if pid <= 0 then return end
        LRoleDataMgr.Pet:DelPetById(pid)
    end
end

function LuaNetRecvdMsg.DealMsgPetInfo(stream)
    local op = stream:ReadByte()
    print("DealMsgPetInfo op=", op)
    if op == 1 then
        --[[
        神将列表
        ]]
        LRoleDataMgr.Pet.followPetId = stream:ReadWord()

        local petlist = LRoleDataMgr.Pet:GetPetListAndReset()
        local num = stream:ReadByte()
        print("LuaNetRecvdMsg.DealMsgPetInfo ==>", num)
        local power = 0
        for i = 1, num do
            local pid = stream:ReadWord()
            local Data = LPetData:New(pid)
            LuaNetRecvdMsg.ReadPetInfo(Data,stream)

            table.insert(petlist, Data)
            if power < Data.zhandouli then
                power = Data.zhandouli
                LRoleDataMgr.Pet.bestPet = Data
            end
        end

        LRoleDataMgr.Pet:SortPetList()

        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIPetEvent.GotPetList)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)

        local petData = LRoleDataMgr.Pet:GetPetById(LRoleDataMgr.Pet.followPetId)
        if petData ~= nil then
            LRoleDataMgr.MyHeroInfo:SendHeroFollowPetChangedMsg(petData.baseData.pic, petData.name, petData.baseData.quality)
        end

    elseif op == 2 then
        --[[
        神将改名
        ]]
        local petId = stream:ReadWord()
        local petData = LRoleDataMgr.Pet:GetPetById(petId)
        if petData == nil then
            return
        end
        local success = stream:ReadByte()
        if success == 0 then
            local msg = stream:ReadString()
            if string.len(msg) > 0 then
                LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
                this:SendMsg(LGameMsg.m_scrollTipsMsg)
            end
            return
        end
        petData.name = stream:ReadString()
        LGameMsg.m_netDealMsg:Change(LUIPetEvent.ChangePetName, petId)
        this:SendMsg(LGameMsg.m_netDealMsg)

    elseif op == 3 then
        --升级
        local petId = stream:ReadWord()
        --print("DealMsgPetInfo petId 1111 ==>", petId)
        local petData = LRoleDataMgr.Pet:GetPetById(petId)
        if petData == nil then
            return
        end
        local success = stream:ReadByte()
        if success == 0 then
            local msg = stream:ReadString()
            if string.len(msg) > 0 then
                LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
                this:SendMsg(LGameMsg.m_scrollTipsMsg)
            end
        end
    elseif op == 4 then
        --一键升级
        -- local useItem = stream:ReadByte()
        -- local costItem = {}
        -- for i=1, useItem do
        --     local itemData = {}
        --     itemData.itemId = stream:ReadWord()
        --     itemData.itemNum = stream:ReadWord()
        --     table.insert(costItem, itemData)
        -- end

        local errorCode = stream:ReadByte()
        --print("errorCode ===>", errorCode)
        if errorCode > 0 then
            local petId = stream:ReadWord()
            --print("DealMsgPetInfo petId ==", petId)
        else
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
        end
    elseif op == 5 then
        local petId = stream:ReadWord()
        local success = stream:ReadByte()
        if success == 1 then

        else
            Utils:ShowScrollTips(stream:ReadString())
        end
    elseif op == 6 then
        --神将修炼
        local petId = stream:ReadWord()
        local xlNum = stream:ReadWord()
        local errCode = stream:ReadByte()
        print("the petXiulian data ======================>", petId, xlNum, errCode)
        if errCode > 0 then
            local xlInfo = {}
            local num = stream:ReadByte()
            print("the petXiulian data ===== num", num)
            for i=1, num do
                local aType = stream:ReadByte()
                local cnt = stream:ReadWord()
                print("xulian ===>", aType, cnt)
                xlInfo[aType] = cnt
            end
            dump(xlInfo, "the petXiulian data ========== 11111111111111 >")
            Utils:SendMsg(LUIPetEvent.PetXLSuc, xlInfo)
        else
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
        end 
    elseif op == 7 then
        --[[
        宠物升星
        ]]
        local petId = stream:ReadWord()
        local petData = LRoleDataMgr.Pet:GetPetById(petId)
        if petData == nil then
            return
        end
        local success = stream:ReadByte()
        --print("success =================", success, petId)
        if success > 0 then

        else
            local msg = stream:ReadString()
            if #msg > 0 then
                LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
                this:SendMsg(LGameMsg.m_scrollTipsMsg)
            end
        end
    elseif op == 8 then
        --神将重生查询
		local petid = stream:ReadUInt()
		local status = stream:ReadByte()
		local num = stream:ReadByte()
		local fanhuanlist = {}
		--print("===========numnum============",num)
		for i = 1, num do
			local data = {}
			table.insert(data, stream:ReadWord())
			table.insert(data, stream:ReadUInt())
			table.insert(data, stream:ReadUInt())
			table.insert(fanhuanlist, data)
		end
		----dump(fanhuanlist, "=====================神将重生======================>")
		LGameMsg.m_netDealMsg:Change(LHuiShouEvent.ShengJiangChaXun, fanhuanlist)
		this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 9 then
        --神将重生请求
		Utils:ShowScrollTips(GUITips.UI_HuiShou_ChongSheng_Success)
		LGameMsg.m_netDealMsg:Change(LHuiShouEvent.ShengJiangChongSheng)
		this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 10 then
        --[[
        宠物遗忘技能
        ]]
        local petId = stream:ReadWord()
        local petData = LRoleDataMgr.Pet:GetPetById(petId)
        if petData == nil then
            return
        end
        local skPos = stream:ReadByte()
        local success = stream:ReadByte()
        if success == 0 then
            local msg = stream:ReadString()
            if string.len(msg) > 0 then
                LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
                this:SendMsg(LGameMsg.m_scrollTipsMsg)
            end
        end
    elseif op == 11 then
        --神将碎片招募
        local petId = stream:ReadUShort()
        local succ = stream:ReadByte()
        --print("petId ==", petId, succ)
        if succ == 0 then
            local msg = stream:ReadString()
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
            this:SendMsg(LGameMsg.m_scrollTipsMsg)
        else
            LGameMsg.m_netDealMsg:Change(LUIPetEvent.ComposionPet, petId)
            this:SendMsg(LGameMsg.m_netDealMsg)          
        end
    elseif op == 12 then
        --神将激活
        -- LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIPetEvent.ResolveSucess)
        -- this:SendMsg(LGameMsg.m_netDealBaseMsg) 
        local petId = stream:ReadWord()
        local errCode = stream:ReadByte()
        if errCode > 0 then
            local curXLLv = stream:ReadByte()
            local xlData = {}
            xlData.xlInfo = {0, 0, 0, 0}
            local num = stream:ReadByte()
            print("the petXiulian data ===== num", num)
            -- for i=1, num do
            --     local aType = stream:ReadByte()
            --     local cnt = stream:ReadWord()
            --     print("xulian ===>", aType, cnt)
            --     xlData.xlInfo[aType] = cnt
            -- end
            xlData.curXLLv = curXLLv
            -- dump(xlData, "PetXuLianSucMainUI  ======================= 222222222222>")
            Utils:SendMsg(LUIPetEvent.PetJiHuoSuc, xlData)
        else
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
        end
    end
    --检测神将小红点    
    LRedDotCheckMgr:ZhenRongCheck()
    --神将背包
    LRedDotCheckMgr:PetBagRedCheck()
end

--神将装备出来
function LuaNetRecvdMsg.DealMsgPetEquip(stream)
    local op = stream:ReadByte()
    -- print("DealMsgPetEquip ====>",op)
    if op == 1 then
        --装备背包数据
        local enum = stream:ReadWord() --总数量
        if enum == 0 then 
            LRoleDataMgr.Pet.equipList = {}
            LRoleDataMgr.Pet.equipList.m_maxGridNum = AppDef.Pet.MaxSuitEquipBagNum
            LRoleDataMgr.Pet.equipList.m_curGridNum = enum
            LRoleDataMgr.Pet.equipList.m_formationEquips = {}
            LRoleDataMgr.Pet.equipList.m_petEquips = {}
            
            LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIPetEvent.GotPetEquip)
            this:SendMsg(LGameMsg.m_netDealBaseMsg)
            return 
        end
        local maxCnt = stream:ReadByte()--总返回消息条数
        local curCnt = stream:ReadByte()--当前消息条数（0开始）
        local curNum = stream:ReadByte()--当前消息装备数量
        if curCnt == 0 then 
            LRoleDataMgr.Pet.equipList = {}
            LRoleDataMgr.Pet.equipList.m_maxGridNum = AppDef.Pet.MaxSuitEquipBagNum
            LRoleDataMgr.Pet.equipList.m_curGridNum = enum
            LRoleDataMgr.Pet.equipList.m_formationEquips = {}
            LRoleDataMgr.Pet.equipList.m_petEquips = {}
        end
        --宠物装备
        for i = 1, curNum do
            local value = LPetEquipInfo:New()
            this.ReadPetEquipData(value, stream)
           ------dump(value,"LuaNetRecvdMsg.DealMsgPetEquip getdata ==>")
            if value.m_uid > 0 and value.m_id > 0 then 
                LRoleDataMgr.Pet.equipList.m_petEquips[value.m_uid] = value
                if value.m_fpos > 0 then
                    if LRoleDataMgr.Pet.equipList.m_formationEquips[value.m_fpos] ~= nil then
                        LRoleDataMgr.Pet.equipList.m_formationEquips[value.m_fpos][value.m_wpos] = value.m_uid
                    else
                        local tbl = {}
                        tbl[value.m_wpos] = value.m_uid
                        LRoleDataMgr.Pet.equipList.m_formationEquips[value.m_fpos] = tbl
                    end
                end
            end
        end
        if maxCnt -1  == curCnt then
            ------dump(LRoleDataMgr.Pet.equipList.m_petEquips,"LuaNetRecvdMsg.DealMsgPetEquip op ==1")
            LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIPetEvent.GotPetEquip)
            this:SendMsg(LGameMsg.m_netDealBaseMsg)
        end     
    elseif op == 2 or op == 3 then
        --穿\脱
        local fpos = stream:ReadByte()
        local uid = stream:ReadUInt()
        local suc = stream:ReadByte()
        if suc == 0 then
            local msg = stream:ReadString()
            if #msg > 0 then
                Utils:ShowScrollTips(msg)
            end
            return
        end
        ----print("petequip",op,uid,fpos)
        local info = LRoleDataMgr.Pet.equipList.m_petEquips[uid] 
        Utils:PlayKPEffect(AppDef.SysBGM.Equip_Wear)
        if info == nil then
            return 
        end
        if op == 2 then
            if LRoleDataMgr.Pet.equipList.m_formationEquips[fpos] == nil then
                LRoleDataMgr.Pet.equipList.m_formationEquips[fpos] = {}
            end
            local otherUid = LRoleDataMgr.Pet.equipList.m_formationEquips[fpos][info.m_wpos]
            local otherInfo = nil
            if otherUid ~= nil and otherUid > 0 then
                otherInfo = LRoleDataMgr.Pet.equipList.m_petEquips[otherUid] 
            end
            if info.m_fpos > 0 then--装备已经被穿戴
                LRoleDataMgr.Pet.equipList.m_formationEquips[info.m_fpos][info.m_wpos] = otherUid
                if otherInfo ~= nil then
                    otherInfo.m_fpos = info.m_fpos
                end
            else
                if otherInfo ~= nil then
                    otherInfo.m_fpos = 0
                end
            end
            Utils:PlayKPEffect(AppDef.SysBGM.Equip_Wear)
            LRoleDataMgr.Pet.equipList.m_formationEquips[fpos][info.m_wpos] = uid
            info.m_fpos = fpos
        else
            if LRoleDataMgr.Pet.equipList.m_formationEquips[fpos] ~= nil then
                LRoleDataMgr.Pet.equipList.m_formationEquips[fpos][info.m_wpos] = nil
            end
            info.m_fpos = 0
        end

        LGameMsg.m_netDealMsg:Change(LUIPetEvent.PetEquipWear,{fpos,info.m_wpos})
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 4 then
        --强化
        local qhData = {}
        qhData.uid = stream:ReadUInt()
        qhData.type = stream:ReadByte()
        local suc = stream:ReadByte()
        if suc == 0 then
            local msg = stream:ReadString()
            if #msg > 0 then
				--print(msg)
                Utils:ShowScrollTips(msg)
            end
            return
        end
        qhData.atype = 1
        qhData.crit = stream:ReadByte()
        qhData.addlevel = stream:ReadUShort()
        LGameMsg.m_netDealMsg:Change(LUIRoleEquipChangeEvent.EquipeShuaXin,qhData)
        this:SendMsg(LGameMsg.m_netDealMsg)
		Utils:ShowScrollTips(GUITips.UI_Equip_QiangHua_Success_tips)
        local info = LRoleDataMgr.Pet.equipList.m_petEquips[qhData.uid]
		LGameMsg.m_netDealMsg:Change(LUIPetEvent.PetEquipWear,{info.m_fpos})
        this:SendMsg(LGameMsg.m_netDealMsg)
		local ecfg = JsonConfig.m_equipConfig.getDefByID(info.m_id)
		local curLevel = info.cultivateLevel[1] or 0
   
        Utils:PlayKPEffect(AppDef.SysBGM.Equip_Enhanced) --装备强化音效
		--Utils:ShowScrollTips(string.format(GUITips.UI_Equip_QiangHua_Level_tips,curLevel))
		--属性增加提示
		for i=1, #ecfg.atrr_qianghua do
			local qattr = ecfg.atrr_qianghua[i]
			Utils:ShowScrollTips(string.format(GUITips.UI_Equip_Attr_Tips, Utils:getAttrName(qattr[1]), qattr[2] * qhData.addlevel))
		end
	elseif op == 12 then
		local fpos = stream:ReadByte()
		local suc = stream:ReadByte()
        if suc == 0 then
            local msg = stream:ReadString()
            if #msg > 0 then
                Utils:ShowScrollTips(msg)
            end
            return
        end
		local num = stream:ReadByte()
		local qhData = {}
		for i = 1,num do
			local data = {}
			data.pos = stream:ReadByte()
			data.uid = stream:ReadUInt()
			data.addlevel = stream:ReadByte()
			if data.uid ~= 0 or data.addlevel > 0 then
				table.insert(qhData, data)
			end
		end
		
		LGameMsg.m_netDealMsg:Change(LUIRoleEquipChangeEvent.EquipeShuaXin,qhData)
        this:SendMsg(LGameMsg.m_netDealMsg)
		LGameMsg.m_netDealMsg:Change(LUIPetEvent.PetEquipWear,{fpos})
        this:SendMsg(LGameMsg.m_netDealMsg)
		--Utils:ShowScrollTips(GUITips.UI_Equip_QiangHua_Success_tips)
		----dump(qhData, "================yijianqianghua================>")
		local msgdatas = {}
		for i = 1,#qhData do
			local info = LRoleDataMgr.Pet.equipList.m_petEquips[qhData[i].uid]
			local ecfg = JsonConfig.m_equipConfig.getDefByID(info.m_id)
			for j=1, #ecfg.atrr_qianghua do
				local qattr = ecfg.atrr_qianghua[j]
				if msgdatas[qattr[1]] == nil then
					msgdatas[qattr[1]] = qattr[2] * qhData[i].addlevel
				else
					msgdatas[qattr[1]] = msgdatas[qattr[1]] + qattr[2] * qhData[i].addlevel
				end
			end
			--local curLevel = info.cultivateLevel[1] or 0
			--Utils:ShowScrollTips(string.format(info.m_name..GUITips.UI_Equip_QiangHua_Level_tips,curLevel))
		end
         Utils:PlayKPEffect(AppDef.SysBGM.Equip_Enhanced) --装备强化音效
		--属性增加提示
		for k,v in pairs(msgdatas) do
			local msg = Utils:getAttrName(k).."+"..tostring(v)
			if v > 0 then
				Utils:ShowScrollTips(string.format(GUITips.UI_Equip_Attr_Tips, Utils:getAttrName(k), v))
			end
		end

    elseif op == 6 then
        local value = LPetEquipInfo:New()
        this.ReadPetEquipData(value, stream)
        ------dump(value,"LuaNetRecvdMsg.DealMsgPetEquip AddEquip")
        -- local sign = LPetDataMgr:GetPetEquipOffSign(value.m_uid)
        -- if sign == 1 then
        --     LPetDataMgr:SetPetEquipOffSign(value.m_uid,0)
        -- else
   --          LPetDataMgr:SavePetEquipRedDot(value.m_suitType,value.m_uid)
			-- LPetDataMgr:SavePetEquipRedDotById(value.m_uid)
   --          LGameMsg.m_netDealMsg:Change(LUIPetEvent.PetEquipAdd,0)
   --          this:SendMsg(LGameMsg.m_netDealMsg)
   --      end
        --装备添加
        if LRoleDataMgr.Pet.equipList == nil or LRoleDataMgr.Pet.equipList.m_petEquips == nil or  LRoleDataMgr.Pet.equipList.m_maxGridNum == 0 then
            return
        end     
        if value.m_uid < 1 or value.m_id < 1 then return end
        local previous = LRoleDataMgr.Pet.equipList.m_petEquips[value.m_uid]
        value.affixSeed = previous.affixSeed
        value.specialAffixId = previous.specialAffixId
        value.specialAffixTier = previous.specialAffixTier
        value.affixLockMask = previous.affixLockMask
        value.specialAffixKey = previous.specialAffixKey
        value.specialAffixName = previous.specialAffixName
        value.specialAffixDesc = previous.specialAffixDesc
        value.specialAffixValue1 = previous.specialAffixValue1
        value.specialAffixValue2 = previous.specialAffixValue2
        LRoleDataMgr.Pet.equipList.m_petEquips[value.m_uid] = value
        LRoleDataMgr.Pet.equipList.m_curGridNum = LRoleDataMgr.Pet.equipList.m_curGridNum+1
        LGameMsg.m_baseMsgTwo:Change(LUIPetEvent.PetBagEquipChanged,1,value)
        this:SendMsg(LGameMsg.m_baseMsgTwo)
        ------dump(LRoleDataMgr.Pet.equipList.m_petEquips,"LuaNetRecvdMsg.DealMsgPetEquip op ==6")
    elseif op == 7 then
        --装备删除
        local uid = stream:ReadUInt() or 0
		--print("----------------delete equip-----------------"..uid)
        if uid < 1 or LRoleDataMgr.Pet.equipList == nil or LRoleDataMgr.Pet.equipList.m_petEquips == nil then
            return
        end
        local value = LRoleDataMgr.Pet.equipList.m_petEquips[uid]
        if value == nil then return end
        local msgData = {}
        msgData.uid = uid
        msgData.suitId = value.m_suitType
        msgData.pos = value.m_wpos        
        
        value:Delete()
        LRoleDataMgr.Pet.equipList.m_petEquips[uid] = nil
        LRoleDataMgr.Pet.equipList.m_curGridNum = LRoleDataMgr.Pet.equipList.m_curGridNum-1
        
        LGameMsg.m_baseMsgTwo:Change(LUIPetEvent.PetBagEquipChanged,2,msgData)
        this:SendMsg(LGameMsg.m_baseMsgTwo)
	elseif op == 9 then
		local petId = stream:ReadWord()
		local id = stream:ReadUInt()
		local suc = stream:ReadByte()
		local msg = stream:ReadString()
		if #msg > 0 then
            Utils:ShowScrollTips(msg)
        end
		if petId > 0 then
			local equipValue = {}
			this.ReadPetEquipData(equipValue, stream)
			LRoleDataMgr:UpdatePetEquip(petId, equipValue)
		else
			local uid = id
			----print("=================="..uid)
			this.ReadPetEquipData(LRoleDataMgr.Pet.equipList.m_petEquips[uid], stream)
			LGameMsg.m_baseMsgTwo:Change(LUIPetEvent.PetBagEquipChanged,10,LRoleDataMgr.Pet.equipList.m_petEquips[uid])
			this:SendMsg(LGameMsg.m_baseMsgTwo)
		end
	elseif op == 10 then
		local petId = stream:ReadWord()
		local id = stream:ReadUInt()
		local suc = stream:ReadByte()
		local msg = stream:ReadString()
		if #msg > 0 then
            Utils:ShowScrollTips(msg)
        end
		if petId > 0 then
			local equipValue = {}
			this.ReadPetEquipData(equipValue, stream)
			LRoleDataMgr:UpdatePetEquip(petId, equipValue)
		else
			local uid = id
			----print("+++++++++++++++++"..uid)
			this.ReadPetEquipData(LRoleDataMgr.Pet.equipList.m_petEquips[uid], stream)
			LGameMsg.m_baseMsgTwo:Change(LUIPetEvent.PetBagEquipChanged,10,LRoleDataMgr.Pet.equipList.m_petEquips[uid])
			this:SendMsg(LGameMsg.m_baseMsgTwo)
		end
	elseif op == 11 then
        local id = stream:ReadWord()
        local suc = stream:ReadByte()
        if suc == 0 then
            local msg = stream:ReadString()
            if #msg > 0 then
                Utils:ShowScrollTips(msg)
            end
        end
        ----print("hecheng suc",suc)
    elseif op == 13 then
        local qhData = {}
        qhData.uid = stream:ReadUInt()
        local suc = stream:ReadByte()
        if suc == 0 then
            local msg = stream:ReadString()
            if #msg > 0 then
                Utils:ShowScrollTips(msg)
            end
            return
        end
        qhData.atype = 2
        qhData.addlevel = stream:ReadUShort()
        LGameMsg.m_netDealMsg:Change(LUIRoleEquipChangeEvent.EquipeShuaXin,qhData)
        this:SendMsg(LGameMsg.m_netDealMsg)
		local info = LRoleDataMgr.Pet.equipList.m_petEquips[qhData.uid]
		LGameMsg.m_netDealMsg:Change(LUIPetEvent.PetEquipWear,{info.m_fpos})
        this:SendMsg(LGameMsg.m_netDealMsg)
		local ecfg = JsonConfig.m_equipConfig.getDefByID(info.m_id)
		Utils:ShowScrollTips(GUITips.UI_Equip_JingLian_Success_tips)
		local curLevel = info.cultivateLevel[2] or 0
		Utils:ShowScrollTips(string.format(GUITips.UI_Equip_JingLian_Level_tips,curLevel))
		--属性增加提示
		for i=1, #ecfg.attr_jinglian do
			local qattr = ecfg.attr_jinglian[i]
			Utils:ShowScrollTips(string.format(GUITips.UI_Equip_Attr_Tips, Utils:getAttrName(qattr[1]), qattr[2] * qhData.addlevel))
		end
         Utils:PlayKPEffect(AppDef.SysBGM.Equip_Refine) --装备精炼音效
    elseif op == 14 then
        local qhData = {}
        qhData.uid = stream:ReadUInt()
        stream:ReadUShort()
        local suc = stream:ReadByte()
        if suc == 0 then
            local msg = stream:ReadString()
            if #msg > 0 then
                Utils:ShowScrollTips(msg)
            end
            return
        end
        qhData.atype = 3
        qhData.addlevel = 1
        LGameMsg.m_netDealMsg:Change(LUIRoleEquipChangeEvent.EquipeShuaXin,qhData)
        this:SendMsg(LGameMsg.m_netDealMsg)
		local info = LRoleDataMgr.Pet.equipList.m_petEquips[qhData.uid]
		LGameMsg.m_netDealMsg:Change(LUIPetEvent.PetEquipWear,{info.m_fpos})
        this:SendMsg(LGameMsg.m_netDealMsg)
		Utils:ShowScrollTips(GUITips.UI_Equip_JueXing_Success_tips)
		local ecfg = JsonConfig.m_equipConfig.getDefByID(info.m_id)
		local curLevel = info.cultivateLevel[3] or 0
		local cfg = JsonConfig.m_equipJueXing.getDefByID(curLevel)
		Utils:ShowScrollTips(string.format(GUITips.UI_Equip_JueXing_Level_tips,cfg.name))
        Utils:PlayKPEffect(AppDef.SysBGM.Equip_Awaken) --装备觉醒音效
		--属性增加提示
		for i=1, #ecfg.attr_juexing do
			local qattr = ecfg.attr_juexing[i]
			Utils:ShowScrollTips(string.format(GUITips.UI_Equip_Attr_Tips, Utils:getAttrName(qattr[1]), qattr[2] * qhData.addlevel))
		end
    elseif op == 15 then
        local qhData = {}
        qhData.uid = stream:ReadUInt()
        stream:ReadUShort()
        local suc = stream:ReadByte()
        if suc == 0 then
            local msg = stream:ReadString()
            if #msg > 0 then
                Utils:ShowScrollTips(msg)
            end
            return
        end
        qhData.atype = 4
        qhData.addlevel = 1
        LGameMsg.m_netDealMsg:Change(LUIRoleEquipChangeEvent.EquipeShuaXin,qhData)
        this:SendMsg(LGameMsg.m_netDealMsg)
		local info = LRoleDataMgr.Pet.equipList.m_petEquips[qhData.uid]
		LGameMsg.m_netDealMsg:Change(LUIPetEvent.PetEquipWear,{info.m_fpos})
        this:SendMsg(LGameMsg.m_netDealMsg)
		local ecfg = JsonConfig.m_equipConfig.getDefByID(info.m_id)
		Utils:ShowScrollTips(GUITips.UI_Equip_ShenZhu_Success_tips)
		local curLevel = info.cultivateLevel[4] or 0
		local cfg = JsonConfig.m_equipShenZhu.getDefByID(curLevel)
		Utils:ShowScrollTips(string.format(GUITips.UI_Equip_ShenZhu_Level_tips,cfg.name))
        Utils:PlayKPEffect(AppDef.SysBGM.Equip_ShenZhu) --装备神铸音效
		--属性增加提示
		for i=1, #ecfg.attr_shenzhu do
			local qattr = ecfg.attr_shenzhu[i]
			Utils:ShowScrollTips(string.format(GUITips.UI_Equip_Attr_Tips, Utils:getAttrName(qattr[1]), qattr[2] * qhData.addlevel))
		end
    elseif op == 16 then
        local value = LPetEquipInfo:New()
        this.ReadPetEquipData(value, stream)
        ------dump(value,"LuaNetRecvdMsg.DealMsgPetEquip UpdateEquip")
        if LRoleDataMgr.Pet.equipList == nil or LRoleDataMgr.Pet.equipList.m_petEquips == nil or  LRoleDataMgr.Pet.equipList.m_maxGridNum == 0 then
            return
        end  
        if LRoleDataMgr.Pet.equipList.m_petEquips[value.m_uid] == nil then
            return
        end
        LRoleDataMgr.Pet.equipList.m_petEquips[value.m_uid] = value
        ------dump(LRoleDataMgr.Pet.equipList.m_petEquips,"LuaNetRecvdMsg.DealMsgPetEquip op ==16")
        LGameMsg.m_baseMsgTwo:Change(LUIPetEvent.PetBagEquipChanged,10,value)
        this:SendMsg(LGameMsg.m_baseMsgTwo)
    elseif op == 17 then
        --法宝背包数据
        local enum = stream:ReadWord() --总数量
        
        print("this is a msg ==>", LUIFaBaoEvent.GotPetFaBao, enum)
        
        if enum == 0 then 
            LRoleDataMgr.Pet.faBaoList = {}
            LRoleDataMgr.Pet.faBaoList.m_maxGridNum = AppDef.Pet.MaxFaBaoBagNum
            LRoleDataMgr.Pet.faBaoList.m_curGridNum = enum
            LRoleDataMgr.Pet.faBaoList.m_petFaBaos = {}
            LRoleDataMgr.Pet.faBaoList.m_formationFaBaos = {}
            --GotPetEquip
            print("LUIFaBaoEvent.GotPetFabao ==>", LUIFaBaoEvent.GotPetFaBao)
            Utils:SendMsg(LUIFaBaoEvent.GotPetFaBao)
            return 
        end
        local maxCnt = stream:ReadByte()--总返回消息条数
        local curCnt = stream:ReadByte()--当前消息条数（0开始）
        local curNum = stream:ReadByte()--当前消息装备数量
        print("this is a fabao test ===>", maxCnt, curCnt, curNum)
        if curCnt == 0 then 
            LRoleDataMgr.Pet.faBaoList = {}
            LRoleDataMgr.Pet.faBaoList.m_maxGridNum = AppDef.Pet.MaxFaBaoBagNum
            LRoleDataMgr.Pet.faBaoList.m_curGridNum = enum
            LRoleDataMgr.Pet.faBaoList.m_petFaBaos = {}
            LRoleDataMgr.Pet.faBaoList.m_formationFaBaos = {}
        end

        --宠物法宝
        for i = 1, curNum do
            local value = LPetFaBaoInfo:New()
            this.ReadPetFaBaoData(value, stream)
            -- ----dump(value, "==================== 111>")
            if value.m_uid > 0 and value.m_id > 0 then

                LRoleDataMgr.Pet.faBaoList.m_petFaBaos[value.m_uid] = value

                value.qhLv = value.cultivateLevel[AppDef.PetFaBaoLevelType.QiangHua] or 0
                value.jlLv = value.cultivateLevel[AppDef.PetFaBaoLevelType.JingLian] or 0

                --记录已经穿戴的法宝
                if value.m_fpos > 0 then
                    if LRoleDataMgr.Pet.faBaoList.m_formationFaBaos[value.m_fpos] ~= nil then
                        LRoleDataMgr.Pet.faBaoList.m_formationFaBaos[value.m_fpos][value.m_wpos] = value.m_uid
                    else
                        local tbl = {}
                        tbl[value.m_wpos] = value.m_uid
                        LRoleDataMgr.Pet.faBaoList.m_formationFaBaos[value.m_fpos] = tbl
                    end
                end

                -- ----dump(LRoleDataMgr.Pet.faBaoList.m_formationFaBaos, "111111111111111111111 ==============>")

            end
        end

        --消息接收完毕
        if maxCnt -1  == curCnt then
            ------dump(LRoleDataMgr.Pet.faBaoList.m_petFaBaos,"LuaNetRecvdMsg.DealMsgPetEquip op ==1")
            -- --print(" LUIPetEvent.GotPetFabao ===>", LUIFaBaoEvent.GotPetFaBao)
            Utils:SendMsg(LUIFaBaoEvent.GotPetFaBao)
        end
		LRedDotCheckMgr:EquipZhenRongRedDotCheck()
		LRedDotCheckMgr:FaBaoBeiBaoRedDotCheck()
	elseif op == 41 or op == 42 then
		-- 服务端权威返回操作结果及完整的新词条记录，客户端不自行随机。
		local success = stream:ReadByte()
		local resultText = stream:ReadString()
		local nextCost = stream:ReadUInt()
		if #resultText > 0 then Utils:ShowScrollTips(resultText) end
		if success == 0 then return end
		local uid = stream:ReadUInt()
		local seed = stream:ReadUInt()
		local affixId = stream:ReadWord()
		local tier = stream:ReadByte()
		local lockMask = stream:ReadByte()
		local key = stream:ReadString()
		local name = stream:ReadString()
		local desc = stream:ReadString()
		local value1 = stream:ReadInt()
		local value2 = stream:ReadInt()
		local info = LRoleDataMgr.Pet.equipList
			and LRoleDataMgr.Pet.equipList.m_petEquips
			and LRoleDataMgr.Pet.equipList.m_petEquips[uid]
		if info ~= nil then
			info.affixSeed = seed
			info.specialAffixId = affixId
			info.specialAffixTier = tier
			info.affixLockMask = lockMask
			info.specialAffixKey = key
			info.specialAffixName = name
			info.specialAffixDesc = desc
			info.specialAffixValue1 = value1
			info.specialAffixValue2 = value2
			info.specialAffixNextCost = nextCost
		end
		LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIPetEvent.GotPetEquip)
		this:SendMsg(LGameMsg.m_netDealBaseMsg)
	elseif op == 40 then
		-- 装备特殊词条使用独立分包，保持旧装备记录协议不变。
		local total = stream:ReadWord()
		if total == 0 then
			return
		end
		local packetCount = stream:ReadByte()
		local packetIndex = stream:ReadByte()
		local itemCount = stream:ReadByte()
		for i = 1, itemCount do
			local uid = stream:ReadUInt()
			local seed = stream:ReadUInt()
			local affixId = stream:ReadWord()
			local tier = stream:ReadByte()
			local lockMask = stream:ReadByte()
			local key = stream:ReadString()
			local name = stream:ReadString()
			local desc = stream:ReadString()
			local value1 = stream:ReadInt()
			local value2 = stream:ReadInt()
			local info = LRoleDataMgr.Pet.equipList
				and LRoleDataMgr.Pet.equipList.m_petEquips
				and LRoleDataMgr.Pet.equipList.m_petEquips[uid]
			if info ~= nil then
				info.affixSeed = seed
				info.specialAffixId = affixId
				info.specialAffixTier = tier
				info.affixLockMask = lockMask
				info.specialAffixKey = key
				info.specialAffixName = name
				info.specialAffixDesc = desc
				info.specialAffixValue1 = value1
				info.specialAffixValue2 = value2
			end
		end
		if packetIndex + 1 == packetCount then
			LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIPetEvent.GotPetEquip)
			this:SendMsg(LGameMsg.m_netDealBaseMsg)
		end
    elseif op == 20 then
        --强化法宝
        local errCode = stream:ReadByte()
        print("pet Qh errCode ==>", errCode)
        if errCode > 0 then
            local data = {}
            data.uid = stream:ReadUInt()
            data.curQhLv = stream:ReadByte()
            data.curQhExp = stream:ReadUInt()
            data.costNum = stream:ReadByte()
            data.costIdList ={}
            for i=1, data.costNum do
                local uid = stream:ReadUInt()
                table.insert(data.costIdList, uid)
                --重置数据
                LRoleDataMgr.Pet.faBaoList.m_petFaBaos[uid] = nil
            end
            ----dump(data, "qh suc ===>")
            Utils:PlayKPEffect(AppDef.SysBGM.PetFaBao_Refine) --法宝强化音效 
            --更新数据
            if LRoleDataMgr.Pet.faBaoList.m_petFaBaos[data.uid] then
                LRoleDataMgr.Pet.faBaoList.m_petFaBaos[data.uid].qhLv = data.curQhLv
                LRoleDataMgr.Pet.faBaoList.m_petFaBaos[data.uid].qHExp = data.curQhExp
            end
            
            Utils:SendMsg(LUIFaBaoEvent.PetQHSuc, data)
        else
            Utils:ShowScrollTips(stream:ReadString())
        end
    elseif op == 21 then
        --精炼法宝
        local data = {}
        data.uid = stream:ReadUInt()
        local toLevelTemp = stream:ReadByte()
        local errCode = stream:ReadByte()
        print("toLevelTemp ==>", toLevelTemp, errCode)
        if errCode > 0 then
            data.toLevel = stream:ReadByte()
            --dump(data, "ShowScrollTips ====================>")

            Utils:PlayKPEffect(AppDef.SysBGM.PetFaBao_Enhanced) --法宝精炼音效 
            Utils:SendMsg(LUIFaBaoEvent.PetJLSuc, data)
        else
            Utils:ShowScrollTips(stream:ReadString())
        end
    elseif op == 22 then
        --更新法宝
        -- --print("ShowScrollTips ==================== 2222222222222222222>")
        local value = LPetFaBaoInfo:New()
        this.ReadPetFaBaoData(value, stream)
        -- ----dump(value, "==================== 111>")
        if value.m_uid > 0 and value.m_id > 0 then

            LRoleDataMgr.Pet.faBaoList.m_petFaBaos[value.m_uid] = value
            value.qhLv = value.cultivateLevel[AppDef.PetFaBaoLevelType.QiangHua] or 0
            value.jlLv = value.cultivateLevel[AppDef.PetFaBaoLevelType.JingLian] or 0

            --记录已经穿戴的法宝
            if value.m_fpos > 0 then
                if LRoleDataMgr.Pet.faBaoList.m_formationFaBaos[value.m_fpos] ~= nil then
                    LRoleDataMgr.Pet.faBaoList.m_formationFaBaos[value.m_fpos][value.m_wpos] = value.m_uid
                else
                    local tbl = {}
                    tbl[value.m_wpos] = value.m_uid
                    LRoleDataMgr.Pet.faBaoList.m_formationFaBaos[value.m_fpos] = tbl
                end
            end
            -- ----dump(LRoleDataMgr.Pet.faBaoList.m_formationFaBaos, "111111111111111111111 ==============>")
        end

        -- ----dump(value, "==================== 111>")
        -- ----dump(LRoleDataMgr.Pet.faBaoList.m_petFaBaos, "add a fabao ======>")
        Utils:SendMsg(LUIFaBaoEvent.UpdateFaBaoSuc, nil)


    elseif op == 23 then
        --删除法宝
        local uid = stream:ReadUInt()
        print("delete fabao ===>", uid)
        LRoleDataMgr.Pet:DelFabaoById(uid)
    elseif op == 18 then
        --穿戴法宝
        local data = {}
        data.m_uid = stream:ReadUInt()
        data.m_fpos = stream:ReadByte()
        data.m_wpos = stream:ReadByte()

        local errcode = stream:ReadByte()
        data.tiHuanUid = stream:ReadUInt()   --被替换的法宝id
        print("errcode ===>", errcode)
        if errcode > 0 then
            ----dump(data, "stream:ReadByte() ==================>>")
            --添加数据
            --重置被替换的数据
            for k,v in pairs(LRoleDataMgr.Pet.faBaoList.m_petFaBaos) do
                if data.tiHuanUid > 0 and v.m_uid == data.tiHuanUid then
                    v.m_fpos = 0
                    v.m_wpos = 0
                    break
                end
            end

            for k,v in pairs(LRoleDataMgr.Pet.faBaoList.m_petFaBaos) do
                if v.m_uid == data.m_uid then
                    v.m_fpos = data.m_fpos
                    v.m_wpos = data.m_wpos
                    break
                end
            end

            if LRoleDataMgr.Pet.faBaoList.m_formationFaBaos[data.m_fpos] ~= nil then
                LRoleDataMgr.Pet.faBaoList.m_formationFaBaos[data.m_fpos][data.m_wpos] = data.m_uid
            else
                local tbl = {}
                tbl[data.m_wpos] = data.m_uid
                LRoleDataMgr.Pet.faBaoList.m_formationFaBaos[data.m_fpos] = tbl
            end
             Utils:PlayKPEffect(AppDef.SysBGM.Equip_Wear)--,--装备穿戴音效

            --显示法宝
            Utils:SendMsg(LUIFaBaoEvent.FaBaoWearSuc, data)

        else
            Utils:ShowScrollTips(stream:ReadString())
        end
        
    elseif op == 19 then
        --脱掉法宝
        local data = {}
        local uid = stream:ReadUInt()
        data.m_uid = uid
        local errcode = stream:ReadByte()
        print("2222222222222 uid ===>", uid, errcode)
        if errcode > 0 then
            --更新数据
            for k,v in pairs(LRoleDataMgr.Pet.faBaoList.m_petFaBaos) do
                if v.m_uid == uid then
                    v.m_fpos = 0
                    v.m_wpos = 0
                    break
                end
            end

            for k,v in pairs(LRoleDataMgr.Pet.faBaoList.m_formationFaBaos) do
                ----dump(v, "===>")
                for i=5, 6 do
                    local wearUid = v[i]
                    if wearUid ~= nil and uid == wearUid then
                        data.m_fpos = k
                        data.m_wpos = i
                        v[i] = 0
                    end
                end
            end
            Utils:PlayKPEffect(AppDef.SysBGM.Equip_Wear)--,--装备穿戴音效

            ----dump(data, "take off =====>")

            Utils:SendMsg(LUIFaBaoEvent.FaBaoTakeOffSuc, data)

        else

            Utils:ShowScrollTips(stream:ReadString())
        end

	elseif op == 24 then
		--更新指定位置指定类型的大师等级
		local pos = stream:ReadByte()
		local type = stream:ReadByte()
		local lv = stream:ReadByte()
		--print("==============更新指定位置指定类型的大师等级 24==================",pos,type,lv)
		local data = LRoleDataMgr.Pet.masterList[pos]
		if data.masterTypeList[type] == nil then
			local dashidata = {}
			dashidata.type = type
			dashidata.lv = lv
			data.masterTypeList[type] = dashidata
		else
			data.masterTypeList[type].lv = lv
		end
		LRoleDataMgr.Pet.masterList[pos] = data
		
		LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Activity.QiangHuaDaShiDaChengUI", AppDef.UIType.ThirdClassLayer, {type = type, level = lv})
		LUIManager:SendMsg(LGameMsg.m_initUIMsg)
	elseif op == 25 then
		--获取指定位置所有类型的大师的等级
		local data = {}
		data.pos = stream:ReadByte()
		local num = stream:ReadByte()
		data.masterTypeList = {}
		for i = 1, num do	
			local dashidata = {}
			dashidata.type = stream:ReadByte()
			dashidata.lv =  stream:ReadByte()	
			data.masterTypeList[dashidata.type] = dashidata
		end
        Utils:PlayKPEffect(AppDef.SysBGM.Equip_Maste)--武器大师音效
		LRoleDataMgr.Pet.masterList[data.pos] = data
	elseif op == 26 or op == 27 then
		--print("==============换装更新装备大师的等级 ==================",op)
		--换装更新装备大师的等级 26:装备 27:法宝
		local data = {}
		data.pos = stream:ReadByte()
		local num = stream:ReadByte()
		data.masterTypeList = {}
		for i = 1, num do	
			local dashidata = {}
			dashidata.type = stream:ReadByte()
			dashidata.lv =  stream:ReadByte()	
			data.masterTypeList[dashidata.type] = dashidata
		end
		LRoleDataMgr.Pet.masterList[data.pos] = data
    elseif op == 28 then--寻宝
        local faBaoId = stream:ReadWord()
        local suiId = stream:ReadWord()
        local suc = stream:ReadByte()
        if suc == 0 then
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
            ----print("op == 28 suc =0",msg)
            return
        end
        local data = LActivityManager:GetXunBaoData()
        data.m_cnt = stream:ReadWord() --剩余次数
        local num = stream:ReadWord() --搜索次数
        data.m_sec = stream:ReadUInt() --增加次数倒计时（秒）
        data.m_records = {}
        for i=1,num do
            local value = {}
            value.idx = i
            value.items = {}
            LuaNetRecvdMsg.ReadRewardData(value.items, stream)
            table.insert(data.m_records,value)
        end
        Utils:SendMsg(LUIXunBaoEvent.UpdateCntUI)
        Utils:SendMsg(LUIXunBaoEvent.ShowResultUI)
        if #data.m_records > 0 then
            Utils:InitUI("WanFa.XunBaoResultUI",AppDef.UIType.SecondClassLayer,{data.m_records,0,faBaoId,suiId})
        end
        --print("op == 28",data.m_cnt,data.m_sec)
    elseif op == 29 then--一键寻宝
        local auto = stream:ReadByte()
        local faBaoId = stream:ReadWord()
        local suc = stream:ReadByte()
        ----print("op == 29 suc =",suc)
        if suc == 0 then
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
            --print("msg",msg)
            return
        end
        local data = LActivityManager:GetXunBaoData()
        
        local num = stream:ReadWord() --搜索次数
        ----print("op == 29 ,num",num)
        data.m_records = {}
        for i=1,num do
            local value = {}
            value.idx = i
            value.items = {}
            LuaNetRecvdMsg.ReadRewardData(value.items, stream)
            table.insert(data.m_records,value)
        end
        data.m_cnt = stream:ReadWord() --剩余次数
        data.m_sec = stream:ReadWord() --增加次数倒计时（秒）
        PetkaPaiManager:setTiLiTimer(nil, data.m_sec)
        local useItemNum = stream:ReadUInt() --使用道具次数
        Utils:SendMsg(LUIXunBaoEvent.UpdateCntUI)
        Utils:SendMsg(LUIXunBaoEvent.ShowResultUI)
        if #data.m_records > 0 then
            Utils:InitUI("WanFa.XunBaoResultUI",AppDef.UIType.SecondClassLayer,{data.m_records,1,faBaoId})
        end
        --print("op == 29",data.m_cnt,data.m_sec)
    elseif op == 30 then --法宝合成
        local faBaoId = stream:ReadWord()
        local suc = stream:ReadByte()
        --print("faBaoId =====>>", faBaoId, suc)
        if suc == 0 then
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
            ----print("op == 30 suc =0",msg)
            return
        end
        Utils:PlayKPEffect(AppDef.SysBGM.PetFaBao_Compose) --法宝法宝合成
        --合成成功提示
        local msg = stream:ReadString()
        Utils:ShowScrollTips(msg)
        --合成成功
        Utils:SendMsg(LUIXunBaoEvent.FaBaoHechengSuc)
    elseif op == 31 then--寻宝次数更新
        local data = LActivityManager:GetXunBaoData()
        data.m_cnt = stream:ReadWord() --剩余次数
        data.m_sec = stream:ReadUInt() --增加次数倒计时（秒）
        --print("op == 31",data.m_cnt,data.m_sec)
        Utils:SendMsg(LUIXunBaoEvent.UpdateCntUI)
	elseif op == 32 or op == 34 then --装备重生
		local type = stream:ReadByte()
		local num = stream:ReadByte()
		local fanhuanlist = {}
		--print("===========numnum============",num)
		for i = 1, num do
			local data = {}
			table.insert(data, stream:ReadWord())
			table.insert(data, stream:ReadUInt())
			table.insert(data, stream:ReadUInt())
			table.insert(fanhuanlist, data)
		end
		--dump(fanhuanlist, "====================装备重生或分解======================>")
		if op == 32 then
			if type == 1 then
				LGameMsg.m_netDealMsg:Change(LHuiShouEvent.ZhuangBeiChaXun, fanhuanlist)
				this:SendMsg(LGameMsg.m_netDealMsg)
			elseif type == 2 then
				LGameMsg.m_netDealMsg:Change(LHuiShouEvent.FenJieZhuangBeiChaXun, fanhuanlist)
				this:SendMsg(LGameMsg.m_netDealMsg)
			end
		elseif op == 34 then
			if type == 1 then
				LGameMsg.m_netDealMsg:Change(LHuiShouEvent.FaBaoChaXun, fanhuanlist)
				this:SendMsg(LGameMsg.m_netDealMsg)
			elseif type == 2 then
				LGameMsg.m_netDealMsg:Change(LHuiShouEvent.FenJieFaBaoChaXun, fanhuanlist)
				this:SendMsg(LGameMsg.m_netDealMsg)
			end
		end
	elseif op == 33 or op == 35 then
		local type = stream:ReadByte()
		if op == 33 then
			if type == 1 then
				Utils:ShowScrollTips(GUITips.UI_HuiShou_ChongSheng_Success)
				LGameMsg.m_netDealMsg:Change(LHuiShouEvent.ZhuangBeiChongSheng)
				this:SendMsg(LGameMsg.m_netDealMsg)
			elseif type == 2 then
				Utils:ShowScrollTips(GUITips.UI_HuiShou_FenJie_Success)
				LGameMsg.m_netDealMsg:Change(LHuiShouEvent.FenJieZhuangBei)
				this:SendMsg(LGameMsg.m_netDealMsg)
			end
		elseif op == 35 then
			if type == 1 then
				Utils:ShowScrollTips(GUITips.UI_HuiShou_ChongSheng_Success)
				LGameMsg.m_netDealMsg:Change(LHuiShouEvent.FaBaoChongSheng)
				this:SendMsg(LGameMsg.m_netDealMsg)
			elseif type == 2 then
				Utils:ShowScrollTips(GUITips.UI_HuiShou_FenJie_Success)
				LGameMsg.m_netDealMsg:Change(LHuiShouEvent.FenJieFaBao)
				this:SendMsg(LGameMsg.m_netDealMsg)
			end
		end
    elseif op == 36 then --法宝一键合成
        local suc = stream:ReadByte()
        if suc == 0 then
            local msg = stream:ReadString()
            if #msg > 0 then
                Utils:ShowScrollTips(msg)
            end
            return
        end
        local value = {}
        this.ReadRewardData(value,stream)
        if #value > 0 then
            Utils:InitUI("Common.SaoDangUI", AppDef.UIType.PopWindow, value)
            LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIXunBaoEvent.FaBaoOneKeyHCSuc)
            this:SendMsg(LGameMsg.m_netDealBaseMsg)
        end
    end
end

function LuaNetRecvdMsg.DealJumpBattle(stream)

    -- LGameMsg.m_netDealMsg:Change(LBattleEvent.RecvJumpBattle, stream)
    -- this:SendMsg(LGameMsg.m_netDealMsg)
    
    local op = stream:ReadByte();
    -- print("DealJumpBattle",op)
    --op=3 跳过战斗
    --op=4 没有结果的战斗
    --op=5 有结果的战斗
    if op == 3 or op == 4 or op == 5 then
        local num = stream:ReadWord();
        -- print("num",num)
        local msgArr = {};
        for i = 1, num do
            local tmpStream = stream:ReadNetMsg();
            -- print("tmpStream.msgId",tmpStream:GetNetCmdId());
            if op == 3 and tmpStream:GetNetCmdId() ==LuaNetCmd.MSG_BATTLE_OVER then
                this.RecvBattleOver(tmpStream)
            end
            tmpStream:retain();
            table.insert(msgArr,tmpStream);
        end
        LRoleDataMgr:SetBattleReplayData(msgArr);
        if op == 4 or op == 5 then 
            if LRoleDataMgr.m_fightResultData ~= nil then
                LRoleDataMgr.m_fightResultData.wanFaId = 0
            end
            LRoleDataMgr:ReplayBattle(true, op)
        end

    end
end

function LuaNetRecvdMsg.RecvServerEnterBattle(stream)
    if LRoleDataMgr.m_fightResultData then
        LRoleDataMgr.m_fightResultData.wanFaId = 0
    end
    this.RecvEnterBattle(stream)
end

function LuaNetRecvdMsg.RecvEnterBattle(stream,isReplay)
    --print("RecvEnterBattle",isReplay)
    isReplay = isReplay or false
    if isReplay == false then
        LRoleDataMgr:ClearBattleReplayData()
        LRoleDataMgr:AddBattleReplayData(stream);
    end
    LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "FirstAward.FirstRewardUI")
    this:SendMsg(LGameMsg.m_deleteUIMsg)
    if isReplay == false then
        LGameMsg.m_netDealMsg:Change(LBattleEvent.RecvEnterBattle, stream)
    else
        LGameMsg.m_netDealMsg:Change(LBattleEvent.RecvEnterBattleReplay, stream)
    end
    this:SendMsg(LGameMsg.m_netDealMsg)

    LGameMsg.m_netDealBaseMsg:ChangeEventId(LGameEvent.EnterBattle)
    this:SendMsg(LGameMsg.m_netDealBaseMsg)
end

function LuaNetRecvdMsg.RecvDoBattle(stream,isReplay)
    isReplay = isReplay or false
    --print("RecvDoBattle")
    if isReplay == false then
        LRoleDataMgr:AddBattleReplayData(stream);
    end
    LGameMsg.m_netDealMsg:Change(LBattleEvent.RecvDoBattle, stream)
    this:SendMsg(LGameMsg.m_netDealMsg)
end

function LuaNetRecvdMsg.RecvBattleOver(stream,isReplay)
    isReplay = isReplay or false
    if isReplay == false then
        LRoleDataMgr:AddBattleReplayData(stream);
    end
    --print("RecvBattleOver")
    LGameMsg.m_netDealMsg:Change(LBattleEvent.RecvBattleOver, stream)
    this:SendMsg(LGameMsg.m_netDealMsg)
    
end

function LuaNetRecvdMsg.DealMsgConvoy(stream)
    local op = stream:ReadByte()
    if op == 1 then
        local Data = LRoleDataMgr.MyHeroInfo.m_Convoy
        Data.Quality = stream:ReadByte()
        Data.MaxNum = stream:ReadByte()
        Data.AvaNum = stream:ReadByte()
        Data.Exp = stream:ReadULongInt()
        Data.useMoney = stream:ReadUInt()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Activity.ShenshouMainUI", AppDef.UIType.FirstClassLayer)
        this:SendMsg(LGameMsg.m_initUIMsg)
    elseif op == 2 then
        -- --刷新品质
        local succ = stream:ReadByte()
        this.SetCenterTip(stream:ReadString())
        if succ == 1 then
            local Data = LRoleDataMgr.MyHeroInfo.m_Convoy
            Data.Quality = stream:ReadByte()
            Data.MaxNum = stream:ReadByte()
            Data.AvaNum = stream:ReadByte()
            Data.Exp = stream:ReadULongInt()
            Data.useMoney = stream:ReadUInt()
            LGameMsg.m_netDealMsg:Change(LUIActivityEvent.ShenshouResult, Data.Quality)
            this:SendMsg(LGameMsg.m_netDealMsg)
        end
    elseif op == 3 then
        -- --接受任务
        local succ = stream:ReadByte()
        this.SetCenterTip(stream:ReadString())
        if succ == 1 then
            local Data = LRoleDataMgr.MyHeroInfo.m_Convoy
            Data.taskId = stream:ReadWord() -- 
            Data.npcId = stream:ReadWord()
            Data.IsAutoYunShou = true
            LRoleDataMgr.MyHeroInfo.ConvoyType = 1

            LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.ShenshouMainUI")
            this:SendMsg(LGameMsg.m_deleteUIMsg)

            LGameMsg.m_netDealMsg:Change(LUIActivityEvent.ShenshouState, Data.Quality)
            this:SendMsg(LGameMsg.m_netDealMsg)

            LRoleDataMgr.MyHeroInfo:SendHeroConvoyChangedMsg()


            LGameMsg.m_autoPathMsg:ChangeToStart(Data.taskId,-1,-1,0,bit.lshift(Data.npcId,16),true,false,AutoPachEndCallback)
            this:SendMsg(LGameMsg.m_autoPathMsg)
			LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, true)
			this:SendMsg(LGameMsg.m_baseMsgWithOne)
        end
    elseif op == 4 then
        --[[
        这个不需要了，改在任务追踪
        ]]
        -- local Data = LRoleDataMgr.MyHeroInfo.m_Convoy
        -- Data.Quality = stream:ReadByte()
        -- Data.MaxNum = stream:ReadByte()
        -- Data.AvaNum = stream:ReadByte()
        -- Data.Exp = stream:ReadULongInt()
        -- Data.taskId = stream:ReadWord()
        -- Data.npcId = stream:ReadWord()
        -- Data.useMoney = -1

        -- if LRoleDataMgr.MyHeroInfo.ConvoyType == 1 then
        --     LGameMsg.m_netDealMsg:Change(LUIActivityEvent.ShenshouState, 0)
        --     this:SendMsg(LGameMsg.m_netDealMsg)
        -- end
        -- LRoleDataMgr.MyHeroInfo:SendHeroConvoyChangedMsg()
    elseif op == 5 then
        local roleId = stream:ReadUInt()
        local succ = stream:ReadByte()
        if succ == 0 then
            local msg = stream:ReadString()
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
            this:SendMsg(LGameMsg.m_scrollTipsMsg)
        end
    elseif op == 6 then
        local succ = stream:ReadByte()
        if succ ~= 1 then
            local msg = stream:ReadString()
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
            this:SendMsg(LGameMsg.m_scrollTipsMsg)
        end
    elseif op == 7 then
        local roleid = stream:ReadUInt()
        local succ = stream:ReadByte()
        if succ == 1 then
            local msg = stream:ReadString()
            local function OKCallback()
                LuaNetSendMsg:QueryConvoyFightConfirm(roleid)
            end
            local function cancelCallback()
            end

            local msgData = 
            {
                okCallback = OKCallback,
                cancelCallback = cancelCallback,
                desc = msg,
                title = GUITips.Husong_Qiangduo
            }
            LGameMsg.m_netDealMsg:Change(LUIMsgBoxEvent.ShowMsgBox, msgData)
            this:SendMsg(LGameMsg.m_netDealMsg)
        else
            local msg = stream:ReadString()
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
            this:SendMsg(LGameMsg.m_scrollTipsMsg)
        end
    elseif op == 8 then
        this.SetCenterTip(stream:ReadString())
        -- 护送结束 检查是否继续护送
        LGameMsg.m_netDealMsg:Change(LUIActivityEvent.ShenshouFinish)
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 9 then
        local roleId = stream:ReadUInt()
        local succ = stream:ReadByte()
        if succ == 0 then
            local msg = stream:ReadString()
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
            this:SendMsg(LGameMsg.m_scrollTipsMsg)
        end
    elseif op == 10 then
        local roleid = stream:ReadUInt()
        local succ = stream:ReadByte()
        if succ == 1 then
            -- GAMELAYER->RemoveIndependDialog()
            -- DialogOKCancel* Notify = DialogOKCancel::create()
            -- Notify->SetText(RES_STRC(DataConsts::RIS_LEFTUI_MSG68),Msg)
            -- Notify->SetPriority(PRY_LOW-5)
            -- Notify->SetOkCallBack(GAMELAYER->GetGameMap(), (SEL_CallFuncN)&GameMap::ConvoyGoToFightCallBack)
            -- GAMELAYER->addChild(Notify, 100, GameLayer::INDEPENDDIALOGLAYER)
        else
            local msg = stream:ReadString()
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
            this:SendMsg(LGameMsg.m_scrollTipsMsg)
        end
    elseif op == 11 then
        if LRoleDataMgr.MyHeroInfo:IsTeam() == true then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_GS_TIP3)
            this:SendMsg(LGameMsg.m_scrollTipsMsg)
            return
        end

        local herodata = LRoleDataMgr.MyHeroInfo
        herodata.IsTakingTask = true

        --下一个寻路NPCId
        local opVal = stream:ReadWord()
        --目标点相关信息
        local sid = stream:ReadUInt()
        local posx = stream:ReadUInt()
        local posy = stream:ReadUInt()
        local pos = cc.p(posx,posy)
        herodata.ConvoyInfo = stream:ReadString()
        local function OKCallback()
            
        end
        local function cancelCallback()
        end
        local msgData = {
            okCallback = OKCallback,
            cancelCallback = cancelCallback,
            desc = herodata.ConvoyInfo,
            okBtnName = GUITips.UI_Btn_Shoudongyunbiao,
            cancelBtnName = GUITips.UI_Btn_Zidongyunbiao

        }
        LGameMsg.m_netDealMsg:Change(LUIMsgBoxEvent.ShowMsgBox, msgData)
        this:SendMsg(LGameMsg.m_netDealMsg)
        --第一次接镖弹出运镖提示框
        -- int DialogMode = ConvoyNotifyDialog::MODE_CHANGE_CONVOY_AUTO
        -- if(false == herodata.IsAutoConvoy)
        -- {
        --     DialogMode = sid == 3 ? ConvoyNotifyDialog::MODE_GET_CONVOY : ConvoyNotifyDialog::MODE_CHANGE_CONVOY
        -- }

        -- ConvoyNotifyDialog* dialog = ConvoyNotifyDialog::createDialog(herodata, 0, DialogMode)
        -- dialog->SetText(herodata.ConvoyInfo)
        -- dialog->SetCallBack(this, (SEL_CallFuncNII)&GameScene::OnConvoyMineCallBack)
        -- GAMELAYER->addChild(dialog,100,GameLayer::INDEPENDDIALOGLAYER)    
    elseif op == 12 then
        -- string Msg = stream:ReadString()
        -- DATA_MGR->PopInfoQueue.Add(DataMgr::CPopInfoQueue::QT_CONVOYMINE_OVER, 0, 0, RES_STR(DataConsts::RIS_LEFTUI_MSG69), Msg)
        -- if(GameLayer* gLayer = GAMELAYER) { gLayer->StartPopInfoQueueCheck() }
    elseif op == 14 then
        if LRoleDataMgr.MyHeroInfo:IsTeam() == true then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_GS_TIP3)
            this:SendMsg(LGameMsg.m_scrollTipsMsg)
            return
        end
        local herodata = LRoleDataMgr.MyHeroInfo
        --如果以存在运镖界面 则掠过（此种情况在接镖的时候会遇到）
        if string.len(herodata.ConvoyInfo) > 0 then
            return
        end

        --寻路结束自动弹窗用
        herodata.ConvoyNPC = stream:ReadWord()

        --每次保存一下运镖信息
        herodata.ConvoySid = stream:ReadUInt()
        local posx = stream:ReadUInt()
        local posy = stream:ReadUInt()
        herodata.ConvoyPos = cc.p(posx,posy)
        herodata.ConvoyInfo = stream:ReadString()
        herodata.IsTakingTask = true

        --弹出运镖弹出框
        -- ConvoyNotifyDialog* dialog = ConvoyNotifyDialog::createDialog(herodata,0,ConvoyNotifyDialog::MODE_GET_CONVOY)
        -- dialog->SetText(herodata.ConvoyInfo)
        -- dialog->SetCallBack(this, (SEL_CallFuncNII)&GameScene::OnConvoyMineCallBack)
        -- GAMELAYER->addChild(dialog,110,GameLayer::INDEPENDDIALOGLAYER)
    elseif op == 15 then
        -- string Msg = stream:ReadString()

        -- --橙色车换车后弹出确认框
        -- ConvoyNotifyDialog* dialog = ConvoyNotifyDialog::createDialog(DATA_MGR->Hero.MyHeroInfo,0,ConvoyNotifyDialog::MODE_CHANGE_CONVOY)
        -- dialog->SetText(Msg)
        -- dialog->SetCallBack(this, (SEL_CallFuncNII)&GameScene::OnConvoyMineCallBack)
        -- GAMELAYER->addChild(dialog,100,GameLayer::INDEPENDDIALOGLAYER)
    elseif op == 16 then
        local Msg = stream:ReadString()

        local herodata = LRoleDataMgr.MyHeroInfo
        data.IsTakingTask=true

        -- ConvoyNotifyDialog* dialog = ConvoyNotifyDialog::createDialog(data,0,ConvoyNotifyDialog::MODE_FINISH_CONVOY)
        -- dialog->SetText(Msg)
        -- dialog->SetCallBack(this, (SEL_CallFuncNII)&GameScene::OnConvoyMineCallBack)
        -- GAMELAYER->addChild(dialog,100,GameLayer::INDEPENDDIALOGLAYER)
    elseif op == 17 then
        --换车交互成功返回，关闭检测timer
        --unschedule(schedule_selector(GameScene::OnConvoyMineWaitingUpdate))

        local herodata = LRoleDataMgr.MyHeroInfo

        herodata.ConvoyNPC = stream:ReadWord()
        herodata.ConvoySid = stream:ReadUInt()
        local posx = stream:ReadUInt()
        local posy = stream:ReadUInt()
        herodata.ConvoyPos = cc.p(posx,posy)

        --第一次接镖需要等待玩家操作，否则直接寻路
        --if(herodata.ConvoySid != 3) { ConvoyMineToNextStep() }
    elseif op == 18 then
        local herodata = LRoleDataMgr.MyHeroInfo
        LRoleDataMgr.MyHeroInfo.ConvoyType = stream:ReadByte()
        LRoleDataMgr.MyHeroInfo.m_Convoy.Quality = stream:ReadByte()

        --op=4不需要了，也不需要请求了
        --LuaNetSendMsg:QueryConvoyNote()
        LRoleDataMgr.MyHeroInfo:SendHeroConvoyChangedMsg()
    end
end

--日常Boss
function LuaNetRecvdMsg.DealMsgDailyBoss(stream)
    local function OkFunc()
        Utils:OpenVipUI()
    end

    local function CloseFunc()
        LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "FirstAward.FristAward")
        this:SendMsg(LGameMsg.m_deleteUIMsg)
    end

    local op = stream:ReadByte()  -- option
    if op == 1 then
        --Boss信息
        this.DealMsgDailyBossInfo(stream)
    elseif op == 2 then
        --更新星级、次数
        local data  = LActivityManager:GetDailyBossData()
        if #data.m_bossInfos == 0 then
            LuaNetSendMsg:QueryDailyBoss(3)
            return
        end
        data.m_bossAwardStar = stream:ReadByte()
		local index = stream:ReadByte()          --从1开始
		data.m_meiriBossTime = stream:ReadByte()
		data.m_bossInfos[index].getStar = stream:ReadByte()  --星级
        --通知界面刷新星级次数
        LGameMsg.m_netDealMsg:Change(LUIDailyBossEvent.DailyBossUpdateTime,index)
        this:SendMsg(LGameMsg.m_netDealMsg)
        --通知UI更新领取结果
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIDailyBossEvent.DailyBossDrawState)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
    elseif op == 6 then
        --关闭日常Boss界面
         LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.DailyBossMainUI")
         this:SendMsg(LGameMsg.m_deleteUIMsg)
    elseif op == 7 then                       
        -- 战斗结束信息
         stream:ReadByte()
         local result  = LActivityManager:GetDailyBossResultData()
         result.m_battleExp1 = stream:ReadUInt()
         result.m_battleStarNum = stream:ReadByte()
         result.m_openUIType = stream:ReadByte()
         result.m_totalStarNum = stream:ReadByte()
         result.m_addStarNum = stream:ReadByte()
         result.m_itemId = stream:ReadWord()
         result.m_itemNum = stream:ReadUInt()
         --TODO:直接弹出结算面板
         if result.m_openUIType == 1 then
             Utils:ShowFiristAwardUI(AppDef.EActivityID.EAID_BOSS,CloseFunc)
         end
         
    --     --加入弹出信息队列
    --     DATA_MGR->PopInfoQueue.Add(DataMgr::CPopInfoQueue::QT_BOSS_STAR, 0, 0, "", "")
    --     GAMELAYER->StartPopInfoQueueCheck()
    elseif op == 8 then  
        --奖励信息
        this.DealMsgDailyBossAwardInfo(stream)             
    elseif op == 9 then               
        --星级奖励领取结果
        this.DealMsgDailyBossDrawResult(stream)
    elseif op ==10 then
        --购买次数后返回
         local val = stream:ReadByte()
         if 0 == val then
             local Rtype = stream:ReadByte()
             local msg = stream:ReadString()
             if Rtype == 0 then
                 Utils:ShowScrollTips(msg)
             else
                 Utils:ShowDialogOKCancel(msg,OkFunc)
             end
         else
             local data  = LActivityManager:GetDailyBossData()
             data.m_meiriBossTime = stream:ReadByte()
             --通知界面更新次数
             LGameMsg.m_netDealMsg:Change(LUIDailyBossEvent.DailyBossUpdateTime,0)
             this:SendMsg(LGameMsg.m_netDealMsg)
         end
    elseif op == 11 then
        local data  = LActivityManager:GetDailyBossData()
        data.m_isShowStarButton = (stream:ReadByte()==1)
        data.m_bossAwardStar = stream:ReadByte()
        --屏蔽新手目标显示
        
    end
end

--日常Boss 奖励信息
function LuaNetRecvdMsg.DealMsgDailyBossAwardInfo(stream)
    local data  = LActivityManager:GetDailyBossData()
	data.m_bossAwardStar = stream:ReadByte()
	local num  = stream:ReadByte()
    data.m_awardInfos = {}
	for k = 1,num do
		local awardInfo = {
            ["totalStar"] = data.m_bossAwardStar, ["needStar"] = 0, ["yuanBao"] = 0, ["drawState"] = 0,
            ["itemType"] = {}, ["itemID"] = {}, ["itemNum"] = {}
        } 
        awardInfo.needStar = stream:ReadByte()
        awardInfo.yuanBao = stream:ReadWord()
        awardInfo.drawState = stream:ReadByte()

		local itemCnt = stream:ReadByte()
		for i = 1,itemCnt do
			local itemType =  stream:ReadByte() --物品类型，1物品，2宠物(暂无)
			table.insert(awardInfo.itemType,itemType)
			if itemType == 1 then
				table.insert(awardInfo.itemID,stream:ReadWord())
				table.insert(awardInfo.itemNum,stream:ReadByte())
			end
--			else if (itemType == 2)
--			{
--				PetData pet
--				MsgDealMgr::ReadPetInfo(pet,stream)
--				_vecPetData.push_back(pet)
--				awardInfo.itemID.push_back(pet.id)
--				awardInfo.itemNum.push_back(1)
--			}			
		end
		table.insert(data.m_awardInfos,awardInfo)
	end
    -- 刷新页面奖励信息
    LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIDailyBossEvent.DailyBossShowAward)
    this:SendMsg(LGameMsg.m_netDealBaseMsg)
end

--日常Boss领取奖励结果
function LuaNetRecvdMsg.DealMsgDailyBossDrawResult(stream)
	local index = stream:ReadByte()
	local succ = stream:ReadByte()
    local msg = stream:ReadString()
    if #msg > 0 then 
        Utils:ShowScrollTips(msg)
    end
	if succ == 1 then
        local data  = LActivityManager:GetDailyBossData()
        local idx = index+1
        if #data.m_awardInfos > index then
            data.m_awardInfos[idx].drawState = 1
            --通知UI更新领取结果
            LGameMsg.m_netDealMsg:Change(LUIDailyBossEvent.DailyBossDrawState,idx)
            this:SendMsg(LGameMsg.m_netDealMsg)
        end
	end
end

--日常Boss，Boss信息解析
function LuaNetRecvdMsg.DealMsgDailyBossInfo(stream)
    local data  = LActivityManager:GetDailyBossData()
	stream:ReadByte()     --0:积分，非零： 付妖镇魔(不用)
	data.m_meiriBossTime = stream:ReadByte()        --剩余次数
	data.m_bossAwardStar = stream:ReadByte()       --拥有星星数
	stream:ReadByte()     --AllStarNum(不用)
	stream:ReadWord()     --场景ID(不用)
	stream:ReadWord()     --坐标x(不用)
	stream:ReadWord()     --坐标Y(不用)
    data.m_bossInfos = {}
	local cnt = stream:ReadByte() 
    for k = 1,cnt do
        local info = {}
        info.vecIndex = stream:ReadByte()         --回传时调用的index
        info.getStar = stream:ReadByte()          --星级
        info.difficulty = stream:ReadByte()       --难度
        info.monsterID =  stream:ReadWord()       --怪物ID
        info.dropExp = stream:ReadUInt()          --经验
        info.itemId=stream:ReadWord()          --物品id
        info.itemNum=stream:ReadUInt()         --物品数量
      --  ----print("s数据",info.itemId,"------",info.itemNum)
        stream:ReadString()                  --任务描述1
        stream:ReadByte()                    --描述1是否完成
        stream:ReadString()                  --任务描述2
        stream:ReadByte()                    --描述2是否完成
        info.monsterName = stream:ReadString()    --怪物名字  
        info.monsterLv =  stream:ReadWord()  
        table.insert(data.m_bossInfos,info)
    end
    --通知界面更新Boss信息
    LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIDailyBossEvent.DailyBossShowBossInfo)
    this:SendMsg(LGameMsg.m_netDealBaseMsg)

    local isGuide =  stream:ReadByte()  --0  不引导 1 引导
    --TODO 通知引导(暂无)
end

function LuaNetRecvdMsg.ReadTeamMember(stream,member)
    --[[
            self.m_type = 0
    self.m_lineupPos = 0
    self.m_id = 0
    self.m_name = ""
    self.m_lv = 0
    self.m_professnal = 0
    self.m_sex = 0
    self.m_weapon = 0
    self.m_wLight = 0
    self.m_title = ""
    self.m_state = 0
    self.m_shap = 0
    self.m_power = 0
    self.m_star1 = 0
    self.m_star2 = 0

=1 人物    tarPos  roleId   serverZone   serverId  leaveFlag   name   level  zhongzu   sex    wuqi   wuqi_light  zhandouli  title  shape 
            1byte    4byte     4byte       4byte      1byte    string  4byte   1byte   1byte   4byte     1byte      4byte    2byte  1byte
                                                                      
=2 宠物    tarPos   petId    PetName   level   qulity  qulityLv  zhandouli
           1byte    4byte    string    4byte    1byte    1byte     4byte
            ]]
    member.m_type = stream:ReadByte()
    if member.m_type == 1 then
        member.m_srcPos = stream:ReadByte()
        member.m_lineupPos = stream:ReadByte()
        member.m_cap = stream:ReadByte()
        member.m_id = stream:ReadUInt()
        member.m_serverZone = stream:ReadUInt()
        member.m_serverId = stream:ReadUInt()
        member.m_state = stream:ReadByte()
        member.m_name = stream:ReadString()
        member.m_lv = stream:ReadWord()
        member.m_professnal = stream:ReadByte()
        member.m_sex = stream:ReadByte()
        member.m_weapon = stream:ReadWord()
        member.m_wLight = stream:ReadByte()
        member.m_power = stream:ReadUInt()
        member.m_titleNum = stream:ReadByte()
        for i=1, member.m_titleNum do
            local title = stream:ReadWord()
            table.insert(member.m_title, title)
        end
        member.m_shap = stream:ReadUInt()
    elseif member.m_type == 2 then
        member.m_srcPos = stream:ReadByte()
        member.m_lineupPos = stream:ReadByte()
        member.m_id = stream:ReadUInt()
        member.m_name = stream:ReadString()
        member.m_lv = stream:ReadWord()
        member.m_star = stream:ReadByte()
        member.m_subStar = stream:ReadByte()
        member.m_power = stream:ReadUInt()
    end
end

function LuaNetRecvdMsg.DealMsgTeamOperation(stream)
    local opt = stream:ReadByte()
    -- GameLayer *gameLayer = GAMELAYER
    -- if(NULL == gameLayer)
    --     return
    if opt == 1 then                           --创建成功
        --local capID =  stream:ReadUInt()   --队长ID
        --gameLayer->GetGameMap()->PlayerCreateTeam(capID)
        
        local success = stream:ReadByte()
        if success == 1 then
            LRoleDataMgr.MyHeroInfo:CreateTeam()
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_MDSI_MSGI4)
            this:SendMsg(LGameMsg.m_scrollTipsMsg)
            LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIRoleTeamEvent.CreateTeam)
            this:SendMsg(LGameMsg.m_netDealBaseMsg)

            LGameMsg.m_netDealMsg:Change(LUIRoleTeamEvent.ApplyListChanged, false)
            this:SendMsg(LGameMsg.m_netDealMsg)

            LGameMsg.m_baseMsgWithOne:Change(LUIRoleDataChangeEvent.CheckOpenBuffTips,AppDef.BuffType.Team)
            this:SendMsg(LGameMsg.m_baseMsgWithOne)
            
            --队伍创建完成后请求我的队伍列表信息
            --LuaNetSendMsg:QueryMyTeamInfo()
        end
    elseif opt == 2 then--有人加入队伍或者自己加入的队伍
        local joinId = stream:ReadUInt()
        
        if joinId == LRoleDataMgr.MyHeroInfo.id then
            --我加入队伍
            local state = stream:ReadByte()
            LRoleDataMgr.MyHeroInfo:JoinTeam()
            LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIRoleTeamEvent.CreateTeam)
            this:SendMsg(LGameMsg.m_netDealBaseMsg)
            LGameMsg.m_netDealMsg:Change(LUIRoleTeamEvent.ApplyListChanged, false)
            this:SendMsg(LGameMsg.m_netDealMsg)

            if state == 0 then --初始是暂离
                --默认归队
                LuaNetSendMsg:QueryBackTeam()
            end
            LGameMsg.m_baseMsgWithOne:Change(LUIRoleDataChangeEvent.CheckOpenBuffTips,AppDef.BuffType.Team)
            this:SendMsg(LGameMsg.m_baseMsgWithOne)
        end
        --LuaNetSendMsg:QueryMyTeamInfo()
    elseif opt == 4 or opt == 6 then--申请加入队伍
        --4是申请入队
        --5是邀请组队
        local id = stream:ReadUInt()--ID
        local applyInfo = LRoleDataMgr.MyHeroInfo:GetApplyMember(id)
        if applyInfo == nil then
            applyInfo = LTeamApplyData:New()
            applyInfo.id = id
            LRoleDataMgr.MyHeroInfo:AddApplyMember(applyInfo)
        end
        applyInfo.name = stream:ReadString()
        applyInfo.profession = stream:ReadByte()
        applyInfo.sex = stream:ReadByte()
        applyInfo.level = stream:ReadWord()
        applyInfo.zhandouli = stream:ReadUInt()
        LGameMsg.m_netDealMsg:Change(LUIRoleTeamEvent.ApplyListChanged, true)
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif opt == 9 then
        -- local leaderId = stream:ReadUInt()
        -- local leaveId = stream:ReadUInt()
        LRoleDataMgr.MyHeroInfo:LeaveTeam()
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIRoleTeamEvent.TeamMemberChanged)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)

        LGameMsg.m_baseMsgWithOne:Change(LUIRoleDataChangeEvent.CheckOpenBuffTips,AppDef.BuffType.Team)
        this:SendMsg(LGameMsg.m_baseMsgWithOne)
    elseif opt == 16 then
        local suc = stream:ReadByte()
        if suc == 0 then
            local msg = stream:ReadString()
            if string.len(msg) > 0 then
                LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
                this:SendMsg(LGameMsg.m_scrollTipsMsg)
            end
        else
            local teamData = LRoleDataMgr.MyHeroInfo.m_pTeam
            teamData:ResetMembers()
            teamData.m_byType = stream:ReadByte()
            teamData.m_zhenfaId = stream:ReadWord()
            local num = stream:ReadByte()
            for i = 1, num do
                local member = teamData:GetTeamMemberByInd(i)
                LuaNetRecvdMsg.ReadTeamMember(stream,member)
                if member.m_type == 1 and member.m_id == LRoleDataMgr.MyHeroInfo.id then
                    if member.m_cap == 1 then
                        LRoleDataMgr.MyHeroInfo:SetCap(true)
                    else
                        LRoleDataMgr.MyHeroInfo:SetCap(false)
                    end
                end
            end
            LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIRoleTeamEvent.TeamMemberChanged)
            this:SendMsg(LGameMsg.m_netDealBaseMsg)
            LGameMsg.m_baseMsgWithOne:Change(LUIRoleDataChangeEvent.CheckOpenBuffTips,AppDef.BuffType.Team)
            this:SendMsg(LGameMsg.m_baseMsgWithOne)
        end
    elseif opt == 20 then
        local res = stream:ReadByte()
        local teamData = LRoleDataMgr.MyHeroInfo.m_pTeam
        local flag = stream:ReadByte()
        if flag == 0 then
            teamData.m_bIsAutoApply = false
        else
            teamData.m_bIsAutoApply = true
        end
        local publishData = teamData.m_pPublishList
        publishData.m_byType = stream:ReadByte()
        publishData.m_minLv = stream:ReadWord()
        publishData.m_maxLv = stream:ReadWord()

        local msg = stream:ReadString()
        if string.len(msg) > 0 then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
            this:SendMsg(LGameMsg.m_scrollTipsMsg)
        end

        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIRoleTeamEvent.TeamTargetChanged)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
        

--     elseif op == 20 then
--         --[[
--     op=20   type   teamId   minLevel    maxLevel   isSuccess      msg
-- 1byte  1byte   4byte      2byte       2byte      1byte       string
--                                                 = 0 failed
--                                                 = 1 success

-- 注：minLevel、maxLevel为新增字段，其余为原来的协议字段
--         ]]
    elseif opt == 22 then
        --[[
        获取队伍列表
    op=22    type   teamNum  { minLevel   maxLevel   memberNum [  roleId   name   leaveFlag  zhongzu   sex   level  ]}
            1byte   1byte    1byte       2byte      2byte     1byte        4byte  string    1byte     1byte   1byte  2byte
        ]]
        LGameMsg.m_netDealMsg:Change(LUIRoleTeamEvent.RecvTeamPublishList, stream)
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif opt == 24 then
        --个人开启自动组队
        local teamType = stream:ReadByte()
        local res = stream:ReadByte()
        local msg = stream:ReadString()
        if res == 1 then
            LRoleDataMgr.MyHeroInfo.m_pTeam.m_bIsAutoApply = true
        else
            LRoleDataMgr.MyHeroInfo.m_pTeam.m_bIsAutoApply = false
        end
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIRoleTeamEvent.AutoApplyChanged)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)

    elseif opt == 25 then
        --[[
        op=25   num   { roleId   name    zhongzu   sex   level  zhandouli  state}
        1byte  2byte     4byte  string    1byte   1byte  2byte    4byte    1byte
        ]]
        LGameMsg.m_netDealMsg:Change(LUIRoleTeamEvent.RecvNearPlayers, {3,stream})
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif opt == 26 then
        --个人关闭自动组队
        local res = stream:ReadByte()
        local msg = stream:ReadString()
        if res == 1 then
            LRoleDataMgr.MyHeroInfo.m_pTeam.m_bIsAutoApply = false
        end
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
        this:SendMsg(LGameMsg.m_scrollTipsMsg)
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIRoleTeamEvent.AutoApplyChanged)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
    elseif opt == 27 then
        local teamData = LRoleDataMgr.MyHeroInfo.m_pTeam
        local publishData = teamData.m_pPublishList
        local flag = stream:ReadByte()
        if flag == 0 then
            teamData.m_bIsAutoApply = false
        else
            teamData.m_bIsAutoApply = true
        end
        publishData.m_byType = stream:ReadByte()
        publishData.m_minLv = stream:ReadWord()
        publishData.m_maxLv = stream:ReadWord()

        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIRoleTeamEvent.TeamTargetChanged)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
    elseif opt == 28 then
        LGameMsg.m_netDealMsg:Change(LUIRoleTeamEvent.RecvNearPlayers, {1,stream})
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif opt == 29 then
        LGameMsg.m_netDealMsg:Change(LUIRoleTeamEvent.RecvNearPlayers, {2,stream})
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif opt == 31 then
        --[[
        等级有变化
        ]]
        local rid = stream:ReadUInt()
        local teamData = LRoleDataMgr.MyHeroInfo.m_pTeam
        local member = teamData:GetHeroMemberById(rid)
        if member == nil then
            return
        end
        member.m_lv = stream:ReadWord()
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIRoleTeamEvent.TeamMemberChanged)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
    --玩家的队伍信息
    elseif opt == 32 then
        local roleId = stream:ReadUInt()

        local isSuccess = stream:ReadByte()
       
        local teamID=0
        if isSuccess==1 then
            teamID = stream:ReadUInt() 
        end
        if isSuccess==0 then
            stream:ReadString()
        end
        
        Utils:SendMsg(LUIChatEvent.getRoleTeamId,{id=roleId,tID=teamID},true)
       
    end
end

function LuaNetRecvdMsg.DealMsgSYSTime(stream)
    LDataConstMgr.m_sysTime = stream:ReadUInt()
    if stream:GetSeek() < stream:GetCurLen() then
        LDataConstMgr.m_serverTime = stream:ReadUInt()
--天元争霸icon倒计时
        LWWDXMgr:beginCountDown(true)
    end
end

function LuaNetRecvdMsg.SetCenterTip(msg, id)

    if msg == nil then
        return
    end

    if id == nil then
        id = LUILogicEvent.ShowSrcollTips
    end
    
    if string.len(msg) ~= 0 then
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(id, msg)
        this:SendMsg(LGameMsg.m_scrollTipsMsg)
    end
end

function LuaNetRecvdMsg.DealMsgHorseInfo(stream)
    local vechorsedata = LRoleDataMgr.MyHeroInfo.Horse
    local OtInfo = LRoleDataMgr.MyHeroInfo.horseExInfo
    local op = stream:ReadByte()
    
    if op == 1 then--我的坐骑列表
        vechorsedata = LRoleDataMgr.MyHeroInfo:GetHorseListAndReset()
        local num = stream:ReadByte()
        for i = 1, num do
            local horsedata = LHorseData:New()
            horsedata.id = stream:ReadByte()
            horsedata.timeLimit = stream:ReadUInt()
            -- horsedata.basicDamage = stream:ReadUInt()
            -- horsedata.basicRecovery = stream:ReadUInt()
            -- horsedata.basicHP = stream:ReadUInt()
            horsedata.basicSpeed = stream:ReadUInt()
            table.insert(vechorsedata,horsedata)
            local baseData = LDataConstMgr:GetHorseConfigData(horsedata.id)
            baseData.isGet = true
        end
        LDataConstMgr:SortHorseConfig()
        local oldInd = OtInfo.useIndex
        OtInfo.useIndex = stream:ReadByte()
        OtInfo.qhLevel = stream:ReadByte()
        OtInfo.plusRate = stream:ReadByte()
       
        -- OtInfo.qh_damage = stream:ReadUInt()
        -- OtInfo.qh_recovery = stream:ReadUInt()
        -- OtInfo.qh_Hp = stream:ReadUInt()
        if OtInfo.useIndex ~= 255 and oldInd ~= OtInfo.useIndex then
            LRoleDataMgr.MyHeroInfo:SendHeroModelChangedMsg()
        end
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIHorseEvent.GotHorseList)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
        if LRoleDataMgr.MyHeroInfo.isInitHorseList then
            LRoleDataMgr.MyHeroInfo.isInitHorseList = false
        else
            LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIHorseEvent.HorseListChange)
            this:SendMsg(LGameMsg.m_netDealBaseMsg)
        end
        ------------------------------------------------------获取服务器发来的消息计算总战力
        -- CalTotalPower()
        -- ----dump(OtInfo, "CalTotalPower =>>>>>>>")
        Utils:CalTotalPower(OtInfo)
    -----------------------------------
       
        LRedDotCheckMgr:MainMountCheck()

    elseif op == 2 then--强化成功失败
        -- CalTotalPower()
        Utils:CalTotalPower(OtInfo)
        local nType = stream:ReadByte()
        if nType == 1 then
            local curLv = stream:ReadByte()
            local exp = stream:ReadUInt()
            local expLimit = stream:ReadUInt()
            LGameMsg.m_netDealMsg:Change(LUIHorseEvent.RecvEnforceValue, {curLv,exp,expLimit})
            this:SendMsg(LGameMsg.m_netDealMsg)
        elseif nType == 2 then
            local succ = stream:ReadByte()
            if succ == 0 then
                local msg = stream:ReadString()
                LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
                this:SendMsg(LGameMsg.m_scrollTipsMsg)
            elseif succ == 1 then
                local curLv = stream:ReadByte()
                local exp = stream:ReadUInt()
                local expLimit = stream:ReadUInt()
        
                local msg = stream:ReadString()

                if string.len(msg) > 0 then
                    LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
                    this:SendMsg(LGameMsg.m_scrollTipsMsg)
                end
                LGameMsg.m_netDealMsg:Change(LUIHorseEvent.RecvEnforceValue, {curLv,exp,expLimit})
                this:SendMsg(LGameMsg.m_netDealMsg)
                
                --SoundMgr:GetInstance():PlayEffect(Game_EffQiangHuaChengGong)
            end
            
        end
         
    elseif op == 3 then--进阶
        local sf = stream:ReadByte()
        if sf == 0 then
            local msg = stream:ReadString()
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
            this:SendMsg(LGameMsg.m_scrollTipsMsg)
        else--成功返回类型
            local horseId = stream:ReadByte()
            LGameMsg.m_netDealMsg:Change(LUIHorseEvent.AddNewHorse, horseId)
            this:SendMsg(LGameMsg.m_netDealMsg)

            local msg = stream:ReadString()
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
            this:SendMsg(LGameMsg.m_scrollTipsMsg)
           
        end
    elseif op == 4 then--设置骑乘状态
        local id = stream:ReadByte()
        local sf = stream:ReadByte()
        local oldInd = OtInfo.useIndex
        if sf == 0 then
            local msg = stream:ReadString()
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
            this:SendMsg(LGameMsg.m_scrollTipsMsg)
            OtInfo.useIndex = 0xff
        else--当前骑乘状态
            local curIdx = 0xff
            if id ~= 0xff then
                for i = 1,#vechorsedata do
                    if id == vechorsedata[i].id then
                        curIdx = i - 1
                        vechorsedata[i].basicSpeed = stream:ReadUInt()
                        break
                    end
                end
            elseif OtInfo.useIndex ~= 0xff then
                vechorsedata[OtInfo.useIndex + 1].basicSpeed = stream:ReadUInt()
            end
            OtInfo.useIndex = curIdx
        end
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIHorseEvent.RideStateChanged)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
        if oldInd ~= OtInfo.useIndex then
            LRoleDataMgr.MyHeroInfo:SendHeroModelChangedMsg()
        end
    elseif op == 5 then  --附加坐骑信息
        -- local hoslist = LRoleDataMgr.MyHeroInfo:GetServerHorseListAndReset()
        -- local num = stream:ReadByte()
        -- for i = 1, num do
        --     local m_hoslist = LServerHorseList:New()
        --     m_hoslist.id = stream:ReadByte()
        --     m_hoslist.describ = stream:ReadString()
        --     m_hoslist.getway = stream:ReadByte()
        --     m_hoslist.needNum = stream:ReadUInt()
        --     m_hoslist.itemId = stream:ReadUInt()
        --     -- m_hoslist.basicDamage = stream:ReadUInt()
        --     -- m_hoslist.basicRecovery = stream:ReadUInt()
        --     -- m_hoslist.basicHP = stream:ReadUInt()
        --     m_hoslist.basicSpeed = stream:ReadUInt()
        --     if stream:ReadByte() == 1 then
        --         m_hoslist.IsGet = true
        --     else
        --         m_hoslist.IsGet = false
        --     end
        --     table.insert(hoslist,m_hoslist)
        -- end
    elseif op == 6 then
        local id = stream:ReadByte()
        local success = stream:ReadByte()
        local str = stream:ReadString()
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,str)
        this:SendMsg(LGameMsg.m_scrollTipsMsg)
        if success == 1 then--更新界面显示
            --LRoleDataMgr.MyHeroInfo:UpdateHorseGetState(id)
            --GAMELAYER->GetMainMenuLayer()->ChectZuoQiRed() --刷新坐骑红点
        end
    elseif op == 8 then--其他人的坐骑列表
        local roleId = stream:ReadUInt()
        if roleId ~= LRoleDataMgr.OtherHeroInfo.id then return end
        LRoleDataMgr.OtherHeroInfo.Horse = {}
        local otherRole = LRoleDataMgr.OtherHeroInfo.horseExInfo
        local num = stream:ReadByte()
        for i = 1, num do
            local horsedata = LHorseData:New()
            horsedata.id = stream:ReadByte()
            horsedata.timeLimit = stream:ReadUInt()
            -- horsedata.basicDamage = stream:ReadUInt()
            -- horsedata.basicRecovery = stream:ReadUInt()
            -- horsedata.basicHP = stream:ReadUInt()
            horsedata.basicSpeed = stream:ReadUInt()
            table.insert(LRoleDataMgr.OtherHeroInfo.Horse,horsedata)
        end
        otherRole.useIndex = stream:ReadByte()
        otherRole.qhLevel = stream:ReadByte()
        otherRole.plusRate = stream:ReadByte()
        -- otherRole.qh_damage = stream:ReadUInt()
        -- otherRole.qh_recovery = stream:ReadUInt()
        -- otherRole.qh_Hp = stream:ReadUInt()
    elseif op == 9 then--新获得坐骑
        local horseId = stream:ReadByte()
        if horseId > 0 then
            LuaNetSendMsg:QueryHorseInfo(1)
            LGameMsg.m_netDealMsg:Change(LUIHorseEvent.AddNewHorse, horseId)
            this:SendMsg(LGameMsg.m_netDealMsg)
        end
    end
end

function LuaNetRecvdMsg.DealMsgTaskUpdate(stream)
end

function LuaNetRecvdMsg.DealMsgNpcChat(stream)
    -- if(DATA_MGR->Guide.IsGuiding)
    --     return
    -- if(FuncPushMgr::GetInstance()->IsFPRuning())
    --     return
    -- GameLayer *gLayer = (GameLayer *)target
    -- if(NULL == gLayer)
    --     return

    -- gLayer->ChooseLayerWidthNpcChat()
    --关闭所有打开的界面
  
    local op = stream:ReadByte()
    ----print("DealMsgNpcChat =============>", op)
    if op == 1 then--普通交互
        local npcChat = LNpcChatData:New()
        npcChat.Name = stream:ReadString()
        npcChat.Desc = stream:ReadString()
        local flag = stream:ReadByte()
        npcChat.type = stream:ReadByte()
        npcChat.picId = stream:ReadWord()

        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Interact.NPCChatUI",AppDef.UIType.PopWindow,npcChat)
        this:SendMsg(LGameMsg.m_initUIMsg)
    elseif op == 2 then
       
        local npcChat = LNpcChatData:New()
        npcChat.Name = stream:ReadString()
        npcChat.Desc = stream:ReadString()
        npcChat.type = stream:ReadByte()
        npcChat.picId = stream:ReadWord()
        local num = stream:ReadByte()
        for i = 1, num do
            local index = stream:ReadUInt()
            table.insert(npcChat.TextIndex, index)
            local str = stream:ReadString()

            table.insert(npcChat.Text, str)
        end
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Interact.NPCChatUI",AppDef.UIType.PopWindow,npcChat)
        this:SendMsg(LGameMsg.m_initUIMsg)

        if LRoleDataMgr.MyHeroInfo.isKuFuTaskAutoPath  then
            LRoleDataMgr.MyHeroInfo.isKuFuTaskAutoPath=false
            LuaNetSendMsg:QueryNpcChatOption(1)               
        end
       
    elseif op == 3 then
        -- local npcAudioResId = stream:ReadUInt()
        -- LGameMsg.m_audioMsg:Change(LAudioEvent.PlayNPCEffect, npcAudioResId)
        -- this:SendMsg(LGameMsg.m_audioMsg)
    elseif op == 4 then
        --shopType 1武器2防具店3药品4杂货店
        local shopType = stream:ReadByte()
        local num = stream:ReadByte()
        local goods = {}
        for i=1,num do
            local item = LPItem:New()
            item.m_pos = i
            LuaNetRecvdMsg.ReadItemData(item, stream)
            item.m_item = LItemMgr:getItem(item.m_id)
            item.m_priceType = stream:ReadByte()
            item.m_price = stream:ReadUInt()
            table.insert(goods, item)
        end

        local sel_id = stream:ReadShort()
        local sel_num = stream:ReadUInt()
--        ----print("DealMsgNpcChat", sel_id, sel_num)
        LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Shop.ShopUI")
        this:SendMsg(LGameMsg.m_deleteUIMsg)

        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Shop.ShopUI", AppDef.UIType.FirstClassLayer, {shopType=8, npcType = shopType})
        this:SendMsg(LGameMsg.m_initUIMsg)

        local msg = {normalGoods=goods, limitedGoods={}, selid=-1,shopType=8}
        LGameMsg.m_netDealMsg:Change(LUIShopEvent.ReloadShopData, msg)
        this:SendMsg(LGameMsg.m_netDealMsg)

        local selectItem = {}
        selectItem.sel_id = sel_id
        selectItem.sel_num = sel_num
        if sel_id > 0 then
            LGameMsg.m_netDealMsg:Change(LUIShopEvent.SelectShopItem, selectItem)
            this:SendMsg(LGameMsg.m_netDealMsg)
        end
    elseif op == 5 then    --SMessage
        -- gLayer->RemoveIndependDialog()

        -- NpcChatData NpcChat
        -- unsigned char flag
        -- stream:ReadString(NpcChat.Desc)
        -- flag = stream:ReadByte()

        -- NoteDialog1 *NotifyLayer = NoteDialog1::create()
        -- NotifyLayer->SetMessage(NpcChat.Desc.c_str())
        -- gLayer->addChild(NotifyLayer,100,GameLayer::INDEPENDDIALOGLAYER)
    elseif op == 9 then    --输入字符串
         local title = stream:ReadString()

        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Social.ActiveCodeUI", AppDef.UIType.PopWindow)
        this:SendMsg(LGameMsg.m_initUIMsg)

        -- gLayer->RemoveInputMsgDialog()

        -- InputMsgDialog* editbox = GAMELAYER->ShowInputMsgDialog()
        -- editbox->setTitle(title,title)
        -- editbox->setMode(InputMsgDialog::Mode_ActivCode)
        -- editbox->setPosition(CCBI_OFFSET)



    elseif op == 12 then   --12 鉴定饰品
        -- unsigned short money = stream:ReadWord()     
    elseif op == 13 then  --13 升级饰品
    elseif op == 14 then --合成
        -- unsigned char type = stream:ReadByte()
        -- switch(type)
        -- {
        -- case 1:   --水晶鉴定
        --     break
        -- case 2:   --转换属性
        --     break
        -- case 3:   --炼化石合成
        --     break
        -- case 4:   --修理装备
        --     break
        -- case 5:   --制作蓝装
        --     break
        -- case 6:   --放入蓝水晶
        --     break
        -- case 7:   --属性拆分(武器和防具)
        --     break 
        -- case 8:   --属性附着(武器、防具)
        --     break
        -- case 9:   --属性附着(饰品)
        --     break
        -- case 10:
        --     break
        -- case 11:  --分解装备(宠物铠甲)
        --     break
        -- default:
        --     break
        -- }
    elseif op == 15 then       --合成物品列表
        -- unsigned char num = stream:ReadByte()
        -- for(int i=0i<numi++)
        --     unsigned short id = stream:ReadWord()
    elseif op == 31 then   --师傅列表
    elseif op == 32 then       --输入2个字符串
        -- gLayer->RemoveInputMsgDialog()
        -- string s = stream:ReadString()
        -- string title,title1
        -- int type--界面类型，1游客绑定2至尊豪礼

        -- int pos = StringHelper::ReadBeforeCharInt(s,'|',0,type)
        -- if(pos != -1)
        -- {
        --     pos = StringHelper::ReadBeforeCharStr(s,'|',pos+1,title)
        --     title1 = s.substr(pos+1,s.size()-pos)
        -- }
        -- else
        -- {
        --     type = 0
        --     title = s
        --     title1 = s
        -- }

        -- int dialogMode = type==0 ? InputMsgDialog::Mode_Confirm : (type==1 ? InputMsgDialog::Mode_TouristBind : InputMsgDialog::Mode_VipGift)
        -- InputMsgDialog* editbox = GAMELAYER->ShowInputMsgDialog()
        -- CCLOG("dialogMode = %d", dialogMode)
        -- editbox->setMode(dialogMode)
        -- editbox->setTitle(title,title1)
        -- editbox->setPosition(CCBI_OFFSET)
    elseif op == 36 then       --仙器
        -- unsigned char type = stream:ReadByte()
        -- if(type == 1)       --铸造仙器
        -- {
        -- }
        -- elseif(type == 2)  --转换属性1
        -- {
        -- }
        -- elseif(type == 3)  --转换属性2
        -- {
        -- }
    elseif op == 38 then --新手任务领取或完成
        -- local npcType = stream:ReadByte()
        -- local npcPicId = stream:ReadWord()
        -- local _TaskId = stream:ReadUInt()
        -- local _TaskName = stream:ReadString()
        -- local bufText = stream:ReadString()

        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Interact.NPCChatTaskUI",AppDef.UIType.PopWindow,stream)
        this:SendMsg(LGameMsg.m_initUIMsg)
        --注意：新手任务一定要加载缓存列表中，避免升级界面删除此界面
        -- string Msg = SystemHelper::GetHexString((char*)stream:GetBufferSeek(), stream:GetSize()-stream:GetSeekPos())
        -- DATA_MGR->PopInfoQueue.Add(DataMgr::CPopInfoQueue::QT_TASK_ACCEPT, 0, 0, Msg, "")
        -- gLayer->StartPopInfoQueueCheck()
    elseif op == 40 then       --采集任务
        --local selectType = stream:ReadByte()-- 1采集中... 2开启中 ... 3礼盒领取中 ... 4宝箱开启中
        local collectTip = stream:ReadString()
        local npcId = stream:ReadWord()
        local serialNum = stream:ReadWord()
        local seconds = stream:ReadUInt() --秒数
        local pic = stream:ReadUInt()
        --[[
        op=40     msg     npcId    npcIdx    second     pic 
1byte     string    2byte     2byte      4byte    4byte

        ]] 
        local collectData = {}
        if seconds == 0 then
            LuaNetSendMsg:QueryNpcChatOption(serialNum)
        else
            collectData["collectTip"] = collectTip
            collectData["npcId"] = npcId
            collectData["serialNum"] = serialNum
            collectData["seconds"] = seconds
            collectData["pic"] = pic
            -- collectData["type"] = selectType
            --------dump(collectData, "QueryNpcChatOption ========>>")
            if npcId >= 77 and npcId <= 79 then
                --帮派战判断要先判断能不能占塔
                Utils:SendMsg(LUIBangPaiWarEvent.ShowTakeTowerEvent, collectData)
            else
                LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Interact.NPCCollectUI",AppDef.UIType.PopWindow,collectData)
                this:SendMsg(LGameMsg.m_initUIMsg)
            end
        end
    elseif op == 41 then       --引导箭头
        --缓存执行
        -- int opt = stream:ReadByte()
        -- DATA_MGR->PopInfoQueue.Add(DataMgr::CPopInfoQueue::QT_TASK_GUIDE_ARROW, opt, 0, "", "")
        -- gLayer->StartPopInfoQueueCheck()
    elseif op == 42 then --剧情对话
        local npcChat = LNpcChatData:New()
        npcChat.picId = stream:ReadWord()
        npcChat.type = stream:ReadByte()
        npcChat.op = stream:ReadByte()
        npcChat.Name = stream:ReadString()
        npcChat.Desc = stream:ReadString()
        LGameMsg.m_netDealMsg:Change(LUILogicEvent.PlotChatModel, true)
        this:SendMsg(LGameMsg.m_netDealMsg)

        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Interact.PlotChatUI",AppDef.UIType.Plot,npcChat)
        this:SendMsg(LGameMsg.m_initUIMsg)
        --设置剧情模式
        -- gLayer->SetPlotMode(true)

        -- NpcChatData NpcChat
        -- NpcChat.picId = stream:ReadWord()
        -- NpcChat.type = stream:ReadByte()
        -- NpcChat.op = stream:ReadByte()
        -- stream:ReadString(NpcChat.Name)
        -- stream:ReadString(NpcChat.Desc)

        -- if(PlotChatLayer* plotChat = gLayer->ShowPlotChatLayer())
        --     plotChat->LoadData(NpcChat)
    elseif  op == 43 then  --NPC商店信息
        local npcChat = LNpcChatData:New()
        npcChat.Name = stream:ReadString()
        npcChat.Desc = stream:ReadString()
        local function OKCallback()
            LuaNetSendMsg:QueryNpcChatOption(1)
        end
        local function cancelCallback()
        end
        local msgData = {
            okCallback = OKCallback,
            cancelCallback = cancelCallback,
            desc = npcChat.Desc,
        }
        LGameMsg.m_netDealMsg:Change(LUIMsgBoxEvent.ShowMsgBox, msgData)
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 44 then--徒弟榜
        return--师傅榜屏蔽
    elseif op == 45 then   -- 创建帮派
        LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "BangPai.BangPaiUI",AppDef.UIType.FirstClassLayer)
        this:SendMsg(LGameMsg.m_deleteUIMsg)
        
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "BangPai.BangPaiCreatePopup",AppDef.UIType.SecondClassLayer)
        this:SendMsg(LGameMsg.m_initUIMsg)

        local cost = stream:ReadWord()
        LGameMsg.m_netDealMsg:Change(LUIBangPaiEvent.CreateCost, cost)
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 46 then -- 通天塔挑战碑
        -- string info = stream:ReadString()
        -- gLayer->ChallengeBaZhu(info)
    elseif op == 47 then--问卷调查
        -- string s = stream:ReadString()
    elseif op == 48 then--打开帮派界面
        -- BangPaiLayer *pBangPai = GAMELAYER->ShowBangPaiLayer()
        -- pBangPai->LoadLayerByIndex(0)      -- 帮派列表
    elseif op == 49 then--打开蛮荒之地
    -- {
    --     if(CopyLayer* pLayer = gLayer->ShowCopyMainLayer()) { pLayer->SetCopyLayerType(CopyLayer::COPY_MANHUANG) pLayer->SetSelCopyID(CopyLayer::CID_RZML)}
    -- }
    elseif op == 50 then--茅山宝洞
    -- {
    --     if(CopyLayer* pLayer = gLayer->ShowCopyMainLayer()) { pLayer->SetCopyLayerType(CopyLayer::COPY_BAODONG) pLayer->SetSelCopyID(CopyLayer::CID_JQ)}
    -- }
    end
end

function LuaNetRecvdMsg.DealMsgUpdatePackage(stream)
    local op = stream:ReadByte()     -- op = 1 addItem, 2 update,delete item
    ----print("DealMsgUpdatePackage ===> op =", op)
    if op == 6 then
        --背包整理
        local success = stream:ReadByte()
        LGameMsg.m_netDealMsg:Change(LUIWaitAni.ClearWait, LuaNetCmd.MSG_UPDATE_PACKAGE)
        this:SendMsg(LGameMsg.m_netDealMsg)
        if success == 1 then
            LuaNetRecvdMsg.DealMsgPackageList(stream)   
            --通知背包UI整体刷新
            LGameMsg.m_netDealMsg:Change(LUIBagEvent.BagDataChanged,0)
            this:SendMsg(LGameMsg.m_netDealMsg)
        end
        return
    end
    -- if #LRoleDataMgr.Equip.PackageList == 0 then
    --     return
    -- end
    
    if op == 0 then -- 丢弃物品
        local pos = stream:ReadWord() + 1
        local num = stream:ReadWord()
        local success = stream:ReadByte()
        if success == 0 then   -- failed
            local msg =stream:ReadString()
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
            this:SendMsg(LGameMsg.m_scrollTipsMsg)
        end
        return
    end

    if op == 7 then
        local pos = stream:ReadWord() + 1
        local num = stream:ReadWord()
        local success = stream:ReadByte()
        if success == 0 then   -- failed
            local msg =stream:ReadString()
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
            this:SendMsg(LGameMsg.m_scrollTipsMsg)
        end
        return
    end

    local pos = stream:ReadWord() + 1
    
    local item_id = stream:ReadWord()
    local num = stream:ReadWord()
    ----print("bagUpdate1",pos,item_id,num)
    local itemInfo = LPItem:New()
    itemInfo.m_pos = pos
    local Pac = LRoleDataMgr.Equip.PackageMap
    
    local beforItemNum = 0
    if Pac[pos] ~= nil then
        beforItemNum = Pac[pos].m_num
    end

    --Pac[pos].m_pos = pos
    --Pac[pos].m_id = item_id
    --Pac[pos].m_num = num

    LuaNetRecvdMsg.ReadItemData(itemInfo,stream)
    LRoleDataMgr.Equip:UpdateItemData(pos, itemInfo)
    ----print("bagUpdate2",pos,Pac[pos].m_id,Pac[pos].m_num)
    -- 检查背包更新提升
    Utils:CheckPackageCanUp(pos, item_id, num)

    --高级藏宝图延迟提示奖励
    local isInHighCangBaoTu = LRoleDataMgr.IsInHighTreasuer
    --百花礼盒
    local isShowRandPetUI = LRoleDataMgr.m_isShowRandPetUI
    if (op == 1 or beforItemNum < num) and not isInHighCangBaoTu and not isShowRandPetUI then
        local flyItem = LFlyItem:New(LFlyItem.FlyType.Item,item_id)
        if LRoleDataMgr:GetDelayShowAward() then
            LRoleDataMgr:InsertDelayAwardData(1, flyItem)
        else
            LGameMsg.m_netDealMsg:Change(LUILogicEvent.ShowFlyItems,flyItem)
            this:SendMsg(LGameMsg.m_netDealMsg)
        end
    end

    --启动自动使用物品定时器,及装备推送
    if(op == 1 or op == 2) then
        LGameMsg.m_netDealMsg:Change(LUIMainEvent.StartAutoUseItemCheck)
        this:SendMsg(LGameMsg.m_netDealMsg)

        for i = 1, #LRoleDataMgr.upgradeItems do
            if AppDef.Pet.UpgradsMats[i] == item_id then
                LRoleDataMgr:UpdatePetUpItems()
                break
            end
        end
        LRedDotCheckMgr:RedDotItemCheck()        
    end
    --print("LUIBagEvent.BagDataChanged,pos",pos)
    LGameMsg.m_netDealMsg:Change(LUIBagEvent.BagDataChanged,pos)
    this:SendMsg(LGameMsg.m_netDealMsg)
end

function LuaNetRecvdMsg.DealMsgUnLockPackage(stream)
    local isOpen = stream:ReadByte()
    local num = stream:ReadByte()
	local success = stream:ReadByte()
	if success == 0 then	--failed
		local errMsg = stream:ReadString()
		Utils:ShowScrollTips(errMsg)
		return
    end
    --local pos = stream:ReadByte()
end

--合成
function LuaNetRecvdMsg.DealMsgSynthesis(stream)
    local op = stream:ReadByte()   
    local sucess = stream:ReadByte()
    local errMsg = ""
    if sucess == 0 then
        errMsg = stream:ReadString()
        if #errMsg > 0 then
            Utils:ShowScrollTips(errMsg)
        end
        return
    end
    if op==3 then
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIForgeEvent.SynthesisSucess)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
      return
    end
    

    if op >= 2 and op <= 5 then
        Utils:ShowScrollTips(GUITips.UI_Synthesis_Sucess)
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIBagEvent.SynthesisSucess)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
	   
    elseif op == 6 then --分解
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIBagEvent.ResolveSucess)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
    elseif op == 7 then	--附着
        --TipsMgr::GetInstance()->SetCenterTip(RES_STRC(DataConsts::RSI_GS_TIP10))
    end  
end

---- 锻造界面，请求强化信息后返回，更新强化界面
--function LuaNetRecvdMsg.DealMsgStrengthenInfo(stream)
--	local money = stream:ReadUInt()
--	local rate = stream:ReadByte()
--	local src1 = stream:ReadWord()
--	local levelup1 = stream:ReadWord()
----	local src2 = stream:ReadWord()
----	local levelup2 = stream:ReadWord()

--    --通知更新强化界面
--    LGameMsg.m_baseMsgTwo:Change(LUIForgeEvent.StrengthenInfo,rate,money)
--    this:SendMsg(LGameMsg.m_baseMsgTwo)


--end

-- 锻造界面，点击强化请求后返回
-- function LuaNetRecvdMsg.DealMsgStrengthenRes(stream)
-- 	local sucess = stream:ReadByte()
--     if sucess == 0 then
--         local errMsg = stream:ReadString()
--         Utils:ShowScrollTips(errMsg)
--         --通知更新强化界面
--         LGameMsg.m_netDealMsg:Change(LUIForgeEvent.StrengthenRefresh,levelUp)
--         this:SendMsg(LGameMsg.m_netDealMsg)
--         return
--     end
--     local levelUp = stream:ReadByte()
-- 	local msg = stream:ReadString()
--     Utils:ShowScrollTips(msg)
--     --if levelUp == 1 then
--     --通知更新强化界面
--     LGameMsg.m_netDealMsg:Change(LUIForgeEvent.StrengthenRefresh,levelUp)
--     this:SendMsg(LGameMsg.m_netDealMsg)
--     -- end

--     --音效
--     if levelUp == 1 then
--         LGameMsg.m_audioMsg:Change(LAudioEvent.PlayEffect, AppDef.SysBGM.Equip_Enhanced)
--         this:SendMsg(LGameMsg.m_audioMsg)

--         LRedDotCheckMgr:MainDuanzaoCheck()
--     end
-- end

--升阶成功
-- function LuaNetRecvdMsg.DealMsgUpgradeRes(stream)
--     local sucess = stream:ReadByte()
--     local errMsg = stream:ReadString()
--     Utils:ShowScrollTips(errMsg)
--     if sucess == 1 then
--         --通知装备升阶ＵＩ刷新
--         LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIForgeEvent.UpgradeRefresh)
--         this:SendMsg(LGameMsg.m_netDealBaseMsg)    
        
--         --音效
--         LGameMsg.m_audioMsg:Change(LAudioEvent.PlayBTEffect, AppDef.SysBGM.Equip_Upgrade)
--         this:SendMsg(LGameMsg.m_audioMsg)    

--         LRedDotCheckMgr:MainDuanzaoCheck()
--     end
-- end

--淬炼
-- function LuaNetRecvdMsg.DealMsgCuilianRes(op,stream)
-- 	if op == 3 then   -- 点击淬炼后返回
-- 		local succ = stream:ReadByte()
--         local errMsg = stream:ReadString()
--         Utils:ShowScrollTips(errMsg)
-- 		if succ == 1 then
--             --通知更新淬炼界面
--             LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIForgeEvent.QuenchRefresh)
--             this:SendMsg(LGameMsg.m_netDealBaseMsg)

--             --音效
--             LGameMsg.m_audioMsg:Change(LAudioEvent.PlayEffect, AppDef.SysBGM.Equip_Quenching)
--             this:SendMsg(LGameMsg.m_audioMsg)

--             LRedDotCheckMgr:MainDuanzaoCheck()
-- 		end
-- 	elseif op == 4 then   --查询淬炼之后属性值=QueryLianhuashiAddVal(选择炼化石或数量后，返回符文属性）
-- 		local ntype = stream:ReadByte()
-- 		local pos = stream:ReadWord()
-- 		local attrIdx = stream:ReadByte()
-- 		local itemId = stream:ReadWord()
-- 		local itemNum = stream:ReadWord()
-- 		local addVal = stream:ReadUInt()

--         --通知更新淬炼界面（符文属性）
--         LGameMsg.m_netDealMsg:Change(LUIForgeEvent.RuneAttrInfo, {ntype,pos,attrIdx,addVal})
--         this:SendMsg(LGameMsg.m_netDealMsg)
-- 	end
-- end

--洗炼
-- function LuaNetRecvdMsg.DealMsgXilianRes(op,stream)
-- 	if op == 5 then   -- 点击洗炼后返回
--         local ntype = stream:ReadByte()
-- 		local pos = stream:ReadWord()
--         local lock = stream:ReadByte()
--         local useItemId = stream:ReadWord()
-- 		local succ = stream:ReadByte()
--         if succ == 0 then
--             local errMsg = stream:ReadString()
--             Utils:ShowScrollTips(errMsg)
--             return
--         end
--         local newLock = stream:ReadByte()
--         local errMsg = stream:ReadString()
--         Utils:ShowScrollTips(errMsg)
--         --通知更新洗炼界面
--         LGameMsg.m_netDealMsg:Change(LUIForgeEvent.XiLianRefresh,newLock)
--         this:SendMsg(LGameMsg.m_netDealMsg)      

--         --音效
--         LGameMsg.m_audioMsg:Change(LAudioEvent.PlayEffect, AppDef.SysBGM.Equip_Clear)
--         this:SendMsg(LGameMsg.m_audioMsg)

--         LRedDotCheckMgr:MainDuanzaoCheck()
-- 	elseif op == 6 then   --保存属性
-- 		local ntype = stream:ReadByte()
-- 		local pos = stream:ReadWord()
-- 		local succ = stream:ReadByte()
--         local errMsg = stream:ReadString()
--         Utils:ShowScrollTips(errMsg)
--         if succ == 1 then
--             --通知更新洗炼界面
--             LGameMsg.m_netDealMsg:Change(LUIForgeEvent.XiLianRefresh)
--             this:SendMsg(LGameMsg.m_netDealMsg)
--         end
-- 	end
-- end

--锻造服务器返回
-- function LuaNetRecvdMsg.DealMsgEquipForgeRes(stream)
--     local op = stream:ReadByte()
--     if op == 1 then
--         -- 强化
--         this.DealMsgStrengthenRes(stream)
--     elseif op == 2 then
--         -- 升阶
--         this.DealMsgUpgradeRes(stream)
--     elseif op == 3 or op == 4 then
--         --淬炼
--         this.DealMsgCuilianRes(op,stream)
--     elseif op == 5 or op == 6 then
--         --洗炼
--         this.DealMsgXilianRes(op,stream)
--     end
-- end

function LuaNetRecvdMsg.DealMsgShenQi(stream)--神器
    local op = stream:ReadByte()
    if op == 1 then 
        --神器基础信息
        LRoleDataMgr.m_ServerShenQiList= {}
        local num = stream:ReadUInt()
        for i = 1, num do
            local cell = LServerShenQiList:New()
            cell.id = stream:ReadUInt()
            cell.state = stream:ReadByte()--0未获得，1休息，2使用
            if cell.state == 2 then
                if LRoleDataMgr.MyHeroInfo.ShenQiId ~= cell.id then
                    LRoleDataMgr.MyHeroInfo.ShenQiId = cell.id
                    LRoleDataMgr.MyHeroInfo:SendHeroModelChangedMsg()
                end
            end
            cell.getWay = stream:ReadByte()
            cell.itemId = stream:ReadUInt()
            cell.needNum = stream:ReadUInt()       
            table.insert(LRoleDataMgr.m_ServerShenQiList, cell)
        end
        LRoleDataMgr:SortShenQiList()
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIShenQiEvent.GotShenQiList)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
    elseif op == 3 then 
        -- 培养信息
        local old_curLv = LArtifactUIDataMgr.m_UIData["cur_level"]
        LArtifactUIDataMgr.m_UIData["cur_id"] = stream:ReadUInt()
	    LArtifactUIDataMgr.m_UIData["cur_level"] = stream:ReadUInt()
	    stream:ReadUInt()
	    LArtifactUIDataMgr.m_UIData["next_level"] = stream:ReadUInt()
	    LArtifactUIDataMgr.m_UIData["cur_star"] = stream:ReadUInt()
	    LArtifactUIDataMgr.m_UIData["cur_exp"] = stream:ReadUInt()
        if old_curLv ~=nil and old_curLv ~= LArtifactUIDataMgr.m_UIData["cur_level"] then
            --音效
            LGameMsg.m_audioMsg:Change(LAudioEvent.PlayEffect, AppDef.SysBGM.ShenQi_Upgrade)
            this:SendMsg(LGameMsg.m_audioMsg)
        end
        -- 通知刷新神器培养界面
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIShenQiEvent.ShenQiDevelopInfoChanged)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)

        -- LRedDotCheckMgr:MainArtifactCheck()
    elseif op == 4 then
        -- 获得新神器（通过碎片激活或者神器升阶等）
        local id = stream:ReadUInt()
        LRoleDataMgr:SetShenQiState(id,1)
         -- 通知神器状态改变
        LGameMsg.m_netDealMsg:Change(LUIShenQiEvent.ShenQiStateChanged,id)
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 5 then
        local oldId = LRoleDataMgr.MyHeroInfo.ShenQiId
        if oldId > 0 then
            LRoleDataMgr:SetShenQiState(oldId,1)
        end
        -- 获取以前设置跟随
        local ShenQiId = stream:ReadByte()
        LRoleDataMgr.MyHeroInfo.ShenQiId =  ShenQiId --当前跟随神器
        if ShenQiId > 0 then
            LRoleDataMgr:SetShenQiState(ShenQiId,2)
        end
        -- 通知跟随神器改变
        LGameMsg.m_netDealMsg:Change(LUIShenQiEvent.CurShenQiChanged,oldId)
        this:SendMsg(LGameMsg.m_netDealMsg)
        if oldId ~= LRoleDataMgr.MyHeroInfo.ShenQiId then
            LRoleDataMgr.MyHeroInfo:SendHeroModelChangedMsg()
        end
    elseif op == 7 then --其他人的神器信息
        local roleId = stream:ReadUInt()
        if roleId ~= LRoleDataMgr.OtherHeroInfo.id then return end
        LRoleDataMgr.m_otherShenqi= {}
        local num = stream:ReadUInt()
        for i = 1, num do
            local cell = LServerShenQiList:New()
            cell.id = stream:ReadUInt()
            cell.state = stream:ReadByte()--0未获得，1休息，2使用
            cell.getWay = stream:ReadByte()
            cell.itemId = stream:ReadUInt()
            cell.needNum = stream:ReadUInt()
            if cell.state ~= 0 then
                table.insert(LRoleDataMgr.m_otherShenqi, cell)
            end
        end

        LArtifactUIDataMgr.m_UIOtherData["cur_level"] = stream:ReadUInt()
        LArtifactUIDataMgr.m_UIOtherData["cur_star"] = stream:ReadUInt()
    end
end

--竞技场信息解析
function LuaNetRecvdMsg.DealMsgArenaInfo(stream)
    local function OkFunc()
        Utils:OpenVipUI()
    end
    local op = stream:ReadByte()
    --print("LuaNetRecvdMsg.DealMsgArenaInfo op",op)
    if op == 0 then--排名战
		local isAd = stream:ReadByte()
		local succ = stream:ReadByte()
		if succ == 0 then
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
            return
        end
        if isAd ~= 1 then
            return
        end
        LArenaDataMgr.m_modelInfos = {}
        local info = LArenaDataMgr.m_modelInfos
        LArenaDataMgr.m_toptenModelInfos = {}
        local topInfo = LArenaDataMgr.m_toptenModelInfos
		local num = stream:ReadByte()
		for i = 1 ,num do
			local warInfo = LArenaHeroInfo:New()
            warInfo.slotIndex = stream:ReadUInt()--排名
            warInfo.IdType = stream:ReadByte()--类型
            warInfo.Id = stream:ReadUInt()--id
            if warInfo.IdType == 0 then
    			warInfo.name = stream:ReadString()-- 姓名
    			warInfo.level = stream:ReadWord()--等级
                warInfo.fightpower = stream:ReadULongInt()--战斗力
                warInfo.sex = stream:ReadByte()--性别
    			warInfo.model = stream:ReadByte()--模型
                warInfo.vipLevel = stream:ReadByte()
            end
            if warInfo.slotIndex > 10 then
    			table.insert(info,warInfo)
            else
                LArenaDataMgr.m_toptenModelInfos[warInfo.slotIndex] = warInfo
            end
		end
		LArenaDataMgr.m_myRank = stream:ReadUInt() --当前排名
		LArenaDataMgr.m_cnt =  stream:ReadWord() --剩余挑战的次数
		LArenaDataMgr.m_tiaoZhCnt = stream:ReadWord() --已经挑战次数
        LArenaDataMgr.m_buyCnt = stream:ReadByte() --挑战令购买次数
		LArenaDataMgr.m_score =  stream:ReadUInt() --竞技积分
        --通知界面更新
        ------dump(LArenaDataMgr,"DealMsgArenaInfo =>")
        ----print("LArenaDataMgr.m_cnt",LArenaDataMgr.m_cnt)
   
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIArenaEvent.UpdateArenaWarInfo)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
        --dump(LArenaDataMgr.m_toptenModelInfos)
        --LRedDotCheckMgr:MainArenaCheck()
	elseif op == 2 then--英雄榜
		local succ = stream:ReadByte()
        if succ == 0 then
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
            return
        end
		LArenaDataMgr.m_rankList = {}
        --LArenaDataMgr.m_toptenModelInfos = {}
        LArenaDataMgr.m_myRank = stream:ReadUInt() --当前排名
		local num = stream:ReadByte()
        --print("op ==2 num",num,LArenaDataMgr.m_myRank)
		for i = 1,num do
			local aHero = LArenaHeroInfo:New()
            aHero.slotIndex = stream:ReadUInt()--排名
            aHero.IdType = stream:ReadByte()--类型
            aHero.Id = stream:ReadUInt()--id
            if aHero.IdType == 0 then
                aHero.name = stream:ReadString()-- 姓名
                aHero.level = stream:ReadWord()--等级
                aHero.fightpower = stream:ReadULongInt()--战斗力
                aHero.sex = stream:ReadByte()--性别
                aHero.head = stream:ReadByte()--头像
                aHero.jingjie = stream:ReadByte()
                aHero.vipLevel = stream:ReadByte()
                aHero.bangId = stream:ReadUInt()
                aHero.bangName = stream:ReadString()
            end
			table.insert(LArenaDataMgr.m_rankList,aHero)
		end
        --通知界面更新
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIArenaEvent.UpdateHeroListInfo)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
	elseif op == 3 then --记录
		local succ = stream:ReadByte()
        ----print("op == 3",succ)
		if succ == 0 then
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
            return
        end
		LArenaDataMgr.m_myrecords = {} --自己战斗记录
    	local num = stream:ReadByte()
        ----print("num",num)
    	for i = 1,num do
    		local data = LArenaRegInfo:New()
            local attacker = data.attackerInfo
            attacker.IdType = stream:ReadByte()--类型
            attacker.Id = stream:ReadUInt()
            if attacker.IdType == 0 then
                attacker.name = stream:ReadString()
                attacker.head = stream:ReadByte()
                attacker.jingjie = stream:ReadByte()
                attacker.level = stream:ReadWord()
                attacker.vipLevel = stream:ReadByte()
                attacker.fightpower = stream:ReadULongInt()
            end
            local victim = data.victimInfo
            victim.IdType = stream:ReadByte()--类型
            victim.Id = stream:ReadUInt()
            if victim.IdType == 0 then
                victim.name = stream:ReadString()
                victim.head = stream:ReadByte()
                victim.jingjie = stream:ReadByte()
                victim.level = stream:ReadWord()
                victim.vipLevel = stream:ReadByte()
                victim.fightpower = stream:ReadULongInt()
            end
            data.win = stream:ReadByte()
            data.rank = stream:ReadUInt()
            data.oldRank = stream:ReadUInt()
            ----print("rank",data.rank,data.oldRank)
            data.time = stream:ReadUInt()
            data.replayId = stream:ReadUInt()
            table.insert(LArenaDataMgr.m_myrecords,data)
        end
        ------dump(LArenaDataMgr.m_myrecords)
        --通知打开记录面板
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIArenaEvent.GetMyRecordInfo)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
    elseif op == 4 then --重新请求排行榜
        --LuaNetSendMsg:QueryArenaList(2)
        LuaNetSendMsg:QueryArenaInfo(1)
	elseif op == 5 then --挑战反馈
		local succ = stream:ReadByte()
		if succ == 1 then
            fightData = {}
            fightData.wanFaId = AppDef.EModuleID.EMID_KAPAI_WF_ARENA
            LuaNetRecvdMsg.ReadBattleResult(stream,fightData)
            --if LRoleDataMgr.m_fightResultData.win then
            --LuaNetSendMsg:QueryArenaList(2)
            LuaNetSendMsg:QueryArenaInfo(1)
            --end
		else
			local Rtype = stream:ReadByte()
			local msg = stream:ReadString()
			if Rtype == 0 then
                if #msg > 0 then
				    LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
                    this:SendMsg(LGameMsg.m_scrollTipsMsg)
                end
			else
				Utils:ShowDialogOKCancel(msg,OkFunc)
			end
		end
    elseif op == 6 then --扫荡返回
        local heroId = stream:ReadUInt()
        local suc = stream:ReadByte()
        if suc == 0 then
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
            return
        end
        LArenaDataMgr.m_sweepInfo = {}
        local cnt = stream:ReadByte()--扫荡次数
        LArenaDataMgr.m_cnt = LArenaDataMgr.m_cnt - cnt
        if LArenaDataMgr.m_cnt < 0 then
            LArenaDataMgr.m_cnt = 0
        end
        --刷新剩余次数
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIArenaEvent.UpdateTime)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)

        --print("sweep cnt",cnt,LArenaDataMgr.m_cnt)
        for i=1,cnt do
            local num = stream:ReadByte()--奖励个数
            --print("sweep reward num",num)
            local value = {}
            value.fightIndex = i
            value.itemList = {}
            for k=1,num do
                local item = LuaNetRecvdMsg.ReadCommonReward(stream)
                table.insert(value.itemList,item)
            end
            if #value.itemList > 0 then
                table.insert(LArenaDataMgr.m_sweepInfo,value)
            end
        end
        ------dump(LArenaDataMgr.m_sweepInfo)
        if #LArenaDataMgr.m_sweepInfo == 0 then
            return
        end

        local fun = function()
            --继续扫荡按钮回调
            LuaNetSendMsg:SendArenaSweepReq(heroId)
        end
        local saodang = {}
        saodang.showType = 1
        saodang.result = LArenaDataMgr.m_sweepInfo
        saodang.callback = fun
        Utils:InitUI("FuBenMap.SaoDangResultUI", AppDef.UIType.PopWindow,saodang)
    elseif op == 7 then--查询竞技场机器人信息
        local robotinfo = {}
        robotinfo.id = stream:ReadUInt()
        robotinfo.zhengfaId = stream:ReadByte()
        robotinfo.zhengfaLv = stream:ReadByte()
        robotinfo.isRole = false
        local num = stream:ReadByte()
        robotinfo.zhengfaData = {}
        for i = 1,num do
            table.insert(robotinfo.zhengfaData, stream:ReadUInt())
        end
        --dump(robotinfo, "==========arena zhenfa============>>>>>>>")
        LGameMsg.m_netDealMsg:Change(LUIKunLunEvent.GetRobotZhenFaInfo, robotinfo)
        this:SendMsg(LGameMsg.m_netDealMsg)
	elseif op == 13 then 
        local time = stream:ReadByte()
        LArenaDataMgr.m_cnt = time
        --刷新剩余次数
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIArenaEvent.UpdateTime)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
        --LRedDotCheckMgr:MainArenaCheck()
	elseif op == 16 then
        --local succ = stream:ReadByte()
        LArenaDataMgr.m_records = {} --前十的战斗记录
        local num = stream:ReadByte()
        ----print("op == 16",num)
        for i = 1,num do
            local data = LArenaRegInfo:New()
            local attacker = data.attackerInfo
            attacker.IdType = stream:ReadByte()--类型
            attacker.Id = stream:ReadUInt()
            if attacker.IdType == 0 then
                attacker.name = stream:ReadString()
                attacker.head = stream:ReadByte()
                attacker.jingjie = stream:ReadByte()
                attacker.level = stream:ReadWord()
                attacker.vipLevel = stream:ReadByte()
                attacker.fightpower = stream:ReadULongInt()
            end
            local victim = data.victimInfo
            victim.IdType = stream:ReadByte()--类型
            victim.Id = stream:ReadUInt()
            if victim.IdType == 0 then
                victim.name = stream:ReadString()
                victim.head = stream:ReadByte()
                victim.jingjie = stream:ReadByte()
                victim.level = stream:ReadWord()
                victim.vipLevel = stream:ReadByte()
                victim.fightpower = stream:ReadULongInt()
            end
            data.win = stream:ReadByte()
            data.rank = stream:ReadUInt()
            data.oldRank = stream:ReadUInt()
            data.time = stream:ReadUInt()
            data.replayId = stream:ReadUInt()
            table.insert(LArenaDataMgr.m_records,data)
        end
       -- ----dump(LArenaDataMgr.m_records)
        -- 通知打开记录面板
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIArenaEvent.OpenRecordUI)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
    end
end

--玩法数据
function LuaNetRecvdMsg.DealMsgActivityList(stream)
    local taskList = LActivityManager.m_pActivityDataBuff
    local msgStr = ""
    local op = stream:ReadByte()
    if op == 1 then
        LActivityManager.m_pActivityDataBuff =  {}
        msgStr = stream:ReadString() --总的字符串
        local index = 1
        local strList = string.split(msgStr,'|')
        local boxInfo = LActivityManager:GetBoxInfo()
        boxInfo.m_activeVal = tonumber(strList[index]) --活跃度值
        if boxInfo.m_activeVal > 100 then 
            boxInfo.m_activeVal = 100
        end
        index = index +1

        local box={}
        for i=1,4 do  --宝箱状态 未开启 已开启
            box[i] = tonumber(strList[index]) 
            index = index +1
        end

        local num = tonumber(strList[index]) --活动数目
        index = index +1

        for i = 1,num do
            local info = LActivityData:new()
            info.id = tonumber(strList[index]) 
            index = index +1
            info.name = strList[index]
            index = index +1
            info.target = strList[index] 
            index = index +1
            info.finishState = strList[index]
            index = index +1
            local temp = string.split(info.finishState,'/')
            local min = tonumber(temp[1]) or 0
            local max = tonumber(temp[2])
            if max == 0 then max = 1 end
            info.finishrate = min/max
            --local leftTimes = 0
            --if max > min then leftTimes = max - min end
            --info.finishState = tostring(leftTimes)
--            if leftTimes > 0 then
--                return
--            end

            info.activeVal =  strList[index]
            index = index +1
            info.state = tonumber(strList[index])
            index = index +1
            info.stateinfo = strList[index]
            index = index +1
            info.instruction = strList[index]
            index = index +1
            info.openLv = tonumber(strList[index])
            index = index +1
            info.opentime = strList[index]
            index = index +1
            str = strList[index]
            index = index +1

            info.RevardId = string.split(str,',')
            info.overCost = tonumber(strList[index])
            index = index +1
            info.startLev = tonumber(strList[index])
            index = index +1
            info.oneKeyOpenLev = tonumber(strList[index]) --一键完成人物等级限制
            index = index +1

			--增加两个字段:扫荡标记，扫荡次数
            info.saodangMark = tonumber(strList[index]) --扫荡标记
            index = index +1
            info.canSaodangTimes = tonumber(strList[index]) 
            index = index +1
            info.gotoPrivilegeCard = tonumber(strList[index]) 
            index = index +1
            str = strList[index] 
            index = index +1
            info.isFinished = tonumber(str) == 1
            local typeList = string.split(strList[index],",")
            info.types = {}
            for i = 1,#typeList do
                table.insert(info.types,tonumber(typeList[i])) 
            end
            index = index +1    
            table.insert(LActivityManager.m_pActivityDataBuff,info)
        end
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIActivityEvent.RefreshPage)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
        if Utils.m_wanfaId ~= nil and Utils.m_wanfaId > 0 then
             LGameMsg.m_netDealMsg:Change(LUIActivityEvent.ClickActivity, Utils.m_wanfaId)
             this:SendMsg(LGameMsg.m_netDealMsg)
             Utils.m_wanfaId = 0
        end
    elseif op == 2 then
        local  succ = stream:ReadByte()
        if succ == 0 then
            return
        end
        --活动奖励配置
        local boxConfig = LActivityManager:GetBoxConfig()
        local boxInfo = LActivityManager:GetBoxInfo()
        boxConfig.m_count = stream:ReadUInt()
        if boxConfig.m_count > 5 then
            boxConfig.m_count = 5
        end
        boxConfig.m_itemIdNums = {}
        for i=1,boxConfig.m_count  do
            boxInfo.m_states[i] = stream:ReadByte() --0 未领奖 1 领奖 
            boxConfig.m_activeVals[i] = stream:ReadUInt()
            local items = boxConfig.m_itemIdNums
            if items[i] == nil then
                items[i] = {}
            end
            local num = stream:ReadUInt()
            for k=1,num do
                local itemValue = {["itemId"] = 0,["itemNum"] = 0}
                itemValue.itemId = stream:ReadUInt()
                itemValue.itemNum = stream:ReadUInt()
                table.insert(items[i],itemValue)
            end
        end
        -- LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIActivityEvent.ShowBox)
        -- this:SendMsg(LGameMsg.m_netDealBaseMsg)
        --LRedDotCheckMgr:MainActivityCheck()
    elseif op == 3 then
        local  succ = stream:ReadByte()
        if succ == 0 then
            return
        end
        LuaNetSendMsg:QueryDailyActivityList(2)
    end
end

function LuaNetRecvdMsg.DealMsgTaskInfo(stream)--任务面板任务解析
    local op = stream:ReadByte()
    -- print("DealMsgTaskInfo ===> op", op)
    --op == 4 七日任务
    if op == 1 then
        local taskType = stream:ReadByte() --活动列型
        -- print("taskType",taskType)
        local taskArr = {}
        local num = stream:ReadWord()
        -- --print("num",num)
        for i = 1, num do
            local taskdata = {}
            taskdata.task_id = stream:ReadWord()
            taskdata.taskActiveNum = stream:ReadUInt()
            taskdata.state = stream:ReadByte()--0未完成 1完成 2已领奖
            table.insert(taskArr, taskdata)
        end
        if taskType == 2 then
            Utils:SendMsg(LUITaskDataEvent.GotDailyTaskInfo,taskArr)
        elseif taskType == 0 then
            Utils:SendMsg(LUITaskDataEvent.GotDailyRewardInfo,taskArr)
        else
            LGameMsg.m_netDealMsg:Change(LUITaskDataEvent.WanFaDailyTaskInfo,{taskType,taskArr})
            this:SendMsg(LGameMsg.m_netDealMsg)
        end
    elseif op == 4 then
        local taskgot = LRoleDataMgr.Task:GetTaskTrackData()
        local num = stream:ReadWord()
        LRoleDataMgr.Task.m_finishNum = 0 --完成的数量
        for i = 1, num do
            local taskdata = LCardTaskData:New()
            taskdata.task_id = stream:ReadWord()
            taskdata.taskActiveNum = stream:ReadUInt()
            taskdata.state = stream:ReadByte()
            taskgot[taskdata.task_id] = taskdata
            -- table.insert(taskgot, taskdata)
            if taskdata.state > 0 then
                LRoleDataMgr.Task.m_finishNum = LRoleDataMgr.Task.m_finishNum + 1
            end
        end

        -- dump(taskgot, "GetTaskTrackData ===>")
        Utils:SendMsg(LUITaskDataEvent.GotTaskInfo)
    elseif op == 2 then
        --任务更新
        local taskArr = {}
        local taskdata = {}
        taskdata.task_id = stream:ReadWord()
        taskdata.taskActiveNum = stream:ReadUInt()
        taskdata.state = stream:ReadByte()
        --dump(taskdata,"taskdata")
        table.insert(taskArr,taskdata)
        Utils:SendMsg(LUITaskDataEvent.DailyTaskUpdate,taskArr)
    elseif op == 3 then
        --领取奖励
        local taskType = stream:ReadByte()
        local id =  stream:ReadWord();
        local sucess = stream:ReadByte();
        if sucess == 0 then
            local msg = stream:ReadString();
            Utils:ShowScrollTips(msg);
            return
        end
        local unlockNum = stream:ReadByte();
        --print("lockNum",unlockNum)
        local taskArr = {}
        for i = 1, unlockNum do
            local id = stream:ReadWord()
            --print("id",id)
            if id > 0 then
                local taskdata = {}
                taskdata.task_id = id
                taskdata.taskActiveNum = stream:ReadUInt()

                taskdata.state = stream:ReadByte()--0未完成 1完成 2已领奖
                table.insert(taskArr, taskdata)
                --print("id",id, "taskdata.taskActiveNum",taskdata.taskActiveNum,"taskdata.state",taskdata.state)
            end
        end
        
        this.ReadRewards(stream)

        if taskType == 2 or taskType == 0 then
            Utils:SendMsg(LUITaskDataEvent.GotDailyTaskReward,id)
        else
            LGameMsg.m_netDealMsg:Change(LUITaskDataEvent.WanFaDailyTaskReward,{taskType,id,taskArr})
            this:SendMsg(LGameMsg.m_netDealMsg)
        end

        if taskType == 2 then
            Utils:SendMsg(LUITaskDataEvent.DailyTaskUpdate,taskArr)
        end

    elseif op == 5 then
        --数量更新
        local taskdata = LCardTaskData:New()
        taskdata.task_id = stream:ReadWord()
        taskdata.taskActiveNum = stream:ReadUInt()
        taskdata.state = stream:ReadByte()

        --print("taskId == 1111 >", taskdata.task_id, taskdata.state, taskdata.taskActiveNum)
        if taskdata.state == 2 then
            local taskFinish = LRoleDataMgr.Task:GetCompleteTaskData()
            table.insert(taskFinish, taskdata.task_id)
        else
            local taskgot = LRoleDataMgr.Task:GetTaskTrackData()
            taskgot[taskdata.task_id] = taskdata
        end

        if taskdata.state > 1 then
            LRoleDataMgr.Task.m_finishNum = LRoleDataMgr.Task.m_finishNum + 1
        end
        
        -- Utils:SendMsg(LUITaskDataEvent.GotTaskInfo)
    elseif op == 6 then
        --领取
        local finishID = stream:ReadWord()
        local errorCode = stream:ReadByte()
        if errorCode > 0 then
            -- print("GetTaskTrackData finishID ===>", finishID)
            local taskgot = LRoleDataMgr.Task:GetTaskTrackData()
            taskgot[finishID].state = 2

            Utils:SendMsg(LUITaskDataEvent.updateQiRiUIAfterAward, finishID)
        else
            Utils:ShowScrollTips(stream:ReadString())
        end
    end

end

function LuaNetRecvdMsg.ReadRewards(stream)
    local num = stream:ReadByte();
    --print("num",num)
    local itemArr = {}
    for i = 1, num do
        -- local itemType = stream:ReadWord();
        -- local itemNum = stream:ReadUInt();

        -- if itemType == 60028 then
        --     table.insert(itemArr,{itemType,stream:ReadUInt(),itemNum});
        -- else
        --     table.insert(itemArr,{itemType,0,itemNum});
        -- end
        local arr = LuaNetRecvdMsg.ReadCommonReward(stream)
        table.insert(itemArr,arr);
        --print("itemType",itemType,"itemNum",itemNum)
    end
    Utils:OpenRewardBox(GUITips.RSI_BOX_TIP2,itemArr,false,"",nil,nil);
end

-----------------------------羽翼解析从这里开始------------------------------------------------
--[[
翅膀羽翼
]]
function LuaNetRecvdMsg.DealMsgChiBangInfo(stream)--翅膀羽翼解析
    local OtInfo = LRoleDataMgr.MyHeroInfo.ChiBangExInfo
    local op = stream:ReadByte()
    
    if op == 1 then --我的翅膀列表
        this.DealGetAlreadyGetWings(stream, OtInfo)
    elseif op == 2 then --强化(培养）成功失败
        this.DealAfterUpgradeWings(stream, OtInfo)
    elseif op == 3 then --设置翅膀状态
        this.DealSetWings(stream, OtInfo)
    -- elseif op == 4 then --获取所有翅膀列表
    --     this.DealGetAllWings(stream, OtInfo)
    elseif op == 5 then --购买（兑换）翅膀
        this.DealAlwaysBuyWing(stream, OtInfo)
    -- elseif op == 6 then --请求翅膀强化信息
    --     this.DealGetWingUpgrade(stream, OtInfo)
    elseif op == 7 then --其他角色翅膀信息
        this.DealOtherRoleWings(stream)
    elseif op == 8 then--获得翅膀（任务等）
        local wingId = stream:ReadByte()
        if wingId > 0 and wingId < 0xff then
            LGameMsg.m_netDealMsg:Change(LUIWingDataEvent.GotNewWing, wingId)
            this:SendMsg(LGameMsg.m_netDealMsg)
        end
    end
end

--[[
处理已获得翅膀羽翼信息 1
]]
function LuaNetRecvdMsg.DealGetAlreadyGetWings(stream, OtInfo)

end

--[[
强化(培养）成功失败 2
]]
function LuaNetRecvdMsg.DealAfterUpgradeWings(stream, OtInfo)

end

--[[
设置翅膀状态 3
]]
function LuaNetRecvdMsg.DealSetWings(stream, OtInfo)

end

--[[
购买（兑换）翅膀 5
]]
function LuaNetRecvdMsg.DealAlwaysBuyWing(stream, OtInfo)

end

--[[
其他角色翅膀信息 7
]]
function LuaNetRecvdMsg.DealOtherRoleWings(stream)
end
-----------------------------羽翼解析到这里结束------------------------------------------------


function LuaNetRecvdMsg.DealMsgUpdateEquip(stream)
    local pos = stream:ReadByte() + 1
    LuaNetRecvdMsg.ReadItemData(LRoleDataMgr.MyHeroInfo.EquipList[pos],stream)
    --unsigned char type = stream:ReadByte()
    LRoleDataMgr:GetEquipList(true) 
end

function LuaNetRecvdMsg.DealMsgUpdateEquipItem(stream)
    local op = stream:ReadByte()
    local equipPos = stream:ReadByte() + 1--服务器下标从0开始，lua默认从1开始
    
   
    if op == 0 then -- 卸下
        
        local isSucess = stream:ReadByte()
        if isSucess == 1 then
            local packagePos = stream:ReadByte()

            LGameMsg.m_netDealMsg:Change(LUIRoleEquipChangeEvent.UnEquip,equipPos)
            this:SendMsg(LGameMsg.m_netDealMsg)
        else
            local msg =stream:ReadString()
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
            this:SendMsg(LGameMsg.m_scrollTipsMsg)
        end
    elseif op == 1 then--装备
        
        local packagePos = stream:ReadByte()
        local isSucess = stream:ReadByte()
        if isSucess == 1 then
            LGameMsg.m_netDealMsg:Change(LUIRoleEquipChangeEvent.Equiped,equipPos)
            this:SendMsg(LGameMsg.m_netDealMsg)
            --音效
            LGameMsg.m_audioMsg:Change(LAudioEvent.PlayBTEffect, AppDef.SysBGM.Equip_Wear)
            this:SendMsg(LGameMsg.m_audioMsg)
        else
            local msg =stream:ReadString()
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
            this:SendMsg(LGameMsg.m_scrollTipsMsg)
        end
    end
    if equipPos == 5 then
        LRoleDataMgr.MyHeroInfo:SendHeroModelChangedMsg()
    end
    return -1
end

function LuaNetRecvdMsg.DealMsgUnGetTaskInfo(stream)
    
    local op = stream:ReadByte()
    --面板可接任务
    if op == 1 then
    elseif op == 2 then--任务追踪可接任务信息
        local num = stream:ReadByte()
        local pTaskNotGet = LRoleDataMgr.Task:GetUngetTasksAndReset()
        for i = 1, num do
            local taskdata = LTaskTrackData:New()
            taskdata.op = 0--初始化op
            taskdata.task_id = stream:ReadWord()
            taskdata.taskType = stream:ReadByte()
            taskdata.getState = 0
            taskdata.name = stream:ReadString()
            taskdata.info = stream:ReadString()
            local path = stream:ReadString()
            taskdata:SetTrackData(path)
            table.insert(pTaskNotGet,taskdata)
        end
    elseif op == 3 then
        --任务追踪特殊任务
        --local pSpecialTask = LRoleDataMgr.Task:GetSpecialTasksAndReset()
        
        local task_id = stream:ReadWord()
        local taskData = LRoleDataMgr.Task:AddSpecialTaskById(task_id)
        local taskType = stream:ReadByte()
        local taskName = stream:ReadString()

        if string.len(taskName) == 0 then
            --发送重新加载任务追踪的消息
			------print("---------------------单次任务结束---------------------")
			LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, false)
			this:SendMsg(LGameMsg.m_baseMsgWithOne)
            return 3
        end
        --local taskData = LTaskTrackData:New()
        --必定是主角达到**级之类的任务，写死打开UI
        taskData.op = 2
        taskData.opVal = 10

        taskData.task_id = task_id
        taskData.taskType = taskType
        taskData.getState = 2
        taskData.name = taskName
        taskData.info = stream:ReadString()
        
        local off               = 1
        local _end              = 0
        local path              = stream:ReadString()
              _end              = string.find(path , ",")
        local temp              = tonumber(string.sub(path , off , _end - 1 ))
        if temp == nil then
            taskData.state      = 2
            off                 = _end + 1
            _end                = string.len(path)
            --taskData.popLayerIdx= tonumber(string.sub(path , off , _end))
        end
        --table.insert(pSpecialTask,taskdata)
        LGameMsg.m_netDealMsg:Change(LUITaskDataEvent.GotTaskInfo,task_id)
        this:SendMsg(LGameMsg.m_netDealMsg)
    --优化服务器响应速度，可接任务分成列表和任务详细信息2步
    elseif  op == 4 then--可接任务列表,收到列表，请求单个任务详细信息
        local num = stream:ReadByte()
        local pTaskNotGet = LRoleDataMgr.Task:GetUngetTasksAndReset()
        for i = 1, num do
            local taskdata = LTaskTrackData:New()
            taskdata.op = 0
            taskdata.task_id = stream:ReadWord()
            table.insert(pTaskNotGet,taskdata)
            LuaNetSendMsg:QueryUnGetTaskInfo(taskdata.task_id)
        end
    elseif op == 5 then--可接任务信息
        local task_id = stream:ReadWord()
        local pTaskNotGet = LRoleDataMgr.Task:FindUngetTaskData(task_id)
        if pTaskNotGet == nil then
            return 0
        end
        pTaskNotGet.taskType = stream:ReadByte()
        pTaskNotGet.name = stream:ReadString()
        pTaskNotGet.info = stream:ReadString()

        local path = stream:ReadString()
        pTaskNotGet:SetTrackData(path)

        LGameMsg.m_netDealMsg:Change(LUITaskDataEvent.GotTaskInfo,task_id)
        this:SendMsg(LGameMsg.m_netDealMsg)
    end
    return op
end

function LuaNetRecvdMsg.DealMsgUpdatePet(stream)
    local petId = stream:ReadWord()
    local petData = LRoleDataMgr.Pet:GetPetById(petId)
    if petData == nil then
        return
    end
    local num = stream:ReadWord()
    for i = 1, num do
        local op = stream:ReadUInt()
        --print("LuaNetRecvdMsg.DealMsgUpdatePet",petId,op)
        local val = 0
        if op == 507 or op == 4 then
            val = stream:ReadULongInt()
        else
            val = stream:ReadUInt()
        end
        if op < 500 then--

            if op >= AppDef.EAttrType.EAT_HIT_RATE then
                petData.attrs[op] = val / 100
            else
                petData.attrs[op] = val
            end
        elseif op == 503 then--hp
            --myInfo.DetailData.hp = val
        elseif op == 507 then--战斗力
            --petData.zhandouli = val - petData.zhandouli
            petData.zhandouli = val
            -- myInfo.MyPowerUpdate = val - myInfo.zhanDouLi
            -- myInfo.zhanDouLi = val
            -- if myInfo.MyPowerUpdate ~= 0 then
            --     LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIRoleDataChangeEvent.PowerChanged)
            --     this:SendMsg(LGameMsg.m_netDealBaseMsg)
            -- end            
        end
    end
    LGameMsg.m_netDealMsg:Change(LUIPetEvent.PetDataChanged, pid)
    this:SendMsg(LGameMsg.m_netDealMsg)
end

function LuaNetRecvdMsg.DealMsgUpdateChar(stream)
    ------
    local PlayMoneyMuicEffect = false           --播放获得物品音效

    local myInfo = LRoleDataMgr.MyHeroInfo
    local heroSkill = LRoleDataMgr.HeroSkills
    local utype = stream:ReadByte()

    --print("LuaNetRecvdMsg.DealMsgUpdateChar type",utype)
    if utype == 1 then
        local num = stream:ReadWord()
        --print("num",num)
        local isAttrChanged = false
        for i = 1, num do
            local op = stream:ReadUInt()
            local val = 0
            if op == 507 or op == 513 then
                val = stream:ReadULongInt()
            else
                val = stream:ReadUInt()
            end
            --print("op val",op,val)
            if op < 500 then--
                if op >= AppDef.EAttrType.EAT_HIT_RATE then
                    myInfo.DetailData.attrs[op] = val / 100
                else
                    myInfo.DetailData.attrs[op] = val
                end
                isAttrChanged = true
            elseif op == 501 then--潜能
                if val > myInfo.DetailData.potential then
                    PlayMoneyMuicEffect = true

                    local flyItem = LFlyItem:New(LFlyItem.FlyType.Qianneng,val)
                    LGameMsg.m_netDealMsg:Change(LUILogicEvent.ShowFlyItems,flyItem)
                    this:SendMsg(LGameMsg.m_netDealMsg)
                    --BT_PARAMS.EndGifts.Qianneng = val
                end

                myInfo.DetailData:setPotential(val)
                LGameMsg.m_netDealMsg:Change(LUILogicEvent.RedDotMoneyCheck)
                this:SendMsg(LGameMsg.m_netDealMsg)
            elseif op == 502 then--exp
                myInfo.DetailData.exp = myInfo.DetailData.exp + val
                -- if (!gameLayer->GetBattleLayer())
                --     SoundMgr::GetInstance()->PlayEffect(Game_EffJinYanHuoDe)-- 经验音效

                if myInfo.DetailData.exp >= LDataConstMgr:GetHeroLevelUpExp(myInfo.level) then
                    myInfo.DetailData.exp = myInfo.DetailData.exp - LDataConstMgr:GetHeroLevelUpExp(myInfo.level)
                    myInfo.level = myInfo.level + 1


                    
                    GameSdk:U8SendInfo(4, myInfo.serverId, myInfo.id, myInfo.name)
                    local thLevel = myInfo.level

                    -- LuaNetSendMsg:QueryUnGetTaskList(4)--升级时请求一次可接任务追踪列表

                    --升级时更新副本次数
                    if thLevel >= AppDef.LevelLimit.Copy then
                        LuaNetSendMsg:QueryCopy(13)
                    end
                    
                    --功能推送先不做
                    -- if(DataConsts::GetLimitLevel(RES_STR(DataConsts::RSI_LVL_TIP4)) == thLevel)
                    --     FP_BYIDX(PT_EQUIPUP)

                    --if(GameMenu* mainmenu = GAMELAYER->GetMainMenuLayer()){ mainmenu->TurnOnButtonByLevel(thLevel) }

                    Utils:SendMsg(LUIRoleDataChangeEvent.LvUp, val, true)

                    if LRoleDataMgr.isInBattle then
                        LRoleDataMgr.isShowLvUp = true;
                        LRoleDataMgr.lvUpAddTili = 20;
                        local tili = LRoleDataMgr.MyHeroInfo:GetDetailData():getTili() + LRoleDataMgr.lvUpAddTili;
                        if tili > 500 then
                            LRoleDataMgr.lvUpAddTili = 500 - LRoleDataMgr.MyHeroInfo:GetDetailData():getTili();
                        end
                    else
                        LRoleDataMgr.isShowLvUp = false;
                        LRoleDataMgr.lvUpAddTili = 20;
                        local tili = LRoleDataMgr.MyHeroInfo:GetDetailData():getTili() + LRoleDataMgr.lvUpAddTili;
                        if tili > 500 then
                            LRoleDataMgr.lvUpAddTili = 500 - LRoleDataMgr.MyHeroInfo:GetDetailData():getTili();
                        end
                        Utils:OpenFunction(AppDef.EModuleID.EMID_LVUP)
                    end
                end
                --Utils:SendMsg(LUIRoleDataChangeEvent.ExpChanged, val, true)
                Utils:SendMsg(LUIRoleDataChangeEvent.ExpChanged)
            elseif op == 503 then--hp
                myInfo.DetailData.hp = val
            elseif op == 504 then--金币
                local isInHighCangBaoTu = LRoleDataMgr.IsInHighTreasuer
                local isShowRandPetUI = LRoleDataMgr.m_isShowRandPetUI
                if val > myInfo.DetailData.Money and not isInHighCangBaoTu and not isShowRandPetUI then
                    --BT_PARAMS.EndGifts.Money = val-myInfo.DetailData.Money
                    local flyItem = LFlyItem:New(LFlyItem.FlyType.Money,val)
                    if LRoleDataMgr:GetDelayShowAward() then
                        LRoleDataMgr:InsertDelayAwardData(1, flyItem)
                    else
                        LGameMsg.m_netDealMsg:Change(LUILogicEvent.ShowFlyItems,flyItem)
                        this:SendMsg(LGameMsg.m_netDealMsg)
                    end
                end

                myInfo.DetailData:setMoney(val) --非绑金
                --print("=========================================================>>>")
                LGameMsg.m_netDealMsg:Change(LUILogicEvent.RedDotMoneyCheck)
                this:SendMsg(LGameMsg.m_netDealMsg)
            elseif op == 505 or op == 506 then--元宝
                if val - myInfo.DetailData.TongBao > 0 then
                    PlayMoneyMuicEffect = true
                end

                -- myInfo.DetailData.TongBao = val
                --print("myInfo.DetailData.TongBao ===", myInfo.DetailData.TongBao)
                myInfo.DetailData:setTongBao(val)
                --首充、次充红点
                local state1 = LRoleDataMgr.m_firstRechargeState
                local state2 = LRoleDataMgr.m_secondRechargeState
                if state1 == 0 then
                    LuaNetSendMsg:QueryKaifuHuodong(9,2)
                elseif state2 == 0 then
                    LuaNetSendMsg:QueryKaifuHuodong(42,2)
                end
                
                if PlayMoneyMuicEffect == true then
                    --七日充值
                    LuaNetSendMsg:QuerySevenChargeInfo(35, 1)
                    --充值送礼红点
                    LuaNetSendMsg:QueryTotalCost(20, 0)
                else
                    --消费送礼红点
                    LuaNetSendMsg:QueryTotalCost(21, 0)
                end

            -- elseif op == 506 then--绑定元宝
            --     if val - myInfo.DetailData.BindTongBao > 0 then
            --         PlayMoneyMuicEffect = true
            --     end

            --     -- myInfo.DetailData.BindTongBao = val
            --     myInfo.DetailData:setBindTongBao(val)
            elseif op == 507 then--战斗力
                -- myInfo.MyPowerUpdate = val - myInfo.zhanDouLi
                -- myInfo.zhanDouLi = val
                -- if myInfo.MyPowerUpdate ~= 0 then
                --     LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIRoleDataChangeEvent.PowerChanged)
                --     this:SendMsg(LGameMsg.m_netDealBaseMsg)
                -- end
            elseif op == 508 then--新开启格子数
                local preOpenNum = val - myInfo.packageOpenNum
                myInfo.packageOpenNum = val
                LGameMsg.m_netDealMsg:Change(LUIBagEvent.BagUnLock,preOpenNum)
                this:SendMsg(LGameMsg.m_netDealMsg)
            elseif op == 509 then--下一个背包格子开启时间
                myInfo.nextOpenPackageTime = val
                LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIBagEvent.RefreshUnLockTime)
                this:SendMsg(LGameMsg.m_netDealBaseMsg)
            elseif op == 510 then--竞技场积分
                -- myInfo.MyPowerUpdate = val - myInfo.zhanDouLi
                -- myInfo.zhanDouLi = val
                -- if myInfo.MyPowerUpdate ~= 0 then
                --     LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIRoleDataChangeEvent.PowerChanged)
                --     this:SendMsg(LGameMsg.m_netDealBaseMsg)
                -- end
            elseif op == 511 then--武器特效
                if myInfo.LightEffect ~= val then
                    local oldValue = myInfo.LightEffect
                    myInfo.LightEffect = val
                    if oldValue ~= myInfo.LightEffect then
                    --更新角色光效
                        LRoleDataMgr.MyHeroInfo:SendHeroModelChangedMsg()
                    end
                end
            elseif op == 512 then--护送
                --0正常1护送2押镖
                if val == 1 then
                    myInfo.ConvoyType = 1
                    -- gameLayer->GetGameMap()->AddConvoyFollow(myInfo.m_Convoy,myInfo.ConvoyType)
                    -- gameLayer->GetMainMenuLayer()->TurnOnAutoYunshouButton(true)
                    LRoleDataMgr.MyHeroInfo:SendHeroConvoyChangedMsg()
                else
                    myInfo.ConvoyType = 0
                    myInfo.m_Convoy.Quality = 255
                    myInfo.IsAutoYunShou = true
                    LRoleDataMgr.MyHeroInfo:SendHeroConvoyChangedMsg()
                    -- gameLayer->GetGameMap()->DelConvoyFollow(myInfo.m_Convoy)
                    -- gameLayer->GetMainMenuLayer()->TurnOnAutoYunshouButton(false)
                end
            elseif op == 513 then--总战斗力
                myInfo.MyPowerUpdate = val - myInfo.zhanDouLiInAll
                myInfo.zhanDouLiInAll = val
                ----print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 513",myInfo.zhanDouLiInAll)
                if myInfo.MyPowerUpdate ~= 0 then
                    LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIRoleDataChangeEvent.PowerChanged)
                    this:SendMsg(LGameMsg.m_netDealBaseMsg)

                    LGameMsg.m_netDealMsg:Change(LUILogicEvent.ShowPowerChangeEffect,{myInfo.zhanDouLiInAll, myInfo.MyPowerUpdate})
                    this:SendMsg(LGameMsg.m_netDealMsg)
                end
            elseif op == 514 then--神魂
                myInfo.DetailData:setShenHun(val)
            elseif op == 515 then
                --更新魅力值
                LRoleDataMgr.MyHeroInfo.meili = val
                LGameMsg.m_netDealMsg:Change(LUIGiveGiftEvent.updateMeili)
                this:SendMsg(LGameMsg.m_netDealMsg)
            elseif op == 516 then--擂台积分
                myInfo.DetailData:setCompeteScore(val)
            elseif op == 517 then
    --            ----print("DealMsgUpdateChar", val)
                -- local myJingHua = LRoleDataMgr.MyHeroInfo:GetDetailData():GetXinXiuJingHua()
                -- --print("DealMsgUpdateHeroSkill myJingHua", myJingHua, val)
                -- if myJingHua ~= val and val > myJingHua then
                --     local flyItem = LFlyItem:New(LFlyItem.FlyType.XinXiuJingHua, val)
                --     LGameMsg.m_netDealMsg:Change(LUILogicEvent.ShowFlyItems, flyItem)
                --     this:SendMsg(LGameMsg.m_netDealMsg)
                -- end
                -- myInfo.DetailData:setXinXiuJingHua(val)
            end
        end

        if isAttrChanged then
            LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIRoleDataChangeEvent.AttrChanged)
            this:SendMsg(LGameMsg.m_netDealBaseMsg)
            
        end
    elseif utype == 2 then --金钱更新
        local id = stream:ReadWord()
        local val = stream:ReadUInt()
        print("update money",id,val)
        if id == AppDef.SpecialItemId.JinjiCnt then
            LArenaDataMgr.m_cnt = val
            --刷新剩余次数
            LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIArenaEvent.UpdateTime)
            this:SendMsg(LGameMsg.m_netDealBaseMsg)
        else
            LRoleDataMgr:SetMoney(id,val)
        end
    elseif utype==3 then  --更新宠物经验
        local num = stream:ReadByte()
        --print("更新宠物经验",num)
        for i=1,num do
            local petId = stream:ReadWord()
            --print("petId",petId)
            local exps = stream:ReadUInt()
            local Data = LRoleDataMgr.Pet:GetPetById(petId)
            if Data then
                Data.exp=exps
                --print("打印宠经验信息",exps, Data.exp)
            end
        end
    end

    -- if(AddBandMoney || AddQiannengOrMoney)
    --     gameLayer->StartGetItemOrMoneyCheck()

    -- if(PlayMoneyMuicEffect && !gameLayer->GetBattleLayer())
    --     SoundMgr::GetInstance()->PlayEffect(Game_EffJinQianHuoDe)
    
    -- local attrType = stream:ReadByte()
    -- local val = stream:ReadUInt()
    -- if op < 500 then--
    -- end
    -- if attrType == 6 then
    --     if val > myInfo.DetailData.potential then
    --         PlayMoneyMuicEffect = true

    --         local flyItem = LFlyItem:New(LFlyItem.FlyType.Qianneng,val)
    --         LGameMsg.m_netDealMsg:Change(LUILogicEvent.ShowFlyItems,flyItem)
    --         this:SendMsg(LGameMsg.m_netDealMsg)
    --         --BT_PARAMS.EndGifts.Qianneng = val
    --     end

    --     myInfo.DetailData.potential = val -- 潜能

    --     AddQiannengOrMoney = true
    -- elseif attrType == 8 then
    --     if op == 1 then
    --         myInfo.DetailData.exp = myInfo.DetailData.exp + val

    --         -- if (!gameLayer->GetBattleLayer())
    --         --     SoundMgr::GetInstance()->PlayEffect(Game_EffJinYanHuoDe)-- 经验音效

    --         if myInfo.DetailData.exp >= LDataConstMgr:GetHeroLevelUpExp(myInfo.level) then
    --             myInfo.DetailData.exp = myInfo.DetailData.exp + LDataConstMgr:GetHeroLevelUpExp(myInfo.level)
    --             myInfo.level = myInfo.level + 1
    --             local thLevel = myInfo.level
    
    --             AddQiannengOrMoney = true
    --             LuaNetSendMsg:QueryUnGetTaskList(4)--升级时请求一次可接任务追踪列表

    --             --升级时更新副本次数
    --             if thLevel >= AppDef.LevelLimit.Copy then
    --                 LuaNetSendMsg:QueryCopy(13)
    --             end
                
    --             --功能推送先不做
    --             -- if(DataConsts::GetLimitLevel(RES_STR(DataConsts::RSI_LVL_TIP4)) == thLevel)
    --             --     FP_BYIDX(PT_EQUIPUP)

    --             --if(GameMenu* mainmenu = GAMELAYER->GetMainMenuLayer()){ mainmenu->TurnOnButtonByLevel(thLevel) }

    --             LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIRoleDataChangeEvent.LvUp)
    --             this:SendMsg(LGameMsg.m_netDealBaseMsg)
    --         end
    --         LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIRoleDataChangeEvent.ExpChanged)
    --         this:SendMsg(LGameMsg.m_netDealBaseMsg)
    --     end
    -- elseif attrType == 9 then
    --     myInfo.DetailData.hp = val
    -- elseif attrType == 10 then
    --     myInfo.DetailData.attrs [AppDef.EAttrType.EAT_HP] = val
    -- elseif attrType == 13 then
    --     myInfo.DetailData.ad = val
    -- elseif attrType == 14 then
    --     myInfo.DetailData.speed = val
    -- elseif attrType == 15 then
    --     myInfo.DetailData.def = val
    -- elseif attrType == 16 then
    --     myInfo.DetailData.strength = val
    -- elseif attrType == 17 then
    --     myInfo.DetailData.power = val
    -- elseif attrType == 18 then
    --     myInfo.DetailData.agile = val
    -- elseif attrType == 19 then
    --     myInfo.DetailData.psychic = val
    -- elseif attrType == 20 then
    --     myInfo.DetailData.endurance = val
    -- elseif attrType == 26 then
    --     if val > myInfo.DetailData.Money then
    --         --BT_PARAMS.EndGifts.Money = val-myInfo.DetailData.Money

    --         local flyItem = LFlyItem:New(LFlyItem.FlyType.Money,val)
    --         LGameMsg.m_netDealMsg:Change(LUILogicEvent.ShowFlyItems,flyItem)
    --         this:SendMsg(LGameMsg.m_netDealMsg)
    --     end

    --     myInfo.DetailData:setMoney(val)      --非绑金
       
    --     AddQiannengOrMoney = true                  --金钱数量变化 检测技能可提升
    -- elseif attrType == 27 then
    --         if val - myInfo.DetailData.TongBao > 0 then
    --             PlayMoneyMuicEffect = true
    --         end

    --         -- myInfo.DetailData.TongBao = val
    --         myInfo.DetailData:setTongBao(val)
    -- elseif attrType == 28 then
    --     myInfo.DetailData.ap = val
    -- elseif attrType == 29 then
    --     myInfo.DetailData.hit = val
    -- elseif attrType == 30 then
    --     myInfo.DetailData.avoid = val
    -- elseif attrType == 33 then
    --     myInfo.DetailData.combo = val
    -- elseif attrType == 34 then
    --     myInfo.DetailData.crit = val
    -- elseif attrType == 35 then
    --     myInfo.DetailData.beatBack = val
    -- elseif attrType == 36 then
    --     myInfo.DetailData.adBeatBack = val
    -- elseif attrType == 37 then
    --     myInfo.DetailData.apBeatBack = val
    -- elseif attrType == 38 then
    --     myInfo.DetailData.apCrit = val
    -- elseif attrType == 46 then
    --     if val - myInfo.DetailData.BindTongBao > 0 then
    --         PlayMoneyMuicEffect = true
    --     end

    --     -- myInfo.DetailData.BindTongBao = val
    --     myInfo.DetailData:setBindTongBao(val)

    -- elseif attrType == 50 then
    --         myInfo.MyPowerUpdate = val - myInfo.zhanDouLi
    --         myInfo.zhanDouLi = val
    --         if myInfo.MyPowerUpdate ~= 0 then
    --             LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIRoleDataChangeEvent.PowerChanged)
    --             this:SendMsg(LGameMsg.m_netDealBaseMsg)
    --         end
    -- elseif attrType == 51 then        -- 背包格数
    --     local preOpenNum = val - myInfo.packageOpenNum
    --     myInfo.packageOpenNum = val
    --     LGameMsg.m_netDealMsg:Change(LUIBagEvent.BagUnLock,preOpenNum)
    --     this:SendMsg(LGameMsg.m_netDealMsg)
    -- elseif attrType == 52 then        -- 下个格子开启时间
    --     myInfo.nextOpenPackageTime = val
    --     LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIBagEvent.RefreshUnLockTime)
    --     this:SendMsg(LGameMsg.m_netDealBaseMsg)
    -- elseif attrType == 53 then        -- 反伤
    --     myInfo.DetailData.hurtBack = val
    -- elseif attrType == 54 then        -- 减伤
    --     myInfo.DetailData.cutHurt = val
    -- elseif attrType == 55 then        -- 招架
    --     myInfo.DetailData.parry = val
    -- elseif attrType == 56 then        -- 格挡
    --     myInfo.DetailData.block = val
    -- elseif attrType == 57 then        -- 韧性
    --     myInfo.DetailData.tenacity = val
    -- elseif attrType == 58 then        -- 绑定钱
    --     if val > myInfo.DetailData.BindMoney then
    --         --BT_PARAMS.EndGifts.Money += val-myInfo.DetailData.BindMoney
    --         local flyItem = LFlyItem:New(LFlyItem.FlyType.Money,val)
    --         LGameMsg.m_netDealMsg:Change(LUILogicEvent.ShowFlyItems,flyItem)
    --         this:SendMsg(LGameMsg.m_netDealMsg)
    --     end
    --     -- myInfo.DetailData.BindMoney = val
    --     myInfo.DetailData:setBindMoney(val)
    --     AddBandMoney = true
    --     AddQiannengOrMoney = true
    -- elseif attrType == 59 then
    --     -- myInfo.DetailData.CompeteScore = val
    --     myInfo.DetailData:setCompeteScore(val)
    -- elseif attrType == 61 then   --角色光效信息
    --     myInfo.LightEffect = val
    --     --更新角色光效
    --     -- if(GameMap* map = gameLayer->GetGameMap())
    --     --     map->CheckHeroWeaponEffect()
    -- end

    -- -- if(AddBandMoney || AddQiannengOrMoney)
    -- --     gameLayer->StartGetItemOrMoneyCheck()

    -- -- if(PlayMoneyMuicEffect && !gameLayer->GetBattleLayer())
    -- --     SoundMgr::GetInstance()->PlayEffect(Game_EffJinQianHuoDe)

    -- return -1---1代表什么都没有
end



-- function LuaNetRecvdMsg.DealMsgSkillDesc(stream)
--     local skillId = stream:ReadWord()
--     local desc = stream:ReadString()
--     LSkillMgr:SetSkillDescBySkillId(skillId,desc)
-- end

--[[
英雄技能更新
]]
function LuaNetRecvdMsg.DealMsgUpdateHeroSkill(stream)
    local heroSkill = LRoleDataMgr.HeroSkills
    local id = stream:ReadWord()
    local level = stream:ReadWord()
    

    local IsUpgrade = false
    for i = 1, #heroSkill do
        if heroSkill[i].id == id then
            heroSkill[i].level = level
            IsUpgrade = true
            break
        end
    end

    if false == IsUpgrade then
        local skill = LSkillMgr:getSkillById(id)
        skill.id = id
        skill.level = level
        --LSkillMgr:UpdateSkill(skill)
        table.insert(heroSkill, skill)

        LGameMsg.m_baseMsgWithOne:Change(LUISkillEvent.SkillNewUnLock, id)
        this:SendMsg(LGameMsg.m_baseMsgWithOne)
    end
    Utils:CheckImprove(ImproveDef.Type.UP_SKILL)
end

-- function LuaNetRecvdMsg.DealMsgHeroSkillList(stream)--解析英雄技能
--     local num = stream:ReadByte()
--     local heroSkill = LRoleDataMgr.HeroSkills
--     local tmp = {}
--     for i = 1, num do
--         local id = stream:ReadWord()
--         local skill = LSkillMgr:getSkillById(id)
--         if skill == nil then
--             stream:ReadWord()
--         else
--             skill.level = stream:ReadWord()
--             --LSkillMgr:UpdateSkill(skill)
--             table.insert(heroSkill, skill)
--             if skill.level > 0 then
--                 table.insert(tmp,id)
--             end
--         end
        
--     end
--     -- local msg = RoleSkillsMsg:new(CEnum.RoleEvent.LuaSetSkills,tmp)
--     -- this:SendMsg(msg)
--     -- --如果在战斗中，更新一下面板
--     -- if(BattleLayer *battleLayer =GAMELAYER->GetBattleLayer())
--     --     battleLayer->updateMenuHeroSkills()
--     LGameMsg.m_netDealMsg:Change(LUIBattleEvent.updateSkillData)
--     this:SendMsg(LGameMsg.m_netDealMsg)
--     LRedDotCheckMgr:MainSkillCheck()
-- end

function LuaNetRecvdMsg.DealMsgHeroSkillNextLvDep(stream)
    local rsp = {}
    rsp.develop = stream:ReadWord() 
    rsp.money = stream:ReadWord()
    rsp.skill_lv = stream:ReadByte()
    LGameMsg.m_netDealMsg:Change(LUISkillEvent.SkillNextDepInfo, rsp)
    this:SendMsg(LGameMsg.m_netDealMsg)
end

function LuaNetRecvdMsg.DealMsgHeroSkillUpGradeOneTime(stream)
    local rsp = {}
    rsp.sucess = stream:ReadByte()
    rsp.errmsg = stream:ReadString()
    if rsp.sucess == 1 then
        LGameMsg.m_netDealMsg:Change(LUISkillEvent.SkillUpGrade, rsp)
        this:SendMsg(LGameMsg.m_netDealMsg)
        --音效
        LGameMsg.m_audioMsg:Change(LAudioEvent.PlayEffect, AppDef.SysBGM.Skill_LevelUp)
        this:SendMsg(LGameMsg.m_audioMsg)    
    end
    

    LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,rsp.errmsg)
    this:SendMsg(LGameMsg.m_scrollTipsMsg)
    
end


function LuaNetRecvdMsg.DealMsgEquipList(stream)
    for i = 1, LRoleData.MAX_EQUIP_NUM do
        LRoleDataMgr.MyHeroInfo.EquipList[i].m_pos = i
        LuaNetRecvdMsg.ReadItemData(LRoleDataMgr.MyHeroInfo.EquipList[i], stream)
    end

    if LRoleDataMgr.MyHeroInfo.EquipList[AppDef.EEquipmentType.EEWuQi].m_id > 0 then
        LRoleDataMgr.MyHeroInfo:SendHeroModelChangedMsg()
    end
    -- GameMap *gameMap = GAMELAYER->GetGameMap()
    -- if (gameMap)
    --     gameMap->CheckHeroWeaponEffect()
    LRedDotCheckMgr:MainDuanzaoCheck()
end

--解析物品详细信息
function LuaNetRecvdMsg.DealMsgItemDetail(stream)
    local op = stream:ReadByte()
    local pos = stream:ReadByte() + 1--服务器下标从0开始，lua数组从1开始
    if op == 0 then     --equip
        LuaNetRecvdMsg.ReadItemData(LRoleDataMgr.MyHeroInfo.EquipList[pos],stream)
    elseif op == 1 then   --package
        LuaNetRecvdMsg.ReadItemData(LRoleDataMgr.Equip.PackageMap[pos],stream)
        --LRoleDataMgr.Equip.m_itemNum = LRoleDataMgr.Equip.m_itemNum - 1
    end
end

function LuaNetRecvdMsg.ReadPetInfo(pData, stream)
    --[[
    petStruct:
 id     type    name   quality   star   star_step  level  attackType  exp    zhandouli     
2byte   1byte  string   1byte    1byte    1byte    2byte    1byte    4byte     4byte

attack  wufang  fafang  qixue  sudu   mingzhong  shanbi  baoji   baojikang  zengshangLv   wumianLv
4byte   4byte   4byte   4byte  4byte   4byte     4byte   4byte    4byte       4byte         4byte
    
famianLv  baojiAdd  fanjiLv  fanjiAdd  fanjikangLv   lianjiLv  lianjiAdd   lianjikangLv   fanzhenLv
 4byte     4byte     4byte    4byte      4byte        4byte      4byte       4byte          4byte

fanzhenAdd  fanzhenkangLv   fumianAdd  fumiankangAdd
   4byte       4byte          4byte       4byte
       
skillNum  [ skillIdx  skillId  skillLv ]
 1byte       1byte     2byte    2byte
     
xuemaiNum  [ xuemaiIdx  xueMaiLevel  ]
  1byte        1byte       1byte
    ]]
    -- local pid = stream:ReadWord()
    -- pData:SetPetId(pid)

    pData.fightPos = stream:ReadByte()--
    pData.name = stream:ReadString()
    pData.star = stream:ReadByte()--星级
    --print("pData.name ===>", pData.name, pData.star)
    pData.breakLevel = stream:ReadByte()--突破等级
    pData.level = stream:ReadWord()
    pData.exp = stream:ReadUInt()--经验
    pData.expMax = stream:ReadUInt()--最大经验
    pData.zhandouli = stream:ReadULongInt() -- 战斗力   
    -- print("ReadPetInfo pData.fightPos ===>",pData.name, pData.fightPos,pData.level,pData.breakLevel,pData.zhandouli)
    pData.attrs = {}
    pData.attrs[AppDef.EAttrType.EAT_ATTACK] = stream:ReadUInt()
    pData.attrs[AppDef.EAttrType.EAT_DEFENSE] = stream:ReadUInt()
    pData.attrs[AppDef.EAttrType.EAT_MAGICD_EFENSE] = stream:ReadUInt()
    pData.attrs[AppDef.EAttrType.EAT_HP] = stream:ReadULongInt()
    pData.attrs[AppDef.EAttrType.EAT_SPEED] = stream:ReadUInt()
    pData.attrs[AppDef.EAttrType.EAT_HIT] = stream:ReadUInt()
    pData.attrs[AppDef.EAttrType.EAT_DODGE] = stream:ReadUInt()
    pData.attrs[AppDef.EAttrType.EAT_CRIT] = stream:ReadUInt()
    pData.attrs[AppDef.EAttrType.EAT_RESISIT_CRIT] = stream:ReadUInt()
    pData.attrs[AppDef.EAttrType.EAT_DAMAGE_RATE] = stream:ReadUInt() / 100
    pData.attrs[AppDef.EAttrType.EAT_WM_RATE] = stream:ReadUInt() / 100
    pData.attrs[AppDef.EAttrType.EAT_FM_RATE] = stream:ReadUInt() / 100
    pData.attrs[AppDef.EAttrType.EAT_CRIT_DAMAGE] = stream:ReadUInt() / 100
    pData.attrs[AppDef.EAttrType.EAT_COUNTER_RATE] = stream:ReadUInt() / 100
    pData.attrs[AppDef.EAttrType.EAT_COUNTER_DAMAGE] = stream:ReadUInt() / 100
    pData.attrs[AppDef.EAttrType.EAT_RCOUNTER_RATE] = stream:ReadUInt() / 100
    pData.attrs[AppDef.EAttrType.EAT_DOUBLE_RATE] = stream:ReadUInt() / 100
    pData.attrs[AppDef.EAttrType.EAT_DOUBLE_DAMAGE] = stream:ReadUInt() / 100
    pData.attrs[AppDef.EAttrType.EAT_RDOUBLE_RATE] = stream:ReadUInt() / 100
    pData.attrs[AppDef.EAttrType.EAT_SHOCK_RATE] = stream:ReadUInt() / 100
    pData.attrs[AppDef.EAttrType.EAT_SHOCK_DAMAGE] = stream:ReadUInt() / 100
    pData.attrs[AppDef.EAttrType.EAT_RSHOCK_RATE] = stream:ReadUInt() / 100
    pData.attrs[AppDef.EAttrType.EAT_FUMIANQIANGHUA] = stream:ReadUInt() / 100
    pData.attrs[AppDef.EAttrType.EAT_FUMIANDIKANG] = stream:ReadUInt() / 100
    --[[新加属性]]
    pData.attrs[AppDef.EAttrType.EAT_ATTACK_JIACHENG] = (stream:ReadUInt() -10000)/100
    pData.attrs[AppDef.EAttrType.EAT_DEFENSE_JIACHENG] = (stream:ReadUInt() -10000)/100
    pData.attrs[AppDef.EAttrType.EAT_MD_JIACHENG] = (stream:ReadUInt() -10000)/100
    pData.attrs[AppDef.EAttrType.EAT_HP_JIACHENG] = (stream:ReadUInt() -10000)/100

    pData.XLLv = stream:ReadByte()
    local num = stream:ReadByte()
    print("LuaNetRecvdMsg.ReadPetInfo num = %d", num)
    for i=1, num do
        local data = {}
        data.type = stream:ReadByte()
        data.xlNum = stream:ReadWord()
        pData.XLInfo[data.type] = data.xlNum
    end

    pData.skillNum = stream:ReadByte()

    -- print("LuaNetRecvdMsg.ReadPetInfo pData.skillNum =>", pData.skillNum)
    
    for i = 1, pData.skillNum do
        local pos = stream:ReadByte() + 1
        local id = stream:ReadWord()
        local sdt = LSkillMgr:getSkillById(id)
        if sdt ~= nil then
            if pData.skills[pos] == nil then
                pData.skills[pos] = {}
            end
            pData.skills[pos].skDetail = sdt
            pData.skills[pos].level = stream:ReadWord()
        end
    end

end

function LuaNetRecvdMsg.ReadPetEquipData(value, stream)
    --宠物装备
    --local value = LPetEquipInfo:New()
    value.m_uid = stream:ReadUInt()
    if value.m_uid == 0 then
        return
    end
    value.m_id = stream:ReadWord()
    value.m_fpos = stream:ReadByte()
    value.m_jlExp = stream:ReadUInt()
    local num = stream:ReadByte()
    for i=1,num do
        local ctype = stream:ReadByte()
        local level = stream:ReadUShort()
        value.cultivateLevel[ctype] = level
    end
    --基础属性
    local attrType = stream:ReadWord()
    local attrVal = stream:ReadUInt()
    value.baseAttrs = {}
    value.baseAttrs[attrType] = attrVal
    for i=1,4 do
        local ctype = stream:ReadByte()
        num = stream:ReadByte()
        local attrs = {}
        for i=1,num do
            local atype = stream:ReadWord()
            local val = stream:ReadUInt()
            attrs[atype] = val
        end

        if ctype == 1 then
            value.qhAttrs = attrs
        elseif ctype == 2 then
            value.jlAttrs = attrs
        elseif ctype == 3 then
            value.jxAttrs = attrs
        elseif ctype == 4 then
            value.szAttrs = attrs
        end
    end
    local cfgData = JsonConfig.m_equipConfig.getDefByID(value.m_id)
    if cfgData ~= nil then
        value.m_name = cfgData.name
        value.m_wpos = cfgData.part
        value.m_suitType = cfgData.suit
        value.m_quality = cfgData.quality
        value.m_pic = cfgData.pic      
        value.m_des = cfgData.des
        value.m_from = cfgData.item_from
        value.m_szCostItemId = cfgData.shenzhu_cost
    end
end


--法宝
function LuaNetRecvdMsg.ReadPetFaBaoData(value, stream)
    --宠物装备
    --local value = LPetEquipInfo:New()
    value.m_uid = stream:ReadUInt()
    if value.m_uid == 0 then
        return
    end
    value.m_id = stream:ReadWord()
    value.m_fpos = stream:ReadByte()
    value.m_wpos = stream:ReadByte()
    value.qHExp = stream:ReadUInt() --强化经验
    --print("ReadPetFaBaoData ====>", value.qHExp, value.m_wpos, value.m_uid, value.m_id)
    local cultnum = stream:ReadByte()
    --强化
    local cfgData = JsonConfig.m_faBaoConfig.getDefByID(value.m_id)
    for i=1,cultnum do
        local ctype = stream:ReadByte()
        local level = stream:ReadByte()  --强化等级
        value.cultivateLevel[ctype] = level
    end
    value.baseData = cfgData
end

function LuaNetRecvdMsg.ReadItemData(pItem, stream)
    if pItem == nil then
        return
    end

    pItem.m_id = stream:ReadWord()
--    dumpdump(pItem, "LuaNetRecvdMsg.ReadItemData")
        
    if pItem.m_id == 0 then
        pItem.m_item = nil
        return
    end
    pItem.m_num = stream:ReadWord()
    stream:ReadWord()--道具类型
    pItem.m_item = LItemMgr:getItem(pItem.m_id)
    if  pItem.m_item == nil then
        return
    end
    pItem.m_name =  pItem.m_item.name
    --pItem.m_pos = pItem.m_item.m_pos
    pItem.m_price = pItem.m_item.jiage
    pItem.m_roleLevel = pItem.m_item.limit_lv
    pItem.m_quality = pItem.m_item.quality
    pItem.m_type = pItem.m_item.type
    -- --print("ReadItemData",pItem.m_id,pItem.m_type,pItem.m_item.m_type)
    -- pItem.m_type = pItem.m_item.m_type
    -- if LItemMgr:IsEquip(pItem.m_type)  then --装备
    --     pItem.m_qhLevel = stream:ReadByte()

    --     pItem.addCuiLianAttrNum = stream:ReadByte()
    --     for i = 1,pItem.addCuiLianAttrNum do
    --         pItem.addCuiLianAttrType[i] = stream:ReadWord()
    --         pItem.addCuiLianAttrVal[i] = stream:ReadUInt()
    --         pItem.addCuiLianAttrStar[i] = stream:ReadByte()
    --     end

    --     pItem.addXiLianAttrNum = stream:ReadByte()
    --     for i = 1,pItem.addXiLianAttrNum do
    --         pItem.addXiLianAttrType[i] = stream:ReadWord()
    --         pItem.addXiLianAttrVal[i] = stream:ReadUInt()
    --         pItem.addXiLianAttrStar[i] = stream:ReadByte()
    --         pItem.addSaveXiLianAttrType[i] = stream:ReadWord()
    --         pItem.addSaveXiLianAttrVal[i] = stream:ReadUInt()
    --         pItem.addSaveXiLianAttrStar[i] = stream:ReadByte()
    --     end
    -- end

-- --藏宝图修改
--     if pItem.m_item.m_id == 2441 or pItem.m_item.m_id == 2442 then
--         local posData = stream:ReadUInt()
--         pItem.m_targetPos = posData
--     end

end

--通用奖励
function LuaNetRecvdMsg.ReadRewardData(value, stream)
    local num = stream:ReadByte()  --未领奖励个数
    for i=1,num do
        local item = LuaNetRecvdMsg.ReadCommonReward(stream)
        -- item.id = stream:ReadWord()
        -- item.num = stream:ReadUInt()
        table.insert(value,item)
    end
end

function LuaNetRecvdMsg.DealMsgPackageList(stream)--解析背包列表数据
    local PackageNum = stream:ReadWord()
    --print("DealMsgPackageList ===>", PackageNum)
    local huoYueItem = nil
    for i = 1, PackageNum do
        local pos = stream:ReadWord()--服务器下标从0开始
        local Item = LPItem:New(0)
        Item.m_pos = pos + 1
        Item.m_id = stream:ReadWord()
        Item.m_num = stream:ReadWord()
        Item.m_item = LItemMgr:getItem(Item.m_id)
        if Item.m_item ~= nil then
            Item.m_type = Item.m_item.type
            Item.m_name = Item.m_item.name
            Item.m_quality = Item.m_item.quality
            Item.m_roleLevel = Item.limit_lv
            end
        LRoleDataMgr.Equip:UpdateItemData(Item.m_pos, Item)
    end
    LRoleDataMgr.Equip.m_itemNum = PackageNum

    LGameMsg.m_netDealMsg:Change(LUIMainEvent.StartAutoUseItemCheck)
    this:SendMsg(LGameMsg.m_netDealMsg)
    LRoleDataMgr:UpdatePetUpItems()
end

function LuaNetRecvdMsg.DealMsgCheckHeroName(stream)
    LGameMsg.m_netDealMsg:Change(LUIWaitAni.ClearWait, LuaNetCmd.MSG_CHECKNAME)
    this:SendMsg(LGameMsg.m_netDealMsg)
    
    local op = stream:ReadByte()
    local heroNames = {}
    if op == 1 then
    elseif op == 2 then
        local sex = stream:ReadByte()
        local nameNum = stream:ReadByte()
        if nameNum <= 0 then
            return
        end

        heroNames[1] = sex
        heroNames[2] = nameNum
        for i=3, nameNum+2 do
            heroNames[i] = stream:ReadString()
        end
        --LGameMsg.m_baseMsgTwo:Change(LUILoginEvent.RecvCheckHeroName, Name,succ)
        --this:SendMsg(LGameMsg.m_baseMsgTwo)
        LGameMsg.m_netDealMsg:Change(LUILoginEvent.RecvCheckHeroName, heroNames)
        this:SendMsg(LGameMsg.m_netDealMsg)
    end
end

function LuaNetRecvdMsg.DealMsgCreateHero(stream)
    LGameMsg.m_netDealMsg:Change(LUIWaitAni.ClearWait, LuaNetCmd.MSG_CREATE_HERO)
    this:SendMsg(LGameMsg.m_netDealMsg)
    local succ = stream:ReadByte()
    if succ == 1 then
        --清空内存储
        LRoleDataMgr.Account.userAccount.Account = ""
        LRoleDataMgr.Account.userAccount.Password = ""
        
        local roleid = stream:ReadUInt()
        local name = stream:ReadString()
        local sex = stream:ReadByte()
        local model = stream:ReadByte()
        local head = stream:ReadByte()
        local createTime = stream:ReadUInt()
        GameSdk:U8SendInfo(2,LRoleDataMgr.Account.selServer, roleid, LRoleDataMgr.m_strCreateName)
        LuaNetSendMsg:QueryStartGame(roleid)
        --LRoleDataMgr:ReadRoleData(stream)
    else
    --失败
        local errMsg = stream:ReadString()
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,errMsg)
        this:SendMsg(LGameMsg.m_scrollTipsMsg)
    end
end

function LuaNetRecvdMsg.DealMsgStartGame(stream)
    LocalTestLog("DealMsgStartGame begin")
    LGameMsg.m_netDealMsg:Change(LUIWaitAni.ClearWait, LuaNetCmd.MSG_CHOOSE_HERO)
    this:SendMsg(LGameMsg.m_netDealMsg)

    -- gameDelayTime = 0.0f
    -- isChooseHero = true
    -- this->unschedule((SEL_SCHEDULE)&GameScene::DelayTimeUpdate)
    -- this->schedule(schedule_selector(GameScene::DelayTimeUpdate),10.0f)

    local succ = stream:ReadByte()
    LocalTestLog("DealMsgStartGame succ=" .. tostring(succ))
    if succ == 1 then

        LRoleDataMgr.Account.userAccount.Account = LUserConfigMgr:GetUserAccount()
        LRoleDataMgr.Account.userAccount.Password = LUserConfigMgr:GetUserPassword()
        LUserConfigMgr:SetUserAccountAndPsd(LRoleDataMgr.Account.userAccount.Account, LRoleDataMgr.Account.userAccount.Password)
        --清空内存储
        -- LRoleDataMgr.Account.userAccount.Account = ""
        -- LRoleDataMgr.Account.userAccount.Password = ""
        
        --建立gameLayer主界面
        LRoleDataMgr:ReadRoleData(stream)
        LUserConfigMgr:LoadCacheDataByUser()
    else
    --失败
        local errMsg = stream:ReadString()
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,errMsg)
        this:SendMsg(LGameMsg.m_scrollTipsMsg)
    end
end

function LuaNetRecvdMsg.DealMsgLogin(stream)
    LocalTestLog("DealMsgLogin begin")
    LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIWaitAni.ForceClearWait)
    this:SendMsg(LGameMsg.m_netDealBaseMsg)

    --记录上次登录的服务器
    local succ = stream:ReadByte()
    LocalTestLog("DealMsgLogin succ=" .. tostring(succ))
    if succ == 1 then
        --成功
        --SetBackToLoginFlag(false)
        local acData = LRoleDataMgr.Account.m_AccountData
        acData.type = stream:ReadByte()--1:神界（跨服） 0：游戏服
        acData.userid = stream:ReadUInt()
        acData.roleid = stream:ReadUInt()
        LocalTestLog("DealMsgLogin type=" .. tostring(acData.type) .. " userid=" .. tostring(acData.userid) .. " roleid=" .. tostring(acData.roleid))
        if acData.roleid == 0 then
           -- LGameMsg.m_initUIMsg:Change("RoleCreateUI")
           -- this:SendMsg(LGameMsg.m_initUIMsg)
           LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Login.RoleCreateUI",AppDef.UIType.Normal)
           this:SendMsg(LGameMsg.m_initUIMsg)
            return
        end

        acData.name = stream:ReadString()
        acData.head  = stream:ReadByte()
        --acData.professional = stream:ReadByte()
        acData.level = stream:ReadWord()
        acData.sex = stream:ReadByte()
        LocalTestLog("DealMsgLogin role name=" .. tostring(acData.name) .. " head=" .. tostring(acData.head) .. " level=" .. tostring(acData.level) .. " sex=" .. tostring(acData.sex))

        local waitAniData = {
                            key = LuaNetCmd.MSG_CHOOSE_HERO, 
                            waitMsg = "", 
                            autoClearTime = 0
                        }
        LGameMsg.m_netDealMsg:Change(LUIWaitAni.ShowWait, waitAniData)
        this:SendMsg(LGameMsg.m_netDealMsg)

        LuaNetSendMsg:QueryStartGame(acData.roleid)
        LocalTestLog("DealMsgLogin sent QueryStartGame roleid=" .. tostring(acData.roleid))
    else
        --失败
        local msg = stream:ReadString()
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
        this:SendMsg(LGameMsg.m_scrollTipsMsg)
    end
end

--[[
收到排队服务器状态信息
]]
function LuaNetRecvdMsg.DealMsgLineUpStatus(stream)
    LGameMsg.m_netDealMsg:Change(LUIWaitAni.ClearWait, LuaNetCmd.MSG_ACC_LINEUP)
    this:SendMsg(LGameMsg.m_netDealMsg)

    local serverId = stream:ReadUInt()

    local success = stream:ReadByte()
    local lineUpIdx = 0
    if success == 0 then
        --还在排队
        lineUpIdx = stream:ReadUInt()
    end

    if lineUpIdx == 0 then

    else

    end
end

--登录服角色列表信息
function LuaNetRecvdMsg.DealMsgRoles(stream)
    LRoleDataMgr.Account:DeleteServerHeroInfo()
    local num = stream:ReadWord()
    for k = 1, num do
        local sLHInfo = LServerHeroInfo:New()
        sLHInfo.id = stream:ReadWord()--2字节的id serverID
        sLHInfo.name = stream:ReadString()--角色名称

        sLHInfo.sex =  stream:ReadByte()
        sLHInfo.head= stream:ReadByte()
        sLHInfo.level =  stream:ReadByte()
        LRoleDataMgr.Account:UpdateServerHeroList(sLHInfo)
    end
    
    --DealMsgServerList(DATA_MGR->Account.serverList)
end

--维护公告
function LuaNetRecvdMsg.DealMsgBehalfAnnouncement(stream)
--     string Str = stream:ReadString()
--     Str = StringHelper::ReplaceStr(Str,"|","\n")
-- #ifndef DEBUG
--     if(CCNode *LogLayer = GAME_SCENE->GetLoginConsole())
--     {
--         LoginNotifyLayer *notify = LoginNotifyLayer::create()
--         notify->SetLogAnnounceText(Str)
--         notify->SetCallBack(LogLayer,(SEL_CallFuncNII)&LoginMainLayer::onLoginNotifyCallBack)
--         LogLayer->addChild(notify, 100)
--     }
-- #endif
end

function LuaNetRecvdMsg.DealMsgAcLogining(stream)
    LGameMsg.m_netDealMsg:Change(LUIWaitAni.ClearWait, LuaNetCmd.MSG_ACC_LOGIN)
    this:SendMsg(LGameMsg.m_netDealMsg)
    local succ = stream:ReadByte()
    if succ == 1 then
        this.DealMsgAcLoginInfo(stream,false)
    else
        --登陆失败
        local errMsg = stream:ReadString()
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,errMsg)
        this:SendMsg(LGameMsg.m_scrollTipsMsg)

        if GameSdk:IsSDKUser() then
            --登录失败重新登录
            --GameSdk:UCLoginServer()
            GameSdk:U8SDKLogin()
        else
            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Login.LoginUI",AppDef.UIType.Normal,2)
            this:SendMsg(LGameMsg.m_initUIMsg)
        end
        
        -- std::string errMsg = stream:ReadString()
        -- TipsMgr::GetInstance()->SetCenterTip(errMsg)
        -- if(ark_Download::IsSDKLogin())
        -- {
        --     _CurLayerType = LT_INIT
        -- }
        -- else
        -- {
        --     _CurLayerType = LT_InputAcPwd
        -- }
        -- UpdateLayer(_CurLayerType)
    end
end

function LuaNetRecvdMsg.DealMsgAcLoginReg(stream)
    
    local op = stream:ReadByte()
    --校验用户名
    if op == 1 then
        local Name = stream:ReadString()
        local succ = stream:ReadByte()
        LGameMsg.m_baseMsgTwo:Change(LUILoginEvent.RegisterCheckAccountResult, Name,succ)
        this:SendMsg(LGameMsg.m_baseMsgTwo)
        -- if succ == 0 then
        --     LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.Login_Register_Account_AlreadyExist)
        --     this:SendMsg(LGameMsg.m_scrollTipsMsg)
        -- end
    elseif op == 2 then--注册返回
         local succ = stream:ReadByte()
         if succ == 1 then
            --注册成功
            LRoleDataMgr.Account.serverHeroInfo = {}
            this.DealMsgAcLoginInfo(stream,true)
         else
            --注册失败
            local errMsg = stream:ReadString()
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,errMsg)
            this:SendMsg(LGameMsg.m_scrollTipsMsg)
         end
        -- int succ = stream:ReadByte()
        -- if(succ == 1)
        -- {
        --     --成功
        --     vector<ServerHeroInfo>& serverHeroInfo = DATA_MGR->Account.serverHeroInfo
        --     serverHeroInfo.clear()
        --     --this->SetCurrentLayer(LT_ServerList)
        --     CCLOG("=================DealMsgAcLoginReg======================1111111")
        --     --ark_Download::PostDownLoadInfo(ark_Download::DS_CREATE_ROLE)
        --     --跳转服务器界面
        --     DealMsgAcLoginInfo(stream,true)
        --     this->SetCurrentLayer(LT_INIT)
        -- }
        -- else
        -- {
        --     string errMsg = stream:ReadString()
        --     TipsMgr::GetInstance()->SetCenterTip(errMsg)
        -- }
    end
end

function LuaNetRecvdMsg.DealMsgAcLoginInfo(stream,fromReg)
    local uid = stream:ReadUInt()
    local sid = stream:ReadString()

    local starttime = 0
    local canenterstate = 0
    -- if(ark_Download::IsKoreaSdk())
    -- {
    --     starttime = stream:ReadUInt()--删除开始计算时间
    --     canenterstate = stream:ReadByte()--0 表示可以进入， 1表示已删除不可进入
    -- }
    --请求服务器列表
    LRoleDataMgr.Account.uid = uid
    LRoleDataMgr.Account.sid = sid
    LRoleDataMgr.Account.serverList = {}

    local num = stream:ReadUInt()
    for i = 1, num do
        local data = LServerInfo:New()
        data.id = stream:ReadWord()
        data.page = stream:ReadWord()
        data.serName = stream:ReadString()
        ----print("data.serName",data.serName)
        data.serIp = stream:ReadString()
        data.serPort = stream:ReadUInt()
        data.serId = stream:ReadUInt()
        data.serType = stream:ReadByte()
        data.onlineState = stream:ReadByte()
        data.serState = stream:ReadByte()
        data.serPic = stream:ReadWord()
        data.errMsg = stream:ReadString()
        if string.len(data.errMsg) == 0 then
            data.errMsg = GUITips.Login_Server_Enter_Error
        end
        if stream:ReadByte() == 1 then
            data.needLineUp = true
        else
            data.needLineUp = false
        end
        data.lineUpIp = stream:ReadString()
        data.lineUpPort = stream:ReadUInt()
        table.insert(LRoleDataMgr.Account.serverList,data)
    end

    stream:ReadByte()
    local accountID = stream:ReadString()
    --是否绑定
    local isBind = stream:ReadByte()
    local phoneNum = stream:ReadString()
    local isRealName = stream:ReadByte()
    LRoleDataMgr.Account.isBindPhone = isBind
    
    LRoleDataMgr.Account.phoneNum = phoneNum
    LRoleDataMgr.Account.isRealName = isRealName

    --sdk登录时，没有该账号即首次登录(可理解为注册,玩家清除游戏数据除外)
--     if(USER_CFG->GetUserAccount().size() <= 0 and ark_Download::IsKoreaSdk())
--     {
--         --韩版用户注册调整为游戏注册
--         CallJava_goAdbrixAnalys(1, "try_join")
--         CallJava_goAdbrixAnalys(1, "_install")
-- #ifdef _IOS_SDK_KOREA
--         KrCSdkfunctionWraper::adbrixAnalyse(1, "try_join")
--         KrCSdkfunctionWraper::adbrixAnalyse(1, "_install")
-- #endif
--     }
    local account = LUserConfigMgr:GetUserAccount()

    -- if (USER_CFG->GetUserAccount().size() <= 0 and ((ark_Download::GetClientADCode() == AD_ARD_YAOSHENZHUANOL) or (ark_Download::GetClientADCode() == AD_ARD_YAOSHENZHUANOL324)or (ark_Download::GetClientADCode() == AD_ARD_YAOSHENZHUANOL323)or (ark_Download::GetClientADCode() == AD_ARD_YAOSHENZHUANOL322)or (ark_Download::GetClientADCode() == AD_ARD_YAOSHENZHUANOL319) or (ark_Download::GetClientADCode() == AD_ARD_YSZWEIXIAZAI)
    --     or(ark_Download::GetClientADCode() == AD_ARD_YSZCPA) or (ark_Download::GetClientADCode() == AD_ARD_YAOSHENZHUANOL329) or (ark_Download::GetClientADCode() == AD_ARD_YAOSHENZHUANOL330) or (ark_Download::GetClientADCode() == AD_ARD_YAOSHENZHUANOL331) or (ark_Download::GetClientADCode() == AD_ARD_YAOSHENZHUANOL332) or  (ark_Download::GetClientADCode() == AD_ARD_YAOSHENZHUANOL334)or (ark_Download::GetClientADCode() == AD_ARD_YAOSHENZHUANOL333)))
    -- {
    --     CallJava_goGDTEvent()
    -- }

    if string.len(LRoleDataMgr.Account.userAccount.Account) > 0 then
        -- 此处密码莫名会变成空 导致密码无法保存 frog
        LUserConfigMgr:SetUserAccountAndPsd(LRoleDataMgr.Account.userAccount.Account, LRoleDataMgr.Account.userAccount.Password)
    end
    if LGameMsg.m_deleteUIMsg == nil then
        LGameMsg.m_deleteUIMsg = LUIInitMsg:New(LUILogicEvent.InitUI, 0)
    end
    LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Login.RegisterUI")
    this:SendMsg(LGameMsg.m_deleteUIMsg)

    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Login.LoginUI",AppDef.UIType.Normal,1)
    this:SendMsg(LGameMsg.m_initUIMsg)
    -- if(ark_Download::IsKoreaSdk()) --删除在7日内，还可登录，显示登录界面
    -- {
    --     if(canenterstate == 1)
    --     {
    --         DialogOKCancel* Notify = DialogOKCancel::create()
    --         Notify->SetText(RES_STRC(DataConsts::RSI_GS_TIP16), RES_STR(DataConsts::RSI_GS_TIP24))
    --         Notify->SetPriority(-201)
    --         Notify->ChangeButtonColor()
    --         Notify->SetOkCallBack(this, (SEL_CallFuncN)&LoginMainLayer::exitGame)--点击确定直接退出游戏
    --         Notify->SetCancelCallBack(this, (SEL_CallFuncN)&LoginMainLayer::exitGame)--点击取消也退出游戏
    --         addChild(Notify,10000)
    --         return
    --     }
    --     else
    --     {
    --         if(starttime > 0)-- 有删除过
    --         {
    --             time_t now = starttime + 28800
    --             struct tm *p
    --             p = gmtime(&now)
    --             char s[80]
    --             strftime(s, 80, "%Y-%m-%d %H:%M:%S", p)
    --             DialogOKCancel* Notify = DialogOKCancel::create()
    --             Notify->SetText(RES_STRC(DataConsts::RSI_GS_TIP16),CCSTR_FMT1(RES_STRC(DataConsts::RSI_GS_TIP25), s))
    --             Notify->SetPriority(-201)
    --             Notify->ChangeButtonColor()
    --             Notify->SetOkCallBack(this, (SEL_CallFuncN)&LoginMainLayer::cancelDelAccount)--取消删除
    --             Notify->SetCancelCallBack(this, (SEL_CallFuncN)&LoginMainLayer::exitGame)--点击直接退出游戏
    --             addChild(Notify,10000)
    --         }
    --         else --没有删除过，直接显示服务器列表
    --         {
    --             DealMsgServerList(pServerList)
    --         }
    --     }
    -- }
    -- else
    --     DealMsgServerList(pServerList)
-- #if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
--     --TestinCrashHelper::setUserInfo(CCSTR_FMT1("%d",DATA_MGR->Account.m_AccountData.userid))

--     if(ark_Download::GetClientADCode() == AD_ARD_49)
--     {
--         --49you 额外信息
--         CallJava_go49ExtData("enterServer",DATA_MGR->Account.m_AccountData.userid,"",1,1,"",0,1,"")
--     }
--     if(ark_Download::GetClientADCode() == AD_ARD_LJAPP)
--     {
--         -- 额外信息
--         CallJava_goLJAppExtData("enterServer",DATA_MGR->Account.m_AccountData.userid,"",1,1,"",0,1,"")
--     }
--     if(ark_Download::GetClientADCode() == AD_ARD_CLOUD)
--     {
--         HeroData& heroData = DATA_MGR->Hero.MyHeroInfo
--         string roleId = INT2STR(heroData.id)
--         string roleName = heroData.name
--         string roleLevel = INT2STR(heroData.level)
--         int zoneId = USER_CFG->GetLastSelServerId()
--         string zoneName = USER_CFG->GetLastSelServerName()
--         string FactionName = heroData.FactionId > 0 ? heroData.FactionName:""
--         int leftMoney = heroData.DetailData.TongBao
--         int vipLevel = heroData.vipLevel
--         int userId = DATA_MGR->Account.m_AccountData.userid
--         CallJava_goCloudGameRole(INT2STR(zoneId),zoneName,roleId,roleName,roleLevel,INT2STR(leftMoney),FactionName,INT2STR(vipLevel))
--     }
     
-- #endif
    
-- #if defined _IOS_OFFICIAL_YSHQGGJ or _IOS_OFFICIAL_YSHQG or _IOS_OFFICIAL_MHXX or _IOS_OFFICIAL_SSJ
--     if (fromReg) {
--         TalkingDataAppCpaWraper::onRegister(CCSTR_FMT1("%d",DATA_MGR->Account.uid))
--     }
--     TalkingDataAppCpaWraper::onLogin(CCSTR_FMT1("%d",DATA_MGR->Account.uid))
-- #endif
-- #if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
--     --信鸽    
-- --    if (!ark_Download::IsSDKLogin() or ark_Download::GetClientADCode() == AD_IOS_MT) {
-- --        XGWraper::setAccount(CCSTR_FMT1("%d",DATA_MGR->Account.uid))
-- --        string serverName = UserConfig::GetInstance()->GetLastSelServerName()
-- --        if (serverName.empty())
-- --            serverName = "Get ServerName nil"
-- --        XGWraper::setDefaultTag(serverName.c_str())
-- --    }
-- #endif
-- #if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
--     CCLOG("AAAAAAAAAAAAAAAAAA = %s", accountID.c_str())
--     string temp[4]
--     string str
--     int i = 0
--     if (ark_Download::GetClientADCode() == AD_ARD_COOLPAD)
--     {
--         --opendid + "&"+access_token+"&"+expires_in+"&"+refresh_token
--         int pos = accountID.find("&")
--         bool last = false
--         while (pos != string::npos)
--         {
--             if (last)
--                 temp[i] = accountID
--             else
--                 temp[i] = accountID.substr(0,pos)
--             i++
--             accountID = accountID.substr(pos + 1, -1)
--             if (i == 3)
--                 last = true
--             else
--                 pos = accountID.find("&")
--         }
--         DATA_MGR->Account.accountID = temp[0]
--         DATA_MGR->Account.access_token = temp[1]
--         DATA_MGR->Account.expires_in = temp[2]
--         DATA_MGR->Account.refresh_token = temp[3]
--     }
--     else{
--         DATA_MGR->Account.accountID = accountID
--     }
-- #endif
   
end


----------------------------------------------------------------------------------------------------------------------------------------------------------------

function LuaNetRecvdMsg.DealMsgRankList(stream)
    local op = stream:ReadWord() -- 类型 1-等级榜,2-神将榜,3-总战力榜,21-血战即时,22-血战昨日榜,23-推图主线,24-推图支线,25 -图鉴
    LRankDataMgr.m_ranks[op] = {}
    LRankDataMgr.m_myInfo[op] = {}
    local num = stream:ReadByte() -- 长度
    --print("DealMsgRankList op",op)
    for i = 1, num do 
        local info = LRankHeroInfo:New()
        info.slotIndex = stream:ReadWord()
        info.Id = stream:ReadUInt()
        info.name = stream:ReadString()
        info.level = stream:ReadWord()
        info.sex = stream:ReadByte()
        info.head = stream:ReadByte()
        info.jingjie = stream:ReadByte()
        info.fightpower = stream:ReadULongInt()
        info.bangId = stream:ReadUInt()
        info.bangName = stream:ReadString()
        info.data = stream:ReadULongInt()
        info.value = stream:ReadUInt()
        table.insert(LRankDataMgr.m_ranks[op],info) 
    end
    LRankDataMgr.m_myInfo[op].slotIndex = stream:ReadWord()
    LRankDataMgr.m_myInfo[op].data = stream:ReadULongInt()
    LRankDataMgr.m_myInfo[op].value = stream:ReadUInt()
    --dump(LRankDataMgr.m_ranks[op],"LRankDataMgr.m_ranks[op]=========>")
    ------dump(LRankDataMgr.m_myInfo[op])
    LGameMsg.m_netDealMsg:Change(LUIRankEvent.RankListInfo,op)
    this:SendMsg(LGameMsg.m_netDealMsg)
end


function LuaNetRecvdMsg.DealMsgXianHuaRankList(stream)
    local rsp = {}
    local op = stream:ReadByte() -- 类型
    --print("DealMsgXianHuaRankList op =", op)
    rsp.op = op
    rsp.rankdata = {}
    rsp.myrank = {}
    -- =====================
    -- 鲜花
    if op == 1 then
--获取鲜花商店列表(Old)
		local num = stream:ReadUShort()
		local ltabShopData = {}
		for i = 1, num do
			local ltab = LXianhuaShopData:New()
			ltab.itemId = stream:ReadUInt()
			ltab.buy_type = stream:ReadByte()
			ltab.price = stream:ReadUInt()
			table.insert(ltabShopData, ltab)
		end

        local caiDaiNum = stream:ReadByte()
        for i=1, caiDaiNum do
            local gift = LXianhuaShopData:New()
            gift.itemId = stream:ReadUInt()
            gift.sendScore = stream:ReadUInt()
            gift.getScore = stream:ReadUInt()
            table.insert(ltabShopData, gift)
        end

        ----dump(ltabShopData, "gift shop data")
        LGameMsg.m_netDealMsg:Change(LUIGiveGiftEvent.updateXianHuaShop, ltabShopData)
        this:SendMsg(LGameMsg.m_netDealMsg)
		
	elseif op == 2 then
--购买鲜花
		local ltab = {}
		ltab.itemId = stream:ReadUInt()
		ltab.buy_num = stream:ReadUInt()
		local success = stream:ReadByte()
		if success == 1 then
			local item = LItemMgr:getItem(ltab.itemId)
			local itemname = item:Getm_name()

 --           LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, string.format(GUITips.RSI_XIANHUA_BUY_SUC, itemname, ltab.buy_num))
 --           this:SendMsg(LGameMsg.m_scrollTipsMsg)
			
            LGameMsg.m_netDealMsg:Change(LUIGiveGiftEvent.buyXHSuccess, ltab)
            this:SendMsg(LGameMsg.m_netDealMsg)
		else
            local msg = stream:ReadString()
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, msg)
            this:SendMsg(LGameMsg.m_scrollTipsMsg)
		end
	elseif op == 3 then
--获取已有鲜花列表
		local num = stream:ReadUShort()
		local ltabOwnerXH = {}
		for i = 1, num do
			local ltab = {}
			ltab.itemId = stream:ReadUShort()
			ltab.itemNum = stream:ReadUInt()
			ltab.meili = stream:ReadUInt()
			ltab.qinmi = stream:ReadUInt()
			table.insert(ltabOwnerXH, ltab)
		end

		local gameLayer = GameScene:sharedGameScene():GetGameLayer()
		local GameLayer = tolua.cast(gameLayer, "CCLayer")
		local xianhualayer = GameLayer:getChildByTag(Tag_XIANHUA)
		if(xianhualayer) then
			xianhualayer:loadShopSendData(ltabOwnerXH)
		end
	elseif op == 4 then
--赠送鲜花
		local ltabSend = {}
		ltabSend.itemId = stream:ReadUShort()
		ltabSend.num = stream:ReadUShort()
		ltabSend.roleId = stream:ReadUInt()
		local success = stream:ReadByte()
		if success == 1 then
            --更新数据

            local item = LItemMgr:getItem(ltabSend.itemId)
            local itemname = item:Getm_name()
            
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, string.format(GUITips.RSI_XIANHUA_GIVE_SUC, itemname, ltabSend.num))
            this:SendMsg(LGameMsg.m_scrollTipsMsg)

            LGameMsg.m_netDealMsg:Change(LUIGiveGiftEvent.updateAfterGiveUI, ltabSend.itemId)
            this:SendMsg(LGameMsg.m_netDealMsg)

		else
			local msg = stream:ReadString()
			LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, msg)
            this:SendMsg(LGameMsg.m_scrollTipsMsg)
		end
	elseif op == 5 then
--获取赠送记录
		local tabRecoed = {}
		tabRecoed.recordType = stream:ReadByte()
		tabRecoed.recordArr = {}
		local success = stream:ReadByte()
		if success == 1 then
			local recordNum = stream:ReadByte()
			for i = 1, recordNum do
				local tab = {}
				tab.buf = stream:ReadString()
				table.insert(tabRecoed.recordArr, tab)
			end
--更新UI			
            LGameMsg.m_netDealMsg:Change(LUIGiveGiftEvent.updateXianHuaRecord, tabRecoed)
            this:SendMsg(LGameMsg.m_netDealMsg)
		else
			local msg = stream:ReadString()
			TipsMgr:GetInstance():SetCenterTip(msg)

		end
    -- elseif op == 6 then
    --     rsp.myrank.my_rank = stream:ReadUInt()
    --     rsp.myrank.my_id = stream:ReadUInt()
    --     rsp.myrank.my_name = stream:ReadString()
    --     rsp.myrank.my_meili = stream:ReadUInt()
    --     rsp.myrank.my_title = stream:ReadUInt()

    --     local len = stream:ReadByte()
    --     rsp.len = len
    --     for i = 1, len do 
    --         local temp = {}
    --         temp.rank = stream:ReadUInt() 
    --         temp.role_id = stream:ReadUInt() -- 会长名字
    --         temp.info_1  = stream:ReadString()
    --         temp.info_2 = stream:ReadUInt()
    --         temp.info_3 = stream:ReadUInt()

    --         if temp.role_id == LRoleDataMgr.MyHeroInfo.id then
    --             rsp.myrank.my_rank = temp.rank
    --             rsp.myrank.my_title = temp.info_3
    --         end
    --         table.insert(rsp.rankdata, temp)
    --     end
    --     LGameMsg.m_netDealMsg:Change(LUIXianHuaRankEvent.XianHuaRankListInfo, rsp)
    --     this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 6 then
        --新的鲜花排行榜
        rsp.type = stream:ReadByte()
        rsp.round = stream:ReadByte() --当前是第几届， 0 代表没有任何数据
        rsp.len = stream:ReadByte() 
        for i=1, rsp.len do
            local temp = {}
            temp.rank = stream:ReadUInt()
            temp.role_id = stream:ReadUInt()
            temp.info_1 = stream:ReadString() --名字
            temp.info_2 = stream:ReadUInt()   --魅力值
            temp.info_3 = stream:ReadWord()   --称号
            table.insert(rsp.rankdata, temp)
        end
--        ------dump(rsp, "xianhua list 66666")
        LGameMsg.m_netDealMsg:Change(LUIXianHuaRankEvent.XianHuaRankListInfo, rsp)
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 7 then
--获取鲜花商店列表
        local flowerNum = stream:ReadUInt()
        local ltabShopData = {}
        local shopFlower = {}
        for i = 1, flowerNum do
            local flowerData = LXianhuaShopData:New()
            flowerData.type = 1
            flowerData.id = stream:ReadUInt()
            flowerData.buy_type = stream:ReadUInt()
            flowerData.price = stream:ReadUInt()
            flowerData.meili = stream:ReadUInt()
            flowerData.qinmi = stream:ReadUInt()
            table.insert(shopFlower, flowerData)
        end
        ltabShopData.FlowerShopData = shopFlower

        local myFlowerNum = stream:ReadUInt()
        local myList = {}
        for i = 1, myFlowerNum do
            local shopData = LXianhuaShopData:New()
            shopData.id = stream:ReadUInt()
            shopData.num = stream:ReadUInt()
            shopData.meili = stream:ReadUInt()
            shopData.qinmi = stream:ReadUInt()
            table.insert(myList, shopData)
        end
        ltabShopData.myList = myList

        local caiDaiNum = stream:ReadByte()
        -- --print("caiDaiNum ===>", caiDaiNum)
        for i=1, caiDaiNum do
            local gift = LXianhuaShopData:New()
            gift.type = 2
            gift.id = stream:ReadUInt()
            gift.sendScore = stream:ReadUInt()
            gift.getScore = stream:ReadUInt()
            gift.num = LRoleDataMgr.Equip:CountItemNumById(gift.id)
            table.insert(shopFlower, gift)
        end
        -- ----dump(ltabShopData, "ltabShopData===>")
        LGameMsg.m_netDealMsg:Change(LUIGiveGiftEvent.updateXianHuaShop, ltabShopData)
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 8 then
        local sucData = {}
        sucData.id = stream:ReadWord()
        sucData.num = stream:ReadWord()
        sucData.roleId = stream:ReadUInt()
        local errorCode = stream:ReadByte()
        -- --print("id num=", id, num, roleId, errorCode)
        if errorCode < 1 then
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
        else
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
            Utils:SendMsg(LUIGiveGiftEvent.updateUIAfterSendGift, sucData)
        end
    end
end

function LuaNetRecvdMsg.DealMsgSystemTips(stream)
    local msg = stream:ReadString()
    if #msg > 0 then
        local isInHighCangBaoTu = LRoleDataMgr.IsInHighTreasuer
    --百花礼盒
        local isShowRandPetUI = LRoleDataMgr.m_isShowRandPetUI
        if not isInHighCangBaoTu and not isShowRandPetUI then
            if LRoleDataMgr:GetDelayShowAward() then
                LRoleDataMgr:InsertDelayAwardData(2, msg)
            else
                Utils:ShowScrollTips(msg,true)
            end
        else
            LRoleDataMgr.IsHighTreasuerMsg = msg
        end
    end
end



-- ---------------------------
-- 处理邮件消息
function LuaNetRecvdMsg.DealMsgQueryMails(s)

    local op = s:ReadByte() -- 类型
    --print("DealMsgQueryMails",op)
    if op == 0 then   --打开信使
        LGameMsg.m_netDealMsg:Change(LUIMailEvent.OpenMail, op)
        this:SendMsg(LGameMsg.m_netDealMsg)
    end

    if op == 1 then
        -- ================
        -- 服务器回复邮件发送的结果
        local rspInfo = {}
        rspInfo.errcode  = s:ReadByte()
        rspInfo.errmsg = s:ReadString()

        LGameMsg.m_netDealMsg:Change(LUIMailEvent.SendMail, rspInfo)
        this:SendMsg(LGameMsg.m_netDealMsg)
    end

    if op == 2 then
        local rsp = {}
        local mails_len = s:ReadByte()
        print("mails_len",mails_len)
        -- if mails_len > 0 then
        --     for i = 1, mails_len do
        --         local m = LMailData:New()
        --         m.id = s:ReadUInt() -- 邮件id
        --         m.from_id =  s:ReadUInt()
        --         m.from_name = s:ReadString()
        --         m.money = s:ReadUInt()
        --         m.yuanbao = s:ReadUInt()
        --         m.bdyuanbao = s:ReadUInt()
        --         m.shenhun = s:ReadUInt()
        --         m.endTime = s:ReadUInt()
        --         local itemNum = s:ReadByte()
        --         for i = 1, itemNum do
        --             table.insert(m.itemNum, itemNum)
        --             local item = LPItem:New()
        --             LuaNetRecvdMsg.ReadItemData(item, s)
        --             if item.m_id >= 0 then
        --                 table.insert(m.item, item)
        --             end
        --         end

        --         local petNum = s:ReadByte();
        --         for i = 1, petNum do
        --             local pid = s:ReadWord()
        --             if pid > 0 then 
        --                 local data = LPetData:New(pid)
        --                 LuaNetRecvdMsg.ReadPetInfo(data, s)
        --                 table.insert(m.pet, data)
        --             end
        --         end

        --         local otherNum = s:ReadByte()
        --         for i=1, otherNum do
        --             local otherItem = {}
        --             otherItem.m_id = s:ReadWord()
        --             otherItem.m_num = s:ReadUInt()
        --             table.insert(m.otherItems, otherItem)
        --         end

        --         local petEquipNum = s:ReadByte()
        --         for i=1, petEquipNum do
        --             local petEquip = LPetEquipInfo:New()
        --             this.ReadPetEquipData(petEquip, s)
        --             table.insert(m.petEquips, petEquip)
        --         end

        --         m.message = s:ReadString()
        --         table.insert(rsp, m)
                
        --     end
        -- end

        --邮件改
        if mails_len > 0 then
            for i = 1, mails_len do
                local m = LMailData:New()
                m.id = s:ReadUInt() -- 邮件id
                m.from_id =  s:ReadUInt()
                m.from_name = s:ReadString()
                m.endTime = s:ReadUInt()
                m.message = s:ReadString()

                local item = {}
                local num = s:ReadByte()
                for i=1, num do
                    local arr = LuaNetRecvdMsg.ReadCommonReward(s)
                    table.insert(item, arr)
                end
                m.item = item
                dump(m, "DealMsgQueryMails ============ 111111111111111111 >")
                table.insert(rsp, m)
            end
        end

        LRoleDataMgr.Social.NewMailData = rsp
--        Utils:--------dump(rsp)
        Utils:SendMsg(LUIMailEvent.QueryMailList)

        --检测社交红点
        -- LRedDotCheckMgr:SocialCheck()
    end 

    if op == 3 then --收信结果
        local rsp =  Utils:deepCopy(LRoleDataMgr.Social.NewMailData)
        local id  = s:ReadUInt()
        local delAll = s:ReadByte()
        local errcode = s:ReadByte()
        local errmsg = s:ReadString()

        if errcode == 0 then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, errmsg)
            this:SendMsg(LGameMsg.m_scrollTipsMsg)

            if delAll then
                LuaNetSendMsg:QueryMails(2)
            end
        else
            if delAll == 0 then
                local rspNum = #rsp
                for i = 1, rspNum do
                    if rsp[i].id == id then
                        --保存邮件
                        local userId = LRoleDataMgr.MyHeroInfo.id
                        LRoleDataMgr.Social:saveMail(0, userId, id, rsp[i])
                        LRoleDataMgr.Social:delNewMailData(id)
                    end
                end
                Utils:SendMsg(LUIMailEvent.QueryMailList)
            elseif delAll == 1 then
                local updateList = true
                local rspNum = #rsp
                for i = 1, rspNum do
                    if rsp[i].id == id then
                        --保存邮件
                        local userId = LRoleDataMgr.MyHeroInfo.id
                        LRoleDataMgr.Social:saveMail(0, userId, id, rsp[i])
                        LRoleDataMgr.Social:delNewMailData(id)
                    elseif #rsp[i].item > 0 then
                        LuaNetSendMsg:SaveMails(rsp[i].id, 1)
                        updateList = false
                        break
                    elseif #rsp[i].pet > 0 then
                        LuaNetSendMsg:SaveMails(rsp[i].id, 1)
                        updateList = false
                        break
                    elseif rsp[i].money > 0 or rsp[i].yuanbao > 0 or rsp[i].bdyuanbao > 0 or rsp[i].shenhun > 0 then
                        LuaNetSendMsg:SaveMails(rsp[i].id, 1)
                        updateList = false
                        break
                    elseif #rsp[i].petEquips > 0 then
                        LuaNetSendMsg:SaveMails(rsp[i].id, 1)
                        updateList = false
                        break
                    elseif #rsp[i].otherItems > 0 then
                        LuaNetSendMsg:SaveMails(rsp[i].id, 1)
                        updateList = false
                        break
                    end
                end
                if updateList then 
                    Utils:SendMsg(LUIMailEvent.QueryMailList)
                end
            end

            -- if delAll == 1 then
            --     local updateList = true
            --     local rspNum = #rsp
            --     for i = 1, rspNum do
            --         if rsp[i].id == id then
            --             --保存邮件
            --             local userId = LRoleDataMgr.MyHeroInfo.id
            --             LRoleDataMgr.Social:saveMail(0, userId, id, rsp[i])
            --             LRoleDataMgr.Social:delNewMailData(id)
            --         elseif #rsp[i].item > 0 then
            --             LuaNetSendMsg:SaveMails(rsp[i].id, 1)
            --             updateList = false
            --             break
            --         elseif #rsp[i].pet > 0 then
            --             LuaNetSendMsg:SaveMails(rsp[i].id, 1)
            --             updateList = false
            --             break
            --         elseif rsp[i].money > 0 or rsp[i].yuanbao > 0 or rsp[i].bdyuanbao > 0 or rsp[i].shenhun > 0 then
            --             LuaNetSendMsg:SaveMails(rsp[i].id, 1)
            --             updateList = false
            --             break
            --         elseif #rsp[i].petEquips > 0 then
            --             LuaNetSendMsg:SaveMails(rsp[i].id, 1)
            --             updateList = false
            --             break
            --         elseif #rsp[i].otherItems > 0 then
            --             LuaNetSendMsg:SaveMails(rsp[i].id, 1)
            --             updateList = false
            --             break
            --         end
            --     end
            --     if updateList then 
            --         LuaNetSendMsg:QueryMails(2)
            --     end
                
            -- else
                
            --     local data = GUITips.RSI_MDSI_MSGI14
            --     local function okCallback()
            --         LuaNetSendMsg:QueryMails(2)                   --请求邮件列表
            --     end
            --     local function cancelCallback()
                    
            --     end
            --     Utils:ShowDialogOKCancel(data, okCallback, cancelCallback)
            -- end

        end

--        LGameMsg.m_netDealMsg:Change(LUIMailEvent.SaveMail, rsp)
--        this:SendMsg(LGameMsg.m_netDealMsg)
    end  

    -- if op == 4 then --已读邮件服务端删除
    --     LGameMsg.m_netDealMsg:Change(LUIMailEvent.ReadMail)
    --     this:SendMsg(LGameMsg.m_netDealMsg)
    -- end

    Utils:SetRedDotState(RedDotDef.ID.MailNew, LRedDotCheckMgr:MailRedCheck());

--移到统一的红点协议里面
--     if op == 5 then --收到新邮件
--         LGameMsg.m_netDealMsg:Change(LUIMailEvent.NewMail)
--         this:SendMsg(LGameMsg.m_netDealMsg)
-- --新邮件小红点
--         LRedDotCheckMgr:newMailCheck()
--     end

end

--function LuaNetRecvdMsg.DealMsgSystemTips(stream)
--    msg = stream:ReadString()
--	LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
--    this:SendMsg(LGameMsg.m_scrollTipsMsg)
--end

function LuaNetRecvdMsg.DealMsgCopyInfo(stream)
    local op = stream:ReadByte()
	if op == 2 then
        this.DealCopyOp2(stream)
    elseif op == 6 then
		this.DealCopyDropTips(stream)
    elseif op == 13 then
        this.DealCopyEnterTimes(stream)
    elseif op == 11 then --请求副本列表
        this.DealQueryCopyList(stream)
    elseif op == 12 then
        this.DealEnterCopy(stream)
        LuaNetSendMsg:QueryCopy(13)
    -- elseif op == 17 then --宠物副本结算广播
    --     this.DealPetCopyAwardBroadcast(stream)
    -- elseif op == 15 then --金币副本结算
    --     this.DealGoldCopyAward(stream)
    elseif op == 18 then --潜能副本结算
        this.DealPotentialCopyAward(stream)
    elseif op == 19 then --扫荡信息查询
        this.DealQueryCopySweep(stream)
    elseif op == 20 then --扫荡请求
        this.DealCopySweep(stream)
    elseif op == 21 then --取消扫荡
        this.DealCancelCopySweep(stream)
    elseif op == 22 then --扫荡奖励信息
        this.DealCopySweepAward(stream)
    elseif op == 23 then --单次扫荡信息
        this.DealSingleCopySweepAward(stream)
    elseif op == 15 or op == 17 or op == 25
        or op == 26 or op == 27 or op == 32
        or op == 34 or op == 33 or op == 14 then --强化副本，升阶副本 淬炼副本 炼化副本 宠铠结算 天书副本结算 宠物副本结算
        this.DealNormalCopySweepAward(stream, op)
    elseif op == 30 then --宠物副本结算
        this.DealSweepSpeedUp(stream)
    -- elseif op == 33 then --宠物副本结算广播
    --     this.DealPetCopyAward(stream)
    end
end

--[[
读取奖励物品信息
]]
function LuaNetRecvdMsg.ReadItemInfo(stream, ItemIds, ItemVals)
    local num = stream:ReadByte()
    for i=1,num do
        local arr = LuaNetRecvdMsg.ReadCommonReward(stream);
        -- local id = stream:ReadWord()
        -- local itemNum = stream:ReadUInt()
        ItemIds[i] = arr[1]
        if arr[1] == AppDef.RewardItem.RD_ITEM_EQUIP
        or arr[1] == AppDef.RewardItem.RD_ITEM_PET
        or arr[1] == AppDef.RewardItem.RD_ITEM_PET then
            ItemVals[i] =  arr[2]
        else
            ItemVals[i] =  arr[3]
        end
    end
end

--[[
获取解析颜色idx
]]
function LuaNetRecvdMsg.GetColorIndex(idx)
    local ARY_I = {3,2,7,8,4,5,1,9}
    if dx>=0 and idx<8 then idx = 0 end
    return ARY_I[idx]
end


--[[
副本扫荡奖励解析
]]
function LuaNetRecvdMsg.AnalysisAwardStr(awardsrr)
    local singleStr = ""
    local tmpStr
    local Split = "|"
    local item_num = 0
    local finish = 0
    local offset = 1
    local type = 0
    -- while true do
    --     finish, type = Utils:ReadBeforeCharInt(awardsrr, Split, offset))
    --     if type = -1 then
    --         singleStr = singleStr..GUITips.RIS_LEFTUI_MSG90
    --         finish, tmpStr = Utils:ReadBeforeCharStr(awardsrr,Split, offset)
    --         singleStr = singleStr..tmpStr
    --     elseif type = -2 then
    --         singleStr = singleStr..GUITips.RIS_LEFTUI_MSG91
    --         finish, tmpStr = Utils:ReadBeforeCharStr(awardsrr,Split, offset)
    --         singleStr = singleStr..tmpStr
    --         finish = string.find(singleStr, Split, offset)
    --         singleStr.appfinish(string(CCSTR_FMT2("[c%d]%s[c]",Opr::GetColorIndex(atoi(awardsrr.substr(off,finish - off).c_str())-1),tmpStr.c_str())))
    --     elseif type = -3 then
    --         singleStr.appfinish(RES_STR(DataConsts::RIS_LEFTUI_MSG92))
    --         finish = Utils:ReadBeforeCharStr(awardsrr,Split,off,tmpStr)
    --         singleStr.appfinish(tmpStr)
    --         break
    --     elseif type = -4 then
    --         singleStr.appfinish(RES_STR(DataConsts::RIS_LEFTUI_MSG93))
    --         finish = Utils:ReadBeforeCharStr(awardsrr,Split,off,tmpStr)
    --         singleStr.appfinish(tmpStr)
    --     elseif type = -5 then
    --         if(item_num == 0)
    --             singleStr.appfinish(RES_STR(DataConsts::RIS_LEFTUI_MSG94))
    --         else
    --             singleStr.appfinish(A2U("、"))
    --         item_num++
    --         local id=0
    --         finish = Utils:ReadBeforeCharInt(awardsrr,Split,off,id)
    --         if(CItem *p = ITEM_MGR->getItem(id))
    --             singleStr.appfinish(p->m_name)
    --         else
    --             singleStr.appfinish(RES_STR(DataConsts::RIS_LEFTUI_MSG95))
    --         end
    --         off = finish+1
    --         singleStr.appfinish("*")
    --         finish = Utils:ReadBeforeCharStr(awardsrr,Split,off,tmpStr)
    --         singleStr.appfinish(tmpStr)
    --         break
    --     end
    --     finish = awardsrr.find(Split,off)
    -- end

    -- return singleStr
end

--[[
op == 2
]]
function LuaNetRecvdMsg.DealCopyOp2(stream)
    stream:ReadWord()
    stream:ReadByte()
    local msg = stream:ReadString()
    this.SetCenterTip(msg)
end

--[[
op == 6 掉落提示
]]
function LuaNetRecvdMsg.DealCopyDropTips(stream)
    local row = stream:ReadByte()
    if row == 1 then
        local id = stream:ReadWord()
        local msg = stream:ReadString()
        this.SetCenterTip(msg)
    end
end

--[[
13 日常副本进入次数
]]
function LuaNetRecvdMsg.DealCopyEnterTimes(stream, op)
    local num = stream:ReadByte()
    -- DATA_MGR->MainMenu.copyTime = 0
    for i=1,num do
        local id = stream:ReadWord()
        for k,v in pairs(LDataConstMgr.m_CopyData._CopyList) do
            if v.Id == id then
                v.MaxTimes = stream:ReadByte()
                v.CurTimes = stream:ReadByte()
                break
            end
        end
    end
    --LRedDotCheckMgr:MainInstancesCheck()
    Utils:SendMsg(LUIActivityEvent.RefreshInstancesCount)
end

--[[
op == 11 请求副本列表
]]
function LuaNetRecvdMsg.DealQueryCopyList(stream)
    local dropMsg
    local ItemId = 0
    local num = stream:ReadByte()
    local level = LRoleDataMgr.MyHeroInfo:Getlevel()
    LDataConstMgr.m_CopyData._CopyList = {}
    for i=1, num do
        local info = LCopyInfo:New()
        info.Id = stream:ReadWord()
        info.CopyName = stream:ReadString()
        info.EnterLevel = stream:ReadWord()
        info.CostTili = stream:ReadByte()
        info.MaxTimes = stream:ReadByte()
        local dropMsg = stream:ReadString()
        info.ItemId = Utils:LuaSplitNumnber(dropMsg, "|")
        info.CurTimes = stream:ReadByte()
        info.CopyType = stream:ReadByte()
        info.CanSweep = (stream:ReadByte() == 1)
        info.CopyLevel = stream:ReadByte()
        -- info.IsLocked = (info.CopyLevel <= level)
        info.Description = stream:ReadString()
        info.CostMoney   = stream:ReadUInt()
        info.JiLvSrc     = stream:ReadString()
        info.JiLv        = stream:ReadString()
        LDataConstMgr.m_CopyData:UpdateCopyData(info.Id,info)
    end
    LCopyData.IsOpenZhuZhan = stream:ReadByte()-- 1助阵，0不助阵
    LCopyData.SaoDangLevel = stream:ReadByte()-- 扫荡开启等级

    --LRedDotCheckMgr:MainInstancesCheck()

    LGameMsg.m_netDealMsg:Change(LUIActivityEvent.RefreshInstances)
    this:SendMsg(LGameMsg.m_netDealMsg)
end

--[[
op == 12
]]
function LuaNetRecvdMsg.DealEnterCopy(stream)
    local ms = stream:ReadByte()
    if ms == 0 then
        local idx = stream:ReadByte()
        msg = stream:ReadString()
        this.SetCenterTip(msg)
    end
end

--[[
op == 14 宠物副本结算
]]
function LuaNetRecvdMsg.DealPetCopyAwardBroadcast(stream)
end

--[[
op == 15 金币副本结算
]]
function LuaNetRecvdMsg.DealGoldCopyAward(stream)
    local cData = LCopyAwardData:New()
    cData.op = op
    cData.extraExp = stream:ReadUInt()
    cData.Money = stream:ReadUInt()
    this.ReadItemInfo(stream,cData.itemId,cData.itemVal1)
    -- Opr::ShowFBALayer(cData.ToStr())
end

--[[
op == 18 潜能副本结算
]]
function LuaNetRecvdMsg.DealPotentialCopyAward(stream)
    -- local cData = LCopyAwardData:New()
    -- cData.op = op
    -- cData.extraExp = stream:ReadUInt()
    -- cData.qianneng = stream:ReadUInt()
    -- Opr::ReadItemInfo(stream,cData.itemId,cData.itemVal1)
    -- Opr::ShowFBALayer(cData.ToStr())
end

--[[
op == 19 扫荡信息查询
]]
function LuaNetRecvdMsg.DealQueryCopySweep(stream)
    -- local copydata = LDataConstMgr.m_CopyData.SweepData
    -- copydata.sweepId = stream:ReadWord()
    -- local enterNum = stream:ReadByte()
    -- local enternum = stream:ReadByte()
    -- copydata.sigleSweepTime = stream:ReadWord()
    -- local level = stream:ReadWord()
    -- local needtili = stream:ReadByte()
    -- local awardStr = stream:ReadString()
    -- local num = enterNum - enternum
end

function LuaNetRecvdMsg.DealCopySweepStream(stream, id)
    LDataConstMgr.m_CopyData.SweepData = {}
    local copydata = LDataConstMgr.m_CopyData.SweepData
    copydata.sweepId = id
    copydata.items = {}
    local times = stream:ReadByte()
    for j=1,times do
        local item = LSweepCopyData:New()
        item.curTime = stream:ReadByte()

        local num = stream:ReadByte()
        for i=1,num do
            local it = {}
            it.awardType = stream:ReadWord()
            it.awardNum = stream:ReadUInt()
            table.insert(item.sweepAward, it)
        end
        table.insert(copydata.items, item)
    end
    table.sort(copydata.items, function(a, b) return a.curTime < b.curTime end)
    --------dump(copydata, "copydata--->")

    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Instances.CopyRewardUI",AppDef.UIType.SecondClassLayer)
    this:SendMsg(LGameMsg.m_initUIMsg)
end

--[[
op == 20 扫荡请求
]]
function LuaNetRecvdMsg.DealCopySweep(stream)
    local id = stream:ReadByte()
    local succ = stream:ReadByte()
    if succ == 0 then
        local msg = stream:ReadString()
        this.SetCenterTip(msg)
    else
        LuaNetRecvdMsg.DealCopySweepStream(stream, id)
        LuaNetSendMsg:QueryCopy(13)
    end
end

--[[
op == 21 取消扫荡
]]
function LuaNetRecvdMsg.DealCancelCopySweep(stream)
    -- local copydata = LDataConstMgr.m_CopyData.SweepData
    -- local val = stream:ReadByte()
    -- if val == 1 then
    --     copydata.isSweeping = false
    -- -- layer->ChangeButtonState(false) 
    -- -- if(copydata.leftSweepTimes != 0){ layer->ReLoadCopyInfo() }
    -- end
end

--[[
op == 22 扫荡奖励信息
]]
function LuaNetRecvdMsg.DealCopySweepAward(stream)
    -- local copydata = LDataConstMgr.m_CopyData.SweepData

    --     local SweepTime = 0
    --     copydata.isSweeping = true
    --     copydata.sweepId = stream:ReadWord()
    --     copydata.leftSweepTimes = stream:ReadByte()
    --     copydata.sigleSweepTime = stream:ReadWord()
    --     copydata.sigleSweepLeftTime = stream:ReadWord()
    --     local str = stream:ReadString()
end

--[[
op == 23 单次扫荡信息
]]
function LuaNetRecvdMsg.DealSingleCopySweepAward(stream)
    -- local copydata = LDataConstMgr.m_CopyData.SweepData
    --     copydata.isSweeping = true
    --     copydata.sweepId = stream:ReadWord()
    --     copydata.leftSweepTimes = stream:ReadByte()
    --     copydata.sigleSweepTime = stream:ReadWord()
    --     copydata.sigleSweepLeftTime = copydata.sigleSweepTime

    --     string str = stream:ReadString()
    --     string singleStr = Opr::AnalysisAwardStr(str)

    --     if(!singleStr.empty()){ copydata.sweepAward.push_back(singleStr) }--不为空时添加奖励信息

    --     if(CopySweepLayer *layer = GAMELAYER->GetCopySweepLayer())
    --     {
    --         if(copydata.leftSweepTimes == 0){ QueryCopy(21) }--如果完成所有扫荡 请求取消
    --         layer->ReLoadCopyInfo()
    --     }       
    --     DATA_MGR->MainMenu.copyTime--
    --     if(GameMenu* mainmenu = GAMELAYER->GetMainMenuLayer())
    --         mainmenu->SetGamePlayButtonNum(GameMenu::MTG_MINE_COPY)
end

--[[
op == 15  op == 17  op == 25  op == 26 op == 27  op == 32  op == 34
强化副本，升阶副本 淬炼副本 炼化副本 宠铠结算 天书副本结算
]]
function LuaNetRecvdMsg.DealNormalCopySweepAward(stream, op)
    local cData = LCopyAwardData:New()
    cData.op = op
    cData.extraExp = stream:ReadUInt()
    this.ReadItemInfo(stream, cData.itemId, cData.itemVal1)
    --------dump(cData, "=======================>")
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "FirstAward.FirstRewardUI",AppDef.UIType.PopWindow, {2, cData})
    this:SendMsg(LGameMsg.m_initUIMsg)
end

--[[
30 扫荡加速
]]
function LuaNetRecvdMsg.DealSweepSpeedUp(stream)
    -- local fbId = stream:ReadWord()
    --     local success = stream:ReadByte()
    --     string msg = stream:ReadString()
    --     TipsMgr::GetInstance()->SetCenterTip(msg)
    --     CopySweepLayer* layer = GAMELAYER->GetCopySweepLayer()
    --     if (success)
    --         layer->SetColdTime(0)
end

--[[
31 获取扫荡消耗
]]
function LuaNetRecvdMsg.DealQuerySweepCost(stream)
    -- local fbId = stream:ReadWord()
    --     local success = stream:ReadByte()
    --     string msg = stream:ReadString()
    --     TipsMgr::GetInstance()->SetCenterTip(msg)
    --     CopySweepLayer* layer = GAMELAYER->GetCopySweepLayer()
    --     if (success)
    --         layer->SetColdTime(0)
end

--[[
33 宠物副本结算
]]
function LuaNetRecvdMsg.DealPetCopyAward(stream)
    -- local cData = LCopyAwardData:New()
    --     cData.op = op
    --     DATA_MGR->Pet.petExtractInfo.clear()

    --     local petNum = stream:ReadByte()
    --     for(local i = 0i < petNumi ++)
    --     {
    --         PetShowInfo info                       --抽取宠物的信息
    --         info.petId = stream:ReadWord()       --我的宠物ID
    --         stream:ReadString(info.petName)
    --         info.petQuality = stream:ReadByte()  --品质
    --         info.petAvoluteStar = stream:ReadByte()
    --         info.bangding = stream:ReadByte()
    --         info.petType = stream:ReadByte()
    --         DATA_MGR->Pet.petExtractInfo.push_back(info)
    --     }
    --     if(petNum == 0)
    --         return op
    --     Opr::ShowFBALayer(cData.ToStr())
    -- }
end

function LuaNetRecvdMsg.DealMsgPetCopyInfo(stream)
    local op = stream:ReadByte()
    --------dump(op, "LuaNetRecvdMsg.DealMsgPetCopyInfo--->")
    if op == 1 then
        LDataConstMgr.m_CopyData._PetCopyList = {}
        local mineNum = stream:ReadByte()
        for i=1, mineNum do
            local info = LMineInfo:New()
            info.Id = stream:ReadByte()
            info.Name = stream:ReadString()
            --info.Description = DATA_CST->GetPetCopyDescById(info.Id)

			--读一个字节消耗类型0-金币 1-元宝
			info.costtype = stream:ReadByte()
            info.UseMoney = stream:ReadUInt()
            info.Notice = stream:ReadString()
            info.IsLock = (stream:ReadByte() == 1)
			info.canEnterTimes = stream:ReadByte()
			info.jilvSrc	= stream:ReadString()
			info.jiLv		= stream:ReadString()
			info.maxSweepTimes = stream:ReadByte() -- 增加扫荡功能
			info.ardSweepTimes = stream:ReadByte()-- 已扫荡次数
			info.isCleared	= stream:ReadByte() -- 增加是否通关该副本
			LDataConstMgr.m_CopyData:UpdatePetCopyData(info.Id, info)
        end
		local reSetNum = stream:ReadByte()
        --if(CopyLayer* layer = GAMELAYER->GetCopyMainLayer())
        --    layer->LoadMineList(DATA_MGR->Copy.GetPetCopyList(),reSetNum)
        LGameMsg.m_netDealMsg:Change(LUIActivityEvent.RefreshInstances)
        this:SendMsg(LGameMsg.m_netDealMsg)
        --LRedDotCheckMgr:MainInstancesCheck()
    elseif op == 2 then
        local type = stream:ReadByte()
        local success = stream:ReadByte()
        local msg = stream:ReadString()
        if success == 0 then
            this.SetCenterTip(msg)
        else
            for k,v in pairs(LDataConstMgr.m_CopyData._PetCopyList) do
                if v.Id == type then
                    if v.canEnterTimes ~= 0xff then
                        v.canEnterTimes = v.canEnterTimes - 1
                    end
                    break
                end
             end
            --不在这里删，mianUI在切换地图的时候判断删不删除
            -- LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Instances.InstancesMainUI")
            -- this:SendMsg(LGameMsg.m_initUIMsg)
            --LRedDotCheckMgr:MainInstancesCheck()
            Utils:SendMsg(LUIActivityEvent.RefreshInstancesCount)
		end
	elseif op == 3 then -- 宠物扫荡信息
		local type = stream:ReadByte()
		local info = LCopyData:GetPetCopyList()
		--local selInfo = info[type]
--		if(GameLayer *gameLayer = (GameLayer*)GAMELAYER)
--		{
--			{
--				CopySweepLayer* layer = gameLayer->ShowCopySweepLayer()
--				layer->SetPriority(-133)
--				layer->setSweepType(1) --宠物扫荡
--				layer->updatePetSweep(selInfo.Id)
--				local num = selInfo.maxSweepTimes - selInfo.ardSweepTimes
--				layer->SetMaxRound(num >= 5 ? 5 : num, 0)
--			}
--		}
	elseif op == 4 then
        local id = stream:ReadByte()
        local succ = stream:ReadByte()
        if succ == 0 then
            local msg = stream:ReadString()
            this.SetCenterTip(msg)
        else
            LuaNetRecvdMsg.DealCopySweepStream(stream, id)
            LuaNetSendMsg:QueryPetCopyList()
        end
	end
end

----商城
function LuaNetRecvdMsg.DealMsgShop(stream)
    local op = stream:ReadByte()
    -- print("LuaNetRecvdMsg.DealMsgShop op =>", op)
    if op == 1 or op == 3 then
        --将魂商店 op = 3 刷新
        local shopInfo = {}
        shopInfo.type = stream:ReadByte()
        -- print("DealMsgShop ===>", shopInfo.type, ShopDef.KP_SP.JIANGHUN )
        -- 2是将魂商店 3 竞技场商店
            shopInfo.errcode = stream:ReadByte()
            if shopInfo.errcode < 1 then
                local msg = stream:ReadString()
                Utils:ShowScrollTips(msg)
                return
            end
            shopInfo.rafreshTimes = stream:ReadUShort()  --刷新次数
            shopInfo.freeTimes = stream:ReadByte()    --免费次数
            shopInfo.freeAddSec = stream:ReadUShort() --免费刷新时间
            shopInfo.itemList = {}
            local num = stream:ReadByte()
            --print("DealMsgShop num ===== 11111 >", num, shopInfo.type)
            for i=1, num do
                local data = {}
                data.index = stream:ReadByte()
                data.id = stream:ReadUShort()
                data.buyTimes = stream:ReadUShort()
                table.insert(shopInfo.itemList, data)
            end
            --dump(shopInfo, "shopInfo === 1111 ==>")
            PetkaPaiManager:InitShopData(shopInfo.type, shopInfo)
            if shopInfo.type > 1 then
                Utils:SendMsg(LUIShopEvent.UpdateKaPaiShop, shopInfo)
                if shopInfo.type == ShopDef.KP_SP.JIANGHUN then
                    LRedDotCheckMgr:JiangHunShopCheck()
                end

            else
                ------dump(vecNormalGoods, "========= 1111111111111 ====>")
                LGameMsg.m_netDealMsg:Change(LUIShopEvent.ReloadShopData, {normalGoods=shopInfo, shopType=1})
                this:SendMsg(LGameMsg.m_netDealMsg)
            end
    elseif op == 2 then
        local markettype = stream:ReadByte()
        local index = stream:ReadWord()
        local num = stream:ReadUShort()
        local used = stream:ReadByte()
        
        local succ = stream:ReadByte()
        --print("markettype ==>", markettype, num, index, succ)
        if succ > 0 then
            Utils:ShowScrollTips(GUITips.RSI_MDSI_MSGI44)
            local info = {}
            info.buyTimes = stream:ReadUShort() --购买次数
            info.buyType = stream:ReadUShort() --类型
            info.buyNum = stream:ReadUInt() --购买数量
            info.index = index
            info.shopType = markettype
            ----dump(info, "DealMsgShop ===================>")
            PetkaPaiManager:SetShopCnt(info.shopType,info.buyType,info.index,info.buyTimes)

            --刷新数据
            if markettype == 1 then
                local ShopDef = require("View.Shop.ShopDef")
                LuaNetSendMsg:QueryKaPaiShopUI(1, ShopDef.KP_SP.YUANBAO)
            else
                Utils:SendMsg(LUIShopEvent.UpdateShopUIAfterBuySuc, info)
            end
			--购买成功消息
            Utils:SendMsg(LUILogicEvent.buyItemSucEvent)
        else --失败
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
        end
    elseif op == 4 then
        --请求商城道具已购买次数
        local sType = stream:ReadByte()
        local itemId = stream:ReadWord()
        local suc = stream:ReadByte()
        if suc == 0 then
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
            return
        end
        local buyCnt = stream:ReadWord()
        LRoleDataMgr:SetShopTempInfo(itemId,buyCnt)
        LGameMsg.m_netDealMsg:Change(LUIShopEvent.QueryBuyCntResult)
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 5 then
        local result=stream:ReadByte()
        if result == 1 then
            local type = stream:ReadByte()
            --类型为1是物品，2是宠物
            if type == 2 then
                local pid = stream:ReadWord()
                local petInfo = petInfo:New()
                --读取宠物

                LuaNetRecvdMsg.ReadPetInfo(petInfo, stream)
                petInfo.id = pid

                local cardInfo = LDataConstMgr:GetMyCardInfo()
                table.insert(cardInfo.AwardPet, petInfo)
            end
        end

        local msg = stream:ReadString()
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, msg)
        this:SendMsg(LGameMsg.m_scrollTipsMsg)

        if result == 1 then
            local itemId = stream:ReadWord()
            local count = stream:ReadByte()
            if count == 0 then
                --QueryMarketInfo(4,0)
                LuaNetSendMsg:QueryMarketInfo(4,0)
            else
                --更新界面
                local info = {}
                info.id = itemId
                info.canBuyNum = count
                LGameMsg.m_netDealMsg:Change(LUIShopEvent.UpdateCountByItemId, info)
                this:SendMsg(LGameMsg.m_netDealMsg)

            end
        end
    elseif op == 6 then--神秘商店
        local info = LShopMysteryInfo:New()
        info.time = stream:ReadUInt()
        info.num  = stream:ReadByte()
        for i=1,info.num do
            local itemInfo = LSMItemInfo:New() 
            itemInfo.vipLimit =  stream:ReadByte()
            if itemInfo.vipLimit == 0 then
                itemInfo.id       =   stream:ReadWord()
                itemInfo.itemId   =   stream:ReadWord()
                itemInfo.petEquipId = stream:ReadWord()
                itemInfo.petEquipStar = stream:ReadByte()
                itemInfo.itemNum  =   stream:ReadByte()
                itemInfo.price    =   stream:ReadWord()
            end
            -- ------dump(itemInfo, "itemInfo---->")
            table.insert(info.ItemData, itemInfo)
        end
        LGameMsg.m_netDealMsg:Change(LUIShopEvent.ReloadShopData, {normalGoods=info, limitedGoods={}, shopType=6})
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 7 or op == 24 then
        local result = stream:ReadByte()
        local msg= stream:ReadString()
       -- ----print("===================",msg)
        Utils:ShowScrollTips(msg)
        if(result == 1) then
            local logMsg = stream:ReadString()
            local index = stream:ReadByte()
            local count = stream:ReadByte()

            LGameMsg.m_netDealMsg:Change(LUIShopEvent.ReloadShopCount, {index=index, count=count})
            this:SendMsg(LGameMsg.m_netDealMsg)
        end
    elseif op == 8 then
        local result = stream:ReadByte()
        if result ~= 1 then
            local errMsg = stream:ReadString()
            Utils:ShowScrollTips(errMsg)
        end
    elseif op == 11 then--砸蛋积分商店
        local score = stream:ReadUInt()
        LRoleDataMgr.MyHeroInfo:GetDetailData():setZaDanScore(score)

        local normalLoop = stream:ReadWord()
        local vecLimitedGoods = {}
        local vecNormalGoods = {}
		print("==========================>>>>>>>>>>>>>>>>>>", score,normalLoop)
        for k=1,normalLoop do --常规物品
            local  norGoods = LMarketGoodsInfo:New()
            norGoods.id = stream:ReadUInt()
            norGoods.petEquipId = stream:ReadWord()
            norGoods.petEquipStar = stream:ReadWord()
            norGoods.price =  stream:ReadUInt()
            norGoods.coupon = stream:ReadUInt()
            norGoods.label = stream:ReadUInt()
            norGoods.leftTime = stream:ReadUInt()
            table.insert(vecNormalGoods, norGoods)
        end
        LGameMsg.m_netDealMsg:Change(LUIShopEvent.ReloadShopData, {normalGoods=vecNormalGoods, limitedGoods=vecLimitedGoods, shopType = 17})
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 12 then--砸蛋积分商店兑换
        local succ = stream:ReadByte()
        if succ == 0 then
            Utils:ShowScrollTips(stream:ReadString())
            return
        end
        local score = stream:ReadUInt()
        LRoleDataMgr.MyHeroInfo:GetDetailData():setZaDanScore(score)
        Utils:ShowScrollTips(stream:ReadString())
    elseif op == 15 then
        local xianshiLoop = stream:ReadUInt()
        local vecLimitedGoods = {}
        local vecNormalGoods = {}
        for k=1,xianshiLoop do-- 常规物品
            local  norGoods = LMarketGoodsInfo:New()
            norGoods.price =  stream:ReadUInt()
            norGoods.id = stream:ReadUInt()
            norGoods.num = stream:ReadUInt()
            table.insert(vecNormalGoods, norGoods)
        end
        ----dump(vecNormalGoods, "========= 1111111111111 ====>")
        LGameMsg.m_netDealMsg:Change(LUIShopEvent.ReloadShopData, {normalGoods=vecNormalGoods, limitedGoods=vecLimitedGoods, shopType=15})
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 23 then--神魂商店
        local info = LShopMysteryInfo:New()
        info.time = stream:ReadUInt()
        info.num  = stream:ReadByte()
        for i=1,info.num do
            local itemInfo = LSMItemInfo:New()
            itemInfo.vipLimit = 0
            itemInfo.id       =   stream:ReadWord()
            itemInfo.itemId   =   stream:ReadWord()
            itemInfo.itemNum  =   stream:ReadByte()
            itemInfo.price    =   stream:ReadWord()
            table.insert(info.ItemData, itemInfo)
        end
        LGameMsg.m_netDealMsg:Change(LUIShopEvent.ReloadShopData, {normalGoods=info, limitedGoods={}, shopType=16})
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 25 then--神魂商店刷新
    end
    Utils:RemoveWaiting(LuaNetCmd.MSG_CLIENT_MARKET)
end

function LuaNetRecvdMsg.DealUpdateClientCST(stream)
--    local num = stream:ReadWord()
--	for i=1, num do
--		--typeId (1-表示字符串常量 其他暂未使用)
--		local typeId = stream:ReadUInt()
--		local Msg = stream:ReadString()

--		--更新字符串常量
--		if typeId == 1 then
--			-- 替换\r\n为\r, 仅支持Window下文件格式
--			Msg = string.gsub(Msg, "\r\n", "\r")
--            local start
--            local finish
--            local id
--			local idx = 1
--			local idxmapStr = ""
--			while idx ~= nil do
--				start, finish = string.find(Msg, "|", idx)
--				if start == nil then
--					break
--                end
--                mapStr = string.sub(Msg, idx, start - 1)
--                id = tonumber(mapStr)

--                idx = finish+1
--				start, finish = string.find(Msg, "\r", idx)
--                mapStr = string.sub(Msg, idx, start - 1)
--                idx = finish
--			end
--		end
--	end
end

--[[
VIP信息 
op:1查询信息2购买月卡3领取奖励
4我的vip信息5vip相关副本次数更新
6清除副本冷却时间7领取元宝
]]
function LuaNetRecvdMsg.DealMsgVIPInfo(stream)

    local op = stream:ReadByte()
    ------print("DealMsgVIPInfo =======>> op =", op)
    
    local msg = ""
   
    if op == 1 then
        this.DealQueryVIPInfo(stream)
    elseif op == 2 then
        this.DealBuyMonthCard(stream)
    elseif op == 3 then
        this.DealGetGiftBag(stream)
    elseif op == 4 then
        this.DealMineVIPInfo(stream)
    elseif op == 5 then
        this.DealVIPCopyInfo(stream)
    elseif op == 6 then
        this.DealClearCopyCD(stream)
    elseif op == 7 then
        this.DealGetCoin(stream)
    elseif op == 8 then
        this.DealGetMonthCardCoin(stream)
    elseif op == 9 then
        this.DealGetMonthCardInfo(stream)
    end
end

--[[
VIP信息 
op:1查询信息
]]
function LuaNetRecvdMsg.DealQueryVIPInfo(stream)
    --LDataConstMgr:GetVipAwardInfo()
    local vipNum = stream:ReadByte()
    for i=1, vipNum do
        local info = LMCAwardInfo:New()
        info.CardPrice = stream:ReadUInt()
        for j=1, 3 do
            local aid = stream:ReadWord()
            local anum = stream:ReadUInt()
            if aid > 0 then -- <=0没有奖励
                if aid < AppDef.AwrdItem.AWRD_ITEM_PET then
                    table.insert(info.AwardId, aid)
                    table.insert(info.AwardNum, anum)
                elseif aid == AppDef.AwrdItem.AWRD_ITEM_PET then--宠物
                    local pid = stream:ReadWord()
                    local data = LPetData:New(pid)
                    LuaNetRecvdMsg.ReadPetInfo(data, stream)
                    table.insert(info.AwardPet, data)
                end
            end
        end
        this.GetVipRightByLevel(i,info.Vipright)
        LDataConstMgr.m_VipAwardInfo[i]= info
    end

    local cardInfo = LDataConstMgr:GetMyCardInfo()
    local num = stream:ReadByte()
    cardInfo.mcAwardInfo = {}
    for i=1, num do
        local data = {}
        data.mcType = stream:ReadByte() --月卡类型 1、月卡 2、终生月卡 4临时月卡
        data.awardType = stream:ReadWord() --奖励类型
        if data.awardType ~= 0 then
            data.awardValue = stream:ReadWord()  --称号Id
        end
        data.awardPerValue = stream:ReadUInt() --购买后的奖励数量
        table.insert(cardInfo.mcAwardInfo, data)
    end

--    ------dump(cardInfo, "mcCard Info =========>>")

    --DATA_MGR->MainMenu.canRewardMonthCard = stream:ReadByte()  --月卡标记
    -- for i=1, #AppDef.VipRightNums do
    --     cardInfo.Vipright[i] = AppDef.VipRightNums["VIP_RIGHT_NUM"..i]
    -- end

    this.GetVipRightByLevel(16,cardInfo.Vipright)

    LGameMsg.m_netDealMsg:Change(LUIPlatinumEvent.updateAwardUI)
    this:SendMsg(LGameMsg.m_netDealMsg)
end

--[[
VIP特权信息
]]
function LuaNetRecvdMsg.GetVipRightByLevel(lv, Vipright)
    local headStr = "RSI_VIP_RIGHT"..lv.."_"
    for i=1, AppDef.VipRightNums["VIP_RIGHT_NUM"..lv] do
        Vipright[i] = GUITips[headStr..i]
    end
end

--[[
VIP信息 
op:2购买月卡
]]
function LuaNetRecvdMsg.DealBuyMonthCard(stream)
    local scs = stream:ReadByte()
    local msg
    if scs == 0 then
        msg = stream:ReadString()
        -- Utils:ShowScrollTips(msg)
--打开元宝不足界面
        Utils:OpenNotEnoughGold()
    elseif scs == 1 then
        stream:ReadByte()
        msg = stream:ReadString()
        Utils:ShowScrollTips(msg)

        LGameMsg.m_netDealMsg:Change(LUIPlatinumEvent.updateBuyPlatinum)
        this:SendMsg(LGameMsg.m_netDealMsg)
    end
end

--[[
VIP信息 
op:3领取奖励
]]
function LuaNetRecvdMsg.DealGetGiftBag(stream)
    --领取礼包成功
    local scs = stream:ReadByte()
    if scs == 0 then
        -- stream:ReadString(msg)
        -- TipsMgr::GetInstance()->SetCenterTip(msg)
        msg = stream:ReadString()
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, msg)
        this:SendMsg(LGameMsg.m_scrollTipsMsg)
--        this.SetCenterTip(msg)
    else
    -- 刷新vip信息
        -- if(VipLayer* vipLayer = GAMELAYER->GetVipLayer())
        -- {
        --     if (USELUAENV && OPENVIPLUA)
        --     {
        --         LuaMgr::GetInstance()->executeGlobalFunction("VipLayer_reLoadMyVipInfo")
        --     }else
        --     {
        --         vipLayer->reLoadMyVipInfo()
        --     }
        -- }

        
    end
     LuaNetSendMsg:QueryVipInfo(1) --重新请求vip中月卡状态
end

--[[
VIP信息 
op:4我的vip信息
]]
function LuaNetRecvdMsg.DealMineVIPInfo(stream)

    local info = LRoleDataMgr.MyHeroInfo.MyVIPInfo
    local vipLevel = stream:ReadByte()
    -- vip升级清空神秘商店商品信息
    if vipLevel>info.vipLevel then
        LRoleDataMgr.MysteryInfo.ItemData = {}
    end
    local lastVipType = info.mcType
    info.vipLevel = vipLevel
    LRoleDataMgr.MyHeroInfo.vipLevel = vipLevel
    info.vipMoney = stream:ReadUInt()
    info.totalRecharge = stream:ReadUInt() --玩家累计充值
    info.totalRecharge = info.totalRecharge / 200
    --print("info.totalRecharge ====", info.totalRecharge)
    info.mcType = stream:ReadByte()
    --LRoleDataMgr.MyHeroInfo.m_CardBuffer=1

    if bit.band(lastVipType, 8) > 0 then
      if info.mcType == 0  then
         LRoleDataMgr.MyHeroInfo.m_CardBuffer=1
       -- Utils:ShowBuffTips(AppDef.BuffType.PlatinumMC) 
       -- Utils:ShowScrollTips(GUITips.RSI_MONTHCARDEN_TIPS2)
      end
    end
    LRoleDataMgr.MyHeroInfo.m_BufferList[AppDef.BuffType.ExperienceMC]=nil
    LRoleDataMgr.MyHeroInfo.m_BufferList[AppDef.BuffType.PlatinumMC]=nil

    --领取状态(1、月卡 2、永久月卡 4、临时月卡)
    local mcGiftState = stream:ReadByte()
    info.mcGiftMonState = bit.band(mcGiftState, 1) <= 0 --月卡领取状态
    info.mcLifeGiftMonState = bit.band(mcGiftState, 2) <= 0  --终身月卡领取状态
    info.isHasLmCard = bit.band(info.mcType, 2) > 0 --终身月卡
    info.isHasMcCard = bit.band(info.mcType, 1) > 0 --月卡
    info.isHasMcCardTemp = bit.band(info.mcType, 8) > 0 --临时月卡
--    ----print("DealMineVIPInfo =========>", mcGiftState, info.mcGiftMonState, info.mcLifeGiftMonState, info.isHasLmCard, info.mcType)

    info.mcLeftTime = stream:ReadUInt()
--    ----print("info.mcLeftTime --------------->>", info.mcLeftTime)
    if info.isHasMcCard or info.isHasLmCard then
        local data = LBuffData:New()
        data.type=AppDef.BuffType.PlatinumMC
        data.limitLevel=0
        data.surplusTime=info.mcLeftTime
        LRoleDataMgr.MyHeroInfo.m_BufferList[data.type]=data
        LGameMsg.m_baseMsgWithOne:Change(LUIRoleDataChangeEvent.CheckOpenBuffTips,AppDef.BuffType.PlatinumMC)
        this:SendMsg(LGameMsg.m_baseMsgWithOne)       
   elseif info.isHasMcCardTemp then  
        local data = LBuffData:New()
        data.type=AppDef.BuffType.ExperienceMC  
        data.limitLevel=0
        info.mcLeftTime = stream:ReadUInt()
        data.surplusTime = info.mcLeftTime
--        ----print("data.surplusTime ==========>", data.surplusTime)
        LRoleDataMgr.MyHeroInfo.m_BufferList[data.type]=data   
        LGameMsg.m_baseMsgWithOne:Change(LUIRoleDataChangeEvent.UpdateBuffTime)
        this:SendMsg(LGameMsg.m_baseMsgWithOne)
        LGameMsg.m_baseMsgWithOne:Change(LUIRoleDataChangeEvent.CheckOpenBuffTips,AppDef.BuffType.ExperienceMC)
        this:SendMsg(LGameMsg.m_baseMsgWithOne)

   end 
    LGameMsg.m_baseMsgWithOne:Change(LUIRoleDataChangeEvent.CheckOpenBuffTips)
    this:SendMsg(LGameMsg.m_baseMsgWithOne) 
    -- local factionMsg = RoleFactionMsg:new(CEnum.RoleEvent.LuaSetFactionInfo,1,1,"测试帮派")
    -- this:SendMsg(factionMsg)
    if vipLevel > 0 then
        local vipMsg = RoleVipMsg:new(CEnum.RoleEvent.LuaSetVip,vipLevel)
        this:SendMsg(vipMsg)
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIRoleDataChangeEvent.VIPChanged)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
    end
    Utils:SendMsg(LUILogicEvent.updateRechargeUIAfterPay)
    LGameMsg.m_netDealMsg:Change(LUIPlatinumEvent.updateAwardUI)
    this:SendMsg(LGameMsg.m_netDealMsg)
    
    GameSdk:updateQuickPlayerInfo()
end

--[[
VIP信息 
op:5vip相关副本次数更新
]]
function LuaNetRecvdMsg.DealVIPCopyInfo(stream)
        local data = LDataConstMgr.GetCopyData().MyCopyInfo
        local adTimes = stream:ReadByte()
        local maxTimes = stream:ReadByte()
        data.addSpTime = maxTimes - adTimes
        data.coldtime = stream:ReadUInt()
        data.herotili = stream:ReadByte()
end

--[[
VIP信息 
op:6清除副本冷却时间
]]
function LuaNetRecvdMsg.DealClearCopyCD(stream)
        local scs = stream:ReadByte()
        if scs == 0 then
            local type = stream:ReadByte()
            if type == 1 then
                this.SetCenterTip(GUITips.RSI_MDSI_MSGI1)
            elseif type == 2 then
                this.SetCenterTip(GUITips.RSI_MDSI_MSGI2)
            elseif type == 3 then
                --GAMELAYER->TipsYuanBao()   
            end
        else
            this:QueryVipInfo(5)
        end
end

--[[
VIP信息 
op:7领取元宝
]]
function LuaNetRecvdMsg.DealGetCoin(stream)
        local scs = stream:ReadByte()
        local msg = stream:ReadString()
        if scs == 1 then
            -- if(VipLayer* vipLayer = GAMELAYER->GetVipLayer())
            -- {
            --     if (USELUAENV && OPENVIPLUA)
            --     {
            --         LuaMgr::GetInstance()->executeGlobalFunction("VipLayer_reLoadMyVipInfo")
            --     }else
            --     {
            --         vipLayer->reLoadMyVipInfo()
            --     }
            -- }
        end

--        this.SetCenterTip(GUITips.RSI_PLATINUM_GETBANGYAUN_SUNC)
--        ----print("DealGetCoin", msg)
        Utils:ShowScrollTips(msg)
--        LuaNetSendMsg:QueryVipInfo(1) --重新请求vip中月卡状态
end

--[[
VIP信息 
op:8 领取月卡元宝
]]
function LuaNetRecvdMsg.DealGetMonthCardCoin(stream)
    local cardInfo = LDataConstMgr.m_PrivilegeCardInfo
    local type = stream:ReadByte()
    local succ = stream:ReadByte()
    ------print("DealGetMonthCardCoin succ =", succ, type)
    if succ then
        cardInfo.yuanbao = 0
        cardInfo.canGet = 0
    end
    local msg = stream:ReadString()
    cardInfo.time = stream:ReadString()
    Utils:ShowScrollTips(msg)
    --更新数据
    LRoleDataMgr.MyHeroInfo:updateMyVipInfo(type)
    --更新ui
    LGameMsg.m_netDealMsg:Change(LUIPlatinumEvent.updateAwardUI)
    this:SendMsg(LGameMsg.m_netDealMsg)
--    LuaNetSendMsg:QueryVipInfo(1) --重新请求vip中月卡状态
end

--[[
VIP信息 
op:9 查询月卡信息
]]
function LuaNetRecvdMsg.DealGetMonthCardInfo(stream)
    local cardInfo = LDataConstMgr.m_PrivilegeCardInfo
    local time=stream:ReadString()
    
    cardInfo.time = time

    cardInfo.id = {}
    cardInfo.price = {}
    cardInfo.isHave = {}
    cardInfo.leftTime = {}
    local num = stream:ReadByte()

    for i=1,num do
        local id = stream:ReadByte()
        table.insert(cardInfo.id, id)
        local price = stream:ReadUInt()
        table.insert(cardInfo.price, price)
        local isHave = stream:ReadByte()
        table.insert(cardInfo.isHave, isHave)
        local t = stream:ReadUInt()
        local leftTime = t / (24*3600)
        local timeStr
        if leftTime > 0 then
            timeStr = string.format(GUITips.RIS_LEFTUI_MSG1, leftTime)
            table.insert(cardInfo.leftTime, timeStr)
        else
            leftTime = (t % (24 * 3600)) / 3600
            if leftTime > 0 then
                timeStr = string.format(GUITips.RIS_LEFTUI_MSG2, leftTime)
                table.insert(cardInfo.leftTime, timeStr)
            else
                leftTime = ((t % (24 * 3600)) % 3600) / 60
                timeStr = string.format(GUITips.RIS_LEFTUI_MSG3, leftTime)
                table.insert(cardInfo.leftTime, timeStr)
            end
        end
    end
    local canGet = stream:ReadByte()
    cardInfo.canGet = canGet
    local yuanbao = stream:ReadUInt()
    cardInfo.yuanbao = yuanbao
end


function LuaNetRecvdMsg.DealMsgChatMsg(stream)--聊天协议

    local chanel = stream:ReadByte()
    -- local chanel = stream:ReadUInt()
    print("DealMsgChatMsg chanel =", chanel)
    --如果游戏在后台， 则不处理消息
    -- if GameSdk:IsGameInBackground() then
    --     return
    -- end

    if chanel == 8 then
        --错误频道
		local errorchanel = stream:ReadByte()
		local succ = stream:ReadByte()
		if succ == 0 then
		    local errorMsg = stream:ReadString()
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,errorMsg)
            this:SendMsg(LGameMsg.m_scrollTipsMsg)
        end
		return
	end

	--私聊频道信息记录在社交信息内
	if chanel == AppDef.ChatChanelType.CCT_PERSIONAL then
        local cMsg = LPcChatMsg:New()
		cMsg.sendId = stream:ReadUInt()
		cMsg.sendName = stream:ReadString()
		cMsg.sendVip = stream:ReadByte()
		cMsg.sendProf = stream:ReadByte()
		cMsg.sendSex = stream:ReadByte()
		cMsg.sendLv = stream:ReadWord()
		cMsg.sendTeamId = stream:ReadUInt()
		cMsg.sendFactionId = stream:ReadUInt()
		cMsg.revId = stream:ReadUInt()
		cMsg.time = stream:ReadUInt()
		cMsg.msg = stream:ReadString()
        
        --非系统公告过滤限制字符
        --Todo后面再加
--		SystemHelper:FilterLimitedMsg(cMsg.msg)
        if AppDef:isChatContentJosn(cMsg.msg) then
            local versionManifest = json.decode(cMsg.msg, 1)
            
            if versionManifest.id then
                cMsg.ChatType = 2 --语音聊天
                cMsg.fid = versionManifest.fid
                local aotuPlayData  = {}
                --增加自动播放列表
                aotuPlayData.fid = versionManifest.fid
                aotuPlayData.time = versionManifest.time
                aotuPlayData.chanel = chanel
            end
        end
    
		if  string.len(cMsg.msg)  <= 0 then
			return
        end
        
        cMsg.msg = Utils:FilterLimitedMsg(cMsg.msg)
		if Utils:FilterAdLimitedMsg(cMsg.msg) == true then
			return
		end
		LRoleDataMgr.Social:AddPcChatMsg(cMsg.sendId,cMsg.revId,cMsg)
		-- LRoleDataMgr.Social:UpdateTmpChatList(cMsg.sendId,cMsg)
        --添加一条消息
         LGameMsg.m_netDealMsg:Change(LUISocialEvent.addPcChatMsg, cMsg)
         this:SendMsg(LGameMsg.m_netDealMsg)
         Utils:SetRedDotState(RedDotDef.ID.Chat_Private, LRedDotCheckMgr:ChatCheck());
         --print("DealGetMonthCardInfo 222")
		return
	end

	--聊天信息存储
    local msg = LChatMsgNode:New()
    msg:DecodeFromServer(chanel,stream);
--    TipsMgr::GetInstance()->SetCenterTip(msg.chatContent)
--    LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowFloatNotice, msg.chatContent)
--    this:SendMsg(LGameMsg.m_scrollTipsMsg)
    
    if AppDef:isChatContentJosn(msg.chatContent) then
        local versionManifest = json.decode(msg.chatContent, 1)
        if versionManifest.id then
            msg.ChatType = 2 --语音聊天
            msg.fid = versionManifest.fid

            --语音聊天
            local aotuPlayData  = {}
                --增加自动播放列表
            aotuPlayData.fid = versionManifest.fid
            aotuPlayData.time = versionManifest.time
            aotuPlayData.chanel = chanel
            LVoiceDataMgr:addVoiceQuene(aotuPlayData)

        end
    end

	if string.len(msg.chatContent) <= 0 then
        --print("999999999999999999999999999999999999999")
		return
    end
--非系统公告过滤限制字符
--  SystemHelper:FilterLimitedMsg(msg.chatContent)
    msg.chatContent = Utils:FilterLimitedMsg(msg.chatContent)
	if Utils:FilterAdLimitedMsg(msg.chatContent) == true then
        --print("8888888888888888888888888888888888")
		return
	end
	--加入系统聊天信息列表
	--DATA_MGR->Chat.AddChatMsg(msg)
    LRoleDataMgr.Chat:AddChatMsg(msg)

	-- 更新主界面聊天框
    -- LGameMsg.m_netDealMsg:Change(LUIChatEvent.updateTextField)
    -- this:SendMsg(LGameMsg.m_netDealMsg)

    local errcode = stream:ReadByte()
    --print("DealMsgChatMsg errcode =====>", errcode)
    --    通知增加一条消息
    LGameMsg.m_netDealMsg:Change(LUIChatEvent.addMsg, msg)
    this:SendMsg(LGameMsg.m_netDealMsg)
end

function LuaNetRecvdMsg.DealMsgSYSAnoncement(stream) --系统消息
    --解析系统消息
	local SysMsg = stream:ReadString()
--	BroadCastMgr::GetInstance()->AddRadioTips(SysMsg)
    
    print("DealMsgSYSAnoncement SysMsg ======================>", SysMsg)
    Utils:ShowFloatNoticeMsg(SysMsg)

--    LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, SysMsg)
--    this:SendMsg(LGameMsg.m_scrollTipsMsg)

	--加入到聊天窗口中
	--ChatMsgNode Msg
    local msg = LChatMsgNode:New()
	msg.roleName = ""
	msg.chanel = AppDef.ChatChanelType.CCT_SYS
	msg.chatContent = SysMsg
	--DATA_MGR->Chat.AddChatMsg(Msg)
	LRoleDataMgr.Chat:AddChatMsg(msg)

--	LGameMsg.m_netDealMsg:Change(LUIChatEvent.updateTextField)
--  this:SendMsg(LGameMsg.m_netDealMsg)

    LGameMsg.m_netDealMsg:Change(LUIChatEvent.addMsg, msg)
    this:SendMsg(LGameMsg.m_netDealMsg)
	
end

function LuaNetRecvdMsg.DealMsgSYSLeiTaiAnoncement(stream) --系统消息
    --解析系统消息
    local SysMsg = stream:ReadString()
--  BroadCastMgr::GetInstance()->AddRadioTips(SysMsg)

    Utils:ShowFloatNoticeMsg(SysMsg)

--    LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, SysMsg)
--    this:SendMsg(LGameMsg.m_scrollTipsMsg)

    --加入到聊天窗口中
    --ChatMsgNode Msg
    local msg = LChatMsgNode:New()
    msg.roleName = ""
    msg.chanel = AppDef.ChatChanelType.CCT_LEITAI
    msg.chatContent = SysMsg
    --DATA_MGR->Chat.AddChatMsg(Msg)
    LRoleDataMgr.Chat:AddChatMsg(msg)

--  LGameMsg.m_netDealMsg:Change(LUIChatEvent.updateTextField)
--  this:SendMsg(LGameMsg.m_netDealMsg)
    
    ------print("DealMsgSYSLeiTaiAnoncement", SysMsg)
    LGameMsg.m_netDealMsg:Change(LUIChatEvent.addMsg, msg)
    this:SendMsg(LGameMsg.m_netDealMsg)
    
end

--[[
帮派信息
]]
function LuaNetRecvdMsg.DealBPSysMsg( stream )
    -- body
    local chatType = stream:ReadByte()
    local SysMsg = stream:ReadString()
    Utils:ShowFloatNoticeMsg(SysMsg)

    local msg = LChatMsgNode:New()
    msg.roleName = ""
    msg.chanel = AppDef.ChatChanelType.CCT_BPSYS
    msg.chatContent = SysMsg

    LRoleDataMgr.Chat:AddChatMsg(msg)

    LGameMsg.m_netDealMsg:Change(LUIChatEvent.addMsg, msg)
    this:SendMsg(LGameMsg.m_netDealMsg)

end


--[[
猜拳处理
]]
function LuaNetRecvdMsg.DealMsgGuessFist(stream)
    local op = stream:ReadByte()
    local row = stream:ReadByte()
    local result
    if row == 0 then -- 猜拳失败
        local msg = stream:ReadString()
        this.SetCenterTip(msg)
        result = 2
    else
        result = stream:ReadByte()
        local msg = stream:ReadString()
        this.SetCenterTip(msg)
    end

    LGameMsg.m_netDealMsg:Change(LUIActivityEvent.GuessFistResult, result)
        this:SendMsg(LGameMsg.m_netDealMsg)
end

function LuaNetRecvdMsg.DealMsgBangPaiOption(stream)

    Utils:RemoveWaiting(LuaNetCmd.MSG_BANGPAI)
    local op = stream:ReadByte()
    -- print("DealMsgBangPaiOption",op);
    if op ~= 10 and op ~= 2 and op ~= 41 and LRoleDataMgr.Account:IsMultiServer() then
        return
    end

    if op == 1 then
        local success = stream:ReadByte()
        local msg = stream:ReadString()
        Utils:ShowScrollTips(msg)
    elseif op == 2 then
        LRoleDataMgr.Faction:ClearFactionList()
        local num = stream:ReadWord()
        for i=1,num do
            local temp = LFactionInfo:New()
            temp.rank = stream:ReadWord()
            temp.id = stream:ReadUInt()
            temp.name = stream:ReadString()
            temp.level = stream:ReadByte()
            temp.bangZhuName = stream:ReadString()
            temp.memberNum = stream:ReadWord()
            temp.MaxMemberNum = stream:ReadWord()
            temp.plantNum = stream:ReadWord()
            temp.gongGao = stream:ReadString()
            temp.isInAskJoin = stream:ReadByte()
            temp.lvLimit = stream:ReadWord()
            if temp.id == LRoleDataMgr.Faction.Info.id then
                LRoleDataMgr.Faction.Info.rank = temp.rank
            end
            LRoleDataMgr.Faction:UpdateFactionList(temp.id, temp)

            local isNeedLv = false
            for i=1, #LRoleDataMgr.Faction.Info.kejiInfo do
                local kejiData = LRoleDataMgr.Faction.Info.kejiInfo[i]
                --检测小红点
                if not isNeedLv then
                    if kejiData.buffLevel < tonumber(LRoleDataMgr.Faction.Info.level) then
                        local linfo = LDataConstMgr:getBpKejiDataByLevel(kejiData.buffLevel, kejiData.buffType)
                        if linfo.isShow then
                            if linfo.effectType > 0 then
                                if linfo.BpCost.id == AppDef.AwrdItem.AWRD_ITEM_BPMONEY then
                                    if tonumber(linfo.BpCost.num)  <= LRoleDataMgr.Faction.Info.bpMoney then
                                        isNeedLv = true
                                    end
                                end
                            else
                                if tonumber(linfo.cost)  <= LRoleDataMgr.Faction.Info.bpMoney then
                                    isNeedLv = true
                                end
                            end
                        end
                    end
                end
            end
            --检测帮派科技小红点
            ----print("info.kejiInfo ============== isNeedLv", isNeedLv)
            Utils:SetRedDotState(RedDotDef.ID.BPKeji, isNeedLv)
        end
        LGameMsg.m_netDealMsg:Change(LUIBangPaiEvent.ShowBangPaiList, {list=LRoleDataMgr.Faction:GetFactionList()})
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 3 then
        local bangPaiId = stream:ReadUInt()
        local success = stream:ReadByte()
        if success == 0 then
            Utils:ShowScrollTips(stream:ReadString())
        else --成功申请入帮
            LGameMsg.m_netDealMsg:Change(LUIBangPaiEvent.UpdateAskJoinBangPai, bangPaiId)
            this:SendMsg(LGameMsg.m_netDealMsg)
        end
    elseif op == 6 then
        local op1 = stream:ReadByte()
        if op1 == 1 then    -- 单个玩家
            local success = stream:ReadByte()
            if success == 0 then    -- failed
                Utils:ShowScrollTips(stream:ReadString())
            end
        elseif op1 == 2 then   --全部邀请
            local success = stream:ReadByte()
        end
    elseif op == 7 then
        local success = stream:ReadByte()
        if(success == 0)then--failed
            Utils:ShowScrollTips(stream:ReadString())
        else
            Utils:ShowScrollTips(GUITips.RSI_MDSI_MSGI5)
            LRoleDataMgr.Faction.InviteList = {}
            Utils:SendMsg(LUIMainEvent.CheckFactionBtn)
            LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "BangPai.BangPaiInviteList")
            this:SendMsg(LGameMsg.m_deleteUIMsg)
        end
    elseif op == 8 then
        local num = stream:ReadByte()
        local askJoinList = {}
        for i=1,num do
            local temp = LApplayInfo:New()
            temp.roleId = stream:ReadUInt()
            temp.name = stream:ReadString()
            temp.level = stream:ReadWord()
            temp.zhandouli = stream:ReadUInt()
            temp.professional = stream:ReadByte()
            temp.sex = stream:ReadByte()
            table.insert(askJoinList, temp)
        end
        LGameMsg.m_netDealMsg:Change(LUIBangPaiEvent.LoadJoinApplyList, askJoinList)
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 10 then
        local num = stream:ReadByte()
        local memberList = {}
        for i=1,num do
            local temp = LFactionMemberInfo:New()
            temp.roleId = stream:ReadUInt()
            temp.roleName = stream:ReadString()
            temp.roleLevel = stream:ReadWord()
            temp.roleWeiJie = stream:ReadByte()
            temp.roleHead = stream:ReadByte()
            temp.gongXian = stream:ReadUInt()
            temp.sex = stream:ReadByte()
            temp.zhandouli = stream:ReadULongInt()
            temp.vip = stream:ReadByte()
            temp.lastOnlineTime = stream:ReadUInt()
            temp.activity = stream:ReadUInt()

            table.insert(memberList, temp)
        end
        Utils:SortBangPaiMemList(memberList)
        LRoleDataMgr.Faction.memberList = memberList
        LGameMsg.m_netDealMsg:Change(LUIBangPaiEvent.LoadMemberList, memberList)
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 11 then
        local roleId = stream:ReadUInt()
        local success = stream:ReadByte()
        if (success == 1) then
            local bangPai = LRoleDataMgr.Faction.Info
            bangPai.memberNum = bangPai.memberNum - 1

            LGameMsg.m_netDealMsg:Change(LUIBangPaiEvent.DelMemberByRoleId, roleId)
            this:SendMsg(LGameMsg.m_netDealMsg)
        end
    elseif op == 12 then
        Utils:ShowScrollTips(GUITips.RSI_MDSI_MSGI6)

        local success = stream:ReadByte()
        if success ~= 0 then
            LRoleDataMgr.Faction.Info.isShowBPName = 0
            LRoleDataMgr.MyHeroInfo.showFactionName = 0
        end
    elseif op == 16 then
        local sucess = stream:ReadByte()
        if sucess == 0 then     -- failed
            Utils:ShowScrollTips(stream:ReadString())
        else
            local gongGao = stream:ReadString()    
            LRoleDataMgr.Faction.Info.gongGao = gongGao
            LGameMsg.m_netDealMsg:Change(LUIBangPaiEvent.UpdateGongGao, gongGao)
            this:SendMsg(LGameMsg.m_netDealMsg)
        end
    elseif op == 19 then
        local roleId = stream:ReadUInt()
        local success = stream:ReadByte()
        local message = stream:ReadString()
        Utils:ShowScrollTips(message)
        if(success == 1) then
            LRoleDataMgr.Faction.Info.selfRank = AppDef.FactionInfo.BPRT_BANGZHONG

            LGameMsg.m_netDealMsg:Change(LUIBangPaiEvent.UpdateBangZhuChuangWei, roleId)
            this:SendMsg(LGameMsg.m_netDealMsg)

            LGameMsg.m_netDealMsg:Change(LUIBangPaiEvent.UpdateSelfZhiWei, {})
            this:SendMsg(LGameMsg.m_netDealMsg)
        end
    elseif op == 20 then
        local success = stream:ReadByte()
        if(success == 1) then    --成功
            local roleId = stream:ReadUInt()
            local rank = stream:ReadByte()

            LGameMsg.m_netDealMsg:Change(LUIBangPaiEvent.UpdateMemberWeiJie, {roleId=roleId, rank=rank})
            this:SendMsg(LGameMsg.m_netDealMsg)
        else--失败
            local message = stream:ReadString()
            Utils:ShowScrollTips(message)
        end
    elseif op == 24 then
        Utils:ShowScrollTips(stream:ReadString())
    elseif op == 26 then-- 收到入帮邀请,右下角提示
        local temp = LFactionInviteInfo:New()
        temp.invideRoleId = stream:ReadUInt()
        temp.bangPaiId = stream:ReadUInt()
        temp.bangPaiName = stream:ReadString()
        temp.invtName = stream:ReadString()
        temp.invtProfessional = stream:ReadByte()
        temp.invtSex = stream:ReadByte()
        temp.invtLevel = stream:ReadByte()
        for i=1,#LRoleDataMgr.Faction.InviteList do
            local info = LRoleDataMgr.Faction.InviteList[i]
            if info.invideRoleId == temp.invideRoleId and info.bangPaiId == temp.bangPaiId then
                return
            end
        end
        table.insert(LRoleDataMgr.Faction.InviteList, temp)
        Utils:SendMsg(LUIMainEvent.CheckFactionBtn)
    elseif op == 27 then
        local success = stream:ReadByte()
        if success ~= 0 then
            LGameMsg.m_netDealMsg:Change(LUILogicEvent.CloseAllPopup)
            this:SendMsg(LGameMsg.m_netDealMsg)
        end
    elseif op == 28 then
        -- local info = LFactionZoneInfo:New()
        -- info.GodTreeLevel = stream:ReadByte()
        -- info.PrayTimes = stream:ReadUInt()
        -- info.GuardNums = stream:ReadByte()
        -- info.MaxFields = stream:ReadByte()
        -- info.LeftFields = stream:ReadByte()
        -- local num = stream:ReadByte()
        -- for i=1,num do
        --     local fInfo = LPlantCellBrief:New()
        --     fInfo.treeName = stream:ReadString()
        --     fInfo.state = stream:ReadWord()
        --     fInfo.leftTimes = stream:ReadUInt()
        --     table.insert(info.VecFileds, fInfo)
        -- end
        local info = LFactionZoneInfo:New()
        info.VecLog = {};
        num = stream:ReadByte()
        for i=1,num do
            local log = LFactionZoneLog:New()
            log.type = stream:ReadShort()
            log.date = stream:ReadUInt()
            log.log = stream:ReadString()
            log.dateStr = os.date("%m/%d %H:%M:%S", log.date)
            table.insert(info.VecLog, log)
        end
        LRoleDataMgr.Faction:UpdateManorInfo(info)

        LGameMsg.m_netDealMsg:Change(LUIBangPaiEvent.UpdateManorInfo, info)
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 29 then
        local success = stream:ReadByte()
        if(success == 1) then    --成功
            Utils:SetRedDotState(RedDotDef.ID.BPJiangLi, false)
        else--失败
            local message = stream:ReadString()
            Utils:ShowScrollTips(message)
        end
    elseif op == 30 then
        local isExistApply = stream:ReadByte()
        local info = LRoleDataMgr.Faction.Info
        local isShow = (isExistApply>0)and(info.selfRank==1 or info.selfRank==2)
        Utils:SetRedDotState(RedDotDef.ID.BPShenQing, isShow)
    -- elseif op == 31 then
    --     local isExistApply = stream:ReadByte()
    --     local info = LRoleDataMgr.Faction.Info
    --     local isShow = (isExistApply>0)and(info.selfRank==1 or info.selfRank==2)
    --     Utils:SetRedDotState(RedDotDef.ID.BPShenQing, isShow)
    elseif op == 32 then
        local isShow = stream:ReadByte()
        local success = stream:ReadByte()
        local tips = stream:ReadString()
        Utils:ShowScrollTips(tips)

        if Utils:ToBool(success) then
            LRoleDataMgr.Faction.Info.isShowBPName = isShow
            LRoleDataMgr.MyHeroInfo.showFactionName = isShow
            LGameMsg.m_netDealMsg:Change(LUIBangPaiEvent.UpdateNameShow, isShow)
            this:SendMsg(LGameMsg.m_netDealMsg)

            local info = LRoleDataMgr.Faction.Info
            local fid, fRank, fName = info.id, info.selfRank, info.name
            if not Utils:ToBool(isShow) then
                fid,fRank,fName = 0,0,""
            end
            local factionMsg = RoleFactionMsg:new(CEnum.RoleEvent.LuaSetFactionInfo, fid, fRank, fName)
            this:SendMsg(factionMsg)
        end
    elseif op == 33 then--获取帮派任务列表
        -- local success = stream:ReadByte()
        -- if success == 1 then
        --     LRoleDataMgr.Faction.Info.isExistActAward = 0
        --     local ret = {}
        --     local num = stream:ReadWord()
        --     for i = 1, num do
        --         local cell = {}
        --         cell.missionId = stream:ReadUInt()
        --         cell.name = stream:ReadString()
        --         cell.desc = stream:ReadString()
        --         cell.missionType = stream:ReadUInt()
        --         cell.awardItemId = stream:ReadUInt()
        --         cell.awardItemNum = stream:ReadUInt()
        --         cell.awardType = stream:ReadUInt()
        --         cell.awardValue = stream:ReadUInt()
        --         cell.needCompleteNum = stream:ReadUInt()
        --         cell.completeNum = stream:ReadUInt()
        --         cell.buttonState = stream:ReadByte()
        --         cell.curHuoYue = stream:ReadByte()
        --         cell.maxHuoYue = stream:ReadByte()
        --         ------print("cell.missionId =====>", cell.missionId, cell.missionType)
        --         if cell.buttonState == 1 and cell.missionType ~= 34 and cell.missionType ~= 36 then
        --             LRoleDataMgr.Faction.Info.isExistActAward = LRoleDataMgr.Faction.Info.isExistActAward +  1
        --         end
        --         if cell.missionType == 34 or cell.missionType == 36 or cell.missionId == 14 then
        --             cell.level = stream:ReadUInt()
        --             cell.time = stream:ReadString()
        --             local awardNum = stream:ReadUInt()
        --             cell.awards = {}
        --             for j=1,awardNum do
        --                 table.insert(cell.awards, stream:ReadUInt())
        --             end
        --             cell.isOpen = cell.buttonState
        --         end
        --         table.insert(ret, cell)
        --     end
        --     LGameMsg.m_netDealMsg:Change(LUIBangPaiEvent.ReloadFactionTaskList, ret)
        --     this:SendMsg(LGameMsg.m_netDealMsg)
        --     Utils:SetRedDotState(RedDotDef.ID.BPHuoDongItem, LRoleDataMgr.Faction.Info.isExistActAward > 0)
        -- else
        --     Utils:ShowScrollTips(stream:ReadString())
        -- end
    elseif op == 36 then
        local missionId = stream:ReadUInt()
        local success = stream:ReadByte()
        if success == 1 then
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
            LGameMsg.m_netDealMsg:Change(LUIBangPaiEvent.GetFactionTaskReward, missionId)
            this:SendMsg(LGameMsg.m_netDealMsg)
            LRoleDataMgr.Faction.Info.isExistActAward = math.max(LRoleDataMgr.Faction.Info.isExistActAward-1, 0)
            -- Utils:SetRedDotState(RedDotDef.ID.BPHuoDongItem, LRoleDataMgr.Faction.Info.isExistActAward > 0)
        else
            Utils:ShowScrollTips(stream:ReadString())
        end
    elseif op == 37 then--请求捐献金币信息
        local success = stream:ReadByte()
        ----print("------------------->> success", success)
        if success == 1 then
            local ret = {}
            local num = stream:ReadByte()
            for i = 1, num do
                local cell = {}
                cell.type = stream:ReadByte()
                cell.money = stream:ReadUInt()
                cell.bangpaiMoney = stream:ReadUInt()
                cell.banggong = stream:ReadUInt()

                table.insert(ret, cell)
            end
            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "BangPai.BangPaiJuanXianUI",AppDef.UIType.FirstClassLayer)
            this:SendMsg(LGameMsg.m_initUIMsg)
            LGameMsg.m_netDealMsg:Change(LUIBangPaiEvent.ReloadJuanXianMsg, ret)
            this:SendMsg(LGameMsg.m_netDealMsg)
        else
            Utils:ShowScrollTips(stream:ReadString())
        end
    elseif op == 38 then--请求捐献金币
        local mType = stream:ReadByte()
        local success = stream:ReadByte()
        Utils:ShowScrollTips(stream:ReadString())
        if success ~= 0 then
            LuaNetSendMsg:QueryFactionTaskList()
        end
    elseif op == 39 then --捐献信息
        local mType = stream:ReadByte()
        local success = stream:ReadByte()
        if mType == 1 then
            if success == 0 then
                Utils:ShowScrollTips(stream:ReadString())
                return
            end
            local num = stream:ReadWord()
            local ret = {}
            ret.mType = mType
            ret.mInfo = {}
            for i = 1, num do
                local cell = {}
                cell.idx = stream:ReadWord()
                cell.time = stream:ReadString()
                cell.desc = stream:ReadString()

                table.insert(ret.mInfo, cell)
            end

            LGameMsg.m_netDealMsg:Change(LUIBangPaiEvent.UpdateJuanXianRecord, ret)
            this:SendMsg(LGameMsg.m_netDealMsg)
        end
    elseif op == 40 then --帮派自动入帮等级设置
        local succ = stream:ReadByte()
        if succ == 0 then
            Utils:ShowScrollTips(stream:ReadString())
            return
        end
        Utils:ShowScrollTips(GUITips.RSI_BP_TIP50)
        LuaNetSendMsg:QueryFactionInfo()
    elseif op == 41 then--活跃度奖励配置
        local datas = {}
        local num = stream:ReadByte()
        for i=1,num do
            local item = {}
            item.type = stream:ReadByte()--1:个人 2:帮派
            item.activityList = {}
            local count = stream:ReadByte()
            for j=1,count do
                local subItem = {}
                subItem.activity = stream:ReadUInt()--活跃度
                subItem.state = stream:ReadByte()--1：领取 0：未领取
                subItem.rewards = {}
                local subCount = stream:ReadByte()
                for k=1,subCount do
                    local rwd = {}
                    -- LuaNetRecvdMsg.ReadAwardData(stream, rwd)
                    rwd.id = stream:ReadUInt()
                    rwd.num = stream:ReadUInt()
                    table.insert(subItem.rewards, rwd)
                end
                -- ------dump(subItem, "subItem--->")
                table.insert(item.activityList, subItem)
            end
--            ------dump(item, "item---->")
            datas[item.type] = item
        end
        -- ------dump(datas, "datas--->")
        LGameMsg.m_netDealMsg:Change(LUIBangPaiEvent.ReloadFactionActivityList, datas)
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 42 then
        local actType = stream:ReadByte()
        local actValue = stream:ReadUInt()
        local succ = stream:ReadByte()
        if succ == 0 then
            Utils:ShowScrollTips(stream:ReadString())
            return
        end
        LuaNetSendMsg:QueryFactionActivityList()
    elseif op == 43 then
        local kejiType = stream:ReadByte()
        local errorCode = stream:ReadByte() 
        ----print("bpki =====================>", errorCode, kejiType)
        if errorCode == 0 then
            local str = stream:ReadString()
            Utils:ShowScrollTips(str)
        else
            --刷新界面
            LuaNetSendMsg:QueryFactionInfo()
        end
    elseif op == 44 then
        local num = stream:ReadByte()
        local levelUpData = {}
        ----print("DealMsgBangPai op =", op, num)
        local isNeedRedDot = false
        for i=1, num do
            local data = {}
            data.id = stream:ReadWord()
            data.level = stream:ReadByte()
            ----print("DealMsgBangPai ====>", data.id, data.level)
            table.insert(levelUpData, data)
            if not isNeedRedDot then
                local attrData = LDataConstMgr:getBpKejiDataByLevel(data.level, data.id)
                if attrData ~= nil then
                    if attrData.effectType > 0 then
                        local errCode = LDataConstMgr:getIsCanEnough( attrData )
                        if errCode <= 0 then
                            isNeedRedDot = true
                        end
                    end
                end
            end
        end
        --小红点检测
        Utils:SetRedDotState(RedDotDef.ID.BPXiuLian, isNeedRedDot)
        Utils:SendMsg(LUIBangPaiWarEvent.UpdateSkillUpUI, levelUpData)
    elseif op == 45 then
        local upType = stream:ReadByte()
        local skillId = stream:ReadWord()
        local isAllUp = stream:ReadByte()
        local errCode = stream:ReadByte()
        ------print("DealMsgBangPai ==== 33333333333> ", upType, skillId, isAllUp, errCode)
        if errCode == 0 then
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
        else
            local skillLv = stream:ReadByte()
            ------print("skillLv ===========>", skillLv)
            if upType == 2 then
                --刷新界面
                LuaNetSendMsg:QueryFactionInfo()
            else
                --刷新界面
                LuaNetSendMsg:QueryBpSkilllevelUpData(44)
            end
        end
    end
end

function LuaNetRecvdMsg.DealMsgBangPaiWar(stream)
    local op = stream:ReadByte()
    if op == 1 then
        --帮派参赛信息
        local info = LBangPaiWarDataMgr:GetWarData()
        info.bpLvflag = stream:ReadByte() == 1
        info.bpLvStr = stream:ReadString()
        info.bpMemNumflag = stream:ReadByte() == 1
        info.bpMemNumStr = stream:ReadString()
        info.roleLvflag = stream:ReadByte() == 1
        info.roleLvStr = stream:ReadString()
        info.enterTimeflag = stream:ReadByte() == 1
        info.enterTimeStr = stream:ReadString()
        info.startFlag = stream:ReadByte() == 1
        info.timeDesc = stream:ReadString()
        info.desc = stream:ReadString()
        local num = stream:ReadWord()
        info.BangPaiList = {}
        for i=1,num do
            local value = {}
            value.id = stream:ReadInt()
            value.name = stream:ReadString()
            value.level = stream:ReadByte()
            value.memCnt = stream:ReadWord()
            value.masterName= stream:ReadString()
            value.score = stream:ReadInt()           
            table.insert(info.BangPaiList,value)
        end
--        for i=1,5 do
--            local value = {}
--            value.id = i
--            value.name = "帮派"..i
--            value.level = i
--            value.masterName = value.name.."帮主"
--            value.score = i*10
--            value.memCnt = i*5
--            table.insert(info.BangPaiList,value)
--        end
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIBangPaiEvent.UpdateBangPaiWarInfo)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
    elseif op == 2 then
        --倒计时
        LBangPaiWarDataMgr.CountDown = stream:ReadInt()
        ------print("LBangPaiWarDataMgr.CountDown =====>", LBangPaiWarDataMgr.CountDown)
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIBangPaiWarEvent.ShowCountDown)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
    elseif op == 3 then
        --现在没有了
        --行动力
        -- LBangPaiWarDataMgr.ActionPower = stream:ReadWord()
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIBangPaiWarEvent.ShowActionPower)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
    elseif op == 4 then
        --帮战排行榜
        local info = LBangPaiWarDataMgr:GetWarRankData()
		info.mybpScore = stream:ReadUInt()
		info.mybpRank = stream:ReadUInt()
        info.bpScoreRankList = {}
		local num = stream:ReadUInt()
		for i=1,num do
            local value = {}
			value.rak = stream:ReadUInt()
            value.bpId = stream:ReadUInt()
            ----print("value.bpId ==", value.bpId)
			value.name = stream:ReadString()
			value.score = stream:ReadUInt()
            value.towerNum = 0         --占塔的数量
			table.insert(info.bpScoreRankList,value)
		end

		info.myScore = stream:ReadUInt()
		info.myRank = stream:ReadUInt()
        info.ScoreRankList = {}
		local ronum = stream:ReadUInt()
		for i=1,ronum do
            local value = {}
			value.rak = stream:ReadUInt()
			value.name = stream:ReadString()
			value.score = stream:ReadUInt()
			table.insert(info.ScoreRankList,value)
		end
        LBangPaiWarDataMgr:initBPWTowerRankData()

        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIBangPaiWarEvent.ShowRankInfo)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
    elseif op == 5 then
        local id = stream:ReadUInt()
        local suc = stream:ReadByte()
        ----print("DealMsgBangPaiWar op ==", op, id, suc)
        if suc <= 0 then
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
        end
    elseif op == 6 then
        --参赛按钮返回
        local suc = stream:ReadByte()
        if suc == 0 then
            local errMsg = stream:ReadString()
            if(#errMsg > 0) then
                Utils:ShowScrollTips(errMsg)
            end
            return
        end
        LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "BangPai.BangPaiUI")
        this:SendMsg(LGameMsg.m_deleteUIMsg)
	elseif op == 7 then
		--宝箱倒计时
		LBangPaiWarDataMgr.BoxCountDown = stream:ReadWord()
        ----print("********************* ===>", LBangPaiWarDataMgr.BoxCountDown)
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIBangPaiWarEvent.ShowBoxCountDown)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
    elseif op == 8 then
        local bpTowerInfo = LBangPaiWarDataMgr:getWarTowerInfo()
        bpTowerInfo = {}
        local towerNum = stream:ReadByte()
        for i=1, towerNum do
            local towerInfo = LBangPaiWarTowerInfo:New()
            towerInfo.id = stream:ReadWord()
            towerInfo.hp = stream:ReadUInt()
            towerInfo.maxHp = stream:ReadUInt()
            towerInfo.leftCd = stream:ReadWord()
            towerInfo.onwerId = stream:ReadUInt()
            towerInfo.name = stream:ReadString()
            towerInfo.picId = stream:ReadWord()
            table.insert(bpTowerInfo, towerInfo)
        end
        ------dump(bpTowerInfo, "bpTowerInfo===>")
        LBangPaiWarDataMgr:settWarTowerInfo(bpTowerInfo)
        Utils:SendMsg(LUIBangPaiWarEvent.updateBpWarTowerUI, bpTowerInfo)
    elseif op == 9 then
        local towerInfo = LBangPaiWarTowerInfo:New()
        towerInfo.id = stream:ReadWord()
        towerInfo.hp = stream:ReadUInt()
        towerInfo.maxHp = stream:ReadUInt()
        towerInfo.leftCd = stream:ReadWord()
        towerInfo.onwerId = stream:ReadUInt()
        towerInfo.name = stream:ReadString()
        Utils:SendMsg(LUIBangPaiWarEvent.updateBpWarData, towerInfo)
        ------dump(towerInfo, "op == 9 towerInfo")
    elseif op == 10 then
        ----print("2222222222222222222222===>")
        Utils:DeleteUI("Interact.NPCCollectUI")
    elseif op == 19 then
        local num = stream:ReadByte()
        local dataInfo = {}
        for i=1, num do
            --伤害数量
            local rankInfo = {}
            local hurtNum = stream:ReadByte()
            for i=1, hurtNum do
                local oneData = {}
                oneData.bpId = stream:ReadUInt()
                oneData.name = stream:ReadString()
                oneData.shanghai = stream:ReadUInt()
                table.insert(rankInfo, oneData)
            end
            table.insert(dataInfo, rankInfo)
--            ------dump(rankInfo, "44444444444444444444444444444 ===>")
        end
        Utils:SendMsg(LUIBangPaiWarEvent.ShowBpWarHurtRank, dataInfo)
    end
end

function LuaNetRecvdMsg.DealMsgMyBangPai(stream)
    local info = LRoleDataMgr.Faction.Info
    local myinfo = LRoleDataMgr.MyHeroInfo
    local op = stream:ReadByte()
    print("DealMsgMyBangPai",op)
    if op == 1 then
        info.id = stream:ReadUInt()
        local isGetedAward = 1
        if info.id > 0 then
            info.picId = stream:ReadUInt()
            info.name = stream:ReadString()
            info.level = stream:ReadByte()
            info.memberNum = stream:ReadWord()
            info.MaxMemberNum = stream:ReadWord()
            info.gongGao = stream:ReadString()
            info.Exp = stream:ReadUInt()
            info.MaxExp = stream:ReadUInt()
            info.selfRank = stream:ReadByte()
            info:SetselfBangGong(stream:ReadUInt())
            info.bpMoney = stream:ReadUInt()
            info.isShowBPName = stream:ReadByte()
            info.bangZhuName = stream:ReadString()
            isGetedAward = stream:ReadByte()
            info.limitLevel = stream:ReadWord()
            info.totalActivity = stream:ReadUInt()
            info.selfActivity = stream:ReadUInt()
            info.kejiInfo = {}
            local num = stream:ReadByte()
            ------print("num =================>", num)
            local isNeedLv = false
            for i=1, num do
                local kejiData = {}
                kejiData.buffType = stream:ReadWord()
                kejiData.buffLevel = stream:ReadByte()
                -- ----print("info.kejiInfo ============== isNeedLv 1111", kejiData.buffLevel, info.level)
                --检测小红点
                if not isNeedLv then
                    if kejiData.buffLevel < info.level then
                        local linfo = LDataConstMgr:getBpKejiDataByLevel(kejiData.buffLevel, kejiData.buffType)
                        if linfo.isShow then
                            if linfo.effectType > 0 then
                                if linfo.BpCost.id == AppDef.AwrdItem.AWRD_ITEM_BPMONEY then
                                    if tonumber(linfo.BpCost.num)  <= LRoleDataMgr.Faction.Info.bpMoney then
                                        isNeedLv = true
                                    end
                                end
                            else
                                if tonumber(linfo.cost)  <= LRoleDataMgr.Faction.Info.bpMoney then
                                    isNeedLv = true
                                end
                            end
                        end
                    end
                end
                table.insert(info.kejiInfo, kejiData)
            end
            ----print("info.kejiInfo ============== 1111111111111111111111", isNeedLv)
            Utils:SetRedDotState(RedDotDef.ID.BPKeji, isNeedLv)

            myinfo.bangZhuName = info.bangZhuName
            myinfo.showFactionName = info.isShowBPName
            myinfo.FactionId = info.id
            myinfo.FactionName = info.name
            myinfo.FactionRankType = info.selfRank
        end
        myinfo.FactionId = info.id
        -- Utils:SetRedDotState(RedDotDef.ID.BPJiangLi, (isGetedAward == 0)and(info.selfRank == 1 or info.selfRank == 2))
        --Utils:SendMsg(LUIBangPaiWarEvent.UpdateBpKejiUI)
        Utils:SendMsg(LUIBangPaiEvent.JoinSuccess)
    elseif op == 2 then
        local id = stream:ReadUInt()
        if info.id ~= id then
            return
        end
        info:SetselfBangGong(stream:ReadUInt())
        info.bpMoney = stream:ReadUInt()
        local isNeedLv = false
        for i=1, #info.kejiInfo do
            local kejiData = info.kejiInfo[i]
            --检测小红点
            if not isNeedLv then
                if kejiData.buffLevel < tonumber(info.level) then
                    local linfo = LDataConstMgr:getBpKejiDataByLevel(kejiData.buffLevel, kejiData.buffType)
                    if linfo.isShow then
                        if linfo.effectType > 0 then
                            if linfo.BpCost.id == AppDef.AwrdItem.AWRD_ITEM_BPMONEY then
                                if tonumber(linfo.BpCost.num)  <= LRoleDataMgr.Faction.Info.bpMoney then
                                    isNeedLv = true
                                end
                            end
                        else
                            if tonumber(linfo.cost)  <= LRoleDataMgr.Faction.Info.bpMoney then
                                isNeedLv = true
                            end
                        end
                    end
                end
            end
        end
        --检测帮派科技小红点
        ----print("info.kejiInfo ============== 222222222222222222 isNeedLv", isNeedLv)
        Utils:SetRedDotState(RedDotDef.ID.BPKeji, isNeedLv)
        info.totalActivity = stream:ReadUInt()
        info.selfActivity = stream:ReadUInt()
    elseif op == 3 then
        local name = stream:ReadString()
        LRoleDataMgr.Faction.Info.name = name
        -- --print("DealMsgFactionZone name =", name)
        --更新帮派名字
        local nameLabel = LRoleDataMgr.MyHeroInfo.node:getChildByTag(-14)
        if nameLabel ~= nil then
            local showStr = name .. LRoleDataMgr:getMyFactionRankTypeName()
            -- --print("DealMsgFactionZone showStr =", showStr)
            nameLabel:setString(showStr)
        end
    end

    LGameMsg.m_netDealMsg:Change(LUIBangPaiEvent.UpdateMyFactionInfo, {})
    this:SendMsg(LGameMsg.m_netDealMsg)
    LGameMsg.m_netDealMsg:Change(LUIBangPaiEvent.FlushFactionActivity)
    this:SendMsg(LGameMsg.m_netDealMsg)

    local fid, fRank, fName = info.id, info.selfRank, info.name
    if fid == 0 then
        fRank,fName = 0,""
    end
    local factionMsg = RoleFactionMsg:new(CEnum.RoleEvent.LuaSetFactionInfo, fid, fRank, fName)
    this:SendMsg(factionMsg)
end

function LuaNetRecvdMsg.DealMsgFactionZone(stream)
    local op = stream:ReadByte()
    if op == 1 then
        Utils:DeleteUI("BangPaiZone.BangPaiZoneUI")

        local myFactionId = stream:ReadUInt()
        local factionId = stream:ReadUInt()
        local factionName = stream:ReadString()
        local factionLevel = stream:ReadByte()
        LRoleDataMgr.Faction.Info.id = myFactionId
        LRoleDataMgr.Faction:SetPlantFactionId(factionId)
        LRoleDataMgr.Faction:SetPlantFactionName(factionName)
        LRoleDataMgr.Faction:SetGodTreeCanRob(false)

        local areaNum = stream:ReadByte()
        for i=1,areaNum do
            stream:ReadByte()
            stream:ReadByte()
            stream:ReadByte()
            stream:ReadByte()
            stream:ReadByte()
            stream:ReadByte()
            local CellNum = stream:ReadByte()
            for j=1,CellNum do
                stream:ReadByte()
                stream:ReadUShort()
            end
        end

        local godTreeLv = stream:ReadByte()
        local magicFireState = stream:ReadByte()
        LRoleDataMgr.Faction:SetMagicFireBurning(magicFireState == 2)

        Utils:InitUI("BangPaiZone.BangPaiZoneUI", AppDef.UIType.PopWindow)

        LGameMsg.m_netDealMsg:Change(LUIBangPaiEvent.EnterBPPlantArea, 0)
        this:SendMsg(LGameMsg.m_netDealMsg)

        if LRoleDataMgr.Faction:IsPlantFactionBelongMe() then
            LuaNetSendMsg:QueryFactionSeedData()
        end
    elseif op == 3 then
        local factionId = stream:ReadUInt()
        local isSuccess = stream:ReadByte()
        if(isSuccess == 0) then
            --种植失败
            local Rtype = stream:ReadByte()
            local errMsg = stream:ReadString()
            if(Rtype==0) then
                Utils:ShowScrollTips(errMsg)
            else
                Utils:ShowDialogOKCancel(errMsg, function()
                    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Vip.VipMainUI",AppDef.UIType.FirstClassLayer, vipLimit)
                    this:SendMsg(LGameMsg.m_initUIMsg)
                end, function() end)
            end
        else
            local succMsg = stream:ReadString()
            if(#succMsg > 0) then
                Utils:ShowScrollTips(succMsg)
            end
            LuaNetSendMsg:QueryFactionTaskList()
        end
    elseif op >= 4 and op <= 10 then
        local factionId = stream:ReadUInt()
        local isSuccess = stream:ReadByte()
        local msg = stream:ReadString()
        Utils:ShowScrollTips(msg)
        if isSuccess ~= 0 then
            if (op==4 or op==5 or op==6 or op==8) then
                LuaNetSendMsg:QueryFactionTaskList()
            end
            if op == 4 or op == 5 then
                Utils:SendMsg(LUIBangPaiEvent.PlantResultEvent, op)
            end
        end
    elseif op == 13 then
        local factionId = stream:ReadUInt()
        local areaIdx = stream:ReadByte()
        local type = stream:ReadByte()
        local roleId = stream:ReadUInt()
        if (roleId == 0) then
            return
        end
        --详细信息
        if (type == 2) then
            LuaNetSendMsg:QueryOtherPlayer(roleId)
        end
    elseif op ==15 or op == 16 then
        local factionId = stream:ReadUInt()
        local isSuccess = stream:ReadByte()
        local msg = stream:ReadString()
        if(#msg > 0) then
            Utils:ShowScrollTips(msg)
        end
    elseif op == 17 then
        local factionId = stream:ReadUInt()
        local state = stream:ReadByte()
        LRoleDataMgr.Faction:SetMagicFireBurning(state == 2)
    elseif op == 18 then--获取神树信息
        local dataInfo = LPlantGodTree:New()
        dataInfo.FactionId = stream:ReadUInt()
        dataInfo.TreeExp = stream:ReadUInt()
        dataInfo.MaxTreeExp = stream:ReadUInt()
        dataInfo.PrayExp = stream:ReadUInt()
        dataInfo.RobbedTimes = stream:ReadByte()
        dataInfo.MaxRobbedTimes = stream:ReadByte()
        dataInfo.RobbedExp = stream:ReadUInt()
        dataInfo.LeftYBPrayTimes = stream:ReadByte()
        dataInfo.LeftNormalPrayTimes = stream:ReadByte()
        dataInfo.PrayCost = stream:ReadWord()
        dataInfo.RipeTimeString = stream:ReadString()
        dataInfo.RobTimeString = stream:ReadString()
        local logNum = stream:ReadByte()

        for i=1,logNum do
            table.insert(dataInfo.VecLog, stream:ReadString())
        end

        LRoleDataMgr.Faction:UpdateGodTree(dataInfo)

        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "BangPai.GodTreeUI",AppDef.UIType.FirstClassLayer)
        this:SendMsg(LGameMsg.m_initUIMsg)

        LGameMsg.m_netDealMsg:Change(LUIBangPaiEvent.ReloadGodTreeInfo, LRoleDataMgr.Faction:GetGodTree())
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 19 then  --神树更新信息
        local factionId = stream:ReadUInt()
        local prayType = stream:ReadByte()
        local isSuccess = stream:ReadByte()
        if isSuccess == 1 then
            local leftpraytimes = stream:ReadByte()
            if prayType == 2 then
                local dataInfo = LRoleDataMgr.Faction:GetGodTree()
                dataInfo.PrayCost = stream:ReadWord()
            end

            local Msg = stream:ReadString()
            Utils:ShowScrollTips( Msg )

            Msg = stream:ReadString()

            local prayExp = stream:ReadUInt()

            local dataInfo = LRoleDataMgr.Faction:GetGodTree()
            if prayType == 1 then
                dataInfo.LeftNormalPrayTimes = leftpraytimes
            else
                dataInfo.LeftYBPrayTimes = leftpraytimes
            end

            table.insert(dataInfo.VecLog, 1, Msg)

            dataInfo.PrayExp = prayExp

            LGameMsg.m_netDealMsg:Change(LUIBangPaiEvent.ReloadGodTreeInfo, LRoleDataMgr.Faction:GetGodTree())
            this:SendMsg(LGameMsg.m_netDealMsg)
        else
            Utils:ShowScrollTips( stream:ReadString() )
        end
    elseif op == 20 then --神树请求掠夺
        local factionId = stream:ReadUInt()
        local isSuccess = stream:ReadByte()
        LRoleDataMgr.Faction:SetGodTreeCanRob(isSuccess == 1)
        LGameMsg.m_netDealMsg:Change(LUIBangPaiEvent.UpdateRobButton, isSuccess == 1)
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 21 then --神树确认掠夺
        local factionId = stream:ReadUInt()
        local isSuccess = stream:ReadByte()
        local msg = stream:ReadString()
        if(#msg > 0) then
            Utils:ShowScrollTips(msg)
        end
    elseif op == 26 then-- 获取仙尊阁信息
        local success = stream:ReadByte()
        if success == 1 then
            local ltab = {}
            ltab.level = stream:ReadUInt()
            ltab.money = stream:ReadUInt()
            ltab.yingxiangli = stream:ReadUInt()
            ltab.ratio = stream:ReadUInt()
            ltab.nextLv = stream:ReadUInt()
            ltab.LvUpYingXiangLi = stream:ReadUInt()
            ltab.LvUpMoney = stream:ReadUInt()
            ltab.showLevelUpButton = stream:ReadByte()
            local num = stream:ReadByte()
            ltab.sxInfo = {}
            for j = 1, num do
                local sxId = stream:ReadWord()
                table.insert(ltab.sxInfo,sxId)
            end
            
            LGameMsg.m_netDealMsg:Change(LUIBangPaiEvent.ReloadXianZunGeMsg, ltab)
            this:SendMsg(LGameMsg.m_netDealMsg)
        else
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
        end
    elseif op == 27 then                           -- 仙尊阁升级
        local success = stream:ReadByte()
        if success == 1 then
            local msg = stream:ReadString()

            local ltab = {}
            ltab.level = stream:ReadUInt()
            ltab.money = stream:ReadUInt()
            ltab.yingxiangli = stream:ReadUInt()
            ltab.ratio = stream:ReadUInt()
            ltab.nextLv = stream:ReadUInt()
            ltab.LvUpYingXiangLi = stream:ReadUInt()
            ltab.LvUpMoney = stream:ReadUInt()
            ltab.showLevelUpButton = stream:ReadByte()
            LGameMsg.m_netDealMsg:Change(LUIBangPaiEvent.ReloadXianZunGeMsg, ltab)
            this:SendMsg(LGameMsg.m_netDealMsg)

            Utils:ShowScrollTips(msg)
        else
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
        end
    elseif op == 36 then
        local missionId = stream:ReadUInt()
        local success = stream:ReadByte()
        if success == 1 then
            --TODO:临时提示
            Utils:ShowScrollTips("任务发布成功")
        else
            Utils:ShowScrollTips(stream:ReadString())
        end
    elseif op == 41 then--打开帮派供奉的界面
        local success = stream:ReadByte()
        if success == 1 then
            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "BangPai.BangPaiXianZunGeUI",AppDef.UIType.FirstClassLayer)
            this:SendMsg(LGameMsg.m_initUIMsg)
        else
            Utils:ShowScrollTips(stream:ReadString())
        end
    elseif op == 47 then --菜地种子
        local datas = {}
        local num = stream:ReadByte()
        for i=1,num do
            local item = {}
            item.subCount = stream:ReadByte()
            item.maxCount = stream:ReadByte()
            table.insert(datas, item)
        end
        Utils:FreeTable(LRoleDataMgr.Faction._PlantExtraData)
        LRoleDataMgr.Faction._PlantExtraData = nil
        LRoleDataMgr.Faction._PlantExtraData = datas
    end
end
--[[
活动主界面快捷按钮
]]
function LuaNetRecvdMsg.checkOpenAct(id, flag, time, timestamp, isNoTime, isFirst)
    -- ------dump({id, flag, time, timestamp, isNoTime, isFirst}, "LuaNetRecvdMsg.checkOpenAct-->")
    local function addActData(actId, time, timestamp, isNoTime, isFirst)
        for i=1,#LRoleDataMgr.OpenedActData do
            local item = LRoleDataMgr.OpenedActData[i]
            if item.actID == actId then
                table.remove(LRoleDataMgr.OpenedActData, i)
                break
            end
        end
        local data = {}
        data.actID = actId
        data.time = time
        data.timestamp = timestamp
        data.isNoTime = isNoTime
        if isFirst then
            local index = 1
            for i=1,#LRoleDataMgr.OpenedActData do
                if LRoleDataMgr.OpenedActData[i] and (not Utils:ToBool(LRoleDataMgr.OpenedActData[i].isNoTime)) then
                    index = i
                    break
                end
            end
            table.insert(LRoleDataMgr.OpenedActData, index, data)
        else
            table.insert(LRoleDataMgr.OpenedActData, data)
        end
    end

    local needFlush = false
    if flag == 1 or flag == 3 then
        needFlush = true
        addActData(id, time, timestamp, isNoTime, isFirst)
    elseif flag == 2 then
        for i=1,#LRoleDataMgr.OpenedActData do
            local item = LRoleDataMgr.OpenedActData[i]
            if item.actID == id then
                table.remove(LRoleDataMgr.OpenedActData, i)
                needFlush = true
                break
            end
        end
    end
    if needFlush then
        LGameMsg.m_netDealMsg:Change(LUIMainEvent.FlushOpenActivity)
        this:SendMsg(LGameMsg.m_netDealMsg)
    end
end
--[[
活动
]]
function LuaNetRecvdMsg.DealHuoDong(stream)
    local op = stream:ReadWord()
    -- =============================
    if op == 1 then--控制活动快捷按钮显不显示
        local actType = stream:ReadByte()
        local flag = stream:ReadByte()
        local time = nil
        local timestamp = nil
        if flag == 1 then
            time = stream:ReadUInt()
        elseif flag == 3 then
            timestamp = stream:ReadUInt()
        end
--        ------dump({actType, flag, time, timestamp}, "DealHuoDong--->")
        this.checkOpenAct(actType, flag, time, timestamp)
        -- if flag == 1 then
        --     if actType == AppDef.EActivityID.EAID_SHENJIELUNDAO then
        --         LuaNetSendMsg:QueryMsBossInfo()
        --     end
        -- end
        if actType == 18 and flag == 1 then--体力领取
            LuaNetSendMsg:QueryRedDot(RedDotDef.SID.Fuli_Tili)
        end
    elseif op ==2 then
        local success = stream:ReadByte()
        if(success == 0) then
            local errMsg = stream:ReadString()
            Utils:ShowScrollTips(errMsg)
        end
    elseif op == 3 then
        this.DealKunlunshan(stream)
    elseif op == 5 then -- 更新昆仑山数据
        this.UpdateKunlunshan(stream)
    elseif op == 6 then -- 灵气捐献数据
        this.DealDonateInfo(stream)
    elseif op == 7 then -- 灵气捐献处理
        this.DealDonateResult(stream)
    elseif op == 8 then
        -- 签到 
        local rsp = {}
        local t = stream:ReadByte()
        rsp.cmd = LuaNetCmd.MSG_CLIENT_HUODONG_OPTION
        rsp.op = op
        rsp.sitype = t

        if t == 0 then
            -- =============================
            -- 服务器返回签到数据
            local si = LDailySignData:New()
            si.isdone = stream:ReadByte()
            si.signnum = stream:ReadByte()
            si.daynum = stream:ReadByte()
            for i = 1, si.daynum do 
                local aw = LDailySignAward:New()
                aw.dayidx = stream:ReadByte()
                aw.awardtype = stream:ReadUInt()
                aw.awardnum = stream:ReadUInt()
                aw.value=stream:ReadUInt()--神将装备星级
                aw.viplv = stream:ReadByte()
                aw.vipmultiple = stream:ReadByte()
                --------dump(aw,"aw信息------------》")
                si:PushDailyAward(aw)
            end
            rsp.sign_info = si 
            LGameMsg.m_netDealMsg:Change(LUIDailySignEvent.DailySignInfo, rsp)
            this:SendMsg(LGameMsg.m_netDealMsg)
            LRoleDataMgr.MyHeroInfo.dailyIsDone = si.isdone
            LRedDotCheckMgr:MainWelfareCheck()
        end

        if t == 1 then 
            -- =============================
            -- 服务器返回签到结果
            rsp.errcode = stream:ReadByte()
--            rsp.errmsg = stream:ReadString()
            LGameMsg.m_netDealMsg:Change(LUIDailySignEvent.DailySignResult, rsp)
            this:SendMsg(LGameMsg.m_netDealMsg)

        end
    elseif op == 11 then --百花礼盒
       -- this.DealMsgBaiHuaAward(stream)
    elseif op == 14 then --六界使者
        this.DealMsgLiujie(stream)
    elseif op == 18 then
        --激活码兑换
    elseif op == 20 then
        --开服时间
        local day = stream:ReadWord()
        local playDays = stream:ReadUInt()
        print("open time day =", day, playDays)
        PetkaPaiManager._serverOpenTime = day
        PetkaPaiManager.m_createRoleDays = playDays
        LGameMsg.m_netDealMsg:Change(LUIMainEvent.ShowActivityIcon)
        this:SendMsg(LGameMsg.m_netDealMsg)
    end
end

--六界使者
function LuaNetRecvdMsg.DealMsgLiujie(stream)
    --[[
    op=14  isSuccess  
2byte    1byte   
        =1 success   num   { sceneId  sceneName  killedNum  allNum  }
                    1byte     2byte    string      1byte     2byte
        =0 failed    msg
                    string

    ]]
    local res = stream:ReadByte()
    if res == 0 then

        return
    end
    if res ~= 1 then
        return
    end
    local num = stream:ReadByte()
    local datas = {}
    for i = 1, num do
        local data = {}
        local sceneId = stream:ReadWord()
        local sceneName = stream:ReadString()
        local killedNum = stream:ReadByte()
        local allNum = stream:ReadByte()
        table.insert(data, sceneId)
        table.insert(data, sceneName)
        table.insert(data, killedNum)
        table.insert(data, allNum)
        table.insert(datas,data)
    end
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI,"Activity.LiuJieUI",AppDef.UIType.PopWindow,datas)
    this:SendMsg(LGameMsg.m_initUIMsg)
    
end

--百花礼盒
-- function LuaNetRecvdMsg.DealMsgBaiHuaAward(stream)
--     local str = stream:ReadString()
--     local msg = stream:ReadString()
-- --    if #msg > 0 then
-- --        Utils:ShowScrollTips(msg)
-- --    end
--     local picList = {}
--     local data = string.split(str,"|")
--     for i = 1,#data do
--         local temp = string.split(data[i],",")
--         local itemType = tonumber(temp[1])
--         if #temp == 3 and itemType > 0 and itemType < 5 then --type 1物品,2经验，3潜能，4金币
--             local data = {}
--             if itemType == 2 then
--                 data.picId = 3007
--                 data.itemId = AppDef.AwrdItem.AWRD_ITEM_EXP
--                 data.itemNum = tonumber(temp[2])
--             elseif itemType == 3 then
--                 data.picId = 3008
--                 data.itemId = AppDef.AwrdItem.AWRD_ITEM_POTEN
--                  data.itemNum = tonumber(temp[2])
--             elseif itemType == 4 then
--                 data.picId = 3006
--                 data.itemId = AppDef.AwrdItem.AWRD_ITEM_COIN
--                 data.itemNum = tonumber(temp[2])
--             else
--                 local dItem = LItemMgr:getItem(tonumber(temp[2]))
--                 if dItem ~= nil then
--                     data.picId = dItem.m_pic
--                     data.itemId = dItem.m_id
--                     data.itemNum = tonumber(temp[3])
-- end
--             end
--             if data.itemId ~= nil then
--                 table.insert(picList,data)
--             end
--         end 
--     end
--     if #picList < 1 then
--         return
--     end
--     local awardList = {}
--     local getSign = 0
--     local get
--     for i = 1,#picList do
--        local pos = math.random(#picList)
--        table.insert(awardList,picList[pos])
--        table.remove(picList,pos)
--        if pos == 1 and getSign == 0 then
--            getSign = i
--        end
--     end
--     Utils:OpenRandPetUI(2,awardList,getSign,msg)
-- end

-----------------------------昆仑山从这里开始------------------------------------------------
function LuaNetRecvdMsg.DealKunlunshan(stream)
    local op = stream:ReadByte()
    if op == 1 then -- 进入昆仑山
        local suc = stream:ReadByte()
        this.SetCenterTip(stream:ReadString())
    elseif op == 2 then -- 排行榜
        this.ReadKunLunShanPaiHang(stream)
    elseif op == 3 then -- 个人活动信息
        this.ReadKunLunShanInfo(stream)
    elseif op == 4 then -- 昆仑山房间信息
        this.ReadRoomInfo(stream)
    elseif op == 5 then -- 切换房间
        local idx = stream:ReadWord()
        this.SetCenterTip(stream:ReadString())
    end
end

function LuaNetRecvdMsg.ReadKunLunShanPaiHang(stream)
    LRoleDataMgr.m_kunlunShanData.m_paiHangList = {}
    local num = stream:ReadByte()
    for i = 1, num do
        local temp = LKunLunShanPaiHang:New()
        temp.rank = i
        temp.roleId = stream:ReadUInt()
        temp.name = stream:ReadString()
        temp.score = stream:ReadWord()
        table.insert(LRoleDataMgr.m_kunlunShanData.m_paiHangList, temp)
    end

    if num > 0 then
        LGameMsg.m_netDealMsg:Change(LUIActivityEvent.RefreshKunlunRank, 0)
        this:SendMsg(LGameMsg.m_netDealMsg)
    end
end

function LuaNetRecvdMsg.ReadKunLunShanInfo(stream)
    local data = LRoleDataMgr.m_kunlunShanData
    data.m_score = stream:ReadWord()
    data.m_killRoleNum = stream:ReadWord()
    data.m_killMonsterNum = stream:ReadWord()
    data.m_nextFlushScecond = stream:ReadWord()
    data.m_timeSpace = stream:ReadWord()
    local num = stream:ReadByte()
    for i=1,num do
        local task = LKunLunShanTask:New()
        task.taskName = stream:ReadString()
        task.targetDesc = stream:ReadString()
        task.killNum = stream:ReadWord()
        task.award1 = stream:ReadString()
        task.award2 = stream:ReadString()
        task.isComplete = (stream:ReadByte() == 1)
        table.insert(data.killRoleTask, task)
    end

    num = stream:ReadByte()
    for i=1, num do
        local task = LKunLunShanTask:New()
        task.taskName = stream:ReadString()
        task.targetDesc = stream:ReadString()
        task.killNum = stream:ReadWord()
        task.award1 = stream:ReadString()
        task.award2 = stream:ReadString()
        task.isComplete = (stream:ReadByte() == 1)
        table.insert(data.killMonsterTask, task)
    end
    LGameMsg.m_netDealMsg:Change(LUIActivityEvent.RefreshKunlunInfo, 2)
    this:SendMsg(LGameMsg.m_netDealMsg)
end

function LuaNetRecvdMsg.ReadRoomInfo(stream)
    LRoleDataMgr.m_kunlunShanData.m_curRoom = stream:ReadWord()
    local num = stream:ReadWord()
    LRoleDataMgr.m_kunlunShanData.vecRoomInfo = {}
    for i=1, num do
        local temp = LRoomInfo:New()
        temp.roomID = stream:ReadWord()
        temp.peopleNum = stream:ReadUInt()
        temp.maxNum = stream:ReadUInt()
        table.insert(LRoleDataMgr.m_kunlunShanData.vecRoomInfo, temp)
    end

    LGameMsg.m_netDealMsg:Change(LUIActivityEvent.RefreshKunlunRoom, LRoleDataMgr.m_kunlunShanData.vecRoomInfo)
    this:SendMsg(LGameMsg.m_netDealMsg)
end

function LuaNetRecvdMsg.UpdateKunlunshan(stream)
    local op = stream:ReadByte()
    local value = stream:ReadUInt()
    local index = stream:ReadByte()
    local data = LRoleDataMgr.m_kunlunShanData
    if op == 1 then -- 历险点
        data.m_score = value
    elseif op == 2 then    -- 杀敌数
        data.m_killRoleNum = value
    elseif op == 3 then    -- 杀怪数
        data.m_killMonsterNum = value
    elseif op == 4 then    -- 杀敌任务
        if index < 0 or index > 3 then return end
        data.killRoleTask[index].isComplete = true
    elseif op == 5 then    -- 杀怪任务
        if index < 0 or index > 3 then return end
        data.killMonsterTask[index].isComplete = true
    elseif op == 6 then    -- 刷怪时间
        data.m_nextFlushScecond = value
    end

    LGameMsg.m_netDealMsg:Change(LUIActivityEvent.RefreshKunlunInfo, op)
    this:SendMsg(LGameMsg.m_netDealMsg)
end

-----------------------------昆仑山到这里结束------------------------------------------------

-- 灵气捐献
function LuaNetRecvdMsg.DealDonateInfo(stream)
    local Linqi = LRoleDataMgr.MyHeroInfo.m_pLingqi
    Linqi.nowCnt = stream:ReadUInt() -- 当前灵气
    Linqi.times = stream:ReadByte() -- 剩余次数
    for i=1,5 do
        Linqi.ids[i] = stream:ReadWord()
        Linqi.exps[i] = stream:ReadULongInt()
    end
    LGameMsg.m_netDealMsg:Change(LUIActivityEvent.RefreshDonate, 0)
    this:SendMsg(LGameMsg.m_netDealMsg)
end

-- 灵气捐献结果
function LuaNetRecvdMsg.DealDonateResult(stream)
    local tmp = stream:ReadByte()
    local ret = stream:ReadByte()
    if ret == 0 then -- faild
        this.SetCenterTip(stream:ReadString())
    elseif ret == 1 then
        LRoleDataMgr.MyHeroInfo.m_pLingqi.nowCnt = stream:ReadUInt()
        LRoleDataMgr.MyHeroInfo.m_pLingqi.times = LRoleDataMgr.MyHeroInfo.m_pLingqi.times or 0
        LRoleDataMgr.MyHeroInfo.m_pLingqi.times = math.max(tonumber(LRoleDataMgr.MyHeroInfo.m_pLingqi.times) - 1, 0)
        LGameMsg.m_netDealMsg:Change(LUIActivityEvent.RefreshDonate, 0)
        this:SendMsg(LGameMsg.m_netDealMsg)
    end
end

--好友信息
-- function LuaNetRecvdMsg.DealMsgFriendsList(stream)
--    --print("DealMsgFriendsListDealMsgFriendsListDealMsgFriendsListDealMsgFriendsList")
-- end

--[[
界面引导 1001 猜拳
]]
function LuaNetRecvdMsg.DealMsgGuideIndo(stream)
    local op = stream:ReadWord()
    if op == 1001 then
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Activity.GuessFistMainUI",AppDef.UIType.FirstClassLayer)
        this:SendMsg(LGameMsg.m_initUIMsg)
    elseif op == 1002 then
        LuaNetSendMsg:QueryQuestion(1)
    elseif op == 1004 then
        --打开组队界面
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Team.TeamMainUI",AppDef.UIType.FirstClassLayer,3)
        this:SendMsg(LGameMsg.m_initUIMsg)

        LGameMsg.m_netDealMsg:Change(LUIRoleTeamEvent.SetQuickTeamInd,3)
        this:SendMsg(LGameMsg.m_netDealMsg)
    end
end

--添加黑名单反馈
function LuaNetRecvdMsg.DealMsgAddBlack(stream)

--	GameLayer *gameLayer = (GameLayer *)pTarget
--	ark_Stream stream
--	stream:CreateReadStreamFromBuf(buf, len)

	local op = stream:ReadByte()
	if op == 1 then
--        TipsMgr::GetInstance()->SetCenterTip(RES_STRC(DataConsts::RSI_MDSI_MSGI17))
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, GUITips.RSI_MDSI_MSGI17)
        this:SendMsg(LGameMsg.m_scrollTipsMsg)
        --刷新界面
		LuaNetSendMsg:QueryBlackListInfo()
    else
		local msg = stream:ReadString()
--		TipsMgr::GetInstance()->SetCenterTip(msg)
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, msg)
        this:SendMsg(LGameMsg.m_scrollTipsMsg)
	end
end


--删除黑名单反馈
function LuaNetRecvdMsg.DealMsgDelBlack(stream)
    local op = stream:ReadByte()
--    LuaNetSendMsg:QueryBlackListInfo()
end

-----------------------------开服活动解析从这里开始------------------------------------------------
function LuaNetRecvdMsg.DealMsgKaifuHuodong(stream)
    local op = stream:ReadByte()
    print("DealMsgKaifuHuodong ==>", op)
    if op == 1 then --豪华礼包
    elseif op == 2 then --每日工资
    elseif op == 3 then --免费坐骑
    elseif op == 4 then --在线好礼
        this.OnLineAward(stream)
    elseif op == 5 then --7日登陆礼包
        this.DealLoginGiftBag(stream)
    elseif op == 6 then --升级礼包
    elseif op == 7 then --等级礼包
        this.DealLevelGiftBag(stream)
    elseif op == 8 then
    elseif op == 9 then --首充送礼
        this.DealFirstRecharge(stream)
    elseif op == 10 then --付费套餐
    elseif op == 11 then --连续登陆
    elseif op == 12 then --充值送礼
    elseif op == 13 then --开服冲级赛
    elseif op == 14 then --新服战力榜
    elseif op == 15 then --仙宠大收集
    elseif op == 16 then --强装有好礼
    elseif op == 17 then --摇钱树
        local op1 = stream:ReadByte()
        this.DealMsgYaoQianShu(stream,op1)
    elseif op == 18 then --每日首冲
        this.DealMsgDayRecharge(stream)
    elseif op == 19 then --节日礼包
    elseif op == 20 then --活动好礼
        this.DealRechargeGift(stream, 1)
        LRedDotCheckMgr:MainHuodongCheck()
    elseif op == 21 then --累计消费
        this.DealRechargeGift(stream, 2)
        LRedDotCheckMgr:MainHuodongCheck()
    elseif (op >= 26 and op <= 30) or op == 45 then--几个排行榜活动
        this.DealMsgActivityRanks(stream, op)
    elseif op == 33 or op == 92 then --砸蛋
        this.DealMsgZaDan(stream, op)
    elseif op == 34 then
        local opSendGift = stream:ReadByte()
        -- --print("opSendGift =", opSendGift)
        if opSendGift == 1 then
            local nationalGiftRankData = {}
            nationalGiftRankData.rankType = stream:ReadByte()
            local errcode = stream:ReadByte()
            -- --print("errcode ==>", errcode)
            if errcode > 0 then
                nationalGiftRankData.leftTime = stream:ReadUInt()
                local num = stream:ReadByte()
                -- --print("DealMsgKaifuHuodong num =>>>", num)
                nationalGiftRankData.sendRankDataList = {}
                nationalGiftRankData.acceptDataList = {}
                for i=1, num do
                    local nationalRankData = LNationalRankData:New()
                    nationalRankData.roleID = stream:ReadUInt()
                    nationalRankData.name = stream:ReadString()
                    nationalRankData.professor = stream:ReadByte()
                    nationalRankData.vip = stream:ReadByte()
                    nationalRankData.score = stream:ReadUInt()
                    local awardNum = stream:ReadByte()
                    for i=1, awardNum do
                        local itemData = {}
                        itemData.itemID = stream:ReadUInt()
                        itemData.itemNum = stream:ReadUInt()
                        table.insert(nationalRankData.itemInfo, itemData)
                    end
                
                    if nationalGiftRankData.rankType == 1 then
                        table.insert(nationalGiftRankData.sendRankDataList, nationalRankData)
                    else
                        table.insert(nationalGiftRankData.acceptDataList, nationalRankData)
                    end
                end
                nationalGiftRankData.ownRank = stream:ReadByte()
                nationalGiftRankData.ownRankScore = stream:ReadUInt()
                nationalGiftRankData.myItemInfo = {}
                local myAwardNum = stream:ReadByte()
                for i=1, myAwardNum do
                    local myItemData = {}
                    myItemData.itemID = stream:ReadUInt()
                    myItemData.itemNum = stream:ReadUInt()
                    table.insert(nationalGiftRankData.myItemInfo, myItemData)
                end
                -- ----dump(nationalGiftRankData, "DealMsgKaifuHuodong 111 ==>")

                LGameMsg.m_netDealMsg:Change(LUIWelfareActivityEvent.ReloadData, {WelfareActivityDef.Type.NationalDayGift, nationalGiftRankData})
                this:SendMsg(LGameMsg.m_netDealMsg)
            else
                local strMsg = stream:ReadString()
                Utils:ShowScrollTips(strMsg)
            end
        end
    elseif op == 35 or op == 36 then
        local opType = stream:ReadByte()
        if opType == 1 then
            local succ = stream:ReadByte()
            if succ == 0 then
                local ErrorInfo = stream:ReadString()
                Utils:ShowScrollTips(ErrorInfo)
            else
                --七天充值
                LRechargeDataMgr:updateSevenChargeData(stream)
                --更新UI
                -- LGameMsg.m_netDealMsg:Change(LUIWelfareEvent.updateSevenCharge)
                -- this:SendMsg(LGameMsg.m_netDealMsg)

                LGameMsg.m_netDealMsg:Change(LUIWelfareActivityEvent.ReloadData, {WelfareActivityDef.Type.SevenDaysChargeTag, nil})
                this:SendMsg(LGameMsg.m_netDealMsg)

                LGameMsg.m_netDealMsg:Change(LUILogicEvent.updatePreViewUI)
                this:SendMsg(LGameMsg.m_netDealMsg)
                
                LRedDotCheckMgr:MainHuodongCheck()
            end
        elseif opType == 2 then
            local opType2 = stream:ReadByte()
            local succ = stream:ReadByte()
            if(succ == 0)then
                local ErrorInfo = stream:ReadString()
                Utils:ShowScrollTips(ErrorInfo)
            else
                if(opType2 == 1)then  --每日奖励
                    local errorCode = stream:ReadByte()
                    if errorCode == 1 then
                        LGameMsg.m_netDealMsg:Change(LUIWelfareEvent.refrashSevenChargeUI)
                        this:SendMsg(LGameMsg.m_netDealMsg)
                    else
                        local ErrorInfo = stream:ReadString()
                        Utils:ShowScrollTips(ErrorInfo)
                    end
                elseif(opType2 == 2)then  --额外奖励
                    local errorCode = stream:ReadByte()
                    if errorCode == 1 then
                        LGameMsg.m_netDealMsg:Change(LUIWelfareEvent.refrashAwardBtn)
                        this:SendMsg(LGameMsg.m_netDealMsg)
                    else
                        local ErrorInfo = stream:ReadString()
                        Utils:ShowScrollTips(ErrorInfo)
                    end
                end
                LRedDotCheckMgr:MainHuodongCheck()
            end
        end
    elseif op == 42 then --次充送礼
        this.DealSecondRecharge(stream)
    elseif op == 50 then --国庆集字活动
        local nwOp = stream:ReadByte()
        --print("QueryKaifuHuodong op =", nwOp)
        if nwOp == 1 then --获取活动信息
            local errorCode = stream:ReadByte()
            --print("QueryKaifuHuodong errorCode =", errorCode)
            if errorCode > 0 then
                local collectWordData = LNationalCollectWrodData:New()
                collectWordData.timeMsg = stream:ReadString()
                local num = stream:ReadByte()
                for i=1, num do
                    local exchangeData = LExchangeWrodData:New()
                    exchangeData.index = stream:ReadUInt()
                    exchangeData.isSelAny = stream:ReadByte()
                    exchangeData.exchangeTimes = stream:ReadByte()
                    exchangeData.totalExchangeTimes = stream:ReadByte()

                    local numTemp = stream:ReadByte()
                    for i=1, numTemp do
                        local data = {}
                        data.id = stream:ReadUInt()
                        data.num = stream:ReadUInt()
                        table.insert(exchangeData.exchangeItems, data)
                    end

                    local itemNum = stream:ReadByte()
                    for i=1, itemNum do
                        local itemData = {}
                        itemData.id = stream:ReadUInt()
                        itemData.num = stream:ReadUInt()
                        table.insert(exchangeData.gainItems, itemData)
                    end
                    table.insert(collectWordData.allExchangeItems, exchangeData)

                    -- ----dump(exchangeData, "collectWordData =======>")
                end

                local marNum = stream:ReadByte()
                for i=1, marNum do
                    local item = {}
                    item.id = stream:ReadUInt()
                    item.num = stream:ReadUInt()
                    table.insert(collectWordData.exchageMaterial, item)
                end

                -- ----dump(collectWordData.exchageMaterial, "DealSecondRecharge")

                LGameMsg.m_netDealMsg:Change(LUIWelfareActivityEvent.ReloadData, {WelfareActivityDef.Type.NationDayCollectWord, collectWordData})
                this:SendMsg(LGameMsg.m_netDealMsg)

            else

            end
        else
            --兑换材料
            local data = {}
            data.exchangeIndex = stream:ReadUInt()
            data.tagIndex = stream:ReadByte()
            local errorCode = stream:ReadByte()
            -- --print("data.exchangeIndex =", data.exchangeIndex, errorCode)
            if errorCode > 0 then
                data.exchangeTimes = stream:ReadByte()
                data.totalExchangeTimes = stream:ReadByte()
                -- ----dump(data, "QueryKaifuHuodong ===>")
                -- Utils:SendMsg(LUIWelfareActivityEvent.updateExchangeWordUI, data)
                --兑换成功,更新UI
                LuaNetSendMsg:QueryNationalDayCoWord(50, 1)
            else
                local msg = stream:ReadString()
                Utils:ShowScrollTips(msg)
            end
        end
    elseif op == 74 then --发红包
    elseif op == 83 then --基金返利
        local opType = stream:ReadByte()
        if opType == 1 then
            local succ = stream:ReadByte()
            if succ == 0 then
                -- Utils:ShowScrollTips(stream:ReadString())
                Utils:SendMsg(LUIFundRebateEvent.LoadDataEvent, {0,0})
            else
                this.DealFundRebate(stream, 1)
            end
        elseif opType == 2 then
            Utils:SendMsg(LUIFundRebateEvent.GetRewardDataEvent, stream)
        end
    elseif op == 94 then --活跃基金
        local opType = stream:ReadByte()
        
        if opType == 1 then
            local succ = stream:ReadByte()
            --print("DealMsgActivityRanks ===>", op, succ)

            if succ == 0 then
                --Utils:ShowScrollTips(stream:ReadString())
                Utils:SendMsg(LUIHuoyueLayerEvent.LoadDataEvent, {0,0})
            else
                this.DealFundRebate(stream, 2)
            end

        elseif opType == 2 then
            Utils:SendMsg(LUIHuoyueLayerEvent.GetRewardDataEvent, stream)
        end
    elseif op == 84 then --神将折扣
        local opType = stream:ReadByte()
        if opType == 1 then
            local succ = stream:ReadByte()
            if succ == 0 then
                Utils:ShowScrollTips(stream:ReadString())
            else
                this.DealPetDiscount(stream)
            end
        elseif opType == 2 then
            local ind = stream:ReadByte()
            local succ = stream:ReadByte()
            if succ == 0 then
                Utils:ShowScrollTips(stream:ReadString())
            else
                Utils:SendMsg(LUIPetDiscountEvent.BuyResultEvent, ind)
            end
        elseif opType == 3 then
            local error = stream:ReadByte()
            LRoleDataMgr.m_petDiscPreView = stream:ReadUInt() --个位B,十位s,百位ss,千位sss
        end
    elseif op == 85 then
        this.DealMsgActivityRanks(stream, op)
    elseif op >= 86 and op <= 88 then --折扣礼包
        local opType = stream:ReadByte()
        if opType == 1 then
            local succ = stream:ReadByte()
            if succ == 0 then
                Utils:ShowScrollTips(stream:ReadString())
            else
                this.DealDiscountBag(stream, op)
            end
        elseif opType == 2 then
            local succ = stream:ReadByte()
            if succ == 0 then
                Utils:ShowScrollTips(stream:ReadString())
            else
                Utils:SendMsg(LUIDiscountBagEvent.BuyResultEvent)
                Utils:SendMsg(LUIMainEvent.UpdateDiscountBag, {type=op})
            end
        end
    elseif op >= 89 and op <= 91 then --新折扣礼包
        local opType = stream:ReadByte()
        if opType == 1 then
            local succ = stream:ReadByte()
            if succ == 0 then
                local msg = stream:ReadString()
                if #msg > 0 then
                    Utils:ShowScrollTips()
                end
                return
            end
            this.DealNewDiscountBag(stream, op)
        elseif opType == 2 then
            local succ = stream:ReadByte()
            local msg = stream:ReadString()
            if #msg > 0 then
                Utils:ShowScrollTips()
            end
            if succ ~= 0 then
                Utils:SendMsg(LUIDiscountBagEvent.NewBuyResultEvent)
                Utils:SendMsg(LUIMainEvent.UpdateDiscountBag, {type=op})
            end
        end
    elseif op == 0xff then --活动列表
        local ignore = {
            [83] = true,
            [86] = true,
            [87] = true,
            [88] = true,
            [89] = true,
            [90] = true,
            [91] = true,
            [94] = true,  --活跃基金
            [95] = true,
        }
        local num = stream:ReadByte()
        local datas = {}
        for i=1,num do
            local data = {}
            data.tag = stream:ReadUInt()
            data.uname = stream:ReadString()
            data.state = stream:ReadByte()
            data.newMask = stream:ReadByte()--按钮左边的“新”字标签
            data.endTime = stream:ReadUInt()
            if ignore[data.tag] == nil then
                table.insert(datas, data)
            end
            Utils:SendMsg(LUIRedDotEvent.RegisterRedDot, {id=RedDotDef.ID.HDBase+i, pid=RedDotDef.ID.HuoDong})
        end
        dump(datas, "DealMsgDayRecharge datas ==>")
        LRechargeDataMgr:updateWelfareActivityData(datas)
        LRoleDataMgr.m_showIndex = 0
        LGameMsg.m_netDealMsg:Change(LUIWelfareActivityEvent.InitListData, datas)
        this:SendMsg(LGameMsg.m_netDealMsg)

        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUILogicEvent.paymentPreview)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)

        LRedDotCheckMgr:MainHuodongCheck()
    end
end

--处理每日首冲消息
function LuaNetRecvdMsg.DealMsgDayRecharge(stream)
	local op = stream:ReadByte()
    local  succ = stream:ReadByte()
	if succ == 0 then   --失败
		local str = stream:ReadString()
		Utils:ShowScrollTips(str)
        return
    end
	if op == 1 then  
        --查询
		local data = LRechargeDataMgr:GetDailyRechargeData()
        data.wxSign = stream:ReadByte() --显示微信充值奖励标识
		data.chongzhi = stream:ReadByte()
		data.lingqu  = stream:ReadByte()
        if data.wxSign == 1 then
            data.wxchongzhi = stream:ReadByte()
		    data.wxlingqu  = stream:ReadByte()
        end
		local num  = stream:ReadByte()
		data.itemList = {}
		for i = 1,num do
			local awardType = stream:ReadWord()
			if awardType ~= AWRD_ITEM_PET then 
                local awardInfo = { ["id"] = 0, ["num"] = 0 } 
                awardInfo.id = awardType
                awardInfo.num = stream:ReadUInt()
                table.insert(data.itemList,awardInfo)
			else
				LuaNetRecvdMsg.ReadPetInfo(data.petData, stream)
            end
		end
        LGameMsg.m_netDealMsg:Change(LUIWelfareActivityEvent.ReloadData, {WelfareActivityDef.Type.MeiRiShouChong, nil})
        this:SendMsg(LGameMsg.m_netDealMsg)
	elseif op == 2 then  
        --领奖
        local data = LRechargeDataMgr:GetDailyRechargeData()
        data.lingqu = 1
		--通知页面领取状态变化
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIWelfareActivityEvent.DailyReChargeBtnState)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
	end
end

--商店
function LuaNetRecvdMsg.DealFirstRecharge(stream)
    local op = stream:ReadByte()
    if op == 1 then
        --状态查询
        local val = stream:ReadByte()
        LRoleDataMgr.m_firstRechargeState = val
        if val ~= 0 then  --不显示首冲，请求次冲
			LuaNetSendMsg:QueryKaifuHuodong(42,1) 
            return
	    end      
        --刷新主界面按钮
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIMainEvent.CheckFirstRechargeBtn)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
        
    elseif op == 2 then
        --获取首充奖励
        
        local data = LRechargeDataMgr:GetFirstRechargeData()
        data.itemList = {}
        data.petList = {}
        data.wingList = {}
        data.mountList = {}
        this.DealRechargeAwardInfo(data,stream)
        dump(data, "DealFirstRecharge =====>")
        --刷新首充界面
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIActivityEvent.RefreshFirstRechargeUI)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
        LRedDotCheckMgr:MainShouchongCheck()
    elseif op == 3 then
        --领取奖励
        local success = stream:ReadByte()
		if success == 0 then
			local str = stream:ReadString()
			Utils:ShowScrollTips(str)
            return
        end
        --不显示首冲，请求次冲
        LRoleDataMgr.m_firstRechargeState = 1
        LuaNetSendMsg:QueryKaifuHuodong(42,1) 
        LuaNetSendMsg:QueryKaifuHuodong(42,2) 
         --刷新主界面按钮
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIMainEvent.CheckFirstRechargeBtn)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
    end
end

--次充
function LuaNetRecvdMsg.DealSecondRecharge(stream)
	local op = stream:ReadByte()
    if op == 1 then --首充按钮开关Btn_Play
		local val = stream:ReadByte()
	    LRoleDataMgr.m_secondRechargeState = val

        --刷新主界面按钮
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIMainEvent.CheckFirstRechargeBtn)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
	elseif op == 2 then
		local data = LRechargeDataMgr:GetSecondRechargeData()
        data.itemList = {}
        data.petList = {}
        data.wingList = {}
        data.mountList = {}
        this.DealRechargeAwardInfo(data,stream)
        --刷新次充界面
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIActivityEvent.RefreshFirstRechargeUI)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
        LRedDotCheckMgr:MainShouchongCheck()
	elseif op == 3 then
		local success = stream:ReadByte()
		if success == 0 then
			local str = stream:ReadString()
			Utils:ShowScrollTips(str)
            return
        end
        LRoleDataMgr.m_secondRechargeState = 1
         --刷新主界面按钮
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIMainEvent.CheckFirstRechargeBtn)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
     end
end

--首充次充奖励解析
function LuaNetRecvdMsg.DealRechargeAwardInfo(data,stream)
    data.isPaid = (stream:ReadByte() == 1)--是否已支付
	stream:ReadByte()   --是否已领取（0表示可领取）
	data.cash = stream:ReadUInt()   --兑换元宝
    local size = stream:ReadByte()
	if size > 5 then size = 5 end
    data.itemList = {}
    data.petList = {}
    data.wingList = {}
	for i = 1,size do
        local info = this.ReadAwardInfo(stream)
        if info ~= nil then
            if info.awardType == AppDef.EAwardType.EAT_ITEM then
                local awardInfo = { ["id"] = 0, ["num"] = 0 } 
                awardInfo.id = info.id
                awardInfo.num = info.value
                table.insert(data.itemList,awardInfo)
            elseif info.awardType == AppDef.EAwardType.EAT_PET then
                table.insert(data.petList,info.petData)
            elseif info.awardType == AppDef.EAwardType.EAT_WIND then
                table.insert(data.wingList,info.id)
            elseif info.awardType == AppDef.EAwardType.EAT_HORSE then
                table.insert(data.mountList,info.id)
            end
        end
    end
    if LRoleDataMgr.m_firstRechargeState ~= 0 then
        data.nowYB = stream:ReadUInt()
	    data.needYB = stream:ReadUInt()
    end
end

--奖励信息解析
function LuaNetRecvdMsg.ReadAwardInfo(stream)
    local info = LAwardData:new()
	local id = stream:ReadWord()

	if id == 0 then
		stream:ReadWord()
        return nil
	elseif id < AppDef.AwrdItem.AWRD_ITEM_COIN 
        or id == AppDef.AwrdItem.AWRD_ITEM_COIN 
        or id == AppDef.AwrdItem.AWRD_ITEM_BDYB 
        or id == AppDef.AwrdItem.AWRD_ITEM_YUANBAO 
        or id == AppDef.AwrdItem.AWRD_ITEM_POTEN then
        info.id = id
		info.value = stream:ReadUInt()
        info.awardType = AppDef.EAwardType.EAT_ITEM
	elseif id == AppDef.AwrdItem.AWRD_ITEM_PET then
		local pid = stream:ReadUInt()
        if pid ~= 0 then
            info.petData = clone(LDataConstMgr:GetPetData(pid))
            if info.petData == nil then
                info.petData = clone(LDataConstMgr:GetPetData(10))
            end
            local star = stream:ReadByte()
            if star ~= 0 then
                info.petData.star = star
            end

            local level = stream:ReadByte()
            if level ~= 0 then
                info.petData.level = level
            end
--            LuaNetRecvdMsg.ReadPetInfo(info.petData, stream)
            info.awardType = AppDef.EAwardType.EAT_PET
        end
    elseif id == AppDef.AwrdItem.AWRD_ITEM_WINDS then
        info.id = stream:ReadUInt()
        info.awardType = AppDef.EAwardType.EAT_WIND
    elseif id == AppDef.AwrdItem.AWRD_ITEM_ARTIFACT then
        info.id = stream:ReadUInt()
        info.awardType = AppDef.EAwardType.EAT_ARTIFACT
    elseif id == AppDef.AwrdItem.AWRD_ITEM_HORSE then
        info.id = stream:ReadUInt()
        info.value = stream:ReadUInt()
        info.awardType = AppDef.EAwardType.EAT_HORSE
    elseif id == AppDef.AwrdItem.AWRD_ITEM_CHENGHAO then
        local addtionData = {}
        this.ReadMedalAddition(medalID, stream, addtionData)
        info["medalID"] = medalID
        info["addtionData"] = addtionData
	end
    return info
end

--7日登陆礼包
function LuaNetRecvdMsg.DealLoginGiftBag(stream)
    local op = stream:ReadByte()
    if op == 1 then -- 状态查询
        local loginGift = LRoleDataMgr.MyHeroInfo.m_pLoginGift
        loginGift.getNum = stream:ReadByte()   --当前登录天数(从1开始)
        loginGift.num = stream:ReadByte()
        loginGift.dayInfo = {}
        for i=1, loginGift.num do
            local info = LTaocanInfo:New()
            info.haveGet = Utils:ToBool(stream:ReadByte())
            local awradNum = stream:ReadByte()

            for j=1, awradNum do
                local arr = LuaNetRecvdMsg.ReadCommonReward(stream)
				table.insert(info.reward, arr)
            end          
            table.insert(loginGift.dayInfo, info)
        end
    elseif op == 2 then--领奖励
        local day = stream:ReadByte()
        local suc = stream:ReadByte()
		print("============================>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>",suc)
        if 1 == suc then
			local awradNum = stream:ReadByte()
			local rewards = {}
			for j=1, awradNum do
                local arr = LuaNetRecvdMsg.ReadCommonReward(stream)
				table.insert(rewards, arr)
            end
			dump(rewards,"==============DealLoginGiftBagaaaaaaaaaaaaaaaaaaaaa==============>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
            Utils:SendMsg(LUIWelfareEvent.RefreshLoginGiftPage, day)
        else
            -- 已领取
            local type = stream:ReadByte()
            local msg
            if type == 1 then
                msg = GUITips.RSI_MDSI_MSGI38
            elseif type == 2 then
                msg = GUITips.RSI_MDSI_MSGI39
            -- elseif type == 3 then
            --走通用tips
            --     msg = stream:ReadString()
            end
            this.SetCenterTip(msg)
        end
    end
end

--[[
等级礼包
]]
function LuaNetRecvdMsg.DealLevelGiftBag(stream)
    local op = stream:ReadByte()
    if op == 1 then--状态查询
        if stream:ReadByte() == 0 then
            -- mainmenu->RemoveMenuItemByTag(GameMenu::MTG_LEVEL_WARD)
            -- DATA_MGR->MainMenu.setActive(true,DataMgr::CMainMenu::BT_DENGJI)
        end
    elseif op == 2 then --领奖励
        if stream:ReadByte() == 0 then
--走通用tips
--            this.SetCenterTip(stream:ReadString())
        else
            local index = stream:ReadByte()
            LRoleDataMgr.MyHeroInfo.m_pLevelWard[index + 1].canBuy = false
        
            LGameMsg.m_netDealMsg:Change(LUIWelfareEvent.RefreshLevelGiftPage, index)
            this:SendMsg(LGameMsg.m_netDealMsg)
        end
    elseif op == 3 then--礼包内容
        LRoleDataMgr.MyHeroInfo.m_pLevelWard = {}
        local pians_num = stream:ReadByte()
        for i = 1, pians_num do
            local info = LTaocanInfo:New()
            info.pian_index = i
            info.levelId = stream:ReadByte()
            info.canBuy  = (stream:ReadByte() == 0)
            info.level   = stream:ReadByte()
            local num = stream:ReadByte()
            for j=1, num do
                local Iid = stream:ReadWord()
                if Iid == 0 then
                    stream:ReadUInt()
                    stream:ReadUInt()
                elseif Iid < AppDef.AwrdItem.AWRD_ITEM_COIN
                        or Iid == AppDef.AwrdItem.AWRD_ITEM_COIN     -- 金币
                        or Iid == AppDef.AwrdItem.AWRD_ITEM_BDYB     -- 绑定元宝
                        or Iid == AppDef.AwrdItem.AWRD_ITEM_YUANBAO  -- 元宝
                        or Iid == AppDef.AwrdItem.AWRD_ITEM_EXP      -- 经验
                        or Iid == AppDef.AwrdItem.AWRD_ITEM_POTEN    -- 潜能
                        or Iid == AppDef.AwrdItem.AWRD_ITEM_PETEQUIP    -- 神将装备
                        then
                    local Inum = stream:ReadUInt()
                    local star = stream:ReadUInt()
                    table.insert(info.ItemId, Iid)
                    table.insert(info.ItemNum, Inum)
                    table.insert(info.value, star)
                    --       info.value=star
                    -- ----print("星级"..star.."数量"..Inum)
                elseif Iid == AppDef.AwrdItem.AWRD_ITEM_BDYB then
                    local Inum = stream:ReadUInt()
                    stream:ReadUInt()
                    table.insert(info.ItemId, Iid)
                    table.insert(info.ItemNum, Inum)
                elseif Iid == AppDef.AwrdItem.AWRD_ITEM_PET then--宠物
                    local pid = stream:ReadWord()
                    local data = LPetData:New(pid)
                    LuaNetRecvdMsg.ReadPetInfo(data,stream)
                    table.insert(info.petdata, data)
                elseif Iid == 60003 then--道具
                    local item = LPItem:New()
                    stream:ReadUInt()
                    LuaNetRecvdMsg.ReadItemData(item,stream)
                    table.insert(info.ItemData, item)
                end

            end
            table.insert(LRoleDataMgr.MyHeroInfo.m_pLevelWard, info)
        end
    end
end

--摇钱树
function LuaNetRecvdMsg.DealMsgYaoQianShu(stream,op)  
    if op == 1 then	
        local success = stream:ReadByte()
        if success == 0 then
            --失败
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
            return
        end
        --成功
        local num = stream:ReadByte()
        for i=1,num do
            local type = stream:ReadByte()
            local data = LActivityManager.m_moneyTreeData[type]  
            if data == nil then 
                data = LMoneyTreeData:new()
                data.type = type
                LActivityManager.m_moneyTreeData[type] = data
            end 
            data.useNum = stream:ReadByte()
            data.freeNum = stream:ReadByte()
            data.maxNum = stream:ReadByte()
            data.costType = stream:ReadWord()
            data.costValue = stream:ReadUInt()
            data.getType = stream:ReadWord()
            data.getValue = stream:ReadUInt()
        end
        --刷新摇钱树界面
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIActivityEvent.RefreshMoneyTreeUI)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
    elseif op == 2 then    
        --local data = LMoneyTreeData:new()
        local type = stream:ReadByte()      
        
        local success = stream:ReadByte()
        if success == 0 then
            --失败
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
            return	
        end
        --成功
        local data = LActivityManager.m_moneyTreeData[type]  
        if data == nil then 
            data = LMoneyTreeData:new()
            data.type = type
            LActivityManager.m_moneyTreeData[type] = data
        end
        data.useNum = stream:ReadByte()
        data.freeNum = stream:ReadByte()
        data.maxNum = stream:ReadByte()
        data.costType = stream:ReadWord()
        data.costValue = stream:ReadUInt()
        data.getType = stream:ReadWord()
        data.getValue = stream:ReadUInt()
        --刷新摇钱树界面
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIActivityEvent.RefreshMoneyTreeUI)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
        --播放摇钱树动画
        LGameMsg.m_netDealMsg:Change(LUIActivityEvent.MoneyEffectPlay,type)
        this:SendMsg(LGameMsg.m_netDealMsg)
        --音效
        LGameMsg.m_audioMsg:Change(LAudioEvent.PlayEffect, AppDef.SysBGM.Money_Tree)
        this:SendMsg(LGameMsg.m_audioMsg)
    end  
end

function LuaNetRecvdMsg.ReadMedalAddition(medelId, stream, additionInfo)

    local detail = LDataConstMgr:GetMedalNote(medelId)
    additionInfo.addHurt = detail.damage
    additionInfo.addRecovery = detail.recovery
    additionInfo.addHp = detail.maxHp
    additionInfo.addSpeed = detail.speed
    additionInfo.addPetHurt = detail.petMaxHp
    additionInfo.addPetRecovery = detail.petRecovery
    additionInfo.addPetHp = detail.petMaxHp
    additionInfo.addPetSpeed = detail.petSpeed
    additionInfo.zhandouli = stream:ReadUInt()

end
--[[
读取奖励内容
]]
function LuaNetRecvdMsg.ReadAwardData(stream, award)
    local id = stream:ReadWord()
    if id < AppDef.AwrdItem.AWRD_ITEM_COIN then--道具
        local itemId = id
        local itemNum = stream:ReadUInt()
        award["itemId"] = itemId
        award["itemNum"] = itemNum
    elseif id == AppDef.AwrdItem.AWRD_ITEM_PET then --宠物
        local id = stream:ReadUInt()
        local petdata = clone(LDataConstMgr:GetPetData(id))
        local star = stream:ReadByte()
        if star ~= 0 then
            petdata.star = star
        end

        local level = stream:ReadByte()
        if level ~= 0 then
            petdata.level = level
        end

        award["petdata"] = petdata
    elseif id == AppDef.AwrdItem.AWRD_ITEM_CHENGHAO then --称号
        local medalID = stream:ReadUInt()
        local addtionData = {}
        this.ReadMedalAddition(medalID, stream, addtionData)
        award["medalID"] = medalID
        award["addtionData"] = addtionData
    else--几种金币，元宝，代币
        local num = stream:ReadUInt()
        award["num"] = num
    end
    award["id"] = id
end
--[[
排行榜活动解析
]]
function LuaNetRecvdMsg.DealMsgActivityRanks(stream, opt)
    local succ = stream:ReadByte()
    if (succ == 0) then
        local ErrorInfo = stream:ReadString()
        Utils:ShowScrollTips(ErrorInfo)
    elseif(succ == 1) then
        --state 0未开始 1进行中 2已结束
        local result = {}
        local state = stream:ReadByte()
        local desc = stream:ReadString()
        local cdTime = stream:ReadUInt()
        if opt == 85 then
            local curCir = stream:ReadByte() --当前第几届
            result["curCir"] = curCir
        end
        local roledatas = {}
        local size = stream:ReadByte()
        for k=1,size do
            local roledata = {}   
            roledata.role_id = stream:ReadUInt()
            roledata.role_name = stream:ReadString()
            roledata.pet_name = stream:ReadString()
            roledata.value = stream:ReadUInt()
            local award_size = stream:ReadByte()
            roledata.awarddatas = {}
            for i = 1,award_size do
                local award = {}
                LuaNetRecvdMsg.ReadAwardData(stream, award)
                table.insert(roledata.awarddatas, award)
            end
            table.insert(roledatas, roledata)
        end
        local my_data = stream:ReadString()
        local my_paihang = stream:ReadByte()
        result["state"] = state
        result["desc"] = desc
        result["cdTime"] = cdTime
        result["roledatas"] = roledatas
        if my_data == "" then
            my_data = LuaStr_Str23  --"无"
        end
        result["my_data"] = my_data
        result["my_paihang"] = my_paihang

        local rankType = 0
        if opt == 26 then
            rankType = WelfareActivityDef.Type.ZuiQiangShenChongBang
        elseif opt == 27 then
            rankType = WelfareActivityDef.Type.XianJiaQiangHuaBang
        elseif opt == 28 then
            rankType = WelfareActivityDef.Type.DengJiChongCiBang
        elseif opt == 29 then
            rankType = WelfareActivityDef.Type.QunXianZhanLiBang
        elseif opt == 30 then
            rankType = WelfareActivityDef.Type.XinFuChongZhiBang
        elseif opt == 45 then
            rankType = WelfareActivityDef.Type.ShenJiYuYiBang
        elseif opt == 85 then
            rankType = WelfareActivityDef.Type.XianHuaBang
        end

        LGameMsg.m_netDealMsg:Change(LUIWelfareActivityEvent.ReloadData, {rankType, result})
        this:SendMsg(LGameMsg.m_netDealMsg)

--        ------dump(result.roledatas[1], "result ======================================")

    end
end

--[[
充值送礼
]]
function LuaNetRecvdMsg.DealRechargeGift(stream, tag)
    local op = stream:ReadByte()
    if op == 0 then
        local info
        if tag == 1 then
            LRoleDataMgr.MyHeroInfo.m_pRechargetGift.awardInfo = {}
            info = LRoleDataMgr.MyHeroInfo.m_pRechargetGift
        else 
            LRoleDataMgr.m_consumptionGiftData.awardInfo = {}
            info = LRoleDataMgr.m_consumptionGiftData
        end

        info.chongzhi = stream:ReadUInt()
        info.desTime = stream:ReadString()
        local num = stream:ReadByte()
        for i = 1, num do
            local award = LAwardInfo:New()
            award.index = stream:ReadByte()
            award.yubao = stream:ReadUInt()
            award.isGetAward  = stream:ReadByte() > 0
            local typeNum = stream:ReadByte()
            for j=1, typeNum do
                local Iid = stream:ReadWord()
                if Iid == AppDef.AwrdItem.AWRD_ITEM_CHENGHAO then--称号
                    local titleId = stream:ReadUInt()
                    local power = stream:ReadUInt()
                    table.insert(award.awardItemId, Iid)
                    table.insert(award.awardItemNum, titleId)
                elseif Iid ~= AppDef.AwrdItem.AWRD_ITEM_PET then -- 非宠物
                    local Inum = stream:ReadUInt()
                    table.insert(award.awardItemId, Iid)
                    table.insert(award.awardItemNum, Inum)
                elseif Iid == AppDef.AwrdItem.AWRD_ITEM_PET then--宠物
                    local pid = stream:ReadUInt()
                    if pid ~= 0 then
                        local data = clone(LDataConstMgr:GetPetData(pid))
                        local star = stream:ReadByte()
                        if star ~= 0 then
                            data.star = star
                           
                        end

                        local level = stream:ReadByte()
                        if level ~= 0 then
                            data.level = level
                        end
                        table.insert(award.awardItemId, Iid)
                        table.insert(award.awardItemNum, 1)
                        table.insert(award.awardPet, data)
                    end
                end
            end
            table.insert(info.awardInfo, award)
        end
        if tag == 1 then
            LGameMsg.m_netDealMsg:Change(LUIWelfareActivityEvent.ReloadData, {WelfareActivityDef.Type.RechargeGift, nil})
            this:SendMsg(LGameMsg.m_netDealMsg)
        else
            LGameMsg.m_netDealMsg:Change(LUIWelfareActivityEvent.ReloadData, {WelfareActivityDef.Type.ConsumptionGift, nil})
            this:SendMsg(LGameMsg.m_netDealMsg)
        end
--        ------dump(info, "充值送豪礼")
    elseif op == 1 then
        local index = stream:ReadByte()
        local success = stream:ReadByte()
        if success == 0 then
            this.SetCenterTip(stream:ReadString())
        else
            if tag == 1 then
                --充值送礼
                LGameMsg.m_netDealMsg:Change(LUIWelfareActivityEvent.updateRechargeUI)
                this:SendMsg(LGameMsg.m_netDealMsg)
            else
                --消费送礼
                LGameMsg.m_netDealMsg:Change(LUIWelfareActivityEvent.updateConsumAwardUI)
                this:SendMsg(LGameMsg.m_netDealMsg)
            end
            
        end
    end
end

-----------------------------开服活动解析到这里结束------------------------------------------------

--[[
请求他人的人物信息
]]
function LuaNetRecvdMsg.DealMsgOtherPlayerInfo(stream)
    LRoleDataMgr.OtherHeroInfo.VecFightPet = {}
    LRoleDataMgr.OtherHeroInfo.Horse = {}
    LRoleDataMgr.OtherHeroInfo.MapEquip = {}
    LRoleDataMgr.OtherHeroInfo.MapFaBao = {}
    local heroData = LRoleDataMgr.OtherHeroInfo
    heroData.id = stream:ReadUInt()
	local idtype = stream:ReadByte()
	local suc = stream:ReadByte()
    if suc == 0 then
        local msg = stream:ReadString()
        Utils:ShowScrollTips(msg)
        return
    end
    heroData.vipLevel = stream:ReadByte()
    heroData.name = stream:ReadString()
    heroData.sex = stream:ReadByte()
    heroData.model = stream:ReadByte()
    heroData.head = stream:ReadByte()
    heroData.level = stream:ReadWord()
    heroData.DetailData.exp = stream:ReadULongInt()
    heroData.zhanDouLi = stream:ReadULongInt()--战斗力

    heroData.DetailData.gong =  stream:ReadUInt()--帮派ID
    heroData.DetailData.gongName = stream:ReadString()
    heroData.ShapeId = stream:ReadUInt()
    heroData.shapeIdState = stream:ReadByte()  -- 变身状态
    --神器
    heroData.ShenQiAddition.id = stream:ReadUInt()
    heroData.WingsId = stream:ReadByte()
    local formationdata = {}
    formationdata.Id = stream:ReadWord()
    formationdata.Lv = stream:ReadWord()
    --出战宠物信息
    local num = stream:ReadByte()
    for  i=1, num do
        local pid = stream:ReadWord()
        local data = LPetData:New(pid)
        this.ReadPetInfo(data, stream)
        heroData.VecFightPet[i]= data
        if LRankDataMgr.m_value == pid then
            LRoleDataMgr.OtherHeroInfo.m_PetIdx = i
        end
    end

    --称号
    local titleNum = stream:ReadByte()
    if titleNum > 0 then
        heroData.MedalAddition.id = stream:ReadWord()
        heroData.MedalAddition.zhandouli = stream:ReadUInt()    
        local detail = LDataConstMgr:GetMedalNote(heroData.MedalAddition.id)
        heroData.MedalAddition.addHp = detail.maxHp
        heroData.MedalAddition.addHurt = detail.damage
        heroData.MedalAddition.addRecovery = detail.recovery
        heroData.MedalAddition.addSpeed = detail.speed
        heroData.MedalAddition.addPetHp = detail.petMaxHp
        heroData.MedalAddition.addPetHurt = detail.petDamage
        heroData.MedalAddition.addPetRecovery = detail.petRecovery
        heroData.MedalAddition.addPetSpeed = detail.petSpeed

    end
	--阵容相关
	local fdata = LCFormation:New()
    fdata.useId = stream:ReadWord()
    local num = stream:ReadByte()
    local list = fdata:ResetMyFormations()
    for i = 1, num do
        local fid = stream:ReadWord()
        local flv = stream:ReadByte()
        table.insert(list,{fid,flv})
    end
	--dump(heroData,"================fdata================>>")
	local Pet = LCPet:New()--神将相关数据
	Pet.ShowPosList = {}
    local fightNum = stream:ReadByte()
    --阵容展示位置
    for i=1, fightNum do
        local pid = stream:ReadWord()
        Pet.ShowPosList[i] = pid
    end

    --出站位置
	local formationlist = {}
    local formationPosNum = stream:ReadByte()
    for i=1, formationPosNum do
        local pid = stream:ReadWord()
		table.insert(formationlist, pid)
	end

    --装备、法宝
    local num  = stream:ReadByte()--上阵神将数量
    for i=1,num do
        local equipNum = stream:ReadByte()-- 穿戴数量
        --print("equipNum equipNum equipNum",equipNum,i)
        for k=1,equipNum do
            local pos = stream:ReadByte()
            --print("pos pos pos",pos,k)
            if pos <= 4 then
                local value = LPetEquipInfo:New()
                this.ReadPetEquipData(value, stream)
                if value.m_uid > 0 and value.m_id > 0 then
                    if LRoleDataMgr.OtherHeroInfo.MapEquip[value.m_fpos] == nil then
                        LRoleDataMgr.OtherHeroInfo.MapEquip[value.m_fpos] = {}
                    end
                    LRoleDataMgr.OtherHeroInfo.MapEquip[value.m_fpos][value.m_wpos] = value
                end
            else
                local value = LPetFaBaoInfo:New()
                this.ReadPetFaBaoData(value,stream)
                if value.m_uid > 0 and value.m_id > 0 then
                    if LRoleDataMgr.OtherHeroInfo.MapFaBao[value.m_fpos] == nil then
                        LRoleDataMgr.OtherHeroInfo.MapFaBao[value.m_fpos] = {}
                    end
                    LRoleDataMgr.OtherHeroInfo.MapFaBao[value.m_fpos][value.m_wpos] = value
                end
            end
        end
    end
    --dump(LRoleDataMgr.OtherHeroInfo.MapEquip)
    --dump(LRoleDataMgr.OtherHeroInfo.MapFaBao)
    --dump(Pet,"================Pet================>>")
	if idtype == 1 then
		local zhenfaInfo = {}
		zhenfaInfo.zhengfaId = fdata.useId
		zhenfaInfo.zhengfaData = formationlist--Pet.ShowPosList
		zhenfaInfo.isRole = true
		LGameMsg.m_netDealMsg:Change(LUIKunLunEvent.GetRobotZhenFaInfo, zhenfaInfo)
        this:SendMsg(LGameMsg.m_netDealMsg)
	else
		local fId = AppDef.EModuleID.EMID_OTHER_ROLE_INFO
		if LRankDataMgr.m_value > 0 then
			fId = AppDef.EModuleID.EMID_OTHER_PET_INFO
		end
		Utils:OpenFunction(fId,nil,true)
	end
	-- LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "OtherRole.OtherRoleMainUI",AppDef.UIType.PopFirstClassLayer, 1)
	-- this:SendMsg(LGameMsg.m_initUIMsg)
end

-- -----------------------------------
-- 通天塔
function LuaNetRecvdMsg.DealMsgTower(stream)
    local op = stream:ReadByte()
    local rsp = {}
    if op == 1 then 
        local  op_ch = stream:ReadByte()
        if op_ch == 1 then 
            rsp.heroID = stream:ReadUInt()
            rsp.hereName = stream:ReadString()
            rsp.heroSex = stream:ReadByte()
            rsp.heroProfessional = stream:ReadByte()
            rsp.heroWuqi = stream:ReadWord()
            rsp.heroPosX = stream:ReadWord()
            rsp.heroPosY = stream:ReadWord()
        end
        return rsp 
    end 

    if op == 2 then 
        rsp.hasEnterTimes = stream:ReadByte()
        rsp.maxEnterTimes = stream:ReadByte()
        rsp.highclass = stream:ReadWord()  -- 历史最高层
        rsp.bazhuNum = stream:ReadByte()
        rsp.preclass = 1886
        rsp.classinfo = {}
        for k = 1, rsp.bazhuNum do
            if k <= 5 then
                local info = {}
                info.awards = {}
                info.heros = {}
                local heroClass = stream:ReadWord() -- 层号
                info.class = heroClass
                local  jiangLiAll = stream:ReadByte()
                info.awardsnum = jiangLiAll
                for i = 1 , jiangLiAll do
                    local  goodinfo = {}
                    goodinfo.heroclass = k
                    goodinfo.id = stream:ReadWord()
                    goodinfo.num = stream:ReadByte()
                    goodinfo.awardNum = jiangLiAll
                    table.insert(info.awards, goodinfo)
                end
                local herodata = {}
                herodata.id = stream:ReadUInt()
                if herodata.id ~= 0 then 
                    herodata.name = stream:ReadString()
                    herodata.sex = stream:ReadByte()
                    herodata.professional = stream:ReadByte()
                    herodata.heroWuqi = stream:ReadWord()
                    herodata.WingsId = stream:ReadByte()
                    table.insert(info.heros, herodata)
                end 
            table.insert(rsp.classinfo, info)
            end 
        end
        LGameMsg.m_netDealMsg:Change(LUITowerEvent.TowerKingData, rsp)
        this:SendMsg(LGameMsg.m_netDealMsg)
    end

    local function showItemTips(id, iNum)
        local name = ""
        if id < AppDef.AwrdItem.AWRD_ITEM_COIN then
            local itemData = LItemMgr:getItem(id)
            name = (itemData and itemData.m_name or "")
        else
            name = AppDef.AwrdItemName[id]
        end
        if name and #name > 0 then
            local msg = string.format(GUITips.RSI_TOWER_TIP1, iNum, name)
            Utils:ShowScrollTips(msg)
        end
    end

    if op == 3 or op == 4 or op == 5 then 
        rsp.errcode = stream:ReadByte()
        if rsp.errcode == 0 then 
            rsp.errmsg = stream:ReadString()
        elseif op == 4 then
            local num = stream:ReadByte()
            for i=1,num do
                local id = stream:ReadWord()
                local iNum = stream:ReadUInt()
                -- showItemTips(id, iNum)
            end
        end
        
        rsp.op = op
        LGameMsg.m_netDealMsg:Change(LUITowerEvent.TowerSaoDang, rsp)
        this:SendMsg(LGameMsg.m_netDealMsg)

        return  
    end 

    if op == 6 then
        rsp.currTimes = stream:ReadByte()        --当前所用次数
        rsp.MaxTimes = stream:ReadByte()         -- 最大次数
        rsp.currClass = stream:ReadWord()        -- 当前层数
        rsp.MaxClass = stream:ReadWord()         -- 最大层数
        rsp.allClass = stream:ReadWord()         -- 总层数
        rsp.jingyan = stream:ReadULongInt()      -- 经验值
        rsp.firstClimbBattle = stream:ReadByte() -- 1首次，0 非首次
        
        local itemLoop = stream:ReadByte()             -- 物品数量
        rsp.items = {}
        for i = 1, itemLoop do 
            local itemid = stream:ReadWord()
            table.insert(rsp.items, itemid)
        end
        
        rsp.mounsters = {}--用于显示怪物模型
        rsp.classMounster = {}
        local  classNum = stream:ReadByte()   --层数
        for i=1,classNum do
            local classMounsterInfo = {}
            classMounsterInfo.fid = stream:ReadByte()--阵法

            local mCount = stream:ReadByte()   --怪物数量
            classMounsterInfo.mounsters = {}
            for j=1,mCount do
                local mons = {}
                mons.id = stream:ReadUInt()
                mons.name = stream:ReadString()
				mons.data = nil
				if pcall(function() mons.data = LDataConstMgr:GetMonsterData(mons.id) end) == false then
					mons.data = nil
				end
                if mons.data then
                    mons.pic = mons.data.pic
                else
                    mons.pic = mons.id
                end
                mons.level = stream:ReadByte()
                mons.quality = stream:ReadByte()
                mons.type = stream:ReadByte()
                mons.face = 0
                if j == 1 then
                    table.insert(rsp.mounsters, mons)
                end
                table.insert(classMounsterInfo.mounsters, mons)
            end
            table.insert(rsp.classMounster, classMounsterInfo)
        end
        LGameMsg.m_netDealMsg:Change(LUITowerEvent.TowerInfo, rsp)
        this:SendMsg(LGameMsg.m_netDealMsg)
        return  
    end 

    if op == 7 then--刷新霸主界面
        LuaNetSendMsg:QueryTowerInfo(2)
        rsp.errcode = stream:ReadByte()
        return rsp 
    end
    
    if op == 8 then 
        return rsp 
    end

    if op == 9 or op == 11 then
        local cData = LCopyAwardData:New()
        rsp.towerhigh = stream:ReadWord()
        cData.attachData = rsp.towerhigh

        local loop = stream:ReadByte()
        rsp.items = {}
        for i = 1, loop do 
            local item = {}
            item.id = stream:ReadWord()
            item.num = stream:ReadUInt()
            table.insert(rsp.items, item)
            table.insert(cData.itemId, item.id)
            table.insert(cData.itemVal1, item.num)
        end

        if op == 11 then
            for i=1,#rsp.items do
                local id = rsp.items[i].id
                local iNum = rsp.items[i].num
                -- showItemTips(id, iNum)
            end
        else
            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "FirstAward.FirstRewardUI",AppDef.UIType.PopWindow, {1, cData})
            this:SendMsg(LGameMsg.m_initUIMsg)
        end
        return rsp 
    end

    if op == 10 then 
        rsp.errcode = stream:ReadByte()
        if rsp.errcode ~= 1 then 
            rsp.errmsg = stream:ReadString()
        end
        LGameMsg.m_netDealMsg:Change(LUITowerEvent.TowerReset, rsp)
        this:SendMsg(LGameMsg.m_netDealMsg)
        return
    end
end


function LuaNetRecvdMsg.DealMsgMedalList(stream)
    
    
    local num = stream:ReadWord()
--	vector<MedalInfo> *medalinfo = &DATA_MGR->Hero.MedalList
    local medalinfo = LRoleDataMgr.MedalList
	medalinfo = {}

	for i = 1, num do
		local info = LMedalInfo:New()
		info.id = stream:ReadWord()
		info.state = stream:ReadByte()
		--增加是否佩戴属性(佩戴属性现在不要了)
--		info.ware = stream:ReadByte()
--战斗力去掉，要自己计算
        info.zhandouli = stream:ReadUInt()
		if info.state == 1 then
            LRoleDataMgr.MyHeroInfo.MedalId = info.id
            local vipMsg = RoleVipMsg:new(CEnum.RoleEvent.LuaSetTitle,LRoleDataMgr.MyHeroInfo.MedalId)
            this:SendMsg(vipMsg)
		end

        table.insert(medalinfo, info)
	end

    LRoleDataMgr.MedalList = medalinfo
    LRoleDataMgr:SortMedalList() --排序

--    ------dump(LRoleDataMgr.MedalList, "luanet DealMsgMedalList -----")

    LGameMsg.m_netDealMsg:Change(LUITitleEvent.updateTitleUI)
    this:SendMsg(LGameMsg.m_netDealMsg)

end

function LuaNetRecvdMsg.DealMsgUseMedal(stream)

    local medal_info = LRoleDataMgr.MedalList
	local op = stream:ReadByte()
	if op == 0  then --增加称号
		local info = LMedalInfo:New()
		info.id = stream:ReadWord()
        info.zhandouli = stream:ReadUInt()
		info.state = 0
		info.ware = 0
        local idx = 0
        for i = 1, #medal_info do
            if medal_info[i].id == info.id then
                idx = i
                break
            end
        end

        if idx <= 0 then
            table.insert(medal_info, info)
        else
            medal_info[idx] = info
        end
        LRoleDataMgr:SortMedalList()

--        ------dump(info, "DealMsgUseMedal")

        LGameMsg.m_netDealMsg:Change(LUITitleEvent.updateTitleUI)
        this:SendMsg(LGameMsg.m_netDealMsg)

        if #medal_info > 0 then
            -- 如果新得的称号排在第一位
            if(info.id == medal_info[1].id) then
                LCheckImproveMgr:getInstance():UpdateMedal()
            end
        end
	elseif op == 1 then --删除称号
        local num = stream:ReadByte()
		local idArr = {}
        for i=1, num do
            local title = stream:ReadWord()
--            ----print("title 111111111111", title)
            table.insert(idArr, title)
        end

        --如果没有要删除的,则不做后面删除逻辑
        if #idArr < 1 then
            return
        end

        local isHasIdNeedRemove = false
        for i=1, #idArr do
            if idArr[i] > 0 then
                isHasIdNeedRemove = true
                break
            end
        end

        if not isHasIdNeedRemove then
            return
        end

--        ------dump(idArr, "DealMsgUseMedal ==========>")

		for i=1,#medal_info do
            local info = medal_info[i]
            if info then
                local _id = info.id
                for j=1, #idArr do
                    local id = idArr[j]
                    if id == _id then
                        LCheckImproveMgr:getInstance():RemoveMedal(i)
                        table.remove(medal_info, i)
                    end
                end
            end 
		end

        --头顶的该称号消失，并随机佩戴1个已获得的称号
        local num = #LRoleDataMgr.MedalList
--        ----print("num ================================>", num)
        if num > 0 then
            local ranomeTitle
            if num < 2 then
                ranomeTitle = 1
            else
                ranomeTitle = math.random(1,num)
            end
            local data = LRoleDataMgr.MedalList[ranomeTitle]
--            ------dump(data, "DealMsgUseMedal ==========================>")
            LuaNetSendMsg:QueryShowMedal(2, data.id, 1)
        end

	elseif op == 2 then --显示称号
		local id = stream:ReadWord()
		local use = stream:ReadByte()
		local success = stream:ReadByte()
		local msg = stream:ReadString()
		if(success == 1) then    --显示成功
		    
            if use > 0 then
                LRoleDataMgr.MyHeroInfo.MedalId = id
            else
                LRoleDataMgr.MyHeroInfo.MedalId = 0
            end
            
			for i = 1, #medal_info do

--重置显示的称号
                if medal_info[i].state == 1 then
                    medal_info[i].state = 0
                end

				if(id == medal_info[i].id) then
					medal_info[i].state = use
				end
			end

            local vipMsg = RoleVipMsg:new(CEnum.RoleEvent.LuaSetTitle, LRoleDataMgr.MyHeroInfo.MedalId)
            this:SendMsg(vipMsg)
            LGameMsg.m_netDealMsg:Change(LUITitleEvent.updateShowMedelSuc, id)
            this:SendMsg(LGameMsg.m_netDealMsg)
        end

--更新数据
        LRoleDataMgr.MedalList = medal_info
--		TipsMgr::GetInstance()->SetCenterTip(msg.c_str())
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, msg)
        this:SendMsg(LGameMsg.m_scrollTipsMsg)
	elseif(op == 3) then
	
		local id = stream:ReadWord()
		local use = stream:ReadByte()
		local success = stream:ReadByte()
		if(success) then
			for i = 1, #medal_info do
				if id == medal_info[i].id then
					medal_info[i].ware = use
			end

             LRoleDataMgr.MedalList = medal_info
             LCheckImproveMgr:getInstance():UpdateMedal()
            LGameMsg.m_netDealMsg:Change(LUITitleEvent.updateMedalShow)
            this:SendMsg(LGameMsg.m_netDealMsg)

		end
        
	end
        
		local msg = stream:ReadString()
--		TipsMgr::GetInstance()->SetCenterTip(msg)
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, msg)
        this:SendMsg(LGameMsg.m_scrollTipsMsg)

    end
end

function LuaNetRecvdMsg.DealLuckDraw(stream)
    local op = stream:ReadByte()
    --print("DealLuckDraw ===> op", op)
    if op == 1 then
        local drawInfo = {}
        local num = stream:ReadByte()
        --print("DealLuckDraw ==> 3333", num)
        for i=1, num do
            local data = {}
            data.type = stream:ReadByte()
            data.TotalNum = stream:ReadUInt()
            data.freeLeftTime = stream:ReadUInt()
            data.leftTimes = stream:ReadByte() --有免费次数
            table.insert(drawInfo, data)
            
        end
        -- dump(drawInfo, "DealLuckDraw ===========================>")
        PetkaPaiManager.m_DrawInfo = drawInfo
        Utils:SendMsg(LUIDrawEvent.updateDrawUI, drawInfo, true)
    elseif op == 2 then
        local kind = stream:ReadByte()
        local type = stream:ReadByte()

        local errCode = stream:ReadByte()
        --print("LuaNetRecvdMsg.DealLuckDraw 22222222222", errCode, type)
        if errCode < 1 then
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
            return
        end

        local totalNum = stream:ReadUInt()
        --print("LuaNetRecvdMsg.DealLuckDraw totalNum ===>", totalNum)
        if type == AppDef.DrawType.OneDraw then
            local itemInfo = LLuckyDrawResultItem:New()

            itemInfo.kind = kind
            itemInfo.type = type
            itemInfo.totalNum = totalNum

            itemInfo.leftDrawTimes = stream:ReadByte()
            itemInfo.freeLeftTime = stream:ReadUInt()

            -- print("DealLuckDraw =======>", itemInfo.type)
            PetkaPaiManager.m_DrawInfo[itemInfo.kind].leftTimes = PetkaPaiManager.m_DrawInfo[itemInfo.type].leftTimes - 1
            PetkaPaiManager.m_DrawInfo[itemInfo.kind].freeLeftTime = itemInfo.freeLeftTime

            local num = stream:ReadByte()
            itemInfo.mustBeList = {}
            for i=1, num do
                local mustBeData = LuaNetRecvdMsg.ReadCommonReward(stream)
                -- dump(mustBeData,"mustBeData")
                -- local data = {}
                -- data.mustBeType = stream:ReadWord()
                -- data.mustBeNum = stream:ReadUInt()
                table.insert(itemInfo.mustBeList, mustBeData)
            end

            local data = LuaNetRecvdMsg.ReadCommonReward(stream)
            itemInfo.awardType = data[1]
            itemInfo.itemNum = data[3]
            itemInfo.totalNum = totalNum

            if itemInfo.awardType == 60002 then
                itemInfo.petId = data[2]
                -- print("itemInfo.petId == 1111111 >", itemInfo.petId)
                local configData = JsonConfig.m_heroCfg.getDefByID(itemInfo.petId)
                if configData == nil then
                    --默认数据
                    configData = JsonConfig.m_heroCfg.getDefByID(10)
                end
                itemInfo.petName = configData.name
                itemInfo.petType = configData.attack_type
                itemInfo.petStar = configData.initstar
                -- if canTrans == 0 then --可以轉換
                itemInfo.transformId = stream:ReadShort()
                itemInfo.transformNum = stream:ReadUInt()

                -- end
            elseif itemInfo.awardType < 60000 then
                itemInfo.itemId = itemInfo.awardType
            end
            PetkaPaiManager.m_DrawResult = itemInfo
            -- dump(itemInfo, "DealLuckDraw 111111111111111111 ====>")
            -- Utils:InitUI("HappyDraw.SingleDrawResultUI", AppDef.UIType.SpecialLayer, itemInfo)
            Utils:SendMsg(LUIDrawEvent.SingleDrawSuccess, itemInfo)
            
        elseif type == AppDef.DrawType.TenDraw then

            local info = LLuckyDrawResultInfo:New()
            info.kind = kind
            info.type = type
            info.totalNum = totalNum

            --十连没有这些
            -- info.leftDrawTimes = 0
            -- info.freeLeftTime = 0

            local mustBeNum = stream:ReadByte()
            info.mustBeList = {}
            for i=1, mustBeNum do
                local mustBeData = LuaNetRecvdMsg.ReadCommonReward(stream)
                -- dump(data,"data")
                -- local data = {}
                -- data.mustBeType = stream:ReadWord()
                -- data.mustBeNum = stream:ReadUInt()
                table.insert(info.mustBeList, mustBeData)
            end

            local num = stream:ReadByte()
            for i=1, num do

                local itemInfo = LLuckyDrawResultItem:New()
                local data = LuaNetRecvdMsg.ReadCommonReward(stream)
                -- itemInfo.awardType = stream:ReadUShort()
                -- itemInfo.itemNum = stream:ReadUInt()
                itemInfo.awardType = data[1]
                itemInfo.itemNum = data[3]

                if itemInfo.awardType == 60002 then
                    itemInfo.petId = data[2]
                    -- --print("itemInfo.itemNum ===>", itemInfo.itemNum)
                    local configData = JsonConfig.m_heroCfg.getDefByID(itemInfo.petId)
                    if configData == nil then
                        --默认数据
                        configData = JsonConfig.m_heroCfg.getDefByID(64)
                    end
                    itemInfo.petName = configData.name
                    itemInfo.petType = configData.attack_type
                    itemInfo.petStar = configData.initstar
                    
                    itemInfo.transformId = stream:ReadShort()
                    itemInfo.transformNum = stream:ReadUInt()

                elseif itemInfo.awardType < 60000 then
                    itemInfo.itemId = itemInfo.awardType
                end
                table.insert(info.items, itemInfo)
            end
            PetkaPaiManager.m_DrawResult = info
            -- Utils:InitUI("HappyDraw.TenDrawResultUI", AppDef.UIType.SpecialLayer, info)
            Utils:SendMsg(LUIDrawEvent.TenDrawSuccess, info)
        end
    elseif op == 3 then
        LRedDotCheckMgr.cardCd = stream:ReadInt()
    end
    LRedDotCheckMgr:MainCardCheck()
end

-----------------------------近期目标解析从这里开始------------------------------------------------
function LuaNetRecvdMsg.DealStageGoal(stream)
    local op = stream:ReadByte()
    if op == 1 then -- 获得所有阶段目标，章节信息
        this.DealStageGoalInfo(stream)
    elseif op == 6 then -- 获取以前设置跟随
        local zhuangbeiZhangjie = stream:ReadByte()
        if zhuangbeiZhangjie > 5 then
            zhuangbeiZhangjie = 1
        end
    elseif op == 7 then -- 返回设置的跟随情况
        local succ = stream:ReadByte()
        local errORunit = stream:ReadByte()
    elseif op == 2 then
        this.DealStageGoalGetTargetReward(stream)
    elseif op == 3 then
        this.DealUpdateStageState(stream)
    elseif op == 4 then -- 小节完成状态自动推送
        this.DealStageGoalUpdateTarget(stream)
    elseif op == 5 then -- 章节完成
        this.DealStageGoalUpdateUnit(stream)
    end

    LRedDotCheckMgr:MainMubiaoCheck()
end

function LuaNetRecvdMsg.DealStageMissionData(stream, itemData)
    local missData = {}
    missData.missId = stream:ReadWord()
    LRoleDataMgr.Task.taskIdMap[missData.missId] = true
    missData.isFinish = Utils:ToBool(stream:ReadByte())--0:not 1:yes
    Utils:UpdateTaskGiftState(missData)
    if (itemData.haveReward == nil or itemData.haveReward == false) and missData.state == 2 then
        itemData.haveReward = true
    end
    missData.baseData = LDataConstMgr:GetMissionData(missData.missId)
    -- ------dump(missData, "missData-->")
    table.insert(itemData.missions, missData)
    return missData
end

--[[
获得所有阶段目标，章节信息
]]
function LuaNetRecvdMsg.DealStageGoalInfo(stream)
    local datas = {}
    local num = stream:ReadByte()
    LRoleDataMgr.Task.taskIdMap = {}
    -- ------dump(num, "num---->")
    for i=1,num do
        local itemData = {}
        itemData.id = stream:ReadByte()
        itemData.name = stream:ReadString()
        itemData.minLevel = stream:ReadByte()
        itemData.maxLevel = stream:ReadByte()
        itemData.state = stream:ReadByte()--0:不能领取 1:可领取 2:已领取
        itemData.haveReward = false
        itemData.finishMissionCount = 0--完成任务进度
        itemData.missions = {}
        local missionCount = stream:ReadByte()
        -- ------dump(itemData, "itemData-->")
        -- ------dump(missionCount, "missionCount-->")
        for j=1,missionCount do
            LuaNetRecvdMsg.DealStageMissionData(stream, itemData)
        end
        -- ------dump(itemData.missions, "itemData.missions-->")
        itemData.awardId = {}
        itemData.awardNum = {}
        LuaNetRecvdMsg.ReadItemInfo(stream, itemData.awardId, itemData.awardNum)
        -- ------dump(itemData, "itemData-->")
        table.insert(datas, itemData)
    end
    -- ------dump(datas, "datas-->")
    LRoleDataMgr.Task.m_targetTaskData = Utils:SortTaskGiftData(datas) or {}
    Utils:SendMsg(LUITaskGiftEvent.LoadDataEvent, LRoleDataMgr.Task.m_targetTaskData)
end

--[[
领取小节奖励
]]
function LuaNetRecvdMsg.DealStageGoalGetTargetReward(stream)
    local id = stream:ReadByte()
    local succ = stream:ReadByte()
    if succ == 0 then
        Utils:ShowScrollTips(stream:ReadString())
        return
    end
    for i=1,#LRoleDataMgr.Task.m_targetTaskData do
        local data = LRoleDataMgr.Task.m_targetTaskData[i]
        if data.id == id then
            data.state = 2
            break
        end
    end
    Utils:SendMsg(LUITaskGiftEvent.GetRewardRetEvent, id)
end

--[[
更新状态，服务器主动推送
]]
function LuaNetRecvdMsg.DealUpdateStageState(stream)
    local itemData = {}
    itemData.id = stream:ReadByte()
    itemData.state = stream:ReadByte()
    itemData.missions = {}
    itemData.haveReward = false
    itemData.finishMissionCount = 0--完成任务进度
    local num = stream:ReadByte()
    for i=1,num do
        LuaNetRecvdMsg.DealStageMissionData(stream, itemData)
    end
    -- ------dump(itemData, "itemData--->")
    local datas = Utils:SortTaskGiftData({itemData})
    for i=1,#LRoleDataMgr.Task.m_targetTaskData do
        local data = LRoleDataMgr.Task.m_targetTaskData[i]
        if data.id == itemData.id then
            itemData.name = data.name
            itemData.awardId = data.awardId
            itemData.awardNum = data.awardNum
            LRoleDataMgr.Task.m_targetTaskData[i] = itemData
            break
        end
    end
    Utils:SendMsg(LUITaskGiftEvent.UpdateDataEvent, datas[1])
end

--[[
更新小节状态
]]
function LuaNetRecvdMsg.DealStageGoalUpdateTarget(stream)
    local ShenQi = LRoleDataMgr.MyHeroInfo.ShenQi
    local unitN = stream:ReadByte() --章节
    local targetN = stream:ReadByte()--小节

    for key,target in pairs(ShenQi.allTarget) do
        if target.unitid  == unitN and target.senderServerID == targetN then
            target.isWancheng = true
            LGameMsg.m_netDealMsg:Change(LUIWelfareEvent.RefreshStageGoal, 0)
            this:SendMsg(LGameMsg.m_netDealMsg)
            break
        end
    end
end

--[[
更新单元状态
]]
function LuaNetRecvdMsg.DealStageGoalUpdateUnit(stream)
    local ShenQi = LRoleDataMgr.MyHeroInfo.ShenQi
    local unitN = stream:ReadByte() --章节
    for key,unit in pairs(ShenQi.allUnit) do
        -- --------dump(unit, "==================>"..key)
        if unit.unit_id  == unitN then
            unit.unit_wancheng = true
            -- --------dump(unit, "==================>>>>")
            LGameMsg.m_netDealMsg:Change(LUIWelfareEvent.RefreshStageGoal, 0)
            this:SendMsg(LGameMsg.m_netDealMsg)
            break
        end
    end
end

function LuaNetRecvdMsg.DealStageGoalString(str, zhangjie)
    local rows = string.split(str, "|")
    local ShenQi = LRoleDataMgr.MyHeroInfo.ShenQi
    ShenQi.allTarget = {} -- 阶段
    ShenQi.allUnit = {} -- 章节
    local unittarget = nil
    local onetarget = nil
    local unitID = 1
    local TargetIDInUnit = 1
    for i=1,#rows do
        local sign = tonumber(rows[i])
        if sign == -1 then
            local target = LUnitTarget:New()
            table.insert(ShenQi.allUnit, target)
            unittarget = target
            i = i+1
            if i >= #rows  then
                return
            end
            unittarget.UnitNumBig = rows[i]

            i = i+1
            if i >= #rows  then
                return
            end
            unittarget.unitName = rows[i]
            unittarget.unit_id = unitID
            if unittarget.unit_id == zhangjie -1 then
                unittarget.isGensui = true
            end
        elseif sign == -5 then -- 一个章节结束
            unittarget = nil
            unitID = unitID+1
            TargetIDInUnit = 1
        elseif sign == -2 then -- 一个目标
            local target = LSingleStageTarget:New()
            table.insert(ShenQi.allTarget, target)
            target.unitid = unitID
            target.targetIDForUnit = TargetIDInUnit
            target.senderServerID = TargetIDInUnit
            TargetIDInUnit = TargetIDInUnit+1
            i=i+1
            target.TargetName = rows[i] -- 目标名称
            onetarget = target
        elseif sign == -11 then -- 目标奖励金币
            if onetarget ~= nil then
                i = i+1
                if i >= #rows  then
                    return
                end
                onetarget.jiangli = 0
                onetarget.jinbi = tonumber(rows[i])   -- 金币数

                i = i+2
                if i >= #rows  then
                    return
                end
                onetarget.isWancheng = (tonumber(rows[i]) ~= 0) --是否已完成

                i = i+1
                if i >= #rows  then
                    return
                end
                onetarget.isLingqu = (tonumber(rows[i]) ~= 0) --是否已领取
            end
        elseif sign == -12 then -- 目标奖励绑元
            if onetarget ~= nil then
                i = i+1
                if i >= #rows  then
                    return
                end
                onetarget.jiangli = 1
                onetarget.bangyuan = tonumber(rows[i])

                i = i+2
                if i >= #rows  then
                    return
                end
                onetarget.isWancheng = (tonumber(rows[i]) ~= 0) --是否已完成

                i = i+1
                if i >= #rows  then
                    return
                end
                onetarget.isLingqu = (tonumber(rows[i]) ~= 0) --是否已领取
            end
        elseif sign == -13 then -- 物品信息
            if onetarget ~= nil then
                i = i+1
                if i >= #rows  then
                    return
                end
                onetarget.jiangli = 2
                onetarget.itemID = rows[i]

                i = i+1
                if i >= #rows  then
                    return
                end
                onetarget.itemNum = tonumber(rows[i])

                i = i+1
                if i >= #rows  then
                    return
                end
                onetarget.isWancheng = (tonumber(rows[i]) ~= 0) --是否已完成

                i = i+1
                if i >= #rows  then
                    return
                end
                onetarget.isLingqu = (tonumber(rows[i]) ~= 0) --是否已领取
            end
        elseif sign == -3 then -- 章节奖励开始
        elseif sign == -21 then -- 章节伤害奖励
            i = i+1
            if i >= #rows  then
                return
            end
            unittarget.unit_jiangli = 0
            unittarget.shanghai = tonumber(rows[i]) --伤害
        elseif sign == -22 then
            i = i+1
            if i >= #rows  then
                return
            end
            unittarget.unit_jiangli = 1
            unittarget.shanghai = tonumber(rows[i]) --防御
        elseif sign == -5 then
            i = i+1
            if i >= #rows  then
                return
            end
            unittarget.unit_jiangli = 2
            unittarget.shanghai = tonumber(rows[i]) --气血
        elseif sign == -4 then
            i = i+1
            if i >= #rows  then
                return
            end
            unittarget.unit_wancheng = (tonumber(rows[i]) ~= 0) --是否已完成

            i = i+1
            if i >= #rows  then
                return
            end
            unittarget.unit_lingqu = (tonumber(rows[i]) ~= 0) --是否已领取
        elseif sign == -6 then
        end
    end
end
-----------------------------近期目标解析到这里结束------------------------------------------------

-- -----------------------------------------
-- 在线奖励
function LuaNetRecvdMsg.OnLineAward(stream)
    local rsp = {}
    local op = stream:ReadByte()
    if op == 1 then  
        local OnlineData = LRoleDataMgr.MyHeroInfo.OnLine
        local lastTime = 0
        local ind =  stream:ReadByte()
        ind=ind+1
        local time = stream:ReadInt()
        local tempData = JsonConfig.m_OnLineConfig.getDefByID(ind-1)
        if tempData==nil then
           lastTime=0
        else
            lastTime=tempData.time
        end
        local OLConfig = JsonConfig.m_OnLineConfig.getDefByID(ind)
        if OLConfig then
            time=(OLConfig.time-lastTime)*60 -time
            if time<0 then
                time=0
            end
        else
            time=0
        end
       
        

        --print("LuaNetRecvdMsg.OnLineAward(stream)",ind,time)
        OnlineData:UpdateData({ind=ind,time=time}) 
        LGameMsg.m_netDealMsg:Change(LOnLineEvent.UpdateTime)
        this:SendMsg(LGameMsg.m_netDealMsg)
       
    end
    if op == 2 then
        --print("获取离线奖励",op,errcode) 
        local errcode = stream:ReadByte()
        rsp.errcode = errcode
      --  --print("获取离线奖励",op,errcode)
        if errcode == 0 then
            rsp.errmsg = stream:ReadString()           
        else
            -- LRedDotCheckMgr.onlineCd = 99999
            -- LGameMsg.m_baseMsgWithOne:Change(LUIOnlineAwardEvent.KaifuReddotRefresh,7)
            -- this:SendMsg(LGameMsg.m_baseMsgWithOne)
        end 
        Utils:ShowScrollTips(stream:ReadString())
        local OnlineData = LRoleDataMgr.MyHeroInfo.OnLine
        OnlineData:GetReward()
        LGameMsg.m_netDealMsg:Change(LOnLineEvent.UpdateTime)
        this:SendMsg(LGameMsg.m_netDealMsg)
        return 
    end 
end 

-- -----------------------------------------
function  LuaNetRecvdMsg.DealOfflineExp(stream)
    local op = stream:ReadByte()
    if op == 1 then 
        LRoleDataMgr.MyHeroInfo.offlineInfo = {}
        local rsp = LRoleDataMgr.MyHeroInfo.offlineInfo
        rsp.time_outLine = stream:ReadUInt()	-- 离线时间
        rsp.belv_outLine = stream:ReadWord()	-- 免费倍率
        rsp.mianfei = stream:ReadUInt()			-- 免费经验
        rsp.shoufeiRate = stream:ReadWord()     -- 收费倍率
        rsp.shoufei = stream:ReadUInt()			-- 收费经验
        rsp.vipRate = stream:ReadWord()         -- vip 倍率
        rsp.vip = stream:ReadUInt()				-- vip 经验
        rsp.shoufeiMoney = stream:ReadUInt()    -- 收费费率
        rsp.minu_t = math.floor(rsp.time_outLine/60)
        LGameMsg.m_netDealMsg:Change(LUIOfflineAwardEvent.OfflineInfo, rsp)
        this:SendMsg(LGameMsg.m_netDealMsg)
    else
        local rsp = {}
        rsp.op = op
        LGameMsg.m_netDealMsg:Change(LUIOfflineAwardEvent.GetOfflineExp, rsp)
        this:SendMsg(LGameMsg.m_netDealMsg)
    end 
end 

--[[
充值档位
]]
function LuaNetRecvdMsg.DealMsgPayPricelist(stream)
    local op = stream:ReadByte()
    if op ~= 1 then return end
    local num = stream:ReadByte()
    LRoleDataMgr.MyHeroInfo.m_PayPricelist = {}
    for i=1,num do
        local price = LPayPricelist:New()
        price.type = stream:ReadByte() -- 1充值档位 6月卡
        price.index = stream:ReadByte() --排序档位
        price.picId = stream:ReadByte() --图片ID
        price.chongzhi = stream:ReadUInt()
        price.fanli = stream:ReadUInt()
        price.showDouble = stream:ReadByte() --1可首充 0首充过了
        price.itemId = stream:ReadUInt()     --道具id
        price.itemNum = stream:ReadUInt()    --道数量
        table.insert(LRoleDataMgr.MyHeroInfo.m_PayPricelist, price)
    end
    --对商城数据进行排序
    LRoleDataMgr.MyHeroInfo:SortPayPriceData()
    if #LRoleDataMgr.MyHeroInfo.m_PayPricelist > 0 then
        Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_RECHARGE,nil,true)
    end
end

--[[
修仙历练
]]
function LuaNetRecvdMsg.DealMsgLiLianInfo(stream)
    local op = stream:ReadByte()
	local msg = ""
	if op == 1 then
	    this.DealMsgLiLianData(stream)
	elseif op == 2 then
        --战斗后更新数据
		local index = stream:ReadWord()
		local suc = stream:ReadByte()
		if suc == 0 then
		    msg = stream:ReadString()
			Utils:ShowScrollTips(msg)
            return
        end
--	elseif op == 3 then
--	    --今日排行(暂不使用)
	elseif op == 4 then
        --信息更新
        this.DealMsgLiLianDataUp(stream)
	elseif op == 5 then
		LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Activity.LiLianUI",AppDef.UIType.SpecialLayer)
		this:SendMsg(LGameMsg.m_initUIMsg)
	end
end

function LuaNetRecvdMsg.DealMsgLiLianData(stream)
    --历练界面信息
	local suc = stream:ReadByte()
	if suc == 0 then
        msg = stream:ReadString()
        Utils:ShowScrollTips(msg)
        return
    end
	for k,v in pairs(LActivityManager.m_LiLianData) do
      LActivityManager.m_LiLianData[k] = nil
      table.remove(LActivityManager.m_LiLianData,k)
    end
    LActivityManager.m_LiLianData = {}
	local pageNum = stream:ReadWord()
	for i=1,pageNum do
		local info = LLiLianInfo:new()
		info.m_chapNumId = stream:ReadWord()
		info.m_chapName = stream:ReadString()
		info.m_perChapNum = stream:ReadWord()

		for j=1,info.m_perChapNum do
            local chapInfo = {
                ["index"] = 0, ["name"] = "", ["winFlag"] = 0, ["canFight"] = 0,
                ["lock"] = 0, ["type"] = 0, ["paramId"] = 0
            } 
		    chapInfo.index	  = stream:ReadWord()
		    chapInfo.name	  = stream:ReadString()
			chapInfo.winFlag  = stream:ReadByte()
			chapInfo.canFight = stream:ReadByte()
			chapInfo.lock	  = stream:ReadByte()
			chapInfo.type	  = stream:ReadByte()
			if chapInfo.type == 1 then
				chapInfo.paramId = stream:ReadWord()
                chapInfo.type = AppDef.CEnum.ModelAniType.Monster
			elseif chapInfo.type == 2 then	
                chapInfo.paramId = stream:ReadByte()
				stream:ReadByte()
                --stream:ReadByte() --性别，不用
                chapInfo.type = AppDef.CEnum.ModelAniType.Hero
			end
			table.insert(info.m_chapInfos,chapInfo)
		end
		table.insert(LActivityManager.m_LiLianData,info)
	end
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Activity.LiLianUI", AppDef.UIType.SpecialLayer)
    this:SendMsg(LGameMsg.m_initUIMsg)
end

function LuaNetRecvdMsg.DealMsgLiLianDataUp(stream)
    local info = LActivityManager.m_LiLianData
    if info == nil then return end
	local idx = stream:ReadWord()
	local flag = stream:ReadByte()
	local fight = stream:ReadByte()
	local lockUpdateNum = stream:ReadByte()
	local indexList = {}
	for z=1,lockUpdateNum do
		local lockIdx = stream:ReadWord()
		local mlock	= stream:ReadByte()
		local value1 = math.floor((lockIdx-1)/5)+1
		local value2 = (lockIdx-1)%5+1
        if info[value1] ~= nil then
            local chapInfo = info[value1].m_chapInfos[value2]
		    if chapInfo ~= nil and chapInfo.index == lockIdx then
			    chapInfo.lock = mlock
                if mlock == 0 then
			        indexList[value1] = 1
                end
		    end
        end
	end
    for k,v in pairs(indexList) do
        --通知UI刷新
        LGameMsg.m_netDealMsg:Change(LUIActivityEvent.RefreshLiLianInfo,k)
        this:SendMsg(LGameMsg.m_netDealMsg)
    end

--    if lockUpdateNum > 0 then 
		for k,v in pairs(info) do
			for j=1,#v.m_chapInfos do
				if v.m_chapInfos[j].index == idx then
					v.m_chapInfos[j].winFlag = flag
					v.m_chapInfos[j].canFight = fight
                     --通知UI刷新
                    LGameMsg.m_netDealMsg:Change(LUIActivityEvent.RefreshLiLianInfo,k)
                    this:SendMsg(LGameMsg.m_netDealMsg)
                    return
				end
			end
		end
--    end
end

--[[
飞仙战场
]]
function LuaNetRecvdMsg.DealMsgFlyFaryField(stream)
    local op = stream:ReadByte()
    if op == 1 then
        local suc = stream:ReadByte()
        if suc == 0 then
            this.SetCenterTip(stream:ReadString())
        end
    elseif op == 2 then
        local info = LDataConstMgr.m_FlyFaryInfo
        info.CurLevel = stream:ReadByte()
        info.State = stream:ReadByte()
        info.KillPoint = stream:ReadByte()
        info.MaxKillPoint = stream:ReadByte()
        info.BeAttackedPoint = stream:ReadByte()
        info.MaxBeAttackedPoint = stream:ReadByte()
        info.CurExp = stream:ReadUInt()
        info.BonusExp = stream:ReadUInt()
        info.LeftTime = stream:ReadUInt()
        info.AddExpTime = stream:ReadUInt()

        info.vecAwardId = {}
        info.vecAwardNum = {}
        local num = stream:ReadByte()
        for i=1,num do
            table.insert(info.vecAwardId, stream:ReadUInt())
            table.insert(info.vecAwardNum, stream:ReadUInt())
        end
        
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Activity.FlyFaryUI",AppDef.UIType.Normal)
        this:SendMsg(LGameMsg.m_initUIMsg)
        LGameMsg.m_netDealMsg:Change(LUIActivityEvent.RefreshFlyFary, 0)
        this:SendMsg(LGameMsg.m_netDealMsg)
        if info.State == 1 then
            LRoleDataMgr.MyHeroInfo.ShapeId = 705
        else
            LRoleDataMgr.MyHeroInfo.ShapeId = 0
        end
        LRoleDataMgr.MyHeroInfo:SendHeroModelChangedMsg()
    end
end

--[[
藏宝图
]]
function LuaNetRecvdMsg.DealMsgCangBaotuInfo(stream)
    local function UseCangbaotuFunc()
        local pos = LRoleDataMgr:FindCangbaotuPos()
        if pos > 0 then
            LRoleDataMgr:useCangbaotu(pos)
--            LuaNetSendMsg:SendItemUseReq(pos-1,1,0)
        end
    end

    local op = stream:ReadByte()
    local isFail = stream:ReadByte()
    if op == 1 or op == 2 then
        if isFail == 0 then
            local msg = stream:ReadString()
            if op == 2 then
                this.SetCenterTip(msg)
            end             
        elseif isFail == 1 then
            local data = LDataConstMgr.m_BaoZangInfo
            data.numLimit = stream:ReadByte()
            data.completeNum = stream:ReadByte()
            data.sid = stream:ReadWord()
            data.posX = stream:ReadWord()
            data.posY = stream:ReadWord()
            if data.isQuery and op == 2 and data.sid ~= 0 then -- 是查询返回 挖宝
                LuaNetSendMsg:QueryCangBaotuWa()
            elseif data.isQuery and data.numLimit > data.completeNum then --还有挖宝次数
                LuaNetSendMsg:QueryCangBaotuInfo(2) --继续挖宝
            end
        end
    elseif op == 3 then
        if isFail == 0 then
            this.SetCenterTip(stream:ReadString())
        end
    elseif op == 7 then
        local nums = {}
        --nums[1] = stream:ReadWord()
        --nums[2] = stream:ReadWord()
        local str = ""
        for i = 1,2 do
            --if nums[i] ~= nil and nums[i] > 0 then              
               local dItem = LItemMgr:getItem(AppDef.CangBaotuIds[i])
               if dItem ~= nil then
                   nums[i] = LRoleDataMgr.Equip:CountItemNumById(dItem.m_id)
                   str = str .. "[c1]"..nums[i].. "[/c]"..GUITips.RSI_ICBL_MSG1..dItem.m_name
               end
            --end
        end
        local tempStr =""
        if LRoleDataMgr.MyHeroInfo.MyVIPInfo.mcType>=1  then
            tempStr=GUITips.RSI_ICBL_TIP2
        end        
        local msg = Utils:JointString(GUITips.RSI_ICBL_TIP1,"   "..str,tempStr)
        --弹提示框,战斗后弹出
        Utils:ShowDialogOKCancel(msg,UseCangbaotuFunc,nil,GUITips.UI_Btn_Wabao,GUITips.UI_Btn_CancelWabao, true, true, 8)
    elseif op == 8 then
        --使用藏宝图
        UseCangbaotuFunc()
    elseif op == 9 then
--新的藏宝图奖励
        local info = {}
        info.idx = stream:ReadByte() --停在的位置
        info.num = stream:ReadByte()
        info.awardInfo = {}
        for i = 1, info.num do
            local awardSt = {}
            local id = stream:ReadWord()
            local num = stream:ReadUInt()
            awardSt.id = id
            awardSt.num = num
            table.insert(info.awardInfo, awardSt)
        end
--        --------dump(info, "========================")

        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Activity.TreasureMapAwardUI", AppDef.UIType.PopWindow, info)
        this:SendMsg(LGameMsg.m_initUIMsg)
    elseif op == 10 then
        if isFail == 1 then
            --使用藏宝图
            local pos = LRoleDataMgr:FindCangbaotuPos()
            if pos > 0 then
                LRoleDataMgr:useCangbaotu(pos)
            end
        end
    end
end

--[[
多人闯关
]]
function LuaNetRecvdMsg.DealMsgMonopoly(stream)
    local op = stream:ReadByte()
    print("DealMsgMonopoly op ========>", op)
    if op == 3 then
        --roll点
        local  errcode = stream:ReadByte()
        if errcode == 1 then
            local  labInfo = {}
            labInfo.destcell = stream:ReadUInt()
--            labInfo.stepNum = stream:ReadUInt()
            labInfo.rollNum = stream:ReadUInt()
            labInfo.roll_max = stream:ReadUInt()
            labInfo.roll_use = stream:ReadUInt()
            
            LGameMsg.m_netDealMsg:Change(LUIMonopolyEvent.recvRoleMove, labInfo)
            this:SendMsg(LGameMsg.m_netDealMsg)

        elseif errcode == 0 then
            local errCodeTemp = stream:ReadByte()
            if errCodeTemp == 1 then
            --显示战斗对话框
                ----print("justShowBattleChatLayer =================>")
                LRechargeDataMgr.isShowBattleChatNow = true
                LGameMsg.m_netDealMsg:Change(LUIMonopolyEvent.justShowBattleChatLayer)
                this:SendMsg(LGameMsg.m_netDealMsg)
            elseif errCodeTemp == 2 then
                LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, GUITips.RSI_MONOPOLY_USEUPROOL)
                this:SendMsg(LGameMsg.m_scrollTipsMsg)
            end

            LGameMsg.m_netDealMsg:Change(LUIMonopolyEvent.RoleOnMove)
            this:SendMsg(LGameMsg.m_netDealMsg)
            local msg = stream:ReadString()

        end
    elseif op == 4 then
        --移动完成
        local rw = stream:ReadByte()

        if rw == AppDef.CellEventType.CellEvent_Box then
            --开宝箱
            local ret = stream:ReadByte()
            LuaNetSendMsg:QueryRushGateInfo(11, 1)

            LGameMsg.m_netDealMsg:Change(LUIMonopolyEvent.updateAwardUIIcon)
            this:SendMsg(LGameMsg.m_netDealMsg)

        elseif rw == AppDef.CellEventType.CellEvent_Hand then

            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Activity.GuessFistMainUI",AppDef.UIType.FirstClassLayer)
            this:SendMsg(LGameMsg.m_initUIMsg)

            LGameMsg.m_netDealMsg:Change(LUIMonopolyEvent.updateAwardUIIcon)
            this:SendMsg(LGameMsg.m_netDealMsg)

        elseif rw == AppDef.CellEventType.CellEvent_Goal then
            LGameMsg.m_netDealMsg:Change(LUIMonopolyEvent.updateAwardUIIcon)
            this:SendMsg(LGameMsg.m_netDealMsg)

        elseif rw == AppDef.CellEventType.CellEvent_Coin then
            --金币
            LGameMsg.m_netDealMsg:Change(LUIMonopolyEvent.updateAwardUIIcon)
            this:SendMsg(LGameMsg.m_netDealMsg)


        elseif rw == AppDef.CellEventType.CellEvent_Robber then
            --战斗
            LuaNetSendMsg:QueryRushGateInfo(12, 1)
        elseif rw == AppDef.CellEventType.CellEvent_End then
--关闭UI
--            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Monopoly.MonopolyBaseUI")
--            this:SendMsg(LGameMsg.m_initUIMsg)

--            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Monopoly.MonopolyUI")
--            this:SendMsg(LGameMsg.m_initUIMsg)
            
            LGameMsg.m_netDealMsg:Change(LUIMonopolyEvent.finishEvent)
            this:SendMsg(LGameMsg.m_netDealMsg)

        elseif rw == AppDef.CellEventType.ECGOp_QueryEnemy then

        elseif rw == AppDef.CellEventType.CellEvent_Random then
            --随机事件
            local data  = {}
            data.targetPos = stream:ReadUInt()
--更新闯关界面
            LGameMsg.m_netDealMsg:Change(LUIMonopolyEvent.updateAwardUIIcon)
            this:SendMsg(LGameMsg.m_netDealMsg)
            
            LGameMsg.m_netDealMsg:Change(LUIMonopolyEvent.recvRandomEvent, data)
            this:SendMsg(LGameMsg.m_netDealMsg)

        end

        ----print("DealAnswerQuestion", rw, AppDef.CellEventType.CellEvent_Random)
        if rw ~= AppDef.CellEventType.CellEvent_Random then
            --判断是否显示战斗界面
            LGameMsg.m_netDealMsg:Change(LUIMonopolyEvent.afterMoveEvent)
            this:SendMsg(LGameMsg.m_netDealMsg)
        end




    elseif op == 6 then
        --猜拳
        local suc = stream:ReadByte()
        local errorCode = stream:ReadByte()
        if errorCode == 1  then -- 成功

        elseif errorCode == 2 then
--平局不关闭窗口
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
        else
            --关闭窗口
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)

        end
        LGameMsg.m_netDealMsg:Change(LUIActivityEvent.GuessFistResult, errorCode)
        this:SendMsg(LGameMsg.m_netDealMsg)

    elseif op == 8 then
        --重置多人闯关
        local isInMonopoly = LRoleDataMgr.MonopolyData.isMonopolyState
        if isInMonopoly then
            local leftTimes = LActivityManager:getLeftMonopolyTimes()
            if leftTimes > 1 then
                LuaNetSendMsg:QueryMonopolyInfo(15) --多人闯关
            else
                Utils:ShowScrollTips(GUITips.Rsi_Tip_Monopoly_reset)
            end        
            LActivityManager:addMonopolyPlayTimes()
        end
    elseif op == 11 then
        --开宝箱
        -- local data = {}
        -- data.exp = stream:ReadUInt()
        -- data.coin = stream:ReadUInt()
        -- data.gold = stream:ReadUInt()

        -- LGameMsg.m_netDealMsg:Change(LUIMonopolyEvent.updateAwardUI, data)
        -- this:SendMsg(LGameMsg.m_netDealMsg)

        local msg = stream:ReadString()
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, msg)
        this:SendMsg(LGameMsg.m_scrollTipsMsg)

        LGameMsg.m_netDealMsg:Change(LUIMonopolyEvent.updateAwardUIIcon)
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 10 then
        --闯关战斗
        local isWin = stream:ReadByte()
        ----print("fight isWin", isWin)
        LRechargeDataMgr.isMonopolyBattleWin = isWin > 0
        if isWin == 0 then
            --通用战斗结算
            local fightData = {}
            fightData.wanFaId = AppDef.EModuleID.EMID_KAPAI_WF_KUN_XB
            LuaNetRecvdMsg.ReadBattleResult(stream, figthData)
            return
        end

        LGameMsg.m_netDealMsg:Change(LUIMonopolyEvent.updateBattleUIIcon)
        this:SendMsg(LGameMsg.m_netDealMsg)

        local  labInfo = {}
        labInfo.destcell = stream:ReadUInt()
        -- ------dump(labInfo, "labInfo 222222222222222")

        LGameMsg.m_netDealMsg:Change(LUIMonopolyEvent.afterBattleUIMove, labInfo)
        this:SendMsg(LGameMsg.m_netDealMsg)


        local summeryInfo = {}
        summeryInfo.exp = stream:ReadUInt()
        summeryInfo.coin = stream:ReadUInt()
        summeryInfo.gold = stream:ReadUInt()

        LGameMsg.m_netDealMsg:Change(LUIMonopolyEvent.updateAwardUI, summeryInfo)
        this:SendMsg(LGameMsg.m_netDealMsg)


        local battleInfo = {}
        battleInfo.maxKill = stream:ReadUInt()
        battleInfo.curKill = stream:ReadUInt()


        --通用战斗结算
        local fightData = {}
        fightData.wanFaId = AppDef.EModuleID.EMID_KAPAI_WF_KUN_XB
        LuaNetRecvdMsg.ReadBattleResult(stream, figthData)

        
        LGameMsg.m_netDealMsg:Change(LUIMonopolyEvent.updateBattleUI, battleInfo)
        this:SendMsg(LGameMsg.m_netDealMsg)

        

    elseif op == 15 then
        --查询地图数据
        local monopolyData = LMonopolyData:New()
        monopolyData.timediff = stream:ReadUInt()
        monopolyData.exp = stream:ReadUInt()
        monopolyData.coin = stream:ReadUInt()
        monopolyData.gold = stream:ReadUInt()
        monopolyData.roll_max = stream:ReadUInt()
        monopolyData.roll_use = stream:ReadUInt()
        monopolyData.monster_num = stream:ReadUInt()
        monopolyData.kill_monster = stream:ReadUInt()
        monopolyData.cellnum = stream:ReadUInt()
        monopolyData.curPos = stream:ReadUInt()
        for i = 1, monopolyData.cellnum do
            local oneCellData = LMonopolyCellData:New()
            oneCellData.cellid = stream:ReadUInt()
            oneCellData.eventid = stream:ReadUInt()
            oneCellData.eventnum = stream:ReadUInt()
            if oneCellData.eventid == 2 then
                oneCellData.userid = stream:ReadUInt()
                oneCellData.career = stream:ReadUInt()
                oneCellData.weapen = stream:ReadUInt()
                oneCellData.effect = stream:ReadUInt()
                oneCellData.power = stream:ReadUInt()
                oneCellData.name = stream:ReadString()
                local awardNum = stream:ReadByte()
                awardNum = 1
                for i=1, awardNum do
                    local awardInfo = {}
                    awardInfo.awardType = stream:ReadWord()
                    -- awardInfo.awardType = AppDef.AwrdItem.AWRD_ITEM_BDYB
                    awardInfo.awardNum = stream:ReadWord()
                    -- awardInfo.awardNum = 30
                    table.insert(oneCellData.awardInfo, awardInfo)
                end
            -- dump(oneCellData.awardInfo, "show info")
            end
            table.insert(monopolyData.cellData, oneCellData)
        end
        LRoleDataMgr.MonopolyData:Delete()
        LRoleDataMgr.MonopolyData = monopolyData
        print(monopolyData, "LuaNetRecvdMsg.DealMsgMonopoly ====================>")
        LGameMsg.m_netDealMsg:Change(LUIMonopolyEvent.updateMonopoly)
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 16 then
        --随机事件 前进或者后退 服务器主动推送
    elseif op == 20 then
    --查询敌人信息
        local enemyData = {}
        enemyData.id = stream:ReadUInt()
        enemyData.power = stream:ReadUInt()
        enemyData.awardType = stream:ReadUInt()
        -- enemyData.awardType = AppDef.AwrdItem.AWRD_ITEM_BDYB
        enemyData.awardNum = stream:ReadUInt()
        -- enemyData.awardNum = 30
        enemyData.name = stream:ReadString()

        dump(enemyData, "enemyData ===================>")

        LGameMsg.m_netDealMsg:Change(LUIMonopolyEvent.showBattleChatLayer, enemyData)
        this:SendMsg(LGameMsg.m_netDealMsg)

    elseif op == 21 then
        local errorCode = stream:ReadByte()   
        if errorCode == 0 then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, GUITips.RSI_TIP_MONOPOLY_BUYTIMESFAIL)
            this:SendMsg(LGameMsg.m_scrollTipsMsg)
            return
        end

        local data = {}
        data.maxTimes = stream:ReadUInt()
        data.curTimes = stream:ReadUInt()
        LGameMsg.m_netDealMsg:Change(LUIMonopolyEvent.udaptePlayTimes, data)
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 22 then
        local errorCode = stream:ReadByte()
        local buyData = {}
        buyData.useType = stream:ReadUInt()
        buyData.price = stream:ReadUInt()
        buyData.buyNum = stream:ReadUInt()
        buyData.maxBuyNum = stream:ReadUInt()
        LGameMsg.m_netDealMsg:Change(LUIMonopolyEvent.showBuyTicket, buyData)
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 23 then
        local data = {}
        data.exp = stream:ReadUInt()
        data.coin = stream:ReadUInt()
        data.gold = stream:ReadUInt()

        LGameMsg.m_netDealMsg:Change(LUIMonopolyEvent.updateAwardUI, data)
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 24 then
        --关闭昆仑寻宝
        LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Monopoly.MonopolyBaseUI")
        this:SendMsg(LGameMsg.m_deleteUIMsg)

        LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Monopoly.MonopolyUI")
        this:SendMsg(LGameMsg.m_deleteUIMsg)
	elseif op == 25 then
		local kunlundata = {}
		kunlundata.ceng = stream:ReadByte()
		kunlundata.zhandou_num = stream:ReadByte()
		kunlundata.buy_num = stream:ReadByte() --剩余购买次数
		kunlundata.pos = stream:ReadByte()
		local num = stream:ReadByte()
		kunlundata.enemyinfos = {}
		for i = 1, num do
			local data = {}
			data.id = stream:ReadByte()
			data.roleid = stream:ReadUInt()
			data.name = stream:ReadString()
			data.professional = stream:ReadByte()
			data.sex = stream:ReadByte()
			data.level = stream:ReadWord()
			data.fight = stream:ReadUInt()
			data.robot = stream:ReadByte()
			data.state = stream:ReadByte() --1 战斗前   2 战斗中 3 已经通过
			local petnum = stream:ReadByte()
			--print("=======petnum==========",petnum)
			data.pets = {}
			for  j = 1, petnum do
				local petdata = {}
				petdata.pos = stream:ReadByte()
				petdata.blood = stream:ReadULongInt()
				petdata.maxblood = stream:ReadULongInt()
				table.insert(data.pets, petdata)
			end
			table.insert(kunlundata.enemyinfos, data)
		end
		LGameMsg.m_netDealMsg:Change(LUIKunLunEvent.LoadDataEvent, kunlundata)
        this:SendMsg(LGameMsg.m_netDealMsg)
		LRoleDataMgr.m_kunlunjuezhanData = kunlundata
		
		LRedDotCheckMgr:WanFaRedDotCheck()
	elseif op == 26 then
		local data = {}
		data.pos = stream:ReadByte()
		data.result = stream:ReadByte()
		--LGameMsg.m_netDealMsg:Change(LUIKunLunEvent.UpdateFightEvent, data)
        --this:SendMsg(LGameMsg.m_netDealMsg)
		print("=========kunlun 26==========",data.pos,data.result)
		
	elseif op == 27 then
		local result = {}
		result.num = stream:ReadByte()
		result.pos = stream:ReadByte()
		local fightData = {}
        fightData.wanFaId = AppDef.EModuleID.EMID_KAPAI_FENGSHENSHILIAN
        LuaNetRecvdMsg.ReadBattleResult(stream,fightData)
		--dump(result, "=========kunlun 27==========")
		LGameMsg.m_netDealMsg:Change(LUIKunLunEvent.UpdateDataEvent, result)
        this:SendMsg(LGameMsg.m_netDealMsg)
		if result.num == 0 then
			LRoleDataMgr.m_kunlunjuezhanData.zhandou_num = 0
			LRedDotCheckMgr:WanFaRedDotCheck()
		end
	elseif op == 28 then
		local num = stream:ReadByte()
		local result = stream:ReadByte()
		if result == 0 then
			return
		end
		local fightnum = stream:ReadByte()
		local buynum = stream:ReadByte() --剩余购买次数
		--dump({num, fightnum, buynum}, "=========kunlun 28==========")
		LGameMsg.m_netDealMsg:Change(LUIKunLunEvent.UpdateBuyFightNum, {fightnum, buynum})
        this:SendMsg(LGameMsg.m_netDealMsg)
		Utils:ShowScrollTips(GUITips.RSI_MDSI_MSGI44)
		LRoleDataMgr.m_kunlunjuezhanData.zhandou_num = fightnum
		LRedDotCheckMgr:WanFaRedDotCheck()
	elseif op == 29 then
		local result = {}
		local success = stream:ReadByte()
		if success == 0  then

		end
		result.num = stream:ReadByte()
		result.usenum = stream:ReadByte()
		result.pos = stream:ReadByte()
		local num = stream:ReadByte()
		result.path = {}
		for i = 1, num do
			local pos = stream:ReadByte()
			table.insert(result.path, pos)
		end
		--dump(result, "=========kunlun 29==========")
		LGameMsg.m_netDealMsg:Change(LUIKunLunEvent.UpdateDataEvent, result)
        this:SendMsg(LGameMsg.m_netDealMsg)
	elseif op == 30 then
		local num = stream:ReadByte()
		local rewards = {}
		--for i = 1, num do
		--	local data = {}
		--	data.id = stream:ReadWord()
		--	data.num = stream:ReadUInt()
		--	table.insert(rewards, data)
		--end
		--dump(rewards, "=========kunlun 30========")
		LGameMsg.m_netDealMsg:Change(LUIKunLunEvent.FightRewardShow, rewards)
        this:SendMsg(LGameMsg.m_netDealMsg)
	elseif op == 31 then
		--战斗失败
		local result = {}
		result.pos = stream:ReadByte()
		result.state = stream:ReadByte()
		result.fightnum = stream:ReadByte()
		result.pets = {}
		local petnum = stream:ReadByte()
		for i = 1, petnum do
			local petdata = {}
			petdata.pos = stream:ReadByte()
			petdata.blood = stream:ReadULongInt()
			petdata.maxblood = stream:ReadULongInt()
			table.insert(result.pets, petdata)
		end
		--dump(result, "=========kunlun 31========")
		LGameMsg.m_netDealMsg:Change(LUIKunLunEvent.FightFailedEvent, result)
        this:SendMsg(LGameMsg.m_netDealMsg)
	elseif op == 32 then
		local robotinfo = {}
		robotinfo.id = stream:ReadUInt()
		robotinfo.zhengfaId = stream:ReadByte()
		robotinfo.zhengfaLv = stream:ReadByte()
		robotinfo.isRole = false
		local num = stream:ReadByte()
		robotinfo.zhengfaData = {}
		for i = 1,num do
			table.insert(robotinfo.zhengfaData, stream:ReadUInt())
		end
		dump(robotinfo, "==========kunlun juezhan============>>>>>>>")
		LGameMsg.m_netDealMsg:Change(LUIKunLunEvent.GetRobotZhenFaInfo, robotinfo)
        this:SendMsg(LGameMsg.m_netDealMsg)
    end
end

--[[
答题处理
]]
function LuaNetRecvdMsg.DealAnswerQuestion(stream)
    local op = stream:ReadByte()
    if op == 1 then
        this.DealQueryQuestion(stream)
    elseif op == 2 then
        this.DealQuestionReward(stream)
    elseif op == 3 then
    elseif op == 4 then
    elseif op == 5 then
    end
end

--[[
处理答题信息
]]
function LuaNetRecvdMsg.DealQueryQuestion(stream)
    local row = stream:ReadByte()
    if row == 0 then
        this.SetCenterTip(stream:ReadString())
	    LGameMsg.m_netDealMsg:Change(LUIActivityEvent.UpdateQuestion, false)
		this:SendMsg(LGameMsg.m_netDealMsg)
        return
    end

    local data = LRoleDataMgr.MyHeroInfo.m_pQuestion
    data.idx = stream:ReadByte()          -- 问题索引
    data.quenum = stream:ReadByte()       -- 答对题目
    data.question = stream:ReadString()
    data.anwser = stream:ReadString()
    data.curReward = 0
    if data.rightNum == nil then data.rightNum = 0 end
    if data.reward == nil then data.reward = 0 end
    --LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Activity.AnswerMainUI",AppDef.UIType.FirstClassLayer, 1)
    --this:SendMsg(LGameMsg.m_initUIMsg)
    LGameMsg.m_netDealMsg:Change(LUIActivityEvent.UpdateQuestion, true)
    this:SendMsg(LGameMsg.m_netDealMsg)
end

--[[
处理答题奖励
]]
function LuaNetRecvdMsg.DealQuestionReward(stream)
    local op = stream:ReadByte()
    local data = LRoleDataMgr.MyHeroInfo.m_pQuestion
    if op == 0 then -- 回答错误
        local aIdx = stream:ReadByte()
        data.curReward = stream:ReadUInt()
        if data.reward == nil then
            data.reward = 0
        end
        data.reward = data.reward + data.curReward
        LGameMsg.m_netDealMsg:Change(LUIActivityEvent.UpdateAnswerInfo, aIdx)
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 1 then -- 回答正确
        data.curReward = stream:ReadUInt()
        data.reward = data.reward + data.curReward
        data.rightNum = data.rightNum + 1
        LGameMsg.m_netDealMsg:Change(LUIActivityEvent.UpdateAnswerInfo, nil)
        this:SendMsg(LGameMsg.m_netDealMsg)
    end
end

--[[
膜拜
]]
function LuaNetRecvdMsg.DealMsgMobaiInfo(stream)
    local op = stream:ReadByte()
    if op == 1 then
        this.DealQueryMobai(stream)
    elseif op == 2 then
        this.DealMobaiCnt(stream)
    elseif op == 3 or op == 4 then
        this.DealMobaiEggOrBow(op, stream)
    end
end

function LuaNetRecvdMsg.DealMsgUnExistItemInfo(stream)
    local pCItem = LCItem:New()
    pCItem.m_id = stream:ReadWord()
    pCItem.m_type = stream:ReadByte()
    pCItem.m_level = stream:ReadByte()
    pCItem.m_sex = stream:ReadByte()
    pCItem.m_name = stream:ReadString()
    pCItem.m_pic = stream:ReadWord()
    pCItem.m_ok = true
    LDataConstMgr:AddItem(pCItem)
    
    -- local pac = LRoleDataMgr.Equip.PackageList
    -- for i=1,#pac do
    --     if(pac[i].m_id == pCItem.m_id) then
    --         if(pac[i].m_item == nil) then
    --             pac[i].m_item = pCItem
    --         end
    --     end
    -- end

    -- local shop = LRoleDataMgr.Equip.ShopItemList
    -- for i=1,#shop do
    --     if(shop[i].m_id == pCItem.m_id) then
    --         if(shop[i].m_item == nil) then
    --             shop[i].m_item = pCItem
    --         end
    --     end
    -- end
            end

--[[
膜拜信息
]]
function LuaNetRecvdMsg.DealQueryMobai(stream)
    local num = stream:ReadByte()
    for i=1, num do
        local wmInfo = LWarshipModel:New()
        wmInfo.index = stream:ReadUInt()
        wmInfo.heroInfo.id = stream:ReadUInt()
        if wmInfo.heroInfo.id ~= 0 then
            wmInfo.heroInfo.roleType = stream:ReadByte()
            wmInfo.heroInfo.name = stream:ReadString()
            wmInfo.heroInfo.professional = stream:ReadByte()
            wmInfo.heroInfo.level = stream:ReadWord()
            wmInfo.heroInfo.sex = stream:ReadByte()
            wmInfo.heroInfo.LightEffect = stream:ReadByte()
            local _ = stream:ReadString()
            wmInfo.heroInfo.WingsId = stream:ReadByte()
            local _ = stream:ReadByte()
            wmInfo.heroInfo.ShenQiId = stream:ReadByte()
            if LChallengeDataMgr._MobaiModelList[i] then
                LChallengeDataMgr._MobaiModelList[i]:Delete()
                Utils:FreeTable(LChallengeDataMgr._MobaiModelList[i])
                LChallengeDataMgr._MobaiModelList[i] = nil
            end
            LChallengeDataMgr._MobaiModelList[i] = wmInfo
        end
    end
    LGameMsg.m_netDealMsg:Change(LUIArenaEvent.RefreshWarship, 0)
    this:SendMsg(LGameMsg.m_netDealMsg)
end

--[[
膜拜信息
]]
function LuaNetRecvdMsg.DealMobaiCnt(stream)
    LChallengeDataMgr._WarshipInfo.warshipPages = {}
    local warship = LChallengeDataMgr._WarshipInfo
    local num = stream:ReadByte()
    for i=1, num do
        local wsData = LWarshipPageInfo:New()
        -- wsData.index = stream:ReadUInt()
        wsData.roleId = stream:ReadUInt()
        if wsData.roleId ~= 0 then
            wsData.roleType = stream:ReadByte()
            wsData.roleName = stream:ReadString()
            wsData.profession = stream:ReadByte()
            wsData.level = stream:ReadWord()
            wsData.sex = stream:ReadByte()
            wsData.bangpaiName = stream:ReadString()
            wsData.bowCount = stream:ReadUInt()
            wsData.eggCount = stream:ReadUInt()
        end
        table.insert(warship.warshipPages, wsData)
    end
    warship.bowNum = stream:ReadByte()
    warship.eggNum = stream:ReadByte()
    warship.MaxNum = stream:ReadByte()
    warship.time = os.time() + stream:ReadUInt() -- 冷却时间
    local logNum = stream:ReadWord()
    for i=1, logNum do
        table.insert(warship.VecPlayerID, stream:ReadUInt())
        local str = stream:ReadString()
        if #warship.VecLog < 10 then
            table.insert(warship.VecLog, str)
        end
    end
    
    LGameMsg.m_netDealMsg:Change(LUIArenaEvent.RefreshWarship, 0)
    this:SendMsg(LGameMsg.m_netDealMsg)
end

--[[
膜拜信息
]]
function LuaNetRecvdMsg.DealMobaiEggOrBow(op, stream)
    local index = stream:ReadUInt()
    local roleId = stream:ReadUInt()
    local roleType = stream:ReadByte()
    
    local wsData = LChallengeDataMgr._WarshipInfo.warshipPages[index]
    local isSuccess = (stream:ReadByte() == 1)
    if isSuccess then
        if op == 3 then
            wsData.eggCount = stream:ReadUInt()
            LChallengeDataMgr._WarshipInfo.eggNum = LChallengeDataMgr._WarshipInfo.eggNum + 1
        elseif op == 4 then
            wsData.bowCount = stream:ReadUInt()
            LChallengeDataMgr._WarshipInfo.bowNum = LChallengeDataMgr._WarshipInfo.bowNum + 1
        end
        LChallengeDataMgr._WarshipInfo.time = os.time() + 60
        table.insert(LChallengeDataMgr._WarshipInfo.VecPlayerID, 1, stream:ReadUInt())
        table.insert(LChallengeDataMgr._WarshipInfo.VecLog, 1, stream:ReadString())

        if #LChallengeDataMgr._WarshipInfo.VecLog > 10 then
            table.remove(LChallengeDataMgr._WarshipInfo.VecPlayerID)
            table.remove(LChallengeDataMgr._WarshipInfo.VecLog)
        end
        LGameMsg.m_netDealMsg:Change(LUIArenaEvent.RefreshWarship, 0)
        this:SendMsg(LGameMsg.m_netDealMsg)
    end
    this.SetCenterTip(stream:ReadString())
end

function LuaNetRecvdMsg.DealMsgShilian(stream)
    local op = stream:ReadByte()
    ----print("DealMsgShilian op =", op)
    if op == 2 then
        local leaveTime = stream:ReadWord()
        LGameMsg.m_netDealMsg:Change(LUIActivityEvent.LeaveShilian, leaveTime)
        this:SendMsg(LGameMsg.m_netDealMsg)
        ----print("DealMsgShilian leave 222=>>>>>>>>>>>>>>>>>>", leaveTime)
    elseif op == 1 then
        local suc = stream:ReadByte()
        ----print("DealMsgShilian suc ======>>", suc)
        if suc == 0 then -- 失败
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
        end
    elseif op == 3 then    --抽卡界面信息
        local lotteryInfo = {}
        lotteryInfo.costYB1 = stream:ReadUInt()
        lotteryInfo.costYB2 = stream:ReadUInt()
        local itemNum = stream:ReadByte()
        ----print("DealMsgShilian itemNum", itemNum)
        lotteryInfo.itemInfo = {}
        for i = 1, itemNum do
            local item = {}
            item.idx = stream:ReadByte()
            item.id = stream:ReadWord()
            item.num = stream:ReadUInt()
            table.insert(lotteryInfo.itemInfo, item)
        end
        Utils:OpenFanPai(lotteryInfo)
    elseif op == 4 then    --抽卡
        local idx = stream:ReadByte()
        local errorCode = stream:ReadByte()
        ----print("DealMsgShilian idx = ", idx, errorCode)
        if errorCode == 1 then
            Utils:SendMsg(LUIActivityEvent.FanPaiShiLian, idx)
        end
        local msg = stream:ReadString()
        Utils:ShowScrollTips(msg)
    elseif op == 5 then    --关闭抽奖界面
        local errorCode = stream:ReadByte() -- 0 failed 1 success
        Utils:SendMsg(LUIActivityEvent.closeFanPai)
    end
end

function LuaNetRecvdMsg.DealPetAnimNotify(stream)
    --用原来代码改的,十连抽不走这里
    -- if PetkaPaiManager.m_curDarwType == AppDef.DrawType.TenDraw then
    --     return
    -- end

    local op = stream:ReadByte()
    local data = {}
    if op == 1 then--宠物
        data.petId = stream:ReadShort()
        data.petLevel = stream:ReadShort()
        data.petStar = stream:ReadByte()
    elseif op == 2 then--物品
        data.itemId = stream:ReadShort()
        data.itemNum = stream:ReadShort()
    elseif op == 3 then--宠物变道具
        data.petId = stream:ReadShort()
        data.petLevel = stream:ReadShort()
        data.petStar = stream:ReadByte()
        data.tranItemId = stream:ReadShort()
        data.tranItemNum = stream:ReadShort()
    end
    --dump(data, "DealPetAnimNotify data =============== 222222222222>")

    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "LuckyDraw.LGetPetWingManager", AppDef.UIType.PopWindow, {type=AppDef.AwrdItem.AWRD_ITEM_PET,data=data})
    this:SendMsg(LGameMsg.m_initUIMsg)
end

function LuaNetRecvdMsg.DealMsgUpgrade(stream)
    local upinfo = {}
    upinfo.petID = {}
    upinfo.petQuality = {}
    upinfo.p_lLevel = stream:ReadByte()
    upinfo.lLevel = upinfo.p_lLevel
    upinfo.lCombat = stream:ReadULongInt()
    upinfo.p_lCombat = stream:ReadULongInt()
    upinfo.p_nLevel = stream:ReadByte()
    upinfo.nLevel = upinfo.p_nLevel
    upinfo.nCombat = stream:ReadULongInt()
    upinfo.p_nCombat = stream:ReadULongInt()
    ------dump(upinfo)
    -- if(upinfo.nLevel < 6) then
    --     Utils:ShowScrollTips(GUITips.RSI_MDSI_MSGI13)
    --     return
    -- end

    -- --存在功能推送或者引导抛掉
    -- if(FuncPushMgr::GetInstance()->IsFPRuning() || DATA_MGR->Guide.IsGuiding)
    --     return

    --升级信息错误忽略
    if(upinfo.lLevel == -1) then
        return
    end
    local num = stream:ReadByte()
    local petId = 0
    local petQuality = 0
    for i=1,num do
        petId = stream:ReadWord()
        table.insert(upinfo.petID, petId)
        petQuality = stream:ReadByte()
        table.insert(upinfo.petQuality, petQuality)
    end
    upinfo.MaxFightPet = stream:ReadByte()
    ----------dump(upinfo)
    --加入弹出信息队列
end
--[[
获取设置信息
]]
function LuaNetRecvdMsg.DealMsgSetttingInfo(stream)
    local settingData = LRoleDataMgr.m_settingData
    local id_max = stream:ReadByte()
    local success = stream:ReadByte()
    if (success == 1) then
        for i=1,id_max do
            settingData[tostring(i-1)] = stream:ReadUInt()
        end
        LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.GetSettingInfo)
        this:SendMsg(LGameMsg.m_baseMsgWithOne)
    end
end

--[[
获取/设置字符串信息
]]
function LuaNetRecvdMsg.DealMsgSetttingStringInfo(stream)
    local settingData = LRoleDataMgr.m_settingStringData
    local op = stream:ReadByte()
    if op == 1 then
        local id = stream:ReadByte()
        local str = stream:ReadString()
        settingData[tostring(id)] = str
    elseif op == 2 then
        local cType = stream:ReadByte()
        if cType == 1 then
            local id = stream:ReadByte()
            local str = stream:ReadString()
            settingData[tostring(id)] = str
        elseif cType == 0 then
            local num = stream:ReadByte()
            for i=1,num do
                local id = stream:ReadByte()
                local str = stream:ReadString()
                settingData[tostring(id)] = str
            end
            -- ------dump(settingData, "settingData----------->")
            Utils:SendMsg(LUILogicEvent.GetSettingStringInfo, nil, true)
        end
    end
end

function LuaNetRecvdMsg.DealMsgTaskList(stream)
    local num = stream:ReadUInt()
    for i=1,num do
        local missionId = stream:ReadUInt()
        LRoleDataMgr.Task:SetTaskComplete(missionId)
    end
    -- --------dump(LRoleDataMgr.Task.m_taskComplete)
    LGameMsg.m_baseMsgWithOne:Change(LUITaskDataEvent.GetCompletedTask)
    this:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function LuaNetRecvdMsg.DealMsgJumpRechargeUI(stream)
    local jumpType = stream:ReadByte()
    if jumpType == 1 then
        Utils:OpenNotEnoughGold()
    end
end

function LuaNetRecvdMsg.DealMsgAudioPlay(stream)
    local op = stream:ReadByte()
    if op == 1 then
        --音效
        LGameMsg.m_audioMsg:Change(LAudioEvent.PlayEffect, AppDef.SysBGM.Get_Itme)
        this:SendMsg(LGameMsg.m_audioMsg)
    end
end

function LuaNetRecvdMsg.DealMsgFish(stream)
    local op = stream:ReadByte()
    if op == 1 then--房间列表
        local list = {}
        local roomNum = stream:ReadUInt()
        for k=1,roomNum do
            local item = LRoomInfo:New()
            item.roomID = stream:ReadUInt()
            item.peopleNum = stream:ReadByte()
            item.maxNum = 25
            table.insert(list, item)
        end
        LGameMsg.m_netDealMsg:Change(LUIActivityEvent.RefreshKunlunRoom, list)
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 2 then--返回加入房间号
        -- DATA_MGR->Hero.MyHeroInfo.huoDongState = 0;
        local succ = stream:ReadByte()
        if (succ > 0 and LRoleDataMgr.MyHeroInfo.SceneType==AppDef.SceneType.MSI_FISHROOM) then
            LRoleDataMgr.FishRoomID = stream:ReadUInt()
            LuaNetSendMsg:QueryFishingInfo(3)
        end
    elseif op == 3 then--钓鱼玩家列表
        local list = {}
        local humanNum = stream:ReadByte()
        for i=1,humanNum do
            local item = {}
            item.id = stream:ReadUInt()--角色id
            item.name = stream:ReadString()
            table.insert(list, item)
        end
        LGameMsg.m_baseMsgWithOne:Change(LUIFishEvent.LoadUserList, list)
        this:SendMsg(LGameMsg.m_baseMsgWithOne)
    elseif op == 4 then--鱼篮信息
        local heroID = stream:ReadUInt()
        local isMe = LRoleDataMgr.MyHeroInfo:IsMe(heroID)
        local num = stream:ReadByte()
        local list = {}
        for i=1,num do
            table.insert(list, stream:ReadUInt())
        end
        LGameMsg.m_baseMsgWithOne:Change(LUIFishEvent.LoadFishBasketList, {isMe, list})
        this:SendMsg(LGameMsg.m_baseMsgWithOne)
    elseif op == 5 then--开始钓鱼
        local succ = stream:ReadByte()
        if succ == 1 then
            local time = stream:ReadUInt()
            LGameMsg.m_baseMsgWithOne:Change(LUIFishEvent.UpdateState, {true, time})
            this:SendMsg(LGameMsg.m_baseMsgWithOne)
        end
    elseif op == 6 then--收获鱼
        local succ = stream:ReadByte()
        if (succ == 1) then--收获成功
            LuaNetSendMsg:QueryFishingInfo(4, LRoleDataMgr.MyHeroInfo.id)--再次请求鱼篓信息（自己）
        end
    elseif op == 10 then--停止钓鱼
        local succ = stream:ReadByte()
        if (succ == 1) then
            LGameMsg.m_baseMsgWithOne:Change(LUIFishEvent.UpdateState, {false, 0})
            this:SendMsg(LGameMsg.m_baseMsgWithOne)
        end
    elseif op == 11 then--鱼自动上钩
        local succ = stream:ReadByte()
        if (succ == 1) then
            local timeNum = stream:ReadUInt()

            LGameMsg.m_baseMsgWithOne:Change(LUIFishEvent.UpdateState, {true, timeNum})
            this:SendMsg(LGameMsg.m_baseMsgWithOne)

            LuaNetSendMsg:QueryFishingInfo(4, LRoleDataMgr.MyHeroInfo.id)--再次请求鱼篓信息（自己）
        end
    elseif op == 14 then--自动更新角色增删
        local addORrdc = stream:ReadByte()
        if (addORrdc == 0) then--减少角色
            local id = stream:ReadUInt()--角色id
            local name = stream:ReadString()
            LGameMsg.m_baseMsgWithOne:Change(LUIFishEvent.UpdateUserList, {false, id})
            this:SendMsg(LGameMsg.m_baseMsgWithOne)
        elseif (addORrdc == 1) then--增加角色
            local id = stream:ReadUInt()--角色id
            local name = stream:ReadString()
            LGameMsg.m_baseMsgWithOne:Change(LUIFishEvent.UpdateUserList, {true, id, name})
            this:SendMsg(LGameMsg.m_baseMsgWithOne)
        end
    end
end

function LuaNetRecvdMsg.DealMsgLoginNotice(stream)
    local str = stream:ReadString()
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Login.GameNoticeUI",AppDef.UIType.PopWindow, str)
    this:SendMsg(LGameMsg.m_initUIMsg)
end

function LuaNetRecvdMsg.DealMsgGameNotice(stream)
    if Utils:IsInGuide() then
        return
    end
    local list = {}
    local num = stream:ReadByte()
    if num == 0 then
        return
    end
    for i=1,num do
        local info = {}
        info.title = stream:ReadString()
        info.text = stream:ReadString()
        info.id = stream:ReadByte()
        info.opType = stream:ReadByte()
        table.insert(list, info)
    end
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "NoticeUI",AppDef.UIType.FirstClassLayer, list)
    this:SendMsg(LGameMsg.m_initUIMsg)
end

function LuaNetRecvdMsg.DealReceivedFlower(stream)
    -- body
    local op = stream:ReadUInt()
    local itemId = stream:ReadUInt()

    local ltabSend = {}
    ltabSend.itemId = itemId

    LGameMsg.m_netDealMsg:Change(LUIGiveGiftEvent.showXianhua, ltabSend)
    this:SendMsg(LGameMsg.m_netDealMsg)
    
end

function LuaNetRecvdMsg.DealServerHookState(stream)
    local state = stream:ReadByte()
    local isChange = false
    if state == 1 then--开始挂机
        if not LRoleDataMgr.isHangUp then
            isChange = true
        end
    elseif state == 2 then--停止挂机
        if LRoleDataMgr.isHangUp then
            isChange = true
        end
    end
    if isChange then
        Utils:SendMsg(LUIMainEvent.ChangeHookEvent)
    end
end

function LuaNetRecvdMsg.DealFightSpeed(stream)
    local op = stream:ReadByte()
    local speed = stream:ReadByte()

    -- ----dump({op, speed}, "DealFightSpeed--->")
    if op == 1 then
        local suc = stream:ReadByte()
        if suc == 0 then
            local str = stream:ReadString()
            Utils:ShowScrollTips(str)
        else

            LRoleDataMgr:SetFightSpeed(speed)
        end
    elseif op == 2 then
        LRoleDataMgr:SetFightSpeed(speed)
    end
end

function LuaNetRecvdMsg.DealQueryPetInfo(stream)
    -- body
    local roleId = stream:ReadUInt()
    local pid = stream:ReadWord()
    if pid <= 0 then
        return
    end

    local Data = LPetData:New(pid)
    LuaNetRecvdMsg.ReadPetInfo(Data,stream)

    -- LRoleDataMgr.OtherHeroInfo.queryPetData = Data

    -- LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "OtherRole.OtherRoleMainUI",AppDef.UIType.PopFirstClassLayer, 1)
    -- this:SendMsg(LGameMsg.m_initUIMsg)
    
--    --------dump(Data, "Query pet Info")
end

--[[
服务器读取通用格式
格式和策划配置的表格格式一直
]]
function LuaNetRecvdMsg.ReadCommonReward(stream)
    local arr = {}
    table.insert(arr,stream:ReadWord());
    table.insert(arr,stream:ReadUInt());
    table.insert(arr,stream:ReadUInt());
    return arr;
end


function LuaNetRecvdMsg.DealQueryResRecovery(stream)
    -- body
    local op = stream:ReadByte()
    -- --print("---------------------DealQueryResRecovery",op)
    if op == 1 then
        -- local offlineResInfo = LRoleDataMgr.recoveryData
        -- offlineResInfo:Reset()
        LRoleDataMgr.recoveryData = {}
        local num = stream:ReadByte()
        -- --print("num",num)
        for i = 1, num do
            local rewardData = {};
            rewardData.funcId = stream:ReadUInt();
            rewardData.leftTimes = stream:ReadWord();
            rewardData.cost = {};
            local cost = LuaNetRecvdMsg.ReadCommonReward(stream);
            rewardData.cost = cost
            -- rewardData.cost[1] = stream:ReadWord();
            -- rewardData.cost[2] = stream:ReadUInt();
            -- rewardData.cost[3] = stream:ReadUInt();
            rewardData.awardNum = stream:ReadByte();
            rewardData.awardInfo = {};
            for i = 1, rewardData.awardNum do
                local awardInfo = {}
                -- awardInfo.awardId = stream:ReadWord()
                -- awardInfo.awardNum = stream:ReadUInt()
                local arr = LuaNetRecvdMsg.ReadCommonReward(stream)
                table.insert(rewardData.awardInfo, arr)
            end
            table.insert(LRoleDataMgr.recoveryData,rewardData);
        end
        Utils:SendMsg(LUIResRecoveryEvent.updateResRecoveryUI)
        -- LRedDotCheckMgr:MainWelfareCheck(6)
    elseif op == 2 then
        local findId = stream:ReadUInt()
        local findNum = stream:ReadWord()
        -- local findType = stream:ReadByte()
        local errorCode = stream:ReadByte()
        -- --print("errorCode",errorCode)
        if errorCode == 0 then
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
        else
            local num = stream:ReadByte()
            -- --print("num",num)
            local itemArr = {}
            for i = 1, num do
                -- local itemType = stream:ReadWord();
                -- local itemNum = stream:ReadUInt();
                local arr = LuaNetRecvdMsg.ReadCommonReward(stream)
                table.insert(itemArr,arr);
                local name = Utils:getItemNameByConfigArr(arr)
                local str = string.format(GUITips.UI_MoneyTips,name,arr[3])
                Utils:ShowScrollTips(str);
            end

            -- Utils:OpenRewardBox(GUITips.RSI_BOX_TIP2,itemArr,false,"",nil,nil);

            --刷新UI
            LuaNetSendMsg:QueryResRecovery(1)

            -- LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUIInBattle, "Welfare.GainRewardUI", AppDef.UIType.PopWindow, awardInfo)
            -- this:SendMsg(LGameMsg.m_initUIMsg)
        end 
    -- elseif op == 3 then
    --     local findType = stream:ReadByte()
    --     local errorCode = stream:ReadByte()
    --     if errorCode == 0 then
    --         local msg = stream:ReadString()
    --         Utils:ShowScrollTips(msg)
    --     else
    --         local num = stream:ReadByte()
    --         local awardInfo = {}
    --         for i=1, num do
    --             local awardData = {}
    --             awardData.awardType = stream:ReadWord()
    --             awardData.awardValue = stream:ReadUInt()
    --             table.insert(awardInfo, awardData)
    --         end

    --         --刷新UI
    --         LuaNetSendMsg:QueryResRecovery(1)
    --         LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUIInBattle, "Welfare.GainRewardUI", AppDef.UIType.PopWindow, awardInfo)
    --         this:SendMsg(LGameMsg.m_initUIMsg)

    --     end
    end
end

function LuaNetRecvdMsg.DealActivityFengShen(stream)
    local op = stream:ReadByte()
    -- ------dump(op, "DealActivityFengShen---->")
    if op == 1 then
        local datas = {}
        local num = stream:ReadByte()
        for i=1,num do
           local data = {}
           data.bossId = stream:ReadWord()
           data.pic = stream:ReadUInt()
           data.name = stream:ReadString()
           data.openFlag = stream:ReadByte()
           data.desc = stream:ReadString()
           data.isOpen = Utils:ToBool(stream:ReadByte())
           data.times = stream:ReadByte()
           data.showAwardId = {}
           local awardNum = stream:ReadByte()
           for k=1,awardNum do
                table.insert(data.showAwardId, stream:ReadWord())
           end
           data.recommendPetId = {}
           local petSize = stream:ReadByte()
           for j=1,petSize do
                table.insert(data.recommendPetId, stream:ReadWord())
           end
           table.insert(datas, data)
        end
        -- ------dump(datas)
        Utils:SendMsg(LUIFengShenEvent.LoadDataEvent, datas)
    elseif op == 2 then
        local bossId = stream:ReadWord()
        local succ = stream:ReadByte()
        if succ == 0 then
            local isJump = stream:ReadByte()
            local errmsg = stream:ReadString()
            if isJump > 0 then
                local function okFunc()
                    Utils:OpenFunction(AppDef.EModuleID.EMID_VIP)
                end
                local function cancelFunc()
                end
                Utils:ShowDialogOKCancel(errmsg, okFunc, cancelFunc)
            else
                Utils:ShowScrollTips(errmsg)
            end
            return
        end
    elseif op == 3 then
        local cData = LCopyAwardData:New()
        cData.star = stream:ReadByte()
        this.ReadItemInfo(stream, cData.itemId, cData.itemVal1)
        -- ------dump(cData, "=======================>")
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "FirstAward.FirstRewardUI",AppDef.UIType.PopWindow, {3, cData})
        this:SendMsg(LGameMsg.m_initUIMsg)
    end
end

function LuaNetRecvdMsg.DealFundRebate(stream, type)
    local cdTime = stream:ReadUInt()
    local buyId = stream:ReadByte()
    -- --print("buyId ==>", buyId)
    -- ----dump({cdTime, buyId}, "LuaNetRecvdMsg.DealFundRebate--->")
    local datas = {}
    local size  = stream:ReadByte()
    -- --print("DealFundRebate size =", size)
    for  i=1,size do
        local jiJinData = {}
        jiJinData.id = stream:ReadByte()    --（1 初级，2中级，3高级）
        jiJinData.state = stream:ReadByte()   --0 未激活 1激活
        -- --print("DealFundRebate ==>", jiJinData.id, jiJinData.state)
        if type == 2 then
            jiJinData.buyTime = stream:ReadUInt()
            jiJinData.amountDays = stream:ReadByte()  --累计登录天数
            -- --print("jiJinData.amountDays ==", jiJinData.amountDays)
        end
        jiJinData.rate = stream:ReadUInt()  --多少倍数
        jiJinData.price = stream:ReadUInt()
        jiJinData.getNum = jiJinData.price * 200
        jiJinData.totalNum = stream:ReadUInt()
        jiJinData.daySize = stream:ReadByte()
        jiJinData.dayArr = {}
        -- ----dump(jiJinData, "jiJinData------->")
        for j=1,jiJinData.daySize do
            local dayData = {}

            dayData.level = stream:ReadByte()
            dayData.state = stream:ReadByte()--1不满足领取条件 2 可领取 3已经领取
            local rewardNum = stream:ReadByte()
            -- ------dump(dayData, "dayData--->")
            dayData.itemArr = {}
            for k=1,rewardNum do
                local tempData = {}
                tempData.itemId = stream:ReadWord()
                tempData.itemNum = stream:ReadUInt()
                table.insert(dayData.itemArr, tempData)
            end
            -- ------dump(dayData, "dayData------->")
            table.insert(jiJinData.dayArr, dayData)
        end
        table.insert(datas, jiJinData)
    end
    -- ------dump(datas, "datas0----->")
    if type == 1 then
        LRoleDataMgr.fundRebateData = {cdTime, buyId, datas}
        Utils:SendMsg(LUIFundRebateEvent.LoadDataEvent, LRoleDataMgr.fundRebateData)
    else
        LRoleDataMgr.huoyueJiJinData = {cdTime, buyId, datas}
        -- ----dump(LRoleDataMgr.huoyueJiJinData, "LRoleDataMgr.huoyueJiJinData ===>")
        Utils:SendMsg(LUIHuoyueLayerEvent.LoadDataEvent, LRoleDataMgr.huoyueJiJinData)
    end
    
end

function LuaNetRecvdMsg.DealPetDiscount(stream)
    local allData = {}
    allData.cdTime = stream:ReadUInt()
    local num = stream:ReadByte()
    allData.datas = {}
    for i=1,num do
        local item = {}
        item.id = stream:ReadByte()--id
        item.state = stream:ReadByte()--购买状态 1:未购买 0:已购买
        item.price = stream:ReadUInt()--原价
        item.discount = stream:ReadUInt()--折扣价
        if i == 1 then
            allData.discount = math.floor(item.discount*10/item.price)--折扣
        end
        item.petId = stream:ReadWord()
        item.petStar = stream:ReadWord()
        item.petLevel = stream:ReadWord()
        item.baseData = LDataConstMgr:GetPetData(item.petId)
        table.insert(allData.datas, item)
    end

    local rankType = WelfareActivityDef.Type.PetDiscount
    Utils:SendMsg(LUIWelfareActivityEvent.ReloadData, {rankType, allData})
end

function LuaNetRecvdMsg.DealDiscountBag(stream, op)
    local data = {}
    data.leftTime = stream:ReadUInt()
    data.price = stream:ReadUInt()
    data.discount = stream:ReadByte()
    data.buyPrice = stream:ReadUInt()
    data.isBuy = Utils:ToBool(stream:ReadByte())
    data.rewards = {}
    local num = stream:ReadByte()
    for i=1,num do
        local item = {}
        item.id = stream:ReadUInt()
        item.num = stream:ReadWord()
        item.pstar = stream:ReadWord()
        item.level = stream:ReadWord()
        if item.id > 0 then
            table.insert(data.rewards, item)
        end
    end
    
    Utils:SendMsg(LUIDiscountBagEvent.UpdateDataEvent, data)
    if data.leftTime <= 0 or data.isBuy then
        Utils:SendMsg(LUIMainEvent.UpdateDiscountBag, {type=op})
    else
        Utils:SendMsg(LUIMainEvent.UpdateDiscountBag, {type=op, info=data})
    end
end

function LuaNetRecvdMsg.DealNewDiscountBag(stream, op)
    local data = {}
    data.leftTime = stream:ReadUInt()
    data.priceType = stream:ReadByte()--1直购 2元宝
    data.price = stream:ReadUInt()--价值
    data.buyPrice = stream:ReadUInt()--购买价格
    data.isBuy = Utils:ToBool(stream:ReadByte())
    data.rewards = {}
    local num = stream:ReadByte()
    for i=1,num do
        local item = {}
        LuaNetRecvdMsg.ReadAwardData(stream, item)
        table.insert(data.rewards, item)
    end
    Utils:SendMsg(LUIDiscountBagEvent.NewUpdateDataEvent, data)
    if data.leftTime <= 0 or data.isBuy then
        Utils:SendMsg(LUIMainEvent.UpdateDiscountBag, {type=op})
    else
        Utils:SendMsg(LUIMainEvent.UpdateDiscountBag, {type=op, info=data})
    end
end

function LuaNetRecvdMsg.DealLeiTaiSai(stream)
    local op = stream:ReadByte()
    if op == 2 then
        local data = {}
        data.jiFen = stream:ReadUInt()--积分
        data.actTime = stream:ReadUInt()--活动剩余时间
        data.totalCount = stream:ReadByte()--总战斗次数
        data.totalLoseCount = stream:ReadByte()--总的可失败次数
        data.loseCount = stream:ReadByte()--失败次数
        data.winCount = data.totalCount - data.loseCount--胜利次数
        data.leftLoseCount = data.totalLoseCount - data.loseCount--剩余失败次数
        data.cdTime = stream:ReadWord()--冷却时间
        data.matchTime = stream:ReadWord()--匹配时间
        Utils:SendMsg(LUILeiTaiSaiEvent.UpdateDataEvent, data)
    elseif op == 3 then
        local vecLeiTaiPaiHang = {}
        local lastTime = stream:ReadUInt() --剩余活动时间
        local count = stream:ReadByte() --数量
        for k=1,count do
            local tmpleiTai = {}
            tmpleiTai.roleId = stream:ReadUInt() --角色id
            tmpleiTai.name = stream:ReadString() --名字
            tmpleiTai.score = stream:ReadWord() --积分
            table.insert(vecLeiTaiPaiHang, tmpleiTai)
        end
        Utils:SendMsg(LUILeiTaiSaiEvent.UpdateRankEvent, vecLeiTaiPaiHang)
    end
end

function LuaNetRecvdMsg.DealLunDao(stream)
    local op = stream:ReadByte()
    if(1 == op) then--参加活动
        local success = stream:ReadByte()
        if(success == 0) then
            Utils:ShowScrollTips(stream:ReadString())
        end
    elseif(2 == op)then --请求排行榜
        local allData = {}
        allData.rankType = 1--神界论道

        allData.myScore = stream:ReadUInt()
        allData.myRankinAll = stream:ReadWord()--全服排名

        local num = stream:ReadWord()
        allData.leftRankList = {}--全服排行
        for i=1,num do
            local item = {}
            item.rank = stream:ReadWord()
            item.roleId = stream:ReadUInt()
            item.name = stream:ReadString()
            item.score = stream:ReadUInt()
            table.insert(allData.leftRankList, item)
        end

        allData.rightRankList = {}--本服排行
        allData.serScore = stream:ReadUInt()
        allData.myRankinSelf = stream:ReadWord()

        num = stream:ReadWord()
        for i=1,num do
            local item = {}
            item.rank = stream:ReadWord()
            item.roleId = stream:ReadUInt()
            item.name = stream:ReadString()
            item.score = stream:ReadUInt()
            table.insert(allData.rightRankList, item)
        end
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Activity.LunDaoRankUI", AppDef.UIType.PopWindow)
        this:SendMsg(LGameMsg.m_initUIMsg)
        Utils:SendMsg(LUILunDaoEvent.UpdateRankEvent, allData)
    elseif(3 == op)then--请求个人活动信息
        local myData = {}
        myData.score = stream:ReadUInt()--协议调整，该值不用

        myData.killRoleNum = stream:ReadWord()
        myData.killMonsterNum = stream:ReadWord()
        myData.nextFlushScecond = stream:ReadWord()
        myData.timeSpace = stream:ReadWord()
        local num = stream:ReadByte()

        myData.killRole = {}
        for i=1,num do
            local item = {}
            item.taskName = stream:ReadString()
            item.targetDesc = stream:ReadString()
            item.killNum = stream:ReadWord()
            local str = stream:ReadString()
            local arr = string.split(str, '\n')
            for j=1,#arr do
                item['award'..j] = arr[j]
            end
            item.isComplete = (stream:ReadByte() == 1) 
            table.insert(myData.killRole, item)
        end

        myData.killManster = {}
        num = stream:ReadByte()
        for i=1,num do
            local item = {}
            item.taskName = stream:ReadString()
            item.targetDesc = stream:ReadString()
            item.killNum = stream:ReadWord()
            local str = stream:ReadString()
            local arr = string.split(str, '\n')
            for j=1,#arr do
                item['award'..j] = arr[j]
            end
            item.isComplete = (stream:ReadByte() == 1)
            table.insert(myData.killManster, item)
        end
        Utils:SendMsg(LUILunDaoEvent.UpdateDataEvent, myData)
    elseif(4 == op)then--请求房间信息
        this.ReadRoomInfo(stream)
    elseif(5 == op)then--切换房间
        local index = stream:ReadWord()
        local errMsg = stream:ReadString()
        Utils:ShowScrollTips(errMsg)
    elseif(6 == op) then--更新任务信息
        local taskData = {}
        taskData.type = stream:ReadByte()
        taskData.value = stream:ReadUInt()
        taskData.idx = stream:ReadByte()
        Utils:SendMsg(LUILunDaoEvent.UpdateTaskEvent, taskData)
    end
end

function LuaNetRecvdMsg.DealWeiWoDuXian(stream)
    -- body
    local op = stream:ReadByte()
    ----print("op DealWeiWoDuXian ==", op)
    if op == 2 then
        --报名成功
        --请求预赛信息
--        LuaNetSendMsg:QueryWeiWoDuXian(1)
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "ZhengBa.TianYuanZhengBa", AppDef.UIType.Chat )
        LUIManager:SendMsg(LGameMsg.m_initUIMsg)
    elseif op == 8 then --预赛界面
        local group = LGroupData:New()
        group.groupId = stream:ReadUInt()
        group.myScore = stream:ReadUInt()
        group.myRank = stream:ReadUInt()
        group.boxId = stream:ReadUInt()
        group.boxText = stream:ReadString()
        group.isFreeRefersh = stream:ReadByte() == 0
        group.leftTimes = stream:ReadUInt();
        group.maxTimes = stream:ReadUInt();
        group.cost = stream:ReadUInt();
        group.coolTime = stream:ReadUInt();
        group.refrashCost = 20
--        ----print("group.coolTime ++++++++++++", group.coolTime)
        for i = 1, 5 do 
            local hero = {}
            local id = LRoleDataMgr.MyHeroInfo.id
            hero.id = stream:ReadUInt();
            hero.face = 1;
            hero.name = stream:ReadString();
            hero.level = stream:ReadUInt();
            hero.professional = stream:ReadUInt();
            hero.sex = stream:ReadUInt();
            hero.vipLevel = stream:ReadUInt();
            hero.WingsId = stream:ReadUInt();
            --武器id
            hero.weponId = stream:ReadUInt();

            hero.LightEffect = stream:ReadUInt();
            hero.zhanDouLi = stream:ReadUInt();
            hero.mid = stream:ReadUInt(); --只是用mid字段 这里只用来表示积分值。不重新定义新的字段
            hero.failScore = stream:ReadUInt() --失败积分
            hero.serzoneid = LRoleDataMgr.MyHeroInfo.serzoneid; --以不用拼接区服信息
            table.insert(group.groupHeroInfo, hero)
        end

--更新界面
        if LRoleDataMgr.m_bIsInBattle then
            LWWDXMgr.m_IsAfterBattle = true
            LWWDXMgr.mGroupData = group
        else
            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "ZhengBa.TianYuanZhengBa", AppDef.UIType.Chat)
            LUIManager:SendMsg(LGameMsg.m_initUIMsg)

            LGameMsg.m_netDealMsg:Change(LUIWeiWoDuXianEvent.UpdateWWDXPreUIEvent, group)
            this:SendMsg(LGameMsg.m_netDealMsg)
        end
        
--        ------dump(group, "DealWeiWoDuXian yusai----")

    elseif op == 3 then
        local rankInfo = {}
        local groupId = stream:ReadUInt()
        local num = stream:ReadUInt()
        for i=1, num do
            local temp = GroupRankInfo:New()
            if i == 5 then
                temp.id = 0;
                temp.name = "";
                temp.score = 0;
--                rankInfo.push_back(temp);
                table.insert(rankInfo, temp)
            end
            temp.id = stream:ReadUInt();
            temp.name = stream:ReadString();
            temp.score = stream:ReadUInt();
            table.insert(rankInfo, temp)
        end
        if groupId < 1 or groupId > 8 then
            return
        end
--刷新
--        ------dump(rankInfo, "rank Info ------------------")

        LGameMsg.m_netDealMsg:Change(LUIWeiWoDuXianEvent.UpdateWWDXGroupEvent, {rankInfo, groupId})
        this:SendMsg(LGameMsg.m_netDealMsg)

    elseif op == 5 then
        local boolCost = (stream:ReadByte() == 0)
        LGameMsg.m_netDealMsg:Change(LUIWeiWoDuXianEvent.UpdateWWDXCostEvent, {op, boolCost})
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 6 then
        local leftTimes = stream:ReadUInt();
        local maxTimes = stream:ReadUInt(); --该值可不用，第一次进入时该值就已确定
        local cost = stream:ReadUInt();
--        ----print("DealWeiWoDuXian leftTimes =", leftTimes, maxTimes, cost)

        LGameMsg.m_netDealMsg:Change(LUIWeiWoDuXianEvent.UpdateWWDXLeftTimes, {op, leftTimes, cost})
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 7 then
        local seconds = stream:ReadUInt();
        LGameMsg.m_netDealMsg:Change(LUIWeiWoDuXianEvent.UpdateWWDXLeftSecond, {op, seconds})
        this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 21 or op == 28 then --界面信息
        -- msgDealMgr.cpp 14580行
        LWWDXMgr:DealWeiWoDuXianFinal(op, stream)
    elseif op == 22 or op == 29 then --查询节点信息
        local type = stream:ReadByte() --type 0上半场 1下半场 2总决赛
        ----print("type ====", type)
        local nodeIdx = stream:ReadByte();
        local suc = stream:ReadByte();
        if suc == 0 then
            local msg = stream:ReadString();
            Utils:ShowScrollTips(msg)
        else
            -- msgDealMgr.cpp 14592行
            local nodeData = {}
            nodeData.winerId = stream:ReadInt()
            nodeData.voteId = stream:ReadInt()
            nodeData.canVote = stream:ReadByte()
            nodeData.VoteMoney = stream:ReadUInt()
            local roleId1 = stream:ReadInt()

            --默认值
            nodeData._VecRoleId1 = 0
            nodeData.name1 = ""
            nodeData.sex1 = 0
            nodeData.score1 = 0
--                score[0] = score1;
            nodeData.shenjia1 = 0
            nodeData.ratio1 = 0
            nodeData.power1 = 0
            if roleId1 > 0  then
--                _VecRoleId[0] = roleId1;
                nodeData._VecRoleId1 = roleId1
                nodeData.name1 = stream:ReadString()
                nodeData.professional1 = stream:ReadByte()
                nodeData.sex1 = stream:ReadByte();
                nodeData.score1 = stream:ReadUInt();
--                score[0] = score1;
                nodeData.shenjia1 = stream:ReadUInt();
                nodeData.ratio1 = stream:ReadUInt();
                nodeData.power1 = stream:ReadUInt()
            end

            --默认值
            nodeData._VecRoleId2 = 0
            nodeData.name2 = ""
            nodeData.sex2 = 0
            nodeData.score2 = 0
            nodeData.shenjia2 = 0
            nodeData.ratio2 = 0
            nodeData.power2 = 0
            local roleId2 = stream:ReadInt();
            if roleId2 > 0 then
                nodeData._VecRoleId2 = roleId2
                nodeData.name2 = stream:ReadString();
                nodeData.professional2 = stream:ReadByte();
                nodeData.sex2 = stream:ReadByte();
 --               score[1]=score2;
                nodeData.score2 = stream:ReadUInt()
                nodeData.shenjia2 = stream:ReadUInt()
                nodeData.ratio2 = stream:ReadUInt()
                nodeData.power2 = stream:ReadUInt()
            end

--            ------dump(nodeData, "nodeData ****************")
--            ----print("DealWeiWoDuXian roleId1 =", roleId1, roleId2)
            if roleId1 <= 0 and roleId2 <= 0 then
                if LWWDXMgr.m_nodeEvent == LWWDXMgr.betEventType.MSI_QUERY then
                    Utils:ShowScrollTips(GUITips.RSI_CROSSSERVER_TIPS_6)
                elseif LWWDXMgr.m_nodeEvent == LWWDXMgr.betEventType.MSI_BET then
                    Utils:ShowScrollTips(GUITips.RSI_CROSSSERVER_TIPS_7)
                end
                LWWDXMgr.m_nodeEvent = LWWDXMgr.betEventType.MSI_NORMAL
                return
            end

            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "ZhengBa.FinalsCupUI", AppDef.UIType.Chat )
            LUIManager:SendMsg(LGameMsg.m_initUIMsg)

            nodeData.type = type
            nodeData.nodeIdx = nodeIdx

            LGameMsg.m_netDealMsg:Change(LUIWeiWoDuXianEvent.WWDXBetDialogEvent, nodeData)
            this:SendMsg(LGameMsg.m_netDealMsg)

        end
    elseif op == 23 then --下注
        local type = stream:ReadByte() --type 0上半场 1下半场 2总决赛
        local nodeIdx = stream:ReadByte();
        local voteId = stream:ReadInt();
        local suc = stream:ReadByte();
        if suc == 0 then
            local msg = stream:ReadString();
            Utils:ShowScrollTips(msg)

            --下注失败关闭界面
            LGameMsg.m_netDealMsg:Change(LUIWeiWoDuXianEvent.WWDXUpdateAfterBetUI)
            this:SendMsg(LGameMsg.m_netDealMsg)
            
        else
            -- msgDealMgr.cpp 14611
            local betData = {}
            betData.voteId = voteId
            betData.nodeIdx = nodeIdx
            betData.type = type
            if betData.voteId > 0 then
                betData.roleId1 = stream:ReadInt();
                betData.shenjia1 = stream:ReadUInt();
                betData.roleId2 = stream:ReadUInt();
                betData.shenjia2 = stream:ReadUInt();
            end
--            ------dump(betData, "betData readInt 下注")
            LGameMsg.m_netDealMsg:Change(LUIWeiWoDuXianEvent.WWDXUpdateBetData, betData)
            this:SendMsg(LGameMsg.m_netDealMsg)
            
        end
    elseif op == 24 then --前往战场
        local suc = stream:ReadByte()
        ----print("stream uc =", suc)
        if suc == 0 then
            local msg = stream:ReadString();
            Utils:ShowScrollTips(msg)
        else
            Utils:SendMsg(LUIWeiWoDuXianEvent.EnterWWDXBattleSuc)
        end
    elseif op == 25 then --唯我独仙倒计时
        --type=1 主场景显示 sid=70
        --type=2 1v1场景显示 sid=73
        local timeInfo = {}

        timeInfo.type = stream:ReadByte()
        timeInfo.msgContent = stream:ReadString()
        timeInfo.second = stream:ReadUInt()

--        ------dump(timeInfo, "timeInfo")

        LGameMsg.m_netDealMsg:Change(LUIWeiWoDuXianEvent.WWDXBattleCoundDown, timeInfo)
        this:SendMsg(LGameMsg.m_netDealMsg)

    elseif op == 26 or op == 27 then --请求决赛双方信息 27更新侧边栏显示
        local WwdxInfo = {}
        WwdxInfo.roleId1 = stream:ReadInt();
        WwdxInfo.name1 = stream:ReadString();
        WwdxInfo.score1 = stream:ReadUInt();

        WwdxInfo.roleId2 = stream:ReadInt();
        WwdxInfo.name2 = stream:ReadString();
        WwdxInfo.score2 = stream:ReadUInt();

        LGameMsg.m_netDealMsg:Change(LUIWeiWoDuXianEvent.ReadWWDXInfo, WwdxInfo)
        this:SendMsg(LGameMsg.m_netDealMsg)
    end

end



function LuaNetRecvdMsg.DealMulitiServerBoss(stream)
    local op = stream:ReadByte()
    if(1 == op)then--参加活动
        local success = stream:ReadByte()
        if(success == 0)then
            Utils:ShowScrollTips(stream:ReadString())
        end
    elseif(2 == op)then--请求排行榜
        local allData = {}
        allData.rankType = 2--神界秘境

        local num = stream:ReadWord()
        allData.leftRankList = {}--全服排行
        for i=1,num do
            local item = {}
            item.rank = stream:ReadWord()
            item.name = stream:ReadString()
            item.score = stream:ReadUInt()
            table.insert(allData.leftRankList, item)
        end
        allData.myRankinAll = stream:ReadWord()--全服排名0是未入榜

        num = stream:ReadWord()
        allData.rightRankList = {}--本服排行
        for i=1,num do
            local item = {}
            item.rank = stream:ReadWord()
            item.name = stream:ReadString()
            item.score = stream:ReadUInt()
            table.insert(allData.rightRankList, item)
        end
        allData.myRankinSelf = stream:ReadWord()--本服排名0是未入榜
        
        allData.myScore = stream:ReadUInt()--个人伤害
        allData.serScore = stream:ReadUInt()--本服总伤害
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Activity.LunDaoRankUI", AppDef.UIType.PopWindow)
        this:SendMsg(LGameMsg.m_initUIMsg)
        Utils:SendMsg(LUIMiJingEvent.UpdateRankEvent, allData)
    elseif(3 == op)then--请求房间信息
        this.ReadRoomInfo(stream)
    elseif(4 == op)then--切换房间
        local _ = stream:ReadUInt()
        Utils:ShowScrollTips(stream:ReadString())
    elseif(5 == op)then--面板信息
        local allData = {}
        for i=1,2 do
            local item = {}
            item.id = stream:ReadUInt()
            item.name = stream:ReadString()
            item.state = stream:ReadUInt()--0:未刷新 1:已刷新 2:已击败
            item.time = stream:ReadString()
            table.insert(allData, item)
        end
        local rewards = {}
        for j=1,3 do
            table.insert(rewards, stream:ReadUInt())
        end
        for i=1,#allData do
            allData[i].rewards = rewards
        end
        Utils:SendMsg(LUIMiJingEvent.UpdateDataEvent, allData)
    elseif(6 == op)then--活动开始/结束
        local isShow = stream:ReadByte() == 1
        Utils:SendMsg(LUIMiJingEvent.UpdateRedDotEvent, isShow)
    elseif(7 == op)then--更新boss血条
        local data = {}
        data.pic = stream:ReadUInt()
        data.name = stream:ReadString()
        data.hp = stream:ReadUInt()
        data.Maxhp = stream:ReadUInt()
        data.id = stream:ReadUInt()
        data.leftTime = stream:ReadUInt()
        Utils:SendMsg(LUIMiJingEvent.UpdateHPEvent, data)
    elseif(8 == op)then--关闭boss血条
        Utils:SendMsg(LUIMiJingEvent.UpdateHPEvent)
    elseif(9 == op)then--更新boss倒计时
        local second = stream:ReadUInt()
        Utils:SendMsg(LUIMiJingEvent.UpdateFaildedTimeEvent, second)
    elseif(10 == op)then--战斗失败，人物死亡
        Utils:SendMsg(LUIMiJingEvent.UpdateBattleFailedEvent)
    end
end

function LuaNetRecvdMsg.DealUpdateFightHp(stream)
    local msg = {}
    msg.pos = stream:ReadByte()
    msg.hp = stream:ReadUInt()
    LRoleDataMgr.m_bossHpData = msg
end
function LuaNetRecvdMsg.DealMsgJingjie(stream)
    local op = stream:ReadByte()

    local  OtInfo= LRoleDataMgr.MyHeroInfo.jingJieOtherInfo
  if op==1 then --获取境界信息
    OtInfo.curId=stream:ReadWord()   
    LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIJingJieEvent.UpdateInfo)
    this:SendMsg(LGameMsg.m_netDealBaseMsg)
    --if OtInfo.isShow == 1 and OtInfo.curId > 0 then
    --    local vipMsg = RoleVipMsg:new(CEnum.RoleEvent.SetJingJie,OtInfo.curId)
    --    this:SendMsg(vipMsg)
    --else
    --    local vipMsg = RoleVipMsg:new(CEnum.RoleEvent.SetJingJie,0)
    --    this:SendMsg(vipMsg)
    --end
   elseif op==4 then --突破
      local isSuccess = stream:ReadByte()
      local msg = stream:ReadString()
      Utils:ShowScrollTips(msg)  
      if isSuccess==1 then
        local id = stream:ReadWord() 
        --LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIJingJieEvent.UpdateInfo)
        --this:SendMsg(LGameMsg.m_netDealBaseMsg)
		local data = JsonConfig.m_jingjieConfig.getDefByID(id)
		Utils:ShowScrollTips( string.format(GUITips.RSI_JINGJIE_TIPS2, data.name))
      end
   end
    LRedDotCheckMgr:MianJingJieCheck()
    
end

function LuaNetRecvdMsg.DealMsgChangeName(stream)
    local op = stream:ReadByte()
    local msg = stream:ReadString()
    local errorCode = stream:ReadByte()
    --print("DealMsgCrossMsg ++", op,msg,errorCode)
    if errorCode == 0 then
        local msg = stream:ReadString()
        Utils:ShowScrollTips(msg)
        return
    end
    if op == 1 then
        local msgSuc = stream:ReadString()
        Utils:ShowScrollTips(msgSuc)
        LRoleDataMgr.MyHeroInfo.name = msg
        --更新角色名字
        -- local nameLabel = LRoleDataMgr.MyHeroInfo.node:getChildByTag(-7)
        -- if nameLabel ~= nil then
        --     nameLabel:setString(msg)
        -- end
        Utils:SendMsg(LUILogicEvent.changeNameSuc)
    elseif op == 2 then
        --帮派改名
        local msgSuc = stream:ReadString()
        Utils:ShowScrollTips(msgSuc)
        LRoleDataMgr.Faction.Info.name = msg

        --更新帮派名字
        -- local nameLabel = LRoleDataMgr.MyHeroInfo.node:getChildByTag(-14)
        -- if nameLabel ~= nil then
        --     local showStr = msg .. LRoleDataMgr:getMyFactionRankTypeName()
        --     nameLabel:setString(showStr)
        -- end

        Utils:SendMsg(LUILogicEvent.changeBpNameSuc)

    else
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIChatEvent.updateSendLabaMsg)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
    end
end

--跨服喊话
function LuaNetRecvdMsg.DealMsgCrossser(stream)
    -- body
    local msg = LChatMsgNode:New()
    msg.chanel = AppDef.ChatChanelType.CCT_LABA
    msg.roleId = stream:ReadUInt()
    msg.roleName = stream:ReadString()
    msg.vipLevel = stream:ReadByte()
    msg.prof = stream:ReadByte()
    msg.sex = stream:ReadByte()
    msg.chatContent = stream:ReadString()

--    ------dump(msg, "laba msg info")

    if string.len(msg.chatContent) <= 0 then
        return
    end

--非系统公告过滤限制字符
    msg.chatContent = Utils:FilterLimitedMsg(msg.chatContent)
	if Utils:FilterAdLimitedMsg(msg.chatContent) == true then
		return
	end
        --跑马灯
    local strNotice = msg.roleName .. ":"..msg.chatContent
    Utils:ShowLabaNoticeMsg(strNotice)

    LRoleDataMgr.Chat:AddChatMsg(msg)

    --    通知增加一条消息
    LGameMsg.m_netDealMsg:Change(LUIChatEvent.addMsg, msg)
    this:SendMsg(LGameMsg.m_netDealMsg)

end

function LuaNetRecvdMsg.DealMsgPK(stream)
    local op = stream:ReadByte()
    if op == 2 then
        local succ = stream:ReadByte()
        if succ == 0 then
            Utils:ShowScrollTips(stream:ReadString())
        end
    end
end

function LuaNetRecvdMsg.DealLaBaIsOpen(stream)
    -- body
    local op = stream:ReadByte()
    local state = stream:ReadByte()
--    ----print("DealLaBaIsOpen op =", op, state)
    if state == 0 then
        Utils:ShowScrollTips(GUITips.RSI_CROSSSERVER_TIPS_8)
    else
        LGameMsg.m_netDealMsg:Change(LUIChatEvent.openSendLabaUI)
        this:SendMsg(LGameMsg.m_netDealMsg)
    end
end
--世界等级
function LuaNetRecvdMsg.DealWorldLevel(stream)
   local  isSucess=stream:ReadByte()
   if isSucess==1 then
      local worldLevel = stream:ReadWord()
      local percent=stream:ReadWord()
      local openLevel = stream:ReadWord()
      local data = LBuffData:New()
      data.type=AppDef.BuffType.WorldLevel  
      data.limitLevel=openLevel
      data.dic1=worldLevel
      data.dic2=percent
      LRoleDataMgr.MyHeroInfo.m_BufferList[data.type]=data
      -- LRoleDataMgr.WorldLevel=worldLevel
      -- LRoleDataMgr.WorldLevelPercent=percent
      -- LRoleDataMgr.WorldLevelOpenLimit=openLevel     
      LGameMsg.m_baseMsgWithOne:Change(LUIRoleDataChangeEvent.CheckOpenBuffTips,AppDef.BuffType.WorldLevel)
      this:SendMsg(LGameMsg.m_baseMsgWithOne)
   end
end

function LuaNetRecvdMsg.DealMsgZaDan(stream, op)
    local opt = stream:ReadByte()
    if opt == 1 then
        local succ = stream:ReadByte()
        if succ == 0 then
            Utils:ShowScrollTips(stream:ReadString())
            return
        end
        local datas = {}
        datas.op = op
        datas.score = stream:ReadUInt()
        datas.clearTime = stream:ReadUInt()
        datas.leftTime = stream:ReadUInt()
        
        datas.awards = {}
        local num = stream:ReadByte()
        for i = 1,num do
            local award = {}
            LuaNetRecvdMsg.ReadAwardData(stream, award)
            award.jp = stream:ReadByte()--极品
            table.insert(datas.awards, award)
        end
        
        datas.extraInfo = {}
        local num = stream:ReadByte()
        for i=1,num do
            local info = {}
            info.num = stream:ReadUInt()
            info.price = stream:ReadUInt()
            table.insert(datas.extraInfo, info)
        end

        datas.myRecords = {}
        local num = stream:ReadByte()
        for i=1,num do
            table.insert(datas.myRecords, 1, stream:ReadString())
        end

        datas.allRecords = {}
        local num = stream:ReadByte()
        for i=1,num do
            table.insert(datas.allRecords, 1, stream:ReadString())
        end
        Utils:SendMsg(LUIZaDanEvent.UpdateDataEvent, datas)
    elseif opt == 2 then
        local t = stream:ReadByte()
        local succ = stream:ReadByte()
        if succ == 0 then
            Utils:ShowScrollTips(stream:ReadString())
            return
        end
        local data = {}
        data.op = op
        data.score = stream:ReadUInt()
        data.index = stream:ReadByte()--0~9

        data.myRecords = {}
        local num = stream:ReadByte()
        for i=1,num do
            table.insert(data.myRecords, stream:ReadString())
        end

        data.allRecords = {}
        local num = stream:ReadByte()
        for i=1,num do
            table.insert(data.allRecords, stream:ReadString())
        end
        dump(data, "DealMsgZaDan ====>")
        Utils:SendMsg(LUIZaDanEvent.BuyResultEvent, {isSingle=(t==0), data=data})
    end
end

--获取IAP orderId 
function LuaNetRecvdMsg.DealGetIAPOrderId(stream)
    local type = stream:ReadWord()
    local orderId = stream:ReadString()
    GameSdk.iapOrderId = orderId
    ----print("DealGetIAPOrderId", orderId, type)

    if type ~= GameSdk.ChannelId then
        return
    end

    if GameSdk.payMoney > 0 then
--        GameSdk:regesterIosPaySucCallBack()
        local app = cc.Application:getInstance()
        local targetPlatform = app:getTargetPlatform()
        if (cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform) or (cc.PLATFORM_OS_MAC == targetPlatform) then
            if not GameSdk:IsQuickSDK() then
                Utils:ShowWaiting(LuaNetCmd.MSG_CLIENT_MARKET, GUITips.RSI_IAP_MSG)
            end
        end
        GameSdk:setIapOrderId(GameSdk.iapOrderId)
        GameSdk:IAPPay(GameSdk.payMoney)
    end
    -- GameSdk:IAPPay(money)
end

function LuaNetRecvdMsg.DealIapValidateResulet(stream)
    -- body
    local suc = stream:ReadByte() -- 1 success 2 failed
    --print("DealIapValidateResulet", suc)
    if suc ==  1 then
        Utils:SendMsg(LUILogicEvent.paymentSuccess)
    else
        Utils:ShowScrollTips(GUITips.RSI_IOS_IAP_DES_TIPS4)
    end
   
end

function LuaNetRecvdMsg.DealOverDayMsg(stream)
    -- body
    local op = stream:ReadByte()
    -- print("DealOverDayMsg =========> DealOverDayMsg", op)
    Utils:SendMsg(LUIMainEvent.ChangeDayMsg)
end

function LuaNetRecvdMsg.ReadBattleResult(stream,figthData)
    --战斗结算
    figthData = figthData or {}
    figthData.itemList = {}
    figthData.starNum = stream:ReadByte()
    print("ReadBattleResult == figthData.starNum >", figthData.starNum)
    local itemNum = stream:ReadByte()
    for i=1, itemNum do
        local item = LuaNetRecvdMsg.ReadCommonReward(stream)
        -- item.itemId = stream:ReadWord()
        -- item.itemNum = stream:ReadInt()
        -- if item.itemId == 60028 then
        --     item.addNum = stream:ReadInt()
        -- end
        table.insert(figthData.itemList, item)
    end
    --保存战斗结果
    LRoleDataMgr.m_fightResultData = figthData

    --更新数据的
    Utils:SendMsg(LUIFuBenMapEvent.refrashUIAfterFight, figthData)
end

function LuaNetRecvdMsg.DealBigMapMsg(stream)
    -- body
    local op = stream:ReadByte()
    if op == 1 then
        local type = stream:ReadByte()
        local errorCode = stream:ReadByte()
        local mapDataInfo = {}
        mapDataInfo.mapNodeNum = stream:ReadWord()
        -- --print("DealBigMapMsg ==>", errorCode, mapDataInfo.mapNodeNum)
        mapDataInfo.mapNodeList = {}
        for i=1, mapDataInfo.mapNodeNum do
            local oneData = {}
            oneData.chapterId = stream:ReadUInt()
            oneData.chapterName = stream:ReadString()
            oneData.openLevel = stream:ReadWord()
            oneData.chapterMaxStarNum = stream:ReadByte()
            table.insert(mapDataInfo.mapNodeList, oneData)
        end

        mapDataInfo.curChapterId = stream:ReadUInt()
        mapDataInfo.curStageID  = stream:ReadUInt()
        mapDataInfo.passChapterNum = stream:ReadWord()
        mapDataInfo.passList = {}
        mapDataInfo.ownTotalStarNum = 0
        for i=1, mapDataInfo.passChapterNum do
            local oneData = {}
            oneData.chapterId = stream:ReadUInt()
            oneData.ownStarNum = stream:ReadWord()
            mapDataInfo.ownTotalStarNum = mapDataInfo.ownTotalStarNum + oneData.ownStarNum
            oneData.ownBoxNum = stream:ReadByte()
            table.insert(mapDataInfo.passList, oneData)
        end
        -- ----dump(mapDataInfo, "DealBigMapMsg ===>")
        Utils:SendMsg(LUIFuBenMapEvent.refrashBigMapUI, mapDataInfo)
        -- --print("1111111111111 ===>", LUIFuBenMapEvent.refrashBigMapUI, LUILunDaoEvent.UpdateDataEvent)

    elseif op == 2 then
        local stageInfo = {}
        stageInfo.type = stream:ReadByte()
        stageInfo.stageNodeList = {}
        stageInfo.chapterId = stream:ReadUInt()
        local errcode = stream:ReadByte()
        stageInfo.curStageName = stream:ReadString()
        local nodeNum = stream:ReadByte()
        for i=1, nodeNum do
            local nodeInfo = {}
            nodeInfo.stageId = stream:ReadUInt()
            nodeInfo.configData = JsonConfig.m_stageNodeConfig.getDefByID(nodeInfo.stageId);
            nodeInfo.maxNum = nodeInfo.configData.AttackCount
            nodeInfo.stageName = stream:ReadString()
            nodeInfo.getStarNum = stream:ReadByte()
            nodeInfo.fightNum = stream:ReadByte()
            nodeInfo.useTili = stream:ReadByte()
            nodeInfo.leftResetTimes = stream:ReadByte()
            nodeInfo.resetCost = stream:ReadWord()
            -- --print("nodeInfo.resetCost",nodeInfo.resetCost)
            nodeInfo.nextLevel = stream:ReadUInt()
            nodeInfo.boxId = stream:ReadUInt()
            nodeInfo.boxState = -1
            if nodeInfo.boxId > 0 then
                nodeInfo.boxState = stream:ReadByte() --0 不能领取 1 可以领取 2已经领取
            end

            --货币奖励
            nodeInfo.itemList = {}
            local huobiAwardNum = stream:ReadByte()
            for i=1, huobiAwardNum do
                local item = LuaNetRecvdMsg.ReadCommonReward(stream)
                -- item.itemId = stream:ReadWord()
                -- item.itemNum = stream:ReadInt()

                table.insert(nodeInfo.itemList, item)
            end

            local itemNum = stream:ReadByte()
            for i=1, itemNum do
                local item = LuaNetRecvdMsg.ReadCommonReward(stream)
                -- item.itemId = stream:ReadWord()
                -- item.itemNum = stream:ReadInt()
                table.insert(nodeInfo.itemList, item)
            end
            table.insert(stageInfo.stageNodeList, nodeInfo)
          --  ----dump(nodeInfo, "DealBigMapMsg  1111111111111111 ==> ")
        end

        stageInfo.starBoxNum = stream:ReadByte()
        stageInfo.starBoxlist = {}
        for i=1, stageInfo.starBoxNum do
            local starData = {}
            starData.needStarNum = stream:ReadByte()  --宝箱需要的星星
            starData.boxId = stream:ReadUInt()
            starData.boxState = stream:ReadByte() --0 不能领取 1 可以领取 2已经领取
            table.insert(stageInfo.starBoxlist, starData)
        end
        --保存关卡数据
        PetkaPaiManager.m_StageInfo = stageInfo

        -- ----dump(stageInfo.starBoxlist, "DealBigMapMsg  222222222222222222 ==> ")
        Utils:SendMsg(LUIFuBenMapEvent.refrashStageMapUI, stageInfo)

    elseif op == 4 then
        --获取宝箱
        local type = stream:ReadByte()
        local boxAwardInfo = {}
        boxAwardInfo.chapterId = stream:ReadUInt()
        boxAwardInfo.boxId = stream:ReadUInt()
        --print("boxAwardInfo.boxId ===>", boxAwardInfo.chapterId, boxAwardInfo.boxId)

        local errorCode = stream:ReadByte()
        local num = stream:ReadByte()
        
        boxAwardInfo.itemList = {}
        for i=1, num do
            local data = LuaNetRecvdMsg.ReadCommonReward(stream)
            -- data.itemId = stream:ReadWord()
            -- data.itemNum = stream:ReadUInt()
            table.insert(boxAwardInfo.itemList, data)
        end

        Utils:SendMsg(LUIFuBenMapEvent.getBoxAwardSuc, boxAwardInfo)

    elseif op == 5 then
        --op 5 挑战
        --op == 6 扫荡
        local type = stream:ReadByte() --1 主线  2 支线
        local fightInfo = {}
        fightInfo.chapterId = stream:ReadUInt()
        fightInfo.stageId = stream:ReadUInt()
        --print("DealBigMapMsg ===>", type, fightInfo.chapterId, fightInfo.stageId)


    elseif op == 6 then
        local type = stream:ReadByte()
        local chapterId = stream:ReadUInt()
        local stageId = stream:ReadUInt()
        local errcode = stream:ReadByte()
        if errcode == 0 then
            Utils:ShowScrollTips(stream:ReadString())
            return
        end
        --print("DealBigMapMsg ===>", type, errcode, chapterId, stageId)
        local fightNum = stream:ReadByte()
        local fastFightInfo = {}
        for i=1, fightNum do
            local oneFightData = {}
            oneFightData.fightIndex = stream:ReadByte()
            --print("oneFightData.fightIndex ===>", oneFightData.fightIndex)
            --货币奖励
            oneFightData.itemList = {}
            local huobiAwardNum = stream:ReadByte()
            for i=1, huobiAwardNum do
                local item = LuaNetRecvdMsg.ReadCommonReward(stream)
                -- item.itemId = stream:ReadWord()
                -- item.itemNum = stream:ReadInt()

                table.insert(oneFightData.itemList, item)
            end

            local itemNum = stream:ReadByte()
            for i=1, itemNum do
                local item = LuaNetRecvdMsg.ReadCommonReward(stream)
                -- item.itemId = stream:ReadWord()
                -- item.itemNum = stream:ReadInt()
                table.insert(oneFightData.itemList, item)
            end
            table.insert(fastFightInfo, oneFightData)
        end
        local data = {}
        data.stageId = stageId;
        data.sandangNum = fightNum;
        Utils:SendMsg(LUIFuBenMapEvent.updateSaoDangEvent,data)
        -- ----dump(fastFightInfo, "fastFightInfo 2222222222222222 ===>")
        local saodang = {}
        saodang.showType = 0
        saodang.result = fastFightInfo
        Utils:InitUI("FuBenMap.SaoDangResultUI", AppDef.UIType.PopWindow, saodang)

    elseif op == 7 then
        --重置关卡
        local resetStageInfo = {}
        resetStageInfo.stageId = stream:ReadUInt()
        resetStageInfo.errCode = stream:ReadByte()
        resetStageInfo.resetTimes = stream:ReadByte()
        resetStageInfo.cost = stream:ReadByte()
        ----dump(resetStageInfo, "resetStageInfo ===>")
        if resetStageInfo.errCode > 0 then
            Utils:SendMsg(LUIFuBenMapEvent.resetFightTimesSuc, resetStageInfo)
        end
        
    elseif op == 8 then
        local figthData = {}
        figthData.alreadyFightTimes = stream:ReadByte()
        figthData.curStageId= stream:ReadUInt()
        figthData.unLockMap = stream:ReadUInt()
        figthData.stageId = stream:ReadUInt()

        figthData.unLockBox = stream:ReadUInt()
        figthData.unLockstarBox = stream:ReadUInt()
        --dump(figthData, "figthData ================>")
        LuaNetRecvdMsg.ReadBattleResult(stream,figthData)
        
	elseif op == 9 then
		local shilianId = stream:ReadUInt()
		local jiesuoId = stream:ReadUInt()
		local times =  stream:ReadByte()
		local tiaozhandata = {}
		tiaozhandata.shilianId = shilianId
		tiaozhandata.jiesuoId = jiesuoId
		tiaozhandata.times = times
        LuaNetRecvdMsg.ReadBattleResult(stream,fightData)
        
		--print("op =", op)
		--dump(tiaozhandata, "tiaozhan=====>")
		Utils:SendMsg(LUIFengShenEvent.TiaoZhanDataEvent, tiaozhandata)
		--红点检查
		LRedDotCheckMgr:FuBenRedDotCheck()
		local fightData = {}
        fightData.wanFaId = AppDef.EModuleID.EMID_KAPAI_FENGSHENSHILIAN
        
	elseif op == 21 then
		local datas = {}
        local num = stream:ReadByte()
        for i=1,num do
           local data = {}
           data.shilianId = stream:ReadUInt()
           data.times = stream:ReadByte()
           data.isOpen = Utils:ToBool(stream:ReadByte())
		   data.saodangId = stream:ReadUInt()
           data.tiaozhanId = stream:ReadUInt()
           table.insert(datas, data)
        end
        --dump(datas)
		Utils:SendMsg(LUIFengShenEvent.LoadDataEvent, datas)
		LRoleDataMgr.m_fengshenshilianData = datas
		
		--红点检查
		LRedDotCheckMgr:FuBenRedDotCheck()
	elseif op == 22 then
		local shilianId = stream:ReadUInt()
		local status = stream:ReadByte()
		--print(shilianId.."============="..status)
		if status == 1 then
			--Utils:ShowScrollTips(GUITips.RSI_FENGSHEN_TIAOZHAN_SUCCESS)
		else 
			--Utils:ShowScrollTips(GUITips.RSI_FENGSHEN_TIAOZHAN_FAILED)
		end
		--print("op =", op)
	elseif op == 23 then
		local shilianId = stream:ReadUInt()
		local status = stream:ReadByte()
		local times = stream:ReadByte()
		--print(shilianId.."============="..status)
		if status == 0 then
			return
		end

		local huobi = stream:ReadByte()
		local itemlist = {}
		for i=1,huobi do
           local data = LuaNetRecvdMsg.ReadCommonReward(stream)
     --       data.id = stream:ReadWord()
		   -- data.num = stream:ReadInt()
           table.insert(itemlist, data)
        end 
		local wuping = stream:ReadByte()
		for i=1,wuping do
			local data = LuaNetRecvdMsg.ReadCommonReward(stream)
   --          data.id = stream:ReadWord()
			-- if data.id == AppDef.AwrdItem.AWRD_ITEM_FABAO then
			-- 	data.fabaoid = stream:ReadUInt()
			-- 	data.num = stream:ReadUInt()
			-- else
			-- 	data.num = stream:ReadInt()
			-- end
           table.insert(itemlist, data)
        end
		local saodangdata = {}
		saodangdata.shilianId = shilianId
		saodangdata.times = times
		saodangdata.itemlist = itemlist

		--print("op =", op)
		----dump(saodangdata, "saodang===========>")
		Utils:SendMsg(LUIFengShenEvent.SaoDangDataEvent, saodangdata)
		--红点检查
		LRedDotCheckMgr:FuBenRedDotCheck()
    elseif op == 24 then--封神列传信息
        local data = LActivityManager:GetFengShenStoryData()
        data.m_chapterId = stream:ReadUInt()+1 --当前章节
        data.m_curLevelId = stream:ReadUInt() --当前关卡
        data.m_cnt = stream:ReadByte()
        -- local num = stream:ReadWord()  --未领奖励个数
        -- data.m_giftBoxs = {}
        -- for i=1,num do
        --     local value = {}
        --     value.chapterId = stream:ReadUInt()+1
        --     value.boxId = stream:ReadUInt() --宝箱ID
        --     table.insert(data.m_giftBoxs,value)
        -- end
        --print("m_cnt",data.m_cnt)
        ------dump(data,"fengshengliezhuan data")
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIActivityEvent.RefreshFengShenStoryUI)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
    elseif op == 25 then --封神列传挑战
        local suc = stream:ReadByte()
        if suc == 0 then
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
        end
        ----print("fengshengliezhuan op == 25 suc",suc)
    elseif op == 26 then --通用奖励窗口
        local rewards = {}
        local num = stream:ReadByte()  --未领奖励个数
        for i=1,num do
            -- local value = {}
            -- value[1] = stream:ReadWord()
            -- value[2] = 0
            -- value[3] = stream:ReadUInt() --宝箱ID
            -- table.insert(rewards,value)
            local arr = LuaNetRecvdMsg.ReadCommonReward(stream)
            table.insert(rewards,arr)
        end
        Utils:OpenRewardBox(GUITips.RSI_BOX_TIP2,rewards,true,GUITips.RSI_GS_TIP_RECOVERY_SURE)
    elseif op == 10 then --封神列传战斗结束推送
        local data = LActivityManager:GetFengShenStoryData()
        local chapterId = stream:ReadUInt()+1--章节
        local levelId = stream:ReadUInt()--小关id
        data.m_cnt = stream:ReadByte()--剩余次数
        data.m_chapterId = stream:ReadUInt()+1--解锁章节
        data.m_curLevelId = stream:ReadUInt()--解锁小关id
        ----dump(data,"op == 10 data")
        local figthData = {}
        figthData.wanFaId = AppDef.EModuleID.EMID_KAPAI_WF_FS_STORY
        LuaNetRecvdMsg.ReadBattleResult(stream,figthData)
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIActivityEvent.RefreshFengShenStoryUI)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
    elseif op == 11 then --主线成就
        local errCode = stream:ReadByte()
        --print("ChangeEventId = errCode ==>", errCode)
        if errCode > 0 then
            local data = {}
            data.orderType = stream:ReadByte()
            data.bitMap = stream:ReadByte()
            -- dump(data, "ChangeEventId ===>")
            Utils:SendMsg(LUIFuBenMapEvent.updateFuBenAchievement, data)
        else
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
        end
    elseif op == 12 then  --领奖
        local index = stream:ReadByte()
        local errcode = stream:ReadByte()
        --print("saodang===== 111111111111111111 ===>", errcode, index)
        if errcode > 0 then
            local data = {}
            data.orderType = stream:ReadByte()
            data.bitMap = stream:ReadByte()
            data.awardItem = LuaNetRecvdMsg.ReadCommonReward(stream)
            -- data.awardType = stream:ReadWord()
            -- data.awardNum = stream:ReadUInt()
            -- dump(data, "LuaNetRecvdMsg reword ===== 1111>")
            Utils:SendMsg(LUIFuBenMapEvent.updateFuBenAchievement, data)
        else
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
        end
    elseif op == 27 then
        local value = {}
        value.fType = stream:ReadByte()
        value.mapId = stream:ReadUInt()
        value.nodeId = stream:ReadUInt()
        value.star =  stream:ReadByte()--0xff未开启，0可以打，其他可以扫荡
        value.fightCnt = stream:ReadByte() --已挑战次数
        value.resetCnt = stream:ReadByte() --可以重置次数
        --dump(value)
        LGameMsg.m_netDealMsg:Change(LUIFuBenMapEvent.getSingleNodeSuc,value)
        this:SendMsg(LGameMsg.m_netDealMsg)
    end
end

function LuaNetRecvdMsg.DealTili(stream)
    Utils:RemoveWaiting(LuaNetCmd.MSG_QUERY_TILI)
    local op = stream:ReadByte()
    --print("DealTili op ===== 1111>", op)
    if op == 1 then
        local errcode = stream:ReadByte()
        local tili = stream:ReadWord()
        LRoleDataMgr.MyHeroInfo:GetDetailData():setTili(tili)
        local nextUpdateTiliTime = stream:ReadUInt()
        PetkaPaiManager:setTiLiTimer(nextUpdateTiliTime,nil)
        --print("DealTili ===", errcode, tili, nextUpdateTiliTime)
    elseif op == 2 then
        --每日免费体力信息
        local errcode = stream:ReadByte()
        local tiliData = {}
        local receiveTimes = stream:ReadByte()
        --print("receiveTimes",receiveTimes)
        for i=1, receiveTimes do
            -- local oneData = {}
            local index = stream:ReadByte()
            local state = stream:ReadByte()
            tiliData[index] = state
            -- table.insert(tiliData, oneData)
        end
        ----dump(tiliData, "tiliData =====>")
        Utils:SendMsg(LUIRoleDataChangeEvent.GetFreeTili,tiliData)
        --LGameMsg.m_netDealMsg:Change(LUIWelfareActivityEvent.ReloadData, {WelfareActivityDef.Type.GetTili, tiliData})
        -- LGameMsg.m_netDealMsg:Change(LUIWelfareActivityEvent.ReloadData, {AppDef.EModuleID.EMID_ACTIVITY_Tili_REVERT, tiliData})
        -- this:SendMsg(LGameMsg.m_netDealMsg)
    elseif op == 3 then
        
        local receiveType = stream:ReadByte()
        local ind = stream:ReadByte()
        local erroCode = stream:ReadByte()
        if erroCode > 0 then
            local curTili = stream:ReadWord()
            --print("idx == ", receiveType, curTili)
            LRoleDataMgr.MyHeroInfo:GetDetailData():setTili(curTili)
            Utils:SendMsg(LUIRoleDataChangeEvent.GetTiliSuc, receiveType)
        else
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
        end
    end

end

function LuaNetRecvdMsg.DealHeroBook(stream)
    local op = stream:ReadByte()
    if op == 1 then
        LRoleDataMgr.m_book.curLevel = stream:ReadByte()
        --print("DealHeroBook === 1111111111 >", LRoleDataMgr.m_book.curLevel)
        LRoleDataMgr.m_book.curScore = stream:ReadUInt()
        stream:ReadUInt()
        stream:ReadUInt()

        -- 星星 积分
        local size = stream:ReadByte()
      
        for i=1,size do
            local starScore = {}
            local heroId = stream:ReadUShort()
            starScore.star = stream:ReadByte()
            starScore.score = stream:ReadUShort()
            LRoleDataMgr.m_book.bookStar[heroId] = starScore
        end
   

        -- 图鉴属性
        size = stream:ReadByte()
      
        for i=1,size do
            local atype = stream:ReadUShort()
            local avalue = stream:ReadUInt()
            LRoleDataMgr.m_book.bookAttr[atype] = avalue

        end
       
        -- 积分属性
        size = stream:ReadByte()
     
        for i=1,size do
            local atype = stream:ReadUShort()
            local avalue = stream:ReadUInt()
            LRoleDataMgr.m_book.bookScoreAttr[atype] = avalue
        end
    
       

        Utils:SendMsg(LUIKaPaiPetEvent.ShowHeroBookUI)
    elseif op == 2 then
        local heroId = stream:ReadUShort()
        local suc = stream:ReadByte()
        if suc == 0 then
            Utils:ShowScrollTips(stream:ReadString(), true)
        else
            local sucInfo = {}
            sucInfo.heroId = heroId
            sucInfo.star = stream:ReadByte()
            sucInfo.addScore = stream:ReadUShort()
            LRoleDataMgr.m_book.curScore = LRoleDataMgr.m_book.curScore + sucInfo.addScore
            sucInfo.booklevel = stream:ReadUShort()
            sucInfo.cardAttr = {}
            sucInfo.levelAttr = {}
            local num = stream:ReadByte()
            for i=1,num do
                local attr = {}
                attr.type = stream:ReadUShort()
                attr.value = stream:ReadUInt()
                if LRoleDataMgr.m_book.bookAttr[attr.type]~=nil then
                    LRoleDataMgr.m_book.bookAttr[attr.type] =LRoleDataMgr.m_book.bookAttr[attr.type]+attr.value
                else
                    LRoleDataMgr.m_book.bookAttr[attr.type]=attr.value
                end
               
                sucInfo.cardAttr[i] = attr
            end
            for i = LRoleDataMgr.m_book.curLevel + 1, sucInfo.booklevel do
                num = stream:ReadByte()
                local bookAttr = {}
                for j=1,num do
                    local attr = {}
                    attr.type = stream:ReadUShort()
                    attr.value = stream:ReadUInt()
                    bookAttr[j] = attr
                end
                sucInfo.levelAttr[i] = bookAttr
            end
            if sucInfo.booklevel>LRoleDataMgr.m_book.curLevel then
                LRoleDataMgr.m_book.curLevel=sucInfo.booklevel
                sucInfo.upgradeLevel=true
                print("升级图鉴====》")
               -- Utils:InitUI("HeroBook.BookActivateUI", AppDef.UIType.PopWindow, sucInfo)
            end
         
            if sucInfo.star == 1 then
                Utils:InitUI("HeroBook.HeroBookActivateUI", AppDef.UIType.PopWindow, sucInfo)
            else
                Utils:InitUI("HeroBook.HeroBookLevelEndUI", AppDef.UIType.PopWindow, sucInfo)
            end
            
            --更新数据
            if LRoleDataMgr.m_book.bookStar[heroId] == nil then
                LRoleDataMgr.m_book.bookStar[heroId] = {}
                LRoleDataMgr.m_book.bookStar[heroId].star = sucInfo.star
                LRoleDataMgr.m_book.bookStar[heroId].score = sucInfo.addScore
            else
                LRoleDataMgr.m_book.bookStar[heroId].star = sucInfo.star
                LRoleDataMgr.m_book.bookStar[heroId].score = LRoleDataMgr.m_book.bookStar[heroId].score + sucInfo.addScore
            end
            Utils:SendMsg(LUIKaPaiPetEvent.UpdateHeroBookUI)
            LuaNetSendMsg:QueryRedDot(RedDotDef.SID.ShenJiangTuJian)--神将图鉴
            
        end
    end
end

--英勇试炼（血战到底）
function LuaNetRecvdMsg.DealXueZhan(stream)
    local data = LActivityManager:GetXueZhanData()
    local op = stream:ReadByte()
    --print("LuaNetRecvdMsg.DealXueZhan",op)
    if op == 1 then --血战数据请求
        data.m_cnt = stream:ReadByte()  --剩余次数
        data.m_reviveCnt = stream:ReadByte() --复活次数
        data.m_state = stream:ReadByte()--1字节 当前状态 1 战斗 2 死亡 3 不复活 4全通状态 7扫荡buff待领取
        data.m_rewardState = stream:ReadByte() --奖励领取状态 0-未领取，1-已领取
        local chapterId = stream:ReadByte() --当前章节
        data.m_levelId = stream:ReadWord() --当前关
        data.m_sweepLevelId = stream:ReadWord()--2字节 可以扫荡关
        data.m_maxLevelId = stream:ReadWord() --今日最高关
        data.m_maxStar = stream:ReadWord()--历史最高星
        data.m_totalStar = stream:ReadWord() --当前总星
        data.m_maxLevelStar = stream:ReadWord() --今天最高星
        data.m_curStar = stream:ReadWord() -- 当前剩余星
        data.m_firstLevelId = stream:ReadWord() -- 当前最高首通关卡
        --data.m_firstState = stream:ReadByte() -- 首通关奖励状态 1 可以领取 2 已经领取 0 不能领取 
        data.m_enemyZhenId[1] = stream:ReadWord() --简单战斗id
        data.m_enemyZhenId[2] = stream:ReadWord() --普通战斗id
        data.m_enemyZhenId[3] = stream:ReadWord() --困难战斗id
        data.m_bufs = {}
        data.m_sweepInfo = {}
        data.m_sweepInfo.bufs = {}
        data.m_sweepInfo.sType = stream:ReadUInt()--扫荡设置
        data.m_sweepInfo.bufIdx = stream:ReadByte()--buff已选择Idx
        --print("DealXueZhan m_sweepInfo.sType,m_maxStar",data.m_sweepInfo.sType,data.m_maxStar)
        local num = stream:ReadByte()--可选buf数量
        local bufs = {}
        if data.m_state == 7 then
            bufs = data.m_sweepInfo.bufs
        else
            bufs = data.m_bufs
        end
        for i = 1,num do
            local value = {}
            value.star = stream:ReadByte() --价格
            value.attrType =  stream:ReadWord()
            value.attrVal =  stream:ReadUInt()
            table.insert(bufs,value)
        end
        local bufNum = stream:ReadByte()--当前buff属性
        data.m_attrs = {}
        for i=1,bufNum do
            local attr = {}
            attr.type =  stream:ReadWord()
            attr.val =  stream:ReadUInt()
            table.insert(data.m_attrs,attr)
        end
        data.m_giftBoxs = {}
        data.m_giftBoxs.level = stream:ReadWord() --关底关卡ID
        data.m_giftBoxs.fiveStar = stream:ReadByte()--五关星数
        data.m_giftBoxs.box = {}
        local boxNum = stream:ReadByte()--关底奖励数量
        for i=1,boxNum do
            local value = {}
            value.star = stream:ReadByte()
            value.state = stream:ReadByte()
            table.insert(data.m_giftBoxs.box,value)
        end
        data:UpdateData(chapterId)
        --print("op == 1,m_curStar,m_state",data.m_curStar,data.m_state)
        --dump(data.m_bufs)
        Utils:OpenXueZhanUI()
        --LuaNetSendMsg:QueryXueZhanBox(5)
    elseif op == 2 then--敌方阵容
        data.m_levelId = stream:ReadWord() --当前关卡ID
        if data.m_maxLevelId < data.m_levelId then
            data.m_maxLevelId = data.m_levelId
        end
        data.m_enemyZhenId[1] = stream:ReadWord() --简单战斗id
        data.m_enemyZhenId[2] = stream:ReadWord() --普通战斗id
        data.m_enemyZhenId[3] = stream:ReadWord() --困难战斗id
        print("GetXueZhanData:m_levelId",data.m_levelId)
        ------dump(data.m_enemyZhenId,"GetXueZhanData:m_enemyZhenId=>")
        local cnt = stream:ReadByte() --胜利条件
        for i=1,cnt do
            stream:ReadWord()-- 条件类型
            stream:ReadUInt()-- 条件值
        end
        data:UpdateData()
        Utils:InitUI("XueZhan.XueZhanChapterUI",AppDef.UIType.FirstClassLayer)

        if data.m_levelId%5 == 1 then
            local levelId = math.ceil(data.m_levelId/5)*5
            LuaNetSendMsg:QueryXueZhanBox(levelId)
        end

        if data.m_levelId%100 == 1 then
            data.m_attrs = {}
            LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIXueZhanEvent.RefreshChapterBuffUI)
            this:SendMsg(LGameMsg.m_netDealBaseMsg)
        end
        Utils:QueryXueCurRank()
    elseif op == 3 then--挑战返回
        local mode = stream:ReadByte()
        local suc = stream:ReadByte()
	----print("op ==3 suc",suc)
        if suc == 0 then
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
        end
    elseif op == 4 then --关底宝箱数据
        data.m_giftBoxs = {}
        data.m_giftBoxs.level = stream:ReadWord() --关底关卡ID
        data.m_giftBoxs.fiveStar = stream:ReadByte()--五关星数
        data.m_giftBoxs.box = {}
        local boxNum = stream:ReadByte()
        for i=1,boxNum do
            local value = {}
            value.star = stream:ReadByte()
            value.state = stream:ReadByte()
            table.insert(data.m_giftBoxs.box,value)
        end
    elseif op == 5 then--次日上线,开始按钮后发放关底奖励
        local num = stream:ReadByte()
        --print("op == 5 num",num)
        data.m_rewards = {}
        data.m_rewardNum = 0
        for i=1,num do
            data.m_rewards[i] = {}
            LuaNetRecvdMsg.ReadRewardData(data.m_rewards[i],stream)
        end
        --dump(data.m_rewards)
        if #data.m_rewards > 0 then
            Utils:OpenXueZhanAyerReward()
        end
    elseif op == 6 then--重置返回
        local suc = stream:ReadByte()
        ----print("XueZhanData op == 6 suc",suc)
        if suc == 0 then
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
            --关闭章节界面
            Utils:DeleteUI("XueZhan.XueZhanChapterUI")
            LuaNetSendMsg:QueryXueZhanInfo(1)
            return
        end
	    local cnt = stream:ReadByte()
        data.m_cnt = cnt
        data.m_state = 5
        data.m_totalStar = 0
        data.m_curStar = 0
        data.m_attrs = {}
        data.m_enemyZhenId = {0,0,0}
        --print("XueZhanData m_cnt",cnt)
        --关闭章节界面
        Utils:DeleteUI("XueZhan.XueZhanChapterUI")
        --打开主界面
        Utils:InitUI("XueZhan.XueZhanMainUI", AppDef.UIType.FirstClassLayer)
        ----print("LuaNetRecvdMsg.DealXueZhan op == 6",suc,cnt)
    elseif op == 7 then--复活返回
        local rType = stream:ReadByte()
        local suc = stream:ReadByte()
        ----print("op ==7 suc",suc)
        if suc == 0 then
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
            return
        end
        data.m_reviveCnt = stream:ReadByte()
        data.m_state = stream:ReadByte()
        ----print("XueZhanData m_reviveCnt,m_state",data.m_reviveCnt,data.m_state)
        if data.m_state == 3 then
            Utils:InitUI("XueZhan.XueZhanEndUI",AppDef.UIType.PopWindow)
        end
    elseif op == 8 then --战斗结果推送
        local curStart = stream:ReadByte()--当前获得星
        ----print("op == 8 curStar",curStart)
        if curStart == 0 then
            if LRoleDataMgr.m_fightResultData == nil then
                LRoleDataMgr.m_fightResultData = {}
            end
            LRoleDataMgr.m_fightResultData.wanFaId = AppDef.EModuleID.EMID_KAPAI_WF_XZ
            data.m_state = stream:ReadByte()
            ----print("XueZhanData m_state",data.m_state)
            return
        end
        data.m_maxStar = stream:ReadWord()--历史最高星
        data.m_totalStar = stream:ReadWord() -- 总星
        data.m_curStar = stream:ReadWord() -- 当前剩余
        data.m_maxLevelStar = stream:ReadWord() --今天最高星
        data.m_state = stream:ReadByte() -- 状态2-死亡，4-结束
        data.m_firstLevelId = stream:ReadWord() -- 首通奖励关卡
        data.m_giftBoxs.fiveStar = stream:ReadByte()--当前关底星星数
        data.m_giftBoxs.box = {}
        local num = stream:ReadByte() -- 关底奖励数量
        for i=1,num do
            local value = {}
            value.star = stream:ReadByte()
            value.state = stream:ReadByte()
            table.insert(data.m_giftBoxs.box,value)
        end
        local bufNum = stream:ReadByte() -- 可选buff数量
        data.m_bufs = {}
        for i=1,bufNum do
            local value = {}
            value.star = stream:ReadByte() --价格
            value.attrType =  stream:ReadWord()
            value.attrVal =  stream:ReadUInt()
            table.insert(data.m_bufs,value)
        end
        local num1 = stream:ReadByte()
        for i=1,num1 do
            local value = LuaNetRecvdMsg.ReadCommonReward(stream)
            table.insert(data.m_items1,value)
        end
        local num2 = stream:ReadByte()
        for i=1,num2 do
            local value = LuaNetRecvdMsg.ReadCommonReward(stream)
            table.insert(data.m_items2,value)
        end
        ----print("num2",num2,data.m_maxStar)
        ------dump(data,"LActivityManager:GetXueZhanData=>")
        local figthData = {}
        figthData.wanFaId = AppDef.EModuleID.EMID_KAPAI_WF_XZ
        LuaNetRecvdMsg.ReadBattleResult(stream,figthData)

        local function fun()
            Utils:OpenXueZhanReward()
        end
        Utils:scheduleOnce(fun, 0.5)  
    elseif op == 9 then--扫荡
        data.m_sweepInfo.rewards = {}
        data:SweepUpdate()
        local num = stream:ReadByte()
        ----print("op ==9 num",num)
        for i=1,num do
            local value = {}
            value.levelId = stream:ReadWord() -- 奖励关卡
            --if value.levelId > 0 then
            value.itemList = {}
            local itemNum = stream:ReadByte()
            for k=1,itemNum do
                local item = LuaNetRecvdMsg.ReadCommonReward(stream)
                table.insert(value.itemList,item)
            end
            if itemNum > 0 then
                table.insert(data.m_sweepInfo.rewards,value)
            end
            --end
        end 
        ------dump(data.m_sweepInfo)
        if #data.m_sweepInfo.rewards == 0 then
            return
        end
        local saodang = {}
        saodang.showType = 1
        saodang.result = data.m_sweepInfo.rewards
        Utils:InitUI("FuBenMap.SaoDangResultUI", AppDef.UIType.PopWindow,saodang )
    elseif op == 10 then--buff选择返回
        local idx = stream:ReadByte()
        local suc = stream:ReadByte()
        ----print("op == 10",idx,suc)
        if suc == 0 then
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
            return
        end
        data:SelectBuff(idx)
        Utils:OpenXueZhanReward()
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIXueZhanEvent.RefreshChapterBuffUI)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
    elseif op == 11 then--扫荡设置
        local sType = stream:ReadUInt()
        local suc = stream:ReadByte()
        if suc == 0 then
            local msg = stream:ReadString()
            Utils:ShowScrollTips(msg)
            return
        end
        data.m_sweepInfo.sType = sType
        ----print("op == 11",sType)
        --LUserConfigMgr:SetXueZhanSType(sType)
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIXueZhanEvent.RefreshChapterSweepUI)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
    elseif op == 12 then--扫荡buff选择后推送
        data.m_totalStar = stream:ReadWord() -- 总星
        data.m_curStar = stream:ReadWord() -- 当前剩余
        data.m_sweepInfo.bufIdx = stream:ReadByte()
        local bufNum = stream:ReadByte()
        data.m_attrs = {}
        for i=1,bufNum do
            local attr = {}
            attr.type =  stream:ReadWord()
            attr.val =  stream:ReadUInt()
            table.insert(data.m_attrs,attr)
        end
        ------dump(data.m_attrs)
        data.m_sweepInfo.bufs = {}
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIXueZhanEvent.RefreshChapterBuffUI)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
    elseif op == 13 then--扫荡buff选择数据推送(打开buff选择界面)
        data.m_sweepInfo.bufs = {}
        data.m_sweepInfo.bufIdx = stream:ReadByte() --当前选到第几个buff
        local bufNum = stream:ReadByte() -- 可选buff数量
        --print("op==13 bufIdx,m_curStar,m_totalStar",data.m_sweepInfo.bufIdx,data.m_curStar,data.m_totalStar)
        for i=1,bufNum do
            local value = {}
            value.star = stream:ReadByte() --价格
            value.attrType =  stream:ReadWord()
            value.attrVal =  stream:ReadUInt()
            table.insert(data.m_sweepInfo.bufs,value)
        end
        ------dump(data.m_sweepInfo)
        Utils:OpenXueZhanSweepBuffUI()
    -- elseif op == 14 then --扫荡选择buff返回
    --     local idx = stream:ReadByte()
    --     local suc = stream:ReadByte()
    --     if suc == 0 then
    --         local msg = stream:ReadString()
    --         Utils:ShowScrollTips(msg)
    --         return
    --     end
    --     data.m_sweepInfo.bufs = {}
    elseif op == 15 then
        if LRoleDataMgr.m_activityInfo == nil then
            LRoleDataMgr.m_activityInfo = {}
        end
        local info = LRoleDataMgr.m_activityInfo
        info.arenaMaxRank = stream:ReadUInt()--竞技场最高排名
        info.xzMaxNum = stream:ReadWord()--血战通关数
        info.xzHardModelMaxNum = stream:ReadWord()--血战连续最高难度通关数
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIXueZhanEvent.GetActivityInfo)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
    elseif op == 16 then
        data.m_rewardState = stream:ReadByte()-- 状态，0-未领取，1-领取
        data.m_items3 = {}
        LuaNetRecvdMsg.ReadRewardData(data.m_items3, stream)
        ----print("op==16",data.m_rewardState)
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIXueZhanEvent.RefreshBtnState)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
        if #data.m_items3 > 0 then
            Utils:OpenRewardBox(GUITips.RSI_XUEZHAN_TIP21,data.m_items3,false,"")
            data.m_items3 = {}
        end
        if data.m_rewardState == 1 then
            Utils:SetRedDotState(RedDotDef.ID.XueZhanDraw,false)
        end
    elseif op == 17 then
        data.m_forecastRankId = stream:ReadUInt()
        data:UpdateData()
        --print("data.m_forecastRankId",data.m_forecastRankId)
        LGameMsg.m_netDealBaseMsg:ChangeEventId(LUIXueZhanEvent.RefreshBtnState)
        this:SendMsg(LGameMsg.m_netDealBaseMsg)
    end
end

LuaNetRecvdMsg.Init()
