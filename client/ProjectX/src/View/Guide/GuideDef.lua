GuideDef = {}

GuideDef.Type = {
    Code = 1,--程序触发
    StartTask = 2,--接取任务后触发
    CompleteTask = 3,--完成任务后触发
    ClickTask = 4,--身上有次任务打开相关界面后触发
}

GuideDef.StepId = {
    Guide_FuBen = 101,--点击副本（主界面）
    Guide_FuBen_1 = 102,--点击章节
    Guide_FuBen_2 = 103,--点击怪物
    Guide_FuBen_Finish = 104,--点击挑战

    Guide_FuBen1 = 201,--点击怪物（2级升级界面关闭触发）
    Guide_FuBen1_Finish = 202,--点击挑战

    Guide_Pet = 301,--点击返回（3级升级界面关闭触发）
    Guide_Pet_1 = 302,--点击返回
    Guide_Pet_2 = 303,--点击招募（主界面）
    Guide_Pet_3 = 304,--点击免费招募
    Guide_Pet_4 = 305,--关闭单个招募成功界面SingleDrawResultUI
    Guide_Pet_5 = 306,--点击返回
    Guide_Pet_6 = 307,--点击阵容（主界面）
    Guide_Pet_7 = 308,--点击可上阵（最后一个位置）
    Guide_Pet_8 = 309,--点击+号
    Guide_Pet_9 = 310,--点击上阵
    Guide_Pet_10 = 311,--点击返回
    Guide_Pet_11 = 312,--点击副本（主界面）
    Guide_Pet_12 = 313,--点击章节
    Guide_Pet_13 = 314,--点击怪物
    Guide_Pet_14 = 315,--点击挑战
    Guide_Pet_15 = 316,--点击怪物（战斗结算界面关闭）
    Guide_Pet_Finish = 317,--点击挑战

    Guide_FuBen2 = 401,--点击第一个星数箱子（4级升级界面关闭触发）
    Guide_FuBen2_1 = 402,--点击领取
    Guide_FuBen2_2 = 403,--点击返回
    Guide_FuBen2_3 = 404,--点击返回
    Guide_FuBen2_4 = 405,--点击阵容（主界面）
    Guide_FuBen2_5 = 406,--点击养成
    Guide_FuBen2_6 = 407,--点击突破页签
    Guide_FuBen2_7 = 408,--点击突破按钮
    Guide_FuBen2_8 = 409,--关闭突破成功界面HeroBreakSuccUI
    Guide_FuBen2_9 = 410,--点击返回
    Guide_FuBen2_10 = 411,--点击返回
    Guide_FuBen2_11 = 412,--点击副本（主界面）
    Guide_FuBen2_12 = 413,--点击章节
    Guide_FuBen2_13 = 414,--点击怪物
    Guide_FuBen2_Finish = 415,--点击挑战

    Guide_FuBen3 = 501,--点击关卡箱子（5级升级界面关闭触发）
    Guide_FuBen3_1 = 502,--点击领取
    Guide_FuBen3_2 = 503,--点击返回
    Guide_FuBen3_3 = 504,--点击返回
    Guide_FuBen3_4 = 505,--点击阵容（主界面）
    Guide_FuBen3_5 = 506,--点击养成
    Guide_FuBen3_6 = 507,--点击升星页签
    Guide_FuBen3_7 = 508,--点击升星按钮
    Guide_FuBen3_8 = 509,--关闭升星成功界面PetStarUpSucUI
    Guide_FuBen3_9 = 510,--点击返回
    Guide_FuBen3_10 = 511,--点击返回
    Guide_FuBen3_11 = 512,--点击副本（主界面）
    Guide_FuBen3_12 = 513,--点击章节
    Guide_FuBen3_13 = 514,--点击怪物
    Guide_FuBen3_Finish = 515,--点击挑战

    Guide_FuBen4 = 516,--点击第二章（关卡通关剧情结束）
    Guide_FuBen4_1 = 517,--点击怪物
    Guide_FuBen4_Finish = 518,--点击挑战

    Guide_Equip = 601,--点击返回（6级升级界面关闭触发）
    Guide_Equip_1 = 602,--点击返回
    Guide_Equip_2 = 603,--点击阵容（主界面）
    Guide_Equip_3 = 604,--点击装备栏(1)
    Guide_Equip_4 = 605,--点击穿戴
    Guide_Equip_5 = 606,--点击当前装备
    Guide_Equip_6 = 607,--点击前往强化
    Guide_Equip_7 = 608,--点击强化按钮
    Guide_Equip_8 = 609,--点击返回
    Guide_Equip_9 = 610,--点击返回
    Guide_Equip_10 = 611,--点击副本（主界面）
    Guide_Equip_11 = 612,--点击章节
    Guide_Equip_12 = 613,--点击怪物
    Guide_Equip_Finish = 614,--点击挑战

    Guide_Pet1 = 801,--点击返回（8级升级界面关闭触发）
    Guide_Pet1_1 = 802,--点击返回
    Guide_Pet1_2 = 803,--点击阵容（主界面）
    Guide_Pet1_3 = 804,--点击养成
    Guide_Pet1_4 = 805,--点击初级经验丹
    Guide_Pet1_5 = 806,--点击返回
    Guide_Pet1_6 = 807,--点击返回
    Guide_Pet1_Finish = 808,--点击副本（主界面）

    Guide_Arena = 1001,--点击返回（10级升级界面关闭触发）
    Guide_Arena_1 = 1002,--点击返回
    Guide_Arena_2 = 1003,--点击玩法（主界面）
    Guide_Arena_3 = 1004,--点击竞技场
    Guide_Arena_Finish = 1005,--点击自己前一个

    Guide_XunBao = 1501,--点击返回（15级升级界面关闭触发）
    Guide_XunBao_1 = 1502,--点击返回
    Guide_XunBao_2 = 1503,--点击玩法（主界面）
    Guide_XunBao_3 = 1504,--点击寻宝
    Guide_XunBao_4 = 1505,--点击+号
    Guide_XunBao_5 = 1506,--点击关闭寻宝获得界面XunBaoPopUI
    Guide_XunBao_6 = 1507,--点击合成
    Guide_XunBao_7 = 1508,--关闭合成结果
    Guide_XunBao_8 = 1509,--点击返回
    Guide_XunBao_9 = 1510,--点击阵容（主界面）
    Guide_XunBao_10 = 1511,--点击法宝位置(1)
    Guide_XunBao_11 = 1512,--点击穿戴
    Guide_XunBao_12 = 1513,--点击返回
    Guide_XunBao_Finish = 1514,--点击副本（主界面）

    Guide_Tujian_1 = 3501,--点击神将按钮（主界面）
    Guide_Tujian_2 = 3502,--点击神将图鉴
    Guide_Tujian_Finish = 3503,--点击激活

}

return GuideDef