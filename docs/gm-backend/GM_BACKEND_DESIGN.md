# GM 后台设计方案（kapai 单机 Unity + SQLite）

> 状态：设计稿 v1.3（修订）
> **重大修订**：服务端**已有完整 GM 控台**（`MSG_MGR` 管理协议 + `DoGMString` 聊天 GM 指令）。因此**不自建 Unity 指令层**——直接复用现有服务端接口，Web 后台做成"服务端管理协议的客户端"即可。
> 确认结论：纯网页端 + 邮件投递（复用 existing op 15）；无游戏内调试面板；仅运行时转发。

---

## 1. 现有服务端 GM 设施（已实测源码定位）

| 能力 | 位置 | 说明 |
|---|---|---|
| **管理协议** | `pack_deal.cpp` `MSG_MGR` op 分发 | 服务端控台主接口，op 10~16+ |
| GM 登录 | op 11 | `select userId,pwd from admin where userID=... and pwd=MD5(...)` → 成功则 `SetAdminLevel(ADMIN_LEVEL)` |
| 改密码 | op 12 | `update admin set pwd=MD5(...) where name=...` |
| **裸执行 SQL** | op 13 | `msg>>sql; pDb->Query(sql)` ⚠️ 高危，Web 后台必须禁用 |
| 全服广播 | op 10 / op 14 | `SendSysChannelMsg` / `SysInfoToAllUser` |
| **发资源邮件** | **op 15** | `roleId,itemId,num,money,YB,message` → `SMailData` + `SendSystemMail(roleId,msg,&mdata)` |
| 全服邮件 | op 16 | 对所有在线玩家发系统邮件（`SysMailToAllUser`） |
| 邮件红点通知 | op 17 | `SendHotPointStatus(... EHPoint_Mail ...)` 提示玩家有新邮件 |
| **ExtData 加值（模板）** | op 18 | 加妖石：`roleId,addValue` → `SetExtData32(407, +v)`；已处理在线/离线（`ReadDataSimple`→改→`SaveDataSimple`）**可作为新增 op 的模板** |
| 邮件附件编码 | op 19 | `(type,id,num)` 列表 → `SMailData` → `MakeMailAttachStr`（供后台预览附件串） |
| 禁言设置 | op 20 | `roleId,op(1设置/2取消)` |
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

- **零服务端改动（核心优势）**：直接复用现有 `MSG_MGR` op 11（登录）+ op 15（发资源邮件）。
- **无玩家入口**：不新增任何游戏内 UI；控制器仅本地且与 admin 鉴权绑定。
- **邮件投递**：全部经 `SendSystemMail(roleId,msg,&SMailData)` 写入 `xin_shi`，玩家游戏内领取——天然走游戏既有发奖/序列化逻辑，**零毁档风险**。

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
| VIP | **不可走邮件附件** | 由 `GetChongzhiTotal()+GetExVipExp()` 推导，无对应 `HDAT_*` → 见 §3b |

> 判断规则（代码惯例）：`typeId < HDAT_MONEY` = 普通道具；`typeId >= HDAT_MONEY` = 货币/特殊资源。

---

## 3b. VIP 发放专项（P0 已查实）

**机制**：VIP 等级是**推导值**，不是可发放的资源 ——
`m_vipLevel = ::GetVipLevel(GetChongzhiTotal() + GetExVipExp())`（`user.cpp:529 / 11483 / 16881`）

- `AddExVipExp(uint32 val) { SetExtData32(457, GetExtData32(457) + val); }`（`user.h:1848`）
- `GetExVipExp() { return GetExtData32(457); }`（`user.h:1849`）
- 推导输入 = 累计充值额 + **额外 VIP 经验（ExtData32 槽位 457）**

**⚠️ 陷阱**：`SetVipLevel(int lv)`（`user.h:668`）只改内存 `m_vipLevel`，**不做持久化**；重新登录后按 `chongzhi+exvipexp` 重算，**会被直接覆盖失效**。GM 不能只调 `SetVipLevel`。

**可行做法（推荐）**：参照现有 **op 18（加妖石，写 ExtData32 槽位 407）** 新增一个 GM op：
1. 入参 `roleId, addValue`
2. 写 `SetExtData32(457, GetExtData32(457) + addValue)`
   - 在线：直接改；离线：`ReadDataSimple` → 改 → `SaveDataSimple`（与 op 18 处理完全一致）
3. 触发 VIP 重算（`m_vipLevel = GetVipLevel(GetChongzhiTotal()+GetExVipExp())`）并广播升级提示

> 说明：这是全方案中**唯一需要少量服务端改动**的部分（新增一个 op）；其余资源均可复用现有 op 15 邮件发放。

---

## 4. GM 账号与鉴权（复用 op 11）

- GM 账号存 **`admin` 表**，口令 **MD5**（op 11 校验逻辑）。
- 登录成功后服务端 `SetAdminLevel(ADMIN_LEVEL)`，后续操作以此为准。
- Web 后台需：
  1. 补 `admin` 表结构（`userId/pwd/name` 等，参照 op 11/12 SQL）
  2. 补 GM 账号数据（MD5 口令）
  3. 登录走 op 11，会话期间保持连接

---

## 5. Web 后台设计（服务端协议客户端）

| 部分 | 说明 |
|---|---|
| 后端 | 本地进程（Python/Node），**直连 LocalServer 8711**，封装 `MSG_MGR` 协议报文（含 `SMailData` 打包） |
| 登录 | 调 op 11（admin 用户名 + MD5 口令） |
| 资源发放 | 调 **op 15**：填 `roleId / itemId / num / money / YB / message` |
| 全服邮件 | 调 op 16 |
| 查询账号/角色 | 只读 `projectx.db`（`user_info1` → `role_info`），或经服务端查询接口 |
| 禁用 | **op 13 裸 SQL 一律不放开**（Web 后台不暴露） |

- 启动：`gm-web.bat` → `http://127.0.0.1:8080`，须游戏/LocalServer 在运行。
- 开发者本地工具，**不进游戏分发包**。

---

## 6. 实施排期

| 阶段 | 内容 | 产出 |
|---|---|---|
| P0 | 核对 `admin` 表真实结构；确认 LocalServer 端口/协议可达；定位 VIP 处理方案 | 落地前置确认 |
| P1 | 补 `admin` 表 + GM 账号（MD5）；跑通 op 11 登录 | Web 后台可鉴权登录 |
| P2 | 实现 op 15 发邮件（货币 + 道具），账号/角色树 | **核心能力：网页端给账号发资源邮件** |
| P3 | 扩展多 `HDAT_*`（神将/宠物装备/法宝/各类货币） | 全资源覆盖 |
| P4 | 全服邮件(op16)、广播(op10/14)、运营操作(SpecChat 1~7) 按需接入 | 完整控台 |

> 服务端基本零改动；工作量集中在 Web 后台的协议封装与 UI。

---

## 7. 安全与边界

- **禁止暴露 op 13 裸 SQL**（否则等同 DB 完全开放）。
- Web 后台仅本地 + admin 鉴权，不进分发包；不新增玩家可见 UI（满足"避免上线后玩家使用"）。
- `DoGMString` 受 `#if _DEBUG` 限制，正式服不可用——Web 后台走 `MSG_MGR` 而非聊天指令，需确认 `MSG_MGR` 在正式包的开关策略。
- 邮件全部经游戏既有 `SendSystemMail`，不伪造概率/奖励（遵循 AGENTS.md 资源边界）。

---

## 8. 待确认/风险

1. **VIP 发放无对应 `HDAT_*`** ——需确认 VIP 如何经邮件发放（或改用直接改等级字段的独立路径）。
2. **`admin` 表真实结构** ——fixture 为空 stub，需按 op 11/12 SQL 反推并核对实际库。
3. **`MSG_MGR` 在正式包是否开放** ——若与 `_DEBUG` 或 `local_test` 绑定，需明确 Web 后台适用环境。
4. LocalServer 端口/报文手足 ——`8711` 为 `LOCAL_TEST` 直连端口，需确认管理协议是否同端口。
5. SQLite 单写者：Web 后台查询走只读或经服务端，绝不并行直写。
