# 神将招募（Draw）迁移证据

## 当前结论

- 本轮 `G0-G6 passed`：当前 `HappyDrawUI`、`/224` 和 28 个控件/状态族全部完成；矩阵为 `../matrices/DRAW_CONTROLS.json`。Hero 与 Formation 仅承担真实招募目标的跨模块回归，没有扩大迁移边界。
- 固定账号 `7200057/1000115` 真实完成高级免费单抽确定获得 `64 郑伦`，随后 `/24 op=3` 培养、`/48 op=4` 上阵、重进、断线重连；切换 `705213/1000006` 后目标神将和阵容均未继承。
- 28/28 控件、6/6 语义硬断言、9/9 双端视觉通过；账号快照、招募记录、神将、培养材料、货币和阵容精确恢复，SHA-256 `d10f760ded12ce9b8518770097bad55e1d85b72906a0e3344a9de47fe23483ee`，Fixture 残留 0。
- 两次真正 `BootstrapSceneBuilder.BuildBatch` 的场景 SHA-256 均为 `CBE2F1020F627C6904F6E754C08CB17D7848CF8FE5F56E70E523FF804C7F700B`。
- 确定性目标只能使用高级池首次真实招募：服务端 `CChouKaManager::ChouKa` 在高级池累计次数为零时权威返回神将 `64`；普通池随机结果不能用作固定账号验收目标。

## 1. 当前范围

- 当前主界面入口：`Layer/Main_UI/ButtonGroup3/btn_zhaomu`。
- 当前回调：`MainUI:LuckDrawTouchCallback → Utils:OpenFunction(EMID_KAPAI_CHOUKA)`。
- 当前 View：`View/HappyDraw/HappyDrawUI.lua`，不是旧 `View/LuckyDraw/LuckyDrawUI.lua`。
- 当前协议：`MSG_PET_RANDOM_DRAW / 224`。
- 第一阶段：三类招募信息、免费次数、倒计时、单抽/十连入口、红点、一次隔离角色免费单抽和单抽结果表现。

旧 `EMID_CHOUKA=160 → LuckyDraw.LuckyDrawUI` 仅在任务追踪等遗留调用中存在，主界面按钮已明确改走 `EMID_KAPAI_CHOUKA=1010 → HappyDraw.HappyDrawUI`，不作为当前迁移版本。

## 2. 当前调用链

```text
UImainLayer_new/ButtonGroup3/btn_zhaomu
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
- `Invoke-DrawCocosFixture.ps1` 使用可逆服务端夹具：目标 `64` 在夹具前不存在，高级池 `allCnt=0/freeTimes=1`，首个高级单抽由 `CChouKaManager` 确定返回 `64`；同时准备招募券、`834` 和其服务端经验模板 `type=3/sub_value=60006,200`，并快照 `package/pet/chou_ka/zhenfa`、培养后会变更的战力与货币字段及模板原值。
- 固定账号闭环另用只读隔离账号 `705213/1000006`：Fixture 建立和预演均解析其真实神将快照并硬断言不存在目标 `64`；Unity 在主账号重连验证后真实切换该账号，再重拉 `/24 → /48` 验证不继承神将、培养或阵容状态。
- 夹具本地自检已执行“建立 → 初始硬断言 → 精确恢复 → fixture 行为 0、整体 SHA 一致”；完整预演必须再走固定账号脚本的登录、恢复与清理流程，不能以本自检替代。

## 7. 动态验证（2026-07-31 最终）

命令：

```powershell
pwsh -File tools/unity-migration/Run-UnityFixedAccountValidation.ps1 -Module Draw -DataPreflightOnly
pwsh -File tools/unity-migration/Run-UnityFixedAccountValidation.ps1 -Module Draw
pwsh -File tools/unity-migration/New-UnityModuleG5Evidence.ps1 -Module Draw
pwsh -File tools/unity-migration/Test-BootstrapSceneIdempotence.ps1
```

最终证据：

- `.local/unity-validation/draw-fixed-account-latest.json`：固定账号 28/28 控件、6/6 语义断言通过。
- `.local/unity-validation/draw-fixed-account-runner-latest.json`：`/224 high free deterministic target 64 → /24 authoritative cultivation → /48 position 1 → reconnect persistence → alternate account 705213 isolation`。
- `.local/ui-fidelity/Draw/compare/g5-20260730/report.json` 与 `manual-acceptance.json`：9 组 Cocos/Unity 原图、并排、叠加和差异报告通过。
- 精简后 Unity 编译指纹 `0D5EBD48125F830ADF99CA08E3159DB59BD03C65133379E8CA0C55E0AB576A1E`；冻结工具链仅修复可选 `visual*` 字段与合同终态账号读取，回归 `43/43`。
- Cocos 上阵完成帧未刷新培养后的等级/装备数值；Unity 显示同一服务端权威培养结果。该差异作为原生陈旧显示缺陷保留，不回退 Unity 权威状态。
- 精确恢复：快照、恢复和重登录哈希一致，Fixture 行 0；严重错误 0。
- 两次正式 BuildBatch 幂等 SHA-256：`CBE2F1020F627C6904F6E754C08CB17D7848CF8FE5F56E70E523FF804C7F700B`。

以下为 2026-07-18 历史 phase1 证据，不计本轮门禁：

- `userId=7200024`，`roleId=1000038`；失败账号 `7200022`、视觉修正前账号 `7200023` 均未复用为最终证据。
- `/224 op=1`：request=5，SEND/RECV，`0.129s`；返回 3 类，基础免费 3、高级免费 1、友情免费 0。
- `/224 op=2 kind=1 drawType=1`：request=6，SEND/RECV，`0.047s`；权威累计次数 1、奖励 1，结果为 `陈奇神魂 ×1`。
- COMPLETE：`current btn_zhaomu -> HappyDrawUI -> /224 op=1 three pools/free countdown/red-point -> op=2 kind=1 single free draw -> authoritative reward/result timeline`。
- 结果 UTC：`2026-07-18T04:41:00.9261860Z`。
- 截图：`build/ui-migration/bootstrap-draw.png`，`1334×750`；真实奖励图标、名称、数量和结果背景可见。
- 严重异常扫描：`error CS\d+ / LuaException / NullReferenceException / MissingReferenceException / Assertion failed / Fatal Error / Crash!!! = 0`。
- 验收脚本 finally 已关闭本批 `kapai.exe` 与 workspace-local MySQL；本模块不使用临时 SQL 夹具。

## 8. 完成边界与后续

- Draw 本轮完成；不迁移副本。
- 概率公示、支付/渠道合规和友情点外部产出链不属于本模块。
- 下一任务仅建议进入 `World（世界/战斗/副本）`，必须重新从 G0 冻结当前入口、协议和控件矩阵。
