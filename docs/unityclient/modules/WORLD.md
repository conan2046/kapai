# 世界/战斗/副本模块

> 状态：第一阶段完成。主线地图只读链路与一次隔离 PvE 进入/结算闭环已验证；战斗表现深化后置。

## 范围

- 已完成：世界地图入口、章节列表、章节关卡列表、关卡状态、详情、挑战次数/体力、阵容摘要、奖励预览、一次本地主线挑战、结算奖励、刷新后星级持久化。
- 复用：`HeroStore`、`FormationStore`、`RewardRecord/RewardStore/RewardPresenter`、`ResourceService`、`VirtualList`、`UiStack` 和通用弹窗。
- 不包含：PvP、完整战斗表现、技能特效、自动战斗、数值平衡、扫荡、重置和宝箱领取。

## 三方证据

### 协议与服务端

- 操作码：`server/src/protocol.h` 的 `MSG_GUANQIA = 320`。
- 注册：`server/src/pack_deal.cpp` 将 `/320` 注册到 `CPackageDeal::DealGuanQia`。
- 处理：`DealGuanQia` 分派 `CUserGuanQia`；本阶段锁定 `op=1/2/5/8/27`。

| op | 方向 | 字段与用途 |
|---:|---|---|
| 1 | C→S→C | 请求 `type:u8`；响应章节数量、章节 `id/name/openLv/maxStars`、当前章/关及各章星数/宝箱状态 |
| 2 | C→S→C | 请求 `type:u8,mapId:u32`；响应关卡 `id/name/stars/remainingAttempts/spirit/resets/resetCost/next/box`、货币/物品奖励、星级宝箱 |
| 27 | C→S→C | 查询 `type,mapId,nodeId`；响应 `stars/fightCnt/resetCnt`，`stars=255` 表示未开启 |
| 5 | C→S→C | 挑战 `type,mapId,nodeId`；服务端进入本地 PvE 处理 |
| 8 | S→C | 结算推送：`alreadyFightTimes,stageId,unlockedChapter,unlockedStage,box,starBox,stars,rewardCount,rewards` |

- 通用奖励三元组为 `type:u16,id:u32,amount:u32`。货币奖励可使用 `type=600xx,id=0`；显示层保留权威 `id=0`，仅用 `type` 查询现有 `ItemCatalog`。
- `/21-23` 属于旧战斗表现流，当前服务端分发表未形成可验证闭环；本阶段不做无证据旁路。
- `/195` 是场景传送，不等同于卡牌副本 `/320`。

### 旧客户端与真实 Prefab

- 请求：`client/ProjectX/src/NetWork/LuaNetSendMsg.lua` 的 `QueryDituInfo`、`QueryStageInfo`、`QueryFightSatge`、`QueryFuBenInfo`。
- 解析：`client/ProjectX/src/NetWork/LuaNetRecvdMsg.lua` 的 `DealBigMapMsg`、`ReadBattleResult`。
- 入口：旧 `MainUI.lua`，Unity 节点 `Layer/Main_UI/btn_fuben`。
- 页面：旧 `View/FuBenMap/NormalFuBenUI.lua`、`FuBenDetailUI.lua`、`StageInfoUI.lua`。
- Prefab：`fuben/WorldMapNewLayer`、`fuben/DadituuiLayer`、`fuben/guanqiaxiangxiLayer`；结算复用 `common/tanchuangjiangli`，`common/zhandoujiesuanLayer` 只保留为后续战斗表现证据。
- 取证草稿：`.local/protocol-evidence/320.md`。

## 实现

- `WorldStore.cs`：章节、关卡、星级宝箱、选中态、挑战状态和结算合并；奖励直接使用 `RewardRecord`。
- `WorldPresenter.cs`：运行时绑定三个只读导入 Prefab；`VirtualList` 渲染关卡，详情复用现有阵容与资源能力。
- `WorldController.lua.txt`：严格解析 `/320 op=1/2/5/8/27`，检查剩余字节并驱动刷新/验证状态机。
- `GameServices/ProjectXApp/ProtocolRegistry/BootstrapSceneBuilder/BootstrapAppRunner`：服务注入、入口、协议登记、场景装配和批处理验收。
- `RewardPresenter`：运行时修正导入 `ItemList` 的异常锚点；未修改导入 Prefab。

## 验证

- 命令：`pwsh -File tools/unity-migration/Run-UnityModuleValidation.ps1 -Module World`。
- 最终隔离账号：`userId=7200008`；阶段账号不再复用。`7200004-7200007` 为启动失败、门禁修正或视觉修正过程账号，不作为最终证据。
- 闭环：入口 → 127 章/第 1001 章 6 关 → 第 10001 关详情 → 阵容/3 项预览奖励 → `op=5` → `op=8` 六项结算 → 重新请求 `op=1/2/27` → 星级 `3` 持久化。
- 服务端真实回包的 `alreadyFightTimes/fightCnt` 在首次本地战斗后仍为 `0`；不伪造该字段，以结算奖励和刷新后三星作为成功证据。
- 截图：`bootstrap-world.png`、`bootstrap-world-detail.png`、`bootstrap-world-result.png`、`bootstrap-world-final.png`，均为 `1334×750`。
- Unity BatchMode 编译/运行通过；严重日志匹配 `0`；UI 转换测试 `10/10`；迁移文档门禁通过。
- 数据边界：变更只落在一次性账号 `7200008`，不复用 Team/Guild 账号，不领取章节/星级宝箱，不执行扫荡或重置。

## 遗留

- 第二阶段再处理扫荡、挑战重置、普通/星级宝箱、支线与更多章节状态。
- 战斗表现需先补齐 `/21-23` 服务端分发及资源证据，再接战斗场景、技能和自动战斗。
- 本地服务首次挑战计数字段仍为 `0`，若后续业务依赖次数限制，应先修复/补证服务端状态语义。
