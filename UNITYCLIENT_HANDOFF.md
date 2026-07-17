# UnityClient 当前工程交接

> 最后更新：2026-07-17 11:02
> 仓库：`E:\neiwang_kapai\Game`
> Unity 工程：`E:\neiwang_kapai\Game\unityclient`
> 原客户端：`E:\neiwang_kapai\Game\client\ProjectX`
> 用途：新 Codex 对话先完整读取本文件和根目录 `AGENTS.md`，再继续 Unity 迁移。
> 后续模块化路线与完成门禁：`UNITYCLIENT_MIGRATION_PLAN.md`。

## 2026-07-17 11:02 Mail Store 第一阶段收口

- 已完成 `/128 MSG_SERVER_XINSHI` 三方取证和 Unity 迁移：`MailStore + MailPresenter + MailController.lua`，覆盖邮件列表、本地已读、附件展示、单封领取和领取后服务端持久化复查。
- 主界面真实入口 `Layer/Main_UI/ButtonGroup7/btn_mail` 已接入；页面复用真实 `MailLayer.prefab`、`VirtualList`、`ResourceService`、`RewardStore/RewardPresenter`、Toast 和返回栈。
- 服务端仅在 `local_test=1` 下补齐本地 `/128 op=2` 直查、`xin_shi` 最小字段和 `/13 op=54` 隔离邮件注入；线上长连接服列表路径保持不变。
- 隔离角色 `userId=717026` 实测通过：注入邮件 → `/128 op=2` 列表 → 选中并标记已读 → 显示 `Unity mail validation` 正文和 `10点贵族经验` 附件 → `/128 op=3` 单封领取 → RewardPresenter 1 项 → 再次 `/128 op=2` 确认邮件移除。
- Unity MCP 已用于实例连接、项目/Editor 状态读取、场景重建、编译 Console 和验证菜单执行；最终 C# 编译为 `0 error / 0 warning`。
- GameView 验收固定为 `1334×750`；`bootstrap-mail-detail.png` 和 `bootstrap-mail.png` 均确认像素尺寸为 `1334×750`。修复了透明正文底板、Cocos ScrollView 正文裁剪、附件行裁剪、未关闭详情浮层、恢复主界面后错误弹窗残留及截图目录未先创建等问题。
- 结果文件 `build/ui-migration/bootstrap-app-result.json`：`success=true`；最终状态为 `COMPLETE: /128 list -> MailStore/read/attachments -> claim id=9 -> RewardStore/RewardPresenter (1) -> persisted removal`。
- 本阶段没有改写 `MailLayer.prefab`；未 stage、commit、push。按完整可玩客户端业务加权口径约完成 `19%`，静态 Prefab 仍为 `356/356`。

下一迁移建议：进入 `Shop Store`，先做商品列表只读、限购/刷新时间与货币显示；购买确认和单次购买继续使用隔离角色。一键领取、邮件删除和邮件红点留在 C4 第二阶段。

## 2026-07-16 23:45 HeroEquip/FaBao Store 阶段收口

- 已按服务端、旧客户端和真实回包三方取证完成共用 `/319 PET_EQUIP_OPERATE`：装备列表 `op=1`、装备增量 `op=16`、法宝列表 `op=17`、法宝增量 `op=22`；列表分包与装备/法宝字段均进入独立 Store，UI 不直接持有网络字节流。
- 新增 `HeroEquipmentStore/FaBaoStore + EquipmentCatalog + HeroEquipmentPresenter + EquipmentController`，复用 `zhuangbeibeibao/zhuangbeiInfo` 真实迁移 Prefab；装备与法宝共用列表、详情、图标、穿戴/卸下入口已接通。
- 已同步 `equip.json/fabao.json` 与 44 张 `petequip_*.png`；真实回归中装备、法宝各 1 件，资源缺失计数为 `0`。
- 隔离角色 `userId=7162311` 真实完成：装备穿戴到阵位 1 → 强化 `0→2` → 卸下；法宝穿戴到阵位 1/槽位 5 → 卸下；最终 Store、列表、详情均恢复。为本地服 60 级隔离角色补了仅 `local_test=1` 生效的装备槽/系统开放旁路，线上路径不变。
- Unity 已实际执行场景重建、C# 编译和多轮 batchMode PlayMode；装备/法宝目标、旧神将/阵容、任务回归均成功，UI 转换测试 `10/10`，`git diff --check` 通过。
- 本会话没有暴露 Unity MCP 工具；batchMode 不能替代 GameView 人工视觉/点击 QA，因此视觉门禁继续保留，不宣称已通过。
- 按“完整可玩 Unity 客户端”的业务加权口径，当前约完成 `18%`、剩余约 `82%`。静态 UI Prefab 转换仍为 `356/356`，该数字不等于功能迁移完成度。
- 阶段结束已关闭 Unity、`kapai.exe`、workspace-local MySQL，并把 Unity MCP 配置恢复为 `enabled = false`；未 stage、commit、push。

下一迁移建议：`Mail Store`（列表/已读/附件/领取），并继续复用 Reward、VirtualList、ServerTime、红点与 Loading/Toast；装备深度培养（法宝强化/炼化、精炼/觉醒/神铸、合成/回收）仍归 C3 后续批次。

## 2026-07-16 23:11 Resource/ServerTime/Loading/Toast 阶段收口

- 新增 `ResourceService`：统一 Sprite 缓存、运行时 Texture→Sprite、释放、缺图占位与统计；`BagPresenter/RewardPresenter` 已移除各自缓存，统一走 `ItemIcons/equip{pic} → MonsterBust/{pic} → head_defult`，并预留 `MonsterBust/{pic}_tou` 神将头像入口。
- 新增 `ServerTimeService + Time.ServerTimeController`：按旧客户端和服务端真实格式发送 `/206 + byte 9`，解析 `todaySeconds + unixSeconds`；倒计时可使用权威 `UnixSeconds/TodaySeconds/RemainingUntil`，切号时重置。
- 新增 keyed `LoadingPresenter`，复用 `common/jiemianjiazai.prefab`，支持多请求、自动超时、连接/重连/自动重连接入；新增队列式 `ToastPresenter`，向 C#/xLua 暴露统一 `ShowToast`。
- `Bootstrap.unity` 已重建并包含 Loading Prefab。Unity 编译成功，仅保留原有 `CocosNodeMetadata.tag` warning。
- 真实回归全部退出码 `0`：任务只读、非空背包 2 组、隔离角色任务领奖 1 项、神将列表 1 名；四轮 `/206` 均同步成功，四份日志严重异常 `0`。
- UI 转换测试 `10/10`、`git diff --check` 通过；未 stage、commit、push。
- 当前会话仍无 Unity MCP 调用工具，batchMode 仍不能替代 GameView 截图与人工点击；视觉 QA 门禁保留。

下一迁移：`HeroEquip/FaBao Store`。已确认共用 `/319 PET_EQUIP_OPERATE`：装备列表 `op=1`、法宝列表 `op=17`；下一步继续取证字段并用真实回包确认，再接现有 `HeroStore/BagStore/RewardModel/ResourceService/Loading/Toast`。

## 2026-07-16 22:53 Player/Bag/Reward/阵容阶段收口

- `PlayerStore + CurrencyStore + MainHudPresenter` 已接权威 `/1004` 快照、`/18` 增量、`/226` 升级与 `/321 op=1` 体力；主界面姓名、等级、战力、金币、元宝、体力由 Store 驱动。真实结果：`gold=1000369 premium=100007 stamina=100`。
- `BagStore` 已成为背包唯一状态源；Lua 不再保存 `itemsBySlot`，只负责 `/8、/15` 字段解析与业务发包。真实 `/8 → /15 op=6 → 注入3201 → 使用 → 删除` 回归通过。
- 新增统一 `RewardRecord/RewardStore/RewardPresenter`，复用 `common/tanchuangjiangli.prefab`；任务 `/37 op=3` 奖励不再只写状态文字。新隔离角色真实领奖、弹窗渲染、任务 `state=2` 持久化通过。
- 新增 `HeroStore + FormationStore + HeroPresenter + HeroController`；`btn_zhenrong → /24 op=1 → /48 op=1` 已渲染 `yingxiongListLayer + yingxiongInfoLayer` 的神将列表与详情。
- 单人阵容实际协议 `/48 op=4` 只支持上阵/替换，不支持空卸下。隔离角色 `hero 57` 已完成阵位 `1→2→1`，两次操作均收到服务端主动 `/48 op=1` 权威快照，最终恢复原态。
- Unity 最终模块回归：Player HUD、背包使用、任务领奖、阵位变更全部退出码 `0`；五份关键日志严重异常 `0`；UI 转换测试 `10/10`；`git diff --check` 通过。
- 当前会话仍无可调用 Unity MCP 工具，batchMode 未生成有效 GameView 截图；功能与协议门禁已完成，但上述新增页面仍保留图形 Editor 人工视觉 QA 门禁。
- 阶段结束必须关闭 Unity、`kapai.exe`、workspace-local MySQL；Cocos 本阶段未启动。未 stage、commit、push。

下一批建议按底层优先：先抽出 `ResourceService`（统一 ItemIcons/MonsterBust/神将头像）、服务器时间与通用 Loading/Toast，再迁移神将装备/法宝 Store；之后进入邮件、商城、好友/帮派，最后活动与商业化。

## 2026-07-16 21:57 增量进展

- 已完成 `AppLaunchOptions/AppState`、结构化 `ClientLog`、`LuaErrorBoundary`、`ProtocolRegistry/RequestContext`、`ConfigService/TaskStore`、固定高度 `VirtualList<T>`。
- 通用错误弹窗复用 `MessageBoxLayer.prefab`，已在任务自动化中完成显示/关闭自检。
- 任务主入口已接通：`Layer/Main_UI/ButtonGroup5/btn_renwu` → Lua `TaskController` → `/37 op=1 type=1` → C# `TaskStore/TaskPresenter` → `huodong_bg + RenwuLayer`。
- 服务端与旧客户端格式已对齐：回包为 `op + taskType + count + [id, progress, state]`；隔离用户 `760018` 收到并渲染 8 条真实日常任务。
- Unity 结果：`COMPLETE: main task button -> /37 op=1 type=1 -> TaskStore -> VirtualList (8 tasks)`；页面入栈、Esc 返回、请求队列清空均通过。
- 回归：隔离用户 `730132` 非空背包仍为 2 组；设置音量持久化、Esc、切换账号断网返回登录均通过。
- 三份 Unity 日志均无 C# 编译错误、LuaException、NullReferenceException、MissingReferenceException；UI 转换测试 10/10。
- batchMode 仍未生成可靠 GameView 截图，未宣称任务页视觉人工 QA 通过。
- 下一批建议：任务 `/39` 增量与隔离角色 `/37 op=3` 领奖，再进入主界面 Store/红点与阵容只读列表。

## 2026-07-16 20:35 增量进展

- 已执行 `BootstrapSceneBuilder.BuildBatch`，生成 `Assets/ProjectX/Scenes/Bootstrap.unity`。
- Build Settings 已将 `Bootstrap.unity` 设为启用的 Build Index 0；`FirstPlayableLoop.unity` 保留但禁用。
- 新增独立 `BootstrapAppRunner`，正式 `ProjectXApp` 已通过真实本地服登录、选角、主界面、背包 `/8` 闭环，不再只依赖 `FirstPlayableLoopBridge` 证明架构。
- 修复自动重连只执行一次的问题；当前最多 3 次，退避为 `1.2s → 4.8s → 19.2s`。停服后前两次连接被拒绝，服务端恢复后第 3 次成功重新登录并再次完成背包 `/8`。
- 修复退出 PlayMode 时已销毁 `CocosUiBinding` 被 `UiStack.Clear()` 再次访问导致的 `MissingReferenceException`；退出回归无编译或运行时异常。
- 本阶段结束后 Unity、Cocos、MySQL、`kapai.exe` 均已关闭，3306/8711 无监听，`.codex/config.toml` 中 Unity MCP 已恢复为 `enabled = false`。
- 尚待：手动 Reconnect 按钮和 Esc 返回的动态验收；随后进入真实背包界面、数据解析与列表渲染。

## 2026-07-16 20:52 增量进展

- 手动 Reconnect 动态验收已完成：测试模式关闭自动重连，停服后确认无自动尝试；服务恢复并触发一次与按钮相同的 `ProjectXApp.Reconnect()` 后，重新连接、选角并再次完成背包 `/8`。
- Esc 返回动态验收已完成：真实背包加入 `UiStack` 后调用与键盘相同的 `HandleBack()`，成功关闭背包并恢复主界面。
- `Bootstrap.unity` 已装配隐藏的 `zhujue/beibao.prefab`；背包按钮不再只判定回包，而会真正打开迁移后的背包界面。
- Lua `BagController` 已按旧协议解析 `count + [slot,itemId,num]`，复用原 `item_dat.lua` 做名称、描述、品质、图片号、排序映射。
- 新增 `BagPresenter`：复用原五格 `ItemCell` 模板生成垂直滚动列表，支持数量显示、条目选择和详情区刷新。
- 新增 `-projectXUserId=<id>` 本地覆盖；默认仍为 userId 1。使用现有隔离角色 `userId=730132 / roleId=1000006` 完成真实非空背包回归，收到并渲染 2 组物品。
- 修复 Unity 2022.3 内置字体兼容：运行时数量标签使用 `LegacyRuntime.ttf`，不再使用已失效的 `Arial.ttf`。
- 验证结果：非空背包正式回归成功；手动重连正式回归成功；相关日志无 C# 编译错误、LuaException、MissingReferenceException、NullReferenceException；UI 转换 Python 测试 10/10。
- 视觉边界：batchMode 无法产出 GameView 背包截图；图形 Editor 在本机停留于无窗口启动器层，因此本轮未宣称视觉截图验收通过。下一步应在可连接的 Unity MCP/正常图形 Editor 中做截图与人工点击 QA，并补真实物品图标加载、使用按钮业务和增量背包更新协议。
- 阶段结束后 Unity、Cocos、MySQL、`kapai.exe` 均已关闭，3306/8711 无监听，Unity MCP 仍为 `enabled = false`。

## 2026-07-16 21:02 增量进展

- 已迁移 529 张原物品图标到 `Resources/ItemIcons`，共 2.17 MB；`BagPresenter` 按 `item_dat.pic -> equip{pic}` 运行时加载并缓存 Sprite。
- 原资源缺少 `item/equip908.png`，对应 `胡喜媚神魂 itemId=2439`；增加按 picture 回退 `MonsterBust/{pic}` 的规则，并迁移 146 张角色立绘，共 5.01 MB。该规则用于神魂等原物品图缺失项。
- 背包详情区与五格列表均已绑定真实图标，正式回归门禁会在任何物品图无法解析时失败。
- 已实现 `PRO_PACKAGE_UPDATE/15`：支持整理后的全量刷新，以及新增/更新/删除物品的单格增量解析和重新排序渲染。
- 自动回归使用隔离角色发送安全的 `/15 op=6` 整理请求，不消耗物品；验证序列为 `/8` 初始解析 → 2 组物品渲染 → `/15` 全量刷新 → 2 组物品重绘。
- 使用按钮已按旧客户端协议接线：`/15 op=1 + slot + num=1 + target=0`。仅 `use_type > 0` 的配置显示按钮；自动回归不点击，尚未宣称真实消耗与奖励表现验收通过。
- 最新结果：`COMPLETE: package/8 + package-update/15 sort -> rendered bag UI (2 stacks)`；两轮渲染均为 `0 missing icons`。

## 2026-07-16 21:13 增量进展

- 已完成真实道具使用闭环。新增仅由 `-projectXUseItemValidation` 启用的自动验收链：`/8` 背包 → `/15 op=6` 整理 → 本地测试 `/13 op=50` 注入 `3201 × 1` → `/15` 增量新增 → 复用使用按钮 `onUse` 路径发送 `/15 op=1` → `/15` 增量删除。
- `3201` 为“10点贵族经验”；服务端配置链 `drop_matching 83201 -> reward 60015 × 10` 已核对，正式 `NoLockUseItem` 会先发奖再删除背包物品。
- 使用全新隔离用户 `760018` 完成创角和验收，不修改默认 userId 1。为支持多个一次性本地角色，自动创角名改为不超过服务端 6 字符限制的 `U%05d`。
- Unity 批处理结果：`COMPLETE: package/8 -> update/15 sort -> local add 3201 -> use-item request -> fixed reward 60015 x10 -> update/15 consume`；新增时 1 组、消耗后 0 组，均为 `0 missing icons`，Esc/返回栈门禁通过。
- 随后用同一用户重新登录回归，背包仍为 `0 stacks`，确认消耗结果已持久化；UI 转换 Python 测试 `10/10` 通过。
- 视觉边界不变：batchMode 仍不能可靠产出 GameView 截图，图形 Editor 在本机无可用窗口，因此未宣称截图或人工点击视觉 QA 通过。

## 2026-07-16 21:25 增量进展

- 已迁移主界面“系统设置”入口：`Layer/Main_UI/ButtonGroup7/btn_xitong` → Lua `SettingsController` → C# `SettingsPresenter` → `zhujue/SystemLayer.prefab`。
- `BootstrapSceneBuilder` 已将 `SystemLayer` 装配为隐藏页面并重新生成 `Bootstrap.unity`；Unity 编译、场景保存和 Build Index 0 重建成功。
- 音乐/音效开关及滑杆已接入，按原客户端语义支持静音、恢复和 `0~1` 音量，使用 `PlayerPrefs` 持久化；批处理写入 `0.35/0.65`、读取校验后恢复原值。
- 设置页显示本地角色、等级和服务器信息；公告、兑换码在未迁移前给出明确状态提示，不伪造功能完成。
- “切换账号”已完成真实行为：断开当前网络、清空业务 UI 栈并恢复登录界面。
- 联合门禁顺序：真实登录 → 非空背包 `/8 + /15` → Esc 返回主界面 → 系统设置打开 → 音量持久化 → Esc 返回 → 再次打开设置 → 切换账号 → 断网登录态。
- 最终结果：`COMPLETE: settings account switch -> network disconnected -> login UI restored`；日志无 C# 编译错误、`LuaException`、`NullReferenceException` 或 `MissingReferenceException`；UI 转换测试 `10/10`。
- 图形截图/人工点击视觉 QA 仍受本机无可用图形 Editor 窗口限制；下一业务候选为任务或阵容系统。

## 2026-07-16 21:30 会话收口

### 当前任务

继续把旧 Cocos2d-x + Lua 客户端按主界面高频系统逐个迁移到 Unity。固定路线为：迁移后的真实 uGUI Prefab → C# 通用基础设施/Presenter/网络 → xLua 业务控制器 → 原 C++ 服务端协议 → Unity 批处理 PlayMode 门禁。不是一次性重写全部客户端。

### 已完成

- 356 个 Cocos Studio UI Prefab、约 19,517 个节点已完成静态迁移；UI 转换测试最后为 `10/10`。
- 正式 `Bootstrap.unity` 已生成并设为 Build Index 0；正式 App、LuaRuntime、网络层、协议分发、UI Router/Stack 已通过运行验收。
- 登录、无角色创角、选角、自动/手动重连、Esc 返回已完成。
- 真实背包已覆盖 `/8` 全量、`/15` 整理及单格增删改、真实图标/立绘回退、详情、使用按钮和真实消耗持久化。
- 系统设置已覆盖音乐/音效开关与音量持久化、Esc 返回、切换账号断网并恢复登录 UI。
- 最后联合结果：`COMPLETE: settings account switch -> network disconnected -> login UI restored`。
- 阶段结束时 Unity/Cocos/`kapai.exe`/workspace-local MySQL 均已关闭，`3306/8711` 无监听；Unity MCP 为 `enabled = false`；未 stage、commit、push。

### 当前卡点

没有代码或协议硬阻塞。唯一未完成的是图形视觉 QA：batchMode 无法可靠生成 GameView 截图，本机图形 Editor 曾无可用窗口，当前会话也没有可调用的 Unity MCP 工具。因此不能宣称背包和设置页截图/人工点击已通过；该限制不阻塞继续迁移其他业务系统。

### 下一步计划

1. 优先迁移“任务”系统：先核对 `btn_renwu`、`TaskPopupLayer/TaskAcceptLayer/huodong/RenwuLayer`、原客户端数据管理器，以及服务端 `/37、/39、/49、/89` 的真实格式。
2. 旧客户端 `Reqtasklist()` 与服务端当前 `/37` 可能存在版本差异；必须依据服务端实现和真实回包，禁止猜 op 或字段。
3. 先做只读任务列表闭环：主界面入口 → Lua → 协议 → 解析 → 真实 Prefab → Esc 返回 → 批处理门禁。
4. 奖励领取使用隔离角色单独验证；不得消耗默认 userId 1 的状态。
5. 若任务协议无法用证据对齐，立即切换“阵容”：`btn_zhenrong`，Prefab 为 `yingxiongListLayer/yingxiongjueseLayer`，协议从 `/24、/25、/51、/69、/70` 取证。
6. 图形 Editor/Unity MCP 恢复可用后，再集中补背包和设置页截图及人工点击 QA。

### 绝对不要再踩

- 用户授权 Codex 自主规划、连续推进，只需最终结果；同一命令、编译、启动或阻塞持续 **30 秒**，必须立即告知用户状态和处理方案，禁止静默等待。
- 不要重做 356 个已迁移 Prefab；正式业务不能用临时 IMGUI 冒充。
- 静态阅读/修改不启动 Unity、MySQL 或服务端；联调只启动必需进程，Unity 与 Cocos 两套客户端禁止同时常驻。
- 不要把 batchMode 当视觉验收；没有真实窗口/截图证据就明确记录未完成。
- 不要猜协议、奖励或字段；版本不一致时以服务端实现、原客户端收发和真实回包为准。
- 消耗、注入、奖励、领取必须使用隔离角色；固定创角名 `Unity01` 会冲突且角色名最多 6 字符，继续使用 `U%05d`。
- 背包槽位服务端从 0 开始、Lua/UI 从 1 开始，发送使用协议必须 `slot - 1`。
- 物品图标不能只查 `equip{pic}`；缺图项继续回退 `MonsterBust/{pic}`，并保留 `MissingIconCount` 门禁。
- Presenter 直接保存 `view.Binding`；不要从 inactive 子节点用 `GetComponentInParent<CocosUiBinding>()` 反查，曾因此空引用。
- Lua/C# 按钮入口必须捕获异常并进入 `ProjectXApp.Fail`，否则 Runner 会停留在旧 COMPLETE 状态并误判。
- 自动化修改 PlayerPrefs 后必须恢复用户原值。
- 不要让 smoke 与 Unity 客户端并发占用同一角色会话。
- 阶段结束关闭 Unity、`kapai.exe`、workspace-local MySQL，并把 Unity MCP 恢复为 disabled。
- 当前工作树包含用户历史修改及大量未跟踪迁移成果；禁止 `git reset --hard`、`git clean`、覆盖式 checkout，禁止擅自 stage/commit/push。

---

## 1. 一句话结论

Unity 工程已经完成 **356 个 Cocos Studio UI Prefab 的静态迁移**，并跑通第一条真实的 **C# + Lua + 本地游戏服** 验证闭环。正式 `Bootstrap.unity` 已生成并设为 Build Index 0，`ProjectXApp + GameServices + AppConfig + NetworkService + UiStack` 已完成运行验收；真实背包现已覆盖全量读取、整理刷新、增量新增/删除、图标渲染和可用道具消耗。

```text
登录界面
  → Unity 登录按钮进入 Lua
  → PRO_USER_LOGIN/1001
  → PRO_SELECT_ROLE/1004（无角色时支持 PRO_CREATE_ROLE/1003）
  → 登录层关闭、主界面激活
  → Unity 背包按钮进入 Lua
  → PRO_ROLE_PACKAGE/8 回包
  → COMPLETE
```

这证明“**Unity/uGUI + C# 基础设施 + Lua 业务与事件 + 原服务端协议**”路线可行，但目前只迁移了验证闭环和正式启动骨架，不是完整可游玩的 Unity 客户端。

---

## 2. 当前真实状态

| 项目 | 状态 |
|---|---|
| Unity | `2022.3.62f3c1` |
| 设计分辨率 | `1334 × 750` |
| Cocos UI Prefab | 356 个 |
| 已转换节点 | 19,517 个 |
| Sprite 组件 | 1,512 个 |
| 九宫格变体 | 673 个 |
| Text | 6,138 个 |
| Sprite 绑定 | 11,256 个 |
| UI 全量结构校验 | 0 错误 |
| UI 转换 Python 测试 | 10/10 通过 |
| Unity 场景 | 2 个：预览场景、首闭环场景 |
| ProjectX C# 源码 | 17 个（运行时 14 个、Editor 3 个） |
| 已迁移 Lua 业务 | 6 个模块化脚本（Bootstrap、Protocol、Login×3、Bag） |
| 原客户端 Lua | 约 729 个文件，绝大多数尚未迁移 |
| 首闭环 Editor 回归 | 通过 |
| Windows/Android 正式包 | 未验证 |
| IL2CPP/AOT | 未验证 |
| 正式 App 骨架 | C# 与 Lua 适配代码已落地，Unity 编译通过 |
| 正式 Bootstrap 场景 | 未生成；`Assets/ProjectX/Scenes/Bootstrap.unity` 当前不存在 |
| Build Settings | 仍只有默认 `Assets/Scenes/SampleScene.unity` |
| 运行时生命周期 | 一套服务端、Cocos/Unity 两套客户端按任务选择，禁止同时常驻 |
| 下一任务 Unity MCP | 项目配置已预启用，Unity Editor 仍保持关闭，由新任务按需启动 |
| Timeline/粒子/复杂列表行为 | 未完整迁移 |

重要判断：

- 已证明架构可行，可以沿该分层继续迁移。
- `BootstrapSceneBuilder` 已实现，但目标任务在执行场景生成菜单前中断；不能宣称正式场景或 Build Settings 已完成。
- 当前成功证据仅覆盖 Unity Editor + Windows 本地测试服。
- 不要把验证脚本当作最终登录框架，也不要宣称完整客户端或 Android 已完成。

---

## 3. 当前技术分层

| 层 | 当前职责 | 主要位置 |
|---|---|---|
| Unity/uGUI | 展示迁移后的 Prefab、Button 事件入口 | `unityclient/Assets/ProjectX/res/csd/Prefabs/` |
| C# App/Core | 正式入口、服务容器、本地配置、生命周期 | `Assets/ProjectX/src/Core/` |
| C# UI 桥 | 按原 Cocos 路径查找节点、切换界面、把点击转给 Lua | `Assets/ProjectX/src/UI/Migration/`、`LuaRuntime/` |
| C# 网络层 | TCP 生命周期、旧包头、收发队列、二进制读写、连接状态与重连 | `Assets/ProjectX/src/Network/` |
| Lua | 登录/创角/选角状态机、协议发送、回包分发、点击业务 | `Assets/ProjectX/Resources/Lua/` |
| xLua | C# 与 Lua 双向调用 | `Assets/XLua/`、`Assets/Plugins/` |
| 原游戏服 | 保持原 C++ 协议和业务逻辑 | `server/` |

建议长期保持：

```text
C#：引擎、资源、网络、平台、生命周期、通用 UI 基础设施
Lua：界面业务、协议业务、活动逻辑、点击回调、可热更内容
```

不要逐字翻译旧 Cocos API。应保留 Lua 的业务意图，由 C# 适配 Unity/uGUI。

---

## 4. 关键目录与文件

```text
D:\neiwang_kapai\
├─ UNITYCLIENT_HANDOFF.md                         # 本交接文件
├─ AGENTS.md                                      # 项目强制规则
├─ LOCAL_RUN.md                                   # 本地数据库/服务端运行手册
├─ unityclient\                                   # Unity 工程
│  ├─ Assets\ProjectX\Scenes\
│  │  ├─ UIMigrationPreview.unity                 # 代表 UI 预览
│  │  └─ FirstPlayableLoop.unity                  # 登录闭环验证场景
│  ├─ Assets\ProjectX\Resources\Lua\
│  │  ├─ Bootstrap.txt                            # Lua 启动与控制器分发
│  │  ├─ Protocol.lua.txt                         # 当前协议号与消息构造入口
│  │  ├─ Login\                                  # LoginController/Protocol/View
│  │  └─ Bag\BagController.lua.txt               # 背包闭环控制器
│  ├─ Assets\ProjectX\src\Editor\
│  │  ├─ CocosUiImporter.cs                       # Prefab 导入/校验
│  │  └─ FirstPlayableLoopRunner.cs               # 自动建场景、Play、判定结果
│  │  └─ BootstrapSceneBuilder.cs                 # 正式场景生成器（尚未执行）
│  ├─ Assets\ProjectX\src\Core\
│  │  ├─ AppConfig.cs                             # 本地地址、超时和重连参数
│  │  ├─ GameServices.cs                          # Lua/网络/协议/UI 生命周期容器
│  │  └─ ProjectXApp.cs                           # 正式 MonoBehaviour 入口与 Lua Bridge
│  ├─ Assets\ProjectX\src\LuaRuntime\
│  │  ├─ LuaRuntimeService.cs                     # xLua 生命周期和 Resources 模块加载
│  │  └─ FirstPlayableLoopBridge.cs               # 当前场景装配与回归状态桥
│  ├─ Assets\ProjectX\src\Network\
│  │  ├─ LegacyTcpClient.cs                       # TCP 连接、接收队列
│  │  └─ LegacyTcpMessage.cs                      # 旧协议二进制读写
│  │  ├─ NetworkService.cs                        # 网络生命周期服务
│  │  └─ ProtocolDispatcher.cs                    # 协议号注册与统一分发
│  ├─ Assets\ProjectX\src\UI\
│  │  ├─ UiRouter.cs                              # 按迁移源定位界面
│  │  └─ CocosUiView.cs                           # 显隐、路径查找和事件绑定
│  │  └─ UiStack.cs                               # 根界面、Push/Pop、返回栈
│  ├─ Assets\ProjectX\src\UI\Migration\
│  │  ├─ CocosUiBinding.cs                        # 原 Cocos 路径查询
│  │  └─ CocosNodeMetadata.cs                     # 节点迁移元数据
│  ├─ Assets\ProjectX\res\csd\Prefabs\          # 356 个生成 Prefab
│  ├─ Assets\XLua\                               # xLua C# 源码
│  ├─ Assets\Plugins\                            # xLua 原生库
│  ├─ Packages\manifest.json                     # 包依赖，含 Unity MCP
│  └─ ProjectSettings\ProjectVersion.txt
├─ tools\ui_migration\                            # CSD/CSB/PLIST 转换工具
├─ tools\local\                                   # 本地服启动、构建、烟测脚本
├─ build\ui-migration\                            # 验证报告/截图；被 gitignore 忽略
└─ client\ProjectX\src\                           # 原 Cocos Lua 业务源码
```

### xLua 版本说明

当前 vendored 包的 `Assets/XLua/README.md` 和 `CHANGELOG.txt` 标记为 **v2.1.15**。此前下载目录可能来自更高版本发行包，但后续对外说明应以仓库内文件为准，不要未经核验写成 v2.1.16。

当前已带 Windows x86/x64、Android ARMv7/ARM64/x86、iOS、WSA、WebGL 等原生插件；只验证了 Windows Unity Editor，不等于其他平台已通过。

---

## 5. 首个验证闭环实现

### 5.1 场景初始状态

`FirstPlayableLoopRunner` 每次运行会重新生成 `FirstPlayableLoop.unity`：

- 激活 `Login/LoginBgLayer.prefab`。
- 激活 `Login/loginLayer.prefab`。
- 实例化但隐藏 `common/UImainLayer_new.prefab`。
- 创建 `Canvas + CanvasScaler + EventSystem`。

所以游戏从登录界面开始，不允许直接显示主界面。

### 5.2 登录事件

登录按钮使用真实迁移路径：

```text
Layer/Login/Btn_Login
```

调用链：

```text
Unity Button.onClick
→ FirstPlayableLoopBridge.HandleLoginClick()
→ Lua OnLoginClicked()
→ Bridge:Connect("127.0.0.1", 8711)
→ Lua OnConnected()
→ PRO_USER_LOGIN/1001
```

### 5.3 角色流程

Lua 收到 `1001`：

- 已有角色：发送 `PRO_SELECT_ROLE/1004`。
- 没有角色：发送 `PRO_CREATE_ROLE/1003`，成功后再发送 `1004`。
- `1004` 成功后关闭登录背景和登录面板，激活主界面。

本次最终干净回归使用已有角色 `roleId=1000005`，因此实际覆盖的是选角路径；创角协议代码已写入，但创角 UI 和人工路径尚未单独验收。

### 5.4 背包事件

背包按钮路径：

```text
Layer/Main_UI/ButtonGroup1/btn_Bag
```

调用链：

```text
Unity Button.onClick
→ Lua OnBagClicked()
→ PRO_ROLE_PACKAGE/8
→ Lua OnPacket(8)
→ COMPLETE
```

### 5.5 自动点击说明

当前 Lua 通过 Bridge 类型区分人工运行和无人值守回归：

```lua
LoginView.show(Bridge:IsAutomation())
LoginView.showMain(Bridge:IsAutomation())
```

`FirstPlayableLoopBridge:IsAutomation()` 返回 `true`，绑定后下一帧自动触发；`ProjectXApp:IsAutomation()` 返回 `false`，正式入口等待人工点击。不要再通过手改 Lua 的 `true/false` 切换模式。

### 5.6 正式 App 骨架的实际完成边界

目标任务 `019f6a9f-7411-7251-905c-0351d5d3e41d` 已落地并通过 Unity 编译：

- `AppConfig`：`127.0.0.1:8711`、8 秒连接超时、3 次自动重连、1.2 秒重连间隔。
- `GameServices`：统一持有 Lua、Network、Protocol、UiRouter、UiStack，并负责 Tick/Dispose。
- `ProjectXApp`：正式 Lua Bridge、登录/主界面装配、协议发送、断线回调、自动/手动重连、Esc 返回。
- `NetworkService`：`Idle/Connecting/Connected/Disconnected/Faulted` 状态、连接超时、断线事件和重连入口。
- `UiStack`：根界面、Push、Pop、Clear。
- `BootstrapSceneBuilder`：具备生成正式场景并将其设为 Build Index 0 的代码。
- `Bootstrap.txt` 已增加 `OnDisconnected`；登录 Lua 改用 `Bridge:IsAutomation()` 兼容正式入口与回归入口。

尚未完成：

- 未执行 `Tools > ProjectX App > Rebuild Bootstrap Scene`。
- `Bootstrap.unity` 尚不存在。
- `EditorBuildSettings.asset` 仍只有默认 `SampleScene.unity`。
- 尚未对正式入口执行 PlayMode 登录、断线、自动重连、手动重连回归。

---

## 6. 如何重新运行首闭环

### 6.1 前置条件

本地模式配置：

- 数据库：`fxl_game_local`
- MySQL：`127.0.0.1:3306`
- 游戏服：`127.0.0.1:8711`
- 服务端：`server/config/config` 中 `local_test=1`
- 登录服源码缺失，当前合法路径是直连本地游戏服

新对话不要假设进程仍在，先检查：

```powershell
Get-Process mysqld,kapai,Unity -ErrorAction SilentlyContinue
Get-NetTCPConnection -LocalPort 8711 -State Listen -ErrorAction SilentlyContinue
```

性能与生命周期规则：

- 本项目只有一套本地服务端：workspace-local MySQL + `kapai.exe`。
- 客户端有两套：Cocos `ProjectX.exe` 和 Unity Editor/Player；当前 Unity 迁移任务只启动 Unity，禁止同时启动 Cocos 客户端。
- 文档阅读和静态修改不启动任何运行时；需要编译、场景、Prefab、Console、PlayMode 或真实协议联调时再启动对应进程。
- Unity MCP 由 `.codex/config.toml` 控制。下一任务已预启用 MCP 配置，但没有启动 Unity Editor，不产生 Unity 常驻负载。
- 阶段验收完成后关闭 Unity、Unity Hub、`kapai.exe` 和 workspace-local MySQL，并把 Unity MCP 恢复为 `enabled = false`。

需要启动时：

```powershell
pwsh -ExecutionPolicy Bypass -File tools/local/Start-LocalMySql.ps1
pwsh -ExecutionPolicy Bypass -File tools/local/Start-Server.ps1
```

完整说明见 `LOCAL_RUN.md`。

### 6.2 Unity 内运行

以 Unity `2022.3.62f3c1` 打开：

```text
D:\neiwang_kapai\unityclient
```

执行菜单：

```text
Tools > ProjectX Lua > Run First Playable Loop
```

快捷键定义为 `Ctrl + Shift + L`，但建议使用菜单，避免编辑器焦点问题。

Runner 会：

1. 重建验证场景。
2. 清除上次结果。
3. 进入 Play Mode。
4. 自动点击登录与背包。
5. 最多等待 60 秒。
6. 写结果并退出 Play Mode。

### 6.3 无法点菜单时

编辑器脚本会监听以下请求文件：

```text
build/ui-migration/run-first-playable-loop.request
```

创建该文件后，Unity 会在回到 Edit Mode 后执行回归。不要在 Unity 正处于脚本编译/切换 Play Mode 时反复创建请求，否则容易形成旧程序集和新脚本竞态。

---

## 7. 最后一次验证证据

最后一次干净回归时间：`2026-07-16 08:04`（Asia/Shanghai）。

框架拆分后的最新干净回归时间：`2026-07-16 19:46`（Asia/Shanghai）。Unity batchMode 退出码为 `0`，结果为：

```json
{
  "success": true,
  "status": "COMPLETE: reusable runtime -> LoginController -> main UI -> BagController -> package response/8"
}
```

结果文件：

```json
{
  "success": true,
  "status": "COMPLETE: login UI -> Lua login -> select role -> main UI -> Lua bag click -> package response/8",
  "utc": "2026-07-16T00:04:31.9786695Z"
}
```

产物：

| 文件 | 用途 |
|---|---|
| `build/ui-migration/first-playable-loop-result.json` | 机器判定结果 |
| `build/ui-migration/first-playable-loop-login.png` | 登录界面运行截图 |
| `build/ui-migration/first-playable-loop-main.png` | 主界面完成截图 |

最终日志关键序列：

```text
Login UI is active. Waiting for the enter-game button.
Login UI ready. Btn_Login click is bound to Lua.
Unity Btn_Login.onClick entered Lua.
Connected. Lua is sending PRO_USER_LOGIN/1001...
Lua sent PRO_SELECT_ROLE/1004 for role 1000005.
PRO_SELECT_ROLE/1004 succeeded. UImainLayer is active.
Main UI ready. Bag click is bound to Lua.
Unity Button.onClick entered Lua; requesting PRO_ROLE_PACKAGE/8...
COMPLETE: login UI -> Lua login -> select role -> main UI -> Lua bag click -> package response/8
```

回归前曾遇到一次旧 TCP/Play 会话残留，表现为连接成功后没有 `1001` 回包；退出 Play Mode并重启本地服后干净回归通过。后续出现同类问题时先清理会话，不要直接改协议代码。

---

## 8. UI 静态迁移成果

转换链：

```text
Cocos Studio CSD/CSB/PLIST
→ tools/ui_migration/convert_ui.py
→ build/ui-migration 中间 JSON/报告
→ tools/ui_migration/prepare_unity_project.py
→ UnityMigration documents/图片/图集帧/九宫格
→ CocosUiImporter.cs
→ 356 个 uGUI Prefab
```

已处理：

- PLIST 子图提取及旋转帧还原。
- `MarkedSubImage` 与 `PlistSubImage` 同名冲突隔离。
- Scale9 Sprite Border 和 673 个切片变体。
- Text 字体、字号、颜色、对齐、描边、阴影。
- 通过“路径 + 类型 + ActionTag”绑定重名节点。
- Prefab 节点、缺失脚本、Sprite、Border、Text 和绑定完整性校验。
- `CocosUiBinding` 在序列化目标缺失时，可回退搜索 `CocosNodeMetadata`。

确实缺失、仍使用占位图的 12 张资源：

```text
res/UI/ditu_shijie/ditu_shijie_chaogecheng_n.png
res/UI/ditu_shijie/ditu_shijie_chentangguan_n.png
res/UI/ditu_shijie/ditu_shijie_dongyi_n.png
res/UI/ditu_shijie/ditu_shijie_huanghetan_n.png
res/UI/ditu_shijie/ditu_shijie_jinbiedao_n.png
res/UI/ditu_shijie/ditu_shijie_kunlunshan_n.png
res/UI/ditu_shijie/ditu_shijie_lingwucun_n.png
res/UI/ditu_shijie/ditu_shijie_nvwamiao_n.png
res/UI/ditu_shijie/ditu_shijie_xifangjingtu_n.png
res/UI/ditu_shijie/ditu_shijie_xiqi_n.png
res/UI/ditu_shijie/ui_icon_map_tianwaitian.png
res/UI/ui_common/ui_juese_title.png
```

不要为了这 12 张图阻塞业务迁移；找到原图后再统一替换并重跑校验。

---

## 9. 当前明确未完成

### P0：完成正式启动骨架装配与验证

- 已完成最小协议注册/分发器、Lua Resources 模块加载与生命周期、UI Router/View、登录模块拆分。
- `ProjectXApp/GameServices/AppConfig/NetworkService/UiStack`、正式场景、Build Index 0、正常登录、自动/手动重连和 Esc 返回均已验收。
- 待补：Lua 错误栈与可控热重载、协议请求关联、统一错误弹窗、完整弹窗/返回键规则。
- `FirstPlayableLoopBridge` 仍是验证场景装配器；正式启动场景需要独立 App Bootstrap，不能直接当发布入口。
- 重复登录、业务错误码展示。
- 配置数据加载和 Lua 数据管理层。

### P1：完整登录链路

- 服务器列表与选服 UI。
- 账号输入/注册的真实规则。
- 创角 UI 人工验证。
- Loading、公告、登录错误提示。
- 正式登录服缺失问题；不能凭空猜线上协议。

### P1：主界面业务

- 背包界面真正打开及列表渲染。
- 阵容、任务、商店、邮件、活动等高频入口。
- 红点、引导、弹窗层级、返回键。

### P2：表现与发布

- Cocos Timeline → Unity AnimationClip/Animator。
- Particle、TextAtlas、ScrollView/ListView/PageView 运行行为。
- 音频、字体授权、Shader/材质。
- Build Settings、启动场景和正式 Player 配置。
- Windows Player 构建。
- Android IL2CPP、ARM64、包体、真机和网络权限验证。

---

## 10. 下一对话建议执行顺序

推荐下一目标：**PlayerStore + CurrencyStore + 主界面角色/货币 HUD**；完成后再进入阵容/神将只读列表。

顺序：

1. 读取 `AGENTS.md`、本文件、`LOCAL_RUN.md`。
2. 确认 Unity、Cocos、MySQL、`kapai.exe` 当前均未常驻；只启动本阶段需要的 Unity。
3. Unity MCP 当前禁用；需要图形验收时再启用，并检查实例、编译状态、Console 和 Build Settings。
4. 需要真实协议联调时再启动 workspace-local MySQL 和 `kapai.exe`，重新跑 `Run First Playable Loop` 确认回归入口未退化。
5. 用正常图形 Editor 补任务追踪、任务面板、背包的截图与人工点击 QA；batchMode 不替代视觉验收。
6. 迁移 PlayerStore/CurrencyStore，把角色基础信息和货币增量接入主界面 HUD。
7. 将现有背包状态正式收进 BagStore，再落地 RewardModel/RewardPresenter。
8. 进入阵容/神将只读列表与详情，消耗型培养和上下阵后置到隔离角色验收。
9. 加入服务器列表、选服和创角界面人工路径；登录服缺失时保持本地直连开关，不猜线上协议。
10. 阶段完成后关闭 Unity/服务端/MySQL；框架稳定后才批量迁移其余 700+ Lua 文件。

不要一开始批量复制全部 Lua；旧 Lua 强依赖 `cc.*`、`LUIBase`、消息总线和 Cocos 节点 API，直接搬运会制造大量不可运行代码。

---

## 11. 验证与重建命令

Python 转换测试：

```powershell
python -m unittest discover -s tools/ui_migration/tests -v
```

从已有 IR 准备全部 Unity 资源：

```powershell
python tools/ui_migration/prepare_unity_project.py --scope all
```

Unity 内全量导入：

```text
Tools > ProjectX UI > Import All Prefabs
```

关闭 Unity 后可批处理：

```powershell
& 'D:\unitypro\2022.3.62f3c1\Editor\Unity.exe' `
  -batchMode -quit `
  -projectPath 'D:\neiwang_kapai\unityclient' `
  -executeMethod ProjectX.Editor.CocosUiImporter.ImportAllPrefabsBatch `
  -logFile 'D:\neiwang_kapai\build\ui-migration\unity-full-import.log'
```

关闭其他 Unity 实例后，可无人值守运行真实首闭环：

```powershell
& 'D:\unitypro\2022.3.62f3c1\Editor\Unity.exe' `
  -batchMode `
  -projectPath 'D:\neiwang_kapai\unityclient' `
  -executeMethod ProjectX.Editor.FirstPlayableLoopRunner.RunBatch `
  -logFile 'D:\neiwang_kapai\build\ui-migration\unity-first-loop-batch.log'
```

`RunBatch` 会在成功/失败后分别以退出码 `0/1` 结束，不需要请求文件或人工关闭 Editor。

不要在 Unity 正打开并导入资源时同时运行批处理实例。

---

## 12. Git 与工作区注意事项

交接时 Git 状态包含用户和此前任务的多组修改：

```text
M  .gitignore
M  AGENTS.md
M  server/sql/local_min_schema.sql
M  server/src/bangpai.cpp
?? unityclient/
?? tools/ui_migration/
?? UI_Editor/
?? UNITYCLIENT_HANDOFF.md
以及其他未跟踪目录
```

规则：

- `unityclient/` 当前整体未跟踪，不代表可删除。
- 不执行 `git reset --hard`、`git clean` 或覆盖式 checkout。
- 不碰无关服务端/策划/美术修改。
- `build/`、`.local/`、Unity `Library/Temp/Logs/UserSettings` 已被忽略。
- 提交前必须单独确认 Unity 资源体积、第三方 xLua 许可证和提交范围。
- xLua 使用 MIT License，许可证位于 `Assets/XLua/LICENSE.TXT`。

---

## 13. 交接时进程快照

2026-07-16 性能收口并重启 Codex 后：

- Unity Editor、Unity Hub：已关闭。
- Cocos `ProjectX.exe`：未运行。
- workspace-local MySQL：已关闭，`3306` 无监听。
- `kapai.exe`：已关闭，`8711` 无监听。
- Unity MCP：为下一次 Unity 迁移任务预启用配置，但 Unity 进程未启动。
- `.svn/`（11.74 GB）和 `concept/`（6.97 GB）已加入 `.gitignore`，不再参与 Git 未跟踪扫描。

这是交接快照。新对话仍须重新检查；按当前任务最小化启动，禁止两套客户端和服务端长期常驻。

---

## 14. 新对话开场指令

直接复制：

```text
请先完整读取：
1. D:\neiwang_kapai\AGENTS.md
2. D:\neiwang_kapai\UNITYCLIENT_HANDOFF.md
3. D:\neiwang_kapai\LOCAL_RUN.md

继续 UnityClient 的 C# + Lua 迁移。不要重做已完成的 356 个 UI Prefab；
当前 Unity、Cocos、MySQL、kapai 均应保持关闭；Unity MCP 配置已为本任务预启用。
先检查 Git 和 Unity MCP 连接，再只启动 Unity Editor。
可复用 LuaRuntime/Network/Protocol/UI 框架和正式 App 骨架代码已经落地；
Bootstrap.unity、正式登录/重连/返回和真实背包全量/增量/使用闭环均已完成。
任务系统列表、增量、红点、主界面追踪和真实领奖闭环均已完成。
Player/Currency HUD、BagStore、RewardStore/Presenter、HeroStore/FormationStore、
神将列表详情与阵位变更恢复均已完成。
下一步先做 ResourceService、服务器时间、通用 Loading/Toast，
再迁移神将装备/法宝 Store；随后邮件、商城、好友/帮派、活动商业化。
需要真实协议联调时再启动 MySQL 和 kapai；阶段完成后关闭 Unity、MySQL、kapai。
```

---

## 15. 2026-07-16 任务系统第二阶段增量

已完成：

- `TaskStore` 支持全量替换、单条增量、领取态、可领取聚合和旧主支线追踪记录。
- `TaskController.lua` 支持 `/37 op=1/2/3/5`、`/39 op=0/1`、`/65 type=101`。
- `RenwuLayer` 的领取按钮已接真实 `/37 op=3`，返回奖励按 `byte count + [word type,uint id,uint num]` 解析。
- 新增 `MainTaskTrackerPresenter`：复用 `UImainLayer_backup` 的 `Panel_QuestAndTeam`，主界面最多显示 3 条未领取任务；点击追踪条打开任务页。
- `btn_renwu/Prompt` 红点由 `TaskStore.HasClaimable` 驱动；任务列表未加载前兼容服务端 `/65`。
- 服务端仅在 `local_test=1` 下新增 `/13 op=51 + condition + amount`，用于隔离角色驱动正常任务更新路径；线上路径不生效。

真实隔离角色验收：

```text
/37 op=1 type=1 -> 8 tasks
/13 op=51 condition=9 amount=3
server push /37 op=2 -> task 1 progress=3 state=1
/37 op=3 type=1 id=1
reward -> type=852 id=0 amount=10
/37 op=1 type=1 -> task 1 state=2
COMPLETE: /37 op=2 incremental -> red dot/tracker -> /37 op=3 claim -> 1 reward -> persisted state=2
```

验证结果：

- 服务端 Debug 构建成功：`build/server-win/Debug/kapai.exe`。
- Unity 真实协议 Runner 退出码 0：`build/ui-migration/task-phase2-validation-2.log`。
- 结果文件：`build/ui-migration/bootstrap-app-result.json`，`success=true`。
- Unity 最终编译退出码 0：`build/ui-migration/task-phase2-final-compile.log`。
- UI 转换测试 10/10。
- `git diff --check` 无 whitespace error。

已知限制：当前会话未暴露 Unity MCP 工具；batchMode 的 `ScreenCapture` 没有产出有效截图，同步截图实验已撤回。任务面板、主界面追踪面板和红点仍需在图形 Editor/Unity MCP 中做最终视觉与人工点击 QA。

该迁移序列已于 22:53 完成。下一迁移：`ResourceService + ServerTime + Loading/Toast`，随后 `HeroEquip/FaBao Store`。

本阶段最终进程快照：Unity、Cocos、`kapai.exe`、workspace-local MySQL 均已关闭，`8711` 无监听；`.codex/config.toml` 中 Unity MCP 保持 `enabled = true`，但当前 Codex 会话仍未暴露 Unity MCP 调用工具。
