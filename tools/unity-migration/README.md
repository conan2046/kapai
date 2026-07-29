# UnityClient 迁移提速工具

## 入口

| 工具 | 用途 |
|---|---|
| `unityclient-modules.json` | 模块、协议、入口、Prefab、配置、验收参数的机器可读清单 |
| `validation-scenarios.json` | Runner 参数、夹具、运行产物和双端截图状态的中央注册表 |
| `validation-fixtures.json` | 只读、隔离角色、多人角色及全局快照回滚策略 |
| `module-evidence-contracts.json` | 固定账号适配器、快照、G5 双端目录与状态对 |
| `migration-gates.json` | 模块 G0-G6 的机器可读状态；未通过前置门禁时拒绝运行 |
| `New-UnityMigrationModule.ps1` | 生成 Lua Controller、只读 ViewState、RenderBridge、模块文档和待办门禁 |
| `Get-ProtocolEvidence.ps1` | 按协议号提取服务端、旧客户端、Unity 和 smoke 三方/四方证据 |
| `Run-UnityModuleValidation.ps1` | 串行启服、运行 Unity、校验结果/日志/截图并清理本阶段进程 |
| `Run-UnityFixedAccountValidation.ps1` | 通用固定账号快照、注入、矩阵覆盖、精确恢复和重登录复核 |
| `Test-UnityModuleG5Preflight.ps1` | G5 状态对、目录、尺寸、新鲜度和重复哈希预检 |
| `New-UnityModuleG5Evidence.ps1` | 通用 G5 双端比较、输入哈希、提交来源和联系表 |
| `Invoke-UnityMigrationGate.ps1` | 校验门禁前置项和证据；按 G0→G6 顺序落账 |
| `Test-UnityMigrationDocs.ps1` | 检查状态唯一性、文档体积、Manifest 和引用路径 |
| `Test-BootstrapSceneIdempotence.ps1` | 连续生成两次 Bootstrap，校验场景 SHA-256 不发生二次变化 |
| `Test-UnityMigrationGitScope.ps1` | 分离语义修改、Unity `.meta` 和换行噪声，并支持 allowlist 门禁 |

迁移流程、功能和视觉完成口径统一见 `docs/unityclient/MIGRATION_GUIDE.md`。`Run-UnityModuleValidation.ps1` 的 Unity 单端截图只证明界面可运行；没有同状态 Cocos 基准、节点映射与差异报告时，Manifest 只能标记 `logic-validated-visual-pending`。

## 常用命令

```powershell
# 查看脚手架计划，不写文件
pwsh -File tools/unity-migration/New-UnityMigrationModule.ps1 -Module Friend -DisplayName 好友 -WhatIf

# 提取协议证据到 .local/protocol-evidence/
pwsh -File tools/unity-migration/Get-ProtocolEvidence.ps1 -Protocol 221 -Module Shop

# 只打印 Unity 验收计划，不启动任何进程
pwsh -File tools/unity-migration/Run-UnityModuleValidation.ps1 -Module Shop -DryRun

# 仅做中央注册表、源码锚点和门禁漂移预检，不启服务
pwsh -File tools/unity-migration/Run-UnityModuleValidation.ps1 -Module Task -ValidationMode Preflight

# 复检现有截图的尺寸、最小体积和重复内容，不替代新鲜 G5 双端取证
pwsh -File tools/unity-migration/Run-UnityModuleValidation.ps1 -Module Task -ValidationMode VisualReplay

# 完整商城验收；变更型模块未传 UserId 时自动分配隔离角色
pwsh -File tools/unity-migration/Run-UnityModuleValidation.ps1 -Module Shop

# 固定账号回滚验收与 G5 对照均由模块契约驱动
pwsh -File tools/unity-migration/Run-UnityFixedAccountValidation.ps1 -Module Task
pwsh -File tools/unity-migration/New-UnityModuleG5Evidence.ps1 -Module Task

# 工具链自身回归；不启服务、不修改账号
pwsh -File tools/unity-migration/Test-UnityMigrationToolchain.ps1

# 固定账号编译预检；不修改账号
pwsh -File tools/unity-migration/Run-UnityFixedAccountValidation.ps1 -Module Shop -PreflightOnly

# 固定账号数据预演；快照、注入、断言、恢复并清除残留，不启动 Unity
pwsh -File tools/unity-migration/Run-UnityFixedAccountValidation.ps1 -Module Shop -DataPreflightOnly

# 文档与 Manifest 门禁
pwsh -File tools/unity-migration/Test-UnityMigrationDocs.ps1
pwsh -File tools/unity-migration/Test-UnityMigrationDocs.ps1 -Module Shop
pwsh -File tools/unity-migration/Test-UnityModuleG5Preflight.ps1 -Module Shop -RequireInputs
pwsh -File tools/unity-migration/Test-BootstrapSceneIdempotence.ps1

# 只校验 G3 前置门禁；-Complete 时必须传真实证据路径
pwsh -File tools/unity-migration/Invoke-UnityMigrationGate.ps1 -Module HeroEquip -Gate G3
```

## 安全规则

- 不启动 Cocos 客户端。
- 运行前发现 Unity 已存在时直接失败，不复用、不强杀。
- 只关闭本脚本实际启动的 `kapai.exe` 和 workspace-local MySQL。
- Unity 必须通过 `Start-Process -Wait` 串行执行。
- 变更型模块默认使用 `.local/unity-migration-userids.json` 分配新角色。
- 变更型模块没有新结果时不会自动重试，避免同一角色重复消耗；重新运行会分配新角色。
- 只删除 `validation-scenarios.json` 中 `lifecycle=runtime` 的产物；`.local/ui-fidelity` 冻结证据受硬保护。
- 每次运行校验结果文件时间、`success`、状态和截图尺寸；Unity 超时由外层 Watchdog 终止并记录场景。
- Runner 参数、夹具和截图状态只在中央场景清单维护；Manifest 保留兼容字段并由文档门禁检查漂移。
- 新模块脚手架默认生成 Lua 权威 + C# 只读 DTO/RenderBridge，不再生成业务型 Store/Catalog。
- 每个界面先记录 Cocos 脚本/操作步骤/UI 资产和基准截图，再记录 Unity 对照与差异报告；不得用“无裁切/无重叠”代替 1:1 验收。
- 启动时缓存配置的模块可在 `validationData` 设置 `setupBeforeServer=true`；Runner 会先启动 MySQL、执行同一套 Manifest SQL，再启动 `kapai.exe`，cleanup 仍在 finally 统一执行。
- `sourceContracts` 在启服前校验 Cocos/Unity 关键文件与锚点，优先暴露入口、协议和实现漂移。
- `validationData.setupAssertSql/cleanupAssertSql` 可用 SQL `SIGNAL` 把夹具注入与恢复验证变为硬失败。
- 声明 `controlCoverageRequired` 后，Runner 实际触发 ID 必须与矩阵 ID 完全一致；语义断言失败或缺失同样硬失败。
- 变更型固定账号模块可在 `fixedAccount` 声明 `extraFlags`、`skipPostValidationFixtureAssert=true` 和 `artifactCopies`：先保存运行原图，再由适配器精确恢复并重登录复核；不得在变更完成后误用“夹具仍处于 Setup 状态”断言。
- 固定账号合同字段在文档门禁和运行入口双重校验，禁止缺字段后进入 G5。
- 每个固定账号合同必须声明 `dataPreflight.requirements`；进入 Unity 前可独立验证数据准备、断言、精确恢复和残留清理。
- 固定账号完整验证必须持有当前适配器和数据需求指纹匹配的 `*-fixed-account-data-preflight-latest.json`，否则在启动 Unity 前失败。
- 数据预演凭证同时绑定非空源码契约和 G5 契约指纹；G3 后入口、状态对或截图目录漂移会在 Unity 启动前失败。
- 普通与固定账号验证统一使用启动存活、日志/CPU/结果进展、心跳、硬超时和进程树清理；旧日志不计为当前进展。
- 固定账号完整验证直接写 G6 标准摘要并引用独立 `resultEvidence`，不再人工补摘要或污染普通隔离账号结果。
- `cleanup=disposable-role` 在停止服务后按精确 userId/roleId 删除并查询残留；残留不为 0 时整次验证失败。
- 夹具写入前先检查项目相关 `dotnet`/ILPP 残留和 Unity 编译状态；编译输入未变化时复用 SHA-256 预检缓存。
- PowerShell/Python 在启动服务前解析为绝对路径；完整运行另存 `*-timings-latest.json` 记录真实阶段耗时。
