# UnityClient 精简交接

> 最后更新：2026-07-19
> 当前状态：`UNITYCLIENT_STATUS.md`
> 长期计划：`UNITYCLIENT_MIGRATION_PLAN.md`
> 模块证据：`docs/unityclient/modules/`
> 严格流程：`docs/unityclient/MIGRATION_SOP.md`
> 视觉门禁：`docs/unityclient/UI_1TO1_STANDARD.md`；历史全文：`docs/unityclient/history/`

## 1. 新任务读取顺序
1. `AGENTS.md`。
2. `UNITYCLIENT_STATUS.md`。
3. 本文件。
4. `docs/unityclient/MIGRATION_SOP.md`。
5. `docs/unityclient/modules/README.md` 和目标模块文档。
6. 只读取 `UNITYCLIENT_MIGRATION_PLAN.md` 的对应阶段，不默认全文读取历史。

## 2. 工程定位
| 项 | 路径 |
|---|---|
| 仓库 | 当前工作区根目录 |
| Unity 工程 | `unityclient/` |
| Cocos 客户端 | `client/ProjectX/` |
| 服务端 | `server/` |
| Unity | 以 `tools/unity-migration/unityclient-modules.json` 的 `unityExecutable` 为准 |
| 本地游戏服 | `127.0.0.1:8711` |
| workspace MySQL | `127.0.0.1:3306` |

## 3. 当前任务
阵容试点已按 G0-G6 收口，状态为 `visual-1to1-complete`。五个目标状态均有 Windows `100%`、原生 `1334×750` 的 Cocos/Unity 对照、节点映射和差异报告；`/24、/48` 换位、恢复、重连持久化和非法回包通过。

当前单模块为装备/法宝。G0-G4 与 G6 逻辑门禁完成，状态为 `g6-logic-complete-visual-fixing`：Lua 权威、共享 `/319` 单次读 op、真实配置/图标、列表/详情/更换/单次强化 Prefab、穿脱/强化/失败/重拉/切号均通过。G5 已恢复装备与法宝列表两组双端差异图；旧 Runner 曾误删冻结 Cocos 基准，下一步只重采详情、弹窗、强化前后和失败态，补齐差异后才可升 `visual-1to1-complete`。

## 4. 当前分层与 Lua 回归原则
```text
入口/Prefab
  → Lua Controller / Legacy Model（协议、业务、权威状态）
  → 通用 C# Bridge（Socket、字节流、Unity 节点/资源/动画适配）
  → Unity UI 重绘
```

约束：

- 新模块不得继续固定新增业务型 `Store.cs + Catalog.cs + Presenter.cs`。
- 旧 Lua Controller/Logic/Data 优先复用；仅直接依赖 `cc/ccui` 的显示调用进入兼容层。
- Presenter 不解析网络字节，不写奖励/消耗规则；现有 Presenter 可暂作渲染镜像，按触达逐步通用化，不一次性推倒。
- 原始网络数据必须先进入 Lua 权威模型；C# Store 如仍存在，只能作为渲染镜像。
- 配置统一由 Catalog/ConfigService 读取。
- 切号清角色 Store，配置缓存可保留。

## 5. 通用能力入口

| 能力 | 主要入口 |
|---|---|
| App/服务容器 | `unityclient/Assets/ProjectX/src/Core/ProjectXApp.cs`、`GameServices.cs` |
| 启动参数 | `Core/AppLaunchOptions.cs` |
| 协议登记 | `Network/ProtocolRegistry.cs` |
| Lua 启动 | `Resources/Lua/Bootstrap.txt` |
| UI 路由/返回 | `UI/UiRouter.cs`、`UI/UiStack.cs` |
| 列表 | `UI/VirtualList.cs` |
| 弹窗/提示 | `UI/GameErrorPresenter.cs`、`LoadingPresenter.cs`、`ToastPresenter.cs` |
| 资源 | `Core/ResourceService.cs` |
| 服务器时间 | `Core/ServerTimeService.cs` |
| 奖励 | `Data/RewardStore.cs`、`UI/RewardPresenter.cs` |
| 场景装配 | `Editor/BootstrapSceneBuilder.cs` |
| 自动化 | `Editor/BootstrapAppRunner.cs` |
| 好友 | `Data/FriendStore.cs`、`UI/FriendPresenter.cs`、`Resources/Lua/Friend/FriendController.lua.txt` |
| 聊天 | `Data/ChatStore.cs`、`UI/ChatPresenter.cs`、`Resources/Lua/Chat/ChatController.lua.txt` |
| 队伍 | `Data/TeamStore.cs`、`UI/TeamPresenter.cs`、`Resources/Lua/Team/TeamController.lua.txt` |
| 帮派 | `Data/GuildStore.cs`、`UI/GuildPresenter.cs`、`Resources/Lua/Guild/GuildController.lua.txt` |
| 世界/副本 | `Data/WorldStore.cs`、`UI/WorldPresenter.cs`、`Resources/Lua/World/WorldController.lua.txt` |
| 福利 | `Data/WelfareStore.cs`、`UI/WelfarePresenter.cs`、`Resources/Lua/Welfare/WelfareController.lua.txt` |
| 登录 | `UI/LoginPresenter.cs`、`Resources/Lua/Login/LoginController.lua.txt`、`LoginProtocol.lua.txt` |
| 活动 | `Data/ActivityStore.cs`、`UI/ActivityPresenter.cs`、`Resources/Lua/Activity/ActivityController.lua.txt`、`TempActivityController.lua.txt` |
| 神将招募 | `Data/DrawStore.cs`、`UI/DrawPresenter.cs`、`Resources/Lua/Draw/DrawController.lua.txt` |
| 玩法大厅 | `Data/GameplayStore.cs`、`UI/GameplayPresenter.cs`、`Resources/Lua/Gameplay/GameplayController.lua.txt`、`Shared/HotPointController.lua.txt` |
| 决战昆仑 | `Data/KunLunStore.cs`、`UI/KunLunPresenter.cs`、`Resources/Lua/Gameplay/KunLunController.lua.txt` |
| 血战到底 | `Data/BloodFightStore.cs`、`UI/BloodFightPresenter.cs`、`Resources/Lua/Gameplay/BloodFightController.lua.txt` |

## 6. 迁移提速工具

| 工具 | 用途 |
|---|---|
| `tools/unity-migration/unityclient-modules.json` | 模块、协议、入口、Prefab、配置、验收参数和数据夹具 |
| `New-UnityMigrationModule.ps1` | 生成 Store/Catalog/Presenter/Lua/模块文档骨架 |
| `Get-ProtocolEvidence.ps1` | 按协议号提取服务端、旧客户端、Unity、smoke 证据 |
| `Run-UnityModuleValidation.ps1` | 自动分配隔离角色、启服、串行 Unity、结果/截图检查和清理 |
| `Test-UnityMigrationDocs.ps1` | 状态唯一性、Manifest、路径及视觉 1:1 完成证据门禁 |
| `Test-BootstrapSceneIdempotence.ps1` | 连续生成两次并校验 Bootstrap 场景 SHA-256 稳定 |
| `tools/ui_migration/convert_ui.py` | 按完整相对路径生成 UI IR、CSB 兜底和 `runtime-ui-usage.json` |
| `tools/ui_migration/convert_animations.py` | 全量解析 Imod `.ani`，按 `welfare/all` scope 准备 Unity 资源 |
| `prepare_unity_project.py --scope timeline` | 解析 29 处有效 Timeline 调用，只准备 27 个唯一目标 Prefab |

## 7. 单模块标准流程

唯一流程见 `docs/unityclient/MIGRATION_SOP.md`：G0 范围冻结 → G1 Cocos 取证 → G2 迁移设计 → G3 静态实现 → G4 逻辑验收 → G5 视觉对照 → G6 回归收口。上一门禁未通过，不得进入下一阶段或开启下一模块。

## 8. Unity 验收规则

- 文档和纯静态修改不启动 Unity/MCP/服务。
- C#/Lua 静态完成后，只有编译、场景、Prefab、Console、PlayMode 才启动 Unity。
- 自动化使用 `Start-Process -Wait`，不得直接假设调用 Unity.exe 会同步阻塞。
- 同一个隔离角色同一时间只能跑一个变更型 Runner。
- Runner 启动前删除旧结果；完成后校验 `success`、UTC、角色和最终状态。
- 严重异常扫描：`error CS`、`LuaException`、`NullReferenceException`、`MissingReferenceException`、assert、真实 crash。
- `CrashHandler` 等 Unity 性能标签不是实际 crash，不能误报。
- Unity 单端 GameView 截图不能替代 Cocos 对照；必须同状态双端截图、节点映射、叠加/差异报告齐全。
- 截图门禁覆盖每个界面、弹窗、Tab 和关键状态；占位文字、错误图片、文字截断/重叠、公共层遮挡任一存在即保持 `visual-pending/visual-fixing`。
- 阶段结束关闭 Unity、Unity Hub、Cocos、`kapai.exe`、workspace-local MySQL，并检查 3306/8711。

## 9. 高频坑

| 坑 | 规则 |
|---|---|
| 配置货币与实际扣款不同 | 同时核对服务端调用链和购买后 CurrencyStore |
| 快速响应丢包 | 保留 Windows 每 socket send queue，不退回单 pending message |
| UTF-16LE/包长度错误 | 遵守旧 Cocos：Unicode 字符串 UTF-16LE，长度不含 6 字节头 |
| 零载荷包被清空 | 保留现有合法零 body 处理 |
| 批处理拿到旧 COMPLETE | 删除旧结果并验证时间戳 |
| Unity 进程重叠 | `Start-Process -Wait`，运行前检查 Unity 进程 |
| 自动脚本破坏手工 Prefab | 默认只实例化和运行时绑定，禁止覆盖重建 |
| 日志成功但 UI 错位 | 只算逻辑通过；按同数据 Cocos 基准逐项修正坐标、字体、层级、状态、动画与交互 |
| Windows 显示缩放不是 100% | 在 G0 立即停止；旧截图全部作废，禁止把低分辨率客户区放大为 `1334×750` 当最终基准 |
| Cocos 基准定位低效 | 截图须验窗口/页面标题、账号角色、步骤、尺寸和节点；坐标只试一次，失败转 Lua/日志/协议/自动化；`cocos-formation-compare.png` 实为公告空框，已判无效 |
| Cocos 启动过早截图 | 本地登录后等待约 `40-45` 秒稳定主界面；`local_client.log` 为跨进程追加日志，多次登录记录不等于当前进程循环 |
| Cocos 窗口边框混入基准 | 最终使用 `Invoke-ClientWindow.ps1 -CaptureClientOnly -PrintWindowFlags 2 -LogicalActivate -RestoreNoActivate`，直接取得原生 `1334×750` 客户区 |
| 动态模型被静态图替代 | 沿 `CreateAnimModel/ImodAnim/Timeline` 真实调用链迁移资源、动作号、循环、缩放和挂点；半身像不得冒充 `PlayStand` 模型 |
| 测试数据重复消耗 | 每个变更场景使用新隔离角色，失败角色不复用为最终证据 |
| ISO UTC 被误判为 stale | PowerShell 7 已转为 `DateTime` 时直接 `ToUniversalTime()`，不要先转字符串 |
| Friend 旧空态溢出 | Prefab 保持只读，用运行时空态文案和添加入口覆盖 |
| 广播消息重复 | 世界本地回显与服务端回包合并；私聊自身双发按发送者/接收者/时间去重 |
| Team 战力被截断 | 服务端写 `uint64`；Unity 必须用 `ReadULongInt`，不要照抄旧 Lua 的 `ReadUInt` |
| Team 推送状态漂移 | `/30` 只作通知，关联自身/当前队长时统一重拉 `/29 op=16` |
| Team 本地功能未开放 | 本地缺配置会得到 `0xffff`；只在 `local_test=1` 回退到开放等级 32 |
| 新 Prefab 路由找不到 | `BootstrapSceneBuilder` 新增装配后先重建场景；模块验证不会自动刷新旧场景 |
| 决战昆仑本地 `/213 op=25` 超时 | 正式服依赖独立匹配服；本地 `long/queue/match` 关闭时仅在 `local_test=1` 返回空匹配状态，禁止改线上分支或伪造 9 个对手 |
| 血战本地 `/323 op=1` 仅回 op | 最小服未生成 `BloodCntCfg`；仅 `local_test=1` 返回完整权威空状态包，线上配置完整分支不变 |
| Bootstrap 每次整场景变化 | `BuildBatch` 先比对 Prefab 路径、层级、顺序和 active 语义签名；一致即跳过，改生成器后运行幂等门禁 |
| Guild 响应包格式不统一 | `/54` 多数处理直接复用请求消息并追加字段，逐 op 读取，不套统一包头 |
| Guild 验证污染数据 | 只用新角色创建单人帮派，读取成员后退出触发解散，并重拉 `/54 op=13` 确认空态 |
| `/320` 货币奖励显示成 `#0` | 权威包使用 `type=600xx,id=0`；保留 id，只用 type 查询现有 ItemCatalog |
| 奖励弹窗格子在画面外 | 导入 `ItemList` 锚点异常；Prefab 只读，在 RewardPresenter 运行时归一化 |
| 首次关卡战斗次数仍为 0 | 以 `op=8` 奖励和重拉后三星为成功证据，保留服务端真实字段，不伪造次数 |
| 福利 Prefab 新接线找不到 | 先执行 `BootstrapSceneBuilder.BuildBatch` 重建 Bootstrap；模块 Runner 只打开现有场景 |
| `/199` 套统一成功码导致错包 | 查询回包直接追加签到字段；只有领取分支追加 `PRO_SUCCESS/ERROR` |
| `/223` 旧客户端可解析但服务端无回包 | 以当前 `CMissionManager` 空实现为准，保留真实空态，不按旧 UI 猜可用性 |
| 两款游戏 Prefab 混在一起 | 不按 basename 匹配；以 Lua 非注释引用和 `csd/` 完整路径生成 scope，未引用项只标记不直接删除 |
| 根目录与 `huodong/` 同名 CSB | 视为两个独立界面；CSB fallback 保留相对目录，禁止拿同名 CSD 替代 |
| `.ani` 无法由 Unity 原生播放 | 先转 JSON，再用 `ImodAnimationPlayer`；CSD/CSB Timeline 单独使用 `CocosTimelinePlayer` |
| Imod 大图在 Unity 切片越界 | `ProjectXAnimation` 必须保留原尺寸、NPOT None、无 Mipmap；默认 2048 缩图会破坏 ANI 像素坐标 |
| Imod 固定调用被误判全覆盖 | 同时跑 `imod_usage.py` 交叉检查 Lua 路径；当前 24 条固定路径有 6 条源包完全缺失 |
| 从另一款游戏补缺失 ANI | 禁止按同名或 Android `xcres` 副本猜补；只接受当前游戏可解码原始 ANI/PNG |
| Timeline 文本命中数与真实调用不一致 | 29 条文本含 1 条注释；28 条有效 `createTimeline` 中通用入口展开为 2 个调用，最终仍是 29 处有效调用、27 个唯一资源 |
| 空 Timeline 被伪造成缺陷 | `shenjiangzhaomu/Online/Lilian/juezhankunlun` 等源文件本身无轨道；Prefab 保留空定义和真实证据，不注入动画 |
| 仓库多代 UI/代码混存 | 先从当前启动入口打印 Lua/C++ 调用链、协议与完整 CSB 路径；禁止按 basename、目录名或截图判断版本 |
| `/222` 被福利与活动共享 | `TempActivityController` 只读一次首字节，再路由 `op=4` 福利或 `op=0xFF/18` 活动；禁止两个 Controller 分别消费同一消息游标 |
| 活动配置启动时缓存 | Manifest 使用通用 `validationData.setupBeforeServer=true`，先备份/注入再启 `kapai.exe`；finally 恢复并删除备份表 |
| 本地登录按钮绑错 | `LoginUI(openType=1)` 使用 `Btn_Play`；`Btn_Login` 是账号密码登录按钮，不能复用 |
| 登录动画只看静态图 | `LoginBgUI` 必须断言 `effect_chuangjue_1` 的 Imod 动作 0 正在循环，再做最终截图 |
| 主界面注释层级过时 | 以当前 Prefab 实际绑定为准；`btn_wanfa` 是 `Layer/Main_UI/btn_wanfa`，不套旧注释中的 `ButtonGroup3` |
| `/65` 被任务与玩法大厅共享 | `Shared/HotPointController` 独占消息游标，再分发 Task/Gameplay Store；禁止两个 Controller 重复读取 |
| `/319` 被装备/法宝与寻宝共享 | `Bootstrap.OnPacket` 只读取一次 op，再调用 `EquipmentController.onOperation` / `XunBaoController.onOperation`；禁止各 Controller 重复读取首字节后顺序试探 |
| Runner 删除冻结基准 | Manifest `screenshots` 只允许登记本次 Runner 生成物；Cocos 冻结图只放 `visualFidelity.cocosScreenshots`，否则 Runner 启动前会删除基准 |
| `/37` 被每日任务与七日目标共享 | `SevenDayController` 必须先识别 `op=4` 并写独立 Store；不能让每日任务 Controller 先消费 op 或混入日常任务列表 |

## 10. 常用验证

```powershell
python -m unittest discover -s tools/ui_migration/tests -v
```

Git 空白检查：

```powershell
& 'C:\Program Files\Git\cmd\git.exe' diff --check
```

迁移文档与 Manifest：

```powershell
pwsh -File tools/unity-migration/Test-UnityMigrationDocs.ps1
```

Unity 模块验收参数示例：

```text
-executeMethod ProjectX.Editor.BootstrapAppRunner.RunBatch
-projectXAutomation
-projectXUserId=<isolated-user-id>
-projectX<Module>Validation
```
## 11. 当前工作区边界

- 只有用户明确要求才 stage、commit、push。
- 处理 Unity 迁移时保留用户已有 xlua `.meta` 删除和 `unityclient/.vscode/`。
- 大日志写入 `build/` 或 `.local/`，对话只读尾部和关键片段。
- 历史证据不再追加到本文件；按模块写入 `docs/unityclient/modules/`，按日期归档到 `docs/unityclient/history/`。
