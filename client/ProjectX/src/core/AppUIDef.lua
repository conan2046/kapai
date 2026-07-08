--[[
UI相关的宏定义和常亮方法
]]
AppDef.Director = cc.Director:getInstance()
AppDef.frameSize = AppDef.Director:getVisibleSize()
AppDef.spriteFrameCache = cc.SpriteFrameCache:getInstance()
AppDef.textureCache = cc.Director:getInstance():getTextureCache()


AppDef.CurScene = nil
-----------字体定义
AppDef.FNT_NAME = "MicrosoftArial.ttf"
AppDef.FNT_NAMEC = "MicrosoftArial.ttf"
AppDef.FNT_SIZE = 15
AppDef.FNT_SIZE_M = 24
AppDef.FNT_SIZE_L = 20
AppDef.UIFONTSIZELB  =20                --文本字号
AppDef.UIFONTSTROKESIZE  = 0.5        --阴影强度
AppDef.UIFONTSIZETITLE  = 24        	--标题字号
AppDef.UIFONTSIZETASKNAME  = 22        --任务名字字号
AppDef.UIFONTSIZELOGIN_M  = 22        --登录22字号

AppDef.Max_TiLi  = 1000        --最大体力
AppDef.Pet.MaxStar = 7--宠物最大星级
AppDef.Pet.MaxSubStar = 10--宠物最大子星级
AppDef.Pet_MaxBreakLv = 15 --最大突破等级

AppDef.MAX_MSG_NUM = 30 --底部走马灯最大消息数量

AppDef.XIANHUA_TAG = 5569 -- 鲜花tag

AppDef.GameZOrder = 
{
	GameLogicNode = 0,--逻辑层，处理update等消息
	--MapLayer = 1,--地图层,暂时用做objectPool层
    PoolLayer = 1,--地图层,暂时用做objectPool层
	BattleLayer = 2,--战斗层
	UILayer = 3,--UI层
}
--------------UI相关------------------------------------------
AppDef.UIType = {
	UnderUI = 0, --UI层下
	Normal = 1,--普通UI
	Battle = 2,--战斗
    Chat = 3,  --聊天界面
    SpecialLayer = 4,--自定义一级弹框
	FirstClassLayer = 5,--一级弹窗(全屏)
    PopFirstClassLayer = 6,--一级弹窗(弹窗)
	SecondClassLayer = 7,--二级弹窗
	ThirdClassLayer = 8,--三级弹窗
	PopWindow = 9,
	Plot = 10,
	MsgBox = 11,
    ScrollTips = 12,
	WaitLoading = 13,
	Guide = 14
}
AppDef.UITab  = {}
AppDef.UITab.Role = 
{
	Attr = 1, --人物属性
	Bag = 2, --人物背包
	Compound = 3,--人物合成
}

AppDef.UITab.Team = {
    Member = 1,    --我的队伍
    Lineup = 2,--队伍阵容
    Quick = 3,     --快速组队
}

AppDef.UITab.TeamInviteTab = {
    NearHero = 1,    --附近玩家
    Friends = 2,--邀请好友
    Faction = 3,     --帮派成员
}

------------------------聊天相关------------------------------------
AppDef.Chat_Msg_Type = 
{
    TAG_MSG_LABEL   = 850,  --消息显示label
	MTG_VOC_WORLD	= 900,	--世界语音
	MTG_VOC_BANGPAI = 902,	--帮派语音
	MTG_VOC_TEAM	= 903,	--队伍语音
	MTG_VOC_LABA	= 904,	--小喇叭语音
	TAG_SCROLL_CELL = 998,	--cell
	TAG_SCROLL_VIEW = 999,	--消息view
    CCT_WORLD_MAXNUM = 30, --世界频道最大人数
    CCT_CUR_MAXNUM = 20,    --当前频道最大人数
    CCT_BP_MAXNUM = 20,    --帮派频道最大人数
    CCT_TEAM_MAXNUM = 20,  --队伍频道最大人数
    CCT_SYS_MAXNUM = 20,  --系统频道最大人数
    CCT_NUM_DEFAULT = 30,  --综合频道最大人数
    CCT_NUM_VOICE = 20,    --最大语音播放数
    CCT_WORLD_CHANNEL_CD = 10,  --世界频道CD时间
    CCT_WORLD_CHANNEL_CD_1 = 20, --当玩家等级在30-34级之间，且VIP为0时，聊天时间间隔为20s
    CCT_WORLD_CHANNEL_CD_2 = 60, -- 当玩家等级大于等于35级时，且VIP为0时，聊天时间间隔为10s
    CCT_CUR_CHANNEL_CD = 5, --当前频道CD时间
    CCT_WORLD_CHANNEL_KUAFU_CD = 20, --跨服
    CCT_CUR_CHANNEL_All_MSG = 200, --聊天缓冲总条数
    CCT_CUR_CHANNEL_LASTMSG = 20,  --最近的聊天消息
    CCT_CHAT_RECHARGE_LIMITE = 30,   --累计充值30元才能聊天
}

AppDef.ChatChanelType =
        {
            CCT_COMMON      = 0,        -- 综合所有
            CCT_WORLD       = 1,		-- 世界
            CCT_NEAR        = 2,		-- 附近
            CCT_BATTLE      = 5,		-- 战斗
            CCT_PERSIONAL   = 7,	    -- 私聊
            CCT_FACTION     = 4,	    -- 帮派
            CCT_TEAM        = 3,		-- 队伍
            CCT_SYS         = 9,		-- 系统
            CCT_BPSYS       = 10,       --系统帮派
            CCT_KUAFU       = 11,       --跨服
            CCT_LABA        = 12,       --喇叭
            CCT_LEITAI      = 13,        -- 系统
            CCT_SPEC		= 200,		--特殊的，服务器不做数字检测，组队发消息的时候容易玩家id太长服务器会拦截掉
        }

AppDef.FriendType =
        {
            QINMIDU_CHOUREN = 1,           --仇人
		    QINMIDU_YANFAN = 2,            --厌烦
		    QINMIDU_CHUSHI = 3,            --初始
		    QINMIDU_QIANJIAO = 4,          --浅交
		    QINMIDU_MIYOU = 5,             --密友
		    QINMIDU_ZHIJIAO = 6,           --至交
        }

AppDef.SocialType =
        {
            RL_FRIENDS = 1,           --好友
		    RL_TANDSTU = 2,            --师徒
		    RL_COUPLE = 3,            --夫妻
        }

AppDef.medalChallengeType =
        {
            RL_MEDAL_NONE = 0,             --不能挑战
            RL_MEDAL_BATTLE = 1,           --竞技场
		    RL_MEDAL_TOWER = 2,            --通天塔
		    RL_MEDAL_VIP = 3,             --vip
        }

------------------------技能相关------------------------------------
AppDef.skill_Type =
{
        TAG_SKILL_BASE = 10000,
        TAG_SKILL_SGL = 10001,
        TAG_SKILL_MUL = 10002,
		TAG_SKILL_SPC = 10003,
		TAG_SKILL_AGL = 10004,
        TAG_SKILL_FLEE = 10009,
        TAG_HERO_ANGER_FULL_EFFECT = 11000,
		TAG_HERO_RUNAWAY = 100011,
}

CCNORMAL_RED     =   cc.c3b(255,0,0)	        --普通红
CCWHITE          =   cc.c3b(255,255,255)       --白色
CCGRAY           =   cc.c3b(100,100,100)       --灰色
CCGREEN          =   cc.c3b(00,255,14)            --绿色
CCBLUE           =   cc.c3b(00,195,212)        --蓝色
CCGREEN1         =   cc.c3b(204,255,119)	    --浅绿
CCPURPLE         =   cc.c3b(224,38,233)	    --紫色
CCYELLOW         =   cc.c3b(255,204,51)	    --黄色
CCORANGE         =   cc.c3b(255,90,0)	        --橙色
CCGOLD           =   cc.c3b(239,186,0)	        --金色
CCGRAY_WHITE     =   cc.c3b(248,232,207)    --灰白色


--新UI颜色
UICOLOR_WHITE_720  	= cc.c3b(255,255,255)	     --白色
UICOLOR_WHITE          = cc.c3b(255,255,255)	     --白色
UICOLOR_BLACK          = cc.c3b(0,0,0)                --黑色
UICOLOR_BLACK_New   = cc.c3b(30,53,72)	         --蓝黑  1e3548
UICOLOR_BROWN          = cc.c3b(0x70,0x3b,0x33)	--偏黑  4b5d79   新颜色，默认灰色
UICOLOR_BROWNL  	= UICOLOR_BROWN	 --为了协调，将UICOLOR_BROWNL  	= UICOLOR_BROWN，而偏黑的另一种颜色单独命名为UICOLOR_BROWNBLACK
UICOLOR_BROWNBLACK  = cc.c3b(45, 57,  69)	--暗紫  2d3945   新颜色，默认黑色
UICOLOR_RED	          = cc.c3b(255, 90, 39)	 --红色  ff5a27
UICOLOR_GREEN          = cc.c3b(47,181,0)	--绿色  2fb500   
UICOLOR_GREEN_MO  	= cc.c3b(0x55,0x6a,0x5d)	--墨绿
UICOLOR_GREEN_DEEP  = cc.c3b(66,156,134)       --深绿
UICOLOR_GREEN_LAN  	= cc.c3b(0x40,0x8f,0xa0)	--蓝绿
UICOLOR_BLUE_GREEN  = cc.c3b(0x40,0x8f,0xa0)	--蓝绿
UICOLOR_YELLOW  	= cc.c3b(0xce,0xaa,0x00)	--黄色  dcab00	cc.c3b(220,171,0)
UICOLOR_GOLD          = cc.c3b(255, 218, 14)	 --金色 ffda0e
UICOLOR_YELLOW_PALE = cc.c3b(0xf9,0xea,0xd5)	--浅黄色  F9EAD5	
UICOLOR_BLUE_DEEP  	= cc.c3b(44,52,82)        	--深蓝色  2c3452	
UICOLOR_BLUE          = cc.c3b(1, 127, 255)	--蓝色  017fff
UICOLOR_BLUE_PALE  	= cc.c3b(154,255,255)	    --浅蓝色  9affff
UICOLOR_ORANGE	  	= cc.c3b(255, 90, 0)	--橙色  ff5a00
UICOLOR_GRAY          = cc.c3b(119,118,118)	--灰色  777676	
UICOLOR_GRAY2       = cc.c3b(176,176,176)	--淡灰色2  b0b0b0
UICOLOR_PINK          = cc.c3b(255, 124, 153)	--粉色  ff7c99
UICOLOR_PURPLE  	= cc.c3b(204, 49, 255)	--紫色  cc31ff
UICOLOR_GRAY_WHITE  = cc.c3b(248,232,207)        --灰白   f8e8cf
UICOLOR_GRAYM          = cc.c3b(0x91,0x72,0x51)	--地图灰色  917251
UICOLOR_HISTORY     = cc.c3b(1, 127, 255)	--历史字（蓝色）  017fff
UICOLOR_GrayBlue 	= cc.c3b(150,172,211)   --灰蓝

UICOLOR_WORD          = cc.c3b(0x15,0x13,0x3d)

UICOLOR_NAME        = cc.c3b(99, 232, 91)  --mini聊天名字绿
UICOLOR_BROWN = cc.c3b(104,90,69)           --棕色 

--新品质颜色
UICOLOR_WHITE_PZ          = cc.c3b(0x73,0x73,0x73)        --        白——无品质、灰色
UICOLOR_GREEN_PZ          = UICOLOR_GREEN        --        	绿色
UICOLOR_BLUE_PZ          = UICOLOR_BLUE  --        蓝色
UICOLOR_PURPLE_PZ          = UICOLOR_PURPLE  --        紫色
UICOLOR_ORANGE_PZ          = UICOLOR_ORANGE  --        橙色
UICOLOR_GOLD_PZ          = UICOLOR_GOLD  --        金
UICOLOR_PINK_PZ          = UICOLOR_PINK  --        粉
UICOLOR_RED_PZ          = UICOLOR_RED  --        红

--描边专用字色
UICOLOR_GRAY_STROKE        	= cc.c3b(0xb0,0xb0,0xb0)	--灰色  b0b0b0	
UICOLOR_GREEN_STROKE        = UICOLOR_GREEN_PZ	    --绿色  29f700	
UICOLOR_BLUE_STROKE        	= UICOLOR_BLUE_PZ	    --蓝色  00d8ff	
UICOLOR_PURPLE_STROKE        = UICOLOR_PURPLE_PZ	--紫色  b97aff
UICOLOR_ORANGE_STROKE        = UICOLOR_ORANGE_PZ	--橙色  ffc556	
UICOLOR_YELLOW_STROKE        = UICOLOR_GOLD_PZ	--黄色
UICOLOR_RED_STROKE        	= UICOLOR_RED_PZ	--红色
UICOLOR_STROKE                = cc.c3b(0x39,0x13,0x06)	--描边色
UICOLOR_CYAN                = cc.c3b(28,184,255)      --青色


--新tips颜色
UICOLOR_WHITE_TIPS  	= cc.c3b(239,239,239)	    --白色  ——常用
UICOLOR_ORANGE_TIPS  	= cc.c3b(255,90,0)	        --橙色 ff5a00——题目和突出
UICOLOR_YELLOW_TIPS  	= cc.c3b(242,217,9)	        --黄色 f2d909——名称和提示
UICOLOR_GREEN_TIPS  	= cc.c3b(11,229,0)	        --绿色 0be500——加量数字
UICOLOR_PURPLE_TIPS     = cc.c3b(187,137,255)       --紫色 bb89ff
UICOLOR_PINK_TIPS       = cc.c3b(251,152,255)       --粉色 fb98ff
UICOLOR_RED_TIPS          = cc.c3b(255,54,54)	        --红色 ff3636——减量数字
UICOLOR_BLUE_TIPS          = cc.c3b(29,178,255)	    --蓝色 1db2ff——非加量数字
UICOLOR_BLUE_DEEP_TIPS  = cc.c3b(0x14,0x84,0xbe)  --        深蓝——类别
UICOLOR_GRAY_TIPS          = cc.c3b(0x87,0x93,0x9a)  --        灰色——材料
UICOLOR_COMMON_TIPS     = cc.c3b(243,229,187)       --普通 f3e5bb

--新tips品质
UICOLOR_WHITE_TIPSPZ  	= cc.c3b(244,244,244)  --        白——无品质、深蓝
UICOLOR_GREEN_TIPSPZ  	= cc.c3b(14,255,37)  --        绿
UICOLOR_BLUE_TIPSPZ  	= cc.c3b(29,199,255)  --        蓝
UICOLOR_PURPLE_TIPSPZ  	= cc.c3b(248,63,255)  --        紫
UICOLOR_ORANGE_TIPSPZ  	= cc.c3b(255,90,0)  --        橙
UICOLOR_GOLD_TIPSPZ  	= cc.c3b(255,247,16)  --        金
UICOLOR_PINK_TIPSPZ  	= cc.c3b(255,98,165)  --        粉
UICOLOR_RED_TIPSPZ  	= cc.c3b(255,8,8)  --        红 
UICOLOR_RED2_TIPSPZ  	= cc.c3b(255,94,0)  --        红橙
UICOLOR_RED3_TIPSPZ  	= cc.c3b(255,39,156)  --	玫瑰红 


--主界面
UICOLOR_GREEN_TASK        =	cc.c3b(0x28,0xea,0x1c)	    --绿色  29f700	
UICOLOR_BLUE_TASK        =	cc.c3b(0x60,0xb6,0xff)	    --蓝色  00d8ff	
UICOLOR_PURPLE_TASK        =	cc.c3b(0xc4,0x78,0xf9)	--紫色  b97aff
UICOLOR_ORANGE_TASK        =	cc.c3b(0xea,0xc7,0x8d)	--橙色  ffc556	
UICOLOR_YELLOW_TASK        =	cc.c3b(0xea,0xe8,0x01)
UICOLOR_CONTENT_TASK	=	cc.c3b(0xf5,0xf5,0xe9)	--白色cc.c3b(0xe7,0xe3,0xd3)
UICOLOR_WHITE_TASK        =	UICOLOR_CONTENT_TASK
CL_TASK_BLUE	=	cc.c3b(0x60,0xb6,0xff)	    --任务追踪蓝   cc.c3b(0x80,0xb5,0xff)
CL_TASK_YELLOW	=    cc.c3b(0xea,0xe8,0x01)            --任务追踪黄色
CL_TASK_GREEN	=    cc.c3b(0x28,0xea,0x1c)        	--任务追踪绿色
CL_TASK_WHITE	=    cc.c3b(0xe7,0xe3,0xd3)	    --任务追踪白色
CL_TASK_PURPLE	=        cc.c3b(0xe4,0x7a,0xff)	--紫色 (0xc4,0x78,0xf9)  ,e47aff
CL_TASK_ORANGE	=        cc.c3b(0xea,0xc7,0x8d)	--橙色  

--英雄榜颜色
UI_RANK_RED = CCNORMAL_RED
UI_RANK_BLUE = cc.c3b(0x1e,0x90,0xff)
UI_RANK_GREEN = cc.c3b(0,0x80,0)
UI_RANK_NORMAL = cc.c3b(0x6e,0x38,0x30)

-------------------------------------新UI颜色表-----------------------------------

AppDef.FontSize = 
{
    Normal = 24,
}

AppDef.UIColor = 
{
    --界面专用字色
    WHITE = cc.c3b(255,255,255), --白色
    BLACK = cc.c3b(0,0,0), --黑色
    YELLOW = cc.c3b(255,255,0), --黄色
    BLUE = cc.c3b(30,144,255),--蓝色
    GREEN = cc.c3b(0,128,0),--绿色
    PURPLE = cc.c3b(128,0,128),--紫色
    ORANGE = cc.c3b(255,180,0),--橙色
    RED = cc.c3b(255,0,0),--红色 
    PINK = cc.c3b(255, 124, 153),--粉色
    BROWN = cc.c3b(110,56,48),--褐色
    GOLD = cc.c3b(255, 255, 0),--金色
    Quest_Color = cc.c3b(121,69,65),--NPC对话文字颜色

    
    
    --任务追踪栏(通用半透底)
    CL_TASK_BLUE    =   cc.c3b(100,179,228),     --任务追踪蓝   cc.c3b(0x80,0xb5,0xff)
    CL_TASK_YELLOW  =    cc.c3b(255,255,0),            --任务追踪黄色
    CL_TASK_GREEN   =    cc.c3b(0,255,0),          --任务追踪绿色
    CL_TASK_WHITE   =    cc.c3b(255,255,255),        --任务追踪白色
    CL_TASK_PURPLE  =        cc.c3b(181,122,209),    --紫色 (0xc4,0x78,0xf9)  ,e47aff
    CL_TASK_ORANGE  =        cc.c3b(255,180,0),  --橙色 
    CL_TASK_RED  =        cc.c3b(255,0,0),  --红色 
    
    --[[
        --英雄榜颜色
        UI_RANK_RED = cc.c3b(255,0,0)
        UI_RANK_BLUE = cc.c3b(30,144,255)
        UI_RANK_GREEN = cc.c3b(0,128,0)
        UI_RANK_NORMAL = cc.c3b(110,56,48)   --通用

        


        --字描边色
        UICOLOR_GRAY_STROKE        	= cc.c3b(0xb0,0xb0,0xb0)	--灰色  b0b0b0	
        UICOLOR_GREEN_STROKE        = cc.c3b(93,171,144)	    --绿色  008000	
        UICOLOR_BLUE_STROKE        	= cc.c3b(30,144,255)	    --蓝色  1e90ff	
        UICOLOR_PURPLE_STROKE        = cc.c3b(128,0,128)	--紫色  800080
        UICOLOR_ORANGE_STROKE        = cc.c3b(255,180,0)	--橙色  ffB400	
        UICOLOR_YELLOW_STROKE        = cc.c3b(255,255,0)	--黄色
        UICOLOR_RED_STROKE        	= cc.c3b(255,0,0)	--红色
        UICOLOR_CYAN_STROKE          = cc.c3b(28,184,255)      --青色
		UICOLOR_BLACK_STROKE        = cc.c3b(0,0,0), --黑色  6e3830
		UICOLOR_BROWN_STROKE        	= cc.c3b(167,101,43)	--褐色

        --主界面
        UICOLOR_GREEN_TASK        =	cc.c3b(0x28,0xea,0x1c)	    --绿色  29f700	
        UICOLOR_BLUE_TASK        =	cc.c3b(0x60,0xb6,0xff)	    --蓝色  00d8ff	
        UICOLOR_PURPLE_TASK        =	cc.c3b(0xc4,0x78,0xf9)	--紫色  b97aff
        UICOLOR_ORANGE_TASK        =	cc.c3b(255,165,0)	--橙色  ffa500	
        UICOLOR_YELLOW_TASK        =	cc.c3b(255,255,0)
        UICOLOR_CONTENT_TASK	=	cc.c3b(255,255,255)	--白色cc.c3b(0xe7,0xe3,0xd3)
        UICOLOR_WHITE_TASK        =	UICOLOR_CONTENT_TASK
        
			
    ]]
}

----------------------------------------------------------------------------------

AppDef.GUIRes = 
{
	-- 资源后缀
    Res_Suffix_Png = ".png",
    Res_Suffix_Ani = ".ani",
    Res_Item_Path = "item/equip%d.png",


    -- 羽翼资源路径
    Res_Wing_File_Path = "res2/Icon/ui_wing_icon/chibang_icon_%d.png",
    Res_Wing_File_Un_Path = "res2/Icon/ui_wing_icon/chibang_icon_un_%d.png",
    -- 创角资源名称
    Create_Role_Path = "res2/create/",
    Create_Role_Bg_1 = "bg.jpg",
    Create_Role_Bg_2 = "bg.jpg",
    Create_Role_jzzs_Bg_1 = "bg_jzzs.jpg",
    Create_Role_Imod_1 = "Create_5",
    Create_Role_Imod_2 = "Create_4",


    --神器阶段资源
    Shenqi_Stage_Icon_1 = "res2/Artifact_Bust/1_tou.png",
    Shenqi_Stage_Icon_2 = "res2/Artifact_Bust/2_tou.png",
    Shenqi_Stage_Icon_3 = "res2/Artifact_Bust/3_tou.png",
    Shenqi_Stage_Ani_1 = "shenqi/shenqi_move_1",
    Shenqi_Stage_Ani_2 = "shenqi/shenqi_move_2",
    Shenqi_Stage_Ani_3 = "shenqi/shenqi_move_3",

    --玩法Icon资源名称
    Activity_Name1 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_boss.png",
    Activity_Name2 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_shimenrenwu.png",
    Activity_Name3 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_chuangguan.png",
    Activity_Name4 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_lingqijuanxian.png",
    Activity_Name5 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_kunlunshan.png",
    Activity_Name6 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_diaoyu.png",
    Activity_Name7 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_dati.png",--答题
    Activity_Name8 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_baihuaxianzi.png",
    Activity_Name9 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_nianshou.png",--年兽/宠物副本
    Activity_Name10 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_zhuangbei.png",--强化副本
    Activity_Name11 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_zhuangbei.png",--升阶副本
    Activity_Name12 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_zhuangbei.png",--金钱副本
    Activity_Name13 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_zhuangbei.png",--潜能副本
    Activity_Name14 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_tongtianta.png",
    Activity_Name15 = "res/UI/Icon/ui_main_icon/ui_main_icon_jingji.png",
    Activity_Name16 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_husongshenshou.png",
    Activity_Name17 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_tiaozhanlingmo.png",
    Activity_Name18 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_baihuaxianzi.png",--猜拳
    Activity_Name19 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_baihuaxianzi.png",--宠物寻访
    Activity_Name20 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_yunbiao.png",
    Activity_Name21 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_zhuangbei.png",--淬炼副本
    Activity_Name22 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_zhuangbei.png",--洗炼副本
    Activity_Name23 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_zhuangbei.png",--宠铠副本
    Activity_Name24 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_shadiqubao.png",
    Activity_Name25 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_weihudanyuan.png",
    Activity_Name26 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_gerenleitai.png",
    Activity_Name27 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_baihuaxianzi.png",
    Activity_Name28 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_bangpaizhongzhi.png",
    Activity_Name29 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_cangbaotu.png",
    Activity_Name30 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_yingyongshilian.png",
    Activity_Name31 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_feixianzhanchang.png",
    Activity_Name32 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_zhuoyao.png",
    Activity_Name33 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_liujieshizhe.png",
    Activity_Name34 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_bangpailueduo.png",
    Activity_Name35 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_yaoqianshu.png",
    Activity_Name36 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_bangzhan.png",
    Activity_Name37 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_xiuxianlilian.png",
	Activity_Name38 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_kuafurenwu.png",
    Activity_Name39 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_xuelangxiaoyue.png",
    Activity_Name40 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_tianyuanzhengba.png",
    Activity_Name41 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_guwuxianshi.png",
    Activity_Name43 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_fuben.png",--染林密竹副本
    Activity_Name44 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_zhuangbei.png",--升阶副本
    Activity_Name45 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_zhuangbei.png",--强化副本
    Activity_Name46 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_zhuangbei.png",--潜能副本
    Activity_Name47 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_zhuangbei.png",--淬炼副本

    Activity_Name49 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_fuben.png",--绝谷悬崖
    Activity_Name50 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_fuben.png",--胡泊沼泽
    Activity_Name51 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_jingyanhuodong.png",--系统双倍
	Activity_Name52 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_meizhourenwu.png",--每周任务
    Activity_Name53 = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_fengshen.png",--封神试炼

    -- 灵气资源
    Lingqi_Ball_1 = "res/UI/ui_lingqijuanxian/lingqijuanxian_heiseqiu_new.png",
    Lingqi_Ball_2 = "res/UI/ui_lingqijuanxian/lingqijuanxian_baiseqiu_new.png",
    Lingqi_Ball_3 = "res/UI/ui_lingqijuanxian/lingqijuanxian_lvseqiu_new.png",
    Lingqi_Ball_4 = "res/UI/ui_lingqijuanxian/lingqijuanxian_lanseqiu_new.png",
    Lingqi_Ball_5 = "res/UI/ui_lingqijuanxian/lingqijuanxian_ziseqiu_new.png",
    Linqi_Fire_Format="donate/lingqi_fire%d%s",

    -- 冲值档位图片
    Recharg_Level_Img_Format = "res/UI/ui_vip/ui_chongzhi_icon_0%d.png",

    -- 称号资源
    Res_Titile_Format = "res/UI/cm_chenghao/chenghao%d.png",

     -- 走马灯底图资源
    FloatNoticeImageName = "res/UI/ui_shenjiang/ui_shenjiang_tips.png",

    Guess_Fist_Npc = "res2/Monster_Bust/505.png",
    Guess_Fist_1 = "bu_caiquan.png",
    Guess_Fist_2 = "jiandao_caiquan.png",
    Guess_Fist_3 = "shitou_caiquan.png",
    Guess_Fist_Win = "shengli_canquan.png",
    Guess_Fist_Lost = "shibai_canquan.png",
    Guess_Fist_Draw = "pinshou_canquan.png",
    Res_UI_Pet_Type_0 = "res_UI_ui_jingji_ui_shuxing_fa.png",
    Res_UI_Pet_Type_1 = "res_UI_ui_jingji_ui_shuxing_wu.png",
    Res_UI_Pet_Type_2 = "res_UI_ui_jingji_ui_shuxing_xue.png",
    Res_UI_Dot_Red = "res/UI/ui_common/ui_tishi_hongdian.png",
    Res_UI_Dot_Green = "res/UI/ui_common/ui_tishi_lvdian.png",

    Res_UI_Collect_Img1 = "res/UI/Icon/ui_caozuo_icon/ui_caozuo_caiji.png",
    Res_UI_Collect_Img2 = "res/UI/Icon/ui_caozuo_icon/ui_caozuo_chanzi.png",
    Res_UI_Collect_Img3 = "res/UI/Icon/ui_caozuo_icon/ui_caozuo_huoba.png",
    Res_UI_Collect_Img4 = "res/UI/Icon/ui_caozuo_icon/ui_caozuo_yanhua.png",

    --功能图片资源
    Function_Name100 = "res/UI/Icon/ui_main_icon/ui_main_icon_guaji.png",
    Function_Name120 = "res/UI/Icon/ui_main_icon/ui_main_icon_bangpai.png",
    Function_Name130 = "res/UI/Icon/ui_main_icon/ui_main_icon_duanzao.png",
    Function_Name131 = "res/UI/Icon/ui_main_icon/ui_main_icon_duanzao.png",
    Function_Name132 = "res/UI/Icon/ui_main_icon/ui_main_icon_duanzao.png",
    Function_Name133 = "res/UI/Icon/ui_main_icon/ui_main_icon_duanzao.png",
    Function_Name134 = "res/UI/Icon/ui_main_icon/ui_main_icon_duanzao.png",
    Function_Name140 = "res/UI/Icon/ui_main_icon/ui_main_icon_zuoqi.png",
    Function_Name141 = "res/UI/Icon/ui_main_icon/ui_main_icon_zuoqi.png",
    Function_Name142 = "res/UI/Icon/ui_main_icon/ui_main_icon_zuoqi.png",
    Function_Name150 = "res/UI/Icon/ui_main_icon/ui_main_icon_shenjiang.png",
    Function_Name151 = "res/UI/Icon/ui_main_icon/ui_main_icon_shenjiang.png",
    Function_Name152 = "res/UI/Icon/ui_main_icon/ui_main_icon_shenjiang.png",
    Function_Name153 = "res/UI/Icon/ui_main_icon/ui_main_icon_shenjiang.png",
    Function_Name154 = "res/UI/Icon/ui_main_icon/ui_main_icon_shenjiang.png",
    Function_Name160 = "res/UI/Icon/ui_main_icon/ui_main_icon_chouka.png",
    Function_Name170 = "res/UI/Icon/ui_main_icon/ui_main_icon_jineng.png",
    Function_Name180 = "res/UI/Icon/ui_main_icon/ui_main_icon_shezhi.png",
    Function_Name190 = "res/UI/Icon/ui_main_icon/ui_main_icon_yuyi.png",
    Function_Name191 = "res/UI/Icon/ui_main_icon/ui_main_icon_yuyi.png",
    Function_Name200 = "res/UI/Icon/ui_main_icon/ui_main_icon_shenqi.png",
    Function_Name201 = "res/UI/Icon/ui_main_icon/ui_main_icon_shenqi.png",
    Function_Name220 = "res/UI/Icon/ui_main_icon/ui_main_icon_huodong.png",
    Function_Name230 = "res/UI/Icon/ui_main_icon/ui_main_icon_fuli.png",
    Function_Name240 = "res/UI/Icon/ui_main_icon/ui_main_icon_fuben.png",
    Function_Name250 = "res/UI/Icon/ui_main_icon/ui_main_icon_jingji.png",
    Function_Name260 = "res/UI/Icon/ui_main_icon/ui_main_icon_paihangbang.png",
    Function_Name270 = "res/UI/Icon/ui_main_icon/ui_main_icon_wanfa.png",
    Function_Name290 = "res/UI/Icon/ui_main_icon/ui_main_icon_duiwu.png",
    Function_Name_Shangcheng = "res2/Icon/ui_main_icon/ui_main_icon_shangcheng.png",
}

AppDef.ColorKuangArr = 
{
    "res/UI/ui_common_new2/ui_common_icon_kuang_01.png",
    "res/UI/ui_common_new2/ui_common_icon_kuang_02.png",
    "res/UI/ui_common_new2/ui_common_icon_kuang_03.png",
    "res/UI/ui_common_new2/ui_common_icon_kuang_04.png",
    "res/UI/ui_common_new2/ui_common_icon_kuang_05.png",
    "res/UI/ui_common_new2/ui_common_icon_kuang_06.png",
    "res/UI/ui_common_new2/ui_common_icon_kuang_07.png",
    "res/UI/ui_common_new2/ui_common_icon_kuang_07.png",
    "res/UI/ui_common_new2/ui_common_icon_kuang_07.png",
    "res/UI/ui_common_new2/ui_common_icon_kuang_07.png",
}

AppDef.ColorDengjiArr = 
{
    "res/UI/ui_common_new2/ui_shenjiangbeibao_dengji_01.png",
    "res/UI/ui_common_new2/ui_shenjiangbeibao_dengji_02.png",
    "res/UI/ui_common_new2/ui_shenjiangbeibao_dengji_03.png",
    "res/UI/ui_common_new2/ui_shenjiangbeibao_dengji_04.png",
    "res/UI/ui_common_new2/ui_shenjiangbeibao_dengji_05.png",
    "res/UI/ui_common_new2/ui_shenjiangbeibao_dengji_06.png",
    "res/UI/ui_common_new2/ui_shenjiangbeibao_dengji_07.png",
    "res/UI/ui_common_new2/ui_shenjiangbeibao_dengji_07.png",
}

--封神列传，章节图片资源
AppDef.FengShenStoryChapterIconArr = 
{
    "res/UI/ui_main/ui_main_icon_14.png", --普通章节
    "res/UI/ui_main/ui_main_icon_06.png", --Boss章节
}

--[[
头像资源类型
]]
AppDef.HeadIconResType = {
    Body = 1,--半身像
    Circel = 2,--圆形头像
    Square = 3,--方形头像
}

AppDef.RedDotBtnName = 
{
    Group1Btn1 = "btn_shangcheng",
    Group1Btn3 = "btn_jingji",
    Group1Btn4 = "btn_paihangbang",
    Group1Btn5 = "btn_mubiao",
    Group1Btn6 = "btn_jingjie",--境界
    Group2Btn1 = "btn_shouchong",
    Group2Btn2 = "btn_zhekou",
    Group2Btn3 = "btn_huodong",
    Group2Btn4 = "btn_fuli",
    Group2Btn5 = "btn_renwu",
    Group3Btn1 = "btn_jineng",
    Group3Btn2 = "btn_zhenrong",
    Group3Btn3 = "btn_chouka",
    Group3Btn4 = "btn_zuoqi",
    Group3Btn5 = "btn_duanzao",
    Group3Btn6 = "btn_bangpai",
    Group4Btn1 = "btn_shenqi",
    Group4Btn2 = "btn_yuyi",
    Group4Btn3 = "btn_xitong",
    --Group5Btn1 = "btn_Activity",
    Group5Btn1 = "btn_bangpai",
    BagBtn     = "btn_Bag",
    LockerBtn  = "locker",
    socialBtn = "btn_social",
    chatBtn = "btn_chat",
    fundBtn = "btn_jijin",
    huoYueJiJin = "btn_jijin2",
    PetEquipBtn = "btn_zhuangbei",
    PetMail = "btn_mail",
    FuBen = "btn_fuben",
    btn_Qiri = "btn_Qiri",
	WanFa = "btn_wanfa",
	ChuangDai = "btn_chuandai",
	FaBaoBtn = "btn_fabao",
    ---------------------------------------------
    --卡牌新加
    PetBagBtn = "btn_shenjiangbeibao",  --卡牌背包
    XunBaoTask = "btn_xunbao_task", --寻宝日常任务
    ----------------------------------------------

    btn_shangcheng = "btn_shangcheng",
    btn_jianghun = "btn_jianghun",
    btn_wanfaShop = "btn_wanfaShop",

}

AppDef.UnOpenWMap_MapId = 
{
    45,
    46,
    51,
    54,
    55,
    201,
    {121,150 },
    {161,168 },
    {171,179 },
}

--是否可以打开地图
function AppDef:IsCanOpenWMap(id)
    for i=1,#AppDef.UnOpenWMap_MapId do
        local value = AppDef.UnOpenWMap_MapId[i]
        if type(value)=="table" then
            if #value == 2 and id >= value[1] and id <= value[2] then
                return false
            end
        elseif value == id then
             return false
        end
    end
    return true
end

--[[
聊天判断是语音聊天(通过json格式判断)
]]
function AppDef:isChatContentJosn(jsonString)

    if string.len(jsonString) < 6 then
        return false
    end

    local string1 = string.sub(jsonString, 1, 1)
    local string2 = string.sub(jsonString, #jsonString)

    if string1 == "{" and string2 == "}" then
        return true
    end

    return false
end

--获取道具来源icon
function AppDef:GetItemFromIcon(id)
    local res = AppDef.FunctionIcon[id]
    if  res == nil then
        res = AppDef.GUIRes["Activity_Name"..id]
    end
    return res
end

AppDef.upgradeMaterial_ID = 
{   
    FM_funcion_none = 1,
    FM_Equip_upgrade = 2,      --锻造升阶
    FM_Equip_strengthen = 3,   --锻造强化
    FM_Equip_Quench = 4,       --锻造淬炼
    FM_Equip_xilian = 5,       --锻造洗练
    FM_Mount_upgrade = 6,      --坐骑进阶
    FM_Mount_strengthen = 7,   --坐骑进阶
    FM_Pet_Skill = 8,          --坐骑强化
    FM_Pet_xiulian = 9,        --坐骑修炼
    FM_Pet_Formation = 10,      --坐骑布阵
    FM_shenqi_upgrade = 11,     --神器进阶
    FM_Chat_Laba = 12,        --购买喇叭
}

--首充提示等级
AppDef.FirstRecharge = 
{   
    show_Lv1 = 99,
    show_Lv2 = 99,      
    show_Lv3 = 99,   
    show_Lv4 = 99,       
    show_Lv5 = 99,       

}

--物品类型
AppDef.ItemType = 
{   
    Normal = 1,   --普通道具
    PetFrag = 2,    --神将碎片
    Jingyandan = 3,   --神将经验丹
    JinLianExp = 4,       --精炼经验道具
    PuTongBaoXiang = 5,       --普通宝箱
    NXuanYiBox = 6,   --N选1宝箱
    PetEquipFrag = 7,    --神将装备碎片
    --FaBaoSuiPian = 8,   --法宝碎片
    ZuoQiSuiPian = 9,       --坐骑碎片
    ChibangSuiPian = 10,  --翅膀碎片
    HuoDongDaoJu = 11,   --活动道具
    ChenHaoDaoJu = 12,       --称号道具
    ZiYuanDaoJu = 13,  --资源道具
    Tilidan = 14,--体力丹
    FaBaoExp = 15,--法宝经验书
    FaBaoSuiPian = 16,--法宝碎片
    TiLiDan = 14,  --体力丹
    FaBaoExp = 15, --法宝经验丹
    FaBaoFrag = 16, --法宝碎片
}

--物品类型
AppDef.HeChengType = 
{
    Cop_Item = 1,  --道具合成
    Cop_Pet = 2 , --神将合成
    Cop_PetFrag = 3,  --神将碎片分解
    Cop_Equip = 4,  --装备合成
    Cop_EquipDeco = 5,  --装备分解
    Cop_EquipReBorn = 6,  --装备重生为碎片
    Cop_EquipFragDeco = 7,  --装备碎片分解
    Cop_FaBao = 8,  --法宝合成
    Cop_FaBaoDeco = 9,  --法宝分解
}


--招募类型
AppDef.DrawKind = {
    NormalDraw = 1, --基础抽卡
    HighLevelDraw = 2, --高级抽卡
    FriendlyDraw = 3, --友情抽卡
}

--招募类型
AppDef.DrawType = {
    OneDraw = 1, --基础抽卡
    TenDraw = 2, --高级抽卡
}

--布阵类型
AppDef.FormationType = {
    XueZhan = 1, --英勇试炼
}


--2进制 位运算
AppDef.BitMapIndex = {
    0x01,
    0x02,
    0x04,
    0x08,
    0x10,
    0x20,
    0x40,
}


--法宝材料
AppDef.fabaoExpItemID = {
    normal_fbExp = 615,
    mid_fbExp = 616,
    high_fbExp = 617,
}

AppDef.QiRiActivityType = {
    DailyFuLi = 1, --每日福利
    NormalFuBen = 2, --主线副本
    EquipStrength = 3, --装备强化
    ShopDisCount = 4,  --商店打折
    TakeTaskCumulative = 5, -- 累计完成任务
}


AppDef.RankIdx = {
    Rank_FuBen = 1,
    Rank_JingJI = 2,
    Rank_XueZhan = 3,
    Rank_Level = 4,
    Rank_Pet = 5,
    Rank_Power = 6,
    Rank_TuJian=7,
}

--一层弹窗帮助按钮

AppDef.FCBHelp={
    ChouKa="ChouKa",--抽卡
    LieZhuan="LieZhuan",--封神列传 1
    ShiLian="ShiLian",--封神试炼  1
    KunLun="KunLun",--决战昆仑  1
    ZhenRong="ZhenRong",--阵容  1
    TuJian="TuJian",--神将图鉴  1
    XueZhan="XueZhan",--血战到底 1
    ZhangBei="ZhangBei",--装备养成+B9 1
    FaBao="FaBao",--法宝养成
	JingJI="JingJi", --竞技场
	DaTi = "DaTi", --答题
	KunLunXunBao = "KunLunXunBao", --昆仑寻宝
	JingJie = "JingJie", --境界
	XunBao = "XunBao", --法宝搜索
	WorldBoss = "WorldBoss", --六圣现世
	BangPaiFuBen = "BangPaiFuBen", --帮派副本
	YouLiSanJie = "YouLiSanJie", --游历三界
}