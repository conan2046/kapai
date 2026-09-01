# Unity 迁移当前交接

> 实时完成率、当前批次和模块门禁唯一读取 [`UNITYCLIENT_STATUS.md`](UNITYCLIENT_STATUS.md)。
> 历史交接已归档到 `docs/unityclient/history/2026-07-to-2026-08-handoff-legacy.md`，不得用其中数字、路径、截图、SHA、账号或 Runner 结论替代当前证据。

## 当前批次

- BattleFengShenStory：2026-09-01 当前输入下 G0-G6 全部通过；9/9控件、10态双端视觉、标准固定账号batch、两次BuildBatch与用户最终Play均通过。
- BattleFengShenStory 自动复盘：失败244、解决244、补充证据4、待诊断0、未解决0；固定账号SQLite `7200057/1000003` 已恢复为40级/1600经验，WAL/SHM均不存在。
- Mail 已按正式门禁从旧`g6-complete`降为G0-G2 passed；Shop降为G0-G4 passed。旧证据保留，但不得冒充当前门禁。
- 全局文档校验34模块通过；Validated主模块保持`5/16 = 31.3%`，BattleFengShenStory属于非分母战斗子模块。
- 同一时间只推进用户当前指定的一个模块；上一门禁未通过不得进入下一门禁或下一模块。

## 当前工作树保护

- 当前已知用户改动：`server/config/config`。
- 当前未跟踪输入：`tmp/pdfs/ai-game-factory-article/` 下图片。
- 上述内容不属于本轮治理范围；不得 reset、checkout、stash、暂存或夹带提交。
- 每次继续前重新执行 Git 状态检查；本节只记录交接时观察，不作为未来数量基线。

## 下一步

1. 新任务先由用户指定下一个模块，再读取 `UNITYCLIENT_STATUS.md`、`docs/unityclient/MIGRATION_GUIDE.md`、`docs/unityclient/modules/README.md`、目标模块文档/矩阵及 `migration-gates.json`。
2. 确认用户当前指定模块和最早 pending 门禁。
3. 新模块 G0 使用中央脚手架生成当前入口清单、协议证据和历史根因命中报告；不得手写缩小分母。
4. 后续新模块记录 G0-G6 日历周期和 Runner 机器耗时；不追补历史模块。
5. 商业发布工程化按 `docs/unityclient/COMMERCIAL_RELEASE_HARDENING.md` 执行；必须先完成C0并取得预算、语言和字体决策。
6. 只有用户明确要求后才提交或推送，并使用严格路径 allowlist。

## 常用入口

```powershell
python tools/cocos-audit/Export-CocosCurrentInventory.py --output tools/cocos-audit/generated
./tools/unity-migration/Get-ProtocolEvidence.ps1 -Protocol <Protocol> -Module <Module>
./tools/unity-migration/Invoke-UnityMigrationGate.ps1 -Module <Module> -Gate G0
./tools/unity-migration/Run-UnityModuleValidation.ps1 -Module <Module> -ValidationMode Preflight
./tools/unity-migration/Run-UnityFixedAccountValidation.ps1 -Module <Module> -DataPreflightOnly
./tools/unity-migration/Test-UnityMigrationDocs.ps1
./tools/unity-migration/Test-UnityMigrationGitScope.ps1 -SummaryOnly
```

## 收口规则

- 初版 UI、协议、代码可运行后立即邀请早期用户 Play；G4 前关闭反馈，G6 仍需最后相关变更后的用户确认。
- 失败立即写 operation ledger；修复后追加 `Resolved + resolution + iterationAction + iterationEvidence`。
- G4/G6 只认标准 batch Runner；G5 只认当前输入指纹匹配的双端证据。
- 阶段完成后关闭本阶段启动的 Unity、Cocos、`kapai.exe`、本地数据库及 Computer Use 运行时。
