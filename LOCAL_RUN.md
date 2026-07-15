# 本地测试服运行步骤

## 当前结论

客户端 Win 模拟器已存在，可以启动：

```powershell
pwsh -ExecutionPolicy Bypass -File tools/local/Start-Client.ps1
```

服务端已可在 Windows 本机启动：

- 构建产物：`build/server-win/Debug/kapai.exe`
- 监听端口：`0.0.0.0:8711`
- 本地数据库：`fxl_game_local`
- 登录服：仓库缺失，当前走 `local_test=1` 直连游戏服。
- 客户端：`Start-Client.ps1` 可启动 Win 模拟器；`LOCAL_TEST_AUTO_ENTER=true` 时会自动直连、登录并进入本地角色。

先跑检查：

```powershell
pwsh -ExecutionPolicy Bypass -File tools/local/Check-LocalEnv.ps1
```

## 服务端运行目录

服务端硬编码读取当前目录下的 `config`，XML 路径为 `./xml/`，地图路径为 `dat/*.map`。

因此本地启动服务端时，工作目录必须是：

```text
server/config
```

`server/config/config` 已配置：

```ini
[database]
username=root
password=123456
dbname=fxl_game_local
host=127.0.0.1
port=3306

[server]
port=8711
local_test=1
local_user_id=1
script_dir=../script/
```

## 数据库

推荐：如果拿到完整基础库结构，例如 `base_schema.sql`，执行：

```powershell
pwsh -ExecutionPolicy Bypass -File tools/local/Init-LocalDb.ps1 `
  -BaseSchema "D:\path\base_schema.sql" `
  -ImportData
```

没有基础 schema 时不要直接导入 `_all_sql.sql`，因为它大量使用 `truncate/insert`，依赖已存在的表。

没有正式基础库时，可使用兜底 schema 尝试启动：

```powershell
pwsh -ExecutionPolicy Bypass -File tools/local/New-MinSchema.ps1
pwsh -ExecutionPolicy Bypass -File tools/local/Init-LocalDb.ps1 -ImportData
```

兜底 schema 只用于本地跑通链路，不等价于正式库结构；如果服务端启动后报缺字段，再按报错补 `New-MinSchema.ps1` 的手工字段列表。

## 构建服务端

本机有 `winget` 时，可先安装基础工具：

```powershell
pwsh -ExecutionPolicy Bypass -File tools/local/Install-LocalDeps.ps1 -IncludeMySql -IncludeBoost
```

Lua 默认复用客户端自带的 LuaJIT：`client/ProjectX/frameworks/cocos2d-x/external/lua/luajit`。
MySQL 默认识别 `C:\Program Files\MySQL\MySQL Server 8.4`。
Boost 默认通过 `tools/local/vcpkg` 安装并由 CMake toolchain 发现。

安装 CMake、MSVC、Boost thread/system、Lua、MySQL client 后执行：

```powershell
pwsh -ExecutionPolicy Bypass -File tools/local/Build-Server.ps1 `
  -BoostRoot "D:\deps\boost" `
  -MySqlIncludeDir "D:\deps\mysql\include" `
  -MySqlLibrary "D:\deps\mysql\lib\libmysql.lib" `
  -LuaIncludeDir "D:\deps\lua\include" `
  -LuaLibrary "D:\deps\lua\lua51.lib"
```

构建成功后启动：

```powershell
pwsh -ExecutionPolicy Bypass -File tools/local/Start-Server.ps1
```

## 启动顺序

1. `Check-LocalEnv.ps1`
2. 安装缺失工具和 MySQL。
3. 获取并导入包含 `CREATE TABLE role_info` 的基础 schema。
4. `Build-Server.ps1`
5. `Start-Server.ps1`
6. `Start-Client.ps1`

依赖、数据库、服务端二进制都就绪后，也可以一条命令启动：

```powershell
pwsh -ExecutionPolicy Bypass -File tools/local/Start-LocalAll.ps1 -InitDb -ImportData
```

## 一键验证

常规验证当前已启动的本地服：

```powershell
pwsh -ExecutionPolicy Bypass -File tools/local/Run-LocalVerification.ps1
```

需要自动启动 MySQL、服务端、客户端并跑 smoke：

```powershell
pwsh -ExecutionPolicy Bypass -File tools/local/Run-LocalVerification.ps1 -Start
```

需要从构建、启动到 smoke 全流程验证：

```powershell
pwsh -ExecutionPolicy Bypass -File tools/local/Run-LocalVerification.ps1 -Build -Start -RestartServer
```

刷新协议覆盖矩阵：

```powershell
pwsh -ExecutionPolicy Bypass -File tools/local/Export-ProtocolCoverage.ps1
```

低于 30 秒的分组验证：

```powershell
pwsh -ExecutionPolicy Bypass -File tools/local/Invoke-ProtocolSmoke.ps1 -Consumption
pwsh -ExecutionPolicy Bypass -File tools/local/Invoke-ProtocolSmoke.ps1 -Battle
pwsh -ExecutionPolicy Bypass -File tools/local/Invoke-ProtocolSmoke.ps1 -UiQueries
```

- `-Consumption`：改名、背包扩展、充值/支付回调等消费入口。
- `-Battle`：竞技场列表、动态机器人实战、观战/退出观战入口。
- `-UiQueries`：充值面板、封神列表、技能/物品描述、活动、挂机、历练、角色详情、闯关次数、仙缘等只读或 no-op UI 入口。
- 当前覆盖：服务端注册协议 143 个，smoke 已覆盖 128 个；剩余 14 个为服务端内部/跨服协议，`MSG_PLAY_ANIMATION/211` 在当前客户端未找到发送入口且依赖缺失的 `CgCallBack`，保留人工/原始脚本源码验证。

调试诊断表见 `LOCAL_DEBUG.md`，协议覆盖矩阵见 `PROTOCOL_COVERAGE.md`。
## Windows local MySQL

If MySQL Server is installed but no Windows service exists, start the workspace-local instance:

```powershell
pwsh -ExecutionPolicy Bypass -File tools/local/Start-LocalMySql.ps1
```

Then initialize/import the local database:

```powershell
pwsh -ExecutionPolicy Bypass -File tools/local/Init-LocalDb.ps1 -ImportData
```

`Start-LocalMySql.ps1` uses `.local/mysql-data` and keeps the root password aligned with `server/config/config` (`123456`).

## 当前 Windows 验证状态

已验证：

```powershell
pwsh -ExecutionPolicy Bypass -File tools/local/Build-Server.ps1 `
  -LuaIncludeDir (Resolve-Path tools/local/vcpkg/installed/x64-windows/include/luajit).Path `
  -LuaLibrary (Resolve-Path tools/local/vcpkg/installed/x64-windows/lib/lua51.lib).Path
```

```powershell
$exe = (Resolve-Path build/server-win/Debug/kapai.exe).Path
Push-Location server/config
Start-Process -FilePath $exe -WindowStyle Hidden
Pop-Location
Get-NetTCPConnection -LocalPort 8711 -State Listen
```

`kapai.exe` 已确认常驻，`8711` 已确认监听。

2026-07-06 追加验证：

- 服务端进程可常驻并监听 `8711`。
- `ProjectX.exe` 可由 `tools/local/Start-Client.ps1` 启动。
- 服务端可收到客户端 `MSG_LOGIN/1001`：`UserLogin id=1, serverId=1`。
- `local_test=1` 下服务端会自动创建/绑定本地角色 `Test01`，`roleId=1000001`。
- 客户端收到 `MSG_LOGIN/1001` 后会发送 `MSG_CHOOSE_HERO/1004`；`client/ProjectX/simulator/win32/local_client.log` 可看到 `DealMsgStartGame succ=1`。
- 最新状态：`kapai.exe` 与 `ProjectX.exe` 可同时常驻，TCP 保持 `Established`，客户端已越过登录等待层进入本地游戏主流程。
- Windows 本地 gyu 协议兼容点：
  - `MET_Unicode` 字符串按客户端 `NetMsgBase` 的 UTF-16LE 格式读写。
  - 4 字节长度字段表示 body length，不包含 6 字节包头。
  - 只有命令号、无 payload 的包合法，不能当作空包清连接。
  - 发送队列按 socket 保留多条待发包；快速初始化响应（例如 `MSG_CLIENT_GET_SAVE_VAL/146`）不能被单一 pending 包覆盖。
- 本地测试旁路：
  - `PRO_Func_HotPoint/65` 红点查询在 `local_test=1` 下统一返回不显示，避免依赖不完整生产库。
  - 6 分钟在线状态定时器在 `local_test=1` 下跳过 `server_list.onlineState` 写回，避免访问未连接的登录库。
  - `MSG_NEW_SHENQI/307` 已修复 `MakeNewShenQiBaseInfo()` 的 `vector` 越界。
- 本地 Lua 兼容：
  - `server/src/swigluarun.h`、`server/src/call_script.cpp`、`server/src/lua_j_stub.cpp` 已注册 `CUser *` userdata、常用 `j.*` 方法和旧式 `bit._and/_rshift` API。
  - `server/script/75.lua` 是可选弹窗脚本的本地占位文件，用于避免缺失脚本阻塞主流程。
- 本地保存修复：
  - `CUser::SaveDataSimple`、`CUser::NoLockSaveData`、`CBangPai::Save` 已按当前 MSVC/Boost 的 `boost::format` 实际消费顺序修正参数顺序。
  - 修复前会出现 `role_info` 保存字段错位、压缩串被当列名、`bang_pai where id=` 等 SQL 错误；修复后 `savefix1` 8 分钟长跑未再出现。
- 2026-07-06 追加长跑验证：
  - `kapai.exe` 与 `ProjectX.exe` 同时运行超过 6 分钟。
  - `127.0.0.1:8711` 保持 `Established`。
  - 服务端日志未再出现 `call:`、Lua `attempt to`、MySQL 空连接、Debug assertion、崩溃类错误。
- 2026-07-07 协议冒烟：
  - 基础脚本：`pwsh -ExecutionPolicy Bypass -File tools/local/Invoke-ProtocolSmoke.ps1`
  - 扩展脚本：`pwsh -ExecutionPolicy Bypass -File tools/local/Invoke-ProtocolSmoke.ps1 -Extended`
  - 操作分支脚本：`pwsh -ExecutionPolicy Bypass -File tools/local/Invoke-ProtocolSmoke.ps1 -Extended -Actions`
  - 可控改档脚本：`pwsh -ExecutionPolicy Bypass -File tools/local/Invoke-ProtocolSmoke.ps1 -Extended -Actions -Mutations`
  - 无效参数风险脚本：`pwsh -ExecutionPolicy Bypass -File tools/local/Invoke-ProtocolSmoke.ps1 -Extended -Actions -Mutations -InvalidRisky`
  - 一次性新角色组合脚本：`pwsh -ExecutionPolicy Bypass -File tools/local/Invoke-ProtocolSmoke.ps1 -UserId 707001 -RoleId 0 -AutoCreateRole -Extended -Actions -Mutations -InvalidRisky`
  - 一次性新角色正向脚本：`pwsh -ExecutionPolicy Bypass -File tools/local/Invoke-ProtocolSmoke.ps1 -UserId 709001 -RoleId 0 -AutoCreateRole -Extended -Actions -Mutations -Positive`
  - 覆盖：登录/选角、背包、系统时间、数值设置、字符串设置、红点、关卡地图、副本成就、体力、图鉴、血战、游历、世界等级、每日活动、VIP、抽神将、神将副本、藏宝图、试炼、阶段目标。
  - 扩展覆盖：坐骑、翅膀、任务列表、可接任务、称号、阵法、资源找回、帮派列表、我的帮派、客户端网络检测、心跳、等级/战力排行榜、离线经验面板、新神器基础/强化/当前信息、变身卡/当前变身信息、公告、充值 serverId、膜拜基础/面板、飞仙数据、任务追踪空查询、玩家自身信息。
  - 新增扩展覆盖：答题题目、帮助标题、日常 Boss 信息、钓鱼房间列表、擂台积分、好友列表/申请/礼物/黑名单/推荐、附近玩家、神将总览、角色名检查、自身角色查询、妖灵消耗、帮战信息、帮派副本章节/buff/活跃、PK 提示开关、免战牌 CD、交易行买入/寄卖/记录面板、鲜花自有/排行。
  - 操作分支覆盖：空背包格详情、隐藏坐骑/翅膀、血战排行/空宝箱、免费体力信息、空关卡宝箱/节点详情、商店列表、脱离卡死坐标、无效物品描述、神将装备/法宝列表、强化大师/搜索次数、无效可接任务详情、无效称号显示、单条字符串设置读取。
  - 可控改档覆盖：数值设置保存/读取、客户端字符串保存/读取、聊天频道关闭/开启、聊天开关查询、隐藏坐骑/翅膀、无效称号隐藏/取消使用。
  - 无效参数覆盖：商店购买/刷新/次数无效类型、阶段目标奖励、图鉴升级、空游历开始/领奖、无效帮派创建/申请、抽神将未知操作、关卡战斗/扫荡/重置、血战复活、神将装备穿戴/卸下/强化、法宝穿戴/卸下。
  - 一次性新角色覆盖：新 userId 登录、`PRO_CREATE_ROLE/1003` 创建隔离角色、`PRO_SELECT_ROLE/1004` 首次进服、主流程初始化回包、组合协议烟测。
  - 正向覆盖：有效创建帮派、帮派信息/成员/捐献信息查询、帮派铜钱捐献、免费体力领取尝试、抽神将单抽尝试、血战开始/挑战/重置、游历开始/领奖尝试、商店刷新/购买尝试、阶段目标领奖尝试。
  - 结果：基础/扩展/操作分支/可控改档/无效参数冒烟均有响应或安全返回，服务端日志未出现 SQL/Lua/assert/crash 类错误；操作分支、可控改档、无效参数后分别等待 7 分钟，保存线程和定时器也未产生新增错误。
  - 2026-07-07 新增结果：一次性新角色组合烟测创建了 `roleId=1000008`，收到 98 个回包；随后等待 7 分钟，`kapai.exe` 和 `ProjectX.exe` 均保持响应，`8711` 保持监听，服务端/客户端日志未出现 SQL/Lua/assert/crash 类错误。
  - 2026-07-07 正向结果：一次性新角色正向烟测触发 `script/200.lua` 缺 `j.GetFuncOpenLevel`，已在 `server/src/lua_j_stub.cpp` 补最小绑定；复测后正向协议均被处理或安全返回，随后等待 7 分钟，服务端/客户端日志未出现 SQL/Lua/assert/crash 类错误。
  - 2026-07-07 帮派创建结果：一次性本地角色已能有效创建帮派并写入 `bang_pai`/`bang_pai_role`；本地建帮会写入非 NULL 默认字段，启动时会修复旧本地 NULL 帮派行，避免 `CBangPaiManager::Init()` 重启读取崩溃；`local_test=1` 下缺少帮派副本章节配置时静默跳过该可选初始化告警。
  - 2026-07-07 新增扩展结果：一次性新角色烟测覆盖心跳、排行榜、离线经验、新神器、变身、公告、充值 serverId、膜拜、飞仙数据、任务追踪、答题、帮助标题、日常 Boss、钓鱼房间、擂台积分、玩家自身信息、脱离卡死坐标、无效物品描述后收到 `recv_count=117`；服务端/客户端日志未出现 SQL/Lua/assert/crash/config-error 类错误。
  - 2026-07-07 Lua/题库修复：为本地 Lua stub 补 `j.GetQuestion`、`j.GetDailyBossExp`、`j.MakeDailyBossInfo`、`CUser:GetVal`、`CUser:SetVal`、`CUser:GetBossMissionStarInfo`；修复 `FormatMission` 分隔符解析；本地启动会补齐 `question` 表字段和至少 21 条默认题，满足 `CUser::GetQuestionId()` 的题库数量要求。
  - 2026-07-07 help 本地降级：`local_test=1` 下帮助标题/内容请求返回空列表或失败包，不再访问缺失的登录库 `help` 表。
  - 2026-07-07 扩展覆盖追加：一次性新角色烟测覆盖好友、妖灵、帮战、PK 提示、免战牌、交易行、鲜花、无效猜拳、空实名后收到 `recv_count=134`；服务端/客户端日志未出现 SQL/Lua/assert/crash/config-error 类错误。
  - 2026-07-07 扩展覆盖再次追加：一次性新角色烟测覆盖附近玩家、神将总览、角色名检查、自身角色查询、建帮后的帮派副本章节/buff/活跃查询后收到 `recv_count=142`；服务端/客户端日志未出现 SQL/Lua/assert/crash/config-error 类错误。
  - 2026-07-08 工具化验证：`Run-LocalVerification.ps1` 已跑通当前服务端运行态，自动创建一次性角色并执行 `-Extended -Actions -Mutations -Positive` smoke，日志扫描未发现 SQL/Lua/assert/crash/config-error 类错误。
  - 2026-07-08 协议覆盖矩阵：`Export-ProtocolCoverage.ps1` 已生成 `PROTOCOL_COVERAGE.md`，当前统计为服务端注册协议 148 个、smoke 已覆盖协议号 67 个、未覆盖注册协议 81 个。
  - 边界：真实扣费购买、真实领奖、真实升级、真实抽卡奖励、战斗结算、有效加入已有帮派仍需用一次性本地角色单独验证，当前不能宣称“全功能已完整人工验收”。

注意：

- 缺 `libssl-3-x64.dll` 时，从 `C:\Program Files\MySQL\MySQL Server 8.4\bin` 复制 `libmysql.dll`、`libssl-3-x64.dll`、`libcrypto-3-x64.dll` 到 `build/server-win/Debug` 或 `server/config`。
- 本地库不是完整生产库，`local_test=1` 下会放行商店、活动、排行、充值档等非登录关键模块的初始化缺表/缺列错误。
- `server/config/config` 中 `local_user_id=0` 表示使用登录包传入的 userId；客户端默认仍是 userId=1，会自动绑定 `Test01`，烟测可传入新 `-UserId` 并用 `-AutoCreateRole` 创建隔离角色。本地一次性角色会补齐 `ReadData()` 需要的空字段，并以 60 级和测试货币创建，用于穿过部分正向功能门槛，包括有效创建帮派。
- 后续手动点击更多功能时，如出现新的 `call:` 脚本错误，优先按日志补 `lua_j_stub.cpp` 的最小绑定或本地测试旁路，不要恢复整套缺失私有 SWIG/登录服链路。
- 已补本地兜底表字段：`huodong_time`、`qin_mi_log`、`mei_li_history`、`mei_li_paihang`、`cz_to_other_reward`、`zha_dan_info`、`zha_dan_log`、`festival_award`、`hd_bang_goods`、`taohuageng_config`、`hd_paihang_info`、`hd_rand_award`、`item_score_exchange`、`hd_paihang_record`、`money_giftbag_huodong`、`hd_chou_record`、`money_giftbag_pay`、`hd_save_data`、`qiang_hongbao_record`、`notice_login`、`question`、`user_info1`、`role_info`。
