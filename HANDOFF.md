# Unity 迁移当前交接

## 2026-09-11 Draw 收口（当前唯一有效入口）

- `Draw / 神将招募` 已完成：用户在最后一次直接碎片图标修复后使用原生 Unity GameView 真人复测，并明确反馈“测试通过”；`manualPassed=true`，G6 收口。
- 根因是奖池直接碎片（如 `type=2458, transformItemId=0`）与重复神将转换（`type=60002, transformItemId>0`）属于两条权威回包分支，旧 Unity 只为后一条创建中央碎片卡。现已统一按实际 item id 渲染稳定卡片，并隐藏非神将结果残留品质图。
- 概率结果不要求跨端相同；正式口径是同一真实账号 UI 状态一致，并逐次核对“实际 `/224` 回包 → 业务数据变化 → 结果 UI”一致。正式229条奖池配置的35种直接奖励映射缺失为0。
- 当前工具链373项、文档一致性与 `git diff --check` 通过；SQLite已恢复并完成账号 `7200057/1000003` 重登业务哈希校验，完整性 `ok`、无 Draw 残留；Unity与`kapai.exe`已关闭。
- runtime-v4 的逐控件双端自动证据仍有历史缺口，继续在矩阵披露，不伪造成通过。本次按用户批准的旧验收路径及最终真人 Play 收口。
- 本任务不启动下一个模块。后续工作新建任务，并以 `UNITYCLIENT_STATUS.md` 的当前状态为唯一入口。

关键文件：

- `unityclient/Assets/ProjectX/src/UI/DrawPresenter.cs`
- `tools/unity-migration/Test-UnityMigrationToolchain.ps1`
- `docs/unityclient/modules/DRAW.md`
- `docs/unityclient/matrices/DRAW_CONTROLS.json`
- `.local/unity-validation/draw-final-user-acceptance-latest.json`
- `.local/unity-validation/draw-real-state-random-result-20260911.md`

## 2026-09-10 Draw 新任务交接（已由上节收口替代）

- 当前唯一模块：`Draw`。不得切换到其他模块，不得提交或推送。
- 用户最新决策：停止扩建双端 JSON hardGate v4，尽快按旧验收方案完成 Draw；保留现有 JSON 结果作为诊断证据，不得据此宣称 G4-G6 通过。
- 新任务必须先读取：`AGENTS.md`、`UNITYCLIENT_STATUS.md`、`docs/unityclient/MIGRATION_GUIDE.md`、`docs/unityclient/modules/README.md`、Draw 模块文档、`docs/unityclient/matrices/DRAW_CONTROLS.json`、本节交接。
- 当前 Draw 矩阵：28 个控件，`hardGateVersion=4`，状态为 `g5-retained-g6-runtime-v4-pending`；G6 仍为 pending。
- 最新 Cocos 诊断运行：`.local/unity-validation/runtime-snapshots/Draw/20260910T103138Z/cocos-session.jsonl`。28 条记录、约 76 秒；`automationPassed=4/28`、`engineInputReplayPassed=17/28`、`protocolSemanticPassed=17/28`、`runtimeTreePassed=22/28`。
- 该轮总落盘约 7.61 MB：JSONL 79,073 bytes，39 个树 sidecar 共 7,532,486 bytes；无需把原始 JSON 灌入对话，只读摘要和失败项。
- JSON 方案已发现并修复的关键问题：启动器未强制固定身份 `7200057/1000003`；Cocos 夹具错误沿用角色 `1000115`；运行时页面准备时序不足；CSD 与运行时节点路径不一致；完整树哈希/编码过慢。不要重新调查这些已解决项。
- JSON 当前未解决且不再扩建的契约缺口：A08/A09 等状态观察被错误建模为点击；未完整校验 `expectedVisible/expectedHidden`；未拒绝意外协议；cleanup/state preparation 未形成有效验收。只把这些作为 JSON 不可用于收口的理由。
- Unity `Assembly-CSharp.csproj` 静态编译最近已通过：0 errors，8 个既有 warnings。`RuntimeSnapshotCollector.cs` 的 `CompressionLevel` 歧义已用明确命名空间处理。新任务不得无原因重复大范围编译；只在相关源码变化后执行最小编译。
- Cocos 原生桥已通过 v143 构建；中央工具链最近通过 352 项。除非相关文件变化，不重复重建原生桥或扩充工具链。
- 固定账号：`userId=7200057 / roleId=1000003`。Cocos MySQL 夹具已恢复；Unity SQLite 已恢复并验证完整性及残留 0，但 `reloginVerified=false`，最终旧方案验收必须补恢复后的 Unity 重登复核。
- 当前操作台账：`.local/unity-validation/draw-operation-ledger.json`。保留全部 Failed/Blocked/Resolved 记录；Computer Use 在旧任务曾返回 `apps=[]`，新任务必须重新加载 `computer-use` skill 并先检查实际原生应用能力，不得复用旧句柄或坐标。
- 旧方案执行顺序：先做最小环境/身份预检；再使用 Computer Use 对原生 `ProjectX.exe / Cocos Simulator` 与已打开 Unity Editor GameView 做真实输入；取得合同规定的 9 个同账号、同数据、同步骤、同分辨率稳定状态；生成并排图、50% 叠加图、增强差异图和差异报告；完成恢复、重登、完整性、残留清零；最后等待用户真实 Play 明确确认。
- 验收边界：真实点击和截图不能被 Runner、MCP、BatchMode、Presenter 回调、JSON 回放或历史图片替代。缺任一端截图、差异报告、恢复重登或用户最终确认时，Draw 必须保持 pending。
- PowerShell 规范：只使用 `pwsh.exe`；避免嵌套 shell、字符串拼接命令和 `foreach { ... } |`；复杂逻辑写入现有脚本或先收集到变量再管道；单次输出不超过 200 行。
- 当前 Cocos、Unity、服务端和 MySQL 已停止。新任务只启动旧方案当前步骤必需的一个重任务，结束后清理残留进程。

关键证据：

- `.local/unity-validation/runtime-snapshots/Draw/20260910T103138Z/cocos-session.jsonl`
- `.local/unity-validation/runtime-snapshots/Draw/static-check/continuation-command-and-runtime-failures.txt`
- `.local/unity-validation/draw-operation-ledger.json`
- `.local/unity-validation/draw-sqlite-fixture-latest.json`
- `.local/unity-validation/draw-cocos-runtime-fixture-latest.json`
- `docs/unityclient/matrices/DRAW_CONTROLS.json`
- `tools/unity-migration/runtime-scenarios/draw.json`

> 更新时间：2026-09-07。实时完成率、当前批次和模块门禁唯一读取 [`UNITYCLIENT_STATUS.md`](UNITYCLIENT_STATUS.md)。历史交接不得替代当前源码、状态表、矩阵、Runner 与本机证据。

## 当前仓库基线

- 仓库：`conan2046/kapai`。
- 当前分支：`main`。
- 本轮整理前基线：`9be6fe95 fix(unity-mail): 同步邮件高亮并统一双端验收夹具`，整理前与`origin/main`一致。
- 当前主干包含装备特殊词条S7、神将配装建议S8、Mail SQLite G3、神将重生G6以及Mail双端验收夹具同步；对应提交`49893bf5`、`a3e62376`、`f62308ac`、`9be6fe95`均已进入当前主干历史。
- 用户修改的`unityclient/Assets/ProjectX/res/csd/Prefabs/common/Choose.prefab`与`MailLayer.prefab`均未被覆盖；本轮按用户“本地修改的所有内容”授权原样纳入整理提交。

## 已收口模块：Mail

- 正式门禁：`G0-G6 passed / 13/13 complete / manualPassed=true`。
- Unity固定身份：persistentDataPath SQLite `userId=7200057 / roleId=1000003`。
- G3当前源码已通过13/13真实控件、5/5语义以及真实`/128 op2/3/4`；可逆夹具覆盖14封可见邮件、1封隐藏已领取邮件、无/单/双/九附件、长正文和滚动状态。
- 固定账号Runner已验证重复失败、串行一键领取/已读、本地删除、空态、账号隔离、重登业务状态、最终整库精确恢复和夹具残留0。
- 2026-09-07用户在已打开Unity Editor中完成整模块测试并明确要求直接标记G6；最终证据`.local/unity-validation/mail-final-user-acceptance-latest.json`。
- 已补齐Mail四项sourceAudit，10/10附件PNG存在且签名有效。当前4态双端证据已对齐，仅保留已批准的Cocos列表不滚与详情数量0差异。
- 一键删除按Cocos语义只删除已处理本地历史，保留未读/未领取服务端邮件；左侧列表立即刷新。两个用户Prefab继续保持只读。

## 已收口模块：主界面 HUD

- 正式门禁：`G0-G6 passed / 56/56 complete / manualPassed=true`。
- 用户在已打开Unity Editor的Play/GameView中自行完成当前PlayerHud测试，并明确授权直接标记G6。
- 商城返回后等级动态字形刷新已由`UiStack.Pop`后的HUD权威重绘和Text重注册处理；失败与解决记录已写入PlayerHud ledger。
- 最终证据：`.local/unity-validation/playerhud-final-user-acceptance-latest.json`、`.local/unity-validation/playerhud-retrospective-latest.json`。

## 当前唯一开发模块：强化大师

- 当前门禁：`G0-G3 passed / early user Play pending / G4-G6 pending / 40 controls frozen`。
- 固定账号`1/1000001`已准备2套红装、4件已穿戴法宝和12件法宝材料。
- 下一步只在已打开Unity Editor内完成六页签、装备/法宝养成路由、法宝材料滚动选择和返回主路径的早期真人Play；反馈闭环后再进入G4。
- 2026-09-07用户重排优先级：强化大师 → 神将培养模块B → 将魂商店 → 抽卡 → 神将/阵容 → 装备（法宝边界回归） → 玩法大厅模块组。前六项全部高于玩法大厅。

## 当前全局状态摘要

- Validated主模块：`7/16 = 43.8%`，Login、Settings、PlayerHud、Bag、Task、World、Mail。
- 神将重生：`G0-G6 passed / 24/24 complete`，当前已收口。
- 主界面HUD：`G0-G6 passed / 56/56 complete`，当前已收口。
- 装备/法宝边界回归：`G0-G4 passed / G5 Unity capture passed / Cocos refresh blocked / final user Play passed / G6 blocked by G5`。
- 强化大师、神将培养、玩法大厅和封神列传仍各有早期真人Play或重测边界；不得因其他模块历史证据跳门禁。
- 神将/阵容旧G1仍待真实Cocos状态重采；竞技场及状态表标记的`steam-excluded`模块不得继续迁移。

## 2026-09-07 同步与查漏补缺结果

- 已执行`git fetch origin --prune`；整理前`HEAD`与`origin/main`均为`9be6fe95`，无需额外合并。
- `Test-UnityMigrationToolchain.ps1`：321项通过。
- `Test-UnityMigrationDocs.ps1`：35模块通过，local evidence为optional。
- `Test-UnityMigrationGitScope.ps1 -SummaryOnly`：total 20、semantic 20、meta 0、noise 0、unexpected 0；均为本轮授权整理内容。
- 根交接原先仍写Mail G0-G2、功能分支未进主干、神将重生未完成及旧工作树条目，均已按实时状态纠正。
- `docs/unityclient/modules/README.md`仍有PlayerHUD、装备等摘要落后于`UNITYCLIENT_STATUS.md`；因当前只允许处理Mail，暂不改其他模块索引。后续切换对应模块时再同步，不能以旧摘要覆盖状态表。

## 验证环境

- 基准库：`server/sql/sqlite/fixtures/projectx-validation-base.db`。
- 安装目标：`%USERPROFILE%\AppData\LocalLow\Xuancai\ProjectX\LocalServer\projectx.db`。
- 固定身份：`1/1000001/S8D01`与`7200057/1000003/T00057`。
- `pwsh -NoProfile`可能命中WindowsApps无效Python占位程序；运行迁移脚本时使用Codex bundled Python或显式可用Python，不修改全局环境。
- PNG/JPG、本机日志、数据库备份和运行证据只放`.local/`或`build/`，不得提交Git。

## 常用命令

```powershell
git status --short
git fetch origin --prune
pwsh -NoProfile -File tools/unity-migration/Install-UnityValidationDatabase.ps1 -Action Verify
pwsh -NoProfile -File tools/unity-migration/Run-UnityFixedAccountValidation.ps1 -Module EnhanceMaster -DataPreflightOnly
pwsh -NoProfile -File tools/unity-migration/Run-UnityFixedAccountValidation.ps1 -Module EnhanceMaster -G3RuntimeOnly
pwsh -NoProfile -File tools/unity-migration/Test-UnityMigrationToolchain.ps1
pwsh -NoProfile -File tools/unity-migration/Test-UnityMigrationDocs.ps1
pwsh -NoProfile -File tools/unity-migration/Test-UnityMigrationGitScope.ps1 -SummaryOnly
```

## 收口规则

- 同一时间只处理一个模块；本交接当前锁定强化大师。玩法大厅及其封神列传、法宝搜索、游历三界子模块整体后移。
- G4/G6只认已打开Unity Editor GameView中的真实输入与用户确认；BatchMode/Runner仅用于编译、夹具、oracle和诊断。G5只认当前输入指纹匹配的双端真实证据。
- 失败立即写operation ledger；修复后追加`Resolved`、`resolution`、`iterationAction`和`iterationEvidence`。
- 只有用户明确要求后才提交或推送，并使用严格路径allowlist。
- 阶段完成后关闭本阶段启动的Unity、Cocos、`kapai.exe`、本地数据库和Computer Use运行时。
