#if UNITY_EDITOR
using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using System.IO;
using System.Text;

namespace ProjectX.UI.Migration.Editor
{
    /// <summary>
    /// 只读统计 / 可选移除 prefab 上挂的 CocosUiBinding、CocosNodeMetadata 组件实例。
    /// 不删除 .cs 类定义；组件移除经由 PrefabUtility，由 Unity 维护 m_Component 引用，
    /// 不会像文本硬删 YAML 那样损坏 prefab 序列化。
    ///
    /// 安全模型：
    ///  - SAFE    : 路径段或文件名含 backup/deprecated/discard/_old/temp 等弃用标记 -> 默认可移除
    ///  - PROTECTED: 命中 ProtectedPatterns -> 永不触碰（留空则靠运行时依赖启发式）
    ///  - ACTIVE  : 其余运行时资源 -> Metadata 与 Binding 分别控制；移除 Metadata 前先保存缺失别名
    /// DRY RUN 模式只报不改；EXECUTE 模式默认仅剥离 SAFE 类，ACTIVE 需二次确认。
    /// </summary>
    public class CocosBindingCleaner : EditorWindow
    {
        bool dryRun = true;
        bool allowActiveMetadataRemoval = false;
        bool allowActiveBindingRemoval = false;
        Vector2 scroll;
        readonly List<string> logLines = new List<string>();

        // 弃用/可安全剥离的标记（路径段或文件名，忽略大小写）
        static readonly string[] SafeTokens = { "backup", "deprecated", "discard", "_old", "temp" };
        // 永不触碰的路径片段（按需补充）
        static readonly string[] ProtectedPatterns = { };
        // 运行时硬依赖这两个组件、用于 dry-run 报告"对应 Presenter"的源码
        static readonly string[] DepSourceFiles = {
            "DrawPresenter.cs", "ShopQuantityPresenter.cs", "ResourcesUiAssetProvider.cs",
            "CocosTimelinePlayer.cs", "HeroEquipmentPresenter.cs", "CocosUiView.cs",
            "ProjectXApp.cs", "UiRouter.cs"
        };

        [MenuItem("Tools/ProjectX 工具/CocosBinding Cleaner")]
        static void Open() { GetWindow<CocosBindingCleaner>("CocosBinding Cleaner"); }

        void OnGUI()
        {
            EditorGUILayout.LabelField("CocosUiBinding / CocosNodeMetadata 组件清理", EditorStyles.boldLabel);
            EditorGUILayout.HelpBox(
                "统计 prefab 上这两个迁移桥接组件的挂载并可选移除（不删 .cs）。\n" +
                "移除 Metadata 前会将 Binding 缺失的身份别名序列化保存；Binding 单独控制。\n" +
                "DRY RUN = 只报告不修改；ACTIVE 组件移除需分别勾选并二次确认。\n" +
                "建议执行前先 git 提交，以便回滚。", MessageType.Info);
            dryRun = EditorGUILayout.ToggleLeft("Dry Run（只报告，不修改文件）", dryRun);
            allowActiveMetadataRemoval = EditorGUILayout.ToggleLeft("允许 ACTIVE Metadata 迁移身份后移除", allowActiveMetadataRemoval);
            allowActiveBindingRemoval = EditorGUILayout.ToggleLeft("允许移除 ACTIVE Binding（通常应保留）", allowActiveBindingRemoval);

            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Button("运行扫描", GUILayout.Width(120)))
            {
                if (!dryRun && !EditorUtility.DisplayDialog("确认执行",
                    "将真正从 prefab 移除组件。建议先 git 提交以便回滚。继续？", "继续", "取消"))
                    return;
                Run();
            }
            if (GUILayout.Button("清空日志", GUILayout.Width(120))) logLines.Clear();
            EditorGUILayout.EndHorizontal();

            scroll = EditorGUILayout.BeginScrollView(scroll, GUILayout.ExpandHeight(true));
            foreach (var l in logLines) EditorGUILayout.LabelField(l, EditorStyles.wordWrappedLabel);
            EditorGUILayout.EndScrollView();
        }

        void Run()
        {
            logLines.Clear();
            var sb = new StringBuilder();
            sb.AppendLine($"=== CocosBinding Cleaner {(dryRun ? "[DRY RUN]" : "[EXECUTE]")} {System.DateTime.Now:yyyy-MM-dd HH:mm:ss} ===");

            string[] guids = AssetDatabase.FindAssets("t:Prefab");
            int total = 0, safe = 0, active = 0, prot = 0;
            int bTotal = 0, mTotal = 0, bRem = 0, mRem = 0;
            var removed = new List<string>();

            foreach (var g in guids)
            {
                string path = AssetDatabase.GUIDToAssetPath(g);
                if (!path.EndsWith(".prefab")) continue;
                // Unity package cache prefabs are not ours and create noise in the report.
                if (path.StartsWith("Packages/")) continue;
                total++;

                var go = PrefabUtility.LoadPrefabContents(path);
                var b = go.GetComponentsInChildren<CocosUiBinding>(true);
                var m = go.GetComponentsInChildren<CocosNodeMetadata>(true);
                bTotal += b.Length; mTotal += m.Length;

                string cat = Classify(path);
                bool removeMetadata;
                bool removeBinding;
                if (cat == "PROTECTED")
                {
                    prot++;
                    removeMetadata = false;
                    removeBinding = false;
                }
                else if (cat == "SAFE")
                {
                    safe++;
                    removeMetadata = true;
                    removeBinding = allowActiveBindingRemoval;
                }
                else
                {
                    active++;
                    removeMetadata = allowActiveMetadataRemoval;
                    removeBinding = allowActiveBindingRemoval;
                }

                bool removeAny = (removeMetadata && m.Length > 0) || (removeBinding && b.Length > 0);
                int metadataAliasesToPreserve = removeMetadata ? CountMetadataAliases(m) : 0;
                if (removeMetadata && m.Length > 0)
                {
                    bool hasOwnerForAllMetadata = true;
                    foreach (CocosNodeMetadata item in m)
                    {
                        CocosUiBinding owner = item != null ? item.GetComponentInParent<CocosUiBinding>() : null;
                        if (owner == null) { hasOwnerForAllMetadata = false; break; }
                    }
                    if (!hasOwnerForAllMetadata)
                    {
                        Emit(sb, $"[BLOCKED][{cat}] {path} Metadata without owning Binding; no components changed");
                        removeAny = false;
                    }
                }

                if (removeAny)
                {
                    var deps = FindDependentSources(Path.GetFileNameWithoutExtension(path));
                    if (dryRun)
                    {
                        Emit(sb, $"[DRYRUN][{cat}] {path} binding={(removeBinding ? b.Length : 0)} meta={(removeMetadata ? m.Length : 0)} migrateAliases={metadataAliasesToPreserve} deps=[{string.Join(",", deps)}]");
                    }
                    else
                    {
                        if (removeMetadata)
                        {
                            foreach (CocosNodeMetadata item in m)
                            {
                                CocosUiBinding owner = item.GetComponentInParent<CocosUiBinding>();
                                owner.PreserveLegacyMetadataPathAlias(item);
                                Object.DestroyImmediate(item);
                            }
                        }
                        if (removeBinding)
                            foreach (var c in b) Object.DestroyImmediate(c);
                        PrefabUtility.SaveAsPrefabAsset(go, path);
                        bRem += removeBinding ? b.Length : 0; mRem += removeMetadata ? m.Length : 0;
                        removed.Add(path);
                        Emit(sb, $"[REMOVED][{cat}] {path} binding={(removeBinding ? b.Length : 0)} meta={(removeMetadata ? m.Length : 0)} migrateAliases={metadataAliasesToPreserve} deps=[{string.Join(",", deps)}]");
                    }
                }
                else
                {
                    Emit(sb, $"[KEEP][{cat}] {path} binding={b.Length} meta={m.Length}");
                }
                PrefabUtility.UnloadPrefabContents(go);
            }

            sb.AppendLine("--- 汇总 ---");
            sb.AppendLine($"prefab 总数={total}  SAFE={safe}  ACTIVE={active}  PROTECTED={prot}");
            sb.AppendLine($"CocosUiBinding   共 {bTotal}  移除 {bRem}");
            sb.AppendLine($"CocosNodeMetadata 共 {mTotal}  移除 {mRem}");
            if (!dryRun) sb.AppendLine($"实际移除 {removed.Count} 个 prefab（建议 git 提交回滚）");
            Emit(sb, "--- 汇总 ---");
            Emit(sb, $"prefab={total} SAFE={safe} ACTIVE={active} PROTECTED={prot} | binding 移除{bRem}/{bTotal} | metadata 移除{mRem}/{mTotal}");

            string outDir = Path.GetFullPath(Path.Combine(
                Application.dataPath, "..", "..", ".local", "unity-validation"));
            Directory.CreateDirectory(outDir);
            string outPath = Path.Combine(outDir,
                $"cocos_binding_cleanup_{(dryRun ? "dryrun" : "execute")}_{System.DateTime.Now:yyyyMMdd_HHmmss}.txt");
            File.WriteAllText(outPath, sb.ToString());
            Emit(sb, $"报告已写出: {outPath}");

            if (!dryRun) AssetDatabase.Refresh();
        }

        void Emit(StringBuilder sb, string line) { sb.AppendLine(line); logLines.Add(line); }

        static int CountMetadataAliases(CocosNodeMetadata[] metadata)
        {
            int count = 0;
            foreach (CocosNodeMetadata item in metadata)
            {
                if (item == null) continue;
                CocosUiBinding owner = item.GetComponentInParent<CocosUiBinding>();
                if (owner == null) continue;
                bool exact = false;
                foreach (CocosNodeReference reference in owner.Nodes)
                {
                    if (reference != null && reference.target == item.gameObject
                        && reference.path == item.CocosPath && reference.nodeType == item.NodeType
                        && reference.tag == item.Tag && reference.actionTag == item.ActionTag)
                    {
                        exact = true;
                        break;
                    }
                }
                if (!exact) count++;
            }
            return count;
        }

        string Classify(string path)
        {
            foreach (var p in ProtectedPatterns)
                if (path.IndexOf(p, System.StringComparison.OrdinalIgnoreCase) >= 0) return "PROTECTED";

            // 路径段标记（backup/deprecated/discard/temp 等整段）
            var segs = path.ToLowerInvariant().Split('/', '\\');
            foreach (var seg in segs)
            {
                string s = Path.GetFileNameWithoutExtension(seg);
                foreach (var t in SafeTokens)
                {
                    if (s == t || s.EndsWith("_" + t) || s.StartsWith(t + "_") || s.Contains("_" + t + "_"))
                        return "SAFE";
                }
            }
            // 文件名标记（_old 等）
            string file = Path.GetFileNameWithoutExtension(path).ToLowerInvariant();
            foreach (var t in SafeTokens)
            {
                if (file == t || file.EndsWith("_" + t) || file.StartsWith(t + "_") || file.Contains("_" + t + "_"))
                    return "SAFE";
            }
            return "ACTIVE";
        }

        Dictionary<string, string> _srcCache;
        List<string> FindDependentSources(string prefabName)
        {
            if (_srcCache == null)
            {
                _srcCache = new Dictionary<string, string>();
                foreach (var f in DepSourceFiles)
                {
                    var gs = AssetDatabase.FindAssets(Path.GetFileNameWithoutExtension(f) + " t:Script");
                    foreach (var x in gs)
                    {
                        string p = AssetDatabase.GUIDToAssetPath(x);
                        if (Path.GetFileName(p) == f) { _srcCache[f] = p; break; }
                    }
                }
            }
            var r = new List<string>();
            foreach (var kv in _srcCache)
            {
                try { if (File.ReadAllText(kv.Value).Contains(prefabName)) r.Add(Path.GetFileName(kv.Value)); }
                catch (System.Exception) { /* 读不到跳过 */ }
            }
            return r;
        }
    }
}
#endif
