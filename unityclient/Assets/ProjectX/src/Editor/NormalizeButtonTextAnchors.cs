#if UNITY_EDITOR
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using UnityEditor;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Editor
{
    /// <summary>
    /// Normalizes only single, direct button captions in project Prefabs.
    /// The preview menu writes a report without modifying any Prefab.
    /// </summary>
    public static class NormalizeButtonTextAnchors
    {
        private const string ReportDirectory = ".local/unity-validation";
        private static readonly HashSet<string> PositionedCaptionPaths = new HashSet<string>(StringComparer.Ordinal)
        {
            "FightLayer/FightUI/btn_Formation_Enemy/Text_name",
            "FightLayer/FightUI/btn_Formation_Oneself/Text_name",
            "FightLayer/FightUI/Buttons/btn_jump/Text",
            "JingjiLayer/ImageBg/Bg/Btn_1/Text",
            "JingjiLayer/ImageBg/Bg/Btn_2/Text",
            "JingjiLayer/ImageBg/Bg/Btn_3/Text",
            "JingjiLayer/ImageBg_1/Btn/Text",
            "JingjiLayer/ImageBg_2/Btn/Text",
            "DrawCardsLayer/Panel/Function/RanksBtn/Text",
            "DrawCardsLayer/Panel/Function/PetBtn/Text",
            "duihualayer/DialogUI/Button_skip/Text",
            "guanqiaxiangxiLayer/Panel_1/Pane/Descbg/Image_bg/Panel_1/Duizhan/Text",
            "guanqiaxiangxiLayer/Panel_1/Pane/Descbg/Image_bg/Panel_1/Buzhen/Text",
            "MountjinjieLayer/MountjinjieUI/btn_Material/Value_0",
        };

        [MenuItem("Tools/ProjectX 界面/按钮下文字锚点/预览")]
        public static void PreviewMenu()
        {
            Run(false);
        }

        [MenuItem("Tools/ProjectX 界面/按钮下文字锚点/执行")]
        public static void ExecuteMenu()
        {
            if (!EditorUtility.DisplayDialog(
                "统一按钮文字锚点",
                "将扫描项目内所有 Prefab，只修改 uGUI Button 的唯一直接标题 Text/TMP_Text。\n" +
                "锚点设为全拉伸，Left/Top/Right/Bottom 均为 0。其他节点不修改。\n\n建议先运行“预览”并检查报告。继续执行？",
                "执行",
                "取消"))
                return;

            Run(true);
        }

        private static void Run(bool execute)
        {
            string mode = execute ? "EXECUTE" : "DRY RUN";
            var report = new StringBuilder();
            report.AppendLine("=== Button text stretch anchors " + mode + " " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " ===");
            report.AppendLine("Scope: project Prefabs except Packages; single direct button caption Text/TMP_Text, excluding verified positioned data text.");
            report.AppendLine("Target: anchorMin=(0,0), anchorMax=(1,1), offsetMin=(0,0), offsetMax=(0,0). Pivot and all other properties are preserved.");

            string[] prefabGuids = AssetDatabase.FindAssets("t:Prefab");
            int prefabCount = 0;
            int matchedTextCount = 0;
            int plannedTextCount = 0;
            int plannedPrefabCount = 0;
            int changedTextCount = 0;
            int changedPrefabCount = 0;
            int failedPrefabCount = 0;

            foreach (string guid in prefabGuids)
            {
                string prefabPath = AssetDatabase.GUIDToAssetPath(guid);
                if (string.IsNullOrEmpty(prefabPath)
                    || !prefabPath.EndsWith(".prefab", StringComparison.OrdinalIgnoreCase)
                    || prefabPath.StartsWith("Packages/", StringComparison.OrdinalIgnoreCase))
                    continue;

                prefabCount++;
                GameObject root = null;
                bool prefabChanged = false;
                bool prefabPlanned = false;
                try
                {
                    root = PrefabUtility.LoadPrefabContents(prefabPath);
                    if (root == null)
                        throw new InvalidOperationException("LoadPrefabContents returned null.");

                    var processedRects = new HashSet<int>();
                    Component[] components = root.GetComponentsInChildren<Component>(true);
                    foreach (Component component in components)
                    {
                        if (component == null || !IsTextComponent(component))
                            continue;

                        Button owningButton = FindAncestorButton(component.transform);
                        if (owningButton == null || !IsSingleDirectCaption(component, owningButton)
                            || IsHeroCardDataName(component, owningButton)
                            || IsPositionedDataText(component, owningButton, prefabPath))
                            continue;

                        RectTransform rect = component.transform as RectTransform;
                        if (rect == null || !processedRects.Add(rect.GetInstanceID()))
                            continue;

                        matchedTextCount++;
                        bool needsChange = !IsTarget(rect);
                        report.AppendLine((needsChange ? (execute ? "SET " : "WOULD SET ") : "UNCHANGED ")
                            + prefabPath + " | button=" + GetHierarchyPath(owningButton.transform)
                            + " | text=" + GetHierarchyPath(component.transform));

                        if (!needsChange)
                            continue;

                        plannedTextCount++;
                        prefabPlanned = true;
                        if (!execute)
                            continue;

                        rect.anchorMin = Vector2.zero;
                        rect.anchorMax = Vector2.one;
                        rect.offsetMin = Vector2.zero;
                        rect.offsetMax = Vector2.zero;
                        EditorUtility.SetDirty(rect);
                        prefabChanged = true;
                        changedTextCount++;
                    }

                    if (prefabPlanned)
                        plannedPrefabCount++;

                    if (prefabChanged)
                    {
                        GameObject saved = PrefabUtility.SaveAsPrefabAsset(root, prefabPath);
                        if (saved == null)
                            throw new InvalidOperationException("SaveAsPrefabAsset returned null.");
                        changedPrefabCount++;
                    }
                }
                catch (Exception exception)
                {
                    failedPrefabCount++;
                    report.AppendLine("ERROR " + prefabPath + " | " + exception.GetType().Name + ": " + exception.Message);
                }
                finally
                {
                    if (root != null)
                        PrefabUtility.UnloadPrefabContents(root);
                }
            }

            report.AppendLine("SUMMARY prefabs=" + prefabCount
                + " matchingTextNodes=" + matchedTextCount
                + " plannedTextNodes=" + plannedTextCount
                + " plannedPrefabs=" + plannedPrefabCount
                + " changedTextNodes=" + changedTextCount
                + " changedPrefabs=" + changedPrefabCount
                + " failedPrefabs=" + failedPrefabCount);
            report.AppendLine(execute
                ? "EXECUTE complete. Only matching text RectTransforms were saved."
                : "DRY RUN only. No Prefab was modified or saved.");

            string projectRoot = Path.GetFullPath(Path.Combine(Application.dataPath, "..", ".."));
            string reportDirectory = Path.Combine(projectRoot, ReportDirectory.Replace('/', Path.DirectorySeparatorChar));
            Directory.CreateDirectory(reportDirectory);
            string reportPath = Path.Combine(reportDirectory,
                "w6.7-button-text-anchors-" + (execute ? "execute" : "preview") + "-" + DateTime.Now.ToString("yyyyMMdd-HHmmss") + ".txt");
            File.WriteAllText(reportPath, report.ToString(), new UTF8Encoding(false));

            Debug.Log("Button text anchor " + mode + " report: " + reportPath
                + " | prefabs=" + prefabCount
                + " textNodes=" + matchedTextCount
                + " planned=" + plannedTextCount
                + " changed=" + changedTextCount
                + " failed=" + failedPrefabCount);
        }

        private static Button FindAncestorButton(Transform textTransform)
        {
            for (Transform parent = textTransform.parent; parent != null; parent = parent.parent)
            {
                Button button = parent.GetComponent<Button>();
                if (button != null)
                    return button;
            }

            return null;
        }

        private static bool IsSingleDirectCaption(Component component, Button owningButton)
        {
            if (component.transform.parent != owningButton.transform)
                return false;

            int textCount = 0;
            foreach (Component child in owningButton.GetComponentsInChildren<Component>(true))
            {
                if (child != null && IsTextComponent(child)
                    && FindAncestorButton(child.transform) == owningButton
                    && ++textCount > 1)
                    return false;
            }

            return textCount == 1;
        }

        private static bool IsHeroCardDataName(Component component, Button owningButton)
        {
            // Draw preview cards are Buttons for selection, but their hero Name is
            // positioned beneath the portrait. Stretching it to the IconBg/Bg image
            // covers the portrait and breaks the card layout; it is data, not a
            // caption on the clickable card.
            Transform parent = component.transform.parent;
            return string.Equals(component.name, "Name", StringComparison.Ordinal)
                && owningButton.name.StartsWith("IconBg_", StringComparison.Ordinal)
                && parent != null
                && string.Equals(parent.name, "Bg", StringComparison.Ordinal)
                && parent.GetComponent<Image>() != null;
        }

        private static bool IsPositionedDataText(Component component, Button owningButton, string prefabPath)
        {
            // These labels are placed beside or below portraits, equipment and icon
            // buttons. Stretching them covers the artwork, as the W6.7 Play capture
            // showed. Keep their authored RectTransforms when the batch is rerun.
            if (PositionedCaptionPaths.Contains(GetHierarchyPath(component.transform)))
                return true;

            string textName = component.name.ToLowerInvariant();
            if (textName == "name" || textName == "value" || textName == "num"
                || textName == "level" || textName == "time" || textName == "equipnum")
                return true;

            string buttonName = owningButton.name.ToLowerInvariant();
            if (buttonName.StartsWith("iconbg", StringComparison.Ordinal)
                || buttonName.StartsWith("equipicon", StringComparison.Ordinal)
                || buttonName.StartsWith("item", StringComparison.Ordinal)
                || buttonName.StartsWith("slot", StringComparison.Ordinal)
                || buttonName.StartsWith("rolebg", StringComparison.Ordinal)
                || buttonName.StartsWith("chapterpage", StringComparison.Ordinal))
                return true;

            if (prefabPath.EndsWith("/chouka/shenjiangzhaomu.prefab", StringComparison.Ordinal)
                && (owningButton.name == "Btn_Recruit_1"
                    || (owningButton.name == "Btn_Recruit_2" && component.name == "Text_1")
                    || owningButton.name == "RewardPreview" || owningButton.name == "Shop"))
                return true;

            if (prefabPath.EndsWith("/shenjiangyangcheng/yingxiongInfoLayer.prefab", StringComparison.Ordinal))
            {
                Transform parent = component.transform.parent;
                if (parent == owningButton.transform
                    && owningButton.name.StartsWith("EquipIcon", StringComparison.Ordinal)
                    && (component.name == "name" || component.name == "Text"))
                    return true;

                if (parent == owningButton.transform
                    && ((owningButton.name == "Button1" && component.name == "Text_17")
                        || (owningButton.name == "Button2" && component.name == "Text")))
                    return true;

                if (owningButton.name == "Btn_Skill" && parent != null
                    && (parent.name == "Panel_skill" || parent.name == "Panel_skill2"))
                    return true;
            }

            if (prefabPath.EndsWith("/shenjiangyangcheng/yingxiongListLayer.prefab", StringComparison.Ordinal)
                && owningButton.name == "Item")
            {
                for (Transform ancestor = component.transform.parent;
                    ancestor != null && ancestor != owningButton.transform; ancestor = ancestor.parent)
                {
                    if (ancestor.name == "bg_Head" || ancestor.name == "bg_Lock")
                        return true;
                }
            }

            return false;
        }

        private static bool IsTextComponent(Component component)
        {
            if (component is Text)
                return true;

            // Resolve TMP by its base type name to keep ProjectX.Editor independent
            // of an optional TMPro assembly reference.
            for (Type type = component.GetType(); type != null; type = type.BaseType)
            {
                if (string.Equals(type.FullName, "TMPro.TMP_Text", StringComparison.Ordinal))
                    return true;
            }

            return false;
        }

        private static bool IsTarget(RectTransform rect)
        {
            const float epsilon = 0.0001f;
            return (rect.anchorMin - Vector2.zero).sqrMagnitude < epsilon
                && (rect.anchorMax - Vector2.one).sqrMagnitude < epsilon
                && rect.offsetMin.sqrMagnitude < epsilon
                && rect.offsetMax.sqrMagnitude < epsilon;
        }

        private static string GetHierarchyPath(Transform target)
        {
            var names = new Stack<string>();
            for (Transform current = target; current != null; current = current.parent)
                names.Push(current.name);
            return string.Join("/", names.ToArray());
        }
    }
}
#endif
