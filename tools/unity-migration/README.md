# UnityClient 迁移提速工具

## 入口

| 工具 | 用途 |
|---|---|
| `unityclient-modules.json` | 模块、协议、入口、Prefab、配置、验收参数的机器可读清单 |
| `New-UnityMigrationModule.ps1` | 生成 Store、Catalog、Presenter、Lua Controller 和模块文档骨架 |
| `Get-ProtocolEvidence.ps1` | 按协议号提取服务端、旧客户端、Unity 和 smoke 三方/四方证据 |
| `Run-UnityModuleValidation.ps1` | 串行启服、运行 Unity、校验结果/日志/截图并清理本阶段进程 |
| `Test-UnityMigrationDocs.ps1` | 检查状态唯一性、文档体积、Manifest 和引用路径 |
| `Test-BootstrapSceneIdempotence.ps1` | 连续生成两次 Bootstrap，校验场景 SHA-256 不发生二次变化 |

## 常用命令

```powershell
# 查看脚手架计划，不写文件
pwsh -File tools/unity-migration/New-UnityMigrationModule.ps1 -Module Friend -DisplayName 好友 -WhatIf

# 提取协议证据到 .local/protocol-evidence/
pwsh -File tools/unity-migration/Get-ProtocolEvidence.ps1 -Protocol 221 -Module Shop

# 只打印 Unity 验收计划，不启动任何进程
pwsh -File tools/unity-migration/Run-UnityModuleValidation.ps1 -Module Shop -DryRun

# 完整商城验收；变更型模块未传 UserId 时自动分配隔离角色
pwsh -File tools/unity-migration/Run-UnityModuleValidation.ps1 -Module Shop

# 文档与 Manifest 门禁
pwsh -File tools/unity-migration/Test-UnityMigrationDocs.ps1
pwsh -File tools/unity-migration/Test-BootstrapSceneIdempotence.ps1
```

## 安全规则

- 不启动 Cocos 客户端。
- 运行前发现 Unity 已存在时直接失败，不复用、不强杀。
- 只关闭本脚本实际启动的 `kapai.exe` 和 workspace-local MySQL。
- Unity 必须通过 `Start-Process -Wait` 串行执行。
- 变更型模块默认使用 `.local/unity-migration-userids.json` 分配新角色。
- 变更型模块没有新结果时不会自动重试，避免同一角色重复消耗；重新运行会分配新角色。
- 每次运行删除旧结果，并校验结果文件时间、`success`、状态和截图尺寸。
