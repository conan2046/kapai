# Unity 数据源补齐后的旧表清单（2026-10-11）

工程：`E:\neiwang_kapai\Game`。路径均相对工程根目录。

## 处置结论

- 本轮8个工作簿、47个Sheet承接了48个旧JSON/XML/CSV文件。新编辑源统一在`unitydata/excel`，旧表业务值和字段语义保留。
- 原运行路径继续保留为导出产物，已确认的客户端/服务端消费者沿用原路径；未命中直接读取的兼容副本不据此删除。四份旧CSV保留为兼容输出，已退役其独立编辑源身份。
- 客户端`unitydata/export/client/source/Configs`及`unityclient/Assets/Resources/ProjectXData/Configs`中的对应JSON/XML继续作为生成/运行产物保留；钓位`map_resource`是客户端专属字段，不输出服务端JSON和SQLite。
- 本轮未删除旧表，未改原Cocos的`server/config`、`server/sql`、`client/ProjectX/src/ConfigData`。原Cocos表属于独立链，不能按此清单批量删除。

## 已补齐：逐文件映射

| 功能 | 旧表路径 | 新编辑源 → Sheet | 当前用途 |
|---|---|---|---|
| 钓鱼 | `unityserver/config/json/fish_settings.json` | `unitydata/excel/fish_config.xlsx → fish_settings` | 运行JSON |
| 钓鱼 | `unityserver/config/json/fish_position.json` | `unitydata/excel/fish_config.xlsx → fish_position` | 运行JSON |
| 钓鱼 | `unityserver/config/json/fish_reward.json` | `unitydata/excel/fish_config.xlsx → fish_reward` | 运行JSON |
| 每日答题 | `unityserver/config/source/answer-settings.csv` | `unitydata/excel/answer_config.xlsx → answer-settings` | 兼容CSV输出 |
| 每日答题 | `unityserver/config/source/question.csv` | `unitydata/excel/answer_config.xlsx → question` | 兼容CSV输出 |
| 欢乐转盘 | `unityserver/config/source/happywheel-settings.csv` | `unitydata/excel/happywheel_config.xlsx → happywheel-settings` | 兼容CSV输出 |
| 欢乐转盘 | `unityserver/config/json/happywheel.json` | `unitydata/excel/happywheel_config.xlsx → happywheel-settings` | 运行JSON（派生产物） |
| 欢乐转盘 | `unityserver/config/source/happywheel-rewards.csv` | `unitydata/excel/happywheel_config.xlsx → happywheel-rewards` | 兼容CSV输出 |
| 法宝搜索 | `unityserver/config/json/fabao_looting.json` | `unitydata/excel/fabao_looting.xlsx → fabao_looting` | 运行JSON |
| 装备词缀/神将技能/配装 | `unityserver/config/json/equipment_affix.json` | `unitydata/excel/hero_combat.xlsx → equipment_affix` | 运行JSON |
| 装备词缀/神将技能/配装 | `unityserver/config/json/hero_skill_role.json` | `unitydata/excel/hero_combat.xlsx → hero_skill_role` | 运行JSON |
| 装备词缀/神将技能/配装 | `unityserver/config/json/hero_build_profile.json` | `unitydata/excel/hero_combat.xlsx → hero_build_profile` | 运行JSON |
| 属性战力 | `unityserver/config/json/attr_type.json` | `unitydata/excel/attr_type.xlsx → attr_type` | 运行JSON |
| 摇钱树/闯关 | `unityserver/config/xml/yaoqianshu.xml` | `unitydata/excel/casual_gameplay.xlsx → yaoqianshu` | 运行XML |
| 摇钱树/闯关 | `unityserver/config/xml/chuangguan.xml` | `unitydata/excel/casual_gameplay.xlsx → chuangguan` | 运行XML |
| 摇钱树/闯关 | `unityserver/config/xml/chuangguan_event.xml` | `unitydata/excel/casual_gameplay.xlsx → chuangguan_event` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/role_basic_config.xml` | `unitydata/excel/role_battle.xlsx → role_basic_config` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/role_level_attr.xml` | `unitydata/excel/role_battle.xlsx → role_level_attr` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/role_skill_LvUp.xml` | `unitydata/excel/role_battle.xlsx → role_skill_LvUp` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/pet_basic_config.xml` | `unitydata/excel/role_battle.xlsx → pet_basic_config` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/skill_basic.xml` | `unitydata/excel/role_battle.xlsx → skill_basic` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/skill_active_effect.xml` | `unitydata/excel/role_battle.xlsx → skill_active_effect` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/skill_additive_effect.xml` | `unitydata/excel/role_battle.xlsx → skill_additive_effect` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/skill_buff.xml` | `unitydata/excel/role_battle.xlsx → skill_buff` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/fight_special_config.xml` | `unitydata/excel/role_battle.xlsx → fight_special_config` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/fight_dialog.xml` | `unitydata/excel/role_battle.xlsx → fight_dialog` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/fight_zhuzhan.xml` | `unitydata/excel/role_battle.xlsx → fight_zhuzhan` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/monster_boss_vary_attr.xml` | `unitydata/excel/role_battle.xlsx → monster_boss_vary_attr` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/pet_born_skill_LvUp.xml` | `unitydata/excel/role_battle.xlsx → pet_born_skill_LvUp` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/pet_skill_LvUp.xml` | `unitydata/excel/role_battle.xlsx → pet_skill_LvUp` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/pet_skill_add.xml` | `unitydata/excel/role_battle.xlsx → pet_skill_add` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/pet_quality.xml` | `unitydata/excel/role_battle.xlsx → pet_quality` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/pet_star.xml` | `unitydata/excel/role_battle.xlsx → pet_star` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/pet_star_step.xml` | `unitydata/excel/role_battle.xlsx → pet_star_step` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/pet_xiulian.xml` | `unitydata/excel/role_battle.xlsx → pet_xiulian` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/pet_type_attr_ratio.xml` | `unitydata/excel/role_battle.xlsx → pet_type_attr_ratio` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/pet_xuemai.xml` | `unitydata/excel/role_battle.xlsx → pet_xuemai` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/equip_qianghua.xml` | `unitydata/excel/role_battle.xlsx → equip_qianghua` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/equip_qianghua_attr.xml` | `unitydata/excel/role_battle.xlsx → equip_qianghua_attr` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/equip_shengjie.xml` | `unitydata/excel/role_battle.xlsx → equip_shengjie` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/equip_cuilian_attr.xml` | `unitydata/excel/role_battle.xlsx → equip_cuilian_attr` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/equip_xilian.xml` | `unitydata/excel/role_battle.xlsx → equip_xilian` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/equip_xilian_attr.xml` | `unitydata/excel/role_battle.xlsx → equip_xilian_attr` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/title_config.xml` | `unitydata/excel/role_battle.xlsx → title_config` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/pet_draw_basic.xml` | `unitydata/excel/role_battle.xlsx → pet_draw_basic` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/pet_draw_config.xml` | `unitydata/excel/role_battle.xlsx → pet_draw_config` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/fengshen_shilian.xml` | `unitydata/excel/role_battle.xlsx → fengshen_shilian` | 运行XML |
| 角色/神将/装备/战斗初始化 | `unityserver/config/xml/tongtiantower.xml` | `unitydata/excel/role_battle.xlsx → tongtiantower` | 运行XML |

## SQLite旧种子：保留为导出产物

| 旧路径 | 新编辑源 | 用途 |
|---|---|---|
| `unityserver/sql/sqlite/seeds/answer_settings.sql` | `answer_config.xlsx / answer-settings` | 答题参数；同步初始化结构标记段 |
| `unityserver/sql/sqlite/seeds/question.sql` | `answer_config.xlsx / question` | 题库；同步初始化结构标记段 |
| `unityserver/sql/sqlite/seeds/happywheel.sql` | `happywheel_config.xlsx / happywheel-rewards` | 转盘type=2奖励；同步初始化结构标记段 |
| `unityserver/sql/sqlite/seeds/fish.sql`（本轮新增） | `fish_config.xlsx`三Sheet | 钓鱼配置；同步初始化结构标记段 |

`unityserver/sql/sqlite/001_initial_schema.sql`仍是正式启动输入，服务端通过`--sqlite-schema`加载。导出器只替换对应种子标记段；不直接操作玩家Slot数据库。
新生成SQL另存于`unitydata/export/server/generated/sqlite`。删除鱼种会清除配置旧行，保留鱼篓玩家状态；新配置在下次启动单机服务端时生效。

## 旧Unity导表入口：用途变更

| 旧入口 | 本轮后用途 | Unity入口 |
|---|---|---|
| `tools/local/Export-QuestionBank.ps1` | 保留给原server链；不再维护Unity题库 | `Export-UnityOwnedTables.ps1 -Group Answer` |
| `tools/local/Export-AnswerSettings.ps1` | 保留给原server链；不再维护Unity答题参数 | 同上 |
| `tools/local/Export-HappyWheelConfig.ps1` | 保留给原server链；不再维护Unity转盘 | `Export-UnityOwnedTables.ps1 -Group HappyWheel` |
| `tools/unity-migration/Sync-FishConfig.mjs` | 历史停用入口，不恢复 | `Export-UnityOwnedTables.ps1 -Group Fish` |

## 未纳入本次源表：保留清单

下列文件不代表当前已开启的玩家功能。本轮不改变Steam排除范围，不将有初始化代码等同于功能已开放，也不删除无直接引用的旧副本。
服务端JSON仍有4个未进入Unity导出中间目录；XML还有41个未纳入本轮类型工作簿。部分已有其他Excel/JSON合同，不能机械补同名源表。

| 类型 | 旧文件路径 | 当前处置 |
|---|---|---|
| JSON | `unityserver/config/json/LoginReward.json` | Steam排除相关旧配置，保留、不重新开启功能 |
| JSON | `unityserver/config/json/guild_reward.json` | Steam排除相关旧配置，保留、不重新开启功能 |
| JSON | `unityserver/config/json/jijin.json` | Steam排除相关旧配置，保留、不重新开启功能 |
| JSON | `unityserver/config/json/revert.json` | Steam排除相关旧配置，保留、不重新开启功能 |
| XML | `unityserver/config/xml/Function_Level.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/activityreward.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/arrt_type.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/bang_pai_huoyue.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/bang_pai_keji.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/bang_pai_reward.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/bang_pai_skill.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/chuangguan_battle.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/doushen_config.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/drop_matching.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/equip_star.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/fight_config.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/find_resource.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/guild_based.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/hecheng.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/jingjie_config.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/level_reward.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/mission_config.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/mission_dialog.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/monster_boss_basic.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/mount_config.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/mount_qianghua.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/pet_equip.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/pet_equip_attr.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/pet_equip_part.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/pet_equip_qianghua.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/pet_level_up_exp.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/random_map.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/rank_reward.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/reward.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/reward_notice.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/shenjiang_zhekou.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/shenqi_config.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/shenqi_peiyang.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/shop_shenjiang_mystery.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/suit.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/team_fabu.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/wing_config.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/wing_qianghua.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/zhenfa_config.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |
| XML | `unityserver/config/xml/zhenfa_level.xml` | 保留旧基线；核对消费者及现有JSON合同后再定处置 |

## 验证与使用

对应表导出入口、字段格式见`unitydata/README.md`。本轮验证包括完整双端导表、工作簿→产物的全字段往返、隔离SQLite种子重复执行、逐组改表传播、失败无写入、鱼种删除保留鱼篓，以及客户端专属字段/XML空占位行。未启动Play，不作画面验收结论。

本清单是迁移后的路径和用途清单，**不是删除授权清单**。
