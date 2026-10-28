# Unity 独立数据

本目录是 Unity 版本独立维护的数据根目录，不读取或反向覆盖 `concept/data/excel`、`client/ProjectX/src/ConfigData`、`server/config`。

## 当前客户端链路

### 境界 Spine 展示

- `excel/jingjie_config.xlsx` 的 `icon` 填 `role_{sex}_01`～`role_{sex}_14`；`{sex}` 按角色存档中 `0=男、1=女` 替换为 `m/w`。创角按钮选项 `1/2` 已由登录协议转为存档值，展示层不要再次转换。
- `excel/role_visual.xlsx` 维护14组男女 Spine、头像、循环动作与创角默认外观。`jingjie_config.icon` 的末尾编号引用 `visual_id`，具体资源名由此表解析。
- 原始预制体位于 `unityclient/Assets/Prefabs/Spine/Role`；Canvas 展示预制体位于 `Assets/Prefabs/Spine/UI/Role`，创角、主界面 `role` 和境界页面共用，通过既有资源引用索引加载。
- 头像位于 `Assets/Art/Portraits/Players`；主界面 `role` 与左上头像按保存的性别、当前境界同步切换。尚未取得境界快照或境界为0时使用创角默认外观。
- Spine 实例挂在持久化的 `SpineAnchor` 空节点下：创角 `Role/SpineAnchor`、主界面 `role/SpineAnchor`、境界各 `Icon/SpineAnchor`。直接在这三份界面 Prefab 中调整空节点的位置、缩放、旋转；代码与资源重建均不覆盖这些值，不自动适配大小。
- Spine 源资产位于 `Assets/Art/Spine`，保持自身 Atlas，不纳入静态 UI SpriteAtlas。运行库位于 `Assets/Plugins/Spine`。
- `jingjie_config.xlsx` 已更新为550小阶正式表；第二页`RuntimeRules`维护在线5秒、离线48小时100%、乌云3秒、雷击与结算间隔及成功显示气血下限。旧等级／战力门槛与材料金币消耗退役。
- 完整双端定向导出：`& .\unitydata\tools\Export-UnityJingJieData.ps1`；只校验加`-ValidateOnly`。客户端入口支持`-OnlyJingJie`（兼容旧`-OnlyJingJieVisuals`），服务端入口支持`-OnlyJingJie`；仅外观表仍用`-OnlyRoleVisuals`。
- 新境界表由Unity专用类型校验／导出器处理，跳过旧通用转换器；生成客户端`Configs/jingjie.json`与`jingjie-rules.json`、服务端`jingjie_config.json`与`jingjie_rules.json`。业务实现进度见`docs/unityclient/JINGJIE_REWORK_PROGRESS.md`；配置导出不代表新版运行逻辑已完成。
- 资源导入后使用菜单 `Tools/ProjectX 资源/构建境界 Spine 展示预制体` 重建展示预制体及引用。
- `role.unitypackage` 里的 `zmls_001` 缺失贴图，H 盘原工程同样缺失；此资源未用于境界，不能选作可播放资源。

```text
unitydata/export/client/source
    -> unitydata/tools/Export-UnityClientData.ps1
    -> unityclient/Assets/Resources/ProjectXData
```

`export/client/source` 是 Unity 独立客户端数据源，截至2026-10-11包含61个运行数据文件。下文列出的Unity自有工作簿先经类型导出器生成对应数据，其余历史快照继续复制；不再从Cocos或旧服务端目录补输入。

宝箱预览表 `World/reward_fixed_dat.txt` 由客户端导出工具从 Unity Excel 的服务端中间产物 `export/server/generated/json_server/reward_fixed.json` 生成，并检查与 `unityserver/config/json/reward_fixed.json` 一致，避免客户端预览与实际奖励不同。仅同步该表可用 `Export-UnityClientData.ps1 -OnlyWorldBoxRewards`。

全量导出校验相对路径与文件哈希；内容未变时不重写文件。`-CleanOutput` 仅删除输出目录内数据源已不存在的数据文件，保留目录和全部 `.meta`，避免已有 Unity GUID/Importer 配置丢失。宝箱模式只同步宝箱预览表，不清理其他输出。

历史 Fish G0 同步入口 `tools/unity-migration/Sync-FishConfig.mjs` 已停用并归档。钓鱼现由`excel/fish_config.xlsx`维护，客户端JSON、服务端JSON及真正业务使用的SQLite种子统一生成；不再向原版`server`或旧Unity Assets目录回填。

```powershell
& .\unitydata\tools\Export-UnityClientData.ps1
& .\unitydata\tools\Export-UnityClientData.ps1 -OnlyWorldBoxRewards
& .\unitydata\tools\Export-UnityClientData.ps1 -CleanOutput
```

## 目录约定

- `export/client/source/Configs`：客户端 JSON/XML 配置
- `export/client/source/Tasks`：Unity 任务配置
- `export/client/source/World`：Unity 世界与培养 TXT 配置
- 神将升级门槛由客户端导出器从正式服务端中间产物`exp.json`生成`Configs/hero-level-exp.json`，并核对当前`unityserver/config/json/exp.json`；培养显示与红点共用，避免旧Cocos经验曲线与单机服务端不同。
- 神将突破同样从正式`break/quality/hero.json`生成`Configs/hero-break.json`并核对当前服务端；按真实神将品质缩放费用，按钮显示和红点共用。
- 神将升星从正式`star/hero.json`生成`Configs/hero-star.json`并核对当前服务端；专属碎片ID、品质费用、下一星级存在性供按钮和红点共用。
- 神将修炼从权威`xiulian.json`及正式config的`xiulian_attr/xiulian_cost`生成`Configs/hero-cultivation.json`并核对当前服务端；训练剩余次数与激活消耗分开判定，不使用固定400次或强制最少1次。
- 神将图鉴继续使用正式handbook/star/quality/hero四张客户端JSON，导出时核对当前Unity服务端；图鉴快照、拥有状态、星级门槛及材料资格供卡片/按钮与主入口共用。
- `export/client/source/Battle`：Unity 战斗表现 DAT/TXT 配置
- `export/client/`：Unity 客户端数据导出工作区

服务端数据另建 `unityserver`，不得写入本目录。

## 当前服务端链路

```text
unitydata/excel/*.xlsx
    -> unitydata/tools/vendor/xl转表.exe
    -> unitydata/tools/Export-UnityServerData.ps1
    -> unitydata/export/server/generated/json_server
    -> unitydata/export/server/authoritative/json 覆盖 7 张完整服务端权威表（item另走正式表合并）
    -> unityserver/config/json
```

`unitydata/excel` 保存Unity正式Excel输入（截至2026-10-11递归共68个文件，其中8个为本轮新增工作簿）。旧通用转换器只处理其合同内的旧工作簿；`unity-owned-tables.json`登记的工作簿由`Export-UnityOwnedTables.ps1`处理，境界及角色外观沿用专用导出器，均不依赖外部`concept`路径。

`unitydata/export/server/authoritative/json` 保存当前 Unity 服务端基线中的 7 张完整权威快照：`drop_matching`、`level_reward`、`mission_dialog`、`sevendays`、`shop_config`、`shop`、`xiulian`。这些表以现有服务器数据为准，覆盖原始 Excel 转换结果；原始 Excel 差异仍记录在 `.local/unityserver-export/latest.json`，但不会再阻断导表。使用 `-ApplyGeneratedJson` 会把合并后的结果同步到 `unityserver/config/json`。

已登记的35张服务端XML接入Unity工作簿；其余XML和地图仍保留历史基线。服务端运行所需的3个DLL位于`unityserver/runtime`，不属于策划数据表。

## Unity 自有表：修改和导出

| 数据组 | 正式工作簿 | 内容 |
|---|---|---|
| Fish | `excel/fish_config.xlsx` | 参数、钓位、10种鱼奖励；钓位`map_resource`只输出客户端 |
| Answer | `excel/answer_config.xlsx` | 每日次数/兜底奖励、38道题及选项 |
| HappyWheel | `excel/happywheel_config.xlsx` | 转盘参数、10项奖励 |
| FaBaoSearch | `excel/fabao_looting.xlsx` | 264条法宝搜索配置 |
| HeroCombat | `excel/hero_combat.xlsx` | 48词缀、59神将技能定位、24配装建议 |
| Attributes | `excel/attr_type.xlsx` | 41条属性/战力系数 |
| CasualGameplay | `excel/casual_gameplay.xlsx` | 摇钱树、闯关地图/事件三表 |
| RoleBattle | `excel/role_battle.xlsx` | 角色/神将/装备/战斗基础、旧培养、称号、旧抽宠、试炼/塔初始化共32表；只接通数据，不恢复旧入口 |

工作簿遵循现有四行表头：第1行字段键、第2行导出范围、第3行说明、第4行类型，第5行起为数据。键和Sheet名称属于运行合同；新增记录应完整填写各字段。`json`列填写合法JSON数组/对象；XML复合属性继续保留原字符串。XML中的原空占位行保留。导出按Sheet名称定位，不依赖标签顺序；含公式的配置单元格会被拒绝，防止读到陈旧公式缓存。

```powershell
# 定向双端导出：写生成目录、Unity运行配置和SQLite种子/初始化结构
& .\unitydata\tools\Export-UnityOwnedTables.ps1 -Group Fish
# 只核对，不写文件
& .\unitydata\tools\Export-UnityOwnedTables.ps1 -Group Fish -ValidateOnly
# 所有登记表；Group省略也等价All
& .\unitydata\tools\Export-UnityOwnedTables.ps1 -Group All
# 只生成服务端产物，暂不同步运行配置/初始化结构
& .\unitydata\tools\Export-UnityOwnedTables.ps1 -Mode Server -ApplyRuntime:$false
```

全量客户端/服务端入口自动纳入这些组。`Export-UnityClientData.ps1 -DataGroup Fish`只同步客户端；`Export-UnityServerData.ps1 -DataGroup Fish`只生成服务端中间产物，添加`-ApplyGeneratedJson`才同步服务端JSON/XML/CSV和SQLite种子。

SQLite链：源表→`export/server/generated/sqlite/*.sql`→`unityserver/sql/sqlite/seeds/*.sql`和`001_initial_schema.sql`的对应标记段。真实启动路径由`LocalServerSupervisor`传入该结构文件，服务端启动执行整份结构，所以改表后需要重新启动单机服务端才能更新已存在存档中的配置行。导表不连接或修改当前玩家存档；种子只更新所属配置表，保留鱼篓等玩家状态。鱼种删除与题库替换会清除所属配置表旧行，转盘奖励只替换`type=2`所属行。

维护源唯一是上述Excel。`unityserver/config/source/*.csv`是兼容输出，不能再当独立编辑源；`tools/local/Export-QuestionBank.ps1`、`Export-AnswerSettings.ps1`、`Export-HappyWheelConfig.ps1`继续服务旧server链，不作为Unity入口。

只读/隔离测试：使用可用Python运行`unitydata/tools/tests/test_unity_owned_tables.py`。测试在工程`.local/unitydata-closure-tests`构建副本，以真实导出脚本及内存SQLite检验改表传播、非法输入无写入、重复导出、鱼种删除、客户端专属字段和XML占位行；不启动游戏。

导表命令：

```powershell
& .\unitydata\tools\Export-UnityServerData.ps1 -CleanOutput
& .\unitydata\tools\Export-UnityServerData.ps1 -CleanOutput -ApplyGeneratedJson
```

## 功能门槛统一维护（2026-10-26，P01）

功能的唯一维护源为 `excel/function.xlsx / Sheet1`，以本次 Unity 当前体验为迁移基线，共121条服务端记录。原始51条旧表已在本轮本地备份保留；当前表补齐全部运行字段，修正重复的show列名为show_reward，并增加客户端目录元数据。境界function_id=22统一为1阶；1050名称按客户端统一为主角。其他运行条件及客户端目录的顺序、图标、路由、Steam排除标记保持原值。

`unity-owned-tables.json` 的 `Function` 组经 `Export-UnityOwnedTables.ps1` 类型校验并导出服务端function.json、客户端function-unlocks.json和gameplay.json。客户端openLevel直接取同一行open_condition中的境界条件，不再独立维护；目录名称和图标仍可按各展示用途配置。旧authoritative/json/function.json仅保留历史参考，全量服务端导出已不再将其覆盖回来。

定向入口：`Export-UnityOwnedTables.ps1 -Group Function -Mode Both`；或客户端/服务端入口的 `-DataGroup Function`。后者服务端仍需显式 `-ApplyGeneratedJson` 才同步运行配置。一般全量入口自动纳入Function组。校验模式 `-Group Function -ValidateOnly` 检查源、生成目录与当前运行输出一致且不写文件。

功能门槛维护链已完成；用户随后确认保留现有洞府数据并修复道具覆盖链，详见下节。导出检查不代表真实Play验收或发行包已更新。

## 道具导出覆盖链（2026-10-26，P01）

道具统一通过现有Export-UnityOwnedTables.ps1中的Items入口，由UnityItemData.ps1进行类型读取和合并。唯一正式维护表为excel/item.xlsx；export/server/authoritative/json/item.json只为正式表尚未收录的历史ID提供兼容底座，同ID始终以正式表为准。当前正式表1884条，加13条历史兼容记录，完整重建1897条；本次不改变任何道具数值、名称、配方或引用。

导出顺序：读取历史兼容底座 → 正式item.xlsx覆盖同ID及追加新ID → 校验字段与堆叠上限 → 用本批道具集合校验洞府引用 → 写生成目录或客户端源目录 → 按Mode及ApplyRuntime同步运行目录。构建不再把当前运行item.json当作输入，也不再向多出source层的旧权威路径写文件。

All和DongFu入口在Server、Client、Both模式均纳入道具阶段。Items、ItemStacks、GardenItems、SpiritItems、LibraryItems、AlchemyItems兼容入口统一走同一条链；ValidateOnly实际检查输出差异而不写入，ApplyRuntime:false只生成指定端产物。单端导出不改另一端；客户端后置装备拷贝已移除item，避免将旧服务端产物写回客户端源；.meta保持原状。

全量服务端通用转换器跳过主item.xlsx及同名历史副本，item不再被整表权威快照覆盖。最终运行目录复制发生在差异检查通过后。Function维护链保持上一阶段实现不变；reward现已转入下节的正式维护链，其余8张完整权威表继续沿用既有规则。

定向导出：Export-UnityOwnedTables.ps1 -Group Items -Mode Both；定向只检验加-ValidateOnly。洞府入口及客户端/服务端的-DataGroup Items也使用同一实现。运行参数保持原有语义，服务端入口需-ApplyGeneratedJson才同步运行配置。

回归入口：tools/tests/test_item_export_chain.py。它在.local隔离副本中覆盖全量通用转换器、单端/预生成、冷重建、非法输入无写入、防止失败后写运行目录、旧错误路径无效及重复导出。全量链测试只隔离了末尾无关的境界导出，不启动Unity Play或游戏服务端。

## 龙崖最终Boss宝箱（2026-10-27）

- 正式维护源为`excel/bigmap.xlsx / bigmap`的`boss_reward`列，直接填写`reward_fixed.xlsx / reward_fixed`的奖励包ID，类型为整数；不再填写星数与奖励ID二元组，`star_reward`列退役。0表示该章节没有宝箱；127个主线章节必须填写有效奖励包。
- 本次每章仅保留原最后一档奖励包，未合并前两档、未修改包内数值。第一章1001填写20013，内容仍由reward_fixed维护。原10000、10011等历史奖励包不恢复挂点。
- 每章仅最后一个Boss关联该包，每次龙崖Boss胜利均随权威结算自动开箱发放；普通关、精英关、失败和非龙崖挑战不发本包。关卡rewardID常规掉落、藏书来源奖励与Boss宝箱各计算一次。旧存档的星数和已领取星箱状态不再作为宝箱资格或防重依据；重复结算仍由当前战斗生命周期拦截。
- 客户端只保留最后一个宝箱作为奖励预览，提示每次Boss胜利自动开启；前三档星箱、星数进度与龙崖结算星星隐藏。预览不发送旧op4领取请求；服务端也拒绝历史星箱领取。op2尾部在零个星箱后下发boss奖励包ID，由当前Unity Lua/C#同步解析。
- WorldRewards组统一读取、校验并导出bigmap和reward_fixed的JSON、客户端DAT及运行副本，全量旧转换器跳过这两张正式表。导出检查每章恰好一个最终Boss、奖励包存在、奖励项有效，失败时不写输出。维护入口仍为`Export-UnityOwnedTables.ps1 -Group WorldRewards -Mode Both`，只检验加`-ValidateOnly`。
- 旧存档结构与.meta、Prefab布局均保持原状。数据同步、规则测试、服务端构建、Unity编译与真实Play验证分别报告；前一天基于星级箱的收益验证不能当作本规则的验收证据。

## 关卡、战斗与奖励正式维护链（2026-10-26）

- 正式维护源位于unitydata/excel：maplist.xlsx / maplist维护关卡与引用；fight_config.xlsx / Sheet1维护战斗、阵法、展示怪和站位；monster_boss_basic.xlsx / Sheet1维护怪物属性和技能；reward.xlsx / Sheet1维护奖励组。客户端和服务端输出均由正式表派生，不从当前运行JSON或客户端输出反向补值。
- 本轮统一范围为bigmap.MapType=1的1266个主线副本/龙崖关卡。一次性核对Cocos客户端现有主线配置后，将1266个战斗、6264个怪物的原始数值纳入正式表。162个同号异内容战斗不覆盖原记录，主线使用空闲22001～23270号段，maplist.fightID同步更新；非主线引用保持原值。fight_config不恢复50000以上记录或team_buff。怪物原始属性、成长值、技能和阵法等级保持原值；zhenfa_level中的角色等级100沿用现有服务端行为。阵法运行输入以zhenfa为准；现有zhenfa_id、zhenfa_level辅助列保留，不反向覆盖zhenfa。
- 定向入口：Export-UnityOwnedTables.ps1 -Group WorldRewards -Mode Both -ApplyRuntime:$false。预生成后检查，确认同步用-ApplyRuntime:$true；-ValidateOnly校验正式源与输出是否一致。全量、客户端和服务端入口复用同一类型校验和前置检查。
- 服务端输出：generated/json_server与unityserver/config/json中的reward.json、maplist.json、fight_config.json、monster_boss_basic.json。通用转换器跳过这四张工作簿；上述输出不参与整表权威JSON覆盖。
- 客户端输出：World/maplist_dat.txt、World/main_dungeon_fight_dat.txt（id、show）、World/main_dungeon_monster_dat.txt（id、pic、scale），同步到Resources/ProjectXData/World。WorldVisualCatalog最后读取这两份主线展示投影，与服务端使用同一个正式fightID和怪物展示字段。两份主线文件是自动生成结果，无需单独维护。保留原World/fight_config_dat.txt、monster_boss_basic_dat.txt供未统一的其他功能使用。
- 运行同步检查只对本轮主线闭合负责：主线fightID、怪物引用、正生命/等级/展示字段、基础技能和阵法均须有效。非主线缺失fightID单独报告为deferredOtherFightIds，不生成占位战斗；支线6个缺失引用及其他功能的数据冲突后续按功能处理。此范围限制不表示其他玩法已一致或已验收。
- drop_type=1为必掉，weight=0；drop_type=2为随机候选，weight为正整数。同组必掉行全部发，随机候选按权重抽1行。允许只有一种类型，不添加空的另一类型占位。
- 单项奖励：[类型或道具ID,具体对象ID,数量]；四元组[类型或道具ID,具体对象ID,最小数量,最大数量]表示含上下限的随机整数数量。第二位不是品质。抽中候选行后发放该行全部奖励项。
- 关卡主奖励只通过rewardID结算，首次与重复通关采用同一奖励规则；藏书继续按来源规则结算。龙崖章节宝箱由下节的boss_reward维护，每次Boss胜利发放一次。first_reward、money、exp_pet、add_reward及AttackCount不再作为单机关卡运行输入。Hope保持当前0；次数使用既有255无限次数协议标记；普通扫荡沿用一请求最多5次，龙崖连战不经过该分支。
- export/server/authoritative/json/reward.json仅为正式表未维护的奖励编号提供兼容输入，当前7组、23条。正式表同编号完整覆盖整个兼容组，不拼接候选；当前运行JSON从不充当生成输入。
- 公式实际解析本表整数引用、加减乘除、括号和文本拼接，并翻译共享公式相对引用；不信任Excel缓存。战斗整数列中既有20个小于1e-9的浮点存储尾差按整数还原，真实小数拒绝；原始单元格不改写。其他函数/外部引用、循环、非整数或溢出结果在写入前拒绝。重复ID、空奖励、非法类型/权重/数量范围和缺失奖励引用同样拒绝。
- 定向回归：tools/tests/test_world_rewards.py。它用隔离、缩减的真实表引用夹具检查导出、拒绝非法输入、共享公式和主线/非主线边界，不模拟实际战斗。原生奖励规则为unityserver/tests/reward_rules_tests.cpp（kapai_reward_rules_tests）。2026-10-26已在高等级隔离Slot09实际验证前5章46关/58场，详情见.local/main-dungeon-acceptance-20261026/验证结果.md。该结果不代表新档体验或1266关逐关验收；随机藏书名称/图标显示链已在同日定向修正：副本奖励统一从正式客户端目录解析；第6章10场实际结算及通关奖励12项横向拖动通过，详见.local/world-reward-display-20261026/验证结果.md。最终画面仍待用户确认。配置同步与静态检查不能代替实际结算。


## 公共事件与任务条件（2026-10-27）

- 唯一维护源为excel/event_config.xlsx的event页；daily.xlsx/Sheet1只维护任务及event_id引用，不再维护condition数组。原148条任务的ID、类型、前置、境界、奖励和跳转保持；daily每日标记由公共事件cycle派生。
- GlobalEvents组通过UnityGlobalEventData.ps1统一类型校验/导出event.json、daily.json及客户端公共目录。All、客户端与服务端DataGroup入口均接入；daily不再被旧转换器或authoritative快照覆盖。旧快照仅留作迁移基线，不能回写。
- 入口：Export-UnityOwnedTables.ps1 -Group GlobalEvents -Mode Both；加-ValidateOnly只校验输出。禁用草案不导出；启用不支持的类型、周期或参数会拒绝，不能默默忽略。
- 当前162条事件启用，开局V1已接界面、对白、神将、装备、阵容、穿戴和章节事件；1015/1017任务示例仍禁用。任务与剧情引用同一个事件ID，进度仍各自归属存档。
- 当前公共层支持周期0/1；周重置和新增类型未接入前禁止启用。count_start=3与每日周期一致；类型参数沿用EMQCT语义，不混用休眠EMISS_DC任务动作。
- 现有业务UpdateQuestState作为兼容入口转发至GlobalEvents.Publish；现任务的条件判定走同一个公共Advance。存档任务编号与保存格式不变，不修改玩家SQLite。
- 客户端TaskStore读取Configs/daily，并从GlobalEventCatalog取得目标；Tasks/daily_tasks仅保留无condition的派生ID投影，已不是运行维护源。

- 当前启用162条事件（原任务147种条件+开局15条），另2条任务示例禁用。主表配置id/name/type/num/param1/param2/count_start/cycle/enabled；event_type解释程序规则，不能任意新增行为。
- count_start=1支持境界、指定关卡已通关一次、当前阵容和穿戴；其他历史累计禁止启用。count_start=2按订阅者生效后累积，3与每日重置一致。
- 定向回归入口：tools/tests/test_global_events.py；服务端离线命令kapai.exe --validate-global-events在InitDB之前返回，实际加载公共目录且不连接数据库。Unity Editor回归GlobalEventCatalogTests.Run读取真实Resources配置，验证148条任务引用同一个目录对象。上述检查不替代真实入口操作/领奖持久化验收。

## 开局剧情流程V1（2026-10-27）

正式维护源为excel/story_config.xlsx，触发/完成只引用公共event_config；奖励包40004（57×1）/40005（1001绿武器×1）在reward_fixed.xlsx。Story定向组统一导出步骤、对白及公共事件，新增奖励包先导出WorldRewards。参数、存档与11步流程以docs/unityclient/modules/OPENING_STORY.md为准。该组不会从旧mission_dialog或生成JSON反向取源。
