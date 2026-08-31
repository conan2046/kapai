# Unity 迁移当前交接

> 实时完成率、当前批次和模块门禁唯一读取 [`UNITYCLIENT_STATUS.md`](UNITYCLIENT_STATUS.md)。
> 历史交接已归档到 `docs/unityclient/history/2026-07-to-2026-08-handoff-legacy.md`，不得用其中数字、路径、截图、SHA、账号或 Runner 结论替代当前证据。

## 当前批次

- Bag：仅G0保留；G1/G4/G5证据后仍有Cocos夹具与Bag运行时代码变化，当前输入指纹失败，G1-G6需串行重验。
- EnhanceMaster：G0-G3 已通过；等待早期用户 Play，未进入 G4。
- HeroCultivation：G0-G2 已通过，G3 初版完成；等待用户按最终布局复测，未进入 G4。
- HeroEquip：G0-G2通过；G3早期真人Play pending，旧G3-G6不可复用。
- 同一时间只推进用户当前指定的一个模块；上一门禁未通过不得进入下一门禁或下一模块。

## 当前工作树保护

- 当前已知用户改动：`server/config/config`。
- 当前未跟踪输入：`tmp/pdfs/ai-game-factory-article/` 下图片。
- 上述内容不属于本轮治理范围；不得 reset、checkout、stash、暂存或夹带提交。
- 每次继续前重新执行 Git 状态检查；本节只记录交接时观察，不作为未来数量基线。

## 下一步

1. 先读取 `UNITYCLIENT_STATUS.md`、`docs/unityclient/MIGRATION_GUIDE.md`、`docs/unityclient/modules/README.md`、目标模块文档/矩阵及 `migration-gates.json`。
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
