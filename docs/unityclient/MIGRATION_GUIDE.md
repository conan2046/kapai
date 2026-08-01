# 《道友来封神》Cocos → Unity 迁移总指南

> 本文件是迁移路线、执行流程、完整标准、视觉标准、工具入口和高频坑的唯一稳定文档。
> 当前进度只看根目录 `UNITYCLIENT_STATUS.md`；模块事实只写入 `docs/unityclient/modules/`；日期流水只写入 `docs/unityclient/history/`。

## 1. 默认读取顺序

1. `AGENTS.md`：项目和运行约束。
2. `UNITYCLIENT_STATUS.md`：唯一实时状态、当前批次、阻塞和下一步。
3. 本文件：唯一稳定流程与完成标准。
4. `docs/unityclient/modules/README.md`：模块索引。
5. 当前目标模块文档和 `matrices/*.json`：调用链、协议、控件和证据。

默认禁止完整读取 `history/`；只有追查旧决策、命令或错误时定点检索。

## 2. 文档与机器状态唯一性

| 信息 | 唯一位置 |
|---|---|
| 实时完成率、当前批次、下一步 | `UNITYCLIENT_STATUS.md` |
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
2. P1 其他单人功能：玩法大厅、封神列传、体力领取、七日目标、法宝搜索、资源找回、游历三界、血战到底。
3. P2 运营与商业化：先完成 `modules/PAYMENT.md` 支付前置，再迁移活动 → 全部基金 → 福利。
4. P3 竞技/玩家依赖：竞技场 → 决战昆仑。
5. P4 社交最后：好友 → 聊天 → 队伍 → 帮派/宗门。
6. 发布收口：热更、性能、Android/Windows、监控、发布门禁。

同一时间只处理一个模块。上一门禁未通过，不得编码、切阶段或启动下一模块；跳过门禁必须先记录阻塞并取得用户明确批准。

进入 P2 的活动、全部基金或福利 G0 前，必须先完成支付前置：测试模式点击充值直接进入服务端权威成功结算，正式模式只走三方 SDK；宏、源码入口、按钮清单和验收条件统一见 `modules/PAYMENT.md`。

## 7. 完整验收单位

验收单位不是“页面”，而是：

`入口 → 页面 → 可操作控件 → 前置状态 → 操作 → 业务结果 → UI反馈 → 持久化/恢复`

每个 Cocos 当前版本可见或可达的按钮、列表项、Tab、槽位、技能图标、关闭区、滑动区、红点和引导热区都必须单独登记。只复制 Prefab、显示数据或让协议返回成功，不算控件完成。

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
| 12 | 自动+人工 | Runner 从真实控件触发且断言通过，人工逐控件通过 |

12/12 才能标记单控件 `complete`。页面完成率必须为在册控件 `100%`，模块完成率必须为全部页面、弹窗、Tab、返回和跨页状态 `100%`。

## 9. G0-G6 唯一执行流程

### G0 范围冻结

冻结模块、入口、页面、弹窗、全部控件、状态、成功/失败分支、测试账号、分辨率、包含项和排除项。生成控件矩阵并写入 `workflowPolicyVersion=1`；用 `acceptanceExamples` 以 `given/when/then` 冻结至少一个具体产品结果，禁止把“分组、汇总、刷新”等歧义拖到 G5；任何 Cocos 可达控件遗漏则后续结果全部无效。

退出条件：范围无歧义；测试账号可复现；矩阵覆盖率100%；机器门禁为 G0 passed。

### G1 Cocos 运行链取证

打印 `入口 → Lua回调 → Utils:OpenFunction/InitUI → View/Controller → CSB/CSD → 动态节点/Timeline/Imod → 协议`。从真实入口取得每个关键状态的 Cocos 截图/视频和日志。迁移操作统一走 `computer-use@openai-bundled`；用户入口可显示为 AdsPower Browser 插件链接，但自动化目标必须唯一匹配原生 `ProjectX.exe / Cocos Simulator`，不得操作 AdsPower 浏览器窗口。每次观察后只执行一个状态派生动作并立即刷新；首次未到达立即记录失败并转源码、日志和协议诊断。

退出条件：所有冻结状态有有效 Cocos 证据；截图窗口、标题、账号、角色、步骤、分辨率和目标节点一致；无猜测链路；G1 门禁已校验 `-CocosAutomationLedgerPath`。

### G2 迁移设计

确认旧 Lua 权威数据、协议/op/字段/错误码、服务端处理、配置和资源、Unity Transform 映射、Lua/C#边界、重连与切号策略。控件矩阵 `sourceAudit` 必须分别关闭入口闭包、共享协议所有权、配置→资源闭包和运行时 Transform 四项检查；源码确实缺失的内容逐项登记 `id/handling/evidence`，不得靠猜路径或临场占位。

退出条件：三方证据齐全；资源类型与播放语义明确；每个控件都有实现与验证设计；`sourceAudit` 机器门禁通过。

### G3 静态实现

接入真实 Prefab、资源、Lua Controller/Legacy Model 和 C# Render Bridge。按矩阵绑定真实控件；排除功能必须隐藏或禁用，不能保留空壳入口。

退出条件：编译通过；无占位资源/伪造数据；静态路径、协议路由、生命周期边界通过检查；场景在 G3 前已登记 `requiredGate=G3`、全控件覆盖、语义断言、源码锚点、全部截图状态和 `1334×750` 视觉断言；变更型模块已有固定账号数据合同。

### G4 逻辑动态验收

验证列表/全量/增量、正常写操作、空态、材料不足、非法/重复、超时/断线、重拉、重连、返回、切号。每项必须由真实控件触发，服务端结果与 UI 刷新一致。G4/G6 运行证据只接受两个标准 Runner 的 Unity `-batchMode` 摘要；Unity MCP 只允许用于 G3 编辑器检查，不得作为动态验收或出证路径。

退出条件：控件功能覆盖100%；成功/失败覆盖100%；权威持久化和清理通过。

### G5 视觉对照

固定同账号、同数据、同步骤、同分辨率和同稳定帧。生成 Cocos/Unity 原图、并排图、50%叠加图、增强差异图和差异报告；逐项核对文字、图片、位置、尺寸、层级、裁剪、动画、点击态和反馈。

截图必须为原生客户区 `1334×750`，Windows 100%缩放，禁止桌面截图或二次放大。`Image`、CSB Timeline、Imod 不可互相替代；`CreateAnimModel + PlayStand` 必须迁真实资源、动作号、循环、缩放和挂点。

Cocos 自动化采用 Computer Use 的原生窗口级观察与输入：每次从最新 `ProjectX.exe / Cocos Simulator` 状态派生一个动作，执行后立即刷新，不复用旧坐标、旧截图 ID 或旧元素索引。常规项目内点击、拖动、滚动和截图已预授权；首次未进入目标页立即记失败并转查 Lua 回调、客户端日志、协议回包。无法到达的页面保留 `pending`，不得用 AdsPower 浏览器页、桌面截图、旧截图或 Unity 单端证据替代。

退出条件：所有状态双端证据齐全；无错误图片、占位文字、截断重叠、公共层遮挡或未解释差异。

### G6 回归与收口

执行真实入口 Runner、人工逐控件、异常扫描、16/16 UI、Bootstrap 两次幂等、文档门禁、Git范围检查和清理验证。Runner 禁止调用内部完成方法。

退出条件：控件矩阵每项 `realEntryClick=true`、`automationPassed=true`、`manualPassed=true`、`status=complete`；工作区无越界变更；模块才可标记 `migration-complete`。

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

`页面 | 控件路径 | 可见条件 | Cocos回调 | 协议/op | Unity绑定 | 成功反馈 | 失败反馈 | 重连结果 | Cocos证据 | Unity证据 | 自动结果 | 人工结果 | 状态`

Runner/文档门禁必须读取矩阵并验证在册覆盖、真实点击、失败分支和人工验收。动态列表按正常、空、锁定、选中、禁用至少各验证一次。

## 12. 工具入口

| 工具 | 用途 |
|---|---|
| `Get-ProtocolEvidence.ps1` | 提取服务端、Cocos、Unity、smoke协议证据 |
| `New-UnityMigrationModule.ps1` | 默认生成规划文档、控件矩阵和 pending 门禁；`-IncludeImplementationSkeleton` 受 G2 前置门禁保护 |
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

工具路由为机器策略，不得临场替换：Cocos 只走 Computer Use 的 `ProjectX.exe / Cocos Simulator` 原生窗口；Unity 逻辑验收走 `Run-UnityModuleValidation.ps1`，固定账号走 `Run-UnityFixedAccountValidation.ps1`；G5 走中央状态对和 `New-UnityModuleG5Evidence.ps1`；G6 走两次 `BuildBatch`。常规 Cocos UI 操作按用户长期授权自动放行，不重复申请；Computer Use 明令要求确认的删除、安装、对外提交等高风险动作不在此授权内。标准工具遇到问题时先形成可复现错误并修工具及测试，禁止换桌面坐标、手工调用内部完成方法、MCP 截图或临时模块脚本绕过门禁。

常用命令：

```powershell
python tools/cocos-audit/Export-CocosCurrentInventory.py --output tools/cocos-audit/generated
./tools/unity-migration/Get-ProtocolEvidence.ps1 -Module <Module>
./tools/unity-migration/Invoke-UnityMigrationGate.ps1 -Module <Module> -Gate G0
./tools/unity-migration/Update-UnityMigrationOperationLedger.ps1 -Module <Module> -Gate G1 -Category CocosAutomation -Tool computer-use@openai-bundled -Operation capture-control -Outcome Passed -TargetId <ControlId> -CapturePath .local/ui-fidelity/<Module>/cocos/<ControlId>.png -Width 1334 -Height 750 -Evidence .local/ui-fidelity/<Module>/cocos/<ControlId>.png
./tools/unity-migration/Invoke-UnityMigrationGate.ps1 -Module <Module> -Gate G1 -Complete -CocosAutomationLedgerPath .local/unity-validation/<module>-cocos-automation-ledger.json -Evidence @('<module-doc>','<ledger>')
./tools/unity-migration/Run-UnityModuleValidation.ps1 -Module <Module> -ValidationMode Preflight
./tools/unity-migration/Run-UnityFixedAccountValidation.ps1 -Module <Module> -DataPreflightOnly
./tools/unity-migration/Run-UnityFixedAccountValidation.ps1 -Module <Module>
./tools/unity-migration/New-UnityModuleG5Evidence.ps1 -Module <Module>
./tools/unity-migration/Test-UnityMigrationDocs.ps1
./tools/unity-migration/Test-UnityMigrationGitScope.ps1 -SummaryOnly
```

动态验证先运行连接诊断和 `Preflight`。Runner 必须写入场景、`userId`、`roleId`、`1334×750`、实际触发控件 ID 和语义断言结果；声明 `controlCoverageRequired` 的场景必须与控件矩阵 ID 集合完全一致。验证器按 30 秒心跳区分总运行超时与无进展超时。G6 只接受连续两次 `BootstrapSceneBuilder.BuildBatch` 的一致哈希，禁止用 `ForceRebuild` 作为幂等证据。

提速分流：`-ValidationMode Preflight` 不分配账号、不启服务/Unity，先查门禁、注册表、源码锚点和配置漂移；`-ValidationMode VisualReplay` 只复检现存截图的 `1334×750`、最小体积和重复哈希，不能替代新鲜 G5 双端证据。固定账号和 G5 状态对统一登记在 `module-evidence-contracts.json`；夹具必须有注入前快照、`setupAssertSql/cleanupAssertSql` 或等价硬断言、`finally` 恢复及重登录后复核。固定账号模块在 G3 后、启动 Unity 前必须运行 `Run-UnityFixedAccountValidation.ps1 -Module <Module> -DataPreflightOnly`，按 `dataPreflight.requirements` 完成数据快照、确定性准备、硬断言、精确恢复和残留清零；完整验证只接受账号、适配器 SHA 和数据需求指纹匹配的预演凭证。新模块 G1 数据不足时直接 `blocked`，禁止用 Unity 假数据补图或进入 G2。

## 13. 高频坑与处理

以下约束来自已完成模块的实际返工，不是建议项：

| 模块 | 已发生的弯路 | 已固化约束 |
|---|---|---|
| Bag | 初始范围遗漏嵌套装备详情分支 | G0 必须从当前入口闭包反查所有嵌套页，矩阵为空或漏页不得继续 |
| Task | 进入动态验证后才发现权威任务列表为空 | 变更型模块 G3 前必须有固定账号合同，Full 前必须通过 `DataPreflightOnly` |
| Hero | Cocos 无有效窗口后尝试旧图、完成标记和 Force Rebuild 证明 | 无当前 Cocos 动态证据保持 pending；G6 只认两次正式 `BuildBatch` |
| HeroEquip | 监听端口存在却没有可用 Unity Editor，反复尝试 MCP | MCP 前先查进程、实例和 editor state；MCP 仅限 G3，G4-G6 只认 batch摘要 |
| Mail | 有/无附件状态及原生滚动、数量缺陷直到后期才分清 | G1 冻结状态对和已批准原生缺陷；Fixture 同时准备正反状态并精确恢复 |
| Shop | 启动 Unity 后才发现账号数据和实际扣款配置不满足 | `dataPreflight.requirements` 必须覆盖账号绑定、货币、商品和真实成本字段 |
| GameplayShops | `VisualOnly` 结果缺截图，随后靠人工合并造成反复 | 只有账号、角色、源码/G5指纹和逐图 SHA 全匹配才允许复用视觉产物 |
| Draw | 可选合同字段、终态切号身份和随机抽取导致假阻塞 | 可选字段统一安全读取；终态身份显式登记；随机业务必须先找确定性服务端条件 |
| World | 猜 `-DryRun`、资产路径和扫荡展示语义；共享 `/320` 被提前消费 | 先查工具参数和源码链；G0 写结果示例；资源缺口只做可证模块兼容；共享协议不匹配必须恢复游标 |

| 问题 | 处理 |
|---|---|
| 扫描到旧游戏 Lua | 只认当前 MainUI 静态闭包和运行入口 |
| AppDef有枚举就认当前功能 | 必须有当前入口、资源和运行证明 |
| 历史截图文件名看似正确 | 核对窗口、标题、账号、角色、步骤、分辨率、节点 |
| 坐标点击失败后继续试错 | 首次失败立即停，转查回调、日志、协议、自动化 |
| Cocos 操作 AdsPower 浏览器窗口或混用多套桌面自动化 | 统一 Computer Use，唯一匹配 `ProjectX.exe / Cocos Simulator`；AdsPower 仅是用户入口标签，不是游戏目标 |

### 6.6 失败台账、自动复盘与迭代

- 标准路径：`.local/unity-validation/<module>-operation-ledger.json`。失败发生即记录，不允许迁移完成后凭记忆补写。
- `Failed/Blocked` 必须包含原始错误和根因；根因暂未知时只能写 `pending-diagnosis`，该状态会阻塞 G6。
- 修复后用同一工具追加 `Resolved`，关联失败 `recordId`，并填写解决方式、可复用迭代动作及证据。迭代优先进入中央脚本、`validation-scenarios.json`、`AGENTS.md` 和工具链回归测试；模块特例进入矩阵/场景。
- G6 自动生成 `.local/unity-validation/<module>-retrospective-latest.json`，按根因聚类所有失败及迭代；任一失败未诊断、未解决或证据缺失时门禁失败。
- 下一模块 G0 先读取上一模块复盘；命中同类根因时直接执行已固化路径，不再重复试错。
| 到 Unity 阶段才发现账号无数据 | G3 前登记固定账号合同；Full 前强制 `-DataPreflightOnly` 凭证 |
| 小改一次就重跑完整闭环 | 先批量收敛视觉差异；Preflight/VisualReplay 分流，最终只跑计划内 Full、G5、G6 |
| Runner直接调用内部方法 | 判定无效，必须从真实 Button/Item/Tab 触发 |
| Unity单端截图通过 | 只能证明可运行，不能算视觉通过 |
| 静态头像替代动态模型 | 使用真实 Imod/Timeline资源和动作语义 |
| C#先改状态再等回包 | 禁止；Lua/服务端权威结果后再渲染 |
| 切号残留旧角色数据 | 清角色Store、Lua模型、pending、监听、UI栈 |
| Runner沿用旧结果 | 运行前删除旧产物并检查本次时间戳 |
| 自动化误删Cocos基准 | 冻结证据不放 Runner outputs 字段 |
| Unity meta批量漂移 | Git scope区分语义/meta/换行噪声，禁止无审计覆盖 |

## 14. 文档维护规则

- `UNITYCLIENT_STATUS.md`只保留当前值、模块状态、最新基线、当前批次、风险和下一步。
- 本文件只保存稳定规则，不追加日期流水和模块结果。
- 每个Manifest模块只对应一份模块文档；共享基础能力可例外共用 FOUNDATION。
- 模块文档建议不超过150行；旧全文和每日记录归档到history。
- JSON矩阵和Manifest是机器事实，不在Markdown复制完整表格。
- 修改路径、状态名或完成口径后，同步更新AGENTS、Manifest、脚本和README，并运行文档门禁。
