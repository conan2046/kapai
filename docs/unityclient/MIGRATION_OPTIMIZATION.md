# Unity 迁移基础设施优化

> 状态：2026-07-19 第一批已落地；新模块迁移暂停，先验证基础设施稳定性。

## 已落地

| 优化 | 落点 | 验收口径 |
|---|---|---|
| 证据生命周期隔离 | `validation-scenarios.json`、Runner 运行产物保护 | Runner 只能删除 `lifecycle=runtime`；`.local/ui-fidelity` 永久拒绝删除 |
| 中央场景注册表 | `validation-scenarios.json` | 29/29 模块唯一场景；参数、夹具、产物、截图状态集中维护 |
| 角色夹具注册表 | `validation-fixtures.json` | 只读、隔离角色、Friend/Team 多角色、全局快照回滚均显式声明 |
| G0-G6 机器门禁 | `migration-gates.json`、`Invoke-UnityMigrationGate.ps1` | 前置门禁或证据缺失时拒绝落账；脚手架默认 G0-G6 全 pending |
| 共享协议 op 路由 | `Shared/ProtocolOpRouter.lua.txt` | `/319` 装备/法宝与寻宝按 op 唯一路由；重复注册直接断言 |
| 资源哈希防碰撞 | `Import-FaBaoIcons.ps1` | 默认发现同名异内容即失败；只有显式授权才能刷新 |
| Lua/C# 权威边界 | `New-UnityMigrationModule.ps1` | 新模块只生成 Lua Controller、只读 ViewState、RenderBridge，不生成业务 Store/Catalog |
| 双端状态清单 | `validation-scenarios.json/captureStates` | 装备/法宝固定 13 个状态；后续截图工具和差异报告复用同一清单 |
| 外层 Watchdog | `Run-UnityModuleValidation.ps1` | Unity 默认 300 秒超时，终止本次进程树并输出场景/尝试号 |
| Git 噪声分层 | `Test-UnityMigrationGitScope.ps1` | 语义变更、Unity `.meta`、换行/时间戳噪声分开报告；933 个脏项实测由 30 秒以上降至约 2 秒 |
| Manifest 生成文档门禁 | `Test-UnityMigrationDocs.ps1` | Manifest、场景、夹具、门禁、资源路径和 Runner 参数漂移统一失败 |

## 保留兼容边界

- `unityclient-modules.json.validationFlags/screenshots` 暂保留，中央场景与其不一致时文档门禁失败；稳定两批后再删除旧字段。
- Friend/Team 的具体拉起过程仍由 Runner adapter 执行，但角色模式和清理语义已收口到 fixture profile。
- 已有业务型 C# Store/Catalog 不批量推倒，只在模块再次触达时迁回 Lua 权威。
- Bootstrap 场景继续使用现有两次 SHA-256 幂等门禁，本批不改序列化逻辑。

## 验证结果

| 项 | 结果 |
|---|---|
| 中央场景 DryRun | 29/29 通过；未启进程、未分配角色、未删产物 |
| 文档/清单一致性 | 29 模块、29 场景、5 夹具通过 |
| Python UI | 16/16 通过 |
| 法宝资源哈希 | 53/53 通过，changed=0 |
| HeroEquip 真实 Runner | `userId=7200066`；穿戴→强化 `0→2`→卸下、法宝穿脱、非法/重复、最终重拉通过 |
| Bootstrap 幂等 | 两次 SHA-256 `5B9CEAF8618C798A75B6EEB6DBB712B9846F3F861983B421CEFAC7463F9977F3` |
| Unity 严重异常 | 0 |
| Git scope | 933 个脏项在约 2 秒分类：17 语义、914 `.meta`、2 换行/时间戳噪声；本批 allowlist 外 0 |
| 进程清理 | Unity、`kapai.exe`、workspace MySQL 均已关闭；3306/8711 监听 0 |

## 恢复迁移前门禁

1. `Test-UnityMigrationDocs.ps1` 通过。
2. 29 个场景 DryRun 通过，且不分配角色、不删除文件。
3. HeroEquip 真实 Runner 通过，验证 `/319` Router、夹具、Watchdog 和运行截图保护。
4. Python UI 16/16、Bootstrap 幂等、严重异常扫描通过。
5. Git scope 仅包含本批 allowlist；现存用户 `.meta` 和换行噪声不得混入提交。

以上已全部通过。迁移仍按用户要求保持暂停；后续恢复时只允许当前 HeroEquip G5 补证，不开启新模块。
