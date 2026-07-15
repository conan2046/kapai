# 游戏功能配置来源总表

> 盘点日期：2026-07-14  
> 范围：当前仓库的客户端 Lua/资源配置、服务端 XML/JSON/dat、数据库配置表、协议入口。  
> 原则：先确认数据源，再决定需要恢复或修复的代码；无数据源的功能不猜配置、不凭残留代码补逻辑。

## 1. 总结

| 项目 | 当前数量 | 结论 |
|---|---:|---|
| 服务端 `server/config/xml` | 76 | 74 个可严格解析；任务主表、任务对白表各 1 个格式损坏 |
| 服务端 `server/config/json` | 59 | 57 个可解析；`function.json`、`mission_dialog.json` 损坏 |
| 服务端地图 `server/config/dat` | 42 | 地图文件存在 |
| 客户端 `src/ConfigData/*_dat.lua` | 64 | 客户端 JSON 转 Lua 表存在 |
| 客户端 `res/ConfigData/*.dat` | 86 | 二进制表存在；代码里找不到的 `.dat` 引用均已被注释 |
| 服务端注册协议 | 143 | 92 个已进入 smoke，51 个待人工 UI、正向消耗、战斗或跨服验证 |

最关键问题不是单个功能代码，而是本地模式跳过了正式功能配置：

```text
ConfigInit()
  -> InitJsonConfig()        # 只初始化少量基础配置
  -> local_test == 1
  -> return true             # InitXMLConfig() 完全不执行
```

因此当前能登录、创角、进主界面，不代表装备、宠物、关卡、商店、体力、活动等模块已按配置正常初始化。

## 2. 状态定义

| 标记 | 含义 |
|---|---|
| `可用` | 来源存在，当前初始化路径会加载，或数据库已有有效数据 |
| `本地跳过` | 来源存在，但 `local_test=1` 不执行 `InitXMLConfig()` |
| `损坏` | 文件存在，但无法按 JSON/XML 解析 |
| `缺源` | 代码明确读取，但仓库没有对应配置内容 |
| `有源未导入` | 仓库 SQL 有数据，本地数据库表为空 |
| `停用` | 初始化/协议代码已注释或直接返回，不是当前启动阻塞 |
| `运行态` | 玩家、排行、邮件、日志等运行数据，不应当作为静态配置补造 |

## 3. 功能模块配置映射

| 功能模块 | 服务端配置来源 | 数据库来源 | 客户端配置来源 | 当前判定 |
|---|---|---|---|---|
| 登录、角色列表、创角、选角 | `server/config/config`；本地直连开关 | `user_info`、`role_info`；无独立登录服源码 | `core/AppDef.lua`、`LoginBg.dat`、`role_basic_config.dat` | 本地直连可用；正式账号登录不能还原 |
| 角色基础属性、等级成长 | `role_basic_config.xml`、`role_level_attr.xml`、`attr_type.json`/`arrt_type.xml` | `role_info` | `role_basic_config.dat`、`attr_type_dat.lua`、`arrt_type.dat` | `本地跳过` |
| 功能开放、红点 | `function.json`、`Function_Level.xml` | `function_switch` 当前 1 行 | `function_dat.lua`、`function.dat`、`module_control.dat` | `损坏但可回建`：客户端同源 Lua 表完整；本地当前红点有降级旁路 |
| 场景、地图、跳点 | `server/config/dat/*.map`、`bigmap.json`、`maplist.json` | `game_scene` 75、`jump_point` 42 | `bigmap_dat.lua`、`maplist_dat.lua`、`map_res_dat.lua`、`map_scene.dat`、`map_path.dat`、`map_size.dat`、`path_config.dat` | 基础来源齐全；关卡 JSON 初始化被本地跳过 |
| NPC、交互、传送 | NPC 脚本 `server/script/*.lua` | `npc_template` 204、`npc_instance` 46 | `npc_template_dat.lua`、场景/路径表 | 来源齐全；后续只按现有 NPC 表和脚本恢复，不再猜协议行为 |
| 主线任务、对白、目标 | `mission_config.xml`、`mission_dialog.xml`、`doushen_config.xml` | 玩家任务状态在 `role_info` | `mission_config.dat`、`mission_dialog.dat`、`doushen_config.dat`、`mission_dialog_dat.lua` | `损坏+停用`：两个 XML 非法，三个旧加载函数已注释；现有文件与客户端同源表可用于修复格式 |
| 日常任务、七日任务、基金任务 | `daily.json`、`sevendays.json`；`jijin.json` 读取代码已注释 | 玩家任务状态 | `daily_dat.lua`、`sevendays_dat.lua`、`jijin_dat.lua` | 日常/七日可加载；基金任务为 `缺源+停用` |
| 新手引导、剧情 CG | 任务/对白表；战斗回放数据 | `fight_cg` 当前 0 | `guide_client.dat`、`NovicePreview.dat`、`die_warning.dat` | `有源未导入`：`server/sql/sql_kp.txt` 有 1 条 CG 数据；引导主要需人工 UI 验证 |
| 战斗公式、战斗演出 | `fight_config.json`、`fight_special_config.xml`、`fight_zhuzhan.xml`、`fight_dialog.xml` | `fight_playback` 为运行态 | `fight_config_dat.lua`、`fight_config.dat`、`battle/*.dat`、`hit_monster.dat` | 基础战斗配置可用；结算入口仍需专项验证 |
| 怪物、Boss | `monster_boss_basic.json`、`monster_boss_vary_attr.xml` | `monster_distribution` 36、`monster_boss_distribution` 6 | `monster_boss_basic_dat.lua/.dat`、`pet_monsters.dat` | Boss 配置 `本地跳过`；分布表已有数据 |
| 技能、技能升级 | `skill_basic.xml`、`skill_active_effect.xml`、`skill_additive_effect.xml`、`skill_buff.xml`、`role_skill_LvUp.xml` | `skill` 190、`skill_levelup` 945 | `skill_*.dat`、`battle/skill_*.dat`、`role_skill_LvUp.dat` | `本地跳过`；数据库和客户端表齐全 |
| 物品、背包、掉落、合成 | `reward.json`、`reward_fixed.json`、`drop_matching.json`、`hecheng.json` | `item_template` 1401 | `item_dat.lua`、`item_template.dat`、`reward*_dat.lua`、`drop_matching_dat.lua`、`hecheng_dat.lua/.dat` | 奖励管理可用；物品/合成完整初始化被本地跳过 |
| 装备强化、升阶、洗炼、淬炼 | `equip_*.xml`、`equip.json`、`equip_qianghua.json`、`equip_jinglian.json`、`equip_juexing.json`、`equip_shenzhu.json`、`suit.json` | 玩家装备在 `role_info` | 同名 `equip_*_dat.lua/.dat`、`suit_dat.lua/.dat` | `本地跳过` |
| 法宝 | `fabao.json`、`fabao_qianghua.json`、`fabao_jinglian.json`、代码要求 `fabao_looting.json` | 玩家法宝状态 | 同名 `fabao_*_dat.lua` | `缺源`：`fabao_looting.json` 不存在；其余配置本地跳过 |
| 神将/宠物基础、成长、血脉 | `hero.json`、`exp.json`、`pet_*.xml`、`quality.json`、`break.json`、`star.json`、`xiulian.json`、`handbook.json` | 玩家宠物状态 | 同名 `hero/exp/pet/quality/break/star/xiulian/handbook` Lua 或 dat | `本地跳过` |
| 神将抽卡 | `draw_basic.json`、`draw_config.json`；旧版 `pet_draw_basic.xml`、`pet_draw_config.xml` | 玩家抽卡状态 | `draw_*_dat.lua`、`pet_draw_*.dat` | `本地跳过` |
| 阵法 | `zhenfa_config.json`、`zhenfa_level.json`；旧 XML 同名表 | 玩家阵法状态 | `zhenfa_*_dat.lua/.dat` | `本地跳过` |
| 坐骑 | `mount_config.xml`、`mount_qianghua.xml` | 玩家坐骑状态 | `mount_config.dat` | `本地跳过` |
| 翅膀 | `wing_config.xml`、`wing_qianghua.xml` | 玩家翅膀状态 | 客户端表现主要来自角色状态和资源 | `本地跳过` |
| 神器 | `shenqi_config.xml`、`shenqi_peiyang.xml` | 玩家神器状态 | `shenqi_config.dat`、`shenqi_peiyang.dat` | `本地跳过` |
| 境界 | 代码读取 `jingjie_config.json`；仓库另有旧 `jingjie_config.xml` | 玩家境界状态 | `jingjie_config_dat.lua`、`jingjie_config.dat` | `缺文件但可回建`：客户端 Lua 表字段与服务端 JSON 契约可对齐 |
| 称号 | `title_config.xml` | 玩家称号状态 | `title_config.dat`、`title_config_client.dat`、`battle/title_config_client.dat` | `本地跳过` |
| 日常副本 | 奖励、战斗、怪物配置 | `fuben_richang` 8 | 关卡/战斗/奖励表 | 数据存在；依赖被跳过的战斗成长配置 |
| 主线关卡、章节、星级宝箱 | `bigmap.json`、`maplist.json`、`reward_fixed.json`、`map_achievement.json` | 玩家关卡状态 | 同名 `*_dat.lua` | `本地跳过` |
| 闯关 | `chuangguan.xml`、`chuangguan_event.xml`、`chuangguan_battle.xml` | 玩家闯关状态 | 通用战斗/奖励/地图表 | `本地跳过` |
| 通天塔 | `tongtiantower.xml` | `tongtianta` 5 行为占领者运行态 | `tongtiantower.dat` | `本地跳过`；数据库不是静态奖励源 |
| 封神试炼 | `fengshen_shilian.xml` | 玩家试炼状态 | `doushen_config.dat` 等战斗表现表 | `本地跳过` |
| 血战 | `blood_battle.json`、`blood_buff.json`、`blood_arrays.json`、`blood_chapter.json` | 玩家血战状态 | 同名 `blood_*_dat.lua` | `本地跳过` |
| 昆仑、游历三界 | `kunlun.json`、`sanjie.json`、`sanjie_cost.json`、`sanjie_dialogue.json`、`chuangguan.xml` | 玩家活动状态 | 同名 `*_dat.lua` | `本地跳过` |
| 仙缘 | 服务端逻辑和通用奖励/战斗配置 | `xianyuan_card` 35、`xianyuan_chapter` 56 | `xianyuan_card.dat`、`xianyuan_chapter.dat` | 数据源齐全；需协议和人工 UI 验证 |
| 商城 | `shop.json`、`shop_config.json` | `shop` 0、`shop_mystery` 153、`shop_yaoshi` 21、`shop_discount` 22 | `shop_dat.lua`、`shop_config_dat.lua` | `有源未导入`：`server/sql/_all_sql.sql` 有 196 条 `shop` 数据；JSON 初始化也被本地跳过 |
| 资源找回 | `revert.json` 当前为空数组 | 玩家找回记录 | `revert_dat.lua` 有 10 条完整配置 | `服务端空表但可回建`：客户端字段与服务端加载契约一致 |
| 奖励、等级礼包、在线奖励 | `level_reward.json`、`reward.json`、`activityreward.xml`、`reward_rank.json`、`reward_notice.xml`、`online_reward.json`、`drop_matching.json` | `dengjilibao` 7 | 同名奖励 Lua 表 | 当前奖励管理器会加载，来源基本齐全 |
| 签到、登录奖励 | `LoginReward.json` 代码读取；活动初始化已停用 | `dailysign` 62、`hd_7ridenglu` 0 | `LoginReward_dat.lua`、`LoginReward.dat` | 服务端 JSON 可由客户端同源表回建；旧 `hd_7ridenglu` 数据仍缺失 |
| 连续充值、基金、福利 | 通用活动奖励管理；`jijin.json` 已停用 | 活动数据库表 | `lianchong_dat.lua`、`jijin_dat.lua` | `jijin.json` 可由客户端同源表回建；连续充值后端活动数据仍不完整 |
| 活动开放、转盘 | 代码要求 `activity.json`、`timing.json`、`zhuanpan_config.json`、`zhuanpan_key.json`、`zhuanpan.json` | 活动表 | 客户端活动 UI、通用奖励表 | `缺源+停用`：`InitHuoDongCfg()` 当前直接返回 `true` |
| 活动奖励、兑换 | 通用奖励配置 | `huodong_info` 0、`huodong_award` 0、`huodong_exchange` 0、`hd_bang_goods` 0 | 活动 UI 与奖励表 | `有源未导入`：`server/sql/sql.txt` 有候选数据，需确认版本和编码后导入 |
| 七日/兑换/节日/现金礼包活动 | 通用奖励配置 | `hd_7ridenglu`、`hd_exchange_list`、`festival_award`、`money_giftbag_huodong` 均 0 | 对应活动 UI 表 | `缺源`：仓库未发现 INSERT 数据 |
| 帮派基础、科技、技能、活跃、奖励 | `guild_buff.json`、`guild_reward.json`、`bang_pai_*.xml`、`guild_based.xml` | `bang_pai_mission` 13、`bang_pai_seed_config` 13、`bang_pai_shangxian_mode` 15；其余为运行态 | `guild_*_dat.lua`、`bang_pai_*.dat`、`guild_based_client.dat` | `guild_reward.json` 为空，但客户端同源表有 6 条可回建；XML 部分 `本地跳过` |
| 帮派副本、帮战、种植 | 帮派/战斗/地图/奖励配置 | 帮派运行态表 | 帮派 UI、地图和战斗配置 | 基础正向协议已覆盖；完整流程依赖未加载配置和人工 UI |
| 竞技场、膜拜 | `arena.json`、`robot.json` | `arena_paihang` 10000、`arena_robot` 0 | `arena_dat.lua`、`robot_dat.lua` | 排行基础可用；`arena_robot` 原始模板 `缺源` |
| 试炼机器人 | 通用角色、宠物、战斗配置 | `shilian_robot` 0 | 通用角色/宠物表 | `缺源`：仓库未发现机器人 INSERT |
| 排行榜 | `reward_rank.json` | `rank_list`、`rank_list_save` 为空，主要是运行态/跨服数据 | `reward_rank_dat.lua` | 本地仅验证空排行响应；正式跨服排行不能靠静态表补造 |
| VIP、充值 | VIP/奖励逻辑 | `vip_def` 16；订单、充值记录为运行态/外部支付 | `vip_dat.lua`、`vip_def_dat.lua`、`guizu_config.dat` | VIP 配置存在；真实充值依赖登录/支付链路，本地只能做测试旁路或模拟订单 |
| 好友、聊天、邮件 | 无独立数值表；聊天敏感词表 | 好友、聊天、`xin_shi` 等为运行态 | UI 和协议代码 | 不需要补静态功能表；需测试数据角色和消息环境 |
| 交易行 | 物品和货币规则 | 挂单、成交记录为运行态 | 物品配置和交易 UI | 不需要单独静态表；需隔离测试角色造交易状态 |
| 体力 | `stamina.json` | 玩家体力状态 | `stamina_dat.lua` | `本地跳过` |
| 花、足迹、变身 | 通用物品/属性逻辑 | `flower_config` 5、`footprint_config` 8 | `transform.dat` 与表现资源 | 数据存在；需人工 UI 验证 |
| 答题 | Lua 接口和问题读取逻辑 | `question` 21 | 答题 UI | 当前 21 条为本地自动生成占位内容；正式题库 `缺源` |
| 公告 | 无独立文件 | `notice_login` 0 | 公告 UI | 表结构已修复，但正式公告内容 `缺源`；空表可作为“无公告”正常状态 |
| 帮助 | 无独立文件 | 登录库 `help` 0 | 帮助 UI | 独立登录库缺失；本地当前返回空列表，正式帮助内容 `缺源` |

## 4. 数据源缺口

### 4.1 仓库内已有同源表，可直接回建，不需要用户补充

| 服务端问题 | 可用同源来源 | 处理方式 |
|---|---|---|
| `function.json` 损坏 | `client/ProjectX/src/ConfigData/function_dat.lua` | 按服务端实际读取字段生成合法 JSON |
| `mission_dialog.json` 损坏 | `client/ProjectX/src/ConfigData/mission_dialog_dat.lua` | 需要 JSON 路径时重新导出；当前服务端主线仍以 XML 为准 |
| `mission_config.xml`、`mission_dialog.xml` 非法字符 | 现有 XML 主体、客户端 `mission_config.dat`/`mission_dialog.dat` | 先修复 XML 转义并验证加载条数，不改任务数值 |
| `jingjie_config.json` 缺文件 | `client/ProjectX/src/ConfigData/jingjie_config_dat.lua` | 字段契约一致，可生成服务端 JSON |
| `LoginReward.json` 缺文件 | `client/ProjectX/src/ConfigData/LoginReward_dat.lua` | 字段契约一致，可生成服务端 JSON |
| `jijin.json` 缺文件 | `client/ProjectX/src/ConfigData/jijin_dat.lua` | 字段契约一致；仅在恢复已注释基金任务时启用 |
| `guild_reward.json` 是 `[]` | `client/ProjectX/src/ConfigData/guild_reward_dat.lua` | 回建 6 条帮派活跃奖励 |
| `revert.json` 是 `[]` | `client/ProjectX/src/ConfigData/revert_dat.lua` | 回建 10 条资源找回配置 |

### 4.2 P0：真正找不到，阻塞对应核心模块

| 来源 | 问题 | 影响 |
|---|---|---|
| `server/config/json/fabao_looting.json` | 代码明确读取；服务端、客户端、SQL 均未找到同源表 | `CItemCfgManager::InitAllCfg()`，法宝/装备完整初始化 |

需要提供该表的原始 Excel、正确 JSON，或同版本正式服配置；不要只提供截图。

### 4.3 P1：仓库无原始内容，功能完整体验时需要

| 数据源 | 当前状态 |
|---|---|
| `arena_robot` | 表为空，未发现 INSERT；竞技场机器人模板缺失 |
| `shilian_robot` | 表为空，未发现 INSERT；试炼机器人模板缺失 |
| `hd_7ridenglu` | 表为空，未发现 INSERT；服务端七日奖励缺失 |
| `hd_exchange_list` | 表为空，未发现 INSERT；活动兑换缺失 |
| `festival_award` | 表为空，未发现 INSERT；节日奖励缺失 |
| `money_giftbag_huodong` | 表为空，未发现 INSERT；现金礼包活动缺失 |
| `question` 正式题库 | 当前 21 条是本地占位题，不是正式内容 |
| `notice_login` 正式公告 | 表为空；不阻塞启动，但无法体验公告内容 |
| 登录库 `help` | 表为空且独立登录服源码缺失；无法还原正式帮助内容 |

### 4.4 P2：停用功能恢复时才需要

| 缺失来源 | 代码状态 |
|---|---|
| `activity.json`、`timing.json` | 活动开放初始化已停用；仓库无同源表 |
| `zhuanpan_config.json`、`zhuanpan_key.json`、`zhuanpan.json` | 转盘初始化已停用；仓库无同源表 |

`LoginReward.json`、`jijin.json` 虽然服务端缺文件，但客户端同源表完整，不需要用户补充。

## 5. 仓库已有数据，不需要用户重做

| 本地空表 | 仓库候选来源 | 下一步 |
|---|---|---|
| `shop` | `server/sql/_all_sql.sql`，196 条 | 先在隔离库校验字段和版本，再导入 |
| `fight_cg` | `server/sql/sql_kp.txt`，1 条 | 校验回放格式后导入 |
| `huodong_info` | `server/sql/sql.txt`，26 条 | 检查编码、字段和活动版本 |
| `huodong_award` | `server/sql/sql.txt`，139 条 | 与 `huodong_info` 成套校验 |
| `huodong_exchange` | `server/sql/sql.txt`，15 条 | 与活动 ID 对齐后导入 |
| `hd_bang_goods` | `server/sql/sql.txt`，1 条 | 校验活动依赖后导入 |

## 6. 下一轮修复顺序

1. 先用客户端同源表回建 8 个损坏/空缺服务端配置，并修复任务 XML 转义。
2. 获取唯一 P0 真缺源：`fabao_looting.json`。
3. 让 `local_test=1` 执行完整配置初始化，但对确认缺源的停用活动保持开关隔离。
4. 按初始化顺序逐个启用：角色属性 → 技能/物品 → 装备/宠物 → 地图关卡 → 商店/体力 → 活动。
5. 每启用一个模块，执行对应协议 smoke，并扫描 SQL、Lua、assert、crash。
6. 数据源缺失的模块停在“缺配置”，不通过代码伪造正式数值。
7. 最后进行 L6 客户端逐 UI 点击验收。
