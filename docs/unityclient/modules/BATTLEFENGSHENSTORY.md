# 封神列传战斗表现 模块

> 状态：2026-09-01已完成G0-G6；用户确认本轮神将朝向修复，标准batch、两次BuildBatch、9控件硬门禁与自动复盘全部通过。

## V0 边界复核

- 当前 `7200057/1000115` 已从正常登录真实点击“玩法→封神列传→当前关→挑战”，两轮均进入列传战斗；服务端分别发送 `/38` 1832/1755 bytes 与 `/320` 8-byte op25应答。第二轮真实点击跳过后即时及1.6秒后均为列传地图，没有稳定结算。
- 用户于2026-08-31确认的无结算行为只覆盖主动跳过。2026-09-01早测确认自然结束直接返回属于缺陷，不能把跳过合同扩展到完整播放。
- 共同机器证据：`.local/unity-validation/cocos-current-version-boundary-v0-latest.json`。
- 本轮动态证据：`.local/unity-validation/v0-battlefengshenstory-runtime-latest.json`；数据库两次精确恢复、重登与零残留：`.local/unity-validation/v0-battlefengshenstory-cleanup-latest.json`。

## 范围

- 唯一战斗类型：`server/src/fight.h::EFTLieZhuanFight=19`。
- 入口：玩法`Function_3` → `FengShenStoryMainUI` → 当前关卡`Btn_Confirm` → `/320 op25` → `CUserGuanQia::TiaoZhanLieZhuan`。
- 包含`/38 op5`内嵌的`/21-/23`共享战斗、`SetFightChooseMode`手动进入、FightLayer速度/跳过、自然完整播放后的`op10/op26`结算栈，以及主动跳过后的父地图直返。`op25`只属于发起挑战的`/320`，不是`/38`回放操作号。
- 分流合同：自然结束显示结算、统计、回放、结算关闭和返回奖励；主动跳过不显示这些结果界面，迟到`op10/op26`也不得重开结果栈。
- 父级列传列表、关卡、宝箱、帮助、布阵页面本身仍归`FengShenStory`，本模块不重做其UI。

## 三方证据

- 协议：`/320 op25`发起挑战；服务端`CFight::GetFightAllNetMsg(EFPT_PlayBack_2)`统一返回`/38 op5`，其内嵌`/21`、`/22`、`/23`，由`/21 fightType=19`确认列传所有权。
- 服务端：`CPackageDeal::DealGuanQia op25 -> CUserGuanQia::TiaoZhanLieZhuan -> BeginFastFight -> EFTLieZhuanFight`；成功另推`op10/op26`。
- 客户端：`FengShenStoryLevelUI.OnFightClick -> QueryFengShenStory(25)`；`/21 -> LBattleLogic.RecvEnterBattle`；`/23 -> FirstFightResultUI`，列传结算隐藏星级并保留统计/回放/全屏关闭。
- 当前源已确认`SetFightChooseMode()`令`m_IsAutoMode=0`，自动按钮再通过`/22 ACT_AUTOFIGHT`切换。
- 真实回包：已确认固定`7200057/1000003`、`fightType=19`、10单位、5动作组；固定 SQLite `storedSpirit=100/lastSpiritTime=0`、`Hope=20`，首个360秒自然恢复 tick 前回程为`80/100`。旧`82/100`由分段取证停留超过12分钟后两次自然恢复造成，已作为捕获时长残留失效。

## 实现边界

- `BattleFengShenStoryController.lua`：协议、业务规则和权威状态。
- `BattleFengShenStoryViewState`：Lua → C# 的只读渲染 DTO。
- `BattleFengShenStoryRenderBridge`：仅绑定 Prefab、资源、动画和交互回调。
- 禁止新建业务型 C# Store/Catalog 或在 Bridge 解析协议。

## 新 G3（passed，2026-08-31）

- 固定 Unity SQLite 身份 `7200057/1000003`；先执行 `-DataPreflightOnly`，再以 `-G3RuntimeOnly` 完成一次标准 batch，未启用 Unity MCP。
- 真实 EventSystem 当前分母 `9/9`：挑战、速度、隐藏自动断言、跳过、统计、统计关闭、回放、结算关闭、返回奖励确认。权威战报为`fightType=19`、10单位。
- 自然结束进入权威结算；主动跳过后播放层隐藏并重拉`/320 op24`，父列传地图可见且结算、统计、回放、奖励弹窗均未显示。关卡标识已修正为仅一个“当前”，已通关关亮显、未来关灰显。
- G3运行图为 `BFS-BATTLE-START/STAND/SPEED/RETURN.png`；它们只证明可运行初版，不冒充 G5 视觉通过。
- DataPreflight 的 Setup/Assert/Restore/Cleanup 全通过，快照 SHA-256=`7445feec27b2bed88164ffbd9cef426b3559e58afb6f51a357258af51701e669`；重登稳定哈希和零残留通过。
- 编译预检 SHA-256=`797810447012EA803DA113A65C1E80C8C1E295DCC691156898536E7B4B648C1D`；中央工具回归 `289/289`。
- 当前证据：`.local/unity-validation/battlefengshenstory-g3-runtime-latest.json`、`.local/unity-validation/battlefengshenstory-fixed-account-runner-latest.json`、`.local/unity-validation/battlefengshenstory-fixed-account-data-preflight-latest.json`、`.local/unity-validation/battlefengshenstory-fixed-account-timings-latest.json`。

## G4-G5（passed，2026-09-01）

- G4固定账号重新执行通过：9/9真实控件、自然结算与主动跳过分流、重登稳定哈希、SQLite精确恢复、Cleanup与零残留均通过。
- G5使用当前Cocos冻结基线与Unity SQLite `7200057/1000003`完成10/10同尺寸状态对比；自然返回奖励和主动跳过返回使用独立截图，禁止互相覆盖。
- 自然返回显示`神魂200/突破丹100`宝箱奖励；神魂保留协议品质4，但按当前Cocos特殊货币格规则显示蓝框。结算暗幕、胜利徽记、货币/经验区与统计页布局已批量收敛。
- 最新指标：结算MAE `17.7058`、统计MAE `19.7098`、返回MAE `23.5630`；动态战斗帧仅保留动作相位、字体栅格化与色彩空间差异，无错误资源、文字截断、层级遮挡或生命周期错位。
- 证据：`.local/ui-fidelity/BattleFengShenStory/compare/g5/report.json`、`.local/ui-fidelity/BattleFengShenStory/compare/g5/contact-side-1.jpg`、`.local/ui-fidelity/BattleFengShenStory/compare/g5/contact-side-2.jpg`、`.local/ui-fidelity/BattleFengShenStory/compare/g5/G5_VISUAL_ACCEPTANCE.md`。

## 历史验证（当前失效，仅作线索）

- G0：8个真实控件、19个业务ID、2个源码分母已冻结。
- G1：唯一原生 ProjectX/Computer Use 当前10态已重建并冻结；固定身份、1334×750、同一40074战报、回程80、奖励和零残留闭合。
- G2：当前源码、协议、资源、动作、Transform及体力`SubSpirit/CheckAddSpirit -> DealTili/TiliChanged/FirstClassBg`链已复核通过；G5输入合同加入四个体力计时/显示源文件。
- G3：固定账号 batch 已按新 G1 重跑，真实 EventSystem `9/9`、`fightType=19`、10单位、5动作组通过；DataPreflight、编译、重登哈希、精确恢复、Cleanup 与零残留均通过。
- 首轮用户早测在真实入口发现底部章节卷轴无响应：导入的`reel`根节点没有`Graphic`，子图又全部`raycastTarget=false`，而旧Runner通过`onClick.Invoke()`绕过了射线缺失。现已给每个运行时章节格补透明点击面，并将父模块及本战斗入口改为真实`GraphicRaycaster`点击`第6章→第7章`。
- 第二轮用户早测发现结算返回并关闭奖励后仍露出旧战场：`zhandoujiesuanLayer`已隐藏、封神主界面及`/320 op=24`已刷新，但同级`WorldBattlePlaybackPresenter`未退出。现已在列传结算继续生命周期中先隐藏播放层，再刷新父界面并展示延迟奖励；Runner新增“返回后/奖励确认后播放层均不可见”断言。修复后固定账号G3、9/9真实EventSystem控件、289项工具回归、BuildBatch严重错误0、重登哈希和零残留均通过，等待用户复测。
- 当前结算已按 Cocos 修正：CSB 第35帧启动胜利 Imod、0.7秒单次播放后隐藏；列传强制`win2/胜利`；金币、元宝、神魂进入四格货币栏，不再误入物品奖励；统计页左右485px底色不再重叠；返回奖励数量按`ItemCellUI tostring(num)`显示`200/100`，不再带 Unity 独有的乘号前缀。
- 翻转站位后的阵法归属已与`LBattleLogic.m_bIsFlipPos`对齐，5v5满阵只保留10个占用底圈，不再额外显示空位幽灵圈。结算阶段继续保留已完成的战场角色、血条和速度/跳过HUD，使用导入的`zhandoujiesuanLayer`背景与位于其下方的全屏暗幕，不再换成无角色的干净背景。
- 2026-08-31用户早测指出我方朝向及右下角按钮需复核。本轮按`BattleUnitNode.lua`修正左右动作组：敌方/左侧使用 action 0，我方/右侧使用 action 1 并水平翻转；同时禁止父节点首次激活时把手动 action 1 重置为默认 action 0。当前固定战报10个模型方向断言通过。
- 加速按钮已拆分“显示倍率”和“播放因子”：Cocos显示`1/2/3/5/10/15`，实际因子为`1/2/3/3.5/4/4.5`；真实点击会即时同步模型、品质与技能特效，回放保持选择，非自动验证运行按角色保存。跳过允许态继续真实点击进入结算；拒绝态不伪造结束并显示Cocos原文`精英、BOSS关无法跳过！`。
- 当前40074战报结算包仅含`60052主角经验=3960`，不含`60006神将经验`，因此界面继续只显示主角经验。`60006`仅保留条件业务分支：真实收到时读取`/24 HeroStore`中`FightPosition>0`的最多5名已上阵神将及其当前等级、经验、经验上限；权威神将数据缺失时拒绝合成展示，绝不为当前战斗造数据。
- 上述修复后重新完成DataPreflight、G3固定账号真实EventSystem`9/9`、重登稳定哈希、精确恢复、Cleanup、零残留、289项中央工具回归及最终BuildBatch严重错误0；仍停在G3等待用户复测，不进入G4。
- 旧G3十态差异结论已由当前G5报告取代；历史截图与旧MAE仅作修复前对照。

## 冻结项

- G0 `acceptanceExamples`：正常完整链与前置/断线失败边界已冻结。
- G1 Cocos 自动化账本：`.local/unity-validation/battlefengshenstory-cocos-automation-ledger.json`，10/10；基线`.local/unity-validation/battlefengshenstory-cocos-baseline-latest.json`。
- G2 sourceAudit：`.local/unity-validation/battlefengshenstory-g2-source-audit-current.json`，当前复核通过。
- G3 batch：以本文件“新 G3”段和 latest 证据为准；旧十态汇总与结算差异矩阵已失效。

## 遗留

- 本模块G6已完成：本轮最终Play已由用户确认；241/241失败均有唯一解决记录，4条过期证据已补充，待诊断0、未解决0。
