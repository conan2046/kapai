# UnityClient 当前状态

> 最后更新：2026-09-21。这里只维护实时状态、当前焦点、顺序和风险。
> 稳定流程见 `docs/unityclient/MIGRATION_GUIDE.md`；模块事实见 `docs/unityclient/modules/`；历史流水见 `docs/unityclient/history/`。

## 1. 当前焦点

| 项 | 当前值 |
|---|---|
| 唯一活动范围 | `World` 三类战斗公共状态隔离 |
| 当前门禁 | `FengShenStory、MoneyTree、HappyWheel、闯关（Monopoly/大富翁）功能验收通过；World 三类战斗公共状态隔离用户 Play 通过` |
| 当前阻塞 | `无；Unity SQLite 单机真实回放、结算、返回和交错链路已复测` |
| 下一步 | `本任务收口；保留未提交工作区，后续如需发布再单独做范围审查和提交` |
| 禁止事项 | 后续调整必须以用户维护的 `FishLayer.prefab` 为基础；未经用户明确许可不操作 Unity |

## 2. 总进度

| 口径 | 当前值 | 说明 |
|---|---:|---|
| Static | `386 CSB 已审计` | 325 个同路径 CSD，61 个 CSB 兜底 IR |
| Functional | `待逐控件重审` | 旧页面/协议主链百分比已作废 |
| Strict Validated | `8/19 = 42.1%` | Login、Settings、PlayerHud、Bag、Task、World、Mail、XunBao |

GameplayShops、HeroCultivation 为用户明确授权的 G6 例外，不增加严格证据分子；BattleFengShenStory 为非分母战斗子模块。完成率不得在其他文档重复维护。
当前 Steam 业务模块分母固定为 19（2026-09-14 用户确认钓鱼纳入范围，由 18 调整为 19）。

## 3. 模块状态

| 模块 | 当前状态 | 下一动作/边界 |
|---|---|---|
| Login | `G0-G6 complete` | 已收口 |
| Settings | `G0-G6 complete` | 已收口 |
| PlayerHud | `G0-G6 complete` | 用户最终确认，已收口 |
| Bag | `G0-G6 complete` | 用户最终确认，已收口 |
| Task | `G0-G6 complete` | 已收口 |
| World | `G0-G6 complete / 公共状态隔离用户 Play 通过` | 32/32 历史门禁已收口；用户真实验证 FightType=16/19/21 交错回放、结算/跳过、返回地图、普通副本自动续战和退出/重进；Unity Console 无业务错误 |
| Mail | `G0-G6 complete` | 用户最终确认，已收口 |
| XunBao | `G0-G6 complete` | 21/21，用户最终确认，已收口 |
| EnhanceMaster | `G0-G6 complete` | 40/40，用户最终确认，已收口 |
| HeroRebirth | `G0-G6 complete` | 24/24，用户最终确认，已收口；用户 Prefab 只读 |
| HeroCultivation | `G0-G6 user exception` | 51/51；Cocos缺口和历史未闭环台账继续披露，不复用例外 |
| GameplayShops | `G0-G6 user exception` | 仅 `function_id=15/type=2`；其他商店不在范围 |
| Draw | `G0-G5 passed / targeted bug user Play passed / G6 evidence pending` | 2026-09-11 用户最终真人 Play 确认定向修复通过；`manualPassed=true`，但 runtime-v4 严格控件证据仍有缺口，中央G6保持pending |
| Hero | `G0 passed / G1-G6 invalidated` | 当前不启动；待有效 Cocos 状态重采 |
| HeroEquip | `G0-G4 passed / G5 blocked` | 当前不启动；用户 Prefab 不覆盖 |
| Shop | `G3 runtime-ready / early Play passed` | 正式 G1-G2、G4-G6 待后续独立任务 |
| Gameplay | `G4 passed / G5 blocked / G6 pending` | Arena `id=6` 已排除；真实 ScrollRect 滚动、用户 Play、重连与账号隔离均已通过；G5 等待 Cocos 跨后端映射 |
| Answer | `implemented / Chinese question bank installed / user Play passed` | 38道中文题已更新至SQLite/MySQL；固定品质框+金币图标+默认1000已验收，Cocos逻辑不改，manualPassed=true；中央G1-G6待补证据 |
| Fish | `G3 passed / user Play accepted` | Unity 单机实现与固定账号 9/9 真实点击回归已通过；Cocos 仅作源码基线且不声称运行截图；用户已在最后一次统一顶部层级与 Prefab `FishScene/pos` 挂点调整后实际测试通过，包含早收网结算逻辑，`manualPassed=true`；G4-G6 待后续重新开启 |
| MoneyTree | `功能验收通过` | 用户已多次真实 Play；查询、摇取、消耗与结果刷新无业务问题；本轮 MCP 截图插件报错不计为功能错误 |
| HappyWheel | `功能验收通过` | 已修复多次抽取后的累计角度偏移；用户连续三次真实 Play确认最终高亮与指针同格，奖励与日志正常 |
| JingJie | `G0 passed / G1 blocked / Unity user Play passed` | `/306 op=1/4`、20阶配置、Prefab、预览和突破动画已接入；2026-09-13 用户测试通过，待当前Cocos原生基线 |
| Monopoly | `闯关功能验收通过` | 2026-09-21 用户完成真实闯关战斗链路测试；地图、随机移动、守卫战 `/38` 回放、FightType=21 回放结束与返回刷新通过；正式 G5/G6 证据仍不虚报 |
| FengShenStory | `功能验收通过` | 2026-09-21真实 Play：货币栏、首通奖励、挑战结算、体力/货币扣增、关卡推进均正常；Console 0错误/警告；不再按迁移G4-G6阻塞 |
| BattleFengShenStory | `G0-G6 complete` | 非分母战斗子模块，已收口 |
| YouLi | `G0 passed / G1-G6 evidence missing` | 后续从当前源码重取 G1 |
| ResourceFoundation | `R0-R4 passed / early Play passed` | YooAsset、Atlas、内存预算后置 |
| Steam SQLite/发布 | `S0-S7 passed / S8 local accepted` | 物理干净机与真实 Steam Depot 暂缓 |

`steam-excluded`：Friend、Chat、Team、Guild主体、Welfare、Activity主体、StaminaClaim、ResourceRecovery、Funds、SevenDay、KunLun、BloodFight、Arena。用户于2026-09-12从Guild/Activity边界单独恢复 `MoneyTree/HappyWheel/Monopoly` 三个单人玩法；帮派种植与神树继续暂停。唯一范围表见 `docs/unityclient/STEAM_SCOPE.md`。

`Fish G0`：2026-09-14 已通过，冻结固定账号 `7200057/1000003`、9个控件、5类来源与50个业务ID。用户确认采用场景54/map33假传送，角色固定在1号区域黑圈位置 `(1086,619)`、`dir=2`、`flip=true`，传入后立即将正常角色模型切为原版 `ShapeId=2000` 钓鱼造型；此时业务态仍为Ready，不扣费、不倒计时，点击开始后才进入权威Fishing；收竿回持竿待机，退出模块恢复正常角色模型。`function_id=32` 10级开放、每日不限次、无扣次、每次成功放竿扣100金币（配置可调）、每轮独立随机10–20秒；鱼篓容量9999格，同种鱼优先补已有未满格，单格上限999，满栈后新增同鱼种格，每格右下角显示数量；10只是当前鱼种数，不是固定格数。9999格均占用且本轮鱼种不存在未满同种格时，新获得的鱼直接舍弃，不改动原鱼格。首版10种鱼走 `fish_reward` 权重配置；后续消耗用途暂不处理。旧主角经验与 `EEHDT_Fish` 限时兑换材料掉落整链删除。正式 Excel→JSON/SQLite 镜像、map33、原版 `btm2000_zd` 与 Unity 40帧/5动作动画、7张新鱼 RGBA 图标及可逆 SQLite 夹具均已落地；整库精确恢复、重登业务哈希、完整性与残留0通过。G1 因原版限时/房间/传送条件及 Computer Use 无原生窗口，由用户明确授权改为源码基线例外：忽略 Cocos 客户端全部表现，直接进入 Unity 实现，最终只做 Cocos 代码语义与 Unity 代码/实际表现对照。

`Fish G3`：2026-09-14 固定账号真实点击玩法入口、`Function_32/EnterBtn`、帮助、鱼篓开关、开始、鱼格领取、收杆与退出；验证 Ready 金币1000不扣费，开始后1000→900，首轮10–20秒产鱼并自动续钓至800，领取整格后第二轮产鱼并续钓至700，最终保留1条鱼、停止并退出。三张1334×750截图、运行结果、SQLite恢复、重登玩家业务哈希与残留0均通过。2026-09-15 正式 UI 收敛为 `DynamicUi_OneLevelLayer` 页面容器并隐藏 `Bg/GoldCheck/shop_bg`，地图场景与定位点改由用户维护的 `FishLayer.prefab/FishScene/pos` 提供；用户在最后一次变更后实际测试确认无误，`manualPassed=true`。本阶段停在 G3，G4-G6 未执行。

## 4. 当前验证基线

| 范围 | 当前结论 | 证据入口 |
|---|---|---|
| Draw | 用户真人输入复现直接碎片图标缺失；源码修复后，正式229条奖池映射全量通过，账号1无注入随机实抽的回包/业务变化/UI一致，SQLite恢复、重登、完整性与残留通过；2026-09-11 用户最终真人 Play 确认通过 | `docs/unityclient/modules/DRAW.md`、`docs/unityclient/matrices/DRAW_CONTROLS.json` |
| Draw 碎片定向条件 | 必须分别覆盖直接碎片道具（`reward.Type<60000`）和重复神将转换（`type=60002 + transformItemId>0`）；`DuplicateFragment` 只保证后一条高级首次抽取前置 | `tools/unity-migration/Invoke-DrawSqliteFixture.ps1` |
| 最近严格完成模块 | XunBao 21/21、7/7双端状态、6/6语义、用户最终Play通过 | `docs/unityclient/modules/XUNBAO.md` |
| Steam本机发布 | Unity可独立双击运行；外部干净机/Depot不在当前阻塞口径 | 对应 S0-S8 本地证据与历史文档 |

### World 公共战斗状态隔离：下一步验收内容

| 场景 | 必须验证 | 通过条件 |
|---|---|---|
| FightType=16 → FightType=21 | 普通副本自动挑战后台继续时进入闯关并触发守卫战 | 通过：replay store、Presenter、回放协程互不覆盖；`/38` 按权威 FightType=21 路由，副本自动链路继续 |
| FightType=21 结算返回 | 闯关回放结束、结算回调、返回地图 | 通过：闯关 pending、地图位置、奖励、守卫格和刷新结果未串入公共 World 状态 |
| FightType=16 连战 | 普通副本手动/自动/连战连续两场 | 通过：chainIndex、chainNextNodeId、自动续战未被闯关回放清空；后续请求仍为 FightType=16 |
| FightType=19 自然结算 | 封神列传回放完成后等待 `/10` 结算 | 通过：stars、rewardPush、结算等待归 FengShenStory，普通副本/闯关状态不改变 |
| FightType=19 跳过 | 封神列传点击跳过并返回地图 | 通过：仅封神跳过抑制生效，无错误结算；下一场 SkipRequested 重新初始化 |
| 退出/重进恢复 | 在任一战斗回放期间离开页面再返回 | 通过：无旧战场覆盖、旧奖励弹窗覆盖或公共协程残留；Unity Console 0 error |

验收证据要求：真实 EventSystem/raycast 输入、玩家可见回放/结算、协议或 Unity SQLite 权威结果、当前源码与 MCP Console/状态记录必须同时具备；未启动本地服务端时只记脚本/编辑器测试通过，不记真实战斗链路通过。

## 5. 总迁移顺序

1. P0 基础层：已按现状冻结，不在 Draw 任务内重开。
2. P1 核心养成与单人功能：Draw 已收口；后续模块须在新任务中按当前状态重新选择，不在本任务启动。
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

## 8. 延后待办

- `ProjectXApp.cs` 大文件拆分优化：待当前 Bug 修复阶段稳定后单独执行；优先按现有 partial/业务域继续拆分，禁止与功能修复混提或改变运行逻辑。
- 新任务默认只读取本文件的“当前焦点”和目标模块所在行，不重复加载已完成模块细节。
