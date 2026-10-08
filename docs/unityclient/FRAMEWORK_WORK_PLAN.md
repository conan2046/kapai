# Unity 客户端内部框架治理工作计划

> **当前目标（2026-09-29）**：继续完成 W8.1–W8.6。W8 工作目录为 `E:\neiwang_kapai\Game`，Unity 工程为 `unityclient`；W7、W9.1–W9.6 已完成。W8.1 Login/Startup 仍部分未收口；W8.2 World/Battle 的既有 Unity-owned Prefab 与入口路线已通过，但新增 P-0118 跨章节通关提示已有 Unity 原生资产/接线、MCP 静态检查通过，真实解锁路线待 MCP 验证；W8.3–W8.5 均未闭合，其中 Bag 已有部分资产迁移；W8.6 FengShenStory main/level 路线已完成部分迁移，共享战斗与其他入口待处理。资源维护链、Notice/Loading 兼容层及动画生成源进度以 [W8 Cocos 依赖退场处理单](W8_COCOS_DEPENDENCY_RETIREMENT.md) 为准。只处理当前 W 的职责，不重开已收口的 W6。
>
> **W6 基线（已完成，Unity/Steam 范围）**：359 个 Prefab 序列化 `CocosNodeMetadata`=0、`CocosUiBinding`=0；22 个有效 `CocosTimelinePlayer` / 461 条轨道保留；范围内 Presenter 固定导入节点待迁移=0。Cocos 文档对比、旧导入器差异、坐骑、屏蔽功能及当前 Unity 无正式入口页面不纳入。W6 当前证据见对应 `.local/unity-validation/` 文件。
>
> **W7 完成证据与边界**：`.local/unity-validation/w7-1-validation-boundary-inventory-20260927.md`。W7.1-W7.5 均完成；最终 Development Player 匹配验证命名的类型/方法为 41/219，Release 为 0/0；Release 中验证/验收/Debug/Automation 启动参数字面量=0、Release 可达 `*Validation` 选项/参数引用=0。Development/Release BuildReport 均成功；各有 1 条既有 XLua `Generator.CheckGenerate` 构建后回调错误（XLua Gen 输出不兼容），未改 XLua 包或 W9 构建治理。W8 边界：只按正式业务域拆分 Core，行为、数据、协议不变；验证代码归 W7，资源/包/构建配置归 W9。

范围：仅针对 `unityclient/`。
原则：保留已验收功能，先静态梳理，再做最小改动；不引入大而全第三方 Unity 框架。
## 一、状态定义

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

**状态：完成（2026-09-27，Unity/Steam 当前范围）。** 当前进度只看本节和 `UNITYCLIENT_STATUS.md`；历史验收证据按需查阅 `.local/unity-validation/`。

- **W6.3 Metadata：通过。** 359 个 Prefab 的序列化 `CocosNodeMetadata` 为 0；Snapshot identity 例外已回读闭合。最新开页联合检查见 `.local/unity-validation/w6-unified-open-prefab-20260926.md`。
- **W6.4 Timeline：通过。** 4 个零轨道/零片段/零时长组件已清理；保留的 22 个有效组件和 461 条轨道继续由 `UiPrefabIdentity` 驱动，不能删除。有效动画页已随真实入口检查。
- **W6.5 Binding/Presenter：通过。** 359 个 Prefab 的旧 `CocosUiBinding` 组件与序列化引用为 0；生产运行时消费者已迁到 `UiPrefabIdentity`。Steam 范围需迁移的 Presenter 固定导入节点调用为 **0 个 Presenter、0 处调用**；Login 手工 Steam 控件、OldMemory 生成节点和动态子节点保留其本地查找。迁移范围与分类见 `.local/unity-validation/w6-steam-presenter-scope-20260926.md`。
- **W6.6 页面联合验收：通过。** 同页一次性检查 Metadata/Binding/Timeline 的路线见 `.local/unity-validation/w6-unified-open-prefab-20260926.md`；背包礼盒→来源→装备信息见 `.local/unity-validation/w6-steam-presenter-scope-20260926.md`；寻宝合成结果见 `.local/unity-validation/w6-xunbao-compose-all-fixed-20260927.md`。2026-09-27 新增真实 Login→Main→HeroHub→HeroBag→HeroBook→返回闭环，44 个身份条目、Metadata/Binding=0、Timeline=N/A、Console=0，见 `.local/unity-validation/w6-final-page-acceptance-20260927.md`。
- **W6.7 范围裁定：** `FightLayer` 已实际开页；`guanqiaxiangxiLayer` 在当前 Unity 默认龙崖路线不可见，用户已明确不启用 `fuben_AB=1`，故不切换模式、不列本轮阻塞。坐骑、Arena/屏蔽功能及只有导入清单、没有当前 Unity 正式入口的 Prefab 不验收、不补造入口。
- **验收边界：** 忽略 Cocos 文档对比和旧严格导入器差异；不执行抽取、激活、升级、领奖或战斗来伪造条件。HeroBook 激活/升级/等级结果弹窗的 Unity 身份映射已静态核对，但本轮未触发其业务前置条件；此项不作为 Cocos 迁移层未退场的理由，也不宣称其业务结果页完成可见验证。
- **恢复检查：** Unity Play 与本地测试服务已停止，Editor 留在 C 盘项目 Edit mode；8711 空闲。`LocalServer/projectx.db` 已恢复至 SHA-256 `1449E792F9444BE03126218D447DA8B9623F45E9DB7A2E8AC374F8D4B49C5118`，SQLite integrity=ok、无活动 WAL/SHM。测试期间的侧车已归档至 C 盘 `.local/unity-validation/`。
### W7：Validation 与正式运行逻辑隔离

- **边界（已锁定）：** 仅隔离 G3-G6 验证入口、RuntimeSnapshot、Debug/Editor Probe、截图和自动输入，并建立 Development/Release 构建边界。不得改业务行为、Prefab、W6 页面或验证夹具。G3-G6 外部 PowerShell 工具保留。详细源文件清单见 `.local/unity-validation/w7-1-validation-boundary-inventory-20260927.md`。
- [x] W7.1 盘点 G3-G6、截图、RuntimeSnapshot、Debug Probe、自动输入代码
- [x] W7.2 隔离运行时验证入口（RuntimeSnapshot/RuntimeInputDispatcher、13 个 Editor facade、所有运行时验证入口及其 runner/截图辅助方法均保留在 Editor/Development；Development Player 中验证命名方法仍可编译）
- [x] W7.3 保证 Runtime 不反向依赖 Validation（Core→Validation asmdef/source refs=0；Validation→Core=0；完整检查见 W7 盘点证据）
- [x] W7.4 建立 Editor/Development 与 Release 编译边界（Editor 编译通过；Development 与 Release Player 构建通过；Release 不含验证/快照接口、Debug overlay、验收参数分支；正式业务输入/协议路径保留）
- [x] W7.5 验证正式 Build 不包含不必要的验收入口（Release `ProjectX.Core.dll` 匹配验证/快照/输入/DebugProbe 的类型=0、方法=0；Release 测试启动参数字面量=0；Development 对应为 41/219）

验收条件：已有验证工具仍可运行；正式运行逻辑不被验证流程污染。

### W8：按功能拆分核心模块

- **2026-10-08 全部Prefab原生化收口：** P-0198–P-0208后398个ProjectX Prefab的Identity/旧Timeline/Imod/缺失脚本/旧资源递归依赖均0，137个Unity Catalog条目实例化/释放/清场通过。旧UI兼容层、Imod运行库/源及旧验证器退役；维护模式unity-native-only，活动UI/Timeline导入行0/0。27项资源测试、478项工具链检查、110次动画采样通过。只关闭资源维护缺口，原W8功能门禁和manualPassed不重算；业务Play与最终画面待用户验收。详见W8处理单P-0198–P-0208，下方旧余量为历史。

- **2026-10-08 当前原生化续记：** P-0189–P-0197闭合游历/大厅共享frame/摇钱树/转盘及神将重生、图鉴、培养与共享数量输入的27个Prefab维护源、资源、Provider/View、Catalog/Reference和准备/写回保护；保留节点布局，旧源归档。MCP397 Prefab/295 Identity/8旧Timeline Prefab、122轨道，活动清单264/0；编译/Console0/0、24单测与476工具链项通过。新增业务Play与最终画面仍待用户确认；全局兼容层及剩余开放入口继续处理。MCP临时DLL锁冲突修复作为项目内嵌包保存，保持开启。证据见W8处理单P-0189–P-0197。

- **2026-10-08 Monopoly 续记：** P-0187 页面与动态资源链已迁移；51 对哈希一致。用户已授权代理自行通过 MCP 完成后续操作。P-0188 将终点共享奖励弹窗及封神列传消费者切换为 Unity Prefab/Provider/Transform，50节点布局一致、14资源副本哈希一致、旧依赖为0；准备器排除已迁页面旧导入源，并补齐奖励/Monopoly 写回保护。Console 0/0，单测24/24、工具链476/476；最新盘点397 Prefab/322 Identity/8 Timeline Prefab、122轨道/活动清单291/0。实际奖励路线未重验，画面由用户最终验收。详见W8处理单P-0188。
- **边界（开工前锁定）：** 只按业务域拆分正式运行逻辑：Login/Startup、World/Battle、Hero/Equipment、Bag、Shop、活动玩法；保持对外行为、数据和协议不变。验证工具归 W7，资源与发布归 W9；不跨模块顺手改功能。
- **Prefab/Cocos 依赖退场：** 2026-09-30 Unity MCP AssetDatabase 最新复核为 402 个 Prefab，其中330个带 `UiPrefabIdentity`；8 个 Timeline Prefab/122 条历史轨道、0 个 `CocosUiBinding` Prefab。活动 UI/Timeline manifest 为 300/0 行。Notice/Loading 的历史 Cocos Prefab/JSON 已转存到 Unity `Assets` 外，Main 云层 Timeline 转换 JSON 已归档，Unity `CloudLoop.anim` 是维护源（P-0149/P-0150/P-0151）。World 大地图敌人预览、结算/通关提示、XunBao/World 扫荡结果、XunBao 确认弹窗、Draw 结果、Main 云层、World 成就、EnhanceMaster、Bag 与 Fish 旧源已按入口迁移旧源组件/Timeline/动画；Fish ShapeId=2000 Action 2 已改成 Unity Clip/Animator，World 62 种大地图敌人预览复用 Formation 原生 controllers（P-0143/P-0145/P-0146/P-0147/P-0148/P-0153/P-0154/P-0155/P-0156/P-0172/P-0173）；共享奖励/来源弹窗及其他活动 Cocos Provider 消费者仍待按入口迁移。逐按钮进度和问题证据见 [W8 Cocos 依赖退场处理单](W8_COCOS_DEPENDENCY_RETIREMENT.md)。
- **Monopoly 增量（2026-10-01，P-0187）：** `GameSceneLayer`、用户维护的 `GameLayer` 和 `caiquanLayer` 已复制为 Unity-owned Prefab，39 个旧 `res/` 依赖改为原生资源引用；旧 Prefab、JSON 和 `.meta` 已归档到 Unity `Assets` 外；Catalog/Reference、Bootstrap 预检、Presenter 和加载 Provider 均已切 Unity。Unity MCP 比较三份源/副本节点树与布局差异为 0，Console 0/0；完整工具链 475 项通过。当前工程清点为 397 Prefab、323 个 Identity Prefab、8 个 Timeline Prefab/122 轨道，活动 UI/Timeline manifest 292/0。Function 21 未进 Play，最终画面由用户验收；全局 Cocos Provider/Importer 仍由其他活动入口使用。详见 W8 处理单 P-0187。
- **运行时功能节点统计（Login/Startup 当前 Steam 路径已收口）：** 用 Unity MCP 从 Bootstrap 实际入口采集启动页、旧存档列表、角色创建页和 Slot01 成功进入 Main 的边界；点击均经 EventSystem 射线首命中校验。启动快照加载 7 个身份根/273 节点，激活 23；旧存档快照加载 8 根/699 节点，激活 144，19 个可交互按钮；`OldMemoryPresenter` 缓存 119 条唯一成功节点路径（不是调用次数），其中 112 条属于槽位节点、7 条属于共享节点。角色创建页运行时 33 节点、32 激活；3 条直接路径加 5 个 ActionTag 目标；Main 边界 223 节点，仅作为 Login 终点。每个 Prefab 的树统计、路径/ActionTag 消费者、路线作用及未覆盖分支见 `.local/unity-validation/w8-runtime-feature-login-node-usage-20260928.md`；原始明细索引见 `.local/unity-validation/w8-runtime-feature-login-summary-20260928.md`。`Btn_New` 直接启动首个空 Slot 并进入角色创建，不会停在档位选择页。采集快照中临时新建的空 Slot05 已在当时通过游戏 UI 删除，Slot01 数据按采集前哈希恢复；用户随后确认已手动清理 Slot03/04。当前 Steam 单机入口清单已收口；选服、非 Steam 登录、断线/公告和错误提示等条件分支明确列为未覆盖范围，不能据此判定为未使用。其他功能尚未统计。
- **当前进度：** W8.1 `[~]`：登录运行逻辑归入 `ProjectXApp.Login.cs`，W7 验证入口与 21 控件闭包 Runner 单独归入 `ProjectXApp.LoginValidation.cs`；登录服务拿到的 `IUiAssetProvider` 已缩为 Unity 原生 API，旧 Cocos source-token 查找另由 `ICocosUiAssetProvider` 暴露；Editor 编译及接口反射冒烟通过。本轮之前真实 Play 通过旧存档进入 Main、Main→系统→离开、空名校验、性别切换、角色创建进入 Main、建角退出/再次进入、LocalServer 异常退出后的断线提示及重新进入。两处实测缺陷已修复：建角返回后旧自动重连使用过期连接；LocalServer 退出后标题页仍残留自动重连。新增 Bootstrap Runner 外部停止清理，受控反射检查通过；P-0039 已通过受控 Bootstrap Play 事件日志与运行态确认解决，`ProjectXApp` 为 Login / `Single-player title ready.`，不能再将旧的 15 秒转场记录描述为当前阻塞。最新 Unity-owned Login Presenter/View、资源、Prefab 和动画改动后，Bootstrap→OldMemory→返回的 EventSystem/Raycast 路线也已通过；2026-09-29 在 `/88` 请求所有权移到 C# 后，使用隔离 SQLite 和 Unity MCP EventSystem/Raycast 重新通过 Login→Main→`/1001`→`/1004`→C# `/88` Notice 显示与关闭。实际显示文本与 SQLite 公告夹具一致，关闭后仍在 Main；Console 0/0，fixture Restore/AssertRestored/Cleanup/AssertCleanup 通过，8711 释放。证据见 `.local/unity-validation/w8-notice-csharp-live-mcp-route-20260929.md`。`Btn_New` 在隔离存档根中进入 RoleCreate，男/女 Unity Animator 状态切换并返回标题页，证据见 `.local/unity-validation/w8-login-rolecreate-mcp-route-20260928.md`。资源维护侧又扩展 Cocos importer 写入保护，Unity-owned Prefab 与 Login/Main/Startup/动画资源图片路径均在修改 TextureImporter 前被拦截；MCP 路径及写入拒绝测试通过，工具链随后停在既有 P-0051 HeroEquip 契约断言。证据见 W8 依赖退场单 P-0079。Login/Startup 画面正确性由用户最终验收，不要求 Cocos 对照截图作为门禁；干净导入及无 XLua 后置错误的 Player 构建仍未完成，因此 W8.1 保持 `[~]`。用户确认 Slot03/04 已手动清理，本轮不再处理存档清理；键盘录入按用户指示不纳入本轮工作。功能证据与限制见 `.local/unity-validation/w8-login-real-input-20260928.md`、`.local/unity-validation/w8-login-playmode-transition-20260928.md`、`.local/unity-validation/w8-login-native-prefab-path-20260928.md`、`.local/unity-validation/w8-runtime-feature-login-node-usage-20260928.md`。W8.2 已迁入口和 chapter unlock Unity replacement 有 MCP 路线证据，`tongguanLayer` 两条导入行已退役，画面由用户验收；W8.3–W8.6 继续按下方模块表处理。

W8 Cocos 依赖按实际按钮入口逐项处理；已经验收且未受本轮改动影响的入口引用原证据并跳过，避免重复验收。详细清单与问题台账见 [W8 Cocos 依赖退场处理单](W8_COCOS_DEPENDENCY_RETIREMENT.md)。

- [~] W8.1 Login/Startup
  - 画面正确性由用户最终验收，不再要求 Cocos 对照截图。2026-09-29 Unity MCP StandaloneWindows64 Mono BuildReport 为 `Succeeded`，Bootstrap Player 输出保留于 `.local/unity-validation/w8-login-native-player-20260929/`；BuildReport 统计 1 error/15 warnings，唯一 Console 异常是既有 XLua `Generator.CheckGenerate` 后置检查，故无后置错误门禁仍未通过。详见 `.local/unity-validation/w8-login-native-player-build-20260929.md`。
- [~] W8.2 World/Battle：已迁入口的 Unity-owned Prefab、动画维护源和 MCP 路线通过；画面由用户最终验收。P-0118 的跨章节通关提示已通过权威挑战→解锁→提示→返回 MCP 路线；其原生 Prefab/Clip/Controller 已接管，`tongguanLayer` UI/Timeline 导入行在 P-0125 退役，历史 Cocos Prefab 于 P-0153 移除 Identity 与 6 条 Timeline 轨道并保留节点树/`.meta`。P-0119 的 `Guide_FuBen4` 引导路线仍未闭合。World 与 XunBao 已迁入口的 Editor 菜单现只校验 Unity 原生资产，不再读取 Cocos Prefab（P-0100、P-0101）。全局 Cocos importer/兼容 Adapter 属于其余入口的后续退场。World 专项证据见 `docs/unityclient/W8_COCOS_DEPENDENCY_RETIREMENT.md` 的 World/Battle 入口表；FengShenStory/Monopoly 是共享战斗资源的其他模块，不计入 World。
- [ ] W8.3 Hero/Equipment：`btn_buzhen → shenjiangzhenxingLayer` 的 Unity-owned Prefab、资源引用、Catalog、Transform 节点查找及 72 组阵位 `.zd` 动画已切换；Unity MCP 资产校验/运行探针通过。其他 Hero/Equipment 入口未处理；画面交由用户最终验收。
- [ ] W8.4 Bag
- [ ] W8.5 Shop
- [ ] W8.6 活动玩法：FengShenStory main/level Prefab 与主→关卡入口已按 Unity-owned 路线验证；共享 Battle/弹窗及其他活动入口未完成。

每个模块必须完成：入口、数据、UI、网络/战斗依赖、验证、真实 Play 回归。

### W9：资源与发布治理

- **边界（开工前锁定）：** 只处理资源加载入口、配置/UI/动画/战斗资源分组、Addressables 适用性评估、无引用包/平台模块清理、MCP package 固定及 Release 构建/版本/前置检查。不重构业务模块；任何包/平台删除必须有无引用证据与构建验证。
- **当前进度：** W9.1 `[x]`（2026-09-27）；27 个正式运行时源码文件的 75 处 `Resources.Load`/`Resources.UnloadAsset` 调用统一经过 `ProjectX.Foundation.ResourceLoader`，Unity 实现为 `ProjectX.Core.UnityResourceLoader`；Animation、LuaRuntime、UI asmdef 增加 Foundation 引用。Unity Editor 编译无 C# 错误；正式运行时直调只剩统一实现，Editor、Validation、Diagnostics 保持原状。W9.2 `[x]`（2026-09-27）；Resources 资产按既有目录建立分组映射：配置45项、UI 1183项、动画1774项、战斗110项，另有 Lua runtime 脚本46项；无资产移动或改名。W9.3 `[x]`（2026-09-27）；`Packages/manifest.json` 与 lock 均无 Addressables 包，运行时代码未使用 Addressables/AssetBundle 加载或远程 Catalog；3158 项本地 Resources 源资产约181 MB（动画约130 MB）。当前 Steam 随包本地加载无需引入 Addressables；无远程内容/DLC或按需下载要求时维持现状，出现这些需求再评估。未安装或迁移资源。W9.4 `[x]`（2026-09-27）；四项已从 `manifest.json` 与 `packages-lock.json` 移除，Unity Package Manager 重解后两文件均无残留；最终 Steam Windows x64 Release BuildReport 和包树校验成功。W9.5 `[x]`（2026-09-27）；MCP 包由 `#main` 固定为已解析的 commit `30d22075093d1d35dfb0091c1c7550e9ad948577`，manifest/lock 指向同一 commit，未升级包。W9.6 `[x]`（2026-09-27）；`SteamWindowsBuild` 完成 Editor/版本/Windows x64/场景/服务端前置检查并在清单写入产品/Unity 版本；C 盘隔离目录服务端构建成功；Builder 的 Steam 路径已改为只校验 Unity Resources，不读 `client/ProjectX`。Release 输出为 `.local/steam-build/ProjectX`，596 个包文件共 510,492,882 bytes；596/596 文件大小与 SHA256、目录白名单、服务端载荷一致性均通过。构建日志输出 `[SteamWindowsBuild:LZ4HC] Passed`。Console 留有 W7 已记录的既有 XLua `Generator.CheckGenerate` 构建后回调异常；BuildReport 仍为 Succeeded，不阻塞包。Bootstrap 场景语义签名未变、无 Prefab 写入；Editor 保存了两个动态 UI Catalog、场景 YAML 与 `UniversalRP.asset`。

**W9.6 可见进度（2026-09-27）**：

| 环节 | 状态 | 当前证据 / 下一步 |
|---|---|---|
| Steam 构建入口、版本与场景前置检查 | `[x]` | 已写入 `SteamWindowsBuild.cs`；待本轮 Unity 编译验证 |
| 服务端输入与过期检查 | `[x]` | Steam 包从独立 `.local/steam-server-build/server-win` 取服务端；缺失或过期时显式使用 worktree 内 vcpkg 重建 |
| 服务端 CMake 配置与路径隔离 | `[x]` | 新缓存的源码根、vcpkg、MySQL、Lua、SQLite 均为 C 盘路径；扫描无 E 盘工程路径 |
| 服务端 Debug 构建与产物新鲜度 | `[x]` | `.local/steam-server-build/server-win/Debug/kapai.exe` 已生成（17.7 MB）；构建成功，依赖部署在同目录 |
| Unity 资源输入边界 | `[x]` | Builder 不再读取外部 `client/ProjectX`；验证 85 张固定图、59 张技能图及 31 个 Unity/数据导出源输入均存在 |
| Unity Editor 编译（含本次 Builder 修复） | `[x]` | 当前 Editor 重编译后 `ProjectX.Editor.dll` 晚于源码更新；编译无 C# 错误 |
| 最终 Windows x64 Release 构建与包清单 | `[x]` | BuildReport Succeeded；`[SteamWindowsBuild:LZ4HC] Passed`；596/596 包文件哈希一致、无额外/禁带文件；包内服务端哈希匹配 C 盘 Debug 构建 |
| 构建副作用检查 | `[x]` | `Bootstrap.unity` 语义签名未变；无 Prefab 改动。Builder/Editor 写入 `UiPrefabs/Catalog.asset`、`WorldMapNewLayer.asset`、Bootstrap YAML 和 `Assets/Settings/UniversalRP.asset` |

- [x] W9.1 统一资源加载接口，业务层不再直接散落 `Resources.Load`（2026-09-27；涉及 `Foundation/IResourceLoader.cs`、`Core/UnityResourceLoader.cs`、`Core/GameServices.cs`、`Core/ResourceService.cs`、Animation/Data/LuaRuntime/UI 27 个调用方及 3 个 asmdef；Unity Editor 编译通过，正式运行时直接调用扫描为 0）
- [x] W9.2 对配置、UI、动画、战斗资源进行分组（2026-09-27；盘点 `Resources/ProjectXData/{Configs,Tasks,World}`、`Lua/Data`、UI根目录、`ProjectXAnimation`、`ProjectXBattle`、`ProjectXAudio/battle` 与 `ProjectXData/Battle`；共3158项非 `.meta` 资源，分组为配置45、UI 1183、动画1774、战斗110；资源路径不变；空目录 `Config`/`Configs`/`ProjectXConfig` 保留）
- [x] W9.3 评估是否需要 Addressables，不进行全量预迁移（2026-09-27；检查 `Packages/manifest.json`、`packages-lock.json` 和运行时代码；当前 3158 项 Resources 本地资源约181 MB，无远程目录/AssetBundle API；Steam 随包加载继续使用 Resources，不增加 Addressables 依赖；未来有远程内容、DLC 或按需下载需求时再启用）
- [x] W9.4 清理确认无引用的 Unity 包和平台模块（2026-09-27；`Packages/manifest.json` 与 `packages-lock.json` 均已移除 `com.unity.visualscripting`、`com.unity.modules.vehicles`、`com.unity.modules.wind`、`com.unity.modules.unitywebrequesttexture`；源码、asmdef、Prefab/场景/资源和 ProjectSettings 搜索均无引用，包锁反向依赖为 0；Editor 编译与最终 Steam Release BuildReport 通过）
- [x] W9.5 固定 MCP package 版本（2026-09-27；`Packages/manifest.json` 固定 `com.coplaydev.unity-mcp` 至 `30d22075093d1d35dfb0091c1c7550e9ad948577`，与原 `packages-lock.json` hash 一致）
- [x] W9.6 建立 Release 构建、版本号和构建前检查（2026-09-27；`SteamWindowsBuild` preflight 通过；ProjectVersion=`2022.3.62f3c1`、bundleVersion=`1.0`、目标 Windows x64、压缩 LZ4HC；Release 包 596 个文件/510,492,882 bytes，文件尺寸与 SHA256 全通过，含 C 盘构建的服务端，未包含 PDB、MySQL 服务端或开发工具）

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
| P-0023 | W6.3 XunBao page currency header | 2026-09-25 | XunBao 开页后顶部体力/金币/元宝均显示模板字面量 `12345678`，与当前 Store 不符 | C 盘同一 Play；Main→Gameplay `Function_9/EnterBtn`，开页同时联合回读 Binding/Metadata/Timeline/Snapshot 和画面 | Prefab 的 `Panel/GoldCheck/GoldIcon{1,3,4}/GoldNumBg/Num` 为硬编码默认值；XunBao Presenter 建立时未调用公共货币头刷新 | `EnsureXunBaoPresenter()` 在 Presenter 初始化后调用 `RefreshStandardCurrencyHeader(xunBaoView.Binding, "Panel/GoldCheck")`；一次受控编译/Play 恢复后复入现有角色，页面显示 `100/100`、`1825992`、`1016188`，与 Currencies Store 一致；EventSystem 关键首击通过、Screenshot目视无重叠/裁切，Console 0/0 | `Core/ProjectXApp.XunBao.cs`；`.local/unity-validation/w6-xunbao-layer-binding-metadata-timeline-joint-20260925.md`；`.local/unity-validation/w6-xunbao-live-20260925.png` | verified | 页面复用 `GoldCheck` 模板时，开页必须从当前权威 Currencies Store 刷新，不得保留导入 Prefab 演示数字 |
W8 Cocos 依赖退场的详细问题记录（含 P-0024 起）统一维护在 [W8 Cocos 依赖退场处理单](W8_COCOS_DEPENDENCY_RETIREMENT.md)，避免在本计划重复维护。

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

```text
W8.1 → W8.2 → W8.3 → W8.4 → W8.5 → W8.6
```
