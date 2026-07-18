# 封神列传（FengShenStory）

## 当前真实链路

`Layer/Main_UI/btn_wanfa` → `Main.WanFaEntranceUI` → `function_id=3` → `Utils:OpenFunction(3)` → `FengShenStory.FengShenStoryMainUI` → `CreateUINode("csd/fengshenliezhuan/fengshenliezhuanlLayer.csb")` → `QueryFengShenStory(24)` → `/320 op=24`。

关卡弹窗：`FengShenStoryLevelUI` → `cc.CSLoader:createNode("csd/fengshenliezhuan/fengshenliezhuanlevel.csb")`；挑战按钮写 `/320 op=25`。

## 协议闭环

- `protocol.h`: `MSG_GUANQIA=320`；`pack_deal.cpp`: 注册 `GuanQiaOption`。
- `op=24`：成功返回 `chapterId:u32 + levelId:u32 + remaining:u8`；Unity 以服务端值覆盖 Store 并刷新独立 Presenter。
- `op=25`：配置缺失、次数不足、等级不足、体力不足返回失败字符串；成功进入战斗并可能产生 `/320 op=10` 战斗结果与 `op=26` 宝箱奖励。本模块动态门禁为只读 `op=24`，不触发消耗/战斗。
- 开放检查失败或服务端提前返回属于失败/不回包边界，Runner 超时即失败，禁止将本地默认值当成功态。

## Unity 实现与门禁

- Store：`FengShenStoryStore`；Lua：`Gameplay/FengShenStoryController.lua.txt`。
- 独立 UI：`FengShenStoryPresenter`，绑定 `fengshenliezhuan/fengshenliezhuanlLayer`；关卡 Prefab 同批纳入 Bootstrap。
- 门禁：`Run-UnityModuleValidation.ps1 -Module FengShenStory`；截图 `build/ui-migration/bootstrap-fengshen-story.png`。

## 动态证据

- 最终隔离账号 `userId=7200025`、角色 `roleId=1000039`；UTC `2026-07-18T06:08:52.6991788Z`。
- `SEND /320 request=5`；`RECV /320 request=5 elapsed=0.145s`；权威态 `chapter=0, level=40011, remaining=5`。
- Unity 单端截图 `build/ui-migration/bootstrap-fengshen-story.png`，`1334×750`；只证明运行态可见，不构成 Cocos 1:1 证据。
- Python UI 门禁 `16/16`；Runner 严重异常扫描为 `0`；Unity、kapai、workspace MySQL 和端口 `8711/3306` 已清理。
- 账号 1 的历史角色曾返回 MSVC 未初始化标记 `0xCDCDCDCD`，该次证据作废；最终使用 Manifest 的隔离创角路径验证初始列传状态，未修改正式服务端语义。
- Bootstrap 连续两次构建 SHA256 均为 `B8491B8EBC761AB6619E4FEC5C8AC463CA19E686C6F7FA9589AD1060BF054E43`，语义幂等通过。

## 视觉 1:1 记录

- 状态：`pending-cocos-baseline`；功能/协议已通过，视觉完成结论撤销。
- Cocos 脚本与 UI：已锁定 `FengShenStoryMainUI`、`FengShenStoryLevelUI`、主页/关卡弹窗 CSB；下一轮补精确行号、动态节点、贴图/字体/动画清单。
- 操作步骤：待记录 `btn_wanfa → 封神列传 → 首屏 → 关卡弹窗 → 返回` 的同数据流程。
- 缺失证据：Cocos 同状态截图、节点映射、状态矩阵、叠加/差异图和动画/交互对照。
- 当前 Unity 截图不得用于标记 `visual-1to1-complete`。
