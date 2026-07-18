# 玩法大厅（Gameplay）迁移证据

## 1. 当前范围

- 当前主界面入口：`Layer/Main_UI/btn_wanfa`。该按钮在当前 `UImainLayer_new` 中直接位于 `Main_UI` 下，不是旧注释暗示的 `ButtonGroup3/btn_wanfa`。
- 当前回调：`MainUI.WanFaCallback → Utils:OpenFunction(AppDef.EModuleID.EMID_WANFA, nil, true)`。
- 当前 View：`Main.WanFaEntranceUI`，详情页为 `Main.WanFaInfoUI`。
- 当前资源：`csd/common/ActivityLayer.csb` 与 `csd/TaskPopupLayer.csb`。
- 当前协议：大厅本身不请求列表协议；竞技场、血战、法宝搜索三个红点查询共用 `PRO_Func_HotPoint / 65`。
- 第一阶段边界：真实入口、13 个当前配置项、双列滚动、等级锁、详情、进入按钮、三类服务端红点与真实未迁移路由边界。

旧 `/209 + ActivityLayer` 是仓库另一代“玩法”活动页，既不是当前 `btn_wanfa` 调用链，也不是当前活动系统，继续判废且不计完成率。

## 2. 当前调用链

```text
UImainLayer_new/Layer/Main_UI/btn_wanfa
→ MainUI.WanFaCallback
→ Utils:OpenFunction(EMID_WANFA=270, nil, true)
→ AppDef.FuncUI[270] = Main.WanFaEntranceUI
→ cc.CSLoader:createNode("csd/common/ActivityLayer.csb")
→ WanFaEntranceUI:initData
→ LDataConstMgr:GetFunctionLevelMap()
→ function_dat.lua：id < 999 且 page != 0
→ Panel/ActivityBg/ActivityList 双列生成 13 个入口
```

详情与进入链：

```text
玩法卡片点击
→ WanFaInfoUI.new(functionId)
→ cc.CSLoader:createNode("csd/TaskPopupLayer.csb")
→ WanFaInfoUI:updateData
→ 当前错误读取未填充的 LDataConstMgr.m_pFunctionLevelMap[functionId]
→ data == nil 提前返回，保留 TaskPopupLayer 默认占位字段
→ Btn_Enter
→ Utils:OpenFunction(functionId)
→ 对应独立子系统 View
```

红点链：

```text
WanFaEntranceUI:UpdateRedDot
→ ArenaTask(101) / XueZhanDraw(51) / XunBaoTask(103)
→ SendHotPointMsg(1, type)
→ /65：op=1 + type:u16
→ CPackageDeal::FuncHotPointOption
→ SendHotPointStatus
→ op + type:u16 + state:u8
→ LuaNetRecvdMsg.DealFuncHotPoint
→ WanFaEntranceUI 对应卡片红点更新
```

## 3. 当前配置与子页面

数据源是当前客户端生成配置 `client/ProjectX/src/ConfigData/function_dat.lua`。服务端源 JSON 在本检出中保留原始非 UTF-8 编码，Unity 快照以当前可运行客户端 Lua 的实际值为准。

| id | 名称 | page | 开放等级 | 当前路由/归属 |
|---:|---|---:|---:|---|
| 1 | 游历三界 | 1 | 26 | `WanFa.YouLiMainUI` |
| 3 | 封神列传 | 1 | 32 | `FengShenStory.FengShenStoryMainUI` |
| 6 | 竞技场 | 1 | 10 | `WanFa.KaPaiArenaUI`；红点 type=101 |
| 7 | 决战昆仑 | 1 | 34 | `JueZhanKunLun.KunLunJueZhanUI`；本地计算红点 |
| 8 | 血战到底 | 1 | 24 | `XueZhan.XueZhanMainUI`；红点 type=51 |
| 9 | 法宝搜索 | 1 | 15 | `WanFa.XunBaoMainUI`；红点 type=103 |
| 10 | 每日任务 | 1 | 13 | `Activity.TaskLayer`；Unity 已有 Task 路由 |
| 11 | 七日目标 | 1 | 13 | `OperationalActivity.SevenDay` |
| 12 | 好友赠送 | 1 | 14 | 好友赠送独立页面 |
| 18 | 体力领取 | 3 | 1 | 福利活动子页 |
| 19 | 资源找回 | 3 | 20 | 福利活动子页 |
| 25 | 成长基金 | 3 | 1 | 福利活动子页 |
| 26 | 活跃基金 | 3 | 1 | 福利活动子页 |

配置中前五项描述仍含当前客户端已有的占位式文本，其余为空；Unity 忠实显示当前数据，不自行编写业务文案。

## 4. `/65` 协议字段

### 4.1 请求

| 字段 | 宽度 | 当前值 |
|---|---:|---|
| cmd | u16 | 65 |
| op | u8 | 1 |
| type | u16 | 101 / 51 / 103 |

### 4.2 响应

| 字段 | 宽度 | 说明 |
|---|---:|---|
| op | u8 | 生产 `SendHotPointStatus` 通常写 2；本地降级回显请求 op=1 |
| type | u16 | 红点类型 |
| state | u8 | 0 隐藏，非 0 显示 |

当前客户端解析器兼容 op=1 与 op=2。字段顺序和宽度来自 `pack_deal.cpp` 写包与当前 Lua 读包的双向核对，不按旧截图推断。

## 5. 服务端分支

- `protocol.h`：`PRO_Func_HotPoint = 65`。
- `pack_deal.cpp` 注册：`PRO_Func_HotPoint → CPackageDeal::FuncHotPointOption`。
- type=101：进入竞技场任务红点子系统。
- type=51：检查血战可领奖状态。
- type=103：进入法宝搜索任务红点子系统。
- 支持类型成功时通过 `SendHotPointStatus` 返回 `op=2 + type:u16 + state:u8`。
- 未支持 type、子系统缺失、部分数据库/配置失败分支可能直接返回，不保证回包；Unity 保留真实超时/空态，禁止伪造成功。
- 收到请求 op=2 时服务端分支为空。
- `local_test=1` 因最小库不具备完整红点业务表，明确返回 `op=1 + 原 type + state=0`；这是权威隐藏态，不是 Unity 假数据。

## 6. CSB、Timeline 与 Imod

| 用途 | 当前完整路径 | 当前调用 |
|---|---|---|
| 玩法大厅 | `csd/common/ActivityLayer.csb` | `createNode`；无当前 `createTimeline` 调用 |
| 玩法详情 | `csd/TaskPopupLayer.csb` | `createNode`；无当前 `createTimeline` 调用 |
| 入口图标 | `res2/Icon/ui_main_icon/*.png` | `function_dat.lua` 配置驱动，11 个当前实际贴图 |

两个页面当前调用链均没有 Imod ANI。所有路径来自 Lua 非注释调用点和配置完整相对路径，未按 basename 判断版本。

## 7. Unity 实现与当前 Cocos 对齐

- `GameplayCatalog` 从 `Resources/Configs/gameplay.json` 加载当前 13 条配置快照。
- `GameplayStore` 保存三个权威红点状态和当前选择项；切号时清理。
- `Shared/HotPointController` 独占 `/65` 消息游标，并同时分发 Task 与 Gameplay，避免两个控制器重复读取同一包。
- `GameplayController` 发起 101、51、103 查询并处理打开、详情、返回与进入流程。
- `BootstrapSceneBuilder` 按当前 Lua 栈将 `shop/shop_bg.prefab` 作为框架，`common/ActivityLayer.prefab` 与 `TaskPopupLayer.prefab` 作为其子层；未触碰用户已有 `OneLevelLayer.prefab` 修改。
- `GameplayPresenter` 复用原框架、列表行、卡片、按钮、图标、字体、详情 NPC/面板；不再生成棕色替代面板或系统字体按钮。
- Cocos `ListView` 首行按 130 高度顶对齐、行距 2；Unity 使用相同几何，双列卡片中心与 Cocos `254.364/705.564` 对齐。
- 卡片 CSD 初始 `TouchEnabled=false` 会让 Unity `Selectable` 使用 Disabled 色块；运行时统一卡片 ColorBlock 为白色、零渐变，保持 Cocos 原图亮度和点击语义。
- 详情右侧信息组修正导入布局的 16px 水平偏移，描述与玩法名称按 Cocos 左对齐。
- 当前 Cocos 详情数据源存在实际缺陷并显示 Prefab 默认占位内容；Unity 同步保留该可见行为，不擅自显示 `gameplay.json` 文案。
- 13 个入口全部显示；等级使用当前角色权威等级判断。
- 第一阶段只有 id=10 接到已迁移的 Task 页面。其他入口明确提示其子系统尚未迁移，不跳到错误旧页面，也不声称子玩法完成。

## 8. 动态验证

命令：

```powershell
pwsh -File tools/unity-migration/Run-UnityModuleValidation.ps1 -Module Gameplay
```

最终证据：

- `userId=7200039`；此前视觉迭代账号未复用为最终证据。
- 结果：`.local/unity-validation/gameplay-latest.json`，`success=true`；结果 UTC `2026-07-18T07:25:18.2818144Z`，脚本检查 UTC `2026-07-18T07:25:20.5817141Z`。
- `/65` SEND/RECV 各 3 次；日志明确解析 `type=101/51/103`，三者 `state=0`，符合本地服权威隐藏态。
- COMPLETE 仅由 Gameplay 最终状态写入：当前 `btn_wanfa → WanFaEntranceUI → 13 项列表/等级锁/详情 → /65 三类红点 → 未迁移子页边界`。
- 截图：`build/ui-migration/bootstrap-gameplay-list.png`、`build/ui-migration/bootstrap-gameplay.png`，均为 `1334×750`。
- Bootstrap 连续两次 SHA-256：`62995484C85CB3E7585D883608C455322A023C54E96A28EDF2AC660DC3779D09`；第二次输出 `semantic signature unchanged`。
- 严重异常扫描：`error CS\d+ / LuaException / NullReferenceException / MissingReferenceException / Assertion failed / Fatal Error / Crash!!! = 0`。
- 本模块 Manifest 为 `mutatesServer=true`，Runner 使用隔离用户且不自动重试；finally 已关闭本批 Unity、`kapai.exe` 与 workspace-local MySQL。

## 9. 视觉 1:1 记录

- 状态：`visual-fixing`；Cocos 基准、Unity 对照、流程、节点映射和差异报告已建立，但仍有未通过项。
- 流程：`.local/ui-fidelity/Gameplay/flow.md`。
- 节点映射：`.local/ui-fidelity/Gameplay/ui-map.json`。
- Cocos 列表：`.local/ui-fidelity/Gameplay/cocos/list.png`，`1334×750`，SHA-256 `11662B04E28B0079692EC7CE550F60A23B9EA4824B1803769AD82CD64039562C`。
- Cocos 详情：`.local/ui-fidelity/Gameplay/cocos/detail-valid.png`，`1334×750`，SHA-256 `7058945FE95587F7B27AD23D6F488C8EDF35AE6C63833D741B662AB999808AC3`。
- Unity 列表：`.local/ui-fidelity/Gameplay/unity/list.png`，SHA-256 `CE18A88C7966BCAA08EF4413368CB137C732D815DB54B9097A56AD9A2FA0BC64`。
- Unity 详情：`.local/ui-fidelity/Gameplay/unity/detail.png`，SHA-256 `421D28525490408E87FA3BC372B49848A1F5FAE820DF50C53F7313274BC6D92C`。
- 差异工具：`python tools/unity-migration/compare_ui_fidelity.py`；阈值为单通道最大差 `>8`。
- 列表全屏差异率 `12.077761%`、模块 ROI `10.139951%`；详情全屏 `10.701549%`、模块 ROI `11.253109%`。
- 已对齐：框架、标题、关闭、列表裁剪、首行/行距、双列卡片、图标、按钮、字体资源、详情 NPC/底板/选择按钮、Cocos 当前占位字段。
- 未通过：Cocos 全局竹叶/扇子装饰与滚动公告未进入 Unity 公共层；Unity/Cocos 字体和纹理采样的抗锯齿边缘仍有差异；锁定、红点显示、有效滚动到底三态尚无完整成对截图。
- 结论：不得标记 `visual-1to1-complete`。

## 10. 未完成边界

- Gameplay 主体 UI 已完成本轮结构修复，但上述公共层和状态截图未收口，仍为 `visual-fixing`。
- 游历三界、封神列传、竞技场已完成首屏逻辑闭环但视觉 1:1 未完成；决战昆仑、血战到底、法宝搜索尚未迁移。
- 七日目标、好友赠送、体力领取、资源找回、成长基金、活跃基金需按各自当前调用链继续迁移。
- 本地最小库只能动态证明 `/65` 三类隐藏态；生产 `op=2` 红点显示态和无回包分支尚无独立动态证据。
- Cocos 详情占位内容来自 `WanFaInfoUI` 读取错误数据源，不是 Unity 配置缺失；本阶段只复刻当前可见行为，不擅自修改 Cocos 业务逻辑。
