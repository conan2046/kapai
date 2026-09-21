# 钓鱼模块（Steam 单机化）

> 当前状态：2026-09-15 单机钓鱼 G3 逻辑与正式 UI 定向检查已通过；固定账号 `7200057/1000003` 的两轮 `/217` 计时产出、扣费/续钓/领取/停止/退出，以及复用背包鱼篓的纵向真实拖动均已验证。用户已在最后一次 `FishLayer.prefab/FishScene/pos` 挂点与统一顶部层级调整后完成实际测试并确认无误，`manualPassed=true`；G4-G6 尚未执行。
> 2026-09-15 根据首次体验反馈完成正式 UI 收敛：钓场操作区复用 `FishLayer.prefab`，鱼篓直接复用 `zhujue/beibao.prefab` 的五列格子、品质框、详情区与 `OneLevelLayer` 外框；鱼篓为纵向 `ScrollRect`，数量显示在格子右下角，不再使用运行时代码绘制的纯色面板与按钮。

## 1. 范围决策（用户授权）

- 决策来源：2026-09-14 用户口头确认「基于 Steam 平台进行单机化玩法迁移和修改」，并持续明确入口、地图、消耗、周期、容量、鱼种、经验、交互币与 Steam 分母等规则。
- 与 `STEAM_SCOPE.md` 的关系：钓鱼此前既未列入 `steam-excluded`，也未列入保留范围；本次为**新增纳入**，已同步 `docs/unityclient/STEAM_SCOPE.md`、`UNITYCLIENT_STATUS.md`、`tools/unity-migration/unityclient-modules.json`（含 `steamProgressPolicy.denominator` 18→19）。
- 当前唯一活动范围已切换为 `Fish`（见 `UNITYCLIENT_STATUS.md` §1），本轮只处理钓鱼 G0，不与其他模块并行。

### 1.1 已确认落地决策（2026-09-14）

| # | 决策项 | 结论 | 证据 / 说明 |
|---|---|---|---|
| 1 | 钓鱼地图 | **保留** | 原版独立场景 `scene_id=54`、`name=瑶池`、`map_id=33`（`server/sql/_all_sql.sql`）；`server/config/dat/map33.map` 存在；`server/src/scene_manager.h` `FISH_ID2=54`。**但 Unity 端当前无场景地图能力，见 §5A 前置阻塞** |
| 2 | 玩法入口 id | **沿用 `function_id=32`** | 已核实原表空闲，正式 Excel/JSON、Unity 路由与玩法大厅入口均已接入 |
| 3 | 解锁与次数控制 | **10级开放；每日不限次；无扣次** | `function_id=32` 的 `open_condition` 配置10级；不新增每日计数、扣次或重置字段 |
| 4 | 抢夺他人鱼 | **直接删除** | 不保留单机替代玩法（原列「NPC 水怪偷鱼」提案作废）；同步移除每日抢夺/被抢上限、120s 被抢锁定、`EFOP_GrabFish=7` 客户端入口 |
| 5 | 钓鱼经验 + 交互币掉落 | **删除** | 旧经验链只给主角 `AddExp`，当前主角不需要经验；旧交互币是限时兑换活动材料，不是钓鱼消耗，当前单机版无兑换配置/入口 |
| 6 | Steam 业务模块分母 | **18 → 19** | `unityclient-modules.json` `steamProgressPolicy.denominator=19`；`UNITYCLIENT_STATUS.md` 进度由 `8/18=44.4%` 更新为 `8/19=42.1%` |
| 7 | 地图呈现方式 | **方案 B：场景54假传送 + 固定钓位 + 入场即钓鱼造型** | 不引入真实场景切换、行走或寻路。进入模块即加载 `map33.jpg`，把玩家固定在原1号区域内用户圈选位置 `(1086,619)`，`dir=2`、`flip=true`，并立即将正常角色模型切换为原版钓鱼造型 `ShapeId=2000`；此时业务状态仍为待开始，不扣金币、不启动倒计时。点击“开始钓鱼”后才发送 `QueryFishingInfo(5,2)` 并进入权威钓鱼状态。详见 §5A |
| 8 | 垂钓周期 | **每轮独立随机10~20秒** | 每轮开始时等概率抽取包含上下限的整数秒，本轮固定、下轮重抽；以服务端时长为准 |
| 9 | 鱼篓结构 | **容量9999格；同种鱼单格堆叠上限999** | 10仅为当前鱼种数，不是固定格数；同种鱼优先补已有未满格，达到999后再占一个新格；每格右下角显示数量。例如鲫鱼1000条占两格：999+1。已占满9999格且该鱼无可补堆叠时，新获得的鱼直接舍弃 |
| 10 | 鱼种与权重 | **首版10种、全部配置化** | 保留青鱼580=50、鲶鱼581=35、娃娃鱼582=15；新增7种见 §6；权重为相对值，不要求合计100 |

### 1.2 单机化边界

- **移除**：房间列表与房间人数、房间内玩家列表与钓鱼玩家列表广播、**抢夺他人鱼（整条链路，直接删除）**、稀有鱼全服播报、限时活动窗 `12:30-12:50`、多人副本实例语义（`GetFishingRoom()` 按人复制副本 → 单机固定单实例）。
- **保留**：**钓鱼地图（场景54 / 瑶池 / map33；方案 B：假传送进入独立钓鱼页面，玩家固定在 `(1086,619)`，入场立即显示 `ShapeId=2000` 钓鱼造型，不引入真实传送、行走、寻路或钓点选择）**、容量9999格鱼篓（同种鱼单格上限999，优先补未满同种格，满后新增格，每格显示数量）、单轮10~20秒动态产出、当前10种配置化鱼道具与品质。
- **删除**：每轮主角经验、`DropExchangeItem(EEHDT_Fish)` 交互币掉落以及其日计数。
- **改造**：解锁改由 **`function` 表** `open_condition` 统一控制；每日不限次，不建立次数状态；每次有效放竿请求成功时扣除100金币（配置表可调），余额不足或放竿失败不扣除；鱼种与概率由硬编码改为 `fish` 配置表驱动。

> 口径提示：「保留地图」与「移除副本实例语义」不矛盾 —— 地图资源与场景 54 保留，但不再按玩家数创建/切换副本实例。

## 2. 来源闭包（Cocos + 服务端）

| 层 | 证据 |
|---|---|
| 入口 | `client/ProjectX/src/core/AppDef.lua:166` `EAID_FISH = 6`；活动跳转 `client/ProjectX/src/View/Activity/ActivityFunction.lua:142-146` → `LuaNetSendMsg:QueryFishingInfo(2, 0, -1)` |
| 客户端 UI | `View/Activity/FishUI.lua`（3.2KB，壳）+ `FishBasketDelegate.lua`（8.7KB，鱼篓）+ `FishControlDelegate.lua`（5.6KB，开钓/收杆）+ `FishUserListDelegate.lua`（10KB，房间/玩家列表）；资源 `res/csd/FishLayer.csb` |
| 钓鱼造型 | `HeroNode::SetFishingMode(true, face)` 将角色 `ShapeId` 改为 `2000` 后调用 `HeroDataChanged()`；`MapModelAni` 对 `ShapeId>0` 按 Monster 模型加载 `Monster/btm2000_zd.png/.ani`；`MapObjNode::RecvFish` 在 op5 成功时传入服务端 `face`，玩家状态更新类型13也会恢复该造型。已从原项目正式资源库恢复到 Cocos，并转换为 Unity 40帧/5动作资源，未使用普通角色站立或占位图 |
| 协议 | 服务端 `server/src/protocol.h:315` `MSG_FISH = 217`；活动类型 `server/src/init.h:797` `SOT_Fish = 6`；客户端 `client/ProjectX/src/NetWork/LuaNetCmd.lua` `MSG_FISHING_INFO = 217` |
| 客户端收发 | 发送 `LuaNetSendMsg.lua` `QueryFishingInfo(op, roomId, idx)`（op2 写 UInt roomId / op5 写 Byte roomId / op7 写 UInt roomId + Byte idx）；接收 `LuaNetRecvdMsg.lua` `DealMsgFish` |
| 服务端 | `server/src/huo_dong.h:304` `CFishManager`（**17 个 op，编号 0-16**：0 错误、1 房间列表、2 加入、3 钓鱼玩家列表、4 鱼篓、5 开始钓鱼、6 收获、7 抢夺、8 倒计时、9 离开、10 停止、11 钓到鱼、12 活动开始、13 活动结束、14 更新钓鱼列表、15 玩家列表、16 更新玩家列表）；`CFishRoom` / `CFishData` 实现在 `server/src/huo_dong.cpp` |
| 场景（本次保留） | `server/sql/_all_sql.sql`：`game_scene id=54 name=瑶池 map_id=33`；`server/config/dat/map33.map` **存在**；`server/src/scene_manager.h` `FISH_ID2 = 54`；`server/src/scene_manager.cpp:8464` `CSceneManager::GetFishingRoom()` 每次复制一份副本场景并用 `m_curFuBenId++` 作为实例 id |
| 鱼道具 | `server/sql/item_template.sql`：`580 青鱼`（品质 3，售价 100）、`581 鲶鱼`（品质 4，售价 1000）、`582 娃娃鱼`（品质 5，售价 2000），`type=19`、`item_source=来源：钓鱼` |

## 3. 原版机制与多人依赖点

- 产出：`server/src/user.cpp:16284` `CUser::TryFishTimeout()` —— `res = Random(1,100)`：`≤15` → 582（15%）、`≤50` → 581（35%）、其余 → 580（50%）；每 `FISH_TIME=60` 秒一条，鱼篓满 4 格时自动把最早一条发背包（`CFishData::AddFish`）。
- 经验：`SingletonHuoDongExpManager.GetHuoDongExp(11, lv, 0.05)`。
- 交互币：`DropExchangeItem(EEHDT_Fish=15)` 从 `hd_exchange_drop` 读取活动材料，命中后绑定入包并通过 `ExtData8` 限制掉落次数；它只在 `hd_exchange_list` 限时兑换配方中作为 `material` 被消耗。当前种子两表均无有效数据，单机版删除该链。
- 鱼道具使用：旧 `drop_matching.xml` 将 580/581/582 映射到 `level_reward_id=60601/60602/60603`，使用后分别发放1级/更多1级/2级坐骑强化石（2251/2252）并消耗鱼。当前 `item.json` 缺失这条完整现行镜像，新鱼用途将由配置字段统一控制，不默认继承旧坐骑奖励。
- 活动窗：`CFishManager::IsInHuoDongTime()`（`huo_dong.cpp:23001` 后）判 `12:30 ≤ now < 12:50`；`GetRoomList` / `JoinRoom` 均先校验。
- 房间制：`CFishRoom::MAX_MAN = 25`、`MAX_FISHER = 20`；`CFishManager::CheckCreateRoom()` 按人数自动建房。
- 抢夺：`CFishRoom::GrabFish` / `GrabFishSuccess`（`huo_dong.cpp:15341`）；每日抢夺上限 `MAX_GRAB_COUNT = 5`（`GetExtData8(63)`）、被抢成功上限 `MAX_BE_GRABED_COUNT = 10`、被抢后 120s 内不可收获（`FISH_GRAB_TIMEOUT`，`CFishData::GetFish` 校验 `m_grabedTime`）。**本次决策：整条链路直接删除。**
- 全服播报：命中 582 时 `SysInfoToAllUser`（`user.cpp:16309` 附近）。
- 入场校验：`JoinRoom` 内 `HaveTeam()`、`CanJoinActivity()`、`GetFightId()>0`、`CanWorldTransPort(FISH_ID2)`，等级门槛 `HUO_DONG_LEVEL = 27` 已被注释掉。
- 场景依赖：`JoinRoom` 通过 `CanWorldTransPort(FISH_ID2)` 进入场景 54，`m_fishSceneSrcId` 记录返回场景，`GetFishingRoom()` 复制副本场景实例。**保留地图意味着该链路必须保留或等价替代，见 §5A。**

## 4. 单机化改造设计

| # | 多人机制 | 原版证据 | 单机化方案 | 协议影响 |
|---|---|---|---|---|
| 1 | 房间列表 | `EFOP_RoomList=1`、`CFishManager::GetRoomList` | 不展示房间，客户端不再请求 | 停用 op1（服务端保留） |
| 2 | 加入房间 | `EFOP_Join=2`、`QueryFishingInfo(2,0,-1)` | `roomId` 固定 1 | op2 语义不变 |
| 3 | 房间玩家列表 | `EFOP_PlayerList=15` / `EFOP_UpdatePlayerList=16`、`SyncPlayerList` | 不渲染他人，服务端只回自己 | 停用 op15，忽略 op16 |
| 4 | 钓鱼玩家列表 | `EFOP_FisherList=3` / `EFOP_UpdateFisherList=14`、`SyncFisherList` | 同上 | 停用 op3，忽略 op14 |
| 5 | 查看他人鱼篓 | `EFOP_FishList=4` + `tarRoleId` | 只查自己 | op4 保留，参数固定为本人 |
| 6 | 抢夺他人鱼 | `EFOP_GrabFish=7`、`GrabFishSuccess`、上限 5/10 | **直接删除**：服务端移除 op7 分支与 `GrabFish*` 实现，客户端移除入口与 `QueryFishingInfo(7,…)` 调用 | op7 废弃（不再收发） |
| 7 | 稀有鱼全服播报 | `SysInfoToAllUser` | 改为本地系统提示 | 无 |
| 8 | 限时活动窗 | `IsInHuoDongTime()` `12:30-12:50` | **取消限时窗**：删/短路 `IsInHuoDongTime()`，解锁由 `function.open_condition` 控制；每日不限次，无次数字段 | 无 |
| 9 | 独立副本场景 54 | `FISH_ID2=54`、`GetFishingRoom()` | **保留场景54表现（方案 B）**：像闯关一样加载独立 `FishLayer` 与 `map33.jpg`，不执行真实场景传送；玩家固定在 `(1086,619)`，入场立即显示 `ShapeId=2000` 钓鱼造型，不提供3钓点选择 | op2只负责进入/查询单机钓鱼页面；op5固定 `dir=2`，成功后才进入权威钓鱼状态 |
| 10 | 组队/跨服/战斗互斥 | `JoinRoom` 内 `HaveTeam` / `CanJoinActivity` / `CanWorldTransPort` | 单机短路为常量放行（保留 `CanWorldTransPort(FISH_ID2)` 以维持地图进入） | 无 |
| 11 | 鱼种、消耗与周期硬编码 | `user.cpp:16303-16324`（580/581/582，15/35/50，60s） | 新增 `fish_settings` + `fish_reward`：金币消耗100、每轮独立等概率随机10~20整秒、鱼篓容量9999格、同种鱼单格上限999并按“先补栈、后开格”存放、当前10种鱼权重可配 | 服务端需在每轮开始时生成并回传当轮时长 |
| 12 | 钓鱼经验 | `GetHuoDongExp(11, lv, 0.05)` | **删除**：不再读取经验活动档位，不调用 `AddExp`，不保留 `exp_ratio` 配置 | 无 |
| 13 | 交互币掉落 | `DropExchangeItem(EEHDT_Fish)` | **删除**：不创建单机交互币，不接 `hd_exchange_drop/hd_exchange_list`，不占用 `ExtData8` 日计数 | 无 |
| 14 | 被抢 120s 锁定 | `CFishData::GetFish` 校验 `m_grabedTime` | 随第 6 项一并移除 | 无 |

## 5. Unity 现状与缺口

- 资源：`unityclient/Assets/ProjectX/res/csd/Prefabs/FishLayer.prefab` + `res/csd/UnityMigration/documents/FishLayer.json`，来源 `cocosstudio/csd/FishLayer.csd`；在 `unity-import-manifest.json` 中为 `documents[78]`，`preview:false`。
  `preview:false` 与已完成的 `AnswerLayer`（documents[62]）、`GoldTreeLayer`（documents[129]）一致，**只表示预览场景开关，不构成迁移缺口**。
- 协议层：`unityclient/Assets/ProjectX/Resources/Lua/` 下无 Fish 控制器。
- 路由：`unityclient/Assets/ProjectX/Resources/Configs/function-routes.json` 无 `Fish` 行（现有行仅覆盖 1/2/3/4/6/7/8/9/10/11/12/13/15/16/17/18/19/21/23/25/26/27/29/1010/1011/1120/1130/1182/1222/2120/2128）。
- 入口配置：正式 `function.xlsx`、服务端/Unity JSON 已增加 `function_id=32`；`function-routes.json` 已注册 `FishLayer` standalone 路由，玩法大厅可真实点击进入。
- 实现范式（可直接复用）：`Resources/Lua/Gameplay/MoneyTreeController.lua.txt` + `src/Data/MoneyTreeStore.cs` + `src/UI/MoneyTreePresenter.cs` + `src/Core/ProjectXApp.MoneyTree.cs`（同族的 HappyWheel、Monopoly 亦为 `*Store.cs` + `*Presenter.cs` + `ProjectXApp.*.cs` 三件套）；Lua 控制器独占该顶级协议号的读写与字节游标，并对 `message.Remaining` 做严格校验，C# 只做展示与 Prefab 绑定。

### 5A 地图呈现方案（**已决策：方案 B —— 模块内保留地图呈现**）

**事实**：`unityclient/Assets/ProjectX/**/*.cs` 全量检索 `MapRender` / `MapLoader` / `Tilemap` / `GridMap` / `SceneMap` / `WalkTo` / `Transport`，仅命中 `LegacyTcpClient.Transport`（TCP 传输层，与地图无关）与 UI 层的 `MoveTo`（界面位移动画）。`docs/unityclient/modules/WORLD.md` 确认 Unity 世界为**大地图 UI + 战斗**两态，**无瓦片地图渲染、无角色行走、无场景传送（Transport）能力**。

**结论**：原版「进入场景 54 → 场景内行走 → 到位后放竿」的链路在 Unity 侧没有可复用基建；严格 1:1 复刻需先补框架级地图能力（方案 A），成本高且会阻塞 G0。

**用户决策（2026-09-14）**：采用**方案 B** —— 像闯关一样做“假传送”：进入功能后加载场景54对应的 `map33` 静态底图与角色表现，但不切 Unity Scene、不执行服务端世界传送、不引入行走与寻路。玩家固定在原1号合法区域内用户圈选的黑色位置 `(1086,619)`；**传入后立即把正常角色模型切换为钓鱼造型**。此时业务状态为 `Ready`，不扣金币、不启动倒计时；点击“开始钓鱼”后才发送 op5 并进入权威 `Fishing` 状态。

**方案 B 资产与数据闭环（已逐项核实）**：

| 用途 | 证据 | 结论 |
|---|---|---|
| 底图 | `../concept/策划文档/03正式版本/04剧情文档/钓鱼场景/map33.jpg`（**1920×1080**，391699 bytes，SHA256 `BBACFAAFA13A0131F110E031D1456984C26BB3D9D1E48EE328007E5DD2E41124`） | 当前位于仓库相邻的 concept 目录，尺寸与 `game_scene` 54 完全一致；G2前须导入Unity项目内，不能把仓外路径当运行资源 |
| 底图分片 | 同目录 `images/map33_01.jpg`(1024×1024)、`map33_02.jpg`(896×1024)、`map33_03.jpg`(1024×56)、`map33_04.jpg`(896×56) | 4 片拼合=1920×1080，适配 Unity 既有 `WorldUI/Maps/{folder}/map_{tile}` 分片约定 |
| 场景记录 | `server/sql/_all_sql.sql`：`game_scene id=54 name=瑶池 map_id=33 x=840 y=250 width=1920 height=1080 world_trans=2 show_type=3`（`id=55` 为同参数重复行） | 场景元数据齐全 |
| 可走区域 | `server/config/dat/map33.map`（= `concept/模拟器/map/map_block/map33.map`）：`uint16 width=60`、`uint16 height=33` 后接位图，**bit=1 为阻挡**；像素域 1920×1056，可走 **591/1980 = 29.8%** | 可用于生成禁行区/钓点坐标准确性校验 |
| 运行时地图 | `concept/模拟器/map/map33.mydj`（102KB）+ `map_image/map33_*.mydj` | 私有格式，Unity 不可直读，仅作参照 |
| 场景动效 | `concept/模拟器/map/mapEffect/`：`waterwave1`（水波）、`waterfall1/2/6/7/8`（瀑布）、`sunshine`（阳光）、`butflay`（蝶） | `.mydp` 私有动画格式 → 需导出序列帧或改用 Unity 粒子/Shader，列为**可选增强** |
| 原版钓鱼区域 | `client/ProjectX/src/View/Activity/FishControlDelegate.lua:4-6` 共3个站位多边形，`dir` 分别为2/6/4；运行时以角色位置命中区域后 `QueryFishingInfo(5, dir)` | 仅保留1号区域为来源约束；2、3号区域不接入单机UI |
| 固定钓位 | 用户在 `FISH_MAP_POINT_OPTIONS.svg` 的1号区域内圈选黑色位置；截图反算中心为 `map33` Cocos坐标约 `(1086,619)`，已验证落在1号多边形内 | `fish_position` 固定 `scene_id=54,map_id=33,x=1086,y=619,dir=2,flip=1` |
| 钓鱼模型切换 | `HeroNode.cpp:213` `SetFishingMode(true,face)`：停止移动、`ShapeId=2000`、设置朝向并重建模型；`MapModelAni.cpp` 对该 ShapeId 走 Monster 站立动画 `Monster/btm2000_zd.*`；`MapObjNode.cpp:1090` 在 op5 成功和玩家状态类型13时调用 | 单机版把**视觉切换时机前移到假传送完成后**；开始按钮仍只控制权威业务状态。正式 `btm2000_zd.png/.ani` 已恢复到 Cocos，并转换为 Unity `ProjectXAnimation/Monster/btm2000_zd.*`（40帧、5动作） |

**方案 B 实施要点（G0 起执行）**：
1. 场景底图由用户维护在正式 `FishLayer.prefab/FishUI/FishScene` 内；`FishPresenter` 不再动态加载 `map33`，也不覆盖 Prefab 中的场景资源和 Transform。
2. 正式角色挂点为 `FishLayer.prefab/FishUI/FishScene/pos`；`FishPresenter` 仅把 `FishingShape2000` 创建为 `pos` 子节点并将局部坐标归零，不再计算绝对或归一化位置，后续位置调整只移动 Prefab 内的 `pos`。运行时不创建 `FishPointMarker`。假传送完成后立即显示 `ShapeId=2000` 对应钓鱼造型，固定 `dir=2`、`flip=true`。
3. 页面进入后的业务状态为 `Ready`，但视觉始终为持竿待机；此时不发 op5、不扣金币、不显示倒计时。点击“开始钓鱼”固定发送 `QueryFishingInfo(5,2)`，权威成功回包后进入 `Fishing`、显示10~20秒倒计时并自动续钓；点击“收竿”回到持竿待机 `Ready`，关闭页面才恢复正常角色外观并销毁钓鱼造型。
4. 不实现：3钓点点击选择、瓦片渲染、角色行走、寻路、真实场景传送进出。原版 `PauseAutoPath` 逻辑连带移除。

**方案 A（框架级地图能力）** 作为独立里程碑保留，不在本项目/本模块范围内；方案 C（纯 UI 无地图）与决策 1 冲突，**已排除**。


## 6. 需要新增或变更的配置与入口

1. `fish_settings` 全局配置：`gold_cost=100`、`cycle_min_seconds=10`、`cycle_max_seconds=20`、`basket_capacity=9999`（单位：格）、`fish_stack_limit=999`、`auto_continue=1`。每轮开始时在包含上下限的整数区间内等概率抽取一次，当轮固定，下轮重抽；非法范围直接拒绝加载。鱼种数量由 `fish_reward` 的启用记录数决定，与鱼篓格数无关。
2. `fish_reward` 鱼种掉落配置：字段 `id/item_id/weight/enabled/sort/use_reward_id`，名称、品质、图标、描述仍引用 `item` 主表，不重复冗余。首版10种如下（权重是相对值，不要求合计100）：

| item_id | 鱼名 | 品质 | 权重 | 图标 | 用途奖励 |
|---:|---|---:|---:|---|---|
| 580 | 青鱼 | 3 | 50 | `equip580` | `use_reward_id=0`（待后续定义） |
| 581 | 鲶鱼 | 4 | 35 | `equip581` | `0` |
| 582 | 娃娃鱼 | 5 | 15 | `equip582` | `0` |
| 10580 | 鲫鱼 | 2 | 80 | `equip10580` | `0` |
| 10581 | 草鱼 | 2 | 65 | `equip10581` | `0` |
| 10582 | 鲤鱼 | 3 | 40 | `equip10582` | `0` |
| 10583 | 黑鱼 | 3 | 25 | `equip10583` | `0` |
| 10584 | 鳜鱼 | 4 | 15 | `equip10584` | `0` |
| 10585 | 金鳞锦鲤 | 5 | 5 | `equip10585` | `0` |
| 10586 | 龙须灵鱼 | 6 | 1 | `equip10586` | `0` |

   - 新ID `10580~10586` 已核对当前 `item` JSON 与旧 `item_template.sql`，未占用。
   - 权重合计331；加载时必须验证至少一条 `enabled=1 && weight>0` 且所有 `item_id` 可解析。
   - 7张新鱼图标已生成 RGBA 正式资源并同步到 `client/ProjectX/res/item/` 与 Unity `Resources/ItemIcons/`；透明角点校验通过。
   - 正式源表链：`fish_settings.xlsx`、`fish_reward.xlsx`、`fish_position.xlsx`，并同步修改 `function.xlsx`、`item.xlsx`；已通过原 `xl转表.exe` 生成并同步服务端/Unity JSON。
3. `fish_position` 固定站位与造型配置（新增，方案 B 专用）：首版唯一记录 `scene_id=54`、`map_id=33`、`x=1086`、`y=619`、`dir=2`、`flip=1`、`fishing_shape_id=2000`。坐标使用1920×1080、左下角为原点的 Cocos 口径；Unity加载时统一换算，不在 Prefab 中硬编码。原2、3号区域不生成交互热区。`fishing_shape_id` 必须解析到正式钓鱼模型与动画，解析失败则阻止进入，不回退普通站立模型。
4. 地图底图资产（新增，方案 B 专用）：正式 `map33.jpg`（1920×1080）已导入 `unityclient/Assets/ProjectX/Resources/Fish/Map/map33.jpg`，SHA256=`BBACFAAFA13A0131F110E031D1456984C26BB3D9D1E48EE328007E5DD2E41124`。
   - 加载路径集中在 `FishPresenter` 常量/配置入口，**禁止硬编码到 Prefab/Scene**。
   - 可选增强：`concept/模拟器/map/mapEffect/`（waterwave1 / waterfall1,2,6,7,8 / sunshine / butflay）为 `.mydp` 私有格式，需先导出序列帧或改用 Unity 粒子/Shader。
   - 参考校验：`concept/模拟器/map/map_block/map33.map`（60×33 瓦片，bit=1 阻挡，可走 29.8%）可用于验证钓点是否落在可走区域。
5. `function` 表新增钓鱼入口行（决策 2 + 3）：`function_id=32`（**已核实空闲**），字段参照 `MoneyTree` 用法。
   - 入口解锁：复用既有 `open_condition`，配置为 **10级**。
   - 次数控制：**每日不限次，无扣次时机**；不向 `function` 表添加 `daily_times`，不建立玩家每日次数状态。
   - 时段：已取消 `12:30-12:50`；如需限定开放日，改用 `show_weekday` 与 `start_time`/`end_time`，不再走 `IsInHuoDongTime()`。
   - 源表：`../concept/data/excel/xml配置表/新表/function.xlsx`（Sheet1，124 行；`function_id=32` 已配置为“钓鱼”、10级开放、`page=1`、图标 `ui_icon_wanfa_diaoyu`，无每日次数字段）。已同步生成 `server/config/json/function.json`、`client/ProjectX/src/ConfigData/function_dat.lua` 与 Unity `Resources/Configs/gameplay.json`。
6. `unityclient/Assets/ProjectX/Resources/Configs/function-routes.json` 新增 `{"functionId":32,"kind":"Gameplay","target":"Fish","prefabKey":"FishLayer","presentation":"standalone"}`，并在玩法大厅入口列表加入该 id。
7. Unity 侧新增：`Resources/Lua/Gameplay/FishController.lua.txt`、`src/Data/FishStore.cs`、`src/UI/FishPresenter.cs`、`src/Core/ProjectXApp.Fish.cs`；`FishPresenter` 承担方案 B 的底图铺放、固定玩家站位、`ShapeId=2000` 钓鱼造型生命周期，以及 `Ready/Fishing` 业务状态切换。正式层级以 `DynamicUi_OneLevelLayer` 为页面容器，`DynamicUi_FishLayer` 直接挂在其下，顶部标题、帮助、关闭使用容器自身的 `Panel_12`；Fish 打开时固定隐藏容器根 `Bg`、整个 `GoldCheck` 和同层 `DynamicUi_shop_bg` 玩法大厅分支。鱼篓展开时仍复用同一顶部预制体与 `zhujue/beibao.prefab`，不创建 `FishTitle/FishExitButton/FishHelpButton/FishGold/FishCost` 或另一套格子美术与背包外框。
8. 服务端：`TryFishTimeout` 改读 `fish_settings/fish_reward`；`op=5` 放竿成功后原子扣除100金币并产生首轮10~20秒时长，每轮结束后重抽下一轮时长；删除 `AddExp` 与 `DropExchangeItem(EEHDT_Fish)`；删除抢夺分支；`IsInHuoDongTime()` 短路；鱼篓最多9999个已占用格。获得鱼时先定位同 `item_id` 且数量小于999的最早格并加1；不存在未满格时才尝试分配新格；若已占满9999格则本次鱼直接舍弃，不新增/覆盖格子，并给出明确的“鱼篓已满，本次鱼已舍弃”提示。每格数量强校验 `1~999`。客户端复用背包五列格子和纵向 `ScrollRect` 显示已占用格，并在每格右下角显示数量；补齐10种鱼的 JSON/SQLite镜像。

## 7. 门禁计划（G0-G6）

1. **G0 前置（已闭环）**：固定账号 `7200057/1000003`；10个控件与50个业务ID见 `FISH_CONTROLS.json` / `FISH_COVERAGE.json`；正式 Excel→JSON、地图、`ShapeId=2000` 模型动画、10种鱼图标/配置和 SQLite 结构均已落地。可逆夹具已完成 `Setup → AssertSetup → Restore → AssertRestored → AssertReloginHash → Cleanup → AssertCleanup`，原库 SHA256、`integrity_check=ok`、重登业务哈希和残留0通过；不建立每日次数、主角经验或交互币状态。
2. **G1 源码闭包（用户授权例外）**：Cocos 入口 → `FishUI`/三个 Delegate → 协议 → 服务端 `CFishManager` 已作为源码基线；用户明确要求忽略 Cocos 客户端全部表现，直接迁移 Unity，故不采、不伪造 Cocos 运行截图。例外证据：`.local/unity-validation/fish-g1-user-authorized-source-only.json`。
3. **G2 审计**：共享协议217、配置资源（`function.json` 含 `function_id=32`、`fish_settings.json`、`fish_reward.json`、`fish_position.json`）、`FishLayer.prefab` 的节点与 Transform 一致性；方案B底图、固定坐标换算、`ShapeId=2000` 正式模型/动画与加载路径。
4. **G3 定向（已通过，用户已实际验收）**：固定账号真实点击玩法大厅与 `Function_32/EnterBtn`，进入场景54/map33固定钓位并立即显示 `ShapeId=2000`；Ready 未扣费，开始后金币 `1000→900`、首轮时长落在10~20秒，首鱼入鱼篓后自动续钓扣至800，鱼格选中后通过正式“收获”按钮整组领取，再次产鱼并续钓扣至700，真实收竿、关闭鱼篓和退出均通过。2026-09-15 使用25个配置鱼格验证鱼篓真实 EventSystem 拖动，纵向位置 `1.00→0.00`，内容高度710大于视口523；最后调整为 `DynamicUi_OneLevelLayer` 容器层级、隐藏 `Bg/GoldCheck/shop_bg`、Prefab 内置 `FishScene/pos` 挂点后，用户实际测试确认无误。证据：`.local/unity-validation/fish-g3-runtime-latest.json`、`.local/unity-validation/fish-formal-basket-scroll-result.txt`、`unityclient/Captures/fish-formal-ui-final-*.png`。
5. **阶段收口**：本次提交停在 G3 用户验收完成，`manualPassed=true`；后续重新开启 Fish 最终迁移验收时再执行 G4-G6 全量、恢复夹具、重登哈希与残留检查。

## 8. 决策状态

- **已确认（2026-09-14）**：①保留地图 ②入口 `function_id=32` ③10级开放、每日不限次、无扣次 ④每次成功放竿扣100金币（可配） ⑤每轮独立随机10~20整秒 ⑥鱼篓容量9999格、同种鱼优先补未满格、单格上限999、满栈后新增同鱼种格、格子右下角显示数量；10只是当前鱼种数而不是固定格数；9999格均占用且该鱼无可补格时直接舍弃新鱼 ⑦在原3种鱼基础上新增7种并全部配置化 ⑧删除主角经验和交互币 ⑨抢夺直接删除 ⑩地图呈现采用方案B ⑪进入场景54表现后立即切为原版 `ShapeId=2000` 钓鱼造型，收竿仍保持持竿待机，只有退出模块才恢复正常角色模型。
- **后续用途暂不处理（用户明确）**：10种鱼未来会进入其他消耗链；本阶段 `use_reward_id=0` 仅表示暂不接用途，不代表永久不可消耗。
- **G0-G3 已通过；G1 由用户明确授权采用源码基线例外；用户已在最后一次正式 UI 与 Prefab 挂点变更后实际测试通过，`manualPassed=true`；G4-G6 待后续重新开启**。鱼篓容量、溢出规则、固定钓位与入场造型时机已全部冻结；正式源表/JSON/SQLite镜像、`ShapeId=2000` 模型动画、7张新鱼图标与可恢复夹具均已落地。方案 A（框架级地图能力）与方案 C（纯 UI）均不在本次范围。
