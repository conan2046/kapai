# Codex Project Notes

## Codex 性能与运行时生命周期
- 本项目只有一套本地服务端：workspace-local MySQL + `kapai.exe`；有两套客户端：Cocos `ProjectX.exe` 与 Unity Editor/Player。
- 每个任务开始先判断目标是服务端、Cocos 客户端还是 Unity 客户端；只启动当前操作必需的进程，不继承上个任务的运行状态。
- 文档、代码阅读和静态修改默认不启动 MySQL、`kapai.exe`、Cocos 客户端、Unity 或 Unity MCP。
- 服务端/协议任务按需启动 MySQL 和 `kapai.exe`；Cocos 联调只加 Cocos 客户端；Unity 联调只加 Unity，禁止两套客户端同时常驻。
- Unity 纯 C#/Lua 文件修改先静态完成，只在编译、场景、Prefab、Console 或 PlayMode 验收阶段启动 Unity/MCP。
- 功能阶段验收完成后，关闭本阶段启动的 Unity、Unity Hub、Cocos Simulator、`kapai.exe` 和 workspace-local MySQL；需要长跑 L5 或用户明确要求持续运行时除外。
- 一个重任务同时只运行一个；16 GB 本机可用内存低于 4 GB 时停止新增任务，低于 2 GB 时停止重任务。
- 单次终端输出不超过 200 行，日志默认只读尾部 100 行；大输出落盘到 `.local/`，不灌入对话。
- 单任务文件达到 15 MB 预警，达到 20 MB 时更新 HANDOFF 并新开任务。
- 根目录 `.svn/`、Unity `Library/Temp/Logs`、`build/`、`.local/` 和 `tools/local/vcpkg/` 默认不扫描、不统计内容，除非当前问题明确指向它们。

## Agent 命令执行环境规范
- 执行命令时，请始终优先选择 **PowerShell 7 (pwsh.exe)**，而不是旧版的 **powershell.exe**
- 这样能保证命令执行全部采用 UTF-8 编码，避免中文乱码问题及 BOM 错误

## 项目定位
- 这是 Cocos2d-x 2.17 + Lua 前端、C++ 后端的联网卡牌游戏。
- 当前仓库没有独立登录服源码；本地测试服采用最小改动的“无登录服直连游戏服”模式。

## Unity 迁移文档读取与维护
- Unity 迁移任务默认读取顺序：`UNITYCLIENT_STATUS.md` → `docs/unityclient/MIGRATION_GUIDE.md` → `docs/unityclient/modules/README.md` → 目标模块文档/控件矩阵。
- `UNITYCLIENT_STATUS.md` 是完成率、当前批次、最新验证的唯一状态源；其他文档禁止维护第二份实时百分比。
- `docs/unityclient/MIGRATION_GUIDE.md` 是路线、G0-G6、功能/视觉完成标准、工具入口和高频坑的唯一稳定文档，禁止再建平行SOP、交接或计划。
- 模块协议、实现和验证证据写入 `docs/unityclient/modules/`；机器控件证据写入 `docs/unityclient/matrices/`；日期流水与旧全文写入 `docs/unityclient/history/`。
- 新任务不得默认完整读取 `docs/unityclient/history/`；只有追查旧命令、错误或决策证据时才定点检索。
- Unity 新模块先读取 `tools/unity-migration/unityclient-modules.json`，优先使用 `Get-ProtocolEvidence.ps1`、`New-UnityMigrationModule.ps1`、`Run-UnityModuleValidation.ps1` 和 `Test-UnityMigrationDocs.ps1`，不得重复创建平行工具。
- 严格按 `MIGRATION_GUIDE.md` 的 G0-G6 门禁推进；同一时间只处理一个模块，上一门禁未通过不得编码、切阶段或开启下一模块。任何跳过门禁必须先记录阻塞并取得用户明确批准。

## 分析与修改范围
- 分析业务代码时优先看 `client/ProjectX/src/`、`client/ProjectX/res/`、`server/src/`、`server/script/`、`server/config/`、`server/sql/`、`tools/local/`。
- 默认忽略生成物和第三方依赖：`build/`、`.local/`、`tools/local/vcpkg/`、客户端/服务端日志、MySQL data 目录。
- `tools/local/vcpkg/` 是外部依赖副本，不要为了统一规则或格式去批量修改。

## 任务类型到源码入口
- 登录/进服/创角：`server/src/pack_deal.cpp` 的 `UserLogin/CreateRole/SelectRole`，客户端 `client/ProjectX/src/core/AppDef.lua`。
- 协议功能：先查 `server/src/protocol.h` 协议号，再查 `server/src/pack_deal.cpp` 的 `cmdFun.push_back` 和对应 `*Option` 函数。
- 服务端 Lua 报错：先查 `server/script/*.lua` 调用点，再在 `server/src/lua_j_stub.cpp` 补最小绑定或本地测试旁路。
- 数据库缺表/缺字段：优先补 `server/sql/local_min_schema.sql` 或 `local_test=1` 启动 bootstrap；不要用正式库猜测大面积结构。
- Windows 编译/运行兼容：优先查 `server/src/win_compat.h`、`server/src/gyu/`、POSIX shim 头文件。
- 客户端本地启动：`tools/local/Start-Client.ps1` 同步 Lua/res 后启动 `client/ProjectX/simulator/win32/ProjectX.exe`。

## 标准调试与验收流程
- 遇到错误先定位根因：复现协议/操作、看服务端日志、看客户端日志、查对应源码，不做无证据猜修。
- Unity 迁移定位 Cocos 界面时，固定先完成：主界面按钮名/模块 ID → Lua 点击回调 → `Utils:OpenFunction/InitUI` → 当前 View/Controller → 完整 CSB/CSD 路径 → 动态节点/Timeline/Imod 调用。链路未打印清楚前禁止启动客户端靠截图找界面。
- 历史截图必须先核对窗口标题、页面标题、账号/角色、步骤、分辨率和目标节点；任一不符即标记无效。禁止仅凭文件名（如 `cocos-formation*.png`）当作目标模块基准。
- `Invoke-ClientWindow.ps1` 点击只允许按已确认控件坐标执行一次。后台消息、同步前台消息或真实点击首次未进入目标页时，立即停止坐标试错，转查 Lua 回调、客户端日志、协议回包或现有模块自动化；禁止连续截图主界面碰运气。
- Cocos 自动化暂时无法进入页面时，先用 Lua/CSB/资源调用链完成可证静态修复，并把“缺有效 Cocos 动态截图”作为门禁保留；不得用 Unity 单端截图、错误历史截图或重复点击伪造视觉通过。
- 每个可见界面及其关键状态必须先取得有效 Cocos 截图；Unity 修复后必须按同账号、同数据、同操作、同分辨率和同稳定帧截图，与 Cocos 逐项对比文字、图片、坐标、尺寸、层级、裁剪、动画和交互，并保存叠加图/差异报告。缺任一侧截图或差异报告时只能标记逻辑通过；占位文字、错误图片、文本截断/重叠、公共层遮挡均视为视觉未通过。
- Cocos 与 Unity 动态资源对照必须核对资源类型与播放语义：静态 `Image`、CSB Timeline、Imod 模型不可互相替代；例如 `CreateAnimModel + PlayStand` 必须迁为对应 Imod 资源、动作号、循环、缩放和挂点，禁止用同角色半身像代替。
- 常见错误诊断表见 `LOCAL_DEBUG.md`。
- 协议覆盖矩阵见 `PROTOCOL_COVERAGE.md`，可用 `tools/local/Export-ProtocolCoverage.ps1` 刷新。
- 一键本地验证用 `tools/local/Run-LocalVerification.ps1`；它会串联环境检查、可选构建/启动、协议 smoke 和日志扫描。
- 验收分级：
  - L1：`kapai.exe` 启动并监听 `8711`。
  - L2：`ProjectX.exe` 可进入本地主流程。
  - L3：基础 smoke 无 SQL/Lua/assert/crash。
  - L4：`-Extended -Actions -Mutations -Positive` 组合 smoke 无错误。
  - L5：定时器/保存线程长跑后无新增错误。
  - L6：客户端人工点击所有主要 UI 功能点无错误。

## 本地测试服规则
- 客户端本地直连开关在 `client/ProjectX/src/core/AppDef.lua`：
  - `AppDef.LOCAL_TEST = true` 时跳过登录服。
  - 本地游戏服默认 `127.0.0.1:8711`。
- 服务端本地测试开关在 `server/config/config`：
  - `[server] local_test=1` 时跳过登录库中的 `server_list/db_config/sig_log` 校验。
  - `local_user_id=0` 表示使用客户端/烟测传入的 userId；默认客户端仍是 userId=1。
  - 游戏库仍使用 `[database]` 配置。
  - `[long_server].port=0`、`[queue].port=0` 表示本地测试时不注册长连接服/匹配服。
- 不要删除原登录服/线上逻辑；本地测试只能通过开关旁路。
- 本地运行步骤见 `LOCAL_RUN.md`。
- 常用脚本在 `tools/local/`：
  - `Check-LocalEnv.ps1`：检查客户端、服务端配置、MySQL、编译器、基础 schema。
  - `Init-LocalDb.ps1`：拿到基础 schema 后创建并导入 `fxl_game_local`。
  - `New-MinSchema.ps1`：从现有 SQL/源码生成应急 schema，默认写入 `.local/generated_min_schema.sql`，不覆盖仓库基准。
  - `Export-LocalSchema.ps1`：从已验证本地库导出纯结构 `local_min_schema.sql` 并附加本地启动必需种子，不包含账号、角色和业务流水。
  - `Install-LocalDeps.ps1`：通过 winget 安装 CMake、VS Build Tools、可选 MySQL，并用固定 vcpkg 提交安装 Boost、LuaJIT、Zlib。
  - `Build-Server.ps1`：用 CMake 构建 Windows 服务端，并默认把运行 DLL 部署到 `kapai.exe` 同目录；可用 `-BuildDir` 做独立干净构建。
  - `Start-Server.ps1`：以 `server/config` 为工作目录启动服务端。
  - `Start-Client.ps1`：同步 Lua/res 并启动 Win 模拟器。
  - `Start-LocalAll.ps1`：依赖齐全后串联检查、可选初始化数据库、启动服务端和客户端。
  - `Invoke-ProtocolSmoke.ps1`：连接已启动的本地游戏服，执行登录/选角和一组无消耗查询协议冒烟；加 `-AutoCreateRole` 可用一次性 userId 创建隔离测试角色，加 `-Extended` 可覆盖更多界面查询入口，加 `-Actions` 覆盖低风险错误分支/空状态操作，加 `-Mutations` 覆盖可控本地改档操作，加 `-Positive` 覆盖部分正向消耗/领奖/战斗入口，加 `-InvalidRisky` 覆盖无效参数/异常分支。
  - `Export-ProtocolCoverage.ps1`：从 `protocol.h`、`pack_deal.cpp`、`Invoke-ProtocolSmoke.ps1` 生成协议覆盖矩阵。
  - `Run-LocalVerification.ps1`：串联环境检查、可选构建/启动、协议 smoke、日志扫描，用于本地验证收口。
  - `Test-FreshLocalSetup.ps1`：创建隔离数据库和临时端口，用指定干净 EXE 验证登录、创角与基础协议，不修改正式本地库。
  - `Invoke-ClientWindow.ps1`：枚举 `ProjectX` 顶层窗口并优先选择 `Cocos Simulator` 游戏窗（不要误用调试控制台句柄），按游戏窗口句柄截图或发送窗口相对坐标消息；截图禁止截桌面。默认后台操作；只有用户明确允许时才能使用 `-ActivateForeground -RealClick` 临时置前和真实点击，并用 `-RestoreForegroundAfter` 恢复原窗口。主界面控件不响应后台消息时不得伪造 L6 通过。

## 编译与运行约束
- 服务端已补 `server/src/gyu/*.cpp` 兼容实现，构建时优先使用仓库内源码，不再强依赖外部 `/usr/local/gyu/lib/libgyu`。
- Linux 可继续用 `server/src/makefile`；Windows 优先用 `server/CMakeLists.txt` 生成 VS/MSVC 工程。
- Windows 原生构建仍需要本机安装 C++ 编译器、Boost thread/system、Lua、MySQL client；Zlib/OpenSSL 为可选增强依赖。
- `server/CMakeLists.txt` 预留了 `BOOST_ROOT/MYSQL_INCLUDE_DIR/MYSQL_LIBRARY/LUA_INCLUDE_DIR/LUA_LIBRARY`。
- 为保留最小改动，业务代码里的 POSIX socket include 通过 `server/src/sys/socket.h`、`server/src/netinet/in.h`、`server/src/arpa/inet.h` 做 Windows 兼容。
- 服务端本地启动工作目录必须是 `server/config`，因为程序读取当前目录的 `config`、`xml/`、`dat/`；`script_dir` 应指向 `../script/`。
- 客户端 Win 模拟器入口为 `client/ProjectX/simulator/win32/ProjectX.exe`。

## 修改原则
- 优先做最小改动，保留线上路径默认可恢复。
- 涉及中文文件时使用 UTF-8。
- 不要凭空补登录服协议；若需要账号登录流程，单独实现本地假登录服或拿原登录服源码。

## Git 提交规则
- 只有用户明确要求后才执行暂存、提交或推送。
- 每次提交必须写详细提交说明，禁止只有一句标题。
- 标题应简明概括目标；正文至少写清：修改模块/文件、问题根因、具体修复、SQL 或配置变化、验证命令与结果、已知限制或外部依赖。
- 多模块提交使用分点正文，确保另一台电脑仅查看提交记录也能判断需要重新编译、重建数据库或补外部依赖。
- 已推送提交不为补写说明而强制改写历史；后续提交严格执行详细说明。

## Windows local-run additions
- `tools/local/Start-LocalMySql.ps1` starts a workspace-local MySQL 8.4 instance with data under `.local/mysql-data`; it does not install or modify a Windows service.
- `server/src/win_compat.h` is force-included by MSVC builds and centralizes Windows compatibility for `access/R_OK`, `bzero`, `strtok_r`, `gettimeofday`, and legacy `auto_ptr` usage.
- `server/src/boost/*.hpp`, `server/src/swigluarun.h`, and POSIX shim headers are local compatibility shims for the missing private/Linux toolchain pieces; keep them scoped to local Windows test-server work.
- Windows/MSVC build now produces `build/server-win/Debug/kapai.exe`.
- The MySQL client DLL dependency chain must sit beside the exe or in `server/config`: `libmysql.dll`, `libssl-3-x64.dll`, `libcrypto-3-x64.dll`.
- `local_test=1` is allowed to degrade non-login-critical optional systems such as shop/activity/rank/recharge initialization so the local game server can listen without the full production database dump.
- Windows protocol compatibility in `server/src/gyu/` must match the legacy Cocos simulator: strings use UTF-16LE when `MET_Unicode` is set, the 4-byte length field is body length excluding the 6-byte header, and zero-payload command packets are valid.
- `server/src/gyu/g_socket_server.cpp` keeps a per-socket send queue on Windows; do not replace it with a single pending message, or rapid init responses such as `MSG_CLIENT_GET_SAVE_VAL/146` can be dropped or crash under MSVC Debug.
- Local-test-only degradations now include red-point responses (`PRO_Func_HotPoint/65`) returning hidden state instead of querying incomplete production tables.
- Local-test-only degradations also skip login-server online-state writeback (`server_list.onlineState`) because `local_test=1` intentionally does not connect `g_LoginDB`.
- Local Lua compatibility is partial but enough for login/main-init validation: `server/src/swigluarun.h`, `server/src/call_script.cpp`, and `server/src/lua_j_stub.cpp` register `CUser *`, selected `j.*` helpers such as `GetFuncOpenLevel`, and the legacy `bit._*` API expected by shipped scripts. Extend this stub from concrete `call:` log errors instead of restoring broad private SWIG output.
- `server/script/75.lua` is a local placeholder for an optional popup script referenced by this checkout but not shipped.
- Fixed local Windows crash points are kept as regression rules: `CUser::MakeNewShenQiBaseInfo()` must not iterate past `shenqiList.size()`, `server/src/gyu/g_socket_server.cpp` must not clear valid coalesced packets when body length is zero, and send queue handling must preserve multiple pending responses per socket.
- MSVC/Boost local build treats `boost::format("%2%")` placeholders as consumed in occurrence order in existing code paths. Keep local save SQL argument order aligned with SQL occurrence order.
- Local role creation is supported for disposable protocol tests: default userId 1 still auto-binds `Test01`, other local userIds can create a role through `PRO_CREATE_ROLE/1003`; local `CreateRole` fills the nullable minimal-schema fields that `CUser::ReadData()` expects, and disposable roles start at level 60 with local test currency so positive protocol gates can be exercised.
- Local guild creation is covered by positive smoke: local disposable roles get enough `TongBao` for `PRO_BANGPAI/54` op 1, `CBangPaiManager::CreateBangPai` inserts non-null local defaults for guild text/blob fields, and `CBangPaiManager::Init()` repairs older local NULL guild rows before reading them. `local_test=1` also suppresses the optional guild-copy chapter config warning when the local resource pack lacks `EBMT_BangPaiCopy` map data.
- Local bootstrap repairs the minimal `notice_login` table by adding `title/msg/showType/jumpType/beginTime/endTime` when missing; this is required for `PRO_GONGGAO/88` in local smoke.
- Local bootstrap repairs the minimal `question` table by adding `question/answer1/answer2/answer3/answer4`, filling empty fields, and ensuring at least 21 rows because `CUser::GetQuestionId()` rejects smaller question pools.
- Local Lua compatibility now includes the concrete bindings required by extended smoke: `j.GetQuestion`, `j.GetDailyBossExp`, `j.MakeDailyBossInfo`, `CUser:GetVal`, `CUser:SetVal`, and `CUser:GetBossMissionStarInfo`. Keep future additions driven by concrete `call:` log errors.
- `local_test=1` makes help-title/content requests return empty/error packets without querying the absent login DB `help` table.
- Historical verification evidence belongs in `LOCAL_HISTORY.md`; do not append long dated smoke records to this file.
- Current runbook is `LOCAL_RUN.md`; diagnosis table is `LOCAL_DEBUG.md`; generated coverage matrix is `PROTOCOL_COVERAGE.md`.
