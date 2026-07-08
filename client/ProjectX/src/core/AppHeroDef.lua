--[[
角色相关的宏定义，以及方法
]]
AppDef.MAX_EQUIP_STRENGTH_LEVEL = 20 --强化最大等级
AppDef.MAX_EQUIP_UPGRADE_LEVEL = 100 --升阶装备最大等级
AppDef.MAX_PET_QUALITY = 4 --神将品质最大值
AppDef.MAX_PET_TAG = 4 --神将图鉴分类
AppDef.MAX_PET_EQUIP_STAR = 6 --神将装备星级最大值

-------------------C++枚举----------------------------------
AppDef.CEnum = {}
AppDef.CEnum.ModelAniType = 
{
	None = 0,
	Hero = 1,
	NPC = 2,
	Monster = 3,
	HolyBeast = 4,
	Wing = 5,
	Other = 6,
	MonsterBig = 7,
}
-----------------------------------------------------------
--野外模型朝向
AppDef.SceneModelFace = {
	Right_Down = 0, 
	Down = 1, 
	Left_Down = 2,
	Left = 3, 
	Left_Up = 4, 
	Up = 5, 
	Right_Up = 6, 
	Right = 7,
}

--AppDef.BTConst = {}
AppDef.HeroSex = 
{
	Male = 0,--男
	Female = 1,--女
}

AppDef.HeroExp = {
	45000,60000,75000,90000,105000,120000,135000,150000,165000,180000,195000,210000,225000,240000,255000,270000,285000,300000,
	315000,330000,345000,360000,375000,390000,405000,420000,435000,450000,465000,520000,503500,510000,525000,537500,550000,570000,
	610000,615000,620000,1102500,1157000,1709000,2280000,3000000,3290000,3360000,1746495,1822500,1858150,1932800,1969200,2005600,2042000,
	3688320,2744700,2900550,2949525,2998500,3047475,4540750,3585510,3641280,3697050,3752820,5366140,4496440,4561270,4626100,6668710,5758240,
	5836660,8660840,5993500,6071920,9004820,16871600,25033200,33392000,41948000,50701200,32534250,48748500,65332500,82286250,99609750,67596000,
	101858250,136860000,172601250,209082000,106355250,160514250,215782500,272160000,329646750,148812000,224716500,302100000,380962500,461304000,
}

AppDef.HusongMonserPics = {302,304,201,204,401}

--[[
职业
]]
AppDef.HeroPro = 
{
    Zhenguo=1,      --镇国
    Bajinggong =2,      --八景宫
    Yuxugong =3,      --玉虚宫
    Biyougong =4,      --碧游宫
    Kunlun=5,    --昆仑
    Jiuli =6,      --九黎
}

--[[
英雄职业对应的资源
]]
AppDef.HeroProAttrSelectedRes = 
{
	"res/UI/ui_zhiye/ui_zhiye_zhenguo_02.png",
	"res/UI/ui_zhiye/ui_zhiye_bajinggong_02.png",
	"res/UI/ui_zhiye/ui_zhiye_yuxugong_02.png",
	"res/UI/ui_zhiye/ui_zhiye_biyougong_02.png",
	"res/UI/ui_zhiye/ui_zhiye_kunlun_02.png",
	"res/UI/ui_zhiye/ui_zhiye_jiuli_02.png",
}

--[[
英雄职业对应的资源
]]
AppDef.HeroProAttrNormalRes = 
{
	"res/UI/ui_zhiye/ui_zhiye_zhenguo_01.png",
	"res/UI/ui_zhiye/ui_zhiye_bajinggong_01.png",
	"res/UI/ui_zhiye/ui_zhiye_yuxugong_01.png",
	"res/UI/ui_zhiye/ui_zhiye_biyougong_01.png",
	"res/UI/ui_zhiye/ui_zhiye_kunlun_01.png",
	"res/UI/ui_zhiye/ui_zhiye_jiuli_01.png",
}

--[[
显示职业属性图片
]]
function AppDef:ShowHeroProAttrImg(imgView, zhiye)
    local attrRes = AppDef.HeroProAttrSelectedRes[zhiye]
    imgView:loadTexture(attrRes,ccui.TextureResType.localType)
end


AppDef.HeadType = 
{
    HERO_IMAGE_HOLE_BODY=0,   --全身像
    HERO_IMAGE_HALF_BODY=1,   --半身像
    HERO_IMAGE_HEAD=2,        --头像
    HERO_IMAGE_HEAD_ROUND=3,  --圆形小头像
}

AppDef.HeroBaseFileList = 
{
	"hero/Z_",
	"hero/B_",
	"hero/Y_",
	"hero/H_",
	"hero/K_",
	"hero/J_"
}

AppDef.HeroFileList = 
{
	"hero/Z_0_",
	"hero/B_0_",
	"hero/Y_0_",
	"hero/H_0_",
	"hero/K_0_",
	"hero/J_0_"
}

--[[
职业属性对应的资源
]]
AppDef.ProAttrRes = 
{
	"res/UI/ui_jingji/ui_shuxing_rou.png",
	"res/UI/ui_jingji/ui_shuxing_fa.png",
	"res/UI/ui_jingji/ui_shuxing_wu.png",
	"res/UI/ui_jingji/ui_shuxing_fu.png",
	"res/UI/ui_jingji/ui_shuxing_kong.png",
	"res/UI/ui_jingji/ui_shuxing_ling.png",
}

--[[
等级限制
]]
AppDef.LevelLimit = 
{
	Copy = 29,--副本29级开启
    RSI_LVL_TIP24 = 24,
}


--[[
根据职业获取性别
]]
function AppDef:GetHeroSexByPro(pro)
	--1、3、5 男  2、4、6 女
	if pro % 2 == 1 then
		return AppDef.HeroSex.Male
	else
		return AppDef.HeroSex.Female
	end
end

function AppDef:GetHeroPicFileName(profession,typ)
	local resType
	if typ == AppDef.HeadType.HERO_IMAGE_HOLE_BODY then
		resType = AppDef.HeadIconResType.Body
	elseif typ == AppDef.HeadType.HERO_IMAGE_HALF_BODY then
		resType = AppDef.HeadIconResType.Body
	elseif typ == AppDef.HeadType.HERO_IMAGE_HEAD then
		resType = AppDef.HeadIconResType.Square
	else
		resType = AppDef.HeadIconResType.Circel
	end
	return Utils:GetHeroIconRes(profession, resType)
end

function AppDef:GetProfNameBy5BaseIndex(profession)
	local str = GUITips["HeroPro" .. profession]
	if str == nil then
		str = ""
	end
	return str
end


--/转换职业值为[1-昆仑山 2-异朽阁 5-妖魔殿]->(1-妖魔殿,2-昆仑山,3-异朽阁)

--[[
阔成6职业，这个不需要了
]]
function AppDef:TransProf5BaseTo3Base(profession)
	return profession
end

function AppDef:GetHipcIdx(prof, sex)
	return prof
end

function AppDef:GetHeroProfessionalName(zhiye)
	local str = GUITips["HeroPro" .. zhiye]
	if str == nil then
		str = ""
	end
	return str
	-- if zhiye == 1 then --昆仑山
 --        return GUITips.RSI_FACTION_MSG48
	-- elseif zhiye == 2 then --异朽阁
 --        return GUITips.RSI_FACTION_MSG49
	-- elseif zhiye == 5 then -- 妖魔殿
 --        return GUITips.RSI_FACTION_MSG50
	-- end
	-- return "Unknow"
end

--[[
显示职业属性图片
]]
function AppDef:ShowProAttrImg(imgView, zhiye)
    local attrRes = AppDef.ProAttrRes[zhiye]
    if attrRes == nil then
    	return
    end
    local function TexErr()
                
    end
    local function showImg()
        imgView:loadTexture(attrRes,ccui.TextureResType.plistType)
    end
    xpcall(showImg,TexErr)
    
end

--[[
显示职业属性
]]
function AppDef:ShowProAttrText(Label, zhiye)
    local attrName = GUITips["HeroProAttr" .. zhiye]
    Label:setString(attrName)
end

-----------------------------阵容相关---------------------------------
AppDef.Formation = {}
AppDef.Formation.MaxFightNum = 5--最大出站单位数量
AppDef.Formation.IconRes = "res2/Icon/ui_zhenfa_icon/zhenfa_"

----------------------------------------------------------------------

--------------------------------宠物相关-------------------------------
AppDef.Pet = {}
AppDef.Pet.MaxLevel = 100--最大等级
AppDef.Pet.AttackType = {}--攻击类型
AppDef.Pet.AttackType.Physical = 1--物攻宠物
AppDef.Pet.AttackType.Magic = 2--法攻攻宠物

AppDef.Pet.MaxBornSkillNum = 4--最大宠物天赋技能数量
AppDef.Pet.MaxSkillNum = 12--最大宠物技能数量
AppDef.Pet.MaxUpgradeItems = 4--宠物升级最大需要材料数量
AppDef.Pet.MaxBornSkillLv = 20--宠物天赋技能最大等级
AppDef.Pet.MaxLearnSkillLv = 5--宠物天书技能最大等级
AppDef.Pet.UpgradsMats = {834,835,836,837}--升级需要的材料id
AppDef.Pet.UpgradsMatsRate = {1, 2.5, 12.5, 62.5}--升级材料的单次升级的数量比例
AppDef.Pet.LearnOpenLv = {20,25,30,35,40,45,50,55,60}--天书技能开启等级,按照神将等级判断
AppDef.Pet.LearnOpenStar = {1,2,3,4,5,6,7,8,9}--天书技能开启等级,按照神将星级判断

AppDef.Pet.MaxXiulianNum = 5--总共5个修炼类型

AppDef.Pet.MaxStar = 8--宠物最大星级
AppDef.Pet.MaxSubStar = 10--宠物最大子星级

AppDef.Pet.MaxXliulianType = 5--宠物最大的修炼类型数量
AppDef.Pet.MaxXliulianLv = 20--最大修炼等级
AppDef.Pet.MaxEquipPosNum = 6 --宠物装备部位数量
AppDef.Pet.MaxSuitTypeNum = 10 --宠物套装类型最大数量
AppDef.Pet.MaxSuitEquipBagNum = 1000 --宠物装备背包格最大数量
AppDef.Pet.MaxFaBaoBagNum = 999 --法宝背包格最大数量

--[[
根据宠物品质获取宠物颜色
]]
function AppDef:GetPetQualityColor(quality)
	return AppDef:GetQualityColor(quality)
end

--[[
根据宠物品质获取宠物颜色
]]
function AppDef:GetPetQualityColorId(quality)
	-- if quality == 1 then
	-- 	return 3
	-- elseif quality == 2 then
	-- 	return 4
	-- elseif quality >= 3 and quality <= 6 then
	-- 	return 5
	-- elseif quality == 7 then
	-- 	return 8
	-- elseif quality == 8 then
	-- 	return 6
	-- else
	-- 	--default
	-- 	return 3
	-- end
	return quality
end

--[[
根据道具品质获取颜色
--@isWhite 表示是否白色
]]
function AppDef:GetItemQualityColor(quality,isWhite)
	if quality == 1 then
        if isWhite == nil or isWhite then
		  return AppDef.UIColor.WHITE
        else
          return AppDef.UIColor.WHITE
        end
	elseif quality == 2 then
		return AppDef.UIColor.GREEN
	elseif quality == 3 then
		return AppDef.UIColor.BLUE
	elseif quality == 4 then
        return AppDef.UIColor.PURPLE
    elseif quality == 5 then
        return AppDef.UIColor.ORANGE
    elseif quality == 6 then
        return AppDef.UIColor.RED
    elseif quality == 7 then
        return AppDef.UIColor.GOLD
    else
        --default
        return AppDef.UIColor.WHITE
    end
end

function AppDef:GetQualityColor(quality)
    if quality == 1 then
        return AppDef.UIColor.WHITE
    elseif quality == 2 then
        return AppDef.UIColor.GREEN
    elseif quality == 3 then
        return AppDef.UIColor.BLUE
    elseif quality == 4 then
        return AppDef.UIColor.PURPLE
    elseif quality == 5 then
        return AppDef.UIColor.ORANGE
    elseif quality == 6 then
        return AppDef.UIColor.RED
    elseif quality == 7 then
        return AppDef.UIColor.GOLD
    else
        --default
        return AppDef.UIColor.WHITE
    end
end


--[[
获取宠物天书技能名字
sid:技能id
lv:技能等级
]]
function AppDef:GetPetLearnSkillName(sid, lv)
	local tmp = GUITips["UI_PET_LearnSkill_LV" .. lv]
	if tmp == nil then
		tmp = "Error"
	end
	local sdt = LSkillMgr:getSkillById(sid)
	if sdt ~= nil then
		tmp = tmp .. sdt.name
	end
	return tmp
end

--[[
评分对应的资源
]]
AppDef.Pet.QualityScoreRes = {
	"res/UI/ui_shenjiang/ui_shenjiang_zhanli_A.png",
	"res/UI/ui_shenjiang/ui_shenjiang_zhanli_A.png",
	"res/UI/ui_shenjiang/ui_shenjiang_zhanli_A.png",
	"res/UI/ui_shenjiang/ui_shenjiang_zhanli_A.png",
	"res/UI/ui_shenjiang/ui_shenjiang_zhanli_s.png",
	"res/UI/ui_shenjiang/ui_shenjiang_zhanli_ss.png",
	"res/UI/ui_shenjiang/ui_shenjiang_zhanli_sss.png",
	"res/UI/ui_shenjiang/ui_shenjiang_zhanli_ssss.png",
}

--[[
宠物品质底框
1蓝色底框
2紫色底框
3456橙色底框
7红色底框
]]

--[[
修炼对应的资源
]]
AppDef.Pet.XiulianRes = {
	"res/UI/ui_shenjiang/ui_shenjiang_baihu.png",
	"res/UI/ui_shenjiang/ui_shenjiang_xuanwu.png",
    "res/UI/ui_shenjiang/ui_shenjiang_qilin.png",
    "res/UI/ui_shenjiang/ui_shenjiang_zhuque.png",
	"res/UI/ui_shenjiang/ui_shenjiang_qinglong.png",
}

--[[
宠物基础属性
]]
AppDef.Pet.BaseAttrNames = {
	GUITips.Item_Info_Attr178,--物攻
	GUITips.Item_Info_Attr178,--法攻
	--物攻和法攻只能有一个
	GUITips.Item_Info_Attr147,--气血
	GUITips.Item_Info_Attr_Wufang,--物防
	GUITips.Item_Info_Attr_Fafang,--法防
	GUITips.Item_Info_Attr149,--命中
	GUITips.Item_Info_Attr158,--闪避
	GUITips.Item_Info_Attr151,--暴击
	GUITips.Item_Info_Attr_Kangbao,--抗暴
	GUITips.Item_Info_Attr148--速度
}

--[[
宠物高级属性
]]
AppDef.Pet.SeniorAttrNames = {
	GUITips.Item_Info_Attr_Zengshagnlv,--增伤率
	GUITips.Item_Info_Attr_Wumianlv,--物免率
	GUITips.Item_Info_Attr_Famianlv,--法免率
	GUITips.Item_Info_Attr_BaojiDamage,--暴击伤害
	GUITips.Item_Info_Attr_Fanjilv,--反击率
	GUITips.Item_Info_Attr_Kangfanlv,--抗反率
	GUITips.Item_Info_Attr_FanjiDamage,--反击伤害
	GUITips.Item_Info_Attr_Lianjilv,--连击率
    GUITips.Item_Info_Attr_Kanglianlv,--抗连率
    GUITips.Item_Info_Attr_LianjiDamage,--连击伤害
	GUITips.Item_Info_Attr_Fanzhenlv,--反震率
	GUITips.Item_Info_Attr_Kangzhenlv,--抗震率
	GUITips.Item_Info_Attr_FanzhenDamage,--反震伤害
	GUITips.Item_Info_Attr_Fumianqianghua,--负面强化
	GUITips.Item_Info_Attr_FumianDikang,--负面抵抗
}
--[[
显示宠物评分
]]
function AppDef:GetPetQualityScore(imageView, quality)
	if quality < 1 then
		quality = 1
	elseif quality > #AppDef.Pet.QualityScoreRes then
		quality = #AppDef.Pet.QualityScoreRes
	end
	local curRes = AppDef.Pet.QualityScoreRes[quality]
	if curRes == nil then
		return
	end
	imageView:ignoreContentAdaptWithSize(true)
    local needPlist = "res/csd/Plist/ui_mainPlist.plist"
    local needPng = "res/csd/Plist/ui_mainPlist.png"
    cc.SpriteFrameCache:getInstance():addSpriteFrames(needPlist, needPng)
	imageView:loadTexture(curRes,ccui.TextureResType.plistType)
end

AppDef.AttrTypeNames = 
{
    GUITips.Item_Info_Attr145,	--攻击(物攻，法攻自行处理)
    GUITips.Item_Info_Attr_Wufang,	--物防
    GUITips.Item_Info_Attr_Fafang,	--法防
    GUITips.Item_Info_Attr147,	--生命
    GUITips.Item_Info_Attr148,	--速度
    GUITips.Item_Info_Attr149,	--命中
    GUITips.Item_Info_Attr158,	--闪避
    GUITips.Item_Info_Attr151,	--暴击
    GUITips.Item_Info_Attr_Kangbao,	--抗暴
    GUITips.Item_Info_Attr_Gongjijia,	--攻击加成
    GUITips.Item_Info_Attr_Wufangjia,	--物防加成
    GUITips.Item_Info_Attr_Fafangjia,	--法防加成
    GUITips.Item_Info_Attr_Shengmingjia,	--生命加成
    GUITips.Item_Info_Attr_Sudujia,	--速度加成
    GUITips.Item_Info_Attr_Mingzhonglv,	--命中率
    GUITips.Item_Info_Attr_Shanbilv,	--闪避率
    GUITips.Item_Info_Attr_Baojilv,	--暴击率
    GUITips.Item_Info_Attr_Kangbaolv,	--抗暴率
    GUITips.Item_Info_Attr_Zengshagnlv,--增伤率
	GUITips.Item_Info_Attr_Wumianlv,--物免率
	GUITips.Item_Info_Attr_Famianlv,--法免率
	GUITips.Item_Info_Attr_BaojiDamage,--暴击伤害
	GUITips.Item_Info_Attr_Fanjilv,--反击率
	GUITips.Item_Info_Attr_Kangfanlv,--抗反率
	GUITips.Item_Info_Attr_FanjiDamage,--反击伤害
	GUITips.Item_Info_Attr_Lianjilv,--连击率
    GUITips.Item_Info_Attr_Kanglianlv,--抗连率
    GUITips.Item_Info_Attr_LianjiDamage,--连击伤害
	GUITips.Item_Info_Attr_Fanzhenlv,--反震率
	GUITips.Item_Info_Attr_Kangzhenlv,--抗震率
	GUITips.Item_Info_Attr_FanzhenDamage,--反震伤害
    GUITips.Item_Info_Attr_Fumianqianghua,	--负面强化
    GUITips.Item_Info_Attr_FumianDikang,	--负面抵抗
}

AppDef.EAttrType = 
{
    EAT_ATTACK = 1,	--攻击
    EAT_DEFENSE = 2,	--物防
    EAT_MAGICD_EFENSE = 3,	--法防
    EAT_HP = 4,	--生命
    EAT_SPEED = 5,	--速度
    EAT_HIT = 6,	--命中
    EAT_DODGE = 7,	--闪避
    EAT_CRIT = 8,	--暴击
    EAT_RESISIT_CRIT = 9,	--抗暴
    EAT_ATTACK_JIACHENG = 10,	--攻击加成
    EAT_DEFENSE_JIACHENG = 11,	--物防加成
    EAT_MD_JIACHENG = 12,	--法防加成
    EAT_HP_JIACHENG = 13,	--生命加成
    EAT_SPEED_JIACHENG = 14,	--速度加成
    EAT_HIT_RATE = 15,	--命中率
    EAT_DODGE_RATE = 16,	--闪避率
    EAT_CRIT_RATE = 17,	--暴击率
    EAT_RCRIT_RATE = 18,	--抗暴率
    EAT_DAMAGE_RATE = 19,	--增伤率
    EAT_WM_RATE = 20,	--物免率
    EAT_FM_RATE = 21,	--法免率
    EAT_CRIT_DAMAGE = 22,	--暴击伤害
    EAT_COUNTER_RATE = 23,	--反击率
    EAT_RCOUNTER_RATE = 24,	--抗反率
    EAT_COUNTER_DAMAGE = 25,	--反击伤害
    EAT_DOUBLE_RATE = 26,	--连击率
    EAT_RDOUBLE_RATE = 27,	--抗连率
    EAT_DOUBLE_DAMAGE = 28,	--连击伤害
    EAT_SHOCK_RATE = 29,	--反震率
    EAT_RSHOCK_RATE = 30,	--抗震率
    EAT_SHOCK_DAMAGE = 31,	--反震伤害
    EAT_FUMIANQIANGHUA = 32,	--负面强化
    EAT_FUMIANDIKANG = 33,	--负面抵抗
}

AppDef.EAttrTypeName = {
	[AppDef.EAttrType.EAT_ATTACK] = "攻击",
	[AppDef.EAttrType.EAT_DEFENSE] = "物防",
	[AppDef.EAttrType.EAT_MAGICD_EFENSE] = "法防",
	[AppDef.EAttrType.EAT_HP] = "生命",
	[AppDef.EAttrType.EAT_SPEED] = "速度",
	[AppDef.EAttrType.EAT_HIT] = "命中",
	[AppDef.EAttrType.EAT_DODGE] = "闪避",
	[AppDef.EAttrType.EAT_CRIT] = "暴击",
	[AppDef.EAttrType.EAT_RESISIT_CRIT] = "抗暴",
    [AppDef.EAttrType.EAT_ATTACK_JIACHENG] = "攻击",
    [AppDef.EAttrType.EAT_DEFENSE_JIACHENG] = "物防",
    [AppDef.EAttrType.EAT_MD_JIACHENG] = "法防",
    [AppDef.EAttrType.EAT_HP_JIACHENG] = "生命",
}

--[[
按照百分比显示的属性
]]
AppDef.EAttrRatioType = 
{
    AppDef.EAttrType.EAT_HIT_RATE,	--命中率
    AppDef.EAttrType.EAT_DODGE_RATE,	--闪避率
    AppDef.EAttrType.EAT_CRIT_RATE,	--暴击率
    AppDef.EAttrType.EAT_RCRIT_RATE,	--抗暴率
    AppDef.EAttrType.EAT_DAMAGE_RATE,	--增伤率
    AppDef.EAttrType.EAT_WM_RATE, 	--物免率
    AppDef.EAttrType.EAT_FM_RATE,	--法免率
    AppDef.EAttrType.EAT_CRIT_DAMAGE,	--暴击伤害
    AppDef.EAttrType.EAT_COUNTER_RATE,	--反击率
    AppDef.EAttrType.EAT_RCOUNTER_RATE,	--抗反率
    AppDef.EAttrType.EAT_COUNTER_DAMAGE,	--反击伤害
    AppDef.EAttrType.EAT_DOUBLE_RATE,	--连击率
    AppDef.EAttrType.EAT_RDOUBLE_RATE,	--抗连率
    AppDef.EAttrType.EAT_DOUBLE_DAMAGE,	--连击伤害
    AppDef.EAttrType.EAT_SHOCK_RATE,	--反震率
    AppDef.EAttrType.EAT_RSHOCK_RATE,	--抗震率
    AppDef.EAttrType.EAT_SHOCK_DAMAGE,	--反震伤害
    AppDef.EAttrType.EAT_FUMIANQIANGHUA,	--负面强化
    AppDef.EAttrType.EAT_FUMIANDIKANG,	--负面抵抗
}
--[[
神将成长
]]
AppDef.EAttrGrowType = 
{
	EAT_ATTACK_CHENGZHANG = 1,	--攻击成长
    EAT_DEFENSE_CHENGZHANG = 2,	--物防成长
    EAT_MD_CHENGZHANG= 3,	--法防成长
    EAT_HP_CHENGZHANG = 4,	--生命成长
    EAT_SPEED_CHENGZHANG = 5,	--速度成长
	EAT_HIT_CHENGZHANG = 6,	--命中成长
    EAT_DODGE_CHENGZHANG = 7,	--闪避成长
    EAT_CRIT_CHENGZHANG = 8,	--暴击成长
    EAT_RCRIT_CHENGZHANG = 9,	--抗暴成长
}

AppDef.EAttrGrowName = {
	[AppDef.EAttrGrowType.EAT_ATTACK_CHENGZHANG] = "攻击成长",
	[AppDef.EAttrGrowType.EAT_DEFENSE_CHENGZHANG] = "物防成长",
	[AppDef.EAttrGrowType.EAT_MD_CHENGZHANG] = "法防成长",
	[AppDef.EAttrGrowType.EAT_HP_CHENGZHANG] = "生命成长",
	[AppDef.EAttrGrowType.EAT_SPEED_CHENGZHANG] = "速度成长",
	[AppDef.EAttrGrowType.EAT_HIT_CHENGZHANG] = "命中成长",
	[AppDef.EAttrGrowType.EAT_DODGE_CHENGZHANG] = "闪避成长",
	[AppDef.EAttrGrowType.EAT_CRIT_CHENGZHANG] = "暴击成长",
	[AppDef.EAttrGrowType.EAT_RCRIT_CHENGZHANG] = "抗暴成长",
}

--[[
神将类型对应的资源
]]
AppDef.Pet.TypeRes = {
    "res/UI/ui_jingji/ui_shuxing_rou.png",
    "res/UI/ui_jingji/ui_shuxing_fa.png",
	"res/UI/ui_jingji/ui_shuxing_wu.png",
	"res/UI/ui_jingji/ui_shuxing_fu.png",
	"res/UI/ui_jingji/ui_shuxing_kong.png",
	"res/UI/ui_jingji/ui_shuxing_ling.png",
}

--[[
是否是概率属性
@param1:attrType,属性类别
@return:true是概率属性，false不是概率属性
]]
function AppDef:IsRatioAttr(attrType)
	for i = 1,#AppDef.EAttrRatioType do
		if AppDef.EAttrRatioType[i] == attrType then
			return true
		end
	end
	return false
end

--[[
显示宠物类型
]]
function AppDef:ShowPetType(imageView, petType)
	if petType < 1 then
		petType = 1
	elseif petType >= #AppDef.Pet.TypeRes then
		petType = #AppDef.Pet.TypeRes
	end
	local curRes = AppDef.Pet.TypeRes[petType]
    --imageView:ignoreContentAdaptWithSize(true)
    imageView:loadTexture(curRes,ccui.TextureResType.plistType)
end

------------------------坐骑相关-----------------------------
AppDef.Mount = {}
AppDef.Mount.MaxEnforceLv = 100--坐骑最大强化等级
AppDef.Mount.EnforceStoneIds = {2251,2252,2253,2254}--坐骑强化宝石
--AppDef.Mount.EnforceStoneIdToMoneys = {2,10,50,250}--强化宝石对应需求的金币，对应宝石使用每加一点经验要多少钱

--藏宝图ID
AppDef.CangBaotuIds = {2441,2442} --2441低阶藏宝图,2442高阶

--[[
货币类型
]]
AppDef.MoneyType = {
    JINBI 			= 1,--金币
    YUANBAO 		= 2,--元宝
    JINBI_BANG 		= 3,--绑定金币
    YUANBAO_BANG 	= 4,--绑定元宝
    COMPETE_POINTS 	= 5,--擂台积分
    BANGGONG       	= 6,--帮贡
    RENMINBI       	= 7,--人民币
    SHENHUN       	= 8,--神魂
    ZADAN_POINTS  	= 9,--砸蛋积分
}
--[[
获取货币图片
]]
function AppDef:GetMoneyIcon(moneyType)
    local str = ""
    if moneyType == AppDef.MoneyType.YUANBAO then
        str = "res/UI/ui_common/ui_icon_yuanbao.png"
    elseif moneyType == AppDef.MoneyType.YUANBAO_BANG then
        str = "res/UI/ui_common/ui_icon_bangyuan.png"
    elseif moneyType == AppDef.MoneyType.JINBI then
        str = "res/UI/ui_common/ui_icon_jinbi.png"
    elseif moneyType == AppDef.MoneyType.JINBI_BANG then
        str = "res/UI/ui_common/ui_icon_jinbi.png"
    elseif moneyType == AppDef.MoneyType.RENMINBI then
        str = "res/UI/ui_common/ui_icon_renminbi.png"
    elseif moneyType == AppDef.MoneyType.BANGGONG then
        str = "res/UI/ui_bangpai/ui_icon_bangpai_banggong.png"
    elseif moneyType == AppDef.MoneyType.SHENHUN then
        str = "res/UI/ui_common/ui_icon_shenjiang_shenhun.png"
    elseif moneyType == AppDef.MoneyType.COMPETE_POINTS then
        str = "res/UI/ui_common/ui_icon_jifen.png"
	elseif moneyType == AppDef.MoneyType.ZADAN_POINTS then
        str = "res/UI/ui_huodong/ui_icon_wuseshi.png"
    end
    return str
end

function AppDef:GetMoneyIconById(ItemId)
	-- body
	AppDef.spriteFrameCache:addSpriteFrames("csd/Plist/ui_huobi.plist", "csd/Plist/ui_huobi.png")
	local itemData = JsonConfig.m_Item.getDefByID(ItemId)
	if itemData == nil then
		return "res/UI/Icon/ui_huobi_icon/huobi_3006.png"
	end
	return "res/UI/Icon/ui_huobi_icon/huobi_" .. itemData.pic .. ".png"
end

function AppDef:GetQualityColorKuang( quality )
	-- body
	if quality <= 0 or quality > 7 then
		return "res/UI/ui_common_new2/ui_shenjiangbeibao_kapai_kuang_01.png"
	end
	return "res/UI/ui_common_new2/ui_shenjiangbeibao_kapai_kuang_0" .. tostring(quality) .. ".png"
end

AppDef.ServerSetIndex = 
{
	SSI_FINISH_GUIDE = 67,     --已完成新手引导(大步骤-ID/100)
	SSI_FIRST_BATTLE = 68,     --首次战斗
	SSI_CURRENT_GUIDE = 69,     --当前新手引导ID
	SSI_FIRST_OPEN_SC = 70,     --首次开启首冲
	SSI_FIRST_GET_ZB = 71,     --首次获得装备
	SSI_FIGHT_SPEED = 72,     --战斗速度
	SSI_CUR_PRE_FUNC = 73,     --当前功能预告步骤ID
	SSI_SAVED_VAL_MAX=100,
	---------------------下面的只是客户端使用不传到服务端的数据---------------------
	SSI_FIRST_SHOW_SC = 101,     --首次显示首冲
	SSI_FIRST_SHOW_CC = 102,     --首次显示次冲
}

AppDef.PetMap = {}
for i=1,40 do
	AppDef.PetMap[2400+i] = 9+i
end