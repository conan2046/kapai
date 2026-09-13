# server/config/xml 废弃配置审计报告

> 审计日期：2026-09-13
> 范围：`server/config/xml/` 下全部 76 个 XML 的加载路径追踪
> 触发：配置映射网页中 14 张表"未见按名硬引用"，需确认是动态加载还是死表
> 结论口径：只依据**可复现的字面量/调用点证据**，不推断

---

## 1. 结论先行

76 个服务端 XML 中，**52 个**被 `CXMLReader reader("xxx.xml")` 字面量加载，**25 个**未被服务端任何字面量引用。对这 25 个逐一追查加载路径后，**仅 6 个为真废弃**（无任何引用方），另外 19 个分属三种仍活着的机制：

| 分类 | 数量 | 机制 | 处置建议 |
|---|---:|---|---|
| ① 服务端字面量加载 | 52 | `CXMLReader reader("*.xml")` | 正常 |
| ② JSON 已取代 | 10 | XML 与 JSON 同名，代码读 JSON（XML 为转表前遗留） | 可归档，勿删（保留源表对应关系） |
| ③ 仅 Cocos 二进制引用 | 4 | XML → `res/ConfigData/*.dat` → Cocos Lua/C++ 加载器 | **不可删**，客户端依赖 |
| ④ 半废弃（.dat 在、无加载器） | 4 | `.dat` 已打包但客户端无读取代码 | 待确认：删 .dat 还是补加载器 |
| ⑤ 真废弃 | 6 | 三端零引用、无 `.dat` | 可标记废弃 |
| ⑥ Unity 专属 | 1 | Unity C# 直接读，服务端不加载 | 正常（跨端口径差异） |
| **合计** | **77\*** | \* 76 个文件 + `attr_type`/`arrt_type` 双拼写计入 | |

> 说明：口径为"未被服务端字面量加载"= 25 个，其中 ① 之外的 25 个构成本报告主体。`pet_basic_config` 归 ⑥。

---

## 2. 加载机制（已坐实）

```
main.cpp:404  ConfigInit()
                ├─ InitJsonConfig()   init.cpp:21   ← 7 个 Manager
                └─ if(local_test==1) return true;   ← ⚠ XML 配置被整体跳过
                   InitXMLConfig()    init.cpp:50   ← 24 个 Manager::Init()
```

- XML 统一入口：`CXMLReader reader("文件名.xml")`，硬编码字面量，**无目录扫描、无动态拼接**。
- 因此"未被字面量引用"= 不会被服务端加载，不存在"动态拼接漏检"的可能。
- `InitXMLConfig()` 共 24 处 `Init()` 调用（init.cpp:53-120），逐一核对后**没有任何一个加载本报告 ⑤ 类文件**。

---

## 3. 逐表判定

### 3.1 ② JSON 已取代（10 个）— XML 为转表前遗留

| XML | JSON 孪生 | JSON 实际加载点 |
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

**证据**：以上 10 个 XML 均无字面量引用；同名 JSON 均已确认存在且被上述行号加载。与 `FEATURE_CONFIG_SOURCES.md` §3"仓库另有旧 xxx.xml"的表述一致。

### 3.2 ③ 仅 Cocos 二进制引用（4 个）— **不可删**

| XML | 客户端产物 | 活跃调用链（file:line） |
|---|---|---|
| `pet_equip.xml` | `res/ConfigData/pet_equip.dat` (11.3 KB) | `LDataConstMgr.lua:2370 LoadPetEquipData` ← `:2405 GetPetEquipCfgData` ← `View/Common/PetEquipTipsUI.lua:106`、`View/Pet/PetEquipStrengthenUI.lua:258`、`View/Mail/MailUI.lua:751`、`View/Shop/MysteryShop.lua:120`、`View/Shop/ZaDanShop.lua:41`、`View/Common/ItemInfoUI.lua:469` |
| `pet_equip_qianghua.xml` | `res/ConfigData/pet_equip_qianghua.dat` (585 B) | `LDataConstMgr.lua:2455 LoadPetEquipQHData` ← `:2496 GetPetEquipQHCfgData` ← `PetEquipStrengthenUI.lua:194/207/298/322`、`PetEquipResolveUI.lua:875`、`PetEquipTipsUI.lua:182`、`PetEquipSubUI.lua:1172` |
| `equip_star.xml` | `res/ConfigData/equip_star.dat` (298 B) | `LDataConstMgr.lua:2519 LoadPetEquipStarData` ← `:2552 GetPetEquipStarCfgData` ← `PetEquipTipsUI.lua:519/624`、`PetEquipStrengthenUI.lua:62`、`PetEquipResolveUI.lua:870` |
| `guild_based.xml` | `res/ConfigData/guild_based_client.dat` (1.2 KB) | `client/ProjectX/frameworks/runtime-src/Classes/Game/Data/GameDataMgr.cpp:406`（Cocos C++ 层） |

**要点**：这 4 张表是"服务端不读、客户端读"的**正常跨端分工**，不是缺陷。服务端用 JSON（`equip.json` / `equip_qianghua.json`），客户端用 `.dat`。差异在于：**同名逻辑两套数据源，字段漂移风险需要单独核对**（参见 `docs/HERO_SKILL_EQUIPMENT_BUILD_DESIGN.md`）。

**误判修正**：初版扫描把这 4 张标为"未见按名硬引用，疑动态拼接"——错。真实机制是 `.dat` 二进制管线 + 懒加载 getter，按"服务端字面量"扫描必然漏掉。

### 3.3 ④ 半废弃：`.dat` 在但客户端无加载器（4 个）

| XML | 客户端产物 | 判定依据 |
|---|---|---|
| `arrt_type.xml` | `res/ConfigData/arrt_type.dat` (637 B) | 真实客户端树 `client/ProjectX/src` **0 引用**；服务端已被 `attr_type.json` 取代（`CAttrCfgMgr::Init init.cpp:1844→1848`）。唯一命中在 `frameworks/runtime-src/proj.android_ad1/assets/` 的乱码副本，非源码 |
| `find_resource.xml` | `res/ConfigData/find_resource.dat` (516 B) | 客户端 **0 引用**；服务端 `CFindResourceManager::Init`（`init.cpp:2073`）读的是 `revert.json`。`find_resource` 一词仅存于协议名 `PRO_FIND_RESOURCE = 52`（`protocol.h:108`） |
| `pet_equip_attr.xml` | `res/ConfigData/pet_equip_attr.dat` (2.4 KB) | 客户端 **0 引用**；设计口径见 `docs/HERO_SKILL_EQUIPMENT_BUILD_DESIGN.md:306`（`curve_id / tier / min_value / max_value` = 统一词条数值曲线）。服务端词条走 `equipment_affix.json`（`pet_equip_manage.cpp:167`） |
| `pet_equip_part.xml` | `res/ConfigData/pet_equip_part.dat` (**52 B**) | 三端**全树 0 引用**；`.dat` 仅 52 字节 ≈ 一个空表头，疑似从未写入数据 |

**待决**：这 4 张 `.dat` 已随包发布但永不加载，属**死包体**。二选一——(a) 确认废弃则从 `res/ConfigData/` 移除；(b) 若策划仍要该数值，需补客户端加载器。**需策划/主程确认，本报告不下结论。**

### 3.4 ⑤ 真废弃（6 个）— 三端零引用、无 `.dat`

| XML | 曾声称的用途 | 实际替代链路 | 证据 |
|---|---|---|---|
| `Function_Level.xml` | 功能开放/红点（FEATURE_CONFIG_SOURCES.md:47） | `function.json` → `CSystemOpenCfgMananger::Init`（`init.cpp:2276→2279`） | 客户端 `LDataConstMgr.lua:2905-2916` 的 `LoadFunctionLevelData` **整段注释**，且注释里读的是 `ConfigData/Function.dat`；无 `Function_Level.dat` |
| `rank_reward.xml` | 排行榜奖励 | `reward_rank.json` → `award_manager.cpp:84` | 无 `.dat`；仅 `docs/COCOS_ANSWER_SYSTEM.md:477/483` 提及"旧文件 `rank_reward.xml` 也只有 `type=1~14`" |
| `random_map.xml` | 随机地图生成 | `maplist.json` / `bigmap.json` + 服务端逻辑 | 无 `.dat`，全树 0 引用 |
| `shenjiang_zhekou.xml` | 神将折扣 | 活动类型 `HD_SHENJIANG_ZHEKOU = 84`（`huo_dong.h:662`、`pack_deal.cpp:14077`） | 无 `.dat`，全树 0 引用 |
| `chuangguan_battle.xml` | 闯关战斗配置 | `CChuangGuanMapManager::Init`（`xun_bao_manage.cpp:70`）只加载 `chuangguan.xml` + `kunlun.json` + `sanjie{,_cost,_dialogue}.json` | 无 `.dat`，全树 0 引用 |
| `pet_level_up_exp.xml` | 神将升级经验 | `exp.json` → `CPetCfgManager::Init`（`pet.cpp:79`） | `CPetCfgManager::Init`（`pet.cpp:9-300`）加载 10 张表：`hero.json`/`exp.json`/`pet_born_skill_LvUp.xml`/`pet_skill_LvUp.xml`/`pet_skill_add.xml`/`pet_quality.xml`/`pet_star.xml`/`pet_star_step.xml`/`pet_xiulan.xml`/`pet_type_attr_ratio.xml` — **不含本表** |

### 3.5 ⑥ Unity 专属（1 个）

| XML | 引用方 |
|---|---|
| `pet_basic_config.xml` | Unity `Data/HeroCatalog.cs:121`（`Resources.Load<TextAsset>("Configs/pet_basic_config")`）。服务端不加载——服务端神将基础走 `hero.json`（`pet.cpp:25`）。**已知三端三套来源缺陷**，见配置映射网页「神将」模块备注 |

---

## 4. 对配置映射网页的修正

以下条目已按本报告更新（`docs/config-map/_build_config_map.py` → `_TL` 表）：

| 表 | 修正前 | 修正后 |
|---|---|---|
| `pet_equip` / `pet_equip_qianghua` / `equip_star` | 未登记 | 新增为**装备模块依赖**（仅 Cocos 二进制），并补入 `装备基础`(+3 张) 与 `装备强化`(+2 张) 依赖集 |
| `pet_equip_attr` / `pet_equip_part` | 未登记 | 新增，标注半废弃/废弃 |
| `find_resource` | "协议 PRO_FIND_RESOURCE" | 改为半废弃 + 真实替代链 `revert.json` |
| `guild_based` | "未见按名硬引用" | 改为"仅 Cocos C++ 层引用 `guild_based_client.dat`" |
| `arrt_type` | "遗留同义表" | 改为"半废弃，已被 `attr_type.json` 取代" |
| `Function_Level` / `rank_reward` / `random_map` / `shenjiang_zhekou` / `chuangguan_battle` / `pet_level_up_exp` | "未见按名硬引用" | 改为"真废弃" + 实际替代链路 file:line |

---

## 5. 处置决定（2026-09-13 用户确认）

| 事项 | 决定 |
|---|---|
| ④ 类 4 个死包体（`arrt_type.dat` / `find_resource.dat` / `pet_equip_attr.dat` / `pet_equip_part.dat`） | **不移除，全部保留**。网页标记为 <kbd>保留观察</kbd> |
| ③ 类 `.xml`/`.dat` 与 `.json` 字段漂移比对 | **已由另一功能验证，本轮不做** |
| ⑤ 类 6 个真废弃 | **标记为 <kbd>废弃候选</kbd>，文件不删除** |

**执行方式**：本轮**未改动任何 `server/config/*` 或 `client/ProjectX/res/*` 文件**。标记仅落在两处：
1. 配置映射网页「配置表依赖」列的徽标（灰删除线 = 废弃候选；虚线黄 = 保留观察）
2. 登记册 `docs/config-map/DECOMMISSION_REGISTER.md`

**原因**：`server/config/xml/*.xml` 与 `res/ConfigData/*.dat` 均为 `xl转表.exe` 的输出产物，直改会在下次转表被覆盖。若要在产品文件内留永久标记，须同步改 `concept/data/excel/xml配置表/新表/` 源表后重跑转表 —— **待明确指令，本报告不自行执行**。

---

## 5.1 遗留未做项

1. `.dat` 二进制内容未解析（未核实 52 B 的 `pet_equip_part.dat` 是否真为空表）。
2. ③ 类字段一致性比对 —— 已由另一功能覆盖，本报告不再列入待办。
3. `server/config/json` 计数漂移（实测 67 vs `FEATURE_CONFIG_SOURCES.md` 记 59）未逐项核对。

---

## 6. 诚实边界

- 本报告的"零引用"判定基于**字面量扫描**（`server/src`+`server/script` 全部 377 文件、客户端真实树 `client/ProjectX/src` + `frameworks/`、Unity `Assets/ProjectX/src`），匹配模式为 `"name.xml"` / `.dat` 路径 / `function 名` / `Load("name")` / `ConfigName` 等实际加载惯用式。若存在运行时字符串拼装（如从配置反查表名再加载）的极端写法，可能漏判——但已确认 `CXMLReader` 不支持该用法。
- 未验证：`proj.android_ad1/assets/` 下的 Android 打包副本内容（文件为无换行的非常规格式），仅确认其**不是**真实源码树。
- 未做：`.dat` 二进制内容解析（未核实 52 B 的 `pet_equip_part.dat` 是否真为空表）。
- 未做：③ 类 `.dat` 与 JSON 孪生的**逐字段一致性比对**。
- `server/config/xml` 76 个文件计数与 `FEATURE_CONFIG_SOURCES.md` §1 "76"一致；`json` 该文档记 59，本次实测 **67**（存在 8 个新增/漏记，未逐项核对）。
