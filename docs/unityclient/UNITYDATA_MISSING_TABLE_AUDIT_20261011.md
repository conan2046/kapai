# Unity 数据表缺口整理（2026-10-11）

> 本文保留首次审计快照。后续已按授权顺序新增8个工作簿/47个Sheet，接通9个JSON、35个XML、4个CSV及SQLite种子。迁移后的旧表路径与保留用途见 `UNITYDATA_LEGACY_TABLES_20261011.md`，当前导出用法见 `unitydata/README.md`。

## 审计范围与结论

目标工程：`E:\neiwang_kapai\Game`；Unity：`unityclient`。会话初始命令目录为 `C:\Users\Admin\.codex\worktrees\fb32\Game`，本次读取和报告均在 E 盘工程。已核对现有 Unity 主进程的 `-projectPath` 指向 E 盘；本次没有控制 Editor、运行导表、修改配置、读取玩家 SQLite 或提交代码。

本次核对的是文件与维护链完整性，不是玩法验收。区分：运行文件缺失、Unity 编辑源缺失、运行基线未纳入 unitydata、已有编辑源但导出仍用快照覆盖。XML 同名 Excel 检查只作为定位线索，不能证明同字段或可互换。

| 核对项 | 当前实查 | 判断 |
|---|---:|---|
| Unity Excel 工作簿 | 60个文件 | 根目录59个，`sql配置表/item.xlsx`另1个；境界、角色外观已纳入 |
| 客户端源快照 / 运行文件 | 61 / 61 | 相对路径齐全，61 对 SHA256 全部一致 |
| 服务端 JSON / 导出中间 JSON | 71 / 58 | 13 张没有对应服务端中间产物；已覆盖的58对哈希一致 |
| 服务端 XML | 76 | 仅4个同名文件在客户端快照；其余72个未收进 unitydata |
| 服务端 CSV 编辑源 | 4 | 全在 `unityserver/config/source`，unitydata 下无同名文件 |

**未发现上述客户端快照同步范围内的运行文件缺失。主要问题是维护源和导出链不完整；有表能运行，不等于已可从 Unity 数据目录统一修改和重建。**

原 `unitydata/README.md` 的54个客户端文件、58个Excel是旧数量，以本次实查为准。

## 当前保留功能：优先补齐清单

以下路径均相对工程根目录；JSON运行基线为 `unityserver/config/json/`，XML运行基线为 `unityserver/config/xml/`。

| 优先级 | 功能 | 缺口表/维护源 | 现状与证据 |
|---|---|---|---|
| P1 | 钓鱼 | `fish_settings`、`fish_position`、`fish_reward` | 客户端 unitydata JSON快照、服务端JSON均存在，但无Unity Excel、无服务端中间产物；真正业务读取SQLite同名配置表。`unityserver/src/fish_single_player.cpp:70,78,156`；初始种子在 `unityserver/sql/sqlite/001_initial_schema.sql:2082` 起。必须补Excel→JSON/SQLite种子链，不能只复制JSON。 |
| P1 | 每日答题 | `question`、`answer_settings` | 题库/参数CSV位于 `unityserver/config/source/question.csv`、`answer-settings.csv`；无 unitydata 编辑源与导出链。运行读取SQLite；`pack_deal.cpp:84`、`script_call.cpp:2951`。现有 `tools/local/Export-QuestionBank.ps1`、`Export-AnswerSettings.ps1` 默认写旧 `server`；题库工具的工作簿默认在 `outputs/answer-question-bank/question.xlsx`，本轮未确认其实际存在，不能当Unity正式输入。 |
| P1 | 欢乐转盘 | `happywheel`；`happywheel-settings.csv`、`happywheel-rewards.csv` | 运行JSON与两份CSV在 unityserver；unitydata全无。`unityserver/src/huo_dong.cpp:5025`读取JSON。`tools/local/Export-HappyWheelConfig.ps1`仍默认读写旧server，需要先迁移维护源和导出入口。 |
| P1 | 法宝搜索 | `fabao_looting` | 仅服务端运行JSON；unitydata无Excel、无同名JSON。`unityserver/src/pet_equip_manage.cpp:380`。Unity源码中的旧concept工作簿路径只是残留说明，当前工程无concept目录，不能当有效源。 |
| P1 | 装备特殊词缀 | `equipment_affix` | 仅服务端运行JSON；unitydata无编辑源/同名JSON。`unityserver/src/pet_equip_manage.cpp:167`。 |
| P1 | 神将技能定位 | `hero_skill_role` | 仅服务端运行JSON；unitydata无编辑源/同名JSON。`unityserver/src/skill.cpp:156`。 |
| P1 | 神将配装建议 | `hero_build_profile` | 客户端 unitydata JSON快照和双端运行JSON存在；无Excel、无服务端中间产物。`unityclient/Assets/src/Data/HeroBuildProfileCatalog.cs:17`读取客户端JSON；未见服务端C++直接读取该JSON，本项不计作服务端运行阻塞。 |
| P1 | 属性与战力换算 | `attr_type` | 仅服务端运行JSON；unitydata无编辑源/同名JSON。`unityserver/src/init.cpp:1848`。 |
| P1 | 摇钱树 | `yaoqianshu.xml` | unitydata无同名XML/Excel；`unityserver/src/huo_dong_mgr.cpp:61`直接读取XML，`init.cpp:63`参与初始化。 |
| P1 | 闯关 | `chuangguan.xml`、`chuangguan_event.xml` | unitydata无同名XML/Excel；`unityserver/src/xun_bao_manage.cpp:77`、`chuangguan_reward_manager.cpp:26`。另有`chuangguan_battle.xml`运行文件，但本次未命中直接源码引用，应先确认使用状态。 |
| P1 | 主角基础/成长/技能 | `role_basic_config.xml`、`role_level_attr.xml`、`role_skill_LvUp.xml` | 三表均无Unity同名编辑源/快照；`unityserver/src/init.cpp:1963,1989,2375`。 |
| P1 | 战斗规则/对白/助战/怪物变化 | `fight_special_config.xml`、`fight_dialog.xml`、`fight_zhuzhan.xml`、`monster_boss_vary_attr.xml` | 无Unity同名编辑源/快照；`unityserver/src/fight.cpp:248,275,316`、`monster.cpp:674`。与已有`fight_config.xlsx`不是同一张表。 |
| P2 | 封神相关旧配置 | `fengshen_shilian.xml` | 无Unity同名编辑源/快照；`unityserver/src/init.cpp:2457`读取，`init.cpp:78`初始化。文件对应旧试炼管理器；不能仅凭名称认定为封神列传的唯一正式表，需在补表前核实当前入口消费关系。 |
| P2 | 神将旧技能/成长配置 | `pet_born_skill_LvUp.xml`、`pet_skill_LvUp.xml`、`pet_skill_add.xml`、`pet_quality.xml`、`pet_star.xml`、`pet_star_step.xml`、`pet_xiulian.xml`、`pet_type_attr_ratio.xml`、`pet_xuemai.xml` | 运行XML有、unitydata无同名编辑源/快照，`unityserver/src/pet.cpp`有加载代码。已有`hero/star/break/xiulian.xlsx`覆盖新JSON业务，不能据此自动替代旧XML；先识别仍有消费者的字段。 |
| P2 | 旧装备培养 | `equip_qianghua.xml`、`equip_qianghua_attr.xml`、`equip_shengjie.xml`、`equip_cuilian_attr.xml`、`equip_xilian.xml`、`equip_xilian_attr.xml` | `unityserver/src/item.cpp`有加载代码，XML未纳入unitydata。强化有同名Excel，但现有通用导出生成JSON，未证明能生成这个XML合同。与新装备培养JSON链分开处理。 |
| P2 | 称号/旧抽宠/通天塔 | `title_config.xml`、`pet_draw_basic.xml`、`pet_draw_config.xml`、`tongtiantower.xml` | unitydata无同名编辑源/快照，服务端初始化保留加载。须先确认Steam实际入口与用途，不直接开启玩法迁移。 |

## 已有文件，但仍缺可重建编辑源

| 功能/类别 | 现有unitydata快照 | 维护链缺口 |
|---|---|---|
| 神将基础展示与技能 | `Configs/pet_basic_config.xml`、`skill_basic.xml`、`skill_active_effect.xml`、`skill_additive_effect.xml` | 四份XML已收进客户端快照；无同名Unity Excel和专用XML导出器。服务端也有这四表，但客户端/服务端语义一致性未在本轮验收。`HeroCatalog.cs:121`起读取。 |
| 战斗表现 | `Battle/skill_client.dat.bytes`、`skill_attack_client.dat.bytes`、`skill_effect_client.dat.bytes`、`skill_behit_client.dat.bytes`、`skill_camerashock.dat.bytes`、`buff_client.dat.bytes`、`hit_monster.dat.bytes`，以及其余Battle文件 | 已有运行快照；目前Unity导出主要复制，缺对应表现源表/生成工具。`BattlePresentationCatalog.cs`真实加载前述7表及阵法文本；其它Battle文件先查消费者。 |
| 世界/培养旧文本 | `World/*_dat.txt` | Excel中的bigmap/map_res/maplist/fight_config/monster_boss_basic等已存在，但当前客户端导出并未统一由Excel重建全部这些文本，仍含快照复制。宝箱reward_fixed已专门接通；MapEditor也能维护map_res快照，不能把所有World表都报成完全无编辑入口。 |
| 玩法大厅/开放条件 | `Configs/function-routes.json`、`function-unlocks.json`、`gameplay.json` | 有Unity快照与function.xlsx，但客户端全量导出未生成上述全部映射；旧`tools/unity-migration/Export-GameplayConfig.ps1`默认读取`server/config/json/function.json`并直接写运行目录。需统一正式输入和映射维护位置。 |

## 已覆盖或不用另建的表

- 境界：`jingjie_config.xlsx` + 第二页 `RuntimeRules` → 客户端 `jingjie.json/jingjie-rules.json`、服务端 `jingjie_config.json/jingjie_rules.json`，专用导出脚本已存在。规则JSON来自同一工作簿，**不缺独立jingjie_rules.xlsx**。
- 新装备/法宝培养、合成、神将升级/突破/升星/修炼/图鉴、阵法费用、游历三界、抽卡、任务、商城、关卡奖励等已有相关Unity Excel/JSON输入。部分客户端派生表本就由多张源表生成，不能按文件同名机械要求新建Excel。
- 11张权威覆盖表`daily/drop_matching/function/item/level_reward/mission_dialog/reward/sevendays/shop_config/shop/xiulian`：Excel和JSON快照都存在，但通用导出仍以`authoritative/json`覆盖Excel结果。这是**Excel修改生效规则缺口**，不是文件不存在；改Excel前须确认权威源。此次未运行转换器，不重新声称11张都与当前Excel内容有差异。

## 排除功能与历史残留

服务端中间JSON缺口中，`guild_reward.json`（帮派）、`jijin.json`（基金）、`LoginReward.json`（登录活动奖励）、`revert.json`（资源找回）属于Steam排除范围或其遗留配置，列入盘点，不补玩法。

72个XML缺口含帮派、队伍、活动福利、旧师门/心魔脚本、坐骑/翅膀/神器以及同业务旧XML副本。**72不是72张当前功能急需补表的数量**。有源码读取也不等于玩家入口开放；未命中源码引用也不能直接删除。完整逐文件路径、同名Excel线索和源码行号见明细。

地图`unityserver/config/dat`及存档/账号/背包等数据库状态不归为本轮缺失策划表；未审计在线数据库实值、每张SQLite业务配置的种子新旧及全字段硬编码。

## 明细与后续顺序

- 逐文件清单：`.local/unitydata-audit-20261011/missing-files.csv`（13个JSON中间产物缺口 + 72个XML集中目录缺口 + 4个CSV编辑源，共89项；类别存在交叉业务，不能相加为缺失功能数）。
- 文件计数、路径与哈希检查：`.local/unitydata-audit-20261011/inventory.json`。
- 可重复的只读盘点：`.local/unitydata-audit-20261011/audit.py`。它只写本轮证据目录，不执行导出。

建议按业务逐个收口：钓鱼 → 答题 → 欢乐转盘 → 法宝搜索 → 装备词缀/神将技能 → 属性战力 → 摇钱树/闯关 → 角色和战斗XML。每项先确认当前权威文件，再集中编辑源并补客户端/服务端/SQLite导出合同。此报告仅整理，未进行上述迁移。
