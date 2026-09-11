using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using ProjectX.Core;
using ProjectX.Network;
using ProjectX.UI.Migration;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace ProjectX.Validation
{
    public sealed class RuntimeSnapshotCollector : MonoBehaviour
    {
        private GameServices services;
        private JObject scenario;
        private string outputPath;
        private string inputFingerprint;
        private readonly List<ProtocolPacketTrace> packets = new List<ProtocolPacketTrace>();
        private readonly object packetLock = new object();
        private Dictionary<string, string> controlByPath;

        public static bool TryInstall(GameObject host, GameServices services)
        {
            string module = GetArgument("-projectXRuntimeSnapshotModule=");
            string scenarioPath = GetArgument("-projectXRuntimeSnapshotScenario=");
            string outputPath = GetArgument("-projectXRuntimeSnapshotOutput=");
            if (!string.Equals(module, "Draw", StringComparison.OrdinalIgnoreCase)
                || string.IsNullOrWhiteSpace(scenarioPath) || string.IsNullOrWhiteSpace(outputPath)) return false;
            try
            {
                var collector = host.AddComponent<RuntimeSnapshotCollector>();
                collector.services = services ?? throw new ArgumentNullException(nameof(services));
                collector.scenario = JObject.Parse(File.ReadAllText(scenarioPath, Encoding.UTF8));
                collector.outputPath = Path.GetFullPath(outputPath);
                collector.inputFingerprint = GetArgument("-projectXRuntimeSnapshotInputFingerprint=");
                if (string.IsNullOrWhiteSpace(collector.inputFingerprint)) collector.inputFingerprint = Sha256(File.ReadAllBytes(scenarioPath));
                collector.BuildControlPathIndex();
                services.Network.PacketObserved += collector.OnPacketObserved;
                collector.StartCoroutine(collector.DelayedReplay());
                return true;
            }
            catch (Exception exception)
            {
                WriteBootstrapFailure(outputPath, exception);
                return false;
            }
        }

        private IEnumerator DelayedReplay()
        {
            // The collector is installed during bootstrap, but Draw targets only exist after the
            // real login/select-role handshake has completed and the normal main UI is visible.
            float readyDeadline = Time.realtimeSinceStartup + 45f;
            while ((services.State.Current != AppState.Main || services.Player.RoleId == 0)
                && Time.realtimeSinceStartup < readyDeadline)
            {
                yield return null;
            }
            if (services.State.Current != AppState.Main || services.Player.RoleId == 0)
            {
                Directory.CreateDirectory(Path.GetDirectoryName(outputPath) ?? Application.persistentDataPath);
                WriteBootstrapFailure(outputPath, new TimeoutException(
                    $"Runtime snapshot readiness timed out: state={services.State.Current}, roleId={services.Player.RoleId}."));
                yield break;
            }
            // Allow the main view's layout/timeline startup to settle before the first real hit test.
            yield return null;
            yield return null;
            Directory.CreateDirectory(Path.GetDirectoryName(outputPath) ?? Application.persistentDataPath);
            using (var stream = new FileStream(outputPath, FileMode.Create, FileAccess.Write, FileShare.Read))
            using (var writer = new StreamWriter(stream, new UTF8Encoding(false)))
            {
                int sequence = 0;
                foreach (JObject definition in scenario["actions"]?.OfType<JObject>() ?? Enumerable.Empty<JObject>())
                {
                    sequence++;
                    JObject record = null;
                    yield return StartCoroutine(ExecuteAction(definition, sequence, value => record = value));
                    if (record == null)
                        record = CreateFailureRecord(definition, sequence,
                            new InvalidOperationException("Runtime action ended without a record."));
                    writer.WriteLine(record.ToString(Formatting.None));
                    writer.Flush();
                    yield return null;
                }
            }
        }

        private IEnumerator ExecuteAction(JObject definition, int sequence, Action<JObject> completed)
        {
            JObject action = (JObject)definition["action"];
            string actionId = (string)definition["actionId"];
            string controlId = (string)action["targetControlId"];
            string targetPath = (string)action["unityPath"];
            string expectedHit = (string)definition["expectedHit"];
            string operationType = (string)action["type"];
            int timeoutMs = (int?)definition["timeout"] ?? 10000;
            string preparationError = null;
            yield return StartCoroutine(PrepareAction(definition, value => preparationError = value));
            if (!string.IsNullOrEmpty(preparationError))
            {
                completed(CreateFailureRecord(definition, sequence,
                    new InvalidOperationException("Scenario precondition failed: " + preparationError)));
                yield break;
            }
            JArray preTree = CaptureUiTree();
            string preHash = HashToken(preTree);
            string preTreeRef = StoreTree(preHash, preTree);
            bool animationStarted = AnyTimelinePlaying();
            int packetStart;
            lock (packetLock) packetStart = packets.Count;
            Stopwatch timer = Stopwatch.StartNew();
            RuntimeInputDispatchResult dispatch = RuntimeInputDispatcher.Dispatch(targetPath, expectedHit, operationType);
            string previousHash = CaptureStableSignature();
            int stableFrames = 0;
            JArray postTree = preTree;
            string postHash = preHash;
            bool expectedPacketsComplete = false;
            int requiredStableFrames = (int?)scenario["stableState"]?["consecutiveFrames"] ?? 3;
            while (dispatch.Dispatched && timer.ElapsedMilliseconds < timeoutMs)
            {
                yield return null;
                string currentHash = CaptureStableSignature();
                if (currentHash == previousHash) stableFrames++; else stableFrames = 0;
                previousHash = currentHash;
                expectedPacketsComplete = ExpectedProtocolsComplete(definition, SnapshotPackets(packetStart));
                if (stableFrames >= requiredStableFrames && expectedPacketsComplete) break;
            }
            timer.Stop();
            postTree = CaptureUiTree();
            postHash = HashToken(postTree);
            string postTreeRef = StoreTree(postHash, postTree);
            List<ProtocolPacketTrace> actionPackets = SnapshotPackets(packetStart);
            bool timedOut = stableFrames < requiredStableFrames || !expectedPacketsComplete;
            bool protocolPassed = !timedOut && ExpectedProtocolsComplete(definition, actionPackets);
            bool treePassed = !string.IsNullOrEmpty(preHash) && !string.IsNullOrEmpty(postHash) && stableFrames >= requiredStableFrames;
            bool replayPassed = dispatch.Dispatched && dispatch.FirstHit == expectedHit;
            JArray changedNodes = ChangedNodes(preTree, postTree);
            bool animationEnded = !AnyTimelinePlaying();
            string cleanupError = null;
            yield return StartCoroutine(CleanupAction(definition, value => cleanupError = value));
            bool cleanupPassed = string.IsNullOrEmpty(cleanupError);
            var record = new JObject
            {
                ["schemaVersion"] = 1,
                ["recordType"] = "action",
                ["module"] = (string)scenario["module"],
                ["stateId"] = (string)definition["expectedState"],
                ["actionId"] = actionId,
                ["controlId"] = controlId,
                ["sequence"] = sequence,
                ["timestampUtc"] = DateTime.UtcNow.ToString("O"),
                ["engine"] = "unity",
                ["operationType"] = operationType,
                ["inputMode"] = "engine-input-replay",
                ["inputCoordinates"] = CanonicalCoordinates(dispatch.ScreenPosition),
                ["preUiTreeHash"] = preHash,
                ["preUiTree"] = new JArray(),
                ["preUiTreeRef"] = preTreeRef,
                ["preUiTreeNodeCount"] = preTree.Count,
                ["targetNodePath"] = dispatch.TargetPath ?? targetPath,
                ["targetSemanticId"] = expectedHit,
                ["hitTest"] = new JObject { ["hits"] = JArray.FromObject(dispatch.Hits), ["firstHit"] = dispatch.FirstHit ?? string.Empty },
                ["engineEventDispatched"] = dispatch.Dispatched,
                ["protocol"] = BuildProtocol(actionPackets, timedOut, dispatch.Error),
                ["changedNodes"] = changedNodes,
                ["postUiTreeHash"] = postHash,
                ["postUiTree"] = new JArray(),
                ["postUiTreeRef"] = postTreeRef,
                ["postUiTreeNodeCount"] = postTree.Count,
                ["stableState"] = new JObject { ["outcome"] = timedOut ? "timeout" : "stable", ["stableFrames"] = stableFrames, ["reason"] = timedOut ? "configured stable state was not reached" : "protocol complete and normalized UI state stable", ["elapsedMs"] = timer.ElapsedMilliseconds },
                ["animation"] = new JObject { ["started"] = animationStarted || AnyTimelineInTree(preTree), ["ended"] = animationEnded, ["durationMs"] = timer.ElapsedMilliseconds, ["cleanupPassed"] = cleanupPassed },
                ["visualStateId"] = definition["visualStateId"]?.DeepClone() ?? JValue.CreateNull(),
                ["identity"] = new JObject { ["account"] = Redact(services.Player.Name), ["userId"] = services.Options.LocalUserId, ["roleId"] = services.Player.RoleId },
                ["resolution"] = new JObject { ["width"] = 1334, ["height"] = 750, ["dpiScale"] = Screen.dpi > 0 ? Screen.dpi / 96f : 1f },
                ["inputFingerprint"] = inputFingerprint.ToUpperInvariant(),
                ["automationPassed"] = replayPassed && protocolPassed && treePassed && cleanupPassed,
                ["engineInputReplayPassed"] = replayPassed,
                ["protocolSemanticPassed"] = protocolPassed,
                ["runtimeTreePassed"] = treePassed
            };
            completed(record);
        }

        private IEnumerator PrepareAction(JObject definition, Action<string> completed)
        {
            string actionId = (string)definition["actionId"];
            if (!string.Equals(actionId, "DRAW-A01", StringComparison.Ordinal))
            {
                string normalizeError = null;
                yield return StartCoroutine(NormalizeToDrawMain(value => normalizeError = value));
                if (!string.IsNullOrEmpty(normalizeError))
                {
                    completed(normalizeError);
                    yield break;
                }
            }

            foreach (string setupActionId in SetupActionIds(actionId))
            {
                JObject setup = (scenario["actions"]?.OfType<JObject>() ?? Enumerable.Empty<JObject>())
                    .FirstOrDefault(value => string.Equals((string)value["actionId"], setupActionId, StringComparison.Ordinal));
                if (setup == null)
                {
                    completed("Missing setup action " + setupActionId + ".");
                    yield break;
                }
                string setupError = null;
                yield return StartCoroutine(DispatchSetupAction(setup, value => setupError = value));
                if (!string.IsNullOrEmpty(setupError))
                {
                    completed(setupActionId + ": " + setupError);
                    yield break;
                }
            }
            completed(null);
        }

        private static IEnumerable<string> SetupActionIds(string actionId)
        {
            switch (actionId)
            {
                case "DRAW-A18": case "DRAW-A19": case "DRAW-A20":
                    return new[] { "DRAW-A15" };
                case "DRAW-A21":
                    return new[] { "DRAW-A02" };
                case "DRAW-A22": case "DRAW-A23": case "DRAW-A24": case "DRAW-A28":
                    return new[] { "DRAW-A02", "DRAW-A21" };
                case "DRAW-A25":
                    return new[] { "DRAW-A03" };
                case "DRAW-A26": case "DRAW-A27":
                    return new[] { "DRAW-A03", "DRAW-A25" };
                default:
                    return Array.Empty<string>();
            }
        }

        private IEnumerator DispatchSetupAction(JObject definition, Action<string> completed)
        {
            JObject action = (JObject)definition["action"];
            int packetStart;
            lock (packetLock) packetStart = packets.Count;
            RuntimeInputDispatchResult dispatch = RuntimeInputDispatcher.Dispatch(
                (string)action["unityPath"], (string)definition["expectedHit"], (string)action["type"]);
            if (!dispatch.Dispatched)
            {
                completed(dispatch.Error ?? "engine input was not dispatched");
                yield break;
            }
            float deadline = Time.realtimeSinceStartup + Math.Max(3f, ((int?)definition["timeout"] ?? 10000) / 1000f);
            string previous = CaptureStableSignature();
            int stableFrames = 0;
            while (Time.realtimeSinceStartup < deadline)
            {
                yield return null;
                string current = CaptureStableSignature();
                stableFrames = current == previous ? stableFrames + 1 : 0;
                previous = current;
                if (stableFrames >= 3 && ExpectedProtocolsComplete(definition, SnapshotPackets(packetStart)))
                {
                    completed(null);
                    yield break;
                }
            }
            completed("setup did not reach protocol-complete stable state");
        }

        private IEnumerator CleanupAction(JObject definition, Action<string> completed)
        {
            string policy = (string)definition["cleanup"] ?? string.Empty;
            if (policy == "keep-draw-open" || policy == "keep-preview-open")
            {
                completed(null);
                yield break;
            }
            yield return StartCoroutine(NormalizeToDrawMain(completed));
        }

        private IEnumerator NormalizeToDrawMain(Action<string> completed)
        {
            const string readyPath = "Layer/Popup1/Btn_Recruit_2";
            const string readyHit = "DRAW-02-BASIC-SINGLE";
            string[] closePaths =
            {
                "DynamicUi_dancichouka/Layer/dancichoukaUI/btn_Close",
                "DynamicUi_shilianchouka/Layer/btn_Close",
                "DynamicUi_dancichouka/Layer/dancichoukaUI/Bg",
                "DynamicUi_shilianchouka/Layer/dancichoukaUI/bg",
                "Layer/MessageBoxUI/Btn_Confirm",
                "Layer/MessageBoxUI/bg/Btn_close",
                "Layer/Popup/Btn_close",
                "RuntimePreviewClose",
                "DrawHeroPreviewFrame/Layer/Panel_12/Title/CloseBtn",
                "Layer/Panel_12/Title/CloseBtn",
                "Layer/shopBg/Popup/Btn_close"
            };
            float deadline = Time.realtimeSinceStartup + 15f;
            while (Time.realtimeSinceStartup < deadline)
            {
                RuntimeInputDispatchResult ready = RuntimeInputDispatcher.Inspect(readyPath, readyHit);
                if (ready.Dispatched)
                {
                    completed(null);
                    yield break;
                }

                bool changed = false;
                foreach (string path in closePaths)
                {
                    RuntimeInputDispatchResult close = RuntimeInputDispatcher.Dispatch(path, "DRAW-RUNTIME-CLEANUP", "click");
                    if (!close.Dispatched) continue;
                    changed = true;
                    yield return null;
                    yield return null;
                    break;
                }
                if (changed) continue;

                RuntimeInputDispatchResult open = RuntimeInputDispatcher.Dispatch(
                    "Layer/Main_UI/ButtonGroup1/btn_zhaomu", "DRAW-01-MAIN-ENTRY", "open");
                if (open.Dispatched)
                {
                    yield return null;
                    yield return null;
                    continue;
                }
                yield return null;
            }
            completed("could not reach a raycast-visible Draw main control through engine input");
        }

        private JArray CaptureUiTree()
        {
            var rows = new List<JObject>();
            foreach (RectTransform rect in FindObjectsOfType<RectTransform>(true).OrderBy(RuntimeInputDispatcher.FullPath, StringComparer.Ordinal))
            {
                string path = RuntimeInputDispatcher.FullPath(rect);
                CocosNodeMetadata metadata = rect.GetComponent<CocosNodeMetadata>();
                Graphic graphic = rect.GetComponent<Graphic>();
                Selectable selectable = rect.GetComponent<Selectable>();
                CanvasGroup[] groups = rect.GetComponentsInParent<CanvasGroup>(true);
                float groupAlpha = groups.Aggregate(1f, (value, group) => value * group.alpha);
                bool active = rect.gameObject.activeSelf;
                bool visible = rect.gameObject.activeInHierarchy && groupAlpha > 0.001f && RectOnScreen(rect);
                bool raycast = graphic != null && graphic.raycastTarget && groups.All(group => group.blocksRaycasts);
                Vector3 world = rect.TransformPoint(rect.rect.center);
                JObject screenRect = CanonicalRect(rect);
                Image image = rect.GetComponent<Image>();
                Text text = rect.GetComponent<Text>();
                ScrollRect scroll = rect.GetComponent<ScrollRect>();
                Toggle toggle = rect.GetComponent<Toggle>();
                InputField input = rect.GetComponent<InputField>();
                CocosTimelinePlayer timeline = rect.GetComponent<CocosTimelinePlayer>();
                string controlId = ResolveControlId(path, metadata?.CocosPath);
                rows.Add(new JObject
                {
                    ["semanticId"] = !string.IsNullOrWhiteSpace(metadata?.CocosPath) ? metadata.CocosPath : path,
                    ["controlId"] = string.IsNullOrEmpty(controlId) ? JValue.CreateNull() : controlId,
                    ["nodePath"] = path,
                    ["nodeType"] = metadata?.NodeType ?? rect.GetType().Name,
                    ["parentPath"] = rect.parent == null ? JValue.CreateNull() : RuntimeInputDispatcher.FullPath(rect.parent),
                    ["siblingIndex"] = rect.GetSiblingIndex(),
                    ["active"] = active,
                    ["selfVisible"] = active && groupAlpha > 0.001f,
                    ["effectiveVisible"] = visible,
                    ["enabled"] = graphic == null || graphic.enabled,
                    ["interactable"] = selectable == null || selectable.IsInteractable(),
                    ["raycast"] = raycast,
                    ["opacity"] = Math.Round((graphic?.color.a ?? 1f) * groupAlpha, 3),
                    ["color"] = graphic == null ? "#FFFFFFFF" : ColorUtility.ToHtmlStringRGBA(graphic.color),
                    ["anchor"] = Vec(rect.anchorMin),
                    ["pivot"] = Vec(rect.pivot),
                    ["localPosition"] = Vec(rect.anchoredPosition),
                    ["worldPosition"] = Vec(new Vector2(world.x, world.y)),
                    ["screenRect"] = screenRect,
                    ["width"] = Math.Round(rect.rect.width, 3),
                    ["height"] = Math.Round(rect.rect.height, 3),
                    ["scale"] = Vec(new Vector2(rect.localScale.x, rect.localScale.y)),
                    ["rotation"] = Math.Round(rect.localEulerAngles.z, 3),
                    ["clippingRect"] = ClippingRect(rect),
                    ["text"] = text == null ? JValue.CreateNull() : Redact(text.text),
                    ["font"] = text?.font == null ? JValue.CreateNull() : text.font.name,
                    ["fontSize"] = text == null ? JValue.CreateNull() : text.fontSize,
                    ["resource"] = image?.sprite == null ? JValue.CreateNull() : image.sprite.name,
                    ["source"] = string.IsNullOrWhiteSpace(metadata?.CocosPath) ? JValue.CreateNull() : metadata.CocosPath,
                    ["animationResource"] = timeline == null ? JValue.CreateNull() : (timeline.Definition?.currentAnimationName ?? "CocosTimeline"),
                    ["animationAction"] = timeline == null ? JValue.CreateNull() : (timeline.CurrentClip ?? string.Empty),
                    ["scroll"] = scroll == null ? JValue.CreateNull() : new JObject { ["viewport"] = scroll.viewport == null ? null : RuntimeInputDispatcher.FullPath(scroll.viewport), ["content"] = scroll.content == null ? null : RuntimeInputDispatcher.FullPath(scroll.content), ["x"] = scroll.horizontalNormalizedPosition, ["y"] = scroll.verticalNormalizedPosition },
                    ["toggle"] = toggle == null ? JValue.CreateNull() : toggle.isOn,
                    ["inputValue"] = input == null ? JValue.CreateNull() : Redact(input.text),
                    ["dataId"] = rect.parent != null && rect.parent.name.IndexOf("Content", StringComparison.OrdinalIgnoreCase) >= 0 ? rect.name : JValue.CreateNull(),
                    ["dataIndex"] = rect.parent != null && rect.parent.name.IndexOf("Content", StringComparison.OrdinalIgnoreCase) >= 0 ? rect.GetSiblingIndex() : JValue.CreateNull()
                });
            }
            return new JArray(rows);
        }

        private string StoreTree(string hash, JArray tree)
        {
            string directory = Path.GetDirectoryName(outputPath) ?? Application.persistentDataPath;
            string fileName = "unity-tree-" + hash.ToUpperInvariant() + ".json.gz";
            string path = Path.Combine(directory, fileName);
            if (!File.Exists(path))
            {
                using (var file = new FileStream(path, FileMode.CreateNew, FileAccess.Write, FileShare.Read))
                using (var gzip = new GZipStream(file, System.IO.Compression.CompressionLevel.Optimal))
                using (var writer = new StreamWriter(gzip, new UTF8Encoding(false)))
                    writer.Write(tree.ToString(Formatting.None));
            }
            return fileName;
        }

        private JObject BuildProtocol(List<ProtocolPacketTrace> traces, bool timedOut, string dispatchError)
        {
            int sequence = 0;
            var sent = new JArray();
            var received = new JArray();
            foreach (ProtocolPacketTrace trace in traces)
            {
                sequence++;
                JObject row = DecodePacket(trace, sequence);
                if (trace.Direction == ProtocolPacketDirection.Sent) sent.Add(row); else received.Add(row);
            }
            var errors = new JArray();
            if (!string.IsNullOrWhiteSpace(dispatchError)) errors.Add(dispatchError);
            return new JObject { ["sent"] = sent, ["received"] = received, ["errors"] = errors, ["timedOut"] = timedOut, ["disconnected"] = services.Network.State == NetworkState.Disconnected || services.Network.State == NetworkState.Faulted };
        }

        private static JObject DecodePacket(ProtocolPacketTrace trace, int sequence)
        {
            int offset = trace.Direction == ProtocolPacketDirection.Sent ? 2 : 0;
            byte? op = trace.Payload.Length > offset ? trace.Payload[offset] : (byte?)null;
            var fields = new JObject();
            if (trace.Command == 224 && op == 2 && trace.Direction == ProtocolPacketDirection.Sent && trace.Payload.Length >= offset + 3)
            {
                fields["kind"] = trace.Payload[offset + 1];
                fields["drawType"] = trace.Payload[offset + 2];
            }
            return new JObject { ["sequence"] = sequence, ["command"] = trace.Command, ["op"] = op.HasValue ? new JValue(op.Value) : JValue.CreateNull(), ["decodedFields"] = fields, ["length"] = trace.RawPacket.Length, ["rawPacketHash"] = Sha256(trace.RawPacket), ["timestampUtc"] = trace.TimestampUtc.ToString("O") };
        }

        private bool ExpectedProtocolsComplete(JObject definition, List<ProtocolPacketTrace> traces)
        {
            foreach (JObject expected in definition["expectedProtocols"]?.OfType<JObject>() ?? Enumerable.Empty<JObject>())
            {
                ProtocolPacketDirection direction = string.Equals((string)expected["direction"], "sent", StringComparison.OrdinalIgnoreCase) ? ProtocolPacketDirection.Sent : ProtocolPacketDirection.Received;
                int command = (int?)expected["command"] ?? 0;
                int? op = (int?)expected["op"];
                if (!traces.Any(trace => trace.Direction == direction && trace.Command == command && (!op.HasValue || PacketOp(trace) == op.Value))) return false;
            }
            return true;
        }

        private static int? PacketOp(ProtocolPacketTrace trace)
        {
            int offset = trace.Direction == ProtocolPacketDirection.Sent ? 2 : 0;
            return trace.Payload.Length > offset ? trace.Payload[offset] : (int?)null;
        }

        private void OnPacketObserved(ProtocolPacketTrace trace)
        {
            int[] ignored = scenario["stableState"]?["ignoreCommands"]?.Values<int>().ToArray() ?? Array.Empty<int>();
            if (ignored.Contains(trace.Command)) return;
            lock (packetLock) packets.Add(trace);
        }

        private List<ProtocolPacketTrace> SnapshotPackets(int start)
        {
            lock (packetLock) return packets.Skip(Math.Min(start, packets.Count)).ToList();
        }

        private void BuildControlPathIndex()
        {
            controlByPath = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            foreach (JObject definition in scenario["actions"]?.OfType<JObject>() ?? Enumerable.Empty<JObject>())
            {
                JObject action = (JObject)definition["action"];
                string id = (string)action["targetControlId"];
                foreach (string field in new[] { "unityPath", "cocosPath" })
                {
                    string path = (string)action[field];
                    if (!string.IsNullOrWhiteSpace(path)) controlByPath[path.Replace('\\', '/').Trim('/')] = id;
                }
            }
        }

        private string ResolveControlId(string path, string cocosPath)
        {
            foreach (KeyValuePair<string, string> pair in controlByPath)
                if (path.EndsWith(pair.Key, StringComparison.OrdinalIgnoreCase) || (!string.IsNullOrEmpty(cocosPath) && cocosPath.EndsWith(pair.Key, StringComparison.OrdinalIgnoreCase))) return pair.Value;
            return string.Empty;
        }

        private static JArray ChangedNodes(JArray before, JArray after)
        {
            Dictionary<string, string> left = SnapshotNodesByPath(before);
            Dictionary<string, string> right = SnapshotNodesByPath(after);
            return new JArray(left.Keys.Union(right.Keys).Where(key => !left.TryGetValue(key, out string l) || !right.TryGetValue(key, out string r) || l != r).OrderBy(value => value));
        }

        private static Dictionary<string, string> SnapshotNodesByPath(JArray tree)
        {
            return tree.OfType<JObject>()
                .GroupBy(value => (string)value["nodePath"] ?? string.Empty, StringComparer.Ordinal)
                .ToDictionary(group => group.Key,
                    group => string.Join("\n", group.Select(value => value.ToString(Formatting.None)).OrderBy(value => value, StringComparer.Ordinal)),
                    StringComparer.Ordinal);
        }

        private string CaptureStableSignature()
        {
            // Stable-state detection deliberately ignores animated transforms, particles and
            // geometry. The full before/after trees still retain those fields for comparison.
            // This keeps the collector from issuing hundreds of raycasts per frame and starving
            // the real network pump while a protocol response is in flight.
            var rows = new JArray();
            foreach (RectTransform rect in FindObjectsOfType<RectTransform>(true)
                .OrderBy(RuntimeInputDispatcher.FullPath, StringComparer.Ordinal))
            {
                CocosNodeMetadata metadata = rect.GetComponent<CocosNodeMetadata>();
                Graphic graphic = rect.GetComponent<Graphic>();
                Selectable selectable = rect.GetComponent<Selectable>();
                CanvasGroup[] groups = rect.GetComponentsInParent<CanvasGroup>(true);
                float groupAlpha = groups.Aggregate(1f, (value, group) => value * group.alpha);
                Text text = rect.GetComponent<Text>();
                string value = text == null ? string.Empty : Redact(text.text);
                // Countdown digits are volatile, while the surrounding semantic node remains.
                if (!string.IsNullOrEmpty(value) && value.All(character => char.IsDigit(character) || character == ':' || char.IsWhiteSpace(character)))
                    value = "<volatile-number>";
                rows.Add(new JObject
                {
                    ["semanticId"] = !string.IsNullOrWhiteSpace(metadata?.CocosPath) ? metadata.CocosPath : RuntimeInputDispatcher.FullPath(rect),
                    ["active"] = rect.gameObject.activeSelf,
                    ["effectiveVisible"] = rect.gameObject.activeInHierarchy && groupAlpha > 0.001f && RectOnScreen(rect),
                    ["enabled"] = graphic == null || graphic.enabled,
                    ["interactable"] = selectable == null || selectable.IsInteractable(),
                    ["text"] = value,
                    ["resource"] = SafeSpriteName(rect.GetComponent<Image>()),
                    ["toggle"] = rect.GetComponent<Toggle>()?.isOn
                });
            }
            return HashToken(rows);
        }

        private static string SafeSpriteName(Image image)
        {
            // UnityEngine.Object uses native-backed null semantics; null-conditional access can
            // still call name on an unassigned/destroyed sprite and throw here.
            if (image == null) return string.Empty;
            Sprite sprite = image.sprite;
            return sprite == null ? string.Empty : sprite.name;
        }

        private bool AnyTimelinePlaying() => FindObjectsOfType<CocosTimelinePlayer>(true).Any(value => value.IsPlaying);
        private static bool AnyTimelineInTree(JArray tree) => tree.OfType<JObject>().Any(value => value["animationResource"]?.Type == JTokenType.String);
        private static JObject Vec(Vector2 value) => new JObject { ["x"] = Math.Round(value.x, 3), ["y"] = Math.Round(value.y, 3) };
        private static JObject CanonicalCoordinates(Vector2 screen) => new JObject { ["x"] = Math.Round(screen.x * 1334d / Math.Max(1, Screen.width), 3), ["y"] = Math.Round(750d - screen.y * 750d / Math.Max(1, Screen.height), 3), ["coordinateSpace"] = "1334x750-top-left" };

        private static JObject CanonicalRect(RectTransform rect)
        {
            Vector3[] corners = new Vector3[4]; rect.GetWorldCorners(corners);
            Camera camera = ResolveCamera(rect);
            Vector2 lower = RectTransformUtility.WorldToScreenPoint(camera, corners[0]);
            Vector2 upper = RectTransformUtility.WorldToScreenPoint(camera, corners[2]);
            double x = lower.x * 1334d / Math.Max(1, Screen.width);
            double y = 750d - upper.y * 750d / Math.Max(1, Screen.height);
            return new JObject { ["x"] = Math.Round(x, 3), ["y"] = Math.Round(y, 3), ["width"] = Math.Round((upper.x - lower.x) * 1334d / Math.Max(1, Screen.width), 3), ["height"] = Math.Round((upper.y - lower.y) * 750d / Math.Max(1, Screen.height), 3) };
        }

        private static JToken ClippingRect(RectTransform rect)
        {
            RectMask2D mask = rect.GetComponentInParent<RectMask2D>();
            if (mask != null) return CanonicalRect(mask.rectTransform);
            Mask legacyMask = rect.GetComponentInParent<Mask>();
            return legacyMask == null ? JValue.CreateNull() : CanonicalRect(legacyMask.rectTransform);
        }

        private static bool RectOnScreen(RectTransform rect)
        {
            JObject value = CanonicalRect(rect);
            double x = (double)value["x"], y = (double)value["y"], width = (double)value["width"], height = (double)value["height"];
            if (x + width <= 0 || y + height <= 0 || x >= 1334 || y >= 750) return false;
            RectMask2D mask = rect.GetComponentInParent<RectMask2D>();
            if (mask == null) return true;
            JObject clip = CanonicalRect(mask.rectTransform);
            return x + width > (double)clip["x"] && x < (double)clip["x"] + (double)clip["width"] && y + height > (double)clip["y"] && y < (double)clip["y"] + (double)clip["height"];
        }

        private static bool IsNotOccluded(RectTransform rect)
        {
            if (EventSystem.current == null) return false;
            Vector2 point = RectTransformUtility.WorldToScreenPoint(ResolveCamera(rect), rect.TransformPoint(rect.rect.center));
            var data = new PointerEventData(EventSystem.current) { position = point };
            var hits = new List<RaycastResult>(); EventSystem.current.RaycastAll(data, hits);
            return hits.Count > 0 && (hits[0].gameObject.transform == rect || hits[0].gameObject.transform.IsChildOf(rect));
        }

        private static Camera ResolveCamera(RectTransform rect)
        {
            Canvas canvas = rect.GetComponentInParent<Canvas>();
            return canvas == null || canvas.renderMode == RenderMode.ScreenSpaceOverlay ? null : canvas.worldCamera ?? Camera.main;
        }

        private JObject CreateFailureRecord(JObject definition, int sequence, Exception exception)
        {
            JObject action = (JObject)definition["action"];
            string zero = new string('0', 64);
            return new JObject {
                ["schemaVersion"] = 1, ["recordType"] = "action", ["module"] = (string)scenario["module"], ["stateId"] = (string)definition["expectedState"], ["actionId"] = (string)definition["actionId"], ["controlId"] = (string)action["targetControlId"], ["sequence"] = sequence, ["timestampUtc"] = DateTime.UtcNow.ToString("O"), ["engine"] = "unity", ["operationType"] = (string)action["type"], ["inputMode"] = "engine-input-replay", ["inputCoordinates"] = new JObject { ["x"] = 0, ["y"] = 0, ["coordinateSpace"] = "1334x750-top-left" }, ["preUiTreeHash"] = zero, ["preUiTree"] = new JArray(), ["preUiTreeRef"] = JValue.CreateNull(), ["preUiTreeNodeCount"] = 0, ["targetNodePath"] = (string)action["unityPath"], ["targetSemanticId"] = (string)definition["expectedHit"], ["hitTest"] = new JObject { ["hits"] = new JArray(), ["firstHit"] = "" }, ["engineEventDispatched"] = false, ["protocol"] = new JObject { ["sent"] = new JArray(), ["received"] = new JArray(), ["errors"] = new JArray(exception.Message), ["timedOut"] = false, ["disconnected"] = false }, ["changedNodes"] = new JArray(), ["postUiTreeHash"] = zero, ["postUiTree"] = new JArray(), ["postUiTreeRef"] = JValue.CreateNull(), ["postUiTreeNodeCount"] = 0, ["stableState"] = new JObject { ["outcome"] = "business-error", ["stableFrames"] = 0, ["reason"] = exception.Message, ["elapsedMs"] = 0 }, ["animation"] = new JObject { ["started"] = false, ["ended"] = false, ["durationMs"] = 0, ["cleanupPassed"] = false }, ["visualStateId"] = definition["visualStateId"]?.DeepClone() ?? JValue.CreateNull(), ["identity"] = new JObject { ["account"] = Redact(services?.Player?.Name), ["userId"] = services?.Options?.LocalUserId ?? 0, ["roleId"] = services?.Player?.RoleId ?? 0 }, ["resolution"] = new JObject { ["width"] = 1334, ["height"] = 750, ["dpiScale"] = 1 }, ["inputFingerprint"] = string.IsNullOrEmpty(inputFingerprint) ? zero : inputFingerprint, ["automationPassed"] = false, ["engineInputReplayPassed"] = false, ["protocolSemanticPassed"] = false, ["runtimeTreePassed"] = false };
        }

        private static string Redact(string value) => string.IsNullOrEmpty(value) ? string.Empty : value.Replace("token", "[redacted]").Replace("password", "[redacted]");
        private static string HashToken(JToken token) => Sha256(Encoding.UTF8.GetBytes(token.ToString(Formatting.None)));
        private static string Sha256(byte[] bytes) { using (SHA256 sha = SHA256.Create()) return BitConverter.ToString(sha.ComputeHash(bytes ?? Array.Empty<byte>())).Replace("-", string.Empty); }
        private static string GetArgument(string prefix) { string value = Environment.GetCommandLineArgs().FirstOrDefault(arg => arg.StartsWith(prefix, StringComparison.OrdinalIgnoreCase)); return value == null ? string.Empty : value.Substring(prefix.Length).Trim('"'); }
        private static void WriteBootstrapFailure(string output, Exception exception) { try { if (string.IsNullOrWhiteSpace(output)) return; Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(output)) ?? Application.persistentDataPath); File.WriteAllText(output + ".error.json", new JObject { ["recordType"] = "collector-error", ["engine"] = "unity", ["timestampUtc"] = DateTime.UtcNow.ToString("O"), ["error"] = exception.ToString() }.ToString(Formatting.Indented), new UTF8Encoding(false)); } catch { } }

        private void OnDestroy()
        {
            if (services?.Network != null) services.Network.PacketObserved -= OnPacketObserved;
        }
    }
}
