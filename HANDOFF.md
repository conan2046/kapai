# Unity 迁移当前交接

> 更新时间：2026-09-05。实时完成率、当前批次和模块门禁唯一读取 [`UNITYCLIENT_STATUS.md`](UNITYCLIENT_STATUS.md)。历史交接不得替代当前源码、状态表、矩阵、Runner 与本机证据。

## 当前仓库基线

- 仓库：`conan2046/kapai`。
- 当前分支：`feature/hero-skill-affix-v1`。
- 当前提交：`cd011165 feat(unity): 完成神将重生G6迁移`，与`origin/main`一致。
- 当前分支包含装备特殊词条S7、神将配装建议S8、Mail SQLite G3以及神将重生G6；对应提交`49893bf5`、`a3e62376`、`f62308ac`均已进入当前主干历史。
- 当前工作树只有976个Unity自动漂移的`.meta`：`HeroUI` 91项、`ProjectXAnimation` 885项；语义改动0、noise 0、unexpected 0。不得批量暂存、提交、reset、checkout或stash这些`.meta`。

## 当前唯一开发模块：Mail

- 正式门禁：`G0-G3 passed / early user Play pending / G4-G6 pending`。
- Unity固定身份：persistentDataPath SQLite `userId=7200057 / roleId=1000003`。
- G3当前源码已通过13/13真实控件、5/5语义以及真实`/128 op2/3/4`；可逆夹具覆盖14封可见邮件、1封隐藏已领取邮件、无/单/双/九附件、长正文和滚动状态。
- 固定账号Runner已验证重复失败、串行一键领取/已读、本地删除、空态、账号隔离、重登业务状态、最终整库精确恢复和夹具残留0。
- 用户早测准备曾注入邮件夹具并启动Unity，但没有收到明确验收反馈。2026-09-05已确认Unity、`kapai.exe`、`ProjectX.exe`和MySQL均未运行，并将数据库精确恢复到基准SHA-256 `CAD6FCF3E98F64A491328650CA911DFA685F6301E49CEDA3E8C7365AA23A3511`；夹具备份已清理。
- 2026-09-05用户授权暂缓人工验收，继续自动步骤；本轮Mail标准Full通过13/13控件、5/5语义、重登、精确恢复和残留0。人工确认仍未通过。
- 已补齐Mail四项sourceAudit，10/10附件PNG存在且签名有效，标准硬门禁预检及VisualReplay通过，原阻塞已Resolved。结构复检不等于当前G5双端视觉，正式G4-G6仍pending。

### Mail 下一步

1. 用户继续暂缓人工验收。Mail双端夹具已统一，15封邮件及货币/角色名一致，高亮滞后已修复且Full通过。下一步诊断Cocos真实入口无`/128`且客户端退出的问题后重采四态；断开日志的`login_log_9`格式错误不等于已确认退出根因。旧Cocos基线已失效。详见`.local/unity-validation/mail-visual-parity-result.md`。
2. 自动Full已通过，业务代码未改变时不重复重跑；缺当前双端证据的状态按标准采集路径准备。
3. 不把历史manualPassed或本轮结构复检作为当前用户确认。正式G4-G6保持pending，直至满足门禁或记录适用的明确豁免。
4. 仅处理Mail；测试夹具遵守SQLite快照、精确恢复和残留0合同，当前无须保持游戏进程。

## 当前全局状态摘要

- Validated主模块：`5/16 = 31.3%`，仅Login、Settings、Bag、Task、World。
- 神将重生：`G0-G6 passed / 24/24 complete`，当前已收口。
- 主界面HUD：`G0-G3 retained / early user Play passed / G4-G6 pending`。
- 装备/法宝边界回归：`G0-G4 passed / G5 Unity capture passed / Cocos refresh blocked / final user Play passed / G6 blocked by G5`。
- 强化大师、神将培养、Mail、玩法大厅和封神列传仍各有早期真人Play或重测边界；不得因其他模块历史证据跳门禁。
- 神将/阵容旧G1仍待真实Cocos状态重采；竞技场及状态表标记的`steam-excluded`模块不得继续迁移。

## 2026-09-05 拉取与查漏补缺结果

- 已执行`git fetch origin --prune`；当前`HEAD`与`origin/main`均为`cd011165`，无需额外合并。
- `Test-UnityMigrationToolchain.ps1`：319项通过。
- `Test-UnityMigrationDocs.ps1`：35模块通过，local evidence为optional。
- `Test-UnityMigrationGitScope.ps1 -SummaryOnly`：total 976、semantic 0、meta 976、noise 0、unexpected 0。
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
pwsh -NoProfile -File tools/unity-migration/Run-UnityFixedAccountValidation.ps1 -Module Mail -DataPreflightOnly
pwsh -NoProfile -File tools/unity-migration/Run-UnityFixedAccountValidation.ps1 -Module Mail -G3RuntimeOnly
pwsh -NoProfile -File tools/unity-migration/Test-UnityMigrationToolchain.ps1
pwsh -NoProfile -File tools/unity-migration/Test-UnityMigrationDocs.ps1
pwsh -NoProfile -File tools/unity-migration/Test-UnityMigrationGitScope.ps1 -SummaryOnly
```

## 收口规则

- 同一时间只处理一个模块；本交接当前锁定Mail。
- G4/G6只认标准batch Runner；G5只认当前输入指纹匹配的双端真实证据。
- 失败立即写operation ledger；修复后追加`Resolved`、`resolution`、`iterationAction`和`iterationEvidence`。
- 只有用户明确要求后才提交或推送，并使用严格路径allowlist。
- 阶段完成后关闭本阶段启动的Unity、Cocos、`kapai.exe`、本地数据库和Computer Use运行时。
