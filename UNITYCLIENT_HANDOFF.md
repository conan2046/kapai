# UnityClient 精简交接

> 最后更新：2026-07-17 22:02
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

Guild 第一阶段已完成：`/54` 空态、帮派列表、当前帮派、成员列表、创建和退出/单人解散已通过隔离账号闭环。

最终证据账号为 `7200003`，角色 `U00003`，帮派 `验00003`；退出后已解散。Friend、Chat、Team、Guild 统一复用 `PlayerSummary`。下一模块尚未开始；Guild 的申请批准、邀请、职位、捐献、任务和红点深化继续后置，不与其他模块混做。

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

## 6. 迁移提速工具

| 工具 | 用途 |
|---|---|
| `tools/unity-migration/unityclient-modules.json` | 模块、协议、入口、Prefab、配置和验收参数 |
| `New-UnityMigrationModule.ps1` | 生成 Store/Catalog/Presenter/Lua/模块文档骨架 |
| `Get-ProtocolEvidence.ps1` | 按协议号提取服务端、旧客户端、Unity、smoke 证据 |
| `Run-UnityModuleValidation.ps1` | 自动分配隔离角色、启服、串行 Unity、结果/截图检查和清理 |
| `Test-UnityMigrationDocs.ps1` | 状态唯一性、文档体积、Manifest 和路径门禁 |

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
| Guild 响应包格式不统一 | `/54` 多数处理直接复用请求消息并追加字段，逐 op 读取，不套统一包头 |
| Guild 验证污染数据 | 只用新角色创建单人帮派，读取成员后退出触发解散，并重拉 `/54 op=13` 确认空态 |

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
