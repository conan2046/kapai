# 本地测试服验证历史

此文件只记录历史验证证据和阶段结论；稳定规则写入 `AGENTS.md`，运行步骤写入 `LOCAL_RUN.md`，当前覆盖矩阵由 `tools/local/Export-ProtocolCoverage.ps1` 生成到 `PROTOCOL_COVERAGE.md`。

## 2026-07-06

- `kapai.exe` 可在 Windows 本机常驻运行，监听 `0.0.0.0:8711`。
- `ProjectX.exe` 可由 `tools/local/Start-Client.ps1` 启动，并与本地游戏服保持 TCP `Established`。
- 服务端收到客户端 `MSG_LOGIN/1001`，`local_test=1` 下自动创建/绑定 `Test01`，客户端随后发送 `MSG_CHOOSE_HERO/1004`。
- 客户端日志观察到 `DealMsgStartGame succ=1`，已越过登录等待层进入本地游戏主流程。
- 修复过的关键本地问题包括 MySQL DLL 链、gyu 包头长度、UTF-16LE 字符串、零 payload 包、Windows send queue、红点本地降级、在线状态登录库写回跳过、新神器 vector 越界、保存 SQL 参数错位。
- `kapai.exe` 与 `ProjectX.exe` 同时运行超过 6 分钟后，服务端日志未再出现 `call:`、Lua `attempt to`、MySQL 空连接、Debug assertion、崩溃类错误。

## 2026-07-07

- `Invoke-ProtocolSmoke.ps1 -Extended` 覆盖登录/选角、背包、系统时间、保存设置、字符串设置、红点、关卡地图、副本成就、体力、图鉴、血战、游历、世界等级、每日活动、VIP、抽神将、神将副本、藏宝图、试炼、阶段目标、坐骑、翅膀、任务、称号、阵法、资源找回、帮派列表、我的帮派、客户端网络检测。
- `-Extended -Actions` 覆盖空背包格详情、隐藏坐骑/翅膀、血战排行/空宝箱、免费体力信息、空关卡宝箱/节点详情、商店列表、神将装备/法宝列表、强化大师/搜索次数、无效可接任务详情、无效称号显示、单条字符串设置读取。
- `-Extended -Actions -Mutations` 覆盖数值设置保存/读取、客户端字符串保存/读取、聊天频道关闭/开启、聊天开关查询、隐藏坐骑/翅膀、无效称号隐藏/取消使用。
- `-Extended -Actions -Mutations -InvalidRisky` 覆盖商店无效购买/刷新/次数、阶段目标奖励、图鉴升级、空游历开始/领奖、无效帮派创建/申请、抽神将未知操作、关卡战斗/扫荡/重置、血战复活、神将装备穿戴/卸下/强化、法宝穿戴/卸下。
- 一次性新角色烟测验证 `PRO_CREATE_ROLE/1003`、`PRO_SELECT_ROLE/1004`、主流程初始化回包和组合协议；曾创建 `roleId=1000008`，收到 98 个回包。
- 正向烟测覆盖有效创建帮派、帮派信息/成员/捐献信息查询、帮派铜钱捐献、免费体力领取尝试、抽神将单抽尝试、血战开始/挑战/重置、游历开始/领奖尝试、商店刷新/购买尝试、阶段目标领奖尝试。
- 扩展 smoke 后续覆盖心跳、排行榜、离线经验、新神器、变身、公告、充值 serverId、膜拜、飞仙数据、任务追踪、答题、帮助标题、日常 Boss、钓鱼房间、擂台积分、玩家自身信息、脱离卡死坐标、无效物品描述；一次新角色验证收到 `recv_count=117`。
- 后续扩展追加覆盖好友、妖灵、帮战、PK 提示、免战牌、交易行、鲜花、无效猜拳、空实名；一次新角色验证收到 `recv_count=134`。
- 再次扩展追加覆盖附近玩家、神将总览、角色名检查、自身角色查询、建帮后的帮派副本章节/buff/活跃查询；一次新角色验证收到 `recv_count=142`。
- 修复和本地降级包括 `j.GetFuncOpenLevel`、帮派 NULL 字段重启崩溃、本地建帮默认字段、帮派副本缺配置静默跳过、`j.GetQuestion`、`j.GetDailyBossExp`、`j.MakeDailyBossInfo`、`CUser:GetVal`、`CUser:SetVal`、`CUser:GetBossMissionStarInfo`、题库默认 21 条、help 表登录库缺失降级。
- 多轮 7 分钟等待验证中，保存线程和定时器未产生新增 SQL/Lua/assert/crash/config-error。

## 2026-07-08

- `Run-LocalVerification.ps1` 已跑通当前服务端运行态：自动创建一次性角色，执行 `-Extended -Actions -Mutations -Positive` smoke，日志扫描未发现 SQL/Lua/assert/crash/config-error 类错误。
- `Export-ProtocolCoverage.ps1` 已生成 `PROTOCOL_COVERAGE.md`，当时统计为服务端注册协议 148 个、smoke 已覆盖协议号 67 个、未覆盖注册协议 81 个。
- 边界仍然存在：真实扣费购买、真实领奖、真实升级、真实抽卡奖励、战斗结算、有效加入已有帮派、人工 UI 全量点击仍需继续用一次性本地角色分层验证。
