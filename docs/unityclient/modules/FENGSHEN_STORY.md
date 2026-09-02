# 封神列传（FengShenStory）

## 当前门禁

- 当前：G0-G3 passed；2026-08-29当前Cocos动态证据、persistentDataPath SQLite数据预检与Unity `BuildBatch`均已重做。等待修复后的早期真人Play复测；反馈闭环前G4-G6保持pending。
- 旧 `logic-validated-visual-pending`、旧截图、旧 Runner、旧 SHA 与 7200025 证据只作线索，不计入本轮门禁。
- 唯一范围：`玩法大厅 → function_id=3 → 封神列传`；World 仅作共享 `/320` 回归面。

## G0 范围冻结

### 入口与界面

`Layer/Main_UI/ButtonGroup1/btn_wanfa` → `Main.WanFaEntranceUI` → `Function_3/EnterBtn` → `Utils:OpenFunction(3)` → `FengShenStory.FengShenStoryMainUI` → `csd/fengshenliezhuan/fengshenliezhuanlLayer.csb` → `/320 op=24`。

关卡弹窗：`FengShenStoryLevelUI` → `csd/fengshenliezhuan/fengshenliezhuanlevel.csb`。当前关显示挑战与布阵；已过关只显示通过；锁定关卡 `userObject=0`，点击只出原生提示。

当前配置有 371 个 `MapType=4` 章节（4001-4371），每章 4 关；主页使用动态横向 TableView、12 个三态关卡模板、两个宝箱按钮和一次非循环 `animation0`。关卡敌人使用 `MonsterBig` Imod、`PlayStand(0)`、挂点缩放 0.8。

### 协议所有权

- `/320 op=24`：服务端返回列传零基章节、当前关、剩余次数；Cocos 将章节 `+1` 后渲染。
- `/320 op=25`：真实挑战；覆盖配置缺失、次数、等级、体力、战斗输赢及成功副作用。
- `/320 op=10`、`op=26`：挑战结果/奖励的服务端推送属于列传闭环；章末 `op25` 成功时服务端已完成发奖，再推送 `op26` 打开奖励确认弹窗。
- `op25`通过前置校验并执行战斗后必须返回`PRO_SUCCESS`确认字节；旧实现只发送`op10/op26`推送，随后把原请求发送成空体`/320`，Unity现保留空包兼容防御，但服务端仍以完整确认包为权威修复。
- G1 源码与原生实测确认：Cocos 的 `op24` 宝箱解析已注释，正常链路不会生成可领红点；`op26` 弹窗的确定按钮仅关闭，不发送列传领奖请求。Unity不得伪造可领态或重复发奖。
- World 独占 `/320 op=1/2/4/5/6/7/8/27` 与其 Store/pending；列传不得抢读、重复发送或清除 World 状态。

### 固定身份与可逆数据

| 用途 | userId | roleId | 要求 |
|---|---:|---:|---|
| 主账号 | 7200057 | 1000003 | SQLite夹具设为99级、第7章末关、次数5；覆盖当前/已过/锁定、章节翻页、体力及挑战边界 |
| 隔离账号 | 705213 | 1000006 | SQLite夹具临时克隆并设为第1章第1关；切号后不得继承主账号 Store/pending，清理后账号与角色均为0 |

Runner 会短暂登录隔离账号完成截图和 Store/pending 断言，随后必须切回主账号；固定账号结果合同的终态身份为 `7200057/1000003`，隔离身份由 `-projectXFengShenStoryIsolationUserId=705213` 与 `fengshen-account-isolation` 语义单独证明。

变更型夹具只允许修改 `Application.persistentDataPath/LocalServer/projectx.db`。当前适配器对整库复制快照，在 `try/finally` 中恢复并重登；恢复后数据库整体 SHA256 相等、临时隔离账号删除、备份文件 residual=0。MySQL不得作为Unity用户测试夹具。

### 控件与状态

- 控件矩阵：`docs/unityclient/matrices/FENGSHEN_STORY_CONTROLS.json`，共 25 个玩家可达/可触控控件。
- 章节视窗宽 `990px`、单元宽 `165px`，每块固定 6 章。用户确认 Unity 左右箭头必须每次翻动一整块（6章），首尾夹紧，翻页后选中章、四关刷新、裁剪和当前章定位保持正确且不发协议。
- 章节列表直接拖拽的手感与惯性细节按用户要求后置统一修复；本模块仍须通过箭头证明章节视窗、裁剪、边界和选章功能闭环。
- G1 原生复核修正：`FirstClassBg.HelpClicked` 未传 `ok/cancel callback`，`MsgBoxUI` 会隐藏确定/取消，仅保留 `MessageBoxLayer/bg/Btn_close`；矩阵 `FENGSHEN-04` 已由错误的确认按钮改为真实关闭按钮。
- G1 奖励图标复核新增：点击首通奖励会真实打开 `Common.ItemSourceUI → csd/common/huoqutujing.csb`；已补冻结关闭、金币图标原生无动作、商城 `function_id=13` 和将魂商店 `function_id=15` 四个边界控件，目标业务页不纳入本模块。由目标页返回时公共框帮助按钮保持隐藏，关闭列传并从玩法大厅重进后恢复，此生命周期边界纳入后续实现。
- 状态覆盖：权威首屏、371章滚动与选章、当前/已过/锁定关卡、宝箱不可领/已开、章末奖励推送确认、帮助、挑战成功/失败、返回重进、客户端重启、断线重连、切号与主账号恢复。
- 排除：完整战斗表现及其他玩法模块；Formation 只作已完成模块的回归面。

## G1-G6

严格按中央门禁推进；每门证据完成后在本文件追加结论。旧 Unity 实现只有 op24、单 Store 和单截图，G3 前必须按本轮矩阵重做，不能当当前证据。

### 2026-08-28 真人Play回归与当前修复

- 用户截图确认两个阻塞缺口：关卡详情的三个首通奖励槽位为空白；公共一级界面顶部缺少体力、金币、元宝货币栏。
- 根因1：Cocos `FengShenStoryLevelUI:ShowInfo()`读取`maplist_dat.first_reward`并调用`Utils:GetItemCellValue`；Unity `WorldVisualCatalog`此前只解析`show_reward`，`FengShenStoryPresenter`只给空槽绑定点击而未渲染奖励。
- 根因2：Cocos `FirstClassBg`由`OneLevelLayer`同时提供`Panel_12/Title`和根级`GoldCheck`；Unity此前只克隆Title，遗漏整个货币Prefab。
- 首轮修复：新增`FirstRewards`权威解析；从`OneLevelLayer/GoldCheck`克隆共享Prefab并绑定`CurrencyStore`实时显示，元宝加号保持原生禁用边界。第二轮真人Play确认货币栏已恢复，但奖励只显示数量，且`tanchuangjiangli`没有道具品质底框。
- 第二轮根因与修复：Cocos实际通过`ItemCellUI`建立`ItemQuality + Icon + ItemNum`复合节点，特殊货币奖励还会强制使用3品质框；Unity首轮仅向导入空槽自身`Image`赋图。现两个奖励入口统一建立`RuntimeFengShenItemCell`复合格，显式加载`common_quality_03`、真实物品图标及数量。
- 第三轮根因与修复：底框与数量已证明复合格生效，但`maplist_dat.first_reward`语义是`{itemId,reserved,amount}`，Unity误将第二列固定0传给`LoadItemIcon`；现改为使用第一列`reward.Type`映射`60000/60001/60014 → 3006/3021/3005`。
- 新增`fengshen-level-first-reward-visible`与`fengshen-first-class-currency-header`运行语义，以及中央源码合同/工具链回归。静态结果：Assembly-CSharp 0错误；模块文档通过；工具链231/231。
- 用户证据：`.local/ui-fidelity/FengShenStory/user-feedback/20260828-reward-header-missing.png`、`20260828-reward-icons-still-missing.png`、`20260828-reward-popup-item-frame-missing.png`、`20260828-reward-frames-visible-icons-missing.png`。2026-08-29标准G3 batch已通过；当前仅保留修复后用户复测门禁。
- 挑战真人Play进一步捕获：成功战斗已收到`op10`结算和`op26`奖励后，服务端又发送`type=320 len=7`空体包，Lua读取首字节触发`Packet body underflow`并把App切到`Failed`。根因是`TiaoZhanLieZhuan`成功路径未向外层请求消息写入`PRO_SUCCESS`。现服务端补齐`op25 + PRO_SUCCESS`，Unity对旧服务端空包做兼容消费；须重启Play使服务端重编译后复测挑战。
- 同轮复测发现挑战完成后旧关卡弹窗仍停留，`op10`已把该关变成已通关态，因此挑战/布阵按规则隐藏，看起来像按钮丢失。Cocos的`OnFightClick`和`OnFormationClick`都会在发送挑战或进入布阵后立即`CloseUI()`；Unity现同步为挑战/布阵后关闭关卡弹窗，返回主图后由玩家点击新“当前”关卡。

### G2 源码审计与设计

- 入口闭包：`function_dat function_id=3/page=1/32级` → `WanFaEntranceUI` → `Utils:OpenFunction(3)` → `FengShenStoryMainUI` → 主 CSB → `/320 op=24`；低级账号停在玩法大厅且不发列传协议。
- 协议闭包：列传只拥有 `/320 op24/op25/op10/op26`；其中 op24/op25 为客户端请求，op10/op26 只由服务端推送。World 的 `/320 op1/2/4/5/6/7/8/27` 保持独占。
- 配置/资源闭包：`bigmap_dat.lua` 中 371 个 `MapType=4` 章节、`maplist_dat.lua` 四关配置、两份 CSB 对应 IR 共 145 节点/35 个唯一资源，缺失导入资源 0。
- Transform 闭包：1334×750；章节视窗 990×126、单元 165×126、每页6章；关卡弹窗 644×422，奖励列表 240×80 且裁剪，敌方挂点缩放0.8并播放 `MonsterBig/PlayStand(0)`。
- 原生差异：左右箭头有节点但无 Lua 回调，按用户批准在 Unity 补足6章整页翻动；直接拖拽手感与惯性继续后置。完整审计：`.local/unity-validation/fengshenstory-g2-source-audit.json`。
- G3 必做：扩展 Store/协议状态机；实现章节页、选章、四关三态、两类弹窗、帮助/奖励/获取途径生命周期、挑战/布阵/重连/切号；重写 Runner 为25控件与4个 acceptanceExamples 的真实点击和语义断言。

### G3 结论（2026-08-04）

- 静态实现完成：Store/Presenter、`/320 op24/op25/op10/op26` Lua 桥、6章箭头分页、关卡/奖励/帮助/获取途径状态、25控件 Runner、固定账号证据合同与13个截图状态；运行器已移除批量补记，宝箱、关卡、奖励图标、来源图标/路由及弹窗关闭均调用实际绑定 Button。
- `dotnet build Assembly-CSharp.csproj`：0 error；中央文档 29/29；工具链 88/88。
- 用户恢复许可证后，团结引擎 `2022.3.62f3c1` 的 `BootstrapSceneBuilder.BuildBatch` 成功解析 entitlement、打开 `Bootstrap.unity`，场景语义签名未变化并安全跳过重建，编译错误/异常/真正崩溃均为0，返回码0。证据：`.local/unity-validation/fengshenstory-g3-buildbatch-after-license.log`。
- 先前3次许可证失败保留在操作账本，并以本次同一标准批处理成功证据逐条标记 Resolved；G3 门禁通过，进入 G4 固定账号批处理验证。

### G3 当前重验（2026-08-29）

- 当前Cocos固定身份 `7200057/1000115` 实际重取主页、关卡详情和首通奖励获取途径原生 `1334×750` 证据；首通奖励确认三格真实图标、品质框、数量与来源弹窗，顶部公共栏确认体力 `100/100`、金币 `100万`、元宝 `999999`。
- Unity固定账号合同已迁为 `Application.persistentDataPath/LocalServer/projectx.db` 的 `7200057/1000003`，完整通过 Setup、AssertSetup、Restore、AssertRestored、Cleanup、AssertCleanup、重登哈希一致与隔离账号零残留。证据：`.local/unity-validation/fengshenstory-fixed-account-data-preflight-latest.json`。
- 静态合同复核发现模块Runner仍硬编码旧MySQL角色`1000115`；现已同步为SQLite合同`7200057/1000003`，并在中央工具链增加源码绑定断言，防止合同与运行时再次漂移。
- 团结引擎 `2022.3.62f3c1` 在该修复后重新执行 `BootstrapSceneBuilder.BuildBatch`，场景语义签名未变化，C#编译错误0，batch return code 0。最终证据：`.local/unity-validation/fengshenstory-g3-buildbatch-final-20260829.log`。
- 中央工具回归 `260/260`；操作账本所有本轮失败均已登记根因、解决方案和文件证据。G3通过，G4严格等待修复后的早期真人Play，不继承2026-08-04旧G4-G6。

### G4-G6 结论（2026-08-04）

- 固定主账号 `7200057/1000115`、隔离账号 `705213/1000006` 完成真实 `/320 op24/op25/op10/op26`、25/25 控件、10/10 语义、断线重连、返回重进、切号隔离和章末奖励推送；终态恢复主账号。
- 主/隔离夹具恢复 SHA256 分别为 `bd12c4e8d2c5bcf7d9bc2213dcadd5181500912778f049681d3b03569d96e7bf`、`9e8abe9c9623389f4b0a5cd0ce446af33e2a3ee2867e8dfd6bfe87c3d282672c`，Fixture residual=0。
- G5 共12组原生 `1334×750` 对照；修复白色头像占位、临时弹窗、敌方模型、初始第2-7章视窗、奖励/来源图标，接入 WorldVisualCatalog、MonsterBust/Imod 及真实 MessageBox/huoqutujing/tanchuangjiangli Prefab。
- G6 生成25张逐控件 Unity 原生帧并与25张唯一 Cocos 证据绑定；严重错误0、占位0、重复证据路径0。两次真实 `BootstrapSceneBuilder.BuildBatch` SHA256 均为 `FA73F3DB609F18F054EE5CDB3699A3BDEED12A607F97EF4638317DC29E01DDA3`。
- 自动复盘 `102/102` 失败均已诊断、解决并具备可验证迭代证据，未解决0。权威证据：`.local/unity-validation/fengshenstory-fixed-account-latest.json`、`.local/ui-fidelity/FengShenStory/compare/g5-20260804/report.json`、`.local/unity-validation/fengshenstory-retrospective-latest.json`。

### 历史 G1 进度（范围变更后不得直接继承）

- 2026-08-04 当前范围 G1 已重新通过：矩阵 25/25 均有 Computer Use 原生证据，账本共 35 个唯一目标。新采 `FENGSHEN-05-CHAPTER-VIEWPORT`、`FENGSHEN-07-LEFT-PAGE`、`FENGSHEN-08-RIGHT-PAGE`，确认 LaterChapter 下原生显示第2-7章且左右箭头点击无回调；该差异作为 Unity 经用户批准补足6章整块翻页的源证据。
- G3 静态验证固定数据使用 `LaterEndChapter`：`chapterIndex=6/nodeId=40074/count=5/petLevel=100`。该单一真实状态同时覆盖第7章末关、1-3关已过/4关当前、前章已开宝箱、1↔7六章翻页，以及挑战成功后的 op10/op26；运行器禁止批量补记未实际操作控件。
- 本轮夹具恢复 SHA256 为 `bd12c4e8d2c5bcf7d9bc2213dcadd5181500912778f049681d3b03569d96e7bf`，Fixture residual=0；ProjectX/kapai/mysqld/Unity 与 Computer Use 运行时残留均为0。G1门禁登记7项证据并通过。

- 新任务已恢复 `computer-use@openai-bundled`，本轮只操作原生 `ProjectX.exe / Cocos Simulator`。25 个矩阵控件中 24 个已有逐控件、唯一目标、`1334×750` 原生截图；共享截图批量登记失败已改为逐项登记并解决。
- 已覆盖：玩法入口/公共框关闭与帮助生命周期、章节单元、左右装饰无动作、四关三态、宝箱不可领/已开、关卡弹窗遮罩/关闭、挑战/布阵/奖励列表、奖励来源弹窗及商城/将魂商店路由、章末挑战成功与 `op26` 奖励确认。
- 动态状态已覆盖：次数为 0 的原生提示、重启、退出重进、断线/重连、隔离账号、切回主账号、1级账号入口锁定。低级账号使用 `Start-Client.ps1 -LocalUserId 7200260` 与临时 `local_preserve_level_user_id=7200260`；证据完成后配置已恢复为 `0`。
- 主账号 `7200057/1000115` 与低级账号 `7200260/1000119` 均已执行 Restore → AssertRestored → Cleanup → AssertCleanup；恢复 SHA256 分别为 `bd12c4e8d2c5bcf7d9bc2213dcadd5181500912778f049681d3b03569d96e7bf`、`20b6110094f9032f4d76dd1670c270b84472e68e5033584427cfb63eeebadf95`，Fixture residual=0。工作区 `ProjectX/kapai/mysqld` 已关闭。
- 旧唯一阻塞 `FENGSHEN-05-CHAPTER-SCROLL` 已因用户范围调整失效：直接拖拽手感后置，原生左右箭头无回调只作为 Cocos 差异证据；Unity 新范围由 `FENGSHEN-05-CHAPTER-VIEWPORT`、`FENGSHEN-07-LEFT-PAGE`、`FENGSHEN-08-RIGHT-PAGE` 承担箭头整块翻页闭环。
- 工具链回归：`Test-UnityMigrationToolchain.ps1` 86/86；新增低级锁定身份、等级断言、同状态安全重应用，以及 `Invoke-ClientWindow.ps1` 绑定输入线程、精确前台校验和失败闭合回归。
- 原始证据：`.local/unity-validation/fengshenstory-operation-ledger.json`、`.local/unity-validation/fengshenstory-cocos-automation-ledger.json`、`.local/ui-fidelity/FengShenStory/cocos/g1-20260802/`。旧 Blocked 记录 `8018984aa1414552ac59a7bf49db0bc5` 必须按本次范围变更补充诊断、解决和新迭代证据；重新完成 G0/G1 前不得进入 G2。

## Steam SQLite S5（2026-08-20）

- 证据：`.local/unity-validation/steam-sqlite-s5-fengshenstory-latest.json`，状态`Passed`；SQLite数据库保留为`steam-sqlite-s5-fengshenstory-v3.db`。
- SQLite/MySQL均从新隔离角色执行真实`/320 op24→op25`，服务端战斗后主动推送`op10`并再次用`op24`回读；双方各4个case、56个响应，初态`mapIndex=0/node=40011/count=5`一致推进到`node=40012/count=4/star=3`，金币10000、通宝200、材料100、角色经验2400四项奖励一致。
- 双端正常退出并重启后各20个响应，`op24`仍为`40012/4次`。`guan_qia/pet/package/mission/save_data`长度和SHA-256逐字节一致，角色金币1010000、经验2400、等级60一致；`user_spirit`当前体力80及其余负载一致，仅恢复时间戳因双端串行运行相差约43秒而规范化排除。
- 新角色初始阵容无法赢得真实列传战斗；本轮在既有`local_test`验收钩子区新增`PRO_INTERACT op58`，只把隔离角色已有神将升至100级，正式配置不可达，战斗、扣体力、推进、奖励和保存仍全部走生产`/320 op25`路径。
- 服务端编译通过，中央工具链`135/135`、文档`29/29`；只删除隔离库`fxl_game_fengshenstory_s5_v1`。正式`fxl_game_local`和MySQL源码、驱动、构建、Schema、脚本、回归全部保留。S5下一模块为`Arena`。
