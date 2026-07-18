# UnityClient 精简交接

> 最后更新：2026-07-18 11:20
> 当前状态：`UNITYCLIENT_STATUS.md`
> 长期计划：`UNITYCLIENT_MIGRATION_PLAN.md`
> 模块证据：`docs/unityclient/modules/`
> 历史全文：`docs/unityclient/history/`

## 1. 新任务读取顺序

1. `AGENTS.md`。
2. `UNITYCLIENT_STATUS.md`。
3. 本文件。
4. `docs/unityclient/modules/README.md` 和目标模块文档。
5. 只读取 `UNITYCLIENT_MIGRATION_PLAN.md` 的对应阶段，不默认全文读取历史。

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

这是 Cocos2d-x 2.17 + Lua 前端、C++ 后端的联网卡牌游戏。Unity 客户端以 uGUI + C# 通用层 + xLua 业务控制器重建，不逐字翻译旧 Cocos API。

## 3. 当前任务

先前活动任务误取了仓库旧版“玩法”链路（`/209 + ActivityLayer`），结论已作废，不提交、不计完成率。仓库同时包含多代代码/UI，后续以当前可运行 Cocos 的实际代码调用链作为唯一版本依据。

登录第一阶段已完成代码取证、Unity 修正与专用门禁：`LogoScene→GameScene→LGameLogic→LoginBgUI/LoginUI(openType=1)`，真实启动资源与六组预载名称、登录/选服/创角/主界面 Prefab、本地按钮 `Btn_Play`、协议 `/1001→/1003→/1004→/88`、登录背景和男女角色 Imod、`NoticeLayer` 标题/正文均已动态验收。最终账号 `7300109`、角色 `1000046`；证据见 `docs/unityclient/modules/LOGIN.md`。

下一阶段按当前运行代码重新追活动入口、协议与真实 CSB；旧 `/209 + ActivityLayer` 结论禁止复用。截图只用于最终像素验收，不用于推断入口、协议或版本。

## 4. 已稳定的分层

```text
入口/Prefab
  → Presenter（节点绑定、渲染、交互转发）
  → Lua Controller（协议业务与按钮流程）
  → ProtocolRegistry/Reader/Writer
  → Store（权威状态、增量合并、事件）
  → Presenter 重绘
```

约束：

- Presenter 不解析网络字节，不写奖励/消耗规则。
- Lua Controller 不直接操作 Unity 层级。
- 原始网络数据必须先进入 Store。
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

## 6. 迁移提速工具

| 工具 | 用途 |
|---|---|
| `tools/unity-migration/unityclient-modules.json` | 模块、协议、入口、Prefab、配置、验收参数和数据夹具 |
| `New-UnityMigrationModule.ps1` | 生成 Store/Catalog/Presenter/Lua/模块文档骨架 |
| `Get-ProtocolEvidence.ps1` | 按协议号提取服务端、旧客户端、Unity、smoke 证据 |
| `Run-UnityModuleValidation.ps1` | 自动分配隔离角色、启服、串行 Unity、结果/截图检查和清理 |
| `Test-UnityMigrationDocs.ps1` | 状态唯一性、文档体积、Manifest 和路径门禁 |
| `Test-BootstrapSceneIdempotence.ps1` | 连续生成两次并校验 Bootstrap 场景 SHA-256 稳定 |
| `tools/ui_migration/convert_ui.py` | 按完整相对路径生成 UI IR、CSB 兜底和 `runtime-ui-usage.json` |
| `tools/ui_migration/convert_animations.py` | 全量解析 Imod `.ani`，按 `welfare/all` scope 准备 Unity 资源 |
| `prepare_unity_project.py --scope timeline` | 解析 29 处有效 Timeline 调用，只准备 27 个唯一目标 Prefab |

完整用法见 `tools/unity-migration/README.md`。

## 7. 单模块标准流程

1. 先运行 `Get-ProtocolEvidence.ps1 -Protocol <id> -Module <name>` 生成取证草稿。
2. 查 `server/src/protocol.h` 协议号。
3. 查 `server/src/pack_deal.cpp` 注册和处理函数。
4. 查旧客户端 Lua 的请求、解析、入口和真实 Prefab。
5. 用 smoke/隔离角色确认真实字段，禁止凭注释猜包。
6. 用脚手架或现有结构建立 `Store/Catalog/Presenter/Lua Controller`。
7. 在 `GameServices/ProjectXApp/ProtocolRegistry/BootstrapSceneBuilder` 接线。
8. 先做只读列表，再增量，再消耗/变更。
9. 使用 `Run-UnityModuleValidation.ps1 -Module <name>` 收口。
10. 更新 STATUS、模块文档、协议覆盖，运行文档门禁并关闭本阶段进程。

## 8. Unity 验收规则

- 文档和纯静态修改不启动 Unity/MCP/服务。
- C#/Lua 静态完成后，只有编译、场景、Prefab、Console、PlayMode 才启动 Unity。
- 自动化使用 `Start-Process -Wait`，不得直接假设调用 Unity.exe 会同步阻塞。
- 同一个隔离角色同一时间只能跑一个变更型 Runner。
- Runner 启动前删除旧结果；完成后校验 `success`、UTC、角色和最终状态。
- 严重异常扫描：`error CS`、`LuaException`、`NullReferenceException`、`MissingReferenceException`、assert、真实 crash。
- `CrashHandler` 等 Unity 性能标签不是实际 crash，不能误报。
- batchMode 日志不能替代 GameView；图形环境可用时必须截图。
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
| 日志成功但 UI 错位 | 固定分辨率截图检查文字、裁剪、层级和按钮状态 |
| 测试数据重复消耗 | 每个变更场景使用新隔离角色，失败角色不复用为最终证据 |
| ISO UTC 被误判为 stale | PowerShell 7 已转为 `DateTime` 时直接 `ToUniversalTime()`，不要先转字符串 |
| Friend 旧空态溢出 | Prefab 保持只读，用运行时空态文案和添加入口覆盖 |
| 广播消息重复 | 世界本地回显与服务端回包合并；私聊自身双发按发送者/接收者/时间去重 |
| Team 战力被截断 | 服务端写 `uint64`；Unity 必须用 `ReadULongInt`，不要照抄旧 Lua 的 `ReadUInt` |
| Team 推送状态漂移 | `/30` 只作通知，关联自身/当前队长时统一重拉 `/29 op=16` |
| Team 本地功能未开放 | 本地缺配置会得到 `0xffff`；只在 `local_test=1` 回退到开放等级 32 |
| 新 Prefab 路由找不到 | `BootstrapSceneBuilder` 新增装配后先重建场景；模块验证不会自动刷新旧场景 |
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
| 本地登录按钮绑错 | `LoginUI(openType=1)` 使用 `Btn_Play`；`Btn_Login` 是账号密码登录按钮，不能复用 |
| 登录动画只看静态图 | `LoginBgUI` 必须断言 `effect_chuangjue_1` 的 Imod 动作 0 正在循环，再做最终截图 |

## 10. 常用验证

UI 转换测试：

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
