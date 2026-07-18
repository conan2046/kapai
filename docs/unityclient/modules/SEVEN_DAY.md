# 七日目标（SevenDay）

## 范围

- 入口：玩法大厅 `function_id=11`，13 级开启。
- Cocos：`OperationalActivity.SevenDay` → `csd/huodong/QiriLayer.csb`。
- Unity：真实 `huodong/QiriLayer.prefab`，保留七天页签、分类、进度奖励、任务列表与返回路径。
- 首期只接查询；领取、前往、折扣购买等变更操作禁用。

## 协议

| 方向 | 协议 | 数据 |
|---|---|---|
| C→S | `PRO_TASK_LIST/37 op=4` | 无后续参数 |
| S→C | `PRO_TASK_LIST/37 op=4` | `count:word` + `taskId:word, progress:uint, state:byte` |

服务端权威实现：`CUserMission::GetHDQuestMessage`。查询不修改服务端数据。

## Unity 实现

- `SevenDayStore` 保存独立七日任务列表，不混入每日任务 Store。
- `SevenDayController.lua.txt` 在通用任务 Controller 前识别 `/37 op=4`。
- `SevenDayPresenter` 绑定真实进度区，渲染首批权威任务记录并禁用变更按钮。
- `ProjectXApp.EnterGameplay(11)` 完成大厅进入与关闭/Esc 返回。

## 验证

- 命令：`pwsh -NoProfile -File tools/unity-migration/Run-UnityModuleValidation.ps1 -Module SevenDay`
- 截图：`build/ui-migration/bootstrap-seven-day.png`
- 结果：服务端权威返回 130 条七日任务；真实左右主布局、七天/分类页签、进度区、任务列表和关闭/Esc 返回通过。
- 自动化：16/16 Python 测试通过，严重异常 0；状态为 `logic-validated-visual-pending`。
- 已知边界：奖励图标、任务文案和具体目标值后续按 `sevendays.json` 深化；领取、购买仍禁用。
