# 本地卡牌项目调试交接

> 更新时间：2026-07-15
> 工作区：`E:\neiwang_kapai\Game`
> 项目：Cocos2d-x 2.17 + Lua 客户端、C++ 服务端的联网卡牌游戏

## 1. 当前任务

目标是在缺少独立登录服和完整生产库的情况下，把 Windows 本地测试环境修到可稳定运行、可直连登录、可验证主要协议和 UI 功能入口的状态。

当前采用最小改动方案：

- 客户端通过 `AppDef.LOCAL_TEST = true` 直连 `127.0.0.1:8711`。
- 服务端通过 `server/config/config` 的 `local_test=1` 跳过登录服依赖。
- 保留线上逻辑，只增加本地测试开关、最小兼容层、最小数据库兜底和可重复烟测。
- 用分组协议 smoke 验证消费、战斗、NPC、UI 查询等入口，不把协议 smoke 冒充完整人工 UI 验收。

## 2. 用户的强制执行规则

这是后续会话必须遵守的规则：

- 编译未完成时，每隔 **30 秒**检查一次并向用户汇报状态。
- 不要因为超过 30 秒自动杀编译进程；持续按 30 秒轮询，除非用户要求杀掉或跳过。
- 其他环境或命令若卡住 30 秒，立即告诉用户，并确认是继续等待、跳过、杀进程还是采取其他操作。
- 不要静默长时间等待。
- 用户已明确跳过一次预计超过 30 秒的“大组合 smoke”；后续优先使用独立分组命令，每组控制在 30 秒内。

## 3. 当前运行状态（2026-07-15 交接时快照）

- 服务端正在运行并监听 `8711`，PID：`25200`。
- 工作区本地 MySQL 8.4 正在运行，进程 PID：`3856`、`7872`。
- 客户端 `ProjectX.exe` 当前未运行。
- `server/config/config`：`local_test=1`、`local_user_id=0`。
- 最新服务端二进制：`build/server-win/Debug/kapai.exe`。
- 工作树很脏，包含本轮和此前未提交修改；**不要 reset、checkout 或覆盖用户改动**。
- 尚未 commit，也未要求 commit。

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
- `tools/local/Build-Server.ps1` 新增可选 `-SkipAppLocal`，通过 `-DVCPKG_APPLOCAL_DEPS=OFF` 避免已有 `zd.dll` 被 vcpkg applocal 锁住导致构建失败；默认行为未改变。
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

## 5. 当前卡点和明确边界

### 5.1 唯一剩余客户端协议：211

`MSG_PLAY_ANIMATION/211`：

- 当前客户端源码中未找到该协议的发送入口。
- 服务端 `AnimationOption` 会调用 `script/10000.lua` 的 `CgCallBack`。
- 当前仓库脚本没有 `CgCallBack` 定义。
- 不要直接补一个空函数来刷覆盖率，这会掩盖未知线上语义。
- 只有拿到原始脚本/旧版本客户端调用证据，或人工复现真实动画回调流程后，才应实现。

### 5.2 14 个服务端内部/跨服协议

剩余 14 个均是服务端内部、长连接服或跨服协议：62、92、128、334、401、402、601、10001、10002、10005、10006、10009、10022、65534。

当前本地没有对应长连接服、跨服服或真实触发入口。不要为了达到 100% 数字伪造客户端包或大面积旁路。

### 5.3 仍未完成的验收等级

- 尚未完成客户端人工点击所有主要 UI 的 L6 验收。
- 客户端当前未运行。
- 没有在本轮修复后重新执行 7 分钟以上 L5 长跑。
- 用户已跳过一次大组合 smoke；不要擅自重新跑长组合。
- 协议 smoke 只证明服务端入口有响应或安全返回，不代表 UI 显示、动画、交互、真实奖励、真实付费全部正确。

## 6. 建议下一步计划

按以下顺序继续：

1. **先确认范围**：询问用户是要收口提交，还是继续做客户端人工 UI/L5 长跑。
2. **若做人工 UI**：
   - 用 `tools/local/Start-Client.ps1` 启动客户端。
   - 验证进入主流程后逐页点击充值、封神、背包、活动、挂机、历练、仙缘、竞技场。
   - 同时观察客户端日志和 `.local/kapai-current.out/.err`。
   - 发现新的 SQL/Lua/assert/crash，按具体日志最小修复。
3. **若做 L5 长跑**：保持服务端和客户端运行，至少跨过保存线程和定时器周期；每 30 秒向用户汇报，不静默等待。
4. **若要收口代码**：
   - 逐文件审查当前脏工作树，区分此前修改和本轮修改。
   - `server/src/fight.h` 当前只有文件尾少一个空行的无功能差异，可在收口时清掉。
   - 再跑 `git diff --check`、JSON/XML 解析和三个独立 smoke。
   - 只有用户明确要求时才 stage/commit。
5. **协议 211**：除非找到真实客户端发送路径或原始 `CgCallBack`，保持未覆盖并写明原因。

## 7. 常用命令

### 构建

```powershell
pwsh -ExecutionPolicy Bypass -File tools/local/Build-Server.ps1 -SkipAppLocal
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

## 9. 当前改动文件概览

核心本轮改动：

- `server/src/boost/any.hpp`：修复递归赋值和竞技场栈溢出。
- `server/src/pack_deal.cpp`：本地登录/场景、消费校验退款、地图路径等。
- `server/src/scene_manager.cpp`：怪物坐标误报修复。
- `server/config/json/config.json`：补齐缺失运行参数。
- `tools/local/Build-Server.ps1`：新增 `-SkipAppLocal`。
- `tools/local/Invoke-ProtocolSmoke.ps1`：新增 `-Consumption`、`-Battle`、`-BattleListOnly`、`-UiQueries`。
- `tools/local/Export-ProtocolCoverage.ps1`、`PROTOCOL_COVERAGE.md`：覆盖统计。
- `LOCAL_RUN.md`：当前运行和分组验证说明。

工作树中还有此前连续修复产生的配置、Lua、数据库 bootstrap、任务、装备、用户数据等修改。接手后以 `git diff` 为准，不要假设所有改动都来自最后一轮。
