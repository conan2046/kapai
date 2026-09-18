// UiCostProbe — 临时 UI 层常驻/开销探针（验证后可删除，不依赖任何业务代码）
//
// 两种模式：
//   1) 实时记录：挂到场景任意常驻物体后运行游戏，把每个 UI 界面打开一次，
//      脚本自动记录每个 DynamicUi_* 实例的体量，并区分"仅隐藏(Hidden)"还是"已销毁(Destroyed)"。
//   2) 全量扫描：按 F9 或勾选 runCatalogScanOnStart，自动遍历 Catalog 全部 133 层，
//      测量每层的节点数 / Sprite 数 / 纹理上界 / 实例化耗时。
// 按 F10 导出 JSON + CSV 到 Application.persistentDataPath，把文件交给 AI 做排序分析。
//
// 注意：texBytes 为 RGBA32 未压缩上界，真机压缩后约为 1/4~1/8，仅供相对排序。

using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using ProjectX.UI;
using ProjectX.UI.Migration;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Profiling;
#if UNITY_EDITOR
using UnityEditor.SceneManagement;
#endif

namespace ProjectX.Diagnostics
{
    [AddComponentMenu("ProjectX/Diagnostics/UiCostProbe")]
    public sealed class UiCostProbe : MonoBehaviour
    {
        public KeyCode scanKey = KeyCode.F9;
        public KeyCode exportKey = KeyCode.F10;
        public bool runCatalogScanOnStart;
        public bool coldScan;            // 每项前强制卸载资源，测"首次打开/资源未缓存"耗时
        public bool logToConsole = true;

        public static UiCostProbe Instance { get; private set; }

        private float startTime;
        private readonly Dictionary<int, RtRecord> live = new Dictionary<int, RtRecord>();
        private readonly List<CatRecord> catalog = new List<CatRecord>();
        private bool scanRunning;
        private int releaseSuccesses;
        private int releaseFailures;

        private const string Prefix = "DynamicUi_";

        // ---------- lifecycle ----------
        private void Awake()
        {
            Instance = this;
            DontDestroyOnLoad(gameObject);
            startTime = Time.time;
        }

        private void Start()
        {
            if (runCatalogScanOnStart) StartCoroutine(ScanCatalogRoutine());
        }

        private void Update()
        {
            if (Input.GetKeyDown(scanKey) && !scanRunning)
                StartCoroutine(ScanCatalogRoutine());
            if (Input.GetKeyDown(exportKey))
                Export();
            // F9 creates a temporary provider and a large number of transient
            // objects. Do not let that diagnostic pass contaminate live records.
            if (!scanRunning) SampleLive();
        }

        // ---------- 实时记录（被动监听 DynamicUi_* 出现/消失） ----------
        private void SampleLive()
        {
            var bindings = Resources.FindObjectsOfTypeAll<CocosUiBinding>();
            var thisFrame = new HashSet<int>();
            foreach (var b in bindings)
            {
                if (b == null || b.gameObject == null) continue;
                if (!IsRuntimeSceneBinding(b)) continue;
                var name = b.gameObject.name;
                if (!name.StartsWith(Prefix)) continue;
                var key = name.Substring(Prefix.Length);
                int instanceId = b.gameObject.GetInstanceID();
                thisFrame.Add(instanceId);

                if (!live.TryGetValue(instanceId, out var rec))
                {
                    var view = new CocosUiView(b);
                    List<TextureRecord> textures = new List<TextureRecord>();
                    SampleView(view, out int nodes, out int sprites, out long tex, textures);
                    rec = new RtRecord
                    {
                        instanceId = instanceId,
                        key = key,
                        source = b.Source ?? string.Empty,
                        firstSeen = Time.time - startTime,
                        nodes = nodes,
                        sprites = sprites,
                        texBytes = tex,
                        textures = textures,
                        state = b.gameObject.activeInHierarchy ? "Visible" : "Hidden"
                    };
                    live[instanceId] = rec;
                }
                else
                {
                    rec.lastSeen = Time.time - startTime;
                    rec.state = b.gameObject.activeInHierarchy ? "Visible" : "Hidden";
                }
            }
            // Runtime-scene objects remain discoverable while inactive. Missing
            // instance IDs therefore mean the object was destroyed, not hidden.
            foreach (var kv in live)
                if (!thisFrame.Contains(kv.Key) && kv.Value.state != "Destroyed")
                    kv.Value.state = "Destroyed";
        }

        private static bool IsRuntimeSceneBinding(CocosUiBinding binding)
        {
            if (binding == null || !binding.gameObject.scene.IsValid()) return false;
#if UNITY_EDITOR
            if (EditorSceneManager.IsPreviewScene(binding.gameObject.scene)) return false;
#endif
            return true;
        }

        // ---------- 全量扫描（遍历 Catalog 全部层） ----------
        private IEnumerator ScanCatalogRoutine()
        {
            scanRunning = true;
            if (logToConsole) Debug.Log("[UiCostProbe] catalog scan start...");

            var cat = Resources.Load<UiPrefabCatalog>("UiPrefabs/Catalog");
            if (cat == null)
            {
                Debug.LogError("[UiCostProbe] UiPrefabCatalog not found at Resources/UiPrefabs/Catalog");
                scanRunning = false;
                yield break;
            }

            var tempRoot = new GameObject("__UiCostProbe_TempRoot").transform;
            var provider = new ResourcesUiAssetProvider(tempRoot);
            catalog.Clear();
            releaseSuccesses = 0;
            releaseFailures = 0;

            var entries = cat.Entries;
            var byKey = entries.ToDictionary(e => e.Key, e => e);
            int done = 0;
            foreach (var entry in entries)
            {
                var sw = System.Diagnostics.Stopwatch.StartNew();
                CocosUiView view = null;
                try { view = provider.GetOrCreate(entry.Key); }
                catch (System.Exception ex)
                {
                    if (logToConsole) Debug.LogWarning($"[UiCostProbe] GetOrCreate failed: {entry.Key} -> {ex.Message}");
                }
                sw.Stop();

                int nodes = 0, sprites = 0; long tex = 0;
                if (view != null && view.IsAlive) SampleView(view, out nodes, out sprites, out tex);

                catalog.Add(new CatRecord
                {
                    key = entry.Key,
                    source = entry.Source ?? string.Empty,
                    parentKey = entry.ParentKey ?? string.Empty,
                    defaultActive = entry.DefaultActive,
                    nodes = nodes,
                    sprites = sprites,
                    texBytes = tex,
                    ms = sw.ElapsedMilliseconds
                });

                ReleaseChain(provider, entry, byKey);
                if (coldScan) yield return Resources.UnloadUnusedAssets();
                yield return null;

                if (logToConsole && (++done % 20 == 0))
                    Debug.Log($"[UiCostProbe] scanned {done}/{entries.Count}");
            }

            provider.Dispose();
            yield return Resources.UnloadUnusedAssets();
            Destroy(tempRoot.gameObject);
            scanRunning = false;
            if (logToConsole) Debug.Log($"[UiCostProbe] catalog scan done: {catalog.Count} entries. Press F10 to export.");
        }

        private void ReleaseChain(ResourcesUiAssetProvider provider, UiPrefabCatalogEntry entry,
            Dictionary<string, UiPrefabCatalogEntry> byKey)
        {
            var chain = new List<string>();
            var cur = entry;
            while (cur != null)
            {
                chain.Add(cur.Key);
                cur = string.IsNullOrEmpty(cur.ParentKey) ? null : (byKey.TryGetValue(cur.ParentKey, out var p) ? p : null);
            }
            foreach (var k in chain)
            {
                var v = provider.GetOrCreate(k);
                if (provider.Release(v)) releaseSuccesses++;
                else releaseFailures++;
            }
        }

        // ---------- 采样 ----------
        private static void SampleView(CocosUiView view, out int nodes, out int sprites, out long texBytes)
        {
            SampleView(view, out nodes, out sprites, out texBytes, null);
        }

        private static void SampleView(CocosUiView view, out int nodes, out int sprites, out long texBytes,
            List<TextureRecord> textureDetails)
        {
            nodes = 0; sprites = 0; texBytes = 0;
            var go = view.GameObject;
            if (go == null) return;

            nodes = go.GetComponentsInChildren<Transform>(true).Length;

            var seen = new HashSet<int>();
            long sum = 0; int count = 0;
            foreach (var img in go.GetComponentsInChildren<Image>(true))
            {
                if (img.sprite == null || img.sprite.texture == null) continue;
                int id = img.sprite.texture.GetInstanceID();
                if (seen.Add(id))
                {
                    long bytes = (long)img.sprite.texture.width * img.sprite.texture.height * 4;
                    sum += bytes;
                    count++;
                    textureDetails?.Add(new TextureRecord { instanceId = id, bytes = bytes });
                }
            }
            foreach (var raw in go.GetComponentsInChildren<RawImage>(true))
            {
                if (raw.texture == null) continue;
                int id = raw.texture.GetInstanceID();
                if (seen.Add(id))
                {
                    long bytes = (long)raw.texture.width * raw.texture.height * 4;
                    sum += bytes;
                    count++;
                    textureDetails?.Add(new TextureRecord { instanceId = id, bytes = bytes });
                }
            }
            sprites = count;
            texBytes = sum;
        }

        // ---------- 导出 ----------
        public void Export()
        {
            var uniqueTextures = new HashSet<int>();
            long uniqueTextureBytes = 0;
            foreach (RtRecord record in live.Values.Where(item => item.state != "Destroyed"))
            {
                foreach (TextureRecord texture in record.textures ?? new List<TextureRecord>())
                {
                    if (uniqueTextures.Add(texture.instanceId))
                        uniqueTextureBytes += texture.bytes;
                }
            }

            var report = new Report
            {
                unityVersion = Application.unityVersion,
                platform = Application.platform.ToString(),
                deviceModel = SystemInfo.deviceModel,
                baselineAllocatedMemoryMB = (Profiler.GetTotalAllocatedMemoryLong() >> 20),
                runtimeUniqueTextureCount = uniqueTextures.Count,
                runtimeUniqueTextureBytes = uniqueTextureBytes,
                releaseSuccesses = releaseSuccesses,
                releaseFailures = releaseFailures,
                exportedAt = System.DateTime.Now.ToString("o", CultureInfo.InvariantCulture),
                live = live.Values.ToList(),
                catalog = catalog
            };

            string json = JsonUtility.ToJson(report, true);
            string stamp = System.DateTime.Now.ToString("yyyyMMdd_HHmmss", CultureInfo.InvariantCulture);
            string dir = Application.persistentDataPath;
            string jsonPath = Path.Combine(dir, $"ui_cost_probe_{stamp}.json");
            File.WriteAllText(jsonPath, json);

            var sb = new System.Text.StringBuilder();
            sb.AppendLine("key,source,parentKey,defaultActive,nodes,sprites,texBytes,ms");
            foreach (var c in catalog)
                sb.AppendLine($"{c.key},{c.source},{c.parentKey},{c.defaultActive},{c.nodes},{c.sprites},{c.texBytes},{c.ms}");
            string csvPath = Path.Combine(dir, $"ui_cost_probe_{stamp}.csv");
            File.WriteAllText(csvPath, sb.ToString());

            // 控制台汇总
            var byTex = catalog.OrderByDescending(c => c.texBytes).Take(10).ToList();
            if (logToConsole)
            {
                Debug.Log($"[UiCostProbe] exported:\n  {jsonPath}\n  {csvPath}");
                Debug.Log("[UiCostProbe] TOP10 by texture (RGBA32 upper bound):");
                foreach (var c in byTex)
                    Debug.Log($"  {c.key,-28} nodes={c.nodes,-5} sprites={c.sprites,-4} texMB={c.texBytes / 1048576f:F2} instantiate={c.ms}ms");
                var hidden = live.Values.Where(r => r.state == "Hidden")
                    .OrderByDescending(r => r.texBytes).ToList();
                Debug.Log($"[UiCostProbe] live instances: {live.Count}, still Hidden(not released)={hidden.Count}, "
                    + $"unique live textures={uniqueTextures.Count}, RGBA32 upper bound={uniqueTextureBytes / 1048576f:F2}MB");
                foreach (var r in hidden)
                    Debug.Log($"  HIDDEN {r.key,-28} id={r.instanceId,-8} nodes={r.nodes,-5} texMB={r.texBytes / 1048576f:F2}");
            }
        }

        // ---------- 数据结构 ----------
        [System.Serializable]
        public sealed class RtRecord
        {
            public int instanceId;
            public string key;
            public string source;
            public float firstSeen;
            public float lastSeen;
            public int nodes;
            public int sprites;
            public long texBytes;
            public List<TextureRecord> textures;
            public string state; // Visible / Hidden / Destroyed
        }

        [System.Serializable]
        public sealed class TextureRecord
        {
            public int instanceId;
            public long bytes;
        }

        [System.Serializable]
        public sealed class CatRecord
        {
            public string key;
            public string source;
            public string parentKey;
            public bool defaultActive;
            public int nodes;
            public int sprites;
            public long texBytes;
            public long ms;
        }

        [System.Serializable]
        public sealed class Report
        {
            public string unityVersion;
            public string platform;
            public string deviceModel;
            public double baselineAllocatedMemoryMB;
            public int runtimeUniqueTextureCount;
            public long runtimeUniqueTextureBytes;
            public int releaseSuccesses;
            public int releaseFailures;
            public string exportedAt;
            public List<RtRecord> live;
            public List<CatRecord> catalog;
        }
    }
}
