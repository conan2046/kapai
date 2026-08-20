# 七日目标（SevenDay）

> 状态：`steam-excluded`。2026-08-20 用户确认 Steam 版本不投放七日目标；Unity入口、路由及后续门禁已屏蔽，不计入迁移分母。Cocos与服务端原逻辑保留，本页以下内容仅作历史审计。

## 范围

- 入口：玩法大厅 `function_id=11`，13 级开启。
- Cocos：`OperationalActivity.SevenDay` → `csd/huodong/QiriLayer.csb`。
- Unity：真实 `huodong/QiriLayer.prefab`，范围冻结为七天页签、四分类、五档累计奖励、任务前往/领取、物品详情、折扣购买、资源栏与返回路径。
- 已完成权威查询/领取、前往边界、物品详情、七天与四分类切换、共享折扣购买和返回闭环。

## 协议

| 方向 | 协议 | 数据 |
|---|---|---|
| C→S | `PRO_TASK_LIST/37 op=4` | 无后续参数 |
| S→C | `PRO_TASK_LIST/37 op=4` | `count:word` + `taskId:word, progress:uint, state:byte` |
| C→S | `PRO_TASK_LIST/37 op=6` | `taskId:word` |
| S→C | `PRO_TASK_LIST/37 op=6` | `PRO_SUCCESS + awards` 或 `PRO_ERROR + reason` |
| C→S/S→C | `MSG_SHOP/221 op=1/2/4` | 折扣分类复用共享商店所有者，`type=10..16` |

服务端权威实现：`CUserMission::GetHDQuestMessage` 与 `GetHDQuestAward`。领取会写入 `ERT_QiRi`，因此正式验证必须使用可逆 Fixture；折扣商店继续由共享 `/221` 所有者处理。

## Unity 实现

- `SevenDayStore` 保存独立七日任务列表，不混入每日任务 Store。
- `SevenDayController.lua.txt` 在通用任务 Controller 前识别 `/37 op=4`。
- `SevenDayPresenter` 必须绑定真实进度区、日/分类控件、任务按钮和折扣商品；业务状态仍由 Lua 与服务端权威决定，C# 只渲染。
- `ProjectXApp.EnterGameplay(11)` 完成大厅进入与关闭/Esc 返回；固定账号 Runner 覆盖真实 `/37 op=4/op=6` 与 `/221 type=10` 购买。

## 2026-08-20 最新提交验收

- 命令：`pwsh -NoProfile -File tools/unity-migration/Run-UnityModuleValidation.ps1 -Module SevenDay`
- 截图：`build/ui-migration/bootstrap-seven-day.png`
- 功能诊断：服务端权威返回当前配置任务；14/14 控件、7 条运行语义、真实领取/重复拒绝/前往/详情/折扣购买和关闭重进通过。
- Fixture 修复：本地长期开服导致 `m_hdQuest` 为空，且旧固定角色注册日超过 7 天；现仅在 `local_test` 可逆 Fixture 中按当前配置补种任务并设置 `GetRegDay()=7`，结束后整行恢复。主账号 `7200057/1000115` 的快照/恢复哈希一致。
- G1 阻塞：本机不存在 `.local/ui-fidelity/SevenDay/cocos/g1/SEVENDAY-LIST.png`、当前 Cocos 自动化台账或冻结基线，不得沿用远端机器未随 Git 交付的 `.local` 结论。
- G5 失败：新鲜 Unity `1334×750` 截图存在黑色调试条遮挡、累计奖励白块/占位、文字与进度区重叠；同时无 Cocos 原图和差异报告。
- Bootstrap：本轮两次 `BootstrapSceneBuilder.BuildBatch` SHA-256 均为 `FA73F3DB609F18F054EE5CDB3699A3BDEED12A607F97EF4638317DC29E01DDA3`，仅证明场景幂等，不能替代视觉通过。
- 控件矩阵：`docs/unityclient/matrices/SEVENDAY_CONTROLS.json`，14 组真实控件（重复节点按同一控件族覆盖）。
- 固定主账号：`7200057/1000115`；隔离账号：`705213/1000006`；分辨率 `1334x750`、Windows 缩放 `100%`。
- 前一模块 `StaminaClaim` 的 `.local` 复盘文件在当前仓库与原工程均不存在，本轮仅记录缺失，不从历史推断结论。
- 当前有效诊断证据：`.local/unity-validation/sevenday-fixed-account-latest.json`、`.local/unity-validation/sevenday-operation-ledger.json`、`.local/unity-validation/bootstrap-idempotence-latest.json`、`build/ui-migration/bootstrap-seven-day.png`。
- 精确恢复入口：从 G1 使用官方 Computer Use 取得 Day1-Day7 与 Day7Full 原生 Cocos 状态，冻结 SHA 后再进入 G2；不得直接复用本轮后置功能诊断作为门禁通过证据。
