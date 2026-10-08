# Codex Project Notes

## 1. 项目与数据边界

- 本项目是 Cocos2d-x 2.17 + Lua 客户端、C++ 服务端及 Unity 迁移客户端。
- 普通交互式 Unity Editor/Player 使用 Steam 单机菜单与 `Application.persistentDataPath/Saves/SlotNN/projectx.db`。固定账号验证或外部服务模式须先按启动参数确认实际数据库；走 LocalServer 时使用 `Application.persistentDataPath/LocalServer/projectx.db`，显式单机流程验证则使用指定的隔离 Slot。账号、角色、神将、装备、道具、货币和阵容夹具必须修改当前路径对应的 SQLite。workspace-local MySQL 只用于 Cocos、本地服务端和离线兼容回归，禁止替代 Unity 用户数据。
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

## 2B. 工作路径

### Unity 资源维护目录

- 图片、字体、音频统一由 `unityclient/Assets/Art/` 维护；公共字体和公共 UI 只保留一份语义等价资产，功能目录只放专属资源。
- Clip/Controller 使用 `Assets/Animations/`；Prefab 使用 `Assets/Prefabs/`，UI Catalog/Reference 使用其下 `Catalog/`。
- `Resources/` 仅保留 `AssetReferences/`、Lua 和正式数据。运行时通过 `UnityAssetReference`/`ResourceLoader` 加载；轻量索引由 `ProjectSettings/ProjectXAssetReferences.json` 的逻辑键和 GUID 维护，可用原生资源引用索引菜单重建。新增动态资源须登记键/GUID，不复制美术到 Resources；同名不同类型资源共用有类型索引。
- 移动资产保留 `.meta`。合并资源须同时核对字节、导入参数、Sprite 切片/九宫格/子资源，并重绑 GUID/fileID。历史源和截图放在 Unity Assets 外；截图默认 `unityclient/Captures/Editor/`。
- 场景统一在 `Assets/Scenes/`：`Bootstrap` 是正式入口，`FirstPlayableLoop` 为验证工具场景。Unity 示例/URP 模板/旧导入预览场景已归档到 Assets 外，不再生成回写。

- 工作路径遵循用户本轮最新明确指定的工程。本轮工程为 `E:\neiwang_kapai\Game`，Unity 项目为其下的 `unityclient`。
- 每轮开始分别核对命令当前目录（PowerShell `Get-Location`）、目标工程根目录和 Unity Editor 命令行中的 `-projectPath`；三者分开记录，避免误操作其他 checkout。
- 用户明确更改目标工程时，直接按最新指示切换；历史阶段或旧任务路径不构成限制。

## 2A. 迁移完成后的定向 Bug 修复

- 用户在已完成迁移的功能中指出具体运行 Bug，并明确进入“定向 Bug 修复阶段”后，本节优先于下方 Unity 迁移 G0-G6 流程。
- 定向 Bug 修复不调用迁移门禁工具，不修改 `migration-gates.json`、控件矩阵、迁移完成率或既有 G0-G6 状态，也不要求重新执行 G0-G6。
- 只追踪当前 Bug 的真实来源，实施最小修复，完成编译与必要的定向回归，然后交由用户从实际功能路径复测。
- 既有迁移结论只作为冻结历史保留；只有用户明确要求重新开启迁移验收时，才恢复 G0-G6 流程。

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
- Unity 功能验收统一通过 Unity MCP 执行，包括 Play、真实入口路线、EventSystem/Raycast、节点/业务状态、SQLite 与 Console 检查；不得绕过入口直接调用 Presenter、`.onClick.Invoke()` 或内部完成方法。截图和组件检查只提供证据，画面是否正确由用户最终验收。Unity 单机明确屏蔽的功能不纳入本轮范围。
- Unity功能验收完成一次登录并进入Play后，必须优先在当前Play中连续完成本批所有未覆盖路线；不因单个检查点完成而重新登录或重启Editor/Play。只有发现真实Bug需要修复，或当前Play确实无法继续时才重启。必须中断时记录当前页面、账号/夹具状态、已完成与剩余路线，从最近检查点续验，跳过已有有效证据的路线。
- 每个可见状态必须有当前Cocos与Unity同账号、同数据、同步骤、同分辨率、同稳定帧截图及差异报告。缺任一侧只能标逻辑通过。
- 当前 Unity 框架 W6 的验收范围按用户 2026-09-26 指令冻结：旧 Cocos 文档、截图与 Unity 的差异不作为 W6 阻塞，不为通过旧导入器对比改动当前 Unity 画面，也不向 Cocos 版本同步 Unity 修复。本条仅覆盖当前 W6，其他模块的迁移门禁仍按原规则执行。
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
