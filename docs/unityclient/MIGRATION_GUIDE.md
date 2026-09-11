# 《道友来封神》Cocos → Unity 迁移总指南

> 本文件是迁移路线、执行流程、完整标准、视觉标准、工具入口和高频坑的唯一稳定文档。
> 当前进度只看根目录 `UNITYCLIENT_STATUS.md`；模块事实只写入 `docs/unityclient/modules/`；日期流水只写入 `docs/unityclient/history/`。

## 0. 快速执行闭环

默认只执行以下闭环，当前步骤需要细节时再读取对应章节：

1. `Context/Preflight`：确认唯一模块、Steam范围、数据后端、输入指纹、进程端口和工具能力；不启动重运行时。
2. `Source closure`：打印入口→Lua→Prefab/动态资源→协议→服务端链；冻结 `given/when/then` 和可机器断言的业务前置条件。
3. `Targeted hybrid`：只验证当前失败控件/状态，必须同时具备真实输入、玩家可见UI、协议或SQLite权威结果和当前文件证据；JSON只作索引。
4. `Final convergence`：全部定向问题收敛后，只执行一次显式 `-FinalFull`、G5和G6；恢复、重登、完整性、残留和最终用户Play全部通过后收口。

失败不盲跑：第一次先诊断；同签名第二次修公共工具/预检；第三次补中央回归。截图前先断言业务输入确实能产生目标状态。纯文档/矩阵改动不启动Unity，视觉修复只重验受影响状态，协议/夹具/共享源码变化才从最早失效门禁扩大范围。

## 1. 默认读取顺序

1. `AGENTS.md`：项目和运行约束，由任务环境提供时不重复读取。
2. `UNITYCLIENT_STATUS.md`：只读当前焦点和目标模块行。
3. `docs/unityclient/STEAM_SCOPE.md`：Steam模块黑名单；命中 `steam-excluded` 时立即停止。
4. 本文件：先读“快速执行闭环”，再按当前门禁定点读取。
5. `docs/unityclient/modules/README.md`：模块索引。
6. 当前目标模块文档和目标矩阵：调用链、协议、控件和证据。

默认禁止完整读取 `history/`、其他模块、全量Manifest、完整Ledger和完整日志；Ledger只查未解决项与最近同签名失败，日志只读错误附近或尾部100行。

## 2. 文档与机器状态唯一性

| 信息 | 唯一位置 |
|---|---|
| 实时完成率、当前批次、下一步 | `UNITYCLIENT_STATUS.md` |
| Steam平台纳入/排除边界 | `docs/unityclient/STEAM_SCOPE.md` + Manifest `migrationExcluded` |
| 路线、G0-G6、功能/视觉标准、工具和坑 | 本文件 |
| 模块调用链、协议、实现与验证 | `docs/unityclient/modules/<MODULE>.md` |
| 控件验收结果 | `docs/unityclient/matrices/<MODULE>_CONTROLS.json` |
| G0-G6 机器状态 | `tools/unity-migration/migration-gates.json` |
| 模块/Runner/资源清单 | `tools/unity-migration/unityclient-modules.json` 等 JSON |
| 日期流水与旧全文 | `docs/unityclient/history/` |

禁止维护第二份实时百分比、第二套 SOP、第二份模块控件表或“精简版/完整版”并行活跃文档。

## 3. 产品归属门禁

仓库含旧游戏 Lua 和多代 UI。当前迁移产品固定为《道友来封神》。

模块进入当前清单必须依次满足：

1. 当前启动配置/窗口属于《道友来封神》。
2. 从当前 `MainUI` 存在真实事件绑定。
3. 经 `OpenFunction` 追到当前 `AppDef.moduleUI`，或由当前闭包代码经 `InitUI` 到达。
4. Lua、CSB、动态资源和协议链真实存在。
5. 当前账号能从玩家入口运行到达。

文件存在、目录名相似、AppDef 残留枚举、Prefab 已导入、历史截图或旧游戏曾使用，都不能证明属于当前版本。未证明项标记 `unqualified`，禁止迁移。

当前机器清单：`tools/cocos-audit/generated/`。

## 4. 工程定位与运行边界

| 项 | 路径/地址 |
|---|---|
| Cocos 客户端 | `client/ProjectX/` |
| Unity 工程 | `unityclient/` |
| 服务端 | `server/` |
| 本地游戏服 | `127.0.0.1:8711` |
| workspace MySQL | `127.0.0.1:3306` |
| 模块 Manifest | `tools/unity-migration/unityclient-modules.json` |
| 场景/夹具 | `validation-scenarios.json` / `validation-fixtures.json` |

静态阅读和文件修改不启动服务。协议联调只启动 MySQL + `kapai.exe`；Cocos 取证只加 Cocos；Unity 验收只加 Unity。禁止两套客户端长期同时常驻。

## 5. 技术分层

```text
真实入口 / 原始 Prefab
  → 旧 Lua Controller / Legacy Model（协议、业务规则、权威状态）
  → 通用 C# Bridge（Socket、字节流、Unity节点/资源/动画适配）
  → Unity UI 渲染
```

- Lua 优先复用旧 Controller、Logic、Data；直接依赖 `cc/ccui` 的显示调用进入兼容层。
- C# 不解析业务规则、不伪造奖励/消耗/成功结果；现有 Store 只能作为渲染镜像。
- 网络数据先进入 Lua 权威模型，再同步 C# ViewState。
- 切号清理角色态、pending、监听和 UI 栈；配置缓存可保留。
- 新模块不得继续固定新增业务型 `Store.cs + Catalog.cs + Presenter.cs` 套件。

## 6. 路线与顺序

1. P0 基础层：登录与创角 → 系统设置 → 主界面 HUD。
2. P1 核心养成与单人功能：强化大师 → 神将培养模块B → 将魂商店 → 抽卡 → 神将/阵容 → 装备（法宝边界回归） → 玩法大厅模块组（大厅框架、封神列传、法宝搜索、游历三界）。玩法大厅按父模块汇总，但内部仍逐门禁单元串行验收。
3. P2 运营与商业化：先完成 `modules/PAYMENT.md` 支付前置，再迁移活动 → 全部基金 → 福利。
4. P3 竞技/玩家依赖：竞技场 → 决战昆仑。
5. P4 社交最后：好友 → 聊天 → 队伍 → 帮派/宗门。
6. 发布收口：热更、性能、Android/Windows、监控、发布门禁。

同一时间只处理一个模块。上一门禁未通过，不得编码、切阶段或启动下一模块；跳过门禁必须先记录阻塞并取得用户明确批准。

进入 P2 的活动、全部基金或福利 G0 前，必须先完成支付前置：测试模式点击充值直接进入服务端权威成功结算，正式模式只走三方 SDK；宏、源码入口、按钮清单和验收条件统一见 `modules/PAYMENT.md`。

### 6.1 Steam 单机 SQLite 与双击启动前置

Steam Windows 正式版的发布目标固定为：玩家只启动 Unity 客户端 EXE；客户端在网络层初始化前准备本地数据、启动 `kapai.exe`、等待 `127.0.0.1:8711` 就绪，退出时安全落盘并只回收本次拥有的后台进程。正式包不得依赖 PowerShell、源码目录、已安装 MySQL、Visual Studio 或管理员权限。

该基础能力前置于剩余 Steam 业务模块，按 S0-S8 串行推进：

| 门禁 | 目标 | 主要交付与通过条件 | 参考节奏 |
|---|---|---|---:|
| S0 范围与基线 | 冻结 Windows x64、单机本地服、SQLite、本地直连边界 | 保存当前 MySQL 的 L1-L4、协议、数据快照和 SQL 清单；明确 Steam 纳入/排除模块；失败时不进入 S1 | 1 天 |
| S1 双后端封装 | 保持 `CDatabaseSql` 上层接口，新增 SQLite 驱动 | MySQL 路径原样可回归；SQLite 可编译、连接、查询、取行数和插入 ID；不得先删除 MySQL 回退 | 2 天 |
| S2 Schema 与版本迁移 | 建立可重复生成的 SQLite 初始库和增量迁移 | 表、索引、默认值、种子逐项核对；新增 `schema_version`；首次启动幂等，升级失败保留原库和备份 | 2-3 天 |
| S3 SQL 兼容收敛 | 处理 MySQL 方言与运行时查询 | 优先在数据库适配层注册时间/字符串兼容函数并做有限语法转换；剩余 SQL 定点改写；禁止吞错或将失败当空结果 | 3-5 天 |
| S4 核心数据闭环 | 打通登录、创角、选角、主初始化、存档、重启读档 | SQLite 下完成协议 smoke、正常退出、强制中断恢复和跨进程数据哈希；MySQL/SQLite 关键结果语义一致 | 2-3 天 |
| S5 Steam 业务回归 | 验证全部 Steam 保留模块的数据读写和持久化 | 只跑 Steam 纳入模块；查询/消耗/奖励/战斗/重连/切号逐项验证，夹具精确恢复且残留 0；排除模块不得重新开启 | 4-6 天 |
| S6 Unity 启动监管 | 由客户端完成准备、启动、等待和故障展示 | `ProjectX.exe` 单入口；启动状态可见；超时/端口冲突/后端崩溃有明确错误；重复启动不产生重复服务 | 2-3 天 |
| S7 发布与生命周期 | 固化只读安装资源、用户数据、升级和退出规则 | SQLite 和日志写入 `Application.persistentDataPath`；服务端只绑定 loopback；数据库备份轮转；优雅退出超时后才强制回收 | 2-3 天 |
| S8 干净机验收 | 证明 Steam 下载后双击即可运行 | 无 MySQL/pwsh/开发环境的干净 Windows 用户完成首启、二启、存读档、更新迁移、崩溃恢复、中文路径和只读安装目录验收 | 1-2 天 |

整体按 15-25 个工作日规划；若 S3 发现未纳入静态清单的动态 SQL 长尾，最高预留到 30 个工作日。每个门禁单独验证和收口，上一门禁失败不得靠 Unity 假数据、静默降级或保留外部 MySQL 依赖进入下一门禁。

固定实现边界：

- MySQL 作为开发回归对照后端持续保留到全部 Steam 保留模块完成验收；即使 S5/S8 已通过，也不得删除 MySQL 驱动、构建参数、脚本、Schema 或回归能力。只有用户在全部模块验收后再次明确通知，才允许单独审计并删除；正式 Steam 包可在此之前仅打包 SQLite，不携带 MySQL 二进制。
- SQLite 优先静态链接到 `kapai.exe`，正式运行只保留 Unity 与 `kapai.exe` 两个进程，不再启动独立数据库进程。
- Steam 发布 Manifest 必须覆盖 Depot 中除 Manifest 自身外的全部客户端、Unity Runtime 和内置服务端文件；构建后必须清除 `*DoNotShip*`，并对完整发布树拒绝 PDB、`mysqld.exe`、`pwsh.exe`、`powershell.exe`，禁止只校验 EXE 或内置服务端子树。
- 安装目录只保存不可变的 `kapai.exe`、脚本、XML、DAT 和初始数据库资源；玩家数据库、生成配置、日志、备份和迁移锁全部进入用户数据目录。
- Unity 必须在构造 `GameServices` 和发起网络请求前等待后端 Ready；服务端必须支持显式配置/数据路径，禁止依赖源码仓库工作目录。
- SQLite 的本地默认自动角色与显式创角必须在 `ReadData` 前共用同一套 `role_info` NULL 字段归一化；既要验证全新数据库首次自动建角，也要验证历史缺省角色可原地修复，禁止把 SQL NULL 直接交给旧 `atoi`/字符串读取路径。
- 更新数据库必须先备份、事务迁移、完整性检查再原子切换；失败时保留旧库并阻止带损坏数据进入游戏。
- 现有 Cocos/Unity 视觉证据不会仅因数据库驱动切换自动失效；但 S5 必须重验协议载荷与持久化语义，发现输出变化时重开对应模块受影响门禁。

## 7. 完整验收单位

验收单位不是“页面”，也不是手工挑选的若干控件，而是：

`入口 → 页面 → 可操作控件 → 前置状态 → 操作 → 业务结果 → UI反馈 → 持久化/恢复`

每个 Cocos 当前版本可见或可达的按钮、列表项、Tab、槽位、技能图标、关闭区、滑动区、红点和引导热区都必须单独登记。只复制 Prefab、显示数据或让协议返回成功，不算控件完成。

凡由配置或数据驱动的功能，G0 分母必须从当前源码、协议注册和配置表反向生成，不得由执行者手写一个较小集合再宣称 100%。至少登记 `来源文件/记录总数/业务ID/分支类型/覆盖场景ID/排除理由`；报告必须同时给出 `总数、已覆盖ID、未覆盖ID`。未覆盖项非零或排除项缺少产品依据时，后续 G1-G6 全部不得标绿。

所有会改变玩家数据的操作，验收单位还必须包含完整事务：

`操作前权威快照 → 真实UI输入 → 请求/回包或推送 → 来源资源变化 → 目标资源变化 → 持久化回读 → 玩家可见反馈`

成功时七段必须全部成立；失败时必须证明来源/目标数据均未错误变化，并收到可解释的失败结果。仅有“请求已发送”“日志显示发奖”“内部变量已变化”或“目标页面已打开”均不构成业务通过。

## 8. 单控件 12 项硬门禁

| # | 验收项 | 必须满足 |
|---:|---|---|
| 1 | 节点 | Transform、位置、尺寸、锚点、层级、裁剪和点击区域一致 |
| 2 | 可操作性 | 真实 Button/事件绑定；正常、禁用、锁定状态正确 |
| 3 | 真实入口 | 从玩家入口点击到达，禁止直接调用内部 Show/Open/Complete |
| 4 | 前置条件 | 等级、阵位、材料、货币、次数、锁定与旧 Lua/服务端一致 |
| 5 | 业务行为 | 页面/弹窗、协议/op、参数顺序和状态变更一致 |
| 6 | 权威结果 | 成功后以服务端回包/推送或旧 Lua 权威状态刷新 |
| 7 | 完整反馈 | Loading、按钮态、音效、Toast、确认框、红点一致 |
| 8 | 动画表现 | Pressed/Disabled、Timeline、Imod、特效、数值跳变一致 |
| 9 | 异常分支 | 空态、材料不足、非法、重复、超时、断线、拒绝均正确 |
| 10 | 生命周期 | 重拉、返回、重进、重连、切号正确，无重复监听和旧角色数据 |
| 11 | 双端证据 | 同账号、同数据、同步骤、同分辨率的 Cocos/Unity 证据 |
| 12 | 自动+人工 | 直接控件由 Runner 从真实控件触发；空态、重启、重连、切号等场景状态由登记的 batch capture state 触发，禁止伪造 `realEntryClick=true`；最后一次相关变更后由用户在真实 Play 路径确认 |

12/12 才能标记单控件 `complete`。页面完成率必须为在册控件 `100%`，模块完成率必须为全部页面、弹窗、Tab、返回和跨页状态 `100%`。

## 9. G0-G6 唯一执行流程

### G0 范围冻结

冻结模块、入口、页面、弹窗、全部控件、状态、成功/失败分支、测试账号、分辨率、包含项和排除项。生成控件矩阵并写入 `workflowPolicyVersion=1`；用 `acceptanceExamples` 以 `given/when/then` 冻结至少一个具体产品结果，禁止把“分组、汇总、刷新”等歧义拖到 G5；任何 Cocos 可达控件遗漏则后续结果全部无效。

G0 必须先生成“覆盖清单”再写控件矩阵。除可见控件外，还要从当前源码/配置枚举所有业务分支，例如全部 `use_type`、`use_jump`、可选礼包、随机盒、直接使用道具、来源跳转、动态列表状态和协议 op；每个业务ID必须映射到至少一个成功场景和必要的失败/边界场景。矩阵中的 100% 只允许以该可追溯清单为分母，禁止用自选控件数、历史Runner数或已有截图数作为模块完成率。

退出条件：范围无歧义；测试账号可复现；覆盖清单来源和总数可复算；未覆盖ID为0；排除项均有证据；矩阵覆盖率100%；机器门禁为 G0 passed。

### G1 Cocos 运行链取证

打印 `入口 → Lua回调 → Utils:OpenFunction/InitUI → View/Controller → CSB/CSD → 动态节点/Timeline/Imod → 协议`。从真实入口取得每个关键状态的 Cocos 截图/视频和日志。迁移操作统一走 `computer-use@openai-bundled`；用户入口可显示为 AdsPower Browser 插件链接，但自动化目标必须唯一匹配原生 `ProjectX.exe / Cocos Simulator`，不得操作 AdsPower 浏览器窗口。启动 MySQL、夹具和客户端前先落 Computer Use transport preflight；再按矩阵 `fixedUserId/fixedRoleId` 启动固定身份客户端，并由本轮新增服务端日志回读确认身份。窗口取证必须完成唯一 `ProjectX.exe`、当前 `WindowId`、输入可用和原始 `1336×777` 检查，统一无缩放裁切 `(1,26,1334,750)`。每次观察后只执行一个状态派生动作并立即刷新；首次未到达立即记录失败并转源码、日志和协议诊断。

G1 一次采齐预计进入 G5 的全部 Cocos 状态后，用中央生命周期工具冻结图片 SHA、状态输入和固定身份指纹。该基线属于本轮新鲜证据，不等同于历史截图；只要源码、资源、账号、夹具、步骤、分辨率和稳定帧输入指纹未变化，G5 默认直接复用，不再重复操作 Cocos。

退出条件：所有冻结状态有有效 Cocos 证据；截图窗口、标题、账号、角色、步骤、分辨率和目标节点一致；无猜测链路；G1 门禁同时校验操作台账、Computer Use preflight、固定身份回读和可复用基线。

### G2 迁移设计

确认旧 Lua 权威数据、协议/op/字段/错误码、服务端处理、配置和资源、Unity Transform 映射、Lua/C#边界、重连与切号策略。控件矩阵 `sourceAudit` 必须分别关闭入口闭包、共享协议所有权、配置→资源闭包和运行时 Transform 四项检查；源码确实缺失的内容逐项登记 `id/handling/evidence`，不得靠猜路径或临场占位。若 G1 后变更了任一 Cocos 基线输入，必须显式失效受影响状态并只补拍这些状态；未受影响状态继续复用原 SHA。静态 CSB/Prefab 节点不能代表完整界面，必须继续追踪 View Lua 加载后的 `ItemCellUI`、品质框/角标/数量层、TableView 行列数、触摸吞噬、Timeline/Imod 完成回调、动态层级和 Store/事件监听，并在矩阵冻结静态节点与运行时改写语义；只绑定 `Icon/Name` 或只看到协议回包即结束审计，判 G2 失败。同类容器必须先检索公共组件：背包、碎片、候选列表等有限视口动态列表优先统一使用 `VirtualList`，禁止页面内平行创建 `RuntimeContent + ScrollRect`，除非矩阵登记不可复用原因、差异合同和独立回归；公共合同至少包含 viewport 射线面、RectMask2D、content 尺寸、滚轮/拖拽转发、按钮不吞父级拖拽、行复用和重绑不重复生成节点。

配置驱动操作必须完成逐ID闭包审计。例如随机奖励必须证明 `item → drop_matching → level_reward → reward → 最终item` 全链存在、等级区间覆盖测试角色和产品边界、奖励池非空、最终ID有效、数量/权重合法；可选礼包、商店、任务和其他数据驱动模块按其真实配置链执行等价检查。协议审计必须同时明确成功回包、失败回包、推送数量/顺序、客户端 pending 清理和静默返回风险。发现任一断链、空池、越界或服务端静默返回，G2 失败，禁止启动 Unity 补表现掩盖。

退出条件：三方证据齐全；资源类型与播放语义明确；每个控件都有实现与验证设计；`sourceAudit` 机器门禁通过。

### G3 实现、影响集回归与早测收敛

接入真实 Prefab、资源、Lua Controller/Legacy Model 和 C# Render Bridge。按矩阵绑定真实控件；排除功能必须隐藏或禁用，不能保留空壳入口。本门禁内部统一执行“实现 → 按变更影响面分流回归 → 代理自检 → 用户早测 → 反馈修复 → 受影响项再验证”的收敛循环，不再把影响集回归作为独立阶段；循环稳定后只执行一次当前输入下的 G3 最终验证，才允许进入 G4。退出条件：编译通过；无占位资源/伪造数据；静态路径、协议路由、生命周期边界通过检查；场景在 G3 前已登记 `requiredGate=G3`、全控件覆盖、语义断言、源码锚点、全部截图状态和 `1334×750` 视觉断言；变更型模块已有固定账号数据合同。

#### G3 早期真实 Play 检查点
G3 初版 UI、协议和代码可运行后立即暂停，由用户从真实入口进行一次早期 Play，优先评价入口、信息层级、主要反馈和整体体验；邀请用户前，代理必须先完成源码合同、DataPreflight、Unity编译/Console、中央工具链、运行时层级/输入，以及动态属性、权威刷新、动画完成清理、按钮显隐和Toast全生命周期等模块专项自检，明显的绑定、刷新、拖拽和生命周期错误不得留给用户首次发现。固定账号Runner还必须验证`unityclient/Assets/ProjectX`内全部PNG/JPG/字体均已脱离Git LFS指针状态；早期Play允许用户从主界面进入既有模块，不能只水合当前模块的入口闭包后把其他已导入界面的缺图留给用户发现。代理同时准备固定账号/数据、启动方式、5–15分钟主路径清单和已知限制，不得等到 G4-G6 完成后才让用户首次体验。反馈写入 `.local/unity-validation/<module>-early-user-play-latest.json`，至少包含 `module/checkpoint/userParticipated/testedUtc/entryPath/result/feedback/agentRecheck`；`blocking` 项必须修复并由代理用文件证据复核，`non-blocking` 项必须修复或经用户明确接受。此轮自检和早测都不设置`manualPassed=true`，不能替代最后一次相关变更后的G4自动事务验证或G6最终确认；缺自检证据、缺早测记录、用户未实际参与、代理复核证据缺失或仍有阻塞项时，G4机器门禁拒绝通过。

用户在当前任务中明确全权委托代理执行该早测时，允许如实记录`userParticipated=false`与`userDelegatedAgentPlay=true`，但必须保存模块限定的授权文件、使用真实Unity Editor与EventSystem、提供文件化操作和代理复核证据，并强制`delegation.finalUserConfirmationRequired=true`。该委托只替代G3后的早期体验检查，不得伪装成用户参与，不得设置`manualPassed=true`，也不得替代最后一次相关变更后的G6用户最终确认。
### G4 逻辑动态验收

验证列表/全量/增量、正常写操作、空态、材料不足、非法/重复、超时/断线、重拉、重连、返回、切号。每项必须由真实控件触发，服务端结果与 UI 刷新一致。真实控件触发必须经过实际 EventSystem/输入链，覆盖点击射线、列表项、Toggle、数字键输入/删除/清空、滚轮/拖拽、确认/取消、关闭/返回；直接调用 Presenter、Show/Open/Complete、回调函数或修改内部状态的结果一律无效。交互回调被调用不等于成功：滚动/拖拽必须先证明 `content > viewport`，再验证真实输入后 `anchoredPosition` 或等价权威位置实际变化，并覆盖卡片/按钮与空白区域；动画必须验证完成后节点状态和末帧清理；跨页/公共层必须验证最终 sibling、可见性和 UI 栈。`hardGateVersion<4` 仍只接受已打开 Unity Editor GameView 中经 Computer Use 逐项取得的证据。`hardGateVersion=4` 可用双端 `engine-input-replay` 覆盖完整逻辑分母，但每条记录必须同时包含运行时目标节点、命中链首项、实际引擎事件派发、协议号/长度/原始包 SHA-256/解码字段、变化节点、稳定帧和动画清理；Presenter/回调直调、`simulation=true` 或缺原始协议证据一律失败。引擎内回放不冒充 Windows 真实输入，必须另以 Computer Use 在 Cocos 与 Unity 各抽取合同规定的代表性控件（Draw 试点各不少于 8 个），用户最终真实 Play 仍不可替代。`-batchMode`、MCP和内部完成方法只能用于编译、夹具、独立 oracle 及诊断。

所有写操作必须用独立权威 oracle 比对操作前后快照：来源道具/货币/次数、全部可能的目标背包/属性/进度、数据库持久化及重登录回读。随机结果不要求固定命中，但必须属于当前有效奖励池、总次数和总增量正确。成功还必须断言玩家可见的道具名、数量、属性变化或等价原版反馈；失败必须断言原子性和明确失败回包。UI 刷新必须复刻 Cocos 权威事件链：回包/推送或权威重拉 → Lua/Store 更新 → 可见页订阅刷新 → 进度、列表数量、货币和目标结果同步变化；原版依赖 `BagDataChanged` 等事件时，Unity 必须登记订阅和解除订阅生命周期，只验证目标新增、不验证来源扣除及当前页重绘，事务不通过。禁止让被测客户端自己的内存状态或“发奖完成”日志同时充当实现与验收依据。

时序场景至少覆盖立即回包、延迟回包、一次操作多条推送、页面关闭/切换后回包、失败回包、静默/超时、断线重连和切号。每个跨页动作同时断言目标页已打开、原页面应显式隐藏/销毁、UI栈无重复实例、延迟回包不会错误重开旧页。

退出条件：覆盖清单中的业务ID和真实控件均为100%；成功/失败/边界及时序场景通过；完整事务、权威持久化、玩家可见反馈和清理通过。

### G5 视觉对照

固定同账号、同数据、同步骤、同分辨率和同稳定帧。G5 首先校验 G1 基线的图片 SHA 与状态输入指纹；通过则直接复用该轮 Cocos 原图，只重新取得 Unity 稳定帧并生成并排图、50%叠加图、增强差异图和差异报告。仅当具体状态的源码、资源、账号、夹具、步骤、分辨率或稳定帧输入改变时，才重新取得该状态的 Cocos 原图并刷新基线；不得为了形式重复跑一遍全部 Cocos。逐项核对文字、图片、位置、尺寸、层级、裁剪、动画、点击态和反馈。

视觉断言必须同时描述“应显示”和“不应显示”：可见文本真实内容、输入值、奖励名称与数量、按钮/Toggle状态、目标页面，以及必须隐藏的原页面、背景层、旧弹窗和重复UI栈。只证明目标页已打开、内部Text值已变化或截图文件存在，不算视觉通过；运行时可见属性断言与最终稳定帧证据必须互相一致。

截图必须为原生客户区 `1334×750`，Windows 100%缩放，禁止桌面截图或二次放大。`Image`、CSB Timeline、Imod 不可互相替代；`CreateAnimModel + PlayStand` 必须迁真实资源、动作号、循环、缩放和挂点。

Cocos 自动化采用 Computer Use 的原生窗口级观察与输入：每次从最新 `ProjectX.exe / Cocos Simulator` 状态派生一个动作，执行后立即刷新，不复用旧坐标、旧截图 ID 或旧元素索引。常规项目内点击、拖动、滚动和截图已预授权；首次未进入目标页立即记失败并转查 Lua 回调、客户端日志、协议回包。出现“网络超时”、协议失败、账号不可用等明确终态时，本次等待立即结束并记账，禁止继续等待或坐标试错。无法到达的页面保留 `pending`，不得用 AdsPower 浏览器页、桌面截图、旧截图或 Unity 单端证据替代。

退出条件：所有状态双端证据齐全；无错误图片、占位文字、截断重叠、公共层遮挡或未解释差异。

### G6 回归与收口

从真实主界面入口重新进入模块并完成异常恢复；同时完成异常扫描、16/16 UI、构建幂等、文档门禁、Git范围和清理检查。v4 模块由双端运行时 JSON 回放覆盖完整控件分母，并以双端 Computer Use 代表性真实输入抽检证明窗口级输入可达；构建、静态检查和引擎内回放均不替代最终 GameView 真实 Play。

自动化通过后只能报告“G6 自动化通过、用户最终确认待完成”，模块仍保持 G6 pending。G3早期Play用于尽早反馈，不等于最终确认；`manualPassed=true` 只能由用户在最后一次影响该模块的代码、Lua、Prefab、场景、资源、服务端、配置或Fixture变更之后，使用真实 Play 路径明确确认。代理自行点击、Runner、MCP、旧人工记录或变更前的早期Play均不得代替。

退出条件：`hardGateVersion<4` 沿用直接控件逐项 `realEntryClick=true` 与逐状态 GameView 证据。`hardGateVersion=4` 要求 Cocos/Unity 各自运行 100% 场景动作且 `logicalPassed/eventDispatchPassed/hitTestPassed/protocolPassed/uiStatePassed/stableOutcomePassed/cleanupPassed` 全真，双端语义对比 100%、每端真实输入抽检达到合同下限、9 个视觉状态当前指纹有效、SQLite 快照/恢复/重登哈希/完整性/残留全通过，并由用户在最后一次相关变更后确认 `manualPassed=true`。`simulation=true`、缺失 JSONL、旧指纹或 BatchMode 产物不得填充交互证据。覆盖清单未覆盖 ID 为 0、工作区无越界变更后，模块才可标记 `migration-complete`。任一相关输入在用户确认后再次变化，自动撤销受影响的 `manualPassed` 和 G4-G6 结论。

## 10. 状态口径

| 状态 | 含义 |
|---|---|
| `shell-only` | 只有页面/资源，业务控件基本未绑定 |
| `read-only` | 权威数据可显示，写操作未闭环 |
| `partial-interactive` | 部分真实控件可操作，矩阵未达100% |
| `functional-complete` | 全部控件和业务分支通过，视觉尚未1:1 |
| `visual-complete` | 功能完整且全部状态视觉/动画1:1 |
| `migration-complete` | 功能、视觉、异常、持久化、自动化、人工全部通过 |
| `legacy-unverified` | 历史结论未按当前逐控件标准复验 |

禁止用“第一阶段完成”“逻辑跑通”“G6通过”代替迁移完整。

## 11. 控件矩阵固定字段

`条目类型（直接控件/场景状态） | 页面 | 控件路径或场景路径 | 可见条件 | Cocos回调 | 协议/op | Unity绑定 | 成功反馈 | 失败反馈 | 重连结果 | Cocos证据 | Unity证据 | 自动结果 | 人工结果 | 状态`

Runner/文档门禁必须读取矩阵及其覆盖清单，验证分母来源、业务ID全量覆盖、真实点击、失败分支、完整事务、玩家可见反馈和用户人工验收。动态列表按正常、空、锁定、选中、禁用至少各验证一次。截图保留在本机`.local/ui-fidelity/`且不入库；静态文档检查只校验合同，进入对应动态门禁时使用`Test-UnityMigrationDocs.ps1 -RequireLocalEvidence`强制校验本机图片，缺图必须由标准流程重跑生成。

## 12. 工具入口

### Unity 本机路径统一规则

- 仓库 Manifest `tools/unity-migration/unityclient-modules.json` 只提交 `unityVersion`，`unityExecutable` 必须保持空字符串；禁止提交 `C:\...`、`D:\...`、`E:\...` 等个人安装路径。
- 所有迁移脚本必须通过 `Resolve-UnityMigrationUnityExecutable` 获取 Editor，不得在模块脚本、命令文档或 C# 中另写绝对路径。
- 解析优先级固定为：命令行 `-UnityExecutable` → 环境变量 `PROJECTX_UNITY_EXECUTABLE` → 本机忽略文件 `.local/unity-migration/settings.json` → Manifest 兜底 → Unity Hub 默认目录 → Unity Hub 次级安装目录 → 各磁盘常见目录。
- 一般无需配置；Unity Hub 已登记安装位置时会自动找到与 `unityVersion` 相同的 Editor。自动发现失败时，每台电脑只需配置一次，二选一：

```powershell
# 方案A：当前用户永久环境变量（重新打开终端后生效）
setx PROJECTX_UNITY_EXECUTABLE "D:\Unity\Hub\Editor\2022.3.62f3c1\Editor\Unity.exe"

# 方案B：仓库本机配置；.local/ 已被 .gitignore 排除，不会提交给其他人
New-Item -ItemType Directory -Force .local/unity-migration | Out-Null
'{"unityExecutable":"D:\\Unity\\Hub\\Editor\\2022.3.62f3c1\\Editor\\Unity.exe"}' |
    Set-Content -Encoding UTF8 .local/unity-migration/settings.json
```

- 临时指定只用于诊断：`./tools/unity-migration/Run-UnityModuleValidation.ps1 -Module <Module> -UnityExecutable <Unity.exe>`；不得为此修改仓库文件。
- `Test-UnityMigrationDocs.ps1` 会拒绝非空 `unityExecutable` 或与 `ProjectVersion.txt` 不一致的 `unityVersion`；`Test-UnityMigrationToolchain.ps1` 会验证解析结果存在且编译指纹稳定。

| 工具 | 用途 |
|---|---|
| `Get-ProtocolEvidence.ps1` | 提取服务端、Cocos、Unity、smoke协议证据 |
| `New-UnityMigrationModule.ps1` | 默认生成规划文档、控件矩阵和 pending 门禁；`-IncludeImplementationSkeleton` 受 G2 前置门禁保护 |
| `Invoke-UnityMigrationCocosEvidence.ps1` | 落 Computer Use transport/窗口预检、固定身份回读及可复用 G1 Cocos 基线 |
| `Invoke-UnityMigrationGate.ps1` | 检查/落账 G0-G6 |
| `Run-UnityModuleValidation.ps1` | 场景、夹具、Watchdog、结果和清理 |
| `Run-UnityFixedAccountValidation.ps1` | 按模块契约执行固定账号快照、注入、真控件验证、精确恢复和重登录复核 |
| `New-UnityModuleG5Evidence.ps1` | 按模块契约生成双端并排/叠加/差异、输入哈希和提交来源报告 |
| `Test-UnityMigrationConnection.ps1` | 调用 Unity MCP 前检查实例、监听、启动日志和孤儿监听 |
| `Test-UnityMigrationHardGates.ps1` | 验证场景/账号/角色/分辨率、控件矩阵、运行摘要和 G6 证据 |
| `Test-UnityMigrationDocs.ps1` | 状态、Manifest、路径、矩阵和完成证据 |
| `Test-UnityMigrationGitScope.ps1` | 语义变更、Unity meta和范围检查 |
| `Test-BootstrapSceneIdempotence.ps1` | Bootstrap连续两次哈希一致 |
| `tools/cocos-audit/Export-CocosCurrentInventory.py` | 当前产品入口闭包和控件候选 |
| `tools/ui_migration/convert_ui.py` | UI IR、CSB兜底、Prefab准备 |
| `tools/ui_migration/convert_animations.py` | Imod ANI解析与资源准备 |
工具路由为机器策略，不得临场替换：Cocos 只走 Computer Use 的 `ProjectX.exe / Cocos Simulator` 原生窗口；Unity动态验收只走Computer Use操作已打开Unity Editor的GameView。`Run-UnityModuleValidation.ps1`与`Run-UnityFixedAccountValidation.ps1`保留用于编译、夹具、独立oracle、恢复和诊断，结果不计为验收通过；G5仍走中央状态对和`New-UnityModuleG5Evidence.ps1`生成差异材料，但Unity原图必须来自已打开Editor；G6的`BuildBatch`只检查构建幂等，不替代交互验收。Computer Use明令要求确认的删除、安装、对外提交等高风险动作仍须确认。
新模块脚手架会自动刷新当前 Cocos 入口 inventory、按登记协议生成 `Get-ProtocolEvidence` 输出，并把中央 `root-cause-rules.json` 与现有 retrospective 匹配结果写入 `.local/unity-validation/<module>-g0-draft-latest.json`。该文件只是 G0 增删确认初稿，不代表覆盖通过；启用该合同的新模块完成 G0 时必须校验其来源哈希并把初稿纳入证据。
常用命令：

```powershell
python tools/cocos-audit/Export-CocosCurrentInventory.py --output tools/cocos-audit/generated
./tools/unity-migration/Get-ProtocolEvidence.ps1 -Protocol <Protocol> -Module <Module>
./tools/unity-migration/Invoke-UnityMigrationGate.ps1 -Module <Module> -Gate G0 -StartTiming
./tools/unity-migration/Invoke-UnityMigrationGate.ps1 -Module <Module> -Gate G0
./tools/unity-migration/Invoke-UnityMigrationCocosEvidence.ps1 -Module <Module> -Action RecordTransportPreflight
./tools/unity-migration/Invoke-UnityMigrationCocosEvidence.ps1 -Module <Module> -Action StartFixedClient
./tools/unity-migration/Invoke-UnityMigrationCocosEvidence.ps1 -Module <Module> -Action RecordWindowPreflight -WindowId <ComputerUseWindowId> -RawWidth 1336 -RawHeight 777 -InputReady
./tools/unity-migration/Update-UnityMigrationOperationLedger.ps1 -Module <Module> -Gate G1 -Category CocosAutomation -Tool computer-use@openai-bundled -Operation capture-control -Outcome Passed -TargetId <ControlId> -CapturePath .local/ui-fidelity/<Module>/cocos/<ControlId>.png -Width 1334 -Height 750 -Evidence .local/ui-fidelity/<Module>/cocos/<ControlId>.png
./tools/unity-migration/Invoke-UnityMigrationCocosEvidence.ps1 -Module <Module> -Action FreezeG1Baseline
./tools/unity-migration/Invoke-UnityMigrationGate.ps1 -Module <Module> -Gate G1 -Complete -CocosAutomationLedgerPath .local/unity-validation/<module>-cocos-automation-ledger.json -CocosPreflightPath .local/unity-validation/<module>-cocos-preflight-latest.json -CocosIdentityPath .local/unity-validation/<module>-cocos-identity-latest.json -CocosBaselinePath .local/unity-validation/<module>-cocos-baseline-latest.json -Evidence @('<module-doc>','<ledger>','<preflight>','<identity>','<baseline>')
./tools/unity-migration/Run-UnityModuleValidation.ps1 -Module <Module> -ValidationMode Preflight
./tools/unity-migration/Run-UnityFixedAccountValidation.ps1 -Module <Module> -DataPreflightOnly
./tools/unity-migration/Run-UnityModuleValidation.ps1 -Module <Module> -ValidationMode Context
./tools/unity-migration/Run-UnityFixedAccountValidation.ps1 -Module <Module> -FinalFull
./tools/unity-migration/Run-UnityModuleValidation.ps1 -Module <Module> -ValidationMode Full -FinalFull
./tools/unity-migration/New-UnityModuleG5Evidence.ps1 -Module <Module>
./tools/unity-migration/Test-UnityMigrationDocs.ps1
./tools/unity-migration/Test-UnityMigrationGitScope.ps1 -SummaryOnly
```
动态验收先运行连接诊断和 `Preflight`，随后在已打开Unity的GameView中逐项操作并记录场景、`userId`、`roleId`、`1334×750`、控件ID、操作前后画面及权威结果。Runner仍须为夹具/oracle/诊断写出同等身份和语义信息，但不得据此标记G4/G6通过。断线/重连不再维护C#模块名白名单。Unity编译预检检查退出码和最终日志；恢复型`Assembly-CSharp.dll`共享锁按限次流程处理。G6连续两次`BuildBatch`一致哈希仅是构建完整性检查，禁止用`ForceRebuild`或该哈希代替GameView交互证据。
提速分流：`-ValidationMode Preflight` 不分配账号、不启服务/Unity，先查门禁、注册表、源码锚点和配置漂移；`-ValidationMode VisualReplay` 只复检现存截图的 `1334×750`、最小体积和重复哈希，不能替代新鲜 G5 双端证据。固定账号和 G5 状态对统一登记在 `module-evidence-contracts.json`；夹具必须有注入前快照、`setupAssertSql/cleanupAssertSql` 或等价硬断言、`finally` 恢复及重登录后复核。固定账号模块在 G3 后、启动 Unity 前必须运行 `Run-UnityFixedAccountValidation.ps1 -Module <Module> -DataPreflightOnly`，按 `dataPreflight.requirements` 完成数据快照、确定性准备、硬断言、精确恢复和残留清零；完整验证只接受账号、适配器 SHA 和数据需求指纹匹配的预演凭证。新模块 G1 数据不足时直接 `blocked`，禁止用 Unity 假数据补图或进入 G2。
计时只从启用 `timingPolicyVersion=1` 的后续模块开始，不追补历史：脚手架自动开始 G0，上一门禁通过后自动开始下一门禁；中途接入时用 `Invoke-UnityMigrationGate.ps1 -StartTiming`。`calendarGateTimings` 包含用户反馈等待和阻塞时间，Runner 的 `*-timings-latest.json` / `*-fixed-account-timings-latest.json` 记录机器执行时间；retrospective 分开汇总，二者都不得冒充人时。已有 EnhanceMaster、HeroCultivation、GameplayShops、XunBao 四组样本，G3 收敛循环正式采用影响集回归：纯文档/矩阵改动只跑文档门禁与 Preflight；输入指纹不变的视觉修复只重验受影响控件/状态及 G5；协议、夹具、共享源码或权威数据变化才从最早失效门禁重跑 Full，全部反馈修复收敛后只执行一次计划内最终 Full/G5/G6。

## 13. 高频坑与处理

以下约束来自历史返工，按问题族执行；模块个案只保存在模块文档或自动复盘中。

| 问题族 | 硬门禁 |
|---|---|
| 业务前置条件未锁定 | G3 后、启动 Unity 前执行 `DataPreflightOnly`；夹具 `Setup` 后立即 `AssertSetup`，不满足即停 |
| 把 Full 当调试器 | 默认只跑 `Context/Preflight/目标场景`；差异收敛后才允许一次 `-FinalFull` |
| JSON/Runner 自证通过 | JSON 仅作索引；必须同时有真实 EventSystem/raycast 操作、玩家可见结果和权威数据变化 |
| 相同失败反复重试 | 首次先诊断；同签名第2次先修共享工具；第3次必须补中央工具链回归，未满足时熔断 |
| CUA/MCP/端口故障介入业务判断 | 先预检能力、实例、项目路径和端口；工具不可用只登记阻塞，不得替代业务证据 |
| 历史证据或脏产物复用 | 核对身份、输入指纹、源码 SHA、分辨率、时间戳与逐图 SHA；任一变化从最早受影响门禁重验 |
| Cocos 首次点击失败后坐标试错 | 立即停止，转查 Lua 回调、CSB/CSD、日志与协议；只操作 `ProjectX.exe / Cocos Simulator` |
| 配置/资源闭包后置 | G2 一次核清入口、共享协议、配置到资源、Transform/缩放/锚点；缺口不得靠假数据补齐 |
| PowerShell 命令自身失败 | 使用已解析字面路径；通配符只放 `-g`；先收集 `foreach` 结果再接管道；变量后接冒号用 `${name}` 或格式化字符串 |
| 过早整理证据 | 目标场景通过前只保留原始日志、截图和台账；通过后再生成摘要、差异报告和 G6 包 |

### 13.1 失败台账、自动复盘与迭代

- 标准路径：`.local/unity-validation/<module>-operation-ledger.json`。失败发生即记录，不允许迁移完成后凭记忆补写。
- Windows 下 `rg` 的路径参数必须是已解析的字面目录/文件；文件筛选统一写成 `rg <pattern> <literal-directory> -g '*.ps1'`，禁止把 `*.ps1`、`user.*` 等通配符直接作为路径参数。中央回归 `Assert-UnityMigrationRgPathArgument` 会拒绝此类参数。
- `Failed/Blocked` 必须包含原始错误和根因；根因暂未知时只能写 `pending-diagnosis`，该状态会阻塞 G6。
- 修复后用同一工具追加 `Resolved`，关联失败 `recordId`，并填写解决方式、可复用迭代动作及已存在的文件证据；纯文字说明或事后承诺路径在写账时立即失败。迭代优先进入中央脚本、`validation-scenarios.json`、`AGENTS.md` 和工具链回归测试；模块特例进入矩阵/场景。
- G6 自动生成 `.local/unity-validation/<module>-retrospective-latest.json`，按解决记录的有效根因聚类所有失败及迭代，不再沿用失败初记的 `pending-diagnosis`；任一失败未形成有效诊断、未解决或文件证据缺失时门禁失败。
- 下一模块 G0 先读取上一模块复盘；命中同类根因时直接执行已固化路径，不再重复试错。
- `root-cause-rules.json` 为跨模块可执行规则 ID 的唯一目录；新模块 G0 自动扫描现有 retrospective 并输出命中规则、来源模块和必做动作。新增问题族应先补规则 ID 与中央回归，再依赖自动命中，禁止用模糊相似文本直接阻断门禁。
- 任何已标记完成的模块被用户、运行日志或新证据发现逃逸缺陷时，立即撤销 `migration-complete`，从最早失效门禁重新打开；不得保留“其余G4-G6仍通过”的口头结论，除非输入指纹和独立证据证明不受影响。
- 逃逸缺陷禁止点修即收口：先确定所属问题族并扩展覆盖清单，再扫描全部同类业务ID和分支。例如一个随机盒断链必须扫描全部随机盒，一个 `use_jump` 生命周期错误必须扫描全部跳转道具，一个反馈缺失必须扫描全部产生资源变化的操作。
- 同类修复必须进入中央验证规则、场景或工具链回归；在机器门禁尚未自动执行新规则前，模块只能保持对应门禁 pending，禁止用Markdown声明代替可执行证明。

## 14. 文档维护规则

- `UNITYCLIENT_STATUS.md`只保留当前值、模块状态、最新基线、当前批次、风险和下一步。
- 本文件只保存稳定规则，不追加日期流水和模块结果。
- 每个Manifest模块只对应一份模块文档；共享基础能力可例外共用 FOUNDATION。
- 模块文档建议不超过150行；旧全文和每日记录归档到history。
- JSON矩阵和Manifest是机器事实，不在Markdown复制完整表格。
- 修改路径、状态名或完成口径后，同步更新AGENTS、Manifest、脚本和README，并运行文档门禁。
