# Cocos UI Timeline 迁移证据

## 1. 范围

- 旧 Lua 中 `cc.CSLoader:createTimeline` 共 29 条文本命中：28 条有效、1 条注释。
- 28 条有效调用包含 `Utils:PlayAction(path)` 通用入口；展开其 2 个真实调用后为 29 处有效调用。
- 去重后对应 27 个完整相对路径 CSB 和 27 个 Unity Prefab；不按 basename 合并。
- `.ani` 不属于本模块，由 `ImodAnimationPlayer` 独立处理。

机器证据：`build/ui-migration/runtime-ui-usage.json` 的 `sets.timeline` 与 `unityclient/Assets/ProjectX/res/csd/UnityMigration/unity-import-manifest.timeline.json`。

## 2. 源文件边界

| 项 | 数量 | 结论 |
|---|---:|---|
| 唯一 Timeline 资源/Prefab | 27 | 全部定向导入 |
| 有真实轨道 | 22 | 461 条轨道、2478 帧 |
| 源时间轴无轨道 | 5 | 保留空定义，不伪造动画 |
| 命名片段 | 34 | 支持 `play(name, loop)` |
| 非空 FrameEvent | 3 | 运行时事件回调已验证 |
| CSB-only | 1 | `FengShenLayer.csb` 已用 FlatBuffers 逐帧解码 |

5 个无轨道源：`chouka/shenjiangzhaomu`、`fengshenliezhuan/fengshenliezhuanlLayer`、`huodong/OnlineLayer`、`kunlun/juezhankunlun`、`LilianLayer`。其中 `fengshenliezhuanlLayer` 只有空命名区间，其余时长也为 0；这与旧 Cocos 源一致。

## 3. Unity 实现

- `CocosTimelinePlayer`：Position、Scale、Rotation/RotationSkew、Alpha、Visible/VisibleForFrame、AnchorPoint、FrameEvent。
- 支持整数帧区间、命名片段、循环、Pause/Stop、时间倍率、完成事件与 Cocos `FrameEaseType` 缓动。
- `CocosUiBinding.FindActionTag` 作为轨道到节点的唯一绑定，不按节点名猜测。
- `csb_dump.cpp` 解码 FlatBuffers `NodeAction/TimeLine/Frame/AnimationInfo`，不再只输出动画摘要。
- `--scope timeline` 生成独立 manifest；Unity 只向 27 个目标 Prefab 增量补写 Timeline 组件，不重建既有层级，也不覆盖 `OneLevelLayer.prefab` 等非目标手工文件。
- 无有效贴图的 Panel/Button Image 使用透明图形，避免空资源渲染成白块。

## 4. 验证

```powershell
python -m unittest discover -s tools/ui_migration/tests -v
python tools/ui_migration/convert_ui.py --clean
python tools/ui_migration/prepare_unity_project.py --scope timeline

& 'D:/UnityPro/2022.3.62f3c1/Editor/Unity.exe' -batchmode -quit `
  -projectPath unityclient `
  -executeMethod ProjectX.Editor.CocosUiImporter.ImportTimelinePrefabsBatch

& 'D:/UnityPro/2022.3.62f3c1/Editor/Unity.exe' -batchmode -quit `
  -projectPath unityclient `
  -executeMethod ProjectX.Editor.CocosUiImporter.ValidateTimelinePlaybackBatch
```

结果：Python `15/15`；Unity 27 个 Prefab、34 个命名片段、3 个非空 FrameEvent 全部完成播放，严重异常 0。

视觉抽样：

- `.local/validation/timeline-fengshen-csb.png`：唯一 CSB-only、命名片段 `M_1`。
- `.local/validation/timeline-tower.png`：`animation2` 多片段切换。
- `.local/validation/timeline-xunbao.png`：1005 帧长时间轴的 `RedOpen`。

## 5. 遗留边界

- 当前 27 个目标未使用 TextureFrame、Color、InnerAction、Blend 轨道；播放器不提前虚构这些映射，后续按真实调用增量实现。
- 粒子表现仍受 Unity ParticleSystem 迁移质量约束，不属于 Timeline 帧推进缺陷。
- Timeline Prefab 迁移不代表对应业务模块已接入 Unity 路由；业务入口继续按模块迁移计划推进。
