# 登录链路代码取证与 Unity 对照

> 基准：当前 Windows Cocos 模拟器实际代码路径；不以截图或同名旧资源判断版本。

## 当前 Cocos 启动/登录调用链

| 顺序 | 当前代码调用 | UI/资源 | 协议/结果 |
|---|---|---|---|
| 1 | `main.lua -> View.LogoScene:create()` | 代码创建 `res/UI/ui_login/bg3.png`，停留 0.5 秒 | 无 |
| 2 | Windows 分支 `LogoScene -> View.GameScene` | 代码创建 `bg_jzzs.jpg + tipbg.png + MicrosoftArial`；异步预载 6 组公共 plist | 无；Windows 不进入 `UpdateScene` 热更新 |
| 3 | `GameScene -> LCommonRequire -> LGameLogic` | `LoginBgUI` 加载 `csd/Login/LoginBgLayer.csb`；`LoginUI` 加载 `csd/Login/loginLayer.csb` | 本地直连由 `LGameLogic:LoadDataFinish()` 构造唯一“本地测试服” |
| 4 | `LoginUI(openType=1)` | 隐藏账号/密码/注册/SDK，显示 `Btn_Sever/Btn_Play/Btn_handover`；本地配置 0.5 秒调用 `EnterGame()` | `TCPSelectedGameServer -> 127.0.0.1:8711` |
| 5 | `GameSocketConnectedSuccess -> QueryGameLogin` | WaitAni 显示“连接游戏服务器成功” | `/1001 PRO_USER_LOGIN` |
| 6A | `/1001 roleId=0 -> Login.RoleCreateUI` | `csd/Login/RoleCreateLayer.csb`；本地 0.5 秒自动创建；男女角色 Imod | `/1003 PRO_CREATE_ROLE`，成功后自动 `/1004` |
| 6B | `/1001 roleId>0 -> QueryStartGame` | 保持等待态 | `/1004 PRO_SELECT_ROLE` |
| 7 | `/1004 -> ReadRoleData -> 主界面初始化` | `common/UImainLayer_new.csb`；云层 `createTimeline` 循环 | 角色权威快照及主界面初始化协议 |
| 8 | `MainUI -> QueryMsgHeader()` | 空/正常公告使用 `csd/NoticeLayer.csb`；维护公告 `/1505` 才使用 `csd/GameNoticeLayer.csb` | `/88 MSG_CLIENT_ACCOUNT` |

生产账号登录服 `/1501、/1502、/1505、/1506` 在本仓库没有服务端源码；本地 Windows 验收只走已有的游戏服直连路径，不伪造正式登录服。

## 游戏服协议字段

| 协议 | 请求字段（顺序/宽度） | 成功响应关键字段 | 服务端 |
|---|---|---|---|
| `/1001` | `uint32 loginId, string signature, string version, uint32 serverId, string netInfo, string mac, string IMEI, string IDFA` | `byte success, byte crossServerType, uint32 userId, uint32 roleId`; 有角色时追加 `string name, byte head, uint16 level, byte sex` | `pack_deal.cpp::UserLogin` |
| `/1002` | `byte op`; op1=`string name`，op2=`byte sex` | 校名或随机名列表 | `RoleNameOption` |
| `/1003` | `string name, byte sex, byte model, byte head, uint16 ad` | `byte success, uint32 roleId, string name, byte sex, byte model, byte head, uint32 createTime` | `CreateRole` |
| `/1004` | `uint32 roleId` | `byte success` 后为完整角色权威快照；Unity 必须读到 `Remaining=0` | `SelectRole` |
| `/88` | 无载荷 | `byte count`，每项 `string title, string text, byte id, byte opType` | `GongGaoOption` |

自动生成的搜索草稿位于 `.local/protocol-evidence/login-1001.md`、`login-1003.md`、`login-1004.md`、`login-88.md`；最终字段以上表人工核对结果为准。

## CSB 与动画

| 状态 | CSB/代码资源 | 动画调用 | Unity 对应 |
|---|---|---|---|
| Logo | 无 CSB；`bg3.png` | 0.5 秒 DelayTime | 待补启动阶段 |
| 资源预载 | 无 CSB；`bg_jzzs.jpg/tipbg.png` | 公共 plist 异步回调 | 待补启动阶段 |
| 登录背景 | `Login/LoginBgLayer.csb` | `ImodAnim res2/animation/effect_chuangjue_1`, `PlayActionRepeat(0)` | `ImodAnimationPlayer/Resources`，动作 0 循环 |
| 登录操作 | `Login/loginLayer.csb` | 仅 0.5/0.2 秒逻辑 DelayTime | 保持真实 Prefab；本地显示 `Btn_Play`，不是账号 `Btn_Login` |
| 选服 | `Login/SeverListLayer.csb` | 无独立 ANI | 保持真实 Prefab，运行时绑定本地服 |
| 创角 | `Login/RoleCreateLayer.csb` | 背景同上；角色 `PlayNewAction(0,true)` | 背景统一 Imod 播放器；男女角色资源待逐项核对 |
| 维护公告 | `GameNoticeLayer.csb` | `createTimeline`, `gotoFrameAndPlay(0)` | `CocosTimelinePlayer`，正式登录服后置 |
| 游戏公告 | `NoticeLayer.csb` | 无 Lua 专属 ANI | `/88` 阶段迁移 |

## 已确认的 Unity 偏差

- 原 Unity 把 `Layer/Login/Btn_Login`（账号登录）当成本地进入游戏按钮；当前 Cocos 本地路径实际使用 `Btn_Play`。
- 原 Unity 登录后直接发 `/1003`，没有经过 `RoleCreateLayer` 状态。
- 原 Unity 未实例化 `SeverListLayer/RoleCreateLayer`，未播放登录背景 `effect_chuangjue_1`。
- 原 Unity 尚未覆盖 Logo、Windows 资源预载态和 `/88 NoticeLayer`。

## 本阶段改造门禁

- 代码链、协议字段、真实 CSB、ANI/Timeline 全部能回指当前 Cocos 调用点。
- 本地登录页显示/交互节点与 `openType=1` 一致，`Btn_Play -> /1001 -> RoleCreate(可选) -> /1004` 状态一致。
- Unity 静态截图与动画过程均验收；截图只用于最终像素比较，不作为流程取证依据。

## 2026-07-18 验证结果

- 统一入口：`pwsh -File tools/unity-migration/Run-UnityModuleValidation.ps1 -Module Login -UserId 7300102 -NoStartServices -SkipPythonTests`
- 专用门禁顺序：`Btn_Play → /1001 roleId=0 → RoleCreateLayer → Create_5/Create_4 动作 0 循环 → /1003 → /1004 → UImainLayer_new`。
- 最终证据：`userId=7300102`、`roleId=1000040`；结果 `build/ui-migration/bootstrap-app-result.json` 为 `success=true`。
- 截图：`build/ui-migration/bootstrap-login.png`，`1334×750`；仅承担最终静态视觉证据。
- 自动化已修正：登录验证禁用背包自动点击，只有登录专用三阶段全部完成才允许写入 `COMPLETE`。
- 失败隔离：`7200017` 已有旧角色；`7300101` 因首次错误把 Toggle 当 Button 绑定而中止。两者不作为最终证据。
- 剩余边界：Logo/Windows 六组公共 plist 预载态与 `/88 NoticeLayer` 尚未进入 Unity 动态门禁；服务端无有效公告时 `/88` 可不回包，后续不得伪造空响应。
