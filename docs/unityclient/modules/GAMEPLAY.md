# 玩法大厅（Gameplay）迁移证据

> 当前门禁：G0-G3 passed；early user Play fix retest pending；G4-G6 pending。2026-08-27已在当前工作树重取G1原生Cocos证据、冻结输入指纹、复核G2并通过G3标准batch；首次早测白屏已修复资源水合缺口，等待用户复测，旧Runner、SHA与人工结果仍只能作历史线索。

> Steam范围更新（2026-08-20）：`function_id=7/8/11/12/18/19/25/26`（决战昆仑、血战到底、七日目标、好友赠送、体力领取、资源找回、成长基金、活跃基金）由 `gameplay.json: steamEnabled=false` 排除。当前Steam大厅为5项/8个控件；下文13项/16控件仅描述排除前的历史验收基线。

## 1. 本轮所有权

- 本模块拥有：HUD 玩法入口、`PopFirstClassBg + ActivityLayer` 大厅框架、Steam 5 项双列列表、裁剪、等级锁、红点显示、关闭/返回及5个目标路由的边界反馈。
- 本模块不拥有：13个入口点击后的独立业务页及其协议；尤其不迁移游历三界、封神列传、竞技场、决战昆仑、血战到底、法宝搜索、每日任务、七日目标、好友赠送、体力领取、资源找回、成长基金、活跃基金。
- `15/16/17` 玩法商店在当前 `function_dat.lua` 中均为 `page=0`，不属于大厅列表；支付、活动、基金、福利、竞技和社交业务继续排除。
- 当前卡片主体 `TaskBtn1/2` 的 CSB `touchEnabled=false`；Lua虽添加监听但未启用触摸，新鲜原生单击也未进入详情。因此卡片选择与 `Main.WanFaInfoUI` 当前玩家不可达，排除而不伪迁。
- 控件矩阵：`docs/unityclient/matrices/GAMEPLAY_CONTROLS.json`，Steam 当前8个真实控件，`workflowPolicyVersion=1`。

## 2. 当前启动与真实入口闭包

```text
src/main.lua
→ require("View.LogoScene")
→ LogoScene / GameScene / LGameLogic 登录选角闭包
→ /1001 登录、必要时 /1003 创角、/1004 选角进服
→ LUILogic 初始化 MainUI
→ csd/common/UImainLayer_new.csb
→ Layer/Main_UI/ButtonGroup1/btn_wanfa
→ MainUI.WanFaCallback
→ Utils:OpenFunction(EMID_WANFA=270, nil, true)
→ AppDef.FuncUI[270] = Main.WanFaEntranceUI, PopFirstClassLayer
→ PopFirstClassBg 加载 csd/shop/shop_bg.csb
→ WanFaEntranceUI 加载 csd/common/ActivityLayer.csb
```

- `btn_wanfa` 当前直接位于 `Layer/Main_UI`；`tankuang1/btn_wanfa` 是玩法商店子菜单，不是本入口。
- HUD 回调以 `noCheckOpen=true` 打开大厅；大厅卡片自己的参加按钮仍按各自功能等级显示/隐藏。
- 原生设计分辨率来自 `src/config.lua = 1334×750`；页面根节点设置 `AppDef.frameSize` 并执行 `ccui.Helper:doLayout`。

## 3. 大厅 View、事件与动态结构

### 3.1 `Main.WanFaEntranceUI`

- `Init`：加载 `csd/common/ActivityLayer.csb`；注册退出回调；向 `PopFirstClassBg` 设置关闭回调与标题 `GUITips.UI_Title_Activity="玩法"`；执行 `initData → UpdateRedDot → initControlUI → RegisterGuide`。
- `RegistMsgs/ProcessEvent`：当前消息表为空；大厅打开后不订阅刷新事件。
- `initData`：读取 `JsonConfig.m_functionConfig.getList()`，筛选 `function_id < 999 && ToBool(page)`。
- `initControlUI`：取 `Panel/ActivityBg/ActivityList` 模板并移除保留；创建垂直 `ccui.ListView`，锚点 `(0,0)`、位置 `(0,0)`、尺寸等于 `ActivityBg`、bounce=true、swallowTouches=false、itemsMargin=2、滚动条隐藏；13项生成7行双列，末项右卡隐藏。
- `updateItem`：写入名称、图标、等级锁、参加按钮、选择层、红点；`State/win` 恒隐藏。模板 `TaskBtn1/2` 的 `touchEnabled=false`，函数没有调用 `setTouchEnabled(true)`。
- 参加按钮：`enterFunction(functionId) → Utils:OpenFunction(functionId) → CloseUI`；目标页面属于独立模块，本轮只验证路由边界。
- `CloseUI/onExit`：删除大厅、注销竞技场/寻宝引导并销毁监听。

### 3.2 `Main.WanFaInfoUI` 不可达旧链

```text
不可达的卡片主体回调
→ LUILogicEvent.InitUI("Main.WanFaInfoUI", PopWindow, functionId)
→ csd/TaskPopupLayer.csb
→ QuestDialogUI/Panel 与 QuestDialogUI/bg/ListView/Btn_1
→ updateData 读取 LDataConstMgr.m_pFunctionLevelMap[functionId]
→ m_pFunctionLevelMap 从未由当前 JsonConfig 路径填充
→ data=nil 提前 return
```

- 即使内部调用该链，详情也因提前返回而保留默认占位且 `Btn_1` 无绑定；但当前玩家入口无法触发，旧截图不能作为本轮范围依据。
- Unity不得把该不可达旧链变成可点击新功能；若未来Cocos修复触摸，须由新的模块/范围变更重新冻结。
- 当前链无 Timeline、Imod、ANI 或独立特效调用。

## 4. 当前 13 项配置与路由边界

| id | 名称 | page | 等级 | 图标 | 目标所有者 |
|---:|---|---:|---:|---|---|
| 1 | 游历三界 | 1 | 26 | `ui_icon_doushenzhilu` | `WanFa.YouLiMainUI` |
| 3 | 封神列传 | 1 | 32 | `ui_main_icon_fengshenliezhuan` | `FengShenStory.FengShenStoryMainUI` |
| 6 | 竞技场 | 1 | 10 | `ui_icon_doushenzhilu` | `WanFa.KaPaiArenaUI` |
| 7 | 决战昆仑 | 1 | 34 | `ui_main_icon_juezhankunlun` | `JueZhanKunLun.KunLunJueZhanUI` |
| 8 | 血战到底 | 1 | 24 | `ui_main_icon_xuezhan` | `XueZhan.XueZhanMainUI` 特殊请求分支 |
| 9 | 法宝搜索 | 1 | 15 | `ui_main_icon_xunbao` | `WanFa.XunBaoMainUI` |
| 10 | 每日任务 | 1 | 13 | `ui_main_icon_renwu` | `Activity.TaskLayer` |
| 11 | 七日目标 | 1 | 13 | `ui_icon_qirihuodong` | `OperationalActivity.SevenDay` |
| 12 | 好友赠送 | 1 | 14 | `ui_main_icon_haoyousong` | `Social.FriendLayer` |
| 18 | 体力领取 | 3 | 1 | `ui_main_icon_lingtili` | 福利活动子页 |
| 19 | 资源找回 | 3 | 20 | `ui_icon_zhuangbeihuishou` | 福利活动子页 |
| 25 | 成长基金 | 3 | 1 | `ui_icon_tujianshuxing` | 基金/支付前置后续模块 |
| 26 | 活跃基金 | 3 | 1 | `ui_main_icon_renwu` | 基金/支付前置后续模块 |

配置源：`client/ProjectX/src/ConfigData/function_dat.lua`；运行时由 `JsonConfig.m_functionConfig` 读取。13项顺序按当前 Lua 数组顺序冻结。

## 5. 红点与 `/65` 所有权

- 大厅 `UpdateRedDot` 只读取 `Utils:GetRedDotState`：昆仑 `ID=501`、竞技场 `ID=512`、血战 `ID=522`、寻宝 `ID=527`。
- 昆仑红点由全局主界面所有者先请求 `/213 op=25`，再按 `LRedDotCheckMgr.WanFaRedDotCheck` 的 `pos/ceng/zhandou_num` 规则本地计算；大厅只读结果，不拥有或重发 `/213`。
- `/65` 查询由全局 `LRedDotCheckMgr` 负责：竞技场 `type=101`、血战 `type=51`、寻宝 `type=103`。大厅打开本身不再次发请求。
- 请求：`cmd:u16=65, op:u8=1, type:u16`。
- 响应/推送：`op:u8=1(local_test回显)或2(生产), type:u16, state:u8`；客户端 `DealRedPoint` 仅接受 op 1/2，并把 `state==1` 映射为显示。
- 服务端：`protocol.h PRO_Func_HotPoint=65`；`pack_deal.cpp cmdFun → FuncHotPointOption`；51进入 `CUserBloodFight::SendBFHotPointStatus`，101/103进入 `CMissionManager::SendQuestHotPointStatus`；`SendHotPointStatus` 写 `op=2`。未知type、空子系统、DB/配置失败可静默返回；`local_test=1` 权威返回 `op=1,state=0`。
- 共享所有权：Unity必须由现有 `Shared/HotPointController` 独占消息游标；Gameplay只消费对应状态，不能抢读或在打开大厅时重复发包。

## 6. CSB/资源/Transform 闭包

- 框架：`csd/shop/shop_bg.csb`，由 `View/Background/PopFirstClassBg.lua` 创建；标题 `玩法`，关闭按钮 `Popup/Btn_close`。
- 内容：`csd/common/ActivityLayer.csb` → `Panel/ActivityBg`；导入文档显示裁剪区，模板 `ActivityList` 包含 `TaskBtn1/2`。
- 卡片：`420×110`；图标 `88×88`；名称使用 `xiaokaiSJ2.ttf`；参加按钮 `120×55`；红点 `20×20`；选择底图默认隐藏。
- 不可达旧详情资源：`csd/TaskPopupLayer.csb`，只作源码闭包记录，不纳入当前可见/可达控件。
- 图标根：`res2/Icon/ui_main_icon/<icon>.png`；当前13项引用11个唯一文件（`ui_icon_doushenzhilu` 与 `ui_main_icon_renwu` 分别复用），Cocos与Unity副本逐文件 SHA-256 一致，资源类型保持静态Image。
- 运行根均设为 `AppDef.frameSize=1334×750` 并 `doLayout`；ActivityBg运行时承载垂直ListView，7行、行距2、顶部/底部裁剪由原生ListView决定；无安全区额外偏移、Timeline、Imod或动画。

## 7. Unity 当前实现与 G0 缺口

- 现有：`GameplayCatalog/Store/Presenter`、`GameplayController.lua.txt`、`BootstrapSceneBuilder` 中的 `shop_bg + ActivityLayer + TaskPopupLayer`、旧两图Runner。
- 缺口A：Unity `gameplay.json` 把15/16/17写为 `page=2`，`GameplayCatalog` 用 `Page != 0` 过滤，实际渲染16项，违反当前Cocos 13项。
- 缺口B：Unity `GameplayController.onClick()` 主动发 `/65` 101/51/103，违反当前Cocos“全局查询、大厅只读缓存”所有权。
- 缺口C：旧Runner只截列表/不可达详情并靠 `CompleteGameplayValidation`，没有16控件、锁定、滚动、红点、失败、生命周期和切号覆盖，不能作为G4-G6证据。
- 缺口D：Manifest仍引用旧截图与旧差异报告；它们只作历史线索，G1/G5必须生成新鲜证据。
- 在 G0/G1 通过前不修改上述 Unity 实现。

## 8. G0/G1 验收状态

- Git/dirty基线：`.local/unity-validation/gameplay-dirty-baseline.txt`。
- G0矩阵：首次冻结30项后被新鲜原生证据推翻；已改为16项真实可达控件。固定账号 `7200057/1000115`、隔离账号 `705213/1000006`、原生客户区 `1334×750`。
- G0中央门禁已通过：16控件、`workflowPolicyVersion=1`、3条源码证据路径均被接受。
- 当前G1已通过：Computer Use原生证据台账含10个唯一target；本工作树生成HUD、顶部、滚动、返回、重进、等级锁、切号后重启、断线、重连、空列表等当前`1334×750`证据，并冻结`cocosBaselineInputs`指纹。
- 证据清单：`.local/ui-fidelity/Gameplay/cocos/g1-20260802/G1_COCOS_EVIDENCE.md`；逐图身份、步骤、SHA、N/A裁定与finally恢复均已记录。
- 当前没有页签/分类，也没有玩家可达的卡片选择/详情；大厅打开不发送自有协议，请求失败状态以真实服务端断线/重连覆盖。
- 空态使用 `tools/unity-migration/Invoke-GameplayCocosFixture.ps1`，仅在模拟器副本把13个非零 `page` 置0；源/运行副本及运行时账号覆盖均已恢复。
- 操作台账当前 Failed/Blocked 24、Resolved 24、未解决0；`DIAGNOSTIC-USER1-HUD.png` 仅用于错误身份诊断，不纳入验收。

## 9. G2 迁移设计与只读数据合同

### 9.1 sourceAudit 四闭包

- 入口闭包：`main.lua → LogoScene → GameScene/LGameLogic → MainUI → btn_wanfa → EMID_WANFA=270 → WanFaEntranceUI → shop_bg + ActivityLayer` 已闭合；Unity入口固定 `GameplayPath → OnGameplayClicked → ShowGameplay`。
- 协议所有权：大厅打开、列表、滚动、锁定、关闭和13个路由边界均不拥有协议；`/65` 由 `Shared.HotPointController` 独占接包，昆仑 `/213 op=25` 也由全局主界面刷新并本地计算 function 7，二者均在大厅进入前稳定，大厅只消费缓存。G3删除 `GameplayController.onClick` 的三次主动查询和 pending 完成条件。
- 配置→资源闭包：权威ID顺序固定为 `1,3,6,7,8,9,10,11,12,18,19,25,26`；15/16/17必须 `page=0`。11个唯一图标在 Cocos与Unity均唯一存在且逐文件哈希相同；缺图标必须计数并保持安全态，不能临场占位。
- Transform闭包：根 `1334×750`；`ActivityBg=970×550`、clip=true；运行时纵向弹性ListView；模板行 `940×130`、首行偏移65、行距2；双卡 `420×110`，左右源位置254.364/705.564；图标 `88×88`；参加 `120×55`；红点 `20×20`。卡体 `touchEnabled=false`、参加按钮 `touchEnabled=true`；Unity不得创建详情或选择交互。

### 9.2 Unity实现约束

- `GameplayCatalog` 保持 `<999 && page!=0`，但配置必须精确收敛为13项并保持数组顺序；不按新增业务需求扩张。
- `GameplayPresenter` 删除 `TaskPopupLayer`、卡体Button、选择层状态与 `ShowDetail`；保留 Frame、裁剪ScrollRect、7行双列、锁定/参加、红点和关闭。
- 13个参加按钮都必须真实绑定并逐一点击；只记录 `id/name/owner` 路由边界与不可用反馈，不调用目标Controller、不发送子模块协议、不打开目标页。
- 空配置/缺资源/断线/重连/切号必须清空旧行、旧红点、旧pending与滚动位置；每次重进默认顶部。
- G3前场景合同已冻结为13个捕获状态、16控件、11条语义断言、7组源码合同；G4-G6只接受标准batch结果。

### 9.3 固定账号与无服务端夹具

- 合同：`shared-readonly + no-server-fixture`；适配器 `tools/unity-migration/Invoke-GameplayFixedAccountFixture.ps1`。
- 主账号：`7200057/1000115/T00057/60`；真实锁定账号：`7200260/1000119/T20260/1`；隔离账号：`705213/1000006/T67076/60`。
- 当前中央数据预检及G3收尾已通过：Setup、AssertSetup、AssertReloginHash、Restore、AssertRestored、Cleanup、AssertCleanup；最终重登录身份哈希 `d286b9c5453303dd732ae9ea0cb564fad988366d84dca89ab36d73cd1adaa0ea`，残留0。
- G3只在`.local/gameplay-server-validation`生成临时服务端配置并设置主/隔离账号等级与余额保护；受保护的`server/config/config`未修改，跟踪文件SHA-256保持`442BD0A705C45E223135D67B00D6007B1F4DAB6A3E502860B3440E7087C1992D`。
- 快照证据：`.local/ui-fidelity/Gameplay/unity/g5-20260802/gameplay-fixed-fixture-snapshot.json`。G2通过后仍必须由 `Run-UnityFixedAccountValidation.ps1 -Module Gameplay -DataPreflightOnly` 生成中央凭证，不能用本次手工预演代替。
- G2中央门禁已通过：入口、协议所有权、配置资源、运行时Transform四闭包完成；4个既有Unity缺口均以G3处理与源码证据登记。

## 10. G3 Unity实现与编辑器证据

- `gameplay.json` 已将15/16/17收敛为 `page=0`；运行目录严格只生成13项。
- `GameplayController` 删除大厅打开时的三次 `/65` 查询；共享红点消息仍由全局控制器独占，大厅只读 `GameplayStore` 缓存。
- `GameplayPresenter` 不再创建 `TaskPopupLayer`、选择态或详情交互；模板卡体运行时强制不可交互，仅13个真实 `EnterBtn` 绑定路由边界。
- 13个参加按钮在 Gameplay 验证模式下仅关闭大厅并报告目标所有者，不启动目标 Controller、不发送目标协议；非 Gameplay 模块验证的既有目标路由保持不变，作为回归面。
- 固定账号 Runner 已覆盖：主账号13项、1级账号3项可参加/10项等级锁、13个参加边界、滚动/返回/重进、空配置安全态、断线重连、隔离账号及最终切回主账号。
- 资源合同验证三个直接水合目录：`Resources/ProjectXStartup`、`Resources/GameplayIcons`与`res/res/UI/ui_login`，并单独验证运行时动态头像`Resources/RoleBust/5_touxiang.png`；同时从4份登录IR、`UImainLayer_new/UImain_cloudLayer/ChatLayer`三份主界面IR及`shop_bg/ActivityLayer`两份Gameplay IR递归解析全部图片与字体依赖，避免只按目录猜测而漏掉背景、九宫格、公共控件、字体及代码动态加载资源。
- G3标准batch已通过：13/13控件、11/11语义断言、Steam 5个入口/路由、等级锁、滚动/返回/重进、空配置、客户端重启、断线恢复及账号隔离均完成；固定账号精确恢复、重登录哈希一致、Fixture残留0。
- 当前证据：`.local/unity-validation/gameplay-g3-runtime-latest.json`、`.local/unity-validation/gameplay-fixed-account-runner-latest.json`、`.local/unity-validation/gameplay-fixed-account-data-preflight-latest.json`、`.local/unity-validation/gameplay-fixed-account-timings-latest.json`、`build/ui-migration/unity-gameplay-fixed-account.log`。
- G3已通过并按流程暂停；必须先取得本轮早期真人Play反馈并闭环，才允许进入G4。此轮早测不设置`manualPassed=true`，也不替代后续相关变更后的G6最终真人确认。
- 首次早测失败：普通Editor已进入`Login`且日志打印`Login UI shown`，但`res/res/UI/ui_login`下28个图片仍为Git LFS指针，Game视图白屏。现已将该根纳入水合合同并完成28/28水合；工具链、DataPreflight和G3标准batch复跑通过，仍须用户复测关闭此失败记录。证据：`.local/unity-validation/gameplay-early-user-play-latest.json`。
- 继续复查发现首次修复范围仍不完整：登录背景实际位于`ui_bg`，文字依赖`xiaokaiSJ2.ttf`，主界面与Gameplay框架还跨`Sliced/ui_common/Icon`等目录。中央Runner现从9份权威UI IR递归校验图片/字体；128个依赖已水合、指针0。Computer Use真实Editor Play已进入完整主界面并从HUD打开5项玩法大厅，用户复测仍保持`manualPassed=false`。证据：`.local/unity-validation/gameplay-early-play-repair-current.png`。
- 用户复核指出该截图仍有两个缺口：玩法框架外露出黑色Camera清屏、HUD角色头像为空。根因分别是`UiStack.Push(gameplayView)`错误停用了包含`Layer/Bg`的整个主界面根，而Cocos只隐藏`Layer/Main_UI`控件并保留底层场景；以及`LoadPlayerRoundPortrait`动态加载的`RoleBust/5_touxiang.png`不在UI IR静态资源闭包内，仍为LFS指针。当前修复保持`Layer/Bg`与云层激活、仅隐藏HUD控件，并把动态头像加入固定账号水合合同；G3批验证新增`gameplay-main-background-preserved`语义断言。
- 用户继续跨模块复测时，背包等既有界面只显示文字：当前工作树仍有3475个ProjectX图片/字体LFS指针（声明总量约180 MB）。这不是Prefab节点丢失，Git状态中Prefab/场景改动为0；根因是前两次只水合Gameplay可见入口闭包。现已水合`unityclient/Assets/ProjectX`全部3634个LFS跟踪资源、剩余指针0，并把该根提升为所有固定账号Runner的全局前置，防止后续模块再次把跨页缺图交给用户发现。

## 11. G4 固定账号逻辑验收

- 标准 batch 固定账号结果 `success=true`：16/16 真实控件、13个权威入口/路由边界、12/12 语义断言通过。
- 主账号 `7200057/1000115`、1级锁定账号 `7200260/1000119`、隔离账号 `705213/1000006`；覆盖滚动、13个参加按钮、10项等级锁、空配置、不可用反馈、断线/重连、重进/重启、切号隔离及切回主账号。
- 大厅不拥有业务子页协议；`/65` 继续由共享红点控制器独占，昆仑 `/213 op=25` 由主界面全局刷新后本地计算，大厅仅消费稳定缓存。
- `shared-readonly + no-server-fixture` 六段合同通过；恢复哈希 `9225585d40d2624b11aad0dc8c713a22afc641489307a68c5ea2e405cd3e0a5a`，变更数0、残留0。
- 证据：`.local/unity-validation/gameplay-fixed-account-latest.json`、`.local/unity-validation/gameplay-fixed-account-runner-latest.json`。

## 12. G5 双端视觉验收

- 当前 Cocos/Unity 原生客户区均为 `1334×750`，9/9状态完成并排、叠加、增强差异和人工验收；大厅状态 MAE `4.71–8.27`。
- 通过范围：HUD入口/关闭返回、列表顶部/底部滚动、13项顺序与资源、1级锁定、空配置、重启、断线、重连、裁剪、层级及昆仑红点。
- 批准一项时序差：重连 Cocos 原生帧早于异步 `/213 op=25` 稳定，Unity等待相同权威响应后截图；两端初始与重启稳定帧红点一致。
- 不可达 `TaskPopupLayer`、伪公告与系统Toast不再污染 Gameplay 稳定帧；未发现剩余错图、遮挡、文本截断或交互阻断。
- 证据：`.local/ui-fidelity/Gameplay/compare/g5-live-20260802/report.json`、`manual-acceptance.json`、`G5_VISUAL_ACCEPTANCE.md`。

## 13. 2026-08-27 当前工作树审计

- 中央规则根因已关闭：矩阵升级为hard-gate v3，8个真实按钮/滚动继续要求`realEntryClick=true`；空态、返回重进、客户端重启、网络恢复、账号隔离5个场景状态必须保持`realEntryClick=false`，并分别映射标准batch的`empty-failure`、`return-hud/reenter`、`restart`、`disconnected/reconnect`、`account-switch` capture state。禁止直接把状态项改成true。
- `Test-UnityMigrationHardGates.ps1 -Module Gameplay -Phase Preflight`通过，当前合同为13条目、8个直接控件、5个场景状态；中央工具链回归225项通过。
- `Test-UnityModuleG5Preflight.ps1 -Module Gameplay -RequireInputs`曾发现旧合同缺`cocosBaselineInputs`；当前已补齐入口/View/红点/配置/CSB/夹具输入，并在本工作树重新生成G1证据与基线，不复用E盘旧`.local`。
- 当前G1、G2、G3已串行通过；G3为当前工作树标准batch结果，13/13控件、11/11语义断言、精确恢复与残留0均有文件证据。不得引用旧两次BuildBatch、旧G5差异或旧`manualPassed=true`恢复完成态。
- 两次真实 `BootstrapSceneBuilder.BuildBatch` 均通过，SHA-256 同为 `BED14CC26A6E055C8C00B4B647E54D7B706B7D0C2651CFF9915D1165094CE4E3`。
- 上一条为2026-08-02历史结果，仅作诊断线索；当前收口顺序是早期真人Play→反馈闭环→G4→G5→G6。
- Cocos、Unity Editor、服务端、本地MySQL与 Computer Use 残留进程均在收口前清理；模块边界只含大厅与13个路由，不宣称任何子页完成。
- 当前审计证据：`.local/unity-validation/gameplay-operation-ledger.json`、`.local/unity-validation/gameplay-g6-docs-audit.json`；旧G6证据路径当前不存在。

## 14. Steam SQLite S5（2026-08-20）

- 证据：`.local/unity-validation/steam-sqlite-s5-gameplay-latest.json`，状态 `Passed`。
- 当前可交付大厅配置严格为`1/3/9/10`；竞技场`6`仍保留在产品范围，但因自身门禁为`G0 pending`以`migrationReady=false`暂时隐藏，大厅不得暴露不可用空壳；对应每日任务同步过滤。共享红点当前只展示寻宝`type=103`，竞技场正式迁完开放后再恢复`type=101`。血战入口`8`已排除，因此`type=51`不属于本轮范围，未被错误带回。
- SQLite/MySQL新隔离角色均执行两轮`/65 op=1`的`101/103`查询；运行期双方各47响应、重启各21响应，归属回包均为4字节`op=1,type,state=0`且逐字节一致，manifest单边协议0、结构差异0。
- 大厅继续只消费`Shared/HotPointController`缓存，打开大厅不重发协议、不修改服务器。数据库`mission/xunbao/blood_fight/save_data/hots`、角色等级/经验/货币和账号货币原始值一致，归属写入0。
- 中央工具链`131/131`；只删除隔离库`fxl_game_gameplay_s5_v1`，正式`fxl_game_local`及MySQL源码/驱动/构建/Schema/脚本/回归全部保留。S5下一模块为`YouLi`。
