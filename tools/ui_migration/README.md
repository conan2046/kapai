# Cocos Studio UI Migration IR

独立于 Unity 的迁移数据工具。读取 Cocos Studio 的 CSD XML、二进制 CSB 与 PLIST，输出引擎无关 JSON、唯一资源清单、图集重映射、节点绑定清单和 HTML 报告。

## 运行

在仓库根目录执行：

```powershell
pwsh.exe -File tools/ui_migration/Build-CsbDump.ps1
python tools/ui_migration/convert_ui.py --clean
```

第一条命令使用仓库自带的旧版 FlatBuffers 头文件构建 CSB 解码器，不依赖 Unity；只需本机已有 Visual Studio C++ Build Tools 和 CMake。完整路径审计后有 61 个仅有同路径 CSB 的界面需要兜底。

默认输入：

```text
UI_Editor/CocosProject
```

默认输出：

```text
build/ui-migration/
├── csd/                 # 333个CSD UI IR
├── csb/                 # 仅有CSB界面的兜底UI IR
├── plist/               # 图集/粒子PLIST IR
├── bindings/            # CSD节点绑定清单
├── bindings-csb/        # CSB节点绑定清单
├── baselines/manifest.json
├── asset-manifest.json  # 唯一资源选源契约
├── atlas-remap.json     # 图集旧帧名重映射/占位恢复项
├── report.json          # 机器可读汇总和逐界面结果
├── report.html          # 人工查看报告
├── runtime-ui-usage.json # Lua引用、完整路径匹配和模块scope
├── ani/                 # ImodAnim JSON（convert_animations.py）
└── ani-manifest.json    # ANI结构、贴图配对和Unity资源键
```

CSB/CSD 必须按 `csd/` 下完整相对路径匹配。根目录与 `huodong/`、`common/` 等目录的同名文件属于不同界面；`duplicateBasenames` 只做风险提示，不再按文件名合并。

指定其他路径：

```powershell
python tools/ui_migration/convert_ui.py `
  --project-root UI_Editor/CocosProject `
  --output build/ui-migration `
  --clean
```

`--strict` 会在 XML/PLIST 解析失败或资源缺失时返回非零退出码，适合后续接入 CI。默认模式会完整生成报告，不因历史资源缺失中断批量转换。

工具默认同时扫描 `client/ProjectX/res/csd`，在报告中列出只有 CSD 或只有二进制 CSB 的界面。可通过 `--csb-root` 指定其他运行资源目录。

资源目录存在编辑器副本和运行副本时，工具会计算 SHA-256，并在 `asset-manifest.json` 中为每个逻辑资源指定唯一选中版本。图集按请求帧覆盖率选版，普通文件优先使用运行客户端资源。

冻结的IR v1契约见 [IR_SCHEMA.md](IR_SCHEMA.md) 和 `ui-ir.schema.json`。

## 测试

```powershell
python -m unittest discover -s tools/ui_migration/tests -v
```

## Unity 范围导入

Unity 工程保持旧客户端逻辑目录：

- 旧客户端：`client/ProjectX/res/<legacy path>`
- Unity：`unityclient/Assets/ProjectX/res/<legacy path>`

默认仍可准备全部 IR；新迁移模块优先使用代码引用 scope，避免把其他项目或废弃界面继续带入 Unity：

```powershell
python tools/ui_migration/prepare_unity_project.py
python tools/ui_migration/prepare_unity_project.py --scope referenced
python tools/ui_migration/prepare_unity_project.py --scope welfare
python tools/ui_migration/prepare_unity_project.py --scope timeline
```

仅需调试 10 个代表界面时可加 `--scope baseline`。

当前运行包为 386 个 CSB：325 个存在同路径 CSD，61 个必须由 CSB 解码器兜底。旧版“333 + 23”是按文件名合并后的历史口径。

## ImodAnim `.ani`

`.ani` 不是 Cocos Studio Timeline。它保存贴图模块、组合帧、动作序列和 30 FPS 时长。全量解析及福利范围准备：

```powershell
python tools/ui_migration/convert_animations.py --scope all
python tools/ui_migration/imod_usage.py --markdown-output docs/unityclient/modules/IMOD_ANIMATION_CALLS.md
python tools/ui_migration/convert_animations.py --scope all --prepare-unity
```

Unity 运行时使用 `ImodAnimationData/ImodAnimationPlayer`；CSD/CSB Timeline 使用独立的 `CocosTimelinePlayer`。后者支持 Position、Scale、RotationSkew、Alpha、VisibleForFrame、AnchorPoint、FrameEvent、命名片段、循环、暂停和时间倍率，并按 Cocos `FrameEaseType` 执行缓动。

Imod 全量门禁为 `ProjectX.Editor.ImodAnimationValidation.ValidateAllImodAnimationsBatch`。它逐项验证资源、全部动作、单次/循环、动态别名、PNG/ANI 分离参数、附加层和旧速度倍率，并生成固定 UI 联系表。当前源包存在 6 个固定调用缺整组 ANI/PNG、1 个 ANI 缺贴图，详见 `docs/unityclient/modules/IMOD_ANIMATION.md`。

然后在 Unity 执行 `Tools > ProjectX UI > Import All Prefabs`，或用批处理：

```powershell
& '<Unity.exe>' -batchmode -quit -projectPath unityclient `
  -executeMethod ProjectX.Editor.CocosUiImporter.ImportAllPrefabsBatch

# 只向旧 Lua Timeline 实际引用的 27 个 Prefab 增量补写组件
& '<Unity.exe>' -batchmode -quit -projectPath unityclient `
  -executeMethod ProjectX.Editor.CocosUiImporter.ImportTimelinePrefabsBatch

& '<Unity.exe>' -batchmode -quit -projectPath unityclient `
  -executeMethod ProjectX.Editor.CocosUiImporter.ValidateTimelinePlaybackBatch
```

输出：

- Prefab：`unityclient/Assets/ProjectX/res/csd/Prefabs/`
- 预览场景：`unityclient/Assets/ProjectX/Scenes/UIMigrationPreview.unity`
- 节点绑定：每个 Prefab 根节点的 `CocosUiBinding`

## 当前边界

- 已完整保留 CSD 节点属性、子属性、资源引用和 Timeline XML 数据。
- 已给常见 Cocos Studio 控件附加 Unity 组件映射提示；历史工程已有 356 个 Prefab，新导入必须按完整路径和 scope 生成。
- 已解析 TexturePacker 图集 PLIST 与粒子 PLIST。
- 已为全部节点生成 `cocos-bottom-left-v1` RectTransform建议值；Stretch等原始约束仍完整保留，等待Unity基准界面视觉验收。
- 仅有CSB的界面可提取节点、布局、文本、资源、命名片段和逐帧 Timeline；旧 Lua Timeline scope 中唯一二进制独占的 `FengShenLayer.csb` 已完成真实帧解码与视觉验收。
- 缺失的旧美术源文件不会被猜测替换，会指向明确占位图，并在 `atlas-remap.json` 标记 `requiresArtRecovery`。
- TextMeshPro 字体资产仍属于后续阶段；`.ani` 使用兼容播放器，不批量膨胀为 AnimationClip。
