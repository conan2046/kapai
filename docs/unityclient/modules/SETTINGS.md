# 系统设置模块

> 当前状态：2026-08-01 已按新标准从 G0 重做并通过 G0-G6；21/21 控件、10/10 语义、8/8 双端原生视觉、设备级持久化、切号隔离、零夹具残留和两次真实 BuildBatch 均通过。旧“第一阶段完成”、旧截图和旧 Runner 结果未用于跳过门禁。

## 当前结论

- 模块：P0 第二个模块“系统设置”；完成后下一模块才是“主界面 HUD”。
- 固定运行身份：`userId=7200057 / roleId=1000115`；切号隔离身份：`userId=705213 / roleId=1000006`；原生客户区 `1334×750`、Windows 100%。
- 设置本体是设备级本地配置，不读写服务端业务数据，登记 `no-server-fixture`；账号只决定角色/服务器展示和切号后的角色态清理。
- 设置自有页面只有 `OneLevelLayer + zhujue/SystemLayer`，无设置自有弹窗。公告、兑换码、商城、体力入口只验证路由边界，不迁移其页面或业务。

## G0 范围

包含：

- 主界面真实入口、公共一级背景、信息/设置页签、关闭返回。
- 体力/金币/元宝显示及其可见按钮状态；商城和体力操作仅登记边界。
- 头像、等级、角色名、服务器名与状态标识。
- 音乐开关、音乐音量、音效开关、音效音量；默认、开启、关闭、0/100 边界和中间值。
- 返回重进、客户端重启后的持久化；切号后身份数据隔离，同时设备级音频偏好按 Cocos 语义保留。
- 缺键、越界值、类型损坏、持久化不可用和音频服务不可用时的安全默认/失败反馈。
- 公告等级不足、公告无数据、兑换码路由和切换账号落回登录态。

排除：

- 公告正文与跳转、`/88` 数据夹具归公告/登录边界所有。
- 兑换码输入、领取与 `/199 op=18` 归福利/活动所有。
- 金币加号商城、体力加号使用/购买流程及支付、活动、基金、福利、竞技、社交均不在本模块扩展。
- 源码中整段注释掉的屏蔽附近玩家/切磋/鲜花/VIP/称号设置不属于当前可达产品。

## 完整源码链

1. `MainUI.lua:2026-2034`：`Layer/Main_UI/ButtonGroup7/btn_xitong` 点击 `Utils:OpenFunction(EMID_SHEZHI)`。
2. `AppDef.lua:239,838`：`EMID_SHEZHI=180`，当前路由 `Role.RoleMainUI, sub=2`；旧 `Setting.SettingMainUI` 路由已注释。
3. `Utils.lua:2648-2707`：通过 `LUILogicEvent.InitUI` 打开 `FirstClassLayer`。
4. `RoleMainUI.lua:16-47,94-108`：创建公共 `FirstClassBg`，动态克隆“信息/设置”页签，选择 sub=2，0.1 秒后加载 `View.Setting.SettingUI`。
5. `FirstClassBg.lua:21-70,87-109,243-289,467-501`：加载 `csd/OneLevelLayer.csb`；绑定关闭、货币显示、金币/体力加号和动态页签。
6. `SettingUI.lua:27-40`：加载 `csd/zhujue/SystemLayer.csb`；无 Timeline、无 Imod、无运行时动态节点。
7. `SettingUI.lua:68-117`：绑定角色信息、两组 CheckBox/Slider、公告、切号和兑换码。
8. `SettingUI.lua:119-170`：开关把对应 Slider 设为 0/100 并禁用/启用；Slider 按百分比写本地配置并发送音频事件。
9. `LUserConfigMgr.lua:9-12,68-75,161-212,614-617`：`CCUserDefault` 键为 `IsMusicClosed/IsEffectClosed/MusicVolume/EffectVolume`，每次写后 `flush()`；布尔默认 `false`、音量默认 `1`，越界音量读取为 `1`。
10. `LSoundLogic.lua:54-69,71-132,159-174,220-229,279-351`：通过 `ccexp.AudioEngine` 暂停/恢复背景音乐、禁止/允许音效并应用音量。
11. `SettingUI.lua:196-220`：角色头像、等级、名称和上次选择服务器名来自 `LRoleDataMgr/LUserConfigMgr`；重进按持久化值刷新。
12. `SettingUI.lua:172-193`：公告按钮等级不足显示“该功能2级开启”，否则发 `/88`；兑换码只打开 `Welfare.NewActiveCodeUI`；切号发送 `LGameEvent.ChangeUser`。
13. `LGameLogic.lua:909-945`：切号断开游戏服、清空 UI/角色态、恢复登录背景并重载登录流程。

## 协议与所有权边界

| 边界 | 请求/字段 | 服务端/结果 | 所有权 |
|---|---|---|---|
| 设置本体 | 无 | 无服务端写入 | Settings |
| 游戏公告 | `/88` 零载荷 | `QueryGongGao` 返回 `count + title + msg + showType + jumpType`；低于2级、无公告或数据库不可用时无回包 | 公告/登录；Settings 只验证入口与失败反馈 |
| 兑换码 | `/199 op=18 + code` | `HuoDongOption → CheckNewUser_JHM_all`，成功/错误由活动脚本返回 | 福利/活动；Settings 只验证打开弹窗边界 |
| 切换账号 | 无业务协议 | `GameDisConnect + Clear + ChangeUser`，回登录并清角色态 | Settings 按钮 + Foundation 生命周期 |

## CSB、资源与场景

- 当前 CSB：`client/ProjectX/res/csd/OneLevelLayer.csb`、`client/ProjectX/res/csd/zhujue/SystemLayer.csb`；可编辑 CSD 未随仓库提供。
- Unity IR/Prefab：`documents/OneLevelLayer.json`（50 节点）与 `documents/zhujue/SystemLayer.json`（23 节点）；设置层 11 个唯一资源引用，Unity 均存在。
- 设置层无 Timeline/Imod；唯一动态节点是 `FirstClassBg:AddTabBtn` 克隆 `Panel_10/Button1` 两个页签。
- `Bootstrap.unity` 已含禁用的 `SystemLayer`，但旧实现只推入该 View，未同步显示 `OneLevelLayer` 公共背景。

## G0 冻结时的 Unity 缺口

- G0 时已有：`SettingsController.onClick → Bridge:ShowSettings → SettingsPresenter`；SystemLayer 两组 Toggle/Slider、PlayerPrefs、切号按钮。
- G0 时缺失：公共一级背景/关闭/页签/货币栏、真实头像与角色/服务器字段、AudioSource 应用、公告/兑换码边界、默认/边界/损坏/不可用状态、真实控件 Runner、重启和双账号验证。
- 这些缺口已在 G3-G6 收口；旧 `ValidatePersistence()` 未作为新门禁证据。

## G0 验收合同

- 控件矩阵：`docs/unityclient/matrices/SETTINGS_CONTROLS.json`，21/21 已冻结并在 G6 全部通过。
- 设备级偏好语义：账号 A 调整后返回/重进/重启保留；切到账号 B 后音频偏好仍保留，但头像、等级、角色名、服务器和所有角色 Store/UI 栈必须只显示账号 B。
- `no-server-fixture`：不得创建或伪造设置业务表；只使用既有固定账号登录，运行前后服务端零 Fixture 残留。
- G1 必须由 Computer Use 从原生 `ProjectX.exe / Cocos Simulator` 取得当前页面与关键状态；旧截图无效。

## 当前证据

- G0：本文件及 `SETTINGS_CONTROLS.json`，21项控件与9类状态冻结。
- G1：`.local/ui-fidelity/Settings/cocos/g1-20260801/G1_COCOS_EVIDENCE.md`；8个唯一原生 Cocos 目标，覆盖真实拖动/开关、重启、切号、越界回退和恢复断言。
- G2：`.local/unity-validation/settings-g2-source-audit.json`；入口/协议所有权/配置资源/运行时 Transform 四闭包均完成，共73节点、28个触摸节点、36项资源记录。
- 协议边界：`.local/unity-validation/settings-protocol-88-evidence.md`、`.local/unity-validation/settings-protocol-199-evidence.md`。
- 资源分类：34项外部 Unity 资源全存在；31项 Cocos `PlistSubImage` 由图集提供；2项 `Default` 为内建资源；唯一源树缺失 `MarkedSubImage` 由 Unity 恢复资源和新鲜 Cocos 原生截图闭包。
- 旧 Unity Manifest/场景/Runner 仅作为缺口证据，不作为 G1-G6 通过证据。
- Settings operation ledger：`.local/unity-validation/settings-operation-ledger.json`。

## G3-G6 实现与验收

- G3：补齐 `OneLevelLayer + SystemLayer` 公共层级、21 项真实控件绑定、权威角色/货币展示、两组 Toggle/Slider、设备级 PlayerPrefs、真实 AudioSource 应用、损坏/不可用回退、外部边界和切号清理。Unity MCP 仅用于编辑器编译、Prefab、场景与 Console 检查。
- G4：标准 `Run-UnityModuleValidation.ps1` batchMode 固定账号 `7200057/1000115` 通过；21/21 控件、10/10 语义断言，默认、开关、0/100/中值、返回重进、重启、损坏回退、边界不越权和切号清理全部成功。
- G5：Cocos 与 Unity 使用同账号、同数据、同步骤、原生 `1334×750`，各 8 个新鲜状态；并排图、50% 叠加图、差异图和报告位于 `.local/ui-fidelity/Settings/compare/g5-live-20260801/`。切号后角色身份隔离，设备级 35%/65% 音频偏好保留。
- G6：矩阵 21/21、语义 10/10、严重错误 0、`no-server-fixture` 残留 0；两次真实 `BootstrapSceneBuilder.BuildBatch` SHA-256 均为 `6A476349E892BF29E845CCA9F37D2292FB0853ADA1868415CAAF982FCD20660C`。自动复盘 72/72 失败已解决，未解决 0。
- 最终证据：`.local/unity-validation/settings-g6-latest.json`、`.local/unity-validation/bootstrap-idempotence-latest.json`、`.local/unity-validation/settings-g6-severe-errors.json`、`.local/unity-validation/settings-no-server-fixture-latest.json`、`.local/unity-validation/settings-computer-use-lifecycle-latest.json`、`.local/unity-validation/settings-retrospective-latest.json`。

## 失败复盘与流程调整

完整原始记录不在对话中省略，统一保存在：

- `.local/unity-validation/settings-operation-ledger.json`：全部命令、门禁、Unity batch 和收口失败；当前 72 个失败/阻塞均有唯一 Resolved、rootCause、iterationAction、iterationEvidence。
- `.local/unity-validation/settings-cocos-automation-ledger.json`：Computer Use 对原生 `ProjectX.exe / Cocos Simulator` 的目标、观察、单步动作和结果。
- `.local/unity-validation/settings-g2-source-audit.json`：Lua 入口、CSB/资源、动态节点、Transform 与 Unity 缺口闭包。
- `.local/unity-validation/settings-protocol-88-evidence.md`、`.local/unity-validation/settings-protocol-199-evidence.md`：公告和兑换码协议/字段/服务端处理及所有权边界。
- `.local/unity-validation/settings-retrospective-latest.json`：自动复盘与未解决计数；`.local/unity-validation/settings-computer-use-lifecycle-latest.json`：Computer Use 运行时关闭证据。

重复问题按语义聚类如下；标签可交叉，不与 72 条简单求和：

| 重复族 | 次数 | 本轮调整 |
|---|---:|---|
| PowerShell/路径/参数类 | 34 | 禁止复合 `foreach` 后直接接管道；探索性 `rg` 允许零匹配；数组参数不得跨原生 `pwsh -File` 用逗号字符串传递 |
| 其中 `foreach` 管道解析 | 3 | 固定为 `$rows=@(foreach(...){...})` 后再单独管道 |
| Evidence/iterationEvidence 数组压平 | 2 | 只在当前 PowerShell 进程传数组，并在 G6 前运行 `New-UnityMigrationRetrospective -RequireEvidenceFiles` |
| 可选 `fixedAccount` 直接解引用 | 2 | 三个中央消费者统一改用 `Get-UnityMigrationPropertyValue`，覆盖 `no-server-fixture` 回归 |
| 截图重复/等价状态 | 5 | 仅允许源码证明的 default/corrupt、music-mid/restart 等价组；未声明重复继续硬失败 |
| 超时/锁/长任务包装 | 7 | 外层超时不短于工具内部超时；保留心跳；Bee 锁只允许中央工具同路径有界重试 |
| 协议外部边界误判 | 2 | 从“全局 Pending 必须为 0”改为点击前后同步增量为 0 |
| 切号后 roleId 丢失 | 2 | 在清理角色 Store 前快照权威 roleId，结果写入使用预切号身份 |
| Computer Use 初始化/状态 | 4，另有收口残留 1 | 首次无效即停止坐标重试；G6 新增强制检查并拒绝残留 `cua_node/node_repl.exe` |

本模块首次出现、非历史模板直接复现的问题：`SystemLayer` 被公共 `OneLevelLayer` 遮挡、导入 Slider 的 `__Handle` 为 0×0、Toggle 截图落在淡入中间帧、设备级音频偏好与账号身份隔离需同时成立、Cocos 切号对照使用了错误的 both-off 前置、以及本地设置合同没有 `fixedAccount` 仍需通过通用 G5/文档工具。对应修复已进入 Presenter、Runner、中央证据工具和回归测试。

## 收口与下一模块

- 系统设置 G0-G6 已收口。下一模块固定为 P0“主界面 HUD”，必须在新任务重新从 G0 开始。
- 公告、兑换码、支付、活动、基金、福利、竞技和社交仍保持所有权边界，未在设置模块顺手扩展。
