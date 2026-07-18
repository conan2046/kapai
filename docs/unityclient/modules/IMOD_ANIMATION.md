# ImodAnim 兼容播放模块

## 范围

- 审计旧 Lua 中活动状态的 `ImodAnim` 构造、加载、播放和生命周期调用。
- 将桌面运行包 `.ani` 转为 JSON，并保留原 PNG 像素坐标。
- Unity 支持固定路径、动态路径、PNG/ANI 分离参数和模型附加动画层。
- 不把 Cocos Studio CSB Timeline 混入本模块；后者见 `UI_TIMELINE.md`。

完整逐行清单见 `IMOD_ANIMATION_CALLS.md`。

## 三方证据

| 证据 | 结论 |
|---|---|
| `client/ProjectX/frameworks/runtime-src/Classes/Game/Player/ImodAnim.cpp/.h` | 30 FPS；时长值 1 兼容为 5；`SetSpeedScale` 乘到帧间隔；最多 5 个叠加层；全局翻转/颜色/透明度；单次、循环、结束与帧回调 |
| `client/ProjectX/src/**/*.lua` 活动代码 | 67 个构造入口、208 个相关调用、38 个动态加载表达式、41 个源文件 |
| `client/ProjectX/res/**/*.ani` | 886/886 可解析，1327 个动作、10264 个动作序列帧 |
| 固定 Lua 路径对资源包 | 24 条固定路径中 18 条存在，6 条缺整组 ANI/PNG |
| PNG 配对 | 885 个动画可获得真实贴图；`Skill/skill_5_h_l.ani` 缺可解码 PNG |

## 实现

- `tools/ui_migration/imod_usage.py`
  - 去除 Lua 单行/块注释后审计活动调用。
  - 输出 `build/ui-migration/imod-usage.json` 和本模块的 Markdown 调用清单。
  - 固定路径与实际 ANI 交叉校验，缺资源不再被“ANI 自身配对统计”遗漏。
- `tools/ui_migration/convert_animations.py`
  - 全量输出 JSON、贴图和 `ProjectXAnimation/catalog.json`。
  - `jishourenwu.ani` 与 `jieshourenwu.png` 按旧调用证据建立别名，不改源文件。
  - `Monster/btm450_zd.png` 小于 ANI 声明边界，Unity 副本只补透明画布，不伪造像素。
- `ImodAnimationResources`
  - 统一 `/`、扩展名、`res/` 和 `ProjectXAnimation/` 前缀。
  - 支持同名加载及显式 `texturePath + animationPath`。
- `ImodAnimationPlayer`
  - 支持单次、循环、动作号、旧速度倍率、X/Y 翻转、颜色、透明度、停止、完成/帧事件。
  - 支持 `addAnimWithName` 对应的附加动画层，供武器/模型动态组合。
- `ImodAnimationTextureImporter`
  - 保留最大 4096 原图尺寸、禁用 NPOT 缩放和 Mipmap、使用无损导入，避免 ANI 像素坐标被 Unity 默认 2048 缩图破坏。

## 验证

```powershell
python tools/ui_migration/imod_usage.py `
  --markdown-output docs/unityclient/modules/IMOD_ANIMATION_CALLS.md
python tools/ui_migration/convert_animations.py --scope all --prepare-unity
python -m unittest discover -s tools/ui_migration/tests -v

$unity = 'D:/unitypro/2022.3.62f3c1/Editor/Unity.exe'
Start-Process -Wait $unity -ArgumentList @(
  '-batchmode','-quit','-projectPath','D:/neiwang_kapai/unityclient',
  '-executeMethod','ProjectX.Editor.ImodAnimationValidation.ValidateAllImodAnimationsBatch'
)
```

最终结果：

- Python：16/16。
- Unity BatchMode：返回码 0，无编译错误和播放异常。
- 885 个真实可播放动画逐项加载通过。
- 1327/1327 个动作完成态与循环态通过。
- 10264/10264 个动作序列帧推进通过。
- 固定 UI 视觉联系表：`.local/validation/imod-static-ui-contact-sheet.png`。
- 签到单项截图：`.local/validation/qiandao-unity.png`。

## 源资源缺口

以下路径在桌面运行资源包中缺 ANI/PNG，Unity 不使用其他游戏或 Android `xcres` 加密副本猜补：

- `effect/biaobai/butflay`
- `effect/hehua/hehua_yu`
- `res2/skill_name/battle_hero_anger_boom`
- `res2/skill_name/battle_hero_anger_burning`
- `res2/skill_name/battle_pet_anger_boom`
- `res2/skill_name/battle_pet_anger_burning`

此外 `Skill/skill_5_h_l.ani` 存在，但桌面资源缺 PNG；Android 副本只有不可直接解码的 `xcres` 文件。上述 7 项必须取得当前游戏的可解码原始美术后才能声明 100% 资源闭环。

## 结论

播放器、动态路径和当前可用真实资源已形成全量闭环；不能把源包缺失的 7 项写成“正确播放”。联系表用红色 `MISSING` 显示固定调用缺口，后续补入真实资源后重新运行同一门禁即可。
