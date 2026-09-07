# Unity 迁移当前交接

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
