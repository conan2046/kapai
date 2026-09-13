# 配置缺口待办台账

> 建立：2026-09-13
> 主源：`FEATURE_CONFIG_SOURCES.md` §4「数据源缺口」+ §5「仓库已有数据」
> 复核方式：对 2026-07-14 版台账**逐项实测**（JSON/XML 可解析性、文件存在性、SQLite 实表行数）
> 配套：`docs/config-map/config-map.html`（页脚有精简版）、`XML_ORPHAN_AUDIT.md`、`DECOMMISSION_REGISTER.md`

---

## 0. 结论先行

**2026-07-14 版台账的 9 项"损坏/缺源"已全部闭环**；答题题库已确认并接入；仍需推进的是 **13 项**（数据补录 7 项 + 候选导入 6 项）。

| 状态 | 项数 | 说明 |
|---|---:|---|
| 已闭环 | **9** | 原 §4.1 可回建 8 项 + §4.2 P0 1 项，实测均已修好 |
| 待办 · 需补数据 | **7** | §4.3 P1：6 张 SQLite 空表 + 公告内容；题库已闭环 |
| 待办 · 候选已存在 | **6** | §5：仓库 SQL 里有 INSERT，本地表仍空，需校验后导入 |
| 已停用（非缺源） | **5 文件** | §4.4：功能停用时才需要 |

---

## 1. 已闭环（07-14 记为问题，09-13 实测已修复）

### 1.1 原 §4.1「服务端缺/坏，客户端有同源表可回建」— 8 项全部已修

| # | 文件 | 07-14 问题 | 09-13 实测 | 结论 |
|---:|---|---|---|---|
| 1 | `server/config/json/function.json` | 损坏（无法解析） | 可解析，**120 条**（42668 B） | ✔ 已修复 |
| 2 | `server/config/json/mission_dialog.json` | 损坏 | 可解析，**662 条**（154106 B） | ✔ 已修复 |
| 3 | `server/config/xml/mission_config.xml` | 非法字符 | 可解析，根 `CONFIGS`，**340 子元素** | ✔ 已修复 |
| 4 | `server/config/xml/mission_dialog.xml` | 非法字符 | 可解析，根 `CONFIGS`，**662 子元素** | ✔ 已修复 |
| 5 | `server/config/json/jingjie_config.json` | 缺文件 | 存在，**20 条**（4593 B） | ✔ 已回建 |
| 6 | `server/config/json/LoginReward.json` | 缺文件 | 存在，**7 条**（478 B） | ✔ 已回建 |
| 7 | `server/config/json/jijin.json` | 缺文件 | 存在，**42 条**（3253 B） | ✔ 已回建 |
| 8 | `server/config/json/guild_reward.json` | 空数组 `[]` | **6 条**（374 B） | ✔ 已回建 |
| 9 | `server/config/json/revert.json` | 空数组 `[]` | **10 条**（1966 B） | ✔ 已回建 |

> ⚠ 第 3/4 项修复后需确认 **服务端加载函数是否已启用** —— `mission_manager.cpp:1835-1837` 的 `ReadMissionConfig()` / `ReadMissionDialogConfig()` / `ReadMubiaoConfig()` 三行**仍处于整段注释状态**（另见 `docs/STORY_DIALOGUE_SYSTEM.md`）。**文件可解析 ≠ 已被加载。**

### 1.2 原 §4.2「P0 唯一真缺源」— 已解决

| 文件 | 07-14 | 09-13 实测 | 结论 |
|---|---|---|---|
| `server/config/json/fabao_looting.json` | 代码明确读取，服务端/客户端/SQL 三处均无 | **存在，264 条**（8869 B），可解析 | ✔ **P0 解除** |

> 引用点：`server/src/pet_equip_manage.cpp:380`（`m_faBaoSS`）/ `:1321 GetFaBaoSouSuo`。
> 遗留：客户端 `ConfigData/fabao_looting_dat.lua` 是否已补齐导出，未核对。

---

## 2. 待办 A · 需补数据（7 项）

实测库：`C:\Users\Admin\AppData\LocalLow\Xuancai\ProjectX\LocalServer\projectx.db`（只读查询，2.3 MB）

### 2.1 SQLite 空表 — 需 INSERT 数据（6 项）

| # | 表名 | 07-14 | 09-13 实测 | 影响功能 | 建议动作 | 责任人 | 状态 |
|---:|---|---|---|---|---|---|---|
| 1 | `arena_robot` | 0 行 | **0 行** | 竞技场机器人模板 | 需提供机器人模板数据 | | |
| 2 | `shilian_robot` | 0 行 | **0 行** | 试炼机器人模板 | 需提供机器人模板数据 | | |
| 3 | `hd_7ridenglu` | 0 行 | **0 行** | 服务端七日奖励 | 需提供七日奖励配置 | | |
| 4 | `hd_exchange_list` | 0 行 | **0 行** | 活动兑换列表 | 需提供兑换配置 | | |
| 5 | `festival_award` | 0 行 | **0 行** | 节日奖励 | 需提供节日奖励配置 | | |
| 6 | `money_giftbag_huodong` | 0 行 | **0 行** | 现金礼包活动 | 需提供礼包活动配置 | | |

> 这 6 张在 `server/sql/` 下**未发现 INSERT 语句**，属真正需要策划/运营补录的数据。

### 2.2 内容类 — 表有行但内容待确认（1 项）

| # | 表名 | 07-14 | 09-13 实测 | 问题 | 建议动作 | 责任人 | 状态 |
|---:|---|---|---|---|---|---|---|
| 7 | `notice_login`（正式公告） | 0 行 | **0 行** | 表结构已修复，但无公告内容 | 不阻塞启动，空表 = "无公告"的正常状态；需要内容时再补 | | |

> `question` 已于 2026-09-13 闭环：`outputs/answer-question-bank/question.xlsx` 的 38 道中文文物题已导出到 `server/config/source/question.csv`，并同步 SQLite/MySQL；英文占位题为 0。ID 25/26 题干相同但答案不同，作为内容校对项保留，不再计入“缺数据”。

> 另有 `help`（登录库帮助，0 行）—— 07-14 记为"独立登录服源码缺失，无法还原正式内容"。本次库中 `help` 表存在且 0 行，**正式内容仍缺**。作为独立登录服遗留项单独登记，不计入上方 13 项 Steam 单机版数据待办。

| # | 表名 | 09-13 实测 | 问题 | 建议动作 | 责任人 | 状态 |
|---:|---|---|---|---|---|---|
| 8 | `help` | 0 行 | 独立登录服源码缺失 | 无法还原正式帮助内容；本地返回空列表 | | |

---

## 3. 待办 B · 候选数据已在仓库，需校验后导入（6 项）

07-14 §5 记为"仓库已有数据，不需要用户重做"，09-13 复核：**候选源仍在，本地表基本仍空**。

| # | 本地空表 | 候选来源 | 候选条数（09-13 实测） | 本地表当前行数 | 建议动作 | 责任人 | 状态 |
|---:|---|---|---:|---:|---|---|---|
| 1 | `shop` | `server/sql/_all_sql.sql` | **196** | 0 | 隔离库校验字段与版本后导入 | | |
| 2 | `fight_cg` | `server/sql/sql_kp.txt` | **1** | 0 | 校验回放格式后导入 | | |
| 3 | `huodong_info` | `server/sql/sql.txt` | **26** | 0 | 检查编码、字段、活动版本 | | |
| 4 | `huodong_award` | `server/sql/sql.txt` | **139** | **1** | 与 `huodong_info` 成套校验 | | |
| 5 | `huodong_exchange` | `server/sql/sql.txt` | **15** | 0 | 与活动 ID 对齐后导入 | | |
| 6 | `hd_bang_goods` | `server/sql/sql.txt` | **1** | 0 | 校验活动依赖后导入 | | |

> ⚠ **观察口径提示**：本次查库时 `item` / `item_template` / `user_info` / `global_variable` / `dailysign` **均为 0 行**，`role_info` 仅 2 行 —— 该库处于**配置未灌入的干净态**（夹具重置后）。因此"本地表为空"反映的是**当前未导入**，不等于配置本身缺失。导入前建议先确认库状态是否符合预期。

---

## 4. 已停用 · 恢复功能时才需要（5 文件）

| # | 文件 | 状态 | 说明 |
|---:|---|---|---|
| 1 | `server/config/json/activity.json` | 不存在 | 活动开放初始化已停用（`InitHuoDongCfg()` 直接 return）；仓库无同源表 |
| 2 | `server/config/json/timing.json` | 不存在 | 同上 |
| 3 | `server/config/json/zhuanpan_config.json` | 不存在 | 转盘初始化已停用；仓库无同源表 |
| 4 | `server/config/json/zhuanpan_key.json` | 不存在 | 同上 |
| 5 | `server/config/json/zhuanpan.json` | 不存在 | 同上 |

> 与"已停用"判定一致：**文件不存在是有意为之**，不是漏做。恢复对应功能时才需要补表。

---

## 5. 本轮新发现（不在 07-14 台账内）

### 5.1 SQLite 运行时动态建表（工具链新事实）

`schema` 文件里只有 `login_log_7`，但实测库中存在 **`login_log_8`** 和 **`login_log_9`** —— 说明服务端有**运行时按序建分表**的逻辑。后续任何"表清单完整性"校验都必须允许这类动态表。

### 5.2 SQLite 表数四口径（务必区分）

| 口径 | 数量 | 含义 |
|---|---:|---|
| 实测库 `sqlite_master` | **180** | 含 `sqlite_sequence`（内部表）+ `login_log_8/9`（运行时动态建） |
| 实测库业务表 | **179** | 180 − `sqlite_sequence` |
| `001_initial_schema.sql` 内 `CREATE TABLE` | **177** | schema 文件定义的静态表 |
| manifest 清单 `tables[]` | **174** | 不含 `schema_version` / `answer_settings` / `answer_daily_progress` |
| manifest 自报 `validation.tableCount` | **175** | 含 `schema_version` |

> 收敛关系：**177 = 174 + schema_version + answer_settings + answer_daily_progress**；**180 = 177 + login_log_8 + login_log_9 + sqlite_sequence**。

### 5.3 行数变化（相对 07-14）

| 表 | 07-14 | 09-13 | 备注 |
|---|---:|---:|---|
| `question` | 21 | **38** | 已确认为中文文物题库并完成 SQLite/MySQL 同步；英文占位题 0 行 |
| `huodong_award` | 0 | **1** | 增加 1 行 |

---

## 6. 建议推进顺序

1. **先确认 `fabao_looting` 客户端导出是否已补齐**（P0 服务端已解除，客户端侧未核对）
2. **确认任务表加载是否已启用** —— `mission_manager.cpp:1835-1837` 三行仍注释；文件可解析但未加载
3. **6 张 SQLite 空表补数据**（待办 A 第 1–6 项）—— 需策划/运营提供
4. **6 项候选数据校验后导入**（待办 B）—— 有现成 SQL，成本最低，建议先做
5. 记录 `login_log_*` 动态建表规则，避免后续表清单校验误报

---

## 7. 诚实边界

- **未验证**：`fabao_looting` 客户端 `_dat.lua` 是否存在；`help` 表对应登录服是否真的缺失源码。
- **未验证（本轮无法做）**：workspace-local MySQL 中对应表的行数 —— 查 MySQL 需启动服务，本轮为只读静态审计，未启动任何进程。上文 §2/§3 的"本地表行数"全部来自 **Unity SQLite（`projectx.db`）**，MySQL 侧可能不同。
- **口径限制**：实测库处于配置未灌入的干净态（`item`/`item_template`/`user_info` 均 0 行），"表为空"只反映**当前未导入**。且该库为设备上最后一次运行留存，不代表其他设备。
- **未做**：`server/sql/sql.txt` 与 `_all_sql.sql` 中 INSERT 数据的**字段/版本一致性校验**（07-14 文档已提示"需确认版本和编码后导入"，本轮未做该校验）。
- 时间跨度：07-14 → 09-13 共 2 个月，期间的修改可能来自其他人；本台账只比对**首尾状态**，不追踪变更过程。
