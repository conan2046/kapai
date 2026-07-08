local ShopDef = {}

ShopDef.PAGE_FOR_ = {
    CHANGYONGDAOJU = 1,    --常用道具
    SHENMISHANGDIAN = 2,     --神秘商店
    BINDYUANBAO = 4,     --绑定元宝
    TEGONGSHANGPIN = 5, --特供商品
    JIFEN = 11, --擂台积分商品
    BANGGONG = 7, --帮贡商品
}

ShopDef.ST_ = {
    WEPONSHOP = 1, --武器商店
    ARMORSHOP = 2,    --防具商店
    DRUGSHOP = 3,     --药品店
    GROCERYSHOP = 4,  --杂货店
    SEEDSHOP = 5,     --种子店
}

ShopDef.MK_TP = {
    XIANSHI   = 0,  --限时抢购
    CHANGYONG = 1,  --常用道具
    DUANZAO   = 2,  --装备锻造
    PETHORSE  = 3,  --宠物坐骑
    BANGDING  = 4,  --绑定元宝
    MYSTERY   = 6,  --神秘商店
    GONGOFFER = 7,  --帮贡商店
    NPC       = 8,  --NPC商店
    COMPETE   = 11, --擂台积分
    TEGONG    = 15, --特供商品 
    SHENPO    = 16, --神魄商品 
    ZADAN     = 17, --砸蛋商品 
}

ShopDef.EXTRACT = {
    NORMAL = 1,--普通
    ZHUOYUE,--卓越
    WANMEI,--完美
    SHILIAN,--十连
}

ShopDef.QUANID = {
    ZHUOYUE = 2376,   --卓越券id
    WANMEI = 2377,    --完美券id
    SHILIAN = 2378,   --十连券id
}


--商店类型
ShopDef.KP_TYPE = {
    SHANGCHENG = 1,        --元宝商店
    JIANGHUNSHANGDIAN = 2, --将魂商店
    JINGJICHANGSHANGDIAN = 3, --竞技场商店
    XUEZHANSHANGDIAN = 4,   --血战商店
    QIRIBANJIASHANGDIAN = 5, --七日半价商店
    KUNLUNSHANGDIAN = 6, --昆仑商店
    BANGPAISHANGDAIN = 7, --帮派商店
    ZHUANPANSHANGDIAN = 8, --转盘商店
}

--新的卡牌商店
ShopDef.KP_SP = {
    YUANBAO = 1,  --元宝商店
    JIANGHUN = 2, --将魂商店
    WANFA = 3,    --竞技场商店(商品)
    WANFA_GIFT = 4,    --竞技场商店(奖励)
    XueZhan_1 = 5, --血战商店(初级装备)
    XueZhan_2 = 6, --血战商店(中级装备)
    XueZhan_3 = 7, --血战商店(高级装备)
    XueZhan_4 = 8, --血战商店(血战奖励)
    KUNLUNSHOP = 23, --昆仑商店
    BANGPAISHOP = 25, --帮派商店
    TURNTABLESHOPUI = 27, --转盘商店
}

--商店条件
ShopDef.KP_CDNTYPE = {
    LM_LEVEL = 1,
    LM_VIP = 2,
    LM_XUEZHAN = 3,
    LM_XUEZHAN_HARD = 4,
    LM_AC_SCORE = 5,
    LM_RANK = 6,
    LM_WULIN = 7,
}

return ShopDef