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

### 技能/词条功能分支本轮接续（2026-08-31）

- 用户明确要求“先跳过验收，继续下一步任务”；只暂缓人工点击、截图与战斗回放，不把缺失证据标记为通过，也不修改迁移门禁。
- S8 已实现首批 12 名神将 / 24 套 A/B 词条配装参考，配置与规则见 `docs/HERO_SKILL_AFFIX_IMPLEMENTATION_V1.md` 的 2.6 节。
- 双端已穿戴装备显示佩戴者的 A/B 匹配度，背包装备显示前三项推荐；评分为核心 100 / 兼容 60 / 不匹配 0，与战力、Tier、整套构筑分离。
- 非 GUI 回归：1,248 项评分、2,052 行 Lua/C# 一致性、5 项 Cocos 上下文单测；C# 离线 Roslyn 编译退出 0。日志位于 `.local/hero-build-s8-tests.log`、`.local/hero-build-s8-lua-parity.log` 和 `.local/hero-build-s8/`。
- 本轮没有开启游戏服务、数据库、Cocos 或 Unity；没有修改账号存档。本轮改动尚未提交/推送，继续保留 976 个既有 Unity `.meta` 改动；新增的三个 S8 资源 `.meta` 是本轮独立文件。
- 下一开发任务：按既有方案推进首批神将的可选技能分支与策略预设，先明确服务端持久化/切换协议与战斗注入合同。当前配装参考不会切换技能，不得当成分支已生效。
- 收口时当前任务记录约 116.7 MB，已超过用户规定的 20 MB 上限，停止在本任务追加开发；下一步请从新任务读取本交接继续。Codex `logs_2.sqlite` 约 218.1 MB，已提醒备份后单独检查，未修改或清理内部数据库。

### 迁移门禁（未因跳过人工验收而变更）

- Bag：G0-G5 已通过；G6 等待最后相关变更后的用户真实 Play 确认，`manualPassed=false`。
- EnhanceMaster：G0-G3 已通过；等待早期用户 Play，未进入 G4。
- HeroCultivation：G0-G2 已通过，G3 初版完成；等待用户按最终布局复测，未进入 G4。
- HeroEquip：仅 G0 通过；G1-G6 保持 pending，旧 33 控件和旧截图不可复用。
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
