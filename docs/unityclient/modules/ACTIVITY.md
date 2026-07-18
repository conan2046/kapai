# UnityClient 活动模块证据

## 1. 范围与版本结论

- 当前活动入口是 `client/ProjectX/src/View/MainUI.lua` 的 `UImainLayer_new/ButtonGroup5/btn_huodong`。
- 点击回调直接执行 `Utils:InitUI("WelfareActivity.WelfareActivityFormerUI", SpecialLayer, 1)`。
- 旧 `/209 + View/Activity/ActivityLayer` 属于另一代“玩法”，不在本模块范围，也不计迁移完成度。
- `/222` 是复用型临时活动协议；本阶段只迁移当前入口首包 `op=0xFF` 和首个真实子页“每日首充” `op=18, subOp=1`。既有福利模块继续使用 `/222 op=4`，由统一 Lua 分发器按首字节路由。

## 2. 当前调用链

```text
csd/common/UImainLayer_new.csb
  → MainUI.lua: ButtonGroup5/btn_huodong
  → WelfareActivity.WelfareActivityFormerUI(openTab=1)
  → csd/huodong/ActivityRankingLayer.csb
  → csd/huodong/ActivityLevelLayer.csb
  → QueryWelFareInfo(0xff, 0)
  → /222: [u8 0xff]
  → HuoDongTmpOption / HD_ALL_LIST
  → MakeHuoDongList
  → LuaNetRecvdMsg.DealMsgKaifuHuodong(op=0xff)
  → InitListData → 左侧活动 Tab
  → 首 Tab tag=1 → DailyRechargeUI
  → csd/DailyChargeLayer.csb
  → QueryKaifuHuodong(18, 1)
  → /222: [u8 18][u8 1]
  → HuoDongTmpOption / HD_MEIRI_SHOUCHONG
  → DealMsgDayRecharge → ReloadData → 每日首充状态与奖励
```

完整相对路径来自 Lua 非注释 `createNode` 调用；仓库根目录还存在同名 `ActivityLevelLayer.csb`，当前链未调用，禁止替代 `csd/huodong/ActivityLevelLayer.csb`。

## 3. 协议字段

`server/src/protocol.h`：`MSG_TMP_HUODONG = 222`；`server/src/pack_deal.cpp` 注册到 `CPackageDeal::HuoDongTmpOption`。

### 3.1 活动列表 `/222 op=0xFF`

| 方向 | 字段 | 宽度 | 说明 |
|---|---|---:|---|
| C→S | command | u16 | 222 |
| C→S | op | u8 | `0xFF` / `HD_ALL_LIST` |
| S→C | op | u8 | 请求消息复用并追加，仍为 `0xFF` |
| S→C | count | u8 | 当前时间内、`isShow=1` 的条目数 |
| S→C | tag | u32 | `CHuoDongAwardManager` 活动类型，不等于 `EMD2_HuoDong` 请求 op |
| S→C | uname | string | `huodong_info.name`，Unicode 字符串 |
| S→C | state | u8 | `GetHuoDongHotPoint` |
| S→C | newMask | u8 | `GetHuoDongNewSign` |
| S→C | endTime | u32 | 距累计/结束时间的剩余秒数，不是 Unix 时间戳 |

`count=0` 是合法空态，服务端仍回包；无统一 success 字节。

### 3.2 每日首充 `/222 op=18`

| 方向 | 字段 | 宽度 | 说明 |
|---|---|---:|---|
| C→S | command/op/subOp | u16/u8/u8 | `222 / 18 / 1` 查询；`subOp=2` 领取，`3` 微信领取 |
| S→C | op/subOp | u8/u8 | 请求消息复用并追加 |
| S→C | success | u8 | `1` 成功、`0` 失败 |
| 失败 | message | string | 活动未开启、未充值、已领取或非法 subOp |
| 查询成功 | wxSign | u8 | 是否显示微信奖励 |
| 查询成功 | charged/claimed | u8/u8 | 普通首充及领取状态 |
| 查询成功 | wxCharged/wxClaimed | u8/u8 | 仅 `wxSign=1` 时存在 |
| 查询成功 | rewardCount | u8 | 奖励条数 |
| 查询成功 | rewardType | u16 | `60002` 为神将并改走 `ReadPetInfo`；本阶段夹具禁止该类型 |
| 查询成功 | amount | u32 | 非神将奖励数量 |

## 4. 服务端分支

- `op=0xFF`：`MakeHuoDongList` 遍历启动时缓存的 `huodong_info`；只追加进行中条目，然后必定发送，包括空列表。
- `op=18, subOp=1`：活动进行中时发送成功状态、普通/微信状态及当月日对应奖励；奖励配置为空时 `rewardCount=0` 仍是成功包。
- `op=18, subOp=2/3`：未充值、已领取返回失败字符串；满足条件才改角色位、发奖励并发送成功。
- `op=18` 非法 subOp：返回 `PRO_ERROR + string`。
- 活动不在有效时间：返回 `PRO_ERROR + string`。
- 未知 `/222 op`：`HuoDongTmpOption` default 不发送；Unity 不伪造响应或 COMPLETE。

## 5. CSB、Timeline 与 Imod

| 作用 | 当前 Cocos 路径 | Unity Prefab |
|---|---|---|
| 活动内容壳 | `csd/huodong/ActivityRankingLayer.csb` | `Prefabs/huodong/ActivityRankingLayer.prefab` |
| 左侧 Tab/背景/关闭 | `csd/huodong/ActivityLevelLayer.csb` | `Prefabs/huodong/ActivityLevelLayer.prefab` |
| 每日首充子页 | `csd/DailyChargeLayer.csb` | `Prefabs/DailyChargeLayer.prefab` |

- 三个当前 CSB 没有 Lua `createTimeline` 调用，也未导入有效 Timeline 播放组件。
- `DailyRechargeUI.ShowIcon` 仅在奖励品质 `>=5` 时动态播放 `res2/fx/gaojiwupin`；对应 ANI/PNG 已存在并已转换到 `ProjectXAnimation/res2/fx/gaojiwupin`。本阶段夹具使用普通货币奖励，不触发高品质特效。

## 6. Unity 实现与偏差

- `ActivityStore` 保存服务端活动列表、红点、新标签、倒计时快照和每日首充权威状态。
- `ActivityPresenter` 只读实例化三个真实 Prefab，运行时重挂层级、生成列表项、绑定 Tab/关闭/按钮并重绘；不改 Prefab 文件。
- `ActivityController` 负责 `/222 op=0xFF/18` 写包与读包；`TempActivityController` 只读一次共享 op，再路由 Activity 或 Welfare，避免两个 Controller 竞争同一消息游标。
- 当前 Cocos 对 `tag=1` 映射每日首充；请求 op 为 `18`。Unity 保留这两个枚举域的差异，不把 tag 误当请求 op。
- 未迁移的真实活动 Tab 显示明确空边界，不调用未知协议，不伪造奖励或成功。

## 7. 第一阶段完成边界

完成：当前主界面活动入口、真实活动壳、服务端列表、Tab/红点/新标签/倒计时、每日首充查询状态、非神将奖励展示、真实未迁移 Tab 空边界、返回主界面。

未完成：`tag=2+` 各节日、排行、累计充值/消费、砸蛋、七日充值、神将折扣等子页；`op=18 subOp=2/3` 实际领取；充值 SDK；神将型奖励 `ReadPetInfo`；高品质奖励 Imod 动态展示。

## 8. 动态验证

| 项 | 结果 |
|---|---|
| 命令 | `pwsh -File tools/unity-migration/Run-UnityModuleValidation.ps1 -Module Activity` |
| 隔离账号/角色 | `userId=7200020`、`roleId=1000034` |
| 协议 | `SEND/RECV cmd=222 request=5` 后列表 `2 entries`；`SEND/RECV cmd=222 request=6` 后 `op=18 subOp=1 rewards=1, recharged=False, claimed=False` |
| 最终状态 | `bootstrap-app-result.json success=true`，UTC `2026-07-18T04:12:06.7360915Z` |
| 截图 | `bootstrap-activity-detail.png`、`bootstrap-activity-empty.png`、`bootstrap-activity.png`，均要求 `1334×750` |
| 异常 | `error CS\d+ / LuaException / NullReferenceException / MissingReferenceException / Assertion failed / Fatal Error / Crash!!!` 命中 `0` |
| 数据清理 | Manifest 在 MySQL 启动后、`kapai.exe` 启动前备份并注入 `huodong_info/huodong_award`；finally 精确恢复。审计 `fixture_info=0`、`backup_tables=0` |
