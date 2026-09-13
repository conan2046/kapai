# Cocos 体力恢复系统源码整理

> 整理日期：2026-09-13
> 范围：Cocos2d-x 2.17 + Lua 客户端、C++ 服务端、配置与界面资源。
> 性质：当前源码静态审计结果，不代表运行验收结论。
> 平台边界：本文为 Cocos 版本体力（Spirit）被动恢复机制的现状记录与迁移参照；Cocos 运行行为保持现状、不增加本需求修改。体力“领取”（三档时段领取、元宝补领）属独立子系统，详见 `docs/unityclient/modules/STAMINACLAIM.md`，本文仅在第 4.5 节作口径区分。

## 1. 结论摘要

- 体力（游戏内称“体力”，代码称 `Spirit`）被动恢复主协议为 `/321`：客户端常量 `MSG_QUERY_TILI`，服务端常量 `MSG_SPIRIT`。
- 恢复信息走 `op=1`；领取信息查询走 `op=2`、领取动作走 `op=3`（后两者属“体力领取”，见 STAMINACLAIM.md）。
- 恢复速率与上限由服务端全局配置键 `stamina` 控制，当前运行值为 `"100,500,360"`，对应：
  - `FULL_SPIRIT = 100`（被动恢复自然上限，也是客户端显示分母）
  - `MAX_SPIRIT = 500`（含领取在内的体力硬上限）
  - `FREE_SPIRIT = 360`（每 360 秒被动恢复 1 点，即 6 分钟/点）
- 恢复为**惰性补齐**而非实时逐秒：服务端在“重登录加载”和“在线心跳 `TimeOutUpdateUserData`”两个时机调用 `CUserSpirit::CheckAddSpirit` 计算应补点数；在线期间每次补齐 `≥1` 点即通过 `/321 op=1` 推送给客户端。
- 客户端进入主界面即发 `/321 op=1` 拉取当前体力与最后恢复时间戳，主界面 `Icon_tili` 显示 `X/100`（分母硬编码为 100，与 `FULL_SPIRIT` 一致）。
- 体力持久化在角色 `user_spirit` 字段（压缩保存 `m_spirit` / `m_lastSpiritTime` / 领取状态），重登录 `LoadData` 时完成离线时长补齐。
- 体力消耗（`SubSpirit`）与增加（`AddSpirit`，含升级 `isLv` 与领取）都会重置 / 推进 `m_lastSpiritTime` 并通过 `/321 op=1` 同步给客户端。

### 1.0 平台修改边界

| 平台/层 | 本需求处理 |
| --- | --- |
| Cocos Lua 客户端 | 不修改 |
| Cocos CSB 资源 | 不修改 |
| C++ 共享 `CUserSpirit` 恢复逻辑 | 不为本需求改变 Cocos 行为；Unity 复用同一服务端类 |
| Cocos 配置（`config.json` stamina 键、`stamina.json` 领取时段） | 不修改；运行态读取 |
| 角色 `user_spirit` 持久化 | 不修改 |

本文第 2～11 节中的 Cocos 代码、协议与配置均为现状记录与迁移参照，不构成本需求对 Cocos 版本的修改要求。

### 1.1 恢复口径（现状确认）

| 项目 | 当前规则 |
| --- | --- |
| 恢复触发 | 重登录 `LoadData` + 在线心跳 `TimeOutUpdateUserData` |
| 恢复速率 | 每 `FREE_SPIRIT`(360) 秒 +1 点 |
| 恢复自然上限 | `FULL_SPIRIT`(100)，达上限后停止恢复 |
| 硬上限（含领取） | `MAX_SPIRIT`(500)，领取时若超过则服务端拒绝 |
| 客户端显示 | 主界面 `X/100`，分母为硬编码常量 |
| 离线补齐 | 重登录 `LoadData → CheckAddSpirit` 一次性补齐至自然上限 |

## 2. 当前源码调用链

> 本节记录仓库现状，用于定位恢复逻辑与迁移参照。

```text
登录 / 重登录
  -> CUser::LoadData(row[44])                 # user.cpp:11344
  -> m_userSpirit.LoadData(str)
  -> CheckAddSpirit()                         # 无 pUser，仅补齐、不推送
  -> 进入主界面 MainUI
  -> LuaNetSendMsg:QueryTiLiInfo(1)           # /321 op=1
  -> CPackageDeal::DealSpirit op=1
  -> CUserSpirit::MakeSpiritMsg
  -> 返回 op=1 / result / tili / lastSpiritTime
  -> LuaNetRecvdMsg.DealTili op=1
  -> setTili(tili) + PetkaPaiManager:setTiLiTimer(lastSpiritTime)
  -> 主界面显示 tili/100

在线心跳
  -> CUser::TimeOutUpdateUserData             # user.cpp:9460
  -> m_userSpirit.CheckAddSpirit(this)
  -> 若 add>0：MSG_SPIRIT op=1 推送新 tili / lastSpiritTime

消耗体力（进入副本等）
  -> CUser::SubSpirit -> MSG_SPIRIT op=1 同步
```

## 3. 标识与入口

| 标识 | 值 | 位置 | 用途 |
| --- | ---: | --- | --- |
| 体力协议 | `/321` | `server/src/protocol.h:439` `MSG_SPIRIT = 321` | 体力信息 / 领取信息 / 领取动作 |
| 客户端常量 | `MSG_QUERY_TILI = 321` | `client/.../LuaNetCmd.lua:152` | 客户端发包常量 |
| 功能语义 | 体力（Spirit） | `server/src/user_spirit.h` 类 `CUserSpirit` | 体力状态机 |
| 运行配置键 | `"stamina"` | `server/config/json/config.json` | `"100,500,360"` = full/max/free |
| 领取时段配置 | `stamina.json` | `server/src/user_spirit.cpp:InitSpiritCfg` | 三档领取窗口（非恢复速率） |
| DB 列 | `user_spirit` | `server/src/user.cpp:8565`（`%41%`） | 压缩持久化 |
| 每日重置 | `FreeSpiritReset` | `server/src/user.cpp:9408` | 领取状态每日清零（恢复本身按时间，不依赖每日重置） |
| 心跳入口 | `TimeOutUpdateUserData` | `server/src/user.cpp:9460` | 在线恢复触发点 |

客户端进入主界面时主动同步：

```lua
-- client/ProjectX/src/View/MainUI.lua:219-221
-- 体力是主界面基础资源，进入主界面后立即向服务端同步。
-- 不依赖延迟执行的红点批量查询，避免批量流程中断时一直显示默认值 0。
LuaNetSendMsg:QueryTiLiInfo(1)
```

## 4. `/321` 前后端协议

### 4.1 协议注册

客户端：

```lua
MSG_QUERY_TILI = 321   -- 体力
this.m_pRegisterMsg:Changer(LuaNetCmd.MSG_QUERY_TILI, this.DealTili)  -- LuaNetRecvdMsg.lua:421
```

服务端：

```cpp
const int MSG_SPIRIT = 321;       // 体力  protocol.h:439
cmdFun.push_back(SCommand{MSG_SPIRIT, boost::bind(&CPackageDeal::DealSpirit,this,_1,_2)});  // pack_deal.cpp:463
```

### 4.2 客户端请求（QueryTiLiInfo）

| 顺序 | 类型 | 值 | 说明 |
| ---: | --- | --- | --- |
| 1 | `UShort` | `321` | 协议号 |
| 2 | `Byte` | `op` | `1`=体力信息，`2`=领取信息，`3`=领取动作 |

发送函数：`client/ProjectX/src/NetWork/LuaNetSendMsg.lua` 中的 `QueryTiLiInfo(op, ind, type)`。
仅 `op=2/3` 显示等待转圈（`ShowWaiting`）；`op=1` 为静默查询。

### 4.3 服务端返回 体力信息（op=1，MakeSpiritMsg）

| 顺序 | 类型 | 字段 | 当前语义 |
| ---: | --- | --- | --- |
| 1 | `Byte` | `op` | `1` |
| 2 | `Byte` | `result` | `PRO_SUCCESS=1` |
| 3 | `Word` | `tili` | 当前体力 `m_spirit` |
| 4 | `UInt32` | `lastSpiritTime` | 最后恢复时间戳 `m_lastSpiritTime` |

两种来源：
- 查询返回：`DealSpirit op=1 → MakeSpiritMsg`（不推进时间，仅读取）。
- 心跳/消耗推送：`CheckAddSpirit` / `AddSpirit` / `SubSpirit` 内部主动 `SendMsg(MSG_SPIRIT, op=1, result, m_spirit, m_lastSpiritTime)`。

### 4.4 客户端接收（DealTili op=1）

```lua
-- client/ProjectX/src/NetWork/LuaNetRecvdMsg.lua:14759
function LuaNetRecvdMsg.DealTili(stream)
    Utils:RemoveWaiting(LuaNetCmd.MSG_QUERY_TILI)
    local op = stream:ReadByte()
    if op == 1 then
        local errcode = stream:ReadByte()
        local tili = stream:ReadWord()
        LRoleDataMgr.MyHeroInfo:GetDetailData():setTili(tili)
        local nextUpdateTiliTime = stream:ReadUInt()
        PetkaPaiManager:setTiLiTimer(nextUpdateTiliTime, nil)
    elseif op == 2 then   -- 每日免费体力信息（领取子系统）
        ...
    elseif op == 3 then   -- 领取结果（领取子系统）
        ...
    end
end
```

主界面显示：

```lua
-- client/ProjectX/src/View/MainUI.lua:391-415
local Icon_tili = ButtonGroup6:getChildByName("Icon_tili")
self._tiliValue = Icon_tili:getChildByName("NumBg"):getChildByName("Num")
...
local tili = LRoleDataMgr.MyHeroInfo:GetDetailData():getTili()
self._tiliValue:setString(Utils:getTiliStr(tili))   -- "tili/100"
```

`Utils:getTiliStr` 分母为硬编码常量：

```lua
-- client/ProjectX/src/Common/Utils.lua:3585
function Utils:getTiliStr( tili )
    tili = tili or 0
    local strTili = string.format("%d/%d", tili, 100)
    return strTili
end
```

### 4.5 op=2/3 与恢复的口径区分

- `op=1`：被动恢复信息（本文范围）。
- `op=2`：三档领取窗口状态（`m_freeGetState`，值 `0/1/2/3` = 不可领/可领/元宝补领/已领）。
- `op=3`：执行领取（免费加 `SPIRIT_LINGQU=50`，或扣 `60001×20` 元宝补领）。

`op=2/3` 属“体力领取”子系统，已由 `STAMINACLAIM.md` 完成 Unity 迁移闭环，本文不展开。

## 5. 客户端代码清单

| 文件 | 职责 |
| --- | --- |
| `client/ProjectX/src/View/MainUI.lua` | 主界面 `Icon_tili` 显示、`TiliChanged` 刷新、进入即发 `/321 op=1` |
| `client/ProjectX/src/NetWork/LuaNetSendMsg.lua` | `QueryTiLiInfo(op,ind,type)` 发送 |
| `client/ProjectX/src/NetWork/LuaNetRecvdMsg.lua` | `DealTili` 接收 `op=1/2/3` |
| `client/ProjectX/src/NetWork/LuaNetCmd.lua` | `MSG_QUERY_TILI = 321` |
| `client/ProjectX/src/Common/Utils.lua` | `getTiliStr` 显示 `tili/100` |
| `client/ProjectX/src/Data/PetkaPaiManager.lua` | `setTiLiTimer` 保存 `m_lastSpiritTime` 作为本地倒计时锚 |
| `client/ProjectX/src/View/WelfareActivity/ReceiveTiliUI.lua` | 体力领取页（op=2/3，关联子系统） |

### 5.1 客户端本地计时

```lua
-- client/ProjectX/src/Data/PetkaPaiManager.lua:34
function PetkaPaiManager:setTiLiTimer(tili, xunBao)
    self.m_TiLiTime = tili or self.m_TiLiTime       -- 即 m_lastSpiritTime
    self.m_XunBaoTime = xunBao or self.m_XunBaoTime
    if self.m_TiliTimer ~= nil then return end
    self.m_TiliTimer = Utils:schedule(nil, function ()
        self.m_TiLiTime = self.m_TiLiTime + 1        -- 本地每秒 +1，作为倒计时锚
        self.m_XunBaoTime = self.m_XunBaoTime - 1
        ...
    end, 1, false)
end
```

注：客户端不自行累加体力数值，仅以 `m_lastSpiritTime` 作锚；体力数值始终来自服务端 `/321 op=1` 推送。

## 6. 服务端代码清单

| 文件 | 职责 |
| --- | --- |
| `server/src/user_spirit.h` | `CUserSpirit` 类、`SpiritCfg`、`CUserSpiritCfg` |
| `server/src/user_spirit.cpp` | `CheckAddSpirit`/`AddSpirit`/`SubSpirit`/`MakeSpiritMsg`/`LoadData`/`SaveData`/`FreeSpiritReset` |
| `server/src/pack_deal.cpp` | `DealSpirit` 协议分发（`op=1/2/3`） |
| `server/src/protocol.h` | `MSG_SPIRIT = 321` |
| `server/src/config_para.cpp` | `ReadSpirit` 解析 `config.json` 的 `stamina` 键 → `FULL/MAX/FREE` |
| `server/src/user.cpp` | `m_userSpirit` 成员、`TimeOutUpdateUserData` 心跳恢复、`LoadData/SaveData` 持久化、每日 `FreeSpiritReset` |
| `server/src/user.h` | `CUserSpirit m_userSpirit;`（:2829）、`GetUserSpirit()`（:2974） |

## 7. 服务端状态与规则

| 状态 | 类型/位置 | 含义 | 变化时机 |
| --- | --- | --- | --- |
| `m_spirit` | `uint16` | 当前体力 | `CheckAddSpirit`/`AddSpirit`/`SubSpirit` |
| `m_lastSpiritTime` | `uint32` | 最后恢复时间戳（秒） | 每次恢复步进 / 消耗低于满时重置为 `now` |
| `m_freeGetState` | `map<uint8,uint8>` | 三档领取状态 | 每日 `FreeSpiritReset` 清零；领取置 `3` |
| `FULL_SPIRIT` | `static uint16` | 自然恢复上限 | 配置加载，当前 `100` |
| `MAX_SPIRIT` | `static uint16` | 含领取硬上限 | 配置加载，当前 `500` |
| `FREE_SPIRIT` | `static uint16` | 每点恢复秒数 | 配置加载，当前 `360` |
| `SPIRIT_LINGQU` | `static uint16` | 每档领取量 | 代码常量，当前 `50` |

静态初值（注意风险见 §10.1）：

```cpp
uint16 CUserSpirit::FULL_SPIRIT = 0;
uint16 CUserSpirit::MAX_SPIRIT  = 0;
uint16 CUserSpirit::FREE_SPIRIT = 0;   // 配置未加载时为 0
uint16 CUserSpirit::SPIRIT_LINGQU = 50;
```

持久化（压缩写）：

```cpp
// user_spirit.cpp SaveData
pos = CopyDataToBuf(..., &m_spirit, sizeof(m_spirit), pos);
pos = CopyDataToBuf(..., &m_lastSpiritTime, sizeof(m_lastSpiritTime), pos);
data[pos++] = m_freeGetState.size();
... // 写入 type/state
Compress(data, pos, str);
```

## 8. 配置

### 8.1 恢复速率（config.json 的 `stamina` 键）

```json
{"id":6,"name":"stamina","type":"array","value":"100,500,360"}
```

`ReadSpirit` 解析为 `[fullSpirit, maxSpirit, freeSpirit]`：

```cpp
// server/src/config_para.cpp:106
void CParaMgr::ReadSpirit(string & val)
{
    // 支持 [a,b,c] 数组 或 "a,b,c" 字符串
    fullSpirit = arrt[0]; maxSpirit = arrt[1]; freeSpirit = arrt[2];
    if (fullSpirit <= 0 || maxSpirit < fullSpirit || freeSpirit <= 0)
        return;                       // 守卫：任一非法则保持静态初值 0
    CUserSpirit::FULL_SPIRIT = (uint16)fullSpirit;   // 100
    CUserSpirit::MAX_SPIRIT  = (uint16)maxSpirit;    // 500
    CUserSpirit::FREE_SPIRIT = (uint16)freeSpirit;   // 360
}
```

### 8.2 领取时段（stamina.json，与恢复速率无关）

`user_spirit.cpp::InitSpiritCfg` 读取 `stamina.json`，字段 `id / time[start,end] / value[?,add] / cost[type,num]`。当前运行值（据 STAMINACLAIM.md）：`12:00-14:00 / 18:00-20:00 / 21:00-22:00`，每档 `add=50`，补领 `cost=60001×20`。此为“领取”窗口配置，不影响被动恢复速率。

### 8.3 加载顺序

`config_para.cpp` 解析循环命中 `key == "stamina"` 时调用 `ReadSpirit`。须在角色加载前完成，否则 `FULL/MAX/FREE` 保持 `0`。

## 9. 体力恢复规则与数学

核心算法（服务端惰性补齐）：

```cpp
// server/src/user_spirit.cpp:172
void CUserSpirit::CheckAddSpirit(CUser* pUser)
{
    if (m_spirit >= FULL_SPIRIT) return;          // 已满，停止恢复
    uint32 now = GetSysTime();
    uint32 sec = now - m_lastSpiritTime;
    uint8 add = sec / FREE_SPIRIT;                // 360 秒/点
    if (add == 0) return;
    m_spirit += add;
    if (add > 0)
        m_lastSpiritTime += add * FREE_SPIRIT;    // 仅步进整数点，余数留在时间戳
    if (m_spirit > FULL_SPIRIT)
    {
        m_spirit = FULL_SPIRIT;
        m_lastSpiritTime = 0;                      // 满体力时时间戳清零
    }
    if (pUser != NULL)
    {
        CNetMessage msg;
        msg.SetType(MSG_SPIRIT);
        msg << (uint8)1 << PRO_SUCCESS << m_spirit << m_lastSpiritTime;
        SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
    }
}
```

推导：
- 恢复速率 = `1 / FREE_SPIRIT` 点/秒 = `1/360` 点/秒 ≈ `1` 点/6 分钟。
- 从 0 恢复到满（100）：`100 × 360 = 36000` 秒 = 10 小时。
- 时间戳步进采用 `add * FREE_SPIRIT`，因此不足一个周期的余量（如 40 秒）累计到下一轮，避免丢秒。
- 离线 10 小时以上：`add = 100`，`m_spirit` 被钳到 `FULL_SPIRIT` 且 `m_lastSpiritTime = 0`，等价于一次性回满。

消耗对恢复时钟的影响（`SubSpirit`）：

```cpp
// user_spirit.cpp:217
if (m_spirit >= FULL_SPIRIT && m_spirit - spirit < FULL_SPIRIT)
    m_lastSpiritTime = now;     // 从满跌到不满时，重置恢复起点为当前时间
m_spirit -= spirit;
```

增加（含领取）对恢复时钟的影响（`AddSpirit`）：

```cpp
// user_spirit.cpp:200
if (m_spirit + spirit > MAX_SPIRIT && !isLv) return false;  // 非升级则受硬上限约束
m_spirit += spirit;
if (m_spirit < FULL_SPIRIT)
    m_lastSpiritTime = GetSysTime();   // 领取后若仍不满，恢复起点被重置为现在
```

## 10. 已知问题与不一致

### 10.1 配置未加载时除零 / 恢复失效

- `FREE_SPIRIT` 静态初值为 `0`；若 `config.json` 的 `stamina` 键未加载或被守卫拒收，`CheckAddSpirit` 中 `sec / FREE_SPIRIT` 为**除零**（未定义行为 / 崩溃风险）。
- 同时 `FULL_SPIRIT`/`MAX_SPIRIT` 保持 `0`，则 `m_spirit(0) >= FULL(0)` 恒成立，`CheckAddSpirit` 永远早返回——无恢复且无崩溃，但体力恒为 0。
- 结论：恢复机制强依赖 `config.json` 的 `stamina` 键在角色加载前就绪；`local_test=1` 跳过 `InitXMLConfig` 时（`FEATURE_CONFIG_SOURCES.md` §1）须确认该键仍被解析。

### 10.2 客户端显示分母硬编码 100

- `getTiliStr` 固定 `/100`，与 `FULL_SPIRIT` 强耦合。修改 `FULL_SPIRIT` 必须同步此处，否则显示与上限不一致。

### 10.3 领取会推迟被动恢复起点

- `AddSpirit` 在 `m_spirit < FULL_SPIRIT` 时把 `m_lastSpiritTime` 重置为 `now`。玩家在未满时领取体力，被动恢复的“下一周期”起点被顺延，等价于领取动作消耗了部分恢复余量。

### 10.4 满体力时间戳清零的隐式依赖

- 满体力时 `m_lastSpiritTime = 0`；下次 `CheckAddSpirit` 因 `m_spirit >= FULL` 早返回，不读时间戳。恢复重启依赖“消耗使 `m_spirit` 跌破 `FULL`”触发 `SubSpirit` 重置时间戳。若玩家长期处于满体力且无消耗，恢复时钟处于静默态，符合预期但不直观。

### 10.5 在线推送仅在有整数点补齐时发生

- `CheckAddSpirit` 仅当 `add > 0` 才推送 `op=1`。单心跳周期内不足 1 点时客户端不收到更新，仍依赖 `LoadData`/`SubSpirit`/`AddSpirit` 推送或主界面重新查询。客户端本地 `setTiLiTimer` 的每秒自增仅作锚，不自行改体力数值。

### 10.6 op=1 双来源幂等

- `op=1` 既来自查询返回也来自心跳/增减推送，客户端 `DealTili` 同一分支处理，属幂等覆盖（`setTili` 直接赋值），无重复累加风险。

## 11. 当前验证覆盖

- `PROTOCOL_COVERAGE.md` 与 `tools/local/Invoke-ProtocolSmoke.ps1` 当前检索未覆盖 `/321` 任意 op（领取子系统的 `answer_question` 式 smoke 不在体力协议上）。
- 当前没有自动覆盖：
  - 离线时长重登补齐至满。
  - 在线心跳逐点恢复与 `op=1` 推送。
  - 阈值 `FULL`/`MAX` 边界（`FREE_SPIRIT` 未加载的除零保护）。
  - 消耗触发恢复时钟重启。
  - 领取后 `m_lastSpiritTime` 重置对被动恢复的影响。
- 建议 Unity 迁移与 Cocos 联调时按上述清单补 `/321 op=1` 的 smoke 与边界用例。

## 12. 后续使用建议

- Cocos 版本：体力恢复逻辑（`CUserSpirit` + `/321 op=1` + `config.json` stamina 键）保持现状，作为 Unity 复用同一服务端实现的参照。
- Unity 版本：复用服务端 `CheckAddSpirit` / `MakeSpiritMsg`；客户端以 `/321 op=1` 拉取并显示 `tili/100`，本地以 `m_lastSpiritTime` 作恢复倒计时锚。
- 配置调整：改 `FULL_SPIRIT`/`MAX_SPIRIT`/`FREE_SPIRIT` 只需改 `config.json` 的 `stamina` 值；改客户端显示分母须同步 `Utils:getTiliStr`；领取窗口改 `stamina.json`。
- 风险红线：`FREE_SPIRIT` 不得为 `0`；上线前必须确认 `config.json` 的 `stamina` 键已加载且通过 `ReadSpirit` 守卫。

## 13. Steam 单机版本影响

- 体力恢复（被动，`op=1`）**不在 `STEAM_SCOPE.md` 排除清单**，单机 Steam 版保留、不改行为。恢复完全由本地 C++ 服务端（kapai.exe / LocalServer）驱动，无账号 / 联网依赖；`/321` 仍走 `127.0.0.1` 本地回路，持久化落地本地 SQLite `projectx.db`。
- 体力领取（`StaminaClaim`，`op=2/3`）**已排除**（`STEAM_SCOPE.md:21`，“作为福利子模块排除，玩法大厅隐藏”）。该部分是独立子系统，勿与恢复混淆；Steam 版应隐藏 / 不接入 `ReceiveTiliUI` 的领取入口与三档按钮，但服务端 `GetFreeSpirit` 留存量不影响恢复。
- 单机构建必须验证项：
  1. 配置加载：确保单机配置初始化链路解析 `config.json` 的 `stamina` 键，使 `FULL/MAX/FREE = 100/500/360` 生效。否则触发 §10.1 除零或恢复恒为 `0`。这是单机版唯一硬性改动点（若构建流程与在线版配置引导不同，须补齐）。
  2. 心跳循环：确认本地服务端主循环仍调用 `TimeOutUpdateUserData`（`pack_deal.cpp:1718`）→ `CheckAddSpirit`，否则在线期间被动恢复不推送（仅登录 `LoadData` 与消耗时补齐）。
- 平衡 / 显示：若单机版重调体力数值（改 `FULL_SPIRIT`），须同步 `Utils:getTiliStr` 硬编码 `/100` 分母。
- 时间作弊（设计决策，非强制改动）：恢复基于真实墙钟 `GetSysTime()`，单机玩家可通过改系统时间快进体力。纯单机通常可接受；若 Steam 含排行榜 / 成就，建议改为基于游戏内时长累计。
