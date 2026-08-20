# 七日目标（SevenDay）

> 状态：2026-08-20 G0-G6 passed / 14/14 complete；旧版只读列表结果仅作历史参考。

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

## 验证

- 命令：`pwsh -NoProfile -File tools/unity-migration/Run-UnityModuleValidation.ps1 -Module SevenDay`
- 截图：`build/ui-migration/bootstrap-seven-day.png`
- 结果：服务端权威返回 130 条七日任务；14/14 控件、6/6 语义断言、真实领取/重复拒绝/前往/详情/折扣购买和关闭重进通过。
- 固定账号验证：主账号 `7200057/1000115`，DataPreflight、可逆 Fixture、精确恢复、重登录哈希和残留清零通过。
- G5：Cocos/Unity 原生 `1334x750` 状态对与差异报告位于 `.local/ui-fidelity/SevenDay/compare/g5/report.json`。
- G6：两次 `BootstrapSceneBuilder.BuildBatch` SHA-256 均为 `48F42BDE8CB04EEB6532C850F0221EB802C4FAF85829B0847DF2EA74FA8DD6F0`；自动复盘 16/16 已解决。
- 控件矩阵：`docs/unityclient/matrices/SEVENDAY_CONTROLS.json`，14 组真实控件（重复节点按同一控件族覆盖）。
- 固定主账号：`7200057/1000115`；隔离账号：`705213/1000006`；分辨率 `1334x750`、Windows 缩放 `100%`。
- 前一模块 `StaminaClaim` 的 `.local` 复盘文件在当前仓库与原工程均不存在，本轮仅记录缺失，不从历史推断结论。
- 证据：`.local/unity-validation/sevenday-fixed-account-latest.json`、`.local/unity-validation/sevenday-retrospective-latest.json`、`.local/unity-validation/bootstrap-idempotence-latest.json`。
