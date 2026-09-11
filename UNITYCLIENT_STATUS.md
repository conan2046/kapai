# UnityClient 当前状态

> 最后更新：2026-09-11。这里只维护实时状态、当前焦点、顺序和风险。
> 稳定流程见 `docs/unityclient/MIGRATION_GUIDE.md`；模块事实见 `docs/unityclient/modules/`；历史流水见 `docs/unityclient/history/`。

## 1. 当前焦点

| 项 | 当前值 |
|---|---|
| 唯一活动模块 | `Draw / 神将招募` |
| 当前门禁 | `G0-G5 retained / G6 runtime evidence pending` |
| 当前仅剩玩家缺陷 | 抽卡后碎片结果未完成真实可见验收；神将预览详情已由用户复测补齐 |
| 下一步 | 使用 `DuplicateFragment` SQLite 定向夹具，先断言重复神将条件，再完成真实高级单抽、权威回包、碎片 UI 和恢复检查 |
| 禁止事项 | 不开启其他模块；不以普通新神将单抽、JSON、内部回调、旧截图或批处理摘要证明碎片显示 |

## 2. 总进度

| 口径 | 当前值 | 说明 |
|---|---:|---|
| Static | `386 CSB 已审计` | 325 个同路径 CSD，61 个 CSB 兜底 IR |
| Functional | `待逐控件重审` | 旧页面/协议主链百分比已作废 |
| Strict Validated | `8/16 = 50.0%` | Login、Settings、PlayerHud、Bag、Task、World、Mail、XunBao |

GameplayShops、HeroCultivation 为用户明确授权的 G6 例外，不增加严格证据分子；BattleFengShenStory 为非分母战斗子模块。完成率不得在其他文档重复维护。
当前 Steam 业务模块分母固定为 16。

## 3. 模块状态

| 模块 | 当前状态 | 下一动作/边界 |
|---|---|---|
| Login | `G0-G6 complete` | 已收口 |
| Settings | `G0-G6 complete` | 已收口 |
| PlayerHud | `G0-G6 complete` | 用户最终确认，已收口 |
| Bag | `G0-G6 complete` | 用户最终确认，已收口 |
| Task | `G0-G6 complete` | 已收口 |
| World | `G0-G6 complete` | 32/32，已收口 |
| Mail | `G0-G6 complete` | 用户最终确认，已收口 |
| XunBao | `G0-G6 complete` | 21/21，用户最终确认，已收口 |
| EnhanceMaster | `G0-G6 complete` | 40/40，用户最终确认，已收口 |
| HeroRebirth | `G0-G6 complete` | 24/24，用户最终确认，已收口；用户 Prefab 只读 |
| HeroCultivation | `G0-G6 user exception` | 51/51；Cocos缺口和历史未闭环台账继续披露，不复用例外 |
| GameplayShops | `G0-G6 user exception` | 仅 `function_id=15/type=2`；其他商店不在范围 |
| Draw | `G0-G5 retained / G6 pending` | 只处理重复神将碎片可见问题；`manualPassed=false` |
| Hero | `G0 passed / G1-G6 invalidated` | 当前不启动；待有效 Cocos 状态重采 |
| HeroEquip | `G0-G4 passed / G5 blocked` | 当前不启动；用户 Prefab 不覆盖 |
| Shop | `G3 runtime-ready / early Play passed` | 正式 G1-G2、G4-G6 待后续独立任务 |
| Gameplay | `G0-G3 passed / early Play retest pending` | 当前不启动；Steam仅保留 `function_id=1/3/9/10` |
| FengShenStory | `G0-G3 passed / early Play retest pending` | 父模块待后续独立任务 |
| BattleFengShenStory | `G0-G6 complete` | 非分母战斗子模块，已收口 |
| YouLi | `G0 passed / G1-G6 evidence missing` | 后续从当前源码重取 G1 |
| ResourceFoundation | `R0-R4 passed / early Play passed` | YooAsset、Atlas、内存预算后置 |
| Steam SQLite/发布 | `S0-S7 passed / S8 local accepted` | 物理干净机与真实 Steam Depot 暂缓 |

`steam-excluded`：Friend、Chat、Team、Guild、Welfare、Activity、StaminaClaim、ResourceRecovery、Funds、SevenDay、KunLun、BloodFight、Arena。唯一范围表见 `docs/unityclient/STEAM_SCOPE.md`；历史实现和证据仅留档，禁止恢复迁移或计入分母。

## 4. 当前验证基线

| 范围 | 当前结论 | 证据入口 |
|---|---|---|
| Draw | SQLite恢复、重登、完整性和残留检查已通过；运行时回放仍不构成最终验收 | `docs/unityclient/modules/DRAW.md`、`docs/unityclient/matrices/DRAW_CONTROLS.json` |
| Draw 碎片定向条件 | `NewHero` 与 `DuplicateFragment` 夹具已分离；碎片测试必须使用后者 | `tools/unity-migration/Invoke-DrawSqliteFixture.ps1` |
| 最近严格完成模块 | XunBao 21/21、7/7双端状态、6/6语义、用户最终Play通过 | `docs/unityclient/modules/XUNBAO.md` |
| Steam本机发布 | Unity可独立双击运行；外部干净机/Depot不在当前阻塞口径 | 对应 S0-S8 本地证据与历史文档 |

## 5. 总迁移顺序

1. P0 基础层：已按现状冻结，不在 Draw 任务内重开。
2. P1 核心养成与单人功能：当前只收口 Draw；后续为 Hero → HeroEquip → Gameplay 模块组（Gameplay、FengShenStory、YouLi）。
3. P2 运营与商业化：进入任何保留模块 G0 前先完成 `docs/unityclient/modules/PAYMENT.md` 前置；当前不启动。
4. P3 竞技/玩家依赖：当前无新增保留模块。
5. P4 社交最后：Steam 排除项不再启动。
6. 任一新模块必须另开任务，从其最早有效门禁开始。

## 6. 已知风险

- 多代 UI、同名 Prefab 和旧 Lua 只能按当前入口闭包归属，不能按文件名判断。
- Unity 用户功能测试只能修改 `Application.persistentDataPath/LocalServer/projectx.db`；workspace MySQL 只用于 Cocos/离线兼容回归。
- JSON 只作证据索引；最终验收必须同时包含真实输入、玩家可见 UI、协议或 SQLite 权威状态和当前文件证据。
- 未水合 LFS、旧输入指纹、进程/端口残留及未解决 Ledger 记录会使对应门禁失效。

## 7. 维护规则

- 本文件只改当前焦点、状态、顺序和风险；不得追加日期流水或长篇验证过程。
- 模块结论写模块文档；控件事实写矩阵；机器门禁写 JSON；历史写 `history/`。
- 新任务默认只读取本文件的“当前焦点”和目标模块所在行，不重复加载已完成模块细节。
