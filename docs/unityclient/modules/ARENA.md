# 竞技场（Arena）

## 当前真实链路

`btn_wanfa` → `Main.WanFaEntranceUI` → `function_id=6` → `WanFa.KaPaiArenaUI` → `cc.CSLoader:createNode("csd/common/JingjiLayer.csb")` → `QueryArenaInfo(1)` → `/161 op=0,type=1`。界面同时请求 `/161 op=3` 战报；首屏核心状态以 `op=0` 闭环。

## 协议与边界

- `LuaNetCmd.MSG_ARENA=161`；`protocol.h MSG_ARENA=161`；`pack_deal.cpp` 注册 `ArenaOption`。
- 成功：`op:u8,type:u8,success:u8,opponentCount:u8`，每名对手按真人/机器人分支读取，末尾为 `rank:u32, remaining:u16, challenged:u16, bought:u8, score:u32`。
- 失败：数据库不可用、榜单为空等走 `PRO_ERROR + string`；类型非法或初次入榜失败可提前返回/不回包。Unity 显式失败，Runner 超时判失败。
- 挑战 `op=5`、扫荡 `op=6`、购买次数 `op=15` 会改变状态，本阶段不触发。

## Unity 与门禁

独立 `ArenaStore`、`Gameplay/ArenaController.lua.txt`、`ArenaPresenter`；绑定完整相对路径 `common/JingjiLayer`。Manifest 使用隔离创角，避免污染既有竞技榜状态。门禁：`Run-UnityModuleValidation.ps1 -Module Arena`。

## 动态证据

- 逻辑 Runner 已通过：`userId=7200026`，UTC `2026-07-18T06:13:02.1480785Z`。
- `/161 op=0` 权威态：`rank=10000, opponents=16, remaining=20`；严重异常扫描为 0。
- Unity 单端截图：`build/ui-migration/bootstrap-arena.png`，`1334×750`；只证明运行态可见，不构成 Cocos 1:1 证据。
- 统一脚本已关闭本轮 `kapai` 与 workspace MySQL。

## 视觉 1:1 记录

- 状态：`pending-cocos-baseline`；只能记 `logic-validated-visual-pending`。
- Cocos 脚本与 UI：已锁定 `KaPaiArenaUI → common/JingjiLayer.csb → /161`；下一轮补精确行号、`op=3` 战报时序、动态对手节点和资源清单。
- 操作步骤：待记录 `btn_wanfa → 竞技场 → 首屏榜单/次数 → 战报 → 返回` 的同账号同数据流程。
- 缺失证据：Cocos 同状态截图、节点/字体/坐标/列表行映射、叠加/差异图、交互与动画对照。
- 当前 Unity 截图不得用于标记 `visual-1to1-complete`。
