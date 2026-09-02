# Unity 迁移当前交接

> 实时完成率、当前批次和模块门禁唯一读取 [`UNITYCLIENT_STATUS.md`](UNITYCLIENT_STATUS.md)。
> 历史交接已归档到 `docs/unityclient/history/2026-07-to-2026-08-handoff-legacy.md`，不得用其中数字、路径、截图、SHA、账号或 Runner 结论替代当前证据。

## 装备特殊词条 S7 收口（2026-08-30）

- 功能分支：`feature/hero-skill-affix-v1`；实现提交：`49893bf5201fa5b1baf5550b102953dd28dfce89`；未合并 `main`。
- 已完成服务端权威词条锁定与重铸（`/319 op=41/42`）、品质 6/7 金币消耗、词条种子与锁定状态持久化。
- Cocos 与 Unity 均已接入锁定/重铸按钮、权威回包刷新和 12 类神将流派推荐；战斗行动流已显示战意实际变化。
- 验收通过：48 词条/59 神将配置回归、双端 LuaJIT 编译、Unity 2022.3.62f3c1 全新批处理编译、服务端 Debug 构建与 SQLite 启动、29 项真实装备词条协议回放、3 项重启持久化回放。
- 本轮只提交 14 个功能文件；工作树中 976 个既有 Unity `.meta` 改动未暂存、未清理、未夹带。
- 下一任务应新开任务继续：优先做 Cocos/Unity 装备详情人工点击与截图验收，以及含战意增减的真实战斗回放；这些人工视觉证据不应由本轮自动化结果替代。

## 当前批次

### 技能/词条功能分支（2026-09-02 同步主干）

- 用户明确要求“先跳过验收，继续下一步任务”；只暂缓人工点击、截图与战斗回放，不把缺失证据标记为通过，也不修改迁移门禁。
- S8 已实现首批 12 名神将 / 24 套 A/B 词条配装参考，配置与规则见 `docs/HERO_SKILL_AFFIX_IMPLEMENTATION_V1.md` 的 2.6 节。
- 双端已穿戴装备显示佩戴者的 A/B 匹配度，背包装备显示前三项推荐；评分为核心 100 / 兼容 60 / 不匹配 0，与战力、Tier、整套构筑分离。
- 非 GUI 回归：1,248 项评分、2,052 行 Lua/C# 一致性、5 项 Cocos 上下文单测；C# 离线 Roslyn 编译退出 0。日志位于 `.local/hero-build-s8-tests.log`、`.local/hero-build-s8-lua-parity.log` 和 `.local/hero-build-s8/`。
- S8 已形成独立提交 `a3e62376`，随后将 `origin/main@77196b74` 合入功能分支；未把功能分支反向合并到 `main`。
- 本轮没有开启游戏服务、数据库、Cocos 或 Unity；没有修改账号存档。976 个既有 Unity `.meta` 改动继续保留且未暂存；新增的三个 S8 资源 `.meta` 已随 S8 正式提交。
- 下一开发任务：按既有方案推进首批神将的可选技能分支与策略预设，先明确服务端持久化/切换协议与战斗注入合同。当前配装参考不会切换技能，不得当成分支已生效。

### 迁移门禁（未因跳过人工验收而变更）

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
