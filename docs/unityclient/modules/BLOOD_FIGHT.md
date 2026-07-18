# 血战到底（BloodFight）

## 当前边界

- 入口：玩法大厅 `function_id=8`。
- Cocos：`XueZhan.XueZhanMainUI`、`csd/xuezhan/XuezhanMain.csb`。
- Unity：真实预制体 `Assets/ProjectX/res/csd/Prefabs/xuezhan/XuezhanMain.prefab`。
- 协议：`MSG_BLOOD_FIGHT/323`，只读查询 `op=1`。

## 已迁移

- 从玩法大厅进入、返回玩法大厅。
- 真实血战背景、今日战绩、开始区域、排行榜框架、商店/排行入口布局。
- 解析剩余次数、复活次数、状态、章节、关卡、今日最高关、历史/今日/当前星数，以及 Buff、属性和宝箱尾段以保证包游标完整。
- 开始、战斗、扫荡、复活、领奖、商店和排行榜保持禁用，不修改服务端状态。

## 延后项

- 排行榜 `/排行协议 type=22`、奖励预览和血战商店。
- `effect_xuezhan_1` 动态表现、章节战斗、Buff 选择、扫荡和结算。
- 字体、按钮细节与动画由后续人工 UI 调整收口。

## 验证

```powershell
pwsh -File tools/unity-migration/Run-UnityModuleValidation.ps1 -Module BloodFight
```

门禁要求：真实 `/323 op=1` 回包、权威状态显示、截图生成、返回玩法大厅、严重日志 0。

2026-07-18 已通过：`userId=1`，本地权威空状态为 `chapter=1, level=0, remaining=0`；16/16 UI 迁移测试通过，截图 `build/ui-migration/bootstrap-blood-fight.png`。本地血战计数配置链缺失时仅 `local_test=1` 返回完整空状态包，线上分支不变。
