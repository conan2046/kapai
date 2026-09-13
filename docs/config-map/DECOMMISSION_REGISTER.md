# 配置表废弃 / 保留观察登记册

> 建立日期：2026-09-13
> 依据：`docs/config-map/XML_ORPHAN_AUDIT.md`（详细证据与 file:line）
> 用途：登记**已确认无加载路径**的配置产物与二进制表，供后续同步 concept 源表、清理打包体积、或恢复功能时查阅
> **重要：本轮未改动任何 `server/config/*` 或 `client/ProjectX/res/*` 文件。** 本册仅为标记台账。

---

## 0. 处置决定（2026-09-13 用户确认）

| 类别 | 处置 | 文件动作 |
|---|---|---|
| ③ 仅 Cocos 二进制引用（4 张） | **保留**（正常跨端分工，非缺陷） | 无 |
| ④ 死包体：`.dat` 在、无加载器（4 张） | **保留观察**，不删除 | 无 |
| ⑤ 真废弃：三端零引用（6 张） | **标记废弃候选**，不删除 | 无 |
| ② JSON 已取代（10 张） | 归档口径，不删除 | 无 |

**为什么不直接改文件**：`server/config/xml/*.xml` 与 `client/ProjectX/res/ConfigData/*.dat` 均为 `concept/data/excel/转表工具/xl转表.exe` 的输出产物，直接编辑会在下次转表时被覆盖。若要在产品文件内留下永久标记，必须**同步修改 concept 源表**（`concept/data/excel/xml配置表/新表/` 下对应 xlsx 或源 XML）。

---

## 1. ⑤ 废弃候选（6 张）— 三端零引用、无 `.dat`

标记：**`废弃候选`**（网页配置表列显示灰删除线徽标）

| # | 表名 | 服务端文件 | 曾声称用途 | 实际替代链路（file:line） |
|---:|---|---|---|---|
| 1 | `Function_Level` | `server/config/xml/Function_Level.xml` | 功能开放/红点等级门槛 | `function.json` → `CSystemOpenCfgMananger::Init`（`init.cpp:2276→2279`）。客户端 `LDataConstMgr.lua:2905-2916` 加载函数**整段注释**，注释内读的是 `ConfigData/Function.dat` |
| 2 | `rank_reward` | `server/config/xml/rank_reward.xml` | 排行榜奖励 | `reward_rank.json` → `award_manager.cpp:84` |
| 3 | `random_map` | `server/config/xml/random_map.xml` | 随机地图生成 | `maplist.json` / `bigmap.json` + 服务端逻辑 |
| 4 | `shenjiang_zhekou` | `server/config/xml/shenjiang_zhekou.xml` | 神将折扣 | 活动类型 `HD_SHENJIANG_ZHEKOU = 84`（`huo_dong.h:662`、`pack_deal.cpp:14077`） |
| 5 | `chuangguan_battle` | `server/config/xml/chuangguan_battle.xml` | 闯关战斗配置 | `CChuangGuanMapManager::Init`（`xun_bao_manage.cpp:70`）只加载 `chuangguan.xml` + `kunlun.json` + `sanjie{,_cost,_dialogue}.json` |
| 6 | `pet_level_up_exp` | `server/config/xml/pet_level_up_exp.xml` | 神将升级经验 | `exp.json` → `CPetCfgManager::Init`（`pet.cpp:79`）。该 Init 加载的 10 张表中不含本表 |

**恢复路径**（若日后确认需要）：从 `server/config/xml/` 取回文件 → 在对应 `Init()` 中补 `CXMLReader reader("xxx.xml")` → 在 `InitXMLConfig()`（`init.cpp:50`）确认 `local_test` 分支不跳过。

---

## 2. ④ 保留观察（4 张）— `.dat` 已随包发布但客户端无加载器

标记：**`保留观察`**（网页显示虚线黄徽标）

| # | 表名 | 服务端 XML | 客户端 `.dat` | 体积 | 说明 |
|---:|---|---|---|---:|---|
| 1 | `arrt_type` | `xml/arrt_type.xml` | `res/ConfigData/arrt_type.dat` | 637 B | 服务端已被 `attr_type.json` 取代（`CAttrCfgMgr::Init init.cpp:1848`）。客户端真实树 0 引用。**⚠ 本表未挂到任何模块依赖清单**（无模块引用它），仅登记在册 |
| 2 | `find_resource` | `xml/find_resource.xml` | `res/ConfigData/find_resource.dat` | 516 B | 服务端资源找回读 `revert.json`（`CFindResourceManager::Init init.cpp:2073`）。`find_resource` 一词仅存于协议名 `PRO_FIND_RESOURCE = 52`（`protocol.h:108`） |
| 3 | `pet_equip_attr` | `xml/pet_equip_attr.xml` | `res/ConfigData/pet_equip_attr.dat` | 2.4 KB | 客户端无加载器。设计口径见 `docs/HERO_SKILL_EQUIPMENT_BUILD_DESIGN.md:306`（`curve_id / tier / min_value / max_value`）。服务端词条走 `equipment_affix.json`（`pet_equip_manage.cpp:167`） |
| 4 | `pet_equip_part` | `xml/pet_equip_part.xml` | `res/ConfigData/pet_equip_part.dat` | **52 B** | 三端全树 0 引用。52 B ≈ 空表头，疑似从未写入数据 |

**影响**：这 4 个 `.dat` 永久占用打包体积但永不加载。合计约 **3.6 KB**，实际影响可忽略，故决定保留观察。

**待确认（未做）**：未解析 `.dat` 二进制内容，未核实 52 B 的 `pet_equip_part.dat` 是否真为空表。

---

## 3. ② JSON 已取代（10 张）— 归档口径

这 10 张 XML 无服务端加载路径，但同名 JSON 已在加载，属**转表前遗留**。**不是缺陷，不需处置**，登记以备溯源。

| XML | JSON 孪生 | JSON 加载点 |
|---|---|---|
| `drop_matching.xml` | `drop_matching.json` | `server/src/award_manager.cpp:657` |
| `fight_config.xml` | `fight_config.json` | `server/src/fight.cpp:204` |
| `hecheng.xml` | `hecheng.json` | `server/src/pet_equip_manage.cpp:331` |
| `jingjie_config.xml` | `jingjie_config.json` | `server/src/init.cpp:2584` |
| `level_reward.xml` | `level_reward.json` | `server/src/award_manager.cpp:33` |
| `monster_boss_basic.xml` | `monster_boss_basic.json` | `server/src/monster.cpp:579` |
| `reward.xml` | `reward.json` | `server/src/award_manager.cpp:129` |
| `suit.xml` | `suit.json` | `server/src/pet_equip_manage.cpp:416` |
| `zhenfa_config.xml` | `zhenfa_config.json` | `server/src/init.cpp:1689` |
| `zhenfa_level.xml` | `zhenfa_level.json` | `server/src/init.cpp:1697` |

---

## 4. ③ 保留：仅 Cocos 二进制引用（4 张）— **不可删**

登记原因：这 4 张服务端不读、客户端读，**属正常跨端分工**，勿误判为死表。

| XML | 客户端 `.dat` | 活跃调用链 |
|---|---|---|
| `pet_equip.xml` | `pet_equip.dat` (11.3 KB) | `LDataConstMgr.lua:2370 LoadPetEquipData` ← `:2405 GetPetEquipCfgData` ← `PetEquipTipsUI.lua:106`、`PetEquipStrengthenUI.lua:258`、`MailUI.lua:751`、`MysteryShop.lua:120`、`ZaDanShop.lua:41`、`ItemInfoUI.lua:469` |
| `pet_equip_qianghua.xml` | `pet_equip_qianghua.dat` (585 B) | `LDataConstMgr.lua:2455 LoadPetEquipQHData` ← `:2496 GetPetEquipQHCfgData` ← `PetEquipStrengthenUI.lua:194/207/298/322`、`PetEquipResolveUI.lua:875`、`PetEquipTipsUI.lua:182`、`PetEquipSubUI.lua:1172` |
| `equip_star.xml` | `equip_star.dat` (298 B) | `LDataConstMgr.lua:2519 LoadPetEquipStarData` ← `:2552 GetPetEquipStarCfgData` ← `PetEquipTipsUI.lua:519/624`、`PetEquipStrengthenUI.lua:62`、`PetEquipResolveUI.lua:870` |
| `guild_based.xml` | `guild_based_client.dat` (1.2 KB) | `client/ProjectX/frameworks/runtime-src/Classes/Game/Data/GameDataMgr.cpp:406` |

> **跨端口径提示**：`pet_equip*.xml`（客户端）与 `equip*.json` / `equip_qianghua.json`（服务端）是同一套策划数值的两份导出。字段一致性**已由另一功能验证**（2026-09-13 用户确认），本册不重复比对。

---

## 5. 汇总

| 类别 | 张数 | 处置 | 文件是否改动 |
|---|---:|---|---|
| ⑤ 废弃候选 | 6 | 标记 | 否 |
| ④ 保留观察 | 4 | 标记 | 否 |
| ② JSON 已取代 | 10 | 登记 | 否 |
| ③ 仅 Cocos 引用 | 4 | 保留 | 否 |
| **合计** | **24** | — | — |

（另有 `pet_basic_config.xml` 属 Unity 专属引用，**不是**废弃配置，不计入本册。）

---

## 6. 后续动作（如需在产品文件内落地标记）

由于产物会被转表覆盖，正式标记需走源表：

1. 在 `concept/data/excel/xml配置表/新表/` 对应源表增加"状态=废弃"列或备注
2. 重跑 `concept/data/excel/转表工具/xl转表.exe`
3. 或由主程决定：在 `server/config/xml/` 增设 `_deprecated/` 子目录并在 `InitXMLConfig()` 中确认无引用（本轮**未执行**）

**本册不自行执行以上动作，需用户/主程明确指令。**
