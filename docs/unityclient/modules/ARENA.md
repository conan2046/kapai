# 竞技场 PVP 战斗模块

> 状态：2026-08-31 用户确认当前版本已屏蔽；不进入当前 Unity 迁移与战斗表现验收分母。

## 范围

- 遗留战斗类型：`server/src/fight.h::EFTJingJiChang=44`。
- 遗留链路：玩法入口 `function_id=6` → `WanFa.KaPaiArenaUI` → 对手布阵 → `/161 op5` → `BeginFastFight`。
- 当前 `server/config/json/function.json` 中竞技场记录为 `function_id=6, show=0`；用户进一步确认当前版本竞技场已屏蔽。
- 本轮不继续 G1 动态取证、不设计 SQLite 竞技场夹具、不启动 Cocos/Unity、不修改 Unity 竞技场或共享战斗播放器。

## 三方证据

- 协议遗留：`/161` 竞技场状态和挑战，`/38` 回放包，内嵌 `/21-/23` 共享战斗。
- 服务端遗留：`CPackageDeal::ArenaOption op5`、`ArenaSaveData`、`EFTJingJiChang=44`。
- Cocos 遗留：`KaPaiArenaUI.OnFightClick`、`QueryArenaChallenge(5,...)`、共享 `LBattleLogic`。
- 当前范围证据：`server/config/json/function.json` 与用户在本任务中明确“竞技场不也屏蔽了么”。

## 实现边界

- 不创建或扩展竞技场固定账号夹具。
- 不新增当前产品不可达的竞技场入口。
- 不把旧 Unity 截图、历史 Runner 或 Steam SQLite 逻辑当作当前通过证据。
- 保留现有遗留源码，不删除线上路径。

## 验证

- 结论：当前版本屏蔽并由用户排除，不属于功能或视觉通过。
- G1-G6 未运行；历史结论仍失效。

## 冻结项

- G0 仅记录当前屏蔽状态、遗留源码链和用户范围决定。
- 未来若恢复竞技场，必须从 G0 重启并重新取得当前 Cocos 动态证据。

## 遗留

- 自动生成的协议草稿、场景和注册项仅作审计，不代表模块已实现或通过。
