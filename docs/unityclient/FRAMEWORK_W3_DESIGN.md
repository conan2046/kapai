# Unity 客户端内部框架治理：W3 边界设计

> 设计日期：2026-09-23
> 范围：`unityclient/` 运行时代码、Validation、Editor 的目标依赖边界。
> W3 冻结时为静态设计；W4 当前已按本文件顺序启动程序集拆分。源码移动保留原 `.meta` GUID，不修改 Prefab 或迁移状态。

## 1. 结论

1. 不新增第二个 `AppScope` 单例。现有 `GameServices` 已经承担组合根职责；W4 将“AppScope”定义为它的职责模型，而不是另建容器。
2. `ProjectXApp` 保留为 Unity 生命周期宿主和旧入口兼容 façade；不在 W3 拆除 partial，也不把它继续扩展成新的全局服务注册表。
3. 第一条必须收敛的反向依赖是 `UI -> Core`：Presenter 不应直接依赖 `GameServices` 或 `Core.ResourceService`，改为依赖窄接口和显式构造参数。
4. `Validation -> Core` 只允许通过运行时契约，不允许直接持有 `GameServices`。现有 `RuntimeSnapshotCollector` 在迁移完成前保持原路径，不能先创建会形成循环的 Validation asmdef。
5. Cocos 迁移组件继续作为独立兼容边界。`CocosUiBinding`、`CocosNodeMetadata`、`CocosTimelinePlayer` 不因框架整理而批量删除。

## 2. 当前证据与设计约束

| 事实 | 证据 | 对 W3 的约束 |
|---|---|---|
| `GameServices` 构造并持有大量 Store、Network、Protocol、UI、Lua 实例 | `Assets/ProjectX/src/Core/GameServices.cs:8-183` | 它是现有组合根；不再新增平行容器 |
| `ProjectXApp` 是 `MonoBehaviour` partial 组合宿主 | `Assets/ProjectX/src/Core/ProjectXApp.cs:21`；共 52 个 partial 文件 | 先保留兼容 façade，再逐功能抽取；不做大规模重命名 |
| Core 对 UI/Data/Network/Migration 有大量直接引用 | 静态统计：Core 137 条 ProjectX using，其中 UI 46、Data 41、Network 18、Migration 16 | Core 只能位于运行时图的上层；底层模块不得反向引用 Core |
| UI 仍直接引用 Core | 静态统计：UI 26 条 `using ProjectX.Core;`，主要涉及 `ResourceService` 与应用入口耦合 | 先抽 `IResourceService` 等窄接口，不直接把 Core 加入 UI asmdef |
| Validation 直接持有 `GameServices` | `Validation/RuntimeSnapshotCollector.cs:23,31` | 改为运行时契约；在契约切换完成前不拆 Validation asmdef |
| Lua Bridge 有 UI 依赖 | `LuaRuntime/FirstPlayableLoopBridge.cs` | Lua 核心与 UI Bridge 分开，避免 Lua ↔ UI 循环 |
| UI 迁移组件是 Prefab 运行基础 | `UI/Migration/CocosUiBinding.cs`、`CocosNodeMetadata.cs`、`CocosTimelinePlayer.cs` | 迁移层独立保留，逐页退场必须晚于真实 Play 回归 |

## 3. W3.1：AppScope 与 GameServices 合并方案

### 3.1 采用方案

| 对象 | W3/W4 职责 | 明确禁止 |
|---|---|---|
| `GameServices` | 唯一运行时组合根：创建服务、Store、Catalog、Router、Stack，统一 Tick/Dispose | 新增第二个全局容器、静态 Service Locator、按功能再建 `AppScope` |
| `ProjectXApp` | Bootstrap 场景中的生命周期宿主；把启动、Lua 回调、旧入口转交给组合根或 Feature Entry | 继续向 partial 增加跨功能 Store、协议回调和 UI 状态 |
| Feature Entry | 接收显式依赖，协调一个功能的路由、Store、Presenter 和刷新 | 从 `ProjectXApp` 或静态单例读取所有依赖 |
| `IAppScope`（可选窄契约） | 仅表达生命周期/时钟/关闭等少量跨功能能力 | 暴露全部 Store、全部 Presenter、全部 Unity View |

“AppScope”在本项目中是职责名，不是新类型名。若 W4 某个入口确实需要抽象，只新增最小接口，例如 `IAppLifecycle`、`IClock` 或 `IResourceService`，由 `GameServices`/现有实现提供；不新增总接口。

### 3.2 过渡顺序

1. 保持 `GameServices` 的公开属性和构造顺序不变，先建立边界台账。
2. 新功能禁止直接把 Store 加入 `ProjectXApp`；先登记 Feature Entry、Store、Presenter、网络端口和 Validation 入口。
3. 从低风险页面抽取一个 Feature Entry 后，才评估已有 partial 的最小搬迁。
4. 每次抽取必须通过编译、序列化检查、启动/登录/存档回归和真实 EventSystem 输入回归。

## 4. W3.2：目标层次与依赖方向

### 4.1 目标层

| 目标程序集/边界 | 主要内容 | 可依赖 | 不可依赖 |
|---|---|---|---|
| `ProjectX.Foundation` | 纯契约、生命周期接口、跨层 DTO、结果/错误模型、最小诊断接口 | BCL | Unity View、Data、Network、UI、Core、Validation |
| `ProjectX.Diagnostics` | 独立日志实现与诊断记录 | BCL、UnityEngine | ProjectX 业务程序集、UI、Core |
| `XLua`（第三方支持程序集） | XLua runtime API | UnityEngine | 不依赖 ProjectX；XLua Editor tooling 单独限 Editor 平台 |
| `ProjectX.Data` | Store、Catalog、Model、配置读取与刷新状态 | Foundation、必要的 Diagnostics | UI、Core、Presenter、Unity Scene |
| `ProjectX.Network` | TCP/协议包、Dispatcher、Registry、请求观察接口 | Foundation、Diagnostics | UI、Core、Presenter |
| `ProjectX.Animation` | Imod Animation 数据、资源与运行时播放器 | UnityEngine、Unity.ugui | Core、Gameplay |
| `ProjectX.UI.Migration` | Cocos Binding、Node Metadata、Timeline 运行时兼容组件 | UnityEngine、Unity UI | Core、Data、Presenter、Validation 业务状态 |
| `ProjectX.UI` | View、Router、Stack、Prefab Provider、Presenter、列表/页签通用能力 | Foundation、Data、UI.Migration、Animation | Core、ProjectXApp、Validation |
| `ProjectX.LuaRuntime` | Lua 生命周期、错误边界、Lua 与协议的最小桥接 | XLua、Diagnostics | UI、Core、Gameplay；场景集成桥留在 Core/Integration 上层 |
| `ProjectX.Gameplay` | 功能 Entry、业务编排、战斗/玩法协调器 | Foundation、Data、Network、UI、LuaRuntime | Editor、Validation 实现细节 |
| `ProjectX.Core` | `GameServices`、`ProjectXApp`、启动、本地服务、正式运行组合 | Foundation、Data、Network、UI、Gameplay、LuaRuntime | 不反向成为 Data/UI 的底层依赖 |
| `ProjectX.Validation` | RuntimeSnapshot、真实输入验证、场景证据适配 | Foundation、Data、Network、UI.Migration | `GameServices` 具体类型、Core partial、Editor API |
| `ProjectX.Editor` | Bootstrap 构建、导入器、验证窗口、构建保护、编辑器检查 | 所有需要的运行时程序集；UnityEditor | 被任何运行时程序集引用 |

### 4.2 依赖图

```text
ProjectX.Editor
  -> ProjectX.Core
  -> ProjectX.Validation
  -> ProjectX.Gameplay / ProjectX.UI / ProjectX.Data / ProjectX.Network

ProjectX.Core
  -> ProjectX.Gameplay -> ProjectX.UI -> ProjectX.Data
                     -> ProjectX.Network
                     -> ProjectX.LuaRuntime -> ProjectX.Network
  -> ProjectX.UI.Migration
  -> ProjectX.Foundation

ProjectX.Validation -> ProjectX.UI.Migration / ProjectX.Network / ProjectX.Data
ProjectX.UI         -> ProjectX.UI.Migration / ProjectX.Animation / ProjectX.Data / ProjectX.Diagnostics
ProjectX.Data       -> ProjectX.Foundation / ProjectX.Diagnostics
ProjectX.Network    -> ProjectX.Foundation / ProjectX.Diagnostics
ProjectX.LuaRuntime -> XLua / ProjectX.Diagnostics
ProjectX.Core       -> ProjectX.Diagnostics
ProjectX.Diagnostics (leaf; no ProjectX assembly references)
```

箭头表示“上层依赖下层”。`ProjectX.Core` 可以组装所有正式运行模块；`Diagnostics` 是无 ProjectX 依赖的日志叶程序集；`Data`、`Network`、`UI`、`LuaRuntime` 不得为了方便调用而引用 `Core`。

### 4.3 当前代码到目标层的过渡映射

| 当前代码 | 目标归属 | 过渡要求 |
|---|---|---|
| `Core/ResourceService.cs`、`ServerTimeService.cs` | Core 的实现；契约移入 Foundation | UI 只拿 `IResourceService`/`IServerTime`，不引用实现类型 |
| `Core/ProjectXApp.*.cs` | 先留在 Core；逐功能迁移到 Gameplay Entry | partial 搬迁前不得创建依赖 Core 的 Gameplay asmdef |
| `UI/*Presenter.cs` | UI | 将 `using ProjectX.Core` 收敛为窄契约/回调；Presenter 不持有总组合根 |
| `Validation/RuntimeSnapshotCollector.cs` | Validation | 将 `GameServices`、`services.Network`、`services.State/Player` 替换为快照/网络观察契约 |
| `LuaRuntime/FirstPlayableLoopBridge.cs` | Gameplay/Integration 适配层 | LuaRuntime 核心不再引用 UI；桥接代码可暂留 Core 直到拆分 |
| `UI/Migration/*` | UI.Migration | 保持序列化类型、GUID、Prefab 引用和 Cocos 路径语义不变 |

## 5. W3.3：Service 接口与依赖规则

### 5.1 首批窄接口

| 接口 | 提供者 | 消费者 | 约束 |
|---|---|---|---|
| `IResourceService` | 当前 `Core.ResourceService` | UI Presenter、Gameplay | 只提供资源/文本/图集查询；不暴露 `GameServices` |
| `IUiResourceProvider` | 当前 `Core.ResourceService` | Mail 试点 Presenter、`ItemQualityVisual` | Mail 首个窄接口；只提供图标和品质框资源，后续再评估归并到统一资源契约 |
| `IServerTime` | 当前 `Core.ServerTimeService` | Data、Gameplay、UI | 只提供当前服务器时间和刷新语义 |
| `IProtocolRequester` | 当前 Network/Protocol 组合 | Gameplay Entry、Validation Adapter | 请求、超时、观察结果分开；Presenter 不拼原始协议 |
| `IProtocolObserver` | `ProtocolRegistry`/Dispatcher 适配 | Store、Validation | 只订阅已解析事件；Dispose 必须可解除订阅 |
| `IRuntimeSnapshotSource` | Core 运行时适配器 | Validation | 暴露只读状态快照；禁止暴露 `GameServices` |
| `IUiAssetProvider` | 现有 `ResourcesUiAssetProvider` | UI Router/Feature Entry | 保留现有接口，继续承担实例生命周期和释放归属 |

不建立 `IGameServices` 这种包含几十个 Store 的总接口。功能需要什么就注入什么；暂时无法抽取的旧入口保留在 Core，并登记为过渡依赖。

### 5.2 生命周期合同

Feature 和 Presenter 的统一顺序：

```text
Construct -> Bind -> Enter -> Refresh -> Exit -> Dispose
```

- `Bind`：绑定 View、监听和必要的静态控件。
- `Enter`：声明共享 Frame owner，清理动态节点、可见性、监听、Sibling/Raycast 和 Close 状态。
- `Refresh`：从权威 Store/服务读取数据；不能用旧 Presenter 缓存覆盖新状态。
- `Exit`：取消请求、解除监听、释放 transient UI；不销毁不属于自己的 Singleton。
- `Dispose`：只执行一次，允许重复调用。

共享页框继续遵循 `docs/unityclient/UI_MERGE_GUIDE.md`，由一个 Coordinator 管理 owner/tab/content/close 状态。

## 6. W3.4：Feature 模块模板

新功能按以下最小结构登记，不要求立即移动现有文件：

```text
Feature/<Name>/
  <Name>Entry.cs          # 路由、前置条件、生命周期
  <Name>Store.cs          # 状态与数据刷新；归属 Data 或 Feature.Data
  <Name>Presenter.cs      # View 绑定、用户输入、状态投影
  <Name>View.cs            # Cocos/Unity 视图适配；不持有总组合根
  <Name>Catalog.cs         # 静态配置/资源索引
  <Name>Config.cs          # 正式配置读取；不得写死解锁条件
  <Name>Validation.cs      # 只登记场景/断言/证据，不进入正式业务逻辑
```

每个功能登记以下字段：

| 字段 | 必填内容 |
|---|---|
| Entry | 入口路径、Function ID、前置条件、关闭/返回路径 |
| Store | 状态所有者、请求刷新、清理方法、持久化边界 |
| Presenter | View、监听、动态节点、Close/Tab owner |
| View | Prefab/Catalog/source、Cocos 兼容依赖、Raycast 层级 |
| Network | 协议号、请求/回包、超时、取消和重入规则 |
| Config | 正式配置来源、导出文件、缺失/重复校验 |
| Validation | Given/When/Then、真实输入点、可见结果、恢复合同 |

## 7. W3.5：asmdef 设计与实施顺序

W3 只冻结设计，不创建 asmdef。W4 采用一次一个边界、一次编译的顺序：

1. `ProjectX.Foundation`
2. `ProjectX.Diagnostics`（日志叶程序集，因 Data/Network 的真实日志依赖前置）
3. `ProjectX.Data`
4. `ProjectX.Network`
5. `ProjectX.UI.Migration`
6. `ProjectX.Animation`（现有 UI Presenter 已直接使用，属于其运行时下层）
7. `ProjectX.UI`
8. `XLua` runtime + Editor support assemblies（LuaRuntime 的第三方前置）
9. `ProjectX.LuaRuntime`
10. `ProjectX.Gameplay`
11. `ProjectX.Core`
12. `ProjectX.Validation`
13. `ProjectX.Editor`

每一步必须同时检查：

- Unity 编译无新增错误；
- 序列化 GUID、Prefab 引用、Catalog 和 Bootstrap 场景不变；
- 依赖方向没有新增反向引用；
- `ProjectX.Validation` 不引用 `ProjectX.Core`；
- 正式运行程序集不引用 `ProjectX.Editor`；
- 真实启动、登录、存档、页面打开/关闭和 EventSystem 输入按影响范围回归。

特殊前置：现有 `ProjectXApp.*Validation.cs` 和 `RuntimeSnapshotCollector` 仍直接依赖 Core 时，不得提前创建 Validation asmdef；先完成契约适配，再拆程序集。

## 8. W3.6：正式运行与 Validation/Editor 隔离

### 正式运行层

- 不包含截图导出、自动点击、RuntimeSnapshot、Debug Probe 或编辑器菜单代码。
- 只依赖正式 Store、Network、UI、Gameplay 和配置链。
- 可以被 Editor/Validation 驱动，但不能引用它们的实现。

### Validation 层

- 可使用真实 `EventSystem`、Raycast、运行时 UI 语义和已登记的网络观察契约。
- 只通过 `IRuntimeSnapshotSource`、`IProtocolObserver` 等契约取证。
- 不调用 Presenter 内部完成方法、旧 Runner 或批处理摘要代替真实输入。

### Editor 层

- 仅包含 `UnityEditor`、导入器、场景构建器、构建保护和验证窗口。
- 通过正式运行公开入口或 Validation 契约工作。
- 不把 Editor 辅助脚本放入正式运行程序集的公共 API。

## 9. W3 验收结论与 W4 闸门

W3 设计结论：

- 组合根：保留 `GameServices`，不新增 `AppScope` 容器。
- 依赖方向：底层 `Data/Network/UI/LuaRuntime` 不再反向引用 `Core`。
- UI 解耦：先抽窄接口，再拆 UI asmdef。
- Validation 解耦：先去掉对 `GameServices` 的具体依赖，再拆 Validation asmdef。
- 迁移兼容：Cocos 绑定、Timeline、Catalog 和用户 Prefab 继续受保护。

W4 开始前必须满足：

1. 用户确认进入源码/asmdef 骨架实施阶段；
2. 选择一个低风险 Feature 作为首个依赖收敛试点；
3. 明确该试点的真实入口、账号/数据夹具和恢复合同；
4. 先提交或保存 W4 前的文档基线，再逐个创建 asmdef；
5. 每次 asmdef 变更都执行定向编译和反向引用检查，未通过不得继续下一层。
