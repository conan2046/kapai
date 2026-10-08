# UnityClient 当前状态

> 最后更新：2026-10-08。这里只维护实时状态、当前焦点、顺序和风险。
> 稳定流程见 `docs/unityclient/MIGRATION_GUIDE.md`；模块事实见 `docs/unityclient/modules/`；历史流水见 `docs/unityclient/history/`。

## 1. 当前焦点

> 2026-10-08 Assets 根目录续记：用户移除 ProjectX 父目录后，硬编码路径、构建场景、原生资源维护配置和工具已同步到 Assets 下8个目录；GUID/运行资源键/程序集名称保留。20057文件完整，398 Prefab、137 UI生命周期、3910资源加载通过，481工具链/27单测通过，Console error0。当前 Editor 为 Assets/Scenes/Bootstrap.unity、非Play。冻结门禁原字节保留，业务画面未验。详见 .local/unity-validation/assets-root-20261008/report.md；下方含ProjectX父目录的资料均为旧布局历史。

> 2026-10-08 场景整理续记：Assets 仅保留 ProjectX/Scenes 下 Bootstrap（正式入口）和 FirstPlayableLoop（验证使用）。SampleScene、URP2DSceneTemplate、UIMigrationPreview 及 URP 场景模板整体移至工程外历史目录，原字节/.meta/GUID 保留；当前 Editor 为 Bootstrap、非 Play。编译后 Console error=0，最终工具链480项通过；业务验收未完成。证据：.local/unity-validation/scene-retirement-20261008/report.md。

> 2026-10-08 源码退役续记：5 个旧 Cocos 类、旧 UI 导入器/清理器与 ProjectX.UI.Migration 程序集已移出 Unity Assets，Core/UI/Validation/Editor 的 4 处引用已移除。验证工具仅使用 Unity 层级与 Animator；编译/Console 无错误，398 Prefab、137 UI 加载/释放、3910 资源重载及 479/27 检查通过。业务 Play/画面仍待验，不重算冻结门禁。证据：.local/unity-validation/cocos-source-retirement-20261008/report.md。

> 2026-10-08 最新原生资源收口：P-0198–P-0208后全部398个ProjectX Prefab的Identity/旧Timeline/Imod/缺失脚本/旧资源递归依赖均0；137个Unity Catalog条目加载/释放/清场通过。旧View/Provider/Loader、Imod运行库与源资源已退役；维护模式unity-native-only，活动UI/Timeline导入行0/0。27项资源测试、478项工具链检查、110次动画采样对比通过。下方旧数量和“Provider仍未退场”是历史快照；资产原生化余量0，业务Play/画面仍待用户验收，屏蔽功能未开放。详见W8处理单P-0198–P-0208。

> 2026-10-08 当前续记：P-0189–P-0197已将游历、大厅/共享框架、摇钱树、转盘、神将重生/图鉴/培养及共享数量输入共27个Prefab维护源切Unity，旧Prefab/JSON/meta归档；MCP397 Prefab/295 Identity/8旧Timeline Prefab、122轨道，活动清单264/0。编译/Console0/0、24单测、476工具链项通过。MCP临时DLL锁冲突已用项目内嵌固定版包与有限共享读取重试修复。所有新增业务Play/最终画面仍待验，Provider/Importer及剩余开放功能尚未全退场；详见W8处理单P-0189–P-0197。

> 2026-10-08 最新续记：P-0187 的 Monopoly 页面与动态资源链、P-0188 的终点共享奖励弹窗及封神列传奖励消费者已切 Unity。下方“页面 Provider 尚未完成”及326 Identity/295 UI行是P-0186旧快照。当前MCP复核397 Prefab/322 Identity/8 Timeline Prefab、122轨道/活动清单291/0；Console 0/0，单测24/24、工具链476/476。用户已授权代理自行通过MCP继续资源与代码操作。Function 21及共享奖励最新变更后的实际路线/用户画面待验，未计整体完成；证据及HANDOFF见W8处理单P-0188。

| 项 | 当前值 |
|---|---|
| 唯一活动范围 | `E:\neiwang_kapai\Game` 的 Unity Framework W8（`codex/framework-w8-e-main`） |
| 当前门禁 | W7.1–W7.5、W9.1–W9.6 已完成。Login/Startup 五个入口 Prefab 与 Unity-owned Main HUD Prefab 已移除 `UiPrefabIdentity`；FirstPlayableLoopBridge 的 Login/背景视图现使用 `UnityUiView`；每日答题 `AnswerLayer` 已移除 `UiPrefabIdentity` 并改为 Unity Transform 路径绑定（P-0157）。Hero 列表/详情/神将背包核心页已改用 Unity Catalog、Prefab 与 Transform 路径（P-0180）；Hero/FengShenStory 来源弹窗已共用 Unity `BagItemSource`，旧 `huoqutujing` 导入项已归档（P-0181）。Notice 已改为序列化 Unity 组件绑定。Main 云层及 Main HUD 的 Catalog/Prefab/视觉资源链已指向 Unity-owned 资源；Main HUD 路由使用 Unity `UiPrefabKey` 与 Transform，Cocos importer 的 Main 专用回写侧门已移除 |
| 当前阻塞 | 原生资产和资源目录技术整理已完成；实际业务 Play/最终画面仍待验收。整理前境界页 Image_bg 的 Sprite 已为空，保持原状态，不计为本轮新增缺失。 |
| 下一步 | 按现有业务入口定向复测本轮资源重绑与原生加载链；不重算冻结的 G0-G6，不开放屏蔽功能。 |
| 当前 Cocos 解耦切片 | 398 个 Prefab 已使用 Unity 原生维护源；美术/字体/音频归 Art，动画归 Animations，预制体及 UI Catalog 归 Prefabs。Resources 仅保留 AssetReferences/Lua/ProjectXData；3818 个轻量键覆盖3910个有类型资源。137 UI条目加载/释放、3910资源加载、398布局对比和27/478工具检查通过；资源副本减少392份/182.37 MiB。旧 Unity res 与20张截图已移出Assets并归档。证据：.local/unity-validation/resource-layout-20261008/report.md；业务Play未运行。 |
| 禁止事项 | W8 固定 E 盘工程；已验页面不重复跑；装备信息与商城按用户要求跳过；本轮跳过七日目标、基金、资源找回、福利/在线奖励、体力领取、好友、聊天、队伍、帮派主体、运营活动/首充/充值/折扣礼包、决战昆仑、血战到底、竞技场、旧师门/心魔/藏宝图战斗脚本、跨服帮战；保留用户维护的 Prefab |

> W8 当前快照（2026-09-30）：397 个 `Assets/ProjectX` Prefab、326 Identity、8 Timeline Player/122轨道，活动 UI/Timeline manifest 295/0。已退役 Timeline 与源资产详见 W8 处理单；剩余8个 Timeline Prefab均为本轮跳过或无 Unity 入口，全部保留。P-0161 的 PlayerHud 路线为 `UPDATE_CHAR=18/kind=513`；P-0162/P-0163/P-0165 已移除 Task、World 结算标题和装备培养动画1–9对 Imod 播放器的调用；P-0171–P-0174 已将 Formation、Fish 和 World 大地图敌人/主角动画改为 Unity Clips/Animator；P-0179 清理 Login 旧 Imod 生成路径及四个旧 Cocos Prefab；P-0180/P-0181 将 Hero 核心页面及共享来源弹窗转为 Unity-owned Prefab/资源/Transform；Hero Equipment路线 G4/最终画面待验；P-0186 Monopoly 动画已改 Unity-owned，页面 Provider 尚未完成；独立的 P-0124 `/226` 奖励入口仍待闭环。

> 2026-10-01 增量：P-0182 已从 Unity 生成链/Catalog 退役 69 个 `_zd_show` 与 72 个 `_zd` 旧 Imod 动画族，564 个既有生成文件归档至 Unity Assets 外，Catalog 为 742 项。Cocos ANI/atlas 与中立 IR 保留；Imod 转换/运行时仍被其他开放功能使用，Provider、WorldBattlePlayback 其余动画路线及 295 条 importer 文档仍未完成。无 Play/画面验收。

> 2026-10-01 最新增量：P-0183 将 WorldBattlePlayback 的 70 个模型、gj/sf1/sf2/sw/bj 五类战斗动作改为 Unity Animator（350 Controller/700 Clip/4,612 Sprite）；P-0184 将4个宠物品质光效改为Unity Sprite；P-0185 将202个技能特效和17个动态Buff动画转为Unity Animator，219组动画时长和循环规则经MCP核验。WorldBattlePlayback运行层已无Imod动画依赖；缺失的6个技能资源位保留原无效果行为。无Play/画面验收，用户最终查看实际战斗画面。全局Provider消费者、其他活动功能Imod消费者及295条活动UI importer文档仍开放。











## 2. 总进度

| 口径 | 当前值 | 说明 |
|---|---:|---|
| Static | `386 CSB 已审计` | 325 个同路径 CSD，61 个 CSB 兜底 IR |
| Functional | `待逐控件重审` | 旧页面/协议主链百分比已作废 |
| Strict Validated | `8/19 = 42.1%` | Login、Settings、PlayerHud、Bag、Task、World、Mail、XunBao |

GameplayShops、HeroCultivation 为用户明确授权的 G6 例外，不增加严格证据分子；BattleFengShenStory 为非分母战斗子模块。完成率不得在其他文档重复维护。
当前 Steam 业务模块分母固定为 19（2026-09-14 用户确认钓鱼纳入范围，由 18 调整为 19）。

> 迁移完成后的工作口径：下方模块的 G0-G6/G5/G6 字段保留为历史证据档案，不再作为当前 Unity 功能 Bug 验收的阻塞条件；后续只以 Unity 现有功能、真实输入、协议或 SQLite 权威结果和 Console 证据判断问题。

## 3. 模块状态

| 模块 | 当前状态 | 下一动作/边界 |
|---|---|---|
| Login | `G0-G6 历史通过 / W8 代码与 MCP 路线已验证，用户视觉验收待办` | Unity-owned Login/Notice/Loading/Error/Startup Prefabs、C# `/88` 请求与 Notice MCP 路线已验证；当前剩余为干净导入与 XLua 后置错误为零的 Player 构建、用户最终画面验收。历史 G0-G6 标签不作为 W8 完成证据。 |
| Settings | `G0-G6 历史完成；W8 Unity-owned 资源链已改，入口待复验` | P-0122 将页面 Prefab/Catalog/Reference/Provider 与 14 个 Transform 绑定切到 Unity-owned；共享 OneLevel 复用 P-0107。Main `btn_xitong` 当前变更后的 MCP 路线待跑，画面由用户最终验收。 |
| PlayerHud | `G0-G6 complete` | 用户最终确认，已收口 |
| Bag | `G0-G6 历史完成；W8 页面资源链部分转 Unity-owned，完整模块未收口` | P-0098 的 `/8` 页面入口已由 MCP 重验；使用/数量/礼包/来源已有 Unity Catalog 资源，Hero/FengShenStory 复用来源弹窗（P-0181）；共享 OneLevel 等路线仍待收口，最终画面由用户验收 |
| Task | `G0-G6 complete` | 已收口 |
| World | `W8 已迁路线通过；P-0119 1003 解锁→成就 MCP 路线通过；Guide_FuBen4 待处置` | P-0118 普通挑战→跨章解锁→原生提示→返回的技术路线已通过；P-0119 又通过 1003 解锁→提示→主线成就→关闭返回，权威 `/320 op=11` 回包有效。章 1001 完成时旧 Cocos `Guide_FuBen4` 跳转仍无 Unity 对应实现，单独待处置；其旧通关提示 Prefab 已在 P-0153 移除 Identity/6 条 Timeline 并保留节点树，用户最终验画待办。FengShenStory/Monopoly 的共享 Battle 入口分别归各模块核验（P-0053）。 |
| Mail | `G0-G6 历史 complete；W8 P-0120 JingJie + /128 + 附件来源路由已复验` | Main `btn_mail` 与回调未改，复用已接受的 G6 主入口证据；共享 BagItemSource 按 P-0099 复用；画面由用户验收 |
| XunBao | `G0-G6 complete` | 21/21，用户最终确认，已收口 |
| EnhanceMaster | `G0-G6 complete` | 40/40，用户最终确认，已收口 |
| HeroRebirth | `G0-G6 complete` | 24/24，用户最终确认，已收口；用户 Prefab 只读 |
| HeroCultivation | `G0-G6 user exception` | 51/51；Cocos缺口和历史未闭环台账继续披露，不复用例外 |
| GameplayShops | `G0-G6 user exception` | 仅 `function_id=15/type=2`；其他商店不在范围 |
| Draw | `G0-G5 passed / targeted bug user Play passed / G6 evidence pending` | 2026-09-11 用户最终真人 Play 确认定向修复通过；`manualPassed=true`，但 runtime-v4 严格控件证据仍有缺口，中央G6保持pending |
| Hero | `W8 核心页及共享来源弹窗已转 Unity-owned；其他子页待按入口处理` | P-0180/P-0181；共享 Prefab 已复用，视觉最终验收待用户执行 |
| HeroEquip | `G0-G4 passed / G5 blocked` | 当前不启动；用户 Prefab 不覆盖 |
| Shop | `G3 runtime-ready / early Play passed` | 正式 G1-G2、G4-G6 待后续独立任务 |
| Gameplay | `G4 passed / G5 blocked / G6 pending` | Arena `id=6` 已排除；真实 ScrollRect 滚动、用户 Play、重连与账号隔离均已通过；G5 等待 Cocos 跨后端映射 |
| Answer | `Unity binding changed / MCP resource probe passed / user retest pending` | 38道中文题与原有UI验收是历史状态；本轮切换UnityUiView/Unity Catalog与Transform绑定并移除AnswerLayer的UiPrefabIdentity，旧Play证据失效。Unity MCP资源路由探针通过；协议路线和用户复测待重新执行，manualPassed=false；中央G1-G6待补证据 |
| Fish | `G3 passed / user Play accepted` | Unity 单机实现与固定账号 9/9 真实点击回归已通过；Cocos 仅作源码基线且不声称运行截图；用户已在最后一次统一顶部层级与 Prefab `FishScene/pos` 挂点调整后实际测试通过，包含早收网结算逻辑，`manualPassed=true`；G4-G6 待后续重新开启 |
| MoneyTree | `功能验收通过` | 用户已多次真实 Play；查询、摇取、消耗与结果刷新无业务问题；本轮 MCP 截图插件报错不计为功能错误 |
| HappyWheel | `功能验收通过` | 已修复多次抽取后的累计角度偏移；用户连续三次真实 Play确认最终高亮与指针同格，奖励与日志正常 |
| JingJie | `G0 passed / G1 blocked / Unity user Play passed` | `/306 op=1/4`、20阶配置、Prefab、预览和突破动画已接入；2026-09-13 用户测试通过，待当前Cocos原生基线 |
| Monopoly | `闯关功能验收通过` | 2026-09-21 用户完成真实闯关战斗链路测试；地图、随机移动、守卫战 `/38` 回放、FightType=21 回放结束与返回刷新通过；正式 G5/G6 证据仍不虚报 |
| FengShenStory | `历史功能验收通过；W8 来源弹窗已转 Unity-owned，其余共享依赖待处理` | 2026-09-21真实 Play历史记录保留；P-0181 仅迁移来源弹窗，奖励弹窗和共享战斗依赖未在本批处理，视觉最终验收待用户执行 |
| BattleFengShenStory | `G0-G6 complete` | 非分母战斗子模块，已收口 |
| YouLi | `G0 passed / G1-G6 evidence missing` | 后续从当前源码重取 G1 |
| ResourceFoundation | `R0-R4 passed / early Play passed` | YooAsset、Atlas、内存预算后置 |
| Steam SQLite/发布 | `S0-S7 passed / S8 local accepted` | 物理干净机与真实 Steam Depot 暂缓 |

`steam-excluded`：Friend、Chat、Team、Guild主体、Welfare、Activity主体、StaminaClaim、ResourceRecovery、Funds、SevenDay、KunLun、BloodFight、Arena。用户于2026-09-12从Guild/Activity边界单独恢复 `MoneyTree/HappyWheel/Monopoly` 三个单人玩法；帮派种植与神树继续暂停。唯一范围表见 `docs/unityclient/STEAM_SCOPE.md`。
## 5. 总迁移顺序

1. P0 基础层：按现状冻结，不在当前功能处理内重开。
2. P1 核心养成与单人功能：按当前入口和实际进度选择下一模块。
3. P2 运营与商业化：进入保留模块前先完成 `docs/unityclient/modules/PAYMENT.md`。
4. P3 竞技/玩家依赖：按范围表和当前优先级推进。
5. P4 社交最后：Steam 排除项不再启动。



## 6. 已知风险

- 多代 UI、同名 Prefab 和旧 Lua 只能按当前入口闭包归属，不能按文件名判断。
- Unity 运行与固定账号验证只接受 SQLite `Application.persistentDataPath/LocalServer/projectx.db` 或明确的项目内隔离库；验证 Runner 不会启动、复用或清理 MySQL。6 个旧固定账号合同缺少 SQLite 声明，当前会 fail-closed，须随对应入口迁移合同与 fixture。
- JSON 只作证据索引；最终验收必须同时包含真实输入、玩家可见 UI、协议或 SQLite 权威状态和当前文件证据。
- 未水合 LFS、旧输入指纹、进程/端口残留及未解决 Ledger 记录会使对应门禁失效。

## 7. 维护规则

- 本文件只改当前焦点、状态、顺序和风险；不得追加日期流水或长篇验证过程。
- 模块结论写模块文档；控件事实写矩阵；机器门禁写 JSON；历史写 `history/`。

## 8. 延后待办

- `ProjectXApp.cs` 大文件拆分优化：待当前 Bug 修复阶段稳定后单独执行；优先按现有 partial/业务域继续拆分，禁止与功能修复混提或改变运行逻辑。
- 新任务默认只读取本文件的“当前焦点”和目标模块所在行，不重复加载已完成模块细节。
