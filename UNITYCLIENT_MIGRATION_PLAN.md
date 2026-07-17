# UnityClient 模块化迁移计划

> 基线日期：2026-07-16  
> 工程：`D:\neiwang_kapai\unityclient`  
> 原客户端：`D:\neiwang_kapai\client\ProjectX`  
> 原服务端：`D:\neiwang_kapai\server`

## 0. 最新状态

2026-07-16 23:45 已完成第一批底层、任务、玩家 HUD、背包/奖励模型、阵容神将、HeroEquip/FaBao Store 及资源/时间/通用提示闭环：

- `AppLaunchOptions + AppStateMachine` 已接入正式 App。
- `ClientLog + LuaErrorBoundary` 已覆盖正式 Lua 调用入口。
- `ProtocolRegistry + RequestContext` 已记录发送、响应、耗时与超时。
- `MessageBoxLayer` 已接成通用错误弹窗并通过显隐自检。
- `ConfigService + TaskStore` 已加载 8 条本地服同源日常任务配置。
- 固定高度 `VirtualList<T>` 已用于任务列表。
- 真实闭环通过：`btn_renwu → /37 op=1 → 8 条任务 → /37 op=2 增量 → 红点/主界面追踪 → /37 op=3 领奖 → 奖励解析 → state=2 持久化`。
- `/39` 已按真实语义接为旧主/支线任务增删；`/37 op=5` 与日常任务 Store 隔离。
- 主界面任务追踪复用 `UImainLayer_backup` 已迁移面板，任务按钮红点由 `TaskStore` 驱动，并兼容 `/65 type=101`。
- 非空背包与设置联合回归通过；严重日志异常为 0。
- `PlayerStore/CurrencyStore` 已覆盖 `/1004、/18、/226、/321`，主 HUD 的姓名、等级、战力、金币、元宝、体力已由 Store 驱动。
- `BagStore` 已取代 Lua 临时字典；`RewardStore/RewardPresenter` 已取代任务领奖临时状态文字。
- `HeroStore/FormationStore` 已覆盖 `/24 op=1、/48 op=1/op=4`，神将列表、详情、阵位变更与恢复真实通过。
- `ResourceService` 已统一 Bag/Reward 的 ItemIcons/MonsterBust 回退、缓存、占位和缺图统计，并提供神将头像入口。
- `ServerTimeService` 已接真实 `/206`，服务器 `todaySeconds + unixSeconds` 四轮回归通过。
- keyed `LoadingPresenter` 已复用 `common/jiemianjiazai.prefab` 并接入连接/重连；队列式 `ToastPresenter` 已向 C#/xLua 提供统一入口。
- `HeroEquipmentStore/FaBaoStore` 已覆盖 `/319 op=1/op=17` 分包列表与 `op=16/op=22` 增量，复用真实装备背包/详情 Prefab；隔离角色装备穿戴、强化 `0→2`、卸下及法宝穿戴/卸下均真实通过，缺图 `0`。
- 受影响模块真实回归：HeroEquip/FaBao、神将/阵容、任务均成功；UI 转换测试 `10/10`，严重运行异常 `0`。
- 完整可玩客户端按业务规模加权约完成 `18%`、剩余约 `82%`；静态 Prefab 为 `356/356`，不能混作业务完成率。

## 1. 迁移目标

保持原 C++ 游戏服协议和 Lua 业务意图，以 Unity/uGUI + C# 通用基础设施 + xLua 业务控制器重建客户端。迁移顺序固定为：

```text
运行时底座 → 网络/协议 → 数据/配置 → UI 通用层 → 资源/音频 → 自动化门禁
→ 登录与主界面壳 → 基础业务 → 成长业务 → 社交/玩法 → 活动/商业化 → 发布
```

不逐字翻译旧 `cc.*`、`LUIBase`、旧消息总线和 Cocos 节点 API；不一次性复制 729 个 Lua 文件。

## 2. 当前规模与完成度

| 资产/代码 | 数量 | 当前状态 |
|---|---:|---|
| 原客户端 Lua | 729 | 绝大多数尚未迁移 |
| 原业务 `View` Lua | 465 | 登录、背包、设置、任务、阵容神将、装备/法宝基础页已形成新实现 |
| 原 `Data` Lua | 72 | Player/Currency/Bag/Reward/Task/Hero/Formation/HeroEquipment/FaBao Store 已落地 |
| 原 `ConfigData` Lua | 64 | 背包仅复用 `item_dat`，其余待统一加载 |
| Cocos 兼容 Lua | 60 | 原则上不迁移，由 Unity/C# 替代 |
| 已转换 uGUI Prefab | 356 | 静态转换完成，复杂运行行为未全部恢复 |
| Unity C# | 46 | 含运行时、UI、Editor 导入/回归代码 |
| Unity Lua 模块 | 12 | Protocol、Login、Player、Bag、Settings、Task、Hero、Equipment、ServerTime、ItemCatalog |
| 服务端协议常量 | 约 248 | 需逐模块做请求/回包取证，不按常量数量宣称覆盖 |
| UI 转换测试 | 10/10 | 已通过 |

已完成运行闭环：正式启动场景、登录/创角/选角、重连、返回栈、主 HUD、背包全量与增量、真实道具使用、统一奖励、任务、系统设置、切换账号、神将列表详情与阵位变更、装备/法宝基础列表详情及穿脱、装备强化。

## 3. 目标分层

| 层 | 职责 | 禁止事项 |
|---|---|---|
| Core | App 生命周期、服务容器、环境配置、状态机 | 业务协议散落在 MonoBehaviour |
| LuaRuntime | Lua 模块加载、错误栈、受控重载、C#/Lua 桥 | 全量搬运旧 Cocos Lua |
| Network | TCP、包头、收发队列、超时、心跳、重连 | Presenter 直接读写 Socket |
| Protocol | 协议号、Reader/Writer、分发、错误码、请求上下文 | 依据旧注释猜字段 |
| Data | 配置表、玩家状态、模块 Store、增量合并 | UI 直接持有原始字节流 |
| UI Foundation | Router、层级、弹窗、返回、列表、红点、Loading | 每个模块重复造列表与弹窗框架 |
| Presenter | Unity 节点绑定、渲染、交互转发 | 在 Presenter 中写奖励和数值规则 |
| Lua Business | 模块状态机、协议业务、按钮业务 | 直接调用 `cc.*` |
| Validation | 静态校验、协议 smoke、PlayMode、截图/人工 QA | 只看日志中的旧 `COMPLETE` 判通过 |

## 4. 阶段 A：基础底层优先

### A0 工程与验收基线

| 项目 | 当前 | 交付 | 完成门禁 |
|---|---|---|---|
| 启动场景/Build Index | 已完成 | 固定 Bootstrap 为 Index 0 | 场景可重建、可批处理启动 |
| 环境配置 | 部分完成 | Local/Dev/Release 配置分层，命令行覆盖集中管理 | 不再由业务代码解析命令行 |
| 日志产物 | 部分完成 | 按模块分级日志、最近协议、异常上下文、单次运行报告 | 失败能定位到协议号/模块/阶段 |
| 回归入口 | 已完成首版 | 拆分 Foundation/Module/Full 三类 Runner | 每个模块可独立运行，结果不串线 |
| 进程生命周期 | 已有规则 | 启停与端口检查脚本化 | 阶段结束无 Unity/MySQL/kapai 残留 |

### A1 Core 与 LuaRuntime

优先级：P0。

- 统一 App 状态：Boot、Login、LoadingRole、Main、Disconnected、ShuttingDown。
- 增加结构化 Lua 错误栈，所有 Lua→C#、C#→Lua 回调带模块名和协议号。
- 增加开发态受控 Lua Reload：只在 Edit/Development 生效；重载前注销协议和按钮回调。
- 明确 Dispose 顺序：UI → Lua → Protocol → Network；禁止销毁对象二次访问。
- 将自动化参数集中为 `AppLaunchOptions`，替代 `ProjectXApp` 内零散判断。

门禁：登录、背包、设置现有回归全部不退化；LuaException 必须进入失败结果，不能停留在旧 COMPLETE。

### A2 Network 与 Protocol

优先级：P0。

- 保留现有旧包头、UTF-16LE、零载荷包和收发队列兼容。
- 增加统一协议注册表：协议号、模块、方向、请求 op、响应 op、字段解析器。
- 增加请求上下文：requestId（客户端内部）、发送时间、超时、当前模块；旧服务端无需支持 requestId。
- 增加通用错误包/业务错误码处理，落地 Toast/MessageBox，不允许静默失败。
- 增加心跳、服务器时间同步、断线期间发包保护、重复登录保护。
- 增加协议录制与脱敏回放：记录命令号、长度、字段摘要，不记录账号隐私。
- 生成“服务端实现—旧客户端收发—Unity 覆盖”三方矩阵。

门禁：未知协议、字段越界、超时、断线发包均有可判定错误；任务 `/37` 版本差异可通过真实回包确定。

### A3 Data 与配置层

优先级：P0。

- 建立 `ConfigService`：统一加载 64 个 `ConfigData`，支持按需加载、缓存、缺表/重复 ID 校验。
- 建立基础 Store：Player、Currency、Bag、Hero、Task、Mail、Shop、Guild。
- 增量消息只更新 Store，再由模块事件刷新 Presenter。
- 建立 Reward/Item/Attribute 通用模型，统一名称、品质、图标、数量和跳转来源。
- 建立服务器时间服务，活动倒计时禁止直接使用本机时间。
- 数据清理边界：切换账号清空角色 Store，配置缓存保留；断线不误清本地展示状态。

门禁：背包改为 Store 驱动且现有 `/8、/15` 回归不退化；配置缺项产生明确校验报告。

### A4 UI 通用基础设施

优先级：P0。

- UI 层级：Scene、Main、Window、Popup、Guide、Toast、Loading。
- Router 支持页面注册、单例/多例、参数、异步打开、关闭原因。
- UiStack 支持 Esc、遮罩点击、强制弹窗、互斥弹窗、返回主界面。
- 通用组件：MessageBox、Toast、Loading、Tab、分页、倒计时、奖励格、货币栏。
- 通用虚拟列表/对象池：固定高度先落地，支持空状态、排序、选中、刷新定位。
- 红点树：服务端 `/65` 与本地条件统一汇总，页面关闭时正确注销。
- 按钮防连点、请求中禁用、长按、二次确认。
- 分辨率、Safe Area、刘海屏和字体回退策略。

门禁：任务、阵容、邮件后续不得各自复制列表/弹窗/红点代码。

### A5 资源、音频与表现基础

优先级：P1，在任务列表前只完成必需子集。

- [x] `ResourceService`：Resources 统一入口、Sprite 缓存、引用释放、缺图占位和统计。
- [x] 图标规则集中配置：ItemIcons → MonsterBust → 默认头像回退，不再写死在 BagPresenter/RewardPresenter。
- Atlas/大图/角色立绘加载策略与内存上限。
- AudioService：BGM/SFX、音量、暂停恢复、场景切换；复用现有 PlayerPrefs。
- 字体、富文本、描边、数字字体和多语言占位策略。
- Timeline/Particle/Animator 建立迁移规范，业务首版不以特效阻塞功能闭环。

门禁：资源缺失计数进入模块报告；页面关闭后无持续增长的 Sprite/GameObject。

### A6 自动化与质量门禁

优先级：P0，随 A1-A5 同步完成。

每个模块至少具备：

1. 静态 Prefab/路径/资源校验。
2. Reader/Writer 字段边界测试。
3. 空数据、正常数据、增量数据测试。
4. 隔离角色真实协议 PlayMode 回归。
5. Esc、重复打开、断线、切换账号回归。
6. Console 中 C# 编译错误、LuaException、MissingReference、NullReference 为零。
7. 图形 Editor 可用时补 GameView 截图与人工点击；batchMode 不替代视觉验收。

## 5. 阶段 B：基础流程与主界面壳

| 模块 | 原 Lua/Prefab 规模 | 当前 | 后续工作 | 优先级 |
|---|---:|---|---|---:|
| 登录与角色 | Login 6 Lua / Login 6 Prefab | 本地直连、创角、选角已完成 | 服务器列表、选服、公告、Loading、错误提示、创角人工路径 | P1 |
| 主界面壳 | Main 9 + Common 35 Lua / common 30 Prefab | 主界面、背包/设置入口已接 | 玩家头像、等级、货币、服务器时间、入口注册、红点、通用弹窗 | P0 |
| 设置 | Setting 1 Lua / SystemLayer | 音量、切号已完成 | 公告、兑换码需等协议证据；补视觉 QA | P2 |
| 背包 | 分散于 Role/Common/Data | `/8、/15`、详情、图标、使用已完成 | Store 化、筛选、批量使用/合成入口、视觉 QA | P1 |

主界面壳完成后，业务模块只声明入口、页面、协议和 Store，不再修改 `ProjectXApp` 主流程。

## 6. 阶段 C：第一批基础业务

### C1 任务系统——第一个标准样板

原资产：`Main/TaskTrackSubUI`、`Data/LTaskData`、`Interact/NPCChatTaskUI`、`TaskPopupLayer`、`TaskAcceptLayer`、`huodong/RenwuLayer`。

协议候选：`/37、/39、/49、/89、/182`，最终字段必须以服务端实现和真实回包为准。

执行拆分：

1. `/37 op=1` 只读任务列表取证；解决旧客户端无 op、当前服务端要求 op 的版本差异。
2. TaskStore：任务定义、状态、进度、奖励、排序、追踪状态。
3. 主界面 `btn_renwu` → TaskController → TaskPresenter → `TaskPopupLayer`。
4. 通用虚拟列表、空状态、详情、奖励格、Esc 返回。
5. `/37 op=2` 日常增量、`/39` 旧主支线增删、`/65 type=101` 红点已完成；`/182` 待取证。
6. `/49、/89` 已完成/可接任务。
7. `/37 op=3` 奖励领取已使用隔离角色验证：任务 1 返回 `type=852,id=0,num=10`，重新拉表为 `state=2`；默认 userId 1 未用于改档。

首个门禁：登录 → 主界面 → 任务列表 → 选择条目 → Esc → 重开 → 断线错误展示。

任务模块剩余：奖励通用弹窗/奖励格、`/49、/89、/182` 取证、NPC 主支线详情与跳转、图形 Editor 人工视觉 QA。

### C1 后的基础迁移队列

下一步不直接进阵容业务，先补主界面和跨模块共用数据底座：

| 顺序 | 模块 | 交付 | 被谁复用 |
|---:|---|---|---|
| 1 | PlayerStore + CurrencyStore | 角色名、等级、经验、头像、铜币/元宝等增量；主界面 HUD 渲染 | 阵容、装备、商店、邮件、活动 |
| 2 | BagStore 正式化 | 把现有背包字典迁入 Store，统一 `/8、/15` 全量/增量和切号清理 | 装备、合成、商店、奖励 |
| 3 | RewardModel + RewardPresenter | 通用奖励三元组、奖励格、领取弹窗、缺图统计 | 任务、邮件、关卡、活动 |
| 4 | ServerTimeService | 服务器时间、倒计时、跨日刷新 | 商店、邮件、活动、福利 |
| 5 | 阵容/神将只读 | HeroStore、神将列表、详情、当前阵容 | 装备、战斗、培养 |
| 6 | 阵容上下阵 | 真实协议、位置校验、隔离角色回归 | 战斗入口 |

当前立即执行项：**PlayerStore + CurrencyStore + 主界面角色/货币 HUD**。这是阵容、装备和商店之前必须稳定的共享底层。

### C2 阵容与神将

规模：KaPaiPet 23 + Pet 15 + Role 9 + Skill 1 + HeroBook 7 Lua；Prefab 主要集中于 `shenjiangyangcheng` 28、`zhujue` 11 及根目录 Formation/Lineup/Role。

顺序：神将列表只读 → 详情/属性 → 阵容站位 → 上下阵 → 升级/进阶 → 技能 → 图鉴。

协议从 `/24、/25、/40、/41、/48、/51、/69、/70、/322` 逐项取证。先只读与上下阵，所有消耗培养后置并使用隔离角色。

### C3 装备与道具生产链

规模：EquipCultivate 13 + PetEquip 6 + FaBao 9 + Artifact 3 + HuiShou 9 Lua；Prefab 主要为 `zhuangbeiyangcheng` 21、`huishou` 7。

顺序：角色装备槽 → 穿脱 → 强化 → 精炼/觉醒/神铸 → 合成 → 分解/回收 → 法宝/神器 → 神将装备。

当前完成：`/319 op=1/op=17` 装备/法宝 Store、分包解析、真实列表/详情、装备穿脱与强化、法宝穿脱、`op=16/op=22` 权威增量。待完成：法宝强化/炼化、装备精炼/觉醒/神铸、合成、分解/回收、完整属性模型与全部视觉 QA。

依赖：BagStore、HeroStore、AttributeModel、RewardModel、确认弹窗、消耗预览。强化/分解等不可逆操作必须隔离角色验证。

### C4 邮件

规模：Mail 1 Lua + `MailLayer.prefab`。

顺序：列表 → 已读 → 附件展示 → 单封领取 → 一键领取 → 删除。邮件适合作为通用列表、红点、奖励格、批量操作的第二个验证模块。

当前完成：`/128 op=2/op=3`、`MailStore/MailPresenter/MailController`、真实 `MailLayer.prefab`、列表/已读/附件/单封领取、RewardPresenter、领取后权威列表复查、隔离角色自动化及 `1334×750` 视觉 QA。待完成：邮件红点、一键领取、删除及对应确认/空态回归。

### C5 商店与基础货币消费

规模：Shop 26 Lua + shop 6 Prefab。

顺序：商品列表只读 → 限购/刷新时间 → 购买确认 → 单次购买 → 刷新 → 特殊商店。依赖服务器时间、CurrencyStore、RewardModel、错误弹窗。

充值、直购、渠道 SDK 不与基础商店同时迁移，单独进入商业化阶段。

## 7. 阶段 D：社交、组织与场景战斗

| 模块组 | 原 View Lua 数 | 主要内容 | 前置依赖 | 优先级 |
|---|---:|---|---|---:|
| 社交/聊天 | Social 17 + Chat 7 + OtherRole 6 | 好友、黑名单、私聊、频道、查看玩家 | 玩家模型、聊天队列、敏感词/输入框 | P1 |
| 队伍 | Team 10 | 创建、邀请、成员、快捷组队 | 社交、场景状态 | P1 |
| 帮派 | BangPai 27 + BangPaiZone 9 | 创建/申请/成员/捐献/科技/活动/帮战 | 社交、排行榜、奖励、场景 | P2 |
| 排行/竞技 | Rank 4 + ZhengBa 6 + Arena 相关 | 排行、竞技场、争霸 | 玩家详情、战斗回放 | P2 |
| 世界/场景 | WorldMap 3 + Interact 4 + Main 子模块 | 地图、NPC、跳转、任务追踪 | 场景对象、任务、Loading | P1 |
| 战斗 | Battle 6 | 入战、过程、结算、回放 | 角色/技能/场景/动画/音频 | P1 |
| 副本玩法 | FuBenMap 12 + Instances 5 + WanFa 11 | 副本、关卡、玩法大厅 | 战斗、奖励、体力 | P2 |

战斗不是第一个业务模块：先用任务、阵容、装备把数据/UI/协议底座稳定，再进入场景和战斗。

## 8. 阶段 E：成长、玩法、活动与商业化

| 模块组 | 原 View Lua 数 | 内容 | 优先级 |
|---|---:|---|---:|
| 深度成长 | Mount 4、Wing 3、JingJie 3、FaBao 9、Artifact 3 | 坐骑、翅膀、境界、法宝、神器 | P2 |
| 中型玩法 | XueZhan 6、Tower 3、YouLiSanJie 2、FengShenStory 2、JueZhanKunLun 2 | 血战、塔、游历、列传、昆仑 | P2 |
| 活动 | Activity 39、OperationalActivity 2 | 日常、限时、排行活动 | P3 |
| 福利 | WelfareActivity 20、Welfare 11、DailySign 1、FirstAward 7、StageGoal 3 | 签到、首奖、阶段目标、在线奖励 | P2 |
| 抽卡 | HappyDraw 9、LuckyDraw 9 | 普通抽卡、活动抽卡、结果表现 | P2 |
| 商业化 | Recharge 2、Vip 4、Shop 的充值子模块 | 充值、VIP、渠道订单、直购 | P3 |
| 引导 | Guide 3 + ImproveUI 10 | 新手引导、变强、功能开启 | P2，核心流程稳定后 |

活动与商业化最后批量迁移：它们依赖服务器时间、红点、奖励、商店、弹窗、渠道 SDK，过早迁移会重复返工。

## 9. 阶段 F：发布与平台

- Windows Development Player：启动、登录、资源路径、日志、窗口/分辨率。
- Android IL2CPP/ARM64：xLua AOT、裁剪、网络权限、包体、真机性能。
- 资源分包/热更：版本清单、下载、校验、回滚；未拿到正式方案前不伪造线上热更。
- SDK：账号、支付、隐私、实名、防沉迷、统计、崩溃上报按发行渠道拆分。
- 性能指标：首包、启动时间、主界面内存、列表滑动、战斗帧率、GC、资源泄漏。
- 安全与合规：日志脱敏、隐私授权、支付回调校验、字体/音频/第三方许可证。

## 10. 每个业务模块的统一完成定义

一个模块只有同时满足以下条件才算“完成”：

| 编号 | 门禁 |
|---:|---|
| 1 | 原入口、原 Prefab、原 Lua 意图、服务端处理函数均已取证 |
| 2 | 请求与回包格式有代码证据或真实抓包证据，无猜测字段 |
| 3 | 数据进入模块 Store，UI 不直接解析网络字节流 |
| 4 | 使用真实迁移 Prefab，Presenter 不承载业务规则 |
| 5 | 空/正常/增量/错误/断线/重复打开/Esc 均通过 |
| 6 | 有独立自动化入口，失败不会继承旧 COMPLETE |
| 7 | 消耗和奖励使用隔离角色，验证前后状态可核对 |
| 8 | Console 严重异常为零，资源缺失有统计 |
| 9 | 图形环境可用时完成截图和人工点击 QA |
| 10 | 更新本计划、交接文档和协议覆盖矩阵 |

## 11. 立即执行批次

当前不直接开写任务 UI，先完成一个短底层批次：

1. [x] `AppLaunchOptions + AppState`：收口自动化参数和 App 状态。
2. [x] `ClientLog + LuaErrorBoundary`：统一 C#/Lua/协议失败报告。
3. [x] `ProtocolRegistry + RequestContext`：登记协议/op/模块/超时。
4. [x] `GameErrorPresenter + LoadingPresenter + ToastPresenter`：统一 MessageBox、keyed Loading 和队列式 Toast。
5. [x] `ConfigService + TaskStore` 最小版：为任务系统提供数据入口。
6. [x] `VirtualList` 最小版：任务列表首用，邮件/商店/神将复用。
7. [x] 取证并实测 `/37 op=1 type=1`，完成任务只读列表闭环。

上述任务、主界面 Store/红点、阵容及 `ResourceService + ServerTime + Loading/Toast` 均已完成。

下一批：`Shop Store` → 商品列表只读 → 限购/刷新时间 → 货币显示；随后使用隔离角色接购买确认与单次购买。邮件红点、一键领取和删除留在 C4 第二阶段；装备深度培养留在 C3 后续批次。

该批次完成后再进入阵容，不同时并行迁移多个业务模块。

## 12. 统计与进度维护

计划按模块维护三类数字：

- `Static`：Prefab、节点、资源已迁移。
- `Functional`：真实入口、协议、数据、交互已闭环。
- `Validated`：自动化、隔离角色、视觉/人工 QA 已完成。

禁止用 356 个静态 Prefab 数量代替业务完成度。每完成一个模块，在本文件对应表格更新状态，并在 `UNITYCLIENT_HANDOFF.md` 顶部追加最新增量记录。
