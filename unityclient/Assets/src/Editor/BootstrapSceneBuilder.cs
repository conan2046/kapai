using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Xml.Linq;
using ProjectX.Core;
using ProjectX.UI;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

namespace ProjectX.Editor
{
    public static class BootstrapSceneBuilder
    {
        private const string BootstrapScene = "Assets/Scenes/Bootstrap.unity";
        private const string FirstPlayableScene = "Assets/Scenes/FirstPlayableLoop.unity";
        private const string LoginBackgroundPrefab = "Assets/Prefabs/Login/LoginBgLayer.prefab";
        private const string LoginPrefab = "Assets/Prefabs/Login/loginLayer.prefab";
        private const string LoginServerListPrefab = "Assets/Prefabs/Login/SeverListLayer.prefab";
        private const string RoleCreatePrefab = "Assets/Prefabs/Login/RoleCreateLayer.prefab";
        private const string OldMemoryPrefab = "Assets/Prefabs/Login/OldMemoryLayer.prefab";
        private const string NoticePrefab = "Assets/Prefabs/Login/NoticeLayer.prefab";
        private const string StartupPrefab = "Assets/Prefabs/Login/StartupLayer.prefab";
        private const string MainPrefab = "Assets/Prefabs/Main/UImainLayer_new.prefab";
        private const string MainCloudPrefab = "Assets/Prefabs/Main/UImain_cloudLayer.prefab";
        private const string BagPrefab = "Assets/Prefabs/Bag/beibao.prefab";
        private const string BagInputPrefab = "Assets/Prefabs/Common/EnterNumLayer.prefab";
        private const string BagGiftPrefab = "Assets/Prefabs/Bag/OpenBox_1Layer.prefab";
        private const string SettingsPrefab = "Assets/Prefabs/Settings/SystemLayer.prefab";
        private const string TaskBackgroundPrefab = "Assets/Prefabs/Task/huodong_bg.prefab";
        private const string TaskPrefab = "Assets/Prefabs/Task/RenwuLayer.prefab";
        private const string ErrorPrefab = "Assets/Prefabs/Login/MessageBoxLayer.prefab";
        private const string RewardPrefab = "Assets/Prefabs/Common/tanchuangjiangli.prefab";
        private const string HeroFramePrefab = "Assets/Prefabs/Retained/OneLevelLayer.prefab";
        private const string JingJiePrefab = "Assets/Prefabs/OneLevel/JingjieLayer.prefab";
        private const string JingJiePreviewPrefab = "Assets/Prefabs/OneLevel/Jingjieyulan.prefab";
        private const string HeroListPrefab = "Assets/Prefabs/Hero/yingxiongListLayer.prefab";
        private const string HeroDetailPrefab = "Assets/Prefabs/Hero/yingxiongInfoLayer.prefab";
        private const string HeroReplacementPrefab = "Assets/Prefabs/Hero/Equipment/yingxionghuanjiang.prefab";
        private const string HeroCultivationPrefab = "Assets/Prefabs/Hero/Cultivation/yingxiongjueseLayer.prefab";
        private const string HeroLevelUpPrefab = "Assets/Prefabs/Hero/Cultivation/yingxiongshuxingLayer.prefab";
        private const string HeroAutoLevelUpPrefab = "Assets/Prefabs/Hero/Cultivation/yingxiongshengjiScene1.prefab";
        private const string HeroStarUpPrefab = "Assets/Prefabs/Hero/Cultivation/yingxiongshengxingLayer.prefab";
        private const string HeroBreakUpPrefab = "Assets/Prefabs/Hero/Cultivation/yingxiongtupoLayer.prefab";
        private const string HeroTrainingPrefab = "Assets/Prefabs/Hero/Cultivation/yingxiongxiulian.prefab";
        private const string HeroInfoPrefab = "Assets/Prefabs/Hero/Cultivation/yingxiongxinxiLayer.prefab";
        private const string HeroTalentPrefab = "Assets/Prefabs/Hero/Cultivation/yingxiongtianfuLayer.prefab";
        private const string HeroTrainingHelpPrefab = "Assets/Prefabs/Hero/Cultivation/yingxiongxiulian2.prefab";
        private const string HeroTrainingAttributePrefab = "Assets/Prefabs/Hero/Cultivation/yingxiongxiulian3.prefab";
        private const string HeroEnhanceMasterPrefab = "Assets/Prefabs/Hero/Equipment/qianghuadashi.prefab";
        private const string HeroAttributesPrefab = "Assets/Prefabs/Hero/Cultivation/shenjiangxiangxishuxing.prefab";
        private const string HeroItemSourcePrefab = "Assets/Prefabs/Bag/huoqutujing.prefab";
        private const string HeroBagPrefab = "Assets/Prefabs/Hero/yingxiongbeibao.prefab";
        private const string HeroBookPrefab = "Assets/Prefabs/Hero/Book/yingxiongtujianLayer.prefab";
        private const string HeroBookUpgradePrefab = "Assets/Prefabs/Hero/Book/yingxiongtujianupLayer.prefab";
        private const string HeroBookActivateResultPrefab = "Assets/Prefabs/Hero/Book/yingxiongtujianendLayer.prefab";
        private const string HeroBookUpgradeResultPrefab = "Assets/Prefabs/Hero/Book/yingxiongtujianupendLayer.prefab";
        private const string HeroBookAttributesPrefab = "Assets/Prefabs/Hero/Book/yingxiongtujianshuxingLayer.prefab";
        private const string HeroBookAchievementsPrefab = "Assets/Prefabs/Hero/Book/yingxiongtujianchengjiuLayer.prefab";
        private const string HeroBookLevelResultPrefab = "Assets/Prefabs/Hero/Book/yingxiongjihuoendLayer.prefab";
        private const string HeroRecyclePrefab = "Assets/Prefabs/Hero/Rebirth/shenjiangchongsheng.prefab";
        private const string HeroRebirthChoosePrefab = "Assets/Prefabs/Hero/Rebirth/Choose.prefab";
        private const string HeroRebirthConfirmPrefab = "Assets/Prefabs/Hero/Rebirth/Popup_Confirm.prefab";
        private const string DynamicUiResourceDirectory = "Assets/Resources/UiPrefabs";
        private const string DynamicUiCatalog = DynamicUiResourceDirectory + "/Catalog.asset";
        private const string EnhanceMasterSuccessPopupPrefab = "Assets/Prefabs/EnhanceMaster/EnhanceMasterSuccessPopup.prefab";
        private const string PlayerLevelUpPopupPrefab = "Assets/Prefabs/Catalog/PlayerLevelUpPopup.prefab";
        private const string FormationPopupPrefab = "Assets/Prefabs/Retained/shenjiangyangcheng/shenjiangzhenxingLayer.prefab";
        private const string HeroEquipmentListPrefab = "Assets/Prefabs/Hero/Equipment/zhuangbeibeibao.prefab";
        private const string HeroEquipmentDetailPrefab = "Assets/Prefabs/Hero/Equipment/zhuangbeiInfo.prefab";
        private const string HeroEquipmentChangePrefab = "Assets/Prefabs/Hero/Equipment/zhuangbeigenghuan.prefab";
        private const string HeroEquipmentCultivatePrefab = "Assets/Prefabs/Hero/Equipment/zhuangbeiyangcheng.prefab";
        private const string HeroEquipmentStrengthPrefab = "Assets/Prefabs/Hero/Equipment/zhuangbeiqianghua.prefab";
        private const string HeroEquipmentRefinePrefab = "Assets/Prefabs/Hero/Equipment/zhuangbeijinglian.prefab";
        private const string HeroEquipmentAwakenPrefab = "Assets/Prefabs/Hero/Equipment/zhuangbeijuexing.prefab";
        private const string HeroEquipmentDivinePrefab = "Assets/Prefabs/Hero/Equipment/zhuangbeishenzhu.prefab";
        private const string HeroEquipmentFragmentPrefab = "Assets/Prefabs/Hero/Equipment/zhuangbeisuipian.prefab";
        private const string HeroEquipmentAutoRefinePrefab = "Assets/Prefabs/Hero/Equipment/yijianjinglian.prefab";
        private const string HeroEquipmentExchangePrefab = "Assets/Prefabs/Hero/Equipment/yijianduihuan.prefab";
        private const string HeroEquipmentAutoStarPrefab = "Assets/Prefabs/Hero/Equipment/yijianshengxing.prefab";
        private const string HeroEquipmentAutoDivinePrefab = "Assets/Prefabs/Hero/Equipment/yijianshengceng.prefab";
        private const string HeroEquipmentDivineEffectPrefab = "Assets/Prefabs/Hero/Equipment/shenzhutexiao.prefab";
        private const string FaBaoStrengthPrefab = "Assets/Prefabs/Hero/Equipment/fabaoqianghua.prefab";
        private const string FaBaoRefinePrefab = "Assets/Prefabs/Hero/Equipment/fabaojinglian.prefab";
        private const string FaBaoMaterialChooserPrefab = "Assets/Prefabs/Hero/Equipment/Choose_fenjie.prefab";
        private const string LoadingPrefab = "Assets/Prefabs/Login/LoadingLayer.prefab";
        private const string MailPrefab = "Assets/Prefabs/Mail/MailLayer.prefab";
        private const string ShopPrefab = "Assets/Prefabs/Shop/shangcheng.prefab";
        private const string SoulShopPrefab = "Assets/Prefabs/Shop/jianghunshop.prefab";
        private const string GameplayShopItemInfoPrefab = "Assets/Prefabs/Shop/SourceLayer.prefab";
        private const string MultiShopPrefab = "Assets/Prefabs/Shop/wanfashop.prefab";
        private const string FriendPrefab = "Assets/Prefabs/Retained/common/FriendLayer.prefab";
        private const string ChatMiniPrefab = "Assets/Prefabs/Retained/ChatLayer.prefab";
        private const string ChatPrefab = "Assets/Prefabs/Retained/MainChatLayer.prefab";
        private const string TeamMembersPrefab = "Assets/Prefabs/Retained/TeamMembersLayer.prefab";
        private const string TeamInvitePrefab = "Assets/Prefabs/Retained/TeamInviteListLayer.prefab";
        private const string GuildListPrefab = "Assets/Prefabs/Retained/bangpai/GangsApplyLayer.prefab";
        private const string GuildInfoPrefab = "Assets/Prefabs/Retained/bangpai/GangsLayer.prefab";
        private const string GuildMemberPrefab = "Assets/Prefabs/Retained/bangpai/GangsMemberLayer.prefab";
        private const string GuildCreatePrefab = "Assets/Prefabs/Retained/bangpai/GangsfoundLayer.prefab";
        private const string WorldPrefab = "Assets/Prefabs/World/WorldMapNewLayer.prefab";
        private const string WorldStagePrefab = "Assets/Prefabs/World/kapaiguaiwuLayer.prefab";
        private const string WorldMapPrefab = "Assets/Prefabs/World/DadituuiLayer.prefab";
        private const string WorldDetailPrefab = "Assets/Prefabs/World/guanqiaxiangxiLayer.prefab";
        private const string WorldSweepPrefab = "Assets/Prefabs/World/saodangLayer.prefab";
        private const string WorldBattleResultPrefab = "Assets/Prefabs/World/zhandoujiesuanLayer.prefab";
        private const string WorldBattleStatisticsPrefab = "Assets/Prefabs/World/zhandoutongji.prefab";
        private const string BattleFightLayerPrefab = "Assets/Prefabs/Battle/BattleFightLayer.prefab";
        private const string BattleHpNodePrefab = "Assets/Prefabs/Battle/BattleHpNode.prefab";
        private const string WorldBoxAwardPrefab = "Assets/Prefabs/World/guaiwubaoxiangLayer.prefab";
        private const string WorldBattleStatisticsFramePrefab = "Assets/Prefabs/World/WorldBattleStatisticsFrame.prefab";
        private const string WorldAchievementPrefab = "Assets/Prefabs/World/zhuxianchengjiu.prefab";
        private const string WelfarePrefab = "Assets/Prefabs/Retained/WelfareLayer.prefab";
        private const string WelfareSignPrefab = "Assets/Prefabs/Retained/SignLayer.prefab";
        private const string WelfareOnlinePrefab = "Assets/Prefabs/Retained/huodong/LoginGiftLayer.prefab";
        private const string ActivityRootPrefab = "Assets/Prefabs/Retained/huodong/ActivityRankingLayer.prefab";
        private const string ActivityBackgroundPrefab = "Assets/Prefabs/Retained/huodong/ActivityLevelLayer.prefab";
        private const string ActivityDailyRechargePrefab = "Assets/Prefabs/Retained/DailyChargeLayer.prefab";
        private const string DrawPrefab = "Assets/Prefabs/Draw/shenjiangzhaomu.prefab";
        private const string DrawSingleResultPrefab = "Assets/Prefabs/Draw/dancichouka.prefab";
        private const string DrawTenResultPrefab = "Assets/Prefabs/Draw/shilianchouka.prefab";
        private const string DrawPreviewPrefab = "Assets/Prefabs/Draw/jiangliyulan.prefab";
        private const string DrawHeroPreviewPrefab = "Assets/Prefabs/Draw/shenjiangyulan.prefab";
        private const string DrawExchangePrefab = "Assets/Prefabs/Draw/daojuduihuan.prefab";
        private const string GameplayFramePrefab = "Assets/Prefabs/Common/shop_bg.prefab";
        private const string GameplayPrefab = "Assets/Prefabs/Gameplay/ActivityLayer.prefab";
        private const string MoneyTreePrefab = "Assets/Prefabs/Gameplay/MoneyTree/GoldTreeLayer.prefab";
        private const string HappyWheelPrefab = "Assets/Prefabs/Gameplay/HappyWheel/ZhuanpanLayer.prefab";
        private const string MonopolyPrefab = "Assets/Prefabs/Gameplay/Monopoly/GameSceneLayer.prefab";
        private const string AnswerPrefab = "Assets/Prefabs/Gameplay/Answer/AnswerLayer.prefab";
        private const string MonopolyHudPrefab = "Assets/Prefabs/Gameplay/Monopoly/GameLayer.prefab";
        private const string MonopolyHandPrefab = "Assets/Prefabs/Gameplay/Monopoly/caiquanLayer.prefab";
        private const string YouLiPrefab = "Assets/Prefabs/Gameplay/YouLi/youlisanjie.prefab";
        private const string YouLiDetailPrefab = "Assets/Prefabs/Retained/youli/youli.prefab";
        private const string YouLiOneKeyPrefab = "Assets/Prefabs/Retained/youli/yijianyouli.prefab";
        private const string YouLiModePrefab = "Assets/Prefabs/Retained/youli/youlifangshi.prefab";
        private const string YouLiTimePrefab = "Assets/Prefabs/Retained/youli/youlishichang.prefab";
        private const string FengShenStoryPrefab = "Assets/Prefabs/Effects/Common/FengShenStory/Prefabs/fengshenliezhuanlLayer.prefab";
        private const string FengShenStoryLevelPrefab = "Assets/Prefabs/Effects/Common/FengShenStory/Prefabs/fengshenliezhuanlevel.prefab";
        private const string ArenaPrefab = "Assets/Prefabs/Retained/common/JingjiLayer.prefab";
        private const string KunLunPrefab = "Assets/Prefabs/Retained/kunlun/juezhankunlun.prefab";
        private const string BloodFightPrefab = "Assets/Prefabs/Retained/xuezhan/XuezhanMain.prefab";
        private const string XunBaoPrefab = "Assets/Prefabs/XunBao/XunbaoLayer.prefab";
        private const string XunBaoPopupPrefab = "Assets/Prefabs/XunBao/Xunbao_popupLayer.prefab";
        private const string XunBaoResultPrefab = "Assets/Prefabs/XunBao/Xunbao_souxunLayer.prefab";
        private const string XunBaoComposeAllPrefab = "Assets/Prefabs/XunBao/saodang.prefab";
        private const string SevenDayPrefab = "Assets/Prefabs/Retained/huodong/QiriLayer.prefab";
        private const string StaminaClaimPrefab = "Assets/Prefabs/Retained/huodong/tililingquLayer.prefab";
        private const string ResourceRecoveryPrefab = "Assets/Prefabs/Retained/huodong/ziyuanzhaohui.prefab";
        private const string GrowthFundPrefab = "Assets/Prefabs/Retained/huodong/ChengZhangLayer.prefab";
        private const string ActiveFundPrefab = "Assets/Prefabs/Retained/huodong/HuoyueLayer.prefab";

        private readonly struct PrefabSpec
        {
            public PrefabSpec(string path, bool active, string parentPath = null)
            {
                Path = path;
                Active = active;
                ParentPath = parentPath;
            }

            public string Path { get; }
            public bool Active { get; }
            public string ParentPath { get; }
        }

        private static readonly HashSet<string> UnityOwnedPrefabPaths = new HashSet<string>(System.StringComparer.OrdinalIgnoreCase)
        {
            RewardPrefab,
            YouLiPrefab,
            GameplayFramePrefab,
            GameplayPrefab,
            MoneyTreePrefab,
            HappyWheelPrefab,
            HeroRecyclePrefab,
            HeroRebirthChoosePrefab,
            HeroRebirthConfirmPrefab,
            HeroBookPrefab,
            HeroBookUpgradePrefab,
            HeroBookActivateResultPrefab,
            HeroBookUpgradeResultPrefab,
            HeroBookAttributesPrefab,
            HeroBookAchievementsPrefab,
            HeroBookLevelResultPrefab,
            HeroCultivationPrefab,
            HeroLevelUpPrefab,
            HeroAutoLevelUpPrefab,
            HeroStarUpPrefab,
            HeroBreakUpPrefab,
            HeroTrainingPrefab,
            HeroInfoPrefab,
            HeroTalentPrefab,
            HeroTrainingHelpPrefab,
            HeroTrainingAttributePrefab,
            HeroAttributesPrefab,
            BagInputPrefab,
            AnswerPrefab,
            DrawPrefab,
            DrawPreviewPrefab,
            DrawHeroPreviewPrefab,
            DrawExchangePrefab,
            TaskBackgroundPrefab,
            TaskPrefab,
            ShopPrefab,
            SoulShopPrefab,
            MultiShopPrefab,
            FaBaoMaterialChooserPrefab,
            FaBaoRefinePrefab,
            FaBaoStrengthPrefab,
            HeroEquipmentAutoDivinePrefab,
            HeroEquipmentAutoRefinePrefab,
            HeroEquipmentAutoStarPrefab,
            HeroEquipmentAwakenPrefab,
            HeroEquipmentChangePrefab,
            HeroEquipmentCultivatePrefab,
            HeroEquipmentDetailPrefab,
            HeroEquipmentDivinePrefab,
            HeroEquipmentDivineEffectPrefab,
            HeroEquipmentExchangePrefab,
            HeroEquipmentFragmentPrefab,
            HeroEquipmentListPrefab,
            HeroEquipmentRefinePrefab,
            HeroEquipmentStrengthPrefab,
            HeroEnhanceMasterPrefab,
            HeroReplacementPrefab,
            GameplayShopItemInfoPrefab,
            "Assets/Prefabs/Gameplay/Monopoly/GameSceneLayer.prefab",
            "Assets/Prefabs/Gameplay/Monopoly/GameLayer.prefab",
            "Assets/Prefabs/Gameplay/Monopoly/caiquanLayer.prefab",
            LoginBackgroundPrefab,
            LoginPrefab,
            LoginServerListPrefab,
            RoleCreatePrefab,
            OldMemoryPrefab,
            NoticePrefab,
            StartupPrefab,
            SettingsPrefab,
            ErrorPrefab,
            LoadingPrefab,
            EnhanceMasterSuccessPopupPrefab,
            PlayerLevelUpPopupPrefab,
            MailPrefab,
            MainPrefab,
            MainCloudPrefab,
            BattleFightLayerPrefab,
            BattleHpNodePrefab,
            "Assets/Prefabs/Fish/FishLayer.prefab",
            XunBaoComposeAllPrefab,
            XunBaoResultPrefab,
            XunBaoPrefab,
            XunBaoPopupPrefab,
            DrawSingleResultPrefab,
            DrawTenResultPrefab,
            WorldAchievementPrefab,
            WorldPrefab,
            WorldStagePrefab,
            WorldMapPrefab,
            WorldDetailPrefab,
            WorldSweepPrefab,
            WorldBattleResultPrefab,
            WorldBattleStatisticsPrefab,
            WorldBoxAwardPrefab,
            WorldBattleStatisticsFramePrefab,
            "Assets/Prefabs/Hero/shenjiangzhenxingLayer.prefab",
            HeroItemSourcePrefab,
            HeroListPrefab,
            HeroDetailPrefab,
            HeroBagPrefab,
        };
        private static readonly string[] UnityOwnedResourceRoots =
        {
            "Assets/Art/",
            "Assets/Animations/",
            "Assets/Prefabs/",
            "Assets/Resources/AssetReferences/",
            "Assets/UnityOwned/WorldBattle/",
        };

        private static readonly PrefabSpec[] PrefabSpecs =
        {
            new PrefabSpec(LoginBackgroundPrefab, true),
            new PrefabSpec(LoginPrefab, true),
            new PrefabSpec(LoginServerListPrefab, false),
            new PrefabSpec(RoleCreatePrefab, false),
            new PrefabSpec(OldMemoryPrefab, false),
            new PrefabSpec(NoticePrefab, false),
            new PrefabSpec(StartupPrefab, false),
            new PrefabSpec(MainPrefab, false),
            new PrefabSpec(MainCloudPrefab, false),
            new PrefabSpec(BagPrefab, false, HeroFramePrefab),
            new PrefabSpec(BagInputPrefab, false),
            new PrefabSpec(BagGiftPrefab, false),
            new PrefabSpec(SettingsPrefab, false),
            new PrefabSpec(TaskBackgroundPrefab, false),
            new PrefabSpec(TaskPrefab, true, TaskBackgroundPrefab),
            new PrefabSpec(StaminaClaimPrefab, false, TaskBackgroundPrefab),
            new PrefabSpec(ResourceRecoveryPrefab, false, TaskBackgroundPrefab),
            new PrefabSpec(GrowthFundPrefab, false, TaskBackgroundPrefab),
            new PrefabSpec(ActiveFundPrefab, false, TaskBackgroundPrefab),
            new PrefabSpec(RewardPrefab, false),
            new PrefabSpec(MailPrefab, false),
            new PrefabSpec(ShopPrefab, false, GameplayFramePrefab),
            new PrefabSpec(SoulShopPrefab, false, GameplayFramePrefab),
            new PrefabSpec(GameplayShopItemInfoPrefab, false),
            new PrefabSpec(MultiShopPrefab, false),
            new PrefabSpec(FriendPrefab, false),
            new PrefabSpec(ChatMiniPrefab, false),
            new PrefabSpec(ChatPrefab, false),
            new PrefabSpec(TeamMembersPrefab, false),
            new PrefabSpec(TeamInvitePrefab, false),
            new PrefabSpec(GuildListPrefab, false),
            new PrefabSpec(GuildInfoPrefab, false),
            new PrefabSpec(GuildMemberPrefab, false),
            new PrefabSpec(GuildCreatePrefab, false),
            new PrefabSpec(WorldPrefab, false),
            new PrefabSpec(WorldStagePrefab, false),
            new PrefabSpec(WorldMapPrefab, false),
            new PrefabSpec(WorldDetailPrefab, false),
            new PrefabSpec(WorldSweepPrefab, false),
            new PrefabSpec(WorldBattleResultPrefab, false),
            new PrefabSpec(WorldBattleStatisticsPrefab, false),
            new PrefabSpec(WorldBoxAwardPrefab, false),
            new PrefabSpec(WorldAchievementPrefab, false),
            new PrefabSpec(WorldBattleStatisticsFramePrefab, false),
            new PrefabSpec(WelfarePrefab, false),
            new PrefabSpec(WelfareSignPrefab, false),
            new PrefabSpec(WelfareOnlinePrefab, false),
            new PrefabSpec(ActivityRootPrefab, false),
            new PrefabSpec(ActivityBackgroundPrefab, true, ActivityRootPrefab),
            new PrefabSpec(ActivityDailyRechargePrefab, true, ActivityRootPrefab),
            new PrefabSpec(DrawPrefab, false),
            new PrefabSpec(DrawSingleResultPrefab, true, DrawPrefab),
            new PrefabSpec(DrawTenResultPrefab, true, DrawPrefab),
            new PrefabSpec(DrawPreviewPrefab, false, DrawPrefab),
            new PrefabSpec(DrawHeroPreviewPrefab, false, DrawPrefab),
            new PrefabSpec(DrawExchangePrefab, false),
            // Gameplay uses shop_bg as a root-level bottom frame. It must not
            // be composed under OneLevelLayer: the gameplay ActivityLayer is a
            // sibling surface, while Panel_12/GoldCheck belong only to Hero/Bag.
            new PrefabSpec(GameplayFramePrefab, false),
            new PrefabSpec(GameplayPrefab, true),
            new PrefabSpec(MoneyTreePrefab, false),
            new PrefabSpec(HappyWheelPrefab, false),
            new PrefabSpec(MonopolyPrefab, false),
            new PrefabSpec(MonopolyHudPrefab, false),
            new PrefabSpec(MonopolyHandPrefab, false),
            new PrefabSpec(YouLiPrefab, false),
            new PrefabSpec(YouLiDetailPrefab, false),
            new PrefabSpec(YouLiOneKeyPrefab, false),
            new PrefabSpec(YouLiModePrefab, false),
            new PrefabSpec(YouLiTimePrefab, false),
            new PrefabSpec(FengShenStoryPrefab, false),
            new PrefabSpec(FengShenStoryLevelPrefab, false),
            new PrefabSpec(ArenaPrefab, false),
            new PrefabSpec(KunLunPrefab, false),
            new PrefabSpec(BloodFightPrefab, false),
            new PrefabSpec(XunBaoPrefab, false),
            new PrefabSpec(XunBaoPopupPrefab, false),
            new PrefabSpec(XunBaoResultPrefab, false),
            new PrefabSpec(XunBaoComposeAllPrefab, false),
            new PrefabSpec(SevenDayPrefab, false),
            new PrefabSpec(HeroFramePrefab, false),
            new PrefabSpec(HeroListPrefab, false, HeroFramePrefab),
            new PrefabSpec(HeroDetailPrefab, false, HeroFramePrefab),
            new PrefabSpec(HeroBagPrefab, false, HeroFramePrefab),
            new PrefabSpec(HeroCultivationPrefab, false, HeroFramePrefab),
            new PrefabSpec(HeroLevelUpPrefab, false, HeroFramePrefab),
            new PrefabSpec(HeroAutoLevelUpPrefab, false, HeroFramePrefab),
            new PrefabSpec(HeroStarUpPrefab, false, HeroFramePrefab),
            new PrefabSpec(HeroBreakUpPrefab, false, HeroFramePrefab),
            new PrefabSpec(HeroTrainingPrefab, false, HeroFramePrefab),
            new PrefabSpec(HeroInfoPrefab, false, HeroFramePrefab),
            new PrefabSpec(HeroTalentPrefab, false, HeroFramePrefab),
            new PrefabSpec(HeroTrainingHelpPrefab, false, HeroFramePrefab),
            new PrefabSpec(HeroTrainingAttributePrefab, false, HeroFramePrefab),
            new PrefabSpec(HeroReplacementPrefab, false),
            new PrefabSpec(HeroAttributesPrefab, false),
            new PrefabSpec(HeroItemSourcePrefab, false),
            new PrefabSpec(FormationPopupPrefab, false)
        };

        private static readonly PrefabSpec[] DynamicOnlyPrefabSpecs =
        {
            new PrefabSpec(ErrorPrefab, false),
            new PrefabSpec(LoadingPrefab, false),
            new PrefabSpec(JingJiePrefab, false, HeroFramePrefab),
            new PrefabSpec(JingJiePreviewPrefab, false, HeroFramePrefab),
            new PrefabSpec(HeroBookPrefab, false),
            new PrefabSpec(HeroBookUpgradePrefab, false),
            new PrefabSpec(HeroBookActivateResultPrefab, false),
            new PrefabSpec(HeroBookUpgradeResultPrefab, false),
            new PrefabSpec(HeroBookAttributesPrefab, false),
            new PrefabSpec(HeroBookAchievementsPrefab, false),
            new PrefabSpec(HeroBookLevelResultPrefab, false),
            new PrefabSpec(HeroRecyclePrefab, false),
            new PrefabSpec(AnswerPrefab, false),
            new PrefabSpec(HeroRebirthChoosePrefab, false),
            new PrefabSpec(HeroRebirthConfirmPrefab, false),
            new PrefabSpec(HeroEnhanceMasterPrefab, false),
            new PrefabSpec(EnhanceMasterSuccessPopupPrefab, false),
            new PrefabSpec(HeroEquipmentListPrefab, false),
            new PrefabSpec(HeroEquipmentDetailPrefab, false),
            new PrefabSpec(HeroEquipmentChangePrefab, false),
            new PrefabSpec(HeroEquipmentCultivatePrefab, false),
            new PrefabSpec(HeroEquipmentStrengthPrefab, false),
            new PrefabSpec(HeroEquipmentRefinePrefab, false),
            new PrefabSpec(HeroEquipmentAwakenPrefab, false),
            new PrefabSpec(HeroEquipmentDivinePrefab, false),
            new PrefabSpec(HeroEquipmentFragmentPrefab, false),
            new PrefabSpec(HeroEquipmentAutoRefinePrefab, false),
            new PrefabSpec(HeroEquipmentExchangePrefab, false),
            new PrefabSpec(HeroEquipmentAutoStarPrefab, false),
            new PrefabSpec(HeroEquipmentAutoDivinePrefab, false),
            new PrefabSpec(HeroEquipmentDivineEffectPrefab, false),
            new PrefabSpec(FaBaoStrengthPrefab, false),
            new PrefabSpec(FaBaoRefinePrefab, false),
            new PrefabSpec(FaBaoMaterialChooserPrefab, false),
            new PrefabSpec(BattleFightLayerPrefab, false),
            new PrefabSpec(BattleHpNodePrefab, false)
        };

        [MenuItem("Tools/ProjectX 应用/确保 Bootstrap 场景", priority = 90)]
        public static void Build()
        {
            EnsureDynamicUiCatalog();
            EnsureDrawDynamicResources();
            if (IsBootstrapSceneCurrent())
            {
                NormalizeBootstrapSceneYaml();
                EnsureBuildSettings();
                AssetDatabase.SaveAssets();
                Debug.Log("[ProjectXApp] Bootstrap scene semantic signature unchanged; rebuild skipped.");
                return;
            }

            Rebuild();
        }

        private static void EnsureDynamicUiCatalog()
        {
            EnsureAssetFolder(DynamicUiResourceDirectory);
            PrefabSpec[] all = PrefabSpecs.Concat(DynamicOnlyPrefabSpecs).ToArray();
            var entries = new List<UiPrefabCatalogEntry>(all.Length);
            foreach (PrefabSpec spec in all)
            {
                string key = GetDynamicKey(spec.Path);
                EnsureDynamicUiReference(key, spec.Path);
                string source = ResolveCatalogSource(spec.Path, key);
                entries.Add(new UiPrefabCatalogEntry(key, source,
                    string.IsNullOrWhiteSpace(spec.ParentPath) ? null : GetDynamicKey(spec.ParentPath),
                    spec.Active));
            }
            string duplicateKey = entries.GroupBy(entry => entry.Key, System.StringComparer.OrdinalIgnoreCase)
                .FirstOrDefault(group => group.Count() > 1)?.Key;
            if (!string.IsNullOrEmpty(duplicateKey))
                throw new InvalidDataException($"Duplicate UI prefab catalog key: {duplicateKey}");
            UiPrefabCatalog catalog = AssetDatabase.LoadAssetAtPath<UiPrefabCatalog>(DynamicUiCatalog);
            if (catalog == null)
            {
                catalog = ScriptableObject.CreateInstance<UiPrefabCatalog>();
                AssetDatabase.CreateAsset(catalog, DynamicUiCatalog);
            }
            catalog.Replace(entries.OrderBy(entry => entry.Key, System.StringComparer.OrdinalIgnoreCase));
            EditorUtility.SetDirty(catalog);
            AssetDatabase.SaveAssetIfDirty(catalog);
            NormalizeUnityYaml(DynamicUiCatalog);
        }

        private static string ResolveCatalogSource(string prefabPath, string key)
        {
            if (!IsUnityOwnedPrefabPath(prefabPath))
                throw new InvalidDataException($"UI Catalog requires a Unity-owned Prefab: {prefabPath}");
            return $"Unity/{key}";
        }

        internal static bool IsUnityOwnedPrefabPath(string prefabPath)
        {
            if (string.IsNullOrWhiteSpace(prefabPath)) return false;
            string normalized = prefabPath.Replace('\\', '/');
            return HasSafeAssetPathSegments(normalized)
                   && (normalized.StartsWith("Assets/Prefabs/", System.StringComparison.OrdinalIgnoreCase)
                       || UnityOwnedPrefabPaths.Contains(normalized));
        }

        internal static bool IsUnityOwnedPrefabName(string prefabName)
        {
            if (string.IsNullOrWhiteSpace(prefabName)) return false;
            return UnityOwnedPrefabPaths.Any(path => string.Equals(
                    Path.GetFileNameWithoutExtension(path), prefabName, System.StringComparison.OrdinalIgnoreCase))
                || string.Equals(prefabName, "dancichouka", System.StringComparison.OrdinalIgnoreCase)
                || string.Equals(prefabName, "shilianchouka", System.StringComparison.OrdinalIgnoreCase);
        }

        internal static bool IsUnityOwnedAssetPath(string assetPath)
        {
            if (string.IsNullOrWhiteSpace(assetPath)) return false;
            string normalized = assetPath.Replace('\\', '/');
            if (!HasSafeAssetPathSegments(normalized)) return false;
            if (IsUnityOwnedPrefabPath(normalized)) return true;
            return UnityOwnedResourceRoots.Any(root =>
                normalized.StartsWith(root, System.StringComparison.OrdinalIgnoreCase));
        }

        internal static bool IsLegacyCocosAssetPath(string assetPath)
        {
            if (string.IsNullOrWhiteSpace(assetPath)) return false;
            string normalized = assetPath.Replace('\\', '/');
            return HasSafeAssetPathSegments(normalized)
                   && normalized.StartsWith("Assets/ProjectX/res/", System.StringComparison.OrdinalIgnoreCase);
        }

        internal static bool IsLegacyCocosPrefabPath(string prefabPath)
        {
            if (string.IsNullOrWhiteSpace(prefabPath)) return false;
            string normalized = prefabPath.Replace('\\', '/');
            return HasSafeAssetPathSegments(normalized)
                   && normalized.StartsWith("Assets/ProjectX/res/csd/Prefabs/", System.StringComparison.OrdinalIgnoreCase);
        }

        private static bool HasSafeAssetPathSegments(string normalized)
        {
            if (string.IsNullOrWhiteSpace(normalized) || normalized.StartsWith("/", System.StringComparison.Ordinal))
                return false;
            return normalized.Split('/').All(segment =>
                !string.IsNullOrWhiteSpace(segment) && segment != "." && segment != "..");
        }

        private static GameObject EnsureDynamicUiReference(string key, string prefabPath)
        {
            GameObject prefab = AssetDatabase.LoadAssetAtPath<GameObject>(prefabPath);
            if (prefab == null) throw new FileNotFoundException($"Dynamic UI prefab is missing: {prefabPath}");
            string assetPath = $"{DynamicUiResourceDirectory}/{key}.asset";
            UiPrefabReference reference = AssetDatabase.LoadAssetAtPath<UiPrefabReference>(assetPath);
            if (reference == null)
            {
                reference = ScriptableObject.CreateInstance<UiPrefabReference>();
                reference.SetPrefab(prefab);
                AssetDatabase.CreateAsset(reference, assetPath);
                return prefab;
            }
            if (reference.Prefab != prefab)
            {
                reference.SetPrefab(prefab);
                EditorUtility.SetDirty(reference);
                AssetDatabase.SaveAssetIfDirty(reference);
            }
            return prefab;
        }

        private static string GetDynamicKey(string prefabPath)
        {
            if (prefabPath == HeroBookPrefab) return "HeroBook";
            if (prefabPath == HeroBookUpgradePrefab) return "HeroBookUpgrade";
            if (prefabPath == HeroBookActivateResultPrefab) return "HeroBookActivateResult";
            if (prefabPath == HeroBookUpgradeResultPrefab) return "HeroBookUpgradeResult";
            if (prefabPath == HeroBookAttributesPrefab) return "HeroBookAttributes";
            if (prefabPath == HeroBookAchievementsPrefab) return "HeroBookAchievements";
            if (prefabPath == HeroBookLevelResultPrefab) return "HeroBookLevelResult";
            if (prefabPath == HeroRecyclePrefab) return "HeroRecycle";
            if (prefabPath == HeroRebirthChoosePrefab) return "HeroRebirthChoose";
            if (prefabPath == HeroRebirthConfirmPrefab) return "HeroRebirthConfirm";
            if (prefabPath == HeroEnhanceMasterPrefab) return "HeroEnhanceMaster";
            if (prefabPath == HeroEquipmentListPrefab) return "HeroEquipmentList";
            if (prefabPath == HeroEquipmentDetailPrefab) return "HeroEquipmentDetail";
            if (prefabPath == HeroEquipmentChangePrefab) return "HeroEquipmentChange";
            if (prefabPath == HeroEquipmentCultivatePrefab) return "HeroEquipmentCultivate";
            if (prefabPath == HeroEquipmentStrengthPrefab) return "HeroEquipmentStrength";
            if (prefabPath == HeroEquipmentRefinePrefab) return "HeroEquipmentRefine";
            if (prefabPath == HeroEquipmentAwakenPrefab) return "HeroEquipmentAwaken";
            if (prefabPath == HeroEquipmentDivinePrefab) return "HeroEquipmentDivine";
            if (prefabPath == HeroEquipmentFragmentPrefab) return "HeroEquipmentFragment";
            if (prefabPath == HeroEquipmentAutoRefinePrefab) return "HeroEquipmentAutoRefine";
            if (prefabPath == HeroEquipmentExchangePrefab) return "HeroEquipmentExchange";
            if (prefabPath == HeroEquipmentAutoStarPrefab) return "HeroEquipmentAutoStar";
            if (prefabPath == HeroEquipmentAutoDivinePrefab) return "HeroEquipmentAutoDivine";
            if (prefabPath == HeroEquipmentDivineEffectPrefab) return "HeroEquipmentDivineEffect";
            if (prefabPath == FaBaoStrengthPrefab) return "FaBaoStrength";
            if (prefabPath == FaBaoRefinePrefab) return "FaBaoRefine";
            if (prefabPath == FaBaoMaterialChooserPrefab) return "FaBaoMaterialChooser";
            if (prefabPath == BattleFightLayerPrefab) return "BattleFightLayer";
            if (prefabPath == BattleHpNodePrefab) return "BattleHpNode";
            return Path.GetFileNameWithoutExtension(prefabPath);
        }

        private static void EnsureAssetFolder(string path)
        {
            string current = "Assets";
            foreach (string segment in path.Split('/').Skip(1))
            {
                string next = current + "/" + segment;
                if (!AssetDatabase.IsValidFolder(next)) AssetDatabase.CreateFolder(current, segment);
                current = next;
            }
        }

        private static void EnsureDrawDynamicResources()
        {
            string repositoryRoot = Directory.GetParent(Application.dataPath).Parent.FullName;
            RequireUnityResource("Assets/Art/Icons/Gameplay/ui_icon_choukarukou.png");
            // Unity Resources is the Steam runtime source of truth. Existing
            // project assets must not be refreshed from the separate Cocos client.
            RequireUnityResource("Assets/Art/World/worldmap.png");
            RequireUnityResource("Assets/Art/World/battle_victory_bg.png");
            RequireUnityResource("Assets/Art/World/battle_victory.png");
            RequireUnityResource("Assets/Art/World/battle_scene_bg.jpg");
            string unityClientDataRoot = Path.Combine(repositoryRoot, "unitydata", "export", "client", "source");
            CopyResourceIfChanged(
                Path.Combine(unityClientDataRoot, "Battle", "hit_monster.dat.bytes"),
                "Assets/Resources/ProjectXData/Battle/hit_monster.dat.bytes");
            CopyResourceIfChanged(
                Path.Combine(unityClientDataRoot, "Battle", "zhenfa_config_dat.txt"),
                "Assets/Resources/ProjectXData/Battle/zhenfa_config_dat.txt");
            RequireUnityResource("Assets/Art/Battle/Hud/num_lan.png");
            RequireUnityResource("Assets/Art/Battle/Hud/ui_pk_num.png");
            for (int formation = 1; formation <= 6; formation++)
            {
                RequireUnityResource($"Assets/Art/Hero/formation_{formation}.png");
            }
            foreach (string configName in new[]
                     {
                         "bigmap_dat", "map_res_dat", "maplist_dat", "fight_config_dat",
                         "monster_boss_basic_dat", "exp_dat", "reward_fixed_dat", "map_achievement_dat",
                         "hero_dat", "star_dat",
                         "break_dat", "xiulian_dat"
                     })
            {
                CopyResourceIfChanged(
                    Path.Combine(unityClientDataRoot, "World", configName + ".txt"),
                    $"Assets/Resources/ProjectXData/World/{configName}.txt");
            }
            for (int map = 1; map <= 6; map++)
            {
                for (int tile = 1; tile <= 12; tile++)
                {
                    RequireUnityResource($"Assets/Art/World/Maps/map_{map}/map_{tile}.jpg");
                }
            }
            for (int world = 1; world <= 3; world++)
            {
                RequireUnityResource($"Assets/Art/World/Chapters/fuben_map{world}.png");
            }
            string petBasicConfig = Path.Combine(unityClientDataRoot, "Configs", "pet_basic_config.xml");
            string skillBasicConfig = Path.Combine(unityClientDataRoot, "Configs", "skill_basic.xml");
            string skillActiveEffectConfig = Path.Combine(unityClientDataRoot, "Configs", "skill_active_effect.xml");
            string skillAdditiveEffectConfig = Path.Combine(unityClientDataRoot, "Configs", "skill_additive_effect.xml");
            CopyResourceIfChanged(petBasicConfig, "Assets/Resources/ProjectXData/Configs/pet_basic_config.xml");
            CopyResourceIfChanged(skillBasicConfig, "Assets/Resources/ProjectXData/Configs/skill_basic.xml");
            CopyResourceIfChanged(skillActiveEffectConfig, "Assets/Resources/ProjectXData/Configs/skill_active_effect.xml");
            CopyResourceIfChanged(skillAdditiveEffectConfig, "Assets/Resources/ProjectXData/Configs/skill_additive_effect.xml");
            IEnumerable<int> heroSkillIds = XDocument.Load(petBasicConfig).Root?.Elements("CONTENT")
                .Select(element => (element.Attribute("skill")?.Value ?? "").Split(';').FirstOrDefault())
                .Select(value => int.TryParse(value, out int parsed) ? parsed : 0)
                .Where(value => value > 0)
                .Distinct()
                ?? Enumerable.Empty<int>();
            foreach (int skillId in heroSkillIds)
            {
                RequireUnityResource($"Assets/Art/Hero/skill_{skillId}.png");
            }
            foreach (string configName in new[] { "fabao_qianghua", "fabao_jinglian", "master", "daily" })
            {
                CopyResourceIfChanged(
                    Path.Combine(unityClientDataRoot, "Configs", configName + ".json"),
                    $"Assets/Resources/ProjectXData/Configs/{configName}.json");
            }
            RequireUnityResource("Assets/Art/Hero/quality_score_A.png");
            RequireUnityResource("Assets/Art/Hero/quality_score_S.png");
            RequireUnityResource("Assets/Art/Hero/quality_score_SS.png");
            RequireUnityResource("Assets/Art/Hero/quality_score_SSS.png");
            RequireUnityResource("Assets/Art/Hero/quality_score_SSSS.png");
        }

        private static void CopyResourceIfChanged(string sourcePath, string destinationAssetPath)
        {
            string absoluteSource = Path.IsPathRooted(sourcePath)
                ? sourcePath : Path.GetFullPath(sourcePath);
            string absoluteDestination = Path.GetFullPath(destinationAssetPath);
            if (!File.Exists(absoluteSource))
                throw new FileNotFoundException($"Runtime dynamic resource is missing: {absoluteSource}");
            byte[] source = File.ReadAllBytes(absoluteSource);
            if (IsGitLfsPointer(source))
                throw new InvalidDataException(
                    $"Runtime dynamic resource is an unresolved Git LFS pointer: {absoluteSource}");
            bool changed = !File.Exists(absoluteDestination)
                || !source.SequenceEqual(File.ReadAllBytes(absoluteDestination));
            if (!changed) return;
            Directory.CreateDirectory(Path.GetDirectoryName(absoluteDestination));
            File.WriteAllBytes(absoluteDestination, source);
            AssetDatabase.ImportAsset(destinationAssetPath, ImportAssetOptions.ForceSynchronousImport);
        }

        private static void RequireUnityResource(string assetPath)
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string absolutePath = Path.GetFullPath(Path.Combine(projectRoot, assetPath));
            if (!File.Exists(absolutePath))
                throw new FileNotFoundException($"Unity runtime resource is missing: {absolutePath}");
            if (IsGitLfsPointer(File.ReadAllBytes(absolutePath)))
                throw new InvalidDataException($"Unity runtime resource is an unresolved Git LFS pointer: {absolutePath}");
        }

        private static bool IsGitLfsPointer(byte[] content)
        {
            if (content == null || content.Length == 0 || content.Length > 512) return false;
            byte[] marker = Encoding.ASCII.GetBytes("version https://git-lfs.github.com/spec/v1");
            if (content.Length < marker.Length) return false;
            for (int index = 0; index < marker.Length; index++)
                if (content[index] != marker[index]) return false;
            return true;
        }

        [MenuItem("Tools/ProjectX 应用/强制重建 Bootstrap 场景", priority = 91)]
        public static void ForceRebuild()
        {
            EnsureDynamicUiCatalog();
            EnsureDrawDynamicResources();
            Rebuild();
        }

        private static void Rebuild()
        {
            Scene scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

            GameObject cameraObject = new GameObject("Main Camera", typeof(Camera), typeof(AudioListener));
            cameraObject.tag = "MainCamera";
            Camera camera = cameraObject.GetComponent<Camera>();
            camera.clearFlags = CameraClearFlags.SolidColor;
            camera.backgroundColor = Color.black;
            camera.orthographic = true;
            cameraObject.transform.position = new Vector3(0f, 0f, -10f);

            GameObject lightObject = new GameObject("Directional Light", typeof(Light));
            lightObject.GetComponent<Light>().type = LightType.Directional;
            lightObject.transform.rotation = Quaternion.Euler(50f, -30f, 0f);

            GameObject canvasObject = new GameObject("Canvas", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            Canvas canvas = canvasObject.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            CanvasScaler scaler = canvasObject.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1334f, 750f);
            scaler.matchWidthOrHeight = 0.5f;
            new GameObject("EventSystem", typeof(EventSystem), typeof(StandaloneInputModule));

            new GameObject("ProjectXApp", typeof(ProjectXApp));

            Directory.CreateDirectory(Path.GetDirectoryName(BootstrapScene));
            EditorSceneManager.SaveScene(scene, BootstrapScene);
            NormalizeBootstrapSceneYaml();
            EnsureBuildSettings();
            AssetDatabase.SaveAssets();
            Debug.Log("[ProjectXApp] Bootstrap scene rebuilt and set as build index 0.");
        }

        public static void BuildBatch()
        {
            Build();
        }

        [MenuItem("Tools/ProjectX 应用/验证资源基础", priority = 92)]
        public static void ValidateResourceFoundationBatch()
        {
            Build();
            UiPrefabCatalog catalog = AssetDatabase.LoadAssetAtPath<UiPrefabCatalog>(DynamicUiCatalog);
            if (catalog == null) throw new InvalidDataException("ResourceFoundation catalog is missing.");
            int expectedCount = PrefabSpecs.Length + DynamicOnlyPrefabSpecs.Length;
            if (catalog.Entries.Count != expectedCount)
                throw new InvalidDataException($"ResourceFoundation catalog count mismatch: expected={expectedCount}, actual={catalog.Entries.Count}.");
            string[] keys = catalog.Entries.Select(entry => entry.Key).ToArray();
            if (keys.Distinct(System.StringComparer.OrdinalIgnoreCase).Count() != keys.Length)
                throw new InvalidDataException("ResourceFoundation catalog contains duplicate keys.");
            var keySet = new HashSet<string>(keys, System.StringComparer.OrdinalIgnoreCase);
            foreach (UiPrefabCatalogEntry entry in catalog.Entries)
            {
                if (string.IsNullOrWhiteSpace(entry.Key) || string.IsNullOrWhiteSpace(entry.Source))
                    throw new InvalidDataException("ResourceFoundation catalog contains incomplete metadata.");
                if (!string.IsNullOrWhiteSpace(entry.ParentKey) && !keySet.Contains(entry.ParentKey))
                    throw new InvalidDataException($"ResourceFoundation parent key is missing: {entry.Key} -> {entry.ParentKey}.");
                string referencePath = $"{DynamicUiResourceDirectory}/{entry.Key}.asset";
                UiPrefabReference reference = AssetDatabase.LoadAssetAtPath<UiPrefabReference>(referencePath);
                if (reference == null || reference.Prefab == null)
                    throw new InvalidDataException($"ResourceFoundation prefab reference is missing: {entry.Key}.");
            }
            foreach (string pilot in new[] { "HeroBook", "HeroRecycle", "HeroRebirthChoose", "HeroRebirthConfirm" })
                if (!keySet.Contains(pilot)) throw new InvalidDataException($"ResourceFoundation lifecycle pilot is missing: {pilot}.");
            if (!IsBootstrapSceneCurrent())
                throw new InvalidDataException("ResourceFoundation Bootstrap scene is not minimal.");
            ValidateProviderContracts();
            long sceneBytes = new FileInfo(BootstrapScene).Length;
            string repositoryRoot = Directory.GetParent(Application.dataPath).Parent.FullName;
            string evidenceDirectory = Path.Combine(repositoryRoot, ".local", "unity-validation");
            Directory.CreateDirectory(evidenceDirectory);
            string evidencePath = Path.Combine(evidenceDirectory, "resourcefoundation-latest.json");
            string json = $"{{\n  \"schemaVersion\": 1,\n  \"status\": \"Passed\",\n  \"rollbackCommit\": \"7422cbd83531b365a4188e36e21999e47d508d5d\",\n  \"catalogEntries\": {expectedCount},\n  \"bootstrapPrefabInstances\": 0,\n  \"bootstrapBytes\": {sceneBytes},\n  \"providerContractsPassed\": true,\n  \"lifecyclePilots\": [\"HeroBook\", \"HeroRecycle\"]\n}}\n";
            File.WriteAllText(evidencePath, json, new UTF8Encoding(false));
            Debug.Log($"[ResourceFoundation] PASS catalog={expectedCount}, bootstrapPrefabs=0, sceneBytes={sceneBytes}, rollback=7422cbd83531b365a4188e36e21999e47d508d5d");
        }

        private static void ValidateProviderContracts()
        {
            ProjectX.Foundation.ResourceLoader.Configure(new UnityResourceLoader());
            ValidateUnityOwnedPrefabDependencies();

            Scene scene = EditorSceneManager.OpenScene(BootstrapScene, OpenSceneMode.Single);
            Transform root = scene.GetRootGameObjects().Single(item => item.name == "Canvas").transform;
            using (var provider = new ResourcesUiAssetProvider(root))
            {

                if (provider.LoadedSingletonCount != 0 || provider.LoadedTransientCount != 0)
                    throw new InvalidDataException("UI provider must start without loaded views.");

                UnityUiView settings = provider.GetUnityOrCreate("SystemLayer");
                UnityUiView settingsAgain = provider.GetUnityOrCreate("SystemLayer");
                if (settings == null || !ReferenceEquals(settings, settingsAgain) || provider.LoadedSingletonCount != 1)
                    throw new InvalidDataException("UI provider singleton contract failed for Settings.");

                UnityUiView taskFrame = provider.GetUnityOrCreate("huodong_bg");
                UnityUiView task = provider.GetUnityOrCreate("RenwuLayer");
                if (task == null || taskFrame == null || task.GameObject.transform.parent != taskFrame.GameObject.transform)
                    throw new InvalidDataException("UI provider parent-child composition contract failed for Task.");

                int loadedBeforeHeroFrame = provider.LoadedSingletonCount;
                UnityUiView heroFrame = provider.GetUnityOrCreate("OneLevelLayer");
                if (heroFrame == null || provider.LoadedSingletonCount != loadedBeforeHeroFrame + 1
                    || heroFrame.GameObject.transform.Find("DynamicUi_yingxiongListLayer") != null
                    || heroFrame.GameObject.transform.Find("DynamicUi_yingxiongInfoLayer") != null)
                    throw new InvalidDataException("UI provider must not eagerly instantiate OneLevelLayer child pages.");
                UnityUiView heroList = provider.GetUnityOrCreate("yingxiongListLayer");
                UnityUiView heroDetail = provider.GetUnityOrCreate("yingxiongInfoLayer");
                UnityUiView heroBag = provider.GetUnityOrCreate("yingxiongbeibao");
                if (heroList == null || heroDetail == null || heroBag == null
                    || heroList.GameObject.transform.parent != heroFrame.GameObject.transform
                    || heroDetail.GameObject.transform.parent != heroFrame.GameObject.transform
                    || heroBag.GameObject.transform.parent != heroFrame.GameObject.transform
                    || heroList.GameObject.activeSelf || heroDetail.GameObject.activeSelf || heroBag.GameObject.activeSelf)
                    throw new InvalidDataException("UI provider lazy Unity-owned Hero child-page contract failed.");

                UnityUiView heroBookA = provider.InstantiateUnity("HeroBook", root);
                UnityUiView heroBookB = provider.InstantiateUnity("HeroBook", root);
                if (ReferenceEquals(heroBookA, heroBookB) || provider.LoadedTransientCount != 2)
                    throw new InvalidDataException("UI provider transient instance contract failed for HeroBook.");
                if (!provider.Release(heroBookA) || !provider.Release(heroBookB) || provider.LoadedTransientCount != 0)
                    throw new InvalidDataException("UI provider transient release contract failed for HeroBook.");

                UnityUiView heroRecycle = provider.InstantiateUnity("HeroRecycle", root);
                if (provider.LoadedTransientCount != 1 || !provider.Release(heroRecycle)
                    || provider.LoadedTransientCount != 0)
                    throw new InvalidDataException("UI provider lifecycle contract failed for HeroRecycle.");
            }
            if (root.childCount != 0)
                throw new InvalidDataException($"UI provider disposal left {root.childCount} objects under Bootstrap Canvas.");
        }

        private static void ValidateUnityOwnedPrefabDependencies()
        {
            foreach (string prefabPath in UnityOwnedPrefabPaths)
            {
                GameObject prefab = AssetDatabase.LoadAssetAtPath<GameObject>(prefabPath);
                if (prefab == null)
                    throw new FileNotFoundException($"Unity-owned UI Prefab is missing: {prefabPath}");
                foreach (string dependency in AssetDatabase.GetDependencies(prefabPath, true))
                    if (IsLegacyCocosAssetPath(dependency))
                        throw new InvalidDataException(
                            $"Unity-owned UI Prefab depends on a legacy Cocos asset: {prefabPath} -> {dependency}");

                GameObject root = PrefabUtility.LoadPrefabContents(prefabPath);
                try
                {
                    foreach (Component component in root.GetComponentsInChildren<Component>(true))
                    {
                        if (component == null)
                            throw new InvalidDataException($"Unity-owned UI Prefab contains a missing script: {prefabPath}");
                        string typeName = component.GetType().Name;
                        if (typeName == "UiPrefabIdentity" || typeName == "CocosTimelinePlayer"
                            || typeName == "CocosUiBinding" || typeName == "CocosNodeMetadata")
                            throw new InvalidDataException(
                                $"Unity-owned UI Prefab contains a Cocos migration component: {prefabPath} -> {component.GetType().Name}");
                    }
                }
                finally
                {
                    PrefabUtility.UnloadPrefabContents(root);
                }
            }
        }

        private static void NormalizeBootstrapSceneYaml()
            => NormalizeUnityYaml(BootstrapScene);

        private static void NormalizeUnityYaml(string assetPath)
        {
            string absolutePath = Path.GetFullPath(assetPath);
            string content = File.ReadAllText(absolutePath);
            string newline = content.Contains("\r\n") ? "\r\n" : "\n";
            string[] lines = content.Replace("\r\n", "\n").Split('\n');
            string normalized = string.Join(newline, lines.Select(line => line.TrimEnd(' ', '\t')));
            if (string.Equals(content, normalized, System.StringComparison.Ordinal)) return;
            File.WriteAllText(absolutePath, normalized, new UTF8Encoding(false));
            AssetDatabase.ImportAsset(assetPath, ImportAssetOptions.ForceSynchronousImport);
        }

        private static bool IsBootstrapSceneCurrent()
        {
            if (!File.Exists(BootstrapScene)) return false;
            Scene scene = EditorSceneManager.OpenScene(BootstrapScene, OpenSceneMode.Single);
            GameObject[] roots = scene.GetRootGameObjects();
            if (!roots.Select(root => root.name).SequenceEqual(new[]
                { "Main Camera", "Directional Light", "Canvas", "EventSystem", "ProjectXApp" })) return false;

            GameObject canvas = roots.SingleOrDefault(root => root.name == "Canvas");
            if (canvas == null || roots.Single(root => root.name == "ProjectXApp").GetComponent<ProjectXApp>() == null) return false;

            int prefabCount = canvas.GetComponentsInChildren<Transform>(true)
                .Count(transform => transform != canvas.transform && PrefabUtility.IsAnyPrefabInstanceRoot(transform.gameObject));
            if (prefabCount != 0)
                Debug.LogWarning($"[ProjectXApp] Minimal Bootstrap must not contain UI prefab instances: actual={prefabCount}.");
            return prefabCount == 0;
        }

        private static void EnsureBuildSettings()
        {
            var expected = new[]
            {
                new EditorBuildSettingsScene(BootstrapScene, true),
                new EditorBuildSettingsScene(FirstPlayableScene, false)
            };
            if (EditorBuildSettings.scenes.Length == expected.Length &&
                EditorBuildSettings.scenes.Zip(expected, (actual, item) =>
                    actual.path == item.path && actual.enabled == item.enabled).All(matches => matches)) return;
            EditorBuildSettings.scenes = expected;
        }
    }
}
