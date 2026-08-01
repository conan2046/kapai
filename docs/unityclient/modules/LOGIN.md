# 登录与创角

> 当前结论：2026-08-01 已按新标准从 G0 重做并通过 G0-G6；21/21 控件、10/10 语义断言、17/17 双端原生视觉、精确恢复、切号隔离、零夹具残留和两次真实 BuildBatch 均通过。旧“complete/第一阶段完成”、旧截图和旧 Bootstrap Runner 结果未用于跳过门禁。

## G0 冻结

- 模块：P0 第一个模块“登录与创角”；后续依次为系统设置、主界面 HUD。
- 分辨率：Windows 100% 缩放，原生客户区 `1334×750`。
- 现有角色固定账号：`7200057 / 1000115`；终态切号隔离账号：`705213 / 1000006`。
- 无角色创角：标准 Runner 从 `7300000+` 分配隔离账号，执行 `snapshot → setup → assert → run → relogin → finally restore → cleanup assert`。
- 控件矩阵：`docs/unityclient/matrices/LOGIN_CONTROLS.json`，21 个物理控件/控件族，`workflowPolicyVersion=1`。
- 包含：Logo、Windows 预载、`LoginBgLayer`、`loginLayer`、`SeverListLayer`、`RoleCreateLayer`、`NoticeLayer`、`/1001、/1002、/1003、/1004、/88`、已有角色、无角色创角、合法/非法/重复名、选服、登录失败/超时/断线/重连、返回/重进/切号隔离。
- 成功边界：仅确认当前 `UImainLayer_new` 已成为根、`/1004 Remaining=0` 且 `/88` 已请求；HUD 控件属于后续模块。
- 排除：仓库无服务端源码的正式登录服 `/1501、/1502、/1505、/1506`、账号注册、SDK 登录、维护公告 `GameNoticeLayer`；支付、活动、基金、福利、竞技、社交均不进入本模块。

## 完整 Cocos 源码链

```text
client/ProjectX/src/main.lua:25-39
  -> require("View.LogoScene") -> LogoScene:create
client/ProjectX/src/View/LogoScene.lua:50-75
  -> res/UI/ui_login/bg3.png -> DelayTime 0.5s
  -> Windows: View.GameScene（不走 UpdateScene 热更新）
client/ProjectX/src/View/GameScene.lua:91-130,153-180
  -> ui_loginPlist/ui_commonPlist/ui_mainPlist/ui_zhandouPlist/ui_huobi/ui_wanfaPlist
  -> LCommonRequire -> LGameLogic
client/ProjectX/src/Logic/LGameLogic.lua:69-84,367-393
  -> InitUI Login.LoginBgUI
  -> LOCAL_TEST 构造唯一 127.0.0.1:8711 本地测试服
  -> InitUI Login.LoginUI(openType=1)
client/ProjectX/src/View/Login/LoginBgUI.lua:16-63
  -> csd/Login/LoginBgLayer.csb
  -> UI_Login/Bg 按 cover 缩放
  -> effect_chuangjue_1 挂载 Imod res2/animation/effect_chuangjue_1，动作0循环
client/ProjectX/src/View/Login/LoginUI.lua:21-61,130-248
  -> csd/Login/loginLayer.csb
  -> openType=1 显示 Btn_Sever/Btn_Play/Btn_handover
  -> Btn_Sever -> Login.ServerListUI
  -> Btn_Play -> TCPSelectedGameServer
  -> Btn_handover -> ShowLoginInput
client/ProjectX/src/Logic/LGameLogic.lua:886-904
  -> GameSocketConnectedSuccess -> QueryGameLogin
client/ProjectX/src/NetWork/LuaNetSendMsg.lua:141-215
  -> /1001；/1002 op1/2；/1003；/1004
client/ProjectX/src/NetWork/LuaNetRecvdMsg.lua:6136-6183
  -> /1001 roleId=0: InitUI Login.RoleCreateUI
  -> /1001 roleId>0: QueryStartGame(/1004)
client/ProjectX/src/View/Login/RoleCreateUI.lua:35-202
  -> csd/Login/RoleCreateLayer.csb
  -> 返回/男女/名称/随机/开始
  -> effect_chuangjue_1 动作0循环
  -> Create_5（男）或 Create_4（女）动作0循环
  -> 随机名 /1002 op=2；创建 /1003
client/ProjectX/src/NetWork/LuaNetRecvdMsg.lua:6078-6134
  -> /1003 成功自动 /1004
  -> /1004 成功 ReadRoleData -> 当前主界面初始化
client/ProjectX/src/View/MainUI.lua:257
  -> QueryMsgHeader
client/ProjectX/src/NetWork/LuaNetSendMsg.lua:6629-6633
  -> /88
client/ProjectX/src/NetWork/LuaNetRecvdMsg.lua:13136-13155
  -> count>0: InitUI NoticeUI
client/ProjectX/src/View/NoticeUI.lua:55-159,183-233
  -> csd/NoticeLayer.csb
  -> 动态标题列表、正文 ScrollView、公共 FirstClass 关闭回调
```

选服分支：`LoginUI:HandleSelectServer → ServerListUI.lua → SeverListLayer.csb`；左侧动态区服行调用 `LeftTableCellTouched/SelServerArea`，右侧动态服务器行首次选中、再次点击进入，独立 `Btn_Play` 也进入，`btn_Exit` 返回。

失败/重连分支：`LGameLogic:GameSocketConnectedFailed/LoginSocketConnectedFailed → ShowSocketConnectFiiledTips → MessageBox OK 重连 / Cancel 退出`；Unity 桌面验收的 Cancel 语义固定为取消后台重连并返回登录页，不退出编辑器。

## AppDef 本地入口

`client/ProjectX/src/core/AppDef.lua:13-23`：

| 项 | 当前值 |
|---|---|
| `LOCAL_TEST` | `true` |
| `LOCAL_TEST_UID` | `1`，由 `Start-Client.ps1 -LocalUserId` 只改模拟器副本 |
| `LOCAL_TEST_SIGNATURE` | `local_test` |
| server | `1 / 本地测试服 / 127.0.0.1:8711` |
| `LOCAL_TEST_AUTO_ENTER` | `true` |
| `LOCAL_TEST_AUTO_CREATE_ROLE` | `true` |
| `LOCAL_TEST_ROLE_NAME` | `Test01` |

G1 取证必须针对模拟器副本关闭自动进入/自动创角，且不得改写仓库 `AppDef.lua` 的用户已有内容。

`Start-Client.ps1` 每次启动先从权威源强制恢复模拟器 `AppDef.lua`，再应用本次 UID、自动进入、自动创角、角色名或测试端点覆盖；避免上一次可逆测试端点泄漏到下一次启动。

## 协议字段与服务端

| 协议 | 请求 | 成功响应 | 处理函数 |
|---|---|---|---|
| `/1001 PRO_USER_LOGIN` | `uint32 loginId, string signature, string version, uint32 serverId, string netInfo, string mac, string IMEI, string IDFA` | `byte success, byte crossType, uint32 userId, uint32 roleId`；有角色追加 `string name, byte head, uint16 level, byte sex` | `pack_deal.cpp::UserLogin` |
| `/1002 PRO_ROLE_NAME_CHECK` | `byte op`; op1=`string name`; op2=`byte sex` | op1=`byte success[,string error]`; op2=`byte op,byte sex,byte count,string[] names` | `RoleNameOption` |
| `/1003 PRO_CREATE_ROLE` | `string name, byte sex, byte model, byte head, uint16 ad` | `byte success, uint32 roleId, string name, byte sex, byte model, byte head, uint32 createTime`；失败追加 `string error` | `CreateRole` |
| `/1004 PRO_SELECT_ROLE` | `uint32 roleId` | `byte success` 后为完整角色权威快照；Unity 必须消费至 `Remaining=0` | `SelectRole` |
| `/88 PRO_GONGGAO` | 无载荷 | `byte count`，每项 `string title,string text,byte id,byte opType`；无公告时服务端合法不回包 | `QueryGongGao` |

注册路由：`server/src/pack_deal.cpp:152-155,262`。服务端实现：`UserLogin:629-902`、`RoleNameOption:990-1054`、`CreateRole:1116-1277`、`SelectRole:1279-1494`、`QueryGongGao:21312-21356`。

`/1004` 当前关键顺序：`roleId,name,sex,model,head,level,exp,power,money,premium,boundPremium,potential,soul,packageCapacity,guildId,guildRank,guildName,showGuildName,guildContribution,rechargeOpen,transformId,transformState,charm,regTime,serverId`。

## 错误文本

响应首字节使用 `PRO_SUCCESS=1 / PRO_ERROR=0`，错误不是独立数值枚举，而是随后字符串：

| 分支 | 当前文本 |
|---|---|
| 版本过低 | `版本过低，请更新版本重试` |
| 登录库错误/超时/校验 | `登陆错误1` / `登陆超时，请重新登陆。` / `登陆校验错误，请重新登陆。` |
| 名称长度 | `名称长度不符要求哦` |
| 限制字符 | `"%s"字为限制使用字符，请换一个哦` |
| 非法词 | `名称包含非法字符，请重新输入` |
| 名称检查重复 | `角色名已存在` |
| 创建重复 | `名称已被占用啦~换一个吧` |
| 已有角色 | `角色已经存在` |
| 选角非法/其他角色在线/封号 | `登录失败` / `您有其他角色在游戏中` / `此用户已封号,请与管理员联系` |

证据：`server/src/language_transform.h:622-640,2936`。

## CSB、动态节点与资源

| 页面 | 源/Prefab | 动态或动画语义 |
|---|---|---|
| LoginBg | `csd/Login/LoginBgLayer.csb` → `Prefabs/Login/LoginBgLayer.prefab` | `UI_Login/Bg` cover 缩放；`effect_chuangjue_1` Imod 动作0循环 |
| loginLayer | `csd/Login/loginLayer.csb` → `Prefabs/Login/loginLayer.prefab` | `Btn_Sever/Btn_Play/Btn_handover`；切换态显示账号/签名输入与 `Btn_Login` |
| SeverList | `csd/Login/SeverListLayer.csb` → `Prefabs/Login/SeverListLayer.prefab` | `Item_1/Item_2` 克隆为左右 `TableView` 动态行；选择图、状态图、角色摘要运行时填充 |
| RoleCreate | `csd/Login/RoleCreateLayer.csb` → `Prefabs/Login/RoleCreateLayer.prefab` | 背景 Imod；`Role` 挂点创建 `Create_5/Create_4`，`PlayNewAction(0,true)` |
| Notice | `csd/NoticeLayer.csb` → `Prefabs/NoticeLayer.prefab` | `Btn` 克隆标题行；`CreateColorText2` 动态正文；ScrollView inner size 动态扩展；公共 FirstClass 关闭 |

源 CSD 不在当前仓库工作树内；机器 IR 的 `source` 字段记录为 `cocosstudio/csd/...`，当前可验证源是 shipped CSB + `UnityMigration/documents/*.json` + Prefab。此缺口必须在 G2 `sourceAudit` 明示，不得猜 CSD 路径。

## Unity 最终实现与边界

当前 `StartupPresenter`、4 个登录 Prefab、`LoginPresenter`、Lua `LoginController/LoginProtocol/LoginView`、`NoticePresenter` 和标准批处理 Runner 已闭合 21 个冻结控件：服务器列表按 Cocos `SeverListLayer` 动态 Item 语义渲染；`/1001→/1003→/1004`、`/1002`、`/88` 均由真实回包驱动；已有角色、无角色创角、男女/随机名、非法/重复/合法名、连接失败、超时、在线断线、重连、返回、重进、切换账号和账号隔离均通过。

保留边界：当前仓库缺独立正式登录服，生产渠道 SDK、正式维护公告与发布配置继续后置；系统设置和主界面 HUD 是独立 P0 模块，不在本模块实现；支付、活动、基金、福利、竞技和社交均未提前处理。

## 门禁证据

- G0：本文件、`docs/unityclient/matrices/LOGIN_CONTROLS.json`、当前入口库存、Manifest/场景注册。
- G1：`.local/unity-validation/login-g1-source-evidence.json`、`.local/unity-validation/login-cocos-automation-ledger.json`、`.local/ui-fidelity/Login/cocos/g1-20260801/`。新鲜原生证据覆盖登录页、选服、已有角色、男女创角、随机名、非法名、重复名、合法创建/重登、`/88` 公告、连接失败、约 25 秒真实 OS 连接超时、在线断线/重连、创角返回/重进、`7200057 ↔ 705213 ↔ 7200057` 隔离。
- Cocos 原生 Cancel 行为是 `Director:endToLua()` 退出客户端；Unity 批处理验收不得退出编辑器进程，采用“取消重连并回到登录页”的桌面等价语义。
- `/1002` 本地真实服务端原先仍转发到已禁用长连接服，现仅在 `local_test=1` 返回三个确定性候选；生产路径不变。真实 `/1003` 重名错误包和数据库零新增已验证。
- `/88` 使用可逆公告夹具：`snapshot → setup → assert → run → cleanup → assert`；合法创角夹具完成 `snapshot → run → relogin → capture → cleanup assert`，身份残留为 0。
- `PRO_UPDATE_PACK /15` 属背包初始化响应，不属于登录模块；宽泛 Extended smoke 的缺失已与登录 `/1002` 专项验证拆分，本模块不越界修复背包。
- G2：`.local/unity-validation/login-g2-source-audit.json` 与 `.local/protocol-evidence/Login/{1001,1002,1003,1004,88}.md`。入口、协议所有权、配置资源、运行时 Transform 四项闭包完成；5 份 IR 共 127 节点、116 次资源引用（57 个全局唯一资源路径）、缺失 0，根画布均为 `1334×750 / cocos-bottom-left-v1`。动态 Item/公告正文/ScrollView/Imod 语义已冻结。
- G3：标准编辑器检查通过；Login Prefab/场景、编译和 Console 无阻塞错误。证据 `.local/unity-validation/login-g3-static-evidence.json`（旧 Runner 不计证）。
- G4：标准 batchMode Runner 通过 21/21 控件与 10/10 语义断言；真实服务端覆盖成功/失败/超时/断线/重连/返回/重进/切号隔离。证据 `.local/unity-validation/login-fixed-account-latest.json`。
- G5：同账号、同数据、同步骤、同分辨率 `1334×750` 的 17/17 Cocos/Unity 原生截图、并排/叠加和差异报告通过。证据 `.local/ui-fidelity/Login/cocos/g5-20260801/`、`.local/ui-fidelity/Login/unity/g5-20260801/`、`.local/ui-fidelity/Login/compare/g5-live-20260801/report.json`。
- G6：21/21 控件矩阵、10/10 语义、严重错误 0、切号隔离、零 Fixture 残留通过；两次真实 `BootstrapSceneBuilder.BuildBatch` SHA-256 均为 `6A476349E892BF29E845CCA9F37D2292FB0853ADA1868415CAAF982FCD20660C`。自动复盘 62/62 失败已解决、未解决 0。证据 `.local/unity-validation/bootstrap-idempotence-latest.json`、`.local/unity-validation/login-retrospective-latest.json`、`docs/unityclient/matrices/LOGIN_CONTROLS.json`。
