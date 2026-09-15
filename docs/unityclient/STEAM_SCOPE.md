# Steam 版本迁移范围

> 本文件只定义 Steam 平台的模块纳入/排除边界，不维护完成率。实时进度仍以根目录 `UNITYCLIENT_STATUS.md` 为唯一来源，机器状态以 `tools/unity-migration/unityclient-modules.json` 为准。

## 强制规则

- 下列 `steam-excluded` 模块不得继续迁移，不得进入 G0-G6，不得补 UI、协议、Prefab、截图或验收证据。
- 不得因为仓库仍保留旧 Unity 实现、Cocos Lua、服务端协议、配置或历史文档，就重新开启迁移。
- Cocos与服务端线上逻辑继续保留，不为 Steam 范围决策删除或改写。
- 两个中央 Runner 会读取 `migrationExcluded=true` 并拒绝执行；禁止通过手工 PlayMode、临时脚本、MCP或直接调用内部方法绕过。
- 只有用户明确改变 Steam 产品范围后，才能同时修改本文件、`UNITYCLIENT_STATUS.md`、Manifest、入口配置和 Runner 门禁。

## 已排除模块

| Manifest Key | 中文范围 | Steam处理 |
|---|---|---|
| `SevenDay` | 七日目标、HUD 7日活动 | 玩法大厅与HUD入口隐藏；路由和验收关闭 |
| `Funds` | 成长基金、活跃基金、全部基金 | 玩法大厅隐藏；支付/领取不迁移 |
| `ResourceRecovery` | 资源找回 | 玩法大厅隐藏；查询/找回不迁移 |
| `Welfare` | 福利、在线奖励 | HUD入口及在线奖励隐藏 |
| `StaminaClaim` | 体力领取 | 作为福利子模块排除，玩法大厅隐藏 |
| `Friend` | 好友、好友赠送 | HUD和玩法大厅入口隐藏 |
| `Chat` | 聊天、HUD聊天条 | 入口及聊天条整体隐藏 |
| `Team` | 队伍 | 入口隐藏 |
| `Guild` | 帮派、宗门 | 主体入口隐藏；帮派种植、神树继续暂停；已拆出的单人玩法按下方例外处理 |
| `Activity` | 运营活动、首充、充值、折扣礼包 | 主体排除；HUD对应入口隐藏，`/222`不得重新显示折扣入口；不包含下方明确恢复的单人玩法 |
| `KunLun` | 决战昆仑 | 玩法大厅隐藏；匹配对手及共享红点 `/213 op=25` 不再请求 |
| `BloodFight` | 血战到底 | 玩法大厅隐藏；全服血战排行榜不迁移 |
| `Arena` | 竞技场 | 用户于2026-08-31确认当前版本保持屏蔽；玩法大厅入口、每日任务和战斗验收不迁移 |
| `BattleScript` | 师门、心魔、藏宝图旧脚本战斗 | 用户于2026-08-31明确不需要；不创建Unity入口或战斗验收 |

## 当前保留范围

- 单人玩法：游历三界、封神列传、法宝搜索、每日任务、闯关、摇钱树、每日答题、欢乐转盘及已纳入的基础功能。
- 用户于2026-09-12明确恢复三个单人玩法：`function_id=21` 闯关、`23` 摇钱树、`29` 欢乐转盘；入口统一进入玩法大厅，开放条件、名称、图标、描述由正式 `function.xlsx` 生成链驱动。
- 用户于2026-09-13明确恢复 `function_id=27` 每日答题，仅Unity使用玩法大厅直达流程；Cocos旧NPC流程不修改。
- 玩法大厅当前列表固定为 `function_id=1/3/9/10/21/23/27/29`。帮派种植与神树仍不展示。

- 用户于 2026-09-14 明确将钓鱼（`EAID=6`）纳入 Steam 单机范围，并要求按「单机化玩法」迁移与修改；同日持续确认产品落地决策。
  - **移除**：房间列表与房间人数、房间内玩家列表与钓鱼玩家列表广播、**抢夺他人鱼（用户决策：直接删除）**、稀有鱼全服播报。
  - **保留**：**钓鱼地图**（场景 `54` = 瑶池，`map_id=33`，`server/config/dat/map33.map` 存在）、固定钓位 `(1086,619)`/`dir=2`/`flip=true`、传入后立即显示原版 `ShapeId=2000` 钓鱼造型（开始后才进入权威Fishing，收竿回持竿待机，退出恢复正常角色）、容量9999格鱼篓（同种鱼优先补未满格，单格上限999，满后新增同鱼种格，每格右下角显示数量；10只是当前鱼种数；9999格均占用且无同鱼未满格时新鱼直接舍弃）、每轮独立随机10–20秒产出、首版10种配置化鱼道具。
  - **移除**：旧主角钓鱼经验、`EEHDT_Fish` 交互币掉落及其日计数；交互币原为独立限时兑换材料，不是垂钓消耗。
  - **改造**：限时活动窗 `12:30-12:50` 取消；解锁由 `function` 表控制（入口 `function_id=32`，10级开放），每日不限次且不新增次数/扣次字段；成功放竿扣配置金币100；周期、容量、鱼种与权重改为配置驱动。
  - 模块登记见 `tools/unity-migration/unityclient-modules.json` 的 `Fish`；范围与设计见 `docs/unityclient/modules/FISH.md`。
- 钓鱼 `function_id=32` 已写入正式 Excel、服务端/Unity JSON，并已接入 `Resources/Configs/function-routes.json` 与玩法大厅真实入口；固定账号 G3 真实点击回归通过，等待用户 Unity Play 体验确认。
- 钓鱼地图前置：Unity 客户端当前**没有场景地图渲染与走位/传送能力**（C# 侧无地图渲染、无 `Transport` 进出场景实现）。用户已决策采用 `FISH.md` §5A **方案 B**：模块内保留地图呈现 —— 正式场景由用户维护在 `FishLayer.prefab/FishUI/FishScene`，角色运行时直接挂到其 `pos` 子节点，不再由 Presenter 动态加载底图或计算坐标；不提供钓点选择，**不引入行走、寻路与场景传送**。传入后立即切 `ShapeId=2000` 钓鱼造型，点击开始固定发 `QueryFishingInfo(5,2)`。原版正式 `Monster/btm2000_zd.png/.ani` 已恢复并转换为 Unity 40帧/5动作资源。方案 A（框架级地图能力）与方案 C（纯 UI）均不在本次范围。
- 玩法大厅已新增钓鱼入口，10级开放；Cocos 运行表现按用户授权不作为本模块验收基线。

## 新任务启动检查

1. 先读本文件和 `UNITYCLIENT_STATUS.md`。
2. 在 `tools/unity-migration/unityclient-modules.json` 检查目标模块是否有 `migrationExcluded=true`。
3. 若已排除，立即停止该模块；不得启动 Cocos、Unity、服务端或 Fixture。
4. 若未排除，才按 `MIGRATION_GUIDE.md` 从当前门禁继续。
