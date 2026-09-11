# Codex Project Notes

## 1. 项目与数据边界

- 本项目是 Cocos2d-x 2.17 + Lua 客户端、C++ 服务端及 Unity 迁移客户端。
- Unity Editor/Player 用户功能测试只使用 `Application.persistentDataPath/LocalServer/projectx.db`；账号、角色、神将、装备、道具、货币和阵容夹具必须修改该 SQLite。workspace-local MySQL 只用于 Cocos、本地服务端和离线兼容回归，禁止替代 Unity 用户数据。
- 本地服务端为 workspace-local MySQL + `kapai.exe`；客户端为 Cocos `ProjectX.exe` 或 Unity。每轮只启动当前需要的一套客户端，不继承上一任务运行状态。
- 文档、源码阅读和静态修改不启动 Unity、MCP、Cocos、`kapai.exe` 或 MySQL；编译、Prefab/场景、Console、Play 或协议联调时才按需启动。
- 一个重任务同时只运行一个。验收后关闭本轮启动的进程并检查端口、SQLite锁和残留；长跑或用户明确要求保持运行时除外。
- 默认忽略 `.svn/`、`Library/`、`Temp/`、`Logs/`、`build/`、`.local/`、`tools/local/vcpkg/`。日志只读错误附近或尾部100行，单次输出不超过200行。

## 2. 命令与修改规则

- 使用 PowerShell 7 `pwsh.exe` 和 UTF-8。搜索先用 `rg`/`rg --files`；字面源码片段用 `rg -F`，Windows文件筛选使用 `-g`，禁止把通配符当路径参数。
- PowerShell 的 `for/foreach/while` 输出先用 `@()` 收集再接管道；双引号变量后紧跟冒号时使用 `-f` 或 `${name}`。
- 调用含 `[string[]]` 等数组参数的 PowerShell 脚本时，在当前进程直接 `& $script @params` 做 hashtable splatting；禁止经嵌套 `pwsh -File` 转发数组，也禁止内联 `@('a','b')` 后继续传其他参数。需要消费台账 `recordId` 时使用工具的 `-PassThru` 结构化结果，不解析 `Write-Host` 文本。
- 使用 `apply_patch` 修改文本；保留用户改动、脏工作树、Prefab、`.meta` 和 `unityclient/Captures/`。不清理无关文件，不用 `git add -A`。
- Windows 执行 `git diff --check` 时沿用仓库现有 EOL 配置；禁止临时设置 `core.autocrlf=false`，否则 CRLF 会被批量误报为尾随空格。
- 只在用户明确要求后提交或推送。提交必须包含模块、根因、修复、配置/数据库影响、验证结果和已知限制。

## 3. Unity 迁移最小读取

1. `UNITYCLIENT_STATUS.md`：只读“当前焦点”和目标模块行。
2. `docs/unityclient/STEAM_SCOPE.md`：命中 `steam-excluded` 立即停止。
3. `docs/unityclient/MIGRATION_GUIDE.md`：先读“快速执行闭环”，再按当前门禁定点读取。
4. `docs/unityclient/modules/README.md`：只用于定位目标文档。
5. 只读目标模块文档、目标矩阵，以及该模块未解决/最新同签名 Ledger 记录。

禁止默认完整读取 `history/`、其他模块、完整 Ledger、完整日志或全量 Manifest。实时百分比只在 `UNITYCLIENT_STATUS.md`；稳定流程只在 `MIGRATION_GUIDE.md`；模块事实写 `modules/`；机器控件写 `matrices/`；日期流水写 `history/`。不得创建平行 SOP、状态表或同用途脚本。

新模块先从 `tools/unity-migration/unityclient-modules.json` 定位该模块，复用现有 `Get-ProtocolEvidence.ps1`、`New-UnityMigrationModule.ps1`、`Run-UnityModuleValidation.ps1`、`Run-UnityFixedAccountValidation.ps1` 和文档/工具链测试。

## 4. 固定迁移闭环

同一时间只处理一个模块和一个问题，严格按 G0-G6；未通过不得切模块。跳过门禁必须记录阻塞并取得用户明确批准。

1. **Context/Preflight**：确认范围、checkout、Steam边界、数据后端、源码/资源指纹、进程端口、工具能力和固定身份。
2. **Source closure**：从主界面按钮/模块ID追到 Lua 回调、`OpenFunction/InitUI`、View/Controller、CSB/CSD、动态 Timeline/Imod、协议及服务端处理；G2关闭入口、共享协议、配置资源和运行时Transform审计。
3. **Targeted hybrid**：先写清 `given/when/then` 和权威业务前置条件；执行单控件/单状态真实输入，同时验证玩家可见UI、协议或SQLite结果和当前文件证据。JSON只作索引，单独使用不合格。
4. **Final convergence**：定向问题全部收敛后，才允许一次 `-FinalFull`、G5和G6；恢复夹具、重登哈希、完整性和残留必须通过。用户在最后一次相关变更后的真实Play确认前，`manualPassed=false`。

硬规则：

- 失败后先保存最小复现并诊断，禁止盲目重跑 Full。
- 同签名第二次出现必须修现有公共工具/预检；第三次必须补 `Test-UnityMigrationToolchain.ps1` 回归。
- 截图前必须先断言业务条件确实能产生目标状态；输入或夹具错误时不得继续截图。
- 只重验变更影响的最早门禁和状态；源码、资源、账号、夹具、步骤、分辨率或稳定帧指纹变化时，旧证据失效。
- G3初版可运行后立即安排5–15分钟早期真实Play；反馈关闭后才进入G4。早测不代替G6最终确认。

## 5. 真实交互与证据

- Cocos只操作原生 `ProjectX.exe / Cocos Simulator`，使用 Computer Use。启动服务前记录transport预检；截图前校验唯一进程、固定身份、输入可用和 `1336×777 → (1,26,1334,750)` 无缩放裁切。首次未到目标页即停止坐标试错，转查回调、日志和协议。
- Unity MCP只用于G3的Prefab、场景、编译和Console检查；G4-G6必须使用真实EventSystem/raycast可达输入。Presenter、`.onClick.Invoke()`、内部完成方法、旧Runner或Batch摘要不能作为验收。
- 每个可见状态必须有当前Cocos与Unity同账号、同数据、同步骤、同分辨率、同稳定帧截图及差异报告。缺任一侧只能标逻辑通过。
- 静态Image、CSB Timeline、Imod模型必须保持资源类型、动作号、循环、缩放和挂点语义，不能互相替代。

## 6. 夹具、失败台账和恢复

- 变更型模块在G3前登记固定账号、数据需求、快照、恢复和残留合同；启动Unity前执行 `-DataPreflightOnly`。
- 固定状态机：`Setup → AssertSetup → 被测操作 → Restore → AssertRestored → Relogin/AssertReloginHash → Cleanup → AssertCleanup`。同一生命周期禁止第二次Setup。
- 每次失败/阻塞立即追加到 `.local/unity-validation/<module>-operation-ledger.json`；保留原错误。解决时关联唯一 `recordId`，填写根因、解决方式、迭代动作和已存在的文件证据，不删除失败记录。
- G6复盘存在未诊断、未解决或无文件证据记录时不得收口。规则ID唯一维护在 `tools/unity-migration/root-cause-rules.json`。

## 7. 本地服务端入口

- 客户端 `AppDef.LOCAL_TEST=true` 时直连 `127.0.0.1:8711`；服务端 `local_test=1` 跳过缺失登录服，但不得删除线上路径。
- 服务端工作目录必须为 `server/config`。常用入口：`LOCAL_RUN.md`、`LOCAL_DEBUG.md`、`PROTOCOL_COVERAGE.md`、`tools/local/Check-LocalEnv.ps1`、`Start-Server.ps1`、`Start-Client.ps1`、`Invoke-ProtocolSmoke.ps1`、`Run-LocalVerification.ps1`。
- 登录/创角查 `server/src/pack_deal.cpp`；协议先查 `protocol.h` 和 `cmdFun`；Lua缺绑定查 `server/script/*.lua` 与 `lua_j_stub.cpp`；缺表/字段补最小schema，不猜正式库。
- Windows兼容、DLL链、协议编码、Lua stub、已修崩溃和本地降级规则按需读取 `LOCAL_DEBUG.md`；历史验证读取 `LOCAL_HISTORY.md`。

## 8. 完成与资源边界

- 优先最小改动，正式线上路径必须可恢复；不得伪造登录、奖励、概率、配置或业务数据。
- 资源缺失必须追溯配置和生成链；不得用临时占位或错误类型资源冒充完成。
- 当前迁移优先级和唯一活动模块只认 `UNITYCLIENT_STATUS.md`。进入任何P2商业化模块前必须先完成 `docs/unityclient/modules/PAYMENT.md`，当前不得误报已实现。
