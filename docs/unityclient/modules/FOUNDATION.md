# 底层、登录与主界面

## 范围

- Bootstrap 启动场景、登录、创角、选角、断线/重连、切换账号。
- App 状态、xLua 生命周期、协议注册、请求上下文、错误边界。
- 主界面 HUD、返回栈、设置、资源、服务器时间、Loading、Toast、Reward。

## 主要实现

| 能力 | 入口 |
|---|---|
| App | `Assets/ProjectX/src/Core/ProjectXApp.cs` |
| 服务容器 | `Assets/ProjectX/src/Core/GameServices.cs` |
| 启动参数 | `Assets/ProjectX/src/Core/AppLaunchOptions.cs` |
| 协议 | `Assets/ProjectX/src/Network/ProtocolRegistry.cs` |
| Lua 启动 | `Assets/ProjectX/Resources/Lua/Bootstrap.txt` |
| 场景装配 | `Assets/ProjectX/src/Editor/BootstrapSceneBuilder.cs` |
| 自动化 | `Assets/ProjectX/src/Editor/BootstrapAppRunner.cs` |

## 已验证

- 正式 Bootstrap：登录、选角、主界面、背包入口闭环。
- 自动重连和手动重连；Esc 返回；切换账号回到断开状态登录 UI。
- Player/Currency：`/1004、/18、/226、/321`。
- ServerTime：`/206` 的 `todaySeconds + unixSeconds`。
- 设置音量持久化、Loading、Toast、MessageBox、RewardPresenter。

## 关键坑

- Windows 协议必须保持 UTF-16LE、旧长度语义、合法零载荷包和每 socket send queue。
- 销毁顺序必须避免 UiStack 二次访问已销毁对象。
- Unity 调用可能异步返回，自动化使用 `Start-Process -Wait`。
- 结果文件必须在每次 Runner 前删除并校验时间戳。

## 遗留

- 正式登录服、发布配置、协议回放、完整错误码、AudioService、红点树深化、资源异步与内存预算。

## Steam 单机 SQLite 前置

- 当前门禁：`S0-S4 passed / S5 current / S6-S8 pending`；实时状态只看根目录 `UNITYCLIENT_STATUS.md`，稳定流程只看 `../MIGRATION_GUIDE.md`。
- 当前 MySQL 耦合盘点：`452` 处 `pDb->Query()`、`230` 处 `GetRow()`、`66` 处 `GetRowNum()`；本地 Schema 为 `173` 张表、`170` 处 `AUTO_INCREMENT`。
- 实现策略：保留 `CDatabaseSql` 业务接口，先做 MySQL/SQLite 双后端；SQLite 达成全部 Steam 保留模块的数据与持久化回归后才切正式默认。MySQL 源码、构建和回归能力必须保留到全部模块验收结束且用户再次明确通知删除。
- 最终进程：Unity 客户端 + 静态链接 SQLite 的 `kapai.exe`；不再要求玩家安装或启动 MySQL。
- 最终数据位置：不可变后端资源随包发布；数据库、生成配置、日志、备份和迁移锁位于 `Application.persistentDataPath`。
- 最终启动顺序：客户端单例 → 数据/版本检查 → SQLite 迁移 → 启动本地服 → 等待 `127.0.0.1:8711` → 构造 `GameServices` → 进入现有登录/主界面链。
- 开发运行：交互式 Unity Editor 点击 Play 先检查仓库 Debug `kapai.exe`，缺失或服务端编译输入更新时自动调用中央 `Build-Server.ps1`，构建失败取消 Play；就绪后与正式 Player 使用同一 SQLite 自动监管语义，停止 Play 时保存并回收其拥有的服务端。`Application.isBatchMode` 或 `-projectXExternalServer` 保持外部服务端/验收工具自行管理生命周期。
- S0 证据：`.local/unity-validation/steam-sqlite-s0-baseline-latest.json`、`steam-sqlite-s0-sql-inventory-latest.json` 和 `steam-sqlite-operation-ledger.json`；MySQL Extended/Actions/Mutations/Positive smoke 收到203个响应，错误扫描0，进程残留0。
- S1 证据：`.local/unity-validation/steam-sqlite-s1-latest.json`；SQLite静态链接、磁盘库增删查/NULL/InsertId通过，`sqlite*.dll=0`，最终 `kapai.exe` 的MySQL Extended/Actions/Mutations/Positive smoke为203响应、错误0、进程残留0。
- S2 证据：`.local/unity-validation/steam-sqlite-s2-latest.json`；从当前MySQL fallback Schema可重复生成173表/1360列，加入`schema_version`后最终174表、34个显式索引；Python与C++适配层均连续执行两次，`integrity_check=ok`，退出后无WAL/SHM残留。
- S3 证据：`.local/unity-validation/steam-sqlite-s3-latest.json`；6个兼容函数、10类有限语法转换、4类SQLite原生形式、运行时MySQL建表和显式错误合同通过；唯一`UPDATE LIMIT`在`script_call.cpp`保留MySQL原句并使用SQLite `rowid`子查询定点等价改写。最终`kapai.exe` SHA对应的MySQL组合smoke为203响应、错误0、残留0。
- S4 证据：`.local/unity-validation/steam-sqlite-s4-latest.json`与`steam-sqlite-s4-failures.json`；发现旧EXE早于源码后已作废旧结论并全量重编译，当前`kapai.exe` SHA为`8BFE438449308F4C9129D7B28EF360BB66F0A5D8320F59C7A4435351B00AF0F6`。新二进制在独立SQLite副本完成登录、创角、选角、主初始化、存档、正常退出、强制中断恢复和跨进程指纹，`integrity_check=ok`、WAL/SHM与进程残留0；同一新二进制回归MySQL组合smoke为205响应、错误0、残留0。MySQL源码、驱动、构建、Schema、脚本和回归能力均保留。
- S5 首批证据：`.local/unity-validation/steam-sqlite-s5-latest.json`；机器矩阵冻结17个模块/25条有效Steam协议，22条已有主动请求/专用推送触发，`/18、/62、/70`已双端被动出现。当前同一83-case持久化角色套件在SQLite/MySQL均为120响应、manifest后端单边协议0、日志错误0；`/88`正确启动前夹具字节一致且残留0；11项确定性持久字段一致。PlayerHud通过`steamProtocols`排除Chat `/26`、Activity `/199`、Welfare `/222`，Task通过`steamProtocols`排除已停用旧主/支线`/39`，完整Cocos协议表不再等于Steam请求范围。
- Bag S5 已关闭：`.local/unity-validation/steam-sqlite-s5-bag-latest.json`；隔离新角色同一8-case流程在SQLite/MySQL均52响应，`/8`三包与`/15`六包字节一致，新增、整理、直接使用删除、任选礼包奖励/扣减语义一致；正常退出后重启`/8`继续字节一致，数据库`package/save_data/mission`三项SHA一致。
- Task、PlayerHud、Hero、HeroEquip、Mail、Shop、GameplayShops、World、Draw、Gameplay、YouLi S5 均已关闭：模块证据均为`.local/unity-validation/steam-sqlite-s5-<module>-latest.json`。YouLi在新隔离角色重复查询`/335 op=1`并重启复查，归属包始终为权威空态`0100`且逐字节一致；`xunbao/mission/save_data`及货币原始值一致、写入0，5地点裁剪配置语义一致。当前下一步验证FengShenStory协议与奖励持久化；响应总数只作诊断，不替代模块语义断言。
