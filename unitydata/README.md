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
    -> unitydata/export/server/authoritative/json 覆盖 11 张服务端权威表
    -> unityserver/config/json
```

`unitydata/excel` 保存Unity正式Excel输入（截至2026-10-11递归共68个文件，其中8个为本轮新增工作簿）。旧通用转换器只处理其合同内的旧工作簿；`unity-owned-tables.json`登记的工作簿由`Export-UnityOwnedTables.ps1`处理，境界及角色外观沿用专用导出器，均不依赖外部`concept`路径。

`unitydata/export/server/authoritative/json` 保存当前 Unity 服务端基线中的 11 张权威快照：`daily`、`drop_matching`、`function`、`item`、`level_reward`、`mission_dialog`、`reward`、`sevendays`、`shop_config`、`shop`、`xiulian`。这些表以现有服务器数据为准，覆盖原始 Excel 转换结果；原始 Excel 差异仍记录在 `.local/unityserver-export/latest.json`，但不会再阻断导表。使用 `-ApplyGeneratedJson` 会把合并后的结果同步到 `unityserver/config/json`。

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
