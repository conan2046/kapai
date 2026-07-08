local BangPaiZoneDef = {}
BangPaiZoneDef.__index = BangPaiZoneDef

BangPaiZoneDef.Collect = {
	PlantWater = 1,
	PlantBug = 2,
	PlantSteal = 3,
	PlantGodTree = 4,
	PlantMagicFire = 5,
	PlantMagicUnFire = 6,
}

BangPaiZoneDef.OprType = 
{
	ChooseSeed = 1,--选择种子
	ClickSeed = 2,--浇水、除虫、移除
	StartSteal = 3,--盗窃
	StopCollectAnim = 4,--移除收集动画
	ClickGodTree = 5,--点击神树
	ClickMagicFire = 6,--点击魔火
	ClickGuard = 7,--点击守卫
	UpdateGuard = 8,--更新守卫信息（lua）
	ClickEnemy = 9,--点击敌人
}

BangPaiZoneDef.PicMap = 
{
	[1] = { --本帮击杀
		["pic"] = "res/UI/faction_plant/factiontask_kill.png",
		["scale"] = 1,
		["name"] = "",
		["tips"] = "在自己的帮派领地击杀外来者"},
	[2] = { --种植
		["pic"] = "res/UI/faction_plant/factiontask_plant.png",
		["scale"] = 1,
		["name"] = "",
		["tips"] = ""},
	[3] = { --除虫
		["pic"] = "res/UI/faction_plant/factiontask_debug.png",
		["scale"] = 1,
		["name"] = "",
		["tips"] = "种植成功后即可进行后续操作"},
	[4] = { --浇水
		["pic"] = "res/UI/faction_plant/factiontask_water.png",
		["scale"] = 1,
		["name"] = "",
		["tips"] = "种植成功后即可进行后续操作"},
	[5] = { --偷菜
		["pic"] = "res/UI/faction_plant/factiontask_steal.png",
		["scale"] = 1,
		["name"] = "",
		["tips"] = "选择帮派潜入偷菜"},
	[6] = { --捐献金币
		["pic"] = "res/UI/faction_plant/factiontask_donater.png",
		["scale"] = 1,
		["name"] = "",
		["tips"] = ""},
	[7] = { --登录
		["pic"] = "res/UI/Icon/ui_main_icon/ui_main_icon_denglu.png",
		["scale"] = 1,
		["name"] = "",
		["tips"] = ""},
	[8] = { --累计时长
		["pic"] = "res/UI/ui_main/ui_main_icon_04.png",
		["scale"] = 1,
		["name"] = "",
		["tips"] = ""},
	[9] = { --累计时长
		["pic"] = "res/UI/ui_main/ui_main_icon_04.png",
		["scale"] = 1,
		["name"] = "",
		["tips"] = ""},
	[10] = { --累计时长
		["pic"] = "res/UI/ui_main/ui_main_icon_04.png",
		["scale"] = 1,
		["name"] = "",
		["tips"] = ""},
	[11] = { --普通祈福
		["pic"] = "res/UI/Icon/ui_main_icon/ui_icon_wanfa_shenshu.png",
		["scale"] = 1,
		["name"] = "",
		["tips"] = ""},
	[12] = { --元宝祈福
		["pic"] = "res/UI/Icon/ui_main_icon/ui_icon_wanfa_shenshu.png",
		["scale"] = 1,
		["name"] = "",
		["tips"] = ""},
	[13] = { --商店兑换
		["pic"] = "res/UI/Icon/ui_main_icon/ui_icon_wanfa_bangpaishangdian.png",
		["scale"] = 1,
		["name"] = "",
		["tips"] = ""},
	[14] = { --帮战
		["pic"] = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_bangzhan.png",
		["scale"] = 1,
		["name"] = "",
		["tips"] = ""},
	[34] = { --帮派掠夺
		["pic"] = "res2/Icon/ui_wanfa_icon/ui_icon_wanfa_bangpailueduo.png",
		["scale"] = 1,
		["name"] = "",
		["tips"] = "选择帮派潜入掠夺神树经验"},
}

BangPaiZoneDef.IconMap = {
	[1] = "item/equip3026.png",-- 个人帮贡
	[3] = "item/equip3030.png",-- 帮派资金
	[4] = "item/equip3031.png",-- 帮派影响力
}

return BangPaiZoneDef