# 世界/战斗/副本模块

> 状态：2026-08-28 用户真人 Play 后重开；当前 G0-G4 passed，G5-G6 pending。旧 G5-G6、25/25 与 Bootstrap SHA 仅作历史线索。

## 2026-08-28 真人反馈与门禁降级

- 实际缺陷一：点击挑战后 Unity 未消费服务端 `/38 op=5` 内嵌的 `/21` 进入、`/22` 战斗过程和 `/23` 战斗结束，直接使用 `/320 op=8` 弹出结算，导致完整战斗被跳过。
- 实际缺陷二：结算继续仅给 `Layer/Panel` 动态添加 `Button`，Panel 本体没有全屏 `raycastTarget`；旧 Runner 又直接执行 `continueButton.onClick.Invoke()`，因此假通过了玩家鼠标无法关闭的控件。
- 状态处理：撤销 World G4-G6 和 `25/25 complete`；`WORLD-14/21/22` 及新增 `WORLD-28..31` 等待当前证据。旧截图和自动化只能作为定位线索。
- 初版修复：`LegacyTcpMessage` 已支持读取嵌套战报；`WorldBattleReplayStore` 解析真实参战单位、动作组和胜负；`WorldBattlePlaybackPresenter` 仅依据真实战报显示单位/动作进度，完成后才放行 `/320 op=8`；结算 Panel 已补透明全屏射线图形，回归改用 `InvokeEventSystemRaycastClick`。
- 当前结果：当前 Cocos 战斗基准已补齐；前台实测完成挑战→完整战斗→结算→缓存回放→同结算→点击屏幕关闭，回放前后 `type=320` 计数均为 13，未再次挑战。标准固定账号 batch 进一步通过 29/29 控件、5/5 语义断言、重连、切号、Esc 返回、重登稳定哈希、完整恢复与残留 0；中央工具链 248/248。G5-G6 仍待本次修改后的用户复测，禁止提前设置受影响控件 `manualPassed=true`。

## G0 范围冻结

- 唯一入口：`UImainLayer_new/Layer/Main_UI/btn_fuben → MainUI:FuBenTouchCallback → Utils:OpenFunction(EMID_KAPAI_ZHUXIANFUBEN) → FuBenMap.NormalFuBenUI`。
- 本轮包含：世界章节地图、章节关卡地图、关卡详情、主线 `/320 op=1/2/4/5/6/7/8/27`、挑战、扫荡、次数重置、普通/星级宝箱、战斗结算与其可达弹窗。
- 本轮状态：正常、未解锁、体力不足、次数用尽、重置次数用尽、宝箱不可领/可领/已领、挑战成功/失败、重拉、重进、断线重连、切号和精确恢复。
- 冻结 `31` 项源码审计对象：`29` 个实际控件进入当前 G4 自动验收，另 `WORLD-07-WORLD-CLOSE`、`WORLD-24-BATTLE-REVIVE` 两项经源码证明不属于独立 World 控件；完整矩阵：`docs/unityclient/matrices/WORLD_CONTROLS.json`。
- 排除但必须在 Unity 明确隐藏/禁用：支线、帮派副本、封神试炼、排行榜、主线成就、商城加币、体力补给、非 `/320` PvP；`/21-/23` 只允许作为当前 `/38 op=5` 内嵌权威战报消费，不得用假数据或静态图替代。
- 固定验证账号冻结为 `userId=7200057 / roleId=1000115`，终态隔离账号冻结为 `userId=705213 / roleId=1000006`；Fixture 适配器、快照表与 G5 状态对必须先在 G1/G2 以服务端实际数据确定，G3 后启动 Unity 前执行 `Run-UnityFixedAccountValidation.ps1 -Module World -DataPreflightOnly`。
- 当前环境：Cocos、`kapai.exe`、Unity 和工作区 MySQL 均已停止；固定账号已精确恢复。

## G1 Cocos 运行取证（passed）

- 2026-08-28 当前轮使用 Computer Use 对唯一原生 `ProjectX.exe / Cocos Simulator` 执行真实路径：`主界面 → 副本 → 第3章 → 3-3挑战并观察战败 → 3-1挑战 → 胜利结算 → 回放 → 再次结算 → 点击屏幕关闭`。全部点击使用同控件一像素拖动作为该原生窗口当前可用的 press/release 手势。
- 当前战斗画面确认：`30` 回合上限、18 个 `FightLayer.csb` 权威阵位、单位 Imod、进场特效、普攻字样、受击/伤害数字、血条、死亡姿态、三倍速和跳过；单位脚底只显示一行阵营/品质色名称，不显示等级或原始 HP 调试堆叠。
- 当前结算行为确认：胜利后显示三星、奖励、经验、统计、回放和“点击屏幕继续”；回放会重新进入完整战斗，第二次结算后真实点击空白区域关闭并返回同一章节地图。
- 当前 `1334×750` 裁切证据：`.local/ui-fidelity/World/cocos/g1-20260828-battle/02-battle-start.png`、`03-battle-round4.png`、`04-victory-settlement.png`、`05-after-close.png`。原始 `FightLayer.csb` SHA-256 为 `45B119F59AFAA85B9DBFFDAA7AA7875C5001D1ED031DCCC4BB3BF23C16BB0898`，解码证据 `.local/unity-validation/fightlayer-csb-raw.json`。
- 本轮操作前快照哈希为 `a469dc2e6acfc416bfcdc18bc57e7fa42e08c1d92269abc8d43bbf9eba3e8809`。首次误在 Setup 前挑战的单行 `role_info` 变更已由 MySQL ROW/FULL binlog 的 53 列 before-image 精确恢复；正式取证轮 Setup/cleanup 后再次通过同哈希与 Fixture 残留 `0`，证据 `.local/unity-validation/world-cocos-binlog-recovery-latest.json`。
- G1 当前结论：新增 `WORLD-28..31` 的 Cocos 进入战斗、单位/阵位、动作序列、胜利结算、回放和关闭行为图谱齐全；Unity 对照与自动化状态仍保持 pending，不用本轮 Cocos 通过冒充后续门禁。

- 电脑操作已切换为用户指定的 Computer Use 链路；不再使用项目窗口脚本驱动 Cocos。该链路实际完成：`主界面 → btn_fuben → 世界地图 → 第3章解救妲己 → 3-3 黄飞虎详情 → 返回`。
- 当前原生证据均由该工具取得、再裁去窗口边框为 `1334×750`：`WORLD-00` 主界面、`01` 世界地图、`02` 第三章、`03` 3-3 详情、`05` 章节下拉、`06/09` 宝箱领取前后、`07` 真实扫荡、`08` 三星结算、`10` 次数重置确认；目录 `.local/ui-fidelity/World/cocos/g1-20260731-cua/`，`capture-manifest.json` 记录固定账号、窗口和裁切边界。
- 服务端同一会话实际触发 `/320 op=1/2/4/5/6/7/8/27`；`op=6` 扣 25 体力并产出五次扫荡奖励，`op=7` 消耗 50 元宝重置，`op=5→8` 进入真实 PvE 后返回三星结算，`op=4` 后宝箱打开。协议静态提取为 `.local/protocol-evidence/320.md`。
- 可逆数据面：`Invoke-WorldCocosFixture.ps1` 快照 `guan_qia/package/save_data/save_val/user_spirit/mission/角色与账户货币`；两轮操作后均恢复 `1fe6274907b6aef8f631994fa0a7c4d9b17e19fe30e7a5b54ae2a6aca0eca11d`，Fixture 表残留 `0`。启动期 `rank_list_save` 缺列已在本地最小 schema 修复并以固定账号协议 smoke 回归，无该 SQL 错误。
- 前次项目窗口脚本的后台/前台点击失败仅作为工具选择错误，不构成本轮 G1 结论，也不作为证据。
- G1 结论：入口、列表、详情、扫荡、重置、战斗与宝箱的当前 Cocos 证据及 Lua→`/320` 链路齐全。断线重连、切号和异常分支保留 G4 的真实 Unity 验收，不用旧 Runner 或 Unity 假数据替代。

## 历史第一阶段范围（非本轮证据）

- 已完成：世界地图入口、章节列表、章节关卡列表、关卡状态、详情、挑战次数/体力、阵容摘要、奖励预览、一次本地主线挑战、结算奖励、刷新后星级持久化。
- 复用：`HeroStore`、`FormationStore`、`RewardRecord/RewardStore/RewardPresenter`、`ResourceService`、`VirtualList`、`UiStack` 和通用弹窗。
- 不包含：PvP、完整战斗表现、技能特效、自动战斗、数值平衡、扫荡、重置和宝箱领取。

## G0 静态链路（已由 G1/G2 复核）

### 协议与服务端

- 操作码：`server/src/protocol.h` 的 `MSG_GUANQIA = 320`。
- 注册：`server/src/pack_deal.cpp` 将 `/320` 注册到 `CPackageDeal::DealGuanQia`。
- 处理：`DealGuanQia` 分派 `CUserGuanQia`；本阶段锁定 `op=1/2/5/8/27`。

| op | 方向 | 字段与用途 |
|---:|---|---|
| 1 | C→S→C | 请求 `type:u8`；响应章节数量、章节 `id/name/openLv/maxStars`、当前章/关及各章星数/宝箱状态 |
| 2 | C→S→C | 请求 `type:u8,mapId:u32`；响应关卡 `id/name/stars/remainingAttempts/spirit/resets/resetCost/next/box`、货币/物品奖励、星级宝箱 |
| 27 | C→S→C | 查询 `type,mapId,nodeId`；响应 `stars/fightCnt/resetCnt`，`stars=255` 表示未开启 |
| 4 | C→S→C | 领取普通/星级宝箱 `type,mapId,fixId`；状态 `1→2` 后按 `MUT_GuanQiaFix` 发权威奖励 |
| 5 | C→S→C | 挑战 `type,mapId,nodeId`；服务端进入本地 PvE 处理 |
| 6 | C→S→C | 扫荡 `type,mapId,nodeId`；按当前体力及剩余次数取 `0..5` 次，发多段奖励并写次数 |
| 7 | C→S→C | 重置 `nodeId`；按 50/50/100/100/200 元宝梯度扣款、清挑战次数、递增重置次数 |
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

## G2 迁移设计（passed）

- 2026-08-28 当前源码审计补齐完整战斗闭包：`StageInfoUI:challengeEvent → /320 op=5 → /38 op=5 内嵌 /21,/22,/23 → LBattleLogic → FirstFightResultUI`；Unity 只在 World 打开时接管该回放包，结算仍只消费 `/320 op=8` 权威奖励。
- `common/FightLayer.csb` 已用仓库中央 CSB 解码器直接读取；18 个 `Image_N` 坐标、`1334×750` 坐标系、回合 HUD、三倍速和跳过均有当前源证据。玩家源位置 `1..9` 按 Cocos `m_bIsFlipPos` 映射到屏幕右侧 `10..18`，敌方 `10..18` 映射到左侧 `1..9`。
- 单位资源语义闭合为 `Monster/btm{picture}_{zd,gj,sf1,bj,sw}` 和 `res2/fx/zhandoukaishi`；不再用半身像或静态结算代替战斗动作。按当前用户验收隐藏所有常驻脚底名称，仅保留血条、回合/控制文本和瞬时伤害；等级与原始 HP 调试文本明确禁止。
- G2 当前结论：入口、共享协议所有权、配置到资源、运行时 Transform/翻转、文字语义均已写入 `WORLD_CONTROLS.json.sourceAudit`；G3 可继续当前实现与编译，后续门禁仍需实际 Unity 证据。

- 权威边界：`LuaNetSendMsg → /320 → CPackageDeal::DealGuanQia → CUserGuanQia` 是唯一数据和扣费边界；Unity `WorldStore` 只能在 `WorldController.lua.txt` 收到完整成功包后渲染，禁止先写本地扣体力、次数、宝箱或奖励。
- 资源语义：`WorldMapNewLayer` 是世界底图，`DadituuiLayer` 是章节地图（含动态关卡/宝箱和 Timeline），`guanqiaxiangxiLayer` 是关卡详情；扫荡结果为 `FuBenMap.SaoDangResultUI`，战斗结算是当前 Cocos 战斗流结果页，不能用静态奖励弹窗替代。
- 现有 Unity 缺口：`WorldPresenter` 只绑定章节、关闭、详情关闭和挑战，且主动隐藏 `Button_1/Button_3`；`WorldController` 只解析 `op=1/2/5/8/27`。G3 必须补齐 `op=4/6/7`、普通/星级箱状态、扫荡结果、重置确认/失败、真实阵容入口、返回栈、断线重拉与切号清理；排除入口（封神试炼、排行榜、主线成就、商城加币）必须隐藏，不可留空壳。
- 可逆策略：`Invoke-WorldCocosFixture.ps1` 在服务端离线时快照 `guan_qia/package/save_data/save_val/user_spirit/mission/角色与账户货币`，并用整体 SHA-256、恢复后重登与 `unity_validation_world_fixture=0` 断言。G3 后必须先跑 `Run-UnityFixedAccountValidation.ps1 -Module World -DataPreflightOnly`。

- G2 结论：控件矩阵、`/320` 全操作码、服务端实现、资源语义、固定账号与恢复合同已对齐；静态实现只可消费服务端成功包。

## G3 静态实现（passed）

- `/320 op=4/6/7` 的请求与成功/失败包解析已接入；章节、详情、宝箱、扫荡、重置和布阵已连接到现有导入 Prefab。
- 扫荡结果 `fuben/saodangLayer`、战斗结算 `common/zhandoujiesuanLayer`、统计页 `common/zhandoutongji` 已由 `WorldOutcomePresenter` 接入 Bootstrap；结算页只消费 `/320` 成功包，通用 `RewardPresenter` 不再替代 World 结算。
- 继续通过结算页真实 `Panel` 控件触发 `/320 op=1` 重拉；回放通过真实 `Button_Replay` 重新发送 `/320 op=5`。`/320 op=8` 未下发逐单位战报、未定义复活请求，统计/复活以真实导入控件给出明确不可用边界，未写入本地假数据。
- 重置成功后立即 `/320 op=2` 重拉权威次数，未再假设最大次数。扫荡可见性遵循当前 Cocos `stars > 0`，而不是自行提高到三星。
- Unity `BuildBatch` 第二轮干净通过，严重错误 `0`；固定账号 `-DataPreflightOnly` 通过 4 项前置、精确恢复与 Fixture 残留清零。实现、编译和预检证据：`.local/unity-validation/world-g3-implementation.md`。
- G3 结论：29 项实际控件的静态路由、真实 Prefab、Lua 协议路由与 C# 渲染桥接已接入；本阶段未以静态实现冒充动态通过。

## G4 固定账号动态验收（passed）

- 固定账号 `7200057/1000115` 由可逆 Fixture 提供可领普通/星级宝箱、可扫荡关卡、次数用尽与可重置状态；终态隔离账号为 `705213/1000006`。
- 当前 Runner 从真实 `btn_fuben` 进入，覆盖 `/320 op=1/2/4/5/6/7/8/27`、`/38 op=5` 内嵌 `/21-/23`、章节前后切换/下拉/动态行、关卡滚动/详情/布阵、扫荡/再次扫荡、重置、两类宝箱、挑战、完整战斗、结算继续/缓存回放/统计边界、Esc 返回、重连与切号。
- 结果：`29/29` 控件、`5/5` 语义断言、6 张互异 `1334×750` 截图、严重异常 0。原始快照与最终完整恢复哈希均为 `a469dc2e6acfc416bfcdc18bc57e7fa42e08c1d92269abc8d43bbf9eba3e8809`；重登只允许服务端合法归一化 `mission`，其余关卡/背包/存档/体力/等级/货币稳定哈希一致，Fixture 残留 0。
- 证据：`.local/unity-validation/world-fixed-account-latest.json`、`.local/unity-validation/world-fixed-account-timings-latest.json`、`.local/unity-validation/world-fixed-account-data-preflight-latest.json`。

## 历史 G5 双端视觉验收（当前已失效）

- 世界地图、关卡详情、扫荡、重置确认、战斗结算、宝箱状态共 `6/6` 当前双端原图、并排、叠加和差异报告通过人工验收；证据 `.local/ui-fidelity/World/compare/g5-20260731-cua/`。
- Cocos `FuBenDetailUI` 对 `MapPanel` 使用 `750/1080` 缩放；Unity 补齐同一语义后，详情和宝箱布局恢复到同一坐标体系。
- 按用户 2026-08-01 最终要求，扫荡页不按每次战斗分组，而展示“扫荡 N 次收益汇总”，以协议 `{type,id}` 合并所有次数的同类收益；标题和再次扫荡按钮均显示实际 `N`。
- 服务端当前可返回 `type=4603,id=0`，共享 `item_dat.lua/item.json` 缺少 `4601–4604`。World 展示层依据 `equip_dat.lua` 的 `1001–1004` 素心装备和紧邻的 `4605–4608` 青罗碎片连续编号，受控显示“碎片素心衣”及 `petequip_2103` 图标；共享掉落配置未修改。

## 历史 G6 收口（当前已失效）

- `WORLD_CONTROLS.json`：25/25 控件 `complete`，逐控件关联当前 Cocos/Unity `1334×750` 证据；占位、重复 UID、严重异常均为 0。
- `Test-UnityMigrationHardGates.ps1 -Module World -Phase G6` 通过；固定摘要与终态隔离身份分别校验，不再错误要求同一账号。
- `BootstrapSceneBuilder.BuildBatch` 连续执行两次，均报告语义签名未变化并跳过重建；两次 Bootstrap SHA-256 均为 `6A476349E892BF29E845CCA9F37D2292FB0853ADA1868415CAAF982FCD20660C`。
- G6 已登记到 `tools/unity-migration/migration-gates.json`；World 当前状态为 `G0-G6 passed / 25/25 complete`。

## G0 前既有 Unity 实现（历史基线）

- `WorldStore.cs`：章节、关卡、星级宝箱、选中态、挑战状态和结算合并；奖励直接使用 `RewardRecord`。
- `WorldPresenter.cs`：运行时绑定三个只读导入 Prefab；`VirtualList` 渲染关卡，详情复用现有阵容与资源能力。
- `WorldController.lua.txt`：严格解析 `/320 op=1/2/5/8/27`，检查剩余字节并驱动刷新/验证状态机。
- `GameServices/ProjectXApp/ProtocolRegistry/BootstrapSceneBuilder/BootstrapAppRunner`：服务注入、入口、协议登记、场景装配和批处理验收。
- `RewardPresenter`：运行时修正导入 `ItemList` 的异常锚点；未修改导入 Prefab。

## Steam SQLite S5（passed，2026-08-20）

- 双端均从新隔离角色出发，生产路径覆盖`/320 op=1/2/4/5/6/7/8/27`：挑战`10001/10002`、普通箱`10000`领取及重复拒绝、六星箱`20011`、关卡`10001`剩余4次扫荡、首次50元宝重置。
- 运行态SQLite/MySQL分别收到133/135个响应，拥有`/320`均17包且长度一致；12个确定性查询/领取/拒绝/重置包逐包字节一致。两次战斗结算和扫荡使用生产随机奖励，按关卡、星级、宝箱、4轮且每轮`1`组货币+`2`组物品做语义等价，所有原始包保留。
- 重启后两端`/320`各4包全部字节一致：`10001`星级保留、挑战次数归零、剩余重置4；`10002`星级与挑战次数1保留。
- 数据库`guan_qia/save_data/mission`、角色金币/经验/等级、账号元宝/绑定元宝精确一致；体力均为70，仅`lastSpiritTime`因真实执行时刻不同而不同；背包仅随机扫荡掉落不同，确定性奖励更新包一致。
- 只删除隔离MySQL库`fxl_game_world_s5_v1`；正式`fxl_game_local`、MySQL源码/驱动/构建/Schema/脚本/回归继续保留，直到全部模块完成且用户明确通知删除。证据：`.local/unity-validation/steam-sqlite-s5-world-latest.json`。

## 历史验证（非本轮证据）

- 命令：`pwsh -File tools/unity-migration/Run-UnityModuleValidation.ps1 -Module World`。
- 最终隔离账号：`userId=7200008`；阶段账号不再复用。`7200004-7200007` 为启动失败、门禁修正或视觉修正过程账号，不作为最终证据。
- 闭环：入口 → 127 章/第 1001 章 6 关 → 第 10001 关详情 → 阵容/3 项预览奖励 → `op=5` → `op=8` 六项结算 → 重新请求 `op=1/2/27` → 星级 `3` 持久化。
- 服务端真实回包的 `alreadyFightTimes/fightCnt` 在首次本地战斗后仍为 `0`；不伪造该字段，以结算奖励和刷新后三星作为成功证据。
- 截图：`bootstrap-world.png`、`bootstrap-world-detail.png`、`bootstrap-world-result.png`、`bootstrap-world-final.png`，均为 `1334×750`。
- Unity BatchMode 编译/运行通过；严重日志匹配 `0`；UI 转换测试 `10/10`；迁移文档门禁通过。
- 数据边界：变更只落在一次性账号 `7200008`，不复用 Team/Guild 账号，不领取章节/星级宝箱，不执行扫荡或重置。

## 本轮已执行门禁

1. G0-G2 已复核服务端 `/320`、配置、Cocos 动态节点和 Unity Transform，并冻结固定账号、重连/切号合同。
2. G3 已按矩阵绑定真实 Prefab、Lua Controller 与 C# Render Bridge，排除入口保持隐藏。
3. G4-G6 已完成数据预检、动态验收、双端视觉、逐控件证据和双次 BuildBatch。

## 历史遗留

- 支线、帮派副本、封神试炼、排行榜、主线成就按独立模块从 G0 开始，不并入本次 World 结论。
- 完整战斗表现仍需先补齐 `/21-23` 服务端分发及资源证据，再接战斗场景、技能和自动战斗。
- 本地服务首次挑战计数字段仍可能为 `0`；若后续独立战斗模块依赖该字段，应先修复并补服务端语义证据。
