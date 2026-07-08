local PetUIDef = {}
PetUIDef.MainTitle = GUITips.UI_Title_Shenjiang
PetUIDef.Tab = {
    Info = 1,     --信息
    Skill = 2,    --技能
    Upgrade = 3,  --升星
    Equip = 4,    --装备
    Xiulian = 5,  --修炼
}

PetUIDef.TabNames = 
{
	GUITips.UI_Shenjiang_TabName1,
    GUITips.UI_Shenjiang_TabName2,
    GUITips.UI_Shenjiang_TabName3,
    GUITips.UI_Shenjiang_TabName4,
    GUITips.UI_Shenjiang_TabName5,
    GUITips.UI_Shenjiang_TabName6,
}

PetUIDef.SubUIPaths = 
{
	"View.Pet.PetInfoSubUI",
	"View.Pet.PetSkillSubUI",
	"View.Pet.PetUpgradeSubUI",
    "View.Pet.PetEquipSubUI",
	"View.Pet.PetXiulianSubUI",
    "View.Pet.PetFormationSubUI",
}

PetUIDef.EquipPos = 
{
    PEPWuqi = 1,--武器
    PEPHujian = 2,--护肩
    PEPYifu = 3,--衣服
    PEPHuwan = 4,--护腕
    PEPJiezhi = 5,--戒指
    PEPXiezi = 6,--鞋子
}

--装备部位开启等级
PetUIDef.EquipPosOpenLv = 
{
    55,
    55,
    60,
    60,
    65,
    65,
}

return PetUIDef