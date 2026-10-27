# 前期体验与投放总表续接（2026-10-26）

## 发布与新聊天续接：2026-10-27
- 用户已授权整理10月26～27日改动、提交并推送远端，然后创建新聊天继续P0。本次承接10月26日本地main提交`e37ecb26`及本次Boss包/原节点结算修复；旧段落的“未提交/未推送”是当时状态，当前以Git日志及origin/main核验为准。
- 两日最终行为、验证、配置/存档影响和已知限制见[两日变更与P0续接](history/2026-10-27-early-experience-release.md)。发布仅包含明确清单；其他资源/Excel/Prefab等脏文件保留。bigmap仅暂存H列，原A3/I3/J3表头措辞不随本次提交。
- **下一项P0为P04：初始资源与首战资格**。先只读核对正式新档入口、初始货币/道具/体力、出生神将57、首战条件和首笔收益；核对首关无元宝与旧教学1元宝需求缺口，不擅自补资源。高等级Slot09通过不等于新档体验已验收。
- P04之后再到P05主线任务数据与持久化；P02继续后置。未确认新数值不改表、不自动启动新档Play或改原存档，不重开迁移门禁。V0.2中早期状态文字可能落后，P03当前以本交接的实际重复到账与原节点结果为准，不重复跑已完成验证。
- 正式微调对象仍为World/zhandoujiesuanLayer.prefab；货币和主角经验显示按最新要求隐藏，奖励到账不变。等级99裁切、独立开箱表现及预览标题/空白按钮未完成，不能将当前源代码发布视为最终画面/Steam发行包验收。

## 最新原节点检查点：2026-10-27 itemlayer / shenjianglayer
- 用户明确继续使用正式`Assets/Prefabs/World/zhandoujiesuanLayer.prefab`，不切换到当前打开的`Retained/common`同名文件。Retained已有用户7处布局/显隐差异，本轮未改。用户最新要求隐藏货币与主角经验；覆盖下文曾经“道具+货币合并”的方案，奖励到账与服务端、正式数据不变。
- WorldOutcomePresenter不再构建RuntimeBattleReward神将/道具区域，改为绑定原`Panel/firPanel/shenjianglayer/IconColor1..5`的Icon、Text（等级）、Quality（评分）、StarsList、LoadingBar_2、Text_jiangN；道具在原`itemlayer/itemList`内复用`baseItem`模板。原ChapterRewardList停用、huobilayer与zhujueayer默认隐藏；未删除这些节点。
- 保留159个原节点的RectTransform、字体、字号、对齐与颜色签名，前后快照一致；未移动层级容器、未更改已有尺寸/位置/字体。仅给空itemList补Content+单行Grid、baseItem补品质Image/数量字段、原StarsList补Prefab布局组件。数量文本复用既有等级Text样式，新增字段可以在Prefab微调。
- 品质评分按原A/S/SS/SSS/SSSS Sprite绑定，引用放在WorldOutcomeBindings组件的heroQualityRatings数组，使用现有Art/UI/ui_shenjiang资产，不用bag_level底框冒充评分标识；未复制美术。实际Boss截图已核对普通品质A与品质7的SSS，五位神将真实等级、星级、经验+150及进度比例匹配HeroStore，道具一件/两件显示真实名称、数量和图标；独立货币/主角经验隐藏，RuntimeBattleReward节点0，Console错误0。
- 仍有视觉待微调项：原等级Text宽25、字号22、换行设置会让99只显示一部分；实际text=99。按用户“不改已有布局显示，字体位置、字号等”的明确要求保留，微调位置为`shenjianglayer/IconColorN/Text`，不能误报最终画面完全通过。原生两层的现有位置/上下顺序同样保留，未继续套用前一轮运行时两排摆位。
- 编译时误删IsCocosMoneyReward辅助函数、首次品质图片用了bag_level底框，均已修正并保留失败证据/既有World operation-ledger；Unity新增序列化字段的空白检查仅清理本轮新增块，不清理旧Prefab内容。证据`.local/boss-chest-20261027/native-templates/verification.json`、`result.png`、`styles-before.txt`、`styles-after.txt`、`cleanup.json`，首次错误品质画面另存before-quality-fix.png/json。
- 本批一次Setup、复用同一隔离Slot09完成修复前后两次Play，没有重复Setup。54份原存档及前三批归档哈希保持，Slot09归档到`Saves/Trash/native-templates-20261027-Slot09`；偏好恢复、Play和本轮服务端退出，Editor/MCP=true保留。未提交、未推送。

## 最新修复检查点：2026-10-27 第一排奖励被遮罩压暗
- 用户反馈第一排奖励看起来半透明。Prefab中图标、品质框、名称、数量的Alpha均为1、无父CanvasGroup衰减；根因为`EnsureBattleBackdrop`将运行时WorldBattleBackdrop放到ChapterRewardList之后，其SettlementWash(alpha0.58)覆盖了奖励列表，而同Backdrop里后生成的神将经验没有被覆盖。
- 仅调整运行时背景初始化的兄弟层级：WorldBattleBackdrop插入到已有ChapterRewardList之前，保留背景遮罩；未改图标Alpha、Prefab布局、字号或尺寸。实际Boss胜利画面验证：奖励Graphic深度202～213，高于遮罩160；12个可见Graphic的color.a和CanvasRenderer Alpha均为1，两排间距仍24.25像素，Console错误0。
- 用户微调入口为`Assets/Prefabs/World/zhandoujiesuanLayer.prefab`：第一排ChapterRewardList/Content（排列与间距）、Content/Item（格子模板）、Item/QualityFrame/Icon、Item/Name、Item/Amount。第二排神将经验仍由WorldOutcomePresenter运行时生成，Prefab没有对应可微调模板；未在本次遮罩修复中扩展为模板迁移。
- 证据`.local/boss-chest-20261027/opacity/result.png`、`result.json`、`verification.json`、`cleanup.json`。新UI批次一次Setup，51份受保护文件（原存档及前两批归档）保持哈希；仅本批隔离Slot09战斗变化，归档到`Saves/Trash/opacity-20261027-Slot09`。恢复偏好、Play停止、本轮服务端8711退出；保留Editor/MCP=true，未提交、未推送。

## 最新布局检查点：2026-10-27 奖励合并为第一排
- 用户最新要求覆盖下文“道具放在神将经验下方”的临时方案：龙崖Boss结算第一排为道具+货币的统一奖励区域，第二排为神将经验。
- `WorldOutcomePresenter.RenderBattleRewards`在龙崖模式不再生成独立Money行，汇总后的道具在前、货币在后，交给同一ChapterRewardList渲染；货币沿用正式图标、名称、数量和公共品质框。奖励结算、正式数据、服务端不变；普通模式和扫荡布局未改。
- `zhandoujiesuanLayer.prefab`维护统一奖励行锚点y0.60～0.77、单行Grid及横向ScrollRect/ContentSizeFitter，溢出横向滚动；神将头像、经验增量与进度条保持第二排。布局没有改成运行时代码摆位。
- 已经真实入口完成第一章Boss结算：接引道人神魂10、金币1000、元宝1000同排；五位神将经验+150位于下一排；两排间距24.25像素、独立Money节点0、图标缺失0、编译及Console错误0。证据`.local/boss-chest-20261027/merged-row/result.png`、`result.json`，最终恢复证据`cleanup.json`与`verification.json`。
- 本批UI测试一次Setup，从上批归档复制隔离Slot09，仅该隔离槽产生战斗变化；48份受保护文件包含原43份存档和上批归档5份文件。完成后只归档本批Slot09到`Saves/Trash/merged-row-20261027-Slot09`，恢复两项偏好、停止本轮Play/服务端；保留Editor和MCP启用。未提交、未推送。

## 最新实测检查点：2026-10-27 Boss重复到账与结算布局
- 用户要求进入Play实测开箱、重复到账，并明确要求处理结算物品与神将经验区重叠。本轮通过已核验E盘Unity MCP/PID71884，复用一次Setup的隔离Slot09；没有提交、推送或改正式奖励数值。
- 实际完成两轮完整六关及两次直接重打Boss，共14场、4次Boss胜利。2402接引道人神魂依次10→20→30→40→50，元宝1011449→1012449→1013449→1014449→1015449，每次Boss均加1000元宝、10碎片；旧星箱fixState均已领取，仍不阻止新Boss包到账。保存SQLite、两次重登核对通过，不是新档胜率验收。
- 正式`zhandoujiesuanLayer.prefab`仅改ChapterRewardList的纵向锚点至0.23～0.40，物品列表位于神将经验区下方，未移动神将或改运行时代码布局。真实一件/两件物品结算截图通过，区域间距25.25像素；`DadituuiLayer.prefab`仅将Box3纵向偏移0→150，修复被Reward_4遮挡，实际Raycast点击打开预览；Box1/2及龙崖星数仍隐藏。保留用户其他Prefab编辑。
- 边界：当前每次Boss奖由服务端自动到账，获奖界面仍为普通胜利结算，没有独立开箱动画，不能标记完整开箱表现通过。奖励预览仍有通用标题“宝箱奖励”和既有ButtonOwn空白底按钮；内容1000元宝、10碎片及关闭X入口可用，预览不发奖励，后续表现完善时处理。
- 最终Console错误0。临时只读观察器曾在结算层尚未懒加载时捕获null而报错，已移除并保留证据；隔离存档归档脚本首次因自身SQLite连接未关闭而失败，显式关闭后重试，不重复Setup。均写入既有World operation-ledger，不改迁移门禁。
- 本轮证据：`.local/boss-chest-20261027/play/verification.json`、`cleanup.json`、`relogin-final.json`、`result-layout-fixed.png`、`result-repeat-layout-fixed.png`、`boss-preview-fixed.png`。隔离Slot09归档到`Saves/Trash/boss-chest-20261027-Slot09`，43份原存档哈希不变、两项PlayerPrefs恢复；Play停止、本轮服务端及8711监听退出，Editor/MCP保留，`unityMCP.enabled=true`。

## 最新检查点：2026-10-27 龙崖每轮Boss宝箱
- 用户已确认：不是首次通关奖励；每次击败本章最后一个Boss都自动开一个宝箱。每章只保留原最后一个奖励包，去掉星数条件，正式表直接填包ID。
- 本轮已修改`unitydata/excel/bigmap.xlsx / bigmap`的H列：`star_reward`替换为整数`boss_reward`，引用`reward_fixed.xlsx`的ID。127个主线章节各保留原最后一档，未合并前两档、未改奖励包内容；515条章节的其他单元格及工作簿其他23个XML部件保留。第一章1001为20013：1000元宝、2402碎片10，每次Boss胜利发一次。
- WorldRewards正式导出组统一接入bigmap、reward_fixed及两端JSON/DAT，通用旧转换器不再处理这两张表。每个主线章节必须恰好一个最终Boss且奖励包有效；非法输入先拒绝、不写输出。服务端不再根据旧星数或星箱fixState发箱；普通关、精英关、战败和非龙崖模式均不发Boss包，旧op4星箱领取也不恢复。存档格式保持兼容。
- 当前Unity Lua/C#同步解析op2尾部的Boss包ID；只复用最后一个Box3预览，前两箱及龙崖星数进度隐藏，奖励弹窗提示每次Boss胜利自动开箱，预览不发领取请求。龙崖结算不显示星星；Prefab/.meta/布局未修改。
- 已验证：9项隔离导出回归；正式两端导出及ValidateOnly一致性；原生服务端构建；当前1735行奖励、2780关运行配置解析；127章最终Boss奖励包及重复获胜规则检查；Unity编译、新Bridge方法加载、Lua语法、资源导入及Console错误0。未启动Play、未改玩家存档、未重打Steam发行包；实际开箱画面与连续重复到账仍待定向Play，不能用10月26日旧星箱结果代替。
- V0.2原文件已回写P03及相关来源、预算事实，V0.1保留；P06旧两箱英雄来源撤下，P10不能再沿用首关1000元宝。首关现为1000金币、100神将经验、无元宝；第一章每轮六关基础6000金币，Boss包1000元宝；旧351金币+1元宝教学顺序存在1元宝缺口，下一项P04继续核对，P02保持后置。
- 本轮未提交、未推送；原有范围外资源、Prefab及其他表格修改保留。项目`.codex/config.toml`的unityMCP保持`enabled=true`，不要在收尾改回false。当前已核验实例unityclient@412d45435dc1aa1a、PID71884、Application.dataPath为E盘目标；不能仅凭ALL_TOOLS列表缺少Unity工具就判断服务不可用。
- 本轮证据集中在`.local/boss-chest-20261027/`：`verification.json`、`export-tests-v2.log`、`native-verify-v2.log`、`unity-check.json`及`diff-check-scoped.log`。最初迁移器空单元格处理和测试RapidJSON接口错误均已修复，保留失败日志；全量diff检查中的原有资源/Prefab尾随空白不属于本轮，未清理。

下文为10月26日历史收口，涉及星级箱的验收口径不再代表10月27日当前规则，以本节和正式表为准。

## 工作位置与本次收口
- 目标工程 E:\neiwang_kapai\Game，Unity 项目 E:\neiwang_kapai\Game\unityclient；本次直接在既有 main 提交明确文件清单，未推送。
- 用户已确认副本奖励名称、图标及通关奖励横向滑动的实际画面“没问题”。
- 不重新执行 G0–G6，不改迁移门禁。禁止未经授权提交、推送或启用子代理。
- 继续遵循当前 AGENTS.md；多个 Editor 时验证 PID、-projectPath、MCP 实例和 Application.dataPath。测试、修改、新增统一经核验后的目标 Unity MCP。
- 工作区仍有其他人的/其他任务的资源、Prefab、场景和表头说明改动。本次未整体暂存、清理或覆盖，续接必须先保护工作区。

## 已完成且纳入本提交
1. P01 功能与道具导出链
   - function.xlsx 作为维护源，121条规则；正式表派生服务端配置、客户端22项解锁目录和24项玩法目录，保留原顺序和Steam屏蔽规则。
   - Items入口优先正式item.xlsx的1884条记录；unitydata/export/server/authoritative/json/item.json仅兜底正式表未维护的13条ID，总输出1897条。
   - 统一All/DongFu、两端和旧专项入口，消除整表覆盖和客户端后置item拷贝覆盖。保留用户确认的种子、丹方、丹药、材料数据。
2. 关卡、战斗、怪物和奖励
   - 正式维护源 unitydata/excel/maplist.xlsx、fight_config.xlsx、monster_boss_basic.xlsx、reward.xlsx，统一导出与当前两端运行数据。
   - maplist保留2780关、Hope=0；不再使用money、exp_pet、first_reward、add_reward、AttackCount；主奖励只走rewardID，首次和重复采用同一规则。已按用户决定用exp_pet替换原money中的神将经验，未相加。
   - reward的drop_type=1为必掉、weight=0；2为随机候选、weight>0。同组必掉全部发，随机候选按权重选一行。只有实际存在的类型才有记录，不补空类型2占位。
   - 三元组[类型或道具ID,对象ID,数量]；四元组[类型或道具ID,对象ID,最小数量,最大数量]，随机数量含上下限；第二位不是品质。
   - 主线1266关、127章；战斗总3559条、怪物总7709条，主线缺引用0。支线20001～20006共6个缺失fightID仍按功能后续处理，不造占位战斗。
   - 客户端新增main_dungeon_fight_dat/main_dungeon_monster_dat正式投影，在通用资料后加载以保持非主线资料。通用Cocos配置不作为当前主线维护输入。
   - 保留龙崖本章Boss的章节宝箱结算与防重；普通扫荡单请求最多5次，龙崖连战不经过该限制。
3. 定向修复
   - 服务端AddPetExp只统计实际序列化的神将记录，修复经验推送长度不匹配。
   - 模式下发不清空进行中的结算状态，修复龙崖连战在章节交界中断。
   - World奖励统一经DescribeWorldReward读取正式客户端目录，普通道具走Configs/item.json，神将/装备走对应目录；不改变服务端类型、对象ID和数量。保留既有4601～4604缺表碎片兼容分支。
   - 正式World/DadituuiLayer.prefab的通关奖励改为单行Content+ScrollRect，支持从图标上左右拖动，保留原视口尺寸、位置、字号和资源引用，刷新复用行并保留滑动位置。
   - 构建失败同时显示stdout/stderr，避免CMake警告掩盖实际编译错误。

## 验证与边界
- 功能、道具及副本导出隔离回归已通过；原生奖励规则、主线实际配置解析、原生服务端构建和Unity编译通过。检查证据的具体时间和源码范围，不把早期报告的1110缺失/未运行状态当当前结论。
- 高等级隔离Slot09：前5章46个不同关卡/58场，跨章、重复通关、经验、货币与章节箱到账已核对。本次第6章10场实际结算，6183“破虚·斩妖秘录”、6188“破虚·守心要诀”均显示正式名称、图标1817和品质4。
- 12项通关奖励实际拖动：偏移0→-773.27→0；点击详情可用，关闭详情保留-250位置。最终Console错误0，用户已确认画面。
- 43份原存档文件哈希未变；隔离Slot09已归档到Saves/Trash，本轮服务端及8711监听已关闭。数据库schema未变；运行配置已更新，Steam发行包未重新打包。
- 不是新档实测，也不是1266关逐关验收。普通模式扫荡没有单独进入Play验收；共享解码和原生规则已验证。尚不能据此确认首战胜率或45～60分钟体验闭环。
- 最新证据：.local/world-reward-display-20261026/verification.json、cleanup.json、验证结果.md。
- 其他证据：.local/main-dungeon-acceptance-20261026/verification.json、验证结果.md；.local/main-dungeon-unify-20261026/verification.json；.local/p01-items-20261026/final-verification.json；.local/p01-unlocks-20261026/final-verification.json。

## 现有策划工作簿与待办
- 保留 Outputs/EarlyExperience/20261026/前期体验与投放总表_V0.1.xlsx；继续使用同目录V0.2，不重建一套表。Outputs和.local属于本地材料，本提交不强行纳入这些忽略目录。
- V0.2有4页、26个体验节点、28项功能核对、17个待定ID；不是全部已解决。P01已实施。
- P02首轮范围与目标：用户明确后置，先处理冲突，不自动重开循环设计。
- P03奖励链：首胜字段/旧money+first/add_reward方案已退役；工作簿仍有实施前文字，须先以本提交正式表和当前代码更新事实与验收状态，不能继续沿用旧金额或重复英雄投放结论。新档经济预算还未确认。
- P04初始资源与首战资格：优先核对当前正式新档入口、初始资源、出生57、体力与首笔可支配收益。高等级隔离测试不等于新档胜率/到账/耗时通过。
- P05主线任务数据与持久化：仍未形成正式主线任务/引导存档链，任务和奖励方案须与用户逐项对齐。
- P1：P06首抽/第二英雄，P07培养教材包，P08洞府教学顺序，P09种植选择，P10聚灵阵供给，P11炼丹材料，P12永久属性，P13首本藏书，P14同阶提示，P15剧情/引导，P16耗时基线。P06/P10的旧首通投放描述同样须先更新。
- P17炼器仍是P2范围，业务尚未开发，不自动纳入首轮。
- 新窗口先读本HANDOFF、当前AGENTS和V0.2待定事项，列清仍存在的数据/代码冲突，并与用户一次只处理一项。区分现有事实、建议、待定数值、待实测项；未确认新数值不直接调整正式表，不启动新档Play或改玩家存档。

## 审阅说明
- 用户本轮允许提交到主干并开启新窗口；当前main本地提交完成后回报实际提交号，未获推送指令不推送。
- 本提交只包含本轮功能/道具导出与副本链的59个明确路径（含本文件）。其他修改完整留在工作区，下一窗口不得当作本轮已发布结果。
