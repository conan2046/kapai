# 野外碰怪战斗模块

> 状态：G1 已证明当前 Cocos 正式 UI 不可达，分类为遗留服务端 fightType，不计入当前 Cocos 用户可达战斗迁移分母；这不是战斗通过，也不得复用 World/EFT_GuanQia 截图或战报。

## 范围

- 唯一fightType：`server/src/fight.h::EFTMeetMonster=1`。服务端仍保留普通场景移动接触非Boss可见野怪的触发代码。
- 原G0假设包含真实场景移动、`/184`野怪移除/重生、`/21-/23`完整战斗、FightLayer速度/跳过、胜负后返回原场景及经验/金钱/任务击杀状态；当前G1已否定“正式客户端存在真实场景移动入口”这一前提。
- 排除Boss、活动、捉鬼、玩家PK和其他fightType分流；每种后续单独门禁。
- 固定身份`7200057/1000003`；所有Unity夹具仅可修改persistentDataPath SQLite并精确恢复。

## 三方证据

- 协议：/10、/11、/21、/22、/23、/63、/184。
- 服务端入口：`CScene::MeetEnemy`命中普通怪后`SetFightType(EFTMeetMonster)`；`CFight::OtherTypeUserFightEnd`处理奖励、击杀和失败状态。
- 当前客户端入口审计：`MainUI:WanFaCallback -> EMID_WANFA -> Main.WanFaEntranceUI`的全部动态条目不含世界地图/野外遇怪；`MainUI`无活动地图按钮，`m_pMapBtn`只剩注释。
- `WorldMapMainUI`唯一创建引用位于`MainChatUI`的开发字符串命令`openUI`，不属于正式用户流程；禁止用该调试命令、直接服务端调用或内部方法伪造G1。
- 共享战斗接收链仍存在：`LuaNetRecvdMsg.RecvServerEnterBattle -> LGameLogic:LuaEnterBattleScene -> LBattleLogic`；但没有当前正式入口产生`/184`或fightType=1的`/21-/23`。

## 实现边界

- `BattleMeetMonsterController.lua`：协议、场景进入和权威状态。
- `BattleMeetMonsterViewState`：Lua → C# 的只读渲染 DTO。
- `BattleMeetMonsterRenderBridge`：仅绑定场景、FightLayer、资源、动画和交互回调。
- 禁止新建业务型 C# Store/Catalog 或在 Bridge 解析协议。

## G1 当前证据与结论

- 固定身份`7200057/1000003`由当前worktree SQLite服务端登录成功，服务端绑定`sceneId=2 x=454 y=344`。
- Computer Use在唯一原生`ProjectX.exe / Cocos Simulator`窗口以原生`1334×750`真实点击任务、返回、玩法并拖到底部；任务与玩法全量可见入口均无世界地图或野外遇怪。
- 当前服务端日志没有`/184`、`/21`、`/22`、`/23`碰怪链；源码入口闭包同样只找到开发命令。
- 证据：`.local/unity-validation/battlemeetmonster-cocos-entry-audit-20260830.json`、`.local/ui-fidelity/BattleMeetMonster/cocos/g1/`、`.local/unity-validation/battlemeetmonster-cocos-automation-ledger.json`。
- 夹具已按`AssertSetup -> Restore -> AssertRestored -> AssertReloginHash -> Cleanup -> AssertCleanup`完成；数据库恢复SHA-256=`7445FEEC27B2BED88164FFBD9CEF426B3559E58AFB6F51A357258AF51701E669`，残留0，进程残留0。
- 门禁结论：`G1 passed=false`；`G1 excluded=true`。它不算已验收，也不要求Unity为当前Cocos不存在的正式流程补入口。

## 冻结项

- 原G0 `acceptanceExamples`与4项控件/状态仍保留于`BATTLEMEETMONSTER_CONTROLS.json`作为被当前证据推翻的审计记录，不把`realEntryClick`改成假通过。
- G1 Cocos 自动化账本与当前入口审计已生成。
- 当前不进入G2/G3；若未来Cocos恢复正式地图/移动入口，必须从G0重新冻结并重取全部当前证据。

## 遗留

- 服务端遗留代码与资源保留，不删除、不改线上路径。
- 战斗总清单保留59个源码枚举；当前用户可达分母为World已验证1类、BattleMeetMonster排除1类、其余57类待逐项证明可达性并按门禁验收。
