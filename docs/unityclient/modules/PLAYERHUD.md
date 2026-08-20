# 主界面 HUD 模块

> 状态：`G0-G6 passed / 56/56 complete`（2026-08-02）。2026-08-01 之前的“第一阶段完成”、截图、Runner、SHA 与历史完成标记未被复用为本轮门禁证据。

## 范围与所有权

- PlayerHud 只拥有：登录选角后的 HUD 数据显示、菜单展开/收起、被动聊天摘要、红点/提示显示、云层 Timeline，以及按钮的路由入口或不可用反馈。
- PlayerHud 不拥有：角色详情、背包、装备、法宝、阵容、排行、招募、帮派、任务、商城、福利、活动、充值、七日、首充、邮件、好友、回收、副本、玩法、聊天发送、语音与在线奖励领取业务页。
- 支付、活动、基金、福利、竞技、社交仅登记边界；本模块不得实现或修改这些页面。
- 固定验证身份：`userId=7200057 / roleId=1000115`；隔离身份：`userId=705213 / roleId=1000006`；原生客户区固定 `1334x750`。
- 数据合同：权威数据只读显示，`no-server-fixture`；不得以 Unity 假数据补协议失败、空数据或缺配置。
- Steam 范围覆盖：`tools/unity-migration/unityclient-modules.json` 的 `steamProtocols` 固定为 `/18、/62、/65、/206、/220、/226、/321、/1004`。聊天摘要及 `/26` 随 Chat 排除；活动/福利入口状态 `/199、/222` 随 Activity/Welfare 排除。下文完整 Cocos 协议表只保留原版所有权证据，不能重新开启这三条 Steam 请求或 UI。

## 登录到 HUD 的真实链路

1. `LuaNetSendMsg:QueryStartGame(roleId)` 发送 `/1004 PRO_SELECT_ROLE`。
2. `LuaNetRecvdMsg.DealMsgStartGame` 读取成功标记；成功调用 `LRoleDataMgr:ReadRoleData`，失败读取服务端错误串并显示原生提示。
3. `LRoleDataMgr:ReadRoleData` 读取角色 ID、名字、性别、模型、头像、等级、经验、总战力、金币、元宝、绑定元宝、潜能、神魂、背包格、帮派、充值开关、外观、魅力、创建时间、serverId/serzoneid，并派发 `EnterGame`、`PowerChanged`、`ChangeMapSuccess`。
4. `LGameLogic:ProcessEvent(EnterGame)` 进入游戏场景并清理登录 UI；`ChangeMapSuccess -> PreloadCommonRes -> LoadCommonResComplete`。
5. 公共资源加载完成后延迟 `InitUI("MainUI")`，再创建触摸层、奖励公共层并执行首次进场请求。
6. `MainUI:Init` 加载 `csd/common/UImainLayer_new.csb`，根尺寸取 `AppDef.frameSize`，完成布局、事件、菜单、数据与触摸初始化。

## Cocos UI、运行时节点与资源

- 主 CSB：`client/ProjectX/res/csd/common/UImainLayer_new.csb`；Unity IR 根为 `1334x750`、左下原点策略，共 194 个节点。
- 云层：`client/ProjectX/res/csd/common/UImain_cloudLayer.csb`，首次进入约 1 秒后挂到根节点 `Bg`，`gotoFrameAndPlay(0,true)` 循环。
- 聊天摘要：`client/ProjectX/res/csd/ChatLayer.csb`；完整聊天/语音资源为 `MainChatLayer.csb`、`VoiceWindow.csb`，仅前者的被动摘要和展开/收起属于 HUD。
- Unity 当前 Prefab：`Assets/ProjectX/res/csd/Prefabs/common/UImainLayer_new.prefab`、`UImain_cloudLayer.prefab`；Bootstrap 场景当前已引用主 Prefab。
- 主层常驻顶级节点：`ButtonGroup3`、`Head`、`tankuang2`、`ButtonGroup1`、`ButtonGroup4`、`tankuang1`、`ButtonGroup6`、`ButtonGroup7`、`ButtonGroup8`、`btn_online`、`btn_fuben`、`btn_wanfa`。Unity 中原 `ButtonGroup5` 的按钮已合并到 `ButtonGroup1`，由横向布局自适应排版。
- 安全区/层级：保持 CSB 的左下坐标、锚点、缩放、ZOrder、裁剪及 1334×750 比例；禁止为了填屏改为自由拉伸。
- 当前新 CSB 不含可见 serverId 文本、地图名、时钟、公告横幅或旧版 `locker` 折叠按钮；不得凭旧代码或旧截图补造。

## 数据 Store、配置与本地状态

- 权威角色 Store：`LRoleDataMgr`；HUD 初始化与事件刷新均读取它，不自建业务 Store。
- 角色名、头像、等级、战力、VIP、经验、金币、元宝、体力分别由 `MainUI:InitData` 绑定；金币使用 `Utils:getGoldStr()`，战力使用 `Utils:getNewPowerStr()` 与独立“万”图标语义，体力使用 `Utils:getTiliStr()`，经验为 `exp / JsonConfig.m_expConfig[level].exp`。
- 等级经验表：`JsonConfig.m_expConfig`，实际来源 `server/config/json/exp.json`；体力参数来自 `stamina.json/config.json`；功能开放来自 `client/ProjectX/res/ConfigData/function.dat`。
- `MainUI:QueryDataEnterGame` 立即发送 `/321 op=1`，并查询灵气/折扣礼包状态；约 1 秒后执行全红点检查、引导与合成检查。
- 菜单展开状态为当前 UI 实例的纯客户端状态，不跨重启持久化：装备菜单沿 Y 轴 `+112`、商城菜单沿 Y 轴 `-126`，时长约 `0.17s` 并伴随显隐渐变。

## 协议与服务端链

| 协议 | Cocos 请求/解析 | 服务端所有权 | HUD 用途与失败边界 |
|---|---|---|---|
| `/1004 PRO_SELECT_ROLE` | `QueryStartGame` / `DealMsgStartGame` / `ReadRoleData` | `CPackageDeal::SelectRole` | 初始角色快照；失败显示服务端错误且不得进入伪 HUD |
| `/18 PRO_UPDATE_CHAR` | `DealMsgUpdateChar` 按 op 更新经验、金币等 | `CUser` 主动推送 | 增量刷新；未知 op 忽略并留可诊断证据 |
| `/26 PRO_MSG_CHAT` | `DealMsgChat` / `ChatMiniShowLayer:AddMsg` | Chat/Social 所有者 | HUD 只读接收最多 10 条摘要；发送、私聊与语音不在本模块 |
| `/62 PRO_SYSTEM_INFO` | `DealMsgSYSAnoncement` 写入系统摘要与提示条 | 系统公告所有者 | 被动显示系统摘要/提示；不实现公告业务页 |
| `/199 MSG_HUODONG_OPTION` | `QueryLingQiButton(20)` | Activity 所有者 | 只消费 HUD 入口开放状态；活动页与写操作排除 |
| `/220 MSG_VIP_OPTION` | `DealMineVIPInfo` op=4 后派发 `VIPChanged` | VIP/Recharge 所有者 | 只读显示权威 VIP 等级；充值、月卡和试用业务排除 |
| `/222 MSG_TMP_HUODONG` | `DealMsgKaifuHuodong` op=4、89-91 | Welfare/Activity 所有者 | 只读显示在线奖励倒计时/可领态和三类折扣入口显隐；领奖、礼包、支付排除 |
| `/226 MSG_UPDATE_USER_LEVELUP_INFO` | `DealMsgUpgrade` | `CUser` 升级推送 | 等级/战力变化；异常包不得覆盖有效旧值 |
| `/321 MSG_SPIRIT` | `DealTili`，op=1 返回错误码、体力和下次恢复时间 | `CPackageDeal::DealSpirit` | 体力显示/倒计时；op=2/3 的领取业务不属于 HUD |
| `/65 PRO_Func_HotPoint` | op=1/2、redType、status，派发 `RedDotStateUpdate` | `CPackageDeal::FuncHotPointOption` | 红点显隐；local_test 缺表时返回隐藏态，不造红点 |
| `/206 MSG_SYNC_TIME` | `DealMsgSyncTime` | `CPackageDeal::SyncTime` | 生命周期时间同步；当前新 HUD 无可见时钟控件 |

协议证据位于 `.local/protocol-evidence/`：HUD 完整集合为 `/18、/26、/62、/65、/199、/206、/220、/222、/226、/321、/1004`。共享协议只消费上述只读展示分支，所有目标业务页和写操作保持原所有者边界。

## 可见区域与交互

- 身份区：头像、角色名、等级、VIP、战力、经验条；点击头像只验证进入角色页的路由边界。
- 资源区：元宝、金币、体力；元宝加号按源码禁用，金币/体力加号只验证现有商城/使用界面边界。
- 常驻入口：背包、英雄背包、阵容、排行、招募、帮派、任务、设置、邮件、好友、回收、世界副本、玩法；Steam 已排除的福利、活动、充值和在线奖励不得显示。
- 装备子菜单：装备、法宝；商城子菜单：普通商城、神魂商城、玩法商城；HUD 只拥有开合动画及入口反馈。
- 条件入口：Steam 不投放七日、首充、充值、三类折扣礼包，对应 HUD 节点固定隐藏，`/222 op89-91` 也不得重新开启；当前 CSB 默认隐藏的主角、宠物折扣、登录七日、开服排行、转盘、VIP、礼包节点不得强制显示。
- 红点：由 `LRedDotCheckMgr` 聚合并响应 `/65`；逐入口状态必须可重复刷新，不得把红点静态烘焙进 Prefab。
- 聊天摘要：最多展示 10 条被动频道摘要，可滚动并自动到底；箭头负责展开/收起。点击背景、私聊、好友、世界/帮派语音只验证社交边界或不可用反馈，不迁移发送/语音业务。
- 在线奖励：HUD 只显示倒计时/可领取提示；不得在本模块实现领奖或 `/Activity` 业务。

## 生命周期、空态与错误态

- 首次进入：必须等待 `/1004` 权威快照与主资源完成，禁止短暂显示固定测试值。
- 刷新与返回重进：`/18`、`/226`、`/321`、`/65` 仅改变对应字段/红点；返回 HUD 重建当前权威状态，菜单默认收起。
- 客户端重启/断线重连：重新走选择角色与初始化请求，旧连接的 pending/回包不得污染新会话。
- 切换账号：清空角色、HUD、pending、聊天摘要和红点会话态；账号 B 只显示账号 B 的权威数据。
- 空数据、缺配置、资源缺失、协议失败、超时：保持安全空态或最后一次已验证值并给出可观测不可用反馈；不得用 Unity 假值、占位图片或目标业务页面掩盖失败。

## G0-G6 收口结论

- G0：从当前真实 Lua/CSB/协议链冻结 56 个控件与状态；唯一机器源为 `docs/unityclient/matrices/PLAYERHUD_CONTROLS.json`。
- G1：Computer Use 仅操作原生 `ProjectX.exe / Cocos Simulator`，取得首次进入、装备/商城菜单、聊天空/多消息、返回重进、客户端重启、断线、重连、切号登录和隔离账号共 11 个新鲜状态；完成后 runtime 已重置并确认残留 0。
- G2：入口、11 个共享只读协议、配置到资源、动态节点、云层 Timeline、运行时 Transform/锚点/缩放/裁剪/层级全部闭合；缺失 serverId/地图名/旧折叠按钮按当前源码判定为不存在，不补造。
- G3：Unity 主 HUD、ChatLayer、Presenter、场景引用和编译通过；MCP 仅用于本门禁，之后关闭。
- G4：标准 `Run-UnityFixedAccountValidation.ps1` batch Runner 通过。固定账号 `7200057/1000115`、隔离账号 `705213/1000006`；56/56 Runtime 控件 ID 与矩阵完全一致，14/14 语义断言、严重错误 0。22 个主路由按钮均真实调用：仅已完成设置模块打开并返回，其他目标页只显示所有权/不可用反馈，协议 Pending 不增加。
- G5：Cocos 与 Unity 均为原生客户区 `1334x750`，同账号、同数据、同步骤、同稳定帧的 11 组原图齐全；并排图、50% 叠加图、增强差异图与报告均生成，最大 MAE `17.9779`。证据：`.local/ui-fidelity/PlayerHud/cocos/g5-20260801/`、`.local/ui-fidelity/PlayerHud/unity/g5-20260801/`、`.local/ui-fidelity/PlayerHud/compare/g5-live-20260801/report.json`。
- G6：56/56 控件均有独立路径的 Cocos/Unity 双端证据；DataPreflight/setup/live assert/restore/cleanup 全通过，恢复精确且 Fixture 残留 0。SceneBuilder YAML 规范化后，两次真实 `ProjectX.Editor.BootstrapSceneBuilder.BuildBatch` 的 SHA-256 均为 `CE9FAD096983A00615EE522019AAC97AE72C8C008F89F097EFCBBAAC0CF256F3`；未使用 Force Rebuild。自动复盘 `125/125` 已解决，未解决 0；中央工具回归 `82/82`。
- 最终证据：`.local/unity-validation/playerhud-fixed-account-latest.json`、`.local/unity-validation/bootstrap-idempotence-latest.json`、`.local/unity-validation/playerhud-retrospective-latest.json`、`.local/unity-validation/playerhud-operation-ledger.json`。
- Steam SQLite S5：`.local/unity-validation/steam-sqlite-s5-playerhud-latest.json`。双方角色均冻结为1级59经验，通过仅`local_test`可用的`/13 op57`调用生产`CUser::AddExp`，`/18`十包与`/226`一包全部字节一致；`/226`语义均为1→2级、角色战力13800、出战神将战力12800、神将57品质4。正常退出重启后双端各34响应，等级2、经验0及`mission/user_spirit/save_data/pet/zhenfa`五项SHA一致。实际线格式保留旧等级`uint8`、新等级`uint16`的历史不对称，本阶段未擅改线上协议。
- Steam 商业入口排除（2026-08-20）：正式 Windows Player 从真实登录按钮进入 Main 后，`7日活动、首充、充值、折扣礼包×3` 六个节点均为非激活；`/222 op89-91`不能重新开启折扣入口。运行截图 `.local/steam-build/build/ui-migration/steam-hud-exclusions.png`，日志 `.local/unity-validation/steam-hud-exclusions-player.log`。

## 本轮迭代与后续自检

- “网络超时”提示被定义为终态：自动化第一次出现后立即停止等待和坐标试错，记录失败并转查源码、日志与协议。
- 中央编译预检现在能识别 Unity 退出码 0 但日志出现 `Assembly-CSharp.dll` 恢复型共享锁的情况，归档首轮并只重跑一次；`Unity.ILPP.Trigger` 纳入 owned-child 清理。
- 大型 UI IR 节点查询改用共享 `System.Text.Json` 遍历；多结果摘要改用 `Get-UnityMigrationValidationResultSummaries`，避免再次拼接禁止的 `foreach {...} |`。
- 下一模块 G0 前必须读取 `.local/unity-validation/playerhud-retrospective-latest.json`，复用上述终态识别、锁清理和命令形状回归；不得重新人工规避。
