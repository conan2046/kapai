# 神将招募（Draw）迁移证据

## 当前结论

- 当前 `G0-G6 complete / user final Play passed`：2026-09-11 用户真人点击基础/高级 `Btn_Recruit_2` 复现“直接碎片道具中央无图标”。源码修复后，正式奖池229条映射全量通过；恢复后的账号1未注入奖励随机实抽得到基础碎片2458和高级新神将64，实际回包、持久化业务变化与结果 UI 一致。用户在最后一次相关变更后明确反馈“测试通过”，`manualPassed=true`，Draw 收口。MCP EventSystem 仍只计诊断，历史 runtime-v4 自动证据缺口继续披露。
- 当前 Unity 固定 SQLite 身份为 `7200057/1000003`，隔离身份为 `1/1000001`；夹具只操作 `Application.persistentDataPath/LocalServer/projectx.db`，必须整库快照、恢复、重登业务哈希、`PRAGMA integrity_check` 与残留 0 全通过。
- 历史 28/28 控件、6/6 语义、9/9 双端视觉及恢复 SHA 仅作回放输入和差异线索；v4 门禁不读取旧逐控件布尔值，也不把缺失的 56 张逐控件图片重新定义为通过证据。
- 两次真正 `BootstrapSceneBuilder.BuildBatch` 的场景 SHA-256 均为 `CBE2F1020F627C6904F6E754C08CB17D7848CF8FE5F56E70E523FF804C7F700B`。
- 确定性重复转换目标只能使用高级池首次真实招募：服务端 `CChouKaManager::ChouKa` 在高级池累计次数为零时权威返回神将 `64`；直接碎片道具来自普通奖池随机项，必须先核对 `/224 reward.Type<60000`，不能拿重复转换结果替代它。
- 概率结果不做跨端逐项相等要求：Cocos 与 Unity 使用同一正式配置和真实账号状态时允许抽到不同奖励；每次验收只要求本次 `/224` 权威回包、业务数据变化与结果 UI 一致。`NewHero`/`DuplicateFragment` 夹具只用于定位分支，不作为正式概率抽取通过条件。

## 1. 当前范围

- 当前双端运行时可见主界面入口：`Layer/Main_UI/ButtonGroup3/btn_zhaomu`；历史 Prefab 中另有隐藏的 `ButtonGroup1/btn_zhaomu`，不得作为当前点击目标。
- 当前回调：`MainUI:LuckDrawTouchCallback → Utils:OpenFunction(EMID_KAPAI_CHOUKA)`。
- 当前 View：`View/HappyDraw/HappyDrawUI.lua`，不是旧 `View/LuckyDraw/LuckyDrawUI.lua`。
- 当前协议：`MSG_PET_RANDOM_DRAW / 224`。
- 第一阶段：三类招募信息、免费次数、倒计时、单抽/十连入口、红点、一次隔离角色免费单抽和单抽结果表现。

旧 `EMID_CHOUKA=160 → LuckyDraw.LuckyDrawUI` 仅在任务追踪等遗留调用中存在，主界面按钮已明确改走 `EMID_KAPAI_CHOUKA=1010 → HappyDraw.HappyDrawUI`，不作为当前迁移版本。

## 2. 当前调用链

```text
UImainLayer_new/Layer/Main_UI/ButtonGroup3/btn_zhaomu
→ MainUI:LuckDrawTouchCallback
→ Utils:OpenFunction(EMID_KAPAI_CHOUKA)
→ AppDef.ModuleOpenData[1010].lua = HappyDraw.HappyDrawUI
→ cc.CSLoader:createNode("csd/chouka/shenjiangzhaomu.csb")
→ createTimeline("csd/chouka/shenjiangzhaomu.csb") / gotoFrameAndPlay(0,false)
→ SendExtractPetMsg(1)
→ /224 op=1
→ CPackageDeal::PetDraw
→ CChouKaManager::GetChouKaMsg
→ LuaNetRecvdMsg.DealLuckDraw
→ LUIDrawEvent.updateDrawUI
→ HappyDrawUI:updateUI
```

单抽链：

```text
Popup1/2/3 → Btn_Recruit_2
→ HappyDrawUI:DrawCallBack
→ SendExtractPetMsg(2, kind, 1)
→ /224 op=2 + kind + drawType
→ CChouKaManager::ChouKa
→ 权威扣券/免费次数、随机奖励、保底、加奖
→ LuaNetRecvdMsg.DealLuckDraw
→ SingleDrawSuccess
→ csd/chouka/dancichouka.csb
```

十连及重复转换链：

```text
Popup1/2/3 → Btn_Recruit_1
→ SendExtractPetMsg(2, kind, 2)
→ /224 op=2 + kind + 2
→ CChouKaManager::ChouKa
→ TenDrawSuccess → csd/chouka/shilianchouka.csb
→ 已拥有神将：reward type=60002 + transformItemId/transformAmount
→ 神魂条目（非客户端推演）
```

## 2.1 本轮 G1 原生运行证据（2026-07-29）

| 状态 | 原生证据 | 结论 |
|---|---|---|
| 三卡池、券数、免费次数、红点 | `DRAW-07-POOL-RESOURCED.png` | 基础/高级/友情均从真实 `op=1` 状态渲染；券由 `/128` 邮件附件真实领取。 |
| 高级免费单抽 | `DRAW-08-HIGH-FREE-NEW-HERO64-RESOURCED.png` | 首次高级池权威返回目标神将 `64/郑伦`，结果 Timeline/关闭/继续入口均可见。 |
| 高级十连与结果状态 | `DRAW-09-HIGH-TEN-RESULT.png`、`DRAW-10-HIGH-TEN-GRID-DUPLICATES.png` | 先展示最高品质 `罗宣`，确认后展示十格权威结算；重复神将显示为“神魂”及数量。 |
| 招募券不足 | `DRAW-11-HIGH-TEN-INSUFFICIENT-EXCHANGE.png` | 高级券仅余 9 时请求十连，客户端展示服务端不足后的“道具兑换”分支。 |
| 奖励预览三页 | `DRAW-02-PREVIEW-NORMAL.png`、`DRAW-03-PREVIEW-HIGH.png`、`DRAW-04-PREVIEW-FRIEND.png` | 三个 Tab 与可滚动奖励预览均在 Cocos 原生界面取得。 |
| 新神将跨模块可见 | `DRAW-06-HERO-LIST-TARGET64.png` | 隔离账号真实招募后，Cocos Hero 列表出现 `郑伦`。完整培养/阵容闭环留待 G5 固定账号。 |

G1 原始窗口截图全部为 `1334×750` PrintWindow 捕获；`kapai-current.out` 含对应 `/224` 请求/回包，严重模式扫描为 0。隔离账号仅作为 G1 证据，完成后将精确删除，不进入固定账号验证。

## 3. 协议字段

### 3.1 请求

| 分支 | 字段顺序 | 宽度 |
|---|---|---:|
| 查询 | cmd=224, op=1 | u16, u8 |
| 抽取 | cmd=224, op=2, kind, drawType | u16, u8, u8, u8 |

`kind`：1 基础、2 高级、3 友情；`drawType`：1 单抽、2 十连。

### 3.2 op=1 响应

| 字段 | 宽度 | 说明 |
|---|---:|---|
| op | u8 | 1 |
| count | u8 | 当前配置数量 |
| kind | u8 | 招募类型 |
| totalDraws | u32 | 累计抽取次数 |
| freeCooldown | u32 | 距下次免费秒数 |
| freeTimes | u8 | 今日剩余免费次数 |

### 3.3 op=2 响应

公共头：`op u8, kind u8, drawType u8, success u8`。失败时追加 UTF-16LE 字符串；成功时追加：

| 字段 | 宽度 | 说明 |
|---|---:|---|
| totalDraws | u32 | 权威累计次数 |
| freeTimes | u8 | 仅单抽 |
| freeCooldown | u32 | 仅单抽 |
| guaranteedCount | u8 | 固定附加奖励数 |
| guaranteed reward | u16 + u32 + u32 | type/id/amount |
| resultCount | u8 | 仅十连；单抽固定 1 |
| result reward | u16 + u32 + u32 | type/id/amount |
| transformItemId/amount | u16 + u32 | reward type=60002 时追加 |

## 4. 服务端分支

- `protocol.h`：`MSG_PET_RANDOM_DRAW = 224`。
- `pack_deal.cpp` 注册：`MSG_PET_RANDOM_DRAW → CPackageDeal::PetDraw`。
- op=1：`CChouKaManager::GetChouKaMsg` 返回三类状态。
- op=2：`CChouKaManager::ChouKa`。
- kind=3 检查系统 1011，其余检查系统 1010；失败直接 `false`，不回包。
- 未知 kind、drawType 或缺配置返回 `false`，不回包。
- 单抽优先消耗可用免费次数，否则必须有对应招募券；不足返回 `PRO_ERROR + string`。
- 十连必须持有十倍对应招募券；不足返回 `PRO_ERROR + string`。
- 高级招募第一次固定神将 64；普通随机与保底完全由服务端 `draw_basic.json/draw_config.json` 决定。
- 服务端先写权威结果，再增加奖励与任务进度；Unity 不预测奖励、不伪造成功。

当前 `CPetDrawCfgMgr` 读取 `pet_draw_*.xml` 的另一套实现没有被 `/224 → PetDraw` 调用，属于并存旧逻辑，不作为当前字段依据。

## 5. CSB、Timeline 与 Imod

| 用途 | 当前完整路径 | 调用 |
|---|---|---|
| 招募主界面 | `csd/chouka/shenjiangzhaomu.csb` | createNode + createTimeline，动作 0 非循环 |
| 单抽结果 | `csd/chouka/dancichouka.csb` | createNode + createTimeline |
| 十连结果 | `csd/chouka/shilianchouka.csb` | createNode + createTimeline |
| 奖励预览 | `csd/chouka/jiangliyulan.csb` | 三类奖励预览共用 |
| 抽取炉特效 | `res2/fx/choukaluzi` | Imod action 0 |

所有路径来自当前 Lua 非注释调用点，未按 basename 推断。

## 6. Unity 实现与偏差

### 本轮 G2 静态映射（2026-07-29）

- `shenjiangzhaomu`：三组 `Popup{1..3}` 的 `Btn_Recruit_2/Btn_Recruit_1` 分别映射 `/224 op=2` 单抽/十连；免费、倒计时、红点只读 `DrawStore` 的权威 `op=1` 状态。
- `dancichouka`：关闭、背景跳过、继续招募、技能/确认均绑到真实结果生命周期；结果文案与图标只由 `op=2` 奖励回包渲染。
- `shilianchouka`：`Item_1..Item_10` 与 `shenjiang_1` 由十连回包渲染，重复项沿用 `type=60002` 的 `transformItemId/transformAmount`，不从本地 HeroStore 反推奖励。
- `jiangliyulan` 已纳入 Bootstrap，`RewardPreview` 使用原生导入 Prefab 打开/关闭；商城兑换和将魂商店仍保持 Cocos 原生联动边界，Unity 不伪造交易或本地扣券。

- `DrawStore` 保存三类权威状态与最后一次权威结果。
- `DrawController` 独占 `/224` 解析，并严格检查剩余字节。
- `DrawPresenter` 运行时绑定真实 Prefab；不修改或重建手工 Prefab。
- 当前主界面入口、三类 Popup、单抽/十连按钮、免费状态、倒计时和红点均按真实节点绑定。
- 第一阶段动态门禁只消耗隔离角色的一次免费基础单抽；十连按钮与协议字段已接入，但不为验收强造十张券。

### 本轮 G3 实现与固定账号数据契约（2026-07-29）

- `HeroController.levelUp` 直接发送 `/24 op=3 + heroId + 834 + 1`，仅在成功回包后重拉 `/24 → /48`；等级、属性和上阵显示不在 Unity 侧预测或改 Store。
- `HeroController.moveHero` 已移除“必须原先上阵”的错误限制，仍通过服务端 `/48 op=4` 对目标神将和阵位做权威校验；因此招募得到、初始未上阵的神将可被真实替换进合法阵位。
- `Invoke-DrawSqliteFixture.ps1/.py` 只接受当前用户 `AppData/LocalLow/Xuancai/ProjectX/LocalServer/projectx.db`。默认 `NewHero` 对 `7200057/1000003` 建立确定性高级首次招募、券/材料/阵位条件；`-Profile DuplicateFragment` 预置目标神将64，确保首次高级单抽满足碎片转换前置条件。隔离身份固定为 `1/1000001`。
- 夹具执行整库快照和精确还原，并独立记录数据库 SHA-256、重登业务哈希、`PRAGMA integrity_check` 与 fixture 残留；静态副本自检不能替代真实客户端重登。

## 7. 动态验证（2026-08-23 历史 G6 记录；2026-08-27 缺证降级）

命令：

```powershell
pwsh -File tools/unity-migration/Run-UnityFixedAccountValidation.ps1 -Module Draw -DataPreflightOnly
pwsh -File tools/unity-migration/Invoke-DrawSqliteFixture.ps1 -Action Setup -Profile DuplicateFragment
pwsh -File tools/unity-migration/Invoke-DrawSqliteFixture.ps1 -Action AssertSetup -Profile DuplicateFragment
# 此时只做一次真实高级单抽并核对 /224、Type=60002、TransformItemId>0 与可见碎片UI；随后按 Restore/AssertRestored/AssertReloginHash/Cleanup/AssertCleanup 恢复。
pwsh -File tools/unity-migration/Run-UnityFixedAccountValidation.ps1 -Module Draw -FinalFull
pwsh -File tools/unity-migration/New-UnityModuleG5Evidence.ps1 -Module Draw
pwsh -File tools/unity-migration/Test-BootstrapSceneIdempotence.ps1
```

最终证据：

- `.local/unity-validation/draw-fixed-account-latest.json`：固定账号 28/28 控件、6/6 语义断言通过。
- `.local/unity-validation/draw-fixed-account-runner-latest.json`：`/224 high free deterministic target 64 → /24 authoritative cultivation → /48 position 1 → reconnect persistence → alternate account 705213 isolation`。
- `.local/ui-fidelity/Draw/compare/g5-20260730/report.json` 与 `manual-acceptance.json`：9 组 Cocos/Unity 原图、并排、叠加和差异报告通过。
- 历史记录曾声明 Unity 编译指纹 `7867253031D35333AC77F495C3922F409951D7439C92005DC9BC30BAD449E67A`、固定账号 28/28 控件和 6/6 语义通过；当前只能作为重拍线索，不能替代缺失文件。
- Cocos 上阵完成帧未刷新培养后的等级/装备数值；Unity 显示同一服务端权威培养结果。该差异作为原生陈旧显示缺陷保留，不回退 Unity 权威状态。
- 精确恢复：快照、恢复和重登录哈希一致，Fixture 行 0；严重错误 0。
- 两次正式 BuildBatch 幂等 SHA-256：`48F42BDE8CB04EEB6532C850F0221EB802C4FAF85829B0847DF2EA74FA8DD6F0`。
- G5 的 9 个原生 `1334×750` 主状态仍存在；`DRAW_CONTROLS.json` 已登记 `g6Audit`。runtime-v4 的56个逐控件双端证据路径仍不存在，该自动审计债务不伪造补齐；本次收口依据用户批准的旧方案与最后一次相关变更后的真人 Play 明确通过。
- 好友入口在 Steam 版本明确提示排除；将魂商店在 Gameplay route 15 尚未迁移时明确提示边界，不伪造商城交易。

### 单抽碎片两分支回归（2026-09-11）

- 用户真人操作已证明缺陷命中的是奖池直接碎片：账号1的物品2458由4增至6、基础/高级累计由4/2增至5/3且未持有神将65，对应 `/224 type=2458, transformItemId=0`；此前通过的高级首次抽取是神将64重复转换 `/224 type=60002, transformItemId=2457`，两次测试并非同一分支。
- 根因：Unity 单抽结果只为 `TransformItemId>0` 创建中央碎片卡；直接物品分支仅激活导入的空 `Item` 节点，并遗留 Prefab 的 `SSS` 品质图。修复后，直接物品以 `reward.Type`、重复转换以 `transformItemId` 取 `ItemIcons/equip{itemId}`，共同使用 Timeline 外稳定运行时卡片；非神将结果强制隐藏旧品质图。
- 结果一致性按规则校验，不比较随机值：正式 `draw_basic.json/draw_config.json` 共229条奖池项；全部35种直接奖励/保底类型均存在正式物品配置，34种具备 `equip{reward.Type}` 图标，神魂货币60014具备正式 `pic=3005` 回退图标，缺失配置与缺失图标均为0。
- 无夹具真实数据复测：恢复后的账号1基础实抽随机返回直接碎片2458×1，持久化后背包2458 `0→1`、基础累计 `0→1`，UI显示 `equip2458/common_quality_04`；高级实抽随机返回新神将64，神将列表新增64、高级累计 `0→1`，UI显示郑伦/A。两次结果不同且都按各自权威回包正确落地。
- 固定身份 `7200057/1000003`，`DuplicateFragment` 的 `AssertSetup` 通过。MCP 调用 `RuntimeInputDispatcher` 执行当前 EventSystem raycast 和 pointer down/up/click，只作修复诊断：基础单抽命中 `DRAW-02` 并显示 `equip2458×1`；高级首次显示 `equip2457×30`；高级下一次直接碎片显示 `equip2417×1`。
- 当前证据：`.local/unity-validation/draw-user-single-fragment-regression-20260911.md`、`.local/unity-validation/draw-direct-fragment-targeted-20260911.md`、`.local/unity-validation/draw-real-state-random-result-20260911.md` 及对应 `.local/ui-fidelity/Draw/unity/g4-20260911-*/`。
- 已执行 `Restore → AssertRestored → 客户端重登 → AssertReloginHash → Cleanup → AssertCleanup`；恢复业务哈希一致、完整性 `ok`、残留 `0`。
- 当前原生 Computer Use 没有暴露 Unity 应用面，因此修复后的三条 MCP 结果仅计定向诊断；随后用户使用原生 Unity GameView 真人复测并明确反馈“测试通过”，`manualPassed=true`。

### hardGateVersion=4 快速回放试点（2026-09-10）

- 公共格式：`tools/unity-migration/runtime-snapshot.schema.json`；Draw 唯一场景：`tools/unity-migration/runtime-scenarios/draw.json`，28 个唯一动作 ID 与 28 个矩阵控件 ID 全等。
- Cocos 通过 `RuntimeSnapshotReplay.lua + RuntimeSnapshotCollector.lua` 走 `cc.EventDispatcher`；Unity 通过 `RuntimeInputDispatcher.cs + RuntimeSnapshotCollector.cs` 走 `EventSystem.RaycastAll + ExecuteEvents`。两端禁止 Presenter、回调或 `.onClick.Invoke()` 直调。
- 每动作输出目标/射线、引擎事件、`/224` 原始包长度与 SHA-256、解码字段、变化节点、稳定帧、动画开始/结束/清理和结论；`Compare-UnityRuntimeSnapshots.ps1` 只比较语义字段，并把 `simulation=true`、缺 raw hash 或任一子标志失败写入 `failures.json`。
- 当前会话均完整出行：Cocos `28/28` 条中自动通过 `0/28`，根因是随包 Lua 绑定无法把回放构造的 touch table/vector 传给 `EventTouch:setTouches`；Unity `28/28` 条中仅 `DRAW-A01/A02/A03` 自动、引擎输入、协议和 UI 树均通过，其余 `25/28` 因动作间未恢复各自前置/清理状态而被上一结果层阻挡。单抽/十连结果根路径已区分，撤销了 A21 命中十连背景形成的假阳性。语义比较 `matched=0/28`、失败明细 `446`，门禁必须拒绝。
- 固定 SQLite 夹具已通过精确恢复、重登录校验、`PRAGMA integrity_check=ok` 与残留 `0`。当前 product 指纹为 `ECEFC4C22D64CC959514BA4B0BEF107D8D082111A8FC4CC5FFBF60435103816D`，probe 指纹为 `F41547E6A486A529A1D6213C6ACC3AC15DFD5A6551A5EEB29F0082022F370DED`。
- Computer Use 原生应用面仍返回空，真实输入抽检保持 `0/8+0/8`；现有 9 组图片未建立本轮 product/probe 双指纹基线，视觉保持 `0/9`，不自动复用。

以下为 2026-07-18 历史 phase1 证据，不计本轮门禁：

- `userId=7200024`，`roleId=1000038`；失败账号 `7200022`、视觉修正前账号 `7200023` 均未复用为最终证据。
- `/224 op=1`：request=5，SEND/RECV，`0.129s`；返回 3 类，基础免费 3、高级免费 1、友情免费 0。
- `/224 op=2 kind=1 drawType=1`：request=6，SEND/RECV，`0.047s`；权威累计次数 1、奖励 1，结果为 `陈奇神魂 ×1`。
- COMPLETE：`current btn_zhaomu -> HappyDrawUI -> /224 op=1 three pools/free countdown/red-point -> op=2 kind=1 single free draw -> authoritative reward/result timeline`。
- 结果 UTC：`2026-07-18T04:41:00.9261860Z`。
- 截图：`build/ui-migration/bootstrap-draw.png`，`1334×750`；真实奖励图标、名称、数量和结果背景可见。
- 严重异常扫描：`error CS\d+ / LuaException / NullReferenceException / MissingReferenceException / Assertion failed / Fatal Error / Crash!!! = 0`。
- 验收脚本 finally 已关闭本批 `kapai.exe` 与 workspace-local MySQL；本模块不使用临时 SQL 夹具。

## Steam SQLite S5（2026-08-20）

- 证据：`.local/unity-validation/steam-sqlite-s5-draw-latest.json`，状态 `Passed`。
- SQLite/MySQL 均使用全新隔离角色执行相同 8-case 运行期流程：三池查询 → 高级首次免费单抽 → 本地验证专用 `/13 op=50` 准备十张 `1001` → 生产 `/224` 十连 → 再次十连券不足拒绝 → `/24` 权威神将查询。
- 双端首次高级单抽均确定返回神将 `64`；十连均返回 10 个合法结果并把高级池累计次数推进到 `11`。重启 2-case 后高级池仍为 `allCnt=11/freeTimes=0`，`/24` 仍可查询。
- 数据库 `pet/package/mission/save_data`、角色等级/经验/货币和账号货币原始值一致；两端均持有 `[24,57,64]`，`1001` 余量均为 `0`。`chou_ka` 仅高级免费冷却截止时间因顺序执行相差 52 秒，按真实墙钟语义归一并保留两端原值。
- 运行期双方各 85 响应、重启各 22 响应，manifest 单边协议 0、结构差异 0；中央工具链 `129/129`。只删除隔离库 `fxl_game_draw_s5_v1`，正式 `fxl_game_local` 与 MySQL 源码/驱动/构建/Schema/脚本/回归全部保留。
- S5 下一模块：`Gameplay`；这不改变本页既有 G0-G6 视觉/功能完成边界。

## 8. 完成边界与后续

- 直接碎片和重复神将转换两条权威结果分支均已修复；正式229条奖池配置的全部35种直接奖励资源映射通过，抽取结果按“实际回包→业务数据→UI”一致性验收，不要求跨端随机结果相同。2026-09-11 用户最终真人 Play 明确通过，Draw G6 收口。
- 概率公示、支付/渠道合规和友情点外部产出链不属于本模块。
- 本任务不进入下一模块；后续模块使用新任务。
