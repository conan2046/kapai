# 本地卡牌项目调试交接

> 当前交接：2026-07-27 Mail G0-G6 passed / 13/13 complete
> 本节覆盖下方 2026-07-16 的旧交接；旧内容只作为历史参考。

## 0. 2026-07-27 新窗口直接执行

### Mail 已收口

- 门禁：`G0-G6 passed / 13/13 complete`；严格完成率 `5/29 = 17.2%`。
- G4 隔离账号 `7200096/1000151`：13/13 真实控件、5/5 语义断言、5 张互异原生 `1334×750` 图通过；覆盖 `/128 op2/3/4`、重复失败、串行一键领取、批量已读、本地删除、空态、重进、断线和切号隔离。
- G5 固定账号 `7200057/1000115`：同一批 14 封邮件完成 4/4 Cocos/Unity 原图与差异；数据库基线哈希 `3e3588a207e5c6d309391bb0a0bbb5cde40b60ffd17b6d3d4eace0d0aa9b1098`，重登录后再次精确恢复，夹具残留 0。
- 已批准差异：Cocos 左列表不滚，Unity 已修为真实滚动；Cocos 附件详情错显 `数量:0`，Unity 显示权威 `数量:10`。
- Unity 复用真实 `OneLevelLayer` 一级框架和 `common/huoqutujing` 公共详情；空态、完整日期/删除时间、活动使者标题、附件视口和旧附件误点竞态均已修复。
- 正式 `BootstrapSceneBuilder.BuildBatch` 连续两次 SHA-256 均为 `B27460DB36051DA396630CFF66EDED1115F3C3CB8148388F9574AA60A92D19AE`。
- 证据：`.local/unity-validation/mail-latest.json`、`.local/ui-fidelity/Mail/compare/g5-live-20260727/`、`docs/unityclient/matrices/MAIL_CONTROLS.json`。
- Unity、Cocos、`kapai.exe` 已停止；workspace-local MySQL 按项目既有状态保留。下一任务重新选择模块并从 G0 开始。
- 未提交的其他工作仍不得暂存/覆盖：7 个 xLua `.meta` 删除、`unityclient/.vscode/`、`tools/local/Optimize-CodexLogsDatabase.ps1`、行尾异常 Lua。

### Task 已收口

- Task 门禁 `G0-G6 passed`，矩阵 `14/14 complete`；严格完成率更新为 `4/29 = 13.8%`。
- 固定账号 `7200057 / roleId=1000115` 从真实 `btn_renwu` 入口完成 Cocos/Unity 原生 `1334×750` 的 `11/11` 关键状态，并排、50%叠加、增强差异和人工视觉均通过。
- `/37` 列表 `op=1,type=2/0`、领奖 `op=3,type=2/0,task_id`，以及 `/39`、`/65 type=101` 已按 Lua 权威/C#渲染镜像接入。
- 14项真控件覆盖关闭、体力/铜钱加号、禁用通宝、唯一每日页签、列表滚动、奖励物品、前往、领取/已领取、四档宝箱和奖励弹窗确认/关闭。
- 重复/非法领取、关闭重载、断线重连、持久化和切号清理通过；最终隔离回归为 `7200085 / roleId=1000140`，严重异常0、Python UI `16/16`。
- 固定账号夹具注入前、精确恢复后及重登录后哈希均为 `99ccff91ef8285ff80565658ce2366ec615682a30ebc48378f452ac341494d29`；`setupAssertSql/cleanupAssertSql/restoredHashAssertSql` 全部通过。
- 正式 `BootstrapSceneBuilder.BuildBatch` 连续两次 SHA-256 均为 `B27460DB36051DA396630CFF66EDED1115F3C3CB8148388F9574AA60A92D19AE`。
- 证据：`.local/unity-validation/task-latest.json`、`.local/ui-fidelity/Task/compare/g5-live-20260727/manual-acceptance.json`、`.local/ui-fidelity/Task/unity/g5-20260727/task-fixed-fixture-snapshot.json`。
- Task 已成为通用回归样板：`Run-UnityFixedAccountValidation.ps1` 负责快照、注入、矩阵覆盖、精确恢复和重登录复核；`New-UnityModuleG5Evidence.ps1` 负责双端输入哈希、提交来源与差异报告。旧 Task 脚本保留为兼容薄封装。
- 下一模块固定为 Mail：先冻结红点、列表、已读、详情、附件、单封/一键领取、删除确认、关闭、滚动、空态、错误、重拉/重连/切号，不得直接沿用旧第一阶段结论。
- 保留且不得暂存/覆盖：7个 xLua `.meta` 删除、`unityclient/.vscode/`、`tools/local/Optimize-CodexLogsDatabase.ps1`、两个仅行尾异常 Lua。

### Bag 已收口

- 只处理 Bag 的任务已完成；门禁 `G0-G6 passed / 26/26 complete`，下一任务重新选择模块并从 G0 开始。
- 固定隔离账号 `userId=7200057 / roleId=1000115`，Windows 100%，Cocos/Unity 原生 `1334×750`；测试数据为可逆本地夹具，不是正式服/生产数据。
- Cocos/Unity 原图、逐控件并排、50% 叠加、增强差异、真实控件自动化与人工视觉均 `26/26 passed`：`.local/ui-fidelity/Bag/compare/g5-live-20260727/`。
- 真实 `/8`、`/15` 的全量、增量、整理、批量/礼包/直接使用、失败拒绝、重拉、断线重连、持久化和切号清理通过：`.local/unity-validation/bag-latest.json`。
- Cocos 列表不滚动缺陷已在 Unity 修复；目标玩法未迁移时保持 Bag 并记录不可用目标，不再跳转无数据神将空壳。
- 正式 `BuildBatch` 两次 SHA-256：`B27460DB36051DA396630CFF66EDED1115F3C3CB8148388F9574AA60A92D19AE`；严重异常 0、Python UI 16/16、文档 29 模块一致。
- G6 后已确认固定角色原背包 `78da63601805a360140c77000003e80001` 与体力 100 恢复；Unity、Cocos、`kapai.exe` 均为 0 进程，既有 workspace-local MySQL 保持运行。
- 远端/本地基线 SHA：`1ae7dee8f456d61f1d50812a4945b0748d5274c2`。
- 保留且不得暂存/覆盖：7 个 xLua `.meta` 删除、`unityclient/.vscode/`、`tools/local/Optimize-CodexLogsDatabase.ps1`、两个仅行尾异常的 Cocos Lua 文件。

### HeroEquip 已完成

### HeroEquip 当前续接

- 未提交硬门禁工具已收口：PowerShell 语法、29 模块文档、16/16 Python UI、PlayerHud Preflight/DryRun、HeroEquip 正反向 Preflight、Unity 编译严重错误 0 均通过。
- `Test-BootstrapSceneIdempotence.ps1` 已按正式 `BootstrapSceneBuilder.BuildBatch` 连续执行两次，SHA-256 均为 `408E3FF9E994AA681B9805AF28F598F2023126E44B00EF55D0BFCACB0C49FEDC`。
- HeroEquip 新矩阵：`docs/unityclient/matrices/HERO_EQUIPMENT_CONTROLS.json`，共 33 控件；Manifest 已声明，G0 机器 Preflight/DryRun 通过。
- G1 已通过：固定账号 `7200057 / roleId=1000115` 从真实入口完成前台自动化，重采 20 张原生 `1334×750` Cocos 基准，覆盖装备/法宝背包、隐藏已穿戴、碎片、帮助、详情、强化前后、更换、卸下/重穿、材料不足、非法 UID 与重复操作。
- G2 已通过：重新冻结 `/319 op1/2/3/4/16/17/18/19/22` 的字段顺序与状态规则、Lua 权威、9 个 Prefab、33 控件、3 份配置和装备/法宝独立资源域；修正协议 smoke 的 3 个旧错位负例。
- G3 已通过：Unity MCP 编译、Bootstrap 强制重建、六个 HeroEquip View/Presenter 初始化及装备/法宝/碎片页面运行时检查均通过，Console 0 error / 0 warning。下一步只执行 G4 联机成功/失败/重拉/重连/切号闭环。
- G4 已通过：固定账号 Unity MCP 真实 Button 完成装备/法宝穿脱、装备强化、材料不足、非法 UID、重复卸下、断服重启重连、正常断开持久化和切号清理；修复普通强化误进自动化卸下链及法宝失败包错读字段。下一步只执行 G5 双端视觉与 33 控件人工验收。
- G5 已通过：Cocos/Unity 原图、并排/叠加/差异和人工验收均 `20/20`；强化页白块补为真实主角头像。
- G6 已通过：控件矩阵 `33/33`，装备4/法宝2、缺图0、严重异常0；单次强化 UID `2121072641` 本轮 `8→10→12`；正式 `BuildBatch` 两次 SHA-256 均为 `188BFD6307DFB0B0F195596D94E95ACE2E103343B8C28057F8AD5A13F580CACB`。
- 证据：`.local/ui-fidelity/HeroEquip/compare/g5-live-20260726/manual-acceptance.json`、`.local/unity-validation/hero-equip-g6-control-runner.json`。
- 当前任务已收口，不开启下一模块；下一任务重新从状态表选择一个模块执行 G0。
- 当前保留项不变：7 个 xLua `.meta` 删除和 `unityclient/.vscode/` 不覆盖、不暂存。

### 当前目标

- 只处理《道友来封神》神将/阵容，不开启新模块。
- 当前门禁：`G0-G6 passed`，神将/阵容 `16/16 complete`。
- G4 已完成：同账号 `7200057` 的16项真实 Button 主链、锁定/非法失败态、阵位 `1→2→1` 权威恢复，以及真实断线→重启服务→重连→重新登录→第二轮16控件复验。
- G4重连证据：`.local/unity-validation/hero-g4-reconnect-user7200057.json`。
- 最终 Runner、16/16真实 Button、严重异常扫描、双端视觉人工验收均已通过；G5、G6门禁已收口。
- G6机器证据：`build/ui-migration/bootstrap-app-result.json`、`build/ui-migration/bootstrap-hero.png`、`build/ui-migration/bootstrap-idempotence-1.log`、`build/ui-migration/bootstrap-idempotence-2.log`；纳入 `ChatLayer` 后按正式 `BuildBatch` 契约双次验证，最终幂等 SHA-256 为 `408E3FF9E994AA681B9805AF28F598F2023126E44B00EF55D0BFCACB0C49FEDC`。
- G5全解锁夹具已补到固定账号 `7200057 / roleId=1000115`：等级60、神将57+64、阵位1穿戴 `1001..1004` 四件装备、法宝 `1001/1002` 两件、主线推进覆盖 `10006/10016/10019/10020`；协议穿戴错误0，压缩存档长度 `pet=84 / pet_equip=100 / guan_qia=424`，证据 `.local/unity-validation/hero-g5-fixture-user7200057.json`。

### G5结果

1. 用户已放宽禁止前台限制；固定账号 `7200057 / roleId=1000115`、同数据、原生客户区 `1334×750` 已重新采集 Cocos 16/16 原图：`.local/ui-fidelity/Hero/cocos/g5-live-20260726/`。
2. Unity 已在相同账号/数据下重新采集16/16原图：`.local/ui-fidelity/Hero/unity/g5-HERO-*.png`。
3. 并排、50%叠加、像素差异和聚合指标已生成：`.local/ui-fidelity/Hero/compare/g5-live-20260726/`。
4. Unity 阵容入口已补 `/319 op=1/17` 装备/法宝预取；全解锁账号下强化大师真实打开，16项 Button 自动化通过。
5. 人工视觉验收结果为 `16/16 passed`；14项原硬缺陷全部修复，详见 `manual-acceptance.md/json`。
6. 最终 Runner 时间 `2026-07-26T14:31:28.6502368Z`，结果 success；本轮 Unity 原图16/16均刷新为原生 `1334×750`。
7. 当前模块已收口，不继续扩展；新任务从 `UNITYCLIENT_STATUS.md` 选择下一模块。

### 必读与状态

按顺序读取：

1. `UNITYCLIENT_STATUS.md`
2. `docs/unityclient/MIGRATION_GUIDE.md`
3. `docs/unityclient/modules/README.md`
4. `docs/unityclient/modules/HERO.md`
5. `docs/unityclient/matrices/HERO_CONTROLS.json`
6. `tools/unity-migration/migration-gates.json`

启动前必须先执行 `git status --short`。工作区仍有阵容 G3/G4、服务端测试、xLua `.meta` 删除和 `.vscode` 等未提交改动；不得 reset、checkout、覆盖或自动暂存。

### 长期配置与最近提交

- `.codex/config.toml` 的 `unityMCP.enabled = true` 是用户要求的长期设置，任务结束后不得改回 false。
- Unity GameView 固定为 `1334×750`，不要通过修改启动分辨率抢占桌面。
- 后台自动化机制已提交并推送远端 `main`：`da513368eec785d8a814ef8544d2845964e087b0`。
- 该提交只包含：
  - `docs/unityclient/MIGRATION_GUIDE.md`
  - `tools/local/Invoke-ClientWindow.ps1`
  - `tools/local/Start-Client.ps1`
  - `unityclient/Assets/ProjectX/src/Editor/BootstrapAppRunner.cs` 的分辨率代码块
- `BootstrapAppRunner.cs` 当前仍有未提交的阵容 G4 重连代码，属于有效工作，不得因文件已部分提交而覆盖。

### 当前运行与验证

- 阶段收口后关闭 Unity、ProjectX、`kapai.exe`；既有 workspace-local MySQL 保持不动。
- Unity迁移文档检查：29模块通过。
- `tools/ui_migration/tests/test_ui_migration.py`：16/16通过。
- 未经用户再次明确要求，不提交或推送剩余工作树。

> 更新时间：2026-07-16
> 工作区：`E:\neiwang_kapai\Game`
> 项目：Cocos2d-x 2.17 + Lua 客户端、C++ 服务端的联网卡牌游戏

## 1. 当前任务

目标是在缺少独立登录服和完整生产库的情况下，把 Windows 本地测试环境修到可稳定运行、可直连登录、可验证主要协议和 UI 功能入口的状态。

当前采用最小改动方案：

- 客户端通过 `AppDef.LOCAL_TEST = true` 直连 `127.0.0.1:8711`。
- 服务端通过 `server/config/config` 的 `local_test=1` 跳过登录服依赖。
- 保留线上逻辑，只增加本地测试开关、最小兼容层、最小数据库兜底和可重复烟测。
- 用分组协议 smoke 验证消费、战斗、NPC、UI 查询等入口，不把协议 smoke 冒充完整人工 UI 验收。

本会话结束时正在按用户要求执行“**一个功能一个功能过**”的客户端 L6 验收：

1. 体力显示 `0/100`、体力丹提示已满的根因已经修复，体力查询和 `100/100` 显示已验证；实际消耗 1 个体力丹变为 `125/100` 仍待人工确认。
2. 随后人工副本流程触发 `FuBenDetailUI.lua` 的战后移动报错；代码已修复、Lua 语法已验证，但用户尚未重新打同一副本完成人工复验。
3. 下一会话先收口这个副本移动功能，不要直接恢复大范围乱点 UI。

## 2. 用户的强制执行规则

这是后续会话必须遵守的规则：

- 编译未完成时，每隔 **30 秒**检查一次并向用户汇报状态。
- 不要因为超过 30 秒自动杀编译进程；持续按 30 秒轮询，除非用户要求杀掉或跳过。
- 其他环境或命令若卡住 30 秒，立即告诉用户，并确认是继续等待、跳过、杀进程还是采取其他操作。
- 不要静默长时间等待。
- 用户已明确跳过一次预计超过 30 秒的“大组合 smoke”；后续优先使用独立分组命令，每组控制在 30 秒内。
- 客户端截图必须基于 `ProjectX` 所属的 `Cocos Simulator` 游戏窗口句柄：进程同时存在游戏窗和调试控制台，不能盲信会漂移的 `MainWindowHandle`。后台截图使用 `PrintWindow(hwnd, flags=0)`，禁止截整张桌面。
- 后台 `PostMessage`、前台 `SendMessage` 和鼠标注入均已出现“不触发 Cocos 控件”的情况，不能把自动点击当可靠验收。用户已明确允许启动弹窗抢焦点和前台操作；必要时请用户手动点击，Codex 只负责按窗口句柄截图、读日志和修复。
- 每次 Git 提交必须包含详细正文：修改模块/文件、根因、修复内容、SQL/配置变化、验证结果、限制与外部依赖；禁止只写一句标题。只有用户明确授权后才提交或推送。

## 3. 当前运行状态（2026-07-16 交接时快照）

- 服务端正在运行并监听 `8711`，2026-07-16 体力修复重编后的 PID：`22748`。
- 工作区本地 MySQL 8.4 正在运行，进程 PID：`3856`、`7872`。
- 客户端 `ProjectX.exe` **当前未运行**；上一轮已同步最新 Lua 后成功启动并截图验证，随后被用户/会话关闭。下一会话用 `tools/local/Start-Client.ps1` 重启即可。
- `server/config/config`：`local_test=1`、`local_user_id=0`。
- 最新服务端二进制：`build/server-win/Debug/kapai.exe`。
- 本轮连续调试成果提交为 `ee23220 fix: stabilize local test server and client flows`。
- 跨电脑可迁移性修复提交为 `d88cf0b fix: make fresh local server setup reproducible`。
- 提交规范与交接同步提交为 `3a57ca0 docs: synchronize handoff and commit requirements`，包含详细提交正文。
- 上述提交均已推送；`3a57ca0` 推送后本地 `HEAD`、`origin/main`、远端 `main` 已核验一致。
- 当前有窗口句柄工具、体力配置解析、副本移动 Lua 和本交接文档修改尚未提交；实际状态以 `git status --short --branch` 为准。
- 不要 reset、checkout 或覆盖后续会话中出现的用户改动。

运行状态会漂移，接手后先执行：

```powershell
Get-NetTCPConnection -LocalPort 8711 -State Listen
Get-Process kapai,mysqld,ProjectX -ErrorAction SilentlyContinue
& 'C:\Program Files\Git\cmd\git.exe' status --short
```

## 4. 已完成内容

### 4.1 Windows 本地服基础链路

- Windows/MSVC 已能生成 `build/server-win/Debug/kapai.exe`。
- 服务端能以 `server/config` 为工作目录启动并监听 `8711`。
- 本地 MySQL、最小 schema、登录/进服/创角、一次性测试角色链路已建立。
- 本地角色默认 60 级并补测试货币，可穿过部分等级和消费门槛。
- 登录服、长连接服、匹配服缺失时通过 `local_test` 最小降级，不删除线上路径。
- 本地角色进服时若没有场景，会绑定有效场景，避免后续 NPC/战斗入口因 `GetScene()==NULL` 无响应。

### 4.2 配置补齐与校验

已补或修复的服务端配置包括：

- `server/config/json/config.json`
- `function.json`
- `guild_reward.json`
- `mission_dialog.json`
- `revert.json`
- `xiulian.json`
- 新增 `LoginReward.json`
- 新增 `jijin.json`
- 新增 `jingjie_config.json`
- `server/config/xml/mission_config.xml`
- `server/config/xml/mission_dialog.xml`

`config.json` 已从客户端同版本配置补入 17～23 项，但保留服务端原有第 16 项差异，不要无脑用客户端文件整份覆盖。

最后一次解析结果：9 个 JSON、2 个 XML 全部通过。

配置来源和映射另见 `FEATURE_CONFIG_SOURCES.md`。

### 4.3 Lua 和本地数据兼容

- `server/src/lua_j_stub.cpp` 已按真实 `call:` 错误补最小 `j.*`、`CUser:*` 和旧式 `bit._*` 绑定。
- `server/script/global.lua`、任务格式、题库、公告、帮助等本地缺失链路已做最小修复或降级。
- `server/script/75.lua` 是缺失可选弹窗脚本的本地占位。
- 不要恢复或臆造整套私有 SWIG 输出；以后仍按具体日志最小补绑定。

### 4.4 消费入口修复

- 增加独立 `-Consumption` smoke。
- 覆盖协议：47、84、177、200、216、257、309、310、332。
- 角色改名、帮派改名改为先校验名称、帮派、权限、数据库，再扣费。
- 数据库更新失败时会退回材料。
- 已验证有效角色改名精确扣除 500 测试货币；无效名称不会先扣费。
- 背包扩展当前角色已初始化到最大容量，因此只能验证“已达上限”分支，不能宣称完成真实背包扩容扣费。

### 4.5 竞技场栈溢出修复

原问题：竞技场挑战进入 `new CFight` 后发生 Windows `0xc00000fd` 栈溢出，客户端只能收到竞技场列表，服务端随后崩溃或工作线程卡死。

最终根因在 `server/src/boost/any.hpp`：

```cpp
std::any::operator=(other);
```

`other` 是派生类 `boost::any`，重载解析会走 `std::any` 的模板赋值，把派生对象再次装进自身，形成无限递归。现已修为显式基类赋值：

```cpp
std::any::operator=(static_cast<const std::any &>(other));
std::any::operator=(static_cast<std::any &&>(other));
```

验证结果：

- `CFight` 18 个成员均可清理。
- 竞技场动态机器人挑战完成。
- 收到战斗回放、结算和竞技场响应。
- 观战入口有有效响应。
- 服务端保持监听，无 stack overflow、assert、crash。
- 临时 `CFight/CreateFight/ArenaOption/BeginFastFight` 定位日志已清理。

### 4.6 其他代码修复

- `server/src/scene_manager.cpp` 的怪物坐标检查已修正：只有中心不可走或周围无任何可走邻居才报警。此前只要八邻域有一个阻挡就报错，属于假阳性。
- `tools/local/Build-Server.ps1` 支持 `-BuildDir` 和可选 `-SkipAppLocal`；默认构建会显式部署 Boost、LuaJIT、Zlib、MySQL/OpenSSL 运行 DLL，保证干净输出目录可直接启动。
- 本地地图查询先兼容旧路径 `dat/<id>.map`，再回退当前仓库实际命名 `dat/map<id>.map`。
- Windows socket 零 payload、UTF-16LE、body length、每 socket 多消息发送队列等兼容修复已保留。

### 4.7 协议覆盖与分组 smoke

当前 `PROTOCOL_COVERAGE.md`：

| 项目 | 数量 |
|---|---:|
| 服务端注册协议 | 143 |
| smoke 已覆盖 | 128 |
| 未覆盖 | 15 |

新增分组：

```powershell
pwsh -ExecutionPolicy Bypass -File tools/local/Invoke-ProtocolSmoke.ps1 -Consumption
pwsh -ExecutionPolicy Bypass -File tools/local/Invoke-ProtocolSmoke.ps1 -Battle
pwsh -ExecutionPolicy Bypass -File tools/local/Invoke-ProtocolSmoke.ps1 -UiQueries
```

最后实测耗时：

- `-Battle`：约 15.4 秒，成功。
- `-Consumption`：约 18 秒，成功。
- `-UiQueries`：约 16.6 秒，成功。

`-UiQueries` 已覆盖充值面板、封神列表、技能描述、物品定义、活动、NPC 引导、挂机、修仙历练、角色详情、闯关次数、临时活动、仙缘以及多个明确 no-op 入口。

### 4.8 最终验证证据

- 全量编译成功，耗时 154.5 秒；按 30 秒节点持续汇报。
- JSON/XML 全部解析通过。
- `git diff --check` 通过。
- 服务端保持监听。
- `.local/kapai-current.out/.err` 未发现 fatal、assert、stack overflow、crash、Lua `call:` error。
- `PROTOCOL_COVERAGE.md` 已重新生成，统计为 128/143。

### 4.9 客户端 nil、空数据与崩溃修复

本轮人工点击继续发现并处理了以下问题：

1. **普通商店 `configData=nil`**
   - 报错入口：`View/Shop/NormalShop.lua:56`。
   - 已从同版本客户端数据补齐 `server/config/json/shop.json`、`shop_config.json`。
   - `server/src/user_shop_manage.cpp` 增加旧存档兼容，避免本地测试角色的商店数据与新配置错位。
2. **欢乐抽奖回调 `data=nil`**
   - 报错入口：`View/HappyDraw/HappyDrawUI.lua:469/487`。
   - 修复抽卡配置与旧存档迁移，相关代码在 `server/src/chou_ka_manager.cpp`。
3. **副本红点 `data=nil`**
   - 报错入口：`View/ImproveUI/LRedDotCheckMgr.lua:2224`。
   - 本地测试路径对不完整红点数据返回隐藏状态，避免客户端解空数据。
4. **七日活动打开 `AppDef.FuncUI[0] not exist`**
   - 修复 `client/ProjectX/src/View/OperationalActivity/SevenDay.lua`，无效功能 ID 不再调用 `OpenFunction(0)`。
5. **购买体力丹提示 `获得(nil)*5`**
   - 根因不是 UI，而是本地 `item` 表缺少模板，服务端下发的物品名为空。
   - `server/src/utility.cpp` 在 `local_test=1` 时只从 `server/config/json/item.json` 补数据库缺失模板，不覆盖已有正式数据。
   - 启动日志曾验证：`[local] ReadItem: filled 287 missing templates from item.json`。
6. **封神试炼点击挑战后客户端原生闪退**
   - Windows 事件显示 `ProjectX.exe` 在 `VCRUNTIME140D.dll` 以 `0xc0000005` 崩溃。
   - 根因在 `server/src/gyu/g_net_msg.cpp::add_NetMsg`：嵌套战斗回放前多写了一层长度，客户端把长度当消息包解析并越界。
   - 现直接追加已经成帧的 `[bodyLen][type][body]`，不再额外包长度。
   - `-Battle` 已动态挑战封神试炼并验证嵌套回放，曾得到 `fengshen_trial_id=3001`、`fengshen_replay_packets=5`。
7. **首充界面五个奖励槽全空**
   - 根因：本地最小库 `hd_peizhi_info`、`huodong_award` 是空表；服务端返回错误包，客户端仍按奖励结构读取。
   - `server/src/main.cpp` 与 `server/sql/local_min_schema.sql` 已在 `local_test=1` 下按“仅缺失时”补首充类型 29 的配置和五项奖励。
   - 当前本地兜底为：姜子牙（神将 19）、高级招募券、特级神将内丹、金币、绑元；这是本地联调用数据，不应当作正式商业化配置。

### 4.10 额外协议与数据回归

- `server/src/user_guanqia.cpp` 已补齐封神试炼缺失条目，列表由异常空/不完整恢复到 4 条。
- `server/sql/local_min_schema.sql`、`server/src/main.cpp` 已补 `fight_playback` 缺列兼容。
- `server/src/pack_deal.cpp` 修复调试协议 13 中 `ADDItem` 名称碰撞导致的栈溢出，并加入 smoke 回归。
- `tools/local/Start-Client.ps1` 支持可选客户端输出日志。
- 最新一次重新编译后 `kapai.exe` 时间为 2026-07-15 17:29:48；服务端重启成功。
- 最新 `-UiQueries`：`recv_count=51`，封神试炼 `fengshen_trial_count=4`，执行成功。

### 4.11 全新克隆与空数据库验证

- 已确认另一台电脑此前缺修复的直接原因是 `ee23220` 当时尚未推送；现已连同 `d88cf0b` 一并推送到 `origin/main`。
- `server/sql/local_min_schema.sql` 已改为从当前可运行本地库导出的 173 张表纯结构快照，不包含账号、角色或业务流水数据。
- 新增三组本地启动必需种子：首充 UI 两表、交易行基准汇率、功能开关默认行。
- 新增 `tools/local/Export-LocalSchema.ps1`，用于结构无数据导出；新增 `Test-FreshLocalSetup.ps1`，用于隔离数据库、临时端口和登录/创角 smoke。
- 独立数据库 `fxl_game_clonecheck_20260716102635` 已从仓库 schema 与全部 4 个数据文件初始化成功；干净构建 EXE 在 `18713` 启动，创建角色 `1000001`，收到 59 个回包后正常停止。
- 完整编译成功，新 `kapai.exe` 时间为 2026-07-16 09:35:26；随后在 `.local/server-win-clean` 完成独立干净构建。
- 主服恢复后 `-Consumption`、`-Battle`、`-UiQueries` 分别通过；15 个 PowerShell、62 个 JSON、76 个 XML 解析通过，主服日志扫描无 SQL/Lua/assert/crash。
- 依赖脚本现固定 vcpkg 到 `a7bd30319eeac16afbe18d64a855303a0a425e84`，自动安装 Boost、LuaJIT、Zlib；构建脚本会自动识别 vcpkg LuaJIT。
- 构建脚本现会把运行 DLL 自动部署到 EXE 同目录；干净 EXE 使用独立数据库 `fxl_game_clonecheck_20260716102149` 和端口 `18712` 通过登录/创角 smoke，收到 59 个回包。
- 当前 `fxl_game_local` 重新导出的 173 表结构与待提交 `server/sql/local_min_schema.sql` SHA-256 完全一致，未发现后来修过但遗漏导出的字段。
- 客户端的 3.3G Cocos2d-x 2.17 内部引擎快照仍未入库，完整客户端编译仍需团队内部源提供，这是当前明确的外部依赖边界。

## 5. 当前卡点和明确边界

### 5.1 唯一剩余客户端协议：211

`MSG_PLAY_ANIMATION/211`：

- 当前客户端源码中未找到该协议的发送入口。
- 服务端 `AnimationOption` 会调用 `script/10000.lua` 的 `CgCallBack`。
- 当前仓库脚本没有 `CgCallBack` 定义。
- 客户端 `LuaNetCmd.lua` 在 210 后直接进入 212，没有定义 211；`LuaNetRecvdMsg.lua` 没有 211 接收注册，完整 `frameworks/` 引擎快照也未找到 211/CgCallBack 处理器。
- 服务端 211 同时承担 `SendCgInfo()` 下发 CG 描述与客户端回传动画 ID；`global.lua::GetCgInfo()` 定义了 CG 描述格式，但当前仓库没有调用点。
- `10000.lua::Logon()` 调用的是数据库战斗回放 `j.PlayFightCG()`，不是协议 211，因此不能把登录首战当作 211 的真实触发证据。
- 不要直接补一个空函数来刷覆盖率，这会掩盖未知线上语义。
- 只有拿到原始脚本/旧版本客户端调用证据，或人工复现真实动画回调流程后，才应实现。

### 5.2 14 个服务端内部/跨服协议

剩余 14 个均是服务端内部、长连接服或跨服协议：62、92、128、334、401、402、601、10001、10002、10005、10006、10009、10022、65534。

当前本地没有对应长连接服、跨服服或真实触发入口。不要为了达到 100% 数字伪造客户端包或大面积旁路。

### 5.3 仍未完成的验收等级

- 尚未完成客户端人工点击所有主要 UI 的 L6 验收。
- 客户端当前未运行；重启后可继续连接 `127.0.0.1:8711`。后台句柄截图已验证可用，但 Win32 注入点击不可靠，L6 需要用户实际点击配合。
- 2026-07-16 已完成 429 秒 L5 长跑：14 次 30 秒检查中服务端、客户端、8711 监听和进程响应均正常；新增服务端日志 100 行，未命中 SQL/Lua/assert/crash/config-error。
- L5 后的三个独立回归均通过：`-Consumption` 18.1 秒、`-Battle` 14.9 秒（`fengshen_replay_packets=3`）、`-UiQueries` 16.9 秒（`recv_count=51`、`fengshen_trial_count=4`）。
- `PRO_GONGGAO/88` 当前返回零条配置，客户端显示空白“游戏公告”页；用户已确认这是未配置公告时的正常表现，不应为此修改公告业务逻辑。
- 不要让默认 userId/roleId 的 smoke 与 L6 客户端并发：smoke 会接管同一角色会话，导致客户端弹出“无法连接服务器”。需要并发时使用一次性 userId；否则 smoke 后重启客户端。
- 用户已跳过一次大组合 smoke；不要擅自重新跑长组合。
- 协议 smoke 只证明服务端入口有响应或安全返回，不代表 UI 显示、动画、交互、真实奖励、真实付费全部正确。

### 5.4 体力显示/体力丹不一致已修复

- 现象：主界面显示 `0/100`，使用体力丹却提示体力已满。
- 根因：`server/config/json/config.json` 的 `stamina` 使用 `array` 类型逗号值 `100,500,360`，`CParaMgr::ReadSpirit()` 却只接受 JSON 数组，导致 `FULL_SPIRIT/MAX_SPIRIT/FREE_SPIRIT` 全部保留为 0。
- 修复：`ReadSpirit()` 同时兼容 JSON 数组和三段逗号值并校验参数；`CUserSpirit` 构造时初始化 `m_lastSpiritTime=0`；客户端把 321 体力查询从延迟红点批处理提前到主界面基础数据初始化。
- 验证：修复前一次性角色的 321 响应体力为 0；重编重启后新角色及当前角色均响应 100，窗口句柄截图确认主界面显示 `100/100`。`Invoke-ProtocolSmoke.ps1` 会输出 `response_321` 作为后续证据。
- 体力配置语义：自然恢复上限 100、道具允许堆叠上限 500、恢复间隔 360 秒；因此 100 点时使用 25 点体力丹应允许增长到 125，而不是提示已满。

### 5.5 副本战后移动 Lua 错误已修复，待人工复现确认

- 错误：`FuBenDetailUI.lua:746 attempt to concatenate local 'targetPos' (a table value)`。
- 根因：调试打印把 `cc.p()` 返回的 table 直接与字符串拼接；紧邻的动作序列还引用了从未定义的 `dealy`。
- 修复：删除错误调试打印，并把动作序列改为 `moveAc, moveEnd`。三个相关 Lua 文件已通过 LuaJIT 字节码语法检查，客户端曾重启并加载成功。
- **当前唯一直接卡点**：还没有人工完成一次同副本战斗，无法证明战后角色移动、站立动作和镜头滚动全部正常。下一会话先让用户复现这一条；若仍报错，立即保存完整 Lua 堆栈并只修该功能。

### 5.6 首充客户端目视复验已完成

- 2026-07-16 已通过游戏窗口句柄截图确认五项奖励全部显示：姜子牙、高级招募券 10、特级神将内丹 10、金币 100000、绑元 500。
- 点击“立即充值”后，再从主界面充值入口复验，充值档位页面正常打开并显示 6/25/128/30/50/98/198/328 等档位及首充双倍标识。
- 未点击任何具体充值档位，也未触发或伪造真实支付。

## 6. 建议下一步计划

按以下顺序继续：

1. **先复验副本战后移动（当前第一优先级）**：
   - 确认 8711 仍由当前 `kapai.exe` 监听；执行 `tools/local/Start-Client.ps1`，启动抢焦点已获用户允许。
   - 请用户重新进入刚才的副本并完成一场战斗，观察角色从旧节点移动到新节点、切回站立动作、镜头滚动是否正常。
   - 同时观察客户端控制台和 `.local/kapai-current.out/.err`；出现错误时保留完整堆栈，不要跳去测试别的功能。
2. **再复验体力丹完整正向分支**：
   - 历史截图已证明主界面能正确显示服务端值；2026-07-16 提交前基础 smoke 的最新 321 响应为 `01015c00fb5b586a`，其中体力为 `0x005c=92`。角色状态会变化，测试前必须重新查询，不能写死为 100。
   - 用户手动使用 1 个体力丹；预期体力在使用前数值基础上增加 25、道具数量减 1，不再错误提示体力已满。该消耗动作尚未做最终人工验证，执行前让用户知情。
3. **继续逐功能 L6**：
   - 一次只验一个入口，建议顺序：副本 → 背包 → 封神 → 活动 → 挂机 → 历练 → 仙缘 → 竞技场 → 充值。
   - 每个功能都记录：进入是否成功、关键操作、截图、客户端/服务端错误；发现问题先修复并复验，再进入下一个。
   - 截图只用窗口句柄 `PrintWindow`；交互以用户手动前台操作为准，不要因注入脚本返回成功就判定 UI 通过。
4. **最后收口当前未提交改动**：
   - 逐文件审查当前脏工作树，区分用户修改和新会话修改。
   - 至少跑 `git diff --check`、三个修改 Lua 的语法检查、服务端增量构建和基础 smoke；321 响应应满足 op=1、success=1，并正确携带服务端当前体力，不能要求动态体力恒为 100。
   - 体力或网络/保存线程若继续修改，再补跑 429 秒标准 L5；否则不必无理由重跑已通过的长跑。
   - 只有用户明确要求时才 stage/commit/push；提交正文必须完整记录修改、根因、验证和限制。
5. **协议边界保持不变**：211 及 14 个内部/跨服协议继续作为证据性未覆盖；没有真实调用证据时不要补空回调或伪造覆盖。

## 7. 常用命令

### 构建

```powershell
pwsh -ExecutionPolicy Bypass -File tools/local/Build-Server.ps1
```

头文件改动会触发约 2～3 分钟全量编译。必须每 30 秒检查并汇报。

### 启动服务端

```powershell
pwsh -ExecutionPolicy Bypass -File tools/local/Start-Server.ps1 -WaitSeconds 25
```

若调用工具超时或脚本无输出，不要立刻判定失败，先查：

```powershell
Get-NetTCPConnection -LocalPort 8711 -State Listen
Get-Content .local/kapai-current.out -Tail 80 -Encoding UTF8
Get-Content .local/kapai-current.err -Tail 80 -Encoding UTF8
```

### 分组 smoke

```powershell
pwsh -ExecutionPolicy Bypass -File tools/local/Invoke-ProtocolSmoke.ps1 -Consumption
pwsh -ExecutionPolicy Bypass -File tools/local/Invoke-ProtocolSmoke.ps1 -Battle
pwsh -ExecutionPolicy Bypass -File tools/local/Invoke-ProtocolSmoke.ps1 -UiQueries
```

### 刷新覆盖矩阵

```powershell
pwsh -ExecutionPolicy Bypass -File tools/local/Export-ProtocolCoverage.ps1
```

### Git 状态

```powershell
& 'C:\Program Files\Git\cmd\git.exe' status --short
& 'C:\Program Files\Git\cmd\git.exe' diff --check
```

## 8. 绝对不要再踩的坑

1. **不要静默等编译**：编译每 30 秒检查并汇报；其他卡顿 30 秒立即询问用户。
2. **不要把超时等同于失败**：`Start-Server.ps1` 曾在工具层约 19 秒超时，但 `kapai.exe` 已成功监听。永远先查端口和 PID。
3. **不要直接用带空格 SQL 的 `mysql.exe -e`**：PowerShell 参数解析曾让 mysql 进入交互模式，看起来像数据库卡死。使用无空格 SQL，例如：
   ```powershell
   mysql.exe ... -e 'select/**/id/**/from/**/item/**/limit/**/1;'
   ```
   或用 `Start-Process` 配合重定向。
4. **不要再怀疑数据库健康度而反复重启**：此前所谓 MySQL 卡死实际是命令行参数问题，数据库本身健康。
5. **不要恢复错误的 `boost::any` 赋值**：派生 `boost::any` 必须显式转成 `std::any` 基类后赋值，否则竞技场创建战斗对象会无限递归并栈溢出。
6. **不要用单 pending 消息替换 socket 发送队列**：快速初始化多回包会丢包或在 MSVC Debug 下崩溃。
7. **不要把零 payload 包当断包**：旧 Cocos 客户端的无 body 命令包是合法协议。
8. **不要把怪物周围任一阻挡格当坐标错误**：只需中心可走且至少存在一个可走邻居。
9. **不要用客户端配置整份覆盖服务端配置**：例如 `config.json` 第 16 项服务端与客户端值不同，应保留服务端语义，只补缺失行。
10. **不要先扣费后校验**：改名、帮派改名等必须先校验名称、权限、DB，再扣费；DB 失败要退款。
11. **不要为刷覆盖率伪造 211 的 `CgCallBack`**：缺少真实语义和客户端入口。
12. **不要声称 128/143 等于全功能完成**：剩余内部协议、动画回调和人工 UI 都有明确边界。
13. **不要广搜整个 C 盘找 procdump**：曾经做过一次广泛递归搜索，10 秒后终止，噪声大且无收益。
14. **不要执行 `git reset --hard`、`git checkout --` 或批量覆盖**：当前大量修改属于连续调试成果，且可能混有用户已有改动。
15. **不要默认使用旧 Windows PowerShell**：优先 `pwsh.exe` 和 UTF-8；中文文件显式 `-Encoding UTF8`。
16. **不要把历史长结果继续堆进项目总规**：当前操作说明写 `LOCAL_RUN.md`，历史证据应写 `LOCAL_HISTORY.md`。
17. **不要给已经成帧的嵌套 `CNetMessage` 再加一层长度**：客户端 `ReadNetMsg()` 直接期待 `[bodyLen][type][body]`；多包一层会在战斗回放处造成客户端原生崩溃。
18. **不要把物品名 `(nil)` 当纯客户端文案问题**：先检查服务端 `item` 模板是否存在，以及协议里下发的 item ID/名称；本次体力丹就是本地数据库缺模板。
19. **不要让客户端把服务端错误包当成功结构解析**：首充 op=9/op1=2 没有独立成功字节；缺配置时返回错误字符串会被 UI 当奖励数组。首先保证本地配置存在，或同步修改协议两端。
20. **不要把本地首充兜底奖励当正式数值**：正式奖励必须恢复生产 `hd_peizhi_info`、`huodong_award` 数据源；当前五项只用于本地 UI/协议联调。
21. **不要在服务端运行时直接链接覆盖同一个 `kapai.exe`**：重编正式输出目录前先停对应服务端，完成后重启并查 8711；编译到独立 `-BuildDir` 时无需关闭正式服。
22. **不要用普通 `mysql.exe -e` 命令判断 SQL 已执行**：本会话即使使用注释替代空格仍出现命令挂起。优先用 `Start-Process` 参数数组和重定向，或直接以启动日志/协议响应验证。
23. **不要把 `config.json` 的 `array` 当成 JSON 数组**：当前 `stamina` 是 `100,500,360` 逗号值；旧解析器因此把体力三个参数留为 0。解析时必须兼容字段实际格式并校验正数/上下限关系。
24. **不要只修报错行就停止检查紧邻路径**：`targetPos` 拼接报错下一行之后还有未定义的 `dealy`；这类确定性连续错误应在同一功能内一起排除，但不要借机大范围重构。
25. **不要把客户端默认值当服务端真实状态**：体力显示曾默认 0；必须用 321 响应或服务端状态证明。基础资源查询应独立于可能中断的红点批处理。
26. **不要声称体力丹正向使用已通过**：目前已证明服务端/客户端体力同步正常，尚未人工消耗 1 个体力丹证明体力增加 25 并扣除道具。

## 9. 已提交成果与当前改动

核心本轮改动：

- `server/src/boost/any.hpp`：修复递归赋值和竞技场栈溢出。
- `server/src/pack_deal.cpp`：本地登录/场景、消费校验退款、地图路径等。
- `server/src/scene_manager.cpp`：怪物坐标误报修复。
- `server/config/json/config.json`：补齐缺失运行参数。
- `tools/local/Build-Server.ps1`：新增 `-BuildDir`、依赖自动发现和运行 DLL 部署；保留诊断用 `-SkipAppLocal`。
- `tools/local/Invoke-ProtocolSmoke.ps1`：新增 `-Consumption`、`-Battle`、`-BattleListOnly`、`-UiQueries`。
- `tools/local/Export-ProtocolCoverage.ps1`、`PROTOCOL_COVERAGE.md`：覆盖统计。
- `LOCAL_RUN.md`：当前运行和分组验证说明。

- 上述连续修复已统一提交到 `ee23220`。
- 该提交共涉及 40 个文件，包含本地配置恢复、数据库 bootstrap、Lua/C++ 兼容、战斗回放修复和 smoke 工具。
- `ee23220`、`d88cf0b` 与文档规则提交 `3a57ca0` 已全部推送到 `origin/main`；`3a57ca0` 推送后远端与本地已核验一致。
- `d88cf0b` 包含完整本地结构 schema、依赖/构建/建库改进、隔离验证脚本、窗口句柄操作工具与文档更新。
- `3a57ca0` 只提交并推送了当时的 `AGENTS.md`、`HANDOFF.md` 规则同步；此后产生的体力、副本移动、窗口工具和新交接更新仍在工作树中，**尚未提交、尚未推送**。
- 当前未提交文件共 9 个：`AGENTS.md`、`HANDOFF.md`、`client/ProjectX/src/View/FuBenMap/FuBenDetailUI.lua`、`client/ProjectX/src/View/ImproveUI/LRedDotCheckMgr.lua`、`client/ProjectX/src/View/MainUI.lua`、`server/src/config_para.cpp`、`server/src/user_spirit.cpp`、`tools/local/Invoke-ClientWindow.ps1`、`tools/local/Invoke-ProtocolSmoke.ps1`。
- 当前未提交改动的核心内容：正确枚举游戏窗口句柄和后台截图；体力配置兼容/计时初始化/主界面提前查询/321 smoke 证据；副本战后移动的 table 拼接与未定义动作修复；交接规则同步。
- 在提交前先检查 `git diff --check` 和 `git status --short`；只有用户明确要求后才 stage、commit、push，且提交必须有详细正文。
- 不需要重做 `ee23220` 已完成的修复，也不要为了“清理”而回退该提交。
