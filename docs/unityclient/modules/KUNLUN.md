# 决战昆仑（KunLun）

## 当前边界

- 入口：玩法大厅 `function_id=7`。
- Cocos：`JueZhanKunLun.KunLunJueZhanUI`、`csd/kunlun/juezhankunlun.csb`。
- Unity：真实导入预制体 `Assets/ProjectX/res/csd/Prefabs/kunlun/juezhankunlun.prefab`。
- 协议：`MSG_CHUANG_GUAN/213`，只读查询 `op=25`。

## 已迁移

- 从玩法大厅进入、返回玩法大厅。
- 昆仑背景、道路、9 个敌方节点、层数和挑战次数的真实布局。
- 解析服务端层数、剩余挑战、剩余购买、当前位置、敌方名称/等级/战力/状态/剩余血量。
- 战斗、连闯、购买次数、商店、宝箱按钮保持禁用，避免验收修改服务端状态。

## 延后项

- Cocos `ModelAniNode` 对应的玩家/敌方动态模型。
- 道路逐段点亮、角色移动、战斗与连闯表现。
- 字体、模型站位、按钮细节由后续人工 UI 调整收口。

## 验证

```powershell
pwsh -File tools/unity-migration/Run-UnityModuleValidation.ps1 -Module KunLun
```

通过门禁：真实 `/213 op=25` 回包完成、UI 栈为决战昆仑、权威状态已显示、截图生成、返回键回到玩法大厅、严重日志为 0。

2026-07-18 已通过：`userId=1`，服务端返回 `floor=1, enemies=0, remaining=12`；16/16 UI 迁移测试通过，截图 `build/ui-migration/bootstrap-kunlun.png`。本地无独立匹配服时，服务端仅在 `local_test=1` 返回权威空匹配状态，线上匹配链不变。
