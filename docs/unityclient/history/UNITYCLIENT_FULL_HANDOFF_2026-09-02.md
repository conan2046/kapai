# UnityClient 全项目接手总表（2026-09-02）

> 冻结基线：`main@9e51d4f7`。本文是一次性交接快照，不是第二份实时状态源。
> 后续进度必须更新根目录 `UNITYCLIENT_STATUS.md`；流程只认 `docs/unityclient/MIGRATION_GUIDE.md`；Steam 范围只认 `docs/unityclient/STEAM_SCOPE.md`。

## 1. 接手结论

- 当前 Steam 业务分母固定为 16，`UNITYCLIENT_STATUS.md` 顶部记录为 `Validated 6/16 = 37.5%`。
- 接手时必须以本表的“逐模块当前门禁”定位工作，不得把历史截图、旧 Runner、旧 G6、Manifest 文案或模块 README 当作当前完成证明。
- 已确认排除的 Steam 功能不得继续迁移；除非用户明确重新改变产品范围。
- 同一时间只推进一个模块，严格串行执行 G0 → G6。
- 所有 Unity Editor/Player 启动、关闭、端口 8711 清理、服务端生命周期由接手人自行处理，不再要求用户通知。
- 用户本轮明确要求跳过 Computer Use。涉及必须依赖当前 Cocos 原生动态取证的门禁保持 pending/blocked，不得用旧图、桌面截图、Unity 单端截图或元数据补过。
- 测试玩家数据只允许写 `Application.persistentDataPath/LocalServer/projectx.db`；MySQL 仅用于 Cocos/离线兼容对照，不得替代 Unity 用户测试数据。

## 2. 默认读取顺序

1. `AGENTS.md`
2. `UNITYCLIENT_STATUS.md`
3. `docs/unityclient/STEAM_SCOPE.md`
4. `docs/unityclient/MIGRATION_GUIDE.md`
5. `tools/unity-migration/unityclient-modules.json`
6. `tools/unity-migration/migration-gates.json`
7. `docs/unityclient/modules/README.md`
8. 当前目标模块文档、控件矩阵、场景和证据契约
9. 仅在追查旧决策/命令/错误时定点读取 `docs/unityclient/history/`

## 3. 16 个 Steam 业务模块总进度

| # | Manifest Key | 功能 | 当前可信门禁/状态 | 已完成边界 | 接手动作 |
|---:|---|---|---|---|---|
| 1 | `Login` | 登录与创角 | `G0-G6 passed / 21/21 complete` | 17/17 双端原生视觉、21/21 真控件、10/10 语义；已有/无角色、公告、失败/超时/重连/切号与精确恢复通过 | 仅做共享基础回归；正式登录服、渠道 SDK、发布配置后置 |
| 2 | `Settings` | 系统设置 | `G0-G6 passed / 21/21 complete` | 8/8 双端视觉、21/21 真控件、10/10 语义；音量、开关、损坏回退、持久化及切号隔离通过 | 仅在共享设置/音频输入变化后重验 |
| 3 | `Bag` | 背包 | `G0-G6 passed / 26/26 complete` | 当前 SQLite 身份 `1/1000001`；26 控件、18 语义、16 态 G5、礼包横向拖动、精确恢复和用户最终确认通过 | 已收口；相关公共背包/奖励组件变化后撤销受影响门禁 |
| 4 | `Task` | 任务 | `G0-G6 passed / 14/14 complete` | 11 个关键视觉状态、14 真控件、每日任务、四档宝箱、奖励、异常、持久化和切号通过 | 已收口；作为新模块硬门禁样板 |
| 5 | `World` | 世界/战斗/副本 | `G0-G6 passed / 32/32 complete` | World V0 范围完成；四个底部入口、成就 `/320 op=11/12`、宝箱、战斗、重登、SQLite 恢复与用户最终确认通过 | 已收口；星数排行保持隐藏 |
| 6 | `PlayerHud` | 主界面 HUD | `G0-G3 retained / G4-G6 invalidated` | `/18` 货币映射修复；多个公共货币栏实时刷新 | 当前源码已改变旧 G4-G6 输入；先真人复测，再走标准 batch、G5、G6 |
| 7 | `Hero` | 神将/阵容 | `G0 passed / G1-G6 pending` | 换将、位置切换、阵法页签/学习、权威刷新及弹窗生命周期已修；Unity 诊断批验曾通过 16/16 控件、6/6 语义和精确恢复 | 当前 Cocos 16 态中 13 态像素重复，G1 无效；Computer Use 被要求跳过，因此保持阻塞。专项交接见 `HERO_HANDOFF_2026-09-02.md` |
| 8 | `HeroEquip` | 装备/法宝 | `G0-G2 passed / G3-G6 pending` | 方案 A 冻结 14 来源、974 业务 ID、86 控件；历史 33 控件/G4-G6 仅作诊断 | 完成 G3 当前实现与早期真实 Play，再进 G4；不得复用历史 G4-G6 |
| 9 | `Mail` | 邮件 | `G0-G2 passed / G3-G6 pending` | 旧 4/4 双端视觉、13/13 控件及 `/128 op2/3/4/5` 可作实现线索 | 从当前源码重跑 G3-G6；模块 README 中旧 complete 文案不得覆盖根状态 |
| 10 | `Shop` | 基础商城 | `G0 passed / runtime-ready / early Play passed / G1-G6 pending` | `type=1` 当前入口、`/221`、真实关闭、数量输入、射线修复完成；用户早测通过 | 正式补 G1-G2；再登记/执行 G3-G6。免截图决定不等于视觉通过 |
| 11 | `GameplayShops` | 将魂商店 | `G0-G4 passed / G5-G6 pending` | 当前仅 `function_id=15/type=2`；29/29 控件、9/9 语义、用户早测和 SQLite 精确恢复通过 | 补 5 个状态 G5 双端视觉与 G6 最终收口；其他玩法商店分支继续暂缓 |
| 12 | `Draw` | 神将招募 | `G0-G5 retained / G6 pending` | G5 主状态与差异报告仍在 | 当前矩阵登记的 28 组 Cocos + 28 组 Unity 逐控件图片缺失；找回或真实重采后才能跑 G6 |
| 13 | `Gameplay` | 玩法大厅 | 文档记录 `G0-G4 passed / G5-G6 pending`；机器门禁仍为 `G0-G3 passed / G4 pending` | 用户早测、13/13 控件、13/13 语义、SQLite 精确恢复和双后端身份映射已完成 | 先同步状态源冲突；Arena 已确认排除，不能继续以“等待 Arena”作为 G5 前提，应重新冻结当前 4 个 Steam 入口后再决定 G5 |
| 14 | `FengShenStory` | 封神列传 | `G0-G3 passed / G4-G6 pending` | 当前 Cocos 关卡/奖励/获取途径证据、复合奖励格、公共货币栏、挑战与布阵关闭修复完成 | 先做 5–15 分钟早期真人复测并闭环，再进入 G4；不得切换到 XunBao |
| 15 | `XunBao` | 法宝搜索 | `G0 passed / G1-G6 pending` | 已修 0 次拦截、搜宝令边界、`op28/29` 奖励、碎片刷新与合成前置 | 用户复测次数不足/补次数/真实搜索/碎片刷新；当前证据目录缺失，从 G1 串行重验 |
| 16 | `YouLi` | 游历三界 | `G0 passed / G1-G6 pending` | `/335 op1/2/3` 实现保留 | 当前 Cocos/Unity 空态和差异目录缺失；从 G1 重取，写操作以 `op1` 权威重查为准 |

### 完成率口径警告

`UNITYCLIENT_STATUS.md` 顶部仍写 `6/16`，但逐模块行已将 `PlayerHud` 降为 G0-G3。接手人不得自行猜测第 6 个完成模块；应先通过当前 Gate/Manifest/证据复核完成率并同步唯一状态源。完成率修正必须同时通过文档门禁，不能只改数字。

## 4. 非 16 分母的基础能力与子模块

| Key/范围 | 当前状态 | 后续 |
|---|---|---|
| 运行时/网络/xLua | 第一阶段完成 | 回放、完整错误码与发布配置仍后置；不能等价于迁移完成 |
| UI 通用层 | 第一阶段完成 | VirtualList、MessageBox、Loading、Toast、Reward 已有；通用 Tab、分页、红点树继续深化 |
| 迁移工具链 | 第三阶段完成 | 固定账号、数据预检/恢复、控件矩阵、语义断言、G5 哈希、重复截图硬门禁已接入；继续扩展中央工具而非创建平行脚本 |
| `ResourceFoundation` | `R0-R4 passed / early user Play passed` | `97952ddd` 已收口；Bootstrap 输入已变化，后续业务模块必须按当前输入重验。YooAsset 后端、Atlas、内存预算后置 |
| Steam SQLite/发布 | `S0-S7 passed / S8 local accepted / external deferred` | Unity 双击运行、监管 `kapai.exe + SQLite`、中文只读路径、备份/日志/退出通过；真实 Steam Depot 与物理干净机升级暂缓 |
| `HeroCultivation` | `G0-G2 passed / G3 implementation ready / early Play pending` | 51 控件、18 个 Cocos 状态；等待按用户最终 Prefab 布局早测，再进入 G4 |
| `EnhanceMaster` | `G0-G3 passed / early Play pending / G4-G6 pending` | 40 控件、14 个 Cocos 状态、13 个 Unity 状态；固定账号 `1/1000001` 已有红装/法宝/材料 |
| `BattleFengShenStory` | `G0-G6 passed / 9/9 complete` | 自然结算、主动跳过、方向、重登、精确恢复与共享战斗回归通过；作为非分母战斗子模块保持收口 |
| `BattleMeetMonster` | V0 边界 E，待动态确认 | `EFTLieZhuanFight=19` 保留；没有新动态证据前不得升为完成 |

## 5. Steam 明确排除项

以下 14 个 Manifest Key 不进入迁移门禁、不计入 16 模块分母、不得补 UI/协议/Prefab/截图：

| Key | 范围 | 处理 |
|---|---|---|
| `Friend` | 好友、好友赠送 | 隐藏入口，保留 Cocos/服务端 |
| `Chat` | 聊天、HUD 聊天条 | 隐藏入口 |
| `Team` | 队伍 | 隐藏入口 |
| `Guild` | 帮派/宗门 | 隐藏入口 |
| `Welfare` | 福利、在线奖励 | 隐藏入口 |
| `Activity` | 活动、首充、充值、折扣礼包 | 整体排除，`/222` 不得恢复入口 |
| `Arena` | 竞技场 | 用户确认当前版本屏蔽；不迁移、不验收 |
| `KunLun` | 决战昆仑 | 排除匹配对手及 `/213 op=25` 红点 |
| `BloodFight` | 血战到底 | 排除全服排行玩法 |
| `SevenDay` | 七日目标 | HUD/玩法入口与 Runner 关闭 |
| `StaminaClaim` | 体力领取 | 随福利整体排除 |
| `ResourceRecovery` | 资源找回 | 玩法入口隐藏 |
| `Funds` | 成长/活跃/全部基金 | 不迁移购买/领取 |
| `BattleScript` | 师门、心魔、藏宝图旧脚本战斗 | 用户确认不需要 |

`47–53` 战斗枚举属于当前产品禁用范围；旧代码、资源或历史截图不能重新开启。

## 6. 当前最优接手顺序

1. **先校准状态源**：只修复明确冲突，不改变实际门禁。重点核对 `PlayerHud`、`Mail`、`Gameplay`、`World` 在 `UNITYCLIENT_STATUS.md`、`migration-gates.json`、Manifest、模块 README 中的差异。
2. **完成无需新 Cocos 动态取证的早测闭环**：`FengShenStory` → `HeroCultivation` → `EnhanceMaster` → `HeroEquip`。
3. **完成高门禁模块**：`GameplayShops` G5-G6、`Draw` G6 证据恢复。
4. **恢复新鲜 Cocos 证据后推进**：`Hero`、`XunBao`、`YouLi`、`Shop`。当前跳过 Computer Use 决定未改变前，不得伪造 G1。
5. **最后复核共享层**：`PlayerHud` G4-G6 与所有受 ResourceFoundation/Bootstrap 输入变化影响的模块。
6. **不要启动**：所有 `steam-excluded` 模块、支付/充值/VIP、竞技场、47–53 战斗。

## 7. 每个模块的执行合同

- G0：当前入口、Lua、协议、配置、资源、全业务 ID、全控件与验收样例冻结。
- G1：当前 Cocos 原生窗口真实入口取证；冻结同账号/同数据/同步骤/同分辨率基线 SHA。
- G2：完成入口闭包、共享协议所有权、配置到资源、运行时 Transform 和生命周期审计。
- G3：真实 Prefab + Lua 权威模型 + C# 渲染桥；完成 DataPreflight、编译/Console、自检并邀请早期 Play。
- G4：只接受标准 batch Runner 的真实 EventSystem、权威事务、异常、重连、切号和精确恢复证据。
- G5：复用有效 G1 Cocos 原图，重取 Unity 稳定帧，生成并排、50% 叠加、增强差异和报告。
- G6：真实入口回归、全部控件、异常扫描、Bootstrap 幂等、文档/Git/残留检查；最后一次相关变更后必须由用户最终确认。

禁止用 `onClick.Invoke()`、Presenter/内部完成方法、伪造 `realEntryClick=true`、旧 Runner、错误历史截图或 Unity 单端截图代替真实门禁。

## 8. 固定身份与数据边界

| 用途 | userId / roleId | 数据后端 |
|---|---|---|
| 当前 Unity 迁移主身份 | `7200057 / 1000003` | `%USERPROFILE%\AppData\LocalLow\Xuancai\ProjectX\LocalServer\projectx.db` |
| 当前 Cocos 对照主身份 | `7200057 / 1000115` | workspace-local MySQL，仅 Cocos/兼容对照 |
| Bag 当前收口身份 | `1 / 1000001` | Unity persistentDataPath SQLite |
| EnhanceMaster 数据身份 | `1 / 1000001` | Unity persistentDataPath SQLite |

- 变更型场景先执行 `-DataPreflightOnly`，再启动完整 Unity 验收。
- 必须保存整库快照、恢复、重登录回读和 Fixture 残留 0 证据。
- 同一个隔离角色禁止并发 Runner。
- 不得将 workspace MySQL 数据复制成 Unity 验收结论。

## 9. 新成员首次环境准备

```powershell
git lfs install
git lfs pull
pwsh -ExecutionPolicy Bypass -File tools/local/Install-LocalDeps.ps1 -IncludeMySql -IncludeBoost
pwsh -ExecutionPolicy Bypass -File tools/local/Check-LocalEnv.ps1 -SkipClient
pwsh -ExecutionPolicy Bypass -File tools/local/Build-Server.ps1
```

Unity 版本固定：`2022.3.62f3c1`；工程目录：`unityclient/`。

Unity Editor 直接 Play 会自动检查/构建并监管 `kapai.exe + SQLite`。停止 Play 时应自动保存和回收服务端。批处理验收不会隐式启动外部服务；需要外部服务时使用标准工具参数，不手工长期常驻。

正式 Windows 包：

```text
Tools → ProjectX App → Build Steam Windows Package
```

默认输出：`.local/steam-build/ProjectX/ProjectX.exe`。验收只双击完整输出目录中的 `ProjectX.exe`，不要单独复制 EXE。

## 10. 高频命令

```powershell
# 文档与中央工具回归
pwsh -NoProfile -File tools/unity-migration/Test-UnityMigrationToolchain.ps1
pwsh -NoProfile -File tools/unity-migration/Test-UnityMigrationDocs.ps1

# 当前模块标准验收
pwsh -NoProfile -File tools/unity-migration/Run-UnityModuleValidation.ps1 -Module <Module>

# 固定账号验收；具体参数先读目标模块文档与 validation-scenarios.json
pwsh -NoProfile -File tools/unity-migration/Run-UnityFixedAccountValidation.ps1 -Module <Module> -DataPreflightOnly
pwsh -NoProfile -File tools/unity-migration/Run-UnityFixedAccountValidation.ps1 -Module <Module>

# G5 输入检查
pwsh -NoProfile -File tools/unity-migration/Test-UnityModuleG5Preflight.ps1 -Module <Module> -RequireInputs

# 本地环境与服务端
pwsh -ExecutionPolicy Bypass -File tools/local/Check-LocalEnv.ps1
pwsh -ExecutionPolicy Bypass -File tools/local/Build-Server.ps1
pwsh -ExecutionPolicy Bypass -File tools/local/Start-Server.ps1

# Git；本机普通 git 可能不在 PATH
& 'C:\Program Files\Git\cmd\git.exe' status --short
```

命令报错、超时、窗口错误、页面不符或证据不合格时，立即写入 `.local/unity-validation/<module>-operation-ledger.json`。查明后追加 `Resolved` 和已存在的文件证据，禁止删除失败记录。

## 11. 已知状态源冲突

| 范围 | 冲突 | 接手规则 |
|---|---|---|
| 总完成率 | 顶部为 `6/16`，逐模块当前完成态仅能直接确认 Login、Settings、Bag、Task、World 五项 | 先审计，不猜第六项；修正后只更新 `UNITYCLIENT_STATUS.md` 的实时百分比 |
| `PlayerHud` | 根状态为 G0-G3；Manifest/机器 Gate 仍显示 G6 | 以根状态降级为准，重新验证受当前输入影响的 G4-G6 |
| `Mail` | 根状态与 Gate 为 G0-G2；模块 README 仍写 complete | README 视为旧文案，禁止直接恢复 G3-G6 |
| `Gameplay` | 根状态写 G0-G4；机器 Gate 仍为 G0-G3，且旧后续仍提“等待 Arena” | Arena 已排除；先对齐门禁和 4 个 Steam 入口范围，再进入 G5 |
| `World` | 根状态为 G0-G6；模块 README 仍写 World 自身停在 G3 | 以根状态和当前 Gate 的 G6 证据为准，修正文档索引 |
| `Hero` | Gate 的 note 仍残留“current-worktree G0-G4 passed”，但 Gate 字段和根状态均为 G0 only | 只认 Gate 字段；必须修掉误导 note，G1-G6 保持 pending |

状态同步不得通过直接改 JSON 绿灯完成；必须先验证证据和输入指纹，再用现有门禁工具更新。

## 12. 当前 Git 与交付基线

| 提交 | 内容 |
|---|---|
| `9e51d4f7` | Hero 阵法/换将/生命周期修复、Cocos 重复截图硬门禁、总状态更新、Hero 专项交接 |
| `97952ddd` | ResourceFoundation 完整资源基础与早测收口 |
| `7422cbd8` | World/装备等用户调整布局保留 |
| `cc016730` | Hero 技能与装备词缀 V1 合并基线 |

接手前执行：

```powershell
& 'C:\Program Files\Git\cmd\git.exe' fetch origin --prune
& 'C:\Program Files\Git\cmd\git.exe' status --short --branch
& 'C:\Program Files\Git\cmd\git.exe' log --oneline --decorate -8
```

不得覆盖未提交 Prefab/Lua/资源/配置；每次只按目标模块显式暂存。只有用户明确要求才提交或推送。

## 13. 本次冻结验证

- `Test-UnityMigrationToolchain.ps1`：`309 passed`
- `Test-UnityMigrationDocs.ps1`：`34 modules passed`
- `main` 已推送至 `origin/main@9e51d4f7`
- Unity、Unity Hub、Cocos、`kapai.exe`、workspace MySQL 均已关闭
- 端口 `8711` 无监听

## 14. 下一位负责人的第一步

先不要启动 Unity。先以只读方式完成第 11 节状态冲突审计，修复机器状态与文档索引中明确的陈旧文案并运行 309/34 回归。随后只选择一个未完成模块进入门禁；建议优先完成 `FengShenStory` 的当前 G3 早测闭环。若用户继续要求跳过 Computer Use，则不要选择 `Hero`、`XunBao`、`YouLi` 或其他缺当前 Cocos G1 的模块。
