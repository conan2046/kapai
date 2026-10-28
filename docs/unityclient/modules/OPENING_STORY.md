# 开局剧情与流程引导

## 当前范围（2026-10-27）

本版只对新创建的正式Steam单机角色开启。旧存档没有unity_story_state记录，沿用既有行为，不回收或重发已有神将。此功能使用公共事件，不恢复旧mission_dialog任务脚本，也不重开迁移门禁。

| 顺序 | 玩家流程 | 权威条件或动作 |
|---|---|---|
| 1 | 创角进入主界面，播放开场对白 | 实际主界面事件1004 |
| 2 | 点击提示打开境界 | 功能22实际打开 |
| 3 | 挂机积累修为，首次小境界突破 | 境界1→2；对白100002 |
| 4 | 伙伴对白结束或跳过 | 奖励包40004：苏全忠57×1 |
| 5 | 苏全忠自动上阵1号位 | 读取真实阵容 |
| 6 | 点击提示前往第一章 | 通关Boss10006 |
| 7 | 首次流程通关奖励 | 奖励包40005：装备1001绿武器×1 |
| 8 | 结算后按提示返回主界面 | 暂停章节自动循环/跨章，原勾选值不改 |
| 9 | 播放穿戴教学对白 | 对白100003 |
| 10 | 打开神将，选择1号位并穿戴武器 | 记录本次奖励UID；必须实际穿戴给目标神将 |
| 11 | 前往第二章并发起挑战 | 服务端接受章节1002挑战后完成 |

**57的赠送时机是首次小境界突破后的剧情对话完成，不在创角或首次登录时赠送。** 本版三段对白为测试稿，可以直接修改正式表文案。跳过对白仍推进；不能跳过突破、通关或实际穿戴条件。

## 维护源与导出

- unitydata/excel/story_config.xlsx：story_dialog对白、story_event步骤、action_type动作说明。触发和完成只填写公共事件ID；本版只支持一条无分支的开局链。
- unitydata/excel/event_config.xlsx：唯一公共事件条件定义，当前162条启用，1015/1017为禁用任务示例。任务与剧情独立保存进度。
- unitydata/excel/reward_fixed.xlsx：正式包40004/40005。本版剧情包仅支持单神将或单装备×1，包内容必须与完成事件的类型和对象一致。
- 导出入口：Export-UnityOwnedTables.ps1 -Group Story -Mode Both；附加-ValidateOnly校验维护源与输出。Story同时导出公共事件/任务；新增或修改奖励包时还须先运行WorldRewards定向组。
- 四份运行副本统一生成至server/generated/json_server、unityserver/config/json、client/source/Configs与Resources/ProjectXData/Configs。禁止手改JSON；authoritative旧快照不覆盖新数据。
- 本版对白支持玩家/神将、固定左侧布局0、scale=1、打字速度、句末等待和跳过开关。NPC类型2、其他位置/缩放尚不支持，启用无效值会拒绝。挂载和XY偏移改由每行parent_node/offset_x/offset_y配置，字体和内部布局仍在正式Prefab维护。

## 实现与保存

- 客户端：ProjectXApp.Story.cs，/328 op0读取、op1当前对白确认、op2实际主界面/境界/神将界面事件。回复版本128；切号和断线清空显示状态。
- 服务端：story_unity.h/.cpp；新角色创建引导记录；旧角色无记录不补开。进度、当前步骤、版本和教学装备UID保存在当前Slot SQLite的unity_story_state。步骤推进和神将/阵容/装备保存使用同一SAVEPOINT事务，重复请求读取当前版本，避免重发奖励。
- 共用层：GlobalEvents.Publish/Advance/ReadCurrent。神将获得、装备获得、上阵、穿戴和章节挑战发布实际业务事件；界面事件只报告真实打开结果。没有第二份剧情条件数组。
- 原Chapter Boss包仍按每次胜利结算；本版首次教学装备是独立的一次性流程奖励，不改变Boss包和其他主线数值。
- 未完成穿戴教学前服务端拒绝越过当前引导章节，客户端暂缓自动跨章与本章循环；教学完成后恢复原自动设置的正常行为。
- 不修改旧任务保存结构；不运行MySQL迁移。SQLite新表按角色创建/加载时追加，不改旧角色数据。

## 预制体

- 原对白美术：Assets/Prefabs/Retained/DialogLayer.prefab。
- 正式复用副本：Assets/Prefabs/Story/StoryDialog.prefab；内容DialogUI/Content、名字DialogUI/bg_Name/Name、立绘DialogUI/NPC、跳过DialogUI/Image_1/btn_Skip。
- 操作提示：Assets/Prefabs/Story/StoryGuide.prefab，复用Retained/GuideLayer；点击Panel/GuideBg执行引导入口。
- 字体、尺寸、内部排版和资源引用留在Prefab；本轮按策划明确要求，挂载节点和XY位置改由Excel逐行控制。原Retained预制体不覆盖，现有正式Story副本也不会被准备工具重新生成覆盖。资源键为UI/StoryDialog和UI/StoryGuide，由项目原生引用索引维护。

## 验证与测试

已完成：8项剧情导出/真实引擎累计触发用例、7项公共事件回归、原生构建与真实离线配置加载、Unity编译和绑定检查。隔离新档实际验证至二阶对白后57上阵及第一章入口；重登仍一名57、步骤6。三个单次强化事件可以累计触发对白，错误参数不会推进；最终证据见.local/onboarding-20261027/verification.json。原生构建、离线实际配置加载和新档触发证据以.local/onboarding-20261027最终记录为准，不把旧模块历史验收当作本次结果。

策划测试从“新的回忆/新游戏”创建新角色开始。第一章必须先完成，结算后返回主界面，按提示穿戴本次绿武器，然后开始第二章。不要用已拥有57的旧档验证新赠送时机。重点检查：首次突破前队伍没有57；对白后只有一名57且在1号位；首章教学绿武器只有一件；退出重进不断链且不重发；穿戴其他旧装备不能冒充本次教学实例。

完整首章战斗胜率、实际耗时及最终画面仍需本次新档实测/用户确认；本功能没有调整怪物、成长或奖励数量。

## 每句对白与教学提示的位置（2026-10-27）

正式表story_config.xlsx的story_dialog和story_event均在M/N/O列增加parent_node、offset_x、offset_y。对白每句独立配置，教学提示每步独立配置，不复用一套硬编码坐标。

| 字段 | 填写规则 |
|---|---|
| parent_node | Canvas；或界面资源键/子节点路径。界面键对应Assets/Prefabs/Catalog文件名，不填DynamicUi_运行时对象名。 |
| offset_x | 对白按目标节点中心定位；教学提示直接控制StoryGuide根节点Pos X，保留预制体锚点。 |
| offset_y | 对白按目标节点中心定位；教学提示直接控制StoryGuide根节点Pos Y，保留预制体锚点。 |

对白仍定位整组DialogUI中心。按最新StoryGuide预制体，story_event原有offset_x/y直接对应StoryGuide根节点Pos X/Pos Y，不再由GuideBg中心反算根节点位置；SelectImage和GuideBg的锚点、轴心、尺寸、缩放及内部图片/文字排版保留用户设置。

导出器解析正式Catalog与Prefab，拒绝错误界面、缺失/歧义节点、路径穿越、NaN/Infinity坐标；不会写出部分运行配置。运行时只查找当前场景的已存在实例，不因挂载自动创建/打开功能；界面或节点未显示时隐藏，实际打开后恢复。多句对白在切句时重新应用该行配置；指向的父界面被销毁时按当前步骤重新创建对白视图。修改表后执行Story定向导出并重新进入Play。

## StoryGuide效果与左右提示（2026-10-27）

以用户手调的StoryGuide为准：根节点直属SelectImage、GuideBg。原有M列parent_node挂载根节点，N/O控制根节点位置；story_event新增P～U列如下：

| 列 | 字段 | 规则 |
|---|---|---|
| P | select_visible | 0隐藏SelectImage，1显示；不关闭文字提示。 |
| Q/R | select_offset_x / select_offset_y | SelectImage的RectTransform Pos X/Pos Y，使用预制体原有锚点。 |
| S | hint_side | 1：Image_1和Text_1同时显示；2：Image_2和Text_2同时显示，两组互斥。 |
| T/U | hint_offset_x / hint_offset_y | GuideBg的RectTransform Pos X/Pos Y，使用预制体原有锚点。 |

两个Text都同步hint正文，显隐按hint_side切换，防止切换后出现旧文字。所有新偏移允许有限小数和负数；非法开关、方向、NaN/Infinity由导出器拦截。SelectImage的Image/Finger使用用户预制体资源和布局，不新增或强制覆盖动画、射线、尺寸。

本版步骤2示范右提示、关闭效果；步骤3示范左提示、开启效果，SelectImage中心对齐升级按钮。新字段的默认子节点位置按用户预制体的325/0填入，原有parent_node和offset_x/y数值保留。正式导出后重新导入story_event客户端资源再测试。

## Play中手调坐标（2026-10-28）

运行时坐标在进入步骤/对白句子、实例重新创建或挂载父节点变化时应用一次，不再每帧写回。当前步骤内可在Inspector/Scene调整StoryGuide、SelectImage、GuideBg的Pos X/Pos Y，弹窗暂时隐藏再恢复也保留这些临时值。切换步骤、切句、重新挂载或重新进入游戏时恢复表中配置。

记录到story_event：StoryGuide对应N/O的offset_x/y；SelectImage对应Q/R的select_offset_x/y；GuideBg对应T/U的hint_offset_x/y。Play中的值不会自动回写Excel，调好后手动填写正式表并保存、导出。
