# 神将招募（Draw）迁移证据

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

- `DrawStore` 保存三类权威状态与最后一次权威结果。
- `DrawController` 独占 `/224` 解析，并严格检查剩余字节。
- `DrawPresenter` 运行时绑定真实 Prefab；不修改或重建手工 Prefab。
- 当前主界面入口、三类 Popup、单抽/十连按钮、免费状态、倒计时和红点均按真实节点绑定。
- 第一阶段动态门禁只消耗隔离角色的一次免费基础单抽；十连按钮与协议字段已接入，但不为验收强造十张券。

## 7. 动态验证

命令：

```powershell
pwsh -File tools/unity-migration/Run-UnityModuleValidation.ps1 -Module Draw
```

最终证据：

- `userId=7200024`，`roleId=1000038`；失败账号 `7200022`、视觉修正前账号 `7200023` 均未复用为最终证据。
- `/224 op=1`：request=5，SEND/RECV，`0.129s`；返回 3 类，基础免费 3、高级免费 1、友情免费 0。
- `/224 op=2 kind=1 drawType=1`：request=6，SEND/RECV，`0.047s`；权威累计次数 1、奖励 1，结果为 `陈奇神魂 ×1`。
- COMPLETE：`current btn_zhaomu -> HappyDrawUI -> /224 op=1 three pools/free countdown/red-point -> op=2 kind=1 single free draw -> authoritative reward/result timeline`。
- 结果 UTC：`2026-07-18T04:41:00.9261860Z`。
- 截图：`build/ui-migration/bootstrap-draw.png`，`1334×750`；真实奖励图标、名称、数量和结果背景可见。
- 严重异常扫描：`error CS\d+ / LuaException / NullReferenceException / MissingReferenceException / Assertion failed / Fatal Error / Crash!!! = 0`。
- 验收脚本 finally 已关闭本批 `kapai.exe` 与 workspace-local MySQL；本模块不使用临时 SQL 夹具。

## 8. 未完成边界

- 十连正向消耗与十个结果的独立动态证据。
- 三类奖励预览页面交互。
- 神将/碎片详情、重复神将转换展示深化。
- 招募券不足跳转、友情点来源和将魂商店联动。
- 发布概率公示、支付/兑换入口与渠道合规。
