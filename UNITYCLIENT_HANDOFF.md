# UnityClient 精简交接

> 最后更新：2026-07-17 12:40
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
| 仓库 | `E:\neiwang_kapai\Game` |
| Unity 工程 | `E:\neiwang_kapai\Game\unityclient` |
| Cocos 客户端 | `E:\neiwang_kapai\Game\client\ProjectX` |
| 服务端 | `E:\neiwang_kapai\Game\server` |
| Unity | `E:\UnityPro\2022.3.62f3c1\Editor\Unity.exe` |
| 本地游戏服 | `127.0.0.1:8711` |
| workspace MySQL | `127.0.0.1:3306` |

这是 Cocos2d-x 2.17 + Lua 前端、C++ 后端的联网卡牌游戏。Unity 客户端以 uGUI + C# 通用层 + xLua 业务控制器重建，不逐字翻译旧 Cocos API。

## 3. 当前任务

下一批：`Friend Store`。

目标边界：好友列表、申请列表、添加、同意、拒绝、删除；先只读，再状态变更。商城手动刷新、邮件批量操作、装备深度培养暂不混入。

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

## 6. 单模块标准流程

1. 查 `server/src/protocol.h` 协议号。
2. 查 `server/src/pack_deal.cpp` 注册和处理函数。
3. 查旧客户端 Lua 的请求、解析、入口和真实 Prefab。
4. 用 smoke/隔离角色确认真实字段，禁止凭注释猜包。
5. 建 `Store/Catalog/Presenter/Lua Controller`。
6. 在 `GameServices/ProjectXApp/ProtocolRegistry/BootstrapSceneBuilder` 接线。
7. 先做只读列表，再增量，再消耗/变更。
8. 自动化必须记录角色、前后状态、资源缺失和结果时间戳。
9. 固定 `1334×750` GameView 视觉检查。
10. 更新 STATUS、模块文档、协议覆盖，关闭本阶段进程。

## 7. Unity 验收规则

- 文档和纯静态修改不启动 Unity/MCP/服务。
- C#/Lua 静态完成后，只有编译、场景、Prefab、Console、PlayMode 才启动 Unity。
- 自动化使用 `Start-Process -Wait`，不得直接假设调用 Unity.exe 会同步阻塞。
- 同一个隔离角色同一时间只能跑一个变更型 Runner。
- Runner 启动前删除旧结果；完成后校验 `success`、UTC、角色和最终状态。
- 严重异常扫描：`error CS`、`LuaException`、`NullReferenceException`、`MissingReferenceException`、assert、真实 crash。
- `CrashHandler` 等 Unity 性能标签不是实际 crash，不能误报。
- batchMode 日志不能替代 GameView；图形环境可用时必须截图。
- 阶段结束关闭 Unity、Unity Hub、Cocos、`kapai.exe`、workspace-local MySQL，并检查 3306/8711。

## 8. 高频坑

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

## 9. 常用验证

UI 转换测试：

```powershell
python -m unittest discover -s tools/ui_migration/tests -v
```

Git 空白检查：

```powershell
& 'C:\Program Files\Git\cmd\git.exe' diff --check
```

Unity 模块验收参数示例：

```text
-executeMethod ProjectX.Editor.BootstrapAppRunner.RunBatch
-projectXAutomation
-projectXUserId=<isolated-user-id>
-projectX<Module>Validation
```

## 10. 当前工作区边界

- 只有用户明确要求才 stage、commit、push。
- 处理 Unity 迁移时保留用户已有 xlua `.meta` 删除、`ShaderGraphSettings.asset` 和 `.vscode/` 变化。
- 大日志写入 `build/` 或 `.local/`，对话只读尾部和关键片段。
- 历史证据不再追加到本文件；按模块写入 `docs/unityclient/modules/`，按日期归档到 `docs/unityclient/history/`。
