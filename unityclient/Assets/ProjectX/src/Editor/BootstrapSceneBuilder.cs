using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Xml.Linq;
using ProjectX.Core;
using ProjectX.UI;
using ProjectX.UI.Migration;
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
        private const string BootstrapScene = "Assets/ProjectX/Scenes/Bootstrap.unity";
        private const string FirstPlayableScene = "Assets/ProjectX/Scenes/FirstPlayableLoop.unity";
        private const string LoginBackgroundPrefab = "Assets/ProjectX/res/csd/Prefabs/Login/LoginBgLayer.prefab";
        private const string LoginPrefab = "Assets/ProjectX/res/csd/Prefabs/Login/loginLayer.prefab";
        private const string LoginServerListPrefab = "Assets/ProjectX/res/csd/Prefabs/Login/SeverListLayer.prefab";
        private const string RoleCreatePrefab = "Assets/ProjectX/res/csd/Prefabs/Login/RoleCreateLayer.prefab";
        private const string NoticePrefab = "Assets/ProjectX/res/csd/Prefabs/NoticeLayer.prefab";
        private const string MainPrefab = "Assets/ProjectX/res/csd/Prefabs/common/UImainLayer_new.prefab";
        private const string MainCloudPrefab = "Assets/ProjectX/res/csd/Prefabs/common/UImain_cloudLayer.prefab";
        private const string BackupMainPrefab = "Assets/ProjectX/res/csd/Prefabs/UImainLayer_backup.prefab";
        private const string BagPrefab = "Assets/ProjectX/res/csd/Prefabs/zhujue/beibao.prefab";
        private const string BagInputPrefab = "Assets/ProjectX/res/csd/Prefabs/EnterNumLayer.prefab";
        private const string BagGiftPrefab = "Assets/ProjectX/res/csd/Prefabs/common/OpenBox_1Layer.prefab";
        private const string SettingsPrefab = "Assets/ProjectX/res/csd/Prefabs/zhujue/SystemLayer.prefab";
        private const string TaskBackgroundPrefab = "Assets/ProjectX/res/csd/Prefabs/huodong/huodong_bg.prefab";
        private const string TaskPrefab = "Assets/ProjectX/res/csd/Prefabs/huodong/RenwuLayer.prefab";
        private const string ErrorPrefab = "Assets/ProjectX/res/csd/Prefabs/MessageBoxLayer.prefab";
        private const string RewardPrefab = "Assets/ProjectX/res/csd/Prefabs/common/tanchuangjiangli.prefab";
        private const string HeroFramePrefab = "Assets/ProjectX/res/csd/Prefabs/OneLevelLayer.prefab";
        private const string HeroListPrefab = "Assets/ProjectX/res/csd/Prefabs/shenjiangyangcheng/yingxiongListLayer.prefab";
        private const string HeroDetailPrefab = "Assets/ProjectX/res/csd/Prefabs/shenjiangyangcheng/yingxiongInfoLayer.prefab";
        private const string HeroReplacementPrefab = "Assets/ProjectX/res/csd/Prefabs/shenjiangyangcheng/yingxionghuanjiang.prefab";
        private const string HeroCultivationPrefab = "Assets/ProjectX/res/csd/Prefabs/shenjiangyangcheng/yingxiongjueseLayer.prefab";
        private const string HeroLevelUpPrefab = "Assets/ProjectX/res/csd/Prefabs/shenjiangyangcheng/yingxiongshuxingLayer.prefab";
        private const string HeroAutoLevelUpPrefab = "Assets/ProjectX/res/csd/Prefabs/shenjiangyangcheng/yingxiongshengjiScene1.prefab";
        private const string HeroStarUpPrefab = "Assets/ProjectX/res/csd/Prefabs/shenjiangyangcheng/yingxiongshengxingLayer.prefab";
        private const string HeroBreakUpPrefab = "Assets/ProjectX/res/csd/Prefabs/shenjiangyangcheng/yingxiongtupoLayer.prefab";
        private const string HeroTrainingPrefab = "Assets/ProjectX/res/csd/Prefabs/shenjiangyangcheng/yingxiongxiulian.prefab";
        private const string HeroInfoPrefab = "Assets/ProjectX/res/csd/Prefabs/shenjiangyangcheng/yingxiongxinxiLayer.prefab";
        private const string HeroTalentPrefab = "Assets/ProjectX/res/csd/Prefabs/shenjiangyangcheng/yingxiongtianfuLayer.prefab";
        private const string HeroTrainingHelpPrefab = "Assets/ProjectX/res/csd/Prefabs/shenjiangyangcheng/yingxiongxiulian2.prefab";
        private const string HeroTrainingAttributePrefab = "Assets/ProjectX/res/csd/Prefabs/shenjiangyangcheng/yingxiongxiulian3.prefab";
        private const string HeroEnhanceMasterPrefab = "Assets/ProjectX/res/csd/Prefabs/zhuangbeiyangcheng/qianghuadashi.prefab";
        private const string HeroAttributesPrefab = "Assets/ProjectX/res/csd/Prefabs/shenjiangyangcheng/shenjiangxiangxishuxing.prefab";
        private const string HeroItemSourcePrefab = "Assets/ProjectX/res/csd/Prefabs/common/huoqutujing.prefab";
        private const string HeroBagPrefab = "Assets/ProjectX/res/csd/Prefabs/shenjiangyangcheng/yingxiongbeibao.prefab";
        private const string HeroBookPrefab = "Assets/ProjectX/res/csd/Prefabs/shenjiangyangcheng/yingxiongtujianLayer.prefab";
        private const string HeroRecyclePrefab = "Assets/ProjectX/res/csd/Prefabs/huishou/shenjiangchongsheng.prefab";
        private const string DynamicUiResourceDirectory = "Assets/ProjectX/Resources/UiPrefabs";
        private const string DynamicUiCatalog = DynamicUiResourceDirectory + "/Catalog.asset";
        private const string FormationPopupPrefab = "Assets/ProjectX/res/csd/Prefabs/shenjiangyangcheng/shenjiangzhenxingLayer.prefab";
        private const string HeroEquipmentListPrefab = "Assets/ProjectX/res/csd/Prefabs/zhuangbeiyangcheng/zhuangbeibeibao.prefab";
        private const string HeroEquipmentDetailPrefab = "Assets/ProjectX/res/csd/Prefabs/zhuangbeiyangcheng/zhuangbeiInfo.prefab";
        private const string HeroEquipmentChangePrefab = "Assets/ProjectX/res/csd/Prefabs/zhuangbeiyangcheng/zhuangbeigenghuan.prefab";
        private const string HeroEquipmentCultivatePrefab = "Assets/ProjectX/res/csd/Prefabs/zhuangbeiyangcheng/zhuangbeiyangcheng.prefab";
        private const string HeroEquipmentStrengthPrefab = "Assets/ProjectX/res/csd/Prefabs/zhuangbeiyangcheng/zhuangbeiqianghua.prefab";
        private const string HeroEquipmentRefinePrefab = "Assets/ProjectX/res/csd/Prefabs/zhuangbeiyangcheng/zhuangbeijinglian.prefab";
        private const string HeroEquipmentAwakenPrefab = "Assets/ProjectX/res/csd/Prefabs/zhuangbeiyangcheng/zhuangbeijuexing.prefab";
        private const string HeroEquipmentDivinePrefab = "Assets/ProjectX/res/csd/Prefabs/zhuangbeiyangcheng/zhuangbeishenzhu.prefab";
        private const string HeroEquipmentFragmentPrefab = "Assets/ProjectX/res/csd/Prefabs/zhuangbeiyangcheng/zhuangbeisuipian.prefab";
        private const string HeroEquipmentAutoRefinePrefab = "Assets/ProjectX/res/csd/Prefabs/zhuangbeiyangcheng/yijianjinglian.prefab";
        private const string HeroEquipmentExchangePrefab = "Assets/ProjectX/res/csd/Prefabs/zhuangbeiyangcheng/yijianduihuan.prefab";
        private const string HeroEquipmentAutoStarPrefab = "Assets/ProjectX/res/csd/Prefabs/zhuangbeiyangcheng/yijianshengxing.prefab";
        private const string HeroEquipmentAutoDivinePrefab = "Assets/ProjectX/res/csd/Prefabs/zhuangbeiyangcheng/yijianshengceng.prefab";
        private const string HeroEquipmentDivineEffectPrefab = "Assets/ProjectX/res/csd/Prefabs/zhuangbeiyangcheng/shenzhutexiao.prefab";
        private const string FaBaoStrengthPrefab = "Assets/ProjectX/res/csd/Prefabs/zhuangbeiyangcheng/fabaoqianghua.prefab";
        private const string FaBaoRefinePrefab = "Assets/ProjectX/res/csd/Prefabs/zhuangbeiyangcheng/fabaojinglian.prefab";
        private const string FaBaoMaterialChooserPrefab = "Assets/ProjectX/res/csd/Prefabs/huishou/Choose_fenjie.prefab";
        private const string LoadingPrefab = "Assets/ProjectX/res/csd/Prefabs/common/jiemianjiazai.prefab";
        private const string MailPrefab = "Assets/ProjectX/res/csd/Prefabs/MailLayer.prefab";
        private const string ShopPrefab = "Assets/ProjectX/res/csd/Prefabs/shop/shangcheng.prefab";
        private const string SoulShopPrefab = "Assets/ProjectX/res/csd/Prefabs/shop/jianghunshop.prefab";
        private const string MultiShopPrefab = "Assets/ProjectX/res/csd/Prefabs/shop/wanfashop.prefab";
        private const string FriendPrefab = "Assets/ProjectX/res/csd/Prefabs/common/FriendLayer.prefab";
        private const string ChatMiniPrefab = "Assets/ProjectX/res/csd/Prefabs/ChatLayer.prefab";
        private const string ChatPrefab = "Assets/ProjectX/res/csd/Prefabs/MainChatLayer.prefab";
        private const string TeamMembersPrefab = "Assets/ProjectX/res/csd/Prefabs/TeamMembersLayer.prefab";
        private const string TeamInvitePrefab = "Assets/ProjectX/res/csd/Prefabs/TeamInviteListLayer.prefab";
        private const string GuildListPrefab = "Assets/ProjectX/res/csd/Prefabs/bangpai/GangsApplyLayer.prefab";
        private const string GuildInfoPrefab = "Assets/ProjectX/res/csd/Prefabs/bangpai/GangsLayer.prefab";
        private const string GuildMemberPrefab = "Assets/ProjectX/res/csd/Prefabs/bangpai/GangsMemberLayer.prefab";
        private const string GuildCreatePrefab = "Assets/ProjectX/res/csd/Prefabs/bangpai/GangsfoundLayer.prefab";
        private const string WorldPrefab = "Assets/ProjectX/res/csd/Prefabs/fuben/WorldMapNewLayer.prefab";
        private const string WorldStagePrefab = "Assets/ProjectX/res/csd/Prefabs/fuben/kapaiguaiwuLayer.prefab";
        private const string WorldMapPrefab = "Assets/ProjectX/res/csd/Prefabs/fuben/DadituuiLayer.prefab";
        private const string WorldDetailPrefab = "Assets/ProjectX/res/csd/Prefabs/fuben/guanqiaxiangxiLayer.prefab";
        private const string WorldSweepPrefab = "Assets/ProjectX/res/csd/Prefabs/fuben/saodangLayer.prefab";
        private const string WorldBattleResultPrefab = "Assets/ProjectX/res/csd/Prefabs/common/zhandoujiesuanLayer.prefab";
        private const string WorldBattleStatisticsPrefab = "Assets/ProjectX/res/csd/Prefabs/common/zhandoutongji.prefab";
        private const string BattleFightLayerPrefab = "Assets/ProjectX/res/csd/Prefabs/common/FightLayer.prefab";
        private const string WorldBoxAwardPrefab = "Assets/ProjectX/res/csd/Prefabs/guaiwubaoxiangLayer.prefab";
        private const string WorldAchievementPrefab = "Assets/ProjectX/res/csd/Prefabs/fuben/zhuxianchengjiu.prefab";
        private const string WelfarePrefab = "Assets/ProjectX/res/csd/Prefabs/WelfareLayer.prefab";
        private const string WelfareSignPrefab = "Assets/ProjectX/res/csd/Prefabs/SignLayer.prefab";
        private const string WelfareOnlinePrefab = "Assets/ProjectX/res/csd/Prefabs/huodong/LoginGiftLayer.prefab";
        private const string ActivityRootPrefab = "Assets/ProjectX/res/csd/Prefabs/huodong/ActivityRankingLayer.prefab";
        private const string ActivityBackgroundPrefab = "Assets/ProjectX/res/csd/Prefabs/huodong/ActivityLevelLayer.prefab";
        private const string ActivityDailyRechargePrefab = "Assets/ProjectX/res/csd/Prefabs/DailyChargeLayer.prefab";
        private const string DrawPrefab = "Assets/ProjectX/res/csd/Prefabs/chouka/shenjiangzhaomu.prefab";
        private const string DrawSingleResultPrefab = "Assets/ProjectX/res/csd/Prefabs/chouka/dancichouka.prefab";
        private const string DrawTenResultPrefab = "Assets/ProjectX/res/csd/Prefabs/chouka/shilianchouka.prefab";
        private const string DrawPreviewPrefab = "Assets/ProjectX/res/csd/Prefabs/chouka/jiangliyulan.prefab";
        private const string DrawExchangePrefab = "Assets/ProjectX/res/csd/Prefabs/common/daojuduihuan.prefab";
        private const string GameplayFramePrefab = "Assets/ProjectX/res/csd/Prefabs/shop/shop_bg.prefab";
        private const string GameplayPrefab = "Assets/ProjectX/res/csd/Prefabs/common/ActivityLayer.prefab";
        private const string GameplayDetailPrefab = "Assets/ProjectX/res/csd/Prefabs/TaskPopupLayer.prefab";
        private const string GameplayFloatNoticePrefab = "Assets/ProjectX/Generated/FloatNoticeLayer.prefab";
        private const string FloatNoticeBackground = "Assets/ProjectX/res/csd/UnityMigration/Sliced/res/UI/ui_shenjiang/ui_shenjiang_tips__L13_B13_R13_T13.png";
        private const string FloatNoticeFont = "Assets/ProjectX/res/xiaokaiSJ2.ttf";
        private const string YouLiPrefab = "Assets/ProjectX/res/csd/Prefabs/youli/youlisanjie.prefab";
        private const string YouLiDetailPrefab = "Assets/ProjectX/res/csd/Prefabs/youli/youli.prefab";
        private const string YouLiOneKeyPrefab = "Assets/ProjectX/res/csd/Prefabs/youli/yijianyouli.prefab";
        private const string YouLiModePrefab = "Assets/ProjectX/res/csd/Prefabs/youli/youlifangshi.prefab";
        private const string YouLiTimePrefab = "Assets/ProjectX/res/csd/Prefabs/youli/youlishichang.prefab";
        private const string FengShenStoryPrefab = "Assets/ProjectX/res/csd/Prefabs/fengshenliezhuan/fengshenliezhuanlLayer.prefab";
        private const string FengShenStoryLevelPrefab = "Assets/ProjectX/res/csd/Prefabs/fengshenliezhuan/fengshenliezhuanlevel.prefab";
        private const string ArenaPrefab = "Assets/ProjectX/res/csd/Prefabs/common/JingjiLayer.prefab";
        private const string KunLunPrefab = "Assets/ProjectX/res/csd/Prefabs/kunlun/juezhankunlun.prefab";
        private const string BloodFightPrefab = "Assets/ProjectX/res/csd/Prefabs/xuezhan/XuezhanMain.prefab";
        private const string XunBaoPrefab = "Assets/ProjectX/res/csd/Prefabs/wanfa/XunbaoLayer.prefab";
        private const string SevenDayPrefab = "Assets/ProjectX/res/csd/Prefabs/huodong/QiriLayer.prefab";
        private const string StaminaClaimPrefab = "Assets/ProjectX/res/csd/Prefabs/huodong/tililingquLayer.prefab";
        private const string ResourceRecoveryPrefab = "Assets/ProjectX/res/csd/Prefabs/huodong/ziyuanzhaohui.prefab";
        private const string GrowthFundPrefab = "Assets/ProjectX/res/csd/Prefabs/huodong/ChengZhangLayer.prefab";
        private const string ActiveFundPrefab = "Assets/ProjectX/res/csd/Prefabs/huodong/HuoyueLayer.prefab";

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

        private static readonly PrefabSpec[] PrefabSpecs =
        {
            new PrefabSpec(LoginBackgroundPrefab, true),
            new PrefabSpec(LoginPrefab, true),
            new PrefabSpec(LoginServerListPrefab, false),
            new PrefabSpec(RoleCreatePrefab, false),
            new PrefabSpec(NoticePrefab, false),
            new PrefabSpec(MainPrefab, false),
            new PrefabSpec(MainCloudPrefab, false),
            new PrefabSpec(BackupMainPrefab, false),
            new PrefabSpec(BagPrefab, false),
            new PrefabSpec(BagInputPrefab, false),
            new PrefabSpec(BagGiftPrefab, false),
            new PrefabSpec(SettingsPrefab, false),
            new PrefabSpec(TaskBackgroundPrefab, false),
            new PrefabSpec(TaskPrefab, true, TaskBackgroundPrefab),
            new PrefabSpec(StaminaClaimPrefab, false, TaskBackgroundPrefab),
            new PrefabSpec(ResourceRecoveryPrefab, false, TaskBackgroundPrefab),
            new PrefabSpec(GrowthFundPrefab, false, TaskBackgroundPrefab),
            new PrefabSpec(ActiveFundPrefab, false, TaskBackgroundPrefab),
            new PrefabSpec(ErrorPrefab, false),
            new PrefabSpec(RewardPrefab, false),
            new PrefabSpec(LoadingPrefab, false),
            new PrefabSpec(MailPrefab, false),
            new PrefabSpec(ShopPrefab, false),
            new PrefabSpec(SoulShopPrefab, false),
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
            new PrefabSpec(DrawExchangePrefab, false),
            new PrefabSpec(GameplayFramePrefab, false),
            new PrefabSpec(GameplayPrefab, true, GameplayFramePrefab),
            new PrefabSpec(GameplayDetailPrefab, false, GameplayFramePrefab),
            new PrefabSpec(GameplayFloatNoticePrefab, false, GameplayFramePrefab),
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
            new PrefabSpec(SevenDayPrefab, false),
            new PrefabSpec(HeroFramePrefab, false),
            new PrefabSpec(HeroListPrefab, true, HeroFramePrefab),
            new PrefabSpec(HeroDetailPrefab, true, HeroFramePrefab),
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
            new PrefabSpec(HeroBookPrefab, false),
            new PrefabSpec(HeroRecyclePrefab, false),
            new PrefabSpec(HeroEnhanceMasterPrefab, false),
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
            new PrefabSpec("Assets/ProjectX/res/csd/Prefabs/HPNode.prefab", false)
        };

        [MenuItem("Tools/ProjectX App/Ensure Bootstrap Scene", priority = 90)]
        public static void Build()
        {
            EnsureFloatNoticePrefab();
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
                GameObject prefab = EnsureDynamicUiReference(key, spec.Path);
                CocosUiBinding binding = prefab.GetComponent<CocosUiBinding>()
                    ?? prefab.GetComponentInChildren<CocosUiBinding>(true);
                if (binding == null || string.IsNullOrWhiteSpace(binding.Source))
                    throw new InvalidDataException($"Registered UI prefab has no source binding: {spec.Path}");
                entries.Add(new UiPrefabCatalogEntry(key, binding.Source,
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
            }
            return prefab;
        }

        private static string GetDynamicKey(string prefabPath)
        {
            if (prefabPath == HeroBookPrefab) return "HeroBook";
            if (prefabPath == HeroRecyclePrefab) return "HeroRecycle";
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
            if (prefabPath.EndsWith("/HPNode.prefab", System.StringComparison.Ordinal)) return "BattleHpNode";
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
            string cocosRoot = Path.Combine(repositoryRoot, "client", "ProjectX");
            // World still draws from the original Cocos bitmaps.  Keep these
            // runtime copies small and explicit instead of substituting screenshots.
            CopyResourceIfChanged(
                "Assets/ProjectX/res/res/UI/Icon/ui_map_icon/ditu_shijie_worldmap.png",
                "Assets/ProjectX/Resources/WorldUI/worldmap.png");
            CopyResourceIfChanged(
                "Assets/ProjectX/res/res/UI/ui_zhandou/ui_jiesuan_shengli_bg.png",
                "Assets/ProjectX/Resources/WorldUI/battle_victory_bg.png");
            CopyResourceIfChanged(
                "Assets/ProjectX/res/res/UI/ui_zhandou/ui_jiesuan_shengli.png",
                "Assets/ProjectX/Resources/WorldUI/battle_victory.png");
            CopyResourceIfChanged(
                Path.Combine(cocosRoot, "res", "res", "UI", "ui_zhandou", "bg0.jpg"),
                "Assets/ProjectX/Resources/WorldUI/battle_scene_bg.jpg");
            // The source-tree copy is an unresolved LFS pointer in this checkout;
            // the native Cocos runtime consumes this hydrated simulator copy.
            CopyResourceIfChanged(
                Path.Combine(cocosRoot, "simulator", "win32", "res", "ConfigData", "hit_monster.dat"),
                "Assets/ProjectX/Resources/ProjectXConfig/battle/hit_monster.dat.bytes");
            CopyResourceIfChanged(
                Path.Combine(cocosRoot, "src", "ConfigData", "zhenfa_config_dat.lua"),
                "Assets/ProjectX/Resources/ProjectXConfig/battle/zhenfa_config_dat.txt");
            CopyResourceIfChanged(
                Path.Combine(cocosRoot, "simulator", "win32", "res", "res", "UI", "ImageNum", "num_lan.png"),
                "Assets/ProjectX/Resources/ProjectXBattle/Hud/num_lan.png");
            CopyResourceIfChanged(
                Path.Combine(cocosRoot, "simulator", "win32", "res", "res", "UI", "ImageNum", "ui_pk_num.png"),
                "Assets/ProjectX/Resources/ProjectXBattle/Hud/ui_pk_num.png");
            for (int formation = 1; formation <= 6; formation++)
            {
                CopyResourceIfChanged(
                    Path.Combine(cocosRoot, "simulator", "win32", "res", "res2", "Icon", "ui_zhenfa_icon", $"zhenfa_{formation}.png"),
                    $"Assets/ProjectX/Resources/HeroUI/formation_{formation}.png");
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
                    Path.Combine(cocosRoot, "src", "ConfigData", configName + ".lua"),
                    $"Assets/ProjectX/Resources/WorldUI/Config/{configName}.txt");
            }
            for (int map = 1; map <= 6; map++)
            {
                for (int tile = 1; tile <= 12; tile++)
                {
                    CopyResourceIfChanged(
                        Path.Combine(cocosRoot, "res", "fuben", $"map_{map}", $"map_{tile}.jpg"),
                        $"Assets/ProjectX/Resources/WorldUI/Maps/map_{map}/map_{tile}.jpg");
                }
            }
            for (int world = 1; world <= 3; world++)
            {
                CopyResourceIfChanged(
                    Path.Combine(cocosRoot, "res", "res", "UI", "Icon", "ui_map_icon", $"fuben_map{world}.png"),
                    $"Assets/ProjectX/Resources/WorldUI/Chapters/fuben_map{world}.png");
            }
            string petBasicConfig = Path.Combine(repositoryRoot, "server", "config", "xml", "pet_basic_config.xml");
            string skillBasicConfig = Path.Combine(repositoryRoot, "server", "config", "xml", "skill_basic.xml");
            string skillActiveEffectConfig = Path.Combine(repositoryRoot, "server", "config", "xml", "skill_active_effect.xml");
            string skillAdditiveEffectConfig = Path.Combine(repositoryRoot, "server", "config", "xml", "skill_additive_effect.xml");
            CopyResourceIfChanged(petBasicConfig, "Assets/ProjectX/Resources/Configs/pet_basic_config.xml");
            CopyResourceIfChanged(skillBasicConfig, "Assets/ProjectX/Resources/Configs/skill_basic.xml");
            CopyResourceIfChanged(skillActiveEffectConfig, "Assets/ProjectX/Resources/Configs/skill_active_effect.xml");
            CopyResourceIfChanged(skillAdditiveEffectConfig, "Assets/ProjectX/Resources/Configs/skill_additive_effect.xml");
            IEnumerable<int> heroSkillIds = XDocument.Load(petBasicConfig).Root?.Elements("CONTENT")
                .Select(element => (element.Attribute("skill")?.Value ?? "").Split(';').FirstOrDefault())
                .Select(value => int.TryParse(value, out int parsed) ? parsed : 0)
                .Where(value => value > 0)
                .Distinct()
                ?? Enumerable.Empty<int>();
            foreach (int skillId in heroSkillIds)
            {
                CopyResourceIfChanged(
                    Path.Combine(repositoryRoot, "client", "ProjectX", "res", "Skill", "UI", $"skill_{skillId}.png"),
                    $"Assets/ProjectX/Resources/HeroUI/skill_{skillId}.png");
            }
            foreach (string configName in new[] { "fabao_qianghua", "fabao_jinglian", "master" })
            {
                CopyResourceIfChanged(
                    Path.Combine(repositoryRoot, "server", "config", "json", configName + ".json"),
                    $"Assets/ProjectX/Resources/Configs/{configName}.json");
            }
            CopyResourceIfChanged(
                "Assets/ProjectX/res/res/UI/ui_shenjiang/ui_shenjiang_zhanli_A.png",
                "Assets/ProjectX/Resources/HeroUI/quality_score_A.png");
            CopyResourceIfChanged(
                "Assets/ProjectX/res/res/UI/ui_shenjiang/ui_shenjiang_zhanli_s.png",
                "Assets/ProjectX/Resources/HeroUI/quality_score_S.png");
            CopyResourceIfChanged(
                "Assets/ProjectX/res/res/UI/ui_shenjiang/ui_shenjiang_zhanli_ss.png",
                "Assets/ProjectX/Resources/HeroUI/quality_score_SS.png");
            CopyResourceIfChanged(
                "Assets/ProjectX/res/res/UI/ui_shenjiang/ui_shenjiang_zhanli_sss.png",
                "Assets/ProjectX/Resources/HeroUI/quality_score_SSS.png");
            CopyResourceIfChanged(
                "Assets/ProjectX/res/res/UI/ui_shenjiang/ui_shenjiang_zhanli_ssss.png",
                "Assets/ProjectX/Resources/HeroUI/quality_score_SSSS.png");
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

        private static bool IsGitLfsPointer(byte[] content)
        {
            if (content == null || content.Length == 0 || content.Length > 512) return false;
            byte[] marker = Encoding.ASCII.GetBytes("version https://git-lfs.github.com/spec/v1");
            if (content.Length < marker.Length) return false;
            for (int index = 0; index < marker.Length; index++)
                if (content[index] != marker[index]) return false;
            return true;
        }

        [MenuItem("Tools/ProjectX App/Force Rebuild Bootstrap Scene", priority = 91)]
        public static void ForceRebuild()
        {
            EnsureFloatNoticePrefab();
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

        [MenuItem("Tools/ProjectX App/Validate Resource Foundation", priority = 92)]
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
            foreach (string pilot in new[] { "HeroBook", "HeroRecycle" })
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
            Scene scene = EditorSceneManager.OpenScene(BootstrapScene, OpenSceneMode.Single);
            Transform root = scene.GetRootGameObjects().Single(item => item.name == "Canvas").transform;
            using (var provider = new ResourcesUiAssetProvider(root))
            {
                if (provider.LoadedSingletonCount != 0 || provider.LoadedTransientCount != 0)
                    throw new InvalidDataException("UI provider must start without loaded views.");

                CocosUiView settings = provider.FindOrLoadBySource("zhujue/SystemLayer");
                CocosUiView settingsAgain = provider.GetOrCreate("SystemLayer");
                if (settings == null || !ReferenceEquals(settings, settingsAgain) || provider.LoadedSingletonCount != 1)
                    throw new InvalidDataException("UI provider singleton contract failed for Settings.");

                CocosUiView taskFrame = provider.GetOrCreate("huodong_bg");
                CocosUiView task = provider.FindOrLoadBySource("huodong/RenwuLayer");
                if (task == null || taskFrame == null || task.GameObject.transform.parent != taskFrame.GameObject.transform)
                    throw new InvalidDataException("UI provider parent-child composition contract failed for Task.");

                CocosUiView heroBookA = provider.Instantiate("HeroBook", root);
                CocosUiView heroBookB = provider.Instantiate("HeroBook", root);
                if (ReferenceEquals(heroBookA, heroBookB) || provider.LoadedTransientCount != 2)
                    throw new InvalidDataException("UI provider transient instance contract failed for HeroBook.");
                if (!provider.Release(heroBookA) || !provider.Release(heroBookB) || provider.LoadedTransientCount != 0)
                    throw new InvalidDataException("UI provider transient release contract failed for HeroBook.");

                CocosUiView heroRecycle = provider.Instantiate("HeroRecycle", root);
                if (provider.LoadedTransientCount != 1 || !provider.Release(heroRecycle)
                    || provider.LoadedTransientCount != 0)
                    throw new InvalidDataException("UI provider lifecycle contract failed for HeroRecycle.");
            }
            if (root.childCount != 0)
                throw new InvalidDataException($"UI provider disposal left {root.childCount} objects under Bootstrap Canvas.");
        }

        private static void NormalizeBootstrapSceneYaml()
        {
            string absolutePath = Path.GetFullPath(BootstrapScene);
            string content = File.ReadAllText(absolutePath);
            string newline = content.Contains("\r\n") ? "\r\n" : "\n";
            string[] lines = content.Replace("\r\n", "\n").Split('\n');
            string normalized = string.Join(newline, lines.Select(line => line.TrimEnd(' ', '\t')));
            if (string.Equals(content, normalized, System.StringComparison.Ordinal)) return;
            File.WriteAllText(absolutePath, normalized, new UTF8Encoding(false));
            AssetDatabase.ImportAsset(BootstrapScene, ImportAssetOptions.ForceSynchronousImport);
        }

        private static void EnsureFloatNoticePrefab()
        {
            GameObject existing = AssetDatabase.LoadAssetAtPath<GameObject>(GameplayFloatNoticePrefab);
            if (existing != null)
            {
                CocosUiBinding existingBinding = existing.GetComponent<CocosUiBinding>();
                if (existingBinding != null && !string.IsNullOrWhiteSpace(existingBinding.Source)) return;
                GameObject editable = PrefabUtility.LoadPrefabContents(GameplayFloatNoticePrefab);
                try
                {
                    CocosUiBinding binding = editable.GetComponent<CocosUiBinding>()
                        ?? editable.AddComponent<CocosUiBinding>();
                    binding.Initialize("Generated/FloatNoticeLayer", new List<CocosNodeReference>());
                    PrefabUtility.SaveAsPrefabAsset(editable, GameplayFloatNoticePrefab);
                }
                finally
                {
                    PrefabUtility.UnloadPrefabContents(editable);
                }
                return;
            }

            Sprite background = AssetDatabase.LoadAssetAtPath<Sprite>(FloatNoticeBackground);
            Font font = AssetDatabase.LoadAssetAtPath<Font>(FloatNoticeFont);
            if (background == null) throw new FileNotFoundException($"FloatNotice background is missing: {FloatNoticeBackground}");
            if (font == null) throw new FileNotFoundException($"FloatNotice font is missing: {FloatNoticeFont}");

            GameObject root = new GameObject("FloatNoticeLayer", typeof(RectTransform));
            root.AddComponent<CocosUiBinding>().Initialize("Generated/FloatNoticeLayer", new List<CocosNodeReference>());
            RectTransform rootRect = root.GetComponent<RectTransform>();
            rootRect.anchorMin = Vector2.zero;
            rootRect.anchorMax = Vector2.one;
            rootRect.offsetMin = rootRect.offsetMax = Vector2.zero;

            GameObject bar = new GameObject("BottomLayout", typeof(RectTransform), typeof(Image));
            RectTransform barRect = bar.GetComponent<RectTransform>();
            barRect.SetParent(rootRect, false);
            barRect.anchorMin = barRect.anchorMax = new Vector2(0.5f, 0f);
            barRect.pivot = new Vector2(0.5f, 0f);
            barRect.anchoredPosition = Vector2.zero;
            barRect.sizeDelta = new Vector2(1200.6f, 30f);
            Image image = bar.GetComponent<Image>();
            image.sprite = background;
            image.type = Image.Type.Sliced;
            image.raycastTarget = false;

            GameObject label = new GameObject("Text", typeof(RectTransform), typeof(Text));
            RectTransform labelRect = label.GetComponent<RectTransform>();
            labelRect.SetParent(barRect, false);
            labelRect.anchorMin = Vector2.zero;
            labelRect.anchorMax = Vector2.one;
            labelRect.offsetMin = labelRect.offsetMax = Vector2.zero;
            Text text = label.GetComponent<Text>();
            text.font = font;
            text.fontSize = 20;
            text.alignment = TextAnchor.MiddleCenter;
            text.color = Color.white;
            text.supportRichText = true;
            text.raycastTarget = false;

            Directory.CreateDirectory(Path.GetDirectoryName(GameplayFloatNoticePrefab));
            PrefabUtility.SaveAsPrefabAsset(root, GameplayFloatNoticePrefab);
            UnityEngine.Object.DestroyImmediate(root);
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
