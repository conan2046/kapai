# 灵气捐献（EAID = 4）功能梳理与单机化前置分析

> **状态**：**未纳入 Unity 迁移清单**。`tools/unity-migration/unityclient-modules.json`（39 个模块）无对应条目；`docs/config-map/_build_config_map.py:1081` 将其归类为「老活动玩法（EAID 4）· 未纳入迁移清单」，迁移状态 **待梳理**。
> **本文件定位**：老端（Cocos + C++）功能事实梳理 + Unity 单机化前置分析。**不作为模块状态来源**，不参与 `UNITYCLIENT_STATUS.md` 完成率口径，不触发 G0-G6。
> **证据基准**：2026-09-14，静态源码阅读（未启动服务端/客户端）。

---

## 1. 结论摘要

1. **功能本质**：玩家消耗「先锋令」类道具或直接捐献，为全服累积「灵气值」（0–1000），灵气值决定每日 16:30 刷新在**帮派场景**的「灵魔」档次（虚弱/强壮/完美/恐怖），击杀后掉落活动兑换币。**灵气捐献是「挑战灵魔」（EAID = 17）的前置蓄能环节**。
2. **服务端捐献逻辑可用、且不依赖定时器**：op6（查询）/ op7（捐献）仅依赖 `vip_def.lingqi` 次数上限与背包道具，无系统开关校验（`CHECK_SYSTEM_OPEN(SOT_Lingqijuanxian)` 两处均被注释），本地可独立验证。
3. **灵魔环节当前不可运行**（三处结构性阻塞，详见 §7）：`LingQiJuanXianTimer()` 在主循环被注释；`IsInLingMoActivity()` 因此恒为 `false`；`CSystemOpenCfgMananger` 实际只解析 3 个字段，`show / show_icon / before_time / start_time / end_time / openWeekday` 全为默认 0，导致 `GetFuncLvTime()` 恒 `false`、`CanShow()` 恒 `false`。
4. **灵魔击杀经验为 0**：`fight.cpp:4853` 为 `int exp = 0; AddExp(exp, true, true);`，即当前实现下击杀灵魔**不给经验**（疑似未实现或被下线），仅给兑换币与活跃度。
5. **单机化（Steam）主要障碍是「帮派前 10 名场景」与「进程级全局灵气值」**：`lingQiValue` 是进程全局变量（`main.cpp:54`）而非存档字段，重启即清零；灵魔仅刷在帮派场景，需前 10 名帮派数据。

---

## 2. 功能定位与易混淆项

### 2.1 三个「捐献」不是同一个功能

| 功能 | 活动 id / 入口 | 客户端实现 | UI 资源 | 服务端入口 | 说明 |
|---|---|---|---|---|---|
| **灵气捐献**（本文件） | `EAID_ANIMA = 4`（`AppDef.lua:164`） | `View/Activity/DonateManiUI.lua` → `View/Activity/DonateUI.lua` | `csd/DonateLayer.csb` + `csd/Plist/lingqijuanxian.plist` | `MSG_HUODONG_OPTION(199)` op6 / op7 | 全服灵气值 + 灵魔档次 |
| **帮派捐献** | 帮派区（`View/BangPai/`） | `View/BangPai/BangPaiJuanXianUI.lua` | `csd/bangpai/GangsDonateLayer.csb` | `QueryFactionJuanXian` / `QueryFactionJuanXianRecord` | 捐钱换帮贡 + 捐献记录；与本文件无关 |
| **挑战灵魔** | `EAID_LINGMO = 17`（`AppDef.lua:173`） | `ActivityFunction.lua:148-153` → `QueryLingMoInfo()` | `Activity_Name17` 玩法图标 | `MSG_HUODONG_OPTION` op12 | 灵气捐献的下游消费环节 |

> 注意：`DonateLayer.csb`（灵气捐献）与 `GangsDonateLayer.csb`（帮派捐献）是两个不同 CSB，勿混用。

---

## 3. 玩法闭环

| # | 环节 | 触发 | 关键数据 | 证据 |
|---|---|---|---|---|
| 1 | 打开面板 | 活动列表点击 `EAID 4` | 打开 `Activity.DonateManiUI` | `ActivityFunction.lua:56-58` |
| 2 | 查询数据 | 面板 `Init` 发 op6 | 返回当前灵气值 + 剩余次数 + 5 档道具/经验 | `DonateUI.lua:48`、`pack_deal.cpp:5263-5286` |
| 3 | 选择档位 | 点击 5 个球体（转盘式） | `m_svrQuality = 6 - curQuality` | `DonateUI.lua:126-156, 184-217` |
| 4 | 执行捐献 | 点击「捐献」按钮发 op7 | 扣 1 个先锋令（或空手）→ 加经验 → 次数 +1 | `DonateUI.lua:107`、`pack_deal.cpp:5287-5390` |
| 5 | 灵气值累积 | 服务端全局自增 | `lingQiValue += point`（5/4/3/2/1），上限 1000 | `pack_deal.cpp:5346-5352, 5374-5380` |
| 6 | 灵魔降生 | 定时器 `LingQiJuanXianTimer()` | 每 5 分钟窗口刷新，按 `lingQiValue` 决定档位 | `main.cpp:1698-1790`（**当前被注释**） |
| 7 | 进入活动 | 活动列表 `EAID 17` → op12 | 随机取帮派前 10 名之一的场景 | `ActivityFunction.lua:148-153`、`pack_deal.cpp:5502-5560` |
| 8 | 击杀灵魔 | 场景内战斗（`EFTLingQiJuanXian = 61`） | 掉兑换币 `EEHDT_BP_LingMo = 18`、经验 0、活跃度 | `scene_manager.cpp:6766-6813`、`fight.cpp:4818-4871` |
| 9 | 17:00 清理 | 定时器 | 清空当日灵魔 NPC | `main.cpp:1700, 1778-1789` |

---

## 4. 来源闭包（证据表）

| 层 | 证据 |
|---|---|
| 入口 | `client/ProjectX/src/core/AppDef.lua:164` `EAID_ANIMA = 4`；`View/Activity/ActivityFunction.lua:56-58` → `InitUI "Activity.DonateManiUI"` |
| 客户端 UI | `View/Activity/DonateManiUI.lua`（96 行，壳；`TabClicked(1)` → `require("View.Activity.DonateUI")`）；`View/Activity/DonateUI.lua`（301 行，主逻辑） |
| UI 资源 | `csd/DonateLayer.csb`（`DonateUI.lua:36`）；`csd/Plist/lingqijuanxian.plist` + `.png`（`DonateUI.lua:34, 52`）；5 球贴图 `AppUIDef.lua:431-435`；火焰 Imod `AppUIDef.lua:436` `Linqi_Fire_Format="donate/lingqi_fire%d%s"` |
| UI 节点 | `Layer/D/Donate/{Bg, LoadingBg/{LoadingBar, NumBg/Value, Image_1..5/{IconBg, EXPText/Value, ItemText/Value}, Icon_1..5}, Times/TimesBg/Value, TipsBg, Button}`（`unityclient/.../documents/csb/DonateLayer.json`，52 节点） |
| 客户端数据 | `Data/LActivityData.lua:4-32` `LLingqiInfo{nowCnt, times, ids, exps}`；挂载点 `Data/Player/LRoleData.lua:415` `m_pLingqi` |
| 协议号 | `NetWork/LuaNetCmd.lua:103` `MSG_CLIENT_HUODONG_OPTION = 199`；服务端 `MSG_HUODONG_OPTION` 注册 `pack_deal.cpp:391` → `CPackageDeal::HuoDongOption`（`pack_deal.cpp:4990`） |
| 客户端发送 | `LuaNetSendMsg.lua:5052` `QueryLingQiButton(op)`；`:5062` `QueryAnimaInfo(op, step)`（op7 时写 1 字节 step）；`:6301` `QueryLingMoInfo()`（op12） |
| 客户端接收 | `LuaNetRecvdMsg.lua:9612-9615` op6/op7 分派；`:9883-9894` `DealDonateInfo`；`:9896-9909` `DealDonateResult`；`:9664-9672` op20（开服时间，非灵气） |
| 服务端 op6 | `pack_deal.cpp:5263-5286` |
| 服务端 op7 | `pack_deal.cpp:5287-5390` |
| 服务端 op12 | `pack_deal.cpp:5502` 灵魔活动传送 |
| 灵魔定时器 | `main.cpp:1698-1790` `CMainClass::LingQiJuanXianTimer()`；`main.h:84` 声明；**调用点 `main.cpp:2997` 被注释** |
| 灵魔刷怪 | `scene_manager.cpp:7340-7413` `AddLingQiJuanXianNPCMonster`；`:7476-7505` `ClearLingQiJuanXianNPCMonster`；`scene_manager.h:824-828` |
| 灵魔战斗 | `scene_manager.cpp:6766-6813` `CScene::LingQiJuanXianFight`；`fight.cpp:4818-4871` `CFight::LingQiJuanXianEnd`；`fight.h:392` `EFTLingQiJuanXian = 61`、`:641` 声明；`scene_manager.cpp:6078` 分发调用 |
| 脚本绑定 | `script_call.cpp:5038` `LingQiJuanXianFight(CUser*)`；`:5300-5303` `GetJuanxianMax`；`:5310-5319` `SetLingMoActivity` / `IsInLingMoActivity` |
| 次数上限 | `server/config/json` ← DB 表 `vip_def`：`huo_dong.cpp:3638-3658` 读 `lingqi` 列 → `G_VipConfig[].lingqi`；全局数组 `utility.cpp:57` / `utility.h:748` |
| 系统编号 | `init.h:795` `SOT_Lingqijuanxian = 4`；`init.h:802` `SOT_Bangpailingmo = 17` |
| 活动时间源 | `init.cpp:2276-2300` `CSystemOpenCfgMananger::Init()` 解析 `function.json`；`init.cpp:2343-2352` `GetFuncLvTime`；`:2321-2332` `CanShow` |
| 玩家计数 | `user.h:1808-1809` `GetLingqiJuanxian()` / `IncLingqiJuanxian()`（`ExtData8(69)`）；每日重置 `user.cpp:9064` |
| 道具 | `server/sql/item_template.sql`：2354 先锋令(绿)、2355 (蓝)、2356 (紫)、2357 (橙)，`type=13`、`quality=2/3/4/5` |
| 活跃/任务 | `mission_config.xml:45` `id=281 [支]灵气捐献(1)`，`doing_target="31-1-0"`、`open_panel="8-4-0"`、奖励 `60006-110000;60000-2000`；判定 `mission_manager.cpp:3789-3797` `EMISS_DC_31`（读 `ExtData8(66)`） |
| 资源找回 | `user.h:144` `EFRT_LingQiJuanXian = 4`；`config/xml/find_resource.xml:6` `find_id=4 normal_find_value=2500 perfect_find_value=5` |
| 兑换币 | `utility.h:240` `EEHDT_BP_LingMo = 18`（帮派灵魔） |
| 文案 | `language_transform.h:1037` 次数用尽 / `:1038`、`:1040` 灵魔公告 / `:1039` 先锋令不足 / `:1050` 灵魔未开启 / `:1052` 30 级提示 |
| 客户端文案 | `Tips.lua:127` `UI_Title_Donate="灵气捐献"`；`:1417` 28 级开启；`:999` VIP≥3 次数增至 4；`:1029` VIP≥6 增至 5 |

---

## 5. 规则明细

### 5.1 捐献档位与收益

| 服务端 type | UI 球（`Lingqi_Ball_n`） | 消耗道具 | 灵气值 `point` | 经验系数 `ratio` | 经验公式 |
|---|---|---|---|---|---|
| 1 | 紫球（`Lingqi_Ball_5`） | 2357 先锋令(橙) | 5 | 1.15 / 3 | `GetLevelUpExp(lv) × GetExpRatio(8,lv) × ratio` |
| 2 | 蓝球（`Lingqi_Ball_4`） | 2356 先锋令(紫) | 4 | 1.0 / 3 | 同上 |
| 3 | 绿球（`Lingqi_Ball_3`） | 2355 先锋令(蓝) | 3 | 0.85 / 3 | 同上 |
| 4 | 白球（`Lingqi_Ball_2`） | 2354 先锋令(绿) | 2 | 0.7 / 3 | 同上 |
| 5 | 黑球（`Lingqi_Ball_1`） | 无（`itemId = 0`，空手捐献） | 1 | 0.6 / 3 | 同上 |

- 经验实现：`huo_dong.h:205-213` `GetHuoDongExp(type=8, level, ratio)`；活动系数表 `HuoDongAddExpInfo.expRatio[130]`（`huo_dong.h:137-161`，注释 `:147` 标明 `type = 8 灵气捐献`）。
- 无道具档位的分支不扣道具、不限道具（`pack_deal.cpp:5368-5382`）；有道具档位道具不足返回 `1039 先锋令不足`（`:5361-5366`）。
- 道具来源（`item_template.sql`）：绿=野外掉落；蓝=杀敌夺宝、背包合成；紫/橙=商城、背包合成；合成规则 3 绿→1 蓝、3 蓝→1 紫、3 紫→1 橙。
- **UI 球色与服务端品质命名不一致**（球名 1–5 = 黑/白/绿/蓝/紫，服务端档位 = 橙/紫/蓝/绿/无），映射靠 `DonateUI.lua:187` `m_svrQuality = 5 - curQuality + 1`；属资源命名滞后，**真机视觉对应需实测确认**（见 §11）。

### 5.2 每日次数上限（DB 驱动，非配置表）

来源 DB 表 `vip_def.lingqi`（`window` 见 `_all_sql.sql:3481-3496`）：

| VIP | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 每日次数 | 3 | 3 | 3 | 4 | 4 | 4 | 5 | 5 | 5 | 5 | 5 | 5 | 5 | 5 | 5 | 5 |

- 校验：`pack_deal.cpp:5299` `GetLingqiJuanxian() >= G_VipConfig[VipLevel].lingqi` → 返回 `1037 灵气捐献次数已经用完，请明天再来。`
- 下发剩余次数：`:5280` `useTimes = G_VipConfig[vip].lingqi - GetLingqiJuanxian()`，负值截 0。
- 每日重置：`user.cpp:9064` `SetExtData8(69, 0)`（`ExtData8(69)` = 当日已捐献次数）。
- 客户端 VIP 描述（`Tips.lua:999` 增至 4 次 / `:1029` 增至 5 次）与上表一致。

### 5.3 灵气值与灵魔档位

- 灵气值：**服务端进程全局变量** `int lingQiValue`（`main.cpp:55`，extern 于 `pack_deal.cpp:41`、`fight.cpp:4818`、`scene_manager.cpp:6764`），受 `boost::recursive_mutex lingQiJuanXian_mutex`（`main.cpp:54`）保护。
- 上限 1000（`:5347-5352` / `:5375-5380`）；跨天清零（`:1713-1721`）。
- 档位判定（`scene_manager.cpp:7365-7372`，取刷怪时刻的 `refreshLingQiValue` 快照）：

| 灵气值区间 | NPC id | 档位 | fightId 段（随机） |
|---|---|---|---|
| ≤ 300 | 154 | 虚弱的灵魔 | 11101–11106 |
| 301 – 600 | 155 | 强壮的灵魔 | 11111–11116 |
| 601 – 900 | 156 | 完美的灵魔 | 11121–11126 |
| > 900 | 157 | 恐怖的灵魔 | 11131–11136 |

### 5.4 刷怪规则（`scene_manager.cpp:7340-7413`）

- 场上灵魔上限 **15** 只（`limitMonsterNum`）；已存在 ≥ 15 直接返回。
- 刷怪点 **20 个固定坐标**（`:7344-7345`，如 `(598,1123)`、`(923,1096)`…），随机取不重复点，已被占用则跳过。
- 场景范围：**帮派前 10 名帮派场景**（`main.cpp:1701` `topBangPaiNum = 10`；`GetBangPaiTopList` → `GetBangPaiScene(BANG_PAI_SCENE_ID, id)`）。
- 时间窗：`minute % 5 <= 2` 且 `flushMonster` 为真时刷一次（`main.cpp:1731-1765`），即每 5 分钟一个 3 分钟窗口。
- 首次刷怪时把 `lingQiValue` 快照进 `refreshLingQiValue`（`:1744-1752`），并发全服公告 `LANGUAGE_SSJ_0152` + 活动旗标。
- 活动结束清图标（`:1771-1777`）；`17:00` 清空余下灵魔（`:1700, 1778-1789`）。

### 5.5 击杀产出（`fight.cpp:4818-4871`）

- 胜利：`AddExp(exp=0)`（**实为 0 经验**）→ `SetExtData32(400) += 1` → `DropExchangeItem(EEHDT_BP_LingMo)` + `DropHDItem(EEHDT_BP_LingMo)` → `SendFightReward` → 删除该 NPC。
- 参与即记活跃度：`CheckMissionHuoYueDu()` + `SetBitSet(303)`（首次参与才计）。
- 失败：`m_pScene->SetNPCMonsterFightFlag(...)` 复位，可再次挑战（`LANGUAGE_TRANSFORM_552`）。
- 战斗创建：`CScene::LingQiJuanXianFight` 按 `pUser->GetVal(1)`（NPC index）在当前场景 `m_dynamicNpc` 中匹配 `id∈[154,157] && index`，`isFight` 已置位返回 1（战斗中）/ 找不到返回 2。

### 5.6 任务、活跃与找回

- 支线任务：`mission_config.xml:45` `id=281 [支]灵气捐献(1)`，`min_level=37`、`weight=0`、`doing_target="31-1-0"`（1 次）、`open_panel="8-4-0"`、奖励 `60006-110000;60000-2000`。
- 任务计数：`ExtData8(66)`（`pack_deal.cpp:5387-5388`，每次 +1，上限 255），由 `VerifyNewBranchMissionFinish(pUser, EMISS_DC_31)` 校验（`mission_manager.cpp:3789-3797`，另有 3533 / 4409 / 4926 三处同项判定）。
- 活跃度：捐献成功即 `CheckMissionHuoYueDu()`（`:5344` / `:5372`）。
- 资源找回：「灵气捐献」为找回项之一（`find_resource.xml:6`，`EFRT_LingQiJuanXian = 4`），单价 `normal_find_value=2500`、`perfect_find_value=5`。

### 5.7 每日重置相关字段

| 字段 | 含义 | 重置点 |
|---|---|---|
| `ExtData8(69)` | 当日已捐献次数 | `user.cpp:9064` ✅ |
| `ExtData8(66)` | 灵气捐献累计次数（任务用） | 未在 `ResetDaily` 列表中出现 ⚠️ |
| `ExtData8(82)` | "灵气捐献每天获取坐骑强化石数量12" | `user.cpp:9076` 仅重置，**无任何读取/写入点** ⚠️ |
| `ExtData8(577/578/579)` | 捐献次数 / 紫令次数 / 橙令次数（`pack_deal.cpp:5355-5359`） | 未见重置点 ⚠️ |
| `ExtData32(400)` | 击杀灵魔计数（`fight.cpp:4855`） | 未核实 |

---

## 6. 协议明细（`MSG_CLIENT_HUODONG_OPTION = 199`）

### op6 — 请求捐献数据（`pack_deal.cpp:5263-5286`）

请求：`[u16 op=6]`
响应：`[u32 lingQiValue][u8 剩余次数][u16 2357][i64 exp][u16 2356][i64 exp][u16 2355][i64 exp][u16 2354][i64 exp][u16 0][i64 exp]`
（5 组「道具 id + 经验」按 橙→紫→蓝→绿→空 排列；`itemId=0` 表示空手档位。）
客户端解析：`LuaNetRecvdMsg.lua:9884-9894`（`nowCnt = ReadUInt`、`times = ReadByte`、5 × (`ReadWord` + `ReadULongInt`)）。

### op7 — 执行捐献（`pack_deal.cpp:5287-5390`）

请求：`[u16 op=7][u8 type]`（`type ∈ [1,5]`，非法值直接 return）
响应：`[u8 PRO_SUCCESS|PRO_ERROR][u32 lingQiValue][string 提示]`（失败时为 `[PRO_ERROR][string]`）
成功提示：`1038`（有道具）/ `1040`（空手）；失败提示：`1037`（次数用尽）/ `1039`（先锋令不足）。
客户端解析：`LuaNetRecvdMsg.lua:9897-9909`（本地 `times - 1`，不重查服务端）。

### op12 — 灵魔活动传送（`pack_deal.cpp:5502-5560`）

请求：`[u16 op=12]`
前置校验：非护送状态（`1048`）、非押镖状态（`1049`）、`IsInLingMoActivity()` 为真且 `topBangPai` 非空（否则 `1050 灵魔活动暂未开启`）、非战斗中（`GetFightId()==0`）、队伍须为队长（队员返回 `1051`）。
动作：随机取一个上榜帮派 id → 内部调用 `BangPai(op=27, id)` 传送。
注：等级校验（30 级，`1052`）**已被注释**（`:5529-5551`）。

### op20 — 开服时间（**与灵气无关，命名遗留**）

`MainUI.lua:225` 通过 `QueryLingQiButton(20)` 发送，实为「七天开服活动换 Icon」查询（`:221-225` 注释）。服务端 `pack_deal.cpp:5684-5690` 返回 `ServerOpenDay + RegDay`；客户端 `LuaNetRecvdMsg.lua:9664-9672` 落到 `PetkaPaiManager` 并触发 `ShowActivityIcon`。

---

## 7. 服务端运行时现状与阻塞（按严重度排序）

| # | 阻塞 | 证据 | 影响 |
|---|---|---|---|
| **P0-1** | 灵魔主循环定时器被注释 | `main.cpp:2997` `// LingQiJuanXianTimer();`（全仓唯一调用点） | 灵魔**永不刷新**；`refreshLingQiValue` 恒 0 |
| **P0-2** | `IsInLingMoActivity()` 恒 `false` | `script_call.cpp:5310-5319` 仅由 `main.cpp:1737/1775` 置位，依赖 P0-1 | op12 恒返回 `1050 灵魔活动暂未开启`，活动入口实际不可用 |
| **P0-3** | `CSystemOpenCfgMananger` 字段缺解析 | `init.cpp:2276-2300` 只读 `function_id / open_condition / type`；但 `CanShow` 用 `cfg->show`（`:2330`）、`GetFuncLvTime` 用 `show_icon / before_time / start_time / end_time`（`:2343-2351`） | 相关字段恒为默认 0 → `CanShow()` 恒 `false`、`GetFuncLvTime()` 恒 `false` → `IsInActivityTime(SOT_Bangpailingmo)` 恒 `false`。**即使恢复 P0-1 也不会刷怪**；是否有第二处赋值路径未发现，见 §11 |
| **P1-1** | SOT 4 与 `function.json` 4 冲突 | `init.h:795` `SOT_Lingqijuanxian = 4`；`function.json` 中 `function_id=4` 为「主线副本」 | 一旦恢复 `CHECK_SYSTEM_OPEN(SOT_Lingqijuanxian)` 会命中错误配置行 |
| **P1-2** | 系统开关校验被注释 | `pack_deal.cpp:5265`、`:5289`、`:5526` | 无等级/开放条件服务端校验；客户端 28 级提示（`Tips.lua:1417`）仅 UI 层 |
| **P1-3** | 灵气值为进程全局变量，未持久化 | `main.cpp:55`（唯一存储）；跨天清零 `:1713-1721` | 重启清零；多进程/跨服不共享；单机化必须改为存档字段 |
| **P2-1** | 客户端进度上限 900 ≠ 服务端 1000 | `AppDef.lua:687-689` `DonateCnt.MaxCnt = 900` vs `pack_deal.cpp:5347/5375` 上限 1000 | 灵气值 > 900 后 `DonateUI.lua:211` 百分比 > 100% |
| **P2-2** | 灵魔击杀经验为 0 | `fight.cpp:4853` `int exp = 0;` | 与「击杀灵魔可获得奖励」的宣导不符 |
| **P2-3** | 死亡/僵尸字段 | `ExtData8(82)`（`user.cpp:9076`）只重置无读写；`ExtData8(577/578/579)` 无重置点 | 语义漂移风险 |
| **P2-4** | `DonateUI` 代码瑕疵 | `:193` 变量名误用（`expBg` 指向 `EXPText`）；`:287-289` 循环变量 `qualityIdx` 与取数索引 `i` 混用；`:15` `times = ""` 初始为字符串 | 可运行但可维护性差，迁移时不宜直接照搬 |

---

## 8. Unity / 单机化现状与缺口

| 项 | 现状 | 证据 |
|---|---|---|
| 模块登记 | **未登记**（39 个模块中无该条目），配置地图标「待梳理」 | `tools/unity-migration/unityclient-modules.json`；`_build_config_map.py:1081` |
| 玩法路由 | **无**灵气捐献路由；`function-routes.json` 中 `functionId 4 = World`（主线副本），17/16 等为 `SteamExcluded` | `unityclient/Assets/ProjectX/Resources/Configs/function-routes.json` |
| Prefab | `res/csd/Prefabs/csb/DonateLayer.prefab` **已批量导入** | Glob 结果 |
| 迁移文档 JSON | `res/csd/UnityMigration/documents/csb/DonateLayer.json`（52 节点，结构完整） | 上述 Glob + 节点导出 |
| Lua 控制器 | **无**（`Resources/Lua/` 下无对应控制器） | `LuaNetSendMsg`/`LuaNetRecvdMsg` 归口在 Cocos 侧 |
| C# 实现 | **无** Store/Presenter/ProjectXApp.* 三件套 | 全仓检索无 `Lingqi` / `Donate` C# 类型 |
| 图集资源 | `res/res/UI/ui_lingqijuanxian/` 仅见 `lingqijuanxian_heiseqiu_new.png`；`lingqijuanxian.plist` 图集未见 Unity 导入 | Glob `**/*lingqijuanxian*` 仅 1 命中 |
| 实现范式（可复用） | `Resources/Lua/Gameplay/MoneyTreeController.lua.txt` + `src/Data/*Store.cs` + `src/UI/*Presenter.cs` + `src/Core/ProjectXApp.*.cs` | 见 `docs/unityclient/modules/MONEYTREE.md`、`FISH.md:81` |

> 「Prefab/文档 JSON 已导入」= 批量导入产物，**不等于实现或验收**；与 `preview:false` 现象同类，不构成缺口证据。

---

## 9. 单机化（Steam）改造要点（建议，待用户决策）

| # | 多人/线上机制 | 证据 | 单机化建议 |
|---|---|---|---|
| 1 | 帮派前 10 名场景刷怪 | `main.cpp:1701, 1758-1764` | 改为**单机固定场景**刷怪，或裁剪为纯「捐献 → 个人收益」闭环（灵魔环节整体排除） |
| 2 | 全服共享 `lingQiValue` | `main.cpp:55` | 改为角色存档字段（SQLite 列），跨天重置；保留 0–1000 与档位语义 |
| 3 | 全服公告（`SysInfoToAllUser` / 活动旗标） | `main.cpp:1749-1751, 1776` | 改本地系统提示 |
| 4 | 每日次数走 `vip_def.lingqi` | `huo_dong.cpp:3658` | 单机无 VIP 成长时，固定取某一档（建议取 VIP0 的 3 次）或改由 `function` 表新增次数字段控制（对齐 FISH 决策 3 的范式） |
| 5 | 复活定时器依赖主循环 | `main.cpp:2997` | 单机可改由玩家侧触发（如「召唤灵魔」按钮）或直接移除 |
| 6 | 灵气值档位 → 灵魔品质 | `scene_manager.cpp:7365-7372` | 保留档位映射（纯数据，无多人依赖） |
| 7 | 击杀掉落 `EEHDT_BP_LingMo` | `fight.cpp:4856-4857` | 取决于活动兑换系统是否纳入单机；若排除则降级为直接入包（同 FISH 决策 5 的处理方式） |
| 8 | 资源找回项 | `find_resource.xml:6` | 单机无离线损失 → 可从找回列表移除 |

---

## 10. 待确认问题

1. `CSystemOpenCfgMananger` 除 `init.cpp:2276` 外，是否存在其它为 `show / show_icon / before_time / start_time / end_time / openWeekday` 赋值的路径？（本次全仓检索未见，需交叉确认）
2. 灵魔档位名称（虚弱/强壮/完美/恐怖）的权威来源是否在 `npc_template` / 文案表中？当前名称仅来自 `scene_manager.cpp:7386-7393` 行内注释。
3. `ExtData8(66)`（灵气捐献累计次数）是否应在每日重置？（当前未重置，与「[支]灵气捐献(1)」的任务语义可能冲突）
4. `ExtData8(82)`（"每天获取坐骑强化石 12"）对应的产出逻辑是否存在于其它模块？
5. 客户端 `ReadULongInt()` 的字节宽度是否与 `int64 exp` 一致（影响协议解析正确性）。
6. UI 球色（黑/白/绿/蓝/紫）与服务端品质（橙/紫/蓝/绿/无）的实际视觉对应，需真机确认。

---

## 11. 诚实边界（未验证项）

- 本文全部结论来自**静态源码与配置阅读**，**未启动服务端、未启动 Cocos/Unity、未做任何真机验证**。
- §7 的「恒 `false` / 永不刷怪」是按代码路径推导的**结构性结论**，未运行时复现；特别是 P0-3 依赖「无第二处赋值路径」这一前提。
- 协议字段字节宽度（尤其 `int64 exp` vs 客户端 `ReadULongInt`）未做抓包校验。
- Unity 侧资源缺口（图集/球贴图）以 Glob 结果为准，未逐一核查 Unity 导入清单（`unity-import-manifest.json`）与 `.meta` 差异。
- 数值上限（1000 / 15 只 / 20 个刷怪点 / 每 5 分钟窗口 / 17:00 清理）为代码常量，未与策划文档交叉比对。
- 本文件**不代表该玩法已被纳入 Steam 单机范围**；纳入与否需用户授权，并按 `docs/unityclient/modules/FISH.md` 的登记四处同步流程执行。
