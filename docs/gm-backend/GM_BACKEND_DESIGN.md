# GM 后台设计方案（kapai 单机 Unity + SQLite）

> 状态：设计稿 **v1.6（在线存档锁定与等级实时同步）**
> **重大修订**：服务端**已有完整 GM 控台**（`MSG_MGR` 管理协议 + `DoGMString` 聊天 GM 指令）。因此**不自建 Unity 指令层**——直接复用现有服务端接口，Web 后台做成"服务端管理协议的客户端"即可。
> 确认结论：纯网页端 + 邮件投递（复用 existing op 15）；无游戏内调试面板；仅运行时转发。
> **v1.4 变更**：服务端改动已落地——① `g_database.cpp` 注册 SQLite `md5()` 函数；② `admin` 表补建 `userId/name/pwd` 列 + GM 账号 + `admin_log` 表（两份 schema 均更新，并提供已有库迁移脚本 `migrate_admin.py`）。**VIP 发放按用户决策取消（Steam 单机无 VIP），§3b 保留为参考但不再实施。**
> **v1.5 变更**：移除登录失败后的 op13 密码自愈；服务端永久禁用 op13；修复下拉误执行和整数截断；op1/op2/op5 返回 `OK|/ERR|` 可判定结果，客户端严格校验响应类型与 op。
> **v1.6 变更**：新增 op21 查询唯一在线存档角色；所有变更操作执行前强制核对目标 roleId；op5 同步数据库与在线内存，并推送 `/226` 让 Unity HUD 和存档列表立即刷新。

---

## 1. 现有服务端 GM 设施（已实测源码定位）

| 能力 | 位置 | 说明 |
|---|---|---|
| **管理协议** | `pack_deal.cpp` `MSG_MGR` op 分发 | 服务端控台主接口，op 10~16+ |
| GM 登录 | op 11 | `select userId,pwd from admin where userID=... and pwd=MD5(...)` → 成功则 `SetAdminLevel(ADMIN_LEVEL)` |
| 改密码 | op 12 | `update admin set pwd=MD5(...) where name=...` |
| **裸执行 SQL** | op 13 | **已永久禁用**，只返回 `ERR|op13 raw SQL disabled` |
| 全服广播 | op 10 / op 14 | `SendSysChannelMsg` / `SysInfoToAllUser` |
| **发资源邮件** | **op 15** | `roleId,itemId,num,money,YB,message` → `SMailData` + `SendSystemMail(roleId,msg,&mdata)` |
| 全服邮件 | op 16 | 对所有在线玩家发系统邮件（`SysMailToAllUser`） |
| 邮件红点通知 | op 17 | `SendHotPointStatus(... EHPoint_Mail ...)` 提示玩家有新邮件 |
| **ExtData 加值（模板）** | op 18 | 加妖石：`roleId,addValue` → `SetExtData32(407, +v)`；已处理在线/离线（`ReadDataSimple`→改→`SaveDataSimple`）**可作为新增 op 的模板** |
| 邮件附件编码 | op 19 | `(type,id,num)` 列表 → `SMailData` → `MakeMailAttachStr`（供后台预览附件串） |
| 禁言设置 | op 20 | `roleId,op(1设置/2取消)` |
| 当前在线角色 | op 21 | 返回唯一在线存档角色的 `roleId/name/level`；无角色或多角色时拒绝变更 |
| 运营操作 | `SpecChat` op 1~7 | 封号(1)/禁言(2)/踢下线(3)/重载NPC脚本(4)/重载物品脚本(5)/发系统邮件(6)/加称号(7) |
| **聊天 GM 指令** | `DoGMString`（`#if _DEBUG`） | `add lv / item / hero / equip / fabao / allequip / allhero / allfabao / quest / yc / gq / mail` |
| 运营鉴权 | `SpecChat` 开头 | `AllowIp()` 白名单 或 `AdminLevel()>0` |
| **邮件表** | **`xin_shi`** | 列含 `money,YB,bdYB,attachment,from_id,to_id,gmtime,time,from_name,message,deleted` |
| 邮件函数 | `SendSystemMail(roleId,msg,&SMailData)` / `SendSystemAwardMail(roleId,title,MultiAward)` | 均支持 `MultiAward` 附件 |
| 奖励类型 | **`HDAT_*` 枚举** | 见 §3 |

> 注：`admin` 表（GM 账号）在 base fixture 中是空 stub，实际应有 `userId/pwd/name` 等列（op 11/12 依赖），落地时需补齐建表/数据。

---

## 2. 总体架构（复用现有控台，不新增服务端逻辑）

```
┌──────────────────────────┐   本地 loopback 127.0.0.1:8711（既有 LocalServer）
│  本地 Web 后台 (浏览器)     │ ─────────────────────────────────────► │  kapai.exe (LocalServer)  │
│  - admin 登录 (op 11)      │   复用 MSG_MGR 管理协议                  │  - MSG_MGR op 分发        │
│  - 账号/角色树 (查询)       │ ◄────────────────────────────────────  │  - SendSystemMail(op15)   │
│  - 选资源 → 发邮件(op 15)  │   JSON/协议响应                          │  - xin_shi 邮件表写入     │
└──────────────────────────┘                                          └───────────┬─────────────┘
                                                                                   ▼
                                                                        projectx.db (xin_shi)
                                                                                   ▼
                                                                        玩家游戏内邮件箱 → 领取入背包
```

- **复用既有业务链**：直接复用 `MSG_MGR`，同时对鉴权、结果返回和高危 op 做最小加固。
- **无玩家入口**：不新增任何游戏内 UI；控制器仅本地且与 admin 鉴权绑定。
- **邮件投递现状**：op15 会调用 `SendSystemMail`，但本地服缺少 server-to-server 通道，当前不能写入 `xin_shi`；在补齐本地投递实现并验证前不得标记成功。

---

## 3. 资源 → `HDAT_*` 奖励类型映射

邮件附件用 `SAwardData{type,typeId,num}`（`type` 即 `HDAT_*`）：

| 资源 | `HDAT_*` | 备注 |
|---|---|---|
| 银两/金币 | `HDAT_MONEY` | op 15 的 `money` 即用此 |
| 元宝 | `HDAT_YB` | op 15 的 `YB` 即用此 |
| 绑定元宝 | `HDAT_BANG_YB` | |
| 道具 | `typeId < HDAT_MONEY`（即普通 itemId） | op 15 的 `itemId,num` |
| 神将/伙伴 | `HDAT_PET` | `DoGMString` 用 `AddPet` |
| 宠物装备 | `HDAT_PetEquip` | |
| 法宝 | `HDAT_FaBao` | |
| 星宿精华 | `HDAT_XingXiuJingHua` | |
| 竞技场货币 | `HDAT_JJCMoney` | |
| 昆仑货币 | `HDAT_KunLunMoney` | |
| 神魂 | `HDAT_SHEN_HUN` | |
| 帮派资金 | `HDAT_BANGPAI_MONEY` | |
| VIP | **不可走邮件附件** | 由 `GetChongzhiTotal()+GetExVipExp()` 推导，无对应 `HDAT_*` → 见 §3b（⚠️ 已取消实施：Steam 单机无 VIP） |

> 判断规则（代码惯例）：`typeId < HDAT_MONEY` = 普通道具；`typeId >= HDAT_MONEY` = 货币/特殊资源。

---

## 3b. VIP 发放专项（⚠️ 已取消实施：Steam 单机无 VIP）

> 以下为当初的方案调研记录，作为技术参考保留；按用户 2026-09-13 决策**不再实施**。

**机制**：VIP 等级是**推导值**，不是可发放的资源 ——
`m_vipLevel = ::GetVipLevel(GetChongzhiTotal() + GetExVipExp())`（`user.cpp:529 / 11483 / 16881`）

- `AddExVipExp(uint32 val) { SetExtData32(457, GetExtData32(457) + val); }`（`user.h:1848`）
- `GetExVipExp() { return GetExtData32(457); }`（`user.h:1849`）
- 推导输入 = 累计充值额 + **额外 VIP 经验（ExtData32 槽位 457）**

**⚠️ 陷阱**：`SetVipLevel(int lv)`（`user.h:668`）只改内存 `m_vipLevel`，**不做持久化**；重新登录后按 `chongzhi+exvipexp` 重算，**会被直接覆盖失效**。GM 不能只调 `SetVipLevel`。

**可行做法（已弃用）**：参照现有 **op 18（加妖石，写 ExtData32 槽位 407）** 新增一个 GM op：
1. 入参 `roleId, addValue`
2. 写 `SetExtData32(457, GetExtData32(457) + addValue)`
   - 在线：直接改；离线：`ReadDataSimple` → 改 → `SaveDataSimple`（与 op 18 处理完全一致）
3. 触发 VIP 重算（`m_vipLevel = GetVipLevel(GetChongzhiTotal()+GetExVipExp())`）并广播升级提示

> 说明：这是全方案中**原唯一需要少量服务端改动**的部分（新增一个 op）。因 Steam 单机无 VIP 系统，本项从范围中移除，服务端改动降至 1 处（md5 注册 + admin 建表）。

---

## 4. GM 账号与鉴权（复用 op 11）

### 4.1 admin 表真实结构：✅ 已落地（v1.4）

实测（已查两份 schema）：

- `server/sql/local_min_schema.sql:26`（MySQL 源）：`admin` 仅 `id int AUTO_INCREMENT`
- `server/sql/sqlite/001_initial_schema.sql:6`（SQLite 生成）：`admin` 仅 `id INTEGER PRIMARY KEY AUTOINCREMENT`

**代码 op 11/12 需要 `userId / name / pwd`**：
- op 11：`select userId,pwd from admin where userID='%u' and pwd=MD5('%s')`
- op 12：`select name,pwd from admin where name='%s' and pwd=MD5('%s')` / `update admin set pwd=MD5(...)`

**v1.4 已补建**（两份 schema 均更新）：
```sql
-- admin 表新增列
ALTER TABLE admin ADD COLUMN userId INTEGER NOT NULL DEFAULT 0;
ALTER TABLE admin ADD COLUMN name  TEXT    NOT NULL DEFAULT '';
ALTER TABLE admin ADD COLUMN pwd   TEXT    NOT NULL DEFAULT '';
-- GM 账号（由当前数据库连接注册的 MD5() 生成，避免构建差异）
INSERT INTO admin (userId,name,pwd) VALUES (1,'gm',MD5('gm123456'));
-- GM 操作日志表（pack_deal.cpp:11808 写入，缺失会报错）
CREATE TABLE admin_log (id INTEGER PRIMARY KEY AUTOINCREMENT, role_id INTEGER NOT NULL DEFAULT 0, msg TEXT, time TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);
```

> ⚠️ **已有 projectx.db 不会自动获得新列**（schema 文件只在新建时生效）。请对运行中的库执行 `docs/gm-backend/migrate_admin.py`：
> `python docs/gm-backend/migrate_admin.py <path/to/projectx.db> [gm_password]`
> 该脚本先备份并执行前后 `quick_check`，再用 PRAGMA 探测列；默认 GM 口令 `gm123456`，当前 Windows LocalServer 默认哈希模式为 `djb2-win32`。

登录成功后服务端 `SetAdminLevel(ADMIN_LEVEL)`，后续操作以此为准。

### 4.2 阻塞项：SQLite 未注册 `md5()` 函数 —— ✅ 已修复（v1.4）

op 11/12 依赖 **SQL 层 MySQL 内置 `MD5()`**。原 SQLite 兼容函数注册表 `SqliteRegisterCompatibility()`（`server/src/gyu/g_database.cpp`）**只注册了**：

`unix_timestamp` / `from_unixtime` / `now` / `concat` / `if` / `greatest` —— **没有 `md5`**。

→ 单机 SQLite 下 op 11/12 会直接失败（`no such function: MD5`），GM 登录不可用。同样影响 op 11 之外的 `md5()` 依赖路径（`pack_deal.cpp:25286`、`script_call.cpp:5627` 的账号口令）。

**已落地方案 A（v1.4）**：在 `SqliteRegisterCompatibility()` 注册 `md5`，实现复用现有 OpenSSL `MD5String()`（`gyu/g_utility.cpp:183`）。新增 `SqliteMd5` 静态函数：

```cpp
static void SqliteMd5(sqlite3_context *context, int argc, sqlite3_value **argv)
{
    if(argc != 1 || sqlite3_value_type(argv[0]) == SQLITE_NULL)
    {
        sqlite3_result_null(context);
        return;
    }
    const unsigned char *text = sqlite3_value_text(argv[0]);
    std::string input = text != NULL ? reinterpret_cast<const char*>(text) : std::string();
    gyu::util::MD5String(input);  // 使用当前构建的服务端哈希实现
    sqlite3_result_text(context, input.c_str(), (int)input.size(), SQLITE_TRANSIENT);
}
```

注册行（在 `greatest` 之后）：
```cpp
if(rc == SQLITE_OK)
    rc = sqlite3_create_function_v2(database, "md5", 1, SQLITE_UTF8 | SQLITE_DETERMINISTIC, NULL, SqliteMd5, NULL, NULL, NULL);
```

> 结论：4.1 建表 + 4.2 注册 md5 函数 **均已落地**，GM 登录链路打通。再加上 §3b VIP op **已取消**，服务端改动合计 **1 处**（md5 注册 + admin 建表，属同一处兼容性补齐）。

---

## 5. Web 后台设计（服务端协议客户端）

| 部分 | 说明 |
|---|---|
| 后端 | 本地进程（Python/Node），**直连 LocalServer 8711**，封装 `MSG_MGR` 协议报文（含 `SMailData` 打包） |
| 登录 | 调 op 11（admin 用户名 + MD5 口令） |
| 资源发放 | 调 **op 15**：填 `roleId / itemId / num / money / YB / message` |
| 全服邮件 | 调 op 16 |
| 查询账号/角色 | 调 op 21 查询当前 LocalServer 唯一在线存档角色，不从兼容登录账号推断目标 |
| 禁用 | **op 13 裸 SQL 一律不放开**（Web 后台不暴露） |

- 启动：`run_gm_web.bat` → `http://127.0.0.1:8081`，须游戏/LocalServer 在运行。
- 开发者本地工具，**不进游戏分发包**。

### 5.1 ✅ 实现落地（v1.6，tools/gm-backend/）

Web 后台已用**纯 Python 标准库**实现（`http.server`，无第三方依赖）：

| 文件 | 作用 |
|---|---|
| `tools/gm-backend/gm_client.py` | 协议客户端：`CNetMessage` 二进制报文编解码 + 登录/GM登录/各 op 构造 |
| `tools/gm-backend/gm_web.py` | 本地 Web 控制台（表单：发邮件/加通宝/加物品/改等级） |
| `tools/gm-backend/gm_config.ini` | 连接与 GM 账号配置 |
| `tools/gm-backend/run_gm_web.bat` | Windows 一键启动 |
| `tools/gm-backend/README.md` | 运行说明 |

**报文格式（已按 `g_net_msg.cpp` 核实）**：`[uint32 LE bodyLen][uint16 LE msgType][body]`，整数小端，字符串 `[uint16 LE 字节数][UTF-16LE]`。

**单次动作流程**：连接 → `PRO_USER_LOGIN(1001)`（只建立 GM 协议会话）→ `MSG_MGR(0xfffe) op11` GM 登录 → op21 查询并核对唯一在线存档角色 → 执行目标 op → 校验响应类型、op 和 `OK|/ERR|` → 关闭。登录失败或目标不一致时不会修改数据库。

**已开放操作**：op1 加通宝、op2 加物品、op5 改等级；op1/op2/op5 已返回可判定结果。op5 对在线角色同时更新数据库与内存，刷新排行并推送 `/226`；Unity 收到后更新 HUD 和存档元数据。op15 仍因本地服无 server-to-server 通道而无法证明投递，客户端会报“未返回可验证结果”。op13 已从客户端移除并在服务端永久禁用。

> 前提：`LocalServer` 运行且 `local_test=1`；`admin` 表已建（已用 `docs/gm-backend/migrate_admin.py` 迁移已有库）；`gm_config.ini` 的 `server_id` 须与服务端一致。

---

## 6. 实施排期

| 阶段 | 内容 | 改动位置 | 产出 | 状态 |
|---|---|---|---|---|
| **P0** | ① SQLite 注册 `md5()` 函数（方案 A）② 补 `admin` 表列 + GM 账号 + `admin_log` 表 | 服务端：1 处兼容性补齐 | GM 登录链路打通（VIP op 已取消） | ✅ 已落地 |
| **P1** | Web 后台跑通 op 11 登录 | 工具 `tools/gm-backend/` | 后台可鉴权登录 | ✅ 已实现 |
| **P2** | op1/op2/op5 + op15 调研 | 工具 `tools/gm-backend/` | 通宝、物品、等级具备协议入口；等级在线实时同步；邮件保留阻塞 | 🟡 部分完成 |
| **P3** | 扩展多 `HDAT_*`（神将/宠物装备/法宝/各类货币），接 op 19 附件预览 | 前端/工具 | 全资源覆盖 | ⬜ 待做 |
| **P4** | 全服邮件(op16)、红点(op17)、广播(op10/14)、运营操作(SpecChat 1~7) 按需接入 | 前端/工具 | 完整控台 | ⬜ 待做 |

> 服务端改动包括 SQLite md5/admin 兼容、op13 禁用、op1/op2/op5 可验证结果。VIP op 已取消。
> Python 协议编解码与边界值可做静态/假服务端回归；op15 收到回包不等于邮件投递成功。

---

## 7. 安全与边界

- **op 13 裸 SQL 已永久禁用**；不得以兼容或密码修复为由重新开放。
- 任何变更执行前必须以 op21 核对当前唯一在线角色；不得使用兼容登录账号、页面旧值或直读其他槽位数据库推断目标。
- Web 后台仅本地 + admin 鉴权，不进分发包；不新增玩家可见 UI（满足"避免上线后玩家使用"）。
- `DoGMString` 受 `#if _DEBUG` 限制，正式服不可用——Web 后台走 `MSG_MGR` 而非聊天指令，需确认 `MSG_MGR` 在正式包的开关策略。
- 邮件全部经游戏既有 `SendSystemMail`，不伪造概率/奖励（遵循 AGENTS.md 资源边界）。

---

## 8. 待确认/风险

**已解决（本次查实 + v1.4 落地）**

- ✅ **SQLite `md5()` 函数**（§4.2）——已在 `g_database.cpp` 注册，复用 `MD5String()`，GM 登录与账号口令等 `MD5()` 路径在单机版已可用。
- ✅ **admin 表结构**（§4.1）——两份 schema 已补 `userId/name/pwd` + GM 账号 + `admin_log`；已有库用 `docs/gm-backend/migrate_admin.py` 迁移。
- ✅ **在线存档识别与等级刷新**——op21 返回唯一在线角色并锁定 roleId；op5 更新持久化、在线状态与 `/226`，Unity 同步 HUD 和存档列表元数据。
- 🟡 VIP 路径：由 `chongzhi+ExVipExp(ExtData32#457)` 推导，**不可走邮件**；且 `SetVipLevel` 仅内存会被覆盖 → 但因 Steam 单机无 VIP，**该项按用户决策取消实施**（§3b 保留为参考）。

**仍需确认**

1. **`MSG_MGR` 在正式包是否开放** ——若与 `_DEBUG` 或 `local_test` 绑定，需明确 Web 后台适用环境（也决定是否需要按 §7 做开关）。
2. **LocalServer 端口与报文格式** ——`8711` 为 `LOCAL_TEST` 直连端口，需确认管理协议（`MSG_MGR`）是否同端口，以及报文头与收发格式（客户端 netcode 需对齐）。
3. `admin` 表除 `userId/name/pwd` 外是否还有其它生产列（如权限分级），需对照线上真实库确认（当前已满足 op 11/12 最小需求）。
4. SQLite 单写者：Web 后台查询走只读或经服务端，绝不并行直写。
