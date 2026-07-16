# Cocos Studio UI Migration IR

独立于 Unity 的迁移数据工具。读取 Cocos Studio 的 CSD XML、二进制 CSB 与 PLIST，输出引擎无关 JSON、唯一资源清单、图集重映射、节点绑定清单和 HTML 报告。

## 运行

在仓库根目录执行：

```powershell
pwsh.exe -File tools/ui_migration/Build-CsbDump.ps1
python tools/ui_migration/convert_ui.py --clean
```

第一条命令使用仓库自带的旧版FlatBuffers头文件构建CSB解码器，不依赖Unity；只需本机已有Visual Studio C++ Build Tools和CMake。没有CSB兜底需求时可不构建，但23个仅有CSB的界面不会被补齐。

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
└── report.html          # 人工查看报告
```

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

## Unity 全量导入

Unity 工程保持旧客户端逻辑目录：

- 旧客户端：`client/ProjectX/res/<legacy path>`
- Unity：`unityclient/Assets/ProjectX/res/<legacy path>`

默认准备全部 333 个 CSD 与 23 个仅 CSB 界面，以及它们引用的资源和九宫格切片：

```powershell
python tools/ui_migration/prepare_unity_project.py
```

仅需调试 10 个代表界面时可加 `--scope baseline`。

然后在 Unity 执行 `Tools > ProjectX UI > Import All Prefabs`，或用批处理：

```powershell
& '<Unity.exe>' -batchmode -quit -projectPath unityclient `
  -executeMethod ProjectX.Editor.CocosUiImporter.ImportAllPrefabsBatch
```

输出：

- Prefab：`unityclient/Assets/ProjectX/res/csd/Prefabs/`
- 预览场景：`unityclient/Assets/ProjectX/Scenes/UIMigrationPreview.unity`
- 节点绑定：每个 Prefab 根节点的 `CocosUiBinding`

## 当前边界

- 已完整保留 CSD 节点属性、子属性、资源引用和 Timeline XML 数据。
- 已给常见 Cocos Studio 控件附加 Unity 组件映射提示，并支持生成全部 356 个 Unity Prefab。
- 已解析 TexturePacker 图集 PLIST 与粒子 PLIST。
- 已为全部节点生成 `cocos-bottom-left-v1` RectTransform建议值；Stretch等原始约束仍完整保留，等待Unity基准界面视觉验收。
- 仅有CSB的界面已提取节点、布局、文本、资源和动画摘要；CSB Timeline逐帧数据标记为后续补充项。
- 缺失的旧美术源文件不会被猜测替换，会指向明确占位图，并在 `atlas-remap.json` 标记 `requiresArtRecovery`。
- TextMeshPro字体资产、Cocos动画到AnimationClip的转换仍属于后续阶段。
