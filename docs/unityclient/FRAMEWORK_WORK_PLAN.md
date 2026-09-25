# Unity 客户端内部框架治理工作计划

> **当前续接状态（2026-09-25，优先级高于下方历史摘要）**：目标为完成全部 W6，执行目录仅 `C:\Users\Admin\.codex\worktrees\a6b4\Game`。W6.3 的90个Prefab路径/目标例外已在 C 盘 Play 中逐项真实退场并回读 Snapshot 身份，90/90 tuple 不变、Metadata 退场、别名保留；临时实例和784条临时 retired identity 已清理。W6.5 Presenter `.Binding.Find(` 范围计数为0；其余共享 Snapshot/Binding 消费者与未验收 Presenter 路线仍在推进。不可达的 KunLun/OnlineLayer/LilianLayer不伪造入口、不改Prefab。当前 Unity PID 45088、LocalServer PID 53772、角色1000001、Play有效；Info 页验证完成后当前仍在 HeroCultivation 信息页，`ProjectXApp.Instance`有效，Console 0/0。本轮修复法宝强化页上限100/120不一致，并修复HeroCultivation升星与Info技能文本裁切/压住详情按钮；两项均在C盘编译后经真实EventSystem和截图复核。W6尚未完成；沿用当前Play，按清单处理未覆盖路线，不重测已验路线。路线及截图索引：`.local/unity-validation/w6-fabao-strength-cap-fixed-runtime-20260925.png`、`.local/unity-validation/w6-hero-cultivation-pages-runtime-20260925.md`。

> **当前续接状态增量（2026-09-25）**：HeroCultivation Info 技能详情列表已修正为 CSD 源定义的 540×270 视口 + 540×800 独立 ScrollRect 内容；8 行首屏与底部通过真实 Raycast/滚轮验证，关闭后重新打开仍为8行且回到顶部。截图及几何证据见 `.local/unity-validation/w6-hero-cultivation-pages-runtime-20260925.md`。Play 已回到 HeroCultivation Info 页面，Console Error/Warning=0；继续当前 C 盘 Play 处理其余未验路线。

> 范围：仅针对 `unityclient/`。
> 原则：保留已验收功能，先静态梳理，再做最小改动；不引入大而全第三方 Unity 框架。
> **历史实施摘要（2026-09-25期间快照，仅保留改动背景；当前门禁以上方续接状态为准）**：W6.1/W6.2完成；W6.3的90个Prefab path-target例外已分类并按上方续接状态完成运行时Snapshot身份回读。全局Snapshot/Binding消费者仍需逐项收敛。W6.4的KunLun/OnlineLayer/LilianLayer不可达，不补入口、不改Prefab/`.meta`，遇到自然入口再验。W6.5 Presenter精确盘点为范围内 `.Binding.Find(` 0；Friend/Guild属于steam-excluded。其它源码迁移数量、分类和背景见 `.local/unity-validation/w6-presenter-binding-find-inventory-20260925.md` 与 `.local/unity-validation/w6-binding-find-callsite-classification-20260925.md`；这些静态计数不替代剩余运行路线。Mail、Bag ItemType=6、商城、招募、背包类型与共享页签的既有证据保留，不重测。不可达页面不构造测试入口。
> **进度覆盖（2026-09-25 07:45）**：Unity Editor 已完成当前全部 Assets C# 源码编译，Tundra build success、0 errors、2 条 `NormalizeSharedUiSprites.cs` CS0618 警告；这只关闭编译门，不代表 W6.3 运行时身份回读或 W6.5 未验真实路线通过。
> 下方以“当前状态（2026-09-24）”开头的长段落是历史基线快照，不能覆盖本条 2026-09-25 进度。
> **MCP 续接状态（2026-09-25 后续核对）**：8080 listener 已恢复，但单次 initialize 返回 HTTP 200 后，同 session 的 `notifications/initialized` 返回 HTTP 404 `Session not found`；未取得 Editor state/Console，也未触发编译。当前不要把端口存活当作工具 session 可用；不再重握手或重启 Editor/MCP。本次代码编译门仍待通过。
> 当前状态（2026-09-24）：W0-W3、W4.1-W4.4 完成；12 个 ProjectX asmdef 与 XLua runtime/editor 支持程序集均已建立并通过 Unity Editor 编译。Windows x64 Mono Player 已构建并启动；Editor Play 通过真实 EventSystem 进入已有存档主界面，本地服务 127.0.0.1:8711 连通。W4.5 的 Slot01→临时 Slot03 快照复制/登录恢复并清理、1334×750 UI保存与 Play 重启偏好恢复已验收；独立 Player 全屏和全部页面行为仍待验证，详见 `.local/unity-validation/w4-save-snapshot-resolution-roundtrip-20260924.md`。Player 构建的 XLua `CheckGenerate` 后处理抛出“Code has not been generated”异常；当前 Windows Mono Player 能启动，移动/AOT 未验收，记录于 P-0017。W5.1/W5.2 已通过境界、背包、邮件、系统四页签的真实 EventSystem 连续切换、关闭和再次打开验收；W5.3 列表绑定/动态节点清理已定向编译；W5.4 分页、W5.5 状态视图及 W5.6 Cell 复用边界已形成契约。Bag 只读试点已通过真实 EventSystem；W6.1 Cocos 依赖盘点、W6.2 Bag 页面绑定和招募/共享层级回归已完成；商城完整链由用户自行测试。W6.3 已移除装备 Presenter 中仅用于异常诊断的 Metadata 读取；Bag、PlayerHub 系统页、主 HUD、商城、招募和存档 Continue 页均在限定运行实例完成绑定后退场 Metadata，并通过真实 EventSystem 定向回归，未改 Prefab。运行时 Timeline 已改用序列化 ActionTag 引用：27 个 Timeline Prefab 共 461 条轨道记录、186 个按 Timeline 组件去重的 ActionTag（全局 183 个不同值），186/186 个标签均可解析到非空序列化目标；主界面云层运行态 Metadata 6→0 后仍播放且坐标继续变化。CocosUiBinding 路径回退、输入路径别名、快照语义和 357 个 Prefab 的序列化组件仍在，另有 90 个 Metadata 记录未能通过同路径同 GameObject 引用闭合，W6.3 继续进行。W6.4 已通过玩法页→封神列传与主界面→招募两条真实 EventSystem 路线评估零轨道候选；招募根 Timeline 0 tracks/0 clips、未播放，Popup1/2/3 同时激活且各入口 Raycast 命中，Close 后返回主界面；用户修改的招募 Prefab 未写入。KunLun function_id=7 当前存档不可达；OnlineLayer 在 Unity 主场景不存在且旧入口隐藏，Cocos 源路径可直接发放可领取奖励；LilianLayer 不在当前 Unity 玩法入口列表中。三者均未通过真实 Unity 路线验收，未移除序列化组件。W6.5 继续进行。Gameplay `ActivityLayer` 曾被 `shop_bg/Mask` 遮挡并拦截 Raycast，已在 `ShowGameplay` 固定内容根节点高于框架，干净 Play 复测通过。最近一次 MCP composited GameView 截图请求返回黑图并在 Unity Console 产生5条 `ScreenshotUtility.CaptureCompositedAfterFrame` PlayerLoop recursive Error；堆栈限于 MCP 截图包，详见 `.local/unity-validation/w6-bag-unavailable-jump-runtime-20260924.md`。最近一次 C 盘 Bootstrap 验证结果为 COMPLETE：旧存档 Slot01→Main→玩家 Head→背包页签的真实 EventSystem 路由已派发，Runner 写入 `build/ui-migration/bootstrap-app-result.json`：package/8 解析成功、渲染背包 UI（11 stacks，server=11）。Runner 完成后自动退出 Play；随后 Close 尝试因 `EventSystem.current` 已不存在而未派发，因此背包页签可见性/层级与共享框架关闭恢复仍待单独实况采证。当前 Editor 为 Edit mode，Console 当前 MCP error/warning 查询返回 0 条。屏蔽功能 Prefab Metadata 按用户要求延期。

> 本轮追加（2026-09-24）：修复 Unity Console 的 XLua asmdef/WSA 插件同名 Error；Unity Editor 重启后旧 WorkerManagerASIO/scheduler framing 错误未复现。Slot01 保存包中仅删除角色 1000001 的垃圾道具 1105×2，SQLite 已备份并通过完整性/物品序列校验。后续已通过真实 EventSystem 重进 Slot01、打开背包确认页面正常可见、无缺失图标，真实关闭后共享框架隐藏并恢复 Main；后续 Play 重启后 Console Error=0，仅有孤儿 LocalServer 回收 Warning(pid=4912)。详情见 `.local/unity-validation/w6-error-log-and-item-cleanup-20260924.md` 与 `.local/unity-validation/w6-bag-post-cleanup-runtime-20260924.md`。

## 一、状态定义

> **最新 W6.3/W6.5 Bag 运行复测（2026-09-24）**：首次复测期间背包有 3 条 item 1105 缺图警告；删除 Slot01 中 1105×2 后，重新通过真实 EventSystem 打开背包、点选动态生成的“转盘钥匙”行，右侧详情名称与描述正确更新；没有点击使用。真实关闭后 OneLevel/Bag 隐藏、Main 恢复，Console Error/Warning=0。截图与逐步证据见 `.local/unity-validation/w6-bag-post-cleanup-runtime-20260924.md`。此前 MCP transport 探测事故已另行记录且清空 Console；W6.3 全局消费者、W6.4 不可达候选与 W6.5 共享消费者仍未完成。

> **神将页运行复核（2026-09-24）**：干净重启 Play 后，从主界面真实点击神将入口，OneLevel 神将页可见；Binding 28/28 引用均解析，Metadata=90（模板 15 项及 5 个动态英雄行 75 项保留，13 项精确重复 Metadata 已退场）。关闭按钮 EventSystem 首命中正确，关闭后回到 Main 且 OneLevel 容器退场。最新 Console 0 Error；仅 1 条 LocalServer 遗留服务回收 Warning，非页面错误。可见截图 `.local/unity-validation/w6-hero-visible-runtime-20260924-082423.png`，详情 `.local/unity-validation/w6-hero-current-play-recheck-20260924.md`。商城链由用户自行验收，本次不重测。

> **玩法页任务弹层返回检查（2026-09-24）**：从主界面真实进入玩法列表，再进入每日任务；只查看，不领取。真实关闭任务弹层后，ActivityLayer 保持显示、`huodong_bg` 隐藏、共享 `shop_bg` 背景恢复显示；再真实关闭玩法框架后，ActivityLayer 与 `shop_bg` 均隐藏并返回 Main。Console Error/Warning=0。检查详情 `.local/unity-validation/w6-gameplay-task-return-runtime-20260924.md`。此项不改变 W6.3/W6.4/W6.5 未完成状态。

> **答题页运行时 Metadata 退场（2026-09-24）**：`AnswerPresenter` 完成固定控件绑定后只退场当前运行实例中 59/59 全字段精确匹配序列化引用的 Metadata；未修改 Prefab。干净 Play 经现有 Slot01、主界面→玩法→Function_27 真实输入进入，问题与四个选项可见，实例 Metadata=0/59 refs；没有选择或提交答案。实际关闭回玩法，再关闭返回 Main；Console Error/Warning=0。证据 `.local/unity-validation/w6-answer-metadata-retirement-20260924.md`。全局 Snapshot/Binding/Dispatcher 消费者仍待处理。

> **最新 W6.5 道具来源路由（2026-09-24）**：完成 1140「装备觉醒」背包入口的真实 EventSystem 验收。复现发现原路由选中首件品质2装备，Presenter 按品质门槛拒绝显示；最小修复后选择品质6装备，觉醒页可见，物品854库存保持5。共享 Close 先返回装备列表，再返回 Main，最终 OneLevel/shop_bg 隐藏。无存档/Prefab/`.meta` 修改；Console Error=0，仅 LocalServer 回收 Warning(pid=52148)。详见 `.local/unity-validation/w6-bag-itemjump-1140-awakening-runtime-20260924.md`。W6.3、W6.4、ItemType=6 与剩余 W6.5 消费者仍在进行。

| 状态 | 含义 |
|---|---|
| `[ ]` | 未开始 |
| `[~]` | 进行中 |
| `[x]` | 已完成并通过节点验收 |
| `[!]` | 被问题阻塞，问题必须登记 |
| `[-]` | 明确延期或不纳入当前范围 |

每个节点完成后必须同时更新：状态、完成日期、涉及文件、验证结果、遗留问题。

## 二、工作节点

### W0：范围与安全基线

- [x] W0.1 确认当前 checkout、Git 状态、Unity 版本、目标平台和禁止修改范围
- [x] W0.2 标记已验收功能、用户维护 Prefab、受保护资源和当前脏文件重叠关系
- [x] W0.3 固定当前编译基线、启动基线、关键页面入口和现有验证证据（Bootstrap Play/登录画面基线完成；Mail 真实入口验收保留为 P-0005）
- [x] W0.4 建立本计划对应的问题台账和变更白名单

验收条件：不改业务逻辑即可复现当前工程基线；保护范围明确。

### W1：现有架构与依赖盘点

- [x] W1.1 盘点 Bootstrap、`GameServices`、`ProjectXApp` 和全局生命周期
- [x] W1.2 盘点 Service：网络、存档、配置、资源、时间、本地服务、Lua Runtime
- [x] W1.3 盘点 Data：Store、Catalog、Model、配置读取和数据刷新路径
- [x] W1.4 盘点 UI：Router、Stack、Presenter、View、PrefabLoader、Catalog
- [x] W1.5 盘点 Gameplay、Battle、Validation、Editor 的实际依赖方向
- [x] W1.6 绘制当前依赖图，标记循环依赖和 `ProjectXApp` 过载职责

验收条件：形成当前架构图和依赖清单；不凭文件夹名称推断模块归属。

### W2：Prefab/UI 静态台账

- [x] W2.1 统计 Prefab、UI Catalog、源 CSD/Prefab/运行时 Asset 的对应关系
- [x] W2.2 分析 `OneLevelLayer`、`CommonPageLayer`、`shop_bg`、`huodong_bg`
- [x] W2.3 分析 `ItemCell`、Bag、Mail、Reward、Shop 的 Cell 结构
- [x] W2.4 分析 Tab、列表、ScrollRect、分页、Loading/Empty/Error 节点
- [x] W2.5 记录动态创建节点、运行时挂载点、SetActive、Sibling、Raycast 操作
- [x] W2.6 记录 `CocosUiBinding`、`CocosNodeMetadata`、`CocosTimelinePlayer` 依赖
- [x] W2.7 标记可复用、可适配、暂不可动、应废弃的 Prefab

验收条件：形成 Prefab 台账；每个候选公共组件都有来源、引用方和风险等级。

### W3：内部框架边界设计

- [x] W3.1 确定 `AppScope` 与现有 `GameServices` 的合并方案
- [x] W3.2 确定 Foundation、Data、Network、UI、Gameplay、Validation、Editor 边界
- [x] W3.3 确定 Service 接口和依赖方向
- [x] W3.4 确定 Feature 模块模板：Entry、Store、Presenter、View、Catalog、Config、Validation
- [x] W3.5 设计 asmdef 依赖图，提前排除循环引用
- [x] W3.6 确定正式运行代码与 Validation/Editor 代码的隔离策略

验收条件：框架设计可以映射到现有代码；不重复创建已有基础设施。证据：[`FRAMEWORK_W3_DESIGN.md`](FRAMEWORK_W3_DESIGN.md)。

### W4：基础框架骨架

- [x] W4.1 在不改变启动行为的前提下收敛 `GameServices` 生命周期（Dispose 幂等；已关闭后 Tick 不再推进）
- [x] W4.2 建立 AppScope 初始化、启动、关闭、销毁约定（沿用 `GameServices` 组合根，不新增第二个容器）
- [x] W4.3 建立 Service 接口适配层，不立即替换底层实现（Mail：`IUiResourceProvider` 窄接口试点已编译）
- [x] W4.4 按依赖顺序逐步引入 asmdef：Foundation → Diagnostics → Data → Network → UI.Migration → Animation → UI → XLua → LuaRuntime → Gameplay → Core → Validation → Editor（十二个 ProjectX 层及 XLua runtime/editor 支持程序集均已建）
- [~] W4.5 每增加一个 asmdef 执行编译、序列化和运行时引用检查（十二个 ProjectX 层及 XLua runtime/editor 均编译；Windows x64 Player build/启动、已有存档登录和本地服务连通已验收；Slot01→临时 Slot03 快照复制/登录恢复并清理、1334×750 UI保存/重启恢复已验收（`.local/unity-validation/w4-save-snapshot-resolution-roundtrip-20260924.md`）；独立 Player 全屏表现与剩余页面行为未验收）

验收条件：启动、登录、存档、本地服务和已有页面行为不变；编译边界可复现。

### W5：UI 公共框架试点

- [x] W5.1 设计 `UiPageFrame`：背景、Header、Close、Content、Footer、Overlay（OneLevelLayer 先落地；真实打开、关闭、重复打开通过）
- [x] W5.2 设计 `UiTabGroup` 和页签所有权/状态模型（PlayerHub 四页签；真实连续切换及固定 sibling 顺序通过）
- [x] W5.3 设计列表 Cell 绑定与动态节点清理规则（以现有 `VirtualList<T>` 为公共实现）
- [x] W5.4 定义 `UiPagination` 契约，区分本地分页和服务端分页

  - 本地分页：对调用方提供的完整快照按固定 pageSize 切片；页码为 0 基，输入数据变化时 clamp 当前页；上一页/下一页只改本地状态，不发网络请求。
  - 服务端分页：Presenter/Store 持有请求、取消、总数或 hasMore 与错误状态；分页组件只呈现并发出目标页，不伪装成全量本地列表。
  - `VirtualList<T>` 只负责视口虚拟化，不隐含分页；无真实服务端分页消费者前不新增请求抽象或迁移现有页面。
- [x] W5.5 定义 `UiStateView`：Loading、Empty、Error、Content

  - StateView 仅投影 Presenter/Store 显式给出的状态到已存在的节点；状态节点互斥显隐，不调 sibling 顺序、不创建无来源文案/资源。
  - Loading/Empty/Error/Content 表达当前结果；已有内容刷新时由调用方选择保留 Content，StateView 不自行抹除已有数据。
  - Error 文案与 Retry 回调归属 Presenter/Store；没有重试语义时不显示可点击的伪 Retry。
- [x] W5.6 定义 `ItemCell`、`RewardCell`、`ShopItemCell`、`MailRewardCell` 的复用边界

  | Cell | 可复用职责 | 保留在页面/Presenter 的职责 |
  |---|---|---|
  | ItemCell | 物品图标、品质框、数量等纯展示投影 | 背包选择/使用、装备替换和物品来源业务 |
  | RewardCell | 奖励类型、图标与数量展示 | 领取/发放结果、奖励弹窗生命周期 |
  | ShopItemCell | 商品图标、价格/限购状态的展示 | 货币校验、数量、确认购买、协议与回包 |
  | MailRewardCell | 邮件附件图标、数量与品质展示 | 读/领/删邮件、已领取状态及请求刷新 |

  - Cell 接收已解析的展示数据和可选事件回调；不读取全局 Store/Network，不自行发请求或改变资源状态。Prefab/Cocos metadata 的显示语义保留，跨页面数据形状不强行合并。
- [x] W5.7 选择 Bag 作为低风险试点；只做列表/选中/关闭/重复进入，不执行使用道具等写操作
- [x] W5.8 真实输入验证打开、切页、列表刷新、返回、关闭和重复进入（Unity MCP EventSystem/Raycast；证据 `.local/unity-validation/w5-bag-play-acceptance-20260923.md`）

验收条件：公共组件至少被两个实际页面使用；动态节点数量、监听数量和 Raycast 状态稳定。

### W6：Cocos 迁移层逐页退场

#### W6 执行节奏与前轮耗时复盘（2026-09-24）

- 前轮约 21 小时仍未收口，主要原因是从商城/共享层级验收扩展到全量 W6 后没有重新锁定范围与检查点；已通过的商城、招募、页签和物品类型被反复检查；启动 UI 前未核对正式运行实际使用的 SQLite 路径，导致 1114 夹具写入 `LocalServer/projectx.db`、单机入口却读取 `Saves/Slot01/projectx.db`；固定等待和 Bootstrap Runner 自动退场造成无效操作；MCP 合成截图递归报错仍消耗排障时间；已完成内容过晚才形成提交检查点。
- 本轮 W6 执行约束：按本节待办逐项建“要求→当前证据→缺口”清单；已有 `[x]` 路线只在其依赖或验收环境变化时重测。每轮只处理一个根因/真实路线；开测前核对 Unity 实例、Runner Armed、实际 Server 命令行数据库路径与夹具目标路径，不一致即停止数据 Setup。用状态/协议事件确认 UI 到达，不用固定长睡眠猜页面时序；禁止再次调用已知会递归失败的 MCP 合成截图路径。每完成一个可审查子项立即写入本计划和 `.local/unity-validation/` 证据；单条排障超过 30 分钟仍无根因时先形成可恢复检查点并转做独立 W6 项，不重复相同探路。收尾核对夹具哈希、进程/端口和原有脏文件。
- Prefab YAML 静态身份脚本必须先断言成功解析到非空 GameObject/Transform/Binding 表，再比较目标路径；比较时剥离 owning view 根节点名，并处理实际两空格缩进的 `nodes` 列表。若解析表为空或所有目标同时“不匹配”，先判定检查器有误，不把它记成项目错误，也不据此改 Prefab/源码。
- 2026-09-25 全源码 `.Binding.Find(` 单次盘点为282处/23文件；`ProjectXApp.cs` 有176处，其中按验证/审计方法名启发式归类116处，仍有60处需逐方法核对。数字仅作定位，不驱动批量改写；详细分组和规则见 `.local/unity-validation/w6-binding-find-callsite-classification-20260925.md`。
- `ProjectXApp.WorldUi.cs` 宝箱/主线成就/统计框架23处迁移后，全源码剩259处/22文件；所涉及60条路径均与实际 Prefab hierarchy 及对应序列化 Binding target 同对象。见 `.local/unity-validation/w6-binding-find-callsite-classification-20260925.md`；编译及领奖/关闭真实路线仍未验证。
- `ProjectXApp.JingJie.NormalizePlayerHubSurfaceOrder` 的 OneLevel `Bg`、`Panel_12`、`GoldCheck` 三处固定路径已核对 hierarchy 与序列化 Binding target 同对象后切换到 `FindNode`；仅影响固定 sibling-order 收敛，真实共享页签/返回路线待复验。YAML 节点 `target.fileID` 是 GameObject 身份，静态核对不得与 Transform ID 混比。
- JingJie 的12处 `CocosUiView.Binding.Find` 迁到拥有它们的 Main/OneLevel `FindNode`；OneLevel五个静态目标同 GameObject，主界面 JingJie 按钮走原 Transform fallback，动态 `Button2_Runtime` 的创建/查询顺序未改。跨变更编译与 JingJie 开页/切换/关闭路线待集中验证。
- 2026-09-24 验收通道耗时补充：C 盘 worktree 的 Unity MCP 临时启动后确认实例唯一、HTTP 8080 连通，但 `editor/state` 连续读取仍返回固定 sequence=3、`ready_for_tools=false/stale_status`；`telemetry_ping` 返回 queued 后快照仍未更新。未绕过门禁调用编辑/Play工具；恢复 `.codex/config.toml` 为 `enabled=false` 并正常退出 Editor。后续遇到同一 stale sequence，只允许一次 ping 加一次短间隔状态刷新；若仍相同，记录工具阻塞并转源码/批编译工作，不循环轮询，不把编译当 Play 验收。
- 2026-09-24 会话续接补充：当前续接时已核实 C 盘 Unity Editor（PID 34032）、LocalServer（PID 49732，Slot01 SQLite）和 Unity MCP HTTP 服务（PID 41696/8080）均存活。复用旧 MCP session 一次返回 HTTP 404；对现有服务发起一次 initialize 后，服务日志确认创建 session `3bccce56163b4710b6dbfc5377bbf4d7`，但紧接的 initialized 请求返回 HTTP 404/`Session not found`。这指向 HTTP transport/session 续接异常，不是 Editor 或服务端退出。未重启 Editor、MCP 服务或服务端，也未重走登录。后续先保留所有仍存活进程与 Play/账号状态；单个 session 失败仅允许一次握手，若新会话不能读取状态则记录桥接阻塞并转静态源码工作，不循环重握手、不重登。
- 2026-09-24 续接识别与剩余依赖核对：Unity 可执行文件位于 `E:\UnityPro\2022.3.62f3c1\Editor\Unity.exe`，但 PID 34032 的 `-projectPath` 明确指向 `C:\Users\Admin\.codex\worktrees\a6b4\Game\unityclient`；工作区判断以 `-projectPath` 为准，不以 Editor 安装盘为准。MCP 8080 listener 与 mcp-for-unity 进程 PID 41696/15104 启动时间一致且仍存活，端口正常监听；不得把单次 session 404 当作服务退出或重启理由。静态源码复核发现，W6.5 仍有真实公共依赖：`CocosUiView` 通过 `CocosUiBinding` 执行节点/按钮绑定，`RuntimeInputDispatcher` 的路径后备仍读取 `CocosNodeMetadata`，`RuntimeSnapshotCollector` 仍读取 Binding 节点、退役 Metadata 身份表和 Metadata 本身。另在 Presenter 源码中计得 `.Binding.Find(...)` 仍有 278 处、分布在24个文件（`HeroCultivationPresenter` 84、`HeroEquipmentPresenter` 47、`DrawPresenter` 27为最大三组）；这只是精确调用盘点，不是迁移完成证据。先迁走或明确替代公共消费者，再逐模块迁移并验证，最后判断组件/Metadata 可否退役；不重复此前已通过的商城、招募、Bag/共享页签路线。
- 2026-09-24 续接桥接复验：保持 PID 34032/41696/15104/49732 与 C 盘 `-projectPath` 原样；8080 服务日志显示旧请求仍有成功 200，亦有 session 404。对当前服务仅做一次独立 initialize，响应创建 session `5f4882e86ca3425fbdff397a116b75a1`，随后同一客户端紧接的 `notifications/initialized` 即返回 `Session not found`（HTTP 404）。据此判定当前客户端到 MCP streamable-HTTP session 的续接仍不可用；没有重启服务、Editor、Play、账号或本地服务。不要继续重握手；等待外部会话桥接恢复期间只做源码/Prefab 只读审计，不把重复验收当作恢复手段。
- 2026-09-25 当前错误复核：沿用已建立的 MCP HTTP session，`resources/read(editor/state/custom-tools)` 与只读 `execute_code` 均成功；Editor 实际为 C 盘 worktree、`isPlaying=true`、`isCompiling=false`。只读运行时查询确认 `ProjectXApp.CurrentAppState=Main`、EventSystem 存在、Canvas 可读；MCP `editor/state` 的 `is_changing=true/phase=playmode_transition` 与实际运行态不一致，不再据此等待或重启。Console 返回一条 `[WebSocket] Connection failed ... Unable to connect to the remote server`（MCP-FOR-UNITY），不是已证实的游戏业务异常或 C# 编译错误；HTTP 通道仍可用。没有重启 Editor/Play/账号/LocalServer，也没有重复握手。后续复用现有 HTTP session，按未完成页面做定向验证，不重测已通过路线。
- 2026-09-25 Play 数据库路径契约审计与修复：普通 Editor 功能测试必须用 `persistentDataPath/LocalServer/projectx.db`，而无 `-projectX` 参数原先误进 `Saves/SlotNN`。已将 `ShouldUseSinglePlayerTitle` 改为：普通 Editor Play 走 LocalServer；只有显式 `-projectXSinglePlayerFlowValidation` 保留 Slot 流程；非 Editor 发布包默认单机流程不变。scripts-only refresh 后运行时反射证实 Editor `singlePlayer=False`，Console error/warning=0。当前旧 Play 仍是无服务状态、PID 49732 仍用 Slot01；只在一次新 Play 后核实 LocalServer 命令行，未重启旧会话/服务或改档。证据 `.local/unity-validation/w6-singleplayer-database-path-contract-20260925.md`。
- 2026-09-25 MCP/Editor 验收防重启补充：复用 session 前先确认准确 session ID；`Session not found` 只说明该 session 无效，不代表 MCP 服务故障，不重新 initialize 或重启 Editor。Unity WebSocket 单次失败时先读现有 HTTP Console/state；HTTP 成功且 Console 无项目错误则继续。`execute_code` 的内存表达式编译失败不等于项目 C# 编译失败；调用类型/属性前先读源码确认命名空间与公开成员，避免猜测式试编译。比较路径身份时统一对象类型（`legacy.transform` 对 `Transform`），避免探针逻辑错误制造假差异。源码 refresh/domain reload 后先确认 `ProjectXApp.Instance`；实例为空时 Dispatcher 会拒绝真实输入。把未验收页面累积后统一做一次 targeted Play，不重复点击已通过路线。
- 2026-09-25 PlayerHub 路由耗时复盘：`AppState=Main` 不代表 Main HUD 当前可见；每次先读 Canvas 根节点 active 状态，按实际界面选择入口。Dispatcher `Error` 为空可能是 null，检查必须用 `string.IsNullOrEmpty`；选中中的页签可能没有 Raycast，先 Inspect，零命中时跳过。每次可见改动后校验页面根状态/关键业务内容，最后一次 Close 并读 Console；避免对不存在的旧路径盲点或因探针表达式错误重跑整条链。详见 `.local/unity-validation/w6-playerhub-tab-settings-runtime-20260925.md`。
- 2026-09-25 MCP 探针错误与批量数据快照：执行代码只访问源码确认过的公共 API；私有字段通过精确反射，反射重载必须给出参数类型，避免把探针编译/运行错误误判成 Unity 项目错误。复用 session 的 Console 查询为0；探针纠错后发现 Main_UI 实际 inactive。当前运行时 BagStore 已具备28项、13种 ItemType（含真实1114×3），不重测已通过类型；等 HUD 恢复后在同一 Play 中完成剩余 BagFlow 链。细节见 `.local/unity-validation/w6-fish-onelevel-runtime-20260925.md`。
- 2026-09-25 列表离屏与输入复盘：目标按钮没有 Raycast 时，先读 ScrollRect viewport/content 和目标 RectTransform bounds；确认在 viewport 外才从真实可滚动区域滚动，再检查目标进入 viewport 后 Inspect。禁止对离屏坐标反复点，也不要为了观察弹性滚动加入固定长等待。Fish function32 因首屏仅显示到 GameplayRow4，ScrollRect 真实滚动后才可见；详见 `.local/unity-validation/w6-fish-onelevel-runtime-20260925.md`。
- 2026-09-25 MCP stale 与 Bag ItemType=6 定向收敛：`editor/state` 在唯一实例和 HTTP 服务已存活时仍固定旧 sequence；一次 `telemetry_ping` 加一次短间隔刷新仍为 stale。运行期间已使用的 C 盘 Unity 实例完成了当前 Bag 定向检查后，按复盘规则停止 Play、正常关闭 Editor、执行官方 fixture Restore/AssertRestored/Cleanup/AssertCleanup；SQLite 返回原 SHA-256 `9ca4fdbb89d14163de7a4734f26e591351b9709750066f73adb63de0b5972eac`，残留0。真实 Raycast 检查 ItemType=6 礼盒六个选项、首选项选择和数量1→2→1；最终共享 Close 通过，1114数量保持3、未确认奖励/消耗。其他已验收类型未重测。旧 Btn_Old 路径不活跃时从当前层级选 Btn_Play；列表整行中心被 ListView 命中时对真实 CheckBox 做 Inspect 再输入。详见 `.local/unity-validation/w6-runtime-error-recovery-20260925.md`。W6.3全局身份例外与剩余W6.5消费者仍未收口。

本轮静态调用清单（`.Binding.Find(...)` 精确字面量计数；迁移状态仍须看模块证据）：

| Presenter | 次数 | Presenter | 次数 |
|---|---:|---|---:|
| HeroCultivationPresenter | 84 | HeroEquipmentPresenter | 47 |
| DrawPresenter | 27 | WorldBattlePlaybackPresenter | 23 |
| HeroRebirthPresenter | 14 | FengShenStoryPresenter | 10 |
| WelfareActivityFramePresenter | 10 | HeroPresenter | 7 |
| MonopolyPresenter | 6 | OldMemoryPresenter | 6 |
| FormationPopupPresenter | 5 | GameErrorPresenter | 4 |
| XunBaoOverlayPresenter | 4 | MailPresenter | 2 |
| FriendPresenter | 1 | GuildPresenter | 1 |
| HeroBookPresenter | 1 | TeamPresenter | 1 |
| WelfarePresenter | 1 | WorldPresenter | 1 |
| WorldOutcomePresenter | 1 |  |  |

计数用于定位下一待迁移 Presenter，不能直接作为完成率；动态列表局部 `Transform.Find` 和 `CocosUiView` 内部路径缓存应分别审计，不得靠全局替换绕过逐页验证。

2026-09-25：MoneyTreePresenter 的6处与 HappyWheelPresenter 的1处已改为 `CocosUiView.FindNode`，活动 Prefab 48/48 个受影响路径保持旧 Binding 与新 Transform 身份一致。定向 Play 中通过真实 EventSystem 打开摇钱树与欢乐转盘；两页可见，关闭均命中当前弹窗自身 CloseBtn 并返回玩法列表，未摇奖/转盘。Console Error/Warning=0。一次预设共享关闭路径与欢乐转盘的实际首命中不一致，Dispatcher 拒绝输入且未触发点击；改用首命中 `DynamicUi_ZhuanpanLayer/Panel/CloseBtn` 后成功关闭，属于验收路径选择错误，不是 Unity Console 报错。证据 `.local/unity-validation/w6-moneytree-happywheel-path-migration-20260925.md`。W6.5 Presenter 字面调用剩余249处/20个Presenter。

HeroCultivation 的早期路径映射预审（历史统计，已由 2026-09-25 当前源码复核替代）：最初将共享 `frame` 错配到 `shop_bg` 后得到的计数已作废。按 `ProjectXApp.EnsureHeroCultivationPresenter()` 的真实 source→Prefab 对应（共享 OneLevel `frame`→`OneLevelLayer.prefab`；运行时复制的 `helpFrame`→`shop_bg.prefab`），将14个视图 Prefab Transform 链与 Presenter 可静态提取的69处 `Binding.Find("literal")` 比较：66处精确匹配 Unity Transform 路径（含 `Layer/` 前缀兼容分支），3处为运行时创建节点，分别是 `HeroCultivationHelpTab2` 与两处 `HeroDestinyButton`（源码可见相应 Instantiate/命名逻辑）。其余15处使用变量/插值，未纳入。66条静态匹配路径可作为下一次定向代码迁移输入；动态节点须继续通过其创建后时序解析。全部属于静态资产/源码映射，尚未在迁移后做编译或真实输入验收；本轮不改代码，避免 Editor 活动状态无法从 MCP 读取时触发重编译并破坏现有 Play 状态。 当前口径见下方“W6.5 HeroCultivationPresenter 固定路径迁移”；旧统计只作为当时源码快照保留。

- [x] W6.1 识别仍依赖 Cocos 路径和 ActionTag 的代码（完成首轮源码消费者、ActionTag 调用链及 Prefab GUID 覆盖统计；页面级替换范围归入 W6.2 准备，不据此删除兼容组件）
- [x] W6.2 将 Bag 试点页面改为 Unity 页面绑定组件（首轮迁移范围限 Bag 自有内容；共享 OneLevelFrame 继续由既有协调器管理；不改 Prefab）
- [~] W6.3 清理无引用的 `CocosNodeMetadata`（装备 Presenter 诊断性读取已退场；Bag、Main HUD、Shop、Recruitment、Continue 存档列表和神将培养均在限定运行实例完成绑定后退场 Metadata 并通过真实 EventSystem 定向回归，未改 Prefab。培养页 `ShowPage()` 在 `Render()` 后清除当前页 Metadata；`Show()` 首屏渲染后再清除 24/24 精确序列化引用闭合的培养壳 Metadata。干净 Play 中壳 24→0、24 条 Binding 引用全部可解析；Level/Star/Breakthrough/Cultivate/Info 均 Metadata=0，页签每次切换后 sibling 固定 0–4；见 `.local/unity-validation/w6-herocultivation-shell-metadata-retirement-20260924.md` 和 `.local/unity-validation/w6-herocultivation-metadata-retirement-20260924.md`。运行时 Timeline 改用序列化 ActionTag 引用；初始 27 个 Timeline Prefab 的 461 条轨道记录、186 个按 Timeline 组件去重的 ActionTag（全局 183 个不同值）均解析到非空序列化目标。现有 26 个仍挂载组件的 Prefab 保留 461 条轨道与上述 ActionTag；干净 Play 实测活动云层 Metadata 6→0 后 Timeline 继续播放、坐标变化。2026-09-24 在干净 Play 用 Slot01 完成 OneLevel Bag→神将→强化大师→装备强化→返回强化大师→关闭恢复主界面；页签 sibling 顺序固定、显隐切换实测不改顺序，Console 0 Error。Editor.log 留有修复前 `HideDetails` NullReference 历史记录；根因是可选法宝材料选择器未绑定时被无条件隐藏，当前已有 null-safe 防护，修复后真实路线 Console 0 Error，详见 `.local/unity-validation/w6-metadata-consumer-recheck-20260924.md`。Dispatcher 已增加序列化引用与 binding-relative Transform 路径解析，并以 Metadata=0 的主界面真实 Raycast/点击打开招募后正常关闭；Draw 首个场景 unityPath 同步改为当前实际可达入口。全工程 357 个 Prefab 仍序列化 Metadata；90 个路径/目标例外与 RuntimeSnapshot 身份消费者仍待闭合）
- 神将列表进一步收敛：已先退役5行克隆75项；本轮在克隆处理后退役 Item 模板15项，列表 Metadata 15→0，28/28 Binding 引用有效。模板保留为 `VirtualList` 克隆源但不再带 Cocos Metadata；15条身份由序列化引用和 Snapshot 精确承接。真实重进、角色行点击与共享关闭回归通过，见 `.local/unity-validation/w6-hero-template-metadata-retirement-20260924.md`。
- [~] W6.4 清理无 Timeline 依赖的 `CocosTimelinePlayer`（剩余 26 个挂载 Prefab：22 个含轨道、4 个无轨道。封神列传 Prefab 的 0 轨道/1 空 clip 组件已通过 PrefabUtility 移除；移除后真实 Slot01→玩法→封神列传路线确认章节/进度文本正常、页面关闭与共享框架返回正常，Console Error/Warning=0，证据 `.local/unity-validation/w6-fengshen-zero-track-timeline-retirement-20260924.md`。招募已实际打开并确认零轨道/未播放，Popup1/2/3 同时显示且 Close 返回正常，用户修改 Prefab 未写入；KunLun function_id=7、OnlineLayer、LilianLayer 当前 Unity 存档/客户端没有可达真实入口，组件保留）
- [~] W6.5 在页面不再依赖路径查找后移除 `CocosUiBinding`（Bag 主页面 `BagPresenter` 已改由 `BagPageBinding` 缓存页面控件，不再调用 `CocosUiBinding.Find`；真实 EventSystem 点选运行时“转盘钥匙”行后，详情名与描述正确更新。BagFlowPresenter 已移除全部 `CocosUiBinding.Find` 调用，固定弹层目标改为按 View 解析并缓存 Unity Transform 节点；干净 Play 真实选择体力丹→Use→输入 `2`→真实关闭，输入文本正确、库存仍3、共享 Close 返回 Main；14个模态按钮与3/3滚动区结构验证通过。Bag 礼盒列表校验也改为读取已绑定的 `GiftScroll` 属性，编译后重新进入真实 Bag 并验证 `GiftScroll/content/viewport` 均有效，Close 返回 Main。仍保留 `CocosUiView` 生命周期封装及 Input Metadata Snapshot 身份登记，礼盒选项/奖励、来源与装备详情未通过有效库存逐条验收；OneLevel 共享框架、运行时路由与 Snapshot 仍有其他迁移层消费者。依据 `.local/unity-validation/w6-bag-binding-play-20260923.md`、`.local/unity-validation/w6-metadata-consumer-recheck-20260924.md`、`.local/unity-validation/w6-bag-post-cleanup-runtime-20260924.md` 与 `.local/unity-validation/w6-bagflow-unity-node-cache-20260924.md`。不移除任何共享组件或 Prefab 序列化引用）
- [x] W6.6 Bag 首轮页面迁移后通过真实 Play，再进入下一页面；后续每页继续执行相同门禁

W6 收口前待办（2026-09-24，按可验证范围排序）：

1. **W6.3 Snapshot 身份闭环**：90 条 Metadata/序列化引用 path-target 例外（85 个 Metadata 对象无任何序列化引用，5 个通过另一条路径引用）；另有 117 条 Metadata path 与实际 Transform 路径不一致。逐类证明消费者不再需要旧语义身份后，才可退场对应组件；不得全局剥离。依据 `.local/unity-validation/w6-metadata-consumer-recheck-20260924.md` 与 `.local/unity-validation/w6-snapshot-identities-and-editor-log-20260924.md`。
2. **W6.4 零轨道候选**：FengShenStory 的冗余组件已从干净 Prefab 移除，且移除后真实路线回归通过，见 `.local/unity-validation/w6-fengshen-zero-track-timeline-retirement-20260924.md`；Recruitment 的零轨道/关闭与 Raycast 已验证，但 Prefab 有用户未提交修改，保持只读；KunLun（Function ID 7）、OnlineLayer、LilianLayer 当前客户端没有真实可达入口，保留序列化组件，等待合法 Unity 路由证据。按用户确认，被屏蔽功能的 Prefab Metadata 延期，不列为本轮阻塞。依据 `.local/unity-validation/w6-timeline-consumer-recheck-20260924.md`。
3. **W6.5 页面路径绑定**：Bag 页面本体已局部解耦；本轮继续将 `AnswerPresenter` 固定节点、`MainTaskTrackerPresenter` 的 Main_UI 根、`ShopQuantityPresenter` 数量输入框、`ShopPresenter` 商城固定控件、`RewardPresenter` 奖励弹层、`NoticePresenter` 固定节点，以及 `MainHudPresenter` 的主界面/ChatLayer 查找迁至 `CocosUiView.FindNode`。MainTaskTracker 的旧 Prompt/Panel 路径在 Prefab 中均无序列化目标且无 Transform，保持原 null 行为；Main_UI 根路径与序列化目标相同。Shop Quantity 使用节点与 `EnterNumLayer.prefab` 目标一致；用户脏改 Prefab 未写入。Shop Presenter 21 个固定字面路径、Reward Presenter 9 个固定路径、Notice Presenter 5 个固定路径均与对应 Prefab 的 Transform/序列化目标相同。Main HUD 43 条当前路径逐项核对；3 条 Unity 已弃用的在线奖励旧路径在 Prefab 中无目标且保持 null，聊天栏另以 `ChatLayer.prefab` 核对的10条路径均与序列化目标同对象。合并 batch compile 退出码0；仅现有 `UiButtonPressFeedback.animation` CS0108 warning。Shop Presenter/ShopQuantity 当前代码已用真实 EventSystem 完成 Main→Shop→数量弹层→关闭弹层→关闭商城→Main 定向回归；商品 6 行可见、数量维持1、最终 OneLevel/shop_bg 隐藏，Console Error/Warning=0，证据 `.local/unity-validation/w6-shop-path-migration-runtime-20260924.md`。Answer、Reward、Notice、主界面/聊天栏及 MainTaskTracker 尚需按影响范围定向回归。剩余消费者集中在 BagFlow 详情/选项/奖励、OneLevel 共享框架、运行时路由与 Snapshot。须逐页替换并经真实输入回归后再评估移除共享 `CocosUiBinding`，禁止因局部页面完成而删除共享组件。

最近 Unity 状态（2026-09-24）：封神列传真实路线回归后，Play 已停止且 Unity Editor 已正常退出；本轮启动时显式设定 Bootstrap Runner Armed=False。最后一轮 Slot01→Main→Head→Bag 页签真实输入通过；运行时 `BagStore.Items` 返回7种现存道具，无 `ItemType=6`，因此未调用 Use、未构造礼盒弹层数据。封神列传关闭回归 Console error/warning=0。现有礼盒弹层数据限制及记录见 `.local/unity-validation/w6-bagflow-gift-fixture-inventory-recheck-20260924.md`；招募商城与 Bag 详情/共享 Close 路线见 `.local/unity-validation/w6-recruit-shop-bag-close-recheck-20260924.md`。

封神列传零轨道 Timeline 清理续验（2026-09-24）：从干净 C 盘 worktree Play 真实登录 Slot01，经主界面玩法入口进入封神列传。组件从 Prefab 移除后，章节/进度文本仍可见、实例 Metadata=0、Timeline 组件不存在；页面 Close 与共享玩法 Close 均由 EventSystem/Raycast 命中正确目标，最终 Main 恢复、ActivityLayer/shop_bg/OneLevel 隐藏，Console Error/Warning=0。已退出 Play/Editor、Unity MCP 项目覆盖恢复为 `enabled=false`。详见 `.local/unity-validation/w6-fengshen-zero-track-timeline-retirement-20260924.md`。

续验补充（2026-09-24）：在 C 盘 worktree 复现后确认，`Btn_Old` 经 UI 状态稳定后正常打开 Old Memory；Slot01 正常进入 Main。将正式 `1114×3` 夹具写入项目允许的 `Application.persistentDataPath/LocalServer/projectx.db` 后，单机 Slot01 仍启动独立的 `Saves/Slot01/projectx.db`，BagStore 因此没有 1114；未继续礼盒交互。已按原 SHA-256 还原 LocalServer 数据库，完整性 `ok`、残留 0，Slot01 未写入。续验记录：`.local/unity-validation/w6-bag-itemtype6-fixture-target-mismatch-20260924.md`。后续不再重试此不匹配路径；先确认是否有正式账号 UI 路由可合法读取 LocalServer 数据库。

验收条件：页面不依赖 Cocos 路径、首次打开/重复打开/切页/返回均通过；不批量删除迁移脚本。

### W7：Validation 与正式运行逻辑隔离

- [ ] W7.1 盘点 G3-G6、截图、RuntimeSnapshot、Debug Probe、自动输入代码
- [ ] W7.2 将验证入口迁入 `ProjectX.Validation`
- [ ] W7.3 保证 Runtime 不反向依赖 Validation
- [ ] W7.4 建立 Development/Release 编译边界
- [ ] W7.5 验证正式 Build 不包含不必要的验收入口

验收条件：已有验证工具仍可运行；正式运行逻辑不被验证流程污染。

### W8：按功能拆分核心模块

- [ ] W8.1 Login/Startup
- [ ] W8.2 World/Battle
- [ ] W8.3 Hero/Equipment
- [ ] W8.4 Bag
- [ ] W8.5 Shop
- [ ] W8.6 活动玩法

每个模块必须完成：入口、数据、UI、网络/战斗依赖、验证、真实 Play 回归。

### W9：资源与发布治理

- [ ] W9.1 统一资源加载接口，业务层不再直接散落 `Resources.Load`
- [ ] W9.2 对配置、UI、动画、战斗资源进行分组
- [ ] W9.3 评估是否需要 Addressables，不进行全量预迁移
- [ ] W9.4 清理确认无引用的 Unity 包和平台模块
- [ ] W9.5 固定 MCP package 版本
- [ ] W9.6 建立 Release 构建、版本号和构建前检查

验收条件：资源加载路径可追踪；构建可在干净环境复现。

## 三、问题台账

每个问题必须登记一条，不删除历史失败记录。

| ID | 节点 | 首次发现 | 现象 | 复现入口 | 根因 | 处理方案 | 证据文件/日志 | 状态 | 复发预防 |
|---|---|---|---|---|---|---|---|---|---|
| P-0001 | W1.6 | 2026-09-23 | 无 asmdef，Core/UI 与 Core/Validation 形成双向依赖风险 | 静态检查 `using ProjectX.*` 与目录依赖 | 所有源码仍在默认 `Assembly-CSharp`；partial 不产生编译边界 | W3 已冻结依赖图和 asmdef 顺序；W4 逐层拆分并逐次编译 | `docs/unityclient/FRAMEWORK_STATIC_AUDIT.md` §3；`docs/unityclient/FRAMEWORK_W3_DESIGN.md` §7 | diagnosed/deferred | 增加依赖图检查，禁止 Validation 反向引用 Runtime Core |
| P-0002 | W1.1/W1.6 | 2026-09-23 | 全局组合根和 `ProjectXApp` 过载 | 静态阅读 `GameServices`、ProjectXApp partial 与 Startup 生命周期 | 一个 MonoBehaviour 同时承担启动、协议、Lua、Store、Presenter、共享 UI 和验证 | 框架稳定后按已有 partial/业务域最小抽取，本轮不拆分 | `FRAMEWORK_STATIC_AUDIT.md` §3 | diagnosed/deferred | 新模块登记 owner、Store、Presenter、验证边界 |
| P-0003 | W2.1-W2.7 | 2026-09-23 | Prefab 普遍依赖 Cocos 绑定/路径/Timeline，共享节点可残留 | 静态搜索组件 GUID、路径、SetActive/Sibling/监听 | 迁移兼容层是已验收页面基础，共享容器无统一 owner 状态模型 | 先做只读台账和共享 Frame 试点；真实 Play 后再处理单页退场 | `FRAMEWORK_STATIC_AUDIT.md` §4；`UI_MERGE_GUIDE.md` | diagnosed/deferred | 删除前完成路径引用、编译、Play、回归和反向引用审计 |
| P-0004 | W0.3 | 2026-09-23 | 外部 Unity/MCP 进程曾指向 E 盘原 checkout（用户主动启动，现已关闭） | 只读检查进程命令行和端口；用户确认归属 | 用户主动启动，不是项目阻塞 | 标记为非项目问题，不进入后续门禁；不再处理 | `FRAMEWORK_STATIC_AUDIT.md` §2.1；用户 2026-09-23 确认 | deferred | 运行阶段只记录当前 checkout 的进程归属 |
| P-0005 | W0.3 / Mail 真实验收 | 2026-09-23 | 初始 checkout 尚无启动/真实 Play 基线；首次直接 Play 未完成稳定切换 | 初始静态审计未启动运行环境；直接 Play 未先打开 Bootstrap/Runner；改用 Runner 后当前 worktree 已进入 Bootstrap Play；Mail 参数启动时 `LocalServerSupervisor` 已持有 `kapai.exe` 且 `127.0.0.1:8711` 已监听 | 编译通过不能替代启动、输入和玩家可见 UI 证据；Mail 真实登录/主界面/入口输入仍未完成 | W0 启动基线以当前 worktree 的编译、Bootstrap、登录画面和本地服务证据收口；Mail 真实入口输入继续作为独立页面验收，不宣称 Mail 功能通过；不把 `-projectXExternalServer` 诊断路径当作本地服务通过 | `mail-editor-mailvalidation.log`；`unityclient/Captures/mail-w0-3-bootstrap-login-local-server.png`；`.local/unity-validation/mail-w4-compile-after-lfs.log` | diagnosed/deferred | 运行前先打开 Bootstrap 并使用 Runner；分别记录 Editor、Play、真实输入、本地服务和页面证据 |
| P-0006 | W4.3 | 2026-09-23 | Unity 首次导入当前 worktree 报告 3097 个资源读取错误；抽样文件为 128-130 字节 Git LFS 指针文本 | `unityclient` batch 导入日志；抽样资源头为 `version https://git-lfs.github.com/spec/v1` | 当前 worktree 的部分资源内容未 hydration | 已按正式链路执行 `git-lfs pull origin main --include='unityclient/Assets/ProjectX/**'`；指针数 3097→0，复验资源读取错误为 0 | `.local/unity-validation/mail-w4-compile-after-lfs.log`；LFS 指针扫描 | verified | 运行前检查 LFS/资源完整性并记录缺失清单 |
| P-0007 | W4.4 | 2026-09-23 | Foundation 消息读取契约首次编译失败，Data 解析器仍调用 `ReadBytes(int)` | Foundation 抽取后 Unity MCP 脚本编译 | 初版 `IProtocolMessageReader` 漏列现有消息读取方法 | 增补 `ReadBytes(int)`，保持 LegacyTcpMessage 原实现 | `.local/unity-validation/w4-foundation-interface-compile.md` | verified | 抽取接口前枚举全部消费者方法；以 Unity 编译确认契约闭合 |
| P-0008 | W4.4 | 2026-09-23 | Data 仍反向依赖 Network 消息类型和 Diagnostics 日志，不能按目标顺序直接加 Data asmdef | `rg` 检查 `src/Data` 的跨层引用 | `WorldBattleReplayStore` 解析 `LegacyTcpMessage`；多处 Catalog/Config 调用 `ClientLog` | 消息读取依赖改为 Foundation 契约；日志独立为无 ProjectX 引用的 Diagnostics 叶程序集；Data 已无 Network/Core/UI 跨层引用并编译通过 | `FRAMEWORK_W3_DESIGN.md` §4；`WorldBattleReplayStore.cs`；`ProjectX.Data.asmdef` | verified | 每个 asmdef 前做跨层引用扫描，不以目录名推断依赖 |
| P-0009 | W4.4 | 2026-09-23 | Network 拆分后 Core 无法调用 `LegacyTcpMessage(byte[])` | Unity 当前 Editor 编译 | 构造器此前为 `internal`，拆程序集后仅 Network 内可见 | 将包络读取构造器开放为 `public`，保持数据读取和解析逻辑不变；复编译通过 | `LegacyTcpMessage.cs`；Unity Editor 编译输出 | verified | asmdef 边界建立后检查跨程序集调用点和可见性 |
| P-0010 | W4.4 | 2026-09-23 | UI 最初有多项 Core 类型依赖，不能建立禁止反向引用的独立 asmdef | 扫描并尝试编译 UI asmdef | UI 依赖资源、时间、存档与解锁 Catalog；存档和 Catalog 的定义错误地留在 Core | UI 改用 `IUiResourceProvider`/`IServerTimeProvider`；`SinglePlayerSaveService` 与 `FunctionUnlockCatalog` 归入 Data；UI asmdef 已建立且编译通过，UI 运行时代码无 Core 引用 | `ProjectX.UI.asmdef`；`IUiAssetProvider.cs`；Data 源码；`.local/unity-validation/w4-ui-asmdef-compile.md` | verified | 界面只依赖 consumer-side 能力；配置与持久化逻辑归 Data |
| P-0011 | W4.4 | 2026-09-23 | UI asmdef 建立后 Core 验证器无法访问 `VirtualListScrollDragRelay` | Unity Editor 编译 | Relay 在 UI 程序集为 internal，但 Core 验证代码需要识别动态创建组件 | 将 Relay 类型设为 public，组件行为与挂载方式不变；复编译通过 | `UI/VirtualList.cs`；`.local/unity-validation/w4-ui-asmdef-compile.md` | verified | 对跨程序集反射/验证使用类型检查的运行时组件显式设置可见性 |
| P-0012 | W4.5 | 2026-09-23 | Unity Editor 导入日志对若干未修改 `.cs.meta` 报 line-11 YAML 解析消息 | 当前 C worktree Unity 导入与 Console | 旧 meta 的空 `assetBundleName:`/`assetBundleVariant:` 字段触发该解析器消息；MonoScript 实际加载与类型解析均成功 | 未改动 clean meta；Unity `AssetDatabase.LoadAssetAtPath<MonoScript>` 与 `GetClass()` 对 4 个文件均返回正确类型和 GUID | `.local/unity-validation/w4-ui-asmdef-compile.md` | verified | 出现元数据解析消息时检查 Unity AssetDatabase 的实际 GUID/类型映射，不仅看文本日志 |
| P-0013 | W4.4 | 2026-09-23 | LuaRuntime 初始 asmdef 候选包含 `FirstPlayableLoopBridge`，其直接依赖 UI/Network | 扫描 LuaRuntime 源文件并编译隔离程序集 | 该 MonoBehaviour 是面向 FirstPlayableLoop 场景的集成测试桥，不属于 Lua runtime 核心服务 | 将桥移到 Core 默认程序集边界，保留 namespace 和 GUID；ProjectX.LuaRuntime 只依赖 Diagnostics、XLua，编译通过 | `.local/unity-validation/w4-luaruntime-asmdef.md` | verified | 区分第三方 runtime、运行时服务与集成测试桥，再划分 asmdef |
| P-0014 | W4.5-Core | 2026-09-23 | 首次建立 Core asmdef 后，RuntimeSnapshotCollector 编译报 4 个 CS1061，找不到 Network、Player、Options 成员 | C worktree Unity `refresh_unity(if_dirty, compile=request)` | `GameServices` 改为窄 `IRuntimeSnapshotContext` 后，Collector 的事件订阅和失败记录仍残留旧的具体服务访问 | 将剩余点改为 `PacketObserved`、PlayerName/RoleId、LocalUserId 等契约属性；再次 Unity refresh/compile 通过，首轮失败保留在证据记录中 | `.local/unity-validation/w4-core-asmdef.md` | verified | 接口签名切换后扫描全部读取/错误路径，并以 Unity 编译结果确认闭合 |
| P-0015 | W4.4-Editor | 2026-09-23 | Editor asmdef 建立后，Settings 页更改分辨率时反射查找 BootstrapAppRunner 会失效 | 扫描 `Type.GetType` 程序集限定名；Unity `execute_code` 确认新类型所在程序集 | 调用点硬编码旧 `Assembly-CSharp-Editor` 名 | 优先查 `ProjectX.Editor`，旧程序集名保留为 fallback；Editor 编译通过，Unity Type.GetType 实际解析到 `ProjectX.Editor.BootstrapAppRunner` | `.local/unity-validation/w4-validation-editor-asmdef.md` | verified | 改程序集边界时检查反射字符串和 Unity Assembly-CSharp 特例 |
| P-0016 | W5.3 | 2026-09-23 | `VirtualList<T>.Dispose` 清理内容与监听后未恢复构造期间修改的模板显隐、ScrollRect 配置及既有 Graphic Raycast | C worktree 列表所有权审查及 Unity Editor 定向编译 | Dispose 只销毁 VirtualContent 并退订滚动监听，构造时却可能新增/改写组件与状态 | Dispose 现在恢复模板、既有 ScrollRect 与 Graphic 状态，仅销毁由列表创建的 ScrollRect、Mask、Graphic 和动态内容；Unity 编译 0 错误 | `.local/unity-validation/w5-virtual-list-lifecycle.md` | verified | 动态组件须记录所有权，释放时只销毁自有节点并恢复外部组件原值 |
| P-0017 | W4.5 | 2026-09-24 | Windows Player build 后处理抛出 `InvalidOperationException: Code has not been generated, may be not work in phone!`，但 BuildReport 成功 | Unity MCP `manage_build`，StandaloneWindows64，Bootstrap | `XLua.Generator.CheckGenerate` 检查 `DelegateBridge.Gen_Flag` 为 false；当前未找到生成的 XLua delegate bridge source | Windows64 Mono Player 已生成并运行；将代码生成/AOT 兼容性留到 Android/iOS/IL2CPP 门禁，不压制后处理异常 | `.local/unity-validation/w4-player-build-startup-20260924.md`；Unity `Editor.log` | diagnosed/deferred | 任何移动或 IL2CPP 构建前必须生成并验证 XLua wrappers/delegate bridge，不能只看 BuildReport 成功 |
| P-0018 | W6.3 | 2026-09-24 | 同一 `execute_code` 调用内连续开页并立刻关闭时，关闭控件 RaycastAll 返回 0 hits | Main Metadata clean Play route sequence；细节见 W6.3 验收记录 | 页面显隐回调已同步执行，但同帧内新界面 Canvas/Layout 尚未完成更新，下一次 Raycast 过早 | 丢弃同帧批量操作状态，干净 Play 重登后按“点击→独立帧检查层级/first-hit→独立点击关闭”分步重跑；Gameplay、商城、招募回归通过 | `.local/unity-validation/w6-metadata-consumer-recheck-20260924.md` | verified | Unity MCP真实页面验收在每次显隐变化后等待稳定帧并先Inspect首个命中，不在一个同步ExecuteCode方法内串接页面开关 |
| P-0019 | W6.5 | 2026-09-25 | Unity 脚本编译后的 Play UI 仍可见、EventSystem 存在，但 `ProjectXApp.Instance=null/services=null` | HeroPresenter Unity 路径迁移后的 scripts-only refresh | Unity domain reload 清空组合根静态实例及非序列化服务；旧 UI 不能证明业务回调仍有效 | RuntimeInputDispatcher 在实际 Dispatch 前增加 singleton 前置检查；本次 compile 后真实 Hero 路线保留待验，未重启用户 Play/账号 | `.local/unity-validation/w6-heropresenter-unity-path-migration-20260925.md` | diagnosed | 活跃真实 Play 期间避免触发脚本刷新；刷新后只读确认 Instance 与服务状态，缺失时不点旧 UI、不循环重登，等待下一次合法 Play 窗口再做受影响路线验收 |
| P-0020 | W6.5 | 2026-09-25 | Unity 功能测试的数据库路径说明与交互式 SinglePlayer 源码分流不一致 | 对照 Editor 命令行、`AppLaunchOptions`、`SinglePlayerSaveService`、LocalServer 进程参数 | 无 `-projectX` 参数的 Editor 选择 Saves/SlotNN；`LocalServer/projectx.db` 属于 `CreateDefault()` 非 SinglePlayer 路径，不能将二者当作同一存档 | 普通 Editor 默认改走 LocalServer；显式 `-projectXSinglePlayerFlowValidation` 仍保留 Slot 流程。编译及 `ShouldUseSinglePlayerTitle=false` 实时反射通过；待一次新 Play 核验实际服务路径 | `.local/unity-validation/w6-singleplayer-database-path-contract-20260925.md` | diagnosed | 每次写夹具或启动有状态验收前，以实际启动参数与 LocalServer 命令行交叉核验路径；不只根据 Editor 展示画面推断档案归属 |
| P-0021 | W6.5 PlayerHub 显示验收 | 2026-09-25 | 选中 Bag 页签时金色选中背景显示但标签缺失 | C 盘当前编译版同一 Play；真实 EventSystem 点击 `Button2_Runtime` 后读取 `ChooseBg`、`ChooseBg/BtnName` 显隐 | `SetTabText` 只更新 chosen Text 内容，未启用其 GameObject；运行时克隆沿用模板隐藏态 | `SetTabText` 同步设置 selected label 的 active 状态；一次编译后为 domain reload 造成的 `ProjectXApp.Instance=null` 执行受控 Play 恢复；重新真实点击并复核 Bag/Mail/Settings 的节点状态、业务页状态与屏幕截图通过，Console error/warning=0 | `UI/PlayerHubTabCoordinator.cs`；`.local/unity-validation/w6-runtime-presenter-route-batch-20260925.md`；Bag/System captures | verified | 共享页签验收同时断言选中背景、选中/普通文字的 activeInHierarchy 与实际画面；运行态脚本刷新后先检查 ProjectXApp singleton/services，失效时仅恢复一次再复测受影响路径 |
| P-0022 | W6.3 90条 Snapshot identity runtime readback | 2026-09-25 | 首轮 MCP 探针未能匹配克隆节点的 Prefab source local fileID，不能执行身份回读 | C 盘当前 Play；对10个源 Prefab 的 Metadata 与运行时实例做对应 | `GetCorrespondingObjectFromSource` 的克隆映射不适用于该层级；首版探针还用了 CodeDom 不支持的 `JToken.Value<T>` 扩展调用；两者均在调用退场方法前失败 | 改为在源 Prefab 上按 asset local fileID 精确找 Metadata，再以 sibling-index 路径映射隐藏的运行时实例；使用兼容的 `Convert` 解析 JSON。最终真实退场784个临时 Metadata，90/90目标的 Snapshot semanticId/nodeType/source 退场前后完全相同，90/90别名保留；清除临时实例及784条静态 identity 后原字典计数恢复202，Console error/warning=0 | `.local/unity-validation/w6-identity-snapshot-runtime-readback-20260925.md`；`.local/unity-validation/w6-snapshot-exception-inventory-20260925.json` | verified | Unity MCP CodeDom 探针应先用一个源 asset row 验证 asset fileID 与 clone sibling-index 映射；失败若发生在任何项目运行时变更前，记录为 probe 构造问题，不重启 Play |

问题状态：`open`、`diagnosed`、`fixed`、`verified`、`deferred`、`blocked`。

同一签名问题再次出现时，必须优先修复公共工具、预检或文档，不重复临时绕过。

## 四、每个节点的固定收口格式

完成节点时必须记录：

```text
节点：W?.?
状态：完成/阻塞/延期
范围：
涉及文件：
未修改文件：
验证命令或真实入口：
验证结果：
新增问题：P-xxxx
已解决问题：P-xxxx
遗留风险：
下一节点：
```

## 五、当前执行顺序

当前新任务从以下顺序开始：

```text
W0 → W1 → W2 → W3 → W4 → W5 → W6 → W7 → W8 → W9
```

第一轮实际工作范围限定为：`W0、W1、W2`。
完成静态基线和 Prefab/UI 台账后，再决定 W3 的最小实现范围。

## 六、第一轮节点收口

| 节点 | 状态 | 日期 | 涉及文件 | 验证结果 | 遗留问题 |
|---|---|---|---|---|---|
| W0.1 | 完成 | 2026-09-23 | `AGENTS.md`、`UNITYCLIENT_STATUS.md`、`ProjectVersion.txt`、`EditorBuildSettings.asset` | checkout、HEAD、Unity 版本、启用场景、目标/禁止范围已冻结；未启动运行环境 | 无 |
| W0.2 | 完成 | 2026-09-23 | `UNITYCLIENT_STATUS.md`、模块文档、Prefab 路径 | 已标记 FishLayer、HeroRebirth、XunBao、HeroEquip/EnhanceMaster 等保护资源；当前 Git 脏文件无业务重叠 | 无 |
| W0.3 | 完成 | 2026-09-23 | `UNITYCLIENT_STATUS.md`、`ProjectXApp.Startup.cs`、`BootstrapAppRunner.cs`、Mail batch 编译日志、Unity/MCP运行日志、Bootstrap登录截图 | 当前 checkout 脚本编译 0 错误、资源导入 0 读取错误；Runner Bootstrap Play、GameView 1334×750、LocalServerSupervisor 本地服务和登录画面证据已在当前 worktree 保存并核验。Mail 真实入口验收仍未完成，继续由 P-0005 跟踪，不计作本节点通过条件 | P-0005（Mail 真实入口验收待完成） |
| W0.4 | 完成 | 2026-09-23 | 本计划、`FRAMEWORK_STATIC_AUDIT.md` | 白名单限定为文档/台账；禁止业务源码、Prefab、`.meta`、用户资源和迁移状态改动 | P-0001-P-0003、P-0005；P-0004 已排除 |
| W1.1 | 完成 | 2026-09-23 | `GameServices.cs`、`ProjectXApp.Startup.cs`、`Bootstrap.unity` | 固定 Bootstrap → ProjectXApp → GameServices 的全局生命周期和销毁链 | P-0002 |
| W1.2 | 完成 | 2026-09-23 | `Network/`、`LuaRuntime/`、`LocalServerSupervisor.cs`、`ResourceService.cs`、`ServerTimeService.cs`、`SinglePlayerSaveService.cs` | 固定网络、协议、Lua、资源、时间、本地服务、存档的静态职责与边界 | P-0002 |
| W1.3 | 完成 | 2026-09-23 | `Data/`、`GameServices.cs`、各 Store/Catalog/Config 源码 | 统计 Data 目录 53 个 C#，区分 Store、Catalog、Config/Model 和 Resources 配置读取 | P-0002 |
| W1.4 | 完成 | 2026-09-23 | `UiRouter.cs`、`UiStack.cs`、`UiPrefabLoader.cs`、`ResourcesUiAssetProvider.cs`、`UI/` | 固定 Router/Stack/Presenter/View/PrefabLoader/Catalog 的实际调用方向和动态加载责任 | P-0003 |
| W1.5 | 完成 | 2026-09-23 | `Core/`、`UI/`、`Data/`、`Network/`、`Validation/`、`Editor/` | 形成按 `using ProjectX.*` 与直接调用的依赖清单；确认 UI↔Core、Validation↔Core 循环风险 | P-0001、P-0002 |
| W1.6 | 完成 | 2026-09-23 | `FRAMEWORK_STATIC_AUDIT.md` §3 | 形成当前依赖图，标记无 asmdef、GameServices/ProjectXApp 过载和迁移兼容边界 | P-0001、P-0002 |
| W2.1 | 完成 | 2026-09-23 | `Resources/UiPrefabs/Catalog.asset`、`Resources/UiPrefabs/*.asset`、`res/csd/Prefabs/` | 统计 359 Prefab、133 Catalog 条目、Catalog parentKey/defaultActive 分布和 CSD/Prefab/Reference 链 | P-0003 |
| W2.2 | 完成 | 2026-09-23 | `OneLevelLayer.prefab`、`CommonPageLayer.prefab`、`shop_bg.prefab`、`huodong_bg.prefab` | 固定共享页框节点、CommonPageLayer 未入 Catalog 的事实、关闭/页签/遮罩风险 | P-0003 |
| W2.3 | 完成 | 2026-09-23 | `beibao.prefab`、`MailLayer.prefab`、重点 Reward/Shop Presenter、`VirtualList.cs` | 固定 ItemCell/TableView/ListView/Content 和 Bag/Mail/Reward/Shop Cell 差异；不强行合并业务 Cell | P-0003 |
| W2.4 | 完成 | 2026-09-23 | 重点 Prefab、UI Presenter、`VirtualList.cs` | 记录 Tab、ListView/TableView、ScrollRect、Loading/Empty/Error 分散控制和分页缺少统一组件的事实 | P-0003 |
| W2.5 | 完成 | 2026-09-23 | UI/Core Presenter 源码 | 统计 SetActive/Instantiate/Destroy/Sibling/Listener/Raycast/ScrollRect 使用面，记录 DynamicUi/Runtime/VirtualRow 挂载约定 | P-0003 |
| W2.6 | 完成 | 2026-09-23 | `CocosUiBinding.cs`、`CocosNodeMetadata.cs`、`CocosTimelinePlayer.cs`、359 个 Prefab | 确认 Binding 359、Metadata 357、Timeline 27 个 Prefab 文件依赖 | P-0003 |
| W2.7 | 完成 | 2026-09-23 | `FRAMEWORK_STATIC_AUDIT.md` §4、`UNITYCLIENT_STATUS.md`、模块文档 | 标记 UiStack/Router/Provider/VirtualList 可先适配；FishLayer 等用户 Prefab、迁移绑定和共享页框暂不可动 | P-0003 |
| W3.1-W3.6 | 完成 | 2026-09-23 | `FRAMEWORK_W3_DESIGN.md`、`GameServices.cs`、`ProjectXApp.cs`、Validation/UI 静态依赖 | 冻结组合根、层次依赖、窄接口、Feature 模板、asmdef 顺序和 Validation/Editor 隔离策略；未创建 asmdef、未改源码 | P-0001、P-0002 |
| W4.1 | 完成 | 2026-09-23 | `Core/GameServices.cs`、`Core/ProjectXApp.Startup.cs` | `GameServices` 继续作为唯一组合根，构造与释放顺序不变；Dispose 重入安全，Dispose 后 Tick 不推进；当前 Editor 脚本编译 0 错误、3 个警告 | 无 |
| W4.2 | 完成 | 2026-09-23 | `FRAMEWORK_W3_DESIGN.md` §3、§5 | 固定 Initialize → Tick → ShuttingDown → Dispose 所有权；`ProjectXApp` 为宿主、`GameServices` 为唯一组合根；不新增 `AppScope` 类型或静态服务定位器 | P-0002（后续逐功能拆分） |
| W4.3-Mail | 完成 | 2026-09-23 | `UI/IUiResourceProvider.cs`、`UI/MailPresenter.cs`、`UI/ItemQualityVisual.cs`、`Core/ResourceService.cs` | Mail/品质资源消费窄接口已接入；真实输入回归留在 W5.8 | P-0005 |
| W4.4-Foundation→Gameplay | 完成 | 2026-09-24 | Foundation、Diagnostics、Data、Network、UI.Migration、Animation、UI、Gameplay、LuaRuntime、Core、Validation、Editor 十二个 ProjectX asmdef；XLua runtime/editor 两个 asmdef；接口解耦、Data catalog/save 迁移、`FirstPlayableLoopBridge.cs` 移动、Gameplay 路由决策抽取 | Unity 2022.3.62f3c1 Editor 编译与 Windows x64 Player build 成功；Gameplay 只依赖 Data；MonoScript GUID/类型映射保留 | 只覆盖当前 Windows64 Mono；XLua AOT 代码生成见 P-0017 |
| W4.5-Foundation→Gameplay | 完成 | 2026-09-24 | 上述 12 个 ProjectX asmdef 与 XLua runtime/editor；Unity Editor 编译及 Player 脚本编译 | Unity 构建报告成功；Player scripting assemblies 已重编译后打包；登录页/主界面运行验收见 W4 Player smoke | Editor 构建后处理抛出 XLua codegen Exception（P-0017）；保存快照恢复仍待验收 |
| W4.4-Core | 完成 | 2026-09-23 | `Core/ProjectX.Core.asmdef`、`Core/ProjectXApp.Startup.cs`、`Core/GameServices.cs`、`Core/RuntimeInputDispatcher.cs`（由 Validation 移入并保留 GUID）、`Validation/RuntimeSnapshotCollector.cs` | 以 `IRuntimeSnapshotContext` 和服务就绪通知去除 Core 对 Validation Collector 的直接编译引用；Core asmdef 建立，Unity refresh/compile 成功，`ProjectX.Core.dll` 生成 | Validation dispatcher 当前随 Core 编译；其正式隔离留给 W7。启动、快照回放、Player build 尚未验证 |
| W4.5-Core | 完成 | 2026-09-23 | 上述 Core asmdef 和接口变更；证据 `.local/unity-validation/w4-core-asmdef.md` | 首编译的 4 个 CS1061 错误保留于 P-0014；收敛剩余旧接口访问后再次 refresh/compile，Editor idle、0 编译错误；Console 两条 CS0618 均来自用户脏 `NormalizeSharedUiSprites.cs` | 非 Play 编译验收；Validation/Editor asmdef 与运行时行为仍待完成 |
| W4.4-Validation | 完成 | 2026-09-23 | `Validation/ProjectX.Validation.asmdef`、`Validation/RuntimeSnapshotCollector.cs`、Core `IRuntimeSnapshotContext` 与服务就绪通知 | Validation → Core/Network/UI.Migration 单向依赖；Collector 不再持有 GameServices；Unity 生成 `ProjectX.Validation.dll` | RuntimeInputDispatcher 暂在 Core；正式隔离待 W7 |
| W4.5-Validation | 完成 | 2026-09-23 | 上述 Validation asmdef；证据 `.local/unity-validation/w4-validation-editor-asmdef.md` | Unity refresh/compile 成功；`ProjectX.Validation.dll` 41,472 bytes；Console 0 编译错误 | 快照启动/真实输入回放未运行 |
| W4.4-Editor | 完成 | 2026-09-23 | `Editor/ProjectX.Editor.asmdef`、`UI/SettingsPresenter.cs` 反射程序集名兼容 | Editor-only asmdef 引用 Core、Animation、LuaRuntime、Network、UI、UI.Migration、Unity.ugui；修正 BootstrapAppRunner 反射程序集名，保留旧名 fallback | User-dirty `NormalizeSharedUiSprites.cs` 未修改 |
| W4.5-Editor | 完成 | 2026-09-24 | 上述 Editor asmdef；证据 `.local/unity-validation/w4-validation-editor-asmdef.md`、`.local/unity-validation/w4-player-build-startup-20260924.md` | Unity refresh/compile、Windows Player build 成功；Player 启动且无运行时异常；Editor 登录和本地服务连通通过 | XLua `CheckGenerate` codegen 异常只表明未验证 AOT/移动；Editor Play 内存档快照和 1334×750 设置回环已在 `.local/unity-validation/w4-save-snapshot-resolution-roundtrip-20260924.md` 验证；独立 Player 全屏窗口仍未验证 |
| W4-Bootstrap Play smoke | 部分验证 | 2026-09-24 | `Bootstrap.unity`、截图 `Captures/w4-bootstrap-login-play-20260924.png`、`Captures/w4-old-memory-entry-20260924.png`、`Captures/w4-playerhub-relogin-20260924.png`；证据 `.local/unity-validation/w4-player-build-startup-20260924.md` | Bootstrap 登录标题页可见；真实 EventSystem 进入已有 Slot02 后主界面可见，OneLevelLayer 初始未显示；LocalServerSupervisor 回收上次遗留服务并启动 PID 47896，Unity 进程连至 `127.0.0.1:8711`；当前 Console Error 0 | 登录写入了正常会话元数据/SQLite 时间戳；快照复制/登录恢复及 Slot03 清理见 `.local/unity-validation/w4-save-snapshot-resolution-roundtrip-20260924.md`；Player 游戏画面仅以进程与 Player.log 做启动 smoke |
| W4.5-Windows Player build/startup | 部分验证 | 2026-09-24 | `.local/framework-player-gate-20260924/ProjectX.exe`、`Player-startup-smoke.log`；Bootstrap 场景；截图同上 | BuildReport succeeded，3456.31 MB/130.4 s；单机 Player 存活 12 s 后正常关闭；Player.log 初始化 Unity 2022.3.62f3c1、Input、D3D11；Editor Play 登录 Slot02、本地服务连接正常 | Editor Play 快照/分辨率回环通过（见 `.local/unity-validation/w4-save-snapshot-resolution-roundtrip-20260924.md`）；Player 仅启动 smoke，独立交互、全屏及全量页面未验收；P-0017 移动/AOT codegen 延期 |
| W5.1-W5.2-PlayerHub | 完成 | 2026-09-24 | `UI/PlayerHubTabCoordinator.cs`、`UI/CocosUiView.cs`、`Core/ProjectXApp.cs`、`Core/ProjectXApp.JingJie.cs`、`Core/ProjectXApp.MainUiBindings.cs`、`Core/ProjectXApp.Bag.cs`；运行证据 `.local/unity-validation/w5-playerhub-tabs-acceptance-20260924.md` | Bootstrap Play 真实 Raycast/EventSystem 连续切换境界→背包→邮件→系统，页内容互斥显隐，邮件空态与设置面板可见；页签 sibling 固定为 0–3；关闭后主界面/云层恢复，主界面境界入口再次打开可恢复境界页。Canvas 共享层 sibling 7 固定。Console Error 0；只有已有 LocalServer 残留服务回收 Warning；无业务写操作 | 无；SystemLayer 仍是设置内容页，不与 Mail Presenter 合并 |
| W5.3-List lifecycle | 完成 | 2026-09-23 | `UI/VirtualList.cs`；证据 `.local/unity-validation/w5-virtual-list-lifecycle.md` | 明确泛型 `bind(row,item,index)` 作为 Cell 绑定契约；Dispose 退订监听、销毁自有动态内容、还原模板状态和既有 ScrollRect/Graphic 原值，只销毁自身新增组件；当前 Unity Editor 脚本编译 0 错误 | 动态数量、监听数和 Raycast 的真实运行态稳定性尚未验收，保留在 W5.8 |
| W5.4-Pagination contract | 完成 | 2026-09-23 | 本计划 W5.4 设计约定；`UI/VirtualList.cs` 的现有职责边界 | 固定本地分页为完整快照切片、服务端分页由 Store/Presenter 驱动请求及结果状态；两者不共用错误的全量数据假设，VirtualList 仅承担视口虚拟化；当前无服务端分页消费者，暂不增加空抽象 | 仅完成契约设计；需在 W5.7 选定试点时确认该页是否实际需要分页 |
| W5.5-UiStateView contract | 完成 | 2026-09-23 | 本计划 W5.5 设计约定；既有 Presenter Loading/Empty/Error/Content 使用盘点 | StateView 只投影显隐已存在节点，retry 与文案归 Presenter/Store，不创建虚假状态节点或改变 sibling 顺序；刷新是否保留旧 Content 由调用方决定 | 仅完成契约设计；运行时状态显隐需由 W5.7/W5.8 试点证明 |
| W5.6-Cell reuse contract | 完成 | 2026-09-23 | 本计划 W5.6 Cell 职责表；Bag/Mail/Reward/Shop Presenter 与 Prefab 静态盘点 | 固定四类 Cell 的展示复用边界；网络、领取/购买、选择、使用和弹窗行为继续归各业务 Presenter；不合并业务数据形状 | Bag 试点采用其已有业务格子，不因抽象而替换 Prefab Cell |
| W5.7-Bag pilot | 完成 | 2026-09-23 | `UI/BagPresenter.cs`、PlayerHub Bag 共享页框、现有 Bag Prefab；真实 Play 证据 `.local/unity-validation/w5-bag-play-acceptance-20260923.md`、截图 `Captures/w5-bag-select-20260923-01.png` | C worktree 主界面真实 Raycast/EventSystem 进入境界/背包；Bag 显示 8 条、2 个列表行，首条可选中并更新详情；关闭返回主界面，重复进入后页框/列表恢复。未点击 Use 等写操作，未改 Prefab。Console 有 itemId=1105 缺图警告；用户确认是待清理垃圾数据，本次排除 | W5.8 已通过；保留旧 preflight 作为未到主界面的历史证据 |
| W5.8-Bag Play | 完成 | 2026-09-23 | Unity MCP `EventSystem.RaycastAll` + `ExecuteEvents`；`.local/unity-validation/w5-bag-play-acceptance-20260923.md`；截图 `Captures/w5-bag-select-20260923-01.png` | 真实点击主界面境界入口、PlayerHub 背包页签、首个背包格、境界页签、关闭与重复进入；页签 sibling 固定为 0–3，境界/背包显隐互斥，OneLevelLayer 关闭后隐藏且重进恢复，列表为 8 项/2 行；Console 无错误，重复记录的 1105 缺图警告按用户说明排除 | 真实输入未覆盖 PlayerHub 的 Mail/System 与其他页面；继续 W6.2 仅迁移 Bag 自有内容绑定 |
| W6.1-Cocos 依赖首轮盘点 | 完成 | 2026-09-23 | `UI/CocosUiView.cs`、`UI/Migration/CocosUiBinding.cs`、`UI/Migration/CocosNodeMetadata.cs`、`UI/Migration/CocosTimelinePlayer.cs`、13 个匹配符号的 UI C# 文件；证据 `.local/unity-validation/w6-cocos-reference-inventory.md` | Assets Prefab GUID 引用计数：Binding 359、Metadata 357、Timeline 27；已定位 Timeline/ActionTag 查找链及 HeroEquipmentPresenter 的直接 Metadata 读取。只做引用盘点，无 Prefab/源码删除 | W5 Bag Play 已通过；逐页推进 W6.2，不批量删除 |
| W6.2-Bag binding | 完成 | 2026-09-23 | `UI/BagPageBinding.cs(.meta)`、`UI/BagPresenter.cs`、`Core/ProjectXApp.BagUi.cs`；证据 `.local/unity-validation/w6-bag-binding-play-20260923.md`、截图 `Captures/w6-bag-binding-repeat-20260923-01.png` | Bag Presenter 改接 Unity GameObject/Transform；BagPageBinding 只挂载运行时实例，按实际 `beibao_layer`/`Panel_12` 层级缓存控件。Unity Editor 编译 0 错误；Play 首次/重复打开、8 项/2 行、真实选中、关闭返回、固定 tab sibling 顺序均通过；未改 Prefab | CocosUiBinding 仍由导入资源与其他页面使用；W6.3-W6.5 不可全局移除 |
| W6.6-Bag Play gate | 完成 | 2026-09-23 | `.local/unity-validation/w6-bag-binding-play-20260923.md`、`Captures/w6-bag-binding-repeat-20260923-01.png` | 对 Bag 页面执行干净 Play 重启后从主界面真实入口打开、选中、关闭并重复进入；共享页框、Bag 绑定、列表行数与固定页签顺序恢复 | 下一页面须单独盘点依赖与真实入口，再修改与验收 |
| W6-UI hierarchy Play regression | 完成 | 2026-09-23、2026-09-24 | `.local/unity-validation/ui-hierarchy-runtime-acceptance-20260923.md`；`.local/unity-validation/w6-metadata-consumer-recheck-20260924.md`；`.local/unity-validation/w6-gameplay-frame-mask-recheck-20260924.md`；截图 `Captures/w6-cultivate-before-return-20260924.png`、`Captures/w6-enhance-master-after-return-20260924.png`、`Captures/w6-main-after-enhance-return-20260924.png` | 强化大师→装备强化页→返回、神将→主界面真实 EventSystem 回归通过；旧 `HideDetails()` NRE 已有可选视图空值保护。另复现 Gameplay 的 `ActivityLayer=6` / `shop_bg=7` 遮挡：Mask 4000×4000、alpha 0.8，点击卡片先命中 Mask。调整玩法内容根层级后重新编译并干净重启 Play；实际 `btn_wanfa` 路线显示 ActivityLayer=8、shop_bg=7，EnterBtn 首个 Raycast 命中；封神列传返回玩法框架、再返回主界面，两层均正确隐藏。MCP 截图错误保留为历史工具错误；2026-09-24 当前 live Console 重新读取 Error=0，未清空 Console | MCP Play 截图工具故障与业务 UI 分离记录；W6.3-W6.5 仍在进行，W6 整体未完成 |

| W6.3-Metadata consumer recheck | 进行中 | 2026-09-24 | `UI/HeroEquipmentPresenter.cs`、`UI/Migration/CocosUiBinding.cs`、`UI/MainHudPresenter.cs`、`UI/ShopPresenter.cs`、`UI/DrawPresenter.cs`、`UI/SettingsPresenter.cs`、`Core/RuntimeInputDispatcher.cs`、`Validation/RuntimeSnapshotCollector.cs`；证据 `.local/unity-validation/w6-metadata-consumer-recheck-20260924.md`；Prefab GUID 扫描 | HeroEquipmentPresenter 的异常诊断改用 Unity Transform 路径；MainHudPresenter、ShopPresenter、DrawPresenter 分别在初始化/首轮渲染后，仅对对应页面运行实例调用 `RetireLegacyNodeMetadataAtRuntime()`；SettingsPresenter 完成 `Refresh()` 后对当前设置页实例退场 Metadata。干净 Play 现有 Slot01 登录后主界面 Metadata=0/193 refs；10 个 HUD Button Raycast 10/10。商城 0/98 refs、18 商品、6 行，真实选择 Item2 并数量 1→2→1，未购买；关闭后主界面与共享层恢复。招募页面 0 Metadata，Popup1/2/3 同时 active，关闭按钮真实 EventSystem first hit 命中并返回主界面；未执行招募/领取。PlayerHub 系统页 Metadata 28→0、23 refs 保留；7 个控件均解析，SaveDisplay/FullScreen/Dropdown Raycast 命中。真实 CloseBtn 命中后 OneLevel 隐藏、主 HUD 恢复。Gameplay→关也已通过。Console Error 0；用户 Prefab未修改。Binding 通用 Metadata fallback、RuntimeInputDispatcher 路径快照、RuntimeSnapshotCollector 采集仍在用；Metadata GUID 仍序列化在 357 个 Prefab 文件 | 继续迁出剩余真实运行时消费者；只有消费者闭合后才评估组件全局退役/Prefab 清理 |
| W6.3-Bag runtime Metadata retirement | 页面级运行时退场完成，资产清理未完成 | 2026-09-24 | `UI/BagPageBinding.cs`；证据 `.local/unity-validation/w6-metadata-consumer-recheck-20260924.md`；未修改 `res/csd/Prefabs/zhujue/beibao.prefab` | BagPageBinding 使用 Unity Transform 完成控件绑定后，在 Play 中对实例子树销毁 Metadata。干净 Play 从现有 Slot01 真实进入 PlayerHub/Bag；实例 Metadata 115→0，CocosUiBinding 的 Source 与 53 个节点引用仍保留；Bag 行控件 Raycast first hit、关闭、同一实例重复打开和再次关闭通过；Console 无 Error。`1105` 已知垃圾数据警告按用户要求排除 | 仍保留 Prefab 序列化引用及 Binding/Dispatcher/Snapshot 的全局消费者；继续逐页迁移，不动 Prefab |
| W6.3-Shop runtime Metadata retirement | 页面级运行时退场完成，资产清理未完成 | 2026-09-24 | `UI/ShopPresenter.cs`、`UI/Migration/CocosUiBinding.cs`；证据 `.local/unity-validation/w6-metadata-consumer-recheck-20260924.md`；商城 Prefab 未修改 | ShopPresenter 完成绑定及首轮渲染后，对商城运行实例调用 Metadata 退场。干净 Play 现有 Slot01：商城 0 Metadata/98 serialized refs、18 商品、6 行；真实 EventSystem 选择 Item2、数量 +/− 为 1→2→1，未点击 Buy；真实 Close 后 IsShopOpen=false、商城与 shop_bg 隐藏、主界面恢复。编译/运行 Error=0。先前 Play 中脚本热重载导致旧绑定失效的尝试已丢弃，以重启后的稳定 Play 为准 | 仅完成页面级运行态验证；继续迁出 Binding/Dispatcher/Snapshot 消费者。保留 Prefab Metadata 序列化状态 |
| W6.3-Recruitment runtime Metadata retirement | 页面级运行时退场完成，资产清理未完成 | 2026-09-24 | `UI/DrawPresenter.cs`、`UI/Migration/CocosUiBinding.cs`；证据 `.local/unity-validation/w6-metadata-consumer-recheck-20260924.md`；用户修改的招募 Prefab 未写入 | DrawPresenter 完成绑定与首轮渲染后，仅对招募页运行实例退场 Metadata。Unity 脚本编译完成；干净 Play 通过主界面招募入口的实际 EventSystem 输入打开，运行实例 Metadata=0、Popup1/2/3 同时 active；实际 CloseBtn first hit 命中并关闭回主界面，OneLevel/shop_bg 保持隐藏。未触发招募/领取；Console Error=0，存在一条 LocalServer 崩溃遗留服务回收 Warning，与页面无关 | 运行态只证明招募页实例；保留用户 Prefab及序列化 Metadata。继续验证 Presenter 后续状态调用并迁出 Binding/Dispatcher/Snapshot 的全局消费者 |
| W6.3-Continue save-selection runtime Metadata retirement | Continue 模式页面级退场完成；其他存档模式未覆盖 | 2026-09-24 | `UI/OldMemoryPresenter.cs`；证据 `.local/unity-validation/w6-metadata-consumer-recheck-20260924.md`；未修改 Login/OldMemory Prefab | 仅 `SinglePlayerSaveMenuMode.Continue` 在 `RenderSlots()`/`ShowSlots()` 后对运行实例退场 Metadata。干净 Play 真实点击 `Btn_Old` 打开存档列表，`DynamicUi_OldMemoryLayer` active、Metadata=0；真实点击 Slot_01 `Btn_Enter` first hit 命中并进入已有存档，旧存档层关闭、主界面 active 且 Metadata=0；Console Error=0。未写存档数据 | NewGame 与 SaveCurrent 模式未验证，故不扩大退场范围；保留 Prefab 序列化 Metadata 与全局兼容消费者 |
| W6.3-Settings runtime Metadata retirement | 页面级运行时退场完成，Prefab 未修改 | 2026-09-24 | `UI/SettingsPresenter.cs`；证据 `.local/unity-validation/w6-metadata-consumer-recheck-20260924.md`；未修改 `zhujue/SystemLayer.prefab` | `SettingsPresenter.Refresh()` 完成路径绑定与设置值刷新后，仅对当前 SystemLayer 运行实例调用 Metadata 退场。干净 Play 由真实 EventSystem 从主界面打开 PlayerHub、点击标记“系统”的 Button4_Runtime；Settings=true，SystemLayer Metadata 28→0、23 个 serialized refs 保留。音乐/音效 Toggle 与 Slider、Resolution Dropdown/FullScreen、Btn_6 共 7 项均通过 `CocosUiBinding.Find` 解析；Btn_6、FullScreen、Dropdown 三处 Raycast first-hit 命中。未更改设置或保存显示偏好。真实 CloseBtn 关闭后 Settings=false、OneLevel 隐藏、Main HUD 恢复且 Metadata=0；Console Error=0。Prefab 未修改 | 仅关闭 SystemLayer 页面实例的 Metadata；`Btn_6`/Resolution 存在旧 CocosPath 与当前 Transform 命名差异，保留序列化组件并继续审查通用路径/快照消费者 |
| W6.3-global Metadata consumer boundary | 进行中/全局删除条件未满足 | 2026-09-24 | `UI/Migration/CocosUiBinding.cs`、`UI/Migration/CocosTimelinePlayer.cs`、`Core/RuntimeInputDispatcher.cs`、`Validation/RuntimeSnapshotCollector.cs`、`tools/unity-migration/runtime-scenarios/draw.json`；证据 `.local/unity-validation/w6-metadata-consumer-recheck-20260924.md`、`.local/unity-validation/w6-snapshot-ancestor-identity-audit-20260924.md`、`.local/unity-validation/w6-snapshot-ancestor-runtime-mapping-20260924.md`、`.local/unity-validation/w6-snapshot-ancestor-classification-20260924.md` | Dispatcher 现按完整 Unity path→序列化 `CocosNodeReference`→binding-relative `Transform.Find`（含虚拟 `Layer/` 前缀兼容）→旧 Metadata CocosPath alias 的顺序解析；Metadata=0 的真实 Main 上 `Layer/Bg/btn_zhaomu` Raycast/click 打开招募，Popup1/2/3 同时 active，真实 Close 返回 Main，Console Error=0。Draw 首动作已改为真实可达 `Layer/Bg/btn_zhaomu`。运行时 Timeline 使用序列化 ActionTag；186/186 唯一轨道 ActionTag 可解析到非空目标。全量只读扫描 19,690 个 Metadata 记录：19,600 同路径同目标、90 个例外；按运行时守卫的路径/目标冲突优先级分类为 5 个目标已有异路径引用、48 个路径已指向其他目标、37 个可尝试祖先派生，其中 7 个可精确映射、30 个语义路径不一致。干净 Play 经真实 Slot01 登录、玩法打开/关闭后，Main HUD Metadata=0、Binding refs 193→199；Collector 实际身份索引验证 6 个路径精确映射，`btn_wanfa` 既有目标引用保留。其余别名与设备神铸候选运行路径仍未闭合 | 继续审查剩余路径别名与运行时重挂；对 48 个路径冲突及 30 个语义不同项保留 Metadata fallback；对设备神铸 Item_bg 需等待合法可达条件后再回归；保留所有 Prefab，不做批量清理 |
| W6.3-Timeline serialized ActionTag consumer closure | 完成/运行时消费关闭，资产 Metadata 保留 | 2026-09-24 | `UI/Migration/CocosUiBinding.cs`、`UI/Migration/CocosTimelinePlayer.cs`；只读扫描全部 359 个 Prefab；运行证据 `.local/unity-validation/w6-metadata-consumer-recheck-20260924.md` | 新增 `FindSerializedActionTag`，运行时 Timeline 不再调用 Metadata fallback；旧 `FindActionTag` 保留给 Editor 导入校验。27 个 Timeline Prefab 共 461 条轨道记录、186 个按组件去重的 ActionTag（全局 183 个不同值），186/186 均解析到同对象绑定节点的非空 target。干净 Play 现有 Slot01：活动主界面云层 4 条 Timeline 轨道全部通过 serialized-only lookup；运行实例 Metadata 6→0 后，IsPlaying 保持 true、frame 237→886、四个云层 Transform 坐标继续变化；编译后运行证据记录 Error=0。Prefabs、`.meta`、存档均未改 | 只关闭 Timeline 运行时对 Metadata 的依赖；不移除 `CocosTimelinePlayer` 或序列化 Metadata，不代表其他路径/快照消费者已闭合 |
| W6.3-Main UI runtime Metadata retirement | 运行时实现及定向 Play 通过，Prefab 未修改 | 2026-09-24 | `UI/Migration/CocosUiBinding.cs`、`UI/MainHudPresenter.cs`；证据 `.local/unity-validation/w6-metadata-consumer-recheck-20260924.md`；未修改 `UImainLayer_new.prefab`、`chouka/shenjiangzhaomu.prefab` | MainHudPresenter 初始控件绑定与首轮渲染完成后只退场 Main HUD 实例 Metadata。干净 Play 现有 Slot01 登录：主界面 Metadata 202→0、序列化节点引用193保留、活跃 Button 射线命中10/10。真实入口 Gameplay→关、商城打开/关闭、招募（Popup1/2/3同时显示）→关均通过；OneLevel/shopBg恢复，live Console Error=0；云层 Metadata/Timeline 保留 | 只对该 HUD 实例生效；不全局移除组件或修改 Prefab，其他页面消费者和357份序列化组件继续按 W6.3/W6.4盘点 |
| W6.3-Gameplay ActivityLayer runtime Metadata retirement | 页面级运行时退场完成，Prefab 未修改 | 2026-09-24 | `UI/GameplayPresenter.cs`；证据 `.local/unity-validation/w6-gameplay-metadata-retirement-20260924.md`；未修改 `common/ActivityLayer.prefab` | Prefab 只读基线 25 Metadata/25 exact same-target-path-type refs，0 未引用节点。Presenter 首轮绑定/渲染后只退场 ActivityLayer 实例；干净 Play 真实路线下 ActivityLayer Metadata=0、refs=25，shop_bg 共享框架仍保留 22 Metadata，ActivityLayer sibling=8 高于 shop_bg=7。动态玩法卡片文本可见，Function_3 EnterBtn EventSystem first hit 命中自身并实际打开封神列传；重复打开仍 0 Metadata/25 refs；框架关闭返回 Main，Console Error=0 | 不移除 Prefab 序列化组件；其他共享内容/Timeline/RuntimeSnapshot consumers 继续按 W6.3/W6.4 逐页评估 |
| W6.3-FengShenStory runtime Metadata retirement | 页面级运行时退场完成，Prefab 未修改 | 2026-09-24 | `UI/FengShenStoryPresenter.cs`；证据 `.local/unity-validation/w6-fengshen-metadata-retirement-20260924.md`；未修改 `fengshenliezhuanlLayer.prefab` | Presenter 完成首轮绑定/渲染后，仅对本次运行实例调用 Metadata 退场。Prefab 只读基线 Metadata=106、Binding refs=106、Timeline=0 tracks/1 clip；真实主界面→玩法→封神列传后，实例 Metadata=0、refs=106，章节及阶段文本可见，Timeline 未播放。Close 首个 Raycast 命中实际 CloseBtn 并返回玩法；框架关闭后主界面恢复，未挑战、领奖或改存档 | 继续保留 Prefab 序列化 Metadata；动态后续刷新与 RuntimeSnapshot fallback 仍按全局 W6.3 证据跟踪 |
| W6.3-Hero Info runtime Metadata retirement | 页面级运行时退场与选将/关闭回归完成，Prefab 未修改 | 2026-09-24 | `UI/HeroPresenter.cs`；证据 `.local/unity-validation/w6-hero-info-metadata-retirement-20260924.md` | `Render()` 首轮绑定后仅退场 Hero Info 实例 Metadata；真实主界面→神将→Hero_11_1 选中→关闭路线通过，Raycast 首击命中各目标，详情名/技能/属性文本可见更新；详情 Metadata=0、序列化 Binding refs=103，Hero List 仍保留 103 Metadata。关闭后 Main HUD 恢复、OneLevel 与 shop_bg 隐藏；当前 Console 无 Error。未执行消耗操作 | 继续保留 Prefab 序列化组件、Hero List Metadata 与共享层；RuntimeSnapshot fallback 和剩余页面继续按 W6.3 逐页审计 |
| W6.3-Hero Cultivation page/shell runtime Metadata retirement | 页面与壳层运行时退场及五页真实切换/关闭回归完成，Prefab 未修改 | 2026-09-24 | `UI/HeroCultivationPresenter.cs`；证据 `.local/unity-validation/w6-herocultivation-shell-metadata-retirement-20260924.md`、`.local/unity-validation/w6-herocultivation-metadata-retirement-20260924.md`；可见截图 `.local/unity-validation/w6-herocultivation-shell-metadata-retired-20260924.png` | 首屏绑定/渲染后培养壳 Metadata 24→0，24/24 同路径同目标序列化引用保留且 `Binding.Find` 全部命中。干净 Play 的五页均 Metadata=0、refs=82/55/54/70/61；每次真实页签点击后 sibling 固定0–4、射线命中自身。`duiwu`/左右切换按钮在壳 Metadata=0 后 Raycast Inspect 通过。两次真实关闭回 Main，OneLevel 和 shop_bg hidden，Console Error=0。无 Prefab、存档或道具更改 | W6.3 全局仍受 RuntimeSnapshot 未绑定/动态节点身份、90 个路径/target 例外及其余页面约束 |
| W6.4-Timeline component inventory | 进行中 | 2026-09-24 | `UI/Migration/CocosTimelinePlayer.cs`；证据 `.local/unity-validation/w6-timeline-consumer-recheck-20260924.md`、`.local/unity-validation/w6-recruitment-visual-20260924.md`、`.local/unity-validation/w6-fengshen-zero-track-timeline-retirement-20260924.md`；Prefab GUID `1adb1cbe63b222847b80234c3bd855ae` | 当前剩余 26 个 Prefab 文件挂载该组件；22 个有 Timeline 轨道，4 个无轨道。封神列传的 0 轨道/1 空 clip 组件已从 Prefab 移除，移除后真实 Slot01→btn_wanfa→Function_3/EnterBtn 路线章节/进度文本可见，EventSystem Close 返回玩法、共享框架 Close 返回主界面，Console Error/Warning=0。招募页零轨道/关闭、并行 Popup Raycast 和 1334×750 GameView 截图已验证，Popup1/2/3 同时显示且无页签；用户 Prefab保持只读。当前主界面云层 Timeline 实际播放 | 3 个零轨道候选仍无法从当前 Unity 真实入口到达：KunLun、OnlineLayer、LilianLayer；不伪造状态或调用内部 Presenter，不移除其序列化组件。确认可达候选的页面级退场另行逐页验证 |
| W6.4-FengShenStory zero-track route | 完成（冗余序列化组件已移除） | 2026-09-24 | `.local/unity-validation/w6-timeline-consumer-recheck-20260924.md`、`.local/unity-validation/w6-fengshen-zero-track-timeline-retirement-20260924.md`；`UI/FengShenStoryPresenter.cs`、Prefab `fengshenliezhuan/fengshenliezhuanlLayer.prefab` | PrefabUtility 基线确认 0 tracks/1 空 clip/`playOnEnable=false`，删除后 Git diff 仅该组件。移除后真实 Slot01→btn_wanfa→Function_3/EnterBtn 页面正常显示章节与进度文字，runtime Metadata=0；实际 EventSystem Close 返回玩法、共享框架 Close 返回 Main，Console Error/Warning=0 | W6.4 仍需评估其余零轨道候选；招募用户修改 Prefab 只读，KunLun/OnlineLayer/LilianLayer 等待合法真实 Unity 路由 |
| W6.4-KunLun route availability | 未通过/待后续真实入口 | 2026-09-24 | `.local/unity-validation/w6-timeline-consumer-recheck-20260924.md`；`GameplayPresenter.cs` 当前运行时列表 | 从主界面真实 EventSystem 进入玩法页，当前存档列表含 9 个实际入口，但不含 function_id=7；未调用内部 Presenter、未改数据、未碰 Prefab；通过实际 `shopBg/Popup/Btn_close` 返回主界面 | KunLun 零轨道候选无法由当前存档的真实入口验收；待未来自然可达入口或已有存档状态支持后再复核 |
| W6.4-OnlineLayer route availability | 未通过/当前 Unity 无入口 | 2026-09-24 | `.local/unity-validation/w6-timeline-consumer-recheck-20260924.md`；`client/ProjectX/src/View/MainUI.lua`、`OperationalActivity/OnLine.lua`；Unity `ProjectXApp.cs`、`WelfarePresenter.cs` | Unity Play 主场景无 `btn_online`/OnlineLayer 实例；Unity welfare 绑定 LoginGiftLayer，兼容路径隐藏旧入口。Cocos 在线按钮在可领取时会走发奖分支，未点击或领取；无 Unity 真入口可供该候选 Play 验收 | 不触发可能领奖的 Cocos 分支；保持 Prefab 和数据不变，不因静态无 Unity 引用直接移除组件 |
| W6.4-LilianLayer route availability | 未通过/当前 Unity 无入口 | 2026-09-24 | `.local/unity-validation/w6-timeline-consumer-recheck-20260924.md`；`client/ProjectX/src/View/Activity/LiLianUI.lua`；Unity `GameplayPresenter.cs` 当前实时列表 | 主界面→玩法真实入口显示九个功能，文案中无历练/Lilian；当前 Unity C# 无 LilianLayer 绑定，未调用内部页面方法、未改存档或 Prefab | 等待自然可达 Unity 入口；当前不以 Cocos Lua 源存在或 Prefab 序列化组件推断可安全删除 |
| W6.4-Recruitment runtime route | 运行态与可见结果验收完成，Prefab 只读 | 2026-09-24 | `.local/unity-validation/w6-recruitment-visual-20260924.md`；截图 `.local/unity-validation/w6-recruitment-live-20260924.png`；旧运行态证据 `.local/unity-validation/w6-timeline-consumer-recheck-20260924.md` | 真实 `btn_zhaomu` Raycast 首击命中；GameView 截图 1334×750 直观显示 Popup1/2/3 同时可见、无页签；三个 `Btn_Recruit_1` 的只读 Inspect 首击分别命中自身；未派发招募/领奖/购买；实际 Title/CloseBtn 命中后回到 Main。Timeline 0 tracks/0 clips、未播放。当前 Console 无 Error；item 1105 Warning 按用户说明排除。用户 Prefab 未写入 | 保留用户 Prefab；此项证明运行态与可见层级，不表示所有招募业务行为或 Prefab 清理完成 |
| W6.5-Bag/Hero Enhance Master/Equipment Strength cross-page regression | 本轮路线回归完成；W6.5 总体仍进行中 | 2026-09-24 | `UI/HeroPresenter.cs`、`UI/BagPresenter.cs`、`UI/HeroEquipmentPresenter.cs`、`UI/BagFlowPresenter.cs`；证据 `.local/unity-validation/w6-shared-frame-cross-page-posthero-20260924.md`、`.local/unity-validation/w6-bag-unavailable-jump-runtime-20260924.md`、`.local/unity-validation/w6-bag-quantity-keypad-runtime-20260924.md`、`.local/unity-validation/w6-bag-itemtype6-runtime-fixture-check-20260924.md` | 干净 Play 现有 Slot01：Main→PlayerHub 背包→关→神将→强化大师→素心刀装备强化页→返回大师→返回神将→Main 全部使用真实 EventSystem/Raycast。Bag Metadata=0/refs=53，PlayerHub 页签 sibling 固定0–3；培养壳 sibling=6、anchor `(0,0)`、size `(1334,750)`；Strength/Refine/Awaken/Divine 与两个法宝内容兄弟索引0–5固定。Refine/Strength 页签点击只切内容显隐，页签顺序不变。装备页用 OneLevel CloseBtn 返回大师，大师 Popup Close 返回神将，OneLevel Close 返回 Main；最终共享层隐藏。BagFlow 已通过体力丹行→Use→数量键 `2`→删除清空→关闭的真实 Raycast/EventSystem 链；数量弹层显示从空值到`2`再回占位文本，最终 EnterNum 隐藏、Bag/OneLevel active、库存仍为3、App 单例有效；未触发确认。另测 Bag `UseJump=1080` 不可用项时显示“当前版本暂未开放”，保持 Bag/OneLevel 与数量110。清洁 Play 重启后真实 Slot01→主角→背包路线显示7组库存、无 `ItemType=6`；Bag Metadata=0/refs=53；未触发使用，真实共享关闭返回 Main 后 OneLevel/shop_bg 隐藏。Console Error=0，仅 LocalServer 回收 Warning(pid=4912)。历史5条截图工具 Error 留存为工具事故，不计业务错误 | Bag `ItemType=6` 奖励选择弹窗没有合法库存夹具；不伪造数据，等待自然存在道具或授权固定夹具。继续完成剩余 W6.3 消费者与 W6.4 可达性证据；商城由用户自行验收 |
| W6.5-Bag UseJump 1140 awakening route | 完成该路由；W6.5 总体仍进行中 | 2026-09-24 | `Core/ProjectXApp.cs`、`unitydata/export/client/source/Configs/function-routes.json`、`Resources/ProjectXData/Configs/function-routes.json`；证据 `.local/unity-validation/w6-bag-itemjump-1140-awakening-runtime-20260924.md` | Slot01 真实背包 UseJump 1140 曾选中第一件品质2装备，导致 Awakening Presenter 因品质门槛>=5拒绝显示；最小修复为 mode2 选首件品质>=5的装备。清洁 Play 后真实 Raycast 进入觉醒页：选中 uid=2123071489/quality6，觉醒内容 active，物品854数量仍5；共享 Close 返回装备列表，再 Close 返回 Main，最终 OneLevel/shop_bg 隐藏。Console Error=0，只有 LocalServer 孤儿回收 Warning(pid=52148)；未消耗物品、未改存档/Prefab/`.meta` | 不执行觉醒或消耗材料；ItemType=6 奖励选择弹窗无合法当前夹具，W6.3/W6.4及其余W6.5消费者仍未收口 |
| W6.5-BagFlow EnterNum quantity binding | 输入弹窗子项完成；W6.5 总体仍进行中 | 2026-09-24 | `UI/BagFlowPresenter.cs`；证据 `.local/unity-validation/w6-bagflow-input-unity-path-retirement-20260924.md` | EnterNum 的数字键/删除/确认/关闭等输入控件改由 Unity Transform 路径解析；运行时 22/22 精确 Metadata 在绑定后退场，保留 22 条序列化引用。干净 Play 的 Slot01 真实 Raycast 路线打开体力丹（数量3）输入弹窗，Metadata=0；点击 2 显示`2`，删除恢复`请输入数量`，关闭隐藏弹窗且库存仍3；共享 Close 返回 Main、OneLevel/shop_bg hidden。Console Error=0，仅 LocalServer 回收 Warning(pid=48684)。未确认使用、未改存档/Prefab/`.meta` | 只完成数量输入子项；礼包奖励、来源、装备详情等 BagFlow 弹窗及共享框架仍依赖迁移层，继续逐个消费者验证 |
| W6.5-BagFlow cached Unity node resolution | 局部绑定迁移与数量弹层定向 Play 通过；W6.5 总体仍进行中 | 2026-09-24 | `UI/BagFlowPresenter.cs`、`Core/ProjectXApp.Bag.cs`；证据 `.local/unity-validation/w6-bagflow-unity-node-cache-20260924.md` | BagFlowPresenter 的 `CocosUiBinding.Find` 调用已清零；固定节点按 view 使用 Unity Transform 路径解析并缓存，保留 `Layer/` 虚拟前缀。Bag G4 礼盒列表验证路径不再自行 Find，改由 Presenter 暴露缓存 `GiftScroll`。Unity 编译无错误；真实 Slot01→Main→PlayerHub→Bag 并检查 `valid=true`、14个模态按钮、3/3 ScrollRects，GiftScroll/content/viewport 均非空；Close 回 Main，Console Error/Warning=0 | ItemType=6 礼盒选项、来源与装备详情缺少本轮真实库存逐项操作证据；CocosUiView/Metadata身份及其他OneLevel、路由、Snapshot消费者仍待迁移，不据此移除Prefab组件 |
| W6.5-OneLevelFrameCoordinator fixed-node path cache | Standard、Fish 与共享层可见运行；Fish→玩法列表返回通过，玩法→Main 后 Main_UI 未恢复，整项阻塞于该缺陷 | 2026-09-25 | `UI/CocosUiView.cs`；编译 `.local/unity-validation/w6-onelevel-transform-cache-compile-20260924.md`、`.local/unity-validation/w6-onelevel-transform-cache-compile-20260924.log`；Fish 运行 `.local/unity-validation/w6-fish-onelevel-runtime-20260925.md` | Standard 页在 PlayerHub Settings 与玩法商店中真实显示/关闭通过。Function32 Fish 真实进入后 `Fish/217 ready`、FishLayer active、OneLevel active，未开钓；Fish Close 返回玩法列表。但关闭玩法后 OneLevel/shop_bg/Activity/Fish 均隐藏、UiStack.Current=mainView、AppState=Main，实际 `Main_UI` 仍 inactive，入口不可用。Console error/warning=0；`CocosUiBinding.Find` 与 `CocosUiView.FindNode` 对 Main_UI 指向同一对象；已定位可见性恢复路径待查，不把该错误归因于路径解析，也不计本节点通过 | 找出真实 Raycast Close 后 Main_UI 仍 inactive 的根因，最小修复并按实际入口复验；随后补 Fish 与 FengShenStory 模式的可视截图及同路径 Cocos 对照，再收敛其他共享消费者 |
| W6.5-CocosUiView shared Unity-path resolver | FishPresenter 固定节点页已进入 Play；Gameplay Close 后 Main_UI 未恢复，待根因与修复；跨引擎对照未完成 | 2026-09-25 | `UI/CocosUiView.cs`、`UI/FishPresenter.cs`；编译 `.local/unity-validation/w6-shared-view-unity-path-cache-compile-20260924.md`、`.local/unity-validation/w6-shared-view-unity-path-cache-compile-20260924.log`；运行 `.local/unity-validation/w6-fish-onelevel-runtime-20260925.md` | `FindNode` 路径成功解析并显示 Fish 页面；旧 Binding 与新 resolver 对 Main_UI 返回同一 Transform。Fish.Close 恢复玩法列表，Main_UI 的退出可见性缺陷发生在后续 Gameplay Close；不能据此判定 resolver/Presenter 运行通过。没有启动或收集鱼、没有修改库存 | 修复并复验 Gameplay Close 的 Main_UI 恢复；重新核对 Fish 页面可见结果；补当前同账号/同步骤 Cocos 对照后才收口此共享 resolver 子项 |
| W6.5-Settings shared OneLevel and exact SystemBg bindings | 固定路径迁移与 Unity batch 编译通过；Settings 路线需复验 | 2026-09-24 | `UI/SettingsPresenter.cs`；证据 `.local/unity-validation/w6-settings-shared-frame-path-cache-20260924.md`、`.local/unity-validation/w6-settings-onelevel-unity-path-compile-20260924.log` | SettingsPresenter 的共享 OneLevel 显隐、标题/货币文字、页签模板、加号按钮、音乐/音效 Toggle/Slider、Resolution Dropdown、FullScreen、头像、显示保存及其他 Settings 点击目标全部改用 `CocosUiView.FindNode`/`BindClickNode`，源码无 `CocosUiBinding.Find`/通用 `BindClick`。Prefab YAML target-to-hierarchy 审计确认改动路径与原引用/回退顺序目标一致；Unity batch 编译 exit 0、无 C# 错误。首次缩减 binding 字段时出现 CS0103，随后将遗留文本路径迁移后移除字段，最终编译通过，详见证据。之前 Settings Play 证据发生在此改动前，需复验后才验收 | 重走主界面→PlayerHub→系统页→关闭回 Main；真实运行路径回归后才计完成。 |
| W6.5-PlayerHubTabCoordinator fixed panel path | 境界、背包、邮件、系统四个真实 Raycast 页签及 Close/Back 已复验 | 2026-09-25 | `UI/PlayerHubTabCoordinator.cs`；编译证据 `.local/unity-validation/w6-playerhub-tab-cache-compile-20260924.md`、`.local/unity-validation/w6-playerhub-tab-cache-compile-20260924.log`；运行时证据 `.local/unity-validation/w6-playerhub-tab-settings-runtime-20260925.md` | C 盘 worktree 当前 Unity Play 中由主角 Head 真实 Raycast 打开 OneLevel；四个 Tab 顺序为 sibling 0–3，`VisibleTabCount=4`。背包页真实打开且 Bag 根 active；邮件页状态为 `Merged player hub mail active`；系统页真实打开，`SettingsPresenter.ValidateIdentityAndHeader=True`（role 1000001、S8D01、level 102）。真实 Close 返回 Main，OneLevel/shop_bg/Activity 均隐藏；Console error/warning=0。未领取邮件、未修改库存、未改 Prefab/`.meta` | 共享解析器其他消费者、Snapshot/Metadata 全局例外和 W6.4 范围仍需分别闭环；该记录不代表 W6 收口。 |
| W6.5-TaskPresenter fixed list paths | Unity 单侧固定路径真实输入回归通过；跨引擎对照待补，W6.5 总体仍进行中 | 2026-09-24 | `UI/TaskPresenter.cs`；`.local/unity-validation/w6-task-presenter-path-cache-compile-20260924.md`、`.local/unity-validation/w6-task-presenter-path-cache-compile-20260924.log`、`.local/unity-validation/w6-task-presenter-path-runtime-20260924.md`、截图 `.local/unity-validation/w6-task-presenter-runtime-20260924.png` | Task Presenter 的 Viewport/Item 模板固定路径改用 `CocosUiView.FindNode`；RenwuLayer Prefab 只读 target-to-hierarchy 核对两路径与原序列化目标相同。当前代码下 Unity 真实 Gameplay→每日任务路线显示7条动态任务，截图1334×750；不领取、不前往。真实任务 Close 保留 Activity，Gameplay Close 恢复 Main 且 OneLevel/shop_bg 隐藏；Console Error/Warning=0 | 仍缺同账号/数据/步骤/分辨率的 Cocos 对照截图及差异报告；另有 MainTaskTracker、Reward、Notice、MainHud/Chat、其他共享和 Snapshot 消费者待逐项验收。 |
| W6.5-GameplayShopItemInfoPresenter fixed paths | Unity 真实来源详情与两级关闭路线通过；跨引擎视觉对照待补 | 2026-09-25 | `UI/GameplayShopItemInfoPresenter.cs`；编译/静态证据 `.local/unity-validation/w6-gameplay-shop-iteminfo-path-cache-compile-20260924.md`、`.local/unity-validation/w6-gameplay-shop-iteminfo-path-cache-compile-20260924.log`；真实路由 `.local/unity-validation/w6-gameplay-shop-iteminfo-path-runtime-20260925.md` | Main 商店→将魂商店（真实 Raycast）显示 `/221 type=2` 的6条正式商品；真实点击 `ShopUI/Mine/jianghun/add` 打开 SourceLayer，显示“神将魂魄 / 来源：抽卡”，动态来源入口存在。真实关闭 SourceLayer 后商店仍开；再关闭商店后 Main active，OneLevel/shop_bg/ActivityLayer 隐藏，`IsGameplayShopOpen=false`，Console error/warning=0。未购买、刷新或进入抽卡 | 尚无当前同账号、同步骤的 Cocos/Unity 视觉差异报告；来源按钮通往抽卡的后续路线本轮未进入，按计划不得触发抽卡。W6.5/W6 总体继续进行。 |
| W6-gameplay frame Mask order | 完成 | 2026-09-24 | `Core/ProjectXApp.MainUiScreens.cs`；证据 `.local/unity-validation/w6-gameplay-frame-mask-recheck-20260924.md` | 真实复现 `ActivityLayer` 卡片被高 sibling 的全屏 Mask 遮罩并拦截 Raycast；ShowGameplay 增加内容根 sibling 顺序约束。脚本编译通过，干净 Play 从主界面进入玩法后，ActivityLayer sibling 8、shop_bg sibling 7，Function_3 EnterBtn 首个 Raycast 命中；关闭封神页/玩法页回到主界面状态恢复 | 继续保留页签固定 sibling 顺序；这次只调整共享页面根节点，不改 Prefab |

### W6.3 Unity error and Slot01 inventory cleanup — 2026-09-24

- Unity Error `xlua.dll` 与 `XLua.Runtime.asmdef` 同名冲突根因是 asmdef assembly name=`XLua`；改为 `XLua.Runtime`，同步 3 个显式 asmdef 引用。`Assets/Refresh` 后编译完成，Console Error=0；保留 `NormalizeSharedUiSprites.cs` 两条 CS0618 警告。Unity Editor 完整重启后旧 `On demand scheduler protocol error`/corrupted-header 记录未复现，Slot01 服务端日志无对应记录。
- 按用户授权，从 Slot01 角色 1000001 的压缩背包中删除一个 1105×2 堆叠，保存包变更前使用 SQLite backup API 备份；完整性检查通过，剩余 11 个堆叠与原始序列一致。当前配置将 1105 映射到“锻造礼盒”/pic 3104，原运行警告却报告 picture=0；此角色数据按用户的垃圾数据说明清除。后续真实 Play 已重新加载 Slot01，背包显示其余 7 个当前可见物品，选择“转盘钥匙”后名称/描述正确更新，Console Error/Warning=0；详见 `.local/unity-validation/w6-bag-post-cleanup-runtime-20260924.md`。
- **后续状态更正**：首次重启 Play 一度停在登录页且 `ProjectXApp.Instance/services` 未初始化；没有通过内部 Presenter 绕过输入。之后 Play 稳定后通过真实 `旧的回忆`→Slot01 `进入游戏`恢复主界面并完成上述背包复测。不得把首次启动失败当作当前 UI 未验证，也不得覆盖其历史记录。
- 修改文件：4 个 XLua/ProjectX `.asmdef`；存档仅改 Slot01 `role_info.package`；Prefabs 与 `.meta` 未改。证据 `.local/unity-validation/w6-error-log-and-item-cleanup-20260924.md`。

### W6 error-log cross-page recheck — 2026-09-24

- 当前 C 盘 Play 使用真实 EventSystem 完成：Slot01 → PlayerHub Bag → 关闭 → 神将 → 强化大师 → 素心刀装备强化 → 强化大师 Popup Close → 神将 Close → Main。背包运行实例 `DynamicUi_beibao` 为 active，Metadata=0、序列化 refs=53；返回设备强化页后 Master 与共享框架状态正确；关闭神将后 `DynamicUi_OneLevelLayer=false` 且 Main HUD active。
- `Editor.log` 中 Bag `Require('DynamicUi_beibao/Layer/beibao_layer')` 为旧版按完整 Layer 路径查找的历史异常；当前 `BagPageBinding` 在实例后代按 `beibao_layer` 节点名解析，本次真实入口无复现。`HeroEquipmentPresenter.HideDetails()` 历史 NRE 本次关闭强化页与神将页时均未复现。Live Console Error=0；仅有用户指定忽略的 `itemId=1105` 缺图 Warning。
- 强化大师隐藏 OneLevel 子项时，正确关闭控件在 `DynamicUi_shop_bg/shopBg/Popup/Btn_close`，Raycast 首命中自身并关闭回神将；隐藏的 OneLevel Close 被全屏 `shop_bg/Mask` 命中是对非活动控件的探测结果，不是实际交互链缺陷。未改源码、Prefab、`.meta` 或存档。

### W6.3/W6.4 live consumer recheck — 2026-09-24

#### Current Bag Play recheck — 2026-09-24

- 正式 Unity MCP (`127.0.0.1:8080/mcp`) 绑定 `unityclient@fdf120ee5ce0f719`。Main→`btn_jingjie`→PlayerHub Bag 页签的两次 Raycast first-hit 均命中真实 Button；Bag 运行实例 active、Metadata=0、Binding refs=53。共享 `Panel_12/Title/CloseBtn` first-hit 命中并关闭，返回 Main，`DynamicUi_OneLevelLayer=false`、主 HUD active；GameView 截图和复测报告见 `.local/unity-validation/w6-bag-current-play-recheck-20260924.md`。
- 本轮实际路由后的 Console Error=0；三条 `itemId=1105` 缺图 Warning 按用户说明忽略。MCP 传输探测造成的 4 条 framing Error/8 条 Assert 已单独存证，见 `.local/unity-validation/w6-mcp-transport-probe-incident-20260924.md`；清空后重新完成上述 UI 路由。

- 当前 C 盘实例 `unityclient@fdf120ee5ce0f719` 的 Play 遥测仍卡在旧 `playmode_transition` 标记，但 MCP 运行时查询与真实 EventSystem Raycast 可用；没有把遥测阶段字段当作页面验收结论。
- 从 Main 实际点击 `btn_wanfa` 后，当前玩法页仍只显示 9 个入口，Function IDs=`1,3,9,10,21,23,27,29,32`；KunLun/7、OnlineLayer、LilianLayer 本次仍无可达入口。实际点击 Function_3 打开封神列传，运行实例 `CocosTimelinePlayer` 为 0 tracks/1 clip/`IsPlaying=false`；真实 Close 返回玩法页，玩法 Popup Close 返回 Main，OneLevel、ActivityLayer 和 `shop_bg` 均恢复为 hidden。Live Console Error=0，只有用户指定忽略的 1105 Warning。
- **更正 W6.4 盘点剩余数**：封神列传已有真实入口且本次复核通过；招募页已有真实入口/关闭、三个并行 Popup Raycast 和当前 GameView 截图 `.local/unity-validation/w6-recruitment-live-20260924.png`（用户 Prefab保持只读）；当前不可达候选为 3 个：KunLun、OnlineLayer、LilianLayer。不可达项不通过内部 Presenter 或伪造存档补入口，不因 0 tracks 删除其 Prefab 组件。
- 为判断 Snapshot 是否可退场 Metadata，在当前已加载 UI 的只读扫描中统计 3,389 个 RectTransform，其中 2,487 个带 Metadata；1,439 个有相同 target、path、nodeType 的序列化 `CocosNodeReference`，1,048 个无同对象序列化引用。样例为封神列传动态创建的 `RuntimeFengShenChapterContent/chapter_*` 节点：它们有旧 CocosPath Metadata，但不在静态 Binding refs 中。Snapshot 身份消费仍需 Metadata 或动态节点显式身份映射，暂不改 collector/组件；这不是 359 个 Prefab 的全量统计。

### W6.3 RuntimeSnapshot 身份与本轮 Unity 日志复核 — 2026-09-24

- 当前仍为 C 盘 worktree 分支 `codex/unity-ui-migration-shop-a6b4`；Unity `unityclient@fdf120ee5ce0f719`（2022.3.62f3c1）在 Bootstrap Play。对 `RuntimeSnapshotCollector` 的序列化节点索引做脚本刷新编译：Unity 返回就绪，Editor.log 显示 Tundra build success、0 C# error；仅有 `TextureImporter.spritesheet` 过时警告。
- Collector 现按同 GameObject 的序列化 `CocosNodeReference` 优先生成 snapshot semanticId/nodeType/source，未命中才回退 Metadata，最终回退 Unity 路径。反射调用同一私有方法的只读运行核验：Bootstrap 中 3,389 RectTransform，1,670 个有序列化引用，其中 1,439 个同时有 Metadata 且路径一致、231 个没有 Metadata；所有有 Metadata 的引用路径冲突数为 0。此改动没有消除 Metadata fallback：现有样本仍有 1,048 个“有 Metadata、无同对象序列化引用”和 671 个两者都没有的节点，完整移除仍未通过。
- Unity Console Error=0。Play 场景及全部已加载 GameObject/Prefab 对象只读扫描均未发现 missing component slot（5,928 GameObject，0）；Assets 中 42,197 条序列化 `m_Script` 引用涉及 34 个 GUID，均能在 Assets 或 PackageCache 的 C# `.meta` 中解析，未发现 `m_Script: {fileID: 0}`。但 domain reload 后 Console/Editor.log 会出现 `The referenced script (Unknown) on this Behaviour is missing!`，当前扫描没有定位其来源，故仍作为未解决警告，不清理或覆盖任何 Prefab。MCP WebSocket 也记录了传输重置 warning；刷新工具已恢复并完成操作。
- 后续用 Unity Editor `AssetDatabase.GUIDToAssetPath` + `MonoScript.GetClass()` 对 Assets 下全部 501 个 Prefab/Scene/Asset 文件复核：34/34 个被引用脚本 GUID 均映射到有效类，359 个 Prefab 的所有被引用脚本类均有效。由此排除了这些序列化 Assets 中的脚本 GUID/类型缺失；domain reload 的 transient Unknown Behaviour 仍未定位，不能把它标成已解决。

### W6.3 FengShenStory 页面级 Metadata 退场复开验收 — 2026-09-24

### W6.3 Answer 页面级 Metadata 退场 — 2026-09-24

- `AnswerPresenter` 固定问题/奖励/反馈/四个选项控件绑定并隐藏页面后，调用 `RetireMetadataWithSerializedIdentityAtRuntime`。改动前只读运行实例核验 59/59 Metadata 全字段匹配同对象序列化引用；干净 Play 经 Slot01 与 Main→玩法→Function_27 真实 EventSystem 路线打开后，问题与四项选项文本可见，实例 Metadata=0、序列化 refs=59。未点击或提交答案；真实 Close 先返回玩法，再关玩法返回 Main，最终共享层均隐藏。Console Error/Warning=0，`AnswerLayer.prefab` 未修改。详见 `.local/unity-validation/w6-answer-metadata-retirement-20260924.md`。
- 仅关闭该页面运行实例的 Metadata 消费。保留 Prefab 序列化组件、全局 Snapshot/Binding/Dispatcher 兼容层和后续答题回包验证；W6.3/W6.5 仍进行中。

### W6.3 XLua 插件/程序集命名告警复核 — 2026-09-24

- Unity 启动日志报告 `Assets/Plugins/WSA/ARM/xlua.dll` 与 `Assets/XLua/Src/XLua.Runtime.asmdef` 命名冲突；程序集名已设为 `XLuaManaged`，三个显式引用（`XLua.Editor`、`ProjectX.LuaRuntime`、`ProjectX.Core`）均匹配。后续启动日志仍出现过一次提示，因此将定义文件及其 `.meta` 成对改名为 `XLuaManaged.asmdef`，保留原 GUID `b55117c7673ee15498388bb4a2267e8b`；未改原生 WSA `xlua.dll` 或其 `.meta` 内容。
- Unity Editor 2022.3.62f3c1 导入改名后再次完成脚本编译；运行时反射确认 `typeof(XLua.LuaEnv).Assembly.GetName().Name=XLuaManaged`，生成物为 `Library/ScriptAssemblies/XLuaManaged.dll/.pdb`。改名后的 Editor.log 未新增该同名提示，Unity Console 当前 Error/Warning=0。Play 仍运行，未改业务存档；此前日志中的提示保留作历史记录。
- 修改路径：`unityclient/Assets/XLua/Src/XLuaManaged.asmdef`（原 `XLua.Runtime.asmdef`）、配对 `.meta`（GUID 不变），以及前述三个引用 asmdef；未改 Prefab、原生 DLL 或存档。

### W6.3 FengShenStory 页面级 Metadata 退场复开验收 — 2026-09-24

- 初次和重复打开均通过 Main→玩法→封神列传真实 EventSystem/Raycast 路线。只读 Prefab 基线 Metadata=106/Binding refs=106；两次运行实例均 Metadata=0/refs=106，章节名、当前关卡与 5/5 次数文本可见。页面 Close 命中真实 CloseBtn，玩法框架关闭恢复主界面；未挑战、领奖或修改存档。第二次关闭时同一 MCP 代码调用在同一帧连续派发两个依赖操作导致第二次 Raycast 无 hits；检查确认 Gameplay/shop_bg 仍 active，等待下一 Unity 帧后检查/派发正常，归因为验证动作帧间隔不足，不是页面状态缺陷。详见 `.local/unity-validation/w6-fengshen-metadata-retirement-20260924.md`。
- 证据边界：以上是当前 Bootstrap Play 场景和已加载资产样本，不是 359 个 Prefab 的 Metadata 全量退场验收。W6.3/W6.5 保持进行中；没有改 Prefab、`.meta`、存档或用户未提交文件。

### W6.3 Retired Metadata Snapshot identity — 2026-09-24

- 在 `CocosUiBinding` 增加仅限运行态的退场身份缓存，Metadata 销毁前暂存原 CocosPath/NodeType/Tag/ActionTag/GameObject；SubsystemRegistration 时清空。`BagPageBinding` 的局部退场也先登记身份。`RuntimeSnapshotCollector` 以直接序列化引用优先，仅对缺少直接引用的目标补入退场缓存；空 CocosPath 仍按原规则回退 Unity 完整路径。
- Unity Editor 强制刷新后完成相关程序集编译；实际 Slot01 旧存档→Main 输入路线启动有效。Main HUD Metadata=0、refs=199；当前运行态缓存 202/202 项进入 Collector identity index，其中 18 项使用缓存回退；直接调用 Collector 的 `ResolveNodeIdentity` 核验语义路径与节点类型，18/18 一致。编译 Console Error=0；存在既存 `UiButtonPressFeedback.animation` 隐藏成员和两条 `TextureImporter.spritesheet` obsolete warnings。最终干净 Play 回到 Main 后 Error=0，另有 LocalServer 遗留服务回收 Warning（pid=33928），与 UI 无关。
- 补做真实链路：Slot01→Main，点击可见 Head→共享框架→背包页签，BagPageBinding 所在 `DynamicUi_beibao` 显示 7 个有效物品文本，Metadata=0；53 条退场身份全部进入 Snapshot index。真实点击 Item2 行后详情为“转盘钥匙/用来启动转盘的道具”，未点击使用。体力丹 slot=5、qty=3、UseType=2；真实点击 Use 打开数量弹层，未选数量/未确认，真实 Close 关闭弹层且 qty 仍为3。共享 Close 命中后 Bag/OneLevel 隐藏、Main 恢复且 `ProjectXApp.Instance=True`、Console Error=0。重复进行 Main→神将→Close、Head→Bag→Close，单例与 Main 恢复均正常；先前单例为 null 现象未复现。奖励弹窗与剩余 W6.3 别名、W6.4/W6.5 消费者继续进行。Prefabs、`.meta` 与存档均未改。
- 修改文件：`unityclient/Assets/ProjectX/src/UI/Migration/CocosUiBinding.cs`、`unityclient/Assets/ProjectX/src/UI/BagPageBinding.cs`、`unityclient/Assets/ProjectX/src/Validation/RuntimeSnapshotCollector.cs`。

### W6.5 Bag unsupported source-item route — 2026-09-24

- 真实复现：Slot01→Main→Head→背包页签→`突破丹`（UseType=0、UseJump=1080、数量110）→Use。原实现无条件先关闭 Bag/OneLevel，再路由；1080 在当前 `FunctionRouteCatalog` 中为 Unsupported，故关闭后没有玩家可见的不可用提示。
- 最小修复：`BagFlowPresenter.ShowUseFlow` 对 source jump 先检查 `CanOpenBagSource`；不可用时经 Bag feedback 显示 Toast 并保持当前页，只有可用路由才执行关闭与导航。Bag feedback 改用 `ShowToast`。
- Unity 2022.3.62f3c1 强制导入、脚本重载并干净 Play 后，重复上述真实 EventSystem/Raycast 操作；Use 按钮 Raycast 首击正确，Toast active 且文本为“当前版本暂未开放”，Bag 与 OneLevel 均 active，选中道具与显示数量110保持，`ProjectXApp.Instance=True`。Console Error=0；仅有回收孤儿 LocalServer 的无关 Warning(pid=38576)。无存档、Prefab 或 `.meta` 修改。证据：`.local/unity-validation/w6-bag-unavailable-jump-runtime-20260924.md`。
- 随后的 `manage_camera` composited GameView 截图请求返回黑图，并产生5条相同 PlayerLoop recursive Error，堆栈全部指向 `com.coplaydev.unity-mcp` 的 `ScreenshotUtility.CaptureCompositedAfterFrame` 第197行；该工具异常发生在背包点击验收之后，非业务代码。当前结果/堆栈已留档，未改 PackageCache。
- 此项完成不代表 W6 收口；Bag ItemType=6 奖励弹窗缺少真实库存夹具，不能伪造；W6.3/W6.4 与剩余 W6.5 消费者工作继续进行。

### W6.5 Bag quantity keypad input/delete/cancel — 2026-09-24

- 在现有 Slot01 通过真实 EventSystem 打开 Bag，选择体力丹（库存3）并点击 Use；数量弹层实际显示。真实 Raycast 点击数字键2后输入显示变为`2`；点击删除键后恢复`请输入数量`占位文本。真实 Close 首击正确，EnterNum 隐藏而 Bag/OneLevel 保持 active，库存显示仍为3，`ProjectXApp.Instance=True`。未点击确认、未消耗物品或改存档/Prefab。
- 当前 Console 的5条 PlayerLoop recursive Error 来自之前 Unity MCP composited screenshot helper，堆栈为 `ScreenshotUtility.CaptureCompositedAfterFrame:197`；本次键盘交互没有新增 Error。完整证据：`.local/unity-validation/w6-bag-quantity-keypad-runtime-20260924.md`。

### W6.3 ancestor identity exception classification — 2026-09-24

- 重新启动 C 盘 Bootstrap Play 后，真实 EventSystem `Btn_Old` → Slot_01 `Btn_Enter` 回到已有存档 Main；`ProjectXApp.Instance=true`，Main HUD active。Play 重启前发现域重载后单例为 null，强化大师 Close 的 Raycast 命中正确但状态未变；已记录为失效运行态并 Stop/Play 恢复，没有调用 Presenter，也未触碰存档。
- 使用 Unity Editor AssetDatabase 只读加载并卸载 359 个 Prefab，复核 19,690 个 Metadata：19,600 有同对象同路径引用；90 个例外按 `PreserveExactAncestorIdentity` 的冲突守卫分类为 5 个目标已有异路径引用、48 个 CocosPath 已由其他目标占用、37 个无路径/目标冲突且有序列化祖先。后者用同一字典序 tie-break 派生后，7 个路径精确一致、30 个与 Metadata 语义路径不一致；无 Prefab 保存或源码/数据更改。精确候选不能覆盖既有路径身份，其他 30 个也不能直接合成别名。
- 同步复核 asmdef 保持 `XLuaManaged`，`XLua.Editor`、`ProjectX.Core`、`ProjectX.LuaRuntime` 三个引用均匹配；运行时反射确认已加载 `XLuaManaged`，WSA ARM `xlua.dll` 的 PluginImporter 对 Editor 不兼容、仅 Windows Store Apps ARM 兼容。Unity 刷新/重启后没有新的 `xlua.dll` 同名告警或 C# 编译错误。Play 路线后 Console Error=0，仅 LocalServer 孤儿恢复 Warning(pid=4912)。全量分类结果不等同于组件退役；W6.3/W6.4/W6.5 仍进行中。

### W6.3 Divine Item_bg 祖先映射运行时更正 — 2026-09-24

- 当前 C 盘 worktree、Bootstrap Play 中复核 `DynamicUi_HeroEquipmentDivine`：`Binding.Find` 命中实际 `Item_bg`；最近序列化祖先路径拼接真实 Transform 子路径后，与 `CocosNodeMetadata.CocosPath` 完全一致。更正旧 runtime-mapping 报告中“此候选派生路径不匹配”的结论；当前实测没有修改源码或退役 Metadata，单个精确候选不代表该绑定的 50 个 Metadata 均可安全删除。
- 共享 Close 的两次真实 EventSystem/Raycast 点击依次返回装备列表、主界面；最终 `DynamicUi_OneLevelLayer`、`DynamicUi_shop_bg` 和装备节点隐藏，Main 恢复、`ProjectXApp.Instance=true`，Console Error=0，仅 LocalServer 孤儿恢复 Warning(pid=52148)。未操作神铸材料、存档、Prefab 或 `.meta`。详见 `.local/unity-validation/w6-divine-itembg-ancestor-runtime-20260924.md`。
- W6.3 的其他别名/消费者边界、W6.4 不可达页面及剩余 W6.5 路线仍未收口。

详细报告、依赖图和组件台账见 [`FRAMEWORK_STATIC_AUDIT.md`](FRAMEWORK_STATIC_AUDIT.md)。

### W6.3 神铸页可解析 Metadata 运行时退场 — 2026-09-24

- 运行时盘点神铸 binding 的 50 个 Metadata：41 个已由同路径同目标序列化引用覆盖，`Item_bg` 可通过精确祖先派生身份注册；另 8 个生成属性行与已有路径身份冲突，继续保留，避免 `Find(path)` 改指目标。
- 修改 `CocosUiBinding.RetireMetadataWithCompleteRuntimeIdentityAtRuntime()`：先经现有冲突守卫注册精确祖先身份；仅退役路径首引用、typed 引用和 ActionTag 均能解析回同一 GameObject 的 Metadata。`HeroEquipmentPresenter.ShowDivine()` 在完成神铸页绑定/显示后调用。无 Prefab、`.meta` 或存档改动。
- Unity 脚本刷新/编译后干净 Stop/Play，以真实 EventSystem 从 Slot01 经主界面、背包、觉醒石 Use、装备列表滚动、uid `2123071489` 详情滚动进入神铸页。运行时 Divine binding 为 Metadata=8、refs=42、ref lookup mismatch=0；`Item_bg` Metadata 已退役但 `Binding.Find` 仍返回原活动对象，动态冲突 8 项保留。未点击神铸消耗按钮。
- 真实共享 Close 返回装备列表再回主界面；最终 OneLevel/shop_bg 隐藏、Main 恢复、`ProjectXApp.Instance=true`。Console Error=0，仅 LocalServer 孤儿回收 Warning(pid=29732)。详细记录：`.local/unity-validation/w6-divine-itembg-ancestor-runtime-20260924.md`。W6.3 全局 fallback、其余消费者和 Metadata 路径异常仍待处理。

### W6.5 BagFlow EnterNum Unity 路径绑定与 Metadata 退场 — 2026-09-24

- `BagFlowPresenter` 的数量弹窗改用运行时 Unity Transform 路径解析，支持导入结构的虚拟 `Layer/` 前缀；数字、删除、确认、关闭、控件验证与 BAG-08 输入分支统一使用该解析器。
- 运行时先确认 EnterNum 22 个 Metadata 均与序列化引用精确匹配，再绑定并退场；干净 Play 的真实 Slot01 路线中 EnterNum Metadata=0、refs=22。真实点击体力丹、Use、数字2、删除、关闭，值按`请输入数量→2→请输入数量`变化；输入框关闭后 Bag 保持打开、库存3，关闭共享框后回 Main，OneLevel/shop_bg 隐藏。
- Unity 刷新编译完成；最终 Console Error=0，仅 LocalServer 孤儿服务回收 Warning(pid=48684)。未确认使用、未修改存档、Prefab 或 `.meta`。W6.5 其余 BagFlow 弹窗及共享绑定继续进行。详见 `.local/unity-validation/w6-bagflow-input-unity-path-retirement-20260924.md`。

### W6.3 Equipment Strength 页面 Metadata 运行时退场 — 2026-09-24

- Strength 子 Prefab 当前运行实例的 34/34 Metadata 在修改前均与同对象序列化引用逐字段匹配。`HeroEquipmentPresenter.ShowStrength()` 完成页面绑定与按钮配置后，现调用 `RetireMetadataWithSerializedIdentityAtRuntime(null)`；只影响 Strength 运行实例，不改 Prefab、`.meta` 或存档。
- Unity 刷新编译并干净 Stop/Play 后，Slot01 经主界面→神将→强化大师→素心刀→装备强化真实 EventSystem 路线通过。Metadata=0、Binding refs=34；关键路径仍可 `Binding.Find`，等级、消耗、属性、装备名称和等级文本可见。强化与强化5次按钮仅做 Raycast Inspect，未执行。
- 培养壳固定 OneLevel sibling=6、尺寸1334×750、锚点与位置为零；Strength/Refine/Awaken/Divine/FaBaoStrength/FaBaoRefine sibling 固定0–5。真实 OneLevel Close 返回强化大师、Popup Close 返回神将、神将 Close 返回 Main；共享层最终隐藏。Console Error=0，仅 LocalServer 孤儿回收 Warning(pid=41276)。详细证据：`.local/unity-validation/w6-equipment-strength-metadata-retirement-20260924.md`。
- W6.3 其他消费者、W6.4 当前不可达候选和 W6.5 剩余路线仍在进行。

### W6.3/W6.5 强化大师分类列表与精炼页 — 2026-09-24

- 复现强化大师打开后 shopBg/Btn_ListView inactive；类别按钮虽配置了顺序与回调，但 MasterTab2/Button 没有活动运行目标。ConfigureHeroEnhanceMasterFrame() 现先激活列表容器。
- 干净 Play 经真实 Slot01→神将→强化大师路线，分类容器 active、六类 sibling 固定0–5；非选中页签 Raycast 命中。实际点“装备精炼”后装备行显示“去精炼”，再点“装备强化”后显示“去强化”，顺序不变。没有 SetAsLastSibling 页签操作。
- 实际打开素心刀精炼页前核对54个 Metadata 中46个可由同对象序列化引用精确覆盖、8个为动态属性项。ShowRefine() 现于绑定/显隐后退场精确匹配项；干净 Play 后 Metadata=8、refs=46、退役缓存46，动态项保留，三条核心 Binding.Find 命中，精炼按钮 Raycast 首命中正确但未执行消耗。
- OneLevel Close 返回强化大师、Popup Close 返回神将、神将 Close 返回 Main；最终共享层隐藏。无 Prefab、.meta、存档或库存更改。记录：.local/unity-validation/w6-master-tabs-refine-metadata-20260924.md。W6.3 全局 Snapshot/fallback、其他可达页与 W6.4/W6.5 仍进行中。

### W6.3 Equipment Awaken 页面 Metadata 运行时退场 — 2026-09-24

- 修改前真实觉醒页实例 refs=41、Metadata=49；41 个同对象序列化身份精确匹配，8 个属于无序列化引用的运行时属性行。ShowAwaken() 完成页面配置后退场精确项。
- 干净 Play 经 Slot01→主界面→背包→觉醒石×5→Use 真实 EventSystem 路线打开觉醒页；运行时 Metadata=8、refs=41、退役缓存41。动态属性行保留，核心 Binding.Find 与觉醒/关闭 Raycast 通过；未点击觉醒。
- Close 返回装备列表再返回 Main；重新打开背包确认觉醒石仍为5。无 Prefab、.meta、存档或库存修改。Console Error=0，仅 LocalServer 孤儿回收 Warning(pid=44172)。证据：.local/unity-validation/w6-equipment-awaken-metadata-retirement-20260924.md。W6.3 全局消费者、W6.4 和 W6.5 仍进行中。

### W6.3/W6.5 法宝精炼与强化大师交叉路由 — 2026-09-24

- 法宝精炼运行实例 42 个 Metadata 中，34 个与同 GameObject 序列化绑定的 path/type/tag/actionTag 完全一致，另 8 个是动态属性行模板。`HeroEquipmentPresenter.ShowFaBaoRefine()` 完成绑定/显隐后退场精确匹配项；未修改 Prefab、`.meta`、存档或库存。
- 刷新后 Stop/Play 以真实 EventSystem 重回 Slot01，走 Main→神将→强化大师→法宝强化→法宝精炼；运行时精炼页 Metadata=8、refs=34，动态模板保留，属性、库存/消耗、Binding 路径可用。真实 Close 返回强化大师，培养壳隐藏。
- 再由强化大师进入装备强化子页：Metadata=0、refs=34，属性与操作控件可见；未执行精炼或强化。Close 返回强化大师时六个页签 sibling 仍固定 0–5；关闭强化大师和神将后 Main 恢复，OneLevel/shop_bg 隐藏。Console 无 Error，仅 LocalServer 回收 Warning(pid=42192)。详见 `.local/unity-validation/w6-fabao-refine-and-strength-route-20260924.md`。
- 本项不代表 W6 收口；W6.3 全局 Snapshot/path fallback 和其余消费者、W6.4 不可达 Timeline 候选、W6.5 共享绑定及 BagFlow 其他消费者仍进行中。

### W6.3 法宝强化页 Metadata 退场 — 2026-09-24

- 法宝强化运行实例 64 个 Metadata 均与同 GameObject 序列化引用的 path/type/tag/actionTag 完全匹配；`HeroEquipmentPresenter.ShowFaBaoStrength()` 在完成绑定和显隐后退场这 64 项。未修改 Prefab、`.meta`、存档或库存。
- 干净 Play 通过真实 EventSystem 从 Slot01→主界面→神将→强化大师→法宝强化→“散瘟鞭”强化页。运行时 Metadata=0、refs=64；`Binding.Find` 的一键添加/强化按钮路径仍可用，属性、等级和消耗内容可见。未执行自动添加、选择材料或强化。
- 共享 Close 返回强化大师；六个页签 sibling 顺序仍固定 0–5。再关闭强化大师和神将回到 Main，OneLevel/shop_bg 隐藏，Console Error=0，仅 LocalServer 回收 Warning(pid=15384)。详见 `.local/unity-validation/w6-fabao-strength-metadata-retirement-20260924.md`。
- W6.3 全局 Snapshot/path fallback 与其他消费者、W6.4 不可达 Timeline 候选、W6.5 其余共享绑定/BagFlow 消费者仍未收口。

### W6.3/W6.5 法宝材料选择器弹窗 — 2026-09-24

- 法宝材料选择弹窗运行实例 83 个 Metadata 中，33 个与同 GameObject 序列化引用完全匹配，50 个属于运行时复制的候选行；`HeroEquipmentPresenter.OpenFaBaoMaterialChooser()` 在构建候选与绑定按钮、ShowPopup 后只退场固定控件的 33 项。克隆候选 Metadata 保留。
- 干净 Play 经真实 Slot01→Main→神将→强化大师→法宝强化→空材料槽打开弹窗；Canvas sibling=11，三条候选可见、数量0、Toggle 全 false，确定按钮 Raycast 命中。退役后 Metadata=50、refs=33；真实点击确定关闭0项后恢复法宝强化页（Metadata=0、refs=64）。没有选材料或强化。
- 真实共享 Close 返回强化大师；页签顺序仍固定0–5；关闭强化大师/神将后 Main 恢复且 OneLevel/shop_bg 隐藏。Console Error=0，仅 LocalServer 回收 Warning(pid=19892)。详见 `.local/unity-validation/w6-fabao-material-chooser-metadata-20260924.md`。
- 此页仍通过 `CocosUiBinding` 解析固定节点，运行时克隆候选依赖直接 Transform 绑定；不据本项移除共享绑定。W6.3 全局 Snapshot/path fallback、W6.4 不可达候选和 W6.5 其余共享/BagFlow 消费者仍未完成。

### W6.3/W6.5 装备一键精炼弹窗与 XLua 命名警告复核 — 2026-09-24

- 真实复现发现：强化大师“去培养”进入装备培养后，默认落在强化页；通过固定顺序的“精炼”页签进入精炼页，再点“一键精炼”时，原先没有打开弹窗。根因是 `cultivationOnly` presenter 路径未加载 auto-refine view，也未给精炼页/弹窗配置监听器。
- 最小修复：`ProjectXApp.EnsureHeroEquipmentPresenter` 在两种模式下均加载 AutoRefine view；`HeroEquipmentPresenter` 无条件配置 AutoRefine 控件；打开弹窗后退场与序列化 path/type/tag/actionTag 完全匹配的运行时 Metadata。Play 实测弹窗 Canvas sibling=11、refs=44、Metadata=0；装备“素心刀”、数量与确认/取消文本可见，取消按钮真实 Raycast 首击为 `autorefine.cancel`。仅点取消，未确认精炼、未改变背包或存档。
- 取消后共享 Close 回强化大师，再关强化大师回神将，最后关闭 OneLevel 回 Main；最终 OneLevel、shop_bg、master 与弹窗均隐藏，`ProjectXApp.Instance=True`。Console Error=0；仅本机服务孤儿回收 Warning(pid=32700)。详见 `.local/unity-validation/w6-equipment-auto-refine-metadata-retirement-20260924.md`。
- 同轮复核 XLua 提示：当前 `XLua.Runtime.asmdef` 不存在，已由 `XLuaManaged.asmdef` 承载 XLuaManaged 程序集；运行时 `XLua.LuaEnv` assembly name=`XLuaManaged`，AssetDatabase 中 XLua.Runtime asmdef=0，当前 Console 无同名告警。Editor.log 中该行属于先前启动导入记录；原生 WSA `xlua.dll` 未重命名。
- W6.3/W6.5 仍进行中；Prefab、`.meta`、背包和存档未改。

### W6.3 神将动态列表克隆 Metadata 退场 — 2026-09-24

- 当前 C 盘 Play 真实打开神将页后，`yingxiongListLayer` 为 28 条序列化引用、90 条运行时 Metadata；其中模板 15 条、五个动态行克隆各 15 条。75 条克隆 Metadata 与模板在相同相对 Transform 路径上逐项匹配 CocosPath/nodeType/tag/actionTag；模板 15 项均有精确序列化目标。克隆行由 `HeroPresenter` 的直接 Transform 绑定消费，Binding.Find 仍指向保留的模板。
- `CocosUiBinding` 新增模板克隆限定退役：先确认模板全部身份已有序列化引用，只清理传入克隆根下完整匹配的行，并在 Destroy 前写入现有 retired identity cache；不匹配的行保留。`HeroPresenter` 首次 Render 后调用，模板及 Prefab 序列化数据不变。
- Unity 刷新编译、Stop/Play、Slot01 登录后真实打开神将：Metadata 90→15，五行克隆 75→0，Binding refs=28。Snapshot Collector 实际身份索引和解析对 75 个克隆均保留退役前 path/type/source（75/75，0 mismatch）。真实点击 `Hero_11_1` 后角色信息从“苏全忠”更新为“接引道人”；关闭回 Main、重新打开神将仍通过，再关闭后共享层隐藏、单例有效。Console Error=0；仅 LocalServer 孤儿回收 Warning(pid=39400)。证据 `.local/unity-validation/w6-hero-list-clone-metadata-retirement-20260924.md`。
- W6.3 的 90 个 Prefab path-target 异常分类、W6.4 不可达 Timeline 候选、其余 W6.5 BagFlow/共享框架消费者仍未收口；本项不修改任何 Prefab、`.meta` 或存档。

### W6.3 神将与装备碎片列表克隆 Metadata 复验 — 2026-09-24

- 神将列表真实实例：28 条序列化引用；Metadata 90→15。五个动态行的 75 条 Metadata 与模板按相对 sibling-index 路径及 `CocosPath/nodeType/tag/actionTag` 一一对应，退役后 Snapshot 身份与解析保留 75/75。真实点击角色行后详情由“苏全忠”切换为“接引道人”；关闭并重开仍正常。
- 装备碎片真实页：75 条序列化引用；Metadata 146→105。模板 56 条保留；运行行 56 条中仅精确对应序列化模板引用的 41 条退役，余下 15 条无直接序列化目标而保留。克隆重命名会改变节点名，因此对应关系以相对 sibling-index 路径核对。Snapshot 身份与解析保留 41/41。
- 碎片“获取/合成”仅检查 Raycast 与可见详情，未执行；共享关闭后回主界面，OneLevel 隐藏、Main 恢复，重新进入列表正常。Console Error=0，仅 LocalServer 孤儿回收 Warning(pid=33988)。未修改 Prefab、`.meta`、库存或存档。详见 `.local/unity-validation/w6-hero-and-equipment-fragment-clone-metadata-20260924.md`。
- 当前 Unity Console 再次读取仍无 Error；仅有上述 LocalServer 回收 Warning。`XLua.Runtime.asmdef` 当前不存在，XLua 运行程序集为 `XLuaManaged`，`XLua.LuaEnv` 运行时程序集名为 `XLuaManaged`；用户提供的 `xlua.dll`/`XLua.Runtime.asmdef` 提示不是当前 Console 活跃错误，无需再次改名或触碰 WSA 插件。
- W6.3 全局身份异常分类、W6.4 不可达 Timeline 候选及 W6.5 其余共享/BagFlow 消费者仍未收口。

### W6.3 神将列表模板 Metadata 运行时退场 — 2026-09-24

- 根因：神将列表克隆的75条 Metadata 已退役；模板的15条 Metadata 仅供克隆比对，实际节点绑定由 Presenter 直接 Transform 和 `CocosNodeReference` 消费。
- 最小改动：`CocosUiBinding` 增加限定子树且同对象 path/type/tag/actionTag 全匹配的运行时 Metadata 退役；`HeroPresenter` 先处理克隆，再处理模板。模板节点继续留作 `VirtualList` 克隆源。
- 干净 Stop/Play 后真实 `Btn_Old→Slot_01/Btn_Enter→Main→btn_zhenrong` 打开神将：列表/模板/克隆 Metadata 均为0，Binding refs=28；模板15条身份在 `RuntimeSnapshotCollector` 实际索引/解析结果均精确（15/15）。真实点击 `Hero_11_1` 首命中 `hero.row.11`，详情更新为接引道人；关闭回 Main 再开后 Metadata仍为0，稳定后行 Raycast 再次通过。最终 OneLevel/shop_bg隐藏、Main恢复、`ProjectXApp.Instance=True`。Console Error=0，仅 LocalServer 回收 Warning(pid=51744)。未修改 Prefab、`.meta`、存档或库存。详见 `.local/unity-validation/w6-hero-template-metadata-retirement-20260924.md`。
- W6.3 全局身份例外和其他页面仍未闭合；W6.4 三个不可达候选保留组件；W6.5 其他 BagFlow/共享绑定仍进行中。

### W6.5 Bootstrap 后背包详情与共享框架恢复复验 — 2026-09-24

- 当前 Editor Play 起于 Bootstrap；真实输入进入 Slot01 后到达 Main，再点击玩家 Head 打开 OneLevel。Bag 页签固定顺序为境界/背包/邮件/系统，对应 sibling 0–3；Canvas 中 OneLevel=sibling 7、shop_bg=sibling 8 且隐藏。
- 真实 Raycast 选中 Bag 的“转盘钥匙”动态行后，右侧详情显示“转盘钥匙 / 用来启动转盘的道具”；Bag 运行实例 Metadata=0、序列化引用53。未执行使用或其他存档写操作。
- 真实点击共享 Close 后 OneLevel、shop_bg 隐藏，Main 恢复，`ProjectXApp.Instance=true`。Console Error=0；当前记录仅含 LocalServer 孤儿回收 Warning(pid=33988)。运行时细节见 `.local/unity-validation/w6-bag-detail-shared-close-recheck-20260924.md`。
- 此为 W6.5 一条可达路线复验，不代表 BagFlow 其余弹层、W6.3 身份闭环或 W6.4 零轨道候选完成；不改 Prefab、`.meta`、存档或库存。

### W6.3 Mail 页运行实例 Metadata 退场 — 2026-09-24

- 只对可达 Mail 页运行实例退场：`CocosUiBinding` 新增保留多个动态模板子树的完整序列化身份退场方法；`MailPresenter` 在首轮 Render 后保留邮件行 `MailBtn` 模板（8 Metadata）和附件 `IconBg` 模板（3 Metadata），其余固定控件 31 项退场。Metadata 42→11，Binding refs 保留 42，31/31 retired identity 经 `RuntimeSnapshotCollector` 的真实身份索引解析回原 CocosPath、NodeType、Snapshot source；RectTransform 缺失 0。
- 干净 Play 使用 `Tools/ProjectX 应用/运行 Bootstrap 验证` 启动，真实 Raycast/EventSystem 完成旧存档 Slot01→Main→Head→Mail→Close→Head→Mail；空邮件提示可见，关闭后 Main 恢复且 OneLevel/shop_bg 隐藏，重进仍 Metadata=11。截图和复现记录：`.local/unity-validation/w6-mail-metadata-retirement-20260924.md`、`.local/unity-validation/w6-mail-metadata-retirement-play-20260924.png`。该路线执行期间 Console Error=0，只有 LocalServer 遗留服务回收 Warning(pid=43224)；之后 Runner 因 300 秒未收到 package response 超时并退出 Play，产生当前保留的 Runner Error，Play 已停止。超时后的额外 Close 因 EventSystem 已退出而未派发，不计入路线验证。
- 当前无真实邮件/附件，未伪造邮件数据；动态行、附件 cell 与详情/领取链待自然数据后验收。屏蔽/不可达功能 Prefab Metadata 继续按用户指示暂缓。W6.3 全局消费者与 W6 总体仍进行中。

### W6.4/W6.5 招募商城与背包详情共享关闭交叉复验 — 2026-09-24

- 当前 C 盘 Unity 实例中临时清除 `SessionState` 的 Bootstrap Runner Armed 标记，以保留 Play/EventSystem 完成 UI 操作；未修改 Runner 源码或项目文件。真实输入依次为 Main→Head→背包页签→选中转盘钥匙→OneLevel Close；以及 Main→招募→招募 Shop→商城 Close→招募 Close。
- 招募页 `DynamicUi_shenjiangzhaomu` 激活时，Popup1、Popup2、Popup3 同时 active；三组单抽/十连按钮都存在于运行层级，没有新增页签或改显示方式。招募 Shop 真实点击后 `DynamicUi_OneLevelLayer@7=True`、`DynamicUi_shop_bg@8=True`，商城商品列表含6个 Item 行及购买按钮。商城 Close 后回到招募，三个 Popup 仍同时 active；招募 Close 后 Main 恢复，三 Popup inactive。
- 背包页打开时 `OneLevel@7=True`、`shop_bg@8=False`；页签顺序为境界/背包/邮件/系统。真实点中 Bag `RuntimeRow1/Item2/RuntimeHitArea` 后，运行文字显示“转盘钥匙 / 物品描述 / 用来启动转盘的道具”，持有数6；仅选择物品，未执行使用或修改库存。真实 OneLevel Close 后 Main active、OneLevel/shop_bg inactive、`ProjectXApp.Instance` 与 EventSystem 均有效。
- Unity Console 当前 MCP 查询为0 Error、1条 MCP WebSocket 初始化 Warning。随后通过 MCP Stop Play 收尾；没有修改 Prefab、`.meta`、存档或库存。逐步证据：`.local/unity-validation/w6-recruit-shop-bag-close-recheck-20260924.md`。
- 本项补齐招募关联商城与一条 Bag详情/共享关闭交叉路线，不代表 W6.3 全局 Snapshot 身份、W6.4 不可达零轨道候选或 W6.5 其余 BagFlow 弹层收口；屏蔽功能 Prefab Metadata 依用户要求延期。

### W6.5 BagFlow 礼盒弹层真实库存资格复核 — 2026-09-24

- 通过真实 Slot01→Main→Head→Bag 页签进入当前 Unity Bag；Bag 页打开且 OneLevel active、shop_bg inactive。只读 `ProjectXApp.services.Bag.Items` 返回7种现存道具：500×3 type14 体力丹、403×6 type11 转盘钥匙、851×110 type1 突破丹、854×5 type1 觉醒石、852×20 type1 修炼丹、581×2 与10581×1 type19 鱼类；没有 `ItemType=6`。
- 不调用 Use、不伪造奖励/库存，因此本轮不打开礼盒弹层；这与之前缺少 ItemType=6 fixture 的边界一致。Console error/warning 查询0条；Play 已停止，Runner Armed=False。无源码、Prefab、`.meta`、存档或库存修改。详见 `.local/unity-validation/w6-bagflow-gift-fixture-inventory-recheck-20260924.md`。

### W6.5 AnswerPresenter 固定路径迁移 — 2026-09-24

- `AnswerPresenter` 固定节点从 `CocosUiBinding.Find` 改为 `CocosUiView.FindNode`。只读核对 `dati/AnswerLayer.prefab`：21 个代码路径中20个可由当前 Transform 层级解析，存在对应序列化目标的节点与目标 GameObject 身份一致；可选隐藏目标 `RewardBg/Bg1/Icon` 在 Prefab 中不存在，保留原有 null guard。
- C 盘 worktree Unity batch compile 退出码0，日志无 C# error/warning；证据 `.local/unity-validation/w6-answer-presenter-path-cache-compile-20260924.md` 与 `.log`。这只是静态/编译证据；答题真实路线需在后续 Play 对当前代码重验，不能据此关闭 W6。

### W6.5 Shop 固定路径迁移定向 Play 回归 — 2026-09-24

- 沿用当前 C 盘 Editor、Slot01、LocalServer 与已恢复的 MCP session，不重启、不重登。Main 下真实 EventSystem 命中商城入口并打开含6个动态商品行的 Shop；真实点击数量输入打开键盘，再真实关闭，显示数量保持1、未点确认或购买；真实关闭商城后回 Main，OneLevel/shop_bg 均隐藏。Console Error/Warning=0。
- 本次只关闭 ShopPresenter/ShopQuantityPresenter 路径改动的对应回归，不重复已验收的商城完整购买流程。证据 `.local/unity-validation/w6-shop-path-migration-runtime-20260924.md`；W6.3 Snapshot 身份、W6.4 范围内剩余候选和其余 W6.5 页面仍未完成。

### W6.5 TaskPresenter 固定路径迁移定向 Play 回归 — 2026-09-24

- 当前 Play 会话的 Unity 侧真实 Main→Gameplay→每日任务打开；7 条 Task 动态行正常生成，任务说明、进度、奖励、按钮可见。当前代码下 TaskPresenter 使用 Unity Transform path cache。截图 `.local/unity-validation/w6-task-presenter-runtime-20260924.png`（1334×750）；未领取或前往。Cocos同态截图和差异报告未采集，因此本项不记跨引擎完整验收。
- 真实 Task Close 返回 Gameplay，Gameplay Close 返回 Main；共享框架隐藏恢复正确，Console Error/Warning=0。详见 `.local/unity-validation/w6-task-presenter-path-runtime-20260924.md`。剩余范围不变。

路由耗时补充：选择入口前先检查活动父级和实际所属页面。本轮 `btn_zhenrong` 打开的是 Hero 页面，`btn_xitong` 在 inactive 的 `ButtonGroup7` 内，不能作为 Settings 运行验收入口；两者未执行业务操作。具体证据见 `.local/unity-validation/w6-task-presenter-path-runtime-20260924.md`。

### W6.5 HeroPresenter Unity 路径迁移 — 2026-09-25

- `HeroPresenter` 7 处 `CocosUiBinding.Find` 已改为 `CocosUiView.FindNode`；运行时对 Hero list/detail/bag 三个绑定的引用对照分别为27/28、102/103、133/134同对象命中，唯一不匹配的是不被页面消费的 `Layer` 绑定根。
- `LoginPresenter` 15 处 `CocosUiBinding.Find` 已迁到 `CocosUiView.FindNode`。Unity `AssetDatabase` 对 Login、ServerList、RoleCreate 的16个代表路径逐一比较旧 Binding 目标和 Transform 目标，GameObject 身份16/16一致；LoginBackground 版本标签身份也一致。scripts-only refresh 后，assembly reload 曾使 `ProjectXApp.Instance=false`；一次 targeted Stop/Play 后以现存账号1/角色1000001经真实 EventSystem 点击 `Btn_Play` 到达 Main。LocalServer 命令行指向持久化目录 `LocalServer/projectx.db`，MainTaskTracker `Layer/Main_UI` 目标与旧 Binding 相同，Console error/warning=0。未创建账号/角色、加夹具或执行领取/购买。证据 `.local/unity-validation/w6-login-presenter-path-migration-20260925.md`。
- 当前 Presenter 源码精确库存已于 2026-09-25 重算：161处 `.Binding.Find`、17个 Presenter；Friend 与 Guild 各1处依 `STEAM_SCOPE.md` 属于 `steam-excluded`，不得继续迁移；W6.5 范围内剩余159处/15个 Presenter。该计数只包含显式 `.Binding.Find(`，不包含 `CocosUiView.BindClick` 等共享 Binding 消费者。清单仅用于定位，不能代替逐页面路径核验和运行验收。
- 已修正普通 Editor Play 默认进入 Slot 的分流：编译后 `ShouldUseSinglePlayerTitle=false` 实时确认，显式单机存档流不变。当前 Play 与 EventSystem仍在，但 `ProjectXApp.Instance/services` 丢失；公共 Dispatcher 已实际调用验证会拒绝输入且不派发。现存旧 PID 49732 仍指向 `Saves/Slot01`，故只待一次新 Play 确认 LocalServer 启动参数后验收 Hero 路线，未把旧 UI 命中当验收。详见 `.local/unity-validation/w6-heropresenter-unity-path-migration-20260925.md`、`.local/unity-validation/w6-singleplayer-database-path-contract-20260925.md`。未改 Prefab、`.meta`、存档或库存。

### W6.5 LoginPresenter 固定路径迁移 — 2026-09-25

- 15处 `CocosUiBinding.Find` 改为当前 View 的 `FindNode`；Login/ServerList/RoleCreate 固定路径与旧 Binding 目标 GameObject 身份 16/16 一致，LoginBackground 版本标签身份也一致。scripts-only refresh 成功，Console error/warning=0。
- refresh 后 Unity Play 仍显示运行，但 `ProjectXApp.Instance=false`；记录状态后只进行一次 targeted Stop/Play 恢复。读取确认已有 LocalServer user 1/role 1000001；真实 EventSystem/Raycast 点击 `Canvas/DynamicUi_loginLayer/Login/Btn_Play` 命中 `login.play` 并进入 Main，运行时 user/role 仍为1/1000001，LocalServer 命令行仍指向 `Application.persistentDataPath/LocalServer/projectx.db`。没有创建账号/角色、加夹具、领取奖励或改库存。Main 中 `MainTaskTrackerPresenter` 的 `Layer/Main_UI` 与旧 Binding 目标身份相同，父节点为 `DynamicUi_UImainLayer_new`；Console error/warning=0。详见 `.local/unity-validation/w6-login-presenter-path-migration-20260925.md`。

### W6.5 BagFlow ItemType=6 礼盒选择与取消 — 2026-09-25

- 在 C 盘 worktree 的单次 Play 中用真实 EventSystem/Raycast 从 Bag 入口选中官方夹具 1114（ItemType=6，数量3），详情文案正确；打开礼盒弹层并读到六个可选阵法书。真实点击 CheckBox 后 Presenter 选中“七星阵法书”；数量按钮由1增至2再减回1。未点击最终“使用”确认。
- 真实点击共享 Popup Close 后礼盒层隐藏、Bag仍可见，1114仍为3。已验收的其他 ItemType 未重测；未购买、消耗或领取。官方 fixture Restore/AssertRestored/Cleanup/AssertCleanup 全部通过，SQLite SHA-256 与原快照一致、residualCount=0、backup不存在。证据 `.local/unity-validation/w6-runtime-error-recovery-20260925.md`。
- 本项仅补齐 ItemType=6 显示/选择/取消链；奖励确认和 ItemType=6 奖励发放不属于本轮允许操作。W6.3 全局身份例外与剩余 W6.5 消费者仍未完成。

### W6.5 MailPresenter Unity 路径迁移（真实路线待验）— 2026-09-25

- MailLayer 固定节点 `Require` 与 OneLevel `Button3_Runtime` 查找改为 `FindNode`；MailLayer Prefab 的15条固定路径经 Transform 父子链与 `CocosUiBinding.nodes` 目标 fileID 对照，身份15/15一致。CloseBtn、Button1 两个按钮绑定改为先 `FindNode` 再调用 `BindClickNode`，OneLevel Prefab身份2/2一致；`Button3_Runtime` 由 `PlayerHubTabCoordinator.EnsureRuntimeTab` 克隆 Button1 并按此名挂到同一 Panel。`CocosUiBinding` 在本 Presenter 中仍用于运行时 Metadata 身份退役，不声称整页已脱离所有旧组件。
- 最终两处查找和两处按钮绑定变更后，仅请求一次 scripts-only compilation（不做全量资源刷新/Play）；`ProjectX.UI.dll` 更新至 2026-09-25 03:47:27。之后 error/warning Console 查询返回0条；同会话 Editor state 请求未解析出可用状态对象，因此无新鲜 readiness 证据。没有做 Mail 真实 UI 路线；状态门禁恢复后只验证本次路径/按钮绑定，再按真实用户路径复测，不重跑已接受的完整邮件操作。无 Prefab、`.meta`、存档或邮件状态改动。详见 `.local/unity-validation/w6-mail-presenter-path-migration-20260925.md`。

### W6.5 GameErrorPresenter Unity 路径迁移（编译/路线待验）— 2026-09-25

- `GameErrorPresenter` 的四个 `CocosUiBinding.Find` helper 调用迁到 `CocosUiView.FindNode`。只读解析 `MessageBoxLayer.prefab` 的 Transform、绑定节点及目标 GameObject：标题、正文、关闭/确认/取消按钮、可选图标/花费/金币/描述/复选框/计时节点与 Layer 根共14条路径全部与原 Binding target 身份一致（14/14）；`FindNode` 的 `Layer/` 虚拟前缀分支与当前 Presenter 根 `MessageBoxLayer` 对应。
- 无 Prefab、`.meta` 或业务状态变更。Unity 当前没有新鲜 `editor/state` 可用证据；本次不重启、不循环探测。脚本编译和真实错误弹窗显示/关闭路线仍待验证；只验证本次迁移受影响的模态显示、按钮回调及关闭，不触发任何购买/奖励操作。

### W6.5 HeroCultivationPresenter 固定路径迁移（编译/路线待验）— 2026-09-25

- 按当前 `ProjectXApp.EnsureHeroCultivationPresenter()` 的14个 view→Prefab 来源映射重新解析当前源码和 Prefab，不沿用旧的69项预审统计。72条字面固定路径中，69条与原 `CocosUiBinding.nodes` target 及 owning-view Transform 路径身份一致，已迁到 `FindNode`；剩余3条在 Prefab 中没有静态节点，分别是运行时克隆/创建的 `HeroCultivationHelpTab2` 和两个 `HeroDestinyButton`，保留旧查找并继续依赖创建时序验证。
- 未改 Prefab、`.meta`、夹具或业务状态。Unity Editor 仍指向 C 盘 worktree，但 MCP bridge 无8080 listener，`ProjectX.UI.dll` 尚未包含本次改动；五个培养页的首次打开、切页、重复打开、返回和共享 Close 需在编译门恢复后一次性复验。详见 `.local/unity-validation/w6-presenter-binding-find-inventory-20260925.md`。

### W6.5 FormationPopupPresenter 查找迁移（编译/路线待验）— 2026-09-25

- 构造期三处查找与 `Require`/`Find` 两个通用 helper 均改为 `FindNode`。只读解析 `shenjiangzhenxingLayer.prefab`：116条序列化 Binding target 与116条 Metadata path 均对应 owning-root Transform，唯一例外是 `Layer` 根本身；Presenter 单独保留 `FindNode("Layer") ?? view.Binding.transform`，与旧目标一致，其余 helper 路径使用 `Layer/` 虚拟前缀兼容分支。
- 无 Prefab、`.meta` 或业务数据修改；Unity 编译与真实阵容弹窗路线待验证。详见 `.local/unity-validation/w6-presenter-binding-find-inventory-20260925.md`。

### W6.5 MonopolyPresenter 固定节点迁移（编译/路线待验）— 2026-09-25

- 3条固定查找迁到 `FindNode`：Monopoly HUD 的自动掷骰复选框（`kunlunxunbao/GameLayer.prefab`）及猜拳手势/选择状态根（`caiquanLayer.prefab`）。序列化 `CocosUiBinding.nodes` target 与 owning-view Transform 身份为3/3一致。
- 插值生成的地图格子路径与通用 `Require` helper 仍依赖旧 Binding，未在本项处理。未改 Prefab、`.meta`、棋盘、骰子/手牌或存档；Unity 编译与本次改动对应的 Monopoly HUD/手牌显隐真实路线待验。见 `.local/unity-validation/w6-presenter-binding-find-inventory-20260925.md`。

### W6.5 XunBao 结果/弹窗/合成页查找迁移（编译/路线待验）— 2026-09-25

- 三个 XunBao Presenter 的 `Require` helper 改为 `FindNode`，连同先前结果页固定文本调用共4处；`ProjectXApp.XunBao.cs` 中 popup Close 模板另1处查找同步改为 `FindNode`。三个 owning Prefab（`Xunbao_souxunLayer`、`Xunbao_popupLayer`、`common/saodang`）的109条序列化 Binding target 与109条 Metadata path 均匹配 owning-root Transform；各自唯一不匹配项为 Presenter 未使用的虚拟根 `Layer`。
- 未改 Prefab、`.meta`、寻宝数据或库存；编译及寻宝结果、弹窗、合成页受影响路线待验。详细清单见 `.local/unity-validation/w6-presenter-binding-find-inventory-20260925.md`。

### W6.5 WelfareActivityFramePresenter 固定路径迁移（编译/路线待验）— 2026-09-25

- 单一 `huodong/huodong_bg` owning view 的10处固定路径查找已改为 `FindNode`。该 Prefab 的34条序列化 Binding target 与34条 Metadata path 均映射到相同 owning-root Transform；唯一未匹配项是 Presenter 不查找的虚拟根 `Layer`。
- 未改 Prefab、`.meta`、货币或活动状态。福利页签、货币显示及真实关闭路线与 Unity 编译待验证；证据见 `.local/unity-validation/w6-presenter-binding-find-inventory-20260925.md`。

### W6.5 WorldPresenter 多视图路径迁移（编译/路线待验）— 2026-09-25

- WorldPresenter 的通用 `Find` helper 已改为 `FindNode`，覆盖 WorldMapNewLayer、章节页、Dadituui 和关卡详情四个 owning view。四个 Prefab 共399条序列化 Binding target 均与 owning-root Transform 路径一致；Dadituui/关卡详情的7条非根 Metadata 语义路径差异逐条对照后确认不在当前 Presenter 的查询集合内，故不影响本次 helper 切换。
- 未改 Prefab、`.meta`、章节/关卡数据。World 底图、章节选择、关卡详情路线与编译待验证。详细路径与边界见 `.local/unity-validation/w6-presenter-binding-find-inventory-20260925.md`。

### W6.5 OldMemoryPresenter 固定/槽位路径迁移（编译/路线待验）— 2026-09-25

- 6处纯查找改为 `CocosUiView.FindNode`。`OldMemoryLayer.prefab` 的 `CocosUiBinding.nodes` 为空；按 Binding 实际逻辑，旧查找回退到 `CocosNodeMetadata` 后再走 owning-root `Transform.Find`。只读解析 Prefab Transform 父子链，确认 `SlotContent`、`Slot_01`–`Slot_10`，以及每个槽位已有的 `FilledState/Btn_Create`、`FilledState/Btn_Enter`、`EmptyState/Btn_Create` 均与 Presenter 拼接路径一致。
- `BindClick` 仍使用共享 Binding API；本次仅迁移 lookup，不据此宣称该 Presenter 或 Metadata 已退役。未改 Prefab、`.meta`、存档或夹具。脚本编译和 OldMemory 受影响路线待验证。准确清单与身份依据见 `.local/unity-validation/w6-presenter-binding-find-inventory-20260925.md`。

### W6.5 TeamPresenter Transform 查找迁移（编译/路线待验）— 2026-09-25

- 单一 `Find` helper 从 `Binding.Find` 切至 `CocosUiView.FindNode`。`TeamMembersLayer.prefab` 序列化 Binding 子树96个 target 与 owning-root Transform 路径96/96同对象；Presenter 使用的按钮列表、邀请/离队按钮、状态文案、TipsBg、成员槽位 Btn1–Btn5 共14条路径均可解析，`Layer/` 虚拟前缀处理与 `FindNode` 行为一致。
- 未改 Prefab、`.meta`、队伍数据或协议。编译及队伍页面受影响路线待验证；不代表 `BindClick` / RuntimeInputDispatcher 等共享 Binding 消费者已退役。证据见 `.local/unity-validation/w6-presenter-binding-find-inventory-20260925.md`。

### W6.5 HeroEquipmentPresenter 强化页定点迁移（编译/路线待验）— 2026-09-25

- `HeroEquipmentPresenter` 的强化五次按钮两处重复查找及按钮文案 Text 查找共3处改为 `FindNode`。`zhuangbeiyangcheng/zhuangbeiqianghua.prefab` 中 `qianghua5Btn`、`qianghuaBtn/Text` 的序列化 Binding target、Metadata identity 与 owning-view Transform 路径均同对象；`FindNode` 通过 `Layer/` 虚拟前缀兼容分支定位。
- 只迁移这3处，不覆盖该 Presenter 的其他视图/helper。未改 Prefab、`.meta`、装备数据或存档；编译及装备强化受影响路线待验证。详细计数见 `.local/unity-validation/w6-presenter-binding-find-inventory-20260925.md`。

### W6.5 HeroBookPresenter 多视图查找迁移（编译/路线待验）— 2026-09-25

- `HeroBookPresenter.Find` 共用 helper 从 `CocosUiBinding.Find` 切换为 owning-view `CocosUiView.FindNode`，覆盖 HeroBook 主页及六个模态视图。按 `BootstrapSceneBuilder` 的真实 source→Prefab 映射，静态解析7个 Prefab 的240条序列化 Binding target 与240条 Metadata path；除未被 Presenter 请求的虚拟根路径 `Layer` 外，其余路径均与 owning-root Transform 同对象，`Layer/` 虚拟前缀由 `FindNode` 兼容分支处理。
- 未改 Prefab、`.meta`、图鉴数据或存档。编译和受影响的图鉴主页/弹窗路线待验证；`Bind` 仍通过同一 helper 解析页面按钮，不代表共享 Metadata/Binding 全局消费者已退役。证据及 Prefab 列表见 `.local/unity-validation/w6-presenter-binding-find-inventory-20260925.md`。

### W6.5 WelfarePresenter 多视图查找迁移（编译/路线待验）— 2026-09-25

- `WelfarePresenter.Find` 通用 helper 已改用 `CocosUiView.FindNode`，覆盖 Welfare 壳、签到页和在线奖励页。三个实际来源 Prefab 的62条序列化 Binding target 与62条 Metadata path 全部映射到相同 Transform；只有未被 Presenter 查找的虚拟根 `Layer` 不在实际 Transform 路径中，`Layer/` 前缀兼容行为已计入核对。
- 未改 Prefab、`.meta`、奖励状态或库存。编译及福利三页显隐、关闭受影响路线待验证，不据此声明 RuntimeSnapshot/Dispatcher 全局 Metadata 消费者可退役。记录见 `.local/unity-validation/w6-presenter-binding-find-inventory-20260925.md`。

### W6.5 WorldOutcomePresenter 多视图查找迁移（编译/路线待验）— 2026-09-25

- `WorldOutcomePresenter.Find` 通用 helper 已改为子节点走 `CocosUiView.FindNode`，精确路径 `Layer` 映射回 `view.GameObject`，保留原有虚拟根语义。覆盖扫荡、战斗结算和战斗统计三个结果 Prefab；共核对325条序列化 Binding target 与 Metadata path，差异仅为虚拟根 `Layer`。
- 未改 Prefab、`.meta`、奖励状态或战斗数据。Unity 编译及受影响的扫荡/战斗结算/统计路线待验证。记录见 `.local/unity-validation/w6-presenter-binding-find-inventory-20260925.md`。

### W6.5 MonopolyPresenter 查找收敛（编译/路线待验）— 2026-09-25

- Monopoly 的动态棋盘节点 `Node_1`–`Node_82`、猜拳三个按钮路径及共享 `Require` helper 已改用 `FindNode`。按 `ProjectXApp.Monopoly.cs` 与 `BootstrapSceneBuilder` 的实际加载映射，静态解析 `GameSceneLayer`、`GameLayer`、`caiquanLayer` 共246条序列化 Binding target，均解析到 owning-root 下的同一 Transform（166/166、55/55、25/25）。
- 未改 Prefab、`.meta`、棋盘或存档。编译和 Monopoly 开启、猜拳显隐、关闭受影响路线待验证。记录见 `.local/unity-validation/w6-presenter-binding-find-inventory-20260925.md`。

### W6.5 FengShenStoryPresenter 查找迁移（编译/路线待验）— 2026-09-25

- 四个实际来源 Prefab 的218条序列化 Binding target 均映射到相同 owning-root Transform；Presenter 的10处 `.Binding.Find` 已统一经 `FindViewNode`，后代使用 `FindNode`，精确 `Layer` 返回视图根节点以保留奖励弹窗 dimmer 语义。
- 未改 Prefab、`.meta`、奖励或存档。Unity 编译及封神列传奖励预览、物品来源弹窗路线待验证。静态路径证据见 `.local/unity-validation/w6-presenter-binding-find-inventory-20260925.md`。

### W6.5 HeroRebirthPresenter 路径迁移（编译/路线待验）— 2026-09-25

- `HeroRebirthPresenter` 的14处显式 `.Binding.Find` 均切至 `FindNode`。按实际 `ProjectXApp` / `BootstrapSceneBuilder` 映射核对 HeroRecycle、shop_bg、HeroRebirthChoose、HeroRebirthConfirm 四个 Prefab；共134条序列化 Binding target 全部解析到 owning-root 同一 Transform。动态候选 cell 使用独立 `Transform` 重载，未在此改动。
- 未改 Prefab、`.meta`、英雄或存档。编译和重生候选/确认路线待验证，证据见 `.local/unity-validation/w6-presenter-binding-find-inventory-20260925.md`。

### W6.5 HeroCultivationPresenter 查找收敛（编译/路线待验）— 2026-09-25

- 其余15处 `HeroCultivationPresenter` 显式 `.Binding.Find` 已改为 owning-view `FindNode`。静态既有映射覆盖14个 Presenter 视图；帮助页第二页签与两项宿命按钮是在 `OpenHelp`/`RenderCultivationDestinyPage` 创建后再读取，查询顺序保持不变。
- 未改 Prefab、`.meta`、培养数据或存档。编译及五培养页、帮助页/宿命页签和真实关闭路线待验证；证据见 `.local/unity-validation/w6-presenter-binding-find-inventory-20260925.md`。

### W6.5 DrawPresenter 路径迁移（编译/路线待验）— 2026-09-25

- DrawPresenter 的27处显式 `.Binding.Find` 已切至 owning-view `FindNode`；额外一处克隆 `shop_bg` 框架的 tab 模板查找改用相对 `Transform.Find`，在删除克隆上的 `CocosUiBinding` 前完成解析。来源映射的五个 Draw Prefab 与共享 `shop_bg` 共442条序列化 Binding target 均与 owning-root Transform 一致。
- 未改 Prefab、`.meta`、招募池、抽卡、奖励或存档。编译与奖励预览/单抽结果/神将预览路线待验证；证据见 `.local/unity-validation/w6-presenter-binding-find-inventory-20260925.md`。

### W6.5 WorldBattlePlaybackPresenter 路径迁移（编译/路线待验）— 2026-09-25

- `WorldBattlePlaybackPresenter` 的23处显式 `.Binding.Find` 已迁移。FightLayer 路径统一经 `FindNode`；BattleHpNode 使用窄 `FindHealthNode`，精确 `Node` 指向血条 View 根，`Node/` 子路径去掉虚拟前缀后按 owning Transform 解析。`common/FightLayer.prefab` 220/220 和 `HPNode.prefab` 16/16 序列化 targets 均核对通过。
- 未改 Prefab、`.meta`、战斗数据或存档。编译与实际战斗回放/血条/速度控制路线待验证；路径证据见 `.local/unity-validation/w6-presenter-binding-find-inventory-20260925.md`。

### W6.5 HeroEquipmentPresenter 装备更换视图路径迁移（编译/路线待验）— 2026-09-25

- 装备更换视图的 TableView、背景与过滤 Toggle 三处查找切到 `FindNode`。BootstrapSceneBuilder 将 `HeroEquipmentChange` 映射到 `zhuangbeiyangcheng/zhuangbeigenghuan.prefab`；Prefab 的40条序列化 Binding target 均与 owning-root Transform 路径一致。
- 后续按 owning view 将余下41处显式查找全部改为 `FindNode`，涉及装备培养壳、强化/精炼/觉醒/神铸、法宝强化/精炼、自动精炼与装备详情。视图来源沿用 `ProjectXApp.EnsureHeroEquipmentPresenter` 和 `BootstrapSceneBuilder` 的既有映射；动态槽位仍在原有循环/数据生成后查找，精确 Layer 前缀继续由 `FindNode` 兼容。
- 本轮源码确认 `HeroEquipmentPresenter.cs` 已无 `.Binding.Find(`；仅将该文件的代码路径检索收敛，不改 Prefab、`.meta`、装备状态或存档。Unity MCP 工具当前未暴露，Editor.log 修改时间早于当前源码，因此本轮编译与运行时身份/更换装备路线仍未验证，不重启 Editor/MCP。静态清单见 `.local/unity-validation/w6-presenter-binding-find-inventory-20260925.md`。

### W6 耗时复盘补充：错误分类与活动会话复用 — 2026-09-25

- 新增确认的耗时点：把 Unity EditorUpdateCheck 的 404、MCP session 生命周期日志和 Unity 编译错误混为同一“报错”，会引发无效重连/重启；上一轮 `[WebSocket] Unexpected receive error: WebSocket is not initialised` 出现在程序集 reload 期间，属于 MCP 接收循环警告；当时 `ProjectX.UI.dll` 更新且随后 Console error/warning 查询为0，只能说明那一轮。当前较晚的源码改动没有匹配的新程序集时间戳，编译状态另列为未确认。后续先按来源分类（Editor update / MCP HTTP transport / Unity Console compiler），同一项只查一次权威日志，不从头重跑已通过路线。
- 继续固定使用 `C:\Users\Admin\.codex\worktrees\a6b4\Game`；先按进程命令行核对 `-projectPath`，再复用存活的 Editor、LocalServer、Play、账号和夹具。MCP `editor/state` stale 时沿用一次 ping+短刷新规则；仍 stale 就转源码/批编译证据，不循环读取或重握手。只有拿到明确 Console error 或真实 UI 症状后，才针对该根因开测。
- 本轮追查补充：Editor log 中的 `Tundra build success` 只能证明那次构建结束，不能自动证明较晚改动的源码已进产物；要按源码修改时间核对对应 `Library/ScriptAssemblies/*.dll/.pdb` 的更新时间及同一轮编译日志。若产物证据没有覆盖最新源码，编译门保持未确认，继续静态工作并在最后集中编译。不要因进程仍活着、端口可连或旧日志中没有 `CS####` 就推断当前编译/编辑器状态。
- 本轮仅因 03:28 出现新的 MCP transport 活动，复用 PID 45088 与既有 HTTP 服务读取一次 `editor/state`；完整 initialize/initialized/GET stream/POST read 均成功，结果仍为相同 `sequence=3`、`stale_status`、age=1,472,368ms、`ready_for_tools=false`、Play=False、compiling=False。未发第二次 ping、未重握手/重启；之后仅做源码静态工作。此记录用于区分“HTTP transport 可用”和“Editor 状态快照新鲜”，避免再次从连接测试起步。
- 对照当前安装包源码 `Library/PackageCache/com.coplaydev.unity-mcp@30d2207509/Editor/Services/EditorStateCache.cs`（`OnUpdate` 287行、`!hasChanges` 346行、仅有变化才 `ForceUpdate("tick")` 364行）：`observed_at_unix_ms` 随 `BuildSnapshot` 更新，而稳定 idle 状态跳过构建。因此 snapshot 的 age 会持续增长并最终被标为 stale，即使 Editor 进程仍存活、transport 正常。本轮 scripts-only compilation 后状态序列仍为3且再次 stale，证明单纯重握手不能修复；不要用重连/重启制造假进展，也不修改 `Library/PackageCache`。运行门禁仍按项目规则处理；静态/编译工作可继续，状态恢复后只验纳入范围页面。
- 本轮一次性环境核对：Unity PID 45088 仍响应且 `-projectPath` 指向 C 盘 worktree；MCP bridge PID 39328 仍存在，但本机8080没有监听，项目 MCP 配置为 enabled。上轮 GameErrorPresenter 源码时间晚于 `ProjectX.UI.dll`，故编译门未通过。仅尝试恢复 bridge 本身时，执行策略拦截了 Stop/Start 命令，命令未执行、Editor/bridge 状态未被本轮改动；不改用其他终止方式绕过。后续先区分“进程存在”和“端口监听”，只在有可用 bridge 时复用当前 Editor 做一次脚本编译与 Console 读取；不可用则继续静态批次，不重走登录、账号或已验收路线。
- 最新编译证据复核（2026-09-25）：PID 45088 的 `-logFile` 确为 `.local/unity-validation/w6-guild-unitypath-20260925.log`；该日志最后写入时间为21:04Z，而 HeroEquipmentPresenter 本轮源码为21:26Z、`ProjectX.UI.dll/.pdb` 为19:47Z，因此日志和产物均早于本轮源文件，不能证明此次修改已编译，也不能以旧日志未见 CS 错误证明当前零错误。当前8080有 listener（PID 49056），但本轮没有暴露 Unity MCP 工具；不重启或手工反复握手，编译门保持未确认。

### W6 范围约束：屏蔽功能 Prefab — 2026-09-24

- 按用户确认，当前被屏蔽/不可达功能的 Prefab Metadata 暂缓处理；不为这些功能补入口、不修改其 Prefab/`.meta`，也不把它们计为本轮 W6 阻塞项。继续验收当前可达功能，遇到真实入口后再按页面证据评估。
- 境界页是当前可达功能：`Render()` 在每次填充后按模板身份清除 Panel_L/Panel_R 动态行克隆，再清除与直接序列化引用精确匹配的静态 Metadata；克隆核对跳过模板本身，兼容 Panel_End 模板位于 Attr_List 内的结构。根因是构造期清理后，同帧状态刷新可再次从尚未完成 Destroy 的模板复制 Metadata；清理放到每次 Render 末尾后，新克隆也会被处理。
- 干净 Play 的真实路径 `Btn_Old→Slot_01/Btn_Enter→Main→btn_jingjie` 通过。初次打开及真实关闭回主界面后再次打开，境界页均为 Metadata=0、Binding refs=86、动态属性行=7 且行 Metadata=0；`DynamicUi_OneLevelLayer=True`、`DynamicUi_shop_bg=False` 时内容可见，显示炼气及攻击200/物防100/法防100/生命4000等属性。

### W6.5 HeroHub 共享 OneLevel 查找迁移（编译/路线待验）— 2026-09-25

- `ProjectXApp.HeroHub.cs` 的共享页签条、标题和 `Panel_10` 三处固定路径已切到 owning `oneLevelFrameView.FindNode`；OneLevelLayer 路径身份沿用前述层级与序列化目标核对，虚拟 `Layer/` 前缀行为不变。
- 未改 Prefab、`.meta`、页签创建/显隐/顺序或交互时序。源码 `.Binding.Find(` 当前为 241 处/21文件；编译与 HeroHub 真实路线待验，旧 Editor 日志早于本次源码。

### W6.5 Hero attributes 弹层查找迁移（编译/路线待验）— 2026-09-25

- `ShowHeroAttributes` 对应 `shenjiangxiangxishuxing.prefab`。五个固定查询路径（名称、战力、定位、立绘、属性 ListView）逐一核对 owning-root Transform 与序列化 Binding target GameObject ID，均为同一对象；虚拟 `Layer/` 根路径由 `FindNode` 兼容。动态属性行仍按原时序创建在该 ListView 下。
- 五处改用 owning `heroAttributesView.FindNode`；渲染、克隆、弹层顺序和关闭绑定未变。未改 Prefab/`.meta`；全源码剩余 `.Binding.Find(` 为236处/21文件，编译及显示/关闭真实路线待验。

### W6.5 主界面 Chat 入口查找收敛（编译/路线待验）— 2026-09-25

- `ChatPath` 在 `UImainLayer_new.prefab` 无序列化 Binding 节点及层级对象；旧查找本就返回 null，点击入口继续由 `EnsureRuntimeChatEntry()` 创建独立的 `ChatEntryRuntime`。两处存在性/隐藏检查改为 `mainView.FindNode`，保持兜底分支不变。
- Friend/Guild（steam-excluded）查找未改。未改 Prefab/`.meta`；源码剩余 `.Binding.Find(` 为234处/21文件，编译及 Chat 实际路线待验。

### W6.5 主界面 Welfare/Activity 查找迁移（编译/路线待验）— 2026-09-25

- Welfare/Activity 排除门禁与 ActivityHotPoint 状态读取切到 owning `mainView.FindNode`。固定 HUD Prefab 的 `btn_fuli`、`btn_huodong` 路径身份一致；旧 ButtonGroup8 福利入口在层级及 Binding 中均不存在，排除分支仍为 no-op 后隐藏独立运行时入口。
- 未改 Prefab/`.meta`、运行时入口、点击或状态逻辑；源码剩余 `.Binding.Find(` 为230处/21文件，编译及 Welfare/Activity 路线待验。Friend/Guild 保持原排除处理。

### W6.5 登录/活动/公告/共享玩法壳查找迁移（编译/路线待验）— 2026-09-25

- 依据 Login、RoleCreate、UImain 实际来源映射及 Prefab 层级/序列化 target 核对，六处查找已迁至 owning view `FindNode`：登录按钮、招募入口命中区域、活动入口刷新、公告关闭模板、共享 `Main_UI` 与 `Bg` 壳节点。招募入口虽无单独序列化 Binding target，旧 resolver 与新 resolver 都回退到同一 Transform。
- 未改 Prefab/`.meta`、输入/显示时序；G4/G5 夹具验证查找未动。当前源码剩余 `.Binding.Find(` 为224处/21文件，编译与相关当前路线待验。

### W6 编译告警修正 — 2026-09-25

- 旧 Editor log 中的 CS0108 是 `UiButtonPressFeedback.animation` 字段遮蔽 Unity `Component.animation`。已将私有协程字段与所有引用改名为 `pressAnimation`；序列化数据和按压动画行为未变。最新改动尚未编译，需与待验的 W6 源码批次集中编译确认。
- `WebSocket is not initialised` 是程序集重载期间 MCP 接收循环警告，与 Unity 项目编译诊断分开；不因该提示重连/重启。另移除 `WorldBattlePlaybackPresenter` 重复的 `using System`，C 盘生成项目最新 build 为0 errors、1条既有 CS0649 (`ProjectXApp.taskButton`) warning。Unity `Library/ScriptAssemblies` 与 Editor log 停在07:30，而当前 `CocosUiBinding.cs`、`WorldBattlePlaybackPresenter.cs` 修改时间为07:36、07:41；Editor 日志中的 Tundra success 早于这两处源码，不能作为当前 Editor 编译证据，门禁仍待新鲜编译确认。

### W6.5 OneLevelLayer 生产查找收敛（编译/路线待验）— 2026-09-25

- 对 `TitleName`、`Btn_ListView`、`Panel_10`、`TitleName/Button_1` 复核 OneLevelLayer hierarchy 与序列化 Binding target GameObject，一致后将 ProjectXApp 中19处生产查找切到 owning `FindNode`。HeroEquipment G4/G5 验证调用保持原样，帮助按钮的点击绑定也保持不变。
- 未改 Prefab/`.meta`、页签创建与顺序。全源码当前 `.Binding.Find(` 为205处/21文件；近期源码统一编译及影响路线验收待做。

### W6.5 神将更换与公共道具来源路径迁移（编译/路线待验）— 2026-09-25

- `HeroReplacement` 的 ItemCell 命中 owning prefab 里相同的层级/Binding target；Empty 在两者都不存在，保留 null。公共 `huoqutujing` 的 Icon、item_icon、Mask、Button_3、Title 五条路径均核对到相同 GameObject，七处生产查找迁到各自 owning view 的 `FindNode`。
- G4/G5 validation 查询未动，无 Prefab/`.meta` 改动。全源码当前 `.Binding.Find(` 为196处/21文件；Unity 编译与受影响路线待验。

### W6.5 装备培养立绘与 HUD 子菜单路径迁移（编译/路线待验）— 2026-09-25

- 培养壳 `Icon`/`Icon_bg` 和 UImain `Main_UI`/`tankuang1`/`tankuang2` 的层级与序列化 target 相同；Draw 热区在 hierarchy 存在但没有 Binding 节点，旧 resolver 与 `FindNode` 都回退到同一 Transform。六处生产查找已迁移。
- 未改 Prefab/`.meta`、布局或 sibling 顺序。全源码当前 `.Binding.Find(` 为190处/21文件；统一编译与影响路线待验。

### W6.5 旧 Team/首局背包入口守卫迁移（编译/路线待验）— 2026-09-25

- `TeamLegacyPath` 与 FirstPlayableLoopBridge 的旧 `BagPath` 在当前 UImain hierarchy/Binding 中均不存在；旧 resolver 已会走同一 Transform 兜底并返回 null。两处改用 mainView.FindNode，运行时 TeamEntryRuntime 与首局 early return 不变。Friend/Guild 排除查找保留。
- 未改 Prefab/`.meta`；全源码当前 `.Binding.Find(` 为188处/21文件，编译/运行门禁待验。

### W6.5 YouLi/FengShenStory 共享模板查找迁移（编译/路线待验）— 2026-09-25

- YouLi 从 shop_bg 取 `Btn_close`；FengShenStory 从 OneLevel 取标题和 `GoldCheck`。三条路径均与各自 owning Prefab 的层级及序列化 Binding target 相同，已迁到 owning view `FindNode`。
- 无 Prefab/`.meta` 变更。全源码当前 `.Binding.Find(` 为185处/21文件；统一编译及影响路线待验。

### W6.5 HeroEnhanceMaster/JingJie 生产查找迁移（编译/路线待验）— 2026-09-25

- HeroEnhanceMaster 的5个英雄根、4个装备槽 EXPBar/Btn_yangcheng 共13个具体目标与 qianghuadashi Prefab 序列化 target 一致；4处调用迁至 owning views `FindNode`。JingjieLayer/Jingjieyulan 序列化路径分别86/86、31/31匹配 hierarchy，`JingJieRenderBridge.Require` 已切到 `FindNode`。
- 未改 Prefab/`.meta`。全源码当前 `.Binding.Find(` 为180处/21文件；编译与这两组实际路线待验。
- `RuntimeSnapshotCollector.BuildSerializedNodeIdentityIndex` 与实际 `ResolveNodeIdentity` 对退场的100个节点逐个复验，100/100 保留原 CocosPath、NodeType 和 Snapshot source，RectTransform 缺失=0。真实 OneLevel Close Raycast 首命中 `onelevel.close`，关闭后 Main 恢复且 OneLevel/shop_bg 隐藏；重开命中 `main.jingjie`。Console Error=0，仅 LocalServer 孤儿回收 Warning(pid=32724)。界面截图 `.local/unity-validation/w6-jingjie-view-capture-mcp.png`。未改 Prefab、`.meta`、存档或库存；证据 `.local/unity-validation/w6-jingjie-metadata-scope-20260924.md`。
- 本页退场完成不代表 W6 收口；全局 Snapshot/path fallback 及其他消费者仍待闭环。被屏蔽/不可达功能 Prefab 的 Metadata 按用户要求暂缓。

### W6 当前源码调用清单校准 — 2026-09-25

- 早先续接盘点曾为169处/11个 C# 文件、`ProjectXApp.cs` 119处；后续调用迁移后，本次精确复点为165处/11文件、`ProjectXApp.cs` 115处。当前以165处逐文件清单为准，不沿用旧数字或重复已迁移 Presenter。
- 本次精确复点为164处/11个 C# 文件：`ProjectXApp.cs` 114处，5个验证 partial 合计42处，其他混合/Steam排除文件8处；Presenter只剩Friend/Guild各1处，二者由 `STEAM_SCOPE.md` 明确排除。`ProjectXApp.cs` 中101处属于验证/审计方法、4处在 `ValidateLoginUi`，9处在共享/生产/Steam边界辅助方法。不对通用路径 fallback 做批量替换。全局 `CocosUiBinding`/Metadata/Snapshot 身份例外、W6.4不可达页面、受影响真实路线仍未收口，W6保持未完成。
- 当次环境复核：Unity PID 45088 仍使用 C 盘 worktree；MCP 8080 listener PID 49056仍在，但复用已知旧 session 读取 `editor/state` 返回404。本次未 initialize、重启或重走 Play；后续运行验证应由宿主提供当前有效会话，期间继续静态工作。`UiButtonPressFeedback` 当前字段为 `pressAnimation`，旧 CS0108 不再由当前源码触发；目标依赖程序集 dotnet build 已通过，但 Unity Editor 编译仍待确认。

### W6.5 Hero level-up runtime node lookup — 2026-09-25

- `BindHeroLevelUp` 的 `ExpBar` 与材料 `Text` 两个生产查找，以及其唯一调用者 `SetRuntimeBoundIcon` 的 `IconImage` host 查找，改为 owning view `FindNode`。该 view 固定由 `UiRouter.FindBySource("shenjiangyangcheng/yingxiongshuxingLayer")` 提供；基于 Prefab Transform 链的校验脚本确认三条路径匹配（3/3）。同一 view 的 `HeroCultivationPresenter` 也以 `FindNode` 使用 ExpBar/材料节点。只替换查找入口，数值、文本、填充比例及材料显示逻辑未改。
- 无 Prefab/`.meta` 修改。当前全源码调用数为166处/11文件，其中 ProjectXApp.cs 116处。`dotnet build ProjectX.Core.csproj --no-restore --verbosity:minimal` exit code=0、0 errors、1 warning（既有 `ProjectXApp.taskButton` CS0649）；没有 CS0108。神将升级页真实路线仍待运行时验收；W6 不收口。

### W6.5 HeroEnhanceMaster 动态品质图标查找 — 2026-09-25

- `SetRuntimeBoundQualityIcon` 的两个调用都来自 `BindHeroEnhanceMaster`，view 固定映射到 `zhuangbeiyangcheng/qianghuadashi.prefab`。按实际 Prefab 两空格 Binding node 列表取 target，再沿 Transform 父链比对 owning-root 相对路径：5 个英雄图标和4个装备/法宝图标均匹配（9/9）。host 查找改为 `view.FindNode`，动态品质框、图标的父节点和 sibling 行为不变。
- 无 Prefab/`.meta` 修改。最新 `dotnet build ProjectX.Core.csproj --no-restore --verbosity:minimal` 成功，0 errors、1既有 CS0649 warning。源码 `.Binding.Find(` 当前164处/11文件，ProjectXApp.cs 114处。强化大师实际路线仍待运行时验收。

### W6.5 Main HUD premium AddBtn lookup — 2026-09-25

- `BindPlayerHudControls` 的元宝补充按钮由 `mainView.Binding.Find` 改为 `mainView.FindNode`。只读解析 UImainLayer_new Prefab 的217个 GameObject/Transform，确认 owning-root 路径为 `Main_UI/ButtonGroup6/Icon_yuanbao/AddBtn`，虚拟 `Layer/` 前缀剥离后可直接命中；该 path 不在90条例外中。
- 修改后 Core dependency build 通过：0 errors，1条既有 `ProjectXApp.taskButton` CS0649 warning。HUD真实 EventSystem 路线并入后续集中验证；未改 Prefab/`.meta`。证据 `.local/unity-validation/w6-mainhud-premium-findnode-migration-20260925.md`。

### W6耗时复盘补充：Prefab YAML 检查器先做解析自检 — 2026-09-25

- 一次临时检查器误用了六空格节点列表并把 owning prefab root 纳入相对路径，导致三条正确路径显示空解析/假 mismatch。纠正后检查器先断言 GameObject、Transform、Binding path map 非空，再用真实两空格列表结构，并对 root-relative path 比较；原三条目标全部通过。后续不可把检查器解析失败当作项目资产错误，禁止据此修改 Prefab 或重跑页面路线。
- 背包固定账号夹具新增“所有配置 ItemType 均至少有一个代表道具”的断言后，漏配了唯一的 ItemType=4 代表道具 610，导致 AssertSetup 必然失败。已补齐 610；以后扩展覆盖断言时，同一轮先由配置和夹具做集合差集校验，再碰真实数据库或启动运行环境。本次只做语法和 13/13 配置覆盖静态检查，未执行夹具 Setup。
- MCP 8080 listener 与 Unity PID 都存活时，复用旧 session ID 仍返回 HTTP 404。端口存活不代表旧 session 有效；本次没有 initialize、重启 Editor/MCP 或重走 Play，而是记录 transport 边界并继续静态工作。后续运行验证应由宿主提供当前有效会话；不要猜 session 或循环握手。

### W6.3 全量 Snapshot 路径/目标例外复核 — 2026-09-25

- 对 C 盘 worktree 当前 359 个 ProjectX Prefab 重建 CocosUiBinding/Metadata 路径与 GameObject fileID 对照；解析总量与基线完全一致：19,690 条 Metadata、19,629 条 Binding 引用、19,600 条同路径同目标、90 条例外。逐项清单为 `.local/unity-validation/w6-snapshot-exception-inventory-20260925.json`。
- 90 条分类：48 条 CocosPath 已由另一序列化目标占用；5 个 Metadata 目标已在 Binding 中以其他路径引用；37 条目标/路径均无冲突且有序列化祖先，其中7条可由祖先+Transform精确还原（Main HUD 6条、神铸 Item_bg 1条），30条派生路径与 CocosPath 语义不同。其余分布：UImainLayer_new 29、WorldMapNewLayer_1 22、zhuangbeisuipian 15、loginLayer 8、DadituuiLayer 6、SystemLayer 5、zhuangbeibeibao 2，其余3个 Prefab 各1。
- 现按对象身份分类闭环：85个Metadata目标没有其它Binding target引用，退场前把旧路径作为运行时别名追加；其中48条路径冲突保留已有序列化项在前，保证无类型 `Find(path)` 仍先返回原序列化目标，同时恢复 typed `Find`/Snapshot 对另一目标的身份。另5个目标已有其它路径的序列化身份，不追加路径，以免改变 Snapshot 规范身份。48/48条路径冲突中的 Metadata target 与原路径 target 都是有效 GameObject。
- 静态分类和生成项目编译通过，不代表所有页面的真实退役/Snapshot回读或全局消费者已闭环。未改 Prefab 或 `.meta`；W6.3 继续进行。

### W6.3 旧 CocosPath 的运行时身份别名 — 2026-09-25

- `CocosUiBinding` 在运行时退役 Metadata 前，现为没有任何序列化目标引用的 Metadata 节点追加精确旧 `CocosPath` alias，不再要求存在可推导的序列化祖先；因此覆盖7条祖先路径精确项、30条 Unity 路径语义不同项，以及48条同路径先被另一个目标占用项。
- 对已有 path 冲突，别名追加在序列化 nodes 之后，原无类型 Find 的首个有效序列化目标继续优先；typed Find 的同三元组序列化项也仍优先，否则可命中新 Metadata alias。另5个已有 target identity 的Metadata不追加，保留 Snapshot canonical identity。Dadituui两个同path/type/actionTag目标按Metadata遍历顺序追加，维持旧 first-match。
- 对48条 path-conflict rows 静态确认Metadata target和既有path target均为有效 GameObject（48/48）。`dotnet build ProjectX.Core.csproj --no-restore --verbosity:minimal` 在别名和HUD变更后成功，0 errors、2条既有warning（WorldBattlePlaybackPresenter重复 `using System`、`ProjectXApp.taskButton`未赋值）；此为生成项目依赖编译，不替代Unity Editor编译。
- Bag 的 `BagPageBinding` 原本绕过通用退役入口；现委托页面根 `CocosUiBinding.RetireLegacyNodeMetadataAtRuntime()`，让同一别名和Snapshot保留逻辑覆盖Bag。85条Metadata退役后的真实Binding/Snapshot identity回读尚未验证，故不计W6.3完成。变更文件为 `UI/Migration/CocosUiBinding.cs`、`UI/BagPageBinding.cs` 与 `Core/ProjectXApp.cs`，无Prefab/`.meta`修改。
- 后续补齐剩余5个“Metadata目标已有其他序列化路径”的查找兼容：旧身份放入当前 `CocosUiBinding` 实例的非序列化 alias 列表，并作为 serialized/活动 Metadata lookup 之后的 fallback；不并入 `nodes`，避免改写 Snapshot canonical path。静态 inventory 显示5/5条旧路径也各有一个序列化 path target；fallback 不抢先于该 target，维持退役前 Find 的同样优先级。`Initialize()` 清空临时列表，防止复用 Binding 时串入旧别名。C 盘 worktree `dotnet build unityclient/ProjectX.Core.csproj --no-restore --verbosity:minimal` 成功，0 errors、1条既有 warning；Unity Editor 已于07:45完成含 `CocosUiBinding.cs` 等当前全部 Assets C# 源码的 Tundra 编译（最新源07:41，ScriptAssemblies产物07:45），0 errors，2条 CS0618 warning 位于 `NormalizeSharedUiSprites.cs`。90例真实运行时退役/回读仍待验证。
- MCP/Editor 时效复核：项目 `.codex/config.toml` 中 `unityMCP.enabled=true`；8080 listener PID 49056 与 Unity PID 45088（`-projectPath C:\Users\Admin\.codex\worktrees\a6b4\Game\unityclient`）均存活。此前可用 session `d13d1fc4fe7743e1949a44634329460a` 本轮只读 `editor/state` 返回404；未重新握手或重启。当前工具列表没有 Unity/computer-use 控制入口。最新 Editor log 和 `Library/ScriptAssemblies` 已更新到07:45并覆盖当前源码；因此接下来仅需等待宿主恢复有效 MCP session/控制入口，以单批 Play 完成90例回读及未验 W6.5 路线。不要重试旧 session 或重复初始化。

### W6.5 PlayerHub 页签显示节点验收修复 — 2026-09-25

- 用户截图中的背包选中态问题已在 PlayerHub 当前编译版复现并修复：真实点击 Bag 后 `ChooseBg` 激活、`ChooseBg/BtnName` 文本仍隐藏；根因为运行时克隆继承隐藏态，而 `SetTabText` 未同步 selected label 的 active 状态。代码现在在写入文本后按 selected 显示/隐藏该节点；无 Prefab/`.meta` 变更。
- scripts-only compile 后检测到 Unity domain reload 清空了 `ProjectXApp.Instance`，因此按既有流程做一次 Play Stop/Play 恢复，复用本地已有 user 1/role 1000001 的 `login.play` 真实输入；未重建账号/角色、修改 SQLite 或夹具。
- 当前新 Play 中真实输入选择 Bag、Mail、Settings，逐次核对选中背景/选中标签/普通标签的显隐。Bag 与 Settings 页面状态分别为 true；Mail 输入到达目标。Bag 和 System 选中态的 GameView 截图已保存；四个标签文字完整，Console error/warning=0。证据见 `.local/unity-validation/w6-runtime-presenter-route-batch-20260925.md` 及两张截图。
- 此修复仅关闭 PlayerHub 页签标签显示缺陷。W6.3 90例退役 Metadata/Snapshot 身份回读、其它未验 Presenter 与不可达入口仍未完成，W6保持进行中。

### W6.5 当前编译版真实 Presenter 路由批次 — 2026-09-25

- 使用 C 盘当前 Editor PID 45088、已有 MCP HTTP bridge 和同一 Play 连续验收；没有重新登录、重启 Editor/Play/LocalServer 或修改账号/SQLite。Main `btn_jingjie`→境界预览→两级 Close、`btn_zhaomu`→三个招募池同时显示/六个单抽与十连目标真实 Raycast→Close、`btn_chuandai`→装备列表→培养页、Main `btn_fuben`→世界详情/章节按钮→World Close，均完成对应无消耗可见路线。
- World `duiwu` 真实打开 `DynamicUi_shenjiangzhenxingLayer`，6 个运行时阵型行存在；使用 Hierarchy 中实际 `RuntimeFormationClose` 关闭后再关闭 World。World `btn_zhenrong` 打开 Hero list/info，`Btn_xiangxi` 打开属性层并由真实 `Mask_close` 关闭；回退顺序为属性→World→Main。未选择、挑战或提交阵型。
- Main `btn_zhenrong` 打开 Hero cultivation；升星/突破/修炼/信息四个 Tab 的 Inspect/Dispatch 均通过，未执行升级，但各页切换后的内容文本未逐一断言，因此仅记控件输入通过。Head 打开共享 OneLevel 后读取 sibling 顺序为 0–3：境界/背包/邮件/系统；邮件页真实点击时 `CurrentTab=Mail`、`jingJieSurfaceMode=Mail` 且 Mail view 位于活动 OneLevel，随后真实 Close 返回 Main。既有 Bag/Mail/Settings 内容未重测。
- `btn_huodong` 在当前运行态 inactive，静态福利入口与 Chat 入口节点也不存在；这些路线不以坐标或内部方法绕过，维持未验。设备/主界面最终回到 Main、OneLevel关闭、EventSystem正常；Editor Console error/warning=0。探针侧命名空间/保留字/缺失动态子节点错误已与 Unity Console 分开识别；准确路径、每条路线边界和恢复记录见 `.local/unity-validation/w6-runtime-presenter-route-batch-20260925.md`。
- 此批次补上 HeroCultivation/JingJie、Draw 可见池、FormationPopup、World、Hero attributes、HeroHub共享页框、Mail页入口的部分或目标路径级真实输入证据；不等于完整 Presenter 行为、视觉差异验收或 W6 完成。战斗/结果、抽奖/奖励、不可达活动入口和其他未覆盖 Presenter 仍待验；W6.3 的90例 Metadata退役与 Snapshot身份回读也仍待完成。

### W6.3 90条 Metadata/Snapshot identity runtime readback — 2026-09-25

- 当前 C 盘 Play（PID 45088）使用实际 Unity 运行时 `CocosUiBinding.RetireLegacyNodeMetadataAtRuntime` 和 `RuntimeSnapshotCollector.BuildSerializedNodeIdentityIndex` / `ResolveNodeIdentity`。只从既有90条例外清单加载10个源 Prefab 到不可见、DontSave 的临时对象；逐行按源 asset local fileID定位目标，再用 sibling-index path映射到克隆 Transform。Before/after 对每行比较 `semanticId`、`nodeType`、`source`。
- 90/90 Snapshot identity 完全一致；目标 Metadata 实例在异步 Destroy 完成后90/90不存在；预期的85个路径别名在 owning `Nodes` 保留、另5个已有 canonical 序列化路径的目标在 owner-scoped aliases 保留，90/90通过。10个 owning Binding 共退场784个临时 Metadata；临时实例及784个新增全局 retired identity 已清除，原 Play 的202条 retired identity恢复不变。
- 运行最终复核：`Application.isPlaying=true`、`ProjectXApp.Instance=true`、NetworkState=Connected、Main HUD active、OneLevel inactive、临时 probe root=0、Console Error/Warning=0。无 Prefab/`.meta`/SQLite/夹具/账号数据修改。逐项清单和完整方法见 `.local/unity-validation/w6-identity-snapshot-runtime-readback-20260925.md`。
- 本结果关闭W6.3这90条对象身份/Snapshot回读子项；不关闭其它全局 `CocosUiBinding`/Snapshot 消费者、W6.5待验路线或W6.4不可达入口，W6仍进行中。

### W6.5 HeroEquipment 强化/精炼/觉醒/神铸页签当前运行版验收 — 2026-09-25

- 同一 C 盘 Play 中，在已打开的装备强化面板逐个对精炼、觉醒、神铸页签执行 `RuntimeInputDispatcher.Inspect`→`Dispatch`。首命中分别为 `HeroEquipmentRefineTab`、`HeroEquipmentAwakenTab`、`HeroEquipmentDivineTab`；各次操作后读取实际活动 Canvas 下的可见 UI 文本。精炼显示属性对比、命中/攻击、经验道具与消耗区；觉醒显示星品属性、附加属性与消耗区；神铸显示属性、特效文案、碎片/货币消耗区。强化页属性、等级、货币和强化控件也可见。没有点击强化、精炼、觉醒或神铸消耗按钮。
- 神铸页运行时截图经实际图像检查：当前选中页签底图和“神铸”文字均可见；页签标题、属性、特效与消耗布局可读。证据 `.local/unity-validation/w6-hero-equipment-tabs-runtime-20260925.md`、`.local/unity-validation/w6-equipment-divine-runtime-20260925.png`。
- Play 与 `ProjectXApp.Instance`保持有效，Console error/warning=0；未重登、重启、改动账号/SQLite/装备或 Prefab。该项仅关闭这四个装备培养页签的运行时输入和内容显示检查；装备详情/更换/FaBao/自动精炼等其他路线及全部 W6 其余范围仍待验，W6 保持进行中。
