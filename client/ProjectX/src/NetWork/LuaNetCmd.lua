--[[
@通信命令，一部分在c#
@作者：陈伟
@创建日期：2016-04-22
]]
LuaNetCmd = 
{
    MSG_ACC_LOGIN = 1501,                
    MSG_ACC_REG = 1502,
    MSG_ACC_ANNOUNCEMENT = 1505,--维护公告
    MSG_ACC_GAME_ROLES = 1506,  --获取服务器列表上的角色信息

    MSG_ACC_LINEUP = 1600,	--排队服务器 
    
    ----------------------游戏相关协议号-----------------------------
    MSG_LOGIN = 1001,
    MSG_CHECKNAME = 1002,--随机名字
    MSG_CREATE_HERO = 1003,--创建角色
    MSG_CHOOSE_HERO = 1004,--选择角色进入游戏
    MSG_QUERY_EQUIP = 7,--装备(去除)
    MSG_QUERY_PACK = 8,--背包
    MSG_OPEN_INTERACT = 12,--打开npc交互
    MSG_NPC_CHAT = 13,--npc交互
    MSG_UPDATE_PACKAGE = 15,--更新背包
    MSG_REQ_ITEM = 16,	--请求物品详细信息
    MSG_EQUIP_ITEM = 17,--穿脱主角装备（去除）
    MSG_UPDATE_CHAR = 18,--主角信息更新
    MSG_SKIP_PLOT = 20,--跳过剧情
    MSG_ENTER_BATTLE = 21,   --收到进入战斗协议
    MSG_BATTLE = 22,   --具体的战斗协议
    MSG_BATTLE_OVER = 23,   --收到结束战斗包
    MSG_PET_INFO = 24, --神将
    MSG_PET_DO = 25,--神将操作
    MSG_CHAT = 26,		--聊天协议
    
    MSG_FRIENDS = 27,   --好友相关
    MSG_UPDATE_SKILL = 28,--更新技能
    MSG_TEAM_OPERATION = 29,--队伍操作
    MSG_SERVER_SYSTEM_TIP = 31, --服务器发来的错误提示
    MSG_PK = 32,  --PK
    MSG_MATCH = 33,   --切磋
    MSG_MISSION_LIST = 37,   --任务列表
    MSG_JUMP_BATTLE = 38,
    MSG_MISSION_CHANGED = 39,   --任务更新

    -- MSG_QUERY_FRIENDS                = 42,   --查询好友
    -- MSG_ADD_HOT                      = 43,   --添加好友
    -- MSG_DEL_HOT                      = 44,   --删除好友
    -- MSG_HOT_ONLINE                   = 45,   --好友上线通知
    MSG_PAY_PRICE_LIST               = 46,   --充值档位请求
    NPC_DIA_CLICK          =   47, --点击对话框推进下一步
    MSG_FORMATION = 48, --  阵容
    MSG_TASK_LIST = 49, --  已完成任务列表
    MSG_FIGHT_SPEED = 50, --  战斗加速
    MSG_TASK_QUERY_PET = 51,   --查询宠物
    MSG_QUERY_RESRECOVERY = 52, --资源找回
    MSG_ACT_FENGSHEN = 53, --封神战场
    MSG_BANGPAI = 54,--帮派
    MSG_BANGPAIWAR = 56,--帮派战
    MSG_UPDATE_FIGHT_HP = 57,--帮派战
    BANGPAI = 61,--帮派
    MSG_SYS_MSG = 62,  --系统信息（滚屏）
    MSG_SYS_LEITAISAI = 63,	--个人擂台赛战斗信息公告
    MSG_BP_Fuben = 64,	--帮派副本
    -- MSG_PRO_EQUIP_FORGE = 65,	--装备锻造
    MSG_RED_POINT = 65,--小红点
    MSG_PRO_EQUIP_SHENGHUA = 67, --淬炼洗炼(废除)
    MSG_PET_UPDATE = 70,--宠物更新协议
    --MSG_SKILL_DESC = 68,--技能描述--不要了
    MSG_UPDATE_EQUIP = 77,--更新装备
    MSG_MY_BANG = 80,--我的帮派信息
    MSG_PRO_CHARGE = 84,--充值
    MSG_CLIENT_ACCOUNT = 88, --请求游戏内公告
    MSG_MISSION_NOGET_LIST = 89,	--未接任务
    --MSG_PRO_SCENE_POS = 90, -- 脱离卡死,老版本直接用条场景命令，新版本沿用，所以这条命令失效
    MSG_ITEM_DEF = 101,  --请求dat之外的物品信息
    MSG_HEART = 102,  --心跳包
    MSG_CHAT_BPSYS = 103,  --帮派信息
    MSG_LIST_TITLE = 105,        --勋章
    MSG_USE_TITLE                    = 106,  --使用称号
    MSG_FACTION_ZONE  = 110,  --帮派领地
    -- MSG_LIST_BLACK                   = 121,         --黑名单
    -- MSG_ADD_BLACK                    = 122,         --添加黑名单
    -- MSG_DEL_BLACK             = 123,          --解除黑名单
    MSG_CLIENT_XINSHI = 128, -- 邮件
    MSG_CLIENT_LEARN_SKILL = 130, -- 技能升级
    MSG_SAVE_VAL = 145, --存储设置信息
    MSG_GET_SAVE_VAL = 146, --获取设置信息
    MSG_AUTOPATH_POS = 153,  --服务器发送寻路信息
    MSG_XIUXIANLILIAN = 160, --修仙历练
    MSG_ARENA = 161,  --竞技场
    MSG_CHIBANG_DO = 180,   --翅膀羽翼相关
    MSG_TASK_INFO = 182,   --请求任务信息
    MSG_HORSE_DO = 185,  --坐骑相关
    MGG_JINGJIE_DO=186,--境界相关
    MSG_GOTO_NEXTLOCAL = 189,  --进入下一个地图
    MSG_QUIRY_COPYINFO = 190,  --请求副本列表以及奖励
    MSG_DEAL_GUIDE_INDO = 191,  --处理引导信息
    MSG_HE_CHENG_OPTION = 192,	--合成
    MSG_CLIENT_RANKLIST = 193,   -- 排行榜
    MSG_WORLDMAP_SID = 195,  --世界地图切换场景
    MSG_EVERY_QUETION = 198, -- 每日答题协议
    MSG_CLIENT_HUODONG_OPTION = 199, -- 活动，百花仙子,昆仑山,签到
    MSG_OPEN_PACKAGE_OPTION = 200,	--背包格开启
    MSG_PLAYER_DETAIL = 201, -- 请求他人的人物信息
    MSG_CAN_BATTLE = 204,  --可以遇敌
    MSG_SYS_TIME = 206,  --系统时间
    MSG_DAILY_ACTIVITY = 209,  --每日活动(玩法)
    MSG_BATTLE_OVER_INFO = 210,  --战斗结束信息显示
    MSG_CLIENT_SKILLPART_INFO = 212, -- 
    MSG_ADVANCEPATH_INFO = 213, --多人闯关
    MSG_SERVER_TOWER_SHOWBAZHU = 214, --通天塔
    MSG_IOS_GET_ORDERID = 216,    --ios 获得order_id
    MSG_FISHING_INFO = 217,--钓鱼
    --MSG_CLIENT_OUTLINEEXP = 219,   -- 离线经验
    MSG_VIP_INFO = 220, --vip信息
    MSG_CLIENT_MARKET = 221, --商城
    MSG_KAIFUHUODONG = 222, --开服活动
    MSG_STAGE_GOAL = 223, --近期目标
    MSG_GET_PET = 224, --宠物抽取
    MSG_DAILYBOSSTASK = 225, --每日Boss
    MSG_LEVELUP_SERVER = 226,--升级信息解析
    MSG_LEITAISAI = 228, --个人擂台
    MSG_CONVOY = 229,  --护送任务
    MSG_GUESSFIST = 232,  --猜拳
    MSG_OVER_DAY = 234,  --跨天协议
    MSG_PET_ANI_NOTIFY = 236,  --宠物动画推送通知
    MSG_WORSHIP_INFO = 239, --膜拜界面信息
    MSG_HOOK_STATE = 240,  --服务器控制任务挂机状态
    MSG_PET_COPY = 243, --宠物副本
    MSG_CANGBAOTU = 244, --藏宝图
    MSG_SHILIAN = 245, --英勇试炼
    MSG_FLYFARY = 246, --飞仙战场
    -- MSG_SERCHPLAYER= 248,          --查找玩家

    
    MSG_WORLDLEVEL= 249,          --世界等级
    MSG_TIPSJUMP = 250,	--元宝 金币不足跳转
    MSG_LUNDAO = 253, --神界论道
    MSG_ACROSSSER = 254,               --跨服喊话
    MSG_WEIWODUXIAN = 255, --唯我独仙
    MSG_MULTISERVER_BOSS = 256,--跨服boss 神界秘境（六圣现世）
    MSG_UPDATE_CST = 301, --更新客户端常量数据
    MSG_COUPLE = 302,  --结婚功能
    MSG_JINGJIE = 306, --境界
    MSG_SHENQI = 307, --神器
    MSG_CLIENT_XIANHUA = 314 ,   -- 魅力排行榜
    MSG_XIANHUA_EFFECT = 315 ,   --鲜花特效
    MSG_AUDIO_PLAY = 318,  --播放音效
    MGS_PETEQUIP_BAG = 319,--神将装备背包
    MSG_QUERY_FUBENMAP = 320,  --副本大地图
    MSG_QUERY_TILI = 321,  --体力
    MSG_HERO_BOOK = 322,  --图鉴
    MSG_XUEZHAN = 323,--英勇试炼
    MSG_SAVE_STR_VAL = 331, --存储设置字符串信息
    MSG_GET_MISSION_AWARD = 332,   --前端领取任务奖励
    MSG_KUAFU_LABA = 334, --跨服喇叭
    MSG_YOULI = 335,--游历三界
    --MSG_JIJIN = 336,--基金
    MSG_CROSS_SERVER = 400, --跨服

    MSG_Test = 4000,--测试
 --    REGUSER          =1001,
 --    LOGIN            = 1002,
 --    SRVLIST          = 1003,
 --    SERVERROLEINFO   = 1006,--向服务器查询是否有角色信息

 --    GAMEKEY = 2001,--第一次登录游戏服务器收到的key
 --    GAMEENTER = 2,--进入游戏
 --    ROLECREATE = 3,  --创建角色
	-- --PLAYER_MOVE = 8,
 --    JUMPSCENE = 9,   --场景跳转
	-- SHUXING_POINT = 10,
 --    XIANGXING_POINT = 11,
 --    UPDATE_ROLE_INFO = 12,
 --    UPDATE_PACK_INFO = 13,
 --    UPDATE_WAREHOUSE_INFO = 14, 
 --    UPDATE_EQUIPMENT_INFO = 15, --装备系统
 --    UPDATE_FASHION_INFO = 16, --换装系统
 --    Init_Role_Skill = 17, --登入的时候获取技能
 --    SKILL = 58,--技能
 --    PRO_MDGAME_HorseSet = 18,--坐骑设置
 --    PRO_MDGAME_HorseOperate = 19,--坐骑操作

 --    PRO_CHAT_MESSAGE = 26,--聊天消息

 --    PRO_PARTNER_INFO = 27,--接受伙伴数据
 --    PRO_PARTNER_UPDATE = 28,--更新伙伴数据

 --    PRO_MDGAME_EQUIPXILIAN         =30, -- 洗练
 --    PRO_MDGAME_EQUIPQIANGHUA       =31, -- 强化
 --    PRO_MDGAME_XIANGQIAN           =32, -- 镶嵌
 --    PRO_MDGAME_SHENGJI             =33, -- 升级


 --    PET_INFO = 24,--宠物相关信息
 --    PET_INFOUPDATE = 25,--宠物更新相关信息
 --    CHAT = 26,--聊天
 --    Partner_Info = 27,--伙伴协议
 --    TASK_JINDU = 36,--获取任务进度
 --    TASK_LIST                  =37, ---获取自己的任务列表
 --    TASK_UPDATE = 39,--更新一个任务
 --    TASK_REQ_INFO       =40, ---获取任务的详细信息，并添加任务
 --   -- TASK_TEST                =41, -- 用来测试任务系统的一个命令字，后面要删掉
 --    NPC_OPEN               =44,  -- 打开NPC
 --    NPC_RECV_DIA           =46, --收到一条服务器来的对话消息
 --    NPC_DIA_CLICK          =47, --点击对话框推进下一步
 --    TEAM = 48,--组队
 --    LEAVE_LOOKBATTLE = 51,--离开组队
 --    --NPC_SHOP = 52,--npc商店
 --    NPC_SHOP  =53,--npc商店
 --    ACTIVITY = 54,--活动
 --    HUOBANSHILIAN_ACTIVITY = 55,--伙伴试炼
 --    FRIENDS = 56,--好友
 --    EMAIL= 59,--邮件
 --    PK = 60,--pK处理
    
 --    INFO_NOTICE = 62,--信息提示
 --    OPEN_NPC = 63,--打开npc界面
 --    ZHUANGSHENG = 64,--人物转生
 --    BAOTULINGQU = 65,--领取宝箱
 --    EQUIP_SHENQI = 66,--神器相关协议
 --    TongTianTa= 67,--通天塔 - 答题
 --    MALL = 68,--商城协议
 --    BANGZHAN = 70,--帮战相关协议

 --    EXITSCENE = 72,--退出通天塔 帮战等的场景
 --    JINGJICHANG = 73,--竞技场相关协议
 --    PRO_BAZAAR=74,--集市功能协议

 --    JIEBAI = 75,--结拜相关协议
 --    XUANCHUAN = 76,--喊话宣传
 --    GUIDE = 77, --引导协议
 --    PlayerOperation = 78, --对其他玩家操作界面
 --    SHUADAO = 79,--刷道
 --    LIXIANXIAOXI = 80,--离线消息
 --    LifeSKILL = 81,--生活技能
}