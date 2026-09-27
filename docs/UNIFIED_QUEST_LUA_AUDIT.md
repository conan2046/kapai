# 服务端 Lua 任务迁移审计（静态阶段）

## 范围与结论

本次逐文件扫描 `server/script/*.lua` 共 235 份，按任务 API、任务编号常量、入口配置、C++ 固定编号调用和 Lua 回调建立只读台账。网页“Lua 脚本”页可查看每份脚本的行号证据。静态筛出任务相关脚本 42 份、任务相关 API 调用 286 处；这不等于 42 份脚本当前都可运行。运行时实际加载的 NPC 表来自数据库，网页分别核对了策划 Excel 与当前 JSON 导出。

旧任务配置和旧服务端剧情在 `CMissionManager::Init()` 的加载调用已注释；NPC、固定编号和场景脚本入口仍需分别判断。不能把“旧任务表休眠”推导成“所有 Lua 任务脚本休眠”。

## Steam 客户端到服务端 Lua 的代码链

Steam 打包工具 `unityclient/Assets/ProjectX/src/Editor/SteamWindowsBuild.cs` 从 `unityserver/script` 复制服务端 Lua。当前 `unityserver/script` 与 `server/script` 的 235 份同名 Lua 内容逐一相同；网页每次读取时重算哈希。这只证明当前源码副本一致，不证明每份脚本在运行时被调用。

| Steam 入口 | 客户端与协议 | 服务端路径 | Lua 结论 |
|---|---|---|---|
| 每日任务 `Function_10` | `ProjectXApp.GameplayRoutes.cs` → `TaskController.lua.txt` 发 `/37 op=1 type=2/0`；领取发 `op=3` | `pack_deal.cpp:GetMissionList` → `CUserMission::GetQuestMessage/GetQuestAward`；`CMissionManager::InitQuestCfg` 读取 `daily.json`，`UpdateQuestState` 推进条件 | 这条查询/领取链没有调用旧 NPC 任务 Lua；其他玩法的服务端 Lua 仍可能产生任务事件，需要按事件产生点审计 |
| 每日答题 `Function_27` | `AnswerController.lua.txt` 发 `/198 op=1/2`，不走 NPC 交互 | `pack_deal.cpp:AnswerQuestionOption` 在 `op=1` 调 `FindScript(200)` 的 `GetQuestionAnswer` | `200.lua` 是当前代码明确使用的服务端 Lua，不能因 Steam 无 NPC 而排除 |
| 法宝搜索 `Function_9`（Steam 无 NPC） | 玩法大厅按钮直接打开 UI；`XunBaoController.lua.txt` 发 `/319 op=28/29/30/31/36`，任务按钮由 `TaskController` 发 `/37 type=3` | `DealPetEquipOperate` 和 `GetMissionList` 分别处理操作与任务列表 | Steam 法宝搜索不走 NPC；`global.lua` 中旧 `MISSION_ID_XUNBAO=102` 的挖宝 NPC/寻路任务是另一条历史流程，不能因名称相近合并 |
| 登录 | 选角 | `pack_deal.cpp` 调 `GetScript()` 的 `Logon`；`utility.cpp` 将其绑定到 `10000.lua` | `10000.lua` 是不依赖 NPC 的直接脚本入口 |
| 旧 NPC 交互 | 当前 Unity Lua/C# 中未检出 `PRO_INTERACT` 的发送；协议注册仍保留 | 原版 `OpenNpcInteract` 调 NPC 脚本 `NpcMain`，选项再调 `SetCallFun` 回调 | 服务端旧链仍在源码中；Steam 范围文件已排除师门、心魔、藏宝图旧脚本战斗，不能据打包文件推断其入口有效 |

Steam 的客户端还使用 `unityclient/Assets/ProjectX/Resources/Lua` 下的 UI/协议控制器。这批 Lua 与 `unityserver/script` 的服务端业务脚本角色不同。Steam 产品范围以 `docs/unityclient/STEAM_SCOPE.md` 和当前路由配置为准；旧 Cocos 的 NPC 流程保留在源码，不作为 Steam 新任务编辑器的默认交互模型。

## 已定位的任务存储与入口

| 机制 | 源码证据 | 迁移判断 |
|---|---|
| NPC 交互 | `npc_manager.cpp` 从数据库 `npc_template.script` 创建 `CCallScript`；`pack_deal.cpp` 调 `NpcMain`，选项后再调用 `SetCallFun` 指定的函数 | 正式 `常规配置/npc_template.xlsx` 关联 95 个脚本，其中 32 个含任务引用；当前 JSON 导出仅关联 89 个，少了 `161～166.lua` 六个镖头脚本。`server/sql/_all_sql.sql` 的 NPC 种子仍有这六项，说明 JSON 与 SQL 种子来源不同；实际运行库和 NPC 实例可达性未核对 |
| 全局脚本 | `GetScript()` 创建 `10000.lua`；多数脚本 `require "global"` | `global.lua` 是师门、周师门、寻宝、丹园、夺宝、跨服历练等任务方法的集中实现，不应按普通 NPC 脚本处理 |
| C++ 固定编号脚本 | `FindScript(常量)`、`new CCallScript(常量)` | 9 份现存脚本有固定编号调用线索；仍需检查调用分支和参数 |
| 场景脚本 | `scene_manager.cpp` 尝试加载 `场景ID + 10000` 的 Lua | 与 `常规配置/game_scene.xlsx` 编号匹配 10 份现存脚本；场景实例及运行时加载仍未确认 |
| 道具脚本 | `utility.cpp` 先从数据库 `item_template.script` 创建 Lua；仅本地测试时，用 `item.json` 补齐数据库缺失的模板 | 正式 `新表/item.xlsx` 关联 8 个现存脚本，当前 `item.json` 无非零脚本关联；JSON 差异不能证明数据库脚本未生效，需核对实际 `item_template` |
| 通用任务数据槽 | Lua 使用 `GetMission / AddMission / UpdateMission / DelMission` | 16 份脚本涉及该接口；`213`、`801～806` 等是数据槽使用证据，不能直接认定为旧任务表 ID |

## 与任务表的核对

`global.lua` 定义并被任务脚本使用的 `MISSION_ID_ZhuoGui=100`、`SHIMEN=101`、`XUNBAO=102`、`DANYUAN=103`、`DUOBAO=104`、`HUSONG=105`、`ZHOUSHIMEN=106`、`KUAFULILIAN=10001` 均能在旧 `mission_config.xlsx` 找到同号记录。这只证明配置来源有对应项；服务端是否为这些脚本建立可用任务状态，仍要按当前初始化和实际运行验证。

`MISSION_ID_DC_*` 是旧目标类型常量，不是任务 ID。`global.lua`、`2.lua`、`74.lua` 等调用旧目标 `59`，参数中再携带所完成的任务 ID；迁移时应保留“任务完成”事件的任务参数。`22441.lua` 与 `22442.lua` 分别推进旧目标 `45`（普通藏宝图）和 `46`（高级藏宝图），但两脚本在当前 NPC、道具导出配置中均没有确认入口。

Lua 中直接调用 `UpdateDCMissionComplate` 的共有 9 处，涉及旧目标 `45`、`46`、`59`、`61` 四种：`45/46` 各 1 处，`59` 共 6 处，`61` 在 `9.lua` 有 1 处。其余 Lua 任务逻辑更多通过 `AcceptCMission`、`UpdateCMissionState`、`DelCMission` 和通用数据槽表达，不能仅统计旧目标推进函数就认定 Lua 任务已覆盖。

## 事件类型归并候选

| 候选 | 表面共同语义 | 当前证据和待核对点 |
|---|---|---|
| 每日条件 `2` 与旧目标 `9` | 神将招募 | 两侧均有 C++ 调用；需核对“招募成功”时机及是否包含全部招募方式 |
| 每日条件 `9` 与旧目标 `30` | 竞技场挑战 | 每日条件有 C++ 直接调用；旧目标未检出同形式的直接调用；需核对胜负、次数和范围 |
| 每日条件 `6` 与旧目标 `54` | 帮派捐献 | 旧目标在帮派代码有直接调用；每日条件未检出同形式调用；需核对捐献种类与成功时机 |
| 旧目标 `45` 与 `46` | 使用藏宝图 | Lua 分别推进普通与高级类型；可考虑统一“使用藏宝图”事件加道具档次参数，待核对道具脚本入口 |
| 旧目标 `59` 的多处调用 | 完成指定任务 | 同一目标类型已通过任务 ID 参数区分师门、周师门、寻宝、丹园等；迁移时不按脚本数拆事件类型 |

以上均为候选，未执行删除或自动合并。编号空间必须保留前缀：每日条件 `9` 是竞技场，旧目标 `9` 是招募。

## 未完成的验证

1. 任务相关脚本中 8 份在当前源表、Lua `require` 和 C++ 固定编号调用中未解析到入口。代码用途已进一步缩小：`21003.lua` 是钓竿道具 `Main`；`22441/22442.lua` 是普通/高级藏宝图道具 `Main`；`229.lua` 是旧任务大使 `NpcMain`；`302～305.lua` 是挖宝 NPC `NpcMain/BattleOver`。`CUser::UseItem` 可按道具配置调用 `Main`，旧 NPC 交互可调用 `NpcMain`，但当前道具 JSON 的脚本字段全为 0，当前 NPC JSON 也没有这些编号。`global.lua` 的当前 `CreateWaBaoMission` 只选动态 NPC 300/301，未找到 302～305 的创建点。Steam 旧脚本战斗已排除；这些判断仍需按运行库与动态配置核对，不能简单宣称脚本绝对不可达。
2. NPC Excel 与 JSON 导出存在六个脚本编号差异，物品 Excel 与 JSON 导出存在八个脚本编号差异。需要明确当前服务器数据库到底采用哪份导出，不应直接按网页某一份配置判断可达。
3. `17.lua` 将 `ChooseOption` 设置为选项回调，但本文件未定义该函数；目前调用分支受常量 `num=0` 限制，不能据此宣称运行时错误。
4. Lua 分支与参数含义仍须逐条核对，尤其是 `global.lua` 的任务接取、完成、删除、每日次数及旧目标 `59` 的触发顺序。
5. Steam 的优先验证入口应是现行功能按钮和协议：法宝搜索 `/319` 与任务 `/37`、每日答题 `/198`、关卡剧情入口。旧 NPC 任务只在确认 Steam 有入口或另行处理 Cocos 历史兼容时验证；不能用 NPC 交互替代 Steam 的功能路径。

本审计不修改奖励、正式 Excel 或服务器运行配置。

## 本轮静态收敛

- `daily.xlsx` 的 148 个任务 ID 与 `daily.json` 完全一致；将空的 `show/jump` 按导出默认值 0、条件拆成数组、奖励按原结构解析后，9 个字段逐条比较差异为 **0**。
- 每日配置实际引用 19 个 `EMQCT` 类型。`UpdateQuestState` 将同一事件分派至普通、七日等任务状态；`CheckQuestState` 将类型区分为累加、当前值等，不能只按显示名称合并。`EMQCT_14` 是法宝搜索成功次数，手动与自动路径均在结算后发出；`EMQCT_34` 是合成成功数量，附带产物品质，两种合成路径均在消耗材料并生成产物后发出。
- `22441.lua` 与 `22442.lua` 都在场景和位置校验、删除藏宝图道具后推进旧目标，区别是普通/高级道具及奖励表现。可考虑共用带 `item_tier` 参数的“使用藏宝图”事件；它属于 Steam 已排除的旧藏宝图脚本战斗，当前不进入策划可选事件目录，道具 JSON 也未证实脚本入口。
- `EMQCT_2` 和 `EMISS_DC_9` 均描述招募，但生产路径分别在 `chou_ka_manager.cpp` 与 `init.cpp`，尚未证明协议、成功时机和覆盖范围一致。竞技场、帮派的同名候选属于 Steam 排除范围；均保持独立映射，未自动删除。
- 章节剧情源表 35 行中，组 `10042` 的第 1 句在 Excel 第 37、39 行完全相同。统一 `DialogueLine` 表按 10 个组 ID 导入 34 句，去掉完全重复的 1 句；`LegacyMap` 保留源组映射，原始源表保持不变。导入对话组不等于已关联 Steam 任务。Cocos `NormalFuBenUI/FuBenDetailUI → NPCChatDialogUI` 有配置消费链；Unity 源码尚未检出同名 `mission_dialog` 或 `dialogid` 引用，Steam 入口仍待核对。
