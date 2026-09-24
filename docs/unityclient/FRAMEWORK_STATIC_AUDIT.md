# Unity 客户端内部框架治理：W0-W2 静态审计

> 审计日期：2026-09-23
> 范围：`unityclient/`；只读源码、Prefab、Catalog、ProjectSettings 与既有文档证据。
> 本轮禁止：启动/接管 Unity、MCP、本地服务端、Cocos、MySQL；修改业务源码、Prefab、`.meta`、用户维护资源和迁移状态。

## 1. 结论前置

- 初始 W0-W2 审计时，当前 worktree 为 detached `HEAD`，`HEAD=origin/main=95fb980b`；当时工作区变更仅为未跟踪的 `FRAMEWORK_WORK_PLAN.md` 与本审计报告两份文档。后续 Mail W4.3 试点变更以工作计划记录为准。
- Unity 工程版本为 `2022.3.62f3c1`；Build Settings 仅启用 `Assets/ProjectX/Scenes/Bootstrap.unity`，`FirstPlayableLoop.unity` 未启用。
- 初始 W0-W2 审计未编译、未启动 Player/Editor、未调用 MCP。此前检查到的 Unity/MCP 属于另一个 `E:\neiwang_kapai\Game\unityclient` checkout，经用户确认是其主动启动，现已关闭，不作为项目风险。后续 W4.3 运行复核只启动当前 worktree：Unity/MCP 已连接，Bootstrap Runner 已进入 Play 并显示登录画面；Mail真实入口仍待输入。W4.3 batch 编译证据记录在工作计划和 `.local/unity-validation/mail-w4-compile-after-lfs.log`。
- 当前工程没有 `.asmdef`；`ProjectX` 全部运行时代码仍处于默认 `Assembly-CSharp` 编译边界。静态依赖已经出现 `Core ↔ UI`、`Core ↔ Validation` 方向，后续拆 asmdef 前必须先做依赖收敛设计。
- `GameServices` 是全局组合根，同时持有网络、协议、Lua、资源、时间、UI Router/Stack、配置和大量业务 Store；`ProjectXApp.cs` 约 9,255 行，`ProjectXApp*.cs` 共 52 个 partial 文件。它是当前最明显的过载点，但本轮不拆分。
- UI 仍以 Cocos 迁移绑定为主：全工程 359 个 Prefab 均包含 `CocosUiBinding`，357 个包含 `CocosNodeMetadata`，27 个包含 `CocosTimelinePlayer`。不能把这些组件批量删除或直接替换为“更通用”的 Unity 组件。

## 2. W0 安全与基线

### 2.1 Checkout、版本、进程与端口

| 项 | 静态结论 | 证据 |
|---|---|---|
| checkout | `C:\Users\Admin\.codex\worktrees\a6b4\Game`，detached `HEAD` | `git status --short --branch`、`git rev-parse --show-toplevel` |
| Git 基线 | `95fb980b 重构：整理 Unity 数据目录与本地运行资源`，与 `origin/main` 一致 | `git log -1 --oneline --decorate` |
| Unity | `2022.3.62f3c1` | `unityclient/ProjectSettings/ProjectVersion.txt` |
| Build Scene | `Bootstrap.unity` enabled；`FirstPlayableLoop.unity` disabled | `unityclient/ProjectSettings/EditorBuildSettings.asset` |
| 规模 | 5 个 Scene、359 个 Prefab、213 个 `src` C# 文件、无 asmdef | `rg --files` 静态计数 |
| 本轮变更 | 仅工作计划未跟踪；无业务源码/Prefab/`.meta` 脏改动 | `git status --short --untracked-files=all` |
| 外部进程 | 已有 Unity/MCP 指向 `E:\neiwang_kapai\Game\unityclient`，不是当前 worktree；本轮未启动、未停止 | `Win32_Process` 只读检查 |
| 服务端端口 | `127.0.0.1:8711`、`3306` 均无监听；8080 为已有 MCP HTTP 服务 | `Get-NetTCPConnection` 只读检查 |

### 2.2 数据、启动和验证边界

- Unity 用户数据边界仍是 `Application.persistentDataPath/LocalServer/projectx.db`；workspace MySQL 不得替代 Unity 用户夹具。
- `ProjectXApp.Startup.cs` 的静态启动链为：单例 `Awake` → 单机存档/本地服务判断 → `GameServices` → `RuntimeSnapshotCollector` → 网络/Lua 回调注册 → `RunCurrentCocosStartup`。本地服务由 `LocalServerSupervisor` 持有；初始 W0-W2 审计没有触发该链路。W4.3 运行复核已在当前 worktree 通过 Unity/MCP 打开 Bootstrap 并进入 Play，确认登录画面和 GameView 1334×750；Mail 参数下已确认 `kapai.exe` 由 Supervisor 持有且 `127.0.0.1:8711` 监听，但本轮尚未把程序化回调当作 Mail真实输入验收。
- 既有文档中可引用的历史证据包括 Login、World、Fish、HeroRebirth、XunBao 等模块的编译/真实 Play/恢复记录；它们只作为基线索引，不等于本轮当前 checkout 的重新验证。
- 当前焦点仍是 Unity 现有功能 Bug 验收，不重开迁移 G0-G6；框架治理只能先做静态盘点，不能改变 `UNITYCLIENT_STATUS.md` 的迁移状态。

### 2.3 保护范围与脏文件重叠

以下资源在现有状态/模块文档中被明确为用户维护或只读布局基线，本轮不写入：

| 保护级别 | 资源/范围 | 原因 |
|---|---|---|
| 强保护 | `unityclient/Assets/ProjectX/res/csd/Prefabs/FishLayer.prefab`，尤其 `FishUI/FishScene/pos` | 当前状态明确要求以后以用户维护 Prefab 为基础；Fish 已在最后一次挂点调整后通过用户 Play |
| 只读布局 | `res/csd/Prefabs/huishou/shenjiangchongsheng.prefab`、`res/csd/Prefabs/common/Choose.prefab` | HeroRebirth 文档冻结用户布局和 SHA |
| 只读布局 | `res/csd/Prefabs/wanfa/Xunbao_souxunLayer.prefab` | XunBao 文档冻结用户调整后的按钮文字布局 |
| 只读/不覆盖 | `res/csd/Prefabs/zhuangbeiyangcheng/zhuangbeiyangcheng.prefab`、`res/csd/Prefabs/shenjiangyangcheng/yingxiongbeibao.prefab` | HeroEquip/EnhanceMaster 文档明确不覆盖用户资源 |
| 已验收布局基线 | `kapaiguaiwuLayer.prefab`、`zhuangbeiyangcheng.prefab`、主界面用户调节入口与 World `DadituuiLayer` | 仅作后续来源证据，不在本轮重排或重建 |
| 全局保护 | 所有 `.meta`、`unityclient/Captures/`、已验收页面 Prefab | AGENTS.md 与当前任务明确禁止修改 |

当前 `git status` 没有上述路径重叠；工作计划和本审计报告属于文档白名单。

## 3. W1 架构与依赖盘点

### 3.1 当前依赖图

```text
Bootstrap.unity
  └─ ProjectXApp (MonoBehaviour, DontDestroyOnLoad)
       ├─ Startup / LocalServerSupervisor / SinglePlayerSaveService
       ├─ GameServices 组合根
       │    ├─ AppState / AppConfig / ConfigService / ServerTimeService
       │    ├─ NetworkService → LegacyTcpClient
       │    │       └─ ProtocolRegistry + ProtocolDispatcher
       │    ├─ LuaRuntimeService → Lua/Bootstrap.lua
       │    ├─ ResourceService / ResourcesUiAssetProvider
       │    ├─ UiRouter / UiStack / UiPrefabLoader
       │    └─ Data Store + Catalog 集合
       ├─ ProjectXApp partial handlers
       │    ├─ Lua callback registration and protocol entry points
       │    ├─ Store mutation / refresh
       │    ├─ Presenter creation, frame state, tab state, close/back
       │    └─ Validation and runtime snapshot hooks
       ├─ UI Presenter
       │    ├─ CocosUiView / CocosUiBinding.Find(path)
       │    ├─ OneLevelFrameCoordinator / UiStack
       │    ├─ ResourcesUiAssetProvider → UiPrefabCatalog + UiPrefabReference
       │    └─ VirtualList / ScrollRect / runtime Instantiate + sibling/raycast repair
       └─ Validation
            ├─ RuntimeInputDispatcher / RuntimeSnapshotCollector
            └─ direct dependency back to Core and UI.Migration

Editor tools
  └─ BootstrapSceneBuilder / CocosUiImporter / CocosBindingCleaner
       └─ imported Prefab + Cocos metadata + Resources/UiPrefabs Catalog
```

### 3.2 分层盘点

| 层 | 静态规模/入口 | 当前责任 | 方向风险 |
|---|---|---|---|
| Core | 62 C#；`ProjectXApp*.cs` 52 个 partial；主文件 9,255 行 | 启动、全局状态、Lua 回调、路由、页面生命周期、验证入口 | 业务、编排、验证、迁移兼容集中在一个 MonoBehaviour；Core 同时依赖 UI/Data/Network/Lua/Validation |
| GameServices | `GameServices.cs` 构造约 34 类 Store、Catalog、Network、Lua、UI 和资源服务 | 全局对象图与统一 Tick/Dispose | 生命周期集中；新增服务继续堆入会扩大组合根和销毁顺序风险 |
| Data | 53 C#；34 个 Store 文件、13 个 Catalog 文件及 Config/Model | 权威状态、配置读取、业务数据刷新 | Data 仍依赖 Network/Diagnostics；Store 通知由 Presenter/Core 各自订阅 |
| Network | 6 C# | TCP、协议定义/注册/派发、请求超时和断线 | ProjectXApp 直接持有大量 LuaFunction 与协议回调，尚未形成 Feature-owned adapter |
| LuaRuntime | 3 C# | Lua VM、Bootstrap、错误边界、FirstPlayableLoop 兼容入口 | 正式启动和验证入口共享相同运行时基础设施 |
| UI | 68 C#；53 Presenter；`Migration` 3 个核心绑定组件 | 视图查找、Stack、动态 Prefab、Presenter 渲染、列表和共享框架 | UI 依赖 Core；大量路径字符串、共享节点显隐、监听清理和 Raycast 修复分散在 Presenter/Core |
| Validation | 2 C# | 运行时输入派发和快照采集 | `Validation → Core`，同时 Core → Validation，后续 asmdef 必须打断反向依赖 |
| Editor | 14 C# | 导入、Catalog/Bootstrap 生成、清理/校验工具 | 依赖 Core/UI/Migration；不能在治理阶段直接作为运行时基础设施复用 |

### 3.3 可确认的过载与循环

1. `GameServices` 同时负责构造、事件接线、Tick、UI 资产提供和所有 Store Dispose；它适合作为现有组合根，但不应直接演化为新的“大框架”。
2. `ProjectXApp` 的 partial 已按业务域分散文件，但仍共享同一个生命周期、事件字段、UI 字段和 `services` 入口；partial 只是组织方式，不是依赖隔离。
3. `UI` 使用 `ProjectX.Core`，而 `Core` 使用 `ProjectX.UI`；`Validation` 使用 `Core`，而 `Core` 又使用 `Validation`。当前无 asmdef，因此编译器不会强制阻止这两组循环。
4. UI 迁移层同时提供三种查找后备：序列化节点引用、`CocosNodeMetadata`、Unity hierarchy `Transform.Find`。这保证了已验收页面兼容，但也使 Prefab 层级调整必须有来源、路径和运行时证据。

## 4. W2 Prefab/UI 组件台账

### 4.1 资产总量与 Catalog

| 项 | 数量/结论 | 说明 |
|---|---:|---|
| `res/csd/Prefabs` 导入 Prefab | 358 | 主要来源；按 common、养成、活动、战斗等目录分布 |
| `Generated/FloatNoticeLayer.prefab` | 1 | 额外生成 Prefab |
| 全工程 Prefab | 359 | 每个均含 `CocosUiBinding` |
| `CocosNodeMetadata` | 357 个 Prefab 文件 | 两个 Prefab 不含该组件，但不能据此删除绑定体系 |
| `CocosTimelinePlayer` | 27 个 Prefab 文件 | 动画/Timeline 仍是独立迁移语义 |
| `Resources/UiPrefabs` | 133 个引用资产 + `Catalog.asset` | `UiPrefabReference` 按 key 指向导入 Prefab |
| Catalog 条目 | 133 | 102 个无 parent；`OneLevelLayer` 16、`huodong_bg` 5、`shop_bg` 4、`shenjiangzhaomu` 4、`ActivityRankingLayer` 2 |
| Catalog 默认激活 | 8 | Activity、登录和抽卡的少量启动/容器节点；不能理解为全部运行时页面 |

### 4.2 共享容器与重点 Prefab

| 资产 | 静态结构 | 运行时责任/风险 | 分类 |
|---|---|---|---|
| `OneLevelLayer.prefab` | 约 151 个命名节点、50 个 RectTransform；含 `GoldCheck`、`Panel_10`、`Panel_12`、`Btn_ListView`、`ListView`、`CloseBtn` | 神将、境界、背包、邮件、鱼场等共享外框；Presenter 会修改显隐、标题、页签、父子关系和 sibling | 暂不可动；后续只能先抽协调协议，不能先换 Prefab |
| `CommonPageLayer.prefab` | 34 个命名节点、11 个 RectTransform；含 `PageBg`、`Panel`、`List`、`Content`、`BtnName` | 独立的通用页内容壳，当前不在 `UiPrefabs/Catalog.asset`，不能仅按名称假设已被运行时统一加载 | 可适配但先补引用闭包；暂不纳入公共框架替换 |
| `shop_bg.prefab` | 约 70 个命名节点、22 个 RectTransform；有 `shop_bg`、`Btn_ListView` | 普通商城、装备详情、来源/奖励等弹窗复用；容易被旧 Presenter 重绑关闭和遮罩 | 暂不可动；仅允许在共享 UI 试点中适配 |
| `huodong_bg.prefab` | 约 104 个命名节点、34 个 RectTransform；有 `Btn_ListView`、`huodong_bg`、`CloseBtn`、`GoldCheck` | 活动/任务/签到等共享父容器；Catalog parentKey 还有 5 个子页面 | 暂不可动；先做 owner/close/raycast 台账 |
| `beibao.prefab` | 约 149 个命名节点、53 个 RectTransform；有 `ItemCell`、`TableView`、`Content` | Bag/Fish 鱼篓/奖励类页面共用格子语义但数据、领取和滚动合同不同 | 可适配，不可直接抽成同一业务 Cell |
| `MailLayer.prefab` | 约 130 个命名节点、42 个 RectTransform；有 `ListView` | Mail 列表、已读/领取/删除和空态由 MailPresenter 控制 | 可适配；先定义 Mail 专属状态模型 |
| `FishLayer.prefab` | 约 126 个命名节点、40 个 RectTransform；含 `FishScene`、`pos`、2 个 `ListView`、`LoadingBar` | 用户维护场景底图和挂点；Presenter 只应挂载角色和渲染状态 | 强保护；不可重构布局或动态替换场景资源 |
| `ActivityLayer.prefab` | 约 84 个命名节点、27 个 RectTransform | 活动入口/列表与 `huodong_bg` 的组合 | 可适配，但受当前 Steam 范围和旧活动边界限制 |
| `Xunbao_souxunLayer.prefab` | 约 45 个命名节点、14 个 RectTransform | 用户调整的搜索结果 UI，包含批次追加和正式品质框 | 只读布局；可在 Presenter 内封装渲染适配 |
| `shenjiangchongsheng.prefab` | 约 141 个命名节点、47 个 RectTransform | 重生奖励列表、确认弹窗和来源详情 | 只读布局；动态奖励行可治理但不改静态节点 |

### 4.3 共享节点、动态操作与输入

- `CocosUiBinding.Find` 的顺序是序列化引用 → `CocosNodeMetadata` → hierarchy path；这三层必须视为同一兼容边界。
- UI 代码静态命中：`SetActive(` 57 个文件、`Instantiate(` 33 个文件、`Destroy(` 37 个文件、`SetAsLastSibling(` 32 个文件、`SetSiblingIndex(` 5 个文件、`AddListener(` 49 个文件、`RemoveAllListeners(` 50 个文件、`raycastTarget` 39 个文件、`ScrollRect` 21 个文件。
- `VirtualList<T>` 已提供复用行、ScrollRect relay、旧行隐藏和 Dispose；适合成为公共列表基础，但其绑定回调仍由页面决定，不能把所有 Bag/Mail/Reward/Shop 行强行合并。
- 当前存在运行时节点命名约定：`DynamicUi_*`、`Runtime*`、`VirtualRow_*`。共享容器切换时必须同时复位显隐、监听、父节点、Sibling、Raycast、关闭行为和数据刷新。
- Loading/Empty/Error 不是统一组件：源码中各 Presenter 以路径和页面状态自行控制；W3/W5 前不得假设可以直接建立单一 `UiStateView` 并替换现有页面。

### 4.4 后续通用化边界

| 结论 | 内容 |
|---|---|
| 适合先通用化 | `UiStack` 的 push/pop/clear 合同；`UiRouter` 的 owner 查找接口；`ResourcesUiAssetProvider` 的加载/释放合同；`VirtualList<T>` 的行复用与 Dispose；共享 Frame 的状态清理清单 |
| 可适配但保留迁移层 | `CocosUiView.BindClick`、`CocosUiBinding.Find`、`CocosNodeMetadata`、`CocosTimelinePlayer`；先包边界，不删实现 |
| 高风险适配 | `OneLevelLayer`、`shop_bg`、`huodong_bg` 的 owner/close/tab/raycast 协调；需要真实 EventSystem Play 后才能进入实现 |
| 暂不可动 | FishLayer、HeroRebirth、XunBao、HeroEquip/EnhanceMaster 用户 Prefab；所有 `.meta`、Cocos 绑定脚本、动态 UI Catalog 和迁移状态 |
| 不纳入本轮 | asmdef、AppScope、Prefab 重构、删除 Cocos 绑定、Cocos→Unity 全量迁移、Unity/MCP/服务端启动 |

## 5. 问题台账

| ID | 节点 | 首次发现 | 现象 | 复现入口 | 根因 | 处理方案 | 证据文件/日志 | 状态 | 复发预防 |
|---|---|---|---|---|---|---|---|---|---|
| P-0001 | W1.6 | 2026-09-23 | 无 asmdef，Core/UI 与 Core/Validation 形成双向依赖风险 | 静态检查 `using ProjectX.*` 与目录依赖 | 所有源码仍在默认 `Assembly-CSharp`；partial 组织不产生编译边界 | W3 已冻结依赖图和 asmdef 顺序；W4 逐层拆分并逐次编译；本轮不改 | `unityclient/` 无 `*.asmdef`；`ProjectXApp.cs`；`GameServices.cs`；`FRAMEWORK_W3_DESIGN.md` | diagnosed/deferred | 加入依赖图检查，禁止 Validation 反向引用 Runtime Core |
| P-0002 | W1.1/W1.6 | 2026-09-23 | 全局组合根和 `ProjectXApp` 过载，新增功能容易继续堆字段/回调 | 阅读 `GameServices` 构造、`ProjectXApp` partial 与 Startup 生命周期 | 一个 MonoBehaviour 同时承担启动、协议、Lua、Store、Presenter、共享 UI 和验证 | 框架稳定后按已有 partial/业务域做最小抽取；不与当前 Bug 修复混提 | `GameServices.cs:10-183`；`ProjectXApp.cs:24-240`；`ProjectXApp.Startup.cs:15-557` | diagnosed/deferred | 新模块必须登记 owner、Store、Presenter、验证边界；禁止新增全局静态服务 |
| P-0003 | W2.1-W2.7 | 2026-09-23 | 359 个 Prefab 仍普遍依赖 Cocos 绑定/路径/Timeline；共享节点可被旧 Presenter 残留控制 | 静态搜索 `CocosUiBinding`、`CocosNodeMetadata`、`CocosTimelinePlayer`、SetActive/Sibling/监听 | 迁移兼容层是当前页面可运行基础，且共享容器没有统一 owner 状态模型 | 先做只读台账和共享 Frame Coordinator 试点；真实输入回归后才处理单页 Cocos 退场 | `CocosUiBinding.cs`；`CocosNodeMetadata.cs`；`CocosTimelinePlayer.cs`；`UI_MERGE_GUIDE.md` | diagnosed/deferred | 删除前必须完成路径引用搜索、编译、Play、回归和反向引用审计 |
| P-0004 | W0.3 | 2026-09-23 | 外部 Unity/MCP 曾指向 E 盘原 checkout；经用户确认是其主动启动，现已关闭 | `Win32_Process` 与端口只读检查；用户确认 | 用户主动启动，不是项目阻塞 | 标记为非项目问题，不进入后续门禁；不再处理 | `E:\neiwang_kapai\Game\unityclient`；用户 2026-09-23 确认已关闭 | deferred | 运行阶段只记录当前 checkout 的进程归属 |
| P-0005 | W0.3 | 2026-09-23 | 初始 checkout 尚无启动/真实 Play 基线；首次直接 Play 未完成稳定切换 | 初始静态审计禁启动；W4.3 batch 编译后，直接 Play 未先打开 Bootstrap/Runner；改用 Runner 后当前 worktree 已进入 Bootstrap Play；Mail 参数启动时 `LocalServerSupervisor` 已持有 `kapai.exe` 且 `127.0.0.1:8711` 已监听 | 编译通过不能替代启动、输入和玩家可见 UI 证据；Mail真实登录/主界面/入口输入仍未完成 | 保留运行阶段进行中：Unity/MCP、Bootstrap、正常本地服务和登录画面已补证，待真实 EventSystem 走到 Mail；不把 `-projectXExternalServer` 诊断路径当作本地服务通过 | 本报告 §2.2；`unityclient/Captures/mail-w0-3-bootstrap-login-local-server.png`；`.local/unity-validation/mail-editor-mailvalidation.log` | diagnosed/deferred | 运行前先打开 Bootstrap 并使用 Runner；分别记录 Editor、Play、真实输入、本地服务和页面证据 |

## 6. 第一轮下一步边界

1. W0.3 若后续进入运行阶段，只补当前 checkout 的编译/启动基线；P-0004 不再处理，不复用其他 checkout 的运行证据。
2. W4 实施之前不得新增 `AppScope`、asmdef、Prefab 通用组件或删除 Cocos 绑定。
3. W3 边界设计已记录于 [`FRAMEWORK_W3_DESIGN.md`](FRAMEWORK_W3_DESIGN.md)；后续仍须保持 `GameServices`、现有 UI Catalog、用户 Prefab 和迁移脚本可回退。
4. 下一轮任何共享 UI 改动先阅读 `UI_MERGE_GUIDE.md`，并以真实 EventSystem/raycast、共享状态清理和用户维护 Prefab 为验收前提。
